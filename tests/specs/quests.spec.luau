--!strict
-- Daily and weekly quests (step 3.4).
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local QuestRules = Roblox.require(Shared.QuestRules)

local DAY = 20000
local USER = 123456789

local function empty()
	return { Day = -1, Week = -1, Daily = { Progress = {}, Done = {} }, Weekly = { Progress = {}, Done = {} } }
end

return {
	["bible: 3 daily quests at 75-150 Scrap, 1 weekly at 600; every quest counts a real stat"] = function()
		local quests = Config.Retention.Quests
		expect.equal(quests.DailyCount, 3)
		for _, quest in quests.Daily do
			expect.truthy(quest.Scrap >= 75 and quest.Scrap <= 150, `{quest.Id} Scrap`)
		end
		expect.equal(#quests.Weekly, 1)
		expect.equal(quests.Weekly[1].Scrap, 600)
		local template = Roblox.require(Shared.Data.Template).Template
		for _, list in { quests.Daily, quests.Weekly } do
			for _, quest in list do
				expect.truthy(template.Stats[quest.Stat] ~= nil, `{quest.Id}: unknown stat {quest.Stat}`)
				expect.truthy(quest.Goal > 0, `{quest.Id} goal`)
				if quest.Mode then
					expect.truthy(Config.Modes.List[quest.Mode], `{quest.Id} mode`)
				end
			end
		end
	end,
	["daily picks: 3 different quests, the same all day, different for other players and days"] = function()
		local picks = QuestRules.dailyFor(USER, DAY)
		expect.equal(#picks, 3)
		expect.truthy(picks[1] ~= picks[2] and picks[2] ~= picks[3] and picks[1] ~= picks[3], "different")
		local again = QuestRules.dailyFor(USER, DAY)
		expect.equal(table.concat(again, ","), table.concat(picks, ","), "stable")
		local differs = 0
		for offset = 1, 10 do
			if table.concat(QuestRules.dailyFor(USER, DAY + offset), ",") ~= table.concat(picks, ",") then
				differs += 1
			end
			if table.concat(QuestRules.dailyFor(USER + offset, DAY), ",") ~= table.concat(picks, ",") then
				differs += 1
			end
		end
		expect.truthy(differs >= 15, `varies ({differs}/20)`)
	end,
	["weeks start on Monday"] = function()
		-- Day 4 (5 Jan 1970) was a Monday, day 3 a Sunday.
		expect.equal(QuestRules.weekOf(3), 0)
		expect.equal(QuestRules.weekOf(4), 1)
		expect.equal(QuestRules.weekOf(10), 1)
		expect.equal(QuestRules.weekOf(11), 2)
		expect.equal(QuestRules.secondsUntilNextWeek(4 * 86400), 7 * 86400, "Monday 00:00 to the next Monday")
		expect.equal(QuestRules.secondsUntilNextWeek(10 * 86400 + 3600), 86400 - 3600, "Sunday 01:00")
	end,
	["progress: counts the quest's stat, caps at the goal, completes once"] = function()
		local data = empty()
		local active = QuestRules.active(data, USER, DAY)
		expect.equal(#active, 4, "3 daily + 1 weekly")
		local target = active[1]
		local quest = target.Quest
		local updated, completed = QuestRules.record(data, USER, DAY, quest.Stat, quest.Goal - 1, quest.Mode)
		expect.equal(updated.Daily.Progress[target.Id], quest.Goal - 1)
		expect.equal(#completed == 0 or completed[1] ~= target.Id, true, "not yet")
		updated, completed = QuestRules.record(updated, USER, DAY, quest.Stat, 5, quest.Mode)
		expect.equal(updated.Daily.Progress[target.Id], quest.Goal, "capped")
		expect.truthy(table.find(completed, target.Id), "completed")
		local _, again = QuestRules.record(updated, USER, DAY, quest.Stat, 5, quest.Mode)
		expect.equal(table.find(again, target.Id), nil, "only once")
		local _, other = QuestRules.record(empty(), USER, DAY, "NotAStat", 99, nil)
		expect.equal(#other, 0, "other stats count nothing")
	end,
	["mode quests count only in their mode; the weekly quest counts in any"] = function()
		local data = empty()
		local _, completed = QuestRules.record(data, USER, DAY, "Wins", 99, "Casual")
		expect.equal(table.find(completed, "ClassicWin"), nil, "a Casual win is not a Classic win")
		local updated = QuestRules.record(data, USER, DAY, "Wins", 1, "Casual")
		expect.equal(updated.Weekly.Progress.WeeklyWins, 1, "the weekly quest counts every win")
	end,
	["a new day restarts the daily quests, a new week the weekly one"] = function()
		local data = empty()
		local weeklyQuest = QuestRules.active(data, USER, DAY)[4]
		local updated = QuestRules.record(data, USER, DAY, weeklyQuest.Quest.Stat, 3, nil)
		local nextDay = QuestRules.current(updated, DAY + 1)
		if QuestRules.weekOf(DAY + 1) == QuestRules.weekOf(DAY) then
			expect.equal(nextDay.Weekly.Progress[weeklyQuest.Id], 3, "the week goes on")
		end
		local nextWeek = QuestRules.current(updated, DAY + 7)
		expect.equal(nextWeek.Weekly.Progress[weeklyQuest.Id], nil, "a new week")
		expect.equal(next(nextDay.Daily.Progress), nil, "a new day")
	end,
}
