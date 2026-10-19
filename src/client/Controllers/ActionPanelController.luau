--!strict
--[[
	ActionPanelController — the bottom-right key panel (owner, 2026-10-17): one slot per move that has a key and a
	cooldown or a cost, each showing its key (key name / gamepad glyph, KeyHint) and filling up as it gets ready:
	  * Run (Left Shift / left stick): lit while running; dimmed when stamina is too low to start.
	  * Dash (Q / RB): fills as the cooldown runs out; dimmed when stamina is below a dash's cost.
	  * Ability (F / Y): only for styles that have one (Wrecker: Parry), filled from the server's AbilityReadyAt.
	Dash and Ability show only while fighting in a round: the lobby is run-only (owner, 2026-10-19).
	Shown with keyboard / mouse and gamepad; on touch the action buttons sit in that corner instead (and the bottom
	bar keeps its dash ring). Hidden while spectating.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local KeyHint = require(Client:WaitForChild("Ui"):WaitForChild("KeyHint"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local DashController = require(script.Parent:WaitForChild("DashController"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MovementController = require(script.Parent:WaitForChild("MovementController"))

local REFRESH_INTERVAL = 0.1
local DIMMED = 0.6 -- transparency of a slot that can't be used right now

type Slot = { Frame: Frame, Fill: UIGradient, Label: TextLabel, Outline: UIStroke }

local ActionPanelController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local slots: { [string]: Slot } = {}

-- Fills the slot from the bottom up: `fill` 0 = just used, 1 = ready.
local function setFill(slot: Slot, fill: number)
	if fill >= 1 then
		slot.Fill.Transparency = NumberSequence.new(0)
	elseif fill <= 0 then
		slot.Fill.Transparency = NumberSequence.new(0.75)
	else
		slot.Fill.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(fill, 0),
			NumberSequenceKeypoint.new(math.min(fill + 0.001, 1), 0.75),
			NumberSequenceKeypoint.new(1, 0.75),
		})
	end
end

local function setDimmed(slot: Slot, dimmed: boolean)
	slot.Frame.BackgroundTransparency = if dimmed then DIMMED else 0.15
	slot.Label.TextTransparency = if dimmed then 0.5 else 0
end

local function buildSlot(parent: Frame, action: string, labelKey: string, order: number): Slot
	local frame = Instance.new("Frame")
	frame.Name = action
	frame.Size = UDim2.fromScale(0.3, 1)
	frame.BackgroundColor3 = Kit.Colors.Button
	frame.LayoutOrder = order
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = frame
	local outline = Instance.new("UIStroke")
	outline.Color = Kit.Colors.Accent
	outline.Thickness = 0
	outline.Parent = frame
	local fill = Instance.new("UIGradient")
	fill.Rotation = -90
	fill.Parent = frame
	local hint = KeyHint.new(frame, action, UDim2.fromScale(0.62, 0.42))
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.fromScale(0.5, 0.1)
	hint.BackgroundTransparency = 1
	local label = Kit.label(frame, Localization.format(labelKey), UDim2.fromScale(0.9, 0.32), 16)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 0.95)
	frame.Parent = parent
	return { Frame = frame, Fill = fill, Label = label, Outline = outline }
end

local function build()
	gui = Kit.screen("ActionPanel", 2)
	gui.Enabled = true
	local panel = Instance.new("Frame")
	panel.Name = "Slots"
	panel.BackgroundTransparency = 1
	panel.AnchorPoint = Vector2.new(1, 1)
	panel.Position = UDim2.new(0.985, 0, 0.975, -14) -- above the key hints (HintBarController)
	panel.Size = UDim2.fromScale(0.24, 0.1)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(280, 84)
	limit.MinSize = Vector2.new(180, 56)
	limit.Parent = panel
	local layout = Kit.list(panel, Enum.FillDirection.Horizontal, UDim.new(0.04, 0))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	panel.Parent = gui
	slots.Run = buildSlot(panel, "Run", "Controls.Run", 1)
	slots.Dash = buildSlot(panel, "Dash", "Controls.Dash", 2)
	slots.Ability = buildSlot(panel, "Ability", "Controls.Parry", 3)
end

local function equippedAbility(): any?
	local data = DataController.get()
	local style = data and Config.Styles.List[data.Styles.Equipped]
	return style and style.Ability
end

local function refresh()
	local status = player:GetAttribute("RoundStatus")
	gui.Enabled = InputController.getDevice() ~= "Touch" and status ~= "Spectating"
	if not gui.Enabled then
		return
	end
	local character = player.Character
	local staminaValue = character and character:GetAttribute("Stamina")
	local staminaLeft = if type(staminaValue) == "number" then staminaValue else Config.Combat.Stamina.Max
	local staminaConfig = Config.Combat.Stamina

	-- Run: lit while running, dimmed when there is not enough stamina to start.
	local running = MovementController.isRunning()
	slots.Run.Outline.Thickness = if running then 3 else 0
	setFill(slots.Run, staminaLeft / staminaConfig.Max)
	setDimmed(slots.Run, not running and staminaLeft < staminaConfig.RunResume)

	-- Dash and Ability only in a round (the lobby is run-only).
	local fighting = status == "Playing"
	slots.Dash.Frame.Visible = fighting

	-- Dash: the cooldown, dimmed below a dash's stamina cost.
	setFill(slots.Dash, HudFormat.dashFill(DashController.cooldownLeft(), Config.Combat.Dash.Cooldown))
	setDimmed(slots.Dash, staminaLeft < staminaConfig.DashCost)

	-- Ability: only for styles that have one.
	local ability = equippedAbility()
	slots.Ability.Frame.Visible = fighting and ability ~= nil
	if ability then
		local readyAt = character and character:GetAttribute("AbilityReadyAt")
		local left = if type(readyAt) == "number" then readyAt - Workspace:GetServerTimeNow() else 0
		setFill(slots.Ability, HudFormat.dashFill(math.max(left, 0), ability.Cooldown))
		setDimmed(slots.Ability, false)
	end
end

function ActionPanelController.Start(_self: any)
	build()
	local elapsed = REFRESH_INTERVAL
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return ActionPanelController
