--!strict
--[[
	AnimationController — plays the scripted R15 animations (Shared/Animation) on every character this client sees.
	Roblox's default animations keep running; each frame, after they have posed the rig (RunService.Stepped), the
	joints a clip uses are blended toward the clip's pose. Nothing replicates: every client poses every character
	from the same signals.
	  * One-shots: the server's Animate event (punch chain / weapon swings, Shove, parry, grab, throw, victory
	    emotes, other players' dashes); the local dash (DashController.Dashed, no round trip); hits from CombatHit (a
	    short recoil, or a tumble looping through a long hitstun).
	  * Loops from replicated attributes: ShoveCharge while ShoveCharging is set, Carry while HeldProp is set. They
	    blend in when the state starts and out when it ends; a one-shot plays on top of a loop.
	A joint Roblox's Animator leaves alone (or any joint of a dummy, which has no default animations) is put back to
	rest when a clip lets go of it. A clip with an uploaded animation in Config.Animations.AssetIds plays that
	animation instead.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Clips = require(Shared:WaitForChild("Animation"):WaitForChild("Clips"))
local Pose = require(Shared:WaitForChild("Animation"):WaitForChild("Pose"))

local DashController = require(script.Parent:WaitForChild("DashController"))

local DUMMY_TAG = "TrainingDummy"

type Playing = { Clip: Pose.Clip, Name: string, StartedAt: number, Length: number? }
type Rig = {
	Joints: { [string]: Motor6D },
	-- What we wrote to each joint last frame. A joint still holding it was not re-posed by Roblox's Animator (a
	-- dummy, or a joint the default animations leave alone), so its real base pose is rest, not our old value.
	Written: { [Motor6D]: CFrame },
	OneShot: Playing?,
	Loop: Playing?,
	Fading: Playing?, -- the loop that just ended, blending out
	FadeStartedAt: number,
	Tracks: { [string]: AnimationTrack },
}

local AnimationController = {}

local rigs: { [Model]: Rig } = {}

local function now(): number
	return os.clock()
end

local function rigOf(character: Model): Rig?
	local rig = rigs[character]
	if rig and next(rig.Joints) ~= nil then
		return rig
	end
	local joints: { [string]: Motor6D } = {}
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") and table.find(Pose.Joints, descendant.Name) then
			joints[descendant.Name] = descendant
		end
	end
	if next(joints) == nil then
		return nil -- not streamed in yet, or not an R15 rig
	end
	local built: Rig = {
		Joints = joints,
		Written = {},
		OneShot = nil,
		Loop = nil,
		Fading = nil,
		FadeStartedAt = 0,
		Tracks = {},
	}
	rigs[character] = built
	character.Destroying:Connect(function()
		rigs[character] = nil
	end)
	return built
end

-- Plays an uploaded animation for `clipName` if one is configured. True when it did.
local function playAsset(character: Model, rig: Rig, clipName: string): boolean
	local assetId = Config.Animations.AssetIds[clipName]
	if assetId == nil or assetId == 0 then
		return false
	end
	local track: AnimationTrack? = rig.Tracks[clipName]
	if track == nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator == nil then
			return false
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = `rbxassetid://{assetId}`
		local loaded = animator:LoadAnimation(animation)
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
	if clip == nil or rig == nil or playAsset(character, rig, clipName) then
		return
	end
	rig.OneShot = { Clip = clip, Name = clipName, StartedAt = now(), Length = length }
end

-- The loop a character's replicated state asks for (charging a Shove beats carrying).
local function loopFor(character: Model): string?
	if character:GetAttribute("ShoveCharging") then
		return "ShoveCharge"
	elseif character:GetAttribute("HeldProp") ~= nil then
		return "Carry"
	end
	return nil
end

local function toCFrame(values: { number }): CFrame
	return CFrame.new(values[4], values[5], values[6])
		* CFrame.fromEulerAnglesYXZ(math.rad(values[1]), math.rad(values[2]), math.rad(values[3]))
end

local function update(character: Model, rig: Rig, t: number)
	local blend = Config.Animations.BlendTime

	-- Loop from state: (re)start it when it changes; an ended loop blends out.
	local loopName = loopFor(character)
	local loop = rig.Loop
	if loop and loop.Name ~= loopName then
		rig.Fading, rig.FadeStartedAt = loop, t
		rig.Loop = nil
	end
	if loopName and rig.Loop == nil then
		rig.Loop = { Clip = Clips[loopName], Name = loopName, StartedAt = t }
	end
	if rig.Fading and t - rig.FadeStartedAt >= blend then
		rig.Fading = nil
	end
	local oneShot = rig.OneShot
	if oneShot and Pose.isOver(oneShot.Clip, t - oneShot.StartedAt, oneShot.Length) then
		rig.OneShot = nil
		oneShot = nil
	end

	-- Layers, bottom to top: the fading loop, the current loop, the one-shot.
	local layers: { { Sample: Pose.Sample, Weight: number } } = {}
	local fading = rig.Fading
	if fading then
		local weight = 1 - (t - rig.FadeStartedAt) / blend
		table.insert(layers, { Sample = Pose.sample(fading.Clip, t - fading.StartedAt), Weight = weight })
	end
	local current = rig.Loop
	if current then
		local elapsed = t - current.StartedAt
		table.insert(layers, { Sample = Pose.sample(current.Clip, elapsed), Weight = math.min(elapsed / blend, 1) })
	end
	if oneShot then
		local elapsed = t - oneShot.StartedAt
		local weight = Pose.weight(oneShot.Clip, elapsed, blend, oneShot.Length)
		table.insert(layers, { Sample = Pose.sample(oneShot.Clip, elapsed), Weight = weight })
	end

	local written: { [Motor6D]: CFrame } = {}
	for name, motor in rig.Joints do
		local last: CFrame? = rig.Written[motor]
		local untouchedByAnimator = false
		if last then
			untouchedByAnimator = motor.Transform == last
		end
		local result: CFrame? = nil
		for _, layer in layers do
			local values = layer.Sample[name]
			if values then
				local base = result or (if untouchedByAnimator then CFrame.identity else motor.Transform)
				result = base:Lerp(toCFrame(values), layer.Weight)
			end
		end
		if result then
			motor.Transform = result
			written[motor] = result
		elseif untouchedByAnimator then
			motor.Transform = CFrame.identity -- nothing else will put this joint back to rest
		end
	end
	rig.Written = written
end

local function onCombatHit(
	_attacker: Model?,
	victim: Model?,
	_attack: string,
	_heavy: boolean,
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
		AnimationController.play(victim, "Hit")
	end
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
	RunService.Stepped:Connect(function()
		local t = now()
		-- Characters with something to show: a one-shot, or a state loop (players only; dummies never carry).
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character and (rigs[character] or loopFor(character)) then
				local rig = rigOf(character)
				if rig then
					update(character, rig, t)
				end
			end
		end
		for _, dummy in CollectionService:GetTagged(DUMMY_TAG) do
			local rig = if dummy:IsA("Model") then rigs[dummy] else nil
			if rig and dummy:IsA("Model") then
				update(dummy, rig, t)
			end
		end
	end)
end

return AnimationController
