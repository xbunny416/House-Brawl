--!strict
-- Keeps the local player's copy of their saved data (sent by the server's DataService) and signals changes.
-- Read-only on the client: every change is made on the server.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))
local DataTemplate = require(Shared:WaitForChild("Data"):WaitForChild("Template"))

type PlayerData = DataTemplate.PlayerData

local DataController = {
	Priority = -50,
	-- (key, value) for every top-level field that changes, including all fields on the first sync.
	Changed = Signal.new() :: Signal.Signal<string, any>,
}

local data: PlayerData? = nil
local ready = Signal.new() :: Signal.Signal<()>

-- The local player's data, or nil before the first sync.
function DataController.get(): PlayerData?
	return data
end

-- Yields until the first sync arrives.
function DataController.waitForData(): PlayerData
	if data == nil then
		ready:Wait()
	end
	return data :: PlayerData
end

function DataController.Init(_self: any)
	Net.on("DataSync", function(snapshot: PlayerData)
		data = snapshot
		ready:Fire()
		for key, value in snapshot :: any do
			DataController.Changed:Fire(key, value)
		end
	end)
	Net.on("DataChanged", function(key: string, value: any)
		if data then
			(data :: any)[key] = value
			DataController.Changed:Fire(key, value)
		end
	end)
end

return DataController
