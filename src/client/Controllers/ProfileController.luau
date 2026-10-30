--!strict
--[[
	ProfileController — the coins and level block on the left, above the lobby menu (owner's fix list, 2026-10-19:
	"coins" in the left UI, like the reference): a gold coin with the balance in big numbers ("1,234", COINS under
	it), the level and rank title, and an XP bar to the next level. It reads the player's own data
	(DataController) and hides while the player is fighting, like the menu, so nothing covers the arena.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local ProfileController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local coinsLabel: TextLabel
local levelLabel: TextLabel
local xpFill: Frame
local xpLabel: TextLabel

local function render()
	local data = DataController.get()
	if data == nil then
		return
	end
	coinsLabel.Text = HudFormat.thousands(data.Scrap)
	local args: { any } = { data.Level, Localization.format(`Rank.{Formulas.rankForLevel(data.Level)}`) }
	levelLabel.Text = Localization.format("Profile.Level", args)
	local needed = Formulas.xpToNextLevel(data.Level)
	if needed <= 0 then
		xpFill.Size = UDim2.fromScale(1, 1)
		xpLabel.Text = Localization.format("Profile.MaxLevel")
	else
		xpFill.Size = UDim2.fromScale(math.clamp(data.XP / needed, 0, 1), 1)
		xpLabel.Text = Localization.format("Profile.XP", { data.XP, needed })
	end
end

local function build()
	gui = Kit.screen("Profile", 4)
	-- Top left, under Roblox's buttons and above the menu (MenuController's bar starts at 0.36).
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.12, 0.19),
		UDim2.fromScale(0.01, 0.14),
		Vector2.new(0, 0),
		Vector2.new(170, 130)
	)

	local coin = Instance.new("Frame")
	coin.Name = "Coin"
	coin.BackgroundColor3 = Kit.Colors.Coin
	coin.Size = UDim2.fromScale(0.22, 0.36)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = coin
	local rim = Instance.new("UIStroke")
	rim.Color = Kit.Colors.Accent
	rim.Thickness = 2
	rim.Parent = coin
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = coin
	coin.Parent = panel

	coinsLabel = Kit.label(panel, "", UDim2.fromScale(0.72, 0.27), 30)
	coinsLabel.Position = UDim2.fromScale(0.28, 0)
	coinsLabel.Font = Kit.TitleFont
	coinsLabel.TextColor3 = Kit.Colors.Coin
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	local coinsName = Kit.label(panel, Localization.format("Profile.Coins"), UDim2.fromScale(0.72, 0.12), 14)
	coinsName.Position = UDim2.fromScale(0.28, 0.26)
	coinsName.TextColor3 = Kit.Colors.Muted
	coinsName.TextXAlignment = Enum.TextXAlignment.Left

	levelLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.2), 18)
	levelLabel.Position = UDim2.fromScale(0, 0.45)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left

	local bar = Instance.new("Frame")
	bar.Name = "XP"
	bar.BackgroundColor3 = Kit.Colors.Button
	bar.Position = UDim2.fromScale(0, 0.7)
	bar.Size = UDim2.fromScale(1, 0.28)
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.3, 0)
	barCorner.Parent = bar
	bar.Parent = panel
	xpFill = Instance.new("Frame")
	xpFill.BackgroundColor3 = Kit.Colors.Accent
	xpFill.BorderSizePixel = 0
	xpFill.Size = UDim2.fromScale(0, 1)
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.3, 0)
	fillCorner.Parent = xpFill
	xpFill.Parent = bar
	xpLabel = Kit.label(bar, "", UDim2.fromScale(1, 1), 14)
	xpLabel.ZIndex = 2
	-- A dark outline keeps it readable where it lies over the bright fill.
	xpLabel.TextStrokeColor3 = Kit.Colors.Panel
	xpLabel.TextStrokeTransparency = 0.2
end

local function refreshVisible()
	gui.Enabled = DataController.get() ~= nil and not MenuController.isFighting()
end

function ProfileController.Start(_self: any)
	build()
	DataController.Changed:Connect(function(key: string)
		if key == "Scrap" or key == "Level" or key == "XP" then
			render()
		end
		refreshVisible()
	end)
	player:GetAttributeChangedSignal("RoundStatus"):Connect(refreshVisible)
	task.spawn(function()
		DataController.waitForData()
		render()
		refreshVisible()
	end)
end

return ProfileController
