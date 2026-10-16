--!strict
-- Breakable structures: damaged by any attack or thrown prop (using Classic damage values in every mode),
-- then break into MinDrops..MaxDrops random props from DropTable. Bible §3.2 and §3.3.
local Types = require(script.Parent.Types)

type StructuresConfig = {
	RespawnTime: number,
	DropDespawnTime: number,
	Types: { [string]: Types.StructureConfig },
}

local Structures: StructuresConfig = {
	RespawnTime = 45,
	DropDespawnTime = 30, -- dropped props nobody picks up vanish after this many seconds
	Types = {
		WreckedCar = {
			Health = 100,
			MinDrops = 2,
			MaxDrops = 4,
			DropTable = { "CarDoor", "Tire", "Barrel" },
			Size = { X = 4.6, Y = 3.6, Z = 9 },
			Material = "CorrodedMetal",
			Color = "#8C4A3A",
		},
		VendingMachine = {
			Health = 80,
			MinDrops = 2,
			MaxDrops = 4,
			DropTable = { "VendingChunk", "TV", "Bucket" },
			Size = { X = 4, Y = 7, Z = 3 },
			Material = "Metal",
			Color = "#C8463C",
		},
		RoadBarrierStack = {
			Health = 60,
			MinDrops = 2,
			MaxDrops = 4,
			DropTable = { "TrafficCone", "Crate", "Tire" },
			Size = { X = 8, Y = 3, Z = 2.4 },
			Material = "Concrete",
			Color = "#E8742A",
		},
	},
}

return Structures
