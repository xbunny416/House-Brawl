--!strict
--[[
	GroupRewardService — the Roblox group perks (bible §8; Config.Retention.Group). Members of the group get the Player
	attribute GroupMember (the client shows a [Crew] chat tag) and, once, Group.Scrap Scrap (saved in Social
	.GroupRewardClaimed; not in private servers, where nothing is earned — it waits for a public server). Membership is
	checked on join (GroupService:GetGroupsAsync) and again every RecheckInterval seconds while the reward is unpaid,
	so joining the group mid-session counts. Off while Group.GroupId is 0.
]]
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))

local GroupRewardService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Group] {message}`)
	end
end

-- Whether the player is in the group (nil when Roblox could not be asked).
local function isMember(player: Player): boolean?
	local groupId = Config.Retention.Group.GroupId
	local ok, groups = pcall(function()
		return GroupService:GetGroupsAsync(player.UserId)
	end)
	if not ok or type(groups) ~= "table" then
		return nil
	end
	for _, group in groups do
		if group.Id == groupId then
			return true
		end
	end
	return false
end

local function check(player: Player)
	local data = DataService.get(player)
	if data == nil or player.Parent ~= Players then
		return
	end
	local member = isMember(player)
	if member == nil then
		return
	end
	player:SetAttribute("GroupMember", member)
	if member and not data.Social.GroupRewardClaimed and PrivateServerService.paysRewards() then
		local scrap = Config.Retention.Group.Scrap
		DataService.update(player, "Social", function(changed)
			changed.Social.GroupRewardClaimed = true
		end)
		DataService.addScrap(player, scrap, Analytics.Transaction.Onboarding, "GroupReward")
		Net.fireClient("Notify", player, "Group.Reward", { scrap })
		log(`{player.Name} got the group reward`)
	end
end

function GroupRewardService.Init(_self: any)
	if Config.Retention.Group.GroupId == 0 then
		return
	end
	DataService.Loaded:Connect(function(player: Player)
		check(player)
	end)
end

function GroupRewardService.Start(_self: any)
	if Config.Retention.Group.GroupId == 0 then
		return
	end
	while true do
		task.wait(Config.Retention.Group.RecheckInterval)
		for _, player in Players:GetPlayers() do
			local data = DataService.get(player)
			if data and not data.Social.GroupRewardClaimed then
				task.spawn(check, player)
			end
		end
	end
end

return GroupRewardService
