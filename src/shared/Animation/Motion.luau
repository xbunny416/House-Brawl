--!strict
--[[
	Motion — the always-on layer under every clip (pure, so specs test it): the body leans into where it is going
	(moving forward tilts it forward, strafing rolls it into the strafe) and, in the air, tucks its legs and spreads
	its arms. It also says how strongly the fighting stance shows (fully when standing still in a round, fading out
	as the character starts moving). Speeds are in the character's own space: Forward along its facing, Side to its
	right, Vertical up. Same angle conventions as Shared/Animation/Pose.
]]
local Config = require(script.Parent.Parent.Config)
local Pose = require(script.Parent.Pose)

local Motion = {}

local function settings()
	return Config.Animations.Motion
end

-- The lean (degrees) the body tilts toward: x forward / back (negative = forward), z sideways.
function Motion.lean(forward: number, side: number): (number, number)
	local motion = settings()
	local pitch = -math.clamp(forward / motion.FullSpeed, -1, 1) * motion.LeanDegrees
	local roll = -math.clamp(side / motion.FullSpeed, -1, 1) * motion.RollDegrees
	return pitch, roll
end

-- How much of the in-air pose shows (0..1) for a vertical speed, when off the ground.
function Motion.airWeight(vertical: number, airborne: boolean): number
	if not airborne then
		return 0
	end
	return math.clamp(math.abs(vertical) / settings().AirSpeed, 0, 1)
end

-- How strongly the fighting stance shows (0..1) at a horizontal speed.
function Motion.stanceWeight(speed: number): number
	return 1 - math.clamp(speed / settings().StanceSpeed, 0, 1)
end

-- The layer's joint values: the (already smoothed) lean on Root, plus the in-air pose scaled by `air`.
function Motion.sample(pitch: number, roll: number, air: number): Pose.Sample
	local sample: Pose.Sample = {
		Root = { pitch, 0, roll, 0, 0, 0 },
	}
	if air > 0 then
		sample.RightShoulder = { 25 * air, 0, 40 * air, 0, 0, 0 }
		sample.LeftShoulder = { 25 * air, 0, -40 * air, 0, 0, 0 }
		sample.RightHip = { 30 * air, 0, 0, 0, 0, 0 }
		sample.LeftHip = { 15 * air, 0, 0, 0, 0, 0 }
		sample.RightKnee = { -45 * air, 0, 0, 0, 0, 0 }
		sample.LeftKnee = { -30 * air, 0, 0, 0, 0, 0 }
	end
	return sample
end

return Motion
