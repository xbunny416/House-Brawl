--!strict
--[[
	The VFX templates (ReplicatedStorage.Assets.VFX), cloned by Controllers/VfxController, CrumbleController and
	Services/CosmeticService (owner's project rules, 2026-10-30: "clone templates from ReplicatedStorage.Assets.VFX,
	call :Emit(count), and tween scale/transparency"). Timings, counts and colours that are tunables come from
	Config.Vfx / Config.Cosmetics; the rest of each look lives here.

	  Bursts (an Attachment holding a ParticleEmitter "Emitter" with Rate 0; clone it onto an Anchor and :Emit):
	    Sparks, KOBurst, ExplosionSmoke, BreakDust, CrumbleDust
	  Trails (an Attachment holding a running ParticleEmitter "Emitter"): LaunchSmoke
	  Parts to tween: Anchor (invisible, effects hang on it), FlashBall, Shockwave (with a PointLight), Chunk, Crack
	  Streaks (a Folder of attachments Top / Bottom and a Trail "Trail" between them, moved onto a root part):
	    DashStreak, CosmeticTrail
	  Billboards: KOStarburst (Holder > Scale, Star1, Star2, Text), FloatingText (Text)
]]
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Color3 = roblox.Color3
local ColorSequence = roblox.ColorSequence
local NumberSequence = roblox.NumberSequence
local NumberRange = roblox.NumberRange
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local UDim2 = roblox.UDim2
local Enum = roblox.Enum

local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local TEXT_FONT = "Bangers"

local Vfx = {}

local function hex(value: string): any
	return Color3.fromHex(value)
end

-- An Attachment named `name` holding a ParticleEmitter "Emitter" with these settings.
local function emitter(parent: any, name: string, settings: { [string]: any }): any
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "Emitter"
	particles.EmissionDirection = Enum.NormalId.Front
	particles.Drag = 4
	particles.Transparency = NumberSequence.new(0, 1)
	particles.Rate = 0
	for key, value in settings do
		(particles :: any)[key] = value
	end
	particles.Parent = attachment
	attachment.Parent = parent
	return attachment
end

-- A part that only shows: anchored, never collides, touched or hit, no shadow.
local function effectPart(parent: any, name: string, shape: string?): any
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = (Enum.PartType :: any)[shape]
	end
	part.Parent = parent
	return part
end

-- Two attachments `half` above and below the root and a Trail between them, in a Folder (move them onto a root part).
local function streak(parent: any, name: string, half: number, settings: { [string]: any }): any
	local folder = Instance.new("Folder")
	folder.Name = name
	local top = Instance.new("Attachment")
	top.Name = "Top"
	top.Position = Vector3.new(0, half, 0)
	top.Parent = folder
	local bottom = Instance.new("Attachment")
	bottom.Name = "Bottom"
	bottom.Position = Vector3.new(0, -half, 0)
	bottom.Parent = folder
	local trail = Instance.new("Trail")
	trail.Name = "Trail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Enabled = false
	for key, value in settings do
		(trail :: any)[key] = value
	end
	trail.Parent = folder
	folder.Parent = parent
	return folder
end

local function label(parent: any, name: string): any
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.FontFace = roblox.Font.fromName(TEXT_FONT)
	text.TextScaled = true
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.TextStrokeTransparency = 0
	text.Parent = parent
	return text
end

-- Builds the VFX folder from `Config`.
function Vfx.build(Config: any): any
	local folder = Instance.new("Folder")
	folder.Name = "VFX"
	local vfx = Config.Vfx

	-- Bursts.
	local sparks = vfx.Sparks
	emitter(folder, "Sparks", {
		Texture = SPARK_TEXTURE,
		LightEmission = 1,
		Speed = NumberRange.new(sparks.Speed[1], sparks.Speed[2]),
		Lifetime = NumberRange.new(sparks.Lifetime * 0.5, sparks.Lifetime),
		Size = NumberSequence.new(0.7, 0),
		SpreadAngle = Vector2.new(60, 60),
	})
	emitter(folder, "KOBurst", {
		Texture = SPARK_TEXTURE,
		LightEmission = 1,
		Speed = NumberRange.new(15, 30),
		Lifetime = NumberRange.new(0.5, 1),
		Size = NumberSequence.new(0.6, 0),
		SpreadAngle = Vector2.new(180, 180),
	})
	emitter(folder, "ExplosionSmoke", {
		Texture = SMOKE_TEXTURE,
		Color = ColorSequence.new(hex("#6E6A64"), hex("#3A3632")),
		Speed = NumberRange.new(8, 20),
		Lifetime = NumberRange.new(1, 1.6),
		Size = NumberSequence.new(3, 8),
		SpreadAngle = Vector2.new(180, 180),
	})
	emitter(folder, "BreakDust", {
		Texture = SMOKE_TEXTURE,
		Speed = NumberRange.new(4, 12),
		Lifetime = NumberRange.new(0.6, 1.2),
		Size = NumberSequence.new(2, 5),
		SpreadAngle = Vector2.new(180, 180),
	})
	emitter(folder, "CrumbleDust", {
		Texture = SMOKE_TEXTURE,
		Speed = NumberRange.new(4, 12),
		Lifetime = NumberRange.new(0.8, 1.5),
		Size = NumberSequence.new(3, 7),
		SpreadAngle = Vector2.new(180, 180),
	})

	-- The smoke trail behind a launched fighter (it runs until turned off).
	local smoke = vfx.LaunchSmoke
	emitter(folder, "LaunchSmoke", {
		Texture = SMOKE_TEXTURE,
		Color = ColorSequence.new(hex(smoke.Color)),
		Rate = smoke.Rate,
		Lifetime = NumberRange.new(smoke.Lifetime * 0.6, smoke.Lifetime),
		Speed = NumberRange.new(0.5, 2),
		Size = NumberSequence.new(1.2, 3.5),
		Transparency = NumberSequence.new(0.3, 1),
		Drag = 0,
	})

	-- Parts.
	local anchor = effectPart(folder, "Anchor")
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	local ball = effectPart(folder, "FlashBall", "Ball")
	ball.Material = Enum.Material.Neon
	ball.Size = Vector3.new(1, 1, 1)
	ball.Transparency = 0.1
	local ring = effectPart(folder, "Shockwave", "Cylinder")
	ring.Material = Enum.Material.Neon
	ring.Color = hex("#FFF1D6")
	ring.Size = Vector3.new(0.25, 2, 2)
	ring.Transparency = 0.2
	local light = Instance.new("PointLight")
	light.Name = "Light"
	light.Color = hex("#FF8A3D")
	light.Brightness = 4
	light.Range = 16
	light.Parent = ring
	local chunk = effectPart(folder, "Chunk")
	chunk.Anchored = false
	chunk.Size = Vector3.new(1, 0.7, 0.9)
	local crack = effectPart(folder, "Crack")
	crack.Color = hex("#2A2420")
	crack.Material = Enum.Material.SmoothPlastic
	crack.Size = Vector3.new(0.18, 0.06, 4)

	-- Streaks.
	streak(folder, "DashStreak", 1.2, {
		Color = ColorSequence.new(hex(vfx.Dash.Color)),
		Transparency = NumberSequence.new(0.4, 1),
		Lifetime = vfx.Dash.StreakLifetime,
		LightEmission = 0.4,
	})
	streak(folder, "CosmeticTrail", 1, {
		Transparency = NumberSequence.new(0.2, 1),
		Lifetime = Config.Cosmetics.TrailLifetime,
		LightEmission = 0.5,
	})

	-- The comic KO starburst: two squares turned 45° apart behind big outlined text.
	local ko = vfx.KO
	local burst = Instance.new("BillboardGui")
	burst.Name = "KOStarburst"
	burst.Size = UDim2.fromScale(ko.BurstSize, ko.BurstSize)
	burst.AlwaysOnTop = true
	burst.LightInfluence = 0
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = burst
	local scale = Instance.new("UIScale")
	scale.Name = "Scale"
	scale.Scale = 0.2
	scale.Parent = holder
	for index, rotation in { 0, 45 } do
		local star = Instance.new("Frame")
		star.Name = `Star{index}`
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.Position = UDim2.fromScale(0.5, 0.5)
		star.Size = UDim2.fromScale(0.62, 0.62)
		star.Rotation = rotation
		star.BackgroundColor3 = hex(ko.StarColor)
		star.Parent = holder
		local outline = Instance.new("UIStroke")
		outline.Thickness = 3
		outline.Color = Color3.new(0, 0, 0)
		outline.Parent = star
	end
	local text = label(holder, "Text")
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.5)
	text.Size = UDim2.fromScale(0.8, 0.45)
	text.TextColor3 = hex(ko.TextColor)
	text.ZIndex = 2
	burst.Parent = folder

	-- Text that pops up and floats away (the Perfect Dodge's PERFECT!).
	local floating = Instance.new("BillboardGui")
	floating.Name = "FloatingText"
	floating.AlwaysOnTop = true
	floating.LightInfluence = 0
	local floatingLabel = label(floating, "Text")
	floatingLabel.Size = UDim2.fromScale(1, 1)
	floating.Parent = folder

	return folder
end

return Vfx
