--!strict
--[[
	QuestsController — the Quests screen (bible §5.3 / §8; Shared/QuestRules): today's daily quests and this week's
	weekly quest, each with what to do, a progress bar, the reward and a done mark, and the time until each set
	changes. Quests count by themselves and pay when done (QuestService); this screen only shows them. Opens from the
	left-edge menu and the lobby's quest board (LobbyPromptController). In a private server nothing counts, and it
	says so.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))
local QuestRules = require(Shared:WaitForChild("QuestRules"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local MENU_ORDER = 3 -- bible §5.1: Shop, Locker, Quests, Daily Reward, ...
local TICK_INTERVAL = 1
local ROW_HEIGHT = 0.17 -- of the list

type Row = { Frame: Frame, Title: TextLabel, Detail: TextLabel, Reward: TextLabel, Fill: Frame }

local QuestsController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local list: Frame
local rows: { Row } = {}
local resetLabel: TextLabel

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function countsHere(): boolean
	return Workspace:GetAttribute("PrivateServer") ~= true or Config.Economy.PrivateServerProgress
end

local function buildRow(order: number): Row
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Kit.Colors.Button
	frame.BackgroundTransparency = 0.2
	frame.Size = UDim2.fromScale(1, ROW_HEIGHT)
	frame.LayoutOrder = order
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = frame
	local title = Kit.label(frame, "", UDim2.fromScale(0.62, 0.45), 22)
	title.Position = UDim2.fromScale(0.03, 0.06)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local detail = Kit.label(frame, "", UDim2.fromScale(0.62, 0.35), 18)
	detail.Position = UDim2.fromScale(0.03, 0.55)
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextColor3 = Kit.Colors.Muted
	local reward = Kit.label(frame, "", UDim2.fromScale(0.3, 0.45), 20)
	reward.AnchorPoint = Vector2.new(1, 0)
	reward.Position = UDim2.fromScale(0.97, 0.06)
	reward.TextXAlignment = Enum.TextXAlignment.Right
	reward.TextColor3 = Kit.Colors.Accent
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Kit.Colors.Panel
	bar.AnchorPoint = Vector2.new(1, 0)
	bar.Position = UDim2.fromScale(0.97, 0.62)
	bar.Size = UDim2.fromScale(0.3, 0.22)
	bar.Parent = frame
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Kit.Colors.Accent
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = bar
	frame.Parent = list
	return { Frame = frame, Title = title, Detail = detail, Reward = reward, Fill = fill }
end

local function render()
	local data = DataController.get()
	if data == nil then
		return
	end
	local active = QuestRules.active(data.Quests, player.UserId, QuestRules.dayAt(now()))
	for index, entry in active do
		local row = rows[index] or buildRow(index)
		rows[index] = row
		row.Frame.Visible = true
		local kind = Localization.format(`Quests.{entry.Kind}`)
		row.Title.Text = Localization.format("Quests.RowTitle", { kind, Localization.format(`Quest.{entry.Id}.Title`) })
		row.Detail.Text = Localization.format(`Quest.{entry.Id}.Desc`, { entry.Quest.Goal })
		row.Reward.Text = if entry.Done
			then Localization.format("Quests.Done")
			else Localization.format("Currency.Scrap", { entry.Quest.Scrap })
		local args: { any } = { entry.Progress, entry.Quest.Goal }
		row.Detail.Text ..= "   " .. Localization.format("Quests.Progress", args)
		row.Fill.Size = UDim2.fromScale(entry.Progress / entry.Quest.Goal, 1)
		row.Frame.BackgroundTransparency = if entry.Done then 0.55 else 0.2
	end
	for index = #active + 1, #rows do
		rows[index].Frame.Visible = false
	end
	if not countsHere() then
		resetLabel.Text = Localization.format("Quests.PrivateServer")
	else
		local daily = Formulas.secondsUntilNextDay(now(), Config.Retention.Quests.ResetHourUTC)
		local weekly = QuestRules.secondsUntilNextWeek(now())
		local args: { any } = { HudFormat.longClock(daily), weekly // 86400, HudFormat.longClock(weekly % 86400) }
		resetLabel.Text = Localization.format("Quests.Resets", args)
	end
end

local function build()
	gui = Kit.screen("Quests", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.6, 0.66),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(760, 520)
	)

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.12)
	header.Parent = panel
	local title = Kit.label(header, Localization.format("Quests.Title"), UDim2.fromScale(0.8, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.2, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0, 0.15)
	list.Size = UDim2.fromScale(1, 0.72)
	list.Parent = panel
	local layout = Kit.list(list, Enum.FillDirection.Vertical, UDim.new(0.03, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	resetLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.08), 18)
	resetLabel.Position = UDim2.fromScale(0, 0.9)
	resetLabel.TextColor3 = Kit.Colors.Muted
end

function QuestsController.Start(_self: any)
	build()
	MenuController.addScreen(Localization.format("Menu.Quests"), MENU_ORDER, gui, render)
	DataController.Changed:Connect(function(key: string)
		if gui.Enabled and key == "Quests" then
			render()
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= TICK_INTERVAL and gui.Enabled then
			elapsed = 0
			render() -- the countdowns, and new quests at the reset
		end
	end)
end

return QuestsController
