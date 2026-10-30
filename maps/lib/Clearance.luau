--!strict
--[[
	Clearance — what's already in a finished map, as boxes, for passes that add things to it (maps/lib/Roofs, the
	Town's street furniture): a new piece goes in only where its box clears every part by a little margin, the stairs
	and ladders by 3 studs (room to step on and off them), the gameplay spots by 3.5 and the movers' whole paths (a
	lift's run, a wheel's or a crane's turn). The pieces a pass adds are added too, so they never overlap each other.
]]
local Clearance = {}

export type Box = { number } -- x0, y0, z0, x1, y1, z1

local CELL = 16 -- the grid's cell (studs)
Clearance.PartMargin = 0.6
local CLIMB_MARGIN = 3
local SPOT_MARGIN = 3.5

-- A part's world-axis box.
function Clearance.boxOf(part: any): Box
	local cf, size = part.CFrame, part.Size
	local p = cf.Position
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	local ex = math.abs(r.X) * hx + math.abs(u.X) * hy + math.abs(l.X) * hz
	local ey = math.abs(r.Y) * hx + math.abs(u.Y) * hy + math.abs(l.Y) * hz
	local ez = math.abs(r.Z) * hx + math.abs(u.Z) * hy + math.abs(l.Z) * hz
	return { p.X - ex, p.Y - ey, p.Z - ez, p.X + ex, p.Y + ey, p.Z + ez }
end

function Clearance.grow(box: Box, by: number): Box
	return { box[1] - by, box[2] - by, box[3] - by, box[4] + by, box[5] + by, box[6] + by }
end

function Clearance.union(a: Box, b: Box): Box
	return {
		math.min(a[1], b[1]),
		math.min(a[2], b[2]),
		math.min(a[3], b[3]),
		math.max(a[4], b[4]),
		math.max(a[5], b[5]),
		math.max(a[6], b[6]),
	}
end

local function overlaps(a: Box, b: Box): boolean
	return a[1] < b[4] and b[1] < a[4] and a[2] < b[5] and b[2] < a[5] and a[3] < b[6] and b[3] < a[6]
end

export type Grid = {
	cells: { [string]: { Box } },
	blocked: (self: Grid, box: Box) -> boolean,
	add: (self: Grid, box: Box) -> (),
}

local function add(self: Grid, box: Box)
	for gx = math.floor(box[1] / CELL), math.floor(box[4] / CELL) do
		for gz = math.floor(box[3] / CELL), math.floor(box[6] / CELL) do
			local key = `{gx},{gz}`
			local list = self.cells[key]
			if list == nil then
				list = {}
				self.cells[key] = list
			end
			table.insert(list, box)
		end
	end
end

local function blocked(self: Grid, box: Box): boolean
	for gx = math.floor(box[1] / CELL), math.floor(box[4] / CELL) do
		for gz = math.floor(box[3] / CELL), math.floor(box[6] / CELL) do
			for _, other in self.cells[`{gx},{gz}`] or {} do
				if overlaps(box, other) then
					return true
				end
			end
		end
	end
	return false
end

--[[
	Everything in `model` as boxes with the margins above (movers swept along their paths), leaving out the parts
	`ignore` says to (the surface a pass builds on). `add` a new piece's box (grown by PartMargin) once it is placed.
]]
function Clearance.new(model: any, ignore: (part: any) -> boolean): Grid
	local grid: Grid = { cells = {}, blocked = blocked, add = add }
	local inMover: { [any]: boolean } = {}
	for _, mover in model:GetDescendants() do
		if mover:IsA("Model") and mover:HasTag("Mover") then
			local pivot = mover.PrimaryPart
			local swept: Box? = nil
			local reach = 0
			for _, part in mover:GetDescendants() do
				if part:IsA("BasePart") then
					inMover[part] = true
					local box = Clearance.boxOf(part)
					swept = if swept then Clearance.union(swept, box) else box
					if pivot then
						local p = pivot.CFrame.Position
						for _, corner in { { box[1], box[2], box[3] }, { box[4], box[5], box[6] } } do
							local dx, dy, dz = corner[1] - p.X, corner[2] - p.Y, corner[3] - p.Z
							reach = math.max(reach, math.sqrt(dx * dx + dy * dy + dz * dz))
						end
					end
				end
			end
			if swept and pivot then
				local kind = mover:GetAttribute("Kind")
				local offset = mover:GetAttribute("Offset")
				local path: Box
				if (kind == "Lift" or kind == "Slide") and offset then
					path = Clearance.union(swept, {
						swept[1] + offset.X,
						swept[2] + offset.Y,
						swept[3] + offset.Z,
						swept[4] + offset.X,
						swept[5] + offset.Y,
						swept[6] + offset.Z,
					})
				else
					local p = pivot.CFrame.Position
					path = Clearance.union(
						swept,
						{ p.X - reach, p.Y - reach, p.Z - reach, p.X + reach, p.Y + reach, p.Z + reach }
					)
				end
				grid:add(Clearance.grow(path, Clearance.PartMargin))
			end
		end
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and not inMover[part] and not ignore(part) then
			local margin = Clearance.PartMargin
			if part:HasTag("Marker") then
				margin = SPOT_MARGIN
			elseif part:IsA("TrussPart") or part.Name == "Stair" then
				margin = CLIMB_MARGIN
			end
			grid:add(Clearance.grow(Clearance.boxOf(part), margin))
		end
	end
	return grid
end

-- A small seeded random in [0, 1) (the same pieces every build).
function Clearance.random(seedText: string): () -> number
	local state = 0
	for index = 1, #seedText do
		state = (state * 31 + string.byte(seedText, index)) % 2147483647
	end
	return function(): number
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
end

return Clearance
