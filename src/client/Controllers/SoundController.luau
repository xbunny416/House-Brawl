--!strict
--[[
	SoundController — music and sound effects (bible §4.4), from the ids in Config.Audio (0 = silent until picked).
	  * Music: the lobby track, or the arena's track while this player is in the running round (fighting, respawning,
	    spectating, or watching it from the lobby), crossfading over FadeTime; the tension layer on top in the last
	    Round.TensionTime seconds; the victory sting when a round ends.
	  * World sounds, heard near where they happen: hits (by the attacker's weapon; heavy hits and thrown props have
	    their own), parries, dashes, grabs, throws, KOs (boom + a short cheer), explosions, structures smashing (wood,
	    metal or glass), the Perfect Dodge chime. CrumbleController plays the rumble and collapse (playAt).
	  * UI: a click on every menu button, a coin sound for round Scrap, a fanfare on level-up.
	Volumes are the sound's own times the player's Music / SFX volume setting (changes apply at once). Every sound is
	a clone of its template in ReplicatedStorage.Assets.Sounds (assets/Sounds.luau: one per slot with an id; no
	template = silent); sound effects play at a random speed in Config.Audio.Pitch.
]]
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent.Parent
local AudioRules = require(Client:WaitForChild("Lib"):WaitForChild("AudioRules"))
local DashController = require(script.Parent:WaitForChild("DashController"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))
local SpectateController = require(script.Parent:WaitForChild("SpectateController"))

local MUSIC_CHECK = 0.5 -- seconds between music checks
local CHEER_DELAY = 0.35 -- seconds after the KO boom
local TOUCH_BUTTONS = "ActionButtons" -- the touch controls' ScreenGui: no clicks there

local SoundController = {}

local player = Players.LocalPlayer
local templates = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds")
local sfxTemplates = templates:WaitForChild("Sfx")
local musicTemplates = templates:WaitForChild("Music")
local folder: Folder
local music: Sound? = nil -- the track playing (a clone of its template)
local musicVolume = 0 -- its own volume, before the player's setting
local tension: Sound? = nil
local currentTrack: string? = nil

local function volumeSetting(key: string): number
	local value = SettingsController.get(key)
	return if type(value) == "number" then value else 1
end

-- A copy of the Sound template `name` in `from`, or nil when that slot has no id yet (silent).
local function clone(from: Instance, name: string): Sound?
	local template = from:FindFirstChild(name)
	return if template and template:IsA("Sound") then template:Clone() else nil
end

--[[
	Plays a sound effect (Config.Audio.Sfx[key]) at a world position or on an instance (it follows it), or as a flat
	UI sound when `where` is nil, at a random speed in its pitch range. Does nothing for an unpicked (0) sound.
]]
function SoundController.playAt(key: string, where: (Vector3 | Instance)?)
	local sound = clone(sfxTemplates, key)
	if sound == nil then
		return
	end
	local entry = Config.Audio.Sfx[key]
	local pitch = if entry and entry.Pitch then entry.Pitch else Config.Audio.Pitch
	sound.Volume *= volumeSetting("SfxVolume")
	sound.PlaybackSpeed = pitch[1] + math.random() * (pitch[2] - pitch[1])
	if where == nil then
		sound.Parent = SoundService
	else
		local holder: Instance
		if typeof(where) == "Vector3" then
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Transparency = 1
			part.Size = Vector3.new(0.2, 0.2, 0.2)
			part.Position = where
			part.Parent = folder
			Debris:AddItem(part, 8)
			holder = part
		else
			holder = where
		end
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMaxDistance = Config.Audio.HearingDistance
		sound.Parent = holder
	end
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, 10)
end

---------------------------------------------------------------------------------------------------------------------
-- Music
---------------------------------------------------------------------------------------------------------------------

-- Fades the music to `track` (a map id or "Lobby"): the old track fades out, a clone of the new one's template in.
local function setTrack(track: string)
	if track == currentTrack then
		return
	end
	currentTrack = track
	local half = Config.Audio.FadeTime / 2
	local old = music
	music = nil
	if old then
		local fadeOut = TweenService:Create(old, TweenInfo.new(half), { Volume = 0 })
		fadeOut:Play()
		fadeOut.Completed:Wait()
		old:Destroy()
	end
	if currentTrack ~= track then
		return -- changed again meanwhile
	end
	local nextTrack = clone(musicTemplates, track)
	if nextTrack == nil then
		return -- no track picked for it yet
	end
	musicVolume = nextTrack.Volume
	nextTrack.Volume = 0
	nextTrack.Parent = SoundService
	nextTrack:Play()
	music = nextTrack
	TweenService:Create(nextTrack, TweenInfo.new(half), { Volume = musicVolume * volumeSetting("MusicVolume") }):Play()
end

