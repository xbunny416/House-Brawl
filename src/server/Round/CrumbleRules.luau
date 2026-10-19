--!strict
--[[
	CrumbleRules — which platform crumbles next and when (pure; randomness is passed in). Bible §3.2.
	From Crumble.StartTime seconds into the round, every Crumble.Interval seconds one platform that can fall (not the
	center) starts its warning, as long as at least Crumble.MinPlatformsRemaining platforms (the center included) would
	still be standing afterwards. The arena closes in toward the centre (owner's fix list, 2026-10-19): the next one is
	picked at random from the outer ring — the standing platforms within Crumble.RingWidth studs of the farthest one
	from the arena's centre — so the outermost platforms go first and the middle last.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

export type Platform = {
	Id: string,
	CanFall: boolean,
	Fallen: boolean, -- crumbling or already gone
	Distance: number, -- studs from the arena's centre to the platform's centre, on the ground plane
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
	local farthest = -math.huge
	for _, platform in platforms do
		if not platform.Fallen then
			standing += 1
			if platform.CanFall then
				farthest = math.max(farthest, platform.Distance)
			end
		end
	end
	if farthest == -math.huge or standing - 1 < Config.Round.Crumble.MinPlatformsRemaining then
		return nil
	end
	local ring: { string } = {}
	for _, platform in platforms do
		if
			not platform.Fallen
			and platform.CanFall
			and platform.Distance >= farthest - Config.Round.Crumble.RingWidth
		then
			table.insert(ring, platform.Id)
		end
	end
	return ring[pick(#ring)]
end

return CrumbleRules
