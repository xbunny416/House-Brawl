--!strict
--[[
	NewsController — the lobby's TVs (owner's fix list, 2026-10-19: "TV showing fun news"; "about 3 big tv, screen only
	show in 2 small"). Every NewsScreen screen (the two small TVs on the bar counter's ends) and VoteScreen screen (the
	three big TVs over the bar, Index 1–3) gets a little news channel: a red
	"JUNKYARD NEWS" banner with a blinking LIVE dot, a big headline that changes every Config.World.News.Interval
	seconds with a burst of static, and a ticker of every headline scrolling along the bottom. Headlines are fun stories
	("News.<n>") mixed with live news this client knows (Client/Lib/NewsRules): the last round's winner, today's daily
	deal at the bar, the all-time Wins leader. All TVs show the same story; nothing runs while the player is fighting.
	The big TVs switch to the round when there is one: during the map vote each shows one map of the ballot with its
	votes and the time left (VoteState), during a round the middle one shows the live match (arena, time left, fighters
	still in); otherwise they show the news too.
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

local SCREEN_TAGS = { "NewsScreen", "VoteScreen" } -- small news TVs, big vote TVs
local VOTE_TAG = "VoteScreen"
local LIVE_TV = 2 -- the big TV that shows the live match
local OVERLAY_REFRESH = 0.25
local GUI_NAME = "NewsGui"
local PIXELS_PER_STUD = 70
local STATIC_TIME = 0.15 -- seconds of static between stories
local SCANLINES = 10
local BANNER_COLOR = Color3.fromHex("#B3261E")
local SCREEN_COLOR = Color3.fromHex("#0F2A2E")
local STATIC_COLOR = Color3.fromHex("#5E7A7E")
local TICKER_COLOR = Color3.fromHex("#F2C14E")
local VOTE_COLOR = Color3.fromHex("#D9822B")
local DEAL_CHECK = 60 -- seconds between checks for a new day's daily deal

type Channel = {
	Surface: SurfaceGui,
	Background: Frame,
	Headline: TextLabel,
	Dot: Frame,
	TickerFrame: Frame,
	Ticker: TextLabel,
	Offset: number,
	-- Big TVs only: the vote / live match screen over the news, and which of the three it is.
	Overlay: Frame?,
	Index: number,
}

type Overlay = { Banner: Frame, BannerText: TextLabel, Title: TextLabel, Detail: TextLabel, Footer: TextLabel }

local NewsController = {}

local player = Players.LocalPlayer
local channels: { [BasePart]: Channel } = {}
local facts: NewsRules.Facts = {}
local headlines: { NewsRules.Headline } = {}
local current = 0
local tickerText = ""
local overlays: { [Frame]: Overlay } = {}
local ballot: { string } = {} -- the map vote's options, while voting
local votes: { [string]: number } = {}
local lastState: unknown = nil

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

-- The vote / live match screen drawn over a big TV's news (hidden until there is a round to show).
local function buildOverlay(background: Frame): Frame
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.BackgroundColor3 = SCREEN_COLOR
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 4
	overlay.Visible = false
	overlay.Parent = background
	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.BorderSizePixel = 0
	banner.Size = UDim2.fromScale(1, 0.22)
	banner.Parent = overlay
	local bannerText = Kit.label(banner, "", UDim2.fromScale(0.92, 0.8), 44)
	bannerText.AnchorPoint = Vector2.new(0.5, 0.5)
	bannerText.Position = UDim2.fromScale(0.5, 0.5)
	bannerText.Font = Kit.TitleFont
	bannerText.TextColor3 = Color3.new(1, 1, 1)
	local title = Kit.label(overlay, "", UDim2.fromScale(0.92, 0.3), 60)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.27)
	title.Font = Kit.TitleFont
	title.TextColor3 = Color3.new(1, 1, 1)
	local detail = Kit.label(overlay, "", UDim2.fromScale(0.92, 0.18), 40)
	detail.AnchorPoint = Vector2.new(0.5, 0)
	detail.Position = UDim2.fromScale(0.5, 0.58)
	detail.Font = Kit.TitleFont
	detail.TextColor3 = TICKER_COLOR
	local footer = Kit.label(overlay, "", UDim2.fromScale(0.92, 0.14), 26)
	footer.AnchorPoint = Vector2.new(0.5, 0)
	footer.Position = UDim2.fromScale(0.5, 0.8)
	footer.TextColor3 = Kit.Colors.Text
	overlays[overlay] = { Banner = banner, BannerText = bannerText, Title = title, Detail = detail, Footer = footer }
	return overlay
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

	local index = part:GetAttribute("Index")
	surface.Parent = part
	local channel: Channel = {
		Surface = surface,
		Background = background,
		Headline = headline,
		Dot = dot,
		TickerFrame = tickerFrame,
		Ticker = ticker,
		Offset = 0,
		Overlay = if part:HasTag(VOTE_TAG) then buildOverlay(background) else nil,
		Index = if type(index) == "number" then index else 0,
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

local function fightersLeft(): number
	local count = 0
	for _, other in Players:GetPlayers() do
		local status = other:GetAttribute("RoundStatus")
		if status == "Playing" or status == "Respawning" then
			count += 1
		end
	end
	return count
end

local function timeLeft(): string
	local endsAt = Workspace:GetAttribute("RoundEndsAt")
	return HudFormat.clock(if type(endsAt) == "number" then endsAt - Workspace:GetServerTimeNow() else 0)
end

-- What each big TV shows now: one map of the ballot while voting, the live match on the middle one during a round,
-- otherwise nothing over the news.
local function refreshOverlays()
	local state = Workspace:GetAttribute("RoundState")
	if lastState == "Voting" and state ~= "Voting" then
		ballot, votes = {}, {} -- the vote is over (a new one sends a new ballot; it may arrive before the state)
	end
	lastState = state
	for _, channel in channels do
		local frame = channel.Overlay
		local overlay = frame and overlays[frame]
		if not frame or not overlay then
			continue
		end
		local mapId = if state == "Voting" then ballot[channel.Index] else nil
		local liveMap = Workspace:GetAttribute("RoundMap")
		if mapId then
			local count = votes[mapId] or 0
			overlay.Banner.BackgroundColor3 = VOTE_COLOR
			overlay.BannerText.Text = Localization.format("TV.Vote")
			overlay.Title.Text = Localization.format(`Map.{mapId}.Name`)
			overlay.Detail.Text = if count == 1
				then Localization.format("TV.OneVote")
				else Localization.format("TV.Votes", { count })
			overlay.Footer.Text = Localization.format("TV.VoteHint", { timeLeft() })
			frame.Visible = true
		elseif state == "Playing" and channel.Index == LIVE_TV and type(liveMap) == "string" then
			local args: { any } = { timeLeft(), fightersLeft() }
			overlay.Banner.BackgroundColor3 = BANNER_COLOR
			overlay.BannerText.Text = Localization.format("TV.Live")
			overlay.Title.Text = Localization.format(`Map.{liveMap}.Name`)
			overlay.Detail.Text = Localization.format("InProgress.Info", args)
			overlay.Footer.Text = Localization.format("TV.Watch")
			frame.Visible = true
		else
			frame.Visible = false
		end
	end
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
	Net.on("VoteState", function(mapIds: { string }, _modeIds: { string }, mapCounts: { [string]: number })
		ballot, votes = mapIds, mapCounts
		refreshOverlays()
	end)
	for _, tag in SCREEN_TAGS do
		for _, part in CollectionService:GetTagged(tag) do
			build(part)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(build)
	end
	nextStory()

	local storyTime, dayCheck, overlayTime = 0, 0, 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		if fighting() then
			return
		end
		storyTime += deltaTime
		overlayTime += deltaTime
		if overlayTime >= OVERLAY_REFRESH then
			overlayTime = 0
			refreshOverlays()
		end
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
				if channel.Overlay then
					overlays[channel.Overlay] = nil
				end
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
