--!strict
--[[
	DevPanelController — the minimal developer panel (step 1.13), for players with the DevAccess attribute (anyone in
	Studio playtests; see Server/Dev/DevRules). Open / close it with Config.Dev.PanelKey (` by default) or the DEV
	button in the top-left corner. Buttons send DevCommand (the server re-checks access): start / end the round,
	crumble a platform, pick the next map / mode, spawn a prop, set your own Percent / HP, own + equip a style. The
	camera buttons run here: a test shake, and switching the saved Camera Shake setting.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

local BUTTON_HEIGHT = 30 -- pixels
local PERCENT_PRESETS = { 0, 100, 200 }
local HEALTH_PRESETS = { 100, 50, 10 }

type Button = { Label: string, Run: () -> () }

local DevPanelController = {}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local panel: Frame
local list: ScrollingFrame
local sections = 0

local function send(command: string, text: string?, value: number?)
	Net.fire("DevCommand", command, text, value)
end

-- A button that sends one DevCommand.
local function command(label: string, name: string, text: string?, value: number?): Button
	return {
		Label = label,
		Run = function()
			send(name, text, value)
		end,
	}
end

-- A heading with a grid of buttons under it.
local function section(titleKey: string, buttons: { Button })
	sections += 1
	local heading = Kit.label(list, Localization.format(titleKey), UDim2.new(1, 0, 0, BUTTON_HEIGHT * 0.8), 18)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.TextColor3 = Kit.Colors.Accent
	heading.LayoutOrder = sections * 2 - 1

	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.LayoutOrder = sections * 2
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.31, 0, 0, BUTTON_HEIGHT)
	layout.CellPadding = UDim2.new(0.02, 0, 0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	for order, entry in buttons do
		local button = Kit.button(grid, entry.Label, UDim2.new())
		button.LayoutOrder = order
		button.Activated:Connect(entry.Run)
	end
	grid.Parent = list
end

local function buildSections()
	section("Dev.Round", {
		command(Localization.format("Dev.Start"), "StartRound"),
		command(Localization.format("Dev.End"), "EndRound"),
		command(Localization.format("Dev.Crumble"), "Crumble"),
	})

	local maps: { Button } = {}
	for _, mapId in Config.Maps.Rotation do
		local map = Config.Maps.List[mapId]
		if map and map.Enabled then
			table.insert(maps, command(Localization.format(`Map.{mapId}.Name`), "ForceMap", mapId))
		end
	end
	table.insert(maps, command(Localization.format("Dev.ByVote"), "ForceMap"))
	section("Dev.NextMap", maps)

	local modes: { Button } = {}
	for _, modeId in Config.Modes.Order do
		table.insert(modes, command(Localization.format(`Mode.{modeId}.Name`), "ForceMode", modeId))
	end
	table.insert(modes, command(Localization.format("Dev.ByVote"), "ForceMode"))
	section("Dev.NextMode", modes)

	local propIds: { string } = {}
	for typeId in Config.Props.Types do
		table.insert(propIds, typeId)
	end
	table.sort(propIds)
	local props: { Button } = {}
	for _, typeId in propIds do
		table.insert(props, command(Localization.format(`Prop.{typeId}.Name`), "SpawnProp", typeId))
	end
	section("Dev.SpawnProp", props)

	local me: { Button } = {}
	for _, percent in PERCENT_PRESETS do
		table.insert(me, command(Localization.format("Combat.Percent", { percent }), "SetPercent", nil, percent))
	end
	for _, health in HEALTH_PRESETS do
		table.insert(me, command(Localization.format("Combat.HP", { health }), "SetHealth", nil, health))
	end
	section("Dev.Me", me)

	local styles: { Button } = {}
	for _, styleId in Config.Styles.Order do
		table.insert(styles, command(Localization.format(`Style.{styleId}.Name`), "SetStyle", styleId))
	end
	section("Dev.Style", styles)

	section("Dev.Camera", {
		{
			Label = Localization.format("Dev.TestShake"),
			Run = function()
				CameraController.shake(1)
			end,
		},
		{
			Label = Localization.format("Dev.ToggleShake"),
			Run = function()
				SettingsController.set("CameraShake", not SettingsController.get("CameraShake"))
			end,
		},
	})
end

local function build()
	local screen = Kit.screen("DevPanel", 20)
	screen.Enabled = true
	gui = screen

	local open = Kit.button(screen, Localization.format("Dev.Open"), UDim2.fromScale(0.07, 0.05))
	open.Position = UDim2.fromScale(0.01, 0.01)
	local openLimit = Instance.new("UISizeConstraint")
	openLimit.MinSize = Vector2.new(48, 28)
	openLimit.MaxSize = Vector2.new(90, 40)
	openLimit.Parent = open

	panel = Kit.panel(
		screen,
		UDim2.fromScale(0.32, 0.8),
		UDim2.fromScale(0.01, 0.55),
		Vector2.new(0, 0.5),
		Vector2.new(400, 640)
	)
	panel.Visible = false
	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)

	list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = UDim2.fromScale(1, 1)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = panel
	local layout = Kit.list(list, Enum.FillDirection.Vertical, UDim.new(0, 4))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	local title = Kit.label(list, Localization.format("Dev.Title"), UDim2.new(1, 0, 0, BUTTON_HEIGHT), 22)
	title.Font = Kit.TitleFont
	title.LayoutOrder = 0
	buildSections()
end

local function activate()
	if gui then
		return
	end
	build()
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode.Name == Config.Dev.PanelKey then
			panel.Visible = not panel.Visible
		end
	end)
end

function DevPanelController.Start(_self: any)
	if player:GetAttribute("DevAccess") then
		activate()
	end
	player:GetAttributeChangedSignal("DevAccess"):Connect(function()
		if player:GetAttribute("DevAccess") then
			activate()
		end
	end)
end

return DevPanelController
