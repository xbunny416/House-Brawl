--!strict
-- Crumbling platforms (step 1.11): schedule from 1:00 every 20 s, the center never falls, at least 2 stay.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local CrumbleRules = Roblox.require(Roblox.game.ServerScriptService.Server.Round.CrumbleRules)

local function first(_count: number): number
	return 1
end

local function arena(): { any }
	local platforms = { { Id = "Center", CanFall = false, Fallen = false } }
	for _, id in { "North", "East", "South", "West", "LedgeNE", "LedgeSW" } do
		table.insert(platforms, { Id = id, CanFall = true, Fallen = false })
	end
	return platforms
end

return {
	["schedule: first crumble at 1:00, then every 20 s"] = function()
		expect.equal(CrumbleRules.timeOf(1), 60)
		expect.equal(CrumbleRules.timeOf(2), 80)
		expect.equal(CrumbleRules.timeOf(7), 180)
		expect.equal(Config.Round.Crumble.WarningTime, 3)
	end,
	["the center never falls and at least 2 platforms always remain"] = function()
		local platforms = arena()
		local fallen = 0
		while true do
			local id = CrumbleRules.pick(platforms, first)
			if id == nil then
				break
			end
			expect.truthy(id ~= "Center", "center picked")
			for _, platform in platforms do
				if platform.Id == id then
					expect.equal(platform.Fallen, false, `{id} picked twice`)
					platform.Fallen = true
				end
			end
			fallen += 1
		end
		local standing = 0
		for _, platform in platforms do
			if not platform.Fallen then
				standing += 1
			end
		end
		expect.equal(standing, Config.Round.Crumble.MinPlatformsRemaining)
		expect.equal(fallen, #platforms - Config.Round.Crumble.MinPlatformsRemaining)
	end,
	["nothing falls when only the minimum is left or nothing can fall"] = function()
		expect.equal(CrumbleRules.pick({ { Id = "Center", CanFall = false, Fallen = false } }, first), nil)
		local two = {
			{ Id = "Center", CanFall = false, Fallen = false },
			{ Id = "East", CanFall = true, Fallen = false },
		}
		expect.equal(CrumbleRules.pick(two, first), nil)
	end,
}
