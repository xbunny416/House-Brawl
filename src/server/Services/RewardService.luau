--!strict
--[[
	RewardService — pays the round rewards (bible §2.1) when RoundService.RoundEnded fires. For every player still in
	the server: Server/Round/Payout (Formulas.roundPayout: KO Scrap with streaks, Perfect Dodge Scrap, placement and
	completion rewards — 60 s of active play, nothing when AFK — VIP / Premium / friend bonuses capped at +60%, the
	event multiplier and the private-server scale), then Scrap and XP through DataService (level-ups included).
	Each player gets a RoundReward message for the results screen. The rank title follows the level (Player
	attribute Rank, a Config.Progression rank id).
]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local Payout = require(Server:WaitForChild("Round"):WaitForChild("Payout"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

local RewardService = {}

local vipCache: { [Player]: boolean } = {}

local function setRank(player: Player, level: number)
	player:SetAttribute("Rank", Formulas.rankForLevel(level))
end

-- VIP game pass ownership (cached per session; false until the pass exists, step 3.1).
local function isVIP(player: Player): boolean
	local cached = vipCache[player]
	if cached ~= nil then
		return cached
	end
	local passId = Config.Monetization.GamePasses.VIP.Id
	local owns = false
	if passId ~= 0 then
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		owns = ok and result == true
	end
	vipCache[player] = owns
	return owns
end

local function friendsInServer(player: Player): number
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWithAsync(other.UserId)
			end)
			if ok and isFriend then
				count += 1
			end
		end
	end
	return count
end

local function isPrivateServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

local function pay(result: RoundService.Result)
	local player = result.Player
	if player.Parent ~= Players or DataService.get(player) == nil then
		return
	end
	local payout = Payout.forResult(result, {
		IsVIP = isVIP(player),
		IsPremium = player.MembershipType == Enum.MembershipType.Premium,
		FriendsInServer = friendsInServer(player),
		IsPrivateServer = isPrivateServer(),
	})
	local data = DataService.get(player)
	local oldRank = data and Formulas.rankForLevel(data.Level)
	DataService.addScrap(player, payout.Scrap, Analytics.Transaction.Gameplay, "RoundReward")
	local levelsGained = DataService.addXP(player, payout.XP)
	local level = (DataService.get(player) or data :: any).Level
	setRank(player, level)
	local newRank = Formulas.rankForLevel(level)
	Net.fireClient(
		"RoundReward",
		player,
		payout.Scrap,
		payout.XP,
		level,
		levelsGained,
		if newRank ~= oldRank then newRank else nil
	)
	if RunService:IsStudio() then
		print(`[Rewards] {player.Name}: +{payout.Scrap} Scrap, +{payout.XP} XP, level {level}`)
	end
end

function RewardService.Init(_self: any)
	RoundService.RoundEnded:Connect(function(summary: RoundService.Summary)
		for _, result in summary.Results do
			task.spawn(pay, result) -- the bonus checks may wait on Roblox web calls
		end
	end)
	DataService.Loaded:Connect(function(player: Player, data)
		setRank(player, data.Level)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		vipCache[player] = nil
	end)
end

return RewardService
