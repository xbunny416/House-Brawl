--!strict
--[[
	Clips — the scripted R15 animations (bible §4.2), as pose keys for Shared/Animation/Pose (degrees: X forward /
	back, Y turn left, Z out to the side; Root offsets in studs, −Z is forward). Lengths follow the bible: punch-chain
	hits 0.3 s, weapon swings 0.45 s, charged punch / swing 0.5 s, Dash 0.25 s, Grab 0.3 s, Throw 0.4 s, hit
	reactions / tumble 0.6 s (the tumble loops through a hitstun), victory emotes 2 s. Carry, Charge and Stance loop.
	Every attack is built the same way so it reads as a hit: a short wind-up the other way ("Out"), a fast strike that
	overshoots and settles ("Back"), a hold, then a smooth recovery; the whole body joins in (the hips turn, the
	root lunges and dips, the head follows, a foot steps). Hits recoil away from the attacker (HitFront / HitBack /
	HitLeft / HitRight). Which clips a style uses: Config.Styles.List[id].Animations. Victory emotes: the cosmetic's
	Emote field.
]]
local Pose = require(script.Parent.Pose)

type Clip = Pose.Clip
type PoseMap = { [string]: Pose.JointPose }

-- Copies `base` with `changes` on top (keeps clip data short).
local function with(base: PoseMap, changes: PoseMap?): PoseMap
	local merged = table.clone(base)
	if changes then
		for joint, value in changes do
			merged[joint] = value
		end
	end
	return merged
end

-- Fists up in front of the chin, knees soft.
local GUARD: PoseMap = {
	RightShoulder = { 65, 0, 20 },
	RightElbow = { 110, 0, 0 },
	LeftShoulder = { 70, 0, -20 },
	LeftElbow = { 115, 0, 0 },
	Neck = { -4, 0, 0 },
	RightKnee = { -10, 0, 0 },
	LeftKnee = { -10, 0, 0 },
}

-- Weapon held ready in the right hand, left hand by the chest.
local READY: PoseMap = {
	RightShoulder = { 45, 0, 25 },
	RightElbow = { 75, 0, 0 },
	LeftShoulder = { 55, 0, -15 },
	LeftElbow = { 95, 0, 0 },
	RightKnee = { -10, 0, 0 },
	LeftKnee = { -10, 0, 0 },
}

-- Prop held up over the head with both hands.
local CARRY: PoseMap = {
	RightShoulder = { 165, 0, 14 },
	RightElbow = { 25, 0, 0 },
	LeftShoulder = { 165, 0, -14 },
	LeftElbow = { 25, 0, 0 },
	Waist = { 6, 0, 0 },
}

-- Winding up a charged punch: body coiled to the right, right fist (or weapon) cocked back by the shoulder, left
-- hand guarding, knees bent low.
local CHARGE: PoseMap = {
	RightShoulder = { -30, -20, 40 },
	RightElbow = { 115, 0, 0 },
	LeftShoulder = { 75, 0, -20 },
	LeftElbow = { 100, 0, 0 },
	Waist = { 10, -40, 0 },
	Neck = { 0, 30, 0 },
	Root = { -6, 0, 0, 0, -0.7, 0.35 },
	RightHip = { 30, 0, 0 },
	RightKnee = { -50, 0, 0 },
	LeftHip = { -10, 0, 0 },
	LeftKnee = { -25, 0, 0 },
}

-- A straight punch with `side` (+1 right hand, −1 left hand): wind up, snap out with the hips and a lunge, hold, back
-- to guard.
local function straight(side: number): Clip
	local hand = if side > 0 then "Right" else "Left"
	local other = if side > 0 then "Left" else "Right"
	local wind = with(GUARD, {
		[`{hand}Shoulder`] = { 50, 0, 25 * side },
		[`{hand}Elbow`] = { 125, 0, 0 },
		Waist = { 0, -12 * side, 0 },
		Root = { 0, 0, 0, 0, -0.15, 0.15 },
	})
	local strike = with(GUARD, {
		[`{hand}Shoulder`] = { 93, 6 * side, 0 },
		[`{hand}Elbow`] = { 0, 0, 0 },
		[`{other}Shoulder`] = { 50, 0, -25 * side },
		[`{other}Elbow`] = { 120, 0, 0 },
		Waist = { -8, 28 * side, 0 },
		Neck = { -2, -14 * side, 0 },
		Root = { -8, 0, 0, 0, -0.2, -0.6 },
		[`{other}Hip`] = { 25, 0, 0 },
		[`{other}Knee`] = { -25, 0, 0 },
	})
	return {
		Duration = 0.3,
		Keys = {
			{ T = 0, Pose = GUARD },
			{ T = 0.04, Pose = wind, Ease = "Out" },
			{ T = 0.1, Pose = strike, Ease = "Back" },
			{ T = 0.17, Pose = strike },
			{ T = 0.3, Pose = GUARD },
		},
	}
