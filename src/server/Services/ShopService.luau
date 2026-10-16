--!strict
--[[
	ShopService — buying fighting styles and cosmetics with Scrap (bible §2.3). The Buy remote (kind, id, price shown)
	is checked with Shared/ShopRules against the player's saved data and today's daily rotation (os.time, UTC); then
	the Scrap is spent (DataService.spendScrap: analytics sink, sku "Style.<id>" / "Cosmetic.<id>") and the item is
	granted through StyleService / CosmeticService. Buying never equips: the Shop offers Equip after a purchase.
	Robux items (game passes, Scrap packs, premium cosmetics) come with step 3.1.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local CosmeticService = require(script.Parent:WaitForChild("CosmeticService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local StyleService = require(script.Parent:WaitForChild("StyleService"))

local ShopService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Shop] {message}`)
	end
end

--[[
	Buys an item for `player`. `expectedPrice` is the price their Shop showed (nil skips that check). Returns true, or
	false and a reason from ShopRules.Reasons.
]]
function ShopService.buy(player: Player, kind: string, itemId: string, expectedPrice: number?): (boolean, string?)
	local data = DataService.get(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local day = ShopRules.dayAt(os.time())
	local price, reason = ShopRules.check(data, kind, itemId, day, expectedPrice)
	if price == nil then
		log(`{player.Name} could not buy {kind} {itemId}: {reason}`)
		return false, reason
	end
	if not DataService.spendScrap(player, price, Analytics.Transaction.Shop, `{kind}.{itemId}`) then
		return false, "NotEnoughScrap"
	end
	if kind == "Style" then
		StyleService.grant(player, itemId)
	else
		CosmeticService.grant(player, itemId)
	end
	Analytics.shopPurchase(player, kind, itemId, price, ShopRules.isDaily(kind, itemId, day))
	log(`{player.Name} bought {kind} {itemId} for {price} Scrap`)
	return true, nil
end

function ShopService.Init(_self: any)
	Net.onServerInvoke("Buy", function(player: Player, kind: string, itemId: string, price: number)
		return ShopService.buy(player, kind, itemId, price)
	end)
end

return ShopService
