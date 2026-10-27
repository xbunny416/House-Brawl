--!strict
--[[
	Furniture — detailed lobby furniture built from parts (owner, 2026-10-19: "style like the reference … right now it
	looks too blocky, items with no detail"). Every piece is many small parts: rolled sofa arms, cushioned backs,
	piping, wood legs, round seats on iron poles, drum lamp shades, iron dome lamps, potted trees, wood table tops on
	iron bases. Since 2026-10-27 it is a bit less luxury (owner: "make lobby a bit less luxury"): worn iron, old brass
	and wood instead of gold and marble, no button tufting. Real meshes (free Creator Store models or
	Studio's AI generator) could replace any piece later; these keep the look while the game is code-first.

	Each builder takes the floor spot (x, z) and a facing (where the front looks: "North" / "South" / "East" / "West").
	Inside, positions are local: lx to the piece's right, y up from the floor, lz forward (toward its front); sizes are
	in the part's own axes (X width, Y height, Z depth). Seats are Builder.seat (LobbySeat, CanTouch off), upright.
]]
local B = require("./Builder")

local Furniture = {}

type Put = (spec: any) -> any

local YAW: { [string]: number } = { South = 0, North = 180, East = -90, West = 90 }

-- Returns part / seat builders that place local specs around (x, z) turned to `facing`.
local function frame(x: number, z: number, facing: string): (Put, Put)
	local yaw = assert(YAW[facing], `unknown facing {facing}`)
	local cos, sin = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	local function convert(spec: any): any
		local copy = table.clone(spec)
		local lx, y, lz = spec.Position[1], spec.Position[2], spec.Position[3]
		-- The part's +X points (cos, -sin) and its front (-Z) points (-sin, -cos) on the floor (X, Z).
		copy.Position = { x + lx * cos - lz * sin, y, z - lx * sin - lz * cos }
		copy.Yaw = yaw
		return copy
	end
	return function(spec: any): any
		return B.part(convert(spec))
	end, function(spec: any): any
		return B.seat(convert(spec))
	end
end

-- A cylinder standing upright (a pole, or a disc when short).
local function upright(
	put: Put,
	name: string,
	at: { number },
	height: number,
	diameter: number,
	colorName: string,
	material: string?,
	collide: boolean?
)
	return put({
		Name = name,
		Size = { height, diameter, diameter },
		Position = at,
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = colorName,
		Material = material or "SmoothPlastic",
		CanCollide = collide == true,
	})
end

---------------------------------------------------------------------------------------------------------------------
-- Seating
---------------------------------------------------------------------------------------------------------------------

export type SofaOptions = {
	Seats: number,
	Color: string, -- upholstery
	Trim: string?, -- piping and booth channels (default SofaDark)
	Material: string?, -- default Fabric
	TallBack: boolean?, -- booth benches: a taller back with channel tufting
}

--[[
	A sofa / armchair / booth bench: a plinth on short wood legs with a rounded front edge, one Seat cushion per seat
	(with piping along the front), a back with tilted cushions (channels on tall booth backs), and rolled arms.
]]
function Furniture.sofa(name: string, x: number, z: number, facing: string, options: SofaOptions)
	local put, seat = frame(x, z, facing)
	local seats = options.Seats
	local inner = seats * 3
	local width = inner + 1.8
	local fabric = options.Material or "Fabric"
	local trim = options.Trim or "SofaDark"
	local backHeight = if options.TallBack then 4.6 else 2.8
	B.model(name, function()
		put({
			Name = "Plinth",
			Size = { width, 0.9, 3.15 },
			Position = { 0, 0.75, -0.225 },
			Color = options.Color,
			Material = fabric,
		})
		put({
			Name = "FrontRoll",
			Size = { width, 0.9, 0.9 },
			Position = { 0, 0.75, 1.35 },
			Shape = "Cylinder",
			Color = options.Color,
			Material = fabric,
		})
		for _, side in { -1, 1 } do
			for _, end_ in { -1, 1 } do
				upright(put, "Leg", { side * (width / 2 - 0.45), 0.15, end_ * 1.45 }, 0.3, 0.32, "WoodDark", "Wood")
			end
			-- Rolled arm: an upright block topped by a cylinder running front to back.
			put({
				Name = "Arm",
				Size = { 0.9, 1.4, 3.6 },
				Position = { side * (inner / 2 + 0.45), 1.9, 0 },
				Color = options.Color,
				Material = fabric,
			})
			put({
				Name = "ArmRoll",
				Size = { 3.6, 1.1, 1.1 },
				Position = { side * (inner / 2 + 0.45), 2.65, 0 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Color = options.Color,
				Material = fabric,
			})
			put({
				Name = "ArmPiping",
				Size = { 3.6, 0.14, 0.14 },
				Position = { side * (inner / 2 + 0.45), 3.15, 0 },
				Rotation = { 0, 90, 0 },
				Shape = "Cylinder",
				Color = trim,
				Material = fabric,
				CanCollide = false,
			})
		end
		put({
			Name = "Back",
			Size = { width, backHeight, 0.8 },
			Position = { 0, 1.2 + backHeight / 2, -1.4 },
			Color = options.Color,
			Material = fabric,
		})
		put({
			Name = "BackRoll",
			Size = { width, 0.9, 0.9 },
			Position = { 0, 1.2 + backHeight, -1.4 },
			Shape = "Cylinder",
			Color = options.Color,
			Material = fabric,
		})
		for index = 1, seats do
			local lx = (index - (seats + 1) / 2) * 3
			seat({
				Name = `Cushion{index}`,
				Size = { 2.9, 0.7, 2.8 },
				Position = { lx, 1.55, 0.3 },
				Color = options.Color,
				Material = fabric,
			})
			put({
				Name = "Piping",
				Size = { 2.9, 0.14, 0.14 },
				Position = { lx, 1.9, 1.7 },
				Shape = "Cylinder",
				Color = trim,
				Material = fabric,
				CanCollide = false,
			})
			local cushionHeight = backHeight - 0.8
			put({
				Name = "BackCushion",
				Size = { 2.85, cushionHeight, 0.6 },
				Position = { lx, 1.9 + cushionHeight / 2, -0.8 },
				Rotation = { 8, 0, 0 },
				Color = options.Color,
				Material = fabric,
				CanCollide = false,
			})
			if options.TallBack then
				-- Channel tufting: vertical seams down the back cushion (diner booths).
				for _, seam in { -0.7, 0.7 } do
					put({
						Name = "Channel",
						Size = { 0.12, cushionHeight - 0.4, 0.12 },
						Position = { lx + seam, 1.9 + cushionHeight / 2, -0.47 },
						Rotation = { 8, 0, 0 },
						Color = trim,
						Material = fabric,
						CanCollide = false,
					})
				end
			end
		end
	end)
end

-- A bar stool: round cushion with an iron ring on an iron pole, footrest ring and base. The Seat is an invisible block
-- inside the cushion (a round, upright Seat isn't possible: cylinders lie along X).
function Furniture.stool(name: string, x: number, z: number, facing: string, height: number, colorName: string): any
	local put, seat = frame(x, z, facing)
	return B.model(name, function()
		upright(put, "Base", { 0, 0.12, 0 }, 0.25, 2, "Iron", "Metal", true)
		upright(put, "Pole", { 0, height / 2, 0 }, height, 0.35, "Iron", "Metal", true)
		upright(put, "Footrest", { 0, height * 0.4, 0 }, 0.15, 1.7, "Iron", "Metal")
		upright(put, "Rim", { 0, height + 0.05, 0 }, 0.2, 2.35, "Iron", "Metal")
		upright(put, "Cushion", { 0, height + 0.35, 0 }, 0.5, 2.2, colorName, "Leather")
		seat({
			Name = "Seat",
			Size = { 1.6, 0.4, 1.6 },
			Position = { 0, height + 0.4, 0 },
			Color = colorName,
			Material = "Leather",
			Transparency = 1,
		})
	end)
end

--[[
	The arm-wrestling table (ArmWrestleService): a dark wood top with an iron edge and a painted centre line on two posts
	with feet, two elbow pads, two pin pads where a beaten hand lands, two iron grip pegs for the free hands, and a stool
	at each end facing the other. The pull runs along X: side 1 sits at −X facing +X, side 2 at +X facing −X; each
	stool sits a little to its sitter's left so the two right hands meet over the middle. The model is tagged
	ArmWrestleTable; its top is the part "Top" (the board over the table hangs above it); each stool's Seat is tagged
	ArmWrestleSeat with a Side attribute (and stays a LobbySeat, so the normal Sit prompt seats players).
]]
function Furniture.armWrestleTable(name: string, x: number, z: number, top: number, seatHeight: number): any
	local put = frame(x, z, "South")
	-- World offsets (dx, dz) from the table's centre; the "South" frame's lz runs toward −Z.
	local function at(dx: number, y: number, dz: number): { number }
		return { dx, y, -dz }
	end
	local model = B.model(name, function()
		put({
			Name = "Top",
			Size = { 3, 0.35, 3.6 },
			Position = at(0, top - 0.175, 0),
			Color = "WoodDark",
			Material = "Wood",
		})
		put({
			Name = "Edge",
			Size = { 3.2, 0.12, 3.8 },
			Position = at(0, top - 0.3, 0),
			Color = "Iron",
			Material = "Metal",
		})
		put({
			Name = "CentreLine",
			Size = { 0.08, 0.02, 3.4 },
			Position = at(0, top + 0.01, 0),
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		for side, dx in { -1, 1 } do
			-- Side 1 (−X) faces +X, so its right is +Z; side 2's right is −Z.
			local right = if side == 1 then 1 else -1
			upright(put, `ElbowPad{side}`, at(dx * 0.6, top + 0.05, right * 0.15), 0.1, 0.9, "SofaDark", "Leather")
			put({
				Name = `PinPad{side}`,
				Size = { 1, 0.08, 0.7 },
				Position = at(0, top + 0.04, -right * 1.25),
				Color = "Sofa",
				Material = "Leather",
				CanCollide = false,
			})
			upright(put, `GripPeg{side}`, at(dx * 0.95, top + 0.35, -right * 1.25), 0.7, 0.22, "Iron", "Metal")
			upright(put, `GripKnob{side}`, at(dx * 0.95, top + 0.72, -right * 1.25), 0.12, 0.34, "Iron", "Metal")
		end
		-- Two posts on feet, off to the sides so the sitters' legs fit under the top.
		for _, dz in { -1.4, 1.4 } do
			upright(put, "Post", at(0, (top - 0.36) / 2, dz), top - 0.36, 0.45, "WoodDark", "Wood", true)
			put({
				Name = "Foot",
				Size = { 2.4, 0.25, 0.5 },
				Position = at(0, 0.125, dz),
				Color = "WoodDark",
				Material = "Wood",
			})
			upright(put, "Collar", at(0, top - 0.6, dz), 0.15, 0.6, "Iron", "Metal")
		end
	end)
	for side, dx in { -1, 1 } do
		local right = if side == 1 then 1 else -1
		local stool = Furniture.stool(
			`Stool{side}`,
			x + dx * 1.8,
			z - right * 0.5,
			if side == 1 then "East" else "West",
			seatHeight,
			"Sofa"
		)
		stool.Parent = model
		local seat = stool:FindFirstChild("Seat")
		seat:AddTag("ArmWrestleSeat")
		seat:SetAttribute("Side", side)
	end
	model:AddTag("ArmWrestleTable")
	return model
end

--[[
	The chess table (ChessService): a square dark wood table with an iron edge on a pedestal with a cross foot, a board of
	64 squares in a wood frame, and a stool at each end facing the other. White plays from −X (side 1), Black from +X
	(side 2): ranks run toward +X, files a → h toward +Z (White's right). The board's frame is the part "Board" with a
	SquareSize attribute; square (file f, rank r, 0-7) sits at Board.CFrame * (( r − 3.5 ) × size, top, ( f − 3.5 ) ×
	size), where the client stands the pieces (ChessController). The model is tagged ChessTable; each stool's Seat is
	tagged ChessSeat with a Side attribute (and stays a LobbySeat, so the normal Sit prompt seats players).
]]
function Furniture.chessTable(name: string, x: number, z: number, top: number, seatHeight: number): any
	local put = frame(x, z, "South")
	local square = 0.55
	local frameSize = square * 8 + 0.5
	-- World offsets (dx, dz) from the table's centre; the "South" frame's lz runs toward −Z.
	local function at(dx: number, y: number, dz: number): { number }
		return { dx, y, -dz }
	end
	local model = B.model(name, function()
		put({
			Name = "Top",
			Size = { 5.4, 0.3, 5.4 },
			Position = at(0, top - 0.15, 0),
			Color = "WoodDark",
			Material = "Wood",
		})
		put({
			Name = "Edge",
			Size = { 5.6, 0.12, 5.6 },
			Position = at(0, top - 0.24, 0),
			Color = "Iron",
			Material = "Metal",
		})
		upright(put, "Pedestal", at(0, (top - 0.3) / 2, 0), top - 0.3, 1, "WoodDark", "Wood", true)
		upright(put, "Collar", at(0, top - 0.55, 0), 0.15, 1.4, "Iron", "Metal")
		for _, size in { { 3.4, 0.3, 0.6 }, { 0.6, 0.3, 3.4 } } do
			put({ Name = "Foot", Size = size, Position = at(0, 0.15, 0), Color = "WoodDark", Material = "Wood" })
		end
		local board = put({
			Name = "Board",
			Size = { frameSize, 0.1, frameSize },
			Position = at(0, top + 0.05, 0),
			Color = "WoodMid",
			Material = "Wood",
		})
		board:SetAttribute("SquareSize", square)
		for rank = 0, 7 do
			for file = 0, 7 do
				put({
					Name = "Square",
					Size = { square, 0.02, square },
					Position = at((rank - 3.5) * square, top + 0.11, (file - 3.5) * square),
					Color = if (rank + file) % 2 == 0 then "ChessDark" else "ChessLight",
					Material = "SmoothPlastic",
					CanCollide = false,
					CastShadow = false,
				})
			end
		end
	end)
	for side, dx in { -1, 1 } do
		local stool =
			Furniture.stool(`Stool{side}`, x + dx * 3.4, z, if side == 1 then "East" else "West", seatHeight, "Sofa")
		stool.Parent = model
		local seat = stool:FindFirstChild("Seat")
		seat:AddTag("ChessSeat")
		seat:SetAttribute("Side", side)
	end
	model:AddTag("ChessTable")
	return model
end

---------------------------------------------------------------------------------------------------------------------
-- Tables
---------------------------------------------------------------------------------------------------------------------

-- A round wood table on an iron pedestal (the lounge's coffee table; tall = a high table).
function Furniture.roundTable(name: string, x: number, z: number, diameter: number, height: number)
	local put = frame(x, z, "South")
	B.model(name, function()
		upright(put, "Top", { 0, height, 0 }, 0.35, diameter, "WoodMid", "Wood", true)
		upright(put, "Rim", { 0, height - 0.12, 0 }, 0.2, diameter + 0.3, "WoodDark", "Wood")
		upright(put, "Apron", { 0, height - 0.3, 0 }, 0.2, diameter * 0.45, "Iron", "Metal")
		upright(put, "Pedestal", { 0, (height - 0.3) / 2, 0 }, height - 0.4, 0.7, "Iron", "Metal", true)
		upright(put, "Collar", { 0, height * 0.35, 0 }, 0.25, 1.3, "Iron", "Metal")
		upright(put, "Foot", { 0, 0.12, 0 }, 0.25, math.min(diameter * 0.55, 3.4), "Iron", "Metal", true)
	end)
end

-- A rectangular wood booth table on an iron pedestal.
function Furniture.boothTable(name: string, x: number, z: number)
	local put = frame(x, z, "South")
	B.model(name, function()
		put({ Name = "Top", Size = { 6, 0.35, 3.4 }, Position = { 0, 3, 0 }, Color = "WoodMid", Material = "Wood" })
		put({
			Name = "Edge",
			Size = { 6.3, 0.15, 3.7 },
			Position = { 0, 2.78, 0 },
			Color = "WoodDark",
			Material = "Wood",
		})
		upright(put, "Pedestal", { 0, 1.4, 0 }, 2.8, 0.6, "Iron", "Metal", true)
		put({ Name = "Foot", Size = { 3, 0.25, 1.6 }, Position = { 0, 0.12, 0 }, Color = "Iron", Material = "Metal" })
	end)
end

-- A dark rug with a black border, a faded rust ring and rust corner marks.
function Furniture.rug(x: number, z: number, sizeX: number, sizeZ: number, ring: number)
	local put = frame(x, z, "South")
	B.model("Rug", function()
		local function flat(name: string, size: { number }, y: number, colorName: string, material: string)
			put({
				Name = name,
				Size = size,
				Position = { 0, y, 0 },
				Color = colorName,
				Material = material,
				CanCollide = false,
				CastShadow = false,
			})
		end
		flat("Border", { sizeX, 0.06, sizeZ }, 0.08, "Black", "Carpet")
		flat("Field", { sizeX - 1.4, 0.06, sizeZ - 1.4 }, 0.1, "Rug", "Carpet")
		upright(put, "Ring", { 0, 0.12, 0 }, 0.06, ring, "RustDark", "Fabric")
		upright(put, "RingInner", { 0, 0.14, 0 }, 0.06, ring - 1.4, "Rug", "Carpet")
		for _, cx in { -1, 1 } do
			for _, cz in { -1, 1 } do
				put({
					Name = "CornerMark",
					Size = { 1.2, 0.06, 1.2 },
					Position = { cx * (sizeX / 2 - 2), 0.12, cz * (sizeZ / 2 - 2) },
					Rotation = { 0, 45, 0 },
					Color = "RustDark",
					Material = "Fabric",
					CanCollide = false,
					CastShadow = false,
				})
			end
		end
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- Lights
---------------------------------------------------------------------------------------------------------------------

-- A floor lamp: weighted base, iron pole with a knob, white drum shade, a glowing bulb.
function Furniture.floorLamp(x: number, z: number)
	local put = frame(x, z, "South")
	B.model("FloorLamp", function()
		upright(put, "Base", { 0, 0.12, 0 }, 0.25, 1.9, "Black", "Metal", true)
		upright(put, "Collar", { 0, 0.32, 0 }, 0.2, 0.9, "Iron", "Metal")
		upright(put, "Pole", { 0, 3.9, 0 }, 7.2, 0.24, "Iron", "Metal", true)
		put({
			Name = "Knob",
			Size = { 0.45, 0.45, 0.45 },
			Position = { 0, 4.6, 0 },
			Shape = "Ball",
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
		})
		upright(put, "Shade", { 0, 8.3, 0 }, 1.9, 2.6, "Shade", "Fabric")
		local bulb = put({
			Name = "Bulb",
			Size = { 0.6, 0.6, 0.6 },
			Position = { 0, 7.9, 0 },
			Shape = "Ball",
			Color = "WarmLight",
			Material = "Neon",
			CanCollide = false,
		})
		B.light(bulb, "WarmLight", 18, 1, true)
	end)
end

-- A pendant lamp hanging from the ceiling at `ceiling`: canopy, chain, a stepped iron dome (a workshop lamp), a bulb.
function Furniture.pendant(x: number, y: number, z: number, ceiling: number, range: number)
	local put = frame(x, z, "South")
	B.model("Lamp", function()
		upright(put, "Canopy", { 0, ceiling - 0.15, 0 }, 0.3, 1.2, "Iron", "Metal")
		upright(put, "Chain", { 0, (ceiling + y) / 2 + 0.6, 0 }, ceiling - y - 1.2, 0.12, "Black", "Metal")
		upright(put, "DomeTop", { 0, y + 1, 0 }, 0.5, 1.2, "Iron", "Metal")
		upright(put, "DomeMid", { 0, y + 0.55, 0 }, 0.5, 2.2, "Iron", "Metal")
		upright(put, "DomeRim", { 0, y + 0.1, 0 }, 0.45, 3.2, "Iron", "Metal")
		local bulb = put({
			Name = "Bulb",
			Size = { 0.9, 0.9, 0.9 },
			Position = { 0, y - 0.4, 0 },
			Shape = "Ball",
			Color = "Amber",
			Material = "Neon",
			CanCollide = false,
		})
		B.light(bulb, "WarmLight", range, 1.3, true) -- the main lamps cast soft shadows (Future lighting)
	end)
end

-- A wall lamp: iron backplate and arm, a small white shade with an iron trim and a bulb (`lit`: a soft light).
function Furniture.sconce(x: number, y: number, z: number, facing: string, lit: boolean)
	local put = frame(x, z, facing)
	B.model("WallLamp", function()
		put({
			Name = "Plate",
			Size = { 0.9, 1.4, 0.15 },
			Position = { 0, y, 0.07 },
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
		})
		put({
			Name = "Arm",
			Size = { 0.18, 0.18, 1 },
			Position = { 0, y, 0.6 },
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
		})
		upright(put, "Shade", { 0, y + 0.55, 1.1 }, 1.1, 1.1, "Shade", "Fabric")
		upright(put, "Trim", { 0, y + 0.02, 1.1 }, 0.1, 1.16, "Iron", "Metal")
		local bulb = put({
			Name = "Bulb",
			Size = { 0.35, 0.35, 0.35 },
			Position = { 0, y + 0.3, 1.1 },
			Shape = "Ball",
			Color = "WarmLight",
			Material = "Neon",
			CanCollide = false,
		})
		if lit then
			B.light(bulb, "WarmLight", 14, 0.7)
		end
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- Decor
---------------------------------------------------------------------------------------------------------------------

-- A potted two-tier tree: black pot with an iron band and rim and soil, a trunk, two balls of leaves (owner,
-- 2026-10-27: "want old tree bush, no rusty" — the tree is back after a day as a shrub in a rusty bucket; its pot's
-- trim stays iron, not gold).
function Furniture.plant(x: number, z: number)
	local put = frame(x, z, "South")
	B.model("Plant", function()
		upright(put, "Pot", { 0, 1.3, 0 }, 2.6, 3, "Black", "SmoothPlastic", true)
		upright(put, "PotBand", { 0, 0.3, 0 }, 0.3, 3.1, "Iron", "Metal")
		upright(put, "Rim", { 0, 2.65, 0 }, 0.25, 3.3, "Iron", "Metal")
		upright(put, "Soil", { 0, 2.62, 0 }, 0.2, 2.7, "Soil", "Ground")
		upright(put, "Trunk", { 0, 4.6, 0 }, 4, 0.35, "Wood", "Wood")
		put({
			Name = "Leaves",
			Size = { 4.4, 4.4, 4.4 },
			Position = { 0, 6.9, 0 },
			Shape = "Ball",
			Color = "Leaf",
			Material = "LeafyGrass",
			CanCollide = false,
		})
		put({
			Name = "LeavesTop",
			Size = { 2.8, 2.8, 2.8 },
			Position = { 0, 9.6, 0 },
			Shape = "Ball",
			Color = "Leaf",
			Material = "LeafyGrass",
			CanCollide = false,
		})
	end)
end

-- A dark wood pillar against a wall: iron base and capital bands, and a wall lamp facing into the room.
function Furniture.pillar(x: number, z: number, facing: string, height: number, lit: boolean)
	local put = frame(x, z, facing)
	B.model("Pillar", function()
		put({
			Name = "Post",
			Size = { 2.4, height, 2.4 },
			Position = { 0, height / 2, 0 },
			Color = "WoodDark",
			Material = "Wood",
			CastShadow = false,
		})
		put({ Name = "Base", Size = { 2.9, 0.8, 2.9 }, Position = { 0, 0.4, 0 }, Color = "WoodDark", Material = "Wood" })
		put({
			Name = "BaseBand",
			Size = { 3, 0.2, 3 },
			Position = { 0, 0.9, 0 },
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
		})
		put({
			Name = "Capital",
			Size = { 3, 0.6, 3 },
			Position = { 0, height - 0.3, 0 },
			Color = "WoodDark",
			Material = "Wood",
		})
		put({
			Name = "CapitalBand",
			Size = { 3.1, 0.2, 3.1 },
			Position = { 0, height - 0.75, 0 },
			Color = "Iron",
			Material = "Metal",
			CanCollide = false,
		})
	end)
	local lampX = x - math.sin(math.rad(YAW[facing])) * 1.2
	local lampZ = z - math.cos(math.rad(YAW[facing])) * 1.2
	Furniture.sconce(lampX, 11, lampZ, facing, lit)
end

--[[
	Wainscoting `length` long along a wall, centred on (x, z) on the wall's inner face and facing into the room: a
	dark wood skin with a baseboard, framed raised panels, a wood cap and a wood rail on top.
]]
function Furniture.wainscot(x: number, z: number, facing: string, length: number, height: number)
	local put = frame(x, z, facing)
	B.model("Wainscot", function()
		put({
			Name = "Skin",
			Size = { length, height, 0.5 },
			Position = { 0, height / 2, 0.25 },
			Color = "WoodDark",
			Material = "Wood",
			CastShadow = false,
		})
		put({
			Name = "Baseboard",
			Size = { length, 0.8, 0.8 },
			Position = { 0, 0.4, 0.4 },
			Color = "WoodDark",
			Material = "Wood",
			CastShadow = false,
		})
		put({
			Name = "Rail",
			Size = { length, 0.3, 0.9 },
			Position = { 0, height + 0.15, 0.45 },
			Color = "WoodMid",
			Material = "Wood",
			CastShadow = false,
		})
		put({
			Name = "Cap",
			Size = { length, 0.25, 0.7 },
			Position = { 0, height - 0.12, 0.4 },
			Color = "WoodMid",
			Material = "Wood",
			CastShadow = false,
		})
		local count = math.max(1, math.floor(length / 9))
		local panel = length / count
		for index = 1, count do
			local lx = -length / 2 + (index - 0.5) * panel
			local w, h, y = panel - 1.6, height - 2.6, height / 2 + 0.2
			put({
				Name = "Panel",
				Size = { w, h, 0.12 },
				Position = { lx, y, 0.56 },
				Color = "Brick",
				Material = "Wood",
				CanCollide = false,
				CastShadow = false,
			})
			for _, edge in
				{
					{ size = { w + 0.5, 0.25, 0.2 }, at = { lx, y + h / 2 + 0.12 } },
					{ size = { w + 0.5, 0.25, 0.2 }, at = { lx, y - h / 2 - 0.12 } },
					{ size = { 0.25, h, 0.2 }, at = { lx - w / 2 - 0.12, y } },
					{ size = { 0.25, h, 0.2 }, at = { lx + w / 2 + 0.12, y } },
				}
			do
				put({
					Name = "Molding",
					Size = edge.size,
					Position = { edge.at[1], edge.at[2], 0.6 },
					Color = "WoodMid",
					Material = "Wood",
					CanCollide = false,
					CastShadow = false,
				})
			end
		end
	end)
end

-- A glass bottle standing on a shelf: body, shoulder, neck and cap.
function Furniture.bottle(x: number, y: number, z: number, colorName: string, tall: boolean)
	local put = frame(x, z, "South")
	local body = if tall then 1.3 else 0.9
	upright(put, "Bottle", { 0, y + body / 2, 0 }, body, 0.55, colorName, "Glass")
	upright(put, "Shoulder", { 0, y + body + 0.1, 0 }, 0.2, 0.4, colorName, "Glass")
	upright(put, "Neck", { 0, y + body + 0.4, 0 }, 0.45, 0.2, colorName, "Glass")
	upright(put, "Cap", { 0, y + body + 0.67, 0 }, 0.1, 0.24, "Metal", "Metal")
end

-- A pool table: framed wood body on turned legs, green felt with cushioned rails, six pockets, pearl diamonds, balls.
function Furniture.poolTable(x: number, z: number, facing: string)
	local put = frame(x, z, facing)
	B.model("PoolTable", function()
		put({ Name = "Body", Size = { 14, 1.4, 8 }, Position = { 0, 2.3, 0 }, Color = "WoodDark", Material = "Wood" })
		for _, lx in { -6.2, 6.2 } do
			for _, lz in { -3.2, 3.2 } do
				upright(put, "Leg", { lx, 0.8, lz }, 1.6, 1.1, "WoodDark", "Wood", true)
				upright(put, "Foot", { lx, 0.1, lz }, 0.2, 1.3, "Iron", "Metal")
			end
		end
		put({ Name = "Felt", Size = { 12.6, 0.2, 6.6 }, Position = { 0, 3.05, 0 }, Color = "Felt", Material = "Fabric" })
		for _, rail in
			{
				{ size = { 14, 0.5, 0.7 }, at = { 0, 3.3, 3.65 } },
				{ size = { 14, 0.5, 0.7 }, at = { 0, 3.3, -3.65 } },
				{ size = { 0.7, 0.5, 6.6 }, at = { 6.65, 3.3, 0 } },
				{ size = { 0.7, 0.5, 6.6 }, at = { -6.65, 3.3, 0 } },
			}
		do
			put({ Name = "Rail", Size = rail.size, Position = rail.at, Color = "WoodDark", Material = "Wood" })
		end
		for _, pocket in { { -6.3, -3.3 }, { 0, -3.4 }, { 6.3, -3.3 }, { -6.3, 3.3 }, { 0, 3.4 }, { 6.3, 3.3 } } do
			upright(put, "Pocket", { pocket[1], 3.2, pocket[2] }, 0.12, 0.9, "Black")
		end
		for _, lx in { -3.5, 0, 3.5 } do
			for _, lz in { -3.65, 3.65 } do
				put({
					Name = "Diamond",
					Size = { 0.25, 0.06, 0.25 },
					Position = { lx, 3.58, lz },
					Rotation = { 0, 45, 0 },
					Color = "OffWhite",
					Material = "SmoothPlastic",
					CanCollide = false,
				})
			end
		end
		for index, ball in
			{
				{ -3, 1, "NeonOrange" },
				{ -2, -1.5, "OffWhite" },
				{ 2, 0.5, "Black" },
				{ 4, -1, "Teal" },
				{ 3.4, 1.4, "LaneYellow" },
			}
		do
			put({
				Name = `Ball{index}`,
				Size = { 0.6, 0.6, 0.6 },
				Position = { ball[1], 3.45, ball[2] },
				Shape = "Ball",
				Color = ball[3],
				CanCollide = false,
			})
		end
	end)
end

return Furniture
