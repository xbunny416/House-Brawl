--!strict
--[[
	Cosmetic slots, rarity pricing, the daily rotating shop and the item catalog. Bible §2.3 / §4.1 (launch: 6 skins,
	6 hats, 4 dash trails, 4 KO effects, 4 victory emotes). Visuals are blockout data until the art pass: skins are
	body colors, hats are welded parts, trails / KO effects are colors. Names come from "Cosmetic.<Id>.Name".
]]
local Types = require(script.Parent.Types)

type CosmeticsConfig = {
	Slots: { string },
	Rarities: { [string]: { MinPrice: number, MaxPrice: number, RobuxOnly: boolean } },
	DailyRotation: { Count: number, ResetHourUTC: number, Discount: number },
	TrailLifetime: number,
	KOEffectParticles: number,
	Items: { [string]: Types.CosmeticItem },
}

local function part(
	name: string,
	size: { number },
	offset: { number },
	rotation: { number },
	material: string,
	color: string,
	shape: string?
): Types.AttachedPart
	return {
		Name = name,
		Attach = "Head",
		Size = { X = size[1], Y = size[2], Z = size[3] },
		Offset = offset,
		Rotation = rotation,
		Shape = shape,
		Material = material,
		Color = color,
	}
end

local NO_TURN = { 0, 0, 0 }
local UPRIGHT = { 0, 0, 90 } -- turns a cylinder's axis (X) to point up

