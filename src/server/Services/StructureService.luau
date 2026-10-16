--!strict
--[[
	StructureService — breakable structures in the arena (bible §3.2–3.3): a wrecked car, vending machine or road
	barrier stack stands on every StructureSpot (its StructureType attribute).
	Attack boxes (their Classic damage, in every mode), thrown props and barrel blasts damage them; the structure
	darkens as it loses health. At 0 HP it breaks into MinDrops–MaxDrops random props from its DropTable (they vanish
	after DropDespawnTime unless picked up) and comes back RespawnTime seconds later. Whoever broke it gets the
	StructuresBroken stat. UI / VFX can read the model's HP and MaxHP attributes.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))

local Server = script.Parent.Parent
local StructureRules = require(Server:WaitForChild("Structures"):WaitForChild("StructureRules"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local CrumbleService = require(script.Parent:WaitForChild("CrumbleService"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local PropService = require(script.Parent:WaitForChild("PropService"))

type Structure = {
	Model: Model,
	Part: BasePart,
	Marker: BasePart,
	BaseColor: Color3,
	State: StructureRules.State,
}

local STRUCTURE_TAG = "Structure"
local DAMAGED_DARKEN = 0.55 -- how much darker a structure is at 1 HP
local DROP_SPREAD = 2.5 -- studs from the structure's center where drops land
local DROP_POP = 18 -- studs/s upward kick when drops appear

local StructureService = {
	-- (structure type, player who broke it or nil) after a structure breaks.
	Broken = Signal.new() :: Signal.Signal<string, Player?>,
}

local structures: { [Model]: Structure } = {}
local folder: Folder? = nil
local generation = 0 -- bumps with every arena load, so respawns never land in a newer arena
local rng = Random.new()

local function log(message: string)
	if RunService:IsStudio() and Config.Dev.LogCombat then
		print(`[Structures] {message}`)
	end
end

local function build(typeId: string, marker: BasePart)
	local typeConfig = Config.Structures.Types[typeId]
	local parent = folder
	if typeConfig == nil or parent == nil or not marker:IsDescendantOf(Workspace) then
		return
	end
	local model = Instance.new("Model")
	model.Name = typeId
	local part = Instance.new("Part")
	part.Name = "Body"
	part.Anchored = true
	part.Size = Vector3.new(typeConfig.Size.X, typeConfig.Size.Y, typeConfig.Size.Z)
	part.Material = (Enum.Material :: any)[typeConfig.Material]
	part.Color = Color3.fromHex(typeConfig.Color)
	-- The marker lies on the floor; stand the structure on it, turned the marker's way.
	part.CFrame = marker.CFrame * CFrame.new(0, (part.Size.Y - marker.Size.Y) / 2, 0)
	part.Parent = model
	model.PrimaryPart = part
	local state = StructureRules.new(typeId)
	model:SetAttribute("StructureType", typeId)
	model:SetAttribute("HP", state.Health)
	model:SetAttribute("MaxHP", state.MaxHealth)
	model:AddTag(STRUCTURE_TAG)
	model.Parent = parent
	structures[model] = { Model = model, Part = part, Marker = marker, BaseColor = part.Color, State = state }
end

local function breakStructure(structure: Structure, attacker: Player?)
	local typeId = structure.State.TypeId
	local center = structure.Part.CFrame
	local floorY = -structure.Part.Size.Y / 2
	structures[structure.Model] = nil
	structure.Model:Destroy()

	for _, dropId in
		StructureRules.drops(typeId, function(min: number, max: number): number
			return rng:NextInteger(min, max)
		end)
	do
		local angle = rng:NextNumber(0, 2 * math.pi)
		local floor = center * CFrame.new(math.cos(angle) * DROP_SPREAD, floorY, math.sin(angle) * DROP_SPREAD)
		local part = PropService.spawnLoose(dropId, floor, "Arena", Config.Structures.DropDespawnTime)
		if part then
			part.AssemblyLinearVelocity = Vector3.new(math.cos(angle), 0, math.sin(angle)) * DROP_SPREAD
				+ Vector3.yAxis * DROP_POP
		end
	end

	if attacker and attacker.Parent == Players then
		DataService.incrementStat(attacker, "StructuresBroken")
	end
	log(`{typeId} broken by {if attacker then attacker.Name else "nobody"}`)
	StructureService.Broken:Fire(typeId, attacker)

	local marker = structure.Marker
	local builtIn = generation
	task.delay(Config.Structures.RespawnTime, function()
		if generation == builtIn then
			build(typeId, marker)
		end
	end)
end

-- Damages a structure (Classic HP damage). Breaks it at 0 HP.
function StructureService.damage(model: Model, amount: number, attacker: Player?)
	local structure = structures[model]
	if structure == nil then
		return
	end
	local state = structure.State
	if StructureRules.damage(state, amount) then
		breakStructure(structure, attacker)
		return
	end
	model:SetAttribute("HP", state.Health)
	local lost = 1 - state.Health / state.MaxHealth
	structure.Part.Color = structure.BaseColor:Lerp(Color3.new(0, 0, 0), lost * DAMAGED_DARKEN)
end

-- The structure a part belongs to, if any.
local function structureOf(part: Instance): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	return if model and structures[model] then model else nil
end

local function onSwung(attacker: Player, box: CFrame, size: Vector3, damage: number)
	local parts: { Instance } = {}
	for model in structures do
		table.insert(parts, model)
	end
	if #parts == 0 then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = parts
	local hit: { Model } = {}
	for _, part in Workspace:GetPartBoundsInBox(box, size, params) do
		local model = structureOf(part)
		if model and not table.find(hit, model) then
			table.insert(hit, model)
		end
	end
	for _, model in hit do
		StructureService.damage(model, damage, attacker)
	end
end

local function onImpact(part: BasePart, damage: number, thrower: Player)
	local model = structureOf(part)
	if model then
		StructureService.damage(model, damage, thrower)
	end
end

-- A blast reaches a structure when its center is within the radius plus half the structure's largest side.
local function onExploded(center: Vector3, radius: number, damage: number, attacker: Player?)
	local reached: { Model } = {}
	for model, structure in structures do
		local size = structure.Part.Size
		local reach = radius + math.max(size.X, size.Y, size.Z) / 2
		if (structure.Part.Position - center).Magnitude <= reach then
			table.insert(reached, model)
		end
	end
	for _, model in reached do
		StructureService.damage(model, damage, attacker)
	end
end

-- Structures on a platform that gives way drop into the void with everything else: no longer breakable, removed
-- when the platform is.
local function onPlatformFalling(platform: Model)
	for model, structure in structures do
		if structure.Marker:IsDescendantOf(platform) then
			structures[model] = nil
			structure.Part.Anchored = false
			pcall(function()
				structure.Part:SetNetworkOwner(nil)
			end)
			task.delay(Config.Round.Crumble.FallTime, function()
				model:Destroy()
			end)
		end
	end
end

local function onArenaLoaded(_mapId: string, arena: Model)
	generation += 1
	table.clear(structures)
	local newFolder = Instance.new("Folder")
	newFolder.Name = "Structures"
	newFolder.Parent = arena
	folder = newFolder
	for _, marker in MapService.getArenaMarkers("StructureSpot") do
		local typeId = marker:GetAttribute("StructureType")
		if type(typeId) == "string" and Config.Structures.Types[typeId] then
			build(typeId, marker)
		else
			warn(`[StructureService] {marker:GetFullName()} has an unknown StructureType "{tostring(typeId)}"`)
		end
	end
end

local function onArenaUnloaded()
	generation += 1
	table.clear(structures)
	folder = nil
end

function StructureService.Init(_self: any)
	CombatService.Swung:Connect(onSwung)
	PropService.Impact:Connect(onImpact)
	PropService.Exploded:Connect(onExploded)
	MapService.ArenaLoaded:Connect(onArenaLoaded)
	MapService.ArenaUnloaded:Connect(onArenaUnloaded)
	CrumbleService.PlatformFalling:Connect(onPlatformFalling)
end

return StructureService
