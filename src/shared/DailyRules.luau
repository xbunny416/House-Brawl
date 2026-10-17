--!strict
--[[
	DailyRules — the daily login streak and playtime rewards (bible §8, Config.Retention); pure, shared with the
	Daily reward screen.
	  * Login streak: one claim per day (days start at LoginStreak.ResetHourUTC). Claiming the day after the last claim
	    moves one step along days 1-7 (after day 7 it starts again at day 1); missing a day starts again at day 1.
	    Days 1-6 pay LoginStreak.Scrap[day]; day 7 gives the week's cosmetic — one of the cosmetics sold for Scrap, the
	    same for everyone that week — or FinalDayFallbackScrap if the player already owns it.
	  * Playtime: every Playtime.Interval seconds of active play in a day pays Playtime.Scrap, up to MaxClaimsPerDay.
]]
local Config = require(script.Parent.Config)
local Formulas = require(script.Parent.Formulas)
local ShopRules = require(script.Parent.ShopRules)
local DataTemplate = require(script.Parent.Data.Template)

type DailyData = DataTemplate.DailyData

export type Reward = { Day: number, Scrap: number, Cosmetic: string? }
export type Playtime = { Seconds: number, Claims: number, Due: number }

local WEEK_STEP = 7919 -- spreads consecutive weeks over the catalog

local DailyRules = {}

DailyRules.Days = 7
-- Why a claim was refused; the screen shows "Daily.Error.<Reason>". TryAgain is the client's own (no answer).
DailyRules.Reasons = { "Claimed", "NotLoaded", "PrivateServer", "TryAgain" }

-- The reward calendar's day number for `unixTime`.
function DailyRules.dayAt(unixTime: number): number
	return Formulas.dayNumber(unixTime, Config.Retention.LoginStreak.ResetHourUTC)
end

function DailyRules.weekOf(day: number): number
	return day // DailyRules.Days
end

-- The streak day a claim on `today` would be (1-7), or nil when today's reward was already claimed.
function DailyRules.claimDay(daily: DailyData, today: number): number?
	if daily.LastClaimDay == today then
		return nil
	end
	if daily.LastClaimDay == today - 1 and daily.Streak >= 1 then
		return daily.Streak % DailyRules.Days + 1
	end
	return 1
end

-- The streak day the calendar highlights on `today`: the one waiting to be claimed, or the one claimed today.
function DailyRules.shownDay(daily: DailyData, today: number): number
	return DailyRules.claimDay(daily, today) or daily.Streak
end

-- The cosmetic day 7 gives in `week` (the same for every player), or nil if nothing is sold for Scrap.
function DailyRules.weeklyCosmetic(week: number): string?
	local ids: { string } = {}
	for id in Config.Cosmetics.Items do
		if ShopRules.basePrice("Cosmetic", id) then
			table.insert(ids, id)
		end
	end
	if #ids == 0 then
		return nil
	end
	table.sort(ids)
	return ids[(week * WEEK_STEP) % #ids + 1]
end

-- What claiming streak day `day` on `today` gives a player who owns the cosmetics in `owned`.
function DailyRules.reward(day: number, today: number, owned: { [string]: boolean }): Reward
	local streak = Config.Retention.LoginStreak
	if day < DailyRules.Days or not streak.FinalDayCosmetic then
		return { Day = day, Scrap = streak.Scrap[math.min(day, #streak.Scrap)] }
	end
	local cosmetic = DailyRules.weeklyCosmetic(DailyRules.weekOf(today))
	if cosmetic and owned[cosmetic] ~= true then
		return { Day = day, Scrap = 0, Cosmetic = cosmetic }
	end
	return { Day = day, Scrap = streak.FinalDayFallbackScrap }
end

--[[
	Adds `seconds` of active play on `today` (a new day starts from zero). Returns the day's total seconds, the
	rewards already paid today and how many more are due now.
]]
function DailyRules.addPlaytime(daily: DailyData, today: number, seconds: number): Playtime
	local config = Config.Retention.Playtime
	local sameDay = daily.PlaytimeDay == today
	local total = (if sameDay then daily.PlaytimeSeconds else 0) + seconds
	local claims = if sameDay then daily.PlaytimeClaims else 0
	local earned = math.min(math.floor(total / config.Interval), config.MaxClaimsPerDay)
	return { Seconds = total, Claims = claims, Due = math.max(earned - claims, 0) }
end

-- Active seconds until the next playtime reward on `today`, or nil when today's rewards are all paid.
function DailyRules.nextPlaytimeIn(daily: DailyData, today: number): number?
	local config = Config.Retention.Playtime
	local state = DailyRules.addPlaytime(daily, today, 0)
	local paid = state.Claims + state.Due
	if paid >= config.MaxClaimsPerDay then
		return nil
	end
	return math.max(config.Interval * (paid + 1) - state.Seconds, 0)
end

return DailyRules
