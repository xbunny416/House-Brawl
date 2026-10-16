--!strict
--[[
	StudioDebugController — Studio playtests only (never in live servers).
	  * Config.Dev.LogInput: prints every input action and device change to Output.
	  * Config.Dev.StudioKeys: K plays a test camera shake, L turns the Camera Shake setting on/off (saved).
	The developer panel (step 1.13) replaces the debug keys.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local CameraController = require(script.Parent:WaitForChild("CameraController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

local StudioDebugController = {}

local function logInput()
	print(`[Input] device: {InputController.getDevice()}`)
	InputController.DeviceChanged:Connect(function(device: string)
		print(`[Input] device: {device}`)
	end)
	InputController.ActionBegan:Connect(function(action: string)
		print(`[Input] {action} began`)
	end)
	InputController.ActionEnded:Connect(function(action: string)
		print(`[Input] {action} ended`)
	end)
end

local function bindKeys()
	local keys = Config.Dev.StudioKeys
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		local key = input.KeyCode.Name
		if key == keys.TestCameraShake then
			CameraController.shake(1)
			print(`[Debug] camera shake (setting: {SettingsController.get("CameraShake")})`)
		elseif key == keys.ToggleCameraShake then
			local enabled = not SettingsController.get("CameraShake")
			SettingsController.set("CameraShake", enabled)
			print(`[Debug] Camera Shake setting -> {enabled}`)
		end
	end)
end

function StudioDebugController.Start(_self: any)
	if not RunService:IsStudio() then
		return
	end
	if Config.Dev.LogInput then
		logInput()
	end
	bindKeys()
end

return StudioDebugController
