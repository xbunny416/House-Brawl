--!strict
--[[
	Music and sound effects (bible §4.4), played on each client by Controllers/SoundController. Every entry is a Roblox
	audio asset id: 0 = silent until one is picked. To fill one: Studio → Toolbox → Audio (free Creator Store audio
	only), right-click a sound → Copy Asset ID, paste the number here. Volume (0–1) is multiplied by the player's
	Music / SFX volume setting; Pitch is a random playback-speed range so repeated sounds don't sound identical.
]]
export type Sound = { Id: number, Volume: number, Pitch: { number }? }

type AudioConfig = {
	FadeTime: number,
	Music: {
		Lobby: Sound,
		Arenas: { [string]: Sound },
		Tension: Sound,
		VictorySting: Sound,
	},
	Sfx: { [string]: Sound },
	HearingDistance: number,
}

local VARY = { 0.92, 1.08 }

local Audio: AudioConfig = {
	FadeTime = 1.5, -- seconds music takes to fade between tracks
	Music = {
		Lobby = { Id = 0, Volume = 0.5 }, -- retro synthwave
		-- One gritty chiptune-rock track per arena (map id → track).
		Arenas = {
			Shinjuku = { Id = 0, Volume = 0.5 },
			BrokenHighway = { Id = 0, Volume = 0.5 },
			JunkyardIsles = { Id = 0, Volume = 0.5 },
			NeonMotel = { Id = 0, Volume = 0.5 },
		},
		Tension = { Id = 0, Volume = 0.5 }, -- layered on top in the last Round.TensionTime seconds of a round
		VictorySting = { Id = 0, Volume = 0.7 }, -- when a round ends
	},
	Sfx = {
		-- Hits (by the attacker's fighting style; a charged punch / heavy hit uses ChargedHit).
		Punch = { Id = 0, Volume = 0.7, Pitch = VARY },
		BatHit = { Id = 0, Volume = 0.8, Pitch = VARY }, -- thwack
		ShovelHit = { Id = 0, Volume = 0.8, Pitch = VARY }, -- clang
		WrenchHit = { Id = 0, Volume = 0.8, Pitch = VARY }, -- bonk
		ChargedHit = { Id = 0, Volume = 0.9, Pitch = VARY },
		PropHit = { Id = 0, Volume = 0.8, Pitch = VARY }, -- a thrown prop landing on someone
		Parry = { Id = 0, Volume = 0.8, Pitch = VARY },
		-- Movement and props.
		Dash = { Id = 0, Volume = 0.6, Pitch = VARY }, -- whoosh
		Grab = { Id = 0, Volume = 0.6, Pitch = VARY },
		Throw = { Id = 0, Volume = 0.7, Pitch = VARY }, -- whoosh
		PerfectDodge = { Id = 0, Volume = 0.8 }, -- chime
		-- Knock-outs and destruction.
		KO = { Id = 0, Volume = 0.9, Pitch = VARY }, -- boom
		Cheer = { Id = 0, Volume = 0.5 }, -- short crowd cheer after a KO
		Explosion = { Id = 0, Volume = 1, Pitch = VARY },
		SmashWood = { Id = 0, Volume = 0.8, Pitch = VARY },
		SmashMetal = { Id = 0, Volume = 0.8, Pitch = VARY },
		SmashGlass = { Id = 0, Volume = 0.8, Pitch = VARY },
		Rumble = { Id = 0, Volume = 0.7 }, -- a platform starts crumbling
		Collapse = { Id = 0, Volume = 0.9 }, -- ...and falls
		-- UI.
		Click = { Id = 0, Volume = 0.4 },
		Coin = { Id = 0, Volume = 0.6 }, -- Scrap earned at the end of a round
		LevelUp = { Id = 0, Volume = 0.8 }, -- fanfare
	},
	HearingDistance = 140, -- studs: how far world sounds carry
}

return Audio
