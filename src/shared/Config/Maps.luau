--!strict
-- Map rotation. Layout data for each map is added with the map itself (step 1.4 / 2.5). Bible §3.1.
local Types = require(script.Parent.Types)

type MapsConfig = {
	Lobby: string,
	Rotation: { string },
	VoteChoices: number,
	KillYBelowLowestPlatform: number,
	List: { [string]: Types.MapConfig },
}

local Maps: MapsConfig = {
	Lobby = "RustDiner",
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
