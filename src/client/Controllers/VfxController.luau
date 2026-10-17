--!strict
--[[
	VfxController — the visual effects (bible §4.3, numbers in Config.Vfx), drawn on this client only:
	  * Hit sparks + an impact flash on every landed hit (CombatHit), in the victim's Percent color, more sparks the
	    higher the Percent; a smoke trail behind fighters launched above TrailPercent, for the hitstun.
	  * Server events (Net "Effect", Server/Visuals/Effects): the comic POW starburst on a KO (K.O.! around the scorer
	    for ring-outs) with a screen-edge flash (red: you were knocked out, gold: you scored); KO-effect cosmetics; the
	    retro cartoon explosion (fireball, ring shockwave, smoke, debris); a structure breaking into chunks of its
	    own color and material; the blue Perfect Dodge flash (and a blue edge flash for the dodger).
	  * A dash streak behind every dash (unless a dash-trail cosmetic already draws one).
	Low Graphics (Settings): no particles, flying debris, post-effects (Bloom, color grading) or shadows; the flashes,
	the starburst and the edge flash stay. Crumbling-platform effects live in CrumbleController.
]]
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local VfxRules = require(Client:WaitForChild("Lib"):WaitForChild("VfxRules"))
local DashController = require(script.Parent:WaitForChild("DashController"))
local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local STREAK_NAME = "VfxDashStreak"
local SMOKE_NAME = "VfxLaunchSmoke"
local COSMETIC_TRAIL = "CosmeticTrail"
local TEXT_FONT = Enum.Font.Bangers

local VfxController = {}

local player = Players.LocalPlayer
local folder: Folder
local edgeGui: ScreenGui
local edges: { Frame } = {}

local function lowGraphics(): boolean
	return SettingsController.get("LowGraphics") == true
end

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

local function rootOf(model: Instance?): BasePart?
	local root = model and model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- An invisible anchored part to hang effects on, removed after `lifetime`.
local function anchorAt(cframe: CFrame, lifetime: number): Part
	local part = Instance.new("Part")
	part.Name = "Vfx"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = cframe
	part.Parent = folder
	Debris:AddItem(part, lifetime)
	return part
end

-- A glowing ball that grows from `fromSize` to `toSize` and fades out over `time`.
local function flashBall(position: Vector3, color: Color3, fromSize: number, toSize: number, time: number)
	local ball = anchorAt(CFrame.new(position), time + 0.1)
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Size = Vector3.one * fromSize
	ball.Transparency = 0.1
	local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ball, info, { Size = Vector3.one * toSize, Transparency = 1 }):Play()
end

-- A one-off burst of particles from `cframe` (emitted along its front, −Z), unless Low Graphics.
local function particles(
	cframe: CFrame,
	count: number,
	color: ColorSequence,
	texture: string,
	speed: NumberRange,
	lifetime: NumberRange,
	size: NumberSequence,
	spread: number
)
	if count <= 0 or lowGraphics() then
		return
	end
	local anchor = anchorAt(cframe, lifetime.Max + 0.2)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture
	emitter.Color = color
	emitter.Speed = speed
	emitter.Lifetime = lifetime
	emitter.Size = size
	emitter.SpreadAngle = Vector2.new(spread, spread)
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Drag = 4
	emitter.LightEmission = if texture == SPARK_TEXTURE then 1 else 0
	emitter.Transparency = NumberSequence.new(0, 1)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(count)
end

-- Text that pops up at `position` and floats up while it fades (BillboardGui, readable through walls).
local function floatingText(position: Vector3, text: string, color: Color3, size: number, time: number)
	local anchor = anchorAt(CFrame.new(position), time + 0.1)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(size, size * 0.4)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = TEXT_FONT
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
end

---------------------------------------------------------------------------------------------------------------------
-- Screen-edge flash
---------------------------------------------------------------------------------------------------------------------

local function buildEdges()
	edgeGui = Instance.new("ScreenGui")
	edgeGui.Name = "EdgeFlash"
	edgeGui.IgnoreGuiInset = true
	edgeGui.ResetOnSpawn = false
	edgeGui.DisplayOrder = 20
	edgeGui.Parent = player:WaitForChild("PlayerGui")
	-- Each edge fades from solid at the screen border to clear toward the middle.
	for _, spec in
		{
			{ size = UDim2.fromScale(1, 0.22), position = UDim2.fromScale(0, 0), rotation = 90 },
			{ size = UDim2.fromScale(1, 0.22), position = UDim2.fromScale(0, 0.78), rotation = -90 },
			{ size = UDim2.fromScale(0.16, 1), position = UDim2.fromScale(0, 0), rotation = 0 },
			{ size = UDim2.fromScale(0.16, 1), position = UDim2.fromScale(0.84, 0), rotation = 180 },
		}
	do
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Size = spec.size
		frame.Position = spec.position
		frame.BackgroundTransparency = 1
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = spec.rotation
		gradient.Transparency = NumberSequence.new(0, 1)
		gradient.Parent = frame
		frame.Parent = edgeGui
		table.insert(edges, frame)
	end
