--!strict
--[[
	DailyRewardController — the Daily reward screen (bible §5.3 / §8; Shared/DailyRules): the 7-day login streak as a
	row of day cards (claimed, today's, still to come; day 7 shows the week's cosmetic), a Claim button or the time
	until the next reward, and today's playtime rewards. Claim asks the server (ClaimDaily), which checks everything
	again. It opens by itself once per session when a reward is waiting (not while fighting) and from the Quests screen's
	Daily reward tab — it has no menu button (owner's fix list, 2026-10-19: "daily reward pops up on login; quests can
	be checked there", so the two screens share a tab row). In a private server that pays nothing it says rewards come
	in public servers.
]]
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DailyRules = require(Shared:WaitForChild("DailyRules"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local DataController = require(script.Parent:WaitForChild("DataController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local MENU_ORDER = 5 -- no button; after Quests, whose tab row it shares
local TICK_INTERVAL = 1
local AUTO_OPEN_DELAY = 3 -- seconds after the data loads, so the player sees the lobby first

local DailyRewardController = {}

local gui: ScreenGui
local cards: { TextLabel } = {}
local claimButton: TextButton
local statusLabel: TextLabel
local playtimeLabel: TextLabel
local claiming = false

local function today(): number
	return DailyRules.dayAt(Workspace:GetServerTimeNow())
end

local function paysRewards(): boolean
	return Workspace:GetAttribute("PrivateServer") ~= true or Config.Economy.PrivateServerRewardScale > 0
end

local function rewardText(day: number, owned: { [string]: boolean }): string
	local reward = DailyRules.reward(day, today(), owned)
	if reward.Cosmetic then
		return Localization.format(`Cosmetic.{reward.Cosmetic}.Name`)
	end
	return Localization.format("Currency.Scrap", { reward.Scrap })
end

local function playtimeText(): string
	local data = DataController.get()
	if data == nil then
		return ""
	end
	local config = Config.Retention.Playtime
	local day = today()
	local state = DailyRules.addPlaytime(data.Daily, day, 0)
	local left = DailyRules.nextPlaytimeIn(data.Daily, day)
	if left == nil then
		return Localization.format("Daily.PlaytimeDone", { config.MaxClaimsPerDay })
	end
	local args: { any } = { config.Scrap, config.Interval // 60, state.Claims + state.Due, config.MaxClaimsPerDay }
	return Localization.format("Daily.Playtime", args)
end

local function render()
	local data = DataController.get()
	if data == nil then
		return
	end
	local day = today()
	local claimable = DailyRules.claimDay(data.Daily, day)
	local shown = claimable or data.Daily.Streak
	local claimedCount = if claimable then claimable - 1 else data.Daily.Streak
	for index, card in cards do
		local claimed = index <= claimedCount
		local current = index == shown
		local state = if claimed
			then Localization.format("Daily.Claimed")
			elseif current then Localization.format("Daily.Today")
			else ""
		card.Text = `{Localization.format("Daily.Day", { index })}\n{rewardText(index, data.Cosmetics.Owned)}\n{state}`
		card.TextTransparency = if claimed and not current then 0.45 else 0
		card.BackgroundColor3 = if current then Kit.Colors.Accent else Kit.Colors.Button
	end
	local seconds =
		Formulas.secondsUntilNextDay(Workspace:GetServerTimeNow(), Config.Retention.LoginStreak.ResetHourUTC)
	if not paysRewards() then
		claimButton.Visible = false
		statusLabel.Text = Localization.format("Daily.Error.PrivateServer")
	elseif claimable then
		claimButton.Visible = true
		claimButton.Text = Localization.format(if claiming then "Daily.Claiming" else "Daily.Claim")
		statusLabel.Text = Localization.format("Daily.Info")
	else
		claimButton.Visible = false
		statusLabel.Text = Localization.format("Daily.ComeBack", { HudFormat.longClock(seconds) })
	end
	playtimeLabel.Text = playtimeText()
end

local function claim()
	if claiming then
		return
	end
	claiming = true
	render()
	task.spawn(function()
		local ok, claimed, result = pcall(Net.invoke, "ClaimDaily")
		claiming = false
		if ok and claimed == true and type(result) == "table" then
			local what = if result.Cosmetic
				then Localization.format(`Cosmetic.{result.Cosmetic}.Name`)
				else Localization.format("Currency.Scrap", { result.Scrap })
			statusLabel.Text = Localization.format("Daily.Got", { what })
		else
			local why = if ok
					and typeof(result) == "string"
					and table.find(DailyRules.Reasons, result)
				then result
				else "TryAgain"
			statusLabel.Text = Localization.format(`Daily.Error.{why}`)
		end
		render()
	end)
end

local function onOpen()
	render()
	if InputController.getDevice() == "Gamepad" and claimButton.Visible then
		GuiService.SelectedObject = claimButton
	end
end

local function build()
	gui = Kit.screen("DailyReward", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.66, 0.62),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(880, 500)
	)

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.15)
	header.Parent = panel
	local tabs = Kit.tabRow(
		header,
		{ Localization.format("Daily.Title"), Localization.format("Quests.Title") },
		UDim2.fromScale(0, 0),
		UDim2.fromScale(0.7, 0.9),
		0.4
	)
	Kit.setChosen(tabs[1], true)
	tabs[2].Activated:Connect(function()
		MenuController.openNamed("Quests")
	end)
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.18, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromScale(0, 0.19)
	row.Size = UDim2.fromScale(1, 0.4)
	row.Parent = panel
	Kit.list(row, Enum.FillDirection.Horizontal, UDim.new(0.01, 0))
	for index = 1, DailyRules.Days do
		local card = Kit.label(row, "", UDim2.fromScale(0.13, 1), 20)
		card.LayoutOrder = index
		card.BackgroundTransparency = 0.1
		card.TextWrapped = true
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.12, 0)
		corner.Parent = card
		cards[index] = card
	end

	claimButton = Kit.button(panel, Localization.format("Daily.Claim"), UDim2.fromScale(0.3, 0.13))
	claimButton.AnchorPoint = Vector2.new(0.5, 0)
	claimButton.Position = UDim2.fromScale(0.5, 0.63)
	Kit.setChosen(claimButton, true)
	claimButton.Activated:Connect(claim)

	statusLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.08), 20)
	statusLabel.Position = UDim2.fromScale(0, 0.79)
	playtimeLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.08), 18)
	playtimeLabel.Position = UDim2.fromScale(0, 0.89)
	playtimeLabel.TextColor3 = Kit.Colors.Muted
end

-- Opens the screen once per session when today's reward is waiting.
local function autoOpen()
	DataController.waitForData()
	task.wait(AUTO_OPEN_DELAY)
	local data = DataController.get()
	if
		data
		and paysRewards()
		and DailyRules.claimDay(data.Daily, today()) ~= nil
		and not MenuController.isFighting()
		and not MenuController.isOpen()
	then
		MenuController.open(gui)
	end
end

function DailyRewardController.Start(_self: any)
	build()
	MenuController.addScreen(nil, MENU_ORDER, gui, onOpen)
	DataController.Changed:Connect(function(key: string)
		if gui.Enabled and (key == "Daily" or key == "Cosmetics") then
			render()
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= TICK_INTERVAL and gui.Enabled then
			elapsed = 0
			render() -- the countdown, and a new day while the screen is open
		end
	end)
	task.spawn(autoOpen)
end

return DailyRewardController
