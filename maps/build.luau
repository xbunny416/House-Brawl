--!strict
--[[
	Generates the blockout map models from the layouts in maps/layouts.
	  lune run maps/build           writes maps/generated/*.rbxmx (commit them; Rojo syncs them into the place)
	  lune run maps/build --check   exits 1 if the committed files are out of date
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Shim = require("../tests/roblox")
local BrokenHighway = require("./layouts/BrokenHighway")
local JunkyardIsles = require("./layouts/JunkyardIsles")
local NeonMotel = require("./layouts/NeonMotel")
local Shinjuku = require("./layouts/Shinjuku")
local Hideout = require("./layouts/Hideout")

local Config = Shim.require(Shim.game.ReplicatedStorage.Shared.Config)

local OUTPUT_DIR = "maps/generated"

local function outputs(): { { file: string, model: any } }
	return {
		{ file = "Hideout.rbxmx", model = Hideout.build(Config.Maps.LobbyOrigin) },
		{ file = "BrokenHighway.rbxmx", model = BrokenHighway.build(Config.Maps.ArenaOrigin) },
		{ file = "JunkyardIsles.rbxmx", model = JunkyardIsles.build(Config.Maps.ArenaOrigin) },
		{ file = "NeonMotel.rbxmx", model = NeonMotel.build(Config.Maps.ArenaOrigin) },
		{ file = "Shinjuku.rbxmx", model = Shinjuku.build(Config.Maps.ArenaOrigin) },
	}
end

local function serialize(model: any): string
	return roblox.serializeModel({ model }, true)
end

local check = table.find(process.args, "--check") ~= nil
local stale: { string } = {}

for _, output in outputs() do
	local path = `{OUTPUT_DIR}/{output.file}`
	local content = serialize(output.model)
	if check then
		if not fs.isFile(path) or fs.readFile(path) ~= content then
			table.insert(stale, path)
		end
	else
		fs.writeFile(path, content)
		print(`wrote {path} ({#output.model:GetDescendants()} instances)`)
	end
end

if #stale > 0 then
	print(`Out of date (run "lune run maps/build"): {table.concat(stale, ", ")}`)
	process.exit(1)
end
