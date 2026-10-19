--!strict
--[[
	RoundService — the round loop (bible §2.1 "Modes and round rules", §3.1, §3.3):
	Waiting → Voting (map + mode, VoteTime) → Playing (RoundTime) → Results (ResultsTime) → Voting ...

	  * Join pad: only players standing on the lobby's join pad (QueueZone tag, Server/Round/Queue) and not AFK are
	    queued; everyone else stays in the lobby (Shop, Locker ...) through the round. Player attribute QueueStatus
	    ("In" | "AFK" | "Off"), Workspace attribute PlayersQueued. Fighters start spread over the platforms
	    (Round/SpawnPlan).
	  * Waiting: fewer than Config.Round.MinPlayers players are queued (Config.Dev.StudioMinPlayers in Studio).
	  * Voting: up to Maps.VoteChoices enabled maps and every mode are on the ballot (Vote remote; only players on the
	    pad vote, and stepping off drops your vote); ties are random. Too few on the pad = back to Waiting. In a
	    private server the owner's locked mode / picked map is the only option, and the owner sets the round length
	    (PrivateServerService).
	  * Playing: the voted arena is loaded and every queued player is moved to a spawn point with a spawn shield. A KO
	    (CombatService) costs the player their character: Roblox respawns it after RespawnDelay and it is moved back
	    into the arena with a fresh fighter and a new shield. Classic: 3 lives, out of lives = spectate, last fighter
	    standing wins. Casual: unlimited respawns, score = KOs − falls, passive Percent gain, and players who step on
	    the pad join after RespawnDelay. In Classic the pad queues for the next round.
	  * Results: everyone returns to the lobby; standings go to clients (RoundResults) and to RoundEnded, which the
	    round rewards (step 2.1) pay from. Lifetime stats are counted here (not in private servers).
	Participation: clients report input (Activity); AFK = no input for AFKTimeout. Only active time counts toward
	the MinSeconds needed for placement rewards, and AFK players are left out of the next round.

	UI reads attributes: Workspace RoundState / RoundEndsAt (server time) / RoundMode / RoundMap / PlayersNeeded /
	PlayersQueued; Player RoundStatus ("Lobby" | "Playing" | "Respawning" | "Spectating") / QueueStatus / Lives /
	KOs / Falls.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))

local Server = script.Parent.Parent
local Queue = require(Server:WaitForChild("Round"):WaitForChild("Queue"))
local Scoreboard = require(Server:WaitForChild("Round"):WaitForChild("Scoreboard"))
local SpawnPlan = require(Server:WaitForChild("Round"):WaitForChild("SpawnPlan"))
local Vote = require(Server:WaitForChild("Round"):WaitForChild("Vote"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))

export type State = "Waiting" | "Voting" | "Playing" | "Results"
export type Status = "Lobby" | "Playing" | "Respawning" | "Spectating"

-- One player's round, as the rewards step needs it (Formulas.roundPayout input fields).
export type Result = {
	Player: Player,
	Placement: number,
	KOs: number,
	KOScrap: number,
	PerfectDodges: number,
	Completed: boolean,
	ActiveSeconds: number,
	AFKAtEnd: boolean,
}

export type Summary = {
	ModeId: string,
	MapId: string,
	Duration: number,
	Results: { Result },
}

type Round = {
	ModeId: string,
	MapId: string,
	StartedAt: number,
	EndsAt: number,
	StartedWith: number,
	Board: Scoreboard.Board,
	NextPassiveGainAt: number,
}

local TICK = 0.25
local SPAWN_WAIT = 10
local QUEUE_TAG = "QueueZone"

local RoundService = {
	Priority = 0, -- after CombatService, whose knock-out and fall handlers this replaces
	-- (modeId, mapId) when a round starts, right after its arena is loaded and before players are moved in.
	RoundStarted = Signal.new() :: Signal.Signal<string, string>,
	-- (summary) when a round ends, before everyone returns to the lobby.
	RoundEnded = Signal.new() :: Signal.Signal<Summary>,
}

