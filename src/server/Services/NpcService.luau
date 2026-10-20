--!strict
--[[
	NpcService — the lobby's bartender (owner, 2026-10-20: "bartender no animation, just make it look like an NPC, not
	just blocks"). The map leaves an invisible Spot behind the bar counter in the ShopNPC model; the server builds a real
	Roblox character there with Players:CreateHumanoidModelFromDescription — the avatar of Config.World.Bartender.UserId
	when one is set (and the web call works), otherwise the built-in bartender: a default body coloured as a white shirt,
	a dark vest and trousers, skin head and hands and dark shoes, plus an apron, a bow tie, a bandana and a moustache
	added as parts. It stands still (no animation): its root is anchored, no name or health bar shows, and it is not a
	fighter. The Shop prompt stays on the model's invisible Torso anchor (LobbyPromptController), so it works even if the
	character can't be built.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local NPC_TAG = "ShopNPC"

-- The built-in bartender's colours (art, not tunables).
local SKIN = Color3.fromHex("#E0B08A")
local SHIRT = Color3.fromHex("#F2EEE6")
local VEST = Color3.fromHex("#2B2D31")
local TROUSERS = Color3.fromHex("#3A3A40")
local SHOES = Color3.fromHex("#2A1E16")
local APRON = Color3.fromHex("#EDE6D6")
local BOW_TIE = Color3.fromHex("#7E2420")
local BANDANA = Color3.fromHex("#C8642D")
local MOUSTACHE = Color3.fromHex("#3B2A1E")
local DEFAULT_FACE = "rbxasset://textures/face.png"

local NpcService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Npc] {message}`)
	end
end

-- The look: the configured user's avatar, or the built-in bartender's colours.
local function description(): (HumanoidDescription, boolean)
	local userId = Config.World.Bartender.UserId
	if userId > 0 then
		local ok, result = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)
		if ok and result then
			return result, false
		end
		warn(`[Npc] couldn't load avatar {userId} for the bartender: {result}`)
	end
	local look = Instance.new("HumanoidDescription")
	look.HeadColor = SKIN
	look.LeftArmColor = SHIRT
	look.RightArmColor = SHIRT
	look.TorsoColor = VEST
	look.LeftLegColor = TROUSERS
	look.RightLegColor = TROUSERS
	return look, true
end

-- The built-in bartender's colour for each R15 body part (the description colours whole limbs: hands and feet too).
local PART_COLORS: { [string]: Color3 } = {
	Head = SKIN,
	UpperTorso = VEST,
	LowerTorso = VEST,
	LeftUpperArm = SHIRT,
	LeftLowerArm = SHIRT,
	LeftHand = SKIN,
	RightUpperArm = SHIRT,
	RightLowerArm = SHIRT,
	RightHand = SKIN,
	LeftUpperLeg = TROUSERS,
	LeftLowerLeg = TROUSERS,
	LeftFoot = SHOES,
	RightUpperLeg = TROUSERS,
	RightLowerLeg = TROUSERS,
	RightFoot = SHOES,
}

-- A part welded to `body` at `offset` from it (decor: no collisions, no mass).
local function attach(
	body: BasePart,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
)
	local part = Instance.new("Part")
	part.Shape = shape or Enum.PartType.Block
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.CFrame = body.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = part
	weld.Parent = part
	part.Parent = body
end

-- The built-in bartender's outfit on top of the default body.
local function dress(character: Model)
	-- Colour each part (hands in skin, shoes dark); the BodyColors would put the limb colours back over them.
	for _, child in character:GetChildren() do
		if child:IsA("BodyColors") then
			child:Destroy()
		elseif child:IsA("BasePart") and PART_COLORS[child.Name] then
			child.Color = PART_COLORS[child.Name]
		end
	end
	local upper = character:FindFirstChild("UpperTorso")
	local lower = character:FindFirstChild("LowerTorso")
	local head = character:FindFirstChild("Head")
	if upper and upper:IsA("BasePart") then
		local front = -(upper.Size.Z / 2 + 0.05)
		attach(upper, "ApronBib", Vector3.new(1.3, 1.1, 0.1), CFrame.new(0, -0.25, front), APRON, Enum.Material.Fabric)
		attach(
			upper,
			"BowTie",
			Vector3.new(0.7, 0.28, 0.14),
			CFrame.new(0, upper.Size.Y / 2 - 0.2, front - 0.04),
			BOW_TIE,
			Enum.Material.Fabric
		)
	end
	if lower and lower:IsA("BasePart") then
		local front = -(lower.Size.Z / 2 + 0.05)
		attach(lower, "Apron", Vector3.new(1.9, 1.9, 0.1), CFrame.new(0, -0.6, front), APRON, Enum.Material.Fabric)
	end
	if head and head:IsA("BasePart") then
		local size = head.Size
		-- A round band (a cylinder stood upright) over the top of the head, tied at the back.
		local band = math.max(size.X, size.Z) + 0.1
		attach(
			head,
			"Bandana",
			Vector3.new(size.Y * 0.28, band, band),
			CFrame.new(0, size.Y * 0.34, 0) * CFrame.Angles(0, 0, math.pi / 2),
			BANDANA,
			Enum.Material.Fabric,
			Enum.PartType.Cylinder
		)
		attach(
			head,
			"BandanaKnot",
			Vector3.new(0.35, 0.35, 0.35),
			CFrame.new(0, size.Y * 0.3, band / 2 + 0.05),
			BANDANA,
			Enum.Material.Fabric,
			Enum.PartType.Ball
		)
		attach(
			head,
			"Moustache",
			Vector3.new(size.X * 0.45, 0.1, 0.08),
			CFrame.new(0, -size.Y * 0.09, -(size.Z / 2 + 0.02)),
			MOUSTACHE,
			Enum.Material.SmoothPlastic
		)
	end
end

-- Builds the bartender on the ShopNPC model's Spot, facing the way the Spot faces.
local function build(model: Instance)
	local spot = model:FindFirstChild("Spot")
	if not spot or not spot:IsA("BasePart") or model:FindFirstChild("Bartender") then
		return
	end
	local look, builtIn = description()
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(look, Enum.HumanoidRigType.R15)
	end)
	if not ok or not result then
		warn(`[Npc] couldn't build the bartender: {result}`)
		return
	end
	local character = result :: Model
	character.Name = "Bartender"
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		character:Destroy()
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	root.Anchored = true
	local head = character:FindFirstChild("Head")
	if head and not head:FindFirstChildWhichIsA("Decal") then
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Texture = DEFAULT_FACE
		face.Parent = head
	end
	-- Feet on the floor: the root sits HipHeight plus half its own height above the Spot's bottom.
	local floor = spot.Position.Y - spot.Size.Y / 2
	local height = humanoid.HipHeight + root.Size.Y / 2
	character:PivotTo(CFrame.new(spot.Position.X, floor + height, spot.Position.Z) * spot.CFrame.Rotation)
	if builtIn then
		dress(character)
	end
	character.Parent = model
	log(if builtIn then "built the bartender" else `dressed the bartender as user {Config.World.Bartender.UserId}`)
end

function NpcService.Start(_self: any)
	for _, model in CollectionService:GetTagged(NPC_TAG) do
		task.spawn(build, model)
	end
	CollectionService:GetInstanceAddedSignal(NPC_TAG):Connect(function(model: Instance)
		task.spawn(build, model)
	end)
end

return NpcService
