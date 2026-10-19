--!strict
--[[
	Game passes, developer products, Roblox Premium perks and private servers. Bible §7. Nothing sold gives a combat
	advantage. Ids are 0 until the passes / products are created on the Creator Dashboard (Monetization → Passes /
	Developer Products); an item with id 0 shows "Coming soon" in the Shop and can't be bought. PriceRobux is for
	reference only: the Shop shows the live price from MarketplaceService once it has loaded.
	  * Passes unlock the cosmetics whose Exclusive is the pass key (VIP → GoldTrail) for as long as the player owns
	    the pass (the Emote Pack pass went with the victory emotes, owner 2026-10-19). VIP also gives +25% Scrap
	    (Economy.Bonuses.VIPScrap) and a gold name tag and chat tag in VIPColor.
	  * Roblox Premium (not sold here) unlocks the cosmetics whose Exclusive is "Premium" and +10% Scrap while the
	    player is subscribed.
	  * Products: Scrap packs (Scrap), Robux-only cosmetics (Cosmetic = the item, whose Exclusive is "Robux") and the
	    style slot (StyleSlot: one more slot for the style roll, up to Config.Styles.Roll.Slots.Max; sold on the
	    Styles screen, not in the Shop's Robux tab), granted once per purchase (DataService.processReceipt)
	    and kept for good.
]]
export type Pass = { Id: number, PriceRobux: number }
export type Product = { Id: number, PriceRobux: number, Scrap: number?, Cosmetic: string?, StyleSlot: boolean? }

type MonetizationConfig = {
	GamePasses: { [string]: Pass },
	Products: { [string]: Product },
	RobuxOrder: { string },
	VIPColor: string,
	WebRetries: { Attempts: number, Delay: number },
	PremiumCosmeticPrice: { Min: number, Max: number },
	PrivateServerPriceRobux: number,
}

local Monetization: MonetizationConfig = {
	GamePasses = {
		VIP = { Id = 0, PriceRobux = 299 }, -- +25% Scrap, gold name + chat tags, exclusive gold dash trail
	},
	Products = {
		ScrapPackS = { Id = 0, PriceRobux = 49, Scrap = 500 },
		ScrapPackM = { Id = 0, PriceRobux = 149, Scrap = 2000 },
		ScrapPackL = { Id = 0, PriceRobux = 399, Scrap = 6000 },
		-- Premium cosmetics (Robux only, within PremiumCosmeticPrice).
		InfernoSkin = { Id = 0, PriceRobux = 149, Cosmetic = "Inferno" },
		LightningTrail = { Id = 0, PriceRobux = 99, Cosmetic = "LightningTrail" },
		GalaxyBurst = { Id = 0, PriceRobux = 199, Cosmetic = "GalaxyBurst" },
		-- One more style slot (owner, 2026-10-19: extra style slots are bought with Robux).
		StyleSlot = { Id = 0, PriceRobux = 99, StyleSlot = true },
	},
	-- The Shop's Robux tab, in this order (game pass and product keys).
	RobuxOrder = {
		"VIP",
		"ScrapPackS",
		"ScrapPackM",
		"ScrapPackL",
		"InfernoSkin",
		"LightningTrail",
		"GalaxyBurst",
	},
	VIPColor = "#F2C14E", -- VIP name tag and [VIP] chat tag
	-- Roblox web calls (pass ownership, policy info): tries, and seconds between them.
	WebRetries = { Attempts = 3, Delay = 2 },
	PremiumCosmeticPrice = { Min = 99, Max = 399 },
	PrivateServerPriceRobux = 100,
}

return Monetization
