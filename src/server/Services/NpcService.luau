--!strict
--[[
	NpcService — the lobby's NPCs: the bartender (owner, 2026-10-20: "bartender no animation, just make it look like an
	NPC, not just blocks") and the style coach by the west wall (owner, 2026-10-27: "an interactive NPC for the style
	roll"). The map leaves an invisible Spot in each NPC model (ShopNPC: behind the bar counter; StyleNPC: by the west
	wall); the server builds a real Roblox character there with Players:CreateHumanoidModelFromDescription — the avatar
	of the role's Config.World.<Bartender / Coach>.UserId when one is set (and the web call works), otherwise the built-in
	outfit: a default body coloured part by part plus a few parts added on top. The bartender wears a white shirt, a dark
	vest and trousers, an apron, a bow tie, a bandana and a moustache; the coach a red tracksuit with white stripes, a
	headband and a whistle. They stand still (no animation): the root is anchored, no name or health bar shows, and they
	are not fighters. Each prompt stays on its model's invisible Torso anchor (LobbyPromptController), so it works even
	if the character can't be built.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

-- The built-in outfits' colours (art, not tunables).
local SKIN = Color3.fromHex("#E0B08A")
local SHIRT = Color3.fromHex("#F2EEE6")
local VEST = Color3.fromHex("#2B2D31")
local TROUSERS = Color3.fromHex("#3A3A40")
local SHOES = Color3.fromHex("#2A1E16")
local APRON = Color3.fromHex("#EDE6D6")
local BOW_TIE = Color3.fromHex("#7E2420")
local BANDANA = Color3.fromHex("#C8642D")
local MOUSTACHE = Color3.fromHex("#3B2A1E")
local COACH_SKIN = Color3.fromHex("#8D5A3B")
local TRACKSUIT = Color3.fromHex("#B23A2E")
local TRACK_PANTS = Color3.fromHex("#2B2D31")
local STRIPE = Color3.fromHex("#F2EEE6")
local SNEAKERS = Color3.fromHex("#E8E6E0")
local HEADBAND = Color3.fromHex("#2F8C8C")
local WHISTLE = Color3.fromHex("#B8BCC2")
local DEFAULT_FACE = "rbxasset://textures/face.png"

type Role = {
	Name: string, -- the character's name in the model (BartenderController finds "Bartender")
	UserId: number,
	Colors: { [string]: Color3 }, -- each R15 body part's colour
	Dress: (character: Model) -> (),
}

local NpcService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Npc] {message}`)
	end
end

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

local function bodyPart(character: Model, name: string): BasePart?
	local part = character:FindFirstChild(name)
	return if part and part:IsA("BasePart") then part else nil
end

-- A round band (a cylinder stood upright) around the head at `height` (a fraction of the head's height above its middle).
local function headBand(head: BasePart, name: string, height: number, thickness: number, color: Color3)
	local size = head.Size
	local band = math.max(size.X, size.Z) + 0.1
	attach(
		head,
		name,
		Vector3.new(size.Y * thickness, band, band),
		CFrame.new(0, size.Y * height, 0) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		Enum.Material.Fabric,
		Enum.PartType.Cylinder
	)
	return band
end

-- The bartender's outfit on top of the default body: apron, bow tie, bandana, moustache.
local function dressBartender(character: Model)
	local upper = bodyPart(character, "UpperTorso")
	local lower = bodyPart(character, "LowerTorso")
	local head = bodyPart(character, "Head")
	if upper then
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
	if lower then
		local front = -(lower.Size.Z / 2 + 0.05)
		attach(lower, "Apron", Vector3.new(1.9, 1.9, 0.1), CFrame.new(0, -0.6, front), APRON, Enum.Material.Fabric)
	end
	if head then
		local size = head.Size
		-- Tied at the back.
		local band = headBand(head, "Bandana", 0.34, 0.28, BANDANA)
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

-- The coach's outfit on top of the red tracksuit: a zip line, white stripes down the arms and legs, a headband and a
-- whistle on the chest.
local function dressCoach(character: Model)
	local upper = bodyPart(character, "UpperTorso")
	local head = bodyPart(character, "Head")
	if upper then
		local front = -(upper.Size.Z / 2 + 0.03)
		attach(
			upper,
			"Zip",
			Vector3.new(0.08, upper.Size.Y, 0.06),
			CFrame.new(0, 0, front),
			STRIPE,
			Enum.Material.Fabric
		)
		attach(
			upper,
			"Whistle",
			Vector3.new(0.3, 0.18, 0.18),
			CFrame.new(0.25, upper.Size.Y * 0.1, front - 0.08),
			WHISTLE,
			Enum.Material.Metal,
			Enum.PartType.Cylinder
		)
	end
	-- A stripe down the outer side of each limb (left limbs: −X, right limbs: +X).
	for _, name in
		{
			"LeftUpperArm",
			"LeftLowerArm",
			"RightUpperArm",
			"RightLowerArm",
			"LeftUpperLeg",
			"LeftLowerLeg",
			"RightUpperLeg",
			"RightLowerLeg",
		}
	do
		local part = bodyPart(character, name)
		if part then
			local side = if string.sub(name, 1, 4) == "Left" then -1 else 1
			attach(
				part,
				"Stripe",
				Vector3.new(0.06, part.Size.Y * 0.95, 0.18),
				CFrame.new(side * (part.Size.X / 2 + 0.02), 0, 0),
				STRIPE,
				Enum.Material.Fabric
			)
		end
	end
	if head then
		headBand(head, "Headband", 0.22, 0.16, HEADBAND)
	end
end

local ROLES: { [string]: Role } = {
	ShopNPC = {
		Name = "Bartender",
		UserId = Config.World.Bartender.UserId,
		Colors = {
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
		},
		Dress = dressBartender,
	},
	StyleNPC = {
		Name = "Coach",
		UserId = Config.World.Coach.UserId,
		Colors = {
			Head = COACH_SKIN,
			UpperTorso = TRACKSUIT,
			LowerTorso = TRACK_PANTS,
			LeftUpperArm = TRACKSUIT,
			LeftLowerArm = TRACKSUIT,
			LeftHand = COACH_SKIN,
			RightUpperArm = TRACKSUIT,
			RightLowerArm = TRACKSUIT,
			RightHand = COACH_SKIN,
			LeftUpperLeg = TRACK_PANTS,
			LeftLowerLeg = TRACK_PANTS,
			LeftFoot = SNEAKERS,
			RightUpperLeg = TRACK_PANTS,
			RightLowerLeg = TRACK_PANTS,
			RightFoot = SNEAKERS,
		},
		Dress = dressCoach,
	},
}

-- The look: the configured user's avatar, or the built-in outfit's body colours.
local function description(role: Role): (HumanoidDescription, boolean)
	if role.UserId > 0 then
		local ok, result = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(role.UserId)
		end)
		if ok and result then
			return result, false
		end
		warn(`[Npc] couldn't load avatar {role.UserId} for the {role.Name}: {result}`)
	end
	local colors = role.Colors
	local look = Instance.new("HumanoidDescription")
	look.HeadColor = colors.Head
	look.LeftArmColor = colors.LeftUpperArm
	look.RightArmColor = colors.RightUpperArm
	look.TorsoColor = colors.UpperTorso
	look.LeftLegColor = colors.LeftUpperLeg
	look.RightLegColor = colors.RightUpperLeg
	return look, true
