--!strict
-- Parties (step 3.7): invites, joining, leaving, kicking; parties start on one platform.
local Roblox = require("../roblox")
local expect = require("../expect")

local Server = Roblox.game.ServerScriptService.Server
local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local Parties = Roblox.require(Server.Social.Parties)
local SpawnPlan = Roblox.require(Server.Round.SpawnPlan)

local NOW, TIMEOUT = 100, 30

-- A "random" pick that always takes the first option (deterministic plans).
local function first(_count: number): number
	return 1
end

return {
	["bible: parties of up to 4"] = function()
		expect.equal(Config.Retention.Party.MaxSize, 4)
	end,
	["invite and accept: the inviter leads a new party; joining another party clears other invites"] = function()
		local state = Parties.new(4)
		expect.truthy(Parties.invite(state, 1, 2, NOW, TIMEOUT))
		expect.truthy(Parties.invite(state, 3, 2, NOW, TIMEOUT))
		local ok, partyId = Parties.respond(state, 2, 1, true, NOW + 1)
		expect.truthy(ok)
		expect.truthy(partyId)
		expect.equal(Parties.leaderOf(state, 2), 1)
		expect.equal(Parties.leaderOf(state, 1), 1)
		local again, reason = Parties.respond(state, 2, 3, true, NOW + 1)
		expect.equal(again, false)
		expect.equal(reason, "NoInvite", "the other invite lapsed")
	end,
	["refusals: yourself, non-leaders, players already in a party, a full party, old invites"] = function()
		local state = Parties.new(3)
		expect.equal(select(2, Parties.invite(state, 1, 1, NOW, TIMEOUT)), "Self")
		Parties.invite(state, 1, 2, NOW, TIMEOUT)
		Parties.respond(state, 2, 1, true, NOW)
		expect.equal(select(2, Parties.invite(state, 2, 5, NOW, TIMEOUT)), "NotLeader")
		expect.equal(select(2, Parties.invite(state, 4, 2, NOW, TIMEOUT)), "InParty")
		Parties.invite(state, 1, 3, NOW, TIMEOUT)
		Parties.respond(state, 3, 1, true, NOW)
		expect.equal(select(2, Parties.invite(state, 1, 4, NOW, TIMEOUT)), "Full")
		local fresh = Parties.new(4)
		Parties.invite(fresh, 1, 2, NOW, TIMEOUT)
		expect.equal(select(2, Parties.respond(fresh, 2, 1, true, NOW + TIMEOUT + 1)), "NoInvite", "expired")
		Parties.invite(fresh, 1, 2, NOW, TIMEOUT)
		expect.truthy(Parties.respond(fresh, 2, 1, false, NOW))
		expect.equal(Parties.partyOf(fresh, 2), nil, "declined")
	end,
	["leaving passes the lead on; a party of one ends; the leader can kick"] = function()
		local state = Parties.new(4)
		for _, member in { 2, 3 } do
			Parties.invite(state, 1, member, NOW, TIMEOUT)
			Parties.respond(state, member, 1, true, NOW)
		end
		Parties.leave(state, 1)
		expect.equal(Parties.leaderOf(state, 2), 2, "the lead passes on")
		expect.equal(Parties.leaderOf(state, 3), 2)
		expect.equal(select(2, Parties.kick(state, 3, 2)), "NotLeader")
		expect.truthy(Parties.kick(state, 2, 3))
		expect.equal(Parties.partyOf(state, 3), nil)
		expect.equal(Parties.partyOf(state, 2), nil, "a party of one ends")
	end,
	["quitting the server leaves the party and drops invites to and from you"] = function()
		local state = Parties.new(4)
		Parties.invite(state, 1, 2, NOW, TIMEOUT)
		Parties.invite(state, 3, 1, NOW, TIMEOUT)
		Parties.removePlayer(state, 1)
		expect.equal(select(2, Parties.respond(state, 2, 1, true, NOW)), "NoInvite")
		expect.equal(state.Invites[1], nil)
	end,
	["spawns: a party starts on one platform, solo fighters spread out, points are reused when short"] = function()
		local platforms = { "A", "A", "A", "B", "B", "C" }
		local plan = SpawnPlan.assign({ { 1, 2, 3 }, { 4 }, { 5 } }, platforms, first)
		local function platformOf(userId: number): string
			return platforms[plan[userId]]
		end
		expect.equal(platformOf(1), "A")
		expect.equal(platformOf(2), "A")
		expect.equal(platformOf(3), "A")
		expect.truthy(platformOf(4) ~= "A" and platformOf(5) ~= "A", "solos take the free platforms")
		expect.truthy(platformOf(4) ~= platformOf(5) or platformOf(4) == "B", "spread out")
		local used: { [number]: boolean } = {}
		for userId = 1, 5 do
			expect.equal(used[plan[userId]], nil, "one fighter per point")
			used[plan[userId]] = true
		end
		local crowded = SpawnPlan.assign({ { 1 }, { 2 }, { 3 } }, { "A", "B" }, first)
		expect.truthy(crowded[1] and crowded[2] and crowded[3], "everyone gets a point")
		expect.equal(next(SpawnPlan.assign({ { 1 } }, {}, first)), nil, "no points, no plan")
	end,
}
