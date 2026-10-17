--!strict
--[[
	PlayerTagController — the VIP pass's gold name tag and [VIP] chat tag (bible §7), from the replicated Player
	attribute VIP (MonetizationService). Name tag: another VIP player's overhead name becomes a gold one
	(Config.Monetization.VIPColor) with the VIP tag; your own name stays hidden, as Roblox does by default. Chat: the
	gold [VIP] tag goes in front of a VIP player's messages (TextChatService). Party / group tags join here (3.7).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))

local TAG_NAME = "VIPNameTag"
local TAG_SIZE = UDim2.fromScale(6, 0.9) -- studs
local TAG_OFFSET = Vector3.new(0, 2.3, 0) -- studs above the head's center
local TAG_DISTANCE = 100 -- studs, like Roblox's own name display
local CHARACTER_WAIT = 10

local PlayerTagController = {}

local localPlayer = Players.LocalPlayer

local function isVIP(player: Player): boolean
	return player:GetAttribute("VIP") == true
end

-- Puts on or takes off the gold name tag (VIP players only; the default name hides while it shows).
local function applyNameTag(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if head == nil or humanoid == nil then
		return
	end
	local vip = isVIP(player)
	humanoid.DisplayDistanceType = if vip
		then Enum.HumanoidDisplayDistanceType.None
		else Enum.HumanoidDisplayDistanceType.Viewer
	local old = head:FindFirstChild(TAG_NAME)
	if old and not vip then
		old:Destroy()
	end
	if not vip or old then
		return
	end
	local tag = Instance.new("BillboardGui")
	tag.Name = TAG_NAME
	tag.Size = TAG_SIZE
	tag.StudsOffset = TAG_OFFSET
	tag.MaxDistance = TAG_DISTANCE
	tag.LightInfluence = 0
	tag.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Kit.TitleFont
	label.TextScaled = true
	label.TextColor3 = Color3.fromHex(Config.Monetization.VIPColor)
	label.TextStrokeTransparency = 0.3
	label.Text = Localization.format("Tag.VIPName", { player.DisplayName })
	label.Parent = tag
	tag.Parent = head
end

local function watch(player: Player)
	if player == localPlayer then
		return
	end
	player.CharacterAdded:Connect(function(character: Model)
		if character:WaitForChild("Head", CHARACTER_WAIT) and character:WaitForChild("Humanoid", CHARACTER_WAIT) then
			applyNameTag(player)
		end
	end)
	player:GetAttributeChangedSignal("VIP"):Connect(function()
		applyNameTag(player)
	end)
	task.spawn(applyNameTag, player)
end

local function onIncomingMessage(message: TextChatMessage): TextChatMessageProperties?
	local source = message.TextSource
	local sender = if source then Players:GetPlayerByUserId(source.UserId) else nil
	if sender == nil or not isVIP(sender) then
		return nil
	end
	local properties = Instance.new("TextChatMessageProperties")
	local tag = Localization.format("Tag.VIPChat")
	properties.PrefixText = `<font color="{Config.Monetization.VIPColor}">{tag}</font> {message.PrefixText}`
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
