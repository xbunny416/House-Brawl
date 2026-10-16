--!strict
--[[
	PropController — the local player's side of props. The Grab action asks the server to grab the nearest prop in
	reach (or drop the held one); while a prop is held (character attribute HeldProp, set by the server) the touch
	buttons read Throw (Attack) and Drop (Grab). The server decides everything else.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local InputController = require(script.Parent:WaitForChild("InputController"))

local PropController = {}

local player = Players.LocalPlayer

local function showHolding(holding: boolean)
	InputController.setLabel("Attack", if holding then "Controls.Throw" else nil)
	InputController.setLabel("Grab", if holding then "Controls.Drop" else nil)
end

local function watchCharacter(character: Model)
	showHolding(character:GetAttribute("HeldProp") ~= nil)
	character:GetAttributeChangedSignal("HeldProp"):Connect(function()
		showHolding(character:GetAttribute("HeldProp") ~= nil)
	end)
end

-- Whether the local character holds a prop.
function PropController.isHolding(): boolean
	local character = player.Character
	return character ~= nil and character:GetAttribute("HeldProp") ~= nil
end

function PropController.Init(_self: any)
	InputController.ActionBegan:Connect(function(action: string)
		if action == "Grab" then
			Net.fire("Grab")
		end
	end)
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end
end

return PropController
