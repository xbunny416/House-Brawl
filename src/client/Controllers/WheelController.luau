--!strict
--[[
	WheelController — the lobby spin wheel (owner's fix list, 2026-10-19; Shared/WheelRules, Config.Retention.Wheel).
	No screen since 2026-10-20 (owner: "make spin wheel separated from quests, no click UI, have to walk to spin, make
	prize show in wheel too"): you walk up to the wheel on the west wall and press the big red button in front of it.
	  * Every slice shows its prize and exact chance (a SurfaceGui on the slice's Label part: the amount, what it is,
	    "30%"), so every outcome and its odds are on the wheel before a spin, as Roblox asks for paid random items.
	  * The button's prompt (E / gamepad B / tap; Config.Controls.Prompts) says what a press does: "Free spin" while
	    today's free spin is ready (the button glows), else "Spin · 200 Coins" held for Wheel.PaidHoldTime with when the
	    free spin comes back — or, where the player's policy doesn't allow paid random items, only that countdown. It
	    hides while the wheel turns (one spin at a time; the server checks too), while a menu screen is open or the
	    player is fighting.
	  * Every spin anyone makes (WheelSpun) turns the Rotor on every client so the prize lands under the pointer, and
	    that slice blinks. The spinner gets a notice with what they won when it lands (a refusal says why at once).
]]
local CollectionService = game:GetService("CollectionService")
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
local MenuController = require(script.Parent:WaitForChild("MenuController"))
local NoticeController = require(script.Parent:WaitForChild("NoticeController"))

local Wheel = Config.Retention.Wheel
local WHEEL_TAG = "SpinWheel"
local PROMPT_NAME = "SpinPrompt"
local REFRESH_INTERVAL = 0.25
local SPIN_TURNS = 4 -- full turns before it lands
local BLINK_TIME = 5 -- seconds the winning slice blinks after landing
local BLINK_EVERY = 0.3
local LABEL_PIXELS = 50 -- per stud on the slice labels
local PRESS_DEPTH = 0.15 -- studs the button dips when pressed
local PRESS_TIME = 0.15
-- What each kind of prize is called on its slice (under the amount).
local SLICE_KEYS: { [string]: string } = {
	Coins = "Wheel.Slice.Coins",
	XP = "Wheel.Slice.XP",
	StyleSpin = "Wheel.Slice.StyleSpin",
	Cosmetic = "Wheel.Slice.Cosmetic",
}

type Rotor = {
	Center: CFrame,
	Parts: { [BasePart]: CFrame },
	Slices: { [number]: { BasePart } },
	Angle: number,
	From: number,
	To: number,
	Started: number,
}
type Button = { Part: BasePart, Rest: CFrame, Prompt: ProximityPrompt }
-- The spin the wheel is turning to: its prize, whether it is this player's, and when it lands (os.clock()).
type Landing = { Index: number, Mine: boolean, At: number }

local WheelController = {}

local player = Players.LocalPlayer
local rotors: { [Model]: Rotor } = {}
local buttons: { [Model]: Button } = {}
local landing: Landing? = nil
local busyUntil = 0 -- os.clock(): the wheel turns and shows its prize until then
local asking = false -- waiting for the server's answer to this player's spin
local myResult: any = nil -- this player's last win, told when the wheel lands
local myResultAt = 0

local function paidAllowed(): boolean
	return player:GetAttribute("PolicyPaidRandomItems") == true
end

local function allowed(): boolean
	return Workspace:GetAttribute("PrivateServer") ~= true or Config.Economy.PrivateServerRewardScale > 0
end

local function today(): number
	return WheelRules.dayAt(Workspace:GetServerTimeNow())
end

-- A prize as a notice names it ("250 Coins", "150 XP", "a free style spin", "a random cosmetic").
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

-- What the server says was won (the cosmetic by name; a cosmetic prize may have turned into Coins).
local function wonName(result: any): string
	if type(result.Cosmetic) == "string" then
		return Localization.format(`Cosmetic.{result.Cosmetic}.Name`)
	elseif result.Kind == "Coins" and type(result.Amount) == "number" then
		return Localization.format("Currency.Scrap", { HudFormat.thousands(result.Amount) })
	end
	local prize = Wheel.Prizes[result.Index]
	return if prize then prizeName(prize) else ""
end

---------------------------------------------------------------------------------------------------------------------
-- The wheel: slice colours, prize labels, turning
---------------------------------------------------------------------------------------------------------------------

local function textLine(gui: SurfaceGui, text: string, top: number, height: number, width: number, color: Color3)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, top)
	label.Size = UDim2.fromScale(width, height)
	label.Font = Kit.TitleFont
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.25
	stroke.Parent = label
	label.Parent = gui
end

-- Writes a slice's prize on its Label part, the top toward the rim: the amount ("+1" for a style spin, "?" for the
-- mystery cosmetic), what it is, and its exact chance.
local function writeLabel(part: BasePart, prize: any)
	if part:FindFirstChild("PrizeLabel") then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PrizeLabel"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = LABEL_PIXELS
	gui.LightInfluence = 0
	local amount = if prize.Kind == "Coins" or prize.Kind == "XP"
		then HudFormat.thousands(prize.Amount)
		elseif prize.Kind == "StyleSpin" then `+{prize.Amount}`
		else "?"
	local white = Color3.new(1, 1, 1)
	textLine(gui, amount, 0, 0.36, 0.96, white)
	textLine(gui, Localization.format(SLICE_KEYS[prize.Kind] or "Wheel.Slice.Cosmetic"), 0.38, 0.22, 0.86, white)
	textLine(
		gui,
		Localization.format("Wheel.Percent", { StyleRules.formatPercent(prize.Percent) }),
		0.66,
		0.18,
		0.5,
		Kit.Colors.Gold
	)
	gui.Parent = part
