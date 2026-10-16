--!strict
--[[
	Launch — flings a character for knockback. Whoever simulates the character runs it: the victim's own client for
	player characters (Net "Knockback"), the server for training dummies.
	While launched the Humanoid stops steering (PlatformStand), so it cannot cancel the knockback, and an
	AlignOrientation keeps the body upright and facing the hit (the tumble is an animation, step 2.6). Control comes
	back once hitstun is over and the character has landed, after Config.Combat.Launch.MaxTime seconds, or when
	Launch.stop is called (an air dash after hitstun is the way to recover).
]]
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Parent.Config)

local UPRIGHT_NAME = "LaunchUpright"
-- Landed: solid ground within this many studs below the feet while not rising faster than LAND_RISE_SPEED studs/s.
local GROUND_MARGIN = 1
local LAND_RISE_SPEED = 1

type Active = {
	startedAt: number,
	hitstun: number,
	finish: () -> (),
}

local Launch = {}

local launches: { [Model]: Active } = {}

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
	local upright = keepUpright(root, facing(root, velocity))
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = velocity
	root.AssemblyAngularVelocity = Vector3.zero

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true

	local active: Active
	local connection: RBXScriptConnection
	local function finish()
		connection:Disconnect()
		if launches[character] == active then
			launches[character] = nil
		end
		upright:Destroy()
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	active = { startedAt = os.clock(), hitstun = hitstun, finish = finish }
	launches[character] = active -- replaces any earlier launch, whose loop then stops without cleaning up

	connection = RunService.Heartbeat:Connect(function()
		if launches[character] ~= active then
			connection:Disconnect() -- replaced by a newer launch, which owns the cleanup
			return
		end
		local elapsed = os.clock() - active.startedAt
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
		finish()
	end)
end

-- True while `character` is flying from a hit.
function Launch.isLaunched(character: Model): boolean
	return launches[character] ~= nil
end

-- True while `character` is in the hitstun of its current launch (it cannot act).
function Launch.inHitstun(character: Model): boolean
	local active = launches[character]
	return active ~= nil and os.clock() - active.startedAt < active.hitstun
end

-- Ends the launch now and gives control back (e.g. the player air-dashed out of it after hitstun).
function Launch.stop(character: Model)
	local active = launches[character]
	if active then
		active.finish()
	end
end

return Launch
