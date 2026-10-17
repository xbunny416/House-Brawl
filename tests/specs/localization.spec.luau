--!strict
-- GameStrings.csv must be well-formed and cover every key the game uses.
local fs = require("@lune/fs")
local csv = require("../../tools/csv")
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local ShopRules = Roblox.require(Roblox.game.ReplicatedStorage.Shared.ShopRules)
local MonetizationRules = Roblox.require(Roblox.game.ReplicatedStorage.Shared.MonetizationRules)
local DailyRules = Roblox.require(Roblox.game.ReplicatedStorage.Shared.DailyRules)
local HudFormat = Roblox.require(Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib.HudFormat)

local CSV_PATH = "src/localization/GameStrings.csv"

local rows = csv.parse(fs.readFile(CSV_PATH))
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
		for id in Config.Props.Types do
			expect.truthy(keys[`Prop.{id}.Name`], `Prop.{id}.Name`)
		end
		for id in Config.Cosmetics.Items do
			expect.truthy(keys[`Cosmetic.{id}.Name`], `Cosmetic.{id}.Name`)
		end
		for _, slot in Config.Cosmetics.Slots do
			expect.truthy(keys[`Slot.{slot}`] and keys[`Slot.{slot}.One`], `Slot.{slot}`)
		end
		for _, reason in ShopRules.Reasons do
			expect.truthy(keys[`Shop.Error.{reason}`], `Shop.Error.{reason}`)
		end
		for _, reason in DailyRules.Reasons do
			expect.truthy(keys[`Daily.Error.{reason}`], `Daily.Error.{reason}`)
		end
		for _, list in { Config.Retention.Quests.Daily, Config.Retention.Quests.Weekly } do
			for _, quest in list do
				expect.truthy(keys[`Quest.{quest.Id}.Title`] and keys[`Quest.{quest.Id}.Desc`], `Quest.{quest.Id}`)
			end
		end
		for _, key in HudFormat.QueueKeys do
			expect.truthy(keys[key], key)
		end
		for rarity in Config.Cosmetics.Rarities do
			expect.truthy(keys[`Rarity.{rarity}`], `Rarity.{rarity}`)
		end
		for _, item in Config.Cosmetics.Items do
			local source = item.Exclusive
			if source then
				expect.truthy(keys[`Locker.{source}Only`], `Locker.{source}Only`)
			end
		end
		for _, perk in MonetizationRules.Perks do
			expect.truthy(keys[`Perk.{perk}`] and keys[`Perk.{perk}.Desc`], `Perk.{perk}`)
		end
		for _, offer in MonetizationRules.offers() do
			expect.truthy(keys[MonetizationRules.nameKey(offer)], MonetizationRules.nameKey(offer))
		end
		for key in Config.Monetization.GamePasses do
			expect.truthy(keys[`Purchase.Done.{key}`], `Purchase.Done.{key}`)
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
			for key in string.gmatch(source, 'Net%.fire%w*%(%s*"Notify"[^"\n]*"([^"]+)"') do
				expect.truthy(keys[key], `{path} notifies with missing key {key}`)
			end
		end
	end,
}