end

-- Paints a wheel's slices, writes their prizes and remembers where its Rotor's parts sit around the hub (it turns
-- about the hub's X axis).
local function addRotor(model: Model)
	local rotorModel = model:WaitForChild("Rotor", 10)
	local hub = rotorModel and rotorModel:WaitForChild("Hub", 10)
	if not rotorModel or not hub or not hub:IsA("BasePart") then
		return
	end
	local center = hub.CFrame
	local parts: { [BasePart]: CFrame } = {}
	local slices: { [number]: { BasePart } } = {}
	for _, part in rotorModel:GetDescendants() do
		if part:IsA("BasePart") then
			parts[part] = center:ToObjectSpace(part.CFrame)
			local segment = part:GetAttribute("Segment")
			local prize = if type(segment) == "number" then Wheel.Prizes[segment] else nil
			if prize and part.Name == "Label" then
				writeLabel(part, prize)
			elseif prize then
				part.Color = Color3.fromHex(prize.Color)
				slices[segment :: number] = slices[segment :: number] or {}
				table.insert(slices[segment :: number], part)
			end
		end
	end
	rotors[model] =
		{ Center = center, Parts = parts, Slices = slices, Angle = 0, From = 0, To = 0, Started = -math.huge }
end

-- Every wheel turns a few times round and lands prize `index` under the pointer (slice i sits at (i - 1) / count
-- of a turn from the top, toward +Z; turning by the opposite angle about X brings it back up).
local function turnTo(index: number)
	local slice = (index - 1) / #Wheel.Prizes * 2 * math.pi
	for _, rotor in rotors do
		local now = rotor.Angle
		local stop = now - SPIN_TURNS * 2 * math.pi - ((now + slice) % (2 * math.pi))
		rotor.From, rotor.To, rotor.Started = now, stop, os.clock()
	end
end

local function stepRotors()
	for model, rotor in rotors do
		if model.Parent == nil then
			rotors[model] = nil
			continue
		end
		local t = (os.clock() - rotor.Started) / Wheel.SpinTime
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

-- Sets the material of prize `index`'s slice on every wheel (Neon while it blinks).
local function lightSlice(index: number, material: Enum.Material)
	for _, rotor in rotors do
		local parts: { BasePart } = rotor.Slices[index] or {}
		for _, part in parts do
			part.Material = material
		end
	end
end

-- After landing: the winning slice blinks, and the spinner hears what they won.
local function stepLanding()
	local now = os.clock()
	if myResult ~= nil then
		local landed = landing ~= nil and landing.Mine and now >= landing.At
		if landed or now > myResultAt + Wheel.SpinTime + 1 then -- (or no WheelSpun came: tell anyway)
			NoticeController.show("Wheel.Won", { wonName(myResult) })
			myResult = nil
		end
	end
	local current = landing
	if current == nil or now < current.At then
		return
	end
	local blinking = now < current.At + BLINK_TIME
	local lit = blinking and math.floor((now - current.At) / BLINK_EVERY) % 2 == 0
	lightSlice(current.Index, if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic)
	if not blinking then
		landing = nil
	end
end

local function onSpun(index: number, userId: unknown)
	local previous = landing
	if previous then -- a new spin before the last one stopped blinking: that slice goes back to plain
		lightSlice(previous.Index, Enum.Material.SmoothPlastic)
	end
	turnTo(index)
	landing = { Index = index, Mine = userId == player.UserId, At = os.clock() + Wheel.SpinTime }
	busyUntil = os.clock() + Wheel.SpinTime + Wheel.NextSpinDelay
end

---------------------------------------------------------------------------------------------------------------------
-- The spin button
---------------------------------------------------------------------------------------------------------------------

local function press()
	for _, button in buttons do
		local part = button.Part
		part.CFrame = button.Rest - Vector3.new(0, PRESS_DEPTH, 0)
		task.delay(PRESS_TIME, function()
			part.CFrame = button.Rest
		end)
	end
end

local function spin()
	local data = DataController.get()
	if data == nil or asking or os.clock() < busyUntil then
		return
	end
	local kind = if WheelRules.freeSpinReady(data.Wheel, today()) then "Free" else "Paid"
	local reason = WheelRules.checkSpin(data.Wheel, kind, today(), data.Scrap, {
		Allowed = allowed(),
		Fighting = MenuController.isFighting(),
		PaidAllowed = paidAllowed(),
	})
	if reason then
		NoticeController.show(`Wheel.Error.{reason}`)
		return
	end
	press()
	asking = true
	task.spawn(function()
		local called, spun, value = pcall(Net.invoke, "SpinWheel", kind)
		asking = false
		if called and spun == true and type(value) == "table" then
			myResult, myResultAt = value, os.clock()
		else
			local why = if called
					and type(value) == "string"
					and table.find(WheelRules.Reasons, value)
				then value
				else "TryAgain"
			NoticeController.show(`Wheel.Error.{why}`)
		end
	end)
end

-- The prompt's texts for this player now: what a press does, and the line over it.
local function promptTexts(): (string, string, number)
	local object = Localization.format("Prompt.Wheel.Object")
	local data = DataController.get()
	if not allowed() or data == nil then
		return Localization.format("Prompt.Wheel"), object, 0
	elseif WheelRules.freeSpinReady(data.Wheel, today()) then
		return Localization.format("Prompt.Wheel.Free"), object, 0
	end
	local resetIn = Formulas.secondsUntilNextDay(Workspace:GetServerTimeNow(), Wheel.FreeSpinResetHourUTC)
	local countdown = Localization.format("Wheel.FreeIn", { HudFormat.longClock(resetIn) })
	if paidAllowed() then
		return Localization.format("Prompt.Wheel.Paid", { Wheel.SpinPrice }), countdown, Wheel.PaidHoldTime
	end
	return countdown, object, 0 -- pressing says the free spin is used
end

local function refresh()
	local shown = not asking
		and os.clock() >= busyUntil
		and not MenuController.isFighting()
		and not MenuController.isOpen()
	local action, object, hold = promptTexts()
	local data = DataController.get()
	local glow = shown and allowed() and data ~= nil and WheelRules.freeSpinReady(data.Wheel, today())
	for model, button in buttons do
		if model.Parent == nil or button.Prompt.Parent == nil then
			buttons[model] = nil
			continue
		end
		local prompt = button.Prompt
		prompt.Enabled = shown
		if prompt.ActionText ~= action then
			prompt.ActionText = action
		end
		if prompt.ObjectText ~= object then
			prompt.ObjectText = object
		end
		prompt.HoldDuration = hold
		button.Part.Material = if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

local function addButton(model: Model)
	local stand = model:WaitForChild("SpinButton", 10)
	local part = stand and stand:WaitForChild("Button", 10)
	if not part or not part:IsA("BasePart") or part:FindFirstChild(PROMPT_NAME) then
		return
	end
	local config = Config.Controls.Prompts
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.KeyboardKeyCode = (Enum.KeyCode :: any)[config.Keyboard]
	prompt.GamepadKeyCode = (Enum.KeyCode :: any)[config.Gamepad]
	prompt.MaxActivationDistance = config.MaxDistance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Triggered:Connect(spin)
	prompt.Parent = part
	buttons[model] = { Part = part, Rest = part.CFrame, Prompt = prompt }
	refresh()
end

local function addWheel(model: Instance)
	if model:IsA("Model") then
		task.spawn(addRotor, model)
		task.spawn(addButton, model)
	end
end

function WheelController.Start(_self: any)
	Net.on("WheelSpun", function(index: number, _name: string, userId: number)
		if type(index) == "number" and Wheel.Prizes[index] then
			onSpun(index, userId)
			refresh()
		end
	end)
	for _, model in CollectionService:GetTagged(WHEEL_TAG) do
		addWheel(model)
	end
	CollectionService:GetInstanceAddedSignal(WHEEL_TAG):Connect(addWheel)
	local elapsed = 0
	RunService.RenderStepped:Connect(function(deltaTime: number)
		stepRotors()
		stepLanding()
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh() -- the countdown, and the prompt coming back once the wheel has stopped
		end
	end)
end

return WheelController
