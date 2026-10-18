--!strict
--[[
	Parties — who is in which party in one server (bible §8: up to Config.Retention.Party.MaxSize). Pure: players are
	UserIds and time is passed in, so specs can test every rule.
	  * Only a party's leader invites (a player in no party may invite too: the party starts when someone accepts).
	    Nobody already in a party can be invited. An invite lasts until `expiresAt`.
	  * Accepting joins the inviter's party (or starts one with the inviter as leader) if it still has room.
	  * Leaving (or quitting the server) passes the lead to the next member; a party of one is disbanded.
	  * The leader can kick a member.
]]
export type Party = { Leader: number, Members: { number } }
export type State = {
	MaxSize: number,
	Parties: { [string]: Party },
	Of: { [number]: string }, -- UserId -> party id
	Invites: { [number]: { [number]: number } }, -- invitee -> inviter -> expires at
	Next: number,
}

local Parties = {}

-- Why an invite, answer or kick was refused (the client shows "Party.Error.<Reason>").
Parties.Reasons = { "Self", "NotLeader", "InParty", "Full", "NoInvite" }

function Parties.new(maxSize: number): State
	return { MaxSize = maxSize, Parties = {}, Of = {}, Invites = {}, Next = 1 }
end

function Parties.partyOf(state: State, userId: number): string?
	return state.Of[userId]
end

function Parties.get(state: State, partyId: string): Party?
	return state.Parties[partyId]
end

-- The leader of `userId`'s party, or nil when they are in no party.
function Parties.leaderOf(state: State, userId: number): number?
	local partyId = state.Of[userId]
	local party = partyId and state.Parties[partyId]
	return if party then party.Leader else nil
end

local function isFull(state: State, inviter: number): boolean
	local partyId = state.Of[inviter]
	local party = partyId and state.Parties[partyId]
	return party ~= nil and #party.Members >= state.MaxSize
end

-- `from` invites `to`. Returns true, or false and a reason.
function Parties.invite(state: State, from: number, to: number, now: number, timeout: number): (boolean, string?)
	if from == to then
		return false, "Self"
	end
	local leader = Parties.leaderOf(state, from)
	if leader ~= nil and leader ~= from then
		return false, "NotLeader"
	end
	if state.Of[to] ~= nil then
		return false, "InParty"
	end
	if isFull(state, from) then
		return false, "Full"
	end
	local invites = state.Invites[to] or {}
	state.Invites[to] = invites
	invites[from] = now + timeout
	return true, nil
end

--[[
	`to` answers `from`'s invite. Accepting joins `from`'s party (or starts one led by `from`). Returns true and the
	party id when they joined (true and nil for a decline), or false and a reason.
]]
function Parties.respond(state: State, to: number, from: number, accept: boolean, now: number): (boolean, string?)
	local invites = state.Invites[to]
	local expiresAt = invites and invites[from]
	if invites == nil or expiresAt == nil or expiresAt < now then
		return false, "NoInvite"
	end
	invites[from] = nil
	if not accept then
		return true, nil
	end
	if state.Of[to] ~= nil then
		return false, "InParty"
	end
	local leader = Parties.leaderOf(state, from)
	if leader ~= nil and leader ~= from then
		return false, "NoInvite" -- the inviter no longer leads a party
	end
	if isFull(state, from) then
		return false, "Full"
	end
	local partyId = state.Of[from]
	if partyId == nil then
		partyId = `P{state.Next}`
		state.Next += 1
		state.Parties[partyId] = { Leader = from, Members = { from } }
		state.Of[from] = partyId
	end
	local party = state.Parties[partyId :: string]
	table.insert(party.Members, to)
	state.Of[to] = partyId
	state.Invites[to] = nil -- one party at a time: other invites lapse
	return true, partyId
end

-- `userId` leaves their party. Returns the party id they left (nil if they were in none).
function Parties.leave(state: State, userId: number): string?
	local partyId = state.Of[userId]
	local party = partyId and state.Parties[partyId]
	if party == nil then
		return nil
	end
	state.Of[userId] = nil
	local index = table.find(party.Members, userId)
	if index then
		table.remove(party.Members, index)
	end
	if #party.Members <= 1 then
		for _, member in party.Members do
			state.Of[member] = nil
		end
		state.Parties[partyId :: string] = nil
	elseif party.Leader == userId then
		party.Leader = party.Members[1]
	end
	return partyId
end

-- The leader removes `target` from the party. Returns true, or false and a reason.
function Parties.kick(state: State, leader: number, target: number): (boolean, string?)
	if Parties.leaderOf(state, leader) ~= leader then
		return false, "NotLeader"
	end
	if leader == target or state.Of[target] ~= state.Of[leader] then
		return false, "Self"
	end
	Parties.leave(state, target)
	return true, nil
end

-- A player quits the server: they leave their party and every invite to or from them lapses.
function Parties.removePlayer(state: State, userId: number): string?
	state.Invites[userId] = nil
	for _, invites in state.Invites do
		invites[userId] = nil
	end
	return Parties.leave(state, userId)
end

return Parties
