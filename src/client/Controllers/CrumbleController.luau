--!strict
--[[
	CrumbleController — draws crumbling platforms on this client. The server (CrumbleService) only sets attributes:
	while Crumbling, the platform flashes red, shakes and cracks; once Falling (no longer solid), it breaks away in a
	dust cloud with chunks flying off (Config.Vfx.Crumble; no dust or chunks with Low Graphics), sinks and fades out
	over Round.Crumble.FallTime. Drawing here keeps it smooth instead of replicating a move every frame. The moves
	are local only; the server removes the platform after FallTime.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local SoundController = require(script.Parent:WaitForChild("SoundController"))
local VfxController = require(script.Parent:WaitForChild("VfxController"))

local WARNING_COLOR = Color3.fromHex("#FF2A1A")
local FLASH_INTERVAL = 0.25 -- seconds per red flash
local SHAKE_OFFSET = 0.25 -- studs
local SHAKE_SPEED = 14 -- how fast the shake wanders
local SINK_DEPTH = 45 -- studs the platform sinks while it falls
local DUST_COLOR = Color3.fromHex("#B8AE9C")

type Watch = {
	origin: CFrame,
	warnedAt: number?,
	fallingAt: number?,
	highlight: Highlight?,
}

local CrumbleController = {}

local watched: { [Model]: Watch } = {}

local function track(instance: Instance)
	if instance:IsA("Model") and watched[instance] == nil then
		watched[instance] = { origin = instance:GetPivot(), warnedAt = nil, fallingAt = nil, highlight = nil }
	end
end

local function warningHighlight(model: Model): Highlight
	local highlight = Instance.new("Highlight")
	highlight.FillColor = WARNING_COLOR
	highlight.OutlineColor = WARNING_COLOR
	highlight.FillTransparency = 0.45
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	return highlight
end

-- Dark cracks spread over the platform's top while it warns (part of the platform, so they shake and sink with it).
local function addCracks(model: Model)
	local base = model.PrimaryPart
	if base == nil then
		return
	end
	SoundController.playAt("Rumble", base)
	local half = base.Size / 2
	for _ = 1, Config.Vfx.Crumble.Cracks do
		local crack = VfxController.template("Crack") :: Part -- ReplicatedStorage.Assets.VFX
		crack.Name = "VfxCrack"
		crack.Size = Vector3.new(crack.Size.X, crack.Size.Y, 2 + math.random() * 5)
		local x = (math.random() * 2 - 1) * (half.X - 2)
		local z = (math.random() * 2 - 1) * (half.Z - 2)
		crack.CFrame = base.CFrame * CFrame.new(x, half.Y + 0.03, z) * CFrame.Angles(0, math.random() * math.pi, 0)
		crack.Parent = model
	end
end

-- The platform gives way: a dust cloud and chunks of it breaking off.
local function breakAway(model: Model)
	local base = model.PrimaryPart
	if base == nil then
		return
	end
	local crumble = Config.Vfx.Crumble
	SoundController.playAt("Collapse", base.Position)
	VfxController.burstDust(base.Position, crumble.Dust, DUST_COLOR)
	local half = base.Size / 2
	for _ = 1, crumble.Debris do
		local edge = base.CFrame
			* CFrame.new((math.random() * 2 - 1) * half.X, half.Y, (math.random() * 2 - 1) * half.Z)
		VfxController.burstChunks(edge.Position, 1, base.Color, base.Material)
	end
end

local function draw(model: Model, entry: Watch, now: number)
	local crumbling = model:GetAttribute("Crumbling") == true
	local falling = model:GetAttribute("Falling") == true
	if crumbling and entry.warnedAt == nil then
		entry.warnedAt = now
		entry.origin = model:GetPivot()
		entry.highlight = warningHighlight(model)
		addCracks(model)
	end
	if falling and entry.fallingAt == nil then
		entry.fallingAt = now
		breakAway(model)
	end
	local highlight = entry.highlight

	local fallingAt = entry.fallingAt
	if fallingAt then
		local t = math.clamp((now - fallingAt) / Config.Round.Crumble.FallTime, 0, 1)
		model:PivotTo(entry.origin * CFrame.new(0, -SINK_DEPTH * t * t, 0))
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = t
			end
		end
		if highlight then
			highlight.Enabled = true
			highlight.FillTransparency = 0.45 + 0.55 * t
			highlight.OutlineTransparency = t
		end
		return
	end

	local warnedAt = entry.warnedAt
	if warnedAt then
		local elapsed = now - warnedAt
		if highlight then
			highlight.Enabled = math.floor(elapsed / FLASH_INTERVAL) % 2 == 0
		end
		local wander = elapsed * SHAKE_SPEED
		local dx = math.clamp(math.noise(wander, 0.5) * 2, -1, 1) * SHAKE_OFFSET
		local dz = math.clamp(math.noise(wander, 7.5) * 2, -1, 1) * SHAKE_OFFSET
		model:PivotTo(entry.origin * CFrame.new(dx, 0, dz))
	end
end

function CrumbleController.Start(_self: any)
	CollectionService:GetInstanceAddedSignal("Platform"):Connect(track)
	CollectionService:GetInstanceRemovedSignal("Platform"):Connect(function(instance: Instance)
		if instance:IsA("Model") then
			watched[instance] = nil
		end
	end)
	for _, instance in CollectionService:GetTagged("Platform") do
		track(instance)
	end
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for model, entry in watched do
			if model.Parent == nil then
				watched[model] = nil
			elseif entry.warnedAt ~= nil or model:GetAttribute("Crumbling") == true then
				draw(model, entry, now)
			end
		end
	end)
end

return CrumbleController
