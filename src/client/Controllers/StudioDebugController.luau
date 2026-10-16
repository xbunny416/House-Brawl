--!strict
--[[
	StudioDebugController — Studio playtests only (never in live servers).
	Config.Dev.LogInput: prints every input action and device change to Output.
	(The camera shake checks moved to the developer panel in step 1.13.)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local InputController = require(script.Parent:WaitForChild("InputController"))

local StudioDebugController = {}

function StudioDebugController.Start(_self: any)
	if not (RunService:IsStudio() and Config.Dev.LogInput) then
		return
	end
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

return StudioDebugController
