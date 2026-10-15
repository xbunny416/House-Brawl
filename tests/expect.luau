--!strict
-- Minimal assertion helpers for Lune specs.
local expect = {}

function expect.equal(actual: any, expected: any, label: string?)
	if actual ~= expected then
		error(`{label or "value"}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
	end
end

function expect.near(actual: number, expected: number, epsilon: number?, label: string?)
	if math.abs(actual - expected) > (epsilon or 1e-6) then
		error(`{label or "value"}: expected ~{expected}, got {actual}`, 2)
	end
end

function expect.truthy(value: any, label: string?)
	if not value then
		error(`{label or "value"}: expected truthy, got {tostring(value)}`, 2)
	end
end

return expect
