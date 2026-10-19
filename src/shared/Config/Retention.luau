--!strict
-- Onboarding, daily/playtime rewards, quests, badges, leaderboards and group perks. Bible §8.
local Types = require(script.Parent.Types)

type RetentionConfig = {
	Tutorial: { Scrap: number, Title: string },
	LoginStreak: { Scrap: { number }, FinalDayCosmetic: boolean, FinalDayFallbackScrap: number, ResetHourUTC: number },
	Playtime: { Interval: number, Scrap: number, MaxClaimsPerDay: number },
	Quests: {
		DailyCount: number,
		ResetHourUTC: number,
		Daily: { Types.QuestConfig },
		Weekly: { Types.QuestConfig },
	},
	Badges: { [string]: Types.BadgeConfig },
	Leaderboards: {
		Stats: { string },
		TopCount: number,
		RefreshInterval: number,
		BoardRows: number,
		BoardCycle: number,
		StorePrefix: string,
	},
	Group: { GroupId: number, Scrap: number, RecheckInterval: number },
}

local Retention: RetentionConfig = {
	-- Training Yard tutorial reward.
	Tutorial = { Scrap = 200, Title = "Rookie" },

	-- Days 1-6 give Scrap; day 7 gives the weekly rotating cosmetic (Scrap cosmetics only; FinalDayFallbackScrap
	-- instead if the player already owns it). Missing a day resets to day 1. Days start at ResetHourUTC.
	LoginStreak = {
		Scrap = { 50, 75, 100, 150, 200, 250 },
		FinalDayCosmetic = true,
		FinalDayFallbackScrap = 300,
		ResetHourUTC = 0,
	},

	-- +25 Scrap every 10 minutes online (AFK time doesn't count), up to 6 times per day.
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

	-- Global all-time and weekly boards (OrderedDataStore; weeks start on Monday, like the weekly quests). The weekly
	-- Level board counts levels gained that week. RefreshInterval: seconds between saving scores and reading the tops.
	-- The lobby screens show BoardRows rows and switch between all-time and this week every BoardCycle seconds.
	Leaderboards = {
		Stats = { "Wins", "KOs", "Level" },
		TopCount = 50,
		RefreshInterval = 120,
		BoardRows = 10,
		BoardCycle = 10,
		StorePrefix = "Leaderboard_", -- changing it starts every board from scratch
	},

	-- The Roblox group: members get Scrap once (in a public server) and a [Crew] chat tag. GroupId 0 = no group yet
	-- (both off). Membership is checked on join and every RecheckInterval seconds until the reward is paid.
	Group = { GroupId = 0, Scrap = 150, RecheckInterval = 120 },
}

return Retention
