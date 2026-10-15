--!strict
-- Developer test panel access. Every command is re-checked on the server against this list. Bible §6.
return {
	-- Roblox UserIds allowed to open the developer panel in live servers.
	AllowedUserIds = {} :: { number },
	-- Anyone can use the panel inside Roblox Studio playtests (never in live servers).
	AllowInStudio = true,
	-- Studio playtests only: load this arena at startup and add a teleport pad in the lobby. nil to disable.
	StudioArenaPreview = "BrokenHighway" :: string?,
}
