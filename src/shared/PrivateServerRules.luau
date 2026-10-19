--!strict
--[[
	PrivateServerRules — what a private server's owner can set (bible §7: lock the mode, pick the map, set the round
	length); pure, shared by the server (Services/PrivateServerService) and the owner's Server menu.
	Mode / Map: "Vote" (the players vote, as in public servers) or a mode / enabled map id. RoundTime: one of
	Config.Round.PrivateRoundTimes. A saved value that is no longer valid (e.g. a map switched off) falls back to its
	default.
]]
local Config = require(script.Parent.Config)
local DataTemplate = require(script.Parent.Data.Template)

export type Settings = DataTemplate.PrivateServerSettings

local VOTE = "Vote"

local PrivateServerRules = {}

PrivateServerRules.Vote = VOTE
PrivateServerRules.Keys = { "Mode", "Map", "RoundTime" }

function PrivateServerRules.defaults(): Settings
	return table.clone(DataTemplate.Template.PrivateServer)
end

function PrivateServerRules.isValid(key: string, value: unknown, enabledMaps: { string }): boolean
	if key == "Mode" then
		return type(value) == "string" and (value == VOTE or table.find(Config.Modes.Order, value) ~= nil)
	elseif key == "Map" then
		return type(value) == "string" and (value == VOTE or table.find(enabledMaps, value) ~= nil)
	elseif key == "RoundTime" then
		return type(value) == "number" and table.find(Config.Round.PrivateRoundTimes, value) ~= nil
	end
	return false
end

-- `saved` with every missing or invalid value replaced by its default.
function PrivateServerRules.sanitize(saved: { [string]: any }?, enabledMaps: { string }): Settings
	local result = PrivateServerRules.defaults()
	if saved then
		for _, key in PrivateServerRules.Keys do
			if PrivateServerRules.isValid(key, saved[key], enabledMaps) then
				(result :: any)[key] = saved[key]
			end
		end
	end
	return result
end

-- The ballot for one vote: the owner's locked mode / picked map is the only option, otherwise `voteOptions`.
function PrivateServerRules.options(setting: string, voteOptions: { string }): { string }
	return if setting ~= VOTE then { setting } else voteOptions
end

return PrivateServerRules
