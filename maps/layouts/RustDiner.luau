--!strict
--[[
	Lobby: "Rust Diner" rooftop (bible §3.2).

	North: diner counter with the Shop NPC, map/mode vote CRT TVs, neon "JUNKYARD BRAWL" sign.
	West: Locker booth, Codes jukebox. East: Quest board. South-west: leaderboard billboards.
	South-east: Training Yard — ramp, a ledge with the dummy to shove off, a dash gap, a chair spot.
	Interactive objects carry CollectionService tags so later steps can attach prompts and UI.
]]
local B = require("../lib/Builder")

local Layout = {}

Layout.Id = "RustDiner"
Layout.Lighting = "Dusk"

local ROOF = { 140, 110 } -- X, Z
local HALF_X, HALF_Z = ROOF[1] / 2, ROOF[2] / 2
local KILL_DEPTH = 40 -- falling this far below the roof returns you to a spawn

local function roof()
	B.slab({
		Name = "Roof",
		Size = { ROOF[1], 4, ROOF[2] },
		Position = { 0, 0, 0 },
		Color = "ConcreteDark",
		Material = "Concrete",
		CastShadow = true,
	})
	B.part({
		Name = "Building",
		Size = { ROOF[1] - 2, 60, ROOF[2] - 2 },
		Position = { 0, -34, 0 },
		Color = "DustyPink",
		Material = "Brick",
		CastShadow = true,
	})
	for index = 1, 6 do
		B.part({
			Name = "Window",
			Size = { 12, 7, 0.4 },
			Position = { -60 + index * 20 - 10, -14, -HALF_Z + 0.8 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.3,
		})
	end
	-- Parapet with a neon trim, plus invisible walls so nobody falls off the lobby.
	local sides = {
		{ size = { ROOF[1], 2.5, 1.5 }, pos = { 0, 1.25, HALF_Z - 0.75 } },
		{ size = { ROOF[1], 2.5, 1.5 }, pos = { 0, 1.25, -HALF_Z + 0.75 } },
		{ size = { 1.5, 2.5, ROOF[2] }, pos = { HALF_X - 0.75, 1.25, 0 } },
		{ size = { 1.5, 2.5, ROOF[2] }, pos = { -HALF_X + 0.75, 1.25, 0 } },
	}
	for index, side in sides do
		B.part({
			Name = "Parapet",
			Size = side.size,
			Position = side.pos,
			Color = "RustOrange",
			Material = "CorrodedMetal",
		})
		B.part({
			Name = "ParapetTrim",
			Size = { side.size[1], 0.3, side.size[3] },
			Position = { side.pos[1], 2.65, side.pos[3] },
			Color = if index % 2 == 0 then "NeonTeal" else "NeonPink",
			Material = "Neon",
			CanCollide = false,
		})
		B.part({
			Name = "SafetyWall",
			Size = { side.size[1], 20, side.size[3] },
			Position = { side.pos[1], 12.5, side.pos[3] },
			Color = "OffWhite",
			Transparency = 1,
			CastShadow = false,
		})
	end
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

local function diner()
	local wallZ = HALF_Z - 5
	B.part({
		Name = "BackWall",
		Size = { 44, 14, 2 },
		Position = { 0, 7, wallZ },
		Color = "PinkDark",
		Material = "Brick",
		CastShadow = true,
	})
	-- Neon title sign with a tube border.
	B.sign({
		Name = "TitleSign",
		Size = { 46, 8, 1 },
		Position = { 0, 18, wallZ },
		Color = "Black",
		Material = "SmoothPlastic",
		Key = "Lobby.Sign.Title",
		TextColor = "NeonPink",
		Glow = true,
	})
	for _, tube in
		{
			{ size = { 46, 0.4, 0.4 }, pos = { 0, 22.2, wallZ - 0.6 }, color = "NeonTeal" },
			{ size = { 46, 0.4, 0.4 }, pos = { 0, 13.8, wallZ - 0.6 }, color = "NeonTeal" },
			{ size = { 0.4, 8.8, 0.4 }, pos = { -23.2, 18, wallZ - 0.6 }, color = "NeonPink" },
			{ size = { 0.4, 8.8, 0.4 }, pos = { 23.2, 18, wallZ - 0.6 }, color = "NeonPink" },
		}
	do
		B.part({
			Name = "NeonTube",
			Size = tube.size,
			Position = tube.pos,
			Color = tube.color,
			Material = "Neon",
			CanCollide = false,
		})
	end

	-- Map vote TVs on the wall, mode vote TVs on the counter ends.
	for index, x in { -14, 0, 14 } do
		tv(`MapTV{index}`, { x, 9.5, wallZ - 3.5 }, { 8, 6.5, 5 }, "Map", index)
	end

	local counterZ = wallZ - 10
	B.part({
		Name = "CounterBase",
		Size = { 32, 3.5, 4 },
		Position = { 0, 1.75, counterZ },
		Color = "Teal",
		Material = "SmoothPlastic",
		Tags = { "ShopCounter" },
	})
	B.part({
		Name = "CounterTop",
		Size = { 33, 0.5, 5 },
		Position = { 0, 3.75, counterZ },
		Color = "OffWhite",
		Material = "Marble",
	})
	for index, x in { -18, 18 } do
		tv(`ModeTV{index}`, { x, 6, counterZ }, { 5, 4, 4 }, "Mode", index)
	end
	for index, x in { -15, -9, -3, 3, 9, 15 } do
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
			Color = "RustOrange",
			Material = "SmoothPlastic",
		})
	end
	B.sign({
		Name = "ShopSign",
		Size = { 8, 2, 0.4 },
		Position = { 0, 8.6, counterZ - 1 },
		Color = "RustOrange",
		Material = "Metal",
		Key = "Lobby.Sign.Shop",
		TextColor = "OffWhite",
	})

	-- Placeholder Shop NPC (the scavenger mechanic) behind the counter.
	local npcZ = counterZ + 4
	B.model("ShopNPC", function()
		for _, x in { -0.55, 0.55 } do
			B.part({ Name = "Leg", Size = { 1, 2.6, 1 }, Position = { x, 1.3, npcZ }, Color = "TealDark" })
		end
		B.part({ Name = "Torso", Size = { 2.4, 2.6, 1.2 }, Position = { 0, 3.9, npcZ }, Color = "RustOrange" })
		for _, x in { -1.6, 1.6 } do
			B.part({ Name = "Arm", Size = { 0.8, 2.4, 0.8 }, Position = { x, 3.9, npcZ }, Color = "OffWhite" })
		end
		B.part({
			Name = "Head",
			Size = { 1.6, 1.6, 1.6 },
			Position = { 0, 6.05, npcZ },
			Shape = "Ball",
			Color = "DustyPink",
		})
		B.part({ Name = "Cap", Size = { 1.8, 0.5, 1.8 }, Position = { 0, 6.9, npcZ }, Color = "Teal" })
	end, { Role = "Shop" }):AddTag("ShopNPC")
