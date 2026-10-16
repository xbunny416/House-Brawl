--!strict
--[[
	Lobby: "The Hideout" — an enclosed hideout bar (owner's choice, 2026-10-16: a closed space, hideout mixed with a
	bar, instead of the open Rust Diner rooftop; no Training Yard).

	North: the bar — counter (Shop) with the bartender (Shop NPC), bottle shelves, map vote TVs hanging over the bar,
	mode vote TVs on the counter ends, neon "JUNKYARD BRAWL" sign. East: the steel ARENA door with the join pad in
	front of it (QueueZone: only players standing on it are taken into the next round). West: Locker booth, Codes
	jukebox, Quest board. South: leaderboard screens on the wall, the spawn pads and the street door.
	Middle: pool table, high tables, booths in the corners, crates and barrels; hanging lamps light the room.
	Interactive objects carry CollectionService tags so later steps can attach prompts and UI.
]]
local B = require("../lib/Builder")

local Layout = {}

Layout.Id = "Hideout"
Layout.Lighting = "Dusk"

local INNER = { 92, 68 } -- X, Z: floor space inside the walls
local HALF_X, HALF_Z = INNER[1] / 2, INNER[2] / 2
local HEIGHT = 22 -- floor to ceiling
local WALL = 2
local KILL_DEPTH = 40 -- falling this far below the floor returns you to a spawn

-- Join pad in front of the ARENA door (east wall).
local PAD_SIZE = { 14, 18 } -- X, Z
local PAD_X = HALF_X - 2 - PAD_SIZE[1] / 2

local function shell()
	B.slab({
		Name = "Floor",
		Size = { INNER[1] + WALL * 2, 4, INNER[2] + WALL * 2 },
		Position = { 0, 0, 0 },
		Color = "ConcreteDark",
		Material = "Concrete",
	})
	-- Wooden floor in the bar half.
	B.part({
		Name = "BarFloor",
		Size = { INNER[1], 0.1, 30 },
		Position = { 0, 0.05, HALF_Z - 15 },
		Color = "Wood",
		Material = "WoodPlanks",
		CanCollide = false,
		CastShadow = false,
	})
	local wallY = (HEIGHT + 4) / 2 - 2 -- from below the floor slab up to the ceiling
	for _, wall in
		{
			{
				name = "NorthWall",
				size = { INNER[1] + WALL * 2, HEIGHT + 4, WALL },
				pos = { 0, wallY, HALF_Z + WALL / 2 },
			},
			{
				name = "SouthWall",
				size = { INNER[1] + WALL * 2, HEIGHT + 4, WALL },
				pos = { 0, wallY, -HALF_Z - WALL / 2 },
			},
			{ name = "EastWall", size = { WALL, HEIGHT + 4, INNER[2] }, pos = { HALF_X + WALL / 2, wallY, 0 } },
			{ name = "WestWall", size = { WALL, HEIGHT + 4, INNER[2] }, pos = { -HALF_X - WALL / 2, wallY, 0 } },
		}
	do
		B.part({
			Name = wall.name,
			Size = wall.size,
			Position = wall.pos,
			Color = "Brick",
			Material = "Brick",
			CastShadow = true,
		})
	end
	-- Dark wood panels along the bottom of the walls, and neon tubes along the top.
	for index, strip in
		{
			{ size = { INNER[1], 1, 0.4 }, pos = { 0, HALF_Z - 0.2 } },
			{ size = { INNER[1], 1, 0.4 }, pos = { 0, -HALF_Z + 0.2 } },
			{ size = { 0.4, 1, INNER[2] }, pos = { HALF_X - 0.2, 0 } },
			{ size = { 0.4, 1, INNER[2] }, pos = { -HALF_X + 0.2, 0 } },
		}
	do
		B.part({
			Name = "Panel",
			Size = { strip.size[1], 4, strip.size[3] },
			Position = { strip.pos[1], 2, strip.pos[2] },
			Color = "RustDark",
			Material = "Wood",
			CastShadow = false,
		})
		B.part({
			Name = "NeonTrim",
			Size = { strip.size[1], 0.3, strip.size[3] },
			Position = { strip.pos[1], HEIGHT - 1.2, strip.pos[2] },
			Color = if index % 2 == 0 then "NeonTeal" else "NeonPink",
			Material = "Neon",
			CanCollide = false,
		})
	end
	B.part({
		Name = "Ceiling",
		Size = { INNER[1] + WALL * 2, 2, INNER[2] + WALL * 2 },
		Position = { 0, HEIGHT + 1, 0 },
		Color = "Black",
		Material = "Concrete",
		CastShadow = true,
	})
	-- Steel beams and a pipe run under the ceiling.
	for _, z in { -24, -8, 8, 24 } do
		B.part({
			Name = "Beam",
			Size = { INNER[1], 1.2, 1 },
			Position = { 0, HEIGHT - 0.6, z },
			Color = "MetalDark",
			Material = "Metal",
		})
	end
	for _, x in { -HALF_X + 1.5, HALF_X - 1.5 } do
		B.part({
			Name = "Pipe",
			Size = { INNER[2], 0.8, 0.8 },
			Position = { x, HEIGHT - 2.5, 0 },
			Rotation = { 0, 90, 0 },
			Shape = "Cylinder",
			Color = "RustOrange",
			Material = "CorrodedMetal",
		})
	end
