--!strict
--[[
	PropService — loose props (bible §3.3 "Props"): spawn spots, grab / carry / drop / throw, thrown-prop hits,
	explosive barrels, the per-zone prop cap and despawning.

	  * Spots: arena PropSpot (a random Config.Props.LooseSpotTypes type), ExplosiveSpot (ExplosiveBarrel) and the
	    lobby's LobbyPropSpot (its PropType attribute; none at the moment). A spot gets a prop when its map is in
	    Workspace, and a new one SpotRespawnTime (ExplosiveSpotRespawnTime) after its prop was taken, while the zone
	    has fewer than MaxActive props.
	  * Grab (Grab remote / Grab action): the server picks the nearest free prop within GrabRange and welds it above
	    the player's head (massless, no collisions); carrying slows them by the class's CarrySlow. Grab again to drop
	    it in front of you. Getting hit or knocked out drops it. Holding blocks a charge.
	  * Throw: while holding, Attack (Punch remote) throws the prop the way the character faces at ThrowSpeed with a
	    slight arc (ThrowCooldown). The server simulates the flight and sweeps it every frame: the first fighter in
	    the way takes the class's damage / Percent / knockback, credited to the thrower; anything else ends the
	    flight. Thrown and dropped props despawn DespawnAfterLanding seconds after they come down.
	  * Explosive barrel: explodes on impact when thrown, or FuseTime seconds after an attack hits it. The blast hits
	    every fighter within Radius, the thrower too, and lights the other barrels in range.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))

