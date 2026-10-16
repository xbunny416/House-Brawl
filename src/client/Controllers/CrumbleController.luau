--!strict
--[[
	CrumbleController — draws crumbling platforms on this client. The server (CrumbleService) only sets attributes:
	while Crumbling, the platform flashes red and shakes; once Falling (no longer solid), it sinks away and fades out
	over Round.Crumble.FallTime. Drawing here keeps it smooth instead of replicating a move every frame. The moves
	are local only; the server removes the platform after FallTime.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local WARNING_COLOR = Color3.fromHex("#FF2A1A")
local FLASH_INTERVAL = 0.25 -- seconds per red flash
local SHAKE_OFFSET = 0.25 -- studs
local SHAKE_SPEED = 14 -- how fast the shake wanders
local SINK_DEPTH = 45 -- studs the platform sinks while it falls

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

local function draw(model: Model, entry: Watch, now: number)
	local crumbling = model:GetAttribute("Crumbling") == true
	local falling = model:GetAttribute("Falling") == true
	if crumbling and entry.warnedAt == nil then
		entry.warnedAt = now
		entry.origin = model:GetPivot()
		entry.highlight = warningHighlight(model)
	end
	if falling and entry.fallingAt == nil then
		entry.fallingAt = now
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
