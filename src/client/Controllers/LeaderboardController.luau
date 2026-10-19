--!strict
--[[
	LeaderboardController — the global leaderboards on the lobby screens (bible §8; Shared/LeaderboardRules), from the
	server's Leaderboards remote: each LeaderboardScreen-tagged part (its Stat attribute) shows the top BoardRows rows,
	switching between all-time and this week every BoardCycle seconds. Re-made when a streamed-out screen comes back.
	There is no Leaderboard menu screen (owner, 2026-10-19: "only the boards in the lobby").
	The look follows docs/reference/leaderboard-boards.png (owner's fix list, 2026-10-19): the board's title is part of
	the map (cream with a gold underline); each row is rank · avatar headshot · name · value (right-aligned, with
	thousands separators); the top 3 rows sit in rounded outlines with gold / silver / bronze rank numbers, rows 4–10
	are plain. The local player's name is in the accent color. Headshots load once per player (cached).
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

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))

local SCREEN_TAG = "LeaderboardScreen"
local GUI_NAME = "LeaderboardGui"
local PIXELS_PER_STUD = 40
local TOP_ROW = 1.35 -- height of a top-3 row, in plain rows

local LeaderboardController = {}

local player = Players.LocalPlayer
local boards: { [string]: { LeaderboardRules.Entry } } = {}
local boardPeriod: LeaderboardRules.Period = "AllTime"
local screens: { [BasePart]: SurfaceGui } = {}
local headshots: { [number]: string } = {} -- UserId → image ("" while loading or unavailable)

local drawScreens: () -> ()

-- The player's avatar headshot, loading it the first time (then the boards are drawn again).
local function headshot(userId: number): string
	local known = headshots[userId]
	if known then
		return known
	end
	headshots[userId] = ""
	if userId > 0 then
		task.spawn(function()
			local ok, image = pcall(function()
				return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			end)
			if ok and type(image) == "string" then
				headshots[userId] = image
				drawScreens()
			end
		end)
	end
	return ""
end

local function medalColor(rank: number): Color3?
	local medal = HudFormat.medal(rank)
	return if medal then (Kit.Colors :: any)[medal] else nil
end

local function row(frame: Frame, rank: number, entry: LeaderboardRules.Entry, height: number)
	local medal = medalColor(rank)
	local box = Instance.new("Frame")
	box.Name = `Row{rank}`
	box.LayoutOrder = rank
	box.Size = UDim2.fromScale(1, height)
	box.BackgroundColor3 = Kit.Colors.BoardRow
	box.BackgroundTransparency = if medal then 0.1 else 1
	if medal then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.25, 0)
		corner.Parent = box
		local outline = Instance.new("UIStroke")
		outline.Color = medal
		outline.Thickness = 2
		outline.Parent = box
	end
	box.Parent = frame

	local rankLabel = Kit.label(box, tostring(rank), UDim2.fromScale(0.09, 0.8), 26)
	rankLabel.AnchorPoint = Vector2.new(0, 0.5)
	rankLabel.Position = UDim2.fromScale(0.02, 0.5)
	rankLabel.Font = Kit.TitleFont
	rankLabel.TextColor3 = medal or Kit.Colors.Muted

	local face = Instance.new("ImageLabel")
	face.Name = "Headshot"
	face.BackgroundColor3 = Kit.Colors.Button
	face.AnchorPoint = Vector2.new(0, 0.5)
	face.Position = UDim2.fromScale(0.12, 0.5)
	face.Size = UDim2.fromScale(0.2, 0.78)
	face.Image = headshot(entry.UserId)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = face
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = face
	face.Parent = box

	local mine = entry.UserId == player.UserId
	local nameLabel = Kit.label(box, entry.Name, UDim2.fromScale(0.5, 0.62), if medal then 26 else 22)
	nameLabel.AnchorPoint = Vector2.new(0, 0.5)
	nameLabel.Position = UDim2.fromScale(0.25, 0.5)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = if mine then Kit.Colors.Accent elseif medal then Kit.Colors.Cream else Kit.Colors.Text

	local value =
		Kit.label(box, HudFormat.thousands(entry.Value), UDim2.fromScale(0.24, 0.62), if medal then 26 else 22)
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.Position = UDim2.fromScale(0.97, 0.5)
	value.Font = Kit.TitleFont
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.TextColor3 = medal or Kit.Colors.Text
end

local function drawScreen(part: BasePart, surface: SurfaceGui)
	local stat = part:GetAttribute("Stat")
	if type(stat) ~= "string" then
		return
	end
	local frame = surface:FindFirstChild("Rows") :: Frame
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local rows = Config.Retention.Leaderboards.BoardRows
	-- Heights as fractions of the screen: a period line, 3 taller medal rows, the rest plain.
	local plain = 1 / (rows + 3 * (TOP_ROW - 1) + 1.4)
	local header = Kit.label(frame, Localization.format(`Leaderboard.{boardPeriod}`), UDim2.fromScale(1, plain), 20)
	header.TextColor3 = Kit.Colors.Muted
	header.LayoutOrder = 0
	local entries: { LeaderboardRules.Entry } = boards[LeaderboardRules.key(stat, boardPeriod)] or {}
	if #entries == 0 then
		local empty = Kit.label(frame, Localization.format("Leaderboard.Empty"), UDim2.fromScale(1, plain), 22)
		empty.LayoutOrder = 1
	end
	for rank = 1, math.min(#entries, rows) do
		row(frame, rank, entries[rank], if rank <= 3 then plain * TOP_ROW else plain)
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
	frame.Size = UDim2.fromScale(0.94, 0.94)
	frame.Parent = surface
	local layout = Kit.list(frame, Enum.FillDirection.Vertical, UDim.new(0.006, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	surface.Parent = part
	screens[part] = surface
	part.Destroying:Connect(function()
		screens[part] = nil
	end)
	drawScreen(part, surface)
end

function drawScreens()
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
