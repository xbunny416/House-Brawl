--!strict
--[[
	Map 2: Junkyard Isles — stacked car and container islands over a dark abyss (bible §3.1–3.2; the toxic sludge became
	the abyss, 2026-10-20), under a stormy rust sunset; four times
	the first size with four layers (owner: 2026-10-17, every platform doubled again 2026-10-20).

	Platforms (studs; X/Z footprint, top height), listed below at the 2026-10-17 size and doubled by Arena.grow:
	  Center 192x192 scrap heap (never falls) with a raised 56x40 scrap deck (+6, a ramp on each end) ·
	  East 80x112 container stack (+3) · West 88x88 car pile · North 96x80 crane barge (−2) · South 112x72 barge
	  (−1) · four 40x40 tire-stack ledges (+6) · two 36x36 tire towers (+12) beyond the NE / SW ledges · two 56x56
	  junk rafts beyond West (−6) and South (−7).
	  Gaps to the nearest platform: East 11, West 11, North 12, South 12, ledges 8.5 (diagonal), towers 9.9, rafts 10
	  — all within 8-14, crossable with jump + dash; every climb is at most 6 studs.
	Same rules as Broken Highway: 16 spawns, 24 loose prop spots, 8 breakable structures, 1 explosive barrel per side
	and low platform, KillY 60 studs below the lowest platform. Edge decor stays low (≤ 1.6 studs) so knockback carries
	over.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")
local Pieces = require("../lib/Pieces")

type Platform = Arena.Platform
type Contents = Arena.Contents

local Layout = {}

Layout.Id = "JunkyardIsles"
Layout.Lighting = "Rust"

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

local center = platform("Center", "Center", { 0, 0 }, { 96, 96 }, 0, 4, "RustDark", "CorrodedMetal")
center.Deck = { Size = { 28, 20 }, Height = 6, Ramp = 12, RampWidth = 12 }

-- Laid out at the 2026-10-17 size; Arena.grow doubles every platform again (owner, 2026-10-20), keeping the gaps.
local GROWTH = 2

Layout.Platforms = Arena.grow({
	center,
	platform("East", "Side", { 79, 0 }, { 40, 56 }, 3, 6, "Teal", "CorrodedMetal"),
	platform("West", "Side", { -81, 8 }, { 44, 44 }, 0, 4, "RustOrange", "CorrodedMetal"),
	platform("North", "Side", { -4, 80 }, { 48, 40 }, -2, 3, "MetalDark", "DiamondPlate"),
	platform("South", "Side", { 8, -78 }, { 56, 36 }, -1, 3, "TealDark", "Metal"),
	platform("LedgeNE", "Ledge", { 64, 64 }, { 20, 20 }, 6, 3, "Black", "SmoothPlastic"),
	platform("LedgeNW", "Ledge", { -64, 64 }, { 20, 20 }, 6, 3, "Black", "SmoothPlastic"),
	platform("LedgeSE", "Ledge", { 64, -64 }, { 20, 20 }, 6, 3, "Black", "SmoothPlastic"),
	platform("LedgeSW", "Ledge", { -64, -64 }, { 20, 20 }, 6, 3, "Black", "SmoothPlastic"),
	platform("PeakNE", "Peak", { 90, 90 }, { 18, 18 }, 12, 3, "Black", "SmoothPlastic"),
	platform("PeakSW", "Peak", { -90, -90 }, { 18, 18 }, 12, 3, "Black", "SmoothPlastic"),
	platform("LowWest", "Low", { -127, 8 }, { 28, 28 }, -6, 3, "TealDark", "Metal"),
	platform("LowSouth", "Low", { 8, -120 }, { 28, 28 }, -7, 3, "RustOrange", "Metal"),
}, GROWTH)

Layout.Contents = Arena.growContents(
	{
		Center = {
			Spawns = { { -36, -36 }, { 36, -36 }, { -36, 36 }, { 36, 36 }, { 0, -30 }, { 0, 30 } },
			Props = {
				{ -30, -16 },
				{ -8, -24 },
				{ 16, -16 },
				{ 34, 4 },
				{ -34, 4 },
				{ -16, 20 },
				{ 12, 28 },
				{ 28, 16 },
			},
			Structures = {
				{ Type = "CrushedCarStack", At = { -24, 30 }, Yaw = 20 },
				{ Type = "ScrapPile", At = { 20, -36 }, Yaw = 35 },
				{ Type = "WreckedCar", At = { -40, -26 }, Yaw = 75 },
			},
		},
		East = {
			Spawns = { { -8, -18 }, { 8, 18 } },
			Props = { { -10, 10 }, { 8, -8 }, { -10, -4 } },
			Explosive = { 0, 0 },
			Structures = { { Type = "WreckedCar", At = { 8, -20 }, Yaw = 90 } },
		},
		West = {
			Spawns = { { -12, -14 }, { 14, 14 } },
			Props = { { 12, -10 }, { -14, 6 }, { 0, 16 } },
			Explosive = { 2, 0 },
			Structures = { { Type = "CrushedCarStack", At = { -4, -2 }, Yaw = 90 } },
		},
		North = {
			Spawns = { { -16, -10 }, { 16, 10 } },
			Props = { { 12, -10 }, { -12, 10 } },
			Explosive = { 0, 0 },
			Structures = { { Type = "ScrapPile", At = { -18, 4 }, Yaw = 10 } },
		},
		South = {
			Spawns = { { -20, -8 }, { 20, 8 } },
			Props = { { -8, 8 }, { 10, -8 } },
			Explosive = { 0, 0 },
		},
		LedgeNE = { Props = { { -4, -4 } } },
		LedgeNW = { Props = { { 4, -4 } } },
		LedgeSE = { Props = { { -4, 4 } } },
		LedgeSW = { Props = { { 4, 4 } } },
		LowWest = {
			Spawns = { { 6, -6 } },
			Props = { { -6, 6 } },
			Explosive = { -8, -8 },
			Structures = { { Type = "ScrapPile", At = { 6, 7 }, Yaw = 0 } },
		},
		LowSouth = {
			Spawns = { { -6, 6 } },
			Props = { { 6, -6 } },
			Explosive = { 8, 8 },
			Structures = { { Type = "CrushedCarStack", At = { -6, -7 }, Yaw = 0 } },
		},
	} :: { [string]: Contents },
	GROWTH
)

function Layout.killY(): number
	return Arena.killY(Layout.Platforms)
end

-- A junk mound under an island, tapering down into the sludge (decor only).
local function underside(platform: Platform, color: string)
	B.part({
		Name = "Underside",
		Size = { platform.Size[1] * 0.75, 6, platform.Size[2] * 0.7 },
		Position = { 0, -platform.Thickness - 2.6, 0 },
		Rotation = { 3, 12, -4 },
		Color = color,
		Material = "CorrodedMetal",
		CanCollide = false,
	})
	B.part({
		Name = "Underside",
		Size = { platform.Size[1] * 0.45, 8, platform.Size[2] * 0.4 },
		Position = { 1, -platform.Thickness - 9, -1 },
		Rotation = { -5, 40, 6 },
		Color = "RustDark",
		Material = "CorrodedMetal",
		CanCollide = false,
	})
end

local function centerDecor()
	-- Rusty floor plates.
	for index, plate in { { -2, 4, 14, 10, 8 }, { 14, -10, 9, 7, -12 }, { -16, -12, 8, 9, 20 } } do
		B.part({
			Name = `FloorPlate{index}`,
			Size = { plate[3], 0.1, plate[4] },
			Position = { plate[1], 0.05, plate[2] },
			Rotation = { 0, plate[5], 0 },
			Color = if index == 2 then "TealDark" else "MetalDark",
			Material = "DiamondPlate",
			CanCollide = false,
		})
	end
	-- A flattened car along the north edge and a low tire pile on the west edge.
	B.part({
		Name = "FlatCar",
		Size = { 10, 1.4, 4 },
		Position = { 0, 0.7, 21 },
		Color = "DustyPink",
		Material = "CorrodedMetal",
	})
	for index, tire in { { -21.5, -8 }, { -21.5, -5.5 } } do
		B.part({
			Name = `Tire{index}`,
			Size = { 0.8, 2.4, 2.4 },
			Position = { tire[1], 0.4, tire[2] },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Black",
			Material = "SmoothPlastic",
		})
	end
end

local function containerDecor(platform: Platform)
	local halfX, halfZ = platform.Size[1] / 2, platform.Size[2] / 2
	-- Two containers side by side: the east one is rust, with a seam between them.
	B.part({
		Name = "SecondContainer",
		Size = { halfX, 0.1, platform.Size[2] },
		Position = { halfX / 2, 0.05, 0 },
		Color = "RustOrange",
		Material = "CorrodedMetal",
		CanCollide = false,
	})
	B.part({
		Name = "Seam",
		Size = { 0.3, 0.12, platform.Size[2] },
		Position = { 0, 0.06, 0 },
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	-- Container doors on the ends.
	for _, side in { -1, 1 } do
		B.part({
			Name = "Doors",
			Size = { platform.Size[1] - 1, platform.Thickness - 1, 0.3 },
			Position = { 0, -platform.Thickness / 2, side * (halfZ + 0.15) },
			Color = "MetalDark",
			Material = "CorrodedMetal",
			CanCollide = false,
		})
	end
	B.sign({
		Name = "YardSign",
		Size = { 16, 2.6, 0.2 },
		Position = { -halfX - 0.15, -2.4, 0 },
		Rotation = B.yaw("West"),
		Color = "OffWhite",
		Material = "SmoothPlastic",
		Key = "Map.JunkyardIsles.Sign.Yard",
		TextColor = "RustDark",
	})
end

local function carPileDecor()
	for index, cube in { { 9, -9, "Teal" }, { -9.5, 9.5, "DustyPink" }, { -9.5, -2, "RustOrange" } } do
		B.part({
			Name = `CrushedCar{index}`,
			Size = { 2.5, 1.5, 2.5 },
			Position = { cube[1], 0.75, cube[2] },
			Rotation = { 0, index * 27, 0 },
			Color = cube[3],
			Material = "CorrodedMetal",
		})
	end
end

-- Laid out for the first island; `scale` spreads it over today's (the arm grows so it still reaches from the mast
-- out over the centre island).
local function craneDecor(scale: number)
	-- Mast on the north-west corner, arm reaching out over the centre island, magnet hanging from it.
	local mastX, mastZ = -10 * scale, 8 * scale
	local armLength = 32 * scale
	local armEnd = mastZ + 1 - armLength -- the arm runs from the mast toward the centre island (south)
	B.part({
		Name = "CraneMast",
		Size = { 1.6, 24, 1.6 },
		Position = { mastX, 12, mastZ },
		Color = "LaneYellow",
		Material = "Metal",
	})
	B.part({
		Name = "CraneArm",
		Size = { 1.2, 1.2, armLength },
		Position = { mastX, 23.4, (mastZ + 1 + armEnd) / 2 },
		Color = "LaneYellow",
		Material = "Metal",
		CanCollide = false,
	})
	B.part({
		Name = "CraneCable",
		Size = { 0.2, 7, 0.2 },
		Position = { mastX, 19.3, armEnd + 2 },
		Color = "Black",
		CanCollide = false,
	})
	B.part({
		Name = "Magnet",
		Size = { 1, 5, 5 },
		Position = { mastX, 15.3, armEnd + 2 },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	-- Mooring bollards on the deck corners.
	for _, corner in { { 11, -9 }, { 11, 9 }, { -11, -9 } } do
		B.part({
			Name = "Bollard",
			Size = { 0.8, 1.2, 1.2 },
			Position = { corner[1] * scale, 0.4, corner[2] * scale },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Black",
			Material = "Metal",
		})
	end
end

local function bargeDecor(platform: Platform)
	local halfX, halfZ = platform.Size[1] / 2, platform.Size[2] / 2
	for _, corner in { { halfX - 1, halfZ - 1 }, { -halfX + 1, -halfZ + 1 }, { halfX - 1, -halfZ + 1 } } do
		B.part({
			Name = "Bollard",
			Size = { 0.8, 1.2, 1.2 },
			Position = { corner[1], 0.4, corner[2] },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Black",
			Material = "Metal",
		})
	end
	-- Hull below the deck.
	B.part({
		Name = "Hull",
		Size = { platform.Size[1] - 2, 4, platform.Size[2] - 2 },
		Position = { 0, -platform.Thickness - 2, 0 },
		Color = "RustOrange",
		Material = "CorrodedMetal",
		CanCollide = false,
	})
end

local function tireStack(platform: Platform)
	for index = 1, 5 do
		B.part({
			Name = `StackTire{index}`,
			Size = { 2.6, platform.Size[1] * 0.9, platform.Size[2] * 0.9 },
			Position = { (index % 2) * 0.6 - 0.3, -platform.Thickness - 1.3 - (index - 1) * 2.6, 0 },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Black",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
end

--[[
	Bridges (owner, 2026-10-20: "some short, some long, some gaps, not too boring"): steel gangways with yellow railings —
	short from the centre to East and West, South to its raft and the SW tyre stack to its tower; long from East to the
	NE tyre stack and North to the NW one. Every other neighbour is a jump. Each is two halves, one on each platform,
	so a crumbling island takes its half and leaves a stub.
]]
Layout.Bridges = {
	{ "Center", "East", Along = -40 },
	{ "Center", "West", Along = 40 },
	{ "South", "LowSouth", Along = 16 },
	{ "LedgeSW", "PeakSW" },
	{ "East", "LedgeNE", Along = 124.5 },
	{ "North", "LedgeNW", Along = 125 },
}
Layout.BridgeWidth = 8

-- A crushed car as a solid block: body, a dark window band, wheel discs on both sides; `y` is what it stands on.
local function carBlock(name: string, at: { number }, size: { number }, y: number, yaw: number, color: string)
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	local function place(lx: number, ly: number, lz: number): { number }
		return { at[1] + lx * c + lz * s, y + ly, at[2] - lx * s + lz * c }
	end
	B.part({
		Name = name,
		Size = size,
		Position = place(0, size[2] / 2, 0),
		Rotation = { 0, yaw, 0 },
		Color = color,
		Material = "CorrodedMetal",
		CastShadow = true,
	})
	B.part({
		Name = `{name}Windows`,
		Size = { size[1] + 0.06, 0.4, size[3] * 0.45 },
		Position = place(0, size[2] - 0.35, 0.2),
		Rotation = { 0, yaw, 0 },
		Color = "Black",
		Material = "Glass",
		CanCollide = false,
	})
	for _, wheel in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		B.part({
			Name = `{name}Wheel`,
			Size = { 0.15, 1.2, 1.2 },
			Position = place(wheel[1] * (size[1] / 2 + 0.05), 0.6, wheel[2] * (size[3] / 2 - 1.2)),
			Rotation = { 0, yaw, 0 },
			Shape = "Cylinder",
			Color = "Black",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
end

-- A square steel deck on four posts, its top at `top`.
local function scaffoldDeck(name: string, at: { number }, size: number, top: number)
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
				`{name}Post`,
				{ at[1] + dx * (size / 2 - 0.3), at[2] + dz * (size / 2 - 0.3) },
				0,
				top - 0.5,
				0.5,
				"LaneYellow",
				"Metal"
			)
		end
	end
end

-- A junk heap: a rusty mound (four ramps up to a flat top, `height` up) with a wreck and loose scrap on it.
local function junkHeap(name: string, at: { number }, size: number, height: number, yaw: number, color: string)
	local top = size * 0.4
	Pieces.block(name, at, { top, height, top }, "RustDark", "CorrodedMetal", 0, yaw)
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	for _, side in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		-- Each ramp runs from the mound's foot up to the top's edge on its side.
		local lx, lz = side[1], side[2]
		local foot = { at[1] + (lx * c + lz * s) * size / 2, at[2] + (-lx * s + lz * c) * size / 2 }
		local edge = { at[1] + (lx * c + lz * s) * top / 2, at[2] + (-lx * s + lz * c) * top / 2 }
		Pieces.ramp(`{name}Slope`, foot, edge, top, height, "RustDark", "CorrodedMetal")
	end
	carBlock(`{name}Wreck`, at, { 3.6, 2, 5.5 }, height, yaw + 25, color)
	B.part({
		Name = `{name}Sheet`,
		Size = { 4, 0.12, 3 },
		Position = { at[1] + size * 0.22, height * 0.5, at[2] - size * 0.18 },
		Rotation = { 18, yaw + 40, -12 },
		Color = "MetalDark",
		Material = "CorrodedMetal",
		CanCollide = false,
	})
end

--[[
	The centre (192 × 192 scrap heap): four junk heaps to run up, a junk tower to climb (a container +6, another +12, a crushed-car block +17; a
	crate to start, the junk elevator beside it), a car crusher (+8, a ramp up), the frame of the magnet crane (its
	magnet swings: a mover).
]]
local function centerFeatures()
	Pieces.container("TowerContainer", { -62, 30 }, { 16, 6, 8 }, 0, "TealDark")
	Pieces.container("TowerContainer", { -62, 30 }, { 10, 6, 7 }, 90, "RustOrange", 6)
	carBlock("TowerCars", { -62, 30 }, { 5, 5, 5 }, 12, 15, "DustyPink")
	Pieces.crate("TowerStep", { -73.5, 30 }, 3)
	-- Junk heaps to run up, in the open parts of the yard.
	junkHeap("JunkHeap", { 40, 40 }, 14, 4, 10, "Teal")
	junkHeap("JunkHeap", { -30, -70 }, 14, 4, -20, "DustyPink")
	junkHeap("JunkHeap", { 70, -45 }, 12, 3.5, 35, "RustOrange")
	junkHeap("JunkHeap", { -20, 70 }, 12, 3.5, 0, "OffWhite")
	-- The junk elevator's shaft (the pad is a mover): four posts and a top frame.
	for _, x in { -65.6, -58.4 } do
		for _, z in { 35.6, 42.4 } do
			Pieces.column("ElevatorPost", { x, z }, 0, 15, 0.5, "LaneYellow", "Metal")
		end
	end

	-- The car crusher: a heavy press block with a car squashed in it, pillars and the raised press plate, a ramp up.
	Pieces.block("Crusher", { 55, -20 }, { 12, 8, 10 }, "MetalDark", "DiamondPlate")
	for _, x in { 49.6, 60.4 } do
		Pieces.column("CrusherPillar", { x, -20 }, 8, 15, 1.2, "LaneYellow", "Metal")
	end
	B.part({
		Name = "CrusherPress",
		Size = { 12, 1.2, 9 },
		Position = { 55, 14.4, -20 },
		Color = "LaneYellow",
		Material = "Metal",
		CanCollide = false,
	})
	carBlock("CrushedInPress", { 55, -20 }, { 5, 1.4, 8 }, 8, 90, "Teal")
	for index = 0, 5 do
		B.part({
			Name = "CrusherStripe",
			Size = { 1.2, 0.06, 10.2 },
			Position = { 49.6 + index * 2.2, 8.03, -20 },
			Rotation = { 0, 30, 0 },
			Color = if index % 2 == 0 then "LaneYellow" else "Black",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
	Pieces.ramp("CrusherRamp", { 55, -40 }, { 55, -25 }, 8, 8, "RustDark", "CorrodedMetal")

	-- The magnet crane's frame: a mast at the north edge and its arm reaching east (the magnet is a mover).
	Pieces.column("MagnetCraneMast", { -44, 88 }, 0, 22.5, 1.6, "LaneYellow", "Metal")
	B.part({
		Name = "MagnetCraneArm",
		Size = { 26, 1.2, 1.2 },
		Position = { -32, 22, 88 },
		Color = "LaneYellow",
		Material = "Metal",
	})
	B.part({
		Name = "MagnetCraneCab",
		Size = { 4, 3, 4 },
		Position = { -44, 18, 85.5 },
		Color = "LaneYellow",
		Material = "Metal",
		CanCollide = false,
	})
end

-- East (the container stack): a two-high stack (+6, +12) under a container crane whose top walkway is +18; another
-- container to climb on the west side.
local function eastFeatures()
	Pieces.container("StackLow", { 30, -14 }, { 22, 6, 8 }, 90, "RustOrange")
	Pieces.container("StackHigh", { 30, -13 }, { 12, 6, 8 }, 90, "Teal", 6)
	Pieces.crate("StackStep", { 24, -28 }, 3)
	-- The container crane: four legs, two beams and a walkway along the top (+18).
	for _, x in { 22, 38 } do
		for _, z in { -30, 2 } do
			Pieces.column("CraneLeg", { x, z }, 0, 18, 1, "LaneYellow", "Metal")
		end
	end
	for _, z in { -30, 2 } do
		B.part({
			Name = "CraneBeam",
			Size = { 17, 1, 1 },
			Position = { 30, 18.5, z },
			Color = "LaneYellow",
			Material = "Metal",
		})
	end
	B.part({
		Name = "CraneWalk",
		Size = { 3, 0.5, 32 },
		Position = { 30, 17.75, -14 },
		Color = "MetalDark",
		Material = "DiamondPlate",
	})
	Pieces.railing("CraneWalkRail", { 31.4, -29.5 }, { 31.4, 1.5 }, 18)
	Pieces.container("SideContainer", { -30, 30 }, { 16, 6, 8 }, 90, "TealDark")
	Pieces.crate("SideStep", { -30, 18 }, 3)
end

-- West (the car pile): a stepped mountain of crushed cars (four layers, +10 at the top).
local function westFeatures()
	local layers = {
		{ y = 0, cars = { { 21, 0, 0 }, { 31, 0, 0 }, { 26, 8, 90 }, { 21, 9, 0 } } },
		{ y = 2.5, cars = { { 24, 2, 10 }, { 31, 6, 80 } } },
		{ y = 5, cars = { { 26.5, 4, -15 } } },
		{ y = 7.5, cars = { { 27, 4.5, 30 } } },
	}
	local colors = { "DustyPink", "Teal", "RustOrange", "OffWhite", "TealDark" }
	local index = 0
	for level, layer in layers do
		for _, car in layer.cars do
			index += 1
			local size = if level == 4 then { 3.6, 2.5, 5 } else { 4.4, 2.5, 7 }
			carBlock(`PileCar{index}`, { car[1], car[2] }, size, layer.y, car[3], colors[index % #colors + 1])
		end
	end
end

-- North (the crane barge): a scaffold tower beside the old crane's mast — decks at +5, +10 and +15, each next to the
-- one below, and the crane cab on the top one.
local function northFeatures()
	scaffoldDeck("ScaffoldDeck", { -32, 22 }, 8, 5)
	scaffoldDeck("ScaffoldDeck", { -32, 30 }, 8, 10)
	scaffoldDeck("ScaffoldDeck", { -24, 30 }, 8, 15)
	B.part({
		Name = "CraneCab",
		Size = { 5, 3.6, 5 },
		Position = { -23, 16.8, 31 },
		Color = "LaneYellow",
		Material = "Metal",
	})
	B.part({
		Name = "CraneCabWindow",
		Size = { 4.2, 1.6, 0.08 },
		Position = { -23, 17.4, 28.46 },
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.35,
		CanCollide = false,
	})
end

-- South (the barge): a two-storey wheelhouse (+5, then +9.4) with a smokestack, and a container on the deck.
local function southFeatures()
	Pieces.block("Wheelhouse", { -40, 20 }, { 12, 5, 10 }, "OffWhite", "SmoothPlastic")
	Pieces.block("Bridgehouse", { -41, 21 }, { 8, 4, 7 }, "OffWhite", "SmoothPlastic", 5)
	Pieces.block("BridgeRoof", { -41, 21 }, { 8.6, 0.4, 7.6 }, "RustOrange", "Metal", 9)
	for _, side in { -1, 1 } do
		B.part({
			Name = "BridgeWindows",
			Size = { 7.2, 1.4, 0.08 },
			Position = { -41, 7.3, 21 + side * 3.53 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.35,
			CanCollide = false,
		})
	end
	Pieces.railing("WheelhouseRail", { -46, 15.3 }, { -34, 15.3 }, 5)
	B.part({
		Name = "Smokestack",
		Size = { 12, 3, 3 },
		Position = { -50, 6, 28 },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "RustDark",
		Material = "CorrodedMetal",
	})
	Pieces.container("DeckContainer", { 24, -6 }, { 16, 6, 8 }, 0, "Teal")
	Pieces.crate("DeckStep", { 24, 0.5 }, 2.6)
end

-- A tyre-stack ledge: two tyre towers on its side corners (the outer corner stays open for the jump to a tower).
local function ledgeFeatures(sx: number, sz: number)
	Pieces.tires("LedgeTires", { 12 * sx, -12 * sz }, 3)
	Pieces.tires("LedgeTires", { -12 * sx, 12 * sz }, 3)
end

-- A tyre tower (peak): tyre piles on its corners as cover.
local function peakFeatures()
	for _, corner in { { 13, -13 }, { -13, 13 } } do
		Pieces.tires("PeakTires", corner, 2)
	end
end

local function decorate(platform: Platform)
	if platform.Kind ~= "Ledge" and platform.Kind ~= "Peak" then
		underside(platform, platform.Color)
	end
	-- Decor laid out for the first islands (a quarter of today's) spreads over the bigger ones (B.spread).
	if platform.Id == "Center" then
		B.spread(2 * GROWTH, centerDecor)
	elseif platform.Id == "East" then
		containerDecor(platform)
	elseif platform.Id == "West" then
		B.spread(2 * GROWTH, carPileDecor)
	elseif platform.Id == "North" then
		craneDecor(2 * GROWTH)
	elseif platform.Id == "South" or platform.Kind == "Low" then
		bargeDecor(platform)
	else
		tireStack(platform)
	end
	-- Shapes and higher places on top, and this island's bridge halves (gangways).
	local sx = if platform.Center[1] > 0 then 1 else -1
	local sz = if platform.Center[2] > 0 then 1 else -1
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
	elseif platform.Kind == "Ledge" then
		ledgeFeatures(sx, sz)
	elseif platform.Kind == "Peak" then
		peakFeatures()
	elseif platform.Kind == "Low" then
		Pieces.tires("RaftTires", { 18 * sx, 0 }, 2)
	end
	Arena.bridges(Layout, platform, function(name: string, from: { number }, to: { number }): any
		return Pieces.span(name, from, to, Layout.BridgeWidth, "MetalDark", "DiamondPlate", "Gangway")
	end)
end

local function scenery(killY: number)
	-- The abyss (owner, 2026-10-20: a dark abyss instead of the green neon), as on Broken Highway: sheets of dark mist,
	-- each more solid and darker, fading to black far below; towers of crushed cars rise out of it all round.
	for index, layer in
		{
			{ 12, 0.82, "#2A2630" },
			{ 40, 0.7, "#1E1B24" },
			{ 80, 0.55, "#141218" },
			{ 130, 0.35, "#0C0B0F" },
			{ 200, 0, "#050507" },
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
	local spireColors = { "RustDark", "TealDark", "PinkDark", "MetalDark" }
	for index, spire in
		{ { -330, 140, -20 }, { 340, -110, -26 }, { -150, 300, -16 }, { 160, -300, -22 }, { 360, 200, -30 } }
	do
		local x, z, top = spire[1], spire[2], spire[3]
		local bottom = killY - 200
		for level = 0, math.floor((top - bottom) / 9) do
			B.part({
				Name = `JunkSpire{index}`,
				Size = { 18 - (level % 3) * 2, 9, 12 + (level % 2) * 3 },
				Position = { x + (level % 2) * 1.5, bottom + level * 9 + 4.5, z - (level % 3) },
				Rotation = { 0, level * 23 + index * 11, 0 },
				Color = spireColors[(level + index) % #spireColors + 1],
				Material = "CorrodedMetal",
				CanCollide = false,
			})
		end
	end
	-- Junk mounds, drifting drums and a car floating in the haze (laid out for the first arena, a quarter of today's:
	-- B.spread).
	B.spread(2 * GROWTH, function()
		for index, mound in
			{
				{ -120, 80, 60, 40 },
				{ 130, -60, 70, 46 },
				{ 40, 140, 50, 34 },
				{ -90, -130, 64, 40 },
				{ 150, 90, 44, 30 },
			}
		do
			B.part({
				Name = `JunkMound{index}`,
				Size = { mound[3], mound[4], mound[3] * 0.8 },
				Position = { mound[1], killY - 30 + mound[4] / 2 - 6, mound[2] },
				Rotation = { 0, index * 41, 0 },
				Shape = "Wedge",
				Color = if index % 2 == 0 then "RustDark" else "MetalDark",
				Material = "CorrodedMetal",
				CanCollide = false,
			})
		end
		-- Floating barrels and a drifting car.
		for index, drum in { { -70, -20, 30 }, { 75, -28, -40 }, { 20, -24, 85 }, { -30, -32, -80 } } do
			B.part({
				Name = `FloatingBarrel{index}`,
				Size = { 3.6, 2.4, 2.4 },
				Position = { drum[1], drum[2], drum[3] },
				Rotation = { index * 20, 0, 70 },
				Shape = "Cylinder",
				Color = if index % 2 == 0 then "Teal" else "RustOrange",
				Material = "CorrodedMetal",
				CanCollide = false,
			})
		end
		B.part({
			Name = "DriftingCar",
			Size = { 5, 3.4, 9 },
			Position = { 90, -18, 55 },
			Rotation = { 12, 30, -18 },
			Color = "DustyPink",
			Material = "CorrodedMetal",
			CanCollide = false,
		})
	end)
end

--[[
	The moving parts (Shared/MoverRules; positions from the arena origin = the centre's top):
	  * Magnet: the magnet crane's magnet swinging on its cable along the centre's north side; it knocks you flying.
	  * Elevator: the junk elevator beside the junk tower, from the floor up to the tower's second container (+12).
	  * Raft: a junk raft sliding along the gap between the centre and the South barge, about level with both.
]]
local function movers()
	local vector = B.roblox.Vector3.new
	Arena.mover("Magnet", { -20, 21.3, 88 }, { Kind = "Swing", Period = 4.2, Angle = 40, Axis = "Z" }, function()
		B.part({
			Name = "MagnetCable",
			Size = { 0.25, 15.5, 0.25 },
			Position = { -20, 13.55, 88 },
			Color = "Black",
			Material = "Metal",
			CanCollide = false,
		})
		local magnet = B.part({
			Name = "MagnetDisc",
			Size = { 1.2, 5, 5 },
			Position = { -20, 3.8, 88 },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		magnet:AddTag("Hazard")
		B.part({
			Name = "MagnetRim",
			Size = { 0.4, 5.4, 5.4 },
			Position = { -20, 4.5, 88 },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "LaneYellow",
			Material = "Metal",
			CanCollide = false,
		})
	end)
	Arena.mover(
		"Elevator",
		{ -62, 0.5, 39 },
		{ Kind = "Lift", Period = 10, Pause = 2.5, Offset = vector(0, 11, 0) },
		function()
			B.part({
				Name = "ElevatorPad",
				Size = { 6, 1, 6 },
				Position = { -62, 0.5, 39 },
				Color = "MetalDark",
				Material = "DiamondPlate",
				CastShadow = true,
			})
			Pieces.railing("ElevatorRail", { -64.6, 36.4 }, { -64.6, 41.6 }, 1, 1.2, "LaneYellow")
			Pieces.railing("ElevatorRail", { -59.4, 36.4 }, { -59.4, 41.6 }, 1, 1.2, "LaneYellow")
		end
	)
	Arena.mover(
		"Raft",
		{ -30, -1, -102 },
		{ Kind = "Slide", Period = 16, Pause = 2.5, Offset = vector(90, 0, 0), Phase = 5 },
		function()
			B.part({
				Name = "RaftDeck",
				Size = { 10, 1, 11.6 },
				Position = { -30, -1, -102 },
				Color = "Wood",
				Material = "WoodPlanks",
				CastShadow = true,
			})
			for index, drum in { { -33.5, -97.5 }, { -26.5, -106.5 } } do
				B.part({
					Name = `RaftDrum{index}`,
					Size = { 2.2, 1.6, 1.6 },
					Position = { drum[1], -0.5, drum[2] },
					Rotation = { 0, 90, 90 },
					Shape = "Cylinder",
					Color = if index == 1 then "RustOrange" else "Teal",
					Material = "CorrodedMetal",
					CanCollide = false,
				})
			end
		end
	)
end

-- Builds the arena model at `origin` (world position of the centre platform's top centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery, movers)
end

return Layout
