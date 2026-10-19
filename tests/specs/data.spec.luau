--!strict
-- Saved-data template, migrations and the Signal utility used by data services.
local serde = require("@lune/serde")
local task = require("@lune/task")
local Roblox = require("../roblox")
local expect = require("../expect")

Roblox.setGlobals({ task = task })

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local DataTemplate = Roblox.require(Shared.Data.Template)
local Migrations = Roblox.require(Roblox.game.ServerScriptService.Server.Data.Migrations)
local Signal = Roblox.require(Shared.Util.Signal)

local function deepEqual(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

return {
	["template version matches VERSION"] = function()
		expect.equal(DataTemplate.Template.Version, DataTemplate.VERSION)
	end,
	["new players start with the default style in their starting slots, slot 1 equipped"] = function()
		local styles = DataTemplate.Template.Styles
		expect.equal(styles.Equipped, Config.Styles.Default)
		expect.equal(#styles.Slots, Config.Styles.Roll.Slots.Start)
		expect.equal(#styles.Locked, Config.Styles.Roll.Slots.Start)
		expect.equal(styles.Slots[1], Config.Styles.Default)
		expect.equal(styles.Active, 1)
		expect.equal(styles.Pity, 0)
		expect.equal(styles.FreeSpinDay, -1)
	end,
	["migration 1 → 2: the equipped style goes into slot 1, owned styles are dropped"] = function()
		local data: { [string]: any } = {
			Version = 1,
			Styles = { Owned = { Brawler = true, Wrecker = true, Slugger = true }, Equipped = "Wrecker" },
		}
		expect.equal(Migrations.run(data, 2), true)
		expect.equal(data.Styles.Owned, nil)
		expect.equal(data.Styles.Slots[1], "Wrecker")
		expect.equal(data.Styles.Equipped, "Wrecker")
		expect.equal(data.Styles.Active, 1)
		expect.equal(data.Styles.Locked[1], false)
		local gone: { [string]: any } = { Version = 1, Styles = { Owned = {}, Equipped = "Removed" } }
		Migrations.run(gone, 2)
		expect.equal(gone.Styles.Equipped, Config.Styles.Default, "a style that no longer exists falls back")
	end,
	["new players start at level 1 with starting Scrap and zeroed stats"] = function()
		local template = DataTemplate.Template
		expect.equal(template.Level, 1)
		expect.equal(template.XP, 0)
		expect.equal(template.Scrap, Config.Economy.StartingScrap)
		for stat, value in template.Stats do
			expect.equal(value, 0, stat)
		end
	end,
	["template survives a JSON round trip (DataStore-safe)"] = function()
		local template = DataTemplate.Template
		local decoded = serde.decode("json", serde.encode("json", template))
		-- Empty tables encode as [] in JSON; compare everything else exactly.
		decoded.Cosmetics.Owned = {}
		decoded.Cosmetics.Equipped = {}
		decoded.Titles.Owned = {}
		decoded.PurchaseIds = {}
		expect.truthy(deepEqual(decoded, template), "round trip")
	end,
	["template settings are a mutable copy of Config defaults"] = function()
		local settings = DataTemplate.Template.Settings
		expect.equal(table.isfrozen(settings), false)
		for key, value in Config.Data.DefaultSettings do
			expect.equal(settings[key], value, key)
		end
	end,
	["migrations: nothing to do at the current version"] = function()
		local data = { Version = DataTemplate.VERSION }
		expect.equal(Migrations.run(data, DataTemplate.VERSION), true)
		expect.equal(data.Version, DataTemplate.VERSION)
	end,
	["migrations: runs steps in order and stops at a gap"] = function()
		local saved = Migrations.Steps
		Migrations.Steps = {
			[1] = function(data)
				data.Coins = nil
			end,
		}
		local data: { [string]: any } = { Version = 1, Coins = 5 }
		expect.equal(Migrations.run(data, 2), true)
		expect.equal(data.Version, 2)
		expect.equal(data.Coins, nil)
		expect.equal(Migrations.run(data, 4), false)
		expect.equal(data.Version, 2)
		Migrations.Steps = saved
	end,
	["signal: connect, fire, disconnect, once"] = function()
		local signal = Signal.new()
		local total = 0
		local connection = signal:Connect(function(amount: number)
			total += amount
		end)
		signal:Once(function(amount: number)
			total += amount * 10
		end)
		signal:Fire(1)
		signal:Fire(2)
		connection:Disconnect()
		signal:Fire(100)
		expect.equal(total, 1 + 10 + 2)
		expect.equal(connection.Connected, false)
	end,
}
