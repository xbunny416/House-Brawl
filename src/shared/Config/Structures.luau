--!strict
-- Breakable structures: damaged by any attack or thrown prop (using Classic damage values in every mode),
-- then break into MinDrops..MaxDrops random props from DropTable. Bible §3.2 and §3.3.
local Types = require(script.Parent.Types)

type StructuresConfig = {
	RespawnTime: number,
	Types: { [string]: Types.StructureConfig },
}

local Structures: StructuresConfig = {
	RespawnTime = 45,
	Types = {
		WreckedCar = { Health = 100, MinDrops = 2, MaxDrops = 4, DropTable = { "CarDoor", "Tire", "Barrel" } },
		VendingMachine = { Health = 80, MinDrops = 2, MaxDrops = 4, DropTable = { "VendingChunk", "TV", "Bucket" } },
		RoadBarrierStack = { Health = 60, MinDrops = 2, MaxDrops = 4, DropTable = { "TrafficCone", "Crate", "Tire" } },
	},
}

return Structures
