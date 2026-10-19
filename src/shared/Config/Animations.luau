--!strict
--[[
	Scripted R15 animations (bible §4.2: "Creator Store, Animation Capture, or scripted"). The clips themselves are pose
	data in Shared/Animation/Clips; these are the numbers around them. Which clips a fighting style uses is in
	Config.Styles.List[id].Animations.
]]
type AnimationsConfig = {
	BlendTime: number,
	HitStop: { Light: number, Heavy: number },
	Motion: {
		LeanDegrees: number,
		RollDegrees: number,
		FullSpeed: number,
		AirSpeed: number,
		Smoothing: number,
		StanceSpeed: number,
	},
	AssetIds: { [string]: number },
}

local Animations: AnimationsConfig = {
	BlendTime = 0.06, -- seconds a clip takes to blend in over (and out back to) the default walk / idle animations
	-- On every landed hit the attacker's and the victim's poses freeze this long ("hit-stop": it sells the impact).
	HitStop = { Light = 0.05, Heavy = 0.09 },
	-- The always-on layer under every clip (Shared/Animation/Motion), from how each character moves.
	Motion = {
		LeanDegrees = 12, -- forward tilt when running forward at FullSpeed (half of it at walking speed)
		RollDegrees = 8, -- sideways tilt into a strafe at FullSpeed
		FullSpeed = 24, -- studs/s: running speed
		AirSpeed = 6, -- vertical studs/s above which the in-air pose (legs tucked, arms out) shows fully
		Smoothing = 10, -- how quickly the lean follows the movement (higher = snappier)
		StanceSpeed = 6, -- studs/s: the fists-up fighting stance (in a round) fades out between standing and this
	},
	-- Optional uploaded animations, by clip name (e.g. Jab = 1234567890): played instead of the scripted pose once
	-- someone makes them in Studio's Animation Editor. Empty = every clip is scripted.
	AssetIds = {},
}

return Animations
