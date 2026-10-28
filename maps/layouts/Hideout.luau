--!strict
--[[
	Lobby: "The Hideout" — an enclosed hideout bar (owner's choices: a closed space instead of the open Rust Diner
	rooftop, 2026-10-16; 25% bigger and in the style of the reference pictures in docs/reference — wood, gold trim,
	warm lamps, a red sofa corner — with detailed furniture instead of plain blocks, 2026-10-19; a bit less luxury,
	2026-10-27: worn iron, old brass and wood instead of gold and marble, a concrete floor instead of the light carpet;
	the new layout and 15% smaller, 2026-10-27).

	Sides: the owner sees the room in Studio and names its sides as you face the bar — the bar (North, +Z), the left
	wall (+X), the right wall (−X) and the ARENA door's wall opposite the bar (South, −Z). The Builder's facing names
	put "East" at +X with North at +Z, a mirror image of a real compass, so in this room "East" (+X) is the LEFT wall and
	"West" (−X) the right one; the wall parts are named LeftWall / RightWall, and comments here say left / right.

	Walls: grey-green plaster over dark wood wainscoting (framed panels, a wood rail), dark wood pillars with iron bands
	and wall lamps, wood beams and two joists under a dark ceiling. More detail since 2026-10-28 (owner: "more overall
	lobby detail, right now it's just a plain square room with no dynamic or dimension"): boarded-up windows high on the
	side walls glowing with the dusk, bare brick where the plaster has fallen off, old fight posters, a fuse box, an
	old arcade cabinet on each side wall; over the concrete six green warehouse lamps, two slowly turning ceiling fans,
	an air duct and pipes. Floor: concrete slabs with joints, oil stains and a drain; the bar end is a wood platform
	BAR_RISE high with two steps up in the middle and railings either side.
	North (the bar's wood floor): the wood-topped counter (Shop) with the bartender (Shop NPC), stools, a back bar with
	a wood-framed mirror and shelves of bottles, map vote TVs hanging over the bar, news TVs on the counter ends, the
	title sign; two long booths for six on the left side, another and the chess table on two armchairs in front of it
	on the right side, high tables in front of the stools.
	Left wall (+X): the three leaderboards in the middle with the pool table in front of them; a barrel and a dartboard
	at the bar end, the teal barrel in the corner by the ARENA wall.
	Right wall (−X): the spin wheel in the middle with open floor in front of it, and a potted tree.
	South (the ARENA wall): the steel ARENA door with the join pad in front of it (QueueZone: only players standing on
	it are taken into the next round); left of it the style coach (StyleNPC: opens the Styles screen) by the jukebox
	(decor) and the street door in the corner; right of it the quest board and the crates in the corner.
	Middle: open floor between the ARENA door and the bar with the spawn (invisible) in the centre; the arm-wrestling
	table in front of the quest board, level with the pillar on the ARENA side of the spin wheel.
	Furniture comes from maps/lib/Furniture.
	Seats (sofas, armchairs, booth benches, stools) are LobbySeat-tagged Seats: walk up and press the Sit prompt.
	Interactive objects carry CollectionService tags so code can attach prompts and UI.
]]
local B = require("../lib/Builder")
local F = require("../lib/Furniture")

local Layout = {}

Layout.Id = "Hideout"
Layout.Lighting = "Dusk"

-- X, Z: floor space inside the walls (92 × 68 until 2026-10-19; 138 × 102 for a day, "too big"; 115 × 85 until
-- 2026-10-27, then 15% smaller: owner, "make lobby 15% smaller").
local INNER = { 98, 72 }
local HALF_X, HALF_Z = INNER[1] / 2, INNER[2] / 2
local HEIGHT = 26 -- floor to ceiling
local WALL = 2
local KILL_DEPTH = 40 -- falling this far below the floor returns you to a spawn
local WAINSCOT = 6 -- height of the wood panelling
local BAR_DEPTH = 27 -- the wood floor in front of the north wall
local BAR_EDGE = HALF_Z - BAR_DEPTH -- where the concrete meets the bar's floor
-- The bar's wood floor is a platform this high, two steps up from the concrete (owner, 2026-10-28: "more dimension";
-- flush with the concrete before).
local BAR_RISE = 1.5
local BAR_CEILING = HEIGHT - BAR_RISE -- the ceiling, measured from the bar's floor
local STEPS_WIDTH = 44 -- the steps up to it in the middle, railings either side
local BEAMS = { -24, -12, 0, 12, 24 } -- Z of the ceiling beams
-- Pillars along each wall (X on the bar / ARENA walls, Z on the side walls: East = the left wall (+X), West = the
-- right wall (−X), the Builder's names), clear of what hangs there.
local PILLARS = {
	North = { -30, 30 },
	South = { -36.5, 34.8 }, -- clear of the street door (left) and the quest board (right)
	East = { -23, 23 }, -- the left wall, around the leaderboards
	West = { -28.5, -14.5, 14.5, 28.5 }, -- the right wall
}

-- Join pad in front of the ARENA door (south wall, opposite the bar; the left wall until 2026-10-27).
local PAD_SIZE = { 18, 14 } -- X, Z
local PAD_Z = -HALF_Z + 2 + PAD_SIZE[2] / 2

-- Runs `fill` on the bar's raised floor: heights from its top.
local function onBar(fill: () -> ())
	B.within({ 0, BAR_RISE, 0 }, fill)
end

---------------------------------------------------------------------------------------------------------------------
-- Room
---------------------------------------------------------------------------------------------------------------------

-- The concrete floor as poured slabs, 12 studs apart (one sheet until 2026-10-28): thin joints show the darker floor
-- under them, and a few slabs are a lighter grey.
local SLAB_X = { -HALF_X, -36, -24, -12, 0, 12, 24, 36, HALF_X }
local SLAB_Z = { -HALF_Z, -24, -12, 0, BAR_EDGE }
local JOINT = 0.15

local function concrete()
	for ix = 1, #SLAB_X - 1 do
		for iz = 1, #SLAB_Z - 1 do
			local x0, x1, z0, z1 = SLAB_X[ix], SLAB_X[ix + 1], SLAB_Z[iz], SLAB_Z[iz + 1]
			B.part({
				Name = "ConcreteFloor", -- a light carpet until 2026-10-27 (owner: "a bit less luxury")
				Size = { x1 - x0 - JOINT, 0.1, z1 - z0 - JOINT },
				Position = { (x0 + x1) / 2, 0.05, (z0 + z1) / 2 },
				Color = if (ix * 3 + iz * 5) % 4 == 0 then "ConcreteLight" else "Concrete",
				Material = "Concrete",
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
end

--[[
	The bar's raised floor (owner, 2026-10-28: "more dimension"): a wood platform BAR_RISE high over the whole bar end,
	planks on top with an iron nosing, two wood steps up in the middle, and on both sides of them a railing to the
	walls: wood posts, a wood handrail, iron balusters, a newel post with a glass globe at each end of the steps.
]]
local function barPlatform()
	B.part({
		Name = "BarPlatform",
		Size = { INNER[1], BAR_RISE, BAR_DEPTH },
		Position = { 0, BAR_RISE / 2, HALF_Z - BAR_DEPTH / 2 },
		Color = "WoodDark",
		Material = "Wood",
	})
	B.part({
		Name = "BarFloor",
		Size = { INNER[1], 0.1, BAR_DEPTH },
		Position = { 0, BAR_RISE + 0.05, HALF_Z - BAR_DEPTH / 2 },
		Color = "Wood",
		Material = "WoodPlanks",
		CanCollide = false,
		CastShadow = false,
	})
	B.part({
		Name = "FloorEdge",
		Size = { INNER[1], 0.14, 0.5 },
		Position = { 0, BAR_RISE + 0.07, BAR_EDGE + 0.25 },
		Color = "Iron",
		Material = "Metal",
		CanCollide = false,
		CastShadow = false,
	})
	-- Baseboards on the platform along the side walls (the wainscot's own sit under it).
	for _, side in { -1, 1 } do
		B.part({
			Name = "Baseboard",
			Size = { 0.8, 0.8, BAR_DEPTH },
			Position = { side * (HALF_X - 0.4), BAR_RISE + 0.4, HALF_Z - BAR_DEPTH / 2 },
			Color = "WoodDark",
			Material = "Wood",
			CastShadow = false,
		})
	end
	-- Two steps, each a third of the rise, with an iron nosing.
	local tread = 1.4
	for step = 1, 2 do
		local height = BAR_RISE * step / 3
		local front = BAR_EDGE - tread * (3 - step)
		B.part({
			Name = "BarStep",
			Size = { STEPS_WIDTH, height, tread },
			Position = { 0, height / 2, front + tread / 2 },
			Color = "WoodMid",
			Material = "WoodPlanks",
		})
		B.part({
			Name = "StepNosing",
			Size = { STEPS_WIDTH, 0.12, 0.4 },
			Position = { 0, height + 0.06, front + 0.2 },
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
			CastShadow = false,
		})
	end
	-- The railings, and wood battens on the platform's face under them.
	local railZ, railTop = BAR_EDGE + 0.35, BAR_RISE + 3.2
	local from, to = STEPS_WIDTH / 2 + 0.6, HALF_X - 1.7 -- clear of the leaderboard on the left wall
	local length = to - from
	for _, side in { -1, 1 } do
		local middle = side * (from + to) / 2
		B.model("Railing", function()
			B.part({
				Name = "Handrail",
				Size = { length, 0.35, 0.6 },
				Position = { middle, railTop, railZ },
				Color = "WoodMid",
				Material = "Wood",
			})
			B.part({
				Name = "BottomRail",
				Size = { length, 0.3, 0.4 },
				Position = { middle, BAR_RISE + 0.45, railZ },
				Color = "WoodDark",
				Material = "Wood",
			})
			local posts = 7
			for index = 0, posts do
				B.part({
					Name = "Post",
					Size = { 0.45, 3.2, 0.45 },
					Position = { side * (from + index * length / posts), BAR_RISE + 1.6, railZ },
					Color = "WoodDark",
					Material = "Wood",
				})
			end
			local balusters = 24
			for index = 1, balusters - 1 do
				B.part({
					Name = "Baluster",
					Size = { 2.5, 0.14, 0.14 },
					Position = { side * (from + index * length / balusters), BAR_RISE + 1.95, railZ },
					Rotation = { 0, 0, 90 },
					Shape = "Cylinder",
					Color = "Iron",
					Material = "Metal",
				})
			end
			B.part({
				Name = "Newel",
				Size = { 0.9, 3.9, 0.9 },
				Position = { side * from, BAR_RISE + 1.95, railZ },
				Color = "WoodDark",
				Material = "Wood",
			})
			B.part({
				Name = "NewelCap",
				Size = { 1.2, 0.3, 1.2 },
				Position = { side * from, BAR_RISE + 4.05, railZ },
				Color = "WoodMid",
				Material = "Wood",
			})
			B.part({
				Name = "Globe",
				Size = { 0.9, 0.9, 0.9 },
				Position = { side * from, BAR_RISE + 4.65, railZ },
				Shape = "Ball",
				Color = "WarmLight",
				Material = "Neon",
				Transparency = 0.15,
				CanCollide = false,
			})
			for index = 0, 9 do
				B.part({
					Name = "Batten",
					Size = { 0.3, BAR_RISE - 0.2, 0.15 },
					Position = { side * (from + 1.2 + index * (length - 2.4) / 9), BAR_RISE / 2, BAR_EDGE - 0.07 },
					Color = "WoodMid",
					Material = "Wood",
					CanCollide = false,
					CastShadow = false,
				})
			end
		end)
	end
end

local function shell()
	B.slab({
		Name = "Floor",
		Size = { INNER[1] + WALL * 2, 4, INNER[2] + WALL * 2 },
		Position = { 0, 0, 0 },
		Color = "ConcreteDark",
		Material = "Concrete",
	})
	concrete()
	barPlatform()
	local wallY = (HEIGHT + 4) / 2 - 2 -- from below the floor slab up to the ceiling
	for _, wall in
		{
			{ name = "NorthWall", size = { INNER[1] + WALL * 2, HEIGHT + 4, WALL }, pos = { 0, HALF_Z + WALL / 2 } },
			{ name = "SouthWall", size = { INNER[1] + WALL * 2, HEIGHT + 4, WALL }, pos = { 0, -HALF_Z - WALL / 2 } },
			-- Named as you face the bar (EastWall / WestWall until 2026-10-27: the owner saw them the other way round).
			{ name = "LeftWall", size = { WALL, HEIGHT + 4, INNER[2] }, pos = { HALF_X + WALL / 2, 0 } },
			{ name = "RightWall", size = { WALL, HEIGHT + 4, INNER[2] }, pos = { -HALF_X - WALL / 2, 0 } },
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
	-- Wainscoting on every wall, facing into the room.
	F.wainscot(0, HALF_Z, "South", INNER[1], WAINSCOT)
	F.wainscot(0, -HALF_Z, "North", INNER[1], WAINSCOT)
	F.wainscot(HALF_X, 0, "West", INNER[2], WAINSCOT)
	F.wainscot(-HALF_X, 0, "East", INNER[2], WAINSCOT)
	B.part({
		Name = "Ceiling",
		Size = { INNER[1] + WALL * 2, 2, INNER[2] + WALL * 2 },
		Position = { 0, HEIGHT + 1, 0 },
		Color = "Black",
		Material = "Plaster",
		CastShadow = true,
	})
	-- Plain wood beams across the room, and two lighter joists along it between them.
	for _, z in BEAMS do
		B.part({
			Name = "Beam",
			Size = { INNER[1], 1.6, 1.4 },
			Position = { 0, HEIGHT - 0.8, z },
			Color = "WoodDark",
			Material = "Wood",
		})
	end
	for _, x in { -24.5, 24.5 } do
		B.part({
			Name = "Joist",
			Size = { 1, 1.1, INNER[2] },
			Position = { x, HEIGHT - 0.55, 0 },
			Color = "WoodMid",
			Material = "Wood",
		})
	end
	-- Pillars along the walls; the side and ARENA-wall ones carry lit wall lamps (those light the spawns). The ones at
	-- the bar end stand on its platform.
	local function pillar(x: number, z: number, facing: string, lit: boolean)
		if z > BAR_EDGE then
			onBar(function()
				F.pillar(x, z, facing, BAR_CEILING, lit)
			end)
		else
			F.pillar(x, z, facing, HEIGHT, lit)
		end
	end
	for _, z in PILLARS.East do
		pillar(HALF_X - 1.2, z, "West", true)
	end
	for _, z in PILLARS.West do
		pillar(-HALF_X + 1.2, z, "East", true)
	end
	for _, x in PILLARS.North do
		pillar(x, HALF_Z - 1.2, "South", false)
	end
	for _, x in PILLARS.South do
		F.pillar(x, -HALF_Z + 1.2, "North", HEIGHT, true)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Gameplay spots
---------------------------------------------------------------------------------------------------------------------

-- An old CRT TV: a dark casing with a bezel, knobs and a speaker grille, a glowing screen that lights the bar a little.
local function tv(name: string, at: { number }, size: { number }, voteKind: string, index: number)
	B.model(name, function()
		B.part({
			Name = "Casing",
			Size = size,
			Position = at,
			Color = "MetalDark",
			Material = "SmoothPlastic",
		})
		local front = at[3] - size[3] / 2
		local screenW, screenH = size[1] * 0.72, size[2] * 0.72
		local screenX = at[1] - size[1] * 0.08
		local screen = B.part({
			Name = "Screen",
			Size = { screenW, screenH, 0.2 },
			Position = { screenX, at[2] + 0.1, front - 0.1 },
			Color = "CrtGlow",
			Material = "Neon",
			-- "News" TVs show the lobby news (the mode vote TVs until Classic became the only mode, 2026-10-19).
			Tags = { if voteKind == "News" then "NewsScreen" else "VoteScreen" },
			Attributes = { VoteKind = voteKind, Index = index },
		})
		B.light(screen, "CrtGlow", 10, 0.5) -- 0.8 until 2026-10-28 (owner: the bar "a bit less bright")
		B.part({
			Name = "Bezel",
			Size = { screenW + 0.5, screenH + 0.5, 0.1 },
			Position = { screenX, at[2] + 0.1, front - 0.02 },
			Color = "Black",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		local panelX = at[1] + size[1] / 2 - size[1] * 0.1
		for knob = 1, 2 do
			B.part({
				Name = "Knob",
				Size = { 0.2, 0.55, 0.55 },
				Position = { panelX, at[2] + 0.9 - knob * 0.9, front - 0.1 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Color = "Metal",
				Material = "Metal",
				CanCollide = false,
			})
		end
		for slot = 1, 3 do
			B.part({
				Name = "Grille",
				Size = { 0.6, 0.08, 0.05 },
				Position = { panelX, at[2] - size[2] / 2 + 0.4 + slot * 0.25, front - 0.03 },
				Color = "Black",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
		for _, side in { -1, 1 } do
			B.part({
				Name = "Antenna",
				Size = { 0.15, 3, 0.15 },
				Position = { at[1] + side * 0.8, at[2] + size[2] / 2 + 1.3, at[3] },
				Rotation = { 0, 0, side * -25 },
				Color = "Metal",
				Material = "Metal",
			})
			B.part({
				Name = "AntennaTip",
				Size = { 0.3, 0.3, 0.3 },
				Position = { at[1] + side * 1.43, at[2] + size[2] / 2 + 2.66, at[3] },
				Shape = "Ball",
				Color = "Metal",
				Material = "Metal",
				CanCollide = false,
			})
		end
	end)
end

-- The bar on its raised floor (heights from the platform's top).
local function barOnPlatform()
	local wallZ = HALF_Z
	local width = 44
	B.sign({
		Name = "TitleSign",
		Size = { 40, 4.6, 0.6 },
		Position = { 0, 21.5, wallZ - 0.9 },
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Title",
		TextColor = "NeonPink",
		Glow = true,
	})
	-- Back bar: a wood-framed mirror, plank shelves on iron brackets, bottles, a cabinet with framed doors.
	B.part({
		Name = "BackMirror",
		Size = { width - 2, 9.5, 0.2 },
		Position = { 0, 10.75, wallZ - 0.65 },
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.35,
		CanCollide = false,
	})
	for _, edge in
		{
			{ size = { width, 0.6, 0.5 }, at = { 0, 15.8 } },
			{ size = { 0.6, 10.6, 0.5 }, at = { -width / 2 + 0.7, 10.75 } },
			{ size = { 0.6, 10.6, 0.5 }, at = { width / 2 - 0.7, 10.75 } },
		}
	do
		B.part({
			Name = "MirrorFrame",
			Size = edge.size,
			Position = { edge.at[1], edge.at[2], wallZ - 0.75 },
			Color = "WoodMid",
			Material = "Wood",
		})
	end
	B.part({
		Name = "BackCabinet",
		Size = { width, 5.5, 2.6 },
		Position = { 0, 2.75, wallZ - 1.8 },
		Color = "WoodDark",
		Material = "Wood",
	})
	B.part({
		Name = "BackCabinetTop",
		Size = { width + 0.4, 0.35, 3 },
		Position = { 0, 5.65, wallZ - 1.8 },
		Color = "WoodMid",
		Material = "Wood",
	})
	for index = 1, 8 do
		local x = -width / 2 + (index - 0.5) * width / 8
		B.part({
			Name = "CabinetDoor",
			Size = { width / 8 - 1, 3.8, 0.15 },
			Position = { x, 2.7, wallZ - 3.15 },
			Color = "WoodMid",
			Material = "Wood",
			CanCollide = false,
		})
		B.part({
			Name = "DoorKnob",
			Size = { 0.3, 0.3, 0.3 },
			Position = { x + (if index % 2 == 0 then -1.6 else 1.6), 3, wallZ - 3.3 },
			Shape = "Ball",
			Color = "OldBrass",
			Material = "Metal",
			CanCollide = false,
		})
	end
	local colors = { "Bottle", "Amber", "Glass", "NeonTeal", "DustyPink" }
	for row, y in { 7.6, 10.6, 13.6 } do
		B.part({
			Name = "Shelf",
			Size = { width - 3, 0.3, 1.8 },
			Position = { 0, y, wallZ - 1.4 },
			Color = "WoodMid",
			Material = "WoodPlanks",
		})
		for _, x in { -14, 0, 14 } do
			B.part({
				Name = "Bracket",
				Size = { 0.25, 0.9, 1.4 },
				Position = { x, y - 0.6, wallZ - 1.2 },
				Color = "Iron",
				Material = "Metal",
				CanCollide = false,
			})
		end
		for index = 1, 13 do
			F.bottle(
				-18.75 + (index - 1) * 3.1,
				y + 0.15,
				wallZ - 1.4,
				colors[(index + row) % #colors + 1],
				(index + row) % 3 == 0
			)
		end
	end

	-- The counter (Shop): framed wood front, a worn wood top with a rounded front edge, an old brass foot rail on iron
	-- brackets.
	local counterZ = wallZ - 11
	B.part({
		Name = "CounterBase",
		Size = { width, 3.5, 3 },
		Position = { 0, 1.75, counterZ },
		Color = "WoodDark",
		Material = "WoodPlanks",
		Tags = { "ShopCounter" },
	})
	for index = 1, 6 do
		local x = -width / 2 + (index - 0.5) * width / 6
		B.part({
			Name = "CounterPanel",
			Size = { width / 6 - 1.4, 2.2, 0.15 },
			Position = { x, 1.85, counterZ - 1.55 },
			Color = "Brick",
			Material = "Wood",
			CanCollide = false,
		})
		for _, edge in
			{
				{ size = { width / 6 - 1, 0.2, 0.15 }, y = 3.05 },
				{ size = { width / 6 - 1, 0.2, 0.15 }, y = 0.65 },
			}
		do
			B.part({
				Name = "CounterMolding",
				Size = edge.size,
				Position = { x, edge.y, counterZ - 1.6 },
				Color = "WoodMid",
				Material = "Wood",
				CanCollide = false,
			})
		end
	end
	B.part({
		Name = "CounterTop",
		Size = { width + 1, 0.4, 3.6 },
		Position = { 0, 3.7, counterZ + 0.2 },
		Color = "WoodMid",
		Material = "WoodPlanks",
	})
	B.part({
		Name = "CounterEdge",
		Size = { width + 1, 0.55, 0.55 },
		Position = { 0, 3.68, counterZ - 1.75 },
		Shape = "Cylinder",
		Color = "WoodMid",
		Material = "Wood",
	})
	B.part({
		Name = "FootRail",
		Size = { width, 0.35, 0.35 },
		Position = { 0, 0.75, counterZ - 2.1 },
		Shape = "Cylinder",
		Color = "OldBrass",
		Material = "Metal",
		CanCollide = false,
	})
	for index = 1, 5 do
		B.part({
			Name = "RailBracket",
			Size = { 0.2, 0.7, 0.6 },
			Position = { -width / 2 + 2 + (index - 1) * (width - 4) / 4, 0.55, counterZ - 1.8 },
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
		})
	end
	B.sign({
		Name = "ShopSign", -- over the back bar, under the title sign
		Size = { 12, 1.6, 0.2 },
		Position = { 0, 17.3, wallZ - 0.8 },
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Shop",
		TextColor = "NeonOrange",
		Glow = true,
	})
	-- Bar stools: sit facing the counter.
	for index = 1, 7 do
		F.stool(`BarStool{index}`, -18 + (index - 1) * 6, counterZ - 4.2, "North", 2.1, "Sofa")
	end

	-- Map vote TVs hang over the bar; news TVs stand on the counter ends.
	for index, x in { -15, 0, 15 } do
		tv(`MapTV{index}`, { x, 14, counterZ }, { 8, 6.5, 5 }, "Map", index)
		B.part({
			Name = "TVMount",
			Size = { 0.4, BAR_CEILING - 17.25, 0.4 },
			Position = { x, (BAR_CEILING + 17.25) / 2, counterZ },
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
		})
	end
	for index, x in { -19.5, 19.5 } do
		tv(`NewsTV{index}`, { x, 5.9, counterZ }, { 5, 4, 4 }, "News", index)
	end

	-- The bartender (Shop NPC) behind the counter: a real Roblox character the server builds here at runtime
	-- (NpcService), standing on Spot and facing the room. Torso is where the Shop prompt sits (LobbyPromptController).
	local npcZ = counterZ + 3.5
	B.model("ShopNPC", function()
		B.part({
			Name = "Spot",
			Size = { 2, 0.2, 2 },
			Position = { 0, 0.1, npcZ },
			Rotation = B.yaw("South"),
			Color = "NeonTeal",
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
		})
		B.part({
			Name = "Torso",
			Size = { 2, 2, 1 },
			Position = { 0, 3.9, npcZ },
			Color = "NeonTeal",
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
		})
	end, { Role = "Shop" }):AddTag("ShopNPC")

	-- Between the TVs, not in front of them; dimmer and shorter-reaching since 2026-10-28 (owner: "make bar counter
	-- and behind bartender light a bit less bright"; 1.3 bright reaching 26 studs, onto the back bar, before).
	for _, x in { -7.5, 7.5 } do
		F.pendant(x, 18.5, counterZ - 5, BAR_CEILING, 24, 0.9)
	end
end

local function bar()
	onBar(barOnPlatform)
end

-- The steel ARENA door in the middle of the south wall, opposite the bar (the left wall until 2026-10-27; owner:
-- "arena entry in place of the old leaderboards, opposite the bar"), with the join pad in front of it.
local function arenaDoor()
	local z = -HALF_Z + 0.3
	local width = PAD_SIZE[1]
	B.model("ArenaDoor", function()
		B.part({
			Name = "Door",
			Size = { width, 14, 0.6 },
			Position = { 0, 7, z },
			Color = "MetalDark",
			Material = "CorrodedMetal",
		})
		for index = 1, 6 do
			B.part({
				Name = "Rib",
				Size = { width, 0.4, 0.3 },
				Position = { 0, index * 2, z + 0.4 },
				Color = "Metal",
				Material = "Metal",
				CanCollide = false,
			})
		end
		for _, side in { -1, 1 } do
			local frameX = side * (width / 2 + 0.6)
			B.part({
				Name = "Frame",
				Size = { 1.2, 15, 1.2 },
				Position = { frameX, 7.5, z + 0.3 },
				Color = "LaneYellow",
				Material = "Metal",
			})
			for rivet = 1, 5 do
				B.part({
					Name = "Rivet",
					Size = { 0.3, 0.3, 0.3 },
					Position = { frameX, rivet * 2.6, z + 0.95 },
					Shape = "Ball",
					Color = "MetalDark",
					Material = "Metal",
					CanCollide = false,
				})
			end
		end
		B.part({
			Name = "Lintel",
			Size = { width + 2.4, 1.2, 1.2 },
			Position = { 0, 14.6, z + 0.3 },
			Color = "LaneYellow",
			Material = "Metal",
		})
		B.sign({
			Name = "ArenaSign",
			Size = { 14, 3, 0.4 },
			Position = { 0, 17.4, z + 1 },
			Rotation = B.yaw("North"),
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
		Position = { 0, 0.1, PAD_Z },
		Color = "NeonOrange",
		Material = "Neon",
		Transparency = 0.45,
		CanCollide = false,
		CastShadow = false,
		Tags = { "QueueZone" },
	})
	B.light(pad, "NeonOrange", 18, 1.2)
	-- Hazard border on the pad's three open sides.
	local front = PAD_Z + PAD_SIZE[2] / 2
	for _, edge in
		{
			{ size = { PAD_SIZE[1] + 1.2, 0.12, 0.6 }, pos = { 0, front + 0.3 } },
			{ size = { 0.6, 0.12, PAD_SIZE[2] }, pos = { -PAD_SIZE[1] / 2 - 0.3, PAD_Z } },
			{ size = { 0.6, 0.12, PAD_SIZE[2] }, pos = { PAD_SIZE[1] / 2 + 0.3, PAD_Z } },
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
	-- The "STAND HERE TO FIGHT" signs on posts at the pad's front corners went on 2026-10-27 (owner: "remove stand here
	-- to fight sign"); the glowing pad and the ARENA sign show the way.
end

-- The left wall's decor: a rust barrel with a dartboard over it at the bar end, the teal barrel in the corner by the
-- street door.
local function leftWall()
	local function barrel(index: number, z: number)
		B.part({
			Name = `Barrel{index}`,
			Size = { 4, 2.6, 2.6 },
			Position = { HALF_X - 2.2, 2, z },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = if index == 1 then "RustOrange" else "Teal",
			Material = "CorrodedMetal",
		})
		for _, y in { 0.9, 3.1 } do
			B.part({
				Name = "BarrelHoop",
				Size = { 0.2, 2.75, 2.75 },
				Position = { HALF_X - 2.2, y, z },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
	end
	onBar(function()
		barrel(1, 30)
		for index, ring in { { 2.6, "Black" }, { 2, "OffWhite" }, { 1.3, "Sofa" }, { 0.5, "Black" } } do
			B.part({
				Name = `Dartboard{index}`,
				Size = { 0.1 + index * 0.05, ring[1], ring[1] },
				Position = { HALF_X - 0.6, 9, 31 },
				Shape = "Cylinder",
				Color = ring[2],
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
	end)
	barrel(2, -HALF_Z + 1.7)
end

--[[
	The style coach on the ARENA wall left of the door, by the jukebox, where the street door was (owner, 2026-10-27:
	"delete locker area, replace with an interactive NPC for the style roll", "move style npc to near music box", then
	"swap place of npc style + music box with green door"; at the bar end of the right wall, then in the left-hand
	corner, before): NpcService builds a Roblox character on the invisible Spot, facing the room (like the bartender);
	the Styles prompt sits on the invisible Torso anchor (LobbyPromptController), so it works even if the character
	can't be built. He stands against the ARENA wall, a STYLES sign over him, a mat under him.
]]
local COACH_X, JUKEBOX_X = 24.5, 30.5
local function styleCoach()
	local x, z = COACH_X, -HALF_Z + 3
	B.model("StyleNPC", function()
		B.part({
			Name = "Spot",
			Size = { 2, 0.2, 2 },
			Position = { x, 0.1, z },
			Rotation = B.yaw("North"),
			Color = "NeonTeal",
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
		})
		B.part({
			Name = "Torso",
			Size = { 2, 2, 1 },
			Position = { x, 3.9, z },
			Rotation = B.yaw("North"),
			Color = "NeonTeal",
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
		})
	end, { Role = "Styles" }):AddTag("StyleNPC")
	B.sign({
		Name = "StylesSign",
		Size = { 5, 1.6, 0.4 },
		Position = { x, 11, -HALF_Z + 0.4 },
		Rotation = B.yaw("North"),
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Styles",
		TextColor = "NeonPink",
		Glow = true,
	})
	B.part({
		Name = "CoachMat",
		Size = { 6, 0.08, 5 },
		Position = { x, 0.12, z + 0.5 },
		Color = "Teal",
		Material = "Carpet",
		CanCollide = false,
		CastShadow = false,
	})
end

-- The jukebox against the ARENA wall beside the style coach, where the street door was (owner, 2026-10-27: "add
-- music box between pillar … green barrel and box", then "swap place of npc style + music box with green door"; the
-- Codes jukebox on the right wall went): decor only, no prompt. A wood cabinet with a glowing arch, a window with
-- records, neon stripes and a speaker grille. Local spots: along the wall, up, out from the wall.
local function jukebox()
	local at = F.at(JUKEBOX_X, -HALF_Z, "North")
	local ACROSS = { 0, 90, 0 } -- a cylinder's axis turned out from the wall
	B.model("Jukebox", function()
		local body = B.part(at({
			Name = "Body",
			Size = { 5, 6, 3.5 },
			Position = { 0, 3, 2.5 },
			Color = "WoodMid",
			Material = "Wood",
		}))
		B.part(at({
			Name = "Arch",
			Size = { 3.5, 5, 5 }, -- the rounded top
			Position = { 0, 6, 2.5 },
			Rotation = ACROSS,
			Shape = "Cylinder",
			Color = "WoodMid",
			Material = "Wood",
		}))
		B.part(at({
			Name = "ArchGlass",
			Size = { 0.2, 3.6, 3.6 },
			Position = { 0, 6, 4.3 },
			Rotation = ACROSS,
			Shape = "Cylinder",
			Color = "NeonOrange",
			Material = "Neon",
			Transparency = 0.3,
			CanCollide = false,
		}))
		B.part(at({
			Name = "Window",
			Size = { 3.8, 1.8, 0.15 },
			Position = { 0, 4.2, 4.3 },
			Color = "Black",
			Material = "Glass",
			Transparency = 0.3,
			CanCollide = false,
		}))
		for index, dx in { -1.2, 0, 1.2 } do
			B.part(at({
				Name = `Record{index}`,
				Size = { 0.08, 1.1, 1.1 },
				Position = { dx, 4.2, 4.15 },
				Rotation = ACROSS,
				Shape = "Cylinder",
				Color = "Black",
				Material = "SmoothPlastic",
				CanCollide = false,
			}))
			B.part(at({
				Name = `RecordLabel{index}`,
				Size = { 0.1, 0.4, 0.4 },
				Position = { dx, 4.2, 4.16 },
				Rotation = ACROSS,
				Shape = "Cylinder",
				Color = if index == 2 then "LaneYellow" else "Red",
				Material = "SmoothPlastic",
				CanCollide = false,
			}))
		end
		for index, color in { "NeonPink", "NeonTeal", "NeonOrange" } do
			B.part(at({
				Name = "Stripe",
				Size = { 4.2, 0.3, 0.2 },
				Position = { 0, 1.1 + index * 0.6, 4.35 },
				Color = color,
				Material = "Neon",
				CanCollide = false,
			}))
		end
		B.part(at({
			Name = "Grille",
			Size = { 3, 1.2, 0.15 },
			Position = { 0, 0.7, 4.3 },
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		}))
		B.light(body, "NeonPink", 12, 1.5)
	end)
end

-- The quest board on the ARENA wall, right of the door as you face the bar: a framed cork board with pinned notes.
local QUEST_X = -27
local function questBoard()
	local at = F.at(QUEST_X, -HALF_Z, "North")
	B.model("QuestBoard", function()
		B.part(at({
			Name = "Frame",
			Size = { 13.4, 8.4, 0.5 },
			Position = { 0, 9, 0.7 },
			Color = "WoodDark",
			Material = "Wood",
		}))
		B.part(at({
			Name = "Board",
			Size = { 12, 7, 0.6 },
			Position = { 0, 9, 0.8 },
			Color = "Cork",
			Material = "Fabric",
		}))
		for index, note in { { -3.5, 1.5 }, { 0, 2 }, { 3.6, 1.2 }, { -2, -1.6 }, { 2.4, -1.8 }, { 4.6, -0.8 } } do
			B.part(at({
				Name = `Note{index}`,
				Size = { 1.5, 1.8, 0.1 },
				Position = { note[1], 9 + note[2], 1.15 },
				Rotation = { 0, 0, index * 7 - 20 },
				Color = "OffWhite",
				Material = "SmoothPlastic",
				CanCollide = false,
			}))
			B.part(at({
				Name = `Pin{index}`,
				Size = { 0.3, 0.3, 0.2 },
				Position = { note[1], 9.6 + note[2], 1.25 },
				Color = "Red",
				Material = "SmoothPlastic",
				CanCollide = false,
			}))
		end
		B.sign(at({
			Name = "QuestSign",
			Size = { 10, 2, 0.4 },
			Position = { 0, 14.2, 1.2 },
			Color = "RustOrange",
			Material = "Metal",
			Key = "Lobby.Sign.Quests",
			TextColor = "OffWhite",
		}))
	end):AddTag("QuestBoard")
end

--[[
	The spin wheel in the middle of the right wall (there since it was built, but for a day, 2026-10-27, on the left wall
	while the leaderboards had the right wall). A wood backboard with a gold rim, and a Rotor: a black face,
	WHEEL_SEGMENTS pie slices (each two wedges; attribute Segment = its prize's index, the client paints them in the
	prize colours from Config.Retention.Wheel and turns the Rotor to each spin's prize about the hub's X axis), an
	invisible Label on each slice (same Segment; facing the room, its up pointing out to the rim: the client writes the
	prize and its chance on it), a gold hub and pegs. Slice 1 starts under the pointer at the top; slices go round
	toward +Z. In front, on the mat, the SpinButton: a post with a big red Button that carries the spin prompt
	(WheelController; since 2026-10-20
	there is no wheel screen — owner: "no click UI, have to walk to spin"). The model streams in whole (Atomic), so the
	client always finds every slice and label. `ROOM` is the side of the wall the room is on (1: toward +X, on the right
	wall; −1 on the left wall).
]]
local WHEEL_SEGMENTS = 8 -- one per prize in Config.Retention.Wheel.Prizes (the maps spec checks)
local function spinWheel()
	local ROOM = 1
	local centerX, centerY, centerZ = -HALF_X + 2, 11, 0
	local radius = 6.5
	local wheel = B.model("SpinWheel", function()
		B.part({
			Name = "Backboard",
			Size = { 0.5, radius * 2 + 1.6, radius * 2 + 1.6 },
			Position = { centerX - 1.4 * ROOM, centerY, centerZ },
			Shape = "Cylinder",
			Color = "WoodDark",
			Material = "Wood",
		})
		B.part({
			Name = "Rim",
			Size = { 0.4, radius * 2 + 0.8, radius * 2 + 0.8 },
			Position = { centerX - 1 * ROOM, centerY, centerZ },
			Shape = "Cylinder",
			Color = "Gold",
			Material = "Metal",
		})
		B.part({
			Name = "Pointer",
			Size = { 0.5, 1.5, 1.5 },
			Position = { centerX + 0.4 * ROOM, centerY + radius + 0.35, centerZ },
			Rotation = { 45, 0, 0 },
			Color = "Red",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.sign({
			Name = "WheelSign",
			Size = { 12, 2.4, 0.4 },
			Position = { centerX - 1.3 * ROOM, centerY + radius + 2.8, centerZ },
			Rotation = B.yaw(if ROOM > 0 then "East" else "West"),
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Lobby.Sign.Wheel",
			TextColor = "Gold",
			Glow = true,
		})
		B.model("Rotor", function()
			B.part({
				Name = "Face",
				Size = { 0.3, radius * 2, radius * 2 },
				Position = { centerX - 0.7 * ROOM, centerY, centerZ },
				Shape = "Cylinder",
				Color = "Black",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
			-- A slice = two right-angled wedges meeting on the line from the centre to the middle of its rim chord.
			local half = math.pi / WHEEL_SEGMENTS
			local inner, side = radius * math.cos(half), radius * math.sin(half) * 0.97 -- a hair short: thin seams show
			for index = 1, WHEEL_SEGMENTS do
				local angle = (index - 1) * 2 * half
				local up = { 0, math.cos(angle), math.sin(angle) } -- outward, toward this slice's middle
				local along = { 0, -math.sin(angle), math.cos(angle) } -- along the rim chord
				local middle = { centerY + inner * up[2], centerZ + inner * up[3] } -- the chord's middle (Y, Z)
				for _, sign in { 1, -1 } do
					B.part({
						Name = `Slice{index}`,
						Size = { 0.2, inner, side },
						Position = {
							centerX - 0.45 * ROOM,
							middle[1] - inner / 2 * up[2] + sign * side / 2 * along[2],
							middle[2] - inner / 2 * up[3] + sign * side / 2 * along[3],
						},
						-- Up runs inward (chord middle → centre); Right flips for the second half so its slope faces out.
						-- The wedge is a thin slab across X, so its shape doesn't depend on the wall it hangs on.
						Axes = { Right = { sign, 0, 0 }, Up = { 0, -up[2], -up[3] } },
						Shape = "Wedge",
						Color = "OffWhite",
						Material = "SmoothPlastic",
						CanCollide = false,
						CastShadow = false,
						Attributes = { Segment = index },
					})
				end
				-- The prize label: across the slice at mid-radius, facing the room (its front toward ROOM along X), its
				-- up toward the rim.
				B.part({
					Name = "Label",
					Size = { 3.2, 3.4, 0.05 },
					Position = { centerX - 0.32 * ROOM, centerY + 4.4 * up[2], centerZ + 4.4 * up[3] },
					Axes = { Right = { 0, -up[3] * ROOM, up[2] * ROOM }, Up = up },
					Color = "Black",
					Transparency = 1,
					CanCollide = false,
					CastShadow = false,
					Attributes = { Segment = index },
				})
				B.part({
					Name = "Peg",
					Size = { 0.45, 0.45, 0.45 },
					Position = {
						centerX - 0.35 * ROOM,
						centerY + (radius - 0.3) * math.cos(angle + half),
						centerZ + (radius - 0.3) * math.sin(angle + half),
					},
					Shape = "Ball",
					Color = "Gold",
					Material = "Metal",
					CanCollide = false,
				})
			end
			local hub = B.part({
				Name = "Hub",
				Size = { 0.6, 2.2, 2.2 },
				Position = { centerX - 0.3 * ROOM, centerY, centerZ },
				Shape = "Cylinder",
				Color = "Gold",
				Material = "Metal",
				CanCollide = false,
			})
			B.light(hub, "WarmLight", 12, 0.6)
		end)
		-- The spin button on the mat: a base, a wood post, a gold housing and the big red Button (the prompt's part).
		B.model("SpinButton", function()
			local x = centerX + 4 * ROOM
			for _, piece in
				{
					{ "Base", { 0.3, 2.4, 2.4 }, 0.15, "Gold", "Metal", true },
					{ "Post", { 3, 0.7, 0.7 }, 1.8, "WoodDark", "Wood", true },
					{ "Housing", { 0.5, 1.8, 1.8 }, 3.55, "Gold", "Metal", true },
					{ "Button", { 0.45, 1.3, 1.3 }, 4, "Red", "SmoothPlastic", false },
				}
			do
				B.part({
					Name = piece[1],
					Size = piece[2],
					Position = { x, piece[3], centerZ },
					Rotation = { 0, 0, 90 },
					Shape = "Cylinder",
					Color = piece[4],
					Material = piece[5],
					CanCollide = piece[6],
				})
			end
		end)
	end)
	wheel.ModelStreamingMode = B.Enum.ModelStreamingMode.Atomic
	wheel:AddTag("SpinWheel")
	-- A red mat in front of it.
	B.part({
		Name = "WheelMat",
		Size = { 6, 0.08, 10 },
		Position = { centerX + 4 * ROOM, 0.12, centerZ },
		Color = "Sofa",
		Material = "Carpet",
		CanCollide = false,
		CastShadow = false,
	})
end

--[[
	Three tall dark leaderboard boards in the middle of the left wall (owner, 2026-10-27: "center of left wall", then
	"opposite side": the right wall for a day; the south wall until then) — reference: leaderboard-boards.png. Each: a
	wood frame with iron corners, a cream title with a thin gold underline, and the screen the rows are drawn on
	(LeaderboardController). Read from left to right (south to north): Wins, KOs, Level.
]]
local function leaderboards()
	-- 12 × 16.5 since 2026-10-27 (owner: "smaller leaderboard"; 17 × 21 before, 14 × 21 for a day). The screen keeps
	-- the first board's shape, so LeaderboardController scales the same rows to it.
	local width, height, bottom = 12, 16.5, 2.5
	local middle, top = bottom + height / 2, bottom + height
	local screenWidth = width - 1.2
	local screenHeight = screenWidth * 16.2 / 15.5
	for index, board in
		{
			{ z = -14.5, stat = "Wins" },
			{ z = 0, stat = "KOs" },
			{ z = 14.5, stat = "Level" },
		}
	do
		local at = F.at(HALF_X, board.z, "West")
		B.model(`Leaderboard{board.stat}`, function()
			B.part(at({
				Name = "Frame",
				Size = { width, height, 1 },
				Position = { 0, middle, 0.5 },
				Color = "BoardDark",
				Material = "SmoothPlastic",
			}))
			for _, edge in
				{
					{ size = { width + 0.6, 0.6, 1.3 }, at = { 0, top + 0.2 } },
					{ size = { width + 0.6, 0.6, 1.3 }, at = { 0, bottom - 0.2 } },
					{ size = { 0.6, height + 0.4, 1.3 }, at = { -width / 2 - 0.3, middle } },
					{ size = { 0.6, height + 0.4, 1.3 }, at = { width / 2 + 0.3, middle } },
				}
			do
				B.part(at({
					Name = "FrameWood",
					Size = edge.size,
					Position = { edge.at[1], edge.at[2], 0.65 },
					Color = "WoodDark",
					Material = "Wood",
				}))
			end
			for _, cx in { -width / 2 - 0.3, width / 2 + 0.3 } do
				for _, cy in { bottom - 0.2, top + 0.2 } do
					B.part(at({
						Name = "Corner",
						Size = { 0.9, 0.9, 0.2 },
						Position = { cx, cy, 1.35 },
						Color = "Iron",
						Material = "Metal",
						CanCollide = false,
					}))
				end
			end
			B.sign(at({
				Name = "Title",
				Size = { screenWidth, 2, 0.2 },
				Position = { 0, top - 1.6, 1.1 },
				Color = "BoardDark",
				Material = "SmoothPlastic",
				Key = `Lobby.Sign.Leaderboard.{board.stat}`,
				TextColor = "Cream",
				Glow = true,
			}))
			B.part(at({
				Name = "Underline",
				Size = { width * 0.6, 0.12, 0.2 },
				Position = { 0, top - 3.1, 1.15 },
				Color = "Gold",
				Material = "Neon",
				CanCollide = false,
				CastShadow = false,
			}))
			B.part(at({
				Name = "Screen",
				Size = { screenWidth, screenHeight, 0.2 },
				Position = { 0, top - 3.75 - screenHeight / 2, 1.1 },
				Color = "BoardDark",
				Material = "SmoothPlastic",
				Tags = { "LeaderboardScreen" },
				Attributes = { Stat = board.stat, Order = index },
			}))
		end, { Stat = board.stat }):AddTag("Leaderboard")
	end
end

--[[
	The spawn in the middle of the room, facing the bar: an invisible, walk-through SpawnLocation flush with the floor
	(owner, 2026-10-27: "set player spawn in center, no blue plate below"; two teal 6 × 6 pads beside the join pad
	before). MapService puts returning players on a random spot of it. Then two trees by the ARENA wall and the street
	door.
]]
local function spawns()
	B.spawnLocation({
		Name = "LobbySpawn",
		Size = { 10, 0.2, 10 },
		Position = { 0, 0.1, 0 },
		Rotation = B.yaw("North"), -- players spawn facing the bar
		Color = "Teal",
		Material = "SmoothPlastic",
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
		Tags = { "LobbySpawn" },
	})
	-- The street door the crew comes in through (decor): a panelled door in a wood frame with a lamp over it, in the
	-- left-hand corner of the ARENA wall since 2026-10-27 (owner: "swap place of npc style + music box with green door").
	local doorX = 41
	B.part({
		Name = "StreetDoor",
		Size = { 7, 10, 0.4 },
		Position = { doorX, 5, -HALF_Z + 0.7 },
		Color = "TealDark",
		Material = "Metal",
	})
	for _, y in { 2.8, 7.2 } do
		B.part({
			Name = "DoorPanel",
			Size = { 5.4, 3.4, 0.15 },
			Position = { doorX, y, -HALF_Z + 0.95 },
			Color = "Teal",
			Material = "Metal",
			CanCollide = false,
		})
	end
	B.part({
		Name = "DoorHandle",
		Size = { 0.3, 0.3, 0.4 },
		Position = { doorX + 2.6, 5, -HALF_Z + 1.1 },
		Shape = "Ball",
		Color = "OldBrass",
		Material = "Metal",
		CanCollide = false,
	})
	for _, side in { -1, 1 } do
		B.part({
			Name = "DoorFrame",
			Size = { 0.8, 11, 1 },
			Position = { doorX + side * 3.9, 5.5, -HALF_Z + 0.5 },
			Color = "WoodDark",
			Material = "Wood",
		})
	end
	B.part({
		Name = "DoorHead",
		Size = { 8.6, 0.8, 1 },
		Position = { doorX, 10.6, -HALF_Z + 0.5 },
		Color = "WoodDark",
		Material = "Wood",
	})
	F.sconce(doorX, 12.5, -HALF_Z + 0.1, "North", true)
	F.plant(19, -HALF_Z + 4)
	F.plant(-14, -HALF_Z + 4) -- on the bar's wood floor until 2026-10-27 (owner: "move tree off bar platform")
end

-- A booth on the bar's floor: a wood table between two channel-stitched benches that face each other, under its own
-- lamp (no shadows since 2026-10-28: the concrete's ceiling lamps have them). `seats` per bench (2 by default; 3 seat
-- six people).
local function booth(name: string, x: number, z: number, seats: number?)
	local perBench = seats or 2
	F.boothTable(`{name}Table`, x, z, perBench * 3)
	F.sofa(
		`{name}BenchSouth`,
		x,
		z - 3.8,
		"North",
		{ Seats = perBench, Color = "Sofa", Material = "Leather", TallBack = true }
	)
	F.sofa(
		`{name}BenchNorth`,
		x,
		z + 3.8,
		"South",
		{ Seats = perBench, Color = "Sofa", Material = "Leather", TallBack = true }
	)
	F.pendant(x, 15, z, BAR_CEILING, 22, 1.3, false)
end

local function lounge()
	-- The lounge (a rug, a round table, a sofa, armchairs, floor lamps, a tree and a lamp over it, in front of the spin
	-- wheel at the end) is gone (owner, 2026-10-27: "that entire circle table area + rug + floor lamp + tree"), and so
	-- are the lamps that hung over the concrete floor ("remove 3 lamp above concrete": the lounge's, the pool table's
	-- and the arm-wrestling table's). A tree stays by the right wall past the wheel.
	F.plant(-HALF_X + 3, -21.5)

	-- The pool table along the left wall, in front of the leaderboards (it stands lower than their screens) (owner,
	-- 2026-10-27: "arm wrestling and snooker move to side"; left of the middle before).
	F.poolTable(37, -10, "East")

	onBar(function()
		-- High tables with stools in front of the bar stools, under one lamp (reaching 22 studs since 2026-10-28, not
		-- 26: it lit the back bar too).
		for index, x in { -10, 10 } do
			F.roundTable(`HighTable{index}`, x, 13, 3.4, 3.9)
			F.stool(`HighStool{index}West`, x - 2.9, 13, "East", 2.1, "Sofa")
			F.stool(`HighStool{index}East`, x + 2.9, 13, "West", 2.1, "Sofa")
		end
		F.pendant(0, 18, 13, BAR_CEILING, 22)

		-- Three long booths for six on the bar's wood floor (owner, 2026-10-27: "add more tables with sofas", "longer
		-- red booth for 6 people", then "make 3 red booth all 6 seat plus longer"): two on the left side, clear of the
		-- leaderboards (the front one clear of the railing), and one in the right-hand corner behind the chess table.
		booth("BoothLeftNorth", 33, HALF_Z - 8.5, 3)
		booth("BoothLeft", 33, 16, 3)
		booth("BoothRight", -35, HALF_Z - 8.5, 3)
	end)

	-- Crates: the hideout's junk, in the right-hand corner by the ARENA wall (the left one is the jukebox's).
	for index, crate in
		{
			{ -HALF_X + 3, -HALF_Z + 3, 4 },
			{ -HALF_X + 8, -HALF_Z + 7.5, 3 },
			{ -HALF_X + 7.5, -HALF_Z + 3, 3 },
			{ -HALF_X + 3.2, -HALF_Z + 3, 2.5, 4 },
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

-- The arm-wrestling table (ArmWrestleService) where the line out from the quest board meets the line out from the
-- spin wheel's left pillar (the one toward the ARENA wall), on its own rug (owner, 2026-10-27: "change wrestling to
-- intercept in front of quest and left spin wheel pillar"; in the middle of the room, then by the left wall before).
-- The pull runs along X (side to side).
local ARM_WRESTLE = { QUEST_X, PILLARS.West[2] }
local function armWrestle()
	local x, z = ARM_WRESTLE[1], ARM_WRESTLE[2]
	F.rug(x, z, 12, 9, 7)
	F.armWrestleTable("ArmWrestleTable", x, z, 3.2, 1.4)
end

-- The chess table (ChessService) on the right side of the bar's wood floor as you face the bar, in front of the long
-- booth, on two armchairs and no rug (owner, 2026-10-27: "chess to north right, change chair to sofa, no rug", then
-- "swap place chess chair table and red booth"; in the left-hand corner for a day, the Builder's mirrored "east",
-- then in the right-hand corner), under its own lamp. White sits in the −X armchair (the one nearer the right wall).
local CHESS = { -35, 15 }
local function chess()
	onBar(function()
		local x, z = CHESS[1], CHESS[2]
		F.chessTable("ChessTable", x, z, 3)
		F.pendant(x, 15, z, BAR_CEILING, 22)
	end)
end

--[[
	The ceiling over the concrete floor (owner, 2026-10-28: "add some ceiling lamps above the concrete area", "more
	overall lobby detail … no dynamic or dimension"): six green warehouse lamps hung close under it between the beams
	(the main light there; they cast the shadows), two ceiling fans under the middle beam that turn slowly (Spin
	movers), a big air duct along the left side and two pipes along the right side, strapped to the beams.
]]
local function ceiling()
	for _, z in { -18, -6 } do
		for _, x in { -30, 0, 30 } do
			F.ceilingLamp(x, z, HEIGHT, 4.5, 36, 1.2)
		end
	end
	local beamBottom = HEIGHT - 1.6
	for index, x in { -15, 15 } do
		F.ceilingFan(`CeilingFan{index}`, x, -12, beamBottom, 5, index * 1.3)
	end

	-- The duct: galvanized, a joint ring every 6 studs, two straps up to each beam, vents under it.
	local ductX, ductY, ductSize = 40, HEIGHT - 3.7, 2.6
	B.model("AirDuct", function()
		B.part({
			Name = "Duct",
			Size = { INNER[2], ductSize, ductSize },
			Position = { ductX, ductY, 0 },
			Rotation = { 0, 90, 0 },
			Shape = "Cylinder",
			Color = "Metal",
			Material = "Metal",
		})
		for index = 1, INNER[2] / 6 - 1 do
			B.part({
				Name = "Joint",
				Size = { 0.3, ductSize + 0.2, ductSize + 0.2 },
				Position = { ductX, ductY, -HALF_Z + index * 6 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
		for _, z in BEAMS do
			for _, side in { -1, 1 } do
				B.part({
					Name = "Strap",
					Size = { 0.15, beamBottom - ductY, 0.4 },
					Position = { ductX + side * (ductSize / 2 + 0.08), (beamBottom + ductY) / 2, z },
					Color = "Iron",
					Material = "Metal",
					CanCollide = false,
				})
			end
		end
		for _, z in { -27, -9, 18 } do
			B.part({
				Name = "Vent",
				Size = { 1.6, 0.6, 3 },
				Position = { ductX, ductY - ductSize / 2 - 0.1, z },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			for slat = -1, 1 do
				B.part({
					Name = "VentSlat",
					Size = { 1.4, 0.08, 0.3 },
					Position = { ductX, ductY - ductSize / 2 - 0.42, z + slat * 0.8 },
					Color = "Black",
					Material = "Metal",
					CanCollide = false,
				})
			end
		end
	end)

	-- The pipes: a teal water pipe and an iron one, wall to wall, each on a strap from every beam.
	B.model("Pipes", function()
		for _, pipe in { { -40, 0.7, "TealDark" }, { -41.4, 0.5, "Iron" } } do
			local x, size = pipe[1], pipe[2]
			local y = beamBottom - 0.5 - size / 2
			B.part({
				Name = "Pipe",
				Size = { INNER[2], size, size },
				Position = { x, y, 0 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Color = pipe[3],
				Material = "Metal",
				CanCollide = false,
			})
			for _, z in BEAMS do
				B.part({
					Name = "Strap",
					Size = { 0.12, beamBottom - y, 0.3 },
					Position = { x, (beamBottom + y) / 2, z + 1 },
					Color = "Iron",
					Material = "Metal",
					CanCollide = false,
				})
			end
		end
	end)
end

--[[
	Wall detail (owner, 2026-10-28: "more overall lobby detail … just a plain square room"): boarded-up windows high on
	both side walls with the dusk glowing through, patches where the plaster has fallen off the brick, two old fight
	posters, a fuse box with its conduit by the street door, and an old arcade cabinet on each side wall (decor).
]]
local function wallDetail()
	-- Windows: two on each side wall, between the pillars.
	for _, z in { -29.5, 29.5 } do
		F.boardedWindow(HALF_X, z, "West", 7, 7.5, 13.5)
	end
	for _, z in { -21.5, 21.5 } do
		F.boardedWindow(-HALF_X, z, "East", 7, 7.5, 13.5)
	end

	-- Bare brick: a ragged patch of three overlapping pieces, (x, z) on the wall's face, its middle `y` up.
	local function brick(x: number, y: number, z: number, facing: string, width: number, height: number)
		local at = F.at(x, z, facing)
		B.model("BrickPatch", function()
			for index, piece in { { 0, 0, 1, 1 }, { -0.3, 0.42, 0.55, 0.45 }, { 0.32, -0.4, 0.5, 0.4 } } do
				B.part(at({
					Name = "Brick",
					Size = { width * piece[3], height * piece[4], 0.06 },
					Position = { width * piece[1], y + height * piece[2], 0.01 + index * 0.02 },
					Color = "BrickRed",
					Material = "Brick",
					CanCollide = false,
					CastShadow = false,
				}))
			end
		end)
	end
	brick(-16, 19.5, -HALF_Z, "North", 6, 3.5) -- the ARENA wall, over the quest board's side of the door
	brick(HALF_X, 22, -7, "West", 5, 3) -- the left wall, over the leaderboards
	brick(-HALF_X, 9, 10.5, "East", 4, 3) -- the right wall, by the wheel

	F.poster(14.5, 10.5, -HALF_Z, "North", "Lobby.Poster.FightNight", { "DustyPink", "Teal" })
	F.poster(-HALF_X, 9.5, 21.5, "East", "Lobby.Poster.Champ", { "LaneYellow", "Red" })

	-- The fuse box on the ARENA wall between the street door and the left wall, its conduit up to the ceiling.
	local at = F.at(46.8, -HALF_Z, "North")
	B.model("FuseBox", function()
		B.part(at({
			Name = "Box",
			Size = { 2.2, 3, 0.8 },
			Position = { 0, 10.5, 0.4 },
			Color = "MetalDark",
			Material = "Metal",
		}))
		B.part(at({
			Name = "Door",
			Size = { 2, 2.8, 0.06 },
			Position = { 0, 10.5, 0.83 },
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		}))
		B.part(at({
			Name = "Warning",
			Size = { 0.9, 0.7, 0.03 },
			Position = { 0, 11.2, 0.87 },
			Color = "LaneYellow",
			Material = "SmoothPlastic",
			CanCollide = false,
		}))
		B.part(at({
			Name = "Handle",
			Size = { 0.15, 0.6, 0.2 },
			Position = { 0.75, 10.2, 0.92 },
			Color = "Black",
			Material = "Metal",
			CanCollide = false,
		}))
		B.part(at({
			Name = "Conduit",
			Size = { HEIGHT - 12, 0.3, 0.3 },
			Position = { 0, (HEIGHT + 12) / 2, 0.2 },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
		}))
	end)

	F.arcade(-HALF_X + 2.15, -10.5, "East", "NeonPink") -- right wall, between the pillar and the wheel
	F.arcade(HALF_X - 2.15, -29.5, "West", "NeonTeal") -- left wall, under the window by the teal barrel
end

-- Floor detail: old oil stains on the concrete and a drain grate where four slabs meet.
local function floorDetail()
	for _, stain in { { 30, -2, 3 }, { -8, -16, 2.4 }, { -40, -24, 4 }, { 21, 4.5, 2 } } do
		for index, blob in { { 0, 0, 1 }, { 0.45, 0.3, 0.55 } } do
			local size = stain[3] * blob[3]
			B.part({
				Name = "OilStain",
				Size = { 0.03, size, size },
				Position = { stain[1] + stain[3] * blob[1], 0.1 + index * 0.012, stain[2] + stain[3] * blob[2] },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "Black",
				Transparency = 0.65,
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	B.model("Drain", function()
		B.part({
			Name = "Grate",
			Size = { 2.4, 0.06, 2.4 },
			Position = { 12, 0.13, -12 },
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
			CastShadow = false,
		})
		for slot = -2, 2 do
			B.part({
				Name = "Slot",
				Size = { 1.8, 0.04, 0.2 },
				Position = { 12, 0.15, -12 + slot * 0.42 },
				Color = "Black",
				Material = "SmoothPlastic",
				CanCollide = false,
				CastShadow = false,
			})
		end
	end)
end

-- Builds the lobby at `origin` (world position of the floor's top centre).
function Layout.build(origin: { number }): any
	return B.root("Lobby", function()
		B.within(origin, function()
			shell()
			bar()
			arenaDoor()
			leftWall()
			styleCoach()
			jukebox()
			questBoard()
			spinWheel()
			leaderboards()
			spawns()
			lounge()
			armWrestle()
			chess()
			ceiling()
			wallDetail()
			floorDetail()
		end)
	end, {
		MapId = Layout.Id,
		Lighting = Layout.Lighting,
		KillY = origin[2] - KILL_DEPTH,
	})
end

-- The room's inside floor size (X, Z) and the join pad's footprint (X, Z) and centre, the bar platform's height and
-- front edge (Z), for specs.
Layout.Inner = INNER
Layout.BarRise = BAR_RISE
Layout.BarEdge = BAR_EDGE
Layout.JoinPad = { Size = PAD_SIZE, Center = { 0, PAD_Z } }
Layout.ArmWrestle = ARM_WRESTLE
Layout.Chess = CHESS

return Layout
