--!strict
-- Game modes. Bible §2.1 "Modes and round rules".
local Types = require(script.Parent.Types)

type ModesConfig = {
	Default: string,
	Order: { string },
	List: { [string]: Types.ModeConfig },
}

local Modes: ModesConfig = {
	Default = "Classic",
	-- Modes in the vote. Classic only (owner, 2026-10-19: "Classic mode only, no mode vote"); Casual stays defined
	-- below and can come back by adding it here.
	Order = { "Classic" },
	List = {
		-- 100 HP, 3 lives. Percent = (MaxHealth - HP) * HealthToPercent. Last fighter standing wins;
		-- at time-out most KOs wins (tiebreak: fewest falls).
		Classic = {
			KnockbackMultiplier = 1,
			Scoring = "LastStanding",
			JoinMidRound = false,
			MaxHealth = 100,
			Lives = 3,
			HealthToPercent = 1.5,
		},
		-- No HP, unlimited respawns, Percent is its own meter. Score = KOs - falls.
		Casual = {
			KnockbackMultiplier = 1.15,
			Scoring = "KOsMinusFalls",
			JoinMidRound = true,
			PercentCap = 300,
			PassiveGainAmount = 1, -- +1% ...
			PassiveGainInterval = 5, -- ...every 5 s while alive
		},
	},
}

return Modes
