--!strict
--[[
	DevService — the server side of the minimal developer panel (step 1.13; the full panel is step 3.9).
	Commands arrive on the DevCommand remote and run only for allowed players (Server/Dev/DevRules: anyone in Studio
	playtests, Config.Dev.AllowedUserIds in live servers). Allowed players get the DevAccess attribute, which makes
	their client show the panel. Every command is printed to Output.

	  StartRound / EndRound          start the vote now (one player on the join pad is enough) or close it; end the
	                                 running round now
	  ForceMap / ForceMode (id?)     the next round uses this map / mode whatever the vote says (no id = the vote)
	  Crumble                        crumble the next platform now
	  SpawnProp (typeId)             a prop in front of you
	  SpawnDummy                     the practice dummy in front of you (replaces the last one)
	  SetPercent / SetHealth (n)     your own Percent / HP
	  SetStyle (styleId)             own and equip a fighting style
	  UnlockCosmetics                own every cosmetic (equip them in the Locker)
	  GiveScrap                      Config.Dev.GiveScrap Scrap (to test the Shop)
	  TogglePerk (perk)              switch VIP / EmotePack / Premium on or off for this session
	  GiveProduct (key)              what a Robux product gives, without a purchase
	  TogglePrivate                  act as a private server you own (Server menu, 50% rewards), or stop
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local DevRules = require(Server:WaitForChild("Dev"):WaitForChild("DevRules"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local CosmeticService = require(script.Parent:WaitForChild("CosmeticService"))
local CrumbleService = require(script.Parent:WaitForChild("CrumbleService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local DummyService = require(script.Parent:WaitForChild("DummyService"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))
local PropService = require(script.Parent:WaitForChild("PropService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))
local StyleService = require(script.Parent:WaitForChild("StyleService"))

local SPAWN_DISTANCE = 6 -- studs in front of the player

type Command = (player: Player, text: string?, value: number?) -> ()

local DevService = {}

local function isAllowed(player: Player): boolean
	return DevRules.isAllowed(player.UserId, RunService:IsStudio())
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local commands: { [string]: Command } = {
	StartRound = function()
		RoundService.startNow()
	end,
	EndRound = function()
		RoundService.endNow()
	end,
	ForceMap = function(_player, text)
		RoundService.forceNext("Map", text)
	end,
	ForceMode = function(_player, text)
		RoundService.forceNext("Mode", text)
	end,
	Crumble = function()
		CrumbleService.crumbleNext()
	end,
	SpawnProp = function(player, text)
		local root = rootOf(player)
		if root == nil or text == nil or Config.Props.Types[text] == nil then
			return
		end
		local zone: MapService.FallZone = MapService.getZone(root.Position)
		-- On the floor under a point in front of the player (the root is about 3 studs above the floor).
		local floor = root.CFrame * CFrame.new(0, -3, -SPAWN_DISTANCE)
		PropService.spawnLoose(text, floor, zone, Config.Structures.DropDespawnTime)
	end,
	SpawnDummy = function(player)
		local root = rootOf(player)
		if root then
			-- Facing you, at your height, in front of you.
			local front = (root.CFrame * CFrame.new(0, 0, -SPAWN_DISTANCE)).Position
			DummyService.spawnAt(CFrame.lookAt(front, Vector3.new(root.Position.X, front.Y, root.Position.Z)))
		end
	end,
	SetPercent = function(player, _text, value)
		local character = player.Character
		if character and value then
			CombatService.setPercent(character, value)
		end
	end,
	SetHealth = function(player, _text, value)
		local character = player.Character
		if character and value then
			CombatService.setHealth(character, value)
		end
	end,
	SetStyle = function(player, text)
		if text then
			StyleService.equip(player, text, true)
		end
	end,
	UnlockCosmetics = function(player)
		CosmeticService.grantAll(player)
	end,
	GiveScrap = function(player)
		DataService.addScrap(player, Config.Dev.GiveScrap, Analytics.Transaction.Gameplay, "DevPanel")
	end,
	TogglePerk = function(player, text)
		if text then
			MonetizationService.togglePerk(player, text)
		end
	end,
	GiveProduct = function(player, text)
		if text then
			MonetizationService.giveProduct(player, text)
		end
	end,
	TogglePrivate = function(player)
		PrivateServerService.toggleSimulated(player)
	end,
}

local function onCommand(player: Player, name: string, text: string?, value: number?)
	if not isAllowed(player) then
		return
	end
	local command = commands[name]
	if command then
		print(`[Dev] {player.Name}: {name} {text or ""} {if value then tostring(value) else ""}`)
		command(player, text, value)
	end
end

function DevService.Init(_self: any)
	Net.onServerEvent("DevCommand", onCommand)
	local function grant(player: Player)
		if isAllowed(player) then
			player:SetAttribute("DevAccess", true)
		end
	end
	Players.PlayerAdded:Connect(grant)
	for _, player in Players:GetPlayers() do
		grant(player)
	end
end

return DevService
