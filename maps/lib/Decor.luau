--!strict
--[[
	Decor — detailed arena furniture and street pieces (owner, 2026-10-29: "do you remember my ref, even table have
	more detail than this. fountain look blocky even table, tv many thing not even detail. make structure 10 times more
	detail"). The reference is the lobby's (docs/reference): sofas with cushions and rolled arms, a table on a pedestal,
	potted plants, a vending machine with shelves of drinks, a kitchen counter with a sink and a tap. Every piece here is
	many parts instead of one block.

	- Builders, at = { x, z } on the floor `y`, `yaw` in degrees (unturned, the front looks +Z): roundTable, sofa, bed,
	  desk, stool, plant, vending, bench, tree.
	- Decor.dressAll(container): rebuilds the plain blocks inside `container` by their names (counters, kitchens,
	  shelves, cabinets, tables, benches, toilets, bunks, wall TVs, boards, clocks, posters, ...) in the same box. A
	  block's front faces the middle of the building it stands in (its GroundFloor), else +Z.
	Collision: what you'd bump into stays solid (tops, bodies, seats, mattresses); trims, legs, goods and screens are
	walk-through.
]]
local B = require("./Builder")

local roblox = B.roblox
local Vector3 = roblox.Vector3

local Decor = {}

type Put = (spec: any) -> any

-- Puts local specs (Position { lx, ly, lz }: lx right, ly up from the floor, lz forward) round (x, z) on y, turned yaw.
local function frame(at: { number }, y: number, yaw: number): Put
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	return function(spec: any): any
		local copy = table.clone(spec)
		local p = spec.Position
		copy.Position = { at[1] + p[1] * c + p[3] * s, y + p[2], at[2] - p[1] * s + p[3] * c }
		copy.Yaw = yaw
		return B.part(copy)
	end
end

-- An upright cylinder (a pole, a disc when short) centred at local `p`.
local function cylinder(
	put: Put,
	name: string,
	p: { number },
	height: number,
	diameter: number,
	color: string,
	material: string?,
	collide: boolean?
): any
	return put({
		Name = name,
		Size = { height, diameter, diameter },
		Position = p,
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = color,
		Material = material or "SmoothPlastic",
		CanCollide = collide == true,
	})
end

local function ball(put: Put, name: string, p: { number }, diameter: number, color: string, material: string?): any
	return put({
		Name = name,
		Size = { diameter, diameter, diameter },
		Position = p,
		Shape = "Ball",
		Color = color,
		Material = material or "SmoothPlastic",
		CanCollide = false,
	})
end

---------------------------------------------------------------------------------------------------------------------
-- Builders
---------------------------------------------------------------------------------------------------------------------

-- A café table on a pedestal: a foot with a ring, an iron pedestal and collar, a marble top with a rim, a vase.
function Decor.roundTable(at: { number }, y: number?, top: string?, metal: string?): any
	local put = frame(at, y or 0, 0)
	local iron = metal or "MetalDark"
	return B.model("Table", function()
		cylinder(put, "Foot", { 0, 0.08, 0 }, 0.16, 1.9, iron, "Metal", true)
		cylinder(put, "FootRing", { 0, 0.19, 0 }, 0.06, 1.4, "Metal", "Metal")
		cylinder(put, "Pedestal", { 0, 1.3, 0 }, 2.2, 0.32, iron, "Metal", true)
		cylinder(put, "Collar", { 0, 2.35, 0 }, 0.16, 0.7, iron, "Metal")
		cylinder(put, "Top", { 0, 2.52, 0 }, 0.18, 2.8, top or "OffWhite", "Marble", true)
		cylinder(put, "TopRim", { 0, 2.52, 0 }, 0.08, 2.9, iron, "Metal")
		cylinder(put, "Vase", { 0.35, 2.82, 0.25 }, 0.42, 0.28, "Glass", "Glass")
		ball(put, "Flower", { 0.35, 3.15, 0.25 }, 0.42, "SakuraPink", "LeafyGrass")
	end)
end

-- A two-seat sofa (you sit facing +Z): a base on wood legs, two seat cushions with piping, a back frame with two
-- tilted cushions, upright arms with rolls on top.
function Decor.sofa(at: { number }, y: number, yaw: number, color: string): any
	local put = frame(at, y, yaw)
	local width = 6.4
	return B.model("Sofa", function()
		put({
			Name = "Base",
			Size = { width - 0.2, 0.7, 2.4 },
			Position = { 0, 0.65, 0 },
			Color = color,
			Material = "Fabric",
		})
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				cylinder(put, "Leg", { sx * (width / 2 - 0.5), 0.15, sz * 0.9 }, 0.3, 0.3, "WoodDark", "Wood")
			end
			put({
				Name = "Cushion",
				Size = { 2.35, 0.55, 2 },
				Position = { sx * 1.2, 1.28, 0.15 },
				Color = color,
				Material = "Fabric",
			})
			put({
				Name = "BackCushion",
				Size = { 2.3, 1.5, 0.5 },
				Position = { sx * 1.2, 2.2, -0.5 },
				Rotation = { -8, 0, 0 },
				Color = color,
				Material = "Fabric",
				CanCollide = false,
			})
			put({
				Name = "Arm",
				Size = { 0.8, 1.7, 2.4 },
				Position = { sx * (width / 2 - 0.4), 1.15, 0 },
				Color = color,
				Material = "Fabric",
			})
			put({
				Name = "ArmRoll",
				Size = { 2.4, 0.9, 0.9 },
				Position = { sx * (width / 2 - 0.4), 2, 0 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Color = color,
				Material = "Fabric",
				CanCollide = false,
			})
		end
		put({
			Name = "BackFrame",
			Size = { width - 1.6, 2.1, 0.6 },
			Position = { 0, 2, -0.95 },
			Color = color,
			Material = "Fabric",
		})
		put({
			Name = "Piping",
			Size = { width - 1.8, 0.1, 0.1 },
			Position = { 0, 1.55, 1.15 },
			Color = "WoodDark",
			Material = "Fabric",
			CanCollide = false,
		})
	end)
end

-- A bed (its head toward local −Z): a wood frame on legs, a mattress, a blanket and a turned-down sheet, two pillows,
-- a headboard with a cap, a footboard.
function Decor.bed(at: { number }, y: number, yaw: number, blanket: string): any
	local put = frame(at, y, yaw)
	local length, width = 7, 4.4
	return B.model("Bed", function()
		put({
			Name = "Frame",
			Size = { width, 0.5, length },
			Position = { 0, 0.65, 0 },
			Color = "WoodDark",
			Material = "Wood",
		})
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				put({
					Name = "Leg",
					Size = { 0.3, 0.4, 0.3 },
					Position = { sx * (width / 2 - 0.3), 0.2, sz * (length / 2 - 0.3) },
					Color = "WoodDark",
					Material = "Wood",
					CanCollide = false,
				})
			end
			put({
				Name = "Pillow",
				Size = { 1.7, 0.45, 1 },
				Position = { sx * 1.05, 1.83, -length / 2 + 1 },
				Color = "OffWhite",
				Material = "Fabric",
				CanCollide = false,
			})
		end
		put({
			Name = "Mattress",
			Size = { width - 0.2, 0.7, length - 0.3 },
			Position = { 0, 1.25, 0.1 },
			Color = "OffWhite",
			Material = "Fabric",
		})
		put({
			Name = "Blanket",
			Size = { width - 0.1, 0.18, length * 0.62 },
			Position = { 0, 1.65, length * 0.17 },
			Color = blanket,
			Material = "Fabric",
			CanCollide = false,
		})
		put({
			Name = "Sheet",
			Size = { width - 0.1, 0.22, 0.6 },
			Position = { 0, 1.7, length * 0.17 - length * 0.31 + 0.3 },
			Color = "Cream",
			Material = "Fabric",
			CanCollide = false,
		})
		put({
			Name = "Headboard",
			Size = { width + 0.2, 3.2, 0.3 },
			Position = { 0, 1.6, -length / 2 - 0.05 },
			Color = "WoodDark",
			Material = "Wood",
		})
		put({
			Name = "HeadboardCap",
			Size = { width + 0.4, 0.2, 0.45 },
			Position = { 0, 3.3, -length / 2 - 0.05 },
			Color = "WoodMid",
			Material = "Wood",
			CanCollide = false,
		})
		put({
			Name = "Footboard",
			Size = { width + 0.2, 1.5, 0.25 },
			Position = { 0, 0.75, length / 2 + 0.02 },
			Color = "WoodDark",
			Material = "Wood",
		})
	end)
end

-- An office desk (you sit at its +Z side): a top on two side panels, a modesty panel, a drawer pedestal with two
-- drawers, a monitor (bezel, screen, neck, foot), a keyboard, a mouse, a mug.
function Decor.desk(at: { number }, y: number, yaw: number): any
	local put = frame(at, y, yaw)
	return B.model("Desk", function()
		put({ Name = "Top", Size = { 5, 0.2, 2.4 }, Position = { 0, 2.5, 0 }, Color = "WoodMid", Material = "Wood" })
		for _, sx in { -1, 1 } do
			put({
				Name = "Side",
				Size = { 0.15, 2.4, 2.2 },
				Position = { sx * 2.35, 1.2, 0 },
				Color = "MetalDark",
				Material = "Metal",
			})
		end
		put({
			Name = "Modesty",
			Size = { 4.6, 1.2, 0.1 },
			Position = { 0, 1.8, -1.05 },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		put({
			Name = "Pedestal",
			Size = { 1.3, 2.2, 2 },
			Position = { 1.55, 1.1, 0.1 },
			Color = "CityGrey",
			Material = "Metal",
		})
		for _, dy in { 0.6, 1.6 } do
			put({
				Name = "Drawer",
				Size = { 1.1, 0.85, 0.05 },
				Position = { 1.55, dy, 1.12 },
				Color = "OffWhite",
				Material = "Metal",
				CanCollide = false,
			})
		end
		put({
			Name = "Bezel",
			Size = { 2.2, 1.35, 0.12 },
			Position = { -0.3, 3.55, -0.7 },
			Color = "Black",
			CanCollide = false,
		})
		put({
			Name = "Screen",
			Size = { 2, 1.15, 0.03 },
			Position = { -0.3, 3.55, -0.63 },
			Color = "ArcadeBlue",
			Material = "Neon",
			CanCollide = false,
		})
		put({
			Name = "Neck",
			Size = { 0.15, 0.55, 0.12 },
			Position = { -0.3, 2.85, -0.78 },
			Color = "Black",
			CanCollide = false,
		})
		put({
			Name = "Foot",
			Size = { 0.8, 0.06, 0.55 },
			Position = { -0.3, 2.63, -0.75 },
			Color = "Black",
			CanCollide = false,
		})
		put({
			Name = "Keyboard",
			Size = { 1.7, 0.07, 0.55 },
			Position = { -0.3, 2.64, 0.35 },
			Color = "Black",
			CanCollide = false,
		})
		put({
			Name = "Mouse",
			Size = { 0.22, 0.08, 0.35 },
			Position = { 0.9, 2.64, 0.4 },
			Color = "Black",
			CanCollide = false,
		})
		cylinder(put, "Mug", { 1.8, 2.8, -0.3 }, 0.4, 0.3, "OffWhite")
	end)
end

-- A bar stool: a foot, a chrome pole and foot ring, a padded seat with a rim. `y` is the floor.
function Decor.stool(at: { number }, y: number, color: string): any
	local put = frame(at, y, 0)
	return B.model("Stool", function()
		cylinder(put, "Foot", { 0, 0.06, 0 }, 0.12, 1.1, "MetalDark", "Metal", true)
		cylinder(put, "Pole", { 0, 1, 0 }, 1.8, 0.22, "Metal", "Metal", true)
		cylinder(put, "FootRing", { 0, 0.8, 0 }, 0.06, 0.9, "Metal", "Metal")
		cylinder(put, "SeatRim", { 0, 1.93, 0 }, 0.08, 1.38, "MetalDark", "Metal")
		cylinder(put, "Seat", { 0, 2.07, 0 }, 0.3, 1.3, color, "Leather", true)
	end)
end

-- A potted plant: a tapered pot with a rim and soil, a stem, three balls of leaves.
function Decor.plant(at: { number }, y: number): any
	local put = frame(at, y, 0)
	return B.model("PottedPlant", function()
		cylinder(put, "Pot", { 0, 0.45, 0 }, 0.9, 1.3, "ConcreteDark", "Concrete", true)
		cylinder(put, "PotTop", { 0, 1.25, 0 }, 0.7, 1.6, "ConcreteDark", "Concrete", true)
		cylinder(put, "Rim", { 0, 1.62, 0 }, 0.12, 1.72, "Concrete", "Concrete")
		cylinder(put, "Soil", { 0, 1.6, 0 }, 0.05, 1.45, "Soil", "Ground")
		cylinder(put, "Stem", { 0, 2.1, 0 }, 1.2, 0.15, "WoodDark", "Wood")
		ball(put, "Leaves", { 0, 2.8, 0 }, 2.2, "Leaf", "LeafyGrass")
		ball(put, "Leaves", { 0.6, 3.4, 0.2 }, 1.5, "Lawn", "LeafyGrass")
		ball(put, "Leaves", { -0.5, 3.2, -0.4 }, 1.3, "Leaf", "LeafyGrass")
	end)
end

-- A vending machine (its front looks +Z): the cabinet, a lit header, a dark window frame and glass over four shelves
-- of coloured drinks, a keypad, a coin slot, the pick-up flap.
function Decor.vending(at: { number }, yaw: number, color: string): any
	local put = frame(at, 0, yaw)
	return B.model("Vending", function()
		put({ Name = "Body", Size = { 3, 6, 2.4 }, Position = { 0, 3, 0 }, Color = color })
		put({
			Name = "Header",
			Size = { 2.6, 0.7, 0.1 },
			Position = { 0, 5.5, 1.21 },
			Color = "OffWhite",
			Material = "Neon",
			CanCollide = false,
		})
		put({
			Name = "WindowFrame",
			Size = { 2.1, 3.4, 0.06 },
			Position = { -0.3, 3.4, 1.22 },
			Color = "Black",
			CanCollide = false,
		})
		for row, drink in { "ShopRed", "ShopYellow", "ShopTeal", "ShopPink" } do
			put({
				Name = "Drinks",
				Size = { 1.85, 0.5, 0.05 },
				Position = { -0.3, 2.05 + row * 0.75, 1.25 },
				Color = drink,
				Material = "Neon",
				CanCollide = false,
			})
		end
		put({
			Name = "Glass",
			Size = { 1.95, 3.2, 0.04 },
			Position = { -0.3, 3.4, 1.29 },
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.55,
			CanCollide = false,
		})
		put({
			Name = "Keypad",
			Size = { 0.5, 0.8, 0.06 },
			Position = { 1.05, 3.9, 1.22 },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
		put({
			Name = "CoinSlot",
			Size = { 0.3, 0.3, 0.06 },
			Position = { 1.05, 3.2, 1.22 },
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		})
		put({ Name = "Flap", Size = { 2.2, 0.7, 0.08 }, Position = { 0, 1, 1.22 }, Color = "Black", CanCollide = false })
	end)
end

-- A park bench (you sit facing +Z) on `y`: three seat slats and two back slats on iron side frames with arms.
function Decor.bench(at: { number }, y: number, yaw: number): any
	local put = frame(at, y, yaw)
	return B.model("Bench", function()
		for _, dz in { -0.45, 0, 0.45 } do
			put({
				Name = "Slat",
				Size = { 5, 0.18, 0.38 },
				Position = { 0, 1.45, dz },
				Color = "Wood",
				Material = "WoodPlanks",
			})
		end
		for index, dy in { 2.1, 2.6 } do
			put({
				Name = "BackSlat",
				Size = { 5, 0.3, 0.12 },
				Position = { 0, dy, -0.72 - index * 0.04 },
				Rotation = { -10, 0, 0 },
				Color = "Wood",
				Material = "WoodPlanks",
				CanCollide = false,
			})
		end
		for _, sx in { -2.2, 2.2 } do
			put({
				Name = "FrontLeg",
				Size = { 0.2, 1.4, 0.2 },
				Position = { sx, 0.7, 0.5 },
				Color = "MetalDark",
				Material = "Metal",
			})
			put({
				Name = "BackLeg",
				Size = { 0.2, 2.9, 0.2 },
				Position = { sx, 1.45, -0.75 },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			put({
				Name = "ArmRest",
				Size = { 0.2, 0.15, 1.4 },
				Position = { sx, 2.05, -0.1 },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
	end)
end

-- A tree on `y`, about 18 tall: a trunk in two pieces, two branches, five clusters of leaves (`leaf` colours them).
function Decor.tree(name: string, at: { number }, leaf: string, y: number?): any
	local put = frame(at, y or 0, 0)
	return B.model(name, function()
		cylinder(put, "Trunk", { 0, 3, 0 }, 6, 1.4, "WoodDark", "Wood", true)
		cylinder(put, "TrunkTop", { 0.2, 7.5, 0 }, 3.2, 1, "WoodDark", "Wood")
		for index, branch in { { 1.2, 8.4, 0.6, -35 }, { -1, 8, -0.8, 40 } } do
			put({
				Name = `Branch{index}`,
				Size = { 0.4, 3.4, 0.4 },
				Position = { branch[1], branch[2], branch[3] },
				Rotation = { 0, 0, branch[4] },
				Color = "WoodDark",
				Material = "Wood",
				CanCollide = false,
			})
		end
		for _, cluster in
			{ { 0, 11, 0, 9 }, { 2.6, 12.4, 1, 7 }, { -2.4, 12, -1.4, 7 }, { 0.5, 15, -0.5, 6 }, { -1, 9.6, 2.2, 5 } }
		do
			ball(put, "Leaves", { cluster[1], cluster[2], cluster[3] }, cluster[4], leaf, "LeafyGrass")
		end
	end)
end

-- A piece of a water jet (or a falling sheet `width` wide, `depth` thick) from (z1, y1) to (z2, y2) in the plane of
-- local Z (out from the middle) and Y.
local function jet(
	put: Put,
	name: string,
	z1: number,
	y1: number,
	z2: number,
	y2: number,
	width: number,
	depth: number?
): any
	local dz, dy = z2 - z1, y2 - y1
	return put({
		Name = name,
		Size = { width, math.sqrt(dz * dz + dy * dy), depth or width },
		Position = { 0, (y1 + y2) / 2, (z1 + z2) / 2 },
		Rotation = { math.deg(math.atan2(dz, dy)), 0, 0 },
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.4,
		CanCollide = false,
	})
end

-- A three-tier stone fountain on `y` (19 across): a step, a basin walled by 12 capped stones with water inside, a
-- pedestal and column with a ring, a lower bowl and an upper bowl, each with water spilling over in curtains, a finial
-- with a jet on top, and four spouts on the rim arcing water to the middle. You can wade in the basin.
function Decor.fountain(at: { number }, y: number?)
	local base = y or 0
	local put = frame(at, base, 0)
	local radius = 7.5
	B.model("Fountain", function()
		cylinder(put, "Step", { 0, 0.2, 0 }, 0.4, 19, "ConcreteDark", "Concrete", true)
		cylinder(put, "BasinFloor", { 0, 0.8, 0 }, 0.8, 15.4, "Stone", "Slate", true)
		local water = cylinder(put, "BasinWater", { 0, 1.85, 0 }, 0.1, 14.6, "Glass", "Glass")
		water.Transparency = 0.35
		for index = 0, 11 do
			local around = frame(at, base, index * 30)
			around({
				Name = "RimStone",
				Size = { 4.05, 1.9, 0.9 },
				Position = { 0, 1.35, radius },
				Color = "Concrete",
				Material = "Concrete",
				CanCollide = true,
			})
			around({
				Name = "RimCap",
				Size = { 4.15, 0.3, 1.3 },
				Position = { 0, 2.45, radius },
				Color = "OffWhite",
				Material = "Marble",
				CanCollide = true,
			})
			around({
				Name = "RimPanel",
				Size = { 2.6, 1, 0.06 },
				Position = { 0, 1.2, radius + 0.48 },
				Color = "Stone",
				Material = "Slate",
				CanCollide = false,
			})
		end
		-- The middle: a pedestal, a column with a ring, the lower bowl.
		cylinder(put, "Pedestal", { 0, 1.6, 0 }, 0.8, 3.4, "Concrete", "Concrete", true)
		cylinder(put, "PedestalCap", { 0, 2.1, 0 }, 0.2, 3.7, "OffWhite", "Marble", true)
		cylinder(put, "Column", { 0, 3.7, 0 }, 3, 1.5, "OffWhite", "Marble", true)
		cylinder(put, "ColumnRing", { 0, 3.6, 0 }, 0.3, 1.9, "Concrete", "Concrete")
		cylinder(put, "BowlFoot", { 0, 5.4, 0 }, 0.4, 3.4, "Concrete", "Concrete", true)
		cylinder(put, "Bowl", { 0, 5.85, 0 }, 0.5, 6.2, "OffWhite", "Marble", true)
		cylinder(put, "BowlRim", { 0, 6.2, 0 }, 0.2, 6.7, "Concrete", "Concrete", true)
		cylinder(put, "BowlWater", { 0, 6.33, 0 }, 0.06, 6.1, "Glass", "Glass").Transparency = 0.3
		-- The upper column and bowl, a finial with a jet and a spray.
		cylinder(put, "UpperColumn", { 0, 7.3, 0 }, 2, 0.9, "OffWhite", "Marble", true)
		cylinder(put, "UpperBowl", { 0, 8.5, 0 }, 0.4, 3.5, "OffWhite", "Marble", true)
		cylinder(put, "UpperRim", { 0, 8.75, 0 }, 0.15, 3.8, "Concrete", "Concrete")
		cylinder(put, "UpperWater", { 0, 8.85, 0 }, 0.05, 3.4, "Glass", "Glass").Transparency = 0.3
		cylinder(put, "FinialStem", { 0, 9.2, 0 }, 0.7, 0.4, "OffWhite", "Marble")
		ball(put, "Finial", { 0, 9.75, 0 }, 0.8, "OffWhite", "Marble")
		cylinder(put, "TopJet", { 0, 11.1, 0 }, 2.2, 0.3, "Glass", "Glass").Transparency = 0.4
		ball(put, "Spray", { 0, 12.3, 0 }, 1.3, "Glass", "Glass").Transparency = 0.55
		-- Curtains of water spilling over both bowls.
		for index = 0, 7 do
			jet(frame(at, base, index * 45 + 22.5), "Curtain", 3.3, 6.2, 3.7, 1.9, 1.7, 0.08)
		end
		for index = 0, 5 do
			jet(frame(at, base, index * 60), "UpperCurtain", 1.9, 8.7, 2.2, 6.4, 1, 0.06)
		end
		-- Four spouts on the rim, each arcing water in two pieces to the middle.
		for index = 0, 3 do
			local around = frame(at, base, index * 90 + 45)
			ball(around, "SpoutHead", { 0, 2.95, radius - 0.1 }, 0.8, "Concrete", "Concrete")
			around({
				Name = "SpoutNose",
				Size = { 0.25, 0.25, 0.6 },
				Position = { 0, 2.95, radius - 0.6 },
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
			jet(around, "SpoutJet", radius - 0.9, 3, radius - 2.4, 3.8, 0.22)
			jet(around, "SpoutJet", radius - 2.4, 3.8, radius - 3.8, 1.9, 0.22)
		end
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- Dressing plain blocks by name
---------------------------------------------------------------------------------------------------------------------

-- A colour a step lighter or darker than `color` (t > 0 lighter), as hex.
local function shade(color: any, t: number): string
	local target = if t > 0 then 1 else 0
	local k = math.abs(t)
	local function channel(v: number): number
		return math.floor(math.clamp(v + (target - v) * k, 0, 1) * 255 + 0.5)
	end
	return string.format("#%02X%02X%02X", channel(color.R), channel(color.G), channel(color.B))
end

-- The geometry of a block: its world frame and a `put` that takes specs in the block's own space (Position from its
-- centre in its axes, Size in its axes); "thin" is the shorter of its X and Z, its front faces the way `front` (±1)
-- along that axis.
type Box = {
	part: any,
	put: Put,
	w: number, -- the long side along the floor
	h: number,
	t: number, -- the thin side
	front: number,
	thinX: boolean,
}

local function local3(box: Box, along: number, y: number, across: number): { number }
	-- `along` the long side, `across` the thin side (+ toward the front).
	if box.thinX then
		return { across, y, along }
	end
	return { along, y, across }
end

local function size3(box: Box, along: number, y: number, across: number): { number }
	if box.thinX then
		return { across, y, along }
	end
	return { along, y, across }
end

local function boxOf(part: any, floors: { any }): Box
	local cf, size = part.CFrame, part.Size
	local right, up = cf.RightVector, cf.UpVector
	local put: Put = function(spec: any): any
		local copy = table.clone(spec)
		local p = spec.Position
		local world = cf * Vector3.new(p[1], p[2], p[3])
		copy.Position = { world.X, world.Y, world.Z }
		if spec.Cylinder then
			-- An upright cylinder: its axis (local X) up.
			copy.Axes = { Right = { 0, 1, 0 }, Up = { -1, 0, 0 } }
			copy.Shape = "Cylinder"
			copy.Cylinder = nil
		else
			copy.Axes = { Right = { right.X, right.Y, right.Z }, Up = { up.X, up.Y, up.Z } }
		end
		return B.part(copy)
	end
	local thinX = size.X <= size.Z
	-- The front: toward the middle of the building the block stands in.
	local p = cf.Position
	local front = 1
	for _, floor in floors do
		local fp, fs = floor.CFrame.Position, floor.Size
		if math.abs(p.X - fp.X) <= fs.X / 2 + 1 and math.abs(p.Z - fp.Z) <= fs.Z / 2 + 1 then
			local toMiddle = Vector3.new(fp.X - p.X, 0, fp.Z - p.Z)
			local axis = if thinX then right else cf.LookVector * -1
			-- LookVector is −Z, so −LookVector is the block's +Z.
			front = if toMiddle:Dot(axis) >= 0 then 1 else -1
			break
		end
	end
	return {
		part = part,
		put = put,
		w = if thinX then size.Z else size.X,
		h = size.Y,
		t = if thinX then size.X else size.Z,
		front = front,
		thinX = thinX,
	}
end

-- A counter: a body on a dark kick, a top that overhangs, two panel seams and a rail on its front; a till on top of
-- a shop's counter.
local function counter(box: Box, till: boolean)
	local part, put = box.part, box.put
	local color = part.Color
	local hex, top = shade(color, 0), shade(color, -0.35)
	local w, h, t, f = box.w, box.h, box.t, box.front
	put({
		Name = "CounterBody",
		Size = size3(box, w - 0.2, h - 0.45, t - 0.2),
		Position = local3(box, 0, -0.025, 0),
		Color = hex,
		Material = part.Material.Name,
	})
	put({
		Name = "CounterTop",
		Size = size3(box, w + 0.3, 0.25, t + 0.3),
		Position = local3(box, 0, h / 2 - 0.125, 0),
		Color = top,
		Material = "Marble",
	})
	put({
		Name = "Kick",
		Size = size3(box, w - 0.5, 0.2, t - 0.5),
		Position = local3(box, 0, -h / 2 + 0.1, 0),
		Color = "Black",
		CanCollide = false,
	})
	for _, along in { -w / 6, w / 6 } do
		put({
			Name = "Seam",
			Size = size3(box, 0.08, h - 0.9, 0.06),
			Position = local3(box, along, -0.15, f * (t / 2 - 0.07)),
			Color = top,
			CanCollide = false,
		})
	end
	put({
		Name = "Rail",
		Size = size3(box, w - 0.3, 0.08, 0.06),
		Position = local3(box, 0, h / 2 - 0.45, f * (t / 2 - 0.07)),
		Color = top,
		CanCollide = false,
	})
	if till and w >= 4 then
		put({
			Name = "Till",
			Size = size3(box, 0.9, 0.6, 0.8),
			Position = local3(box, w / 2 - 0.9, h / 2 + 0.3, 0),
			Color = "Black",
			CanCollide = false,
		})
		put({
			Name = "TillScreen",
			Size = size3(box, 0.7, 0.45, 0.05),
			Position = local3(box, w / 2 - 0.9, h / 2 + 0.8, -f * 0.2),
			Color = "NeonTeal",
			Material = "Neon",
			CanCollide = false,
		})
	end
end

-- A kitchen run: the counter, a sink with a tap, two hob rings, three cupboard handles.
local function kitchen(box: Box)
	counter(box, false)
	local put, w, h, t, f = box.put, box.w, box.h, box.t, box.front
	put({
		Name = "Sink",
		Size = size3(box, 1.6, 0.06, math.min(1.2, t - 0.5)),
		Position = local3(box, -w / 4, h / 2 + 0.01, 0),
		Color = "Metal",
		Material = "Metal",
		CanCollide = false,
	})
	put({
		Name = "Tap",
		Size = { 0.8, 0.15, 0.15 },
		Position = local3(box, -w / 4, h / 2 + 0.4, -f * (t / 2 - 0.35)),
		Color = "Metal",
		Material = "Metal",
		Cylinder = true,
		CanCollide = false,
	})
	put({
		Name = "Spout",
		Size = size3(box, 0.12, 0.12, 0.6),
		Position = local3(box, -w / 4, h / 2 + 0.8, -f * (t / 2 - 0.6)),
		Color = "Metal",
		Material = "Metal",
		CanCollide = false,
	})
	for _, along in { w / 4 - 0.5, w / 4 + 0.5 } do
		put({
			Name = "Hob",
			Size = { 0.05, 0.8, 0.8 },
			Position = local3(box, along, h / 2 + 0.03, 0),
			Color = "Black",
			Cylinder = true,
			CanCollide = false,
		})
	end
	for _, along in { -w / 3, 0, w / 3 } do
		put({
			Name = "Handle",
			Size = size3(box, 0.6, 0.1, 0.1),
			Position = local3(box, along, h / 2 - 0.8, f * (t / 2 + 0.02)),
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		})
	end
end

-- A shelving unit: two uprights, a back panel, four boards, a row of goods on each of the lower three.
local function shelf(box: Box)
	local put, part = box.put, box.part
	local w, h, t, f = box.w, box.h, box.t, box.front
	local wood = shade(part.Color, 0)
	for _, along in { -(w / 2 - 0.1), w / 2 - 0.1 } do
		put({
			Name = "Upright",
			Size = size3(box, 0.2, h, t),
			Position = local3(box, along, 0, 0),
			Color = wood,
			Material = part.Material.Name,
		})
	end
	put({
		Name = "Back",
		Size = size3(box, w - 0.4, h, 0.12),
		Position = local3(box, 0, 0, -f * (t / 2 - 0.06)),
		Color = shade(part.Color, -0.2),
		Material = part.Material.Name,
	})
	local goods = { "ShopRed", "ShopYellow", "ShopTeal", "ShopPink", "ShopOrange", "CityBlue" }
	for level = 0, 3 do
		local y = -h / 2 + 0.06 + level * (h - 0.12) / 3
		put({
			Name = "Board",
			Size = size3(box, w - 0.4, 0.12, t),
			Position = local3(box, 0, y, 0),
			Color = wood,
			Material = part.Material.Name,
			CanCollide = level == 3,
		})
		if level < 3 then
			local tall = (h - 0.12) / 3 * 0.6
			put({
				Name = "Goods",
				Size = size3(box, w - 0.8, tall, math.max(t * 0.55, 0.2)),
				Position = local3(box, 0, y + 0.06 + tall / 2, f * t * 0.1),
				Color = goods[(level + math.floor(w)) % #goods + 1],
				CanCollide = false,
			})
		end
	end
end

-- Doors on a cabinet's front: `doors` across it (seams between them and a handle each), drawers when `drawers`.
local function cabinet(box: Box, doors: number, drawers: boolean)
	local put, part = box.put, box.part
	local w, h, t, f = box.w, box.h, box.t, box.front
	local line = shade(part.Color, -0.4)
	if drawers then
		for index = 1, doors - 1 do
			put({
				Name = "Seam",
				Size = size3(box, w - 0.3, 0.06, 0.04),
				Position = local3(box, 0, -h / 2 + index * h / doors, f * (t / 2 + 0.01)),
				Color = line,
				CanCollide = false,
			})
		end
		for index = 1, doors do
			put({
				Name = "Handle",
				Size = size3(box, 0.6, 0.1, 0.1),
				Position = local3(box, 0, -h / 2 + (index - 0.5) * h / doors, f * (t / 2 + 0.05)),
				Color = "Metal",
				Material = "Metal",
				CanCollide = false,
			})
		end
		return
	end
	for index = 1, doors - 1 do
		put({
			Name = "Seam",
			Size = size3(box, 0.06, h - 0.3, 0.04),
			Position = local3(box, -w / 2 + index * w / doors, 0, f * (t / 2 + 0.01)),
			Color = line,
			CanCollide = false,
		})
	end
	for index = 1, doors do
		put({
			Name = "Handle",
			Size = size3(box, 0.1, 0.7, 0.1),
			Position = local3(box, -w / 2 + index * w / doors - 0.35, 0.2, f * (t / 2 + 0.05)),
			Color = "Metal",
			Material = "Metal",
			CanCollide = false,
		})
	end
end

-- A table in the block's box: a top with an edge band, an apron, four legs.
local function tableFrom(box: Box)
	local put, part = box.put, box.part
	local w, h, t = box.w, box.h, box.t
	local wood, dark = shade(part.Color, 0), shade(part.Color, -0.3)
	put({
		Name = "TableTop",
		Size = size3(box, w, 0.22, t),
		Position = local3(box, 0, h / 2 - 0.11, 0),
		Color = wood,
		Material = part.Material.Name,
	})
	put({
		Name = "Edge",
		Size = size3(box, w + 0.1, 0.07, t + 0.1),
		Position = local3(box, 0, h / 2 - 0.26, 0),
		Color = dark,
		CanCollide = false,
	})
	if h > 0.9 then
		put({
			Name = "Apron",
			Size = size3(box, w - 0.5, 0.25, t - 0.5),
			Position = local3(box, 0, h / 2 - 0.42, 0),
			Color = dark,
			CanCollide = false,
		})
	end
	for _, sa in { -1, 1 } do
		for _, st in { -1, 1 } do
			put({
				Name = "Leg",
				Size = size3(box, 0.25, h - 0.22, 0.25),
				Position = local3(box, sa * (w / 2 - 0.3), -0.11, st * (t / 2 - 0.3)),
				Color = dark,
				CanCollide = false,
			})
		end
	end
end

-- A bench or pew in the block's box: the seat on two end legs, a back for a pew.
local function benchFrom(box: Box, back: boolean)
	local put, part = box.put, box.part
	local w, h, t, f = box.w, box.h, box.t, box.front
	local wood = shade(part.Color, 0)
	put({
		Name = "Seat",
		Size = size3(box, w, 0.3, t),
		Position = local3(box, 0, h / 2 - 0.15, 0),
		Color = wood,
		Material = part.Material.Name,
	})
	for _, sa in { -1, 1 } do
		put({
			Name = "EndLeg",
			Size = size3(box, 0.3, h - 0.3, t - 0.2),
			Position = local3(box, sa * (w / 2 - 0.25), -0.15, 0),
			Color = shade(part.Color, -0.25),
			Material = part.Material.Name,
		})
	end
	if back then
		put({
			Name = "Back",
			Size = size3(box, w, 1.8, 0.2),
			Position = local3(box, 0, h / 2 + 0.9, -f * (t / 2 - 0.1)),
			Color = wood,
			Material = part.Material.Name,
		})
	end
end

-- A wall TV in a flat panel's place: a bezel, a screen on each face, a maker's strip, a power light.
local function tv(box: Box)
	local put = box.put
	local w, h = box.w, box.h
	put({
		Name = "Bezel",
		Size = size3(box, w + 0.3, h + 0.3, 0.2),
		Position = local3(box, 0, 0, 0),
		Color = "Black",
		CanCollide = false,
	})
	for _, side in { -1, 1 } do
		put({
			Name = "Screen",
			Size = size3(box, w, h, 0.04),
			Position = local3(box, 0, 0.05, side * 0.11),
			Color = "ArcadeBlue",
			Material = "Glass",
			Transparency = 0.1,
			CanCollide = false,
		})
		put({
			Name = "Logo",
			Size = size3(box, 0.5, 0.06, 0.03),
			Position = local3(box, 0, -h / 2 - 0.05, side * 0.11),
			Color = "Metal",
			CanCollide = false,
		})
		put({
			Name = "PowerLight",
			Size = size3(box, 0.08, 0.08, 0.03),
			Position = local3(box, w / 2 - 0.1, -h / 2 - 0.05, side * 0.11),
			Color = "Red",
			Material = "Neon",
			CanCollide = false,
		})
	end
end

-- A frame round a wall panel (a poster, a painting, a menu, a whiteboard), and lines of writing on a board.
local function framed(box: Box, writing: number)
	local put = box.put
	local w, h = box.w, box.h
	put({
		Name = "PanelFrame",
		Size = size3(box, w + 0.3, h + 0.3, 0.06),
		Position = local3(box, 0, 0, 0),
		Color = "WoodDark",
		Material = "Wood",
		CanCollide = false,
	})
	for line = 1, writing do
		for _, side in { -1, 1 } do
			put({
				Name = "Writing",
				Size = size3(box, w * (0.75 - line * 0.1), 0.1, 0.03),
				Position = local3(box, -w * 0.05, h / 2 - line * h / (writing + 1), side * 0.08),
				Color = "Black",
				CanCollide = false,
			})
		end
	end
end

-- A wall clock in a disc's place: a rim, two hands each side.
local function clock(part: any)
	local cf, size = part.CFrame, part.Size
	local axis = cf.RightVector -- a cylinder's axis: its face looks along it
	local p = cf.Position
	B.part({
		Name = "ClockRim",
		Size = { size.X + 0.06, size.Y + 0.2, size.Z + 0.2 },
		Position = { p.X, p.Y, p.Z },
		Axes = { Right = { axis.X, axis.Y, axis.Z }, Up = { 0, 1, 0 } },
		Shape = "Cylinder",
		Color = "Black",
		CanCollide = false,
	})
	for _, side in { -1, 1 } do
		local out = p + axis * (side * (size.X / 2 + 0.05))
		for index, hand in { { 0.5, 0 }, { 0.35, 90 } } do
			local angle = math.rad(hand[2])
			local dir = Vector3.new(0, math.cos(angle), 0) + axis:Cross(Vector3.new(0, 1, 0)).Unit * math.sin(angle)
			local mid = out + dir * (hand[1] / 2)
			B.part({
				Name = `ClockHand{index}`,
				Size = { 0.06, hand[1], 0.06 },
				Position = { mid.X, mid.Y, mid.Z },
				Axes = { Right = { axis.X, axis.Y, axis.Z }, Up = { dir.X, dir.Y, dir.Z } },
				Color = "Black",
				CanCollide = false,
			})
		end
	end
end

-- Rebuilds a stool (an upright cylinder named Stool) as a detailed one standing where it stood.
local function stoolFrom(part: any)
	local p, size = part.CFrame.Position, part.Size
	Decor.stool({ p.X, p.Z }, p.Y - size.X / 2, shade(part.Color, 0))
end

-- A toilet in the block's box: a foot, a bowl, a seat ring, a cistern at the back.
local function toilet(box: Box)
	local put = box.put
	local h, t, f = box.h, box.t, box.front
	put({
		Name = "ToiletFoot",
		Size = { 0.6, 0.8, 0.8 },
		Position = local3(box, 0, -h / 2 + 0.3, f * 0.1),
		Color = "OffWhite",
		Cylinder = true,
	})
	put({
		Name = "Bowl",
		Size = { 0.5, 1.3, 1.3 },
		Position = local3(box, 0, -h / 2 + 0.85, f * 0.1),
		Color = "OffWhite",
		Cylinder = true,
	})
	put({
		Name = "SeatRing",
		Size = { 0.08, 1.4, 1.4 },
		Position = local3(box, 0, -h / 2 + 1.14, f * 0.1),
		Color = "OffWhite",
		Cylinder = true,
		CanCollide = false,
	})
	put({
		Name = "Cistern",
		Size = size3(box, 1.2, 1.2, 0.45),
		Position = local3(box, 0, -h / 2 + 1.5, -f * (t / 2 - 0.22)),
		Color = "OffWhite",
		CanCollide = false, -- the bowl's back runs into it
	})
end

-- A bunk in the block's box: a metal frame on four posts, a mattress, a pillow.
local function bunk(box: Box)
	local put = box.put
	local w, h, t, f = box.w, box.h, box.t, box.front
	put({
		Name = "BunkFrame",
		Size = size3(box, w, 0.3, t),
		Position = local3(box, 0, h / 2 - 0.65, 0),
		Color = "MetalDark",
		Material = "Metal",
	})
	put({
		Name = "Mattress",
		Size = size3(box, w - 0.2, 0.5, t - 0.2),
		Position = local3(box, 0, h / 2 - 0.25, 0),
		Color = "CityGrey",
		Material = "Fabric",
	})
	put({
		Name = "Pillow",
		Size = size3(box, 1.2, 0.3, t - 0.6),
		Position = local3(box, -w / 2 + 0.8, h / 2 + 0.1, 0),
		Color = "OffWhite",
		Material = "Fabric",
		CanCollide = false,
	})
	for _, sa in { -1, 1 } do
		for _, st in { -1, 1 } do
			put({
				Name = "Post",
				Size = size3(box, 0.2, h - 0.5, 0.2),
				Position = local3(box, sa * (w / 2 - 0.1), -0.25, st * (t / 2 - 0.1)),
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
	end
	local _ = f
end

-- A piano's keys, black keys, lid and music stand on its block.
local function piano(box: Box)
	local put = box.put
	local w, h, t, f = box.w, box.h, box.t, box.front
	put({
		Name = "Keys",
		Size = size3(box, w - 0.4, 0.15, 0.6),
		Position = local3(box, 0, h * 0.15, f * (t / 2 + 0.3)),
		Color = "OffWhite",
		CanCollide = false,
	})
	put({
		Name = "BlackKeys",
		Size = size3(box, w - 0.6, 0.1, 0.3),
		Position = local3(box, 0, h * 0.15 + 0.12, f * (t / 2 + 0.15)),
		Color = "Black",
		CanCollide = false,
	})
	put({
		Name = "Lid",
		Size = size3(box, w + 0.1, 0.12, t + 0.1),
		Position = local3(box, 0, h / 2 + 0.06, 0),
		Color = "Black",
		CanCollide = false,
	})
	put({
		Name = "MusicStand",
		Size = size3(box, 2, 0.8, 0.06),
		Position = local3(box, 0, h * 0.15 + 0.6, f * (t / 2 - 0.1)),
		Color = "Black",
		CanCollide = false,
	})
end

-- What each block name becomes. A name not listed stays as built.
local RULES: { [string]: (box: Box) -> boolean } = {}
local function rule(names: { string }, fn: (box: Box) -> (), keep: boolean)
	for _, name in names do
		RULES[name] = function(box: Box): boolean
			fn(box)
			return not keep
		end
	end
end
rule({ "Counter", "Till" }, function(box)
	counter(box, true)
end, false)
rule({
	"BarCounter",
	"Reception",
	"FrontDesk",
	"PrizeCounter",
	"ShoeCounter",
	"SnackCounter",
	"JudgeBench",
	"Workbench",
	"Kiosk",
}, function(box)
	counter(box, false)
end, false)
rule({ "Kitchen" }, kitchen, false)
rule({ "Shelf", "Bookshelf", "MagazineRack", "PrizeShelf", "GoodsRack", "BallRack" }, shelf, false)
rule({ "Lockers" }, function(box)
	cabinet(box, 3, false)
end, true)
rule({ "Wardrobe", "Fridge" }, function(box)
	cabinet(box, 2, false)
end, true)
rule({ "FilingCabinet", "Nightstand" }, function(box)
	cabinet(box, if box.h > 3 then 3 else 1, true)
end, true)
rule({ "LowTable", "CoffeeTable", "CanteenTable", "BoothTable", "Display", "AirHockey", "Altar" }, tableFrom, false)
rule({ "CanteenBench" }, function(box)
	benchFrom(box, false)
end, false)
rule({ "Pew", "JuryBench" }, function(box)
	benchFrom(box, true)
end, false)
rule({ "WallTV" }, tv, false)
rule({ "Menu", "Whiteboard", "MapBoard" }, function(box)
	framed(box, 3)
end, true)
rule({ "Poster", "Painting", "Mural" }, function(box)
	framed(box, 0)
end, true)
rule({ "KaraokeScreen" }, function(box)
	framed(box, 0)
end, true)
rule({ "Toilet" }, toilet, false)
rule({ "Bunk" }, bunk, false)
rule({ "Piano" }, piano, true)

-- Rebuilds every plain block in `container` that RULES (or the stool and clock rules) knows, in place.
function Decor.dressAll(container: any)
	local floors = {}
	local todo = {}
	for _, part in container:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Name == "GroundFloor" then
				table.insert(floors, part)
			elseif RULES[part.Name] or part.Name == "Stool" or part.Name == "WallClock" then
				table.insert(todo, part)
			end
		end
	end
	for _, part in todo do
		local parent = part.Parent
		local replace = true
		B.into(parent, function()
			if part.Name == "Stool" then
				stoolFrom(part)
			elseif part.Name == "WallClock" then
				clock(part)
				replace = false
			else
				-- A thin panel's "front" is either face; a block's faces the middle of its building.
				replace = RULES[part.Name](boxOf(part, floors))
			end
		end)
		if replace then
			part:Destroy()
		end
	end
end

return Decor
