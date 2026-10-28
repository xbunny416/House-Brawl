--!strict
-- Breakable structures: damaged by any attack or thrown prop (using Classic damage values in every mode),
-- then break into MinDrops..MaxDrops random props from DropTable. Bible §3.2 and §3.3.
local Types = require(script.Parent.Types)

type StructuresConfig = {
	RespawnTime: number,
	DropDespawnTime: number,
	Types: { [string]: Types.StructureConfig },
	Walls: { Health: { [string]: number }, DefaultHealth: number, MaxPiece: number, MaxGlass: number },
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
			Size = { X = 6.2, Y = 4.9, Z = 12.2 }, -- life-size beside an avatar (owner, 2026-10-28; was 4.6 × 3.6 × 9)
			Material = "Metal",
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
		-- Junkyard Isles (step 2.5; HP tiers as on Broken Highway: 100 / 80 / 60).
		CrushedCarStack = {
			Health = 100,
			MinDrops = 2,
			MaxDrops = 4,
			DropTable = { "CarDoor", "Tire", "Barrel" },
			Size = { X = 5, Y = 5, Z = 8 },
			Material = "Metal",
			Color = "#6E5A4A",
		},
		ScrapPile = {
			Health = 60,
			MinDrops = 2,
			MaxDrops = 4,
			DropTable = { "Crate", "Bucket", "Tire" },
			Size = { X = 6, Y = 3, Z = 6 },
			Material = "Metal",
			Color = "#7A6A55",
		},
		-- Neon Motel (step 2.5).
		IceMachine = {
			Health = 80,
			MinDrops = 2,
			MaxDrops = 4,
			DropTable = { "VendingChunk", "Bucket", "Crate" },
			Size = { X = 4, Y = 6, Z = 3 },
			Material = "Metal",
			Color = "#9FD6E0",
		},
		LawnChairStack = {
			Health = 60,
			MinDrops = 2,
			MaxDrops = 4,
			DropTable = { "Chair", "Bucket", "Crate" },
			Size = { X = 5, Y = 3, Z = 3 },
			Material = "SmoothPlastic",
			Color = "#3FB8AF",
		},
	},
	-- Breakable walls (owner, 2026-10-28: "add breakable walls"): arena parts tagged BreakableWall — building walls,
	-- windows, block walls (Services/WallService). Attacks, thrown props and blasts take their Classic damage off a
	-- wall's health, which comes from its material (Glass breaks with one punch: a punch does 8); at 0 it shatters and
	-- stays gone for the rest of the round. MaxPiece: the widest a wall piece may be (studs), so one break opens a
	-- hole, not a whole side; MaxGlass the widest glass pane (the maps spec checks both).
	Walls = {
		Health = { Glass = 6, Wood = 20, WoodPlanks = 20, Fabric = 6 },
		DefaultHealth = 32,
		MaxPiece = 16,
		MaxGlass = 26,
	},
}

return Structures
