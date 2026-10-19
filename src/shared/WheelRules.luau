--!strict
--[[
	WheelRules — the lobby spin wheel (owner's fix list, 2026-10-19: "a spin wheel … 1 free spin a day plus extra spins
	for Scrap"; Config.Retention.Wheel). Pure, shared so the wheel screen shows the same odds, prices and answers as
	the server (Services/WheelService).
	  * One free spin a day (Wheel.FreeDay, days from FreeSpinResetHourUTC); more cost SpinPrice Scrap. Paid spins are a
	    paid random item: only where PolicyService allows them (PaidAllowed). No spins in private servers (nothing is
	    earned there) or while fighting.
	  * Each prize's Percent is its exact chance; the segments are laid out in the order of Prizes.
	  * The Cosmetic prize is a random cosmetic sold for Scrap that the player doesn't own yet (CosmeticFallbackScrap
	    instead when they own them all).
]]
local Config = require(script.Parent.Config)
local Formulas = require(script.Parent.Formulas)
local ShopRules = require(script.Parent.ShopRules)

export type Checks = {
	Allowed: boolean, -- spins pay out here (not a private server)
	Fighting: boolean, -- in a round
	PaidAllowed: boolean, -- PolicyService allows paid random items for this player
}

local Wheel = Config.Retention.Wheel

local WheelRules = {}

WheelRules.Kinds = { "Free", "Paid" }
WheelRules.PrizeKinds = { "Coins", "XP", "StyleSpin", "Cosmetic" }
-- Why a spin was refused; the wheel screen shows "Wheel.Error.<Reason>". TryAgain is the client's own (no answer).
WheelRules.Reasons =
	{ "NotLoaded", "Fighting", "NoFreeSpin", "NotEnoughScrap", "NotAllowed", "PrivateServer", "TryAgain" }

function WheelRules.dayAt(unixTime: number): number
	return Formulas.dayNumber(unixTime, Wheel.FreeSpinResetHourUTC)
end

function WheelRules.freeSpinReady(wheel: { FreeDay: number }, day: number): boolean
	return wheel.FreeDay < day
end

-- The index (in Wheel.Prizes) of the prize a spin lands on, for `roll` in [0, 1): prizes laid out by their Percent.
function WheelRules.pick(roll: number): number
	local target = math.clamp(roll, 0, 1) * 100
	for index, prize in Wheel.Prizes do
		target -= prize.Percent
		if target < 0 then
			return index
		end
	end
	return #Wheel.Prizes
end

-- Why a spin of `kind` ("Free" / "Paid") on `day` would be refused, or nil if it may go ahead.
function WheelRules.checkSpin(
	wheel: { FreeDay: number },
	kind: string,
	day: number,
	scrap: number,
	checks: Checks
): string?
	if not checks.Allowed then
		return "PrivateServer"
	elseif checks.Fighting then
		return "Fighting"
	elseif kind == "Free" then
		return if WheelRules.freeSpinReady(wheel, day) then nil else "NoFreeSpin"
	elseif kind == "Paid" then
		if not checks.PaidAllowed then
			return "NotAllowed"
		elseif scrap < Wheel.SpinPrice then
			return "NotEnoughScrap"
		end
		return nil
	end
	return "TryAgain"
end

-- The cosmetic the Cosmetic prize gives for `roll` in [0, 1): one sold for Scrap that isn't in `owned`, or nil.
function WheelRules.cosmeticFor(owned: { [string]: boolean }, roll: number): string?
	local choices: { string } = {}
	for id in Config.Cosmetics.Items do
		if ShopRules.basePrice("Cosmetic", id) and owned[id] ~= true then
			table.insert(choices, id)
		end
	end
	if #choices == 0 then
		return nil
	end
	table.sort(choices)
	return choices[math.clamp(math.floor(roll * #choices) + 1, 1, #choices)]
end

return WheelRules
