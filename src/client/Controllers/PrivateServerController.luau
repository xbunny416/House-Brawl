--!strict
--[[
	PrivateServerController — the private server owner's Server menu (bible §7): lock the mode, pick the map and set
	the round length (Shared/PrivateServerRules). Each tap sends PrivateServerSetting; the server checks that the
	sender owns the server, saves the choice in their data and publishes the Workspace attributes (PrivateMode /
	PrivateMap / PrivateRoundTime) this screen lights up. Changes apply from the next vote / round. The left-edge
	menu button only shows for the owner (Workspace PrivateOwnerId).
]]
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))
local PrivateServerRules = require(Shared:WaitForChild("PrivateServerRules"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local MENU_ORDER = 9 -- after the other lobby screens (Shop, Locker, Quests, Daily ...)
local ROW_HEIGHT = 0.2 -- of the panel's body

type Choice = { Label: string, Text: string?, Seconds: number? }
type Row = { Key: string, Attribute: string, Buttons: { [TextButton]: Choice } }

local PrivateServerController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local menuButton: TextButton
local rows: { Row } = {}
local firstButton: TextButton? = nil

local function isOwner(): boolean
	local owner = Workspace:GetAttribute("PrivateOwnerId")
	return type(owner) == "number" and owner ~= 0 and owner == player.UserId
end

local function enabledMaps(): { string }
	local maps: { string } = {}
	for _, mapId in Config.Maps.Rotation do
		local map = Config.Maps.List[mapId]
		if map and map.Enabled then
			table.insert(maps, mapId)
		end
	end
	return maps
end

local function choicesFor(key: string): { Choice }
	local vote = Localization.format("PrivateServer.Vote")
	local choices: { Choice } = {}
	if key == "Mode" then
		table.insert(choices, { Label = vote, Text = PrivateServerRules.Vote })
		for _, modeId in Config.Modes.Order do
			table.insert(choices, { Label = Localization.format(`Mode.{modeId}.Name`), Text = modeId })
		end
	elseif key == "Map" then
		table.insert(choices, { Label = vote, Text = PrivateServerRules.Vote })
		for _, mapId in enabledMaps() do
			table.insert(choices, { Label = Localization.format(`Map.{mapId}.Name`), Text = mapId })
		end
	else
		for _, seconds in Config.Round.PrivateRoundTimes do
			table.insert(choices, { Label = HudFormat.clock(seconds), Seconds = seconds })
		end
	end
	return choices
end

-- Lights up the chosen button in every row from the published Workspace attributes.
local function render()
	for _, row in rows do
		local value = Workspace:GetAttribute(row.Attribute)
		for button, choice in row.Buttons do
			Kit.setChosen(button, value ~= nil and (value == choice.Text or value == choice.Seconds))
		end
	end
end

local function onOpen()
	render()
	if firstButton and InputController.getDevice() == "Gamepad" then
		GuiService.SelectedObject = firstButton
	end
end

local function addRow(body: Frame, key: string, attribute: string, titleKey: string, order: number)
	local frame = Instance.new("Frame")
	frame.Name = key
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, ROW_HEIGHT)
	frame.LayoutOrder = order
	frame.Parent = body
	local title = Kit.label(frame, Localization.format(titleKey), UDim2.fromScale(0.22, 1), 24)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local buttons = Instance.new("Frame")
	buttons.BackgroundTransparency = 1
	buttons.Position = UDim2.fromScale(0.24, 0)
	buttons.Size = UDim2.fromScale(0.76, 1)
	buttons.Parent = frame
	local layout = Kit.list(buttons, Enum.FillDirection.Horizontal, UDim.new(0.015, 0))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local row: Row = { Key = key, Attribute = attribute, Buttons = {} }
	local choices = choicesFor(key)
	for index, choice in choices do
		local button = Kit.button(buttons, choice.Label, UDim2.fromScale(math.min(0.24, 0.98 / #choices), 0.8))
		button.LayoutOrder = index
		button.Activated:Connect(function()
			Net.fire("PrivateServerSetting", key, choice.Text, choice.Seconds)
		end)
		row.Buttons[button] = choice
		if firstButton == nil then
			firstButton = button
		end
	end
	table.insert(rows, row)
end

local function build()
	gui = Kit.screen("PrivateServer", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.62, 0.6),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(820, 460)
	)

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.14)
	header.Parent = panel
	local title = Kit.label(header, Localization.format("PrivateServer.Title"), UDim2.fromScale(0.8, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.2, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromScale(0, 0.17)
	body.Size = UDim2.fromScale(1, 0.83)
	body.Parent = panel
	local layout = Kit.list(body, Enum.FillDirection.Vertical, UDim.new(0.04, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	addRow(body, "Mode", "PrivateMode", "PrivateServer.Mode", 1)
	addRow(body, "Map", "PrivateMap", "PrivateServer.Map", 2)
	addRow(body, "RoundTime", "PrivateRoundTime", "PrivateServer.RoundTime", 3)
	local percent = math.floor(Config.Economy.PrivateServerRewardScale * 100 + 0.5)
	local infoText = if percent > 0
		then Localization.format("PrivateServer.InfoScaled", { percent })
		else Localization.format("PrivateServer.Info")
	local info = Kit.label(body, infoText, UDim2.fromScale(1, 0.16), 20)
	info.TextColor3 = Kit.Colors.Muted
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.LayoutOrder = 4
end

-- Shows the menu button to the owner only (closing the screen for anyone else).
local function refreshOwner()
	local owner = isOwner()
	menuButton.Visible = owner
	if not owner and gui.Enabled then
		MenuController.close()
	end
end

function PrivateServerController.Start(_self: any)
	build()
	menuButton = MenuController.addScreen(Localization.format("Menu.Server"), MENU_ORDER, gui, onOpen)
	refreshOwner()
	Workspace:GetAttributeChangedSignal("PrivateOwnerId"):Connect(refreshOwner)
	for _, attribute in { "PrivateMode", "PrivateMap", "PrivateRoundTime" } do
		Workspace:GetAttributeChangedSignal(attribute):Connect(function()
			if gui.Enabled then
				render()
			end
		end)
	end
end

return PrivateServerController
