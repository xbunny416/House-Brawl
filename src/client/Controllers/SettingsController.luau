--!strict
--[[
	SettingsController — the local player's Settings-menu values (camera shake, volumes, button layout, ...).
	Values come from the saved data (Config defaults until it loads). SettingsController.set applies a change locally
	at once and asks the server to save it; the server validates it and syncs the saved value back.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Settings = require(Shared:WaitForChild("Settings"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))

local DataController = require(script.Parent:WaitForChild("DataController"))

local SettingsController = {
	Priority = -45,
	-- (key, value) whenever a setting's value changes.
	Changed = Signal.new() :: Signal.Signal<string, any>,
}

local current: { [string]: any } = table.clone(Config.Data.DefaultSettings :: any)

local function apply(key: string, value: any)
	if current[key] ~= value then
		current[key] = value
		SettingsController.Changed:Fire(key, value)
	end
end

function SettingsController.get(key: string): any
	return current[key]
end

-- Changes a setting. Invalid values are ignored.
function SettingsController.set(key: string, value: any)
	if not Settings.isValid(key, value) or current[key] == value then
		return
	end
	apply(key, value)
	Net.fire("ChangeSetting", key, value)
end

function SettingsController.Init(_self: any)
	DataController.Changed:Connect(function(key: string, value: any)
		if key == "Settings" and type(value) == "table" then
			for settingKey, settingValue in value do
				apply(settingKey, settingValue)
			end
		end
	end)
end

return SettingsController
