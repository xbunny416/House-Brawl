--!strict
-- Combat tunables: knockback/Percent, hitstun, base attacks, dash and Perfect Dodge. Bible §2.1 and §3.3.
local Types = require(script.Parent.Types)

type CombatConfig = {
	Knockback: {
		Base: number,
		Growth: number,
		VelocityScale: number,
		LaunchAngleDegrees: number,
		TrailPercent: number,
	},
	Hitstun: { Base: number, PerPercent: number, Max: number },
	KOCreditWindow: number,
	HitboxPadding: number,
	PerfectDodge: {
		Window: number,
		Scrap: number,
		BonusWindow: number,
		BonusKnockbackMultiplier: number,
	},
	Dash: {
		Distance: number,
		Duration: number,
		InvulnerabilityTime: number,
		Cooldown: number,
		AirDashesPerJump: number,
	},
	Attacks: {
		Punch: Types.PunchConfig,
		Shove: Types.ShoveConfig,
	},
	Launch: { MaxTime: number },
	Feedback: { VictimShake: number, AttackerShake: number },
	Dummy: { RespawnTime: number, FallDistance: number },
}

local Combat: CombatConfig = {
	Knockback = {
		-- Knockback force = (Base + (Percent / 100) * Growth * AttackKnockbackScale) * ModeMultiplier
		Base = 30,
		Growth = 70,
		-- The force is applied as launch speed in studs/s: speed = force * VelocityScale.
		VelocityScale = 1,
		LaunchAngleDegrees = 30,
		-- Players launched above this Percent leave a smoke trail.
		TrailPercent = 100,
	},

	-- Hitstun = Base + Percent * PerPercent, capped at Max (seconds).
	Hitstun = { Base = 0.15, PerPercent = 0.002, Max = 0.8 },

	-- The last attacker who hit you within this many seconds gets the KO when you fall or reach 0 HP.
	KOCreditWindow = 6,

	-- Extra studs added around every server hitbox to absorb network latency.
	HitboxPadding = 0.5,

	PerfectDodge = {
		Window = 0.15, -- dash started within this many seconds before a hit lands
		Scrap = 5,
		BonusWindow = 2, -- your next hit within this many seconds...
		BonusKnockbackMultiplier = 1.25, -- ...deals +25% knockback
	},

	Dash = {
		Distance = 18,
		Duration = 0.25,
		InvulnerabilityTime = 0.25,
		Cooldown = 2.5,
		AirDashesPerJump = 1,
	},

	-- Base (Brawler) attacks. Fighting styles scale these in Config.Styles.
	Attacks = {
		Punch = {
			Damage = 8,
			Percent = 6,
			KnockbackScale = 1,
			Cooldown = 0.35, -- between chain hits
			Windup = 0.1,
			Hitbox = { X = 4, Y = 4, Z = 5 },
			ChainLength = 3,
			FinisherKnockbackMultiplier = 1.5, -- 3rd hit
			FinisherCooldown = 0.8, -- after the 3rd hit
			ChainResetTime = 1, -- seconds without punching before the chain restarts at hit 1
		},
		Shove = {
			Damage = 14,
			Percent = 11,
			KnockbackScale = 1.6,
			Cooldown = 1.2,
			Windup = 0.15, -- after the charge is released
			Hitbox = { X = 5, Y = 5, Z = 6 },
			MaxChargeTime = 0.8,
			MaxChargeKnockbackMultiplier = 1.5,
			ChargeSlow = 0.4, -- 40% slower while charging
		},
	},

	-- A launched character cannot steer until its hitstun is over and it has landed, or after MaxTime seconds.
	Launch = { MaxTime = 3 },

	-- Camera shake intensity (0-1, scales Config.Controls.Camera.ShakeMagnitude) on heavy hits (Shove, punch finisher).
	Feedback = { VictimShake = 1, AttackerShake = 0.4 },

	-- Training Yard dummy (lobby): respawns this long after it is knocked out or falls this many studs below its spot.
	Dummy = { RespawnTime = 2, FallDistance = 4 },
}

return Combat
