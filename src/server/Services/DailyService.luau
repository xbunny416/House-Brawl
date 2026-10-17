--!strict
--[[
	DailyService — the daily login streak and playtime rewards (bible §8; Shared/DailyRules, Config.Retention).
	  * ClaimDaily (RemoteFunction): pays today's streak day once — Scrap (TimedReward transaction, sku
	    "LoginStreak.Day<n>") or, on day 7, the week's cosmetic (Scrap instead if already owned) — and saves the claim
	    in the player's Daily data. Returns true and the reward, or false and a DailyRules reason.
	  * Playtime: every PLAYTIME_TICK seconds each player who isn't AFK (RoundService.isAFK) gets that time added to
	    today's playtime (saved, so rejoining keeps it); every Playtime.Interval of it pays Playtime.Scrap, up to
	    MaxClaimsPerDay a day, with a Notify.
	Neither pays in private servers (PrivateServerService.paysRewards: they are for play and testing).
	Developer panel: "Next day" moves the player's claim and playtime back a day; "+10 min" adds playtime.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DailyRules = require(Shared:WaitForChild("DailyRules"))
local Net = require(Shared:WaitForChild("Net"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local CosmeticService = require(script.Parent:WaitForChild("CosmeticService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

local PLAYTIME_TICK = 15 -- seconds between playtime updates (each one saves and syncs the player's Daily data)

local DailyService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Daily] {message}`)
	end
end

local function today(): number
	return DailyRules.dayAt(os.time())
end

-- Claims today's login reward. Returns true and the reward, or false and a DailyRules reason.
function DailyService.claim(player: Player): (boolean, any)
	local data = DataService.get(player)
	if data == nil then
		return false, "NotLoaded"
	end
	if not PrivateServerService.paysRewards() then
		return false, "PrivateServer"
	end
	local day = today()
	local streakDay = DailyRules.claimDay(data.Daily, day)
	if streakDay == nil then
		return false, "Claimed"
	end
	local reward = DailyRules.reward(streakDay, day, data.Cosmetics.Owned)
	DataService.update(player, "Daily", function(changed)
		changed.Daily.LastClaimDay = day
		changed.Daily.Streak = streakDay
	end)
	if reward.Scrap > 0 then
		DataService.addScrap(player, reward.Scrap, Analytics.Transaction.TimedReward, `LoginStreak.Day{streakDay}`)
	end
	if reward.Cosmetic then
		CosmeticService.grant(player, reward.Cosmetic)
		Analytics.custom(player, "LoginStreakCosmetic", 1, { reward.Cosmetic })
	end
	log(
		`{player.Name} claimed day {streakDay}: {reward.Scrap} Scrap{if reward.Cosmetic
			then ", " .. reward.Cosmetic
			else ""}`
	)
	return true, reward
end

-- Adds `seconds` of play to today's playtime and pays any rewards now due.
local function addPlaytime(player: Player, seconds: number)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local day = today()
	local state = DailyRules.addPlaytime(data.Daily, day, seconds)
	DataService.update(player, "Daily", function(changed)
		changed.Daily.PlaytimeDay = day
		changed.Daily.PlaytimeSeconds = state.Seconds
		changed.Daily.PlaytimeClaims = state.Claims + state.Due
	end)
	if state.Due > 0 then
		local config = Config.Retention.Playtime
		local scrap = state.Due * config.Scrap
		DataService.addScrap(player, scrap, Analytics.Transaction.TimedReward, "Playtime")
		local minutes = math.floor(config.Interval * (state.Claims + state.Due) / 60 + 0.5)
		Net.fireClient("Notify", player, "Daily.PlaytimeReward", { scrap, minutes })
		log(`{player.Name}: playtime reward {state.Claims + state.Due}/{config.MaxClaimsPerDay}`)
	end
end

local function tickPlaytime()
	if not PrivateServerService.paysRewards() then
		return
	end
	for _, player in Players:GetPlayers() do
		if not RoundService.isAFK(player) then
			addPlaytime(player, PLAYTIME_TICK)
		end
	end
end

-- Developer panel: as if a day had passed since the last claim and today's playtime.
function DailyService.devNextDay(player: Player)
	DataService.update(player, "Daily", function(changed)
		changed.Daily.LastClaimDay -= 1
		changed.Daily.PlaytimeDay -= 1
	end)
end

-- Developer panel: one playtime interval of play at once.
function DailyService.devAddPlaytime(player: Player)
	addPlaytime(player, Config.Retention.Playtime.Interval)
end

function DailyService.Init(_self: any)
	Net.onServerInvoke("ClaimDaily", function(player: Player)
		return DailyService.claim(player)
	end)
end

function DailyService.Start(_self: any)
	while true do
		task.wait(PLAYTIME_TICK)
		tickPlaytime()
	end
end

return DailyService
