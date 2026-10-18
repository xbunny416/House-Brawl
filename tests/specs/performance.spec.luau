--!strict
-- Low-end performance (step 3.11): how often other characters are posed.
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local AnimationLod = Roblox.require(Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib.AnimationLod)

local LOD = Config.Performance.AnimationLod

return {
	["your own character is posed every frame, wherever the camera is"] = function()
		expect.equal(AnimationLod.interval(9999, false, true, true, LOD), 1)
	end,
	["close and in view: every frame; further: less often; off screen: rarely; very far: never"] = function()
		expect.equal(AnimationLod.interval(10, true, false, false, LOD), 1)
		expect.equal(AnimationLod.interval(LOD.Near + 1, true, false, false, LOD), LOD.FarEvery)
		expect.equal(AnimationLod.interval(LOD.Far + 1, true, false, false, LOD), LOD.OffscreenEvery)
		expect.equal(AnimationLod.interval(10, false, false, false, LOD), LOD.OffscreenEvery)
		expect.equal(AnimationLod.interval(LOD.Cull + 1, true, false, false, LOD), nil)
	end,
	["Low Graphics brings every distance closer"] = function()
		local distance = LOD.Near * LOD.LowGraphicsScale + 1
		expect.equal(AnimationLod.interval(distance, true, false, false, LOD), 1)
		expect.equal(AnimationLod.interval(distance, true, true, false, LOD), LOD.FarEvery)
		expect.equal(AnimationLod.interval(LOD.Cull * LOD.LowGraphicsScale + 1, true, true, false, LOD), nil)
	end,
	["sane numbers: Near < Far < Cull, slower rates further away, a reachable frame-rate check"] = function()
		expect.truthy(LOD.Near < LOD.Far and LOD.Far < LOD.Cull)
		expect.truthy(1 < LOD.FarEvery and LOD.FarEvery <= LOD.OffscreenEvery)
		expect.truthy(LOD.LowGraphicsScale > 0 and LOD.LowGraphicsScale < 1)
		local auto = Config.Performance.AutoLowGraphics
		expect.truthy(auto.MinFps > 0 and auto.MinFps < 60 and auto.SampleTime > 0)
	end,
}
