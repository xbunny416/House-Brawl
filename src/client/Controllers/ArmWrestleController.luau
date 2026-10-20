--!strict
--[[
	ArmWrestleController — the lobby's arm-wrestling table on screen (ArmWrestleService runs the matches; this only
	draws the table's attributes and sends presses).
	  * Over every table, for everyone in the lobby: a board with ARM WRESTLING, who is wrestling, a tug bar (side 1's
	    colour from the left, side 2's from the right), the countdown / time left / winner, and the table champion.
	  * For the two wrestlers, a panel at the bottom: "You" against the other, the bar from their own side (their colour
	    grows as they win), the countdown, "PUSH!" with the Attack key (gamepad glyph) — or a big PUSH button on touch —
	    and the result. Each press of Attack (or the button) during the pull sends ArmWrestleTap; the server decides
	    what counts (Config.World.ArmWrestle.TapRate).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArmWrestleRules = require(Shared:WaitForChild("ArmWrestleRules"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent.Parent
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local KeyHint = require(Client:WaitForChild("Ui"):WaitForChild("KeyHint"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local TABLE_TAG = "ArmWrestleTable"
local SEAT_TAG = "ArmWrestleSeat"
local REFRESH_INTERVAL = 0.1
local BOARD_HEIGHT = 6 -- studs above the table top
local BOARD_DISTANCE = 70 -- studs the board shows from
local SIDE_COLORS = { Kit.Colors.Accent, Kit.Colors.Rival } -- side 1, side 2 (the panel shows you in your side's colour)
local PULSE = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

type Bar = { Frame: Frame, Fill: Frame }
type Board = { Gui: BillboardGui, Title: TextLabel, Status: TextLabel, Bar: Bar, Champion: TextLabel }

local ArmWrestleController = {}

local player = Players.LocalPlayer
local boards: { [Model]: Board } = {}

local panelGui: ScreenGui
local panel: Frame
local youLabel: TextLabel
local otherLabel: TextLabel
local panelBar: Bar
local bigLabel: TextLabel
local hintRow: Frame
local pushButton: TextButton
local barScale: UIScale

local function numberAttribute(model: Instance, name: string): number
	local value = model:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

-- The name to show for a side's UserId.
local function nameOf(userId: number): string
	if userId == ArmWrestleRules.Bot then
		return Localization.format("ArmWrestle.Bot")
	end
	local other = if userId > 0 then Players:GetPlayerByUserId(userId) else nil
	return if other then other.DisplayName else Localization.format("ArmWrestle.Someone")
end

local function secondsLeft(model: Instance): number
	return math.max(0, math.ceil(numberAttribute(model, "EndsAt") - Workspace:GetServerTimeNow()))
end

local function newBar(parent: Instance, size: UDim2, position: UDim2): Bar
	local frame = Instance.new("Frame")
	frame.Name = "Bar"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = SIDE_COLORS[2]
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0.5, 1)
	fill.BackgroundColor3 = SIDE_COLORS[1]
	fill.BorderSizePixel = 0
	fill.Parent = frame
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill
	-- The middle mark: where the hands started.
	local middle = Instance.new("Frame")
	middle.Name = "Middle"
	middle.AnchorPoint = Vector2.new(0.5, 0.5)
	middle.Position = UDim2.fromScale(0.5, 0.5)
	middle.Size = UDim2.new(0, 2, 1.4, 0)
	middle.BackgroundColor3 = Kit.Colors.Text
	middle.BorderSizePixel = 0
	middle.ZIndex = 2
	middle.Parent = frame
	frame.Parent = parent
	return { Frame = frame, Fill = fill }
end

-- `share` = how much of the bar the left colour fills (0 … 1).
local function setBar(bar: Bar, share: number, left: Color3, right: Color3)
	bar.Fill.Size = UDim2.fromScale(math.clamp(share, 0, 1), 1)
	bar.Fill.BackgroundColor3 = left
	bar.Frame.BackgroundColor3 = right
end

---------------------------------------------------------------------------------------------------------------------
-- The board over each table
---------------------------------------------------------------------------------------------------------------------

local function buildBoard(): Board
	local gui = Instance.new("BillboardGui")
	gui.Name = "ArmWrestleBoard"
	gui.Size = UDim2.fromOffset(280, 120)
	gui.LightInfluence = 0
	gui.MaxDistance = BOARD_DISTANCE
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Kit.Colors.Panel
	back.BackgroundTransparency = 0.15
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = back
	local outline = Instance.new("UIStroke")
	outline.Color = Kit.Colors.Gold
	outline.Thickness = 2
	outline.Parent = back

	local title = Kit.label(back, Localization.format("ArmWrestle.Title"), UDim2.fromScale(1, 0.24), 20)
	title.Font = Kit.TitleFont
	title.TextColor3 = Kit.Colors.Gold
	title.Position = UDim2.fromScale(0, 0.04)
	local status = Kit.label(back, "", UDim2.fromScale(0.92, 0.26), 18)
	status.Position = UDim2.fromScale(0.04, 0.3)
	local bar = newBar(back, UDim2.fromScale(0.84, 0.1), UDim2.fromScale(0.5, 0.6))
	local champion = Kit.label(back, "", UDim2.fromScale(0.92, 0.18), 14)
	champion.Position = UDim2.fromScale(0.04, 0.76)
	champion.TextColor3 = Kit.Colors.Muted
	gui.Parent = player:WaitForChild("PlayerGui")
	return { Gui = gui, Title = title, Status = status, Bar = bar, Champion = champion }
end

local function refreshBoard(model: Model, board: Board)
	local top = model:FindFirstChild("Top")
	if top and top:IsA("BasePart") and board.Gui.Adornee ~= top then
		board.Gui.Adornee = top
	end
	board.Gui.StudsOffsetWorldSpace = Vector3.new(0, BOARD_HEIGHT, 0)
	local state = model:GetAttribute("State")
	local one, two = numberAttribute(model, "Player1"), numberAttribute(model, "Player2")
	local progress = numberAttribute(model, "Progress")
	local status: string
	if state == "Countdown" then
		status = Localization.format("ArmWrestle.Versus", { nameOf(one), nameOf(two) })
	elseif state == "Pulling" then
		local args: { any } = { nameOf(one), nameOf(two), secondsLeft(model) }
		status = Localization.format("ArmWrestle.VersusTime", args)
	elseif state == "Result" then
		local winner = numberAttribute(model, "Winner")
		status = if winner == 0
			then Localization.format("ArmWrestle.Draw")
			else Localization.format("ArmWrestle.Wins", { nameOf(if winner == 1 then one else two) })
	elseif one ~= 0 or two ~= 0 then
		status = Localization.format("ArmWrestle.WaitingFor", { nameOf(if one ~= 0 then one else two) })
	else
		status = Localization.format("ArmWrestle.Empty")
	end
	board.Status.Text = status
	board.Bar.Frame.Visible = state == "Countdown" or state == "Pulling" or state == "Result"
	setBar(board.Bar, (1 + progress) / 2, SIDE_COLORS[1], SIDE_COLORS[2])
	local champion, streak = numberAttribute(model, "Champion"), numberAttribute(model, "Streak")
	board.Champion.Text = if champion ~= 0
		then Localization.format("ArmWrestle.Champion", { nameOf(champion), streak } :: { any })
		else ""
end

-- A table left this client (destroyed, or the lobby streamed out while in a round): drop its board.
local function removeTable(instance: Instance)
	local board = boards[instance :: Model]
	if board then
		board.Gui:Destroy()
		boards[instance :: Model] = nil
	end
end

local function addTable(instance: Instance)
	if instance:IsA("Model") and boards[instance] == nil then
		boards[instance] = buildBoard()
		instance.Destroying:Connect(function()
			removeTable(instance)
		end)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- The wrestler's panel
---------------------------------------------------------------------------------------------------------------------

-- The table the local player sits at and their side, if any.
local function myTable(): (Model?, number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat == nil or not seat:HasTag(SEAT_TAG) then
		return nil, 0
	end
	local node: Instance? = seat.Parent
	while node and not node:HasTag(TABLE_TAG) do
		node = node.Parent
	end
	local side = seat:GetAttribute("Side")
	if node == nil or not node:IsA("Model") or (side ~= 1 and side ~= 2) then
		return nil, 0
	end
	return node, side :: number
end

local function buildPanel()
	panelGui = Kit.screen("ArmWrestle", 6)
	panel = Kit.panel(
		panelGui,
		UDim2.fromScale(0.46, 0.24),
		UDim2.fromScale(0.5, 0.84),
		Vector2.new(0.5, 1),
		Vector2.new(520, 190)
	)
	youLabel = Kit.label(panel, Localization.format("ArmWrestle.You"), UDim2.fromScale(0.42, 0.18), 20)
	youLabel.TextXAlignment = Enum.TextXAlignment.Left
	otherLabel = Kit.label(panel, "", UDim2.fromScale(0.42, 0.18), 20)
	otherLabel.Position = UDim2.fromScale(0.58, 0)
	otherLabel.TextXAlignment = Enum.TextXAlignment.Right
	panelBar = newBar(panel, UDim2.fromScale(1, 0.14), UDim2.fromScale(0.5, 0.24))
	barScale = Instance.new("UIScale")
	barScale.Parent = panelBar.Frame
	bigLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.3), 34)
	bigLabel.Font = Kit.TitleFont
	bigLabel.Position = UDim2.fromScale(0, 0.42)

	-- The key to mash (keyboard / gamepad): the Attack key's box, then "Mash to push".
	hintRow = Instance.new("Frame")
	hintRow.BackgroundTransparency = 1
	hintRow.Position = UDim2.fromScale(0, 0.76)
	hintRow.Size = UDim2.fromScale(1, 0.22)
	hintRow.Parent = panel
	local layout = Kit.list(hintRow, Enum.FillDirection.Horizontal, UDim.new(0, 8))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	local key = KeyHint.new(hintRow, "Attack", UDim2.fromOffset(34, 34))
	key.LayoutOrder = 1
	local mash = Kit.label(hintRow, Localization.format("ArmWrestle.Mash"), UDim2.new(0, 220, 0.8, 0), 18)
	mash.LayoutOrder = 2
	mash.TextXAlignment = Enum.TextXAlignment.Left

	-- Touch: one big button to tap.
	pushButton = Kit.button(panelGui, Localization.format("ArmWrestle.PushButton"), UDim2.fromScale(0.2, 0.2))
	pushButton.AnchorPoint = Vector2.new(1, 1)
	pushButton.Position = UDim2.fromScale(0.97, 0.84)
	pushButton.BackgroundColor3 = Kit.Colors.Accent
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = pushButton
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(96, 96)
	limit.MaxSize = Vector2.new(160, 160)
	limit.Parent = pushButton
end

local function push()
	local model = myTable()
	if model and model:GetAttribute("State") == "Pulling" then
		Net.fire("ArmWrestleTap")
		barScale.Scale = 1.06
		TweenService:Create(barScale, PULSE, { Scale = 1 }):Play()
	end
end

local function refreshPanel()
	local model, side = myTable()
	panelGui.Enabled = model ~= nil
	if model == nil then
		return
	end
	local state = model:GetAttribute("State")
	local mine = ArmWrestleRules.view(numberAttribute(model, "Progress"), side)
	local otherId = numberAttribute(model, if side == 1 then "Player2" else "Player1")
	otherLabel.Text = if otherId ~= 0 then nameOf(otherId) else ""
	youLabel.TextColor3 = SIDE_COLORS[side]
	otherLabel.TextColor3 = SIDE_COLORS[3 - side]
	panelBar.Frame.Visible = state ~= "Waiting"
	setBar(panelBar, (1 + mine) / 2, SIDE_COLORS[side], SIDE_COLORS[3 - side])
	local pulling = state == "Pulling"
	local touch = InputController.getDevice() == "Touch"
	hintRow.Visible = pulling and not touch
	pushButton.Visible = pulling and touch
	if state == "Countdown" then
		bigLabel.Text = tostring(math.max(1, secondsLeft(model))) -- 3, 2, 1 (never 0 before the pull starts)
		bigLabel.TextColor3 = Kit.Colors.Text
	elseif pulling then
		bigLabel.Text = Localization.format("ArmWrestle.Push", { secondsLeft(model) })
		bigLabel.TextColor3 = Kit.Colors.Coin
	elseif state == "Result" then
		local winner = numberAttribute(model, "Winner")
		bigLabel.Text = Localization.format(
			if winner == 0
				then "ArmWrestle.Draw"
				elseif winner == side then "ArmWrestle.YouWin"
				else "ArmWrestle.YouLose"
		)
		bigLabel.TextColor3 = if winner == side then Kit.Colors.Gold else Kit.Colors.Text
	else
		bigLabel.Text = Localization.format("ArmWrestle.WaitingYou")
		bigLabel.TextColor3 = Kit.Colors.Muted
	end
end

function ArmWrestleController.Start(_self: any)
	buildPanel()
	for _, model in CollectionService:GetTagged(TABLE_TAG) do
		addTable(model)
	end
	CollectionService:GetInstanceAddedSignal(TABLE_TAG):Connect(addTable)
	CollectionService:GetInstanceRemovedSignal(TABLE_TAG):Connect(removeTable)

	InputController.ActionBegan:Connect(function(action: string)
		if action == "Attack" then
			push()
		end
	end)
	pushButton.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
			push()
		end
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < REFRESH_INTERVAL then
			return
		end
		elapsed = 0
		for model, board in boards do
			refreshBoard(model, board)
		end
		refreshPanel()
	end)
end

return ArmWrestleController
