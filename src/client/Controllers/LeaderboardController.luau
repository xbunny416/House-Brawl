--!strict
--[[
	LeaderboardController — the global leaderboards on the lobby screens (bible §8; Shared/LeaderboardRules), from the
	server's Leaderboards remote: each LeaderboardScreen-tagged part (its Stat attribute) shows the top BoardRows rows,
	switching between all-time and this week every BoardCycle seconds. Re-made when a streamed-out screen comes back.
	There is no Leaderboard menu screen (owner, 2026-10-19: "only the boards in the lobby").
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

local SCREEN_TAG = "LeaderboardScreen"
local GUI_NAME = "LeaderboardGui"
local PIXELS_PER_STUD = 40

local LeaderboardController = {}

local player = Players.LocalPlayer
local boards: { [string]: { LeaderboardRules.Entry } } = {}
local boardPeriod: LeaderboardRules.Period = "AllTime"
local screens: { [BasePart]: SurfaceGui } = {}

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

function LeaderboardController.Start(_self: any)
	Net.on("Leaderboards", function(received: unknown)
		if type(received) == "table" then
			boards = received :: any
			drawScreens()
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
