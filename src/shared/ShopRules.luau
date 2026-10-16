--!strict
--[[
	ShopRules — what the Shop sells and what it costs (pure; shared so the Shop shows the price the server charges).
	Styles sell for Config.Styles.List[id].Price (the default style is free and never sold). Cosmetics sell for their
	Price, except Exclusive (VIP / Premium) and Robux-only items, which are never sold for Scrap.
	Daily rotation (Config.Cosmetics.DailyRotation): every day (UTC, from ResetHourUTC) the same Count cosmetics are
	picked for every player and server — a shuffle of the cosmetics for sale seeded by the day number — and sell at
	Discount off.
]]
local Config = require(script.Parent.Config)
local CosmeticRules = require(script.Parent.CosmeticRules)
local Formulas = require(script.Parent.Formulas)
local StyleRules = require(script.Parent.StyleRules)
local DataTemplate = require(script.Parent.Data.Template)

-- The player's saved data (a purchase reads Scrap, Styles.Owned and Cosmetics.Owned).
type Wallet = DataTemplate.PlayerData

local ShopRules = {}

-- Item kinds the Buy remote takes.
ShopRules.Kinds = { "Style", "Cosmetic" }
-- Why a purchase was refused; the Shop shows "Shop.Error.<Reason>". TryAgain is the client's own (no answer).
ShopRules.Reasons = { "NotForSale", "Owned", "NotEnoughScrap", "PriceChanged", "NotLoaded", "TryAgain" }

-- Park–Miller "minimal standard" generator: exact with doubles, so every machine picks the same daily items.
local MODULUS = 2147483647
local MULTIPLIER = 16807
local SEED_STEP = 7919 -- spreads consecutive day numbers apart
local WARMUP = 4 -- steps before the first pick, so nearby seeds diverge

local function nextState(state: number): number
	return state * MULTIPLIER % MODULUS
end

-- The Scrap price before any discount, or nil if the item is not sold for Scrap.
function ShopRules.basePrice(kind: string, id: string): number?
	if kind == "Style" then
		local style = Config.Styles.List[id]
		if style and id ~= Config.Styles.Default and style.Price > 0 then
			return style.Price
		end
	elseif kind == "Cosmetic" then
		local item = Config.Cosmetics.Items[id]
		local rarity = item and Config.Cosmetics.Rarities[item.Rarity]
		if item and rarity and item.Exclusive == nil and not rarity.RobuxOnly and item.Price > 0 then
			return item.Price
		end
	end
	return nil
end

-- Every cosmetic sold for Scrap, by id.
local function cosmeticsForSale(): { string }
	local ids: { string } = {}
	for id in Config.Cosmetics.Items do
		if ShopRules.basePrice("Cosmetic", id) then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

-- The cosmetics in the Daily tab on `day` (Formulas.dayNumber with DailyRotation.ResetHourUTC).
function ShopRules.dailyItems(day: number): { string }
	local pool = cosmeticsForSale()
	local count = math.min(Config.Cosmetics.DailyRotation.Count, #pool)
	local state = (day * SEED_STEP) % (MODULUS - 1) + 1
	for _ = 1, WARMUP do
		state = nextState(state)
	end
	local picked: { string } = {}
	for index = 1, count do
		state = nextState(state)
		local swap = index + state % (#pool - index + 1)
		pool[index], pool[swap] = pool[swap], pool[index]
		table.insert(picked, pool[index])
	end
	return picked
end

-- The day number for `unixTime` in the shop's calendar.
function ShopRules.dayAt(unixTime: number): number
	return Formulas.dayNumber(unixTime, Config.Cosmetics.DailyRotation.ResetHourUTC)
end

function ShopRules.isDaily(kind: string, id: string, day: number): boolean
	return kind == "Cosmetic" and table.find(ShopRules.dailyItems(day), id) ~= nil
end

-- What the item costs on `day` (the daily discount applied), or nil if it is not sold for Scrap.
function ShopRules.priceOf(kind: string, id: string, day: number): number?
	local price = ShopRules.basePrice(kind, id)
	if price and ShopRules.isDaily(kind, id, day) then
		return Formulas.discountedPrice(price, Config.Cosmetics.DailyRotation.Discount)
	end
	return price
end

function ShopRules.owns(wallet: Wallet, kind: string, id: string): boolean
	if kind == "Style" then
		return StyleRules.owns(wallet.Styles.Owned, id)
	end
	return CosmeticRules.owns(wallet.Cosmetics.Owned, id)
end

--[[
	Checks a purchase on `day`. Returns the price to charge, or nil and the reason it is refused. `expectedPrice` is
	the price the Shop showed: a different price (the daily rotation just changed) refuses with PriceChanged, so a
	player is never charged more than they agreed to.
]]
function ShopRules.check(
	wallet: Wallet,
	kind: string,
	id: string,
	day: number,
	expectedPrice: number?
): (number?, string?)
	local price = ShopRules.priceOf(kind, id, day)
	if price == nil then
		return nil, "NotForSale"
	end
	if ShopRules.owns(wallet, kind, id) then
		return nil, "Owned"
	end
	if expectedPrice ~= nil and expectedPrice ~= price then
		return nil, "PriceChanged"
	end
	if wallet.Scrap < price then
		return nil, "NotEnoughScrap"
	end
	return price, nil
end

return ShopRules
