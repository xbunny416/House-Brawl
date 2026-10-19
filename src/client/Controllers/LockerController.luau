--!strict
--[[
	LockerController — the Inventory (the Locker renamed by the owner, 2026-10-19; bible §5.3): your fighting styles
	and the cosmetics you own. Opened from the left-edge Inventory button (MenuController), only outside a fight.
	Tabs: Styles — the style roll page (Ui/StyleRollView: slots, Spin, odds) — then every cosmetic slot that has
	items. A cosmetic card shows the name, its rarity and what tapping it does: equip, take off (an equipped
	cosmetic), or where it comes from (its Scrap price in the Shop, a pass, Premium or a Robux item).
	The server checks every change (SpinStyle / EquipStyleSlot / LockStyleSlot / EquipCosmetic).
]]
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CosmeticRules = require(Shared:WaitForChild("CosmeticRules"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Ui = script.Parent.Parent:WaitForChild("Ui")
local Kit = require(Ui:WaitForChild("Kit"))
local StyleRollView = require(Ui:WaitForChild("StyleRollView"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local STYLES_TAB = "Styles"
local CARD_HEIGHT = 74 -- pixels
local LOCKED_TRANSPARENCY = 0.45
local TICK_INTERVAL = 1 -- seconds between refreshes of the free-spin countdown

type Card = { Title: string, Detail: string, Status: string, Chosen: boolean, Locked: boolean, Run: (() -> ())? }

local LockerController = {}

local gui: ScreenGui
local tabs: Frame
local grid: ScrollingFrame
local tabButtons: { [string]: TextButton } = {}
local currentTab = STYLES_TAB
local styleView: StyleRollView.View

local function cosmeticCards(slot: string): { Card }
	local data = DataController.get()
	local cards: { Card } = {}
	if data == nil then
		return cards
	end
	for _, itemId in CosmeticRules.itemsIn(slot) do
		local item = Config.Cosmetics.Items[itemId]
		local owned = CosmeticRules.owns(data.Cosmetics.Owned, itemId)
		local equipped = data.Cosmetics.Equipped[slot] == itemId
		local status
		if equipped then
			status = Localization.format("Locker.EquippedRemovable")
		elseif owned then
			status = Localization.format("Locker.Equip")
		elseif item.Exclusive then
			status = Localization.format(`Locker.{item.Exclusive}Only`) -- a pass, Premium or Robux item (Shop)
		else
			status = Localization.format("Locker.Price", { item.Price })
		end
		table.insert(cards, {
			Title = Localization.format(`Cosmetic.{itemId}.Name`),
			Detail = Localization.format(`Rarity.{item.Rarity}`),
			Status = status,
			Chosen = equipped,
			Locked = not owned,
			Run = if owned
				then function()
					Net.fire("EquipCosmetic", slot, if equipped then nil else itemId)
				end
				else nil,
		})
	end
	return cards
end

local function render()
	for _, child in grid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for tab, button in tabButtons do
		Kit.setChosen(button, tab == currentTab)
	end
	local onStyles = currentTab == STYLES_TAB
	styleView.Frame.Visible = onStyles
	grid.Visible = not onStyles
	if onStyles then
		styleView.render()
		return
	end
	local cards = cosmeticCards(currentTab)
	for order, card in ipairs(cards) do
		local button = Kit.button(grid, `{card.Title}\n{card.Detail}\n{card.Status}`, UDim2.new())
		button.LayoutOrder = order
		button.Font = Kit.BodyFont
		Kit.setChosen(button, card.Chosen)
		if card.Locked then
			button.TextTransparency = LOCKED_TRANSPARENCY
			button.AutoButtonColor = false
		end
		local run = card.Run
		if run then
			button.Activated:Connect(run)
		end
	end
end

local function onOpen()
	render()
	if InputController.getDevice() == "Gamepad" then
		GuiService.SelectedObject = tabButtons[currentTab]
	end
end

local function addTab(tab: string, label: string, order: number)
	local button = Kit.button(tabs, label, UDim2.fromScale(1, 0.1))
	button.LayoutOrder = order
	button.Activated:Connect(function()
		currentTab = tab
		render()
	end)
	tabButtons[tab] = button
end

local function build()
	gui = Kit.screen("Locker", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.72, 0.76),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(920, 600)
	)

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.1)
	header.Parent = panel
	local title = Kit.label(header, Localization.format("Locker.Title"), UDim2.fromScale(0.8, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.18, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.fromScale(0, 0.13)
	tabs.Size = UDim2.fromScale(0.24, 0.87)
	tabs.Parent = panel
	local tabLayout = Kit.list(tabs, Enum.FillDirection.Vertical, UDim.new(0.015, 0))
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	addTab(STYLES_TAB, Localization.format("Locker.Styles"), 0)
	for order, slot in CosmeticRules.usedSlots() do
		addTab(slot, Localization.format(`Slot.{slot}`), order)
	end

	grid = Instance.new("ScrollingFrame")
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Position = UDim2.fromScale(0.27, 0.13)
	grid.Size = UDim2.fromScale(0.73, 0.87)
	grid.CanvasSize = UDim2.new()
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.ScrollBarThickness = 6
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.31, 0, 0, CARD_HEIGHT)
	layout.CellPadding = UDim2.new(0.02, 0, 0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	styleView = StyleRollView.new(panel, grid.Position, grid.Size)
end

function LockerController.Start(_self: any)
	build()
	MenuController.addScreen(Localization.format("Menu.Locker"), 2, gui, onOpen)
	DataController.Changed:Connect(function(key: string)
		if gui.Enabled and (key == "Styles" or key == "Cosmetics" or key == "Scrap") then
			render()
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= TICK_INTERVAL and gui.Enabled and currentTab == STYLES_TAB then
			elapsed = 0
			styleView.render() -- the free-spin countdown
		end
	end)
	-- Paid spins show once the player's policy is known (PlayerPolicyService).
	Players.LocalPlayer:GetAttributeChangedSignal("PolicyPaidRandomItems"):Connect(function()
		if gui.Enabled then
			render()
		end
	end)
end

return LockerController
