--!strict
--[[
	Map 4: Shinjuku — the only arena in the vote since 2026-10-28. The owner asked for one new arena instead of the 3 old
	ones ("just store them somewhere, don't delete them"; Broken Highway, Junkyard Isles and Neon Motel stay built,
	switched off in Config.Maps.List), first "like the default small city in Roblox", then "no floating island … with
	mountains around", then: "want arena to look like jjk shenanigans, not like this" — the Shinjuku battleground of
	the Roblox game Jujutsu Shenanigans. This is our own Shinjuku-style district in that spirit (generic shop names,
	nothing copied): a dense Tokyo street block around a station, twin towers joined by a skybridge, a plaza with a
	cafe, small shops, a graveyard, a jail, a mall with a bowling alley.

	A ground arena (Layout.Ground): one flat district (the Center platform, 400 × 336, never falls) walled in by
	invisible walls, with tall city blocks rising behind them all round, so the city seems to go on. Nobody falls: a
	Classic life ends when its HP runs out. Day lighting.

	Plan (north = +Z): the station along the north edge (platforms, tracks and a parked train under a long roof you
	can climb onto) with the station plaza in front of it; the main street across (z 64); below it, either side of the
	avenue (x 0), the twin towers (11 floors, a skybridge at the 9th, ladders up the outside), the ramen shop and the
	plaza with the two-storey cafe on the west, the 24-hour mart, the graveyard and the arcade on the east; the second
	street across (z −70); south of it a row of small shops (books, electronics, karaoke, subs, sweets), the jail and
	the comedy club, the courthouse and a mansion, a pocket park with cherry trees. The mall and bowling alley fill the
	north-west, apartments the east. Japanese streets: utility poles with wires, crosswalks, vending machines.
	Spots: 16 spawns (the station plaza and the streets), 24 loose prop spots (some on the roofs, the skybridge, the
	station roof and platforms, the cafe's deck), 8 breakable structures, 6 explosive barrels.
]]
local Arena = require("../lib/Arena")
local B = require("../lib/Builder")
local Pieces = require("../lib/Pieces")

type Platform = Arena.Platform

local Layout = {}

Layout.Id = "Shinjuku"
Layout.Lighting = "Day"
Layout.Ground = true -- one walled-in ground platform instead of floating ones (the maps spec checks it differently)

local DISTRICT = { 400, 336 } -- X, Z: the playable ground inside the walls
local WALL_HEIGHT = 260
local ROAD = 16
local TOWER = { X = 26, Z = 20, Size = 28, Lower = 40, Upper = 18, Top = 48.4 } -- the twin towers (x ±26)
local CAFE_DECK = 7 -- the cafe's first floor

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
			{ -120, 95 },
			{ -60, 100 },
			{ 0, 95 },
			{ 60, 100 },
			{ 120, 95 },
			{ -170, 95 },
			{ 170, 95 },
			{ -60, -70 },
			{ 60, -70 },
			{ -160, -70 },
			{ 160, -70 },
			{ 0, -30 },
			{ 0, -120 },
			{ -80, -20 },
			{ -120, 0 },
			{ 120, 0 },
		},
		Props = {
			{ -TOWER.X, TOWER.Z, TOWER.Top }, -- the tower roofs
			{ TOWER.X, TOWER.Z, TOWER.Top },
			{ 0, TOWER.Z, TOWER.Lower }, -- the skybridge
			{ -TOWER.X, 8.5, TOWER.Lower }, -- the west tower's terrace
			{ -80, 140, 15.5 }, -- the station roof
			{ 80, 140, 15.5 },
			{ -100, 130, 1.2 }, -- the station platforms
			{ 100, 154, 1.2 },
			{ -90, 85 }, -- the station plaza
			{ 90, 85 },
			{ -34, -40 }, -- the cafe, downstairs and on its deck
			{ -26, -44, CAFE_DECK },
			{ -84, 32 }, -- the ramen shop
			{ 78, 29 }, -- the mart
			{ 38, -32 }, -- the graveyard
			{ -70, -45 }, -- the plaza
			{ -95, -10 },
			{ -60, -130 }, -- the lot behind the shops
			{ -90, -150 },
			{ 60, -90 }, -- in front of the courthouse
			{ 70, -150 }, -- the mansion's garden
			{ 164, -120 }, -- the pocket park
			{ 166, 0 }, -- the apartments' courtyard
			{ -150, -85 }, -- by the jail
		},
		Explosives = {
			{ 150, 88 },
			{ -100, -70 },
			{ 0, 30 }, -- under the skybridge
			{ -140, -150 },
			{ 40, -150 },
			{ 150, -150 },
		},
		Structures = {
			{ Type = "VendingMachine", At = { -30, 112 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { 30, 112 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { 64, 21 }, Yaw = 0 },
			{ Type = "IceMachine", At = { 96, 21 }, Yaw = 0 },
			{ Type = "VendingMachine", At = { -44, 2 }, Yaw = 0 },
			{ Type = "WreckedCar", At = { -20, -66 }, Yaw = 90 },
			{ Type = "WreckedCar", At = { -120, -40 }, Yaw = 0 },
			{ Type = "RoadBarrierStack", At = { 120, -110 }, Yaw = 0 },
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

-- A flat panel on the face of a box: `face` "+X" / "-X" / "+Z" / "-Z" of the box at `at` sized `size` (X, Z),
-- `along` across the face, `y` its middle, `w` × `h`; walk-through.
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
	local out = sign * (size[axis] / 2 + 0.06)
	local glass = material == "Glass"
	return B.part({
		Name = name,
		Size = if axis == 1 then { 0.1, h, w } else { w, h, 0.1 },
		Position = if axis == 1 then { at[1] + out, y, at[2] + along } else { at[1] + along, y, at[2] + out },
		Color = color,
		Material = material or "SmoothPlastic",
		Transparency = if glass then 0.2 else nil,
		CanCollide = false,
		CastShadow = false,
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

-- A bench turned `yaw` (unturned, you sit facing +Z): a wood seat and back on iron legs.
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

-- An air-conditioner box on a wall or roof, standing on `y`.
local function acUnit(at: { number }, y: number)
	Pieces.block("ACUnit", at, { 2.4, 1.6, 1.4 }, "OffWhite", "Metal", y)
end

--[[
	A shop front: a box `size` (X, height, Z) with its front on `face` ("+Z" / "-Z"): a glass shopfront, a striped
	awning, a sign board with the text `key`, a tall vertical sign on one corner and, on taller ones, a band of upstairs
	windows; an AC unit on the roof.
]]
local function shop(name: string, at: { number }, size: { number }, color: string, face: string, key: string)
	local sign = if face == "+Z" then 1 else -1
	local footprint = { size[1], size[3] }
	B.model(name, function()
		Pieces.block("Walls", at, size, color, "Concrete")
		panel("Shopfront", at, footprint, face, 0, 2.8, size[1] - 4, 4, "Glass", "Glass")
		B.part({
			Name = "Awning",
			Size = { size[1] - 2, 0.3, 3 },
			Position = { at[1], 5.6, at[2] + sign * (size[3] / 2 + 1.4) },
			Rotation = { sign * 12, 0, 0 },
			Color = color,
			Material = "Fabric",
			CanCollide = false,
		})
		B.sign({
			Name = "Sign",
			Size = { size[1] - 3, 2.2, 0.3 },
			Position = { at[1], 7.6, at[2] + sign * (size[3] / 2 + 0.25) },
			Rotation = if face == "+Z" then B.yaw("North") else nil,
			Color = "OffWhite",
			Material = "SmoothPlastic",
			Key = key,
			TextColor = "Black",
			CanCollide = false,
		})
		B.part({
			Name = "VerticalSign",
			Size = { 1.6, math.min(size[2] - 3, 9), 0.5 },
			Position = {
				at[1] + size[1] / 2 - 1,
				size[2] - math.min(size[2] - 3, 9) / 2 - 1,
				at[2] + sign * (size[3] / 2 + 0.6),
			},
			Color = if color == "ShopYellow" then "Red" else "LaneYellow",
			Material = "Neon",
			CanCollide = false,
		})
		if size[2] >= 12 then
			panel("Upstairs", at, footprint, face, 0, 10.4, size[1] - 3, 2, "Glass", "Glass")
		end
		acUnit({ at[1] - size[1] / 4, at[2] }, size[2])
	end)
end

-- A concrete utility pole (solid) with a crossbar, insulators and, when `transformer`, a grey transformer can.
local function utilityPole(at: { number }, acrossX: boolean, transformer: boolean)
	B.model("UtilityPole", function()
		upright("Pole", at, 0, 12, 0.8, "ConcreteLight", "Concrete")
		B.part({
			Name = "Crossbar",
			Size = if acrossX then { 3.6, 0.25, 0.25 } else { 0.25, 0.25, 3.6 },
			Position = { at[1], 11.4, at[2] },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		if transformer then
			upright(
				"Transformer",
				{ at[1] + (if acrossX then 0 else 0.9), at[2] + (if acrossX then 0.9 else 0) },
				8,
				1.8,
				1.2,
				"Metal",
				"Metal",
				false
			)
		end
	end)
end

-- Two power lines from pole top `a` to pole top `b` (x, z), walk-through.
local function wires(a: { number }, b: { number })
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local length = math.sqrt(dx * dx + dz * dz)
	for _, wire in { { 11.55, 1.4 }, { 11.55, -1.4 }, { 10.6, 0 } } do
		local offset = wire[2]
		local ox, oz = -dz / length * offset, dx / length * offset
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

local STREETS_Z = { 64, -70 } -- the streets across (along X)
local STREETS_X = { -120, 0, 120 } -- the streets along Z, from the south edge up to the main street
local GAPS_Z = { { -168, -78 }, { -62, 56 } } -- where those run (between the crossings)

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
				local across = -ROAD / 2 + 1.8 + stripe * 3.1
				paint("Crosswalk", { cx + ROAD / 2 + 2.5, cz + across }, { 4, 1.5 }, "LaneWhite", nil, 0.12)
				paint("Crosswalk", { cx + across, cz + inward * (ROAD / 2 + 2.5) }, { 1.5, 4 }, "LaneWhite", nil, 0.12)
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
	local segments = { { -200, -128 }, { -112, -8 }, { 8, 112 }, { 128, 200 } }
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
	for _, line in
		{
			{ z = 53.5, xs = { -184, -152, -88, -56, 40, 72, 152, 184 } },
			{ z = -59.5, xs = { -184, -152, -96, -64, 32, 64, 96, 152, 184 } },
		}
	do
		for index, x in line.xs do
			utilityPole({ x, line.z }, false, index % 3 == 0)
			local nextX = line.xs[index + 1]
			if nextX then
				wires({ x, line.z }, { nextX, line.z })
			end
		end
	end
	-- Parked cars and a taxi rank by the station.
	car("Taxi", { -40, 60 }, 90, "LaneYellow")
	car("Taxi", { -50, 60 }, 90, "LaneYellow")
	car("ParkedCar", { 40, 68 }, -90, "OffWhite")
	car("ParkedCar", { 140, -74 }, -90, "CityBlue")
	car("ParkedCar", { -124, -120 }, 0, "Red")
end

---------------------------------------------------------------------------------------------------------------------
-- The station and its plaza (north)
---------------------------------------------------------------------------------------------------------------------

local function station()
	local front, back = 118, 166
	local middle = (front + back) / 2
	B.model("Station", function()
		Pieces.block("Roof", { 0, middle }, { 300, 1.5, back - front }, "ConcreteDark", "Concrete", 14)
		for x = -140, 140, 28 do
			for _, z in { front + 2, back - 2 } do
				Pieces.column("Column", { x, z }, 0, 14, 1.6, "OffWhite", "Concrete")
			end
		end
		Pieces.block("BackWall", { 0, back + 1 }, { 304, 30, 2 }, "CityTan", "Concrete")
		for _, side in { -1, 1 } do
			Pieces.block("SideWall", { side * 151, middle }, { 2, 14, back - front }, "CityTan", "Concrete")
		end
		B.part({
			Name = "Fascia",
			Size = { 300, 1.4, 0.4 },
			Position = { 0, 14.75, front - 0.2 },
			Color = "TealDark",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.sign({
			Name = "StationSign",
			Size = { 70, 5, 0.6 },
			Position = { 0, 18.2, front + 0.5 },
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Station",
			TextColor = "OffWhite",
		})
		-- Platforms (1.2 high) either side of two tracks, a parked train on the far track.
		for _, z in { 130, 154 } do
			Pieces.block("Platform", { 0, z }, { 280, 1.2, 8 }, "Concrete", "Concrete")
			paint("TactileLine", { 0, z + (if z < 142 then 3.4 else -3.4) }, { 280, 0.6 }, "LaneYellow", nil, 1.22)
		end
		for _, z in { 138.5, 145.5 } do
			paint("Ballast", { 0, z }, { 300, 5.5 }, "AsphaltDark", "Pebble")
			for _, rail in { -0.75, 0.75 } do
				B.part({
					Name = "Rail",
					Size = { 300, 0.25, 0.3 },
					Position = { 0, 0.18, z + rail },
					Color = "Metal",
					Material = "Metal",
					CanCollide = false,
				})
			end
		end
		for index, x in { -42, 0, 42 } do
			B.model(`TrainCar{index}`, function()
				Pieces.block("Body", { x, 145.5 }, { 40, 6.5, 5.6 }, "OffWhite", "SmoothPlastic", 0.6)
				glassBand({ x, 145.5 }, { 40, 5.6 }, 4.4, 1.8)
				B.part({
					Name = "Stripe",
					Size = { 40.2, 0.6, 5.8 },
					Position = { x, 2.4, 145.5 },
					Color = "Bottle",
					Material = "SmoothPlastic",
					CanCollide = false,
				})
				Pieces.block("RoofCap", { x, 145.5 }, { 39, 0.4, 4.8 }, "Metal", "Metal", 7.1)
			end)
		end
		ladder({ 64, 145.5 }, 0, 8) -- up onto the train's roof
		-- Ticket gates across the front, with gaps to walk through.
		for x = -36, 36, 4 do
			Pieces.block("TicketGate", { x, front + 4 }, { 1, 2.6, 2.6 }, "Metal", "Metal")
		end
		-- Ladders up onto the long roof at both front corners.
		for _, side in { -1, 1 } do
			ladder({ side * 147, front - 1 }, 0, 16)
		end
	end)
end

local function stationPlaza()
	paint("Pavers", { 0, 95 }, { DISTRICT[1], 46 }, "ConcreteLight", "Pavement")
	for x = -192, 192, 16 do
		paint("PaverStripe", { x, 95 }, { 1, 46 }, "ConcreteDark", "Pavement", 0.12)
	end
	for _, at in { { -35, 88 }, { 35, 88 }, { -145, 108 }, { 145, 108 } } do
		planterTree(at)
	end
	bench({ -20, 80 }, 180)
	bench({ 20, 80 }, 180)
	vendingRow({ -100, 114 }, 5, 180)
	vendingRow({ 87, 114 }, 5, 180)
	-- The station clock on a post.
	B.model("Clock", function()
		upright("Post", { 0, 112 }, 0, 9, 0.5, "MetalDark", "Metal")
		B.part({
			Name = "Face",
			Size = { 0.4, 2.6, 2.6 },
			Position = { 0, 9.6, 112 },
			Rotation = { 0, 90, 0 },
			Shape = "Cylinder",
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The middle: twin towers, the cafe and plaza, the ramen shop, the mart, the graveyard, the arcade
---------------------------------------------------------------------------------------------------------------------

--[[
	The twin towers either side of the avenue (owner's reference: Jujutsu Shenanigans' 11-floor towers joined at the 9th
	floor): each a 28-wide block to the 9th floor's roof (+40) with an 18-wide top for floors 10–11 (+48.4), so a terrace
	runs round each top; a skybridge over the avenue joins the terraces; ladders run up the outside of each tower to
	its terrace and on to its roof; a billboard on each one's south face.
]]
local function twinTowers()
	for index, side in { -1, 1 } do
		local at = { side * TOWER.X, TOWER.Z }
		local base = { TOWER.Size, TOWER.Size }
		B.model(if side < 0 then "TowerWest" else "TowerEast", function()
			Pieces.block(
				"Lower",
				at,
				{ TOWER.Size, TOWER.Lower, TOWER.Size },
				if side < 0 then "CityGrey" else "CityBlue",
				"Concrete"
			)
			Pieces.block(
				"Upper",
				at,
				{ TOWER.Upper, TOWER.Top - TOWER.Lower, TOWER.Upper },
				"ConcreteLight",
				"Concrete",
				TOWER.Lower
			)
			for floor = 1, 8 do
				glassBand(at, base, 2.2 + floor * 4.4)
			end
			for _, y in { 42.2, 46.4 } do
				glassBand(at, { TOWER.Upper, TOWER.Upper }, y, 2)
			end
			panel("Lobby", at, base, "-Z", 0, 2.8, 20, 4.4, "Glass", "Glass")
			B.part({
				Name = "EntranceCanopy",
				Size = { 12, 0.5, 4 },
				Position = { at[1], 6.5, at[2] - TOWER.Size / 2 - 2 },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			-- The terrace's parapet, open where the skybridge meets it.
			local half = TOWER.Size / 2
			local inner = at[1] - side * half -- the side facing the avenue
			for _, edge in
				{
					{ { at[1], at[2] - half + 0.25 }, { TOWER.Size, 0.5 } },
					{ { at[1], at[2] + half - 0.25 }, { TOWER.Size, 0.5 } },
					{ { at[1] + side * (half - 0.25), at[2] }, { 0.5, TOWER.Size } },
					{ { inner + side * 0.25, at[2] - 9.5 }, { 0.5, 9 } }, -- the gap between them: the skybridge (10 wide)
					{ { inner + side * 0.25, at[2] + 9.5 }, { 0.5, 9 } },
				}
			do
				Pieces.block("Parapet", edge[1], { edge[2][1], 1, edge[2][2] }, "ConcreteDark", "Concrete", TOWER.Lower)
			end
			for _, edge in { { 0, -8.75 }, { 0, 8.75 } } do
				Pieces.block(
					"RoofParapet",
					{ at[1], at[2] + edge[2] },
					{ TOWER.Upper, 0.6, 0.5 },
					"ConcreteDark",
					"Concrete",
					TOWER.Top
				)
			end
			ladder({ at[1] + side * (half + 1), at[2] }, 0, TOWER.Lower)
			ladder({ at[1] + side * (TOWER.Upper / 2 + 1), at[2] }, TOWER.Lower, 8)
			B.sign({
				Name = "Billboard",
				Size = { 20, 9, 0.5 },
				Position = { at[1], 33, at[2] - half - 0.4 },
				Color = if index == 1 then "Red" else "CityBlue",
				Material = "SmoothPlastic",
				Key = if index == 1 then "Map.Shinjuku.Sign.AdCola" else "Map.Shinjuku.Sign.AdNight",
				TextColor = "OffWhite",
				CanCollide = false,
			})
		end)
	end
	-- The skybridge: a steel deck with glass sides and a glass roof.
	local gap = TOWER.X * 2 - TOWER.Size
	B.model("Skybridge", function()
		Pieces.block("Deck", { 0, TOWER.Z }, { gap, 1, 10 }, "MetalDark", "DiamondPlate", TOWER.Lower - 1)
		for _, z in { TOWER.Z - 4.85, TOWER.Z + 4.85 } do
			Pieces.block("Railing", { 0, z }, { gap, 1.2, 0.3 }, "Glass", "Glass", TOWER.Lower)
		end
		B.part({
			Name = "GlassRoof",
			Size = { gap, 0.3, 10.4 },
			Position = { 0, TOWER.Lower + 4, TOWER.Z },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.5,
			CanCollide = false,
		})
	end)
end

-- The cafe at the plaza's corner: open downstairs (a counter and tables behind two walls), a deck upstairs (+7) up an
-- outside stair, a red roof on posts, a CAFE sign.
local function cafe()
	local at, size = { -32, -40 }, { 28, 22 }
	local x0, x1, z0, z1 = at[1] - size[1] / 2, at[1] + size[1] / 2, at[2] - size[2] / 2, at[2] + size[2] / 2
	B.model("Cafe", function()
		Pieces.block("SouthWall", { at[1], z0 + 0.3 }, { size[1], CAFE_DECK - 0.6, 0.6 }, "OffWhite", "Concrete")
		Pieces.block("WestWall", { x0 + 0.3, at[2] }, { 0.6, CAFE_DECK - 0.6, size[2] }, "OffWhite", "Concrete")
		for _, corner in { { x1 - 0.5, z1 - 0.5 }, { x1 - 0.5, z0 + 0.5 }, { x0 + 0.5, z1 - 0.5 } } do
			Pieces.column("Post", corner, 0, CAFE_DECK - 0.6, 0.8, "WoodDark", "Wood")
		end
		Pieces.block("Deck", at, { size[1], 0.6, size[2] }, "Wood", "WoodPlanks", CAFE_DECK - 0.6)
		Pieces.block("Counter", { at[1], z0 + 2 }, { 18, 3, 2 }, "WoodDark", "Wood")
		Pieces.block("CoffeeMachine", { at[1] + 4, z0 + 2 }, { 2, 1.6, 1.2 }, "MetalDark", "Metal", 3)
		for _, spot in { { -40, -33 }, { -24, -33 }, { -24, -45 } } do
			smallTable(spot)
		end
		-- Upstairs: tables, a railing on the open sides (a gap where the stair arrives), the roof on four posts.
		for _, spot in { { -38, -34 }, { -40, -46 } } do
			smallTable(spot, CAFE_DECK)
		end
		Pieces.block("RailingNorth", { at[1], z1 - 0.15 }, { size[1], 1.2, 0.3 }, "WoodDark", "Wood", CAFE_DECK)
		Pieces.block("RailingEast", { x1 - 0.15, at[2] }, { 0.3, 1.2, size[2] }, "WoodDark", "Wood", CAFE_DECK)
		Pieces.block("RailingWest", { x0 + 0.15, z0 + 5 }, { 0.3, 1.2, 10 }, "WoodDark", "Wood", CAFE_DECK)
		for _, corner in
			{ { x0 + 0.5, z0 + 0.5 }, { x1 - 0.5, z0 + 0.5 }, { x0 + 0.5, z1 - 0.5 }, { x1 - 0.5, z1 - 0.5 } }
		do
			Pieces.column("RoofPost", corner, CAFE_DECK, 13, 0.6, "WoodDark", "Wood")
		end
		Pieces.block("Roof", at, { size[1] + 1, 0.6, size[2] + 1 }, "Red", "SmoothPlastic", 13)
		Pieces.stairs("CafeStairs", { x0 - 1.5, z0 }, "+Z", 3, 7, 1, 2.2, "WoodDark", "Wood")
		B.sign({
			Name = "CafeSign",
			Size = { 10, 2, 0.3 },
			Position = { at[1], 14.8, z1 + 0.2 },
			Rotation = B.yaw("North"),
			Color = "WoodDark",
			Material = "Wood",
			Key = "Map.Shinjuku.Sign.Cafe",
			TextColor = "Cream",
		})
	end)
end

-- The plaza west of the avenue: pavers, planters, benches.
local function plaza()
	paint("PlazaPavers", { -60, -28 }, { 104, 68 }, "ConcreteLight", "Pavement")
	for _, at in { { -100, -50 }, { -100, -2 }, { -56, -2 } } do
		planterTree(at)
	end
	bench({ -80, -55 }, 0)
	bench({ -60, -5 }, 180)
end

-- The ramen shop on the main street side, its front open to the south: three walls and a roof, a counter with
-- stools, tables, curtains over the opening, red lanterns, a RAMEN sign.
local function ramen()
	local at, size = { -84, 34 }, { 32, 20 }
	local x0, x1, z0, z1 = at[1] - size[1] / 2, at[1] + size[1] / 2, at[2] - size[2] / 2, at[2] + size[2] / 2
	B.model("Ramen", function()
		Pieces.block("BackWall", { at[1], z1 - 0.3 }, { size[1], 9, 0.6 }, "Brick", "Brick")
		for _, x in { x0 + 0.3, x1 - 0.3 } do
			Pieces.block("SideWall", { x, at[2] }, { 0.6, 9, size[2] }, "Brick", "Brick")
		end
		Pieces.block("Roof", at, { size[1] + 1, 0.6, size[2] + 1 }, "AsphaltDark", "Slate", 9)
		Pieces.block("Counter", { at[1], z1 - 4 }, { 20, 3.4, 2 }, "Wood", "Wood")
		for x = at[1] - 8, at[1] + 8, 4 do
			upright("Stool", { x, z1 - 6.5 }, 0, 2, 1.1, "Red", "SmoothPlastic")
		end
		for _, x in { x0 + 6, x1 - 6 } do
			smallTable({ x, z0 + 6 })
		end
		B.part({
			Name = "Fascia",
			Size = { size[1], 2, 0.4 },
			Position = { at[1], 8, z0 + 0.2 },
			Color = "Black",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.sign({
			Name = "RamenSign",
			Size = { 12, 1.8, 0.3 },
			Position = { at[1], 8, z0 - 0.1 },
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Ramen",
			TextColor = "Cream",
			CanCollide = false,
		})
		for index = 0, 3 do
			B.part({
				Name = "Curtain",
				Size = { 3, 2.4, 0.1 },
				Position = { at[1] - 6 + index * 4, 5.8, z0 - 0.15 },
				Color = "TealDark",
				Material = "Fabric",
				CanCollide = false,
			})
		end
		for _, x in { x0 + 1.5, x1 - 1.5 } do
			B.part({
				Name = "Lantern",
				Size = { 1.4, 1.8, 1.4 },
				Position = { x, 6.4, z0 - 0.9 },
				Shape = "Ball",
				Color = "Red",
				Material = "Neon",
				CanCollide = false,
			})
		end
	end)
end

-- The 24-hour mart: three walls, glass on both sides of the doors, shelves and a drinks cooler inside, a striped sign
-- band; vending machines on its side.
local function mart()
	local at, size = { 84, 34 }, { 30, 18 }
	local x0, x1, z0, z1 = at[1] - size[1] / 2, at[1] + size[1] / 2, at[2] - size[2] / 2, at[2] + size[2] / 2
	B.model("Mart", function()
		Pieces.block("BackWall", { at[1], z1 - 0.3 }, { size[1], 9, 0.6 }, "OffWhite", "Concrete")
		for _, x in { x0 + 0.3, x1 - 0.3 } do
			Pieces.block("SideWall", { x, at[2] }, { 0.6, 9, size[2] }, "OffWhite", "Concrete")
		end
		for _, x in { x0 + 5, x1 - 5 } do
			Pieces.block("Window", { x, z0 + 0.1 }, { 10, 6, 0.2 }, "Glass", "Glass")
		end
		Pieces.block("Roof", at, { size[1] + 1, 0.6, size[2] + 1 }, "OffWhite", "SmoothPlastic", 9)
		B.part({
			Name = "SignBand",
			Size = { size[1], 2.2, 0.4 },
			Position = { at[1], 7.9, z0 - 0.1 },
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.part({
			Name = "Stripe",
			Size = { size[1], 0.6, 0.42 },
			Position = { at[1], 6.5, z0 - 0.1 },
			Color = "Teal",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.sign({
			Name = "MartSign",
			Size = { 14, 1.6, 0.3 },
			Position = { at[1], 7.9, z0 - 0.45 },
			Color = "OffWhite",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Mart",
			TextColor = "TealDark",
			CanCollide = false,
		})
		for _, z in { z0 + 8, z0 + 13 } do
			Pieces.block("Shelf", { at[1], z }, { 14, 4, 1.6 }, "OffWhite", "Metal")
		end
		Pieces.block("Cooler", { x1 - 1.4, at[2] + 2 }, { 1.6, 6, 12 }, "Glass", "Glass")
		Pieces.block("Counter", { x0 + 3, z0 + 5 }, { 2, 3.4, 6 }, "WoodDark", "Wood")
	end)
	vending({ x1 + 1.3, at[2] - 2 }, 90, "Red")
	vending({ x1 + 1.3, at[2] + 1.4 }, 90, "CityBlue")
end

-- The graveyard: a low stone wall with a gap on the north, rows of gravestones, three bare trees.
local function graveyard()
	local at, size = { 38, -40 }, { 40, 32 }
	local x0, x1, z0, z1 = at[1] - size[1] / 2, at[1] + size[1] / 2, at[2] - size[2] / 2, at[2] + size[2] / 2
	B.model("Graveyard", function()
		paint("Ground", at, size, "GraveGrass", "Grass")
		Pieces.block("WallSouth", { at[1], z0 + 0.4 }, { size[1], 1.2, 0.8 }, "Stone", "Cobblestone")
		Pieces.block("WallWest", { x0 + 0.4, at[2] }, { 0.8, 1.2, size[2] }, "Stone", "Cobblestone")
		Pieces.block("WallEast", { x1 - 0.4, at[2] }, { 0.8, 1.2, size[2] }, "Stone", "Cobblestone")
		for _, piece in { { x0, at[1] - 4 }, { at[1] + 4, x1 } } do
			Pieces.block(
				"WallNorth",
				{ (piece[1] + piece[2]) / 2, z1 - 0.4 },
				{ piece[2] - piece[1], 1.2, 0.8 },
				"Stone",
				"Cobblestone"
			)
		end
		for _, z in { -50, -44 } do
			for _, x in { 24, 30, 36, 44, 50 } do
				Pieces.block("GraveBase", { x, z }, { 2.6, 0.5, 1.2 }, "Stone", "Slate")
				Pieces.block("Gravestone", { x, z }, { 2, 2.8, 0.5 }, "Stone", "Slate", 0.5)
			end
		end
		for _, spot in { { 22, -28 }, { 54, -52 }, { 54, -28 } } do
			deadTree(spot)
		end
	end)
end

-- The arcade by the second street: a dark building with neon trim, a glass front and a big ARCADE sign.
local function arcade()
	local at, size = { 84, -36 }, { 32, 12, 26 }
	B.model("Arcade", function()
		Pieces.block("Walls", at, size, "ArcadeBlue", "Concrete")
		panel("Front", at, { size[1], size[3] }, "-Z", 0, 3, 24, 4.6, "Glass", "Glass")
		for index, color in { "NeonPink", "NeonTeal" } do
			B.part({
				Name = "NeonTrim",
				Size = { size[1] + 0.4, 0.3, size[3] + 0.4 },
				Position = { at[1], size[2] - index * 0.8, at[2] },
				Color = color,
				Material = "Neon",
				CanCollide = false,
				CastShadow = false,
			})
		end
		B.sign({
			Name = "ArcadeSign",
			Size = { 18, 3, 0.4 },
			Position = { at[1], 8.6, at[2] - size[3] / 2 - 0.5 },
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Arcade",
			TextColor = "NeonPink",
			Glow = true,
			CanCollide = false,
		})
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The edges of the district: the mall and bowling alley (north-west), apartments (east)
---------------------------------------------------------------------------------------------------------------------

local function mall()
	local at, size = { -166, 15 }, { 60, 16, 70 }
	B.model("Mall", function()
		Pieces.block("Walls", at, size, "CityTan", "Concrete")
		local footprint = { size[1], size[3] }
		panel("Storefront", at, footprint, "+X", 0, 3.5, 60, 5, "Glass", "Glass")
		panel("UpperWindows", at, footprint, "+X", 0, 11, 56, 3, "Glass", "Glass")
		for index, color in { "NeonPink", "ShopYellow", "NeonTeal", "ShopOrange" } do
			panel(`Graffiti{index}`, at, footprint, "+Z", -22 + (index - 1) * 14, 4 + (index % 2), 9, 4.5, color)
		end
		B.sign({
			Name = "MallSign",
			Size = { 16, 4, 0.4 },
			Position = { at[1] + size[1] / 2 + 0.3, 13, at[2] },
			Rotation = B.yaw("East"),
			Color = "CityBlue",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Mall",
			TextColor = "OffWhite",
			CanCollide = false,
		})
		ladder({ at[1] + size[1] / 2 + 1, at[2] + 30 }, 0, 16)
	end)
	local alley, alleySize = { -168, -42 }, { 56, 10, 32 }
	B.model("BowlingAlley", function()
		Pieces.block("Walls", alley, alleySize, "ShopRed", "Concrete")
		panel("Front", alley, { alleySize[1], alleySize[3] }, "+X", 0, 3, 20, 4, "Glass", "Glass")
		B.sign({
			Name = "BowlingSign",
			Size = { 14, 2.6, 0.4 },
			Position = { alley[1] + alleySize[1] / 2 + 0.3, 7.4, alley[2] },
			Rotation = B.yaw("East"),
			Color = "OffWhite",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Bowling",
			TextColor = "Red",
			CanCollide = false,
		})
		-- A giant pin on the roof.
		upright("GiantPin", { -150, -42 }, alleySize[2], 6, 2.6, "OffWhite", "SmoothPlastic", false)
		upright("PinStripe", { -150, -42 }, alleySize[2] + 4, 0.6, 2.7, "Red", "SmoothPlastic", false)
		B.part({
			Name = "PinHead",
			Size = { 2.2, 2.2, 2.2 },
			Position = { -150, alleySize[2] + 6.8, -42 },
			Shape = "Ball",
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end)
end

-- An apartment block `size` (X, height, Z): walls, a balcony strip and glass every floor on its street face (−X),
-- AC units on some balconies.
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
			if floor % 2 == 1 then
				acUnit({ front - 0.9, at[2] + size[3] / 2 - 3 }, y + 0.15)
			end
		end
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The south: the shop row, the jail and the comedy club, the courthouse and mansion, the pocket park
---------------------------------------------------------------------------------------------------------------------

local function shopRow()
	for index, entry in
		{
			{ -101, 12, "ShopRed", "Map.Shinjuku.Sign.Books" },
			{ -83, 15, "ShopYellow", "Map.Shinjuku.Sign.Electronics" },
			{ -65, 10, "ShopTeal", "Map.Shinjuku.Sign.Karaoke" },
			{ -47, 14, "ShopPink", "Map.Shinjuku.Sign.Subs" },
			{ -29, 11, "ShopOrange", "Map.Shinjuku.Sign.Sweets" },
		}
	do
		shop(`Shop{index}`, { entry[1], -88 }, { 18, entry[2], 16 }, entry[3], "+Z", entry[4])
	end
	-- Behind the shops: dumpsters and manholes.
	for _, at in { { -40, -100 }, { -100, -102 } } do
		Pieces.block("Dumpster", at, { 5, 3.4, 3 }, "Bottle", "Metal")
	end
	for _, at in { { -70, -140 }, { -30, -160 } } do
		upright("Manhole", at, 0.1, 0.04, 2.4, "MetalDark", "DiamondPlate", false)
	end
end

local function jailAndClub()
	local jail, jailSize = { -170, -104 }, { 28, 12.6, 22 }
	B.model("Jail", function()
		Pieces.block("Walls", jail, jailSize, "LightPurple", "Concrete")
		for floor = 0, 2 do
			panel("Windows", jail, { jailSize[1], jailSize[3] }, "+Z", 0, 2.6 + floor * 4.2, 22, 1.8, "Glass", "Glass")
		end
		B.sign({
			Name = "JailSign",
			Size = { 8, 1.6, 0.3 },
			Position = { jail[1], 11.6, jail[2] + jailSize[3] / 2 + 0.25 },
			Rotation = B.yaw("North"),
			Color = "OffWhite",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Jail",
			TextColor = "Black",
			CanCollide = false,
		})
		-- The barred cell on its east side.
		local cell = { jail[1] + jailSize[1] / 2 + 4, jail[2] - 1 }
		Pieces.block("CellRoof", cell, { 8, 0.4, 10 }, "MetalDark", "Metal", 6)
		for z = cell[2] - 4.5, cell[2] + 4.5, 1 do
			upright("Bar", { cell[1] + 3.9, z }, 0, 6, 0.2, "MetalDark", "Metal")
		end
		for x = cell[1] - 3.5, cell[1] + 3, 1 do
			for _, z in { cell[2] - 4.9, cell[2] + 4.9 } do
				upright("Bar", { x, z }, 0, 6, 0.2, "MetalDark", "Metal")
			end
		end
	end)
	local club, clubSize = { -170, -145 }, { 24, 8, 18 }
	B.model("ComedyClub", function()
		Pieces.block("Walls", club, clubSize, "Purple", "Concrete")
		B.sign({
			Name = "ClubSign",
			Size = { 14, 2.2, 0.3 },
			Position = { club[1], 6.8, club[2] + clubSize[3] / 2 + 0.25 },
			Rotation = B.yaw("North"),
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Map.Shinjuku.Sign.Comedy",
			TextColor = "LaneYellow",
			Glow = true,
			CanCollide = false,
		})
		for index = 0, 6 do
			B.part({
				Name = "MarqueeLight",
				Size = { 0.5, 0.5, 0.5 },
				Position = { club[1] - 7.5 + index * 2.5, 8.4, club[2] + clubSize[3] / 2 + 0.3 },
				Shape = "Ball",
				Color = "WarmLight",
				Material = "Neon",
				CanCollide = false,
			})
		end
	end)
end

local function courtAndMansion()
	-- The courthouse: white, a portico of six columns over three steps, a COURT sign.
	local court, courtSize = { 40, -112 }, { 34, 10, 22 }
	local front = court[2] + courtSize[3] / 2
	B.model("Courthouse", function()
		Pieces.block("Walls", court, courtSize, "OffWhite", "Marble")
		Pieces.block("PorticoFloor", { court[1], front + 2 }, { 36, 1.2, 4 }, "OffWhite", "Marble")
		Pieces.block("PorticoRoof", { court[1], front + 2 }, { 36, 1, 4.4 }, "OffWhite", "Marble", 9.2)
		for index = 0, 5 do
			Pieces.column("Column", { court[1] - 15 + index * 6, front + 3 }, 1.2, 9.2, 1.4, "OffWhite", "Marble", true)
		end
		Pieces.stairs("CourtSteps", { court[1], front + 7 }, "-Z", 20, 3, 0.4, 1, "OffWhite", "Marble")
		B.sign({
			Name = "CourtSign",
			Size = { 12, 1.4, 0.3 },
			Position = { court[1], 10.7, front + 4.3 },
			Rotation = B.yaw("North"),
			Color = "OffWhite",
			Material = "Marble",
			Key = "Map.Shinjuku.Sign.Court",
			TextColor = "Black",
			CanCollide = false,
		})
	end)
	-- The mansion: two floors, a garage on the side, a low hedge along the front with a gap.
	local mansion, mansionSize = { 88, -140 }, { 28, 9.5, 20 }
	B.model("Mansion", function()
		Pieces.block("Walls", mansion, mansionSize, "Cream", "Concrete")
		Pieces.block("Roof", mansion, { 30, 0.6, 22 }, "AsphaltDark", "Slate", mansionSize[2])
		for floor = 0, 1 do
			panel(
				"Windows",
				mansion,
				{ mansionSize[1], mansionSize[3] },
				"+Z",
				0,
				2.6 + floor * 4.6,
				24,
				2,
				"Glass",
				"Glass"
			)
		end
		Pieces.block("Garage", { 68, -138 }, { 12, 5, 12 }, "Cream", "Concrete")
		panel("GarageDoor", { 68, -138 }, { 12, 12 }, "+Z", 0, 2.2, 9, 4.2, "MetalDark", "Metal")
		for _, piece in { { 62, 80 }, { 90, 104 } } do
			Pieces.block(
				"Hedge",
				{ (piece[1] + piece[2]) / 2, -124 },
				{ piece[2] - piece[1], 1.6, 1.4 },
				"Leaf",
				"LeafyGrass"
			)
		end
	end)
end

local function pocketPark()
	paint("Lawn", { 164, -123 }, { 72, 90 }, "Lawn", "Grass")
	paint("Path", { 164, -123 }, { 4, 90 }, "ConcreteLight", "Pavement", 0.06)
	for index, at in { { 140, -95 }, { 186, -95 }, { 140, -138 }, { 186, -150 }, { 166, -160 } } do
		tree(`CherryTree{index}`, at, "SakuraPink")
	end
	bench({ 156, -110 }, 90)
	bench({ 172, -135 }, -90)
	vendingRow({ 190, -110 }, 2, -90)
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
	apartments("ApartmentsNorth", { 166, 36 }, { 60, 24, 28 }, "Cream")
	apartments("ApartmentsSouth", { 166, -40 }, { 60, 30, 32 }, "CityGrey")
	vendingRow({ 186, -2 }, 3, 180)
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
		for x = -220, 220, 44 do
			block({ x, halfZ + 24 }, { 42, 40 }, "-Z")
			block({ x, -halfZ - 24 }, { 42, 40 }, "+Z")
		end
		for z = -150, 150, 50 do
			block({ halfX + 24, z }, { 40, 48 }, "-X")
			block({ -halfX - 24, z }, { 40, 48 }, "+X")
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
