--!strict
--[[
	PartyController — the Party screen and party invites (bible §5.3 / §8; server: PartyService). The screen lists
	your party (leader marked; the leader can remove members; anyone can leave) and the other players in the server
	with an Invite button (friends marked), plus the friend XP bonus you have right now. Party membership comes from
	the replicated Player attributes PartyId / PartyLeader. An invite (PartyInvited) shows a small Join / No popup at
	the top right that closes by itself when it runs out.
	Party bar (owner, 2026-10-18: "really show the players in the same party, their profile, 2/4"): while you are in a
	party, a strip at the top left shows "Party 2/4" and a card per member — their avatar headshot (a gold ring for
	the leader), name ("You" for yourself) and where they are (lobby, fighting, respawning, watching) — in the lobby
	and in rounds alike.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local MENU_ORDER = 7 -- after the bible's lobby screens (... Leaderboard, Settings)
local ROW_HEIGHT = 34 -- pixels
local REFRESH_INTERVAL = 1
local BAR_INTERVAL = 0.25 -- seconds between party bar updates
local LEADER_RING = Color3.fromHex("#F2C14E")
local STATUS_COLORS: { [string]: Color3 } = {
	Playing = Color3.fromHex("#7CE07C"),
	Respawning = Color3.fromHex("#F2C14E"),
	Spectating = Color3.fromHex("#A89A85"),
}

type Card = { Frame: Frame, Image: ImageLabel, Ring: UIStroke, Initial: TextLabel, Name: TextLabel, Status: TextLabel }

local PartyController = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local memberList: ScrollingFrame
local inviteList: ScrollingFrame
local leaveButton: TextButton
local bonusLabel: TextLabel
local friends: { [number]: boolean } = {}

local inviteGui: ScreenGui
local inviteLabel: TextLabel
local inviteFrom: number? = nil
local inviteEndsAt = 0

local bar: Frame
local barTitle: TextLabel
local cards: { Card } = {}

local function partyOf(other: Player): string?
	local partyId = other:GetAttribute("PartyId")
	return if type(partyId) == "string" then partyId else nil
end

local function isFriend(other: Player): boolean
	local known = friends[other.UserId]
	if known == nil then
		friends[other.UserId] = false -- asked once; filled in when Roblox answers
		task.spawn(function()
			local ok, result = pcall(function()
				return player:IsFriendsWith(other.UserId)
			end)
			friends[other.UserId] = ok and result == true
		end)
		return false
	end
	return known
end

local function clear(list: ScrollingFrame)
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- A round avatar headshot (Roblox's thumbnail; the name's first letter shows until it loads, or if it can't).
local function headshot(parent: GuiObject, size: UDim2, position: UDim2): (ImageLabel, UIStroke, TextLabel)
	local initial = Kit.label(parent, "", size, 24)
	initial.Position = position
	initial.BackgroundColor3 = Kit.Colors.Button
	initial.BackgroundTransparency = 0
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Parent = initial
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = initial
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = initial
	local imageCorner = corner:Clone()
	imageCorner.Parent = image
	local ring = Instance.new("UIStroke")
	ring.Thickness = 0
	ring.Color = LEADER_RING
	ring.Parent = initial
	return image, ring, initial
end

local function setHeadshot(image: ImageLabel, initial: TextLabel, other: Player)
	image.Image = `rbxthumb://type=AvatarHeadShot&id={other.UserId}&w=150&h=150`
	initial.Text = string.upper(string.sub(other.DisplayName, 1, 1))
end

local function row(
	list: ScrollingFrame,
	text: string,
	order: number,
	buttonText: string?,
	onClick: (() -> ())?,
	who: Player?
)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	frame.LayoutOrder = order
	frame.Parent = list
	local offset = 0
	if who then
		local image, _, initial = headshot(frame, UDim2.fromScale(0.09, 0.9), UDim2.fromScale(0, 0.05))
		setHeadshot(image, initial, who)
		offset = 0.11
	end
	local label = Kit.label(frame, text, UDim2.fromScale((if buttonText then 0.66 else 1) - offset, 1), 20)
	label.Position = UDim2.fromScale(offset, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	if buttonText and onClick then
		local button = Kit.button(frame, buttonText, UDim2.fromScale(0.32, 0.9))
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.fromScale(1, 0.5)
		button.Activated:Connect(onClick)
	end
end

local function render()
	clear(memberList)
	clear(inviteList)
	local myParty = partyOf(player)
	local amLeader = player:GetAttribute("PartyLeader") == true
	local others = Players:GetPlayers()
	table.sort(others, function(a: Player, b: Player): boolean
		return a.DisplayName < b.DisplayName
	end)

	-- Your party.
	local order = 0
	if myParty == nil then
		row(memberList, Localization.format("Party.Alone"), 1)
	else
		for _, member in others do
			if partyOf(member) == myParty then
				order += 1
				local leader = member:GetAttribute("PartyLeader") == true
				local text = if leader
					then Localization.format("Party.LeaderName", { member.DisplayName })
					else member.DisplayName
				local canKick = amLeader and member ~= player
				local kick = if canKick then Localization.format("Party.Kick") else nil
				row(memberList, text, order, kick, function()
					Net.fire("PartyKick", member.UserId)
				end, member)
			end
		end
	end
	leaveButton.Visible = myParty ~= nil

	-- Everyone else in the server.
	local friendCount = 0
	order = 0
	for _, other in others do
		if other ~= player then
			local friend = isFriend(other)
			if friend then
				friendCount += 1
			end
			if partyOf(other) == nil and (myParty == nil or amLeader) then
				order += 1
				local name = if friend
					then Localization.format("Party.FriendName", { other.DisplayName })
					else other.DisplayName
				row(inviteList, name, order, Localization.format("Party.Invite"), function()
					Net.fire("PartyInvite", other.UserId)
				end, other)
			end
		end
	end
	if order == 0 then
		row(inviteList, Localization.format("Party.NobodyToInvite"), 1)
	end
	local bonus = math.floor(Formulas.friendXPBonus(friendCount) * 100 + 0.5)
	bonusLabel.Text = Localization.format("Party.FriendBonus", { friendCount, bonus })
end

local function section(panel: Frame, titleKey: string, y: number, height: number): ScrollingFrame
	local title = Kit.label(panel, Localization.format(titleKey), UDim2.fromScale(1, 0.06), 22)
	title.Position = UDim2.fromScale(0, y)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Kit.Colors.Accent
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromScale(0, y + 0.07)
	list.Size = UDim2.fromScale(1, height)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = panel
	local layout = Kit.list(list, Enum.FillDirection.Vertical, UDim.new(0, 4))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	return list
end

local function build()
	gui = Kit.screen("Party", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.5, 0.74),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(620, 600)
	)
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.1)
	header.Parent = panel
	local title = Kit.label(header, Localization.format("Party.Title"), UDim2.fromScale(0.5, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.22, 0.9))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)
	leaveButton = Kit.button(header, Localization.format("Party.Leave"), UDim2.fromScale(0.22, 0.9))
	leaveButton.AnchorPoint = Vector2.new(1, 0)
	leaveButton.Position = UDim2.fromScale(0.76, 0)
	leaveButton.Activated:Connect(function()
		Net.fire("PartyLeave")
	end)

	local info = Kit.label(
		panel,
		Localization.format("Party.Info", { Config.Retention.Party.MaxSize }),
		UDim2.fromScale(1, 0.07),
		18
	)
	info.Position = UDim2.fromScale(0, 0.11)
	info.TextColor3 = Kit.Colors.Muted
	info.TextWrapped = true
	memberList = section(panel, "Party.Members", 0.19, 0.24)
	inviteList = section(panel, "Party.InviteTitle", 0.51, 0.34)
	bonusLabel = Kit.label(panel, "", UDim2.fromScale(1, 0.06), 18)
	bonusLabel.Position = UDim2.fromScale(0, 0.93)
	bonusLabel.TextColor3 = Kit.Colors.Muted
end

---------------------------------------------------------------------------------------------------------------------
-- Invite popup
---------------------------------------------------------------------------------------------------------------------

local function closeInvite()
	inviteFrom = nil
	inviteGui.Enabled = false
end

local function answer(accept: boolean)
	local from = inviteFrom
	if from then
		Net.fire("PartyRespond", from, accept)
	end
	closeInvite()
end

local function buildInvite()
	inviteGui = Kit.screen("PartyInvite", 9)
	local box = Kit.panel(
		inviteGui,
		UDim2.fromScale(0.26, 0.14),
		UDim2.fromScale(0.985, 0.22),
		Vector2.new(1, 0),
		Vector2.new(360, 140)
	)
	inviteLabel = Kit.label(box, "", UDim2.fromScale(1, 0.55), 20)
	inviteLabel.TextWrapped = true
	local join = Kit.button(box, Localization.format("Party.Join"), UDim2.fromScale(0.46, 0.34))
	join.Position = UDim2.fromScale(0.02, 0.62)
	Kit.setChosen(join, true)
	join.Activated:Connect(function()
		answer(true)
	end)
	local no = Kit.button(box, Localization.format("Party.No"), UDim2.fromScale(0.46, 0.34))
	no.Position = UDim2.fromScale(0.52, 0.62)
	no.Activated:Connect(function()
		answer(false)
	end)
end

local function onInvited(fromId: unknown, fromName: unknown, seconds: unknown)
	if type(fromId) ~= "number" or type(fromName) ~= "string" or type(seconds) ~= "number" then
		return
	end
	inviteFrom = fromId
	inviteEndsAt = os.clock() + seconds
	local args: { any } = { fromName, math.ceil(seconds) }
	inviteLabel.Text = Localization.format("Party.InvitedYou", args)
	inviteGui.Enabled = true
end

---------------------------------------------------------------------------------------------------------------------
-- Party bar
---------------------------------------------------------------------------------------------------------------------

local function buildCard(order: number): Card
	local frame = Instance.new("Frame")
	frame.Name = `Member{order}`
	frame.BackgroundColor3 = Kit.Colors.Panel
	frame.BackgroundTransparency = 0.25
	frame.Size = UDim2.fromScale(0.235, 1)
	frame.LayoutOrder = order
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.12, 0)
	corner.Parent = frame
	local image, ring, initial = headshot(frame, UDim2.fromScale(0.62, 0.56), UDim2.fromScale(0.19, 0.04))
	local name = Kit.label(frame, "", UDim2.fromScale(0.94, 0.2), 14)
	name.Position = UDim2.fromScale(0.03, 0.6)
	local status = Kit.label(frame, "", UDim2.fromScale(0.94, 0.18), 12)
	status.Position = UDim2.fromScale(0.03, 0.8)
	frame.Parent = bar:FindFirstChild("Cards")
	return { Frame = frame, Image = image, Ring = ring, Initial = initial, Name = name, Status = status }
