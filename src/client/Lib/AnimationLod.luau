--!strict
--[[
	AnimationLod — how often a character's scripted pose is updated, so low-end devices don't pose every character
	every frame (numbers: Config.Performance.AnimationLod). Pure, so Lune specs test it.
]]
export type Settings = {
	Near: number,
	Far: number,
	Cull: number,
	FarEvery: number,
	OffscreenEvery: number,
	LowGraphicsScale: number,
}

local AnimationLod = {}

--[[
	Frames between two updates of a character `distance` studs from the camera (1 = every frame), or nil when it is too
	far to pose at all. `onScreen`: whether it is in view; `own`: the local player's character (always every frame).
	Low Graphics shrinks every distance by LowGraphicsScale.
]]
function AnimationLod.interval(
	distance: number,
	onScreen: boolean,
	lowGraphics: boolean,
	own: boolean,
	settings: Settings
): number?
	if own then
		return 1
	end
	local scale = if lowGraphics then settings.LowGraphicsScale else 1
	if distance > settings.Cull * scale then
		return nil
	end
	if not onScreen or distance > settings.Far * scale then
		return settings.OffscreenEvery
	end
	if distance > settings.Near * scale then
		return settings.FarEvery
	end
	return 1
end

return AnimationLod
