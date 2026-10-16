--!strict
-- Shop (step 2.4): what is for sale, the daily rotation and its discount, purchase checks.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local Formulas = Roblox.require(Shared.Formulas)
local ShopRules = Roblox.require(Shared.ShopRules)

local Rotation = Config.Cosmetics.DailyRotation
local DAY = 20000 -- some day in 2024

local function wallet(scrap: number, styles: { [string]: boolean }?, cosmetics: { [string]: boolean }?)
	return {
		Scrap = scrap,
		Styles = { Owned = styles or { [Config.Styles.Default] = true } },
		Cosmetics = { Owned = cosmetics or {} },
	}
end

-- A cosmetic for sale that is not in the given day's rotation.
local function regularItem(day: number): string
	local daily = ShopRules.dailyItems(day)
	for id in Config.Cosmetics.Items do
		if ShopRules.basePrice("Cosmetic", id) and not table.find(daily, id) then
			return id
		end
	end
	error("no regular item")
end

return {
	["styles sell for their price; the default style is never sold"] = function()
		expect.equal(ShopRules.basePrice("Style", "Slugger"), 1500)
		expect.equal(ShopRules.basePrice("Style", "Scrapper"), 3000)
		expect.equal(ShopRules.basePrice("Style", "Wrecker"), 6000)
		expect.equal(ShopRules.basePrice("Style", Config.Styles.Default), nil)
		expect.equal(ShopRules.basePrice("Style", "Nope"), nil)
	end,
	["cosmetics sell for their price; VIP / Premium exclusives never do"] = function()
		expect.equal(ShopRules.basePrice("Cosmetic", "ConeHat"), 300)
		expect.equal(ShopRules.basePrice("Cosmetic", "PremiumGold"), nil)
		expect.equal(ShopRules.basePrice("Cosmetic", "GoldTrail"), nil)
		expect.equal(ShopRules.basePrice("Cosmetic", "Nope"), nil)
		expect.equal(ShopRules.basePrice("Hat", "ConeHat"), nil, "unknown kind")
		for id, item in Config.Cosmetics.Items do
			expect.equal(ShopRules.basePrice("Cosmetic", id) ~= nil, item.Exclusive == nil, id)
		end
	end,
	["daily deals: Count different items for sale, the same for everyone on a day"] = function()
		for day = DAY, DAY + 60 do
			local items = ShopRules.dailyItems(day)
			expect.equal(#items, Rotation.Count, `day {day}`)
			local seen: { [string]: boolean } = {}
			for _, id in items do
				expect.truthy(ShopRules.basePrice("Cosmetic", id), `{id} is for sale`)
				expect.equal(seen[id], nil, `{id} twice on day {day}`)
				seen[id] = true
			end
			expect.equal(table.concat(ShopRules.dailyItems(day), ","), table.concat(items, ","), "deterministic")
		end
	end,
	["daily deals change from day to day and cover the catalog over time"] = function()
		local changed = 0
		local offered: { [string]: boolean } = {}
		for day = DAY, DAY + 59 do
			local today = table.concat(ShopRules.dailyItems(day), ",")
			if today ~= table.concat(ShopRules.dailyItems(day + 1), ",") then
				changed += 1
			end
			for _, id in ShopRules.dailyItems(day) do
				offered[id] = true
			end
		end
		expect.truthy(changed >= 58, `deals changed on {changed} of 60 days`)
		for id in Config.Cosmetics.Items do
			if ShopRules.basePrice("Cosmetic", id) then
				expect.truthy(offered[id], `{id} never in the daily deals over 60 days`)
			end
		end
	end,
	["the shop's day turns at the reset hour (UTC)"] = function()
		local start = (DAY * 86400) + Rotation.ResetHourUTC * 3600
		expect.equal(ShopRules.dayAt(start - 1), DAY - 1)
		expect.equal(ShopRules.dayAt(start), DAY)
		expect.equal(ShopRules.dayAt(start + 86399), DAY)
	end,
	["daily deals cost Discount less; styles are never discounted"] = function()
		for _, id in ShopRules.dailyItems(DAY) do
			local base = ShopRules.basePrice("Cosmetic", id) :: number
			expect.equal(ShopRules.priceOf("Cosmetic", id, DAY), Formulas.discountedPrice(base, Rotation.Discount), id)
			expect.truthy(ShopRules.isDaily("Cosmetic", id, DAY), id)
		end
		local regular = regularItem(DAY)
		expect.equal(ShopRules.priceOf("Cosmetic", regular, DAY), ShopRules.basePrice("Cosmetic", regular))
		expect.equal(ShopRules.priceOf("Style", "Slugger", DAY), 1500)
		expect.equal(ShopRules.isDaily("Style", "Slugger", DAY), false)
		expect.equal(ShopRules.priceOf("Cosmetic", "GoldTrail", DAY), nil)
	end,
	["purchase check: price to pay, or why not"] = function()
		local regular = regularItem(DAY)
		local price = ShopRules.basePrice("Cosmetic", regular) :: number
		local rich = wallet(100000)
		expect.equal(ShopRules.check(rich, "Cosmetic", regular, DAY, price), price)
		expect.equal(ShopRules.check(rich, "Cosmetic", regular, DAY), price, "no expected price given")
		expect.equal(ShopRules.check(rich, "Style", "Wrecker", DAY, 6000), 6000)

		local function reason(...): string?
			local _, why = ShopRules.check(...)
			return why
		end
		expect.equal(reason(rich, "Cosmetic", "GoldTrail", DAY, 0), "NotForSale")
		expect.equal(reason(rich, "Style", Config.Styles.Default, DAY, 0), "NotForSale")
		expect.equal(reason(wallet(100000, nil, { [regular] = true }), "Cosmetic", regular, DAY, price), "Owned")
		expect.equal(reason(wallet(100000, { Slugger = true }), "Style", "Slugger", DAY, 1500), "Owned")
		expect.equal(reason(rich, "Cosmetic", regular, DAY, price + 1), "PriceChanged")
		expect.equal(reason(wallet(price - 1), "Cosmetic", regular, DAY, price), "NotEnoughScrap")
		expect.equal(ShopRules.check(wallet(price), "Cosmetic", regular, DAY, price), price, "exactly enough")
	end,
	["a deal bought just after the rotation changed is refused, not overcharged"] = function()
		local checked = 0
		for _, id in ShopRules.dailyItems(DAY) do
			if not ShopRules.isDaily("Cosmetic", id, DAY + 1) then
				local shown = ShopRules.priceOf("Cosmetic", id, DAY) :: number
				local _, why = ShopRules.check(wallet(100000), "Cosmetic", id, DAY + 1, shown)
				expect.equal(why, "PriceChanged", id)
				checked += 1
			end
		end
		expect.truthy(checked > 0, "every deal stayed for the next day")
	end,
	["every refusal reason is a known one"] = function()
		for _, reason in { "NotForSale", "Owned", "NotEnoughScrap", "PriceChanged", "NotLoaded", "TryAgain" } do
			expect.truthy(table.find(ShopRules.Reasons, reason), reason)
		end
	end,
}
