--!strict
-- Developer test panel access. Every command is re-checked on the server against this list. Bible §6.
return {
	-- Roblox UserIds allowed to open the developer panel in live servers.
	AllowedUserIds = {} :: { number },
	-- Anyone can use the panel inside Roblox Studio playtests (never in live servers).
	AllowInStudio = true,
	-- Studio playtests only: players needed to start a round (live servers use Config.Round.MinPlayers). 1 lets you
	-- play rounds alone; set it to 2 to stay in the lobby (e.g. to practise on the training dummy).
	StudioMinPlayers = 1,
	-- Studio playtests only: print every input action and device change to Output.
	LogInput = true,
	-- Studio playtests only: print every hit (damage, Percent, knockback, hitstun) and KO to Output.
	LogCombat = true,
	-- Studio playtests only: flash every attack hitbox (red = hit something, grey = missed).
	ShowHitboxes = true,
	-- Key that opens / closes the developer panel (KeyCode name; only for players with panel access).
	PanelKey = "Backquote",
	-- Scrap the developer panel's "+Scrap" button gives (to test the Shop).
	GiveScrap = 5000,
}
