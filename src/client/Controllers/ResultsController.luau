--!strict
--[[
	ResultsController — the standings panel shown after a round (RoundResults), while RoundState is "Results".
	Lists the top MAX_ROWS players with KOs and falls (Casual: score too); the local player's row is highlighted.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))

local MAX_ROWS = 10

type Row = {
	UserId: number,
	Name: string,
	Placement: number,
	KOs: number,
	Falls: number,
	Score: number,
	Lives: number?,
}

local ResultsController = {}

local gui: ScreenGui
local list: Frame
local winnerLabel: TextLabel
local rewardLabel: TextLabel

-- What the local player earned (RoundReward arrives just after RoundResults).
-- In a private server that pays nothing (Economy.PrivateServerRewardScale 0) the line says so instead.
local function onReward(scrap: number, xp: number, level: number, levelsGained: number, newRank: string?)
	if Workspace:GetAttribute("PrivateServer") == true and Config.Economy.PrivateServerRewardScale <= 0 then
		rewardLabel.Text = Localization.format("Results.PrivateServer")
		return
	end
	local lines = { Localization.format("Results.Reward", { scrap, xp }) }
	if levelsGained > 0 then
		table.insert(lines, Localization.format("Results.LevelUp", { level }))
	end
	if newRank then
		table.insert(lines, Localization.format("Results.NewRank", { Localization.format(`Rank.{newRank}`) }))
	end
	rewardLabel.Text = table.concat(lines, "   ")
end

local function rowText(row: Row, modeId: string): string
	if Config.Modes.List[modeId] and Config.Modes.List[modeId].Lives == nil then
		local casual: { any } = { row.Placement, row.Name, row.Score, row.KOs, row.Falls }
		return Localization.format("Results.RowCasual", casual)
	end
	local classic: { any } = { row.Placement, row.Name, row.KOs, row.Falls }
	return Localization.format("Results.RowClassic", classic)
end

local function onResults(rows: { Row }, modeId: string, _mapId: string)
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local winners: { string } = {}
	for _, row in rows do
		if row.Placement == 1 then
			table.insert(winners, row.Name)
		end
	end
	winnerLabel.Text = if #winners > 0
		then Localization.format("Results.Winner", { table.concat(winners, ", ") })
		else Localization.format("Results.NoWinner")

	local height = 1 / MAX_ROWS
	for index = 1, math.min(#rows, MAX_ROWS) do
		local row = rows[index]
		local label = Kit.label(list, rowText(row, modeId), UDim2.fromScale(1, height * 0.9), 22)
		label.LayoutOrder = index
		label.TextXAlignment = Enum.TextXAlignment.Left
		if row.UserId == Players.LocalPlayer.UserId then
			label.TextColor3 = Kit.Colors.Accent
		end
	end
	gui.Enabled = true
end

local function build()
	gui = Kit.screen("Results", 6)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.5, 0.66),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(560, 480)
	)
	Kit.list(panel, Enum.FillDirection.Vertical, UDim.new(0.02, 0))
	local title = Kit.label(panel, Localization.format("Results.Title"), UDim2.fromScale(1, 0.13))
	title.Font = Kit.TitleFont
	title.LayoutOrder = 1
	winnerLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.1))
	winnerLabel.TextColor3 = Kit.Colors.Accent
	winnerLabel.LayoutOrder = 2
	rewardLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.08), 20)
	rewardLabel.LayoutOrder = 3
	list = Instance.new("Frame")
	list.Name = "Standings"
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromScale(1, 0.62)
	list.LayoutOrder = 4
	list.Parent = panel
	Kit.list(list, Enum.FillDirection.Vertical, UDim.new(0.01, 0))
end

function ResultsController.Start(_self: any)
	build()
	Net.on("RoundResults", onResults)
	Net.on("RoundReward", onReward)
	Workspace:GetAttributeChangedSignal("RoundState"):Connect(function()
		if Workspace:GetAttribute("RoundState") ~= "Results" then
			gui.Enabled = false
			rewardLabel.Text = "" -- the reward may arrive before or after the standings; clear it once they close
		end
	end)
end

return ResultsController
