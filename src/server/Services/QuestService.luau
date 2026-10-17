--!strict
--[[
	QuestService — daily and weekly quests (bible §8; Shared/QuestRules, Config.Retention.Quests). Every lifetime stat
	a player earns (DataService.StatIncremented) counts toward their quests for today and this week, in the running
	round's mode (RoundService.currentMode). A quest that reaches its goal pays its Scrap at once (Gameplay
	transaction, sku "Quest.<id>") with a notice. Progress is saved in the player's Quests data; the Quests screen
	works out the rest (which quests, the resets) from QuestRules. Nothing counts in private servers, because stats
	don't (PrivateServerService.countsProgress).
	Developer panel: finish the next unfinished quest; "Next day" starts today's daily quests over.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local QuestRules = require(Shared:WaitForChild("QuestRules"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

local QuestService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Quests] {message}`)
	end
end

local function today(): number
	return QuestRules.dayAt(os.time())
end

-- True if any quest's progress differs between two snapshots of the same day.
local function progressChanged(before: QuestRules.QuestData, after: QuestRules.QuestData): boolean
	for _, kind in { "Daily", "Weekly" } do
		local old, new = (before :: any)[kind].Progress, (after :: any)[kind].Progress
		for id, value in new do
			if old[id] ~= value then
				return true
			end
		end
	end
	return false
end

-- Counts `amount` of `stat` (earned in `mode`) toward the player's quests, saves it and pays completed quests.
local function apply(player: Player, stat: string, amount: number, mode: string?)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local day = today()
	local updated, completed = QuestRules.record(data.Quests, player.UserId, day, stat, amount, mode)
	if not progressChanged(QuestRules.current(data.Quests, day), updated) then
		return
	end
	DataService.update(player, "Quests", function(saved)
		saved.Quests = updated
	end)
	for _, id in completed do
		local quest = QuestRules.find(id)
		if quest then
			DataService.addScrap(player, quest.Scrap, Analytics.Transaction.Gameplay, `Quest.{id}`)
			Analytics.custom(player, "QuestCompleted", quest.Scrap, { id })
			local args: { any } = { { Key = `Quest.{id}.Title` }, quest.Scrap }
			Net.fireClient("Notify", player, "Quests.Completed", args)
			log(`{player.Name} completed {id} (+{quest.Scrap} Scrap)`)
		end
	end
end

-- Developer panel: completes the next unfinished quest (today's daily ones first, then the weekly ones).
function QuestService.devFinishNext(player: Player)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	for _, entry in QuestRules.active(data.Quests, player.UserId, today()) do
		if not entry.Done then
			apply(player, entry.Quest.Stat, entry.Quest.Goal, entry.Quest.Mode)
			return
		end
	end
end

-- Developer panel: as if a day had passed — today's daily quests start over (the week stays).
function QuestService.devNextDay(player: Player)
	DataService.update(player, "Quests", function(saved)
		saved.Quests.Day -= 1
	end)
end

function QuestService.Init(_self: any)
	DataService.StatIncremented:Connect(function(player: Player, stat: string, amount: number)
		apply(player, stat, amount, RoundService.currentMode())
	end)
end

return QuestService
