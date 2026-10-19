--!strict
--[[
	Builder — tiny DSL for blockout maps, run by Lune (maps/build.luau) to produce .rbxmx models that Rojo puts into
	the place. Positions are in studs relative to the current origin (see `within`); rotations are degrees.

	`spread(factor, fill)` multiplies the horizontal (X / Z) positions of everything built inside it, keeping sizes:
	decor laid out for a smaller platform spreads over a bigger one without stretching the objects.

	Gameplay markers (spawn points, prop/structure spots) are tagged parts. They are semi-transparent so they can be
	seen and moved in Studio's Edit mode; MapService hides them at runtime.
]]
local roblox = require("@lune/roblox")
local csv = require("../../tools/csv")
local Palette = require("./Palette")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

export type Vec = { number }

export type PartSpec = {
	Name: string?,
	Size: Vec,
	Position: Vec,
	Rotation: Vec?,
	Yaw: number?, -- degrees around Y applied before Rotation (furniture turned as a whole: maps/lib/Furniture)
	Axes: { Right: Vec, Up: Vec }?, -- the part's X and Y directions (instead of Yaw / Rotation): exact slants, e.g. wedges
	Color: string,
	Material: string?,
	Shape: string?, -- "Block" (default), "Cylinder" (axis along X), "Ball", "Wedge"
	Transparency: number?,
	CanCollide: boolean?,
	CastShadow: boolean?,
	Tags: { string }?,
	Attributes: { [string]: any }?,
}

local Builder = {}

local strings = csv.readStrings()
local parentStack: { any } = {}
local originStack: { Vec } = { { 0, 0, 0 } }
local spreadStack: { number } = { 1 }