end

local function edgeFlash(color: Color3, time: number)
	local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, frame in edges do
		frame.BackgroundColor3 = color
		frame.BackgroundTransparency = 1 - Config.Vfx.EdgeFlash.Opacity
		TweenService:Create(frame, info, { BackgroundTransparency = 1 }):Play()
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Hits
---------------------------------------------------------------------------------------------------------------------

local function onCombatHit(
	attacker: Model?,
	victim: Model?,
	_attack: string,
	heavy: boolean,
	trail: boolean,
	hitstun: number?
)
	local victimRoot = rootOf(victim)
	if victim == nil or victimRoot == nil then
		return
	end
	local attackerRoot = rootOf(attacker)
	local away = if attackerRoot then (victimRoot.Position - attackerRoot.Position) * Vector3.new(1, 0, 1) else nil
	local direction = if away and away.Magnitude > 0.01 then away.Unit else victimRoot.CFrame.LookVector
	local impact = victimRoot.Position - direction * 1.2 + Vector3.new(0, 0.5, 0)

	local percent = victim:GetAttribute("Percent")
	local rgb = HudFormat.percentColor(if type(percent) == "number" then percent else 0)
	local color = Color3.new(rgb.R, rgb.G, rgb.B)
	local flash = Config.Vfx.ImpactFlash
	flashBall(impact, color, 0.6, if heavy then flash.HeavySize else flash.Size, flash.Time)

	local sparks = Config.Vfx.Sparks
	local count = VfxRules.sparkCount(if type(percent) == "number" then percent else 0, sparks, lowGraphics())
	particles(
		CFrame.lookAt(impact, impact + direction + Vector3.new(0, 0.3, 0)),
		if heavy then count * 2 else count,
		ColorSequence.new(color),
		SPARK_TEXTURE,
		NumberRange.new(sparks.Speed[1], sparks.Speed[2]),
		NumberRange.new(sparks.Lifetime * 0.5, sparks.Lifetime),
		NumberSequence.new(0.7, 0),
		60
	)

	-- Launched hard: a smoke trail for the length of the hitstun.
	if trail and not lowGraphics() then
		local old = victimRoot:FindFirstChild(SMOKE_NAME)
		if old then
			old:Destroy()
		end
		local smoke = Config.Vfx.LaunchSmoke
		local attachment = Instance.new("Attachment")
		attachment.Name = SMOKE_NAME
		attachment.Parent = victimRoot
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = SMOKE_TEXTURE
		emitter.Color = ColorSequence.new(hex(smoke.Color))
		emitter.Rate = smoke.Rate
		emitter.Lifetime = NumberRange.new(smoke.Lifetime * 0.6, smoke.Lifetime)
		emitter.Speed = NumberRange.new(0.5, 2)
		emitter.Size = NumberSequence.new(1.2, 3.5)
		emitter.Transparency = NumberSequence.new(0.3, 1)
		emitter.Parent = attachment
		local stun = if type(hitstun) == "number" then hitstun else 0.5
		task.delay(stun, function()
			emitter.Enabled = false
		end)
		Debris:AddItem(attachment, stun + smoke.Lifetime + 0.2)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Server events
---------------------------------------------------------------------------------------------------------------------

