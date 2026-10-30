--!strict
--[[
	Roofs — rooftop gear on the walk-in buildings' roofs (owner, 2026-10-30: "add detail to the roofs"), as a pass over
	a finished map: AC condensers, vent stacks, mushroom vents, skylights, solar panels, ducts and exhaust fans along
	each roof's edge (the middle stays open to fight on and for props to land), lightning rods on tall buildings and
	membrane seams across big roofs.

	It works from what was built, not from the layouts: a roof is a building model's "Roof" pieces (Rooms leaves the
	stair hatch out of them), and a thing only goes where it stands wholly on a roof piece and clears everything
	already there (maps/lib/Clearance) — every part (a little margin), the stairs and ladders (3 studs, to step off
	them), the gameplay spots (3.5) and the movers' paths (a lift's run, a wheel's whole turn). The bigger items are solid like the other
	roof units; the small ones walk-through. Each building's gear goes into its model, so it streams in with it.
]]
local B = require("./Builder")
local Clearance = require("./Clearance")

local Roofs = {}

type Box = Clearance.Box

local INSET = 1.4 -- from a roof's outer edge to where gear may start (the parapet is 0.5)
local SPACING = 7 -- between slots along an edge
local TALL = 35 -- studs from its ground floor up to its roof from which a building gets lightning rods

--[[
	The gear, built facing in from the edge: `at` is its centre on the roof (x, z), `yaw` turns its local −Z (its
	front) to face the roof's middle, `y` is the roof's top. Each kind has a footprint (width along the edge, depth
	in from it) and a build.
]]
type Kind = { Size: { number }, Height: number, Build: (at: { number }, yaw: number, y: number) -> () }

local function place(at: { number }, yaw: number): (lx: number, ly: number, lz: number) -> { number }
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	return function(lx: number, ly: number, lz: number): { number }
		return { at[1] + lx * c + lz * s, ly, at[2] - lx * s + lz * c }
	end
end

local function piece(spec: { [string]: any }): any
	spec.CastShadow = spec.CastShadow or false
	return B.part(spec :: any)
end

