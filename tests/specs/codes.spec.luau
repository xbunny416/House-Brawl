--!strict
-- Redeem codes (step 3.8): tidying, the checks, and the server-only code list.
local Roblox = require("../roblox")
local expect = require("../expect")

local Server = Roblox.game.ServerScriptService.Server
local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local CodeRules = Roblox.require(Server.Codes.CodeRules)
local ServerConfig = Roblox.require(Server.ServerConfig)

local NOW = 1_800_000_000
local CODES = {
	HELLO = { Scrap = 100 },
	OLD = { Scrap = 50, ExpiresAt = NOW - 1 },
	HAT = { Cosmetic = "ConeHat" },
}

return {
	["typed codes are tidied: spaces dropped, upper-case, capped"] = function()
		expect.equal(CodeRules.normalize("  hel lo "), "HELLO")
		expect.equal(#CodeRules.normalize(string.rep("a", 40)), CodeRules.MaxLength)
	end,
	["a known code works once; unknown and expired codes are refused"] = function()
		local key, code, reason = CodeRules.check("hello", {}, NOW, CODES)
		expect.equal(key, "HELLO")
		expect.equal(code and code.Scrap, 100)
		expect.equal(reason, nil)
		expect.equal(select(3, CodeRules.check("hello", { HELLO = true }, NOW, CODES)), "Redeemed")
		expect.equal(select(3, CodeRules.check("nope", {}, NOW, CODES)), "Invalid")
		expect.equal(select(3, CodeRules.check("   ", {}, NOW, CODES)), "Invalid")
		expect.equal(select(3, CodeRules.check("old", {}, NOW, CODES)), "Expired")
		expect.equal(select(2, CodeRules.check("hat", {}, NOW, CODES)).Cosmetic, "ConeHat")
	end,
	["every real code: an upper-case key that fits, a reward, a known cosmetic, whole Scrap"] = function()
		local count = 0
		for key, code in ServerConfig.Codes do
			count += 1
			expect.equal(CodeRules.normalize(key), key, `{key} is upper-case without spaces`)
			expect.truthy(string.match(key, "^[%u%d]+$"), `{key}: letters and digits only`)
			expect.truthy((code.Scrap or 0) > 0 or code.Cosmetic ~= nil, `{key} gives something`)
			if code.Scrap then
				expect.equal(code.Scrap, math.floor(code.Scrap), `{key} Scrap`)
			end
			if code.Cosmetic then
				expect.truthy(Config.Cosmetics.Items[code.Cosmetic], `{key}: unknown cosmetic {code.Cosmetic}`)
			end
		end
		expect.truthy(count >= 1, "at least one code")
	end,
}
