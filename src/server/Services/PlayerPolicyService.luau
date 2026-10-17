--!strict
--[[
	PlayerPolicyService — reads each player's Roblox policy (PolicyService:GetPolicyInfoForPlayerAsync) once when they
	join, retrying a failed call (Config.Monetization.WebRetries). `allows(player, feature)` and
	`allowsLink(player, name)` (Shared/PolicyRules) answer "no" until it has loaded, and for good if it never does.
	Clients see the answers as the Player attributes "Policy<Feature>" (true / false). Bible §7: nothing at launch
	needs them (no paid random items, paid trading or external links); later features check here first.
]]
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PolicyRules = require(Shared:WaitForChild("PolicyRules"))
local Retry = require(Shared:WaitForChild("Util"):WaitForChild("Retry"))

local PlayerPolicyService = {}

local policies: { [Player]: PolicyRules.Policy } = {}

function PlayerPolicyService.allows(player: Player, feature: string): boolean
	return PolicyRules.allows(policies[player], feature)
end

function PlayerPolicyService.allowsLink(player: Player, name: string): boolean
	return PolicyRules.allowsLink(policies[player], name)
end

local function load(player: Player)
	local retries = Config.Monetization.WebRetries
	local ok, result = Retry.call(retries.Attempts, retries.Delay, function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok or type(result) ~= "table" then
		warn(`[Policy] could not read the policy for {player.Name}: {result}`)
	elseif player.Parent == Players then
		policies[player] = result
	end
	for _, feature in PolicyRules.Features do
		player:SetAttribute(`Policy{feature}`, PlayerPolicyService.allows(player, feature))
	end
end

function PlayerPolicyService.Init(_self: any)
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		policies[player] = nil
	end)
end

return PlayerPolicyService
