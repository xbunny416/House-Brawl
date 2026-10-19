--!strict
-- Crumbling platforms (step 1.11): schedule from 1:00 every 20 s, the center never falls, at least 2 stay; the arena
-- closes in from the outer ring toward the centre (owner's fix list, 2026-10-19).
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local CrumbleRules = Roblox.require(Roblox.game.ServerScriptService.Server.Round.CrumbleRules)

local function first(_count: number): number
	return 1
end

-- Distances from the arena's centre like Broken Highway's: sides about 140-180, ledges 187, peaks and lows 260+.
local function arena(): { any }
	local platforms = { { Id = "Center", CanFall = false, Fallen = false, Distance = 0 } }
	for _, entry in
		{
			{ "North", 140 },
			{ "South", 138 },
			{ "East", 179 },
			{ "West", 177 },
			{ "LedgeNE", 187 },
			{ "LedgeSW", 187 },
			{ "PeakNE", 259 },
			{ "LowEast", 265 },
		}
	do
		table.insert(platforms, { Id = entry[1], CanFall = true, Fallen = false, Distance = entry[2] })
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
		expect.equal(
			CrumbleRules.pick({ { Id = "Center", CanFall = false, Fallen = false, Distance = 0 } }, first),
			nil
		)
		local two = {
			{ Id = "Center", CanFall = false, Fallen = false, Distance = 0 },
			{ Id = "East", CanFall = true, Fallen = false, Distance = 100 },
		}
		expect.equal(CrumbleRules.pick(two, first), nil)
	end,
	["the arena closes in: the outer ring falls first, then the next ring in, the middle last"] = function()
		local platforms = arena()
		local order: { string } = {}
		local last = math.huge
		while true do
			-- Always take the last one the ring offers: the order inside a ring is random, between rings it is not.
			local id = CrumbleRules.pick(platforms, function(count: number): number
				return count
			end)
			if id == nil then
				break
			end
			for _, platform in platforms do
				if platform.Id == id then
					platform.Fallen = true
					expect.truthy(
						platform.Distance <= last + Config.Round.Crumble.RingWidth,
						`{id} fell after a platform more than a ring further in`
					)
					last = math.min(last, platform.Distance)
				end
			end
			table.insert(order, id)
		end
		local firstTwo = { order[1], order[2] }
		table.sort(firstTwo)
		expect.equal(table.concat(firstTwo, ","), "LowEast,PeakNE", "the far peak and low go first")
		expect.equal(#order, #platforms - Config.Round.Crumble.MinPlatformsRemaining)
		local finalPick = order[#order]
		expect.truthy(finalPick == "North" or finalPick == "South", `the innermost ring goes last, not {finalPick}`)
	end,
}