local Server = script.Parent.Parent
local Carrier = require(Server:WaitForChild("Props"):WaitForChild("Carrier"))
local Animate = require(Server:WaitForChild("Visuals"):WaitForChild("Animate"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local MapService = require(script.Parent:WaitForChild("MapService"))

type Zone = MapService.FallZone

type Spot = {
	Marker: BasePart,
	TypeId: string?, -- fixed type (lobby chair, explosive spot); nil = a random loose type
	Zone: Zone,
	Prop: Prop?, -- the prop waiting on this spot, until someone takes it
	RespawnAt: number?,
}

type Prop = {
	Part: BasePart,
	TypeId: string,
	Class: string,
	Zone: Zone,
	Spot: Spot?,
	Holder: Player?,
	HolderCharacter: Model?,
	Thrower: Player?,
	Flying: boolean,
	FlightStartedAt: number,
	LastPosition: Vector3,
	DespawnAt: number?,
	FuseAt: number?,
	Igniter: Player?,
}

local PROP_TAG = "Prop"
local HOLD_NAME = "HoldWeld"
local CARRY_SPEED_KEY = "Carry"
local HOLD_HEIGHT = 2.6 -- studs from the character's root to just above its head
local DROP_DISTANCE = 3 -- studs in front of the character
local THROW_HEIGHT = 1.5 -- studs above the root where a throw starts
local FLIGHT_MAX_TIME = 4
local LANDING_SLOWDOWN = 0.3 -- share of its speed a prop keeps when its flight ends
local THROW_SPIN = 6 -- radians/s of tumble on a throw
local TICK = 0.2 -- spots, despawns and fuses are checked this often; flights every frame

local PropService = {
	-- (part hit, the prop class's Classic damage, thrower) when a thrown prop's flight ends on something that is not
	-- a fighter (structures take damage from it).
	Impact = Signal.new() :: Signal.Signal<BasePart, number, Player>,
	-- (center, radius, Classic damage, credited player or nil) when a barrel explodes.
	Exploded = Signal.new() :: Signal.Signal<Vector3, number, number, Player?>,
}

local props: { [BasePart]: Prop } = {}
local spots: { Spot } = {}
local carriers: { [Player]: Carrier.Carrier } = {}
local lobbyFolder: Folder
local arenaFolder: Folder? = nil
local rng = Random.new()

local fighterParams = RaycastParams.new()
fighterParams.FilterType = Enum.RaycastFilterType.Include
local worldParams = RaycastParams.new()
worldParams.FilterType = Enum.RaycastFilterType.Exclude
worldParams.RespectCanCollide = true

local function log(message: string)
	if RunService:IsStudio() and Config.Dev.LogCombat then
		print(`[Props] {message}`)
	end
end

local function rootOf(character: Model?): BasePart?
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function countIn(zone: Zone): number
	local count = 0
	for _, prop in props do
		if prop.Zone == zone then
			count += 1
		end
	end
	return count
end

local function respawnTimeOf(spot: Spot): number
	local explosive = spot.TypeId ~= nil and Config.Props.Types[spot.TypeId].Class == "Explosive"
	return if explosive then Config.Props.ExplosiveSpotRespawnTime else Config.Props.SpotRespawnTime
end

-- The spot's prop is gone or taken: a new one comes after the respawn time.
local function vacate(spot: Spot)
	spot.Prop = nil
	spot.RespawnAt = os.clock() + respawnTimeOf(spot)
end

---------------------------------------------------------------------------------------------------------------------
-- Holding
---------------------------------------------------------------------------------------------------------------------

local function carrierOf(player: Player): Carrier.Carrier
	local carrier = carriers[player]
	if carrier == nil then
		carrier = Carrier.new()
		carriers[player] = carrier
	end
	return carrier
end

local function heldBy(player: Player): Prop?
	local carrier = carriers[player]
	return if carrier then carrier.Held :: Prop? else nil
end

-- Unwelds a held prop and gives the holder their speed back. The prop keeps its place in the world.
local function detach(prop: Prop)
	local weld = prop.Part:FindFirstChild(HOLD_NAME)
	if weld then
		weld:Destroy()
	end
	prop.Part.Massless = false
	prop.Part.CanCollide = true
	prop.Part:SetAttribute("Held", nil)
	local character = prop.HolderCharacter
	if character then
		character:SetAttribute("HeldProp", nil)
		CombatService.setSpeedModifier(character, CARRY_SPEED_KEY, nil)
	end
	prop.Holder = nil
	prop.HolderCharacter = nil
end

local function attach(prop: Prop, player: Player, character: Model, root: BasePart)
	if prop.Spot then
		vacate(prop.Spot)
		prop.Spot = nil
	end
	prop.Holder = player
	prop.HolderCharacter = character
	prop.Thrower = nil
	prop.DespawnAt = nil
	local part = prop.Part
	-- Take the loose prop from whichever client was simulating it, so the move below is not fought over; once welded
	-- it becomes part of the character, which the holder's client simulates.
	pcall(function()
		part:SetNetworkOwner(nil)
	end)
	part.CanCollide = false
	part.Massless = true
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
	part.CFrame = root.CFrame * CFrame.new(0, HOLD_HEIGHT + part.Size.Y / 2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Name = HOLD_NAME
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part:SetAttribute("Held", true)
	character:SetAttribute("HeldProp", prop.TypeId) -- also the carry pose on every client
	Animate.play(character, "Grab")
	local slow = Config.Props.Classes[prop.Class].CarrySlow
	CombatService.setSpeedModifier(character, CARRY_SPEED_KEY, if slow > 0 then 1 - slow else nil)
	log(`{player.Name} grabbed {prop.TypeId}`)
end

-- Drops whatever the player holds in front of them (or where it is, if their character is gone).
local function drop(player: Player)
	local carrier = carriers[player]
	local prop = if carrier then Carrier.release(carrier, os.clock()) :: Prop? else nil
	if prop == nil or props[prop.Part] == nil then
		return
	end
	local root = rootOf(prop.HolderCharacter)
	detach(prop)
	local part = prop.Part
	if root then
		part.CFrame = root.CFrame * CFrame.new(0, 0, -DROP_DISTANCE)
		part.AssemblyLinearVelocity = Vector3.zero
	end
	pcall(function()
		part:SetNetworkOwnershipAuto()
	end)
	prop.DespawnAt = os.clock() + Config.Props.DespawnAfterLanding
	log(`{player.Name} dropped {prop.TypeId}`)
end

---------------------------------------------------------------------------------------------------------------------
-- Spawning
---------------------------------------------------------------------------------------------------------------------

local function forget(part: BasePart)
	local prop = props[part]
	if prop == nil then
		return
	end
	props[part] = nil
	local holder = prop.Holder
	if holder then
		local carrier = carriers[holder]
		if carrier and carrier.Held == prop then
			Carrier.release(carrier, os.clock())
		end
		detach(prop)
	end
	local spot = prop.Spot
	if spot and spot.Prop == prop then
		vacate(spot)
	end
end

-- Creates a prop centered at `center` in a zone's folder (no cap check).
local function makeProp(typeId: string, center: CFrame, zone: Zone, spot: Spot?): Prop?
	local folder = if zone == "Lobby" then lobbyFolder else arenaFolder
	local typeConfig = Config.Props.Types[typeId]
	if folder == nil or typeConfig == nil then
		return nil
	end
	local part = Instance.new("Part")
	part.Name = typeId
	part.Size = Vector3.new(typeConfig.Size.X, typeConfig.Size.Y, typeConfig.Size.Z)
	part.Material = (Enum.Material :: any)[typeConfig.Material]
	part.Color = Color3.fromHex(typeConfig.Color)
	part.CFrame = center
	part:SetAttribute("PropType", typeId)
	part:AddTag(PROP_TAG)
	local prop: Prop = {
		Part = part,
		TypeId = typeId,
		Class = typeConfig.Class,
		Zone = zone,
		Spot = spot,
		Holder = nil,
		HolderCharacter = nil,
		Thrower = nil,
		Flying = false,
		FlightStartedAt = 0,
		LastPosition = part.Position,
		DespawnAt = nil,
		FuseAt = nil,
		Igniter = nil,
	}
	props[part] = prop
	part.Destroying:Connect(function()
		forget(part)
	end)
	part.Parent = folder
	return prop
end

-- Spawns a prop standing on `floor` (a CFrame at floor level).
local function spawnProp(typeId: string, floor: CFrame, zone: Zone, spot: Spot?): Prop?
	local typeConfig = Config.Props.Types[typeId]
	if typeConfig == nil then
		return nil
	end
	return makeProp(typeId, floor * CFrame.new(0, typeConfig.Size.Y / 2 + 0.05, 0), zone, spot)
end

local function fillSpot(spot: Spot)
	if spot.Prop or not spot.Marker:IsDescendantOf(Workspace) or countIn(spot.Zone) >= Config.Props.MaxActive then
		return
	end
	local loose = Config.Props.LooseSpotTypes
	local typeId = spot.TypeId or loose[rng:NextInteger(1, #loose)]
	-- Markers lie on the floor: their bottom face is floor level.
	local floor = spot.Marker.CFrame * CFrame.new(0, -spot.Marker.Size.Y / 2, 0)
	local prop = spawnProp(typeId, floor, spot.Zone, spot)
	if prop then
		spot.Prop = prop
		spot.RespawnAt = nil
	end
end

-- Spawns a loose prop standing on `floor` (e.g. a structure's drops), if the zone has fewer than MaxActive props.
-- Unless someone picks it up first it vanishes after `despawnAfter` seconds. Returns its part, or nil.
function PropService.spawnLoose(typeId: string, floor: CFrame, zone: Zone, despawnAfter: number?): BasePart?
	if countIn(zone) >= Config.Props.MaxActive then
		return nil
	end
	local prop = spawnProp(typeId, floor, zone, nil)
	if prop == nil then
		return nil
	end
	if despawnAfter then
		prop.DespawnAt = os.clock() + despawnAfter
	end
	return prop.Part
end

local function addSpot(marker: BasePart, typeId: string?, zone: Zone)
	if typeId and Config.Props.Types[typeId] == nil then
		warn(`[PropService] {marker:GetFullName()} asks for unknown prop type "{typeId}"`)
		typeId = nil
	end
	local spot: Spot = { Marker = marker, TypeId = typeId, Zone = zone, Prop = nil, RespawnAt = nil }
	table.insert(spots, spot)
	fillSpot(spot)
end

---------------------------------------------------------------------------------------------------------------------
-- Throwing, flights and explosions
---------------------------------------------------------------------------------------------------------------------

local function blowFor(prop: Prop, attacker: Player): CombatService.Blow
	local class = Config.Props.Classes[prop.Class]
	return {
		Attacker = attacker,
		AttackerCharacter = attacker.Character,
		Damage = class.Damage,
		Percent = class.Percent,
		KnockbackScale = class.KnockbackScale,
		Multiplier = 1,
		Source = prop.TypeId,
		Label = prop.TypeId,
		Heavy = prop.Class ~= "Light",
		Fallback = Vector3.zero,
	}
end

local explode: (prop: Prop, igniter: Player?) -> ()

-- Lights a barrel: it explodes FuseTime seconds from now, credited to `igniter`.
local function light(prop: Prop, igniter: Player?)
	if prop.Class ~= "Explosive" or prop.FuseAt ~= nil then
		return
	end
	prop.FuseAt = os.clock() + (Config.Props.Classes.Explosive.FuseTime or 0)
	prop.Igniter = igniter
	prop.Part.Material = Enum.Material.Neon
	prop.Part:SetAttribute("Lit", true)
	log(`{prop.TypeId} lit{if igniter then ` by {igniter.Name}` else ""}`)
end

function explode(prop: Prop, igniter: Player?)
	local part = prop.Part
	if props[part] == nil then
		return
	end
	local class = Config.Props.Classes.Explosive
	local radius = class.Radius or 0
	local center = part.Position
	part:Destroy()
	local blast = Instance.new("Explosion")
	blast.BlastPressure = 0 -- visual only: the blow below does the knockback
	blast.DestroyJointRadiusPercent = 0
	blast.BlastRadius = radius
	blast.Position = center
	blast.Parent = Workspace
	local credited = igniter or prop.Igniter
	if credited then
		local hit = CombatService.explode(center, radius, blowFor(prop, credited))
		log(`{prop.TypeId} exploded ({credited.Name}), {#hit} hit`)
	end
	PropService.Exploded:Fire(center, radius, class.Damage, credited)
	for otherPart, other in props do
		if other.Class == "Explosive" and (otherPart.Position - center).Magnitude <= radius then
			light(other, credited)
		end
	end
end

-- The flight is over (it hit something or ran out of time): the prop collides again and despawns later.
local function endFlight(prop: Prop, restAt: Vector3?)
	prop.Flying = false
	local part = prop.Part
	if restAt then
		part.CFrame = CFrame.new(restAt) * part.CFrame.Rotation
	end
	part.CanCollide = true
	part.AssemblyLinearVelocity *= LANDING_SLOWDOWN
	prop.DespawnAt = os.clock() + Config.Props.DespawnAfterLanding
	pcall(function()
		part:SetNetworkOwnershipAuto()
	end)
	if prop.Class == "Explosive" then
		explode(prop, prop.Thrower)
	end
end

-- Holding a prop turns Punch into a throw. Returns true when the Punch was used up by the prop.
local function flat(vector: Vector3): Vector3?
	local flatVector = Vector3.new(vector.X, 0, vector.Z)
	return if flatVector.Magnitude > 1e-3 then flatVector.Unit else nil
end

-- Where a throw starts and which way it goes (flat). Uses the thrower's own view (`facing` / `position` from their
-- client, sanity-checked) so the throw leaves from where they see themselves, then bends toward a fighter inside
-- the aim-assist cone.
local function throwAim(player: Player, root: BasePart, facing: Vector3?, position: Vector3?): (Vector3, Vector3)
	local origin = root.Position
	if position and (position - origin).Magnitude <= Config.Props.ThrowOriginTolerance then
		origin = position
	end
	local direction = (facing and flat(facing)) or flat(root.CFrame.LookVector) or Vector3.zAxis
	local targets: { { X: number, Z: number } } = {}
	local positions: { Vector3 } = {}
	for _, character in CombatService.combatants() do
		local target = rootOf(character)
		if character ~= player.Character and target and CombatService.isTarget(character, origin) then
			local offset = target.Position - origin
			table.insert(targets, { X = offset.X, Z = offset.Z })
			table.insert(positions, target.Position)
		end
	end
	local index = Formulas.aimAssistIndex(direction.X, direction.Z, targets)
	if index then
		direction = flat(positions[index] - origin) or direction
	end
	return origin, direction
end

local function throw(player: Player, facing: Vector3?, position: Vector3?): boolean
	local carrier = carriers[player]
	if carrier == nil or carrier.Held == nil then
		return false
	end
	local character = player.Character
	local root = rootOf(character)
	if character == nil or root == nil or not CombatService.canAct(character) then
		return true -- holding, but in hitstun: no punch either
	end
	local held = Carrier.throw(carrier, os.clock()) :: Prop?
	if held == nil then
		return true -- throw cooldown
	end
	CombatService.breakShield(character)
	Animate.play(character, "Throw")
	local origin, direction = throwAim(player, root, facing, position)
	-- A fresh copy flies, owned by the server: the held prop is part of the thrower's character (simulated by their
	-- client), so the server cannot reliably take it over in the same frame. The held one is removed (its Destroying
	-- handler gives the thrower their speed back).
	local size = held.Part.Size
	local reach = math.max(size.X, size.Y, size.Z) / 2 + 1
	local start = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, THROW_HEIGHT, -reach)
	local prop = makeProp(held.TypeId, start, held.Zone, nil)
	if held.FuseAt and prop then
		prop.FuseAt, prop.Igniter = held.FuseAt, held.Igniter
		prop.Part.Material = Enum.Material.Neon
		prop.Part:SetAttribute("Lit", true)
	end
	held.Part:Destroy()
	if prop == nil then
		return true
	end
	local part = prop.Part
	part.CanCollide = false -- the flight is swept by the server instead
	pcall(function()
		part:SetNetworkOwner(nil)
	end)
	local vx, vy, vz = Formulas.throwVelocity(direction.X, direction.Z)
	part.AssemblyLinearVelocity = Vector3.new(vx, vy, vz)
	part.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), 0) * THROW_SPIN
	prop.Thrower = player
	prop.Flying = true
	prop.FlightStartedAt = os.clock()
	prop.LastPosition = part.Position
	log(`{player.Name} threw {prop.TypeId}`)
	return true
end

local function combatantOf(instance: Instance, candidates: { Instance }): Model?
	local node: Instance? = instance
	while node and node ~= Workspace do
		if node:IsA("Model") and table.find(candidates, node) then
			return node
		end
		node = node.Parent
	end
	return nil
end

-- Moves a flight one frame: the first fighter in the way is hit, anything else ends the flight.
local function sweep(prop: Prop, deltaTime: number)
	local part = prop.Part
	local from = prop.LastPosition
	local delta = part.Position - from
	prop.LastPosition = part.Position
	-- Thrown props feel only part of gravity, for a flatter, more accurate throw.
	part.AssemblyLinearVelocity += Vector3.yAxis * Workspace.Gravity * (1 - Config.Props.ThrowGravityScale) * deltaTime
	if os.clock() - prop.FlightStartedAt > FLIGHT_MAX_TIME then
		endFlight(prop)
		return
	end
	if delta.Magnitude < 1e-3 then
		return
	end
	local radius = math.max(math.min(part.Size.X, part.Size.Y, part.Size.Z) / 2, 0.5)
	local thrower = prop.Thrower
	local combatants = CombatService.combatants()
	local targets: { Instance } = {}
	for _, character in combatants do
		if thrower == nil or character ~= thrower.Character then
			table.insert(targets, character)
		end
	end
	if #targets > 0 then
		fighterParams.FilterDescendantsInstances = targets
		local result = Workspace:Spherecast(from, radius, delta, fighterParams)
		local victim = if result then combatantOf(result.Instance, targets) else nil
		if result and victim then
			if thrower and prop.Class ~= "Explosive" then
				CombatService.hitWith(victim, blowFor(prop, thrower), result.Position, delta)
				log(`{prop.TypeId} hit {victim.Name}`)
			end
			endFlight(prop, result.Position - delta.Unit * radius)
			return
		end
	end
	local ignore: { Instance } = { part }
	for _, character in combatants do
		table.insert(ignore, character)
	end
	worldParams.FilterDescendantsInstances = ignore
	local result = Workspace:Spherecast(from, radius, delta, worldParams)
	if result then
		local hitPart = result.Instance
		if thrower and prop.Class ~= "Explosive" and hitPart:IsA("BasePart") then
			PropService.Impact:Fire(hitPart, Config.Props.Classes[prop.Class].Damage, thrower)
		end
		endFlight(prop, result.Position + result.Normal * radius)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Upkeep
---------------------------------------------------------------------------------------------------------------------

local function killYOf(zone: Zone): number
	local model: Instance? = if zone == "Lobby" then Workspace:FindFirstChild("Lobby") else MapService.getArena()
	local killY = model and model:GetAttribute("KillY")
	return if type(killY) == "number" then killY else -math.huge
end

local function upkeep()
	local now = os.clock()
	for _, spot in spots do
		if spot.Prop == nil and spot.RespawnAt and now >= spot.RespawnAt then
			fillSpot(spot)
		end
	end
	for part, prop in props do
		local fellOut = part.Position.Y < killYOf(prop.Zone)
		local expired = prop.DespawnAt ~= nil and now >= prop.DespawnAt and prop.Holder == nil and not prop.Flying
		if prop.FuseAt and now >= prop.FuseAt then
			explode(prop, prop.Igniter)
		elseif fellOut or expired then
			part:Destroy()
		end
	end
end

-- An attack box lights every explosive barrel it touches.
local function onSwung(attacker: Player, box: CFrame, size: Vector3, _damage: number)
	local barrels: { Instance } = {}
	for part, prop in props do
		if prop.Class == "Explosive" and prop.FuseAt == nil then
			table.insert(barrels, part)
		end
	end
	if #barrels == 0 then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = barrels
	for _, part in Workspace:GetPartBoundsInBox(box, size, params) do
		local prop = props[part]
		if prop then
			light(prop, attacker)
		end
	end
end

local function onArenaLoaded(_mapId: string, arena: Model)
	local folder = Instance.new("Folder")
	folder.Name = "Props"
	folder.Parent = arena
	arenaFolder = folder
	for _, marker in MapService.getArenaMarkers("PropSpot") do
		addSpot(marker, nil, "Arena")
	end
	for _, marker in MapService.getArenaMarkers("ExplosiveSpot") do
		addSpot(marker, "ExplosiveBarrel", "Arena")
	end
end

-- The arena (and every prop in it) is gone: forget its spots.
local function onArenaUnloaded()
	arenaFolder = nil
	for index = #spots, 1, -1 do
		if spots[index].Zone == "Arena" then
			table.remove(spots, index)
		end
	end
end

function PropService.Init(_self: any)
	lobbyFolder = Instance.new("Folder")
	lobbyFolder.Name = "LobbyProps"
	lobbyFolder.Parent = Workspace

	Net.onServerEvent("Grab", function(player: Player)
		local carrier = carrierOf(player)
		if carrier.Held then
			drop(player)
			return
		end
		local character = player.Character
		local root = rootOf(character)
		if character == nil or root == nil or not CombatService.canAct(character) then
			log(`{player.Name} can't grab right now (no character, knocked out or in hitstun)`)
			return
		end
		local candidates: { Carrier.Candidate } = {}
		local closest = math.huge
		for part, prop in props do
			if prop.Holder == nil and not prop.Flying then
				local distance = (part.Position - root.Position).Magnitude
				closest = math.min(closest, distance)
				table.insert(candidates, {
					Item = prop,
					Distance = distance,
					Radius = math.max(part.Size.X, part.Size.Y, part.Size.Z) / 2,
				})
			end
		end
		local prop = Carrier.nearest(candidates) :: Prop?
		if prop == nil then
			log(`{player.Name}: nothing to grab within {Config.Props.GrabRange} studs (closest {math.floor(closest)})`)
		elseif Carrier.grab(carrier, prop, os.clock()) then
			attach(prop, player, character, root)
		end
	end)

	-- Holding a prop: Punch throws it and a charge is blocked.
	CombatService.setInterceptor(function(player: Player, attack: string, facing: Vector3?, position: Vector3?): boolean
		if heldBy(player) == nil then
			return false
		end
		if attack == "Punch" then
			throw(player, facing, position)
		end
		return true
	end)
	CombatService.Swung:Connect(onSwung)
	CombatService.Hit:Connect(function(victim: Model)
		local player = Players:GetPlayerFromCharacter(victim)
		if player then
			drop(player)
		end
	end)
	CombatService.KnockedOut:Connect(function(victim: Model)
		local player = Players:GetPlayerFromCharacter(victim)
		if player then
			drop(player)
		end
	end)
	local function watchPlayer(player: Player)
		player.CharacterRemoving:Connect(function()
			drop(player)
		end)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		drop(player)
		carriers[player] = nil
	end)
	MapService.ArenaLoaded:Connect(onArenaLoaded)
	MapService.ArenaUnloaded:Connect(onArenaUnloaded)
end

function PropService.Start(_self: any)
	for _, marker in CollectionService:GetTagged("LobbyPropSpot") do
		if marker:IsA("BasePart") and marker:IsDescendantOf(Workspace) then
			local typeId = marker:GetAttribute("PropType")
			addSpot(marker, if type(typeId) == "string" then typeId else nil, "Lobby")
		end
	end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		for _, prop in props do
			if prop.Flying then
				sweep(prop, deltaTime)
			end
		end
		elapsed += deltaTime
		if elapsed >= TICK then
			elapsed = 0
			upkeep()
		end
	end)
end

return PropService
