--!strict
--[[
	MenuController — the lobby menu buttons down the left edge (bible §5.1: Shop, Locker, Quests, Daily Reward,
	Leaderboard, Settings — each screen adds its own button as it is built). Hidden while the player is fighting in a
	round, so nothing covers the arena.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))

local REFRESH_INTERVAL = 0.25

local MenuController = {}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local bar: Frame

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

-- Adds a menu button (already-localized text), sorted by `order`.
function MenuController.addButton(text: string, order: number, onActivated: () -> ()): TextButton
	local button = Kit.button(ensureBar(), text, UDim2.fromScale(1, 0.14))
	button.LayoutOrder = order
	button.Activated:Connect(onActivated)
	return button
end

function MenuController.Start(_self: any)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local screen = gui
		if screen and elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			screen.Enabled = not MenuController.isFighting()
		end
	end)
end

return MenuController
