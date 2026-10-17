--!strict
--[[
	LeaderboardRules — the global leaderboards (bible §8, Config.Retention.Leaderboards); pure, shared by the server
	(Services/LeaderboardService), the lobby screens and the Leaderboard screen.
	A board for every stat in Leaderboards.Stats (Wins, KOs, Level), all-time and weekly. All-time scores are the
	lifetime stats (Level: the player's level). Weekly scores count from the week's start (Monday, as for the weekly
	quests): the Wins and KOs earned that week, and Level = levels gained that week. Each board is an OrderedDataStore
	named by `storeName` (a new one every week for the weekly boards).
]]
local Config = require(script.Parent.Config)
local QuestRules = require(script.Parent.QuestRules)
local DataTemplate = require(script.Parent.Data.Template)

type PlayerData = DataTemplate.PlayerData
type LeaderboardWeek = DataTemplate.LeaderboardWeek

export type Period = "AllTime" | "Weekly"
export type Entry = { UserId: number, Name: string, Value: number }

local LeaderboardRules = {}

LeaderboardRules.Periods = { "AllTime", "Weekly" } :: { Period }

-- The board's id, e.g. "Wins.AllTime".
function LeaderboardRules.key(stat: string, period: string): string
	return `{stat}.{period}`
end

function LeaderboardRules.storeName(stat: string, period: string, week: number): string
	local prefix = Config.Retention.Leaderboards.StorePrefix
	return if period == "Weekly" then `{prefix}{stat}_W{week}` else `{prefix}{stat}`
end

function LeaderboardRules.weekAt(unixTime: number): number
	return QuestRules.weekOf(QuestRules.dayAt(unixTime))
end

-- This week's scores, started over when the week has changed (`level` is the player's level now). Never mutates.
function LeaderboardRules.currentWeek(weekly: LeaderboardWeek, week: number, level: number): LeaderboardWeek
	if weekly.Week == week then
		return table.clone(weekly)
	end
	return { Week = week, Wins = 0, KOs = 0, StartLevel = level }
end

-- This week's scores after earning `amount` of `stat` (only Wins and KOs are counted this way).
function LeaderboardRules.addToWeek(
	weekly: LeaderboardWeek,
	week: number,
	level: number,
	stat: string,
	amount: number
): LeaderboardWeek
	local fresh = LeaderboardRules.currentWeek(weekly, week, level)
	if stat == "Wins" then
		fresh.Wins += amount
	elseif stat == "KOs" then
		fresh.KOs += amount
	end
	return fresh
end

-- The player's score on a board.
function LeaderboardRules.score(data: PlayerData, stat: string, period: string, week: number): number
	if period == "AllTime" then
		return if stat == "Level" then data.Level else (data.Stats :: any)[stat] or 0
	end
	local weekly = LeaderboardRules.currentWeek(data.LeaderboardWeek, week, data.Level)
	if stat == "Level" then
		return math.max(data.Level - weekly.StartLevel, 0)
	end
	return (weekly :: any)[stat] or 0
end

-- `entries` best first (ties: the lower UserId first, as an OrderedDataStore would), the top `count` with a score.
function LeaderboardRules.top(entries: { Entry }, count: number): { Entry }
	local list: { Entry } = {}
	for _, entry in entries do
		if entry.Value > 0 then
			table.insert(list, entry)
		end
	end
	table.sort(list, function(a: Entry, b: Entry): boolean
		if a.Value ~= b.Value then
			return a.Value > b.Value
		end
		return a.UserId < b.UserId
	end)
	while #list > count do
		table.remove(list)
	end
	return list
end

return LeaderboardRules
