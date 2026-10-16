--!strict
--[[
	CombatService — Punch chain, charged Shove, server hitboxes, HP / Percent, knockback, hitstun and KO credit.

	Clients only send intents (Punch; Shove Start / Release / Cancel). Each one is checked against the attacker's
	Fighter (Server/Combat/Fighter: cooldowns, chain, hitstun). After the attack's windup the server looks for
	victims in the attack's box in front of the attacker (padded for latency) and applies the hits. Knockback is
	run by whoever simulates the victim: its own client for players (Net "Knockback"), this server for training
	dummies. PvP only counts inside the arena; training dummies can always be hit.

	Dash: the client moves its own character and sends Dash; the server checks cooldown and hitstun and starts the
	invulnerability (Dash.InvulnerabilityTime). A hit landing inside it misses; if the dash began within
	PerfectDodge.Window before the hit, it is a Perfect Dodge (PerfectDodged signal; the dodger's next hit within
	BonusWindow gets BonusKnockbackMultiplier). The Perfect Dodge Scrap is paid with the round rewards.

	Every combatant has a Fighter and the character attributes HP (modes with HP) and Percent, which UI reads.
	Round rules (lives, respawns, scoring) live elsewhere: the round system replaces the knock-out handler and the
	MapService fall handler (step 1.8). Until then a knocked-out player returns to the lobby with full HP and 0%.
]]
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))
local Launch = require(Shared:WaitForChild("Combat"):WaitForChild("Launch"))

