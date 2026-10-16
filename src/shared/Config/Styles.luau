--!strict
-- Fighting styles: side-grades only (different feel, similar strength). Bible §2.3.
local Types = require(script.Parent.Types)

type StylesConfig = {
	Default: string,
	Order: { string },
	List: { [string]: Types.StyleConfig },
	Weapons: { [string]: { Types.AttachedPart } },
}

local NO_CHANGE: Types.StyleAttack = { DamageMultiplier = 1, KnockbackMultiplier = 1, ReachBonus = 0 }

local Styles: StylesConfig = {
	Default = "Brawler",
	Order = { "Brawler", "Slugger", "Scrapper", "Wrecker" },
	List = {
		Brawler = {
			Weapon = "Fists",
			Price = 0,
			UnlockLevel = 1,
			AttackSpeed = 1,
			Animations = { Punch = { "Jab", "Cross", "Uppercut" }, Shove = "Shove" },
			Punch = NO_CHANGE,
			Shove = NO_CHANGE,
		},
		-- Baseball bat: harder hits, longer reach, slower swings.
		Slugger = {
			Weapon = "BaseballBat",
			Price = 1500,
			UnlockLevel = 5,
			AttackSpeed = 0.8,
			Animations = { Punch = { "SwingRight", "SwingLeft", "Smash" }, Shove = "Shove" },
			Punch = { DamageMultiplier = 1.15, KnockbackMultiplier = 1, ReachBonus = 2 },
			Shove = { DamageMultiplier = 1.15, KnockbackMultiplier = 1, ReachBonus = 2 },
		},
		-- Shovel: wide sweeps, a bit less damage, stronger shove.
		Scrapper = {
			Weapon = "Shovel",
			Price = 3000,
			UnlockLevel = 12,
			AttackSpeed = 1,
			Animations = { Punch = { "SweepRight", "SweepLeft", "Smash" }, Shove = "Shove" },
			Punch = {
				DamageMultiplier = 0.9,
				KnockbackMultiplier = 1,
				ReachBonus = 0,
				Hitbox = { X = 7, Y = 4, Z = 5 },
			},
			Shove = { DamageMultiplier = 0.9, KnockbackMultiplier = 1.1, ReachBonus = 0 },
		},
		-- Wrench + hubcap shield: Shove becomes a short parry that reflects knockback.
		Wrecker = {
			Weapon = "WrenchAndHubcap",
			Price = 6000,
			UnlockLevel = 25,
			AttackSpeed = 1,
			Animations = { Punch = { "SwingRight", "SwingLeft", "Smash" }, Shove = "Parry" },
			Punch = { DamageMultiplier = 0.95, KnockbackMultiplier = 1, ReachBonus = 0 },
			Shove = {
				DamageMultiplier = 1,
				KnockbackMultiplier = 1,
				ReachBonus = 0,
				Parry = { Window = 0.2, ReflectMultiplier = 1 },
			},
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
