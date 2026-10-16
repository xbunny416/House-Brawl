--!strict
--[[
	Vote — one map or mode vote (pure). Each player has one choice and can change it until the vote closes.
	The option with the most votes wins; ties and empty votes are settled with `pick`, which returns a random index in
	1..n (passed in so specs are deterministic).
]]
export type Pick = (count: number) -> number

export type Vote = {
	Options: { string },
	Choices: { [number]: string }, -- UserId -> option
}

local Vote = {}

function Vote.new(options: { string }): Vote
	return { Options = table.clone(options), Choices = {} }
end

-- Up to `count` different entries of `pool`, in random order.
function Vote.pickOptions(pool: { string }, count: number, pick: Pick): { string }
	local remaining = table.clone(pool)
	local chosen: { string } = {}
	while #chosen < count and #remaining > 0 do
		table.insert(chosen, table.remove(remaining, pick(#remaining)) :: string)
	end
	return chosen
end

-- Records (or changes) a player's choice. False if `option` is not on the ballot.
function Vote.cast(vote: Vote, userId: number, option: string): boolean
	if not table.find(vote.Options, option) then
		return false
	end
	vote.Choices[userId] = option
	return true
end

-- Drops a player's choice (they left).
function Vote.remove(vote: Vote, userId: number)
	vote.Choices[userId] = nil
end

-- Votes per option (every option listed, 0 included).
function Vote.counts(vote: Vote): { [string]: number }
	local counts: { [string]: number } = {}
	for _, option in vote.Options do
		counts[option] = 0
	end
	for _, option in vote.Choices do
		counts[option] += 1
	end
	return counts
end

-- The winning option: most votes, a random one of the tied leaders (or of all options if nobody voted).
function Vote.winner(vote: Vote, pick: Pick): string
	local counts = Vote.counts(vote)
	local best = -1
	local leaders: { string } = {}
	for _, option in vote.Options do
		local count = counts[option]
		if count > best then
			best = count
			leaders = { option }
		elseif count == best then
			table.insert(leaders, option)
		end
	end
	return leaders[pick(#leaders)]
end

return Vote
