--!strict
--[[
	CombatController — the local player's side of combat.
	  * Sends intents. Attack pressed -> Punch at once. Attack still held Config.Combat.Attacks.Charged.HoldTime later
	    -> Charge "Start"; let go -> Charge "Release" (the charged punch). A press that throws a held prop never
	    charges. Ability pressed -> Ability (the equipped style's move, e.g. the Wrecker parry). The server decides
	    everything else (cooldowns, hits, damage, knockback).
	  * Shows the touch Ability button only for styles that have an ability, labelled with its move.
	  * Runs the knockback the server sends for the local character (clients simulate their own character).
	  * Shakes the camera on heavy hits taken or landed.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Launch = require(Shared:WaitForChild("Combat"):WaitForChild("Launch"))

local CameraController = require(script.Parent:WaitForChild("CameraController"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local CombatController = {}

local player = Players.LocalPlayer
local charging = false
local pressCount = 0 -- tells a held press apart from a newer one

local function onAttackPressed()
	pressCount += 1
	local press = pressCount
	local character = player.Character
	local holdingProp = character ~= nil and character:GetAttribute("HeldProp") ~= nil
	-- Our facing and position as we see them; the server uses them to aim a throw (when holding a prop).
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		Net.fire("Punch", root.CFrame.LookVector, root.Position)
	else
		Net.fire("Punch")
	end
	if holdingProp then
		return -- that press threw the prop: no charge
	end
	task.delay(Config.Combat.Attacks.Charged.HoldTime, function()
		if press == pressCount and InputController.isDown("Attack") and not charging then
			charging = true
			Net.fire("Charge", "Start")
		end
	end)
end

local function onActionBegan(action: string)
	if action == "Attack" then
		onAttackPressed()
	elseif action == "Ability" then
		Net.fire("Ability")
	end
end

local function onActionEnded(action: string)
	if action == "Attack" and charging then
		charging = false
		Net.fire("Charge", "Release")
	end
end

-- The touch Ability button: only for a style with an ability, labelled with what it does.
local function refreshAbilityButton()
	local data = DataController.get()
	local style = data and Config.Styles.List[data.Styles.Equipped]
	local ability = style and style.Ability
	InputController.setVisible("Ability", ability ~= nil)
	InputController.setLabel("Ability", if ability then "Controls.Parry" else nil)
end

local function onKnockback(velocity: Vector3, hitstun: number)
	local character = player.Character
	if character then
		Launch.apply(character, velocity, hitstun)
	end
end

local function onCombatHit(attacker: Model?, victim: Model?, _attack: string, heavy: boolean, _trail: boolean)
	local character = player.Character
	if not heavy or character == nil then
		return
	end
	if victim == character then
		CameraController.shake(Config.Combat.Feedback.VictimShake)
	elseif attacker == character then
		CameraController.shake(Config.Combat.Feedback.AttackerShake)
	end
end

function CombatController.Init(_self: any)
	InputController.ActionBegan:Connect(onActionBegan)
	InputController.ActionEnded:Connect(onActionEnded)
	Net.on("Knockback", onKnockback)
	Net.on("CombatHit", onCombatHit)
end

function CombatController.Start(_self: any)
	refreshAbilityButton()
	DataController.Changed:Connect(function(key: string)
		if key == "Styles" then
			refreshAbilityButton()
		end
	end)
end

return CombatController