local KINDS: { [string]: Kind } = {
	-- An AC condenser: a box with a fan grille on top and a pipe down into the roof (solid).
	Condenser = {
		Size = { 3.2, 3 },
		Height = 2.2,
		Build = function(at, yaw, y)
			local p = place(at, yaw)
			piece({
				Name = "Condenser",
				Size = { 3, 1.8, 2.4 },
				Position = p(0, y + 0.9, -0.2),
				Yaw = yaw,
				Color = "Metal",
				Material = "Metal",
				CastShadow = true,
			})
			piece({
				Name = "CondenserFan",
				Size = { 0.12, 1.8, 1.8 },
				Position = p(0, y + 1.86, -0.2),
				Rotation = { 0, yaw, 90 },
				Shape = "Cylinder",
				Color = "Iron",
				Material = "DiamondPlate",
				CanCollide = false,
			})
			piece({
				Name = "CondenserPipe",
				Size = { 0.3, 0.3, 0.6 },
				Position = p(1.2, y + 0.3, 1.2),
				Yaw = yaw,
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end,
	},
	-- A vent stack: a pipe with a rain cap (walk-through).
	VentStack = {
		Size = { 1.2, 1.2 },
		Height = 3,
		Build = function(at, _yaw, y)
			piece({
				Name = "VentPipe",
				Size = { 2.6, 0.5, 0.5 },
				Position = { at[1], y + 1.3, at[2] },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			piece({
				Name = "VentCap",
				Size = { 0.25, 1, 1 },
				Position = { at[1], y + 2.75, at[2] },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "Metal",
				Material = "Metal",
				CanCollide = false,
			})
		end,
	},
	-- A mushroom vent: a short drum under a wide cap (solid, knee-high).
	Mushroom = {
		Size = { 2, 2 },
		Height = 1.3,
		Build = function(at, _yaw, y)
			piece({
				Name = "MushroomVent",
				Size = { 0.8, 1.2, 1.2 },
				Position = { at[1], y + 0.4, at[2] },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "ConcreteLight",
				Material = "Metal",
			})
			piece({
				Name = "MushroomCap",
				Size = { 0.35, 1.9, 1.9 },
				Position = { at[1], y + 0.98, at[2] },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "Metal",
				Material = "Metal",
				CanCollide = false,
			})
		end,
	},
	-- A skylight: a curb with a glass top (solid, knee-high).
	Skylight = {
		Size = { 4.4, 3.4 },
		Height = 0.9,
		Build = function(at, yaw, y)
			local p = place(at, yaw)
			piece({
				Name = "SkylightCurb",
				Size = { 4.2, 0.7, 3.2 },
				Position = p(0, y + 0.35, 0),
				Yaw = yaw,
				Color = "ConcreteDark",
				Material = "Concrete",
				CastShadow = true,
			})
			local glass = piece({
				Name = "SkylightGlass",
				Size = { 3.8, 0.12, 2.8 },
				Position = p(0, y + 0.76, 0),
				Yaw = yaw,
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.3,
				CanCollide = false,
			})
			glass.Reflectance = 0.2
		end,
	},
	-- A solar panel tilted up toward the middle of the roof, on a frame (walk-through).
	Solar = {
		Size = { 4.4, 2.8 },
		Height = 1.6,
		Build = function(at, yaw, y)
			local p = place(at, yaw)
			piece({
				Name = "SolarPanel",
				Size = { 4.2, 0.12, 2.6 },
				Position = p(0, y + 0.9, 0),
				Yaw = yaw,
				Rotation = { 20, 0, 0 },
				Color = "ArcadeBlue",
				Material = "Glass",
				CanCollide = false,
			})
			piece({
				Name = "SolarFrame",
				Size = { 3.8, 1.2, 0.2 },
				Position = p(0, y + 0.6, 0.9),
				Yaw = yaw,
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end,
	},
	-- A duct along the edge, turning down into the roof at one end (solid).
	Duct = {
		Size = { 6.4, 1.6 },
		Height = 1.6,
		Build = function(at, yaw, y)
			local p = place(at, yaw)
			piece({
				Name = "Duct",
				Size = { 5.2, 1.2, 1.2 },
				Position = p(0.6, y + 1, 0),
				Yaw = yaw,
				Color = "Metal",
				Material = "Metal",
				CastShadow = true,
			})
			piece({
				Name = "DuctElbow",
				Size = { 1.2, 1.6, 1.2 },
				Position = p(-2.6, y + 0.8, 0),
				Yaw = yaw,
				Color = "Metal",
				Material = "Metal",
			})
		end,
	},
	-- An exhaust fan: a housing with a hood on top (solid, waist-high).
	Exhaust = {
		Size = { 2, 2 },
		Height = 1.8,
		Build = function(at, yaw, y)
			local p = place(at, yaw)
			piece({
				Name = "ExhaustHousing",
				Size = { 1.6, 1.1, 1.6 },
				Position = p(0, y + 0.55, 0),
				Yaw = yaw,
				Color = "ConcreteLight",
				Material = "Metal",
			})
			piece({
				Name = "ExhaustHood",
				Size = { 0.6, 1.8, 1.8 },
				Position = p(0, y + 1.4, 0),
				Rotation = { 0, yaw, 90 },
				Shape = "Cylinder",
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end,
	},
}

-- How often each kind comes up (a weighted pick).
local MIX = {
	{ "Condenser", 4 },
	{ "VentStack", 3 },
	{ "Mushroom", 2 },
	{ "Exhaust", 2 },
	{ "Duct", 2 },
	{ "Skylight", 2 },
	{ "Solar", 2 },
}

local function pick(roll: number): string
	local total = 0
	for _, entry in MIX do
		total += entry[2]
	end
	local at = roll * total
	for _, entry in MIX do
		at -= entry[2]
		if at < 0 then
			return entry[1]
		end
	end
	return MIX[1][1]
end

-- True when every corner of the footprint (a centre, its half sizes along X and Z) stands on one of `pieces`.
local function onRoof(pieces: { Box }, cx: number, cz: number, hx: number, hz: number): boolean
	for _, corner in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
		local x, z = cx + corner[1] * hx, cz + corner[2] * hz
		local inside = false
		for _, roof in pieces do
			if x >= roof[1] + 0.3 and x <= roof[4] - 0.3 and z >= roof[3] + 0.3 and z <= roof[6] - 0.3 then
				inside = true
				break
			end
		end
		if not inside then
			return false
		end
	end
	return true
end

-- Dresses one building's roof; returns how many things it added.
local function dressRoof(building: any, grid: Clearance.Grid): number
	local pieces: { Box } = {}
	local roofColor = nil
	for _, part in building:GetChildren() do
		if part:IsA("BasePart") and part.Name == "Roof" then
			table.insert(pieces, Clearance.boxOf(part))
			roofColor = roofColor or part.Color
		end
	end
	if #pieces == 0 then
		return 0
	end
	local bounds = pieces[1]
	for _, roof in pieces do
		bounds = Clearance.union(bounds, roof)
	end
	local top = bounds[5]
	local x0, z0, x1, z1 = bounds[1], bounds[3], bounds[4], bounds[6]
	local roll = Clearance.random(building.Name)
	local added = 0
	local ground = Clearance.boxOf(building:FindFirstChild("GroundFloor"))[2]
	local height = top - ground
	local maxItems = math.clamp(math.floor(((x1 - x0) + (z1 - z0)) * 2 / 13), 3, 14)
	local items = 0

	local function try(kindName: string, cx: number, cz: number, yaw: number): boolean
		local kind = KINDS[kindName]
		local alongX = math.abs(math.sin(math.rad(yaw))) < 0.5 -- facing ±Z: the width runs along X
		local hx = (if alongX then kind.Size[1] else kind.Size[2]) / 2
		local hz = (if alongX then kind.Size[2] else kind.Size[1]) / 2
		if not onRoof(pieces, cx, cz, hx, hz) then
			return false
		end
		local box = { cx - hx, top + 0.05, cz - hz, cx + hx, top + kind.Height, cz + hz }
		if grid:blocked(box) then
			return false
		end
		B.into(building, function()
			kind.Build({ cx, cz }, yaw, top)
		end)
		grid:add(Clearance.grow(box, Clearance.PartMargin))
		return true
	end

	-- Gear along the four edges, facing the middle.
	local edges = {
		{ from = { x0, z0 }, along = { 1, 0 }, length = x1 - x0, inward = { 0, 1 }, yaw = 180 },
		{ from = { x0, z1 }, along = { 1, 0 }, length = x1 - x0, inward = { 0, -1 }, yaw = 0 },
		{ from = { x0, z0 }, along = { 0, 1 }, length = z1 - z0, inward = { 1, 0 }, yaw = -90 },
		{ from = { x1, z0 }, along = { 0, 1 }, length = z1 - z0, inward = { -1, 0 }, yaw = 90 },
	}
	for _, edge in edges do
		local slots = math.floor((edge.length - 6) / SPACING)
		for slot = 0, slots do
			if items >= maxItems then
				break
			end
			if roll() < 0.25 then
				continue
			end
			local kindName = pick(roll())
			local depth = KINDS[kindName].Size[2]
			local d = 3 + slot * SPACING + roll() * 2
			local inset = INSET + depth / 2
			local cx = edge.from[1] + edge.along[1] * d + edge.inward[1] * inset
			local cz = edge.from[2] + edge.along[2] * d + edge.inward[2] * inset
			if try(kindName, cx, cz, edge.yaw) then
				items += 1
				added += 1
			end
		end
	end

	-- Lightning rods on the parapet corners of tall buildings.
	if height >= TALL then
		for _, corner in { { x0, z0 }, { x0, z1 }, { x1, z0 }, { x1, z1 } } do
			local cx = corner[1] + (if corner[1] == x0 then 0.25 else -0.25)
			local cz = corner[2] + (if corner[2] == z0 then 0.25 else -0.25)
			B.into(building, function()
				piece({
					Name = "LightningRod",
					Size = { 3, 0.15, 0.15 },
					Position = { cx, top + 1.45 + 1.5, cz },
					Rotation = { 0, 0, 90 },
					Shape = "Cylinder",
					Color = "Brass",
					Material = "Metal",
					CanCollide = false,
				})
			end)
			added += 1
		end
	end

	-- Membrane seams across a big roof (along its long side, every 8 studs; flat and walk-through).
	if roofColor and math.min(x1 - x0, z1 - z0) >= 20 then
		local alongX = (x1 - x0) >= (z1 - z0)
		local seamColor = B.shade(roofColor:ToHex(), 0.82)
		local from, to = if alongX then z0 else x0, if alongX then z1 else x1
		local line = from + 8
		while line < to - 4 do
			for _, roof in pieces do
				local lo, hi = if alongX then roof[3] else roof[1], if alongX then roof[6] else roof[4]
				if line > lo + 0.5 and line < hi - 0.5 then
					local a, b = if alongX then roof[1] else roof[3], if alongX then roof[4] else roof[6]
					local length = b - a - 1.2
					if length > 2 then
						local middle = (a + b) / 2
						B.into(building, function()
							piece({
								Name = "RoofSeam",
								Size = if alongX then { length, 0.04, 0.2 } else { 0.2, 0.04, length },
								Position = if alongX
									then { middle, top + 0.02, line }
									else { line, top + 0.02, middle },
								Color = seamColor,
								Material = "Slate",
								CanCollide = false,
							})
						end)
						added += 1
					end
				end
			end
			line += 8
		end
	end
	return added
end

-- Dresses the roof of every walk-in building (a Model with a GroundFloor) in `district`, clearing everything in `model`.
-- Returns how many parts were added.
function Roofs.dress(district: any, model: any): number
	local grid = Clearance.new(model, function(part: any): boolean
		return part.Name == "Roof" -- what the gear stands on
	end)
	local added = 0
	for _, building in district:GetChildren() do
		if building:IsA("Model") and building:FindFirstChild("GroundFloor") then
			added += dressRoof(building, grid)
		end
	end
	return added
end

return Roofs
