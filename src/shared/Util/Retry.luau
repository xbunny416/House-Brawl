--!strict
--[[
	Retry — calls something that may fail (a Roblox web call) up to `attempts` times, waiting `delay` seconds between
	tries. Returns true and the result, or false and the last error.
]]
local Retry = {}

function Retry.call(attempts: number, delay: number, callback: () -> any): (boolean, any)
	local ok, result = false, nil
	for attempt = 1, math.max(attempts, 1) do
		ok, result = pcall(callback)
		if ok then
			return true, result
		end
		if attempt < attempts then
			task.wait(delay)
		end
	end
	return false, result
end

return Retry
