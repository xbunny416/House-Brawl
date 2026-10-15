--!strict
-- Remote call limits. Each player gets Burst calls per remote, refilling at Rate per second.
return {
	DefaultRateLimit = { Rate = 20, Burst = 30 },
	-- Invalid or rate-limited calls are dropped; this many in a row are logged in Studio as a warning.
	RejectWarnEvery = 20,
}
