--!strict
--[[
	MapService — the Lobby (always in Workspace) and the active arena.

	Arena templates live in ServerStorage.Arenas (generated from maps/layouts, see maps/build.luau). Only one arena is
	in Workspace at a time. Gameplay markers inside maps are tagged parts:
	  SpawnPoint, PropSpot, ExplosiveSpot, StructureSpot (arena platforms) · LobbySpawn (lobby).
	Markers are visible in Edit mode for level design and hidden here at runtime.
]]
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))
local LightingPresets = require(Shared:WaitForChild("Config"):WaitForChild("Lighting"))

local FALL_CHECK_INTERVAL = 0.2
local SPAWN_HEIGHT = 3
local SPAWN_EDGE = 1 -- lobby spawn spots stay this far inside the spawn's edge

export type FallZone = "Lobby" | "Arena"

local MapService = {
	Priority = -40,
	-- (mapId, arena) after an arena is placed in Workspace.
	ArenaLoaded = Signal.new() :: Signal.Signal<string, Model>,
	-- () after the arena is removed.
	ArenaUnloaded = Signal.new() :: Signal.Signal<()>,
}

local lobby: Model
local arenaFolder: Folder
local activeArena: Model? = nil
local activeMapId: string? = nil

-- Called when a character falls below the kill height of the zone it is in. The round system replaces this;
-- by default everyone goes back to the lobby.
local fallHandler: (player: Player, zone: FallZone) -> () = function(player: Player, _zone: FallZone)
	MapService.sendToLobby(player)
end

