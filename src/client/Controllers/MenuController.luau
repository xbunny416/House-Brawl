--!strict
--[[
	MenuController — the lobby menu down the left edge (bible §5.1: Shop, Locker, Quests, Daily Reward, Leaderboard,
	Settings — each screen adds itself with addScreen as it is built). One menu screen is open at a time. The menu is
	hidden while the player is fighting in a round, and an open screen closes then, so nothing covers the arena.
	The Menu action (M / D-pad Up) closes the open screen; otherwise it opens the first screen (the Shop), or on a
	gamepad selects the first menu button (move with the D-pad / stick, A opens).
]]
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local REFRESH_INTERVAL = 0.25

type Screen = { Gui: ScreenGui, Button: TextButton, Order: number, OnOpen: () -> () }

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
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.fromScale(0.01, 0.5)
	bar.Size = UDim2.fromScale(0.12, 0.5)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(150, 420)
	limit.Parent = bar
	local layout = Kit.list(bar, Enum.FillDirection.Vertical, UDim.new(0.02, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
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

-- Opens a menu screen added with addScreen (closing any other), unless the player is fighting.
function MenuController.open(screenGui: ScreenGui)
	if MenuController.isFighting() then
		return
	end
	for _, screen in screens do
		if screen.Gui == screenGui then
			MenuController.close()
			screenGui.Enabled = true
			screen.OnOpen()
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
	`screenGui`. `onOpen` runs after the screen is shown (render it, select its first button on gamepad).
]]
function MenuController.addScreen(text: string, order: number, screenGui: ScreenGui, onOpen: () -> ()): TextButton
	local button = Kit.button(ensureBar(), text, UDim2.fromScale(1, 0.14))
	button.LayoutOrder = order
	button.Activated:Connect(function()
		MenuController.toggle(screenGui)
	end)
	table.insert(screens, { Gui = screenGui, Button = button, Order = order, OnOpen = onOpen })
	table.sort(screens, function(a: Screen, b: Screen): boolean
		return a.Order < b.Order
	end)
	return button
end

local function onMenu()
	local first = screens[1]
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
