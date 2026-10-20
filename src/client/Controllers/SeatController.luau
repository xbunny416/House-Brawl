--!strict
--[[
	SeatController — the "Sit" prompts on the lobby's seats (owner's fix list, 2026-10-19: "sit on chairs / couches").
	Every LobbySeat-tagged Seat (sofa and armchair cushions, booth benches, bar and high-table stools) gets a
	ProximityPrompt within Config.Controls.Prompts.SitDistance (E / gamepad B / tap); it asks the server (Sit remote,
	SeatService), which checks everything again. Jump to stand up. A prompt hides while its seat is taken, while you
	sit, while a menu screen is open and while you are fighting. Seats that stream in later get their prompt then;
	the bottom-edge key hints show "[E] Sit" near one (HintBarController).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local MenuController = require(script.Parent:WaitForChild("MenuController"))

local SEAT_TAG = "LobbySeat"
local PROMPT_NAME = "SitPrompt"
local REFRESH_INTERVAL = 0.25

local SeatController = {}

local player = Players.LocalPlayer
local prompts: { [Seat]: ProximityPrompt } = {}

local function sitting(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.SeatPart ~= nil
end

local function addPrompt(instance: Instance)
	if not instance:IsA("Seat") or prompts[instance] then
		return
	end
	local seat = instance :: Seat
	local config = Config.Controls.Prompts
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	-- The arm-wrestling and chess tables' seats (ArmWrestleService, ChessService) say what sitting there starts.
	prompt.ActionText = Localization.format(
		if seat:HasTag("ArmWrestleSeat")
			then "Prompt.ArmWrestle"
			elseif seat:HasTag("ChessSeat") then "Prompt.Chess"
			else "Prompt.Sit"
	)
	prompt.KeyboardKeyCode = (Enum.KeyCode :: any)[config.Keyboard]
	prompt.GamepadKeyCode = (Enum.KeyCode :: any)[config.Gamepad]
	prompt.MaxActivationDistance = config.SitDistance
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Enabled = false
	prompt.Triggered:Connect(function()
		Net.fire("Sit", seat)
	end)
	prompt.Parent = seat
	prompts[seat] = prompt
end

local function refresh()
	local blocked = sitting() or MenuController.isFighting() or MenuController.isOpen()
	for seat, prompt in prompts do
		if seat.Parent == nil or prompt.Parent ~= seat then
			prompts[seat] = nil -- streamed out or removed
		else
			prompt.Enabled = not blocked and seat.Occupant == nil
		end
	end
end

function SeatController.Start(_self: any)
	for _, seat in CollectionService:GetTagged(SEAT_TAG) do
		addPrompt(seat)
	end
	CollectionService:GetInstanceAddedSignal(SEAT_TAG):Connect(addPrompt)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return SeatController
