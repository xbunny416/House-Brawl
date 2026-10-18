--!strict
--[[
	The saved shape of a player's data. New fields added here are filled in for existing players automatically
	(ProfileStore Reconcile). Renames, removals or value changes need a migration: bump VERSION and add a step in
	Server/Data/Migrations.
]]
local Config = require(script.Parent.Parent.Config)

export type Settings = {
	MusicVolume: number,
	SfxVolume: number,
	CameraSensitivity: number,
	CameraShake: boolean,
	LowGraphics: boolean,
	ButtonLayout: string,
}

export type Stats = {
	KOs: number,
	Falls: number,
	Wins: number,
	RingOuts: number,
	ChairKOs: number,
	PropKOs: number,
	PerfectDodges: number,
	StructuresBroken: number,
	RoundsPlayed: number,
	RoundsCompleted: number,
}

-- A private server owner's choices (Shared/PrivateServerRules): "Vote" or a mode / map id, and the round length.
export type PrivateServerSettings = { Mode: string, Map: string, RoundTime: number }

-- Daily login streak and playtime rewards (Shared/DailyRules). Day numbers count days since 1970 (UTC, from
-- Config.Retention.LoginStreak.ResetHourUTC); -1 = never.
export type DailyData = {
	LastClaimDay: number,
	Streak: number, -- streak day of the last claim (1-7)
	PlaytimeDay: number,
	PlaytimeSeconds: number, -- active seconds online on PlaytimeDay
	PlaytimeClaims: number, -- playtime rewards paid on PlaytimeDay
}

-- Quest progress (Shared/QuestRules) for the current day and week (day numbers as for Daily; weeks from Monday).
export type QuestProgress = { Progress: { [string]: number }, Done: { [string]: boolean } }
export type QuestData = { Day: number, Week: number, Daily: QuestProgress, Weekly: QuestProgress }

-- This week's leaderboard scores (Shared/LeaderboardRules): Wins and KOs earned since Week began, and the level
-- the player had when they first played that week.
export type LeaderboardWeek = { Week: number, Wins: number, KOs: number, StartLevel: number }

export type PlayerData = {
	Version: number,
	Scrap: number,
	Level: number,
	XP: number, -- XP into the current level
	Stats: Stats,
	Styles: { Owned: { [string]: boolean }, Equipped: string },
	Cosmetics: { Owned: { [string]: boolean }, Equipped: { [string]: string } },
	Titles: { Owned: { [string]: boolean }, Equipped: string },
	Tutorial: { Completed: boolean, Step: number },
	Settings: Settings,
	PurchaseIds: { string }, -- recent developer-product purchases already granted
	PrivateServer: PrivateServerSettings, -- applied in private servers this player owns
	Daily: DailyData,
	Quests: QuestData,
	LeaderboardWeek: LeaderboardWeek,
	Social: { GroupRewardClaimed: boolean }, -- the Roblox group join reward was paid
	Codes: { [string]: boolean }, -- redeem codes this player has used (ServerConfig.Codes keys)
}

local VERSION = 1

local defaultStyle = Config.Styles.Default

local Template: PlayerData = {
	Version = VERSION,
	Scrap = Config.Economy.StartingScrap,
	Level = 1,
	XP = 0,
	Stats = {
		KOs = 0,
		Falls = 0,
		Wins = 0,
		RingOuts = 0,
		ChairKOs = 0,
		PropKOs = 0,
		PerfectDodges = 0,
		StructuresBroken = 0,
		RoundsPlayed = 0,
		RoundsCompleted = 0,
	},
	Styles = { Owned = { [defaultStyle] = true }, Equipped = defaultStyle },
	Cosmetics = { Owned = {}, Equipped = {} },
	Titles = { Owned = {}, Equipped = "" },
	Tutorial = { Completed = false, Step = 0 },
	Settings = table.clone(Config.Data.DefaultSettings),
	PurchaseIds = {},
	PrivateServer = { Mode = "Vote", Map = "Vote", RoundTime = Config.Round.RoundTime },
	Daily = { LastClaimDay = -1, Streak = 0, PlaytimeDay = -1, PlaytimeSeconds = 0, PlaytimeClaims = 0 },
	Quests = { Day = -1, Week = -1, Daily = { Progress = {}, Done = {} }, Weekly = { Progress = {}, Done = {} } },
	LeaderboardWeek = { Week = -1, Wins = 0, KOs = 0, StartLevel = 1 },
	Social = { GroupRewardClaimed = false },
	Codes = {},
}

return {
	VERSION = VERSION,
	Template = Template,
}
