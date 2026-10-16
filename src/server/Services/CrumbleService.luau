--!strict
--[[
	CrumbleService — crumbling platforms (bible §3.2). From Round.Crumble.StartTime seconds into a round, every
	Interval seconds one random outer platform (CanFall attribute) gets a WarningTime warning — it flashes red and
	shakes — then falls for FallTime seconds, taking anyone standing on it, and is removed. The center never falls
	and at least MinPlatformsRemaining platforms always stay (Server/Round/CrumbleRules).
	When the warning starts the platform gets the attribute Crumbling = true, so its spawn points and prop spots stop
	being used (MapService.getArenaMarkers).
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

local WARNING_COLOR = Color3.fromHex("#FF2A1A")
local FLASH_INTERVAL = 0.25 -- seconds per red flash
local SHAKE_STEP = 0.05 -- seconds between shake offsets
local SHAKE_OFFSET = 0.15 -- studs
local FALL_START_SPEED = 4 -- studs/s downward push when the platform lets go
local SCHEDULE_TICK = 0.25

local CrumbleService = {
	-- (platform) when a platform's warning ends and it starts to fall. Listeners weld their own parts to
	-- platform.PrimaryPart now if they should fall with it (it is unanchored right after).
	PlatformFalling = Signal.new() :: Signal.Signal<Model>,
}

local roundToken = 0
local rng = Random.new()

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Crumble] {message}`)
	end
end

-- Warns (flash + shake), then drops the platform and removes it after FallTime.
local function crumble(platform: Model)
	if platform:GetAttribute("Crumbling") then
		return
	end
	platform:SetAttribute("Crumbling", true)
	log(`{platform.Name} is crumbling`)
	local crumbleConfig = Config.Round.Crumble

	local highlight = Instance.new("Highlight")
	highlight.FillColor = WARNING_COLOR
	highlight.OutlineColor = WARNING_COLOR
	highlight.FillTransparency = 0.45
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = platform
	local origin = platform:GetPivot()
	local started = os.clock()
	while os.clock() - started < crumbleConfig.WarningTime do
		if platform.Parent == nil then
			return
		end
		local elapsed = os.clock() - started
		highlight.Enabled = math.floor(elapsed / FLASH_INTERVAL) % 2 == 0
		local shake = CFrame.new(rng:NextNumber(-1, 1) * SHAKE_OFFSET, 0, rng:NextNumber(-1, 1) * SHAKE_OFFSET)
		platform:PivotTo(origin * shake)
		task.wait(SHAKE_STEP)
	end
	local base = platform.PrimaryPart
	if platform.Parent == nil or base == nil then
		return
	end
	platform:PivotTo(origin)
	highlight.Enabled = true

	-- Weld everything to the base, then let gravity take it.
	for _, part in platform:GetDescendants() do
		if part:IsA("BasePart") and part ~= base then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = base
			weld.Part1 = part
			weld.Parent = part
		end
	end
	CrumbleService.PlatformFalling:Fire(platform)
	for _, part in platform:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	pcall(function()
		base:SetNetworkOwner(nil)
	end)
	base.AssemblyLinearVelocity = Vector3.new(0, -FALL_START_SPEED, 0)
	log(`{platform.Name} falls`)
	task.delay(crumbleConfig.FallTime, function()
		platform:Destroy()
	end)
end

local function standingPlatforms(): ({ CrumbleRules.Platform }, { [string]: Model })
	local entries: { CrumbleRules.Platform } = {}
	local byId: { [string]: Model } = {}
	for _, platform in MapService.getPlatforms() do
		table.insert(entries, {
			Id = platform.Name,
			CanFall = platform:GetAttribute("CanFall") == true,
			Fallen = platform:GetAttribute("Crumbling") == true,
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
