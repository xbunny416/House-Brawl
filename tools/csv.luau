--!strict
-- Minimal RFC 4180 CSV reader (quoted fields, doubled quotes, commas/newlines inside quotes). Used by Lune tooling.
local fs = require("@lune/fs")

local csv = {}

function csv.parse(text: string): { { string } }
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

-- Reads GameStrings.csv into { [key]: sourceText }.
function csv.readStrings(path: string?): { [string]: string }
	local rows = csv.parse(fs.readFile(path or "src/localization/GameStrings.csv"))
	local strings: { [string]: string } = {}
	for index = 2, #rows do
		strings[rows[index][1]] = rows[index][2]
	end
	return strings
end

return csv
