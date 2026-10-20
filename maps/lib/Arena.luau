--!strict
--[[
	Arena — what every arena layout shares (bible §3.2): floating platforms over a void, each a Platform-tagged model
	(Persistent streaming, CanFall unless it is the centre) whose gameplay markers ride on it so they fall with it
	when it crumbles; KillY 60 studs below the lowest platform; a "Scenery" folder for decor off the platforms.
	Layers (owner, 2026-10-17: "twice bigger, more layers"): Low platforms (about 6 below a side), the base level
	(Center and Sides), the mid level (Ledges, and the centre's raised Deck with a ramp on each end) and the high
	level (Peaks, about 6 above a ledge). Each climb is at most 6 studs, so every platform can be reached with a jump
	(+ dash across a gap).
	A layout can list its platforms and contents at one size and grow them (Arena.grow / growContents: every platform
	`factor` times bigger, every gap kept; owner, 2026-10-20: "double every platform").
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

-- The edge-to-edge gap between two platforms on the floor plan (0 when their footprints overlap).
function Arena.gap(a: Platform, b: Platform): number
	local gapX = math.max(0, math.abs(a.Center[1] - b.Center[1]) - (a.Size[1] + b.Size[1]) / 2)
	local gapZ = math.max(0, math.abs(a.Center[2] - b.Center[2]) - (a.Size[2] + b.Size[2]) / 2)
	return math.sqrt(gapX * gapX + gapZ * gapZ)
end

--[[
	Grows every platform `factor` times wider and longer (owner, 2026-10-20: "double every platform") while keeping each
	gap the same, so every jump still works. Each platform is reached from the nearest one listed before it (the centre
	comes first and stays at the origin); along an axis where the two are apart, the child moves out by exactly what
	both grew, and along an axis where they overlap, its offset scales with them. Heights stay; a deck grows with its
	platform (its height and the climb stay the same).
]]
function Arena.grow(platforms: { Platform }, factor: number): { Platform }
	local grown: { Platform } = {}
	for index, platform in platforms do
		local copy = table.clone(platform)
		copy.Size = { platform.Size[1] * factor, platform.Size[2] * factor }
		local deck = platform.Deck
		if deck then
			local offset = deck.Offset
			copy.Deck = {
				Size = { deck.Size[1] * factor, deck.Size[2] * factor },
				Height = deck.Height,
				Ramp = deck.Ramp * factor,
				RampWidth = deck.RampWidth * factor,
				Offset = if offset then { offset[1] * factor, offset[2] * factor } else nil,
			}
		end
		local parentIndex, nearest = nil, math.huge
		for earlier = 1, index - 1 do
			local gap = Arena.gap(platforms[earlier], platform)
			if gap < nearest then
				parentIndex, nearest = earlier, gap
			end
		end
		if parentIndex then
			local parent, grownParent = platforms[parentIndex], grown[parentIndex]
			local center: { number } = {}
			for axis = 1, 2 do
				local offset = platform.Center[axis] - parent.Center[axis]
				local halves = (platform.Size[axis] + parent.Size[axis]) / 2
				center[axis] = grownParent.Center[axis]
					+ if math.abs(offset) >= halves
						then offset + math.sign(offset) * halves * (factor - 1)
						else offset * factor
			end
			copy.Center = center
		else
			copy.Center = { platform.Center[1] * factor, platform.Center[2] * factor }
		end
		grown[index] = copy
	end
	return grown
end

-- The platforms' contents with every spot `factor` times further from its platform's centre (sizes stay).
function Arena.growContents(contents: { [string]: Contents }, factor: number): { [string]: Contents }
	local function scaled(spot: Spot): Spot
		return { spot[1] * factor, spot[2] * factor }
	end
	local grown: { [string]: Contents } = {}
	for id, entry in contents do
		local spawns: { Spot } = {}
		for _, spot in entry.Spawns or {} do
			table.insert(spawns, scaled(spot))
		end
		local props: { Spot } = {}
		for _, spot in entry.Props or {} do
			table.insert(props, scaled(spot))
		end
		local structures = {}
		for _, structure in entry.Structures or {} do
			table.insert(structures, { Type = structure.Type, At = scaled(structure.At), Yaw = structure.Yaw })
		end
		grown[id] = {
			Spawns = if entry.Spawns then spawns else nil,
			Props = if entry.Props then props else nil,
			Explosive = if entry.Explosive then scaled(entry.Explosive) else nil,
			Structures = if entry.Structures then structures else nil,
		}
	end
	return grown
end

--[[
	Where a bridge between platforms `a` and `b` meets each of them (owner, 2026-10-20: "outer platforms more connected
	together — still able to crumble"): from arena-origin points on each platform's top, 0.5 studs in from the facing
	edges. Side by side (apart along one axis, overlapping along the other) the bridge crosses the gap straight, at
	`along` on the overlapping axis (default: the middle of the overlap); corner to corner (apart on both axes) it runs
	diagonally between the facing corners, 2 studs in. The layout builds each half with its own platform, so a
	crumbling platform takes its half and leaves the other half as a broken stub.
]]
function Arena.bridgeEnds(a: Platform, b: Platform, along: number?): ({ number }, { number })
	local function bounds(p: Platform, axis: number): (number, number)
		return p.Center[axis] - p.Size[axis] / 2, p.Center[axis] + p.Size[axis] / 2
	end
	local gaps = {}
	for axis = 1, 2 do
		gaps[axis] = math.abs(a.Center[axis] - b.Center[axis]) - (a.Size[axis] + b.Size[axis]) / 2
	end
	local function edge(p: Platform, toward: Platform, axis: number, inset: number): number
		local low, high = bounds(p, axis)
		return if toward.Center[axis] > p.Center[axis] then high - inset else low + inset
	end
	if gaps[1] > 0 and gaps[2] > 0 then
		return { edge(a, b, 1, 2), a.Top, edge(a, b, 2, 2) }, { edge(b, a, 1, 2), b.Top, edge(b, a, 2, 2) }
	end
	local across = if gaps[1] > 0 then 1 else 2 -- the axis the gap is on
	local other = 3 - across
	local aLow, aHigh = bounds(a, other)
	local bLow, bHigh = bounds(b, other)
	local at = along or (math.max(aLow, bLow) + math.min(aHigh, bHigh)) / 2
	local function point(p: Platform, toward: Platform): { number }
		local values = { 0, 0 }
		values[across] = edge(p, toward, across, 0.5)
		values[other] = at
		return { values[1], p.Top, values[2] }
	end
	return point(a, b), point(b, a)
end

-- Whether arena-origin point (x, z) is over platform `p`'s footprint.
local function over(p: Platform, x: number, z: number): boolean
	return math.abs(x - p.Center[1]) <= p.Size[1] / 2 and math.abs(z - p.Center[2]) <= p.Size[2] / 2
end

--[[
	Splits a straight elevated road from `from` to `to` (arena-origin points; the road's top passes through them) into
	one piece per platform it passes over, in `owners` order: each piece runs from where the road leaves the previous
	platform's footprint (the middle of the gap it crosses) to the middle of the next gap, so each platform carries the
	road above it and takes that piece down when it crumbles. Returns { Owner, From, To } pieces.
]]
function Arena.splitRoad(
	platforms: { Platform },
	owners: { string },
	from: { number },
	to: { number }
): { { Owner: string, From: { number }, To: { number } } }
	local byId: { [string]: Platform } = {}
	for _, platform in platforms do
		byId[platform.Id] = platform
	end
	local function at(t: number): { number }
		return {
			from[1] + (to[1] - from[1]) * t,
			from[2] + (to[2] - from[2]) * t,
			from[3] + (to[3] - from[3]) * t,
		}
	end
	local steps = 2000
	-- Where the road leaves each owner and enters the next (by sampling along it).
	local cuts: { number } = {}
	for index = 1, #owners - 1 do
		local current, nextOne = byId[owners[index]], byId[owners[index + 1]]
		local leave, enter = nil, nil
		for step = 0, steps do
			local t = step / steps
			local point = at(t)
			if leave == nil and not over(current, point[1], point[3]) and t > (cuts[#cuts] or 0) then
				leave = t
			end
			if leave and enter == nil and over(nextOne, point[1], point[3]) then
				enter = t
				break
			end
		end
		assert(leave and enter, `the road doesn't run from {owners[index]} to {owners[index + 1]}`)
		table.insert(cuts, (leave + enter) / 2)
	end
	local pieces = {}
	local previous = 0
	for index, owner in owners do
		local t = cuts[index] or 1
		table.insert(pieces, { Owner = owner, From = at(previous), To = at(t) })
		previous = t
	end
	return pieces
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

--[[
	A moving part (Shared/MoverRules; owner, 2026-10-20: "moving parts"): a Mover-tagged model, always streamed in, with
	an invisible "Pivot" part at `pivot` (from the arena origin; a Swing turns about it) and the rest built by `fill`
	(positions from the arena origin). `attributes`: Kind ("Lift" / "Slide" / "Swing"), Period, Pause, Offset (Vector3),
	Angle, Axis, Phase. Hazard-tagged parts knock fighters they touch (MoverService). Movers sit in the arena's Movers
	folder, not on a platform, so they never crumble.
]]
function Arena.mover(name: string, pivot: { number }, attributes: { [string]: any }, fill: () -> ()): any
	local model = B.model(name, function()
		B.part({
			Name = "Pivot",
			Size = { 1, 1, 1 },
			Position = pivot,
			Color = "Metal",
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
		})
		fill()
	end, attributes)
	local pivotPart = model:FindFirstChild("Pivot")
	pivotPart.CanQuery = false
	pivotPart.CanTouch = false
	model.PrimaryPart = pivotPart
	model.ModelStreamingMode = B.Enum.ModelStreamingMode.Persistent
	model:AddTag("Mover")
	return model
end

-- Builds the arena model at `origin` (world position of the centre platform's top centre). `movers` (optional) builds
-- the arena's moving parts (Arena.mover), from the arena origin.
function Arena.build(
	layout: Layout,
	origin: { number },
	decorate: (Platform) -> (),
	scenery: (killY: number) -> (),
	movers: (() -> ())?
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
			if movers then
				B.folder("Movers", movers)
			end
		end)
	end, {
		MapId = layout.Id,
		Lighting = layout.Lighting,
		KillY = origin[2] + killY,
	})
end

return Arena
