--!strict
--[[
	StructureRules — one breakable structure's health and what it drops (pure; randomness is passed in).
	Every hit removes its Classic HP damage (in every mode); the hit that takes it to 0 breaks it and its attacker
	gets the credit. A break drops MinDrops..MaxDrops props, each a random entry of the type's DropTable.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

-- Random whole number in [min, max] (Random:NextInteger in the game, fixed in specs).
export type Roll = (min: number, max: number) -> number

export type State = {
	TypeId: string,
	Health: number,
	MaxHealth: number,
	Broken: boolean,
}

local StructureRules = {}

function StructureRules.new(typeId: string): State
	local structure = Config.Structures.Types[typeId]
	assert(structure, `Unknown structure type "{typeId}"`)
	return { TypeId = typeId, Health = structure.Health, MaxHealth = structure.Health, Broken = false }
end

-- Removes `amount` health. True when this hit broke the structure (only once).
function StructureRules.damage(state: State, amount: number): boolean
	if state.Broken or amount <= 0 then
		return false
	end
	state.Health = math.max(state.Health - amount, 0)
	if state.Health <= 0 then
		state.Broken = true
		return true
	end
	return false
end

-- The prop types a broken structure drops.
function StructureRules.drops(typeId: string, roll: Roll): { string }
	local structure = Config.Structures.Types[typeId]
	local drops: { string } = {}
	for _ = 1, roll(structure.MinDrops, structure.MaxDrops) do
		table.insert(drops, structure.DropTable[roll(1, #structure.DropTable)])
	end
	return drops
end

return StructureRules
