--!strict
--[[
	GameInProgressController — the "Game in progress" card under the lobby menu (owner's fix list, 2026-10-19: "game
	in progress" and spectate mode in the left UI). While a round runs and the local player is in the lobby it shows
	a blinking live dot, the arena's name, the time left and how many are still fighting, and a Watch button that
	turns the camera onto the round (SpectateController.watch; the spectate bar and Z / X switch fighters). "Stop
	watching" brings the camera back; the round ending does too.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))
local SpectateController = require(script.Parent:WaitForChild("SpectateController"))

local MENU_ORDER = 100 -- under the menu buttons
local REFRESH_INTERVAL = 0.25
local BLINK_PERIOD = 1 -- seconds per live-dot blink

local GameInProgressController = {}

local player = Players.LocalPlayer
local card: Frame
local dot: Frame
local mapLabel: TextLabel
local infoLabel: TextLabel
local watchButton: TextButton

local function fightersLeft(): number
	local count = 0
	for _, other in Players:GetPlayers() do
		local status = other:GetAttribute("RoundStatus")
		if status == "Playing" or status == "Respawning" then
			count += 1
		end
	end
	return count
end

local function refresh()
	local shown = Workspace:GetAttribute("RoundState") == "Playing" and player:GetAttribute("RoundStatus") == "Lobby"
	card.Visible = shown
	if not shown then
		return
	end
	local mapId = Workspace:GetAttribute("RoundMap")
	mapLabel.Text = if type(mapId) == "string" then Localization.format(`Map.{mapId}.Name`) else ""
	local endsAt = Workspace:GetAttribute("RoundEndsAt")
	local left = if type(endsAt) == "number" then endsAt - Workspace:GetServerTimeNow() else 0
	local args: { any } = { HudFormat.clock(left), fightersLeft() }
	infoLabel.Text = Localization.format("InProgress.Info", args)
	local watching = SpectateController.isWatching()
	watchButton.Text = Localization.format(if watching then "InProgress.Stop" else "InProgress.Watch")
	Kit.setChosen(watchButton, watching)
end

local function build()
	card = Instance.new("Frame")
	card.Name = "GameInProgress"
	card.BackgroundColor3 = Kit.Colors.Panel
	card.BackgroundTransparency = 0.12
	card.Size = UDim2.fromScale(1, 0.32)
	card.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card
	local outline = Instance.new("UIStroke")
	outline.Color = Kit.Colors.Accent
	outline.Thickness = 1.5
	outline.Parent = card
	local padding = Instance.new("UIPadding")
	for _, side in { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" } do
		(padding :: any)[side] = UDim.new(0.06, 0)
	end
	padding.Parent = card

	dot = Instance.new("Frame")
	dot.Name = "Live"
	dot.BackgroundColor3 = Kit.Colors.Live
	dot.Position = UDim2.fromScale(0, 0.04)
	dot.Size = UDim2.fromScale(0.1, 0.12)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = dot
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = dot
	dot.Parent = card

	local title = Kit.label(card, Localization.format("InProgress.Title"), UDim2.fromScale(0.86, 0.2), 14)
	title.Position = UDim2.fromScale(0.14, 0)
	title.Font = Kit.TitleFont
	title.TextColor3 = Kit.Colors.Accent
	title.TextXAlignment = Enum.TextXAlignment.Left
	mapLabel = Kit.label(card, "", UDim2.fromScale(1, 0.2), 16)
	mapLabel.Position = UDim2.fromScale(0, 0.22)
	mapLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel = Kit.label(card, "", UDim2.fromScale(1, 0.17), 14)
	infoLabel.Position = UDim2.fromScale(0, 0.43)
	infoLabel.TextColor3 = Kit.Colors.Muted
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left

	watchButton = Kit.button(card, Localization.format("InProgress.Watch"), UDim2.fromScale(1, 0.32))
	watchButton.Position = UDim2.fromScale(0, 0.68)
	watchButton.Activated:Connect(function()
		SpectateController.watch(not SpectateController.isWatching())
		refresh()
	end)
	MenuController.addWidget(card, MENU_ORDER)
end

function GameInProgressController.Start(_self: any)
	build()
	SpectateController.WatchingChanged:Connect(refresh)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if card.Visible then
			dot.BackgroundTransparency = if os.clock() % BLINK_PERIOD < BLINK_PERIOD / 2 then 0 else 0.6
		end
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return GameInProgressController
