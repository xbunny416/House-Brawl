--!strict
--[[
	InputController — one action map for keyboard/mouse, gamepad and touch (bindings in Config.Controls).

	Gameplay code never reads raw keys; it listens for actions:
		InputController.ActionBegan:Connect(function(action: string) ... end) -- "Attack", "Ability", "Grab", "Dash", ...
		InputController.ActionEnded:Connect(function(action: string) ... end) -- released (e.g. a charged punch)
	The client only turns presses into intents; the server decides what they do.

	Touch: the action buttons sit in an arc around Roblox's own jump button (bottom-right, sizes from
	Config.Controls.Touch, recomputed from the screen size) and are shown only while touch is the preferred input.
	Keys typed into text boxes and clicks on UI never start actions.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))

local Lib = script.Parent.Parent:WaitForChild("Lib")
local ActionMap = require(Lib:WaitForChild("ActionMap"))
local TouchLayout = require(Lib:WaitForChild("TouchLayout"))

local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

export type Device = ActionMap.Device

local BUTTON_COLOR = Color3.fromHex("#2A2420")
local BUTTON_PRESSED_COLOR = Color3.fromHex("#D9822B")
local BUTTON_TRANSPARENCY = 0.25
local OUTLINE_COLOR = Color3.fromHex("#F2E6D0")
local TEXT_COLOR = Color3.fromHex("#F2E6D0")
local MAX_TEXT_SIZE = 22
local PRESSED_SCALE = 0.9

local InputController = {
	Priority = -30,
	-- (action) when an action starts: a key, gamepad button or touch button was pressed.
	ActionBegan = Signal.new() :: Signal.Signal<string>,
	-- (action) when the last input holding that action is released.
	ActionEnded = Signal.new() :: Signal.Signal<string>,
	-- (device) when the player switches between keyboard/mouse, gamepad and touch.
	DeviceChanged = Signal.new() :: Signal.Signal<Device>,
}

local tracker = ActionMap.newTracker()
local lookup = ActionMap.lookup(Config.Controls.Keyboard, Config.Controls.Gamepad)
local device: Device = "KeyboardAndMouse"

local playerGui: PlayerGui
local screenGui: ScreenGui? = nil
local container: Frame
local buttons: { [string]: TextButton } = {}
local labelKeys: { [string]: string? } = {} -- action -> GameStrings key, when not the default Controls.<Action>
local hidden: { [string]: boolean? } = {} -- actions whose touch button is hidden (setVisible)
local jumpButton: GuiObject? = nil
local jumpConnections: { RBXScriptConnection } = {}

local function press(source: string, action: string)
	if tracker.press(source, action) then
		InputController.ActionBegan:Fire(action)
	end
end

local function release(source: string, action: string)
	if tracker.release(source, action) then
		InputController.ActionEnded:Fire(action)
	end
end

-- True while any input holds `action`.
function InputController.isDown(action: string): boolean
	return tracker.isDown(action)
end

-- Changes what an action's touch button says (a GameStrings key, e.g. "Controls.Throw" while holding a prop).
-- nil restores the default Controls.<Action>.
function InputController.setLabel(action: string, key: string?)
	labelKeys[action] = key
	local button = buttons[action]
	if button then
		button.Text = Localization.format(key or `Controls.{action}`)
	end
end

-- Shows or hides an action's touch button (e.g. Ability only for styles that have one). Buttons are visible by
-- default; a hidden one keeps its place in the arc.
function InputController.setVisible(action: string, visible: boolean)
	hidden[action] = if visible then nil else true
	local button = buttons[action]
	if button then
		button.Visible = visible
	end
end

-- "KeyboardAndMouse", "Gamepad" or "Touch": the player's current input device.
function InputController.getDevice(): Device
	return device
end

---------------------------------------------------------------------------------------------------------------------
-- Keyboard, mouse and gamepad
---------------------------------------------------------------------------------------------------------------------

local function actionsFor(input: InputObject): (string?, { string }?)
	local name = ActionMap.inputName(input.UserInputType.Name, input.KeyCode.Name)
	if name == nil then
		return nil, nil
	end
	return name, lookup[name]
end

local function onInputBegan(input: InputObject, processed: boolean)
	if processed then
		return -- typing in a text box, clicking a button, or a Roblox menu
	end
	local name, actions = actionsFor(input)
	if name and actions then
		for _, action in actions do
			press(name, action)
		end
	end
end

local function onInputEnded(input: InputObject)
	-- No `processed` check: a held action must end even if it was released over UI.
	local name, actions = actionsFor(input)
	if name and actions then
		for _, action in actions do
			release(name, action)
		end
	end
end

local function releaseAll()
	for _, action in tracker.releaseAll() do
		InputController.ActionEnded:Fire(action)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Touch buttons
---------------------------------------------------------------------------------------------------------------------

local function currentLayout(): { TouchLayout.ButtonSpec }
	local layouts = Config.Controls.Touch.Layouts
	return layouts[SettingsController.get("ButtonLayout")] or layouts.Default
end

