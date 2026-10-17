--!strict
--[[
	Effects — tells every client to draw a one-off visual effect (client: VfxController). Server code calls it when
	the thing really happens:
	  "KO"           a knock-out (data: Victim, Killer models, Cause "Health" / "Fall")
	  "KOBurst"      the scorer's KO-effect cosmetic (data: Colors — hex strings)
	  "Explosion"    an explosive barrel (data: Radius)
	  "Break"        a structure breaking (data: Size, Color, Material name)
	  "PerfectDodge" a Perfect Dodge (data: Character)
	Hit sparks, launch smoke and dash streaks need no call: clients draw them from CombatHit / Animate.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Effects = {}

function Effects.play(kind: string, position: Vector3, data: { [string]: any }?)
	Net.fireAll("Effect", kind, position, data or {})
end

return Effects
