--!strict
-- Combat tunables: knockback/Percent, hitstun, base attacks, dash, stamina and Perfect Dodge. Bible §2.1 and §3.3.
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
		CooldownTolerance: number,
	},
	Stamina: {
		Max: number,
		RunCostPerSecond: number,
		DashCost: number,
		RegenPerSecond: number,
		RegenDelay: number,
		RunResume: number,
		RunSpeedMultiplier: number,
		MovingSpeed: number,
	},
	Attacks: {
		Punch: Types.PunchConfig,
		Charged: Types.ChargedConfig,
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
		Distance = 12, -- owner playtest 2026-10-16: 18 crossed too much of the map (bible had 18)
		Duration = 0.25,
		InvulnerabilityTime = 0.25,
		Cooldown = 0.6, -- short since dashes cost stamina (owner, 2026-10-17); was 2.5 s
		AirDashesPerJump = 1, -- dashes allowed per stay in the air (jump, fall or launch); ground dashes are unlimited
		-- The client dashes at once and tells the server; the server accepts a dash this many seconds before the
		-- cooldown ends so network jitter never costs a legitimate dash its invulnerability.
		CooldownTolerance = 0.15,
	},

	-- Stamina (owner, 2026-10-17): running and dashing use it, for everyone, in every mode. It refills after a pause.
	Stamina = {
		Max = 100,
		RunCostPerSecond = 20, -- 5 s of running from full
		DashCost = 25, -- 4 dashes from full
		RegenPerSecond = 30,
		RegenDelay = 0.8, -- seconds after spending before it starts to refill
		RunResume = 20, -- running stops at 0 and starts again (Run still held) once stamina is back to this
		RunSpeedMultiplier = 1.5, -- 16 → 24 studs/s
		MovingSpeed = 2, -- studs/s: a running fighter moving faster than this pays for it
	},

	-- Base (Brawler) attacks. Fighting styles scale these in Config.Styles.
	Attacks = {
		Punch = {
			Damage = 8,
			Percent = 6,
			KnockbackScale = 1,
			Cooldown = 0.35, -- between chain hits
			Windup = 0.05, -- owner playtest: 0.1 felt delayed
			Hitbox = { X = 4, Y = 4, Z = 5 },
			ChainLength = 3,
			FinisherKnockbackMultiplier = 1.5, -- 3rd hit
			FinisherCooldown = 0.8, -- after the 3rd hit
			ChainResetTime = 1, -- seconds without punching before the chain restarts at hit 1
		},
		-- Charged punch (owner, 2026-10-17: replaces the right-click Shove). Tap the attack to punch; keep holding it
		-- HoldTime seconds after the punch and it starts charging; let go to throw the charged punch.
		Charged = {
			Damage = 14,
			Percent = 11,
			KnockbackScale = 1.6,
			Cooldown = 1.2,
			Windup = 0.05, -- after the charge is released (owner playtest: 0.15 felt delayed)
			Hitbox = { X = 5, Y = 5, Z = 6 },
			HoldTime = 0.25, -- seconds the attack is held before charging starts
			MaxChargeTime = 0.8,
			MaxChargeKnockbackMultiplier = 1.5,
			ChargeSlow = 0.4, -- 40% slower while charging
		},
	},

	-- A launched character cannot steer until its hitstun is over and it has landed, or after MaxTime seconds.
	Launch = { MaxTime = 3 },

	-- Camera shake intensity (0-1, scales Config.Controls.Camera.ShakeMagnitude) on heavy hits (charged, finisher).
	Feedback = { VictimShake = 1, AttackerShake = 0.6 },

	-- Practice dummy (developer panel): back this long after a KO or a fall of this many studs below its place.
	Dummy = { RespawnTime = 2, FallDistance = 4 },
}

return Combat