end

-- A lamp hanging from the ceiling with a warm light.
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
			Size = { 1.2, 2.4, 2.4 },
			Position = { at[1], at[2], at[3] },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		local bulb = B.part({
			Name = "Bulb",
			Size = { 0.9, 0.9, 0.9 },
			Position = { at[1], at[2] - 0.7, at[3] },
			Shape = "Ball",
			Color = lightColor,
			Material = "Neon",
			CanCollide = false,
		})
		B.light(bulb, lightColor, range, 1.6)
	end)
end

local function tv(name: string, at: { number }, size: { number }, voteKind: string, index: number)
	B.model(name, function()
		B.part({
			Name = "Casing",
			Size = size,
			Position = at,
			Color = "OffWhite",
			Material = "SmoothPlastic",
		})
		B.part({
			Name = "Screen",
			Size = { size[1] * 0.8, size[2] * 0.75, 0.2 },
			Position = { at[1], at[2] + 0.2, at[3] - size[3] / 2 - 0.1 },
			Color = "Black",
			Material = "SmoothPlastic",
			Tags = { "VoteScreen" },
			Attributes = { VoteKind = voteKind, Index = index },
		})
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
	-- Neon title sign on the back wall.
	B.sign({
		Name = "TitleSign",
		Size = { 38, 4.6, 0.6 },
		Position = { 0, 18, wallZ - 0.4 },
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Title",
		TextColor = "NeonPink",
		Glow = true,
	})
	-- Back bar: cabinet, shelves and bottles.
	local shelfZ = wallZ - 1.2
	B.part({
		Name = "BackCabinet",
		Size = { 34, 4, 2.4 },
		Position = { 0, 2, shelfZ },
		Color = "RustDark",
		Material = "Wood",
	})
	for row, y in { 6.5, 9.5, 12.5 } do
		B.part({
			Name = "Shelf",
			Size = { 34, 0.3, 1.6 },
			Position = { 0, y, wallZ - 0.8 },
			Color = "Wood",
			Material = "Wood",
		})
		for index = 1, 11 do
			local colors = { "Bottle", "Amber", "Glass", "NeonTeal" }
			B.part({
				Name = "Bottle",
				Size = { 1.4, 0.55, 0.55 },
				Position = { -15 + (index - 1) * 3, y + 0.85, wallZ - 0.8 },
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
	local counterZ = wallZ - 8
	B.part({
		Name = "CounterBase",
		Size = { 34, 3.5, 3 },
		Position = { 0, 1.75, counterZ },
		Color = "RustDark",
		Material = "WoodPlanks",
		Tags = { "ShopCounter" },
	})
	B.part({
		Name = "CounterTop",
		Size = { 35, 0.4, 4 },
		Position = { 0, 3.7, counterZ },
		Color = "Wood",
		Material = "Wood",
	})
	B.part({
		Name = "FootRail",
		Size = { 34, 0.35, 0.35 },
		Position = { 0, 0.7, counterZ - 2 },
		Rotation = { 0, 0, 0 },
		Shape = "Cylinder",
		Color = "Brass",
		Material = "Metal",
		CanCollide = false,
	})
	B.sign({
		Name = "ShopSign",
		Size = { 9, 2, 0.2 },
		Position = { 0, 1.9, counterZ - 1.6 },
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Shop",
		TextColor = "NeonOrange",
		Glow = true,
	})
	for index, x in { -14, -8.4, -2.8, 2.8, 8.4, 14 } do
		B.part({
			Name = `StoolPole{index}`,
			Size = { 0.6, 2.4, 0.6 },
			Position = { x, 1.2, counterZ - 4 },
			Color = "Metal",
			Material = "Metal",
		})
		B.part({
			Name = `StoolSeat{index}`,
			Size = { 0.5, 2.2, 2.2 },
			Position = { x, 2.65, counterZ - 4 },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Leather",
			Material = "Fabric",
		})
	end

	-- Map vote TVs hang over the bar; mode vote TVs stand on the counter ends.
	for index, x in { -12, 0, 12 } do
		tv(`MapTV{index}`, { x, 12, counterZ }, { 8, 6.5, 5 }, "Map", index)
		B.part({
			Name = "TVMount",
			Size = { 0.4, HEIGHT - 15.25, 0.4 },
			Position = { x, (HEIGHT + 15.25) / 2, counterZ },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
	end
	for index, x in { -15, 15 } do
		tv(`ModeTV{index}`, { x, 5.9, counterZ }, { 5, 4, 4 }, "Mode", index)
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

	for _, x in { -12, 0, 12 } do
		lamp({ x, 16.5, counterZ - 5 }, "WarmLight", 26)
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
end

local function locker()
	local x, z = -HALF_X + 6.5, 16
	B.model("Locker", function()
		B.part({ Name = "Back", Size = { 1, 10, 12 }, Position = { x - 5.5, 5, z }, Color = "Teal" })
		for _, side in { -1, 1 } do
			B.part({ Name = "Side", Size = { 10, 10, 1 }, Position = { x, 5, z + side * 6 }, Color = "Teal" })
		end
		B.part({ Name = "Top", Size = { 12, 1, 14 }, Position = { x, 10.5, z }, Color = "TealDark" })
		for index = 1, 5 do
			B.part({
				Name = "LockerDoor",
				Size = { 1.6, 7, 2 },
				Position = { x - 4.2, 3.5, z + (index - 3) * 2.2 },
				Color = if index % 2 == 0 then "Metal" else "MetalDark",
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
	local x, z = -HALF_X + 2.5, 0
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

local function questBoard()
	local x, z = -HALF_X + 0.7, -16
	B.model("QuestBoard", function()
		B.part({
			Name = "Board",
			Size = { 0.6, 7, 12 },
			Position = { x, 6.5, z },
			Color = "Cork",
			Material = "Fabric",
		})
		for index, note in { { -3.5, 1.5 }, { 0, 2 }, { 3.6, 1.2 }, { -2, -1.6 }, { 2.4, -1.8 }, { 4.6, -0.8 } } do
			B.part({
				Name = `Note{index}`,
				Size = { 0.1, 1.8, 1.5 },
				Position = { x + 0.35, 6.5 + note[2], z + note[1] },
				Rotation = { index * 7 - 20, 0, 0 },
				Color = "OffWhite",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
		B.sign({
			Name = "QuestSign",
			Size = { 10, 2, 0.4 },
			Position = { x + 0.4, 11.2, z },
			Rotation = B.yaw("East"),
			Color = "RustOrange",
			Material = "Metal",
			Key = "Lobby.Sign.Quests",
			TextColor = "OffWhite",
		})
	end):AddTag("QuestBoard")
end

-- Leaderboard screens hung on the south wall, facing the room.
local function leaderboards()
	local z = -HALF_Z + 0.5
	for index, board in
		{
			{ x = -26, stat = "Wins" },
			{ x = -6, stat = "KOs" },
			{ x = 14, stat = "Level" },
		}
	do
		B.model(`Leaderboard{board.stat}`, function()
			B.part({
				Name = "Frame",
				Size = { 17, 11, 1 },
				Position = { board.x, 12, z },
				Color = "RustOrange",
				Material = "CorrodedMetal",
			})
			B.part({
				Name = "Screen",
				Size = { 15.5, 8, 0.2 },
				Position = { board.x, 11.2, z + 0.6 },
				Rotation = B.yaw("North"),
				Color = "Black",
				Material = "SmoothPlastic",
				Tags = { "LeaderboardScreen" },
				Attributes = { Stat = board.stat, Order = index },
			})
			B.sign({
				Name = "Title",
				Size = { 15.5, 2, 0.2 },
				Position = { board.x, 16.3, z + 0.6 },
				Rotation = B.yaw("North"),
				Color = "Black",
				Material = "SmoothPlastic",
				Key = `Lobby.Sign.Leaderboard.{board.stat}`,
				TextColor = "NeonOrange",
				Glow = true,
			})
		end, { Stat = board.stat }):AddTag("Leaderboard")
	end
end

local function spawns()
	for index, x in { -10, 0, 10 } do
		B.spawnLocation({
			Name = `LobbySpawn{index}`,
			Size = { 6, 1, 6 },
			Position = { x, 0.5, -HALF_Z + 12 },
			Rotation = B.yaw("North"), -- players spawn facing the bar
			Color = "Teal",
			Material = "SmoothPlastic",
			Tags = { "LobbySpawn" },
		})
	end
	-- The street door the crew comes in through (decor).
	B.part({
		Name = "StreetDoor",
		Size = { 7, 10, 0.4 },
		Position = { 34, 5, -HALF_Z + 0.2 },
		Color = "TealDark",
		Material = "Metal",
	})
	B.part({
		Name = "StreetDoorLight",
		Size = { 1.6, 0.6, 0.8 },
		Position = { 34, 11, -HALF_Z + 0.4 },
		Color = "LaneYellow",
		Material = "Neon",
		CanCollide = false,
	})
end

local function booth(name: string, x: number, z: number)
	B.model(name, function()
		B.part({ Name = "Table", Size = { 6, 0.4, 3.4 }, Position = { x, 3, z }, Color = "Wood", Material = "Wood" })
		B.part({ Name = "TableLeg", Size = { 0.6, 3, 0.6 }, Position = { x, 1.5, z }, Color = "MetalDark" })
		for _, side in { -1, 1 } do
			local benchZ = z + side * 3
			B.part({
				Name = "Seat",
				Size = { 7, 1.4, 2.2 },
				Position = { x, 0.7, benchZ },
				Color = "Leather",
				Material = "Fabric",
			})
			B.part({
				Name = "Back",
				Size = { 7, 3.6, 0.8 },
				Position = { x, 2.6, benchZ + side * 1.2 },
				Color = "Leather",
				Material = "Fabric",
			})
		end
	end)
end

local function lounge()
	-- Pool table with its own lamp.
	local poolX, poolZ = -22, -4
	B.model("PoolTable", function()
		B.part({
			Name = "Body",
			Size = { 14, 2.8, 8 },
			Position = { poolX, 1.4, poolZ },
			Color = "RustDark",
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
	lamp({ poolX, 12, poolZ }, "WarmLight", 22)

	-- High tables between the spawn and the bar.
	for index, spot in { { 4, 2 }, { 16, 10 }, { 14, -8 } } do
		B.model(`HighTable{index}`, function()
			B.part({
				Name = "Top",
				Size = { 0.3, 3.2, 3.2 },
				Position = { spot[1], 3.8, spot[2] },
				Rotation = { 0, 0, 90 },
				Shape = "Cylinder",
				Color = "Wood",
				Material = "Wood",
			})
			B.part({
				Name = "Pole",
				Size = { 0.5, 3.7, 0.5 },
				Position = { spot[1], 1.85, spot[2] },
				Color = "MetalDark",
				Material = "Metal",
			})
		end)
	end
	lamp({ 10, 14, 1 }, "WarmLight", 26)

	booth("BoothWest", -34, HALF_Z - 6)
	booth("BoothEast", 32, HALF_Z - 6)
	lamp({ -34, 13, HALF_Z - 6 }, "WarmLight", 20)
	lamp({ 32, 13, HALF_Z - 6 }, "WarmLight", 20)
	lamp({ 0, 15, -HALF_Z + 12 }, "WarmLight", 26)

	-- Crates and barrels: the hideout's junk.
	for index, crate in
		{
			{ -HALF_X + 3, -HALF_Z + 3, 4 },
			{ -HALF_X + 7.5, -HALF_Z + 2.5, 3 },
			{ -HALF_X + 3.5, -HALF_Z + 3, 2.5, 4 },
			{ HALF_X - 3, -HALF_Z + 3, 4 },
			{ HALF_X - 3, -HALF_Z + 7.5, 3 },
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
	for index, z in { PAD_SIZE[2] / 2 + 5, -PAD_SIZE[2] / 2 - 5 } do
		B.part({
			Name = `Barrel{index}`,
			Size = { 4, 2.6, 2.6 },
			Position = { HALF_X - 2, 2, z },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = if index == 1 then "RustOrange" else "Teal",
			Material = "CorrodedMetal",
		})
	end
	-- Dartboard on the east wall.
	B.part({
		Name = "Dartboard",
		Size = { 0.3, 2.6, 2.6 },
		Position = { HALF_X - 0.15, 7, 24 },
		Shape = "Cylinder",
		Color = "Black",
		Material = "SmoothPlastic",
		CanCollide = false,
	})
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

-- The join pad's footprint (X, Z) and centre, for specs.
Layout.JoinPad = { Size = PAD_SIZE, Center = { PAD_X, 0 } }

return Layout
