--!strict
--[[
	ChessService — chess at the lobby's chess table (owner's fix list: "chess minigame in the lobby"). A table is a
	ChessTable-tagged model with two ChessSeat Seats (attribute Side: 1 = White, the west seat; 2 = Black); they are
	also LobbySeats, so the normal Sit prompt (it says "Play chess") and SeatService seat players there. This service
	runs one Shared/ChessMatch per table: sitting down / standing up, ChessMove (from, to, promotion) and ChessAction
	(Resign / OfferDraw / AcceptDraw) from the seated players, and a 0.2 s tick for the clocks and the next game.
	Every move is checked by Shared/ChessRules. Everything shows through the table model's attributes: State, Fen,
	Player1 / Player2 (who sits where: UserIds, 0 = empty, −1 = the bot), White / Black (who plays the current or last
	game, kept when one stands up), Clock1 / Clock2 (seconds left when the turn began) and
	TurnStartedAt (Workspace:GetServerTimeNow()), LastMove ("e2e4"), Check, DrawOffer (side), Result, Winner (side,
	0 = draw) and EndsAt. A win adds to the winner's ChessWins stat (not in private servers, not against the bot).
	Developer panel: "Chess bot" puts a practice bot in the empty seat of the sender's table; it plays a random legal
	move Config.Dev.ChessBotDelay seconds after each of yours and leaves when the table empties.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ChessMatch = require(Shared:WaitForChild("ChessMatch"))
local ChessRules = require(Shared:WaitForChild("ChessRules"))
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))

local TABLE_TAG = "ChessTable"
local SEAT_TAG = "ChessSeat"
local TICK_INTERVAL = 0.2
local BOT = ChessMatch.Bot

type Table = {
	Model: Model,
	Seats: { [number]: Seat },
	Match: ChessMatch.Match,
	BotTurn: number, -- when the turn the bot is replying to began (TurnStartedAt: new for every move and game)
	BotAt: number, -- when the bot moves
}

local ChessService = {}

local tables: { Table } = {}
local random = Random.new()

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Chess] {message}`)
	end
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function playerOn(entry: Table, side: number): Player?
	local userId = entry.Match.Players[side]
	return if userId > 0 then Players:GetPlayerByUserId(userId) else nil
end

local function nameOf(entry: Table, side: number): string
	local player = playerOn(entry, side)
	return if player then player.Name elseif entry.Match.Players[side] == BOT then "bot" else "nobody"
end

-- Mirrors the game onto the table's attributes.
local function publish(entry: Table)
	local match, model = entry.Match, entry.Model
	model:SetAttribute("State", match.State)
	model:SetAttribute("Fen", ChessRules.toFen(match.Position))
	model:SetAttribute("Player1", match.Players[1])
	model:SetAttribute("Player2", match.Players[2])
	model:SetAttribute("White", match.GamePlayers[1])
	model:SetAttribute("Black", match.GamePlayers[2])
	model:SetAttribute("Clock1", match.Clocks[1])
	model:SetAttribute("Clock2", match.Clocks[2])
	model:SetAttribute("TurnStartedAt", match.TurnStartedAt)
	model:SetAttribute("LastMove", match.LastMove)
	model:SetAttribute("Check", match.State == "Playing" and ChessRules.inCheck(match.Position))
	model:SetAttribute("DrawOffer", match.DrawOffer)
	model:SetAttribute("Result", match.Result)
	model:SetAttribute("Winner", match.Winner)
	model:SetAttribute("EndsAt", match.EndsAt)
end

-- A game ended: the winner's stat, analytics, Output.
local function finished(entry: Table)
	local match = entry.Match
	local againstBot = match.Players[1] == BOT or match.Players[2] == BOT
	local winner = if match.Winner ~= 0 then playerOn(entry, match.Winner) else nil
	if winner and not againstBot and PrivateServerService.countsProgress() then
		DataService.incrementStat(winner, "ChessWins")
	end
	for side = 1, 2 do
		local player = playerOn(entry, side)
		if player then
			local outcome = if match.Winner == 0 then "Draw" elseif match.Winner == side then "Won" else "Lost"
			Analytics.custom(player, "Chess", 1, { outcome, match.Result, if againstBot then "Bot" else "Player" })
		end
	end
	log(
		if match.Winner == 0
			then `draw ({match.Result})`
			else `{nameOf(entry, match.Winner)} wins ({match.Result}) after {#match.History - 1} moves`
	)
end

