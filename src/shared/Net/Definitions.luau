--!strict
--[[
	Every remote in the game. The server creates them at startup; clients wait for them.
	ToServer remotes must list Args (validated on the server before any handler runs) and may override the default
	rate limit from Config.Net. Add new remotes here together with the feature that uses them.
]]
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
}

return Definitions
