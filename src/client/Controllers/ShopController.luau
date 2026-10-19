--!strict
--[[
	ShopController — the Shop (bible §2.3 / §5.3): buy cosmetics with Scrap (fighting styles come from the style roll
	in the Inventory since 2026-10-19). Opened from the left-edge Shop button (MenuController; the Menu action opens it
	first), only outside a fight. Tabs: Daily deals (today's cosmetics at a discount and the time until they change),
	then every cosmetic slot. Tapping an
	item you can buy opens a confirmation with the price and your Scrap; Buy asks the server (Buy remote), which
	checks everything again (Shared/ShopRules). After a purchase, Equip puts the item on at once.
	The Robux tab (bible §7, Shared/MonetizationRules) lists the game passes, Scrap packs and Robux cosmetics with their
	live price, and a Roblox Premium card: tapping one opens Roblox's own purchase prompt (the server grants what Roblox
	confirms: MonetizationService). An item whose id is still 0 shows "Coming soon". Exclusive items in the slot tabs
	open the prompt for the pass / product / Premium they come with.
]]
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CosmeticRules = require(Shared:WaitForChild("CosmeticRules"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))
local MonetizationRules = require(Shared:WaitForChild("MonetizationRules"))
local Net = require(Shared:WaitForChild("Net"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local DAILY_TAB = "Daily"
local ROBUX_TAB = "Robux"
local ROBUX_TAB_ORDER = 100 -- after every cosmetic slot
local CARD_HEIGHT = 74 -- pixels
local DIMMED_TRANSPARENCY = 0.45
local TICK_INTERVAL = 1 -- seconds between countdown updates

type Offer = { Kind: string, Id: string, Price: number, Name: string }
-- Offer: a Scrap purchase (confirmation first); Prompt: opens a Roblox purchase prompt.
type Card = { Title: string, Detail: string, Status: string, Dimmed: boolean, Offer: Offer?, Prompt: (() -> ())? }

local ShopController = {}

local player = Players.LocalPlayer
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
local livePrices: { [string]: number } = {} -- Robux prices from MarketplaceService, by offer key
local pricesRequested = false
local pricesChanged = false -- a live price arrived: render again

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

---------------------------------------------------------------------------------------------------------------------
-- Robux
---------------------------------------------------------------------------------------------------------------------

local function hasPerk(perk: string): boolean
	return player:GetAttribute(perk) == true
end

local function robuxPrice(offer: MonetizationRules.Offer): string
	return Localization.format("Shop.RobuxPrice", { livePrices[offer.Key] or offer.PriceRobux })
end

-- Opens Roblox's purchase prompt for `offer`; nil while the offer has no id yet.
local function promptFor(offer: MonetizationRules.Offer?): (() -> ())?
	if offer == nil or not MonetizationRules.isAvailable(offer) then
		return nil
	end
	local entry: MonetizationRules.Offer = offer
	return function()
		if entry.Kind == "Pass" then
			MarketplaceService:PromptGamePassPurchase(player, entry.Id)
		else
			MarketplaceService:PromptProductPurchase(player, entry.Id)
		end
	end
end

local function promptPremium()
	MarketplaceService:PromptPremiumPurchase(player)
end

-- Asks Roblox for the live prices once; the cards show Config's reference price until they arrive.
local function requestPrices()
	if pricesRequested then
		return
	end
	pricesRequested = true
	for _, offer in MonetizationRules.offers() do
		if MonetizationRules.isAvailable(offer) then
			task.spawn(function()
				local infoType = if offer.Kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
				local ok, productInfo = pcall(function()
					return MarketplaceService:GetProductInfo(offer.Id, infoType)
				end)
				local price = if ok and type(productInfo) == "table" then productInfo.PriceInRobux else nil
				if type(price) == "number" then
					livePrices[offer.Key] = price
					pricesChanged = true
				end
			end)
		end
	end
end

local function robuxCards(owned: { [string]: boolean }): { Card }
	local cards: { Card } = {}
	for _, offer in MonetizationRules.offers() do
		local available = MonetizationRules.isAvailable(offer)
		local isOwned = if offer.Kind == "Pass"
			then hasPerk(offer.Key)
			elseif offer.Cosmetic then CosmeticRules.owns(owned, offer.Cosmetic)
			else false
		local detail
		if offer.Kind == "Pass" then
			detail = Localization.format(`Perk.{offer.Key}.Desc`)
		elseif offer.Cosmetic then
			local item = Config.Cosmetics.Items[offer.Cosmetic]
			local args: { any } =
				{ Localization.format(`Slot.{item.Slot}.One`), Localization.format(`Rarity.{item.Rarity}`) }
			detail = Localization.format("Shop.ItemDetail", args)
		else
			detail = Localization.format("Currency.Scrap", { offer.Scrap or 0 })
		end
		table.insert(cards, {
			Title = Localization.format(MonetizationRules.nameKey(offer)),
			Detail = detail,
			Status = if isOwned
				then Localization.format("Shop.Owned")
				elseif available then robuxPrice(offer)
				else Localization.format("Shop.ComingSoon"),
			Dimmed = isOwned or not available,
			Prompt = if isOwned then nil else promptFor(offer),
		})
	end
	local premium = hasPerk("Premium")
	table.insert(cards, {
		Title = Localization.format("Perk.Premium"),
		Detail = Localization.format("Perk.Premium.Desc"),
		Status = Localization.format(if premium then "Shop.PremiumActive" else "Shop.GetPremium"),
		Dimmed = premium,
		Prompt = if premium then nil else promptPremium,
	})
	return cards
end

---------------------------------------------------------------------------------------------------------------------
-- Cards
---------------------------------------------------------------------------------------------------------------------

local function cosmeticCard(itemId: string, owned: { [string]: boolean }, day: number, withSlot: boolean): Card
	local item = Config.Cosmetics.Items[itemId]
	local name = Localization.format(`Cosmetic.{itemId}.Name`)
	local base = ShopRules.basePrice("Cosmetic", itemId)
	local price = ShopRules.priceOf("Cosmetic", itemId, day)
	local isOwned = CosmeticRules.owns(owned, itemId)
	local status
	local prompt: (() -> ())? = nil
	if isOwned then
		status = Localization.format("Shop.Owned")
	elseif item.Exclusive == "Robux" then
		local offer = MonetizationRules.offer(MonetizationRules.productFor(itemId) or "")
		prompt = promptFor(offer)
		status = if offer and prompt then robuxPrice(offer) else Localization.format("Shop.ComingSoon")
	elseif item.Exclusive == "Premium" then
		status = Localization.format("Locker.PremiumOnly")
		prompt = promptPremium
	elseif item.Exclusive then
		status = Localization.format(`Locker.{item.Exclusive}Only`) -- comes with a game pass
		prompt = promptFor(MonetizationRules.offer(item.Exclusive))
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
		Dimmed = isOwned or (price == nil and prompt == nil),
		Offer = if price and not isOwned then { Kind = "Cosmetic", Id = itemId, Price = price, Name = name } else nil,
		Prompt = prompt,
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
	elseif tab == ROBUX_TAB then
		return robuxCards(data.Cosmetics.Owned)
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
	elseif currentTab == ROBUX_TAB then
		return Localization.format("Shop.RobuxInfo")
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
	Net.fire("EquipCosmetic", Config.Cosmetics.Items[offer.Id].Slot, offer.Id)
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
		local offer, prompt = card.Offer, card.Prompt
		if offer then
			button.Activated:Connect(function()
				confirm(offer)
			end)
		elseif prompt then
			button.Activated:Connect(prompt)
		end
	end
end

local function onOpen()
	pending = nil
	dialog.Visible = false
	requestPrices()
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
	for order, slot in CosmeticRules.usedSlots() do
		addTab(slot, Localization.format(`Slot.{slot}`), order)
	end
	addTab(ROBUX_TAB, Localization.format("Shop.Robux"), ROBUX_TAB_ORDER)

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
		if gui.Enabled and (key == "Scrap" or key == "Cosmetics" or key == "Level") then
			render()
		end
	end)
	for _, perk in MonetizationRules.Perks do
		player:GetAttributeChangedSignal(perk):Connect(function()
			if gui.Enabled then
				render() -- a pass was bought, or Premium changed
			end
		end)
	end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed < TICK_INTERVAL or not gui.Enabled then
			return
		end
		elapsed = 0
		if today() ~= renderedDay or pricesChanged then
			pricesChanged = false
			render() -- the daily deals changed, or live Robux prices arrived
		elseif currentTab == DAILY_TAB then
			info.Text = dailyInfo()
		end
	end)
end

return ShopController
