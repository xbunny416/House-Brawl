--!strict
--[[
	Map 3: Neon Motel — sinking motel rooftops over a dark abyss (the flooded street until 2026-10-20) on a cloudy night, flickering retro neon, a pool on one
	roof (bible §3.1–3.2; Night lighting); four times the first size with four layers (owner: 2026-10-17, every platform
	doubled again 2026-10-20).

	Platforms (studs; X/Z footprint, top height), listed below at the 2026-10-17 size and doubled by Arena.grow:
	  Center 224x144 main roof (never falls) with a raised 56x36 roof-access deck (+6, a ramp on each end) ·
	  East 96x104 pool roof (+1) · West 88x88 sign roof (−1) · North 104x80 roof (−3) · South 96x80 roof (−2) ·
	  ledges (+6): NE 40x40 water tower, SW 48x32 billboard, NW / SE 40x40 vent roofs · two 36x36 antenna roofs (+12)
	  beyond the NE / SW ledges · two 56x56 low roofs beyond East (−5) and West (−7).
	  Gaps to the nearest platform: East 10, West 12, North 12, South 11, ledges 8.5 (diagonal), antenna roofs 9.9,
	  low roofs 10 — all within 8-14, crossable with jump + dash; every climb is at most 6 studs.
	Same rules as Broken Highway: 16 spawns, 24 loose prop spots, 8 breakable structures, 1 explosive barrel per side
	and low platform, KillY 60 studs below the lowest platform. Edge decor stays low so knockback carries over.
	Neon parts and signs tagged NeonFlicker flicker now and then (client: NeonFlickerController).
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")
local Pieces = require("../lib/Pieces")

type Platform = Arena.Platform
type Contents = Arena.Contents

local Layout = {}

Layout.Id = "NeonMotel"
Layout.Lighting = "Night"

local FLICKER = { "NeonFlicker" }
local POOL = { 40, 48 } -- pool water on the East roof (X, Z): 20 × 24 until the platforms doubled again (2026-10-20)

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

local center = platform("Center", "Center", { 0, 0 }, { 112, 72 }, 0, 5, "ConcreteDark", "Slate")
center.Deck = { Size = { 28, 18 }, Height = 6, Ramp = 12, RampWidth = 12 }

-- Laid out at the 2026-10-17 size; Arena.grow doubles every platform again (owner, 2026-10-20), keeping the gaps.
local GROWTH = 2

Layout.Platforms = Arena.grow({
	center,
	platform("East", "Side", { 90, -4 }, { 48, 52 }, 1, 4, "OffWhite", "Concrete"),
	platform("West", "Side", { -90, 6 }, { 44, 44 }, -1, 4, "DustyPink", "Concrete"),
	platform("North", "Side", { 8, 68 }, { 52, 40 }, -3, 4, "PinkDark", "Slate"),
	platform("South", "Side", { -8, -67 }, { 48, 40 }, -2, 4, "TealDark", "Slate"),
	platform("LedgeNE", "Ledge", { 72, 52 }, { 20, 20 }, 6, 2, "Wood", "WoodPlanks"),
	platform("LedgeSW", "Ledge", { -74, -50 }, { 24, 16 }, 6, 1.5, "MetalDark", "DiamondPlate"),
	platform("LedgeNW", "Ledge", { -72, 52 }, { 20, 20 }, 6, 2, "ConcreteDark", "Slate"),
	platform("LedgeSE", "Ledge", { 72, -52 }, { 20, 20 }, 6, 2, "ConcreteDark", "Slate"),
	platform("PeakNE", "Peak", { 98, 78 }, { 18, 18 }, 12, 3, "PinkDark", "Slate"),
	platform("PeakSW", "Peak", { -102, -74 }, { 18, 18 }, 12, 3, "TealDark", "Slate"),
	platform("LowEast", "Low", { 138, -4 }, { 28, 28 }, -5, 4, "DustyPink", "Concrete"),
	platform("LowWest", "Low", { -136, 6 }, { 28, 28 }, -7, 4, "OffWhite", "Concrete"),
}, GROWTH)

Layout.Contents = Arena.growContents(
	{
		Center = {
			Spawns = { { -44, -24 }, { 44, -24 }, { -44, 24 }, { 44, 24 }, { 0, -26 }, { 0, 26 } },
			Props = {
				{ -28, -14 },
				{ -10, -22 },
				{ 18, -14 },
				{ 32, 4 },
				{ -32, 4 },
				{ -14, 16 },
				{ 10, 24 },
				{ 34, 14 },
			},
			Structures = {
				{ Type = "VendingMachine", At = { -28, 18 }, Yaw = 180 },
				{ Type = "IceMachine", At = { 28, -24 }, Yaw = 0 },
				{ Type = "LawnChairStack", At = { -44, -12 }, Yaw = 90 },
			},
		},
		East = {
			Spawns = { { -16, -18 }, { 16, 18 } },
			Props = { { -16, 12 }, { 16, -16 }, { 18, 2 } },
			Explosive = { 0, -20 },
			Structures = { { Type = "LawnChairStack", At = { 0, 19 }, Yaw = 0 } },
		},
		West = {
			Spawns = { { -10, -14 }, { 14, 12 } },
			Props = { { 12, -12 }, { -12, 10 }, { 0, 18 } },
			Explosive = { 2, 0 },
			Structures = { { Type = "IceMachine", At = { -12, -2 }, Yaw = 90 } },
		},
		North = {
			Spawns = { { -18, -10 }, { 18, 10 } },
			Props = { { 14, -10 }, { -14, 10 } },
			Explosive = { 0, 0 },
			Structures = { { Type = "VendingMachine", At = { -20, 4 }, Yaw = 90 } },
		},
		South = {
			Spawns = { { 18, -10 }, { -18, 10 } },
			Props = { { -12, -10 }, { 12, 10 } },
			Explosive = { 0, 0 },
		},
		LedgeNE = { Props = { { -5, -5 } } },
		LedgeSW = { Props = { { 3, 3 } } },
		LedgeNW = { Props = { { -4, -5 } } },
		LedgeSE = { Props = { { 4, 5 } } },
		LowEast = {
			Spawns = { { -6, -6 } },
			Props = { { 6, 6 } },
			Explosive = { 8, -8 },
			Structures = { { Type = "IceMachine", At = { -7, 8 }, Yaw = 0 } },
		},
		LowWest = {
			Spawns = { { 6, 6 } },
			Props = { { -6, -6 } },
			Explosive = { -8, 8 },
			Structures = { { Type = "LawnChairStack", At = { 7, -8 }, Yaw = 0 } },
		},
	} :: { [string]: Contents },
	GROWTH
)

function Layout.killY(): number
	return Arena.killY(Layout.Platforms)
end

-- The motel building under a roof, sinking into the flooded street (decor only).
local function building(platform: Platform)
	local depth = 26
	B.part({
		Name = "Building",
		Size = { platform.Size[1] - 2, depth, platform.Size[2] - 2 },
		Position = { 0, -platform.Thickness - depth / 2, 0 },
		Color = if platform.Kind == "Center" then "PinkDark" else platform.Color,
		Material = "Brick",
		CanCollide = false,
		CastShadow = false,
	})
	-- Lit windows on the side facing the arena centre.
	local towardX = if platform.Center[1] > 0 then -1 elseif platform.Center[1] < 0 then 1 else 0
	local towardZ = if towardX == 0 then (if platform.Center[2] > 0 then -1 else 1) else 0
	for index = -1, 1 do
		local along = index * (if towardX ~= 0 then platform.Size[2] else platform.Size[1]) / 4
		B.part({
			Name = "Window",
			Size = if towardX ~= 0 then { 0.2, 2.4, 3 } else { 3, 2.4, 0.2 },
			Position = {
				if towardX ~= 0 then towardX * (platform.Size[1] / 2 - 0.9) else along,
				-platform.Thickness - 4,
				if towardZ ~= 0 then towardZ * (platform.Size[2] / 2 - 0.9) else along,
			},
			Color = if index == 0 then "NeonPink" else "WarmLight",
			Material = "Neon",
			CanCollide = false,
			Tags = if index == 0 then FLICKER else nil,
		})
	end
end

-- A low roof edge (knockback carries over it) with a neon tube on top. `from` / `to` were laid out for the
-- 2026-10-17 roofs, so they grow with the platforms (GROWTH).
local function parapet(laidFrom: { number }, laidTo: { number }, neon: string)
	local from = { laidFrom[1] * GROWTH, laidFrom[2] * GROWTH }
	local to = { laidTo[1] * GROWTH, laidTo[2] * GROWTH }
	local length = math.max(math.abs(to[1] - from[1]), math.abs(to[2] - from[2]))
	local alongX = math.abs(to[1] - from[1]) >= math.abs(to[2] - from[2])
	local center = { (from[1] + to[1]) / 2, (from[2] + to[2]) / 2 }
	B.part({
		Name = "Parapet",
		Size = if alongX then { length, 0.8, 0.6 } else { 0.6, 0.8, length },
		Position = { center[1], 0.4, center[2] },
		Color = "Concrete",
		Material = "Concrete",
	})
	local tube = B.part({
		Name = "NeonTube",
		Size = if alongX then { length, 0.25, 0.25 } else { 0.25, 0.25, length },
		Position = { center[1], 0.95, center[2] },
		Color = neon,
		Material = "Neon",
		CanCollide = false,
		Tags = FLICKER,
	})
	B.light(tube, neon, 18, 1.6)
end

-- A lamp post on a roof corner: thin pole, warm light over the fighters.
local function roofLamp(at: { number })
	B.part({
		Name = "LampPole",
		Size = { 0.4, 7, 0.4 },
		Position = { at[1], 3.5, at[2] },
		Color = "MetalDark",
		Material = "Metal",
	})
	local head = B.part({
		Name = "LampHead",
		Size = { 1.4, 0.5, 1.4 },
		Position = { at[1], 7.2, at[2] },
		Color = "WarmLight",
		Material = "Neon",
		CanCollide = false,
	})
	B.light(head, "WarmLight", 32, 1.8)
end

local function acUnit(at: { number })
	B.part({
		Name = "ACUnit",
		Size = { 4, 2.5, 3 },
		Position = { at[1], 1.25, at[2] },
		Color = "Metal",
		Material = "DiamondPlate",
	})
	B.part({
		Name = "ACFan",
		Size = { 0.2, 2.2, 2.2 },
		Position = { at[1], 2.6, at[2] },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
end

local function centerDecor()
	-- Laid out for the first roof, a quarter of today's: spread over the bigger one (sizes stay).
	B.spread(2 * GROWTH, function()
		acUnit({ 20, -8 })
		acUnit({ -24, 0 })
		roofLamp({ 27, 17 })
		roofLamp({ -27, -17 })
		roofLamp({ 27, -17 })
		roofLamp({ -27, 17 })
	end)
	parapet({ -20, 35.4 }, { 28, 35.4 }, "NeonPink")
	parapet({ -32, -35.4 }, { 12, -35.4 }, "NeonTeal")
end

local function poolDecor()
	local poolX, poolZ = POOL[1], POOL[2] -- water size
	B.part({
		Name = "PoolWater",
		Size = { poolX, 0.12, poolZ },
		Position = { 0, 0.06, 0 },
		Color = "NeonTeal",
		Material = "Glass",
		Transparency = 0.3,
		CanCollide = false,
		CastShadow = false,
	})
	local water = B.part({
		Name = "PoolGlow",
		Size = { poolX - 1, 0.05, poolZ - 1 },
		Position = { 0, 0.02, 0 },
		Color = "Teal",
		Material = "Neon",
		CanCollide = false,
		CastShadow = false,
	})
	B.light(water, "NeonTeal", 16, 1.4)
	-- Tile rim (walk-through) and a diving board on the west side.
	for _, rim in
		{
			{ size = { poolX + 1.2, 0.3, 0.6 }, pos = { 0, poolZ / 2 + 0.3 } },
			{ size = { poolX + 1.2, 0.3, 0.6 }, pos = { 0, -poolZ / 2 - 0.3 } },
			{ size = { 0.6, 0.3, poolZ }, pos = { poolX / 2 + 0.3, 0 } },
			{ size = { 0.6, 0.3, poolZ }, pos = { -poolX / 2 - 0.3, 0 } },
		}
	do
		B.part({
			Name = "PoolRim",
			Size = rim.size,
			Position = { rim.pos[1], 0.15, rim.pos[2] },
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
	B.part({
		Name = "DivingBoard",
		Size = { 4, 0.3, 1.4 },
		Position = { -poolX / 2 - 0.5, 0.7, 0 },
		Color = "NeonTeal",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
end

local function signDecor(platform: Platform)
	local edgeX = -platform.Size[1] / 2 + 0.6
	for _, z in { -6.5, 6.5 } do
		B.part({
			Name = "SignPost",
			Size = { 0.8, 7, 0.8 },
			Position = { edgeX, 3.5, z },
			Color = "MetalDark",
			Material = "Metal",
		})
	end
	local motel = B.sign({
		Name = "MotelSign",
		Size = { 16, 5, 0.6 },
		Position = { edgeX, 9.5, 0 },
		Rotation = B.yaw("East"),
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Map.NeonMotel.Sign.Motel",
		TextColor = "NeonPink",
		Glow = true,
		Tags = FLICKER,
	})
	B.light(motel, "NeonPink", 32, 2)
	for _, tube in
		{
			{ size = { 0.25, 0.25, 16.4 }, pos = { 12.2, 0 } },
			{ size = { 0.25, 0.25, 16.4 }, pos = { 6.8, 0 } },
			{ size = { 0.25, 5.4, 0.25 }, pos = { 9.5, -8.2 } },
			{ size = { 0.25, 5.4, 0.25 }, pos = { 9.5, 8.2 } },
		}
	do
		B.part({
			Name = "SignTube",
			Size = tube.size,
			Position = { edgeX + 0.45, tube.pos[1], tube.pos[2] },
			Color = "NeonTeal",
			Material = "Neon",
			CanCollide = false,
		})
	end
	B.sign({
		Name = "VacancySign",
		Size = { 7, 1.6, 0.3 },
		Position = { edgeX, 5.2, 0 },
		Rotation = B.yaw("East"),
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Map.NeonMotel.Sign.Vacancy",
		TextColor = "NeonOrange",
		Glow = true,
		Tags = FLICKER,
	})
end

local function northDecor()
	roofLamp({ 12, 9 })
	B.part({
		Name = "Chimney",
		Size = { 2, 4, 2 },
		Position = { -11.5, 2, 8 },
		Rotation = { 0, 0, 6 },
		Color = "Brick",
		Material = "Brick",
	})
	B.part({
		Name = "Dish",
		Size = { 0.3, 2.4, 2.4 },
		Position = { 11.5, 1.5, -8 },
		Rotation = { 0, 30, 60 },
		Shape = "Cylinder",
		Color = "OffWhite",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
end

local function southDecor()
	B.spread(2 * GROWTH, function()
		roofLamp({ -11, -9 })
		B.part({
			Name = "Skylight",
			Size = { 4, 0.2, 3 },
			Position = { -1, 0.1, -6 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.3,
			CanCollide = false,
		})
	end)
	parapet({ -8, -19.4 }, { 20, -19.4 }, "NeonOrange")
end

local function waterTower(platform: Platform)
	local diameter = platform.Size[1] * 0.9
	B.part({
		Name = "Tank",
		Size = { 8, diameter, diameter },
		Position = { 0, -platform.Thickness - 4, 0 },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "Wood",
		Material = "WoodPlanks",
		CanCollide = false,
	})
	local leg = platform.Size[1] * 0.35
	for _, corner in { { -leg, -leg }, { -leg, leg }, { leg, -leg }, { leg, leg } } do
		B.part({
			Name = "TowerLeg",
			Size = { 0.6, 22, 0.6 },
			Position = { corner[1], -platform.Thickness - 19, corner[2] },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
	end
end

local function billboard(platform: Platform)
	local backZ = -platform.Size[2] / 2 + 0.3
	local width = platform.Size[1] - 1
	B.sign({
		Name = "Billboard",
		Size = { width, 5, 0.4 },
		Position = { 0, 2.5, backZ },
		Rotation = B.yaw("North"),
		Color = "DustyPink",
		Material = "SmoothPlastic",
		Key = "Map.NeonMotel.Sign.Billboard",
		TextColor = "Black",
	})
	local strip = B.part({
		Name = "BillboardLight",
		Size = { width, 0.3, 0.3 },
		Position = { 0, 5.3, backZ + 0.6 },
		Color = "WarmLight",
		Material = "Neon",
		CanCollide = false,
		Tags = FLICKER,
	})
	B.light(strip, "WarmLight", 16, 1.5)
	for _, x in { -width / 3, width / 3 } do
		B.part({
			Name = "BillboardLeg",
			Size = { 0.6, 20, 0.6 },
			Position = { x, -platform.Thickness - 10, backZ },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
	end
end

-- A small roof with an AC unit and a lamp (the NW / SE ledges). `side` mirrors it.
local function ventRoof(side: number)
	B.spread(GROWTH, function() -- laid out for the 2026-10-17 ledges
		acUnit({ 4 * side, -4 * side })
		roofLamp({ -7 * side, 7 * side })
	end)
end

-- A radio antenna on a high roof corner, its red light blinking (the antenna roofs).
local function antenna(platform: Platform)
	local corner = { platform.Size[1] / 2 - 2, platform.Size[2] / 2 - 2 }
	B.part({
		Name = "AntennaMast",
		Size = { 0.6, 16, 0.6 },
		Position = { corner[1], 8, corner[2] },
		Color = "MetalDark",
		Material = "Metal",
	})
	local beacon = B.part({
		Name = "AntennaBeacon",
		Size = { 1, 1, 1 },
		Position = { corner[1], 16.4, corner[2] },
		Shape = "Ball",
		Color = "NeonPink",
		Material = "Neon",
		CanCollide = false,
		Tags = FLICKER,
	})
	B.light(beacon, "NeonPink", 24, 1.6)
end

--[[
	Bridges (owner, 2026-10-20: "some short, some long, some gaps, not too boring"): steel gangways — short from the
	centre to West and South, East to its low roof and the NE water-tower roof to its antenna roof; longer from West to
	the NW vent roof and a long one from South to the SE vent roof. Every other neighbour is a jump (the centre–East gap
	has the window cleaner's platform). Each is two halves, one on each roof, so a crumbling roof takes its half.
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

-- A small rooftop hut (stairwell / pump house) `size` across, standing on `floor` (default the roof), with a roof slab,
-- a door and a lamp over it; its roof's top is `floor` + height + 0.4.
local function hut(name: string, at: { number }, size: { number }, color: string, floor: number?)
	local base = floor or 0
	Pieces.block(name, at, size, color, "Brick", base)
	Pieces.block(`{name}Roof`, at, { size[1] + 0.6, 0.4, size[3] + 0.6 }, "ConcreteDark", "Concrete", base + size[2])
	B.part({
		Name = `{name}Door`,
		Size = { 1.8, 3.2, 0.1 },
		Position = { at[1], base + 1.6, at[2] - size[3] / 2 - 0.05 },
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	local lamp = B.part({
		Name = `{name}Lamp`,
		Size = { 0.8, 0.3, 0.5 },
		Position = { at[1], base + 3.8, at[2] - size[3] / 2 - 0.3 },
		Color = "WarmLight",
		Material = "Neon",
		CanCollide = false,
	})
	B.light(lamp, "WarmLight", 14, 1.2)
end

-- A square steel deck on four posts with its top at `top` (from `floor`).
local function stiltDeck(name: string, at: { number }, size: number, top: number, floor: number?)
	B.part({
		Name = name,
		Size = { size, 0.5, size },
		Position = { at[1], top - 0.25, at[2] },
		Color = "MetalDark",
		Material = "DiamondPlate",
		CastShadow = true,
	})
	for _, dx in { -1, 1 } do
		for _, dz in { -1, 1 } do
			Pieces.column(
				`{name}Leg`,
				{ at[1] + dx * (size / 2 - 0.3), at[2] + dz * (size / 2 - 0.3) },
				floor or 0,
				top - 0.5,
				0.5,
				"MetalDark",
				"Metal"
			)
		end
	end
end

-- A wooden water tank you can stand on: staves, iron hoops and a cone roof.
local function waterTank(at: { number }, base: number, diameter: number, height: number)
	B.part({
		Name = "WaterTank",
		Size = { height, diameter, diameter },
		Position = { at[1], base + height / 2, at[2] },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "Wood",
		Material = "WoodPlanks",
		CastShadow = true,
	})
	for _, y in { 1, height - 1 } do
		B.part({
			Name = "WaterTankHoop",
			Size = { 0.3, diameter + 0.2, diameter + 0.2 },
			Position = { at[1], base + y, at[2] },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
	end
end

-- A raised section of roof (+3, walkable) with two skylights and an AC unit on it.
local function raisedRoof(at: { number })
	Pieces.block("RaisedRoof", at, { 20, 3, 14 }, "ConcreteDark", "Slate")
	for _, dx in { -5, 5 } do
		B.part({
			Name = "RaisedSkylight",
			Size = { 6, 0.3, 5 },
			Position = { at[1] + dx, 3.15, at[2] - 2 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.3,
			CanCollide = false,
		})
	end
	B.within({ at[1] + 5, 3, at[2] + 4 }, function()
		acUnit({ 0, 0 })
	end)
end

--[[
	The centre (the main roof): two raised roof sections (+3), a machine room (+7) with a water-tank deck beside its roof (+13; the tank's top +18) and
	the service lift up to it; a neon sign tower with a catwalk (+10) under a big MOTEL sign; the frame the swinging OPEN
	sign hangs from (the sign is a mover).
]]
local function centerFeatures()
	raisedRoof({ 95, -15 })
	raisedRoof({ -90, 20 })
	hut("MachineRoom", { 24, 28 }, { 14, 7, 10 }, "PinkDark")
	stiltDeck("TankDeck", { 27, 28 }, 8, 13, 7.4)
	waterTank({ 27, 28 }, 13, 4, 5)
	Pieces.crate("MachineStep", { 13.5, 28 }, 3)
	Pieces.crate("MachineStep", { 13.5, 28 }, 2.6, 3, 15)
	for _, x in { 31.6, 38.4 } do
		for _, z in { 24.4, 31.6 } do
			Pieces.column("LiftPost", { x, z }, 0, 16, 0.5, "NeonTeal", "Metal")
		end
	end

	-- The neon sign tower.
	for _, x in { -44.5, -35.5 } do
		Pieces.column("SignTowerLeg", { x, -30 }, 0, 23, 0.8, "MetalDark", "Metal")
	end
	B.part({
		Name = "SignCatwalk",
		Size = { 10, 0.5, 3 },
		Position = { -40, 9.75, -30 },
		Color = "MetalDark",
		Material = "DiamondPlate",
	})
	Pieces.railing("SignCatwalkRail", { -45, -31.3 }, { -35, -31.3 }, 10)
	local sign = B.sign({
		Name = "TowerSign",
		Size = { 12, 5, 0.4 },
		Position = { -40, 19.5, -30 },
		Rotation = B.yaw("North"),
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Map.NeonMotel.Sign.Motel",
		TextColor = "NeonPink",
		Glow = true,
		Tags = FLICKER,
	})
	B.light(sign, "NeonPink", 34, 2)
	for _, tube in { { 12.6, 0.25, 22.2 }, { 12.6, 0.25, 16.8 } } do
		B.part({
			Name = "TowerSignTube",
			Size = { tube[1], tube[2], 0.25 },
			Position = { -40, tube[3], -29.7 },
			Color = "NeonTeal",
			Material = "Neon",
			CanCollide = false,
		})
	end
	Pieces.crate("SignStep", { -40, -24.5 }, 3)
	Pieces.crate("SignStep", { -40, -24.5 }, 2.6, 3, -10)

	-- The OPEN sign's frame.
	for _, z in { -22, 22 } do
		Pieces.column("OpenSignPost", { 60, z }, 0, 21.5, 0.8, "MetalDark", "Metal")
	end
	B.part({
		Name = "OpenSignBeam",
		Size = { 1, 1, 45 },
		Position = { 60, 21, 0 },
		Color = "MetalDark",
		Material = "Metal",
	})
end

-- East (the pool roof): a high-dive tower at the pool's south end (+5, then +10 with the board out over the water)
-- and a cabana you can climb onto (+5).
local function eastFeatures()
	stiltDeck("DiveDeck", { -12, -30 }, 6, 5)
	stiltDeck("DiveDeck", { -6, -30 }, 6, 10)
	B.part({
		Name = "HighBoard",
		Size = { 1.4, 0.3, 8 },
		Position = { -6, 9.85, -23 },
		Color = "NeonTeal",
		Material = "SmoothPlastic",
	})
	for _, x in { 26.4, 33.6 } do
		for _, z in { 17.4, 22.6 } do
			Pieces.column("CabanaPost", { x, z }, 0, 5, 0.4, "Wood", "Wood")
		end
	end
	Pieces.block("CabanaRoof", { 30, 20 }, { 8, 0.4, 6 }, "NeonPink", "Fabric", 4.8)
	for _, x in { 28, 32 } do
		B.part({
			Name = "Lounger",
			Size = { 1.6, 0.4, 4 },
			Position = { x, 0.6, 20 },
			Rotation = { -8, 0, 0 },
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
end

-- West (the sign roof): a maintenance catwalk along the MOTEL sign (+7) and a stairwell hut (+6).
local function westFeatures()
	B.part({
		Name = "SignWalk",
		Size = { 3, 0.4, 18 },
		Position = { -41, 7, 0 },
		Color = "MetalDark",
		Material = "DiamondPlate",
	})
	Pieces.railing("SignWalkRail", { -39.6, -9 }, { -39.6, 3 }, 7.2)
	Pieces.crate("SignWalkStep", { -37, 6 }, 3)
	Pieces.crate("SignWalkStep", { -37, 6 }, 2.6, 3, 20)
	hut("Stairwell", { 20, -10 }, { 10, 6, 8 }, "DustyPink")
	Pieces.crate("StairwellStep", { 20, -3 }, 3)
end

-- North: a two-storey penthouse (roofs +6.4, then +11.8).
local function northFeatures()
	hut("Penthouse", { 10, 24 }, { 16, 6, 12 }, "PinkDark")
	hut("PenthouseTop", { 14, 26 }, { 8, 5, 6 }, "DustyPink", 6.4)
	Pieces.crate("PenthouseStep", { -1.5, 24 }, 3)
end

-- South: a water tank on stilts (+8, the tank's top +13).
local function southFeatures()
	stiltDeck("TankStilts", { 20, -10 }, 10, 8)
	waterTank({ 20, -10 }, 8, 5, 5)
	Pieces.crate("TankStep", { 20, -1.5 }, 3)
	Pieces.crate("TankStep", { 20, -1.5 }, 2.6, 3, 15)
end

local function decorate(platform: Platform)
	if platform.Kind ~= "Ledge" then
		building(platform)
	end
	if platform.Id == "Center" then
		centerDecor()
	elseif platform.Id == "East" then
		poolDecor()
	elseif platform.Id == "West" then
		signDecor(platform)
	elseif platform.Id == "North" then
		B.spread(2 * GROWTH, northDecor) -- laid out for the first roof, a quarter of today's
	elseif platform.Id == "South" then
		southDecor()
	elseif platform.Id == "LedgeNE" then
		waterTower(platform)
	elseif platform.Id == "LedgeSW" then
		billboard(platform)
	elseif platform.Id == "LedgeNW" then
		ventRoof(1)
	elseif platform.Id == "LedgeSE" then
		ventRoof(-1)
	elseif platform.Kind == "Peak" then
		antenna(platform)
	elseif platform.Kind == "Low" then
		B.spread(GROWTH, function()
			roofLamp({ 11 * math.sign(platform.Center[1]), 11 })
		end)
	end
	-- Shapes and higher places on top, and this roof's bridge halves (gangways).
	if platform.Id == "Center" then
		centerFeatures()
	elseif platform.Id == "East" then
		eastFeatures()
	elseif platform.Id == "West" then
		westFeatures()
	elseif platform.Id == "North" then
		northFeatures()
	elseif platform.Id == "South" then
		southFeatures()
	elseif platform.Id == "LedgeNE" or platform.Id == "LedgeNW" then
		hut("RoofHut", { 10, 10 }, { 6, 5, 6 }, "DustyPink")
		Pieces.crate("RoofHutStep", { 10, 3.5 }, 3)
	elseif platform.Id == "LedgeSE" then
		hut("RoofHut", { -10, -10 }, { 6, 5, 6 }, "DustyPink")
		Pieces.crate("RoofHutStep", { -10, -3.5 }, 3)
	end
	Arena.bridges(Layout, platform, function(name: string, from: { number }, to: { number }): any
		return Pieces.span(name, from, to, Layout.BridgeWidth, "MetalDark", "DiamondPlate", "Gangway")
	end)
end

local function scenery(killY: number)
	-- The abyss (owner, 2026-10-20: a dark abyss instead of the flooded street), as on the other arenas: sheets of dark
	-- mist fading to black far below; the sunken buildings reach down into it.
	for index, layer in
		{
			{ 12, 0.82, "#221F2E" },
			{ 40, 0.7, "#191624" },
			{ 80, 0.55, "#110F1A" },
			{ 130, 0.35, "#0A0910" },
			{ 200, 0, "#040407" },
		}
	do
		B.part({
			Name = `AbyssMist{index}`,
			Size = { 2800, 1, 2800 },
			Position = { 0, killY - layer[1], 0 },
			Color = layer[3],
			Material = "SmoothPlastic",
			Transparency = layer[2],
			CanCollide = false,
			CastShadow = false,
		})
	end
	-- Dark buildings around the motel, half sunk, each with a neon sign on the side facing the arena (positions laid
	-- out for the first arena, a quarter of today's, so × 2 × GROWTH).
	for index, block in
		{
			{ -130, 40, 40, 70, 30 },
			{ 140, -30, 36, 80, 40 },
			{ 30, 150, 50, 60, 34 },
			{ -60, -140, 44, 76, 30 },
			{ 120, 120, 30, 90, 30 },
			{ -140, -90, 34, 64, 28 },
		}
	do
		local x, z, height = block[1] * 2 * GROWTH, block[2] * 2 * GROWTH, block[4]
		local faceZ = if z > 0 then -block[5] / 2 - 0.3 else block[5] / 2 + 0.3
		B.part({
			Name = `Tower{index}`,
			Size = { block[3], height + 165, block[5] },
			Position = { x, killY - 25 + height / 2 - 10 - 82.5, z },
			Color = "Black",
			Material = "Concrete",
			CanCollide = false,
			CastShadow = false,
		})
		B.part({
			Name = `TowerSign{index}`,
			Size = { block[3] * 0.5, 3, 0.4 },
			Position = { x, killY - 25 + height - 18, z + faceZ },
			Color = if index % 2 == 0 then "NeonPink" else "NeonTeal",
			Material = "Neon",
			CanCollide = false,
			CastShadow = false,
			Tags = if index % 3 == 0 then FLICKER else nil,
		})
	end
end

--[[
	The moving parts (Shared/MoverRules; positions from the arena origin = the centre's top):
	  * OpenSign: a neon OPEN sign swinging on chains under its frame on the east of the main roof; it knocks you flat.
	  * ServiceLift: a service lift beside the machine room, from the roof up to the water-tank deck (+13).
	  * WindowCleaner: a window cleaner's platform sliding along the gap between the main roof and the pool roof, about
	    level with both.
]]
local function movers()
	local vector = B.roblox.Vector3.new
	Arena.mover(
		"OpenSign",
		{ 60, 20.5, 0 },
		{ Kind = "Swing", Period = 3.8, Angle = 50, Axis = "Z", Phase = 1.1 },
		function()
			for _, z in { -3, 3 } do
				B.part({
					Name = "Chain",
					Size = { 0.2, 14.5, 0.2 },
					Position = { 60, 13.25, z },
					Color = "MetalDark",
					Material = "Metal",
					CanCollide = false,
				})
			end
			for _, side in { -1, 1 } do
				local board = B.sign({
					Name = "OpenBoard",
					Size = { 8, 3.5, 0.2 },
					Position = { 60 + side * 0.15, 4.25, 0 },
					Rotation = B.yaw(if side < 0 then "West" else "East"),
					Color = "Black",
					Material = "SmoothPlastic",
					Key = "Map.NeonMotel.Sign.Open",
					TextColor = "NeonPink",
					Glow = true,
					CanCollide = false,
				})
				board:AddTag("Hazard")
			end
			local rim = B.part({
				Name = "OpenRim",
				Size = { 0.5, 3.9, 8.4 },
				Position = { 60, 4.25, 0 },
				Color = "NeonTeal",
				Material = "Neon",
				CanCollide = false,
			})
			B.light(rim, "NeonTeal", 18, 1.4)
		end
	)
	Arena.mover(
		"ServiceLift",
		{ 35, 0.5, 28 },
		{ Kind = "Lift", Period = 11, Pause = 3, Offset = vector(0, 12, 0) },
		function()
			B.part({
				Name = "LiftCage",
				Size = { 6, 1, 6 },
				Position = { 35, 0.5, 28 },
				Color = "MetalDark",
				Material = "DiamondPlate",
				CastShadow = true,
			})
			Pieces.railing("LiftCageRail", { 37.6, 25.4 }, { 37.6, 30.6 }, 1, 1.2, "NeonTeal")
		end
	)
	Arena.mover(
		"WindowCleaner",
		{ 117, 0, -50 },
		{ Kind = "Slide", Period = 15, Pause = 2.5, Offset = vector(0, 0, 84), Phase = 4 },
		function()
			B.part({
				Name = "CleanerDeck",
				Size = { 9.6, 1, 10 },
				Position = { 117, 0, -50 },
				Color = "MetalDark",
				Material = "DiamondPlate",
				CastShadow = true,
			})
			for _, z in { -54.6, -45.4 } do
				B.part({
					Name = "CleanerRail",
					Size = { 9.6, 0.2, 0.2 },
					Position = { 117, 1.7, z },
					Color = "NeonOrange",
					Material = "Metal",
					CanCollide = false,
				})
			end
			B.part({
				Name = "CleanerBucket",
				Size = { 1.2, 1.4, 1.2 },
				Position = { 120, 1.2, -52 },
				Shape = "Cylinder",
				Rotation = { 0, 0, 90 },
				Color = "NeonTeal",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
	)
end

-- Builds the arena model at `origin` (world position of the centre platform's top centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery, movers)
end

return Layout
