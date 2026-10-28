--!strict
--[[
	Rooms — buildings you can walk into (owner, 2026-10-28: "town structure more bigger and can enter"): hollow shells of
	`Floors` storeys. Each storey's walls are split round their doors and windows into pieces no wider than
	Config.Structures.Walls.MaxPiece, so one break opens a hole, not a whole side; the pieces and the window glass are
	tagged BreakableWall (Services/WallService). Floors, stairs, roofs and parapets don't break.
	Inside: a floor slab on every upper storey with a hole over the stair well, and a ramp up each storey; the well has
	two lanes and the ramps take them in turn (odd storeys rise toward +Along, even ones back), so they switch back. The
	roof can let the stair on up through a hatch and has an optional low parapet.
	`At` is the footprint's centre (x, z) from the current origin; stair and opening spots are from there. Faces are
	"+X", "-X", "+Z", "-Z"; an opening's `At` runs along its face (world Z on an X face, world X on a Z face).
]]
local B = require("./Builder")
local Pieces = require("./Pieces")

local Rooms = {}

export type Opening = {
	Face: string,
	At: number,
	Width: number,
	Height: number,
	Bottom: number?, -- above the storey's floor (0 / nil: a doorway)
	Floor: number?, -- the storey (1 = ground, the default)
	Glass: boolean?, -- a glass pane fills it (a window)
}

export type Windows = {
	Faces: { string },
	Width: number,
	Height: number,
	Sill: number,
	Spacing: number,
	From: number?, -- the first storey with windows (1)
}

export type Spec = {
	Name: string,
	At: { number },
	Size: { number }, -- X, Z
	Floors: number,
	Storey: number, -- floor-to-floor height
	Wall: number?, -- thickness (0.8)
	Color: string,
	Material: string?,
	FloorColor: string?,
	FloorMaterial: string?,
	Openings: { Opening }?,
	Windows: Windows?,
	Stair: { At: { number }, Along: string, Width: number }?, -- the well's centre, its ramps along "X" or "Z"
	Roof: { Color: string, Material: string?, Hatch: boolean?, Parapet: boolean? }?,
	Breakable: boolean?, -- false: plain walls (true by default)
	MaxPiece: number?, -- the widest wall piece (16, Config.Structures.Walls.MaxPiece)
	Sill: string?, -- the colour of a sill under every window (nil: none); it goes when the wall under it breaks
}

-- The widest wall piece and glass pane (Config.Structures.Walls.MaxPiece / MaxGlass; the maps spec checks them).
local MAX_PIECE = 16
local MAX_GLASS = 26
local SLAB = 0.5 -- floor slab thickness
local ROOF = 0.6
local RAMP_RUN = 1.6 -- a ramp's length per stud of rise (about 32°)

type Rect = { number } -- x0, x1, z0, z1

-- A flat slab over `rect` (local x0, x1, z0, z1) with its top at `top`, leaving out `hole` (up to four parts).
local function slab(
	name: string,
	rect: Rect,
	hole: Rect?,
	top: number,
	thickness: number,
	color: string,
	material: string
)
	local function piece(x0: number, x1: number, z0: number, z1: number)
		if x1 - x0 > 0.01 and z1 - z0 > 0.01 then
			B.part({
				Name = name,
				Size = { x1 - x0, thickness, z1 - z0 },
				Position = { (x0 + x1) / 2, top - thickness / 2, (z0 + z1) / 2 },
				Color = color,
				Material = material,
				CastShadow = true,
			})
		end
	end
	local x0, x1, z0, z1 = rect[1], rect[2], rect[3], rect[4]
	if hole == nil or hole[2] <= x0 or hole[1] >= x1 or hole[4] <= z0 or hole[3] >= z1 then
		piece(x0, x1, z0, z1)
		return
	end
	local hx0, hx1 = math.max(hole[1], x0), math.min(hole[2], x1)
	local hz0, hz1 = math.max(hole[3], z0), math.min(hole[4], z1)
	piece(x0, x1, z0, hz0)
	piece(x0, x1, hz1, z1)
	piece(x0, hx0, hz0, hz1)
	piece(hx1, x1, hz0, hz1)
end

