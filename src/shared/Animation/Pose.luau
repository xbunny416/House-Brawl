--!strict
--[[
	Pose — samples scripted animation clips (pure numbers, so Lune specs test it). A clip is a list of keys; each key
	gives some R15 joints an angle in degrees, applied Y·X·Z on the joint (X: a limb swings forward / the body tilts
	back; Y: turns left; Z: a right limb swings out to the right, a left limb with −Z to the left) and optionally an
	offset in studs (on Root it moves the whole body, e.g. a crouch). A joint the clip uses but a key leaves out is
	at rest (0) at that key.
	Easing: the curve used to reach a key from the one before — the key's Ease, else the clip's, else "Smooth".
	"Out" starts fast (strikes), "In" starts slow, "Back" overshoots a little and settles (snappy impacts), "Linear"
	keeps a constant speed (spins).
]]
export type Ease = "Smooth" | "Linear" | "In" | "Out" | "Back"
export type JointPose = { number } -- { x, y, z } degrees, then optionally { px, py, pz } studs
export type Key = { T: number, Pose: { [string]: JointPose }, Ease: Ease? }
export type Clip = {
	Duration: number,
	Loop: boolean?,
	Ease: Ease?,
	Keys: { Key },
}
export type Sample = { [string]: { number } } -- joint -> { x, y, z, px, py, pz }

local Pose = {}

-- The R15 Motor6Ds a clip may move (the names of the joints in a standard R15 rig).
Pose.Joints = {
	"Root",
	"Waist",
	"Neck",
	"RightShoulder",
	"RightElbow",
	"RightWrist",
	"LeftShoulder",
	"LeftElbow",
	"LeftWrist",
	"RightHip",
	"RightKnee",
	"RightAnkle",
	"LeftHip",
	"LeftKnee",
	"LeftAnkle",
}

local BACK = 1.70158 -- easeOutBack's overshoot constant (~10%)

-- Eases `alpha` (0..1) along a curve; 0 stays 0 and 1 stays 1.
function Pose.ease(kind: Ease, alpha: number): number
	if kind == "Linear" then
		return alpha
	elseif kind == "In" then
		return alpha * alpha * alpha
	elseif kind == "Out" then
		local rest = 1 - alpha
		return 1 - rest * rest * rest
	elseif kind == "Back" then
		local rest = alpha - 1
		return 1 + (BACK + 1) * rest * rest * rest + BACK * rest * rest
	end
	return alpha * alpha * (3 - 2 * alpha)
end

-- When the clip stops: `length` (a loop held for a while, e.g. a hitstun), else its Duration; loops never stop.
local function finishOf(clip: Clip, length: number?): number
	return length or (if clip.Loop then math.huge else clip.Duration)
end

-- The time inside the clip for `elapsed` seconds since it started: loops wrap, one-shots stop at the end.
function Pose.timeIn(clip: Clip, elapsed: number): number
	if clip.Loop then
		return elapsed % clip.Duration
	end
	return math.clamp(elapsed, 0, clip.Duration)
end

-- Every joint any key of the clip moves.
function Pose.jointsOf(clip: Clip): { [string]: boolean }
	local joints: { [string]: boolean } = {}
	for _, key in clip.Keys do
		for joint in key.Pose do
			joints[joint] = true
		end
	end
	return joints
end

-- Joint values `elapsed` seconds into the clip, for every joint the clip moves.
function Pose.sample(clip: Clip, elapsed: number): Sample
	local t = Pose.timeIn(clip, elapsed)
	local keys = clip.Keys
	local from, to = keys[1], keys[#keys]
	if t <= from.T then
		to = from
	elseif t < to.T then
		for index = 1, #keys - 1 do
			if t >= keys[index].T and t < keys[index + 1].T then
				from, to = keys[index], keys[index + 1]
				break
			end
		end
	else
		from = to
	end
	local span = to.T - from.T
	local alpha = if span > 0 then (t - from.T) / span else 0
	alpha = Pose.ease(to.Ease or clip.Ease or "Smooth", alpha)
	local result: Sample = {}
	for joint in Pose.jointsOf(clip) do
		local a, b = from.Pose[joint], to.Pose[joint]
		local values = table.create(6, 0)
		for index = 1, 6 do
			local start = if a then a[index] or 0 else 0
			local finish = if b then b[index] or 0 else 0
			values[index] = start + (finish - start) * alpha
		end
		result[joint] = values
	end
	return result
end

--[[
	How much the clip shows over the default animations `elapsed` seconds after it started (0..1): it blends in over
	`blend` seconds and, unless it loops forever, back out over the last `blend` seconds before it stops.
]]
function Pose.weight(clip: Clip, elapsed: number, blend: number, length: number?): number
	local finish = finishOf(clip, length)
	if elapsed < 0 or elapsed >= finish then
		return 0
	end
	if blend <= 0 then
		return 1
	end
	return math.clamp(math.min(elapsed / blend, (finish - elapsed) / blend), 0, 1)
end

function Pose.isOver(clip: Clip, elapsed: number, length: number?): boolean
	return elapsed >= finishOf(clip, length)
end

return Pose
