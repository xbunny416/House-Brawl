--!strict
-- Map rotation. Layout data for each map is added with the map itself (step 1.4 / 2.5). Bible §3.1.
local Types = require(script.Parent.Types)

type MapsConfig = {
	Lobby: string,
	LobbyOrigin: { number },
	ArenaOrigin: { number },
	Rotation: { string },
	VoteChoices: number,
	KillYBelowLowestPlatform: number,
	Movers: { HazardSpeed: number, HazardUp: number, HazardHitstun: number, HazardCooldown: number, HazardReach: number },
	List: { [string]: Types.MapConfig },
}

local Maps: MapsConfig = {
	Lobby = "Hideout",
	-- World positions (X, Y, Z) of the lobby floor centre and of every arena's centre platform. They are far apart so
	-- streaming only sends what is near the player (arena platforms stay Persistent).
	LobbyOrigin = { 0, 100, 0 },
	ArenaOrigin = { 0, 100, -800 },
	Rotation = { "BrokenHighway", "JunkyardIsles", "NeonMotel" },
	VoteChoices = 3, -- maps offered per vote (only Enabled maps are offered)
	KillYBelowLowestPlatform = 60,
	-- The arenas' moving parts (Shared/MoverRules; their paths and timing are map data on each mover). A swinging hazard
	-- (MoverService) knocks a fighter it touches (within HazardReach studs of its box) along its swing at HazardSpeed
	-- studs/s, tipped HazardUp up, for HazardHitstun seconds; no damage, no Percent. The same fighter can be knocked
	-- again after HazardCooldown seconds.
	Movers = { HazardSpeed = 75, HazardUp = 0.45, HazardHitstun = 0.6, HazardCooldown = 1, HazardReach = 1 },
	List = {
		BrokenHighway = { Enabled = true, Lighting = "Smog" },
		JunkyardIsles = { Enabled = true, Lighting = "Dusk" },
		NeonMotel = { Enabled = true, Lighting = "Night" },
	},
}

return Maps