local state: State = "Waiting"
local round: Round? = nil
local mapVote: Vote.Vote? = nil
local modeVote: Vote.Vote? = nil
local voteEndsAt = 0
local statuses: { [Player]: Status } = {}
local lastActive: { [Player]: number } = {}
local joinAt: { [Player]: number } = {} -- Casual: players waiting to join the running round
local queueStatuses: { [Player]: Queue.Status } = {}
local rng = Random.new()
-- Developer panel overrides (RoundService.forceNext / startNow).
local forced: { Map: string?, Mode: string? } = { Map = nil, Mode = nil }
local startRequested = false

local function pick(count: number): number
	return rng:NextInteger(1, count)
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Round] {message}`)
	end
end

-- Counts a lifetime stat, except where progress doesn't count (private servers: PrivateServerService).
local function countStat(player: Player, stat: string)
	if PrivateServerService.countsProgress() then
		DataService.incrementStat(player, stat)
	end
end

local function minPlayers(): number
	return if RunService:IsStudio() then Config.Dev.StudioMinPlayers else Config.Round.MinPlayers
end

-- Players needed right now: one after a developer "start now", until that round has started.
local function needed(): number
	return if startRequested then 1 else minPlayers()
end

local function setState(newState: State, endsAt: number?)
	state = newState
	Workspace:SetAttribute("RoundState", newState)
	Workspace:SetAttribute("RoundEndsAt", endsAt)
	log(newState)
end

local function setStatus(player: Player, status: Status)
	statuses[player] = status
	player:SetAttribute("RoundStatus", status)
end

local function syncScore(player: Player)
	local r = round
	local entry = r and Scoreboard.get(r.Board, player.UserId)
	player:SetAttribute("Lives", entry and entry.Lives)
	player:SetAttribute("KOs", entry and entry.KOs)
	player:SetAttribute("Falls", entry and entry.Falls)
end

local function aliveCharacter(player: Player): Model?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return if character and humanoid and humanoid.Health > 0 then character else nil
end

-- Loaded data and a living character.
local function isReady(player: Player): boolean
	return DataService.get(player) ~= nil and aliveCharacter(player) ~= nil
end

local function isAFK(player: Player): boolean
	return now() - (lastActive[player] or now()) >= Config.Round.Participation.AFKTimeout
end

local function onPad(player: Player): boolean
	local character = aliveCharacter(player)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return false
	end
	for _, pad in CollectionService:GetTagged(QUEUE_TAG) do
		if pad:IsA("BasePart") and Queue.contains(pad.CFrame, pad.Size, root.Position, Config.Round.Queue.Height) then
			return true
		end
	end
	return false
end

-- Updates every player's queue status (and the attributes the UI reads). Returns the queued players.
local function refreshQueue(): { Player }
	local queued: { Player } = {}
	for _, player in Players:GetPlayers() do
		local ready = DataService.get(player) ~= nil and onPad(player)
		local status: Queue.Status = Queue.status(statuses[player] or "Lobby", ready, isAFK(player))
		queueStatuses[player] = status
		if player:GetAttribute("QueueStatus") ~= status then
			player:SetAttribute("QueueStatus", status)
		end
		if status == "In" then
			table.insert(queued, player)
		end
	end
	Workspace:SetAttribute("PlayersQueued", #queued)
	return queued
end

local function isQueued(player: Player): boolean
	return queueStatuses[player] == "In"
end

local function markActive(player: Player)
	lastActive[player] = now()
	local r = round
	if r then
		Scoreboard.markActive(r.Board, player.UserId, now())
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Arena entry
---------------------------------------------------------------------------------------------------------------------

-- The name of the platform a marker stands on (its Platform-tagged ancestor).
local function platformOf(marker: Instance): string
	local node = marker.Parent
	while node and not node:HasTag("Platform") do
		node = node.Parent
	end
	return if node then node.Name else ""
end

-- Puts a participant's (living) character into the arena: fresh fighter, spawn point, spawn shield.
local function enterArena(player: Player, spawnPoint: BasePart?)
	local character = aliveCharacter(player)
	if character == nil then
		return
	end
	setStatus(player, "Playing")
	syncScore(player)
	CombatService.resetFighter(character)
	MapService.sendToArena(player, spawnPoint)
	CombatService.shield(character, Config.Round.SpawnShieldTime)
end

-- Adds a player to the running round (Casual late joiner) and puts them in.
local function joinRound(player: Player)
	local r = round
	if r == nil or not isReady(player) then
		return
	end
	Scoreboard.add(r.Board, player.UserId, player.Name, now())
	log(`{player.Name} joined the round`)
	enterArena(player)
end

---------------------------------------------------------------------------------------------------------------------
-- Knock-outs and falls
---------------------------------------------------------------------------------------------------------------------

local function kill(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0 -- Roblox respawns the player after Players.RespawnTime (= RespawnDelay)
	end
end

local function onKnockOut(character: Model, killer: Player?, cause: CombatService.KOCause, weapon: string?)
	local player = Players:GetPlayerFromCharacter(character)
	if player == nil then
		return
	end
	local r = round
	if r == nil or statuses[player] ~= "Playing" then
		-- Not in a round (lobby, or a stray in the arena): back to the lobby with a fresh fighter.
		CombatService.resetFighter(character)
		task.spawn(MapService.sendToLobby, player)
		return
	end
	local victim = Scoreboard.recordKO(r.Board, player.UserId, killer and killer.UserId, cause == "Fall", now())
	countStat(player, "Falls")
	if killer and Scoreboard.get(r.Board, killer.UserId) then
		countStat(killer, "KOs")
		if cause == "Fall" then
			countStat(killer, "RingOuts")
		end
		if weapon and Config.Props.Types[weapon] then
			countStat(killer, "PropKOs")
			if weapon == "Chair" then
				countStat(killer, "ChairKOs")
			end
		end
		syncScore(killer)
	end
	syncScore(player)
	local eliminated = victim ~= nil and victim.Eliminated
	setStatus(player, if eliminated then "Spectating" else "Respawning")
	log(
		`{player.Name} KO'd ({cause}) by {if killer then killer.Name else "nobody"}{if eliminated then ", out" else ""}`
	)
	Net.fireAll("KillFeed", if killer then killer.DisplayName else nil, player.DisplayName, weapon)
	kill(character)
