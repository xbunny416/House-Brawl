--!strict
--[[
	The model templates (ReplicatedStorage.Assets.Models), cloned by the server and positioned / welded by script
	(owner's project rules, 2026-10-30: "clone props/weapons from ReplicatedStorage.Assets.Models and position/weld via
	script"):
	  Props/<type id>       a prop's box (Config.Props.Types: size, colour, material) with its detailed look
	                        (Shared/ItemShapes) on it; cloned by Services/PropService
	  Structures/<type id>  a breakable structure's box (Config.Structures.Types) and its look; Services/StructureService
	  Weapons/<weapon id>   a style weapon (Config.Styles.Weapons); Services/StyleService through Server/Visuals/Attached
	  Cosmetics/<item id>   a hat or back item (Config.Cosmetics.Items[..].Parts); Services/CosmeticService, Attached
	An item's box does the colliding, the hit checks and the physics; when it has a look the box is invisible and the
	look's parts ("Detail") only show: massless, no collisions, touches or queries, each held by a Weld (C0 = where it
	sits on the box), so it follows the box wherever the clone is put. A worn model's parts carry an "Attach" attribute
	(the R15 body part) and sit where they go on it (their CFrame from the template's origin); Attached welds them on.
]]
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Color3 = roblox.Color3
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Enum = roblox.Enum

local SHADOW_VOLUME = 1 -- cubic studs: smaller parts cast no shadow (performance on low-end phones)
local LIT_ATTRIBUTE = "LitGlow" -- parts that glow when an explosive barrel is lit (Server/Visuals/ItemDetail.light)

local Models = {}

local function folderIn(parent: any, name: string): any
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function sorted(map: { [string]: any }): { string }
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

local function smooth(part: any)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

local function tinted(color: any, tint: number?): any
	if tint == nil or tint == 1 then
		return color
	end
	return Color3.new(math.min(color.R * tint, 1), math.min(color.G * tint, 1), math.min(color.B * tint, 1))
end

-- An item's box named `name` (`config`: Size, Color, Material) with `shapes` welded on (Shared/ItemShapes).
local function item(parent: any, name: string, config: any, shapes: { any }?, ItemShapes: any): any
	local box = Instance.new("Part")
	box.Name = name
	box.Size = Vector3.new(config.Size.X, config.Size.Y, config.Size.Z)
	box.Color = Color3.fromHex(config.Color)
	box.Material = (Enum.Material :: any)[config.Material]
	smooth(box)
	if shapes and #shapes > 0 then
		box.Transparency = 1
		for _, shape in shapes do
			local detail = if shape.Shape == "Wedge" then Instance.new("WedgePart") else Instance.new("Part")
			if shape.Shape ~= "Wedge" then
				detail.Shape = (Enum.PartType :: any)[shape.Shape]
			end
			local offset = ItemShapes.offset(shape)
			detail.Name = "Detail"
			detail.Size = Vector3.new(shape.Size[1], shape.Size[2], shape.Size[3])
			detail.CFrame = offset
			detail.Color = if shape.Color then Color3.fromHex(shape.Color) else tinted(box.Color, shape.Tint)
			detail.Material = if shape.Material then (Enum.Material :: any)[shape.Material] else box.Material
			detail.Transparency = shape.Transparency or 0
			detail.Reflectance = shape.Reflectance or 0
			smooth(detail)
			detail.Anchored = false
			detail.CanCollide = false
			detail.CanTouch = false
			detail.CanQuery = false
			detail.Massless = true
			detail.CastShadow = detail.Size.X * detail.Size.Y * detail.Size.Z >= SHADOW_VOLUME
			if shape.Lit then
				detail:SetAttribute(LIT_ATTRIBUTE, true)
			end
			local weld = Instance.new("Weld")
			weld.Part0 = box
			weld.Part1 = detail
			weld.C0 = offset
			weld.Parent = detail
			detail.Parent = box
		end
	end
	box.Parent = parent
	return box
end

-- A worn model named `name` from Config part specs (Types.AttachedPart), each part where it goes on its body part.
local function worn(parent: any, name: string, specs: { any })
	local model = Instance.new("Model")
	model.Name = name
	for _, spec in specs do
		local part = Instance.new("Part")
		part.Name = spec.Name
		part.Size = Vector3.new(spec.Size.X, spec.Size.Y, spec.Size.Z)
		part.Shape = (Enum.PartType :: any)[spec.Shape or "Block"]
		part.Material = (Enum.Material :: any)[spec.Material]
		part.Color = Color3.fromHex(spec.Color)
		smooth(part)
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		part.CFrame = CFrame.new(spec.Offset[1], spec.Offset[2], spec.Offset[3])
			* CFrame.Angles(math.rad(spec.Rotation[1]), math.rad(spec.Rotation[2]), math.rad(spec.Rotation[3]))
		part:SetAttribute("Attach", spec.Attach)
		part.Parent = model
	end
	model.Parent = parent
end

-- Builds the Models folder from `Config` and `ItemShapes` (Shared/ItemShapes).
function Models.build(Config: any, ItemShapes: any): any
	local folder = Instance.new("Folder")
	folder.Name = "Models"
	local props = folderIn(folder, "Props")
	for _, typeId in sorted(Config.Props.Types) do
		item(props, typeId, Config.Props.Types[typeId], ItemShapes.Props[typeId], ItemShapes)
	end
	local structures = folderIn(folder, "Structures")
	for _, typeId in sorted(Config.Structures.Types) do
		local body =
			item(structures, typeId, Config.Structures.Types[typeId], ItemShapes.Structures[typeId], ItemShapes)
		body.Anchored = true
	end
	local weapons = folderIn(folder, "Weapons")
	for _, weaponId in sorted(Config.Styles.Weapons) do
		worn(weapons, weaponId, Config.Styles.Weapons[weaponId])
	end
	local cosmetics = folderIn(folder, "Cosmetics")
	for _, itemId in sorted(Config.Cosmetics.Items) do
		local parts = Config.Cosmetics.Items[itemId].Parts
		if parts and #parts > 0 then
			worn(cosmetics, itemId, parts)
		end
	end
	return folder
end

return Models
