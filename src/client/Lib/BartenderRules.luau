--!strict
--[[
	BartenderRules — what the lobby's bartender says to the local player, and when (owner's fix list: "bartender
	phrases"; the owner dropped the animation, 2026-10-20). Pure (the Talk numbers from Config.World.Bartender are
	passed in), so Lune specs test it. BartenderController shows each line in a speech bubble over the bartender; only
	this player sees it.
	  * Walking within Distance greets you, at most once every GreetCooldown seconds. After a round you fought in, the
	    next time you are near you get a Won / Lost line instead (once).
	  * Opening the Shop near the bar says a Shop line; buying something there a Thanks line.
	  * Staying near says an Idle line every IdleEvery.Min–Max seconds, never over a line that is still showing.
	Lines are the GameStrings keys "Bartender.<Pool>.<n>"; a pool never says its last line twice in a row.
]]
export type Talk = {
	Distance: number,
	GreetCooldown: number,
	IdleEvery: { Min: number, Max: number },
	ReadTime: { Base: number, PerCharacter: number, Min: number, Max: number },
	Lines: { [string]: number },
}

export type State = {
	Near: boolean, -- near the bartender at the last check
	LastGreet: number, -- when the last greeting was said (os.clock), -math.huge for never
	NextIdle: number, -- when the next idle line is due
	BusyUntil: number, -- when the line on show ends
	Result: string?, -- "Won" / "Lost": the last round's outcome, said the next time the player is near
	Last: { [string]: number }, -- the last line said from each pool
}

local BartenderRules = {}

BartenderRules.Pools = { "Greet", "Idle", "Shop", "Thanks", "Won", "Lost" }
BartenderRules.Events = { "ShopOpened", "Bought" }

function BartenderRules.new(): State
	return { Near = false, LastGreet = -math.huge, NextIdle = math.huge, BusyUntil = -math.huge, Last = {} }
end

-- Seconds until the next idle line, for `roll` in [0, 1).
function BartenderRules.idleDelay(talk: Talk, roll: number): number
	return talk.IdleEvery.Min + (talk.IdleEvery.Max - talk.IdleEvery.Min) * math.clamp(roll, 0, 1)
end

-- Seconds a line of `length` characters stays on show.
function BartenderRules.readTime(talk: Talk, length: number): number
	local time = talk.ReadTime
	return math.clamp(time.Base + time.PerCharacter * length, time.Min, time.Max)
end

-- Records that a line `readTime` seconds long started at `now`: idle chatter waits for it, then IdleEvery more.
function BartenderRules.said(state: State, talk: Talk, now: number, readTime: number, roll: number)
	state.BusyUntil = now + readTime
	state.NextIdle = state.BusyUntil + BartenderRules.idleDelay(talk, roll)
end

-- The pool to say from at `now`, given whether the player is `near` (nil = nothing to say). Coming near greets (the
-- last round's result first); staying near brings idle chatter once it is due and nothing else is showing.
function BartenderRules.tick(state: State, talk: Talk, near: boolean, now: number): string?
	local arrived = near and not state.Near
	state.Near = near
	if not near then
		return nil
	end
	local result = state.Result
	if result then
		state.Result = nil
		state.LastGreet = now
		return result
	end
	if arrived then
		if now - state.LastGreet >= talk.GreetCooldown then
			state.LastGreet = now
			return "Greet"
		end
		-- No greeting this soon after the last one: chatter starts after a pause instead of at once.
		state.NextIdle = math.max(state.NextIdle, now + talk.IdleEvery.Min)
		return nil
	end
	if now >= state.NextIdle and now >= state.BusyUntil then
		return "Idle"
	end
	return nil
end

-- The pool for `event` ("ShopOpened" / "Bought"), or nil when the player isn't near the bartender.
function BartenderRules.react(event: string, near: boolean): string?
	if not near then
		return nil
	elseif event == "Bought" then
		return "Thanks"
	elseif event == "ShopOpened" then
		return "Shop"
	end
	return nil
end

-- Remembers how the player's round went ("Won" when they placed first), said the next time they are near.
function BartenderRules.roundEnded(state: State, placement: number)
	state.Result = if placement == 1 then "Won" else "Lost"
end

-- Which line of `pool` to say (1 … count) for `roll` in [0, 1): never the pool's last line again when it has more.
function BartenderRules.pick(state: State, pool: string, count: number, roll: number): number
	local last = state.Last[pool]
	local index: number
	if count <= 1 then
		index = 1
	elseif last and last >= 1 and last <= count then
		index = math.clamp(math.floor(math.clamp(roll, 0, 1) * (count - 1)) + 1, 1, count - 1)
		if index >= last then
			index += 1
		end
	else
		index = math.clamp(math.floor(math.clamp(roll, 0, 1) * count) + 1, 1, count)
	end
	state.Last[pool] = index
	return index
end

return BartenderRules
