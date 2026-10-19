--!strict
--[[
	NewsRules — what the lobby's news TVs show (owner's fix list, 2026-10-19: "TV showing fun news"). Pure, so Lune
	specs test it. Live stories come from what this client knows (the last round's winner, today's daily deal at the
	bar, the Wins leader) and are mixed in between the fun headlines ("News.1" … "News.<count>"), one live story after
	each fun one, so they come round often.
]]
export type Facts = {
	Winner: { Name: string, Map: string }?, -- the last round's winner and the arena's name (already localized)
	Deal: { Item: string, Price: string }?, -- a daily deal: the item's name, its price (formatted)
	Leader: { Name: string, Value: string }?, -- the all-time Wins leader and their wins (formatted)
}

export type Headline = { Key: string, Args: { any }? }

local NewsRules = {}

-- Every GameStrings key a live story can use.
NewsRules.LiveKeys = { "News.Winner", "News.Deal", "News.Leader" }

function NewsRules.headlines(facts: Facts, count: number): { Headline }
	local live: { Headline } = {}
	local winner = facts.Winner
	if winner then
		table.insert(live, { Key = "News.Winner", Args = { winner.Name, winner.Map } })
	end
	local deal = facts.Deal
	if deal then
		table.insert(live, { Key = "News.Deal", Args = { deal.Item, deal.Price } })
	end
	local leader = facts.Leader
	if leader then
		table.insert(live, { Key = "News.Leader", Args = { leader.Name, leader.Value } })
	end
	local result: { Headline } = {}
	for index = 1, count do
		table.insert(result, { Key = `News.{index}` })
		if live[index] then
			table.insert(result, live[index])
		end
	end
	return result
end

return NewsRules