end

local function buildBar()
	local screen = Kit.screen("PartyBar", 3)
	screen.Enabled = true
	bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BackgroundTransparency = 1
	bar.Position = UDim2.fromScale(0.01, 0.1)
	bar.Size = UDim2.fromScale(0.24, 0.15)
	bar.Visible = false
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(300, 120)
	limit.MinSize = Vector2.new(200, 84)
	limit.Parent = bar
	barTitle = Kit.label(bar, "", UDim2.fromScale(1, 0.22), 18)
	barTitle.TextXAlignment = Enum.TextXAlignment.Left
	barTitle.TextColor3 = Color3.fromHex(Config.Retention.Party.Color)
	local cardRow = Instance.new("Frame")
	cardRow.Name = "Cards"
	cardRow.BackgroundTransparency = 1
	cardRow.Position = UDim2.fromScale(0, 0.25)
	cardRow.Size = UDim2.fromScale(1, 0.75)
	cardRow.Parent = bar
	local layout = Kit.list(cardRow, Enum.FillDirection.Horizontal, UDim.new(0.02, 0))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bar.Parent = screen
end

-- The local player's party, the leader first, then by name.
local function partyMembers(): { Player }
	local myParty = partyOf(player)
	local members: { Player } = {}
	if myParty == nil then
		return members
	end
	for _, other in Players:GetPlayers() do
		if partyOf(other) == myParty then
			table.insert(members, other)
		end
	end
	table.sort(members, function(a: Player, b: Player): boolean
		local leaderA, leaderB = a:GetAttribute("PartyLeader") == true, b:GetAttribute("PartyLeader") == true
		if leaderA ~= leaderB then
			return leaderA
		end
		return a.DisplayName < b.DisplayName
	end)
	return members
