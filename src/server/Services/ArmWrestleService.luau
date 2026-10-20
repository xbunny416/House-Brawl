--!strict
--[[
	ArmWrestleService — the lobby's arm-wrestling table (owner's fix list: "arm-wrestling minigame in the lobby").
	A table is an ArmWrestleTable-tagged model with two ArmWrestleSeat Seats (attribute Side 1 / 2); they are also
	LobbySeats, so the normal Sit prompt and SeatService seat players there ("Arm wrestle" on the prompt). This service
	runs one Shared/ArmWrestleRules match per table: whoever sits or stands changes the match, ArmWrestleTap presses
	push, and a 0.1 s tick moves countdowns, pulls and results on. Everything shows through attributes:
	  * the table model: State, Progress (−1 … 1, side 1 ahead when positive), EndsAt (Workspace:GetServerTimeNow()),
	    Player1 / Player2 (UserIds, 0 = empty, −1 = the bot), Winner (side, 0 = draw), Champion (UserId), Streak;
	  * each wrestler's character: ArmWrestle = their own view of the progress (AnimationController poses the arm).
	A win adds to the winner's ArmWrestleWins stat (not in private servers, not against the bot). Nothing is paid.
	Developer panel: "Arm wrestle bot" puts a practice bot in the empty seat of the sender's table; it presses
	Config.Dev.ArmWrestleBotTaps times a second and leaves when the table empties.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArmWrestleRules = require(Shared:WaitForChild("ArmWrestleRules"))
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))

local TABLE_TAG = "ArmWrestleTable"
local SEAT_TAG = "ArmWrestleSeat"
local TICK_INTERVAL = 0.1
local BOT = ArmWrestleRules.Bot

type Table = {
	Model: Model,
	Seats: { [number]: Seat },
	Match: ArmWrestleRules.Match,
	BotPresses: number, -- presses the bot still owes (it presses ArmWrestleBotTaps a second)
}

local ArmWrestleService = {}

local tables: { Table } = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[ArmWrestle] {message}`)
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

-- Mirrors the match onto the table's attributes and the wrestlers' characters.
local function publish(entry: Table)
	local match, model = entry.Match, entry.Model
	model:SetAttribute("State", match.State)
	model:SetAttribute("Progress", math.round(match.Progress * 100) / 100)
	model:SetAttribute("EndsAt", match.EndsAt)
	model:SetAttribute("Player1", match.Players[1])
	model:SetAttribute("Player2", match.Players[2])
	model:SetAttribute("Winner", match.Winner)
	model:SetAttribute("Champion", match.Champion)
	model:SetAttribute("Streak", match.Streak)
	local active = match.State ~= "Waiting"
	for side = 1, 2 do
		local player = playerOn(entry, side)
		local character = player and player.Character
		if character then
			character:SetAttribute("ArmWrestle", if active then ArmWrestleRules.view(match.Progress, side) else nil)
		end
	end
end

-- A match ended (a pin or the time): the winner's stat, analytics, Output.
local function finished(entry: Table)
	local match = entry.Match
	local againstBot = match.Players[1] == BOT or match.Players[2] == BOT
	local winner = if match.Winner ~= 0 then playerOn(entry, match.Winner) else nil
	if winner and not againstBot and PrivateServerService.countsProgress() then
		DataService.incrementStat(winner, "ArmWrestleWins")
	end
	for side = 1, 2 do
		local player = playerOn(entry, side)
		if player then
			local outcome = if match.Winner == 0 then "Draw" elseif match.Winner == side then "Won" else "Lost"
			Analytics.custom(player, "ArmWrestle", 1, { outcome, if againstBot then "Bot" else "Player" })
		end
	end
	log(if match.Winner == 0 then "draw" else `{nameOf(entry, match.Winner)} wins (streak {match.Streak})`)
end

-- The seat on `side` changed hands.
local function onOccupant(entry: Table, side: number)
	local seat = entry.Seats[side]
	local humanoid = seat.Occupant
	local player = if humanoid then Players:GetPlayerFromCharacter(humanoid.Parent) else nil
	local before = playerOn(entry, side)
	if before and before ~= player and before.Character then
		before.Character:SetAttribute("ArmWrestle", nil)
	end
	local match = entry.Match
	if ArmWrestleRules.seat(match, side, if player then player.UserId else 0, now()) == "Cancelled" then
		log(`{if before then before.Name else "someone"} stood up: match cancelled`)
	end
	-- The bot only keeps someone company: it leaves when the other seat empties.
	local other = 3 - side
	if player == nil and match.Players[other] == BOT then
		ArmWrestleRules.seat(match, other, 0, now())
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
		warn(`[ArmWrestle] {model:GetFullName()} needs two ArmWrestleSeat seats (Side 1 and 2)`)
		return
	end
	local entry: Table = { Model = model, Seats = seats, Match = ArmWrestleRules.new(), BotPresses = 0 }
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

local function press(entry: Table, side: number)
	local _, event = ArmWrestleRules.tap(entry.Match, side, now())
	if event == "Finished" then
		finished(entry)
	end
	publish(entry)
end

-- Developer panel: a practice bot in the empty seat of `player`'s table. Returns whether one sat down.
function ArmWrestleService.addBot(player: Player): boolean
	local entry, side = seatOf(player)
	if entry == nil then
		log(`{player.Name} isn't at an arm-wrestling table: sit down first`)
		return false
	end
	local other = 3 - side
	if entry.Match.Players[other] ~= 0 then
		return false
	end
	entry.BotPresses = 0
	ArmWrestleRules.seat(entry.Match, other, BOT, now())
	publish(entry)
	log(`bot sits down opposite {player.Name}`)
	return true
end

local function tick()
	local t = now()
	for _, entry in tables do
		local match = entry.Match
		local event = ArmWrestleRules.tick(match, t)
		if event == "Finished" then
			finished(entry)
		end
		for side = 1, 2 do
			if match.Players[side] == BOT and match.State == "Pulling" then
				entry.BotPresses += Config.Dev.ArmWrestleBotTaps * TICK_INTERVAL
				while entry.BotPresses >= 1 and match.State == "Pulling" do
					entry.BotPresses -= 1
					press(entry, side)
				end
			end
		end
		publish(entry)
	end
end

function ArmWrestleService.Init(_self: any)
	Net.onServerEvent("ArmWrestleTap", function(player: Player)
		local entry, side = seatOf(player)
		if entry then
			press(entry, side)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, entry in tables do
			ArmWrestleRules.forget(entry.Match, player.UserId)
		end
	end)
end

function ArmWrestleService.Start(_self: any)
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

return ArmWrestleService
