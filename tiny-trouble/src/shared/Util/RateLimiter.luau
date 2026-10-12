--!strict
--[[
	RateLimiter
	-----------
	Token-bucket rate limiter keyed by any value (normally a Player).
	Used by the server to throttle remote traffic from a single client.

		local limiter = RateLimiter.new(8, 4) -- burst of 8, refills 4 per second
		if not limiter:Allow(player) then return end
]]

export type RateLimiter = {
	Allow: (self: RateLimiter, key: any) -> boolean,
	Forget: (self: RateLimiter, key: any) -> (),
	Reset: (self: RateLimiter) -> (),
}

type Bucket = {
	tokens: number,
	last: number,
}

type RateLimiterImpl = {
	_capacity: number,
	_refillPerSecond: number,
	_buckets: { [any]: Bucket },
}

local RateLimiterClass = {}
RateLimiterClass.__index = RateLimiterClass

function RateLimiterClass.Allow(self: RateLimiterImpl, key: any): boolean
	local now = os.clock()
	local bucket = self._buckets[key]
	if not bucket then
		bucket = { tokens = self._capacity, last = now }
		self._buckets[key] = bucket
	end

	local elapsed = now - bucket.last
	bucket.last = now
	bucket.tokens = math.min(self._capacity, bucket.tokens + elapsed * self._refillPerSecond)

	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

function RateLimiterClass.Forget(self: RateLimiterImpl, key: any)
	self._buckets[key] = nil
end

function RateLimiterClass.Reset(self: RateLimiterImpl)
	table.clear(self._buckets)
end

local RateLimiter = {}

function RateLimiter.new(capacity: number, refillPerSecond: number): RateLimiter
	assert(capacity >= 1, "RateLimiter capacity must be >= 1")
	assert(refillPerSecond > 0, "RateLimiter refill rate must be > 0")
	local limiter: RateLimiterImpl = setmetatable({
		_capacity = capacity,
		_refillPerSecond = refillPerSecond,
		_buckets = {},
	}, RateLimiterClass) :: any
	return limiter :: any
end

return RateLimiter
