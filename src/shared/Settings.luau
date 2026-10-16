--!strict
--[[
	Settings — which Settings-menu values are allowed. The server checks every change with this before saving it;
	the client checks too, so it never sends a change the server would drop.
	Every setting has a default in Config.Data.DefaultSettings; numbers also need a range in Config.Data.SettingRanges
	and strings a list of options below.
]]
local Config = require(script.Parent.Config)

local Settings = {}

local defaults = Config.Data.DefaultSettings :: { [string]: any }
local ranges = Config.Data.SettingRanges :: { [string]: { Min: number, Max: number } }

-- String settings: the value must be a key of this map.
local options: { [string]: { [string]: any } } = {
	ButtonLayout = Config.Controls.Touch.Layouts,
}

-- True if `key` is a setting and `value` is allowed for it.
function Settings.isValid(key: string, value: unknown): boolean
	local default = defaults[key]
	if default == nil or type(value) ~= type(default) then
		return false
	end
	if type(value) == "number" then
		local range = ranges[key]
		return range ~= nil and value >= range.Min and value <= range.Max -- NaN fails both comparisons
	elseif type(value) == "string" then
		local allowed = options[key]
		return allowed ~= nil and allowed[value] ~= nil
	end
	return true
end

return Settings
