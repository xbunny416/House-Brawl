--!strict
--[[
	Lobby: "The Hideout" — an enclosed hideout bar (owner's choices: a closed space instead of the open Rust Diner
	rooftop, 2026-10-16; 25% bigger and in the style of the reference pictures in docs/reference — wood, gold trim,
	warm lamps, a red sofa corner — with detailed furniture instead of plain blocks, 2026-10-19; a bit less luxury,
	2026-10-27: worn iron, old brass and wood instead of gold and marble, a concrete floor instead of the light carpet;
	the new layout and 15% smaller, 2026-10-27).

	Walls: grey-green plaster over dark wood wainscoting (framed panels, a wood rail), dark wood pillars with iron bands
	and wall lamps, wood beams under a dark ceiling. Floor: concrete, wood planks in the bar.
	North (the bar's wood floor): the wood-topped counter (Shop) with the bartender (Shop NPC), stools, a back bar with
	a wood-framed mirror and shelves of bottles, map vote TVs hanging over the bar, news TVs on the counter ends, the
	title sign; two booths on the west side, the chess table on two armchairs and a booth on the east side, high tables
	in front of the stools.
	West (the left wall as you face the bar): the three leaderboards in the middle, the style coach (StyleNPC: opens the
	Styles screen) at the north end.
	East: the spin wheel in the middle with a barrel on each side, the jukebox (decor) further south, a dartboard.
	South: the steel ARENA door with the join pad in front of it (QueueZone: only players standing on it are taken into
	the next round), the spawn pads on both sides of it, the quest board, the street door, crates in the corner.
	Middle: the lounge — a worn rug with a rust ring, a round wood table, a red sofa and two armchairs, floor lamps,
	potted trees — the arm-wrestling table and the pool table. Furniture comes from maps/lib/Furniture.
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
-- Pillars along each wall (X on the north / south walls, Z on the east / west walls), clear of what hangs there.
local PILLARS = {
	North = { -30, 30 },
	South = { -38, 38 },
	East = { -28.5, -14.5, 14.5, 28.5 },
	West = { -28.2, 28.2 }, -- around the leaderboards
}

-- Join pad in front of the ARENA door (south wall, opposite the bar; the east wall until 2026-10-27).
local PAD_SIZE = { 18, 14 } -- X, Z
local PAD_Z = -HALF_Z + 2 + PAD_SIZE[2] / 2

---------------------------------------------------------------------------------------------------------------------
-- Room
---------------------------------------------------------------------------------------------------------------------

local function shell()
	B.slab({
		Name = "Floor",
		Size = { INNER[1] + WALL * 2, 4, INNER[2] + WALL * 2 },
		Position = { 0, 0, 0 },
		Color = "ConcreteDark",
		Material = "Concrete",
	})
	B.part({
		Name = "ConcreteFloor", -- a light carpet until 2026-10-27 (owner: "a bit less luxury")
		Size = { INNER[1], 0.1, INNER[2] - BAR_DEPTH },
		Position = { 0, 0.05, -BAR_DEPTH / 2 },
		Color = "Concrete",
		Material = "Concrete",
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
	B.part({
		Name = "FloorEdge",
		Size = { INNER[1], 0.12, 0.4 },
		Position = { 0, 0.06, HALF_Z - BAR_DEPTH },
		Color = "Iron",
		Material = "Metal",
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
	-- Plain wood beams.
	for _, z in { -24, -12, 0, 12, 24 } do
		B.part({
			Name = "Beam",
			Size = { INNER[1], 1.6, 1.4 },
			Position = { 0, HEIGHT - 0.8, z },
			Color = "WoodDark",
			Material = "Wood",
		})
	end
	-- Pillars along the walls; the east, west and south ones carry lit wall lamps (the south ones light the spawns).
	for _, z in PILLARS.East do
		F.pillar(HALF_X - 1.2, z, "West", HEIGHT, true)
	end
	for _, z in PILLARS.West do
		F.pillar(-HALF_X + 1.2, z, "East", HEIGHT, true)
	end
	for _, x in PILLARS.North do
		F.pillar(x, HALF_Z - 1.2, "South", HEIGHT, false)
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
		B.light(screen, "CrtGlow", 10, 0.8)
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

local function bar()
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
			Size = { 0.4, HEIGHT - 17.25, 0.4 },
			Position = { x, (HEIGHT + 17.25) / 2, counterZ },
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

	-- Between the TVs, not in front of them.
	for _, x in { -7.5, 7.5 } do
		F.pendant(x, 18.5, counterZ - 5, HEIGHT, 26)
	end
end

-- The steel ARENA door in the middle of the south wall, opposite the bar (the east wall until 2026-10-27; owner:
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
	-- "Stand here" signs on posts at both front corners of the pad, facing the room.
	for _, side in { -1, 1 } do
		local signX, signZ = side * (PAD_SIZE[1] / 2 + 1.5), front + 1.5
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
			Rotation = B.yaw("North"),
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Lobby.Sign.Join",
			TextColor = "NeonOrange",
			Glow = true,
		})
	end
end

-- The east wall's decor: a barrel on each side of the spin wheel (the teal one by the jukebox), a dartboard further
-- north.
local function eastWall()
	for index, z in { 11, -11 } do
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
	for index, ring in { { 2.6, "Black" }, { 2, "OffWhite" }, { 1.3, "Sofa" }, { 0.5, "Black" } } do
		B.part({
			Name = `Dartboard{index}`,
			Size = { 0.1 + index * 0.05, ring[1], ring[1] },
			Position = { HALF_X - 0.6, 9, 22 },
			Shape = "Cylinder",
			Color = ring[2],
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
end

--[[
	The style coach at the north end of the west wall, where the locker booth was (owner, 2026-10-27: "delete locker
	area, replace with an interactive NPC for the style roll"): NpcService builds a Roblox character on the invisible
	Spot, facing the room (like the bartender); the Styles prompt sits on the invisible Torso anchor
	(LobbyPromptController), so it works even if the character can't be built. A STYLES sign over him, a mat under him.
]]
local function styleCoach()
	local x, z = -HALF_X + 3, 33
	B.model("StyleNPC", function()
		B.part({
			Name = "Spot",
			Size = { 2, 0.2, 2 },
			Position = { x, 0.1, z },
			Rotation = B.yaw("East"),
			Color = "NeonTeal",
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
		})
		B.part({
			Name = "Torso",
			Size = { 2, 2, 1 },
			Position = { x, 3.9, z },
			Rotation = B.yaw("East"),
			Color = "NeonTeal",
			Transparency = 1,
			CanCollide = false,
			CastShadow = false,
		})
	end, { Role = "Styles" }):AddTag("StyleNPC")
	B.sign({
		Name = "StylesSign",
		Size = { 5, 1.6, 0.4 },
		Position = { -HALF_X + 0.4, 11, z },
		Rotation = B.yaw("East"),
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Styles",
		TextColor = "NeonPink",
		Glow = true,
	})
	B.part({
		Name = "CoachMat",
		Size = { 5, 0.08, 6 },
		Position = { x + 0.5, 0.12, z },
		Color = "Teal",
		Material = "Carpet",
		CanCollide = false,
		CastShadow = false,
	})
end

-- The jukebox on the east wall between the pillars south of the wheel, by the teal barrel and the crates (owner,
-- 2026-10-27: "add music box between pillar … green barrel and box"; the Codes jukebox on the west wall went): decor
-- only, no prompt. A wood cabinet with a glowing arch, a window with records, neon stripes and a speaker grille.
local function jukebox()
	local x, z = HALF_X - 2.5, -21.5
	local front = -1 -- its front faces the room (−X)
	B.model("Jukebox", function()
		local body = B.part({
			Name = "Body",
			Size = { 5, 6, 3.5 },
			Position = { x, 3, z },
			Rotation = B.yaw("West"),
			Color = "WoodMid",
			Material = "Wood",
		})
		B.part({
			Name = "Arch",
			Size = { 3.5, 5, 5 }, -- a cylinder front to back: the rounded top
			Position = { x, 6, z },
			Shape = "Cylinder",
			Color = "WoodMid",
			Material = "Wood",
		})
		B.part({
			Name = "ArchGlass",
			Size = { 0.2, 3.6, 3.6 },
			Position = { x + 1.8 * front, 6, z },
			Shape = "Cylinder",
			Color = "NeonOrange",
			Material = "Neon",
			Transparency = 0.3,
			CanCollide = false,
		})
		B.part({
			Name = "Window",
			Size = { 3.8, 1.8, 0.15 },
			Position = { x + 1.8 * front, 4.2, z },
			Rotation = B.yaw("West"),
			Color = "Black",
			Material = "Glass",
			Transparency = 0.3,
			CanCollide = false,
		})
		for index, dz in { -1.2, 0, 1.2 } do
			B.part({
				Name = `Record{index}`,
				Size = { 0.08, 1.1, 1.1 },
				Position = { x + 1.65 * front, 4.2, z + dz },
				Shape = "Cylinder",
				Color = "Black",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
			B.part({
				Name = `RecordLabel{index}`,
				Size = { 0.1, 0.4, 0.4 },
				Position = { x + 1.66 * front, 4.2, z + dz },
				Shape = "Cylinder",
				Color = if index == 2 then "LaneYellow" else "Red",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
		for index, color in { "NeonPink", "NeonTeal", "NeonOrange" } do
			B.part({
				Name = "Stripe",
				Size = { 4.2, 0.3, 0.2 },
				Position = { x + 1.85 * front, 1.1 + index * 0.6, z },
				Rotation = B.yaw("West"),
				Color = color,
				Material = "Neon",
				CanCollide = false,
			})
		end
		B.part({
			Name = "Grille",
			Size = { 0.15, 1.2, 3 },
			Position = { x + 1.8 * front, 0.7, z },
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		})
		B.light(body, "NeonPink", 12, 1.5)
	end)
end

-- The quest board on the south wall, west of the ARENA door: a framed cork board with pinned notes.
local function questBoard()
	local at = F.at(-27, -HALF_Z, "North")
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
	The spin wheel in the middle of the east wall, where the ARENA door was (on the west wall until 2026-10-27, when
	the leaderboards took it). A wood backboard with a gold rim, and a Rotor: a black face, WHEEL_SEGMENTS pie slices
	(each two wedges; attribute Segment = its prize's index, the client paints them in the prize colours from
	Config.Retention.Wheel and turns the Rotor to each spin's prize about the hub's X axis), an invisible Label on each
	slice (same Segment; facing the room, its up pointing out to the rim: the client writes the prize and its chance on
	it), a gold hub and pegs. Slice 1 starts under the pointer at the top; slices go round toward +Z. In front, on the
	mat, the SpinButton: a post with a big red Button that carries the spin prompt (WheelController; since 2026-10-20
	there is no wheel screen — owner: "no click UI, have to walk to spin"). The model streams in whole (Atomic), so the
	client always finds every slice and label. `ROOM` is the side of the wall the room is on (−1: toward −X).
]]
local WHEEL_SEGMENTS = 8 -- one per prize in Config.Retention.Wheel.Prizes (the maps spec checks)
local function spinWheel()
	local ROOM = -1
	local centerX, centerY, centerZ = HALF_X - 2, 11, 0
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
			Rotation = B.yaw("West"),
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
	Three tall dark leaderboard boards in the middle of the west wall, the left wall as you face the bar (owner,
	2026-10-27: "center of left wall"; the south wall until then) — reference: leaderboard-boards.png. Each: a wood
	frame with iron corners, a cream title with a thin gold underline, and the screen the rows are drawn on
	(LeaderboardController). Read from left to right (north to south): Wins, KOs, Level.
]]
local function leaderboards()
	local width = 15 -- 17 until 2026-10-27; three fit between the west wall's pillars
	for index, board in
		{
			{ z = 18.2, stat = "Wins" },
			{ z = 0, stat = "KOs" },
			{ z = -18.2, stat = "Level" },
		}
	do
		local at = F.at(-HALF_X, board.z, "East")
		B.model(`Leaderboard{board.stat}`, function()
			B.part(at({
				Name = "Frame",
				Size = { width, 21, 1 },
				Position = { 0, 12.5, 0.5 },
				Color = "BoardDark",
				Material = "SmoothPlastic",
			}))
			for _, edge in
				{
					{ size = { width + 0.6, 0.6, 1.3 }, at = { 0, 23.2 } },
					{ size = { width + 0.6, 0.6, 1.3 }, at = { 0, 1.8 } },
					{ size = { 0.6, 21.4, 1.3 }, at = { -width / 2 - 0.3, 12.5 } },
					{ size = { 0.6, 21.4, 1.3 }, at = { width / 2 + 0.3, 12.5 } },
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
				for _, cy in { 1.8, 23.2 } do
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
				Size = { width - 1.5, 2.4, 0.2 },
				Position = { 0, 21.1, 1.1 },
				Color = "BoardDark",
				Material = "SmoothPlastic",
				Key = `Lobby.Sign.Leaderboard.{board.stat}`,
				TextColor = "Cream",
				Glow = true,
			}))
			B.part(at({
				Name = "Underline",
				Size = { 10, 0.15, 0.2 },
				Position = { 0, 19.7, 1.15 },
				Color = "Gold",
				Material = "Neon",
				CanCollide = false,
				CastShadow = false,
			}))
			B.part(at({
				Name = "Screen",
				Size = { width - 1.5, 16.2, 0.2 },
				Position = { 0, 11, 1.1 },
				Color = "BoardDark",
				Material = "SmoothPlastic",
				Tags = { "LeaderboardScreen" },
				Attributes = { Stat = board.stat, Order = index },
			}))
		end, { Stat = board.stat }):AddTag("Leaderboard")
	end
end

-- The spawn pads on both sides of the join pad, facing the bar, two trees by the walls, and the street door.
local function spawns()
	for index, x in { -19, 19 } do
		B.spawnLocation({
			Name = `LobbySpawn{index}`,
			Size = { 6, 1, 6 },
			Position = { x, 0.5, PAD_Z + 3 },
			Rotation = B.yaw("North"), -- players spawn facing the bar
			Color = "Teal",
			Material = "SmoothPlastic",
			Tags = { "LobbySpawn" },
		})
	end
	-- The street door the crew comes in through (decor): a panelled door in a wood frame with a lamp over it.
	local doorX = 32
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
	F.plant(25, -HALF_Z + 4)
	F.plant(-14, -HALF_Z + 4) -- on the bar's wood floor until 2026-10-27 (owner: "move tree off bar platform")
end

-- A booth: a wood table between two channel-stitched benches that face each other, under its own lamp.
local function booth(name: string, x: number, z: number)
	F.boothTable(`{name}Table`, x, z)
	F.sofa(
		`{name}BenchSouth`,
		x,
		z - 3.8,
		"North",
		{ Seats = 2, Color = "Sofa", Material = "Leather", TallBack = true }
	)
	F.sofa(
		`{name}BenchNorth`,
		x,
		z + 3.8,
		"South",
		{ Seats = 2, Color = "Sofa", Material = "Leather", TallBack = true }
	)
	F.pendant(x, 15, z, HEIGHT, 22)
end

local function lounge()
	-- The sitting area: a worn rug with a rust ring, a round wood table, a red sofa and two armchairs.
	local rugX, rugZ = -25, -4
	F.rug(rugX, rugZ, 28, 20, 13)
	F.roundTable("CoffeeTable", rugX, rugZ, 6.5, 2.4)
	F.sofa("Sofa", rugX, rugZ - 8, "North", { Seats = 3, Color = "Sofa" })
	F.sofa("ArmchairWest", rugX - 11.5, rugZ + 0.5, "East", { Seats = 1, Color = "Sofa" })
	F.sofa("ArmchairEast", rugX + 11.5, rugZ + 0.5, "West", { Seats = 1, Color = "Sofa" })
	F.floorLamp(rugX - 9, rugZ - 9.5)
	F.floorLamp(rugX + 9, rugZ - 9.5)
	F.plant(-HALF_X + 5, -HALF_Z + 5) -- in the corner, clear of the leaderboards
	F.plant(rugX + 16, rugZ + 10)
	F.pendant(rugX, 17, rugZ, HEIGHT, 30)

	-- Pool table with its own lamp.
	F.poolTable(22, -4, "South")
	F.pendant(22, 14, -4, HEIGHT, 24)

	-- High tables with stools in front of the bar stools, under one lamp.
	for index, x in { -10, 10 } do
		F.roundTable(`HighTable{index}`, x, 13, 3.4, 3.9)
		F.stool(`HighStool{index}West`, x - 2.9, 13, "East", 2.1, "Sofa")
		F.stool(`HighStool{index}East`, x + 2.9, 13, "West", 2.1, "Sofa")
	end
	F.pendant(0, 18, 13, HEIGHT, 26)

	-- Booths on the bar's wood floor: two on the west side (one more since 2026-10-27, owner: "add more tables with
	-- sofas"), one on the east side south of the chess table (in the north-east corner until then).
	booth("BoothNorthWest", -33, HALF_Z - 8.5)
	booth("BoothWest", -33, 15)
	booth("BoothEast", 35, 15)

	-- Crates: the hideout's junk, in the south-east corner.
	for index, crate in
		{
			{ HALF_X - 3, -HALF_Z + 3, 4 },
			{ HALF_X - 8, -HALF_Z + 7.5, 3 },
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

-- The arm-wrestling table (ArmWrestleService) in the open middle of the room, between the lounge and the pool table,
-- on its own rug under its own lamp. The pull runs east-west.
local ARM_WRESTLE = { 0, -4 }
local function armWrestle()
	local x, z = ARM_WRESTLE[1], ARM_WRESTLE[2]
	F.rug(x, z, 12, 9, 7)
	F.armWrestleTable("ArmWrestleTable", x, z, 3.2, 1.4)
	F.pendant(x, 15, z, HEIGHT, 22)
end

-- The chess table (ChessService) in the north-east corner of the bar's wood floor, right of the bar, on two armchairs
-- and no rug (owner, 2026-10-27: "chess to north right, change chair to sofa, no rug"), under its own lamp. White sits
-- in the west armchair.
local CHESS = { 35, 28.5 }
local function chess()
	local x, z = CHESS[1], CHESS[2]
	F.chessTable("ChessTable", x, z, 3)
	F.pendant(x, 15, z, HEIGHT, 22)
end

-- Builds the lobby at `origin` (world position of the floor's top centre).
function Layout.build(origin: { number }): any
	return B.root("Lobby", function()
		B.within(origin, function()
			shell()
			bar()
			arenaDoor()
			eastWall()
			styleCoach()
			jukebox()
			questBoard()
			spinWheel()
			leaderboards()
			spawns()
			lounge()
			armWrestle()
			chess()
		end)
	end, {
		MapId = Layout.Id,
		Lighting = Layout.Lighting,
		KillY = origin[2] - KILL_DEPTH,
	})
end

-- The room's inside floor size (X, Z) and the join pad's footprint (X, Z) and centre, for specs.
Layout.Inner = INNER
Layout.JoinPad = { Size = PAD_SIZE, Center = { 0, PAD_Z } }
Layout.ArmWrestle = ARM_WRESTLE
Layout.Chess = CHESS

return Layout
