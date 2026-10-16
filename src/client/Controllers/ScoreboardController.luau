--!strict
--[[
	ScoreboardController — the round scoreboard, shown while the Scoreboard action is held (Tab / D-pad Down; no touch
	button, as in the bible). It replaces Roblox's player list. During a round, fighters come first (Classic: lives,
	KOs, falls; Casual: score); everyone else is listed with their level.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local REFRESH_INTERVAL = 0.25
local MAX_ROWS = 12

local ScoreboardController = {}

local gui: ScreenGui
local list: Frame

local function numberAttribute(target: Instance, name: string): number?
	local value = target:GetAttribute(name)
	return if type(value) == "number" then value else nil
end

local function rowText(player: Player, row: HudFormat.ScoreRow, hasLives: boolean): string
	local level = numberAttribute(player, "Level") or 1
	if not row.InRound then
		local args: { any } = { player.DisplayName, level }
		return Localization.format("Scoreboard.RowLobby", args)
	end
	if hasLives then
		local args: { any } = { player.DisplayName, level, row.Lives or 0, row.KOs, row.Falls }
		return Localization.format("Scoreboard.RowClassic", args)
	end
	local args: { any } = { player.DisplayName, level, row.KOs - row.Falls, row.KOs, row.Falls }
	return Localization.format("Scoreboard.RowCasual", args)
end

local function refresh()
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local modeId = Workspace:GetAttribute("RoundMode")
	local mode = if type(modeId) == "string" then Config.Modes.List[modeId] else nil
	local hasLives = mode ~= nil and mode.Lives ~= nil
	local rows: { HudFormat.ScoreRow } = {}
	local playerOf: { [HudFormat.ScoreRow]: Player } = {}
	for _, player in Players:GetPlayers() do
		local kos = numberAttribute(player, "KOs")
		local row: HudFormat.ScoreRow = {
			Name = player.DisplayName,
			Lives = if hasLives then numberAttribute(player, "Lives") else nil,
			KOs = kos or 0,
			Falls = numberAttribute(player, "Falls") or 0,
			InRound = kos ~= nil,
		}
		table.insert(rows, row)
		playerOf[row] = player
	end
	for index, row in HudFormat.sortScoreboard(rows) do
		if index > MAX_ROWS then
			break
		end
		local player = playerOf[row]
		local label = Kit.label(list, rowText(player, row, hasLives), UDim2.fromScale(1, 1 / MAX_ROWS * 0.9), 20)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = index
		if player == Players.LocalPlayer then
			label.TextColor3 = Kit.Colors.Accent
		end
	end
end

local function build()
	gui = Kit.screen("Scoreboard", 7)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.5, 0.62),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(620, 480)
	)
	Kit.list(panel, Enum.FillDirection.Vertical, UDim.new(0.02, 0))
	local title = Kit.label(panel, Localization.format("Scoreboard.Title"), UDim2.fromScale(1, 0.1))
	title.Font = Kit.TitleFont
	title.LayoutOrder = 1
	list = Instance.new("Frame")
	list.Name = "Rows"
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromScale(1, 0.86)
	list.LayoutOrder = 2
	list.Parent = panel
	Kit.list(list, Enum.FillDirection.Vertical, UDim.new(0.005, 0)).VerticalAlignment = Enum.VerticalAlignment.Top
end

function ScoreboardController.Start(_self: any)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)
	build()
	InputController.ActionBegan:Connect(function(action: string)
		if action == "Scoreboard" then
			refresh()
			gui.Enabled = true
		end
	end)
	InputController.ActionEnded:Connect(function(action: string)
		if action == "Scoreboard" then
			gui.Enabled = false
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if gui.Enabled and elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return ScoreboardController
