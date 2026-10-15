--!strict
--[[
	Formulas — pure gameplay math shared by server and client. No instances, no side effects:
	every function takes plain values and reads constants from Config, so it is unit-tested in tests/specs.
]]
local Config = require(script.Parent.Config)
local Types = require(script.Parent.Config.Types)

local Combat = Config.Combat
local Economy = Config.Economy
local Progression = Config.Progression

local Formulas = {}

export type AttackName = "Punch" | "Shove"

export type ResolvedAttack = {
	Damage: number,
	Percent: number,
	KnockbackScale: number,
	Cooldown: number,
	Windup: number,
	Hitbox: Types.Box,
	Parry: Types.ParryConfig?,
}

export type PayoutInput = {
	KOScrap: number, -- Scrap from KOs this round, already multiplied by the KO streak at the time of each KO
	KOs: number,
	PerfectDodges: number,
	Placement: number?, -- final rank (1 = winner); nil when unranked
	Completed: boolean, -- still in the round when it ended
	ActiveSeconds: number, -- seconds in the round while not AFK
	AFKAtEnd: boolean,
	IsVIP: boolean,
	IsPremium: boolean,
	FriendsInServer: number,
	IsPrivateServer: boolean,
}

export type Payout = { Scrap: number, XP: number }

local function round(value: number): number
	return math.floor(value + 0.5)
end

local function getMode(modeId: string): Types.ModeConfig
	local mode = Config.Modes.List[modeId]
	assert(mode, `Unknown mode "{modeId}"`)
	return mode
end

local function getStyle(styleId: string): Types.StyleConfig
	local style = Config.Styles.List[styleId]
	assert(style, `Unknown style "{styleId}"`)
	return style
end

---------------------------------------------------------------------------------------------------------------------
-- Knockback / Percent / Health
---------------------------------------------------------------------------------------------------------------------

-- Knockback force = (Base + (Percent / 100) * Growth * attackScale) * ModeMultiplier * extraMultiplier.
-- extraMultiplier covers per-hit bonuses (punch finisher, shove charge, Perfect Dodge bonus).
function Formulas.knockbackForce(percent: number, attackScale: number, modeId: string, extraMultiplier: number?): number
	local kb = Combat.Knockback
	local force = (kb.Base + (percent / 100) * kb.Growth * attackScale) * getMode(modeId).KnockbackMultiplier
	return force * (extraMultiplier or 1)
end

-- Launch speed in studs/s for a knockback force.
function Formulas.launchSpeed(force: number): number
	return force * Combat.Knockback.VelocityScale
end

-- Seconds of hitstun after being hit at `percent`.
function Formulas.hitstun(percent: number): number
	local h = Combat.Hitstun
	return math.min(h.Base + math.max(percent, 0) * h.PerPercent, h.Max)
end

-- True when a launch at this Percent should leave a trail.
function Formulas.leavesTrail(percent: number): boolean
	return percent > Combat.Knockback.TrailPercent
end

-- Classic: Percent = damage taken this life * HealthToPercent.
function Formulas.classicPercent(health: number): number
	local classic = getMode("Classic")
	local maxHealth = classic.MaxHealth :: number
	return math.clamp(maxHealth - health, 0, maxHealth) * (classic.HealthToPercent :: number)
end

-- Casual: adds Percent and applies the cap.
function Formulas.addCasualPercent(current: number, gain: number): number
	return math.clamp(current + gain, 0, getMode("Casual").PercentCap :: number)
end

---------------------------------------------------------------------------------------------------------------------
-- Attacks and styles
---------------------------------------------------------------------------------------------------------------------

-- Combines a base attack with a fighting style's modifiers.
function Formulas.resolveAttack(styleId: string, attackName: AttackName): ResolvedAttack
	local style = getStyle(styleId)
	local base: Types.AttackConfig = if attackName == "Punch" then Combat.Attacks.Punch else Combat.Attacks.Shove
	local modifier = if attackName == "Punch" then style.Punch else style.Shove
	local hitbox = modifier.Hitbox or base.Hitbox
	return {
		Damage = base.Damage * modifier.DamageMultiplier,
		Percent = base.Percent * modifier.DamageMultiplier,
		KnockbackScale = base.KnockbackScale * modifier.KnockbackMultiplier,
		Cooldown = base.Cooldown / style.AttackSpeed,
		Windup = base.Windup / style.AttackSpeed,
		Hitbox = { X = hitbox.X, Y = hitbox.Y, Z = hitbox.Z + modifier.ReachBonus },
		Parry = modifier.Parry,
	}
end

-- Knockback multiplier for the n-th punch of a chain (the finisher hits harder).
function Formulas.punchChainMultiplier(hitIndex: number): number
	local punch = Combat.Attacks.Punch
	return if hitIndex >= punch.ChainLength then punch.FinisherKnockbackMultiplier else 1
end

-- Cooldown after the n-th punch of a chain, scaled by the style's attack speed.
function Formulas.punchCooldown(hitIndex: number, attackSpeed: number): number
	local punch = Combat.Attacks.Punch
	local cooldown = if hitIndex >= punch.ChainLength then punch.FinisherCooldown else punch.Cooldown
	return cooldown / attackSpeed
end

-- Knockback multiplier for a Shove charged for `chargeTime` seconds (linear up to the max charge).
function Formulas.shoveChargeMultiplier(chargeTime: number): number
	local shove = Combat.Attacks.Shove
	local t = math.clamp(chargeTime, 0, shove.MaxChargeTime) / shove.MaxChargeTime
	return 1 + t * (shove.MaxChargeKnockbackMultiplier - 1)
