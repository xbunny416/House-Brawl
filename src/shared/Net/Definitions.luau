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
	-- Server -> client: show a localized notice (NoticeController). (key: string, args: { any }? — an arg that is a
	-- table { Key = string } is a GameStrings key the client localizes, e.g. an item name)
	Notify = { Kind = "Event", Direction = "ToClient" },
	-- Server -> client: the player's full saved data once it loads. (data: PlayerData)
	DataSync = { Kind = "Event", Direction = "ToClient" },
	-- Server -> client: one top-level field of the player's data changed. (key: string, value: any)
	DataChanged = { Kind = "Event", Direction = "ToClient" },

	-- Client -> server: the Attack action was pressed. The server runs the punch chain, cooldown and hit check.
	-- (facing: Vector3?, position: Vector3?) — the character's facing and position on the sender's screen, used only
	-- to aim a throw when the player holds a prop (the position must be close to the server's view).
	Punch = {
		Kind = "Event",
		Direction = "ToServer",
		Args = { Guard.optional(Guard.vector3(1.5)), Guard.optional(Guard.vector3()) },
	},
	-- Client -> server: the attack is still held after Charged.HoldTime: "Start" (charge), "Release" (let go: the
	-- charged punch) or "Cancel" (stop charging).
	Charge = {
		Kind = "Event",
		Direction = "ToServer",
		Args = { Guard.oneOf({ "Start", "Release", "Cancel" }) },
	},
	-- Client -> server: the Ability key (the equipped style's move, e.g. the Wrecker parry).
	Ability = { Kind = "Event", Direction = "ToServer", Args = {} },
	-- Client -> server: Run held (true) or let go (false); a toggle on gamepad / touch sends the same. (held: boolean)
	-- Stamina decides whether the fighter really runs.
	Run = { Kind = "Event", Direction = "ToServer", Args = { Guard.boolean } },
	-- Client -> server: the Grab action. Grabs the nearest prop in reach, or drops the held one.
	Grab = { Kind = "Event", Direction = "ToServer", Args = {} },
	-- Client -> server: the local player dashed (the client already moved its character). The server checks the
	-- cooldown and hitstun and starts the dash's invulnerability.
	Dash = { Kind = "Event", Direction = "ToServer", Args = {} },
	-- Server -> the victim's client: launch your character. (velocity: Vector3, hitstun: number)
	Knockback = { Kind = "Event", Direction = "ToClient" },
	-- Server -> all clients: a hit landed, for feedback (camera shake, the victim's hit / tumble animation; VFX/SFX
	-- later). (attacker: Model, victim: Model, attack: "Punch" | "Charged" | "Parry" | prop type, heavy: boolean,
	-- trail: boolean, hitstun: number — seconds, weapon: string — the attacker's style weapon, for the hit sound)
	CombatHit = { Kind = "UnreliableEvent", Direction = "ToClient" },
	-- Server -> clients: play a scripted animation clip (Shared/Animation/Clips) on a character. (character: Model,
	-- clip: string)
	Animate = { Kind = "UnreliableEvent", Direction = "ToClient" },
	-- Server -> clients: draw a one-off visual effect (Server/Visuals/Effects lists the kinds).
	-- (kind: string, position: Vector3, data: { [string]: any })
	Effect = { Kind = "UnreliableEvent", Direction = "ToClient" },

	-- Client -> server: vote during the intermission. (kind: "Map" | "Mode", option: map or mode id)
	Vote = {
		Kind = "Event",
		Direction = "ToServer",
		Args = { Guard.oneOf({ "Map", "Mode" }), Guard.string(32) },
	},
	-- Server -> client: the ballot and vote counts (sent when voting opens and after every vote).
	-- (maps: { string }, modes: { string }, mapCounts: { [string]: number }, modeCounts: { [string]: number })
	VoteState = { Kind = "Event", Direction = "ToClient" },
	-- Server -> one client: what they earned in the round that just ended.
	-- (scrap: number, xp: number, level: number, levelsGained: number, newRank: string? — a rank id when it changed)
	RoundReward = { Kind = "Event", Direction = "ToClient" },
	-- Server -> all clients: a KO in the round, for the kill feed.
	-- (killerName: string?, victimName: string, weapon: string? — "Punch", "Charged", "Parry" or a prop type)
	KillFeed = { Kind = "UnreliableEvent", Direction = "ToClient" },
	-- Server -> all clients: final standings when a round ends.
	-- (rows: { { UserId, Name, Placement, KOs, Falls, Score, Lives? } }, modeId: string, mapId: string)
	RoundResults = { Kind = "Event", Direction = "ToClient" },
	-- Client -> server: spectate this player (UserId), or 0 to stop. Only while the sender is spectating.
	Spectate = { Kind = "Event", Direction = "ToServer", Args = { Guard.integer(0, 2 ^ 53) } },
	-- Client -> server: "I had input lately" (AFK tracking), at most every Round.Participation.ActivityPingInterval.
	Activity = { Kind = "Event", Direction = "ToServer", Args = {}, RateLimit = { Rate = 1, Burst = 3 } },

	-- Client -> server: equip an owned fighting style (refused while fighting in a round). (styleId: string)
	EquipStyle = { Kind = "Event", Direction = "ToServer", Args = { Guard.keyOf(Config.Styles.List) } },
	-- Client -> server: equip an owned cosmetic in its slot, or nil to take the slot off. (slot: string, itemId: string?)
	EquipCosmetic = {
		Kind = "Event",
		Direction = "ToServer",
		Args = {
			Guard.oneOf(Config.Cosmetics.Slots),
			Guard.optional(Guard.keyOf(Config.Cosmetics.Items)),
		},
	},
	-- Client -> server: buy a style or cosmetic with Scrap. (kind: "Style" | "Cosmetic", id: string, price: number —
	-- the price the Shop showed; a different price today is refused). Returns (ok: boolean, reason: string?), the
	-- reason being one of Shared/ShopRules.Reasons.
	Buy = {
		Kind = "Function",
		Direction = "ToServer",
		Args = { Guard.oneOf({ "Style", "Cosmetic" }), Guard.string(32), Guard.integer(0, 1000000) },
		RateLimit = { Rate = 2, Burst = 4 },
	},
	-- Client -> server: claim today's login-streak reward (Shared/DailyRules). Returns (claimed: boolean, reward or
	-- reason: { Day, Scrap, Cosmetic? } | "Claimed" | "NotLoaded" | "PrivateServer").
	ClaimDaily = {
		Kind = "Function",
		Direction = "ToServer",
		Args = {},
		RateLimit = { Rate = 1, Burst = 3 },
	},
	-- Client -> server: a developer panel command (only allowed players; see Server/Dev/DevRules).
	-- (command: string, text: string? — a map / mode / prop id, value: number? — a Percent or HP)
	DevCommand = {
		Kind = "Event",
		Direction = "ToServer",
		Args = { Guard.string(24), Guard.optional(Guard.string(32)), Guard.optional(Guard.range(0, 1000)) },
		RateLimit = { Rate = 5, Burst = 10 },
	},

	-- Client -> server: the private server's owner changes a setting (Shared/PrivateServerRules; the server checks the
	-- owner). (key: "Mode" | "Map" | "RoundTime", text: string? — "Vote" or a mode / map id, seconds: number? — RoundTime)
	PrivateServerSetting = {
		Kind = "Event",
		Direction = "ToServer",
		Args = {
			Guard.oneOf({ "Mode", "Map", "RoundTime" }),
			Guard.optional(Guard.string(32)),
			Guard.optional(Guard.integer(0, 3600)),
		},
	},

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
