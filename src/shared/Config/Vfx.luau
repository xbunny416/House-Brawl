--!strict
--[[
	Visual effects (bible §4.3), drawn on each client by Controllers/VfxController (and CrumbleController for
	platforms). Times in seconds, sizes in studs, colors hex. With the Low Graphics setting on, particles, flying
	debris, post-effects (Bloom, color grading) and shadows are off; the cheap flashes, the KO starburst and the
	screen-edge flash stay.
]]
type VfxConfig = {
	Sparks: { MinCount: number, MaxCount: number, MaxPercent: number, Speed: { number }, Lifetime: number },
	ImpactFlash: { Size: number, HeavySize: number, Time: number },
	LaunchSmoke: { Rate: number, Lifetime: number, Color: string },
	KO: { BurstTime: number, BurstSize: number, FlashTime: number, StarColor: string, TextColor: string },
	EdgeFlash: { KnockedOut: string, Scored: string, PerfectDodge: string, Opacity: number },
	Explosion: { Time: number, RingTime: number, Smoke: number, Debris: number },
	Break: { Chunks: number, LowChunks: number, ChunkTime: number, Dust: number },
	Dash: { StreakLifetime: number, Color: string },
	PerfectDodge: { Time: number, Color: string },
	Crumble: { Cracks: number, Dust: number, Debris: number, DebrisTime: number },
}

local Vfx: VfxConfig = {
	-- Hit sparks: more of them the higher the victim's Percent (up to MaxCount at MaxPercent), in the Percent colors
	-- (white → yellow → red), thrown away from the attacker.
	Sparks = { MinCount = 8, MaxCount = 30, MaxPercent = 150, Speed = { 18, 36 }, Lifetime = 0.35 },
	ImpactFlash = { Size = 2.2, HeavySize = 3.6, Time = 0.16 },
	-- Smoke trail behind a fighter launched above Combat.Knockback.TrailPercent, for the length of the hitstun.
	LaunchSmoke = { Rate = 45, Lifetime = 0.8, Color = "#BDB6AC" },
	-- Comic "POW" starburst where a fighter is knocked out (around the scorer for ring-outs).
	KO = { BurstTime = 0.9, BurstSize = 7, FlashTime = 0.55, StarColor = "#FFD23F", TextColor = "#E2463A" },
	-- Screen-edge flash: red when you are knocked out, gold when you score a KO, blue on your Perfect Dodge.
	EdgeFlash = { KnockedOut = "#FF2A1A", Scored = "#FFD23F", PerfectDodge = "#3FA9FF", Opacity = 0.55 },
	-- Retro cartoon explosion: fireball, ring shockwave, smoke puffs and flying debris.
	Explosion = { Time = 0.45, RingTime = 0.55, Smoke = 24, Debris = 6 },
	-- A structure breaking: chunks in its own color and material, plus dust.
	Break = { Chunks = 10, LowChunks = 3, ChunkTime = 1.6, Dust = 18 },
	Dash = { StreakLifetime = 0.25, Color = "#F2E6D0" },
	PerfectDodge = { Time = 0.4, Color = "#3FA9FF" },
	-- Crumbling platforms: cracks during the warning, dust and debris when it falls.
	Crumble = { Cracks = 7, Dust = 30, Debris = 8, DebrisTime = 2.5 },
}

return Vfx
