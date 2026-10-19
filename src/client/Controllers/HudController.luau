--!strict
--[[
	HudController — the in-game HUD (bible §5.1), the same layout on mobile, PC and gamepad:
	  * Top bar: before a round, how the lobby join pad stands ("Step on the ARENA pad to play (1/2)", "You're in!
	    ..."; during the vote only for players off the pad); during a round the mode badge, time left, and fighters
	    left (Classic) or your score (Casual; players in the lobby see how many are fighting), with a line under it
	    for players in the lobby (join now / next round). Hidden while the results panel is up.
	  * Kill feed (top right): who KO'd whom, newest first, each line fades after FEED_LIFETIME.
	  * Bottom bar: the dash cooldown ring (touch only: keyboard and gamepad see the bottom-right action panel), your
	    vitals while in a round (Classic: HP bar + lives; Casual: Percent in white → yellow → red), and the held prop
	    with Throw / Drop key hints. Above it, the stamina bar (orange when there is too little left for a dash).
	Key hints follow the input device (KeyHint). Hidden while spectating (the spectate bar takes the bottom).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local KeyHint = require(Client:WaitForChild("Ui"):WaitForChild("KeyHint"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local DashController = require(script.Parent:WaitForChild("DashController"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local REFRESH_INTERVAL = 0.1
local FEED_LIFETIME = 6
local FEED_MAX = 5
local HP_COLOR = Color3.fromHex("#6CCB5F")
local HP_LOW_COLOR = Color3.fromHex("#E2463A")
local EMPTY_COLOR = Color3.fromHex("#2A2420")
local STAMINA_COLOR = Color3.fromHex("#F2C14E")
local STAMINA_LOW_COLOR = Color3.fromHex("#E8742A") -- not enough left for a dash

local HudController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local top = {} :: {
	Panel: Frame,
	Waiting: TextLabel,
	Round: Frame,
	Mode: TextLabel,
	Timer: TextLabel,
	Info: TextLabel,
	Hint: TextLabel,
}
local feed: Frame
local feedCount = 0
local bottom: Frame
local dash = {} :: { Ring: Frame, Fill: UIGradient }
local stamina = {} :: { Bar: Frame, Fill: Frame }
local vitals = {} :: {
	Frame: Frame,
	Classic: Frame,
	HpFill: Frame,
	HpLabel: TextLabel,
	Lives: { Frame },
	Percent: TextLabel,
}
local held = {} :: { Frame: Frame, Name: TextLabel, Hints: Frame, Prompt: Frame }

local function rgb(color: HudFormat.Rgb): Color3
	return Color3.new(color.R, color.G, color.B)
end

local function modeHasLives(modeId: unknown): boolean
	local mode = if type(modeId) == "string" then Config.Modes.List[modeId] else nil
	return mode ~= nil and mode.Lives ~= nil
end

---------------------------------------------------------------------------------------------------------------------
-- Building
---------------------------------------------------------------------------------------------------------------------

local function buildTop()
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.4, 0.075),
		UDim2.fromScale(0.5, 0.015),
		Vector2.new(0.5, 0),
		Vector2.new(520, 52)
	)
	top.Panel = panel
	top.Waiting = Kit.label(panel, "", UDim2.fromScale(1, 1), 22)

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = panel
	Kit.list(row, Enum.FillDirection.Horizontal, UDim.new(0.02, 0))
	top.Round = row

	local mode = Kit.label(row, "", UDim2.fromScale(0.34, 1), 20)
	mode.Font = Kit.TitleFont
	mode.BackgroundColor3 = Kit.Colors.Accent
	mode.BackgroundTransparency = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = mode
	mode.LayoutOrder = 1
	top.Mode = mode

	local timer = Kit.label(row, "", UDim2.fromScale(0.26, 1), 24)
	timer.Font = Kit.TitleFont
	timer.LayoutOrder = 2
	top.Timer = timer

	local info = Kit.label(row, "", UDim2.fromScale(0.34, 1), 20)
	info.LayoutOrder = 3
	top.Info = info

	-- Under the top bar during a round, for players in the lobby: how the join pad works right now.
	local hint = Kit.label(gui, "", UDim2.fromScale(0.4, 0.035), 18)
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.fromScale(0.5, 0.1)
	hint.TextColor3 = Kit.Colors.Accent
	hint.TextStrokeTransparency = 0.3
	hint.Visible = false
	top.Hint = hint
end

local function buildFeed()
	feed = Instance.new("Frame")
	feed.Name = "KillFeed"
	feed.BackgroundTransparency = 1
	feed.AnchorPoint = Vector2.new(1, 0)
	feed.Position = UDim2.fromScale(0.985, 0.12)
	feed.Size = UDim2.fromScale(0.3, 0.3)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(360, 220)
	limit.Parent = feed
	local layout = Kit.list(feed, Enum.FillDirection.Vertical, UDim.new(0.02, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	feed.Parent = gui
end

local function buildDash(parent: Frame)
	local ring = Instance.new("Frame")
	ring.Name = "DashRing"
	ring.Size = UDim2.fromScale(0.16, 1)
	ring.BackgroundColor3 = Kit.Colors.Accent
	ring.LayoutOrder = 1
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = ring
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	local outline = Instance.new("UIStroke")
	outline.Color = Kit.Colors.Text
	outline.Thickness = 2
	outline.Parent = ring
	-- Fills from the bottom as the cooldown runs out.
	local fill = Instance.new("UIGradient")
	fill.Rotation = -90
	fill.Parent = ring
	local hint = KeyHint.new(ring, "Dash", UDim2.fromScale(0.6, 0.6))
	hint.AnchorPoint = Vector2.new(0.5, 0.5)
	hint.Position = UDim2.fromScale(0.5, 0.5)
	hint.BackgroundTransparency = 1
	ring.Parent = parent
	dash.Ring = ring
	dash.Fill = fill
end

local function buildVitals(parent: Frame)
	local frame = Instance.new("Frame")
	frame.Name = "Vitals"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(0.48, 1)
	frame.LayoutOrder = 2
	frame.Parent = parent
	vitals.Frame = frame

	-- Classic: HP bar with the number on it, lives as pips underneath.
	local classic = Instance.new("Frame")
	classic.BackgroundTransparency = 1
	classic.Size = UDim2.fromScale(1, 1)
	classic.Parent = frame
	vitals.Classic = classic
	local bar = Instance.new("Frame")
	bar.Name = "HpBar"
	bar.BackgroundColor3 = EMPTY_COLOR
	bar.Size = UDim2.fromScale(1, 0.55)
	bar.Parent = classic
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.3, 0)
	barCorner.Parent = bar
	local hpFill = Instance.new("Frame")
	hpFill.BackgroundColor3 = HP_COLOR
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.Parent = bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.3, 0)
	fillCorner.Parent = hpFill
	vitals.HpFill = hpFill
	local hpLabel = Kit.label(bar, "", UDim2.fromScale(1, 1), 22)
	hpLabel.Font = Kit.TitleFont
	hpLabel.TextStrokeTransparency = 0.4
	hpLabel.ZIndex = 2
	vitals.HpLabel = hpLabel

	local pips = Instance.new("Frame")
	pips.BackgroundTransparency = 1
	pips.Position = UDim2.fromScale(0, 0.65)
	pips.Size = UDim2.fromScale(1, 0.35)
	pips.Parent = classic
	Kit.list(pips, Enum.FillDirection.Horizontal, UDim.new(0.02, 0))
	vitals.Lives = {}
	for index = 1, Config.Modes.List.Classic.Lives or 0 do
		local pip = Instance.new("Frame")
		pip.Size = UDim2.fromScale(1, 1)
		pip.BackgroundColor3 = Kit.Colors.Accent
		pip.LayoutOrder = index
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.Parent = pip
		local pipCorner = Instance.new("UICorner")
		pipCorner.CornerRadius = UDim.new(0.5, 0)
		pipCorner.Parent = pip
		pip.Parent = pips
		table.insert(vitals.Lives, pip)
	end

	-- Casual: the Percent, big.
	local percent = Kit.label(frame, "", UDim2.fromScale(1, 1), 48)
	percent.Font = Kit.TitleFont
	percent.TextStrokeTransparency = 0.3
	vitals.Percent = percent
end

local function buildHeld(parent: Frame)
	local frame = Instance.new("Frame")
	frame.Name = "HeldProp"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(0.32, 1)
	frame.LayoutOrder = 3
	frame.Parent = parent
	held.Frame = frame
	local name = Kit.label(frame, "", UDim2.fromScale(1, 0.45), 20)
	name.Font = Kit.TitleFont
	held.Name = name

	local hints = Instance.new("Frame")
	hints.BackgroundTransparency = 1
	hints.Position = UDim2.fromScale(0, 0.52)
	hints.Size = UDim2.fromScale(1, 0.45)
	hints.Parent = frame
	Kit.list(hints, Enum.FillDirection.Horizontal, UDim.new(0.03, 0))
	for order, pair in { { "Attack", "Controls.Throw" }, { "Grab", "Controls.Drop" } } do
		local hint = KeyHint.new(hints, pair[1], UDim2.fromScale(0.24, 1))
		hint.LayoutOrder = order * 2 - 1
		local label = Kit.label(hints, Localization.format(pair[2]), UDim2.fromScale(0.24, 1), 16)
		label.LayoutOrder = order * 2
	end
	held.Hints = hints

	-- Not holding anything, but a free prop is in reach: "[E] Grab".
	local prompt = Instance.new("Frame")
	prompt.Name = "GrabPrompt"
	prompt.BackgroundTransparency = 1
	prompt.Position = UDim2.fromScale(0, 0.52)
	prompt.Size = UDim2.fromScale(1, 0.45)
	prompt.Parent = frame
	Kit.list(prompt, Enum.FillDirection.Horizontal, UDim.new(0.03, 0))
	local hint = KeyHint.new(prompt, "Grab", UDim2.fromScale(0.24, 1))
	hint.LayoutOrder = 1
	local label = Kit.label(prompt, Localization.format("Controls.Grab"), UDim2.fromScale(0.4, 1), 16)
	label.LayoutOrder = 2
	held.Prompt = prompt
end

-- The free prop (not held by anyone) closest to the local character within grab reach, if any.
local function propInReach(root: BasePart): BasePart?
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, instance in CollectionService:GetTagged("Prop") do
		if instance:IsA("BasePart") and instance:GetAttribute("Held") == nil and instance:IsDescendantOf(Workspace) then
			local size = instance.Size
			local distance = (instance.Position - root.Position).Magnitude
			local reach = Config.Props.GrabRange + math.max(size.X, size.Y, size.Z) / 2
			if distance <= reach and distance < bestDistance then
				best, bestDistance = instance, distance
			end
		end
	end
	return best
end

local function buildBottom()
	bottom = Instance.new("Frame")
	bottom.Name = "Bottom"
	bottom.BackgroundTransparency = 1
	bottom.AnchorPoint = Vector2.new(0.5, 1)
	bottom.Position = UDim2.fromScale(0.5, 0.975)
	bottom.Size = UDim2.fromScale(0.46, 0.1)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(620, 80)
	limit.Parent = bottom
	Kit.list(bottom, Enum.FillDirection.Horizontal, UDim.new(0.03, 0))
	bottom.Parent = gui
	buildDash(bottom)
	buildVitals(bottom)
	buildHeld(bottom)

	-- Stamina: a thin bar just above the bottom bar (running and dashing use it).
	local bar = Instance.new("Frame")
	bar.Name = "Stamina"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.fromScale(0.5, 0.865)
	bar.Size = UDim2.fromScale(0.3, 0.012)
	bar.BackgroundColor3 = EMPTY_COLOR
	bar.BackgroundTransparency = 0.2
	local barLimit = Instance.new("UISizeConstraint")
	barLimit.MaxSize = Vector2.new(420, 10)
	barLimit.MinSize = Vector2.new(120, 6)
	barLimit.Parent = bar
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.5, 0)
	barCorner.Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = STAMINA_COLOR
	fill.Size = UDim2.fromScale(1, 1)
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill
	fill.Parent = bar
	bar.Parent = gui
	stamina.Bar = bar
	stamina.Fill = fill
end

---------------------------------------------------------------------------------------------------------------------
-- Updating
---------------------------------------------------------------------------------------------------------------------

local function fighterCount(): number
	local count = 0
	for _, other in Players:GetPlayers() do
		local lives = other:GetAttribute("Lives")
		if type(lives) == "number" and lives > 0 then
			count += 1
		end
	end
	return count
end

local function attribute(instance: Instance, name: string): string?
	local value = instance:GetAttribute(name)
	return if type(value) == "string" then value else nil
end

local function number(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

-- Players fighting in the running round.
local function inRoundCount(): number
	local count = 0
	for _, other in Players:GetPlayers() do
		local status = other:GetAttribute("RoundStatus")
		if status == "Playing" or status == "Respawning" then
			count += 1
		end
	end
	return count
end

local function refreshTop()
	local state = attribute(Workspace, "RoundState")
	local status = attribute(player, "RoundStatus")
	local modeId = attribute(Workspace, "RoundMode")
	local mode = if modeId then Config.Modes.List[modeId] else nil
	local queueKey =
		HudFormat.queueKey(state, status, attribute(player, "QueueStatus"), mode ~= nil and mode.JoinMidRound)
	top.Panel.Visible = state == "Waiting" or state == "Playing" or (state == "Voting" and queueKey ~= nil)
	top.Waiting.Visible = state ~= "Playing"
	top.Round.Visible = state == "Playing"
	top.Hint.Visible = state == "Playing" and queueKey ~= nil
	local endsAt = Workspace:GetAttribute("RoundEndsAt")
	local left = if type(endsAt) == "number" then endsAt - Workspace:GetServerTimeNow() else 0
	if state == "Waiting" and queueKey then
		local needed = Workspace:GetAttribute("PlayersNeeded")
		top.Waiting.Text = Localization.format(queueKey, { number(Workspace, "PlayersQueued"), needed or 2 })
	elseif state == "Voting" and queueKey then
		top.Waiting.Text = Localization.format(queueKey, { math.max(math.ceil(left), 0) })
	elseif state == "Playing" then
		top.Mode.Text = if modeId then Localization.format(`Mode.{modeId}.Name`) else ""
		top.Timer.Text = HudFormat.clock(left)
		if queueKey then
			top.Hint.Text = Localization.format(queueKey)
		end
		if modeHasLives(modeId) then
			top.Info.Text = Localization.format("Hud.Left", { fighterCount() })
		elseif status == "Lobby" then
			top.Info.Text = Localization.format("Hud.Fighting", { inRoundCount() })
		else
			local kos, falls = player:GetAttribute("KOs"), player:GetAttribute("Falls")
			local score = (if type(kos) == "number" then kos else 0) - (if type(falls) == "number" then falls else 0)
			top.Info.Text = Localization.format("Hud.Score", { score })
		end
	end
end

local function refreshBottom()
	local status = player:GetAttribute("RoundStatus")
	bottom.Visible = status ~= "Spectating"
	-- With keyboard or gamepad the bottom-right action panel shows the dash; touch players keep the ring here.
	dash.Ring.Visible = InputController.getDevice() == "Touch"

	local staminaLeft = if player.Character then player.Character:GetAttribute("Stamina") else nil
	local staminaConfig = Config.Combat.Stamina
	stamina.Bar.Visible = bottom.Visible and type(staminaLeft) == "number"
	if type(staminaLeft) == "number" then
		stamina.Fill.Size = UDim2.fromScale(math.clamp(staminaLeft / staminaConfig.Max, 0, 1), 1)
		stamina.Fill.BackgroundColor3 = if staminaLeft < staminaConfig.DashCost
			then STAMINA_LOW_COLOR
			else STAMINA_COLOR
		stamina.Bar.BackgroundTransparency = if staminaLeft >= staminaConfig.Max then 0.5 else 0.2
	end

	local fill = HudFormat.dashFill(DashController.cooldownLeft(), Config.Combat.Dash.Cooldown)
	if fill >= 1 then
		dash.Fill.Transparency = NumberSequence.new(0)
	elseif fill <= 0 then
		dash.Fill.Transparency = NumberSequence.new(0.75)
	else
		dash.Fill.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(fill, 0),
			NumberSequenceKeypoint.new(math.min(fill + 0.001, 1), 0.75),
			NumberSequenceKeypoint.new(1, 0.75),
		})
	end

	local character = player.Character
	local inRound = status == "Playing" or status == "Respawning"
	vitals.Frame.Visible = inRound
	if inRound then
		local hp = character and character:GetAttribute("HP")
		local percent = character and character:GetAttribute("Percent")
		local classic = type(hp) == "number"
		vitals.Classic.Visible = classic
		vitals.Percent.Visible = not classic
		if type(hp) == "number" then
			local maxHealth = Config.Modes.List.Classic.MaxHealth or 100
			local share = math.clamp(hp / maxHealth, 0, 1)
			vitals.HpFill.Size = UDim2.fromScale(share, 1)
			vitals.HpFill.BackgroundColor3 = HP_LOW_COLOR:Lerp(HP_COLOR, share)
			vitals.HpLabel.Text = Localization.format("Combat.HP", { math.ceil(hp) })
			local lives = player:GetAttribute("Lives")
			for index, pip in vitals.Lives do
				pip.BackgroundTransparency = if type(lives) == "number" and index <= lives then 0 else 0.75
			end
		else
			local value = if type(percent) == "number" then percent else 0
			vitals.Percent.Text = Localization.format("Combat.Percent", { math.floor(value + 0.5) })
			vitals.Percent.TextColor3 = rgb(HudFormat.percentColor(value))
		end
	end

	local heldType = character and character:GetAttribute("HeldProp")
	local holding = type(heldType) == "string"
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local nearby = if not holding and root and root:IsA("BasePart") then propInReach(root) else nil
	held.Frame.Visible = holding or nearby ~= nil
	held.Hints.Visible = holding
	held.Prompt.Visible = not holding and nearby ~= nil
	if type(heldType) == "string" then
		held.Name.Text = Localization.format(`Prop.{heldType}.Name`)
	elseif nearby then
		local typeId = nearby:GetAttribute("PropType")
		held.Name.Text = if type(typeId) == "string" then Localization.format(`Prop.{typeId}.Name`) else ""
	end
end

local function addFeedLine(killerName: string?, victimName: string, weapon: string?)
	local text
	if killerName == nil then
		text = Localization.format("Feed.SelfKO", { victimName })
	elseif weapon and Config.Props.Types[weapon] then
		local args: { any } = { killerName, victimName, Localization.format(`Prop.{weapon}.Name`) }
		text = Localization.format("Feed.KOWith", args)
	else
		text = Localization.format("Feed.KO", { killerName, victimName })
	end
	feedCount += 1
	local label = Kit.label(feed, text, UDim2.fromScale(1, 0.18), 18)
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.TextStrokeTransparency = 0.4
	label.LayoutOrder = -feedCount -- newest on top
	local lines = {}
	for _, child in feed:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(lines, child)
		end
	end
	table.sort(lines, function(a: TextLabel, b: TextLabel): boolean
		return a.LayoutOrder < b.LayoutOrder
	end)
	for index = FEED_MAX + 1, #lines do
		lines[index]:Destroy()
	end
	task.delay(FEED_LIFETIME, function()
		label:Destroy()
	end)
end

function HudController.Start(_self: any)
	gui = Kit.screen("Hud", 2)
	gui.Enabled = true
	buildTop()
	buildFeed()
	buildBottom()
	Net.on("KillFeed", addFeedLine)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refreshTop()
			refreshBottom()
		end
	end)
end

return HudController
