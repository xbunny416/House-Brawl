--!strict
-- Map layouts match the bible's numbers and the shared arena rules, and the committed .rbxmx files match the layouts.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Roblox = require("../roblox")
local expect = require("../expect")

local BrokenHighway = require("../../maps/layouts/BrokenHighway")
local Hideout = require("../../maps/layouts/Hideout")
local JunkyardIsles = require("../../maps/layouts/JunkyardIsles")
local NeonMotel = require("../../maps/layouts/NeonMotel")
local Arena = require("../../maps/lib/Arena")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)

local ORIGIN = { 0, 0, 0 }

local function tagged(root: any, tag: string): { any }
	local found = {}
	for _, instance in root:GetDescendants() do
		if instance:HasTag(tag) then
			table.insert(found, instance)
		end
	end
	return found
end

-- Horizontal gap between two platform footprints (0 if they overlap).
local function gap(a: any, b: any): number
	local dx = math.max(0, math.abs(a.Center[1] - b.Center[1]) - (a.Size[1] + b.Size[1]) / 2)
	local dz = math.max(0, math.abs(a.Center[2] - b.Center[2]) - (a.Size[2] + b.Size[2]) / 2)
	return math.sqrt(dx * dx + dz * dz)
end

-- Every arena in the vote rotation, built at the origin.
local arenas = {
	{ Layout = BrokenHighway, Model = BrokenHighway.build(ORIGIN) },
	{ Layout = JunkyardIsles, Model = JunkyardIsles.build(ORIGIN) },
	{ Layout = NeonMotel, Model = NeonMotel.build(ORIGIN) },
}
local lobby = Hideout.build(Config.Maps.LobbyOrigin)

local function eachArena(check: (layout: any, model: any) -> ())
	for _, arena in arenas do
		check(arena.Layout, arena.Model)
	end
end

