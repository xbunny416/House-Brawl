--!strict
-- Scrap/XP rewards and payout bonuses. Bible §2.1 "Main Resource Gain" and "Reward Distribution".
local Types = require(script.Parent.Types)

type EconomyConfig = {
	StartingScrap: number,
	Rewards: {
		KO: Types.Reward,
		Win: Types.Reward,
		Top3: Types.Reward,
		Completed: Types.Reward,
	},
	WinnerAlsoGetsTop3: boolean,
	KOStreak: { Start: number, Step: number, Max: number },
	Bonuses: {
		VIPScrap: number,
		PremiumScrap: number,
		FriendXPPerFriend: number,
		FriendXPMax: number,
		MaxTotal: number,
	},
	EventScrapMultiplier: number,
	PrivateServerRewardScale: number,
	PrivateServerProgress: boolean,
}

local Economy: EconomyConfig = {
	StartingScrap = 0,

	Rewards = {
		KO = { Scrap = 10, XP = 20 }, -- ring-out or HP KO
		Win = { Scrap = 50, XP = 100 },
		Top3 = { Scrap = 25, XP = 50 }, -- 2nd and 3rd place (see WinnerAlsoGetsTop3)
		Completed = { Scrap = 15, XP = 40 }, -- stayed until the end
	},
	-- false: 1st place gets Win only; true: 1st place gets Win + Top3.
	WinnerAlsoGetsTop3 = false,

	-- KO streak multiplier on KO Scrap: Start + Step per previous consecutive KO, capped at Max.
	-- Resets when you are KO'd or the round ends.
	KOStreak = { Start = 1, Step = 0.1, Max = 1.5 },

	-- Payout bonuses add together and are capped at +MaxTotal per currency.
	Bonuses = {
		VIPScrap = 0.25,
		PremiumScrap = 0.1,
		FriendXPPerFriend = 0.1,
		FriendXPMax = 0.3,
		MaxTotal = 0.6,
	},

	-- Live-event multiplier on all Scrap payouts (2 = double-Scrap weekend). Not part of the bonus cap.
	EventScrapMultiplier = 1,

	-- Private servers are for play and testing only (owner, 2026-10-17): round rewards (Scrap, XP, so no levels) are
	-- scaled by PrivateServerRewardScale (0 = nothing), and PrivateServerProgress says whether lifetime stats — and
	-- later quests, badges and leaderboards — count there. Robux purchases and the Shop still work.
	PrivateServerRewardScale = 0,
	PrivateServerProgress = false,
}

return Economy
