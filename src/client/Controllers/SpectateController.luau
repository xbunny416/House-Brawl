--!strict
--[[
	SpectateController — while the local player is spectating a round (Classic: out of lives, joined late, or left out
	for being AFK) the camera follows a fighter still in it. SpectatePrevious / SpectateNext (Z / X, D-pad) or the
	arrows on the bottom bar switch fighters; when the watched fighter is knocked out the next one is picked.
	Players in the lobby can watch the running round too (owner's fix list, 2026-10-19: "game in progress" and
	spectate mode): `watch(true)` from the Game in progress panel (GameInProgressController); their character stays in
	the lobby, only the camera goes, and it ends with the round or `watch(false)`.
	The server streams the watched fighter's surroundings to this client (Spectate remote).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Util"):WaitForChild("Signal"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local REFRESH_INTERVAL = 0.25

local SpectateController = {
	-- Fires with true / false when the local player starts / stops watching from the lobby.
	WatchingChanged = Signal.new() :: Signal.Signal<boolean>,
}

local player = Players.LocalPlayer
local gui: ScreenGui
local nameLabel: TextLabel
local active = false
local watching = false -- watching the round from the lobby
local target: Player? = nil

-- Fighters still in the round, in a stable order.
local function candidates(): { Player }
	local list: { Player } = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("RoundStatus") == "Playing" then
			table.insert(list, other)
		end
	end
	table.sort(list, function(a: Player, b: Player): boolean
		return a.UserId < b.UserId
	end)
	return list
end

local function setTarget(newTarget: Player?)
	if newTarget ~= target then
		target = newTarget
		Net.fire("Spectate", if newTarget then newTarget.UserId else 0)
	end
	nameLabel.Text = if newTarget
		then Localization.format("Spectate.Watching", { newTarget.DisplayName })
		else Localization.format("Spectate.Nobody")
end

local function cycle(step: number)
	local list = candidates()
	if #list == 0 then
		setTarget(nil)
		return
	end
	local index = (target and table.find(list, target)) or 0
	setTarget(list[(index - 1 + step) % #list + 1])
end

local function ownHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function stop()
	active = false
	gui.Enabled = false
	setTarget(nil)
	local camera = Workspace.CurrentCamera
	local humanoid = ownHumanoid()
	if camera and humanoid then
		camera.CameraSubject = humanoid
	end
end

local function setWatching(on: boolean)
	if watching ~= on then
		watching = on
		SpectateController.WatchingChanged:Fire(on)
	end
end

local function refresh()
	local status = player:GetAttribute("RoundStatus")
	local playing = Workspace:GetAttribute("RoundState") == "Playing"
	if watching and (status ~= "Lobby" or not playing) then
		setWatching(false) -- the round ended, or the player went into it
	end
	local spectating = playing and (status == "Spectating" or watching)
	if not spectating then
		if active then
			stop()
		end
		return
	end
	if not active then
		active = true
		gui.Enabled = true
	end
	local current = target
	if current == nil or current.Parent ~= Players or current:GetAttribute("RoundStatus") ~= "Playing" then
		target = nil
		cycle(1)
		current = target
	end
	-- The watched fighter's character arrives once the server has streamed it in.
	local character = current and current.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local camera = Workspace.CurrentCamera
	if camera and humanoid and camera.CameraSubject ~= humanoid then
		camera.CameraSubject = humanoid
	end
end

local function build()
	gui = Kit.screen("Spectate", 4)
	local bar = Kit.panel(
		gui,
		UDim2.fromScale(0.44, 0.1),
		UDim2.new(0.5, 0, 0.97, -14), -- above the key hints (HintBarController)
		Vector2.new(0.5, 1),
		Vector2.new(520, 72)
	)
	Kit.list(bar, Enum.FillDirection.Horizontal, UDim.new(0.02, 0))
	local previous = Kit.button(bar, Localization.format("Controls.SpectatePrevious"), UDim2.fromScale(0.14, 1))
	previous.LayoutOrder = 1
	previous.Activated:Connect(function()
		cycle(-1)
	end)
	nameLabel = Kit.label(bar, "", UDim2.fromScale(0.66, 1))
	nameLabel.LayoutOrder = 2
	local nextButton = Kit.button(bar, Localization.format("Controls.SpectateNext"), UDim2.fromScale(0.14, 1))
	nextButton.LayoutOrder = 3
	nextButton.Activated:Connect(function()
		cycle(1)
	end)
end

function SpectateController.isSpectating(): boolean
	return active
end

-- True while the local player watches the round from the lobby.
function SpectateController.isWatching(): boolean
	return watching
end

-- Starts / stops watching the running round from the lobby (only while the round runs and the player is in the
-- lobby; the server checks the same before streaming the arena).
function SpectateController.watch(on: boolean)
	local canWatch = player:GetAttribute("RoundStatus") == "Lobby" and Workspace:GetAttribute("RoundState") == "Playing"
	setWatching(on and canWatch)
	refresh()
end

function SpectateController.Start(_self: any)
	build()
	InputController.ActionBegan:Connect(function(action: string)
		if not active then
			return
		end
		if action == "SpectatePrevious" then
			cycle(-1)
		elseif action == "SpectateNext" then
			cycle(1)
		end
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed >= REFRESH_INTERVAL then
			elapsed = 0
			refresh()
		end
	end)
end

return SpectateController
