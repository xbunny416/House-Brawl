--!strict
-- Daily login streak and playtime rewards (step 3.3).
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local DailyRules = Roblox.require(Shared.DailyRules)
local ShopRules = Roblox.require(Shared.ShopRules)

local TODAY = 20000

local function daily(fields: { [string]: number }?)
	local data = { LastClaimDay = -1, Streak = 0, PlaytimeDay = -1, PlaytimeSeconds = 0, PlaytimeClaims = 0 }
	for key, value in fields or {} do
		(data :: any)[key] = value
	end
	return data
end

return {
	["streak: day 1 first, +1 the next day, back to 1 after a missed day or after day 7; one claim a day"] = function()
		expect.equal(DailyRules.claimDay(daily(), TODAY), 1, "never claimed")
		expect.equal(DailyRules.claimDay(daily({ LastClaimDay = TODAY - 1, Streak = 3 }), TODAY), 4)
		expect.equal(DailyRules.claimDay(daily({ LastClaimDay = TODAY, Streak = 3 }), TODAY), nil, "claimed today")
		expect.equal(DailyRules.claimDay(daily({ LastClaimDay = TODAY - 2, Streak = 5 }), TODAY), 1, "missed a day")
		expect.equal(DailyRules.claimDay(daily({ LastClaimDay = TODAY - 1, Streak = 7 }), TODAY), 1, "after day 7")
		expect.equal(DailyRules.shownDay(daily({ LastClaimDay = TODAY, Streak = 3 }), TODAY), 3)
	end,
	["rewards: days 1-6 pay the bible's Scrap, day 7 the week's cosmetic (Scrap if already owned)"] = function()
		local expected = { 50, 75, 100, 150, 200, 250 }
		for day, scrap in expected do
			local reward = DailyRules.reward(day, TODAY, {})
			expect.equal(reward.Scrap, scrap, `day {day}`)
			expect.equal(reward.Cosmetic, nil, `day {day} cosmetic`)
		end
		local cosmetic = DailyRules.weeklyCosmetic(DailyRules.weekOf(TODAY))
		expect.truthy(cosmetic, "a weekly cosmetic")
		local seventh = DailyRules.reward(7, TODAY, {})
		expect.equal(seventh.Cosmetic, cosmetic)
		expect.equal(seventh.Scrap, 0)
		local owned = DailyRules.reward(7, TODAY, { [cosmetic :: string] = true })
		expect.equal(owned.Cosmetic, nil)
		expect.equal(owned.Scrap, Config.Retention.LoginStreak.FinalDayFallbackScrap)
	end,
	["the weekly cosmetic: the same all week, changes between weeks, always sold for Scrap"] = function()
		local week = DailyRules.weekOf(TODAY)
		expect.equal(DailyRules.weekOf(week * 7), week)
		expect.equal(DailyRules.weekOf(week * 7 + 6), week)
		local seen: { [string]: boolean } = {}
		local distinct = 0
		for offset = 0, 9 do
			local id = DailyRules.weeklyCosmetic(week + offset) :: string
			expect.truthy(ShopRules.basePrice("Cosmetic", id), `{id} is sold for Scrap`)
			if not seen[id] then
				seen[id] = true
				distinct += 1
			end
		end
		expect.truthy(distinct >= 5, `rotates ({distinct} different in 10 weeks)`)
	end,
	["playtime: one reward per interval of active play, capped per day, reset by a new day"] = function()
		local config = Config.Retention.Playtime
		expect.equal(config.Interval, 600)
		expect.equal(config.Scrap, 25)
		expect.equal(config.MaxClaimsPerDay, 6)
		local state = DailyRules.addPlaytime(daily(), TODAY, 599)
		expect.equal(state.Due, 0)
		state = DailyRules.addPlaytime(daily(), TODAY, 600)
		expect.equal(state.Due, 1)
		local today = daily({ PlaytimeDay = TODAY, PlaytimeSeconds = 1250, PlaytimeClaims = 1 })
		state = DailyRules.addPlaytime(today, TODAY, 15)
		expect.equal(state.Seconds, 1265)
		expect.equal(state.Due, 1, "the second reward")
		state = DailyRules.addPlaytime(
			daily({ PlaytimeDay = TODAY, PlaytimeSeconds = 99999, PlaytimeClaims = 2 }),
			TODAY,
			15
		)
		expect.equal(state.Due, 4, "capped at 6 a day")
		state = DailyRules.addPlaytime(
			daily({ PlaytimeDay = TODAY - 1, PlaytimeSeconds = 5000, PlaytimeClaims = 6 }),
			TODAY,
			15
		)
		expect.equal(state.Seconds, 15, "a new day starts from zero")
		expect.equal(state.Claims, 0)
	end,
	["next playtime reward: seconds left, nil once the day's rewards are paid"] = function()
		expect.equal(DailyRules.nextPlaytimeIn(daily(), TODAY), 600)
		expect.equal(
			DailyRules.nextPlaytimeIn(daily({ PlaytimeDay = TODAY, PlaytimeSeconds = 700, PlaytimeClaims = 1 }), TODAY),
			500
		)
		expect.equal(
			DailyRules.nextPlaytimeIn(daily({ PlaytimeDay = TODAY, PlaytimeSeconds = 4000, PlaytimeClaims = 6 }), TODAY),
			nil
		)
	end,
}
