--!strict
--[[
	PartyService — parties in this server (bible §8; rules in Server/Social/Parties, Config.Retention.Party).
	Remotes: PartyInvite (target UserId), PartyRespond (inviter UserId, accept), PartyLeave, PartyKick (member UserId);
	the invitee gets PartyInvited (inviter UserId, display name, seconds to answer). Every change sets the Player
	attributes PartyId (nil = no party) and PartyLeader on the members — the party list, name tags and chat tags read
	them — and tells the people involved (Notify).
	What a party does (owner, 2026-10-18): members are taken into a round with their leader (RoundService asks
	`leaderOf`) and start on the same platform (`groupsOf`, Server/Round/SpawnPlan).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Parties = require(script.Parent.Parent:WaitForChild("Social"):WaitForChild("Parties"))

local PartyService = {}

local state = Parties.new(Config.Retention.Party.MaxSize)

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Party] {message}`)
	end
end

local function now(): number
	return os.clock()
end

local function playerOf(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function nameOf(userId: number): string
	local player = playerOf(userId)
	return if player then player.DisplayName else `#{userId}`
end

local function notify(userId: number, key: string, args: { any }?)
	local player = playerOf(userId)
	if player then
		Net.fireClient("Notify", player, key, args)
	end
end

local function sync(userId: number)
	local player = playerOf(userId)
	if player == nil then
		return
	end
	local partyId = Parties.partyOf(state, userId)
	player:SetAttribute("PartyId", partyId)
	player:SetAttribute("PartyLeader", partyId ~= nil and Parties.leaderOf(state, userId) == userId)
end

local function syncParty(partyId: string?)
	local party = partyId and Parties.get(state, partyId)
	if party then
		for _, member in party.Members do
			sync(member)
		end
	end
end

local function refuse(userId: number, reason: string?)
	notify(userId, `Party.Error.{reason or "NoInvite"}`)
end

-- The leader of the player's party, if they are in one (and it isn't them).
function PartyService.leaderOf(player: Player): Player?
	local leader = Parties.leaderOf(state, player.UserId)
	if leader == nil or leader == player.UserId then
		return nil
	end
	return playerOf(leader)
end

-- `players` grouped by party (each party's members in it together; everyone else alone).
function PartyService.groupsOf(players: { Player }): { { number } }
	local groups: { { number } } = {}
	local byParty: { [string]: { number } } = {}
	for _, player in players do
		local partyId = Parties.partyOf(state, player.UserId)
		if partyId then
			local group = byParty[partyId]
			if group == nil then
				group = {}
				byParty[partyId] = group
				table.insert(groups, group)
			end
			table.insert(group, player.UserId)
		else
			table.insert(groups, { player.UserId })
		end
	end
	return groups
end

local function onInvite(player: Player, targetId: number)
	local target = playerOf(targetId)
	if target == nil then
		return
	end
	local timeout = Config.Retention.Party.InviteTimeout
	local ok, reason = Parties.invite(state, player.UserId, targetId, now(), timeout)
	if not ok then
		refuse(player.UserId, reason)
		return
	end
	Net.fireClient("PartyInvited", target, player.UserId, player.DisplayName, timeout)
	notify(player.UserId, "Party.Invited", { target.DisplayName })
	log(`{player.Name} invited {target.Name}`)
end

local function onRespond(player: Player, fromId: number, accept: boolean)
	local ok, result = Parties.respond(state, player.UserId, fromId, accept, now())
	if not ok then
		refuse(player.UserId, result)
		return
	end
	if not accept then
		notify(fromId, "Party.Declined", { player.DisplayName })
		return
	end
	local partyId = result
	syncParty(partyId)
	local party = partyId and Parties.get(state, partyId)
	local members: { number } = if party then party.Members else {}
	for _, member in members do
		if member ~= player.UserId then
			notify(member, "Party.Joined", { player.DisplayName })
		end
	end
	notify(player.UserId, "Party.YouJoined", { nameOf(fromId) })
	log(`{player.Name} joined {nameOf(fromId)}'s party`)
end

-- Removes `userId` from their party and updates / tells everyone who stays.
local function leave(userId: number, removeFully: boolean)
	local partyId = if removeFully then Parties.removePlayer(state, userId) else Parties.leave(state, userId)
	if partyId == nil then
		return
	end
	sync(userId)
	local party = Parties.get(state, partyId)
	if party then
		syncParty(partyId)
		for _, member in party.Members do
			notify(member, "Party.Left", { nameOf(userId) })
		end
	else
		-- Disbanded: the last member is on their own again.
		for _, other in Players:GetPlayers() do
			if other.UserId ~= userId and other:GetAttribute("PartyId") == partyId then
				sync(other.UserId)
				notify(other.UserId, "Party.Disbanded")
			end
		end
	end
end

local function onLeave(player: Player)
	if Parties.partyOf(state, player.UserId) then
		leave(player.UserId, false)
		notify(player.UserId, "Party.YouLeft")
	end
end

local function onKick(player: Player, targetId: number)
	local before = Parties.partyOf(state, targetId)
	local ok, reason = Parties.kick(state, player.UserId, targetId)
	if not ok then
		refuse(player.UserId, reason)
		return
	end
	-- Parties.kick already removed them; sync the kicked player and the rest of the party.
	sync(targetId)
	notify(targetId, "Party.Kicked")
	if before then
		if Parties.get(state, before) then
			syncParty(before)
		else
			sync(player.UserId)
			notify(player.UserId, "Party.Disbanded")
		end
	end
end

function PartyService.Init(_self: any)
	Net.onServerEvent("PartyInvite", onInvite)
	Net.onServerEvent("PartyRespond", onRespond)
	Net.onServerEvent("PartyLeave", onLeave)
	Net.onServerEvent("PartyKick", onKick)
	Players.PlayerRemoving:Connect(function(player: Player)
		leave(player.UserId, true)
	end)
end

return PartyService
