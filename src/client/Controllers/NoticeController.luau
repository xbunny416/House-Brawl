--!strict
--[[
	NoticeController — short notices from the server (Notify remote: key, args?), e.g. the thank-you after a Robux
	purchase. Each shows under the top bar for NOTICE_LIFETIME seconds, newest at the bottom, NOTICE_MAX at a time. An
	argument that is a table { Key = "..." } is itself a GameStrings key, localized here (e.g. an item's name).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))

local NOTICE_LIFETIME = 5 -- seconds
local NOTICE_MAX = 3
local FADE = TweenInfo.new(0.4)

local NoticeController = {}

local list: Frame
local shown: { Frame } = {}
local count = 0

-- The arguments with every { Key = ... } table replaced by its localized text.
local function localizeArgs(args: unknown): { any }?
	if type(args) ~= "table" then
		return nil
	end
	local result: { any } = {}
	for index, value in args :: { any } do
		if type(value) == "table" and type(value.Key) == "string" then
			result[index] = Localization.format(value.Key)
		elseif type(value) == "string" or type(value) == "number" then
			result[index] = value
		end
	end
	return result
end

local function remove(notice: Frame)
	local index = table.find(shown, notice)
	if index then
		table.remove(shown, index)
	end
	notice:Destroy()
end

local function show(key: unknown, args: unknown)
	if type(key) ~= "string" or not Localization.has(key) then
		return
	end
	count += 1
	local notice = Instance.new("Frame")
	notice.Name = "Notice"
	notice.BackgroundColor3 = Kit.Colors.Panel
	notice.BackgroundTransparency = 0.15
	notice.Size = UDim2.fromScale(1, 0.3)
	notice.LayoutOrder = count
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = notice
	local outline = Instance.new("UIStroke")
	outline.Color = Kit.Colors.Accent
	outline.Thickness = 2
	outline.Parent = notice
	local label = Kit.label(notice, Localization.format(key, localizeArgs(args)), UDim2.fromScale(0.94, 0.8), 22)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	notice.Parent = list
	table.insert(shown, notice)
	while #shown > NOTICE_MAX do
		remove(shown[1])
	end
	task.delay(NOTICE_LIFETIME, function()
		if notice.Parent == nil then
			return
		end
		TweenService:Create(notice, FADE, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, FADE, { TextTransparency = 1 }):Play()
		TweenService:Create(outline, FADE, { Transparency = 1 }):Play()
		task.wait(FADE.Time)
		remove(notice)
	end)
end

function NoticeController.Start(_self: any)
	local gui = Kit.screen("Notices", 9)
	gui.Enabled = true
	list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.AnchorPoint = Vector2.new(0.5, 0)
	list.Position = UDim2.fromScale(0.5, 0.16)
	list.Size = UDim2.fromScale(0.42, 0.2)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(560, 160)
	limit.Parent = list
	local layout = Kit.list(list, Enum.FillDirection.Vertical, UDim.new(0.04, 0))
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	list.Parent = gui
	Net.on("Notify", show)
end

return NoticeController
