--!strict
--[[
	CosmeticService — cosmetics (bible §2.3): owned items (saved Cosmetics.Owned) and one equipped per slot
	(Cosmetics.Equipped). Shown on the character:
	  * Skin: body colors (taking it off restores the avatar's own colors).
	  * Hat / BackItem: welded blockout parts (Visuals/Attached).
	  * DashTrail: a streak behind every dash (CombatService.Dashed).
	  * KOEffect: a particle burst on each KO you score — at the victim for HP KOs, around you for ring-outs (the
	    victim is out in the void by then).
	VictoryEmote plays from the animations step (2.6); NameplateFrame has no items yet.
	EquipCosmetic(slot, itemId?) equips an owned item (nil takes the slot off). Items are bought in the Shop (2.4);
	Exclusive ones (VIP / Premium) are granted by the pass / membership (3.1).
]]
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CosmeticRules = require(Shared:WaitForChild("CosmeticRules"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("Config"):WaitForChild("Types"))

local Attached = require(script.Parent.Parent:WaitForChild("Visuals"):WaitForChild("Attached"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local TRAIL_NAME = "CosmeticTrail"
local CHARACTER_WAIT = 10
local BURST_LIFETIME = 2
-- Body parts each skin color goes to: head, torso, arms, legs.
local SKIN_PARTS: { { string } } = {
	{ "HeadColor3" },
	{ "TorsoColor3" },
	{ "LeftArmColor3", "RightArmColor3" },
	{ "LeftLegColor3", "RightLegColor3" },
}

local CosmeticService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Cosmetics] {message}`)
	end
end

-- The item equipped in `slot`, or nil.
function CosmeticService.equippedIn(player: Player, slot: string): Types.CosmeticItem?
	local data = DataService.get(player)
	local itemId = data and data.Cosmetics.Equipped[slot]
	return if itemId then Config.Cosmetics.Items[itemId] else nil
end

local function applySkin(character: Model, item: Types.CosmeticItem?)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors == nil then
		return
	end
	-- Remember the avatar's own colors once, so taking the skin off restores them.
	if bodyColors:GetAttribute("OriginalSaved") == nil then
		for _, names in SKIN_PARTS do
			for _, name in names do
				bodyColors:SetAttribute(name, (bodyColors :: any)[name])
			end
		end
		bodyColors:SetAttribute("OriginalSaved", true)
	end
	for index, names in SKIN_PARTS do
		for _, name in names do
			local color = if item and item.Colors
				then Color3.fromHex(item.Colors[index])
				else bodyColors:GetAttribute(name)
			if typeof(color) == "Color3" then
				(bodyColors :: any)[name] = color
			end
		end
	end
end

-- A trail behind the root, switched on for each dash.
local function applyTrail(character: Model, item: Types.CosmeticItem?)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	for _, name in { TRAIL_NAME, `{TRAIL_NAME}Top`, `{TRAIL_NAME}Bottom` } do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	if item == nil or item.Colors == nil then
		return
	end
	local top = Instance.new("Attachment")
	top.Name = `{TRAIL_NAME}Top`
	top.Position = Vector3.new(0, 1, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = `{TRAIL_NAME}Bottom`
	bottom.Position = Vector3.new(0, -1, 0)
	bottom.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = TRAIL_NAME
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = ColorSequence.new(Color3.fromHex(item.Colors[1]), Color3.fromHex(item.Colors[#item.Colors]))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = Config.Cosmetics.TrailLifetime
	trail.LightEmission = 0.5
	trail.Enabled = false
	trail.Parent = root
end

local function applyAll(player: Player)
	local character = player.Character
	if character == nil then
		return
	end
	applySkin(character, CosmeticService.equippedIn(player, "Skin"))
	local hat = CosmeticService.equippedIn(player, "Hat")
	Attached.build(character, "CosmeticHat", if hat then hat.Parts else nil)
	local back = CosmeticService.equippedIn(player, "BackItem")
	Attached.build(character, "CosmeticBack", if back then back.Parts else nil)
	applyTrail(character, CosmeticService.equippedIn(player, "DashTrail"))
end

local function onDashed(_player: Player, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	local trail = root and root:FindFirstChild(TRAIL_NAME)
	if trail and trail:IsA("Trail") then
		trail.Enabled = true
		task.delay(Config.Combat.Dash.Duration, function()
			trail.Enabled = false
		end)
	end
end

local function burst(position: Vector3, colors: { string })
	local anchor = Instance.new("Part")
	anchor.Name = "KOEffect"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = position
	local keypoints: { ColorSequenceKeypoint } = {}
	for index, hex in colors do
		local time = if #colors > 1 then (index - 1) / (#colors - 1) else 0
		table.insert(keypoints, ColorSequenceKeypoint.new(time, Color3.fromHex(hex)))
	end
	if #keypoints == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, Color3.fromHex(colors[1])))
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(keypoints)
	emitter.Speed = NumberRange.new(15, 30)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Size = NumberSequence.new(0.6, 0)
	emitter.Rate = 0
	emitter.Parent = anchor
	anchor.Parent = Workspace
	emitter:Emit(Config.Cosmetics.KOEffectParticles)
	Debris:AddItem(anchor, BURST_LIFETIME)
end

local function onKnockedOut(victim: Model, killer: Player?, cause: string)
	if killer == nil then
		return
	end
	local item = CosmeticService.equippedIn(killer, "KOEffect")
	if item == nil or item.Colors == nil then
		return
	end
	local where = if cause == "Health" then victim else killer.Character
	local root = where and where:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		burst(root.Position, item.Colors)
	end
end

--[[
	Equips `itemId` in `slot` (nil = take the slot off). Without `grant` the player must own it. Returns false for an
	item that is not for that slot, not owned, or before the player's data has loaded.
]]
function CosmeticService.equip(player: Player, slot: string, itemId: string?, grant: boolean?): boolean
	local data = DataService.get(player)
	if data == nil or not table.find(Config.Cosmetics.Slots, slot) then
		return false
	end
	if itemId then
		local item = Config.Cosmetics.Items[itemId]
		if item == nil or item.Slot ~= slot then
			return false
		end
		if not grant and not CosmeticRules.owns(data.Cosmetics.Owned, itemId) then
			return false
		end
	end
	DataService.update(player, "Cosmetics", function(changed)
		if itemId then
			if grant then
				changed.Cosmetics.Owned[itemId] = true
			end
			changed.Cosmetics.Equipped[slot] = itemId
		else
			changed.Cosmetics.Equipped[slot] = nil
		end
	end)
	applyAll(player)
	log(`{player.Name}: {slot} = {itemId or "none"}`)
	return true
end

-- Gives every item in the catalog (developer panel).
function CosmeticService.grantAll(player: Player)
	DataService.update(player, "Cosmetics", function(changed)
		for itemId in Config.Cosmetics.Items do
			changed.Cosmetics.Owned[itemId] = true
		end
	end)
end

local function onCharacterAdded(player: Player, character: Model)
	if
		character:WaitForChild("Head", CHARACTER_WAIT) and character:WaitForChild("HumanoidRootPart", CHARACTER_WAIT)
	then
		character:WaitForChild("BodyColors", CHARACTER_WAIT)
		if player.Character == character then
			applyAll(player)
		end
	end
end

function CosmeticService.Init(_self: any)
	Net.onServerEvent("EquipCosmetic", function(player: Player, slot: string, itemId: string?)
		CosmeticService.equip(player, slot, itemId)
	end)
	CombatService.Dashed:Connect(onDashed)
	CombatService.KnockedOut:Connect(onKnockedOut)
	DataService.Loaded:Connect(function(player: Player)
		applyAll(player)
	end)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return CosmeticService