end

local function onFall(player: Player, zone: MapService.FallZone)
	local character = aliveCharacter(player)
	if character == nil then
		return -- a knocked-out body falling while it waits for the respawn
	end
	if zone == "Arena" and statuses[player] == "Playing" then
		CombatService.knockOut(character, "Fall")
	else
		MapService.sendToLobby(player)
	end
end

local function onPerfectDodge(character: Model, _attacker: Player)
	local player = Players:GetPlayerFromCharacter(character)
	local r = round
	if player and r and statuses[player] == "Playing" then
		Scoreboard.recordPerfectDodge(r.Board, player.UserId)
		countStat(player, "PerfectDodges")
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Players
---------------------------------------------------------------------------------------------------------------------

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", SPAWN_WAIT)
	if humanoid and humanoid:IsA("Humanoid") then
		-- Resetting the character in the arena counts as a fall (the last attacker still gets the KO).
		humanoid.Died:Connect(function()
			if statuses[player] == "Playing" then
				CombatService.knockOut(character, "Fall")
			end
		end)
	end
	if character:WaitForChild("HumanoidRootPart", SPAWN_WAIT) == nil or round == nil then
		return
	end
	if statuses[player] == "Respawning" then
		enterArena(player)
	end
end

local function onPlayerAdded(player: Player)
	lastActive[player] = now()
	setStatus(player, "Lobby") -- late joiners stay in the lobby; the join pad takes them into a round
	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
	local mv, dv = mapVote, modeVote
	if state == "Voting" and mv and dv then
		Net.fireClient("VoteState", player, mv.Options, dv.Options, Vote.counts(mv), Vote.counts(dv))
	end
end

