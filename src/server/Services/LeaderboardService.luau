--!strict
--[[
	LeaderboardService — the global leaderboards (bible §8; Shared/LeaderboardRules, Config.Retention.Leaderboards):
	all-time and weekly Wins, KOs and Level, each an OrderedDataStore.
	  * Every RefreshInterval: each player's changed scores are saved (and once more when they leave or the server
	    closes), then every board's top TopCount is read, names are looked up (UserService, cached) and the boards go
	    to every client (Leaderboards remote; new players get the latest at once).
	  * This week's Wins / KOs are counted from DataService.StatIncremented into the player's LeaderboardWeek data; the
	    week (and the level it started at) rolls over on load and at each refresh.
	  * Nothing is saved from private servers (PrivateServerService.countsProgress).
	  * Offline (Studio without API access, or Config.Data.UseMockInStudio): the boards show this server's players.
]]
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LeaderboardRules = require(Shared:WaitForChild("LeaderboardRules"))
local Net = require(Shared:WaitForChild("Net"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))

local FIRST_REFRESH_DELAY = 5 -- seconds after the server starts

local LeaderboardService = {}

local boards: { [string]: { LeaderboardRules.Entry } } = {}
local written: { [Player]: { [string]: number } } = {}
local names: { [number]: string } = {}
local online = not (RunService:IsStudio() and Config.Data.UseMockInStudio)

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Leaderboards] {message}`)
	end
end

local function week(): number
	return LeaderboardRules.weekAt(os.time())
end

-- Switches to this-server-only boards after a DataStore call fails (no API access).
local function goOffline(err: unknown)
	if online then
		online = false
		warn(`[Leaderboards] DataStores unavailable, showing this server only: {err}`)
	end
end

local function store(stat: string, period: string): OrderedDataStore
	return DataStoreService:GetOrderedDataStore(LeaderboardRules.storeName(stat, period, week()))
end

-- Starts this week's scores over if the week has changed.
local function rollWeek(player: Player)
	local data = DataService.get(player)
	if data and data.LeaderboardWeek.Week ~= week() then
		DataService.update(player, "LeaderboardWeek", function(changed)
			changed.LeaderboardWeek = LeaderboardRules.currentWeek(changed.LeaderboardWeek, week(), changed.Level)
		end)
	end
end

local function onStat(player: Player, stat: string, amount: number)
	if stat ~= "Wins" and stat ~= "KOs" then
		return
	end
	DataService.update(player, "LeaderboardWeek", function(changed)
		changed.LeaderboardWeek =
			LeaderboardRules.addToWeek(changed.LeaderboardWeek, week(), changed.Level, stat, amount)
	end)
end

-- Saves the player's scores that changed since the last save.
local function saveScores(player: Player)
	local data = DataService.get(player)
	if data == nil or not online or not PrivateServerService.countsProgress() then
		return
	end
	local saved = written[player] or {}
	written[player] = saved
	for _, stat in Config.Retention.Leaderboards.Stats do
		for _, period in LeaderboardRules.Periods do
			local value = math.floor(LeaderboardRules.score(data, stat, period, week()))
			local key = LeaderboardRules.key(stat, period)
			if value > 0 and saved[key] ~= value then
				local ok, err = pcall(function()
					store(stat, period):SetAsync(tostring(player.UserId), value)
				end)
				if not ok then
					goOffline(err)
					return
				end
				saved[key] = value
			end
		end
	end
end

-- Display names for these UserIds (cached; players in the server are known at once).
local function lookUpNames(userIds: { number })
	local missing: { number } = {}
	for _, userId in userIds do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			names[userId] = player.DisplayName
		elseif names[userId] == nil then
			table.insert(missing, userId)
		end
	end
	if #missing == 0 then
		return
	end
	local ok, infos = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(missing)
	end)
	if ok and type(infos) == "table" then
		for _, info in infos do
			names[info.Id] = info.DisplayName
		end
	end
end

-- One board read from its OrderedDataStore, or nil when that fails.
local function readBoard(stat: string, period: string): { LeaderboardRules.Entry }?
	local ok, page = pcall(function()
		return store(stat, period):GetSortedAsync(false, Config.Retention.Leaderboards.TopCount):GetCurrentPage()
	end)
	if not ok then
		goOffline(page)
		return nil
	end
	local entries: { LeaderboardRules.Entry } = {}
	for _, item in page do
		local userId = tonumber(item.key)
		if userId then
			table.insert(entries, { UserId = userId, Name = "", Value = item.value })
		end
	end
	return entries
end

-- One board made from the players in this server (offline).
local function localBoard(stat: string, period: string): { LeaderboardRules.Entry }
	local entries: { LeaderboardRules.Entry } = {}
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data then
			local value = LeaderboardRules.score(data, stat, period, week())
			table.insert(entries, { UserId = player.UserId, Name = player.DisplayName, Value = value })
		end
	end
	return entries
end

local function refreshBoards()
	local topCount = Config.Retention.Leaderboards.TopCount
	for _, stat in Config.Retention.Leaderboards.Stats do
		for _, period in LeaderboardRules.Periods do
			local entries = (if online then readBoard(stat, period) else nil) or localBoard(stat, period)
			local top = LeaderboardRules.top(entries, topCount)
			local ids: { number } = {}
			for _, entry in top do
				table.insert(ids, entry.UserId)
			end
			lookUpNames(ids)
			for _, entry in top do
				entry.Name = names[entry.UserId] or entry.Name
				if entry.Name == "" then
					entry.Name = `#{entry.UserId}`
				end
			end
			boards[LeaderboardRules.key(stat, period)] = top
		end
	end
	Net.fireAll("Leaderboards", boards, online)
end

local function refresh()
	for _, player in Players:GetPlayers() do
		rollWeek(player)
		saveScores(player)
	end
	refreshBoards()
	log(`refreshed ({if online then "global" else "this server only"})`)
end

function LeaderboardService.Init(_self: any)
	DataService.StatIncremented:Connect(onStat)
	DataService.Loaded:Connect(function(player: Player)
		rollWeek(player)
		Net.fireClient("Leaderboards", player, boards, online)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		saveScores(player)
		written[player] = nil
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			task.spawn(saveScores, player)
		end
	end)
end

function LeaderboardService.Start(_self: any)
	task.wait(FIRST_REFRESH_DELAY)
	while true do
		refresh()
		task.wait(Config.Retention.Leaderboards.RefreshInterval)
	end
end

return LeaderboardService
