--!strict
--[[
	Scoreboard — one round's participants and the mode's scoring rules (pure: times are passed in).

	Every KO a fighter takes is a fall. The credited attacker gets the KO, plus KO Scrap at the KO streak they had at
	that moment (Formulas.koScrap); being KO'd resets your streak.
	  * Classic (mode has Lives): a KO costs a life; at 0 lives the fighter is eliminated. Standings: fighters still in
	    first (most KOs, then fewest falls), then the eliminated (eliminated later = higher).
	  * Casual (no Lives): score = KOs − falls. Standings: score, then KOs, then fewest falls.
	Equal records share a placement (1, 1, 3, ...). Players who left mid-round are not ranked.
	Active time only grows while a fighter is still in and not AFK (no input for AFKTimeout seconds).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))

export type Entry = {
	UserId: number,
	Name: string,
	JoinOrder: number,
	Lives: number?, -- modes with lives (Classic)
	KOs: number,
	Falls: number,
	RingOuts: number, -- KOs made by knocking someone out of the arena
	PerfectDodges: number,
	KOStreak: number, -- KOs since this fighter was last KO'd
	KOScrap: number, -- Scrap earned from KOs (streak applied at the time of each KO)
	Eliminated: boolean,
	EliminatedAt: number?,
	Left: boolean, -- left the server during the round
	ActiveSeconds: number,
	LastActiveAt: number,
}

export type Board = {
	ModeId: string,
	Entries: { [number]: Entry }, -- by UserId
	Joined: number,
}

export type Standing = { Entry: Entry, Placement: number }

local Scoreboard = {}

function Scoreboard.new(modeId: string): Board
	assert(Config.Modes.List[modeId], `Unknown mode "{modeId}"`)
	return { ModeId = modeId, Entries = {}, Joined = 0 }
end

-- Adds a participant (round start, or a Casual late joiner). Returns the existing entry if already in.
function Scoreboard.add(board: Board, userId: number, name: string, now: number): Entry
	local existing = board.Entries[userId]
	if existing then
		existing.Left = false
		return existing
	end
	board.Joined += 1
	local entry: Entry = {
		UserId = userId,
		Name = name,
		JoinOrder = board.Joined,
		Lives = Config.Modes.List[board.ModeId].Lives,
		KOs = 0,
		Falls = 0,
		RingOuts = 0,
		PerfectDodges = 0,
		KOStreak = 0,
		KOScrap = 0,
		Eliminated = false,
		EliminatedAt = nil,
		Left = false,
		ActiveSeconds = 0,
		LastActiveAt = now,
	}
	board.Entries[userId] = entry
	return entry
end

function Scoreboard.get(board: Board, userId: number): Entry?
	return board.Entries[userId]
end

-- True while the participant is still competing (not eliminated, still in the server).
function Scoreboard.isIn(entry: Entry): boolean
	return not entry.Eliminated and not entry.Left
end

-- Records a KO. `killerId` is the credited attacker (nil for a self-KO); `ringOut` = knocked out of the arena.
-- Returns the victim's entry (nil if the victim is not on the board).
function Scoreboard.recordKO(board: Board, victimId: number, killerId: number?, ringOut: boolean, now: number): Entry?
	local victim = board.Entries[victimId]
	if victim == nil or not Scoreboard.isIn(victim) then
		return nil
	end
	victim.Falls += 1
	victim.KOStreak = 0
	local lives = victim.Lives
	if lives then
		victim.Lives = math.max(lives - 1, 0)
		if lives - 1 <= 0 then
			victim.Eliminated = true
			victim.EliminatedAt = now
		end
	end
	local killer = if killerId and killerId ~= victimId then board.Entries[killerId] else nil
	if killer and not killer.Left then
		killer.KOScrap += Formulas.koScrap(killer.KOStreak)
		killer.KOStreak += 1
		killer.KOs += 1
		if ringOut then
			killer.RingOuts += 1
		end
	end
	return victim
end

function Scoreboard.recordPerfectDodge(board: Board, userId: number)
	local entry = board.Entries[userId]
	if entry and Scoreboard.isIn(entry) then
		entry.PerfectDodges += 1
	end
end

function Scoreboard.leave(board: Board, userId: number)
	local entry = board.Entries[userId]
	if entry then
		entry.Left = true
	end
end

function Scoreboard.markActive(board: Board, userId: number, now: number)
	local entry = board.Entries[userId]
	if entry then
		entry.LastActiveAt = now
	end
end

function Scoreboard.isAFK(entry: Entry, now: number): boolean
	return now - entry.LastActiveAt >= Config.Round.Participation.AFKTimeout
end

-- Adds `dt` seconds of active time to every participant still in and not AFK.
function Scoreboard.tick(board: Board, dt: number, now: number)
	for _, entry in board.Entries do
		if Scoreboard.isIn(entry) and not Scoreboard.isAFK(entry, now) then
			entry.ActiveSeconds += dt
		end
	end
end

-- Participants still competing.
function Scoreboard.remaining(board: Board): number
	local count = 0
	for _, entry in board.Entries do
		if Scoreboard.isIn(entry) then
			count += 1
		end
	end
	return count
end

-- Classic ends early once one fighter is left (or none, if the round started with only one).
-- Every mode ends when nobody is left.
function Scoreboard.isDecided(board: Board, startedWith: number): boolean
	local remaining = Scoreboard.remaining(board)
	if Config.Modes.List[board.ModeId].Lives ~= nil then
		return remaining <= (if startedWith >= 2 then 1 else 0)
	end
	return remaining == 0
end

function Scoreboard.score(entry: Entry): number
	return entry.KOs - entry.Falls
end

-- Negative when `a` ranks above `b`, positive when below, 0 when they share a placement.
local function compare(board: Board, a: Entry, b: Entry): number
	if Config.Modes.List[board.ModeId].Lives ~= nil then
		if a.Eliminated ~= b.Eliminated then
			return if a.Eliminated then 1 else -1
		end
		if a.Eliminated then
			return (b.EliminatedAt or 0) - (a.EliminatedAt or 0)
		end
	else
		local byScore = Scoreboard.score(b) - Scoreboard.score(a)
		if byScore ~= 0 then
			return byScore
		end
	end
	if a.KOs ~= b.KOs then
		return b.KOs - a.KOs
	end
	return a.Falls - b.Falls
end

-- Everyone still in the server, best first, with placements (ties share one).
function Scoreboard.standings(board: Board): { Standing }
	local entries: { Entry } = {}
	for _, entry in board.Entries do
		if not entry.Left then
			table.insert(entries, entry)
		end
	end
	table.sort(entries, function(a: Entry, b: Entry): boolean
		local order = compare(board, a, b)
		if order ~= 0 then
			return order < 0
		end
		return a.JoinOrder < b.JoinOrder
	end)
	local standings: { Standing } = {}
	for index, entry in entries do
		local placement = index
		local previous = standings[index - 1]
		if previous and compare(board, previous.Entry, entry) == 0 then
			placement = previous.Placement
		end
		table.insert(standings, { Entry = entry, Placement = placement })
	end
	return standings
end

return Scoreboard
