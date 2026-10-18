--!strict
--[[
	Config — every tunable number in Junkyard Brawl (prices, HP, cooldowns, rewards, odds, formula constants).
	Balance the game here only; docs/PROJECT_BIBLE.md documents the same values.
	The whole tree is frozen: reading is free, writing errors.
	Secrets that must not replicate to clients (e.g. redeem codes) live in ServerScriptService.Server.ServerConfig.
]]
local Freeze = require(script.Parent.Util.Freeze)

local Config = {
	Combat = require(script.Combat),
	Modes = require(script.Modes),
	Styles = require(script.Styles),
	Props = require(script.Props),
	Structures = require(script.Structures),
	Round = require(script.Round),
	Economy = require(script.Economy),
	Progression = require(script.Progression),
	Cosmetics = require(script.Cosmetics),
	Monetization = require(script.Monetization),
	Retention = require(script.Retention),
	Maps = require(script.Maps),
	Controls = require(script.Controls),
	World = require(script.World),
	Dev = require(script.Dev),
	Net = require(script.Net),
	Data = require(script.Data),
	Lighting = require(script.Lighting),
	Animations = require(script.Animations),
	Vfx = require(script.Vfx),
	Audio = require(script.Audio),
	Performance = require(script.Performance),
}

return Freeze.deep(Config)
