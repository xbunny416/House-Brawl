--!strict
--[[
	Map 1: Broken Highway — shattered overpass chunks over a toxic void (bible §3.2).

	Platforms (studs; X/Z footprint, top height):
	  Center 60x40 (never falls) · East/West/North/South 24x24 · two 12x12 high ledges.
	  Gaps to the nearest platform: East 11, West 9, North 12, South 10, ledges 10 (diagonal) — all within 8-14,
	  crossable with jump + dash.
	Gameplay markers ride on their platform so they fall with it: 12 spawns, 14 loose prop spots,
	4 breakable structures, 1 explosive barrel per side platform.
]]
local B = require("../lib/Builder")

export type Platform = {
	Id: string,
	Kind: "Center" | "Side" | "Ledge",
	Center: { number }, -- X, Z
	Size: { number }, -- X, Z
	Top: number,
	Thickness: number,
	Color: string,
	Material: string,
}

type Spot = { number } -- X, Z relative to the platform's top centre

type Contents = {
	Spawns: { Spot }?,
	Props: { Spot }?,
	Explosive: Spot?,
	Structures: { { Type: string, At: Spot, Yaw: number } }?,
}

local Layout = {}

Layout.Id = "BrokenHighway"
Layout.Lighting = "Dusk"

Layout.Platforms = {
	{
		Id = "Center",
		Kind = "Center",
		Center = { 0, 0 },
		Size = { 60, 40 },
		Top = 0,
		Thickness = 4,
		Color = "Asphalt",
		Material = "Asphalt",
	},
	{
		Id = "East",
		Kind = "Side",
		Center = { 53, 0 },
		Size = { 24, 24 },
		Top = 2,
		Thickness = 3,
		Color = "Asphalt",
		Material = "Asphalt",
	},
	{
		Id = "West",
		Kind = "Side",
		Center = { -51, 0 },
		Size = { 24, 24 },
		Top = 0,
		Thickness = 3,
		Color = "Asphalt",
		Material = "Asphalt",
	},
	{
		Id = "North",
		Kind = "Side",
		Center = { 0, 44 },
		Size = { 24, 24 },
		Top = -2,
		Thickness = 3,
		Color = "Concrete",
		Material = "Concrete",
	},
	{
		Id = "South",
		Kind = "Side",
		Center = { 0, -42 },
		Size = { 24, 24 },
		Top = 0,
		Thickness = 3,
		Color = "Concrete",
		Material = "Concrete",
	},
	{
		Id = "LedgeNE",
		Kind = "Ledge",
		Center = { 42, 34 },
		Size = { 12, 12 },
		Top = 6,
		Thickness = 2,
		Color = "ConcreteDark",
		Material = "Concrete",
	},
	{
		Id = "LedgeSW",
		Kind = "Ledge",
		Center = { -42, -34 },
		Size = { 12, 12 },
		Top = 6,
		Thickness = 2,
		Color = "ConcreteDark",
		Material = "Concrete",
	},
} :: { Platform }

Layout.Contents = {
	Center = {
		Spawns = { { -24, -14 }, { 24, -14 }, { -24, 14 }, { 24, 14 } },
		Props = { { -16, -6 }, { -6, -12 }, { 8, -6 }, { -8, 6 }, { 4, 13 }, { 18, 4 } },
		Structures = {
			{ Type = "WreckedCar", At = { -15, 10 }, Yaw = 15 },
			{ Type = "VendingMachine", At = { 14, -14 }, Yaw = 180 },
		},
	},
	East = {
		Spawns = { { -6, -8 }, { 6, 8 } },
		Props = { { -6, 6 }, { 2, -7 } },
		Explosive = { 0, 0 },
		Structures = { { Type = "RoadBarrierStack", At = { 8, -1 }, Yaw = 90 } },
	},
	West = {
		Spawns = { { -6, -8 }, { 8, 8 } },
		Props = { { 6, -4 }, { -9, -2 } },
		Explosive = { 2, -8 },
		Structures = { { Type = "WreckedCar", At = { -2, 4 }, Yaw = 90 } },
	},
	North = {
		Spawns = { { -7, -6 }, { 7, 7 } },
		Props = { { 6, -5 }, { -6, 6 } },
		Explosive = { 0, 0 },
	},
	South = {
		Spawns = { { 7, 6 }, { -7, -7 } },
		Props = { { -6, 5 }, { 6, -5 } },
		Explosive = { 0, 0 },
	},
} :: { [string]: Contents }

local KILL_DEPTH = 60 -- bible: KillY 60 studs below the lowest platform

