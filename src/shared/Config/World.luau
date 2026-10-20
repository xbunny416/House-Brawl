--!strict
-- Character movement and world physics.
return {
	Gravity = 196.2,
	WalkSpeed = 16,
	JumpHeight = 7.2,
	MaxPlayers = 12, -- set the same value in Game Settings > Places (target 10 per server)
	-- The loading screen (ReplicatedFirst): shown at least MinTime seconds and until the game and your data have
	-- loaded (at most MaxTime), then fades out over FadeTime; it shows one of TipCount tips ("Tip.<n>" strings).
	Loading = { MinTime = 1.5, MaxTime = 20, FadeTime = 0.6, TipCount = 8 },
	-- The lobby news TVs (NewsScreen parts, NewsController): a new headline every Interval seconds, a ticker scrolling
	-- TickerSpeed pixels a second, Headlines fun stories ("News.<n>" strings) mixed with live news.
	News = { Interval = 8, TickerSpeed = 40, Headlines = 12 },
	-- The bartender (NpcService): a Roblox user id whose avatar the bartender wears, or 0 for the built-in bartender
	-- outfit (white shirt, dark vest, apron, bow tie, bandana, moustache).
	-- Talk: speech bubbles over the bartender that only the local player sees (BartenderController, Lib/BartenderRules):
	-- walking within Distance studs greets (once per GreetCooldown seconds; after a round you fought in, a Won / Lost line
	-- instead), opening the Shop near the bar and buying there get their own lines, and staying near brings an idle
	-- line every IdleEvery Min–Max seconds (random). A bubble stays ReadTime.Base + PerCharacter × its length seconds,
	-- within Min–Max. Lines[pool] = how many "Bartender.<pool>.<n>" strings each pool has.
	Bartender = {
		UserId = 0,
		Talk = {
			Distance = 20,
			GreetCooldown = 90,
			IdleEvery = { Min = 15, Max = 28 },
			ReadTime = { Base = 2.5, PerCharacter = 0.05, Min = 3, Max = 7 },
			Lines = { Greet = 6, Idle = 14, Shop = 4, Thanks = 4, Won = 4, Lost = 4 },
		},
	},
	-- Arm wrestling at the lobby table (ArmWrestleService, Shared/ArmWrestleRules). When both seats are taken a
	-- CountdownTime countdown starts, then the pull: every press of Attack (the PUSH button on touch) moves the clasped
	-- hands PushPerTap toward the presser (they start in the middle; 1 wins). Presses count up to TapRate a second (a
	-- burst of TapBurst), so an autoclicker is no faster than a quick finger. After PullTime the one ahead wins (dead
	-- even = a draw). The result shows ResultTime seconds, then the next match starts while both stay seated. Nothing
	-- is paid: a win counts toward the ArmWrestleWins stat and the table champion's streak.
	ArmWrestle = { CountdownTime = 3, PullTime = 15, ResultTime = 3, PushPerTap = 0.05, TapRate = 10, TapBurst = 3 },
	-- Chess at the lobby table (ChessService, Shared/ChessMatch, Shared/ChessRules). A game starts as soon as both seats
	-- are taken: the west seat plays White. Each side has TimePerSide seconds plus Increment after each move; running
	-- out loses (a draw if the other side can't checkmate). Standing up loses; resigning, draw offers and every draw rule
	-- of chess apply. NewGameDelay seconds after a game the next one starts while both stay seated. Nothing is paid: a
	-- win counts toward the ChessWins stat. PieceLetters shows K Q R B N P on the board screen instead of the chess
	-- symbols (in case a device lacks them).
	Chess = { TimePerSide = 300, Increment = 3, NewGameDelay = 10, PieceLetters = false },
}
