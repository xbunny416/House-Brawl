--!strict
-- Round flow, respawning, participation rules and the crumbling-platform event. Bible §2.1 and §3.2.
return {
	MinPlayers = 2, -- players needed in the server to start a round
	VoteTime = 15, -- intermission: map + mode vote
	RoundTime = 180,
	ResultsTime = 8, -- results / MVP screen before returning to the Lobby
	RespawnDelay = 3,
	SpawnShieldTime = 2, -- breaks early if the player attacks
	TensionTime = 30, -- the last N seconds use the tension music layer
	PlacementsRewarded = 3, -- top N finishers get placement rewards

	Participation = {
		MinSeconds = 60, -- must be active in the round this long for placement + completion rewards
		AFKTimeout = 45, -- no input for this long = AFK (no rewards)
	},

	Crumble = {
		StartTime = 60, -- seconds into the round
		Interval = 20,
		WarningTime = 3, -- flash + shake before the platform falls
		MinPlatformsRemaining = 2, -- including the central platform, which never falls
		FallTime = 4, -- seconds the falling platform takes before it is removed
	},
}
