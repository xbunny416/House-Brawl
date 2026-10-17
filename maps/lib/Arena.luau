--!strict
--[[
	Arena — what every arena layout shares (bible §3.2): floating platforms over a void, each a Platform-tagged model
	(Persistent streaming, CanFall unless it is the centre) whose gameplay markers ride on it so they fall with it
	when it crumbles; KillY 60 studs below the lowest platform; a "Scenery" folder for decor off the platforms.
	Layers (owner, 2026-10-17: "twice bigger, more layers"): Low platforms (about 6 below a side), the base level
	(Center and Sides), the mid level (Ledges, and the centre's raised Deck with a ramp on each end) and the high
	level (Peaks, about 6 above a ledge). Each climb is at most 6 studs, so every platform can be reached with a jump
	(+ dash across a gap).
	A layout lists its Platforms and their Contents (spawns, prop spots, an explosive barrel, structures) and passes
	a `decorate(platform)` callback that adds its own parts on each platform, positioned from the platform's top
	centre.
]]
local B = require("./Builder")

-- A raised block on a platform (mid level) with a ramp up to it on its east and west ends.
export type Deck = {
	Size: { number }, -- X, Z of the top
	Height: number, -- studs above the platform top
	Ramp: number, -- length of each ramp (X)
	RampWidth: number, -- Z
	Offset: { number }?, -- X, Z from the platform's centre
}

export type Platform = {
	Id: string,
	Kind: "Center" | "Side" | "Ledge" | "Peak" | "Low",
	Center: { number }, -- X, Z
	Size: { number }, -- X, Z
	Top: number,
	Thickness: number,
	Color: string,
	Material: string,
	Deck: Deck?,
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

-- The deck's footprint with its ramps, as min / max X and Z from the platform's centre (for the specs).
function Arena.deckBounds(deck: Deck): { number }
	local offset = deck.Offset or { 0, 0 }
	local halfX = deck.Size[1] / 2 + deck.Ramp
	local halfZ = math.max(deck.Size[2], deck.RampWidth) / 2
	return { offset[1] - halfX, offset[1] + halfX, offset[2] - halfZ, offset[2] + halfZ }
end

-- Yaw that points a marker's front (-Z) at the arena centre.
local function facingCenter(x: number, z: number): { number }
	return { 0, math.deg(math.atan2(x, z)), 0 }
end

-- The deck block and its two ramps (wedges rising toward the deck), in the platform's colours.
local function buildDeck(platform: Platform, deck: Deck)
	local offset = deck.Offset or { 0, 0 }
	B.slab({
		Name = "Deck",
		Size = { deck.Size[1], deck.Height, deck.Size[2] },
		Position = { offset[1], deck.Height, offset[2] },
		Color = platform.Color,
		Material = platform.Material,
		CastShadow = true,
	})
	for _, side in { 1, -1 } do
		B.part({
			Name = "DeckRamp",
			Size = { deck.RampWidth, deck.Height, deck.Ramp },
			Position = { offset[1] + side * (deck.Size[1] + deck.Ramp) / 2, deck.Height / 2, offset[2] },
			Rotation = { 0, -90 * side, 0 }, -- the wedge's high end faces the deck
			Shape = "Wedge",
			Color = platform.Color,
			Material = platform.Material,
		})
	end
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
			if platform.Deck then
				buildDeck(platform, platform.Deck)
			end
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
