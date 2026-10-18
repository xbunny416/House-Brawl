--!strict
--[[
	CodeService — redeem codes (bible §8; Server/Codes/CodeRules, codes in the server-only ServerConfig). The
	RedeemCode remote checks the typed code for the player, saves it as used (Codes data) and gives its reward: Scrap
	(Gameplay transaction, sku "Code.<CODE>") and / or a cosmetic. Returns true and the reward, or false and a
	CodeRules reason. Nothing is given in private servers (play and testing only); the code stays unused for later.
	Developer panel: forget the player's used codes, to test again.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local CodeRules = require(script.Parent.Parent:WaitForChild("Codes"):WaitForChild("CodeRules"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local CosmeticService = require(script.Parent:WaitForChild("CosmeticService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))

local CodeService = {}

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Codes] {message}`)
	end
end

-- Redeems `text` for the player. Returns true and the reward ({ Scrap, Cosmetic? }), or false and a reason.
function CodeService.redeem(player: Player, text: string): (boolean, any)
	local data = DataService.get(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local key, code, reason = CodeRules.check(text, data.Codes, os.time())
	if key == nil or code == nil then
		return false, reason
	end
	if not PrivateServerService.paysRewards() then
		return false, "PrivateServer"
	end
	DataService.update(player, "Codes", function(changed)
		changed.Codes[key] = true
	end)
	local scrap = code.Scrap or 0
	if scrap > 0 then
		DataService.addScrap(player, scrap, Analytics.Transaction.Gameplay, `Code.{key}`)
	end
	local cosmetic = code.Cosmetic
	if cosmetic and Config.Cosmetics.Items[cosmetic] then
		CosmeticService.grant(player, cosmetic)
	end
	Analytics.custom(player, "CodeRedeemed", scrap, { key })
	log(`{player.Name} redeemed {key}`)
	return true, { Scrap = scrap, Cosmetic = cosmetic }
end

-- Developer panel: forgets the player's used codes.
function CodeService.devReset(player: Player)
	DataService.update(player, "Codes", function(changed)
		changed.Codes = {}
	end)
end

function CodeService.Init(_self: any)
	Net.onServerInvoke("RedeemCode", function(player: Player, text: string)
		return CodeService.redeem(player, text)
	end)
end

return CodeService
