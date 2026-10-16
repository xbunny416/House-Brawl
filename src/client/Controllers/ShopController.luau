--!strict
--[[
	ShopController — the Shop (bible §2.3 / §5.3): buy fighting styles and cosmetics with Scrap. Opened from the
	left-edge Shop button (MenuController; the Menu action opens it first), only outside a fight. Tabs: Daily deals
	(today's cosmetics at a discount and the time until they change), Styles, then every cosmetic slot. Tapping an
	item you can buy opens a confirmation with the price and your Scrap; Buy asks the server (Buy remote), which
	checks everything again (Shared/ShopRules). After a purchase, Equip puts the item on at once.
	Robux items (Scrap packs, passes, premium cosmetics) come with step 3.1.
]]
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CosmeticRules = require(Shared:WaitForChild("CosmeticRules"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))
local StyleRules = require(Shared:WaitForChild("StyleRules"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local DAILY_TAB = "Daily"
local STYLES_TAB = "Styles"
local CARD_HEIGHT = 74 -- pixels
local DIMMED_TRANSPARENCY = 0.45
local TICK_INTERVAL = 1 -- seconds between countdown updates

type Offer = { Kind: string, Id: string, Price: number, Name: string }
type Card = { Title: string, Detail: string, Status: string, Dimmed: boolean, Offer: Offer? }

local ShopController = {}

local gui: ScreenGui
local tabs: Frame
local grid: ScrollingFrame
local info: TextLabel
local balance: TextLabel
local tabButtons: { [string]: TextButton } = {}
local currentTab = DAILY_TAB
local renderedDay = -1

local dialog: TextButton
local message: TextLabel
local primary: TextButton
local secondary: TextButton
local primaryAction: (() -> ())? = nil
local pending: Offer? = nil

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function today(): number
	return ShopRules.dayAt(now())
end

local function scrap(): number
	local data = DataController.get()
	return if data then data.Scrap else 0
end

local function dailyInfo(): string
	local rotation = Config.Cosmetics.DailyRotation
	local left = Formulas.secondsUntilNextDay(now(), rotation.ResetHourUTC)
	local args: { any } = { math.floor(rotation.Discount * 100 + 0.5), HudFormat.longClock(left) }
	return Localization.format("Shop.DailyInfo", args)
end

local function cosmeticCard(itemId: string, owned: { [string]: boolean }, day: number, withSlot: boolean): Card
	local item = Config.Cosmetics.Items[itemId]
	local name = Localization.format(`Cosmetic.{itemId}.Name`)
	local base = ShopRules.basePrice("Cosmetic", itemId)
	local price = ShopRules.priceOf("Cosmetic", itemId, day)
	local isOwned = CosmeticRules.owns(owned, itemId)
	local status
	if isOwned then
		status = Localization.format("Shop.Owned")
	elseif item.Exclusive == "VIP" then
		status = Localization.format("Locker.VIPOnly")
	elseif item.Exclusive == "Premium" then
		status = Localization.format("Locker.PremiumOnly")
	elseif price and base and price < base then
		status = Localization.format("Shop.DealPrice", { price, base })
	elseif price then
		status = Localization.format("Currency.Scrap", { price })
	else
		status = Localization.format("Shop.NotForSale")
	end
	local rarity = Localization.format(`Rarity.{item.Rarity}`)
	return {
		Title = name,
		Detail = if withSlot
			then Localization.format("Shop.ItemDetail", { Localization.format(`Slot.{item.Slot}.One`), rarity })
			else rarity,
		Status = status,
		Dimmed = isOwned or price == nil,
		Offer = if price and not isOwned then { Kind = "Cosmetic", Id = itemId, Price = price, Name = name } else nil,
	}
end

local function styleCard(styleId: string, owned: { [string]: boolean }, day: number): Card
	local style = Config.Styles.List[styleId]
	local name = Localization.format(`Style.{styleId}.Name`)
	local price = ShopRules.priceOf("Style", styleId, day)
	local isOwned = StyleRules.owns(owned, styleId)
	return {
		Title = name,
		Detail = Localization.format(`Style.{styleId}.Desc`),
		Status = if isOwned
			then Localization.format("Shop.Owned")
			elseif price then Localization.format("Shop.StylePrice", { price, style.UnlockLevel })
			else Localization.format("Shop.NotForSale"),
		Dimmed = isOwned or price == nil,
		Offer = if price and not isOwned then { Kind = "Style", Id = styleId, Price = price, Name = name } else nil,
	}
end

local function cardsFor(tab: string, day: number): { Card }
	local data = DataController.get()
	local cards: { Card } = {}
	if data == nil then
		return cards
	end
	if tab == DAILY_TAB then
		for _, itemId in ShopRules.dailyItems(day) do
			table.insert(cards, cosmeticCard(itemId, data.Cosmetics.Owned, day, true))
		end
	elseif tab == STYLES_TAB then
		for _, styleId in Config.Styles.Order do
			table.insert(cards, styleCard(styleId, data.Styles.Owned, day))
		end
	else
		for _, itemId in CosmeticRules.itemsIn(tab) do
			table.insert(cards, cosmeticCard(itemId, data.Cosmetics.Owned, day, false))
		end
	end
	return cards
end

local function infoText(): string
	if currentTab == DAILY_TAB then
		return dailyInfo()
	elseif currentTab == STYLES_TAB then
		return Localization.format("Shop.StylesInfo")
	end
	return Localization.format("Shop.CosmeticsInfo")
end

---------------------------------------------------------------------------------------------------------------------
-- Confirmation
---------------------------------------------------------------------------------------------------------------------

local function focus(button: GuiObject)
	if InputController.getDevice() == "Gamepad" then
		GuiService.SelectedObject = button
	end
end

local function setButtons(primaryText: string?, action: (() -> ())?, secondaryText: string)
	primary.Visible = primaryText ~= nil
	primary.Text = primaryText or ""
	primaryAction = action
	secondary.Text = secondaryText
	focus(if primaryText then primary else secondary)
end

local function closeDialog()
	pending = nil
	primaryAction = nil
	dialog.Visible = false
	focus(tabButtons[currentTab])
end

local function equip(offer: Offer)
	if offer.Kind == "Style" then
		Net.fire("EquipStyle", offer.Id)
	else
		Net.fire("EquipCosmetic", Config.Cosmetics.Items[offer.Id].Slot, offer.Id)
	end
	closeDialog()
end

local function buy()
	local offer = pending
	if offer == nil then
		return
	end
	primaryAction = nil -- no second Buy while this one is on its way
	primary.Text = Localization.format("Shop.Buying")
	task.spawn(function()
		local ok, bought, reason = pcall(Net.invoke, "Buy", offer.Kind, offer.Id, offer.Price)
		if pending ~= offer then
			return -- the dialog was closed meanwhile
		end
		if ok and bought == true then
			message.Text = Localization.format("Shop.Bought", { offer.Name })
			setButtons(Localization.format("Shop.Equip"), function()
				equip(offer)
			end, Localization.format("Common.Close"))
		else
			local why = if ok
					and typeof(reason) == "string"
					and table.find(ShopRules.Reasons, reason)
				then reason
				else "TryAgain"
			message.Text = Localization.format(`Shop.Error.{why}`)
			setButtons(nil, nil, Localization.format("Common.Close"))
		end
	end)
end

local function confirm(offer: Offer)
	pending = offer
	dialog.Visible = true
	local have = scrap()
	if have >= offer.Price then
		local args: { any } = { offer.Name, offer.Price, have }
		message.Text = Localization.format("Shop.Confirm", args)
		setButtons(Localization.format("Shop.Buy"), buy, Localization.format("Common.Cancel"))
	else
		local args: { any } = { offer.Name, offer.Price, offer.Price - have }
		message.Text = Localization.format("Shop.NeedMore", args)
		setButtons(nil, nil, Localization.format("Common.Close"))
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Screen
---------------------------------------------------------------------------------------------------------------------

local function render()
	local day = today()
	renderedDay = day
	for _, child in grid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for tab, button in tabButtons do
		Kit.setChosen(button, tab == currentTab)
	end
	balance.Text = Localization.format("Currency.Scrap", { scrap() })
	info.Text = infoText()
	for order, card in ipairs(cardsFor(currentTab, day)) do
		local button = Kit.button(grid, `{card.Title}\n{card.Detail}\n{card.Status}`, UDim2.new())
		button.LayoutOrder = order
		button.Font = Kit.BodyFont
		if card.Dimmed then
			button.TextTransparency = DIMMED_TRANSPARENCY
			button.AutoButtonColor = false
		end
		local offer = card.Offer
		if offer then
			button.Activated:Connect(function()
				confirm(offer)
			end)
		end
	end
end

local function onOpen()
	pending = nil
	dialog.Visible = false
	render()
	focus(tabButtons[currentTab])
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

local function buildDialog(panel: Frame)
	-- A full-panel button so taps on the cards underneath are blocked while it shows.
	dialog = Instance.new("TextButton")
	dialog.Name = "Confirm"
	dialog.Text = ""
	dialog.AutoButtonColor = false
	dialog.Selectable = false
	dialog.BackgroundColor3 = Color3.new(0, 0, 0)
	dialog.BackgroundTransparency = 0.4
	dialog.Size = UDim2.fromScale(1, 1)
	dialog.ZIndex = 10
	dialog.Visible = false
	dialog.Parent = panel

	local box = Kit.panel(dialog, UDim2.fromScale(0.6, 0.5), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	message = Kit.label(box, "", UDim2.fromScale(1, 0.6), 26)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromScale(0, 0.68)
	row.Size = UDim2.fromScale(1, 0.32)
	row.Parent = box
	Kit.list(row, Enum.FillDirection.Horizontal, UDim.new(0.04, 0))
	primary = Kit.button(row, "", UDim2.fromScale(0.44, 1))
	primary.LayoutOrder = 1
	Kit.setChosen(primary, true)
	primary.Activated:Connect(function()
		local action = primaryAction
		if action then
			action()
		end
	end)
	secondary = Kit.button(row, "", UDim2.fromScale(0.44, 1))
	secondary.LayoutOrder = 2
	secondary.Activated:Connect(closeDialog)
end

local function build()
	gui = Kit.screen("Shop", 8)
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
	local title = Kit.label(header, Localization.format("Shop.Title"), UDim2.fromScale(0.4, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	balance = Kit.label(header, "", UDim2.fromScale(0.36, 0.8), 24)
	balance.AnchorPoint = Vector2.new(1, 0.5)
	balance.Position = UDim2.fromScale(0.8, 0.5)
	balance.TextColor3 = Kit.Colors.Accent
	balance.TextXAlignment = Enum.TextXAlignment.Right
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
	addTab(DAILY_TAB, Localization.format("Shop.Daily"), 0)
	addTab(STYLES_TAB, Localization.format("Shop.Styles"), 1)
	for order, slot in CosmeticRules.usedSlots() do
		addTab(slot, Localization.format(`Slot.{slot}`), order + 1)
	end

	info = Kit.label(panel, "", UDim2.fromScale(0.73, 0.06), 20)
	info.Position = UDim2.fromScale(0.27, 0.13)
	info.TextColor3 = Kit.Colors.Muted
	info.TextXAlignment = Enum.TextXAlignment.Left

	grid = Instance.new("ScrollingFrame")
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Position = UDim2.fromScale(0.27, 0.21)
	grid.Size = UDim2.fromScale(0.73, 0.79)
	grid.CanvasSize = UDim2.new()
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.ScrollBarThickness = 6
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.31, 0, 0, CARD_HEIGHT)
	layout.CellPadding = UDim2.new(0.02, 0, 0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	buildDialog(panel)
end

function ShopController.Start(_self: any)
	build()
	MenuController.addScreen(Localization.format("Menu.Shop"), 1, gui, onOpen)
	DataController.Changed:Connect(function(key: string)
		if gui.Enabled and (key == "Scrap" or key == "Styles" or key == "Cosmetics" or key == "Level") then
			render()
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed < TICK_INTERVAL or not gui.Enabled then
			return
		end
		elapsed = 0
		if today() ~= renderedDay then
			render() -- the daily deals just changed
		elseif currentTab == DAILY_TAB then
			info.Text = dailyInfo()
		end
	end)
end

return ShopController
