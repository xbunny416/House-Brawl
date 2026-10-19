--!strict
-- Round flow, respawning, participation rules and the crumbling-platform event. Bible §2.1 and §3.2.
return {
	MinPlayers = 2, -- players on the lobby join pad needed to start a round
	VoteTime = 15, -- intermission: map + mode vote
	RoundTime = 240, -- 4:00 (owner, 2026-10-17; was 3:00)
	ResultsTime = 8, -- results / MVP screen before returning to the Lobby
	RespawnDelay = 3,
	SpawnShieldTime = 2, -- breaks early if the player attacks
	TensionTime = 30, -- the last N seconds use the tension music layer
	PlacementsRewarded = 3, -- top N finishers get placement rewards
	-- Private servers (bible §7): the owner picks the round length from these (seconds; RoundTime is the default).
	-- Rewards there: Economy.PrivateServerRewardScale.
	PrivateRoundTimes = { 120, 180, 240, 300 },

	-- Lobby join pad (QueueZone-tagged part): only active players standing on it are taken into the next round
	-- (Casual: into the running round). Everyone else stays in the lobby (Shop, Locker ...).
	Queue = {
		Height = 10, -- studs above the pad that still count as standing on it (jumping)
	},

	Participation = {
		MinSeconds = 60, -- must be active in the round this long for placement + completion rewards
		AFKTimeout = 45, -- no input for this long = AFK (no rewards, not put into the next round)
		ActivityPingInterval = 10, -- clients report "had input" at most this often
	},

	Crumble = {
		StartTime = 60, -- seconds into the round
		Interval = 20,
		WarningTime = 3, -- flash + shake before the platform falls
		MinPlatformsRemaining = 2, -- including the central platform, which never falls
		FallTime = 4, -- seconds the falling platform takes before it is removed
		-- The arena closes in: the next platform comes from the outer ring, those within RingWidth studs of the farthest
		-- one from the centre (owner's fix list, 2026-10-19).
		RingWidth = 40,
	},
}
