--!strict
--[[
	DummyService — the practice dummy, a developer-panel test target (the lobby's Training Yard was removed on the
	owner's request, 2026-10-16). DummyService.spawnAt puts one standing dummy at a place (the panel's "Dummy"
	button: in front of you); a new one replaces the old. Anyone can hit it, also in the lobby (it is not PvP); its
	Percent is shown above it by the client (TrainingDummyController). It comes back at the same place
	Config.Combat.Dummy.RespawnTime seconds after it is knocked out or falls Config.Combat.Dummy.FallDistance studs
	below it, as long as there is still ground there (not after its arena was unloaded).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local CombatService = require(script.Parent:WaitForChild("CombatService"))

local DUMMY_TAG = "TrainingDummy"
local FALL_CHECK_INTERVAL = 0.2
local GROUND_CHECK = 12 -- studs below the dummy's place that must hit something before it respawns there
local BODY_COLOR = Color3.fromHex("#B5652B") -- rusty orange

local DummyService = {}

local folder: Folder
local current: Model? = nil -- the standing dummy
local home: CFrame? = nil -- where it stands (its root)
local generation = 0 -- bumped by every spawnAt, so a slow build for an old place is thrown away

local function buildModel(): Model?
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = BODY_COLOR
	description.TorsoColor = BODY_COLOR
	description.LeftArmColor = BODY_COLOR
	description.RightArmColor = BODY_COLOR
	description.LeftLegColor = BODY_COLOR
	description.RightLegColor = BODY_COLOR
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn(`[DummyService] could not build the practice dummy: {result}`)
		return nil
	end
	return result
end

local function hasGround(at: CFrame): boolean
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { folder }
	params.FilterType = Enum.RaycastFilterType.Exclude
	return Workspace:Raycast(at.Position, Vector3.new(0, -GROUND_CHECK, 0), params) ~= nil
end

local function spawnDummy(at: CFrame, forGeneration: number)
	local model = buildModel()
	if model == nil then
		return
	end
	if forGeneration ~= generation then
		model:Destroy() -- replaced while it was being built
		return
	end
	model.Name = "TrainingDummy"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.WalkSpeed = 0
		humanoid.BreakJointsOnDeath = false
	end
	model:PivotTo(at)
	model:AddTag(DUMMY_TAG)
	model.Parent = folder
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root:SetNetworkOwner(nil) -- the server simulates the dummy, so it runs the dummy's knockback
	end
	CombatService.register(model)
	current = model
end

-- Puts the practice dummy at `at` (its root's CFrame), replacing the one already standing.
function DummyService.spawnAt(at: CFrame)
	generation += 1
	home = at
	local old = current
	current = nil
	if old then
		CombatService.unregister(old)
		old:Destroy()
	end
	task.spawn(spawnDummy, at, generation)
end

-- Knocked out: the dummy is no longer a target, and is replaced after RespawnTime.
local function onKnockedOut(character: Model)
	if character ~= current then
		return
	end
	current = nil
	CombatService.unregister(character)
	local forGeneration = generation
	task.delay(Config.Combat.Dummy.RespawnTime, function()
		character:Destroy()
		local at = home
		if at and forGeneration == generation and hasGround(at) then
			spawnDummy(at, forGeneration)
		end
	end)
end

local function watchFalls()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed < FALL_CHECK_INTERVAL then
			return
		end
		elapsed = 0
		local model, at = current, home
		if model == nil or at == nil then
			return
		end
		local root = model:FindFirstChild("HumanoidRootPart")
		if
			root == nil
			or not root:IsA("BasePart")
			or root.Position.Y < at.Position.Y - Config.Combat.Dummy.FallDistance
		then
			CombatService.knockOut(model, "Fall")
		end
	end)
end

function DummyService.Init(_self: any)
	folder = Instance.new("Folder")
	folder.Name = "TrainingDummies"
	folder.Parent = Workspace
	CombatService.KnockedOut:Connect(onKnockedOut)
end

function DummyService.Start(_self: any)
	watchFalls()
end

return DummyService
