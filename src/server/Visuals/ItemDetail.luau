--!strict
--[[
	ItemDetail — dresses a prop or a breakable structure in its detailed look (Shared/ItemShapes; owner, 2026-10-20:
	"more detail in every item"). The item's own box stays and does everything that matters — collisions, hit checks,
	grabbing, throwing, physics, falling with a crumbling platform — but turns invisible; the shapes are welded onto
	it as massless parts that don't collide, can't be hit or touched and are left out of spatial queries, so no game
	rule changes. Items without shapes keep their plain box.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemShapes = require(Shared:WaitForChild("ItemShapes"))

local LIT_ATTRIBUTE = "LitGlow"
local SHADOW_VOLUME = 1 -- cubic studs: smaller parts cast no shadow (performance on low-end phones)

local ItemDetail = {}

local function tinted(color: Color3, tint: number?): Color3
	if tint == nil or tint == 1 then
		return color
	end
	return Color3.new(math.min(color.R * tint, 1), math.min(color.G * tint, 1), math.min(color.B * tint, 1))
end

-- Welds `shapes` onto `root` in `color` / `material` (where a shape names none) and hides the root's own box.
-- Returns the parts made.
function ItemDetail.dress(
	root: BasePart,
	shapes: { ItemShapes.Shape }?,
	color: Color3,
	material: Enum.Material
): { BasePart }
	local parts: { BasePart } = {}
	if shapes == nil or #shapes == 0 then
		return parts
	end
	root.Transparency = 1
	for _, shape in shapes do
		local part: BasePart
		if shape.Shape == "Wedge" then
			part = Instance.new("WedgePart")
		else
			local plain = Instance.new("Part")
			plain.Shape = (Enum.PartType :: any)[shape.Shape]
			part = plain
		end
		part.Name = "Detail"
		part.Size = Vector3.new(shape.Size[1], shape.Size[2], shape.Size[3])
		part.CFrame = root.CFrame * ItemShapes.offset(shape)
		part.Color = if shape.Color then Color3.fromHex(shape.Color) else tinted(color, shape.Tint)
		part.Material = if shape.Material then (Enum.Material :: any)[shape.Material] else material
		part.Transparency = shape.Transparency or 0
		part.Reflectance = shape.Reflectance or 0
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CastShadow = part.Size.X * part.Size.Y * part.Size.Z >= SHADOW_VOLUME
		if shape.Lit then
			part:SetAttribute(LIT_ATTRIBUTE, true)
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		part.Parent = root
		table.insert(parts, part)
	end
	return parts
end

-- A lit explosive barrel: its painted parts (and the box, if it has no detail) glow.
function ItemDetail.light(root: BasePart)
	root.Material = Enum.Material.Neon
	for _, part in root:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute(LIT_ATTRIBUTE) == true then
			part.Material = Enum.Material.Neon
		end
	end
end

return ItemDetail
