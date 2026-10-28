--!strict
--[[
	Map 4: Shinjuku — the only arena in the vote since 2026-10-28. The owner asked for one new arena instead of the 3 old
	ones ("just store them somewhere, don't delete them"; Broken Highway, Junkyard Isles and Neon Motel stay built,
	switched off in Config.Maps.List), then "no floating island", then "want arena to look like jjk shenanigans" (the
	Shinjuku battleground of the Roblox game Jujutsu Shenanigans), then: "add breakable walls and trash can
	throwables, more detail, more look alike, town structures bigger and can enter". This is our own Shinjuku-style
	district in that spirit (generic shop names, nothing copied).

	A ground arena (Layout.Ground): one flat district (the Center platform, 480 × 400, never falls) walled in by
	invisible walls, with tall city blocks behind them all round. Nobody falls: a Classic life ends at 0 HP. Day light.
	Its buildings are ones you can walk into (maps/lib/Rooms: hollow storeys, floors, switchback ramps, roofs), and their
	walls and windows break (BreakableWall pieces, Services/WallService), as do the block walls and the gravestones.

	Plan (north = +Z): the station along the north edge (a long hall with ticket gates, two platforms, tracks and a
	three-car train you can walk through, a roof you can climb onto) and the station plaza; the main street across
	(z 80); below it, either side of the avenue (x 0), the twin towers (11 floors with stairs, a skybridge at the 9th,
	ladders up the outside to the roof); west of them the ramen shop and the plaza with the two-storey cafe, east the
	24-hour mart, the graveyard and the arcade; the second street across (z −80); south of it a row of five two-storey
	shops, the three-storey jail with its cell and the comedy club with a stage, the courthouse and a mansion with a
	garage, a pocket park with cherry trees. The mall (two floors, a ramp between them) and the bowling alley fill the
	west strip, apartments the east. Japanese streets: utility poles with wires, crosswalks, vending machines.
	Spots: 16 spawns (the station plaza and the streets), 24 loose prop spots (on roofs, upper floors, the skybridge,
	the station), trash cans and chairs where they belong (TypedProps), 8 breakables, 6 explosive barrels.
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

local DISTRICT = { 480, 400 } -- X, Z: the playable ground inside the walls
local WALL_HEIGHT = 260
local ROAD = 18
local BREAKABLE = { "BreakableWall" }
-- The twin towers (x ±33): 11 storeys of 4.6, the skybridge on the 9th.
local TOWER = { X = 33, Z = 30, Size = 34, Floors = 11, Storey = 7, BridgeFloor = 9 }
local TOWER_ROOF = TOWER.Floors * TOWER.Storey + 0.6
local BRIDGE_Y = (TOWER.BridgeFloor - 1) * TOWER.Storey
local STATION = { Front = 144, Back = 198, Roof = 18, HalfX = 181 }
local CAFE = { At = { -35, -48 }, Storey = 7 }

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
			{ -150, 115 },
			{ -75, 120 },
			{ 0, 112 },
			{ 75, 120 },
			{ 150, 115 },
			{ -210, 112 },
			{ 210, 112 },
			{ -75, -80 },
			{ 75, -80 },
			{ -200, -80 },
			{ 200, -80 },
			{ 0, -40 },
			{ 0, -150 },
			{ -95, -20 },
			{ -150, 0 },
			{ 150, 0 },
		},
		Props = {
			{ -TOWER.X, TOWER.Z, TOWER_ROOF }, -- the tower roofs
			{ TOWER.X, TOWER.Z, TOWER_ROOF },
			{ 0, TOWER.Z, BRIDGE_Y }, -- the skybridge
			{ -36, 20, BRIDGE_Y }, -- the west tower's 9th floor
			{ 36, 20, 4 * TOWER.Storey }, -- the east tower's 5th floor
			{ -100, 158.5, 1.2 }, -- the station's platforms
			{ 100, 184.5, 1.2 },
			{ -90, 170, STATION.Roof + 1.5 }, -- the station roof
			{ 90, 170, STATION.Roof + 1.5 },
			{ -110, 100 }, -- the station plaza
			{ 110, 100 },
			{ -25, -42, CAFE.Storey }, -- the cafe upstairs and on its roof
			{ -26, -58, 2 * CAFE.Storey + 0.6 },
			{ -215, 20 }, -- the mall
			{ 45, -35 }, -- the graveyard
			{ -80, -50 }, -- the plaza
			{ -75, -150 }, -- the lot behind the shops
			{ 78, -110 }, -- by the courthouse
			{ 110, -186 }, -- behind the mansion
			{ 200, -140 }, -- the pocket park
			{ 200, 0 }, -- the apartments' courtyard
			{ -200, -100 }, -- by the jail
		},
		TypedProps = {
			-- Trash cans where a street has them: the station plaza, the mart, the ramen shop, the shops, the park.
			{ At = { -42, 132 }, Type = "TrashCan" },
			{ At = { 42, 132 }, Type = "TrashCan" },
			{ At = { 95, 27 }, Type = "TrashCan" },
			{ At = { 125, 27 }, Type = "TrashCan" },
			{ At = { -86, 30 }, Type = "TrashCan" },
			{ At = { -111, -91.5 }, Type = "TrashCan" },
			-- Chairs where people sit: the cafe, the ramen shop, the comedy club, the court.
			{ At = { -29, -54 }, Type = "Chair" },
			{ At = { -31, -54, CAFE.Storey }, Type = "Chair" },
			{ At = { -115, 38 }, Type = "Chair" },
			{ At = { -105, 38 }, Type = "Chair" },
			{ At = { -205, -176 }, Type = "Chair" },
			{ At = { -195, -176 }, Type = "Chair" },
			{ At = { 40, -143 }, Type = "Chair" },
		},
		Explosives = {
			{ 165, 125 },
			{ -120, -80 },
			{ 0, 40 }, -- under the skybridge
			{ -175, -180 },
			{ 40, -180 },
			{ 180, -180 },
		},
		Structures = {
			{ Type = "VendingMachine", At = { -30, 136 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { 30, 136 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { 80, 27 }, Yaw = 0 },
			{ Type = "IceMachine", At = { 135, 27 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { -55, 8 }, Yaw = 0 },
			{ Type = "WreckedCar", At = { -25, -76 }, Yaw = 90 },
			{ Type = "WreckedCar", At = { -150, -40 }, Yaw = 0 },
			{ Type = "RoadBarrierStack", At = { 150, -130 }, Yaw = 0 },
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

---------------------------------------------------------------------------------------------------------------------
-- Streets
---------------------------------------------------------------------------------------------------------------------

local STREETS_Z = { 80, -80 } -- the streets across (along X)
local STREETS_X = { -150, 0, 150 } -- the streets along Z, from the south edge up to the main street
local GAPS_Z = { { -200, -89 }, { -71, 71 } } -- where those run (between the crossings)
local POLES_X = { -225, -190, -120, -85, -50, 50, 85, 120, 190, 225 }

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
				local across = -ROAD / 2 + 2 + stripe * 3.5
				paint("Crosswalk", { cx + ROAD / 2 + 2.5, cz + across }, { 4, 1.6 }, "LaneWhite", nil, 0.12)
				paint("Crosswalk", { cx + across, cz + inward * (ROAD / 2 + 2.5) }, { 1.6, 4 }, "LaneWhite", nil, 0.12)
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
	local segments = { { -240, -159 }, { -141, -9 }, { 9, 141 }, { 159, 240 } }
	for _, z in STREETS_Z do
		for _, edge in { -1, 1 } do
			local kz = z + edge * (ROAD / 2 + 0.25)
			if z > 0 and edge > 0 then
				kerb({ 0, kz }, { DISTRICT[1], 0.5 }) -- the station side has no crossings
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
	for _, z in { 68.5, -68.5 } do
		for index, x in POLES_X do
			utilityPole({ x, z }, index % 3 == 0)
			local nextX = POLES_X[index + 1]
			if nextX then
				wires({ x, z }, { nextX, z })
			end
		end
	end
	-- Taxis at the station, parked cars.
	car("Taxi", { -45, 75 }, 90, "LaneYellow")
	car("Taxi", { -56, 75 }, 90, "LaneYellow")
	car("ParkedCar", { 45, 84 }, -90, "OffWhite")
	car("ParkedCar", { 170, -76 }, -90, "CityBlue")
	car("ParkedCar", { -154, -150 }, 0, "Red")
end

---------------------------------------------------------------------------------------------------------------------
-- The station and its plaza (north)
---------------------------------------------------------------------------------------------------------------------

local function station()
	local front, back, roofY = STATION.Front, STATION.Back, STATION.Roof
	local middle = (front + back) / 2
	B.model("Station", function()
		Pieces.block("Roof", { 0, middle }, { STATION.HalfX * 2, 1.5, back - front }, "ConcreteDark", "Concrete", roofY)
		for x = -176, 176, 32 do
			for _, z in { front + 2, back - 2 } do
				Pieces.column("Column", { x, z }, 0, roofY, 1.8, "OffWhite", "Concrete")
			end
		end
		-- The back wall is the district's edge (it doesn't break); the side walls do, in pieces.
		Pieces.block("BackWall", { 0, back + 1 }, { STATION.HalfX * 2 + 4, 32, 2 }, "CityTan", "Concrete")
		for _, side in { -1, 1 } do
			for z = front + 4.5, back - 4.5, 9 do
				B.part({
					Name = "SideWall",
					Size = { 1, roofY, 9 },
					Position = { side * (STATION.HalfX + 0.5), roofY / 2, z },
					Color = "CityTan",
					Material = "Concrete",
					CastShadow = true,
					Tags = BREAKABLE,
				})
			end
		end
		B.part({
			Name = "Fascia",
			Size = { STATION.HalfX * 2, 1.4, 0.4 },
			Position = { 0, roofY + 0.75, front - 0.2 },
			Color = "TealDark",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.sign({
			Name = "StationSign",
			Size = { 80, 5, 0.6 },
			Position = { 0, roofY + 4, front + 0.5 },
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Station",
			TextColor = "OffWhite",
		})
		-- Two platforms (1.2 high) either side of two tracks.
		for _, z in { 158.5, 184.5 } do
			Pieces.block("Platform", { 0, z }, { 340, 1.2, 9 }, "Concrete", "Concrete")
			paint("TactileLine", { 0, z + (if z < 170 then 3.8 else -3.8) }, { 340, 0.6 }, "LaneYellow", nil, 1.22)
		end
		for _, z in { 167.5, 175.5 } do
			paint("Ballast", { 0, z }, { 360, 5.5 }, "AsphaltDark", "Pebble")
			for _, rail in { -0.75, 0.75 } do
				B.part({
					Name = "Rail",
					Size = { 360, 0.25, 0.3 },
					Position = { 0, 0.18, z + rail },
					Color = "Metal",
					Material = "Metal",
					CanCollide = false,
				})
			end
		end
		-- Ticket gates across the concourse, with gaps to walk through; a vending row on the first platform.
		for x = -40, 40, 4 do
			Pieces.block("TicketGate", { x, front + 5 }, { 1, 2.6, 2.6 }, "Metal", "Metal")
		end
		-- Ladders up onto the long roof at both front corners.
		for _, side in { -1, 1 } do
			ladder({ side * (STATION.HalfX - 3), front - 1 }, 0, 20)
		end
	end)
	-- The train on the far track: three cars you can walk through (doors both sides, seats, glass that breaks), an
	-- underframe level with the platforms and a ladder onto its roof at the east end.
	for index, x in { -48, 0, 48 } do
		local at = { x, 175.5 }
		Pieces.block("Underframe", at, { 44, 1.2, 5.6 }, "MetalDark", "Metal")
		B.within({ 0, 1.2, 0 }, function()
			Rooms.building({
				Name = `TrainCar{index}`,
				At = at,
				Size = { 44, 5.6 },
				Floors = 1,
				Storey = 6.4,
				Wall = 0.4,
				Color = "OffWhite",
				Material = "SmoothPlastic",
				FloorColor = "Metal",
				FloorMaterial = "DiamondPlate",
				Openings = {
					{ Face = "+Z", At = -11, Width = 3, Height = 4.8 },
					{ Face = "+Z", At = 11, Width = 3, Height = 4.8 },
					{ Face = "-Z", At = -11, Width = 3, Height = 4.8 },
					{ Face = "-Z", At = 11, Width = 3, Height = 4.8 },
				},
				Windows = { Faces = { "+Z", "-Z", "+X", "-X" }, Width = 4, Height = 2.2, Sill = 2.2, Spacing = 6 },
				Roof = { Color = "Metal", Material = "Metal" },
			})
			B.part({
				Name = "Stripe",
				Size = { 44.2, 0.6, 5.8 },
				Position = { x, 1.6, 175.5 },
				Color = "Bottle",
				CanCollide = false,
				CastShadow = false,
			})
			for _, z in { 173.4, 177.6 } do
				Pieces.block("Seat", { x, z }, { 14, 1.2, 1 }, "TealDark", "Fabric")
			end
		end)
	end
	ladder({ 72, 175.5 }, 0, 10)
end

local function stationPlaza()
	paint("Pavers", { 0, 115.5 }, { DISTRICT[1], 53 }, "ConcreteLight", "Pavement")
	for x = -232, 232, 16 do
		paint("PaverStripe", { x, 115.5 }, { 1, 53 }, "ConcreteDark", "Pavement", 0.12)
	end
	for _, at in { { -45, 108 }, { 45, 108 }, { -185, 130 }, { 185, 130 } } do
		planterTree(at)
	end
	bench({ -25, 100 }, 180)
	bench({ 25, 100 }, 180)
	vendingRow({ -122, 139.5 }, 5, 180)
	vendingRow({ 109, 139.5 }, 5, 180)
	B.model("Clock", function()
		upright("Post", { 0, 136 }, 0, 9, 0.5, "MetalDark", "Metal")
		B.part({
			Name = "Face",
			Size = { 0.4, 2.6, 2.6 },
			Position = { 0, 9.6, 136 },
			Rotation = { 0, 90, 0 },
			Shape = "Cylinder",
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The middle: the twin towers, the cafe and plaza, the ramen shop, the mart, the graveyard, the arcade
---------------------------------------------------------------------------------------------------------------------

--[[
	The twin towers either side of the avenue (the owner's reference: Jujutsu Shenanigans' 11-floor towers joined at
	the 9th floor): 34 × 34, eleven storeys you can walk up (switchback ramps to the roof's hatch), a glass lobby on
	the south, a door on each side; a ribbon of glass on every face of every upper storey; on the 9th, a door on the
	avenue side onto the glass skybridge; a ladder up the outside to the roof; a billboard on the south face.
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
				{ Face = "-Z", At = 0, Width = 8, Height = 5.5 },
				{ Face = "-Z", At = -10.5, Width = 11, Height = 5, Bottom = 0.4, Glass = true },
				{ Face = "-Z", At = 10.5, Width = 11, Height = 5, Bottom = 0.4, Glass = true },
				{ Face = "+Z", At = 0, Width = 8, Height = 5.5 },
				{ Face = inner, At = 0, Width = 8, Height = 5, Floor = TOWER.BridgeFloor },
			},
			Windows = {
				Faces = { "+X", "-X", "+Z", "-Z" },
				Width = 24,
				Height = 4.2,
				Sill = 0.8,
				Spacing = 28,
				From = 2,
			},
			Stair = { At = { side * 10, 8 }, Along = "Z", Width = 4 },
			Roof = { Color = "ConcreteDark", Hatch = true, Parapet = true },
		})
		B.part({
			Name = "EntranceCanopy",
			Size = { 12, 0.4, 4 },
			Position = { x, 4.4, z - half - 2 },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		ladder({ x + side * (half + 1), z + half - 3 }, 0, 80) -- past the roof's parapet (+78.8)
		B.sign({
			Name = "Billboard",
			Size = { 24, 10, 0.5 },
			Position = { x, 66, z - half - 0.5 },
			Color = if index == 1 then "Red" else "CityBlue",
			Material = "SmoothPlastic",
			Key = if index == 1 then "Map.Shinjuku.Sign.AdCola" else "Map.Shinjuku.Sign.AdNight",
			TextColor = "OffWhite",
			CanCollide = false,
		})
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
	local at, size = CAFE.At, { 36, 28 }
	Rooms.building({
		Name = "Cafe",
		At = at,
		Size = size,
		Floors = 2,
		Storey = CAFE.Storey,
		Color = "Cream",
		FloorColor = "Wood",
		FloorMaterial = "WoodPlanks",
		Openings = {
			{ Face = "+Z", At = 0, Width = 10, Height = 5 },
			{ Face = "+Z", At = -12, Width = 8, Height = 4, Bottom = 1, Glass = true },
			{ Face = "+Z", At = 12, Width = 8, Height = 4, Bottom = 1, Glass = true },
			{ Face = "+X", At = 0, Width = 6, Height = 5 },
		},
		Windows = { Faces = { "-X", "-Z", "+Z", "+X" }, Width = 6, Height = 3, Sill = 1.5, Spacing = 9, From = 2 },
		Stair = { At = { -11, 6 }, Along = "X", Width = 3.5 },
		Roof = { Color = "Red", Hatch = true, Parapet = true },
	})
	Pieces.block("Counter", { at[1] + 4, at[2] - 11 }, { 16, 3, 2 }, "WoodDark", "Wood")
	Pieces.block("CoffeeMachine", { at[1] + 8, at[2] - 11 }, { 2, 1.6, 1.2 }, "MetalDark", "Metal", 3)
	for _, spot in { { -25, -44 }, { -25, -54 } } do
		smallTable(spot)
	end
	smallTable({ -25, -54 }, CAFE.Storey)
	faceSign(at, size, "+Z", 0, 6, 10, 1.4, "Map.Shinjuku.Sign.Cafe", "WoodDark", "Cream")
	B.part({
		Name = "Awning",
		Size = { 14, 0.3, 3 },
		Position = { at[1], 5.4, at[2] + size[2] / 2 + 1.5 },
		Rotation = { 12, 0, 0 },
		Color = "Red",
		Material = "Fabric",
		CanCollide = false,
	})
end

-- The plaza west of the avenue: pavers, planters, benches.
local function plaza()
	paint("PlazaPavers", { -75, -29.5 }, { 132, 83 }, "ConcreteLight", "Pavement")
	for _, at in { { -130, -60 }, { -130, 4 }, { -70, 4 } } do
		planterTree(at)
	end
	bench({ -95, -62 }, 0)
	bench({ -70, -8 }, 180)
end

-- The ramen shop on the main street side, its front onto the plaza: a counter with stools, tables, curtains over
-- the door, red lanterns and a RAMEN sign.
local function ramen()
	local at, size = { -110, 45 }, { 40, 26 }
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
			{ Face = "-Z", At = -13, Width = 8, Height = 4, Bottom = 1.2, Glass = true },
			{ Face = "-Z", At = 13, Width = 8, Height = 4, Bottom = 1.2, Glass = true },
		},
		Windows = { Faces = { "+X", "-X" }, Width = 5, Height = 3, Sill = 2, Spacing = 8 },
		Roof = { Color = "AsphaltDark", Material = "Slate", Parapet = true },
	})
	Pieces.block("Counter", { at[1], at[2] + 8 }, { 24, 3.4, 2 }, "Wood", "Wood")
	for sx = -10, 10, 5 do
		upright("Stool", { at[1] + sx, at[2] + 5.5 }, 0, 2, 1.1, "Red", "SmoothPlastic")
	end
	for _, dx in { -10, 10 } do
		smallTable({ at[1] + dx, 38 })
	end
	faceSign(at, size, "-Z", 0, 7.6, 12, 1.8, "Map.Shinjuku.Sign.Ramen", "Black", "Cream")
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
	for _, dx in { -19, 19 } do
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
end

-- The 24-hour mart: a big glass front, shelves and a drinks cooler inside, a counter by the door, a striped sign
-- band; vending machines on its side.
local function mart()
	local at, size = { 110, 45 }, { 38, 24 }
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
			{ Face = "-Z", At = 0, Width = 8, Height = 6 },
			{ Face = "-Z", At = -11, Width = 12, Height = 5.6, Bottom = 0.4, Glass = true },
			{ Face = "-Z", At = 11, Width = 12, Height = 5.6, Bottom = 0.4, Glass = true },
		},
		Roof = { Color = "OffWhite", Parapet = true },
	})
	for _, dz in { 0, 5 } do
		Pieces.block("Shelf", { at[1], at[2] + dz }, { 16, 4, 1.6 }, "OffWhite", "Metal")
	end
	Pieces.block("Cooler", { at[1] + 17.4, at[2] + 2 }, { 1.6, 6, 14 }, "Glass", "Glass")
	Pieces.block("Counter", { at[1] - 14, at[2] - 5 }, { 2, 3.4, 6 }, "WoodDark", "Wood")
	panel("SignBand", at, size, "-Z", 0, 7.7, size[1], 2.2, "OffWhite")
	panel("Stripe", at, size, "-Z", 0, 6.3, size[1], 0.6, "Teal")
	faceSign(at, size, "-Z", 0, 7.7, 14, 1.6, "Map.Shinjuku.Sign.Mart", "OffWhite", "TealDark")
	vending({ at[1] + size[1] / 2 + 1.3, at[2] - 2 }, 90, "Red")
	vending({ at[1] + size[1] / 2 + 1.3, at[2] + 1.4 }, 90, "CityBlue")
end

-- The graveyard: a low stone wall with a gap on the north, rows of gravestones, three bare trees. The wall and the
-- stones break.
local function graveyard()
	local at, size = { 45, -45 }, { 44, 40 }
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
		for _, z in { -57, -49 } do
			for _, x in { 29, 37, 45, 53, 61 } do
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
		for _, spot in { { 28, -30 }, { 64, -61 }, { 62, -30 } } do
			deadTree(spot)
		end
	end)
end

-- The arcade by the second street: rows of game cabinets inside, a glass front, neon trim and a big ARCADE sign.
local function arcade()
	local at, size = { 110, -45 }, { 40, 32 }
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
			{ Face = "-Z", At = -13, Width = 10, Height = 6, Bottom = 0.5, Glass = true },
			{ Face = "-Z", At = 13, Width = 10, Height = 6, Bottom = 0.5, Glass = true },
			{ Face = "+Z", At = 0, Width = 6, Height = 6 },
		},
		Roof = { Color = "ArcadeBlue", Parapet = true },
	})
	for _, row in { { -52, 0 }, { -38, 180 } } do
		for x = 96, 124, 5.6 do
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
					Color = if x % 2 == 0 then "NeonTeal" else "NeonPink",
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
	faceSign(at, size, "-Z", 0, 9.4, 18, 3, "Map.Shinjuku.Sign.Arcade", "Black", "NeonPink", true)
end

---------------------------------------------------------------------------------------------------------------------
-- The west strip: the mall and the bowling alley; the east strip: apartments
---------------------------------------------------------------------------------------------------------------------

local function mall()
	local at, size = { -200, 25 }, { 70, 84 }
	Rooms.building({
		Name = "Mall",
		At = at,
		Size = size,
		Floors = 2,
		Storey = 8,
		Color = "CityTan",
		FloorColor = "ConcreteLight",
		Openings = {
			{ Face = "+X", At = 0, Width = 12, Height = 6 },
			{ Face = "+X", At = -20, Width = 16, Height = 5.5, Bottom = 0.5, Glass = true },
			{ Face = "+X", At = 20, Width = 16, Height = 5.5, Bottom = 0.5, Glass = true },
			{ Face = "+Z", At = 0, Width = 8, Height = 5 },
		},
		Windows = { Faces = { "+X", "+Z", "-Z" }, Width = 10, Height = 3, Sill = 2, Spacing = 14, From = 2 },
		Stair = { At = { 0, 0 }, Along = "Z", Width = 5 },
		Roof = { Color = "ConcreteDark", Parapet = true },
	})
	-- Shop stalls along the back wall on both floors.
	for _, y in { 0, 8 } do
		for index, z in { -5, 13, 31, 49 } do
			local colors = { "ShopRed", "ShopTeal", "ShopYellow", "ShopPink" }
			Pieces.block("Stall", { -228, z }, { 10, 4, 6 }, colors[index], "SmoothPlastic", y)
		end
	end
	for index, color in { "NeonPink", "ShopYellow", "NeonTeal", "ShopOrange" } do
		panel(`Graffiti{index}`, at, size, "+Z", -24 + (index - 1) * 16, 4 + (index % 2), 10, 4.5, color)
	end
	faceSign(at, size, "+X", 0, 7, 16, 1.8, "Map.Shinjuku.Sign.Mall", "CityBlue", "OffWhite")
	ladder({ at[1] + size[1] / 2 + 1, at[2] + 39 }, 0, 18)
end

local function bowling()
	local at, size = { -200, -45 }, { 70, 44 }
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
			{ Face = "+X", At = -13, Width = 8, Height = 5, Bottom = 0.5, Glass = true },
			{ Face = "+X", At = 13, Width = 8, Height = 5, Bottom = 0.5, Glass = true },
		},
		Roof = { Color = "ShopRed", Parapet = true },
	})
	-- Four lanes toward the back wall: light wood with dark gutters and three pins at the end of each.
	for _, z in { -58, -51, -44, -37 } do
		paint("Lane", { -207, z }, { 44, 4.4 }, "Cream", "WoodPlanks", 0.13)
		paint("Gutter", { -207, z + 2.6 }, { 44, 0.8 }, "Black", nil, 0.13)
		for _, dz in { -1, 0, 1 } do
			upright("Pin", { -228 + math.abs(dz) * 1.2, z + dz }, 0.15, 1.4, 0.4, "OffWhite", "SmoothPlastic", false)
		end
	end
	faceSign(at, size, "+X", 0, 7.6, 14, 2.4, "Map.Shinjuku.Sign.Bowling", "OffWhite", "Red")
	upright("GiantPin", { -180, -45 }, 10.6, 6, 2.6, "OffWhite", "SmoothPlastic", false) -- on the roof (+10.6)
	upright("PinStripe", { -180, -45 }, 14.6, 0.6, 2.7, "Red", "SmoothPlastic", false)
	B.part({
		Name = "PinHead",
		Size = { 2.2, 2.2, 2.2 },
		Position = { -180, 17.4, -45 },
		Shape = "Ball",
		Color = "OffWhite",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
end

-- An apartment block `size` (X, height, Z) — solid, not one to walk into: walls, a balcony strip and glass every
-- floor on its street face (−X), AC units on some balconies.
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
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The south: the shop row, the jail and the comedy club, the courthouse and the mansion, the pocket park
---------------------------------------------------------------------------------------------------------------------

local SHOP_Z = -104

local function shopRow()
	for index, entry in
		{
			{ -123, "ShopRed", "Map.Shinjuku.Sign.Books" },
			{ -99, "ShopYellow", "Map.Shinjuku.Sign.Electronics" },
			{ -75, "ShopTeal", "Map.Shinjuku.Sign.Karaoke" },
			{ -51, "ShopPink", "Map.Shinjuku.Sign.Subs" },
			{ -27, "ShopOrange", "Map.Shinjuku.Sign.Sweets" },
		}
	do
		local at, size = { entry[1], SHOP_Z }, { 24, 20 }
		Rooms.building({
			Name = `Shop{index}`,
			At = at,
			Size = size,
			Floors = 2,
			Storey = 7,
			Color = entry[2],
			FloorColor = "ConcreteLight",
			Openings = {
				{ Face = "+Z", At = 0, Width = 4, Height = 5.2 },
				{ Face = "+Z", At = -6.5, Width = 7, Height = 4.4, Bottom = 0.6, Glass = true },
				{ Face = "+Z", At = 6.5, Width = 7, Height = 4.4, Bottom = 0.6, Glass = true },
				{ Face = "-Z", At = 6, Width = 3, Height = 5.2 },
			},
			Windows = { Faces = { "+Z" }, Width = 6, Height = 2.6, Sill = 1.4, Spacing = 8, From = 2 },
			Stair = { At = { -4, -5 }, Along = "X", Width = 2.5 },
			Roof = { Color = "ConcreteDark", Parapet = true },
		})
		faceSign(at, size, "+Z", 0, 6.3, 14, 1.2, entry[3], "OffWhite", "Black")
		B.part({
			Name = "Awning",
			Size = { 20, 0.3, 2.4 },
			Position = { at[1], 5.5, at[2] + size[2] / 2 + 1.2 },
			Rotation = { 12, 0, 0 },
			Color = entry[2],
			Material = "Fabric",
			CanCollide = false,
		})
		B.part({
			Name = "VerticalSign",
			Size = { 1.4, 8, 0.4 },
			Position = { at[1] + 10.5, 9, at[2] + size[2] / 2 + 0.5 },
			Color = if entry[2] == "ShopYellow" then "Red" else "LaneYellow",
			Material = "Neon",
			CanCollide = false,
		})
		Pieces.block("Counter", { at[1] + 6, at[2] - 6 }, { 6, 3, 1.6 }, "WoodDark", "Wood")
		Pieces.block("Shelf", { at[1] + 9, at[2] + 2 }, { 1.2, 4, 6 }, "WoodMid", "Wood")
	end
	-- Behind the shops: a back lot with dumpsters, manholes and broken-up block walls.
	for _, at in { { -40, -118 }, { -100, -120 } } do
		Pieces.block("Dumpster", at, { 5, 3.4, 3 }, "Bottle", "Metal")
	end
	for _, at in { { -70, -160 }, { -30, -185 } } do
		upright("Manhole", at, 0.1, 0.04, 2.4, "MetalDark", "DiamondPlate", false)
	end
	for _, piece in { { -135, -115 }, { -105, -85 }, { -70, -50 }, { -40, -20 } } do
		blockWall({ piece[1], -132 }, { piece[2], -132 })
	end
end

local function jailAndClub()
	local jail, jailSize = { -200, -135 }, { 44, 30 }
	Rooms.building({
		Name = "Jail",
		At = jail,
		Size = jailSize,
		Floors = 3,
		Storey = 7,
		Color = "LightPurple",
		FloorColor = "ConcreteLight",
		Openings = {
			{ Face = "+Z", At = 0, Width = 6, Height = 5.2 },
			{ Face = "+X", At = -2, Width = 4, Height = 5.2 }, -- into the cell
		},
		Windows = { Faces = { "+Z", "-X", "-Z", "+X" }, Width = 3, Height = 2.4, Sill = 2.4, Spacing = 6 },
		Stair = { At = { -15, 0 }, Along = "Z", Width = 3 },
		Roof = { Color = "Purple", Parapet = true },
	})
	faceSign(jail, jailSize, "+Z", 0, 20, 8, 1.2, "Map.Shinjuku.Sign.Jail", "OffWhite", "Black")
	-- The barred cell on its east side (the bars don't break).
	local cell = { jail[1] + jailSize[1] / 2 + 4, jail[2] - 2 }
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
	local club, clubSize = { -200, -180 }, { 40, 24 }
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
	Pieces.block("Stage", { club[1], club[2] - 8 }, { 30, 1.5, 6 }, "WoodDark", "WoodPlanks")
	upright("MicStand", { club[1], club[2] - 8 }, 1.5, 4.4, 0.2, "MetalDark", "Metal", false)
	panel("Curtain", club, { clubSize[1] - 1.8, clubSize[2] - 1.8 }, "-Z", 0, 5, 30, 7, "Red", "Fabric") -- on the back wall
	faceSign(club, clubSize, "+Z", 0, 7, 14, 1.8, "Map.Shinjuku.Sign.Comedy", "Black", "LaneYellow", true)
	for index = 0, 6 do
		B.part({
			Name = "MarqueeLight",
			Size = { 0.5, 0.5, 0.5 },
			Position = { club[1] - 7.5 + index * 2.5, 8.4, club[2] + clubSize[2] / 2 + 0.4 },
			Shape = "Ball",
			Color = "WarmLight",
			Material = "Neon",
			CanCollide = false,
		})
	end
end

local function courtAndMansion()
	-- The courthouse: one tall hall (a judge's bench on a dais, rows of benches), a portico of six columns over three
	-- steps, a COURT sign.
	local court, courtSize = { 50, -140 }, { 44, 30 }
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
	Pieces.block("Dais", { court[1], court[2] - 10 }, { 20, 1, 6 }, "WoodDark", "Wood")
	Pieces.block("JudgeBench", { court[1], court[2] - 10.5 }, { 14, 3, 3 }, "WoodDark", "Wood", 1)
	for _, dz in { 2, 8 } do
		Pieces.block("Pew", { court[1] + 6, court[2] + dz }, { 16, 1.4, 1.2 }, "WoodMid", "Wood")
	end
	B.model("Portico", function()
		Pieces.block("Floor", { court[1], front + 2.5 }, { 46, 1.2, 5 }, "OffWhite", "Marble")
		Pieces.block("Roof", { court[1], front + 2.5 }, { 46, 1, 5.4 }, "OffWhite", "Marble", 11)
		for index = 0, 5 do
			Pieces.column(
				"Column",
				{ court[1] - 20 + index * 8, front + 3.5 },
				1.2,
				11,
				1.4,
				"OffWhite",
				"Marble",
				true
			)
		end
		Pieces.stairs("Steps", { court[1], front + 8 }, "-Z", 24, 3, 0.4, 1, "OffWhite", "Marble")
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
		At = { 118, -162 },
		Size = { 36, 26 },
		Floors = 2,
		Storey = 7,
		Color = "Cream",
		FloorColor = "WoodMid",
		FloorMaterial = "WoodPlanks",
		Openings = { { Face = "+Z", At = 0, Width = 4, Height = 5.2 } },
		Windows = { Faces = { "+X", "-X", "+Z", "-Z" }, Width = 3, Height = 3, Sill = 2, Spacing = 6 },
		Stair = { At = { -10, -4 }, Along = "X", Width = 3 },
		Roof = { Color = "AsphaltDark", Material = "Slate", Parapet = true },
	})
	Rooms.building({
		Name = "Garage",
		At = { 90, -165 },
		Size = { 16, 18 },
		Floors = 1,
		Storey = 6,
		Color = "Cream",
		Openings = { { Face = "+Z", At = 0, Width = 12, Height = 5.2 } },
		Roof = { Color = "AsphaltDark", Material = "Slate" },
	})
	for _, piece in { { 80, 112 }, { 124, 138 } } do
		local length = piece[2] - piece[1]
		for index = 1, 2 do
			B.part({
				Name = "Hedge",
				Size = { length / 2, 1.6, 1.4 },
				Position = { piece[1] + (index - 0.5) * length / 2, 0.8, -145 },
				Color = "Leaf",
				Material = "LeafyGrass",
				Tags = BREAKABLE,
			})
		end
	end
end

local function pocketPark()
	paint("Lawn", { 199.5, -144.5 }, { 81, 111 }, "Lawn", "Grass")
	paint("Path", { 199.5, -144.5 }, { 4, 111 }, "ConcreteLight", "Pavement", 0.06)
	for index, at in { { 175, -100 }, { 225, -100 }, { 175, -150 }, { 225, -165 }, { 200, -185 } } do
		tree(`CherryTree{index}`, at, "SakuraPink")
	end
	bench({ 190, -120 }, 90)
	bench({ 210, -160 }, -90)
	vendingRow({ 230, -125 }, 2, -90)
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
	station()
	stationPlaza()
	twinTowers()
	plaza()
	cafe()
	ramen()
	mart()
	graveyard()
	arcade()
	mall()
	bowling()
	apartments("ApartmentsNorth", { 200, 40 }, { 70, 26, 40 }, "Cream")
	apartments("ApartmentsSouth", { 200, -40 }, { 70, 32, 40 }, "CityGrey")
	vendingRow({ 220, -2 }, 3, 180)
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
				panel(
					"NeonSign",
					at,
					size,
					faceIn,
					size[1] * 0.2,
					height * 0.55,
					3,
					14,
					if count % 2 == 0 then "NeonPink" else "NeonTeal",
					"Neon"
				)
			end
		end
		for x = -264, 264, 44 do
			block({ x, halfZ + 24 }, { 42, 40 }, "-Z")
			block({ x, -halfZ - 24 }, { 42, 40 }, "+Z")
		end
		for z = -180, 180, 45 do
			block({ halfX + 24, z }, { 40, 44 }, "-X")
			block({ -halfX - 24, z }, { 40, 44 }, "+X")
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
