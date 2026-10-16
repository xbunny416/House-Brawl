--!strict
--[[
	Attached — builds a blockout model from Config part lists (Types.AttachedPart) and welds each part to its body
	part on a character: style weapons, hats, back items. Visual only: massless, no collisions, not hit by attack
	boxes (CanQuery off). Building again under the same name replaces the old model.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Config"):WaitForChild("Types"))

local Attached = {}

-- Replaces the model called `name` on `character` with one built from `parts` (nil / empty = just remove it).
function Attached.build(character: Model, name: string, parts: { Types.AttachedPart }?)
	local old = character:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	if parts == nil or #parts == 0 then
		return
	end
	local model = Instance.new("Model")
	model.Name = name
	for _, spec in parts do
		local anchor = character:FindFirstChild(spec.Attach)
		if anchor == nil or not anchor:IsA("BasePart") then
			continue
		end
		local part = Instance.new("Part")
		part.Name = spec.Name
		part.Size = Vector3.new(spec.Size.X, spec.Size.Y, spec.Size.Z)
		part.Shape = (Enum.PartType :: any)[spec.Shape or "Block"]
		part.Material = (Enum.Material :: any)[spec.Material]
		part.Color = Color3.fromHex(spec.Color)
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		local rotation =
			CFrame.Angles(math.rad(spec.Rotation[1]), math.rad(spec.Rotation[2]), math.rad(spec.Rotation[3]))
		part.CFrame = anchor.CFrame * CFrame.new(spec.Offset[1], spec.Offset[2], spec.Offset[3]) * rotation
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = anchor
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
	end
	model.Parent = character
end

return Attached
