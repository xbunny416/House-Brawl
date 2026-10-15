--!strict
-- Cosmetic slots, rarity pricing and the daily rotating shop. Bible §2.3. The item catalog is added in step 2.3.
type CosmeticsConfig = {
	Slots: { string },
	Rarities: { [string]: { MinPrice: number, MaxPrice: number, RobuxOnly: boolean } },
	DailyRotation: { Count: number, ResetHourUTC: number },
	Items: { [string]: { Slot: string, Rarity: string, Price: number } },
}

local Cosmetics: CosmeticsConfig = {
	Slots = { "Skin", "Hat", "BackItem", "DashTrail", "KOEffect", "VictoryEmote", "NameplateFrame" },
	Rarities = {
		Common = { MinPrice = 300, MaxPrice = 800, RobuxOnly = false },
		Rare = { MinPrice = 1200, MaxPrice = 2500, RobuxOnly = false },
		Premium = { MinPrice = 0, MaxPrice = 0, RobuxOnly = true },
	},
	DailyRotation = { Count = 4, ResetHourUTC = 0 },
	Items = {},
}

return Cosmetics