return {
	["generated .rbxmx files are up to date (run: lune run maps/build)"] = function()
		local expected = {
			["maps/generated/Hideout.rbxmx"] = lobby,
		}
		for _, arena in arenas do
			expected[`maps/generated/{arena.Layout.Id}.rbxmx`] = arena.Layout.build(Config.Maps.ArenaOrigin)
		end
		for path, model in expected do
			expect.truthy(fs.isFile(path), `{path} exists`)
			expect.equal(fs.readFile(path) == roblox.serializeModel({ model }, true), true, path)
		end
	end,
	["every map in the rotation has a layout and its configured lighting"] = function()
		for _, mapId in Config.Maps.Rotation do
			local found = nil
			for _, arena in arenas do
				if arena.Layout.Id == mapId then
					found = arena
				end
			end
			expect.truthy(found, `{mapId} layout`)
			expect.equal(found.Layout.Lighting, Config.Maps.List[mapId].Lighting, `{mapId} lighting`)
			expect.truthy(Config.Lighting[found.Layout.Lighting], `{mapId} lighting preset`)
			expect.equal(found.Model:GetAttribute("MapId"), mapId)
		end
	end,
	["broken highway: platform sizes from the bible (twice the first arena)"] = function()
		local sizes = {
			Center = { 120, 80 },
			Side = { 48, 48 },
			Ledge = { 24, 24 },
			Peak = { 20, 20 },
			Low = { 28, 28 },
		}
		for _, platform in BrokenHighway.Platforms do
			local expectedSize = sizes[platform.Kind]
			expect.equal(platform.Size[1], expectedSize[1], `{platform.Id} X`)
			expect.equal(platform.Size[2], expectedSize[2], `{platform.Id} Z`)
		end
	end,
	["arenas: one centre, four sides, four ledges, two peaks, two lows; platforms never overlap"] = function()
		eachArena(function(layout)
			local counts = { Center = 0, Side = 0, Ledge = 0, Peak = 0, Low = 0 }
			for index, platform in layout.Platforms do
				counts[platform.Kind] += 1
				for other = index + 1, #layout.Platforms do
					local second = layout.Platforms[other]
					expect.truthy(gap(platform, second) > 0, `{layout.Id}: {platform.Id} overlaps {second.Id}`)
				end
			end
			for kind, count in { Center = 1, Side = 4, Ledge = 4, Peak = 2, Low = 2 } do
				expect.equal(counts[kind], count, `{layout.Id} {kind} platforms`)
			end
		end)
	end,
	["arenas: every outer platform is 8-14 studs from its nearest neighbour"] = function()
		eachArena(function(layout)
			for _, platform in layout.Platforms do
				if platform.Kind ~= "Center" then
					local nearest = math.huge
					for _, other in layout.Platforms do
						if other ~= platform then
							nearest = math.min(nearest, gap(platform, other))
						end
					end
					expect.truthy(nearest >= 8 and nearest <= 14, `{layout.Id} {platform.Id} nearest gap {nearest}`)
				end
			end
		end)
	end,
	["arenas: four layers — lows below, sides level, ledges (≤ 6 up) and peaks above"] = function()
		local bands = {
			Center = { 0, 0 },
			Side = { -3, 3 },
			Ledge = { 4, 6 },
			Peak = { 10, 12 },
			Low = { -9, -4 },
		}
		eachArena(function(layout)
			for _, platform in layout.Platforms do
				local band = bands[platform.Kind]
				local where = `{layout.Id} {platform.Id} top {platform.Top}`
				expect.truthy(platform.Top >= band[1] and platform.Top <= band[2], where)
			end
		end)
	end,
	["arenas: every platform can be reached from the centre and back (gaps ≤ 14, climbs ≤ 6)"] = function()
		eachArena(function(layout)
			local center
			for _, platform in layout.Platforms do
				if platform.Kind == "Center" then
					center = platform
				end
			end
			local reached = { [center] = true }
			local queue = { center }
			while #queue > 0 do
				local from = table.remove(queue, 1)
				for _, to in layout.Platforms do
					if not reached[to] and gap(from, to) <= 14 and math.abs(to.Top - from.Top) <= 6 then
						reached[to] = true
						table.insert(queue, to)
					end
				end
			end
			for _, platform in layout.Platforms do
				expect.truthy(reached[platform], `{layout.Id} {platform.Id} can't be reached`)
			end
		end)
	end,
	["arenas: the centre's raised deck fits on it, is climbable and keeps clear of every spot"] = function()
		eachArena(function(layout)
			for _, platform in layout.Platforms do
				local deck = platform.Deck
				expect.equal(deck ~= nil, platform.Kind == "Center", `{layout.Id} {platform.Id} deck`)
				if deck then
					expect.truthy(deck.Height <= 6, `{layout.Id} deck height`)
					local bounds = Arena.deckBounds(deck)
					local halfX, halfZ = platform.Size[1] / 2, platform.Size[2] / 2
					expect.truthy(bounds[1] >= -halfX + 2 and bounds[2] <= halfX - 2, `{layout.Id} deck X fits`)
					expect.truthy(bounds[3] >= -halfZ + 2 and bounds[4] <= halfZ - 2, `{layout.Id} deck Z fits`)
					local contents = layout.Contents[platform.Id] or {}
					local spots: { { number } } = {}
					for _, list in { contents.Spawns or {}, contents.Props or {} } do
						for _, spot in list do
							table.insert(spots, spot)
						end
					end
					for _, structure in contents.Structures or {} do
						table.insert(spots, structure.At)
					end
					for _, spot in spots do
						local clear = spot[1] < bounds[1] - 1.5
							or spot[1] > bounds[2] + 1.5
							or spot[2] < bounds[3] - 1.5
							or spot[2] > bounds[4] + 1.5
						expect.truthy(clear, `{layout.Id}: spot {spot[1]}, {spot[2]} is on the deck`)
					end
				end
			end
		end)
	end,
	["arenas: marker counts"] = function()
		eachArena(function(layout, model)
			expect.equal(#tagged(model, "SpawnPoint"), 16, `{layout.Id} spawn points`)
			expect.truthy(#tagged(model, "SpawnPoint") >= Config.World.MaxPlayers, `{layout.Id} a spawn per player`)
			expect.equal(#tagged(model, "PropSpot"), 24, `{layout.Id} loose prop spots`)
			expect.equal(#tagged(model, "StructureSpot"), 8, `{layout.Id} breakable structures`)
			expect.equal(#tagged(model, "ExplosiveSpot"), 6, `{layout.Id} explosive barrel spots`)
			expect.equal(#tagged(model, "Platform"), 13, `{layout.Id} platforms`)
		end)
	end,
	["arenas: one explosive spot per side and low platform"] = function()
		eachArena(function(layout)
			for _, platform in layout.Platforms do
				local contents = layout.Contents[platform.Id]
				local hasExplosive = contents ~= nil and contents.Explosive ~= nil
				local expected = platform.Kind == "Side" or platform.Kind == "Low"
				expect.equal(hasExplosive, expected, `{layout.Id} {platform.Id}`)
			end
		end)
	end,
	["arenas: structure types exist in Config"] = function()
		eachArena(function(layout, model)
			for _, marker in tagged(model, "StructureSpot") do
				local structureType = marker:GetAttribute("StructureType")
				expect.truthy(Config.Structures.Types[structureType], `{layout.Id} structure {structureType}`)
			end
		end)
	end,
	["arenas: spots sit inside their platform and do not crowd each other"] = function()
		eachArena(function(layout)
			for platformId, contents in layout.Contents do
				local platform
				for _, candidate in layout.Platforms do
					if candidate.Id == platformId then
						platform = candidate
					end
				end
				expect.truthy(platform, `{layout.Id} platform {platformId}`)
				local where = `{layout.Id} {platformId}`
				local spots: { { x: number, z: number, radius: number, name: string } } = {}
				local function add(spot: { number }, radius: number, name: string)
					local halfX, halfZ = platform.Size[1] / 2, platform.Size[2] / 2
					expect.truthy(math.abs(spot[1]) <= halfX - 1.5, `{where} {name} X inside`)
					expect.truthy(math.abs(spot[2]) <= halfZ - 1.5, `{where} {name} Z inside`)
					table.insert(spots, { x = spot[1], z = spot[2], radius = radius, name = name })
				end
				for index, spot in contents.Spawns or {} do
					add(spot, 1.5, `spawn {index}`)
				end
				for index, spot in contents.Props or {} do
					add(spot, 1.5, `prop {index}`)
				end
				if contents.Explosive then
					add(contents.Explosive, 1.5, "explosive")
				end
				for index, structure in contents.Structures or {} do
					add(structure.At, 4, `structure {index}`)
				end
				for i = 1, #spots do
					for j = i + 1, #spots do
						local a, b = spots[i], spots[j]
						local distance = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
						expect.truthy(distance >= a.radius + b.radius, `{where}: {a.name} too close to {b.name}`)
					end
				end
			end
		end)
	end,
	["arenas: KillY is 60 studs below the lowest platform; centre never falls"] = function()
		expect.equal(BrokenHighway.killY(), -6 - 3 - 60) -- the West low slab
		eachArena(function(layout, model)
			local lowest = math.huge
			for _, platform in layout.Platforms do
				lowest = math.min(lowest, platform.Top - platform.Thickness)
			end
			expect.equal(layout.killY(), lowest - 60, `{layout.Id} KillY`)
			expect.equal(model:GetAttribute("KillY"), layout.killY(), `{layout.Id} KillY attribute`)
			for _, platform in tagged(model, "Platform") do
				local name = `{layout.Id} {platform.Name}`
				expect.equal(platform:GetAttribute("CanFall"), platform.Name ~= "Center", name)
				expect.equal(platform.ModelStreamingMode, roblox.Enum.ModelStreamingMode.Persistent, name)
				expect.truthy(platform.PrimaryPart, `{name} PrimaryPart`)
			end
		end)
	end,
	["arenas: markers ride on their platform (they fall with it)"] = function()
		eachArena(function(layout, model)
			for _, tag in { "SpawnPoint", "PropSpot", "ExplosiveSpot", "StructureSpot" } do
				for _, marker in tagged(model, tag) do
					local node = marker.Parent
					while node and not node:HasTag("Platform") do
						node = node.Parent
					end
					expect.truthy(node, `{layout.Id} {marker.Name} is not on a platform`)
				end
			end
		end)
	end,
	["lobby: interactive objects and spawns exist; no Training Yard"] = function()
		for _, tag in { "ShopNPC", "ShopCounter", "Locker", "CodesJukebox", "QuestBoard", "ArenaDoor" } do
			expect.equal(#tagged(lobby, tag), 1, tag)
		end
		for _, tag in { "TrainingYard", "TrainingDummySpot", "TrainingPropSpot", "TrainingStart", "TrainingDashGoal" } do
			expect.equal(#tagged(lobby, tag), 0, tag)
		end
		expect.truthy(#tagged(lobby, "LobbySpawn") >= 1, "lobby spawns")
	end,
	["lobby: one visible, walk-through join pad, away from the spawns"] = function()
		local pads = tagged(lobby, "QueueZone")
		expect.equal(#pads, 1, "join pads")
		local pad = pads[1]
		expect.equal(pad:HasTag("Marker"), false, "not hidden at runtime")
		expect.equal(pad.CanCollide, false, "walk-through")
		expect.truthy(pad.Transparency < 1, "visible")
		expect.equal(pad.Size.X, Hideout.JoinPad.Size[1])
		expect.equal(pad.Size.Z, Hideout.JoinPad.Size[2])
		for _, spawn in tagged(lobby, "LobbySpawn") do
			local offset = spawn.CFrame.Position - pad.CFrame.Position
			local outside = math.abs(offset.X) > (pad.Size.X + spawn.Size.X) / 2
				or math.abs(offset.Z) > (pad.Size.Z + spawn.Size.Z) / 2
			expect.truthy(outside, `{spawn.Name} is on the join pad`)
		end
	end,
	["lobby: enclosed (four walls and a ceiling)"] = function()
		for _, name in { "NorthWall", "SouthWall", "EastWall", "WestWall", "Ceiling" } do
			expect.truthy(lobby:FindFirstChild(name, true), name)
		end
	end,
	["lobby: 3 map and 2 mode vote screens"] = function()
		local counts = { Map = 0, Mode = 0 }
		for _, screen in tagged(lobby, "VoteScreen") do
			counts[screen:GetAttribute("VoteKind")] += 1
		end
		expect.equal(counts.Map, Config.Maps.VoteChoices)
		expect.equal(counts.Mode, #Config.Modes.Order)
	end,
	["lobby: one leaderboard per leaderboard stat"] = function()
		local stats = {}
		for _, board in tagged(lobby, "Leaderboard") do
			stats[board:GetAttribute("Stat")] = true
		end
		for _, stat in Config.Retention.Leaderboards.Stats do
			expect.truthy(stats[stat], `leaderboard {stat}`)
		end
	end,
	["lobby: KillY sits below the floor"] = function()
		expect.equal(lobby:GetAttribute("KillY"), Config.Maps.LobbyOrigin[2] - 40)
	end,
}
