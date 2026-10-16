--!strict
--[[
	RoundService — the round loop (bible §2.1 "Modes and round rules", §3.1, §3.3):
	Waiting → Voting (map + mode, VoteTime) → Playing (RoundTime) → Results (ResultsTime) → Voting ...

	  * Waiting: fewer than Config.Round.MinPlayers players are ready (Config.Dev.StudioMinPlayers in Studio).
	  * Voting: up to Maps.VoteChoices enabled maps and every mode are on the ballot (Vote remote); ties are random.
	  * Playing: the voted arena is loaded and every ready, non-AFK player is moved to a spawn point with a spawn
	    shield. A KO (CombatService) costs the player their character: Roblox respawns it after RespawnDelay and it is
	    moved back into the arena with a fresh fighter and a new shield. Classic: 3 lives, out of lives = spectate,
	    last fighter standing wins. Casual: unlimited respawns, score = KOs − falls, passive Percent gain, and players
	    not in the round join after RespawnDelay. Classic late joiners spectate.
	  * Results: everyone returns to the lobby; standings go to clients (RoundResults) and to RoundEnded, which the
	    round rewards (step 2.1) pay from. Lifetime stats are counted here.
	Participation: clients report input (Activity); AFK = no input for AFKTimeout. Only active time counts toward
	the MinSeconds needed for placement rewards, and AFK players are left out of the next round.

	UI reads attributes: Workspace RoundState / RoundEndsAt (server time) / RoundMode / RoundMap / PlayersNeeded;
	Player RoundStatus ("Lobby" | "Playing" | "Respawning" | "Spectating") / Lives / KOs / Falls.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))

local Server = script.Parent.Parent
local Scoreboard = require(Server:WaitForChild("Round"):WaitForChild("Scoreboard"))
local Vote = require(Server:WaitForChild("Round"):WaitForChild("Vote"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MapService = require(script.Parent:WaitForChild("MapService"))

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

local RoundService = {
	Priority = 0, -- after CombatService, whose knock-out and fall handlers this replaces
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
local rng = Random.new()

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

local function minPlayers(): number
	return if RunService:IsStudio() then Config.Dev.StudioMinPlayers else Config.Round.MinPlayers
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

local function readyPlayers(): { Player }
	local ready: { Player } = {}
	for _, player in Players:GetPlayers() do
		if isReady(player) then
			table.insert(ready, player)
		end
	end
	return ready
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

local function shuffled<T>(list: { T }): { T }
	local copy = table.clone(list)
	for index = #copy, 2, -1 do
		local other = pick(index)
		copy[index], copy[other] = copy[other], copy[index]
	end
	return copy
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

local function onKnockOut(character: Model, killer: Player?, cause: CombatService.KOCause)
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
	DataService.incrementStat(player, "Falls")
	if killer and Scoreboard.get(r.Board, killer.UserId) then
		DataService.incrementStat(killer, "KOs")
		if cause == "Fall" then
			DataService.incrementStat(killer, "RingOuts")
		end
		syncScore(killer)
	end
	syncScore(player)
	local eliminated = victim ~= nil and victim.Eliminated
	setStatus(player, if eliminated then "Spectating" else "Respawning")
	log(
		`{player.Name} KO'd ({cause}) by {if killer then killer.Name else "nobody"}{if eliminated then ", out" else ""}`
	)
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
		DataService.incrementStat(player, "PerfectDodges")
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
	setStatus(player, if round then "Spectating" else "Lobby")
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

local function onVote(player: Player, kind: string, option: string)
	if state ~= "Voting" then
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
	local maps = Vote.pickOptions(MapService.getEnabledMaps(), Config.Maps.VoteChoices, pick)
	if #maps == 0 then
		warn("[RoundService] no enabled arena to vote for")
		task.wait(Config.Round.VoteTime)
		return nil, nil
	end
	local mv = Vote.new(maps)
	local dv = Vote.new(Config.Modes.Order)
	mapVote, modeVote = mv, dv
	voteEndsAt = now() + Config.Round.VoteTime
	setState("Voting", voteEndsAt)
	broadcastVote()
	while now() < voteEndsAt do
		task.wait(TICK)
		if #readyPlayers() < minPlayers() then
			mapVote, modeVote = nil, nil
			return nil, nil
		end
	end
	mapVote, modeVote = nil, nil
	return Vote.winner(mv, pick), Vote.winner(dv, pick)
end

---------------------------------------------------------------------------------------------------------------------
-- Playing
---------------------------------------------------------------------------------------------------------------------

local function startRound(mapId: string, modeId: string): boolean
	local participants: { Player } = {}
	for _, player in readyPlayers() do
		if not isAFK(player) then
			table.insert(participants, player)
		end
	end
	if #participants < minPlayers() then
		log("not enough active players; back to waiting")
		return false
	end

	CombatService.setMode(modeId)
	MapService.loadArena(mapId)
	local startedAt = now()
	local r: Round = {
		ModeId = modeId,
		MapId = mapId,
		StartedAt = startedAt,
		EndsAt = startedAt + Config.Round.RoundTime,
		StartedWith = #participants,
		Board = Scoreboard.new(modeId),
		NextPassiveGainAt = startedAt + (Config.Modes.List[modeId].PassiveGainInterval or math.huge),
	}
	round = r
	Workspace:SetAttribute("RoundMode", modeId)
	Workspace:SetAttribute("RoundMap", mapId)
	setState("Playing", r.EndsAt)
	log(`{modeId} on {mapId} with {#participants} player(s)`)

	for _, player in Players:GetPlayers() do
		if not table.find(participants, player) then
			setStatus(player, "Spectating")
		end
	end
	local spawns = shuffled(MapService.getArenaMarkers("SpawnPoint"))
	for index, player in participants do
		Scoreboard.add(r.Board, player.UserId, player.Name, startedAt)
		local data = DataService.get(player)
		Analytics.roundModePicked(player, modeId, mapId)
		Analytics.styleUsed(player, if data then data.Styles.Equipped else Config.Styles.Default, modeId)
		task.spawn(enterArena, player, if #spawns > 0 then spawns[(index - 1) % #spawns + 1] else nil)
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
			local waiting = status ~= "Playing" and status ~= "Respawning" and (entry == nil or Scoreboard.isIn(entry))
			if not waiting or isAFK(player) or not isReady(player) then
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
		DataService.incrementStat(player, "RoundsPlayed")
		DataService.incrementStat(player, "RoundsCompleted")
		if standing.Placement == 1 and eligible then
			DataService.incrementStat(player, "Wins")
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
		while #readyPlayers() < minPlayers() do
			task.wait(1)
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

function RoundService.getStatus(player: Player): Status
	return statuses[player] or "Lobby"
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
	loop()
end

return RoundService
