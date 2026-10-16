--!strict
--[[
	Every remote in the game. The server creates them at startup; clients wait for them.
	ToServer remotes must list Args (validated on the server before any handler runs) and may override the default
	rate limit from Config.Net. Add new remotes here together with the feature that uses them.
]]
local Config = require(script.Parent.Parent.Config)
local Guard = require(script.Parent.Guard)

export type Kind = "Event" | "UnreliableEvent" | "Function"
export type Direction = "ToServer" | "ToClient"

export type Definition = {
	Kind: Kind,
	Direction: Direction,
	Args: { Guard.Check }?,
	RateLimit: { Rate: number, Burst: number }?,
}

local Definitions: { [string]: Definition } = {
	-- Server -> client: show a localized notice. (key: string, args: { [string]: any }?)
	Notify = { Kind = "Event", Direction = "ToClient" },
	-- Server -> client: the player's full saved data once it loads. (data: PlayerData)
	DataSync = { Kind = "Event", Direction = "ToClient" },
	-- Server -> client: one top-level field of the player's data changed. (key: string, value: any)
	DataChanged = { Kind = "Event", Direction = "ToClient" },

	-- Client -> server: the Attack action was pressed. The server runs the punch chain, cooldown and hit check.
	Punch = { Kind = "Event", Direction = "ToServer", Args = {} },
	-- Client -> server: Shove "Start" (pressed: charge), "Release" (let go: shove) or "Cancel" (stop charging).
	Shove = {
		Kind = "Event",
		Direction = "ToServer",
		Args = { Guard.oneOf({ "Start", "Release", "Cancel" }) },
	},
	-- Server -> the victim's client: launch your character. (velocity: Vector3, hitstun: number)
	Knockback = { Kind = "Event", Direction = "ToClient" },
	-- Server -> all clients: a hit landed, for feedback (camera shake; VFX/SFX later).
	-- (attacker: Model, victim: Model, attack: "Punch" | "Shove", heavy: boolean, trail: boolean)
	CombatHit = { Kind = "UnreliableEvent", Direction = "ToClient" },

	-- Client -> server: change one Settings-menu value. (key: string, value: boolean | number | string)
	-- Shared/Settings checks the value for that key before it is saved.
	ChangeSetting = {
		Kind = "Event",
		Direction = "ToServer",
		Args = {
			Guard.keyOf(Config.Data.DefaultSettings),
			Guard.anyOf(Guard.boolean, Guard.number, Guard.string(32)),
		},
	},
}

return Definitions
