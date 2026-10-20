--!strict
-- The lobby's arm-wrestling table (owner's fix list): seats, countdown, presses, pins, time-outs, champion.
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local ArmWrestleRules = Roblox.require(Roblox.game.ReplicatedStorage.Shared.ArmWrestleRules)
local ArmWrestle = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Animation.ArmWrestle)

local rules = Config.World.ArmWrestle

-- A match with both seats taken (UserIds 11 and 22) that has just started pulling at time `t`.
local function pulling(t: number): any
	local match = ArmWrestleRules.new()
	ArmWrestleRules.seat(match, 1, 11, t - rules.CountdownTime)
	ArmWrestleRules.seat(match, 2, 22, t - rules.CountdownTime)
	expect.equal(ArmWrestleRules.tick(match, t), "Started")
	return match
end

-- Presses `count` times from `side`, spaced so every press counts; returns the last press's event.
local function presses(match: any, side: number, count: number, t: number): (string?, number)
	local event: string? = nil
	for _ = 1, count do
		t += 1 / rules.TapRate
		local _, result = ArmWrestleRules.tap(match, side, t)
		event = result or event
	end
	return event, t
end

return {
	["waits for two, counts down, then pulls"] = function()
		local match = ArmWrestleRules.new()
		expect.equal(ArmWrestleRules.seat(match, 1, 11, 0), nil)
		expect.equal(match.State, "Waiting")
		ArmWrestleRules.seat(match, 2, 22, 5)
		expect.equal(match.State, "Countdown")
		expect.equal(match.EndsAt, 5 + rules.CountdownTime)
		expect.equal(ArmWrestleRules.tick(match, 5 + rules.CountdownTime - 0.1), nil)
		expect.equal(ArmWrestleRules.tick(match, 5 + rules.CountdownTime), "Started")
		expect.equal(match.State, "Pulling")
		expect.equal(match.Progress, 0)
		expect.equal(match.EndsAt, 5 + rules.CountdownTime + rules.PullTime)
	end,
	["presses push toward the presser; none count outside the pull"] = function()
		local match = ArmWrestleRules.new()
		ArmWrestleRules.seat(match, 1, 11, 0)
		expect.equal((ArmWrestleRules.tap(match, 1, 0)), false)
		match = pulling(10)
		expect.equal((ArmWrestleRules.tap(match, 1, 10)), true)
		expect.near(match.Progress, rules.PushPerTap)
		ArmWrestleRules.tap(match, 2, 10)
		ArmWrestleRules.tap(match, 2, 10)
		expect.near(match.Progress, -rules.PushPerTap)
		expect.near(ArmWrestleRules.view(match.Progress, 2), rules.PushPerTap)
	end,
	["mashing faster than TapRate doesn't help"] = function()
		local match = pulling(0)
		local counted = 0
		for _ = 1, 50 do
			if ArmWrestleRules.tap(match, 1, 0) then
				counted += 1
			end
		end
		expect.equal(counted, rules.TapBurst)
		-- A second later the bucket has refilled up to its burst again, not 50 presses' worth.
		counted = 0
		for _ = 1, 50 do
			if ArmWrestleRules.tap(match, 1, 1) then
				counted += 1
			end
		end
		expect.equal(counted, rules.TapBurst)
	end,
	["a pin wins at once and crowns the champion"] = function()
		local match = pulling(0)
		local needed = math.ceil(1 / rules.PushPerTap - 1e-9)
		local event, t = presses(match, 1, needed - 1, 0)
		expect.equal(event, nil)
		expect.equal(match.State, "Pulling")
		event, t = presses(match, 1, 1, t)
		expect.equal(event, "Finished")
		expect.equal(match.State, "Result")
		expect.equal(match.Winner, 1)
		expect.equal(match.Progress, 1)
		expect.equal(match.Champion, 11)
		expect.equal(match.Streak, 1)
		-- Both still seated: the next countdown starts after the result, and a second win makes a streak.
		expect.equal(ArmWrestleRules.tick(match, t + rules.ResultTime), nil)
		expect.equal(match.State, "Countdown")
		ArmWrestleRules.tick(match, match.EndsAt)
		presses(match, 1, needed, match.EndsAt - rules.PullTime)
		expect.equal(match.Streak, 2)
	end,
	["a new winner takes the champion's place"] = function()
		local match = pulling(0)
		match.Champion, match.Streak = 11, 4
		presses(match, 2, math.ceil(1 / rules.PushPerTap - 1e-9), 0)
		expect.equal(match.Winner, 2)
		expect.equal(match.Progress, -1)
		expect.equal(match.Champion, 22)
		expect.equal(match.Streak, 1)
		ArmWrestleRules.forget(match, 11)
		expect.equal(match.Champion, 22)
		ArmWrestleRules.forget(match, 22)
		expect.equal(match.Champion, 0)
		expect.equal(match.Streak, 0)
	end,
	["time out: the side ahead wins; dead even is a draw"] = function()
		local match = pulling(0)
		presses(match, 2, 3, 0)
		expect.equal(ArmWrestleRules.tick(match, rules.PullTime), "Finished")
		expect.equal(match.Winner, 2)
		match = pulling(0)
		presses(match, 1, 2, 0)
		presses(match, 2, 2, 0)
		expect.equal(ArmWrestleRules.tick(match, rules.PullTime), "Finished")
		expect.equal(match.Winner, 0)
		expect.equal(match.Champion, 0)
	end,
	["standing up cancels a countdown or a pull; a result keeps showing"] = function()
		local match = ArmWrestleRules.new()
		ArmWrestleRules.seat(match, 1, 11, 0)
		ArmWrestleRules.seat(match, 2, 22, 0)
		expect.equal(ArmWrestleRules.seat(match, 2, 0, 1), "Cancelled")
		expect.equal(match.State, "Waiting")
		match = pulling(0)
		presses(match, 1, 4, 0)
		expect.equal(ArmWrestleRules.seat(match, 1, 0, 1), "Cancelled")
		expect.equal(match.State, "Waiting")
		expect.equal(match.Progress, 0)
		match = pulling(0)
		ArmWrestleRules.tick(match, rules.PullTime)
		expect.equal(ArmWrestleRules.seat(match, 1, 0, rules.PullTime + 1), nil)
		expect.equal(match.State, "Result")
		ArmWrestleRules.tick(match, match.EndsAt)
		expect.equal(match.State, "Waiting")
	end,
	["the pose leans the forearm toward the winner's left and stops shaking at a pin"] = function()
		local winning = ArmWrestle.sample(1, 0.37)
		local losing = ArmWrestle.sample(-1, 0.37)
		expect.truthy(winning.RightElbow[3] < -30, "winning: forearm to the left")
		expect.truthy(losing.RightElbow[3] > 30, "losing: forearm to the right")
		expect.near(winning.RightElbow[3], -losing.RightElbow[3])
		expect.truthy(winning.Waist[2] > 0 and losing.Waist[2] < 0, "the waist twists into the push")
		local even = ArmWrestle.sample(0, 0.37)
		expect.truthy(math.abs(even.RightElbow[3]) <= 2.5, "even: only a small tremble")
		expect.near(ArmWrestle.sample(5, 0).RightElbow[3], winning.RightElbow[3])
	end,
	["the numbers make sense"] = function()
		expect.truthy(rules.PushPerTap > 0 and rules.PushPerTap < 1, "push per press")
		expect.truthy(rules.TapRate > 0 and rules.TapBurst >= 1, "press rate")
		expect.truthy(rules.CountdownTime > 0 and rules.PullTime > 0 and rules.ResultTime > 0, "times")
		-- A quick finger (the rate) can pin an idle opponent well inside the pull.
		expect.truthy(1 / rules.PushPerTap / rules.TapRate < rules.PullTime, "a pin is possible in time")
	end,
}