-- The jump button as a circle in the container's pixel space (Roblox's real one once it exists).
local function jumpCircle(): TouchLayout.Circle
	local button = jumpButton
	if button and button:IsDescendantOf(playerGui) and button.AbsoluteSize.X > 0 then
		local center = button.AbsolutePosition + button.AbsoluteSize / 2 - container.AbsolutePosition
		return {
			X = center.X,
			Y = center.Y,
			Radius = math.min(button.AbsoluteSize.X, button.AbsoluteSize.Y) / 2,
		}
	end
	return TouchLayout.defaultJump(container.AbsoluteSize.X, container.AbsoluteSize.Y)
end

local function relayout()
	local size = container.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return
	end
	for _, placement in TouchLayout.place(size.X, size.Y, jumpCircle(), currentLayout(), Config.Controls.Touch) do
		local button = buttons[placement.Action]
		if button then
			button.Position = UDim2.fromOffset(placement.X, placement.Y)
			button.Size = UDim2.fromOffset(placement.Size, placement.Size)
		end
	end
end

local function createButton(action: string): TextButton
	local button = Instance.new("TextButton")
	button.Name = action
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.AutoButtonColor = false
	button.BackgroundColor3 = BUTTON_COLOR
	button.BackgroundTransparency = BUTTON_TRANSPARENCY
	button.Font = Enum.Font.GothamBlack
	button.Text = Localization.format(labelKeys[action] or `Controls.{action}`)
	button.TextColor3 = TEXT_COLOR
	button.TextScaled = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button

	local outline = Instance.new("UIStroke")
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Color = OUTLINE_COLOR
	outline.Thickness = 2
	outline.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.16, 0)
	padding.PaddingRight = UDim.new(0.16, 0)
	padding.Parent = button

	local textSize = Instance.new("UITextSizeConstraint")
	textSize.MaxTextSize = MAX_TEXT_SIZE
	textSize.Parent = button

	local scale = Instance.new("UIScale")
	scale.Parent = button

	local function setPressed(pressed: boolean)
		scale.Scale = if pressed then PRESSED_SCALE else 1
		button.BackgroundColor3 = if pressed then BUTTON_PRESSED_COLOR else BUTTON_COLOR
	end

	local source = `Touch.{action}`
	button.InputBegan:Connect(function(input: InputObject)
		local inputType = input.UserInputType
		local isPress = inputType == Enum.UserInputType.Touch or inputType == Enum.UserInputType.MouseButton1
		if not isPress or input.UserInputState ~= Enum.UserInputState.Begin then
			return
		end
		setPressed(true)
		press(source, action)
		-- Wait for this finger to lift, wherever it is by then.
		local connection: RBXScriptConnection
		connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			local state = input.UserInputState
			if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				connection:Disconnect()
				setPressed(false)
				release(source, action)
			end
		end)
	end)

	return button
end

local function buildButtons()
	for _, button in buttons do
		button:Destroy()
	end
	table.clear(buttons)
	for _, spec in currentLayout() do
		local button = createButton(spec.Action)
		button.Visible = not hidden[spec.Action]
		button.Parent = container
		buttons[spec.Action] = button
	end
	relayout()
end

local function watchJumpButton(button: GuiObject)
	for _, connection in jumpConnections do
		connection:Disconnect()
	end
	jumpButton = button
	jumpConnections = {
		button:GetPropertyChangedSignal("AbsolutePosition"):Connect(relayout),
		button:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout),
	}
	relayout()
end

-- Roblox's touch jump button: PlayerGui.TouchGui.TouchControlFrame.JumpButton.
local function isJumpButton(instance: Instance): boolean
	return instance.Name == "JumpButton" and instance:IsA("GuiObject") and instance:FindFirstAncestor("TouchGui") ~= nil
end

local function createTouchGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ActionButtons"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = device == "Touch"

	container = Instance.new("Frame")
	container.Name = "Container"
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromScale(1, 1)
	container.Parent = gui
	container:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)

	gui.Parent = playerGui
	screenGui = gui
	buildButtons()

	for _, descendant in playerGui:GetDescendants() do
		if isJumpButton(descendant) then
			watchJumpButton(descendant :: GuiObject)
		end
	end
	playerGui.DescendantAdded:Connect(function(descendant: Instance)
		if isJumpButton(descendant) then
			watchJumpButton(descendant :: GuiObject)
		end
	end)

	SettingsController.Changed:Connect(function(key: string)
		if key == "ButtonLayout" then
			buildButtons()
		end
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------------------------------------------------

local function readDevice(): Device
	return ActionMap.device(UserInputService.PreferredInput.Name)
end

local function onPreferredInputChanged()
	local previous: Device = device
	device = readDevice()
	if device == previous then
		return
	end
	local gui = screenGui
	if gui then
		gui.Enabled = device == "Touch"
		relayout()
	end
	InputController.DeviceChanged:Fire(device)
end

-- Warns (in Output) about binding names that are not real KeyCode / UserInputType names.
local function checkBindings()
	for name in lookup do
		local ok = pcall(function()
			return if string.sub(name, 1, 11) == "MouseButton"
				then (Enum.UserInputType :: any)[name]
				else (Enum.KeyCode :: any)[name]
		end)
		if not ok then
			warn(`[InputController] Config.Controls binds unknown input "{name}"`)
		end
	end
end

function InputController.Init(_self: any)
	device = readDevice()
	checkBindings()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	UserInputService.WindowFocusReleased:Connect(releaseAll)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(onPreferredInputChanged)
end

function InputController.Start(_self: any)
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	createTouchGui()
end

return InputController
