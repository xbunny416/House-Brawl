--!strict
-- CameraShake — the offset of one camera shake over time (pure math for CameraController and Lune specs).

local CameraShake = {}

-- math.noise rarely goes past ±0.5, so it is doubled (then clamped) to use the full magnitude.
local NOISE_GAIN = 2
-- Each axis reads the noise at its own offset so they wobble independently.
local AXIS_SEEDS = { 0, 57.31, 113.7, 171.9 }

local function wobble(seed: number, t: number): number
	return math.clamp(math.noise(seed, t) * NOISE_GAIN, -1, 1)
end

-- How strong a shake is `elapsed` seconds in: 1 at the start, easing to 0 at `duration` (0 outside it).
local function fade(elapsed: number, duration: number): number
	if elapsed < 0 or elapsed >= duration then
		return 0
	end
	return (1 - elapsed / duration) ^ 2
end

--[[
	Sideways (x) and vertical (y) camera offset in studs, `elapsed` seconds into a shake. Smooth noise at `frequency`
	wobbles per second, fading out over `duration`; never larger than `magnitude` on either axis.
	`seed` picks the wobble pattern (use a non-integer so the noise does not start at 0).
]]
function CameraShake.offset(
	elapsed: number,
	duration: number,
	magnitude: number,
	frequency: number,
	seed: number
): (number, number)
	local amplitude = magnitude * fade(elapsed, duration)
	if amplitude <= 0 then
		return 0, 0
	end
	local t = elapsed * frequency
	return wobble(seed + AXIS_SEEDS[1], t) * amplitude, wobble(seed + AXIS_SEEDS[2], t) * amplitude
end

-- Pitch and roll tilt in degrees for the same shake, never larger than `maxDegrees` on either axis.
function CameraShake.tilt(
	elapsed: number,
	duration: number,
	maxDegrees: number,
	frequency: number,
	seed: number
): (number, number)
	local amplitude = maxDegrees * fade(elapsed, duration)
	if amplitude <= 0 then
		return 0, 0
	end
	local t = elapsed * frequency
	return wobble(seed + AXIS_SEEDS[3], t) * amplitude, wobble(seed + AXIS_SEEDS[4], t) * amplitude
end

return CameraShake
