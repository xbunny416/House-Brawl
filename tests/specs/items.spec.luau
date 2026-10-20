--!strict
-- The detailed props and breakable structures (owner, 2026-10-20: "more detail in every item"): every prop has its
-- shapes, and every shape stays inside its item's box (the box still does the colliding, so the look must match it).
local roblox = require("@lune/roblox")
local Roblox = require("../roblox")
local expect = require("../expect")

Roblox.setGlobals({ CFrame = roblox.CFrame, Vector3 = roblox.Vector3 })

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local ItemShapes = Roblox.require(Roblox.game.ReplicatedStorage.Shared.ItemShapes)

local TOLERANCE = 0.2 -- studs a detail may poke out of its box (rims, bumpers, antennae)
local SHAPES = { Block = true, Cylinder = true, Ball = true, Wedge = true }

-- Fails if any corner of any shape lies outside the box `size` (centred) by more than TOLERANCE.
local function checkInside(name: string, shapes: { any }, size: { X: number, Y: number, Z: number })
	local half = { size.X / 2 + TOLERANCE, size.Y / 2 + TOLERANCE, size.Z / 2 + TOLERANCE }
	for index, shape in shapes do
		expect.truthy(SHAPES[shape.Shape], `{name} shape {index}: unknown kind {shape.Shape}`)
		if shape.Shape == "Ball" then
			expect.truthy(shape.Size[1] == shape.Size[2] and shape.Size[2] == shape.Size[3], `{name} ball {index}`)
		end
		local cframe = ItemShapes.offset(shape)
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = cframe
						* roblox.Vector3.new(sx * shape.Size[1] / 2, sy * shape.Size[2] / 2, sz * shape.Size[3] / 2)
					expect.truthy(
						math.abs(corner.X) <= half[1]
							and math.abs(corner.Y) <= half[2]
							and math.abs(corner.Z) <= half[3],
						`{name} shape {index} pokes out of its box at ({corner.X}, {corner.Y}, {corner.Z})`
					)
				end
			end
		end
		if shape.Color then
			expect.truthy(string.match(shape.Color, "^#%x%x%x%x%x%x$"), `{name} shape {index} colour`)
		end
	end
end

return {
	["every prop type is detailed, and every shape fits inside its box"] = function()
		for typeId, typeConfig in Config.Props.Types do
			local shapes = ItemShapes.Props[typeId]
			expect.truthy(shapes and #shapes >= 5, `{typeId} has detail`)
			checkInside(typeId, shapes, typeConfig.Size)
		end
		for typeId in ItemShapes.Props do
			expect.truthy(Config.Props.Types[typeId], `{typeId} is a prop type`)
		end
	end,
	["detailed structures fit inside their boxes"] = function()
		for typeId, shapes in ItemShapes.Structures do
			local typeConfig = Config.Structures.Types[typeId]
			expect.truthy(typeConfig, `{typeId} is a structure type`)
			expect.truthy(#shapes >= 10, `{typeId} has detail`)
			checkInside(typeId, shapes, typeConfig.Size)
		end
		for _, typeId in { "WreckedCar", "VendingMachine", "RoadBarrierStack" } do
			expect.truthy(ItemShapes.Structures[typeId], `{typeId} (Broken Highway) is detailed`)
		end
	end,
	["only the explosive barrel's paint glows when lit"] = function()
		local lit = 0
		for typeId, shapes in ItemShapes.Props do
			for _, shape in shapes do
				if shape.Lit then
					expect.equal(typeId, "ExplosiveBarrel", "lit shapes")
					lit += 1
				end
			end
		end
		expect.truthy(lit >= 3, "the explosive barrel glows")
	end,
}
