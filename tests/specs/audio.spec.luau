--!strict
-- Music + SFX (step 2.8): the sound slots are well formed, every map has a track, and every sound the game asks for
-- has a slot; music follows the round, the tension layer the last seconds.
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local AudioRules = Roblox.require(Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib.AudioRules)

local Audio = Config.Audio

local function checkSound(name: string, sound: any)
	expect.truthy(type(sound.Id) == "number" and sound.Id >= 0 and sound.Id == math.floor(sound.Id), `{name} id`)
	expect.truthy(sound.Volume > 0 and sound.Volume <= 1, `{name} volume`)
	if sound.Pitch then
		expect.truthy(sound.Pitch[1] > 0 and sound.Pitch[1] <= sound.Pitch[2], `{name} pitch range`)
	end
end

return {
	["every sound slot has a whole, non-negative id (0 = silent), a volume and a sane pitch range"] = function()
		checkSound("Lobby", Audio.Music.Lobby)
		checkSound("Tension", Audio.Music.Tension)
		checkSound("VictorySting", Audio.Music.VictorySting)
		for mapId, sound in Audio.Music.Arenas do
			checkSound(mapId, sound)
		end
		for name, sound in Audio.Sfx do
			checkSound(name, sound)
		end
	end,
	["every map in the rotation has a music track"] = function()
		for _, mapId in Config.Maps.Rotation do
			expect.truthy(Audio.Music.Arenas[mapId], `track for {mapId}`)
		end
	end,
	["every sound the rules pick has a slot"] = function()
		for styleId, style in Config.Styles.List do
			local key = AudioRules.hitSound("Punch", style.Weapon, false)
			expect.truthy(Audio.Sfx[key], `{styleId} hit sound {key}`)
		end
		for _, key in
			{
				AudioRules.hitSound("Charged", "Fists", true),
				AudioRules.hitSound("Chair", nil, false),
				AudioRules.hitSound("Parry", "WrenchAndHubcap", true),
			}
		do
			expect.truthy(Audio.Sfx[key], key)
		end
		for typeId, structure in Config.Structures.Types do
			local key = AudioRules.smashSound(structure.Material)
			expect.truthy(Audio.Sfx[key], `{typeId} smash {key}`)
		end
		for _, key in
			{ "Dash", "Grab", "Throw", "Parry", "KO", "Cheer", "Explosion", "PerfectDodge", "Rumble", "Collapse" }
		do
			expect.truthy(Audio.Sfx[key], key)
		end
		for _, key in { "Click", "Coin", "LevelUp" } do
			expect.truthy(Audio.Sfx[key], key)
		end
	end,
	["hit sounds: weapon by style, heavy hits and thrown props have their own"] = function()
		expect.equal(AudioRules.hitSound("Punch", "Fists", false), "Punch")
		expect.equal(AudioRules.hitSound("Punch", "BaseballBat", false), "BatHit")
		expect.equal(AudioRules.hitSound("Punch", "Shovel", false), "ShovelHit")
		expect.equal(AudioRules.hitSound("Punch", "WrenchAndHubcap", false), "WrenchHit")
		expect.equal(AudioRules.hitSound("Charged", "Shovel", true), "ChargedHit")
		expect.equal(AudioRules.hitSound("Crate", "Fists", false), "PropHit")
		expect.equal(AudioRules.hitSound("Parry", nil, true), "Parry")
		expect.equal(AudioRules.smashSound("WoodPlanks"), "SmashWood")
		expect.equal(AudioRules.smashSound("Glass"), "SmashGlass")
		expect.equal(AudioRules.smashSound("CorrodedMetal"), "SmashMetal")
	end,
	["music: the arena track only while in the running round; tension in the last seconds"] = function()
		expect.equal(AudioRules.musicFor("Waiting", "Lobby", nil), "Lobby")
		expect.equal(AudioRules.musicFor("Playing", "Playing", "NeonMotel"), "NeonMotel")
		expect.equal(AudioRules.musicFor("Playing", "Spectating", "NeonMotel"), "NeonMotel", "watching")
		expect.equal(AudioRules.musicFor("Playing", "Lobby", "NeonMotel"), "Lobby", "shopping in the lobby")
		expect.equal(AudioRules.musicFor("Results", "Lobby", "NeonMotel"), "Lobby")
		local tension = Config.Round.TensionTime
		expect.equal(AudioRules.tensionOn("Playing", "Playing", tension - 1, tension), true)
		expect.equal(AudioRules.tensionOn("Playing", "Playing", tension + 1, tension), false, "too early")
		expect.equal(AudioRules.tensionOn("Playing", "Lobby", 5, tension), false, "not in the round")
		expect.equal(AudioRules.tensionOn("Results", "Playing", 5, tension), false, "round over")
	end,
}
