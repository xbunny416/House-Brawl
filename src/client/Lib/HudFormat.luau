--!strict
--[[
	HudFormat — pure helpers for the HUD and scoreboard (no instances, so Lune specs test them): the round clock,
	numbers with thousands separators, the Percent color, the dash ring fill and the scoreboard order.
]]
export type Rgb = { R: number, G: number, B: number } -- 0..1 each

export type ScoreRow = {
	Name: string,
	Lives: number?, -- Classic
	KOs: number,
	Falls: number,
	InRound: boolean,
}

local HudFormat = {}

-- Percent color stops: white at 0%, yellow at 60%, red from 150% (bible §4.3: white → yellow → red).
local STOPS: { { at: number, color: Rgb } } = {
	{ at = 0, color = { R = 1, G = 1, B = 1 } },
	{ at = 60, color = { R = 1, G = 0.86, B = 0.2 } },
	{ at = 150, color = { R = 1, G = 0.23, B = 0.19 } },
}

-- "m:ss" for a number of seconds (rounded up, never negative).
function HudFormat.clock(seconds: number): string
	local whole = math.max(math.ceil(seconds), 0)
	return string.format("%d:%02d", whole // 60, whole % 60)
end

-- Every GameStrings key queueKey can return.
HudFormat.QueueKeys = {
	"Round.Waiting",
	"Round.WaitingIn",
	"Round.QueueAFK",
	"Round.Starting",
	"Round.JoinNow",
	"Round.Joining",
	"Round.JoinNext",
	"Round.InNext",
}

--[[
	The line the HUD shows about the lobby join pad (a GameStrings key), or nil for none. `state` is the RoundState,
	`roundStatus` / `queueStatus` the local player's RoundStatus / QueueStatus attributes, `joinMidRound` whether the
	running mode lets players join mid-round (Casual). On the pad during the vote the vote panel shows instead.
]]
function HudFormat.queueKey(state: string?, roundStatus: string?, queueStatus: string?, joinMidRound: boolean): string?
	local queue = queueStatus or "Off"
	if state == "Waiting" then
		return if queue == "In" then "Round.WaitingIn" elseif queue == "AFK" then "Round.QueueAFK" else "Round.Waiting"
	elseif state == "Voting" then
		return if queue == "Off" then "Round.Starting" else nil
	elseif state == "Playing" and roundStatus == "Lobby" then
		if queue == "AFK" then
			return "Round.QueueAFK"
		elseif joinMidRound then
			return if queue == "In" then "Round.Joining" else "Round.JoinNow"
		end
		return if queue == "In" then "Round.InNext" else "Round.JoinNext"
	end
	return nil
end

-- "h:mm:ss" for a number of seconds (rounded up, never negative).
function HudFormat.longClock(seconds: number): string
	local whole = math.max(math.ceil(seconds), 0)
	return string.format("%d:%02d:%02d", whole // 3600, whole // 60 % 60, whole % 60)
end

-- A whole number with thousands separators ("1,234,567"; the whole part, minus sign kept), for coin balances.
function HudFormat.thousands(value: number): string
	local whole = if value < 0 then math.ceil(value) else math.floor(value)
	local digits = tostring(math.abs(whole))
	local grouped = string.reverse((string.gsub(string.reverse(digits), "(%d%d%d)", "%1,")))
	if string.sub(grouped, 1, 1) == "," then
		grouped = string.sub(grouped, 2)
	end
	return if whole < 0 then "-" .. grouped else grouped
end

-- The color a Percent is shown in.
function HudFormat.percentColor(percent: number): Rgb
	if percent <= STOPS[1].at then
		return STOPS[1].color
	end
	for index = 2, #STOPS do
		local low, high = STOPS[index - 1], STOPS[index]
		if percent <= high.at then
			local t = (percent - low.at) / (high.at - low.at)
			return {
				R = low.color.R + (high.color.R - low.color.R) * t,
				G = low.color.G + (high.color.G - low.color.G) * t,
				B = low.color.B + (high.color.B - low.color.B) * t,
			}
		end
	end
	return STOPS[#STOPS].color
end

-- How full the dash ring is: 1 = ready, 0 = just used.
function HudFormat.dashFill(cooldownLeft: number, cooldown: number): number
	if cooldown <= 0 then
		return 1
	end
	return math.clamp(1 - cooldownLeft / cooldown, 0, 1)
end

-- Scoreboard order: fighters in the round first; Classic by lives, then KOs, then fewest falls; Casual by score
-- (KOs − falls), then KOs; then by name.
function HudFormat.sortScoreboard(rows: { ScoreRow }): { ScoreRow }
	local sorted = table.clone(rows)
	table.sort(sorted, function(a: ScoreRow, b: ScoreRow): boolean
		if a.InRound ~= b.InRound then
			return a.InRound
		end
		if a.Lives ~= nil or b.Lives ~= nil then
			local livesA, livesB = a.Lives or 0, b.Lives or 0
			if livesA ~= livesB then
				return livesA > livesB
			end
		else
			local scoreA, scoreB = a.KOs - a.Falls, b.KOs - b.Falls
			if scoreA ~= scoreB then
				return scoreA > scoreB
			end
		end
		if a.KOs ~= b.KOs then
			return a.KOs > b.KOs
		end
		if a.Falls ~= b.Falls then
			return a.Falls < b.Falls
		end
		return a.Name < b.Name
	end)
	return sorted
end

return HudFormat
