--!strict
-- Onboarding, daily/playtime rewards, quests, badges, leaderboards and group perks. Bible §8.
local Types = require(script.Parent.Types)

-- One segment of the lobby spin wheel. Kind: "Coins" / "XP" (Amount of it), "StyleSpin" (one bonus free style spin),
-- "Cosmetic" (a random cosmetic sold for Scrap the player doesn't own). Percent: its exact chance per spin.
export type WheelPrize = { Id: string, Kind: string, Amount: number, Percent: number, Color: string }

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
	Wheel: {
		SpinPrice: number,
		FreeSpinResetHourUTC: number,
		CosmeticFallbackScrap: number,
		Prizes: { WheelPrize },
	},
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

	-- The lobby spin wheel (owner's fix list, 2026-10-19: "1 free spin a day plus extra spins for Scrap"). Paid spins
	-- are a paid random item: every prize and its exact Percent show before a spin, they are offered only where
	-- PolicyService allows paid random items, and the maturity questionnaire declares them. Percents add up to 100;
	-- the segments go round the wheel in this order. Nothing in private servers (nothing is earned there).
	Wheel = {
		SpinPrice = 200, -- Scrap per spin after the day's free one
		FreeSpinResetHourUTC = 0,
		CosmeticFallbackScrap = 500, -- the Cosmetic prize when the player owns every cosmetic sold for Scrap
		Prizes = {
			{ Id = "Coins50", Kind = "Coins", Amount = 50, Percent = 30, Color = "#7A8B99" },
			{ Id = "XP150", Kind = "XP", Amount = 150, Percent = 15, Color = "#4A9BFF" },
			{ Id = "Coins100", Kind = "Coins", Amount = 100, Percent = 20, Color = "#5BD16A" },
			{ Id = "StyleSpin", Kind = "StyleSpin", Amount = 1, Percent = 10, Color = "#B05BD1" },
			{ Id = "Coins250", Kind = "Coins", Amount = 250, Percent = 12, Color = "#2F8C8C" },
			{ Id = "Cosmetic", Kind = "Cosmetic", Amount = 1, Percent = 5, Color = "#FF4FA3" },
			{ Id = "Coins500", Kind = "Coins", Amount = 500, Percent = 6, Color = "#FF8A3D" },
			{ Id = "Coins1000", Kind = "Coins", Amount = 1000, Percent = 2, Color = "#F2C14E" },
		},
	},
}

return Retention