end

local function renderBar()
	local members = partyMembers()
	bar.Visible = #members > 0
	if #members == 0 then
		return
	end
	local args: { any } = { #members, Config.Retention.Party.MaxSize }
	barTitle.Text = Localization.format("Party.Count", args)
	for index, member in members do
		local card = cards[index] or buildCard(index)
		cards[index] = card
		card.Frame.Visible = true
		setHeadshot(card.Image, card.Initial, member)
		card.Ring.Thickness = if member:GetAttribute("PartyLeader") == true then 3 else 0
		card.Name.Text = if member == player then Localization.format("Party.You") else member.DisplayName
		local status = member:GetAttribute("RoundStatus")
		local statusName = if type(status) == "string" and STATUS_COLORS[status] then status else "Lobby"
		card.Status.Text = Localization.format(`Party.Status.{statusName}`)
		card.Status.TextColor3 = STATUS_COLORS[statusName] or Kit.Colors.Muted
	end
	for index = #members + 1, #cards do
		cards[index].Frame.Visible = false
	end
end

function PartyController.Start(_self: any)
	build()
	buildInvite()
	buildBar()
	MenuController.addScreen(Localization.format("Menu.Party"), MENU_ORDER, gui, render)
	Net.on("PartyInvited", onInvited)
	local elapsed, barElapsed = 0, BAR_INTERVAL
	RunService.Heartbeat:Connect(function(deltaTime: number)
		if inviteFrom and os.clock() >= inviteEndsAt then
			closeInvite()
		end
		barElapsed += deltaTime
		if barElapsed >= BAR_INTERVAL then
			barElapsed = 0
			renderBar() -- members joining / leaving and where they are
		end
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL and gui.Enabled then
			elapsed = 0
			render() -- party changes, players joining / leaving, friend answers
		end
	end)
end

return PartyController
