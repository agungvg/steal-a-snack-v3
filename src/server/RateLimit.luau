-- RateLimit.luau
-- Per-player, per-action cooldowns. Pure table logic, no Roblox calls.
-- Written fresh for Steal a Snack v3 from the design spec.

local RateLimit = {}

RateLimit.Limits = {
	Buy = 2,
	Steal = 5,
}

local lastAction: { [string]: number } = {}

function RateLimit.check(userId, action)
	local limit = RateLimit.Limits[action]
	if not limit then
		-- Unknown actions are not rate-limited.
		return true
	end
	local key = tostring(userId) .. ":" .. action
	local now = os.clock()
	local previous = lastAction[key]
	if previous and (now - previous) < limit then
		return false
	end
	lastAction[key] = now
	return true
end

function RateLimit.reset(userId, action)
	if action then
		lastAction[tostring(userId) .. ":" .. action] = nil
		return
	end
	local prefix: string = tostring(userId) .. ":"
	for key in pairs(lastAction) do
		if string.sub(key, 1, #prefix) == prefix then
			lastAction[key] = nil
		end
	end
end

return RateLimit
