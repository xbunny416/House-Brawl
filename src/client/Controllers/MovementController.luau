--!strict
--[[
	MovementController — running (owner, 2026-10-17). Keyboard: hold Run (Left Shift). Gamepad (left-stick press) and
	touch (the Run button): one press runs until the character stops moving, or until pressed again. The server is
	told only when that changes (Run true / false); it spends the stamina and sets the speed (CombatService), so
	running stops on its own when stamina runs out. A new character starts walking.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local InputController = require(script.Parent:WaitForChild("InputController"))

local STOP_GRACE = 0.4 -- seconds standing still that end a run started with a press (gamepad / touch)

local MovementController = {}

local player = Players.LocalPlayer
local held = false -- keyboard: Run is held
local toggled = false -- gamepad / touch: a press turned running on
local sent = false -- what the server was told last
local stillFor = 0

local function send()
	local want = held or toggled
	if want ~= sent then
		sent = want
		Net.fire("Run", want)
	end
end

local function onActionBegan(action: string)
	if action ~= "Run" then
		return
	end
	if InputController.getDevice() == "KeyboardAndMouse" then
		held = true
	else
		toggled = not toggled
		stillFor = 0
	end
	send()
end

local function onActionEnded(action: string)
	if action == "Run" and held then
		held = false
		send()
	end
end

-- A run started with a press ends once the character has stood still for STOP_GRACE.
local function watchStillness(deltaTime: number)
	if not toggled then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
		stillFor = 0
		return
	end
	stillFor += deltaTime
	if stillFor >= STOP_GRACE then
		toggled = false
		send()
	end
end

-- True while the player asks to run (held or toggled on); the server still needs stamina for it.
function MovementController.isRunning(): boolean
	return held or toggled
end

function MovementController.Start(_self: any)
	InputController.ActionBegan:Connect(onActionBegan)
	InputController.ActionEnded:Connect(onActionEnded)
	RunService.Heartbeat:Connect(watchStillness)
	player.CharacterAdded:Connect(function()
		-- The server's new fighter starts walking; tell it again if Run is still held.
		toggled = false
		sent = false
		send()
	end)
end

return MovementController
