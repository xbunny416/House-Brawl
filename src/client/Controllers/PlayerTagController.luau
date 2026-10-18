--!strict
--[[
	PlayerTagController — name tags over other players and tags in front of chat messages (bible §7 / §8), from the
	replicated Player attributes VIP (MonetizationService), PartyId (PartyService) and GroupMember (GroupRewardService):
	  * Name tag: another player who is VIP or in your party gets their overhead name replaced by one that shows it —
	    "[VIP]" in gold (Config.Monetization.VIPColor) and the name in your party's color
	    (Config.Retention.Party.Color) or gold. Your own name stays hidden, as Roblox does by default.
	  * Chat: "[VIP]", "[Crew]" (the Roblox group) and "[Party]" (only for your own party's messages) go in front of
	    a message (TextChatService).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))

local TAG_NAME = "PlayerNameTag"
local TAG_SIZE = UDim2.fromScale(7, 0.9) -- studs
local TAG_OFFSET = Vector3.new(0, 2.3, 0) -- studs above the head's center
local TAG_DISTANCE = 100 -- studs, like Roblox's own name display
local CHARACTER_WAIT = 10
local WATCHED = { "VIP", "PartyId", "GroupMember" }

local PlayerTagController = {}

local localPlayer = Players.LocalPlayer

local function isVIP(player: Player): boolean
	return player:GetAttribute("VIP") == true
end

-- True if `player` is in the local player's party (and isn't the local player).
local function inMyParty(player: Player): boolean
	local mine = localPlayer:GetAttribute("PartyId")
	return player ~= localPlayer and type(mine) == "string" and player:GetAttribute("PartyId") == mine
end

local function colored(color: string, text: string): string
	return `<font color="{color}">{text}</font>`
end

-- Puts on, updates or takes off the name tag (the default name hides while it shows).
local function applyNameTag(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if head == nil or humanoid == nil then
		return
	end
	local vip, party = isVIP(player), inMyParty(player)
	local show = vip or party
	humanoid.DisplayDistanceType = if show
		then Enum.HumanoidDisplayDistanceType.None
		else Enum.HumanoidDisplayDistanceType.Viewer
	local tag = head:FindFirstChild(TAG_NAME)
	if not show then
		if tag then
			tag:Destroy()
		end
		return
	end
	local label: TextLabel
	if tag and tag:IsA("BillboardGui") then
		label = tag:FindFirstChildOfClass("TextLabel") :: TextLabel
	else
		local billboard = Instance.new("BillboardGui")
		billboard.Name = TAG_NAME
		billboard.Size = TAG_SIZE
		billboard.StudsOffset = TAG_OFFSET
		billboard.MaxDistance = TAG_DISTANCE
		billboard.LightInfluence = 0
		billboard.AlwaysOnTop = true
		label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Kit.TitleFont
		label.TextScaled = true
		label.RichText = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.Parent = billboard
		billboard.Parent = head
	end
	local nameColor = if party then Config.Retention.Party.Color else Config.Monetization.VIPColor
	local name = colored(nameColor, player.DisplayName)
	label.Text = if vip
		then `{colored(Config.Monetization.VIPColor, Localization.format("Tag.VIPChat"))} {name}`
		else name
end

local function refreshAll()
	for _, player in Players:GetPlayers() do
		if player ~= localPlayer then
			task.spawn(applyNameTag, player)
		end
	end
end

local function watch(player: Player)
	if player == localPlayer then
		localPlayer:GetAttributeChangedSignal("PartyId"):Connect(refreshAll)
		return
	end
	player.CharacterAdded:Connect(function(character: Model)
		if character:WaitForChild("Head", CHARACTER_WAIT) and character:WaitForChild("Humanoid", CHARACTER_WAIT) then
			applyNameTag(player)
		end
	end)
	for _, attribute in WATCHED do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			applyNameTag(player)
		end)
	end
	task.spawn(applyNameTag, player)
end

local function onIncomingMessage(message: TextChatMessage): TextChatMessageProperties?
	local source = message.TextSource
	local sender = if source then Players:GetPlayerByUserId(source.UserId) else nil
	if sender == nil then
		return nil
	end
	local tags: { string } = {}
	if isVIP(sender) then
		table.insert(tags, colored(Config.Monetization.VIPColor, Localization.format("Tag.VIPChat")))
	end
	if sender:GetAttribute("GroupMember") == true then
		table.insert(tags, colored("#" .. Kit.Colors.Accent:ToHex(), Localization.format("Tag.GroupChat")))
	end
	local mine = localPlayer:GetAttribute("PartyId")
	if type(mine) == "string" and sender:GetAttribute("PartyId") == mine then
		table.insert(tags, colored(Config.Retention.Party.Color, Localization.format("Tag.PartyChat")))
	end
	if #tags == 0 then
		return nil
	end
	local properties = Instance.new("TextChatMessageProperties")
	properties.PrefixText = `{table.concat(tags, " ")} {message.PrefixText}`
	return properties
end

function PlayerTagController.Start(_self: any)
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		TextChatService.OnIncomingMessage = onIncomingMessage
	end
end

return PlayerTagController
