--!strict
-- Prop rules (step 1.9): grab range and cooldowns, one prop at a time, throw rate, throw velocity, prop config.
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local Formulas = Roblox.require(Shared.Formulas)
local Carrier = Roblox.require(Roblox.game.ServerScriptService.Server.Props.Carrier)

local Props = Config.Props

return {
	["grab picks the nearest prop whose edge is within GrabRange"] = function()
		local candidates = {
			{ Item = "far", Distance = 20, Radius = 1 },
			{ Item = "near", Distance = 4, Radius = 1 },
			{ Item = "nearer", Distance = 3, Radius = 1 },
		}
		expect.equal(Carrier.nearest(candidates), "nearer")
		expect.equal(Carrier.nearest({ { Item = "edge", Distance = Props.GrabRange + 2, Radius = 2 } }), "edge")
		expect.equal(Carrier.nearest({ { Item = "out", Distance = Props.GrabRange + 2.1, Radius = 2 } }), nil)
		expect.equal(Carrier.nearest({}), nil)
	end,
	["one prop at a time; grab and drop share the grab cooldown"] = function()
		local carrier = Carrier.new()
		expect.equal(Carrier.grab(carrier, "chair", 0), true)
		expect.equal(Carrier.grab(carrier, "crate", 1), false, "hands full")
		expect.equal(Carrier.release(carrier, 1), "chair")
		expect.equal(Carrier.release(carrier, 1), nil, "nothing held")
		expect.equal(Carrier.grab(carrier, "crate", 1 + Props.GrabCooldown - 0.01), false, "grab cooldown")
		expect.equal(Carrier.grab(carrier, "crate", 1 + Props.GrabCooldown), true)
	end,
	["throws are limited by ThrowCooldown"] = function()
		local carrier = Carrier.new()
		Carrier.grab(carrier, "chair", 0)
		expect.equal(Carrier.throw(carrier, 0), "chair")
		expect.equal(carrier.Held, nil)
		Carrier.grab(carrier, "tire", Props.GrabCooldown)
		expect.equal(Carrier.throw(carrier, Props.ThrowCooldown - 0.01), nil, "throw cooldown")
		expect.equal(carrier.Held, "tire", "still held after a refused throw")
		expect.equal(Carrier.throw(carrier, Props.ThrowCooldown), "tire")
		expect.equal(Carrier.throw(Carrier.new(), 10), nil, "nothing to throw")
	end,
	["throw velocity: ThrowSpeed along the facing plus a slight upward arc"] = function()
		local vx, vy, vz = Formulas.throwVelocity(0, -2)
		expect.near(vx, 0)
		expect.near(vz, -Props.ThrowSpeed)
		expect.equal(vy, Props.ThrowUpwardSpeed)
		vx, vy, vz = Formulas.throwVelocity(3, 4)
		expect.near(math.sqrt(vx * vx + vz * vz), Props.ThrowSpeed)
		vx, vy, vz = Formulas.throwVelocity(0, 0)
		expect.equal(vx + vz, 0, "no facing: straight up")
	end,
	["prop classes match the bible and every loose spot type exists"] = function()
		expect.equal(Props.Classes.Light.Damage, 10)
		expect.equal(Props.Classes.Medium.CarrySlow, 0.15)
		expect.equal(Props.Classes.Heavy.KnockbackScale, 1.7)
		expect.equal(Props.Classes.Explosive.Radius, 10)
		expect.equal(Props.Classes.Explosive.FuseTime, 3)
		expect.equal(Props.MaxActive, 40)
		for _, typeId in Props.LooseSpotTypes do
			expect.truthy(Props.Types[typeId], typeId)
			expect.truthy(Props.Types[typeId].Class ~= "Explosive", `{typeId} is not a barrel`)
		end
		expect.equal(Props.Types.ExplosiveBarrel.Class, "Explosive")
	end,
}
