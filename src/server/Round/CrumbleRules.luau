--!strict
--[[
	CrumbleRules — which platform crumbles next and when (pure; randomness is passed in). Bible §3.2.
	From Crumble.StartTime seconds into the round, every Crumble.Interval seconds one random platform that can fall
	(not the center) starts its warning, as long as at least Crumble.MinPlatformsRemaining platforms (the center
	included) would still be standing afterwards.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

export type Platform = {
	Id: string,
	CanFall: boolean,
	Fallen: boolean, -- crumbling or already gone
}

local CrumbleRules = {}

-- Seconds after the round start of the n-th crumble (n = 1, 2, ...).
function CrumbleRules.timeOf(n: number): number
	local crumble = Config.Round.Crumble
	return crumble.StartTime + (n - 1) * crumble.Interval
end

-- The platform that crumbles next, or nil if none may fall. `pick(count)` returns a random index in 1..count.
function CrumbleRules.pick(platforms: { Platform }, pick: (count: number) -> number): string?
	local standing = 0
	local candidates: { string } = {}
	for _, platform in platforms do
		if not platform.Fallen then
			standing += 1
			if platform.CanFall then
				table.insert(candidates, platform.Id)
			end
		end
	end
	if #candidates == 0 or standing - 1 < Config.Round.Crumble.MinPlatformsRemaining then
		return nil
	end
	return candidates[pick(#candidates)]
end

return CrumbleRules
