--!strict
-- Server-only configuration: never replicated to clients, so values here cannot be read by exploiters.
export type Code = {
	Scrap: number?, -- Scrap given
	Cosmetic: string?, -- a Config.Cosmetics.Items id given (nothing more if the player already owns it)
	ExpiresAt: number?, -- unix time (os.time()); nil = never expires
}

return table.freeze({
	-- Redeem codes (bible §8): upper-case keys, letters and digits only. One use per player, checked on the server
	-- (Services/CodeService). A code needs a Scrap and / or a Cosmetic reward. To add one:
	--   SUMMER26 = table.freeze({ Scrap = 500, ExpiresAt = os.time({ year = 2026, month = 9, day = 1 }) }),
	-- LAUNCH is a placeholder: change the code and reward before release.
	Codes = table.freeze({
		LAUNCH = table.freeze({ Scrap = 250 }) :: Code,
	}) :: { [string]: Code },
})
