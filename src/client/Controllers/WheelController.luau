--!strict
--[[
	WheelController — the lobby spin wheel (owner's fix list, 2026-10-19; Shared/WheelRules, Config.Retention.Wheel).
	  * The screen (no menu button: the wheel on the west wall opens it, and it is the third tab next to Daily reward
	    and Quests): every prize with its colour and exact chance — shown before any spin, as Roblox asks for paid
	    random items — the Spin button (free once a day, then Wheel.SpinPrice Coins where the player's policy allows
	    paid random items), when the free spin comes back, and what the last spin won. A spin runs a highlight down the
	    prize list that slows and lands on the server's answer. It sits on the right, so the wheel stays in view.
	  * The wheel in the lobby (SpinWheel tag): its slices are painted in the prize colours, and every spin anyone makes
	    (WheelSpun) turns its Rotor a few times round to land that prize under the pointer, on every client.
]]
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))
local StyleRules = require(Shared:WaitForChild("StyleRules"))
local WheelRules = require(Shared:WaitForChild("WheelRules"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local Wheel = Config.Retention.Wheel
local MENU_ORDER = 7 -- no button; next to Daily reward (6) and Quests (5), whose tab row it shares
local TICK_INTERVAL = 1
local WHEEL_TAG = "SpinWheel"
local SPIN_TIME = 4 -- seconds the lobby wheel turns
local SPIN_TURNS = 4 -- full turns before it lands
local HIGHLIGHT_TIME = 1.8 -- seconds the highlight runs down the list at least
local HIGHLIGHT_START = 0.05 -- seconds per row at the start, slowing to...
local HIGHLIGHT_END = 0.25 -- ...this at the end

type Row = { Frame: Frame, Name: TextLabel, Percent: TextLabel }
type Rotor = { Center: CFrame, Parts: { [BasePart]: CFrame }, Angle: number, From: number, To: number, Started: number }

local WheelController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local rows: { Row } = {}
local spinButton: TextButton
local freeLabel: TextLabel
local resultLabel: TextLabel
local noteLabel: TextLabel
local spinning = false
local rotors: { [Model]: Rotor } = {}

local function prizeName(prize: any): string
	if prize.Kind == "Coins" then
		return Localization.format("Currency.Scrap", { HudFormat.thousands(prize.Amount) })
	elseif prize.Kind == "XP" then
		return Localization.format("Wheel.XP", { HudFormat.thousands(prize.Amount) })
	elseif prize.Kind == "StyleSpin" then
		return Localization.format("Wheel.StyleSpin")
	end
	return Localization.format("Wheel.Cosmetic")
end

local function paidAllowed(): boolean
	return player:GetAttribute("PolicyPaidRandomItems") == true
end

local function allowed(): boolean
	return Workspace:GetAttribute("PrivateServer") ~= true or Config.Economy.PrivateServerRewardScale > 0
end

local function today(): number
	return WheelRules.dayAt(Workspace:GetServerTimeNow())
end

local function spinKind(wheel: { FreeDay: number }): string
	return if WheelRules.freeSpinReady(wheel, today()) then "Free" else "Paid"
end

local function highlight(index: number?)
	for rowIndex, row in rows do
		local on = rowIndex == index
		row.Frame.BackgroundColor3 = if on then Kit.Colors.Accent else Kit.Colors.Button
		row.Frame.BackgroundTransparency = if on then 0 else 0.35
	end
end

local function render()
	local data = DataController.get()
	if data == nil or spinning then
		return
	end
	local wheel = data.Wheel
	local kind = spinKind(wheel)
	local reason = WheelRules.checkSpin(wheel, kind, today(), data.Scrap, {
		Allowed = allowed(),
		Fighting = false,
		PaidAllowed = paidAllowed(),
	})
	spinButton.Text = if kind == "Free"
		then Localization.format("Wheel.SpinFree")
		elseif paidAllowed() then Localization.format("Wheel.SpinPaid", { Wheel.SpinPrice })
		else Localization.format("Wheel.NoSpin")
	spinButton.TextTransparency = if reason == nil then 0 else 0.35
	local resetIn = Formulas.secondsUntilNextDay(Workspace:GetServerTimeNow(), Wheel.FreeSpinResetHourUTC)
	freeLabel.Text = if not allowed()
		then Localization.format("Wheel.Error.PrivateServer")
		elseif WheelRules.freeSpinReady(wheel, today()) then Localization.format("Wheel.FreeReady")
		else Localization.format("Wheel.FreeIn", { HudFormat.longClock(resetIn) })
	noteLabel.Text = if paidAllowed()
		then Localization.format("Wheel.PaidNote", { Wheel.SpinPrice })
		else Localization.format("Wheel.Error.NotAllowed")
end

-- Runs the highlight down the list until `done()` and HIGHLIGHT_TIME has passed, then lands on `final()`.
local function runHighlight(done: () -> boolean, final: () -> number?)
	local started = os.clock()
	local index = 0
	while true do
		local elapsed = os.clock() - started
		if elapsed >= HIGHLIGHT_TIME and done() then
			break
		end
		index = index % #rows + 1
		highlight(index)
		local t = math.clamp(elapsed / HIGHLIGHT_TIME, 0, 1)
		task.wait(HIGHLIGHT_START + (HIGHLIGHT_END - HIGHLIGHT_START) * t * t)
	end
	highlight(final())
end

local function spin()
	local data = DataController.get()
	if spinning or data == nil then
		return
	end
	local kind = spinKind(data.Wheel)
	local reason = WheelRules.checkSpin(data.Wheel, kind, today(), data.Scrap, {
		Allowed = allowed(),
		Fighting = false,
		PaidAllowed = paidAllowed(),
	})
	if reason then
		resultLabel.Text = Localization.format(`Wheel.Error.{reason}`)
		return
	end
	spinning = true
	resultLabel.Text = ""
	spinButton.Text = Localization.format("Wheel.Spinning")
	local answered = false
	local ok: boolean, result: any = false, nil
	task.spawn(function()
		local called, spun, value = pcall(Net.invoke, "SpinWheel", kind)
		ok, result = called and spun == true, if called then value else nil
		answered = true
	end)
	runHighlight(function(): boolean
		return answered
	end, function(): number?
		return if ok and type(result) == "table" then result.Index else nil
	end)
	spinning = false
	if ok and type(result) == "table" then
		local won = if result.Cosmetic
			then Localization.format(`Cosmetic.{result.Cosmetic}.Name`)
			elseif result.Kind == "Coins" then Localization.format(
				"Currency.Scrap",
				{ HudFormat.thousands(result.Amount) }
			)
			else prizeName(Wheel.Prizes[result.Index])
		resultLabel.Text = Localization.format("Wheel.Won", { won })
	else
		local why = if type(result) == "string" and table.find(WheelRules.Reasons, result) then result else "TryAgain"
		resultLabel.Text = Localization.format(`Wheel.Error.{why}`)
	end
	render()
end

local function build()
	gui = Kit.screen("SpinWheel", 8)
	-- On the right, so the wheel on the wall stays in view while it turns.
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.36, 0.84),
		UDim2.fromScale(0.98, 0.5),
		Vector2.new(1, 0.5),
		Vector2.new(500, 640)
	)
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.08)
	header.Parent = panel
	local tabs = Kit.tabRow(header, {
		Localization.format("Daily.Title"),
		Localization.format("Quests.Title"),
		Localization.format("Wheel.Tab"),
	}, UDim2.fromScale(0, 0), UDim2.fromScale(0.78, 0.9), 0.31)
	Kit.setChosen(tabs[3], true)
	tabs[1].Activated:Connect(function()
		MenuController.openNamed("DailyReward")
	end)
	tabs[2].Activated:Connect(function()
		MenuController.openNamed("Quests")
	end)
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.2, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	local title = Kit.label(panel, Localization.format("Wheel.Odds"), UDim2.fromScale(1, 0.05), 20)
	title.Position = UDim2.fromScale(0, 0.1)
	title.Font = Kit.TitleFont
	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0, 0.16)
	list.Size = UDim2.fromScale(1, 0.52)
	list.Parent = panel
	Kit.list(list, Enum.FillDirection.Vertical, UDim.new(0.01, 0))
	local height = 1 / (#Wheel.Prizes + 1)
	for index, prize in Wheel.Prizes do
		local frame = Instance.new("Frame")
		frame.Name = `Prize{index}`
		frame.LayoutOrder = index
		frame.Size = UDim2.fromScale(1, height)
		frame.BackgroundColor3 = Kit.Colors.Button
		frame.BackgroundTransparency = 0.35
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.25, 0)
		corner.Parent = frame
		frame.Parent = list
		local swatch = Instance.new("Frame")
		swatch.BackgroundColor3 = Color3.fromHex(prize.Color)
		swatch.AnchorPoint = Vector2.new(0, 0.5)
		swatch.Position = UDim2.fromScale(0.03, 0.5)
		swatch.Size = UDim2.fromScale(0.1, 0.62)
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = swatch
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = swatch
		swatch.Parent = frame
		local name = Kit.label(frame, prizeName(prize), UDim2.fromScale(0.6, 0.7), 20)
		name.AnchorPoint = Vector2.new(0, 0.5)
		name.Position = UDim2.fromScale(0.13, 0.5)
		name.TextXAlignment = Enum.TextXAlignment.Left
		local percent = Kit.label(
			frame,
			Localization.format("Wheel.Percent", { StyleRules.formatPercent(prize.Percent) }),
			UDim2.fromScale(0.22, 0.7),
			20
		)
		percent.AnchorPoint = Vector2.new(1, 0.5)
		percent.Position = UDim2.fromScale(0.97, 0.5)
		percent.Font = Kit.TitleFont
		percent.TextXAlignment = Enum.TextXAlignment.Right
		rows[index] = { Frame = frame, Name = name, Percent = percent }
	end

	resultLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.06), 22)
	resultLabel.Position = UDim2.fromScale(0, 0.69)
	resultLabel.TextColor3 = Kit.Colors.Accent
	spinButton = Kit.button(panel, "", UDim2.fromScale(0.8, 0.1))
	spinButton.AnchorPoint = Vector2.new(0.5, 0)
	spinButton.Position = UDim2.fromScale(0.5, 0.76)
	Kit.setChosen(spinButton, true)
	spinButton.Activated:Connect(spin)
	freeLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.05), 18)
	freeLabel.Position = UDim2.fromScale(0, 0.87)
	noteLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.06), 15)
	noteLabel.Position = UDim2.fromScale(0, 0.93)
	noteLabel.TextColor3 = Kit.Colors.Muted
