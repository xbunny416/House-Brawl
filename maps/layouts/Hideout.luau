--!strict
--[[
	Lobby: "The Hideout" — an enclosed hideout lounge (owner's choices: a closed space instead of the open Rust Diner
	rooftop, 2026-10-16; 50% bigger and furnished like the reference pictures in docs/reference, 2026-10-19).

	Walls: grey-green plaster over dark wood wainscoting with a gold rail, dark wood pillars with white wall lamps,
	wood beams under a dark ceiling. Floor: a light carpet, wood planks in the bar.
	North: the bar — counter (Shop) with the bartender (Shop NPC), bottle shelves, map vote TVs hanging over the bar,
	news TVs on the counter ends, the title sign, bar stools. Booths in both north corners.
	East: the steel ARENA door with the join pad in front of it (QueueZone: only players standing on it are taken into
	the next round), barrels, a dartboard.
	West: Locker booth (Inventory), Codes jukebox, the cork quest board, a kitchen counter (sink, microwave, coffee
	machine) and two bunk beds in the south-west corner.
	South: three tall leaderboard boards, the spawn pads, vending machines and the street door.
	Middle: the lounge — a dark rug with a gold ring, a round black marble table on a gold base, a red sofa and two
	armchairs, floor lamps, potted topiaries — plus a pool table and high tables with stools.
	Seats (sofas, armchairs, booths, stools) are LobbySeat-tagged Seats: walk up and press the Sit prompt.
	Interactive objects carry CollectionService tags so code can attach prompts and UI.
]]
local B = require("../lib/Builder")

local Layout = {}

Layout.Id = "Hideout"
Layout.Lighting = "Dusk"

local INNER = { 138, 102 } -- X, Z: floor space inside the walls (92 × 68 until 2026-10-19: 50% bigger)
local HALF_X, HALF_Z = INNER[1] / 2, INNER[2] / 2
local HEIGHT = 28 -- floor to ceiling
local WALL = 2
local KILL_DEPTH = 40 -- falling this far below the floor returns you to a spawn
local WAINSCOT = 6 -- height of the wood panelling
local BAR_DEPTH = 40 -- the wood floor in front of the north wall

-- Join pad in front of the ARENA door (east wall).
local PAD_SIZE = { 14, 18 } -- X, Z
local PAD_X = HALF_X - 2 - PAD_SIZE[1] / 2

-- Unit vectors (X, Z) for a facing; "right" is the facing turned a quarter clockwise seen from above.
local FORWARD: { [string]: { number } } = { North = { 0, 1 }, South = { 0, -1 }, East = { 1, 0 }, West = { -1, 0 } }

-- World X / Z of a point `lx` to the right and `lz` forward of (x, z) for something facing `facing`.
local function place(x: number, z: number, facing: string, lx: number, lz: number): (number, number)
	local f = FORWARD[facing]
	return x + f[2] * lx + f[1] * lz, z - f[1] * lx + f[2] * lz
end

-- A flat disc lying on the floor (or on a table): a cylinder with its axis turned up.
local function disc(
	name: string,
	x: number,
	y: number,
	z: number,
	diameter: number,
	thickness: number,
	colorName: string,
	material: string?
)
	return B.part({
		Name = name,
		Size = { thickness, diameter, diameter },
		Position = { x, y, z },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = colorName,
		Material = material or "SmoothPlastic",
		CanCollide = false,
		CastShadow = false,
	})
end

---------------------------------------------------------------------------------------------------------------------
-- Room
---------------------------------------------------------------------------------------------------------------------

