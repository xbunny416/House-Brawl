--!strict
--[[
	LoadingScreen — replaces Roblox's default loading screen (bible §5.3; step 3.10). Runs from ReplicatedFirst, before
	the rest of the game arrives: a dark screen with the game's title, a random tip and a "Loading" line, shown for at
	least Config.World.Loading.MinTime seconds and until the game has loaded and the player's data has arrived (the
	server sets their Level attribute when it loads), at most MaxTime; then it fades out. Colors match Client/Ui/Kit
	(not loaded yet this early).
]]
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BACKGROUND = Color3.fromHex("#1E1A17")
local TEXT = Color3.fromHex("#F2E6D0")
local ACCENT = Color3.fromHex("#D9822B")
local MUTED = Color3.fromHex("#A89A85")
local DOTS_INTERVAL = 0.4

local player = Players.LocalPlayer
local startedAt = os.clock()

ReplicatedFirst:RemoveDefaultLoadingScreen()

local screen = Instance.new("ScreenGui")
screen.Name = "LoadingScreen"
screen.IgnoreGuiInset = true
screen.DisplayOrder = 100
screen.ResetOnSpawn = false
local background = Instance.new("Frame")
background.BackgroundColor3 = BACKGROUND
background.BorderSizePixel = 0
background.Size = UDim2.fromScale(1, 1)
background.Parent = screen

local function label(size: UDim2, y: number, color: Color3, maxSize: number): TextLabel
	local made = Instance.new("TextLabel")
	made.BackgroundTransparency = 1
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.Position = UDim2.fromScale(0.5, y)
	made.Size = size
	made.Font = Enum.Font.GothamBlack
	made.TextColor3 = color
	made.TextScaled = true
	made.TextWrapped = true
	made.Text = ""
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.Parent = made
	made.Parent = background
	return made
end

local title = label(UDim2.fromScale(0.8, 0.14), 0.4, ACCENT, 72)
local tip = label(UDim2.fromScale(0.7, 0.08), 0.6, TEXT, 26)
tip.Font = Enum.Font.GothamBold
local status = label(UDim2.fromScale(0.4, 0.05), 0.88, MUTED, 22)
status.Font = Enum.Font.GothamBold
screen.Parent = player:WaitForChild("PlayerGui")

-- The text needs the shared modules (Config, Localization), which arrive a moment later.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local loading = Config.World.Loading

title.Text = Localization.format("Lobby.Sign.Title")
local tipKey = `Tip.{Random.new():NextInteger(1, loading.TipCount)}`
tip.Text = Localization.format("Loading.Tip", { Localization.format(tipKey) })

local function ready(): boolean
	return game:IsLoaded() and player:GetAttribute("Level") ~= nil
end

local dots = 0
while os.clock() - startedAt < loading.MaxTime and (not ready() or os.clock() - startedAt < loading.MinTime) do
	dots = dots % 3 + 1
	status.Text = Localization.format("Loading.Text") .. string.rep(".", dots)
	task.wait(DOTS_INTERVAL)
end

local fade = TweenInfo.new(loading.FadeTime)
TweenService:Create(background, fade, { BackgroundTransparency = 1 }):Play()
for _, text in { title, tip, status } do
	TweenService:Create(text, fade, { TextTransparency = 1 }):Play()
end
task.wait(loading.FadeTime)
screen:Destroy()
