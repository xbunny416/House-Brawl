--!strict
-- Grabbable props and their weight classes. Bible §3.3 "Props".
local Types = require(script.Parent.Types)

type PropsConfig = {
	GrabRange: number,
	GrabCooldown: number,
	ThrowSpeed: number,
	ThrowUpwardSpeed: number,
	ThrowCooldown: number,
	ThrowGravityScale: number,
	ThrowOriginTolerance: number,
	ThrowAimAssist: { Angle: number, Range: number },
	DespawnAfterLanding: number,
	MaxActive: number,
	SpotRespawnTime: number,
	ExplosiveSpotRespawnTime: number,
	LooseSpotTypes: { string },
	Classes: { [string]: Types.PropClassConfig },
	Types: { [string]: Types.PropTypeConfig },
}

local Props: PropsConfig = {
	GrabRange = 6, -- studs, checked on the server
	GrabCooldown = 0.3,
	ThrowSpeed = 90, -- studs/s
	ThrowUpwardSpeed = 14, -- studs/s added upward for a slight arc
	ThrowCooldown = 0.5, -- server-enforced throw rate
	-- Share of world gravity a thrown prop feels while flying. Full gravity dropped a 90 studs/s throw about 6 studs
	-- over 30 studs, so long throws hit the floor (owner playtest: "throws are off").
	ThrowGravityScale = 0.25,
	-- The thrower's client reports where it is when it throws; the server uses that position if it is within this
	-- many studs of where the server sees the thrower (otherwise the server's own), so throws start where you are.
	ThrowOriginTolerance = 8,
	-- A throw bends toward a fighter within Angle degrees of the thrower's facing and Range studs (Angle 0 = off).
	ThrowAimAssist = { Angle = 15, Range = 80 },
	DespawnAfterLanding = 8,
	MaxActive = 80, -- per arena (Town has 72 spots: owner, 2026-10-28, "add more throwable item")
	SpotRespawnTime = 20,
	ExplosiveSpotRespawnTime = 30,

	-- Prop types that loose prop spots pick from at random.
	LooseSpotTypes = { "Chair", "Crate", "Tire", "Bucket", "TV", "Barrel", "TrashCan" },

	Classes = {
		Light = { Damage = 10, Percent = 8, KnockbackScale = 1, CarrySlow = 0 },
		Medium = { Damage = 18, Percent = 14, KnockbackScale = 1.3, CarrySlow = 0.15 },
		Heavy = { Damage = 28, Percent = 22, KnockbackScale = 1.7, CarrySlow = 0.3 },
		-- Explodes on impact, or FuseTime seconds after being hit. Damages everyone within Radius studs.
		Explosive = {
			Damage = 25,
			Percent = 20,
			KnockbackScale = 1.5,
			CarrySlow = 0.15,
			Radius = 10,
			FuseTime = 3,
		},
	},

	-- Size in studs; Material/Color are used by the blockout models until final art replaces them.
	Types = {
		Chair = { Class = "Light", Size = { X = 2, Y = 3, Z = 2 }, Material = "Metal", Color = "#3C8C8C" },
		Bucket = { Class = "Light", Size = { X = 1.5, Y = 1.6, Z = 1.5 }, Material = "Metal", Color = "#B8B2A6" },
		Tire = { Class = "Light", Size = { X = 2.6, Y = 1, Z = 2.6 }, Material = "SmoothPlastic", Color = "#2B2B2B" },
		TrafficCone = {
			Class = "Light",
			Size = { X = 1.4, Y = 2.2, Z = 1.4 },
			Material = "SmoothPlastic",
			Color = "#E8742A",
		},
		Crate = { Class = "Medium", Size = { X = 3, Y = 3, Z = 3 }, Material = "WoodPlanks", Color = "#9C6B3E" },
		TV = { Class = "Medium", Size = { X = 2.6, Y = 2.2, Z = 2.2 }, Material = "SmoothPlastic", Color = "#6E5A4A" },
		Barrel = { Class = "Medium", Size = { X = 2.2, Y = 3, Z = 2.2 }, Material = "Metal", Color = "#3E6E8C" },
		-- A street trash can (owner, 2026-10-28: "add trash can throwables").
		TrashCan = { Class = "Medium", Size = { X = 2, Y = 2.8, Z = 2 }, Material = "Metal", Color = "#4E7A5A" },
		-- Things that belong where they are found in Town (owner, 2026-10-28: "add more throwable item also match
		-- that found area"): arena prop spots name them (PropType).
		Stool = { Class = "Light", Size = { X = 1.4, Y = 2.2, Z = 1.4 }, Material = "SmoothPlastic", Color = "#C8463C" },
		PaperLantern = { Class = "Light", Size = { X = 1.4, Y = 2, Z = 1.4 }, Material = "Fabric", Color = "#D93A2B" },
		PottedPlant = { Class = "Light", Size = { X = 1.6, Y = 3, Z = 1.6 }, Material = "Concrete", Color = "#6E6A64" },
		OfficeChair = { Class = "Light", Size = { X = 2, Y = 3.4, Z = 2 }, Material = "Fabric", Color = "#2E3440" },
		Monitor = {
			Class = "Light",
			Size = { X = 2.2, Y = 1.8, Z = 0.8 },
			Material = "SmoothPlastic",
			Color = "#2B2B2B",
		},
		ShoppingBasket = {
			Class = "Light",
			Size = { X = 2, Y = 1.4, Z = 1.4 },
			Material = "SmoothPlastic",
			Color = "#C8463C",
		},
		BowlingPin = {
			Class = "Light",
			Size = { X = 0.8, Y = 2.4, Z = 0.8 },
			Material = "SmoothPlastic",
			Color = "#F2F2F2",
		},
		FireExtinguisher = {
			Class = "Light",
			Size = { X = 0.9, Y = 2.2, Z = 0.9 },
			Material = "Metal",
			Color = "#C9302C",
		},
		BookStack = {
			Class = "Light",
			Size = { X = 1.6, Y = 1.4, Z = 1.2 },
			Material = "SmoothPlastic",
			Color = "#8A4634",
		},
		Toolbox = { Class = "Light", Size = { X = 2, Y = 1.3, Z = 1 }, Material = "Metal", Color = "#C9302C" },
		Speaker = {
			Class = "Medium",
			Size = { X = 2, Y = 3.2, Z = 1.8 },
			Material = "SmoothPlastic",
			Color = "#1C1C1F",
		},
		Suitcase = {
			Class = "Medium",
			Size = { X = 2.2, Y = 2.8, Z = 1 },
			Material = "SmoothPlastic",
			Color = "#3E6E8C",
		},
		BowlingBall = {
			Class = "Medium",
			Size = { X = 1.6, Y = 1.6, Z = 1.6 },
			Material = "SmoothPlastic",
			Color = "#3A4FB0",
		},
		Cinderblock = {
			Class = "Medium",
			Size = { X = 2.4, Y = 1.2, Z = 1.2 },
			Material = "Concrete",
			Color = "#9A968F",
		},
		GasCan = { Class = "Medium", Size = { X = 1.8, Y = 1.8, Z = 1 }, Material = "SmoothPlastic", Color = "#C9302C" },
		Mannequin = {
			Class = "Medium",
			Size = { X = 1.6, Y = 5.4, Z = 1 },
			Material = "SmoothPlastic",
			Color = "#E8E2D6",
		},
		Fridge = { Class = "Heavy", Size = { X = 3, Y = 5.5, Z = 3 }, Material = "SmoothPlastic", Color = "#EDE6D6" },
		CarDoor = { Class = "Heavy", Size = { X = 4.5, Y = 3, Z = 0.5 }, Material = "Metal", Color = "#D97A8A" },
		VendingChunk = { Class = "Heavy", Size = { X = 3, Y = 3, Z = 2 }, Material = "Metal", Color = "#C8463C" },
		ExplosiveBarrel = {
			Class = "Explosive",
			Size = { X = 2.2, Y = 3, Z = 2.2 },
			Material = "Metal",
			Color = "#D93A2B",
		},
	},
}

return Props
