--!strict
--[[
	Map 1: Broken Highway — shattered overpass chunks over a toxic void (bible §3.2), twice the first size with four
	layers (owner, 2026-10-17).

	Platforms (studs; X/Z footprint, top height):
	  Center 120x80 (never falls) with a raised 36x20 overpass deck (+6, a ramp on each end) ·
	  East/West/North/South 48x48 · four 24x24 corner ledges (+6) · two 20x20 peaks (+12) beyond the NE / SW
	  ledges · two 28x28 low slabs beyond East (−4) and West (−6).
	  Gaps to the nearest platform: East 11, West 9, North 12, South 10, ledges / peaks 9.9 (diagonal), lows 10 — all
	  within 8-14, crossable with jump + dash; every climb is at most 6 studs.
	Gameplay markers ride on their platform so they fall with it: 16 spawns, 24 loose prop spots,
	8 breakable structures, 1 explosive barrel per side and low platform.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")

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

Layout.Platforms = {
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
}

Layout.Contents = {
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
} :: { [string]: Contents }

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
	-- Low guardrail stubs: knockback still carries players over them.
	for _, rail in
		{
			{ from = 20, to = 44, z = halfZ - 0.6 },
			{ from = -44, to = -24, z = -halfZ + 0.6 },
			{ from = -16, to = 0, z = halfZ - 0.6 },
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
	-- Cracks.
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
end

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
end

-- Decor on each platform (positions from its top centre). Part of the platform, so it crumbles with it.
local function decorate(platform: Platform)
	-- Jagged broken underside.
	B.part({
		Name = "Underside",
		Size = { platform.Size[1] * 0.7, 3, platform.Size[2] * 0.6 },
		Position = { 0, -platform.Thickness - 1.2, 0 },
		Rotation = { 0, 8, 4 },
		Color = "ConcreteDark",
		Material = "Concrete",
	})
	-- Overpass pillars hanging under the platform (decor only).
	if platform.Kind ~= "Ledge" and platform.Kind ~= "Peak" then
		local diameter = if platform.Kind == "Center" then 10 else 6
		local length = if platform.Kind == "Center" then 56 else 36
		local offsets = if platform.Kind == "Center" then { -36, 0, 36 } else { 0 }
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

	if platform.Kind == "Center" then
		centerDecor(platform)
	elseif platform.Id == "LedgeNE" then
		exitSign({ 2, 2 }, "South")
	elseif platform.Id == "LedgeSW" then
		exitSign({ -2, -2 }, "North")
	elseif platform.Id == "PeakNE" then
		exitSign({ -4, -4 }, "South")
	elseif platform.Id == "PeakSW" then
		exitSign({ 4, 4 }, "North")
	end
end

local function scenery(killY: number)
	-- Floating debris chunks around the arena (laid out for the first, half-size arena).
	B.spread(2, function()
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
	-- Toxic sludge far below: the green glow under the arena.
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
end

-- Builds the arena model at `origin` (world position of the centre platform's top centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery)
end

return Layout
