--!strict
--[[
	Pieces — street and industrial set pieces the arenas are shaped with (owner, 2026-10-20: "more dynamic, not just
	flat platforms, more layers, more detail"): ramps and stairs between levels, railings, concrete road barriers,
	columns, lamp posts, tyre stacks, crates and shipping containers. Each is several parts with real detail. Positions
	are from the current origin (on a platform: its top centre, so y = 0 is the floor); `y` lifts a piece onto a
	higher surface. Solid pieces collide (they are cover, steps and floors); trims and lights don't.
]]
local B = require("./Builder")

local Pieces = {}

type Vec = { number }

-- Yaw (degrees) that turns a part's +Z toward the direction (dx, dz).
local function yawToward(dx: number, dz: number): number
	return math.deg(math.atan2(dx, dz))
end

-- A wedge ramp from `low` (x, z; at height `y`) up to `high` (`rise` above it), `width` across.
function Pieces.ramp(
	name: string,
	low: Vec,
	high: Vec,
	width: number,
	rise: number,
	color: string,
	material: string,
	y: number?
)
	local base = y or 0
	local dx, dz = high[1] - low[1], high[2] - low[2]
	local length = math.sqrt(dx * dx + dz * dz)
	return B.part({
		Name = name,
		Size = { width, rise, length },
		Position = { (low[1] + high[1]) / 2, base + rise / 2, (low[2] + high[2]) / 2 },
		Rotation = { 0, yawToward(dx, dz), 0 }, -- a wedge's tall end is its +Z
		Shape = "Wedge",
		Color = color,
		Material = material,
		CastShadow = true,
	})
end

-- A solid block standing on `y` (default the floor): `at` is its footprint centre (x, z).
function Pieces.block(name: string, at: Vec, size: Vec, color: string, material: string, y: number?, yaw: number?): any
	return B.part({
		Name = name,
		Size = size,
		Position = { at[1], (y or 0) + size[2] / 2, at[2] },
		Rotation = if yaw then { 0, yaw, 0 } else nil,
		Color = color,
		Material = material,
	})
end

-- Steps climbing from `start` (x, z of the bottom step's outer edge) toward `toward` ("+X" / "-X" / "+Z" / "-Z"):
-- `count` steps of `rise` up and `run` deep, `width` across, each solid down to `y`.
function Pieces.stairs(
	name: string,
	start: Vec,
	toward: string,
	width: number,
	count: number,
	rise: number,
	run: number,
	color: string,
	material: string,
	y: number?
)
	local base = y or 0
	local axis = if toward == "+X" or toward == "-X" then "X" else "Z"
	local sign = if toward == "+X" or toward == "+Z" then 1 else -1
	for step = 1, count do
		local along = (step - 0.5) * run * sign
		local height = step * rise
		local x = start[1] + (if axis == "X" then along else 0)
		local z = start[2] + (if axis == "Z" then along else 0)
		B.part({
			Name = name,
			Size = if axis == "X" then { run, height, width } else { width, height, run },
			Position = { x, base + height / 2, z },
			Color = color,
			Material = material,
		})
		-- A bright nosing strip on each step's edge.
		local edge = (step - 1) * run * sign
		B.part({
			Name = `{name}Nosing`,
			Size = if axis == "X" then { 0.3, 0.06, width } else { width, 0.06, 0.3 },
			Position = {
				start[1] + (if axis == "X" then edge + 0.15 * sign else 0),
				base + height + 0.03,
				start[2] + (if axis == "Z" then edge + 0.15 * sign else 0),
			},
			Color = "LaneYellow",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
end

-- A steel railing from `a` to `b` (x, z) standing on `y`: posts every 3 studs, a top rail and a mid rail.
function Pieces.railing(name: string, a: Vec, b: Vec, y: number, height: number?, color: string?)
	local tall = height or 1.4
	local paint = color or "Metal"
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local length = math.sqrt(dx * dx + dz * dz)
	local yaw = yawToward(dx, dz)
	for _, rail in { { tall, 0.18 }, { tall * 0.5, 0.12 } } do
		B.part({
			Name = name,
			Size = { rail[2], rail[2], length },
			Position = { (a[1] + b[1]) / 2, y + rail[1], (a[2] + b[2]) / 2 },
			Rotation = { 0, yaw, 0 },
			Color = paint,
			Material = "Metal",
			CanCollide = rail[1] == tall,
		})
	end
	local posts = math.max(1, math.floor(length / 3))
	for index = 0, posts do
		local t = index / posts
		B.part({
			Name = `{name}Post`,
			Size = { 0.2, tall, 0.2 },
			Position = { a[1] + dx * t, y + tall / 2, a[2] + dz * t },
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
	end
end

-- A concrete road barrier (jersey profile: wide foot, sloped middle, narrow top) `length` long, turned `yaw`,
-- with a reflector every 3 studs and optional orange-and-white stripes.
function Pieces.jersey(name: string, at: Vec, length: number, yaw: number, y: number?, striped: boolean?)
	local base = y or 0
	local turn = { 0, yaw, 0 }
	local color = if striped then "RustOrange" else "Concrete"
	B.part({
		Name = name,
		Size = { length, 0.6, 1.8 },
		Position = { at[1], base + 0.3, at[2] },
		Rotation = turn,
		Color = color,
		Material = "Concrete",
	})
	B.part({
		Name = name,
		Size = { length, 0.9, 1.2 },
		Position = { at[1], base + 1.05, at[2] },
		Rotation = turn,
		Color = color,
		Material = "Concrete",
	})
	B.part({
		Name = name,
		Size = { length, 1.1, 0.7 },
		Position = { at[1], base + 2.05, at[2] },
		Rotation = turn,
		Color = color,
		Material = "Concrete",
	})
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	local count = math.max(1, math.floor(length / 3))
	for index = 1, count do
		local along = -length / 2 + (index - 0.5) * length / count
		for _, side in { -1, 1 } do
			-- Along the barrier's X (rotated by yaw) and out to its side.
			local lx, lz = along, side * 0.37
			local x = at[1] + lx * c + lz * s
			local z = at[2] - lx * s + lz * c
			B.part({
				Name = `{name}Reflector`,
				Size = { if striped then length / count * 0.45 else 0.35, if striped then 0.9 else 0.2, 0.05 },
				Position = { x, base + (if striped then 2.05 else 2.3), z },
				Rotation = turn,
				Color = if striped then "OffWhite" else "LaneYellow",
				Material = if striped then "SmoothPlastic" else "Neon",
				CanCollide = false,
			})
		end
	end
end

-- A round or square column from `bottom` to `top` at `at` (x, z).
function Pieces.column(
	name: string,
	at: Vec,
	bottom: number,
	top: number,
	width: number,
	color: string,
	material: string,
	round: boolean?
)
	local height = top - bottom
	if round then
		B.part({
			Name = name,
			Size = { height, width, width },
			Position = { at[1], bottom + height / 2, at[2] },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = color,
			Material = material,
		})
	else
		B.part({
			Name = name,
			Size = { width, height, width },
			Position = { at[1], bottom + height / 2, at[2] },
			Color = color,
			Material = material,
		})
		-- A cap at the top.
		B.part({
			Name = `{name}Cap`,
			Size = { width + 0.6, 0.5, width + 0.6 },
			Position = { at[1], top - 0.25, at[2] },
			Color = color,
			Material = material,
			CanCollide = false,
		})
	end
end

-- A highway lamp post: a pole, an arm reaching toward `yaw`, a lamp head with a warm light; `bright` lights it.
function Pieces.lamp(name: string, at: Vec, height: number, yaw: number, y: number?, bright: boolean?)
	local base = y or 0
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	B.part({
		Name = name,
		Size = { 0.7, 0.4, 0.7 },
		Position = { at[1], base + 0.2, at[2] },
		Color = "MetalDark",
		Material = "Metal",
	})
	B.part({
		Name = name,
		Size = { height, 0.45, 0.45 },
		Position = { at[1], base + height / 2, at[2] },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "Metal",
		Material = "Metal",
	})
	-- The arm reaches 3 studs out along the yaw's −Z (its front).
	local armX, armZ = at[1] - s * 1.5, at[2] - c * 1.5
	B.part({
		Name = `{name}Arm`,
		Size = { 0.3, 0.3, 3 },
		Position = { armX, base + height - 0.2, armZ },
		Rotation = { 0, yaw, 0 },
		Color = "Metal",
		Material = "Metal",
		CanCollide = false,
	})
	local headX, headZ = at[1] - s * 3, at[2] - c * 3
	B.part({
		Name = `{name}Head`,
		Size = { 1, 0.35, 1.8 },
		Position = { headX, base + height - 0.35, headZ },
		Rotation = { 0, yaw, 0 },
		Color = "MetalDark",
		Material = "Metal",
		CanCollide = false,
	})
	local glow = B.part({
		Name = `{name}Light`,
		Size = { 0.8, 0.1, 1.5 },
		Position = { headX, base + height - 0.57, headZ },
		Rotation = { 0, yaw, 0 },
		Color = "WarmLight",
		Material = "Neon",
		CanCollide = false,
		CastShadow = false,
	})
	if bright then
		B.light(glow, "WarmLight", 26, 1.4)
	end
end

-- A stack of `count` tyres (each a rubber ring with a darker hole) standing on `y`.
function Pieces.tires(name: string, at: Vec, count: number, y: number?)
	local base = y or 0
	for index = 1, count do
		local offset = if index % 2 == 0 then 0.25 else -0.2
		local center = base + (index - 0.5) * 1.05
		B.part({
			Name = name,
			Size = { 1.05, 3.4, 3.4 },
			Position = { at[1] + offset, center, at[2] - offset },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "Black",
			Material = "SmoothPlastic",
		})
		B.part({
			Name = `{name}Hole`,
			Size = { 1.07, 1.6, 1.6 },
			Position = { at[1] + offset, center, at[2] - offset },
			Rotation = { 0, 0, 90 },
			Shape = "Cylinder",
			Color = "AsphaltDark",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
	end
end

-- A wooden crate standing on `y`: planked box with lighter edge beams.
function Pieces.crate(name: string, at: Vec, size: number, y: number?, yaw: number?)
	local base = y or 0
	local turn = { 0, yaw or 0, 0 }
	B.part({
		Name = name,
		Size = { size, size, size },
		Position = { at[1], base + size / 2, at[2] },
		Rotation = turn,
		Color = "Wood",
		Material = "WoodPlanks",
	})
	for _, h in { 0.12, size - 0.12 } do
		B.part({
			Name = `{name}Band`,
			Size = { size + 0.08, 0.24, size + 0.08 },
			Position = { at[1], base + h, at[2] },
			Rotation = turn,
			Color = "Cork",
			Material = "Wood",
			CanCollide = false,
		})
	end
end

-- A shipping container `size` (x, y, z) standing on `y`, turned `yaw`: ribbed sides, corner posts, doors with
-- locking bars on its +X end.
function Pieces.container(name: string, at: Vec, size: Vec, yaw: number, color: string, y: number?)
	local base = y or 0
	local turn = { 0, yaw, 0 }
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	local function place(lx: number, ly: number, lz: number): Vec
		return { at[1] + lx * c + lz * s, base + ly, at[2] - lx * s + lz * c }
	end
	B.part({
		Name = name,
		Size = size,
		Position = place(0, size[2] / 2, 0),
		Rotation = turn,
		Color = color,
		Material = "CorrodedMetal",
		CastShadow = true,
	})
	-- Ribs along both long sides.
	local ribs = math.floor(size[1] / 1.6)
	for index = 1, ribs - 1 do
		local lx = -size[1] / 2 + index * size[1] / ribs
		for _, side in { -1, 1 } do
			B.part({
				Name = `{name}Rib`,
				Size = { 0.25, size[2] - 0.6, 0.12 },
				Position = place(lx, size[2] / 2, side * (size[3] / 2 + 0.06)),
				Rotation = turn,
				Color = color,
				Material = "CorrodedMetal",
				CanCollide = false,
			})
		end
	end
	-- Corner posts and the door end's locking bars.
	for _, cx in { -1, 1 } do
		for _, cz in { -1, 1 } do
			B.part({
				Name = `{name}Corner`,
				Size = { 0.4, size[2], 0.4 },
				Position = place(cx * (size[1] / 2 - 0.15), size[2] / 2, cz * (size[3] / 2 - 0.15)),
				Rotation = turn,
				Color = "MetalDark",
				Material = "Metal",
				CanCollide = false,
			})
		end
	end
	for index = 1, 4 do
		local lz = -size[3] / 2 + index * size[3] / 5
		B.part({
			Name = `{name}Bar`,
			Size = { 0.12, size[2] - 0.8, 0.12 },
			Position = place(size[1] / 2 + 0.07, size[2] / 2, lz),
			Rotation = turn,
			Color = "MetalDark",
			Material = "Metal",
			CanCollide = false,
		})
	end
end

-- Rebar sticking out of a broken concrete edge: `count` thin rods along (from `a` to `b`) at height `y`, bent out.
function Pieces.rebar(name: string, a: Vec, b: Vec, y: number, count: number, outward: number)
	for index = 1, count do
		local t = (index - 0.5) / count
		B.part({
			Name = name,
			Size = { 0.15, 0.15, 2.2 + (index % 3) * 0.6 },
			Position = { a[1] + (b[1] - a[1]) * t, y + (index % 2) * 0.4, a[2] + (b[2] - a[2]) * t },
			Rotation = { (index % 4) * 8 - 12, outward + (index % 3) * 9 - 9, 0 },
			Color = "RustDark",
			Material = "CorrodedMetal",
			CanCollide = false,
		})
	end
end

-- A wrecked city bus `length` long standing on `y`, turned `yaw` (its length along its X): body, a band of
-- windows, a windscreen, doors, a roof vent and six wheels. You can climb onto its roof (5.5 up).
function Pieces.bus(name: string, at: Vec, length: number, yaw: number, color: string, y: number?)
	local base = y or 0
	local turn = { 0, yaw, 0 }
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	local function place(lx: number, ly: number, lz: number): Vec
		return { at[1] + lx * c + lz * s, base + ly, at[2] - lx * s + lz * c }
	end
	B.part({
		Name = name,
		Size = { length, 4.4, 8 },
		Position = place(0, 3.3, 0),
		Rotation = turn,
		Color = color,
		Material = "Metal",
		CastShadow = true,
	})
	B.part({
		Name = `{name}Skirt`,
		Size = { length - 1, 1.1, 7.6 },
		Position = place(0, 0.55, 0),
		Rotation = turn,
		Color = "MetalDark",
		Material = "Metal",
	})
	for _, side in { -1, 1 } do
		B.part({
			Name = `{name}Windows`,
			Size = { length - 5, 1.6, 0.1 },
			Position = place(0.8, 4, side * 4.02),
			Rotation = turn,
			Color = "Glass",
			Material = "Glass",
			Transparency = 0.35,
			CanCollide = false,
		})
		B.part({
			Name = `{name}Stripe`,
			Size = { length, 0.4, 0.08 },
			Position = place(0, 2.4, side * 4.03),
			Rotation = turn,
			Color = "OffWhite",
			Material = "SmoothPlastic",
			CanCollide = false,
		})
		for _, lx in { -length / 2 + 4, -length / 2 + 7.5, length / 2 - 5 } do
			B.part({
				Name = `{name}Wheel`,
				Size = { 0.6, 2.4, 2.4 },
				Position = place(lx, 1.2, side * 3.75),
				Rotation = { 0, yaw + 90, 0 },
				Shape = "Cylinder",
				Color = "Black",
				Material = "SmoothPlastic",
				CanCollide = false,
			})
		end
	end
	B.part({
		Name = `{name}Windscreen`,
		Size = { 0.1, 2.2, 7.2 },
		Position = place(length / 2 + 0.02, 3.9, 0),
		Rotation = turn,
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.35,
		CanCollide = false,
	})
	B.part({
		Name = `{name}Door`,
		Size = { 2.6, 3.6, 0.1 },
		Position = place(length / 2 - 3, 2.9, -4.03),
		Rotation = turn,
		Color = "Glass",
		Material = "Glass",
		Transparency = 0.5,
		CanCollide = false,
	})
	B.part({
		Name = `{name}Vent`,
		Size = { 4, 0.4, 3 },
		Position = place(-length / 4, 5.7, 0),
		Rotation = turn,
		Color = "Metal",
		Material = "Metal",
		CanCollide = false,
	})
end

-- A concrete planter (2 high, you can stand on it) with soil and a dead tree.
function Pieces.planter(name: string, at: Vec, size: number)
	B.part({
		Name = name,
		Size = { size, 1.6, size },
		Position = { at[1], 0.8, at[2] },
		Color = "Concrete",
		Material = "Concrete",
	})
	B.part({
		Name = `{name}Soil`,
		Size = { size - 0.8, 0.1, size - 0.8 },
		Position = { at[1], 1.62, at[2] },
		Color = "Soil",
		Material = "Ground",
		CanCollide = false,
	})
	B.part({
		Name = `{name}Trunk`,
		Size = { 8, 0.9, 0.9 },
		Position = { at[1], 5.6, at[2] },
		Rotation = { 0, 0, 90 },
		Shape = "Cylinder",
		Color = "Soil",
		Material = "Wood",
	})
	for index, branch in { { 35, 0 }, { -40, 120 }, { 30, 230 }, { -25, 300 } } do
		local lean, around = math.rad(branch[1]), math.rad(branch[2])
		B.part({
			Name = `{name}Branch`,
			Size = { 0.35, 3.2 - index * 0.3, 0.35 },
			Position = {
				at[1] + math.sin(lean) * math.cos(around) * 1.4,
				7 + index * 0.6,
				at[2] + math.sin(lean) * math.sin(around) * 1.4,
			},
			Rotation = { 0, branch[2], branch[1] },
			Color = "Soil",
			Material = "Wood",
			CanCollide = false,
		})
	end
end

return Pieces
