--!strict
-- HUD helpers (step 1.12): round clock, thousands separators, Percent colors, dash ring, scoreboard order.
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
	["join pad line: waiting, voting and during a round"] = function()
		local key = HudFormat.queueKey
		expect.equal(key("Waiting", "Lobby", "Off", false), "Round.Waiting")
		expect.equal(key("Waiting", "Lobby", nil, false), "Round.Waiting")
		expect.equal(key("Waiting", "Lobby", "In", false), "Round.WaitingIn")
		expect.equal(key("Waiting", "Lobby", "AFK", false), "Round.QueueAFK")
		expect.equal(key("Voting", "Lobby", "Off", false), "Round.Starting")
		expect.equal(key("Voting", "Lobby", "In", false), nil, "the vote panel shows instead")
		expect.equal(key("Playing", "Lobby", "Off", false), "Round.JoinNext")
		expect.equal(key("Playing", "Lobby", "In", false), "Round.InNext")
		expect.equal(key("Playing", "Lobby", "Off", true), "Round.JoinNow")
		expect.equal(key("Playing", "Lobby", "In", true), "Round.Joining")
		expect.equal(key("Playing", "Lobby", "AFK", true), "Round.QueueAFK")
		expect.equal(key("Playing", "Playing", "Off", true), nil, "fighting")
		expect.equal(key("Playing", "Spectating", "Off", false), nil, "spectating")
		expect.equal(key("Results", "Lobby", "In", false), nil)
		expect.equal(key(nil, nil, nil, false), nil)
	end,
	["long clock shows h:mm:ss, rounded up, never negative"] = function()
		expect.equal(HudFormat.longClock(5 * 3600 + 12 * 60 + 9), "5:12:09")
		expect.equal(HudFormat.longClock(59.5), "0:01:00")
		expect.equal(HudFormat.longClock(86400), "24:00:00")
		expect.equal(HudFormat.longClock(-1), "0:00:00")
	end,
	["leaderboard medals: gold, silver, bronze for the top 3"] = function()
		expect.equal(HudFormat.medal(1), "Gold")
		expect.equal(HudFormat.medal(2), "Silver")
		expect.equal(HudFormat.medal(3), "Bronze")
		expect.equal(HudFormat.medal(4), nil)
	end,
	["thousands: groups of three digits, whole part, minus sign kept"] = function()
		expect.equal(HudFormat.thousands(0), "0")
		expect.equal(HudFormat.thousands(999), "999")
		expect.equal(HudFormat.thousands(1000), "1,000")
		expect.equal(HudFormat.thousands(1234567), "1,234,567")
		expect.equal(HudFormat.thousands(123456.9), "123,456")
		expect.equal(HudFormat.thousands(-12500), "-12,500")
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
