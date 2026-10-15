--!strict
--[[
	Lune test runner (Studio is not available in CI, so this is the automated gate for Luau code).
	Usage: lune run tests/run

	1. Compiles every .luau file under src/ to catch syntax errors.
	2. Runs every tests/specs/*.spec.luau file. A spec returns a table of named test functions;
	   a test fails by throwing (use assert or tests/expect.luau).
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local SOURCE_ROOT = "src"
local SPEC_ROOT = "tests/specs"

local failures = 0

local function walk(dir: string, out: { string })
	for _, name in fs.readDir(dir) do
		local path = `{dir}/{name}`
		if fs.isDir(path) then
			walk(path, out)
		elseif string.sub(name, -5) == ".luau" then
			table.insert(out, path)
		end
	end
end

-- 1. Syntax check
local sources: { string } = {}
walk(SOURCE_ROOT, sources)
table.sort(sources)
for _, path in sources do
	local ok, err = pcall(luau.compile, fs.readFile(path))
	if not ok then
		failures += 1
		print(`[syntax] FAIL {path}\n    {err}`)
	end
end
print(`[syntax] checked {#sources} file(s)`)

-- 2. Specs
local specs: { string } = {}
if fs.isDir(SPEC_ROOT) then
	walk(SPEC_ROOT, specs)
end
table.sort(specs)

local passed = 0
for _, path in specs do
	if string.sub(path, -10) ~= ".spec.luau" then
		continue
	end
	local requirePath = "./" .. string.sub(string.sub(path, #"tests/" + 1), 1, -6)
	local loaded, spec = pcall(require, requirePath)
	if not loaded then
		failures += 1
		print(`[spec] FAIL {path} (could not load)\n    {spec}`)
		continue
	end
	local names: { string } = {}
	for name in spec :: { [string]: () -> () } do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local ok, err = pcall((spec :: { [string]: () -> () })[name])
		if ok then
			passed += 1
		else
			failures += 1
			print(`[spec] FAIL {path} :: {name}\n    {err}`)
		end
	end
end
print(`[spec] {passed} passed, {failures} failure(s) total`)

if failures > 0 then
	process.exit(1)
end
