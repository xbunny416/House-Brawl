--!strict
--[[
	Map 4: Small City — the only arena in the vote since 2026-10-28 (owner: "make another, only one arena instead of the 3
	old arenas, just store them somewhere, don't delete them; this one is just like the default small city in Roblox but
	still has throwable objects in it"). Broken Highway, Junkyard Isles and Neon Motel stay built and in the place,
	switched off in Config.Maps.List.

	A small daytime town torn into blocks that float in a bright, hazy sky (Day lighting: a blue sky with white clouds,
	like a fresh Roblox place). It keeps the shared arena rules (Arena.luau): 13 platforms in four layers, gaps 8–14,
	climbs ≤ 6, 16 spawns, 24 loose prop spots, 8 breakable structures, 1 explosive barrel per side and low platform,
	KillY 60 studs below the lowest platform. The platforms sit where Neon Motel's do (the same tested gaps, climbs and
	bridges); everything on them is new.
	  Center 224×144 (never falls) — downtown: two streets each way around a park, crosswalks, traffic lights, street
	    lamps, a bus stop, a phone booth, a hot dog cart, parked cars; in the park a raised fountain plaza (+6, a ramp on
	    each end) with trees and benches.
	  East (+1) — a gas station: a canopy over the pumps, a mini mart, a price sign. West (−1) — two suburban houses
	    with pitched roofs, front fences, mailboxes, a doghouse. North (−3) — a parking lot with parked cars and a
	    ticket booth. South (−2) — a basketball court with two hoops.
	  Ledges (+6) and peaks (+12) — office and tower rooftops (the buildings reach down into the haze): stair huts, AC
	    units, a water tank, a billboard; a helipad and a radio mast on the peaks.
	  Low lots (−5 / −7) — a construction site and a bus depot.
	  Bridges — road bridges from the centre to West and South, steel gangways between the rest (Neon Motel's six).
	Under each street block hangs the earth and rock it was torn out with. Edge decor stays low so knockback carries
	over it.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")
local Pieces = require("../lib/Pieces")

type Platform = Arena.Platform
type Contents = Arena.Contents

local Layout = {}

Layout.Id = "SmallCity"
Layout.Lighting = "Day"

-- One platform entry (keeps the list short).
local function platform(
	id: string,
	kind: string,
	center: { number },
	size: { number },
	top: number,
	thickness: number,
	color: string,
	material: string
): Platform
	return {
		Id = id,
		Kind = kind :: any,
		Center = center,
		Size = size,
		Top = top,
		Thickness = thickness,
		Color = color,
		Material = material,
	}
end

local center = platform("Center", "Center", { 0, 0 }, { 112, 72 }, 0, 5, "Concrete", "Concrete")
center.Deck = { Size = { 28, 18 }, Height = 6, Ramp = 12, RampWidth = 12 }

-- Laid out at half size and doubled by Arena.grow (keeping the gaps), exactly like Neon Motel's platforms.
local GROWTH = 2

Layout.Platforms = Arena.grow({
	center,
	platform("East", "Side", { 90, -4 }, { 48, 52 }, 1, 4, "Concrete", "Concrete"),
	platform("West", "Side", { -90, 6 }, { 44, 44 }, -1, 4, "Lawn", "Grass"),
	platform("North", "Side", { 8, 68 }, { 52, 40 }, -3, 4, "Asphalt", "Asphalt"),
	platform("South", "Side", { -8, -67 }, { 48, 40 }, -2, 4, "Concrete", "Concrete"),
	platform("LedgeNE", "Ledge", { 72, 52 }, { 20, 20 }, 6, 2, "ConcreteDark", "Concrete"),
	platform("LedgeSW", "Ledge", { -74, -50 }, { 24, 16 }, 6, 2, "ConcreteDark", "Concrete"),
	platform("LedgeNW", "Ledge", { -72, 52 }, { 20, 20 }, 6, 2, "ConcreteDark", "Concrete"),
	platform("LedgeSE", "Ledge", { 72, -52 }, { 20, 20 }, 6, 2, "ConcreteDark", "Concrete"),
	platform("PeakNE", "Peak", { 98, 78 }, { 18, 18 }, 12, 3, "ConcreteDark", "Concrete"),
	platform("PeakSW", "Peak", { -102, -74 }, { 18, 18 }, 12, 3, "ConcreteDark", "Concrete"),
	platform("LowEast", "Low", { 138, -4 }, { 28, 28 }, -5, 4, "Soil", "Ground"),
	platform("LowWest", "Low", { -136, 6 }, { 28, 28 }, -7, 4, "Asphalt", "Asphalt"),
}, GROWTH)

-- Spots at the final size (from each platform's top centre).
Layout.Contents = {
	Center = {
		Spawns = { { -100, -62 }, { 100, 62 }, { -100, 62 }, { 100, -62 }, { 0, -40 }, { 0, 40 } },
		Props = {
			{ -34, -40 },
			{ 34, 40 },
			{ -62, 0 },
			{ 62, 0 },
			{ -30, 58 },
			{ 36, -58 },
			{ 82, 14 },
			{ -82, -16 },
		},
		Structures = {
			{ Type = "WreckedCar", At = { 85.5, -14 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { -8, 66 }, Yaw = 0 },
			{ Type = "RoadBarrierStack", At = { -82, 15 }, Yaw = 0 },
		},
	},
	East = {
		Spawns = { { -30, 30 }, { 30, -36 } },
		Props = { { -38, -20 }, { 24, 4 }, { -20, 44 } },
		Explosive = { 0, -36 },
		Structures = { { Type = "IceMachine", At = { -2, 32 }, Yaw = 0 } },
	},
	West = {
		Spawns = { { 12, -36 }, { 12, 36 } },
		Props = { { 37, -30 }, { 37, 2 }, { -36, 24 } },
		Explosive = { 2, 0 },
		Structures = { { Type = "LawnChairStack", At = { -36, -4 }, Yaw = 90 } },
	},
	North = {
		Spawns = { { -36, -4 }, { 36, 4 } },
		Props = { { 26, -6 }, { -22, 8 } },
		Explosive = { 0, 0 },
		Structures = { { Type = "WreckedCar", At = { -3, 22 }, Yaw = 0 } },
	},
	South = {
		Spawns = { { 36, -20 }, { -38, 22 } },
		Props = { { -24, -14 }, { 12, 4 } },
		Explosive = { -6, -6 },
	},
	LedgeNE = { Props = { { -10, -10 } } },
	LedgeSW = { Props = { { 6, 6 } } },
	LedgeNW = { Props = { { -8, -10 } } },
	LedgeSE = { Props = { { 8, 10 } } },
	LowEast = {
		Spawns = { { -12, -12 } },
		Props = { { 12, 12 } },
		Explosive = { 16, -16 },
		Structures = { { Type = "RoadBarrierStack", At = { -14, 16 }, Yaw = 0 } },
	},
	LowWest = {
		Spawns = { { 12, 12 } },
		Props = { { -12, -12 } },
		Explosive = { -16, 14 },
		Structures = { { Type = "VendingMachine", At = { 14, -16 }, Yaw = 0 } },
	},
} :: { [string]: Contents }

function Layout.killY(): number
	return Arena.killY(Layout.Platforms)
end

---------------------------------------------------------------------------------------------------------------------
-- Pieces (positions from the platform's top centre)
---------------------------------------------------------------------------------------------------------------------

-- Paint on the ground: a flat, walk-through strip `size` (X, Z) at `y` (roads 0.05, lines 0.12).
local function paint(name: string, at: { number }, size: { number }, color: string, material: string?, y: number?)
	B.part({
		Name = name,
		Size = { size[1], if y and y > 0.1 then 0.02 else 0.1, size[2] },
		Position = { at[1], y or 0.05, at[2] },
		Color = color,
		Material = material or "SmoothPlastic",
		CanCollide = false,
		CastShadow = false,
	})
end

-- A world point `lx` to the right, `ly` up and `lz` ahead of `at` for something turned `yaw` (its length along Z).
local function placer(at: { number }, yaw: number, base: number?): (lx: number, ly: number, lz: number) -> { number }
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	local y = base or 0
	return function(lx: number, ly: number, lz: number): { number }
		return { at[1] + lx * c + lz * s, y + ly, at[2] - lx * s + lz * c }
	end
end

-- An upright cylinder (a pole, a can, a disc when short) standing on `y`.
local function upright(
	name: string,
	at: { number },
	y: number,
	height: number,
	diameter: number,
	color: string,
	material: string,
	collide: boolean?
)
	return B.part({
		Name = name,
		Size = { height, diameter, diameter },
		Position = { at[1], y + height / 2, at[2] },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = color,
		Material = material,
		CanCollide = collide ~= false,
	})
end

-- A parked car (decor, solid: you can be knocked into it or stand on it), its length along Z turned `yaw`: body,
-- glass cabin with a roof, four wheels, bumpers, headlights and tail lights.
local function car(name: string, at: { number }, yaw: number, color: string, base: number?)
	local place = placer(at, yaw, base)
	local turn = { 0, yaw, 0 }
	B.model(name, function()
		B.part({ Name = "Body", Size = { 4.6, 1.5, 9 }, Position = place(0, 1.25, 0), Rotation = turn, Color = color })
		B.part({
			Name = "Cabin",
			Size = { 4.2, 1.4, 4.6 },
			Position = place(0, 2.7, -0.4),
			Rotation = turn,
			Color = "Black",
			Material = "Glass",
			Transparency = 0.25,
		})
		B.part({
			Name = "Roof",
			Size = { 4.2, 0.2, 4 },
			Position = place(0, 3.5, -0.4),
			Rotation = turn,
			Color = color,
			CanCollide = false,
		})
		for _, lx in { -2.2, 2.2 } do
			for _, lz in { -3, 3 } do
				B.part({
					Name = "Wheel",
					Size = { 0.8, 1.6, 1.6 },
					Position = place(lx, 0.8, lz),
					Rotation = turn,
					Shape = "Cylinder",
					Color = "Black",
					CanCollide = false,
				})
			end
		end
		for _, lz in { -4.6, 4.6 } do
			B.part({
				Name = "Bumper",
				Size = { 4.7, 0.5, 0.3 },
				Position = place(0, 0.9, lz),
				Rotation = turn,
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			for _, lx in { -1.6, 1.6 } do
				B.part({
					Name = if lz > 0 then "Headlight" else "TailLight",
					Size = { 0.9, 0.4, 0.1 },
					Position = place(lx, 1.6, lz + (if lz > 0 then 0.06 else -0.06)),
					Rotation = turn,
					Color = if lz > 0 then "WarmLight" else "Red",
					Material = "Neon",
					CanCollide = false,
				})
			end
		end
	end)
end

-- A leafy tree on `y`: a trunk (solid) and two balls of leaves.
local function tree(name: string, at: { number }, y: number?, scale: number?)
	local base, k = y or 0, scale or 1
	B.model(name, function()
		upright("Trunk", at, base, 5 * k, 0.9 * k, "Wood", "Wood")
		B.part({
			Name = "Leaves",
			Size = { 6 * k, 6 * k, 6 * k },
			Position = { at[1], base + 6.5 * k, at[2] },
			Shape = "Ball",
			Color = "Leaf",
			Material = "LeafyGrass",
			CanCollide = false,
		})
		B.part({
			Name = "LeavesTop",
			Size = { 4 * k, 4 * k, 4 * k },
			Position = { at[1] + 0.6 * k, base + 9 * k, at[2] - 0.4 * k },
			Shape = "Ball",
			Color = "Leaf",
			Material = "LeafyGrass",
			CanCollide = false,
		})
	end)
end

-- A park bench on `y` turned `yaw` (unturned, you sit facing +Z): a wood seat and back on iron legs.
local function bench(name: string, at: { number }, yaw: number, y: number?)
	local place = placer(at, yaw, y)
	local turn = { 0, yaw, 0 }
	B.model(name, function()
		B.part({
			Name = "Seat",
			Size = { 5, 0.3, 1.4 },
			Position = place(0, 1.4, 0),
			Rotation = turn,
			Color = "Wood",
			Material = "WoodPlanks",
		})
		B.part({
			Name = "Back",
			Size = { 5, 1.2, 0.25 },
			Position = place(0, 2.3, -0.65),
			Rotation = turn,
			Color = "Wood",
			Material = "WoodPlanks",
		})
		for _, lx in { -2, 2 } do
			B.part({
				Name = "Leg",
				Size = { 0.3, 1.3, 1.2 },
				Position = place(lx, 0.65, 0),
				Rotation = turn,
				Color = "MetalDark",
				Material = "Metal",
			})
		end
	end)
end

-- A red fire hydrant on `y`.
local function hydrant(at: { number }, y: number?)
	local base = y or 0
	B.model("Hydrant", function()
		upright("Body", at, base, 1.6, 0.8, "Red", "Metal")
		B.part({
			Name = "Cap",
			Size = { 0.8, 0.8, 0.8 },
			Position = { at[1], base + 1.7, at[2] },
			Shape = "Ball",
			Color = "Red",
			Material = "Metal",
			CanCollide = false,
		})
		B.part({
			Name = "Nozzles",
			Size = { 1.3, 0.35, 0.35 },
			Position = { at[1], base + 1.1, at[2] },
			Color = "LaneYellow",
			Material = "Metal",
			CanCollide = false,
		})
	end)
end

-- A green city trash can with a lid, on `y`.
local function trashCan(at: { number }, y: number?)
	local base = y or 0
	B.model("TrashCan", function()
		upright("Can", at, base, 2.2, 1.4, "Bottle", "Metal")
		upright("Lid", at, base + 2.2, 0.2, 1.6, "MetalDark", "Metal", false)
	end)
end

-- A street lamp (not lit in the daytime): Pieces.lamp, its arm reaching toward `yaw`.
local function streetLamp(at: { number }, yaw: number, y: number?)
	Pieces.lamp("StreetLamp", at, 10, yaw, y, false)
end

--[[
	A traffic light on a street corner: a pole, an arm reaching `reach` (a unit vector on the floor: over the road it
	controls) and a signal box hanging off its end with red, amber and green lenses facing both ways along the road.
	Only the pole is solid.
]]
local function trafficLight(at: { number }, reach: { number })
	B.model("TrafficLight", function()
		upright("Pole", at, 0, 9.5, 0.5, "MetalDark", "Metal")
		local alongX = math.abs(reach[1]) > 0
		B.part({
			Name = "Arm",
			Size = if alongX then { 7, 0.3, 0.3 } else { 0.3, 0.3, 7 },
			Position = { at[1] + reach[1] * 3.5, 9.2, at[2] + reach[2] * 3.5 },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		local box = { at[1] + reach[1] * 6.5, at[2] + reach[2] * 6.5 }
		B.part({
			Name = "Signal",
			Size = { 1, 2.8, 1 },
			Position = { box[1], 7.6, box[2] },
			Color = "LaneYellow",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		-- Lenses on the two faces across the arm (traffic runs that way).
		for index, lens in { { 8.5, "Red" }, { 7.6, "Amber" }, { 6.7, "Bottle" } } do
			for _, side in { -1, 1 } do
				B.part({
					Name = `Lens{index}`,
					Size = { 0.1, 0.6, 0.6 },
					Position = {
						box[1] + (if alongX then 0 else side * 0.55),
						lens[1],
						box[2] + (if alongX then side * 0.55 else 0),
					},
					Rotation = if alongX then { 0, 90, 0 } else nil,
					Shape = "Cylinder",
					Color = lens[2],
					Material = if index == 3 then "Neon" else "SmoothPlastic",
					CanCollide = false,
				})
			end
		end
	end)
end

--[[
	A small building `size` (X, height, Z) standing on `y`: plain walls, a roof cap, rows of windows on the faces in
	`faces` ("+X" / "-X" / "+Z" / "-Z"), and a door on the first of them. Solid (the roof is walkable).
]]
local function building(name: string, at: { number }, size: { number }, color: string, faces: { string }, y: number?)
	local base = y or 0
	B.model(name, function()
		Pieces.block("Walls", at, size, color, "Concrete", base)
		Pieces.block("RoofCap", at, { size[1] + 0.6, 0.5, size[3] + 0.6 }, "ConcreteDark", "Concrete", base + size[2])
		for faceIndex, face in faces do
			local axis = if string.sub(face, 2) == "X" then 1 else 3
			local sign = if string.sub(face, 1, 1) == "+" then 1 else -1
			local width = if axis == 1 then size[3] else size[1]
			local out = sign * ((if axis == 1 then size[1] else size[3]) / 2 + 0.06)
			local function at2(along: number): { number }
				return if axis == 1 then { at[1] + out, at[2] + along } else { at[1] + along, at[2] + out }
			end
			local panel = function(partName: string, along: number, y0: number, w: number, h: number, colorName: string)
				local spot = at2(along)
				B.part({
					Name = partName,
					Size = if axis == 1 then { 0.1, h, w } else { w, h, 0.1 },
					Position = { spot[1], base + y0, spot[2] },
					Color = colorName,
					Material = if colorName == "Glass" then "Glass" else "SmoothPlastic",
					Transparency = if colorName == "Glass" then 0.2 else nil,
					CanCollide = false,
				})
			end
			local columns = math.max(1, math.floor(width / 4.5))
			local floors = math.max(1, math.floor((size[2] - 1) / 4))
			for floor = 1, floors do
				for column = 1, columns do
					local along = -width / 2 + (column - 0.5) * width / columns
					local isDoor = faceIndex == 1 and floor == 1 and column == math.ceil(columns / 2)
					if isDoor then
						panel("Door", along, 1.6, 2.4, 3.2, "MetalDark")
					else
						panel("Window", along, (floor - 1) * 4 + 2.4, 2.6, 2, "Glass")
					end
				end
			end
		end
	end)
end

-- A tower under a rooftop platform, reaching `depth` studs down into the haze (decor, walk-through): walls in
-- `color` and a band of glass every 6 studs on all four sides.
local function towerBody(plat: Platform, depth: number, color: string)
	local sx, sz = plat.Size[1] - 1, plat.Size[2] - 1
	local top = -plat.Thickness
	B.part({
		Name = "Tower",
		Size = { sx, depth, sz },
		Position = { 0, top - depth / 2, 0 },
		Color = color,
		Material = "Concrete",
		CanCollide = false,
		CastShadow = false,
	})
	for index = 1, math.floor(depth / 6) - 1 do
		B.part({
			Name = "GlassBand", -- a little wider than the tower, so it shows on all four sides
			Size = { sx + 0.2, 2.2, sz + 0.2 },
			Position = { 0, top - index * 6, 0 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.1,
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- The earth and rock a street block was torn out with, hanging under it (decor, walk-through), and broken pipes.
local function chunk(plat: Platform)
	local sx, sz = plat.Size[1], plat.Size[2]
	local top = -plat.Thickness
	B.part({
		Name = "Earth",
		Size = { sx - 4, 10, sz - 4 },
		Position = { 0, top - 5, 0 },
		Color = "Soil",
		Material = "Ground",
		CanCollide = false,
		CastShadow = false,
	})
	B.part({
		Name = "Rock",
		Size = { sx * 0.55, 14, sz * 0.55 },
		Position = { sx * 0.05, top - 17, -sz * 0.04 },
		Color = "Slate",
		Material = "Slate",
		CanCollide = false,
		CastShadow = false,
	})
	for index, pipe in { { 1, 0.3, 2.2 }, { -1, -0.2, 1.6 }, { 1, -0.35, 1.2 } } do
		local alongX = index % 2 == 1
		B.part({
			Name = "BrokenPipe",
			Size = { 8, pipe[3], pipe[3] },
			Position = {
				if alongX then pipe[1] * (sx / 2 - 1) else pipe[2] * sx,
				top - 3 - index * 2,
				if alongX then pipe[2] * sz else pipe[1] * (sz / 2 - 1),
			},
			Rotation = if alongX then nil else { 0, 90, 0 },
			Shape = "Cylinder",
			Color = if index == 1 then "MetalDark" else "TealDark",
			Material = "Metal",
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- A low roof hut (a stairwell, 6 across, roof +5.4) with its door on the side toward −`side` along Z and a crate to
-- climb it by on the `side` along X.
local function stairHut(at: { number }, side: number)
	Pieces.block("StairHut", at, { 6, 5, 6 }, "CityTan", "Concrete")
	Pieces.block("StairHutRoof", at, { 6.6, 0.4, 6.6 }, "ConcreteDark", "Concrete", 5)
	B.part({
		Name = "StairHutDoor",
		Size = { 1.8, 3.2, 0.1 },
		Position = { at[1], 1.6, at[2] - side * 3.05 },
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	Pieces.crate("StairHutStep", { at[1] + side * 4.6, at[2] }, 3)
end

-- A rooftop AC unit with a fan on top.
local function acUnit(at: { number })
	Pieces.block("ACUnit", at, { 4, 2.5, 3 }, "Metal", "DiamondPlate")
	upright("ACFan", at, 2.5, 0.2, 2.2, "MetalDark", "Metal", false)
end

---------------------------------------------------------------------------------------------------------------------
-- The platforms
---------------------------------------------------------------------------------------------------------------------

-- The centre's half size (X, Z) once grown, and its streets: two along X (z ±40) and two along Z (x ±82), each 20
-- wide.
local CENTRE_HALF = { 112, 72 }
local ROAD = 20
local STREETS_Z = { -40, 40 } -- the X streets' centre lines
local STREETS_X = { -82, 82 } -- the Z streets' centre lines

local function downtownStreets()
	local halfX, halfZ = CENTRE_HALF[1], CENTRE_HALF[2]
	for _, z in STREETS_Z do
		paint("Road", { 0, z }, { halfX * 2, ROAD }, "Asphalt", "Asphalt")
	end
	-- The Z streets in three pieces, so they don't paint over the crossings twice.
	for _, x in STREETS_X do
		for _, piece in { { -61, 22 }, { 0, 60 }, { 61, 22 } } do
			paint("Road", { x, piece[1] }, { ROAD, piece[2] }, "Asphalt", "Asphalt")
		end
	end
	-- Dashed yellow centre lines, stopping short of the crossings.
	local function nearCrossing(value: number, lines: { number }): boolean
		for _, line in lines do
			if math.abs(value - line) < ROAD / 2 + 5 then
				return true
			end
		end
		return false
	end
	for _, z in STREETS_Z do
		for x = -halfX + 4, halfX - 4, 8 do
			if not nearCrossing(x, STREETS_X) then
				paint("CentreLine", { x, z }, { 4, 0.4 }, "LaneYellow", nil, 0.12)
			end
		end
	end
	for _, x in STREETS_X do
		for z = -halfZ + 4, halfZ - 4, 8 do
			if not nearCrossing(z, STREETS_Z) then
				paint("CentreLine", { x, z }, { 0.4, 4 }, "LaneYellow", nil, 0.12)
			end
		end
	end
	-- Crosswalks on the two sides of each crossing that face the park, stop lines on the other two.
	for _, cx in STREETS_X do
		for _, cz in STREETS_Z do
			local inX, inZ = -math.sign(cx), -math.sign(cz) -- toward the park
			for stripe = 0, 5 do
				local across = -ROAD / 2 + 1.7 + stripe * 3.3
				paint("Crosswalk", { cx + inX * (ROAD / 2 + 2.5), cz + across }, { 4, 1.4 }, "LaneWhite", nil, 0.12)
				paint("Crosswalk", { cx + across, cz + inZ * (ROAD / 2 + 2.5) }, { 1.4, 4 }, "LaneWhite", nil, 0.12)
			end
			paint("StopLine", { cx - inX * (ROAD / 2 + 1), cz }, { 0.6, ROAD - 2 }, "LaneWhite", nil, 0.12)
			paint("StopLine", { cx, cz - inZ * (ROAD / 2 + 1) }, { ROAD - 2, 0.6 }, "LaneWhite", nil, 0.12)
		end
	end
	-- Kerbs along the pavements (walk-through, low), broken at the crossings.
	local function kerb(at: { number }, size: { number })
		B.part({
			Name = "Kerb",
			Size = { size[1], 0.3, size[2] },
			Position = { at[1], 0.15, at[2] },
			Color = "LaneWhite",
			Material = "Concrete",
			CanCollide = false,
			CastShadow = false,
		})
	end
	for _, z in STREETS_Z do
		for _, edge in { -1, 1 } do
			local kz = z + edge * (ROAD / 2 + 0.25)
			for _, piece in { { -102, 20 }, { 0, 144 }, { 102, 20 } } do
				kerb({ piece[1], kz }, { piece[2], 0.5 })
			end
		end
	end
	for _, x in STREETS_X do
		for _, edge in { -1, 1 } do
			local kx = x + edge * (ROAD / 2 + 0.25)
			for _, piece in { { -61, 22 }, { 0, 60 }, { 61, 22 } } do
				kerb({ kx, piece[1] }, { 0.5, piece[2] })
			end
		end
	end
	-- Traffic lights on two corners of each crossing: one over each street.
	for _, cx in STREETS_X do
		for _, cz in STREETS_Z do
			local sx, sz = math.sign(cx), math.sign(cz)
			local corner = ROAD / 2 + 1
			trafficLight({ cx - sx * corner, cz - sz * corner }, { 0, sz })
			trafficLight({ cx + sx * corner, cz + sz * corner }, { -sx, 0 })
		end
	end
end

-- The park in the middle with the fountain plaza on the raised deck (+6, 56 × 36; ramps east and west).
local function park()
	paint("Lawn", { 0, 0 }, { 136, 52 }, "Lawn", "Grass")
	for index, at in { { -62, -20 }, { -62, 20 }, { 62, -20 }, { 62, 20 }, { -36, 22 }, { 36, -22 } } do
		tree(`ParkTree{index}`, at)
	end
	bench("ParkBench", { -40, -23 }, 0)
	bench("ParkBench", { 40, 23 }, 180)
	-- The plaza: brick pavers, a fountain, trees in planters, benches and two lamps.
	local top = 6
	paint("Pavers", { 0, 0 }, { 56, 36 }, "BrickRed", "Brick", top + 0.05)
	upright("FountainBasin", { 0, 0 }, top, 1.2, 14, "Concrete", "Concrete")
	upright("FountainWater", { 0, 0 }, top + 1.05, 0.1, 12.6, "Glass", "Glass", false)
	upright("FountainColumn", { 0, 0 }, top + 1.2, 2.6, 1.6, "Concrete", "Concrete")
	upright("FountainBowl", { 0, 0 }, top + 3.8, 0.6, 5, "Concrete", "Concrete")
	B.part({
		Name = "FountainSpout",
		Size = { 1.2, 1.2, 1.2 },
		Position = { 0, top + 4.9, 0 },
		Shape = "Ball",
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.3,
		CanCollide = false,
	})
	for _, x in { -22, 22 } do
		for _, z in { -12, 12 } do
			Pieces.block("Planter", { x, z }, { 5, 1.4, 5 }, "Concrete", "Concrete", top)
			tree("PlazaTree", { x, z }, top + 1.4, 0.8)
		end
	end
	bench("PlazaBench", { 0, -14 }, 0, top)
	bench("PlazaBench", { 0, 14 }, 180, top)
	streetLamp({ -12, -16 }, 0, top)
	streetLamp({ 12, 16 }, 180, top)
end

-- The pavements' furniture: a bus stop, a vending machine spot beside it, a phone booth, a hot dog cart, street lamps,
-- hydrants, trash cans, parked cars along the kerbs.
local function downtownFurniture()
	-- The bus stop on the north pavement, facing the street.
	B.model("BusStop", function()
		Pieces.block("Back", { -20, 66.2 }, { 10, 6, 0.3 }, "Glass", "Glass")
		Pieces.block("Roof", { -20, 64.4 }, { 11, 0.4, 4.2 }, "MetalDark", "Metal", 6.6)
		for _, x in { -25, -15 } do
			Pieces.column("Post", { x, 62.6 }, 0, 6.6, 0.4, "MetalDark", "Metal")
		end
		Pieces.block("Seat", { -20, 65.4 }, { 8, 0.4, 1.2 }, "Wood", "WoodPlanks", 1.3)
		Pieces.column("SignPole", { -27, 61.5 }, 0, 8, 0.3, "MetalDark", "Metal")
		B.sign({
			Name = "BusSign",
			Size = { 3.6, 1.2, 0.2 },
			Position = { -27, 7.4, 61.3 },
			Color = "TealDark",
			Material = "SmoothPlastic",
			Key = "Map.SmallCity.Sign.Bus",
			TextColor = "OffWhite",
		})
	end)
	-- A red phone booth on the east pavement.
	B.model("PhoneBooth", function()
		Pieces.block("Booth", { 102, 12 }, { 3, 7.5, 3 }, "Red", "SmoothPlastic")
		for _, face in { -1, 1 } do
			B.part({
				Name = "Pane",
				Size = { 0.1, 4.5, 2.2 },
				Position = { 102 + face * 1.56, 4, 12 },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.3,
				CanCollide = false,
			})
		end
	end)
	-- A hot dog cart on the south pavement: the cart, two wheels and a striped umbrella.
	B.model("HotDogCart", function()
		Pieces.block("Cart", { 28, -62 }, { 5, 2.4, 3 }, "OffWhite", "Metal", 0.8)
		for _, x in { 26, 30 } do
			B.part({
				Name = "Wheel",
				Size = { 0.4, 1.6, 1.6 },
				Position = { x, 0.8, -60.4 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Color = "Black",
				CanCollide = false,
			})
		end
		upright("UmbrellaPole", { 28, -62 }, 3.2, 3.8, 0.2, "MetalDark", "Metal", false)
		upright("Umbrella", { 28, -62 }, 6.8, 0.4, 7, "Red", "Fabric", false)
		upright("UmbrellaStripe", { 28, -62 }, 7.2, 0.2, 4, "LaneYellow", "Fabric", false)
	end)
	for _, lamp in
		{ { -44, 61, 0 }, { 44, 61, 0 }, { -44, -61, 180 }, { 52, -61, 180 }, { 102, -12, 90 }, { -102, 4, -90 } }
	do
		streetLamp({ lamp[1], lamp[2] }, lamp[3])
	end
	for _, at in { { 94, 27 }, { -94, -27 }, { 70, -56 }, { -70, 56 } } do
		hydrant(at)
	end
	for _, at in { { -12, 60.5 }, { 60, -60.5 }, { -104, 22 }, { 104, -24 } } do
		trashCan(at)
	end
	car("ParkedCar", { -54, -46.5 }, 90, "Red")
	car("ParkedCar", { 54, 33.5 }, -90, "TealDark")
	car("Taxi", { -88.5, -6 }, 0, "LaneYellow")
	car("ParkedCar", { 75.5, 59 }, 180, "OffWhite")
end

-- East: the gas station — a canopy over two pump islands, the mini mart, the price sign, a service road.
local function gasStation()
	paint("ServiceRoad", { -41, 0 }, { 14, 104 }, "Asphalt", "Asphalt")
	for z = -48, 48, 8 do
		paint("CentreLine", { -41, z }, { 0.4, 4 }, "LaneYellow", nil, 0.12)
	end
	-- The canopy: four posts, a white roof with a red fascia, lights under it.
	B.model("Canopy", function()
		for _, x in { -12, 12 } do
			for _, z in { -18, -2 } do
				Pieces.column("Post", { x, z }, 0, 6.6, 1, "OffWhite", "SmoothPlastic")
			end
		end
		Pieces.block("Roof", { 0, -10 }, { 30, 0.8, 22 }, "OffWhite", "SmoothPlastic", 6.6)
		B.part({
			Name = "Fascia",
			Size = { 30.4, 1.2, 22.4 },
			Position = { 0, 7.2, -10 },
			Color = "Red",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		for _, x in { -6, 6 } do
			paint("CanopyLight", { x, -10 }, { 1.2, 16 }, "WarmLight", "Neon", 6.58)
		end
	end)
	for index, x in { -6, 6 } do
		B.model(`PumpIsland{index}`, function()
			Pieces.block("Island", { x, -10 }, { 2, 0.4, 11 }, "Concrete", "Concrete")
			for _, z in { -13, -7 } do
				Pieces.block("Pump", { x, z }, { 1.4, 3.2, 1 }, "Red", "SmoothPlastic", 0.4)
				B.part({
					Name = "PumpScreen",
					Size = { 1.46, 0.8, 0.6 },
					Position = { x, 2.9, z },
					Color = "Black",
					Material = "SmoothPlastic",
					CanCollide = false,
				})
			end
		end)
	end
	car("FuelingCar", { -9.6, -10 }, 0, "Teal")
	-- The mini mart: windows and a door facing the pumps, its sign over them.
	building("MiniMart", { 22, 35 }, { 26, 9, 16 }, "CityTan", { "-Z" })
	B.sign({
		Name = "MartSign",
		Size = { 14, 1.8, 0.3 },
		Position = { 22, 8.3, 26.75 },
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.SmallCity.Sign.Mart",
		TextColor = "OffWhite",
	})
	-- The price sign on a pole, facing the centre.
	Pieces.column("PriceSignPole", { -26, -44 }, 0, 9, 0.6, "MetalDark", "Metal")
	B.sign({
		Name = "PriceSign",
		Size = { 7, 3.4, 0.4 },
		Position = { -26.4, 10.4, -44 },
		Rotation = B.yaw("West"),
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.SmallCity.Sign.Gas",
		TextColor = "OffWhite",
	})
	trashCan({ 0, -24 })
	Pieces.block("AirPump", { 38, 20 }, { 1.4, 3, 1.2 }, "TealDark", "Metal")
end

-- West: two little houses with pitched roofs facing the street on the east side, front fences, mailboxes, a car in a
-- driveway, a doghouse and trees in the back.
local function house(name: string, at: { number }, color: string, roof: string)
	local width, depth, height, rise = 18, 14, 8, 4.5
	B.model(name, function()
		Pieces.block("Walls", at, { width, height, depth }, color, "WoodPlanks")
		-- The roof: two wedges meeting at a ridge along Z (their tall ends at the middle).
		for _, side in { -1, 1 } do
			B.part({
				Name = "Roof",
				Size = { depth + 1.2, rise, width / 2 + 0.8 },
				Position = { at[1] + side * (width / 4 + 0.4), height + rise / 2, at[2] },
				Rotation = { 0, -90 * side, 0 },
				Shape = "Wedge",
				Color = roof,
				Material = "Slate",
			})
		end
		Pieces.block("Chimney", { at[1] - 4, at[2] + 4 }, { 1.6, 5, 1.6 }, "Brick", "Brick", height)
		local front = at[1] + width / 2 + 0.06
		B.part({
			Name = "Door",
			Size = { 0.1, 3.6, 2.2 },
			Position = { front, 1.8, at[2] },
			Color = "Brick",
			Material = "Wood",
			CanCollide = false,
		})
		for _, z in { -4.5, 4.5 } do
			B.part({
				Name = "Window",
				Size = { 0.1, 2.2, 2.8 },
				Position = { front, 4.4, at[2] + z },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.2,
				CanCollide = false,
			})
		end
		paint("Driveway", { (front + 30) / 2, at[2] }, { 30 - front, 6 }, "Concrete", "Concrete")
	end)
end

-- A white picket fence along X = `x` from `z0` to `z1`: two rails (low, solid) and pickets.
local function picketFence(x: number, z0: number, z1: number)
	local length = z1 - z0
	B.model("PicketFence", function()
		for _, y in { 0.4, 1 } do
			B.part({
				Name = "Rail",
				Size = { 0.2, 0.2, length },
				Position = { x, y, (z0 + z1) / 2 },
				Color = "OffWhite",
				Material = "Wood",
			})
		end
		for z = z0 + 0.5, z1 - 0.5, 1.5 do
			B.part({
				Name = "Picket",
				Size = { 0.15, 1.5, 0.5 },
				Position = { x + 0.15, 0.75, z },
				Color = "OffWhite",
				Material = "Wood",
				CanCollide = false,
			})
		end
	end)
end

local function suburb()
	paint("Street", { 37, 0 }, { 14, 88 }, "Asphalt", "Asphalt")
	paint("Pavement", { 28, 0 }, { 4, 88 }, "Concrete", "Concrete")
	for z = -40, 40, 8 do
		paint("CentreLine", { 37, z }, { 0.4, 4 }, "LaneYellow", nil, 0.12)
	end
	house("HouseSouth", { -18, -24 }, "CityTan", "Brick")
	house("HouseNorth", { -18, 22 }, "DustyPink", "AsphaltDark")
	picketFence(22, -42, -27.5)
	picketFence(22, -20.5, 18.5)
	picketFence(22, 25.5, 42)
	for _, z in { -28.5, 26.5 } do
		Pieces.column("MailboxPost", { 24, z }, 0, 3, 0.3, "Wood", "Wood")
		Pieces.block("Mailbox", { 24, z }, { 0.9, 0.9, 1.6 }, "Teal", "Metal", 3)
	end
	car("DrivewayCar", { 4, -24 }, 90, "Red")
	-- The doghouse in the back yard.
	Pieces.block("Doghouse", { -36, -34 }, { 3.4, 2.6, 3.4 }, "Wood", "WoodPlanks")
	for _, side in { -1, 1 } do
		B.part({
			Name = "DoghouseRoof",
			Size = { 3.8, 1.4, 2 },
			Position = { -36 + side * 0.9, 3.3, -34 },
			Rotation = { 0, -90 * side, 0 },
			Shape = "Wedge",
			Color = "Red",
			Material = "SmoothPlastic",
		})
	end
	tree("YardTree", { -2, -40 })
	tree("YardTree", { -2, 40 })
	tree("YardTree", { -38, 38 })
end

-- North: the parking lot — two rows of bays off an aisle, parked cars, a ticket booth, lamps, the sign.
local function parkingLot()
	for _, row in { -22, 22 } do
		paint("BayEnd", { 0, row + math.sign(row) * 8 }, { 96, 0.3 }, "LaneWhite", nil, 0.12)
		for x = -48, 48, 6 do
			paint("BayLine", { x, row }, { 0.3, 16 }, "LaneWhite", nil, 0.12)
		end
	end
	for _, at in { { -33, -22 }, { 21, -22 }, { -27, 22 }, { 33, 22 } } do
		car("ParkedCar", at, if at[2] < 0 then 0 else 180, if at[1] < 0 then "OffWhite" else "TealDark")
	end
	B.model("TicketBooth", function()
		Pieces.block("Booth", { -47, 0 }, { 4, 6, 4 }, "CityBlue", "SmoothPlastic")
		Pieces.block("BoothRoof", { -47, 0 }, { 5, 0.4, 5 }, "OffWhite", "SmoothPlastic", 6)
		B.part({
			Name = "BoothWindow",
			Size = { 0.1, 1.8, 2.6 },
			Position = { -44.94, 3.8, 0 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.2,
			CanCollide = false,
		})
		B.part({
			Name = "BarrierArm",
			Size = { 0.25, 0.25, 9 },
			Position = { -44.2, 3, -6.5 },
			Color = "RustOrange",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end)
	streetLamp({ -50, 36 }, 180)
	streetLamp({ 50, -36 }, 0)
	B.model("ParkingSign", function()
		for _, x in { 15, 25 } do
			Pieces.column("SignPost", { x, -37 }, 0, 5, 0.4, "MetalDark", "Metal")
		end
		B.sign({
			Name = "Board",
			Size = { 12, 2.6, 0.4 },
			Position = { 20, 6.2, -37 },
			Color = "CityBlue",
			Material = "SmoothPlastic",
			Key = "Map.SmallCity.Sign.Parking",
			TextColor = "OffWhite",
		})
	end)
end

-- South: the basketball court — a green court with white lines, two hoops, benches, trees.
local function court()
	local cx, cz, length, width = -6, -6, 60, 32
	paint("Court", { cx, cz }, { length, width }, "CourtGreen", "SmoothPlastic")
	for _, edge in
		{
			{ { cx, cz - width / 2 }, { length, 0.4 } },
			{ { cx, cz + width / 2 }, { length, 0.4 } },
			{ { cx - length / 2, cz }, { 0.4, width } },
			{ { cx + length / 2, cz }, { 0.4, width } },
			{ { cx, cz }, { 0.4, width } },
			{ { cx - length / 2 + 6, cz }, { 12, 0.4 } },
			{ { cx + length / 2 - 6, cz }, { 12, 0.4 } },
		}
	do
		paint("CourtLine", edge[1], edge[2], "LaneWhite", nil, 0.12)
	end
	upright("CentreCircle", { cx, cz }, 0.1, 0.02, 8, "LaneWhite", "SmoothPlastic", false) -- under the lines
	for _, side in { -1, 1 } do
		local poleX = cx + side * (length / 2 + 1.5)
		B.model("Hoop", function()
			upright("Pole", { poleX, cz }, 0, 10, 0.6, "MetalDark", "Metal")
			B.part({
				Name = "Arm",
				Size = { 2, 0.3, 0.3 },
				Position = { poleX - side * 1, 9.6, cz },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			B.part({
				Name = "Backboard",
				Size = { 0.2, 3.6, 6 },
				Position = { poleX - side * 2, 9.6, cz },
				Color = "OffWhite",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
			upright("Rim", { poleX - side * 3, cz }, 8.4, 0.12, 1.8, "NeonOrange", "Metal", false)
			upright("Net", { poleX - side * 3, cz }, 7.2, 1.2, 1.5, "OffWhite", "Fabric", false).Transparency = 0.5
		end)
	end
	bench("CourtBench", { -20, 16 }, 180)
	bench("CourtBench", { 8, 16 }, 180)
	tree("CourtTree", { -42, 32 })
	tree("CourtTree", { 40, -34 })
	trashCan({ 20, 18 })
end

-- A rooftop's decor (the ledges): the office tower under it, and what stands on each roof.
local function rooftop(plat: Platform)
	towerBody(plat, 72, if plat.Id == "LedgeNE" or plat.Id == "LedgeSW" then "CityBlue" else "CityTan")
	if plat.Id == "LedgeNE" then
		stairHut({ 8, -8 }, -1)
		acUnit({ -10, 8 })
		-- A water tank on stilts (its deck +5, the tank's top +11).
		B.model("WaterTank", function()
			Pieces.block("Deck", { 10, 10 }, { 6, 0.4, 6 }, "MetalDark", "DiamondPlate", 4.6)
			for _, dx in { -2.6, 2.6 } do
				for _, dz in { -2.6, 2.6 } do
					Pieces.column("Leg", { 10 + dx, 10 + dz }, 0, 4.6, 0.4, "MetalDark", "Metal")
				end
			end
			upright("Tank", { 10, 10 }, 5, 5, 5, "Wood", "WoodPlanks")
			B.part({
				Name = "TankRoof",
				Size = { 5.4, 1.6, 5.4 },
				Position = { 10, 10.8, 10 },
				Shape = "Ball",
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end)
	elseif plat.Id == "LedgeSW" then
		-- The billboard on two posts, facing the centre (north).
		for _, x in { -8, 8 } do
			Pieces.column("BillboardPost", { x, -11 }, 0, 4.5, 0.6, "MetalDark", "Metal")
		end
		B.sign({
			Name = "Billboard",
			Size = { 22, 6, 0.5 },
			Position = { 0, 7.5, -11 },
			Rotation = B.yaw("North"),
			Color = "CityBlue",
			Material = "SmoothPlastic",
			Key = "Map.SmallCity.Sign.Billboard",
			TextColor = "OffWhite",
		})
		acUnit({ -14, 8 })
	elseif plat.Id == "LedgeNW" then
		stairHut({ -10, 10 }, 1)
		acUnit({ 10, 10 })
		acUnit({ 10, 0 })
	elseif plat.Id == "LedgeSE" then
		stairHut({ 10, -10 }, -1)
		acUnit({ -8, 10 })
	end
	for _, at in { { -16, -16 }, { 16, -16 }, { -16, 16 } } do
		if math.abs(at[1]) < plat.Size[1] / 2 and math.abs(at[2]) < plat.Size[2] / 2 then
			upright("RoofVent", at, 0, 1.4, 1.2, "Metal", "Metal")
		end
	end
end

-- A peak's decor: a tall tower under it; a helipad (NE) or a radio mast (SW) on top.
local function peak(plat: Platform)
	towerBody(plat, 110, if plat.Id == "PeakNE" then "CityGrey" else "CityBlue")
	if plat.Id == "PeakNE" then
		-- Stacked discs, each a little higher than the last (no two tops level): the pad, a yellow ring, an H.
		upright("Helipad", { 2, 2 }, 0, 0.1, 22, "AsphaltDark", "SmoothPlastic", false)
		upright("HelipadRing", { 2, 2 }, 0.1, 0.02, 20, "LaneYellow", "SmoothPlastic", false)
		upright("HelipadInner", { 2, 2 }, 0.12, 0.02, 18.6, "AsphaltDark", "SmoothPlastic", false)
		for _, piece in { { -2.5, 0.8, 7 }, { 6.5, 0.8, 7 }, { 2, 8, 0.8 } } do
			paint("HelipadH", { piece[1], 2 }, { piece[2], piece[3] }, "LaneWhite", nil, 0.16)
		end
	else
		Pieces.block("MastBase", { -6, -6 }, { 3, 2, 3 }, "MetalDark", "DiamondPlate")
		upright("Mast", { -6, -6 }, 2, 16, 0.5, "OffWhite", "Metal", false)
		B.part({
			Name = "MastLight",
			Size = { 0.8, 0.8, 0.8 },
			Position = { -6, 18.4, -6 },
			Shape = "Ball",
			Color = "Red",
			Material = "Neon",
			CanCollide = false,
		})
	end
	-- Red corner lights (PeakNE's south-west corner is where its gangway lands).
	for _, corner in { { -16, -16 }, { 16, 16 }, { -16, 16 }, { 16, -16 } } do
		if not (plat.Id == "PeakNE" and corner[1] < 0 and corner[2] < 0) then
			upright("CornerLight", corner, 0, 0.6, 0.6, "Red", "Neon", false)
		end
	end
end

-- LowEast: the construction site — dirt, a stack of steel beams, a portable toilet, cones and barriers.
local function constructionSite()
	paint("Dirt", { 4, -4 }, { 40, 36 }, "Soil", "Mud")
	for layer = 0, 2 do
		B.part({
			Name = "SteelBeam",
			Size = { 12, 0.6, 1 },
			Position = { 0, 0.3 + layer * 0.6, 22 + (layer % 2) * 1.2 },
			Color = "RustOrange",
			Material = "Metal",
		})
	end
	Pieces.block("PortableToilet", { 22, -4 }, { 3, 7, 3 }, "Teal", "SmoothPlastic")
	Pieces.jersey("Barrier", { 25, -20 }, 12, 90, 0, true)
	for index, at in { { -4, -24 }, { 4, -10 }, { -20, 2 }, { 8, 2 }, { 20, 12 } } do
		B.model(`Cone{index}`, function()
			B.part({
				Name = "Base",
				Size = { 1.2, 0.15, 1.2 },
				Position = { at[1], 0.08, at[2] },
				Color = "NeonOrange",
				CanCollide = false,
			})
			upright("Cone", at, 0.15, 1.4, 0.6, "NeonOrange", "SmoothPlastic", false)
		end)
	end
end

-- LowWest: the bus depot — a parked city bus you can climb onto, a stop sign, a bench.
local function busDepot()
	for x = -24, 24, 8 do
		paint("BayLine", { x, 0 }, { 0.3, 20 }, "LaneWhite", nil, 0.12)
	end
	Pieces.bus("CityBus", { -4, 23 }, 22, 0, "LaneYellow")
	bench("DepotBench", { 22, 22 }, 180)
	Pieces.column("DepotSignPole", { 24, 14 }, 0, 7, 0.3, "MetalDark", "Metal")
end

local function decorate(plat: Platform)
	if plat.Kind == "Ledge" then
		rooftop(plat)
	elseif plat.Kind == "Peak" then
		peak(plat)
	else
		chunk(plat)
	end
	if plat.Id == "Center" then
		downtownStreets()
		park()
		downtownFurniture()
	elseif plat.Id == "East" then
		gasStation()
	elseif plat.Id == "West" then
		suburb()
	elseif plat.Id == "North" then
		parkingLot()
	elseif plat.Id == "South" then
		court()
	elseif plat.Id == "LowEast" then
		constructionSite()
	elseif plat.Id == "LowWest" then
		busDepot()
	end
	-- This platform's bridge halves: road bridges to the centre (their middle is just off its edge), steel gangways for
	-- the rest.
	Arena.bridges(Layout, plat, function(name: string, from: { number }, to: { number }): any
		local road = math.abs(to[1]) < CENTRE_HALF[1] + 14 and math.abs(to[3]) < CENTRE_HALF[2] + 14
		return Pieces.span(
			name,
			from,
			to,
			Layout.BridgeWidth,
			if road then "Asphalt" else "MetalDark",
			if road then "Asphalt" else "DiamondPlate",
			if road then "Road" else "Gangway"
		)
	end)
end

--[[
	Bridges (Neon Motel's six, so every jump is the tested one): road bridges from the centre to West and South, steel
	gangways from East to its low lot, the NE rooftop to its tower, West to the NW rooftop and South to the SE rooftop.
]]
Layout.Bridges = {
	{ "Center", "West", Along = 30 },
	{ "Center", "South", Along = 20 },
	{ "East", "LowEast" },
	{ "LedgeNE", "PeakNE" },
	{ "West", "LedgeNW", Along = -141 },
	{ "South", "LedgeSE", Along = -100.5 },
}
Layout.BridgeWidth = 8

-- Off the platforms: a bright sky haze below instead of an abyss, clouds drifting under the blocks, and a ring of
-- far-off office towers rising out of the haze.
local function scenery(killY: number)
	for index, layer in
		{
			{ 12, 0.85, "#D2E0EC" },
			{ 40, 0.75, "#BDD0E2" },
			{ 80, 0.6, "#A8C0D8" },
			{ 130, 0.4, "#93AFCC" },
			{ 200, 0, "#7E9CBE" },
		}
	do
		B.part({
			Name = `SkyHaze{index}`,
			Size = { 2800, 1, 2800 },
			Position = { 0, killY - layer[1], 0 },
			Color = layer[3],
			Material = "SmoothPlastic",
			Transparency = layer[2],
			CanCollide = false,
			CastShadow = false,
		})
	end
	for index, puff in
		{
			{ 60, 180, 30 },
			{ -220, 120, 40 },
			{ 300, -150, 35 },
			{ -120, -260, 45 },
			{ 380, 120, 30 },
			{ -360, -60, 38 },
			{ 140, -300, 32 },
			{ -40, 300, 42 },
		}
	do
		for ball = 0, 2 do
			local size = puff[3] * (1 - ball * 0.25)
			B.part({
				Name = `Cloud{index}`,
				Size = { size * 1.6, size * 0.6, size },
				Position = { puff[1] + ball * size * 0.7, killY + 20 - ball * 4, puff[2] + ball * size * 0.3 },
				Shape = "Ball",
				Color = "OffWhite",
				Material = "SmoothPlastic",
				Transparency = 0.25,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	for index, block in
		{
			{ -520, 160, 50, 130, 40, "CityGrey" },
			{ 560, -120, 44, 160, 50, "CityBlue" },
			{ 120, 600, 60, 110, 44, "CityTan" },
			{ -240, -560, 52, 150, 40, "CityGrey" },
			{ 480, 480, 40, 180, 40, "CityBlue" },
			{ -560, -360, 46, 120, 46, "CityTan" },
			{ -420, 480, 50, 140, 42, "CityBlue" },
			{ 420, -460, 48, 125, 48, "CityGrey" },
		}
	do
		local x, z, height = block[1], block[2], block[4]
		local bottom = killY - 160
		local total = height - bottom
		B.part({
			Name = `Tower{index}`,
			Size = { block[3], total, block[5] },
			Position = { x, bottom + total / 2, z },
			Color = block[6],
			Material = "Concrete",
			CanCollide = false,
			CastShadow = false,
		})
		for band = 1, 6 do
			B.part({
				Name = `TowerGlass{index}`,
				Size = { block[3] + 0.4, 4, block[5] + 0.4 },
				Position = { x, height - band * 14, z },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.1,
				CanCollide = false,
				CastShadow = false,
			})
		end
		B.part({
			Name = `TowerCrown{index}`,
			Size = { block[3] * 0.6, 8, block[5] * 0.6 },
			Position = { x, height + 4, z },
			Color = "ConcreteDark",
			Material = "Concrete",
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- Builds the arena model at `origin` (world position of the centre platform's top centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery)
end

return Layout
