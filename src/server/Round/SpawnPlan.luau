--!strict
--[[
	SpawnPlan — where each fighter starts a round (pure). Spawn points are grouped by the platform they stand on.
	A group (parties used this until they were removed on 2026-10-19; RoundService now puts every fighter in a group
	of one) starts on one platform: the biggest groups first, each on the platform with the most free points (members
	that don't fit fall back to the solo rule). Solo fighters spread out: each takes a free point on the platform with
	the most free points left. When there are more fighters than points, points are reused.

	Close starts (owner, 2026-10-30: "how it plays"): on an arena of one platform (Shinjuku, 560 × 340) random points
	put fighters up to 400 studs apart, half a minute's run before the first punch. Given the points' positions, the
	fighters there start at a random point and the points nearest to it. Respawns (`respawn`) come back a little way
	from the nearest fighter.
]]
local SpawnPlan = {}

export type Band = { MinEnemyDistance: number, MaxEnemyDistance: number }

local function distance(a: { number }, b: { number }): number
	local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--[[
	`groups`: lists of UserIds (one fighter each, or a group to keep together). `platforms`: the platform of each
	spawn point (by index). `pick(n)` returns a random 1..n. `positions` (optional): each point's { x, y, z }, for the
	close start on a single platform. Returns the spawn point index for every UserId.
]]
function SpawnPlan.assign(
	groups: { { number } },
	platforms: { string },
	pick: (number) -> number,
	positions: { { number } }?
): { [number]: number }
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
	-- One platform: nearest to a random point last (points are taken from the end), so fighters start close.
	if #order == 1 and positions then
		local list = free[order[1]]
		local focus = positions[list[pick(#list)]]
		table.sort(list, function(a: number, b: number): boolean
			return distance(positions[a], focus) > distance(positions[b], focus)
		end)
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

--[[
	Where a fighter comes back into a running round (a respawn, a late joiner): `points` are the spawn points'
	{ x, y, z }, `enemies` the other fighters'. A random point whose nearest fighter is within the band; failing that,
	the nearest point at least MinEnemyDistance from every fighter; failing that, the point farthest from them. With
	nobody else in the arena, any point. Returns the point's index (0 when there are no points).
]]
function SpawnPlan.respawn(
	points: { { number } },
	enemies: { { number } },
	band: Band,
	pick: (number) -> number
): number
	if #points == 0 then
		return 0
	end
	if #enemies == 0 then
		return pick(#points)
	end
	local inBand: { number } = {}
	local safest, safestGap = 1, -math.huge
	local closest, closestGap = 0, math.huge
	for index, point in points do
		local gap = math.huge
		for _, enemy in enemies do
			gap = math.min(gap, distance(point, enemy))
		end
		if gap >= band.MinEnemyDistance and gap <= band.MaxEnemyDistance then
			table.insert(inBand, index)
		end
		if gap >= band.MinEnemyDistance and gap < closestGap then
			closest, closestGap = index, gap
		end
		if gap > safestGap then
			safest, safestGap = index, gap
		end
	end
	if #inBand > 0 then
		return inBand[pick(#inBand)]
	end
	return if closest > 0 then closest else safest
end

return SpawnPlan
