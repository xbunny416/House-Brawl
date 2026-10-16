--!strict
-- HUD helpers (step 1.12): round clock, Percent colors, dash ring, scoreboard order.
local Roblox = require("../roblox")
local expect = require("../expect")

local HudFormat = Roblox.require(Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib.HudFormat)

local function names(rows: { any }): string
	local list = {}
	for _, row in rows do
		table.insert(list, row.Name)
	end
	return table.concat(list, ",")
end

return {
	["clock shows m:ss, rounded up, never negative"] = function()
		expect.equal(HudFormat.clock(180), "3:00")
		expect.equal(HudFormat.clock(151.2), "2:32")
		expect.equal(HudFormat.clock(9), "0:09")
		expect.equal(HudFormat.clock(-4), "0:00")
	end,
	["percent color: white at 0%, yellow at 60%, red from 150%"] = function()
		local white = HudFormat.percentColor(0)
		expect.equal(white.R + white.G + white.B, 3)
		local yellow = HudFormat.percentColor(60)
		expect.near(yellow.G, 0.86)
		expect.near(yellow.B, 0.2)
		local red = HudFormat.percentColor(300)
		expect.equal(red.R, 1)
		expect.truthy(red.G < 0.3, "red")
		local between = HudFormat.percentColor(30)
		expect.truthy(between.B < 1 and between.B > 0.2, "white to yellow")
	end,
	["dash ring: full when ready, empty right after a dash"] = function()
		expect.equal(HudFormat.dashFill(0, 2.5), 1)
		expect.equal(HudFormat.dashFill(2.5, 2.5), 0)
		expect.near(HudFormat.dashFill(1, 2.5), 0.6)
		expect.equal(HudFormat.dashFill(1, 0), 1)
	end,
	["scoreboard: fighters first; Classic by lives then KOs; Casual by score"] = function()
		local classic = HudFormat.sortScoreboard({
			{ Name = "Lobby", Lives = nil, KOs = 0, Falls = 0, InRound = false },
			{ Name = "Ann", Lives = 1, KOs = 5, Falls = 2, InRound = true },
			{ Name = "Bob", Lives = 3, KOs = 0, Falls = 0, InRound = true },
			{ Name = "Cat", Lives = 1, KOs = 6, Falls = 2, InRound = true },
		})
		expect.equal(names(classic), "Bob,Cat,Ann,Lobby")
		local casual = HudFormat.sortScoreboard({
			{ Name = "Ann", KOs = 5, Falls = 4, InRound = true },
			{ Name = "Bob", KOs = 2, Falls = 0, InRound = true },
			{ Name = "Cat", KOs = 3, Falls = 1, InRound = true },
		})
		expect.equal(names(casual), "Cat,Bob,Ann")
	end,
}
