--!strict
--[[
	AnimationController — plays the scripted R15 animations (Shared/Animation) on every character this client sees.
	Each frame before rendering, every joint a layer uses is turned through its rest offset (Motor6D.C0, or an
	AnimationConstraint's Attachment0). Roblox's default walk / idle animations never touch those, so they keep
	playing on top and nothing races them. Nothing replicates: every client poses every character from the same
	signals. Layers, bottom to top:
	  1. Motion (always, Shared/Animation/Motion): the body leans into its movement and tucks up in the air.
	  2. Stance: fists up while standing still in a round (fades out as the fighter moves).
	  3. A state loop from replicated attributes: Charge while Charging is set, Carry while HeldProp is set (blends in
	     and out).
	     Arm wrestling at the lobby table (Shared/Animation/ArmWrestle) while ArmWrestle is set, following the match.
	  4. One-shots: the server's Animate event (punch chain / weapon swings, charged punch, parry, grab, throw, victory
	     emotes, other players' dashes); the local dash (DashController.Dashed, no round trip); hits from CombatHit (a
	     recoil away from the attacker, or a tumble looping through a long hitstun).
	Hit-stop: a landed hit freezes the attacker's and the victim's clips for Config.Animations.HitStop seconds.
	When a layer lets go of a joint, the joint goes back to its rest offset. A clip with an uploaded animation in
	Config.Animations.AssetIds plays that animation instead (its Animation template in ReplicatedStorage.Assets.
	Animations, loaded onto the Animator). Studio: Config.Dev.LogAnimations prints each rig found and every clip started.
	Performance (step 3.11): other characters far from the camera or off screen are posed only every few frames, and
	not at all past Config.Performance.AnimationLod.Cull (Lib/AnimationLod; closer under Low Graphics).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local animationTemplates = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Animations")
local Net = require(Shared:WaitForChild("Net"))
local ArmWrestle = require(Shared:WaitForChild("Animation"):WaitForChild("ArmWrestle"))
local Clips = require(Shared:WaitForChild("Animation"):WaitForChild("Clips"))
local Motion = require(Shared:WaitForChild("Animation"):WaitForChild("Motion"))
local Pose = require(Shared:WaitForChild("Animation"):WaitForChild("Pose"))

local AnimationLod = require(script.Parent.Parent:WaitForChild("Lib"):WaitForChild("AnimationLod"))
local DashController = require(script.Parent:WaitForChild("DashController"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

local DUMMY_TAG = "TrainingDummy"
local RIG_RETRY = 1 -- seconds between looks for the joints of a character that is not (fully) streamed in yet

-- R6 joint names → the R15 names the clips use (R6 has no waist, elbows, wrists, knees or ankles).
local R6_JOINTS: { [string]: string } = {
	RootJoint = "Root",
	Neck = "Neck",
	["Right Shoulder"] = "RightShoulder",
	["Left Shoulder"] = "LeftShoulder",
	["Right Hip"] = "RightHip",
	["Left Hip"] = "LeftHip",
}

-- One joint a clip can turn: a Motor6D (through C0) or an AnimationConstraint (through its parent-side
-- Attachment0); `Rest` is that offset before anything turned it.
type Joint = { Motor: Motor6D?, Attachment: Attachment?, Constraint: AnimationConstraint?, Rest: CFrame }

type Playing = { Clip: Pose.Clip, Name: string, StartedAt: number, Length: number? }
type Layer = { Sample: Pose.Sample, Weight: number }
type Rig = {
	Joints: { [string]: Joint },
	Posed: { [string]: boolean }, -- joints a layer turned last frame
	Clock: number, -- this character's animation time: stands still during hit-stop
	LastFrame: number,
	FrozenUntil: number,
	Pitch: number, -- smoothed Motion lean
	Roll: number,
	StanceWeight: number, -- smoothed
	WrestleWeight: number, -- smoothed: how much the arm-wrestling pose shows
	WrestleProgress: number, -- smoothed ArmWrestle attribute
	OneShot: Playing?,
	Loop: Playing?,
	Fading: Playing?, -- the loop that just ended, blending out
	FadeStartedAt: number,
	Tracks: { [string]: AnimationTrack },
	Phase: number, -- spreads characters updated every few frames over different frames
}

local AnimationController = {}

local rigs: { [Model]: Rig } = {}
local retryAt: { [Model]: number } = {}

local function now(): number
	return os.clock()
end

local function log(message: string)
	if RunService:IsStudio() and Config.Dev.LogAnimations then
		print(`[Anim] {message}`)
	end
end

-- The clip joint name an instance stands for (R15 names as they are, R6 names mapped), or nil.
local function clipJointOf(instance: Instance): string?
	if table.find(Pose.Joints, instance.Name) then
		return instance.Name
	end
	return R6_JOINTS[instance.Name]
end

local function findJoints(character: Model): { [string]: Joint }
	local joints: { [string]: Joint } = {}
	for _, descendant in character:GetDescendants() do
		local name = clipJointOf(descendant)
		local current = name and joints[name]
		if name and (current == nil or current.Motor == nil) then
			if descendant:IsA("Motor6D") then
				joints[name] = { Motor = descendant, Rest = descendant.C0 }
			elseif current == nil and descendant:IsA("AnimationConstraint") and descendant.Attachment0 then
				local attachment = descendant.Attachment0 :: Attachment
				joints[name] = { Attachment = attachment, Constraint = descendant, Rest = attachment.CFrame }
			end
		end
	end
	return joints
end

-- Studio diagnostics: what a character without usable joints has instead (logged once per character).
local reported: { [Model]: boolean } = {}
local function reportMissingJoints(character: Model)
	if reported[character] or not (RunService:IsStudio() and Config.Dev.LogAnimations) then
		return
	end
	reported[character] = true
	local found: { string } = {}
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("JointInstance") or descendant:IsA("Constraint") or descendant:IsA("Bone") then
			table.insert(found, `{descendant.ClassName} "{descendant.Name}" in {(descendant.Parent :: Instance).Name}`)
		end
	end
	log(`no joints to animate on {character.Name}; it has: {if #found > 0 then table.concat(found, ", ") else "none"}`)
end

local function describe(joints: { [string]: Joint }): string
	local kinds: { string } = {}
	for name, joint in joints do
		local kind = "Motor6D"
		local constraint = joint.Constraint
		if constraint then
			kind = if constraint.IsKinematic then "AnimationConstraint(kinematic)" else "AnimationConstraint(physical)"
		end
		table.insert(kinds, `{name}:{kind}`)
	end
	table.sort(kinds)
	return table.concat(kinds, " ")
end

local function rigOf(character: Model): Rig?
	local existing = rigs[character]
	if existing then
		return existing
	end
	local t = now()
	if (retryAt[character] or 0) > t then
		return nil
	end
	local joints = findJoints(character)
	if next(joints) == nil then
		retryAt[character] = t + RIG_RETRY
		reportMissingJoints(character)
		return nil -- not streamed in yet, or a rig we do not know
	end
	retryAt[character] = nil
	log(`{character.Name}: {describe(joints)}`)
	local rig: Rig = {
		Joints = joints,
		Posed = {},
		Clock = 0,
		LastFrame = t,
		Phase = math.random(0, 3),
		FrozenUntil = 0,
		Pitch = 0,
		Roll = 0,
		StanceWeight = 0,
		WrestleWeight = 0,
		WrestleProgress = 0,
		OneShot = nil,
		Loop = nil,
		Fading = nil,
		FadeStartedAt = 0,
		Tracks = {},
	}
	rigs[character] = rig
	character.Destroying:Connect(function()
		rigs[character] = nil
		retryAt[character] = nil
	end)
	return rig
end

-- Plays an uploaded animation for `clipName` if one is configured. True when it did.
local function playAsset(character: Model, rig: Rig, clipName: string): boolean
	-- Uploaded clips are Animation templates in ReplicatedStorage.Assets.Animations (assets/Sounds.luau builds them
	-- from Config.Animations.AssetIds), loaded onto the Animator.
	local template = animationTemplates:FindFirstChild(clipName)
	if template == nil or not template:IsA("Animation") then
		return false
	end
	local track: AnimationTrack? = rig.Tracks[clipName]
	if track == nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator == nil then
			return false
		end
		local loaded = animator:LoadAnimation(template)
		rig.Tracks[clipName] = loaded
		track = loaded
	end
	if track then
		track:Play(Config.Animations.BlendTime)
	end
	return true
end

--[[
	Plays a one-shot clip on a character (replacing the one playing). `length` holds a looping clip that long
	(a tumble through a hitstun). Unknown clips are ignored.
]]
function AnimationController.play(character: Model, clipName: string, length: number?)
	local clip = Clips[clipName]
	local rig = rigOf(character)
	if clip == nil then
		log(`unknown clip {clipName}`)
		return
	elseif rig == nil then
		log(`{clipName}: no joints to animate on {character.Name}`)
		return
	end
	log(`{clipName} on {character.Name}`)
	if playAsset(character, rig, clipName) then
		return
	end
	rig.OneShot = { Clip = clip, Name = clipName, StartedAt = rig.Clock, Length = length }
end

-- The loop a character's replicated state asks for (charging a punch beats carrying).
local function loopFor(character: Model): string?
	if character:GetAttribute("Charging") then
		return "Charge"
	elseif character:GetAttribute("HeldProp") ~= nil then
		return "Carry"
	end
	return nil
end

local function toCFrame(values: { number }): CFrame
	return CFrame.new(values[4], values[5], values[6])
		* CFrame.fromEulerAnglesYXZ(math.rad(values[1]), math.rad(values[2]), math.rad(values[3]))
end

--[[
	Turns a joint by `turn` (nil = back to rest). The turn is applied around the joint's pivot in the parent body
	part's axes, whatever rotation the joint's own offset has (R15 offsets have none; R6 shoulders and hips are turned
	90°), so a clip means the same on every rig.
]]
local function setTurn(joint: Joint, turn: CFrame?)
	local rest = joint.Rest
	local offset = if turn then CFrame.new(rest.Position) * turn * rest.Rotation else rest
	local motor, attachment = joint.Motor, joint.Attachment
	if motor then
		motor.C0 = offset
	elseif attachment then
		attachment.CFrame = offset
	end
end

-- The Motion layer's input from the character's movement, with the lean smoothed toward its target.
local function motionLayer(character: Model, rig: Rig, dt: number): (Layer?, number)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return nil, 0
	end
	local velocity = root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
	local forward, side = -velocity.Z, velocity.X
	local pitch, roll = Motion.lean(forward, side)
	local follow = 1 - math.exp(-Config.Animations.Motion.Smoothing * dt)
	rig.Pitch += (pitch - rig.Pitch) * follow
	rig.Roll += (roll - rig.Roll) * follow
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local airborne = humanoid == nil or humanoid.FloorMaterial == Enum.Material.Air
	local air = Motion.airWeight(velocity.Y, airborne)
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	return { Sample = Motion.sample(rig.Pitch, rig.Roll, air), Weight = 1 }, speed
end

-- Fists up while standing still in a round (players only).
local function inRound(character: Model): boolean
	local player = Players:GetPlayerFromCharacter(character)
	return player ~= nil and player:GetAttribute("RoundStatus") == "Playing"
end

local function update(character: Model, rig: Rig)
	local t = now()
	local dt = math.min(t - rig.LastFrame, 0.1)
	rig.LastFrame = t
	if t >= rig.FrozenUntil then
		rig.Clock += dt -- hit-stop holds every clip still
	end
	local clock = rig.Clock
	local blend = Config.Animations.BlendTime

	-- State loop: (re)start it when it changes; an ended loop blends out.
	local loopName = loopFor(character)
	local loop = rig.Loop
	if loop and loop.Name ~= loopName then
		rig.Fading, rig.FadeStartedAt = loop, clock
		rig.Loop = nil
	end
	if loopName and rig.Loop == nil then
		rig.Loop = { Clip = Clips[loopName], Name = loopName, StartedAt = clock }
	end
	if rig.Fading and clock - rig.FadeStartedAt >= blend then
		rig.Fading = nil
	end
	local oneShot = rig.OneShot
	if oneShot and Pose.isOver(oneShot.Clip, clock - oneShot.StartedAt, oneShot.Length) then
		rig.OneShot = nil
		oneShot = nil
	end

	local layers: { Layer } = {}
	local motion, speed = motionLayer(character, rig, dt)
	if motion then
		table.insert(layers, motion)
	end
	local stanceTarget = if inRound(character) and rig.Loop == nil then Motion.stanceWeight(speed) else 0
	rig.StanceWeight += (stanceTarget - rig.StanceWeight) * (1 - math.exp(-dt / math.max(blend * 2, 0.01)))
	if rig.StanceWeight > 0.01 then
		table.insert(layers, { Sample = Pose.sample(Clips.Stance, clock), Weight = rig.StanceWeight })
	end
	-- Arm wrestling at the lobby table: the seated pose, following the match (the ArmWrestle attribute).
	local wrestle = character:GetAttribute("ArmWrestle")
	local follow = 1 - math.exp(-dt / math.max(blend, 0.01))
	rig.WrestleWeight += ((if type(wrestle) == "number" then 1 else 0) - rig.WrestleWeight) * follow
	if type(wrestle) == "number" then
		rig.WrestleProgress += (wrestle - rig.WrestleProgress) * follow
	end
	if rig.WrestleWeight > 0.01 then
		local sample = ArmWrestle.sample(rig.WrestleProgress, clock)
		table.insert(layers, { Sample = sample, Weight = rig.WrestleWeight })
	end
	local fading = rig.Fading
	if fading then
		local weight = 1 - (clock - rig.FadeStartedAt) / blend
		table.insert(layers, { Sample = Pose.sample(fading.Clip, clock - fading.StartedAt), Weight = weight })
	end
	local current = rig.Loop
	if current then
		local elapsed = clock - current.StartedAt
		table.insert(layers, { Sample = Pose.sample(current.Clip, elapsed), Weight = math.min(elapsed / blend, 1) })
	end
	if oneShot then
		local elapsed = clock - oneShot.StartedAt
		local weight = Pose.weight(oneShot.Clip, elapsed, blend, oneShot.Length)
		table.insert(layers, { Sample = Pose.sample(oneShot.Clip, elapsed), Weight = weight })
	end

	local posed: { [string]: boolean } = {}
	for name, joint in rig.Joints do
		local turn: CFrame? = nil
		for _, layer in layers do
			local values = layer.Sample[name]
			if values then
				turn = (turn or CFrame.identity):Lerp(toCFrame(values), layer.Weight)
			end
		end
		if turn then
			setTurn(joint, turn)
			posed[name] = true
		elseif rig.Posed[name] then
			setTurn(joint, nil) -- every layer let go: back to rest
		end
	end
	rig.Posed = posed
end

-- The recoil clip for a hit, from where the attacker stands relative to the victim.
local function recoilClip(attacker: Model?, victim: Model): string
	local victimRoot = victim:FindFirstChild("HumanoidRootPart")
	local attackerRoot = attacker and attacker:FindFirstChild("HumanoidRootPart")
	if
		victimRoot == nil
		or attackerRoot == nil
		or not victimRoot:IsA("BasePart")
		or not attackerRoot:IsA("BasePart")
	then
		return "Hit"
	end
	local from = victimRoot.CFrame:PointToObjectSpace(attackerRoot.Position)
	if math.abs(from.X) > math.abs(from.Z) then
		return if from.X > 0 then "HitRight" else "HitLeft"
	end
	return if from.Z < 0 then "Hit" else "HitBack"
end

local function freeze(character: Model?, seconds: number)
	local rig = character and rigs[character]
	if rig then
		rig.FrozenUntil = math.max(rig.FrozenUntil, now() + seconds)
	end
end

local function onCombatHit(
	attacker: Model?,
	victim: Model?,
	_attack: string,
	heavy: boolean,
	_trail: boolean,
	hitstun: number?
)
	if victim == nil or not victim:IsA("Model") then
		return
	end
	local stun = if type(hitstun) == "number" then hitstun else 0
	if stun >= Clips.Tumble.Duration then
		AnimationController.play(victim, "Tumble", stun)
	else
		AnimationController.play(victim, recoilClip(attacker, victim))
	end
	local stop = if heavy then Config.Animations.HitStop.Heavy else Config.Animations.HitStop.Light
	freeze(victim, stop)
	freeze(attacker, stop)
end

function AnimationController.Start(_self: any)
	Net.on("Animate", function(character: Model?, clipName: string?)
		if typeof(character) == "Instance" and character:IsA("Model") and type(clipName) == "string" then
			AnimationController.play(character, clipName)
		end
	end)
	Net.on("CombatHit", onCombatHit)
	-- Our own dash shows at once (the server tells everyone else). It also ends a tumble: dashing out of a launch.
	DashController.Dashed:Connect(function()
		local character = Players.LocalPlayer.Character
		if character then
			AnimationController.play(character, "Dash")
		end
	end)
	-- Right before each frame is drawn: every character this client sees — far or off-screen ones only every few
	-- frames, the farthest not at all (Lib/AnimationLod, Config.Performance.AnimationLod).
	local frame = 0
	RunService.RenderStepped:Connect(function()
		frame += 1
		local camera = Workspace.CurrentCamera
		local lowGraphics = SettingsController.get("LowGraphics") == true
		local own = Players.LocalPlayer.Character
		local function due(character: Model, rig: Rig): boolean
			local root = character:FindFirstChild("HumanoidRootPart")
			if character == own or camera == nil or root == nil or not root:IsA("BasePart") then
				return true
			end
			local _, onScreen = camera:WorldToViewportPoint(root.Position)
			local distance = (camera.CFrame.Position - root.Position).Magnitude
			local every = AnimationLod.interval(distance, onScreen, lowGraphics, false, Config.Performance.AnimationLod)
			return every ~= nil and (frame + rig.Phase) % every == 0
		end
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local rig = character and rigOf(character)
			if character and rig and due(character, rig) then
				update(character, rig)
			end
		end
		for _, dummy in CollectionService:GetTagged(DUMMY_TAG) do
			local rig = if dummy:IsA("Model") then rigOf(dummy) else nil
			if rig and dummy:IsA("Model") and due(dummy, rig) then
				update(dummy, rig)
			end
		end
	end)
	log("ready")
end

return AnimationController
