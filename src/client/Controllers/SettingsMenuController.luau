--!strict
--[[
	SettingsMenuController — the Settings screen (bible §5.3; step 3.10), in the left-edge menu. Every change goes
	through SettingsController (saved and checked by the server):
	  * Music / Sound effects: − and + buttons in steps of Config.Data.VolumeStep (work with mouse, touch and gamepad).
	  * Camera shake and Low graphics: On / Off.
	  * Button layout (touch only, and only when there is more than one layout): tap to switch.
	  * Camera sensitivity can't be changed by a game script on Roblox, so a note points to Roblox's own menu.
	  * How to play: a page with the rules and the controls for the device in use — the "tutorial replay" while the
	    tutorial itself is skipped (owner, 2026-10-17).
]]
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))

local Client = script.Parent.Parent
local KeyHint = require(Client:WaitForChild("Ui"):WaitForChild("KeyHint"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

local MENU_ORDER = 6 -- bible §5.1: ... Leaderboard, Settings
local ROW_HEIGHT = 0.12 -- of the page
-- The controls the How to play page lists (Jump is Roblox's own: Space / A / the jump button).
local GUIDE_ACTIONS = { "Attack", "Ability", "Grab", "Dash", "Run", "Scoreboard", "Menu" }
local GUIDE_LINES = { "Guide.Goal", "Guide.Modes", "Guide.Join", "Guide.Props", "Guide.Dodge", "Guide.Crumble" }

local SettingsMenuController = {}

local gui: ScreenGui
local settingsPage: Frame
local guidePage: Frame
local refreshers: { () -> () } = {}
local firstButton: TextButton? = nil

local function percent(value: number): string
	return Localization.format("Settings.Percent", { math.floor(value * 100 + 0.5) })
end

local function onOff(value: boolean): string
	return Localization.format(if value then "Settings.On" else "Settings.Off")
end

local function render()
	for _, refresh in refreshers do
		refresh()
	end
end

local function row(page: Frame, labelKey: string, order: number): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, ROW_HEIGHT)
	frame.LayoutOrder = order
	frame.Parent = page
	local label = Kit.label(frame, Localization.format(labelKey), UDim2.fromScale(0.45, 1), 22)
	label.TextXAlignment = Enum.TextXAlignment.Left
	return frame
end

local function button(parent: Instance, text: string, size: UDim2, x: number): TextButton
	local made = Kit.button(parent, text, size)
	made.AnchorPoint = Vector2.new(0, 0.5)
	made.Position = UDim2.fromScale(x, 0.5)
	if firstButton == nil then
		firstButton = made
	end
	return made
end

-- A volume row: − value +.
local function volumeRow(page: Frame, key: string, labelKey: string, order: number)
	local frame = row(page, labelKey, order)
	local step = Config.Data.VolumeStep
	local minus = button(frame, "−", UDim2.fromScale(0.12, 0.8), 0.5)
	local value = Kit.label(frame, "", UDim2.fromScale(0.2, 0.8), 22)
	value.AnchorPoint = Vector2.new(0, 0.5)
	value.Position = UDim2.fromScale(0.64, 0.5)
	local plus = button(frame, "+", UDim2.fromScale(0.12, 0.8), 0.86)
	local function change(delta: number)
		local range = Config.Data.SettingRanges[key]
		local current = SettingsController.get(key)
		local nextValue = math.clamp(math.floor((current + delta) * 100 + 0.5) / 100, range.Min, range.Max)
		SettingsController.set(key, nextValue)
		render()
	end
	minus.Activated:Connect(function()
		change(-step)
	end)
	plus.Activated:Connect(function()
		change(step)
	end)
	table.insert(refreshers, function()
		value.Text = percent(SettingsController.get(key))
	end)
end

-- An On / Off row.
local function toggleRow(page: Frame, key: string, labelKey: string, order: number)
	local frame = row(page, labelKey, order)
	local toggle = button(frame, "", UDim2.fromScale(0.48, 0.8), 0.5)
	toggle.Activated:Connect(function()
		SettingsController.set(key, not SettingsController.get(key))
		render()
	end)
	table.insert(refreshers, function()
		local on = SettingsController.get(key) == true
		toggle.Text = onOff(on)
		Kit.setChosen(toggle, on)
	end)
end

-- The touch button layout (shown only on touch, when there is a choice).
local function layoutRow(page: Frame, order: number)
	local layouts: { string } = {}
	for id in Config.Controls.Touch.Layouts do
		table.insert(layouts, id)
	end
	table.sort(layouts)
	local frame = row(page, "Settings.ButtonLayout", order)
	local cycle = button(frame, "", UDim2.fromScale(0.48, 0.8), 0.5)
	cycle.Activated:Connect(function()
		local index = table.find(layouts, SettingsController.get("ButtonLayout")) or 0
		SettingsController.set("ButtonLayout", layouts[index % #layouts + 1])
		render()
	end)
	table.insert(refreshers, function()
		frame.Visible = #layouts > 1 and InputController.getDevice() == "Touch"
		cycle.Text = Localization.format(`Layout.{SettingsController.get("ButtonLayout")}`)
	end)
end

local function page(panel: Frame, name: string): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromScale(0, 0.14)
	frame.Size = UDim2.fromScale(1, 0.86)
	frame.Parent = panel
	local layout = Kit.list(frame, Enum.FillDirection.Vertical, UDim.new(0.02, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	return frame
end

local function showGuide(show: boolean)
	settingsPage.Visible = not show
	guidePage.Visible = show
end

local function buildGuide(panel: Frame)
	guidePage = page(panel, "Guide")
	guidePage.Visible = false
	local order = 0
	for _, key in GUIDE_LINES do
		order += 1
		local line = Kit.label(guidePage, Localization.format(key), UDim2.fromScale(1, 0.085), 18)
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.TextWrapped = true
		line.LayoutOrder = order
	end
	local controls = Instance.new("Frame")
	controls.BackgroundTransparency = 1
	controls.Size = UDim2.fromScale(1, 0.3)
	controls.LayoutOrder = order + 1
	controls.Parent = guidePage
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromScale(0.32, 0.3)
	grid.CellPadding = UDim2.fromScale(0.01, 0.03)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = controls
	for index, action in GUIDE_ACTIONS do
		local cell = Instance.new("Frame")
		cell.BackgroundTransparency = 1
		cell.LayoutOrder = index
		cell.Parent = controls
		KeyHint.new(cell, action, UDim2.fromScale(0.3, 1))
		local label = Kit.label(cell, Localization.format(`Controls.{action}`), UDim2.fromScale(0.66, 1), 18)
		label.Position = UDim2.fromScale(0.34, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
	local note = Kit.label(guidePage, "", UDim2.fromScale(1, 0.07), 16)
	note.TextColor3 = Kit.Colors.Muted
	note.LayoutOrder = order + 2
	table.insert(refreshers, function()
		note.Text =
			Localization.format(if InputController.getDevice() == "Touch" then "Guide.TouchControls" else "Guide.Jump")
	end)
	local back = Kit.button(guidePage, Localization.format("Settings.Back"), UDim2.fromScale(0.3, 0.09))
	back.LayoutOrder = order + 3
	back.Activated:Connect(function()
		showGuide(false)
	end)
end

local function build()
	gui = Kit.screen("Settings", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.56, 0.72),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(700, 580)
	)
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.11)
	header.Parent = panel
	local title = Kit.label(header, Localization.format("Settings.Title"), UDim2.fromScale(0.7, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.22, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	settingsPage = page(panel, "Settings")
	volumeRow(settingsPage, "MusicVolume", "Settings.Music", 1)
	volumeRow(settingsPage, "SfxVolume", "Settings.Sfx", 2)
	toggleRow(settingsPage, "CameraShake", "Settings.CameraShake", 3)
	toggleRow(settingsPage, "LowGraphics", "Settings.LowGraphics", 4)
	layoutRow(settingsPage, 5)
	local note = Kit.label(settingsPage, Localization.format("Settings.Sensitivity"), UDim2.fromScale(1, 0.08), 16)
	note.TextColor3 = Kit.Colors.Muted
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.LayoutOrder = 6
	local guideButton = Kit.button(settingsPage, Localization.format("Settings.HowToPlay"), UDim2.fromScale(0.4, 0.1))
	guideButton.LayoutOrder = 7
	guideButton.Activated:Connect(function()
		showGuide(true)
	end)

	buildGuide(panel)
end

local function onOpen()
	showGuide(false)
	render()
	if firstButton and InputController.getDevice() == "Gamepad" then
		GuiService.SelectedObject = firstButton
	end
end

function SettingsMenuController.Start(_self: any)
	build()
	MenuController.addScreen(Localization.format("Menu.Settings"), MENU_ORDER, gui, onOpen)
	SettingsController.Changed:Connect(function()
		if gui.Enabled then
			render()
		end
	end)
	InputController.DeviceChanged:Connect(function()
		if gui.Enabled then
			render()
		end
	end)
end

return SettingsMenuController
