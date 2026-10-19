--!strict
--[[
	LockerController — the Inventory (the Locker renamed by the owner, 2026-10-19; bible §5.3): equip the cosmetics you
	own. Opened from the left-edge Inventory button (MenuController), only outside a fight. One tab per cosmetic slot
	that has items. A card shows the name, its rarity and what tapping it does: equip, take off (an equipped
	cosmetic), or where it comes from (its Scrap price in the Shop, a pass, Premium or a Robux item). Fighting styles
	have their own screen (StyleRollController, owner 2026-10-19: "style as separate ui").
	The server checks every change (EquipCosmetic).
]]
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CosmeticRules = require(Shared:WaitForChild("CosmeticRules"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local MENU_ORDER = 2 -- owner, 2026-10-19: Shop, Inventory, Styles, Settings, Quests
local CARD_HEIGHT = 74 -- pixels
local LOCKED_TRANSPARENCY = 0.45

type Card = { Title: string, Detail: string, Status: string, Chosen: boolean, Locked: boolean, Run: (() -> ())? }

local LockerController = {}

local gui: ScreenGui
local tabs: Frame
local grid: ScrollingFrame
local tabButtons: { [string]: TextButton } = {}
local currentTab = CosmeticRules.usedSlots()[1]

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
	for order, card in ipairs(cosmeticCards(currentTab)) do
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
end

function LockerController.Start(_self: any)
	build()
	MenuController.addScreen(Localization.format("Menu.Locker"), MENU_ORDER, gui, onOpen)
	DataController.Changed:Connect(function(key: string)
		if gui.Enabled and key == "Cosmetics" then
			render()
		end
	end)
end

return LockerController