-- The comic starburst: two square bursts turned 45° apart behind big outlined text, popping in and fading out.
local function starburst(position: Vector3, text: string)
	local ko = Config.Vfx.KO
	local anchor = anchorAt(CFrame.new(position + Vector3.new(0, 3, 0)), ko.BurstTime + 0.1)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(ko.BurstSize, ko.BurstSize)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.Rotation = math.random(-15, 15)
	holder.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = holder
	local fading: { GuiObject } = {}
	for _, rotation in { 0, 45 } do
		local star = Instance.new("Frame")
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
		table.insert(fading, star)
	end
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.8, 0.45)
	label.Font = TEXT_FONT
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = hex(ko.TextColor)
	label.TextStrokeTransparency = 0
	label.ZIndex = 2
	label.Parent = holder
	local pop = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(scale, pop, { Scale = 1 }):Play()
	task.delay(ko.BurstTime * 0.55, function()
		local fade = TweenInfo.new(ko.BurstTime * 0.45)
		for _, star in fading do
			TweenService:Create(star, fade, { BackgroundTransparency = 1 }):Play()
			local outline = star:FindFirstChildOfClass("UIStroke")
			if outline then
				TweenService:Create(outline, fade, { Transparency = 1 }):Play()
			end
		end
		TweenService:Create(label, fade, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(scale, fade, { Scale = 1.3 }):Play()
	end)
end

local function onKO(position: Vector3, data: { [string]: any })
	local text = Localization.format(if data.Cause == "Fall" then "Vfx.KO" else "Vfx.Pow")
	starburst(position, text)
	local mine = player.Character
	local flash = VfxRules.koFlash(mine ~= nil and data.Victim == mine, mine ~= nil and data.Killer == mine)
	if flash then
		edgeFlash(hex((Config.Vfx.EdgeFlash :: any)[flash]), Config.Vfx.KO.FlashTime)
	end
end

local function onKOBurst(position: Vector3, data: { [string]: any })
	local colors = data.Colors
	if type(colors) ~= "table" or #colors == 0 then
		return
	end
	local keypoints: { ColorSequenceKeypoint } = {}
	for index, value in colors do
		local time = if #colors > 1 then (index - 1) / (#colors - 1) else 0
		table.insert(keypoints, ColorSequenceKeypoint.new(time, hex(value)))
	end
	if #keypoints == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, hex(colors[1])))
	end
	particles(
		CFrame.lookAt(position, position + Vector3.yAxis),
		Config.Cosmetics.KOEffectParticles,
		ColorSequence.new(keypoints),
		SPARK_TEXTURE,
		NumberRange.new(15, 30),
		NumberRange.new(0.5, 1),
		NumberSequence.new(0.6, 0),
		180
	)
end

-- Small chunks that fly out from `position` and tumble down (local physics), unless Low Graphics allows only `low`.
local function chunks(
	position: Vector3,
	count: number,
	color: Color3,
	material: Enum.Material,
	size: number,
	time: number
)
	for _ = 1, count do
		local chunk = Instance.new("Part")
		chunk.Name = "VfxChunk"
		chunk.CanCollide = false
		chunk.CanQuery = false
		chunk.CanTouch = false
		chunk.CastShadow = false
		chunk.Color = color
		chunk.Material = material
		local s = size * (0.5 + math.random())
		chunk.Size = Vector3.new(s, s * 0.7, s * 0.9)
		chunk.CFrame = CFrame.new(position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		chunk.Parent = folder
		local angle = math.random() * math.pi * 2
		chunk.AssemblyLinearVelocity = Vector3.new(math.cos(angle) * 18, 22 + math.random() * 14, math.sin(angle) * 18)
		chunk.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		Debris:AddItem(chunk, time)
	end
end

local function onExplosion(position: Vector3, data: { [string]: any })
	local radius = if type(data.Radius) == "number" then data.Radius else 8
	local explosion = Config.Vfx.Explosion
	flashBall(position, hex("#FFE45C"), 1, radius, explosion.Time * 0.6)
	flashBall(position, hex("#FF8A3D"), 2, radius * 1.9, explosion.Time)
	-- The ring shockwave: a flat disc racing outward along the ground.
	local ring = anchorAt(CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2), explosion.RingTime + 0.1)
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = hex("#FFF1D6")
	ring.Size = Vector3.new(0.25, 2, 2)
	ring.Transparency = 0.2
	local info = TweenInfo.new(explosion.RingTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = Vector3.new(0.25, radius * 2.6, radius * 2.6), Transparency = 1 }):Play()
	local light = Instance.new("PointLight")
	light.Color = hex("#FF8A3D")
	light.Range = radius * 2
	light.Brightness = 4
	light.Parent = ring
	TweenService:Create(light, info, { Brightness = 0 }):Play()
	particles(
		CFrame.lookAt(position, position + Vector3.yAxis),
		explosion.Smoke,
		ColorSequence.new(hex("#6E6A64"), hex("#3A3632")),
		SMOKE_TEXTURE,
		NumberRange.new(8, 20),
		NumberRange.new(1, 1.6),
		NumberSequence.new(3, 8),
		180
	)
	if not lowGraphics() then
		chunks(position, explosion.Debris, hex("#3A3632"), Enum.Material.CorrodedMetal, 0.8, 2)
	end
end

local function onBreak(position: Vector3, data: { [string]: any })
	local brk = Config.Vfx.Break
	local size = if typeof(data.Size) == "Vector3" then data.Size else Vector3.new(4, 4, 4)
	local color = if typeof(data.Color) == "Color3" then data.Color else Color3.new(0.5, 0.5, 0.5)
	local ok, material = pcall(function()
		return (Enum.Material :: any)[data.Material]
	end)
	local chunkMaterial: Enum.Material = if ok and material then material else Enum.Material.SmoothPlastic
	local chunkSize = math.max(size.X, size.Y, size.Z) * 0.18
	chunks(
		position,
		if lowGraphics() then brk.LowChunks else brk.Chunks,
		color,
		chunkMaterial,
		chunkSize,
		brk.ChunkTime
	)
	particles(
		CFrame.lookAt(position, position + Vector3.yAxis),
		brk.Dust,
		ColorSequence.new(color:Lerp(Color3.new(0.8, 0.78, 0.72), 0.6)),
		SMOKE_TEXTURE,
		NumberRange.new(4, 12),
		NumberRange.new(0.6, 1.2),
		NumberSequence.new(2, 5),
		180
	)
