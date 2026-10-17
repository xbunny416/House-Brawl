--!strict
-- Combat rules for one fighter (step 1.6): punch chain, charged punch, cooldowns, hitstun, HP / Percent, KO credit.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local Formulas = Roblox.require(Shared.Formulas)
local Fighter = Roblox.require(Roblox.game.ServerScriptService.Server.Combat.Fighter)

local Punch = Config.Combat.Attacks.Punch
local Charged = Config.Combat.Attacks.Charged

local function punchHit(multiplier: number?): any
	return {
		Damage = Punch.Damage,
		Percent = Punch.Percent,
		KnockbackScale = Punch.KnockbackScale,
		Multiplier = multiplier or 1,
	}
end

return {
	["a new fighter has full HP and 0% (Classic), no HP (Casual)"] = function()
		local classic = Fighter.new("Classic")
		expect.equal(classic.Health, 100)
		expect.equal(classic.Percent, 0)
		local casual = Fighter.new("Casual")
		expect.equal(casual.Percent, 0)
		expect.equal(Fighter.canAct(casual, 0), true)
	end,

	-- Punch chain -----------------------------------------------------------------------------------------------------
	["punch chain: 1, 2, 3 with 0.35 s between hits and 0.8 s after the finisher"] = function()
		local f = Fighter.new("Classic")
		expect.equal(Fighter.punch(f, 1, 0), 1)
		expect.equal(Fighter.punch(f, 1, 0.2), nil, "on cooldown")
		expect.equal(Fighter.punch(f, 1, 0.35), 2)
		expect.equal(Fighter.punch(f, 1, 0.7), 3)
		expect.equal(Fighter.punch(f, 1, 0.7 + 0.79), nil, "finisher cooldown")
		expect.equal(Fighter.punch(f, 1, 0.7 + 0.8), 1, "chain restarts after the finisher")
	end,
	["punch chain resets after ChainResetTime without punching"] = function()
		local f = Fighter.new("Classic")
		Fighter.punch(f, 1, 0)
		expect.equal(Fighter.punch(f, 1, Punch.ChainResetTime + 0.01), 1)
	end,
	["slower styles have longer punch cooldowns"] = function()
		local f = Fighter.new("Classic")
		Fighter.punch(f, 0.8, 0)
		expect.equal(Fighter.punch(f, 0.8, 0.35), nil)
		expect.equal(Fighter.punch(f, 0.8, 0.35 / 0.8), 2)
	end,

	-- Charged punch ---------------------------------------------------------------------------------------------------
	["holding the attack after a punch can charge at once (the charge has its own cooldown)"] = function()
		local f = Fighter.new("Classic")
		expect.equal(Fighter.punch(f, 1, 0), 1)
		expect.equal(Fighter.startCharge(f, Charged.HoldTime), true, "a punch's cooldown does not block the charge")
	end,
	["a charge caps at MaxChargeTime and starts its cooldown on release"] = function()
		local f = Fighter.new("Classic")
		expect.equal(Fighter.startCharge(f, 0), true)
		expect.equal(Fighter.startCharge(f, 0.1), false, "already charging")
		expect.equal(Fighter.punch(f, 1, 0.1), nil, "no punching while charging")
		expect.equal(Fighter.releaseCharge(f, Charged.Cooldown, 2), Charged.MaxChargeTime)
		expect.equal(Fighter.releaseCharge(f, Charged.Cooldown, 2.1), nil, "not charging")
		expect.equal(Fighter.startCharge(f, 2 + Charged.Cooldown - 0.01), false, "cooldown")
		expect.equal(Fighter.startCharge(f, 2 + Charged.Cooldown), true)
		expect.near(Fighter.releaseCharge(f, Charged.Cooldown, 2 + Charged.Cooldown + 0.4) :: number, 0.4)
	end,
	["a cancelled charge has no cooldown"] = function()
		local f = Fighter.new("Classic")
		Fighter.startCharge(f, 0)
		expect.equal(Fighter.cancelCharge(f), true)
		expect.equal(Fighter.cancelCharge(f), false)
		expect.equal(Fighter.startCharge(f, 0.1), true)
	end,

	-- Hits ------------------------------------------------------------------------------------------------------------
	["classic hit: HP down, Percent = damage taken x 1.5, knockback from the new Percent"] = function()
		local f = Fighter.new("Classic")
		local result = Fighter.takeHit(f, punchHit(), "attacker", 10)
		expect.equal(f.Health, 92)
		expect.equal(f.Percent, 12)
		expect.near(result.Force, Formulas.knockbackForce(12, 1, "Classic"))
		expect.near(result.Hitstun, Formulas.hitstun(12))
		expect.equal(result.Trail, false)
		expect.equal(result.Defeated, false)
	end,
	["casual hit: Percent rises, capped at 300%, never defeated"] = function()
		local f = Fighter.new("Casual")
		Fighter.takeHit(f, punchHit(), "a", 0)
		expect.equal(f.Percent, 6)
		f.Percent = 298
		local result = Fighter.takeHit(f, punchHit(), "a", 1)
		expect.equal(f.Percent, 300)
		expect.equal(result.Trail, true)
		expect.equal(result.Defeated, false)
		expect.near(result.Force, Formulas.knockbackForce(300, 1, "Casual"))
	end,
	["finisher and charge multipliers scale knockback"] = function()
		local plain = Fighter.takeHit(Fighter.new("Classic"), punchHit(), "a", 0)
		local finisher = Fighter.takeHit(Fighter.new("Classic"), punchHit(1.5), "a", 0)
		expect.near(finisher.Force, plain.Force * 1.5)
	end,
	["hitstun blocks attacks and interrupts a charge"] = function()
		local f = Fighter.new("Classic")
		Fighter.startCharge(f, 0)
		local result = Fighter.takeHit(f, punchHit(), "a", 1)
		expect.equal(result.InterruptedCharge, true)
		expect.equal(f.ChargeStartedAt, nil)
		expect.equal(Fighter.canAct(f, 1 + result.Hitstun / 2), false)
		expect.equal(Fighter.punch(f, 1, 1 + result.Hitstun / 2), nil)
		expect.equal(Fighter.startCharge(f, 1 + result.Hitstun / 2), false)
		expect.equal(Fighter.punch(f, 1, 1 + result.Hitstun), 1)
	end,
	["an attack is interrupted if its attacker is hit during the windup"] = function()
		local f = Fighter.new("Classic")
		Fighter.punch(f, 1, 5)
		expect.equal(Fighter.wasHitSince(f, 5), false)
		Fighter.takeHit(f, punchHit(), "a", 5.05)
		expect.equal(Fighter.wasHitSince(f, 5), true)
	end,
	["classic: defeated at 0 HP"] = function()
		local f = Fighter.new("Classic")
		f.Health = 5
		local result = Fighter.takeHit(f, punchHit(), "a", 0)
		expect.equal(f.Health, 0)
		expect.equal(f.Percent, 150)
		expect.equal(result.Defeated, true)
		expect.equal(Fighter.canAct(f, 100), false)
	end,

	-- Dash and Perfect Dodge -----------------------------------------------------------------------------------------
	["server dash: cooldown with network tolerance, none during hitstun"] = function()
		local Dash = Config.Combat.Dash
		local f = Fighter.new("Classic")
		expect.equal(Fighter.dash(f, 0), true)
		expect.equal(Fighter.dash(f, Dash.Cooldown - Dash.CooldownTolerance - 0.01), false)
		expect.equal(Fighter.dash(f, Dash.Cooldown - Dash.CooldownTolerance), true, "jitter-early dash accepted")
		local stunned = Fighter.new("Classic")
		local result = Fighter.takeHit(stunned, punchHit(), "a", 0)
		expect.equal(Fighter.dash(stunned, result.Hitstun / 2), false, "hitstun")
	end,
	["a dash cancels a charge"] = function()
		local f = Fighter.new("Classic")
		Fighter.startCharge(f, 0)
		Fighter.dash(f, 0.1)
		expect.equal(f.ChargeStartedAt, nil)
	end,
	["hits inside the dash's invulnerability miss; the first 0.15 s is a Perfect Dodge (once per dash)"] = function()
		local Dash = Config.Combat.Dash
		local window = Config.Combat.PerfectDodge.Window
		local f = Fighter.new("Classic")
		expect.equal(Fighter.evade(f, 0), "None", "not dashing")
		Fighter.dash(f, 10)
		expect.equal(Fighter.evade(f, 10 + window * 0.9), "Perfect")
		expect.equal(Fighter.evade(f, 10 + window * 0.95), "Dodged", "one Perfect Dodge per dash")
		expect.equal(Fighter.evade(f, 10 + Dash.InvulnerabilityTime * 0.99), "Dodged")
		expect.equal(Fighter.evade(f, 10 + Dash.InvulnerabilityTime + 0.01), "None")
		local late = Fighter.new("Classic")
		Fighter.dash(late, 0)
		expect.equal(Fighter.evade(late, window + 0.01), "Dodged", "dodged, but too early for a Perfect Dodge")
	end,
	["Perfect Dodge bonus: x1.25 knockback on the next hit within 2 s"] = function()
		local PerfectDodge = Config.Combat.PerfectDodge
		local f = Fighter.new("Classic")
		expect.equal(Fighter.dodgeBonus(f, 0), 1)
		Fighter.dash(f, 0)
		Fighter.evade(f, 0.1)
		expect.equal(Fighter.dodgeBonus(f, 0.1 + PerfectDodge.BonusWindow), PerfectDodge.BonusKnockbackMultiplier)
		expect.equal(Fighter.dodgeBonus(f, 0.1 + PerfectDodge.BonusWindow + 0.01), 1, "expired")
		Fighter.clearDodgeBonus(f)
		expect.equal(Fighter.dodgeBonus(f, 0.2), 1, "used up")
	end,

	-- Spawn shield and passive gain -----------------------------------------------------------------------------------
	["spawn shield blocks hits until it runs out or the fighter attacks"] = function()
		local f = Fighter.new("Classic")
		Fighter.shield(f, 0, Config.Round.SpawnShieldTime)
		expect.equal(Fighter.evade(f, 1), "Shielded")
		expect.equal(Fighter.evade(f, Config.Round.SpawnShieldTime), "None", "expired")
		Fighter.shield(f, 10, Config.Round.SpawnShieldTime)
		Fighter.punch(f, 1, 10.5)
		expect.equal(Fighter.isShielded(f, 10.6), false, "a punch ends it")
		local g = Fighter.new("Classic")
		Fighter.shield(g, 0, 2)
		Fighter.startCharge(g, 0.5)
		expect.equal(Fighter.isShielded(g, 0.6), false, "a charge ends it")
	end,
	["passive gain adds Percent in Casual only"] = function()
		local casual = Fighter.new("Casual")
		Fighter.addPercent(casual, 1)
		expect.equal(casual.Percent, 1)
		casual.Percent = 300
		Fighter.addPercent(casual, 1)
		expect.equal(casual.Percent, 300, "cap")
		local classic = Fighter.new("Classic")
		Fighter.addPercent(classic, 1)
		expect.equal(classic.Percent, 0)
	end,

	-- KO credit -------------------------------------------------------------------------------------------------------
	["KO credit goes to the last attacker within 6 s"] = function()
		local f = Fighter.new("Casual")
		expect.equal(Fighter.koCredit(f, 0), nil, "never hit")
		Fighter.takeHit(f, punchHit(), "first", 0)
		Fighter.takeHit(f, punchHit(), "second", 1)
		expect.equal(Fighter.koCredit(f, 1 + Config.Combat.KOCreditWindow), "second")
		expect.equal(Fighter.koCredit(f, 1 + Config.Combat.KOCreditWindow + 0.01), nil)
	end,
	["KO credit names what the last hit was (chair KOs)"] = function()
		local f = Fighter.new("Casual")
		local chair = punchHit()
		chair.Source = "Chair"
		Fighter.takeHit(f, chair, "thrower", 0)
		local killer, weapon = Fighter.koCredit(f, 1)
		expect.equal(killer, "thrower")
		expect.equal(weapon, "Chair")
		local _, expired = Fighter.koCredit(f, 100)
		expect.equal(expired, nil)
	end,
	["breaking the shield ends it at once"] = function()
		local f = Fighter.new("Classic")
		Fighter.shield(f, 0, 2)
		Fighter.breakShield(f)
		expect.equal(Fighter.isShielded(f, 0.1), false)
	end,
}
