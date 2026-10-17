--!strict
-- Scripted animations (step 2.6): clip data is well formed, matches the bible's lengths, every clip the game asks for
-- exists, and the pose sampler interpolates, loops and blends as documented.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local Clips = Roblox.require(Shared.Animation.Clips)
local Pose = Roblox.require(Shared.Animation.Pose)
local Motion = Roblox.require(Shared.Animation.Motion)

local function near(actual: number, wanted: number, label: string)
	expect.truthy(math.abs(actual - wanted) < 1e-6, `{label}: {actual} ~= {wanted}`)
end

local TEST_CLIP = {
	Duration = 1,
	Keys = {
		{ T = 0, Pose = { RightShoulder = { 0, 0, 0 }, Root = { 0, 0, 0, 0, 0, 0 } } },
		{ T = 0.5, Pose = { RightShoulder = { 90, 10, 0 } } },
		{ T = 1, Pose = { RightShoulder = { 0, 0, 0 }, Root = { 0, 0, 0, 0, -1, 0 } } },
	},
}

return {
	["every clip is well formed: keys from 0, in order, known joints, 3 or 6 numbers"] = function()
		for name, clip in Clips do
			expect.truthy(clip.Duration > 0, `{name} duration`)
			expect.truthy(#clip.Keys >= 2, `{name} needs at least two keys`)
			expect.equal(clip.Keys[1].T, 0, `{name} starts at 0`)
			local last = -1
			for index, key in clip.Keys do
				-- Equal times are allowed: the clip snaps from one key to the next (Backflip: 180° → −180°).
				expect.truthy(key.T >= last, `{name} key {index} out of order`)
				expect.truthy(key.T <= clip.Duration, `{name} key {index} after the end`)
				last = key.T
				for joint, values in key.Pose do
					expect.truthy(table.find(Pose.Joints, joint), `{name}: unknown joint {joint}`)
					expect.truthy(#values == 3 or #values == 6, `{name} {joint}: {#values} numbers`)
				end
			end
		end
	end,
	["clip lengths match the bible (§4.2)"] = function()
		local lengths = {
			Jab = 0.3,
			Cross = 0.3,
			Uppercut = 0.3,
			SwingRight = 0.45,
			SwingLeft = 0.45,
			SweepRight = 0.45,
			SweepLeft = 0.45,
			Smash = 0.45,
			PowerPunch = 0.5,
			PowerSwing = 0.5,
			Dash = 0.25,
			Grab = 0.3,
			Throw = 0.4,
			Hit = 0.6,
			HitBack = 0.6,
			HitLeft = 0.6,
			HitRight = 0.6,
			Tumble = 0.6,
			Flex = 2,
			JunkDance = 2,
			Taunt = 2,
			Champion = 2,
		}
		for name, length in lengths do
			expect.truthy(Clips[name], `{name} exists`)
			expect.equal(Clips[name].Duration, length, name)
		end
		for _, name in { "Tumble", "Carry", "Charge", "Stance" } do
			expect.equal(Clips[name].Loop, true, `{name} loops`)
		end
	end,
	["every style names one clip per punch-chain hit, a charged clip, and an Ability clip if it has an ability"] = function()
		for styleId, style in Config.Styles.List do
			expect.equal(#style.Animations.Punch, Config.Combat.Attacks.Punch.ChainLength, `{styleId} chain`)
			for _, clip in style.Animations.Punch do
				expect.truthy(Clips[clip], `{styleId}: clip {clip}`)
			end
			expect.truthy(Clips[style.Animations.Charged], `{styleId}: clip {style.Animations.Charged}`)
			local abilityClip = style.Animations.Ability
			expect.equal(abilityClip ~= nil, style.Ability ~= nil, `{styleId} ability clip`)
			if abilityClip then
				expect.truthy(Clips[abilityClip], `{styleId}: clip {abilityClip}`)
			end
		end
	end,
	["every victory emote cosmetic has a 2 s clip; uploaded ids only for known clips"] = function()
		for itemId, item in Config.Cosmetics.Items do
			if item.Slot == "VictoryEmote" then
				local clip = item.Emote and Clips[item.Emote]
				expect.truthy(clip, `{itemId} clip`)
				expect.equal(clip.Duration, 2, `{itemId} length`)
			end
		end
		for clipName in Config.Animations.AssetIds do
			expect.truthy(Clips[clipName], `asset id for unknown clip {clipName}`)
		end
	end,
	["two keys at the same time snap: the backflip turns 0 → 180, −180 → 0 and ends upright"] = function()
		local flip = Clips.Backflip
		expect.near(Pose.sample(flip, 0.7499).Root[1], 180, 1, "just before the top")
		expect.near(Pose.sample(flip, 0.75).Root[1], -180, 0.001, "at the top")
		expect.near(Pose.sample(flip, 0.9).Root[1], -108, 0.001, "on the way down")
		expect.near(Pose.sample(flip, flip.Duration).Root[1], 0, 0.001, "upright at the end")
	end,
	["sample: key values at key times, eased in between, missing joints at rest"] = function()
		local atKey = Pose.sample(TEST_CLIP, 0.5)
		near(atKey.RightShoulder[1], 90, "shoulder X at the middle key")
		near(atKey.RightShoulder[2], 10, "shoulder Y at the middle key")
		near(atKey.Root[5], 0, "root is at rest in a key that leaves it out")
		local quarter = Pose.sample(TEST_CLIP, 0.25)
		near(quarter.RightShoulder[1], 45, "smoothstep is halfway at the middle of a span")
		local early = Pose.sample(TEST_CLIP, 0.125)
		expect.truthy(early.RightShoulder[1] < 22.5, "smoothstep starts slow")
		local done = Pose.sample(TEST_CLIP, 5)
		near(done.Root[5], -1, "a one-shot holds its last key")
	end,
	["sample: a linear loop wraps (the tumble turns a full flip per loop)"] = function()
		local tumble = Clips.Tumble
		near(Pose.sample(tumble, 0.15).Root[1], 90, "quarter flip")
		near(Pose.sample(tumble, 0.75).Root[1], 90, "wraps after one loop")
		near(Pose.sample(tumble, 0.3).Root[1], 180, "half flip")
		near(tumble.Keys[#tumble.Keys].Pose.Root[1], 360, "ends a whole turn round: upright")
	end,
	["weight: blends in and out of one-shots; held loops stop at their length"] = function()
		local blend = 0.1
		near(Pose.weight(TEST_CLIP, 0, blend), 0, "start")
		near(Pose.weight(TEST_CLIP, 0.05, blend), 0.5, "blending in")
		near(Pose.weight(TEST_CLIP, 0.5, blend), 1, "middle")
		near(Pose.weight(TEST_CLIP, 0.95, blend), 0.5, "blending out")
		near(Pose.weight(TEST_CLIP, 1, blend), 0, "over")
		expect.equal(Pose.isOver(TEST_CLIP, 1), true)
		expect.equal(Pose.isOver(TEST_CLIP, 0.99), false)
		local tumble = Clips.Tumble
		near(Pose.weight(tumble, 5, blend), 1, "a loop with no length goes on")
		expect.equal(Pose.isOver(tumble, 1000), false)
		near(Pose.weight(tumble, 1.0, blend, 1.2), 1, "held loop, inside its length")
		near(Pose.weight(tumble, 1.15, blend, 1.2), 0.5, "held loop, blending out")
		expect.equal(Pose.isOver(tumble, 1.2, 1.2), true)
	end,
	["easing: every curve starts at 0 and ends at 1; Out is fast early, In slow, Back overshoots"] = function()
		for _, kind in { "Smooth", "Linear", "In", "Out", "Back" } do
			near(Pose.ease(kind :: any, 0), 0, `{kind} at 0`)
			near(Pose.ease(kind :: any, 1), 1, `{kind} at 1`)
		end
		expect.truthy(Pose.ease("Out", 0.3) > 0.3, "Out starts fast")
		expect.truthy(Pose.ease("In", 0.3) < 0.3, "In starts slow")
		local peak = 0
		for step = 1, 99 do
			peak = math.max(peak, Pose.ease("Back", step / 100))
		end
		expect.truthy(peak > 1 and peak < 1.2, `Back overshoots a little ({peak})`)
	end,
	["a key's own easing wins over the clip's"] = function()
		local clip = {
			Duration = 1,
			Ease = "Linear",
			Keys = {
				{ T = 0, Pose = { Neck = { 0, 0, 0 } } },
				{ T = 1, Pose = { Neck = { 100, 0, 0 } }, Ease = "Out" },
			},
		}
		expect.truthy(Pose.sample(clip :: any, 0.3).Neck[1] > 30, "Out on the key, not the clip's Linear")
	end,
	["attacks wind up, then strike with an overshoot"] = function()
		for _, name in { "Jab", "Cross", "Uppercut", "SwingRight", "Smash", "PowerPunch", "PowerSwing", "Throw" } do
			local struck = false
			for _, key in Clips[name].Keys do
				if key.Ease == "Back" then
					struck = true
				end
			end
			expect.truthy(struck, `{name} has a snappy ("Back") strike`)
		end
	end,
	["motion: lean forward when running forward, roll into a strafe, more at full speed"] = function()
		local settings = Config.Animations.Motion
		local pitch, roll = Motion.lean(settings.FullSpeed, 0)
		near(pitch, -settings.LeanDegrees, "full forward lean")
		near(roll, 0, "no roll going straight")
		local walkPitch = Motion.lean(settings.FullSpeed / 2, 0)
		near(walkPitch, -settings.LeanDegrees / 2, "half at half speed")
		local _, strafeRoll = Motion.lean(0, settings.FullSpeed * 3)
		near(strafeRoll, -settings.RollDegrees, "capped roll strafing right")
		local backPitch = Motion.lean(-settings.FullSpeed, 0)
		near(backPitch, settings.LeanDegrees, "leans back walking backwards")
	end,
	["motion: the air pose shows off the ground with speed; stance fades out as the fighter moves"] = function()
		local settings = Config.Animations.Motion
		near(Motion.airWeight(50, false), 0, "on the ground")
		near(Motion.airWeight(settings.AirSpeed / 2, true), 0.5, "half")
		near(Motion.airWeight(-settings.AirSpeed * 3, true), 1, "falling fast")
		near(Motion.stanceWeight(0), 1, "standing still")
		near(Motion.stanceWeight(settings.StanceSpeed), 0, "moving")
		local sample = Motion.sample(-5, 3, 0)
		near(sample.Root[1], -5, "lean on the root")
		expect.equal(sample.RightKnee, nil, "no air pose on the ground")
		expect.truthy(Motion.sample(0, 0, 1).RightKnee ~= nil, "knees tuck in the air")
	end,
}
