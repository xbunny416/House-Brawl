--!strict
--[[
	VoteController — the map + mode vote panel (top of the screen) shown while RoundState is "Voting", to players
	standing on the lobby join pad (QueueStatus In / AFK). One button per map and per mode with its vote count; the
	player's own choices are highlighted. With a gamepad the first button is selected when the panel opens.
]]
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local REFRESH_INTERVAL = 0.25

local player = Players.LocalPlayer
local wasVoting = false

-- One row of the ballot (maps or modes).
type Section = {
	Kind: string, -- "Map" | "Mode" (the Vote remote's first argument)
	NameKey: (id: string) -> string,
	Row: Frame?,
	Options: { string },
	Buttons: { [string]: TextButton },
	Chosen: string?,
}

local VoteController = {}

local gui: ScreenGui
local timeLabel: TextLabel
local maps: Section = {
	Kind = "Map",
	NameKey = function(id: string): string
		return `Map.{id}.Name`
	end,
	Row = nil,
	Options = {},
	Buttons = {},
	Chosen = nil,
}
local modes: Section = {
	Kind = "Mode",
	NameKey = function(id: string): string
		return `Mode.{id}.Name`
	end,
	Row = nil,
	Options = {},
	Buttons = {},
	Chosen = nil,
}

local function refreshChosen(section: Section)
	for id, button in section.Buttons do
		Kit.setChosen(button, section.Chosen == id)
	end
end

local function rebuild(section: Section, ids: { string })
	for _, button in section.Buttons do
		button:Destroy()
	end
	section.Buttons = {}
	section.Options = table.clone(ids)
	section.Chosen = nil
	local width = 1 / math.max(#ids, 1) - 0.03
	for index, id in ids do
		local button = Kit.button(section.Row :: Frame, "", UDim2.fromScale(width, 1))
		button.Name = id
		button.LayoutOrder = index
		button.Activated:Connect(function()
			section.Chosen = id
			refreshChosen(section)
			Net.fire("Vote", section.Kind, id)
		end)
		section.Buttons[id] = button
	end
end

local function update(section: Section, ids: { string }, counts: { [string]: number })
	if table.concat(ids, ",") ~= table.concat(section.Options, ",") then
		rebuild(section, ids)
	end
	-- A choice of one is no choice: hide its row (Classic is the only mode).
	local row = section.Row
	if row then
		row.Visible = #ids > 1
	end
	for id, button in section.Buttons do
		local votes = Localization.format("Vote.Votes", { counts[id] or 0 })
		button.Text = `{Localization.format(section.NameKey(id))}\n{votes}`
	end
	refreshChosen(section)
end

local function onVoteState(
	mapIds: { string },
	modeIds: { string },
	mapCounts: { [string]: number },
	modeCounts: { [string]: number }
)
	update(maps, mapIds, mapCounts)
	update(modes, modeIds, modeCounts)
end

local function refresh()
	local inVote = Workspace:GetAttribute("RoundState") == "Voting"
	if wasVoting and not inVote then
		-- The next vote brings a new ballot.
		maps.Options, modes.Options = {}, {}
	end
	wasVoting = inVote
	-- Only players on the join pad vote (RoundService drops the vote of anyone who steps off).
	local queue = player:GetAttribute("QueueStatus")
	local voting = inVote and #maps.Options > 0 and (queue == "In" or queue == "AFK")
	if voting ~= gui.Enabled then
		gui.Enabled = voting
		if voting and InputController.getDevice() == "Gamepad" then
			local first = maps.Buttons[maps.Options[1]]
			if first then
				GuiService.SelectedObject = first
			end
		end
	end
	if voting then
		local endsAt = Workspace:GetAttribute("RoundEndsAt")
		local left = if type(endsAt) == "number"
			then math.max(math.ceil(endsAt - Workspace:GetServerTimeNow()), 0)
			else 0
		timeLabel.Text = Localization.format("Vote.TimeLeft", { left })
	end
end

local function build()
	gui = Kit.screen("Vote", 5)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.62, 0.38),
		UDim2.fromScale(0.5, 0.02),
		Vector2.new(0.5, 0),
		Vector2.new(760, 320)
	)
	Kit.list(panel, Enum.FillDirection.Vertical, UDim.new(0.03, 0))

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.2)
	header.LayoutOrder = 1
	header.Parent = panel
	Kit.list(header, Enum.FillDirection.Horizontal, UDim.new(0.02, 0))
	local title = Kit.label(header, Localization.format("Vote.Title"), UDim2.fromScale(0.78, 1))
	title.Font = Kit.TitleFont
	title.LayoutOrder = 1
	timeLabel = Kit.label(header, "", UDim2.fromScale(0.18, 1))
	timeLabel.TextColor3 = Kit.Colors.Accent
	timeLabel.LayoutOrder = 2

	for order, section in { maps, modes } do
		local row = Instance.new("Frame")
		row.Name = section.Kind
		row.BackgroundTransparency = 1
		row.Size = UDim2.fromScale(1, 0.36)
		row.LayoutOrder = order + 1
		row.Parent = panel
		Kit.list(row, Enum.FillDirection.Horizontal, UDim.new(0.03, 0))
		section.Row = row
	end
end

function VoteController.Start(_self: any)
	build()
	Net.on("VoteState", onVoteState) -- after build: a ballot sent before this script ran is queued until now
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return VoteController
