--!strict
-- Grabbable props and their weight classes. Bible §3.3 "Props".
local Types = require(script.Parent.Types)

type PropsConfig = {
	GrabRange: number,
	GrabCooldown: number,
	ThrowSpeed: number,
	ThrowUpwardSpeed: number,
	ThrowCooldown: number,
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
	DespawnAfterLanding = 8,
	MaxActive = 40, -- per arena
	SpotRespawnTime = 20,
	ExplosiveSpotRespawnTime = 30,

	-- Prop types that loose prop spots pick from at random.
	LooseSpotTypes = { "Chair", "Crate", "Tire", "Bucket", "TV", "Barrel" },

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
		Barrel = { Class = "Medium", Size = { X = 2.2, Y = 3, Z = 2.2 }, Material = "CorrodedMetal", Color = "#3E6E8C" },
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
