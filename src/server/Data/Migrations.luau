--!strict
--[[
	Data migrations. Steps[n] upgrades a profile from version n to n + 1. Pure functions on plain tables, so they are
	unit-tested in tests/specs/data.spec.luau. Never edit a released step; add a new one instead.
]]
local Migrations = {}

Migrations.Steps = {} :: { [number]: (data: { [string]: any }) -> () }

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
