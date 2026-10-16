--!strict
--[[
	Carrier — what one player is holding and when they may grab or throw again (pure: time is passed in).
	Hold one prop at a time. Grabbing and dropping share GrabCooldown; throws are limited by ThrowCooldown.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Props = Config.Props

export type Carrier = {
	Held: any?, -- the held prop (opaque to these rules)
	NextGrabAt: number,
	NextThrowAt: number,
}

-- One prop the player could grab: how far its center is from the player, and its size.
export type Candidate = { Item: any, Distance: number, Radius: number }

local Carrier = {}

function Carrier.new(): Carrier
	return { Held = nil, NextGrabAt = 0, NextThrowAt = 0 }
end

-- The closest candidate within GrabRange (measured to the prop's edge, `Radius` = half its largest side), or nil.
function Carrier.nearest(candidates: { Candidate }): any?
	local best: Candidate? = nil
	for _, candidate in candidates do
		local inRange = candidate.Distance - candidate.Radius <= Props.GrabRange
		if inRange and (best == nil or candidate.Distance < best.Distance) then
			best = candidate
		end
	end
	return if best then best.Item else nil
end

-- Picks up `item` if the hands are free and the grab cooldown is over.
function Carrier.grab(carrier: Carrier, item: any, now: number): boolean
	if carrier.Held ~= nil or now < carrier.NextGrabAt then
		return false
	end
	carrier.Held = item
	carrier.NextGrabAt = now + Props.GrabCooldown
	return true
end

-- Lets go of the held prop (drop, getting hit, knocked out). Returns it, or nil if nothing was held.
function Carrier.release(carrier: Carrier, now: number): any?
	local item = carrier.Held
	if item == nil then
		return nil
	end
	carrier.Held = nil
	carrier.NextGrabAt = now + Props.GrabCooldown
	return item
end

-- Throws the held prop if the throw cooldown is over. Returns it, or nil.
function Carrier.throw(carrier: Carrier, now: number): any?
	if carrier.Held == nil or now < carrier.NextThrowAt then
		return nil
	end
	carrier.NextThrowAt = now + Props.ThrowCooldown
	return Carrier.release(carrier, now)
end

return Carrier
