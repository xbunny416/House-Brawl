--!strict
--[[
	StyleRules — fighting styles come from the style roll (owner's fix list, 2026-10-19; Config.Styles.Roll). Pure,
	shared so the Inventory shows the same odds, prices and answers as the server (Services/StyleService).
	  * A player has slots (Styles.Slots), one of them equipped (Active). A spin puts a random style into the
	    equipped slot, unless that slot is locked. Slot 1 is everyone's; more are bought with Robux.
	  * Odds: each rarity in Roll.Odds has that chance in percent, shared equally by its styles; rarities missing from
	    Odds (the default style's) are never rolled. Pity: the PityAt-th spin since the last PityRarity style is one
	    for sure.
	  * One free spin a day (FreeSpinDay, days from FreeSpinResetHourUTC); more cost SpinPrice Scrap. Paid spins are a
	    paid random item: the server only allows them where PolicyService does (PaidAllowed).
]]
local Config = require(script.Parent.Config)
local DataTemplate = require(script.Parent.Data.Template)
local Formulas = require(script.Parent.Formulas)

export type Styles = DataTemplate.StyleData
export type Tier = { Rarity: string, Percent: number, Styles: { string } }
export type SpinChecks = {
	Fighting: boolean, -- in a round (styles don't change mid-fight)
	PaidAllowed: boolean, -- PolicyService allows paid random items for this player
	FreeAllowed: boolean, -- free spins pay out here (not in a private server)
}

local Roll = Config.Styles.Roll

local StyleRules = {}

StyleRules.Kinds = { "Free", "Paid" }
-- Why a spin was refused; the Inventory shows "Roll.Error.<Reason>". TryAgain is the client's own (no answer).
StyleRules.Reasons = {
	"NotLoaded",
	"Fighting",
	"SlotLocked",
	"NoFreeSpin",
	"NotEnoughScrap",
	"NotAllowed",
	"PrivateServer",
	"TryAgain",
}

-- The rollable rarities, most to least common (Roll.RarityOrder), each with its chance and its styles.
function StyleRules.tiers(): { Tier }
	local tiers: { Tier } = {}
	for _, rarity in Roll.RarityOrder do
		local percent = Roll.Odds[rarity]
		if percent and percent > 0 then
			local styles: { string } = {}
			for _, styleId in Config.Styles.Order do
				if Config.Styles.List[styleId].Rarity == rarity then
					table.insert(styles, styleId)
				end
			end
			if #styles > 0 then
				table.insert(tiers, { Rarity = rarity, Percent = percent, Styles = styles })
			end
		end
	end
	return tiers
end

-- A style's chance per spin in percent (0 for styles that are never rolled).
function StyleRules.chance(styleId: string): number
	for _, tier in StyleRules.tiers() do
		if table.find(tier.Styles, styleId) then
			return tier.Percent / #tier.Styles
		end
	end
	return 0
end

-- True if the next spin is guaranteed to be a PityRarity style.
function StyleRules.isPitySpin(pity: number): boolean
	return pity + 1 >= Roll.PityAt
end

--[[
	The style a spin lands on, for `roll` in [0, 1): styles laid out by their chance, in tier order. A pity spin
	picks among the PityRarity styles only.
]]
function StyleRules.pick(roll: number, pity: number): string
	local guaranteed = StyleRules.isPitySpin(pity)
	local weights: { { Id: string, Weight: number } } = {}
	local total = 0
	for _, tier in StyleRules.tiers() do
		if not guaranteed or tier.Rarity == Roll.PityRarity then
			for _, styleId in tier.Styles do
				local weight = if guaranteed then 1 else tier.Percent / #tier.Styles
				table.insert(weights, { Id = styleId, Weight = weight })
				total += weight
			end
		end
	end
	local target = math.clamp(roll, 0, 1) * total
	for _, entry in weights do
		target -= entry.Weight
		if target < 0 then
			return entry.Id
		end
	end
	return weights[#weights].Id
end

-- The pity count after a spin that landed on `styleId`.
function StyleRules.nextPity(pity: number, styleId: string): number
	return if Config.Styles.List[styleId].Rarity == Roll.PityRarity then 0 else pity + 1
end

-- The free-spin day number for `unixTime`.
function StyleRules.dayAt(unixTime: number): number
	return Formulas.dayNumber(unixTime, Roll.FreeSpinResetHourUTC)
end

function StyleRules.freeSpinReady(styles: Styles, day: number): boolean
	return styles.FreeSpinDay < day
end

-- The equipped style: the active slot's, or the default style if that slot holds nothing known.
function StyleRules.equipped(styles: Styles): string
	local styleId = styles.Slots[styles.Active]
	return if styleId and Config.Styles.List[styleId] then styleId else Config.Styles.Default
end

function StyleRules.isSlot(styles: Styles, index: number): boolean
	return index >= 1 and index <= #styles.Slots and index == math.floor(index)
end

function StyleRules.canAddSlot(styles: Styles): boolean
	return #styles.Slots < Roll.Slots.Max
end

-- Why a spin of `kind` ("Free" / "Paid") on `day` would be refused, or nil if it may go ahead.
function StyleRules.checkSpin(styles: Styles, kind: string, day: number, scrap: number, checks: SpinChecks): string?
	if checks.Fighting then
		return "Fighting"
	elseif styles.Locked[styles.Active] == true then
		return "SlotLocked"
	elseif kind == "Free" then
		if not checks.FreeAllowed then
			return "PrivateServer"
		elseif not StyleRules.freeSpinReady(styles, day) then
			return "NoFreeSpin"
		end
	elseif kind == "Paid" then
		if not checks.PaidAllowed then
			return "NotAllowed"
		elseif scrap < Roll.SpinPrice then
			return "NotEnoughScrap"
		end
	else
		return "TryAgain"
	end
	return nil
end

-- Puts the rolled style into the equipped slot (mutates `styles`; the spin was checked first).
function StyleRules.applySpin(styles: Styles, kind: string, day: number, styleId: string)
	styles.Slots[styles.Active] = styleId
	styles.Equipped = styleId
	styles.Pity = StyleRules.nextPity(styles.Pity, styleId)
	if kind == "Free" then
		styles.FreeSpinDay = day
	end
end

-- Equips slot `index` (mutates `styles`; the index was checked with isSlot).
function StyleRules.equipSlot(styles: Styles, index: number)
	styles.Active = index
	styles.Equipped = StyleRules.equipped(styles)
end

-- Adds a slot holding the default style (mutates `styles`; checked with canAddSlot).
function StyleRules.addSlot(styles: Styles)
	table.insert(styles.Slots, Config.Styles.Default)
	table.insert(styles.Locked, false)
end

-- A chance as the odds list shows it: whole numbers plain ("70"), others with up to 3 decimals ("2.5", "0.015").
function StyleRules.formatPercent(percent: number): string
	if percent == math.floor(percent) then
		return string.format("%d", percent)
	end
	local text = string.format("%.3f", percent)
	text = string.gsub(text, "0+$", "")
	return text
end

return StyleRules
