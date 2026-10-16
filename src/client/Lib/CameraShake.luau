--!strict
-- CameraShake — the offset of one camera shake over time (pure math for CameraController and Lune specs).

local CameraShake = {}

-- math.noise rarely goes past ±0.5, so it is doubled (then clamped) to use the full magnitude.
local NOISE_GAIN = 2

local function wobble(seed: number, t: number): number
	return math.clamp(math.noise(seed, t) * NOISE_GAIN, -1, 1)
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
	if elapsed < 0 or elapsed >= duration or magnitude <= 0 then
		return 0, 0
	end
	local fade = (1 - elapsed / duration) ^ 2
	local t = elapsed * frequency
	local amplitude = magnitude * fade
	return wobble(seed, t) * amplitude, wobble(seed + 57.31, t) * amplitude
end

return CameraShake
