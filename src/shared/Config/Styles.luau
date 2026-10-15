--!strict
-- Fighting styles: side-grades only (different feel, similar strength). Bible §2.3.
local Types = require(script.Parent.Types)

type StylesConfig = {
	Default: string,
	Order: { string },
	List: { [string]: Types.StyleConfig },
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
			Punch = NO_CHANGE,
			Shove = NO_CHANGE,
		},
		-- Baseball bat: harder hits, longer reach, slower swings.
		Slugger = {
			Weapon = "BaseballBat",
			Price = 1500,
			UnlockLevel = 5,
			AttackSpeed = 0.8,
			Punch = { DamageMultiplier = 1.15, KnockbackMultiplier = 1, ReachBonus = 2 },
			Shove = { DamageMultiplier = 1.15, KnockbackMultiplier = 1, ReachBonus = 2 },
		},
		-- Shovel: wide sweeps, a bit less damage, stronger shove.
		Scrapper = {
			Weapon = "Shovel",
			Price = 3000,
			UnlockLevel = 12,
			AttackSpeed = 1,
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
			Punch = { DamageMultiplier = 0.95, KnockbackMultiplier = 1, ReachBonus = 0 },
			Shove = {
				DamageMultiplier = 1,
				KnockbackMultiplier = 1,
				ReachBonus = 0,
				Parry = { Window = 0.2, ReflectMultiplier = 1 },
			},
		},
	},
}

return Styles
