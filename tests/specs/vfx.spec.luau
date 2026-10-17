--!strict
-- Visual effects (step 2.7): spark counts follow the Percent, KO flashes go to the right players, Low Graphics turns
-- particles off, and the effect config is well formed.
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local VfxRules = Roblox.require(Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib.VfxRules)

local Sparks = Config.Vfx.Sparks

local function isHex(value: string): boolean
	return string.match(value, "^#%x%x%x%x%x%x$") ~= nil
end

return {
	["sparks: MinCount at 0%, MaxCount from MaxPercent, more in between"] = function()
		expect.equal(VfxRules.sparkCount(0, Sparks, false), Sparks.MinCount)
		expect.equal(VfxRules.sparkCount(Sparks.MaxPercent, Sparks, false), Sparks.MaxCount)
		expect.equal(VfxRules.sparkCount(Sparks.MaxPercent * 3, Sparks, false), Sparks.MaxCount, "capped")
		local half = VfxRules.sparkCount(Sparks.MaxPercent / 2, Sparks, false)
		expect.truthy(half > Sparks.MinCount and half < Sparks.MaxCount, "in between")
	end,
	["Low Graphics: no sparks at all"] = function()
		expect.equal(VfxRules.sparkCount(200, Sparks, true), 0)
	end,
	["KO flash: red for the knocked-out player, gold for the scorer, none for anyone else"] = function()
		expect.equal(VfxRules.koFlash(true, false), "KnockedOut")
		expect.equal(VfxRules.koFlash(false, true), "Scored")
		expect.equal(VfxRules.koFlash(false, false), nil)
		expect.equal(VfxRules.koFlash(true, true), "KnockedOut", "a self-KO shows as knocked out")
		for _, key in { "KnockedOut", "Scored", "PerfectDodge" } do
			expect.truthy(isHex((Config.Vfx.EdgeFlash :: any)[key]), `edge flash color {key}`)
		end
	end,
	["effect colors are hex, times and counts positive"] = function()
		local vfx = Config.Vfx
		for _, color in
			{ vfx.LaunchSmoke.Color, vfx.KO.StarColor, vfx.KO.TextColor, vfx.Dash.Color, vfx.PerfectDodge.Color }
		do
			expect.truthy(isHex(color), color)
		end
		for _, value in
			{
				vfx.ImpactFlash.Time,
				vfx.KO.BurstTime,
				vfx.Explosion.Time,
				vfx.Explosion.RingTime,
				vfx.Break.ChunkTime,
				vfx.Dash.StreakLifetime,
				vfx.PerfectDodge.Time,
				vfx.Crumble.DebrisTime,
			}
		do
			expect.truthy(value > 0, "time")
		end
		expect.truthy(vfx.Break.LowChunks < vfx.Break.Chunks, "Low Graphics breaks into fewer chunks")
		expect.truthy(vfx.EdgeFlash.Opacity > 0 and vfx.EdgeFlash.Opacity <= 1, "edge flash opacity")
	end,
	["Low Graphics is a saved setting (off by default)"] = function()
		expect.equal(Config.Data.DefaultSettings.LowGraphics, false)
	end,
}
