--!strict
-- Combat rules for one fighter (step 1.6): punch chain, Shove charge, cooldowns, hitstun, HP / Percent, KO credit.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local Formulas = Roblox.require(Shared.Formulas)
local Fighter = Roblox.require(Roblox.game.ServerScriptService.Server.Combat.Fighter)

local Punch = Config.Combat.Attacks.Punch
local Shove = Config.Combat.Attacks.Shove

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

	-- Shove -----------------------------------------------------------------------------------------------------------
	["shove charges, caps at MaxChargeTime and starts its cooldown on release"] = function()
		local f = Fighter.new("Classic")
		expect.equal(Fighter.startShove(f, 0), true)
		expect.equal(Fighter.startShove(f, 0.1), false, "already charging")
		expect.equal(Fighter.punch(f, 1, 0.1), nil, "no punching while charging")
		expect.equal(Fighter.releaseShove(f, Shove.Cooldown, 2), Shove.MaxChargeTime)
		expect.equal(Fighter.releaseShove(f, Shove.Cooldown, 2.1), nil, "not charging")
		expect.equal(Fighter.startShove(f, 2 + Shove.Cooldown - 0.01), false, "cooldown")
		expect.equal(Fighter.startShove(f, 2 + Shove.Cooldown), true)
		expect.near(Fighter.releaseShove(f, Shove.Cooldown, 2 + Shove.Cooldown + 0.4) :: number, 0.4)
	end,
	["a cancelled shove has no cooldown"] = function()
		local f = Fighter.new("Classic")
		Fighter.startShove(f, 0)
		expect.equal(Fighter.cancelShove(f), true)
		expect.equal(Fighter.cancelShove(f), false)
		expect.equal(Fighter.startShove(f, 0.1), true)
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
	["hitstun blocks attacks and interrupts a shove charge"] = function()
		local f = Fighter.new("Classic")
		Fighter.startShove(f, 0)
		local result = Fighter.takeHit(f, punchHit(), "a", 1)
		expect.equal(result.InterruptedCharge, true)
		expect.equal(f.ChargeStartedAt, nil)
		expect.equal(Fighter.canAct(f, 1 + result.Hitstun / 2), false)
		expect.equal(Fighter.punch(f, 1, 1 + result.Hitstun / 2), nil)
		expect.equal(Fighter.startShove(f, 1 + result.Hitstun / 2), false)
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

	-- KO credit -------------------------------------------------------------------------------------------------------
	["KO credit goes to the last attacker within 6 s"] = function()
		local f = Fighter.new("Casual")
		expect.equal(Fighter.koCredit(f, 0), nil, "never hit")
		Fighter.takeHit(f, punchHit(), "first", 0)
		Fighter.takeHit(f, punchHit(), "second", 1)
		expect.equal(Fighter.koCredit(f, 1 + Config.Combat.KOCreditWindow), "second")
		expect.equal(Fighter.koCredit(f, 1 + Config.Combat.KOCreditWindow + 0.01), nil)
	end,
}
