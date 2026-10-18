--!strict
--[[
	NeonFlickerController — neon that flickers now and then (Neon Motel's "flickering retro neon", bible §3.1). Parts
	tagged NeonFlicker (map layouts) blink off a few times at random intervals: a Neon part fades, a sign's text
	fades, and the light they cast goes out with them. Stops on a platform that is falling (CrumbleController fades
	it out), and stays steady with Low Graphics. Local and visual only.
]]
local CollectionService = game:GetService("CollectionService")

local SettingsController = require(script.Parent:WaitForChild("SettingsController"))

local TAG = "NeonFlicker"
local MIN_WAIT, MAX_WAIT = 2, 9 -- seconds between two flickers of one part
local BLINKS = { 0.07, 0.05, 0.12, 0.06 } -- off, on, off, on (seconds)
local DIM = 0.8 -- transparency while off

local NeonFlickerController = {}

local running: { [Instance]: boolean } = {}

local function onFallingPlatform(part: BasePart): boolean
	local node = part.Parent
	while node do
		if node:HasTag("Platform") then
			return node:GetAttribute("Crumbling") == true or node:GetAttribute("Falling") == true
		end
		node = node.Parent
	end
	return false
end

local function setOff(part: BasePart, off: boolean, base: number)
	if part.Material == Enum.Material.Neon then
		part.Transparency = if off then math.max(base, DIM) else base
	end
	for _, descendant in part:GetDescendants() do
		if descendant:IsA("TextLabel") then
			descendant.TextTransparency = if off then DIM else 0
		elseif descendant:IsA("Light") then
			descendant.Enabled = not off
		end
	end
end

local function flicker(part: BasePart)
	running[part] = true
	local random = Random.new()
	local base = part.Transparency
	while running[part] do
		task.wait(random:NextNumber(MIN_WAIT, MAX_WAIT))
		if not running[part] or part.Parent == nil or onFallingPlatform(part) then
			break
		end
		if SettingsController.get("LowGraphics") == true then
			continue -- steady neon with Low Graphics (no light toggling)
		end
		for index, duration in BLINKS do
			setOff(part, index % 2 == 1, base)
			task.wait(duration)
		end
		setOff(part, false, base)
	end
	running[part] = nil
end

function NeonFlickerController.Start(_self: any)
	local function add(instance: Instance)
		if instance:IsA("BasePart") and not running[instance] then
			task.spawn(flicker, instance)
		end
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance: Instance)
		running[instance] = nil
	end)
	for _, instance in CollectionService:GetTagged(TAG) do
		add(instance)
	end
end

return NeonFlickerController
