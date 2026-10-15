--!strict
--[[
	Token-bucket rate limiter keyed by any value (usually a Player).
	Each key gets `burst` tokens that refill at `rate` tokens per second; every allowed call spends one token.
	Pure: the caller passes the current time, so it is deterministic in tests.
]]
local RateLimiter = {}
RateLimiter.__index = RateLimiter

type Bucket = { tokens: number, updated: number }

export type RateLimiter = typeof(setmetatable(
	{} :: {
		rate: number,
		burst: number,
		buckets: { [any]: Bucket },
	},
	RateLimiter
))

function RateLimiter.new(rate: number, burst: number): RateLimiter
	assert(rate > 0 and burst >= 1, "RateLimiter needs rate > 0 and burst >= 1")
	return setmetatable({ rate = rate, burst = burst, buckets = {} }, RateLimiter)
end

-- Spends one token for `key` if available. Returns false when the key is over its limit.
function RateLimiter.allow(self: RateLimiter, key: any, now: number): boolean
	local bucket = self.buckets[key]
	if not bucket then
		bucket = { tokens = self.burst, updated = now }
		self.buckets[key] = bucket
	end
	local elapsed = math.max(now - bucket.updated, 0)
	bucket.tokens = math.min(self.burst, bucket.tokens + elapsed * self.rate)
	bucket.updated = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

-- Forgets a key (call when a player leaves).
function RateLimiter.remove(self: RateLimiter, key: any)
	self.buckets[key] = nil
end

return RateLimiter
