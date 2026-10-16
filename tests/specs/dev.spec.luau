--!strict
-- Developer panel (step 1.13): who may use it, and the Percent / HP setters it calls.
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local Server = Roblox.game.ServerScriptService.Server
local DevRules = Roblox.require(Server.Dev.DevRules)
local Fighter = Roblox.require(Server.Combat.Fighter)

return {
	["anyone in Studio; in live servers only the allowlist (empty for now: owner's choice)"] = function()
		expect.equal(Config.Dev.AllowInStudio, true)
		expect.equal(DevRules.isAllowed(12345, true), true)
		expect.equal(#Config.Dev.AllowedUserIds, 0)
		expect.equal(DevRules.isAllowed(12345, false), false)
	end,
	["every command name fits the DevCommand argument limit"] = function()
		for _, name in DevRules.Commands do
			expect.truthy(#name <= 24, name)
		end
	end,
	["set Percent: Casual clamps to the cap; Classic sets the HP that gives it"] = function()
		local casual = Fighter.new("Casual")
		Fighter.setPercent(casual, 500)
		expect.equal(casual.Percent, Config.Modes.List.Casual.PercentCap)
		local classic = Fighter.new("Classic")
		Fighter.setPercent(classic, 60)
		expect.equal(classic.Health, 60)
		expect.equal(classic.Percent, 60)
	end,
	["set HP: modes with HP only, never below 1 (no KO from the panel)"] = function()
		local classic = Fighter.new("Classic")
		Fighter.setHealth(classic, 0)
		expect.equal(classic.Health, 1)
		expect.equal(classic.Defeated, false)
		Fighter.setHealth(classic, 500)
		expect.equal(classic.Health, 100)
		expect.equal(classic.Percent, 0)
		local casual = Fighter.new("Casual")
		Fighter.setHealth(casual, 50)
		expect.equal(casual.Percent, 0, "no HP in Casual")
	end,
}
