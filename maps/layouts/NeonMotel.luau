--!strict
--[[
	Map 3: Neon Motel — sinking motel rooftops over a flooded street at night, flickering retro neon, a pool on one
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
end

local function scenery(killY: number)
	-- The flooded street far below.
	B.part({
		Name = "FloodWater",
		Size = { 2800, 1, 2800 },
		Position = { 0, killY - 25, 0 },
		Color = "TealDark",
		Material = "Glass",
		Transparency = 0.2,
		CanCollide = false,
		CastShadow = false,
	})
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
			Size = { block[3], height, block[5] },
			Position = { x, killY - 25 + height / 2 - 10, z },
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

-- Builds the arena model at `origin` (world position of the centre platform's top centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery)
end

return Layout
