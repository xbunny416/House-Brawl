--!strict
-- Round rewards (step 2.1): a round result plus the player's bonuses through Formulas.roundPayout.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Formulas = Roblox.require(Shared.Formulas)
local Payout = Roblox.require(Roblox.game.ServerScriptService.Server.Round.Payout)

local NO_BONUS = { IsVIP = false, IsPremium = false, FriendsInServer = 0, IsPrivateServer = false }

local function result(overrides: { [string]: any }): any
	local base = {
		Placement = 2,
		KOs = 0,
		KOScrap = 0,
		PerfectDodges = 0,
		Completed = true,
		ActiveSeconds = 120,
		AFKAtEnd = false,
	}
	for key, value in overrides do
		base[key] = value
	end
	return base
end

return {
	["a winner with 2 KOs: KO, win and completion rewards"] = function()
		local kos = Formulas.koScrap(0) + Formulas.koScrap(1)
		local payout = Payout.forResult(result({ Placement = 1, KOs = 2, KOScrap = kos }), NO_BONUS)
		expect.equal(payout.Scrap, kos + 50 + 15)
		expect.equal(payout.XP, 2 * 20 + 100 + 40)
	end,
	["2nd place gets Top 3; Perfect Dodges pay 5 Scrap each"] = function()
		local payout = Payout.forResult(result({ PerfectDodges = 2 }), NO_BONUS)
		expect.equal(payout.Scrap, 25 + 15 + 10)
		expect.equal(payout.XP, 50 + 40)
	end,
	["under 60 s of active play: only KO and Perfect Dodge rewards"] = function()
		local payout = Payout.forResult(result({ Placement = 1, KOs = 1, KOScrap = 10, ActiveSeconds = 59 }), NO_BONUS)
		expect.equal(payout.Scrap, 10)
		expect.equal(payout.XP, 20)
	end,
	["AFK at the end pays nothing"] = function()
		local payout = Payout.forResult(result({ Placement = 1, AFKAtEnd = true }), NO_BONUS)
		expect.equal(payout.Scrap + payout.XP, 0)
	end,
	["bonuses: Premium +10% Scrap, friends +XP, private servers half"] = function()
		local base = Payout.forResult(result({}), NO_BONUS)
		local premium = Payout.forResult(result({}), {
			IsVIP = false,
			IsPremium = true,
			FriendsInServer = 2,
			IsPrivateServer = false,
		})
		expect.equal(premium.Scrap, math.floor(base.Scrap * 1.1 + 0.5))
		expect.equal(premium.XP, math.floor(base.XP * 1.2 + 0.5))
		local private = Payout.forResult(result({}), {
			IsVIP = false,
			IsPremium = false,
			FriendsInServer = 0,
			IsPrivateServer = true,
		})
		expect.equal(private.Scrap, math.floor(base.Scrap * 0.5 + 0.5))
	end,
}
