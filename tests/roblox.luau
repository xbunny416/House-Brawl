--!strict
--[[
	Minimal Roblox instance shim for Lune specs.

	Builds a fake DataModel from default.project.json (the same mapping Rojo uses) so game modules written with
	instance requires — `require(script.Parent.Config)` — can be loaded and tested outside Studio.

	Supported: Name, Parent, ClassName, child indexing, FindFirstChild, WaitForChild, GetChildren, IsA, GetFullName,
	game:GetService. Only modules that avoid other Roblox APIs (or receive stubs via `extraGlobals`) can be loaded.

	Usage from a spec:
		local Roblox = require("../roblox")
		local Formulas = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Formulas)
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")

type Node = {
	Name: string,
	ClassName: string,
	Parent: Node?,
	_children: { [string]: Node },
	_order: { Node },
	_file: string?,
}

local Roblox = {}

local nodeMethods = {}
local nodeMeta = {}

local function newNode(name: string, className: string, parent: Node?, file: string?): Node
	local node = setmetatable({
		Name = name,
		ClassName = className,
		Parent = parent,
		_children = {},
		_order = {},
		_file = file,
	}, nodeMeta) :: any
	if parent then
		parent._children[name] = node
		table.insert(parent._order, node)
	end
	return node
end

function nodeMethods.FindFirstChild(self: Node, name: string): Node?
	return self._children[name]
end

function nodeMethods.WaitForChild(self: Node, name: string): Node
	local child = self._children[name]
	if not child then
		error(`[shim] WaitForChild would hang: {name} is not a child of {nodeMethods.GetFullName(self)}`, 2)
	end
	return child
end

function nodeMethods.GetChildren(self: Node): { Node }
	return table.clone(self._order)
end

function nodeMethods.IsA(self: Node, className: string): boolean
	return self.ClassName == className or className == "Instance"
end

function nodeMethods.GetFullName(self: Node): string
	if self.Parent == nil or self.Parent.ClassName == "DataModel" then
		return self.Name
	end
	return `{nodeMethods.GetFullName(self.Parent)}.{self.Name}`
end

function nodeMethods.GetService(self: Node, name: string): Node
	return self._children[name] or newNode(name, name, self)
end

nodeMeta.__index = function(self: any, key: string): any
	local method = (nodeMethods :: any)[key]
	if method then
		return method
	end
	local child = rawget(self, "_children")[key]
	if child then
		return child
	end
	error(`[shim] {key} is not a valid member of {nodeMethods.GetFullName(self)}`, 2)
end

nodeMeta.__tostring = function(self: any): string
	return self.Name
end

local mapPath: (path: string, name: string, parent: Node) -> ()

local function mapChildren(dir: string, node: Node)
	local entries = fs.readDir(dir)
	table.sort(entries)
	for _, entry in entries do
		if entry ~= "init.luau" then
			mapPath(`{dir}/{entry}`, entry, node)
		end
	end
end

-- Mirrors Rojo's file -> instance rules for the subset this project uses.
function mapPath(path: string, entry: string, parent: Node)
	if fs.isDir(path) then
		local initFile = `{path}/init.luau`
		local node = if fs.isFile(initFile)
			then newNode(entry, "ModuleScript", parent, initFile)
			else newNode(entry, "Folder", parent, nil)
		mapChildren(path, node)
		return
	end
	local name = string.match(entry, "^(.-)%.luau$")
	if not name then
		return -- non-Luau files are not needed by specs
	end
	local scriptName = string.match(name, "^(.-)%.server$")
	local localScriptName = string.match(name, "^(.-)%.client$")
	if scriptName then
		newNode(scriptName, "Script", parent, path)
	elseif localScriptName then
		newNode(localScriptName, "LocalScript", parent, path)
	else
		newNode(name, "ModuleScript", parent, path)
	end
end

local function classFor(key: string, value: { [string]: any }, parent: Node): string
	local path = value["$path"]
	if value["$className"] then
		return value["$className"]
	elseif type(path) == "string" and string.sub(path, -4) == ".csv" then
		return "LocalizationTable"
	elseif parent.ClassName == "DataModel" then
		return key -- services
	end
	return "Folder"
end

local function mapTree(tree: { [string]: any }, node: Node)
	local path = tree["$path"]
	if type(path) == "string" and fs.isDir(path) then
		mapChildren(path, node)
	end
	for key, value in tree do
		if string.sub(key, 1, 1) ~= "$" and type(value) == "table" then
			local className = classFor(key, value, node)
			local child = node._children[key] or newNode(key, className, node)
			mapTree(value, child)
		end
	end
end

local project = serde.decode("json", fs.readFile("default.project.json"))
local game = newNode("Game", "DataModel", nil)
mapTree(project.tree, game)

local cache: { [Node]: any } = {}
local loading: { [Node]: boolean } = {}
local extraGlobals: { [string]: any } = {}

local function requireNode(node: any): any
	if type(node) ~= "table" or getmetatable(node) ~= nodeMeta then
		error(`[shim] require expects a ModuleScript node, got {typeof(node)}`, 2)
	end
	if node.ClassName ~= "ModuleScript" then
		error(`[shim] require: {node:GetFullName()} is a {node.ClassName}, not a ModuleScript`, 2)
	end
	if cache[node] ~= nil then
		return cache[node]
	end
	if loading[node] then
		error(`[shim] circular require of {node:GetFullName()}`, 2)
	end
	loading[node] = true

	local environment: { [string]: any } = {
		script = node,
		game = game,
		require = requireNode,
	}
	for key, value in extraGlobals do
		environment[key] = value
	end
	local chunk = luau.load(fs.readFile(node._file), {
		debugName = node._file,
		environment = environment,
	})
	local result = chunk()
	loading[node] = nil
	cache[node] = result
	return result
end

Roblox.game = game :: any
Roblox.require = requireNode

-- Makes extra globals (e.g. stubbed services or datatypes) visible to modules loaded after this call.
function Roblox.setGlobals(globals: { [string]: any })
	for key, value in globals do
		extraGlobals[key] = value
	end
end

return Roblox
