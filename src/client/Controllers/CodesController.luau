--!strict
--[[
	CodesController — the Codes screen (bible §5.3 / §8): type a code, press Redeem (or Enter), and the server checks
	it (RedeemCode; the codes themselves never reach the client) and says what it gave or why not. Opens from the
	left-edge menu and the lobby's codes jukebox (LobbyPromptController).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local MenuController = require(script.Parent:WaitForChild("MenuController"))

local MENU_ORDER = 8 -- after Party
local MAX_LENGTH = 24 -- the RedeemCode remote's limit

local CodesController = {}

local gui: ScreenGui
local box: TextBox
local redeemButton: TextButton
local message: TextLabel
local busy = false

local function describe(reward: { [string]: any }): string
	local parts: { string } = {}
	if type(reward.Scrap) == "number" and reward.Scrap > 0 then
		table.insert(parts, Localization.format("Currency.Scrap", { reward.Scrap }))
	end
	if type(reward.Cosmetic) == "string" then
		table.insert(parts, Localization.format(`Cosmetic.{reward.Cosmetic}.Name`))
	end
	return table.concat(parts, " + ")
end

local function redeem()
	local text = box.Text
	if busy or text == "" then
		return
	end
	busy = true
	redeemButton.Text = Localization.format("Codes.Redeeming")
	task.spawn(function()
		local ok, redeemed, result = pcall(Net.invoke, "RedeemCode", string.sub(text, 1, MAX_LENGTH))
		busy = false
		redeemButton.Text = Localization.format("Codes.Redeem")
		if ok and redeemed == true and type(result) == "table" then
			message.Text = Localization.format("Codes.Redeemed", { describe(result) })
			message.TextColor3 = Kit.Colors.Accent
			box.Text = ""
		else
			-- A refusal names a Server/Codes/CodeRules reason; no answer (or an unknown one) is TryAgain.
			local known = ok and typeof(result) == "string" and Localization.has(`Codes.Error.{result}`)
			local why = if known then result else "TryAgain"
			message.Text = Localization.format(`Codes.Error.{why}`)
			message.TextColor3 = Kit.Colors.Muted
		end
	end)
end

local function onOpen()
	message.Text = Localization.format("Codes.Info")
	message.TextColor3 = Kit.Colors.Muted
	box:CaptureFocus()
end

local function build()
	gui = Kit.screen("Codes", 8)
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.42, 0.36),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5),
		Vector2.new(520, 300)
	)
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.22)
	header.Parent = panel
	local title = Kit.label(header, Localization.format("Codes.Title"), UDim2.fromScale(0.7, 1), 30)
	title.Font = Kit.TitleFont
	title.TextXAlignment = Enum.TextXAlignment.Left
	local closeButton = Kit.button(header, Localization.format("Common.Close"), UDim2.fromScale(0.26, 0.8))
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Activated:Connect(MenuController.close)

	box = Instance.new("TextBox")
	box.Name = "Code"
	box.BackgroundColor3 = Kit.Colors.Button
	box.TextColor3 = Kit.Colors.Text
	box.PlaceholderText = Localization.format("Codes.Placeholder")
	box.PlaceholderColor3 = Kit.Colors.Muted
	box.Font = Kit.BodyFont
	box.TextScaled = true
	box.ClearTextOnFocus = false
	box.Text = ""
	box.Position = UDim2.fromScale(0, 0.3)
	box.Size = UDim2.fromScale(0.64, 0.24)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = box
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.18, 0)
	padding.PaddingBottom = UDim.new(0.18, 0)
	padding.Parent = box
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 28
	limit.Parent = box
	box.Parent = panel
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text > MAX_LENGTH then
			box.Text = string.sub(box.Text, 1, MAX_LENGTH)
		end
	end)
	box.FocusLost:Connect(function(enterPressed: boolean)
		if enterPressed then
			redeem()
		end
	end)

	redeemButton = Kit.button(panel, Localization.format("Codes.Redeem"), UDim2.fromScale(0.33, 0.24))
	redeemButton.AnchorPoint = Vector2.new(1, 0)
	redeemButton.Position = UDim2.fromScale(1, 0.3)
	Kit.setChosen(redeemButton, true)
	redeemButton.Activated:Connect(redeem)

	message = Kit.label(panel, "", UDim2.fromScale(1, 0.3), 20)
	message.Position = UDim2.fromScale(0, 0.62)
	message.TextWrapped = true
end

function CodesController.Start(_self: any)
	build()
	MenuController.addScreen(Localization.format("Menu.Codes"), MENU_ORDER, gui, onOpen)
end

return CodesController
