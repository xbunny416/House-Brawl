--!strict
--[[
	ActivityController — tells the server the player is not AFK. Any input (keys, buttons, mouse, touch, sticks) since
	the last report is sent as one Activity ping every Config.Round.Participation.ActivityPingInterval seconds.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local ActivityController = {}

local hadInput = false

local function onInput()
	hadInput = true
end

function ActivityController.Init(_self: any)
	UserInputService.InputBegan:Connect(onInput)
	UserInputService.InputChanged:Connect(onInput)
end

function ActivityController.Start(_self: any)
	while true do
		task.wait(Config.Round.Participation.ActivityPingInterval)
		if hadInput then
			hadInput = false
			Net.fire("Activity")
		end
	end
end

return ActivityController
