--!strict
--[[
	Lobby: "The Hideout" — an enclosed hideout bar (owner's choices: a closed space instead of the open Rust Diner
	rooftop, 2026-10-16; 25% bigger and in the style of the reference pictures in docs/reference — wood, gold trim,
	warm lamps, a red sofa corner — with detailed furniture instead of plain blocks, 2026-10-19).

	Walls: grey-green plaster over dark wood wainscoting (framed panels, a gold rail), dark wood pillars with gold bands
	and wall lamps, wood beams with gold strips under a dark ceiling. Floor: a light carpet, wood planks in the bar.
	North: the bar — marble-topped counter (Shop) with the bartender (Shop NPC), stools, a mirrored back bar with
	shelves of bottles, map vote TVs hanging over the bar, news TVs on the counter ends, the title sign. Booths with
	tufted benches in both north corners.
	East: the steel ARENA door with the join pad in front of it (QueueZone: only players standing on it are taken into
	the next round), barrels, a dartboard.
	West: Locker booth (Inventory), Codes jukebox, the cork quest board.
	South: three tall leaderboard boards, the spawn pads, the street door.
	Middle: the lounge — a rug with a gold ring, a round black marble table, a red tufted sofa and two armchairs, floor
	lamps, topiaries — a pool table and high tables with stools. Furniture comes from maps/lib/Furniture.
	Seats (sofas, armchairs, booth benches, stools) are LobbySeat-tagged Seats: walk up and press the Sit prompt.
	Interactive objects carry CollectionService tags so code can attach prompts and UI.
]]
local B = require("../lib/Builder")
local F = require("../lib/Furniture")

local Layout = {}

Layout.Id = "Hideout"
Layout.Lighting = "Dusk"

-- X, Z: floor space inside the walls (92 × 68 until 2026-10-19; 138 × 102 for a day, "too big"; now 1.25×).
local INNER = { 115, 85 }
local HALF_X, HALF_Z = INNER[1] / 2, INNER[2] / 2
local HEIGHT = 26 -- floor to ceiling
local WALL = 2
local KILL_DEPTH = 40 -- falling this far below the floor returns you to a spawn
local WAINSCOT = 6 -- height of the wood panelling
local BAR_DEPTH = 32 -- the wood floor in front of the north wall
local PILLARS_X = { -38, 38 } -- pillars on the north / south walls
local PILLARS_Z = { -34, -17, 17, 34 } -- pillars on the east / west walls

