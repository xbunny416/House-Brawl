--!strict
--[[
	DummyService — the Training Yard dummy (bible §3.3). One stands still on every TrainingDummySpot in the lobby.
	Anyone can hit it, also in the lobby (it is not PvP); its Percent is shown above it by the client
	(TrainingDummyController). It respawns Config.Combat.Dummy.RespawnTime seconds after it is knocked out or falls
	Config.Combat.Dummy.FallDistance studs below its spot (e.g. shoved off the ledge).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local CombatService = require(script.Parent:WaitForChild("CombatService"))

local SPOT_TAG = "TrainingDummySpot"
local DUMMY_TAG = "TrainingDummy"
local SPAWN_HEIGHT = 3
local FALL_CHECK_INTERVAL = 0.2
local BODY_COLOR = Color3.fromHex("#B5652B") -- rusty orange

local DummyService = {}

local folder: Folder
local spots: { [Model]: BasePart } = {} -- standing dummies and their spots

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
		warn(`[DummyService] could not build the training dummy: {result}`)
		return nil
	end
	return result
end

local function spawnDummy(spot: BasePart)
	local model = buildModel()
	if model == nil or not spot:IsDescendantOf(Workspace) then
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
	model:PivotTo(spot.CFrame + Vector3.new(0, SPAWN_HEIGHT, 0))
	model:AddTag(DUMMY_TAG)
	model.Parent = folder
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root:SetNetworkOwner(nil) -- the server simulates the dummy, so it runs the dummy's knockback
	end
	CombatService.register(model)
	spots[model] = spot
end

-- Knocked out: the dummy is no longer a target, and is replaced after RespawnTime.
local function onKnockedOut(character: Model)
	local spot: BasePart? = spots[character]
	if spot == nil then
		return
	end
	spots[character] = nil
	CombatService.unregister(character)
	task.delay(Config.Combat.Dummy.RespawnTime, function()
		character:Destroy()
		spawnDummy(spot)
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
		for model, spot in spots do
			local root = model:FindFirstChild("HumanoidRootPart")
			local fallen = root == nil
				or not root:IsA("BasePart")
				or root.Position.Y < spot.Position.Y - Config.Combat.Dummy.FallDistance
			if fallen then
				CombatService.knockOut(model, "Fall")
			end
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
	for _, spot in CollectionService:GetTagged(SPOT_TAG) do
		if spot:IsA("BasePart") and spot:IsDescendantOf(Workspace) then
			task.spawn(spawnDummy, spot)
		end
	end
	watchFalls()
end

return DummyService
