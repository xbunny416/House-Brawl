--!strict
--[[
	MoverRules — how an arena's moving parts move (owner, 2026-10-20: "more dynamic … moving parts"). Pure, shared:
	every client moves the movers itself from the server clock (MoverController: smooth, nothing sent over the
	network) and the server works out where a hazard is from the same numbers (MoverService). A mover is a model in
	the arena's Movers folder with a "Pivot" part and these attributes:
	  * Kind "Lift" / "Slide": travels by Offset (a Vector3 from where it rests) and back: waits Pause seconds at each
	    end, eases between them, Period seconds for the whole round trip.
	  * Kind "Swing": swings ±Angle degrees about its Pivot's X or Z axis (Axis), Period seconds per back-and-forth.
	  * Kind "Spin": turns round and round about its Pivot's up axis, Period seconds a turn (the lobby's ceiling fans,
	    owner 2026-10-28: "more dynamic").
	  * Phase: seconds added to the clock, so movers of one kind don't all move together.
]]
export type Params = {
	Kind: string,
	Period: number,
	Pause: number,
	Offset: Vector3?,
	Angle: number,
	Axis: string,
	Phase: number,
}

local MoverRules = {}

MoverRules.Kinds = { "Lift", "Slide", "Swing", "Spin" }

-- Smooth start and stop between 0 and 1.
local function ease(alpha: number): number
	local a = math.clamp(alpha, 0, 1)
	return a * a * (3 - 2 * a)
end

-- How far along its Offset a Lift / Slide is at time `t` (0 at rest, 1 at the far end).
function MoverRules.travel(period: number, pause: number, t: number): number
	local travel = math.max(period / 2 - pause, 0.01)
	local u = t % period
	if u < pause then
		return 0
	elseif u < pause + travel then
		return ease((u - pause) / travel)
	elseif u < 2 * pause + travel then
		return 1
	end
	return 1 - ease((u - 2 * pause - travel) / travel)
end

-- A Swing's angle (degrees) at time `t`.
function MoverRules.swing(angle: number, period: number, t: number): number
	return angle * math.sin(2 * math.pi * t / period)
end

-- A Spin's angle (degrees, 0 up to 360) at time `t`.
function MoverRules.spin(period: number, t: number): number
	return (t % period) / period * 360
end

-- Where a mover's pivot is at time `t`, given where it rests.
function MoverRules.pivotAt(params: Params, rest: CFrame, t: number): CFrame
	local time = t + params.Phase
	if params.Kind == "Spin" then
		return rest * CFrame.Angles(0, math.rad(MoverRules.spin(params.Period, time)), 0)
	elseif params.Kind == "Swing" then
		local angle = math.rad(MoverRules.swing(params.Angle, params.Period, time))
		return rest * (if params.Axis == "X" then CFrame.Angles(angle, 0, 0) else CFrame.Angles(0, 0, angle))
	end
	local offset = params.Offset or Vector3.zero
	return rest + offset * MoverRules.travel(params.Period, params.Pause, time)
end

-- A mover's attributes read off its model (missing ones take safe defaults).
function MoverRules.read(model: Instance): Params
	local function number(name: string, default: number): number
		local value = model:GetAttribute(name)
		return if type(value) == "number" then value else default
	end
	local offset = model:GetAttribute("Offset")
	local kind = model:GetAttribute("Kind")
	local axis = model:GetAttribute("Axis")
	return {
		Kind = if type(kind) == "string" then kind else "Slide",
		Period = math.max(number("Period", 8), 0.5),
		Pause = math.max(number("Pause", 0), 0),
		Offset = if typeof(offset) == "Vector3" then offset else nil,
		Angle = number("Angle", 0),
		Axis = if axis == "X" then "X" else "Z",
		Phase = number("Phase", 0),
	}
end

return MoverRules
