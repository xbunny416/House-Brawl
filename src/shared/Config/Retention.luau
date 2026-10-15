--!strict
-- Onboarding, daily/playtime rewards, quests, badges, leaderboards and group perks. Bible §8.
local Types = require(script.Parent.Types)

type RetentionConfig = {
	Tutorial: { Scrap: number, Title: string },
	LoginStreak: { Scrap: { number }, FinalDayCosmetic: boolean, ResetHourUTC: number },
	Playtime: { Interval: number, Scrap: number, MaxClaimsPerDay: number },
	Quests: {
		DailyCount: number,
		ResetHourUTC: number,
		Daily: { Types.QuestConfig },
		Weekly: { Types.QuestConfig },
	},
	Badges: { [string]: Types.BadgeConfig },
	Leaderboards: { Stats: { string }, TopCount: number, RefreshInterval: number },
	Group: { GroupId: number, Scrap: number },
}

local Retention: RetentionConfig = {
	-- Training Yard tutorial reward.
	Tutorial = { Scrap = 200, Title = "Rookie" },

	-- Days 1-6 give Scrap; day 7 gives the weekly rotating cosmetic. Missing a day resets to day 1.
	LoginStreak = { Scrap = { 50, 75, 100, 150, 200, 250 }, FinalDayCosmetic = true, ResetHourUTC = 0 },

	-- +25 Scrap every 10 minutes online, up to 6 times per day.
	Playtime = { Interval = 600, Scrap = 25, MaxClaimsPerDay = 6 },

	Quests = {
		DailyCount = 3,
		ResetHourUTC = 0,
		Daily = {
			{ Id = "ChairKOs", Stat = "ChairKOs", Goal = 5, Scrap = 150 },
			{ Id = "ClassicWin", Stat = "Wins", Goal = 1, Scrap = 100, Mode = "Classic" },
			{ Id = "PerfectDodges", Stat = "PerfectDodges", Goal = 10, Scrap = 125 },
			{ Id = "StructuresBroken", Stat = "StructuresBroken", Goal = 8, Scrap = 75 },
			{ Id = "RingOuts", Stat = "RingOuts", Goal = 10, Scrap = 100 },
			{ Id = "ThrowKOs", Stat = "PropKOs", Goal = 5, Scrap = 125 },
			{ Id = "RoundsPlayed", Stat = "RoundsCompleted", Goal = 3, Scrap = 75 },
		},
		Weekly = {
			{ Id = "WeeklyWins", Stat = "Wins", Goal = 10, Scrap = 600 },
		},
	},

	-- BadgeId 0 = not created yet (award is skipped).
	Badges = {
		Welcome = { BadgeId = 0 },
		FirstKO = { BadgeId = 0, Stat = "KOs", Goal = 1 },
		FirstWin = { BadgeId = 0, Stat = "Wins", Goal = 1 },
		RingOutRookie = { BadgeId = 0, Stat = "RingOuts", Goal = 100 },
		ChairMaster = { BadgeId = 0, Stat = "ChairKOs", Goal = 50 },
		Demolition = { BadgeId = 0, Stat = "StructuresBroken", Goal = 500 },
		Survivor = { BadgeId = 0 }, -- win a Classic round without losing a life
		Level10 = { BadgeId = 0, Stat = "Level", Goal = 10 },
		Level25 = { BadgeId = 0, Stat = "Level", Goal = 25 },
		Level50 = { BadgeId = 0, Stat = "Level", Goal = 50 },
		Level100 = { BadgeId = 0, Stat = "Level", Goal = 100 },
	},

	-- Global all-time and weekly boards (OrderedDataStore).
	Leaderboards = { Stats = { "Wins", "KOs", "Level" }, TopCount = 50, RefreshInterval = 120 },

	-- GroupId 0 = no group yet (reward disabled).
	Group = { GroupId = 0, Scrap = 150 },
}

return Retention
