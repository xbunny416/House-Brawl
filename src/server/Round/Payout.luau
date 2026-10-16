--!strict
--[[
	Payout — one player's round reward (pure): their round result plus who they are (VIP, Premium, friends in the
	server, private server) turned into Formulas.roundPayout's input. Bible §2.1 "Reward distribution".
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared:WaitForChild("Formulas"))

-- The parts of RoundService's Result the payout needs.
export type RoundResult = {
	Placement: number,
	KOs: number,
	KOScrap: number,
	PerfectDodges: number,
	Completed: boolean,
	ActiveSeconds: number,
	AFKAtEnd: boolean,
}

export type Bonuses = {
	IsVIP: boolean,
	IsPremium: boolean,
	FriendsInServer: number,
	IsPrivateServer: boolean,
}

local Payout = {}

function Payout.forResult(result: RoundResult, bonuses: Bonuses): Formulas.Payout
	return Formulas.roundPayout({
		KOScrap = result.KOScrap,
		KOs = result.KOs,
		PerfectDodges = result.PerfectDodges,
		Placement = result.Placement,
		Completed = result.Completed,
		ActiveSeconds = result.ActiveSeconds,
		AFKAtEnd = result.AFKAtEnd,
		IsVIP = bonuses.IsVIP,
		IsPremium = bonuses.IsPremium,
		FriendsInServer = bonuses.FriendsInServer,
		IsPrivateServer = bonuses.IsPrivateServer,
	})
end

return Payout
