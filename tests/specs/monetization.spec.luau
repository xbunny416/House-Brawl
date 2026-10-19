--!strict
-- Monetization (step 3.1): passes, products, perk cosmetics and Roblox policy checks.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local MonetizationRules = Roblox.require(Shared.MonetizationRules)
local PolicyRules = Roblox.require(Shared.PolicyRules)

local Monetization = Config.Monetization

local function count(list: { string }, value: string): number
	local total = 0
	for _, entry in list do
		if entry == value then
			total += 1
		end
	end
	return total
end

return {
	["bible §7 prices and contents"] = function()
		expect.equal(Monetization.GamePasses.VIP.PriceRobux, 299)
		expect.equal(Monetization.GamePasses.EmotePack.PriceRobux, 149)
		expect.equal(Monetization.Products.ScrapPackS.Scrap, 500)
		expect.equal(Monetization.Products.ScrapPackM.Scrap, 2000)
		expect.equal(Monetization.Products.ScrapPackL.Scrap, 6000)
		expect.equal(Config.Economy.Bonuses.VIPScrap, 0.25)
		expect.equal(Config.Economy.Bonuses.PremiumScrap, 0.1)
		expect.equal(#MonetizationRules.itemsFrom("EmotePack"), 4, "the Emote Pack's 4 emotes")
		for _, id in MonetizationRules.itemsFrom("EmotePack") do
			expect.equal(Config.Cosmetics.Items[id].Slot, "VictoryEmote", id)
		end
		expect.truthy(table.find(MonetizationRules.itemsFrom("VIP"), "GoldTrail"), "VIP gold dash trail")
		expect.truthy(table.find(MonetizationRules.itemsFrom("Premium"), "PremiumGold"), "Premium skin")
	end,
	["every pass is a perk; every exclusive comes from a perk or a Robux product"] = function()
		for key in Monetization.GamePasses do
			expect.truthy(MonetizationRules.isPerk(key), `{key} is a perk`)
		end
		for id, item in Config.Cosmetics.Items do
			local source = item.Exclusive
			if source == "Robux" then
				expect.truthy(MonetizationRules.productFor(id), `{id} needs a product`)
			elseif source then
				expect.truthy(MonetizationRules.isPerk(source), `{id}: unknown source {source}`)
			end
		end
	end,
	["Robux products: whole Scrap amounts or a Robux cosmetic, priced inside the premium range"] = function()
		for key, product in Monetization.Products do
			local gives = (if product.Scrap then 1 else 0)
				+ (if product.Cosmetic then 1 else 0)
				+ (if product.StyleSlot then 1 else 0)
			expect.equal(gives, 1, `{key}: Scrap, a cosmetic or a style slot`)
			if product.Scrap then
				expect.truthy(product.Scrap > 0 and product.Scrap == math.floor(product.Scrap), `{key} Scrap`)
			end
			local cosmetic = product.Cosmetic
			if cosmetic then
				local item = Config.Cosmetics.Items[cosmetic]
				expect.truthy(item, `{key}: unknown cosmetic {cosmetic}`)
				expect.equal(item and item.Exclusive, "Robux", `{cosmetic} is Robux-only`)
				local range = Monetization.PremiumCosmeticPrice
				expect.truthy(product.PriceRobux >= range.Min and product.PriceRobux <= range.Max, `{key} price`)
			end
		end
	end,
	["the Robux tab lists every pass and product once (the style slot is sold on the Styles page)"] = function()
		local order = Monetization.RobuxOrder
		for key in Monetization.GamePasses do
			expect.equal(count(order, key), 1, key)
		end
		for key, product in Monetization.Products do
			expect.equal(count(order, key), if product.StyleSlot then 0 else 1, key)
		end
		local offers = MonetizationRules.offers()
		expect.equal(#offers, #order)
		expect.equal(offers[1].Key, order[1])
		expect.equal(MonetizationRules.offer("VIP").Kind, "Pass")
		expect.equal(MonetizationRules.offer("ScrapPackM").Kind, "Product")
		expect.equal(MonetizationRules.offer("ScrapPackM").Scrap, 2000)
		expect.equal(MonetizationRules.offer("Nope"), nil)
	end,
	["offers with id 0 can't be bought; ids of 0 never match a receipt"] = function()
		local vip = MonetizationRules.offer("VIP") :: MonetizationRules.Offer
		expect.equal(MonetizationRules.isAvailable(vip), Monetization.GamePasses.VIP.Id > 0)
		expect.equal(MonetizationRules.isAvailable({ Key = "X", Kind = "Product", Id = 0, PriceRobux = 49 }), false)
		expect.equal(MonetizationRules.isAvailable({ Key = "X", Kind = "Product", Id = 123, PriceRobux = 49 }), true)
		expect.equal(MonetizationRules.productKeyFor(0), nil)
		expect.equal(MonetizationRules.passKeyFor(0), nil)
		expect.equal(MonetizationRules.productKeyFor(-5), nil)
		for key, product in Monetization.Products do
			if product.Id > 0 then
				expect.equal(MonetizationRules.productKeyFor(product.Id), key)
			end
		end
	end,
	["offer names: the perk, the cosmetic, or the Scrap pack"] = function()
		local vip = MonetizationRules.offer("VIP") :: MonetizationRules.Offer
		local inferno = MonetizationRules.offer("InfernoSkin") :: MonetizationRules.Offer
		local pack = MonetizationRules.offer("ScrapPackS") :: MonetizationRules.Offer
		expect.equal(MonetizationRules.nameKey(vip), "Perk.VIP")
		expect.equal(MonetizationRules.nameKey(inferno), "Cosmetic.Inferno.Name")
		expect.equal(MonetizationRules.nameKey(pack), "Robux.ScrapPackS.Name")
	end,
	["perk cosmetics are granted with the perk and taken back without it; unknown perks change nothing"] = function()
		local grant, revoke = MonetizationRules.ownershipChanges({}, { VIP = true })
		expect.equal(table.concat(grant, ","), table.concat(MonetizationRules.itemsFrom("VIP"), ","))
		expect.equal(#revoke, 0)

		grant, revoke = MonetizationRules.ownershipChanges({ GoldTrail = true, ConeHat = true }, { VIP = false })
		expect.equal(#grant, 0)
		expect.equal(table.concat(revoke, ","), "GoldTrail", "Scrap items stay")

		grant, revoke = MonetizationRules.ownershipChanges({ GoldTrail = true, PremiumGold = true }, {})
		expect.equal(#grant + #revoke, 0, "nothing known yet")

		grant, revoke = MonetizationRules.ownershipChanges({ Inferno = true }, { VIP = false, EmotePack = false })
		expect.equal(#revoke, 0, "Robux cosmetics are kept")

		grant = MonetizationRules.ownershipChanges({ Robot = true }, { EmotePack = true })
		expect.equal(#grant, 3, "only the missing emotes")
		grant, revoke = MonetizationRules.ownershipChanges({}, { Premium = true, VIP = false })
		expect.equal(table.concat(grant, ","), "PremiumGold")
		expect.equal(#revoke, 0)
	end,
	["policy: features are off until the policy is known, then follow Roblox's flags"] = function()
		for _, feature in PolicyRules.Features do
			expect.equal(PolicyRules.allows(nil, feature), false, `{feature} without a policy`)
		end
		local open = {
			ArePaidRandomItemsRestricted = false,
			IsPaidItemTradingAllowed = true,
			AllowedExternalLinkReferences = { "Discord" },
		}
		local strict = {
			ArePaidRandomItemsRestricted = true,
			IsPaidItemTradingAllowed = false,
			AllowedExternalLinkReferences = {},
		}
		expect.equal(PolicyRules.allows(open, "PaidRandomItems"), true)
		expect.equal(PolicyRules.allows(open, "PaidTrading"), true)
		expect.equal(PolicyRules.allows(strict, "PaidRandomItems"), false)
		expect.equal(PolicyRules.allows(strict, "PaidTrading"), false)
		expect.equal(PolicyRules.allows(open, "Nope"), false, "unknown feature")
		expect.equal(PolicyRules.allows({}, "PaidRandomItems"), false, "missing flag")
		expect.equal(PolicyRules.allowsLink(open, "Discord"), true)
		expect.equal(PolicyRules.allowsLink(open, "YouTube"), false)
		expect.equal(PolicyRules.allowsLink(strict, "Discord"), false)
		expect.equal(PolicyRules.allowsLink(nil, "Discord"), false)
	end,
}
