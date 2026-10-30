--!strict
--[[
	ItemShapes — what the props and breakable structures look like (owner, 2026-10-20: "more detail in every item").
	Pure data, so a spec checks every shape stays inside its item's box. Each item keeps its Config size as an
	invisible box that does the colliding, the hit checks and the physics; these parts are welded onto it and only
	show. assets/Models.luau builds each item's template (ReplicatedStorage.Assets.Models) from them.

	A shape: Shape ("Block", "Cylinder", "Ball", "Wedge"), Size (the part's own X, Y, Z; a cylinder lies along X, so
	Upright turns it to stand along Y and Facing turns it to point along Z), At (from the item's centre: X right, Y up,
	−Z the item's front), Turn (degrees X, Y, Z, after Upright / Facing), Color (hex; nil = the item's colour times
	Tint), Material (nil = the item's), Transparency, Reflectance, and Lit (glows when an explosive barrel is lit).
]]
export type Shape = {
	Shape: string,
	Size: { number },
	At: { number },
	Turn: { number }?,
	Upright: boolean?,
	Facing: boolean?,
	Color: string?,
	Tint: number?,
	Material: string?,
	Transparency: number?,
	Reflectance: number?,
	Lit: boolean?,
}

local ItemShapes = {}

-- Shared colours.
local STEEL = "#9A9EA3"
local CHROME = "#C9CED6"
local RUBBER = "#262626"
local DARK = "#1C1C1F"
local GLASS = "#9FD6E0"
local WHITE = "#F2F2F2"
local AMBER = "#F2C14E"
local RED_LIGHT = "#C9302C"

local function block(size: { number }, at: { number }, extra: { [string]: any }?): Shape
	local shape: { [string]: any } = { Shape = "Block", Size = size, At = at }
	local options: { [string]: any } = extra or {}
	for key, value in options do
		shape[key] = value
	end
	return shape :: any
end

-- A cylinder standing up: `diameter` across, `height` tall.
local function upright(diameter: number, height: number, at: { number }, extra: { [string]: any }?): Shape
	local shape = block({ height, diameter, diameter }, at, extra)
	shape.Shape = "Cylinder"
	shape.Upright = true
	return shape
end

-- A cylinder lying along X (a wheel's axle), or along Z with Facing (a knob on a front face).
local function lying(diameter: number, length: number, at: { number }, extra: { [string]: any }?): Shape
	local shape = block({ length, diameter, diameter }, at, extra)
	shape.Shape = "Cylinder"
	return shape
end

local function ball(diameter: number, at: { number }, extra: { [string]: any }?): Shape
	local shape = block({ diameter, diameter, diameter }, at, extra)
	shape.Shape = "Ball"
	return shape
end

-- The same shapes made `factor` times bigger about the item's centre (sizes and offsets; turns stay).
local function scaled(shapes: { Shape }, factor: number): { Shape }
	local out: { Shape } = {}
	for _, shape in shapes do
		local copy: { [string]: any } = table.clone(shape :: any)
		copy.Size = { shape.Size[1] * factor, shape.Size[2] * factor, shape.Size[3] * factor }
		copy.At = { shape.At[1] * factor, shape.At[2] * factor, shape.At[3] * factor }
		table.insert(out, copy :: any)
	end
	return out
end

-- Appends every shape of `more` to `list`.
local function add(list: { Shape }, more: { Shape }): { Shape }
	for _, shape in more do
		table.insert(list, shape)
	end
	return list
end

---------------------------------------------------------------------------------------------------------------------
-- Props (Config.Props.Types)
---------------------------------------------------------------------------------------------------------------------

-- A steel drum: body, rolling hoops, rims, lid and bung (the explosive one adds a hazard band).
local function drum(lit: boolean?): { Shape }
	local function paint(extra: { [string]: any }?): { [string]: any }
		local merged: { [string]: any } = { Lit = lit }
		local options: { [string]: any } = extra or {}
		for key, value in options do
			merged[key] = value
		end
		return merged
	end
	return {
		upright(2.06, 2.96, { 0, 0, 0 }, paint()),
		upright(2.2, 0.14, { 0, -0.5, 0 }, paint({ Tint = 0.75 })),
		upright(2.2, 0.14, { 0, 0.5, 0 }, paint({ Tint = 0.75 })),
		upright(2.14, 0.1, { 0, -1.42, 0 }, paint({ Tint = 0.8 })),
		upright(2.14, 0.1, { 0, 1.42, 0 }, paint({ Tint = 0.8 })),
		upright(1.86, 0.04, { 0, 1.49, 0 }, paint({ Tint = 0.65 })),
		upright(0.3, 0.08, { 0.55, 1.52, 0.3 }, { Color = STEEL, Material = "Metal" }),
		upright(0.22, 0.06, { -0.6, 1.51, -0.2 }, { Color = STEEL, Material = "Metal" }),
	}
end

ItemShapes.Props = {
	-- A folding steel chair, its seat facing −Z.
	Chair = {
		block({ 1.8, 0.14, 1.7 }, { 0, -0.12, -0.05 }),
		block({ 1.7, 0.06, 1.6 }, { 0, -0.03, -0.05 }, { Tint = 0.7, Material = "Fabric" }),
		block({ 0.12, 1.32, 0.12 }, { 0.8, -0.84, -0.72 }, { Color = STEEL }),
		block({ 0.12, 1.32, 0.12 }, { -0.8, -0.84, -0.72 }, { Color = STEEL }),
		block({ 0.12, 2.9, 0.12 }, { 0.82, -0.05, 0.82 }, { Color = STEEL, Turn = { -6, 0, 0 } }),
		block({ 0.12, 2.9, 0.12 }, { -0.82, -0.05, 0.82 }, { Color = STEEL, Turn = { -6, 0, 0 } }),
		block({ 1.7, 0.9, 0.12 }, { 0, 0.85, 0.88 }, { Turn = { -6, 0, 0 } }),
		block({ 1.5, 0.08, 0.08 }, { 0, -1.1, -0.72 }, { Color = STEEL }),
		block({ 1.5, 0.08, 0.08 }, { 0, -1.1, 0.75 }, { Color = STEEL }),
	},
	-- A metal bucket with rim, bands, a dark inside and its handle folded down.
	Bucket = {
		upright(1.36, 1.5, { 0, -0.03, 0 }),
		upright(1.5, 0.1, { 0, 0.74, 0 }, { Tint = 1.15 }),
		upright(1.2, 0.04, { 0, 0.71, 0 }, { Color = "#3A3A3A" }),
		upright(1.42, 0.08, { 0, -0.5, 0 }, { Tint = 0.8 }),
		upright(1.42, 0.08, { 0, 0.3, 0 }, { Tint = 0.8 }),
		block({ 1.5, 0.06, 0.06 }, { 0, 0.78, 0.3 }, { Color = STEEL }),
		lying(0.14, 0.06, { 0.72, 0.6, 0 }, { Color = STEEL }),
		lying(0.14, 0.06, { -0.72, 0.6, 0 }, { Color = STEEL }),
	},
	-- A tyre lying flat: rubber with treads, sidewall lines, a steel rim, hub and lug nuts.
	Tire = (function(): { Shape }
		local shapes = {
			upright(2.6, 1, { 0, 0, 0 }),
			upright(2.2, 1.02, { 0, 0, 0 }, { Color = "#3A3A3A" }),
			upright(1.5, 1.04, { 0, 0, 0 }, { Color = "#A8ADB3", Material = "Metal" }),
			upright(0.7, 1.08, { 0, 0, 0 }, { Color = "#8C9096", Material = "Metal" }),
		}
		for index = 0, 4 do
			local angle = index / 5 * 2 * math.pi
			table.insert(
				shapes,
				upright(0.12, 1.1, { math.cos(angle) * 0.5, 0, math.sin(angle) * 0.5 }, { Color = DARK })
			)
		end
		for index = 0, 9 do
			local angle = index / 10 * 2 * math.pi
			table.insert(
				shapes,
				block(
					{ 0.12, 0.9, 0.3 },
					{ math.cos(angle) * 1.28, 0, math.sin(angle) * 1.28 },
					{ Turn = { 0, -math.deg(angle), 0 }, Tint = 0.7 }
				)
			)
		end
		return shapes
	end)(),
	-- A traffic cone: a square base and stepped orange cone with two reflective white bands.
	TrafficCone = {
		block({ 1.4, 0.14, 1.4 }, { 0, -1.03, 0 }, { Tint = 0.8 }),
		upright(1.0, 0.45, { 0, -0.74, 0 }),
		upright(0.88, 0.22, { 0, -0.41, 0 }, { Color = WHITE }),
		upright(0.82, 0.25, { 0, -0.18, 0 }),
		upright(0.7, 0.45, { 0, 0.16, 0 }),
		upright(0.6, 0.16, { 0, 0.46, 0 }, { Color = WHITE }),
		upright(0.52, 0.3, { 0, 0.69, 0 }),
		upright(0.38, 0.25, { 0, 0.97, 0 }),
	},
	-- A wooden crate: planked box, lighter edge beams and a diagonal brace on the front and back.
	Crate = (function(): { Shape }
		local beam = { Color = "#B98552", Material = "Wood" }
		local shapes = { block({ 2.84, 2.84, 2.84 }, { 0, 0, 0 }, { Tint = 0.85 }) }
		for _, x in { -1.34, 1.34 } do
			for _, z in { -1.34, 1.34 } do
				table.insert(shapes, block({ 0.32, 3, 0.32 }, { x, 0, z }, beam))
			end
		end
		for _, y in { -1.34, 1.34 } do
			for _, z in { -1.34, 1.34 } do
				table.insert(shapes, block({ 3, 0.32, 0.32 }, { 0, y, z }, beam))
			end
			for _, x in { -1.34, 1.34 } do
				table.insert(shapes, block({ 0.32, 0.32, 3 }, { x, y, 0 }, beam))
			end
		end
		for _, z in { -1.44, 1.44 } do
			table.insert(shapes, block({ 0.3, 3.4, 0.12 }, { 0, 0, z }, { Turn = { 0, 0, 45 }, Color = "#B98552" }))
		end
		return shapes
	end)(),
	-- An old CRT television: wood-look case, deep back, dark screen in a bezel, knobs, speaker, rabbit-ear antenna.
	TV = {
		block({ 2.6, 2, 1.4 }, { 0, -0.1, -0.4 }),
		block({ 1.8, 1.5, 0.8 }, { 0, -0.15, 0.7 }, { Tint = 0.7 }),
		block({ 2.1, 1.6, 0.04 }, { -0.2, 0, -1.1 }, { Color = DARK }),
		block({ 1.9, 1.4, 0.06 }, { -0.2, 0, -1.12 }, { Color = "#2E4A4E", Reflectance = 0.15 }),
		lying(0.22, 0.08, { 1.0, 0.3, -1.12 }, { Facing = true, Color = "#C9B79C" }),
		lying(0.22, 0.08, { 1.0, -0.2, -1.12 }, { Facing = true, Color = "#C9B79C" }),
		block({ 0.4, 0.5, 0.03 }, { 1.0, -0.68, -1.11 }, { Color = DARK }),
		block({ 0.06, 0.45, 0.06 }, { 0.22, 0.98, 0.4 }, { Color = CHROME, Turn = { 0, 0, -55 } }),
		block({ 0.06, 0.45, 0.06 }, { -0.22, 0.98, 0.4 }, { Color = CHROME, Turn = { 0, 0, 55 } }),
		ball(0.14, { 0, 0.92, 0.4 }, { Color = DARK }),
	},
	-- A corroded steel drum.
	Barrel = drum(),
	-- A street trash can: a ribbed green can on a dark foot ring, a domed lid with a handle, a white sticker.
	TrashCan = {
		upright(1.8, 2.3, { 0, -0.25, 0 }),
		upright(1.9, 0.12, { 0, -1.32, 0 }, { Tint = 0.6 }),
		upright(1.86, 0.1, { 0, -0.6, 0 }, { Tint = 0.8 }),
		upright(1.86, 0.1, { 0, 0.3, 0 }, { Tint = 0.8 }),
		upright(1.98, 0.3, { 0, 1.05, 0 }, { Tint = 1.15 }),
		upright(1.4, 0.12, { 0, 1.26, 0 }, { Tint = 1.15 }),
		block({ 0.5, 0.08, 0.14 }, { 0, 1.36, 0 }, { Color = STEEL, Material = "Metal" }),
		block({ 0.7, 0.5, 0.02 }, { 0, 0, -0.91 }, { Color = WHITE, Material = "SmoothPlastic" }),
	},
	-- A bar stool: a round red seat on a chrome post, a foot ring, a heavy dark base.
	Stool = {
		upright(1.36, 0.3, { 0, 0.95, 0 }),
		upright(1.2, 0.06, { 0, 1.07, 0 }, { Tint = 1.15 }),
		upright(0.24, 1.6, { 0, 0, 0 }, { Color = CHROME, Material = "Metal" }),
		upright(0.9, 0.08, { 0, -0.45, 0 }, { Color = CHROME, Material = "Metal" }),
		upright(1.1, 0.14, { 0, -1.03, 0 }, { Color = DARK, Material = "Metal" }),
	},
	-- A red paper lantern: a glowing ball with two ribs, black caps, a hook and a gold tassel.
	PaperLantern = {
		ball(1.36, { 0, 0, 0 }, { Material = "Neon" }),
		upright(1.25, 0.06, { 0, 0.3, 0 }, { Tint = 0.6 }),
		upright(1.25, 0.06, { 0, -0.3, 0 }, { Tint = 0.6 }),
		upright(0.8, 0.14, { 0, 0.72, 0 }, { Color = DARK }),
		upright(0.8, 0.14, { 0, -0.72, 0 }, { Color = DARK }),
		upright(0.12, 0.18, { 0, 0.88, 0 }, { Color = DARK, Material = "Metal" }),
		upright(0.14, 0.2, { 0, -0.89, 0 }, { Color = AMBER }),
	},
	-- A potted plant: a concrete pot with a rim and soil, a stem, two balls of leaves.
	PottedPlant = {
		upright(1.3, 1.2, { 0, -0.9, 0 }),
		upright(1.4, 0.12, { 0, -0.3, 0 }, { Tint = 1.2 }),
		upright(1.2, 0.04, { 0, -0.25, 0 }, { Color = "#3B2A1E", Material = "Ground" }),
		upright(0.14, 0.5, { 0, -0.05, 0 }, { Color = "#4A3324", Material = "Wood" }),
		ball(1.6, { 0, 0.6, 0 }, { Color = "#4E8A3E", Material = "LeafyGrass" }),
		ball(1.0, { 0.15, 0.95, -0.1 }, { Color = "#5E9C48", Material = "LeafyGrass" }),
	},
	-- A swivel office chair: a padded seat and back, armrests, a chrome gas post, a five-wheel star base.
	OfficeChair = {
		block({ 1.7, 0.3, 1.7 }, { 0, -0.1, -0.05 }),
		block({ 1.6, 1.5, 0.2 }, { 0, 0.9, 0.8 }),
		block({ 0.15, 0.8, 0.15 }, { 0, 0.05, 0.8 }, { Color = DARK, Material = "Metal" }),
		block({ 0.15, 0.1, 1 }, { 0.85, 0.45, -0.05 }, { Color = DARK }),
		block({ 0.15, 0.1, 1 }, { -0.85, 0.45, -0.05 }, { Color = DARK }),
		block({ 0.1, 0.5, 0.1 }, { 0.85, 0.2, 0.1 }, { Color = DARK }),
		block({ 0.1, 0.5, 0.1 }, { -0.85, 0.2, 0.1 }, { Color = DARK }),
		upright(0.25, 0.9, { 0, -0.7, 0 }, { Color = CHROME, Material = "Metal" }),
		block({ 1.8, 0.12, 0.2 }, { 0, -1.25, 0 }, { Color = DARK, Material = "Metal" }),
		block({ 0.2, 0.12, 1.8 }, { 0, -1.25, 0 }, { Color = DARK, Material = "Metal" }),
		ball(0.3, { 0.85, -1.5, 0 }, { Color = RUBBER }),
		ball(0.3, { -0.85, -1.5, 0 }, { Color = RUBBER }),
		ball(0.3, { 0, -1.5, 0.85 }, { Color = RUBBER }),
		ball(0.3, { 0, -1.5, -0.85 }, { Color = RUBBER }),
	},
	-- A flat computer screen: a thin frame and dark glass, a bulge at the back, a neck, a foot, a green power light.
	Monitor = {
		block({ 2.2, 1.3, 0.15 }, { 0, 0.25, -0.2 }),
		block({ 2, 1.1, 0.04 }, { 0, 0.27, -0.29 }, { Color = "#1E3A4E", Reflectance = 0.2 }),
		block({ 1.2, 0.8, 0.2 }, { 0, 0.25, -0.02 }, { Tint = 0.8 }),
		block({ 0.2, 0.5, 0.12 }, { 0, -0.55, 0 }, { Color = DARK }),
		block({ 0.9, 0.08, 0.6 }, { 0, -0.86, 0 }, { Color = DARK }),
		block({ 0.08, 0.04, 0.02 }, { 0.9, -0.33, -0.29 }, { Color = "#4FD07A", Material = "Neon" }),
	},
	-- A red plastic shopping basket: a floor and four sides, two handles, some shopping inside.
	ShoppingBasket = {
		block({ 1.8, 0.1, 1.2 }, { 0, -0.6, 0 }),
		block({ 1.8, 0.9, 0.08 }, { 0, -0.15, 0.6 }),
		block({ 1.8, 0.9, 0.08 }, { 0, -0.15, -0.6 }),
		block({ 0.08, 0.9, 1.2 }, { 0.9, -0.15, 0 }),
		block({ 0.08, 0.9, 1.2 }, { -0.9, -0.15, 0 }),
		block({ 0.1, 0.1, 1.2 }, { 0.4, 0.62, 0 }, { Color = DARK }),
		block({ 0.1, 0.1, 1.2 }, { -0.4, 0.62, 0 }, { Color = DARK }),
		block({ 0.5, 0.5, 0.4 }, { -0.4, -0.3, 0.1 }, { Color = AMBER }),
		upright(0.35, 0.6, { 0.3, -0.25, -0.2 }, { Color = "#3FA7B5" }),
	},
	-- A bowling pin: a white body and belly, a slim neck with two red stripes, a round head, a flat foot.
	BowlingPin = {
		upright(0.76, 1.1, { 0, -0.55, 0 }),
		ball(0.8, { 0, -0.5, 0 }),
		upright(0.36, 0.7, { 0, 0.35, 0 }),
		upright(0.4, 0.08, { 0, 0.25, 0 }, { Color = RED_LIGHT }),
		upright(0.38, 0.08, { 0, 0.4, 0 }, { Color = RED_LIGHT }),
		ball(0.5, { 0, 0.88, 0 }),
		upright(0.5, 0.1, { 0, -1.15, 0 }, { Tint = 0.9 }),
	},
	-- A fire extinguisher: a red cylinder with a domed top, a valve and handle, a black hose, a white label.
	FireExtinguisher = {
		upright(0.8, 1.7, { 0, -0.25, 0 }),
		ball(0.8, { 0, 0.6, 0 }),
		upright(0.25, 0.25, { 0, 0.95, 0 }, { Color = DARK }),
		block({ 0.5, 0.08, 0.15 }, { 0.05, 1.05, 0 }, { Color = DARK }),
		block({ 0.1, 0.9, 0.1 }, { 0.38, 0.2, 0 }, { Color = DARK, Material = "Fabric" }),
		block({ 0.4, 0.6, 0.02 }, { 0, -0.3, -0.41 }, { Color = WHITE, Material = "SmoothPlastic" }),
	},
	-- A stack of five books, a little askew, page edges showing.
	BookStack = {
		block({ 1.5, 0.26, 1.1 }, { 0, -0.57, 0 }),
		block({ 1.4, 0.24, 1 }, { 0.05, -0.32, 0.02 }, { Color = "#2E4A7A", Turn = { 0, 6, 0 } }),
		block({ 1.5, 0.28, 1.1 }, { -0.03, -0.06, -0.02 }, { Color = "#3C7A4A" }),
		block({ 1.3, 0.24, 1 }, { 0.04, 0.2, 0 }, { Color = "#C9A227", Turn = { 0, -8, 0 } }),
		block({ 1.4, 0.26, 1.05 }, { 0, 0.46, 0.01 }, { Color = "#7A2E5A" }),
		block({ 1.42, 0.2, 0.02 }, { 0, -0.57, -0.56 }, { Color = WHITE }),
	},
	-- A red metal toolbox: a box and lid, a handle on two posts, chrome latches.
	Toolbox = {
		block({ 1.96, 0.9, 0.96 }, { 0, -0.2, 0 }),
		block({ 2, 0.2, 1 }, { 0, 0.32, 0 }, { Tint = 0.85 }),
		block({ 0.9, 0.1, 0.15 }, { 0, 0.6, 0 }, { Color = DARK }),
		block({ 0.1, 0.2, 0.15 }, { 0.4, 0.5, 0 }, { Color = DARK }),
		block({ 0.1, 0.2, 0.15 }, { -0.4, 0.5, 0 }, { Color = DARK }),
		block({ 0.2, 0.2, 0.04 }, { 0.5, 0.2, -0.48 }, { Color = CHROME }),
		block({ 0.2, 0.2, 0.04 }, { -0.5, 0.2, -0.48 }, { Color = CHROME }),
	},
	-- A loudspeaker: a black cabinet, a grille, a woofer and a tweeter, a handle, steel corners.
	Speaker = {
		block({ 2, 3.2, 1.6 }, { 0, 0, 0.1 }),
		block({ 1.8, 3, 0.06 }, { 0, 0, -0.73 }, { Color = "#2E2E33", Material = "Fabric" }),
		lying(1.3, 0.12, { 0, -0.6, -0.8 }, { Facing = true, Color = "#3A3A3A" }),
		lying(0.5, 0.14, { 0, -0.6, -0.82 }, { Facing = true, Color = DARK }),
		lying(0.5, 0.12, { 0, 0.8, -0.8 }, { Facing = true, Color = "#3A3A3A" }),
		block({ 0.8, 0.1, 0.2 }, { 0, 1.55, 0.1 }, { Color = STEEL, Material = "Metal" }),
		block({ 0.15, 0.15, 1.6 }, { 0.92, 1.53, 0.1 }, { Color = STEEL, Material = "Metal" }),
		block({ 0.15, 0.15, 1.6 }, { -0.92, 1.53, 0.1 }, { Color = STEEL, Material = "Metal" }),
		block({ 0.15, 0.15, 1.6 }, { 0.92, -1.53, 0.1 }, { Color = STEEL, Material = "Metal" }),
		block({ 0.15, 0.15, 1.6 }, { -0.92, -1.53, 0.1 }, { Color = STEEL, Material = "Metal" }),
	},
	-- A hard suitcase: a ribbed shell, a handle on two posts, two wheels, a luggage tag.
	Suitcase = {
		block({ 2.1, 2.4, 0.9 }, { 0, -0.1, 0 }),
		block({ 2.14, 0.08, 0.94 }, { 0, 0.5, 0 }, { Tint = 0.8 }),
		block({ 2.14, 0.08, 0.94 }, { 0, -0.7, 0 }, { Tint = 0.8 }),
		block({ 0.8, 0.12, 0.2 }, { 0, 1.3, 0 }, { Color = DARK }),
		block({ 0.1, 0.2, 0.15 }, { 0.35, 1.18, 0 }, { Color = DARK }),
		block({ 0.1, 0.2, 0.15 }, { -0.35, 1.18, 0 }, { Color = DARK }),
		ball(0.3, { 0.8, -1.25, 0.3 }, { Color = RUBBER }),
		ball(0.3, { -0.8, -1.25, 0.3 }, { Color = RUBBER }),
		block({ 0.3, 0.4, 0.04 }, { 0.6, 0.6, -0.47 }, { Color = AMBER }),
	},
	-- A bowling ball: glossy, three finger holes, a swirl band.
	BowlingBall = {
		ball(1.58, { 0, 0, 0 }, { Reflectance = 0.2 }),
		lying(0.22, 0.1, { 0.2, 0.55, -0.53 }, { Facing = true, Color = DARK }),
		lying(0.22, 0.1, { -0.2, 0.55, -0.53 }, { Facing = true, Color = DARK }),
		lying(0.26, 0.1, { 0, 0.1, -0.74 }, { Facing = true, Color = DARK }),
		upright(1.6, 0.06, { 0, -0.2, 0 }, { Tint = 1.3 }),
	},
	-- A concrete cinderblock: two dark holes through it, a chipped corner.
	Cinderblock = {
		block({ 2.36, 1.16, 1.16 }, { 0, 0, 0 }),
		block({ 0.8, 0.04, 0.6 }, { -0.55, 0.58, 0 }, { Color = "#4A4640" }),
		block({ 0.8, 0.04, 0.6 }, { 0.55, 0.58, 0 }, { Color = "#4A4640" }),
		block({ 0.8, 0.04, 0.6 }, { -0.55, -0.58, 0 }, { Color = "#4A4640" }),
		block({ 0.8, 0.04, 0.6 }, { 0.55, -0.58, 0 }, { Color = "#4A4640" }),
		block({ 0.3, 0.3, 0.1 }, { 1, 0.3, -0.55 }, { Tint = 0.8 }),
	},
	-- A red jerry can: a ribbed body, a handle on two posts, a yellow spout with a black cap.
	GasCan = {
		block({ 1.6, 1.4, 0.9 }, { 0, -0.2, 0 }),
		block({ 1.62, 0.08, 0.92 }, { 0, -0.5, 0 }, { Tint = 0.8 }),
		block({ 1.62, 0.08, 0.92 }, { 0, 0.1, 0 }, { Tint = 0.8 }),
		block({ 0.9, 0.12, 0.3 }, { -0.2, 0.74, 0 }, { Tint = 0.9 }),
		block({ 0.12, 0.3, 0.3 }, { -0.6, 0.6, 0 }, { Tint = 0.9 }),
		block({ 0.12, 0.3, 0.3 }, { 0.2, 0.6, 0 }, { Tint = 0.9 }),
		upright(0.3, 0.4, { 0.6, 0.7, 0 }, { Color = AMBER }),
		upright(0.34, 0.1, { 0.6, 0.85, 0 }, { Color = DARK }),
	},
	-- A shop mannequin on a stand: legs, a torso in a red top, arms, a neck and head, a chrome pole, a round foot.
	Mannequin = {
		block({ 1.4, 1.8, 0.7 }, { 0, 0.7, 0 }),
		block({ 1.44, 1, 0.74 }, { 0, 1.05, 0 }, { Color = "#C8463C", Material = "Fabric" }),
		block({ 0.3, 1.6, 0.4 }, { 0.64, 0.6, 0 }),
		block({ 0.3, 1.6, 0.4 }, { -0.64, 0.6, 0 }),
		upright(0.3, 0.3, { 0, 1.65, 0 }),
		ball(0.8, { 0, 2.1, 0 }),
		block({ 0.5, 2, 0.5 }, { 0.33, -1.2, 0 }),
		block({ 0.5, 2, 0.5 }, { -0.33, -1.2, 0 }),
		upright(0.2, 0.4, { 0, -2.4, 0 }, { Color = CHROME, Material = "Metal" }),
		upright(1, 0.1, { 0, -2.65, 0 }, { Color = DARK }),
	},
	-- The explosive drum: red, with a yellow hazard band and black warning diamonds; it glows when lit.
	ExplosiveBarrel = add(drum(true), {
		upright(2.1, 0.5, { 0, 0, 0 }, { Color = "#E8C547" }),
		block({ 0.45, 0.45, 0.04 }, { 0, 0, -1.06 }, { Color = DARK, Turn = { 0, 0, 45 } }),
		block({ 0.45, 0.45, 0.04 }, { 0, 0, 1.06 }, { Color = DARK, Turn = { 0, 0, 45 } }),
	}),
	-- A fridge: body, freezer and main doors, chrome handles, feet and a rust patch.
	Fridge = {
		block({ 2.9, 5.4, 2.7 }, { 0, 0, 0.1 }),
		block({ 2.86, 1.5, 0.12 }, { 0, 1.85, -1.3 }, { Tint = 1.04 }),
		block({ 2.86, 3.7, 0.12 }, { 0, -0.85, -1.3 }, { Tint = 1.04 }),
		block({ 2.86, 0.06, 0.1 }, { 0, 1.07, -1.33 }, { Color = "#8C877C" }),
		block({ 0.12, 0.8, 0.12 }, { 1.15, 1.6, -1.42 }, { Color = CHROME, Material = "Metal" }),
		block({ 0.12, 1.6, 0.12 }, { 1.15, 0.2, -1.42 }, { Color = CHROME, Material = "Metal" }),
		block({ 0.6, 0.4, 0.04 }, { -0.8, -2.0, -1.37 }, { Color = "#8A5A32", Material = "Metal" }),
		block({ 0.3, 0.12, 0.3 }, { 1.2, -2.69, 1.2 }, { Color = DARK }),
		block({ 0.3, 0.12, 0.3 }, { -1.2, -2.69, 1.2 }, { Color = DARK }),
		block({ 0.3, 0.12, 0.3 }, { 1.2, -2.69, -1.2 }, { Color = DARK }),
		block({ 0.3, 0.12, 0.3 }, { -1.2, -2.69, -1.2 }, { Color = DARK }),
	},
	-- A torn-off car door: panel, window glass in its frame, chrome handle and trim, the wing mirror.
	CarDoor = {
		block({ 4.4, 1.8, 0.4 }, { 0, -0.6, 0 }),
		block({ 4, 0.16, 0.3 }, { 0.2, 1.4, 0 }),
		block({ 0.16, 1.1, 0.3 }, { -1.75, 0.85, 0 }),
		block({ 0.16, 1.1, 0.3 }, { 2.15, 0.85, 0 }),
		block({ 3.6, 1.0, 0.08 }, { 0.2, 0.85, 0 }, { Color = GLASS, Material = "Glass", Transparency = 0.5 }),
		block({ 0.6, 0.14, 0.12 }, { 1.4, -0.2, -0.22 }, { Color = CHROME, Material = "Metal" }),
		block({ 4.4, 0.08, 0.06 }, { 0, -0.1, -0.22 }, { Color = CHROME, Material = "Metal" }),
		block({ 0.5, 0.35, 0.35 }, { -1.9, 0.5, -0.05 }, { Tint = 0.8 }),
	},
	-- A broken-off vending machine corner: shell, shelves with cans and a cracked glass shard.
	VendingChunk = {
		block({ 2.9, 2.9, 0.3 }, { 0, 0, 0.85 }),
		block({ 0.3, 2.9, 1.9 }, { 1.35, 0, 0 }),
		block({ 2.9, 0.25, 1.9 }, { 0, -1.37, 0 }),
		block({ 2.2, 0.3, 1.9 }, { 0.35, 1.35, 0 }, { Turn = { 0, 0, -6 } }),
		block({ 2.6, 0.08, 1.5 }, { -0.15, -0.8, 0.05 }, { Color = DARK }),
		block({ 2.6, 0.08, 1.5 }, { -0.15, 0.2, 0.05 }, { Color = DARK }),
		upright(0.3, 0.5, { -0.8, -0.5, -0.2 }, { Color = "#E5484D" }),
		upright(0.3, 0.5, { -0.3, -0.5, -0.2 }, { Color = "#3FA7B5" }),
		upright(0.3, 0.5, { 0.3, -0.5, -0.2 }, { Color = AMBER }),
		upright(0.3, 0.5, { -0.6, 0.5, -0.2 }, { Color = "#6FA556" }),
		upright(0.3, 0.5, { 0.1, 0.5, -0.2 }, { Color = "#E5484D" }),
		block(
			{ 1.2, 1.4, 0.05 },
			{ -0.8, 0.2, -0.9 },
			{ Color = GLASS, Material = "Glass", Transparency = 0.5, Turn = { 0, 0, 15 } }
		),
	},
}

---------------------------------------------------------------------------------------------------------------------
-- Breakable structures (Config.Structures.Types)
---------------------------------------------------------------------------------------------------------------------

ItemShapes.Structures = {
	-- A rusted wreck: body, hood and trunk, a caved-in roof on pillars, cracked windows, three wheels and a bare
	-- drum, chrome bumpers, lights and grille, rust patches.
	-- (Life-size beside an avatar since 2026-10-28: the owner, "match avatar size". Drawn at its old size, scaled up.)
	WreckedCar = scaled(
		(function(): { Shape }
			local glass = { Color = GLASS, Material = "Glass", Transparency = 0.55 }
			local shapes = {
				block({ 4.4, 1.4, 8.8 }, { 0, -0.6, 0 }),
				block({ 4.2, 0.3, 2.6 }, { 0, 0.2, -2.9 }, { Turn = { -4, 0, 0 }, Tint = 1.08 }),
				block({ 4.2, 0.3, 1.8 }, { 0, 0.2, 3.3 }, { Tint = 1.08 }),
				block({ 3.8, 0.25, 3.4 }, { 0, 1.62, 0.4 }, { Turn = { 0, 0, 4 }, Tint = 1.08 }),
				-- The windscreen and rear window lean back over the cabin.
				block(
					{ 3.5, 1.3, 0.08 },
					{ 0, 0.95, -1.75 },
					{ Turn = { -32, 0, 0 }, Color = GLASS, Material = "Glass", Transparency = 0.55 }
				),
				block(
					{ 3.5, 1.2, 0.08 },
					{ 0, 0.95, 2.45 },
					{ Turn = { 30, 0, 0 }, Color = GLASS, Material = "Glass", Transparency = 0.55 }
				),
				block({ 0.06, 0.95, 3.0 }, { 1.86, 0.98, 0.4 }, glass),
				block({ 0.06, 0.95, 3.0 }, { -1.86, 0.98, 0.4 }, glass),
				block({ 4.5, 0.4, 0.3 }, { 0, -0.9, -4.42 }, { Color = CHROME, Material = "Metal" }),
				block({ 4.5, 0.4, 0.3 }, { 0, -0.9, 4.42 }, { Color = CHROME, Material = "Metal" }),
				block({ 0.7, 0.35, 0.1 }, { 1.4, -0.25, -4.42 }, { Color = "#F5E6B8", Material = "Glass" }),
				block({ 0.7, 0.35, 0.1 }, { -1.4, -0.25, -4.42 }, { Color = "#F5E6B8", Material = "Glass" }),
				block({ 0.7, 0.3, 0.1 }, { 1.5, -0.25, 4.42 }, { Color = RED_LIGHT, Material = "Glass" }),
				block({ 0.7, 0.3, 0.1 }, { -1.5, -0.25, 4.42 }, { Color = RED_LIGHT, Material = "Glass" }),
				block({ 1.8, 0.45, 0.1 }, { 0, -0.35, -4.43 }, { Color = DARK }),
				block({ 0.04, 0.6, 1.4 }, { 2.21, -0.7, 1.5 }, { Color = "#5A2E1E", Material = "Metal" }),
				block({ 0.04, 0.5, 1.1 }, { -2.21, -0.5, -1.8 }, { Color = "#5A2E1E", Material = "Metal" }),
			}
			-- Pillars hold up the roof.
			for _, x in { -1.84, 1.84 } do
				table.insert(shapes, block({ 0.2, 1.4, 0.2 }, { x, 0.95, -1.75 }, { Turn = { -32, 0, 0 }, Tint = 0.9 }))
				table.insert(shapes, block({ 0.2, 1.3, 0.2 }, { x, 0.95, 0.4 }, { Tint = 0.9 }))
				table.insert(shapes, block({ 0.2, 1.3, 0.2 }, { x, 0.95, 2.45 }, { Turn = { 30, 0, 0 }, Tint = 0.9 }))
			end
			-- Wheels (one gone: a bare brake drum), each with a hubcap.
			for _, wheel in { { 2.0, -2.8 }, { -2.0, -2.8 }, { 2.0, 2.8 } } do
				table.insert(shapes, lying(1.7, 0.6, { wheel[1], -0.95, wheel[2] }, { Color = RUBBER }))
				table.insert(
					shapes,
					lying(0.8, 0.62, { wheel[1], -0.95, wheel[2] }, { Color = CHROME, Material = "Metal" })
				)
			end
			table.insert(shapes, lying(0.9, 0.4, { -1.95, -1.1, 2.8 }, { Color = "#5A5550", Material = "Metal" }))
			return shapes
		end)(),
		1.35
	),
	-- A drinks machine: red cabinet, lit sign, glass front with shelves of cans, the control panel with buttons and
	-- coin slot, the pickup bin and a kick plate.
	VendingMachine = (function(): { Shape }
		local shapes = {
			block({ 3.9, 6.9, 2.8 }, { 0, 0, 0.1 }),
			block({ 3.7, 1.1, 0.06 }, { 0, 2.95, -1.33 }, { Color = DARK }),
			block({ 3.5, 0.9, 0.08 }, { 0, 2.95, -1.36 }, { Color = "#F5E6B8", Material = "Neon" }),
			block({ 2.5, 4.6, 0.05 }, { -0.55, 0.15, -0.9 }, { Color = DARK }),
			block(
				{ 2.5, 4.6, 0.06 },
				{ -0.55, 0.15, -1.36 },
				{ Color = "#BFE3EA", Material = "Glass", Transparency = 0.6 }
			),
			block({ 0.9, 4.6, 0.06 }, { 1.35, 0.15, -1.36 }, { Color = "#2B2D31" }),
			block({ 0.3, 0.08, 0.04 }, { 1.35, 0, -1.4 }, { Color = CHROME, Material = "Metal" }),
			block({ 0.4, 0.25, 0.04 }, { 1.35, -0.45, -1.4 }, { Color = DARK }),
			block({ 2.6, 0.7, 0.06 }, { -0.55, -2.6, -1.36 }, { Color = DARK }),
			block({ 2.4, 0.5, 0.04 }, { -0.55, -2.6, -1.4 }, { Color = "#5A5550" }),
			block({ 3.9, 0.4, 0.1 }, { 0, -3.28, -1.36 }, { Color = DARK }),
		}
		for index = 0, 5 do
			table.insert(shapes, block({ 0.22, 0.16, 0.05 }, { 1.35, 1.6 - index * 0.25, -1.4 }, { Color = "#E8E8E8" }))
		end
		local cans = { "#E5484D", "#3FA7B5", AMBER, "#6FA556" }
		for shelf, y in { -1.8, -0.6, 0.6, 1.8 } do
			table.insert(shapes, block({ 2.4, 0.08, 0.4 }, { -0.55, y, -1.1 }, { Color = STEEL, Material = "Metal" }))
			for slot = 0, 3 do
				local color = cans[(shelf + slot) % #cans + 1]
				table.insert(shapes, upright(0.32, 0.6, { -1.5 + slot * 0.62, y + 0.34, -1.1 }, { Color = color }))
			end
		end
		return shapes
	end)(),
	-- Two concrete road barriers, one on the other, with reflective white panels and amber warning lamps on top.
	RoadBarrierStack = (function(): { Shape }
		local shapes = {
			block({ 8, 0.45, 2.3 }, { 0, -1.275, 0 }),
			block({ 8, 0.95, 1.3 }, { 0, -0.6, 0 }),
			block({ 6.4, 0.4, 1.9 }, { 0.4, 0.075, 0 }, { Tint = 0.92 }),
			block({ 6.4, 0.9, 1.1 }, { 0.4, 0.725, 0 }, { Tint = 0.92 }),
		}
		for _, x in { -3, -1, 1, 3 } do
			for _, z in { -0.67, 0.67 } do
				table.insert(shapes, block({ 0.9, 0.5, 0.04 }, { x, -0.6, z }, { Color = WHITE }))
			end
		end
		for _, x in { -2, 0.4, 2.8 } do
			for _, z in { -0.57, 0.57 } do
				table.insert(shapes, block({ 0.9, 0.45, 0.04 }, { x, 0.725, z }, { Color = WHITE }))
			end
		end
		for _, x in { -2.2, 2.6 } do
			table.insert(shapes, block({ 0.12, 0.25, 0.12 }, { x, 1.3, 0 }, { Color = DARK }))
			table.insert(shapes, upright(0.35, 0.2, { x, 1.45, 0 }, { Color = AMBER, Material = "Neon" }))
		end
		return shapes
	end)(),
	-- Junkyard Isles: three crushed cars stacked and strapped, each with its window band, flattened wheels and a
	-- bumper, turned a little against each other.
	CrushedCarStack = (function(): { Shape }
		local shapes: { Shape } = {}
		local cars = {
			{ size = { 4.8, 1.5, 7.8 }, y = -1.75, turn = 0, color = "#B87A82" },
			{ size = { 4.6, 1.45, 7.5 }, y = -0.27, turn = 6, color = "#2F8C8C" },
			{ size = { 4.3, 1.5, 7.1 }, y = 1.24, turn = -8, color = "#C8642D" },
		}
		for _, car in cars do
			local turn = { 0, car.turn, 0 }
			local sx, sy, sz = car.size[1], car.size[2], car.size[3]
			table.insert(
				shapes,
				block(car.size, { 0, car.y, 0 }, { Turn = turn, Color = car.color, Material = "Metal" })
			)
			table.insert(
				shapes,
				block(
					{ sx + 0.06, 0.35, sz * 0.45 },
					{ 0, car.y + sy / 2 - 0.3, 0.2 },
					{ Turn = turn, Color = DARK, Material = "Glass" }
				)
			)
			table.insert(
				shapes,
				block(
					{ sx - 0.2, 0.25, 0.12 },
					{ 0, car.y - 0.3, -sz / 2 - 0.02 },
					{ Turn = turn, Color = CHROME, Material = "Metal" }
				)
			)
			local c, s = math.cos(math.rad(car.turn)), math.sin(math.rad(car.turn))
			for _, wheel in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
				local lx, lz = wheel[1] * (sx / 2 + 0.03), wheel[2] * (sz / 2 - 1.3)
				table.insert(
					shapes,
					lying(1, 0.12, { lx * c + lz * s, car.y - 0.2, -lx * s + lz * c }, { Turn = turn, Color = RUBBER })
				)
			end
		end
		-- Steel straps round the stack.
		for _, z in { -2.2, 2.2 } do
			for _, x in { -2.53, 2.53 } do
				table.insert(shapes, block({ 0.08, 4.9, 0.3 }, { x, 0, z }, { Color = STEEL, Material = "Metal" }))
			end
			table.insert(shapes, block({ 5, 0.08, 0.3 }, { 0, 2.47, z }, { Color = STEEL, Material = "Metal" }))
		end
		return shapes
	end)(),
	-- Junkyard Isles: a heap of scrap — a rusty mound with pipes, bent sheet metal, a tyre, a drum and a gear on it.
	ScrapPile = {
		block({ 6, 1.6, 3 }, { 0, -0.7, -1.5 }, { Shape = "Wedge" } :: any),
		block({ 6, 1.6, 3 }, { 0, -0.7, 1.5 }, { Shape = "Wedge", Turn = { 0, 180, 0 } } :: any),
		block({ 3.2, 1, 3 }, { 0, 0.3, 0 }, { Tint = 0.8 }),
		lying(0.5, 4.2, { -0.6, 0.65, 0.6 }, { Turn = { 0, 30, 8 }, Color = STEEL, Material = "Metal" }),
		lying(0.4, 3.6, { 0.9, 0.35, -1 }, { Turn = { 0, -50, 0 }, Color = "#8A5A32", Material = "Metal" }),
		block({ 2.8, 0.1, 1.8 }, { 0.8, 0.95, 0.2 }, { Turn = { 15, 20, -10 }, Color = "#55595E", Material = "Metal" }),
		block(
			{ 2.2, 0.1, 1.6 },
			{ -1.2, 0.55, -1.2 },
			{ Turn = { -12, -35, 8 }, Color = "#8C4A2A", Material = "Metal" }
		),
		upright(1.8, 0.55, { 1.5, 0.75, 1.5 }, { Turn = { 25, 0, 0 }, Color = RUBBER }),
		lying(1.1, 1.8, { -1.7, -0.75, 1.9 }, { Color = "#2F8C8C", Material = "Metal" }),
		upright(1.1, 0.25, { 0.2, 1.05, -0.4 }, { Color = "#55595E", Material = "Metal" }),
	},
	-- Neon Motel: an ice machine — its cabinet, a glowing blue ICE header, the bin door with a chrome handle, a vent
	-- grille, the coin box, feet and a few ice cubes on top.
	IceMachine = (function(): { Shape }
		local shapes = {
			block({ 3.9, 5.7, 2.8 }, { 0, 0.05, 0.05 }, { Color = "#E8EEF2" }),
			block({ 3.7, 1, 0.08 }, { 0, 2.25, -1.42 }, { Color = "#3FA7E8", Material = "Neon" }),
			block({ 3.2, 2.6, 0.1 }, { 0, -0.6, -1.42 }, { Color = "#C9D6DE", Material = "Metal" }),
			block({ 2.4, 0.15, 0.12 }, { 0, 0.55, -1.48 }, { Color = CHROME, Material = "Metal" }),
			block({ 3.3, 0.12, 0.06 }, { 0, 0.85, -1.47 }, { Color = WHITE }),
			block({ 0.5, 0.7, 0.08 }, { 1.4, 1.3, -1.45 }, { Color = DARK }),
		}
		for index = 0, 3 do
			table.insert(shapes, block({ 2.6, 0.06, 0.05 }, { -0.4, 1.2 + index * 0.18, -1.45 }, { Color = DARK }))
		end
		for _, foot in { { -1.6, -1.1 }, { 1.6, -1.1 }, { -1.6, 1.1 }, { 1.6, 1.1 } } do
			table.insert(shapes, block({ 0.4, 0.2, 0.4 }, { foot[1], -2.9, foot[2] }, { Color = DARK }))
		end
		for index, cube in { { -1, 0.3 }, { 0.2, -0.4 }, { 1.1, 0.5 } } do
			table.insert(
				shapes,
				block(
					{ 0.35, 0.35, 0.35 },
					{ cube[1], 3, cube[2] },
					{ Turn = { 0, index * 25, 0 }, Color = "#CFEFF7", Material = "Glass", Transparency = 0.3 }
				)
			)
		end
		return shapes
	end)(),
	-- Neon Motel: two stacks of plastic lawn chairs (three and two), each chair a seat, a tilted back, arms and legs.
	LawnChairStack = (function(): { Shape }
		local shapes: { Shape } = {}
		local colors = { "#F2F2F2", "#3FB8AF", "#D98C9A" }
		local function chair(x: number, y: number, color: string)
			table.insert(shapes, block({ 2.2, 0.14, 2.1 }, { x, y, 0.1 }, { Color = color }))
			table.insert(
				shapes,
				block({ 2.2, 1.3, 0.12 }, { x, y + 0.6, 1.1 }, { Turn = { -12, 0, 0 }, Color = color })
			)
			for _, side in { -1, 1 } do
				table.insert(shapes, block({ 0.12, 0.12, 1.9 }, { x + side * 1.05, y + 0.45, 0.1 }, { Color = color }))
				table.insert(shapes, block({ 0.12, 0.6, 0.12 }, { x + side * 1.05, y - 0.35, -0.9 }, { Color = color }))
			end
		end
		for level = 0, 2 do
			chair(-1.25, -0.9 + level * 0.5, colors[level + 1])
		end
		for level = 0, 1 do
			chair(1.25, -0.9 + level * 0.5, colors[3 - level])
		end
		return shapes
	end)(),
}

-- Where a shape sits relative to its item's centre (its CFrame there; Size is the part's own size).
function ItemShapes.offset(shape: Shape): CFrame
	local turn = shape.Turn or { 0, 0, 0 }
	local cframe = CFrame.new(shape.At[1], shape.At[2], shape.At[3])
		* CFrame.Angles(math.rad(turn[1]), math.rad(turn[2]), math.rad(turn[3]))
	if shape.Upright then
		cframe *= CFrame.Angles(0, 0, math.pi / 2)
	elseif shape.Facing then
		cframe *= CFrame.Angles(0, math.pi / 2, 0)
	end
	return cframe
end

return ItemShapes
