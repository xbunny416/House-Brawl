--!strict
--[[
	Map 4: Shinjuku — the only arena in the vote since 2026-10-28. The owner asked for one new arena instead of the 3 old
	ones ("just store them somewhere, don't delete them"; Broken Highway, Junkyard Isles and Neon Motel stay built,
	switched off in Config.Maps.List), then "no floating island", then "want arena to look like jjk shenanigans" (the
	Shinjuku battleground of the Roblox game Jujutsu Shenanigans), then "add breakable walls and trash can throwables,
	town structures bigger and can enter", then: "replace the train station with another thing; bit bigger structures
	like the shops and towers; more polish and detail". This is our own Shinjuku-style district in that spirit (generic
	names, nothing copied).

	A ground arena (Layout.Ground): one flat district (the Center platform, 560 × 460, never falls) walled in by
	invisible walls, with tall city blocks behind them all round. Nobody falls: a Classic life ends at 0 HP. Day light.
	Its buildings are ones you can walk into (maps/lib/Rooms: hollow storeys 7 high, floors, switchback ramps, roofs), and
	their walls and windows break (BreakableWall pieces, Services/WallService), as do the block walls, the graveyard's
	stones and the hedges.

	Plan (north = +Z): along the north edge a high school (three storeys, a clock tower, a roof you can reach) with its
	gym and its schoolyard (a running track round a football pitch, a flagpole, a bike shed, a gate onto the main
	street), and a small shrine (torii gates, stone lanterns, a shrine hall) in the corner — where the station was until
	2026-10-28; the main street across (z 90); below it, either side of the avenue (x 0), the twin towers (11 storeys,
	a skybridge at the 9th, ladders up the outside to the roof); west of them the ramen shop and the plaza (a fountain)
	with the two-storey cafe, east the 24-hour mart, the graveyard and the arcade; the second street across (z −90);
	south of it a row of five three-storey shops, the three-storey jail with its cell and the comedy club with a stage,
	the courthouse and a two-storey mansion with a garage, a pocket park with cherry trees and swings. The mall (two
	floors, a ramp between them) and the bowling alley fill the west strip, apartments the east. Japanese streets:
	utility poles with wires, crosswalks, guardrails, street trees, bicycles, vending machines.
	Spots: 16 spawns (the schoolyard and the streets), 22 loose prop spots (on roofs, upper floors, the skybridge),
	trash cans and chairs where they belong (TypedProps), 8 breakables, 6 explosive barrels.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")
local Pieces = require("../lib/Pieces")
local Rooms = require("../lib/Rooms")

type Platform = Arena.Platform

local Layout = {}

Layout.Id = "Shinjuku"
Layout.Lighting = "Day"
Layout.Ground = true -- one walled-in ground platform instead of floating ones (the maps spec checks it differently)

local DISTRICT = { 560, 460 } -- X, Z: the playable ground inside the walls
local WALL_HEIGHT = 260
local ROAD = 20
local BREAKABLE = { "BreakableWall" }
-- The twin towers (x ±38): 40 wide, 11 storeys of 7, the skybridge on the 9th.
local TOWER = { X = 38, Z = 35, Size = 40, Floors = 11, Storey = 7, BridgeFloor = 9 }
local TOWER_ROOF = TOWER.Floors * TOWER.Storey + 0.6
local BRIDGE_Y = (TOWER.BridgeFloor - 1) * TOWER.Storey
local STOREY = 7 -- every other building's storey (6.5 of headroom)
local SCHOOL = { At = { 0, 196 }, Size = { 220, 40 }, Floors = 3 }
local SCHOOL_ROOF = SCHOOL.Floors * STOREY + 0.6
local CAFE = { At = { -40, -52 }, Size = { 42, 32 } }

Layout.Platforms = {
	{
		Id = "Center",
		Kind = "Center",
		Center = { 0, 0 },
		Size = DISTRICT,
		Top = 0,
		Thickness = 6,
		Color = "Concrete",
		Material = "Concrete",
	},
} :: { Platform }

Layout.Contents = {
	Center = {
		Spawns = {
			{ -150, 130 }, -- the schoolyard
			{ -50, 118 },
			{ 0, 136 },
			{ 50, 118 },
			{ 150, 130 },
			{ -100, 160 },
			{ 100, 160 },
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
		Props = {
			{ -TOWER.X, TOWER.Z, TOWER_ROOF }, -- the tower roofs
			{ TOWER.X, TOWER.Z, TOWER_ROOF },
			{ 0, TOWER.Z, BRIDGE_Y }, -- the skybridge
			{ -40, 25, BRIDGE_Y }, -- the west tower's 9th floor
			{ 40, 25, 4 * TOWER.Storey }, -- the east tower's 5th floor
			{ 40, 196, STOREY }, -- the school's 2nd floor and roof
			{ 60, 190, SCHOOL_ROOF },
			{ -225, 160 }, -- the gym
			{ 228, 198 }, -- the shrine hall
			{ -28, -45, STOREY }, -- the cafe upstairs and on its roof
			{ -30, -62, 2 * STOREY + 0.6 },
			{ 120, 46 }, -- the mart
			{ 55, -38 }, -- the graveyard
			{ 130, -50 }, -- the arcade
			{ -80, -55 }, -- the plaza
			{ -245, 20 }, -- the mall
			{ -205, -40 }, -- the bowling alley
			{ -90, -175 }, -- the lot behind the shops
			{ 90, -120 }, -- by the courthouse
			{ 130, -215 }, -- behind the mansion
			{ 232, -165 }, -- the pocket park
			{ -232, -110 }, -- by the jail
		},
		TypedProps = {
			-- Trash cans where a street has them: the school's front, the ramen shop, the mart, the shops, the park.
			{ At = { -30, 172 }, Type = "TrashCan" },
			{ At = { 40, 172 }, Type = "TrashCan" },
			{ At = { -97, 38 }, Type = "TrashCan" },
			{ At = { 110, 35 }, Type = "TrashCan" },
			{ At = { 140, 35 }, Type = "TrashCan" },
			{ At = { -132, -102 }, Type = "TrashCan" },
			{ At = { 215, -115 }, Type = "TrashCan" },
			-- Chairs where people sit: the ramen shop, the cafe, the comedy club, the court.
			{ At = { -131, 47 }, Type = "Chair" },
			{ At = { -119, 47 }, Type = "Chair" },
			{ At = { -33, -60 }, Type = "Chair" },
			{ At = { -35, -60, STOREY }, Type = "Chair" },
			{ At = { -238, -195 }, Type = "Chair" },
			{ At = { -226, -195 }, Type = "Chair" },
			{ At = { 45, -152 }, Type = "Chair" },
		},
		Explosives = {
			{ -175, 108 },
			{ -140, -90 },
			{ 0, 45 }, -- under the skybridge
			{ -200, -200 },
			{ 60, -200 },
			{ 210, -210 },
		},
		Structures = {
			{ Type = "VendingMachine", At = { -40, 106 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { 40, 106 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { 95, 35 }, Yaw = 0 },
			{ Type = "IceMachine", At = { 155, 35 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { -64, 10 }, Yaw = 0 },
			{ Type = "WreckedCar", At = { -25, -86 }, Yaw = 90 },
			{ Type = "WreckedCar", At = { -175, -40 }, Yaw = 0 },
			{ Type = "RoadBarrierStack", At = { 175, -150 }, Yaw = 0 },
		},
	},
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

-- A glass band wrapped round a box at height `y` (a little wider than the box, so it shows on all four sides).
local function glassBand(at: { number }, size: { number }, y: number, height: number?)
	B.part({
		Name = "GlassBand",
		Size = { size[1] + 0.3, height or 2.2, size[2] + 0.3 },
		Position = { at[1], y, at[2] },
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.1,
		CanCollide = false,
		CastShadow = false,
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

-- A white roadside guardrail along X from `x0` to `x1` at `z`: a top rail (solid) and a lower one, a post every 8.
local function guardrail(x0: number, x1: number, z: number)
	B.model("Guardrail", function()
		for _, rail in { { 2.1, 0.25, true }, { 1.1, 0.18, false } } do
			B.part({
				Name = "Rail",
				Size = { x1 - x0, rail[2], rail[2] },
				Position = { (x0 + x1) / 2, rail[1], z },
				Color = "OffWhite",
				Material = "Metal",
				CanCollide = rail[3],
			})
		end
		local posts = math.max(1, math.floor((x1 - x0) / 8))
		for index = 0, posts do
			B.part({
				Name = "Post",
				Size = { 0.25, 2.2, 0.25 },
				Position = { x0 + (x1 - x0) * index / posts, 1.1, z },
				Color = "OffWhite",
				Material = "Metal",
				CanCollide = false,
			})
		end
	end)
end

-- A parked car (solid: you can be knocked into it or stand on it), its length along Z turned `yaw`.
local function car(name: string, at: { number }, yaw: number, color: string)
	local place = placer(at, yaw)
	local turn = { 0, yaw, 0 }
	B.model(name, function()
		B.part({ Name = "Body", Size = { 4.4, 1.5, 8.4 }, Position = place(0, 1.25, 0), Rotation = turn, Color = color })
		B.part({
			Name = "Cabin",
			Size = { 4, 1.5, 4.6 },
			Position = place(0, 2.75, -0.3),
			Rotation = turn,
			Color = "Black",
			Material = "Glass",
			Transparency = 0.25,
		})
		B.part({
			Name = "Roof",
			Size = { 4, 0.2, 4 },
			Position = place(0, 3.6, -0.3),
			Rotation = turn,
			Color = color,
			CanCollide = false,
		})
		for _, lx in { -2.1, 2.1 } do
			for _, lz in { -2.8, 2.8 } do
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
		for _, lz in { -4.25, 4.25 } do
			for _, lx in { -1.5, 1.5 } do
				B.part({
					Name = if lz > 0 then "Headlight" else "TailLight",
					Size = { 0.9, 0.4, 0.1 },
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

-- A tree on `y`: a trunk (solid) and two balls of leaves (`leaf`: green, or pink for a cherry tree).
local function tree(name: string, at: { number }, leaf: string, y: number?)
	local base = y or 0
	B.model(name, function()
		upright("Trunk", at, base, 5, 0.9, "WoodDark", "Wood")
		B.part({
			Name = "Leaves",
			Size = { 6.5, 5.5, 6.5 },
			Position = { at[1], base + 6.5, at[2] },
			Shape = "Ball",
			Color = leaf,
			Material = "LeafyGrass",
			CanCollide = false,
		})
		B.part({
			Name = "LeavesTop",
			Size = { 4.4, 4, 4.4 },
			Position = { at[1] + 0.6, base + 8.6, at[2] - 0.4 },
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
		upright("Trunk", at, 0, 7, 0.8, "WoodDark", "Wood")
		for index, branch in { { 35, 0, 5.5 }, { -40, 120, 6.2 }, { 30, 240, 4.8 } } do
			local c, s = math.cos(math.rad(branch[2])), math.sin(math.rad(branch[2]))
			B.part({
				Name = `Branch{index}`,
				Size = { 0.3, 3.2, 0.3 },
				Position = { at[1] + c * 1.1, branch[3] + 1.2, at[2] + s * 1.1 },
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
	Pieces.block("Planter", at, { 5, 1.4, 5 }, "ConcreteDark", "Concrete")
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

-- A concrete utility pole (solid) with a crossbar and, when `transformer`, a grey transformer can.
local function utilityPole(at: { number }, transformer: boolean)
	B.model("UtilityPole", function()
		upright("Pole", at, 0, 12, 0.8, "ConcreteLight", "Concrete")
		B.part({
			Name = "Crossbar",
			Size = { 0.25, 0.25, 3.6 },
			Position = { at[1], 11.4, at[2] },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		if transformer then
			upright("Transformer", { at[1] + 0.9, at[2] }, 8, 1.8, 1.2, "Metal", "Metal", false)
		end
	end)
end

-- Three power lines from pole `a` to pole `b` (x, z), walk-through.
local function wires(a: { number }, b: { number })
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local length = math.sqrt(dx * dx + dz * dz)
	for _, wire in { { 11.55, 1.4 }, { 11.55, -1.4 }, { 10.6, 0 } } do
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

-- A basketball hoop (a pole, an arm, a backboard, a rim and a net) facing −`side` along X from `poleX`.
local function hoop(poleX: number, z: number, side: number, y: number?)
	local base = y or 0
	B.model("Hoop", function()
		upright("Pole", { poleX, z }, base, 10, 0.6, "MetalDark", "Metal")
		B.part({
			Name = "Backboard",
			Size = { 0.2, 3.6, 6 },
			Position = { poleX - side * 2, base + 9.6, z },
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.part({
			Name = "Arm",
			Size = { 2, 0.3, 0.3 },
			Position = { poleX - side * 1, base + 9.6, z },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		upright("Rim", { poleX - side * 3, z }, base + 8.4, 0.12, 1.8, "NeonOrange", "Metal", false)
		upright("Net", { poleX - side * 3, z }, base + 7.2, 1.2, 1.5, "OffWhite", "Fabric", false).Transparency = 0.5
	end)
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
				kerb({ 0, kz }, { DISTRICT[1], 0.5 }) -- the school side has no crossings
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
	-- Taxis by the school gate, parked cars, bicycles.
	car("Taxi", { -45, 85 }, 90, "LaneYellow")
	car("Taxi", { -56, 85 }, 90, "LaneYellow")
	car("ParkedCar", { 45, 95 }, -90, "OffWhite")
	car("ParkedCar", { 200, -86 }, -90, "CityBlue")
	car("ParkedCar", { -179, -170 }, 0, "Red")
	for index, x in { -150, -147.5, -90, -87.5, -30 } do
		bike({ x, -101.5 }, 90, if index % 2 == 0 then "Red" else "CityBlue")
	end
end

---------------------------------------------------------------------------------------------------------------------
-- The north: the school, its gym and yard, the shrine (where the station was until 2026-10-28)
---------------------------------------------------------------------------------------------------------------------

-- The high school: three storeys with rows of classroom windows front and back, a main door and two side doors onto
-- the yard, a stair up to the roof, a clock tower on the roof, the school's name over the door.
local function school()
	local at, size = SCHOOL.At, SCHOOL.Size
	Rooms.building({
		Name = "School",
		At = at,
		Size = size,
		Floors = SCHOOL.Floors,
		Storey = STOREY,
		Color = "Cream",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "-Z", At = 0, Width = 10, Height = 5.5 },
			{ Face = "-Z", At = -70, Width = 6, Height = 5.2 },
			{ Face = "-Z", At = 70, Width = 6, Height = 5.2 },
			{ Face = "+Z", At = 0, Width = 6, Height = 5.2 },
		},
		Windows = { Faces = { "-Z", "+Z" }, Width = 16, Height = 3.6, Sill = 1.4, Spacing = 22 },
		Stair = { At = { -20, 8 }, Along = "X", Width = 4 },
		Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
	})
	-- Horizontal bands between the storeys (the school's look), the entrance canopy, the name over the door.
	for floor = 1, SCHOOL.Floors - 1 do
		glassBand(at, size, floor * STOREY, 0.5)
	end
	B.part({
		Name = "EntranceCanopy",
		Size = { 16, 0.4, 5 },
		Position = { at[1], 5.9, at[2] - size[2] / 2 - 2.5 },
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	faceSign(at, size, "-Z", 0, 6.4, 24, 1.4, "Map.Shinjuku.Sign.School", "OffWhite", "Black")
	-- The clock tower on the roof.
	local tower = { at[1], at[2] - 6 }
	Pieces.block("ClockTower", tower, { 14, 12, 10 }, "OffWhite", "Concrete", SCHOOL_ROOF)
	Pieces.block("ClockTowerCap", tower, { 15, 1, 11 }, "ConcreteDark", "Concrete", SCHOOL_ROOF + 12)
	B.part({
		Name = "ClockFace",
		Size = { 0.3, 6, 6 },
		Position = { tower[1], SCHOOL_ROOF + 7, tower[2] - 5.1 },
		Rotation = { 0, 90, 0 },
		Shape = "Cylinder",
		Color = "OffWhite",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
	for _, hand in { { 0, 2.2 }, { 90, 1.6 } } do
		B.part({
			Name = "ClockHand",
			Size = { 0.3, hand[2], 0.1 },
			Position = { tower[1], SCHOOL_ROOF + 7 + hand[2] / 2 * math.cos(math.rad(hand[1])), tower[2] - 5.3 },
			Rotation = { 0, 0, hand[1] },
			Color = "Black",
			CanCollide = false,
		})
	end
	roofKit({ at[1] + 60, at[2] }, { 60, size[2] }, SCHOOL_ROOF, true)
	roofKit({ at[1] - 60, at[2] }, { 60, size[2] }, SCHOOL_ROOF, false)
	vendingRow({ 20, 172.5 }, 3, 180)
end

-- The gym: one tall hall with a wooden court, its lines and two hoops, high windows, doors onto the yard.
local function gym()
	local at, size = { -225, 170 }, { 80, 60 }
	Rooms.building({
		Name = "Gym",
		At = at,
		Size = size,
		Floors = 1,
		Storey = 14,
		Color = "CityBlue",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "+X", At = -15, Width = 8, Height = 6 },
			{ Face = "+X", At = 15, Width = 8, Height = 6 },
			{ Face = "-Z", At = 0, Width = 8, Height = 6 },
		},
		Windows = { Faces = { "+X", "-X", "+Z", "-Z" }, Width = 10, Height = 3, Sill = 9, Spacing = 14 },
		Roof = { Color = "ConcreteDark", Parapet = true },
	})
	local cx, cz, length, width = at[1], at[2], 56, 30
	for _, edge in
		{
			{ { cx, cz - width / 2 }, { length, 0.4 } },
			{ { cx, cz + width / 2 }, { length, 0.4 } },
			{ { cx - length / 2, cz }, { 0.4, width } },
			{ { cx + length / 2, cz }, { 0.4, width } },
			{ { cx, cz }, { 0.4, width } },
		}
	do
		paint("CourtLine", edge[1], edge[2], "OffWhite", nil, 0.13)
	end
	hoop(cx - length / 2 - 1.5, cz, -1)
	hoop(cx + length / 2 + 1.5, cz, 1)
	faceSign(at, size, "+X", 0, 10, 10, 2, "Map.Shinjuku.Sign.Gym", "OffWhite", "CityBlue")
	roofKit(at, size, 14.6, false)
	ladder({ at[1] + size[1] / 2 + 1, at[2] + 26 }, 0, 16) -- onto the roof, by the yard
end

-- The schoolyard: dirt with a red running track round a green football pitch, two goals, a flagpole, a bike shed,
-- benches and cherry trees, a guardrail along the main street with the gate in it.
local function schoolyard()
	paint("Yard", { 7.5, 138 }, { 375, 76 }, "SchoolYard", "Ground")
	-- The track: a rectangle and two half-circle ends, and the pitch inside it a little higher.
	paint("Track", { 0, 136 }, { 180, 56 }, "TrackRed", "Ground", 0.12)
	upright("TrackEnd", { -90, 136 }, 0.11, 0.02, 56, "TrackRed", "Ground", false)
	upright("TrackEnd", { 90, 136 }, 0.11, 0.02, 56, "TrackRed", "Ground", false)
	paint("Pitch", { 0, 136 }, { 180, 40 }, "Lawn", "Grass", 0.15)
	upright("PitchEnd", { -90, 136 }, 0.14, 0.02, 40, "Lawn", "Grass", false)
	upright("PitchEnd", { 90, 136 }, 0.14, 0.02, 40, "Lawn", "Grass", false)
	paint("HalfwayLine", { 0, 136 }, { 0.4, 40 }, "OffWhite", nil, 0.17)
	for _, side in { -1, 1 } do
		B.model("Goal", function()
			local x = side * 80
			for _, z in { 130, 142 } do
				upright("Post", { x, z }, 0, 4, 0.3, "OffWhite", "Metal")
			end
			B.part({
				Name = "Crossbar",
				Size = { 0.3, 0.3, 12 },
				Position = { x, 4, 136 },
				Color = "OffWhite",
				Material = "Metal",
				CanCollide = false,
			})
			B.part({
				Name = "Net",
				Size = { 0.1, 4, 12 },
				Position = { x + side * 2, 2, 136 },
				Color = "OffWhite",
				Material = "Fabric",
				Transparency = 0.6,
				CanCollide = false,
			})
		end)
	end
	-- The flagpole and its flag.
	upright("Flagpole", { -95, 172 }, 0, 20, 0.4, "Metal", "Metal")
	B.part({
		Name = "Flag",
		Size = { 4, 2.6, 0.1 },
		Position = { -92.8, 18.6, 172 },
		Color = "OffWhite",
		Material = "Fabric",
		CanCollide = false,
	})
	B.part({
		Name = "FlagSun",
		Size = { 0.12, 1.4, 1.4 },
		Position = { -92.8, 18.6, 171.9 },
		Rotation = { 0, 90, 0 },
		Shape = "Cylinder",
		Color = "Red",
		CanCollide = false,
	})
	-- The bike shed: a roof on posts over a row of bicycles.
	B.model("BikeShed", function()
		Pieces.block("Roof", { -150, 172 }, { 30, 0.4, 6 }, "TealDark", "Metal", 6)
		for _, x in { -164, -150, -136 } do
			for _, z in { 169.4, 174.6 } do
				Pieces.column("Post", { x, z }, 0, 6, 0.3, "MetalDark", "Metal")
			end
		end
	end)
	for index = 0, 5 do
		bike({ -161 + index * 4.4, 172 }, 0, if index % 2 == 0 then "Red" else "OffWhite")
	end
	bench({ -60, 170 }, 180)
	bench({ 60, 170 }, 180)
	for _, x in { -160, -130, 130, 160 } do
		tree("CherryTree", { x, 106 }, "SakuraPink")
	end
	-- The guardrail along the main street with the gate (two pillars, the school's name on a plate).
	guardrail(-180, -14, 101.5)
	guardrail(14, 195, 101.5)
	for _, side in { -1, 1 } do
		Pieces.block("GatePillar", { side * 12, 101.5 }, { 2, 6, 2 }, "ConcreteLight", "Concrete")
		Pieces.block("GateCap", { side * 12, 101.5 }, { 2.6, 0.5, 2.6 }, "ConcreteDark", "Concrete", 6)
	end
	B.sign({
		Name = "GatePlate",
		Size = { 1.8, 3.6, 0.2 },
		Position = { -12, 3.6, 100.4 },
		Color = "OffWhite",
		Material = "Marble",
		Key = "Map.Shinjuku.Sign.School",
		TextColor = "Black",
		CanCollide = false,
	})
end

-- The shrine in the north-east corner: two red torii over a stone path, stone lanterns, a shrine hall open at the front
-- (an offering box, a bell rope) under a gabled roof, cherry trees.
local function shrine()
	local x = 235
	paint("ShrinePath", { x, 150 }, { 6, 96 }, "Stone", "Cobblestone")
	local function torii(z: number)
		B.model("Torii", function()
			for _, side in { -1, 1 } do
				upright("Pillar", { x + side * 7, z }, 0, 12, 1.6, "ToriiRed", "SmoothPlastic")
			end
			B.part({
				Name = "Kasagi",
				Size = { 20, 1.2, 1.8 },
				Position = { x, 12.6, z },
				Color = "Black",
				Material = "SmoothPlastic",
			})
			B.part({
				Name = "Shimaki",
				Size = { 18, 0.8, 1.4 },
				Position = { x, 11.6, z },
				Color = "ToriiRed",
				Material = "SmoothPlastic",
			})
			B.part({
				Name = "Nuki",
				Size = { 16, 0.7, 1 },
				Position = { x, 9.6, z },
				Color = "ToriiRed",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end)
	end
	torii(112)
	torii(150)
	for _, z in { 130, 170 } do
		for _, side in { -1, 1 } do
			B.model("StoneLantern", function()
				local spot = { x + side * 6, z }
				Pieces.block("Base", spot, { 1.6, 0.6, 1.6 }, "Stone", "Slate")
				Pieces.block("Pillar", spot, { 0.7, 2.4, 0.7 }, "Stone", "Slate", 0.6)
				Pieces.block("Light", spot, { 1.4, 1.2, 1.4 }, "WarmLight", "Neon", 3)
				Pieces.block("Cap", spot, { 2, 0.5, 2 }, "Stone", "Slate", 4.2)
			end)
		end
	end
	local hall, hallSize = { x, 200 }, { 34, 24 }
	Rooms.building({
		Name = "ShrineHall",
		At = hall,
		Size = hallSize,
		Floors = 1,
		Storey = 10,
		Color = "Wood",
		Material = "WoodPlanks",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = { { Face = "-Z", At = 0, Width = 16, Height = 7.5 } },
		Roof = { Color = "WoodDark", Material = "Wood" },
	})
	-- A gabled roof over it (two wedges meeting along X).
	for _, side in { -1, 1 } do
		B.part({
			Name = "Gable",
			Size = { hallSize[1] + 4, 5, hallSize[2] / 2 + 2 },
			Position = { hall[1], 10.6 + 2.5, hall[2] + side * (hallSize[2] / 4 + 1) },
			Rotation = { 0, if side < 0 then 0 else 180, 0 }, -- each wedge's tall end toward the ridge
			Shape = "Wedge",
			Color = "AsphaltDark",
			Material = "Slate",
		})
	end
	Pieces.block("OfferingBox", { x, 206 }, { 5, 2.4, 2.4 }, "WoodDark", "Wood")
	B.part({
		Name = "BellRope",
		Size = { 0.3, 6, 0.3 },
		Position = { x, 6, 203.5 },
		Color = "ToriiRed",
		Material = "Fabric",
		CanCollide = false,
	})
	for _, spot in { { 212, 125 }, { 258, 125 }, { 212, 175 }, { 258, 175 } } do
		tree("CherryTree", spot, "SakuraPink")
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
		Rooms.building({
			Name = if side < 0 then "TowerWest" else "TowerEast",
			At = { x, z },
			Size = { TOWER.Size, TOWER.Size },
			Floors = TOWER.Floors,
			Storey = TOWER.Storey,
			Color = if side < 0 then "CityGrey" else "CityBlue",
			FloorColor = "ConcreteLight",
			Openings = {
				{ Face = "-Z", At = 0, Width = 10, Height = 5.5 },
				{ Face = "-Z", At = -13, Width = 14, Height = 5, Bottom = 0.4, Glass = true },
				{ Face = "-Z", At = 13, Width = 14, Height = 5, Bottom = 0.4, Glass = true },
				{ Face = "+Z", At = 0, Width = 10, Height = 5.5 },
				{ Face = inner, At = 0, Width = 8, Height = 5, Floor = TOWER.BridgeFloor },
			},
			Windows = {
				Faces = { "+X", "-X", "+Z", "-Z" },
				Width = 30,
				Height = 4.2,
				Sill = 0.8,
				Spacing = 34,
				From = 2,
			},
			Stair = { At = { side * 12, 10 }, Along = "Z", Width = 4 },
			Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
		})
		B.part({
			Name = "EntranceCanopy",
			Size = { 14, 0.4, 4 },
			Position = { x, 6, z - half - 2 },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		ladder({ x + side * (half + 1), z + half - 3 }, 0, 80) -- past the roof's parapet (+78.8)
		B.sign({
			Name = "Billboard",
			Size = { 28, 10, 0.5 },
			Position = { x, 66, z - half - 0.5 },
			Color = if index == 1 then "Red" else "CityBlue",
			Material = "SmoothPlastic",
			Key = if index == 1 then "Map.Shinjuku.Sign.AdCola" else "Map.Shinjuku.Sign.AdNight",
			TextColor = "OffWhite",
			CanCollide = false,
		})
		acUnit({ x - side * 12, z - 12 }, TOWER_ROOF)
		acUnit({ x - side * 12, z + 12 }, TOWER_ROOF)
		waterTank({ x + side * 10, z - 10 }, TOWER_ROOF)
	end
	-- The skybridge: a steel deck between the 9th floors' doors, glass sides (they break) and a roof.
	local gap = (TOWER.X - TOWER.Size / 2) * 2
	B.model("Skybridge", function()
		Pieces.block("Deck", { 0, TOWER.Z }, { gap, 1, 10 }, "MetalDark", "DiamondPlate", BRIDGE_Y - 1)
		for _, dz in { -4.85, 4.85 } do
			for _, dx in { -gap / 4, gap / 4 } do
				B.part({
					Name = "Glass",
					Size = { gap / 2, 6.2, 0.3 },
					Position = { dx, BRIDGE_Y + 3.1, TOWER.Z + dz },
					Color = "Glass",
					Material = "Glass",
					Transparency = 0.45,
					Tags = BREAKABLE,
				})
			end
		end
		Pieces.block("Roof", { 0, TOWER.Z }, { gap, 0.4, 10.4 }, "MetalDark", "Metal", BRIDGE_Y + 6.2)
	end)
end

-- The cafe at the plaza's corner: two storeys and a roof terrace up a switchback stair, a counter and tables, a big
-- glass front onto the plaza, a CAFE sign and an awning.
local function cafe()
	local at, size = CAFE.At, CAFE.Size
	Rooms.building({
		Name = "Cafe",
		At = at,
		Size = size,
		Floors = 2,
		Storey = STOREY,
		Color = "Cream",
		FloorColor = "Wood",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "+Z", At = 0, Width = 10, Height = 5 },
			{ Face = "+Z", At = -14, Width = 10, Height = 4, Bottom = 1, Glass = true },
			{ Face = "+Z", At = 14, Width = 10, Height = 4, Bottom = 1, Glass = true },
			{ Face = "+X", At = 0, Width = 6, Height = 5 },
		},
		Windows = { Faces = { "-X", "-Z", "+Z", "+X" }, Width = 6, Height = 3, Sill = 1.5, Spacing = 9, From = 2 },
		Stair = { At = { -13, 7 }, Along = "X", Width = 3.5 },
		Roof = { Color = "Red", Hatch = true, Parapet = true },
	})
	Pieces.block("Counter", { at[1] + 4, at[2] - 13 }, { 18, 3, 2 }, "WoodDark", "Wood")
	Pieces.block("CoffeeMachine", { at[1] + 9, at[2] - 13 }, { 2, 1.6, 1.2 }, "MetalDark", "Metal", 3)
	for _, spot in { { -28, -48 }, { -28, -60 } } do
		smallTable(spot)
	end
	smallTable({ -28, -60 }, STOREY)
	faceSign(at, size, "+Z", 0, 6, 12, 1.4, "Map.Shinjuku.Sign.Cafe", "WoodDark", "Cream")
	B.part({
		Name = "Awning",
		Size = { 16, 0.3, 3 },
		Position = { at[1], 5.4, at[2] + size[2] / 2 + 1.5 },
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
	paint("PlazaPavers", { -87.5, -35 }, { 155, 90 }, "ConcreteLight", "Pavement")
	for x = -160, -14, 12 do
		paint("PaverStripe", { x, -35 }, { 0.6, 90 }, "ConcreteDark", "Pavement", 0.12)
	end
	upright("FountainBasin", { -100, -35 }, 0, 1.2, 12, "Concrete", "Concrete")
	upright("FountainWater", { -100, -35 }, 1.05, 0.1, 10.6, "Glass", "Glass", false)
	upright("FountainColumn", { -100, -35 }, 1.2, 2.6, 1.4, "Concrete", "Concrete")
	upright("FountainBowl", { -100, -35 }, 3.8, 0.5, 4.4, "Concrete", "Concrete")
	for _, at in { { -150, -70 }, { -150, 0 }, { -80, 0 } } do
		planterTree(at)
	end
	bench({ -105, -72 }, 0)
	bench({ -80, -12 }, 180)
end

-- The ramen shop on the main street side, its front onto the plaza: a counter with stools, tables, curtains over
-- the door, red lanterns, a RAMEN sign and a rooftop sign.
local function ramen()
	local at, size = { -125, 55 }, { 46, 30 }
	Rooms.building({
		Name = "Ramen",
		At = at,
		Size = size,
		Floors = 1,
		Storey = 9,
		Color = "Brick",
		Material = "Brick",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "-Z", At = 0, Width = 10, Height = 6 },
			{ Face = "-Z", At = -15, Width = 10, Height = 4, Bottom = 1.2, Glass = true },
			{ Face = "-Z", At = 15, Width = 10, Height = 4, Bottom = 1.2, Glass = true },
		},
		Windows = { Faces = { "+X", "-X" }, Width = 5, Height = 3, Sill = 2, Spacing = 8 },
		Roof = { Color = "AsphaltDark", Material = "Slate", Parapet = true },
	})
	Pieces.block("Counter", { at[1], at[2] + 8 }, { 28, 3.4, 2 }, "Wood", "Wood")
	for sx = -12, 12, 6 do
		upright("Stool", { at[1] + sx, at[2] + 5.5 }, 0, 2, 1.1, "Red", "SmoothPlastic")
	end
	for _, dx in { -12, 12 } do
		smallTable({ at[1] + dx, 47 })
	end
	faceSign(at, size, "-Z", 0, 7.6, 14, 1.8, "Map.Shinjuku.Sign.Ramen", "Black", "Cream")
	for index = 0, 3 do
		B.part({
			Name = "Curtain",
			Size = { 2.4, 2.2, 0.1 },
			Position = { at[1] - 3.75 + index * 2.5, 4.9, at[2] - size[2] / 2 - 0.2 },
			Color = "TealDark",
			Material = "Fabric",
			CanCollide = false,
		})
	end
	for _, dx in { -22, 22 } do
		B.part({
			Name = "Lantern",
			Size = { 1.4, 1.8, 1.4 },
			Position = { at[1] + dx, 6.4, at[2] - size[2] / 2 - 1 },
			Shape = "Ball",
			Color = "Red",
			Material = "Neon",
			CanCollide = false,
		})
	end
	-- A rooftop sign facing the plaza.
	for _, dx in { -6, 6 } do
		Pieces.column("SignPost", { at[1] + dx, at[2] - 10 }, 9.6, 13, 0.4, "MetalDark", "Metal")
	end
	B.sign({
		Name = "RoofSign",
		Size = { 16, 4, 0.4 },
		Position = { at[1], 15, at[2] - 10 },
		Color = "Red",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Ramen",
		TextColor = "OffWhite",
		CanCollide = false,
	})
	acUnit({ at[1] + 14, at[2] + 8 }, 9.6)
end

-- The 24-hour mart: a big glass front, shelves and a drinks cooler inside, a counter by the door, a striped sign
-- band; vending machines on its side.
local function mart()
	local at, size = { 125, 55 }, { 46, 30 }
	Rooms.building({
		Name = "Mart",
		At = at,
		Size = size,
		Floors = 1,
		Storey = 9,
		Color = "OffWhite",
		FloorColor = "OffWhite",
		FloorMaterial = "SmoothPlastic",
		Openings = {
			{ Face = "-Z", At = 0, Width = 10, Height = 6 },
			{ Face = "-Z", At = -14, Width = 14, Height = 5.6, Bottom = 0.4, Glass = true },
			{ Face = "-Z", At = 14, Width = 14, Height = 5.6, Bottom = 0.4, Glass = true },
		},
		Roof = { Color = "OffWhite", Parapet = true },
	})
	for _, dz in { -2, 3, 8 } do
		Pieces.block("Shelf", { at[1] + 2, at[2] + dz }, { 20, 4, 1.6 }, "OffWhite", "Metal")
	end
	Pieces.block("Cooler", { at[1] + 21.4, at[2] + 2 }, { 1.6, 6, 18 }, "Glass", "Glass")
	Pieces.block("Counter", { at[1] - 17, at[2] - 7 }, { 2, 3.4, 6 }, "WoodDark", "Wood")
	panel("SignBand", at, size, "-Z", 0, 7.7, size[1], 2.2, "OffWhite")
	panel("Stripe", at, size, "-Z", 0, 6.3, size[1], 0.6, "Teal")
	faceSign(at, size, "-Z", 0, 7.7, 16, 1.6, "Map.Shinjuku.Sign.Mart", "OffWhite", "TealDark")
	vending({ at[1] + size[1] / 2 + 1.3, at[2] - 2 }, 90, "Red")
	vending({ at[1] + size[1] / 2 + 1.3, at[2] + 1.4 }, 90, "CityBlue")
	roofKit(at, size, 9.6, true)
end

-- The graveyard: a low stone wall with a gap on the north, rows of gravestones, three bare trees. The wall and the
-- stones break.
local function graveyard()
	local at, size = { 55, -50 }, { 50, 44 }
	local x0, x1, z0, z1 = at[1] - size[1] / 2, at[1] + size[1] / 2, at[2] - size[2] / 2, at[2] + size[2] / 2
	B.model("Graveyard", function()
		paint("Ground", at, size, "GraveGrass", "Grass")
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
		for _, z in { -62, -53 } do
			for _, x in { 37, 46, 55, 64, 73 } do
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
		for _, spot in { { 35, -33 }, { 77, -68 }, { 76, -33 } } do
			deadTree(spot)
		end
	end)
end

-- The arcade by the second street: two rows of game cabinets inside, a glass front, neon trim and a big ARCADE sign.
local function arcade()
	local at, size = { 130, -50 }, { 46, 38 }
	Rooms.building({
		Name = "Arcade",
		At = at,
		Size = size,
		Floors = 1,
		Storey = 12,
		Color = "ArcadeBlue",
		FloorColor = "Black",
		Openings = {
			{ Face = "-Z", At = 0, Width = 10, Height = 7 },
			{ Face = "-Z", At = -15, Width = 12, Height = 6, Bottom = 0.5, Glass = true },
			{ Face = "-Z", At = 15, Width = 12, Height = 6, Bottom = 0.5, Glass = true },
			{ Face = "+Z", At = 0, Width = 6, Height = 6 },
		},
		Roof = { Color = "ArcadeBlue", Parapet = true },
	})
	for _, row in { { -58, 0 }, { -42, 180 } } do
		for index = 0, 6 do
			local x = 113 + index * 5.6
			local place = placer({ x, row[1] }, row[2])
			B.model("Cabinet", function()
				B.part({
					Name = "Body",
					Size = { 2.6, 6.4, 2.2 },
					Position = place(0, 3.2, 0),
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
	for index, color in { "NeonPink", "NeonTeal" } do
		B.part({
			Name = "NeonTrim",
			Size = { size[1] + 0.4, 0.3, size[2] + 0.4 },
			Position = { at[1], 12 - index * 0.8, at[2] },
			Color = color,
			Material = "Neon",
			CanCollide = false,
			CastShadow = false,
		})
	end
	faceSign(at, size, "-Z", 0, 9.4, 20, 3, "Map.Shinjuku.Sign.Arcade", "Black", "NeonPink", true)
	roofKit(at, size, 12.6, false)
	ladder({ at[1] + size[1] / 2 + 1, at[2] + 15 }, 0, 14) -- onto the roof from the east side
end

---------------------------------------------------------------------------------------------------------------------
-- The west strip: the mall and the bowling alley; the east strip: apartments
---------------------------------------------------------------------------------------------------------------------

local function mall()
	local at, size = { -232, 25 }, { 80, 96 }
	Rooms.building({
		Name = "Mall",
		At = at,
		Size = size,
		Floors = 2,
		Storey = 8,
		Color = "CityTan",
		FloorColor = "ConcreteLight",
		Openings = {
			{ Face = "+X", At = 0, Width = 14, Height = 6 },
			{ Face = "+X", At = -24, Width = 18, Height = 5.5, Bottom = 0.5, Glass = true },
			{ Face = "+X", At = 24, Width = 18, Height = 5.5, Bottom = 0.5, Glass = true },
			{ Face = "+Z", At = 0, Width = 10, Height = 5 },
		},
		Windows = { Faces = { "+X", "+Z", "-Z" }, Width = 12, Height = 3, Sill = 2, Spacing = 16, From = 2 },
		Stair = { At = { 0, 0 }, Along = "Z", Width = 6 },
		Roof = { Color = "ConcreteDark", Parapet = true },
	})
	-- Shop stalls along the back wall on both floors.
	local colors = { "ShopRed", "ShopTeal", "ShopYellow", "ShopPink" }
	for _, y in { 0, 8 } do
		for index, z in { -10, 10, 30, 50 } do
			Pieces.block("Stall", { -262, z }, { 10, 4, 6 }, colors[index], "SmoothPlastic", y)
		end
	end
	for index, color in { "NeonPink", "ShopYellow", "NeonTeal", "ShopOrange" } do
		panel(`Graffiti{index}`, at, size, "+Z", -27 + (index - 1) * 18, 4 + (index % 2), 11, 4.5, color)
	end
	faceSign(at, size, "+X", 0, 7, 18, 1.8, "Map.Shinjuku.Sign.Mall", "CityBlue", "OffWhite")
	-- A big sign on the roof facing the street.
	for _, dz in { -10, 10 } do
		Pieces.column("SignPost", { at[1] + 30, at[2] + dz }, 16.6, 20, 0.5, "MetalDark", "Metal")
	end
	B.sign({
		Name = "RoofSign",
		Size = { 26, 6, 0.5 },
		Position = { at[1] + 30, 23, at[2] },
		Rotation = B.yaw("East"),
		Color = "CityBlue",
		Material = "SmoothPlastic",
		Key = "Map.Shinjuku.Sign.Mall",
		TextColor = "OffWhite",
		CanCollide = false,
	})
	ladder({ at[1] + size[1] / 2 + 1, at[2] + 45 }, 0, 18)
	roofKit({ at[1] - 10, at[2] }, { 50, size[2] }, 16.6, true)
end

local function bowling()
	local at, size = { -232, -52 }, { 80, 48 }
	Rooms.building({
		Name = "BowlingAlley",
		At = at,
		Size = size,
		Floors = 1,
		Storey = 10,
		Color = "ShopRed",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "+X", At = 0, Width = 10, Height = 6 },
			{ Face = "+X", At = -14, Width = 10, Height = 5, Bottom = 0.5, Glass = true },
			{ Face = "+X", At = 14, Width = 10, Height = 5, Bottom = 0.5, Glass = true },
		},
		Roof = { Color = "ShopRed", Parapet = true },
	})
	-- Five lanes toward the back wall: light wood with dark gutters and three pins at the end of each.
	for _, z in { -68, -60, -52, -44, -36 } do
		paint("Lane", { -238, z }, { 52, 4.6 }, "Cream", "WoodPlanks", 0.13)
		paint("Gutter", { -238, z + 2.7 }, { 52, 0.8 }, "Black", nil, 0.13)
		for _, dz in { -1, 0, 1 } do
			upright("Pin", { -262 + math.abs(dz) * 1.2, z + dz }, 0.15, 1.4, 0.4, "OffWhite", "SmoothPlastic", false)
		end
	end
	faceSign(at, size, "+X", 0, 7.6, 16, 2.4, "Map.Shinjuku.Sign.Bowling", "OffWhite", "Red")
	upright("GiantPin", { -205, -52 }, 10.6, 6, 2.6, "OffWhite", "SmoothPlastic", false) -- on the roof (+10.6)
	upright("PinStripe", { -205, -52 }, 14.6, 0.6, 2.7, "Red", "SmoothPlastic", false)
	B.part({
		Name = "PinHead",
		Size = { 2.2, 2.2, 2.2 },
		Position = { -205, 17.4, -52 },
		Shape = "Ball",
		Color = "OffWhite",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
end

-- An apartment block `size` (X, height, Z) — solid, not one to walk into: walls, a balcony strip and glass every
-- floor on its street face (−X), AC units on the balconies, water tanks on the roof.
local function apartments(name: string, at: { number }, size: { number }, color: string)
	B.model(name, function()
		Pieces.block("Walls", at, size, color, "Concrete")
		local front = at[1] - size[1] / 2
		for floor = 1, math.floor(size[2] / 4.4) - 1 do
			local y = floor * 4.4
			B.part({
				Name = "Balcony",
				Size = { 1.6, 0.3, size[3] - 2 },
				Position = { front - 0.8, y, at[2] },
				Color = "OffWhite",
				Material = "Concrete",
				CanCollide = false,
			})
			B.part({
				Name = "BalconyRail",
				Size = { 0.2, 1, size[3] - 2 },
				Position = { front - 1.5, y + 0.65, at[2] },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			panel("Windows", at, { size[1], size[3] }, "-X", 0, y + 2.2, size[3] - 4, 2.2, "Glass", "Glass")
		end
		waterTank({ at[1] + 15, at[2] }, size[2])
		waterTank({ at[1] - 15, at[2] + 10 }, size[2])
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The south: the shop row, the jail and the comedy club, the courthouse and the mansion, the pocket park
---------------------------------------------------------------------------------------------------------------------

local SHOP_Z = -117

local function shopRow()
	for index, entry in
		{
			{ -147, "ShopRed", "Map.Shinjuku.Sign.Books" },
			{ -117, "ShopYellow", "Map.Shinjuku.Sign.Electronics" },
			{ -87, "ShopTeal", "Map.Shinjuku.Sign.Karaoke" },
			{ -57, "ShopPink", "Map.Shinjuku.Sign.Subs" },
			{ -27, "ShopOrange", "Map.Shinjuku.Sign.Sweets" },
		}
	do
		local at, size = { entry[1], SHOP_Z }, { 30, 26 }
		local front = at[2] + size[2] / 2
		Rooms.building({
			Name = `Shop{index}`,
			At = at,
			Size = size,
			Floors = 3,
			Storey = STOREY,
			Color = entry[2],
			FloorColor = "ConcreteLight",
			Openings = {
				{ Face = "+Z", At = 0, Width = 5, Height = 5.2 },
				{ Face = "+Z", At = -8.5, Width = 9, Height = 4.4, Bottom = 0.6, Glass = true },
				{ Face = "+Z", At = 8.5, Width = 9, Height = 4.4, Bottom = 0.6, Glass = true },
				{ Face = "-Z", At = 8, Width = 3, Height = 5.2 },
			},
			Windows = { Faces = { "+Z", "-Z" }, Width = 7, Height = 2.6, Sill = 1.4, Spacing = 9, From = 2 },
			Stair = { At = { -6, -6 }, Along = "X", Width = 2.5 },
			Roof = { Color = "ConcreteDark", Parapet = true },
		})
		faceSign(at, size, "+Z", 0, 6.3, 16, 1.2, entry[3], "OffWhite", "Black")
		B.part({
			Name = "Awning",
			Size = { 26, 0.3, 2.4 },
			Position = { at[1], 5.5, front + 1.2 },
			Rotation = { 12, 0, 0 },
			Color = entry[2],
			Material = "Fabric",
			CanCollide = false,
		})
		B.part({
			Name = "VerticalSign",
			Size = { 1.6, 12, 0.4 },
			Position = { at[1] + 13.5, 13, front + 0.5 },
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
		Pieces.block("Counter", { at[1] + 7, at[2] - 8 }, { 7, 3, 1.6 }, "WoodDark", "Wood")
		Pieces.block("Shelf", { at[1] + 12, at[2] + 3 }, { 1.2, 4, 8 }, "WoodMid", "Wood")
		roofKit(at, size, 3 * STOREY + 0.6, index % 2 == 1)
	end
	-- Behind the shops: a back lot with dumpsters, manholes and broken-up block walls.
	for _, at in { { -50, -136 }, { -120, -138 } } do
		Pieces.block("Dumpster", at, { 5, 3.4, 3 }, "Bottle", "Metal")
	end
	for _, at in { { -70, -190 }, { -30, -210 } } do
		upright("Manhole", at, 0.1, 0.04, 2.4, "MetalDark", "DiamondPlate", false)
	end
	for _, piece in { { -165, -140 }, { -125, -100 }, { -80, -55 }, { -40, -15 } } do
		blockWall({ piece[1], -152 }, { piece[2], -152 })
	end
end

local function jailAndClub()
	local jail, jailSize = { -232, -145 }, { 50, 34 }
	Rooms.building({
		Name = "Jail",
		At = jail,
		Size = jailSize,
		Floors = 3,
		Storey = STOREY,
		Color = "LightPurple",
		FloorColor = "ConcreteLight",
		Openings = {
			{ Face = "+Z", At = 0, Width = 6, Height = 5.2 },
			{ Face = "+X", At = -3, Width = 4, Height = 5.2 }, -- into the cell
		},
		Windows = { Faces = { "+Z", "-X", "-Z", "+X" }, Width = 3, Height = 2.4, Sill = 2.4, Spacing = 6 },
		Stair = { At = { -18, 0 }, Along = "Z", Width = 3 },
		Roof = { Color = "Purple", Parapet = true },
	})
	faceSign(jail, jailSize, "+Z", 0, 20, 8, 1.2, "Map.Shinjuku.Sign.Jail", "OffWhite", "Black")
	-- The barred cell on its east side (the bars don't break).
	local cell = { jail[1] + jailSize[1] / 2 + 4, jail[2] - 3 }
	B.model("Cell", function()
		Pieces.block("CellRoof", cell, { 8, 0.4, 10 }, "MetalDark", "Metal", 6.6)
		for z = cell[2] - 4.5, cell[2] + 4.5, 1 do
			upright("Bar", { cell[1] + 3.9, z }, 0, 6.6, 0.2, "MetalDark", "Metal")
		end
		for x = cell[1] - 3.5, cell[1] + 3, 1 do
			for _, z in { cell[2] - 4.9, cell[2] + 4.9 } do
				upright("Bar", { x, z }, 0, 6.6, 0.2, "MetalDark", "Metal")
			end
		end
	end)
	roofKit(jail, jailSize, 3 * STOREY + 0.6, false)
	local club, clubSize = { -232, -200 }, { 46, 28 }
	Rooms.building({
		Name = "ComedyClub",
		At = club,
		Size = clubSize,
		Floors = 1,
		Storey = 9,
		Color = "Purple",
		FloorColor = "Black",
		FloorMaterial = "Carpet",
		Openings = { { Face = "+Z", At = 0, Width = 6, Height = 5 } },
		Windows = { Faces = { "+X", "-X" }, Width = 4, Height = 2.4, Sill = 3, Spacing = 8 },
		Roof = { Color = "Black", Parapet = true },
	})
	Pieces.block("Stage", { club[1], club[2] - 9 }, { 34, 1.5, 7 }, "WoodDark", "WoodPlanks")
	upright("MicStand", { club[1], club[2] - 9 }, 1.5, 4.4, 0.2, "MetalDark", "Metal", false)
	panel("Curtain", club, { clubSize[1] - 1.8, clubSize[2] - 1.8 }, "-Z", 0, 5, 34, 7, "Red", "Fabric") -- the back wall
	faceSign(club, clubSize, "+Z", 0, 7, 16, 1.8, "Map.Shinjuku.Sign.Comedy", "Black", "LaneYellow", true)
	for index = 0, 8 do
		B.part({
			Name = "MarqueeLight",
			Size = { 0.5, 0.5, 0.5 },
			Position = { club[1] - 10 + index * 2.5, 8.4, club[2] + clubSize[2] / 2 + 0.4 },
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
	Rooms.building({
		Name = "Courthouse",
		At = court,
		Size = courtSize,
		Floors = 1,
		Storey = 11,
		Color = "OffWhite",
		Material = "Marble",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = { { Face = "+Z", At = 0, Width = 8, Height = 7 } },
		Windows = { Faces = { "+X", "-X", "+Z" }, Width = 3, Height = 6, Sill = 2.5, Spacing = 7 },
		Roof = { Color = "OffWhite", Material = "Marble", Parapet = true },
	})
	Pieces.block("Dais", { court[1], court[2] - 10 }, { 22, 1, 6 }, "WoodDark", "Wood")
	Pieces.block("JudgeBench", { court[1], court[2] - 10.5 }, { 16, 3, 3 }, "WoodDark", "Wood", 1)
	for _, dz in { 2, 9 } do
		Pieces.block("Pew", { court[1] + 6, court[2] + dz }, { 18, 1.4, 1.2 }, "WoodMid", "Wood")
	end
	B.model("Portico", function()
		Pieces.block("Floor", { court[1], front + 2.5 }, { 52, 1.2, 5 }, "OffWhite", "Marble")
		Pieces.block("Roof", { court[1], front + 2.5 }, { 52, 1, 5.4 }, "OffWhite", "Marble", 11)
		for index = 0, 5 do
			Pieces.column(
				"Column",
				{ court[1] - 23 + index * 9.2, front + 3.5 },
				1.2,
				11,
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
		Position = { court[1], 12.7, front + 5.3 },
		Rotation = B.yaw("North"),
		Color = "OffWhite",
		Material = "Marble",
		Key = "Map.Shinjuku.Sign.Court",
		TextColor = "Black",
		CanCollide = false,
	})
	-- The mansion: two storeys up a stair, a garage beside it, a hedge with a gap along the front.
	Rooms.building({
		Name = "Mansion",
		At = { 135, -190 },
		Size = { 42, 30 },
		Floors = 2,
		Storey = STOREY,
		Color = "Cream",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = { { Face = "+Z", At = 0, Width = 5, Height = 5.2 } },
		Windows = { Faces = { "+X", "-X", "+Z", "-Z" }, Width = 3, Height = 3, Sill = 2, Spacing = 6 },
		Stair = { At = { -12, -5 }, Along = "X", Width = 3 },
		Roof = { Color = "AsphaltDark", Material = "Slate", Parapet = true },
	})
	Rooms.building({
		Name = "Garage",
		At = { 100, -192 },
		Size = { 18, 20 },
		Floors = 1,
		Storey = 6,
		Color = "Cream",
		Openings = { { Face = "+Z", At = 0, Width = 12, Height = 5.2 } },
		Roof = { Color = "AsphaltDark", Material = "Slate" },
	})
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

-- The pocket park: lawn, a path, cherry trees, benches, vending machines and a swing set.
local function pocketPark()
	paint("Lawn", { 232.5, -165 }, { 95, 130 }, "Lawn", "Grass")
	paint("Path", { 232.5, -165 }, { 4, 130 }, "ConcreteLight", "Pavement", 0.06)
	for index, at in { { 205, -115 }, { 260, -115 }, { 205, -170 }, { 260, -190 }, { 232, -215 } } do
		tree(`CherryTree{index}`, at, "SakuraPink")
	end
	bench({ 222, -140 }, 90)
	bench({ 243, -185 }, -90)
	vendingRow({ 265, -140 }, 2, -90)
	B.model("SwingSet", function()
		for _, x in { 250, 262 } do
			for _, dz in { -1.4, 1.4 } do
				B.part({
					Name = "Leg",
					Size = { 0.3, 7, 0.3 },
					Position = { x, 3.4, -150 + dz },
					Rotation = { dz * 8, 0, 0 },
					Color = "TealDark",
					Material = "Metal",
				})
			end
		end
		B.part({
			Name = "TopBar",
			Size = { 12.4, 0.3, 0.3 },
			Position = { 256, 6.8, -150 },
			Color = "TealDark",
			Material = "Metal",
		})
		for _, x in { 253.5, 258.5 } do
			for _, dx in { -0.7, 0.7 } do
				B.part({
					Name = "Chain",
					Size = { 0.08, 4.6, 0.08 },
					Position = { x + dx, 4.5, -150 },
					Color = "Metal",
					Material = "Metal",
					CanCollide = false,
				})
			end
			B.part({
				Name = "SwingSeat",
				Size = { 1.8, 0.2, 0.8 },
				Position = { x, 2.2, -150 },
				Color = "Black",
				CanCollide = false,
			})
		end
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The district
---------------------------------------------------------------------------------------------------------------------

-- The invisible walls along the district's edge (the city blocks behind rise past them).
local function walls()
	local halfX, halfZ = DISTRICT[1] / 2, DISTRICT[2] / 2
	for _, wall in
		{
			{ { halfX + 2, 0 }, { 4, DISTRICT[2] + 8 } },
			{ { -halfX - 2, 0 }, { 4, DISTRICT[2] + 8 } },
			{ { 0, halfZ + 2 }, { DISTRICT[1] + 8, 4 } },
			{ { 0, -halfZ - 2 }, { DISTRICT[1] + 8, 4 } },
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
	assert(plat.Id == "Center", "Shinjuku has one platform")
	streets()
	school()
	gym()
	schoolyard()
	shrine()
	twinTowers()
	plaza()
	cafe()
	ramen()
	mart()
	graveyard()
	arcade()
	mall()
	bowling()
	apartments("ApartmentsNorth", { 232, 45 }, { 80, 28, 44 }, "Cream")
	apartments("ApartmentsSouth", { 232, -45 }, { 80, 34, 44 }, "CityGrey")
	vendingRow({ 250, -2 }, 3, 180)
	shopRow()
	jailAndClub()
	courtAndMansion()
	pocketPark()
	walls()
end

--[[
	Off the district: a ring of city blocks right behind the walls on every side (offices and apartment towers with
	glass bands, roof units and a few vertical neon signs facing in), so the city seems to go on; Persistent, so it
	never streams out. Grey ground under everything.
]]
local function scenery(_killY: number)
	local halfX, halfZ = DISTRICT[1] / 2, DISTRICT[2] / 2
	local colors = { "CityGrey", "CityTan", "CityBlue", "Cream", "ConcreteDark", "LightPurple" }
	local heights = { 46, 78, 58, 104, 66, 92, 52, 120, 70 }
	local count = 0
	local skyline = B.model("Skyline", function()
		local function block(at: { number }, size: { number }, faceIn: string)
			count += 1
			local height = heights[(count - 1) % #heights + 1]
			Pieces.block("Building", at, { size[1], height, size[2] }, colors[(count - 1) % #colors + 1], "Concrete")
			for y = 8, height - 6, 9 do
				glassBand(at, size, y, 2.6)
			end
			Pieces.block("RoofUnit", at, { size[1] * 0.4, 4, size[2] * 0.4 }, "Metal", "Metal", height)
			if count % 3 == 0 then
				local neon = if count % 2 == 0 then "NeonPink" else "NeonTeal"
				panel("NeonSign", at, size, faceIn, size[1] * 0.2, height * 0.55, 3, 14, neon, "Neon")
			end
		end
		for x = -308, 308, 44 do
			block({ x, halfZ + 24 }, { 42, 40 }, "-Z")
			block({ x, -halfZ - 24 }, { 42, 40 }, "+Z")
		end
		for z = -210, 210, 42 do
			block({ halfX + 24, z }, { 40, 40 }, "-X")
			block({ -halfX - 24, z }, { 40, 40 }, "+X")
		end
	end)
	skyline.ModelStreamingMode = B.Enum.ModelStreamingMode.Persistent
	B.part({
		Name = "FarGround",
		Size = { 4000, 1, 4000 },
		Position = { 0, -2.5, 0 },
		Color = "ConcreteDark",
		Material = "Concrete",
		CanCollide = false,
		CastShadow = false,
	})
end

-- Builds the arena model at `origin` (world position of the district floor's centre).
function Layout.build(origin: { number }): any
	return Arena.build(Layout :: any, origin, decorate, scenery)
end

return Layout
