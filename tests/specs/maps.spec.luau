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
local Shinjuku = require("../../maps/layouts/Shinjuku")
local Arena = require("../../maps/lib/Arena")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local MoverRules = Roblox.require(Roblox.game.ReplicatedStorage.Shared.MoverRules)

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

-- Every arena in the rotation (the vote offers only the enabled ones), built at the origin.
local arenas = {
	{ Layout = BrokenHighway, Model = BrokenHighway.build(ORIGIN) },
	{ Layout = JunkyardIsles, Model = JunkyardIsles.build(ORIGIN) },
	{ Layout = NeonMotel, Model = NeonMotel.build(ORIGIN) },
	{ Layout = Shinjuku, Model = Shinjuku.build(ORIGIN) },
}
local lobby = Hideout.build(Config.Maps.LobbyOrigin)

local function eachArena(check: (layout: any, model: any) -> ())
	for _, arena in arenas do
		check(arena.Layout, arena.Model)
	end
end

-- Only the floating arenas (platforms over a void), not a ground arena like Shinjuku (one district on the ground).
local function eachFloating(check: (layout: any, model: any) -> ())
	for _, arena in arenas do
		if not arena.Layout.Ground then
			check(arena.Layout, arena.Model)
		end
	end
end

-- A part's world-axis bounding box (corners of its rotated box), with its name.
local function boxOf(part: any): { min: { number }, max: { number }, name: string, part: any }
	local cframe, size = part.CFrame, part.Size
	local min = { math.huge, math.huge, math.huge }
	local max = { -math.huge, -math.huge, -math.huge }
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = cframe * roblox.Vector3.new(sx * size.X / 2, sy * size.Y / 2, sz * size.Z / 2)
				local values = { corner.X, corner.Y, corner.Z }
				for axis = 1, 3 do
					min[axis] = math.min(min[axis], values[axis])
					max[axis] = math.max(max[axis], values[axis])
				end
			end
		end
	end
	return { min = min, max = max, name = part:GetFullName(), part = part }
end

-- Whether the axis-aligned box `a` and the part box `b` overlap by more than a hair (touching faces don't count): their
-- world-axis boxes first, then exactly by separating axes, so a long diagonal road doesn't count as covering its whole
-- bounding rectangle.
local function overlaps(a: any, b: any): boolean
	for axis = 1, 3 do
		if a.max[axis] <= b.min[axis] + 0.05 or b.max[axis] <= a.min[axis] + 0.05 then
			return false
		end
	end
	local Vector3 = roblox.Vector3
	local center = Vector3.new((a.min[1] + a.max[1]) / 2, (a.min[2] + a.max[2]) / 2, (a.min[3] + a.max[3]) / 2)
	local half = Vector3.new((a.max[1] - a.min[1]) / 2, (a.max[2] - a.min[2]) / 2, (a.max[3] - a.min[3]) / 2)
	local cframe, size = b.part.CFrame, b.part.Size / 2
	local partAxes = { cframe.RightVector, cframe.UpVector, cframe.LookVector }
	local worldAxes = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis }
	local offset = cframe.Position - center
	local function separated(axis: any): boolean
		if axis.Magnitude < 1e-6 then
			return false
		end
		local unit = axis.Unit
		local reachA = half.X * math.abs(unit.X) + half.Y * math.abs(unit.Y) + half.Z * math.abs(unit.Z)
		local reachB = size.X * math.abs(unit:Dot(partAxes[1]))
			+ size.Y * math.abs(unit:Dot(partAxes[2]))
			+ size.Z * math.abs(unit:Dot(partAxes[3]))
		return math.abs(offset:Dot(unit)) >= reachA + reachB - 0.05
	end
	for _, axis in worldAxes do
		if separated(axis) then
			return false
		end
	end
	for _, axis in partAxes do
		if separated(axis) then
			return false
		end
	end
	for _, worldAxis in worldAxes do
		for _, partAxis in partAxes do
			if separated(worldAxis:Cross(partAxis)) then
				return false
			end
		end
	end
	return true
end

