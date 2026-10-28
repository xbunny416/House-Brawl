--!strict
-- The arenas' moving parts (owner, 2026-10-20: "more dynamic … moving parts"): how lifts, slides and swings move.
local roblox = require("@lune/roblox")
local Roblox = require("../roblox")
local expect = require("../expect")

Roblox.setGlobals({ CFrame = roblox.CFrame, Vector3 = roblox.Vector3 })

local MoverRules = Roblox.require(Roblox.game.ReplicatedStorage.Shared.MoverRules)

local function params(overrides: { [string]: any }): any
	local base: { [string]: any } = {
		Kind = "Lift",
		Period = 10,
		Pause = 2,
		Offset = roblox.Vector3.new(0, 10, 0),
		Angle = 0,
		Axis = "Z",
		Phase = 0,
	}
	for key, value in overrides do
		base[key] = value
	end
	return base
end

return {
	["a lift waits at each end and eases between them"] = function()
		-- Period 10, pause 2: rests 0–2, rises 2–5, waits at the top 5–7, comes down 7–10.
		expect.equal(MoverRules.travel(10, 2, 0), 0)
		expect.equal(MoverRules.travel(10, 2, 1.9), 0)
		expect.near(MoverRules.travel(10, 2, 3.5), 0.5)
		expect.equal(MoverRules.travel(10, 2, 5.5), 1)
		expect.equal(MoverRules.travel(10, 2, 6.9), 1)
		expect.near(MoverRules.travel(10, 2, 8.5), 0.5)
		expect.near(MoverRules.travel(10, 2, 10), 0) -- the next round trip
		expect.near(MoverRules.travel(10, 2, 23.5), 0.5)
		-- Eased: slow near the ends, quick in the middle.
		local early = MoverRules.travel(10, 2, 2.3) - MoverRules.travel(10, 2, 2)
		local middle = MoverRules.travel(10, 2, 3.65) - MoverRules.travel(10, 2, 3.35)
		expect.truthy(middle > early * 3, "eases in")
	end,
	["travel always stays between the two ends"] = function()
		for step = 0, 200 do
			local value = MoverRules.travel(7, 1.5, step * 0.073)
			expect.truthy(value >= 0 and value <= 1, `travel {value}`)
		end
	end,
	["a swing goes ±Angle and back each Period"] = function()
		expect.near(MoverRules.swing(55, 4, 0), 0)
		expect.near(MoverRules.swing(55, 4, 1), 55)
		expect.near(MoverRules.swing(55, 4, 2), 0)
		expect.near(MoverRules.swing(55, 4, 3), -55)
	end,
	["the pivot: a lift rises by its offset, a swing turns about its axis, the phase shifts the clock"] = function()
		local rest = roblox.CFrame.new(5, 0, 5)
		local lift = params({})
		expect.near(MoverRules.pivotAt(lift, rest, 0).Position.Y, 0)
		expect.near(MoverRules.pivotAt(lift, rest, 6).Position.Y, 10)
		expect.near(MoverRules.pivotAt(params({ Phase = 6 }), rest, 0).Position.Y, 10)
		local swing = params({ Kind = "Swing", Period = 4, Angle = 90, Axis = "Z" })
		-- A point hanging 10 below the pivot swings out to the side at the top of the swing.
		local hanging = MoverRules.pivotAt(swing, rest, 1) * roblox.Vector3.new(0, -10, 0)
		expect.near(math.abs(hanging.X - 5), 10, 0.001)
		expect.near(hanging.Y, 0, 0.001)
		expect.near(hanging.Z, 5, 0.001)
		local aroundX = MoverRules.pivotAt(params({ Kind = "Swing", Period = 4, Angle = 90, Axis = "X" }), rest, 1)
			* roblox.Vector3.new(0, -10, 0)
		expect.near(aroundX.X, 5, 0.001)
		expect.near(math.abs(aroundX.Z - 5), 10, 0.001)
	end,
	["a spin turns round its up axis, a full turn every period, and stays level"] = function()
		expect.near(MoverRules.spin(4, 0), 0)
		expect.near(MoverRules.spin(4, 1), 90)
		expect.near(MoverRules.spin(4, 3), 270)
		expect.near(MoverRules.spin(4, 4), 0) -- the next turn
		expect.near(MoverRules.spin(4, 1e9 + 2), 180, 0.01) -- late in the server clock too
		local rest = roblox.CFrame.new(5, 20, 5)
		local fan = params({ Kind = "Spin", Period = 4 })
		local quarter = MoverRules.pivotAt(fan, rest, 1)
		expect.near((quarter.Position - rest.Position).Magnitude, 0, 0.001)
		expect.near(quarter.UpVector.Y, 1, 0.001)
		local tip = quarter * roblox.Vector3.new(4, 0, 0)
		expect.near(tip.Y, 20, 0.001)
		expect.near(math.abs(tip.Z - 5), 4, 0.001)
	end,
	["settings read off a model, with safe defaults"] = function()
		local model = roblox.Instance.new("Model")
		local read = MoverRules.read(model)
		expect.equal(read.Kind, "Slide")
		expect.truthy(read.Period >= 0.5, "a period")
		expect.equal(read.Offset, nil)
		model:SetAttribute("Kind", "Swing")
		model:SetAttribute("Period", 0)
		model:SetAttribute("Axis", "X")
		model:SetAttribute("Offset", roblox.Vector3.new(1, 2, 3))
		read = MoverRules.read(model)
		expect.equal(read.Kind, "Swing")
		expect.equal(read.Period, 0.5) -- never zero
		expect.equal(read.Axis, "X")
		expect.equal(read.Offset, roblox.Vector3.new(1, 2, 3))
		for _, kind in { "Lift", "Slide", "Swing", "Spin" } do
			expect.truthy(table.find(MoverRules.Kinds, kind), kind)
		end
	end,
}
