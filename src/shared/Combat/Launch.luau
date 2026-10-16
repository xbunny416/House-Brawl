--!strict
--[[
	Launch — flings a character for knockback. Whoever simulates the character runs it: the victim's own client for
	player characters (Net "Knockback"), the server for training dummies.
	While launched the Humanoid stops steering (PlatformStand), so it cannot cancel the knockback, and an
	AlignOrientation keeps the body upright and facing the hit (the tumble is an animation, step 2.6). Control comes
	back once hitstun is over and the character has landed, or after Config.Combat.Launch.MaxTime seconds.
]]
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Parent.Config)

local UPRIGHT_NAME = "LaunchUpright"
-- Landed: solid ground within this many studs below the feet while not rising faster than LAND_RISE_SPEED studs/s.
local GROUND_MARGIN = 1
local LAND_RISE_SPEED = 1

local Launch = {}

local launches: { [Model]: number } = {}
local lastId = 0

-- Yaw-only rotation facing back along the launch (towards the attacker), or the current facing.
local function facing(root: BasePart, velocity: Vector3): CFrame
	local back = Vector3.new(-velocity.X, 0, -velocity.Z)
	if back.Magnitude < 1e-3 then
		local look = root.CFrame.LookVector
		back = Vector3.new(look.X, 0, look.Z)
	end
	if back.Magnitude < 1e-3 then
		return CFrame.identity
	end
	return CFrame.lookAt(Vector3.zero, back.Unit)
end

local function keepUpright(root: BasePart, rotation: CFrame): Attachment
	local existing = root:FindFirstChild(UPRIGHT_NAME)
	local attachment: Attachment
	if existing and existing:IsA("Attachment") then
		attachment = existing
	else
		attachment = Instance.new("Attachment")
		attachment.Name = UPRIGHT_NAME
		local align = Instance.new("AlignOrientation")
		align.Mode = Enum.OrientationAlignmentMode.OneAttachment
		align.Attachment0 = attachment
		align.RigidityEnabled = true
		align.Parent = attachment
		attachment.Parent = root
	end
	local align = attachment:FindFirstChildOfClass("AlignOrientation")
	if align then
		align.CFrame = rotation
	end
	return attachment
end

-- Launches `character` with `velocity` (studs/s). It cannot steer for at least `hitstun` seconds.
function Launch.apply(character: Model, velocity: Vector3, hitstun: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end
	lastId += 1
	local id = lastId
	launches[character] = id -- a newer launch takes over from this one

	local upright = keepUpright(root, facing(root, velocity))
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = velocity
	root.AssemblyAngularVelocity = Vector3.zero

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true

	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		if launches[character] ~= id then
			connection:Disconnect()
			return
		end
		local elapsed = os.clock() - started
		local over = elapsed >= Config.Combat.Launch.MaxTime or not root:IsDescendantOf(Workspace)
		if not over then
			if elapsed < hitstun or root.AssemblyLinearVelocity.Y > LAND_RISE_SPEED then
				return
			end
			local reach = humanoid.HipHeight + root.Size.Y / 2 + GROUND_MARGIN
			if Workspace:Raycast(root.Position, Vector3.new(0, -reach, 0), params) == nil then
				return
			end
		end
		connection:Disconnect()
		launches[character] = nil
		upright:Destroy()
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

-- True while `character` is flying from a hit.
function Launch.isLaunched(character: Model): boolean
	return launches[character] ~= nil
end

return Launch