-- The openings in face `face` on storey `storey`: the spec's own, then its windows where they don't overlap them.
local function openingsOf(spec: Spec, face: string, storey: number, length: number): { Opening }
	local list: { Opening } = {}
	for _, opening in spec.Openings or {} do
		if opening.Face == face and (opening.Floor or 1) == storey then
			table.insert(list, opening)
		end
	end
	local windows = spec.Windows
	if windows and table.find(windows.Faces, face) and storey >= (windows.From or 1) then
		local count = math.max(1, math.floor((length - 2) / windows.Spacing))
		for index = 1, count do
			local at = (index - (count + 1) / 2) * windows.Spacing
			local clear = true
			for _, opening in list do
				if math.abs(at - opening.At) < (opening.Width + windows.Width) / 2 + 0.5 then
					clear = false
				end
			end
			if clear then
				table.insert(list, {
					Face = face,
					At = at,
					Width = windows.Width,
					Height = windows.Height,
					Bottom = windows.Sill,
					Floor = storey,
					Glass = true,
				})
			end
		end
	end
	return list
end

-- One storey of one face: solid pieces round its openings (no wider than `maxPiece`), glass in its windows.
local function face(spec: Spec, faceName: string, storey: number, maxPiece: number)
	local sx, sz = spec.Size[1], spec.Size[2]
	local wall = spec.Wall or 0.8
	local height = spec.Storey
	local floorY = (storey - 1) * height
	local alongX = string.sub(faceName, 2) == "Z" -- a Z face runs along X
	local sign = if string.sub(faceName, 1, 1) == "+" then 1 else -1
	local length = if alongX then sx - 2 * wall else sz
	local plane = sign * ((if alongX then sz else sx) / 2 - wall / 2)
	local breakable = spec.Breakable ~= false
	local material = spec.Material or "Concrete"
	local openings = openingsOf(spec, faceName, storey, length)

	-- Builds the pieces from `a` to `b` along the face between heights `y0` and `y1`; returns the first one.
	local function piece(a: number, b: number, y0: number, y1: number, glass: boolean): any
		if b - a <= 0.01 or y1 - y0 <= 0.01 then
			return nil
		end
		local count = math.ceil((b - a) / (if glass then MAX_GLASS else maxPiece) - 1e-6)
		local step = (b - a) / count
		local first = nil
		for index = 1, count do
			local p0 = a + (index - 1) * step
			local middle = p0 + step / 2
			local thickness = if glass then 0.3 else wall
			local part = B.part({
				Name = if glass then "Glass" else "Wall",
				Size = if alongX then { step, y1 - y0, thickness } else { thickness, y1 - y0, step },
				Position = if alongX
					then { middle, floorY + (y0 + y1) / 2, plane }
					else { plane, floorY + (y0 + y1) / 2, middle },
				Color = if glass then "Glass" else spec.Color,
				Material = if glass then "Glass" else material,
				Transparency = if glass then 0.45 else nil,
				CastShadow = not glass,
				Tags = if breakable then { "BreakableWall" } else nil,
			})
			if glass then
				part.Reflectance = 0.15
			end
			first = first or part
		end
		return first
	end

	-- Breakpoints along the face, then each interval: solid, or round the opening that covers it.
	local half = length / 2
	local cuts = { -half, half }
	for _, opening in openings do
		table.insert(cuts, math.clamp(opening.At - opening.Width / 2, -half, half))
		table.insert(cuts, math.clamp(opening.At + opening.Width / 2, -half, half))
	end
	table.sort(cuts)
	local solidFrom: number? = nil
	local function flush(upTo: number)
		if solidFrom then
			piece(solidFrom, upTo, 0, height, false)
			solidFrom = nil
		end
	end
	for index = 1, #cuts - 1 do
		local a, b = cuts[index], cuts[index + 1]
		if b - a > 0.01 then
			local middle = (a + b) / 2
			local cover: Opening? = nil
			for _, opening in openings do
				if math.abs(middle - opening.At) < opening.Width / 2 then
					cover = opening
				end
			end
			if cover then
				flush(a)
				local bottom = cover.Bottom or 0
				local top = math.min(bottom + cover.Height, height)
				local below = piece(a, b, 0, bottom, false)
				piece(a, b, top, height, false)
				if cover.Glass then
					piece(a, b, bottom, top, true)
					-- A sill standing out under the window (walk-through), carried by the wall below it.
					local sillColor = spec.Sill
					if sillColor and below then
						local out = plane + sign * (wall / 2 + 0.1)
						local y = floorY + bottom - 0.125
						local sill = B.part({
							Name = "Sill",
							Size = if alongX then { b - a + 0.4, 0.25, 0.5 } else { 0.5, 0.25, b - a + 0.4 },
							Position = if alongX then { (a + b) / 2, y, out } else { out, y, (a + b) / 2 },
							Color = sillColor,
							Material = "Concrete",
							CanCollide = false,
						})
						sill.Parent = below
					end
				end
			elseif solidFrom == nil then
				solidFrom = a
			end
		end
	end
	flush(half)
