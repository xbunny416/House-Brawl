--!strict
--[[
	SpectateController — while the local player is spectating a round (Classic: out of lives, joined late, or left out
	for being AFK) the camera follows a fighter still in it. SpectatePrevious / SpectateNext (Z / X, D-pad) or the
	arrows on the bottom bar switch fighters; when the watched fighter is knocked out the next one is picked.
	The server streams the watched fighter's surroundings to this client (Spectate remote).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local REFRESH_INTERVAL = 0.25

local SpectateController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local nameLabel: TextLabel
local active = false
local target: Player? = nil

-- Fighters still in the round, in a stable order.
local function candidates(): { Player }
	local list: { Player } = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("RoundStatus") == "Playing" then
			table.insert(list, other)
		end
	end
	table.sort(list, function(a: Player, b: Player): boolean
		return a.UserId < b.UserId
	end)
	return list
end

local function setTarget(newTarget: Player?)
	if newTarget ~= target then
		target = newTarget
		Net.fire("Spectate", if newTarget then newTarget.UserId else 0)
	end
	nameLabel.Text = if newTarget
		then Localization.format("Spectate.Watching", { newTarget.DisplayName })
		else Localization.format("Spectate.Nobody")
end

local function cycle(step: number)
	local list = candidates()
	if #list == 0 then
		setTarget(nil)
		return
	end
	local index = (target and table.find(list, target)) or 0
	setTarget(list[(index - 1 + step) % #list + 1])
end

local function ownHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function stop()
	active = false
	gui.Enabled = false
	setTarget(nil)
	local camera = Workspace.CurrentCamera
	local humanoid = ownHumanoid()
	if camera and humanoid then
		camera.CameraSubject = humanoid
	end
end

local function refresh()
	local spectating = player:GetAttribute("RoundStatus") == "Spectating"
		and Workspace:GetAttribute("RoundState") == "Playing"
	if not spectating then
		if active then
			stop()
		end
		return
	end
	if not active then
		active = true
		gui.Enabled = true
	end
	local current = target
	if current == nil or current.Parent ~= Players or current:GetAttribute("RoundStatus") ~= "Playing" then
		target = nil
		cycle(1)
		current = target
	end
	-- The watched fighter's character arrives once the server has streamed it in.
	local character = current and current.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local camera = Workspace.CurrentCamera
	if camera and humanoid and camera.CameraSubject ~= humanoid then
		camera.CameraSubject = humanoid
	end
end

local function build()
	gui = Kit.screen("Spectate", 4)
	local bar = Kit.panel(
		gui,
		UDim2.fromScale(0.44, 0.1),
		UDim2.fromScale(0.5, 0.97),
		Vector2.new(0.5, 1),
		Vector2.new(520, 72)
	)
	Kit.list(bar, Enum.FillDirection.Horizontal, UDim.new(0.02, 0))
	local previous = Kit.button(bar, Localization.format("Controls.SpectatePrevious"), UDim2.fromScale(0.14, 1))
	previous.LayoutOrder = 1
	previous.Activated:Connect(function()
		cycle(-1)
	end)
	nameLabel = Kit.label(bar, "", UDim2.fromScale(0.66, 1))
	nameLabel.LayoutOrder = 2
	local nextButton = Kit.button(bar, Localization.format("Controls.SpectateNext"), UDim2.fromScale(0.14, 1))
	nextButton.LayoutOrder = 3
	nextButton.Activated:Connect(function()
		cycle(1)
	end)
end

function SpectateController.isSpectating(): boolean
	return active
end

function SpectateController.Start(_self: any)
	build()
	InputController.ActionBegan:Connect(function(action: string)
		if not active then
			return
		end
		if action == "SpectatePrevious" then
			cycle(-1)
		elseif action == "SpectateNext" then
			cycle(1)
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return SpectateController