end

-- True if a dash that started at `dashStart` turns a hit landing at `hitTime` into a Perfect Dodge.
function Formulas.isPerfectDodge(dashStart: number, hitTime: number): boolean
	local before = hitTime - dashStart
	return before >= 0 and before <= Combat.PerfectDodge.Window
end

-- True if a hit landing at `hitTime` is inside the dash's invulnerability.
function Formulas.isDashInvulnerable(dashStart: number, hitTime: number): boolean
	local elapsed = hitTime - dashStart
	return elapsed >= 0 and elapsed <= Combat.Dash.InvulnerabilityTime
end

---------------------------------------------------------------------------------------------------------------------
-- Progression
---------------------------------------------------------------------------------------------------------------------

-- XP needed to go from `level` to `level + 1` (0 at the level cap).
function Formulas.xpToNextLevel(level: number): number
	if level >= Progression.LevelCap then
		return 0
	end
	return math.floor(Progression.XPCurve.Base * level ^ Progression.XPCurve.Exponent)
end

-- Adds XP and levels up as needed. Returns the new level, the XP into that level and how many levels were gained.
function Formulas.addXP(level: number, xp: number, gained: number): (number, number, number)
	local newLevel = level
	local newXP = xp + math.max(gained, 0)
	while newLevel < Progression.LevelCap do
		local needed = Formulas.xpToNextLevel(newLevel)
		if newXP < needed then
			break
		end
		newXP -= needed
		newLevel += 1
	end
	if newLevel >= Progression.LevelCap then
		newXP = 0
	end
	return newLevel, newXP, newLevel - level
end

-- Rank id for a level (the highest rank whose Level is <= level).
function Formulas.rankForLevel(level: number): string
	local ranks = Progression.Ranks
	local rank = ranks[1].Id
	for _, entry in ranks do
		if level >= entry.Level then
			rank = entry.Id
		end
	end
	return rank
end

---------------------------------------------------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------------------------------------------------

-- KO streak multiplier for a KO made after `previousKOs` consecutive KOs without being KO'd.
function Formulas.koStreakMultiplier(previousKOs: number): number
	local streak = Economy.KOStreak
	return math.min(streak.Start + streak.Step * math.max(previousKOs, 0), streak.Max)
end

-- Scrap for one KO, including the streak multiplier.
function Formulas.koScrap(previousKOs: number): number
	return round(Economy.Rewards.KO.Scrap * Formulas.koStreakMultiplier(previousKOs))
end

-- Summed Scrap bonus fraction from VIP and Premium (before the cap).
function Formulas.scrapBonus(isVIP: boolean, isPremium: boolean): number
	local bonuses = Economy.Bonuses
	return (if isVIP then bonuses.VIPScrap else 0) + (if isPremium then bonuses.PremiumScrap else 0)
end

-- XP bonus fraction from friends in the server.
function Formulas.friendXPBonus(friends: number): number
	local bonuses = Economy.Bonuses
	return math.min(math.max(friends, 0) * bonuses.FriendXPPerFriend, bonuses.FriendXPMax)
end

-- 1 + summed bonus fraction, capped at +MaxTotal.
function Formulas.bonusMultiplier(bonus: number): number
	return 1 + math.clamp(bonus, 0, Economy.Bonuses.MaxTotal)
end

-- Round-end payout. Placement and completion rewards need MinSeconds of active play; AFK at the end pays nothing.
function Formulas.roundPayout(input: PayoutInput): Payout
	if input.AFKAtEnd then
		return { Scrap = 0, XP = 0 }
	end

	local rewards = Economy.Rewards
	local scrap = input.KOScrap + input.PerfectDodges * Combat.PerfectDodge.Scrap
	local xp = input.KOs * rewards.KO.XP

	if input.ActiveSeconds >= Config.Round.Participation.MinSeconds then
		local placement = input.Placement
		if placement == 1 then
			scrap += rewards.Win.Scrap
			xp += rewards.Win.XP
		end
		local inTop = placement ~= nil and placement <= Config.Round.PlacementsRewarded
		if inTop and (placement ~= 1 or Economy.WinnerAlsoGetsTop3) then
			scrap += rewards.Top3.Scrap
			xp += rewards.Top3.XP
		end
		if input.Completed then
			scrap += rewards.Completed.Scrap
			xp += rewards.Completed.XP
		end
	end

	scrap *= Formulas.bonusMultiplier(Formulas.scrapBonus(input.IsVIP, input.IsPremium))
	scrap *= Economy.EventScrapMultiplier
	xp *= Formulas.bonusMultiplier(Formulas.friendXPBonus(input.FriendsInServer))

	if input.IsPrivateServer then
		scrap *= Economy.PrivateServerRewardScale
		xp *= Economy.PrivateServerRewardScale
	end

	return { Scrap = round(scrap), XP = round(xp) }
end

---------------------------------------------------------------------------------------------------------------------
-- Time
---------------------------------------------------------------------------------------------------------------------

-- Day number for daily resets: increments at `resetHourUTC` every day. `unixTime` is os.time().
function Formulas.dayNumber(unixTime: number, resetHourUTC: number?): number
	return math.floor((unixTime - (resetHourUTC or 0) * 3600) / 86400)
end

return Formulas