end

---------------------------------------------------------------------------------------------------------------------
-- The wheel in the lobby
---------------------------------------------------------------------------------------------------------------------

-- Paints a wheel's slices and remembers where its Rotor's parts sit around the hub (it turns about the hub's X axis).
local function addWheel(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local rotorModel = model:WaitForChild("Rotor", 10)
	local hub = rotorModel and rotorModel:WaitForChild("Hub", 10)
	if not rotorModel or not hub or not hub:IsA("BasePart") then
		return
	end
	local center = hub.CFrame
	local parts: { [BasePart]: CFrame } = {}
	for _, part in rotorModel:GetDescendants() do
		if part:IsA("BasePart") then
			parts[part] = center:ToObjectSpace(part.CFrame)
			local segment = part:GetAttribute("Segment")
			local prize = if type(segment) == "number" then Wheel.Prizes[segment] else nil
			if prize then
				part.Color = Color3.fromHex(prize.Color)
			end
		end
	end
	rotors[model] = { Center = center, Parts = parts, Angle = 0, From = 0, To = 0, Started = -math.huge }
end

-- Every wheel turns a few times round and lands prize `index` under the pointer (slice i sits at (i - 1) / count
-- of a turn from the top, toward +Z; turning by the opposite angle about X brings it back up).
local function onSpun(index: number)
	local slice = (index - 1) / #Wheel.Prizes * 2 * math.pi
	for _, rotor in rotors do
		local now = rotor.Angle
		local landing = now - SPIN_TURNS * 2 * math.pi - ((now + slice) % (2 * math.pi))
		rotor.From, rotor.To, rotor.Started = now, landing, os.clock()
	end
end

local function stepWheels()
	for model, rotor in rotors do
		if model.Parent == nil then
			rotors[model] = nil
			continue
		end
		local t = (os.clock() - rotor.Started) / SPIN_TIME
		if t > 1.05 then
			continue -- standing still
		end
		local eased = 1 - (1 - math.clamp(t, 0, 1)) ^ 3 -- fast start, slow landing
		rotor.Angle = rotor.From + (rotor.To - rotor.From) * eased
		local turned = rotor.Center * CFrame.Angles(rotor.Angle, 0, 0)
		for part, offset in rotor.Parts do
			if part.Parent then
				part.CFrame = turned * offset
			end
		end
	end
end

local function onOpen()
	render()
	if InputController.getDevice() == "Gamepad" then
		GuiService.SelectedObject = spinButton
	end
end

function WheelController.Start(_self: any)
	build()
	MenuController.addScreen(nil, MENU_ORDER, gui, onOpen)
	DataController.Changed:Connect(function(key: string)
		if gui.Enabled and (key == "Wheel" or key == "Scrap") then
			render()
		end
	end)
	Net.on("WheelSpun", function(index: number)
		if type(index) == "number" and Wheel.Prizes[index] then
			onSpun(index)
		end
	end)
	for _, model in CollectionService:GetTagged(WHEEL_TAG) do
		task.spawn(addWheel, model)
	end
	CollectionService:GetInstanceAddedSignal(WHEEL_TAG):Connect(function(model: Instance)
		task.spawn(addWheel, model)
	end)
	local elapsed = 0
	RunService.RenderStepped:Connect(function(deltaTime: number)
		stepWheels()
		elapsed += deltaTime
		if elapsed >= TICK_INTERVAL and gui.Enabled then
			elapsed = 0
			render() -- the free-spin countdown
		end
	end)
end

return WheelController
