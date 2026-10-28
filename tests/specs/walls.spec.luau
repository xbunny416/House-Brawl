--!strict
-- Breakable walls (owner, 2026-10-28: "add breakable walls"): health from the wall's material, breaks once at 0.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local WallRules = Roblox.require(Roblox.game.ServerScriptService.Server.Structures.WallRules)

-- Punches until the wall breaks; how many it took.
local function punchesToBreak(material: string): number
	local wall = WallRules.new(material)
	local punch = Config.Combat.Attacks.Punch.Damage
	local hits = 0
	while not wall.Broken and hits < 100 do
		hits += 1
		WallRules.damage(wall, punch)
	end
	return hits
end

return {
	["a wall's health comes from its material, with a default for the rest"] = function()
		local walls = Config.Structures.Walls
		expect.equal(WallRules.health("Glass"), walls.Health.Glass)
		expect.equal(WallRules.health("WoodPlanks"), walls.Health.WoodPlanks)
		expect.equal(WallRules.health("Concrete"), walls.DefaultHealth)
		expect.equal(WallRules.health("Brick"), walls.DefaultHealth)
	end,
	["glass goes with one punch, wood takes a few, concrete more"] = function()
		expect.equal(punchesToBreak("Glass"), 1)
		local wood, concrete = punchesToBreak("Wood"), punchesToBreak("Concrete")
		expect.truthy(wood >= 2 and wood < concrete, `wood {wood}, concrete {concrete}`)
		expect.truthy(concrete <= 6, `concrete takes {concrete} punches (not a slog)`)
	end,
	["damage breaks a wall exactly once, at 0"] = function()
		local wall = WallRules.new("Concrete")
		expect.equal(WallRules.damage(wall, wall.Health - 1), false)
		expect.equal(wall.Health, 1)
		expect.equal(WallRules.damage(wall, 5), true)
		expect.equal(wall.Health, 0)
		expect.equal(WallRules.damage(wall, 5), false, "already broken")
		expect.equal(WallRules.damage(WallRules.new("Glass"), 0), false, "no damage, no break")
	end,
}
