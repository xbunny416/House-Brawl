--!strict
--[[
	WallRules — one breakable wall piece's health (pure; owner, 2026-10-28: "add breakable walls"). A wall's health
	comes from its material (Config.Structures.Walls: glass goes with one punch, wood takes a few, brick and concrete
	more). Every hit removes its Classic HP damage; the hit that takes it to 0 breaks it (only once).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

export type State = {
	Health: number,
	MaxHealth: number,
	Broken: boolean,
}

local WallRules = {}

-- A wall's full health for its material (an Enum.Material name).
function WallRules.health(material: string): number
	local walls = Config.Structures.Walls
	return walls.Health[material] or walls.DefaultHealth
end

function WallRules.new(material: string): State
	local health = WallRules.health(material)
	return { Health = health, MaxHealth = health, Broken = false }
end

-- Removes `amount` health. True when this hit broke the wall (only once).
function WallRules.damage(state: State, amount: number): boolean
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

return WallRules
