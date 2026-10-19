--!strict
--[[
	Fighting styles: side-grades only (different feel, similar strength). Bible §2.3.
	Styles come from the style roll (owner's fix list, 2026-10-19; Shared/StyleRules, Services/StyleService), not from
	levels or the Shop: a spin puts a random style into the player's equipped slot. Each style has a Rarity; Roll.Odds
	gives each rarity's chance in percent (styles of one rarity share it equally) and a rarity missing from Odds is
	never rolled (the default style: everyone starts with it). Every PityAt-th spin without a PityRarity style is
	that rarity for sure. One free spin a day (from FreeSpinResetHourUTC); more cost SpinPrice Scrap, which makes
	them a paid random item (shown odds, hidden where PolicyService restricts them, declared on the maturity form).
	Players start with Slots.Start slots; more are a Robux product each (Config.Monetization.Products.StyleSlot), up
	to Slots.Max; a slot bought when the player already has Max gives Slots.OverflowScrap instead.
]]
local Types = require(script.Parent.Types)

type RollConfig = {
	Odds: { [string]: number },
	RarityOrder: { string },
	RarityColors: { [string]: string },
	PityAt: number,
	PityRarity: string,
	SpinPrice: number,
	FreeSpinResetHourUTC: number,
	Slots: { Start: number, Max: number, OverflowScrap: number },
}

type StylesConfig = {
	Default: string,
	Order: { string },
	Roll: RollConfig,
	List: { [string]: Types.StyleConfig },
	Weapons: { [string]: { Types.AttachedPart } },
}

local NO_CHANGE: Types.StyleAttack = { DamageMultiplier = 1, KnockbackMultiplier = 1, ReachBonus = 0 }

local Styles: StylesConfig = {
	Default = "Brawler",
	Order = { "Brawler", "Slugger", "Scrapper", "Wrecker" },
	Roll = {
		Odds = { Uncommon = 70, Rare = 25, Legendary = 5 }, -- percent; must add up to 100
		RarityOrder = { "Common", "Uncommon", "Rare", "Legendary" }, -- most to least common (odds list, colors)
		RarityColors = { Common = "#B8B8B8", Uncommon = "#5BD16A", Rare = "#4A9BFF", Legendary = "#F2C14E" },
		PityAt = 50, -- the 50th spin since the last Legendary is a Legendary
		PityRarity = "Legendary",
		SpinPrice = 250, -- Scrap per spin after the free one
		FreeSpinResetHourUTC = 0,
		Slots = { Start = 1, Max = 4, OverflowScrap = 1000 },
	},
	List = {
		Brawler = {
			Weapon = "Fists",
			Rarity = "Common",
			AttackSpeed = 1,
			Animations = { Punch = { "Jab", "Cross", "Uppercut" }, Charged = "PowerPunch" },
			Punch = NO_CHANGE,
			Charged = NO_CHANGE,
		},
		-- Baseball bat: harder hits, longer reach, slower swings.
		Slugger = {
			Weapon = "BaseballBat",
			Rarity = "Uncommon",
			AttackSpeed = 0.8,
			Animations = { Punch = { "SwingRight", "SwingLeft", "Smash" }, Charged = "PowerSwing" },
			Punch = { DamageMultiplier = 1.15, KnockbackMultiplier = 1, ReachBonus = 2 },
			Charged = { DamageMultiplier = 1.15, KnockbackMultiplier = 1, ReachBonus = 2 },
		},
		-- Shovel: wide sweeps, a bit less damage, a stronger charged swing.
		Scrapper = {
			Weapon = "Shovel",
			Rarity = "Rare",
			AttackSpeed = 1,
			Animations = { Punch = { "SweepRight", "SweepLeft", "Smash" }, Charged = "PowerSwing" },
			Punch = {
				DamageMultiplier = 0.9,
				KnockbackMultiplier = 1,
				ReachBonus = 0,
				Hitbox = { X = 7, Y = 4, Z = 5 },
			},
			Charged = { DamageMultiplier = 0.9, KnockbackMultiplier = 1.1, ReachBonus = 0 },
		},
		-- Wrench + hubcap shield: the Ability key raises the hubcap for a short parry that reflects knockback.
		Wrecker = {
			Weapon = "WrenchAndHubcap",
			Rarity = "Legendary",
			AttackSpeed = 1,
			Animations = { Punch = { "SwingRight", "SwingLeft", "Smash" }, Charged = "PowerSwing", Ability = "Parry" },
			Punch = { DamageMultiplier = 0.95, KnockbackMultiplier = 1, ReachBonus = 0 },
			Charged = NO_CHANGE,
			Ability = { Parry = { Window = 0.2, ReflectMultiplier = 1 }, Cooldown = 1.2 },
		},
	},

	-- Blockout weapon models (welded accessories, not Tools), keyed by a style's Weapon. "Fists" has none.
	-- Offsets are in the hand's space: -Z points forward out of the fist, -Y down along the arm.
	Weapons = {
		BaseballBat = {
			{
				Name = "Bat",
				Attach = "RightHand",
				Size = { X = 3.4, Y = 0.5, Z = 0.5 },
				Offset = { 0, -0.1, -1.5 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Material = "Wood",
				Color = "#C9A26B",
			},
		},
		Shovel = {
			{
				Name = "Handle",
				Attach = "RightHand",
				Size = { X = 3.6, Y = 0.3, Z = 0.3 },
				Offset = { 0, -0.1, -1.4 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Material = "WoodPlanks",
				Color = "#8A6A44",
			},
			{
				Name = "Blade",
				Attach = "RightHand",
				Size = { X = 1.3, Y = 0.15, Z = 1.2 },
				Offset = { 0, -0.1, -3.5 },
				Rotation = { 0, 0, 0 },
				Material = "Metal",
				Color = "#8F9399",
			},
		},
		WrenchAndHubcap = {
			{
				Name = "Wrench",
				Attach = "RightHand",
				Size = { X = 0.35, Y = 0.2, Z = 2.2 },
				Offset = { 0, -0.1, -1 },
				Rotation = { 0, 0, 0 },
				Material = "Metal",
				Color = "#B8BEC6",
			},
			{
				Name = "WrenchHead",
				Attach = "RightHand",
				Size = { X = 0.8, Y = 0.25, Z = 0.55 },
				Offset = { 0, -0.1, -2.2 },
				Rotation = { 0, 0, 0 },
				Material = "Metal",
				Color = "#B8BEC6",
			},
			{
				Name = "Hubcap",
				Attach = "LeftHand",
				Size = { X = 0.2, Y = 2.2, Z = 2.2 },
				Offset = { -0.4, 0.3, 0 },
				Rotation = { 0, 0, 0 },
				Shape = "Cylinder",
				Material = "DiamondPlate",
				Color = "#D8DCE0",
			},
		},
	},
}

return Styles
