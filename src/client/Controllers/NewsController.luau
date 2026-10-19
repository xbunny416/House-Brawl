--!strict
--[[
	NewsController — the lobby's news TVs (owner's fix list, 2026-10-19: "TV showing fun news"). Every
	NewsScreen-tagged screen (the two CRT TVs on the bar counter's ends) gets a little news channel: a red
	"JUNKYARD NEWS" banner with a blinking LIVE dot, a big headline that changes every Config.World.News.Interval
	seconds with a burst of static, and a ticker of every headline scrolling along the bottom. Headlines are fun stories
	("News.<n>") mixed with live news this client knows (Client/Lib/NewsRules): the last round's winner, today's daily
	deal at the bar, the all-time Wins leader. Both TVs show the same story; nothing runs while the player is fighting.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LeaderboardRules = require(Shared:WaitForChild("LeaderboardRules"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local NewsRules = require(Client:WaitForChild("Lib"):WaitForChild("NewsRules"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))

local SCREEN_TAG = "NewsScreen"
local GUI_NAME = "NewsGui"
local PIXELS_PER_STUD = 70
local STATIC_TIME = 0.15 -- seconds of static between stories
local SCANLINES = 10
local BANNER_COLOR = Color3.fromHex("#B3261E")
local SCREEN_COLOR = Color3.fromHex("#0F2A2E")
local STATIC_COLOR = Color3.fromHex("#5E7A7E")
local TICKER_COLOR = Color3.fromHex("#F2C14E")
local DEAL_CHECK = 60 -- seconds between checks for a new day's daily deal

type Channel = {
	Surface: SurfaceGui,
	Background: Frame,
	Headline: TextLabel,
	Dot: Frame,
	TickerFrame: Frame,
	Ticker: TextLabel,
	Offset: number,
}

local NewsController = {}

local player = Players.LocalPlayer
local channels: { [BasePart]: Channel } = {}
local facts: NewsRules.Facts = {}
local headlines: { NewsRules.Headline } = {}
local current = 0
local tickerText = ""

local function textOf(headline: NewsRules.Headline): string
	return Localization.format(headline.Key, headline.Args)
end

local function rebuild()
	headlines = NewsRules.headlines(facts, Config.World.News.Headlines)
	local parts: { string } = {}
	for _, headline in headlines do
		table.insert(parts, textOf(headline))
	end
	tickerText = table.concat(parts, "     •     ")
	for _, channel in channels do
		channel.Ticker.Text = tickerText
	end
end

local function todaysDeal()
	local day = ShopRules.dayAt(Workspace:GetServerTimeNow())
	local itemId = ShopRules.dailyItems(day)[1]
	local price = itemId and ShopRules.priceOf("Cosmetic", itemId, day)
	if itemId and price then
		facts.Deal = { Item = Localization.format(`Cosmetic.{itemId}.Name`), Price = HudFormat.thousands(price) }
	end
end

local function build(part: Instance)
	if not part:IsA("BasePart") or channels[part] then
		return
	end
	local surface = Instance.new("SurfaceGui")
	surface.Name = GUI_NAME
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = PIXELS_PER_STUD
	surface.LightInfluence = 0
	surface.ClipsDescendants = true

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = SCREEN_COLOR
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = surface

	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.BackgroundColor3 = BANNER_COLOR
	banner.BorderSizePixel = 0
	banner.Size = UDim2.fromScale(1, 0.22)
	banner.Parent = background
	local title = Kit.label(banner, Localization.format("News.Header"), UDim2.fromScale(0.7, 0.8), 40)
	title.Position = UDim2.fromScale(0.04, 0.1)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.new(1, 1, 1)
	local live = Kit.label(banner, Localization.format("News.Live"), UDim2.fromScale(0.16, 0.6), 30)
	live.AnchorPoint = Vector2.new(1, 0.5)
	live.Position = UDim2.fromScale(0.97, 0.5)
	live.Font = Kit.TitleFont
	live.TextColor3 = Color3.new(1, 1, 1)
	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.AnchorPoint = Vector2.new(1, 0.5)
	dot.Position = UDim2.fromScale(0.78, 0.5)
	dot.Size = UDim2.fromScale(0.05, 0.36)
	local dotAspect = Instance.new("UIAspectRatioConstraint")
	dotAspect.AspectRatio = 1
	dotAspect.Parent = dot
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(0.5, 0)
	dotCorner.Parent = dot
	dot.Parent = banner

	local headline = Kit.label(background, "", UDim2.fromScale(0.92, 0.5), 44)
	headline.Name = "Headline"
	headline.AnchorPoint = Vector2.new(0.5, 0)
	headline.Position = UDim2.fromScale(0.5, 0.25)
	headline.Font = Kit.TitleFont
	headline.TextColor3 = Color3.new(1, 1, 1)

	local tickerFrame = Instance.new("Frame")
	tickerFrame.Name = "TickerBand"
	tickerFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	tickerFrame.BorderSizePixel = 0
	tickerFrame.Position = UDim2.fromScale(0, 0.8)
	tickerFrame.Size = UDim2.fromScale(1, 0.2)
	tickerFrame.ClipsDescendants = true
	tickerFrame.Parent = background
	local ticker = Kit.label(tickerFrame, tickerText, UDim2.fromScale(0, 1), 24)
	ticker.Name = "Ticker"
	ticker.AnchorPoint = Vector2.new(0, 0.5)
	ticker.Position = UDim2.fromScale(1, 0.5)
	ticker.TextScaled = false
	ticker.TextWrapped = false
	ticker.TextSize = 22
	ticker.AutomaticSize = Enum.AutomaticSize.X
	ticker.TextColor3 = TICKER_COLOR

	-- CRT scanlines over everything.
	for index = 1, SCANLINES do
		local line = Instance.new("Frame")
		line.Name = "Scanline"
		line.BackgroundColor3 = Color3.new(0, 0, 0)
		line.BackgroundTransparency = 0.85
		line.BorderSizePixel = 0
		line.Position = UDim2.fromScale(0, (index - 0.5) / SCANLINES)
		line.Size = UDim2.new(1, 0, 0, 2)
		line.ZIndex = 5
		line.Parent = background
	end

	surface.Parent = part
	local channel: Channel = {
		Surface = surface,
		Background = background,
		Headline = headline,
		Dot = dot,
		TickerFrame = tickerFrame,
		Ticker = ticker,
		Offset = 0,
	}
	channels[part] = channel
	if headlines[current] then
		headline.Text = textOf(headlines[current])
	end
	part.Destroying:Connect(function()
		channels[part] = nil
	end)
end

-- The next story, after a short burst of static.
local function nextStory()
	if #headlines == 0 then
		return
	end
	current = current % #headlines + 1
	local text = textOf(headlines[current])
	for _, channel in channels do
		channel.Background.BackgroundColor3 = STATIC_COLOR
		channel.Headline.Text = ""
	end
	task.delay(STATIC_TIME, function()
		for _, channel in channels do
			channel.Background.BackgroundColor3 = SCREEN_COLOR
			channel.Headline.Text = text
		end
	end)
end

local function fighting(): boolean
	local status = player:GetAttribute("RoundStatus")
	return status == "Playing" or status == "Respawning"
end

function NewsController.Start(_self: any)
	todaysDeal()
	rebuild()
	Net.on("RoundResults", function(rows: { any }, _modeId: string, mapId: string)
		for _, row in rows do
			if row.Placement == 1 then
				facts.Winner = { Name = row.Name, Map = Localization.format(`Map.{mapId}.Name`) }
				rebuild()
				return
			end
		end
	end)
	Net.on("Leaderboards", function(received: unknown)
		local boards = if type(received) == "table" then received :: any else {}
		local top = (boards[LeaderboardRules.key("Wins", "AllTime")] or {})[1]
		if top and top.Value > 0 then
			facts.Leader = { Name = top.Name, Value = HudFormat.thousands(top.Value) }
			rebuild()
		end
	end)
	for _, part in CollectionService:GetTagged(SCREEN_TAG) do
		build(part)
	end
	CollectionService:GetInstanceAddedSignal(SCREEN_TAG):Connect(build)
	nextStory()

	local storyTime, dayCheck = 0, 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		if fighting() then
			return
		end
		storyTime += deltaTime
		dayCheck += deltaTime
		if storyTime >= Config.World.News.Interval then
			storyTime = 0
			nextStory()
		end
		if dayCheck >= DEAL_CHECK then
			dayCheck = 0
			local before = facts.Deal and facts.Deal.Item
			todaysDeal() -- the daily deals change at the reset
			if facts.Deal and facts.Deal.Item ~= before then
				rebuild()
			end
		end
		local blink = os.clock() % 1 < 0.5
		for part, channel in channels do
			if part.Parent == nil then
				channels[part] = nil
				continue
			end
			channel.Dot.BackgroundTransparency = if blink then 0 else 0.7
			local width = channel.TickerFrame.AbsoluteSize.X
			channel.Offset -= Config.World.News.TickerSpeed * deltaTime
			if channel.Offset < -channel.Ticker.AbsoluteSize.X - width then
				channel.Offset = 0
			end
			channel.Ticker.Position = UDim2.new(1, channel.Offset, 0.5, 0)
		end
	end)
end

return NewsController
