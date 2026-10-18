--!strict
--[[
	CodeRules — redeem codes (bible §8; the codes are in the server-only ServerConfig). Pure, so specs test it.
	What the player typed is tidied (spaces dropped, upper-case) and looked up; a code is refused when it doesn't
	exist, has expired, or this player already used it. Codes are only ever checked on the server.
]]
local ServerConfig = require(script.Parent.Parent.ServerConfig)

local CodeRules = {}

CodeRules.MaxLength = 24
-- Why a code was refused; the Codes screen shows "Codes.Error.<Reason>". TryAgain is the client's own (no answer).
CodeRules.Reasons = { "Invalid", "Expired", "Redeemed", "PrivateServer", "NotLoaded", "TryAgain" }

-- What the player typed, as a code key: no spaces, upper-case, at most MaxLength characters.
function CodeRules.normalize(text: string): string
	local code = string.upper((string.gsub(text, "%s", "")))
	return string.sub(code, 1, CodeRules.MaxLength)
end

--[[
	Checks `text` for a player who has used the codes in `redeemed`, at unix time `now`. Returns the code key and its
	reward, or nil and a reason. `codes` defaults to ServerConfig.Codes (specs pass their own).
]]
function CodeRules.check(
	text: string,
	redeemed: { [string]: boolean },
	now: number,
	codes: { [string]: ServerConfig.Code }?
): (string?, ServerConfig.Code?, string?)
	local list = codes or ServerConfig.Codes
	local key = CodeRules.normalize(text)
	local code = list[key]
	if key == "" or code == nil then
		return nil, nil, "Invalid"
	end
	if code.ExpiresAt and now >= code.ExpiresAt then
		return nil, nil, "Expired"
	end
	if redeemed[key] then
		return nil, nil, "Redeemed"
	end
	return key, code, nil
end

return CodeRules
