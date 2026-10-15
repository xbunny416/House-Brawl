--!strict
-- GameStrings.csv must be well-formed and cover every key the game uses.
local fs = require("@lune/fs")
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)

local CSV_PATH = "src/localization/GameStrings.csv"

-- Minimal RFC 4180 parser (quoted fields, doubled quotes, commas inside quotes).
local function parseCsv(text: string): { { string } }
	local rows: { { string } } = {}
	local row: { string } = {}
	local field = ""
	local inQuotes = false
	local i = 1
	while i <= #text do
		local char = string.sub(text, i, i)
		if inQuotes then
			if char == '"' then
				if string.sub(text, i + 1, i + 1) == '"' then
					field ..= '"'
					i += 1
				else
					inQuotes = false
				end
			else
				field ..= char
			end
		elseif char == '"' then
			inQuotes = true
		elseif char == "," then
			table.insert(row, field)
			field = ""
		elseif char == "\n" then
			table.insert(row, field)
			table.insert(rows, row)
			row, field = {}, ""
		elseif char ~= "\r" then
			field ..= char
		end
		i += 1
	end
	if field ~= "" or #row > 0 then
		table.insert(row, field)
		table.insert(rows, row)
	end
	return rows
end

local rows = parseCsv(fs.readFile(CSV_PATH))
local keys: { [string]: string } = {}
for index = 2, #rows do
	keys[rows[index][1]] = rows[index][2]
end

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

return {
	["header is Key,Source,Context,Example"] = function()
		expect.equal(table.concat(rows[1], ","), "Key,Source,Context,Example")
	end,
	["every row has 4 columns, a key and source text, and keys are unique"] = function()
		local seen: { [string]: boolean } = {}
		for index = 2, #rows do
			local row = rows[index]
			expect.equal(#row, 4, `row {index} columns`)
			expect.truthy(row[1] ~= "" and row[2] ~= "", `row {index} key/source`)
			expect.equal(seen[row[1]], nil, `duplicate key {row[1]}`)
			seen[row[1]] = true
		end
	end,
	["every mode, map, style and rank has its strings"] = function()
		for id in Config.Modes.List do
			expect.truthy(keys[`Mode.{id}.Name`] and keys[`Mode.{id}.Desc`], `Mode.{id}`)
		end
		expect.truthy(keys[`Map.{Config.Maps.Lobby}.Name`], "lobby name")
		for id in Config.Maps.List do
			expect.truthy(keys[`Map.{id}.Name`], `Map.{id}.Name`)
		end
		for id in Config.Styles.List do
			expect.truthy(keys[`Style.{id}.Name`] and keys[`Style.{id}.Desc`], `Style.{id}`)
		end
		for _, rank in Config.Progression.Ranks do
			expect.truthy(keys[`Rank.{rank.Id}`], `Rank.{rank.Id}`)
		end
	end,
	["every literal key used in code exists"] = function()
		local files: { string } = {}
		walk("src", files)
		for _, path in files do
			local source = fs.readFile(path)
			for key in string.gmatch(source, 'Localization%.format%(%s*"([^"]+)"') do
				expect.truthy(keys[key], `{path} uses missing key {key}`)
			end
			for key in string.gmatch(source, 'Net%.fire%w*%(%s*"Notify"[^"]*"([^"]+)"') do
				expect.truthy(keys[key], `{path} notifies with missing key {key}`)
			end
		end
	end,
}
