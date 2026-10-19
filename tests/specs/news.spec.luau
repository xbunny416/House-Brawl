--!strict
-- Lobby news TVs (owner's fix list, 2026-10-19): fun headlines mixed with live news; every headline has its string.
local fs = require("@lune/fs")
local csv = require("../../tools/csv")
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local NewsRules = Roblox.require(Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib.NewsRules)

local function keysOf(headlines: { any }): string
	local keys = {}
	for _, headline in headlines do
		table.insert(keys, headline.Key)
	end
	return table.concat(keys, ",")
end

return {
	["no live news: the fun headlines in order"] = function()
		expect.equal(keysOf(NewsRules.headlines({}, 3)), "News.1,News.2,News.3")
	end,
	["live news comes after each fun headline, with its values"] = function()
		local headlines = NewsRules.headlines({
			Winner = { Name = "Alex", Map = "Neon Motel" },
			Deal = { Item = "Cone Hat", Price = "240" },
			Leader = { Name = "Sam", Value = "1,204" },
		}, 4)
		expect.equal(keysOf(headlines), "News.1,News.Winner,News.2,News.Deal,News.3,News.Leader,News.4")
		expect.equal(table.concat(headlines[2].Args, "|"), "Alex|Neon Motel")
		expect.equal(table.concat(headlines[6].Args, "|"), "Sam|1,204")
		expect.equal(
			keysOf(NewsRules.headlines({ Leader = { Name = "Sam", Value = "3" } }, 2)),
			"News.1,News.Leader,News.2"
		)
	end,
	["every fun and live headline has its string"] = function()
		local rows = csv.parse(fs.readFile("src/localization/GameStrings.csv"))
		local keys: { [string]: boolean } = {}
		for index = 2, #rows do
			keys[rows[index][1]] = true
		end
		for index = 1, Config.World.News.Headlines do
			expect.truthy(keys[`News.{index}`], `News.{index}`)
		end
		for _, key in NewsRules.LiveKeys do
			expect.truthy(keys[key], key)
		end
		expect.truthy(Config.World.News.Interval > 0 and Config.World.News.TickerSpeed > 0, "news timing")
	end,
}
