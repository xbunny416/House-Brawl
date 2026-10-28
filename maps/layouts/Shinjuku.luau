--!strict
--[[
	Map 4: Shinjuku — the only arena in the vote since 2026-10-28. The owner asked for one new arena instead of the 3 old
	ones ("just store them somewhere, don't delete them"; Broken Highway, Junkyard Isles and Neon Motel stay built,
	switched off in Config.Maps.List), then "no floating island", then "want arena to look like jjk shenanigans" (the
	Shinjuku battleground of the Roblox game Jujutsu Shenanigans), then "add breakable walls and trash can throwables,
	town structures bigger and can enter", then: "replace the train station with another thing; bit bigger structures
	like the shops and towers; more polish and detail", then: "shrink the arena by deleting the entire school area;
	remove the boundary so players can fall dead", then: "more dimension and dynamic, literally include inside
	structure too, also bigger buildings; I don't want too much flat area except the fountain area or the road". This is
	our own Shinjuku-style district in that spirit (generic names, nothing copied).

	A ground arena (Layout.Ground): one district (the Center platform, 560 × 340, never falls) with open edges: no
	walls, nothing round it, and the ground ends in a cliff over a dark abyss. Falling off is a KO (below KillY, as on
	the floating arenas), and so is 0 HP in Classic. Day light. Its buildings are ones you can walk into
	(maps/lib/Rooms: hollow storeys 10 high to fit an avatar, doors 8 high, floors, switchback ramps, roofs), furnished
	inside (desks, beds, booths,
	shelves, racks, partitions that break), and their walls and windows break (BreakableWall pieces,
	Services/WallService), as do the block walls, the graveyard's stones, the hedges and the site's fence. Only the
	streets and the fountain plaza are open ground; every block is built up, at many heights, joined by bridges, ladders
	and planks, with things that move (Arena.mover): glass lifts up the towers, a tower crane turning over the building
	site and its hoist, a Ferris wheel and a carousel on the department store's roof, the pachinko parlor's sign.

	Plan (north = +Z): the main street across along the north edge (z 90; the school, its gym and yard and the shrine
	stood north of it until 2026-10-28); below it, either side of the avenue (x 0), the twin towers (11 storeys of
	offices, a skybridge at the 9th, ladders and lifts up the outside to the roof). West of them: the two-storey ramen
	shop, the pachinko parlor, the yokocho (two rows of tiny bars on a lantern-lit lane) and the plaza (a fountain) with
	the cafe. East: the karaoke tower, the 24-hour mart, the multi-storey car park, the gas station and the police box,
	the graveyard with its temple and pagoda, the two-storey arcade. The second street across (z −90); south of it a
	row of five three-storey shops, the department store, a mechanical parking rack and a water tower behind them, the
	jail (cells, a yard with a watchtower) and the comedy club (tiered seats), the courthouse with the fire station
	(a drill tower) behind it, the hotel tower and the mansion, and the building site (a steel frame, scaffolding, the
	crane, a dirt mound and an excavator). The mall (three floors) and the bowling alley fill the west strip, two walk-in
	apartment blocks the east, joined by a deck over their lane and a footbridge above it. Japanese streets: utility
	poles with wires, crosswalks, street trees, bicycles, vending machines.
	Spots: 16 spawns (the streets and the plaza), 22 loose prop spots (on roofs, upper floors, decks, the skybridge),
	trash cans and chairs where they belong (TypedProps), 8 breakables, 6 explosive barrels. Spots and pieces are written
	from the arena origin (the main street's crossing with the avenue is at z 90); the district's centre is at z −60.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")
local Pieces = require("../lib/Pieces")
local Rooms = require("../lib/Rooms")

type Platform = Arena.Platform

local Layout = {}

Layout.Id = "Shinjuku"
Layout.Lighting = "Day"
Layout.Ground = true -- one ground platform instead of floating ones (the maps spec checks it differently)

local DISTRICT = { 560, 340 } -- X, Z: the playable ground, from z −230 (the south edge) to z 110 (the north edge)
local CENTER_Z = -60 -- the district's centre from the arena origin
local ROAD = 20
local BREAKABLE = { "BreakableWall" }
-- Sized to the avatar (owner, 2026-10-28: "structure and building want to match avatar size cus some still small"): a
-- Roblox avatar stands about 5.3 studs (more with a tall body), so a storey is 10 (9.5 of headroom), a door 8 high
-- and at least 5 wide, a stair lane at least 4 wide; cars, trees and poles are life-size beside it.
local STOREY = 10
local DOOR = 8 -- a doorway's height
-- The twin towers (x ±38): 40 wide, 11 storeys, the skybridge on the 9th.
local TOWER = { X = 38, Z = 35, Size = 40, Floors = 11, Storey = STOREY, BridgeFloor = 9 }
local TOWER_ROOF = TOWER.Floors * TOWER.Storey + 0.6
local BRIDGE_Y = (TOWER.BridgeFloor - 1) * TOWER.Storey
local CAFE = { At = { -40, -52 }, Size = { 42, 32 } }
local PACHINKO = { At = { -80, 58 }, Size = { 36, 28 } }
local KARAOKE = { At = { 81, 57 }, Size = { 36, 30 }, Floors = 4 }
-- The multi-storey car park: four open decks 9 apart (8.5 of headroom over the cars) and a roof deck.
local CARPARK = { At = { 111, 3 }, Size = { 94, 50 }, Floors = 4, Storey = 9 }
local CARPARK_ROOF = CARPARK.Floors * CARPARK.Storey + 0.6
local DEPT = { At = { -108, -187 }, Size = { 104, 70 }, Floors = 4 }
local DEPT_ROOF = DEPT.Floors * STOREY + 0.6
local HOTEL = { At = { 127, -136 }, Size = { 50, 34 }, Floors = 6 }
local HOTEL_ROOF = HOTEL.Floors * STOREY + 0.6
-- The building site's steel frame (decks at 10, 20 and 30, bare beams at 40) and its tower crane.
local SITE = { At = { 238, -165 }, Size = { 60, 48 }, Deck = 10 }
local CRANE = { At = { 204, -205 }, Height = 80, Jib = 50 }

Layout.Platforms = {
	{
		Id = "Center",
		Kind = "Center",
		Center = { 0, CENTER_Z },
		Size = DISTRICT,
		Top = 0,
		Thickness = 6,
		Color = "Concrete",
		Material = "Concrete",
	},
} :: { Platform }

-- The spots below are written from the arena origin, like the pieces; a platform's contents are from its centre.
local function fromOrigin(spot: Arena.Spot): Arena.Spot
	return { spot[1], spot[2] - CENTER_Z, spot[3] }
end

local function onDistrict(contents: Arena.Contents): Arena.Contents
	local function each(spots: { Arena.Spot }?): { Arena.Spot }
		local moved = {}
		for _, spot in spots or {} do
			table.insert(moved, fromOrigin(spot))
		end
		return moved
	end
	local typed = {}
	for _, prop in contents.TypedProps or {} do
		table.insert(typed, { At = fromOrigin(prop.At), Type = prop.Type })
	end
	local structures = {}
	for _, structure in contents.Structures or {} do
		table.insert(structures, { Type = structure.Type, At = fromOrigin(structure.At), Yaw = structure.Yaw })
	end
	return {
		Spawns = each(contents.Spawns),
		Props = each(contents.Props),
		Explosives = each(contents.Explosives),
		TypedProps = typed,
		Structures = structures,
	}
end

Layout.Contents = {
	Center = onDistrict({
		Spawns = {
			{ -240, 90 }, -- the main street along the north edge
			{ -120, 90 },
			{ 0, 90 },
			{ 120, 90 },
			{ 240, 90 },
			{ -175, 45 }, -- the streets along the strips
			{ 175, 45 },
			{ -80, -90 }, -- the second street
			{ 80, -90 },
			{ -230, -90 },
			{ 230, -90 },
			{ 0, -45 }, -- the avenue
			{ 0, -170 },
			{ -110, -15 }, -- the plaza
			{ -175, 0 }, -- the streets along the strips
			{ 175, 0 },
		},
		-- Loose spots (a random prop from Config.Props.LooseSpotTypes): roofs, the skybridge, a few lots.
		Props = {
			{ -TOWER.X, TOWER.Z, TOWER_ROOF }, -- the tower roofs
			{ TOWER.X, TOWER.Z, TOWER_ROOF },
			{ 0, TOWER.Z, BRIDGE_Y }, -- the skybridge
			{ -30, -62, 2 * STOREY + 0.6 }, -- the cafe's roof
			{ -108, -210, DEPT_ROOF }, -- the department store's roof
			{ 142, -128, HOTEL_ROOF }, -- the hotel's roof
			{ 90, -120 }, -- by the courthouse
			{ 230, -160, SITE.Deck }, -- the building site's first deck
			{ -232, -110 }, -- by the jail
		},
		-- Spots that always get the prop that belongs there (owner, 2026-10-28: "add more throwable item also match
		-- that found area").
		TypedProps = {
			-- Trash cans along the streets: the main street, the plaza, the shops, the site's fence, the hotel.
			{ At = { -30, 70 }, Type = "TrashCan" },
			{ At = { 30, 70 }, Type = "TrashCan" },
			{ At = { -125, -70 }, Type = "TrashCan" },
			{ At = { -132, -102 }, Type = "TrashCan" },
			{ At = { 206, -103 }, Type = "TrashCan" },
			{ At = { 120, -110 }, Type = "TrashCan" },
			-- The towers: plants in the lobbies, office chairs upstairs.
			{ At = { -38, 28 }, Type = "PottedPlant" },
			{ At = { 38, 28 }, Type = "PottedPlant" },
			{ At = { -34, 30, 2 * STOREY }, Type = "OfficeChair" },
			{ At = { 34, 30, 3 * STOREY }, Type = "OfficeChair" },
			-- The ramen shop and the yokocho: stools, paper lanterns, trash cans in the lane.
			{ At = { -136, 63 }, Type = "Stool" },
			{ At = { -112, 63 }, Type = "Stool" },
			{ At = { -121, 56, STOREY }, Type = "PaperLantern" },
			{ At = { -100, 22 }, Type = "TrashCan" },
			{ At = { -140, 22 }, Type = "TrashCan" },
			{ At = { -120, 22 }, Type = "PaperLantern" },
			{ At = { -96.5, 30 }, Type = "Stool" },
			-- The pachinko parlor's stools, the cafe's chairs and plant.
			{ At = { -86, 65 }, Type = "Stool" },
			{ At = { -76, 65 }, Type = "Stool" },
			{ At = { -33, -60 }, Type = "Chair" },
			{ At = { -35, -60, STOREY }, Type = "Chair" },
			{ At = { -28, -45, STOREY }, Type = "PottedPlant" },
			-- The karaoke booths' speakers; the mart's basket and trash cans.
			{ At = { 85.6, 50, STOREY }, Type = "Speaker" },
			{ At = { 77.2, 64, 2 * STOREY }, Type = "Speaker" },
			{ At = { 120, 46 }, Type = "ShoppingBasket" },
			{ At = { 110, 35 }, Type = "TrashCan" },
			{ At = { 140, 35 }, Type = "TrashCan" },
			-- The car park: tyres and cones; the gas station's cans; the temple's lantern; the arcade's stools.
			{ At = { 95, 10, CARPARK.Storey }, Type = "Tire" },
			{ At = { 130, -2, 2 * CARPARK.Storey }, Type = "Tire" },
			{ At = { 90, -2 }, Type = "TrafficCone" },
			{ At = { 125, -10, CARPARK_ROOF }, Type = "TrafficCone" },
			{ At = { 36, -6 }, Type = "GasCan" },
			{ At = { 52, -6 }, Type = "GasCan" },
			{ At = { 48, -62 }, Type = "PaperLantern" },
			{ At = { 100, -50 }, Type = "Stool" },
			{ At = { 115, -50 }, Type = "Stool" },
			-- The mall's mannequin and basket; the bowling alley's balls and a pin.
			{ At = { -250, 0, 11 }, Type = "Mannequin" },
			{ At = { -245, 45 }, Type = "ShoppingBasket" },
			{ At = { -213, -48 }, Type = "BowlingBall" },
			{ At = { -208, -60, 1 }, Type = "BowlingBall" },
			{ At = { -256, -48 }, Type = "BowlingPin" },
			-- The apartments' TV; the shops' books, screen and basket; the department store.
			{ At = { 226, 50, STOREY }, Type = "TV" },
			{ At = { -150, -110 }, Type = "BookStack" },
			{ At = { -117, -110 }, Type = "Monitor" },
			{ At = { -87, -110 }, Type = "ShoppingBasket" },
			{ At = { -105, -175, STOREY }, Type = "Mannequin" },
			{ At = { -100, -195 }, Type = "ShoppingBasket" },
			-- Crates in the back lot; chairs in the jail's office, the comedy club and the court; the club's speaker.
			{ At = { -58, -136 }, Type = "Crate" },
			{ At = { -126, -137 }, Type = "Crate" },
			{ At = { -232, -140, STOREY }, Type = "Chair" },
			{ At = { -245, -204 }, Type = "Chair" },
			{ At = { -225, -204 }, Type = "Chair" },
			{ At = { -250, -211, 1.5 }, Type = "Speaker" },
			{ At = { 45, -152 }, Type = "Chair" },
			-- The fire station's extinguisher and toolbox; the hotel's suitcases; the mansion's TV.
			{ At = { 60, -201 }, Type = "FireExtinguisher" },
			{ At = { 70, -212 }, Type = "Toolbox" },
			{ At = { 120, -128 }, Type = "Suitcase" },
			{ At = { 114, -141.2, 2 * STOREY }, Type = "Suitcase" },
			{ At = { 130, -184 }, Type = "TV" },
			-- The building site: cinderblocks and cones.
			{ At = { 236, -128 }, Type = "Cinderblock" },
			{ At = { 232, -198 }, Type = "Cinderblock" },
			{ At = { 220, -113 }, Type = "TrafficCone" },
			{ At = { 250, -113 }, Type = "TrafficCone" },
		},
		Explosives = {
			{ 44, -20 }, -- by the gas station's pumps
			{ -140, -90 },
			{ 0, 45 }, -- under the skybridge
			{ -194, -205 },
			{ 55, -173 }, -- between the courthouse and the fire station
			{ 214, -214 }, -- the building site
		},
		Structures = {
			{ Type = "VendingMachine", At = { -80, 76.5 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { 81, 76.5 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { 95, 35 }, Yaw = 0 },
			{ Type = "IceMachine", At = { 155, 35 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { -60, 6 }, Yaw = 0 },
			{ Type = "WreckedCar", At = { -25, -86 }, Yaw = 90 },
			{ Type = "WreckedCar", At = { -175, -40 }, Yaw = 0 },
			{ Type = "RoadBarrierStack", At = { 175, -150 }, Yaw = 0 },
		},
	}),
} :: { [string]: Arena.Contents }

function Layout.killY(): number
	return Arena.killY(Layout.Platforms)
end

---------------------------------------------------------------------------------------------------------------------
-- Pieces (positions from the district's centre)
---------------------------------------------------------------------------------------------------------------------

-- Paint on the ground: a flat, walk-through strip `size` (X, Z) at `y` (surfaces 0.05, lines 0.12).
local function paint(name: string, at: { number }, size: { number }, color: string, material: string?, y: number?)
	B.part({
		Name = name,
		Size = { size[1], if y and y > 0.1 then 0.02 else 0.1, size[2] },
		Position = { at[1], y or 0.05, at[2] },
		Color = color,
		Material = material or "SmoothPlastic",
		CanCollide = false,
		CastShadow = false,
	})
end

-- A world point `lx` to the right, `ly` up and `lz` ahead of `at` for something turned `yaw` (its length along Z).
local function placer(at: { number }, yaw: number, base: number?): (lx: number, ly: number, lz: number) -> { number }
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	local y = base or 0
	return function(lx: number, ly: number, lz: number): { number }
		return { at[1] + lx * c + lz * s, y + ly, at[2] - lx * s + lz * c }
	end
end

-- An upright cylinder (a pole, a can, a disc when short) standing on `y`.
local function upright(
	name: string,
	at: { number },
	y: number,
	height: number,
	diameter: number,
	color: string,
	material: string,
	collide: boolean?
): any
	return B.part({
		Name = name,
		Size = { height, diameter, diameter },
		Position = { at[1], y + height / 2, at[2] },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = color,
		Material = material,
		CanCollide = collide ~= false,
	})
end

-- A flat, walk-through panel just outside the face `face` ("+X" / "-X" / "+Z" / "-Z") of a box at `at` sized `size`
-- (X, Z): `along` across the face, `y` its middle, `w` × `h`.
local function panel(
	name: string,
	at: { number },
	size: { number },
	face: string,
	along: number,
	y: number,
	w: number,
	h: number,
	color: string,
	material: string?
): any
	local axis = if string.sub(face, 2) == "X" then 1 else 2
	local sign = if string.sub(face, 1, 1) == "+" then 1 else -1
	local out = sign * (size[axis] / 2 + 0.08)
	return B.part({
		Name = name,
		Size = if axis == 1 then { 0.1, h, w } else { w, h, 0.1 },
		Position = if axis == 1 then { at[1] + out, y, at[2] + along } else { at[1] + along, y, at[2] + out },
		Color = color,
		Material = material or "SmoothPlastic",
		Transparency = if material == "Glass" then 0.2 else nil,
		CanCollide = false,
		CastShadow = false,
	})
end

-- A sign board on a face of a building at `at` sized `size` (X, Z), facing out from it.
local function faceSign(
	at: { number },
	size: { number },
	face: string,
	along: number,
	y: number,
	w: number,
	h: number,
	key: string,
	color: string,
	text: string,
	glow: boolean?
)
	local axis = if string.sub(face, 2) == "X" then 1 else 2
	local sign = if string.sub(face, 1, 1) == "+" then 1 else -1
	local out = sign * (size[axis] / 2 + 0.25)
	local facing = if face == "+X"
		then "East"
		elseif face == "-X" then "West"
		elseif face == "+Z" then "North"
		else "South"
	B.sign({
		Name = "Sign",
		Size = { w, h, 0.3 },
		Position = if axis == 1 then { at[1] + out, y, at[2] + along } else { at[1] + along, y, at[2] + out },
		Rotation = B.yaw(facing),
		Color = color,
		Material = "SmoothPlastic",
		Key = key,
		TextColor = text,
		Glow = glow,
		CanCollide = false,
	})
end

-- A ladder (a climbable truss) standing on `y`, `height` tall (even).
local function ladder(at: { number }, y: number, height: number)
	B.truss({
		Name = "Ladder",
		Size = { 2, height, 2 },
		Position = { at[1], y + height / 2, at[2] },
		Color = "MetalDark",
		Material = "Metal",
	})
end

-- A breakable concrete block wall (a Japanese lot wall) from `a` to `b` (along X or Z), 4 high, in pieces.
local function blockWall(a: { number }, b: { number })
	local alongX = math.abs(b[1] - a[1]) >= math.abs(b[2] - a[2])
	local length = if alongX then math.abs(b[1] - a[1]) else math.abs(b[2] - a[2])
	local count = math.max(1, math.ceil(length / 10))
	local step = length / count
	for index = 1, count do
		local t = (index - 0.5) / count
		B.part({
			Name = "BlockWall",
			Size = if alongX then { step, 4, 1 } else { 1, 4, step },
			Position = { a[1] + (b[1] - a[1]) * t, 2, a[2] + (b[2] - a[2]) * t },
			Color = "ConcreteLight",
			Material = "Concrete",
			CastShadow = true,
			Tags = BREAKABLE,
		})
	end
end

-- A parked car (solid: you can be knocked into it or stand on it), its length along Z turned `yaw`, on `y`; life-size
-- beside an avatar (12 long, 6 wide, 5 high).
local CAR = 1.42 -- the car's scale from its 8.4-long base model
local function car(name: string, at: { number }, yaw: number, color: string, y: number?)
	local base = placer(at, yaw, y)
	local function place(lx: number, ly: number, lz: number): { number }
		return base(lx * CAR, ly * CAR, lz * CAR)
	end
	local function size(x: number, yy: number, z: number): { number }
		return { x * CAR, yy * CAR, z * CAR }
	end
	local turn = { 0, yaw, 0 }
	B.model(name, function()
		B.part({
			Name = "Body",
			Size = size(4.4, 1.5, 8.4),
			Position = place(0, 1.25, 0),
			Rotation = turn,
			Color = color,
		})
		B.part({
			Name = "Cabin",
			Size = size(4, 1.5, 4.6),
			Position = place(0, 2.75, -0.3),
			Rotation = turn,
			Color = "Black",
			Material = "Glass",
			Transparency = 0.25,
		})
		B.part({
			Name = "Roof",
			Size = size(4, 0.2, 4),
			Position = place(0, 3.6, -0.3),
			Rotation = turn,
			Color = color,
			CanCollide = false,
		})
		for _, lx in { -2.1, 2.1 } do
			for _, lz in { -2.8, 2.8 } do
				B.part({
					Name = "Wheel",
					Size = size(0.8, 1.6, 1.6),
					Position = place(lx, 0.8, lz),
					Rotation = turn,
					Shape = "Cylinder",
					Color = "Black",
					CanCollide = false,
				})
			end
		end
		for _, lz in { -4.25, 4.25 } do
			for _, lx in { -1.5, 1.5 } do
				B.part({
					Name = if lz > 0 then "Headlight" else "TailLight",
					Size = size(0.9, 0.4, 0.1),
					Position = place(lx, 1.6, lz),
					Rotation = turn,
					Color = if lz > 0 then "WarmLight" else "Red",
					Material = "Neon",
					CanCollide = false,
				})
			end
		end
	end)
end

-- A parked bicycle (decor, walk-through), its length along Z turned `yaw`: two wheels, a frame, a seat, a handlebar.
local function bike(at: { number }, yaw: number, color: string)
	local place = placer(at, yaw)
	local turn = { 0, yaw, 0 }
	B.model("Bicycle", function()
		for _, lz in { -1.1, 1.1 } do
			B.part({
				Name = "Wheel",
				Size = { 0.15, 2, 2 },
				Position = place(0, 1, lz),
				Rotation = turn,
				Shape = "Cylinder",
				Color = "Black",
				CanCollide = false,
			})
		end
		B.part({
			Name = "Frame",
			Size = { 0.15, 0.15, 2.4 },
			Position = place(0, 1.5, 0),
			Rotation = turn,
			Color = color,
			Material = "Metal",
			CanCollide = false,
		})
		B.part({
			Name = "Seat",
			Size = { 0.4, 0.15, 0.7 },
			Position = place(0, 2.1, -0.6),
			Rotation = turn,
			Color = "Black",
			CanCollide = false,
		})
		B.part({
			Name = "Handlebar",
			Size = { 1.2, 0.12, 0.12 },
			Position = place(0, 2.2, 1),
			Rotation = turn,
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		})
	end)
end

-- A tree on `y`, about 18 tall: a trunk (solid) and two balls of leaves (`leaf`: green, or pink for a cherry tree).
local function tree(name: string, at: { number }, leaf: string, y: number?)
	local base = y or 0
	B.model(name, function()
		upright("Trunk", at, base, 8.5, 1.4, "WoodDark", "Wood")
		B.part({
			Name = "Leaves",
			Size = { 11, 9.4, 11 },
			Position = { at[1], base + 11, at[2] },
			Shape = "Ball",
			Color = leaf,
			Material = "LeafyGrass",
			CanCollide = false,
		})
		B.part({
			Name = "LeavesTop",
			Size = { 7.5, 6.8, 7.5 },
			Position = { at[1] + 1, base + 14.6, at[2] - 0.7 },
			Shape = "Ball",
			Color = leaf,
			Material = "LeafyGrass",
			CanCollide = false,
		})
	end)
end

-- A street tree in an iron-edged pit.
local function streetTree(at: { number })
	paint("TreePit", at, { 3.4, 3.4 }, "Soil", "Ground", 0.07)
	tree("StreetTree", at, "Leaf")
end

-- A bare, dead tree (the graveyard): a dark trunk and three crooked branches.
local function deadTree(at: { number })
	B.model("DeadTree", function()
		upright("Trunk", at, 0, 11, 1.1, "WoodDark", "Wood")
		for index, branch in { { 35, 0, 8.5 }, { -40, 120, 9.6 }, { 30, 240, 7.4 } } do
			local c, s = math.cos(math.rad(branch[2])), math.sin(math.rad(branch[2]))
			B.part({
				Name = `Branch{index}`,
				Size = { 0.45, 5, 0.45 },
				Position = { at[1] + c * 1.7, branch[3] + 1.8, at[2] + s * 1.7 },
				Rotation = { branch[1] * s, 0, -branch[1] * c },
				Color = "WoodDark",
				Material = "Wood",
				CanCollide = false,
			})
		end
	end)
end

-- A bench turned `yaw` (unturned, you sit facing +Z) on `y`: a wood seat and back on iron legs.
local function bench(at: { number }, yaw: number, y: number?)
	local place = placer(at, yaw, y)
	local turn = { 0, yaw, 0 }
	B.model("Bench", function()
		B.part({
			Name = "Seat",
			Size = { 5, 0.3, 1.4 },
			Position = place(0, 1.4, 0),
			Rotation = turn,
			Color = "Wood",
			Material = "WoodPlanks",
		})
		B.part({
			Name = "Back",
			Size = { 5, 1.2, 0.25 },
			Position = place(0, 2.3, -0.65),
			Rotation = turn,
			Color = "Wood",
			Material = "WoodPlanks",
		})
		for _, lx in { -2, 2 } do
			B.part({
				Name = "Leg",
				Size = { 0.3, 1.3, 1.2 },
				Position = place(lx, 0.65, 0),
				Rotation = turn,
				Color = "MetalDark",
				Material = "Metal",
			})
		end
	end)
end

-- A small round table on a post (decor, solid), on `y`.
local function smallTable(at: { number }, y: number?)
	local base = y or 0
	B.model("Table", function()
		upright("Post", at, base, 2.6, 0.4, "MetalDark", "Metal")
		upright("Top", at, base + 2.6, 0.2, 2.6, "OffWhite", "SmoothPlastic")
	end)
end

-- A vending machine (decor, solid), its front toward `yaw`: a coloured body, a lit drinks window, a slot.
local function vending(at: { number }, yaw: number, color: string)
	local place = placer(at, yaw)
	local turn = { 0, yaw, 0 }
	B.model("Vending", function()
		B.part({ Name = "Body", Size = { 3, 6, 2.4 }, Position = place(0, 3, 0), Rotation = turn, Color = color })
		B.part({
			Name = "Drinks",
			Size = { 2.4, 2.6, 0.1 },
			Position = place(0, 4.2, 1.22),
			Rotation = turn,
			Color = "WarmLight",
			Material = "Neon",
			Transparency = 0.3,
			CanCollide = false,
		})
		B.part({
			Name = "Slot",
			Size = { 2, 0.6, 0.1 },
			Position = place(0, 1, 1.22),
			Rotation = turn,
			Color = "Black",
			CanCollide = false,
		})
	end)
end

-- A row of `count` vending machines from `start` along +X (3.2 apart), facing `yaw`.
local function vendingRow(start: { number }, count: number, yaw: number)
	local colors = { "Red", "OffWhite", "CityBlue", "Bottle" }
	for index = 1, count do
		vending({ start[1] + (index - 1) * 3.2, start[2] }, yaw, colors[(index - 1) % #colors + 1])
	end
end

-- A concrete planter (1.4 high) with a tree in it.
local function planterTree(at: { number })
	Pieces.block("Planter", at, { 7, 1.4, 7 }, "ConcreteDark", "Concrete")
	tree("PlanterTree", at, "Leaf", 1.4)
end

-- An air-conditioner box (solid) standing on `y`, its fan on top.
local function acUnit(at: { number }, y: number)
	Pieces.block("ACUnit", at, { 3, 2, 2.4 }, "OffWhite", "Metal", y)
	upright("ACFan", at, y + 2, 0.15, 1.8, "MetalDark", "Metal", false)
end

-- A rooftop water tank on four legs (solid), standing on `y`.
local function waterTank(at: { number }, y: number)
	B.model("WaterTank", function()
		for _, dx in { -1.6, 1.6 } do
			for _, dz in { -1.6, 1.6 } do
				Pieces.column("Leg", { at[1] + dx, at[2] + dz }, y, y + 3, 0.3, "MetalDark", "Metal")
			end
		end
		upright("Tank", at, y + 3, 4, 4.4, "CityBlue", "Metal")
		upright("Lid", at, y + 7, 0.4, 4.8, "MetalDark", "Metal", false)
	end)
end

-- A concrete utility pole (solid, 20 tall) with a crossbar and, when `transformer`, a grey transformer can.
local function utilityPole(at: { number }, transformer: boolean)
	B.model("UtilityPole", function()
		upright("Pole", at, 0, 20, 1.1, "ConcreteLight", "Concrete")
		B.part({
			Name = "Crossbar",
			Size = { 0.3, 0.3, 4.4 },
			Position = { at[1], 19.3, at[2] },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		if transformer then
			upright("Transformer", { at[1] + 1.3, at[2] }, 14, 2.6, 1.6, "Metal", "Metal", false)
		end
	end)
end

-- Three power lines from pole `a` to pole `b` (x, z), walk-through.
local function wires(a: { number }, b: { number })
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local length = math.sqrt(dx * dx + dz * dz)
	for _, wire in { { 19.5, 1.8 }, { 19.5, -1.8 }, { 18.2, 0 } } do
		local ox, oz = -dz / length * wire[2], dx / length * wire[2]
		B.part({
			Name = "Wire",
			Size = { 0.08, 0.08, length },
			Position = { (a[1] + b[1]) / 2 + ox, wire[1], (a[2] + b[2]) / 2 + oz },
			Rotation = { 0, math.deg(math.atan2(dx, dz)), 0 },
			Color = "Black",
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- The roof furniture of a building `size` (X, Z) at `at` whose roof is at `y`: AC units and, when `tank`, a water tank,
-- along its back half (clear of the roof's middle, where props land).
local function roofKit(at: { number }, size: { number }, y: number, tank: boolean)
	local back = at[2] + size[2] / 4
	acUnit({ at[1] - size[1] / 3, back }, y)
	acUnit({ at[1] + size[1] / 3, back }, y)
	if tank then
		waterTank({ at[1] + size[1] / 3, at[2] - size[2] / 4 }, y)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Inside (owner, 2026-10-28: "literally include inside structure too")
---------------------------------------------------------------------------------------------------------------------

-- An inside wall (it breaks) from `a` to `b` (x, z; along X or Z) standing on `y`, `height` tall, with a doorway 4 wide
-- at each distance in `doors` (from `a`); pieces at most 16 wide (Config.Structures.Walls.MaxPiece).
local function partition(
	a: { number },
	b: { number },
	y: number,
	height: number,
	doors: { number }?,
	color: string?,
	material: string?
)
	local alongX = math.abs(b[1] - a[1]) >= math.abs(b[2] - a[2])
	local length = if alongX then math.abs(b[1] - a[1]) else math.abs(b[2] - a[2])
	local direction = if alongX then math.sign(b[1] - a[1]) else math.sign(b[2] - a[2])
	local cuts = table.clone(doors or {})
	table.sort(cuts)
	local from = 0
	local function run(to: number)
		local span = to - from
		if span > 0.05 then
			local count = math.ceil(span / 16 - 1e-6)
			for index = 1, count do
				local middle = from + (index - 0.5) * span / count
				B.part({
					Name = "Partition",
					Size = if alongX then { span / count, height, 0.4 } else { 0.4, height, span / count },
					Position = if alongX
						then { a[1] + direction * middle, y + height / 2, a[2] }
						else { a[1], y + height / 2, a[2] + direction * middle },
					Color = color or "OffWhite",
					Material = material or "SmoothPlastic",
					CastShadow = true,
					Tags = BREAKABLE,
				})
			end
		end
	end
	for _, door in cuts do
		run(door - 2)
		from = door + 2
	end
	run(length)
end

-- An office desk (solid) with a screen on it, its long side along X (yaw 0) or Z (yaw 90), on `y`.
local function desk(at: { number }, y: number, yaw: number)
	Pieces.block("Desk", at, { 5, 2.6, 2.4 }, "WoodMid", "Wood", y, yaw)
	B.part({
		Name = "Screen",
		Size = { 1.8, 1.2, 0.15 },
		Position = { at[1], y + 3.2, at[2] },
		Rotation = { 0, yaw, 0 },
		Color = "Black",
		CanCollide = false,
	})
end

-- A bed (a frame you can stand on, a blanket over it) on `y`, its length along Z (yaw 0) or X (yaw 90).
local function bed(at: { number }, y: number, yaw: number, blanket: string)
	Pieces.block("Bed", at, { 4.4, 1.6, 7 }, "OffWhite", "Fabric", y, yaw)
	Pieces.block("Blanket", at, { 4.5, 0.2, 4.8 }, blanket, "Fabric", y + 1.6, yaw).CanCollide = false
end

-- A sofa (a seat and a back, both solid) on `y`, turned `yaw` (unturned, you sit facing +Z).
local function sofa(at: { number }, y: number, yaw: number, color: string)
	local place = placer(at, yaw, y)
	B.part({
		Name = "Sofa",
		Size = { 6, 1.4, 2.2 },
		Position = place(0, 0.7, 0),
		Rotation = { 0, yaw, 0 },
		Color = color,
	})
	B.part({
		Name = "SofaBack",
		Size = { 6, 1.6, 0.6 },
		Position = place(0, 2.2, -0.8),
		Rotation = { 0, yaw, 0 },
		Color = color,
		Material = "Fabric",
	})
end

-- A potted plant (a pot and a ball of leaves) on `y`.
local function pottedPlant(at: { number }, y: number)
	upright("Pot", at, y, 1.6, 1.6, "ConcreteDark", "Concrete")
	B.part({
		Name = "Plant",
		Size = { 2.6, 2.6, 2.6 },
		Position = { at[1], y + 2.8, at[2] },
		Shape = "Ball",
		Color = "Leaf",
		Material = "LeafyGrass",
		CanCollide = false,
	})
end

---------------------------------------------------------------------------------------------------------------------
-- The finish (owner, 2026-10-28: "add more overall entire detail then polish")
---------------------------------------------------------------------------------------------------------------------

-- The ledge colour of the buildings that don't take the default dark concrete.
local TRIM: { [string]: string } = {
	TowerWest = "OffWhite",
	TowerEast = "OffWhite",
	Ramen = "Cream",
	YokochoNorth = "WoodMid",
	YokochoSouth = "WoodMid",
	Jail = "Purple",
	ComedyClub = "Black",
	Courthouse = "Concrete",
	Arcade = "NeonPink",
	Pachinko = "NeonTeal",
	Hotel = "WoodMid",
	Temple = "WoodDark",
}

-- Wall and floor materials other than plain concrete (owner, 2026-10-28: "still look less detail and blocky").
local FINISH: { [string]: { Wall: string?, Floor: string? } } = {
	ApartmentsNorth = { Wall = "Plaster" },
	ApartmentsSouth = { Wall = "Plaster" },
	Hotel = { Wall = "Plaster" },
	Mansion = { Wall = "Plaster" },
	Cafe = { Wall = "Plaster" },
	Koban = { Wall = "Plaster" },
	Karaoke = { Wall = "Plaster" },
	Mart = { Floor = "CeramicTiles" },
	GasKiosk = { Floor = "CeramicTiles" },
	FireStation = { Wall = "Brick" },
	DeptStore = { Wall = "Limestone" },
	Arcade = { Floor = "Carpet" },
}

--[[
	A Rooms building with the finish every building here gets: a sill under every window, a column standing out at
	each corner, a ledge round it at every floor line and a cornice at the roof line (all walk-through, so they never
	snag anyone), a light under every ceiling clear of the stair well, and its wall and floor materials (FINISH). The
	open car park keeps its bare decks. Its parts go into the building's model.
]]
local function building(spec: Rooms.Spec): any
	local trim = TRIM[spec.Name] or "ConcreteDark"
	local finish = FINISH[spec.Name]
	if finish then
		spec.Material = spec.Material or finish.Wall
		spec.FloorMaterial = finish.Floor or spec.FloorMaterial
	end
	spec.Sill = spec.Sill or (if trim == "ConcreteDark" then "ConcreteLight" else trim)
	local model = Rooms.building(spec)
	local sx, sz = spec.Size[1], spec.Size[2]
	local cx, cz = spec.At[1], spec.At[2]
	local h = spec.Storey
	local function keep(part: any)
		part.Parent = model
	end
	local top = spec.Floors * h + (if spec.Roof then 0.6 else 0)
	for _, sxSign in { -1, 1 } do
		for _, szSign in { -1, 1 } do
			keep(B.part({
				Name = "CornerColumn",
				Size = { 1.2, top, 1.2 },
				Position = { cx + sxSign * (sx / 2 - 0.3), top / 2, cz + szSign * (sz / 2 - 0.3) },
				Color = trim,
				Material = if string.sub(trim, 1, 4) == "Neon" then "Neon" else "Concrete",
				CanCollide = false,
			}))
		end
	end
	local function ring(name: string, y: number, height: number, out: number)
		for _, side in
			{
				{ { 0, sz / 2 + out / 2 }, { sx + 2 * out, height, out } },
				{ { 0, -sz / 2 - out / 2 }, { sx + 2 * out, height, out } },
				{ { sx / 2 + out / 2, 0 }, { out, height, sz } },
				{ { -sx / 2 - out / 2, 0 }, { out, height, sz } },
			}
		do
			keep(B.part({
				Name = name,
				Size = side[2],
				Position = { cx + side[1][1], y, cz + side[1][2] },
				Color = trim,
				Material = if string.sub(trim, 1, 4) == "Neon" then "Neon" else "Concrete",
				CanCollide = false,
			}))
		end
	end
	if spec.Name ~= "CarPark" then
		for floor = 1, spec.Floors - 1 do
			ring("Ledge", floor * h - 0.15, 0.5, 0.3)
		end
		if spec.Roof then
			ring("Cornice", spec.Floors * h + 0.3, 0.9, 0.45)
		end
	end
	-- Ceiling lights: one strip in a small room, two in a big one, never over the stair well.
	local well: { number }? = nil
	local stair = spec.Stair
	if stair then
		local run = h * 1.6
		well = if stair.Along == "X"
			then { stair.At[1] - run / 2, stair.At[1] + run / 2, stair.At[2] - stair.Width, stair.At[2] + stair.Width }
			else {
				stair.At[1] - stair.Width,
				stair.At[1] + stair.Width,
				stair.At[2] - run / 2,
				stair.At[2] + run / 2,
			}
	end
	local big = sx * sz >= 900
	local candidates = if big
		then { { -sx / 4, 0 }, { sx / 4, 0 }, { 0, -sz / 4 }, { 0, sz / 4 }, { 0, 0 } }
		else { { 0, 0 }, { -sx / 4, 0 }, { sx / 4, 0 }, { 0, -sz / 4 }, { 0, sz / 4 } }
	local spots = {}
	for _, spot in candidates do
		local w = well
		local inWell = w ~= nil
			and spot[1] > w[1] - 3
			and spot[1] < w[2] + 3
			and spot[2] > w[3] - 3
			and spot[2] < w[4] + 3
		if #spots < (if big then 2 else 1) and not inWell then
			table.insert(spots, spot)
		end
	end
	local length = math.min(math.max(sx, sz) * 0.3, 14)
	for floor = 1, spec.Floors do
		local ceiling = floor * h - (if floor < spec.Floors then 0.5 else 0)
		for _, spot in spots do
			keep(B.part({
				Name = "CeilingLight",
				Size = if sx >= sz then { length, 0.12, 1.2 } else { 1.2, 0.12, length },
				Position = { cx + spot[1], ceiling - 0.08, cz + spot[2] },
				Color = "OffWhite",
				Material = "Neon",
				CanCollide = false,
			}))
		end
	end
	return model
end

-- An outdoor air-conditioner unit on a wall: a box standing out from the wall's face `face` ("+X" / "-X" / "+Z" /
-- "-Z", the side it faces) at `at` (x, z on the wall's plane), `y` its middle, a fan grille on its front.
local function wallAC(at: { number }, face: string, y: number)
	local alongX = string.sub(face, 2) == "Z"
	local sign = if string.sub(face, 1, 1) == "+" then 1 else -1
	local out = sign * 0.6
	local box = if alongX then { 2.6, 1.8, 1.2 } else { 1.2, 1.8, 2.6 }
	local spot = if alongX then { at[1], y, at[2] + out } else { at[1] + out, y, at[2] }
	B.part({ Name = "WallAC", Size = box, Position = spot, Color = "OffWhite", Material = "Metal" })
	B.part({
		Name = "WallACFan",
		Size = { 0.1, 1.3, 1.3 },
		Position = if alongX
			then { spot[1] - 0.4, y, spot[3] + sign * 0.62 }
			else { spot[1] + sign * 0.62, y, spot[3] - 0.4 },
		Rotation = if alongX then { 0, 90, 0 } else nil,
		Shape = "Cylinder",
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
end

-- A roof antenna (a mast and two crossbars) standing on `y`.
local function antenna(at: { number }, y: number)
	upright("Antenna", at, y, 10, 0.3, "Metal", "Metal", false)
	for index, bar in { { 7, 3 }, { 9, 2 } } do
		B.part({
			Name = `AntennaBar{index}`,
			Size = { bar[2], 0.12, 0.12 },
			Position = { at[1], y + bar[1], at[2] },
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		})
	end
end

-- A satellite dish on a short post on `y`, tilted up toward the south.
local function dish(at: { number }, y: number)
	upright("DishPost", at, y, 1.6, 0.25, "MetalDark", "Metal", false)
	B.part({
		Name = "Dish",
		Size = { 0.2, 2.4, 2.4 },
		Position = { at[1], y + 2, at[2] - 0.3 },
		Rotation = { 0, 90, -35 },
		Shape = "Cylinder",
		Color = "OffWhite",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
end

-- A traffic signal on its pole at `at` (x, z): an arm out over the street along Z (`armDir` ±1), a horizontal box of
-- three lights facing along X (`faceDir` ±1).
local function trafficLight(at: { number }, armDir: number, faceDir: number)
	B.model("TrafficLight", function()
		upright("SignalPole", at, 0, 11, 0.45, "OffWhite", "Metal")
		B.part({
			Name = "SignalArm",
			Size = { 0.3, 0.3, 5 },
			Position = { at[1], 10.6, at[2] + armDir * 2.5 },
			Color = "OffWhite",
			Material = "Metal",
			CanCollide = false,
		})
		B.part({
			Name = "SignalBox",
			Size = { 0.9, 1.1, 3.4 },
			Position = { at[1], 10.6, at[2] + armDir * 4.2 },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		for index, color in { "Lawn", "LaneYellow", "Red" } do
			B.part({
				Name = "SignalLamp",
				Size = { 0.1, 0.8, 0.8 },
				Position = { at[1] + faceDir * 0.5, 10.6, at[2] + armDir * (4.2 + (index - 2) * 1.05) },
				Shape = "Cylinder",
				Color = color,
				Material = "Neon",
				CanCollide = false,
			})
		end
	end)
end

-- A round road sign (a red ring round a blue disc) on a pole at `at`, facing along X, or along Z when `alongZ`.
local function roadSign(at: { number }, alongZ: boolean)
	upright("SignPole", at, 0, 8, 0.25, "Metal", "Metal")
	for _, disc in { { 2.2, "Red", 0 }, { 1.8, "CityBlue", 0.06 } } do
		B.part({
			Name = "RoadSign",
			Size = { 0.08, disc[1] :: number, disc[1] :: number },
			Position = if alongZ
				then { at[1], 7.4, at[2] + (disc[3] :: number) }
				else { at[1] + (disc[3] :: number), 7.4, at[2] },
			Rotation = if alongZ then { 0, 90, 0 } else nil,
			Shape = "Cylinder",
			Color = disc[2] :: string,
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
end

-- A yellow fire hydrant standpipe, a red post box, a nobori banner on its pole.
local function hydrant(at: { number })
	upright("Hydrant", at, 0, 2.4, 0.8, "LaneYellow", "Metal")
	upright("HydrantCap", at, 2.4, 0.3, 1, "Red", "Metal", false)
end

local function postBox(at: { number })
	Pieces.block("PostBox", at, { 1.6, 3.6, 1.6 }, "Red", "Metal")
	upright("PostBoxTop", at, 3.6, 0.5, 1.7, "Red", "Metal", false)
end

local function banner(at: { number }, color: string)
	upright("BannerPole", at, 0, 9, 0.15, "Metal", "Metal", false)
	B.part({
		Name = "Banner",
		Size = { 0.05, 6, 1.4 },
		Position = { at[1] + 0.1, 5, at[2] + 0.8 },
		Color = color,
		Material = "Fabric",
		CanCollide = false,
	})
end

---------------------------------------------------------------------------------------------------------------------
-- Streets
---------------------------------------------------------------------------------------------------------------------

local STREETS_Z = { 90, -90 } -- the streets across (along X)
local STREETS_X = { -175, 0, 175 } -- the streets along Z, from the south edge up to the main street
local GAPS_Z = { { -230, -100 }, { -80, 80 } } -- where those run (between the crossings)
local POLES_X = { -260, -220, -140, -100, -60, 60, 100, 140, 220, 260 }

local function streets()
	local halfX = DISTRICT[1] / 2
	for _, z in STREETS_Z do
		paint("Road", { 0, z }, { DISTRICT[1], ROAD }, "Asphalt", "Asphalt")
	end
	for _, x in STREETS_X do
		for _, gap in GAPS_Z do
			paint("Road", { x, (gap[1] + gap[2]) / 2 }, { ROAD, gap[2] - gap[1] }, "Asphalt", "Asphalt")
		end
	end
	-- Dashed white centre lines, stopping short of the crossings.
	local function nearCrossing(value: number, lines: { number }): boolean
		for _, line in lines do
			if math.abs(value - line) < ROAD / 2 + 4 then
				return true
			end
		end
		return false
	end
	for _, z in STREETS_Z do
		for x = -halfX + 4, halfX - 4, 8 do
			if not nearCrossing(x, STREETS_X) then
				paint("CentreLine", { x, z }, { 4, 0.35 }, "LaneWhite", nil, 0.12)
			end
		end
	end
	for _, x in STREETS_X do
		for _, gap in GAPS_Z do
			for z = gap[1] + 4, gap[2] - 4, 8 do
				paint("CentreLine", { x, z }, { 0.35, 4 }, "LaneWhite", nil, 0.12)
			end
		end
	end
	-- Crosswalks at every crossing: across the street along X (east of the crossing) and across the one along Z (on
	-- the town's side of it).
	for _, cx in STREETS_X do
		for _, cz in STREETS_Z do
			local inward = if cz > 0 then -1 else 1
			for stripe = 0, 4 do
				local across = -ROAD / 2 + 2 + stripe * 4
				paint("Crosswalk", { cx + ROAD / 2 + 2.5, cz + across }, { 4, 1.8 }, "LaneWhite", nil, 0.12)
				paint("Crosswalk", { cx + across, cz + inward * (ROAD / 2 + 2.5) }, { 1.8, 4 }, "LaneWhite", nil, 0.12)
			end
		end
	end
	-- Kerbs along the streets (walk-through, low).
	local function kerb(at: { number }, size: { number })
		B.part({
			Name = "Kerb",
			Size = { size[1], 0.3, size[2] },
			Position = { at[1], 0.15, at[2] },
			Color = "LaneWhite",
			Material = "Concrete",
			CanCollide = false,
			CastShadow = false,
		})
	end
	local segments = { { -280, -185 }, { -165, -10 }, { 10, 165 }, { 185, 280 } }
	for _, z in STREETS_Z do
		for _, edge in { -1, 1 } do
			local kz = z + edge * (ROAD / 2 + 0.25)
			if z > 0 and edge > 0 then
				kerb({ 0, kz }, { DISTRICT[1], 0.5 }) -- the north edge side has no crossings
			else
				for _, segment in segments do
					kerb({ (segment[1] + segment[2]) / 2, kz }, { segment[2] - segment[1], 0.5 })
				end
			end
		end
	end
	for _, x in STREETS_X do
		for _, edge in { -1, 1 } do
			for _, gap in GAPS_Z do
				kerb({ x + edge * (ROAD / 2 + 0.25), (gap[1] + gap[2]) / 2 }, { 0.5, gap[2] - gap[1] })
			end
		end
	end
	-- Utility poles along the pavements of both streets across, wired together.
	for _, z in { 77.5, -77.5 } do
		for index, x in POLES_X do
			utilityPole({ x, z }, index % 3 == 0)
			local nextX = POLES_X[index + 1]
			if nextX then
				wires({ x, z }, { nextX, z })
			end
		end
	end
	-- Street trees along the avenue's pavements.
	for _, x in { -14, 14 } do
		for _, z in { -25, -62 } do
			streetTree({ x, z })
		end
	end
	-- Taxis on the main street, parked cars, bicycles.
	car("Taxi", { -45, 85 }, 90, "LaneYellow")
	car("Taxi", { -60, 85 }, 90, "LaneYellow")
	car("ParkedCar", { 45, 95 }, -90, "OffWhite")
	car("ParkedCar", { 200, -86 }, -90, "CityBlue")
	car("ParkedCar", { -179, -170 }, 0, "Red")
	for index, x in { -150, -147.5, -90, -87.5, -30 } do
		bike({ x, -101.5 }, 90, if index % 2 == 0 then "Red" else "CityBlue")
	end
end

---------------------------------------------------------------------------------------------------------------------
-- The middle: the twin towers, the cafe and plaza, the ramen shop, the mart, the graveyard, the arcade
---------------------------------------------------------------------------------------------------------------------

--[[
	The twin towers either side of the avenue (the owner's reference: Jujutsu Shenanigans' 11-floor towers joined at
	the 9th floor): 40 × 40, eleven storeys you can walk up (switchback ramps to the roof's hatch), a glass lobby on
	the south, a door on the north; a ribbon of glass on every face of every upper storey; on the 9th, a door on the
	avenue side onto the glass skybridge; a ladder up the outside to the roof; a billboard on the south face; AC units
	and a water tank on the roof.
]]
local function twinTowers()
	local half = TOWER.Size / 2
	for index, side in { -1, 1 } do
		local x, z = side * TOWER.X, TOWER.Z
		local inner = if side < 0 then "+X" else "-X" -- the side facing the avenue
		building({
			Name = if side < 0 then "TowerWest" else "TowerEast",
			At = { x, z },
			Size = { TOWER.Size, TOWER.Size },
			Floors = TOWER.Floors,
			Storey = TOWER.Storey,
			Color = if side < 0 then "CityGrey" else "CityBlue",
			FloorColor = "ConcreteLight",
			Openings = {
				{ Face = "-Z", At = 0, Width = 10, Height = DOOR },
				{ Face = "-Z", At = -13, Width = 14, Height = 7.5, Bottom = 0.4, Glass = true },
				{ Face = "-Z", At = 13, Width = 14, Height = 7.5, Bottom = 0.4, Glass = true },
				{ Face = "+Z", At = 0, Width = 10, Height = DOOR },
				{ Face = inner, At = 0, Width = 8, Height = DOOR, Floor = TOWER.BridgeFloor },
			},
			Windows = {
				Faces = { "+X", "-X", "+Z", "-Z" },
				Width = 30,
				Height = 6,
				Sill = 1.5,
				Spacing = 34,
				From = 2,
			},
			Stair = { At = { side * 12, 10 }, Along = "Z", Width = 4 },
			Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
		})
		B.part({
			Name = "EntranceCanopy",
			Size = { 16, 0.4, 5 },
			Position = { x, DOOR + 1, z - half - 2.5 },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		ladder({ x + side * (half + 1), z + half - 3 }, 0, 112) -- past the roof's parapet (+111.8)
		B.sign({
			Name = "Billboard",
			Size = { 32, 14, 0.5 },
			Position = { x, 92, z - half - 0.5 },
			Color = if index == 1 then "Red" else "CityBlue",
			Material = "SmoothPlastic",
			Key = if index == 1 then "Map.Shinjuku.Sign.AdCola" else "Map.Shinjuku.Sign.AdNight",
			TextColor = "OffWhite",
			CanCollide = false,
		})
		acUnit({ x - side * 12, z - 12 }, TOWER_ROOF)
		acUnit({ x - side * 12, z + 12 }, TOWER_ROOF)
		waterTank({ x + side * 10, z - 10 }, TOWER_ROOF)
		-- The lobby: a reception desk on the avenue side, sofas and plants by the glass front.
		Pieces.block("Reception", { x - side * 11, z + 2 }, { 2.4, 3.2, 10 }, "WoodDark", "Wood")
		sofa({ x + side * 6, z - 13 }, 0, 0, "CityBlue")
		sofa({ x - side * 8, z - 13 }, 0, 0, "CityBlue")
		pottedPlant({ x - side * 17, z - 17 }, 0)
		pottedPlant({ x + side * 17, z - 17 }, 0)
		-- Offices on every upper floor: desks along the avenue side (clear of the skybridge's door on the 9th), a
		-- water cooler in the far corner.
		for floor = 2, TOWER.Floors do
			local y = (floor - 1) * TOWER.Storey
			for _, dz in { -14, 10, 16 } do
				desk({ x - side * 12, z + dz }, y, 90)
			end
			desk({ x - side * 4, z - 15 }, y, 0)
			upright("WaterCooler", { x + side * 15, z - 16 }, y, 3.4, 1.2, "CityBlue", "SmoothPlastic")
		end
	end
	-- The skybridge: a steel deck between the 9th floors' doors, glass sides (they break) and a roof.
	local gap = (TOWER.X - TOWER.Size / 2) * 2
	B.model("Skybridge", function()
		Pieces.block("Deck", { 0, TOWER.Z }, { gap, 1, 10 }, "MetalDark", "DiamondPlate", BRIDGE_Y - 1)
		for _, dz in { -4.85, 4.85 } do
			for _, dx in { -gap / 4, gap / 4 } do
				B.part({
					Name = "Glass",
					Size = { gap / 2, 9, 0.3 },
					Position = { dx, BRIDGE_Y + 4.5, TOWER.Z + dz },
					Color = "Glass",
					Material = "Glass",
					Transparency = 0.45,
					Tags = BREAKABLE,
				})
			end
		end
		Pieces.block("Roof", { 0, TOWER.Z }, { gap, 0.4, 10.4 }, "MetalDark", "Metal", BRIDGE_Y + 9)
	end)
end

-- The cafe at the plaza's corner: two storeys and a roof terrace up a switchback stair, a counter and tables, a big
-- glass front onto the plaza, a CAFE sign and an awning.
local function cafe()
	local at, size = CAFE.At, CAFE.Size
	building({
		Name = "Cafe",
		At = at,
		Size = size,
		Floors = 2,
		Storey = STOREY,
		Color = "Cream",
		FloorColor = "Wood",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "+Z", At = 0, Width = 8, Height = DOOR },
			{ Face = "+Z", At = -14, Width = 10, Height = 5.5, Bottom = 1, Glass = true },
			{ Face = "+Z", At = 14, Width = 10, Height = 5.5, Bottom = 1, Glass = true },
			{ Face = "+X", At = 0, Width = 5, Height = DOOR },
		},
		Windows = { Faces = { "-X", "-Z", "+Z", "+X" }, Width = 6, Height = 4, Sill = 2.5, Spacing = 9, From = 2 },
		Stair = { At = { -9, 7 }, Along = "X", Width = 4 },
		Roof = { Color = "Red", Hatch = true, Parapet = true },
	})
	Pieces.block("Counter", { at[1] + 4, at[2] - 13 }, { 18, 3, 2 }, "WoodDark", "Wood")
	Pieces.block("CoffeeMachine", { at[1] + 9, at[2] - 13 }, { 2, 1.6, 1.2 }, "MetalDark", "Metal", 3)
	for _, spot in { { -28, -48 }, { -28, -60 } } do
		smallTable(spot)
	end
	smallTable({ -28, -60 }, STOREY)
	-- Upstairs: a sofa against the back wall, a bookshelf, a second table.
	sofa({ -40, -65.4 }, STOREY, 0, "WoodMid")
	Pieces.block("Bookshelf", { -20.6, -52 }, { 1.2, 5, 8 }, "WoodDark", "Wood", STOREY)
	smallTable({ -40, -60 }, STOREY)
	faceSign(at, size, "+Z", 0, DOOR + 1, 12, 1.4, "Map.Shinjuku.Sign.Cafe", "WoodDark", "Cream")
	B.part({
		Name = "Awning",
		Size = { 16, 0.3, 3 },
		Position = { at[1], DOOR + 0.4, at[2] + size[2] / 2 + 1.5 },
		Rotation = { 12, 0, 0 },
		Color = "Red",
		Material = "Fabric",
		CanCollide = false,
	})
	-- AC units on the roof terrace, clear of its hatch (the west end) and of the middle.
	acUnit({ -24, -40 }, 2 * STOREY + 0.6)
	acUnit({ -24, -65 }, 2 * STOREY + 0.6)
end

-- The plaza west of the avenue: pavers, a fountain, planters, benches.
local function plaza()
	paint("PlazaPavers", { -87.5, -38 }, { 155, 84 }, "ConcreteLight", "Pavement")
	for x = -160, -14, 12 do
		paint("PaverStripe", { x, -38 }, { 0.6, 84 }, "ConcreteDark", "Pavement", 0.12)
	end
	upright("FountainBasin", { -100, -35 }, 0, 1.6, 16, "Concrete", "Concrete")
	upright("FountainWater", { -100, -35 }, 1.45, 0.1, 14.6, "Glass", "Glass", false)
	upright("FountainColumn", { -100, -35 }, 1.6, 3.6, 2, "Concrete", "Concrete")
	upright("FountainBowl", { -100, -35 }, 5.2, 0.6, 6, "Concrete", "Concrete")
	for _, at in { { -150, -70 }, { -150, -6 }, { -80, -6 } } do
		planterTree(at)
	end
	bench({ -105, -72 }, 0)
	bench({ -80, -12 }, 180)
end

-- The ramen shop on the main street: two storeys, the front (curtains over the door, red lanterns, a RAMEN sign and a
-- rooftop sign) onto the street; downstairs a counter with stools, a kitchen and tables, a stair up to an izakaya (low
-- tables on mats, a paper screen that breaks) and on to the roof.
local function ramen()
	local at, size = { -125, 55 }, { 46, 30 }
	local front = at[2] + size[2] / 2
	building({
		Name = "Ramen",
		At = at,
		Size = size,
		Floors = 2,
		Storey = STOREY,
		Color = "Brick",
		Material = "Brick",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "+Z", At = 0, Width = 8, Height = DOOR },
			{ Face = "+Z", At = -14, Width = 10, Height = 5, Bottom = 1.2, Glass = true },
			{ Face = "+Z", At = 14, Width = 10, Height = 5, Bottom = 1.2, Glass = true },
			{ Face = "-Z", At = 19, Width = 5, Height = DOOR },
		},
		Windows = { Faces = { "+Z", "+X", "-X" }, Width = 5, Height = 4, Sill = 2.5, Spacing = 8, From = 2 },
		Stair = { At = { -18, 0 }, Along = "Z", Width = 4 },
		Roof = { Color = "AsphaltDark", Material = "Slate", Hatch = true, Parapet = true },
	})
	Pieces.block("Counter", { at[1] + 3, at[2] - 6 }, { 24, 3.4, 2 }, "Wood", "Wood")
	Pieces.block("Kitchen", { at[1] + 3, at[2] - 12.6 }, { 24, 3.6, 2.4 }, "MetalDark", "Metal")
	for sx = -6, 14, 5 do
		upright("Stool", { at[1] + sx, at[2] - 3.5 }, 0, 2.2, 1.2, "Red", "SmoothPlastic")
	end
	for _, dx in { -6, 18 } do
		smallTable({ at[1] + dx, 63 })
	end
	-- Upstairs, the izakaya: low tables on the mats, a paper screen across the room.
	paint("Tatami", { at[1] + 8, at[2] + 2 }, { 28, 20 }, "Cream", "Fabric", STOREY + 0.06)
	for _, spot in { { -2, 6 }, { 10, 6 }, { -2, -4 }, { 10, -4 } } do
		Pieces.block("LowTable", { at[1] + spot[1], at[2] + spot[2] }, { 4, 1, 2.6 }, "WoodDark", "Wood", STOREY)
	end
	partition(
		{ at[1] - 8, at[2] - 14.2 },
		{ at[1] - 8, at[2] + 14.2 },
		STOREY,
		STOREY - 0.5,
		{ 14.2 },
		"OffWhite",
		"Fabric"
	)
	faceSign(at, size, "+Z", 0, DOOR + 1, 14, 1.4, "Map.Shinjuku.Sign.Ramen", "Black", "Cream")
	for index = 0, 3 do
		B.part({
			Name = "Curtain",
			Size = { 1.9, 2.2, 0.1 },
			Position = { at[1] - 2.85 + index * 1.9, DOOR - 1.1, front + 0.2 },
			Color = "TealDark",
			Material = "Fabric",
			CanCollide = false,
		})
	end
	for _, dx in { -21, 21 } do
		B.part({
			Name = "Lantern",
			Size = { 1.6, 2.2, 1.6 },
			Position = { at[1] + dx, DOOR, front + 1 },
			Shape = "Ball",
			Color = "Red",
			Material = "Neon",
			CanCollide = false,
		})
	end
	-- A rooftop sign facing the street.
	for _, dx in { -6, 6 } do
		Pieces.column(
			"SignPost",
			{ at[1] + dx, at[2] + 10 },
			2 * STOREY + 0.6,
			2 * STOREY + 4,
			0.4,
			"MetalDark",
			"Metal"
		)
	end
	B.sign({
		Name = "RoofSign",
		Size = { 16, 4, 0.4 },
		Position = { at[1], 2 * STOREY + 6, at[2] + 10 },
		Rotation = B.yaw("North"),
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Ramen",
		TextColor = "OffWhite",
		CanCollide = false,
	})
	acUnit({ at[1] + 14, at[2] - 8 }, 2 * STOREY + 0.6)
end

--[[
	The yokocho between the ramen shop and the plaza (after Shinjuku's lantern-lit alleys of tiny bars): two
	two-storey rows facing a lane, each split into six little bars (a door, a counter, stools, a red lantern; the
	wooden partitions break) and, at the west end, a bay with the stair up to the rooms above, which doorways join;
	lanterns hang across the lane, an arch with the YOKOCHO sign at its west end, a ladder onto the north row's roof.
]]
local YOKOCHO = { X = -112, Length = 96, Depth = 12, LaneZ = 22, Lane = 8 }

local function yokocho()
	local bays = { -39, -23.5, -10.5, 2.5, 15.5, 28.5, 41.5 } -- the bays' centres along the row (the first: the stair)
	local walls = { -30, -17, -4, 9, 22, 35 }
	for _, side in { 1, -1 } do -- the north row (its doors face −Z), then the south row
		local z = YOKOCHO.LaneZ + side * (YOKOCHO.Lane / 2 + YOKOCHO.Depth / 2)
		local laneFace = if side > 0 then "-Z" else "+Z"
		local back = z + side * (YOKOCHO.Depth / 2 - 1.6) -- along the back wall, inside
		-- A door into each bar off the lane; the stair's bay opens at the row's west end, onto the foot of the ramp.
		local openings: { Rooms.Opening } = { { Face = "-X", At = -2, Width = 4, Height = DOOR } }
		for index, bay in bays do
			if index > 1 then
				table.insert(openings, { Face = laneFace, At = bay, Width = 5, Height = DOOR })
			end
			table.insert(openings, { Face = laneFace, At = bay, Width = 5, Height = 3, Bottom = 3, Floor = 2 })
		end
		building({
			Name = if side > 0 then "YokochoNorth" else "YokochoSouth",
			At = { YOKOCHO.X, z },
			Size = { YOKOCHO.Length, YOKOCHO.Depth },
			Floors = 2,
			Storey = STOREY,
			Color = if side > 0 then "WoodDark" else "Wood",
			Material = "WoodPlanks",
			FloorColor = "WoodMid",
			FloorMaterial = "WoodPlanks",
			Openings = openings,
			Stair = { At = { bays[1], 0 }, Along = "X", Width = 4 },
			Roof = { Color = "AsphaltDark", Material = "Slate", Parapet = true },
		})
		for index, wallX in walls do
			local x = YOKOCHO.X + wallX
			local inner = YOKOCHO.Depth / 2 - 0.8
			-- Downstairs each bar is its own room; upstairs a doorway joins them.
			partition({ x, z - inner }, { x, z + inner }, 0, STOREY - 0.5, nil, "WoodMid", "Wood")
			partition({ x, z - inner }, { x, z + inner }, STOREY, STOREY - 0.5, { inner }, "WoodMid", "Wood")
			local bay = YOKOCHO.X + bays[index + 1]
			Pieces.block("BarCounter", { bay, back }, { 8, 3.4, 1.2 }, "WoodDark", "Wood")
			for _, dx in { -2, 2 } do
				upright("Stool", { bay + dx, back - side * 2 }, 0, 2.2, 1.2, "Red", "SmoothPlastic")
			end
			Pieces.block("LowTable", { bay, z }, { 4, 1, 2.6 }, "WoodDark", "Wood", STOREY)
		end
		for _, bay in bays do
			B.part({
				Name = "Lantern",
				Size = { 1.2, 1.6, 1.2 },
				Position = { YOKOCHO.X + bay, DOOR - 0.4, YOKOCHO.LaneZ + side * (YOKOCHO.Lane / 2 - 2) },
				Shape = "Ball",
				Color = "Red",
				Material = "Neon",
				CanCollide = false,
			})
		end
	end
	-- Lanterns strung across the lane, the arch at its west end, a ladder up the north row's east end.
	for _, x in { -150, -126, -102, -78 } do
		local length = YOKOCHO.Lane + 2
		B.part({
			Name = "LanternWire",
			Size = { 0.08, 0.08, length },
			Position = { x, 13, YOKOCHO.LaneZ },
			Color = "Black",
			CanCollide = false,
			CastShadow = false,
		})
		for _, dz in { -2.5, 0, 2.5 } do
			B.part({
				Name = "Lantern",
				Size = { 1, 1.3, 1 },
				Position = { x, 12.1, YOKOCHO.LaneZ + dz },
				Shape = "Ball",
				Color = if dz == 0 then "WarmLight" else "Red",
				Material = "Neon",
				CanCollide = false,
			})
		end
	end
	local west = YOKOCHO.X - YOKOCHO.Length / 2
	for _, dz in { -YOKOCHO.Lane / 2 - 0.5, YOKOCHO.Lane / 2 + 0.5 } do
		upright("ArchPost", { west - 2, YOKOCHO.LaneZ + dz }, 0, 12, 0.6, "MetalDark", "Metal")
	end
	B.sign({
		Name = "ArchSign",
		Size = { 0.3, 2, YOKOCHO.Lane + 2 },
		Position = { west - 2, 12.6, YOKOCHO.LaneZ },
		Rotation = B.yaw("East"),
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Yokocho",
		TextColor = "OffWhite",
		Glow = true,
		CanCollide = false,
	})
	ladder({ YOKOCHO.X + YOKOCHO.Length / 2 + 1, YOKOCHO.LaneZ + YOKOCHO.Lane / 2 + YOKOCHO.Depth / 2 }, 0, 22)
	-- A plank from the north row's roof to the pachinko parlor's.
	Pieces.block("RoofPlank", { -88, 41 }, { 3, 0.3, 9.5 }, "Wood", "WoodPlanks", 2 * STOREY + 1.8)
end

-- The pachinko parlor between the ramen shop and the west tower: rows of pinball machines on both floors (screens on
-- both sides of each row), a prize counter, a glass front onto the main street with a neon band, a stair to the roof
-- (where its sign spins: movers()).
local function pachinko()
	local at, size = PACHINKO.At, PACHINKO.Size
	local front = at[2] + size[2] / 2
	building({
		Name = "Pachinko",
		At = at,
		Size = size,
		Floors = 2,
		Storey = STOREY,
		Color = "ShopPink",
		FloorColor = "Red",
		FloorMaterial = "Carpet",
		Openings = {
			{ Face = "+Z", At = 0, Width = 8, Height = DOOR },
			{ Face = "+Z", At = -11, Width = 8, Height = 6.5, Bottom = 0.6, Glass = true },
			{ Face = "+Z", At = 11, Width = 8, Height = 6.5, Bottom = 0.6, Glass = true },
			{ Face = "-Z", At = -10, Width = 5, Height = DOOR },
		},
		Windows = { Faces = { "+Z" }, Width = 6, Height = 4, Sill = 2.5, Spacing = 9, From = 2 },
		Stair = { At = { 13, 0 }, Along = "Z", Width = 4 },
		Roof = { Color = "Black", Hatch = true, Parapet = true },
	})
	for _, row in { { 0, 49 }, { 0, 55 }, { 0, 61 }, { STOREY, 51 }, { STOREY, 59 } } do
		local y, z = row[1], row[2]
		Pieces.block("Machines", { at[1] - 3.5, z }, { 23, 4.6, 1.4 }, "OffWhite", "SmoothPlastic", y)
		for _, dz in { -0.75, 0.75 } do
			B.part({
				Name = "MachineScreens",
				Size = { 22, 1.6, 0.1 },
				Position = { at[1] - 3.5, y + 3, z + dz },
				Color = if dz < 0 then "NeonPink" else "NeonTeal",
				Material = "Neon",
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	Pieces.block("PrizeCounter", { at[1] - 14, front - 4 }, { 6, 3.4, 2 }, "WoodDark", "Wood")
	panel("NeonBand", at, size, "+Z", 0, DOOR + 1, size[1], 0.5, "NeonPink", "Neon")
	faceSign(at, size, "+Z", 0, 18.4, 18, 2.2, "Map.Shinjuku.Sign.Pachinko", "Black", "NeonPink", true)
	B.part({
		Name = "VerticalSign",
		Size = { 1.6, 14, 0.4 },
		Position = { at[1] - 16.5, 10, front + 0.5 },
		Color = "LaneYellow",
		Material = "Neon",
		CanCollide = false,
	})
	acUnit({ at[1] - 12, at[2] + 8 }, 2 * STOREY + 0.6)
	acUnit({ at[1] - 12, at[2] - 8 }, 2 * STOREY + 0.6)
end

-- The karaoke tower between the east tower and the mart: four storeys, a lobby with a counter and sofas, then on each
-- floor above a corridor between six booths (a sofa in each; the walls break), a stair to the roof, a big sign.
local function karaoke()
	local at, size = KARAOKE.At, KARAOKE.Size
	building({
		Name = "Karaoke",
		At = at,
		Size = size,
		Floors = KARAOKE.Floors,
		Storey = STOREY,
		Color = "ShopTeal",
		FloorColor = "Black",
		FloorMaterial = "Carpet",
		Openings = {
			{ Face = "+Z", At = 0, Width = 6, Height = DOOR },
			{ Face = "+Z", At = -10, Width = 8, Height = 6.5, Bottom = 0.6, Glass = true },
			{ Face = "+Z", At = 10, Width = 8, Height = 6.5, Bottom = 0.6, Glass = true },
			{ Face = "-Z", At = -4, Width = 5, Height = DOOR },
		},
		Windows = { Faces = { "+Z", "-Z" }, Width = 5, Height = 4, Sill = 2.5, Spacing = 8, From = 2 },
		Stair = { At = { -13, 0 }, Along = "Z", Width = 4 },
		Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
	})
	local x0, x1 = at[1] - 8, at[1] + size[1] / 2 - 0.8 -- the booths: east of the stair
	local booth = (x1 - x0) / 3
	local zSouth, zNorth = at[2] - 3, at[2] + 3 -- the corridor's walls
	local inner = size[2] / 2 - 0.8
	Pieces.block("Counter", { at[1] + 6, at[2] + 4 }, { 10, 3.4, 2 }, "WoodDark", "Wood")
	sofa({ at[1] + 12, at[2] - 10 }, 0, 0, "Purple")
	sofa({ at[1] + 2, at[2] - 10 }, 0, 0, "Purple")
	for floor = 2, KARAOKE.Floors do
		local y = (floor - 1) * STOREY
		local height = STOREY - 0.5
		local doors = { booth / 2, booth * 1.5, booth * 2.5 }
		partition({ x0, zSouth }, { x1, zSouth }, y, height, doors, "OffWhite")
		partition({ x0, zNorth }, { x1, zNorth }, y, height, doors, "OffWhite")
		for _, wallX in { x0 + booth, x0 + 2 * booth } do
			partition({ wallX, at[2] - inner }, { wallX, zSouth }, y, height, nil, "Purple")
			partition({ wallX, zNorth }, { wallX, at[2] + inner }, y, height, nil, "Purple")
		end
		for _, boothX in { x0 + booth / 2, x0 + booth * 1.5, x0 + booth * 2.5 } do
			sofa({ boothX, at[2] - inner + 1.4 }, y, 0, "Purple")
			sofa({ boothX, at[2] + inner - 1.4 }, y, 180, "Purple")
		end
	end
	-- The sign on the roof, facing the main street, on two posts; AC units by the hatch-free end.
	local roof = KARAOKE.Floors * STOREY + 0.6
	for _, dx in { -7, 7 } do
		Pieces.column("SignPost", { at[1] + dx, at[2] + 6 }, roof, roof + 3, 0.4, "MetalDark", "Metal")
	end
	B.sign({
		Name = "RoofSign",
		Size = { 20, 5, 0.4 },
		Position = { at[1], roof + 5.5, at[2] + 6 },
		Rotation = B.yaw("North"),
		Color = "ShopTeal",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Karaoke",
		TextColor = "OffWhite",
		Glow = true,
		CanCollide = false,
	})
	acUnit({ at[1] + 12, at[2] - 8 }, roof)
	acUnit({ at[1] + 4, at[2] - 8 }, roof)
end

--[[
	The multi-storey car park between the karaoke tower, the mart and the arcade: four decks 9 apart behind low walls
	(open between the piers, so you can jump out or in), a roof deck with lamp posts, columns, parked cars, a stair up
	the east end to the roof, car entrances off the side street, a PARKING sign; a steel gangway climbs from its roof
	to the karaoke tower's.
]]
local function carPark()
	local at, size = CARPARK.At, CARPARK.Size
	local openings = {}
	for floor = 1, CARPARK.Floors do
		for _, faceName in { "+X", "-X", "+Z", "-Z" } do
			local alongX = string.sub(faceName, 2) == "Z"
			local count = if alongX then 7 else 4
			for index = 1, count do
				local spot = (index - (count + 1) / 2) * 12
				-- Car entrances off the side street, walk-in doors on the other sides; the rest open above a low wall.
				local entry = floor == 1
					and (
						(faceName == "+X" and (index == 2 or index == 3))
						or (faceName ~= "+X" and index == math.ceil(count / 2))
					)
				table.insert(openings, {
					Face = faceName,
					At = spot,
					Width = 9.5,
					Height = if entry then 7.5 else CARPARK.Storey,
					Bottom = if entry then nil else 1.2,
					Floor = floor,
				})
			end
		end
	end
	building({
		Name = "CarPark",
		At = at,
		Size = size,
		Floors = CARPARK.Floors,
		Storey = CARPARK.Storey,
		Color = "ConcreteLight",
		FloorColor = "Concrete",
		Openings = openings,
		Stair = { At = { 38, 12 }, Along = "Z", Width = 4 },
		Roof = { Color = "Concrete", Hatch = true, Parapet = true },
	})
	for floor = 1, CARPARK.Floors do
		local y = (floor - 1) * CARPARK.Storey
		for _, cx in { -33, -11, 11, 30 } do
			for _, cz in { -8, 8 } do
				B.part({
					Name = "Column",
					Size = { 1.4, CARPARK.Storey - 0.5, 1.4 },
					Position = { at[1] + cx, y + (CARPARK.Storey - 0.5) / 2, at[2] + cz },
					Color = "ConcreteLight",
					Material = "Concrete",
				})
			end
		end
		-- The lane edges, painted yellow along both rows of bays.
		for _, cz in { -11, 11 } do
			paint("BayLine", { at[1] - 6, at[2] + cz }, { 76, 0.4 }, "LaneYellow", nil, y + 0.12)
		end
	end
	local cars: { { At: { number }, Y: number, Color: string } } = {
		{ At = { -38, -16 }, Y = 0, Color = "Red" },
		{ At = { 18, 16 }, Y = 0, Color = "OffWhite" },
		{ At = { -24, 16 }, Y = CARPARK.Storey, Color = "CityBlue" },
		{ At = { 4, -16 }, Y = CARPARK.Storey, Color = "Black" },
		{ At = { -6, 16 }, Y = 2 * CARPARK.Storey, Color = "LaneYellow" },
		{ At = { 24, -16 }, Y = 2 * CARPARK.Storey, Color = "OffWhite" },
		{ At = { -8, -16 }, Y = CARPARK_ROOF, Color = "Red" },
		{ At = { 6, -16 }, Y = CARPARK_ROOF, Color = "CityGrey" },
	}
	for index, parked in cars do
		car(`ParkedCar{index}`, { at[1] + parked.At[1], at[2] + parked.At[2] }, 0, parked.Color, parked.Y)
	end
	for _, dx in { -40, 22 } do
		Pieces.lamp("RoofLamp", { at[1] + dx, at[2] }, 12, 90, CARPARK_ROOF)
	end
	faceSign(at, size, "+X", 0, 22, 16, 3, "Map.Shinjuku.Sign.Parking", "CityBlue", "OffWhite")
	-- The gangway up to the karaoke tower's roof (over both parapets).
	local karaokeRoof = KARAOKE.Floors * STOREY + 0.6
	Pieces.span(
		"Gangway",
		{ KARAOKE.At[1], CARPARK_ROOF + 1.2, at[2] + size[2] / 2 - 0.6 },
		{ KARAOKE.At[1], karaokeRoof + 1.2, KARAOKE.At[2] - KARAOKE.Size[2] / 2 + 0.6 },
		3,
		"MetalDark",
		"DiamondPlate",
		"Gangway"
	)
end

-- The gas station by the avenue, in front of the east tower: a canopy on four columns over two pump islands (a ladder
-- up onto it), a kiosk with a counter, a price pylon with the GAS sign.
local function gasStation()
	local canopy = { 44, -6 }
	Pieces.block("Canopy", canopy, { 26, 0.8, 18 }, "OffWhite", "Metal", 10)
	panel("CanopyStripe", canopy, { 26, 18 }, "-X", 0, 10.4, 18, 0.5, "Red")
	panel("CanopyStripe", canopy, { 26, 18 }, "+Z", 0, 10.4, 26, 0.5, "Red")
	for _, dx in { -10, 10 } do
		for _, dz in { -7, 7 } do
			Pieces.column("CanopyColumn", { canopy[1] + dx, canopy[2] + dz }, 0, 10, 0.9, "OffWhite", "Metal", true)
		end
	end
	for _, dz in { -3.5, 3.5 } do
		Pieces.block("PumpIsland", { canopy[1], canopy[2] + dz }, { 12, 0.4, 2.2 }, "ConcreteLight", "Concrete")
		for _, dx in { -3, 3 } do
			Pieces.block("Pump", { canopy[1] + dx, canopy[2] + dz }, { 1.6, 4.4, 1.4 }, "Red", "SmoothPlastic", 0.4)
		end
	end
	ladder({ canopy[1] + 14, canopy[2] }, 0, 12)
	local kiosk, kioskSize = { 22, -15 }, { 14, 10 }
	building({
		Name = "GasKiosk",
		At = kiosk,
		Size = kioskSize,
		Floors = 1,
		Storey = 9,
		Color = "OffWhite",
		Openings = {
			{ Face = "+X", At = 0, Width = 5, Height = DOOR },
			{ Face = "-X", At = 0, Width = 8, Height = 3.5, Bottom = 2.5, Glass = true },
		},
		Roof = { Color = "Red" },
	})
	Pieces.block("Counter", { kiosk[1] - 3, kiosk[2] }, { 1.6, 3.4, 6 }, "WoodDark", "Wood")
	upright("PylonPost", { 32, -24 }, 0, 14, 0.7, "MetalDark", "Metal")
	B.sign({
		Name = "Pylon",
		Size = { 6, 3.4, 0.4 },
		Position = { 32, 15.5, -24 },
		Rotation = B.yaw("West"),
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Gas",
		TextColor = "OffWhite",
		CanCollide = false,
	})
end

-- The police box (koban) on the avenue under the east tower: a white hut with a red lamp, a desk inside, a bicycle.
local function koban()
	local at, size = { 22, 6 }, { 12, 10 }
	building({
		Name = "Koban",
		At = at,
		Size = size,
		Floors = 1,
		Storey = STOREY,
		Color = "OffWhite",
		Openings = { { Face = "-X", At = 0, Width = 5, Height = DOOR } },
		Windows = { Faces = { "+Z", "-Z" }, Width = 3, Height = 3, Sill = 3, Spacing = 5 },
		Roof = { Color = "AsphaltDark" },
	})
	faceSign(at, size, "-X", 0, 9, 6, 1, "Map.Shinjuku.Sign.Koban", "OffWhite", "Black")
	B.part({
		Name = "RedLamp",
		Size = { 1.1, 1.1, 1.1 },
		Position = { at[1] - size[1] / 2 - 0.5, 9, at[2] + 3.6 },
		Shape = "Ball",
		Color = "Red",
		Material = "Neon",
		CanCollide = false,
	})
	desk({ at[1] + 2, at[2] }, 0, 90)
	bike({ at[1] - size[1] / 2 - 1.5, at[2] - 3 }, 0, "OffWhite")
end

-- A bus shelter on the avenue's pavement: a roof on two posts, a glass back, a bench.
local function busStop(at: { number })
	B.model("BusStop", function()
		Pieces.block("ShelterRoof", at, { 3.6, 0.3, 11 }, "MetalDark", "Metal", 8)
		for _, dz in { -5.1, 5.1 } do
			upright("ShelterPost", { at[1] + 1.4, at[2] + dz }, 0, 8, 0.35, "MetalDark", "Metal")
		end
		B.part({
			Name = "ShelterGlass",
			Size = { 0.2, 5, 10 },
			Position = { at[1] + 1.5, 3.6, at[2] },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.5,
			Tags = BREAKABLE,
		})
		bench({ at[1] + 0.4, at[2] }, -90)
	end)
end

-- The 24-hour mart: a big glass front, shelves and a drinks cooler inside, a counter by the door, a striped sign
-- band; vending machines on its side.
local function mart()
	local at, size = { 125, 55 }, { 46, 30 }
	building({
		Name = "Mart",
		At = at,
		Size = size,
		Floors = 1,
		Storey = 12,
		Color = "OffWhite",
		FloorColor = "OffWhite",
		FloorMaterial = "SmoothPlastic",
		Openings = {
			{ Face = "-Z", At = 0, Width = 10, Height = DOOR },
			{ Face = "-Z", At = -14, Width = 14, Height = 7.6, Bottom = 0.4, Glass = true },
			{ Face = "-Z", At = 14, Width = 14, Height = 7.6, Bottom = 0.4, Glass = true },
		},
		Roof = { Color = "OffWhite", Parapet = true },
	})
	for _, dz in { -4, 2, 8 } do
		Pieces.block("Shelf", { at[1] + 2, at[2] + dz }, { 20, 4.6, 1.6 }, "OffWhite", "Metal")
	end
	Pieces.block("Cooler", { at[1] + 21.4, at[2] + 2 }, { 1.6, 7, 18 }, "Glass", "Glass")
	Pieces.block("Counter", { at[1] - 17, at[2] - 7 }, { 2, 3.4, 6 }, "WoodDark", "Wood")
	panel("SignBand", at, size, "-Z", 0, 10.4, size[1], 2.6, "OffWhite")
	panel("Stripe", at, size, "-Z", 0, 8.7, size[1], 0.6, "Teal")
	faceSign(at, size, "-Z", 0, 10.4, 16, 1.8, "Map.Shinjuku.Sign.Mart", "OffWhite", "TealDark")
	vending({ at[1] + size[1] / 2 + 1.3, at[2] - 2 }, 90, "Red")
	vending({ at[1] + size[1] / 2 + 1.3, at[2] + 1.4 }, 90, "CityBlue")
	roofKit(at, size, 12.6, true)
end

-- The graveyard: a low stone wall with a gap on the north, a path to a small temple at the back (a gabled roof, an
-- altar, an offering box, an incense burner, stone lanterns), rows of gravestones either side, a four-tier pagoda you
-- can climb eave by eave, bare trees. The wall and the stones break.
local function graveyard()
	local at, size = { 55, -50 }, { 50, 44 }
	local x0, x1, z0, z1 = at[1] - size[1] / 2, at[1] + size[1] / 2, at[2] - size[2] / 2, at[2] + size[2] / 2
	B.model("Graveyard", function()
		paint("Ground", at, size, "GraveGrass", "Grass")
		paint("Path", { at[1], -40 }, { 4, 24 }, "Stone", "Cobblestone", 0.08)
		local function stoneWall(a: { number }, b: { number })
			local alongX = math.abs(b[1] - a[1]) >= math.abs(b[2] - a[2])
			local length = if alongX then math.abs(b[1] - a[1]) else math.abs(b[2] - a[2])
			local count = math.max(1, math.ceil(length / 12))
			for index = 1, count do
				local t = (index - 0.5) / count
				B.part({
					Name = "StoneWall",
					Size = if alongX then { length / count, 1.4, 0.8 } else { 0.8, 1.4, length / count },
					Position = { a[1] + (b[1] - a[1]) * t, 0.7, a[2] + (b[2] - a[2]) * t },
					Color = "Stone",
					Material = "Cobblestone",
					Tags = BREAKABLE,
				})
			end
		end
		stoneWall({ x0, z0 + 0.4 }, { x1, z0 + 0.4 })
		stoneWall({ x0 + 0.4, z0 + 0.8 }, { x0 + 0.4, z1 })
		stoneWall({ x1 - 0.4, z0 + 0.8 }, { x1 - 0.4, z1 })
		stoneWall({ x0 + 0.8, z1 - 0.4 }, { at[1] - 4, z1 - 0.4 })
		stoneWall({ at[1] + 4, z1 - 0.4 }, { x1 - 0.8, z1 - 0.4 })
		for _, z in { -46, -37 } do
			for _, x in { 35, 39, 43, 47, 63, 67 } do
				Pieces.block("GraveBase", { x, z }, { 2.6, 0.5, 1.2 }, "Stone", "Slate")
				B.part({
					Name = "Gravestone",
					Size = { 2, 2.8, 0.5 },
					Position = { x, 1.9, z },
					Color = "Stone",
					Material = "Slate",
					Tags = BREAKABLE,
				})
			end
		end
		for _, spot in { { 34, -32 }, { 33, -53 }, { 77, -53 } } do
			deadTree(spot)
		end
	end)
	-- The temple at the back, open to the path.
	local hall, hallSize = { at[1], -63 }, { 26, 12 }
	building({
		Name = "Temple",
		At = hall,
		Size = hallSize,
		Floors = 1,
		Storey = 12,
		Color = "Wood",
		Material = "WoodPlanks",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = { { Face = "+Z", At = 0, Width = 12, Height = 9.5 } },
		Roof = { Color = "WoodDark", Material = "Wood" },
	})
	for _, side in { -1, 1 } do
		B.part({
			Name = "Gable",
			Size = { hallSize[1] + 4, 5, hallSize[2] / 2 + 2 },
			Position = { hall[1], 12.6 + 2.5, hall[2] + side * (hallSize[2] / 4 + 1) },
			Rotation = { 0, if side < 0 then 0 else 180, 0 }, -- each wedge's tall end toward the ridge
			Shape = "Wedge",
			Color = "AsphaltDark",
			Material = "Slate",
		})
	end
	Pieces.block("Altar", { hall[1], hall[2] - 3.5 }, { 10, 3.4, 2.6 }, "WoodDark", "Wood")
	Pieces.block("OfferingBox", { hall[1], hall[2] + 2.5 }, { 4, 2.4, 2 }, "WoodDark", "Wood")
	B.part({
		Name = "BellRope",
		Size = { 0.3, 7, 0.3 },
		Position = { hall[1], 8, hall[2] + 4.5 },
		Color = "Red",
		Material = "Fabric",
		CanCollide = false,
	})
	upright("IncenseBurner", { hall[1], -51 }, 0, 2.2, 2.4, "MetalDark", "Metal")
	upright("IncenseLid", { hall[1], -51 }, 2.2, 0.5, 3, "MetalDark", "Metal", false)
	for _, dx in { -9, 9 } do
		B.model("StoneLantern", function()
			local spot = { hall[1] + dx, -54 }
			Pieces.block("Base", spot, { 2.2, 0.8, 2.2 }, "Stone", "Slate")
			Pieces.block("Pillar", spot, { 1, 3.4, 1 }, "Stone", "Slate", 0.8)
			Pieces.block("Light", spot, { 2, 1.8, 2 }, "WarmLight", "Neon", 4.2)
			Pieces.block("Cap", spot, { 2.8, 0.7, 2.8 }, "Stone", "Slate", 6)
		end)
	end
	-- The pagoda in the east corner: four shrinking tiers under wide eaves, a spire on top.
	local pagoda = { 74, -40 }
	B.model("Pagoda", function()
		for tier = 0, 3 do
			local base = tier * 5.4
			local width = 8 - tier * 1.5
			Pieces.block("Tier", pagoda, { width, 4.8, width }, "TempleRed", "SmoothPlastic", base)
			Pieces.block("Eave", pagoda, { width + 4, 0.6, width + 4 }, "AsphaltDark", "Slate", base + 4.8)
		end
		upright("Spire", pagoda, 21.6, 5.4, 0.5, "OldBrass", "Metal", false)
		B.part({
			Name = "Finial",
			Size = { 1.2, 1.2, 1.2 },
			Position = { pagoda[1], 27.4, pagoda[2] },
			Shape = "Ball",
			Color = "OldBrass",
			Material = "Metal",
			CanCollide = false,
		})
	end)
end

-- The arcade by the second street, two storeys: rows of game cabinets downstairs, prize-grabber machines and a prize
-- counter upstairs (a stair at the east end), a glass front, neon trim and a big ARCADE sign, a ladder to the roof.
local function arcade()
	local at, size = { 119, -50 }, { 68, 38 }
	local roof = 2 * STOREY + 0.6
	building({
		Name = "Arcade",
		At = at,
		Size = size,
		Floors = 2,
		Storey = STOREY,
		Color = "ArcadeBlue",
		FloorColor = "Black",
		Openings = {
			{ Face = "-Z", At = 0, Width = 8, Height = DOOR },
			{ Face = "-Z", At = -15, Width = 12, Height = 7, Bottom = 0.5, Glass = true },
			{ Face = "-Z", At = 15, Width = 12, Height = 7, Bottom = 0.5, Glass = true },
			{ Face = "+Z", At = 0, Width = 6, Height = DOOR },
		},
		Windows = { Faces = { "+X", "-X", "+Z" }, Width = 5, Height = 4, Sill = 2.5, Spacing = 9, From = 2 },
		Stair = { At = { 29, 0 }, Along = "Z", Width = 4 },
		Roof = { Color = "ArcadeBlue", Hatch = true, Parapet = true },
	})
	for _, row in { { -58, 0 }, { -42, 180 } } do
		for index = 0, 8 do
			local x = 93 + index * 5.6
			local place = placer({ x, row[1] }, row[2])
			B.model("Cabinet", function()
				B.part({
					Name = "Body",
					Size = { 2.6, 6.2, 2.2 },
					Position = place(0, 3.1, 0),
					Rotation = { 0, row[2], 0 },
					Color = "Black",
				})
				B.part({
					Name = "Screen",
					Size = { 2, 1.6, 0.1 },
					Position = place(0, 4.6, 1.12),
					Rotation = { 0, row[2], 0 },
					Color = if index % 2 == 0 then "NeonTeal" else "NeonPink",
					Material = "Neon",
					CanCollide = false,
				})
			end)
		end
	end
	-- Upstairs: a row of prize grabbers (a base and a glass box) and the prize counter.
	for index = 0, 4 do
		local spot = { 115 + index * 6, -60 }
		Pieces.block(
			"GrabberBase",
			spot,
			{ 3, 2.4, 3 },
			if index % 2 == 0 then "NeonPink" else "NeonTeal",
			"SmoothPlastic",
			STOREY
		)
		local glass = Pieces.block("GrabberGlass", spot, { 3, 3, 3 }, "Glass", "Glass", STOREY + 2.4)
		glass.Transparency = 0.5
	end
	Pieces.block("PrizeCounter", { 125, -40 }, { 10, 3.2, 2 }, "WoodDark", "Wood", STOREY)
	for index, color in { "NeonPink", "NeonTeal" } do
		B.part({
			Name = "NeonTrim",
			Size = { size[1] + 0.4, 0.3, size[2] + 0.4 },
			Position = { at[1], roof - 0.6 - index * 0.8, at[2] },
			Color = color,
			Material = "Neon",
			CanCollide = false,
			CastShadow = false,
		})
	end
	faceSign(at, size, "-Z", 0, 13, 20, 3, "Map.Shinjuku.Sign.Arcade", "Black", "NeonPink", true)
	roofKit(at, size, roof, false)
	ladder({ at[1] + size[1] / 2 + 1, at[2] + 15 }, 0, 22) -- onto the roof from the east side
end

---------------------------------------------------------------------------------------------------------------------
-- The west strip: the mall and the bowling alley; the east strip: apartments
---------------------------------------------------------------------------------------------------------------------

-- The mall: three floors joined by a wide stair (on up to the roof), shop stalls along the back wall on every floor,
-- benches, a food court on the top floor, graffiti, a big sign on the roof and a ladder to it.
local function mall()
	local at, size = { -232, 25 }, { 80, 96 }
	local storey = 11
	local roof = 3 * storey + 0.6
	building({
		Name = "Mall",
		At = at,
		Size = size,
		Floors = 3,
		Storey = storey,
		Color = "CityTan",
		FloorColor = "ConcreteLight",
		Openings = {
			{ Face = "+X", At = 0, Width = 14, Height = 9 },
			{ Face = "+X", At = -24, Width = 18, Height = 8, Bottom = 0.5, Glass = true },
			{ Face = "+X", At = 24, Width = 18, Height = 8, Bottom = 0.5, Glass = true },
			{ Face = "+Z", At = 0, Width = 10, Height = DOOR },
		},
		Windows = { Faces = { "+X", "+Z", "-Z" }, Width = 12, Height = 4.5, Sill = 3, Spacing = 16, From = 2 },
		Stair = { At = { 0, 0 }, Along = "Z", Width = 6 },
		Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
	})
	local colors = { "ShopRed", "ShopTeal", "ShopYellow", "ShopPink" }
	for floor = 1, 3 do
		local y = (floor - 1) * storey
		for index, z in { -10, 10, 30, 50 } do
			Pieces.block("Stall", { -262, z }, { 10, 4, 6 }, colors[(index + floor) % #colors + 1], "SmoothPlastic", y)
		end
		if floor < 3 then
			bench({ -214, -10 }, -90, y)
			bench({ -214, 60 }, -90, y)
		end
	end
	for _, spot in { { -248, 5 }, { -248, 45 }, { -212, 5 }, { -212, 45 } } do
		smallTable(spot, 2 * storey)
	end
	for index, color in { "NeonPink", "ShopYellow", "NeonTeal", "ShopOrange" } do
		panel(`Graffiti{index}`, at, size, "+Z", -27 + (index - 1) * 18, 5.5 + (index % 2), 11, 5, color)
	end
	faceSign(at, size, "+X", 0, 10, 18, 1.8, "Map.Shinjuku.Sign.Mall", "CityBlue", "OffWhite")
	-- A big sign on the roof facing the street.
	for _, dz in { -10, 10 } do
		Pieces.column("SignPost", { at[1] + 30, at[2] + dz }, roof, roof + 3.4, 0.5, "MetalDark", "Metal")
	end
	B.sign({
		Name = "RoofSign",
		Size = { 26, 6, 0.5 },
		Position = { at[1] + 30, roof + 6.4, at[2] },
		Rotation = B.yaw("East"),
		Color = "CityBlue",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Mall",
		TextColor = "OffWhite",
		CanCollide = false,
	})
	ladder({ at[1] + size[1] / 2 + 1, at[2] + 45 }, 0, 36)
	roofKit({ at[1] - 10, at[2] }, { 50, size[2] }, roof, true)
end

-- The bowling alley: five lanes toward the back wall (pins at the end, ball returns, score screens over them), a raised
-- seating platform with benches behind the foul line, a shoe counter by the door.
local function bowling()
	local at, size = { -232, -52 }, { 80, 48 }
	building({
		Name = "BowlingAlley",
		At = at,
		Size = size,
		Floors = 1,
		Storey = 13,
		Color = "ShopRed",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "+X", At = 0, Width = 10, Height = 9 },
			{ Face = "+X", At = -14, Width = 10, Height = 7, Bottom = 0.5, Glass = true },
			{ Face = "+X", At = 14, Width = 10, Height = 7, Bottom = 0.5, Glass = true },
		},
		Roof = { Color = "ShopRed", Parapet = true },
	})
	for _, z in { -68, -60, -52, -44, -36 } do
		paint("Lane", { -238, z }, { 52, 4.6 }, "Cream", "WoodPlanks", 0.13)
		paint("Gutter", { -238, z + 2.7 }, { 52, 0.8 }, "Black", nil, 0.13)
		for _, dz in { -1, 0, 1 } do
			upright("Pin", { -262 + math.abs(dz) * 1.2, z + dz }, 0.15, 1.4, 0.4, "OffWhite", "SmoothPlastic", false)
		end
	end
	for _, z in { -56, -40 } do
		Pieces.block("BallReturn", { -211, z }, { 1.6, 1.2, 2 }, "MetalDark", "Metal")
		B.part({
			Name = "ScoreScreen",
			Size = { 0.3, 2.4, 6 },
			Position = { -213, 10.5, z },
			Color = "NeonTeal",
			Material = "Neon",
			CanCollide = false,
			CastShadow = false,
		})
	end
	Pieces.block("Seating", { -206, -52 }, { 8, 1, 40 }, "WoodDark", "WoodPlanks")
	bench({ -205, -64 }, -90, 1)
	bench({ -205, -56 }, -90, 1)
	Pieces.block("ShoeCounter", { -197, -70 }, { 2, 3.4, 8 }, "WoodDark", "Wood")
	faceSign(at, size, "+X", 0, 10.8, 16, 2.4, "Map.Shinjuku.Sign.Bowling", "OffWhite", "Red")
	upright("GiantPin", { -205, -52 }, 13.6, 8, 3.4, "OffWhite", "SmoothPlastic", false) -- on the roof (+13.6)
	upright("PinStripe", { -205, -52 }, 18.8, 0.8, 3.5, "Red", "SmoothPlastic", false)
	B.part({
		Name = "PinHead",
		Size = { 3, 3, 3 },
		Position = { -205, 23.4, -52 },
		Shape = "Ball",
		Color = "OffWhite",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
end

--[[
	A walk-in apartment block, 80 × 44 and `floors` storeys: a door onto the street (−X) and one onto the lane
	(`laneFace`), windows and balconies on the street face, a stair up to the roof away from the lane; on every floor two
	flats either side of a partition (beds, a sofa, a table), water tanks on the roof. On the 3rd floor a doorway on the
	lane face (x 210) opens onto the footbridge between the two blocks.
]]
local function apartments(name: string, at: { number }, floors: number, color: string, laneFace: string)
	local size = { 80, 44 }
	local away = if laneFace == "+Z" then -1 else 1 -- toward the side away from the lane
	local roof = floors * STOREY + 0.6
	building({
		Name = name,
		At = at,
		Size = size,
		Floors = floors,
		Storey = STOREY,
		Color = color,
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "-X", At = 0, Width = 5, Height = DOOR },
			{ Face = laneFace, At = -20, Width = 5, Height = DOOR },
			{ Face = laneFace, At = 0, Width = 5, Height = DOOR, Floor = 2 }, -- onto the lane's deck
			{ Face = laneFace, At = 210 - at[1], Width = 5, Height = DOOR, Floor = 3 },
		},
		Windows = { Faces = { "-X" }, Width = 6, Height = 4, Sill = 2.5, Spacing = 9 },
		Stair = { At = { 30, away * 12 }, Along = "Z", Width = 4 },
		Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
	})
	local inner = size[2] / 2 - 0.8
	for floor = 1, floors do
		local y = (floor - 1) * STOREY
		partition({ at[1], at[2] - inner }, { at[1], at[2] + inner }, y, STOREY - 0.5, { 6, 2 * inner - 6 }, "Cream")
		bed({ at[1] - 32, at[2] + away * 13 }, y, 0, if floor % 2 == 0 then "CityBlue" else "ShopPink")
		bed({ at[1] + 14, at[2] + away * 13 }, y, 0, "Lawn")
		sofa({ at[1] - 14, at[2] + away * 17 }, y, if away > 0 then 180 else 0, "WoodMid")
		smallTable({ at[1] - 14, at[2] + away * 9 }, y)
		if floor > 1 then
			local front = at[1] - size[1] / 2
			B.part({
				Name = "Balcony",
				Size = { 1.6, 0.3, size[2] - 4 },
				Position = { front - 0.8, y, at[2] },
				Color = "OffWhite",
				Material = "Concrete",
				CanCollide = false,
			})
			B.part({
				Name = "BalconyRail",
				Size = { 0.2, 1, size[2] - 4 },
				Position = { front - 1.5, y + 0.65, at[2] },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
	end
	waterTank({ at[1] + 15, at[2] }, roof)
	waterTank({ at[1] - 15, at[2] - away * 10 }, roof)
end

-- Between the apartment blocks: a deck over the lane at their 2nd floors (doorways onto it, a ramp up the lane from
-- the side street, columns, planters and benches on it; bicycles and vending machines in the shade under it), and a
-- footbridge between their 3rd floors above that.
local function apartmentLane()
	local deck = STOREY
	Pieces.block("LaneDeck", { 240, 0 }, { 56, 0.6, 47.2 }, "ConcreteLight", "Concrete", deck - 0.6)
	for _, x in { 220, 240, 260 } do
		for _, z in { -12, 12 } do
			B.part({
				Name = "DeckColumn",
				Size = { 0.8, deck - 0.6, 0.8 },
				Position = { x, (deck - 0.6) / 2, z },
				Color = "ConcreteDark",
				Material = "Concrete",
			})
		end
	end
	Pieces.ramp("DeckRamp", { 194, 0 }, { 212, 0 }, 4, deck, "ConcreteLight", "Concrete")
	Pieces.block("DeckWall", { 267.8, 0 }, { 0.4, 1.1, 47.2 }, "ConcreteDark", "Concrete", deck)
	for _, side in { -1, 1 } do
		Pieces.block("DeckWall", { 212.2, side * 12.8 }, { 0.4, 1.1, 21.6 }, "ConcreteDark", "Concrete", deck)
		pottedPlant({ 252, side * 16 }, deck)
		bench({ 232, side * 18 }, if side > 0 then 180 else 0, deck)
	end
	Pieces.span(
		"Footbridge",
		{ 210, 2 * STOREY, 24 },
		{ 210, 2 * STOREY, -24 },
		3.6,
		"MetalDark",
		"DiamondPlate",
		"Gangway"
	)
	for _, x in { 236, 241 } do
		bike({ x, 4 }, 90, if x > 238 then "Red" else "CityBlue")
	end
end

-- A water tower on four legs in the back lot: a walkway round the tank, a ladder up.
local function waterTower(at: { number })
	B.model("WaterTower", function()
		for _, dx in { -3, 3 } do
			for _, dz in { -3, 3 } do
				Pieces.column("Leg", { at[1] + dx, at[2] + dz }, 0, 30, 0.7, "MetalDark", "Metal")
			end
		end
		Pieces.block("Walkway", at, { 12, 0.5, 12 }, "MetalDark", "DiamondPlate", 30)
		upright("Tank", at, 30.5, 10, 8, "CityBlue", "Metal")
		upright("TankLid", at, 40.5, 0.6, 8.6, "MetalDark", "Metal")
	end)
	ladder({ at[1] + 7, at[2] }, 0, 32)
end

---------------------------------------------------------------------------------------------------------------------
-- The south: the shop row, the department store, the jail and the comedy club, the courthouse, the hotel and the
-- mansion, the building site
---------------------------------------------------------------------------------------------------------------------

local SHOP_Z = -117

local function shopRow()
	for index, entry in
		{
			{ -147, "ShopRed", "Map.Shinjuku.Sign.Books" },
			{ -117, "ShopYellow", "Map.Shinjuku.Sign.Electronics" },
			{ -87, "ShopTeal", "Map.Shinjuku.Sign.Drugstore" },
			{ -57, "ShopPink", "Map.Shinjuku.Sign.Subs" },
			{ -27, "ShopOrange", "Map.Shinjuku.Sign.Sweets" },
		}
	do
		local at, size = { entry[1], SHOP_Z }, { 30, 26 }
		local front = at[2] + size[2] / 2
		building({
			Name = `Shop{index}`,
			At = at,
			Size = size,
			Floors = 3,
			Storey = STOREY,
			Color = entry[2],
			FloorColor = "ConcreteLight",
			Openings = {
				{ Face = "+Z", At = 0, Width = 5, Height = DOOR },
				{ Face = "+Z", At = -8.5, Width = 8, Height = 6.5, Bottom = 0.6, Glass = true },
				{ Face = "+Z", At = 8.5, Width = 8, Height = 6.5, Bottom = 0.6, Glass = true },
				{ Face = "-Z", At = 8, Width = 5, Height = DOOR },
			},
			Windows = { Faces = { "+Z", "-Z" }, Width = 7, Height = 4, Sill = 2.5, Spacing = 9, From = 2 },
			Stair = { At = { -4, -6 }, Along = "X", Width = 3.5 },
			Roof = { Color = "ConcreteDark", Parapet = true },
		})
		faceSign(at, size, "+Z", 0, DOOR + 1.2, 16, 1.2, entry[3], "OffWhite", "Black")
		B.part({
			Name = "Awning",
			Size = { 26, 0.3, 2.4 },
			Position = { at[1], DOOR + 0.4, front + 1.2 },
			Rotation = { 12, 0, 0 },
			Color = entry[2],
			Material = "Fabric",
			CanCollide = false,
		})
		B.part({
			Name = "VerticalSign",
			Size = { 1.6, 16, 0.4 },
			Position = { at[1] + 13.5, 18, front + 0.5 },
			Color = if entry[2] == "ShopYellow" then "Red" else "LaneYellow",
			Material = "Neon",
			CanCollide = false,
		})
		-- Balconies on the upper floors' fronts.
		for floor = 2, 3 do
			local y = (floor - 1) * STOREY
			B.part({
				Name = "Balcony",
				Size = { 12, 0.3, 1.4 },
				Position = { at[1] - 6, y, front + 0.7 },
				Color = "OffWhite",
				Material = "Concrete",
				CanCollide = false,
			})
			B.part({
				Name = "BalconyRail",
				Size = { 12, 1, 0.15 },
				Position = { at[1] - 6, y + 0.65, front + 1.35 },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
		Pieces.block("Counter", { at[1] + 9, at[2] - 8 }, { 7, 3, 1.6 }, "WoodDark", "Wood")
		Pieces.block("Shelf", { at[1] + 12, at[2] + 3 }, { 1.2, 4, 8 }, "WoodMid", "Wood")
		-- Upstairs: a stockroom (a shelf, a table), then a flat (a bed, a sofa).
		Pieces.block("Shelf", { at[1] - 12, at[2] + 7 }, { 1.2, 4, 8 }, "WoodMid", "Wood", STOREY)
		smallTable({ at[1] + 6, at[2] + 4 }, STOREY)
		bed({ at[1] - 8, at[2] + 6 }, 2 * STOREY, 90, entry[2])
		sofa({ at[1] + 6, at[2] + 8 }, 2 * STOREY, 180, "WoodMid")
		roofKit(at, size, 3 * STOREY + 0.6, index % 2 == 1)
	end
	-- Behind the shops: a back lot with dumpsters, manholes and broken-up block walls.
	for _, at in { { -50, -136 }, { -120, -138 } } do
		Pieces.block("Dumpster", at, { 5, 3.4, 3 }, "Bottle", "Metal")
	end
	for _, at in { { -90, -147 }, { -30, -145 } } do
		upright("Manhole", at, 0.1, 0.04, 2.4, "MetalDark", "DiamondPlate", false)
	end
	for _, piece in { { -165, -140 }, { -125, -100 }, { -80, -55 }, { -40, -15 } } do
		blockWall({ piece[1], -142 }, { piece[2], -142 })
	end
end

--[[
	The jail: three storeys (holding cells behind bars downstairs with a front desk, offices on the 2nd, a canteen on the
	3rd), a barred cell on its east side, and behind it the yard with a watchtower (a ladder up to its deck). The comedy
	club: a stage under a curtain, three tiers of seats either side of an aisle, a bar, a marquee.
]]
local function jailAndClub()
	local jail, jailSize = { -235, -143 }, { 66, 40 }
	building({
		Name = "Jail",
		At = jail,
		Size = jailSize,
		Floors = 3,
		Storey = STOREY,
		Color = "LightPurple",
		FloorColor = "ConcreteLight",
		Openings = {
			{ Face = "+Z", At = 0, Width = 6, Height = DOOR },
			{ Face = "+X", At = -3, Width = 5, Height = DOOR }, -- into the cell
		},
		Windows = { Faces = { "+Z", "+X" }, Width = 3, Height = 3, Sill = 3, Spacing = 11 },
		Stair = { At = { -28, 0 }, Along = "Z", Width = 4 },
		Roof = { Color = "Purple", Parapet = true },
	})
	faceSign(jail, jailSize, "+Z", 0, 28, 8, 1.2, "Map.Shinjuku.Sign.Jail", "OffWhite", "Black")
	-- Downstairs: two holding cells along the back wall (an open door in each), a bunk in each, the front desk.
	local barsZ = jail[2] - 10
	for x = jail[1] - 27, jail[1] + 3, 2 do
		local doorway = math.abs(x - (jail[1] - 20)) < 2 or math.abs(x - (jail[1] - 4)) < 2
		if not doorway then
			upright("Bar", { x, barsZ }, 0, STOREY - 0.5, 0.25, "MetalDark", "Metal")
		end
	end
	Pieces.block("BarsRail", { jail[1] - 12, barsZ }, { 30, 0.4, 0.4 }, "MetalDark", "Metal", STOREY - 1)
	partition(
		{ jail[1] - 12, barsZ - 0.4 },
		{ jail[1] - 12, jail[2] - jailSize[2] / 2 + 0.8 },
		0,
		STOREY - 0.5,
		nil,
		"ConcreteLight",
		"Concrete"
	)
	for _, dx in { -24, -1 } do
		Pieces.block("Bunk", { jail[1] + dx, jail[2] - 16 }, { 6, 1.6, 2.6 }, "MetalDark", "Metal")
	end
	Pieces.block("FrontDesk", { jail[1] + 10, jail[2] + 11 }, { 8, 3.2, 2 }, "WoodDark", "Wood")
	-- The 2nd floor's offices and the 3rd floor's canteen.
	for _, dx in { -10, 3, 16 } do
		desk({ jail[1] + dx, jail[2] + 8 }, STOREY, 0)
	end
	Pieces.block("FilingCabinet", { jail[1] + 30, jail[2] - 8 }, { 2, 4, 6 }, "Metal", "Metal", STOREY)
	for _, dx in { -5, 15 } do
		Pieces.block(
			"CanteenTable",
			{ jail[1] + dx, jail[2] },
			{ 12, 2.6, 2.6 },
			"OffWhite",
			"SmoothPlastic",
			2 * STOREY
		)
		for _, dz in { -2.6, 2.6 } do
			Pieces.block(
				"CanteenBench",
				{ jail[1] + dx, jail[2] + dz },
				{ 12, 1.4, 1 },
				"MetalDark",
				"Metal",
				2 * STOREY
			)
		end
	end
	-- The barred cell on its east side (the bars don't break).
	local cell = { jail[1] + jailSize[1] / 2 + 4, jail[2] - 3 }
	B.model("Cell", function()
		Pieces.block("CellRoof", cell, { 8, 0.4, 10 }, "MetalDark", "Metal", 9)
		for z = cell[2] - 4.5, cell[2] + 4.5, 1 do
			upright("Bar", { cell[1] + 3.9, z }, 0, 9, 0.2, "MetalDark", "Metal")
		end
		for x = cell[1] - 3.5, cell[1] + 3, 1 do
			for _, z in { cell[2] - 4.9, cell[2] + 4.9 } do
				upright("Bar", { x, z }, 0, 9, 0.2, "MetalDark", "Metal")
			end
		end
	end)
	roofKit(jail, jailSize, 3 * STOREY + 0.6, false)
	-- The yard's watchtower: four legs, a deck with low walls (open to the ladder), a roof on posts, a searchlight.
	local tower = { -262, -173.5 }
	B.model("Watchtower", function()
		for _, dx in { -3, 3 } do
			for _, dz in { -3, 3 } do
				Pieces.column("Leg", { tower[1] + dx, tower[2] + dz }, 0, 14, 0.6, "MetalDark", "Metal")
				upright("RoofPost", { tower[1] + dx, tower[2] + dz }, 14.6, 5, 0.25, "MetalDark", "Metal", false)
			end
		end
		Pieces.block("Deck", tower, { 7, 0.6, 7 }, "WoodDark", "WoodPlanks", 14)
		for _, wall in { { { 0, -3.3 }, { 7, 0.3 } }, { { 0, 3.3 }, { 7, 0.3 } }, { { -3.3, 0 }, { 0.3, 6.4 } } } do
			Pieces.block(
				"DeckWall",
				{ tower[1] + wall[1][1], tower[2] + wall[1][2] },
				{ wall[2][1], 1.2, wall[2][2] },
				"WoodDark",
				"Wood",
				14.6
			)
		end
		Pieces.block("WatchRoof", tower, { 8, 0.4, 8 }, "AsphaltDark", "Metal", 19.6)
		upright("Searchlight", { tower[1] - 2.4, tower[2] }, 15.8, 0.9, 1.2, "WarmLight", "Neon", false)
	end)
	ladder({ tower[1] + 4.5, tower[2] }, 0, 16)

	local club, clubSize = { -235, -200 }, { 66, 32 }
	building({
		Name = "ComedyClub",
		At = club,
		Size = clubSize,
		Floors = 1,
		Storey = 13,
		Color = "Purple",
		FloorColor = "Black",
		FloorMaterial = "Carpet",
		Openings = { { Face = "+Z", At = 0, Width = 6, Height = DOOR } },
		Windows = { Faces = { "+X", "-X" }, Width = 4, Height = 3, Sill = 4, Spacing = 8 },
		Roof = { Color = "Black", Parapet = true },
	})
	Pieces.block("Stage", { club[1], club[2] - 11.5 }, { 40, 1.5, 7 }, "WoodDark", "WoodPlanks")
	upright("MicStand", { club[1], club[2] - 11.5 }, 1.5, 4.4, 0.2, "MetalDark", "Metal", false)
	panel("Curtain", club, { clubSize[1] - 1.8, clubSize[2] - 1.8 }, "-Z", 0, 6.5, 40, 11, "Red", "Fabric") -- the back wall
	-- Three tiers of seats rising toward the door, either side of the aisle.
	for tier = 0, 2 do
		for _, x in { club[1] - 15, club[1] + 15 } do
			Pieces.block("SeatTier", { x, club[2] + 2 + tier * 4.5 }, { 24, 0.8 * (tier + 1), 4.5 }, "Red", "Fabric")
		end
	end
	Pieces.block("Bar", { club[1] + 30.5, club[2] + 8 }, { 2, 3.4, 12 }, "WoodDark", "Wood")
	faceSign(club, clubSize, "+Z", 0, DOOR + 1.6, 16, 1.8, "Map.Shinjuku.Sign.Comedy", "Black", "LaneYellow", true)
	for index = 0, 8 do
		B.part({
			Name = "MarqueeLight",
			Size = { 0.5, 0.5, 0.5 },
			Position = { club[1] - 10 + index * 2.5, DOOR + 3, club[2] + clubSize[2] / 2 + 0.4 },
			Shape = "Ball",
			Color = "WarmLight",
			Material = "Neon",
			CanCollide = false,
		})
	end
end

local function courtAndMansion()
	-- The courthouse: one tall hall (a judge's bench on a dais, rows of pews), a portico of six columns over three
	-- steps, a COURT sign.
	local court, courtSize = { 60, -150 }, { 50, 34 }
	local front = court[2] + courtSize[2] / 2
	building({
		Name = "Courthouse",
		At = court,
		Size = courtSize,
		Floors = 1,
		Storey = 15,
		Color = "OffWhite",
		Material = "Marble",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = { { Face = "+Z", At = 0, Width = 8, Height = 10 } },
		Windows = { Faces = { "+X", "-X", "+Z" }, Width = 3, Height = 8, Sill = 3, Spacing = 7 },
		Roof = { Color = "OffWhite", Material = "Marble", Parapet = true },
	})
	Pieces.block("Dais", { court[1], court[2] - 10 }, { 22, 1, 6 }, "WoodDark", "Wood")
	Pieces.block("JudgeBench", { court[1], court[2] - 10.5 }, { 16, 3, 3 }, "WoodDark", "Wood", 1)
	for _, dz in { 2, 9 } do
		Pieces.block("Pew", { court[1] + 6, court[2] + dz }, { 18, 1.4, 1.2 }, "WoodMid", "Wood")
	end
	-- The witness stand by the bench, the jury box (a rail, two benches) along the east wall.
	Pieces.block("WitnessStand", { court[1] - 16, court[2] - 8 }, { 3, 2.4, 3 }, "WoodDark", "Wood")
	Pieces.block("JuryRail", { court[1] + 16, court[2] + 3 }, { 0.4, 1.6, 10 }, "WoodDark", "Wood")
	for _, dx in { 19, 22 } do
		Pieces.block("JuryBench", { court[1] + dx, court[2] + 3 }, { 1.6, 1.4, 9 }, "WoodMid", "Wood")
	end
	B.model("Portico", function()
		Pieces.block("Floor", { court[1], front + 2.5 }, { 52, 1.2, 5 }, "OffWhite", "Marble")
		Pieces.block("Roof", { court[1], front + 2.5 }, { 52, 1, 5.4 }, "OffWhite", "Marble", 15)
		for index = 0, 5 do
			Pieces.column(
				"Column",
				{ court[1] - 23 + index * 9.2, front + 3.5 },
				1.2,
				15,
				1.4,
				"OffWhite",
				"Marble",
				true
			)
		end
		Pieces.stairs("Steps", { court[1], front + 8 }, "-Z", 26, 3, 0.4, 1, "OffWhite", "Marble")
	end)
	B.sign({
		Name = "CourtSign",
		Size = { 14, 1.4, 0.3 },
		Position = { court[1], 16.7, front + 5.3 },
		Rotation = B.yaw("North"),
		Color = "OffWhite",
		Material = "Marble",
		Key = "Map.Shinjuku.Sign.Court",
		TextColor = "Black",
		CanCollide = false,
	})
	-- The mansion: two storeys up a stair, a garage beside it, a hedge with a gap along the front.
	building({
		Name = "Mansion",
		At = { 135, -190 },
		Size = { 42, 30 },
		Floors = 2,
		Storey = STOREY,
		Color = "Cream",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = { { Face = "+Z", At = 0, Width = 5, Height = DOOR } },
		Windows = { Faces = { "+X", "-X", "+Z", "-Z" }, Width = 3, Height = 4, Sill = 2.5, Spacing = 6 },
		Stair = { At = { -10, -5 }, Along = "X", Width = 3.5 },
		Roof = { Color = "AsphaltDark", Material = "Slate" }, -- under its pitched tile roof (roofDetail)
	})
	building({
		Name = "Garage",
		At = { 100, -192 },
		Size = { 18, 20 },
		Floors = 1,
		Storey = 9,
		Color = "Cream",
		Openings = { { Face = "+Z", At = 0, Width = 12, Height = 7.5 } },
		Roof = { Color = "AsphaltDark", Material = "Slate" },
	})
	car("GarageCar", { 100, -194 }, 0, "Black")
	-- Inside the mansion: a sitting room and a kitchen downstairs, two bedrooms upstairs.
	sofa({ 142, -182 }, 0, 180, "Red")
	Pieces.block("CoffeeTable", { 142, -186 }, { 4, 1.2, 2 }, "WoodDark", "Wood")
	Pieces.block("Piano", { 121, -180 }, { 4, 3, 2 }, "Black", "SmoothPlastic")
	Pieces.block("Kitchen", { 151, -201 }, { 6, 3.2, 1.6 }, "OffWhite", "Marble")
	smallTable({ 140, -196 })
	bed({ 148, -198 }, STOREY, 0, "CityBlue")
	bed({ 138, -198 }, STOREY, 0, "ShopPink")
	Pieces.block("Wardrobe", { 154.2, -185 }, { 1.6, 5, 6 }, "WoodDark", "Wood", STOREY)
	for _, piece in { { 92, 128 }, { 142, 160 } } do
		local length = piece[2] - piece[1]
		local count = math.ceil(length / 12)
		for index = 1, count do
			B.part({
				Name = "Hedge",
				Size = { length / count, 1.6, 1.4 },
				Position = { piece[1] + (index - 0.5) * length / count, 0.8, -170 },
				Color = "Leaf",
				Material = "LeafyGrass",
				Tags = BREAKABLE,
			})
		end
	end
end

-- The fire station behind the courthouse: two truck bays onto the avenue (two fire engines inside), lockers, a stair up
-- to the crew's floor (bunks, a table, a sofa) and on to the roof, where the drill tower rises (a ladder up its side
-- from the street), the FIRE STATION sign.
local function fireStation()
	local at, size = { 52, -201 }, { 60, 42 }
	local storey = 12
	local roof = 2 * storey + 0.6
	building({
		Name = "FireStation",
		At = at,
		Size = size,
		Floors = 2,
		Storey = storey,
		Color = "OffWhite",
		FloorColor = "ConcreteLight",
		Openings = {
			{ Face = "-X", At = -8, Width = 10, Height = 10 },
			{ Face = "-X", At = 8, Width = 10, Height = 10 },
			{ Face = "+Z", At = 6, Width = 5, Height = DOOR },
		},
		Windows = { Faces = { "+Z", "-X", "-Z" }, Width = 4, Height = 4, Sill = 2.5, Spacing = 10, From = 2 },
		Stair = { At = { 24, 10 }, Along = "Z", Width = 4 },
		Roof = { Color = "Red", Hatch = true, Parapet = true },
	})
	for _, dz in { -8, 8 } do
		B.model("FireEngine", function()
			local z = at[2] + dz
			Pieces.block("Body", { 41, z }, { 13, 4.8, 6 }, "Red", "SmoothPlastic", 0.9)
			Pieces.block("Cab", { 32.5, z }, { 4, 4, 6 }, "Red", "SmoothPlastic", 0.9)
			Pieces.block("LadderRack", { 41, z }, { 12, 0.5, 1.6 }, "Metal", "Metal", 5.7)
			Pieces.block("Bumper", { 30.3, z }, { 0.4, 0.8, 6 }, "Metal", "Metal", 0.9)
			for _, x in { 34, 45 } do
				B.part({
					Name = "Wheels",
					Size = { 6.4, 1.8, 1.8 },
					Position = { x, 0.9, z },
					Rotation = { 0, 90, 0 },
					Shape = "Cylinder",
					Color = "Black",
					CanCollide = false,
				})
			end
		end)
	end
	panel("BayStripe", at, size, "-X", 0, 11, size[2] - 2, 0.8, "Red")
	faceSign(at, size, "-X", 0, 21, 16, 1.6, "Map.Shinjuku.Sign.Fire", "Red", "OffWhite")
	Pieces.block("Lockers", { 80.4, at[2] - 11 }, { 1, 5, 10 }, "CityGrey", "Metal")
	for _, x in { 40, 50, 60 } do
		bed({ x, at[2] - 14 }, storey, 0, "Red")
	end
	smallTable({ 55, at[2] + 6 }, storey)
	sofa({ 45, at[2] + 13 }, storey, 180, "CityBlue")
	-- The drill tower on the roof's south-west corner, a ladder up its side from the street.
	local tower = { at[1] - size[1] / 2 + 5, at[2] - size[2] / 2 + 5 }
	Pieces.block("DrillTower", tower, { 8, 16, 8 }, "OffWhite", "Concrete", roof)
	for _, face in { "+Z", "-X" } do
		for _, y in { roof + 4, roof + 10 } do
			panel("DrillWindow", tower, { 8, 8 }, face, 0, y, 3, 2.4, "Black")
		end
	end
	for _, edge in { { { 0, 3.8 }, { 8, 0.4 } }, { { 0, -3.8 }, { 8, 0.4 } }, { { 3.8, 0 }, { 0.4, 7.2 } } } do
		Pieces.block(
			"DrillParapet",
			{ tower[1] + edge[1][1], tower[2] + edge[1][2] },
			{ edge[2][1], 1.1, edge[2][2] },
			"Red",
			"Concrete",
			roof + 16
		)
	end
	ladder({ at[1] - size[1] / 2 - 1, tower[2] }, 0, 42)
	acUnit({ at[1] + 10, at[2] - 12 }, roof)
end

-- The hotel by the second street: six storeys, a glass lobby (a reception desk, sofas, plants) under an entrance
-- canopy, then on every floor above a corridor between six rooms (a bed in each; the walls break), a stair to the
-- roof, where there is a helipad and the HOTEL sign.
local function hotel()
	local at, size = HOTEL.At, HOTEL.Size
	local front = at[2] + size[2] / 2
	building({
		Name = "Hotel",
		At = at,
		Size = size,
		Floors = HOTEL.Floors,
		Storey = STOREY,
		Color = "Cream",
		FloorColor = "Red",
		FloorMaterial = "Carpet",
		Openings = {
			{ Face = "+Z", At = 0, Width = 8, Height = 9 },
			{ Face = "+Z", At = -12, Width = 10, Height = 7, Bottom = 0.6, Glass = true },
			{ Face = "+Z", At = 12, Width = 10, Height = 7, Bottom = 0.6, Glass = true },
		},
		Windows = { Faces = { "+Z", "-Z" }, Width = 8, Height = 4, Sill = 2.5, Spacing = 12, From = 2 },
		Stair = { At = { -20, 0 }, Along = "Z", Width = 4 },
		Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
	})
	Pieces.block("Reception", { at[1] + 10, at[2] + 6 }, { 8, 3.2, 2 }, "WoodDark", "Wood")
	sofa({ at[1] - 8, at[2] - 12 }, 0, 0, "Red")
	sofa({ at[1] + 8, at[2] - 12 }, 0, 0, "Red")
	pottedPlant({ at[1] - 22, front - 2.5 }, 0)
	pottedPlant({ at[1] + 22, front - 2.5 }, 0)
	local x0, x1 = at[1] - 16, at[1] + size[1] / 2 - 0.8 -- the rooms: east of the stair
	local zSouth, zNorth = at[2] - 3, at[2] + 3
	local inner = size[2] / 2 - 0.8
	for floor = 2, HOTEL.Floors do
		local y = (floor - 1) * STOREY
		local height = STOREY - 0.5
		partition({ x0, zSouth }, { x1, zSouth }, y, height, { 5, 15, 25, 35 }, "Cream")
		partition({ x0, zNorth }, { x1, zNorth }, y, height, { 5, 15, 25, 35 }, "Cream")
		for _, wallX in { x0 + 10, x0 + 20, x0 + 30 } do
			partition({ wallX, at[2] - inner }, { wallX, zSouth }, y, height, nil, "Cream")
			partition({ wallX, zNorth }, { wallX, at[2] + inner }, y, height, nil, "Cream")
		end
		for _, roomX in { x0 + 5, x0 + 15, x0 + 25, x0 + 35 } do
			bed({ roomX, at[2] - 11 }, y, 0, "OffWhite")
			bed({ roomX, at[2] + 11 }, y, 0, "OffWhite")
		end
	end
	-- The entrance canopy on two posts.
	Pieces.block("EntranceCanopy", { at[1], front + 3 }, { 16, 0.4, 6 }, "MetalDark", "Metal", 9.5)
	for _, dx in { -7, 7 } do
		upright("CanopyPost", { at[1] + dx, front + 5.5 }, 0, 9.5, 0.45, "MetalDark", "Metal")
	end
	-- The roof: a helipad (a disc and an H), the sign on two posts facing the street, a water tank.
	local roof = HOTEL_ROOF
	local pad = { at[1] + 6, at[2] - 4 }
	upright("Helipad", pad, roof, 0.06, 14, "AsphaltDark", "SmoothPlastic", false)
	for _, strip in { { -2.2, 0, 1, 7 }, { 2.2, 0, 1, 7 }, { 0, 0, 3.4, 1 } } do
		paint("HelipadH", { pad[1] + strip[1], pad[2] + strip[2] }, { strip[3], strip[4] }, "OffWhite", nil, roof + 0.1)
	end
	for _, dx in { -7, 7 } do
		Pieces.column("SignPost", { at[1] + dx, front - 3 }, roof, roof + 3, 0.4, "MetalDark", "Metal")
	end
	B.sign({
		Name = "RoofSign",
		Size = { 18, 4.4, 0.4 },
		Position = { at[1], roof + 5.2, front - 3 },
		Rotation = B.yaw("North"),
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Hotel",
		TextColor = "OffWhite",
		Glow = true,
		CanCollide = false,
	})
	waterTank({ at[1] - 8, at[2] - 10 }, roof)
end

--[[
	The department store behind the shop row: four floors (cosmetics counters, fashion racks and mannequins, homeware,
	a restaurant) up a stair to the roof, a glass ground floor onto the back lot, the DEPT. STORE sign. On the roof, an
	old-style rooftop playground: a Ferris wheel and a carousel (movers()), a ticket booth, AC units.
]]
local function deptStore()
	local at, size = DEPT.At, DEPT.Size
	local openings: { Rooms.Opening } = {
		{ Face = "+Z", At = 0, Width = 8, Height = 9 },
		{ Face = "+X", At = 0, Width = 6, Height = DOOR },
	}
	for _, spot in { -44, -30, -14, 14, 30, 44 } do
		table.insert(openings, { Face = "+Z", At = spot, Width = 12, Height = 7, Bottom = 0.6, Glass = true })
	end
	building({
		Name = "DeptStore",
		At = at,
		Size = size,
		Floors = DEPT.Floors,
		Storey = STOREY,
		Color = "OffWhite",
		FloorColor = "ConcreteLight",
		FloorMaterial = "Marble",
		Openings = openings,
		Windows = { Faces = { "+Z", "-Z" }, Width = 10, Height = 4.5, Sill = 2.5, Spacing = 16, From = 2 },
		Stair = { At = { -44, 0 }, Along = "Z", Width = 4 },
		Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
	})
	local north, south = at[2] + 16, at[2] - 16 -- two lines of displays on every floor
	for _, x in { -130, -110, -90, -70 } do
		local counter = Pieces.block("Counter", { x, north }, { 6, 3, 2 }, "Glass", "Glass")
		counter.Transparency = 0.4
		Pieces.block(
			"Rack",
			{ x - 5, south },
			{ 8, 4.5, 0.6 },
			if x % 40 == 10 then "ShopPink" else "CityBlue",
			"Fabric",
			STOREY
		)
		smallTable({ x, north }, 3 * STOREY)
	end
	for _, x in { -125, -85 } do
		upright("Mannequin", { x, north }, STOREY, 4.6, 1.2, "OffWhite", "SmoothPlastic")
		B.part({
			Name = "MannequinHead",
			Size = { 1.1, 1.1, 1.1 },
			Position = { x, STOREY + 5.2, north },
			Shape = "Ball",
			Color = "OffWhite",
			CanCollide = false,
		})
	end
	for _, x in { -130, -100 } do
		sofa({ x, south }, 2 * STOREY, 0, "WoodMid")
		Pieces.block("Display", { x, north }, { 6, 2.4, 3 }, "WoodDark", "Wood", 2 * STOREY)
	end
	faceSign(at, size, "+Z", 0, 11.5, 28, 1.6, "Map.Shinjuku.Sign.DeptStore", "OffWhite", "Black")
	-- The roof: the Ferris wheel's A-frame legs and axle, a ticket booth, AC units.
	local hub = { -80, DEPT_ROOF + 15.4, at[2] }
	for _, dz in { -3.2, 3.2 } do
		for _, dx in { -7, 7 } do
			local rise = hub[2] - DEPT_ROOF
			B.part({
				Name = "WheelLeg",
				Size = { 0.8, math.sqrt(dx * dx + rise * rise), 0.8 },
				Position = { hub[1] + dx / 2, DEPT_ROOF + rise / 2, hub[3] + dz },
				Rotation = { 0, 0, math.deg(math.atan2(dx, rise)) },
				Color = "OffWhite",
				Material = "Metal",
			})
		end
	end
	B.part({
		Name = "WheelAxle",
		Size = { 6.4, 0.8, 0.8 },
		Position = hub,
		Rotation = { 0, 90, 0 },
		Shape = "Cylinder",
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	Pieces.block("TicketBooth", { -108, at[2] + 18 }, { 5, 6, 4 }, "ShopYellow", "SmoothPlastic", DEPT_ROOF)
	acUnit({ -64, at[2] - 18 }, DEPT_ROOF)
	acUnit({ -64, at[2] + 18 }, DEPT_ROOF)
end

-- A mechanical parking rack by the avenue: two bays of three steel decks on yellow posts, cars parked up it, a ladder
-- to the top.
local function parkingRack()
	local at = { -34, -196 }
	B.model("ParkingRack", function()
		for _, dx in { -8, 0, 8 } do
			for _, dz in { -6.5, 6.5 } do
				Pieces.column("RackPost", { at[1] + dx, at[2] + dz }, 0, 22, 0.6, "LaneYellow", "Metal")
			end
		end
		for _, level in { 7, 14, 21 } do
			for _, dx in { -4, 4 } do
				Pieces.block(
					"RackDeck",
					{ at[1] + dx, at[2] },
					{ 7.4, 0.4, 13 },
					"MetalDark",
					"DiamondPlate",
					level - 0.4
				)
			end
		end
	end)
	car("RackCar1", { at[1] - 4, at[2] }, 0, "Red")
	car("RackCar2", { at[1] + 4, at[2] }, 0, "OffWhite", 7)
	car("RackCar3", { at[1] - 4, at[2] }, 0, "CityBlue", 14)
	ladder({ at[1] - 10, at[2] }, 0, 24)
end

--[[
	The building site in the south-east corner (a flat pocket park until 2026-10-28): a hoarding fence along the
	streets (its panels break) with a gate and the UNDER CONSTRUCTION board; a steel frame going up (columns, beams on
	every level; a full concrete deck at 10, two halves with a gap at 20, the east half at 30, bare beams at 40),
	ladders between the levels, scaffolding planks along its north face; the hoist up its east side and the tower crane
	turning over it (movers()); a two-storey site office, a stack of containers, a dirt mound with an excavator, pipes,
	a sand pile, a cement mixer, portable toilets, cones.
]]
local function buildingSite()
	local function fence(a: { number }, b: { number })
		local alongX = math.abs(b[1] - a[1]) >= math.abs(b[2] - a[2])
		local length = if alongX then math.abs(b[1] - a[1]) else math.abs(b[2] - a[2])
		local count = math.ceil(length / 15)
		for index = 1, count do
			local t = (index - 0.5) / count
			B.part({
				Name = "Hoarding",
				Size = if alongX then { length / count, 6, 0.3 } else { 0.3, 6, length / count },
				Position = { a[1] + (b[1] - a[1]) * t, 3, a[2] + (b[2] - a[2]) * t },
				Color = "OffWhite",
				Material = "Metal",
				Tags = BREAKABLE,
			})
		end
	end
	fence({ 188, -107 }, { 226, -107 })
	fence({ 238, -107 }, { 276, -107 })
	fence({ 188, -107.3 }, { 188, -226 })
	for _, x in { 226, 238 } do
		upright("GatePost", { x, -107 }, 0, 7, 0.5, "LaneYellow", "Metal")
	end
	B.sign({
		Name = "SiteBoard",
		Size = { 18, 3, 0.2 },
		Position = { 207, 3.6, -106.75 },
		Rotation = B.yaw("North"),
		Color = "CityBlue",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Construction",
		TextColor = "OffWhite",
		CanCollide = false,
	})
	-- The steel frame.
	local at, size, deck = SITE.At, SITE.Size, SITE.Deck
	local x0, x1, z0, z1 = at[1] - size[1] / 2, at[1] + size[1] / 2, at[2] - size[2] / 2, at[2] + size[2] / 2
	B.model("SteelFrame", function()
		for _, x in { x0, x0 + 15, x0 + 30, x0 + 45, x1 } do
			for _, z in { z0, at[2], z1 } do
				B.part({
					Name = "Column",
					Size = { 0.9, 4 * deck + 2, 0.9 },
					Position = { x, (4 * deck + 2) / 2, z },
					Color = "RustOrange",
					Material = "Metal",
				})
			end
		end
		for level = 1, 4 do
			local y = level * deck - 0.4
			for _, z in { z0, z1 } do
				B.part({
					Name = "Beam",
					Size = { size[1] + 0.8, 0.8, 0.8 },
					Position = { at[1], y, z },
					Color = "RustOrange",
					Material = "Metal",
				})
			end
			for _, x in { x0, x1 } do
				B.part({
					Name = "Beam",
					Size = { 0.8, 0.8, size[2] },
					Position = { x, y, at[2] },
					Color = "RustOrange",
					Material = "Metal",
				})
			end
		end
		for _, x in { x0 + 15, x0 + 30, x0 + 45 } do
			B.part({
				Name = "Beam",
				Size = { 0.8, 0.8, size[2] },
				Position = { x, 4 * deck - 0.4, at[2] },
				Color = "RustOrange",
				Material = "Metal",
			})
		end
		Pieces.block("Deck", at, { size[1], 0.6, size[2] }, "Concrete", "Concrete", deck - 0.6)
		Pieces.block("Deck", { x0 + 14, at[2] }, { 28, 0.6, size[2] }, "Concrete", "Concrete", 2 * deck - 0.6)
		Pieces.block("Deck", { x1 - 14, at[2] }, { 28, 0.6, size[2] }, "Concrete", "Concrete", 2 * deck - 0.6)
		Pieces.block("Deck", { x1 - 15, at[2] }, { 30, 0.6, size[2] }, "Concrete", "Concrete", 3 * deck - 0.6)
		-- Scaffolding along the north face: three plank walks on poles, halfway between the decks.
		for level = 0, 2 do
			local y = (level + 0.5) * deck
			Pieces.block("ScaffoldPlank", { at[1], z1 + 2.5 }, { size[1], 0.3, 3 }, "Wood", "WoodPlanks", y - 0.3)
		end
		for _, x in { x0, at[1], x1 } do
			upright("ScaffoldPole", { x, z1 + 4.2 }, 0, 3 * deck, 0.25, "Metal", "Metal", false)
		end
	end)
	ladder({ x0 - 1.5, at[2] - 10 }, 0, 12)
	ladder({ x0 - 1.5, at[2] + 10 }, deck, 12)
	ladder({ x1 - 31, z0 + 3 }, 2 * deck, 12) -- from the west half's deck up beside the east half's
	ladder({ x1 + 1, z1 - 5 }, 3 * deck, 12)
	-- The hoist's guide posts (the cage is a mover) and the crane's footing and mast (its top turns: movers()).
	for _, dz in { -3.2, 3.2 } do
		upright("HoistGuide", { x1 + 8.4, at[2] + dz }, 0, 3 * deck + 4, 0.3, "LaneYellow", "Metal", false)
	end
	local crane = CRANE.At
	Pieces.block("CraneFooting", crane, { 6, 2, 6 }, "Concrete", "Concrete")
	B.truss({
		Name = "CraneMast",
		Size = { 2, CRANE.Height, 2 },
		Position = { crane[1], 2 + CRANE.Height / 2, crane[2] },
		Color = "LaneYellow",
		Material = "Metal",
	})
	for _, dx in { -1.6, 1.6 } do
		for _, dz in { -1.6, 1.6 } do
			upright("MastChord", { crane[1] + dx, crane[2] + dz }, 2, CRANE.Height, 0.3, "LaneYellow", "Metal", false)
		end
	end
	Pieces.block("MastTop", crane, { 4, 0.6, 4 }, "LaneYellow", "Metal", 2 + CRANE.Height)
	-- The site office (a container with a cabin on top and a ladder up), materials.
	Pieces.container("SiteOffice", { 204, -124 }, { 14, 7, 6 }, 0, "OffWhite")
	Pieces.block("SiteOfficeTop", { 204, -124 }, { 14, 6, 6 }, "CityBlue", "Metal", 7)
	panel("OfficeWindow", { 204, -124 }, { 14, 6 }, "-Z", 0, 10, 7, 2.4, "Glass", "Glass")
	ladder({ 212, -122 }, 0, 14)
	for index, pipe in { { -121.6, 0.6 }, { -122.8, 0.6 }, { -122.2, 1.6 } } do
		B.part({
			Name = `Pipe{index}`,
			Size = { 10, 1.2, 1.2 },
			Position = { 226, pipe[2], pipe[1] },
			Shape = "Cylinder",
			Color = "MetalDark",
			Material = "Metal",
		})
	end
	for _, side in { -1, 1 } do
		B.part({
			Name = "SandPile",
			Size = { 10, 3.4, 4 },
			Position = { 252, 1.7, -122 + side * 2 },
			Rotation = { 0, if side < 0 then 0 else 180, 0 },
			Shape = "Wedge",
			Color = "CityTan",
			Material = "Sand",
		})
	end
	-- A stepped dirt mound and an excavator digging into it.
	for tier, width in { 14, 10, 6 } do
		Pieces.block("DirtMound", { 266, -214 }, { width, 2.4, width }, "Soil", "Ground", (tier - 1) * 2.4)
	end
	B.model("Excavator", function()
		for _, dx in { -3.75, 3.75 } do
			Pieces.block("Track", { 224 + dx, -218 }, { 3, 2, 12 }, "Black", "Metal")
		end
		Pieces.block("Body", { 224, -218.75 }, { 9, 4.5, 9 }, "LaneYellow", "Metal", 2)
		Pieces.block("Cab", { 221, -221 }, { 4, 4.5, 4 }, "LaneYellow", "Glass", 6.5)
		B.part({
			Name = "Boom",
			Size = { 1.5, 1.5, 12.6 },
			Position = { 224, 10, -208.25 },
			Rotation = { -33.3, 0, 0 },
			Color = "LaneYellow",
			Material = "Metal",
		})
		B.part({
			Name = "Arm",
			Size = { 1.2, 10, 1.2 },
			Position = { 224, 9, -200.75 },
			Rotation = { -26.6, 0, 0 },
			Color = "LaneYellow",
			Material = "Metal",
		})
		Pieces.block("Bucket", { 224, -198.5 }, { 3.6, 2.1, 2.4 }, "MetalDark", "Metal", 2.5)
	end)
	-- Two shipping containers stacked at the back of the site (a step up to the second one).
	Pieces.container("SiteContainer", { 242, -212 }, { 18, 7.5, 7.5 }, 0, "CityBlue")
	Pieces.container("SiteContainer", { 244, -212 }, { 18, 7.5, 7.5 }, 0, "RustOrange", 7.5)
	Pieces.block("MixerBase", { 264, -124 }, { 4, 1.6, 5 }, "MetalDark", "Metal")
	B.part({
		Name = "MixerDrum",
		Size = { 5, 3.6, 3.6 },
		Position = { 264, 3.6, -124 },
		Rotation = { 0, 90, 25 },
		Shape = "Cylinder",
		Color = "RustOrange",
		Material = "Metal",
	})
	for _, z in { -113, -118 } do
		Pieces.block("PortableToilet", { 272, z }, { 3.4, 7.5, 3.4 }, "CityBlue", "SmoothPlastic")
	end
	for _, spot in { { 232, -112 }, { 236, -114 }, { 216, -196 }, { 214, -201 } } do
		upright("Cone", spot, 0, 2.2, 1, "RustOrange", "SmoothPlastic", false)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Things that move (owner, 2026-10-28: "more dynamic"): Arena.mover models, from the arena origin
---------------------------------------------------------------------------------------------------------------------

local function movers()
	local vector = B.roblox.Vector3.new
	-- The towers' glass lifts on their north faces, from the street up to the roof's parapet (+112.4).
	for index, side in { -1, 1 } do
		local x, z = side * (TOWER.X + 11), TOWER.Z + TOWER.Size / 2 + 3.6
		Arena.mover(
			`TowerLift{index}`,
			{ x, 0.5, z },
			{ Kind = "Lift", Period = 30, Pause = 4, Offset = vector(0, TOWER_ROOF + 0.8, 0), Phase = index * 7 },
			function()
				B.part({
					Name = "LiftFloor",
					Size = { 6, 1, 6 },
					Position = { x, 0.5, z },
					Color = "MetalDark",
					Material = "DiamondPlate",
					CastShadow = true,
				})
				for _, wall in { { { -2.9, 0 }, { 0.2, 6 } }, { { 2.9, 0 }, { 0.2, 6 } }, { { 0, 2.9 }, { 5.6, 0.2 } } } do
					B.part({
						Name = "LiftGlass",
						Size = { wall[2][1], 4, wall[2][2] },
						Position = { x + wall[1][1], 3, z + wall[1][2] },
						Color = "Glass",
						Material = "Glass",
						Transparency = 0.5,
					})
				end
			end
		)
		for _, dx in { -3.4, 3.4 } do
			upright("LiftGuide", { x + dx, z + 3.4 }, 0, TOWER_ROOF + 4, 0.3, "MetalDark", "Metal", false)
		end
	end
	-- The building site's hoist: a cage up the frame's east side to the 24 deck.
	local site = SITE.At
	local hoist = { site[1] + SITE.Size[1] / 2 + 4.5, site[2] }
	Arena.mover("SiteHoist", { hoist[1], 0.5, hoist[2] }, {
		Kind = "Lift",
		Period = 16,
		Pause = 3,
		Offset = vector(0, 3 * SITE.Deck - 0.6, 0),
		Phase = 2,
	}, function()
		B.part({
			Name = "HoistFloor",
			Size = { 6, 1, 6 },
			Position = { hoist[1], 0.5, hoist[2] },
			Color = "LaneYellow",
			Material = "DiamondPlate",
			CastShadow = true,
		})
		Pieces.railing(
			"HoistRail",
			{ hoist[1] + 2.8, hoist[2] - 2.8 },
			{ hoist[1] + 2.8, hoist[2] + 2.8 },
			1,
			1.2,
			"LaneYellow"
		)
	end)
	-- The tower crane's top turning slowly: the jib with its trolley and a bundle of beams on the hook, the counter-jib
	-- and its weight, the cab, the tower head and its ties.
	local crane = CRANE.At
	local top = 2 + CRANE.Height + 0.6
	Arena.mover("CraneJib", { crane[1], top, crane[2] }, { Kind = "Spin", Period = 60, Phase = 0 }, function()
		upright("SlewRing", crane, top, 0.6, 3.6, "MetalDark", "Metal")
		local jibY = top + 1.2
		Pieces.block(
			"Jib",
			{ crane[1] + CRANE.Jib / 2, crane[2] },
			{ CRANE.Jib, 1.2, 1.6 },
			"LaneYellow",
			"Metal",
			top + 0.6
		)
		Pieces.block("CounterJib", { crane[1] - 8, crane[2] }, { 16, 1.2, 1.6 }, "LaneYellow", "Metal", top + 0.6)
		Pieces.block("Counterweight", { crane[1] - 14, crane[2] }, { 4, 3, 2.4 }, "Concrete", "Concrete", top - 2.4)
		Pieces.block("Cab", { crane[1], crane[2] - 2.6 }, { 3, 2.6, 3 }, "OffWhite", "SmoothPlastic", top + 0.6)
		Pieces.block("TowerHead", crane, { 1, 6, 1 }, "LaneYellow", "Metal", top + 1.8)
		local apex = top + 7.8
		for _, reach in { CRANE.Jib, -16 } do
			local dx, dy = reach, jibY + 0.6 - apex
			B.part({
				Name = "Tie",
				Size = { math.sqrt(dx * dx + dy * dy), 0.2, 0.2 },
				Position = { crane[1] + dx / 2, (apex + jibY + 0.6) / 2, crane[2] },
				Rotation = { 0, 0, math.deg(math.atan2(dy, dx)) },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
		local hook = crane[1] + 36
		Pieces.block("Trolley", { hook, crane[2] }, { 2, 0.6, 2 }, "MetalDark", "Metal", top)
		B.part({
			Name = "Cable",
			Size = { 0.1, 20, 0.1 },
			Position = { hook, top - 10, crane[2] },
			Color = "Black",
			CanCollide = false,
		})
		Pieces.block("BeamBundle", { hook, crane[2] }, { 8, 1.2, 2.2 }, "RustOrange", "Metal", top - 21.2)
	end)
	-- The pachinko parlor's sign, turning on a post on its roof.
	local parlor = PACHINKO.At
	local parlorRoof = 2 * STOREY + 0.6
	upright("SignMast", parlor, parlorRoof, 5, 0.6, "MetalDark", "Metal")
	Arena.mover("PachinkoSign", { parlor[1], parlorRoof + 5, parlor[2] }, { Kind = "Spin", Period = 10 }, function()
		for _, facing in { "North", "South" } do
			B.sign({
				Name = "SpinningSign",
				Size = { 14, 3.4, 0.4 },
				Position = { parlor[1], parlorRoof + 7, parlor[2] + (if facing == "North" then 0.21 else -0.21) },
				Rotation = B.yaw(facing),
				Color = "Black",
				Material = "SmoothPlastic",
				Key = "Map.Shinjuku.Sign.Pachinko",
				TextColor = "NeonPink",
				Glow = true,
				CanCollide = false,
			})
		end
		Pieces.block("SignFrame", parlor, { 14.4, 0.3, 1 }, "NeonTeal", "Neon", parlorRoof + 5.15).CanCollide = false
	end)
	-- The department store's rooftop Ferris wheel (spinning about Z: its pivot is tilted) and carousel.
	local hub = { -80, DEPT_ROOF + 15.4, DEPT.At[2] }
	local radius = 12
	Arena.mover("FerrisWheel", hub, { Kind = "Spin", Period = 40 }, function()
		B.part({
			Name = "Hub",
			Size = { 2.4, 2.4, 2.4 },
			Position = hub,
			Shape = "Ball",
			Color = "OffWhite",
			CanCollide = false,
		})
		for spoke = 0, 7 do
			local angle = spoke * 45
			local c, s = math.cos(math.rad(angle)), math.sin(math.rad(angle))
			B.part({
				Name = "Spoke",
				Size = { 0.3, radius, 0.3 },
				Position = { hub[1] + c * radius / 2, hub[2] + s * radius / 2, hub[3] },
				Rotation = { 0, 0, angle - 90 },
				Color = "OffWhite",
				Material = "Metal",
				CanCollide = false,
			})
			local mid = angle + 22.5
			local cm, sm = math.cos(math.rad(mid)), math.sin(math.rad(mid))
			local chord = radius * math.cos(math.rad(22.5))
			B.part({
				Name = "Rim",
				Size = { 2 * radius * math.sin(math.rad(22.5)), 0.4, 0.4 },
				Position = { hub[1] + cm * chord, hub[2] + sm * chord, hub[3] },
				Rotation = { 0, 0, mid + 90 },
				Color = "ShopPink",
				Material = "Metal",
				CanCollide = false,
			})
			B.part({
				Name = "Pod",
				Size = { 2.8, 2.8, 2.8 },
				Position = { hub[1] + c * radius, hub[2] + s * radius, hub[3] },
				Shape = "Ball",
				Color = ({ "ShopYellow", "ShopTeal", "ShopRed", "NeonPink" })[spoke % 4 + 1],
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
	end, { 90, 0, 0 })
	local ride = { -135, DEPT.At[2] }
	Arena.mover("Carousel", { ride[1], DEPT_ROOF, ride[2] }, { Kind = "Spin", Period = 14 }, function()
		upright("CarouselFloor", ride, DEPT_ROOF, 0.6, 14, "Cream", "WoodPlanks")
		upright("CarouselPole", ride, DEPT_ROOF + 0.6, 8.4, 1, "OldBrass", "Metal")
		upright("CarouselCanopy", ride, DEPT_ROOF + 9, 0.6, 15, "Red", "Fabric", false)
		for horse = 0, 5 do
			local angle = math.rad(horse * 60)
			local spot = { ride[1] + 5 * math.cos(angle), ride[2] + 5 * math.sin(angle) }
			upright("HorsePole", spot, DEPT_ROOF + 0.6, 8.4, 0.2, "OldBrass", "Metal", false)
			B.part({
				Name = "Horse",
				Size = { 1.2, 2, 3.4 },
				Position = { spot[1], DEPT_ROOF + 3.2, spot[2] },
				Rotation = { 0, -horse * 60, 0 },
				Color = if horse % 2 == 0 then "OffWhite" else "ShopYellow",
				Material = "SmoothPlastic",
			})
		end
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The district
---------------------------------------------------------------------------------------------------------------------

--[[
	The streets' furniture (owner, 2026-10-28: "add more overall entire detail then polish"): street lamps along every
	street, traffic signals at the crossings, road signs, manholes, fire hydrants, red post boxes, bollards along the
	plaza, nobori banners outside the bars, a phone booth by the police box, a yellow line along the district's edge.
]]
local function streetDetail()
	-- Lamps: the main street's north pavement, the second street's north kerb, both sides of the avenue, the strips.
	for _, x in { -245, -185, -125, -65, -5, 55, 115, 175, 235 } do
		Pieces.lamp("StreetLamp", { x, 104 }, 14, 0)
	end
	for _, x in { -240, -120, -40, 30, 120, 240 } do
		Pieces.lamp("StreetLamp", { x, -79 }, 14, 0)
	end
	for _, z in { -200, -150, -40, 40 } do
		Pieces.lamp("StreetLamp", { -12.5, z }, 14, -90)
	end
	for _, z in { -210, -165, -8 } do
		Pieces.lamp("StreetLamp", { 12.5, z }, 14, 90)
	end
	for _, spot in
		{ { 162.5, -45, -90 }, { 162.5, 60, -90 }, { 163, -150, -90 }, { -162.5, -40, 90 }, { -162.5, 60, 90 } }
	do
		Pieces.lamp("StreetLamp", { spot[1], spot[2] }, 14, spot[3])
	end
	Pieces.lamp("StreetLamp", { -187.5, -160 }, 14, -90)
	-- Signals at the six crossings, on two opposite corners of each.
	for _, cx in STREETS_X do
		for _, cz in STREETS_Z do
			trafficLight({ cx - 12, cz + 12 }, -1, -1)
			trafficLight({ cx + 12, cz - 12 }, 1, 1)
		end
	end
	for _, at in
		{ { -210, 86 }, { -60, 94 }, { 70, 86 }, { 210, 94 }, { -100, -86 }, { 100, -94 }, { 0, -130 }, { 0, 25 } }
	do
		upright("Manhole", at, 0.1, 0.04, 2.6, "MetalDark", "DiamondPlate", false)
	end
	for _, at in { { -90, 104 }, { 90, 104 }, { -150, -79 }, { 80, -79 }, { -12.5, -135 }, { 12.5, -120 } } do
		hydrant(at)
	end
	for _, at in { { -12.5, -10 }, { 20, 104 }, { 162.5, 20 } } do
		postBox(at)
	end
	for _, sign in
		{
			{ -186.5, 70, true },
			{ 186.5, 70, true },
			{ -12.5, 70, true },
			{ 12.5, 64, true },
			{ -186.5, -110, true },
			{ 186.5, -112, true },
		}
	do
		roadSign({ sign[1] :: number, sign[2] :: number }, sign[3] :: boolean)
	end
	-- Bollards along the plaza's street edges.
	for x = -155, -20, 15 do
		if math.abs(x + 35) > 1 then
			upright("Bollard", { x, -78.5 }, 0, 2.4, 0.6, "ConcreteDark", "Concrete")
		end
	end
	for _, z in { -70, -56, -28, -14, 0 } do
		upright("Bollard", { -11.5, z }, 0, 2.4, 0.6, "ConcreteDark", "Concrete")
	end
	-- Nobori banners outside the ramen shop, the pachinko parlor, the yokocho and the karaoke tower.
	for index, spot in
		{
			{ -146, 73.5 },
			{ -104, 73.5 },
			{ -97, 75 },
			{ -63, 75 },
			{ -163, 13 },
			{ -163, 31 },
			{ 63.5, 75 },
			{ 98.5, 75 },
		}
	do
		banner(spot, ({ "Red", "OffWhite", "LaneYellow", "TealDark" })[index % 4 + 1])
	end
	-- A phone booth by the police box.
	B.model("PhoneBooth", function()
		local booth = Pieces.block("Booth", { 13, -3 }, { 2.6, 6.5, 2.6 }, "Glass", "Glass")
		booth.Transparency = 0.5
		Pieces.block("BoothRoof", { 13, -3 }, { 3, 0.4, 3 }, "Lawn", "SmoothPlastic", 6.5)
		Pieces.block("Phone", { 13.8, -3 }, { 0.6, 1, 0.6 }, "Lawn", "SmoothPlastic", 3.6).CanCollide = false
	end)
	-- Paved pavements along both sides of every street (paler than the bare ground, under the buildings' floors).
	local pave = ROAD / 2 + 3.5
	for _, z in STREETS_Z do
		for _, side in { -1, 1 } do
			paint("Pavement", { 0, z + side * pave }, { DISTRICT[1], 7 }, "ConcreteLight", "Pavement", 0.03)
		end
	end
	for _, x in STREETS_X do
		for _, gap in GAPS_Z do
			for _, side in { -1, 1 } do
				paint(
					"Pavement",
					{ x + side * pave, (gap[1] + gap[2]) / 2 },
					{ 7, gap[2] - gap[1] },
					"ConcreteLight",
					"Pavement",
					0.03
				)
			end
		end
	end
	-- A yellow line along the district's edge, so the drop is easy to see.
	for _, line in
		{
			{ { 0, 108.5 }, { DISTRICT[1] - 3, 0.6 } },
			{ { 0, -228.5 }, { DISTRICT[1] - 3, 0.6 } },
			{ { 278.5, CENTER_Z }, { 0.6, DISTRICT[2] - 3 } },
			{ { -278.5, CENTER_Z }, { 0.6, DISTRICT[2] - 3 } },
		}
	do
		paint("EdgeLine", line[1], line[2], "LaneYellow", nil, 0.12)
	end
end

--[[
	The buildings' extras: outdoor air-conditioner units on the walls of the flats, the hotel, the shops, the karaoke
	tower and the department store; tall neon signs on the corners of the karaoke tower, the hotel, the ramen shop
	and the arcade, banners on the department store; antennas and satellite dishes on the roofs; the fountain's jet and
	flower beds round it; wooden grave stakes behind the gravestones.
]]
local function buildingDetail()
	for _, block in { { 45, 4 }, { -45, 5 } } do
		for floor = 2, block[2] do
			for _, dz in { -18, 18 } do
				wallAC({ 192, block[1] + dz }, "-X", (floor - 1) * STOREY + 1.05)
			end
		end
	end
	for floor = 2, HOTEL.Floors do
		for _, z in { -128, -144 } do
			wallAC({ HOTEL.At[1] + HOTEL.Size[1] / 2, z }, "+X", (floor - 1) * STOREY + 5)
		end
	end
	for _, x in { -147, -117, -87, -57, -27 } do
		for floor = 2, 3 do
			wallAC({ x - 10, SHOP_Z - 13 }, "-Z", (floor - 1) * STOREY + 5)
		end
	end
	for floor = 2, KARAOKE.Floors do
		for _, dx in { -16.5, 16.5 } do
			wallAC({ KARAOKE.At[1] + dx, KARAOKE.At[2] - KARAOKE.Size[2] / 2 }, "-Z", (floor - 1) * STOREY + 5)
		end
	end
	for floor = 2, DEPT.Floors do
		for _, z in { -175, -199 } do
			wallAC({ DEPT.At[1] + DEPT.Size[1] / 2, z }, "+X", (floor - 1) * STOREY + 5)
		end
	end
	for _, sign in
		{
			{ { 97.5, 72.5 }, { 1.6, 20, 0.4 }, 22, "NeonTeal" },
			{ { 150, -118.5 }, { 1.6, 26, 0.4 }, 32, "Red" },
			{ { -103.5, 70.5 }, { 1.4, 9, 0.3 }, 14, "Red" },
			{ { 86.5, -69.5 }, { 1.6, 14, 0.4 }, 12, "NeonPink" },
		}
	do
		B.part({
			Name = "VerticalSign",
			Size = sign[2],
			Position = { sign[1][1], sign[3], sign[1][2] },
			Color = sign[4],
			Material = "Neon",
			CanCollide = false,
		})
	end
	for index, x in { DEPT.At[1] - 48, DEPT.At[1] + 48 } do
		B.part({
			Name = "Banner",
			Size = { 3, 22, 0.3 },
			Position = { x, 22, DEPT.At[2] + DEPT.Size[2] / 2 + 0.4 },
			Color = if index == 1 then "ShopRed" else "CityBlue",
			Material = "Fabric",
			CanCollide = false,
		})
	end
	-- Antennas and dishes on the roofs.
	for _, side in { -1, 1 } do
		antenna({ side * TOWER.X + side * 3, TOWER.Z + 16 }, TOWER_ROOF)
	end
	antenna({ 148, -147 }, HOTEL_ROOF)
	for _, block in { { 62, 4 }, { -62, 5 } } do
		local roof = block[2] * STOREY + 0.6
		antenna({ 200, block[1] }, roof)
		dish({ 206, block[1] }, roof)
		dish({ 226, block[1] }, roof)
	end
	-- The fountain's jet and the water in its bowl, four flower beds round it.
	upright("FountainJet", { -100, -35 }, 5.8, 3.2, 0.5, "Glass", "Glass", false).Transparency = 0.35
	upright("BowlWater", { -100, -35 }, 5.75, 0.06, 5.4, "Glass", "Glass", false).Transparency = 0.3
	for _, bed in { { -86, -35, true }, { -114, -35, true }, { -100, -21, false }, { -100, -49, false } } do
		local alongZ = bed[3] :: boolean
		local spot = { bed[1] :: number, bed[2] :: number }
		Pieces.block("FlowerBed", spot, if alongZ then { 2.5, 1, 6 } else { 6, 1, 2.5 }, "ConcreteDark", "Concrete")
		B.part({
			Name = "Flowers",
			Size = if alongZ then { 2, 0.8, 5.4 } else { 5.4, 0.8, 2 },
			Position = { spot[1], 1.3, spot[2] },
			Color = "SakuraPink",
			Material = "LeafyGrass",
			CanCollide = false,
		})
	end
	for _, spot in { { -128, -45, 90 }, { -72, -25, -90 } } do
		Pieces.lamp("PlazaLamp", { spot[1], spot[2] }, 12, spot[3])
	end
	-- Wooden grave stakes (sotoba) behind the gravestones.
	for _, z in { -46, -37 } do
		for _, x in { 35, 39, 43, 47, 63, 67 } do
			B.part({
				Name = "GraveStake",
				Size = { 0.5, 3.6, 0.15 },
				Position = { x + 0.7, 1.8, z - 0.9 },
				Rotation = { 0, 0, 4 },
				Color = "Wood",
				Material = "WoodPlanks",
				CanCollide = false,
			})
		end
	end
end

-- A flat panel on a wall (a whiteboard, a painting, a menu, a screen): `size` (X, Y, Z) at `at` (x, y, z).
local function wallPanel(name: string, at: { number }, size: { number }, color: string, material: string?)
	B.part({
		Name = name,
		Size = size,
		Position = at,
		Color = color,
		Material = material or "SmoothPlastic",
		CanCollide = false,
	})
end

-- A small glowing ball (a hanging lamp, a lantern, a bulb).
local function glow(name: string, at: { number }, size: number, color: string)
	B.part({
		Name = name,
		Size = { size, size, size },
		Position = at,
		Shape = "Ball",
		Color = color,
		Material = "Neon",
		CanCollide = false,
	})
end

--[[
	More inside every building (owner, 2026-10-28: "add more detail inside buildings too, more polish"): filing
	cabinets, whiteboards and clocks in the offices, lift doors and a rug in the towers' lobbies; nightstands and
	carpet runners in the hotel; kitchens, fridges, rugs and wall TVs in the flats; tables and screens in the karaoke
	booths; goods on the mart's shelves, a freezer, a magazine rack and a cash machine; menu boards, hanging lamps and
	lanterns in the ramen shop, the bars' bottle shelves; the pachinko parlor's prize shelf and lamps; the cafe's
	stools, cake case, menu and rug; the arcade's neon floor stripe and air-hockey table; the mall's kiosks and plants;
	the bowling alley's snack counter and ball rack; the shops' goods, stock boxes, rugs and TVs; the department
	store's tills and floor signs; toilets in the cells; stage lights in the comedy club; flags and a clock in the
	court; a hose reel and a helmet shelf in the fire station; rugs, paintings and a chandelier in the mansion; altar
	candles and a lantern in the temple; the car park's pay machine and barriers; a map board in the police box; a
	shelf in the kiosk; a workbench in the garage.
]]
local function interiorDetail()
	-- The towers.
	for _, side in { -1, 1 } do
		local x0, z0 = side * TOWER.X, TOWER.Z
		for floor = 2, TOWER.Floors do
			local y = (floor - 1) * TOWER.Storey
			Pieces.block("FilingCabinet", { x0 + side * 18.3, z0 - 6 }, { 1.6, 4, 3 }, "CityGrey", "Metal", y)
			wallPanel("Whiteboard", { x0 - side * 4, y + 5, z0 - 19.1 }, { 6, 3, 0.1 }, "OffWhite")
			B.part({
				Name = "WallClock",
				Size = { 0.1, 1.4, 1.4 },
				Position = { x0, y + 7.5, z0 + 19.1 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Color = "OffWhite",
				CanCollide = false,
			})
		end
		for _, dz in { 10, 15 } do
			wallPanel("LiftDoor", { x0 - side * 19.15, 4, z0 + dz }, { 0.1, 8, 4 }, "Metal", "Metal")
		end
		paint("LobbyRug", { x0, z0 - 6 }, { 14, 10 }, "Red", "Carpet", 0.14)
	end
	-- The hotel: a nightstand by every bed, a carpet runner down every corridor.
	local hotelX0 = HOTEL.At[1] - 16
	for floor = 2, HOTEL.Floors do
		local y = (floor - 1) * STOREY
		for _, roomX in { hotelX0 + 5, hotelX0 + 15, hotelX0 + 25, hotelX0 + 35 } do
			Pieces.block("Nightstand", { roomX + 3.2, HOTEL.At[2] - 15 }, { 1.4, 2, 1.4 }, "WoodDark", "Wood", y)
			Pieces.block("Nightstand", { roomX + 3.2, HOTEL.At[2] + 15 }, { 1.4, 2, 1.4 }, "WoodDark", "Wood", y)
		end
		paint("Runner", { hotelX0 + 20, HOTEL.At[2] }, { 38, 3 }, "Red", "Carpet", y + 0.06)
	end
	-- The flats: a kitchen and a fridge along the lane wall, a rug, a TV on the partition.
	for _, block in { { 45, 4, 1 }, { -45, 5, -1 } } do
		local z, away = block[1], block[3]
		for floor = 1, block[2] do
			local y = (floor - 1) * STOREY
			Pieces.block("Kitchen", { 201.5, z - away * 19.8 }, { 6, 3.4, 2 }, "OffWhite", "Marble", y)
			Pieces.block("Fridge", { 196.5, z - away * 19.6 }, { 2.6, 5.4, 2.6 }, "OffWhite", "SmoothPlastic", y)
			paint(
				"Rug",
				{ 218, z + away * 12 },
				{ 8, 6 },
				if floor % 2 == 0 then "ShopTeal" else "ShopOrange",
				"Carpet",
				y + 0.08
			)
			wallPanel("WallTV", { 231.7, y + 4.5, z + away * 9 }, { 0.1, 2.4, 4 }, "Black")
		end
	end
	-- The karaoke booths: a low table and a glowing screen in each.
	local boothX0 = KARAOKE.At[1] - 8
	local booth = (KARAOKE.At[1] + KARAOKE.Size[1] / 2 - 0.8 - boothX0) / 3
	for floor = 2, KARAOKE.Floors do
		local y = (floor - 1) * STOREY
		for index = 0, 2 do
			local x = boothX0 + booth * (index + 0.5)
			Pieces.block("BoothTable", { x, KARAOKE.At[2] - 10 }, { 3, 1.6, 2 }, "Black", "SmoothPlastic", y)
			Pieces.block("BoothTable", { x, KARAOKE.At[2] + 10 }, { 3, 1.6, 2 }, "Black", "SmoothPlastic", y)
			-- The screen on each booth's east wall (the end booth's: the tower's own wall).
			local wallX = boothX0 + booth * (index + 1) - (if index == 2 then 0.05 else 0.25)
			wallPanel("KaraokeScreen", { wallX, y + 5, KARAOKE.At[2] - 9.5 }, { 0.1, 2.8, 4 }, "NeonTeal", "Neon")
			wallPanel("KaraokeScreen", { wallX, y + 5, KARAOKE.At[2] + 9.5 }, { 0.1, 2.8, 4 }, "NeonPink", "Neon")
		end
	end
	-- The mart: rows of goods on both faces of every shelf, a freezer, a magazine rack, a cash machine.
	local goods = { "ShopRed", "ShopYellow", "ShopTeal", "ShopOrange", "ShopPink", "CityBlue" }
	for index, dz in { -4, 2, 8 } do
		for side, offset in { -0.9, 0.9 } do
			wallPanel("Goods", { 127, 2.3, 55 + dz + offset }, { 19.6, 3.6, 0.2 }, goods[(index + side) % #goods + 1])
		end
	end
	Pieces.block("Freezer", { 108, 63 }, { 8, 3, 3 }, "OffWhite", "SmoothPlastic")
	Pieces.block("MagazineRack", { 140, 41.6 }, { 10, 4, 1 }, "WoodMid", "Wood")
	Pieces.block("CashMachine", { 145, 68.2 }, { 2, 5, 1.6 }, "CityBlue", "Metal")
	-- The ramen shop: a menu over the kitchen, lamps over the counter, lanterns upstairs; the bars' bottle shelves.
	wallPanel("Menu", { -122, 6.5, 40.9 }, { 10, 2.5, 0.1 }, "Cream", "Wood")
	for _, x in { -130, -122, -114 } do
		glow("CounterLamp", { x, 8.4, 49 }, 1, "WarmLight")
	end
	for _, x in { -124, -110 } do
		glow("PaperLantern", { x, STOREY + 8.2, 56 }, 1.4, "Red")
	end
	for _, side in { 1, -1 } do
		local back = YOKOCHO.LaneZ + side * (YOKOCHO.Lane / 2 + YOKOCHO.Depth - 0.9)
		for _, bay in { -23.5, -10.5, 2.5, 15.5, 28.5, 41.5 } do
			Pieces.block("BottleShelf", { YOKOCHO.X + bay, back }, { 6, 2.2, 0.5 }, "Bottle", "Glass", 5).CanCollide =
				false
		end
	end
	-- The pachinko parlor's prize shelf and jackpot lamps.
	Pieces.block("PrizeShelf", { -92.5, 70.4 }, { 8, 6, 1.2 }, "ShopYellow", "SmoothPlastic")
	for _, z in { 49, 55, 61 } do
		upright("JackpotLamp", { -94.5, z }, 4.6, 0.8, 0.7, "NeonPink", "Neon", false)
	end
	-- The cafe: counter stools, a cake case, a menu, a rug upstairs.
	for _, x in { -44, -40 } do
		upright("Stool", { x, -61.8 }, 0, 2.2, 1.2, "WoodDark", "Wood")
	end
	local case = Pieces.block("CakeCase", { -40, -65 }, { 4, 1.6, 1.6 }, "Glass", "Glass", 3)
	case.Transparency = 0.4
	case.CanCollide = false
	wallPanel("Menu", { -36, 6.5, -67.15 }, { 8, 2, 0.1 }, "WoodDark", "Wood")
	paint("Rug", { -40, -58 }, { 10, 8 }, "ShopOrange", "Carpet", STOREY + 0.08)
	-- The arcade's neon floor stripe and an air-hockey table upstairs.
	paint("NeonStripe", { 117, -50 }, { 50, 0.4 }, "NeonPink", "Neon", 0.13)
	Pieces.block("AirHockey", { 100, -44 }, { 4, 2.6, 7 }, "CityBlue", "SmoothPlastic", STOREY)
	-- The mall's kiosks and plants.
	for floor = 1, 2 do
		Pieces.block("Kiosk", { -215, 25 }, { 6, 3.4, 3 }, "ShopTeal", "SmoothPlastic", (floor - 1) * 11)
	end
	pottedPlant({ -245, 70 }, 0)
	pottedPlant({ -245, -20 }, 0)
	-- The bowling alley's snack counter and ball rack.
	Pieces.block("SnackCounter", { -197, -36 }, { 2, 3.4, 10 }, "ShopRed", "SmoothPlastic")
	Pieces.block("BallRack", { -211, -72 }, { 2, 2, 6 }, "MetalDark", "Metal")
	-- The shops: goods on the shelf, stock boxes upstairs, a rug and a TV on the top floor.
	for index, x in { -147, -117, -87, -57, -27 } do
		wallPanel("Goods", { x + 11.35, 2.3, SHOP_Z + 3 }, { 0.1, 3.2, 7.4 }, goods[index])
		Pieces.block("StockBox", { x + 10, SHOP_Z - 8 }, { 2.4, 2.4, 2.4 }, "Cardboard", "Cardboard", STOREY)
		Pieces.block("StockBox", { x + 11, SHOP_Z - 4.5 }, { 2, 2, 2 }, "Cardboard", "Cardboard", STOREY)
		paint("Rug", { x + 4, SHOP_Z + 4 }, { 8, 6 }, goods[(index + 2) % #goods + 1], "Carpet", 2 * STOREY + 0.08)
		wallPanel("WallTV", { x + 14.1, 2 * STOREY + 4.5, SHOP_Z + 6 }, { 0.1, 2.4, 4 }, "Black")
	end
	-- The department store's tills and a sign hanging over every floor.
	for _, x in { -120, -96 } do
		Pieces.block("Till", { x, DEPT.At[2] - 16 }, { 6, 3.4, 2 }, "WoodDark", "Wood")
	end
	for floor = 1, DEPT.Floors do
		wallPanel(
			"FloorSign",
			{ -108, floor * STOREY - 1.6, DEPT.At[2] },
			{ 10, 1.6, 0.2 },
			goods[floor],
			"SmoothPlastic"
		)
	end
	-- Toilets in the cells; stage lights in the comedy club; flags and a clock in the court.
	for _, x in { -250, -244 } do
		Pieces.block("Toilet", { x, -160 }, { 1.4, 1.6, 1.6 }, "OffWhite", "SmoothPlastic")
	end
	Pieces.block("LightRig", { -235, -209 }, { 40, 0.4, 0.4 }, "MetalDark", "Metal", 11.5).CanCollide = false
	for _, x in { -250, -240, -230, -220 } do
		Pieces.block("StageLight", { x, -209 }, { 1, 1.2, 1 }, "WarmLight", "Neon", 10.3).CanCollide = false
	end
	for index, x in { 51, 69 } do
		upright("FlagPole", { x, -164 }, 0, 9, 0.2, "OldBrass", "Metal", false)
		B.part({
			Name = "Flag",
			Size = { 3, 2, 0.05 },
			Position = { x + 1.6, 7.8, -164 },
			Color = if index == 1 then "OffWhite" else "CityBlue",
			Material = "Fabric",
			CanCollide = false,
		})
	end
	B.part({
		Name = "WallClock",
		Size = { 0.1, 1.6, 1.6 },
		Position = { 60, 12, -166.1 },
		Rotation = { 0, 90, 0 },
		Shape = "Cylinder",
		Color = "OffWhite",
		CanCollide = false,
	})
	-- The fire station's hose reel and helmet shelf.
	B.part({
		Name = "HoseReel",
		Size = { 0.6, 2.4, 2.4 },
		Position = { 80.7, 4, -204 },
		Shape = "Cylinder",
		Color = "Red",
		Material = "Metal",
		CanCollide = false,
	})
	wallPanel("HelmetShelf", { 40, 5, -221.05 }, { 8, 0.3, 1 }, "WoodDark", "Wood")
	for _, x in { 37.5, 40, 42.5 } do
		glow("Helmet", { x, 5.6, -221 }, 0.9, "LaneYellow")
	end
	-- The mansion: rugs, a chandelier.
	paint("Rug", { 142, -184 }, { 8, 6 }, "Red", "Carpet", 0.14)
	paint("Rug", { 143, -197 }, { 10, 6 }, "CityBlue", "Carpet", STOREY + 0.08)
	glow("Chandelier", { 142, 8.6, -184 }, 1.4, "WarmLight")
	-- The temple's candles and lantern.
	for _, dx in { -3, 3 } do
		upright("Candle", { 55 + dx, -66.5 }, 3.4, 0.8, 0.3, "WarmLight", "Neon", false)
	end
	glow("TempleLantern", { 55, 9.5, -60 }, 1.6, "Red")
	-- The car park's pay machine and the barriers at its car entrances.
	Pieces.block("PayMachine", { 154, -12 }, { 1.6, 5, 1.2 }, "CityBlue", "Metal")
	for _, z in { -3, 9 } do
		Pieces.block("Barrier", { 156.4, z }, { 0.3, 0.3, 8 }, "Red", "SmoothPlastic", 3).CanCollide = false
	end
	-- The police box's map board, the kiosk's shelf, the garage's workbench.
	wallPanel("MapBoard", { 27.15, 5, 6 }, { 0.1, 3, 5 }, "CityBlue", "SmoothPlastic")
	Pieces.block("Shelf", { 24, -18.6 }, { 5, 4, 1.2 }, "WoodMid", "Wood")
	Pieces.block("Workbench", { 106.6, -196 }, { 2.4, 3, 6 }, "WoodDark", "Wood")
end

--[[
	Roofs and eaves so the low buildings aren't flat boxes: tiled eaves along both rows of the yokocho and over the
	ramen shop's front, pitched tile roofs on the mansion, the garage and the police box, a pediment over the court's
	portico, canopies over the comedy club's, the mall's and the department store's doors.
]]
local function roofDetail()
	for _, side in { 1, -1 } do
		local face = YOKOCHO.LaneZ + side * YOKOCHO.Lane / 2
		B.part({
			Name = "Eave",
			Size = { YOKOCHO.Length, 0.4, 3 },
			Position = { YOKOCHO.X, 9.2, face - side * 1.3 },
			Rotation = { -side * 18, 0, 0 }, -- higher at the wall, lower over the lane
			Color = "AsphaltDark",
			Material = "ClayRoofTiles",
			CanCollide = false,
		})
	end
	B.part({
		Name = "Eave",
		Size = { 46, 0.4, 3 },
		Position = { -125, 10.9, 71.3 },
		Rotation = { 18, 0, 0 },
		Color = "AsphaltDark",
		Material = "ClayRoofTiles",
		CanCollide = false,
	})
	local function gable(name: string, at: { number }, size: { number }, y: number, color: string)
		for _, side in { -1, 1 } do
			B.part({
				Name = name,
				Size = { size[1], size[2], size[3] / 2 },
				Position = { at[1], y + size[2] / 2, at[2] + side * size[3] / 4 },
				Rotation = { 0, if side < 0 then 0 else 180, 0 }, -- each wedge's tall end toward the ridge
				Shape = "Wedge",
				Color = color,
				Material = "ClayRoofTiles",
			})
		end
	end
	gable("PitchedRoof", { 135, -190 }, { 44, 6, 32 }, 2 * STOREY + 0.6, "TempleRed")
	gable("PitchedRoof", { 100, -192 }, { 20, 3, 22 }, 9.6, "AsphaltDark")
	gable("PitchedRoof", { 22, 6 }, { 14, 2.4, 12 }, STOREY + 0.6, "AsphaltDark")
	-- The court's pediment: two wedges meeting over the middle of the portico.
	local front = -150 + 17
	for _, side in { -1, 1 } do
		B.part({
			Name = "Pediment",
			Size = { 1, 4, 26 },
			Position = { 60 + side * 13, 18, front + 2.5 },
			Rotation = { 0, -side * 90, 0 },
			Shape = "Wedge",
			Color = "OffWhite",
			Material = "Marble",
			CanCollide = false,
		})
	end
	Pieces.block("Canopy", { -235, -184 + 2 }, { 18, 0.4, 4 }, "Black", "Metal", 8.1).CanCollide = false
	Pieces.block("Canopy", { -192 + 3, 25 }, { 6, 0.3, 18 }, "CityBlue", "Metal", 9).CanCollide = false
	Pieces.block(
		"Canopy",
		{ DEPT.At[1], DEPT.At[2] + DEPT.Size[2] / 2 + 2.5 },
		{ 16, 0.4, 5 },
		"MetalDark",
		"Metal",
		9.1
	).CanCollide =
		false
end

local function district()
	streets()
	streetDetail()
	twinTowers()
	plaza()
	cafe()
	ramen()
	yokocho()
	pachinko()
	karaoke()
	mart()
	carPark()
	gasStation()
	koban()
	busStop({ 16, -45 })
	graveyard()
	arcade()
	mall()
	bowling()
	apartments("ApartmentsNorth", { 232, 45 }, 4, "Cream", "-Z")
	apartments("ApartmentsSouth", { 232, -45 }, 5, "CityGrey", "+Z")
	apartmentLane()
	vendingRow({ 250, -2 }, 3, 180)
	shopRow()
	deptStore()
	parkingRack()
	waterTower({ -30, -160 })
	jailAndClub()
	courtAndMansion()
	fireStation()
	hotel()
	buildingSite()
	buildingDetail()
	interiorDetail()
	roofDetail()
end

-- The pieces are written from the arena origin; the platform's own frame is at its centre (z CENTER_Z).
local function decorate(plat: Platform)
	assert(plat.Id == "Center", "Shinjuku has one platform")
	B.within({ 0, 0, -CENTER_Z }, district)
end

--[[
	Off the district: nothing round it (owner, 2026-10-28: "remove the boundary so players can fall dead"; until then
	invisible walls and a ring of city blocks closed it in). The ground ends in a cliff: under the street slab a layer of
	soil, then a face of rock going down into the abyss, the old arenas' dark mist fading to black far below. Fall past
	KillY (60 below the slab) and it's a KO.
]]
local function scenery(killY: number)
	-- A layer under the district from `top` down to `base`, `inset` in from its edges (walk-through: nothing to land on).
	local function layer(name: string, top: number, base: number, inset: number, color: string, material: string)
		B.part({
			Name = name,
			Size = { DISTRICT[1] - 2 * inset, top - base, DISTRICT[2] - 2 * inset },
			Position = { 0, (top + base) / 2, CENTER_Z },
			Color = color,
			Material = material,
			CanCollide = false,
			CastShadow = false,
		})
	end
	layer("Soil", -6, -18, 0.5, "Soil", "Ground")
	layer("Bedrock", -18, killY - 200, 1.5, "Bedrock", "Rock")
	for index, mist in
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
			Position = { 0, killY - mist[1], CENTER_Z },
			Color = mist[3],
			Material = "SmoothPlastic",
			Transparency = mist[2],
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- Builds the arena model at `origin` (world position of the district floor's centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery, movers)
end

return Layout
