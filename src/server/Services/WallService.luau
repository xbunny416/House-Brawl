--!strict
--[[
	WallService — breakable walls in the arena (owner, 2026-10-28: "add breakable walls", like the walls of the city in
	Jujutsu Shenanigans): every part tagged BreakableWall in the active arena (building walls and windows, block
	walls). Attack boxes, thrown props and barrel blasts damage them the way they damage structures (StructureService);
	a wall darkens as it loses health and at 0 it shatters (the Break effect) and stays gone for the rest of the round
	(the next round loads a fresh copy of the arena). Health comes from the wall's material (Server/Structures/WallRules).
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Server = script.Parent.Parent
local WallRules = require(Server:WaitForChild("Structures"):WaitForChild("WallRules"))
local Effects = require(Server:WaitForChild("Visuals"):WaitForChild("Effects"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local PropService = require(script.Parent:WaitForChild("PropService"))

type Wall = {
	Part: BasePart,
	Color: Color3, -- its undamaged colour (darkened as it loses health)
	State: WallRules.State,
}

local WALL_TAG = "BreakableWall"
local DAMAGED_DARKEN = 0.5 -- how much darker a wall is at 1 HP

local WallService = {}

local walls: { [BasePart]: Wall } = {}
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

local function log(message: string)
	if RunService:IsStudio() and Config.Dev.LogCombat then
		print(`[Walls] {message}`)
	end
end

-- Damages a wall piece (Classic HP damage). It shatters at 0.
function WallService.damage(part: BasePart, amount: number, attacker: Player?)
	local wall = walls[part]
	if wall == nil then
		return
	end
	if WallRules.damage(wall.State, amount) then
		walls[part] = nil
		Effects.play("Break", part.Position, { Size = part.Size, Color = wall.Color, Material = part.Material.Name })
		log(`{part.Name} broken by {if attacker then attacker.Name else "nobody"}`)
		part:Destroy()
		return
	end
	local lost = 1 - wall.State.Health / wall.State.MaxHealth
	part.Color = wall.Color:Lerp(Color3.new(0, 0, 0), lost * DAMAGED_DARKEN)
end

local function onSwung(attacker: Player, box: CFrame, size: Vector3, damage: number)
	if next(walls) == nil then
		return
	end
	for _, part in Workspace:GetPartBoundsInBox(box, size, overlap) do
		if part:IsA("BasePart") and walls[part] then
			WallService.damage(part, damage, attacker)
		end
	end
end

local function onImpact(part: BasePart, damage: number, thrower: Player)
	if walls[part] then
		WallService.damage(part, damage, thrower)
	end
end

-- A blast reaches a wall when its centre is within the radius plus half the wall's largest side.
local function onExploded(center: Vector3, radius: number, damage: number, attacker: Player?)
	local reached: { BasePart } = {}
	for part in walls do
		local size = part.Size
		if (part.Position - center).Magnitude <= radius + math.max(size.X, size.Y, size.Z) / 2 then
			table.insert(reached, part)
		end
	end
	for _, part in reached do
		WallService.damage(part, damage, attacker)
	end
end

local function onArenaLoaded(_mapId: string, arena: Model)
	table.clear(walls)
	local list: { Instance } = {}
	for _, part in CollectionService:GetTagged(WALL_TAG) do
		if part:IsA("BasePart") and part:IsDescendantOf(arena) then
			walls[part] = { Part = part, Color = part.Color, State = WallRules.new(part.Material.Name) }
			table.insert(list, part)
		end
	end
	overlap.FilterDescendantsInstances = list
	log(`{#list} breakable wall pieces`)
end

local function onArenaUnloaded()
	table.clear(walls)
	overlap.FilterDescendantsInstances = {}
end

function WallService.Init(_self: any)
	CombatService.Swung:Connect(onSwung)
	PropService.Impact:Connect(onImpact)
	PropService.Exploded:Connect(onExploded)
	MapService.ArenaLoaded:Connect(onArenaLoaded)
	MapService.ArenaUnloaded:Connect(onArenaUnloaded)
end

return WallService
