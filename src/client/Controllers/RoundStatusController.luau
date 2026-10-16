--!strict
--[[
	RoundStatusController — one line at the top of the screen: "Waiting for players (1/2)", or during a round its mode,
	time left and (Classic) the local player's lives. Hidden while the vote or results panels are up.
	The full round HUD (HP / Percent, kill feed, scoreboard) comes in step 1.12.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))

local REFRESH_INTERVAL = 0.25

local RoundStatusController = {}

local gui: ScreenGui
local label: TextLabel

local function clock(seconds: number): string
	local whole = math.max(math.ceil(seconds), 0)
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function describe(): string?
	local state = Workspace:GetAttribute("RoundState")
	if state == "Waiting" then
		local needed = Workspace:GetAttribute("PlayersNeeded")
		return Localization.format("Round.Waiting", { #Players:GetPlayers(), needed or 2 })
	elseif state == "Playing" then
		local mode = Workspace:GetAttribute("RoundMode")
		local endsAt = Workspace:GetAttribute("RoundEndsAt")
		local modeName = if type(mode) == "string" then Localization.format(`Mode.{mode}.Name`) else ""
		local timeLeft = clock(if type(endsAt) == "number" then endsAt - Workspace:GetServerTimeNow() else 0)
		local lives = Players.LocalPlayer:GetAttribute("Lives")
		if type(lives) == "number" then
			local args: { any } = { modeName, timeLeft, lives }
			return Localization.format("Round.TimerLives", args)
		end
		return Localization.format("Round.Timer", { modeName, timeLeft })
	end
	return nil
end

local function refresh()
	local text = describe()
	gui.Enabled = text ~= nil
	if text then
		label.Text = text
	end
end

function RoundStatusController.Start(_self: any)
	gui = Kit.screen("RoundStatus", 3)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.34, 0.07),
		UDim2.fromScale(0.5, 0.015),
		Vector2.new(0.5, 0),
		Vector2.new(420, 48)
	)
	label = Kit.label(panel, "", UDim2.fromScale(1, 1), 22)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return RoundStatusController
