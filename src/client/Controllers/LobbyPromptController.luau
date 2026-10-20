--!strict
--[[
	LobbyPromptController — walk-up menus in the lobby (owner, 2026-10-17): a ProximityPrompt on the bartender
	(ShopNPC tag) opens the Shop, one in the locker booth (Locker tag) opens the Inventory, one at the quest board
	(QuestBoard tag) opens the Quests screen, one at the codes jukebox (CodesJukebox tag) opens Settings on the Promo
	code tab (the spin wheel has its own prompt: WheelController). They open through MenuController, so its
	rules apply (one screen at a time, never while fighting), and hide while a menu screen is open or the player is
	fighting. Keys and range: Config.Controls.Prompts (E / gamepad B; touch taps). The prompts are made here on the
	client — opening a screen needs nothing from the server — and come back when a streamed-out part streams in again.
	Later lobby screens add a target here.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))

local MenuController = require(script.Parent:WaitForChild("MenuController"))

local PROMPT_NAME = "MenuPrompt"
local REFRESH_INTERVAL = 0.25

-- Tag: the lobby model's tag; Part: the child the prompt sits on; Screen: the menu ScreenGui's name.
type Target = { Tag: string, Part: string, Screen: string, Arg: string?, Action: string, Object: string }

local LobbyPromptController = {}

local prompts: { ProximityPrompt } = {}

local function targets(): { Target }
	return {
		{
			Tag = "ShopNPC",
			Part = "Torso",
			Screen = "Shop",
			Action = Localization.format("Prompt.Shop"),
			Object = Localization.format("Prompt.Shop.Object"),
		},
		{
			Tag = "Locker",
			Part = "Back",
			Screen = "Locker",
			Action = Localization.format("Prompt.Locker"),
			Object = Localization.format("Prompt.Locker.Object"),
		},
		{
			Tag = "QuestBoard",
			Part = "Board",
			Screen = "Quests",
			Action = Localization.format("Prompt.Quests"),
			Object = Localization.format("Prompt.Quests.Object"),
		},
		{
			Tag = "CodesJukebox",
			Part = "Body",
			Screen = "Settings",
			Arg = "Codes", -- the Promo code tab
			Action = Localization.format("Prompt.Codes"),
			Object = Localization.format("Prompt.Codes.Object"),
		},
	}
end

local function addPrompt(target: Target, part: BasePart)
	if part:FindFirstChild(PROMPT_NAME) then
		return
	end
	local config = Config.Controls.Prompts
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = target.Action
	prompt.ObjectText = target.Object
	prompt.KeyboardKeyCode = (Enum.KeyCode :: any)[config.Keyboard]
	prompt.GamepadKeyCode = (Enum.KeyCode :: any)[config.Gamepad]
	prompt.MaxActivationDistance = config.MaxDistance
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Enabled = not MenuController.isFighting() and not MenuController.isOpen()
	prompt.Triggered:Connect(function()
		MenuController.openNamed(target.Screen, target.Arg)
	end)
	prompt.Parent = part
	table.insert(prompts, prompt)
end

-- Puts the prompt on the target part of a tagged model, now or whenever that part streams in.
local function watch(target: Target, model: Instance)
	local function try(child: Instance)
		if child.Name == target.Part and child:IsA("BasePart") then
			addPrompt(target, child)
		end
	end
	for _, child in model:GetChildren() do
		try(child)
	end
	model.ChildAdded:Connect(try)
end

local function refresh()
	local enabled = not MenuController.isFighting() and not MenuController.isOpen()
	for index = #prompts, 1, -1 do
		local prompt = prompts[index]
		if prompt.Parent == nil then
			table.remove(prompts, index) -- its part streamed out or was removed
		else
			prompt.Enabled = enabled
		end
	end
end

function LobbyPromptController.Start(_self: any)
	for _, target in targets() do
		for _, model in CollectionService:GetTagged(target.Tag) do
			watch(target, model)
		end
		CollectionService:GetInstanceAddedSignal(target.Tag):Connect(function(model: Instance)
			watch(target, model)
		end)
	end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return LobbyPromptController