local Cosmetics: CosmeticsConfig = {
	Slots = { "Skin", "Hat", "BackItem", "DashTrail", "KOEffect", "VictoryEmote", "NameplateFrame" },
	Rarities = {
		Common = { MinPrice = 300, MaxPrice = 800, RobuxOnly = false },
		Rare = { MinPrice = 1200, MaxPrice = 2500, RobuxOnly = false },
		Premium = { MinPrice = 0, MaxPrice = 0, RobuxOnly = true },
	},
	-- The Shop's Daily tab: Count cosmetics picked every day (UTC, at ResetHourUTC), sold at Discount off.
	DailyRotation = { Count = 4, ResetHourUTC = 0, Discount = 0.2 },
	TrailLifetime = 0.3, -- seconds a dash trail lingers
	KOEffectParticles = 40, -- particles in one KO burst

	Items = {
		-- Skins: body colors (head, torso, arms, legs).
		RustBucket = {
			Slot = "Skin",
			Rarity = "Common",
			Price = 400,
			Colors = { "#B5652B", "#8C4A2F", "#B5652B", "#5A3A28" },
		},
		ScrapMetal = {
			Slot = "Skin",
			Rarity = "Common",
			Price = 500,
			Colors = { "#9AA0A6", "#6E737A", "#9AA0A6", "#4B4F55" },
		},
		HazardOrange = {
			Slot = "Skin",
			Rarity = "Common",
			Price = 700,
			Colors = { "#E8742A", "#2B2B2B", "#E8742A", "#2B2B2B" },
		},
		NeonPunk = {
			Slot = "Skin",
			Rarity = "Rare",
			Price = 1500,
			Colors = { "#3FF2E0", "#E040FB", "#3FF2E0", "#1A1033" },
		},
		ChromeKing = {
			Slot = "Skin",
			Rarity = "Rare",
			Price = 2500,
			Colors = { "#E6E9ED", "#C0C6CC", "#E6E9ED", "#8D949C" },
		},
		PremiumGold = {
			Slot = "Skin",
			Rarity = "Premium",
			Price = 0,
			Exclusive = "Premium", -- bible §7: one exclusive Premium skin
			Colors = { "#F2C14E", "#D9A21B", "#F2C14E", "#8C6A12" },
		},

		-- Hats: welded to the head (offsets from the head's center).
		ConeHat = {
			Slot = "Hat",
			Rarity = "Common",
			Price = 300,
			Parts = {
				part("Base", { 1.6, 0.2, 1.6 }, { 0, 0.7, 0 }, NO_TURN, "SmoothPlastic", "#E8742A"),
				part("Cone", { 1, 1.6, 1 }, { 0, 1.55, 0 }, NO_TURN, "SmoothPlastic", "#E8742A"),
				part("Stripe", { 1.02, 0.3, 1.02 }, { 0, 1.5, 0 }, NO_TURN, "SmoothPlastic", "#F2F2F2"),
			},
		},
		BucketHelm = {
			Slot = "Hat",
			Rarity = "Common",
			Price = 450,
			Parts = { part("Bucket", { 1.2, 1.5, 1.5 }, { 0, 0.6, 0 }, UPRIGHT, "Metal", "#B8B2A6", "Cylinder") },
		},
		HubcapHat = {
			Slot = "Hat",
			Rarity = "Common",
			Price = 600,
			Parts = { part("Hubcap", { 0.2, 2, 2 }, { 0, 0.75, 0 }, UPRIGHT, "DiamondPlate", "#D8DCE0", "Cylinder") },
		},
		TireCrown = {
			Slot = "Hat",
			Rarity = "Rare",
			Price = 1200,
			Parts = { part("Tire", { 0.6, 1.9, 1.9 }, { 0, 0.85, 0 }, UPRIGHT, "SmoothPlastic", "#2B2B2B", "Cylinder") },
		},
		WeldingMask = {
			Slot = "Hat",
			Rarity = "Rare",
			Price = 1800,
			Parts = {
				part("Mask", { 1.3, 1.3, 0.3 }, { 0, 0.05, -0.65 }, NO_TURN, "Metal", "#3A3A3A"),
				part("Visor", { 0.8, 0.25, 0.05 }, { 0, 0.15, -0.82 }, NO_TURN, "Neon", "#1DE9B6"),
			},
		},
		PropellerCap = {
			Slot = "Hat",
			Rarity = "Rare",
			Price = 2200,
			Parts = {
				part("Cap", { 0.5, 1.3, 1.3 }, { 0, 0.7, 0 }, UPRIGHT, "SmoothPlastic", "#E53935", "Cylinder"),
				part("Stem", { 0.1, 0.4, 0.1 }, { 0, 1.1, 0 }, NO_TURN, "Metal", "#9AA0A6"),
				part("Blade", { 1.6, 0.05, 0.25 }, { 0, 1.32, 0 }, NO_TURN, "SmoothPlastic", "#FFEB3B"),
			},
		},

		-- Dash trails: start → end color of the streak behind a dash.
		SmokeTrail = { Slot = "DashTrail", Rarity = "Common", Price = 400, Colors = { "#BDBDBD", "#5A5A5A" } },
		SparkTrail = { Slot = "DashTrail", Rarity = "Common", Price = 700, Colors = { "#FFD54F", "#FF6F00" } },
		ToxicTrail = { Slot = "DashTrail", Rarity = "Rare", Price = 1500, Colors = { "#B2FF59", "#33691E" } },
		GoldTrail = {
			Slot = "DashTrail",
			Rarity = "Premium",
			Price = 0,
			Exclusive = "VIP", -- bible §7: exclusive gold dash trail for VIP
			Colors = { "#FFE082", "#F2C14E" },
		},

		-- KO effects: particle colors of the burst on every KO you score.
		ScrapBurst = { Slot = "KOEffect", Rarity = "Common", Price = 500, Colors = { "#9AA0A6", "#B5652B" } },
		ConfettiPop = {
			Slot = "KOEffect",
			Rarity = "Common",
			Price = 800,
			Colors = { "#FF4081", "#40C4FF", "#FFEB3B" },
		},
		ToxicSplash = { Slot = "KOEffect", Rarity = "Rare", Price = 1600, Colors = { "#B2FF59", "#64DD17" } },
		NeonStars = { Slot = "KOEffect", Rarity = "Rare", Price = 2400, Colors = { "#3FF2E0", "#E040FB" } },

		-- Victory emotes: played by the round winner on the results screen (animations arrive in step 2.6).
		Flex = { Slot = "VictoryEmote", Rarity = "Common", Price = 500, Emote = "Flex" },
		JunkDance = { Slot = "VictoryEmote", Rarity = "Common", Price = 800, Emote = "JunkDance" },
		Taunt = { Slot = "VictoryEmote", Rarity = "Rare", Price = 1500, Emote = "Taunt" },
		Champion = { Slot = "VictoryEmote", Rarity = "Rare", Price = 2000, Emote = "Champion" },
	},
}

return Cosmetics
