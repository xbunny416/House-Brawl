--!strict
--[[
	Arena — what every arena layout shares (bible §3.2): floating platforms over a void, each a Platform-tagged model
	(Persistent streaming, CanFall unless it is the centre) whose gameplay markers ride on it so they fall with it
	when it crumbles; KillY 60 studs below the lowest platform; a "Scenery" folder for decor off the platforms.
	A layout lists its Platforms and their Contents (spawns, prop spots, an explosive barrel, structures) and passes
	a `decorate(platform)` callback that adds its own parts on each platform, positioned from the platform's top
	centre.
]]
local B = require("./Builder")

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

export type Spot = { number } -- X, Z relative to the platform's top centre

export type Contents = {
	Spawns: { Spot }?,
	Props: { Spot }?,
	Explosive: Spot?,
	Structures: { { Type: string, At: Spot, Yaw: number } }?,
}

export type Layout = {
	Id: string,
	Lighting: string,
	Platforms: { Platform },
	Contents: { [string]: Contents },
}

local Arena = {}

Arena.KILL_DEPTH = 60 -- bible: KillY 60 studs below the lowest platform

-- Lowest platform bottom (relative to the arena origin) minus the kill depth.
function Arena.killY(platforms: { Platform }): number
	local lowest = math.huge
	for _, platform in platforms do
		lowest = math.min(lowest, platform.Top - platform.Thickness)
	end
	return lowest - Arena.KILL_DEPTH
end

-- Yaw that points a marker's front (-Z) at the arena centre.
local function facingCenter(x: number, z: number): { number }
	return { 0, math.deg(math.atan2(x, z)), 0 }
end

local function buildPlatform(platform: Platform, contents: Contents, decorate: (Platform) -> ())
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
			decorate(platform)

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

-- Builds the arena model at `origin` (world position of the centre platform's top centre).
function Arena.build(
	layout: Layout,
	origin: { number },
	decorate: (Platform) -> (),
	scenery: (killY: number) -> ()
): any
	local killY = Arena.killY(layout.Platforms)
	return B.root(layout.Id, function()
		B.within(origin, function()
			B.folder("Platforms", function()
				for _, platform in layout.Platforms do
					buildPlatform(platform, layout.Contents[platform.Id] or {}, decorate)
				end
			end)
			B.folder("Scenery", function()
				scenery(killY)
			end)
		end)
	end, {
		MapId = layout.Id,
		Lighting = layout.Lighting,
		KillY = origin[2] + killY,
	})
end

return Arena
