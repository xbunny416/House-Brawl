--!strict
-- Scripted animations (step 2.6): clip data is well formed, matches the bible's lengths, every clip the game asks for
-- exists, and the pose sampler interpolates, loops and blends as documented.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local Clips = Roblox.require(Shared.Animation.Clips)
local Pose = Roblox.require(Shared.Animation.Pose)

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
				expect.truthy(key.T > last, `{name} key {index} out of order`)
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
		for _, name in { "Tumble", "Carry", "Charge" } do
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
}
