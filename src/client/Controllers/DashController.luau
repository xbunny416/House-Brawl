--!strict
--[[
	DashController — Dash (Q / RB / the touch Dash button).
	The local character moves at once, because clients simulate their own character: Config.Combat.Dash.Distance
	studs in Duration seconds along the move direction (or the facing), level even in the air. The server is told at
	the same moment and grants the invulnerability after checking the cooldown, hitstun and stamina.
	Rules (Lib/DashRules): cooldown, one dash per stay in the air, none during hitstun, and Stamina.DashCost stamina
	(the Stamina attribute; the server spends it). An air dash after hitstun ends a knockback launch, which is how a
	launched player recovers.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))
local Launch = require(Shared:WaitForChild("Combat"):WaitForChild("Launch"))

local DashRules = require(script.Parent.Parent:WaitForChild("Lib"):WaitForChild("DashRules"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local MOVER_NAME = "DashMover"

local DashController = {
	-- () each time the local player dashes (dash cooldown ring, VFX).
	Dashed = Signal.new() :: Signal.Signal<()>,
}

local player = Players.LocalPlayer
local state = DashRules.new()

-- Seconds until the next dash is allowed (0 when ready).
function DashController.cooldownLeft(): number
	return DashRules.cooldownLeft(state, os.clock())
end

-- Where the dash goes: the way the player is moving, else the way the character faces (flat).
local function dashDirection(humanoid: Humanoid, root: BasePart): Vector3
	local move = humanoid.MoveDirection
	local flat = Vector3.new(move.X, 0, move.Z)
	if flat.Magnitude < 0.1 then
		local look = root.CFrame.LookVector
		flat = Vector3.new(look.X, 0, look.Z)
	end
	return if flat.Magnitude > 1e-3 then flat.Unit else -Vector3.zAxis
end

-- Holds the dash velocity (horizontal, no gravity) for Duration seconds.
local function push(root: BasePart, direction: Vector3)
	local old = root:FindFirstChild(MOVER_NAME)
	if old then
		old:Destroy()
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = MOVER_NAME
	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = attachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.ForceLimitsEnabled = false
	mover.VectorVelocity = direction * Formulas.dashSpeed()
	mover.Parent = attachment
	attachment.Parent = root
	task.delay(Config.Combat.Dash.Duration, function()
		attachment:Destroy()
	end)
end

local function onActionBegan(action: string)
	if action ~= "Dash" or player:GetAttribute("RoundStatus") ~= "Playing" then
		return -- dashing only in a round: the lobby is run-only
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character == nil or humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end
	if Launch.inHitstun(character) then
		return
	end
	-- Not enough stamina (the server checks again and spends it).
	local stamina = character:GetAttribute("Stamina")
	if type(stamina) == "number" and stamina < Config.Combat.Stamina.DashCost then
		return
	end
	local airborne = humanoid.FloorMaterial == Enum.Material.Air or Launch.isLaunched(character)
	if not DashRules.tryDash(state, os.clock(), airborne, Config.Combat.Dash) then
		return
	end
	Net.fire("Dash")
	Launch.stop(character)
	push(root, dashDirection(humanoid, root))
	DashController.Dashed:Fire()
end

local function watchCharacter(character: Model)
	DashRules.landed(state)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid == nil or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			DashRules.landed(state)
		end
	end)
end

function DashController.Init(_self: any)
	InputController.ActionBegan:Connect(onActionBegan)
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
end

return DashController
