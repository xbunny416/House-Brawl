--!strict
--[[
	MonetizationService — Robux purchases and perks (bible §7; Config.Monetization, Shared/MonetizationRules).
	  * Perks: the VIP game pass (UserOwnsGamePassAsync once the player's data loads, retried; and
	    PromptGamePassPurchaseFinished for a pass bought in this server) and Roblox Premium (MembershipType, and
	    PlayerMembershipChanged). Each perk is a Player attribute (VIP / Premium: Shop, name and chat tags) and keeps
	    its exclusive cosmetics owned: granted while the perk is there, taken back (and unequipped) once it is known
	    to be gone. `has(player, perk)` feeds the VIP / Premium Scrap bonuses (RewardService).
	  * Developer products: MarketplaceService.ProcessReceipt → DataService.processReceipt (granted once per
	    PurchaseId, confirmed only after the grant is saved). Scrap packs add Scrap (IAP transaction, sku = product
	    key); Robux cosmetics grant their item for good; StyleSlot adds a style slot (StyleService.addSlot), or
	    Config.Styles.Roll.Slots.OverflowScrap when the player already has every slot.
	  * Clients prompt purchases themselves (the Shop's Robux tab); the server only grants what Roblox confirms, then
	    sends a Notify thank-you and logs Analytics.robuxPurchase.
	The developer panel can switch a perk on / off for the session and give a product without a receipt, to test in
	Studio while the ids are 0.
]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MonetizationRules = require(Shared:WaitForChild("MonetizationRules"))
local Net = require(Shared:WaitForChild("Net"))
local Retry = require(Shared:WaitForChild("Util"):WaitForChild("Retry"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local CosmeticService = require(script.Parent:WaitForChild("CosmeticService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local StyleService = require(script.Parent:WaitForChild("StyleService"))

type Perks = { [string]: boolean? }

local MonetizationService = {}

local perks: { [Player]: Perks } = {} -- what Roblox says (nil = not known yet)
local overrides: { [Player]: { [string]: boolean } } = {} -- developer panel, this session only

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Monetization] {message}`)
	end
end

function MonetizationService.has(player: Player, perk: string): boolean
	local override = overrides[player] and overrides[player][perk]
	if override ~= nil then
		return override
	end
	local known = perks[player]
	return known ~= nil and known[perk] == true
end

-- The perks known so far, developer overrides on top.
local function knownPerks(player: Player): Perks
	local known: Perks = table.clone(perks[player] or {})
	local playerOverrides: { [string]: boolean } = overrides[player] or {}
	for perk, value in playerOverrides do
		known[perk] = value
	end
	return known
end

-- Updates the perk attributes and the perk cosmetics the player owns.
local function refresh(player: Player)
	if player.Parent ~= Players then
		return
	end
	for _, perk in MonetizationRules.Perks do
		player:SetAttribute(perk, MonetizationService.has(player, perk))
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local granted, revoked = MonetizationRules.ownershipChanges(data.Cosmetics.Owned, knownPerks(player))
	if #granted > 0 or #revoked > 0 then
		CosmeticService.setOwned(player, granted, revoked)
		log(`{player.Name}: granted {table.concat(granted, ", ")}; took back {table.concat(revoked, ", ")}`)
	end
end

-- Whether the player owns the pass `key`: nil while its id is 0 or when Roblox could not be asked.
local function ownsPass(player: Player, key: string): boolean?
	local passId = Config.Monetization.GamePasses[key].Id
	if passId <= 0 then
		return nil
	end
	local retries = Config.Monetization.WebRetries
	local ok, owns = Retry.call(retries.Attempts, retries.Delay, function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if not ok then
		warn(`[Monetization] could not check the {key} pass for {player.Name}: {owns}`)
		return nil
	end
	return owns == true
end

local function isPremium(player: Player): boolean
	return player.MembershipType == Enum.MembershipType.Premium
end

local function onLoaded(player: Player)
	if player.Parent ~= Players then
		return
	end
	local state: Perks = perks[player] or {}
	perks[player] = state
	state.Premium = isPremium(player)
	refresh(player)
	for key in Config.Monetization.GamePasses do
		local owns = ownsPass(player, key)
		if owns ~= nil and state[key] ~= true then -- a pass bought meanwhile stays
			state[key] = owns
		end
	end
	refresh(player)
end

local function onPassPurchased(player: Player, passId: number, purchased: boolean)
	local key = MonetizationRules.passKeyFor(passId)
	if not purchased or key == nil or player.Parent ~= Players then
		return
	end
	local state: Perks = perks[player] or {}
	perks[player] = state
	state[key] = true
	refresh(player)
	Net.fireClient("Notify", player, `Purchase.Done.{key}`)
	Analytics.robuxPurchase(player, "Pass", key, Config.Monetization.GamePasses[key].PriceRobux)
	log(`{player.Name} bought the {key} pass`)
end

-- What a product gives. Errors if the player's data can't take it (the receipt is then retried later).
local function give(player: Player, key: string)
	local product = Config.Monetization.Products[key]
	if product.Scrap then
		assert(DataService.addScrap(player, product.Scrap, Analytics.Transaction.IAP, key), "data not loaded")
		Net.fireClient("Notify", player, "Purchase.Done.Scrap", { product.Scrap })
	end
	local cosmetic = product.Cosmetic
	if cosmetic then
		assert(CosmeticService.grant(player, cosmetic), "data not loaded")
		Net.fireClient("Notify", player, "Purchase.Done.Cosmetic", { { Key = `Cosmetic.{cosmetic}.Name` } })
	end
	if product.StyleSlot then
		assert(DataService.get(player), "data not loaded")
		if StyleService.addSlot(player) then
			Net.fireClient("Notify", player, "Purchase.Done.StyleSlot")
		else
			-- Every slot already (bought twice at once): never charge for nothing.
			local scrap = Config.Styles.Roll.Slots.OverflowScrap
			assert(DataService.addScrap(player, scrap, Analytics.Transaction.IAP, key), "data not loaded")
			Net.fireClient("Notify", player, "Purchase.SlotsFull", { scrap })
		end
	end
	log(`{player.Name} got the {key} product`)
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local productId = receipt.ProductId
	local key = if type(productId) == "number" then MonetizationRules.productKeyFor(productId) else nil
	if key == nil then
		warn(`[Monetization] receipt for an unknown product {productId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local productKey: string = key
	return DataService.processReceipt(receipt, function(player: Player)
		give(player, productKey)
		local spent = receipt.CurrencySpent
		Analytics.robuxPurchase(player, "Product", productKey, if type(spent) == "number" then spent else 0)
	end)
end

-- Developer panel: switches a perk on / off for this session, whatever the pass / membership says.
function MonetizationService.togglePerk(player: Player, perk: string)
	if not MonetizationRules.isPerk(perk) then
		return
	end
	local playerOverrides = overrides[player] or {}
	overrides[player] = playerOverrides
	playerOverrides[perk] = not MonetizationService.has(player, perk)
	refresh(player)
end

-- Developer panel: what buying the product `key` gives, without a receipt (no analytics).
function MonetizationService.giveProduct(player: Player, key: string)
	if Config.Monetization.Products[key] and DataService.get(player) then
		give(player, key)
	end
end

function MonetizationService.Init(_self: any)
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPassPurchased)
	DataService.Loaded:Connect(onLoaded)
	for _, player in Players:GetPlayers() do
		if DataService.get(player) then
			task.spawn(onLoaded, player)
		end
	end
	Players.PlayerMembershipChanged:Connect(function(player: Player)
		local state = perks[player]
		if state then
			state.Premium = isPremium(player)
			refresh(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		perks[player] = nil
		overrides[player] = nil
	end)
end

return MonetizationService
