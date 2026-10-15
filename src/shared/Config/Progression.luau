--!strict
-- Levels and rank titles. Bible §2.1.
local Types = require(script.Parent.Types)

type ProgressionConfig = {
	LevelCap: number,
	XPCurve: { Base: number, Exponent: number },
	Ranks: { Types.RankConfig },
}

local Progression: ProgressionConfig = {
	LevelCap = 100,
	-- XP to reach the next level = floor(Base * Level ^ Exponent)
	XPCurve = { Base = 100, Exponent = 1.4 },
	-- Ascending by Level. Title text comes from the localization key "Rank.<Id>".
	Ranks = {
		{ Level = 1, Id = "Scavenger" },
		{ Level = 10, Id = "Raider" },
		{ Level = 20, Id = "Wrecker" },
		{ Level = 30, Id = "Rustlord" },
		{ Level = 40, Id = "Warlord" },
		{ Level = 50, Id = "WastelandLegend" },
		{ Level = 75, Id = "JunkKing" },
		{ Level = 100, Id = "ApexScrapper" },
	},
}

return Progression
