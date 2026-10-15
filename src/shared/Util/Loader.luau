--!strict
--[[
	Loader
	Boots a folder of service (server) or controller (client) modules in two passes:
	  1. Init  - runs synchronously in Priority order (lowest first). Create state, remotes and connections here.
	  2. Start - runs in its own thread per module. Begin loops and gameplay here.
	A module may omit either method. A failing module is reported by name and does not stop the others.
]]

export type Module = {
	Priority: number?,
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

type Entry = {
	name: string,
	module: Module,
	priority: number,
}

local Loader = {}

local function report(name: string, phase: string, err: unknown)
	warn(`[Loader] {name}.{phase} failed: {err}`)
end

local function collect(folder: Instance): { Entry }
	local entries: { Entry } = {}
	for _, child in folder:GetChildren() do
		if not child:IsA("ModuleScript") then
			continue
		end
		local ok, result = pcall((require :: any), child)
		if not ok then
			report(child.Name, "require", result)
			continue
		end
		if type(result) ~= "table" then
			report(child.Name, "require", "module did not return a table")
			continue
		end
		local module = result :: Module
		table.insert(entries, { name = child.Name, module = module, priority = module.Priority or 0 })
	end
	table.sort(entries, function(a: Entry, b: Entry): boolean
		if a.priority == b.priority then
			return a.name < b.name
		end
		return a.priority < b.priority
	end)
	return entries
end

-- Requires, initialises and starts every ModuleScript directly inside `folder`.
-- Returns the loaded modules keyed by their instance name.
function Loader.Boot(folder: Instance): { [string]: Module }
	local entries = collect(folder)
	local loaded: { [string]: Module } = {}

	for _, entry in entries do
		loaded[entry.name] = entry.module
		local init = entry.module.Init
		if init then
			local ok, err = xpcall(init, debug.traceback, entry.module)
			if not ok then
				report(entry.name, "Init", err)
			end
		end
	end

	for _, entry in entries do
		local start = entry.module.Start
		if start then
			task.spawn(function()
				local ok, err = xpcall(start, debug.traceback, entry.module)
				if not ok then
					report(entry.name, "Start", err)
				end
			end)
		end
	end

	return loaded
end

return Loader