end

-- A horizontal swing with the right hand: wind up on `fromSide` (+1 right, −1 left), sweep across at `height`
-- (shoulder X: 85 for a bat or wrench, 40 for a low shovel sweep).
local function swing(fromSide: number, height: number): Clip
	local wind = with(READY, {
		RightShoulder = { height, -80 * fromSide, 0 },
		RightElbow = { 40, 0, 0 },
		LeftShoulder = { height, -45 * fromSide, 0 },
		LeftElbow = { 65, 0, 0 },
		Waist = { 4, -45 * fromSide, 0 },
		Neck = { 0, 20 * fromSide, 0 },
		Root = { 0, 0, 0, 0, -0.25, 0.2 },
	})
	local follow = with(READY, {
		RightShoulder = { height, 75 * fromSide, 0 },
		RightElbow = { 8, 0, 0 },
		LeftShoulder = { height - 5, 80 * fromSide, 0 },
		LeftElbow = { 30, 0, 0 },
		Waist = { -6, 50 * fromSide, 0 },
		Neck = { 0, -20 * fromSide, 0 },
		Root = { -6, 0, 0, 0, -0.3, -0.5 },
		LeftHip = { 25, 0, 0 },
		LeftKnee = { -30, 0, 0 },
	})
	return {
		Duration = 0.45,
		Keys = {
			{ T = 0, Pose = READY },
			{ T = 0.12, Pose = wind, Ease = "Out" },
			{ T = 0.2, Pose = follow, Ease = "Back" },
			{ T = 0.3, Pose = follow },
			{ T = 0.45, Pose = READY },
		},
	}
end

-- Recoil after a hit that came from `pitch` / `roll`: degrees the body is thrown (positive pitch = backwards, positive
-- roll = to its left) and how far the root is pushed (`push`, studs along Z: positive = backwards).
local function recoil(pitch: number, roll: number, push: number): Clip
	local hit: PoseMap = {
		Waist = { pitch * 1.2, 0, roll },
		Neck = { pitch * 1.3, 0, roll * 0.8 },
		Root = { pitch * 0.6, 0, roll * 0.6, 0, -0.2, push },
		RightShoulder = { 40, 0, 55 },
		LeftShoulder = { 40, 0, -55 },
		RightElbow = { 45, 0, 0 },
		LeftElbow = { 45, 0, 0 },
		RightKnee = { -20, 0, 0 },
		LeftKnee = { -20, 0, 0 },
	}
	local sway: PoseMap = {
		Waist = { -pitch * 0.3, 0, -roll * 0.3 },
		Neck = { -pitch * 0.2, 0, 0 },
		Root = { -pitch * 0.15, 0, -roll * 0.15, 0, -0.1, push * 0.3 },
		RightShoulder = { 30, 0, 25 },
		LeftShoulder = { 30, 0, -25 },
		RightElbow = { 60, 0, 0 },
		LeftElbow = { 60, 0, 0 },
	}
	return {
		Duration = 0.6,
		Keys = {
			{ T = 0, Pose = {} },
			{ T = 0.06, Pose = hit, Ease = "Back" },
			{ T = 0.26, Pose = sway },
			{ T = 0.6, Pose = {} },
		},
	}
end

