--!strict
--[[
	BartenderController — the lobby bartender's phrases (owner's fix list: "bartender phrases"; no animation, the owner
	2026-10-20). When to talk and which line is the pure Lib/BartenderRules over Config.World.Bartender.Talk; this
	shows each line in a speech bubble over the bartender's head (NpcService's character, or the ShopNPC model's Torso
	anchor if it isn't there): it pops in, types itself out and shrinks away after its read time. Only the local player
	sees their bartender's lines, so nothing goes through the server.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local BartenderRules = require(script.Parent.Parent:WaitForChild("Lib"):WaitForChild("BartenderRules"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))
local ShopController = require(script.Parent:WaitForChild("ShopController"))

local NPC_TAG = "ShopNPC"
local CHECK_INTERVAL = 0.25
local HEAD_OFFSET = 1.6 -- studs above the head (or the Torso anchor's top) to the bubble's tail
local BUBBLE_WIDTH = 250 -- pixels at most, before the line wraps
local TAIL_SIZE = 14 -- pixels
local POP_IN = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TYPE_SPEED = 45 -- characters a second while the line types itself out

local talk: BartenderRules.Talk = Config.World.Bartender.Talk
local player = Players.LocalPlayer
local state = BartenderRules.new()
local random = Random.new()

local BartenderController = {}

local billboard: BillboardGui
local label: TextLabel
local scale: UIScale
local shown = 0 -- counts lines, so an older line's hide doesn't close a newer one

-- The part the bubble sits over: the bartender's head, else the ShopNPC model's Torso anchor.
local function anchor(): BasePart?
	local model = CollectionService:GetTagged(NPC_TAG)[1]
	if model == nil then
		return nil
	end
	local character = model:FindFirstChild("Bartender")
	local head = character and character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	local torso = model:FindFirstChild("Torso")
	return if torso and torso:IsA("BasePart") then torso else nil
end

local function build()
	billboard = Instance.new("BillboardGui")
	billboard.Name = "BartenderBubble"
	billboard.Size = UDim2.fromOffset(BUBBLE_WIDTH + 40, 160)
	billboard.LightInfluence = 0
	billboard.MaxDistance = talk.Distance * 2
	billboard.ResetOnSpawn = false
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Enabled = false

	-- Everything pops in and out together, growing from the bottom middle (where the tail points down).
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.fromScale(0.5, 1)
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.Parent = billboard
	scale = Instance.new("UIScale")
	scale.Parent = holder

	-- Bottom-centred, so the bubble grows upwards from its tail.
	local bubble = Instance.new("Frame")
	bubble.Name = "Bubble"
	bubble.AnchorPoint = Vector2.new(0.5, 1)
	bubble.Position = UDim2.new(0.5, 0, 1, -TAIL_SIZE)
	bubble.AutomaticSize = Enum.AutomaticSize.XY
	bubble.Size = UDim2.fromOffset(0, 0)
	bubble.BackgroundColor3 = Kit.Colors.Cream
	bubble.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = bubble

	-- The tail: a small turned square centred on the bubble's bottom edge (its lower half points at the bartender).
	local tail = Instance.new("Frame")
	tail.Name = "Tail"
	tail.AnchorPoint = Vector2.new(0.5, 0.5)
	tail.Position = UDim2.new(0.5, 0, 1, -TAIL_SIZE)
	tail.Size = UDim2.fromOffset(TAIL_SIZE, TAIL_SIZE)
	tail.Rotation = 45
	tail.BackgroundColor3 = Kit.Colors.Cream
	tail.BorderSizePixel = 0
	tail.Parent = holder

	label = Instance.new("TextLabel")
	label.Name = "Line"
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 0)
	label.TextWrapped = true
	label.Font = Kit.BodyFont
	label.TextSize = 18
	label.TextColor3 = Kit.Colors.Panel
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = bubble
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = label
	local width = Instance.new("UISizeConstraint")
	width.MaxSize = Vector2.new(BUBBLE_WIDTH, math.huge)
	width.Parent = label

	billboard.Parent = player:WaitForChild("PlayerGui")
end

-- Shows one line from `pool` over the bartender.
local function say(pool: string)
	local count = talk.Lines[pool]
	local part = anchor()
	if count == nil or count < 1 or part == nil then
		return
	end
	local index = BartenderRules.pick(state, pool, count, random:NextNumber())
	local text = Localization.format(`Bartender.{pool}.{index}`)
	local length = utf8.len(text) or #text
	local readTime = BartenderRules.readTime(talk, length)
	BartenderRules.said(state, talk, os.clock(), readTime, random:NextNumber())

	shown += 1
	local line = shown
	billboard.Adornee = part
	billboard.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + HEAD_OFFSET, 0)
	label.Text = text
	label.MaxVisibleGraphemes = 0
	scale.Scale = 0.6
	billboard.Enabled = true
	TweenService:Create(scale, POP_IN, { Scale = 1 }):Play()
	TweenService:Create(label, TweenInfo.new(length / TYPE_SPEED), { MaxVisibleGraphemes = length }):Play()
	task.delay(readTime, function()
		if shown ~= line then
			return
		end
		local out = TweenService:Create(scale, POP_OUT, { Scale = 0 })
		out.Completed:Once(function()
			if shown == line then
				billboard.Enabled = false
				label.MaxVisibleGraphemes = -1
			end
		end)
		out:Play()
	end)
end

-- True while the local player is in the lobby within Distance of the bartender.
local function isNear(): boolean
	if MenuController.isFighting() then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local part = anchor()
	if root == nil or not root:IsA("BasePart") or part == nil then
		return false
	end
	return (root.Position - part.Position).Magnitude <= talk.Distance
end

function BartenderController.Start(_self: any)
	build()
	Net.on("RoundResults", function(rows: { any })
		for _, row in rows do
			if row.UserId == player.UserId and type(row.Placement) == "number" then
				BartenderRules.roundEnded(state, row.Placement)
				return
			end
		end
	end)
	ShopController.Bought:Connect(function()
		local pool = BartenderRules.react("Bought", isNear())
		if pool then
			say(pool)
		end
	end)

	local shopWasOpen = false
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed = 0
		local near = isNear()
		local shopOpen = MenuController.openName() == "Shop"
		local opened = shopOpen and not shopWasOpen
		shopWasOpen = shopOpen
		local pool = BartenderRules.tick(state, talk, near, os.clock())
		if opened then
			pool = BartenderRules.react("ShopOpened", near) or pool
		end
		if pool then
			say(pool)
		end
	end)
end

return BartenderController
