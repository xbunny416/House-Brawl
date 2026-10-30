--!strict
--[[
	The sound templates (ReplicatedStorage.Assets.Sounds), cloned by Controllers/SoundController (owner's project
	rules, 2026-10-30: "clone from ReplicatedStorage.Assets.Sounds, randomize PlaybackSpeed (0.9–1.1), and play").
	One Sound per Config.Audio slot that has an id, at the slot's volume: Sfx/<key>, Music/Lobby, Music/<map id>
	(looped), Music/Tension (looped), Music/VictorySting. A slot still at 0 gets no template (never a sound with an
	empty id), so it stays silent.
]]
local roblox = require("@lune/roblox")

local Sounds = {}

local function folderIn(parent: any, name: string): any
	local folder = roblox.Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function sound(parent: any, name: string, entry: { Id: number, Volume: number }, looped: boolean)
	if entry.Id == 0 then
		return
	end
	local template = roblox.Instance.new("Sound")
	template.Name = name
	template.SoundId = `rbxassetid://{entry.Id}`
	template.Volume = entry.Volume
	template.Looped = looped
	template.Parent = parent
end

-- The keys of `map`, sorted (a stable order, so the generated file only changes when the Config does).
local function sorted(map: { [string]: any }): { string }
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

-- Builds the Sounds folder from `Config`.
function Sounds.build(Config: any): any
	local audio = Config.Audio
	local folder = roblox.Instance.new("Folder")
	folder.Name = "Sounds"
	local sfx = folderIn(folder, "Sfx")
	for _, key in sorted(audio.Sfx) do
		sound(sfx, key, audio.Sfx[key], false)
	end
	local music = folderIn(folder, "Music")
	sound(music, "Lobby", audio.Music.Lobby, true)
	for _, mapId in sorted(audio.Music.Arenas) do
		sound(music, mapId, audio.Music.Arenas[mapId], true)
	end
	sound(music, "Tension", audio.Music.Tension, true)
	sound(music, "VictorySting", audio.Music.VictorySting, false)
	return folder
end

-- Builds the Animations folder: an Animation per uploaded clip (Config.Animations.AssetIds, never an empty id),
-- loaded onto the Animator by Controllers/AnimationController.
function Sounds.animations(Config: any): any
	local folder = roblox.Instance.new("Folder")
	folder.Name = "Animations"
	local ids = Config.Animations.AssetIds
	for _, clip in sorted(ids) do
		if ids[clip] ~= 0 then
			local animation = roblox.Instance.new("Animation")
			animation.Name = clip
			animation.AnimationId = `rbxassetid://{ids[clip]}`
			animation.Parent = folder
		end
	end
	return folder
end

return Sounds