-- Lowest platform bottom (relative to the arena origin) minus the kill depth.
function Layout.killY(): number
	local lowest = math.huge
	for _, platform in Layout.Platforms do
		lowest = math.min(lowest, platform.Top - platform.Thickness)
	end
	return lowest - KILL_DEPTH
end

local function facingCenter(x: number, z: number): { number }
	-- Yaw that points a marker's front (-Z) at the arena centre.
	return { 0, math.deg(math.atan2(x, z)), 0 }
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
	-- Two short, low guardrail stubs: knockback still carries players over them.
	for _, rail in { { from = 10, to = 22, z = halfZ - 0.6 }, { from = -22, to = -12, z = -halfZ + 0.6 } } do
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
	for _, crack in { { -4, 0, -9, 25 }, { 12, 0, 9, -40 }, { -20, 0, -2, 70 } } do
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

local function buildPlatform(platform: Platform)
	local contents = Layout.Contents[platform.Id] or {}
	local centerX, centerZ = platform.Center[1], platform.Center[2]
	local model = B.model(platform.Id, function()
		B.within({ centerX, platform.Top, centerZ }, function()
			B.slab({
				Name = "Base",
				Size = { platform.Size[1], platform.Thickness, platform.Size[2] },
				Position = { 0, 0, 0 },
				Color = platform.Color,
				Material = platform.Material,
				CastShadow = true,
			})
			-- Jagged broken underside.
			B.part({
				Name = "Underside",
				Size = { platform.Size[1] * 0.7, 3, platform.Size[2] * 0.6 },
				Position = { 0, -platform.Thickness - 1.2, 0 },
				Rotation = { 0, 8, 4 },
				Color = "ConcreteDark",
				Material = "Concrete",
			})

			if platform.Kind == "Center" then
				centerDecor(platform)
			elseif platform.Id == "LedgeNE" then
				exitSign({ 2, 2 }, "South")
			elseif platform.Id == "LedgeSW" then
				exitSign({ -2, -2 }, "North")
			end

			for index, spot in contents.Spawns or {} do
				B.marker(
					"SpawnPoint",
					`Spawn{index}`,
					{ spot[1], 0, spot[2] },
					nil,
					facingCenter(centerX + spot[1], centerZ + spot[2])
				)
			end
			for index, spot in contents.Props or {} do
				B.marker("PropSpot", `PropSpot{index}`, { spot[1], 0, spot[2] })
			end
			if contents.Explosive then
				B.marker("ExplosiveSpot", "ExplosiveSpot", { contents.Explosive[1], 0, contents.Explosive[2] })
			end
			for index, structure in contents.Structures or {} do
				B.marker(
					"StructureSpot",
					`StructureSpot{index}`,
					{ structure.At[1], 0, structure.At[2] },
					{ StructureType = structure.Type },
					{ 0, structure.Yaw, 0 }
				)
			end
		end)
	end, {
		PlatformId = platform.Id,
		Kind = platform.Kind,
		CanFall = platform.Kind ~= "Center",
	})
	model.PrimaryPart = model:FindFirstChild("Base")
	model.ModelStreamingMode = B.Enum.ModelStreamingMode.Persistent
	model:AddTag("Platform")
end

local function scenery(killY: number)
	-- Overpass pillars hanging under the platforms (decor only).
	for _, platform in Layout.Platforms do
		if platform.Kind ~= "Ledge" then
			local diameter = if platform.Kind == "Center" then 8 else 5
			local length = if platform.Kind == "Center" then 46 else 30
			local offsets = if platform.Kind == "Center" then { -15, 15 } else { 0 }
			for _, offset in offsets do
				B.part({
					Name = "Pillar",
					Size = { length, diameter, diameter },
					Position = {
						platform.Center[1] + offset,
						platform.Top - platform.Thickness - length / 2,
						platform.Center[2],
					},
					Rotation = { 0, 0, 90 },
					Shape = "Cylinder",
					Color = "Concrete",
					Material = "Concrete",
					CanCollide = false,
				})
			end
		end
	end
	-- Floating debris chunks around the arena.
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
	-- Toxic sludge far below: the green glow under the arena.
	B.part({
		Name = "Sludge",
		Size = { 700, 1, 700 },
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
	local killY = Layout.killY()
	return B.root(Layout.Id, function()
		B.within(origin, function()
			B.folder("Platforms", function()
				for _, platform in Layout.Platforms do
					buildPlatform(platform)
				end
			end)
			B.folder("Scenery", function()
				scenery(killY)
			end)
		end)
	end, {
		MapId = Layout.Id,
		Lighting = Layout.Lighting,
		KillY = origin[2] + killY,
	})
end

return Layout
