--!strict
-- Breakable structures (step 1.10): health from Config, breaks once at 0 HP, drops from the type's table.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local StructureRules = Roblox.require(Roblox.game.ServerScriptService.Server.Structures.StructureRules)

local function low(min: number, _max: number): number
	return min
end

local function high(_min: number, max: number): number
	return max
end

return {
	["structures start at their bible HP"] = function()
		expect.equal(StructureRules.new("WreckedCar").Health, 100)
		expect.equal(StructureRules.new("VendingMachine").Health, 80)
		expect.equal(StructureRules.new("RoadBarrierStack").Health, 60)
	end,
	["damage breaks a structure exactly once, at 0 HP"] = function()
		local barrier = StructureRules.new("RoadBarrierStack")
		local punch = Config.Combat.Attacks.Punch.Damage
		local hits = 0
		local brokeOn = nil
		while not barrier.Broken and hits < 100 do
			hits += 1
			if StructureRules.damage(barrier, punch) then
				brokeOn = hits
			end
		end
		expect.equal(brokeOn, math.ceil(60 / punch))
		expect.equal(barrier.Health, 0)
		expect.equal(StructureRules.damage(barrier, punch), false, "already broken")
		expect.equal(StructureRules.damage(StructureRules.new("WreckedCar"), 0), false, "no damage")
	end,
	["drops: MinDrops..MaxDrops entries of the type's DropTable"] = function()
		for typeId, structure in Config.Structures.Types do
			local few = StructureRules.drops(typeId, low)
			local many = StructureRules.drops(typeId, high)
			expect.equal(#few, structure.MinDrops, `{typeId} min`)
			expect.equal(#many, structure.MaxDrops, `{typeId} max`)
			for _, dropId in many do
				expect.truthy(table.find(structure.DropTable, dropId), `{typeId} drops {dropId}`)
				expect.truthy(Config.Props.Types[dropId], `{dropId} is a prop`)
			end
		end
	end,
	["every arena structure spot names a known structure with a blockout size"] = function()
		local BrokenHighway = require("../../maps/layouts/BrokenHighway")
		local count = 0
		for _, contents in BrokenHighway.Contents do
			for _, structure in contents.Structures or {} do
				count += 1
				local typeConfig = Config.Structures.Types[structure.Type]
				expect.truthy(typeConfig, structure.Type)
				expect.truthy(typeConfig.Size.X > 0 and typeConfig.Size.Y > 0 and typeConfig.Size.Z > 0, "size")
			end
		end
		expect.equal(count, 4, "bible: 4 breakable structures on Broken Highway")
	end,
}