-- Every solid part in an arena (it collides), but not the gameplay markers or a mover's invisible pivot.
local function solidBoxes(model: any): { any }
	local boxes = {}
	for _, part in model:GetDescendants() do
		if
			part:IsA("BasePart")
			and part.CanCollide
			and not part:HasTag("SpawnPoint")
			and not part:HasTag("PropSpot")
			and not part:HasTag("ExplosiveSpot")
			and not part:HasTag("StructureSpot")
			and part.Name ~= "Pivot"
		then
			table.insert(boxes, boxOf(part))
		end
	end
	return boxes
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
	["Shinjuku is the only arena in the vote; the old three stay built and in the place, switched off"] = function()
		-- The owner, 2026-10-28: "only one arena instead of the 3 old arenas, just store them somewhere, don't delete it".
		local enabled = {}
		for _, mapId in Config.Maps.Rotation do
			if Config.Maps.List[mapId].Enabled then
				table.insert(enabled, mapId)
			end
		end
		expect.equal(#enabled, 1, "enabled arenas")
		expect.equal(enabled[1], "Shinjuku")
		local project = fs.readFile("default.project.json")
		for _, mapId in { "BrokenHighway", "JunkyardIsles", "NeonMotel" } do
			expect.truthy(table.find(Config.Maps.Rotation, mapId), `{mapId} stays in the rotation list`)
			expect.truthy(fs.isFile(`maps/generated/{mapId}.rbxmx`), `{mapId} stays built`)
			expect.truthy(string.find(project, `maps/generated/{mapId}.rbxmx`, 1, true), `{mapId} stays in the place`)
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
	["broken highway: platform sizes (4× the first arena: doubled 2026-10-17 and again 2026-10-20)"] = function()
		local sizes = {
			Center = { 240, 160 },
			Side = { 96, 96 },
			Ledge = { 48, 48 },
			Peak = { 40, 40 },
			Low = { 56, 56 },
		}
		for _, platform in BrokenHighway.Platforms do
			local expectedSize = sizes[platform.Kind]
			expect.equal(platform.Size[1], expectedSize[1], `{platform.Id} X`)
			expect.equal(platform.Size[2], expectedSize[2], `{platform.Id} Z`)
		end
	end,
	["floating arenas: one centre, four sides, four ledges, two peaks, two lows; platforms never overlap"] = function()
		eachFloating(function(layout)
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
	["floating arenas: the centre's raised deck fits on it, is climbable and keeps clear of every spot"] = function()
		eachFloating(function(layout)
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
			-- A ground arena also has spots for the props that belong somewhere (trash cans, chairs: TypedProps).
			local props = #tagged(model, "PropSpot")
			if layout.Ground then
				expect.truthy(props >= 24 and props <= Config.Props.MaxActive, `{layout.Id}: {props} prop spots`)
			else
				expect.equal(props, 24, `{layout.Id} loose prop spots`)
			end
			expect.equal(#tagged(model, "StructureSpot"), 8, `{layout.Id} breakable structures`)
			expect.equal(#tagged(model, "ExplosiveSpot"), 6, `{layout.Id} explosive barrel spots`)
			expect.equal(#tagged(model, "Platform"), if layout.Ground then 1 else 13, `{layout.Id} platforms`)
		end)
	end,
	["Shinjuku: one district on the ground, open edges to fall off, no school strip"] = function()
		-- The owner, 2026-10-28: "no floating island", then "want arena to look like jjk shenanigans", then "shrink the
		-- arena by delete entire school area. remove tower boundary so player can fall dead".
		expect.equal(Shinjuku.Ground, true, "a ground arena")
		expect.equal(#Shinjuku.Platforms, 1, "one platform")
		local district = Shinjuku.Platforms[1]
		expect.equal(district.Kind, "Center", "the district never falls")
		local model = Shinjuku.build(ORIGIN)
		local halfX, halfZ = district.Size[1] / 2, district.Size[2] / 2
		local centerX, centerZ = district.Center[1], district.Center[2]
		-- The district ends at the main street's far pavement: the school, its gym and yard and the shrine are gone.
		expect.equal(centerZ + halfZ, 110, "the north edge (the main street at z 90)")
		expect.equal(centerZ - halfZ, -230, "the south edge")
		for _, name in { "School", "Gym", "Schoolyard", "ShrineHall", "Torii", "Station" } do
			expect.equal(model:FindFirstChild(name, true), nil, `no {name}`)
		end
		-- Nothing closes the edges in (no walls, no city blocks round it) and nothing solid past them or under the
		-- district to land on: knocked off an edge, a fighter falls past KillY (MapService: a KO in a round).
		expect.equal(model:FindFirstChild("BoundaryWall", true), nil, "no boundary walls")
		expect.equal(model:FindFirstChild("Skyline", true), nil, "no city blocks round it")
		local underside = district.Top - district.Thickness
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part.CanCollide then
				local box = boxOf(part)
				local within = box.min[1] >= centerX - halfX - 0.5
					and box.max[1] <= centerX + halfX + 0.5
					and box.min[3] >= centerZ - halfZ - 0.5
					and box.max[3] <= centerZ + halfZ + 0.5
				expect.truthy(within, `{box.name} is solid past the district's edge`)
				expect.truthy(box.min[2] >= underside - 0.01, `{box.name} is solid under the district`)
			end
		end
		expect.truthy(model:GetAttribute("KillY") < underside, "KillY under the district")
		expect.truthy(model:FindFirstChild("Bedrock", true) and model:FindFirstChild("AbyssMist1", true), "a cliff")
		-- The owner's reference (Jujutsu Shenanigans' Shinjuku): the twin towers with their skybridge, ladders up them.
		expect.truthy(
			model:FindFirstChild("TowerWest", true) and model:FindFirstChild("TowerEast", true),
			"twin towers"
		)
		expect.truthy(model:FindFirstChild("Skybridge", true), "skybridge")
		local ladders = 0
		for _, part in model:GetDescendants() do
			if part:IsA("TrussPart") then
				ladders += 1
				expect.equal(part.Size.X, 2, "a truss is 2 wide")
				expect.equal(part.Size.Y % 2, 0, "a truss's height is even")
			end
		end
		expect.truthy(ladders >= 4, `{ladders} ladders`)
		-- The owner, 2026-10-28: "add breakable walls … town structures bigger and can enter". Walls and windows are
		-- BreakableWall pieces: solid, anchored, no wider than Config's limits; buildings you can walk into have
		-- doorways, upper floors and stairs.
		local walls = Config.Structures.Walls
		local breakable = 0
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part:HasTag("BreakableWall") then
				breakable += 1
				expect.truthy(part.CanCollide and part.Anchored, `{part:GetFullName()} solid`)
				local limit = if part.Material == roblox.Enum.Material.Glass then walls.MaxGlass else walls.MaxPiece
				local wide = math.max(part.Size.X, part.Size.Z)
				expect.truthy(wide <= limit + 0.01, `{part:GetFullName()} is {wide} wide (most {limit})`)
			end
		end
		expect.truthy(breakable >= 300, `{breakable} breakable wall pieces`)
		for _, name in
			{
				"TowerWest",
				"TowerEast",
				"Cafe",
				"Ramen",
				"Mart",
				"Arcade",
				"Mall",
				"BowlingAlley",
				"Jail",
				"Courthouse",
				-- The owner, 2026-10-28: "more dimension … also bigger buildings".
				"Pachinko",
				"Karaoke",
				"CarPark",
				"YokochoNorth",
				"YokochoSouth",
				"DeptStore",
				"Hotel",
				"FireStation",
				"ApartmentsNorth",
				"ApartmentsSouth",
				"Temple",
				"Koban",
			}
		do
			local building = model:FindFirstChild(name, true)
			expect.truthy(building, `{name} is built`)
			expect.truthy(building:FindFirstChild("GroundFloor"), `{name} has a floor inside`)
		end
		for _, name in
			{
				"TowerWest",
				"TowerEast",
				"Cafe",
				"Mall",
				"Jail",
				"Shop1",
				"Mansion",
				"Ramen",
				"Karaoke",
				"CarPark",
				"DeptStore",
				"Hotel",
				"ApartmentsSouth",
			}
		do
			local building = model:FindFirstChild(name, true)
			expect.truthy(
				building and building:FindFirstChild("Stair") and building:FindFirstChild("Floor"),
				`{name} has stairs`
			)
		end
		-- "Make structure 10 times more detail" (owner, 2026-10-29): the detail streams in by distance. The Center
		-- platform (Persistent) keeps only its slab and the gameplay markers; the buildings and dressing are in the
		-- District folder, each building streamed whole (Atomic).
		local platform = model:FindFirstChild("Center", true)
		for _, child in platform:GetChildren() do
			expect.truthy(child.Name == "Base" or child:HasTag("Marker"), `{child.Name} is on the persistent platform`)
		end
		local district = model:FindFirstChild("District")
		expect.truthy(district and district.Parent == model, "a District folder at the arena's root")
		for _, name in { "TowerWest", "Hotel", "Ramen" } do
			local building = district:FindFirstChild(name)
			expect.equal(building.ModelStreamingMode, roblox.Enum.ModelStreamingMode.Atomic, `{name} streams whole`)
		end
		-- The plain blocks are rebuilt as detailed furniture (maps/lib/Decor): none is left as one block.
		for _, name in { "Counter", "Shelf", "WallTV", "CoffeeTable", "Toilet", "Bunk", "Stool" } do
			for _, part in district:GetDescendants() do
				expect.truthy(not (part:IsA("BasePart") and part.Name == name), `{part:GetFullName()} is a plain block`)
			end
		end
		local fountain = district:FindFirstChild("Fountain", true)
		expect.truthy(fountain and #fountain:GetChildren() >= 40, "a fountain in many pieces")
		-- "Literally include inside structure too": every building you can walk into has something solid inside it
		-- that isn't its own shell (furniture, counters, partitions, cars), upstairs too when it has floors.
		local furnishings = {}
		for _, part in district:GetDescendants() do
			if
				part:IsA("BasePart")
				and part.CanCollide
				and part.Name ~= "Base"
				and not (part:HasTag("SpawnPoint") or part:HasTag("PropSpot"))
				and not (part:HasTag("ExplosiveSpot") or part:HasTag("StructureSpot"))
			then
				table.insert(furnishings, part)
			end
		end
		local buildings = 0
		for _, building in district:GetChildren() do
			local ground = building:FindFirstChild("GroundFloor")
			if ground then
				buildings += 1
				local floor = boxOf(ground)
				local upstairs = math.huge
				for _, slab in building:GetChildren() do
					if slab.Name == "Floor" then
						upstairs = math.min(upstairs, boxOf(slab).max[2])
					end
				end
				local inside, above = false, false
				for _, part in furnishings do
					local p = part.CFrame.Position
					local within = p.X > floor.min[1]
						and p.X < floor.max[1]
						and p.Z > floor.min[3]
						and p.Z < floor.max[3]
					if within and p.Y > 0 and not part:IsDescendantOf(building) then
						inside = true
						above = above or p.Y > upstairs
					end
				end
				expect.truthy(inside, `{building.Name} is furnished`)
				expect.truthy(upstairs == math.huge or above, `{building.Name} is furnished upstairs`)
			end
		end
		expect.truthy(buildings >= 30, `{buildings} buildings to walk into`)
		-- "Structure and building want to match avatar size" (owner, 2026-10-28): an avatar stands about 5.3 studs, so
		-- every building's ground storey has at least 8.5 of headroom (the first slab above it 9+ up) and every stair
		-- lane is at least 3.5 wide.
		for _, building in district:GetChildren() do
			if building:FindFirstChild("GroundFloor") then
				local lowest = math.huge
				for _, part in building:GetChildren() do
					if part:IsA("BasePart") and (part.Name == "Floor" or part.Name == "Roof") then
						lowest = math.min(lowest, boxOf(part).max[2])
					elseif part:IsA("BasePart") and part.Name == "Stair" then
						expect.truthy(part.Size.X >= 3.5 - 0.01, `{building.Name}'s stair is {part.Size.X} wide`)
					end
				end
				expect.truthy(lowest >= 9 - 0.01, `{building.Name}'s ground storey is {lowest} high`)
			end
		end
		-- "I don't want too much flat area except the fountain area or the road": off the streets (and their
		-- pavements), the plaza and the edge's margin, at most a third of the ground is open (samples every 5; built
		-- up = under a building's floor, a solid part 2+ tall, or a deck overhead).
		local covers, streets = {}, {}
		for _, part in district:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "Base" then
				local box = boxOf(part)
				if part.Name == "GroundFloor" then
					table.insert(covers, box)
				elseif part.Name == "Road" or part.Name == "PlazaPavers" then
					table.insert(streets, box)
				elseif part.CanCollide and part.Transparency < 1 then
					local bottom, top = box.min[2], box.max[2]
					if top - math.max(bottom, 0) >= 2 or (bottom >= 2 and bottom <= 30) then
						table.insert(covers, box)
					end
				end
			end
		end
		local function under(list: { any }, x: number, z: number, pad: number): boolean
			for _, box in list do
				if
					x >= box.min[1] - pad
					and x <= box.max[1] + pad
					and z >= box.min[3] - pad
					and z <= box.max[3] + pad
				then
					return true
				end
			end
			return false
		end
		local open, lots = 0, 0
		for z = centerZ - halfZ + 8, centerZ + halfZ - 10, 5 do
			for x = centerX - halfX + 8, centerX + halfX - 8, 5 do
				if not under(streets, x, z, 6) then
					lots += 1
					if not under(covers, x, z, 1.5) then
						open += 1
					end
				end
			end
		end
		expect.truthy(open <= lots / 3, `{open} of {lots} samples are open flat ground`)
		-- "More dynamic": things that move — the towers' glass lifts (up to the roof's parapet), the site's hoist, the
		-- crane, the Ferris wheel, the carousel, the pachinko sign.
		local kinds = {}
		for _, mover in tagged(model, "Mover") do
			local kind = mover:GetAttribute("Kind")
			kinds[kind] = (kinds[kind] or 0) + 1
		end
		expect.truthy((kinds.Lift or 0) >= 3 and (kinds.Spin or 0) >= 4, "lifts and things that turn")
		local towerTop = boxOf(model:FindFirstChild("TowerWest", true):FindFirstChild("Parapet")).max[2]
		for _, name in { "TowerLift1", "TowerLift2" } do
			local lift = model:FindFirstChild(name, true)
			local floor = boxOf(lift:FindFirstChild("LiftFloor"))
			expect.truthy(floor.max[2] + lift:GetAttribute("Offset").Y >= towerTop - 0.01, `{name} reaches the roof`)
		end
		-- Every spot is at least 10 in from the edge (the spacing checks above cover the rest).
		for _, tag in { "SpawnPoint", "PropSpot", "ExplosiveSpot", "StructureSpot" } do
			for _, marker in tagged(model, tag) do
				local p = marker.CFrame.Position
				local inside = math.abs(p.X - centerX) < halfX - 10 and math.abs(p.Z - centerZ) < halfZ - 10
				expect.truthy(inside, `{marker.Name} inside`)
			end
		end
	end,
	["Shinjuku: framed windows, two-tone faces, base courses and roof caps; the trim breaks with its wall"] = function()
		-- The owner, 2026-10-30: "more detail on buildings, still look blocky".
		local model = Shinjuku.build(ORIGIN)
		local counts: { [string]: number } = {}
		for _, part in model:GetDescendants() do
			if not part:IsA("BasePart") then
				continue
			end
			counts[part.Name] = (counts[part.Name] or 0) + 1
			local carrier = part.Parent
			if part.Name == "Mullion" or part.Name == "Transom" then
				expect.truthy(
					carrier.Name == "Glass" and carrier:HasTag("BreakableWall"),
					`{part:GetFullName()} on glass`
				)
				expect.equal(part.CanCollide, false, `{part:GetFullName()} walk-through`)
			elseif part.Name == "WindowHead" or part.Name == "Plinth" then
				expect.truthy(
					carrier.Name == "Wall" and carrier:HasTag("BreakableWall"),
					`{part:GetFullName()} on a wall`
				)
				expect.equal(part.CanCollide, false, `{part:GetFullName()} walk-through`)
			elseif
				part.Name == "Glass"
				and carrier:FindFirstChild("GroundFloor") -- a walk-in building's window (maps/lib/Rooms)
				and math.max(part.Size.X, part.Size.Z) >= 4.5
			then
				expect.truthy(part:FindFirstChild("Mullion") ~= nil, `{part:GetFullName()} has glazing bars`)
			end
		end
		for name, least in { Mullion = 500, WindowHead = 400, Plinth = 400, Coping = 80 } do
			expect.truthy((counts[name] or 0) >= least, `{counts[name] or 0} {name} parts (at least {least})`)
		end
		-- Two-tone faces: a tower's walls come in its colour and its darker spandrels.
		local colors: { [string]: boolean } = {}
		local kinds = 0
		for _, part in model:FindFirstChild("TowerWest", true):GetChildren() do
			if part.Name == "Wall" and not colors[part.Color:ToHex()] then
				colors[part.Color:ToHex()] = true
				kinds += 1
			end
		end
		expect.truthy(kinds >= 2, `the west tower's walls have {kinds} colour(s)`)
	end,
	["floating arenas: one explosive spot per side and low platform"] = function()
		eachFloating(function(layout)
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
				local spots: { { x: number, y: number, z: number, radius: number, name: string } } = {}
				local function add(spot: { number }, radius: number, name: string)
					local halfX, halfZ = platform.Size[1] / 2, platform.Size[2] / 2
					expect.truthy(math.abs(spot[1]) <= halfX - 1.5, `{where} {name} X inside`)
					expect.truthy(math.abs(spot[2]) <= halfZ - 1.5, `{where} {name} Z inside`)
					table.insert(spots, { x = spot[1], y = spot[3] or 0, z = spot[2], radius = radius, name = name })
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
				for index, spot in contents.Explosives or {} do
					add(spot, 1.5, `explosive {index}`)
				end
				for index, typed in contents.TypedProps or {} do
					expect.truthy(Config.Props.Types[typed.Type], `{where} typed prop {index}: {typed.Type}`)
					add(typed.At, 1.5, `{typed.Type} {index}`)
				end
				for index, structure in contents.Structures or {} do
					add(structure.At, 4, `structure {index}`)
				end
				for i = 1, #spots do
					for j = i + 1, #spots do
						local a, b = spots[i], spots[j]
						local distance = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
						-- Spots on different floors (a roof over a street) don't crowd each other.
						local clear = distance >= a.radius + b.radius or math.abs(a.y - b.y) > 4
						expect.truthy(clear, `{where}: {a.name} too close to {b.name}`)
					end
				end
			end
		end)
	end,
	["arenas: nothing solid stands on a spawn, prop, barrel or structure spot"] = function()
		eachArena(function(layout, model)
			local solids = solidBoxes(model)
			for _, tag in { "SpawnPoint", "PropSpot", "ExplosiveSpot", "StructureSpot" } do
				for _, marker in tagged(model, tag) do
					local position = marker.CFrame.Position
					local floor = position.Y - marker.Size.Y / 2
					local half = { 1.5, 1.5 }
					if tag == "StructureSpot" then
						local size = Config.Structures.Types[marker:GetAttribute("StructureType")].Size
						local radius = math.max(size.X, size.Z) / 2 + 0.3
						half = { radius, radius }
					end
					local column = {
						min = { position.X - half[1], floor + 0.05, position.Z - half[2] },
						max = { position.X + half[1], floor + 6, position.Z + half[2] },
					}
					for _, solid in solids do
						expect.truthy(
							not overlaps(column, solid),
							`{layout.Id} {marker.Parent.Name} {marker.Name} is blocked by {solid.name}`
						)
					end
				end
			end
		end)
	end,
	["arenas: bridges join neighbours in two halves, one on each platform, some short, some long, at a walkable slope"] = function()
		eachArena(function(layout, model)
			local bridges = layout.Bridges
			if bridges == nil then
				return
			end
			local byId: { [string]: any } = {}
			for _, platform in layout.Platforms do
				byId[platform.Id] = platform
			end
			local short, long = 0, 0
			for _, bridge in bridges do
				local name = `{bridge[1]}-{bridge[2]}`
				local a, b = byId[bridge[1]], byId[bridge[2]]
				expect.truthy(a and b, `{name} platforms`)
				for _, platform in { a, b } do
					local halves = 0
					for _, part in model.Platforms[platform.Id]:GetDescendants() do
						if part:GetAttribute("Bridge") == name then
							halves += 1
						end
					end
					expect.equal(halves, 1, `{name}: one half on {platform.Id} (it crumbles with it)`)
				end
				local fromA, fromB = Arena.bridgeEnds(a, b, bridge.Along)
				local run = math.sqrt((fromA[1] - fromB[1]) ^ 2 + (fromA[3] - fromB[3]) ^ 2)
				local rise = math.abs(fromA[2] - fromB[2])
				expect.truthy(run > 1, `{name} spans its gap`)
				expect.truthy(math.deg(math.atan2(rise, run)) <= 35, `{name} slope`)
				if run <= 16 then
					short += 1
				elseif run >= 30 then
					long += 1
				end
			end
			-- The owner: "some short, some long, some gaps, not too boring".
			expect.truthy(short >= 2 and long >= 1, `{layout.Id}: a mix of short and long bridges`)
			expect.truthy(#bridges <= 8, `{layout.Id}: not too many bridges (gaps stay)`)
		end)
	end,
	["arenas: movers have a pivot and valid settings; a lift or slide never runs into anything"] = function()
		eachArena(function(layout, model)
			local movers = tagged(model, "Mover")
			if layout.Id == "BrokenHighway" then
				expect.truthy(#movers >= 3, "Broken Highway has its lift, slide and swing")
			end
			local solids = solidBoxes(model)
			for _, mover in movers do
				local where = `{layout.Id} {mover.Name}`
				expect.truthy(mover.PrimaryPart and mover.PrimaryPart.Name == "Pivot", `{where} pivot`)
				expect.equal(mover.ModelStreamingMode, roblox.Enum.ModelStreamingMode.Persistent, `{where} streaming`)
				local kind = mover:GetAttribute("Kind")
				expect.truthy(table.find(MoverRules.Kinds, kind), `{where} kind`)
				expect.truthy((mover:GetAttribute("Period") or 0) > 0, `{where} period`)
				for _, part in mover:GetDescendants() do
					if part:IsA("BasePart") and part:HasTag("Hazard") then
						expect.equal(kind, "Swing", `{where}: only swings are hazards`)
					end
				end
				if kind == "Lift" or kind == "Slide" then
					local offset = mover:GetAttribute("Offset")
					expect.equal(typeof(offset), "Vector3", `{where} offset`)
					-- The box it sweeps on its way (start and end), against everything solid that isn't itself.
					for _, part in mover:GetDescendants() do
						if part:IsA("BasePart") and part.CanCollide then
							local box = boxOf(part)
							local swept = {
								min = {
									math.min(box.min[1], box.min[1] + offset.X),
									math.min(box.min[2], box.min[2] + offset.Y),
									math.min(box.min[3], box.min[3] + offset.Z),
								},
								max = {
									math.max(box.max[1], box.max[1] + offset.X),
									math.max(box.max[2], box.max[2] + offset.Y),
									math.max(box.max[3], box.max[3] + offset.Z),
								},
							}
							for _, solid in solids do
								if not solid.part:IsDescendantOf(mover) then
									expect.truthy(not overlaps(swept, solid), `{where} runs into {solid.name}`)
								end
							end
						end
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
	["lobby: interactive objects and spawns exist; no Training Yard, locker booth or codes jukebox"] = function()
		for _, tag in { "ShopNPC", "ShopCounter", "StyleNPC", "QuestBoard", "ArenaDoor" } do
			expect.equal(#tagged(lobby, tag), 1, tag)
		end
		for _, tag in { "TrainingYard", "TrainingDummySpot", "TrainingPropSpot", "TrainingStart", "TrainingDashGoal" } do
			expect.equal(#tagged(lobby, tag), 0, tag)
		end
		-- The owner swapped them for the style coach and a decor jukebox (2026-10-27).
		for _, tag in { "Locker", "CodesJukebox" } do
			expect.equal(#tagged(lobby, tag), 0, tag)
		end
		expect.truthy(#tagged(lobby, "LobbySpawn") >= 1, "lobby spawns")
	end,
	["lobby: the style coach's spot stands on the floor by the jukebox, facing the room"] = function()
		local npc = tagged(lobby, "StyleNPC")[1]
		local spot = npc:FindFirstChild("Spot")
		expect.truthy(spot and spot:IsA("BasePart"), "Spot")
		expect.truthy(npc:FindFirstChild("Torso"), "Torso (the Styles prompt's part)")
		expect.truthy(
			math.abs(spot.CFrame.Position.Y - spot.Size.Y / 2 - Config.Maps.LobbyOrigin[2]) < 0.01,
			"on the floor"
		)
		-- The owner: "move style npc to near music box" (2026-10-27).
		local origin = Config.Maps.LobbyOrigin
		local position, look = spot.CFrame.Position, spot.CFrame.LookVector
		local toCentre = { origin[1] - position.X, origin[3] - position.Z }
		expect.truthy(look.X * toCentre[1] + look.Z * toCentre[2] > 0, "faces the room")
		local jukebox = lobby:FindFirstChild("Jukebox")
		local body = jukebox and jukebox:FindFirstChild("Body")
		expect.truthy(body, "the jukebox")
		local gap = body.CFrame.Position - position
		expect.truthy(math.sqrt(gap.X * gap.X + gap.Z * gap.Z) < 10, "next to the jukebox")
		for _, part in npc:GetDescendants() do
			if part:IsA("BasePart") then
				expect.equal(part.Transparency, 1, `{part.Name} is an invisible anchor`)
			end
		end
	end,
	["lobby: the bartender's spot stands on the bar's raised floor behind the counter, facing the room"] = function()
		local npc = tagged(lobby, "ShopNPC")[1]
		local counter = tagged(lobby, "ShopCounter")[1]
		local spot = npc:FindFirstChild("Spot")
		expect.truthy(spot and spot:IsA("BasePart"), "Spot")
		expect.truthy(npc:FindFirstChild("Torso"), "Torso (the Shop prompt's part)")
		expect.truthy(
			math.abs(spot.CFrame.Position.Y - spot.Size.Y / 2 - Config.Maps.LobbyOrigin[2] - Hideout.BarRise) < 0.01,
			"on the bar's floor"
		)
		expect.truthy(spot.CFrame.LookVector.Z < -0.99, "faces the room (south)")
		local back = counter.CFrame.Position.Z + counter.Size.Z / 2
		expect.truthy(spot.CFrame.Position.Z - spot.Size.Z / 2 > back, "behind the counter")
		for _, part in npc:GetDescendants() do
			if part:IsA("BasePart") then
				expect.equal(part.Transparency, 1, `{part.Name} is an invisible anchor`)
			end
		end
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
	["lobby: one invisible, walk-through spawn in the middle of the room, facing the bar"] = function()
		-- The owner, 2026-10-27: "set player spawn in center, no blue plate below".
		local spawns = tagged(lobby, "LobbySpawn")
		expect.equal(#spawns, 1, "lobby spawns")
		local spawn = spawns[1]
		expect.equal(spawn.Transparency, 1, "invisible")
		expect.equal(spawn.CanCollide, false, "walk-through")
		local origin = Config.Maps.LobbyOrigin
		local position = spawn.CFrame.Position
		expect.near(position.X, origin[1], 0.001, "centre (X)")
		expect.near(position.Z, origin[3], 0.001, "centre (Z)")
		expect.truthy(spawn.CFrame.LookVector.Z > 0.99, "faces the bar (+Z)")
	end,
	["lobby: enclosed (four walls and a ceiling)"] = function()
		for _, name in { "NorthWall", "SouthWall", "LeftWall", "RightWall", "Ceiling" } do
			expect.truthy(lobby:FindFirstChild(name, true), name)
		end
	end,
	["lobby: 3 map vote screens (Classic is the only mode) and 2 news TVs"] = function()
		local maps = 0
		for _, screen in tagged(lobby, "VoteScreen") do
			expect.equal(screen:GetAttribute("VoteKind"), "Map")
			maps += 1
		end
		expect.equal(maps, Config.Maps.VoteChoices)
		expect.equal(#tagged(lobby, "NewsScreen"), 2)
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
	["lobby: 15% smaller than 115 × 85 (98 × 72; the owner, 2026-10-27)"] = function()
		expect.equal(Hideout.Inner[1], 98)
		expect.equal(Hideout.Inner[2], 72)
		local north = lobby:FindFirstChild("NorthWall", true)
		expect.near(north.Size.X, Hideout.Inner[1] + 4, 0.001, "north wall spans the room")
	end,
	["lobby: seats are upright, untouchable LobbySeat Seats inside the room, off the join pad"] = function()
		local seats = tagged(lobby, "LobbySeat")
		expect.truthy(#seats >= 20, `{#seats} seats`)
		local origin = Config.Maps.LobbyOrigin
		local pad = Hideout.JoinPad
		for _, seat in seats do
			expect.equal(seat.ClassName, "Seat", seat.Name)
			expect.equal(seat.CanTouch, false, `{seat.Name} sits people down on touch`)
			expect.near(seat.CFrame.UpVector.Y, 1, 0.001, `{seat.Name} is not upright`)
			local x, z = seat.CFrame.Position.X - origin[1], seat.CFrame.Position.Z - origin[3]
			expect.truthy(
				math.abs(x) < Hideout.Inner[1] / 2 and math.abs(z) < Hideout.Inner[2] / 2,
				`{seat.Name} outside`
			)
			local onPad = math.abs(x - pad.Center[1]) < pad.Size[1] / 2
				and math.abs(z - pad.Center[2]) < pad.Size[2] / 2
			expect.equal(onPad, false, `{seat.Name} on the join pad`)
		end
	end,
	["lobby: one arm-wrestling table, its two seats facing each other across it"] = function()
		local tables = tagged(lobby, "ArmWrestleTable")
		expect.equal(#tables, 1, "arm-wrestling tables")
		local model = tables[1]
		local top = model:FindFirstChild("Top")
		expect.truthy(top and top:IsA("BasePart"), "Top")
		local seats: { [number]: any } = {}
		for _, seat in tagged(model, "ArmWrestleSeat") do
			expect.equal(seat.ClassName, "Seat", seat.Name)
			expect.truthy(seat:HasTag("LobbySeat"), "a lobby seat too (the Sit prompt)")
			seats[seat:GetAttribute("Side")] = seat
		end
		expect.equal(#tagged(model, "ArmWrestleSeat"), 2, "two seats")
		local one, two = seats[1], seats[2]
		expect.truthy(one and two, "sides 1 and 2")
		local centre = top.CFrame.Position
		expect.near(centre.X - Config.Maps.LobbyOrigin[1], Hideout.ArmWrestle[1], 0.001, "table x")
		expect.near(centre.Z - Config.Maps.LobbyOrigin[3], Hideout.ArmWrestle[2], 0.001, "table z")
		expect.truthy(one.CFrame.Position.X < centre.X and two.CFrame.Position.X > centre.X, "side 1 west, side 2 east")
		expect.truthy(one.CFrame.LookVector.X > 0.99, "side 1 faces the table")
		expect.truthy(two.CFrame.LookVector.X < -0.99, "side 2 faces the table")
		-- The seat sits lower than the table top, by about a seated elbow's height.
		local seatTop = one.CFrame.Position.Y + one.Size.Y / 2
		local tableTop = centre.Y + top.Size.Y / 2
		expect.truthy(
			tableTop - seatTop > 0.8 and tableTop - seatTop < 1.6,
			`table {tableTop - seatTop} above the seat`
		)
	end,
	["lobby: one chess table: 64 squares in the board, two seats facing each other"] = function()
		local tables = tagged(lobby, "ChessTable")
		expect.equal(#tables, 1, "chess tables")
		local model = tables[1]
		local board = model:FindFirstChild("Board")
		expect.truthy(board and board:IsA("BasePart"), "Board")
		local size = board:GetAttribute("SquareSize")
		expect.truthy(type(size) == "number" and size > 0, "SquareSize")
		expect.near(board.CFrame.Position.X - Config.Maps.LobbyOrigin[1], Hideout.Chess[1], 0.001, "table x")
		expect.near(board.CFrame.Position.Z - Config.Maps.LobbyOrigin[3], Hideout.Chess[2], 0.001, "table z")
		-- Every square where the client puts its piece: a1 dark, at White's left (−Z) nearest White (−X).
		local squares = 0
		for _, square in model:GetChildren() do
			if square.Name == "Square" then
				squares += 1
				local offset = board.CFrame:PointToObjectSpace(square.CFrame.Position)
				local rank, file = offset.X / size + 3.5, offset.Z / size + 3.5
				expect.near(rank, math.round(rank), 0.001, "on a rank")
				expect.near(file, math.round(file), 0.001, "on a file")
				local dark = (math.round(rank) + math.round(file)) % 2 == 0
				expect.equal(square.Color.R < 0.75, dark, `square {math.round(file)},{math.round(rank)} shade`)
			end
		end
		expect.equal(squares, 64, "squares")
		local seats: { [number]: any } = {}
		for _, seat in tagged(model, "ChessSeat") do
			expect.truthy(seat:HasTag("LobbySeat"), "a lobby seat too (the Sit prompt)")
			seats[seat:GetAttribute("Side")] = seat
		end
		expect.equal(#tagged(model, "ChessSeat"), 2, "two seats")
		expect.truthy(seats[1].CFrame.Position.X < board.CFrame.Position.X, "White sits west")
		expect.truthy(seats[1].CFrame.LookVector.X > 0.99, "White faces the board")
		expect.truthy(seats[2].CFrame.LookVector.X < -0.99, "Black faces the board")
	end,
	["lobby: the bar end is a raised platform with easy steps up from the concrete"] = function()
		-- The owner, 2026-10-28: "more dimension".
		local origin = Config.Maps.LobbyOrigin
		local platform = lobby:FindFirstChild("BarPlatform")
		expect.truthy(platform and platform.CanCollide, "a solid platform")
		local top = platform.CFrame.Position.Y + platform.Size.Y / 2 - origin[2]
		expect.near(top, Hideout.BarRise, 0.001, "its top")
		expect.near(platform.CFrame.Position.Z - platform.Size.Z / 2 - origin[3], Hideout.BarEdge, 0.001, "its front")
		local heights = { 0 }
		for _, step in lobby:GetChildren() do
			if step.Name == "BarStep" then
				expect.truthy(step.CanCollide, "a solid step")
				table.insert(heights, step.CFrame.Position.Y + step.Size.Y / 2 - origin[2])
			end
		end
		table.insert(heights, top)
		table.sort(heights)
		expect.truthy(#heights >= 3, "steps up")
		for index = 2, #heights do
			expect.truthy(heights[index] - heights[index - 1] <= 0.6, `a step of {heights[index] - heights[index - 1]}`)
		end
	end,
	["lobby: green ceiling lamps over the concrete; ceiling fans that spin and touch nothing"] = function()
		local origin = Config.Maps.LobbyOrigin
		local overConcrete = 0
		for _, lamp in lobby:GetChildren() do
			if lamp.Name == "CeilingLamp" then
				local bulb = lamp:FindFirstChild("Bulb")
				local light = bulb and bulb:FindFirstChildOfClass("PointLight")
				expect.truthy(light, "a lit bulb")
				if bulb.CFrame.Position.Z - origin[3] < Hideout.BarEdge then
					overConcrete += 1
				end
			end
		end
		expect.truthy(overConcrete >= 4, `{overConcrete} ceiling lamps over the concrete`)
		local fans = 0
		for _, mover in tagged(lobby, "Mover") do
			fans += 1
			expect.equal(mover:GetAttribute("Kind"), "Spin", `{mover.Name} kind`)
			expect.truthy((mover:GetAttribute("Period") or 0) > 0, `{mover.Name} period`)
			expect.truthy(mover.PrimaryPart and mover.PrimaryPart.Name == "Pivot", `{mover.Name} pivot`)
			for _, part in mover:GetDescendants() do
				if part:IsA("BasePart") then
					expect.equal(part.CanCollide, false, `{mover.Name} {part.Name} collides`)
					-- High enough that nobody's head reaches it.
					expect.truthy(part.CFrame.Position.Y - origin[2] > 15, `{mover.Name} {part.Name} hangs low`)
				end
			end
		end
		expect.truthy(fans >= 1, "ceiling fans")
	end,
	["lobby: a few main lamps cast shadows (Future lighting), all tagged for Low Graphics"] = function()
		local shadows = 0
		for _, light in lobby:GetDescendants() do
			if light:IsA("Light") and light.Shadows then
				shadows += 1
				expect.truthy(light:HasTag("ShadowLight"), `{light:GetFullName()} casts shadows but isn't tagged`)
			end
		end
		expect.truthy(shadows >= 1 and shadows <= 12, `{shadows} shadow-casting lights (keep it to the main lamps)`)
	end,
	["lobby: KillY sits below the floor"] = function()
		expect.equal(lobby:GetAttribute("KillY"), Config.Maps.LobbyOrigin[2] - 40)
	end,
}
