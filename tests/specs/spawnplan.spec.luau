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
	["one platform with positions: fighters start at the points nearest a random one"] = function()
		-- Points along a line; with `first` the "random" focus is point 5 (x = 100), so 0, 50 and 100 are nearest.
		local platforms = { "Center", "Center", "Center", "Center", "Center" }
		local positions = { { 300, 0, 0 }, { 400, 0, 0 }, { 0, 0, 0 }, { 50, 0, 0 }, { 100, 0, 0 } }
		local plan = SpawnPlan.assign({ { 1 }, { 2 }, { 3 } }, platforms, first, positions)
		local xs: { number } = {}
		for userId = 1, 3 do
			table.insert(xs, positions[plan[userId]][1])
		end
		table.sort(xs)
		local spread = xs[3] - xs[1]
		expect.truthy(spread <= 100, `three fighters start within 100 studs (spread {spread})`)
		-- Several platforms keep the spread-out rule (positions don't matter there).
		local multi = SpawnPlan.assign({ { 1 }, { 2 } }, { "A", "B" }, first, positions)
		expect.truthy(multi[1] ~= multi[2], "two platforms: one fighter on each")
	end,
	["a respawn comes back near the fight but not on top of anyone"] = function()
		local band = { MinEnemyDistance = 40, MaxEnemyDistance = 130 }
		local points = { { 0, 0, 0 }, { 60, 0, 0 }, { 300, 0, 0 }, { 500, 0, 0 } }
		-- An enemy at x = 10: the point at 0 is too close, 300 and 500 too far; 60 is in the band.
		expect.equal(SpawnPlan.respawn(points, { { 10, 0, 0 } }, band, first), 2)
		-- Enemies at 0 and 250: 60 is 60 from the first, 300 is 50 from the second; both are in the band.
		local both = SpawnPlan.respawn(points, { { 0, 0, 0 }, { 250, 0, 0 } }, band, first)
		expect.truthy(both == 2 or both == 3, "a point in the band")
		-- Nothing in the band: the nearest point that is still at least the minimum away.
		local far = { { 0, 0, 0 }, { 200, 0, 0 }, { 400, 0, 0 } }
		expect.equal(SpawnPlan.respawn(far, { { 5, 0, 0 } }, band, first), 2)
		-- Every point too close: the farthest from the fighters.
		local crowded = { { 0, 0, 0 }, { 20, 0, 0 } }
		expect.equal(SpawnPlan.respawn(crowded, { { 0, 0, 0 } }, band, first), 2)
		-- Height counts: a fighter on a roof 110 up is 110 from the point below (in the band), not 0.
		expect.equal(SpawnPlan.respawn({ { 0, 0, 0 }, { 300, 0, 0 } }, { { 0, 110, 0 } }, band, first), 1)
		-- Nobody else in the arena: any point; no points: 0.
		expect.equal(SpawnPlan.respawn(points, {}, band, first), 1)
		expect.equal(SpawnPlan.respawn({}, { { 0, 0, 0 } }, band, first), 0)
	end,
}
