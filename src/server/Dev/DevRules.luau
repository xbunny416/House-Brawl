--!strict
--[[
	DevRules — who may use the developer panel and which commands exist (pure, so specs check the allowlist logic).
	Anyone in a Studio playtest when Config.Dev.AllowInStudio is on; in live servers only Config.Dev.AllowedUserIds.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local DevRules = {}

-- Every developer panel command (the DevCommand remote's first argument).
DevRules.Commands = {
	"StartRound",
	"EndRound",
	"ForceMap",
	"ForceMode",
	"Crumble",
	"SpawnProp",
	"SetPercent",
	"SetHealth",
	"SetStyle",
}

function DevRules.isAllowed(userId: number, inStudio: boolean): boolean
	if inStudio and Config.Dev.AllowInStudio then
		return true
	end
	return table.find(Config.Dev.AllowedUserIds, userId) ~= nil
end

return DevRules
