--!strict
--[[
	SpawnPlan — where each fighter starts a round (pure). Spawn points are grouped by the platform they stand on.
	A group (parties used this until they were removed on 2026-10-19; RoundService now puts every fighter in a group
	of one) starts on one platform: the biggest groups first, each on the platform with the most free points (members
	that don't fit fall back to the solo rule). Solo fighters spread out: each takes a free point on the platform with
	the most free points left. When there are more fighters than points, points are reused.
]]
local SpawnPlan = {}

--[[
	`groups`: lists of UserIds (one fighter each, or a group to keep together). `platforms`: the platform of each
	spawn point (by index). `pick(n)` returns a random 1..n. Returns the spawn point index for every UserId.
]]
function SpawnPlan.assign(groups: { { number } }, platforms: { string }, pick: (number) -> number): { [number]: number }
	local plan: { [number]: number } = {}
	if #platforms == 0 then
		return plan
	end
	-- Free points per platform, in a random order.
	local free: { [string]: { number } } = {}
	local order: { string } = {}
	for index, platform in platforms do
		local list = free[platform]
		if list == nil then
			list = {}
			free[platform] = list
			table.insert(order, platform)
		end
		table.insert(list, pick(#list + 1), index)
	end
	-- The platform with the most free points (ties: the first in a random order).
	for index = #order, 2, -1 do
		local swap = pick(index)
		order[index], order[swap] = order[swap], order[index]
	end
	local function roomiest(): string?
		local best, size = nil, 0
		for _, platform in order do
			if #free[platform] > size then
				best, size = platform, #free[platform]
			end
		end
		return best
	end
	local function take(userId: number, platform: string?): boolean
		local list = platform and free[platform]
		if list == nil or #list == 0 then
			return false
		end
		plan[userId] = table.remove(list) :: number
		return true
	end

	local sorted = table.clone(groups)
	table.sort(sorted, function(a: { number }, b: { number }): boolean
		return #a > #b
	end)
	local solos: { number } = {}
	for _, group in sorted do
		if #group >= 2 then
			local platform = roomiest()
			for _, userId in group do
				if not take(userId, platform) then
					table.insert(solos, userId)
				end
			end
		else
			table.insert(solos, group[1])
		end
	end
	local reuse = 0
	for _, userId in solos do
		if not take(userId, roomiest()) then
			reuse += 1
			plan[userId] = (reuse - 1) % #platforms + 1
		end
	end
	return plan
end

return SpawnPlan
