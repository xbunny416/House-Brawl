--!strict
--[[
	StyleService — fighting styles (bible §2.3) and the style roll (owner's fix list, 2026-10-19; Shared/StyleRules,
	Config.Styles.Roll). A player's styles are slots (saved Styles): the equipped slot's style is the one they fight
	with (Styles.Equipped; CombatService reads its numbers: damage, reach, speed, hitbox, parry).
	  * SpinStyle (kind "Free" / "Paid"): puts a random style into the equipped slot unless it is locked. The free
	    spin comes back every day and pays nothing in private servers; a paid spin costs Roll.SpinPrice Scrap
	    (DataService.spendScrap, Shop sink, sku "StyleSpin") and only where PolicyService allows paid random items.
	    The server rolls (Random) and answers with the style, so the client can play the reel and land on it.
	  * EquipStyleSlot / LockStyleSlot: pick the equipped slot, lock or unlock a slot. Styles never change while the
	    player is fighting in a round.
	  * More slots come from the StyleSlot Robux product (MonetizationService → addSlot), up to Roll.Slots.Max.
	The weapon is a welded model on the character (its template in ReplicatedStorage.Assets.Models.Weapons, from
	Config.Styles.Weapons): visual only — no collisions, not hit by attack boxes. Weapons are accessories, not Tools,
	so the mobile buttons never change.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local StyleRules = require(Shared:WaitForChild("StyleRules"))

local Attached = require(script.Parent.Parent:WaitForChild("Visuals"):WaitForChild("Attached"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerPolicyService = require(script.Parent:WaitForChild("PlayerPolicyService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

local WEAPON_NAME = "StyleWeapon"
local HAND_WAIT = 10

export type SpinResult = { Style: string, Rarity: string, Pity: boolean }

local StyleService = {}

local random = Random.new()

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

-- Replaces the weapon model on `character` with a clone of the one for `weaponId` (ReplicatedStorage.Assets.Models.
-- Weapons; none for fists).
local function buildWeapon(character: Model, weaponId: string)
	local weapons = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Weapons")
	Attached.build(character, WEAPON_NAME, weapons:FindFirstChild(weaponId))
end

local function refreshWeapon(player: Player)
	local character = player.Character
	if character then
		buildWeapon(character, Config.Styles.List[StyleService.equippedOf(player)].Weapon)
	end
end

local function isFighting(player: Player): boolean
	local status = RoundService.getStatus(player)
	return status == "Playing" or status == "Respawning"
end

--[[
	Spins the style roll for `player` (kind "Free" or "Paid"). Returns true and what they rolled, or false and a
	reason from StyleRules.Reasons.
]]
function StyleService.spin(player: Player, kind: string): (boolean, SpinResult | string)
	local data = DataService.get(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local day = StyleRules.dayAt(os.time())
	local reason = StyleRules.checkSpin(data.Styles, kind, day, data.Scrap, {
		Fighting = isFighting(player),
		PaidAllowed = PlayerPolicyService.allows(player, "PaidRandomItems"),
		FreeAllowed = PrivateServerService.paysRewards(),
	})
	if reason then
		log(`{player.Name} could not spin ({kind}): {reason}`)
		return false, reason
	end
	if kind == "Paid" then
		local price = Config.Styles.Roll.SpinPrice
		if not DataService.spendScrap(player, price, Analytics.Transaction.Shop, "StyleSpin") then
			return false, "NotEnoughScrap"
		end
	end
	local pity = StyleRules.isPitySpin(data.Styles.Pity)
	local styleId = StyleRules.pick(random:NextNumber(), data.Styles.Pity)
	DataService.update(player, "Styles", function(changed)
		StyleRules.applySpin(changed.Styles, kind, day, styleId)
	end)
	refreshWeapon(player)
	local rarity = Config.Styles.List[styleId].Rarity
	Analytics.custom(player, "StyleSpin", if kind == "Paid" then Config.Styles.Roll.SpinPrice else 0, {
		kind,
		styleId,
		rarity,
	})
	log(`{player.Name} spun ({kind}): {styleId} ({rarity}){if pity then " — pity" else ""}`)
	return true, { Style = styleId, Rarity = rarity, Pity = pity }
end

-- Equips slot `index`. Returns false for a slot the player doesn't have, while fighting or before their data loads.
function StyleService.equipSlot(player: Player, index: number): boolean
	local data = DataService.get(player)
	if data == nil or isFighting(player) or not StyleRules.isSlot(data.Styles, index) then
		return false
	end
	DataService.update(player, "Styles", function(changed)
		StyleRules.equipSlot(changed.Styles, index)
	end)
	refreshWeapon(player)
	log(`{player.Name} equipped slot {index} ({StyleService.equippedOf(player)})`)
	return true
end

-- Locks or unlocks slot `index` (a locked slot is never replaced by a spin).
function StyleService.lockSlot(player: Player, index: number, locked: boolean): boolean
	local data = DataService.get(player)
	if data == nil or not StyleRules.isSlot(data.Styles, index) then
		return false
	end
	return DataService.update(player, "Styles", function(changed)
		changed.Styles.Locked[index] = locked
	end)
end

--[[
	Adds a style slot (the StyleSlot Robux product, the developer panel). Returns false if the player already has
	Roll.Slots.Max slots or their data hasn't loaded.
]]
function StyleService.addSlot(player: Player): boolean
	local data = DataService.get(player)
	if data == nil or not StyleRules.canAddSlot(data.Styles) then
		return false
	end
	return DataService.update(player, "Styles", function(changed)
		StyleRules.addSlot(changed.Styles)
	end)
end

-- Developer panel: puts `styleId` into the equipped slot (locked or not) and equips it.
function StyleService.setStyle(player: Player, styleId: string): boolean
	if Config.Styles.List[styleId] == nil or DataService.get(player) == nil then
		return false
	end
	DataService.update(player, "Styles", function(changed)
		changed.Styles.Slots[changed.Styles.Active] = styleId
		changed.Styles.Equipped = styleId
	end)
	refreshWeapon(player)
	log(`{player.Name} got {styleId} in their equipped slot`)
	return true
end

-- Developer panel: changes the roll's saved state (`pity`: spins since the last pity-rarity style; `freeSpin`: make
-- today's free spin available again).
function StyleService.setRollState(player: Player, pity: number?, freeSpin: boolean?)
	DataService.update(player, "Styles", function(changed)
		if pity then
			changed.Styles.Pity = pity
		end
		if freeSpin then
			changed.Styles.FreeSpinDay = -1
		end
	end)
end

local function onCharacterAdded(player: Player, character: Model)
	if character:WaitForChild("RightHand", HAND_WAIT) and character:WaitForChild("LeftHand", HAND_WAIT) then
		if player.Character == character then
			refreshWeapon(player)
		end
	end
end

function StyleService.Init(_self: any)
	Net.onServerInvoke("SpinStyle", function(player: Player, kind: string)
		return StyleService.spin(player, kind)
	end)
	Net.onServerEvent("EquipStyleSlot", function(player: Player, index: number)
		StyleService.equipSlot(player, index)
	end)
	Net.onServerEvent("LockStyleSlot", function(player: Player, index: number, locked: boolean)
		StyleService.lockSlot(player, index, locked)
	end)
	DataService.Loaded:Connect(function(player: Player)
		refreshWeapon(player)
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

return StyleService
