--!strict
-- Lobby join pad (owner's request, 2026-10-16): who is on the pad, and who is counted for the next round.
local roblox = require("@lune/roblox")
local Roblox = require("../roblox")
local expect = require("../expect")

local Queue = Roblox.require(Roblox.game.ServerScriptService.Server.Round.Queue)

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

local PAD = CFrame.new(37, 100.1, 0)
local SIZE = Vector3.new(14, 0.2, 18)
local HEIGHT = 10

local function on(x: number, y: number, z: number): boolean
	return Queue.contains(PAD, SIZE, Vector3.new(x, y, z), HEIGHT)
end

return {
	["a root over the pad counts, up to Height above it (jumping)"] = function()
		expect.equal(on(37, 103, 0), true, "standing in the middle")
		expect.equal(on(30.1, 103, 8.9), true, "near a corner")
		expect.equal(on(37, 110, 0), true, "jumping")
		expect.equal(on(37, 100.2 + HEIGHT + 0.1, 0), false, "too high")
		expect.equal(on(37, 99, 0), false, "below the pad")
	end,
	["a root beside the pad does not count"] = function()
		expect.equal(on(29.5, 103, 0), false, "west of it")
		expect.equal(on(44.5, 103, 0), false, "east of it")
		expect.equal(on(37, 103, 9.5), false, "north of it")
		expect.equal(on(37, 103, -9.5), false, "south of it")
	end,
	["a turned pad uses its own axes"] = function()
		local turned = PAD * CFrame.Angles(0, math.rad(90), 0) -- 14 along Z, 18 along X now
		expect.equal(Queue.contains(turned, SIZE, Vector3.new(37 + 8.5, 103, 0), HEIGHT), true)
		expect.equal(Queue.contains(turned, SIZE, Vector3.new(37, 103, 8.5), HEIGHT), false)
	end,
	["only lobby players (and knocked-out Classic spectators) queue; AFK ones are not counted"] = function()
		expect.equal(Queue.status("Lobby", true, false), "In")
		expect.equal(Queue.status("Spectating", true, false), "In")
		expect.equal(Queue.status("Lobby", true, true), "AFK")
		expect.equal(Queue.status("Lobby", false, false), "Off")
		expect.equal(Queue.status("Lobby", false, true), "Off")
		expect.equal(Queue.status("Playing", true, false), "Off")
		expect.equal(Queue.status("Respawning", true, false), "Off")
	end,
}
