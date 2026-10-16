--!strict
--[[
	Map 3: Neon Motel — sinking motel rooftops over a flooded street at night, flickering retro neon, a pool on one
	roof (bible §3.1–3.2; Night lighting).

	Platforms (studs; X/Z footprint, top height):
	  Center 56x36 main roof (never falls) · East 24x26 pool roof (+1) · West 22x22 sign roof (−1) ·
	  North 26x20 roof (−3) · South 24x20 roof (−2) · NE 10x10 water tower and SW 12x8 billboard ledges (+6).
	  Gaps to the nearest platform: East 10, West 12, North 12, South 11, ledges 8.6 / 8.9 (diagonal) — all within
	  8-14, crossable with jump + dash.
	Same rules as Broken Highway: 12 spawns, 14 loose prop spots, 4 breakable structures, 1 explosive barrel per side
	platform, KillY 60 studs below the lowest platform. Edge decor stays low so knockback carries over.
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

Layout.Platforms = {
	{
		Id = "Center",
		Kind = "Center",
		Center = { 0, 0 },
		Size = { 56, 36 },
		Top = 0,
		Thickness = 5,
		Color = "ConcreteDark",
		Material = "Slate",
	},
	{
		Id = "East",
		Kind = "Side",
		Center = { 50, -2 },
		Size = { 24, 26 },
		Top = 1,
		Thickness = 4,
		Color = "OffWhite",
		Material = "Concrete",
	},
	{
		Id = "West",
		Kind = "Side",
		Center = { -51, 3 },
		Size = { 22, 22 },
		Top = -1,
		Thickness = 4,
		Color = "DustyPink",
		Material = "Concrete",
	},
	{
		Id = "North",
		Kind = "Side",
		Center = { 4, 40 },
		Size = { 26, 20 },
		Top = -3,
		Thickness = 4,
		Color = "PinkDark",
		Material = "Slate",
	},
	{
		Id = "South",
		Kind = "Side",
		Center = { -4, -39 },
		Size = { 24, 20 },
		Top = -2,
		Thickness = 4,
		Color = "TealDark",
		Material = "Slate",
	},
	{
		Id = "LedgeNE",
		Kind = "Ledge",
		Center = { 38, 30 },
		Size = { 10, 10 },
		Top = 6,
		Thickness = 2,
		Color = "Wood",
		Material = "WoodPlanks",
	},
	{
		Id = "LedgeSW",
		Kind = "Ledge",
		Center = { -38, -30 },
		Size = { 12, 8 },
		Top = 6,
		Thickness = 1.5,
		Color = "MetalDark",
		Material = "DiamondPlate",
	},
} :: { Platform }

Layout.Contents = {
	Center = {
		Spawns = { { -22, -12 }, { 22, -12 }, { -22, 12 }, { 22, 12 } },
		Props = { { -14, -4 }, { -5, -11 }, { 9, -6 }, { -7, 7 }, { 5, 12 }, { 17, 2 } },
		Structures = {
			{ Type = "VendingMachine", At = { -14, 9 }, Yaw = 180 },
			{ Type = "IceMachine", At = { 14, -12 }, Yaw = 0 },
		},
	},
	East = {
		Spawns = { { -8, -9 }, { 8, 9 } },
		Props = { { -8, 6 }, { 8, -8 } },
		Explosive = { 0, -10 },
		Structures = { { Type = "LawnChairStack", At = { 0, 9.5 }, Yaw = 0 } },
	},
	West = {
		Spawns = { { -5, -7 }, { 7, 6 } },
		Props = { { 6, -6 }, { -6, 5 } },
		Explosive = { 1, 0 },
		Structures = { { Type = "IceMachine", At = { -6, -1 }, Yaw = 90 } },
	},
	North = {
		Spawns = { { -9, -5 }, { 9, 5 } },
		Props = { { 7, -5 }, { -7, 5 } },
		Explosive = { 0, 0 },
	},
	South = {
		Spawns = { { 9, -5 }, { -9, 5 } },
		Props = { { -6, -5 }, { 6, 5 } },
		Explosive = { 0, 0 },
	},
} :: { [string]: Contents }

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

-- A low roof edge (knockback carries over it) with a neon tube on top.
local function parapet(from: { number }, to: { number }, neon: string)
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
	B.part({
		Name = "NeonTube",
		Size = if alongX then { length, 0.25, 0.25 } else { 0.25, 0.25, length },
		Position = { center[1], 0.95, center[2] },
		Color = neon,
		Material = "Neon",
		CanCollide = false,
		Tags = FLICKER,
	})
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
	acUnit({ 1, 1 })
	acUnit({ -24, 0 })
	B.part({
		Name = "RoofHatch",
		Size = { 3, 0.6, 3 },
		Position = { -2, 0.3, -3 },
		Color = "MetalDark",
		Material = "Metal",
	})
	parapet({ -10, 17.7 }, { 14, 17.7 }, "NeonPink")
	parapet({ -16, -17.7 }, { 6, -17.7 }, "NeonTeal")
end

local function poolDecor()
	local poolX, poolZ = 10, 12 -- water size
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
	B.sign({
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
	B.part({
		Name = "Skylight",
		Size = { 4, 0.2, 3 },
		Position = { -1, 0.1, -6 },
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.3,
		CanCollide = false,
	})
	parapet({ -4, -9.7 }, { 10, -9.7 }, "NeonOrange")
end

local function waterTower(platform: Platform)
	B.part({
		Name = "Tank",
		Size = { 8, 9, 9 },
		Position = { 0, -platform.Thickness - 4, 0 },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "Wood",
		Material = "WoodPlanks",
		CanCollide = false,
	})
	for _, corner in { { -3.5, -3.5 }, { -3.5, 3.5 }, { 3.5, -3.5 }, { 3.5, 3.5 } } do
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
	B.sign({
		Name = "Billboard",
		Size = { 11, 5, 0.4 },
		Position = { 0, 2.5, backZ },
		Rotation = B.yaw("North"),
		Color = "DustyPink",
		Material = "SmoothPlastic",
		Key = "Map.NeonMotel.Sign.Billboard",
		TextColor = "Black",
	})
	B.part({
		Name = "BillboardLight",
		Size = { 11, 0.3, 0.3 },
		Position = { 0, 5.3, backZ + 0.6 },
		Color = "WarmLight",
		Material = "Neon",
		CanCollide = false,
		Tags = FLICKER,
	})
	for _, x in { -4, 4 } do
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
		northDecor()
	elseif platform.Id == "South" then
		southDecor()
	elseif platform.Id == "LedgeNE" then
		waterTower(platform)
	else
		billboard(platform)
	end
end

local function scenery(killY: number)
	-- The flooded street far below.
	B.part({
		Name = "FloodWater",
		Size = { 700, 1, 700 },
		Position = { 0, killY - 25, 0 },
		Color = "TealDark",
		Material = "Glass",
		Transparency = 0.2,
		CanCollide = false,
		CastShadow = false,
	})
	-- Dark buildings around the motel, half sunk, each with a neon sign on the side facing the arena.
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
		local height = block[4]
		local faceZ = if block[2] > 0 then -block[5] / 2 - 0.3 else block[5] / 2 + 0.3
		B.part({
			Name = `Tower{index}`,
			Size = { block[3], height, block[5] },
			Position = { block[1], killY - 25 + height / 2 - 10, block[2] },
			Color = "Black",
			Material = "Concrete",
			CanCollide = false,
			CastShadow = false,
		})
		B.part({
			Name = `TowerSign{index}`,
			Size = { block[3] * 0.5, 3, 0.4 },
			Position = { block[1], killY - 25 + height - 18, block[2] + faceZ },
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
