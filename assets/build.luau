--!strict
--[[
	Generates ReplicatedStorage.Assets (assets/Assets.luau) into a model file Rojo syncs.
	  lune run assets/build           writes assets/generated/Assets.rbxmx (commit it)
	  lune run assets/build --check   exits 1 if the committed file is out of date
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Assets = require("./Assets")

local PATH = "assets/generated/Assets.rbxmx"

local folder = Assets.build()
local content = roblox.serializeModel({ folder }, true)
if table.find(process.args, "--check") ~= nil then
	if not fs.isFile(PATH) or fs.readFile(PATH) ~= content then
		print(`Out of date (run "lune run assets/build"): {PATH}`)
		process.exit(1)
	end
else
	fs.writeDir("assets/generated")
	fs.writeFile(PATH, content)
	print(`wrote {PATH} ({#folder:GetDescendants()} instances)`)
end
