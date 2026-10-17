--!strict
--[[
	VfxRules — the pure choices behind the effects (no instances, so Lune specs test them): how many hit sparks a hit
	throws, and which screen-edge flash a knock-out shows on this client.
]]
export type SparkSettings = { MinCount: number, MaxCount: number, MaxPercent: number }

local VfxRules = {}

-- Sparks for a hit that left the victim at `percent`: MinCount at 0%, rising linearly to MaxCount at MaxPercent.
-- None with Low Graphics.
function VfxRules.sparkCount(percent: number, settings: SparkSettings, lowGraphics: boolean): number
	if lowGraphics then
		return 0
	end
	local t = math.clamp(percent / settings.MaxPercent, 0, 1)
	return math.floor(settings.MinCount + (settings.MaxCount - settings.MinCount) * t + 0.5)
end

-- The screen-edge flash a KO shows here: "KnockedOut" if it was this player, "Scored" if they made it, else nil.
function VfxRules.koFlash(isVictim: boolean, isKiller: boolean): string?
	if isVictim then
		return "KnockedOut"
	elseif isKiller then
		return "Scored"
	end
	return nil
end

return VfxRules
