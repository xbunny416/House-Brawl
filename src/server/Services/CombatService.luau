--!strict
--[[
	CombatService — Punch chain, charged punch, the Ability move (parry), server hitboxes, HP / Percent, knockback,
	hitstun and KO credit.

	Clients only send intents (Punch; Charge Start / Release / Cancel while the attack is held; Ability). Each one is
	checked against the attacker's Fighter (Server/Combat/Fighter: cooldowns, chain, hitstun). After the attack's
	windup the server looks for victims in the attack's box in front of the attacker (padded for latency) and
	applies the hits. The Ability move is the equipped style's (Wrecker: parry); styles without one ignore it.
	Knockback is
	run by whoever simulates the victim: its own client for players (Net "Knockback"), this server for training
	dummies. PvP only counts inside the arena; training dummies can always be hit.

	Dash: the client moves its own character and sends Dash; the server checks cooldown, hitstun and stamina
	(Stamina.DashCost), spends it and starts the invulnerability (Dash.InvulnerabilityTime). A hit landing inside it
	misses; if the dash began within PerfectDodge.Window before the hit, it is a Perfect Dodge (PerfectDodged signal;
	the dodger's next hit within BonusWindow gets BonusKnockbackMultiplier). The Perfect Dodge Scrap is paid with the
	round rewards.

	Run: the client sends Run held / let go; every STAMINA_TICK the server advances each player's stamina (running
	drains it while moving, it refills after a pause) and switches the "Run" walk-speed modifier.

	Every combatant has a Fighter and the character attributes HP (modes with HP), Percent and Stamina, which UI reads.
	Round rules (lives, respawns, scoring) live in RoundService, which replaces the knock-out handler and the
	MapService fall handler. The defaults here (KO = back to the lobby with full HP and 0%) only run without it.
	The spawn shield (CombatService.shield) blocks hits until it runs out or the fighter attacks.

	Other systems hook in without CombatService knowing them: thrown props and explosions land through hitWith /
	explode, Swung lets props and structures react to attack boxes, Hit reports every landed blow, the interceptor
	can take over an attack intent (holding a prop turns Punch into Throw), and walk-speed modifiers stack.
]]
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
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
local Animate = require(Server:WaitForChild("Visuals"):WaitForChild("Animate"))
local Effects = require(Server:WaitForChild("Visuals"):WaitForChild("Effects"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MapService = require(script.Parent:WaitForChild("MapService"))

export type KOCause = "Health" | "Fall"

-- One blow on its way to a victim: a swing, a thrown prop or an explosion.
export type Blow = {
	Attacker: Player, -- gets the KO credit
	AttackerCharacter: Model?, -- for hit feedback
	Damage: number, -- Classic HP
	Percent: number, -- Casual Percent
	KnockbackScale: number,
	Multiplier: number, -- extra knockback (finisher, charge, ...)
	Source: string, -- "Punch", "Charged", "Parry" or a prop type
	Label: string, -- Studio log, e.g. "Punch 3"
	Heavy: boolean, -- shakes the camera
	Fallback: Vector3, -- launch direction when the victim is right on top of the blow's origin
}

type KnockOutHandler = (character: Model, killer: Player?, cause: KOCause, weapon: string?) -> ()

-- Takes over an attack intent (returns true when it did). `facing` / `position`: the attacker's facing and position
-- on their own screen, sent with Punch (unchecked; a user must sanity-check them).
export type Interceptor = (player: Player, attack: Formulas.AttackName, facing: Vector3?, position: Vector3?) -> boolean

type Fighter = Fighter.Fighter

-- One attack on its way to the hit check.
type Swing = {
	Name: Formulas.AttackName,
	Label: string,
	Attack: Formulas.ResolvedAttack,
	Multiplier: number, -- finisher / charge knockback multiplier
	Heavy: boolean,
}

local DUMMY_TAG = "TrainingDummy"
local FIGHTER_GROUP = "Fighters"
local SHIELD_NAME = "SpawnShield"
local CHARGE_SPEED_KEY = "Charge"
local RUN_SPEED_KEY = "Run"
local STAMINA_TICK = 0.1 -- seconds between stamina updates
local HITBOX_FLASH_TIME = 0.25
local HITBOX_HIT_COLOR = Color3.fromHex("#FF3B30")
local HITBOX_MISS_COLOR = Color3.fromHex("#B0B0B0")

local CombatService = {
	Priority = -20,
	-- (victim character, credited Player or nil, cause, weapon of the credited hit) whenever a combatant is knocked
	-- out (dummies included).
	KnockedOut = Signal.new() :: Signal.Signal<Model, Player?, KOCause, string?>,
	-- (dodger character, attacker) when a dash started in the last moment before a hit (+Scrap at round end, and the
	-- dodger's next hit gets bonus knockback).
	PerfectDodged = Signal.new() :: Signal.Signal<Model, Player>,
	-- (victim character, attacker) after every blow that landed.
	Hit = Signal.new() :: Signal.Signal<Model, Player>,
	-- (attacker, box CFrame, box size, Classic damage) for every Punch / Charged hit check, hit or miss.
	Swung = Signal.new() :: Signal.Signal<Player, CFrame, Vector3, number>,
	-- (player, character) when a dash is accepted (its invulnerability started): dash trails, VFX.
	Dashed = Signal.new() :: Signal.Signal<Player, Model>,
}

local fighters: { [Model]: Fighter } = {}
local knockedOut: { [Model]: boolean } = {}
local speedModifiers: { [Model]: { [string]: number } } = {}
local modeId: string = Config.Modes.Default
local interceptor: Interceptor? = nil

local function isStudioFlag(flag: boolean): boolean
	return flag and RunService:IsStudio()
end

local function rootOf(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- The player's equipped fighting style (the default until their data loads).
local function styleOf(player: Player): string
	local data = DataService.get(player)
	local style = data and data.Styles.Equipped
	return if style and Config.Styles.List[style] then style else Config.Styles.Default
end

local function isAlive(character: Model): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function syncAttributes(character: Model, fighter: Fighter)
	local hasHealth = Config.Modes.List[fighter.ModeId].MaxHealth ~= nil
	character:SetAttribute("HP", if hasHealth then fighter.Health else nil)
	character:SetAttribute("Percent", fighter.Percent)
	character:SetAttribute("Stamina", math.floor(fighter.Stamina + 0.5))
end

local function applySpeed(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or Players:GetPlayerFromCharacter(character) == nil then
		return
	end
	local multiplier = 1
	local modifiers = speedModifiers[character]
	if modifiers then
		for _, factor in modifiers do
			multiplier *= factor
		end
	end
	humanoid.WalkSpeed = Config.World.WalkSpeed * multiplier
end

-- Sets (or with nil, removes) one named walk-speed multiplier on a player character, e.g. "Carry" = 0.85.
-- All modifiers multiply together.
function CombatService.setSpeedModifier(character: Model, key: string, multiplier: number?)
	local modifiers = speedModifiers[character]
	if modifiers == nil then
		modifiers = {}
		speedModifiers[character] = modifiers
	end
	if multiplier then
		modifiers[key] = multiplier
	else
		modifiers[key] = nil
	end
	applySpeed(character)
end

-- Walk speed: slowed while a punch is charging. The Charging attribute shows the charge pose on every client.
local function setCharging(character: Model, charging: boolean)
	local slow = Config.Combat.Attacks.Charged.ChargeSlow
	CombatService.setSpeedModifier(character, CHARGE_SPEED_KEY, if charging then 1 - slow else nil)
	character:SetAttribute("Charging", if charging then true else nil)
end

-- Default knock-out handler (the round system replaces it): players go back to the lobby with a fresh fighter.
local knockOutHandler: KnockOutHandler = function(character: Model, _killer: Player?, _cause: KOCause, _weapon: string?)
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
	local previous = fighters[character]
	local fighter = Fighter.new(modeId)
	-- A reset (e.g. entering the arena) keeps Run held: the player may still be holding the key.
	Fighter.setRunHeld(fighter, previous ~= nil and previous.RunHeld)
	fighters[character] = fighter
	knockedOut[character] = nil
	syncAttributes(character, fighter)
	setCharging(character, false)
	CombatService.setSpeedModifier(character, RUN_SPEED_KEY, nil) -- the new fighter starts walking
	if character:GetAttribute("FighterCollisions") == nil then
		character:SetAttribute("FighterCollisions", true)
		-- Fighters pass through each other: no body-pushing someone off a ledge by walking into them, and dashes
		-- go through players. Hits use overlap queries, which collision groups do not affect.
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = FIGHTER_GROUP
			end
		end
		character.DescendantAdded:Connect(function(part: Instance)
			if part:IsA("BasePart") then
				part.CollisionGroup = FIGHTER_GROUP
			end
		end)
	end
end

function CombatService.unregister(character: Model)
	fighters[character] = nil
	knockedOut[character] = nil
	speedModifiers[character] = nil
end

-- Starts a new life for a combatant: full HP, 0%, no cooldowns.
function CombatService.resetFighter(character: Model)
	if fighters[character] then
		CombatService.register(character)
	end
end

-- Every registered combatant character (players and dummies).
function CombatService.combatants(): { Model }
	local list: { Model } = {}
	for character in fighters do
		table.insert(list, character)
	end
	return list
end

local function removeShieldVisual(character: Model)
	local visual = character:FindFirstChild(SHIELD_NAME)
	if visual then
		visual:Destroy()
	end
end

-- Spawn shield: hits do nothing for `seconds` (ends early when the fighter attacks). Shown as a ForceField.
function CombatService.shield(character: Model, seconds: number)
	local fighter = fighters[character]
	if fighter == nil then
		return
	end
	Fighter.shield(fighter, os.clock(), seconds)
	removeShieldVisual(character)
	local visual = Instance.new("ForceField")
	visual.Name = SHIELD_NAME
	visual.Parent = character
	task.delay(seconds, function()
		if visual.Parent and not Fighter.isShielded(fighter, os.clock()) then
			visual:Destroy()
		end
	end)
end

-- Ends a spawn shield early (the fighter attacked in a way CombatService does not see, e.g. a throw).
function CombatService.breakShield(character: Model)
	local fighter = fighters[character]
	if fighter then
		Fighter.breakShield(fighter)
		removeShieldVisual(character)
	end
end

-- Adds Percent outside of hits (Casual passive gain).
function CombatService.addPercent(character: Model, amount: number)
	local fighter = fighters[character]
	if fighter and not knockedOut[character] then
		Fighter.addPercent(fighter, amount)
		syncAttributes(character, fighter)
	end
end

-- Developer panel: sets a combatant's Percent (in modes with HP, the HP that gives it).
function CombatService.setPercent(character: Model, percent: number)
	local fighter = fighters[character]
	if fighter and not knockedOut[character] then
		Fighter.setPercent(fighter, percent)
		syncAttributes(character, fighter)
	end
end

-- Developer panel: sets a combatant's HP (modes with HP only; never below 1).
function CombatService.setHealth(character: Model, health: number)
	local fighter = fighters[character]
	if fighter and not knockedOut[character] then
		Fighter.setHealth(fighter, health)
		syncAttributes(character, fighter)
	end
end

function CombatService.getFighter(character: Model): Fighter?
	return fighters[character]
end

-- True while the character can attack (registered, alive, not knocked out or in hitstun).
function CombatService.canAct(character: Model): boolean
	local fighter = fighters[character]
	return fighter ~= nil and isAlive(character) and not knockedOut[character] and Fighter.canAct(fighter, os.clock())
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
function CombatService.setKnockOutHandler(handler: KnockOutHandler)
	knockOutHandler = handler
end

-- Lets another system take over an attack intent before CombatService handles it. The interceptor returns true
-- when it took the intent (e.g. a player holding a prop: Punch throws it, a charge is blocked).
function CombatService.setInterceptor(handler: Interceptor)
	interceptor = handler
end

-- Knocks a combatant out (HP reached 0, or it fell). The last attacker within KOCreditWindow gets the credit.
function CombatService.knockOut(character: Model, cause: KOCause)
	local fighter = fighters[character]
	if fighter == nil or knockedOut[character] then
		return
	end
	knockedOut[character] = true
	fighter.Defeated = true
	local credited, weapon = Fighter.koCredit(fighter, os.clock())
	local killer = credited :: Player?
	if killer and (killer.Parent ~= Players or killer.Character == character) then
		killer, weapon = nil, nil
	end
	if isStudioFlag(Config.Dev.LogCombat) then
		local credit = if killer then `{killer.Name} ({weapon})` else "none"
		print(`[Combat] KO: {character.Name} ({cause}), credit: {credit}`)
	end
	-- The POW starburst: at the victim, or around the scorer for a ring-out (the victim is out in the void).
	local killerCharacter = killer and killer.Character
	local victimRoot = rootOf(character)
	local killerRoot = if killerCharacter then rootOf(killerCharacter) else nil
	local where = if cause == "Fall" and killerRoot then killerRoot else victimRoot
	if where then
		Effects.play("KO", where.Position, { Victim = character, Killer = killerCharacter, Cause = cause })
	end
	CombatService.KnockedOut:Fire(character, killer, cause, weapon)
	if not character:HasTag(DUMMY_TAG) then
		knockOutHandler(character, killer, cause, weapon)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Hits
---------------------------------------------------------------------------------------------------------------------

-- PvP only counts inside the arena; training dummies can always be hit.
local function canBeHit(victim: Model, attackerInArena: boolean): boolean
	if fighters[victim] == nil or not isAlive(victim) or knockedOut[victim] then
		return false
	end
	if victim:HasTag(DUMMY_TAG) then
		return true
	end
	local root = rootOf(victim)
	return attackerInArena and root ~= nil and MapService.getZone(root.Position) == "Arena"
end

-- True if an attack coming from `from` could hit `victim` (alive, not knocked out, PvP rules for that zone).
function CombatService.isTarget(victim: Model, from: Vector3): boolean
	return canBeHit(victim, MapService.getZone(from) == "Arena")
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

-- A blow met a dashing or shielded victim: no damage or knockback. A Perfect Dodge is announced.
local function dodged(victim: Model, blow: Blow, evade: Fighter.Evade)
	if evade == "Perfect" then
		CombatService.PerfectDodged:Fire(victim, blow.Attacker)
		local root = rootOf(victim)
		if root then
			Effects.play("PerfectDodge", root.Position, { Character = victim })
		end
	end
	if isStudioFlag(Config.Dev.LogCombat) then
		local kind = if evade == "Perfect"
			then "PERFECT DODGE"
			elseif evade == "Shielded" then "shielded"
			elseif evade == "Parried" then "PARRIED"
			else "dodged"
		print(`[Combat] {victim.Name} {kind}: {blow.Attacker.Name} {blow.Label}`)
	end
end

local land: (victim: Model, blow: Blow, away: Vector3) -> boolean

-- A parried melee blow comes back: its attacker takes the knockback (not the damage), credited to the parrier and
-- scaled by the parrier's style's ReflectMultiplier.
local function reflect(parrier: Model, blow: Blow)
	local parrierPlayer = Players:GetPlayerFromCharacter(parrier)
	local attackerCharacter = blow.AttackerCharacter
	local parrierRoot = rootOf(parrier)
	local attackerRoot = if attackerCharacter then rootOf(attackerCharacter) else nil
	if parrierPlayer == nil or attackerCharacter == nil or parrierRoot == nil or attackerRoot == nil then
		return
	end
	local ability = Config.Styles.List[styleOf(parrierPlayer)].Ability
	local parry = ability and ability.Parry
	land(attackerCharacter, {
		Attacker = parrierPlayer,
		AttackerCharacter = parrier,
		Damage = 0,
		Percent = 0,
		KnockbackScale = blow.KnockbackScale,
		Multiplier = blow.Multiplier * (if parry then parry.ReflectMultiplier else 1),
		Source = "Parry", -- not "Punch" / "Charged", so a reflected blow can't be parried back
		Label = "Parry",
		Heavy = true,
		Fallback = parrierRoot.CFrame.LookVector,
	}, attackerRoot.Position - parrierRoot.Position)
end

-- Applies one blow to one victim, launching it along `away` (flat; blow.Fallback when ~zero).
-- Returns false when the victim dodged, was shielded or parried it.
function land(victim: Model, blow: Blow, away: Vector3): boolean
	local fighter = fighters[victim]
	if fighter == nil or rootOf(victim) == nil then
		return false
	end
	local now = os.clock()
	local melee = blow.Source == "Punch" or blow.Source == "Charged"
	local evade: Fighter.Evade = Fighter.evade(fighter, now, melee)
	if evade == "Parried" then
		dodged(victim, blow, evade)
		reflect(victim, blow)
		return false
	elseif evade == "Perfect" or evade == "Dodged" or evade == "Shielded" then
		dodged(victim, blow, evade)
		return false
	end
	local result = Fighter.takeHit(fighter, {
		Damage = blow.Damage,
		Percent = blow.Percent,
		KnockbackScale = blow.KnockbackScale,
		Multiplier = blow.Multiplier,
		Source = blow.Source,
	}, blow.Attacker, now)
	if result.InterruptedCharge then
		setCharging(victim, false)
	end
	syncAttributes(victim, fighter)

	local speed = Formulas.launchSpeed(result.Force)
	local vx, vy, vz = Formulas.launchVelocity(away.X, away.Z, speed, blow.Fallback.X, blow.Fallback.Z)
	local velocity = Vector3.new(vx, vy, vz)
	local victimPlayer = Players:GetPlayerFromCharacter(victim)
	if victimPlayer then
		Net.fireClient("Knockback", victimPlayer, velocity, result.Hitstun)
	else
		Launch.apply(victim, velocity, result.Hitstun)
	end
	Net.fireAll("CombatHit", blow.AttackerCharacter, victim, blow.Source, blow.Heavy, result.Trail, result.Hitstun)
	CombatService.Hit:Fire(victim, blow.Attacker)

	if isStudioFlag(Config.Dev.LogCombat) then
		local hp = if victim:GetAttribute("HP") ~= nil then ` HP {fighter.Health},` else ""
		print(
			`[Combat] {blow.Attacker.Name} {blow.Label} -> {victim.Name}:{hp} {string.format("%.0f", fighter.Percent)}%,`
				.. ` knockback {string.format("%.1f", result.Force)}, hitstun {string.format("%.2f", result.Hitstun)} s`
				.. (if result.Trail then ", trail" else "")
				.. (if blow.Multiplier > 1 then ` (x{string.format("%.2f", blow.Multiplier)})` else "")
		)
	end
	if result.Defeated then
		CombatService.knockOut(victim, "Health")
	end
	return true
end

-- The attacker's Perfect Dodge knockback bonus (1 when none), and a function that uses it up.
local function dodgeBonus(attacker: Player): (number, () -> ())
	local character = attacker.Character
	local fighter = character and fighters[character]
	if fighter == nil then
		return 1, function() end
	end
	return Fighter.dodgeBonus(fighter, os.clock()), function()
		Fighter.clearDodgeBonus(fighter)
	end
end

-- A thrown prop (or another projectile) at `at`, flying along `direction`, hits `victim`. PvP rules use the zone of
-- `at`. Returns true if the blow landed.
function CombatService.hitWith(victim: Model, blow: Blow, at: Vector3, direction: Vector3): boolean
	if not canBeHit(victim, MapService.getZone(at) == "Arena") then
		return false
	end
	local bonus, useBonus = dodgeBonus(blow.Attacker)
	local boosted = table.clone(blow)
	boosted.Multiplier *= bonus
	local landed = land(victim, boosted, Vector3.new(direction.X, 0, direction.Z))
	if landed and bonus > 1 then
		useBonus()
	end
	return landed
end

-- An explosion at `center`: every combatant within `radius` studs (the attacker too) takes the blow and is knocked
-- away from the center. Returns the characters that were hit.
function CombatService.explode(center: Vector3, radius: number, blow: Blow): { Model }
	local inArena = MapService.getZone(center) == "Arena"
	local hit: { Model } = {}
	for _, character in CombatService.combatants() do
		local root = rootOf(character)
		if root and (root.Position - center).Magnitude <= radius and canBeHit(character, inArena) then
			if land(character, blow, root.Position - center) then
				table.insert(hit, character)
			end
		end
	end
	return hit
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
	CombatService.Swung:Fire(attacker, box, size, swing.Attack.Damage)

	local bonus, useBonus = dodgeBonus(attacker)
	local blow: Blow = {
		Attacker = attacker,
		AttackerCharacter = character,
		Damage = swing.Attack.Damage,
		Percent = swing.Attack.Percent,
		KnockbackScale = swing.Attack.KnockbackScale,
		Multiplier = swing.Multiplier * bonus,
		Source = swing.Name,
		Label = swing.Label,
		Heavy = swing.Heavy,
		Fallback = root.CFrame.LookVector,
	}
	local landed = false
	for _, victim in victims do
		local victimRoot = rootOf(victim)
		if victimRoot and land(victim, blow, victimRoot.Position - root.Position) then
			landed = true
		end
	end
	if landed and bonus > 1 then
		useBonus()
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Intents
---------------------------------------------------------------------------------------------------------------------

local function fighterOf(player: Player): (Model?, Fighter?)
	local character = player.Character
	if character == nil or not isAlive(character) then
		return nil, nil
	end
	return character, fighters[character]
end

local function intercepted(player: Player, attack: Formulas.AttackName, facing: Vector3?, position: Vector3?): boolean
	local handler = interceptor
	return handler ~= nil and handler(player, attack, facing, position)
end

local function onPunch(player: Player, facing: Vector3?, position: Vector3?)
	local character, fighter = fighterOf(player)
	if character == nil or fighter == nil or intercepted(player, "Punch", facing, position) then
		return
	end
	local styleId = styleOf(player)
	local now = os.clock()
	local hitIndex = Fighter.punch(fighter, Config.Styles.List[styleId].AttackSpeed, now)
	if hitIndex == nil then
		return
	end
	removeShieldVisual(character) -- attacking ended the spawn shield
	local clips = Config.Styles.List[styleId].Animations.Punch
	Animate.play(character, clips[(hitIndex - 1) % #clips + 1])
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

-- The attack held past Charged.HoldTime: "Start" charges, "Release" throws the charged punch, "Cancel" stops.
local function onCharge(player: Player, phase: string)
	local character, fighter = fighterOf(player)
	if character == nil or fighter == nil then
		return
	end
	local now = os.clock()
	if phase == "Start" then
		if not intercepted(player, "Charged") and Fighter.startCharge(fighter, now) then
			setCharging(character, true)
			removeShieldVisual(character) -- attacking ended the spawn shield
		end
	elseif phase == "Cancel" then
		if Fighter.cancelCharge(fighter) then
			setCharging(character, false)
		end
	else
		local styleId = styleOf(player)
		local attack = Formulas.resolveAttack(styleId, "Charged")
		local charge = Fighter.releaseCharge(fighter, attack.Cooldown, now)
		if charge == nil then
			return
		end
		setCharging(character, false)
		Animate.play(character, Config.Styles.List[styleId].Animations.Charged)
		task.delay(
			attack.Windup,
			strike,
			player,
			character,
			fighter,
			now,
			{
				Name = "Charged",
				Label = `Charged punch {string.format("%.2f", charge)} s`,
				Attack = attack,
				Multiplier = Formulas.chargeMultiplier(charge),
				Heavy = true,
			} :: Swing
		)
	end
end

-- The Ability key: the equipped style's move (Wrecker: a parry). Styles without one ignore it.
local function onAbility(player: Player)
	local character, fighter = fighterOf(player)
	local styleId = styleOf(player)
	local style = Config.Styles.List[styleId]
	local ability = style.Ability
	if character == nil or fighter == nil or ability == nil then
		return
	end
	if Fighter.parry(fighter, os.clock(), ability.Parry.Window, ability.Cooldown) then
		Animate.play(character, style.Animations.Ability or "Parry")
		if isStudioFlag(Config.Dev.LogCombat) then
			print(`[Combat] {player.Name} parries`)
		end
	end
end

-- Run held / let go (the client turns a toggle into the same intent). Stamina decides whether it really runs.
local function onRun(player: Player, held: boolean)
	local _, fighter = fighterOf(player)
	if fighter then
		Fighter.setRunHeld(fighter, held)
	end
end

-- Stamina for every player fighter: running drains it while moving, it refills after a pause; the run speed and the
-- Stamina attribute (HUD) follow.
local function tickStamina(dt: number)
	local now = os.clock()
	for character, fighter in fighters do
		local root = rootOf(character)
		if root and Players:GetPlayerFromCharacter(character) then
			local velocity = root.AssemblyLinearVelocity
			local moving = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > Config.Combat.Stamina.MovingSpeed
			local wasRunning = fighter.Running
			local running = Fighter.tickStamina(fighter, dt, now, moving)
			if running ~= wasRunning then
				local multiplier = Config.Combat.Stamina.RunSpeedMultiplier
				CombatService.setSpeedModifier(character, RUN_SPEED_KEY, if running then multiplier else nil)
			end
			local shown = math.floor(fighter.Stamina + 0.5)
			if character:GetAttribute("Stamina") ~= shown then
				character:SetAttribute("Stamina", shown)
			end
		end
	end
end

-- The client already moved its character; the server only grants the invulnerability and spends the stamina
-- (cooldown, hitstun and stamina checked).
local function onDash(player: Player)
	local character, fighter = fighterOf(player)
	if character == nil or fighter == nil then
		return
	end
	local wasCharging = fighter.ChargeStartedAt ~= nil
	if not Fighter.dash(fighter, os.clock()) then
		return
	end
	character:SetAttribute("Stamina", math.floor(fighter.Stamina + 0.5))
	if wasCharging then
		setCharging(character, false)
	end
	Animate.play(character, "Dash", player) -- the dasher's own client already showed it
	CombatService.Dashed:Fire(player, character)
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
	PhysicsService:RegisterCollisionGroup(FIGHTER_GROUP)
	PhysicsService:CollisionGroupSetCollidable(FIGHTER_GROUP, FIGHTER_GROUP, false)

	Net.onServerEvent("Punch", onPunch)
	Net.onServerEvent("Charge", onCharge)
	Net.onServerEvent("Ability", onAbility)
	Net.onServerEvent("Dash", onDash)
	Net.onServerEvent("Run", onRun)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= STAMINA_TICK then
			tickStamina(elapsed)
			elapsed = 0
		end
	end)

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
