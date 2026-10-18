--!strict
--[[
	PerformanceController — low-end devices (bible §6 "runs smoothly on low-end phones"; step 3.11). Once per player
	(the saved GraphicsAutoChecked setting), Config.Performance.AutoLowGraphics.StartDelay seconds after their data
	loads, it measures the frame rate for SampleTime seconds; below MinFps — with Low Graphics still off — it turns
	Low Graphics on and says so (they can switch it back in Settings). Either way the check never runs again.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local DataController = require(script.Parent:WaitForChild("DataController"))
local NoticeController = require(script.Parent:WaitForChild("NoticeController"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

local PerformanceController = {}

-- Average frames per second over the next `seconds`.
local function measureFps(seconds: number): number
	local frames, elapsed = 0, 0
	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		frames += 1
		elapsed += deltaTime
	end)
	task.wait(seconds)
	connection:Disconnect()
	return if elapsed > 0 then frames / elapsed else math.huge
end

local function checkOnce()
	DataController.waitForData()
	local config = Config.Performance.AutoLowGraphics
	task.wait(config.StartDelay) -- also lets the saved settings arrive
	if SettingsController.get("GraphicsAutoChecked") == true then
		return
	end
	local fps = measureFps(config.SampleTime)
	if fps < config.MinFps and SettingsController.get("LowGraphics") ~= true then
		SettingsController.set("LowGraphics", true)
		NoticeController.show("Performance.LowGraphicsOn")
	end
	SettingsController.set("GraphicsAutoChecked", true)
end

function PerformanceController.Start(_self: any)
	task.spawn(checkOnce)
end

return PerformanceController
