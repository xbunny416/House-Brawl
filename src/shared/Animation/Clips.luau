--!strict
--[[
	Clips — the scripted R15 animations (bible §4.2), as pose keys for Shared/Animation/Pose (degrees: X forward /
	back, Y turn left, Z out to the side; Root offsets in studs). Lengths follow the bible: punch-chain hits 0.3 s,
	weapon swings 0.45 s, Shove 0.5 s, Dash 0.25 s, Grab 0.3 s, Throw 0.4 s, hit reaction / tumble 0.6 s (the tumble
	loops through a hitstun), victory emotes 2 s. Carry and ShoveCharge loop while their state lasts.
	Which clips a style uses: Config.Styles.List[id].Animations. Victory emotes: the cosmetic's Emote field.
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

-- Fists up in front of the chin.
local GUARD: PoseMap = {
	RightShoulder = { 60, 0, 15 },
	RightElbow = { 100, 0, 0 },
	LeftShoulder = { 60, 0, -15 },
	LeftElbow = { 100, 0, 0 },
}

-- Weapon held ready in the right hand, left hand by the chest.
local READY: PoseMap = {
	RightShoulder = { 45, 0, 20 },
	RightElbow = { 70, 0, 0 },
	LeftShoulder = { 50, 0, -15 },
	LeftElbow = { 90, 0, 0 },
}

-- Prop held up over the head with both hands.
local CARRY: PoseMap = {
	RightShoulder = { 165, 0, 12 },
	RightElbow = { 25, 0, 0 },
	LeftShoulder = { 165, 0, -12 },
	LeftElbow = { 25, 0, 0 },
	Waist = { 4, 0, 0 },
}

-- Arms pulled back, leaning back, knees bent: winding up a Shove.
local CHARGE: PoseMap = {
	RightShoulder = { 25, 0, 25 },
	RightElbow = { 125, 0, 0 },
	LeftShoulder = { 25, 0, -25 },
	LeftElbow = { 125, 0, 0 },
	Waist = { 12, 0, 0 },
	Root = { 0, 0, 0, 0, -0.3, 0 },
	RightKnee = { -20, 0, 0 },
	LeftKnee = { -20, 0, 0 },
}

-- A horizontal swing with the right hand: wind up on `fromSide` (+1 right, −1 left), sweep across at `height`
-- (shoulder X: 85 for a bat or wrench, 40 for a low shovel sweep).
local function swing(fromSide: number, height: number): Clip
	local wind = with(READY, {
		RightShoulder = { height, -70 * fromSide, 0 },
		RightElbow = { 35, 0, 0 },
		LeftShoulder = { height, -40 * fromSide, 0 },
		LeftElbow = { 60, 0, 0 },
		Waist = { 0, -35 * fromSide, 0 },
	})
	local follow = with(READY, {
		RightShoulder = { height, 65 * fromSide, 0 },
		RightElbow = { 10, 0, 0 },
		LeftShoulder = { height - 5, 70 * fromSide, 0 },
		LeftElbow = { 30, 0, 0 },
		Waist = { 0, 40 * fromSide, 0 },
	})
	return {
		Duration = 0.45,
		Keys = {
			{ T = 0, Pose = READY },
			{ T = 0.1, Pose = wind },
			{ T = 0.22, Pose = follow },
			{ T = 0.32, Pose = follow },
			{ T = 0.45, Pose = READY },
		},
	}
end

local Clips: { [string]: Clip } = {
	-- Punch chain (Brawler).
	Jab = {
		Duration = 0.3,
		Keys = {
			{ T = 0, Pose = GUARD },
			{
				T = 0.07,
				Pose = with(GUARD, { RightShoulder = { 90, 0, 5 }, RightElbow = { 5, 0, 0 }, Waist = { 0, 20, 0 } }),
			},
			{
				T = 0.16,
				Pose = with(GUARD, { RightShoulder = { 90, 0, 5 }, RightElbow = { 5, 0, 0 }, Waist = { 0, 20, 0 } }),
			},
			{ T = 0.3, Pose = GUARD },
		},
	},
	Cross = {
		Duration = 0.3,
		Keys = {
			{ T = 0, Pose = GUARD },
			{
				T = 0.07,
				Pose = with(GUARD, { LeftShoulder = { 90, 0, -5 }, LeftElbow = { 5, 0, 0 }, Waist = { 0, -25, 0 } }),
			},
			{
				T = 0.16,
				Pose = with(GUARD, { LeftShoulder = { 90, 0, -5 }, LeftElbow = { 5, 0, 0 }, Waist = { 0, -25, 0 } }),
			},
			{ T = 0.3, Pose = GUARD },
		},
	},
	Uppercut = {
		Duration = 0.3,
		Keys = {
			{ T = 0, Pose = GUARD },
			{
				T = 0.06,
				Pose = with(GUARD, {
					RightShoulder = { 20, 0, 10 },
					RightElbow = { 110, 0, 0 },
					Waist = { -10, 15, 0 },
					Root = { 0, 0, 0, 0, -0.5, 0 },
				}),
			},
			{
				T = 0.15,
				Pose = with(GUARD, {
					RightShoulder = { 155, 0, 5 },
					RightElbow = { 40, 0, 0 },
					Waist = { 8, -10, 0 },
					Root = { 0, 0, 0, 0, 0.2, 0 },
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
				T = 0.12,
				Pose = with(READY, {
					RightShoulder = { 175, 0, 0 },
					RightElbow = { 60, 0, 0 },
					LeftShoulder = { 170, 0, 0 },
					LeftElbow = { 60, 0, 0 },
					Waist = { 15, 0, 0 },
				}),
			},
			{
				T = 0.25,
				Pose = with(READY, {
					RightShoulder = { 55, 0, 0 },
					RightElbow = { 10, 0, 0 },
					LeftShoulder = { 55, 0, 0 },
					LeftElbow = { 15, 0, 0 },
					Waist = { -25, 0, 0 },
					Root = { 0, 0, 0, 0, -0.5, 0 },
				}),
			},
			{
				T = 0.33,
				Pose = with(READY, {
					RightShoulder = { 55, 0, 0 },
					RightElbow = { 10, 0, 0 },
					LeftShoulder = { 55, 0, 0 },
					LeftElbow = { 15, 0, 0 },
					Waist = { -25, 0, 0 },
					Root = { 0, 0, 0, 0, -0.5, 0 },
				}),
			},
			{ T = 0.45, Pose = READY },
		},
	},

	-- Shove: the charge loop while the button is held, then a two-hand push.
	ShoveCharge = {
		Duration = 0.6,
		Loop = true,
		Keys = {
			{ T = 0, Pose = CHARGE },
			{ T = 0.3, Pose = with(CHARGE, { Waist = { 16, 0, 0 } }) },
			{ T = 0.6, Pose = CHARGE },
		},
	},
	Shove = {
		Duration = 0.5,
		Keys = {
			{ T = 0, Pose = CHARGE },
			{
				T = 0.1,
				Pose = {
					RightShoulder = { 95, 0, 8 },
					RightElbow = { 0, 0, 0 },
					LeftShoulder = { 95, 0, -8 },
					LeftElbow = { 0, 0, 0 },
					Waist = { -15, 0, 0 },
					Root = { -8, 0, 0 },
				},
			},
			{
				T = 0.28,
				Pose = {
					RightShoulder = { 95, 0, 8 },
					RightElbow = { 0, 0, 0 },
					LeftShoulder = { 95, 0, -8 },
					LeftElbow = { 0, 0, 0 },
					Waist = { -15, 0, 0 },
					Root = { -8, 0, 0 },
				},
			},
			{ T = 0.5, Pose = GUARD },
		},
	},
	-- Wrecker: the hubcap shield (left hand) snaps up in front of the chest.
	Parry = {
		Duration = 0.3,
		Keys = {
			{ T = 0, Pose = READY },
			{
				T = 0.04,
				Pose = with(READY, { LeftShoulder = { 95, 35, 0 }, LeftElbow = { 85, 0, 0 }, Waist = { 0, -15, 0 } }),
			},
			{
				T = 0.2,
				Pose = with(READY, { LeftShoulder = { 95, 35, 0 }, LeftElbow = { 85, 0, 0 }, Waist = { 0, -15, 0 } }),
			},
			{ T = 0.3, Pose = READY },
		},
	},

	-- Movement.
	Dash = {
		Duration = 0.25,
		Keys = {
			{
				T = 0,
				Pose = {
					Root = { -25, 0, 0 },
					RightShoulder = { -45, 0, 15 },
					LeftShoulder = { -45, 0, -15 },
					RightElbow = { 20, 0, 0 },
					LeftElbow = { 20, 0, 0 },
				},
			},
			{
				T = 0.25,
				Pose = {
					Root = { -15, 0, 0 },
					RightShoulder = { -30, 0, 15 },
					LeftShoulder = { -30, 0, -15 },
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
				T = 0.12,
				Pose = {
					Root = { -20, 0, 0, 0, -1.2, 0 },
					RightHip = { 45, 0, 0 },
					LeftHip = { 45, 0, 0 },
					RightKnee = { -65, 0, 0 },
					LeftKnee = { -65, 0, 0 },
					RightShoulder = { 70, 0, 12 },
					LeftShoulder = { 70, 0, -12 },
					RightElbow = { 20, 0, 0 },
					LeftElbow = { 20, 0, 0 },
				},
			},
			{ T = 0.3, Pose = CARRY },
		},
	},
	Carry = {
		Duration = 1,
		Loop = true,
		Keys = {
			{ T = 0, Pose = CARRY },
			{ T = 0.5, Pose = with(CARRY, { Waist = { 7, 0, 0 } }) },
			{ T = 1, Pose = CARRY },
		},
	},
	Throw = {
		Duration = 0.4,
		Keys = {
			{
				T = 0,
				Pose = with(CARRY, {
					RightShoulder = { 190, 0, 10 },
					LeftShoulder = { 190, 0, -10 },
					RightElbow = { 60, 0, 0 },
					LeftElbow = { 60, 0, 0 },
					Waist = { 15, 0, 0 },
				}),
			},
			{
				T = 0.14,
				Pose = {
					RightShoulder = { 60, 0, 10 },
					LeftShoulder = { 60, 0, -10 },
					RightElbow = { 0, 0, 0 },
					LeftElbow = { 0, 0, 0 },
					Waist = { -25, 0, 0 },
					Root = { -10, 0, 0 },
				},
			},
			{ T = 0.4, Pose = GUARD },
		},
	},

	-- Getting hit: a short recoil, or a backflip tumble that loops through a long hitstun (a launch).
	Hit = {
		Duration = 0.6,
		Keys = {
			{ T = 0, Pose = {} },
			{
				T = 0.08,
				Pose = {
					Waist = { 22, 0, 0 },
					Neck = { 20, 0, 0 },
					Root = { 10, 0, 0 },
					RightShoulder = { 35, 0, 45 },
					LeftShoulder = { 35, 0, -45 },
					RightElbow = { 40, 0, 0 },
					LeftElbow = { 40, 0, 0 },
				},
			},
			{ T = 0.6, Pose = {} },
		},
	},
	Tumble = {
		Duration = 0.6,
		Loop = true,
		Ease = "Linear",
		Keys = {
			{
				T = 0,
				Pose = {
					Root = { 0, 0, 0 },
					RightShoulder = { 120, 0, 60 },
					LeftShoulder = { 120, 0, -60 },
					RightElbow = { 30, 0, 0 },
					LeftElbow = { 30, 0, 0 },
					RightHip = { 50, 0, 0 },
					LeftHip = { 50, 0, 0 },
					RightKnee = { -70, 0, 0 },
					LeftKnee = { -70, 0, 0 },
				},
			},
			{
				T = 0.3,
				Pose = {
					Root = { 180, 0, 0 },
					RightShoulder = { 120, 0, 60 },
					LeftShoulder = { 120, 0, -60 },
					RightElbow = { 30, 0, 0 },
					LeftElbow = { 30, 0, 0 },
					RightHip = { 50, 0, 0 },
					LeftHip = { 50, 0, 0 },
					RightKnee = { -70, 0, 0 },
					LeftKnee = { -70, 0, 0 },
				},
			},
			{
				T = 0.6,
				Pose = {
					Root = { 360, 0, 0 },
					RightShoulder = { 120, 0, 60 },
					LeftShoulder = { 120, 0, -60 },
					RightElbow = { 30, 0, 0 },
					LeftElbow = { 30, 0, 0 },
					RightHip = { 50, 0, 0 },
					LeftHip = { 50, 0, 0 },
					RightKnee = { -70, 0, 0 },
					LeftKnee = { -70, 0, 0 },
				},
			},
		},
	},

	-- Victory emotes (2 s each), played by the round winner (and as a preview when equipped in the Locker).
	Flex = {
		Duration = 2,
		Keys = {
			{ T = 0, Pose = {} },
			{
				T = 0.3,
				Pose = {
					RightShoulder = { 15, 0, 95 },
					LeftShoulder = { 15, 0, -95 },
					RightElbow = { 120, 0, 0 },
					LeftElbow = { 120, 0, 0 },
					Waist = { 5, 0, 0 },
				},
			},
			{
				T = 0.9,
				Pose = {
					RightShoulder = { 15, 0, 95 },
					LeftShoulder = { 15, 0, -95 },
					RightElbow = { 130, 0, 0 },
					LeftElbow = { 130, 0, 0 },
					Waist = { 5, 18, 0 },
				},
			},
			{
				T = 1.5,
				Pose = {
					RightShoulder = { 15, 0, 95 },
					LeftShoulder = { 15, 0, -95 },
					RightElbow = { 130, 0, 0 },
					LeftElbow = { 130, 0, 0 },
					Waist = { 5, -18, 0 },
				},
			},
			{ T = 2, Pose = {} },
		},
	},
	JunkDance = {
		Duration = 2,
		Keys = {
			{ T = 0, Pose = {} },
			{
				T = 0.25,
				Pose = {
					RightShoulder = { 150, 0, 20 },
					LeftShoulder = { 30, 0, -20 },
					Waist = { 0, 20, 0 },
					Root = { 0, 0, 8, 0, -0.3, 0 },
				},
			},
			{
				T = 0.5,
				Pose = {
					RightShoulder = { 30, 0, 20 },
					LeftShoulder = { 150, 0, -20 },
					Waist = { 0, -20, 0 },
					Root = { 0, 0, -8, 0, 0, 0 },
				},
			},
			{
				T = 0.75,
				Pose = {
					RightShoulder = { 150, 0, 20 },
					LeftShoulder = { 30, 0, -20 },
					Waist = { 0, 20, 0 },
					Root = { 0, 0, 8, 0, -0.3, 0 },
				},
			},
			{
				T = 1,
				Pose = {
					RightShoulder = { 30, 0, 20 },
					LeftShoulder = { 150, 0, -20 },
					Waist = { 0, -20, 0 },
					Root = { 0, 0, -8, 0, 0, 0 },
				},
			},
			{
				T = 1.25,
				Pose = {
					RightShoulder = { 150, 0, 20 },
					LeftShoulder = { 30, 0, -20 },
					Waist = { 0, 20, 0 },
					Root = { 0, 0, 8, 0, -0.3, 0 },
				},
			},
			{
				T = 1.5,
				Pose = {
					RightShoulder = { 30, 0, 20 },
					LeftShoulder = { 150, 0, -20 },
					Waist = { 0, -20, 0 },
					Root = { 0, 0, -8, 0, 0, 0 },
				},
			},
			{ T = 2, Pose = {} },
		},
	},
	Taunt = {
		Duration = 2,
		Keys = {
			{ T = 0, Pose = {} },
			{
				T = 0.3,
				Pose = {
					RightShoulder = { 90, 0, 0 },
					RightElbow = { 0, 0, 0 },
					Waist = { 10, 0, 0 },
					Neck = { 10, 0, 0 },
				},
			},
			{
				T = 0.6,
				Pose = {
					RightShoulder = { 90, 0, 0 },
					RightElbow = { 80, 0, 0 },
					Waist = { 10, 0, 0 },
					Neck = { 10, 0, 0 },
				},
			},
			{
				T = 0.9,
				Pose = {
					RightShoulder = { 90, 0, 0 },
					RightElbow = { 0, 0, 0 },
					Waist = { 10, 0, 0 },
					Neck = { 10, 0, 0 },
				},
			},
			{
				T = 1.2,
				Pose = {
					RightShoulder = { 90, 0, 0 },
					RightElbow = { 80, 0, 0 },
					Waist = { 10, 0, 0 },
					Neck = { 10, 0, 0 },
				},
			},
			{
				T = 1.6,
				Pose = {
					RightShoulder = { 0, 0, 30 },
					LeftShoulder = { 0, 0, -30 },
					Waist = { 12, 0, 0 },
					Neck = { 15, 20, 0 },
				},
			},
			{ T = 2, Pose = {} },
		},
	},
	Champion = {
		Duration = 2,
		Keys = {
			{ T = 0, Pose = {} },
			{
				T = 0.3,
				Pose = {
					RightShoulder = { 170, 0, 30 },
					LeftShoulder = { 170, 0, -30 },
					Neck = { 15, 0, 0 },
					Root = { 0, 0, 0, 0, 0.6, 0 },
				},
			},
			{
				T = 0.6,
				Pose = {
					RightShoulder = { 170, 0, 30 },
					LeftShoulder = { 170, 0, -30 },
					Neck = { 15, 0, 0 },
					Root = { 0, 0, 0, 0, 0, 0 },
				},
			},
			{
				T = 0.9,
				Pose = {
					RightShoulder = { 170, 0, 30 },
					LeftShoulder = { 170, 0, -30 },
					Neck = { 15, 0, 0 },
					Root = { 0, 0, 0, 0, 0.6, 0 },
				},
			},
			{
				T = 1.2,
				Pose = {
					RightShoulder = { 170, 0, 30 },
					LeftShoulder = { 170, 0, -30 },
					Neck = { 15, 0, 0 },
					Root = { 0, 0, 0, 0, 0, 0 },
				},
			},
			{
				T = 1.7,
				Pose = {
					RightShoulder = { 170, 0, 30 },
					LeftShoulder = { 170, 0, -30 },
					Neck = { 15, 0, 0 },
				},
			},
			{ T = 2, Pose = {} },
		},
	},
}

return Clips