-- One beat of a dance / cheer, repeated: `poses` alternate every `beat` seconds over `duration`.
local function beats(poses: { PoseMap }, beat: number, duration: number): Clip
	local keys: { Pose.Key } = { { T = 0, Pose = {} } }
	local t, index = beat, 1
	while t < duration - beat * 0.5 do
		table.insert(keys, { T = t, Pose = poses[index], Ease = "Out" })
		index = index % #poses + 1
		t += beat
	end
	table.insert(keys, { T = duration, Pose = {} })
	return { Duration = duration, Keys = keys }
end

local TUCK: PoseMap = {
	RightShoulder = { 120, 0, 60 },
	LeftShoulder = { 120, 0, -60 },
	RightElbow = { 40, 0, 0 },
	LeftElbow = { 40, 0, 0 },
	RightHip = { 70, 0, 0 },
	LeftHip = { 70, 0, 0 },
	RightKnee = { -90, 0, 0 },
	LeftKnee = { -90, 0, 0 },
	Neck = { -20, 0, 0 },
}

local Clips: { [string]: Clip } = {
	-- Punch chain (Brawler).
	Jab = straight(1),
	Cross = straight(-1),
	Uppercut = {
		Duration = 0.3,
		Keys = {
			{ T = 0, Pose = GUARD },
			{
				T = 0.06,
				Ease = "Out",
				Pose = with(GUARD, {
					RightShoulder = { 15, 0, 15 },
					RightElbow = { 125, 0, 0 },
					Waist = { -18, 22, 0 },
					Root = { -6, 0, 0, 0, -0.7, 0 },
					RightKnee = { -45, 0, 0 },
					LeftKnee = { -45, 0, 0 },
				}),
			},
			{
				T = 0.14,
				Ease = "Back",
				Pose = with(GUARD, {
					RightShoulder = { 165, 0, 0 },
					RightElbow = { 35, 0, 0 },
					Waist = { 14, -18, 0 },
					Neck = { 18, 0, 0 },
					Root = { 6, 0, 0, 0, 0.45, -0.4 },
					RightKnee = { 0, 0, 0 },
					LeftKnee = { -5, 0, 0 },
				}),
			},
			{
				T = 0.2,
				Pose = with(GUARD, {
					RightShoulder = { 160, 0, 0 },
					RightElbow = { 40, 0, 0 },
					Waist = { 12, -15, 0 },
					Neck = { 15, 0, 0 },
					Root = { 5, 0, 0, 0, 0.35, -0.35 },
				}),
			},
			{ T = 0.3, Pose = GUARD },
		},
	},

	-- Weapon chains (Slugger bat, Wrecker wrench: Swing; Scrapper shovel: low Sweep; all end on an overhead Smash).
	SwingRight = swing(1, 85),
	SwingLeft = swing(-1, 85),
	SweepRight = swing(1, 40),
	SweepLeft = swing(-1, 40),
	Smash = {
		Duration = 0.45,
		Keys = {
			{ T = 0, Pose = READY },
			{
				T = 0.14,
				Ease = "Out",
				Pose = with(READY, {
					RightShoulder = { 185, 0, 0 },
					RightElbow = { 70, 0, 0 },
					LeftShoulder = { 175, 0, 0 },
					LeftElbow = { 70, 0, 0 },
					Waist = { 20, 0, 0 },
					Neck = { 15, 0, 0 },
					Root = { 4, 0, 0, 0, 0.2, 0.3 },
				}),
			},
			{
				T = 0.22,
				Ease = "Back",
				Pose = with(READY, {
					RightShoulder = { 50, 0, 0 },
					RightElbow = { 5, 0, 0 },
					LeftShoulder = { 50, 0, 0 },
					LeftElbow = { 15, 0, 0 },
					Waist = { -30, 0, 0 },
					Neck = { -10, 0, 0 },
					Root = { -10, 0, 0, 0, -0.8, -0.7 },
					LeftHip = { 35, 0, 0 },
					LeftKnee = { -50, 0, 0 },
					RightKnee = { -40, 0, 0 },
				}),
			},
			{
				T = 0.32,
				Pose = with(READY, {
					RightShoulder = { 55, 0, 0 },
					RightElbow = { 10, 0, 0 },
					LeftShoulder = { 55, 0, 0 },
					LeftElbow = { 20, 0, 0 },
					Waist = { -26, 0, 0 },
					Root = { -8, 0, 0, 0, -0.7, -0.6 },
					LeftHip = { 30, 0, 0 },
					LeftKnee = { -45, 0, 0 },
					RightKnee = { -35, 0, 0 },
				}),
			},
			{ T = 0.45, Pose = READY },
		},
	},

	-- Charged punch: the wind-up loop while the attack is held (it trembles as power builds), then the hit.
	Charge = {
		Duration = 0.2,
		Loop = true,
		Keys = {
			{ T = 0, Pose = CHARGE },
			{ T = 0.1, Pose = with(CHARGE, { Waist = { 12, -44, 0 }, Root = { -6, 0, 0, 0, -0.78, 0.38 } }) },
			{ T = 0.2, Pose = CHARGE },
		},
	},
	-- Fists: the body uncoils into a lunging straight right.
	PowerPunch = {
		Duration = 0.5,
		Keys = {
			{ T = 0, Pose = CHARGE },
			{
				T = 0.08,
				Ease = "Back",
				Pose = {
					RightShoulder = { 95, 12, 0 },
					RightElbow = { 0, 0, 0 },
					LeftShoulder = { 15, 0, -35 },
					LeftElbow = { 110, 0, 0 },
					Waist = { -20, 50, 0 },
					Neck = { 5, -24, 0 },
					Root = { -16, 0, 0, 0, -0.35, -1.4 },
					RightHip = { -30, 0, 0 },
					RightKnee = { -10, 0, 0 },
					LeftHip = { 50, 0, 0 },
					LeftKnee = { -45, 0, 0 },
				},
			},
			{
				T = 0.26,
				Pose = {
					RightShoulder = { 92, 10, 0 },
					RightElbow = { 5, 0, 0 },
					LeftShoulder = { 20, 0, -35 },
					LeftElbow = { 105, 0, 0 },
					Waist = { -16, 45, 0 },
					Neck = { 5, -20, 0 },
					Root = { -13, 0, 0, 0, -0.3, -1.2 },
					RightHip = { -25, 0, 0 },
					LeftHip = { 45, 0, 0 },
					LeftKnee = { -40, 0, 0 },
				},
			},
			{ T = 0.5, Pose = GUARD },
		},
	},
	-- Weapons: a full two-hand swing from the cocked-back wind-up across the body.
	PowerSwing = {
		Duration = 0.5,
		Keys = {
			{ T = 0, Pose = CHARGE },
			{
				T = 0.09,
				Ease = "Back",
				Pose = {
					RightShoulder = { 85, 80, 0 },
					RightElbow = { 8, 0, 0 },
					LeftShoulder = { 80, 85, 0 },
					LeftElbow = { 25, 0, 0 },
					Waist = { -14, 60, 0 },
					Neck = { 0, -28, 0 },
					Root = { -12, 0, 0, 0, -0.45, -1 },
					LeftHip = { 40, 0, 0 },
					LeftKnee = { -40, 0, 0 },
				},
			},
			{
				T = 0.27,
				Pose = {
					RightShoulder = { 80, 75, 0 },
					RightElbow = { 15, 0, 0 },
					LeftShoulder = { 75, 80, 0 },
					LeftElbow = { 30, 0, 0 },
					Waist = { -10, 52, 0 },
					Neck = { 0, -24, 0 },
					Root = { -9, 0, 0, 0, -0.4, -0.8 },
					LeftHip = { 32, 0, 0 },
					LeftKnee = { -32, 0, 0 },
				},
			},
			{ T = 0.5, Pose = READY },
		},
	},
	-- Wrecker: the hubcap shield (left hand) snaps up in front of the chest.
	Parry = {
		Duration = 0.3,
		Keys = {
			{ T = 0, Pose = READY },
			{
				T = 0.05,
				Ease = "Back",
				Pose = with(READY, {
					LeftShoulder = { 100, 40, 0 },
					LeftElbow = { 90, 0, 0 },
					Waist = { 6, -20, 0 },
					Neck = { -6, 0, 0 },
					Root = { 0, 0, 0, 0, -0.35, 0.2 },
					RightKnee = { -30, 0, 0 },
					LeftKnee = { -30, 0, 0 },
				}),
			},
			{
				T = 0.2,
				Pose = with(READY, {
					LeftShoulder = { 98, 38, 0 },
					LeftElbow = { 90, 0, 0 },
					Waist = { 5, -18, 0 },
					Root = { 0, 0, 0, 0, -0.3, 0.15 },
					RightKnee = { -25, 0, 0 },
					LeftKnee = { -25, 0, 0 },
				}),
			},
			{ T = 0.3, Pose = READY },
		},
	},

	-- The fighting stance while standing still in a round: guard up, a light bounce on the knees.
	Stance = {
		Duration = 0.8,
		Loop = true,
		Keys = {
			{ T = 0, Pose = with(GUARD, { Root = { 0, 0, 0, 0, -0.1, 0 } }) },
			{
				T = 0.4,
				Pose = with(GUARD, {
					Root = { 0, 0, 0, 0, -0.28, 0 },
					RightKnee = { -22, 0, 0 },
					LeftKnee = { -22, 0, 0 },
					RightShoulder = { 62, 0, 22 },
					LeftShoulder = { 67, 0, -22 },
				}),
			},
			{ T = 0.8, Pose = with(GUARD, { Root = { 0, 0, 0, 0, -0.1, 0 } }) },
		},
	},

	-- Movement.
	Dash = {
		Duration = 0.25,
		Keys = {
			{ T = 0, Pose = {} },
			{
				T = 0.05,
				Ease = "Out",
				Pose = {
					Root = { -30, 0, 0, 0, -0.3, 0 },
					Waist = { -10, 0, 0 },
					RightShoulder = { -55, 0, 20 },
					LeftShoulder = { -55, 0, -20 },
					RightElbow = { 25, 0, 0 },
					LeftElbow = { 25, 0, 0 },
					RightHip = { 35, 0, 0 },
					LeftHip = { -25, 0, 0 },
					RightKnee = { -50, 0, 0 },
					LeftKnee = { -20, 0, 0 },
				},
			},
			{
				T = 0.25,
				Pose = {
					Root = { -14, 0, 0 },
					RightShoulder = { -25, 0, 15 },
					LeftShoulder = { -25, 0, -15 },
					RightElbow = { 20, 0, 0 },
					LeftElbow = { 20, 0, 0 },
				},
			},
		},
	},

	-- Props: crouch and lift, carry loop, overhead throw.
	Grab = {
		Duration = 0.3,
		Keys = {
			{ T = 0, Pose = {} },
			{
				T = 0.11,
				Ease = "Out",
				Pose = {
					Root = { -22, 0, 0, 0, -1.3, 0 },
					Waist = { -10, 0, 0 },
					RightHip = { 50, 0, 0 },
					LeftHip = { 50, 0, 0 },
					RightKnee = { -75, 0, 0 },
					LeftKnee = { -75, 0, 0 },
					RightShoulder = { 70, 0, 14 },
					LeftShoulder = { 70, 0, -14 },
					RightElbow = { 15, 0, 0 },
					LeftElbow = { 15, 0, 0 },
				},
			},
			{ T = 0.3, Pose = CARRY, Ease = "Back" },
		},
	},
	Carry = {
		Duration = 0.9,
		Loop = true,
		Keys = {
			{ T = 0, Pose = CARRY },
			{ T = 0.45, Pose = with(CARRY, { Waist = { 9, 0, 0 }, Root = { 0, 0, 0, 0, -0.15, 0 } }) },
			{ T = 0.9, Pose = CARRY },
		},
	},
	Throw = {
		Duration = 0.4,
		Keys = {
			{ T = 0, Pose = CARRY },
			{
				T = 0.1,
				Ease = "Out",
				Pose = with(CARRY, {
					RightShoulder = { 200, 0, 12 },
					LeftShoulder = { 200, 0, -12 },
					RightElbow = { 70, 0, 0 },
					LeftElbow = { 70, 0, 0 },
					Waist = { 22, 0, 0 },
					Neck = { 12, 0, 0 },
					Root = { 6, 0, 0, 0, -0.1, 0.4 },
					LeftHip = { 25, 0, 0 },
				}),
			},
			{
				T = 0.18,
				Ease = "Back",
				Pose = {
					RightShoulder = { 55, 0, 12 },
					LeftShoulder = { 55, 0, -12 },
					RightElbow = { 0, 0, 0 },
					LeftElbow = { 0, 0, 0 },
					Waist = { -30, 0, 0 },
					Neck = { -8, 0, 0 },
					Root = { -14, 0, 0, 0, -0.4, -0.7 },
					LeftHip = { 40, 0, 0 },
					LeftKnee = { -40, 0, 0 },
					RightHip = { -15, 0, 0 },
				},
			},
			{ T = 0.4, Pose = GUARD },
		},
	},

	-- Getting hit: a recoil away from the attacker, or a backflip tumble that loops through a long hitstun.
	Hit = recoil(26, 0, 0.6), -- from the front: thrown back
	HitBack = recoil(-24, 0, -0.6), -- from behind: thrown forward
	HitLeft = recoil(6, -24, 0), -- from the left: thrown to the right
	HitRight = recoil(6, 24, 0), -- from the right: thrown to the left
	Tumble = {
		Duration = 0.6,
		Loop = true,
		Ease = "Linear",
		Keys = {
			{ T = 0, Pose = with(TUCK, { Root = { 0, 0, 0 } }) },
			{ T = 0.3, Pose = with(TUCK, { Root = { 180, 0, 0 } }) },
			{ T = 0.6, Pose = with(TUCK, { Root = { 360, 0, 0 } }) },
		},
	},

	-- Victory emotes (2 s each), played by the round winner (and as a preview when equipped in the Locker).
	Flex = beats({
		{
			RightShoulder = { 10, 0, 95 },
			LeftShoulder = { 10, 0, -95 },
			RightElbow = { 125, 0, 0 },
			LeftElbow = { 125, 0, 0 },
			Waist = { 8, 20, 0 },
			Root = { 0, 0, 0, 0, -0.25, 0 },
		},
		{
			RightShoulder = { 20, 0, 85 },
			LeftShoulder = { 20, 0, -85 },
			RightElbow = { 140, 0, 0 },
			LeftElbow = { 140, 0, 0 },
			Waist = { 8, -20, 0 },
			Neck = { 10, 0, 0 },
			Root = { 0, 0, 0, 0, 0, 0 },
		},
	}, 0.45, 2),
	JunkDance = beats({
		{
			RightShoulder = { 160, 0, 20 },
			LeftShoulder = { 25, 0, -30 },
			RightElbow = { 30, 0, 0 },
			Waist = { 0, 25, 0 },
			Root = { 0, 0, 10, 0, -0.35, 0 },
			RightKnee = { -30, 0, 0 },
			LeftHip = { 20, 0, 0 },
		},
		{
			RightShoulder = { 25, 0, 30 },
			LeftShoulder = { 160, 0, -20 },
			LeftElbow = { 30, 0, 0 },
			Waist = { 0, -25, 0 },
			Root = { 0, 0, -10, 0, 0, 0 },
			LeftKnee = { -30, 0, 0 },
			RightHip = { 20, 0, 0 },
		},
	}, 0.25, 2),
	Taunt = beats({
		{ RightShoulder = { 90, 10, 0 }, RightElbow = { 0, 0, 0 }, Waist = { 12, 0, 0 }, Neck = { 12, 0, 0 } },
		{ RightShoulder = { 90, 10, 0 }, RightElbow = { 90, 0, 0 }, Waist = { 14, 5, 0 }, Neck = { 14, 10, 0 } },
	}, 0.3, 2),
	Champion = beats({
		{
			RightShoulder = { 175, 0, 30 },
			LeftShoulder = { 175, 0, -30 },
			RightElbow = { 10, 0, 0 },
			LeftElbow = { 10, 0, 0 },
			Neck = { 18, 0, 0 },
			Root = { 0, 0, 0, 0, 0.8, 0 },
		},
		{
			RightShoulder = { 160, 0, 40 },
			LeftShoulder = { 160, 0, -40 },
			RightElbow = { 30, 0, 0 },
			LeftElbow = { 30, 0, 0 },
			Neck = { 10, 0, 0 },
			Root = { 0, 0, 0, 0, -0.3, 0 },
			RightKnee = { -35, 0, 0 },
			LeftKnee = { -35, 0, 0 },
		},
	}, 0.3, 2),
}

return Clips
