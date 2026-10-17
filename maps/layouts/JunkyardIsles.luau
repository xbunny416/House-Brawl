--!strict
--[[
	Map 2: Junkyard Isles — stacked car and container islands over toxic sludge (bible §3.1–3.2), at dusk; twice the
	first size with four layers (owner, 2026-10-17).

	Platforms (studs; X/Z footprint, top height):
	  Center 96x96 scrap heap (never falls) with a raised 28x20 scrap deck (+6, a ramp on each end) ·
	  East 40x56 container stack (+3) · West 44x44 car pile · North 48x40 crane barge (−2) · South 56x36 barge (−1) ·
	  four 20x20 tire-stack ledges (+6) · two 18x18 tire towers (+12) beyond the NE / SW ledges · two 28x28 junk
	  rafts beyond West (−6) and South (−7).
	  Gaps to the nearest platform: East 11, West 11, North 12, South 12, ledges 8.5 (diagonal), towers 9.9, rafts 10
	  — all within 8-14, crossable with jump + dash; every climb is at most 6 studs.
	Same rules as Broken Highway: 16 spawns, 24 loose prop spots, 8 breakable structures, 1 explosive barrel per side
	and low platform, KillY 60 studs below the lowest platform. Edge decor stays low (≤ 1.6 studs) so knockback carries
	over.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")

type Platform = Arena.Platform
type Contents = Arena.Contents

local Layout = {}

Layout.Id = "JunkyardIsles"
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

local center = platform("Center", "Center", { 0, 0 }, { 96, 96 }, 0, 4, "RustDark", "CorrodedMetal")
center.Deck = { Size = { 28, 20 }, Height = 6, Ramp = 12, RampWidth = 12 }

Layout.Platforms = {
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
}

Layout.Contents = {
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
} :: { [string]: Contents }

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

local function craneDecor()
	-- Mast on the north-west corner, arm reaching out over the centre island, magnet hanging from it.
	B.part({
		Name = "CraneMast",
		Size = { 1.6, 24, 1.6 },
		Position = { -10, 12, 8 },
		Color = "LaneYellow",
		Material = "Metal",
	})
	B.part({
		Name = "CraneArm",
		Size = { 1.2, 1.2, 32 },
		Position = { -10, 23.4, -7 },
		Color = "LaneYellow",
		Material = "Metal",
		CanCollide = false,
	})
	B.part({
		Name = "CraneCable",
		Size = { 0.2, 7, 0.2 },
		Position = { -10, 19.3, -21 },
		Color = "Black",
		CanCollide = false,
	})
	B.part({
		Name = "Magnet",
		Size = { 1, 5, 5 },
		Position = { -10, 15.3, -21 },
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
			Position = { corner[1], 0.4, corner[2] },
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

local function decorate(platform: Platform)
	if platform.Kind ~= "Ledge" and platform.Kind ~= "Peak" then
		underside(platform, platform.Color)
	end
	-- Decor laid out for the first, half-size islands spreads over the bigger ones (B.spread).
	if platform.Id == "Center" then
		B.spread(2, centerDecor)
	elseif platform.Id == "East" then
		containerDecor(platform)
	elseif platform.Id == "West" then
		B.spread(2, carPileDecor)
	elseif platform.Id == "North" then
		B.spread(2, craneDecor)
	elseif platform.Id == "South" or platform.Kind == "Low" then
		bargeDecor(platform)
	else
		tireStack(platform)
	end
end

local function scenery(killY: number)
	-- Toxic sludge far below, with junk mounds poking out of it (laid out for the half-size arena: B.spread).
	B.part({
		Name = "Sludge",
		Size = { 1400, 1, 1400 },
		Position = { 0, killY - 30, 0 },
		Color = "ToxicGreen",
		Material = "Neon",
		Transparency = 0.35,
		CanCollide = false,
		CastShadow = false,
	})
	B.spread(2, function()
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
				Color = if index % 2 == 0 then "ToxicGreen" else "RustOrange",
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

-- Builds the arena model at `origin` (world position of the centre platform's top centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery)
end

return Layout
