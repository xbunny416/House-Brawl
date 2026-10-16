--!strict
--[[
	CombatController — the local player's side of combat.
	  * Sends intents: Attack -> Punch; Shove pressed / released -> Shove "Start" / "Release". The server decides
	    everything else (cooldowns, hits, damage, knockback).
	  * A right-click Shove turns into a camera turn (Shove "Cancel") if the mouse drags Config.Controls.ShoveDragCancel
	    pixels while the camera is being rotated with the right button.
	  * Runs the knockback the server sends for the local character (clients simulate their own character).
	  * Shakes the camera on heavy hits taken or landed.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Launch = require(Shared:WaitForChild("Combat"):WaitForChild("Launch"))

local CameraController = require(script.Parent:WaitForChild("CameraController"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local CombatController = {}

local player = Players.LocalPlayer
local charging = false
local dragged = 0

local function onActionBegan(action: string)
	if action == "Attack" then
		-- Our facing and position as we see them; the server uses them to aim a throw (when holding a prop).
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			Net.fire("Punch", root.CFrame.LookVector, root.Position)
		else
			Net.fire("Punch")
		end
	elseif action == "Shove" then
		charging = true
		dragged = 0
		Net.fire("Shove", "Start")
	end
end

local function onActionEnded(action: string)
	if action == "Shove" and charging then
		charging = false
		Net.fire("Shove", "Release")
	end
end

-- Roblox locks the mouse in place while the right button turns the camera; mouse movement then is a camera drag.
local function onInputChanged(input: InputObject)
	local limit = Config.Controls.ShoveDragCancel
	if
		not charging
		or limit == nil
		or input.UserInputType ~= Enum.UserInputType.MouseMovement
		or UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCurrentPosition
		or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	then
		return
	end
	dragged += input.Delta.Magnitude
	if dragged >= limit then
		charging = false
		Net.fire("Shove", "Cancel")
	end
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
	UserInputService.InputChanged:Connect(onInputChanged)
	Net.on("Knockback", onKnockback)
	Net.on("CombatHit", onCombatHit)
end

return CombatController
