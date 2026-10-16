--!strict
-- Cosmetics (step 2.3): the launch catalog, prices per rarity, visual data, ownership rules.
local Roblox = require("../roblox")
local roblox = require("@lune/roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local CosmeticRules = Roblox.require(Shared.CosmeticRules)

local Cosmetics = Config.Cosmetics

local function isHex(color: string): boolean
	return string.match(color, "^#%x%x%x%x%x%x$") ~= nil
end

local function isEnumItem(enum: any, name: string): boolean
	return (pcall(function()
		return enum[name]
	end))
end

return {
	["launch catalog: 6 skins, 6 hats, 4 dash trails, 4 KO effects, 4 victory emotes"] = function()
		expect.equal(#CosmeticRules.itemsIn("Skin"), 6)
		expect.equal(#CosmeticRules.itemsIn("Hat"), 6)
		expect.equal(#CosmeticRules.itemsIn("DashTrail"), 4)
		expect.equal(#CosmeticRules.itemsIn("KOEffect"), 4)
		expect.equal(#CosmeticRules.itemsIn("VictoryEmote"), 4)
	end,
	["every item has a known slot and rarity; Scrap prices sit inside their rarity's range"] = function()
		for id, item in Cosmetics.Items do
			expect.truthy(table.find(Cosmetics.Slots, item.Slot), `{id} slot`)
			local rarity = Cosmetics.Rarities[item.Rarity]
			expect.truthy(rarity, `{id} rarity`)
			if item.Exclusive then
				expect.truthy(item.Exclusive == "VIP" or item.Exclusive == "Premium", `{id} exclusive`)
				expect.equal(item.Price, 0, `{id} is never sold for Scrap`)
			else
				expect.truthy(not rarity.RobuxOnly, `{id} Scrap item with a Robux rarity`)
				expect.truthy(item.Price >= rarity.MinPrice and item.Price <= rarity.MaxPrice, `{id} price`)
			end
		end
	end,
	["visual data matches each slot"] = function()
		for id, item in Cosmetics.Items do
			if item.Slot == "Skin" then
				expect.equal(item.Colors and #item.Colors, 4, `{id} needs head, torso, arms, legs`)
			elseif item.Slot == "DashTrail" or item.Slot == "KOEffect" then
				expect.truthy(item.Colors and #item.Colors >= 2, `{id} colors`)
			elseif item.Slot == "Hat" or item.Slot == "BackItem" then
				expect.truthy(item.Parts and #item.Parts > 0, `{id} parts`)
				for _, part in item.Parts or {} do
					expect.truthy(isEnumItem(roblox.Enum.Material, part.Material), `{id} {part.Name} material`)
					expect.truthy(isEnumItem(roblox.Enum.PartType, part.Shape or "Block"), `{id} {part.Name} shape`)
					expect.truthy(isHex(part.Color), `{id} {part.Name} color`)
				end
			elseif item.Slot == "VictoryEmote" then
				expect.truthy(item.Emote, `{id} emote`)
			end
			for _, color in item.Colors or {} do
				expect.truthy(isHex(color), `{id} color {color}`)
			end
		end
	end,
	["items equip only in their own slot and only when owned"] = function()
		expect.equal(CosmeticRules.canEquip({}, "Hat", "ConeHat"), false, "not owned")
		expect.equal(CosmeticRules.canEquip({ ConeHat = true }, "Hat", "ConeHat"), true)
		expect.equal(CosmeticRules.canEquip({ ConeHat = true }, "Skin", "ConeHat"), false, "wrong slot")
		expect.equal(CosmeticRules.canEquip({ Nope = true }, "Hat", "Nope"), false, "unknown item")
	end,
	["items list cheapest rarity first, then by price; empty slots are hidden"] = function()
		local skins = CosmeticRules.itemsIn("Skin")
		expect.equal(skins[1], "RustBucket")
		expect.equal(skins[#skins], "PremiumGold")
		local used = CosmeticRules.usedSlots()
		expect.truthy(table.find(used, "Hat"), "hats shown")
		expect.equal(table.find(used, "NameplateFrame"), nil, "no name plates yet")
	end,
}
