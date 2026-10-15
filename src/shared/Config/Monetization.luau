--!strict
-- Game passes, developer products and private servers. Bible §7.
-- Ids are 0 until the passes/products are created on the Creator Dashboard; Robux prices here are for reference
-- only (the live price always comes from MarketplaceService). Nothing sold gives a combat advantage.
type MonetizationConfig = {
	GamePasses: { [string]: { Id: number, PriceRobux: number } },
	Products: { [string]: { Id: number, PriceRobux: number, Scrap: number } },
	PremiumCosmeticPrice: { Min: number, Max: number },
	PrivateServerPriceRobux: number,
}

local Monetization: MonetizationConfig = {
	GamePasses = {
		VIP = { Id = 0, PriceRobux = 299 }, -- +25% Scrap (Economy.Bonuses), gold tags, gold dash trail
		EmotePack = { Id = 0, PriceRobux = 149 }, -- 4 extra victory emotes
	},
	Products = {
		ScrapPackS = { Id = 0, PriceRobux = 49, Scrap = 500 },
		ScrapPackM = { Id = 0, PriceRobux = 149, Scrap = 2000 },
		ScrapPackL = { Id = 0, PriceRobux = 399, Scrap = 6000 },
	},
	PremiumCosmeticPrice = { Min = 99, Max = 399 },
	PrivateServerPriceRobux = 100,
}

return Monetization
