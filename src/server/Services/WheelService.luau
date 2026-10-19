--!strict
--[[
	WheelService — the lobby spin wheel (owner's fix list, 2026-10-19; Shared/WheelRules, Config.Retention.Wheel).
	SpinWheel (kind "Free" / "Paid"): the day's free spin, or a paid one for Wheel.SpinPrice Scrap (DataService
	.spendScrap, Shop sink, sku "WheelSpin") where PolicyService allows paid random items. Never in private servers
	(nothing is earned there) or while fighting. The server rolls (Random) and pays the prize:
	  Coins → DataService.addScrap (Gameplay, sku "Wheel.<prize id>"), XP → DataService.addXP, StyleSpin → one bonus
	  free style spin (Styles.BonusSpins), Cosmetic → a random cosmetic sold for Scrap the player doesn't own
	  (CosmeticService.grant), or CosmeticFallbackScrap when they own them all.
	Then every client hears WheelSpun (prize index, who spun) and turns the lobby wheel to it.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local WheelRules = require(Shared:WaitForChild("WheelRules"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local CosmeticService = require(script.Parent:WaitForChild("CosmeticService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerPolicyService = require(script.Parent:WaitForChild("PlayerPolicyService"))
local PrivateServerService = require(script.Parent:WaitForChild("PrivateServerService"))
local RoundService = require(script.Parent:WaitForChild("RoundService"))

export type SpinResult = { Index: number, Kind: string, Amount: number, Cosmetic: string? }

local WheelService = {}

local random = Random.new()

local function log(message: string)
	if RunService:IsStudio() then
		print(`[Wheel] {message}`)
	end
end

-- Pays the prize at `index`. Returns what was actually given (a Cosmetic prize may turn into Scrap).
local function pay(player: Player, index: number): SpinResult
	local prize = Config.Retention.Wheel.Prizes[index]
	local sku = `Wheel.{prize.Id}`
	if prize.Kind == "Coins" then
		DataService.addScrap(player, prize.Amount, Analytics.Transaction.Gameplay, sku)
	elseif prize.Kind == "XP" then
		DataService.addXP(player, prize.Amount)
	elseif prize.Kind == "StyleSpin" then
		DataService.update(player, "Styles", function(changed)
			changed.Styles.BonusSpins = (changed.Styles.BonusSpins or 0) + prize.Amount
		end)
	elseif prize.Kind == "Cosmetic" then
		local data = DataService.get(player)
		local itemId = data and WheelRules.cosmeticFor(data.Cosmetics.Owned, random:NextNumber())
		if itemId then
			CosmeticService.grant(player, itemId)
			return { Index = index, Kind = "Cosmetic", Amount = 1, Cosmetic = itemId }
		end
		local fallback = Config.Retention.Wheel.CosmeticFallbackScrap
		DataService.addScrap(player, fallback, Analytics.Transaction.Gameplay, sku)
		return { Index = index, Kind = "Coins", Amount = fallback }
	end
	return { Index = index, Kind = prize.Kind, Amount = prize.Amount }
end

--[[
	Spins the wheel for `player` (kind "Free" or "Paid"). Returns true and what they won, or false and a reason from
	WheelRules.Reasons.
]]
function WheelService.spin(player: Player, kind: string): (boolean, SpinResult | string)
	local data = DataService.get(player)
	if data == nil then
		return false, "NotLoaded"
	end
	local status = RoundService.getStatus(player)
	local day = WheelRules.dayAt(os.time())
	local reason = WheelRules.checkSpin(data.Wheel, kind, day, data.Scrap, {
		Allowed = PrivateServerService.paysRewards(),
		Fighting = status == "Playing" or status == "Respawning",
		PaidAllowed = PlayerPolicyService.allows(player, "PaidRandomItems"),
	})
	if reason then
		log(`{player.Name} could not spin ({kind}): {reason}`)
		return false, reason
	end
	local price = if kind == "Paid" then Config.Retention.Wheel.SpinPrice else 0
	if kind == "Paid" then
		if not DataService.spendScrap(player, price, Analytics.Transaction.Shop, "WheelSpin") then
			return false, "NotEnoughScrap"
		end
	else
		DataService.update(player, "Wheel", function(changed)
			changed.Wheel.FreeDay = day
		end)
	end
	local index = WheelRules.pick(random:NextNumber())
	local result = pay(player, index)
	Net.fireAll("WheelSpun", index, player.DisplayName)
	local prize = Config.Retention.Wheel.Prizes[index]
	Analytics.custom(player, "WheelSpin", price, { kind, prize.Id, result.Cosmetic or "" })
	log(`{player.Name} spun ({kind}): {prize.Id}{if result.Cosmetic then ` → {result.Cosmetic}` else ""}`)
	return true, result
end

-- Developer panel: today's free wheel spin is ready again.
function WheelService.resetFreeSpin(player: Player)
	DataService.update(player, "Wheel", function(changed)
		changed.Wheel.FreeDay = -1
	end)
end

function WheelService.Init(_self: any)
	Net.onServerInvoke("SpinWheel", function(player: Player, kind: string)
		return WheelService.spin(player, kind)
	end)
end

return WheelService
