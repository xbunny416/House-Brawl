--!strict
--[[
	CameraController — third-person camera rules (Config.Controls.Camera) and camera shake.
	  * Zoom stays between MinZoom (no first person) and MaxZoom.
	  * Shift Lock (PC) is allowed but toggled by ShiftLockKeys (Right Shift), so Left Shift stays free for Dash.
	  * CameraController.shake(intensity) plays a short shake for heavy hits. It does nothing while the player has
	    Camera Shake turned off in Settings.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local CameraShake = require(script.Parent.Parent:WaitForChild("Lib"):WaitForChild("CameraShake"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

-- How long to wait for Roblox's PlayerModule before giving up on rebinding Shift Lock.
local PLAYER_MODULE_TIMEOUT = 10

type Shake = {
	startedAt: number,
	magnitude: number, -- studs
	degrees: number, -- tilt
	seed: number,
}

local CameraController = {}

local cameraConfig = Config.Controls.Camera
local shakes: { Shake } = {}
local random = Random.new()

-- Starts a camera shake. `intensity` (0–1, default 1) scales Config.Controls.Camera.ShakeMagnitude.
function CameraController.shake(intensity: number?)
	local scale = math.clamp(intensity or 1, 0, 1)
	if scale <= 0 or not SettingsController.get("CameraShake") then
		return
	end
	table.insert(shakes, {
		startedAt = os.clock(),
		magnitude = cameraConfig.ShakeMagnitude * scale,
		degrees = cameraConfig.ShakeRotation * scale,
		seed = random:NextNumber(0, 1000) + 0.5,
	})
end

-- The shake added to the camera last frame. It is taken off again just before Roblox's camera update, so the camera
-- scripts never see it and never drift.
local applied: CFrame? = nil

local function removeShake()
	local current = Workspace.CurrentCamera
	if applied and current then
		current.CFrame *= applied:Inverse()
	end
	applied = nil
end

-- Runs right after Roblox's camera update each frame: moves and tilts the camera by every running shake.
local function applyShakes()
	if #shakes == 0 then
		return
	end
	local now = os.clock()
	local x, y, pitch, roll = 0, 0, 0, 0
	for index = #shakes, 1, -1 do
		local shake = shakes[index]
		local elapsed = now - shake.startedAt
		if elapsed >= cameraConfig.ShakeDuration then
			table.remove(shakes, index)
		else
			local duration, frequency = cameraConfig.ShakeDuration, cameraConfig.ShakeFrequency
			local dx, dy = CameraShake.offset(elapsed, duration, shake.magnitude, frequency, shake.seed)
			local dPitch, dRoll = CameraShake.tilt(elapsed, duration, shake.degrees, frequency, shake.seed)
			x += dx
			y += dy
			pitch += dPitch
			roll += dRoll
		end
	end
	local current = Workspace.CurrentCamera
	if current == nil then
		return
	end
	local limit, tiltLimit = cameraConfig.ShakeMagnitude, cameraConfig.ShakeRotation
	local offset = CFrame.new(math.clamp(x, -limit, limit), math.clamp(y, -limit, limit), 0)
		* CFrame.Angles(
			math.rad(math.clamp(pitch, -tiltLimit, tiltLimit)),
			0,
			math.rad(math.clamp(roll, -tiltLimit, tiltLimit))
		)
	current.CFrame *= offset
	applied = offset
end

-- Roblox's MouseLockController reads its toggle keys from a "BoundKeys" StringValue and rebinds when it changes.
local function rebindShiftLock(player: Player)
	local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", PLAYER_MODULE_TIMEOUT)
	local cameraModule = playerModule and playerModule:WaitForChild("CameraModule", PLAYER_MODULE_TIMEOUT)
	local mouseLock = cameraModule and cameraModule:WaitForChild("MouseLockController", PLAYER_MODULE_TIMEOUT)
	if mouseLock == nil then
		warn("[CameraController] Roblox MouseLockController not found; Left Shift may still toggle Shift Lock")
		return
	end
	local keys = table.concat(cameraConfig.ShiftLockKeys, ",")
	local boundKeys = mouseLock:FindFirstChild("BoundKeys")
	if boundKeys and boundKeys:IsA("StringValue") then
		boundKeys.Value = keys
	else
		local value = Instance.new("StringValue")
		value.Name = "BoundKeys"
		value.Value = keys
		value.Parent = mouseLock
	end
end

function CameraController.Init(_self: any)
	local player = Players.LocalPlayer
	player.CameraMaxZoomDistance = cameraConfig.MaxZoom
	player.CameraMinZoomDistance = cameraConfig.MinZoom
	player.DevEnableMouseLock = cameraConfig.ShiftLockAllowed

	SettingsController.Changed:Connect(function(key: string, value: any)
		if key == "CameraShake" and not value then
			table.clear(shakes)
		end
	end)
	RunService:BindToRenderStep("CameraShakeUndo", Enum.RenderPriority.Camera.Value - 1, removeShake)
	RunService:BindToRenderStep("CameraShake", Enum.RenderPriority.Camera.Value + 1, applyShakes)
end

function CameraController.Start(_self: any)
	if cameraConfig.ShiftLockAllowed then
		rebindShiftLock(Players.LocalPlayer)
	end
end

return CameraController
