--!strict
-- Server-only configuration: never replicated to clients, so values here cannot be read by exploiters.
type Code = {
	Scrap: number,
	ExpiresAt: number?, -- unix time (os.time()); nil = never expires
}

return table.freeze({
	-- Redeem codes (upper-case keys). One use per player, validated on the server. Bible §8.
	-- LAUNCH is a placeholder: change the code and reward before release.
	Codes = table.freeze({
		LAUNCH = table.freeze({ Scrap = 250 }) :: Code,
	}) :: { [string]: Code },
})
