--!strict
--[[
	Map 1: Broken Highway — shattered overpass chunks over a toxic void (bible §3.2), four times the first size with four
	layers (owner: twice the size with more layers 2026-10-17, every platform doubled again 2026-10-20).

	Platforms (studs; X/Z footprint, top height), listed below at the 2026-10-17 size and doubled by Arena.grow:
	  Center 240x160 (never falls) with a raised 72x40 overpass deck (+6, a ramp on each end) ·
	  East/West/North/South 96x96 · four 48x48 corner ledges (+6) · two 40x40 peaks (+12) beyond the NE / SW
	  ledges · two 56x56 low slabs beyond East (−4) and West (−6).
	  Gaps to the nearest platform: East 11, West 9, North 12, South 10, ledges / peaks 9.9 (diagonal), lows 10 — all
	  within 8-14, crossable with jump + dash; every climb is at most 6 studs.
	Gameplay markers ride on their platform so they fall with it: 16 spawns, 24 loose prop spots,
	8 breakable structures, 1 explosive barrel per side and low platform.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")
local Pieces = require("../lib/Pieces")

type Platform = Arena.Platform
type Contents = Arena.Contents

local Layout = {}

Layout.Id = "BrokenHighway"
Layout.Lighting = "Dusk"

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

local center = platform("Center", "Center", { 0, 0 }, { 120, 80 }, 0, 4, "Asphalt", "Asphalt")
center.Deck = { Size = { 36, 20 }, Height = 6, Ramp = 12, RampWidth = 12 }

-- Laid out at the 2026-10-17 size; Arena.grow doubles every platform again (owner, 2026-10-20), keeping the gaps.
local GROWTH = 2

Layout.Platforms = Arena.grow({
	center,
	platform("East", "Side", { 95, 0 }, { 48, 48 }, 2, 3, "Asphalt", "Asphalt"),
	platform("West", "Side", { -93, 0 }, { 48, 48 }, 0, 3, "Asphalt", "Asphalt"),
	platform("North", "Side", { 0, 76 }, { 48, 48 }, -2, 3, "Concrete", "Concrete"),
	platform("South", "Side", { 0, -74 }, { 48, 48 }, 0, 3, "Concrete", "Concrete"),
	platform("LedgeNE", "Ledge", { 79, 59 }, { 24, 24 }, 6, 2, "ConcreteDark", "Concrete"),
	platform("LedgeNW", "Ledge", { -79, 59 }, { 24, 24 }, 6, 2, "ConcreteDark", "Concrete"),
	platform("LedgeSE", "Ledge", { 79, -59 }, { 24, 24 }, 6, 2, "ConcreteDark", "Concrete"),
	platform("LedgeSW", "Ledge", { -79, -59 }, { 24, 24 }, 6, 2, "ConcreteDark", "Concrete"),
	platform("PeakNE", "Peak", { 108, 88 }, { 20, 20 }, 12, 2, "SignGreen", "Metal"),
	platform("PeakSW", "Peak", { -108, -88 }, { 20, 20 }, 12, 2, "SignGreen", "Metal"),
	platform("LowEast", "Low", { 143, 0 }, { 28, 28 }, -4, 3, "AsphaltDark", "Asphalt"),
	platform("LowWest", "Low", { -141, 0 }, { 28, 28 }, -6, 3, "AsphaltDark", "Asphalt"),
}, GROWTH)

Layout.Contents = Arena.growContents(
	{
		Center = {
			Spawns = { { -48, -28 }, { 48, -28 }, { -48, 28 }, { 48, 28 }, { 0, -30 }, { 0, 30 } },
			Props = {
				{ -32, -20 },
				{ -12, -24 },
				{ 16, -20 },
				{ 36, -8 },
				{ -36, 8 },
				{ -16, 22 },
				{ 12, 26 },
				{ 32, 18 },
			},
			Structures = {
				{ Type = "WreckedCar", At = { -30, 20 }, Yaw = 15 },
				{ Type = "VendingMachine", At = { 28, -28 }, Yaw = 180 },
				{ Type = "RoadBarrierStack", At = { -46, 0 }, Yaw = 90 },
			},
		},
		East = {
			Spawns = { { -12, -16 }, { 12, 16 } },
			Props = { { -12, 12 }, { 4, -14 }, { 16, -4 } },
			Explosive = { 0, 0 },
			Structures = { { Type = "RoadBarrierStack", At = { 14, 6 }, Yaw = 90 } },
		},
		West = {
			Spawns = { { -12, -16 }, { 16, 16 } },
			Props = { { 12, -8 }, { -18, -4 }, { 0, 14 } },
			Explosive = { 4, -16 },
			Structures = { { Type = "WreckedCar", At = { -4, 6 }, Yaw = 90 } },
		},
		North = {
			Spawns = { { -14, -12 }, { 14, 14 } },
			Props = { { 12, -10 }, { -12, 12 } },
			Explosive = { 0, 0 },
			Structures = { { Type = "VendingMachine", At = { -16, 0 }, Yaw = 90 } },
		},
		South = {
			Spawns = { { 14, 12 }, { -14, -14 } },
			Props = { { -12, 10 }, { 12, -10 } },
			Explosive = { 0, 0 },
			Structures = { { Type = "RoadBarrierStack", At = { -14, 0 }, Yaw = 0 } },
		},
		LedgeNE = { Props = { { -6, -6 } } },
		LedgeNW = { Props = { { 6, -6 } } },
		LedgeSE = { Props = { { -6, 6 } } },
		LedgeSW = { Props = { { 6, 6 } } },
		LowEast = {
			Spawns = { { -6, -6 } },
			Props = { { 6, 8 } },
			Explosive = { 8, -8 },
			Structures = { { Type = "WreckedCar", At = { -7, 7 }, Yaw = 0 } },
		},
		LowWest = {
			Spawns = { { 6, 6 } },
			Props = { { -6, -8 } },
			Explosive = { -8, 8 },
		},
	} :: { [string]: Contents },
	GROWTH
)

-- Lowest platform bottom (relative to the arena origin) minus the kill depth.
function Layout.killY(): number
	return Arena.killY(Layout.Platforms)
end

local function centerDecor(platform: Platform)
	local halfX, halfZ = platform.Size[1] / 2, platform.Size[2] / 2
	-- Dashed yellow centre line and white edge lines.
	for x = -halfX + 4, halfX - 6, 9 do
		B.part({
			Name = "LaneDash",
			Size = { 5, 0.1, 0.6 },
			Position = { x + 2.5, 0.05, 0 },
			Color = "LaneYellow",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
	for _, z in { -halfZ + 3, halfZ - 3 } do
		B.part({
			Name = "EdgeLine",
			Size = { platform.Size[1] - 4, 0.1, 0.5 },
			Position = { 0, 0.05, z },
			Color = "LaneWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
	-- Low guardrail stubs: knockback still carries players over them (laid out for the 2026-10-17 deck: × GROWTH).
	for _, rail in
		{
			{ from = 20 * GROWTH, to = 44 * GROWTH, z = halfZ - 0.6 },
			{ from = -44 * GROWTH, to = -24 * GROWTH, z = -halfZ + 0.6 },
			{ from = -16 * GROWTH, to = 0, z = halfZ - 0.6 },
		}
	do
		local length = rail.to - rail.from
		B.part({
			Name = "Guardrail",
			Size = { length, 0.6, 0.4 },
			Position = { (rail.from + rail.to) / 2, 1.3, rail.z },
			Color = "Metal",
			Material = "Metal",
		})
		for x = rail.from, rail.to, 4 do
			B.part({
				Name = "RailPost",
				Size = { 0.4, 1.6, 0.4 },
				Position = { x, 0.8, rail.z },
				Color = "MetalDark",
				Material = "Metal",
			})
		end
	end
	-- Cracks (laid out for the 2026-10-17 deck: spread).
	B.spread(GROWTH, function()
		for _, crack in
			{ { -8, 0, -18, 25 }, { 24, 0, 18, -40 }, { -40, 0, -4, 70 }, { 44, 0, -16, 10 }, { -24, 0, 30, -60 } }
		do
			B.part({
				Name = "Crack",
				Size = { 6, 0.08, 0.3 },
				Position = { crack[1], 0.04, crack[3] },
				Rotation = { 0, crack[4], 0 },
				Color = "AsphaltDark",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
	end)
end

-- A green highway sign board on a pole.
local function exitSign(at: { number }, facing: string)
	B.part({
		Name = "SignPole",
		Size = { 0.6, 9, 0.6 },
		Position = { at[1], 4.5, at[2] },
		Color = "Metal",
		Material = "Metal",
	})
	B.sign({
		Name = "ExitSign",
		Size = { 8, 3, 0.4 },
		Position = { at[1], 9.5, at[2] },
		Rotation = B.yaw(facing),
		Color = "SignGreen",
		Material = "Metal",
		Key = "Map.BrokenHighway.Sign.Exit",
		TextColor = "OffWhite",
	})
	-- A white border round the board.
	B.part({
		Name = "ExitSignFrame",
		Size = { 8.4, 3.4, 0.3 },
		Position = { at[1], 9.5, at[2] },
		Rotation = B.yaw(facing),
		Color = "OffWhite",
		Material = "Metal",
		CanCollide = false,
	})
end

-- Manhole covers and pothole patches (decor on the road).
local function roadWear(spots: { { number } })
	for index, spot in spots do
		B.part({
			Name = if index % 2 == 0 then "Manhole" else "Pothole",
			Size = { 0.08, 2.4, 2.4 },
			Position = { spot[1], 0.04, spot[2] },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = if index % 2 == 0 then "MetalDark" else "AsphaltDark",
			Material = if index % 2 == 0 then "DiamondPlate" else "Asphalt",
			CanCollide = false,
		})
	end
end

--[[
	The centre (240 × 160): the raised overpass deck (+6, Arena.Deck) with guardrails, a steel catwalk on columns
	above it (+14) reached by stairs from the deck or by the lift (a mover) at the end of a bridge north; the frame
	the swinging sign (a mover) hangs from; a broken flyover ramp on the west side that ends in mid-air (+8);
	concrete barrier lines, a fallen container (with a crate to climb it) and a two-high container tower (+12) as
	cover and high ground; a planter with a dead tree; raised sidewalks with lamp posts along the long edges; lane
	lines, cracks, potholes and manholes.
]]
local function centerFeatures()
	local deckTop = 6
	-- Guardrails along the deck's long edges, with gaps in the middle.
	for _, z in { -19.6, 19.6 } do
		Pieces.railing("DeckRail", { -34, z }, { -8, z }, deckTop, 1.3)
		Pieces.railing("DeckRail", { 8, z }, { 34, z }, deckTop, 1.3)
	end
	for x = -30, 30, 9 do
		B.part({
			Name = "DeckDash",
			Size = { 4, 0.06, 0.5 },
			Position = { x, deckTop + 0.03, 0 },
			Color = "LaneYellow",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end

	-- The catwalk (+14) on four columns over the deck, its stairs down to the deck (east) and a bridge north to the
	-- lift's top stop.
	local walk = 14
	B.part({
		Name = "Catwalk",
		Size = { 24, 1, 12 },
		Position = { 0, walk - 0.5, 0 },
		Color = "MetalDark",
		Material = "DiamondPlate",
		CastShadow = true,
	})
	for _, x in { -11, 11 } do
		for _, z in { -5, 5 } do
			Pieces.column("CatwalkColumn", { x, z }, deckTop, walk - 1, 0.9, "Metal", "Metal", true)
		end
	end
	Pieces.stairs("CatwalkStairs", { 22, 0 }, "-X", 6, 4, 2, 2.5, "MetalDark", "DiamondPlate", deckTop)
	Pieces.railing("CatwalkRail", { -12, -6 }, { 12, -6 }, walk)
	Pieces.railing("CatwalkRail", { -12, -6 }, { -12, 6 }, walk)
	Pieces.railing("CatwalkRail", { -12, 6 }, { -3, 6 }, walk)
	Pieces.railing("CatwalkRail", { 3, 6 }, { 12, 6 }, walk)
	B.part({
		Name = "LiftBridge",
		Size = { 6, 0.8, 18 },
		Position = { 0, walk - 0.4, 15 },
		Color = "MetalDark",
		Material = "DiamondPlate",
		CastShadow = true,
	})
	Pieces.railing("LiftBridgeRail", { -3, 6 }, { -3, 24 }, walk)
	Pieces.railing("LiftBridgeRail", { 3, 6 }, { 3, 24 }, walk)
	for _, face in { -1, 1 } do
		B.sign({
			Name = "CatwalkSign",
			Size = { 10, 2.4, 0.3 },
			Position = { 0, walk + 2.6, face * 6.2 },
			Rotation = B.yaw(if face > 0 then "North" else "South"),
			Color = "SignGreen",
			Material = "Metal",
			Key = "Map.BrokenHighway.Sign.Exit",
			TextColor = "OffWhite",
			CanCollide = false,
		})
	end

	-- The lift's shaft: four posts, a top frame and a pulley; striped floor round its bottom stop.
	for _, x in { -4.6, 4.6 } do
		for _, z in { 23.4, 32.6 } do
			Pieces.column("LiftPost", { x, z }, 0, 18, 0.6, "LaneYellow", "Metal")
		end
		B.part({
			Name = "LiftFrame",
			Size = { 0.5, 0.5, 9.8 },
			Position = { x, 18.25, 28 },
			Color = "LaneYellow",
			Material = "Metal",
			CanCollide = false,
		})
	end
	B.part({
		Name = "LiftPulley",
		Size = { 1.2, 2, 2 },
		Position = { 0, 18.6, 28 },
		Shape = "Cylinder",
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	for index = 0, 5 do
		B.part({
			Name = "LiftStripe",
			Size = { 1.2, 0.06, 10 },
			Position = { -5.5 + index * 2.2, 0.03, 28 },
			Rotation = { 0, 30, 0 },
			Color = if index % 2 == 0 then "LaneYellow" else "Black",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end

	-- The frame the swinging sign hangs from (the sign itself is a mover).
	for _, z in { -23, 23 } do
		Pieces.column("SwingPost", { -24, z }, 0, 21.5, 0.8, "MetalDark", "Metal")
	end
	B.part({
		Name = "SwingBeam",
		Size = { 1, 1, 47 },
		Position = { -24, 21, 0 },
		Color = "MetalDark",
		Material = "Metal",
	})
	B.sign({
		Name = "DangerSign",
		Size = { 5, 1.6, 0.2 },
		Position = { -24, 3.4, 23.5 },
		Rotation = B.yaw("North"),
		Color = "LaneYellow",
		Material = "Metal",
		Key = "Map.BrokenHighway.Sign.Danger",
		TextColor = "Black",
		CanCollide = false,
	})

	-- The broken flyover: a ramp up the west side to +8, then a slab that ends in mid-air, rebar sticking out.
	Pieces.ramp("Flyover", { -62, -28 }, { -104, -28 }, 12, 8, "Asphalt", "Asphalt")
	Pieces.block("FlyoverEnd", { -109, -28 }, { 10, 2, 12 }, "Asphalt", "Asphalt", 6)
	for _, z in { -32, -24 } do
		Pieces.column("FlyoverPillar", { -109, z }, 0, 6, 1.6, "Concrete", "Concrete", true)
	end
	Pieces.railing("FlyoverRail", { -104, -33.6 }, { -114, -33.6 }, 8)
	Pieces.rebar("FlyoverRebar", { -114.2, -33 }, { -114.2, -23 }, 7, 7, -90)
	for index = 0, 3 do
		B.part({
			Name = "FlyoverDash",
			Size = { 3.5, 0.06, 0.4 },
			Position = { -68 - index * 10, 0.75 + index * 1.9, -28 },
			Rotation = { 0, 0, -10.8 },
			Color = "LaneWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end

	-- Cover: concrete barrier lines and a fallen container with a crate to climb it.
	Pieces.jersey("Barrier", { 30, 30 }, 12, 0)
	Pieces.jersey("Barrier", { 80, -36 }, 12, 90, nil, true)
	Pieces.jersey("Barrier", { -40, 22 }, 12, 0, nil, true)
	Pieces.jersey("Barrier", { 40, -66 }, 12, 0)
	Pieces.jersey("Barrier", { -80, 50 }, 12, 90)
	Pieces.container("FallenContainer", { 95, 8 }, { 22, 6, 8 }, 90, "RustOrange")
	Pieces.crate("ContainerStep", { 86.5, 14 }, 3)
	-- A container tower (+6, then +12): a crate, the lower container, the upper one turned across it.
	Pieces.container("TowerContainer", { 48, 64 }, { 16, 6, 8 }, 0, "TealDark")
	Pieces.container("TowerContainer", { 50, 64.5 }, { 12, 6, 7 }, 8, "RustOrange", 6)
	Pieces.crate("TowerStep", { 37.5, 62 }, 3)
	Pieces.planter("Planter", { -100, 28 }, 10)

	-- Raised sidewalks along both long edges (half a stud up), with a kerb line.
	for _, z in { 76, -76 } do
		B.part({
			Name = "Sidewalk",
			Size = { 240, 0.5, 8 },
			Position = { 0, 0.25, z },
			Color = "Concrete",
			Material = "Concrete",
		})
		B.part({
			Name = "SidewalkKerb",
			Size = { 240, 0.55, 0.4 },
			Position = { 0, 0.275, z - 4 * math.sign(z) },
			Color = "ConcreteDark",
			Material = "Concrete",
			CanCollide = false,
		})
	end

	-- Lamp posts along the long edges, arms over the road; every other one lit.
	for index, x in { -100, -40, 40, 100 } do
		Pieces.lamp("Lamp", { x, 76 }, 16, 0, 0.5, index % 2 == 1)
		Pieces.lamp("Lamp", { x, -76 }, 16, 180, 0.5, index % 2 == 0)
	end
	roadWear({ { -12, 14 }, { 50, 6 }, { -50, -10 }, { 14, -30 }, { 100, -30 }, { -86, 30 } })
end

-- East (96 × 96): a toll plaza — two booths on kerb islands (a crate up to each roof) under a canopy you can climb
-- onto by the crate stacks at its edge (+11), barrier arms, a lit sign.
local function eastFeatures()
	B.part({
		Name = "Canopy",
		Size = { 80, 1, 24 },
		Position = { 0, 10.5, 0 },
		Color = "OffWhite",
		Material = "Metal",
		CastShadow = true,
	})
	for _, edge in { { 0, 12.25, 81, 0.5 }, { 0, -12.25, 81, 0.5 }, { 40.25, 0, 0.5, 25 }, { -40.25, 0, 0.5, 25 } } do
		B.part({
			Name = "CanopyFascia",
			Size = { edge[3], 1.4, edge[4] },
			Position = { edge[1], 10.3, edge[2] },
			Color = "RustOrange",
			Material = "Metal",
			CanCollide = false,
		})
	end
	B.sign({
		Name = "TollSign",
		Size = { 16, 1.3, 0.2 },
		Position = { 0, 10.3, -12.65 },
		Rotation = B.yaw("South"),
		Color = "RustOrange",
		Material = "Metal",
		Key = "Map.BrokenHighway.Sign.Toll",
		TextColor = "OffWhite",
		CanCollide = false,
	})
	for _, x in { -36, -12, 12, 36 } do
		for _, z in { -11, 11 } do
			Pieces.column("CanopyColumn", { x, z }, 0, 10, 1.2, "Concrete", "Concrete")
		end
		B.part({
			Name = "CanopyLight",
			Size = { 1, 0.15, 18 },
			Position = { x / 1.5, 9.92, 0 },
			Color = "WarmLight",
			Material = "Neon",
			CanCollide = false,
			CastShadow = false,
		})
	end
	for _, x in { -14, 14 } do
		Pieces.block("TollIsland", { x, 0 }, { 4, 0.4, 14 }, "Concrete", "Concrete")
		Pieces.block("TollBooth", { x, 0 }, { 3, 6, 4 }, "OffWhite", "SmoothPlastic", 0.4)
		Pieces.block("TollBoothRoof", { x, 0 }, { 3.8, 0.4, 4.8 }, "RustOrange", "Metal", 6.4)
		for _, side in { -1, 1 } do
			B.part({
				Name = "TollWindow",
				Size = { 0.08, 2.4, 3 },
				Position = { x + side * 1.53, 3.6, 0 },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.4,
				CanCollide = false,
			})
		end
		-- The barrier arm across the lane, striped red and white.
		for index = 0, 3 do
			B.part({
				Name = "TollArm",
				Size = { 0.25, 0.25, 2.5 },
				Position = { x + (if x < 0 then 1 else -1) * 0.3, 3, (if x < 0 then -1 else 1) * (3.2 + index * 2.5) },
				Color = if index % 2 == 0 then "Red" else "OffWhite",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
	end
	Pieces.crate("TollStep", { -17.6, -3.5 }, 2.6)
	Pieces.crate("TollStep", { 17.6, 3.5 }, 2.6)
	-- Up to the canopy (+11): a crate, a smaller crate on it, then a jump onto the canopy's edge.
	for _, side in { -1, 1 } do
		Pieces.crate("CanopyStep", { 36 * side, 16 * side }, 3)
		Pieces.crate("CanopyStep", { 36 * side, 16 * side }, 2.6, 3, 12)
	end
	roadWear({ { -30, -20 }, { 30, 26 } })
end

-- West (96 × 96): a collapsed road section tilted up to +6 with rebar at its broken top, a crashed bus you can stand
-- on (+5.5) and a barrier line.
local function westFeatures()
	Pieces.ramp("CollapsedSlab", { -10, -17 }, { -40, -17 }, 10, 6, "Asphalt", "Asphalt")
	Pieces.rebar("CollapsedRebar", { -40.3, -21.5 }, { -40.3, -12.5 }, 5.2, 6, -90)
	for index = 0, 2 do
		B.part({
			Name = "CollapsedCrack",
			Size = { 0.3, 0.08, 9 },
			Position = { -16 - index * 9, 1.3 + index * 1.8, -17 },
			Rotation = { 0, index * 14 - 10, -11.3 },
			Color = "AsphaltDark",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
	Pieces.jersey("Barrier", { 16, 0 }, 12, 90)
	Pieces.bus("CrashedBus", { 32, 14 }, 26, 0, "LaneYellow")
	Pieces.lamp("Lamp", { -44, 40 }, 14, -90)
	Pieces.lamp("Lamp", { 44, -44 }, 14, 90)
	roadWear({ { 20, 20 }, { -20, 36 } })
end

-- North (96 × 96): a two-level parking deck chunk — a slab at +7 on columns (walk under it) with a ramp up,
-- railings, parking lines and crates and tyres on top for cover.
local function northFeatures()
	B.part({
		Name = "ParkingDeck",
		Size = { 28, 1, 22 },
		Position = { 22, 6.5, 11 },
		Color = "Concrete",
		Material = "Concrete",
		CastShadow = true,
	})
	for _, x in { 9, 22, 35 } do
		for _, z in { 1, 21 } do
			Pieces.column("ParkingColumn", { x, z }, 0, 6, 1.2, "ConcreteDark", "Concrete")
		end
	end
	Pieces.ramp("ParkingRamp", { -8, 10 }, { 8, 10 }, 8, 7, "Concrete", "Concrete")
	Pieces.railing("ParkingRail", { 8.4, 21.6 }, { 35.6, 21.6 }, 7)
	Pieces.railing("ParkingRail", { 35.6, 0.4 }, { 35.6, 21.6 }, 7)
	for index = 0, 3 do
		for _, y in { 0.04, 7.04 } do
			B.part({
				Name = "ParkingLine",
				Size = { 0.3, 0.06, 6 },
				Position = { 12 + index * 6.5, y, 17 },
				Color = "LaneWhite",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
	end
	Pieces.crate("ParkingCrate", { 30, 6 }, 3, 7)
	Pieces.crate("ParkingCrate", { 30.4, 6.2 }, 2.4, 10, 20)
	Pieces.tires("ParkingTires", { 14, 15 }, 2, 7)
	roadWear({ { -20, -36 }, { 34, -36 } })
end

-- South (96 × 96): a bus shelter you can climb onto (+5.5), a roadside billboard on posts and a barrier line.
local function southFeatures()
	B.part({
		Name = "ShelterRoof",
		Size = { 22, 0.5, 8 },
		Position = { 24, 5.25, 7 },
		Color = "TealDark",
		Material = "Metal",
		CastShadow = true,
	})
	for _, x in { 14.5, 33.5 } do
		for _, z in { 3.5, 10.5 } do
			Pieces.column("ShelterPost", { x, z }, 0, 5, 0.4, "Metal", "Metal")
		end
	end
	for index = 0, 3 do
		B.part({
			Name = "ShelterGlass",
			Size = { 4.6, 3.6, 0.15 },
			Position = { 16.8 + index * 4.8, 2.6, 10.4 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.45,
		})
	end
	Pieces.block("ShelterBench", { 24, 9.2 }, { 12, 0.4, 1.6 }, "Wood", "WoodPlanks", 1.1)
	for _, x in { 19, 29 } do
		Pieces.block("ShelterBenchLeg", { x, 9.2 }, { 0.3, 1.1, 1.2 }, "MetalDark", "Metal")
	end
	for _, x in { -28, -8 } do
		Pieces.column("BillboardPost", { x, -40 }, 0, 15, 0.9, "MetalDark", "Metal")
	end
	B.sign({
		Name = "Billboard",
		Size = { 22, 7, 0.6 },
		Position = { -18, 11, -40 },
		Rotation = B.yaw("North"),
		Color = "DustyPink",
		Material = "SmoothPlastic",
		Key = "Map.BrokenHighway.Sign.Billboard",
		TextColor = "Black",
	})
	B.part({
		Name = "BillboardFrame",
		Size = { 23, 8, 0.4 },
		Position = { -18, 11, -40.2 },
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	Pieces.jersey("Barrier", { -4, -20 }, 12, 0, nil, true)
	roadWear({ { -30, 20 }, { 34, -34 } })
end

-- A corner ledge: low barrier walls along its two outer edges (the corner stays open for the jump to a peak) and a
-- crate. `sx` / `sz` point outward.
local function ledgeFeatures(sx: number, sz: number)
	Pieces.jersey("LedgeWall", { 22.5 * sx, -7 * sz }, 26, 90)
	Pieces.jersey("LedgeWall", { -7 * sx, 22.5 * sz }, 26, 0)
	Pieces.crate("LedgeCrate", { 8 * sx, -8 * sz }, 3, nil, 15)
end

-- A peak (a giant green highway sign lying flat): a white rim and a floodlight on its outer corner.
local function peakFeatures(sx: number, sz: number)
	for _, edge in { { 0, 19.8, 40, 0.4 }, { 0, -19.8, 40, 0.4 }, { 19.8, 0, 0.4, 40 }, { -19.8, 0, 0.4, 40 } } do
		B.part({
			Name = "SignRim",
			Size = { edge[3], 0.3, edge[4] },
			Position = { edge[1], 0.15, edge[2] },
			Color = "OffWhite",
			Material = "Metal",
			CanCollide = false,
		})
	end
	Pieces.lamp("Floodlight", { 17 * sx, 17 * sz }, 6, if sx > 0 then 45 else -135, nil, true)
end

-- A low platform: a tyre stack to hide behind and a barrier.
local function lowFeatures(side: number)
	Pieces.tires("LowTires", { 14 * side, 0 }, 3)
	Pieces.jersey("Barrier", { if side > 0 then -2 else 2, if side > 0 then 4 else -4 }, 12, 0)
end

-- Decor and shapes on each platform (positions from its top centre). Part of the platform, so it crumbles with it.
local function decorate(platform: Platform)
	-- Jagged broken underside, tilted 4°: lowered by what the tilt raises its far end, so it never pokes up through the
	-- road (on the wide centre it used to, by up to 2 studs).
	local underWidth = platform.Size[1] * 0.7
	B.part({
		Name = "Underside",
		Size = { underWidth, 3, platform.Size[2] * 0.6 },
		Position = { 0, -platform.Thickness - 1.6 - underWidth / 2 * math.sin(math.rad(4)), 0 },
		Rotation = { 0, 8, 4 },
		Color = "ConcreteDark",
		Material = "Concrete",
	})
	-- Overpass pillars hanging under the platform (decor only).
	if platform.Kind ~= "Ledge" and platform.Kind ~= "Peak" then
		local diameter = if platform.Kind == "Center" then 10 else 6
		local length = if platform.Kind == "Center" then 56 else 36
		local offsets = if platform.Kind == "Center" then { -36 * GROWTH, 0, 36 * GROWTH } else { 0 }
		for _, offset in offsets do
			B.part({
				Name = "Pillar",
				Size = { length, diameter, diameter },
				Position = { offset, -platform.Thickness - length / 2, 0 },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "Concrete",
				Material = "Concrete",
				CanCollide = false,
			})
		end
	end
	-- A kerb round the edge of every road platform.
	if platform.Kind ~= "Peak" then
		local halfX, halfZ = platform.Size[1] / 2, platform.Size[2] / 2
		for _, edge in
			{
				{ 0, halfZ - 0.3, platform.Size[1], 0.6 },
				{ 0, -halfZ + 0.3, platform.Size[1], 0.6 },
				{ halfX - 0.3, 0, 0.6, platform.Size[2] },
				{ -halfX + 0.3, 0, 0.6, platform.Size[2] },
			}
		do
			B.part({
				Name = "Kerb",
				Size = { edge[3], 0.12, edge[4] },
				Position = { edge[1], 0.06, edge[2] },
				Color = "ConcreteDark",
				Material = "Concrete",
				CanCollide = false,
			})
		end
	end

	local sx = if platform.Center[1] > 0 then 1 else -1
	local sz = if platform.Center[2] > 0 then 1 else -1
	if platform.Kind == "Center" then
		centerDecor(platform)
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
		peakFeatures(sx, sz)
	elseif platform.Kind == "Low" then
		lowFeatures(sx)
	end
	if platform.Id == "LedgeNE" then
		exitSign({ 2, 2 }, "South")
	elseif platform.Id == "LedgeSW" then
		exitSign({ -2, -2 }, "North")
	elseif platform.Id == "PeakNE" then
		exitSign({ -4, -4 }, "South")
	elseif platform.Id == "PeakSW" then
		exitSign({ 4, 4 }, "North")
	end
end

--[[
	The moving parts (Shared/MoverRules; positions from the arena origin = the centre's top):
	  * Lift: a diamond-plate pad from the centre's floor (north of the deck) up to the catwalk's bridge (+14).
	  * SwingingSign: a broken highway sign swinging across the deck on its chains; it knocks you off your feet.
	  * SlideBridge: a flatbed plate sliding along the gap between the centre and the South platform, flush with both:
	    when it passes, you can walk across.
]]
local function movers()
	local vector = B.roblox.Vector3.new
	Arena.mover("Lift", { 0, 0.5, 28 }, { Kind = "Lift", Period = 11, Pause = 3, Offset = vector(0, 13, 0) }, function()
		B.part({
			Name = "LiftPad",
			Size = { 8, 1, 8 },
			Position = { 0, 0.5, 28 },
			Color = "MetalDark",
			Material = "DiamondPlate",
			CastShadow = true,
		})
		for _, x in { -3.8, 3.8 } do
			Pieces.railing("LiftRail", { x, 24.4 }, { x, 31.6 }, 1, 1.2, "LaneYellow")
		end
		for _, z in { 24.1, 31.9 } do
			B.part({
				Name = "LiftEdge",
				Size = { 8, 0.08, 0.2 },
				Position = { 0, 1.04, z },
				Color = "LaneYellow",
				Material = "Neon",
				CanCollide = false,
				CastShadow = false,
			})
		end
	end)

	Arena.mover(
		"SwingingSign",
		{ -24, 20.5, 0 },
		{ Kind = "Swing", Period = 3.6, Angle = 55, Axis = "Z", Phase = 0.4 },
		function()
			for _, z in { -3, 3 } do
				B.part({
					Name = "Chain",
					Size = { 0.2, 7.4, 0.2 },
					Position = { -24, 16.8, z },
					Color = "MetalDark",
					Material = "Metal",
					CanCollide = false,
				})
			end
			for _, side in { -1, 1 } do
				local board = B.sign({
					Name = "SwingBoard",
					Size = { 9, 4, 0.2 },
					Position = { -24 + side * 0.15, 11, 0 },
					Rotation = B.yaw(if side < 0 then "West" else "East"),
					Color = "SignGreen",
					Material = "Metal",
					Key = "Map.BrokenHighway.Sign.Exit",
					TextColor = "OffWhite",
					CanCollide = false,
				})
				board:AddTag("Hazard")
			end
			B.part({
				Name = "SwingBoardRim",
				Size = { 0.5, 4.4, 9.4 },
				Position = { -24, 11, 0 },
				Color = "OffWhite",
				Material = "Metal",
				CanCollide = false,
			})
		end
	)

	Arena.mover(
		"SlideBridge",
		{ -40, -0.5, -85 },
		{ Kind = "Slide", Period = 14, Pause = 2.5, Offset = vector(80, 0, 0), Phase = 3 },
		function()
			B.part({
				Name = "Flatbed",
				Size = { 10, 1, 9.6 },
				Position = { -40, -0.5, -85 },
				Color = "RustOrange",
				Material = "DiamondPlate",
				CastShadow = true,
			})
			for _, x in { -44.8, -35.2 } do
				for index = 0, 3 do
					B.part({
						Name = "FlatbedStripe",
						Size = { 0.4, 0.06, 2.2 },
						Position = { x, 0.03, -88.6 + index * 2.4 },
						Color = if index % 2 == 0 then "LaneYellow" else "Black",
						Material = "SmoothPlastic",
						CanCollide = false,
					})
				end
			end
			for _, x in { -44.6, -35.4 } do
				for _, z in { -89.4, -80.6 } do
					B.part({
						Name = "FlatbedBeacon",
						Size = { 0.4, 0.4, 0.4 },
						Position = { x, 0.2, z },
						Shape = "Ball",
						Color = "Amber",
						Material = "Neon",
						CanCollide = false,
						CastShadow = false,
					})
				end
			end
		end
	)
end

local function scenery(killY: number)
	-- Floating debris chunks around the arena (laid out for the first arena, a quarter of today's).
	B.spread(2 * GROWTH, function()
		for index, chunk in
			{
				{ -95, -18, 40, 22, 14, 12 },
				{ 100, -26, -30, 18, 12, -9 },
				{ 30, -34, 90, 26, 12, 6 },
				{ -40, -22, -95, 20, 10, -14 },
				{ 85, -12, 70, 12, 10, 18 },
			}
		do
			B.part({
				Name = `Debris{index}`,
				Size = { chunk[4], 3, chunk[5] },
				Position = { chunk[1], chunk[2], chunk[3] },
				Rotation = { chunk[6], index * 23, chunk[6] / 2 },
				Color = "Asphalt",
				Material = "Asphalt",
				CanCollide = false,
			})
		end
	end)
	-- Ruins of the old highway standing in the sludge all round: broken pillars carrying tilted slabs of road with
	-- lane lines, a lamp post still on one (decor; nothing out there can be reached).
	for index, ruin in
		{
			{ -360, 120, 20, -18 },
			{ 360, -120, -15, -24 },
			{ -170, 260, 35, -14 },
			{ 170, -260, -30, -20 },
			{ 0, 320, 10, -28 },
			{ -380, -160, -25, -16 },
		}
	do
		local x, z, yaw, top = ruin[1], ruin[2], ruin[3], ruin[4]
		B.part({
			Name = `RuinPillar{index}`,
			Size = { top - killY + 30, 14, 14 },
			Position = { x, (top + killY - 30) / 2, z },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Concrete",
			Material = "Concrete",
			CanCollide = false,
		})
		B.part({
			Name = `RuinSlab{index}`,
			Size = { 60, 4, 26 },
			Position = { x, top + 2, z },
			Rotation = { index % 2 * 6 - 3, yaw, (index % 3 - 1) * 7 },
			Color = "Asphalt",
			Material = "Asphalt",
			CanCollide = false,
		})
		for dash = -2, 2 do
			B.part({
				Name = `RuinLane{index}`,
				Size = { 6, 0.1, 0.8 },
				Position = {
					x + dash * 10 * math.cos(math.rad(yaw)),
					top + 4.1,
					z - dash * 10 * math.sin(math.rad(yaw)),
				},
				Rotation = { index % 2 * 6 - 3, yaw, (index % 3 - 1) * 7 },
				Color = "LaneYellow",
				Material = "SmoothPlastic",
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	B.within({ -360, -18 + 4, 120 }, function()
		Pieces.lamp("RuinLamp", { 12, 4 }, 14, 70, 0, true)
	end)
	-- Toxic sludge far below: the green glow under the arena.
	B.part({
		Name = "Sludge",
		Size = { 2800, 1, 2800 },
		Position = { 0, killY - 30, 0 },
		Color = "ToxicGreen",
		Material = "Neon",
		Transparency = 0.35,
		CanCollide = false,
		CastShadow = false,
	})
end

-- Builds the arena model at `origin` (world position of the centre platform's top centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery, movers)
end

return Layout
