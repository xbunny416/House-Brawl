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
	List = {
		BrokenHighway = { Enabled = true, Lighting = "Dusk" },
		JunkyardIsles = { Enabled = false, Lighting = "Dusk" }, -- built in step 2.5
		NeonMotel = { Enabled = false, Lighting = "Night" }, -- built in step 2.5
	},
}

return Maps
