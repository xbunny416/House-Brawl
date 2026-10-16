--!strict
--[[
	StyleRules — which fighting styles a player has (pure; shared so the Locker / Shop UI agrees with the server).
	The default style is always owned. A style unlocks for free once the player reaches its UnlockLevel; buying it
	with Scrap (Config.Styles.List[id].Price) comes with the Shop (step 2.4).
]]
local Config = require(script.Parent.Config)

local StyleRules = {}

-- True if `owned` (saved Styles.Owned) includes the style; the default style always counts.
function StyleRules.owns(owned: { [string]: boolean }, styleId: string): boolean
	return styleId == Config.Styles.Default or owned[styleId] == true
end

-- Every style a player at `level` has unlocked by level, in Config.Styles.Order.
function StyleRules.unlockedAt(level: number): { string }
	local unlocked: { string } = {}
	for _, styleId in Config.Styles.Order do
		local style = Config.Styles.List[styleId]
		if style and level >= style.UnlockLevel then
			table.insert(unlocked, styleId)
		end
	end
	return unlocked
end

return StyleRules
