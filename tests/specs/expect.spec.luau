--!strict
-- Sanity spec: proves the runner discovers specs and reports failures correctly.
local expect = require("../expect")

return {
	["equal passes on equal values"] = function()
		expect.equal(1 + 1, 2)
	end,
	["equal throws on different values"] = function()
		expect.equal(pcall(expect.equal, 1, 2), false)
	end,
	["near tolerates epsilon"] = function()
		expect.near(0.1 + 0.2, 0.3, 1e-9)
	end,
}
