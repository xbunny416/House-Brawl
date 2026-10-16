--!strict
-- Round rules (step 1.8): map/mode vote, Classic lives and standings, Casual scoring, KO streak Scrap, active time.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local RoundFolder = Roblox.game.ServerScriptService.Server.Round
local Config = Roblox.require(Shared.Config)
local Formulas = Roblox.require(Shared.Formulas)
local Vote = Roblox.require(RoundFolder.Vote)
local Scoreboard = Roblox.require(RoundFolder.Scoreboard)

local function first(_count: number): number
	return 1
end

local function last(count: number): number
	return count
end

local function placements(board: any): { [string]: number }
	local result: { [string]: number } = {}
	for _, standing in Scoreboard.standings(board) do
		result[standing.Entry.Name] = standing.Placement
	end
	return result
end

return {
	-- Vote ------------------------------------------------------------------------------------------------------------
	["vote: most votes wins; players can change their vote; unknown options are refused"] = function()
		local vote = Vote.new({ "BrokenHighway", "NeonMotel" })
		expect.equal(Vote.cast(vote, 1, "NeonMotel"), true)
		expect.equal(Vote.cast(vote, 2, "NeonMotel"), true)
		expect.equal(Vote.cast(vote, 3, "BrokenHighway"), true)
		expect.equal(Vote.cast(vote, 4, "Moon"), false)
		expect.equal(Vote.winner(vote, first), "NeonMotel")
		Vote.cast(vote, 1, "BrokenHighway")
		expect.equal(Vote.counts(vote).BrokenHighway, 2)
		expect.equal(Vote.winner(vote, first), "BrokenHighway")
		Vote.remove(vote, 1)
		Vote.remove(vote, 3)
		expect.equal(Vote.counts(vote).BrokenHighway, 0)
		expect.equal(Vote.winner(vote, last), "NeonMotel")
	end,
	["vote: ties and empty votes are settled at random among the leaders"] = function()
		local vote = Vote.new({ "Classic", "Casual" })
		expect.equal(Vote.winner(vote, first), "Classic")
		expect.equal(Vote.winner(vote, last), "Casual")
		Vote.cast(vote, 1, "Classic")
		Vote.cast(vote, 2, "Casual")
		expect.equal(Vote.winner(vote, last), "Casual")
		Vote.cast(vote, 3, "Classic")
		expect.equal(Vote.winner(vote, last), "Classic")
	end,
	["vote options: up to N different maps"] = function()
		local options = Vote.pickOptions({ "A", "B", "C", "D" }, 3, first)
		expect.equal(table.concat(options, ","), "A,B,C")
		expect.equal(#Vote.pickOptions({ "A" }, 3, first), 1)
	end,

	-- Classic ---------------------------------------------------------------------------------------------------------
	["classic: 3 lives, eliminated on the third KO, last fighter standing decides the round"] = function()
		local board = Scoreboard.new("Classic")
		Scoreboard.add(board, 1, "Ann", 0)
		Scoreboard.add(board, 2, "Bob", 0)
		Scoreboard.add(board, 3, "Cat", 0)
		expect.equal(Scoreboard.get(board, 1).Lives, Config.Modes.List.Classic.Lives)
		Scoreboard.recordKO(board, 2, 1, true, 10)
		Scoreboard.recordKO(board, 2, 1, true, 20)
		local bob = Scoreboard.recordKO(board, 2, 3, false, 30)
		expect.equal(bob.Eliminated, true)
		expect.equal(bob.Lives, 0)
		expect.equal(Scoreboard.recordKO(board, 2, 1, true, 31), nil, "already out")
		expect.equal(Scoreboard.isDecided(board, 3), false)
		for t = 40, 42 do
			Scoreboard.recordKO(board, 3, 1, true, t)
		end
		expect.equal(Scoreboard.isDecided(board, 3), true)
		local standings = placements(board)
		expect.equal(standings.Ann, 1)
		expect.equal(standings.Cat, 2, "eliminated later ranks higher")
		expect.equal(standings.Bob, 3)
		expect.equal(Scoreboard.get(board, 1).RingOuts, 5)
	end,
	["classic time-out: survivors by KOs then fewest falls, above the eliminated"] = function()
		local board = Scoreboard.new("Classic")
		for id, name in { "Ann", "Bob", "Cat", "Dan" } do
			Scoreboard.add(board, id, name, 0)
		end
		Scoreboard.recordKO(board, 2, 1, true, 1) -- Ann 1 KO, Bob 1 fall
		Scoreboard.recordKO(board, 4, 2, true, 2) -- Bob 1 KO
		Scoreboard.recordKO(board, 4, 3, true, 3)
		Scoreboard.recordKO(board, 4, 3, true, 4) -- Dan eliminated, Cat 2 KOs
		local standings = placements(board)
		expect.equal(standings.Cat, 1)
		expect.equal(standings.Ann, 2, "1 KO, 0 falls")
		expect.equal(standings.Bob, 3, "1 KO, 1 fall")
		expect.equal(standings.Dan, 4)
	end,
	["classic solo round only ends when the fighter is out"] = function()
		local board = Scoreboard.new("Classic")
		Scoreboard.add(board, 1, "Ann", 0)
		expect.equal(Scoreboard.isDecided(board, 1), false)
		for t = 1, 3 do
			Scoreboard.recordKO(board, 1, nil, true, t)
		end
		expect.equal(Scoreboard.isDecided(board, 1), true)
	end,

	-- Casual ----------------------------------------------------------------------------------------------------------
	["casual: unlimited lives, score = KOs - falls, ties share a placement"] = function()
		local board = Scoreboard.new("Casual")
		for id, name in { "Ann", "Bob", "Cat" } do
			Scoreboard.add(board, id, name, 0)
		end
		for t = 1, 5 do
			Scoreboard.recordKO(board, 2, 1, true, t)
		end
		expect.equal(Scoreboard.get(board, 2).Eliminated, false)
		expect.equal(Scoreboard.get(board, 2).Lives, nil)
		Scoreboard.recordKO(board, 1, 3, false, 6)
		expect.equal(Scoreboard.score(Scoreboard.get(board, 1)), 4)
		expect.equal(Scoreboard.score(Scoreboard.get(board, 2)), -5)
		local standings = placements(board)
		expect.equal(standings.Ann, 1)
		expect.equal(standings.Cat, 2)
		expect.equal(standings.Bob, 3)
		expect.equal(Scoreboard.isDecided(board, 3), false)

		local tied = Scoreboard.new("Casual")
		Scoreboard.add(tied, 1, "Ann", 0)
		Scoreboard.add(tied, 2, "Bob", 0)
		local tie = placements(tied)
		expect.equal(tie.Ann, 1)
		expect.equal(tie.Bob, 1)
	end,
	["players who left are not ranked; nobody left ends the round"] = function()
		local board = Scoreboard.new("Casual")
		Scoreboard.add(board, 1, "Ann", 0)
		Scoreboard.add(board, 2, "Bob", 0)
		Scoreboard.leave(board, 2)
		expect.equal(#Scoreboard.standings(board), 1)
		expect.equal(Scoreboard.isDecided(board, 2), false)
		Scoreboard.leave(board, 1)
		expect.equal(Scoreboard.isDecided(board, 2), true)
	end,

	-- Streaks and activity --------------------------------------------------------------------------------------------
	["KO Scrap uses the streak at each KO; being KO'd resets it; self-KOs credit nobody"] = function()
		local board = Scoreboard.new("Casual")
		Scoreboard.add(board, 1, "Ann", 0)
		Scoreboard.add(board, 2, "Bob", 0)
		local expected = 0
		for streak = 0, 6 do
			Scoreboard.recordKO(board, 2, 1, false, streak)
			expected += Formulas.koScrap(streak)
		end
		local ann = Scoreboard.get(board, 1)
		expect.equal(ann.KOScrap, expected)
		expect.equal(ann.KOStreak, 7)
		Scoreboard.recordKO(board, 1, nil, true, 10)
		expect.equal(ann.KOStreak, 0)
		expect.equal(Scoreboard.get(board, 2).KOs, 0, "no credit for a self-KO")
	end,
	["active time only counts while in and not AFK"] = function()
		local afk = Config.Round.Participation.AFKTimeout
		local board = Scoreboard.new("Classic")
		Scoreboard.add(board, 1, "Ann", 0)
		Scoreboard.tick(board, 10, 10)
		expect.equal(Scoreboard.get(board, 1).ActiveSeconds, 10)
		Scoreboard.tick(board, 10, afk + 1)
		expect.equal(Scoreboard.get(board, 1).ActiveSeconds, 10, "AFK")
		Scoreboard.markActive(board, 1, afk + 2)
		Scoreboard.tick(board, 5, afk + 3)
		expect.equal(Scoreboard.get(board, 1).ActiveSeconds, 15)
		Scoreboard.recordPerfectDodge(board, 1)
		expect.equal(Scoreboard.get(board, 1).PerfectDodges, 1)
	end,
}
