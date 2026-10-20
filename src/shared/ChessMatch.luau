--!strict
--[[
	ChessMatch — one game of chess at a lobby table (Config.World.Chess): who sits where, the clocks, draw offers and
	how the game ended. Pure, shared (ChessService runs it; specs test it); the moves themselves are Shared/ChessRules.
	  * Side 1 (the west seat) plays White, side 2 Black. A game starts as soon as both seats are taken.
	  * Each side's clock runs on its own turn; a move adds Increment. A flag fall loses — or draws when the other side
	    has nothing left to checkmate with.
	  * Results: Checkmate, Resigned, Time, Left (standing up mid-game loses), and the draws Stalemate, Insufficient,
	    FiftyMoves, Repetition and Agreed (a draw offer the other side accepts; it lapses when they move instead).
	  * NewGameDelay after a game the next starts if both are still seated, otherwise the table waits.
	A side holds a UserId (0 = empty seat; ChessMatch.Bot = the developer panel's practice bot).
]]
local ChessRules = require(script.Parent.ChessRules)
local Config = require(script.Parent.Config)

export type State = "Waiting" | "Playing" | "Over"

export type Match = {
	State: State,
	Players: { number }, -- side (1 White, 2 Black) → UserId, 0 = empty
	GamePlayers: { number }, -- who played the current (or last) game, kept when one stands up
	Position: ChessRules.Position,
	History: { string }, -- position keys since the game began (threefold repetition)
	Clocks: { number }, -- seconds each side had left when the current turn began
	TurnStartedAt: number,
	LastMove: string, -- "e2e4", "" before the first move
	DrawOffer: number, -- the side offering a draw, 0 = none
	Result: string, -- how the game ended ("" while it goes on)
	Winner: number, -- the winning side, 0 = a draw
	EndsAt: number, -- Over: when the next game may start
}

local ChessMatch = {}

ChessMatch.Bot = -1
ChessMatch.Results = {
	"Checkmate",
	"Resigned",
	"Time",
	"Left",
	"Stalemate",
	"Insufficient",
	"FiftyMoves",
	"Repetition",
	"Agreed",
}
ChessMatch.Actions = { "Resign", "OfferDraw", "AcceptDraw" }

local function settings()
	return Config.World.Chess
end

function ChessMatch.new(): Match
	local position = ChessRules.new()
	return {
		State = "Waiting",
		Players = { 0, 0 },
		GamePlayers = { 0, 0 },
		Position = position,
		History = { ChessRules.key(position) },
		Clocks = { settings().TimePerSide, settings().TimePerSide },
		TurnStartedAt = 0,
		LastMove = "",
		DrawOffer = 0,
		Result = "",
		Winner = 0,
		EndsAt = 0,
	}
end

-- The side whose turn it is (1 White, 2 Black).
function ChessMatch.toMove(match: Match): number
	return if match.Position.Turn == "w" then 1 else 2
end

-- Seconds `side` has left at `now`.
function ChessMatch.remaining(match: Match, side: number, now: number): number
	local left = match.Clocks[side]
	if match.State == "Playing" and ChessMatch.toMove(match) == side then
		left -= now - match.TurnStartedAt
	end
	return math.max(left, 0)
end

local function start(match: Match, now: number)
	local position = ChessRules.new()
	match.State = "Playing"
	match.Position = position
	match.GamePlayers = { match.Players[1], match.Players[2] }
	match.History = { ChessRules.key(position) }
	match.Clocks = { settings().TimePerSide, settings().TimePerSide }
	match.TurnStartedAt = now
	match.LastMove = ""
	match.DrawOffer = 0
	match.Result = ""
	match.Winner = 0
	match.EndsAt = 0
end

local function finish(match: Match, result: string, winner: number, now: number)
	if match.State == "Playing" then
		-- Freeze the clocks where they stand.
		local side = ChessMatch.toMove(match)
		match.Clocks[side] = ChessMatch.remaining(match, side, now)
	end
	match.State = "Over"
	match.Result = result
	match.Winner = winner
	match.DrawOffer = 0
	match.EndsAt = now + settings().NewGameDelay
end

-- Someone sat down on `side` (their UserId) or stood up (0) at `now`. Returns "Started" when a game began, or
-- "Finished" when standing up lost one.
function ChessMatch.seat(match: Match, side: number, userId: number, now: number): string?
	local before = match.Players[side]
	match.Players[side] = userId
	if match.State == "Playing" and userId == 0 and before ~= 0 then
		finish(match, "Left", 3 - side, now)
		return "Finished"
	elseif match.State == "Waiting" and match.Players[1] ~= 0 and match.Players[2] ~= 0 then
		start(match, now)
		return "Started"
	end
	return nil
end

-- A move by `side` (squares "e2", "e4"; `promotion` "Q" / "R" / "B" / "N" when a pawn promotes) at `now`.
-- Returns whether it was played, and "Finished" when it (or the clock) ended the game.
function ChessMatch.move(
	match: Match,
	side: number,
	from: string,
	to: string,
	promotion: string?,
	now: number
): (boolean, string?)
	if match.State ~= "Playing" or ChessMatch.toMove(match) ~= side or match.Players[side] == 0 then
		return false, nil
	end
	if ChessMatch.remaining(match, side, now) <= 0 then
		return false, ChessMatch.tick(match, now)
	end
	local fromSquare, toSquare = ChessRules.square(from), ChessRules.square(to)
	local move = if fromSquare and toSquare
		then ChessRules.findMove(match.Position, fromSquare, toSquare, promotion)
		else nil
	if move == nil then
		return false, nil
	end
	match.Clocks[side] = ChessMatch.remaining(match, side, now) + settings().Increment
	match.TurnStartedAt = now
	match.Position = ChessRules.apply(match.Position, move)
	match.LastMove = ChessRules.notation(move)
	table.insert(match.History, ChessRules.key(match.Position))
	if match.DrawOffer == 3 - side then
		match.DrawOffer = 0 -- moving declines the other side's offer
	end
	local outcome = ChessRules.outcome(match.Position, match.History)
	if outcome then
		finish(match, outcome, if outcome == "Checkmate" then side else 0, now)
		return true, "Finished"
	end
	return true, nil
end

-- Resign, offer a draw, or accept the other side's offer. Returns "Finished" when the game ended.
function ChessMatch.act(match: Match, side: number, action: string, now: number): string?
	if match.State ~= "Playing" or match.Players[side] == 0 then
		return nil
	end
	if action == "Resign" then
		finish(match, "Resigned", 3 - side, now)
		return "Finished"
	elseif action == "OfferDraw" and match.DrawOffer == 0 then
		match.DrawOffer = side
	elseif action == "AcceptDraw" and match.DrawOffer == 3 - side then
		finish(match, "Agreed", 0, now)
		return "Finished"
	end
	return nil
end

-- Moves the table on at `now`: "Finished" when a flag fell, "Started" when the next game began.
function ChessMatch.tick(match: Match, now: number): string?
	if match.State == "Playing" then
		local side = ChessMatch.toMove(match)
		if ChessMatch.remaining(match, side, now) <= 0 then
			local otherSide = 3 - side
			local otherColor = if otherSide == 1 then "w" else "b"
			finish(match, "Time", if ChessRules.canMate(match.Position.Board, otherColor) then otherSide else 0, now)
			return "Finished"
		end
	elseif match.State == "Over" and now >= match.EndsAt then
		if match.Players[1] ~= 0 and match.Players[2] ~= 0 then
			start(match, now)
			return "Started"
		end
		match.State = "Waiting"
	end
	return nil
end

return ChessMatch