-- A dark wood pillar against a wall with a small white wall lamp; `lit` adds a soft light.
local function pillar(x: number, z: number, facing: string, lit: boolean)
	B.model("Pillar", function()
		B.part({
			Name = "Post",
			Size = { 2.4, HEIGHT, 2.4 },
			Position = { x, HEIGHT / 2, z },
			Color = "WoodDark",
			Material = "Wood",
			CastShadow = false,
		})
		local lampX, lampZ = place(x, z, facing, 0, 1.6)
		B.part({
			Name = "LampArm",
			Size = { 0.3, 0.3, 1.2 },
			Position = { lampX, 12, lampZ },
			Rotation = B.yaw(facing),
			Color = "Gold",
			Material = "Metal",
			CanCollide = false,
		})
		local shade = B.part({
			Name = "WallLamp",
			Size = { 1.3, 1.5, 1.3 },
			Position = { lampX, 12.9, lampZ },
			Color = "Shade",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		if lit then
			B.light(shade, "WarmLight", 14, 0.7)
		end
	end)
end

local function shell()
	B.slab({
		Name = "Floor",
		Size = { INNER[1] + WALL * 2, 4, INNER[2] + WALL * 2 },
		Position = { 0, 0, 0 },
		Color = "ConcreteDark",
		Material = "Concrete",
	})
	B.part({
		Name = "Carpet",
		Size = { INNER[1], 0.1, INNER[2] - BAR_DEPTH },
		Position = { 0, 0.05, -BAR_DEPTH / 2 },
		Color = "Carpet",
		Material = "Carpet",
		CanCollide = false,
		CastShadow = false,
	})
	B.part({
		Name = "BarFloor",
		Size = { INNER[1], 0.1, BAR_DEPTH },
		Position = { 0, 0.05, HALF_Z - BAR_DEPTH / 2 },
		Color = "Wood",
		Material = "WoodPlanks",
		CanCollide = false,
		CastShadow = false,
	})
	local wallY = (HEIGHT + 4) / 2 - 2 -- from below the floor slab up to the ceiling
	for _, wall in
		{
			{ name = "NorthWall", size = { INNER[1] + WALL * 2, HEIGHT + 4, WALL }, pos = { 0, HALF_Z + WALL / 2 } },
			{ name = "SouthWall", size = { INNER[1] + WALL * 2, HEIGHT + 4, WALL }, pos = { 0, -HALF_Z - WALL / 2 } },
			{ name = "EastWall", size = { WALL, HEIGHT + 4, INNER[2] }, pos = { HALF_X + WALL / 2, 0 } },
			{ name = "WestWall", size = { WALL, HEIGHT + 4, INNER[2] }, pos = { -HALF_X - WALL / 2, 0 } },
		}
	do
		B.part({
			Name = wall.name,
			Size = wall.size,
			Position = { wall.pos[1], wallY, wall.pos[2] },
			Color = "Plaster",
			Material = "Plaster",
			CastShadow = true,
		})
	end
	-- Wainscoting: dark wood up to WAINSCOT, raised panels, a gold rail on top.
	for _, side in
		{
			{ length = INNER[1], x = 0, z = HALF_Z - 0.25, alongX = true },
			{ length = INNER[1], x = 0, z = -HALF_Z + 0.25, alongX = true },
			{ length = INNER[2], x = HALF_X - 0.25, z = 0, alongX = false },
			{ length = INNER[2], x = -HALF_X + 0.25, z = 0, alongX = false },
		}
	do
		local function size(along: number, height: number, depth: number): { number }
			return if side.alongX then { along, height, depth } else { depth, height, along }
		end
		local inward = if side.alongX then -math.sign(side.z) else -math.sign(side.x)
		B.part({
			Name = "Wainscot",
			Size = size(side.length, WAINSCOT, 0.5),
			Position = { side.x, WAINSCOT / 2, side.z },
			Color = "WoodDark",
			Material = "Wood",
			CastShadow = false,
		})
		B.part({
			Name = "GoldRail",
			Size = size(side.length, 0.35, 0.8),
			Position = { side.x, WAINSCOT + 0.1, side.z },
			Color = "Gold",
			Material = "Metal",
			CastShadow = false,
		})
		local count = math.floor(side.length / 10)
		for index = 1, count do
			local along = -side.length / 2 + (index - 0.5) * side.length / count
			local x = if side.alongX then along else side.x + inward * 0.3
			local z = if side.alongX then side.z + inward * 0.3 else along
			B.part({
				Name = "Panel",
				Size = size(side.length / count - 2, WAINSCOT - 2.2, 0.2),
				Position = { x, WAINSCOT / 2, z },
				Color = "Brick",
				Material = "Wood",
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	B.part({
		Name = "Ceiling",
		Size = { INNER[1] + WALL * 2, 2, INNER[2] + WALL * 2 },
		Position = { 0, HEIGHT + 1, 0 },
		Color = "Black",
		Material = "Plaster",
		CastShadow = true,
	})
	for _, z in { -34, -17, 0, 17, 34 } do
		B.part({
			Name = "Beam",
			Size = { INNER[1], 1.6, 1.4 },
			Position = { 0, HEIGHT - 0.8, z },
			Color = "WoodDark",
			Material = "Wood",
		})
	end
	-- Pillars along the walls; the east / west ones carry lit wall lamps.
	for _, z in { -34, -17, 17, 34 } do
		pillar(HALF_X - 1.2, z, "West", true)
		pillar(-HALF_X + 1.2, z, "East", true)
	end
	for _, x in { -46, 46 } do
		pillar(x, HALF_Z - 1.2, "South", false)
		pillar(x, -HALF_Z + 1.2, "North", false)
	end
end

-- A lamp hanging from the ceiling: gold shade, dim amber bulb, warm light.
local function lamp(at: { number }, lightColor: string, range: number)
	B.model("Lamp", function()
		B.part({
			Name = "Cord",
			Size = { 0.15, HEIGHT - at[2], 0.15 },
			Position = { at[1], (HEIGHT + at[2]) / 2, at[3] },
			Color = "Black",
			CanCollide = false,
		})
		B.part({
			Name = "Shade",
			Size = { 1.2, 2.6, 2.6 },
			Position = { at[1], at[2], at[3] },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Gold",
			Material = "Metal",
			CanCollide = false,
		})
		local bulb = B.part({
			Name = "Bulb",
			Size = { 0.9, 0.9, 0.9 },
			Position = { at[1], at[2] - 0.7, at[3] },
			Shape = "Ball",
			Color = "Amber",
			Material = "Neon",
			CanCollide = false,
		})
		B.light(bulb, lightColor, range, 1.3)
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- Furniture (the reference pictures' style)
---------------------------------------------------------------------------------------------------------------------

--[[
	A sofa (or an armchair with seats = 1, or a booth bench) at (x, z) whose sitters look `facing`: a base on short gold
	legs, one Seat cushion per seat, a back and two arms.
]]
local function sofa(name: string, x: number, z: number, facing: string, seats: number, colorName: string)
	local width = seats * 2.8 + 1.2
	local yaw = B.yaw(facing)
	B.model(name, function()
		local function piece(partName: string, size: { number }, lx: number, y: number, lz: number)
			local px, pz = place(x, z, facing, lx, lz)
			B.part({
				Name = partName,
				Size = size,
				Position = { px, y, pz },
				Rotation = yaw,
				Color = colorName,
				Material = "Fabric",
			})
		end
		piece("Base", { width, 1.2, 3.4 }, 0, 0.9, 0)
		piece("Back", { width - 1.2, 2.8, 0.9 }, 0, 2.9, -1.25)
		for _, side in { -1, 1 } do
			piece("Arm", { 0.6, 1.7, 3.4 }, side * (width / 2 - 0.3), 2.35, 0)
			for _, end_ in { -1, 1 } do
				local lx, lz = place(x, z, facing, side * (width / 2 - 0.4), end_ * 1.3)
				B.part({
					Name = "Leg",
					Size = { 0.4, 0.3, 0.4 },
					Position = { lx, 0.15, lz },
					Color = "Gold",
					Material = "Metal",
				})
			end
		end
		for index = 1, seats do
			local sx, sz = place(x, z, facing, (index - (seats + 1) / 2) * 2.8, 0.3)
			B.seat({
				Name = `Cushion{index}`,
				Size = { 2.7, 0.7, 2.6 },
				Position = { sx, 1.85, sz },
				Rotation = yaw,
				Color = colorName,
				Material = "Fabric",
			})
		end
	end)
end

-- A round black marble table on a gold pedestal.
local function coffeeTable(x: number, z: number)
	B.model("CoffeeTable", function()
		B.part({
			Name = "Top",
			Size = { 0.4, 6.5, 6.5 },
			Position = { x, 2.4, z },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Marble",
			Material = "Marble",
		})
		B.part({
			Name = "Pedestal",
			Size = { 2, 0.7, 0.7 },
			Position = { x, 1.2, z },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Gold",
			Material = "Metal",
		})
		disc("Foot", x, 0.25, z, 3.2, 0.3, "Gold", "Metal")
	end)
end

-- A dark rug with a gold ring around the table.
local function rug(x: number, z: number, sizeX: number, sizeZ: number)
	B.part({
		Name = "Rug",
		Size = { sizeX, 0.1, sizeZ },
		Position = { x, 0.12, z },
		Color = "Rug",
		Material = "Carpet",
		CanCollide = false,
		CastShadow = false,
	})
	disc("RugRing", x, 0.15, z, 14, 0.1, "Gold", "Fabric")
	disc("RugInner", x, 0.17, z, 12, 0.1, "Rug", "Carpet")
end

-- A floor lamp: black foot, thin gold pole, white shade that lights the corner.
local function floorLamp(x: number, z: number)
	B.model("FloorLamp", function()
		disc("Foot", x, 0.15, z, 1.8, 0.3, "Black")
		B.part({
			Name = "Pole",
			Size = { 0.25, 7.4, 0.25 },
			Position = { x, 3.9, z },
			Color = "Gold",
			Material = "Metal",
			CanCollide = false,
		})
		local shade = B.part({
			Name = "Shade",
			Size = { 1.8, 2.4, 2.4 },
			Position = { x, 8.1, z },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Shade",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.light(shade, "WarmLight", 18, 1)
	end)
end

-- A potted topiary: black pot with a gold rim, a short trunk, a ball of leaves.
local function plant(x: number, z: number)
	B.model("Plant", function()
		B.part({
			Name = "Pot",
			Size = { 2.4, 3, 3 },
			Position = { x, 1.2, z },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Black",
			Material = "SmoothPlastic",
		})
		disc("Rim", x, 2.45, z, 3.2, 0.2, "Gold", "Metal")
		B.part({
			Name = "Trunk",
			Size = { 0.4, 3, 0.4 },
			Position = { x, 3.9, z },
			Color = "Wood",
			Material = "Wood",
			CanCollide = false,
		})
		B.part({
			Name = "Leaves",
			Size = { 4.6, 4.6, 4.6 },
			Position = { x, 7.2, z },
			Shape = "Ball",
			Color = "Leaf",
			Material = "LeafyGrass",
			CanCollide = false,
		})
	end)
end

-- A vending machine against a wall, front facing `facing`: dark body, red sign, colorful shelves behind glass.
local function vendingMachine(name: string, x: number, z: number, facing: string)
	local yaw = B.yaw(facing)
	B.model(name, function()
		local function piece(
			partName: string,
			size: { number },
			lx: number,
			y: number,
			lz: number,
			colorName: string,
			material: string?,
			neon: boolean?
		)
			local px, pz = place(x, z, facing, lx, lz)
			return B.part({
				Name = partName,
				Size = size,
				Position = { px, y, pz },
				Rotation = yaw,
				Color = colorName,
				Material = if neon then "Neon" else material or "SmoothPlastic",
				CanCollide = partName == "Body",
			})
		end
		piece("Body", { 5, 9, 3.4 }, 0, 4.5, 0, "Black", "Metal")
		piece("Sign", { 4.6, 1.2, 0.2 }, 0, 8.1, 1.75, "VendRed")
		local glow = piece("SignLight", { 3.8, 0.6, 0.1 }, 0, 8.1, 1.88, "OffWhite", nil, true)
		B.light(glow, "OffWhite", 10, 0.6)
		piece("Glass", { 3.2, 5.6, 0.1 }, -0.7, 4.6, 1.75, "Glass", "Glass")
		for row = 1, 4 do
			for column = 1, 4 do
				local colors = { "NeonPink", "LaneYellow", "NeonTeal", "VendRed", "Leaf" }
				piece(
					`Snack{row}{column}`,
					{ 0.6, 0.9, 0.5 },
					-1.85 + column * 0.7,
					2.3 + row * 1.25,
					1.4,
					colors[(row + column) % #colors + 1]
				)
			end
		end
		piece("Keypad", { 0.9, 2, 0.15 }, 1.75, 5.4, 1.75, "MetalDark", "Metal")
	end)
end

-- A black metal bunk bed against the south wall (long side along X).
local function bunkBed(name: string, x: number, z: number, blanket: string)
	B.model(name, function()
		for _, dx in { -4.4, 4.4 } do
			for _, dz in { -2, 2 } do
				B.part({
					Name = "Post",
					Size = { 0.5, 12, 0.5 },
					Position = { x + dx, 6, z + dz },
					Color = "Black",
					Material = "Metal",
				})
			end
		end
		for _, y in { 2.4, 7.8 } do
			B.part({
				Name = "Frame",
				Size = { 9.2, 0.5, 4.4 },
				Position = { x, y - 0.6, z },
				Color = "Black",
				Material = "Metal",
			})
			B.part({
				Name = "Mattress",
				Size = { 8.6, 1, 4 },
				Position = { x, y + 0.15, z },
				Color = "Mattress",
				Material = "Fabric",
			})
			B.part({
				Name = "Blanket",
				Size = { 5.8, 0.3, 4.1 },
				Position = { x + 1.3, y + 0.8, z },
				Color = blanket,
				Material = "Fabric",
				CanCollide = false,
			})
			B.part({
				Name = "Pillow",
				Size = { 1.8, 0.7, 3 },
				Position = { x - 3.2, y + 0.95, z },
				Color = "OffWhite",
				Material = "Fabric",
				CanCollide = false,
			})
		end
		B.part({
			Name = "Rail",
			Size = { 9.2, 0.3, 0.3 },
			Position = { x, 10, z + 2 },
			Color = "Black",
			Material = "Metal",
			CanCollide = false,
		})
		for index = 1, 4 do
			B.part({
				Name = "Rung",
				Size = { 0.25, 0.25, 1.6 },
				Position = { x + 4.4, 2.4 + index * 1.4, z + 2.9 },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
		for _, dz in { 2.1, 3.7 } do
			B.part({
				Name = "LadderSide",
				Size = { 0.25, 8, 0.25 },
				Position = { x + 4.4, 5.6, z + dz },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
	end)
end

-- A kitchen counter along the west wall: white cabinets, dark top, sink, microwave, coffee machine.
local function kitchen(x: number, zFrom: number, zTo: number)
	local length = zTo - zFrom
	local z = (zFrom + zTo) / 2
	B.model("Kitchen", function()
		B.part({
			Name = "Cabinets",
			Size = { 3, 3.6, length },
			Position = { x, 1.8, z },
			Color = "Cabinet",
			Material = "SmoothPlastic",
		})
		for index = 1, math.floor(length / 3) do
			B.part({
				Name = "Handle",
				Size = { 0.2, 1.2, 0.2 },
				Position = { x + 1.55, 2.2, zFrom + (index - 0.5) * 3 },
				Color = "Metal",
				Material = "Metal",
				CanCollide = false,
			})
		end
		B.part({
			Name = "Top",
			Size = { 3.4, 0.4, length + 0.4 },
			Position = { x, 3.8, z },
			Color = "Countertop",
			Material = "Granite",
		})
		B.part({
			Name = "Sink",
			Size = { 2, 0.15, 3 },
			Position = { x, 4.05, zFrom + 4 },
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		})
		B.part({
			Name = "Faucet",
			Size = { 0.3, 1.6, 0.3 },
			Position = { x - 1.2, 4.8, zFrom + 4 },
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		})
		B.part({
			Name = "Microwave",
			Size = { 2.4, 1.6, 3 },
			Position = { x - 0.2, 4.8, zFrom + 9 },
			Color = "Black",
			Material = "Metal",
		})
		B.part({
			Name = "MicrowaveDoor",
			Size = { 0.1, 1.1, 2 },
			Position = { x + 1.05, 4.8, zFrom + 8.7 },
			Color = "Glass",
			Material = "Glass",
			CanCollide = false,
		})
		B.part({
			Name = "CoffeeMachine",
			Size = { 2, 2.8, 1.8 },
			Position = { x - 0.3, 5.4, zFrom + 13 },
			Color = "Black",
			Material = "SmoothPlastic",
		})
		B.part({
			Name = "CoffeePot",
			Size = { 1, 0.9, 0.9 },
			Position = { x + 0.4, 4.6, zFrom + 13 },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.3,
			CanCollide = false,
		})
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- Gameplay spots
---------------------------------------------------------------------------------------------------------------------

-- An old CRT TV: dark casing, glowing screen that lights the bar a little.
local function tv(name: string, at: { number }, size: { number }, voteKind: string, index: number)
	B.model(name, function()
		B.part({
			Name = "Casing",
			Size = size,
			Position = at,
			Color = "MetalDark",
			Material = "SmoothPlastic",
		})
		local screen = B.part({
			Name = "Screen",
			Size = { size[1] * 0.8, size[2] * 0.75, 0.2 },
			Position = { at[1], at[2] + 0.2, at[3] - size[3] / 2 - 0.1 },
			Color = "CrtGlow",
			Material = "Neon",
			-- "News" TVs show the lobby news (the mode vote TVs until Classic became the only mode, 2026-10-19).
			Tags = { if voteKind == "News" then "NewsScreen" else "VoteScreen" },
			Attributes = { VoteKind = voteKind, Index = index },
		})
		B.light(screen, "CrtGlow", 10, 0.8)
		for _, side in { -1, 1 } do
			B.part({
				Name = "Antenna",
				Size = { 0.2, 3, 0.2 },
				Position = { at[1] + side * 0.8, at[2] + size[2] / 2 + 1.3, at[3] },
				Rotation = { 0, 0, side * -25 },
				Color = "Metal",
				Material = "Metal",
			})
		end
	end)
end

local function bar()
	local wallZ = HALF_Z
	local width = 48
	B.sign({
		Name = "TitleSign",
		Size = { 46, 5, 0.6 },
		Position = { 0, 23, wallZ - 0.6 },
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Title",
		TextColor = "NeonPink",
		Glow = true,
	})
	-- Back bar: cabinet, shelves and bottles.
	B.part({
		Name = "BackCabinet",
		Size = { width, 4, 2.4 },
		Position = { 0, 2, wallZ - 1.7 },
		Color = "WoodDark",
		Material = "Wood",
	})
	for row, y in { 7.5, 10.5, 13.5 } do
		B.part({
			Name = "Shelf",
			Size = { width, 0.3, 1.6 },
			Position = { 0, y, wallZ - 1.3 },
			Color = "Gold",
			Material = "Metal",
		})
		for index = 1, 16 do
			local colors = { "Bottle", "Amber", "Glass", "NeonTeal" }
			B.part({
				Name = "Bottle",
				Size = { 1.4, 0.55, 0.55 },
				Position = { -22.5 + (index - 1) * 3, y + 0.85, wallZ - 1.3 },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = colors[(index + row) % #colors + 1],
				Material = "Glass",
				Transparency = 0.15,
				CanCollide = false,
			})
		end
	end

	-- The counter (Shop).
	local counterZ = wallZ - 12
	B.part({
		Name = "CounterBase",
		Size = { width, 3.5, 3 },
		Position = { 0, 1.75, counterZ },
		Color = "WoodDark",
		Material = "WoodPlanks",
		Tags = { "ShopCounter" },
	})
	B.part({
		Name = "CounterTop",
		Size = { width + 1, 0.4, 4 },
		Position = { 0, 3.7, counterZ },
		Color = "Marble",
		Material = "Marble",
	})
	B.part({
		Name = "FootRail",
		Size = { width, 0.35, 0.35 },
		Position = { 0, 0.7, counterZ - 2 },
		Shape = "Cylinder",
		Color = "Gold",
		Material = "Metal",
		CanCollide = false,
	})
	B.sign({
		Name = "ShopSign",
		Size = { 10, 2, 0.2 },
		Position = { 0, 1.9, counterZ - 1.6 },
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Shop",
		TextColor = "NeonOrange",
		Glow = true,
	})
	-- Bar stools: sit facing the counter.
	for index = 1, 8 do
		local x = -21 + (index - 1) * 6
		B.part({
			Name = `StoolPole{index}`,
			Size = { 0.6, 2.2, 0.6 },
			Position = { x, 1.1, counterZ - 4 },
			Color = "Gold",
			Material = "Metal",
		})
		B.seat({
			Name = `Stool{index}`,
			Size = { 2, 0.5, 2 },
			Position = { x, 2.45, counterZ - 4 },
			Rotation = B.yaw("North"),
			Color = "Sofa",
			Material = "Leather",
		})
	end

	-- Map vote TVs hang over the bar; news TVs stand on the counter ends.
	for index, x in { -16, 0, 16 } do
		tv(`MapTV{index}`, { x, 15, counterZ }, { 8, 6.5, 5 }, "Map", index)
		B.part({
			Name = "TVMount",
			Size = { 0.4, HEIGHT - 18.25, 0.4 },
			Position = { x, (HEIGHT + 18.25) / 2, counterZ },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
	end
	for index, x in { -21.5, 21.5 } do
		tv(`NewsTV{index}`, { x, 5.9, counterZ }, { 5, 4, 4 }, "News", index)
	end

	-- Placeholder Shop NPC (the bartender) behind the counter.
	local npcZ = counterZ + 3.5
	B.model("ShopNPC", function()
		for _, x in { -0.55, 0.55 } do
			B.part({ Name = "Leg", Size = { 1, 2.6, 1 }, Position = { x, 1.3, npcZ }, Color = "TealDark" })
		end
		B.part({ Name = "Torso", Size = { 2.4, 2.6, 1.2 }, Position = { 0, 3.9, npcZ }, Color = "Black" })
		B.part({ Name = "Apron", Size = { 2, 2.4, 0.1 }, Position = { 0, 3.7, npcZ - 0.65 }, Color = "OffWhite" })
		for _, x in { -1.6, 1.6 } do
			B.part({ Name = "Arm", Size = { 0.8, 2.4, 0.8 }, Position = { x, 3.9, npcZ }, Color = "DustyPink" })
		end
		B.part({
			Name = "Head",
			Size = { 1.6, 1.6, 1.6 },
			Position = { 0, 6.05, npcZ },
			Shape = "Ball",
			Color = "DustyPink",
		})
		B.part({ Name = "Bandana", Size = { 1.7, 0.45, 1.7 }, Position = { 0, 6.6, npcZ }, Color = "RustOrange" })
	end, { Role = "Shop" }):AddTag("ShopNPC")

	-- Between the TVs, not in front of them.
	for _, x in { -8, 8 } do
		lamp({ x, 19.5, counterZ - 5 }, "WarmLight", 28)
	end
end

local function arenaDoor()
	local x = HALF_X - 0.3
	B.model("ArenaDoor", function()
		B.part({
			Name = "Door",
			Size = { 0.6, 14, PAD_SIZE[2] },
			Position = { x, 7, 0 },
			Color = "MetalDark",
			Material = "CorrodedMetal",
		})
		for index = 1, 6 do
			B.part({
				Name = "Rib",
				Size = { 0.3, 0.4, PAD_SIZE[2] },
				Position = { x - 0.4, index * 2, 0 },
				Color = "Metal",
				Material = "Metal",
				CanCollide = false,
			})
		end
		for _, side in { -1, 1 } do
			B.part({
				Name = "Frame",
				Size = { 1.2, 15, 1.2 },
				Position = { x - 0.3, 7.5, side * (PAD_SIZE[2] / 2 + 0.6) },
				Color = "LaneYellow",
				Material = "Metal",
			})
		end
		B.part({
			Name = "Lintel",
			Size = { 1.2, 1.2, PAD_SIZE[2] + 2.4 },
			Position = { x - 0.3, 14.6, 0 },
			Color = "LaneYellow",
			Material = "Metal",
		})
		B.sign({
			Name = "ArenaSign",
			Size = { 14, 3, 0.4 },
			Position = { x - 1, 17.4, 0 },
			Rotation = B.yaw("West"),
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Lobby.Sign.Arena",
			TextColor = "NeonOrange",
			Glow = true,
		})
	end):AddTag("ArenaDoor")

	-- The join pad: standing on it = in the next round (RoundService). Visible and walk-through.
	local pad = B.part({
		Name = "JoinPad",
		Size = { PAD_SIZE[1], 0.2, PAD_SIZE[2] },
		Position = { PAD_X, 0.1, 0 },
		Color = "NeonOrange",
		Material = "Neon",
		Transparency = 0.45,
		CanCollide = false,
		CastShadow = false,
		Tags = { "QueueZone" },
	})
	B.light(pad, "NeonOrange", 18, 1.2)
	-- Hazard border around the pad.
	for _, edge in
		{
			{ size = { PAD_SIZE[1] + 1.2, 0.12, 0.6 }, pos = { PAD_X, PAD_SIZE[2] / 2 + 0.3 } },
			{ size = { PAD_SIZE[1] + 1.2, 0.12, 0.6 }, pos = { PAD_X, -PAD_SIZE[2] / 2 - 0.3 } },
			{ size = { 0.6, 0.12, PAD_SIZE[2] }, pos = { PAD_X - PAD_SIZE[1] / 2 - 0.3, 0 } },
		}
	do
		B.part({
			Name = "PadBorder",
			Size = edge.size,
			Position = { edge.pos[1], 0.06, edge.pos[2] },
			Color = "LaneYellow",
			Material = "SmoothPlastic",
			CanCollide = false,
			CastShadow = false,
		})
	end
	-- "Stand here" signs on posts at both front corners of the pad, facing the room.
	for _, side in { -1, 1 } do
		local signX, signZ = PAD_X - PAD_SIZE[1] / 2 - 1.5, side * (PAD_SIZE[2] / 2 + 1.5)
		B.part({
			Name = "JoinSignPost",
			Size = { 0.5, 4, 0.5 },
			Position = { signX, 2, signZ },
			Color = "Metal",
			Material = "Metal",
		})
		B.sign({
			Name = "JoinSign",
			Size = { 7, 2.4, 0.3 },
			Position = { signX, 5.2, signZ },
			Rotation = B.yaw("West"),
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Lobby.Sign.Join",
			TextColor = "NeonOrange",
			Glow = true,
		})
	end
	-- Barrels beside the door, a dartboard further along the wall.
	for index, z in { PAD_SIZE[2] / 2 + 4, -PAD_SIZE[2] / 2 - 4 } do
		B.part({
			Name = `Barrel{index}`,
			Size = { 4, 2.6, 2.6 },
			Position = { HALF_X - 2.2, 2, z },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = if index == 1 then "RustOrange" else "Teal",
			Material = "CorrodedMetal",
		})
	end
	B.part({
		Name = "Dartboard",
		Size = { 0.3, 2.6, 2.6 },
		Position = { HALF_X - 0.2, 9, 26 },
		Shape = "Cylinder",
		Color = "Black",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
end

local function locker()
	local x, z = -HALF_X + 6.5, 25.5 -- between the wall pillars at z 17 and 34
	B.model("Locker", function()
		B.part({
			Name = "Back",
			Size = { 1, 10, 12 },
			Position = { x - 5.5, 5, z },
			Color = "WoodDark",
			Material = "Wood",
		})
		for _, side in { -1, 1 } do
			B.part({
				Name = "Side",
				Size = { 10, 10, 1 },
				Position = { x, 5, z + side * 6 },
				Color = "WoodDark",
				Material = "Wood",
			})
		end
		B.part({ Name = "Top", Size = { 12, 1, 14 }, Position = { x, 10.5, z }, Color = "Gold", Material = "Metal" })
		for index = 1, 5 do
			B.part({
				Name = "LockerDoor",
				Size = { 1.6, 7, 2 },
				Position = { x - 4.2, 3.5, z + (index - 3) * 2.2 },
				Color = if index % 2 == 0 then "Teal" else "TealDark",
				Material = "DiamondPlate",
			})
		end
		B.sign({
			Name = "LockerSign",
			Size = { 10, 2.2, 0.4 },
			Position = { x + 4.8, 12.3, z },
			Rotation = B.yaw("East"),
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Lobby.Sign.Locker",
			TextColor = "NeonTeal",
			Glow = true,
		})
	end):AddTag("Locker")
end

local function jukebox()
	local x, z = -HALF_X + 2.5, 6
	B.model("CodesJukebox", function()
		local body = B.part({
			Name = "Body",
			Size = { 5, 7, 3.5 },
			Position = { x, 3.5, z },
			Rotation = B.yaw("East"),
			Color = "RustDark",
			Material = "SmoothPlastic",
		})
		for index, color in { "NeonPink", "NeonTeal", "NeonOrange" } do
			B.part({
				Name = "Stripe",
				Size = { 4.2, 0.3, 0.2 },
				Position = { x + 1.85, 1.5 + index * 1.4, z },
				Rotation = B.yaw("East"),
				Color = color,
				Material = "Neon",
				CanCollide = false,
			})
		end
		B.light(body, "NeonPink", 12, 1.5)
		B.sign({
			Name = "CodesSign",
			Size = { 6, 1.6, 0.4 },
			Position = { x + 0.5, 8.4, z },
			Rotation = B.yaw("East"),
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Lobby.Sign.Codes",
			TextColor = "NeonOrange",
			Glow = true,
		})
	end):AddTag("CodesJukebox")
end

-- The quest board: a framed cork board with pinned notes (like the bunk corner reference).
local function questBoard()
	local x, z = -HALF_X + 0.8, -6
	B.model("QuestBoard", function()
		B.part({
			Name = "Frame",
			Size = { 0.5, 8.4, 13.4 },
			Position = { x - 0.1, 9, z },
			Color = "WoodDark",
			Material = "Wood",
		})
		B.part({
			Name = "Board",
			Size = { 0.6, 7, 12 },
			Position = { x, 9, z },
			Color = "Cork",
			Material = "Fabric",
		})
		for index, note in { { -3.5, 1.5 }, { 0, 2 }, { 3.6, 1.2 }, { -2, -1.6 }, { 2.4, -1.8 }, { 4.6, -0.8 } } do
			B.part({
				Name = `Note{index}`,
				Size = { 0.1, 1.8, 1.5 },
				Position = { x + 0.35, 9 + note[2], z + note[1] },
				Rotation = { index * 7 - 20, 0, 0 },
				Color = "OffWhite",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
			B.part({
				Name = `Pin{index}`,
				Size = { 0.2, 0.3, 0.3 },
				Position = { x + 0.45, 9.6 + note[2], z + note[1] },
				Color = "VendRed",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
		B.sign({
			Name = "QuestSign",
			Size = { 10, 2, 0.4 },
			Position = { x + 0.4, 14.2, z },
			Rotation = B.yaw("East"),
			Color = "RustOrange",
			Material = "Metal",
			Key = "Lobby.Sign.Quests",
			TextColor = "OffWhite",
		})
	end):AddTag("QuestBoard")
end

-- Three tall dark leaderboard boards on the south wall (reference: leaderboard-boards.png): a cream title with a thin
-- gold underline over the screen the leaderboard rows are drawn on (LeaderboardController).
local function leaderboards()
	local z = -HALF_Z + 0.5
	for index, board in
		{
			{ x = -22, stat = "Wins" },
			{ x = 0, stat = "KOs" },
			{ x = 22, stat = "Level" },
		}
	do
		B.model(`Leaderboard{board.stat}`, function()
			B.part({
				Name = "Frame",
				Size = { 17, 22, 1 },
				Position = { board.x, 13, z },
				Color = "BoardDark",
				Material = "SmoothPlastic",
			})
			B.part({
				Name = "Cap",
				Size = { 17.6, 0.6, 1.4 },
				Position = { board.x, 24.2, z + 0.1 },
				Color = "WoodDark",
				Material = "Wood",
			})
			B.sign({
				Name = "Title",
				Size = { 15.5, 2.4, 0.2 },
				Position = { board.x, 21.8, z + 0.6 },
				Rotation = B.yaw("North"),
				Color = "BoardDark",
				Material = "SmoothPlastic",
				Key = `Lobby.Sign.Leaderboard.{board.stat}`,
				TextColor = "Cream",
				Glow = true,
			})
			B.part({
				Name = "Underline",
				Size = { 10, 0.15, 0.2 },
				Position = { board.x, 20.4, z + 0.65 },
				Color = "Gold",
				Material = "Neon",
				CanCollide = false,
				CastShadow = false,
			})
			B.part({
				Name = "Screen",
				Size = { 15.5, 17, 0.2 },
				Position = { board.x, 11.3, z + 0.6 },
				Rotation = B.yaw("North"),
				Color = "BoardDark",
				Material = "SmoothPlastic",
				Tags = { "LeaderboardScreen" },
				Attributes = { Stat = board.stat, Order = index },
			})
		end, { Stat = board.stat }):AddTag("Leaderboard")
	end
end

local function spawns()
	for index, x in { -12, 0, 12 } do
		B.spawnLocation({
			Name = `LobbySpawn{index}`,
			Size = { 6, 1, 6 },
			Position = { x, 0.5, -HALF_Z + 15 },
			Rotation = B.yaw("North"), -- players spawn facing the bar
			Color = "Teal",
			Material = "SmoothPlastic",
			Tags = { "LobbySpawn" },
		})
	end
	lamp({ 0, 20, -HALF_Z + 15 }, "WarmLight", 30)
	-- The street door the crew comes in through (decor), with vending machines and a plant beside it.
	B.part({
		Name = "StreetDoor",
		Size = { 7, 10, 0.4 },
		Position = { 54, 5, -HALF_Z + 0.2 },
		Color = "TealDark",
		Material = "Metal",
	})
	B.part({
		Name = "StreetDoorLight",
		Size = { 1.6, 0.6, 0.8 },
		Position = { 54, 11, -HALF_Z + 0.4 },
		Color = "LaneYellow",
		Material = "Neon",
		CanCollide = false,
	})
	vendingMachine("VendingMachine1", 36, -HALF_Z + 2.2, "North")
	vendingMachine("VendingMachine2", 42, -HALF_Z + 2.2, "North")
	plant(49, -HALF_Z + 3)
end

-- Booths in the north corners: a table between two benches that face each other.
local function booth(name: string, x: number, z: number)
	B.model(name, function()
		B.part({
			Name = "Table",
			Size = { 6, 0.4, 3.4 },
			Position = { x, 3, z },
			Color = "Marble",
			Material = "Marble",
		})
		B.part({ Name = "TableLeg", Size = { 0.6, 3, 0.6 }, Position = { x, 1.5, z }, Color = "Gold" })
	end)
	sofa(`{name}BenchSouth`, x, z - 3.6, "North", 2, "Sofa")
	sofa(`{name}BenchNorth`, x, z + 3.6, "South", 2, "Sofa")
	lamp({ x, 16, z }, "WarmLight", 22)
end

local function lounge()
	-- The sitting area (reference: lobby-lounge.jpg).
	local rugX, rugZ = -32, -8
	rug(rugX, rugZ, 34, 26)
	coffeeTable(rugX, rugZ)
	sofa("Sofa", rugX, rugZ - 8.5, "North", 3, "Sofa")
	sofa("ArmchairWest", rugX - 12, rugZ + 1, "East", 1, "Sofa")
	sofa("ArmchairEast", rugX + 12, rugZ + 1, "West", 1, "Sofa")
	floorLamp(rugX - 9, rugZ - 10)
	floorLamp(rugX + 9, rugZ - 10)
	plant(rugX - 19, rugZ - 12)
	plant(rugX + 19, rugZ + 13)
	lamp({ rugX, 18, rugZ }, "WarmLight", 30)

	-- The bunk corner (reference: lobby-bunk-corner.jpg): kitchen on the west wall, bunks against the south wall.
	kitchen(-HALF_X + 2.1, -32.5, -18.5) -- between two wall pillars
	bunkBed("BunkBed1", -60, -HALF_Z + 2.6, "Blanket")
	bunkBed("BunkBed2", -36, -HALF_Z + 2.6, "BlanketRed")
	lamp({ -52, 18, -38 }, "WarmLight", 24)

	-- Pool table with its own lamp.
	local poolX, poolZ = 24, -10
	B.model("PoolTable", function()
		B.part({
			Name = "Body",
			Size = { 14, 2.8, 8 },
			Position = { poolX, 1.4, poolZ },
			Color = "WoodDark",
			Material = "Wood",
		})
		B.part({
			Name = "Felt",
			Size = { 13, 0.2, 7 },
			Position = { poolX, 2.9, poolZ },
			Color = "Felt",
			Material = "Fabric",
		})
		for index, ball in { { -3, 1, "NeonOrange" }, { -2, -1.5, "OffWhite" }, { 2, 0.5, "Black" }, { 4, -1, "Teal" } } do
			B.part({
				Name = `Ball{index}`,
				Size = { 0.6, 0.6, 0.6 },
				Position = { poolX + ball[1], 3.3, poolZ + ball[2] },
				Shape = "Ball",
				Color = ball[3],
				CanCollide = false,
			})
		end
	end)
	lamp({ poolX, 15, poolZ }, "WarmLight", 24)

	-- High tables with stools between the lounge and the arena door.
	for index, spot in { { 16, 16 }, { 34, 16 } } do
		B.model(`HighTable{index}`, function()
			B.part({
				Name = "Top",
				Size = { 0.3, 3.4, 3.4 },
				Position = { spot[1], 3.8, spot[2] },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "Marble",
				Material = "Marble",
			})
			B.part({
				Name = "Pole",
				Size = { 0.5, 3.7, 0.5 },
				Position = { spot[1], 1.85, spot[2] },
				Color = "Gold",
				Material = "Metal",
			})
		end)
		for side, facing in { "East", "West" } do
			local x = spot[1] + (if side == 1 then -2.8 else 2.8)
			B.part({
				Name = `HighStoolPole{index}{side}`,
				Size = { 0.5, 2.2, 0.5 },
				Position = { x, 1.1, spot[2] },
				Color = "Gold",
				Material = "Metal",
			})
			B.seat({
				Name = `HighStool{index}{side}`,
				Size = { 1.9, 0.5, 1.9 },
				Position = { x, 2.45, spot[2] },
				Rotation = B.yaw(facing),
				Color = "Sofa",
				Material = "Leather",
			})
		end
	end
	lamp({ 25, 19, 16 }, "WarmLight", 26)
	plant(6, 24)

	booth("BoothWest", -54, HALF_Z - 9)
	booth("BoothEast", 52, HALF_Z - 9)

	-- Crates: the hideout's junk, in the south-east corner.
	for index, crate in
		{
			{ HALF_X - 3, -HALF_Z + 3, 4 },
			{ HALF_X - 3, -HALF_Z + 7.5, 3 },
			{ HALF_X - 7.5, -HALF_Z + 3, 3 },
			{ HALF_X - 3.2, -HALF_Z + 3, 2.5, 4 },
		}
	do
		local size = crate[3]
		B.part({
			Name = `Crate{index}`,
			Size = { size, size, size },
			Position = { crate[1], (crate[4] or 0) + size / 2, crate[2] },
			Rotation = { 0, index * 23, 0 },
			Color = "Wood",
			Material = "WoodPlanks",
		})
	end
end

-- Builds the lobby at `origin` (world position of the floor's top centre).
function Layout.build(origin: { number }): any
	return B.root("Lobby", function()
		B.within(origin, function()
			shell()
			bar()
			arenaDoor()
			locker()
			jukebox()
			questBoard()
			leaderboards()
			spawns()
			lounge()
		end)
	end, {
		MapId = Layout.Id,
		Lighting = Layout.Lighting,
		KillY = origin[2] - KILL_DEPTH,
	})
end

-- The room's inside floor size (X, Z) and the join pad's footprint (X, Z) and centre, for specs.
Layout.Inner = INNER
Layout.JoinPad = { Size = PAD_SIZE, Center = { PAD_X, 0 } }

return Layout