local function onPlayerRemoving(player: Player)
	local r = round
	if r then
		Scoreboard.leave(r.Board, player.UserId)
	end
	for _, vote in { mapVote, modeVote } do
		if vote then
			Vote.remove(vote, player.UserId)
		end
	end
	statuses[player] = nil
	lastActive[player] = nil
	joinAt[player] = nil
	queueStatuses[player] = nil
end

---------------------------------------------------------------------------------------------------------------------
-- Voting
---------------------------------------------------------------------------------------------------------------------

local function broadcastVote()
	local mv, dv = mapVote, modeVote
	if mv and dv then
		Net.fireAll("VoteState", mv.Options, dv.Options, Vote.counts(mv), Vote.counts(dv))
	end
end

-- Drops the votes of players who are no longer queued (stepped off the pad, left). True if any was dropped.
local function dropUnqueuedVotes(): boolean
	local dropped = false
	for _, vote in { mapVote, modeVote } do
		if vote then
			for userId in vote.Choices do
				local player = Players:GetPlayerByUserId(userId)
				if player == nil or queueStatuses[player] == "Off" then
					Vote.remove(vote, userId)
					dropped = true
				end
			end
		end
	end
	return dropped
end

local function onVote(player: Player, kind: string, option: string)
	-- Only players on the pad vote (an AFK one too: voting is input, so they count again).
	if state ~= "Voting" or (queueStatuses[player] or "Off") == "Off" then
		return
	end
	local vote = if kind == "Map" then mapVote else modeVote
	if vote and Vote.cast(vote, player.UserId, option) then
		markActive(player)
		if kind == "Map" then
			Analytics.mapVoted(player, option)
		end
		broadcastVote()
	end
end

-- Runs the vote. Returns the winning map and mode, or nil if too few players stayed.
local function runVote(): (string?, string?)
	local maps =
		PrivateServerService.ballot("Map", Vote.pickOptions(MapService.getEnabledMaps(), Config.Maps.VoteChoices, pick))
	if #maps == 0 then
		warn("[RoundService] no enabled arena to vote for")
		task.wait(Config.Round.VoteTime)
		return nil, nil
	end
	local mv = Vote.new(maps)
	local dv = Vote.new(PrivateServerService.ballot("Mode", Config.Modes.Order))
	mapVote, modeVote = mv, dv
	voteEndsAt = now() + Config.Round.VoteTime
	setState("Voting", voteEndsAt)
	broadcastVote()
	while now() < voteEndsAt do
		task.wait(TICK)
		if #refreshQueue() < needed() then
			log("too few players on the join pad; back to waiting")
			mapVote, modeVote = nil, nil
			return nil, nil
		end
		if dropUnqueuedVotes() then
			broadcastVote()
		end
	end
	mapVote, modeVote = nil, nil
	local mapId, modeId = forced.Map or Vote.winner(mv, pick), forced.Mode or Vote.winner(dv, pick)
	forced.Map, forced.Mode = nil, nil
	return mapId, modeId
end

---------------------------------------------------------------------------------------------------------------------
-- Playing
---------------------------------------------------------------------------------------------------------------------

