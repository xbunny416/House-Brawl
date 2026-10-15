--!strict
-- Recursively freezes a table (and every nested table) in place, so shared config data can never be mutated.
local Freeze = {}

function Freeze.deep<T>(value: T): T
	if type(value) == "table" and not table.isfrozen(value :: any) then
		for _, child in value :: any do
			Freeze.deep(child)
		end
		table.freeze(value :: any)
	end
	return value
end

return Freeze
