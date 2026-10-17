--!strict
--[[
	MonetizationRules — what Robux and Roblox Premium unlock (pure; shared so the Shop agrees with the server).
	Bible §7, Config.Monetization.
	  * Perks are things a player has or not: the game passes (VIP, EmotePack) and Roblox Premium. A cosmetic whose
	    Exclusive is a perk is owned while the player has it; `ownershipChanges` lists what to grant and what to take
	    back once the perks are known (an unknown perk — a failed web call, an id of 0 — changes nothing).
	  * Robux cosmetics (Exclusive "Robux") come from the developer product whose Cosmetic names them and stay owned.
	  * Offers are the Shop's Robux tab (Config.Monetization.RobuxOrder): each a game pass or a product. An offer
	    with id 0 has not been created on the Creator Dashboard yet and can't be bought.
]]
local Config = require(script.Parent.Config)

export type Perk = "VIP" | "EmotePack" | "Premium"
export type Offer = {
	Key: string,
	Kind: "Pass" | "Product",
	Id: number,
	PriceRobux: number,
	Scrap: number?, -- a Scrap pack
	Cosmetic: string?, -- a Robux cosmetic
}

local MonetizationRules = {}

MonetizationRules.Perks = { "VIP", "EmotePack", "Premium" } :: { Perk }

function MonetizationRules.isPerk(name: string): boolean
	return table.find(MonetizationRules.Perks, name :: Perk) ~= nil
end

-- The cosmetics that come with `source` (a perk or "Robux"), sorted by id.
function MonetizationRules.itemsFrom(source: string): { string }
	local ids: { string } = {}
	for id, item in Config.Cosmetics.Items do
		if item.Exclusive == source then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

-- The offer for a game pass or product key, or nil.
function MonetizationRules.offer(key: string): Offer?
	local pass = Config.Monetization.GamePasses[key]
	if pass then
		return { Key = key, Kind = "Pass", Id = pass.Id, PriceRobux = pass.PriceRobux }
	end
	local product = Config.Monetization.Products[key]
	if product then
		return {
			Key = key,
			Kind = "Product",
			Id = product.Id,
			PriceRobux = product.PriceRobux,
			Scrap = product.Scrap,
			Cosmetic = product.Cosmetic,
		}
	end
	return nil
end

-- The Robux tab's offers, in RobuxOrder.
function MonetizationRules.offers(): { Offer }
	local list: { Offer } = {}
	for _, key in Config.Monetization.RobuxOrder do
		local entry = MonetizationRules.offer(key)
		if entry then
			table.insert(list, entry)
		end
	end
	return list
end

-- The GameStrings key of an offer's name: the perk a pass gives, a Robux cosmetic's name or a Scrap pack's name.
function MonetizationRules.nameKey(entry: Offer): string
	if entry.Kind == "Pass" then
		return `Perk.{entry.Key}`
	elseif entry.Cosmetic then
		return `Cosmetic.{entry.Cosmetic}.Name`
	end
	return `Robux.{entry.Key}.Name`
end

-- True once the pass / product exists on the Creator Dashboard (its id is set).
function MonetizationRules.isAvailable(entry: Offer): boolean
	return entry.Id > 0
end

-- The product key for a receipt's ProductId, or nil (an id of 0 never matches).
function MonetizationRules.productKeyFor(productId: number): string?
	if productId <= 0 then
		return nil
	end
	for key, product in Config.Monetization.Products do
		if product.Id == productId then
			return key
		end
	end
	return nil
end

-- The game pass key for a GamePassId, or nil (an id of 0 never matches).
function MonetizationRules.passKeyFor(passId: number): string?
	if passId <= 0 then
		return nil
	end
	for key, pass in Config.Monetization.GamePasses do
		if pass.Id == passId then
			return key
		end
	end
	return nil
end

-- The product key that sells a Robux cosmetic, or nil.
function MonetizationRules.productFor(cosmeticId: string): string?
	for key, product in Config.Monetization.Products do
		if product.Cosmetic == cosmeticId then
			return key
		end
	end
	return nil
end

--[[
	The cosmetics to grant and to take back, given what the player owns and the perks known so far (true / false;
	nil = unknown, which changes nothing). Robux cosmetics and Scrap items are never taken back.
]]
function MonetizationRules.ownershipChanges(
	owned: { [string]: boolean },
	perks: { [string]: boolean? }
): ({ string }, { string })
	local grant: { string }, revoke: { string } = {}, {}
	for _, perk in MonetizationRules.Perks do
		local has = perks[perk]
		if has ~= nil then
			for _, id in MonetizationRules.itemsFrom(perk) do
				if has and owned[id] ~= true then
					table.insert(grant, id)
				elseif not has and owned[id] == true then
					table.insert(revoke, id)
				end
			end
		end
	end
	return grant, revoke
end

return MonetizationRules
