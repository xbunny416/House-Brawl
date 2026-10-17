--!strict
--[[
	DataService — loads, saves and changes player data. Built on ProfileStore (Server/Vendor), which provides session
	locking (one server owns a profile at a time), auto-save, and a final save on leave/shutdown.

	Rules:
	  * Only change data through the functions below, so the owning client is told about every change.
	  * Scrap amounts are whole numbers; spending checks the balance on the server.
	  * Developer products go through DataService.processReceipt (granted once per PurchaseId, confirmed only after
	    the grant is saved).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))
local DataTemplate = require(Shared:WaitForChild("Data"):WaitForChild("Template"))

local Server = script.Parent.Parent
local ProfileStore = require(Server:WaitForChild("Vendor"):WaitForChild("ProfileStore"))
local Migrations = require(Server:WaitForChild("Data"):WaitForChild("Migrations"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))

type PlayerData = DataTemplate.PlayerData

-- The ProfileStore profile members this service uses (ProfileStore's own generic type intersects Data with a JSON
-- union, which strict mode cannot unify with PlayerData).
type Profile = {
	Data: PlayerData,
	LastSavedData: PlayerData,
	Key: string,
	OnSessionEnd: { Connect: (self: any, listener: () -> ()) -> any },
	OnAfterSave: { Connect: (self: any, listener: (PlayerData) -> ()) -> any, Wait: (self: any) -> PlayerData },
	IsActive: (self: any) -> boolean,
	Reconcile: (self: any) -> (),
	EndSession: (self: any) -> (),
	AddUserId: (self: any, userId: number) -> (),
	Save: (self: any) -> (),
}

local DataService = {
	Priority = -50, -- loads before gameplay services so they can use DataService.Loaded

	-- Fires once per player when their data is ready: (player, data)
	Loaded = Signal.new() :: Signal.Signal<Player, PlayerData>,
	-- Fires when a player gains one or more levels: (player, new level)
	LeveledUp = Signal.new() :: Signal.Signal<Player, number>,
	-- Fires after a lifetime stat goes up: (player, stat, amount) — quests count from it
	StatIncremented = Signal.new() :: Signal.Signal<Player, string, number>,
}

local profiles: { [Player]: Profile } = {}

local store = ProfileStore.New(Config.Data.StoreName, DataTemplate.Template)
local sessionStore = if RunService:IsStudio() and Config.Data.UseMockInStudio then store.Mock else store

local function profileKey(player: Player): string
	return Config.Data.KeyPrefix .. player.UserId
end

-- Sends one top-level data field to the owning client.
local function replicate(player: Player, key: string)
	local profile = profiles[player]
	if profile then
		Net.fireClient("DataChanged", player, key, (profile.Data :: any)[key])
	end
end

