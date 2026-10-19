--!strict
-- Round start spawns (Round/SpawnPlan): fighters spread over the platforms, groups stay together.
local Roblox = require("../roblox")
local expect = require("../expect")

local SpawnPlan = Roblox.require(Roblox.game.ServerScriptService.Server.Round.SpawnPlan)

-- A "random" pick that always takes the first option (deterministic plans).
local function first(_count: number): number
	return 1
end

return {
	["solo fighters spread out (the roomiest platform each time), one fighter per point"] = function()
		local platforms = { "A", "A", "A", "B", "B", "C" }
		local plan = SpawnPlan.assign({ { 1 }, { 2 }, { 3 }, { 4 } }, platforms, first)
		local used: { [number]: boolean } = {}
		local perPlatform: { [string]: number } = {}
		for userId = 1, 4 do
			expect.equal(used[plan[userId]], nil, "one fighter per point")
			used[plan[userId]] = true
			local platform = platforms[plan[userId]]
			perPlatform[platform] = (perPlatform[platform] or 0) + 1
		end
		expect.truthy((perPlatform.A or 0) <= 2, "not everyone on the biggest platform")
		expect.truthy((perPlatform.B or 0) >= 1, "the next platform gets fighters too")
	end,
	["a group starts on one platform; points are reused when there are more fighters than points"] = function()
		local platforms = { "A", "A", "A", "B", "B", "C" }
		local plan = SpawnPlan.assign({ { 1, 2, 3 }, { 4 } }, platforms, first)
		expect.equal(platforms[plan[1]], "A")
		expect.equal(platforms[plan[2]], "A")
		expect.equal(platforms[plan[3]], "A")
		local crowded = SpawnPlan.assign({ { 1 }, { 2 }, { 3 } }, { "A", "B" }, first)
		expect.truthy(crowded[1] and crowded[2] and crowded[3], "everyone gets a point")
		expect.equal(next(SpawnPlan.assign({ { 1 } }, {}, first)), nil, "no points, no plan")
	end,
}
