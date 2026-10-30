--!strict
--[[
	Attached — puts a worn model on a character: style weapons, hats, back items. The model is a clone of its template
	in ReplicatedStorage.Assets.Models (Weapons / Cosmetics, built from Config part lists by assets/Models.luau); each
	part names its R15 body part ("Attach" attribute) and sits where it goes on it (its CFrame from the template's
	origin), so it is positioned on that body part and welded to it. Visual only: massless, no collisions, not hit by
	attack boxes (CanQuery off). Putting one on again under the same name replaces the old model.
]]
local Attached = {}

-- Replaces the model called `name` on `character` with a clone of `template` (nil = just remove it).
function Attached.build(character: Model, name: string, template: Instance?)
	local old = character:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	if template == nil then
		return
	end
	local model = template:Clone()
	model.Name = name
	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		local attach = part:GetAttribute("Attach")
		local anchor = if type(attach) == "string" then character:FindFirstChild(attach) else nil
		if anchor == nil or not anchor:IsA("BasePart") then
			part:Destroy()
			continue
		end
		local offset = part.CFrame -- where it goes on its body part
		part.CFrame = anchor.CFrame * offset
		local weld = Instance.new("Weld")
		weld.Part0 = anchor
		weld.Part1 = part
		weld.C0 = offset
		weld.Parent = part
	end
	model.Parent = character
end

return Attached