local function startRound(mapId: string, modeId: string): boolean
	local participants = refreshQueue()
	if #participants < needed() then
		log("not enough active players on the join pad; back to waiting")
		return false
	end
	startRequested = false

	CombatService.setMode(modeId)
	MapService.loadArena(mapId)
	local startedAt = now()
	local r: Round = {
		ModeId = modeId,
		MapId = mapId,
		StartedAt = startedAt,
		EndsAt = startedAt + PrivateServerService.roundTime(),
		StartedWith = #participants,
		Board = Scoreboard.new(modeId),
		NextPassiveGainAt = startedAt + (Config.Modes.List[modeId].PassiveGainInterval or math.huge),
	}
	round = r
	Workspace:SetAttribute("RoundMode", modeId)
	Workspace:SetAttribute("RoundMap", mapId)
	setState("Playing", r.EndsAt)
	log(`{modeId} on {mapId} with {#participants} player(s)`)
	RoundService.RoundStarted:Fire(modeId, mapId)

	-- Everyone not on the pad stays in the lobby (status "Lobby").
	-- Fighters start spread over the platforms (Round/SpawnPlan).
	local spawns = MapService.getArenaMarkers("SpawnPoint")
	local platforms: { string } = {}
	for index, spawn in spawns do
		platforms[index] = platformOf(spawn)
	end
	local groups: { { number } } = {}
	for _, player in participants do
		table.insert(groups, { player.UserId })
	end
	local plan = SpawnPlan.assign(groups, platforms, pick)
	for _, player in participants do
		Scoreboard.add(r.Board, player.UserId, player.Name, startedAt)
		local data = DataService.get(player)
		Analytics.roundModePicked(player, modeId, mapId)
		Analytics.styleUsed(player, if data then data.Styles.Equipped else Config.Styles.Default, modeId)
		local spawnIndex = plan[player.UserId]
		task.spawn(enterArena, player, if spawnIndex then spawns[spawnIndex] else nil)
	end
	return true
end

-- One tick of a running round: active time, Casual passive gain and late joiners.
local function tickRound(r: Round, dt: number)
	local t = now()
	Scoreboard.tick(r.Board, dt, t)
	local mode = Config.Modes.List[r.ModeId]

	if t >= r.NextPassiveGainAt then
		r.NextPassiveGainAt += mode.PassiveGainInterval or math.huge
		for player, status in statuses do
			local character = aliveCharacter(player)
			if status == "Playing" and character then
				CombatService.addPercent(character, mode.PassiveGainAmount or 0)
			end
		end
	end

	if mode.JoinMidRound then
		for player, status in statuses do
			local entry = Scoreboard.get(r.Board, player.UserId)
			-- Players who step on the join pad join after RespawnDelay (stepping off cancels).
			local waiting = status ~= "Playing" and status ~= "Respawning" and (entry == nil or Scoreboard.isIn(entry))
			if not waiting or not isQueued(player) or not isReady(player) then
				joinAt[player] = nil
			elseif joinAt[player] == nil then
				joinAt[player] = t + Config.Round.RespawnDelay
			elseif t >= joinAt[player] then
				joinAt[player] = nil
				task.spawn(joinRound, player)
			end
		end
	end
end

local function playRound()
	local r = round :: Round
	local last = now()
	while now() < r.EndsAt and not Scoreboard.isDecided(r.Board, r.StartedWith) do
		task.wait(TICK)
		local t = now()
		tickRound(r, t - last)
		last = t
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Results
---------------------------------------------------------------------------------------------------------------------

local function endRound()
	local r = round :: Round
	local endedAt = now()
	local duration = endedAt - r.StartedAt
	local standings = Scoreboard.standings(r.Board)
	local results: { Result } = {}
	local rows = {}
	for _, standing in standings do
		local entry = standing.Entry
		local player = Players:GetPlayerByUserId(entry.UserId)
		if player == nil then
			continue
		end
		local afk = Scoreboard.isAFK(entry, endedAt)
		local eligible = entry.ActiveSeconds >= Config.Round.Participation.MinSeconds and not afk
		countStat(player, "RoundsPlayed")
		countStat(player, "RoundsCompleted")
		if standing.Placement == 1 and eligible then
			countStat(player, "Wins")
		end
		Analytics.roundFinished(player, duration, entry.KOs, r.ModeId, r.MapId)
		table.insert(results, {
			Player = player,
			Placement = standing.Placement,
			KOs = entry.KOs,
			KOScrap = entry.KOScrap,
			PerfectDodges = entry.PerfectDodges,
			Completed = true,
			ActiveSeconds = entry.ActiveSeconds,
			AFKAtEnd = afk,
		})
		table.insert(rows, {
			UserId = entry.UserId,
			Name = player.DisplayName,
			Placement = standing.Placement,
			KOs = entry.KOs,
			Falls = entry.Falls,
			Score = Scoreboard.score(entry),
			Lives = entry.Lives,
		})
	end
	log(`ended after {math.floor(duration)} s; winner: {if rows[1] then rows[1].Name else "none"}`)
	RoundService.RoundEnded:Fire({ ModeId = r.ModeId, MapId = r.MapId, Duration = duration, Results = results })

	round = nil
	table.clear(joinAt)
	setState("Results", endedAt + Config.Round.ResultsTime)
	Net.fireAll("RoundResults", rows, r.ModeId, r.MapId)
	CombatService.setMode(Config.Modes.Default)
	for _, player in Players:GetPlayers() do
		setStatus(player, "Lobby")
		syncScore(player)
		player.ReplicationFocus = nil
		local character = aliveCharacter(player)
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and MapService.getZone(root.Position) == "Arena" then
			task.spawn(MapService.sendToLobby, player)
		end
	end
	task.wait(Config.Round.ResultsTime)
	MapService.unloadArena()
	Workspace:SetAttribute("RoundMode", nil)
	Workspace:SetAttribute("RoundMap", nil)
