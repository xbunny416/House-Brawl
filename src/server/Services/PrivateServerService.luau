--!strict
--[[
	PrivateServerService — private servers (bible §7). In a private server (a PrivateServerId with an owner; reserved
	servers don't count) the owner sets from their Server menu (PrivateServerSetting remote, Shared/PrivateServerRules):
	the mode (locked, or "Vote"), the map (picked, or "Vote") and the round length (Config.Round.PrivateRoundTimes).
	The choices are saved in the owner's data (PrivateServer), so they come back in every private server they own, and
	apply from the next vote / round (RoundService asks `ballot` and `roundTime`). Private servers are for play and
	testing (owner, 2026-10-17): round rewards are scaled by Economy.PrivateServerRewardScale = 0 (RewardService asks
	`isPrivate`) and lifetime stats don't count (`countsProgress`); every player is told so when they join.
	Workspace attributes for the UI: PrivateServer, PrivateOwnerId, PrivateMode, PrivateMap, PrivateRoundTime.
	Studio: the developer panel can make the playtest act as a private server owned by the player who asks.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local PrivateServerRules = require(Shared:WaitForChild("PrivateServerRules"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local MapService = require(script.Parent:WaitForChild("MapService"))

local PrivateServerService = {}

local simulatedOwner: number? = nil -- developer panel (Studio)
local current: PrivateServerRules.Settings = PrivateServerRules.defaults()

local function log(message: string)
	if RunService:IsStudio() then
		print(`[PrivateServer] {message}`)
	end
end

-- The owner's UserId, or 0 when this is not a private server.
local function ownerId(): number
	if simulatedOwner then
		return simulatedOwner
	end
	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
		return game.PrivateServerOwnerId
	end
	return 0
end

function PrivateServerService.isPrivate(): boolean
	return ownerId() ~= 0
end

function PrivateServerService.isOwner(player: Player): boolean
	local owner = ownerId()
	return owner ~= 0 and player.UserId == owner
end

-- Whether lifetime stats (and later quests, badges, leaderboards) count here: not in a private server, unless
-- Economy.PrivateServerProgress.
function PrivateServerService.countsProgress(): boolean
	return Config.Economy.PrivateServerProgress or not PrivateServerService.isPrivate()
end

-- Whether rewards (round Scrap / XP, daily and playtime rewards) are paid here: not in a private server while
-- Economy.PrivateServerRewardScale is 0.
function PrivateServerService.paysRewards(): boolean
	return Config.Economy.PrivateServerRewardScale > 0 or not PrivateServerService.isPrivate()
end

-- The settings in force: the owner's (once their data has loaded) in a private server, otherwise the defaults.
function PrivateServerService.settings(): PrivateServerRules.Settings
	return if PrivateServerService.isPrivate() then current else PrivateServerRules.defaults()
end

-- The options for the next vote: the owner's locked mode / picked map, or `voteOptions`.
function PrivateServerService.ballot(kind: "Map" | "Mode", voteOptions: { string }): { string }
	local settings = PrivateServerService.settings()
	return PrivateServerRules.options(if kind == "Map" then settings.Map else settings.Mode, voteOptions)
end

-- Seconds the next round lasts.
function PrivateServerService.roundTime(): number
	return PrivateServerService.settings().RoundTime
end

local function publish()
	local settings = PrivateServerService.settings()
	Workspace:SetAttribute("PrivateServer", PrivateServerService.isPrivate())
	Workspace:SetAttribute("PrivateOwnerId", ownerId())
	Workspace:SetAttribute("PrivateMode", settings.Mode)
	Workspace:SetAttribute("PrivateMap", settings.Map)
	Workspace:SetAttribute("PrivateRoundTime", settings.RoundTime)
end

-- Takes the owner's saved choices (defaults until their data has loaded).
local function loadOwnerSettings()
	local owner = Players:GetPlayerByUserId(ownerId())
	local data = owner and DataService.get(owner)
	current = PrivateServerRules.sanitize(if data then data.PrivateServer else nil, MapService.getEnabledMaps())
	publish()
end

local function welcome(player: Player)
	local percent = math.floor(Config.Economy.PrivateServerRewardScale * 100 + 0.5)
	if percent > 0 then
		Net.fireClient("Notify", player, "PrivateServer.WelcomeScaled", { percent })
	else
		Net.fireClient("Notify", player, "PrivateServer.Welcome")
	end
end

local function onSetting(player: Player, key: string, text: string?, seconds: number?)
	if not PrivateServerService.isOwner(player) then
		return
	end
	local value: any = if key == "RoundTime" then seconds else text
	if not PrivateServerRules.isValid(key, value, MapService.getEnabledMaps()) then
		return
	end
	(current :: any)[key] = value
	DataService.update(player, "PrivateServer", function(data)
		(data.PrivateServer :: any)[key] = value
	end)
	publish()
	log(`{player.Name}: {key} = {value}`)
end

-- Developer panel (Studio): this playtest acts as a private server owned by `player`, or stops acting as one.
function PrivateServerService.toggleSimulated(player: Player)
	if not RunService:IsStudio() then
		return -- never turn a live public server into a private one
	end
	simulatedOwner = if simulatedOwner == nil then player.UserId else nil
	loadOwnerSettings()
	if simulatedOwner then
		welcome(player)
	end
	log(if simulatedOwner then `simulating a private server owned by {player.Name}` else "back to a public server")
end

function PrivateServerService.Init(_self: any)
	Net.onServerEvent("PrivateServerSetting", onSetting)
	DataService.Loaded:Connect(function(player: Player)
		if PrivateServerService.isOwner(player) then
			loadOwnerSettings()
		end
		if PrivateServerService.isPrivate() then
			welcome(player)
		end
	end)
	publish()
end

return PrivateServerService
