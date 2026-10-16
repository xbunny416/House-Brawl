--!strict
--[[
	Guard — argument validators for remote calls. Never trust the client: every value a client sends is checked
	against one of these before any game code sees it. Each check returns true when the value is acceptable.
]]
export type Check = (value: unknown) -> boolean

local Guard = {}

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Finite number (rejects NaN and infinities).
function Guard.number(value: unknown): boolean
	return type(value) == "number" and isFinite(value)
end

-- Finite number within [min, max].
function Guard.range(min: number, max: number): Check
	return function(value: unknown): boolean
		return type(value) == "number" and isFinite(value) and value >= min and value <= max
	end
end

-- Whole number within [min, max].
function Guard.integer(min: number, max: number): Check
	return function(value: unknown): boolean
		return type(value) == "number" and value == math.floor(value) and value >= min and value <= max
	end
end

function Guard.boolean(value: unknown): boolean
	return type(value) == "boolean"
end

-- String no longer than maxLength bytes.
function Guard.string(maxLength: number): Check
	return function(value: unknown): boolean
		return type(value) == "string" and #value <= maxLength
	end
end

-- One of a fixed set of strings (e.g. map or style ids).
function Guard.oneOf(options: { string }): Check
	local allowed: { [string]: boolean } = {}
	for _, option in options do
		allowed[option] = true
	end
	return function(value: unknown): boolean
		return type(value) == "string" and allowed[value] == true
	end
end

-- String that is a key of `map` (e.g. Config.Styles.List).
function Guard.keyOf(map: { [string]: any }): Check
	return function(value: unknown): boolean
		return type(value) == "string" and map[value] ~= nil
	end
end

-- Vector3 with finite components, optionally no longer than maxMagnitude.
function Guard.vector3(maxMagnitude: number?): Check
	return function(value: unknown): boolean
		if typeof(value) ~= "Vector3" then
			return false
		end
		local v = value :: Vector3
		if not (isFinite(v.X) and isFinite(v.Y) and isFinite(v.Z)) then
			return false
		end
		return maxMagnitude == nil or v.Magnitude <= maxMagnitude
	end
end

-- Instance of the given class (IsA), still parented to the game.
function Guard.instance(className: string): Check
	return function(value: unknown): boolean
		return typeof(value) == "Instance" and (value :: Instance):IsA(className) and (value :: Instance).Parent ~= nil
	end
end

-- Allows nil in addition to whatever `check` accepts.
function Guard.optional(check: Check): Check
	return function(value: unknown): boolean
		return value == nil or check(value)
	end
end

-- Accepts a value that passes at least one of `checks`.
function Guard.anyOf(...: Check): Check
	local checks = { ... }
	return function(value: unknown): boolean
		for _, check in checks do
			if check(value) then
				return true
			end
		end
		return false
	end
end

-- Validates a packed argument list against a list of checks. Extra arguments are rejected.
function Guard.args(checks: { Check }, args: { n: number, [number]: unknown }): boolean
	if args.n > #checks then
		return false
	end
	for index, check in checks do
		if not check(args[index]) then
			return false
		end
	end
	return true
end

return Guard
