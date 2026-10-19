--!strict
--[[
	StyleRollController — the Styles screen (owner, 2026-10-19: "style as separate ui instead of within inventory";
	reference picture docs/reference/style-roll.jpg): a big panel of its own with the style roll (Ui/StyleRollView:
	slots, the equipped style, Spin, free-spin countdown, pity, odds). Opened from its left-edge menu button (third,
	after Shop and Inventory), only outside a fight. The countdown refreshes every second while it is open, and the
	page redraws when the player's styles or Coins change or their policy (paid spins) becomes known.
]]
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))

local Ui = script.Parent.Parent:WaitForChild("Ui")
local Kit = require(Ui:WaitForChild("Kit"))
local StyleRollView = require(Ui:WaitForChild("StyleRollView"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local MENU_ORDER = 3 -- owner, 2026-10-19: Shop, Inventory, Styles, Settings, Quests
local TICK_INTERVAL = 1 -- seconds between refreshes of the free-spin countdown

local StyleRollController = {}

local gui: ScreenGui
local closeButton: TextButton
local view: StyleRollView.View

local function build()
	gui = Kit.screen("StyleRoll", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.86, 0.84),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(1200, 700)
	)

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.09)
	header.Parent = panel
	local title = Kit.label(header, Localization.format("Menu.Styles"), UDim2.fromScale(0.8, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.15, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	view = StyleRollView.new(panel, UDim2.fromScale(0, 0.12), UDim2.fromScale(1, 0.88))
end

local function onOpen()
	view.render()
	if InputController.getDevice() == "Gamepad" then
		GuiService.SelectedObject = closeButton
	end
end

function StyleRollController.Start(_self: any)
	build()
	MenuController.addScreen(Localization.format("Menu.Styles"), MENU_ORDER, gui, onOpen)
	DataController.Changed:Connect(function(key: string)
		if gui.Enabled and (key == "Styles" or key == "Scrap") then
			view.render()
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= TICK_INTERVAL and gui.Enabled then
			elapsed = 0
			view.tick() -- the free-spin countdown
		end
	end)
	-- Paid spins show once the player's policy is known (PlayerPolicyService).
	Players.LocalPlayer:GetAttributeChangedSignal("PolicyPaidRandomItems"):Connect(function()
		if gui.Enabled then
			view.render()
		end
	end)
end

return StyleRollController
