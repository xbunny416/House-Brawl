--!strict
-- Developer test panel access. Every command is re-checked on the server against this list. Bible §6.
return {
	-- Roblox UserIds allowed to open the developer panel in live servers.
	AllowedUserIds = {} :: { number },
	-- Anyone can use the panel inside Roblox Studio playtests (never in live servers).
	AllowInStudio = true,
	-- Studio playtests only: players needed to start a round (live servers use Config.Round.MinPlayers). 1 lets you
	-- play rounds alone: stand on the lobby's join pad.
	StudioMinPlayers = 1,
	-- Studio playtests only: print every input action and device change to Output.
	LogInput = true,
	-- Studio playtests only: print every hit (damage, Percent, knockback, hitstun) and KO to Output.
	LogCombat = true,
	-- Studio playtests only: flash every attack hitbox (red = hit something, grey = missed).
	ShowHitboxes = true,
	-- Studio playtests only: print every animation clip a client starts ("[Anim] Jab on Player1").
	LogAnimations = true,
	-- Key that opens / closes the developer panel (KeyCode name; only for players with panel access).
	PanelKey = "Backquote",
	-- Scrap the developer panel's "+Scrap" button gives (to test the Shop).
	GiveScrap = 5000,
	-- XP the panel's "+XP" button gives (level-ups apply), and the levels its Level buttons set (5 / 12 / 25 unlock
	-- the Slugger / Scrapper / Wrecker).
	GiveXP = 1000,
	LevelPresets = { 1, 5, 12, 25, 50 },
	-- The panel's "Arm wrestle bot": presses a second the bot makes at the arm-wrestling table (a quick human makes 6-8).
	ArmWrestleBotTaps = 6,
	-- The panel's "Chess bot": seconds the bot waits before each move (it plays a random legal move).
	ChessBotDelay = 1,
}