local function current(): any
	return parentStack[#parentStack]
end

local function origin(): Vec
	return originStack[#originStack]
end

local function color(value: string): any
	local hex = (Palette :: any)[value] or value
	return Color3.fromHex(hex)
end

local function spread(): number
	return spreadStack[#spreadStack]
end

local function cframe(position: Vec, rotation: Vec?, yaw: number?, axes: { Right: Vec, Up: Vec }?): any
	local o, s = origin(), spread()
	local at = Vector3.new(position[1] * s + o[1], position[2] + o[2], position[3] * s + o[3])
	if axes then
		local right, up = axes.Right, axes.Up
		return CFrame.fromMatrix(at, Vector3.new(right[1], right[2], right[3]), Vector3.new(up[1], up[2], up[3]))
	end
	local cf = CFrame.new(at.X, at.Y, at.Z)
	if yaw then
		cf = cf * CFrame.Angles(0, math.rad(yaw), 0)
	end
	if rotation then
		cf = cf * CFrame.Angles(math.rad(rotation[1]), math.rad(rotation[2]), math.rad(rotation[3]))
	end
	return cf
end

local function applyCommon(instance: any, spec: PartSpec)
	instance.Name = spec.Name or "Part"
	instance.Anchored = true
	instance.Size = Vector3.new(spec.Size[1], spec.Size[2], spec.Size[3])
	instance.CFrame = cframe(spec.Position, spec.Rotation, spec.Yaw, spec.Axes)
	instance.Color = color(spec.Color)
	instance.Material = (Enum.Material :: any)[spec.Material or "SmoothPlastic"]
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	if spec.Transparency then
		instance.Transparency = spec.Transparency
	end
	if spec.CanCollide ~= nil then
		instance.CanCollide = spec.CanCollide
	end
	-- Small parts never cast shadows (performance on low-end phones).
	local volume = spec.Size[1] * spec.Size[2] * spec.Size[3]
	if spec.CastShadow ~= nil then
		instance.CastShadow = spec.CastShadow
	elseif volume < 64 then
		instance.CastShadow = false
	end
	for _, tag in spec.Tags or {} do
		instance:AddTag(tag)
	end
	for key, value in spec.Attributes or {} do
		instance:SetAttribute(key, value)
	end
	instance.Parent = current()
end

-- Facing names map to the yaw that points a part's Front (-Z) face that way.
local FACING: { [string]: number } = { South = 0, North = 180, East = -90, West = 90 }

function Builder.yaw(facing: string): Vec
	return { 0, assert(FACING[facing], `unknown facing {facing}`), 0 }
end

-- Creates a Model under the current parent and runs `fill` with it as the parent.
function Builder.model(name: string, fill: (() -> ())?, attributes: { [string]: any }?): any
	local model = Instance.new("Model")
	model.Name = name
	for key, value in attributes or {} do
		model:SetAttribute(key, value)
	end
	model.Parent = current()
	if fill then
		table.insert(parentStack, model)
		fill()
		table.remove(parentStack)
	end
	return model
end

function Builder.folder(name: string, fill: () -> ()): any
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = current()
	table.insert(parentStack, folder)
	fill()
	table.remove(parentStack)
	return folder
end

-- Runs `fill` with every horizontal position (X / Z, from the current origin) multiplied by `factor`; sizes stay.
function Builder.spread(factor: number, fill: () -> ())
	table.insert(spreadStack, spread() * factor)
	fill()
	table.remove(spreadStack)
end

-- Runs `fill` with positions measured from `offset` (added to the current origin).
function Builder.within(offset: Vec, fill: () -> ())
	local o, s = origin(), spread()
	table.insert(originStack, { o[1] + offset[1] * s, o[2] + offset[2], o[3] + offset[3] * s })
	fill()
	table.remove(originStack)
end

function Builder.part(spec: PartSpec): any
	local shape = spec.Shape or "Block"
	local instance
	if shape == "Wedge" then
		instance = Instance.new("WedgePart")
	else
		instance = Instance.new("Part")
		instance.Shape = (Enum.PartType :: any)[shape]
	end
	applyCommon(instance, spec)
	return instance
end

-- A Seat players can sit on, built like a part (Shape works too). Tagged LobbySeat: a client prompt asks the server
-- to sit you down (SeatService). CanTouch is off, so walking into it never sits you down by accident.
function Builder.seat(spec: PartSpec): any
	local seat = Instance.new("Seat")
	seat.Shape = (Enum.PartType :: any)[spec.Shape or "Block"]
	applyCommon(seat, spec)
	seat.CanTouch = false
	seat:AddTag("LobbySeat")
	return seat
end

-- A SpawnLocation (neutral, no spawn forcefield) built like a part.
function Builder.spawnLocation(spec: PartSpec): any
	local spawn = Instance.new("SpawnLocation")
	applyCommon(spawn, spec)
	spawn.Neutral = true
	spawn.Duration = 0
	return spawn
end

-- A box whose top surface sits at Position.Y (handy for floors and platforms).
function Builder.slab(spec: PartSpec): any
	local position = { spec.Position[1], spec.Position[2] - spec.Size[2] / 2, spec.Position[3] }
	local copy = table.clone(spec) :: any
	copy.Position = position
	return Builder.part(copy)
end

-- An invisible-at-runtime gameplay marker standing on the surface at `position`.
function Builder.marker(tag: string, name: string, position: Vec, attributes: { [string]: any }?, facing: Vec?): any
	return Builder.part({
		Name = name,
		Size = { 2, 0.4, 2 },
		Position = { position[1], position[2] + 0.2, position[3] },
		Rotation = facing,
		Color = "NeonTeal",
		Material = "Neon",
		Transparency = 0.5,
		CanCollide = false,
		CastShadow = false,
		Tags = { tag, "Marker" },
		Attributes = attributes,
	})
end

-- Looks up player-facing text in GameStrings.csv (no text is hard-coded in layouts).
function Builder.text(key: string): string
	return assert(strings[key], `GameStrings.csv has no key "{key}"`)
end

-- A sign: a board part with a SurfaceGui label on its Front face. Text comes from a localization key.
function Builder.sign(spec: PartSpec & {
	Key: string,
	TextColor: string,
	Glow: boolean?,
}): any
	local board = Builder.part(spec)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = if spec.Glow then 0 else 1
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = roblox.UDim2.fromScale(1, 1)
	label.FontFace = roblox.Font.fromName("Bangers")
	label.TextScaled = true
	label.TextColor3 = color(spec.TextColor)
	label.Text = Builder.text(spec.Key)
	label:SetAttribute("LocKey", spec.Key)
	label.Parent = gui
	return board
end

-- A point light. `shadows`: it casts soft shadows (Future lighting) — only the few main lamps, it costs frame time.
function Builder.light(parentPart: any, lightColor: string, range: number, brightness: number, shadows: boolean?): any
	local light = Instance.new("PointLight")
	light.Color = color(lightColor)
	light.Range = range
	light.Brightness = brightness
	light.Shadows = shadows == true
	if shadows then
		light:AddTag("ShadowLight") -- Low Graphics turns these shadows off (VfxController)
	end
	light.Parent = parentPart
	return light
end

-- Starts a new top-level model (returned) for a map file.
function Builder.root(name: string, fill: () -> (), attributes: { [string]: any }?): any
	parentStack = {}
	originStack = { { 0, 0, 0 } }
	spreadStack = { 1 }
	local root = Instance.new("Model")
	root.Name = name
	for key, value in attributes or {} do
		root:SetAttribute(key, value)
	end
	table.insert(parentStack, root)
	fill()
	table.remove(parentStack)
	return root
end

Builder.roblox = roblox
Builder.Enum = Enum

return Builder
