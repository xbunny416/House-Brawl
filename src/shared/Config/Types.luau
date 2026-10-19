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

export type ChargedConfig = AttackConfig & {
	HoldTime: number,
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
}

-- A style's move on the Ability key (Wrecker: the parry). Styles without one have no Ability button.
export type StyleAbility = {
	Parry: ParryConfig,
	Cooldown: number,
}

export type StyleConfig = {
	Weapon: string,
	Rarity: string, -- a key of Config.Styles.Roll.RarityColors; rolled with Roll.Odds[Rarity] (none: never rolled)
	AttackSpeed: number, -- 1 = normal; cooldowns and windups are divided by this
	-- Scripted animation clips (Shared/Animation/Clips): one per punch-chain hit, the charged punch, and the
	-- Ability move's clip (styles with an ability).
	Animations: { Punch: { string }, Charged: string, Ability: string? },
	Punch: StyleAttack,
	Charged: StyleAttack,
	Ability: StyleAbility?,
}

-- One block of a blockout model welded to a body part: weapons, hats, back items (art pass replaces with meshes).
export type AttachedPart = {
	Name: string,
	Attach: string, -- the R15 body part it is welded to, e.g. "RightHand", "Head", "UpperTorso"
	Size: Box,
	Offset: { number }, -- studs from that body part (x, y, z in its space; -z is forward)
	Rotation: { number }, -- degrees (x, y, z)
	Shape: string?, -- Enum.PartType name (default Block)
	Material: string, -- Enum.Material name
	Color: string, -- hex
}

export type CosmeticSlot = "Skin" | "Hat" | "BackItem" | "DashTrail" | "KOEffect" | "VictoryEmote" | "NameplateFrame"

export type CosmeticItem = {
	Slot: CosmeticSlot,
	Rarity: string, -- a key of Config.Cosmetics.Rarities
	Price: number, -- Scrap (0 for exclusive / Robux items)
	-- Never sold for Scrap. "VIP" / "EmotePack": comes with that game pass; "Premium": with Roblox Premium (while
	-- subscribed); "Robux": sold as the developer product whose Cosmetic is this item (Config.Monetization.Products).
	Exclusive: string?,
	Colors: { string }?, -- Skin: head, torso, arms, legs; DashTrail: start → end; KOEffect: particle colors
	Parts: { AttachedPart }?, -- Hat / BackItem
	Emote: string?, -- VictoryEmote: which emote animation plays (step 2.6)
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
