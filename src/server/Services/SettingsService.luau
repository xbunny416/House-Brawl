--!strict
--[[
	SettingsService — saves Settings-menu changes (camera shake, volumes, button layout, ...).
	The client sends ChangeSetting(key, value); the value is checked against Shared/Settings and then written through
	DataService, which syncs the new Settings back to the client.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Settings = require(Shared:WaitForChild("Settings"))

local DataService = require(script.Parent:WaitForChild("DataService"))

local SettingsService = {}

function SettingsService.Init(_self: any)
	Net.onServerEvent("ChangeSetting", function(player: Player, key: string, value: any)
		if not Settings.isValid(key, value) then
			return
		end
		DataService.update(player, "Settings", function(data)
			(data.Settings :: any)[key] = value
		end)
	end)
end

return SettingsService
