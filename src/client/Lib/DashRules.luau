--!strict
--[[
	DashRules — when the local player may dash (pure logic for DashController and Lune specs).
	Every dash waits for the cooldown. In the air (a jump, a fall or a launch) only AirDashesPerJump dashes are
	allowed until the character lands; ground dashes have no such limit. The server re-checks the cooldown and
	hitstun before it grants the dash's invulnerability.
]]
export type State = {
	NextDashAt: number,
	AirDashesUsed: number,
}

export type DashConfig = {
	Cooldown: number,
	AirDashesPerJump: number,
}

local DashRules = {}

function DashRules.new(): State
	return { NextDashAt = 0, AirDashesUsed = 0 }
end

-- Uses a dash if one is allowed now. Returns false (and changes nothing) otherwise.
function DashRules.tryDash(state: State, now: number, airborne: boolean, dash: DashConfig): boolean
	if now < state.NextDashAt or (airborne and state.AirDashesUsed >= dash.AirDashesPerJump) then
		return false
	end
	state.NextDashAt = now + dash.Cooldown
	if airborne then
		state.AirDashesUsed += 1
	end
	return true
end

-- The character touched the ground: air dashes are available again.
function DashRules.landed(state: State)
	state.AirDashesUsed = 0
end

-- Seconds until the next dash is allowed (0 when ready).
function DashRules.cooldownLeft(state: State, now: number): number
	return math.max(state.NextDashAt - now, 0)
end

return DashRules
