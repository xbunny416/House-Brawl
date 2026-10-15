--!strict
-- Rate limiting and argument validation for remotes.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local RateLimiter = Roblox.require(Shared.Util.RateLimiter)
local Guard = Roblox.require(Shared.Net.Guard)

local function pack(...: any): { n: number, [number]: any }
	return table.pack(...)
end

return {
	["rate limiter allows a burst then blocks"] = function()
		local limiter = RateLimiter.new(2, 3)
		expect.equal(limiter:allow("p", 0), true)
		expect.equal(limiter:allow("p", 0), true)
		expect.equal(limiter:allow("p", 0), true)
		expect.equal(limiter:allow("p", 0), false)
	end,
	["rate limiter refills over time and per key"] = function()
		local limiter = RateLimiter.new(2, 1)
		expect.equal(limiter:allow("a", 0), true)
		expect.equal(limiter:allow("a", 0.2), false)
		expect.equal(limiter:allow("a", 0.5), true)
		expect.equal(limiter:allow("b", 0.5), true)
		limiter:remove("a")
		expect.equal(limiter:allow("a", 0.5), true)
	end,
	["number rejects NaN and infinity"] = function()
		expect.equal(Guard.number(1.5), true)
		expect.equal(Guard.number(0 / 0), false)
		expect.equal(Guard.number(math.huge), false)
		expect.equal(Guard.number("1"), false)
	end,
	["range, integer and string limits"] = function()
		expect.equal(Guard.range(0, 1)(0.5), true)
		expect.equal(Guard.range(0, 1)(2), false)
		expect.equal(Guard.integer(1, 3)(2), true)
		expect.equal(Guard.integer(1, 3)(2.5), false)
		expect.equal(Guard.string(3)("abc"), true)
		expect.equal(Guard.string(3)("abcd"), false)
	end,
	["oneOf, keyOf and optional"] = function()
		expect.equal(Guard.oneOf({ "Classic", "Casual" })("Casual"), true)
		expect.equal(Guard.oneOf({ "Classic", "Casual" })("Hardcore"), false)
		expect.equal(Guard.keyOf({ Brawler = true })("Brawler"), true)
		expect.equal(Guard.keyOf({ Brawler = true })("__index"), false)
		expect.equal(Guard.optional(Guard.boolean)(nil), true)
		expect.equal(Guard.optional(Guard.boolean)(1), false)
	end,
	["args rejects extra or invalid arguments"] = function()
		local checks = { Guard.number, Guard.optional(Guard.boolean) }
		expect.equal(Guard.args(checks, pack(1)), true)
		expect.equal(Guard.args(checks, pack(1, true)), true)
		expect.equal(Guard.args(checks, pack(1, true, "extra")), false)
		expect.equal(Guard.args(checks, pack("1")), false)
		expect.equal(Guard.args({}, pack()), true)
	end,
}
