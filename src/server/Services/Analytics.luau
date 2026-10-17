--!strict
--[[
	Analytics — failure-safe wrapper over AnalyticsService. Every tracked event in the game goes through here so
	names stay consistent (bible §6: tutorial steps, purchases, currency earned/spent, round mode, round length,
	KOs per round, style used, map voted).
]]
local AnalyticsService = game:GetService("AnalyticsService")

local CURRENCY = "Scrap"

local FIELD_KEYS = {
	Enum.AnalyticsCustomFieldKeys.CustomField01.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField02.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField03.Name,
}

local Analytics = {
	Priority = -100, -- other services may log during their own Init

	-- Enum.AnalyticsEconomyTransactionType names.
	Transaction = {
		IAP = Enum.AnalyticsEconomyTransactionType.IAP.Name,
		Shop = Enum.AnalyticsEconomyTransactionType.Shop.Name,
		Gameplay = Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
		TimedReward = Enum.AnalyticsEconomyTransactionType.TimedReward.Name,
		Onboarding = Enum.AnalyticsEconomyTransactionType.Onboarding.Name,
	},
}

-- Up to three custom field values (e.g. { modeId, mapId }).
local function customFields(values: { string }?): { [string]: string }?
	if values == nil then
		return nil
	end
	local fields: { [string]: string } = {}
	for index, value in values do
		local key = FIELD_KEYS[index]
		if key then
			fields[key] = value
		end
	end
	return fields
end

local function safely(label: string, callback: () -> ())
	xpcall(callback, function(err: unknown)
		warn(`[Analytics] {label} failed: {err}`)
	end)
end

-- Scrap earned. `sku` names the source (e.g. "RoundReward", "DailyLogin", "ScrapPackM").
function Analytics.scrapEarned(player: Player, amount: number, balance: number, transaction: string, sku: string)
	safely("scrapEarned", function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			CURRENCY,
			amount,
			balance,
			transaction,
			sku
		)
	end)
end

-- Scrap spent. `sku` names the item bought (e.g. "Style.Slugger").
function Analytics.scrapSpent(player: Player, amount: number, balance: number, transaction: string, sku: string)
	safely("scrapSpent", function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Sink,
			CURRENCY,
			amount,
			balance,
			transaction,
			sku
		)
	end)
end

-- Tutorial / onboarding funnel step (1-based, in order).
function Analytics.onboardingStep(player: Player, step: number, stepName: string)
	safely("onboardingStep", function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

-- Generic custom event with an optional value and up to three custom fields.
function Analytics.custom(player: Player, eventName: string, value: number?, fields: { string }?)
	safely(eventName, function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1, customFields(fields))
	end)
end

-- Named events from the bible, so call sites cannot drift.
function Analytics.mapVoted(player: Player, mapId: string)
	Analytics.custom(player, "MapVoted", 1, { mapId })
end

function Analytics.roundModePicked(player: Player, modeId: string, mapId: string)
	Analytics.custom(player, "RoundModePicked", 1, { modeId, mapId })
end

function Analytics.styleUsed(player: Player, styleId: string, modeId: string)
	Analytics.custom(player, "StyleUsed", 1, { styleId, modeId })
end

-- A Shop purchase (the Scrap itself is logged by DataService.spendScrap). `kind` is "Style" or "Cosmetic".
function Analytics.shopPurchase(player: Player, kind: string, itemId: string, price: number, daily: boolean)
	Analytics.custom(player, "ShopPurchase", price, { kind, itemId, if daily then "Daily" else "Regular" })
end

-- A Robux purchase: a game pass or developer product (key from Config.Monetization) and the Robux spent.
function Analytics.robuxPurchase(player: Player, kind: string, key: string, robux: number)
	Analytics.custom(player, "RobuxPurchase", robux, { kind, key })
end

function Analytics.roundFinished(player: Player, seconds: number, kos: number, modeId: string, mapId: string)
	Analytics.custom(player, "RoundLength", seconds, { modeId, mapId })
	Analytics.custom(player, "KOsPerRound", kos, { modeId, mapId })
end

return Analytics
