--!strict
--[[
	SeatService — sitting on the lobby's sofas, armchairs, booth benches and stools (owner's fix list, 2026-10-19:
	"sit on chairs / couches"). The seats are LobbySeat-tagged Seats in the lobby model (maps/layouts/Hideout) with
	CanTouch off, so walking into one never sits you down; the client shows a Sit prompt (SeatController) and sends
	the Sit intent. The server sits the player down only if the seat is a lobby seat and free, their character is
	alive and not already sitting, they aren't fighting in a round, and they stand within
	Config.Controls.Prompts.SitDistance + SitTolerance studs of it. Jumping stands them up (Roblox's own seats).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local SEAT_TAG = "LobbySeat"

local SeatService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Seats] {message}`)
	end
end

-- Why `player` can't sit on `seat` now, or nil if they can.
local function refusal(player: Player, seat: Seat): string?
	if not seat:HasTag(SEAT_TAG) or not seat:IsDescendantOf(Workspace) then
		return "not a lobby seat"
	elseif seat.Occupant ~= nil then
		return "taken"
	end
	local status = player:GetAttribute("RoundStatus")
	if status == "Playing" or status == "Respawning" then
		return "fighting"
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return "no character"
	elseif humanoid.SeatPart ~= nil then
		return "already sitting"
	end
	local prompts = Config.Controls.Prompts
	if (root.Position - seat.Position).Magnitude > prompts.SitDistance + prompts.SitTolerance then
		return "too far"
	end
	return nil
end

function SeatService.Init(_self: any)
	Net.onServerEvent("Sit", function(player: Player, seat: Seat)
		local why = refusal(player, seat)
		if why then
			log(`{player.Name} can't sit on {seat:GetFullName()}: {why}`)
			return
		end
		local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
		seat:Sit(humanoid)
	end)
end

return SeatService
