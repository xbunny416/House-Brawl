--!strict
--[[
	StyleService — fighting styles (bible §2.3). Players own styles (saved Styles.Owned) and have one equipped
	(Styles.Equipped); CombatService uses the equipped style's numbers (damage, reach, speed, hitbox, parry).
	Styles unlock for free at their UnlockLevel (buying them with Scrap comes with the Shop, step 2.4). The
	EquipStyle remote switches to an owned style, but not while the player is fighting in a round.
	The weapon is a welded blockout model on the character (Config.Styles.Weapons): visual only — no collisions,
	not hit by attack boxes. Weapons are accessories, not Tools, so the mobile buttons never change.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local StyleRules = require(Shared:WaitForChild("StyleRules"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

local WEAPON_NAME = "StyleWeapon"
local HAND_WAIT = 10

local StyleService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Styles] {message}`)
	end
end

function StyleService.equippedOf(player: Player): string
	local data = DataService.get(player)
	local style = data and data.Styles.Equipped
	return if style and Config.Styles.List[style] then style else Config.Styles.Default
end

-- Replaces the weapon model on `character` with the one for `weaponId` (none for fists).
local function buildWeapon(character: Model, weaponId: string)
	local old = character:FindFirstChild(WEAPON_NAME)
	if old then
		old:Destroy()
	end
	local parts = Config.Styles.Weapons[weaponId]
	if parts == nil then
		return
	end
	local model = Instance.new("Model")
	model.Name = WEAPON_NAME
	for _, spec in parts do
		local hand = character:FindFirstChild(`{spec.Hand}Hand`)
		if hand == nil or not hand:IsA("BasePart") then
			continue
		end
		local part = Instance.new("Part")
		part.Name = spec.Name
		part.Size = Vector3.new(spec.Size.X, spec.Size.Y, spec.Size.Z)
		part.Shape = (Enum.PartType :: any)[spec.Shape or "Block"]
		part.Material = (Enum.Material :: any)[spec.Material]
		part.Color = Color3.fromHex(spec.Color)
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		local rotation =
			CFrame.Angles(math.rad(spec.Rotation[1]), math.rad(spec.Rotation[2]), math.rad(spec.Rotation[3]))
		part.CFrame = hand.CFrame * CFrame.new(spec.Offset[1], spec.Offset[2], spec.Offset[3]) * rotation
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
	end
	model.Parent = character
end

local function refreshWeapon(player: Player)
	local character = player.Character
	if character then
		buildWeapon(character, Config.Styles.List[StyleService.equippedOf(player)].Weapon)
	end
end

-- Gives the player every style their level unlocks (saved; no-op if they own them all already).
local function grantLevelUnlocks(player: Player, level: number)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local new: { string } = {}
	for _, styleId in StyleRules.unlockedAt(level) do
		if not StyleRules.owns(data.Styles.Owned, styleId) then
			table.insert(new, styleId)
		end
	end
	if #new == 0 then
		return
	end
	DataService.update(player, "Styles", function(changed)
		for _, styleId in new do
			changed.Styles.Owned[styleId] = true
		end
	end)
	log(`{player.Name} unlocked {table.concat(new, ", ")}`)
end

--[[
	Equips a style. Without `grant` the player must own it. Returns false for an unknown or unowned style, or before
	their data has loaded. (`grant` = also give it: developer panel, Shop purchases.)
]]
function StyleService.equip(player: Player, styleId: string, grant: boolean?): boolean
	local data = DataService.get(player)
	if data == nil or Config.Styles.List[styleId] == nil then
		return false
	end
	if not grant and not StyleRules.owns(data.Styles.Owned, styleId) then
		return false
	end
	DataService.update(player, "Styles", function(changed)
		if grant then
			changed.Styles.Owned[styleId] = true
		end
		changed.Styles.Equipped = styleId
	end)
	refreshWeapon(player)
	log(`{player.Name} equipped {styleId}`)
	return true
end

local function onCharacterAdded(player: Player, character: Model)
	if character:WaitForChild("RightHand", HAND_WAIT) and character:WaitForChild("LeftHand", HAND_WAIT) then
		if player.Character == character then
			refreshWeapon(player)
		end
	end
end

function StyleService.Init(_self: any)
	Net.onServerEvent("EquipStyle", function(player: Player, styleId: string)
		local status = RoundService.getStatus(player)
		if status == "Playing" or status == "Respawning" then
			return -- no switching styles mid-fight
		end
		StyleService.equip(player, styleId)
	end)
	DataService.Loaded:Connect(function(player: Player, data)
		grantLevelUnlocks(player, data.Level)
		refreshWeapon(player)
	end)
	DataService.LeveledUp:Connect(grantLevelUnlocks)
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

return StyleService
