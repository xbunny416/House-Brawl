--!strict
-- Formula values checked against the numbers in docs/PROJECT_BIBLE.md.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local F = Roblox.require(Shared.Formulas)

local function payout(overrides: { [string]: any }): any
	local input = {
		KOScrap = 0,
		KOs = 0,
		PerfectDodges = 0,
		Placement = nil,
		Completed = false,
		ActiveSeconds = 180,
		AFKAtEnd = false,
		IsVIP = false,
		IsPremium = false,
		FriendsInServer = 0,
		IsPrivateServer = false,
	}
	for key, value in overrides do
		(input :: any)[key] = value
	end
	return F.roundPayout(input)
end

return {
	["knockback: base at 0%"] = function()
		expect.equal(F.knockbackForce(0, 1, "Classic"), 30)
	end,
	["knockback: 100% punch in Classic = 100"] = function()
		expect.equal(F.knockbackForce(100, 1, "Classic"), 100)
	end,
	["knockback: Casual multiplies by 1.15"] = function()
		expect.near(F.knockbackForce(100, 1, "Casual"), 115)
	end,
	["knockback: shove scale 1.6 at 50%"] = function()
		expect.near(F.knockbackForce(50, 1.6, "Classic"), 86)
	end,
	["knockback: extra multiplier applies last"] = function()
		expect.near(F.knockbackForce(0, 1, "Classic", 1.25), 37.5)
	end,
	["hitstun: base, growth and cap"] = function()
		expect.near(F.hitstun(0), 0.15)
		expect.near(F.hitstun(100), 0.35)
		expect.near(F.hitstun(300), 0.75)
		expect.near(F.hitstun(1000), 0.8)
	end,
	["trail only above 100%"] = function()
		expect.equal(F.leavesTrail(100), false)
		expect.equal(F.leavesTrail(101), true)
	end,
	["classic percent = damage taken * 1.5"] = function()
		expect.equal(F.classicPercent(100), 0)
		expect.equal(F.classicPercent(60), 60)
		expect.equal(F.classicPercent(0), 150)
		expect.equal(F.classicPercent(-20), 150)
	end,
	["casual percent caps at 300"] = function()
		expect.equal(F.addCasualPercent(295, 11), 300)
		expect.equal(F.addCasualPercent(10, 6), 16)
	end,
	["brawler punch matches base"] = function()
		local punch = F.resolveAttack("Brawler", "Punch")
		expect.equal(punch.Damage, 8)
		expect.equal(punch.Percent, 6)
		expect.equal(punch.Hitbox.Z, 5)
		expect.near(punch.Cooldown, 0.35)
	end,
	["slugger: x1.15 damage, +2 reach, x0.8 speed"] = function()
		local punch = F.resolveAttack("Slugger", "Punch")
		expect.near(punch.Damage, 9.2)
		expect.equal(punch.Hitbox.Z, 7)
		expect.near(punch.Cooldown, 0.4375)
		local shove = F.resolveAttack("Slugger", "Shove")
		expect.near(shove.Damage, 16.1)
		expect.equal(shove.Hitbox.Z, 8)
	end,
	["scrapper: wide sweep, x0.9 damage, shove KB x1.1"] = function()
		local punch = F.resolveAttack("Scrapper", "Punch")
		expect.equal(punch.Hitbox.X, 7)
		expect.equal(punch.Hitbox.Y, 4)
		expect.near(punch.Damage, 7.2)
		expect.near(F.resolveAttack("Scrapper", "Shove").KnockbackScale, 1.76)
	end,
	["wrecker: punch x0.95, shove is a 0.2 s parry"] = function()
		expect.near(F.resolveAttack("Wrecker", "Punch").Damage, 7.6)
		local shove = F.resolveAttack("Wrecker", "Shove")
		expect.truthy(shove.Parry, "parry")
		expect.near((shove.Parry :: any).Window, 0.2)
	end,
	["punch chain: 3rd hit x1.5 KB and 0.8 s cooldown"] = function()
		expect.equal(F.punchChainMultiplier(1), 1)
		expect.equal(F.punchChainMultiplier(3), 1.5)
		expect.near(F.punchCooldown(2, 1), 0.35)
		expect.near(F.punchCooldown(3, 1), 0.8)
		expect.near(F.punchCooldown(3, 0.8), 1)
	end,
	["shove charge scales to x1.5 at 0.8 s"] = function()
		expect.equal(F.shoveChargeMultiplier(0), 1)
		expect.near(F.shoveChargeMultiplier(0.4), 1.25)
		expect.near(F.shoveChargeMultiplier(0.8), 1.5)
		expect.near(F.shoveChargeMultiplier(5), 1.5)
	end,
	["perfect dodge window is the last 0.15 s"] = function()
		expect.equal(F.isPerfectDodge(10, 10.1), true)
		expect.equal(F.isPerfectDodge(10, 10.2), false)
		expect.equal(F.isPerfectDodge(10, 9.9), false)
		expect.equal(F.isDashInvulnerable(10, 10.2), true)
		expect.equal(F.isDashInvulnerable(10, 10.3), false)
	end,
	["xp curve = floor(100 * L^1.4)"] = function()
		expect.equal(F.xpToNextLevel(1), 100)
		expect.equal(F.xpToNextLevel(2), 263)
		expect.equal(F.xpToNextLevel(10), 2511)
		expect.equal(F.xpToNextLevel(100), 0)
	end,
	["addXP levels up across multiple levels and stops at the cap"] = function()
		local level, xp, gained = F.addXP(1, 50, 400)
		expect.equal(level, 3, "level")
		expect.equal(xp, 87, "xp") -- 450 - 100 - 263
		expect.equal(gained, 2, "gained")
		local capLevel, capXP = F.addXP(99, 0, 10 ^ 9)
		expect.equal(capLevel, 100)
		expect.equal(capXP, 0)
	end,
	["rank titles by level"] = function()
		expect.equal(F.rankForLevel(1), "Scavenger")
		expect.equal(F.rankForLevel(9), "Scavenger")
		expect.equal(F.rankForLevel(10), "Raider")
		expect.equal(F.rankForLevel(74), "WastelandLegend")
		expect.equal(F.rankForLevel(75), "JunkKing")
		expect.equal(F.rankForLevel(100), "ApexScrapper")
	end,
	["KO streak: +0.1 per KO, capped at x1.5"] = function()
		expect.equal(F.koStreakMultiplier(0), 1)
		expect.near(F.koStreakMultiplier(3), 1.3)
		expect.equal(F.koStreakMultiplier(10), 1.5)
		expect.equal(F.koScrap(0), 10)
		expect.equal(F.koScrap(2), 12)
		expect.equal(F.koScrap(9), 15)
	end,
	["bonuses add and cap at +60%"] = function()
		expect.near(F.scrapBonus(true, true), 0.35)
		expect.near(F.friendXPBonus(2), 0.2)
		expect.near(F.friendXPBonus(5), 0.3)
		expect.near(F.bonusMultiplier(0.35), 1.35)
		expect.near(F.bonusMultiplier(0.9), 1.6)
	end,
	["payout: winner who stayed the whole round"] = function()
		local result = payout({ KOScrap = 33, KOs = 3, Placement = 1, Completed = true })
		expect.equal(result.Scrap, 33 + 50 + 15)
		expect.equal(result.XP, 60 + 100 + 40)
	end,
	["payout: 2nd and 3rd get Top3, 4th does not"] = function()
		expect.equal(payout({ Placement = 2 }).Scrap, 25)
		expect.equal(payout({ Placement = 3 }).XP, 50)
		expect.equal(payout({ Placement = 4 }).Scrap, 0)
	end,
	["payout: under 60 s active keeps only KO and dodge rewards"] = function()
		local result =
			payout({ KOScrap = 10, KOs = 1, PerfectDodges = 2, Placement = 1, Completed = true, ActiveSeconds = 59 })
		expect.equal(result.Scrap, 20)
		expect.equal(result.XP, 20)
	end,
	["payout: AFK at the end pays nothing"] = function()
		local result = payout({ KOScrap = 50, KOs = 5, Placement = 1, Completed = true, AFKAtEnd = true })
		expect.equal(result.Scrap, 0)
		expect.equal(result.XP, 0)
	end,
	["payout: VIP + Premium scrap, friend XP, private server half"] = function()
		local result = payout({ Placement = 1, Completed = true, IsVIP = true, IsPremium = true, FriendsInServer = 3 })
		expect.equal(result.Scrap, 88) -- 65 * 1.35 = 87.75
		expect.equal(result.XP, 182) -- 140 * 1.3
		local private = payout({ Placement = 1, Completed = true, IsPrivateServer = true })
		expect.equal(private.Scrap, 33) -- 65 * 0.5 = 32.5
		expect.equal(private.XP, 70)
	end,
	["day number rolls over at the reset hour (UTC)"] = function()
		expect.equal(F.dayNumber(0), 0)
		expect.equal(F.dayNumber(86399), 0)
		expect.equal(F.dayNumber(86400), 1)
		expect.equal(F.dayNumber(86400 + 3600, 2), 0)
	end,
}