-- Join pad in front of the ARENA door (east wall).
local PAD_SIZE = { 14, 18 } -- X, Z
local PAD_X = HALF_X - 2 - PAD_SIZE[1] / 2

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
	B.part({
		Name = "FloorEdge",
		Size = { INNER[1], 0.12, 0.4 },
		Position = { 0, 0.06, HALF_Z - BAR_DEPTH },
		Color = "Gold",
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
	-- Crown molding where the walls meet the ceiling.
	for _, crown in
		{
			{ size = { INNER[1], 0.8, 0.8 }, pos = { 0, HALF_Z - 0.4 } },
			{ size = { INNER[1], 0.8, 0.8 }, pos = { 0, -HALF_Z + 0.4 } },
			{ size = { 0.8, 0.8, INNER[2] }, pos = { HALF_X - 0.4, 0 } },
			{ size = { 0.8, 0.8, INNER[2] }, pos = { -HALF_X + 0.4, 0 } },
		}
	do
		B.part({
			Name = "Crown",
			Size = crown.size,
			Position = { crown.pos[1], HEIGHT - 0.4, crown.pos[2] },
			Color = "WoodDark",
			Material = "Wood",
			CastShadow = false,
		})
	end
	B.part({
		Name = "Ceiling",
		Size = { INNER[1] + WALL * 2, 2, INNER[2] + WALL * 2 },
		Position = { 0, HEIGHT + 1, 0 },
		Color = "Black",
		Material = "Plaster",
		CastShadow = true,
	})
	-- Wood beams with a gold strip down each lower edge.
	for _, z in { -28, -14, 0, 14, 28 } do
		B.part({
			Name = "Beam",
			Size = { INNER[1], 1.6, 1.4 },
			Position = { 0, HEIGHT - 0.8, z },
			Color = "WoodDark",
			Material = "Wood",
		})
		for _, side in { -1, 1 } do
			B.part({
				Name = "BeamStrip",
				Size = { INNER[1], 0.12, 0.12 },
				Position = { 0, HEIGHT - 1.62, z + side * 0.64 },
				Color = "Gold",
				Material = "Metal",
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	-- Pillars along the walls; the east / west ones carry lit wall lamps.
	for _, z in PILLARS_Z do
		F.pillar(HALF_X - 1.2, z, "West", HEIGHT, true)
		F.pillar(-HALF_X + 1.2, z, "East", HEIGHT, true)
	end
	for _, x in PILLARS_X do
		F.pillar(x, HALF_Z - 1.2, "South", HEIGHT, false)
		F.pillar(x, -HALF_Z + 1.2, "North", HEIGHT, false)
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
	-- Back bar: a framed mirror, gold shelves on brackets, bottles, a cabinet with framed doors.
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
			Color = "Gold",
			Material = "Metal",
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
		Color = "Marble",
		Material = "Marble",
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
			Color = "Gold",
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
			Color = "Gold",
			Material = "Metal",
		})
		for _, x in { -14, 0, 14 } do
			B.part({
				Name = "Bracket",
				Size = { 0.25, 0.9, 1.4 },
				Position = { x, y - 0.6, wallZ - 1.2 },
				Color = "Gold",
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

	-- The counter (Shop): framed wood front, marble top with a rounded front edge, gold foot rail on brackets.
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
		Color = "Marble",
		Material = "Marble",
	})
	B.part({
		Name = "CounterEdge",
		Size = { width + 1, 0.55, 0.55 },
		Position = { 0, 3.68, counterZ - 1.75 },
		Shape = "Cylinder",
		Color = "Marble",
		Material = "Marble",
	})
	B.part({
		Name = "FootRail",
		Size = { width, 0.35, 0.35 },
		Position = { 0, 0.75, counterZ - 2.1 },
		Shape = "Cylinder",
		Color = "Gold",
		Material = "Metal",
		CanCollide = false,
	})
	for index = 1, 5 do
		B.part({
			Name = "RailBracket",
			Size = { 0.2, 0.7, 0.6 },
			Position = { -width / 2 + 2 + (index - 1) * (width - 4) / 4, 0.55, counterZ - 1.8 },
			Color = "Gold",
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
			Color = "Gold",
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
			for rivet = 1, 5 do
				B.part({
					Name = "Rivet",
					Size = { 0.3, 0.3, 0.3 },
					Position = { x - 0.95, rivet * 2.6, side * (PAD_SIZE[2] / 2 + 0.6) },
					Shape = "Ball",
					Color = "MetalDark",
					Material = "Metal",
					CanCollide = false,
				})
			end
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
			Position = { HALF_X - 0.6, 9, 26 },
			Shape = "Cylinder",
			Color = ring[2],
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
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
			B.part({
				Name = "SideTrim",
				Size = { 10, 0.25, 1.1 },
				Position = { x, 6.1, z + side * 6 },
				Color = "Gold",
				Material = "Metal",
				CanCollide = false,
			})
		end
		B.part({ Name = "Top", Size = { 12, 1, 14 }, Position = { x, 10.5, z }, Color = "WoodDark", Material = "Wood" })
		B.part({
			Name = "TopTrim",
			Size = { 12.2, 0.25, 14.2 },
			Position = { x, 10, z },
			Color = "Gold",
			Material = "Metal",
		})
		for index = 1, 5 do
			local doorZ = z + (index - 3) * 2.2
			B.part({
				Name = "LockerDoor",
				Size = { 0.4, 7, 2 },
				Position = { x - 4.8, 3.6, doorZ },
				Color = if index % 2 == 0 then "Teal" else "TealDark",
				Material = "Metal",
			})
			for vent = 1, 3 do
				B.part({
					Name = "Vent",
					Size = { 0.1, 0.12, 1.2 },
					Position = { x - 4.57, 6.2 - vent * 0.3, doorZ },
					Color = "Black",
					Material = "Metal",
					CanCollide = false,
				})
			end
			B.part({
				Name = "Handle",
				Size = { 0.2, 0.9, 0.2 },
				Position = { x - 4.5, 3.6, doorZ + 0.6 },
				Color = "Gold",
				Material = "Metal",
				CanCollide = false,
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
			Size = { 5, 6, 3.5 },
			Position = { x, 3, z },
			Rotation = B.yaw("East"),
			Color = "RustDark",
			Material = "SmoothPlastic",
		})
		B.part({
			Name = "Arch",
			Size = { 3.5, 5, 5 }, -- a cylinder front to back: the rounded top
			Position = { x, 6, z },
			Shape = "Cylinder",
			Color = "RustDark",
			Material = "SmoothPlastic",
		})
		B.part({
			Name = "ArchGlass",
			Size = { 0.2, 3.6, 3.6 },
			Position = { x + 1.8, 6, z },
			Shape = "Cylinder",
			Color = "NeonOrange",
			Material = "Neon",
			Transparency = 0.3,
			CanCollide = false,
		})
		for index, color in { "NeonPink", "NeonTeal", "NeonOrange" } do
			B.part({
				Name = "Stripe",
				Size = { 4.2, 0.3, 0.2 },
				Position = { x + 1.85, 0.8 + index * 1.2, z },
				Rotation = B.yaw("East"),
				Color = color,
				Material = "Neon",
				CanCollide = false,
			})
		end
		B.part({
			Name = "Grille",
			Size = { 0.15, 1.2, 3 },
			Position = { x + 1.8, 0.7, z },
			Color = "Gold",
			Material = "Metal",
			CanCollide = false,
		})
		B.light(body, "NeonPink", 12, 1.5)
		B.sign({
			Name = "CodesSign",
			Size = { 6, 1.6, 0.4 },
			Position = { x + 0.5, 9.8, z },
			Rotation = B.yaw("East"),
			Color = "Black",
			Material = "SmoothPlastic",
			Key = "Lobby.Sign.Codes",
			TextColor = "NeonOrange",
			Glow = true,
		})
	end):AddTag("CodesJukebox")
end

-- The quest board: a framed cork board with pinned notes.
local function questBoard()
	local x, z = -HALF_X + 0.8, -8
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
				Color = "Red",
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

--[[
	The spin wheel on the west wall (owner's fix list, 2026-10-19: "a spin wheel"). A wood backboard with a gold rim,
	and a Rotor: a black face, WHEEL_SEGMENTS pie slices (each two wedges; attribute Segment = its prize's index, the
	client paints them in the prize colours from Config.Retention.Wheel and turns the Rotor to each spin's prize), a gold
	hub and pegs. Slice 1 starts under the pointer at the top; slices go round toward +Z (south). The prompt that opens
	the wheel screen sits on the Backboard (LobbyPromptController).
]]
local WHEEL_SEGMENTS = 8 -- one per prize in Config.Retention.Wheel.Prizes (the maps spec checks)
local function spinWheel()
	local centerX, centerY, centerZ = -HALF_X + 2, 11, -25.5 -- between the wall pillars at z -17 and -34
	local radius = 6.5
	B.model("SpinWheel", function()
		B.part({
			Name = "Backboard",
			Size = { 0.5, radius * 2 + 1.6, radius * 2 + 1.6 },
			Position = { centerX - 1.4, centerY, centerZ },
			Shape = "Cylinder",
			Color = "WoodDark",
			Material = "Wood",
		})
		B.part({
			Name = "Rim",
			Size = { 0.4, radius * 2 + 0.8, radius * 2 + 0.8 },
			Position = { centerX - 1, centerY, centerZ },
			Shape = "Cylinder",
			Color = "Gold",
			Material = "Metal",
		})
		B.part({
			Name = "Pointer",
			Size = { 0.5, 1.5, 1.5 },
			Position = { centerX + 0.4, centerY + radius + 0.35, centerZ },
			Rotation = { 45, 0, 0 },
			Color = "Red",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		B.sign({
			Name = "WheelSign",
			Size = { 12, 2.4, 0.4 },
			Position = { centerX - 1.3, centerY + radius + 2.8, centerZ },
			Rotation = B.yaw("East"),
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
				Position = { centerX - 0.7, centerY, centerZ },
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
							centerX - 0.45,
							middle[1] - inner / 2 * up[2] + sign * side / 2 * along[2],
							middle[2] - inner / 2 * up[3] + sign * side / 2 * along[3],
						},
						-- Up runs inward (chord middle → centre); Right flips for the second half so its slope faces out.
						Axes = { Right = { sign, 0, 0 }, Up = { 0, -up[2], -up[3] } },
						Shape = "Wedge",
						Color = "OffWhite",
						Material = "SmoothPlastic",
						CanCollide = false,
						CastShadow = false,
						Attributes = { Segment = index },
					})
				end
				B.part({
					Name = "Peg",
					Size = { 0.45, 0.45, 0.45 },
					Position = {
						centerX - 0.35,
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
				Position = { centerX - 0.3, centerY, centerZ },
				Shape = "Cylinder",
				Color = "Gold",
				Material = "Metal",
				CanCollide = false,
			})
			B.light(hub, "WarmLight", 12, 0.6)
		end)
	end):AddTag("SpinWheel")
	-- A red mat in front of it.
	B.part({
		Name = "WheelMat",
		Size = { 6, 0.08, 10 },
		Position = { -HALF_X + 6, 0.12, centerZ },
		Color = "Sofa",
		Material = "Carpet",
		CanCollide = false,
		CastShadow = false,
	})
end

-- Three tall dark leaderboard boards on the south wall (reference: leaderboard-boards.png): a wood frame with gold
-- corners, a cream title with a thin gold underline, and the screen the rows are drawn on (LeaderboardController).
local function leaderboards()
	local z = -HALF_Z + 0.5
	for index, board in
		{
			{ x = -20, stat = "Wins" },
			{ x = 0, stat = "KOs" },
			{ x = 20, stat = "Level" },
		}
	do
		B.model(`Leaderboard{board.stat}`, function()
			B.part({
				Name = "Frame",
				Size = { 17, 21, 1 },
				Position = { board.x, 12.5, z },
				Color = "BoardDark",
				Material = "SmoothPlastic",
			})
			for _, edge in
				{
					{ size = { 17.6, 0.6, 1.3 }, at = { 0, 23.2 } },
					{ size = { 17.6, 0.6, 1.3 }, at = { 0, 1.8 } },
					{ size = { 0.6, 21.4, 1.3 }, at = { -8.8, 12.5 } },
					{ size = { 0.6, 21.4, 1.3 }, at = { 8.8, 12.5 } },
				}
			do
				B.part({
					Name = "FrameWood",
					Size = edge.size,
					Position = { board.x + edge.at[1], edge.at[2], z + 0.15 },
					Color = "WoodDark",
					Material = "Wood",
				})
			end
			for _, cx in { -8.8, 8.8 } do
				for _, cy in { 1.8, 23.2 } do
					B.part({
						Name = "Corner",
						Size = { 0.9, 0.9, 0.2 },
						Position = { board.x + cx, cy, z + 0.85 },
						Color = "Gold",
						Material = "Metal",
						CanCollide = false,
					})
				end
			end
			B.sign({
				Name = "Title",
				Size = { 15.5, 2.4, 0.2 },
				Position = { board.x, 21.1, z + 0.6 },
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
				Position = { board.x, 19.7, z + 0.65 },
				Color = "Gold",
				Material = "Neon",
				CanCollide = false,
				CastShadow = false,
			})
			B.part({
				Name = "Screen",
				Size = { 15.5, 16.2, 0.2 },
				Position = { board.x, 11, z + 0.6 },
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
			Position = { x, 0.5, -HALF_Z + 13 },
			Rotation = B.yaw("North"), -- players spawn facing the bar
			Color = "Teal",
			Material = "SmoothPlastic",
			Tags = { "LobbySpawn" },
		})
	end
	F.pendant(0, 18, -HALF_Z + 13, HEIGHT, 30)
	-- The street door the crew comes in through (decor): a panelled door in a wood frame with a lamp over it.
	local doorX = 46
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
		Color = "Gold",
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
	F.plant(31, -HALF_Z + 3)
end

-- Booths in the north corners: a marble table between two tufted benches that face each other.
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
	-- The sitting area: a rug with a gold ring, a black marble table, a red tufted sofa and two armchairs.
	local rugX, rugZ = -27, -6
	F.rug(rugX, rugZ, 30, 24, 15)
	F.roundTable("CoffeeTable", rugX, rugZ, 6.5, 2.4)
	F.sofa("Sofa", rugX, rugZ - 8, "North", { Seats = 3, Color = "Sofa" })
	F.sofa("ArmchairWest", rugX - 11.5, rugZ + 0.5, "East", { Seats = 1, Color = "Sofa" })
	F.sofa("ArmchairEast", rugX + 11.5, rugZ + 0.5, "West", { Seats = 1, Color = "Sofa" })
	F.floorLamp(rugX - 9, rugZ - 9.5)
	F.floorLamp(rugX + 9, rugZ - 9.5)
	F.plant(rugX - 17, rugZ - 11)
	F.plant(rugX + 17, rugZ + 12)
	F.pendant(rugX, 17, rugZ, HEIGHT, 30)

	-- Pool table with its own lamp.
	F.poolTable(20, -8, "South")
	F.pendant(20, 14, -8, HEIGHT, 24)

	-- High tables with stools between the bar and the arena door.
	for index, spot in { { 14, 13 }, { 29, 13 } } do
		F.roundTable(`HighTable{index}`, spot[1], spot[2], 3.4, 3.9)
		F.stool(`HighStool{index}West`, spot[1] - 2.9, spot[2], "East", 2.1, "Sofa")
		F.stool(`HighStool{index}East`, spot[1] + 2.9, spot[2], "West", 2.1, "Sofa")
	end
	F.pendant(21.5, 18, 13, HEIGHT, 26)
	F.plant(4, 20)

	booth("BoothWest", -41.5, HALF_Z - 8.5) -- clear of the locker booth and the north wall pillars
	booth("BoothEast", 41.5, HALF_Z - 8.5)

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
local ARM_WRESTLE = { 0, -10 }
local function armWrestle()
	local x, z = ARM_WRESTLE[1], ARM_WRESTLE[2]
	F.rug(x, z, 12, 9, 7)
	F.armWrestleTable("ArmWrestleTable", x, z, 3.2, 1.4)
	F.pendant(x, 15, z, HEIGHT, 22)
end

-- The chess table (ChessService) on the bar's wood floor, west of the high tables, on a rug under its own lamp.
-- White sits on the west stool.
local CHESS = { -22, 15 }
local function chess()
	local x, z = CHESS[1], CHESS[2]
	F.rug(x, z, 13, 10, 8)
	F.chessTable("ChessTable", x, z, 3, 1.4)
	F.pendant(x, 15, z, HEIGHT, 22)
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
Layout.JoinPad = { Size = PAD_SIZE, Center = { PAD_X, 0 } }
Layout.ArmWrestle = ARM_WRESTLE
Layout.Chess = CHESS

return Layout
