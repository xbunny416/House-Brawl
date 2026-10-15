--!strict
-- Map layouts match the bible's numbers, and the committed .rbxmx files match the layouts.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Roblox = require("../roblox")
local expect = require("../expect")

local BrokenHighway = require("../../maps/layouts/BrokenHighway")
local RustDiner = require("../../maps/layouts/RustDiner")

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

local arena = BrokenHighway.build(ORIGIN)
local lobby = RustDiner.build(Config.Maps.LobbyOrigin)

return {
	["generated .rbxmx files are up to date (run: lune run maps/build)"] = function()
		local expected = {
			["maps/generated/BrokenHighway.rbxmx"] = BrokenHighway.build(Config.Maps.ArenaOrigin),
			["maps/generated/RustDiner.rbxmx"] = lobby,
		}
		for path, model in expected do
			expect.truthy(fs.isFile(path), `{path} exists`)
			expect.equal(fs.readFile(path) == roblox.serializeModel({ model }, true), true, path)
		end
	end,
	["broken highway: platform sizes from the bible"] = function()
		local counts = { Center = 0, Side = 0, Ledge = 0 }
		for _, platform in BrokenHighway.Platforms do
			counts[platform.Kind] += 1
			local expectedSize = if platform.Kind == "Center"
				then { 60, 40 }
				elseif platform.Kind == "Side" then { 24, 24 }
				else { 12, 12 }
			expect.equal(platform.Size[1], expectedSize[1], `{platform.Id} X`)
			expect.equal(platform.Size[2], expectedSize[2], `{platform.Id} Z`)
		end
		expect.equal(counts.Center, 1)
		expect.equal(counts.Side, 4)
		expect.equal(counts.Ledge, 2)
	end,
	["broken highway: every outer platform is 8-14 studs from its nearest neighbour"] = function()
		for _, platform in BrokenHighway.Platforms do
			if platform.Kind ~= "Center" then
				local nearest = math.huge
				for _, other in BrokenHighway.Platforms do
					if other ~= platform then
						nearest = math.min(nearest, gap(platform, other))
					end
				end
				expect.truthy(nearest >= 8 and nearest <= 14, `{platform.Id} nearest gap {nearest}`)
			end
		end
	end,
	["broken highway: marker counts"] = function()
		expect.equal(#tagged(arena, "SpawnPoint"), 12, "spawn points")
		expect.equal(#tagged(arena, "PropSpot"), 14, "loose prop spots")
		expect.equal(#tagged(arena, "StructureSpot"), 4, "breakable structures")
		expect.equal(#tagged(arena, "ExplosiveSpot"), 4, "explosive barrel spots")
		expect.equal(#tagged(arena, "Platform"), 7, "platforms")
	end,
	["broken highway: one explosive spot per side platform"] = function()
		for _, platform in BrokenHighway.Platforms do
			local contents = BrokenHighway.Contents[platform.Id]
			local hasExplosive = contents ~= nil and contents.Explosive ~= nil
			expect.equal(hasExplosive, platform.Kind == "Side", platform.Id)
		end
	end,
	["broken highway: structure types exist in Config"] = function()
		for _, marker in tagged(arena, "StructureSpot") do
			local structureType = marker:GetAttribute("StructureType")
			expect.truthy(Config.Structures.Types[structureType], `structure {structureType}`)
		end
	end,
	["broken highway: spots sit inside their platform and do not crowd each other"] = function()
		for platformId, contents in BrokenHighway.Contents do
			local platform
			for _, candidate in BrokenHighway.Platforms do
				if candidate.Id == platformId then
					platform = candidate
				end
			end
			expect.truthy(platform, `platform {platformId}`)
			local spots: { { x: number, z: number, radius: number, name: string } } = {}
			local function add(spot: { number }, radius: number, name: string)
				local halfX, halfZ = platform.Size[1] / 2, platform.Size[2] / 2
				expect.truthy(math.abs(spot[1]) <= halfX - 1.5, `{platformId} {name} X inside`)
				expect.truthy(math.abs(spot[2]) <= halfZ - 1.5, `{platformId} {name} Z inside`)
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
					expect.truthy(distance >= a.radius + b.radius, `{platformId}: {a.name} too close to {b.name}`)
				end
			end
		end
	end,
	["broken highway: KillY is 60 studs below the lowest platform; centre never falls"] = function()
		expect.equal(BrokenHighway.killY(), -2 - 3 - 60)
		expect.equal(arena:GetAttribute("KillY"), BrokenHighway.killY())
		for _, platform in tagged(arena, "Platform") do
			expect.equal(platform:GetAttribute("CanFall"), platform.Name ~= "Center", platform.Name)
			expect.equal(platform.ModelStreamingMode, roblox.Enum.ModelStreamingMode.Persistent, platform.Name)
			expect.truthy(platform.PrimaryPart, `{platform.Name} PrimaryPart`)
		end
	end,
	["lobby: interactive objects and markers exist"] = function()
		for _, tag in { "ShopNPC", "ShopCounter", "Locker", "CodesJukebox", "QuestBoard", "TrainingYard" } do
			expect.equal(#tagged(lobby, tag), 1, tag)
		end
		for _, tag in { "TrainingDummySpot", "TrainingPropSpot", "TrainingStart", "TrainingDashGoal" } do
			expect.equal(#tagged(lobby, tag), 1, tag)
		end
		expect.truthy(#tagged(lobby, "LobbySpawn") >= 1, "lobby spawns")
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
	["lobby: KillY sits below the roof"] = function()
		expect.equal(lobby:GetAttribute("KillY"), Config.Maps.LobbyOrigin[2] - 40)
	end,
}
