--!strict
--[[
	SettingsMenuController — the Settings screen (bible §5.3; steps 3.10 and the owner's fix list, 2026-10-19:
	"Settings: visual, audio, promo code"), in the left-edge menu, with four tabs. Every setting goes through
	SettingsController (saved and checked by the server):
	  * Visual: Camera shake and Low graphics On / Off; the touch button layout (on touch, when there is a choice); a
	    note that camera sensitivity is Roblox's own setting (a game script can't change it).
	  * Audio: Music / Sound effects with − and + buttons in steps of Config.Data.VolumeStep (mouse, touch, gamepad).
	  * Promo code: type a code and Redeem (or Enter); the server checks it (RedeemCode — the codes never reach the
	    client) and says what it gave or why not. The lobby's jukebox opens this tab (LobbyPromptController).
	  * How to play: the rules and the controls for the device in use (the "tutorial replay" while the tutorial is
	    skipped).
	open's argument picks the tab ("Visual", "Audio", "Codes", "Guide"; Visual by default).
]]
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent.Parent
local KeyHint = require(Client:WaitForChild("Ui"):WaitForChild("KeyHint"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

local MENU_ORDER = 4 -- owner, 2026-10-19: Shop, Inventory, Styles, Settings, Quests
local ROW_HEIGHT = 0.14 -- of a page
local TABS = { "Visual", "Audio", "Codes", "Guide" }
local CODE_LENGTH = 24 -- the RedeemCode remote's limit
-- The controls the How to play page lists (Jump is Roblox's own: Space / A / the jump button).
local GUIDE_ACTIONS = { "Attack", "Ability", "Grab", "Dash", "Run", "Scoreboard", "Menu" }
local GUIDE_LINES = { "Guide.Goal", "Guide.Modes", "Guide.Join", "Guide.Props", "Guide.Dodge", "Guide.Crumble" }

local SettingsMenuController = {}

local gui: ScreenGui
local pages: { [string]: Frame } = {}
local tabButtons: { [string]: TextButton } = {}
local currentTab = "Visual"
local refreshers: { () -> () } = {}

local codeBox: TextBox
local redeemButton: TextButton
local codeMessage: TextLabel
local redeeming = false

local function render()
	for tab, page in pages do
		page.Visible = tab == currentTab
	end
	for tab, button in tabButtons do
		Kit.setChosen(button, tab == currentTab)
	end
	for _, refresh in refreshers do
		refresh()
	end
end

local function showTab(tab: string)
	currentTab = if pages[tab] then tab else "Visual"
	render()
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
	return made
end

local function note(page: Frame, key: string, order: number): TextLabel
	local label = Kit.label(page, Localization.format(key), UDim2.fromScale(1, 0.1), 16)
	label.TextColor3 = Kit.Colors.Muted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.LayoutOrder = order
	return label
end

---------------------------------------------------------------------------------------------------------------------
-- Visual / Audio
---------------------------------------------------------------------------------------------------------------------

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
		value.Text = Localization.format("Settings.Percent", { math.floor(SettingsController.get(key) * 100 + 0.5) })
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
		toggle.Text = Localization.format(if on then "Settings.On" else "Settings.Off")
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

---------------------------------------------------------------------------------------------------------------------
-- Promo code
---------------------------------------------------------------------------------------------------------------------

local function describe(reward: { [string]: any }): string
	local parts: { string } = {}
	if type(reward.Scrap) == "number" and reward.Scrap > 0 then
		table.insert(parts, Localization.format("Currency.Scrap", { reward.Scrap }))
	end
	if type(reward.Cosmetic) == "string" then
		table.insert(parts, Localization.format(`Cosmetic.{reward.Cosmetic}.Name`))
	end
	return table.concat(parts, " + ")
end

local function redeem()
	local text = codeBox.Text
	if redeeming or text == "" then
		return
	end
	redeeming = true
	redeemButton.Text = Localization.format("Codes.Redeeming")
	task.spawn(function()
		local ok, redeemed, result = pcall(Net.invoke, "RedeemCode", string.sub(text, 1, CODE_LENGTH))
		redeeming = false
		redeemButton.Text = Localization.format("Codes.Redeem")
		if ok and redeemed == true and type(result) == "table" then
			codeMessage.Text = Localization.format("Codes.Redeemed", { describe(result) })
			codeMessage.TextColor3 = Kit.Colors.Accent
			codeBox.Text = ""
		else
			-- A refusal names a Server/Codes/CodeRules reason; no answer (or an unknown one) is TryAgain.
			local known = ok and typeof(result) == "string" and Localization.has(`Codes.Error.{result}`)
			local why = if known then result else "TryAgain"
			codeMessage.Text = Localization.format(`Codes.Error.{why}`)
			codeMessage.TextColor3 = Kit.Colors.Muted
		end
	end)
end

local function buildCodes(page: Frame)
	note(page, "Codes.Info", 1)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, ROW_HEIGHT)
	frame.LayoutOrder = 2
	frame.Parent = page
	codeBox = Instance.new("TextBox")
	codeBox.Name = "Code"
	codeBox.BackgroundColor3 = Kit.Colors.Button
	codeBox.TextColor3 = Kit.Colors.Text
	codeBox.PlaceholderText = Localization.format("Codes.Placeholder")
	codeBox.PlaceholderColor3 = Kit.Colors.Muted
	codeBox.Font = Kit.BodyFont
	codeBox.TextScaled = true
	codeBox.ClearTextOnFocus = false
	codeBox.Text = ""
	codeBox.Size = UDim2.fromScale(0.64, 0.9)
	codeBox.AnchorPoint = Vector2.new(0, 0.5)
	codeBox.Position = UDim2.fromScale(0, 0.5)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = codeBox
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.18, 0)
	padding.PaddingBottom = UDim.new(0.18, 0)
	padding.Parent = codeBox
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 28
	limit.Parent = codeBox
	codeBox.Parent = frame
	codeBox:GetPropertyChangedSignal("Text"):Connect(function()
		if #codeBox.Text > CODE_LENGTH then
			codeBox.Text = string.sub(codeBox.Text, 1, CODE_LENGTH)
		end
	end)
	codeBox.FocusLost:Connect(function(enterPressed: boolean)
		if enterPressed then
			redeem()
		end
	end)
	redeemButton = button(frame, Localization.format("Codes.Redeem"), UDim2.fromScale(0.33, 0.9), 0.67)
	Kit.setChosen(redeemButton, true)
	redeemButton.Activated:Connect(redeem)
	codeMessage = Kit.label(page, "", UDim2.fromScale(1, 0.14), 20)
	codeMessage.TextWrapped = true
	codeMessage.LayoutOrder = 3
end

---------------------------------------------------------------------------------------------------------------------
-- How to play
---------------------------------------------------------------------------------------------------------------------

local function buildGuide(page: Frame)
	local order = 0
	for _, key in GUIDE_LINES do
		order += 1
		local line = Kit.label(page, Localization.format(key), UDim2.fromScale(1, 0.09), 18)
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.TextWrapped = true
		line.LayoutOrder = order
	end
	local controls = Instance.new("Frame")
	controls.BackgroundTransparency = 1
	controls.Size = UDim2.fromScale(1, 0.3)
	controls.LayoutOrder = order + 1
	controls.Parent = page
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
	local deviceNote = note(page, "Guide.Jump", order + 2)
	table.insert(refreshers, function()
		deviceNote.Text =
			Localization.format(if InputController.getDevice() == "Touch" then "Guide.TouchControls" else "Guide.Jump")
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- Screen
---------------------------------------------------------------------------------------------------------------------

local function page(panel: Frame, name: string): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromScale(0, 0.24)
	frame.Size = UDim2.fromScale(1, 0.76)
	frame.Parent = panel
	local layout = Kit.list(frame, Enum.FillDirection.Vertical, UDim.new(0.02, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	pages[name] = frame
	return frame
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

	local texts: { string } = {}
	for _, tab in TABS do
		table.insert(texts, Localization.format(`Settings.Tab.{tab}`))
	end
	local buttons = Kit.tabRow(panel, texts, UDim2.fromScale(0, 0.13), UDim2.fromScale(1, 0.08), 0.235)
	for index, tab in TABS do
		buttons[index].Activated:Connect(function()
			showTab(tab)
		end)
		tabButtons[tab] = buttons[index]
	end

	local visual = page(panel, "Visual")
	toggleRow(visual, "CameraShake", "Settings.CameraShake", 1)
	toggleRow(visual, "LowGraphics", "Settings.LowGraphics", 2)
	layoutRow(visual, 3)
	note(visual, "Settings.Sensitivity", 4)

	local audio = page(panel, "Audio")
	volumeRow(audio, "MusicVolume", "Settings.Music", 1)
	volumeRow(audio, "SfxVolume", "Settings.Sfx", 2)

	buildCodes(page(panel, "Codes"))
	buildGuide(page(panel, "Guide"))
end

local function onOpen(tab: any?)
	showTab(if type(tab) == "string" then tab else "Visual")
	if tab == "Codes" then
		codeMessage.Text = ""
	end
	if InputController.getDevice() == "Gamepad" then
		GuiService.SelectedObject = tabButtons[currentTab]
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