end

local function onPerfectDodge(position: Vector3, data: { [string]: any })
	local dodge = Config.Vfx.PerfectDodge
	local color = hex(dodge.Color)
	flashBall(position, color, 2, 9, dodge.Time)
	floatingText(position + Vector3.new(0, 3.5, 0), Localization.format("Vfx.Perfect"), color, 6, 0.9)
	if data.Character ~= nil and data.Character == player.Character then
		edgeFlash(hex(Config.Vfx.EdgeFlash.PerfectDodge), dodge.Time)
	end
end

-- Shared with CrumbleController: flying chunks (none with Low Graphics) and a dust puff (particles).
function VfxController.burstChunks(position: Vector3, count: number, color: Color3, material: Enum.Material)
	if not lowGraphics() then
		chunks(position, count, color, material, 1.2, Config.Vfx.Crumble.DebrisTime)
	end
end

function VfxController.burstDust(position: Vector3, count: number, color: Color3)
	particles(
		CFrame.lookAt(position, position + Vector3.yAxis),
		count,
		ColorSequence.new(color),
		SMOKE_TEXTURE,
		NumberRange.new(4, 12),
		NumberRange.new(0.8, 1.5),
		NumberSequence.new(3, 7),
		180
	)
end

local handlers: { [string]: (Vector3, { [string]: any }) -> () } = {
	KO = onKO,
	KOBurst = onKOBurst,
	Explosion = onExplosion,
	Break = onBreak,
	PerfectDodge = onPerfectDodge,
}

---------------------------------------------------------------------------------------------------------------------
-- Dash streak
---------------------------------------------------------------------------------------------------------------------

local function dashStreak(character: Model?)
	local root = rootOf(character)
	if root == nil or root:FindFirstChild(COSMETIC_TRAIL) then
		return -- a dash-trail cosmetic draws its own
	end
	local trail = root:FindFirstChild(STREAK_NAME)
	if trail == nil then
		local top = Instance.new("Attachment")
		top.Name = `{STREAK_NAME}Top`
		top.Position = Vector3.new(0, 1.2, 0)
		top.Parent = root
		local bottom = Instance.new("Attachment")
		bottom.Name = `{STREAK_NAME}Bottom`
		bottom.Position = Vector3.new(0, -1.2, 0)
		bottom.Parent = root
		local streak = Instance.new("Trail")
		streak.Name = STREAK_NAME
		streak.Attachment0 = top
		streak.Attachment1 = bottom
		streak.Color = ColorSequence.new(hex(Config.Vfx.Dash.Color))
		streak.Transparency = NumberSequence.new(0.4, 1)
		streak.Lifetime = Config.Vfx.Dash.StreakLifetime
		streak.LightEmission = 0.4
		streak.Enabled = false
		streak.Parent = root
		trail = streak
	end
	if trail and trail:IsA("Trail") then
		trail.Enabled = true
		task.delay(Config.Combat.Dash.Duration, function()
			trail.Enabled = false
		end)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Low Graphics
---------------------------------------------------------------------------------------------------------------------

local function applyGraphics()
	local low = lowGraphics()
	Lighting.GlobalShadows = not low
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("PostEffect") then
			effect.Enabled = not low
		end
	end
end

function VfxController.Start(_self: any)
	folder = Instance.new("Folder")
	folder.Name = "Vfx"
	folder.Parent = Workspace
	buildEdges()

	Net.on("CombatHit", onCombatHit)
	Net.on("Effect", function(kind: string, position: Vector3, data: { [string]: any }?)
		local handler = handlers[kind]
		if handler and typeof(position) == "Vector3" then
			handler(position, if type(data) == "table" then data else {})
		end
	end)
	Net.on("Animate", function(character: Model?, clip: string?)
		if clip == "Dash" and typeof(character) == "Instance" and character:IsA("Model") then
			dashStreak(character)
		end
	end)
	DashController.Dashed:Connect(function()
		dashStreak(player.Character)
	end)

	applyGraphics()
	SettingsController.Changed:Connect(function(key: string)
		if key == "LowGraphics" then
			applyGraphics()
		end
	end)
	-- Lighting effects the server adds later (MapService creates them on first use).
	Lighting.ChildAdded:Connect(function(child: Instance)
		if child:IsA("PostEffect") then
			child.Enabled = not lowGraphics()
		end
	end)
end

return VfxController
