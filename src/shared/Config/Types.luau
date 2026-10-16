--!strict
-- Shapes of the Config tables. Keeping them explicit lets other modules index config maps by id (string) safely.

export type Box = { X: number, Y: number, Z: number }
export type Reward = { Scrap: number, XP: number }

export type AttackConfig = {
	Damage: number, -- Classic: HP removed
	Percent: number, -- Casual: Percent added
	KnockbackScale: number, -- AttackKBScale in the knockback formula
	Cooldown: number, -- seconds before the next attack of this type
	Windup: number, -- seconds from input to the server hit check
	Hitbox: Box, -- studs (width, height, depth) in front of the attacker's root
}

export type PunchConfig = AttackConfig & {
	ChainLength: number,
	FinisherKnockbackMultiplier: number,
	FinisherCooldown: number,
	ChainResetTime: number,
}

export type ShoveConfig = AttackConfig & {
	MaxChargeTime: number,
	MaxChargeKnockbackMultiplier: number,
	ChargeSlow: number,
}

export type ParryConfig = {
	Window: number,
	ReflectMultiplier: number,
}

export type StyleAttack = {
	DamageMultiplier: number,
	KnockbackMultiplier: number,
	ReachBonus: number,
	Hitbox: Box?, -- replaces the base hitbox when set
	Parry: ParryConfig?, -- replaces the attack with a parry when set
}

export type StyleConfig = {
	Weapon: string,
	Price: number,
	UnlockLevel: number,
	AttackSpeed: number, -- 1 = normal; cooldowns and windups are divided by this
	Punch: StyleAttack,
	Shove: StyleAttack,
}

-- One block of a weapon's blockout model, welded to a hand (art pass replaces these with meshes).
export type WeaponPart = {
	Name: string,
	Hand: "Right" | "Left", -- welded to RightHand / LeftHand
	Size: Box,
	Offset: { number }, -- studs from the hand (x, y, z in the hand's space; -z is forward)
	Rotation: { number }, -- degrees (x, y, z)
	Shape: string?, -- Enum.PartType name (default Block)
	Material: string, -- Enum.Material name
	Color: string, -- hex
}

export type ModeConfig = {
	KnockbackMultiplier: number,
	Scoring: "LastStanding" | "KOsMinusFalls",
	JoinMidRound: boolean,
	-- Classic
	MaxHealth: number?,
	Lives: number?,
	HealthToPercent: number?,
	-- Casual
	PercentCap: number?,
	PassiveGainAmount: number?,
	PassiveGainInterval: number?,
}

export type PropClass = "Light" | "Medium" | "Heavy" | "Explosive"

export type PropClassConfig = {
	Damage: number,
	Percent: number,
	KnockbackScale: number,
	CarrySlow: number,
	Radius: number?, -- explosive only
	FuseTime: number?, -- explosive only
}

export type PropTypeConfig = {
	Class: PropClass,
	Size: Box,
	Material: string, -- Enum.Material name, used by blockout models
	Color: string, -- hex, used by blockout models
}

export type StructureConfig = {
	Health: number,
	MinDrops: number,
	MaxDrops: number,
	DropTable: { string },
	Size: Box, -- studs (width, height, length), used by blockout models
	Material: string, -- Enum.Material name, used by blockout models
	Color: string, -- hex, used by blockout models
}

export type RankConfig = { Level: number, Id: string }

export type MapConfig = {
	Enabled: boolean,
	Lighting: string,
}

export type QuestConfig = {
	Id: string,
	Stat: string,
	Goal: number,
	Scrap: number,
	Mode: string?, -- only counts in this mode when set
}

export type BadgeConfig = {
	BadgeId: number,
	Stat: string?,
	Goal: number?,
}

return {}