end

---------------------------------------------------------------------------------------------------------------------
-- Spectating
---------------------------------------------------------------------------------------------------------------------

-- A spectator asks to watch `targetUserId` (0 = stop). The server streams the area around the target to them.
local function onSpectate(player: Player, targetUserId: number)
	if targetUserId == 0 or statuses[player] ~= "Spectating" then
		player.ReplicationFocus = nil
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	local character = target and statuses[target] == "Playing" and aliveCharacter(target)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		player.ReplicationFocus = root
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------------------------------------------------

local function loop()
	while true do
		Workspace:SetAttribute("PlayersNeeded", minPlayers())
		setState("Waiting")
		while #refreshQueue() < needed() do
			task.wait(TICK)
		end
		local mapId, modeId = runVote()
		if mapId and modeId and startRound(mapId, modeId) then
			playRound()
			endRound()
		end
	end
end

function RoundService.getState(): State
	return state
end

-- The running round's mode, or nil between rounds (quests that count in one mode only).
function RoundService.currentMode(): string?
	local r = round
	return if r then r.ModeId else nil
end

-- True when the player has sent no input for Round.Participation.AFKTimeout (playtime rewards skip AFK time).
function RoundService.isAFK(player: Player): boolean
	return isAFK(player)
end

function RoundService.getStatus(player: Player): Status
	return statuses[player] or "Lobby"
end

-- Developer panel: the next round uses this map ("Map", an enabled map) or mode ("Mode") whatever the vote says;
-- nil lets the vote decide again. Returns false for an unknown id.
function RoundService.forceNext(kind: "Map" | "Mode", id: string?): boolean
	if kind == "Map" then
		if id and not table.find(MapService.getEnabledMaps(), id) then
			return false
		end
		forced.Map = id
	else
		if id and Config.Modes.List[id] == nil then
			return false
		end
		forced.Mode = id
	end
	return true
end

-- Developer panel: while waiting, starts the vote even with too few players; while voting, closes the vote now.
function RoundService.startNow()
	startRequested = true
	if state == "Voting" then
		voteEndsAt = now()
	end
end

-- Developer panel: ends the running round now (standings and results as at a time-out).
function RoundService.endNow()
	local r = round
	if r and state == "Playing" then
		r.EndsAt = now()
	end
end

function RoundService.Init(_self: any)
	Players.RespawnTime = Config.Round.RespawnDelay
	CombatService.setKnockOutHandler(onKnockOut)
	MapService.setFallHandler(onFall)
	CombatService.PerfectDodged:Connect(onPerfectDodge)

	Net.onServerEvent("Vote", onVote)
	Net.onServerEvent("Spectate", onSpectate)
	Net.onServerEvent("Activity", markActive)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

function RoundService.Start(_self: any)
	-- Keeps QueueStatus / PlayersQueued current in every state (the loop below also refreshes when it decides).
	task.spawn(function()
		while true do
			refreshQueue()
			task.wait(TICK)
		end
	end)
	loop()
end

return RoundService
