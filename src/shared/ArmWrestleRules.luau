--!strict
--[[
	ArmWrestleRules — one arm-wrestling table in the lobby (owner's fix list: "arm-wrestling minigame in the lobby";
	Config.World.ArmWrestle). Pure, so Lune specs test it; ArmWrestleService runs one Match per table and mirrors it
	onto the table's attributes, which the client draws (ArmWrestleController).
	  * Waiting until both seats are taken, then a Countdown, then the Pull: each accepted press moves Progress
	    PushPerTap toward the presser's side (side 1 pushes it up to 1, side 2 down to −1). Presses are counted up to
	    TapRate a second per side (a token bucket holding TapBurst), so mashing faster than that doesn't help.
	  * Reaching ±1 wins at once; when PullTime runs out the side ahead wins, dead even is a draw (Winner 0).
	  * The Result shows ResultTime seconds; then the next countdown starts if both are still seated.
	  * Standing up during a countdown or a pull cancels the match (no result).
	  * The table's champion: the last winner, with how many wins in a row they have at this table.
	A side holds a UserId (0 = empty seat; ArmWrestleRules.Bot = the developer panel's practice bot).
]]
local Config = require(script.Parent.Config)

export type State = "Waiting" | "Countdown" | "Pulling" | "Result"
type Bucket = { Tokens: number, At: number }

export type Match = {
	State: State,
	Players: { number }, -- side (1 / 2) → UserId, 0 = an empty seat
	Progress: number, -- −1 … 1, positive = side 1 ahead
	EndsAt: number, -- when the countdown, the pull or the result ends
	Winner: number, -- in Result: the winning side, 0 = a draw
	Champion: number, -- UserId of the table's champion, 0 = none
	Streak: number, -- the champion's wins in a row at this table
	Buckets: { [number]: Bucket },
}

local ArmWrestleRules = {}

ArmWrestleRules.States = { "Waiting", "Countdown", "Pulling", "Result" }
ArmWrestleRules.Bot = -1
local EVEN = 1e-6 -- Progress closer to 0 than this is dead even

local function settings()
	return Config.World.ArmWrestle
end

function ArmWrestleRules.new(): Match
	return {
		State = "Waiting",
		Players = { 0, 0 },
		Progress = 0,
		EndsAt = 0,
		Winner = 0,
		Champion = 0,
		Streak = 0,
		Buckets = {},
	}
end

local function bothSeated(match: Match): boolean
	return match.Players[1] ~= 0 and match.Players[2] ~= 0
end

local function reset(match: Match, state: State, endsAt: number)
	match.State = state
	match.EndsAt = endsAt
	match.Progress = 0
	match.Winner = 0
	match.Buckets = {}
end

local function finish(match: Match, winner: number, now: number)
	match.State = "Result"
	match.EndsAt = now + settings().ResultTime
	match.Winner = winner
	if winner ~= 0 then
		match.Progress = if winner == 1 then 1 else -1
		local userId = match.Players[winner]
		if match.Champion == userId then
			match.Streak += 1
		else
			match.Champion = userId
			match.Streak = 1
		end
	end
end

-- `side`'s progress as that side sees it: 1 = winning outright, −1 = beaten.
function ArmWrestleRules.view(progress: number, side: number): number
	return if side == 1 then progress else -progress
end

-- Someone sat down on `side` (their UserId) or stood up (0) at `now`. Returns "Cancelled" when that stopped a
-- countdown or a pull.
function ArmWrestleRules.seat(match: Match, side: number, userId: number, now: number): string?
	match.Players[side] = userId
	if bothSeated(match) then
		if match.State == "Waiting" then
			reset(match, "Countdown", now + settings().CountdownTime)
		end
		return nil
	elseif match.State == "Countdown" or match.State == "Pulling" then
		reset(match, "Waiting", 0)
		return "Cancelled"
	end
	return nil -- a result keeps showing; tick goes back to Waiting after it
end

-- A press from `side` at `now`. Returns whether it counted, and "Finished" when it won the match.
function ArmWrestleRules.tap(match: Match, side: number, now: number): (boolean, string?)
	if match.State ~= "Pulling" or match.Players[side] == 0 then
		return false, nil
	end
	local rules = settings()
	local bucket = match.Buckets[side]
	if bucket == nil then
		bucket = { Tokens = rules.TapBurst, At = now }
		match.Buckets[side] = bucket
	end
	bucket.Tokens = math.min(rules.TapBurst, bucket.Tokens + math.max(now - bucket.At, 0) * rules.TapRate)
	bucket.At = now
	if bucket.Tokens < 1 then
		return false, nil
	end
	bucket.Tokens -= 1
	local toward = if side == 1 then 1 else -1
	match.Progress = math.clamp(match.Progress + toward * rules.PushPerTap, -1, 1)
	if math.abs(match.Progress) >= 1 - EVEN then
		finish(match, side, now)
		return true, "Finished"
	end
	return true, nil
end

-- Moves the match on at `now`: "Started" when a pull begins, "Finished" when time runs out on one.
function ArmWrestleRules.tick(match: Match, now: number): string?
	if match.State == "Countdown" and now >= match.EndsAt then
		reset(match, "Pulling", now + settings().PullTime)
		return "Started"
	elseif match.State == "Pulling" and now >= match.EndsAt then
		local progress = match.Progress
		finish(match, if progress > EVEN then 1 elseif progress < -EVEN then 2 else 0, now)
		return "Finished"
	elseif match.State == "Result" and now >= match.EndsAt then
		if bothSeated(match) then
			reset(match, "Countdown", now + settings().CountdownTime)
		else
			reset(match, "Waiting", 0)
		end
	end
	return nil
end

-- The champion left the server: the table has no champion until the next win.
function ArmWrestleRules.forget(match: Match, userId: number)
	if match.Champion == userId then
		match.Champion = 0
		match.Streak = 0
	end
end

return ArmWrestleRules
