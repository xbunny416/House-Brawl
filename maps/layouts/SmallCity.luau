--!strict
--[[
	Map 4: Small City — the only arena in the vote since 2026-10-28 (owner: "make another, only one arena instead of the 3
	old arenas, just store them somewhere, don't delete them; just like the default small city in Roblox but still has
	throwable objects", then the same day: "no floating island, just a Roblox default city with mountains around").
	Broken Highway, Junkyard Isles and Neon Motel stay built and in the place, switched off in Config.Maps.List.

	A ground arena, not floating platforms: one flat green valley (the Center platform, 400 × 336, never falls) with a
	small town on it, walled in by mountains — grass slopes, grey rock and snowy tops, like Roblox's old City and
	Suburban templates and the hills around its starting places. Invisible walls along the valley's edge keep everyone
	in (the mountains rise behind them). Nobody falls here: a Classic life ends when its HP runs out (KillY under the
	ground only catches someone who slips through). Day lighting: a blue sky with white clouds.

	The town (320 × 256) is a street grid: a main avenue (x 0) that runs into a tunnel in the mountains at both ends, two
	more streets along Z (x ±96) and two across (z ±48), with lane lines, crosswalks, kerbs, traffic lights, street
	lamps, hydrants, trash cans and parked cars. Twelve blocks between them:
	  middle row — a gas station (west), office towers A and B either side of the avenue, a parking lot (east);
	  north row — houses (west), the park with a fountain and a playground, office tower C, houses (east);
	  south row — a construction site with a two-storey steel frame (west), office tower D and a diner you can climb,
	    a basketball court with bleachers, the bus depot (east).
	The four towers are the old City template's "four urban buildings". Higher places: the diner's roof (+9.5, its fire
	escape), the steel frame (+6, +12), the playground tower (+5), the bus's roof (+5.5), the bleachers, cars.
	Spots: 16 spawns in the streets, 24 loose prop spots, 8 breakable structures, 6 explosive barrels.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")
local Pieces = require("../lib/Pieces")

type Platform = Arena.Platform

local Layout = {}

Layout.Id = "SmallCity"
Layout.Lighting = "Day"
Layout.Ground = true -- one walled-in ground platform instead of floating ones (the maps spec checks it differently)

local VALLEY = { 400, 336 } -- X, Z: the playable ground inside the walls
local TOWN = { 320, 256 } -- X, Z: the street grid
local WALL_HEIGHT = 260

Layout.Platforms = {
	{
		Id = "Center",
		Kind = "Center",
		Center = { 0, 0 },
		Size = VALLEY,
		Top = 0,
		Thickness = 6,
		Color = "Lawn",
		Material = "Grass",
	},
} :: { Platform }

-- Streets: centre lines of the three along Z and the two along X, all 20 wide.
local ROAD = 20
local STREETS_X = { -96, 0, 96 } -- x of the streets that run along Z (0 = the avenue)
local STREETS_Z = { -48, 48 } -- z of the streets that run along X
-- The blocks between them: x bands (west to east) and z bands (south to north), as centre and half size.
local BANDS_X = { { -133, 27 }, { -48, 38 }, { 48, 38 }, { 133, 27 } }
local BANDS_Z = { { -93, 35 }, { 0, 38 }, { 93, 35 } }

-- The centre of block (column, row).
local function block(column: number, row: number): { number }
	return { BANDS_X[column][1], BANDS_Z[row][1] }
end

-- A spot `lx`, `lz` from block (column, row)'s centre, in arena coordinates.
local function inBlock(column: number, row: number, lx: number, lz: number): { number }
	local at = block(column, row)
	return { at[1] + lx, at[2] + lz }
end

Layout.Contents = {
	Center = {
		Spawns = {
			{ 0, -110 },
			{ 0, -20 },
			{ 0, 20 },
			{ 0, 110 },
			{ -140, -48 },
			{ -50, -48 },
			{ 50, -48 },
			{ 140, -48 },
			{ -140, 48 },
			{ -50, 48 },
			{ 50, 48 },
			{ 140, 48 },
			{ -96, 0 },
			{ 96, 0 },
			{ -96, -100 },
			{ 96, 100 },
		},
		Props = {
			inBlock(1, 2, -16, 0), -- the gas station
			inBlock(1, 2, 18, -30),
			inBlock(4, 2, 0, -10), -- the parking lot
			inBlock(4, 2, 0, 34),
			inBlock(2, 2, -30, -28), -- tower A's plaza
			inBlock(2, 2, 30, 18),
			inBlock(3, 2, -30, 4), -- tower B's plaza
			inBlock(3, 2, 30, 28),
			inBlock(2, 3, -24, -22), -- the park
			inBlock(2, 3, 20, -24),
			inBlock(3, 3, -24, 0), -- tower C's plaza
			inBlock(3, 3, -2, -26),
			inBlock(1, 3, 10, 30), -- the houses (west)
			inBlock(1, 3, -22, -14),
			inBlock(4, 3, -10, 30), -- the houses (east)
			inBlock(4, 3, 22, -14),
			inBlock(1, 1, 14, 6), -- the construction site
			inBlock(1, 1, -20, 26),
			inBlock(2, 1, -30, 22), -- tower D and the diner
			inBlock(2, 1, 30, -20),
			inBlock(3, 1, -18, -14), -- the basketball court
			inBlock(3, 1, 16, 4),
			inBlock(4, 1, 14, 24), -- the bus depot
			inBlock(4, 1, -16, 26),
		},
		Explosives = {
			inBlock(1, 2, -18, -30),
			inBlock(4, 2, 0, 20),
			inBlock(2, 3, 0, -26),
			inBlock(1, 1, 16, -28),
			inBlock(3, 1, 0, -6),
			inBlock(4, 1, -16, -24),
		},
		Structures = {
			{ Type = "IceMachine", At = inBlock(1, 2, 14, 24), Yaw = 90 },
			{ Type = "VendingMachine", At = inBlock(1, 2, -24, 24), Yaw = 90 },
			{ Type = "WreckedCar", At = inBlock(4, 2, 14, -3), Yaw = 90 },
			{ Type = "WreckedCar", At = { 72, -52 }, Yaw = 90 },
			{ Type = "LawnChairStack", At = inBlock(1, 3, -22, 0), Yaw = 90 },
			{ Type = "RoadBarrierStack", At = inBlock(1, 1, 14, 24), Yaw = 90 },
			{ Type = "RoadBarrierStack", At = { 96, -90 }, Yaw = 0 },
			{ Type = "VendingMachine", At = inBlock(4, 1, 18, -24), Yaw = 90 },
		},
	},
} :: { [string]: Arena.Contents }

function Layout.killY(): number
	return Arena.killY(Layout.Platforms)
end

---------------------------------------------------------------------------------------------------------------------
-- Pieces (positions from where they're called: the valley's centre, or a block's with B.within)
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

-- A parked car (decor, solid: you can be knocked into it or stand on it), its length along Z turned `yaw`: body,
-- glass cabin with a roof, four wheels, bumpers, headlights and tail lights.
local function car(name: string, at: { number }, yaw: number, color: string)
	local place = placer(at, yaw)
	local turn = { 0, yaw, 0 }
	B.model(name, function()
		B.part({ Name = "Body", Size = { 4.6, 1.5, 9 }, Position = place(0, 1.25, 0), Rotation = turn, Color = color })
		B.part({
			Name = "Cabin",
			Size = { 4.2, 1.4, 4.6 },
			Position = place(0, 2.7, -0.4),
			Rotation = turn,
			Color = "Black",
			Material = "Glass",
			Transparency = 0.25,
		})
		B.part({
			Name = "Roof",
			Size = { 4.2, 0.2, 4 },
			Position = place(0, 3.5, -0.4),
			Rotation = turn,
			Color = color,
			CanCollide = false,
		})
		for _, lx in { -2.2, 2.2 } do
			for _, lz in { -3, 3 } do
				B.part({
					Name = "Wheel",
					Size = { 0.8, 1.6, 1.6 },
					Position = place(lx, 0.8, lz),
					Rotation = turn,
					Shape = "Cylinder",
					Color = "Black",
					CanCollide = false,
				})
			end
		end
		for _, lz in { -4.6, 4.6 } do
			B.part({
				Name = "Bumper",
				Size = { 4.7, 0.5, 0.3 },
				Position = place(0, 0.9, lz),
				Rotation = turn,
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			for _, lx in { -1.6, 1.6 } do
				B.part({
					Name = if lz > 0 then "Headlight" else "TailLight",
					Size = { 0.9, 0.4, 0.1 },
					Position = place(lx, 1.6, lz + (if lz > 0 then 0.06 else -0.06)),
					Rotation = turn,
					Color = if lz > 0 then "WarmLight" else "Red",
					Material = "Neon",
					CanCollide = false,
				})
			end
		end
	end)
end

-- A leafy tree on `y`: a trunk (solid) and two balls of leaves.
local function tree(name: string, at: { number }, y: number?, scale: number?)
	local base, k = y or 0, scale or 1
	B.model(name, function()
		upright("Trunk", at, base, 5 * k, 0.9 * k, "Wood", "Wood")
		B.part({
			Name = "Leaves",
			Size = { 6 * k, 6 * k, 6 * k },
			Position = { at[1], base + 6.5 * k, at[2] },
			Shape = "Ball",
			Color = "Leaf",
			Material = "LeafyGrass",
			CanCollide = false,
		})
		B.part({
			Name = "LeavesTop",
			Size = { 4 * k, 4 * k, 4 * k },
			Position = { at[1] + 0.6 * k, base + 9 * k, at[2] - 0.4 * k },
			Shape = "Ball",
			Color = "Leaf",
			Material = "LeafyGrass",
			CanCollide = false,
		})
	end)
end

-- A park bench turned `yaw` (unturned, you sit facing +Z): a wood seat and back on iron legs.
local function bench(name: string, at: { number }, yaw: number)
	local place = placer(at, yaw)
	local turn = { 0, yaw, 0 }
	B.model(name, function()
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

-- A red fire hydrant.
local function hydrant(at: { number })
	B.model("Hydrant", function()
		upright("Body", at, 0, 1.6, 0.8, "Red", "Metal")
		B.part({
			Name = "Cap",
			Size = { 0.8, 0.8, 0.8 },
			Position = { at[1], 1.7, at[2] },
			Shape = "Ball",
			Color = "Red",
			Material = "Metal",
			CanCollide = false,
		})
		B.part({
			Name = "Nozzles",
			Size = { 1.3, 0.35, 0.35 },
			Position = { at[1], 1.1, at[2] },
			Color = "LaneYellow",
			Material = "Metal",
			CanCollide = false,
		})
	end)
end

-- A green city trash can with a lid.
local function trashCan(at: { number })
	B.model("TrashCan", function()
		upright("Can", at, 0, 2.2, 1.4, "Bottle", "Metal")
		upright("Lid", at, 2.2, 0.2, 1.6, "MetalDark", "Metal", false)
	end)
end

-- A street lamp (not lit in the daytime): Pieces.lamp, its arm reaching toward `yaw`.
local function streetLamp(at: { number }, yaw: number)
	Pieces.lamp("StreetLamp", at, 10, yaw, 0, false)
end

--[[
	A traffic light on a street corner: a pole, an arm reaching `reach` (a unit vector on the floor: over the road it
	controls) and a signal box hanging off its end with red, amber and green lenses facing both ways along the road.
	Only the pole is solid.
]]
local function trafficLight(at: { number }, reach: { number })
	B.model("TrafficLight", function()
		upright("Pole", at, 0, 9.5, 0.5, "MetalDark", "Metal")
		local alongX = math.abs(reach[1]) > 0
		B.part({
			Name = "Arm",
			Size = if alongX then { 7, 0.3, 0.3 } else { 0.3, 0.3, 7 },
			Position = { at[1] + reach[1] * 3.5, 9.2, at[2] + reach[2] * 3.5 },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		local box = { at[1] + reach[1] * 6.5, at[2] + reach[2] * 6.5 }
		B.part({
			Name = "Signal",
			Size = { 1, 2.8, 1 },
			Position = { box[1], 7.6, box[2] },
			Color = "LaneYellow",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		-- Lenses on the two faces across the arm (traffic runs that way).
		for index, lens in { { 8.5, "Red" }, { 7.6, "Amber" }, { 6.7, "Bottle" } } do
			for _, side in { -1, 1 } do
				B.part({
					Name = `Lens{index}`,
					Size = { 0.1, 0.6, 0.6 },
					Position = {
						box[1] + (if alongX then 0 else side * 0.55),
						lens[1],
						box[2] + (if alongX then side * 0.55 else 0),
					},
					Rotation = if alongX then { 0, 90, 0 } else nil,
					Shape = "Cylinder",
					Color = lens[2],
					Material = if index == 3 then "Neon" else "SmoothPlastic",
					CanCollide = false,
				})
			end
		end
	end)
end

-- Glass panels flat on the face `face` ("+X" / "-X" / "+Z" / "-Z") of a box at `at` sized `size`: one row per 4 studs
-- of height from `from` to `to`, a window every 4.5 studs across, and a door in the middle of the bottom row when
-- `door`.
local function windows(at: { number }, size: { number }, face: string, from: number, to: number, door: boolean)
	local axis = if string.sub(face, 2) == "X" then 1 else 3
	local sign = if string.sub(face, 1, 1) == "+" then 1 else -1
	local width = if axis == 1 then size[3] else size[1]
	local out = sign * ((if axis == 1 then size[1] else size[3]) / 2 + 0.06)
	local columns = math.max(1, math.floor(width / 4.5))
	local rows = math.max(1, math.floor((to - from) / 4))
	for row = 1, rows do
		for column = 1, columns do
			local along = -width / 2 + (column - 0.5) * width / columns
			local isDoor = door and row == 1 and column == math.ceil(columns / 2)
			local w, h = if isDoor then 2.4 else 2.6, if isDoor then 3.2 else 2
			local y = if isDoor then 1.6 else from + (row - 1) * 4 + 2.4
			B.part({
				Name = if isDoor then "Door" else "Window",
				Size = if axis == 1 then { 0.1, h, w } else { w, h, 0.1 },
				Position = if axis == 1 then { at[1] + out, y, at[2] + along } else { at[1] + along, y, at[2] + out },
				Color = if isDoor then "MetalDark" else "Glass",
				Material = if isDoor then "Metal" else "Glass",
				Transparency = if isDoor then nil else 0.2,
				CanCollide = false,
			})
		end
	end
end

-- A small building `size` (X, height, Z): plain walls, a roof cap, windows and a door on the faces in `faces` (the
-- door on the first). Solid (the roof is walkable).
local function building(name: string, at: { number }, size: { number }, color: string, faces: { string })
	B.model(name, function()
		Pieces.block("Walls", at, size, color, "Concrete")
		Pieces.block("RoofCap", at, { size[1] + 0.6, 0.5, size[3] + 0.6 }, "ConcreteDark", "Concrete", size[2])
		for index, face in faces do
			windows(at, size, face, 0, size[2] - 1, index == 1)
		end
	end)
end

--[[
	An office tower `size` (X, height, Z): walls, a band of glass every 6 studs (a little wider than the tower, so it
	shows on all four sides), a glass lobby and an entrance canopy on `entrance`, a roof crown and a mast with a red
	light.
]]
local function tower(name: string, at: { number }, size: { number }, color: string, entrance: string)
	local sx, height, sz = size[1], size[2], size[3]
	B.model(name, function()
		Pieces.block("Walls", at, size, color, "Concrete")
		for y = 9, height - 4, 6 do
			B.part({
				Name = "GlassBand",
				Size = { sx + 0.3, 2.6, sz + 0.3 },
				Position = { at[1], y, at[2] },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.1,
				CanCollide = false,
				CastShadow = false,
			})
		end
		windows(at, size, entrance, 0, 5, true)
		local axis = if string.sub(entrance, 2) == "X" then 1 else 3
		local sign = if string.sub(entrance, 1, 1) == "+" then 1 else -1
		local out = sign * ((if axis == 1 then sx else sz) / 2 + 2)
		B.part({
			Name = "EntranceCanopy",
			Size = if axis == 1 then { 4, 0.5, 12 } else { 12, 0.5, 4 },
			Position = if axis == 1 then { at[1] + out, 6.5, at[2] } else { at[1], 6.5, at[2] + out },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		Pieces.block("Crown", at, { sx * 0.7, 6, sz * 0.7 }, "ConcreteDark", "Concrete", height)
		upright("Mast", at, height + 6, 14, 0.5, "OffWhite", "Metal", false)
		B.part({
			Name = "MastLight",
			Size = { 0.9, 0.9, 0.9 },
			Position = { at[1], height + 20.4, at[2] },
			Shape = "Ball",
			Color = "Red",
			Material = "Neon",
			CanCollide = false,
		})
	end)
end

-- A concrete planter (1.4 high) with a tree in it.
local function planterTree(at: { number })
	Pieces.block("Planter", at, { 5, 1.4, 5 }, "Concrete", "Concrete")
	tree("PlanterTree", at, 1.4, 0.8)
end

-- A statue on a pedestal (decor, solid).
local function statue(at: { number })
	B.model("Statue", function()
		Pieces.block("Pedestal", at, { 4, 3, 4 }, "Concrete", "Concrete")
		Pieces.block("Figure", at, { 1.6, 4.4, 1.2 }, "TealDark", "Metal", 3)
		B.part({
			Name = "Head",
			Size = { 1.3, 1.3, 1.3 },
			Position = { at[1], 8.1, at[2] },
			Shape = "Ball",
			Color = "TealDark",
			Material = "Metal",
			CanCollide = false,
		})
	end)
end

-- A house with a pitched roof, its front toward `facing` along X (+1 / −1): walls, two roof wedges meeting at a ridge
-- along Z, a chimney, a door and two windows on the front, a driveway out to the block's edge (`yard` studs away).
local function house(name: string, at: { number }, facing: number, color: string, roof: string, yard: number)
	local width, depth, height, rise = 18, 14, 8, 4.5
	B.model(name, function()
		Pieces.block("Walls", at, { width, height, depth }, color, "WoodPlanks")
		for _, side in { -1, 1 } do
			B.part({
				Name = "Roof",
				Size = { depth + 1.2, rise, width / 2 + 0.8 },
				Position = { at[1] + side * (width / 4 + 0.4), height + rise / 2, at[2] },
				Rotation = { 0, -90 * side, 0 }, -- each wedge's tall end toward the ridge
				Shape = "Wedge",
				Color = roof,
				Material = "Slate",
			})
		end
		Pieces.block("Chimney", { at[1] - facing * 4, at[2] + 4 }, { 1.6, 5, 1.6 }, "Brick", "Brick", height)
		local front = at[1] + facing * (width / 2 + 0.06)
		B.part({
			Name = "Door",
			Size = { 0.1, 3.6, 2.2 },
			Position = { front, 1.8, at[2] },
			Color = "Brick",
			Material = "Wood",
			CanCollide = false,
		})
		for _, z in { -4.5, 4.5 } do
			B.part({
				Name = "Window",
				Size = { 0.1, 2.2, 2.8 },
				Position = { front, 4.4, at[2] + z },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.2,
				CanCollide = false,
			})
		end
		paint("Driveway", { front + facing * yard / 2, at[2] }, { yard, 6 }, "Concrete", "Concrete")
	end)
end

-- A white picket fence along X = `x` from `z0` to `z1`: two low rails (solid) and pickets.
local function picketFence(x: number, z0: number, z1: number)
	local length = z1 - z0
	B.model("PicketFence", function()
		for _, y in { 0.4, 1 } do
			B.part({
				Name = "Rail",
				Size = { 0.2, 0.2, length },
				Position = { x, y, (z0 + z1) / 2 },
				Color = "OffWhite",
				Material = "Wood",
			})
		end
		for z = z0 + 0.5, z1 - 0.5, 1.5 do
			B.part({
				Name = "Picket",
				Size = { 0.15, 1.5, 0.5 },
				Position = { x, 0.75, z },
				Color = "OffWhite",
				Material = "Wood",
				CanCollide = false,
			})
		end
	end)
end

-- A bus shelter with a seat and a BUS STOP sign, its open front toward −Z.
local function busShelter(at: { number })
	B.model("BusShelter", function()
		Pieces.block("Back", { at[1], at[2] + 2.2 }, { 10, 6, 0.3 }, "Glass", "Glass")
		Pieces.block("Roof", { at[1], at[2] + 0.4 }, { 11, 0.4, 4.2 }, "MetalDark", "Metal", 6.6)
		for _, dx in { -5, 5 } do
			Pieces.column("Post", { at[1] + dx, at[2] - 1.4 }, 0, 6.6, 0.4, "MetalDark", "Metal")
		end
		Pieces.block("Seat", { at[1], at[2] + 1.4 }, { 8, 0.4, 1.2 }, "Wood", "WoodPlanks", 1.3)
		Pieces.column("SignPole", { at[1] - 7, at[2] - 2.5 }, 0, 8, 0.3, "MetalDark", "Metal")
		B.sign({
			Name = "BusSign",
			Size = { 3.6, 1.2, 0.2 },
			Position = { at[1] - 7, 7.4, at[2] - 2.7 },
			Color = "TealDark",
			Material = "SmoothPlastic",
			Key = "Map.SmallCity.Sign.Bus",
			TextColor = "OffWhite",
		})
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The streets
---------------------------------------------------------------------------------------------------------------------

local function streets()
	local halfX, halfZ = TOWN[1] / 2, TOWN[2] / 2
	for _, z in STREETS_Z do
		paint("Road", { 0, z }, { TOWN[1], ROAD }, "Asphalt", "Asphalt")
	end
	-- The streets along Z in pieces between the crossings (no road painted twice); the avenue runs on through the
	-- grass to the tunnels at both ends.
	for _, x in STREETS_X do
		for _, band in BANDS_Z do
			paint("Road", { x, band[1] }, { ROAD, band[2] * 2 }, "Asphalt", "Asphalt")
		end
	end
	local beyond = (VALLEY[2] - TOWN[2]) / 2
	for _, side in { -1, 1 } do
		paint("Road", { 0, side * (halfZ + beyond / 2) }, { ROAD, beyond }, "Asphalt", "Asphalt")
	end
	-- Dashed yellow centre lines, stopping short of the crossings.
	local function nearCrossing(value: number, lines: { number }): boolean
		for _, line in lines do
			if math.abs(value - line) < ROAD / 2 + 5 then
				return true
			end
		end
		return false
	end
	for _, z in STREETS_Z do
		for x = -halfX + 4, halfX - 4, 8 do
			if not nearCrossing(x, STREETS_X) then
				paint("CentreLine", { x, z }, { 4, 0.4 }, "LaneYellow", nil, 0.12)
			end
		end
	end
	for _, x in STREETS_X do
		local reach = if x == 0 then VALLEY[2] / 2 else halfZ
		for z = -reach + 4, reach - 4, 8 do
			if not nearCrossing(z, STREETS_Z) then
				paint("CentreLine", { x, z }, { 0.4, 4 }, "LaneYellow", nil, 0.12)
			end
		end
	end
	-- Crosswalks on all four sides of the avenue's crossings, on the two inner sides of the others; a traffic light on
	-- two corners of each, one over each street.
	for _, cx in STREETS_X do
		for _, cz in STREETS_Z do
			local sx = if cx >= 0 then 1 else -1
			local sz = if cz >= 0 then 1 else -1
			local sides = if cx == 0 then { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } else { { -sx, 0 }, { 0, -sz } }
			for _, side in sides do
				for stripe = 0, 5 do
					local across = -ROAD / 2 + 1.7 + stripe * 3.3
					local spot = if side[1] ~= 0
						then { cx + side[1] * (ROAD / 2 + 2.5), cz + across }
						else { cx + across, cz + side[2] * (ROAD / 2 + 2.5) }
					paint("Crosswalk", spot, if side[1] ~= 0 then { 4, 1.4 } else { 1.4, 4 }, "LaneWhite", nil, 0.12)
				end
			end
			local corner = ROAD / 2 + 1
			trafficLight({ cx - sx * corner, cz - sz * corner }, { 0, sz })
			trafficLight({ cx + sx * corner, cz + sz * corner }, { -sx, 0 })
		end
	end
	-- Kerbs round every block (walk-through, low).
	for _, bandX in BANDS_X do
		for _, bandZ in BANDS_Z do
			local x, z, hx, hz = bandX[1], bandZ[1], bandX[2], bandZ[2]
			for _, edge in
				{
					{ { x, z - hz - 0.25 }, { hx * 2 + 1, 0.5 } },
					{ { x, z + hz + 0.25 }, { hx * 2 + 1, 0.5 } },
					{ { x - hx - 0.25, z }, { 0.5, hz * 2 } },
					{ { x + hx + 0.25, z }, { 0.5, hz * 2 } },
				}
			do
				B.part({
					Name = "Kerb",
					Size = { edge[2][1], 0.3, edge[2][2] },
					Position = { edge[1][1], 0.15, edge[1][2] },
					Color = "LaneWhite",
					Material = "Concrete",
					CanCollide = false,
					CastShadow = false,
				})
			end
		end
	end
	-- Street lamps, hydrants and trash cans on the pavements; parked cars along the kerbs, a taxi on the avenue.
	for _, lamp in
		{
			{ 11.5, 25, -90 },
			{ -11.5, -25, 90 },
			{ 11.5, -100, -90 },
			{ -11.5, 100, 90 },
			{ -11.5, -84, 90 },
			{ 11.5, 84, -90 },
			{ 70, 59.5, 180 },
			{ -70, -59.5, 0 },
			{ 140, 36.5, 0 },
			{ -140, -36.5, 180 },
		}
	do
		streetLamp({ lamp[1], lamp[2] }, lamp[3])
	end
	for _, at in { { 11.5, 34 }, { -11.5, -34 }, { 84.5, 62 }, { -84.5, -62 } } do
		hydrant(at)
	end
	for _, at in { { -11.5, 12 }, { 11.5, -14 }, { -84.5, 66 }, { 84.5, -66 } } do
		trashCan(at)
	end
	car("ParkedCar", { -70, 41 }, 90, "Red")
	car("ParkedCar", { 120, -55 }, -90, "TealDark")
	car("ParkedCar", { -120, -41 }, 90, "OffWhite")
	car("Taxi", { -6, 70 }, 0, "LaneYellow")
end

---------------------------------------------------------------------------------------------------------------------
-- The blocks (positions from the block's centre)
---------------------------------------------------------------------------------------------------------------------

-- Gas station (middle row, west; the street on its +X side): a forecourt with a canopy over two pump islands, a mini
-- mart, a GAS price sign facing the street, an air pump.
local function gasStation()
	paint("Forecourt", { 0, -14 }, { 54, 48 }, "Asphalt", "Asphalt")
	B.model("Canopy", function()
		for _, x in { -9, 13 } do
			for _, z in { -21, -7 } do
				Pieces.column("Post", { x, z }, 0, 6.6, 1, "OffWhite", "SmoothPlastic")
			end
		end
		Pieces.block("Roof", { 2, -14 }, { 26, 0.8, 18 }, "OffWhite", "SmoothPlastic", 6.6)
		B.part({
			Name = "Fascia",
			Size = { 26.4, 1.2, 18.4 },
			Position = { 2, 7.2, -14 },
			Color = "Red",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		for _, x in { -3, 7 } do
			paint("CanopyLight", { x, -14 }, { 1.2, 14 }, "WarmLight", "Neon", 6.58)
		end
	end)
	for index, x in { -3, 7 } do
		B.model(`PumpIsland{index}`, function()
			Pieces.block("Island", { x, -14 }, { 2, 0.4, 11 }, "Concrete", "Concrete")
			for _, z in { -17, -11 } do
				Pieces.block("Pump", { x, z }, { 1.4, 3.2, 1 }, "Red", "SmoothPlastic", 0.4)
				B.part({
					Name = "PumpScreen",
					Size = { 1.46, 0.8, 0.6 },
					Position = { x, 2.9, z },
					Color = "Black",
					Material = "SmoothPlastic",
					CanCollide = false,
				})
			end
		end)
	end
	car("FuelingCar", { 2, -14 }, 0, "Teal")
	building("MiniMart", { -6, 24 }, { 30, 9, 16 }, "CityTan", { "-Z" })
	B.sign({
		Name = "MartSign",
		Size = { 14, 1.8, 0.3 },
		Position = { -6, 8.3, 15.75 },
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.SmallCity.Sign.Mart",
		TextColor = "OffWhite",
	})
	Pieces.column("PriceSignPole", { 22, 30 }, 0, 9, 0.6, "MetalDark", "Metal")
	B.sign({
		Name = "PriceSign",
		Size = { 7, 3.4, 0.4 },
		Position = { 22.4, 10.4, 30 },
		Rotation = B.yaw("East"),
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.SmallCity.Sign.Gas",
		TextColor = "OffWhite",
	})
	trashCan({ -22, -8 })
	Pieces.block("AirPump", { 20, 12 }, { 1.4, 3, 1.2 }, "TealDark", "Metal")
end

-- Parking lot (middle row, east; the street on its −X side): two rows of bays off an aisle along Z, parked cars, a
-- ticket booth, lamps and a PARKING sign facing the street.
local function parkingLot()
	paint("Asphalt", { 0, 0 }, { 54, 76 }, "Asphalt", "Asphalt")
	for _, x in { -14, 14 } do
		for z = -36, 36, 6 do
			paint("BayLine", { x, z }, { 16, 0.3 }, "LaneWhite", nil, 0.12)
		end
		paint("BayEnd", { x + math.sign(x) * 8, 0 }, { 0.3, 72 }, "LaneWhite", nil, 0.12)
	end
	for _, spot in { { -14, -27 }, { -14, -9 }, { -14, 21 }, { 14, -21 }, { 14, 9 }, { 14, 27 } } do
		car("ParkedCar", spot, if spot[1] < 0 then 90 else -90, if spot[2] < 0 then "OffWhite" else "CityBlue")
	end
	B.model("TicketBooth", function()
		Pieces.block("Booth", { 0, -34 }, { 4, 6, 4 }, "CityBlue", "SmoothPlastic")
		Pieces.block("BoothRoof", { 0, -34 }, { 5, 0.4, 5 }, "OffWhite", "SmoothPlastic", 6)
		B.part({
			Name = "BoothWindow",
			Size = { 2.6, 1.8, 0.1 },
			Position = { 0, 3.8, -31.94 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.2,
			CanCollide = false,
		})
	end)
	streetLamp({ -25, 2 }, 90)
	streetLamp({ 25, 2 }, -90)
	B.model("ParkingSign", function()
		for _, z in { -15, -5 } do
			Pieces.column("SignPost", { -25, z }, 0, 5, 0.4, "MetalDark", "Metal")
		end
		B.sign({
			Name = "Board",
			Size = { 12, 2.6, 0.4 },
			Position = { -25.3, 6.2, -10 },
			Rotation = B.yaw("West"),
			Color = "CityBlue",
			Material = "SmoothPlastic",
			Key = "Map.SmallCity.Sign.Parking",
			TextColor = "OffWhite",
		})
	end)
end

-- A tower block's pavement and plaza: two planters with trees and a bench on the side `plazaSide` (+1 / −1 along X).
local function plaza(plazaSide: number, halfZ: number)
	paint("Pavement", { 0, 0 }, { 76, halfZ * 2 }, "Concrete", "Concrete")
	local x = plazaSide * 22
	planterTree({ x, -halfZ + 9 })
	planterTree({ x, halfZ - 6 })
	bench("PlazaBench", { plazaSide * 32, -12 }, -90 * plazaSide)
end

-- The park (north row): lawn, two paths crossing at a fountain, benches round it, trees, and a playground tower
-- (+5, stairs up, a slide down).
local function park()
	paint("PathX", { 0, 0 }, { 76, 5 }, "Concrete", "Concrete")
	paint("PathZ", { 0, 0 }, { 5, 70 }, "Concrete", "Concrete", 0.06)
	upright("PlazaPavers", { 0, 0 }, 0.1, 0.02, 24, "BrickRed", "Brick", false)
	upright("FountainBasin", { 0, 0 }, 0, 1.2, 12, "Concrete", "Concrete")
	upright("FountainWater", { 0, 0 }, 1.05, 0.1, 10.6, "Glass", "Glass", false)
	upright("FountainColumn", { 0, 0 }, 1.2, 2.6, 1.4, "Concrete", "Concrete")
	upright("FountainBowl", { 0, 0 }, 3.8, 0.5, 4.4, "Concrete", "Concrete")
	B.part({
		Name = "FountainSpout",
		Size = { 1.2, 1.2, 1.2 },
		Position = { 0, 4.9, 0 },
		Shape = "Ball",
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.3,
		CanCollide = false,
	})
	bench("ParkBench", { 0, 14 }, 180)
	bench("ParkBench", { 0, -14 }, 0)
	bench("ParkBench", { 14, 0 }, -90)
	bench("ParkBench", { -14, 0 }, 90)
	for index, at in { { -28, 24 }, { -28, -22 }, { 28, -22 }, { -10, -26 }, { 10, 28 } } do
		tree(`ParkTree{index}`, at)
	end
	-- The playground tower: a deck on four posts, stairs up its south side, a slide down to the east.
	B.model("Playground", function()
		Pieces.block("Deck", { 22, 22 }, { 6, 0.4, 6 }, "RustOrange", "SmoothPlastic", 4.6)
		for _, dx in { -2.6, 2.6 } do
			for _, dz in { -2.6, 2.6 } do
				Pieces.column("Post", { 22 + dx, 22 + dz }, 0, 4.6, 0.4, "TealDark", "Metal")
			end
		end
		Pieces.stairs("PlayStairs", { 22, 13 }, "+Z", 3, 5, 1, 1.2, "LaneYellow", "SmoothPlastic")
		Pieces.ramp("Slide", { 33, 22 }, { 25, 22 }, 2.6, 5, "Red", "SmoothPlastic")
	end)
end

-- Houses (north row, both ends): two houses facing the street on the `facing` side (+1: +X), front fences with gaps
-- for the driveways, mailboxes, a car in a driveway, a doghouse and trees.
local function houses(facing: number)
	local f = facing
	house("HouseSouth", { -8 * f, -16 }, f, "CityTan", "Brick", 26)
	house("HouseNorth", { -8 * f, 16 }, f, "DustyPink", "AsphaltDark", 26)
	for _, piece in { { -34, -20 }, { -12, 12 }, { 20, 34 } } do
		picketFence(20 * f, piece[1], piece[2])
	end
	for _, z in { -21, 21 } do
		Pieces.column("MailboxPost", { 22 * f, z }, 0, 3, 0.3, "Wood", "Wood")
		Pieces.block("Mailbox", { 22 * f, z }, { 0.9, 0.9, 1.6 }, "Teal", "Metal", 3)
	end
	car("DrivewayCar", { 12 * f, -16 }, 90, if f > 0 then "Red" else "CityBlue")
	Pieces.block("Doghouse", { -22 * f, -28 }, { 3.4, 2.6, 3.4 }, "Wood", "WoodPlanks")
	tree("YardTree", { -22 * f, 28 })
	tree("YardTree", { 8 * f, 0 })
end

-- Construction site (south row, west): dirt, a two-storey steel frame (decks at +6 and +12, stairs up to each), a stack
-- of steel beams, a portable toilet, cones and a barrier along the street.
local function constructionSite()
	paint("Dirt", { 0, 0 }, { 54, 70 }, "Soil", "Mud")
	B.model("SteelFrame", function()
		B.part({
			Name = "Deck1",
			Size = { 24, 0.5, 24 },
			Position = { -6, 5.75, -10 },
			Color = "MetalDark",
			Material = "DiamondPlate",
			CastShadow = true,
		})
		B.part({
			Name = "Deck2",
			Size = { 12, 0.5, 24 },
			Position = { -12, 11.75, -10 },
			Color = "MetalDark",
			Material = "DiamondPlate",
			CastShadow = true,
		})
		for _, x in { -17.6, -6.4, 5.6 } do
			for _, z in { -21.6, 1.6 } do
				Pieces.column("Column", { x, z }, 0, if x < 0 then 11.5 else 5.5, 0.6, "RustOrange", "Metal")
			end
		end
		Pieces.stairs("FrameStairs", { 2, 14 }, "-Z", 4, 6, 1, 2, "MetalDark", "DiamondPlate")
		Pieces.stairs("FrameStairsUpper", { 4, -16 }, "-X", 4, 6, 1, 1.6, "MetalDark", "DiamondPlate", 6)
	end)
	for layer = 0, 2 do
		B.part({
			Name = "SteelBeam",
			Size = { 12, 0.6, 1 },
			Position = { 16, 0.3 + layer * 0.6, -12 + (layer % 2) * 1.2 },
			Color = "RustOrange",
			Material = "Metal",
		})
	end
	Pieces.block("PortableToilet", { 22, 4 }, { 3, 7, 3 }, "Teal", "SmoothPlastic")
	Pieces.jersey("Barrier", { 8, 33 }, 14, 0, 0, true)
	for index, at in { { -4, 20 }, { 4, 28 }, { -20, 8 }, { 20, -20 }, { -22, -30 } } do
		B.model(`Cone{index}`, function()
			B.part({
				Name = "Base",
				Size = { 1.2, 0.15, 1.2 },
				Position = { at[1], 0.08, at[2] },
				Color = "NeonOrange",
				CanCollide = false,
			})
			upright("Cone", at, 0.15, 1.4, 0.6, "NeonOrange", "SmoothPlastic", false)
		end)
	end
end

-- Tower D's block (south row, beside the avenue): the tower, and a diner on the avenue side with a fire escape up to
-- its roof (+9.5) and a DINER sign facing the avenue.
local function dinerBlock()
	plaza(1, 35) -- on the diner's side (the tower fills the other)
	tower("TowerD", { -14, -8 }, { 32, 70, 34 }, "CityTan", "+Z")
	building("Diner", { 22, 10 }, { 24, 9, 16 }, "Red", { "+X", "-Z" })
	B.sign({
		Name = "DinerSign",
		Size = { 10, 2, 0.3 },
		Position = { 34.3, 7.6, 10 },
		Rotation = B.yaw("East"),
		Color = "OffWhite",
		Material = "SmoothPlastic",
		Key = "Map.SmallCity.Sign.Diner",
		TextColor = "Red",
	})
	Pieces.stairs("FireEscape", { 12, -1 }, "+X", 3, 9, 1, 1.6, "MetalDark", "Metal")
end

-- Basketball court (south row): a green court with white lines, two hoops, bleachers on the north side, trees.
local function court()
	paint("Pavement", { 0, 0 }, { 76, 70 }, "Concrete", "Concrete")
	local cx, cz, length, width = 0, -6, 56, 30
	paint("Court", { cx, cz }, { length, width }, "CourtGreen", "SmoothPlastic", 0.11)
	for _, edge in
		{
			{ { cx, cz - width / 2 }, { length, 0.4 } },
			{ { cx, cz + width / 2 }, { length, 0.4 } },
			{ { cx - length / 2, cz }, { 0.4, width } },
			{ { cx + length / 2, cz }, { 0.4, width } },
			{ { cx, cz }, { 0.4, width } },
			{ { cx - length / 2 + 6, cz }, { 12, 0.4 } },
			{ { cx + length / 2 - 6, cz }, { 12, 0.4 } },
		}
	do
		paint("CourtLine", edge[1], edge[2], "LaneWhite", nil, 0.15)
	end
	upright("CentreCircle", { cx, cz }, 0.12, 0.02, 8, "LaneWhite", "SmoothPlastic", false)
	for _, side in { -1, 1 } do
		local poleX = cx + side * (length / 2 + 1.5)
		B.model("Hoop", function()
			upright("Pole", { poleX, cz }, 0, 10, 0.6, "MetalDark", "Metal")
			B.part({
				Name = "Arm",
				Size = { 2, 0.3, 0.3 },
				Position = { poleX - side * 1, 9.6, cz },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			B.part({
				Name = "Backboard",
				Size = { 0.2, 3.6, 6 },
				Position = { poleX - side * 2, 9.6, cz },
				Color = "OffWhite",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
			upright("Rim", { poleX - side * 3, cz }, 8.4, 0.12, 1.8, "NeonOrange", "Metal", false)
			upright("Net", { poleX - side * 3, cz }, 7.2, 1.2, 1.5, "OffWhite", "Fabric", false).Transparency = 0.5
		end)
	end
	Pieces.stairs("Bleachers", { 0, 16 }, "+Z", 24, 3, 1, 2, "Wood", "WoodPlanks")
	tree("CourtTree", { -32, 26 })
	tree("CourtTree", { 32, 26 })
	trashCan({ 20, 20 })
end

-- Bus depot (south row, east): bus bays, a city bus you can climb onto, a bus shelter.
local function busDepot()
	paint("Asphalt", { 0, 0 }, { 54, 70 }, "Asphalt", "Asphalt")
	for _, x in { -12, 0, 12 } do
		paint("BayLine", { x, 2 }, { 0.3, 40 }, "LaneWhite", nil, 0.12)
	end
	Pieces.bus("CityBus", { -6, 2 }, 24, 90, "LaneYellow")
	busShelter({ 16, 8 })
end

---------------------------------------------------------------------------------------------------------------------
-- The valley
---------------------------------------------------------------------------------------------------------------------

-- The invisible walls along the valley's edge (the mountains rise behind them), a little outside it.
local function walls()
	local halfX, halfZ = VALLEY[1] / 2, VALLEY[2] / 2
	for _, wall in
		{
			{ { halfX + 2, 0 }, { 4, VALLEY[2] + 8 } },
			{ { -halfX - 2, 0 }, { 4, VALLEY[2] + 8 } },
			{ { 0, halfZ + 2 }, { VALLEY[1] + 8, 4 } },
			{ { 0, -halfZ - 2 }, { VALLEY[1] + 8, 4 } },
		}
	do
		B.part({
			Name = "BoundaryWall",
			Size = { wall[2][1], WALL_HEIGHT, wall[2][2] },
			Position = { wall[1][1], WALL_HEIGHT / 2, wall[1][2] },
			Color = "Glass",
			Transparency = 1,
			CastShadow = false,
		})
	end
end

local function decorate(plat: Platform)
	assert(plat.Id == "Center", "Small City has one platform")
	streets()
	local function at(column: number, row: number, fill: () -> ())
		local centre = block(column, row)
		B.within({ centre[1], 0, centre[2] }, fill)
	end
	at(1, 2, gasStation)
	at(2, 2, function()
		plaza(1, 38)
		tower("TowerA", { -8, 4 }, { 40, 96, 36 }, "CityGrey", "+X")
		statue({ 28, 4 })
	end)
	at(3, 2, function()
		plaza(-1, 38)
		tower("TowerB", { 8, -4 }, { 36, 120, 40 }, "CityBlue", "-X")
	end)
	at(4, 2, parkingLot)
	at(1, 3, function()
		houses(1)
	end)
	at(2, 3, park)
	at(3, 3, function()
		plaza(-1, 35)
		tower("TowerC", { 10, 8 }, { 36, 80, 30 }, "CityTan", "-Z")
	end)
	at(4, 3, function()
		houses(-1)
	end)
	at(1, 1, constructionSite)
	at(2, 1, dinerBlock)
	at(3, 1, court)
	at(4, 1, busDepot)
	walls()
	-- A few trees on the grass between the town and the mountains.
	for index, spot in { { -180, -150 }, { 180, 150 }, { -184, 60 }, { 184, -70 }, { 60, -150 }, { -70, 150 } } do
		tree(`ValleyTree{index}`, spot, 0, 1.3)
	end
end

--[[
	A mountain: a grass ridge (two wedges back to back, `length` along it, `width` across its foot, `height` tall,
	turned `yaw`), a narrower, taller rock core poking out of it and, on the tall ones, a snow cap a hair outside the
	rock (no flicker). `collide`: the near ring is solid, the far one is backdrop.
]]
local function mountain(at: { number }, length: number, width: number, height: number, yaw: number, collide: boolean)
	local place = placer(at, yaw, -2)
	local function ridge(name: string, l: number, w: number, h: number, y: number, color: string, material: string)
		for _, side in { -1, 1 } do
			B.part({
				Name = name,
				Size = { l, h, w / 2 },
				Position = place(0, y + h / 2, side * w / 4),
				Rotation = { 0, yaw + (if side < 0 then 0 else 180), 0 }, -- the tall ends meet at the ridge line
				Shape = "Wedge",
				Color = color,
				Material = material,
				CanCollide = collide,
				CastShadow = collide,
			})
		end
	end
	local rock = height * 1.3
	ridge("Slope", length, width, height, 0, "MountainGreen", "Grass")
	ridge("Rock", length * 0.7, width * 0.5, rock, 0, "MountainRock", "Rock")
	if rock >= 140 then
		local snow = rock * 0.22 * 1.08
		ridge("Snow", length * 0.4, width * 0.5 * 0.22 * 1.08, snow, rock - snow + 0.6, "Snow", "Snow")
	end
end

-- Off the valley: the ring of mountains (solid, Persistent so it never streams out), a farther ring of big hazy
-- mountains, the ground under them, and a tunnel portal where the avenue meets the mountains at each end.
local function scenery(_killY: number)
	local halfX, halfZ = VALLEY[1] / 2, VALLEY[2] / 2
	local sizes = {
		{ 120, 140, 95 },
		{ 140, 160, 125 },
		{ 100, 130, 85 },
		{ 130, 170, 135 },
		{ 110, 150, 110 },
	}
	local count = 0
	local function nextSize(): { number }
		count += 1
		return sizes[(count - 1) % #sizes + 1]
	end
	local ring = B.model("Mountains", function()
		-- North and south sides: ridges along X, their near foot on the valley's edge, clear of the tunnel's rock face (x
		-- ±30); a lower one over each tunnel.
		for _, side in { -1, 1 } do
			for _, x in { -170, -100, 100, 170 } do
				local size = nextSize()
				mountain({ x, side * (halfZ + size[2] / 2) }, size[1], size[2], size[3], 0, true)
			end
			mountain({ 0, side * (halfZ + 75) }, 100, 140, 70, 0, true)
		end
		-- East and west sides: ridges along Z.
		for _, side in { -1, 1 } do
			for _, z in { -130, -65, 0, 65, 130 } do
				local size = nextSize()
				mountain({ side * (halfX + size[2] / 2), z }, size[1], size[2], size[3], 90, true)
			end
		end
		-- The corners, turned 45°.
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				mountain({ sx * (halfX + 60), sz * (halfZ + 60) }, 150, 170, 140, 45 * sx * sz, true)
			end
		end
		-- The far ring: big, hazy and snowy, behind the near one.
		for index = 0, 13 do
			local angle = index / 14 * 2 * math.pi
			local spot = { math.sin(angle) * 620, math.cos(angle) * 540 }
			mountain(spot, 300, 320, 190 + (index % 3) * 40, math.deg(angle) + 90, false)
		end
	end)
	ring.ModelStreamingMode = B.Enum.ModelStreamingMode.Persistent
	B.part({
		Name = "FarGround",
		Size = { 4000, 1, 4000 },
		Position = { 0, -2.5, 0 },
		Color = "MountainGreen",
		Material = "Grass",
		CanCollide = false,
		CastShadow = false,
	})
	-- The tunnel portals: a concrete frame round a dark mouth, in a rock face, facing the valley.
	for _, side in { -1, 1 } do
		local z = side * (halfZ + 6)
		B.model("Tunnel", function()
			B.part({
				Name = "RockFace",
				Size = { 60, 34, 10 },
				Position = { 0, 15, z + side * 4 },
				Color = "MountainRock",
				Material = "Rock",
			})
			B.part({
				Name = "Mouth",
				Size = { 20, 13, 0.4 },
				Position = { 0, 6.5, z - side * 1.2 },
				Color = "Black",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
			for _, x in { -12, 12 } do
				B.part({
					Name = "Pier",
					Size = { 4, 16, 3 },
					Position = { x, 8, z - side * 2 },
					Color = "Concrete",
					Material = "Concrete",
				})
			end
			B.part({
				Name = "Lintel",
				Size = { 28, 4, 3 },
				Position = { 0, 15, z - side * 2 },
				Color = "Concrete",
				Material = "Concrete",
			})
		end)
	end
end

-- Builds the arena model at `origin` (world position of the valley floor's centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery)
end

return Layout
