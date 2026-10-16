--!strict
-- Developer test panel access. Every command is re-checked on the server against this list. Bible §6.
return {
	-- Roblox UserIds allowed to open the developer panel in live servers.
	AllowedUserIds = {} :: { number },
	-- Anyone can use the panel inside Roblox Studio playtests (never in live servers).
	AllowInStudio = true,
	-- Studio playtests only: load this arena at startup and add a teleport pad in the lobby. nil to disable.
	StudioArenaPreview = "BrokenHighway" :: string?,
	-- Studio playtests only: print every input action and device change to Output.
	LogInput = true,
	-- Studio playtests only: print every hit (damage, Percent, knockback, hitstun) and KO to Output.
	LogCombat = true,
	-- Studio playtests only: flash every attack hitbox (red = hit something, grey = missed).
	ShowHitboxes = true,
	-- Studio playtests only: debug keys (KeyCode names). The developer panel replaces these in step 1.13.
	StudioKeys = {
		TestCameraShake = "K",
		ToggleCameraShake = "L",
	},
}
