--!strict
--[[
	KeyHint — a small "which button" hint for an action, shown next to a HUD item: the key name on keyboard / mouse,
	the button glyph on gamepad, nothing on touch (the touch buttons carry their own labels). Follows device changes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))

local InputController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("InputController"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local KeyHint = {}

local function keyCode(name: string): Enum.KeyCode?
	local ok, code = pcall(function()
		return (Enum.KeyCode :: any)[name]
	end)
	return if ok then code else nil
end

-- Keyboard / mouse text for an action's first binding ("Q", "Click", ...).
function KeyHint.text(action: string): string
	local binding = (Config.Controls.Keyboard[action] or {})[1]
	if binding == nil then
		return ""
	elseif binding == "MouseButton1" then
		return Localization.format("Hint.LeftClick")
	elseif binding == "MouseButton2" then
		return Localization.format("Hint.RightClick")
	end
	local code = keyCode(binding)
	local text = if code then UserInputService:GetStringForKeyCode(code) else ""
	return if text ~= "" then text else binding
end

-- A hint box for `action` (a square box with the key text or gamepad glyph).
function KeyHint.new(parent: Instance, action: string, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = `{action}Hint`
	frame.Size = size
	frame.BackgroundColor3 = Kit.Colors.Button
	frame.BackgroundTransparency = 0.2
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = frame

	local label = Kit.label(frame, "", UDim2.fromScale(1, 1), 18)
	label.Font = Kit.TitleFont
	local glyph = Instance.new("ImageLabel")
	glyph.BackgroundTransparency = 1
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.ScaleType = Enum.ScaleType.Fit
	glyph.Parent = frame

	local function update(device: string)
		frame.Visible = device ~= "Touch"
		local isPad = device == "Gamepad"
		label.Visible = not isPad
		glyph.Visible = isPad
		if isPad then
			local code = keyCode((Config.Controls.Gamepad[action] or {})[1] or "")
			glyph.Image = if code then UserInputService:GetImageForKeyCode(code) else ""
		else
			label.Text = KeyHint.text(action)
		end
	end
	update(InputController.getDevice())
	InputController.DeviceChanged:Connect(update)
	frame.Parent = parent
	return frame
end

return KeyHint
