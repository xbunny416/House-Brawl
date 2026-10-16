--!strict
--[[
	Fighter — one combatant's combat state and rules: punch chain, Shove charge, cooldowns, hitstun, HP / Percent and
	KO credit. Pure logic (no instances; the current time is passed in), so Lune specs test every rule.
	CombatService keeps one Fighter per character and turns the results into hit checks, launches and KOs.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))

local Punch = Config.Combat.Attacks.Punch
local Shove = Config.Combat.Attacks.Shove

export type Fighter = {
	ModeId: string,
	Health: number, -- Classic HP (0 and unused in modes without HP)
	Percent: number,
	PunchChain: number, -- punches thrown in the current chain
	LastPunchAt: number,
	NextPunchAt: number,
	NextShoveAt: number,
	ChargeStartedAt: number?, -- set while a Shove is charging
	StunnedUntil: number,
	LastHitAt: number,
	LastAttacker: any?, -- whoever hit last (a Player on the server)
	Defeated: boolean,
}

-- One hit as it lands: the attack's values plus every extra knockback multiplier (finisher, charge, ...).
export type Hit = {
	Damage: number,
	Percent: number,
	KnockbackScale: number,
	Multiplier: number,
}

export type HitResult = {
	Force: number, -- knockback force (Formulas.launchSpeed turns it into studs/s)
	Hitstun: number,
	Trail: boolean, -- launched above TrailPercent: leaves a smoke trail
	Defeated: boolean, -- Classic: HP reached 0
	InterruptedCharge: boolean, -- the hit cancelled the victim's Shove charge
}

local Fighter = {}

local function getMode(modeId: string)
	local mode = Config.Modes.List[modeId]
	assert(mode, `Unknown mode "{modeId}"`)
	return mode
end

-- A fresh fighter (full HP, 0%) for a mode.
function Fighter.new(modeId: string): Fighter
	return {
		ModeId = modeId,
		Health = getMode(modeId).MaxHealth or 0,
		Percent = 0,
		PunchChain = 0,
		LastPunchAt = -math.huge,
		NextPunchAt = 0,
		NextShoveAt = 0,
		ChargeStartedAt = nil,
		StunnedUntil = 0,
		LastHitAt = -math.huge,
		LastAttacker = nil,
		Defeated = false,
	}
end

-- True while the fighter can attack (not knocked out, not in hitstun).
function Fighter.canAct(fighter: Fighter, now: number): boolean
	return not fighter.Defeated and now >= fighter.StunnedUntil
end

-- True if the fighter was hit after `time` (an attack started at `time` is interrupted).
function Fighter.wasHitSince(fighter: Fighter, time: number): boolean
	return fighter.LastHitAt > time
end

-- Throws a punch if allowed. Returns its place in the chain (1 to ChainLength), or nil if not allowed now
-- (cooldown, hitstun, charging a Shove).
function Fighter.punch(fighter: Fighter, attackSpeed: number, now: number): number?
	if not Fighter.canAct(fighter, now) or now < fighter.NextPunchAt or fighter.ChargeStartedAt ~= nil then
		return nil
	end
	if now - fighter.LastPunchAt > Punch.ChainResetTime or fighter.PunchChain >= Punch.ChainLength then
		fighter.PunchChain = 0
	end
	fighter.PunchChain += 1
	fighter.LastPunchAt = now
	fighter.NextPunchAt = now + Formulas.punchCooldown(fighter.PunchChain, attackSpeed)
	return fighter.PunchChain
end

-- Starts charging a Shove. False if not allowed now (cooldown, hitstun, already charging).
function Fighter.startShove(fighter: Fighter, now: number): boolean
	if not Fighter.canAct(fighter, now) or now < fighter.NextShoveAt or fighter.ChargeStartedAt ~= nil then
		return false
	end
	fighter.ChargeStartedAt = now
	return true
end

-- Releases the charge and starts the Shove cooldown. Returns the charge time (capped at MaxChargeTime), or nil when
-- the fighter was not charging.
function Fighter.releaseShove(fighter: Fighter, cooldown: number, now: number): number?
	local started = fighter.ChargeStartedAt
	if started == nil then
		return nil
	end
	fighter.ChargeStartedAt = nil
	fighter.NextShoveAt = now + cooldown
	return math.min(now - started, Shove.MaxChargeTime)
end

-- Stops charging without shoving (no cooldown). True if a charge was cancelled.
function Fighter.cancelShove(fighter: Fighter): boolean
	if fighter.ChargeStartedAt == nil then
		return false
	end
	fighter.ChargeStartedAt = nil
	return true
end

-- Applies a hit: HP and Percent (Classic) or Percent (Casual), then knockback from the new Percent, hitstun and KO
-- credit for `attacker`.
function Fighter.takeHit(fighter: Fighter, hit: Hit, attacker: any, now: number): HitResult
	if getMode(fighter.ModeId).MaxHealth ~= nil then
		fighter.Health = math.max(fighter.Health - hit.Damage, 0)
		fighter.Percent = Formulas.classicPercent(fighter.Health)
		fighter.Defeated = fighter.Health <= 0
	else
		fighter.Percent = Formulas.addCasualPercent(fighter.Percent, hit.Percent)
	end
	local hitstun = Formulas.hitstun(fighter.Percent)
	local interrupted = Fighter.cancelShove(fighter)
	fighter.StunnedUntil = math.max(fighter.StunnedUntil, now + hitstun)
	fighter.LastHitAt = now
	fighter.LastAttacker = attacker
	return {
		Force = Formulas.knockbackForce(fighter.Percent, hit.KnockbackScale, fighter.ModeId, hit.Multiplier),
		Hitstun = hitstun,
		Trail = Formulas.leavesTrail(fighter.Percent),
		Defeated = fighter.Defeated,
		InterruptedCharge = interrupted,
	}
end

-- Who gets the KO if this fighter is knocked out now: the last attacker within KOCreditWindow seconds, else nil.
function Fighter.koCredit(fighter: Fighter, now: number): any?
	if fighter.LastAttacker ~= nil and now - fighter.LastHitAt <= Config.Combat.KOCreditWindow then
		return fighter.LastAttacker
	end
	return nil
end

return Fighter
