--!strict
--[[
	CrumbleService — crumbling platforms (bible §3.2). From Round.Crumble.StartTime seconds into a round, every
	Interval seconds one platform that can fall (CanFall attribute) gets a WarningTime warning, then stops being solid
	(everyone and everything on it falls) and is removed after FallTime. The arena closes in: the platform comes from
	the outer ring, the ones farthest from the arena's centre (Crumble.RingWidth). The center never falls and at least
	MinPlatformsRemaining platforms always stay (Server/Round/CrumbleRules).
	Attributes: Crumbling = true when the warning starts (its spawn points and prop spots stop being used,
	MapService.getArenaMarkers), Falling = true when it gives way. Clients draw the red flash, the shake and the
	platform sinking away (CrumbleController), so it looks smooth instead of replicating every frame from here.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))

local Server = script.Parent.Parent
local CrumbleRules = require(Server:WaitForChild("Round"):WaitForChild("CrumbleRules"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

local SCHEDULE_TICK = 0.25

local CrumbleService = {
	-- (platform) when a platform's warning ends and it stops being solid (things on it should fall now).
	PlatformFalling = Signal.new() :: Signal.Signal<Model>,
}

local roundToken = 0
local rng = Random.new()

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Crumble] {message}`)
	end
end

-- Warns for WarningTime, then the platform stops being solid (everything on it falls) and is removed after
-- FallTime. Clients draw the warning (red flash + shake) and the platform sinking away (CrumbleController).
local function crumble(platform: Model)
	if platform:GetAttribute("Crumbling") then
		return
	end
	local crumbleConfig = Config.Round.Crumble
	platform:SetAttribute("Crumbling", true)
	log(`{platform.Name} is crumbling`)
	task.wait(crumbleConfig.WarningTime)
	if platform.Parent == nil then
		return
	end
	for _, part in platform:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	platform:SetAttribute("Falling", true)
	CrumbleService.PlatformFalling:Fire(platform)
	log(`{platform.Name} falls`)
	task.delay(crumbleConfig.FallTime, function()
		platform:Destroy()
	end)
end

local function standingPlatforms(): ({ CrumbleRules.Platform }, { [string]: Model })
	local entries: { CrumbleRules.Platform } = {}
	local byId: { [string]: Model } = {}
	local origin = Config.Maps.ArenaOrigin
	for _, platform in MapService.getPlatforms() do
		local position = platform:GetPivot().Position
		table.insert(entries, {
			Id = platform.Name,
			CanFall = platform:GetAttribute("CanFall") == true,
			Fallen = platform:GetAttribute("Crumbling") == true,
			-- On the ground plane, from the arena's centre (where the centre platform is built).
			Distance = Vector2.new(position.X - origin[1], position.Z - origin[3]).Magnitude,
		})
		byId[platform.Name] = platform
	end
	return entries, byId
end

-- Crumbles the next platform the rules allow, at once (developer panel, tests). False if none may fall.
function CrumbleService.crumbleNext(): boolean
	local entries, byId = standingPlatforms()
	local id = CrumbleRules.pick(entries, function(count: number): number
		return rng:NextInteger(1, count)
	end)
	local platform = id and byId[id]
	if platform == nil then
		return false
	end
	task.spawn(crumble, platform)
	return true
end

-- Runs one round's crumble schedule until the round ends (or a newer round starts).
local function runSchedule(token: number, startedAt: number)
	local n = 1
	while true do
		local at = startedAt + CrumbleRules.timeOf(n)
		while os.clock() < at do
			task.wait(SCHEDULE_TICK)
			if token ~= roundToken or RoundService.getState() ~= "Playing" then
				return
			end
		end
		CrumbleService.crumbleNext()
		n += 1
	end
end

function CrumbleService.Init(_self: any)
	RoundService.RoundStarted:Connect(function()
		roundToken += 1
		task.spawn(runSchedule, roundToken, os.clock())
	end)
end

return CrumbleService