end

-- Builds the building (a Model named spec.Name) and returns it.
function Rooms.building(spec: Spec): any
	local sx, sz = spec.Size[1], spec.Size[2]
	local wall = spec.Wall or 0.8
	local height = spec.Storey
	local maxPiece = spec.MaxPiece or MAX_PIECE
	local floorColor = spec.FloorColor or "ConcreteLight"
	local floorMaterial = spec.FloorMaterial or "Concrete"
	local stair = spec.Stair
	local run = height * RAMP_RUN
	local well: Rect? = nil
	if stair then
		local cx, cz = stair.At[1], stair.At[2]
		well = if stair.Along == "X"
			then { cx - run / 2, cx + run / 2, cz - stair.Width, cz + stair.Width }
			else { cx - stair.Width, cx + stair.Width, cz - run / 2, cz + run / 2 }
	end
	return B.model(spec.Name, function()
		B.within({ spec.At[1], 0, spec.At[2] }, function()
			local inner: Rect = { -sx / 2 + wall, sx / 2 - wall, -sz / 2 + wall, sz / 2 - wall }
			B.part({
				Name = "GroundFloor",
				Size = { inner[2] - inner[1], 0.1, inner[4] - inner[3] },
				Position = { 0, 0.06, 0 },
				Color = floorColor,
				Material = floorMaterial,
				CanCollide = false,
				CastShadow = false,
			})
			for storey = 1, spec.Floors do
				for _, faceName in { "+X", "-X", "+Z", "-Z" } do
					face(spec, faceName, storey, maxPiece)
				end
				if storey > 1 then
					slab("Floor", inner, well, (storey - 1) * height, SLAB, floorColor, floorMaterial)
				end
			end
			local roof = spec.Roof
			if roof then
				local top = spec.Floors * height
				slab(
					"Roof",
					{ -sx / 2, sx / 2, -sz / 2, sz / 2 },
					if roof.Hatch then well else nil,
					top + ROOF,
					ROOF,
					roof.Color,
					roof.Material or "Concrete"
				)
				if roof.Parapet then
					for _, edge in
						{
							{ { 0, sz / 2 - 0.25 }, { sx, 0.5 } },
							{ { 0, -sz / 2 + 0.25 }, { sx, 0.5 } },
							{ { sx / 2 - 0.25, 0 }, { 0.5, sz - 1 } },
							{ { -sx / 2 + 0.25, 0 }, { 0.5, sz - 1 } },
						}
					do
						Pieces.block(
							"Parapet",
							edge[1],
							{ edge[2][1], 1.2, edge[2][2] },
							roof.Color,
							roof.Material or "Concrete",
							top + ROOF
						)
					end
				end
			end
			-- The ramps: one per storey (and on up to the roof through its hatch), taking the well's lanes in turn.
			if stair and well then
				local storeys = spec.Floors - 1 + (if roof and roof.Hatch then 1 else 0)
				for storey = 1, storeys do
					local laneOffset = (if storey % 2 == 1 then -1 else 1) * stair.Width / 2
					local rising = if storey % 2 == 1 then 1 else -1
					local cx, cz = stair.At[1], stair.At[2]
					local low: { number }, high: { number }
					if stair.Along == "X" then
						low = { cx - rising * run / 2, cz + laneOffset }
						high = { cx + rising * run / 2, cz + laneOffset }
					else
						low = { cx + laneOffset, cz - rising * run / 2 }
						high = { cx + laneOffset, cz + rising * run / 2 }
					end
					local rise = if storey == spec.Floors then height + ROOF else height
					Pieces.ramp("Stair", low, high, stair.Width, rise, floorColor, floorMaterial, (storey - 1) * height)
				end
			end
		end)
	end)
end

return Rooms
