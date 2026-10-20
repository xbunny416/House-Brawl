--!strict
--[[
	MoverService — the server side of the arenas' moving parts (Shared/MoverRules). The server never moves them: every
	client moves its own copy from the shared server clock (MoverController), which is smooth and sends nothing. The
	server only needs to know where a hazard is: every frame it works each swinging hazard's place out from the same
	rules, and a fighter it touches (Hazard-tagged parts, within Config.Maps.Movers.HazardReach) is knocked along the
	swing through CombatService.push — no damage, no Percent, no KO credit; spawn shields and dashes let it pass. Each
	fighter can be knocked again after HazardCooldown seconds.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MoverRules = require(Shared:WaitForChild("MoverRules"))

local CombatService = require(script.Parent:WaitForChild("CombatService"))

local MOVER_TAG = "Mover"
local HAZARD_TAG = "Hazard"
local BODY_HALF = Vector3.new(1, 2.5, 1) -- a character's half size around its root (studs)
local VELOCITY_STEP = 0.05 -- seconds between the two samples that give a hazard's speed

type Hazard = { Part: BasePart, FromPivot: CFrame } -- the part's place relative to the pivot at rest
type Mover = { Model: Model, Params: MoverRules.Params, Rest: CFrame, Hazards: { Hazard } }

local MoverService = {}

local movers: { [Model]: Mover } = {}
local lastPushed: { [Model]: number } = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Movers] {message}`)
	end
end

local function add(instance: Instance)
	if not instance:IsA("Model") or not instance:IsDescendantOf(Workspace) or movers[instance] then
		return
	end
	local pivot = instance.PrimaryPart
	if pivot == nil then
		warn(`[Movers] {instance:GetFullName()} has no Pivot part`)
		return
	end
	local hazards: { Hazard } = {}
	for _, part in instance:GetDescendants() do
		if part:IsA("BasePart") and part:HasTag(HAZARD_TAG) then
			table.insert(hazards, { Part = part, FromPivot = pivot.CFrame:ToObjectSpace(part.CFrame) })
		end
	end
	local params = MoverRules.read(instance)
	movers[instance] = { Model = instance, Params = params, Rest = pivot.CFrame, Hazards = hazards }
	log(`{instance.Name}: {params.Kind}{if #hazards > 0 then `, {#hazards} hazard part(s)` else ""}`)
end

local function remove(instance: Instance)
	movers[instance :: Model] = nil
end

-- Knocks every fighter a hazard part touches at time `t`.
local function checkHazard(mover: Mover, hazard: Hazard, t: number, now: number)
	local settings = Config.Maps.Movers
	local cframe = MoverRules.pivotAt(mover.Params, mover.Rest, t) * hazard.FromPivot
	local later = MoverRules.pivotAt(mover.Params, mover.Rest, t + VELOCITY_STEP) * hazard.FromPivot
	local half = hazard.Part.Size / 2 + BODY_HALF + Vector3.one * settings.HazardReach
	for _, character in CombatService.combatants() do
		local root = character:FindFirstChild("HumanoidRootPart")
		if root == nil or not root:IsA("BasePart") or now < (lastPushed[character] or 0) + settings.HazardCooldown then
			continue
		end
		local localPoint = cframe:PointToObjectSpace(root.Position)
		if math.abs(localPoint.X) > half.X or math.abs(localPoint.Y) > half.Y or math.abs(localPoint.Z) > half.Z then
			continue
		end
		-- Along the swing where it hits; straight away from the part if it is about to turn.
		local motion = later.Position - cframe.Position
		local flat = Vector3.new(motion.X, 0, motion.Z)
		if flat.Magnitude < 0.05 then
			flat = Vector3.new(root.Position.X - cframe.Position.X, 0, root.Position.Z - cframe.Position.Z)
		end
		local direction = if flat.Magnitude > 0.001 then flat.Unit else Vector3.xAxis
		local velocity = (direction + Vector3.yAxis * settings.HazardUp).Unit * settings.HazardSpeed
		if CombatService.push(character, velocity, settings.HazardHitstun) then
			lastPushed[character] = now
			log(`{mover.Model.Name} knocked {character.Name}`)
		end
	end
end

function MoverService.Start(_self: any)
	for _, instance in CollectionService:GetTagged(MOVER_TAG) do
		add(instance)
	end
	CollectionService:GetInstanceAddedSignal(MOVER_TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(MOVER_TAG):Connect(remove)
	RunService.Heartbeat:Connect(function()
		local t = Workspace:GetServerTimeNow()
		local now = os.clock()
		for model, mover in movers do
			if not model:IsDescendantOf(Workspace) then
				movers[model] = nil
				continue
			end
			for _, hazard in mover.Hazards do
				checkHazard(mover, hazard, t, now)
			end
		end
		for character in lastPushed do
			if character.Parent == nil then
				lastPushed[character] = nil
			end
		end
	end)
end

return MoverService