end

-- Colours each body part (hands in skin, shoes their own colour); the BodyColors would put the limb colours back.
local function paint(character: Model, colors: { [string]: Color3 })
	for _, child in character:GetChildren() do
		if child:IsA("BodyColors") then
			child:Destroy()
		elseif child:IsA("BasePart") and colors[child.Name] then
			child.Color = colors[child.Name]
		end
	end
end

-- Builds the role's character on the model's Spot, facing the way the Spot faces.
local function build(model: Instance, role: Role)
	local spot = model:FindFirstChild("Spot")
	if not spot or not spot:IsA("BasePart") or model:FindFirstChild(role.Name) then
		return
	end
	local look, builtIn = description(role)
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(look, Enum.HumanoidRigType.R15)
	end)
	if not ok or not result then
		warn(`[Npc] couldn't build the {role.Name}: {result}`)
		return
	end
	local character = result :: Model
	character.Name = role.Name
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
		paint(character, role.Colors)
		role.Dress(character)
	end
	character.Parent = model
	log(if builtIn then `built the {role.Name}` else `dressed the {role.Name} as user {role.UserId}`)
end

function NpcService.Start(_self: any)
	for tag, role in ROLES do
		for _, model in CollectionService:GetTagged(tag) do
			task.spawn(build, model, role)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(model: Instance)
			task.spawn(build, model, role)
		end)
	end
end

return NpcService
