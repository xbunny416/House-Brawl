--!strict
--[[
	LeaderboardController — the global leaderboards on the client (bible §8; Shared/LeaderboardRules), from the
	server's Leaderboards remote:
	  * Lobby screens: each LeaderboardScreen-tagged part (its Stat attribute) shows the top BoardRows rows, switching
	    between all-time and this week every BoardCycle seconds. Re-made when a streamed-out screen comes back.
	  * The Leaderboard menu screen: a tab per stat, All-time / This week, the top TopCount with the local player
	    highlighted, and a note when the boards only show this server (offline, e.g. Studio without API access).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LeaderboardRules = require(Shared:WaitForChild("LeaderboardRules"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local MENU_ORDER = 5 -- bible §5.1: Shop, Locker, Quests, Daily Reward, Leaderboard, Settings
local SCREEN_TAG = "LeaderboardScreen"
local GUI_NAME = "LeaderboardGui"
local PIXELS_PER_STUD = 40
local ROW_HEIGHT = 30 -- pixels, menu screen

local LeaderboardController = {}

local player = Players.LocalPlayer
local boards: { [string]: { LeaderboardRules.Entry } } = {}
local online = true
local boardPeriod: LeaderboardRules.Period = "AllTime"
local screens: { [BasePart]: SurfaceGui } = {}

local gui: ScreenGui
local list: ScrollingFrame
local note: TextLabel
local statButtons: { [string]: TextButton } = {}
local periodButtons: { [string]: TextButton } = {}
local currentStat = Config.Retention.Leaderboards.Stats[1]
local currentPeriod: LeaderboardRules.Period = "AllTime"

local function statName(stat: string, period: string): string
	return Localization.format(
		if period == "Weekly" and stat == "Level" then "Leaderboard.LevelsGained" else `Leaderboard.Stat.{stat}`
	)
end

local function rowText(rank: number, entry: LeaderboardRules.Entry): string
	local args: { any } = { rank, entry.Name, entry.Value }
	return Localization.format("Leaderboard.Row", args)
end

---------------------------------------------------------------------------------------------------------------------
-- Lobby screens
---------------------------------------------------------------------------------------------------------------------

local function drawScreen(part: BasePart, surface: SurfaceGui)
	local stat = part:GetAttribute("Stat")
	if type(stat) ~= "string" then
		return
	end
	local frame = surface:FindFirstChild("Rows") :: Frame
	for _, child in frame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local rows = Config.Retention.Leaderboards.BoardRows
	local height = 1 / (rows + 1.5)
	local header = Kit.label(frame, Localization.format(`Leaderboard.{boardPeriod}`), UDim2.fromScale(1, height * 1.3))
	header.TextColor3 = Kit.Colors.Accent
	header.LayoutOrder = 0
	local entries: { LeaderboardRules.Entry } = boards[LeaderboardRules.key(stat, boardPeriod)] or {}
	if #entries == 0 then
		local empty = Kit.label(frame, Localization.format("Leaderboard.Empty"), UDim2.fromScale(1, height))
		empty.LayoutOrder = 1
	end
	for rank = 1, math.min(#entries, rows) do
		local label = Kit.label(frame, rowText(rank, entries[rank]), UDim2.fromScale(1, height))
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = rank
		if entries[rank].UserId == player.UserId then
			label.TextColor3 = Kit.Colors.Accent
		end
	end
end

local function addScreen(part: Instance)
	if not part:IsA("BasePart") or screens[part] then
		return
	end
	local surface = Instance.new("SurfaceGui")
	surface.Name = GUI_NAME
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = PIXELS_PER_STUD
	surface.LightInfluence = 0
	local frame = Instance.new("Frame")
	frame.Name = "Rows"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.94, 0.92)
	frame.Parent = surface
	local layout = Kit.list(frame, Enum.FillDirection.Vertical, UDim.new(0, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	surface.Parent = part
	screens[part] = surface
	part.Destroying:Connect(function()
		screens[part] = nil
	end)
	drawScreen(part, surface)
end

local function drawScreens()
	for part, surface in screens do
		if part.Parent then
			drawScreen(part, surface)
		else
			screens[part] = nil
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Menu screen
---------------------------------------------------------------------------------------------------------------------

local function render()
	for stat, button in statButtons do
		Kit.setChosen(button, stat == currentStat)
		button.Text = statName(stat, currentPeriod)
	end
	for period, button in periodButtons do
		Kit.setChosen(button, period == currentPeriod)
	end
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local entries: { LeaderboardRules.Entry } = boards[LeaderboardRules.key(currentStat, currentPeriod)] or {}
	if #entries == 0 then
		Kit.label(list, Localization.format("Leaderboard.Empty"), UDim2.new(1, 0, 0, ROW_HEIGHT), 20)
	end
	for rank, entry in entries do
		local label = Kit.label(list, rowText(rank, entry), UDim2.new(1, 0, 0, ROW_HEIGHT), 20)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = rank
		if entry.UserId == player.UserId then
			label.TextColor3 = Kit.Colors.Accent
		end
	end
	note.Text = if online then "" else Localization.format("Leaderboard.Offline")
end

local function build()
	gui = Kit.screen("Leaderboard", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.56, 0.74),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(700, 600)
	)
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.1)
	header.Parent = panel
	local title = Kit.label(header, Localization.format("Leaderboard.Title"), UDim2.fromScale(0.75, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.22, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.fromScale(0, 0.12)
	tabs.Size = UDim2.fromScale(1, 0.08)
	tabs.Parent = panel
	local tabLayout = Kit.list(tabs, Enum.FillDirection.Horizontal, UDim.new(0.02, 0))
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	for order, stat in Config.Retention.Leaderboards.Stats do
		local button = Kit.button(tabs, "", UDim2.fromScale(0.22, 1))
		button.LayoutOrder = order
		button.Activated:Connect(function()
			currentStat = stat
			render()
		end)
		statButtons[stat] = button
	end
	for index, period in LeaderboardRules.Periods do
		local button = Kit.button(tabs, Localization.format(`Leaderboard.{period}`), UDim2.fromScale(0.15, 1))
		button.LayoutOrder = 10 + index
		button.Activated:Connect(function()
			currentPeriod = period :: LeaderboardRules.Period
			render()
		end)
		periodButtons[period] = button
	end

	list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromScale(0, 0.22)
	list.Size = UDim2.fromScale(1, 0.7)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = panel
	local layout = Kit.list(list, Enum.FillDirection.Vertical, UDim.new(0, 2))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	note = Kit.label(panel, "", UDim2.fromScale(1, 0.06), 16)
	note.Position = UDim2.fromScale(0, 0.93)
	note.TextColor3 = Kit.Colors.Muted
end

function LeaderboardController.Start(_self: any)
	build()
	MenuController.addScreen(Localization.format("Menu.Leaderboard"), MENU_ORDER, gui, render)
	Net.on("Leaderboards", function(received: unknown, isOnline: unknown)
		if type(received) == "table" then
			boards = received :: any
			online = isOnline == true
			drawScreens()
			if gui.Enabled then
				render()
			end
		end
	end)
	for _, part in CollectionService:GetTagged(SCREEN_TAG) do
		addScreen(part)
	end
	CollectionService:GetInstanceAddedSignal(SCREEN_TAG):Connect(addScreen)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= Config.Retention.Leaderboards.BoardCycle then
			elapsed = 0
			boardPeriod = if boardPeriod == "AllTime" then "Weekly" else "AllTime"
			drawScreens()
		end
	end)
end

return LeaderboardController
