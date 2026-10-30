--!strict
--[[
	ItemDetail — the lit look of an explosive barrel. A prop's or structure's detailed look (Shared/ItemShapes; owner,
	2026-10-20: "more detail in every item") comes with its template in ReplicatedStorage.Assets.Models (assets/
	Models.luau): the item's own box still does everything that matters — collisions, hit checks, grabbing, throwing,
	physics, falling with a crumbling platform — but is invisible; the shapes are welded on as massless parts that don't
	collide, can't be hit or touched and are left out of spatial queries, so no game rule changes.
]]
local LIT_ATTRIBUTE = "LitGlow"

local ItemDetail = {}

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
