--!strict
--[[
	StyleRollView — the style roll page of the Inventory's Styles tab (owner's fix list, 2026-10-19; reference picture
	docs/reference/style-roll.jpg). Left: the player's style slots (tap to equip, Lock / Unlock; a "+ Style slot"
	card opens the Robux purchase while there is room). Middle: the equipped style (name in its rarity color, rarity,
	description), the Spin button (free once a day, then Config.Styles.Roll.SpinPrice Scrap), when the free spin
	comes back, and the pity counter. Right: every rarity with its exact odds and the styles in it — shown before
	any spin, as Roblox asks for paid random items. Paid spins are offered only where the player's policy allows
	them (Player attribute PolicyPaidRandomItems); the server checks everything again (StyleService).
	A spin plays a short reel through the style names and lands on what the server rolled.
]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))
local StyleRules = require(Shared:WaitForChild("StyleRules"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local DataController = require(Client:WaitForChild("Controllers"):WaitForChild("DataController"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local Roll = Config.Styles.Roll
local SLOT_HEIGHT = 68 -- pixels
local REEL_TIME = 1.4 -- seconds the reel runs at least
local REEL_START_STEP = 0.05 -- seconds between names at the start, slowing to...
local REEL_END_STEP = 0.22 -- ...this at the end

export type View = { Frame: Frame, render: () -> () }

local StyleRollView = {}

local player = Players.LocalPlayer

local function rarityColor(rarity: string): Color3
	return Color3.fromHex(Roll.RarityColors[rarity] or Roll.RarityColors[Roll.RarityOrder[1]])
end

local function styleName(styleId: string): string
	return Localization.format(`Style.{styleId}.Name`)
end

local function paidAllowed(): boolean
	return player:GetAttribute("PolicyPaidRandomItems") == true
end

local function freeAllowed(): boolean
	return Workspace:GetAttribute("PrivateServer") ~= true or Config.Economy.PrivateServerRewardScale > 0
end

local function today(): number
	return StyleRules.dayAt(Workspace:GetServerTimeNow())
end

-- The spin the button offers now: the free one while it's ready (and pays here), else a paid one.
local function spinKind(styles: StyleRules.Styles): string
	return if freeAllowed() and StyleRules.freeSpinReady(styles, today()) then "Free" else "Paid"
end

local function label(parent: Instance, text: string, position: UDim2, size: UDim2, maxSize: number): TextLabel
	local made = Kit.label(parent, text, size, maxSize)
	made.Position = position
	return made
end

function StyleRollView.new(parent: Instance, position: UDim2, size: UDim2): View
	local frame = Instance.new("Frame")
	frame.Name = "StyleRoll"
	frame.BackgroundTransparency = 1
	frame.Position = position
	frame.Size = size
	frame.Parent = parent

	-- Left: slots.
	local slots = Instance.new("ScrollingFrame")
	slots.Name = "Slots"
	slots.BackgroundTransparency = 1
	slots.BorderSizePixel = 0
	slots.Size = UDim2.fromScale(0.27, 1)
	slots.CanvasSize = UDim2.new()
	slots.AutomaticCanvasSize = Enum.AutomaticSize.Y
	slots.ScrollBarThickness = 4
	slots.Parent = frame
	local slotLayout = Kit.list(slots, Enum.FillDirection.Vertical, UDim.new(0, 6))
	slotLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	-- Middle: the equipped style and the Spin button.
	local middle = Instance.new("Frame")
	middle.BackgroundTransparency = 1
	middle.Position = UDim2.fromScale(0.29, 0)
	middle.Size = UDim2.fromScale(0.44, 1)
	middle.Parent = frame
	local currentTitle =
		label(middle, Localization.format("Roll.Current"), UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.06), 16)
	currentTitle.TextColor3 = Kit.Colors.Muted
	local nameLabel = label(middle, "", UDim2.fromScale(0, 0.06), UDim2.fromScale(1, 0.13), 44)
	nameLabel.Font = Kit.TitleFont
	local rarityLabel = label(middle, "", UDim2.fromScale(0, 0.19), UDim2.fromScale(1, 0.05), 16)
	local descLabel = label(middle, "", UDim2.fromScale(0.04, 0.25), UDim2.fromScale(0.92, 0.2), 16)
	descLabel.TextColor3 = Kit.Colors.Muted
	local resultLabel = label(middle, "", UDim2.fromScale(0, 0.48), UDim2.fromScale(1, 0.1), 20)
	resultLabel.TextColor3 = Kit.Colors.Accent
	local spinButton = Kit.button(middle, "", UDim2.fromScale(0.8, 0.14))
	spinButton.Position = UDim2.fromScale(0.1, 0.6)
	Kit.setChosen(spinButton, true)
	local freeLabel = label(middle, "", UDim2.fromScale(0, 0.76), UDim2.fromScale(1, 0.06), 16)
	local pityLabel = label(middle, "", UDim2.fromScale(0, 0.83), UDim2.fromScale(1, 0.06), 16)
	pityLabel.TextColor3 = Kit.Colors.Muted
	local infoLabel =
		label(middle, Localization.format("Roll.Info"), UDim2.fromScale(0, 0.9), UDim2.fromScale(1, 0.1), 14)
	infoLabel.TextColor3 = Kit.Colors.Muted

	-- Right: the odds, shown before every spin.
	local odds = Instance.new("Frame")
	odds.BackgroundTransparency = 1
	odds.Position = UDim2.fromScale(0.75, 0)
	odds.Size = UDim2.fromScale(0.25, 1)
	odds.Parent = frame
	local oddsLayout = Kit.list(odds, Enum.FillDirection.Vertical, UDim.new(0, 4))
	oddsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	local oddsTitle = Kit.label(odds, Localization.format("Roll.Odds"), UDim2.fromScale(1, 0.06), 18)
	oddsTitle.Font = Kit.TitleFont
	oddsTitle.LayoutOrder = 0
	for index, tier in StyleRules.tiers() do
		local row = Kit.label(
			odds,
			Localization.format(
				"Roll.Tier",
				{ Localization.format(`Rarity.{tier.Rarity}`), StyleRules.formatPercent(tier.Percent) }
			),
			UDim2.fromScale(1, 0.08),
			18
		)
		row.LayoutOrder = index * 2
		row.Font = Kit.TitleFont
		row.BackgroundColor3 = rarityColor(tier.Rarity)
		row.BackgroundTransparency = 0.15
		row.TextColor3 = Kit.Colors.Panel
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = row
		local names: { string } = {}
		for _, styleId in tier.Styles do
			table.insert(
				names,
				Localization.format(
					"Roll.StyleChance",
					{ styleName(styleId), StyleRules.formatPercent(StyleRules.chance(styleId)) }
				)
			)
		end
		local members = Kit.label(odds, table.concat(names, "  ·  "), UDim2.fromScale(1, 0.06), 14)
		members.LayoutOrder = index * 2 + 1
		members.TextColor3 = Kit.Colors.Muted
	end
	local paidNote = Kit.label(odds, "", UDim2.fromScale(1, 0.16), 14)
	paidNote.LayoutOrder = 100
	paidNote.TextColor3 = Kit.Colors.Muted

	local spinning = false
	local slotPrice: number? = nil -- the StyleSlot product's live price, once read

	local function showStyle(styleId: string)
		local rarity = Config.Styles.List[styleId].Rarity
		nameLabel.Text = styleName(styleId)
		nameLabel.TextColor3 = rarityColor(rarity)
		rarityLabel.Text = Localization.format(`Rarity.{rarity}`)
		rarityLabel.TextColor3 = rarityColor(rarity)
		descLabel.Text = Localization.format(`Style.{styleId}.Desc`)
	end

	local function slotCard(styles: StyleRules.Styles, index: number)
		local saved = styles.Slots[index]
		local styleId = if Config.Styles.List[saved] then saved else Config.Styles.Default
		local active = index == styles.Active
		local locked = styles.Locked[index] == true
		local card = Kit.button(slots, "", UDim2.new(1, -6, 0, SLOT_HEIGHT))
		card.LayoutOrder = index
		-- The equipped slot gets the accent outline only, so the rarity-colored name stays readable.
		Kit.setChosen(card, active)
		card.BackgroundColor3 = Kit.Colors.Button
		card.Activated:Connect(function()
			if not active then
				Net.fire("EquipStyleSlot", index)
			end
		end)
		local status = Localization.format(if active then "Roll.Equipped" else "Roll.TapToEquip")
		local color = rarityColor(Config.Styles.List[styleId].Rarity):ToHex()
		local text = Kit.label(
			card,
			`<font color="#{color}">{styleName(styleId)}</font>\n{status}`,
			UDim2.fromScale(0.62, 1),
			18
		)
		text.RichText = true
		text.TextXAlignment = Enum.TextXAlignment.Left
		local lock = Kit.button(
			card,
			Localization.format(if locked then "Roll.Locked" else "Roll.Lock"),
			UDim2.fromScale(0.36, 0.5)
		)
		lock.AnchorPoint = Vector2.new(1, 0.5)
		lock.Position = UDim2.fromScale(1, 0.5)
		lock.Font = Kit.BodyFont
		lock.BackgroundColor3 = if locked then Kit.Colors.Accent else Kit.Colors.Panel
		lock.Activated:Connect(function()
			Net.fire("LockStyleSlot", index, not locked)
		end)
	end

	local function buySlotCard(order: number)
		local product = Config.Monetization.Products.StyleSlot
		local available = product.Id > 0
		local price = if available
			then Localization.format("Shop.RobuxPrice", { slotPrice or product.PriceRobux })
			else Localization.format("Shop.ComingSoon")
		local card =
			Kit.button(slots, `{Localization.format("Roll.NewSlot")}\n{price}`, UDim2.new(1, -6, 0, SLOT_HEIGHT))
		card.LayoutOrder = order
		card.Font = Kit.BodyFont
		card.TextTransparency = if available then 0 else 0.45
		card.Activated:Connect(function()
			if available then
				MarketplaceService:PromptProductPurchase(player, product.Id)
			end
		end)
	end

	local function render()
		local data = DataController.get()
		if data == nil or spinning then
			return -- while the reel runs, the page waits for it to land
		end
		local styles = data.Styles
		for _, child in slots:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for index = 1, #styles.Slots do
			slotCard(styles, index)
		end
		if StyleRules.canAddSlot(styles) then
			buySlotCard(#styles.Slots + 1)
		end
		showStyle(StyleRules.equipped(styles))
		local kind = spinKind(styles)
		local reason = StyleRules.checkSpin(styles, kind, today(), data.Scrap, {
			Fighting = false,
			PaidAllowed = paidAllowed(),
			FreeAllowed = freeAllowed(),
		})
		spinButton.Text = if kind == "Free"
			then Localization.format("Roll.SpinFree")
			elseif paidAllowed() then Localization.format("Roll.SpinPaid", { Roll.SpinPrice })
			else Localization.format("Roll.NoSpin")
		spinButton.AutoButtonColor = reason == nil
		spinButton.TextTransparency = if reason == nil then 0 else 0.35
		local resetIn = Formulas.secondsUntilNextDay(Workspace:GetServerTimeNow(), Roll.FreeSpinResetHourUTC)
		freeLabel.Text = if not freeAllowed()
			then Localization.format("Roll.Error.PrivateServer")
			elseif StyleRules.freeSpinReady(styles, today()) then Localization.format("Roll.FreeReady")
			else Localization.format("Roll.FreeIn", { HudFormat.longClock(resetIn) })
		local pityArgs: { any } = { styles.Pity, Roll.PityAt, Localization.format(`Rarity.{Roll.PityRarity}`) }
		pityLabel.Text = Localization.format("Roll.Pity", pityArgs)
		paidNote.Text = if paidAllowed()
			then Localization.format("Roll.PaidNote", { Roll.SpinPrice })
			else Localization.format("Roll.Error.NotAllowed")
	end

	-- Runs the reel until `done()` says the answer is in and REEL_TIME has passed, then lands on `final()`.
	local function reel(done: () -> boolean, final: () -> string?)
		local rollable: { string } = {}
		for _, tier in StyleRules.tiers() do
			for _, styleId in tier.Styles do
				table.insert(rollable, styleId)
			end
		end
		local started = os.clock()
		local index = 0
		while true do
			local elapsed = os.clock() - started
			if elapsed >= REEL_TIME and done() then
				break
			end
			index = index % #rollable + 1
			showStyle(rollable[index])
			local t = math.clamp(elapsed / REEL_TIME, 0, 1)
			task.wait(REEL_START_STEP + (REEL_END_STEP - REEL_START_STEP) * t * t)
		end
		local landed = final()
		if landed then
			showStyle(landed)
		end
	end

	local function spin()
		local data = DataController.get()
		if spinning or data == nil then
			return
		end
		local kind = spinKind(data.Styles)
		local reason = StyleRules.checkSpin(data.Styles, kind, today(), data.Scrap, {
			Fighting = false,
			PaidAllowed = paidAllowed(),
			FreeAllowed = freeAllowed(),
		})
		if reason then
			resultLabel.Text = Localization.format(`Roll.Error.{reason}`)
			return
		end
		spinning = true
		resultLabel.Text = ""
		spinButton.Text = Localization.format("Roll.Spinning")
		local answered = false
		local ok: boolean, result: any = false, nil
		task.spawn(function()
			local called, spun, value = pcall(Net.invoke, "SpinStyle", kind)
			ok, result = called and spun == true, if called then value else nil
			answered = true
		end)
		reel(function(): boolean
			return answered
		end, function(): string?
			return if ok and type(result) == "table" then result.Style else nil
		end)
		spinning = false
		if ok and type(result) == "table" then
			local name = styleName(result.Style)
			resultLabel.Text = Localization.format(if result.Pity then "Roll.GotPity" else "Roll.Got", { name })
			resultLabel.TextColor3 = rarityColor(result.Rarity)
		else
			local why = if type(result) == "string" and table.find(StyleRules.Reasons, result)
				then result
				else "TryAgain"
			resultLabel.Text = Localization.format(`Roll.Error.{why}`)
			resultLabel.TextColor3 = Kit.Colors.Accent
		end
		render()
	end

	spinButton.Activated:Connect(spin)
	local product = Config.Monetization.Products.StyleSlot
	if product.Id > 0 then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(product.Id, Enum.InfoType.Product)
			end)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				slotPrice = info.PriceInRobux
			end
		end)
	end

	return { Frame = frame, render = render }
end

return StyleRollView
