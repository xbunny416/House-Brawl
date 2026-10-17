--!strict
-- Private servers (step 3.2): what the owner can set, saved values, the locked ballot; nothing is earned there.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local PrivateServerRules = Roblox.require(Shared.PrivateServerRules)

local MAPS = { "BrokenHighway", "JunkyardIsles" }

return {
	["defaults: everything by vote, the normal round length (one of the choices)"] = function()
		local defaults = PrivateServerRules.defaults()
		expect.equal(defaults.Mode, PrivateServerRules.Vote)
		expect.equal(defaults.Map, PrivateServerRules.Vote)
		expect.equal(defaults.RoundTime, Config.Round.RoundTime)
		expect.truthy(table.find(Config.Round.PrivateRoundTimes, Config.Round.RoundTime), "default is a choice")
		expect.equal(Config.Economy.PrivateServerRewardScale, 0, "owner: no rewards in private servers")
		expect.equal(Config.Economy.PrivateServerProgress, false, "owner: no stats in private servers")
	end,
	["valid values: a mode or map id (map enabled) or Vote, and a listed round length"] = function()
		expect.truthy(PrivateServerRules.isValid("Mode", "Classic", MAPS))
		expect.truthy(PrivateServerRules.isValid("Mode", "Vote", MAPS))
		expect.equal(PrivateServerRules.isValid("Mode", "Nope", MAPS), false)
		expect.truthy(PrivateServerRules.isValid("Map", "JunkyardIsles", MAPS))
		expect.equal(PrivateServerRules.isValid("Map", "NeonMotel", MAPS), false, "not enabled")
		expect.equal(PrivateServerRules.isValid("Map", "Hideout", MAPS), false, "the lobby")
		expect.truthy(PrivateServerRules.isValid("RoundTime", 120, MAPS))
		expect.equal(PrivateServerRules.isValid("RoundTime", 999, MAPS), false)
		expect.equal(PrivateServerRules.isValid("RoundTime", "120", MAPS), false, "wrong type")
		expect.equal(PrivateServerRules.isValid("Mode", 1, MAPS), false, "wrong type")
		expect.equal(PrivateServerRules.isValid("Lives", 5, MAPS), false, "unknown key")
	end,
	["saved settings keep valid values and fall back to defaults for the rest"] = function()
		local settings = PrivateServerRules.sanitize({ Mode = "Casual", Map = "NeonMotel", RoundTime = 300 }, MAPS)
		expect.equal(settings.Mode, "Casual")
		expect.equal(settings.Map, PrivateServerRules.Vote, "a map no longer enabled")
		expect.equal(settings.RoundTime, 300)
		local empty = PrivateServerRules.sanitize(nil, MAPS)
		expect.equal(empty.RoundTime, Config.Round.RoundTime)
	end,
	["the ballot: a locked choice is the only option, Vote keeps the vote's options"] = function()
		local options = PrivateServerRules.options("Casual", { "Classic", "Casual" })
		expect.equal(#options, 1)
		expect.equal(options[1], "Casual")
		local voted = PrivateServerRules.options(PrivateServerRules.Vote, { "Classic", "Casual" })
		expect.equal(#voted, 2)
	end,
}
