--!strict
-- Global leaderboards (step 3.6): boards, scores, weekly roll-over, ordering.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local LeaderboardRules = Roblox.require(Shared.LeaderboardRules)
local Template = Roblox.require(Shared.Data.Template).Template

local WEEK = 2900

local function data(fields: { [string]: any }?)
	local copy = table.clone(Template)
	copy.Stats = table.clone(Template.Stats)
	copy.LeaderboardWeek = table.clone(Template.LeaderboardWeek)
	for key, value in fields or {} do
		(copy :: any)[key] = value
	end
	return copy
end

return {
	["boards: Wins, KOs and Level, all-time and weekly; a new weekly store every week"] = function()
		expect.equal(table.concat(Config.Retention.Leaderboards.Stats, ","), "Wins,KOs,Level")
		expect.equal(LeaderboardRules.key("Wins", "AllTime"), "Wins.AllTime")
		expect.equal(LeaderboardRules.storeName("Wins", "AllTime", WEEK), "Leaderboard_Wins")
		expect.equal(LeaderboardRules.storeName("KOs", "Weekly", WEEK), "Leaderboard_KOs_W2900")
		expect.truthy(
			LeaderboardRules.storeName("KOs", "Weekly", WEEK) ~= LeaderboardRules.storeName("KOs", "Weekly", WEEK + 1)
		)
		local stats = table.clone(Template.Stats)
		for _, stat in Config.Retention.Leaderboards.Stats do
			expect.truthy(stat == "Level" or stats[stat] ~= nil, `{stat} is a stat`)
		end
	end,
	["all-time scores are the lifetime stats and the level"] = function()
		local player = data({ Level = 12 })
		player.Stats.Wins = 7
		player.Stats.KOs = 40
		expect.equal(LeaderboardRules.score(player, "Wins", "AllTime", WEEK), 7)
		expect.equal(LeaderboardRules.score(player, "KOs", "AllTime", WEEK), 40)
		expect.equal(LeaderboardRules.score(player, "Level", "AllTime", WEEK), 12)
	end,
	["weekly scores count from the week's start and start over in a new week"] = function()
		local player = data({ Level = 12 })
		player.LeaderboardWeek = LeaderboardRules.addToWeek(player.LeaderboardWeek, WEEK, 10, "Wins", 2)
		player.LeaderboardWeek = LeaderboardRules.addToWeek(player.LeaderboardWeek, WEEK, 10, "KOs", 5)
		player.LeaderboardWeek = LeaderboardRules.addToWeek(player.LeaderboardWeek, WEEK, 11, "Falls", 9)
		expect.equal(LeaderboardRules.score(player, "Wins", "Weekly", WEEK), 2)
		expect.equal(LeaderboardRules.score(player, "KOs", "Weekly", WEEK), 5)
		expect.equal(LeaderboardRules.score(player, "Level", "Weekly", WEEK), 2, "levels gained since level 10")
		expect.equal(LeaderboardRules.score(player, "Wins", "Weekly", WEEK + 1), 0, "a new week")
		expect.equal(LeaderboardRules.score(player, "Level", "Weekly", WEEK + 1), 0)
		local fresh = LeaderboardRules.currentWeek(player.LeaderboardWeek, WEEK + 1, 12)
		expect.equal(fresh.StartLevel, 12)
		expect.equal(player.LeaderboardWeek.Week, WEEK, "never mutates")
	end,
	["top: best first, ties by UserId, no zero scores, capped"] = function()
		local top = LeaderboardRules.top({
			{ UserId = 5, Name = "E", Value = 3 },
			{ UserId = 2, Name = "B", Value = 9 },
			{ UserId = 9, Name = "I", Value = 3 },
			{ UserId = 1, Name = "A", Value = 0 },
			{ UserId = 7, Name = "G", Value = 1 },
		}, 3)
		expect.equal(#top, 3)
		expect.equal(top[1].UserId, 2)
		expect.equal(top[2].UserId, 5, "tie: lower UserId first")
		expect.equal(top[3].UserId, 9)
	end,
}
