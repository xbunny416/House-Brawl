--!strict
--[[
	Kit — the shared look of every screen: colors, fonts and small builders for screens, panels, labels and buttons.
	Sizes are Scale (fractions of the parent) with pixel limits where text must stay readable. Callers pass text that
	is already localized (Localization.format).
]]
local Players = game:GetService("Players")

local Kit = {}

Kit.Colors = {
	Panel = Color3.fromHex("#1E1A17"),
	Text = Color3.fromHex("#F2E6D0"),
	Muted = Color3.fromHex("#A89A85"),
	Accent = Color3.fromHex("#D9822B"),
	Button = Color3.fromHex("#3A302A"),
	Coin = Color3.fromHex("#F2C14E"),
	Live = Color3.fromHex("#E5484D"), -- the "game in progress" dot
	Hint = Color3.fromHex("#D0D0D0"), -- the small key hints along the bottom edge
	-- Leaderboard boards (reference: docs/reference/leaderboard-boards.png).
	Gold = Color3.fromHex("#E8C04A"),
	Silver = Color3.fromHex("#C9CED6"),
	Bronze = Color3.fromHex("#D08A4E"),
	Cream = Color3.fromHex("#F0E2C0"),
	BoardRow = Color3.fromHex("#26262B"),
	Rival = Color3.fromHex("#3FA7B5"), -- the other side at the arm-wrestling table (your side is Accent)
}
Kit.TitleFont = Enum.Font.GothamBlack
Kit.BodyFont = Enum.Font.GothamBold

local PANEL_TRANSPARENCY = 0.12
local MAX_TEXT_SIZE = 28

-- A hidden ScreenGui in the local player's PlayerGui (kept across respawns).
function Kit.screen(name: string, displayOrder: number): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = displayOrder
	gui.Enabled = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

local function corner(parent: Instance, radius: UDim)
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = radius
	uiCorner.Parent = parent
end

-- A rounded, outlined panel. `maxSize` caps it in pixels on big screens.
function Kit.panel(parent: Instance, size: UDim2, position: UDim2, anchor: Vector2, maxSize: Vector2?): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.AnchorPoint = anchor
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Kit.Colors.Panel
	frame.BackgroundTransparency = PANEL_TRANSPARENCY
	corner(frame, UDim.new(0, 12))
	local outline = Instance.new("UIStroke")
	outline.Color = Kit.Colors.Accent
	outline.Thickness = 2
	outline.Parent = frame
	local padding = Instance.new("UIPadding")
	for _, side in { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" } do
		(padding :: any)[side] = UDim.new(0.04, 0)
	end
	padding.Parent = frame
	if maxSize then
		local limit = Instance.new("UISizeConstraint")
		limit.MaxSize = maxSize
		limit.Parent = frame
	end
	frame.Parent = parent
	return frame
end

-- Text that scales with its box (up to `maxTextSize` pixels).
function Kit.label(parent: Instance, text: string, size: UDim2, maxTextSize: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Font = Kit.BodyFont
	label.Text = text
	label.TextColor3 = Kit.Colors.Text
	label.TextScaled = true
	label.TextWrapped = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxTextSize or MAX_TEXT_SIZE
	limit.Parent = label
	label.Parent = parent
	return label
end

-- A rounded button (works with mouse, touch and gamepad selection).
function Kit.button(parent: Instance, text: string, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = Kit.Colors.Button
	button.Font = Kit.TitleFont
	button.Text = text
	button.TextColor3 = Kit.Colors.Text
	button.TextScaled = true
	button.TextWrapped = true
	corner(button, UDim.new(0, 8))
	local outline = Instance.new("UIStroke")
	outline.Name = "Outline"
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Color = Kit.Colors.Accent
	outline.Thickness = 0
	outline.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.06, 0)
	padding.PaddingRight = UDim.new(0.06, 0)
	padding.PaddingTop = UDim.new(0.08, 0)
	padding.PaddingBottom = UDim.new(0.08, 0)
	padding.Parent = button
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = MAX_TEXT_SIZE
	limit.Parent = button
	button.Parent = parent
	return button
end

-- Marks a button as the player's current choice.
function Kit.setChosen(button: TextButton, chosen: boolean)
	local outline = button:FindFirstChild("Outline")
	if outline and outline:IsA("UIStroke") then
		outline.Thickness = if chosen then 3 else 0
	end
	button.BackgroundColor3 = if chosen then Kit.Colors.Accent else Kit.Colors.Button
end

-- Lays children out in a row or column, centered, in LayoutOrder.
function Kit.list(parent: Instance, direction: Enum.FillDirection, padding: UDim): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.Padding = padding
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = parent
	return layout
end

-- A row of tab buttons (already-localized texts) in a new frame at `position` / `size` inside `parent`, left to
-- right; each button is `width` of the row wide. Returns the buttons in order (mark the open one with setChosen).
function Kit.tabRow(parent: Instance, texts: { string }, position: UDim2, size: UDim2, width: number): { TextButton }
	local row = Instance.new("Frame")
	row.Name = "Tabs"
	row.BackgroundTransparency = 1
	row.Position = position
	row.Size = size
	row.Parent = parent
	local layout = Kit.list(row, Enum.FillDirection.Horizontal, UDim.new(0.02, 0))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	local buttons: { TextButton } = {}
	for index, text in texts do
		local button = Kit.button(row, text, UDim2.fromScale(width, 1))
		button.LayoutOrder = index
		table.insert(buttons, button)
	end
	return buttons
end

return Kit
