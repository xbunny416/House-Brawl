--!strict
--[[
	Net — the only way client and server talk.

	Server: Net.onServerEvent / Net.onServerInvoke register one handler per remote. Every call is rate-limited per
	player and its arguments are validated against Definitions before the handler runs; bad calls are dropped.
	Server -> client: Net.fireClient / fireAll / fireAllExcept / fireClients.
	Client: Net.fire / Net.invoke / Net.on.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)
local RateLimiter = require(script.Parent.Util.RateLimiter)
local Definitions = require(script.Definitions)
local Guard = require(script.Guard)

local FOLDER_NAME = "Remotes"
local IS_SERVER = RunService:IsServer()

local Net = {}

local folder: Instance
local remotes: { [string]: any } = {}
local handled: { [string]: boolean } = {}
local limiters: { RateLimiter.RateLimiter } = {}
local rejects: { [Player]: number } = {}

local function getDefinition(name: string): Definitions.Definition
	local definition = Definitions[name]
	assert(definition, `Unknown remote "{name}"`)
	return definition
end

local function remoteClass(kind: Definitions.Kind): string
	if kind == "Function" then
		return "RemoteFunction"
	elseif kind == "UnreliableEvent" then
		return "UnreliableRemoteEvent"
	end
	return "RemoteEvent"
end

if IS_SERVER then
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for name, definition in Definitions do
		local remote = Instance.new(remoteClass(definition.Kind))
		remote.Name = name
		remote.Parent = folder
		remotes[name] = remote
	end
	folder.Parent = ReplicatedStorage

	Players.PlayerRemoving:Connect(function(player: Player)
		for _, limiter in limiters do
			limiter:remove(player)
		end
		rejects[player] = nil
	end)
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

local function getRemote(name: string): any
	local remote = remotes[name]
	if remote == nil then
		getDefinition(name)
		remote = folder:WaitForChild(name)
		remotes[name] = remote
	end
	return remote
end

local function reject(player: Player, name: string, reason: string)
	local count = (rejects[player] or 0) + 1
	rejects[player] = count
	if RunService:IsStudio() and count % Config.Net.RejectWarnEvery == 1 then
		warn(`[Net] dropped {name} from {player.Name}: {reason} (x{count})`)
	end
end

-- Builds the gate for one remote: true when a call passes the per-player rate limit and the argument checks.
local function guarded(
	name: string,
	definition: Definitions.Definition
): (Player, { n: number, [number]: any }) -> boolean
	local limit = definition.RateLimit or Config.Net.DefaultRateLimit
	local limiter = RateLimiter.new(limit.Rate, limit.Burst)
	table.insert(limiters, limiter)
	local checks = definition.Args or {}
	return function(player: Player, args: { n: number, [number]: any }): boolean
		if not limiter:allow(player, os.clock()) then
			reject(player, name, "rate limit")
			return false
		end
		if not Guard.args(checks, args) then
			reject(player, name, "invalid arguments")
			return false
		end
		return true
	end
end

local function claim(name: string, kind: "event" | "function"): Definitions.Definition
	assert(IS_SERVER, "server only")
	local definition = getDefinition(name)
	assert(definition.Direction == "ToServer", `{name} is not a ToServer remote`)
	assert((definition.Kind == "Function") == (kind == "function"), `{name} is not a remote {kind}`)
	assert(definition.Args, `{name} must declare Args`)
	assert(not handled[name], `{name} already has a handler`)
	handled[name] = true
	return definition
end

---------------------------------------------------------------------------------------------------------------------
-- Server
---------------------------------------------------------------------------------------------------------------------

-- Handles a client -> server event. The handler only ever sees validated arguments.
function Net.onServerEvent(name: string, handler: (player: Player, ...any) -> ())
	local allow = guarded(name, claim(name, "event"))
	getRemote(name).OnServerEvent:Connect(function(player: Player, ...: any)
		local args = table.pack(...)
		if allow(player, args) then
			handler(player, table.unpack(args, 1, args.n))
		end
	end)
end

-- Handles a client -> server function call. Rejected calls return nil.
function Net.onServerInvoke(name: string, handler: (player: Player, ...any) -> ...any)
	local allow = guarded(name, claim(name, "function"))
	getRemote(name).OnServerInvoke = function(player: Player, ...: any): ...any
		local args = table.pack(...)
		if allow(player, args) then
			return handler(player, table.unpack(args, 1, args.n))
		end
		return nil
	end
end

function Net.fireClient(name: string, player: Player, ...: any)
	getRemote(name):FireClient(player, ...)
end

function Net.fireAll(name: string, ...: any)
	getRemote(name):FireAllClients(...)
end

function Net.fireClients(name: string, players: { Player }, ...: any)
	local remote = getRemote(name)
	for _, player in players do
		remote:FireClient(player, ...)
	end
end

function Net.fireAllExcept(name: string, except: Player, ...: any)
	local remote = getRemote(name)
	for _, player in Players:GetPlayers() do
		if player ~= except then
			remote:FireClient(player, ...)
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Client
---------------------------------------------------------------------------------------------------------------------

function Net.fire(name: string, ...: any)
	getRemote(name):FireServer(...)
end

function Net.invoke(name: string, ...: any): ...any
	return getRemote(name):InvokeServer(...)
end

function Net.on(name: string, handler: (...any) -> ()): RBXScriptConnection
	return getRemote(name).OnClientEvent:Connect(handler)
end

return Net