local function refreshMusic()
	local state = Workspace:GetAttribute("RoundState")
	-- Watching the round from the lobby plays the arena's music, like spectating.
	local status = if SpectateController.isWatching() then "Spectating" else player:GetAttribute("RoundStatus")
	local mapId = Workspace:GetAttribute("RoundMap")
	local track = AudioRules.musicFor(
		if type(state) == "string" then state else nil,
		if type(status) == "string" then status else nil,
		if type(mapId) == "string" then mapId else nil
	)
	task.spawn(setTrack, track)

	local endsAt = Workspace:GetAttribute("RoundEndsAt")
	local left = if type(endsAt) == "number" then endsAt - Workspace:GetServerTimeNow() else 0
	local on = AudioRules.tensionOn(
		if type(state) == "string" then state else nil,
		if type(status) == "string" then status else nil,
		left,
		Config.Round.TensionTime
	)
	local layer = tension
	if layer and on and not layer.IsPlaying then
		layer.Volume = Config.Audio.Music.Tension.Volume * volumeSetting("MusicVolume")
		layer:Play()
	elseif layer and not on and layer.IsPlaying then
		layer:Stop()
	end
end

local function applyMusicVolume()
	local volume = volumeSetting("MusicVolume")
	if music then
		music.Volume = musicVolume * volume
	end
	if tension then
		tension.Volume = Config.Audio.Music.Tension.Volume * volume
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------------------------------------------------

local function onCombatHit(
	_attacker: Model?,
	victim: Model?,
	attack: string,
	heavy: boolean,
	_trail: boolean,
	_hitstun: number?,
	weapon: string?
)
	local root = victim and victim:FindFirstChild("HumanoidRootPart")
	if root then
		SoundController.playAt(AudioRules.hitSound(attack, weapon, heavy), root)
	end
end

local function onEffect(kind: string, position: Vector3, data: { [string]: any }?)
	if typeof(position) ~= "Vector3" then
		return
	end
	if kind == "KO" then
		SoundController.playAt("KO", position)
		task.delay(CHEER_DELAY, SoundController.playAt, "Cheer", nil)
	elseif kind == "Explosion" then
		SoundController.playAt("Explosion", position)
	elseif kind == "Break" then
		local material = if type(data) == "table" and type(data.Material) == "string" then data.Material else ""
		SoundController.playAt(AudioRules.smashSound(material), position)
	elseif kind == "PerfectDodge" then
		SoundController.playAt("PerfectDodge", position)
	end
end

-- Sounds that go with an animation the server announces.
local CLIP_SOUNDS: { [string]: string } = { Dash = "Dash", Grab = "Grab", Throw = "Throw", Parry = "Parry" }

local function onAnimate(character: Model?, clip: string?)
	local key = if type(clip) == "string" then CLIP_SOUNDS[clip] else nil
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if key and root then
		SoundController.playAt(key, root)
	end
end

-- A click on every menu button (not the touch action buttons).
local function watchButton(instance: Instance)
	if instance:IsA("GuiButton") and instance:FindFirstAncestor(TOUCH_BUTTONS) == nil then
		instance.Activated:Connect(function()
			SoundController.playAt("Click")
		end)
	end
end

function SoundController.Start(_self: any)
	folder = Instance.new("Folder")
	folder.Name = "Sounds"
	folder.Parent = Workspace
	tension = clone(musicTemplates, "Tension")
	if tension then
		tension.Name = "TensionLayer"
		tension.Parent = SoundService
	end

	Net.on("CombatHit", onCombatHit)
	Net.on("Effect", onEffect)
	Net.on("Animate", onAnimate)
	DashController.Dashed:Connect(function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			SoundController.playAt("Dash", root)
		end
	end)
	Net.on("RoundResults", function()
		local sting = clone(musicTemplates, "VictorySting")
		if sting then
			sting.Volume *= volumeSetting("MusicVolume")
			sting.Parent = SoundService
			sting:Play()
			Debris:AddItem(sting, 15)
		end
	end)
	Net.on("RoundReward", function(scrap: number, _xp: number, _level: number, levelsGained: number)
		if type(scrap) == "number" and scrap > 0 then
			SoundController.playAt("Coin")
		end
		if type(levelsGained) == "number" and levelsGained > 0 then
			SoundController.playAt("LevelUp")
		end
	end)

	local playerGui = player:WaitForChild("PlayerGui")
	for _, descendant in playerGui:GetDescendants() do
		watchButton(descendant)
	end
	playerGui.DescendantAdded:Connect(watchButton)

	SettingsController.Changed:Connect(function(key: string)
		if key == "MusicVolume" then
			applyMusicVolume()
		end
	end)
	local elapsed = MUSIC_CHECK
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= MUSIC_CHECK then
			elapsed = 0
			refreshMusic()
		end
	end)
end

return SoundController
