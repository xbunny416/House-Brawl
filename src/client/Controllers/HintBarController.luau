--!strict
--[[
	HintBarController — small light-grey key hints along the bottom edge (owner's fix list, 2026-10-19: "small
	light-grey key hints at the bottom of the UI, more when near something interactive"), on keyboard / mouse and
	gamepad: Run and Menu in the lobby, plus "[E] Shop"-style hints for the walk-up prompts in reach; Punch (hold to
	charge) and Scoreboard while fighting; switching fighters while spectating. What shows where is the pure
	Client/Lib/HintRules (lists in Config.Controls.Hints); the key names and gamepad glyphs come from KeyHint. The bar
	is rebuilt only when its hints change.
]]
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))

local Client = script.Parent.Parent
local HintRules = require(Client:WaitForChild("Lib"):WaitForChild("HintRules"))
local KeyHint = require(Client:WaitForChild("Ui"):WaitForChild("KeyHint"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))
local SpectateController = require(script.Parent:WaitForChild("SpectateController"))

local REFRESH_INTERVAL = 0.25
local TEXT_SIZE = 14
local KEY_WIDTH = 34 -- pixels per key box
local GAP = 16 -- pixels between hints

local HintBarController = {}

local player = Players.LocalPlayer
local row: Frame
local shownPrompts: { [ProximityPrompt]: boolean } = {}
local current = ""

local function promptTexts(): { string }
	local texts: { string } = {}
	for prompt in shownPrompts do
		if prompt.Parent and prompt.Enabled and prompt.ActionText ~= "" then
			table.insert(texts, prompt.ActionText)
		end
	end
	table.sort(texts)
	return texts
end

local function hintText(hint: HintRules.Hint): string
	return hint.Text or Localization.format(hint.Key or "")
end

local function addHint(hint: HintRules.Hint, order: number)
	local item = Instance.new("Frame")
	item.Name = "Hint"
	item.BackgroundTransparency = 1
	item.AutomaticSize = Enum.AutomaticSize.X
	item.Size = UDim2.fromScale(0, 1)
	item.LayoutOrder = order
	local layout = Kit.list(item, Enum.FillDirection.Horizontal, UDim.new(0, 4))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	for index, action in hint.Actions do
		local key = KeyHint.new(item, action, UDim2.new(0, KEY_WIDTH, 1, 0))
		key.LayoutOrder = index
		key.BackgroundTransparency = 0.45
	end
	local label = Kit.label(item, hintText(hint), UDim2.fromScale(0, 1), TEXT_SIZE)
	label.LayoutOrder = #hint.Actions + 1
	label.TextScaled = false
	label.TextWrapped = false
	label.TextSize = TEXT_SIZE
	label.AutomaticSize = Enum.AutomaticSize.X
	label.TextColor3 = Kit.Colors.Hint
	label.TextStrokeTransparency = 0.7
	item.Parent = row
end

local function refresh()
	local status = player:GetAttribute("RoundStatus")
	local hints = HintRules.list({
		Device = InputController.getDevice(),
		Status = if type(status) == "string" then status else nil,
		Watching = SpectateController.isWatching(),
		MenuOpen = MenuController.isOpen(),
		Prompts = promptTexts(),
	}, Config.Controls.Hints)
	local parts: { string } = { InputController.getDevice() }
	for _, hint in hints do
		table.insert(parts, `{table.concat(hint.Actions, "+")}={hintText(hint)}`)
	end
	local signature = table.concat(parts, ",")
	if signature == current then
		return
	end
	current = signature
	for _, child in row:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for order, hint in hints do
		addHint(hint, order)
	end
end

function HintBarController.Start(_self: any)
	local gui = Kit.screen("Hints", 3)
	gui.Enabled = true
	row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.new(0.5, 0, 1, -4)
	row.Size = UDim2.new(0.9, 0, 0, TEXT_SIZE + 8)
	Kit.list(row, Enum.FillDirection.Horizontal, UDim.new(0, GAP))
	row.Parent = gui

	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
		shownPrompts[prompt] = true
		refresh()
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
		shownPrompts[prompt] = nil
		refresh()
	end)
	InputController.DeviceChanged:Connect(refresh)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
	refresh()
end

return HintBarController
