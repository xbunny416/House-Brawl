--!strict
--[[
	CosmeticRules — cosmetic ownership and listing (pure; shared so the Locker / Shop UI agrees with the server).
	An item can be equipped only in its own slot and only when owned (saved Cosmetics.Owned).
]]
local Config = require(script.Parent.Config)
local Types = require(script.Parent.Config.Types)

local CosmeticRules = {}

local RARITY_ORDER: { [string]: number } = { Common = 1, Rare = 2, Premium = 3 }

function CosmeticRules.owns(owned: { [string]: boolean }, itemId: string): boolean
	return owned[itemId] == true
end

-- True if `itemId` is an item for `slot` that the player owns.
function CosmeticRules.canEquip(owned: { [string]: boolean }, slot: string, itemId: string): boolean
	local item = Config.Cosmetics.Items[itemId]
	return item ~= nil and item.Slot == slot and CosmeticRules.owns(owned, itemId)
end

-- Every item id for `slot`, cheapest rarity first, then by price, then by id.
function CosmeticRules.itemsIn(slot: string): { string }
	local ids: { string } = {}
	for id, item in Config.Cosmetics.Items do
		if item.Slot == slot then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a: string, b: string): boolean
		local itemA: Types.CosmeticItem, itemB: Types.CosmeticItem =
			Config.Cosmetics.Items[a], Config.Cosmetics.Items[b]
		local rankA, rankB = RARITY_ORDER[itemA.Rarity] or 99, RARITY_ORDER[itemB.Rarity] or 99
		if rankA ~= rankB then
			return rankA < rankB
		end
		if itemA.Price ~= itemB.Price then
			return itemA.Price < itemB.Price
		end
		return a < b
	end)
	return ids
end

-- Slots that have at least one item (the Locker only shows these).
function CosmeticRules.usedSlots(): { string }
	local slots: { string } = {}
	for _, slot in Config.Cosmetics.Slots do
		if #CosmeticRules.itemsIn(slot) > 0 then
			table.insert(slots, slot)
		end
	end
	return slots
end

return CosmeticRules
