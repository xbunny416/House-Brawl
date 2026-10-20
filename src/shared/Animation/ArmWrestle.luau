--!strict
--[[
	ArmWrestle — the seated arm-wrestling pose (the lobby table; AnimationController layers it while a character's
	ArmWrestle attribute is set). Pure, so specs test it. Same angle conventions as Shared/Animation/Pose: the right
	upper arm reaches forward and down so the elbow rests on the table and the forearm stands up to the clasp in the
	middle; the left hand rests on the table. `progress` is the wrestler's own view (1 = pinning the other hand, −1 =
	pinned): the forearm tilts toward the wrestler's left as they win (the clasped hands go down on the loser's side),
	the body twists into the push and leans in, and the arms tremble with effort while the match is close.
]]
local Pose = require(script.Parent.Pose)

local ArmWrestle = {}

local TILT = 65 -- degrees the forearm leans at a pin
local TWIST = 14 -- degrees the waist turns into the push at a pin
local TREMBLE = 2.5 -- degrees of shaking while the match is even
local TREMBLE_RATE = 9 -- shakes a second

function ArmWrestle.sample(progress: number, clock: number): Pose.Sample
	local push = math.clamp(progress, -1, 1)
	local shake = math.sin(clock * TREMBLE_RATE * 2 * math.pi) * TREMBLE * (1 - push * push)
	return {
		RightShoulder = { 55, 0, -8, 0, 0, 0 },
		RightElbow = { 110, 0, -TILT * push + shake, 0, 0, 0 },
		RightWrist = { -10, 0, 0, 0, 0, 0 },
		LeftShoulder = { 40, 0, 12, 0, 0, 0 },
		LeftElbow = { 75, 0, 0, 0, 0, 0 },
		Waist = { -12 + shake * 0.4, TWIST * push, 0, 0, 0, 0 },
		Neck = { -6, -TWIST * 0.5 * push, 0, 0, 0, 0 },
	}
end

return ArmWrestle
