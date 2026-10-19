--!strict
--[[
	MenuController — the lobby menu down the left edge (owner, 2026-10-19: Shop, Inventory, Styles, Settings, Quests —
	each screen adds itself with addScreen; the Daily reward has no button, it opens itself and from Quests). One menu
	screen is open at a time. The menu is hidden while the player is fighting in a round, and an open screen closes
	then, so nothing covers the arena.
	The Menu action (M / D-pad Up) closes the open screen; otherwise it opens the first screen (the Shop), or on a
	gamepad selects the first menu button (move with the D-pad / stick, A opens). Screens also open from the lobby's
	walk-up prompts (LobbyPromptController → openNamed).
]]
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local REFRESH_INTERVAL = 0.25

type Screen = { Gui: ScreenGui, Button: TextButton?, Order: number, OnOpen: (any?) -> () }

local MenuController = {}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local bar: Frame
local screens: { Screen } = {}

local function ensureBar(): Frame
	if gui then
		return bar
	end
	local screen = Kit.screen("Menu", 4)
	screen.Enabled = true
	gui = screen
	bar = Instance.new("Frame")
	bar.Name = "Buttons"
	bar.BackgroundTransparency = 1
	-- Under the coins / level block (ProfileController), like the owner's reference (2026-10-19).
	bar.Position = UDim2.fromScale(0.01, 0.36)
	bar.Size = UDim2.fromScale(0.12, 0.42)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(170, 360)
	limit.Parent = bar
	local layout = Kit.list(bar, Enum.FillDirection.Vertical, UDim.new(0.02, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	bar.Parent = screen
	return bar
end

-- True while the local player is fighting in a round (menus stay closed then).
function MenuController.isFighting(): boolean
	local status = player:GetAttribute("RoundStatus")
	return status == "Playing" or status == "Respawning"
end

local function openScreen(): Screen?
	for _, screen in screens do
		if screen.Gui.Enabled then
			return screen
		end
	end
	return nil
end

-- True while a menu screen is open.
function MenuController.isOpen(): boolean
	return openScreen() ~= nil
end

-- Closes the open menu screen (if any).
function MenuController.close()
	for _, screen in screens do
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(screen.Gui) then
			GuiService.SelectedObject = nil
		end
		screen.Gui.Enabled = false
	end
end

-- Opens a menu screen added with addScreen (closing any other), unless the player is fighting. `arg` goes to its
-- onOpen (e.g. which tab to show).
function MenuController.open(screenGui: ScreenGui, arg: any?)
	if MenuController.isFighting() then
		return
	end
	for _, screen in screens do
		if screen.Gui == screenGui then
			MenuController.close()
			screenGui.Enabled = true
			screen.OnOpen(arg)
			return
		end
	end
end

-- Opens the menu screen whose ScreenGui is named `name` (e.g. "Shop"), like `open` (lobby walk-up prompts).
function MenuController.openNamed(name: string, arg: any?)
	for _, screen in screens do
		if screen.Gui.Name == name then
			MenuController.open(screen.Gui, arg)
			return
		end
	end
end

function MenuController.toggle(screenGui: ScreenGui)
	if screenGui.Enabled then
		MenuController.close()
	else
		MenuController.open(screenGui)
	end
end

--[[
	Adds a menu screen: a left-edge button (already-localized text, sorted by `order`) that opens / closes
	`screenGui` — or no button when `text` is nil (a screen opened from elsewhere, e.g. the Daily reward). `onOpen`
	runs after the screen is shown, with open's `arg` (render it, select its first button on gamepad).
]]
function MenuController.addScreen(text: string?, order: number, screenGui: ScreenGui, onOpen: (any?) -> ()): TextButton?
	local button: TextButton? = nil
	if text then
		local made = Kit.button(ensureBar(), text, UDim2.fromScale(1, 0.14))
		made.LayoutOrder = order
		made.Activated:Connect(function()
			MenuController.toggle(screenGui)
		end)
		button = made
	end
	table.insert(screens, { Gui = screenGui, Button = button, Order = order, OnOpen = onOpen })
	table.sort(screens, function(a: Screen, b: Screen): boolean
		return a.Order < b.Order
	end)
	return button
end

-- Puts `widget` in the menu column, after the buttons with a lower `order` (e.g. the Game in progress card). It
-- shows and hides with the menu.
function MenuController.addWidget(widget: GuiObject, order: number)
	widget.LayoutOrder = order
	widget.Parent = ensureBar()
end

local function onMenu()
	local first: Screen? = nil
	for _, screen in screens do
		if screen.Button and screen.Button.Visible then
			first = screen
			break
		end
	end
	if openScreen() then
		MenuController.close()
	elseif first == nil or MenuController.isFighting() then
		return
	elseif InputController.getDevice() == "Gamepad" then
		GuiService.SelectedObject = first.Button
	else
		MenuController.open(first.Gui)
	end
end

function MenuController.Start(_self: any)
	InputController.ActionBegan:Connect(function(action: string)
		if action == "Menu" then
			onMenu()
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local screen = gui
		if screen and elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			local fighting = MenuController.isFighting()
			screen.Enabled = not fighting
			if fighting and openScreen() then
				MenuController.close()
			end
		end
	end)
end

return MenuController
