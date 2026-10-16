--!strict
--[[
	Animate — tells clients to play a scripted animation clip on a character (client: AnimationController). Server
	code calls it when an action really happens (an accepted punch, shove, grab, throw, a victory emote), so every
	client shows the same thing. `except` skips the player whose client already played it (their own dash).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Animate = {}

function Animate.play(character: Model, clip: string, except: Player?)
	if except then
		Net.fireAllExcept("Animate", except, character, clip)
	else
		Net.fireAll("Animate", character, clip)
	end
end

return Animate
