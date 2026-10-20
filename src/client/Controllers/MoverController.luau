--!strict
--[[
	MoverController — moves the arena's moving parts on this client (Shared/MoverRules: lifts, sliding platforms,
	swinging hazards). The server never moves them; every client places them from the shared server clock each
	physics step, so they look smooth and nothing is sent over the network. Each part also gets the speed it is
	moving at, so a character standing on a lift or a sliding platform rides along with it. (The server's own copy
	stays where it rests: MoverService works hazards out from the same rules.)
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MoverRules = require(Shared:WaitForChild("MoverRules"))

local MOVER_TAG = "Mover"

type Mover = {
	Model: Model,
	Params: MoverRules.Params,
	Rest: CFrame, -- where the pivot rests (the server's copy never moves)
	Parts: { BasePart },
	Last: { [BasePart]: Vector3 }, -- each part's position at the last step, for its speed
	LastPivot: CFrame?,
}

local MoverController = {}

local movers: { [Model]: Mover } = {}

local function add(instance: Instance)
	if not instance:IsA("Model") or movers[instance] then
		return
	end
	local pivot = instance.PrimaryPart
	if pivot == nil then
		return
	end
	local parts: { BasePart } = {}
	for _, part in instance:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end
	movers[instance] = {
		Model = instance,
		Params = MoverRules.read(instance),
		Rest = pivot.CFrame,
		Parts = parts,
		Last = {},
		LastPivot = nil,
	}
end

local function remove(instance: Instance)
	movers[instance :: Model] = nil
end

local function step(dt: number)
	local t = Workspace:GetServerTimeNow()
	for model, mover in movers do
		if model.Parent == nil or model.PrimaryPart == nil then
			movers[model] = nil
			continue
		end
		local target = MoverRules.pivotAt(mover.Params, mover.Rest, t)
		model:PivotTo(target)
		-- Each part's speed, so characters standing on it are carried (an anchored part's velocity moves what
		-- stands on it).
		local spin = Vector3.zero
		local lastPivot = mover.LastPivot
		if lastPivot and dt > 0 then
			local axis, angle = (lastPivot.Rotation:Inverse() * target.Rotation):ToAxisAngle()
			spin = lastPivot.Rotation:VectorToWorldSpace(axis) * (angle / dt)
		end
		for _, part in mover.Parts do
			local position = part.Position
			local before = mover.Last[part]
			if before and dt > 0 then
				part.AssemblyLinearVelocity = (position - before) / dt
				part.AssemblyAngularVelocity = spin
			end
			mover.Last[part] = position
		end
		mover.LastPivot = target
	end
end

function MoverController.Start(_self: any)
	for _, instance in CollectionService:GetTagged(MOVER_TAG) do
		add(instance)
	end
	CollectionService:GetInstanceAddedSignal(MOVER_TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(MOVER_TAG):Connect(remove)
	RunService.PreSimulation:Connect(step)
end

return MoverController