end

local function locker()
	local x, z = -HALF_X + 7, 22
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
	local x, z = -HALF_X + 6, -8
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
	local x, z = HALF_X - 6, 22
	B.model("QuestBoard", function()
		for _, side in { -1, 1 } do
			B.part({
				Name = "Post",
				Size = { 1, 10, 1 },
				Position = { x, 5, z + side * 6.5 },
				Color = "Wood",
				Material = "Wood",
			})
		end
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
				Position = { x - 0.35, 6.5 + note[2], z + note[1] },
				Rotation = { index * 7 - 20, 0, 0 },
				Color = "OffWhite",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
		B.sign({
			Name = "QuestSign",
			Size = { 10, 2, 0.4 },
			Position = { x, 11.2, z },
			Rotation = B.yaw("West"),
			Color = "RustOrange",
			Material = "Metal",
			Key = "Lobby.Sign.Quests",
			TextColor = "OffWhite",
		})
	end):AddTag("QuestBoard")
end

local function leaderboards()
	local z = -HALF_Z + 7
	for index, board in
		{
			{ x = -52, stat = "Wins" },
			{ x = -32, stat = "KOs" },
			{ x = -12, stat = "Level" },
		}
	do
		B.model(`Leaderboard{board.stat}`, function()
			for _, side in { -1, 1 } do
				B.part({
					Name = "Post",
					Size = { 1, 9, 1 },
					Position = { board.x + side * 6.5, 4.5, z },
					Color = "Metal",
					Material = "Metal",
				})
			end
			B.part({
				Name = "Frame",
				Size = { 17, 11, 1 },
				Position = { board.x, 14, z + 0.3 },
				Color = "RustOrange",
				Material = "CorrodedMetal",
			})
			B.part({
				Name = "Screen",
				Size = { 15.5, 8, 0.2 },
				Position = { board.x, 13.2, z - 0.3 },
				Rotation = B.yaw("North"),
				Color = "Black",
				Material = "SmoothPlastic",
				Tags = { "LeaderboardScreen" },
				Attributes = { Stat = board.stat, Order = index },
			})
			B.sign({
				Name = "Title",
				Size = { 15.5, 2, 0.2 },
				Position = { board.x, 18.3, z - 0.3 },
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

local function trainingYard()
	local yardZ = -25
	B.model("TrainingYard", function()
		B.part({
			Name = "YardFloor",
			Size = { 54, 0.2, 40 },
			Position = { 41, 0.1, -30 },
			Color = "TealDark",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		-- Ramp rising east onto ledge A (top 8).
		B.part({
			Name = "Ramp",
			Size = { 10, 8, 14 },
			Position = { 25, 4, yardZ },
			Rotation = { 0, 90, 0 },
			Shape = "Wedge",
			Color = "RustOrange",
			Material = "DiamondPlate",
		})
		local function ledge(name: string, centerX: number, sizeX: number, sizeZ: number)
			B.slab({
				Name = name,
				Size = { sizeX, 2, sizeZ },
				Position = { centerX, 8, yardZ },
				Color = "RustOrange",
				Material = "DiamondPlate",
				CastShadow = true,
			})
			for _, corner in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
				B.part({
					Name = "Leg",
					Size = { 1, 6, 1 },
					Position = { centerX + corner[1] * (sizeX / 2 - 1), 3, yardZ + corner[2] * (sizeZ / 2 - 1) },
					Color = "MetalDark",
					Material = "Metal",
				})
			end
		end
		ledge("LedgeA", 40, 16, 16) -- x 32..48
		ledge("LedgeB", 62, 8, 10) -- x 58..66: a 10-stud gap to practise dashing
		B.marker("TrainingDummySpot", "DummySpot", { 44, 8, yardZ - 6 }, nil, B.yaw("North"))
		B.marker("TrainingPropSpot", "ChairSpot", { 36, 8, yardZ + 5 }, { PropType = "Chair" })
		B.marker("TrainingStart", "StartSpot", { 18, 0, yardZ })
		B.marker("TrainingDashGoal", "DashGoal", { 62, 8, yardZ })
		B.part({
			Name = "SignPost",
			Size = { 0.8, 11, 0.8 },
			Position = { 20, 5.5, -9 },
			Color = "Metal",
			Material = "Metal",
		})
		B.sign({
			Name = "TrainingSign",
			Size = { 14, 3, 0.4 },
			Position = { 20, 12, -9 },
			Rotation = B.yaw("North"),
			Color = "TealDark",
			Material = "Metal",
			Key = "Lobby.Sign.TrainingYard",
			TextColor = "OffWhite",
		})
	end):AddTag("TrainingYard")
end

local function spawns()
	for index, x in { -10, 0, 10 } do
		B.spawnLocation({
			Name = `LobbySpawn{index}`,
			Size = { 6, 1, 6 },
			Position = { x, 0.5, -12 },
			Rotation = B.yaw("North"), -- players spawn facing the diner counter
			Color = "Teal",
			Material = "SmoothPlastic",
			Tags = { "LobbySpawn" },
		})
	end
end

local function decor()
	-- Water tower (north-west corner).
	local towerX, towerZ = -HALF_X + 12, HALF_Z - 12
	for _, corner in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
		B.part({
			Name = "TowerLeg",
			Size = { 1, 14, 1 },
			Position = { towerX + corner[1] * 4, 7, towerZ + corner[2] * 4 },
			Color = "MetalDark",
			Material = "Metal",
		})
	end
	B.part({
		Name = "TowerTank",
		Size = { 10, 11, 11 },
		Position = { towerX, 19, towerZ },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "RustOrange",
		Material = "CorrodedMetal",
		CastShadow = true,
	})
	-- AC units (north-east).
	for index = 1, 3 do
		local x = HALF_X - 10 - (index - 1) * 8
		B.part({
			Name = "ACUnit",
			Size = { 6, 3.5, 5 },
			Position = { x, 1.75, HALF_Z - 8 },
			Color = "Metal",
			Material = "DiamondPlate",
		})
		B.part({
			Name = "ACFan",
			Size = { 0.3, 3.6, 3.6 },
			Position = { x, 3.6, HALF_Z - 8 },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "MetalDark",
			Material = "Metal",
		})
	end
	-- Junk pile near the locker.
	for index, junk in { { -58, 1.25, 4, 2.5 }, { -55, 1, 2, 2 }, { -60.5, 3.5, 2.5, 2 } } do
		B.part({
			Name = `Junk{index}`,
			Size = { junk[4], junk[4], junk[4] },
			Position = { junk[1], junk[2], junk[3] },
			Rotation = { 0, index * 31, 0 },
			Color = if index == 2 then "Teal" else "Wood",
			Material = if index == 2 then "CorrodedMetal" else "WoodPlanks",
		})
	end
end

-- Builds the lobby at `origin` (world position of the roof's top centre).
function Layout.build(origin: { number }): any
	return B.root("Lobby", function()
		B.within(origin, function()
			roof()
			diner()
			locker()
			jukebox()
			questBoard()
			leaderboards()
			trainingYard()
			spawns()
			decor()
		end)
	end, {
		MapId = Layout.Id,
		Lighting = Layout.Lighting,
		KillY = origin[2] - KILL_DEPTH,
	})
end

return Layout