local Server = script.Parent.Parent
local Fighter = require(Server:WaitForChild("Combat"):WaitForChild("Fighter"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MapService = require(script.Parent:WaitForChild("MapService"))

export type KOCause = "Health" | "Fall"

type Fighter = Fighter.Fighter

-- One attack on its way to the hit check.
type Swing = {
	Name: Formulas.AttackName,
	Label: string, -- for the Studio log, e.g. "Punch 3" or "Shove 0.80 s"
	Attack: Formulas.ResolvedAttack,
	Multiplier: number, -- finisher / charge knockback multiplier
	Heavy: boolean, -- shakes the camera
}

local DUMMY_TAG = "TrainingDummy"
local HITBOX_FLASH_TIME = 0.25
local HITBOX_HIT_COLOR = Color3.fromHex("#FF3B30")
local HITBOX_MISS_COLOR = Color3.fromHex("#B0B0B0")

local CombatService = {
	Priority = -20,
	-- (victim character, credited Player or nil, cause) whenever a combatant is knocked out (dummies included).
	KnockedOut = Signal.new() :: Signal.Signal<Model, Player?, KOCause>,
	-- (dodger character, attacker) when a dash started in the last moment before a hit (+Scrap at round end, and the
	-- dodger's next hit gets bonus knockback).
	PerfectDodged = Signal.new() :: Signal.Signal<Model, Player>,
}

local fighters: { [Model]: Fighter } = {}
local knockedOut: { [Model]: boolean } = {}
local modeId: string = Config.Modes.Default

local function isStudioFlag(flag: boolean): boolean
	return flag and RunService:IsStudio()
end

local function rootOf(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isAlive(character: Model): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function syncAttributes(character: Model, fighter: Fighter)
	local hasHealth = Config.Modes.List[fighter.ModeId].MaxHealth ~= nil
	character:SetAttribute("HP", if hasHealth then fighter.Health else nil)
	character:SetAttribute("Percent", fighter.Percent)
end

-- Walk speed: slowed while a Shove is charging.
local function setCharging(character: Model, charging: boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and Players:GetPlayerFromCharacter(character) then
		local slow = if charging then Config.Combat.Attacks.Shove.ChargeSlow else 0
		humanoid.WalkSpeed = Config.World.WalkSpeed * (1 - slow)
	end
end

-- Default knock-out handler (the round system replaces it): players go back to the lobby with a fresh fighter.
local knockOutHandler: (character: Model, killer: Player?, cause: KOCause) -> () = function(
	character: Model,
	_killer: Player?,
	_cause: KOCause
)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		CombatService.resetFighter(character)
		MapService.sendToLobby(player)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Combatants
---------------------------------------------------------------------------------------------------------------------

-- Makes a character (player or training dummy) a combatant with full HP and 0%.
function CombatService.register(character: Model)
	local fighter = Fighter.new(modeId)
	fighters[character] = fighter
	knockedOut[character] = nil
	syncAttributes(character, fighter)
	setCharging(character, false)
end

function CombatService.unregister(character: Model)
	fighters[character] = nil
	knockedOut[character] = nil
end

-- Starts a new life for a combatant: full HP, 0%, no cooldowns.
function CombatService.resetFighter(character: Model)
	if fighters[character] then
		CombatService.register(character)
	end
end

function CombatService.getFighter(character: Model): Fighter?
	return fighters[character]
end

function CombatService.getMode(): string
	return modeId
end

-- Switches the rules (e.g. at round start) and gives every combatant a fresh fighter for that mode.
function CombatService.setMode(newModeId: string)
	assert(Config.Modes.List[newModeId], `Unknown mode "{newModeId}"`)
	modeId = newModeId
	for character in fighters do
		CombatService.register(character)
	end
end

-- Replaces what happens to a knocked-out player (the round system: lives, respawn delay, spectate).
function CombatService.setKnockOutHandler(handler: (character: Model, killer: Player?, cause: KOCause) -> ())
	knockOutHandler = handler
end

-- Knocks a combatant out (HP reached 0, or it fell). The last attacker within KOCreditWindow gets the credit.
function CombatService.knockOut(character: Model, cause: KOCause)
	local fighter = fighters[character]
	if fighter == nil or knockedOut[character] then
		return
	end
	knockedOut[character] = true
	fighter.Defeated = true
	local killer = Fighter.koCredit(fighter, os.clock()) :: Player?
	if killer and (killer.Parent ~= Players or killer.Character == character) then
		killer = nil
	end
	if isStudioFlag(Config.Dev.LogCombat) then
		print(`[Combat] KO: {character.Name} ({cause}), credit: {if killer then killer.Name else "none"}`)
	end
	CombatService.KnockedOut:Fire(character, killer, cause)
	if not character:HasTag(DUMMY_TAG) then
		knockOutHandler(character, killer, cause)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Hits
---------------------------------------------------------------------------------------------------------------------

-- PvP only counts inside the arena; training dummies can always be hit.
local function canBeHit(victim: Model, attackerInArena: boolean): boolean
	if not isAlive(victim) or knockedOut[victim] then
		return false
	end
	if victim:HasTag(DUMMY_TAG) then
		return true
	end
	local root = rootOf(victim)
	return attackerInArena and root ~= nil and MapService.getZone(root.Position) == "Arena"
end

-- The combatant a part belongs to (walks up past accessories and welded models).
local function combatantOf(part: Instance): Model?
	local node = part.Parent
	while node and node ~= Workspace do
		if node:IsA("Model") and fighters[node] then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function findVictims(attacker: Model, attackerRoot: BasePart, box: CFrame, size: Vector3): { Model }
	local attackerInArena = MapService.getZone(attackerRoot.Position) == "Arena"
	local candidates: { Instance } = {}
	for character in fighters do
		if character ~= attacker and canBeHit(character, attackerInArena) then
			table.insert(candidates, character)
		end
	end
	local victims: { Model } = {}
	if #candidates == 0 then
		return victims
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = candidates
	for _, part in Workspace:GetPartBoundsInBox(box, size, params) do
		local victim = combatantOf(part)
		if victim and not table.find(victims, victim) then
			table.insert(victims, victim)
		end
	end
	return victims
end

-- Studio only: flashes the hitbox (red = hit something, grey = missed).
local function showHitbox(box: CFrame, size: Vector3, hit: boolean)
	if not isStudioFlag(Config.Dev.ShowHitboxes) then
		return
	end
	local part = Instance.new("Part")
	part.Name = "DebugHitbox"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = if hit then HITBOX_HIT_COLOR else HITBOX_MISS_COLOR
	part.Transparency = 0.6
	part.Size = size
	part.CFrame = box
	part.Parent = Workspace
	Debris:AddItem(part, HITBOX_FLASH_TIME)
end

-- A hit met a dashing victim: no damage or knockback. A Perfect Dodge is announced.
local function dodged(attacker: Player, victim: Model, swing: Swing, evade: Fighter.Evade)
	if evade == "Perfect" then
		CombatService.PerfectDodged:Fire(victim, attacker)
	end
	if isStudioFlag(Config.Dev.LogCombat) then
		local kind = if evade == "Perfect" then "PERFECT DODGE" else "dodged"
		print(`[Combat] {victim.Name} {kind}: {attacker.Name} {swing.Label}`)
	end
end

-- Applies one swing to one victim. `bonus` is the attacker's Perfect Dodge knockback bonus (1 when none).
-- Returns false when the victim dodged it.
local function applyHit(
	attacker: Player,
	attackerCharacter: Model,
	attackerRoot: BasePart,
	victim: Model,
	swing: Swing,
	bonus: number
): boolean
	local fighter = fighters[victim]
	local victimRoot = rootOf(victim)
	if fighter == nil or victimRoot == nil then
		return false
	end
	local now = os.clock()
	local evade: Fighter.Evade = Fighter.evade(fighter, now)
	if evade == "Perfect" or evade == "Dodged" then
		dodged(attacker, victim, swing, evade)
		return false
	end
	local attack = swing.Attack
	local result = Fighter.takeHit(fighter, {
		Damage = attack.Damage,
		Percent = attack.Percent,
		KnockbackScale = attack.KnockbackScale,
		Multiplier = swing.Multiplier * bonus,
	}, attacker, now)
	if result.InterruptedCharge then
		setCharging(victim, false)
	end
	syncAttributes(victim, fighter)

	local away = victimRoot.Position - attackerRoot.Position
	local look = attackerRoot.CFrame.LookVector
	local vx, vy, vz = Formulas.launchVelocity(away.X, away.Z, Formulas.launchSpeed(result.Force), look.X, look.Z)
	local velocity = Vector3.new(vx, vy, vz)
	local victimPlayer = Players:GetPlayerFromCharacter(victim)
	if victimPlayer then
		Net.fireClient("Knockback", victimPlayer, velocity, result.Hitstun)
	else
		Launch.apply(victim, velocity, result.Hitstun)
	end
	Net.fireAll("CombatHit", attackerCharacter, victim, swing.Name, swing.Heavy, result.Trail)

	if isStudioFlag(Config.Dev.LogCombat) then
		local hp = if victim:GetAttribute("HP") ~= nil then ` HP {fighter.Health},` else ""
		print(
			`[Combat] {attacker.Name} {swing.Label} -> {victim.Name}:{hp} {string.format("%.0f", fighter.Percent)}%,`
				.. ` knockback {string.format("%.1f", result.Force)}, hitstun {string.format("%.2f", result.Hitstun)} s`
				.. (if result.Trail then ", trail" else "")
				.. (if bonus > 1 then ", Perfect Dodge bonus" else "")
		)
	end
	if result.Defeated then
		CombatService.knockOut(victim, "Health")
	end
	return true
end

-- Runs when an attack's windup ends. The swing is lost if the attacker was hit, knocked out or respawned meanwhile.
local function strike(attacker: Player, character: Model, fighter: Fighter, startedAt: number, swing: Swing)
	if fighters[character] ~= fighter or fighter.Defeated or Fighter.wasHitSince(fighter, startedAt) then
		return
	end
	local root = rootOf(character)
	if root == nil then
		return
	end
	local padded = Formulas.paddedHitbox(swing.Attack.Hitbox)
	local size = Vector3.new(padded.X, padded.Y, padded.Z)
	local box = root.CFrame * CFrame.new(0, 0, -swing.Attack.Hitbox.Z / 2)
	local victims = findVictims(character, root, box, size)
	showHitbox(box, size, #victims > 0)
	local bonus = Fighter.dodgeBonus(fighter, os.clock())
	local landed = false
	for _, victim in victims do
		if applyHit(attacker, character, root, victim, swing, bonus) then
			landed = true
		end
	end
	if landed and bonus > 1 then
		Fighter.clearDodgeBonus(fighter)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Intents
---------------------------------------------------------------------------------------------------------------------

local function styleOf(player: Player): string
	local data = DataService.get(player)
	local style = data and data.Styles.Equipped
	return if style and Config.Styles.List[style] then style else Config.Styles.Default
end

local function fighterOf(player: Player): (Model?, Fighter?)
	local character = player.Character
	if character == nil or not isAlive(character) then
		return nil, nil
	end
	return character, fighters[character]
end

local function onPunch(player: Player)
	local character, fighter = fighterOf(player)
	if character == nil or fighter == nil then
		return
	end
	local styleId = styleOf(player)
	local now = os.clock()
	local hitIndex = Fighter.punch(fighter, Config.Styles.List[styleId].AttackSpeed, now)
	if hitIndex == nil then
		return
	end
	local attack = Formulas.resolveAttack(styleId, "Punch")
	task.delay(
		attack.Windup,
		strike,
		player,
		character,
		fighter,
		now,
		{
			Name = "Punch",
			Label = `Punch {hitIndex}`,
			Attack = attack,
			Multiplier = Formulas.punchChainMultiplier(hitIndex),
			Heavy = hitIndex >= Config.Combat.Attacks.Punch.ChainLength,
		} :: Swing
	)
end

local function onShove(player: Player, phase: string)
	local character, fighter = fighterOf(player)
	if character == nil or fighter == nil then
		return
	end
	local now = os.clock()
	if phase == "Start" then
		if Fighter.startShove(fighter, now) then
			setCharging(character, true)
		end
	elseif phase == "Cancel" then
		if Fighter.cancelShove(fighter) then
			setCharging(character, false)
		end
	else
		local attack = Formulas.resolveAttack(styleOf(player), "Shove")
		local charge = Fighter.releaseShove(fighter, attack.Cooldown, now)
		if charge == nil then
			return
		end
		setCharging(character, false)
		task.delay(
			attack.Windup,
			strike,
			player,
			character,
			fighter,
			now,
			{
				Name = "Shove",
				Label = `Shove {string.format("%.2f", charge)} s`,
				Attack = attack,
				Multiplier = Formulas.shoveChargeMultiplier(charge),
				Heavy = true,
			} :: Swing
		)
	end
end

-- The client already moved its character; the server only grants the invulnerability (cooldown + hitstun checked).
local function onDash(player: Player)
	local character, fighter = fighterOf(player)
	if character == nil or fighter == nil then
		return
	end
	local wasCharging = fighter.ChargeStartedAt ~= nil
	if not Fighter.dash(fighter, os.clock()) then
		return
	end
	if wasCharging then
		setCharging(character, false)
	end
	if isStudioFlag(Config.Dev.LogCombat) then
		print(`[Combat] {player.Name} dashed`)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------------------------------------------------

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(CombatService.register)
	player.CharacterRemoving:Connect(CombatService.unregister)
	if player.Character then
		CombatService.register(player.Character)
	end
end

function CombatService.Init(_self: any)
	Net.onServerEvent("Punch", onPunch)
	Net.onServerEvent("Shove", onShove)
	Net.onServerEvent("Dash", onDash)

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	-- Falling out of the arena is a KO (credit to the last attacker); falling out of the lobby just respawns there.
	-- The round system replaces this handler and calls CombatService.knockOut itself.
	MapService.setFallHandler(function(player: Player, zone: MapService.FallZone)
		local character = player.Character
		if zone == "Arena" and character and fighters[character] then
			CombatService.knockOut(character, "Fall")
		else
			MapService.sendToLobby(player)
		end
	end)
end

return CombatService