local function loadProfile(player: Player)
	-- Stops waiting for the session lock if the player leaves first.
	local options = {
		Cancel = function(): boolean
			return player.Parent ~= Players
		end,
	}
	local profile: Profile? = sessionStore:StartSessionAsync(profileKey(player), options :: any) :: any

	if profile == nil then
		-- Another server kept the session lock, or DataStores are down. Kicking is safer than playing unsaved.
		if player.Parent == Players then
			player:Kick(Localization.format("Data.LoadFailed"))
		end
		return
	end

	local savedVersion = (profile.Data :: any).Version
	if type(savedVersion) == "number" and savedVersion > DataTemplate.VERSION then
		-- Saved by a newer server build (mid-update). Leave it untouched; the player rejoins onto a new server.
		profile:EndSession()
		player:Kick(Localization.format("Data.ServerOutdated"))
		return
	end

	profile:AddUserId(player.UserId) -- GDPR: links the profile to the user for right-to-erasure requests
	profile:Reconcile() -- fills fields added to the template since this profile was last saved
	if not Migrations.run(profile.Data :: any, DataTemplate.VERSION) then
		-- A migration step is missing. Saves whatever steps did run (Version reflects them) and asks to rejoin.
		warn(`[DataService] missing migration step for {profile.Key}`)
		profile:EndSession()
		player:Kick(Localization.format("Data.LoadFailed"))
		return
	end

	profile.OnSessionEnd:Connect(function()
		-- Only reached while still registered when the session was ended from outside (e.g. another server
		-- took the lock). Normal leaves unregister first, in PlayerRemoving.
		if profiles[player] == profile then
			profiles[player] = nil
			if player.Parent == Players then
				player:Kick(Localization.format("Data.SessionEnded"))
			end
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession() -- left while loading
		return
	end

	profiles[player] = profile
	player:SetAttribute("Level", profile.Data.Level)
	Net.fireClient("DataSync", player, profile.Data)
	DataService.Loaded:Fire(player, profile.Data)
end

---------------------------------------------------------------------------------------------------------------------
-- Reading
---------------------------------------------------------------------------------------------------------------------

-- The player's data, or nil if it has not loaded (or failed to load). Treat it as read-only.
function DataService.get(player: Player): PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- Yields until the player's data is ready. Returns nil if they leave first.
function DataService.waitFor(player: Player): PlayerData?
	while player.Parent == Players do
		local profile = profiles[player]
		if profile then
			return profile.Data
		end
		task.wait()
	end
	return nil
end

---------------------------------------------------------------------------------------------------------------------
-- Changing
---------------------------------------------------------------------------------------------------------------------

-- Runs `mutate` on the player's data and replicates the given top-level key. Returns false if not loaded.
function DataService.update(player: Player, key: string, mutate: (data: PlayerData) -> ()): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	mutate(profile.Data)
	replicate(player, key)
	return true
end

-- Adds Scrap (whole, non-negative amount). `sku` names the source for analytics (e.g. "RoundReward").
function DataService.addScrap(player: Player, amount: number, transaction: string, sku: string): boolean
	assert(amount >= 0 and amount == math.floor(amount), "Scrap amount must be a whole, non-negative number")
	local profile = profiles[player]
	if not profile then
		return false
	end
	if amount == 0 then
		return true
	end
	profile.Data.Scrap += amount
	replicate(player, "Scrap")
	Analytics.scrapEarned(player, amount, profile.Data.Scrap, transaction, sku)
	return true
end

-- Spends Scrap if the player can afford it. Returns false (and changes nothing) otherwise.
function DataService.spendScrap(player: Player, amount: number, transaction: string, sku: string): boolean
	assert(amount >= 0 and amount == math.floor(amount), "Scrap amount must be a whole, non-negative number")
	local profile = profiles[player]
	if not profile or profile.Data.Scrap < amount then
		return false
	end
	profile.Data.Scrap -= amount
	replicate(player, "Scrap")
	Analytics.scrapSpent(player, amount, profile.Data.Scrap, transaction, sku)
	return true
end

-- Adds XP and applies level-ups. Returns the number of levels gained.
function DataService.addXP(player: Player, amount: number): number
	local profile = profiles[player]
	if not profile or amount <= 0 then
		return 0
	end
	local data = profile.Data
	local level, xp, gained = Formulas.addXP(data.Level, data.XP, math.floor(amount))
	data.Level = level
	data.XP = xp
	replicate(player, "XP")
	if gained > 0 then
		replicate(player, "Level")
		player:SetAttribute("Level", level)
		DataService.LeveledUp:Fire(player, level)
	end
	return gained
end

-- Adds to a lifetime stat (KOs, Wins, ...).
function DataService.incrementStat(player: Player, stat: string, amount: number?)
	local profile = profiles[player]
	if not profile then
		return
	end
	local stats = profile.Data.Stats :: any
	assert(type(stats[stat]) == "number", `Unknown stat "{stat}"`)
	stats[stat] += amount or 1
	replicate(player, "Stats")
	DataService.StatIncremented:Fire(player, stat, amount or 1)
end

---------------------------------------------------------------------------------------------------------------------
-- Developer products
---------------------------------------------------------------------------------------------------------------------

--[[
	Grants a developer product exactly once and only reports PurchaseGranted after the grant is saved
	(ProfileStore's PurchaseId-cache pattern). Use as the body of MarketplaceService.ProcessReceipt.
	`grant` changes the data (e.g. adds Scrap) and must not yield.
]]
function DataService.processReceipt(
	receipt: { [string]: any },
	grant: (player: Player) -> ()
): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile: Profile? = nil
	while player.Parent == Players do
		profile = profiles[player]
		if profile then
			break
		end
		task.wait()
	end
	if not profile or not profile:IsActive() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receipt.PurchaseId)
	local cache = profile.Data.PurchaseIds
	if not table.find(cache, purchaseId) then
		local granted = true
		xpcall(grant, function(err: unknown)
			granted = false
			warn(`[DataService] failed to grant purchase {purchaseId}: {err}`)
		end, player)
		if not granted then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		while #cache >= Config.Data.PurchaseIdCacheSize do
			table.remove(cache, 1)
		end
		table.insert(cache, purchaseId)
	end

	local activeProfile = profile :: Profile
	local function isSaved(): boolean
		return table.find(activeProfile.LastSavedData.PurchaseIds or {}, purchaseId) ~= nil
	end

	while not isSaved() do
		if not activeProfile:IsActive() then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local lastSaved = activeProfile.LastSavedData
		activeProfile:Save()
		if activeProfile.LastSavedData == lastSaved then
			activeProfile.OnAfterSave:Wait()
		end
		if not isSaved() and activeProfile:IsActive() then
			task.wait(10)
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------------------------------------------------

function DataService.Init(_self: any)
	ProfileStore.OnError:Connect(function(message: string, storeName: string, key: string)
		warn(`[DataService] ProfileStore error ({storeName}/{key}): {message}`)
	end)

	Players.PlayerAdded:Connect(loadProfile)
	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		local profile = profiles[player]
		if profile then
			profiles[player] = nil
			profile:EndSession()
		end
	end)
end

return DataService
