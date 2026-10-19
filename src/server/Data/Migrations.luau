--!strict
--[[
	Data migrations. Steps[n] upgrades a profile from version n to n + 1. Pure functions on plain tables, so they are
	unit-tested in tests/specs/data.spec.luau. Never edit a released step; add a new one instead.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Migrations = {}

Migrations.Steps = {} :: { [number]: (data: { [string]: any }) -> () }

-- 1 → 2 (owner's fix list, 2026-10-19: the style roll): owned styles become slots. The equipped style (if it still
-- exists) goes into slot 1, so nobody loses what they fight with; the other owned styles are dropped.
Migrations.Steps[1] = function(data)
	local old = if type(data.Styles) == "table" then data.Styles else {}
	local equipped = if type(old.Equipped) == "string" and Config.Styles.List[old.Equipped]
		then old.Equipped
		else Config.Styles.Default
	local slots: { string }, locked: { boolean } = { equipped }, { false }
	for _ = 2, Config.Styles.Roll.Slots.Start do
		table.insert(slots, Config.Styles.Default)
		table.insert(locked, false)
	end
	data.Styles = {
		Slots = slots,
		Locked = locked,
		Active = 1,
		Equipped = equipped,
		Pity = 0,
		FreeSpinDay = -1,
	}
end

-- Upgrades `data` in place to `targetVersion`. Returns false if a step is missing (data is left as far as it got).
function Migrations.run(data: { [string]: any }, targetVersion: number): boolean
	local version = if type(data.Version) == "number" then data.Version else 1
	while version < targetVersion do
		local step = Migrations.Steps[version]
		if not step then
			return false
		end
		step(data)
		version += 1
		data.Version = version
	end
	return true
end

return Migrations
