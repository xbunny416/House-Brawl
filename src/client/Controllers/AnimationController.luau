--!strict
--[[
	AnimationController — plays the scripted R15 animations (Shared/Animation) on every character this client sees.
	A clip turns each joint it uses through the joint's C0 (its rest offset), every frame before rendering. Roblox's
	default walk / idle animations never touch C0, so they keep playing on top of the clip (arms still swing a little
	while walking) and nothing has to win a race with them. Nothing replicates: every client poses every character
	from the same signals.
	  * One-shots: the server's Animate event (punch chain / weapon swings, Shove, parry, grab, throw, victory
	    emotes, other players' dashes); the local dash (DashController.Dashed, no round trip); hits from CombatHit (a
	    short recoil, or a tumble looping through a long hitstun).
	  * Loops from replicated attributes: ShoveCharge while ShoveCharging is set, Carry while HeldProp is set. They
	    blend in when the state starts and out when it ends; a one-shot plays on top of a loop.
	When a clip lets go of a joint, its C0 goes back to the rest offset it had before. A clip with an uploaded
	animation in Config.Animations.AssetIds plays that animation instead. Studio: Config.Dev.LogAnimations prints
	every clip started.
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
	RestC0: { [Motor6D]: CFrame }, -- each joint's own C0, before any clip turned it
	Posed: { [Motor6D]: boolean }, -- joints a clip turned last frame
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

local function log(message: string)
	if RunService:IsStudio() and Config.Dev.LogAnimations then
		print(`[Anim] {message}`)
	end
end

local function rigOf(character: Model): Rig?
	local existing = rigs[character]
	if existing then
		return existing
	end
	local joints: { [string]: Motor6D } = {}
	local rest: { [Motor6D]: CFrame } = {}
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") and table.find(Pose.Joints, descendant.Name) then
			joints[descendant.Name] = descendant
			rest[descendant] = descendant.C0
		end
	end
	if next(joints) == nil then
		return nil -- not streamed in yet, or not an R15 rig
	end
	local rig: Rig = {
		Joints = joints,
		RestC0 = rest,
		Posed = {},
		OneShot = nil,
		Loop = nil,
		Fading = nil,
		FadeStartedAt = 0,
		Tracks = {},
	}
	rigs[character] = rig
	character.Destroying:Connect(function()
		rigs[character] = nil
	end)
	return rig
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
	if clip == nil then
		log(`unknown clip {clipName}`)
		return
	elseif rig == nil then
		log(`{clipName}: no R15 joints found on {character.Name}`)
		return
	end
	log(`{clipName} on {character.Name}`)
	if playAsset(character, rig, clipName) then
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

	local posed: { [Motor6D]: boolean } = {}
	for name, motor in rig.Joints do
		local turn: CFrame? = nil
		for _, layer in layers do
			local values = layer.Sample[name]
			if values then
				turn = (turn or CFrame.identity):Lerp(toCFrame(values), layer.Weight)
			end
		end
		if turn then
			motor.C0 = rig.RestC0[motor] * turn
			posed[motor] = true
		elseif rig.Posed[motor] then
			motor.C0 = rig.RestC0[motor] -- the clip let go: back to rest
		end
	end
	rig.Posed = posed
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
	-- Right before each frame is drawn.
	RunService.RenderStepped:Connect(function()
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
	log("ready")
end

return AnimationController