local function hideMarkers(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:HasTag("Marker") then
			descendant.Transparency = 1
		end
	end
end

-- The lighting preset a map model asks for (its "Lighting" attribute).
local function lightingOf(model: Model): string
	local preset = model:GetAttribute("Lighting")
	return if type(preset) == "string" then preset else "Dusk"
end

local function toVector(values: { number }): Vector3
	return Vector3.new(values[1], values[2], values[3])
end

local function findEffect<T>(className: string, name: string): T
	local effect = Lighting:FindFirstChild(name)
	if effect == nil then
		effect = Instance.new(className)
		effect.Name = name
		effect.Parent = Lighting
	end
	return effect :: any
end

-- Applies a lighting preset from Config.Lighting.
function MapService.applyLighting(presetId: string)
	local preset = LightingPresets[presetId]
	assert(preset, `Unknown lighting preset "{presetId}"`)
	Lighting.ClockTime = preset.ClockTime
	Lighting.GeographicLatitude = preset.GeographicLatitude
	Lighting.Brightness = preset.Brightness
	Lighting.Ambient = Color3.fromHex(preset.Ambient)
	Lighting.OutdoorAmbient = Color3.fromHex(preset.OutdoorAmbient)
	Lighting.ColorShift_Top = Color3.fromHex(preset.ColorShiftTop)
	Lighting.ColorShift_Bottom = Color3.fromHex(preset.ColorShiftBottom)
	Lighting.EnvironmentDiffuseScale = preset.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = preset.EnvironmentSpecularScale

	local atmosphere = findEffect("Atmosphere", "Atmosphere") :: Atmosphere
	atmosphere.Density = preset.Atmosphere.Density
	atmosphere.Offset = preset.Atmosphere.Offset
	atmosphere.Color = Color3.fromHex(preset.Atmosphere.Color)
	atmosphere.Decay = Color3.fromHex(preset.Atmosphere.Decay)
	atmosphere.Glare = preset.Atmosphere.Glare
	atmosphere.Haze = preset.Atmosphere.Haze

	local bloom = findEffect("BloomEffect", "Bloom") :: BloomEffect
	bloom.Intensity = preset.Bloom.Intensity
	bloom.Size = preset.Bloom.Size
	bloom.Threshold = preset.Bloom.Threshold

	local grade = findEffect("ColorCorrectionEffect", "ColorGrade") :: ColorCorrectionEffect
	grade.Brightness = preset.ColorCorrection.Brightness
	grade.Contrast = preset.ColorCorrection.Contrast
	grade.Saturation = preset.ColorCorrection.Saturation
	grade.TintColor = Color3.fromHex(preset.ColorCorrection.TintColor)

	-- Dynamic clouds only where the preset asks for them (they live under Terrain).
	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
	if preset.Clouds then
		if clouds == nil then
			clouds = Instance.new("Clouds")
			clouds.Parent = Workspace.Terrain
		end
		local settings = preset.Clouds
		local sky = clouds :: Clouds
		sky.Cover = settings.Cover
		sky.Density = settings.Density
		sky.Color = Color3.fromHex(settings.Color)
		sky.Enabled = true
	elseif clouds then
		clouds.Enabled = false
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Arenas
---------------------------------------------------------------------------------------------------------------------

-- Map ids that can be voted for (in rotation and enabled).
function MapService.getEnabledMaps(): { string }
	local maps = {}
	for _, mapId in Config.Maps.Rotation do
		local map = Config.Maps.List[mapId]
		if map and map.Enabled and ServerStorage.Arenas:FindFirstChild(mapId) then
			table.insert(maps, mapId)
		end
	end
	return maps
end

-- Places a fresh copy of the arena in Workspace (replacing any active one) and returns it.
function MapService.loadArena(mapId: string): Model
	local template = ServerStorage.Arenas:FindFirstChild(mapId)
	assert(template and template:IsA("Model"), `No arena template "{mapId}" in ServerStorage.Arenas`)
	MapService.unloadArena()

	local arena = template:Clone()
	hideMarkers(arena)
	arena.Parent = arenaFolder
	activeArena = arena
	activeMapId = mapId
	MapService.applyLighting(lightingOf(arena))
	MapService.ArenaLoaded:Fire(mapId, arena)
	return arena
end

-- Removes the active arena (if any) and restores the lobby lighting.
function MapService.unloadArena()
	local arena = activeArena
	if arena == nil then
		return
	end
	activeArena = nil
	activeMapId = nil
	arena:Destroy()
	MapService.applyLighting(lightingOf(lobby))
	MapService.ArenaUnloaded:Fire()
end

function MapService.getArena(): (Model?, string?)
	return activeArena, activeMapId
end

-- False for markers on a platform that is crumbling or falling (its "Crumbling" attribute is set).
local function onSolidGround(marker: Instance, arena: Model): boolean
	local node = marker.Parent
	while node and node ~= arena do
		if node:HasTag("Platform") then
			return node:GetAttribute("Crumbling") ~= true
		end
		node = node.Parent
	end
	return true
end

-- Tagged parts of a kind (e.g. "SpawnPoint", "PropSpot") inside the active arena, skipping crumbling platforms.
function MapService.getArenaMarkers(tag: string): { BasePart }
	local markers: { BasePart } = {}
	local arena = activeArena
	if arena then
		for _, instance in CollectionService:GetTagged(tag) do
			if instance:IsA("BasePart") and instance:IsDescendantOf(arena) and onSolidGround(instance, arena) then
				table.insert(markers, instance)
			end
		end
	end
	return markers
end

-- Platform models of the active arena.
function MapService.getPlatforms(): { Model }
	local platforms: { Model } = {}
	local arena = activeArena
	if arena then
		for _, instance in CollectionService:GetTagged("Platform") do
			if instance:IsA("Model") and instance:IsDescendantOf(arena) then
				table.insert(platforms, instance)
			end
		end
	end
	return platforms
end

---------------------------------------------------------------------------------------------------------------------
-- Moving players
---------------------------------------------------------------------------------------------------------------------

local function teleport(player: Player, target: CFrame)
	local character = player.Character
	if not character then
		return
	end
	-- Ask streaming to send the destination first so the player never lands in an empty world.
	pcall(function()
		player:RequestStreamAroundAsync(target.Position, 2)
	end)
	character:PivotTo(target)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

-- A random spot on a random lobby spawn (the lobby has one wide spawn since 2026-10-27, so players coming back
-- together don't land on top of each other), raised so the character stands on it.
function MapService.getLobbySpawn(): CFrame
	local spawns = CollectionService:GetTagged("LobbySpawn")
	local spawn = spawns[math.random(1, math.max(#spawns, 1))]
	if spawn and spawn:IsA("BasePart") then
		local spreadX = math.max(spawn.Size.X / 2 - SPAWN_EDGE, 0)
		local spreadZ = math.max(spawn.Size.Z / 2 - SPAWN_EDGE, 0)
		local offset = Vector3.new((math.random() * 2 - 1) * spreadX, 0, (math.random() * 2 - 1) * spreadZ)
		return spawn.CFrame * CFrame.new(offset) + Vector3.new(0, SPAWN_HEIGHT, 0)
	end
	return CFrame.new(toVector(Config.Maps.LobbyOrigin) + Vector3.new(0, SPAWN_HEIGHT, 0))
end

function MapService.sendToLobby(player: Player)
	teleport(player, MapService.getLobbySpawn())
end

-- Moves a player onto a spawn point of the active arena (a given one, or a random one).
function MapService.sendToArena(player: Player, spawnPoint: BasePart?)
	local point = spawnPoint
	if point == nil then
		local spawns = MapService.getArenaMarkers("SpawnPoint")
		point = spawns[math.random(1, math.max(#spawns, 1))]
	end
	if point then
		teleport(player, point.CFrame + Vector3.new(0, SPAWN_HEIGHT, 0))
	end
end

-- Replaces what happens when a character falls out of the lobby or the arena.
function MapService.setFallHandler(handler: (player: Player, zone: FallZone) -> ())
	fallHandler = handler
end

---------------------------------------------------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------------------------------------------------

-- Which zone a world position belongs to (whichever origin is closer on the ground plane).
function MapService.getZone(position: Vector3): FallZone
	local lobbyOrigin = toVector(Config.Maps.LobbyOrigin)
	local arenaOrigin = toVector(Config.Maps.ArenaOrigin)
	local flat = Vector3.new(1, 0, 1)
	local toLobby = ((position - lobbyOrigin) * flat).Magnitude
	local toArena = ((position - arenaOrigin) * flat).Magnitude
	return if toArena < toLobby then "Arena" else "Lobby"
end

local function watchFalls()
	local lobbyKillY = lobby:GetAttribute("KillY") :: number
	local handling: { [Player]: boolean } = {}
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed < FALL_CHECK_INTERVAL then
			return
		end
		elapsed = 0
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local position = root.Position
				local zone: FallZone = MapService.getZone(position)
				local arena = activeArena
				local killY = if zone == "Arena" and arena then arena:GetAttribute("KillY") :: number else lobbyKillY
				if position.Y < killY and not handling[player] then
					-- One fall at a time per player (the handler may yield while teleporting).
					handling[player] = true
					task.spawn(function()
						fallHandler(player, zone)
						handling[player] = nil
					end)
				end
			end
		end
	end)
end

function MapService.Init(_self: any)
	lobby = Workspace:WaitForChild("Lobby") :: Model
	hideMarkers(lobby)
	MapService.applyLighting(lightingOf(lobby))

	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "Arena"
	arenaFolder.Parent = Workspace
end

function MapService.Start(_self: any)
	watchFalls()
end

return MapService
