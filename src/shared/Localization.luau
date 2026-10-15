--!strict
--[[
	Localization — turns string keys into player-facing text. UI code never hard-codes text; it calls
	Localization.format(key, args) with a key from GameStrings.csv.

	Source strings live in src/localization/GameStrings.csv (LocalizationService.GameStrings). On clients the
	player's Translator (cloud table + GameStrings, with Roblox automatic translation) is used once it loads; until
	then, or if a key has no translation, the English source text is used.
]]
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TABLE_NAME = "GameStrings"

local Localization = {}

local sources: { [string]: string } = {}
local missing: { [string]: boolean } = {}
local translator: Translator? = nil

local stringsTable = LocalizationService:WaitForChild(TABLE_NAME) :: LocalizationTable
for _, entry in stringsTable:GetEntries() do
	sources[entry.Key] = entry.Source
end

if RunService:IsClient() then
	task.spawn(function()
		local ok, result = pcall(function()
			return LocalizationService:GetTranslatorForPlayerAsync(Players.LocalPlayer)
		end)
		if ok then
			translator = result
		end
	end)
end

local function substitute(text: string, args: { [any]: any }): string
	return (
		string.gsub(text, "{([%w_]+)}", function(token: string): string
			local value = args[tonumber(token) or token]
			return if value ~= nil then tostring(value) else `\{{token}\}`
		end)
	)
end

-- Returns the text for `key`, filling {1}/{name} placeholders from `args`.
function Localization.format(key: string, args: { [any]: any }?): string
	if translator then
		local ok, text = pcall(function()
			return (translator :: Translator):FormatByKey(key, args or {})
		end)
		if ok then
			return text
		end
	end
	local source = sources[key]
	if source == nil then
		if not missing[key] then
			missing[key] = true
			warn(`[Localization] missing key "{key}"`)
		end
		return key
	end
	return if args then substitute(source, args) else source
end

-- True if the key exists in GameStrings.
function Localization.has(key: string): boolean
	return sources[key] ~= nil
end

return Localization