-- The seat on `side` changed hands.
local function onOccupant(entry: Table, side: number)
	local seat = entry.Seats[side]
	local humanoid = seat.Occupant
	local player = if humanoid then Players:GetPlayerFromCharacter(humanoid.Parent) else nil
	local match = entry.Match
	local event = ChessMatch.seat(match, side, if player then player.UserId else 0, now())
	if event == "Finished" then
		finished(entry)
	end
	-- The bot only keeps someone company: it leaves when the other seat empties.
	local other = 3 - side
	if player == nil and match.Players[other] == BOT then
		ChessMatch.seat(match, other, 0, now())
	end
	publish(entry)
end

local function add(model: Instance)
	if not model:IsA("Model") or not model:IsDescendantOf(Workspace) then
		return
	end
	for _, entry in tables do
		if entry.Model == model then
			return
		end
	end
	local seats: { [number]: Seat } = {}
	for _, seat in model:GetDescendants() do
		local side = seat:GetAttribute("Side")
		if seat:IsA("Seat") and seat:HasTag(SEAT_TAG) and (side == 1 or side == 2) then
			seats[side :: number] = seat
		end
	end
	if not seats[1] or not seats[2] then
		warn(`[Chess] {model:GetFullName()} needs two ChessSeat seats (Side 1 and 2)`)
		return
	end
	local entry: Table = { Model = model, Seats = seats, Match = ChessMatch.new(), BotTurn = -1, BotAt = 0 }
	table.insert(tables, entry)
	for side, seat in seats do
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			onOccupant(entry, side)
		end)
	end
	publish(entry)
end

-- The table `player` sits at, and their side, if any.
local function seatOf(player: Player): (Table?, number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat == nil then
		return nil, 0
	end
	for _, entry in tables do
		for side, tableSeat in entry.Seats do
			if (tableSeat :: Instance) == (seat :: Instance) and entry.Match.Players[side] == player.UserId then
				return entry, side
			end
		end
	end
	return nil, 0
end

-- Developer panel: a practice bot in the empty seat of `player`'s table. Returns whether one sat down.
function ChessService.addBot(player: Player): boolean
	local entry, side = seatOf(player)
	if entry == nil then
		log(`{player.Name} isn't at a chess table: sit down first`)
		return false
	end
	local other = 3 - side
	if entry.Match.Players[other] ~= 0 then
		return false
	end
	ChessMatch.seat(entry.Match, other, BOT, now())
	publish(entry)
	log(`bot sits down opposite {player.Name}`)
	return true
end

-- The bot's reply: a random legal move (a promotion makes a queen), a moment after its turn began.
local function botMove(entry: Table, t: number)
	local match = entry.Match
	local side = ChessMatch.toMove(match)
	if match.State ~= "Playing" or match.Players[side] ~= BOT then
		return
	end
	if entry.BotTurn ~= match.TurnStartedAt then
		entry.BotTurn = match.TurnStartedAt
		entry.BotAt = t + Config.Dev.ChessBotDelay
		return
	end
	if t < entry.BotAt then
		return
	end
	local moves = ChessRules.legalMoves(match.Position)
	local candidates: { ChessRules.Move } = {}
	for _, move in moves do
		if move.Promotion == nil or move.Promotion == "Q" then
			table.insert(candidates, move)
		end
	end
	local move = candidates[random:NextInteger(1, #candidates)]
	local _, event =
		ChessMatch.move(match, side, ChessRules.name(move.From), ChessRules.name(move.To), move.Promotion, t)
	if event == "Finished" then
		finished(entry)
	end
end

local function tick()
	local t = now()
	for _, entry in tables do
		if ChessMatch.tick(entry.Match, t) == "Finished" then
			finished(entry)
		end
		botMove(entry, t)
		publish(entry)
	end
end

function ChessService.Init(_self: any)
	Net.onServerEvent("ChessMove", function(player: Player, from: string, to: string, promotion: string?)
		local entry, side = seatOf(player)
		if entry == nil then
			return
		end
		local played, event = ChessMatch.move(entry.Match, side, from, to, promotion, now())
		if event == "Finished" then
			finished(entry)
		end
		if played or event then
			publish(entry)
		end
	end)
	Net.onServerEvent("ChessAction", function(player: Player, action: string)
		local entry, side = seatOf(player)
		if entry == nil then
			return
		end
		if ChessMatch.act(entry.Match, side, action, now()) == "Finished" then
			finished(entry)
		end
		publish(entry)
	end)
end

function ChessService.Start(_self: any)
	for _, model in CollectionService:GetTagged(TABLE_TAG) do
		add(model)
	end
	CollectionService:GetInstanceAddedSignal(TABLE_TAG):Connect(add)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed >= TICK_INTERVAL then
			elapsed = 0
			tick()
		end
	end)
end

return ChessService
