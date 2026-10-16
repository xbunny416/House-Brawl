--!strict
--[[
	Scripted R15 animations (bible §4.2: "Creator Store, Animation Capture, or scripted"). The clips themselves are pose
	data in Shared/Animation/Clips; these are the numbers around them. Which clips a fighting style uses is in
	Config.Styles.List[id].Animations; a victory emote's clip is its cosmetic's Emote field.
]]
type AnimationsConfig = {
	BlendTime: number,
	EmoteDelay: number,
	AssetIds: { [string]: number },
}

local Animations: AnimationsConfig = {
	BlendTime = 0.06, -- seconds a clip takes to blend in over (and out back to) the default walk / idle animations
	EmoteDelay = 1, -- seconds after a round ends before the winner's victory emote plays (they are back in the lobby)
	-- Optional uploaded animations, by clip name (e.g. Jab = 1234567890): played instead of the scripted pose once
	-- someone makes them in Studio's Animation Editor. Empty = every clip is scripted.
	AssetIds = {},
}

return Animations
