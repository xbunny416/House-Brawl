--!strict
--[[
	PolicyRules — what Roblox's per-region policy allows for a player (pure). `policy` is the table returned by
	PolicyService:GetPolicyInfoForPlayerAsync, or nil when it could not be read: then every restricted feature is off
	(the safe default). Bible §7: the game has no paid random items, paid trading or external links at launch; any
	later feature that adds one asks here first (server: Services/PlayerPolicyService).
]]
export type Policy = { [string]: any }

local PolicyRules = {}

-- Features a policy can switch off. Clients read them as the Player attributes "Policy<Feature>".
PolicyRules.Features = { "PaidRandomItems", "PaidTrading" }

function PolicyRules.allows(policy: Policy?, feature: string): boolean
	if policy == nil then
		return false
	end
	if feature == "PaidRandomItems" then
		return policy.ArePaidRandomItemsRestricted == false
	elseif feature == "PaidTrading" then
		return policy.IsPaidItemTradingAllowed == true
	end
	return false
end

-- True if the game may point this player to the external site `name` (e.g. "Discord", "YouTube").
function PolicyRules.allowsLink(policy: Policy?, name: string): boolean
	local allowed = policy and policy.AllowedExternalLinkReferences
	return type(allowed) == "table" and table.find(allowed, name) ~= nil
end

return PolicyRules
