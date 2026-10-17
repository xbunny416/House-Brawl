--!strict
--[[
	QuestRules — daily and weekly quests (bible §8, Config.Retention.Quests); pure, shared with the Quests screen.
	  * Every day (from Quests.ResetHourUTC) each player gets DailyCount of the Daily quests, picked by a shuffle seeded
	    by the day and their UserId: they differ between players but stay the same all day, in every server, with
	    nothing to save.
	  * Every week (Monday to Sunday) everyone gets all the Weekly quests.
	  * A quest counts its Stat — the lifetime stats, so nothing counts where stats don't (private servers) — and only
	    in its Mode when it has one. Reaching Goal completes it; its Scrap is paid once (QuestService).
]]
local Config = require(script.Parent.Config)
local Formulas = require(script.Parent.Formulas)
local Types = require(script.Parent.Config.Types)
local DataTemplate = require(script.Parent.Data.Template)

export type QuestData = DataTemplate.QuestData
export type Kind = "Daily" | "Weekly"
export type Active = { Id: string, Kind: Kind, Quest: Types.QuestConfig, Progress: number, Done: boolean }

-- Park–Miller "minimal standard" generator (exact in doubles), as in ShopRules.
local MODULUS = 2147483647
local MULTIPLIER = 16807
local SEED_STEP = 7919
local WARMUP = 4
local MONDAY_OFFSET = 3 -- day 0 (1 Jan 1970) was a Thursday

local QuestRules = {}

function QuestRules.dayAt(unixTime: number): number
	return Formulas.dayNumber(unixTime, Config.Retention.Quests.ResetHourUTC)
end

-- The week number of a day; weeks start on Monday.
function QuestRules.weekOf(day: number): number
	return (day + MONDAY_OFFSET) // 7
end

-- Seconds from `unixTime` until the weekly quests change (the next Monday's reset).
function QuestRules.secondsUntilNextWeek(unixTime: number): number
	local resetHour = Config.Retention.Quests.ResetHourUTC
	local nextMonday = (QuestRules.weekOf(QuestRules.dayAt(unixTime)) + 1) * 7 - MONDAY_OFFSET
	return nextMonday * 86400 + resetHour * 3600 - unixTime
end

-- The quest with this id and whether it is a daily or a weekly one, or nil.
function QuestRules.find(id: string): (Types.QuestConfig?, Kind?)
	for _, quest in Config.Retention.Quests.Daily do
		if quest.Id == id then
			return quest, "Daily"
		end
	end
	for _, quest in Config.Retention.Quests.Weekly do
		if quest.Id == id then
			return quest, "Weekly"
		end
	end
	return nil, nil
end

-- The daily quest ids `userId` gets on `day`.
function QuestRules.dailyFor(userId: number, day: number): { string }
	local pool: { string } = {}
	for _, quest in Config.Retention.Quests.Daily do
		table.insert(pool, quest.Id)
	end
	local count = math.min(Config.Retention.Quests.DailyCount, #pool)
	local state = (day * SEED_STEP + userId % (MODULUS - 1)) % (MODULUS - 1) + 1
	for _ = 1, WARMUP do
		state = state * MULTIPLIER % MODULUS
	end
	local picked: { string } = {}
	for index = 1, count do
		state = state * MULTIPLIER % MODULUS
		local swap = index + state % (#pool - index + 1)
		pool[index], pool[swap] = pool[swap], pool[index]
		table.insert(picked, pool[index])
	end
	return picked
end

function QuestRules.weekly(): { string }
	local ids: { string } = {}
	for _, quest in Config.Retention.Quests.Weekly do
		table.insert(ids, quest.Id)
	end
	return ids
end

-- `data` for `day`: the daily (or weekly) progress starts again when the day (or week) has changed. Never mutates.
function QuestRules.current(data: QuestData, day: number): QuestData
	local week = QuestRules.weekOf(day)
	local sameDay, sameWeek = data.Day == day, data.Week == week
	return {
		Day = day,
		Week = week,
		Daily = if sameDay
			then { Progress = table.clone(data.Daily.Progress), Done = table.clone(data.Daily.Done) }
			else { Progress = {}, Done = {} },
		Weekly = if sameWeek
			then { Progress = table.clone(data.Weekly.Progress), Done = table.clone(data.Weekly.Done) }
			else { Progress = {}, Done = {} },
	}
end

-- The player's quests on `day` with their progress: the daily ones first, then the weekly ones.
function QuestRules.active(data: QuestData, userId: number, day: number): { Active }
	local fresh = QuestRules.current(data, day)
	local list: { Active } = {}
	local function add(id: string, kind: Kind)
		local quest = QuestRules.find(id)
		if quest then
			local progress = if kind == "Daily" then fresh.Daily else fresh.Weekly
			table.insert(list, {
				Id = id,
				Kind = kind,
				Quest = quest,
				Progress = math.min(progress.Progress[id] or 0, quest.Goal),
				Done = progress.Done[id] == true,
			})
		end
	end
	for _, id in QuestRules.dailyFor(userId, day) do
		add(id, "Daily")
	end
	for _, id in QuestRules.weekly() do
		add(id, "Weekly")
	end
	return list
end

--[[
	Counts `amount` of `stat` (earned in `mode`, nil between rounds) toward the player's quests on `day`. Returns the
	new data and the ids of the quests it completed (pay those once).
]]
function QuestRules.record(
	data: QuestData,
	userId: number,
	day: number,
	stat: string,
	amount: number,
	mode: string?
): (QuestData, { string })
	local fresh = QuestRules.current(data, day)
	local completed: { string } = {}
	for _, entry in QuestRules.active(data, userId, day) do
		local quest = entry.Quest
		if not entry.Done and quest.Stat == stat and (quest.Mode == nil or quest.Mode == mode) then
			local progress = if entry.Kind == "Daily" then fresh.Daily else fresh.Weekly
			local value = math.min((progress.Progress[entry.Id] or 0) + amount, quest.Goal)
			progress.Progress[entry.Id] = value
			if value >= quest.Goal then
				progress.Done[entry.Id] = true
				table.insert(completed, entry.Id)
			end
		end
	end
	return fresh, completed
end

return QuestRules
