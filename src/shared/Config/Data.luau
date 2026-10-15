--!strict
-- Player data saving (ProfileStore). See Server/Services/DataService.
return {
	StoreName = "PlayerData", -- DataStore name; changing it starts everyone from scratch
	KeyPrefix = "Player_", -- profile key = KeyPrefix .. UserId
	-- true: Studio playtests use an in-memory store even when API access is enabled (live data is never touched).
	UseMockInStudio = false,
	-- How many recent developer-product PurchaseIds each profile remembers (prevents double grants).
	PurchaseIdCacheSize = 100,
	DefaultSettings = {
		MusicVolume = 0.5,
		SfxVolume = 0.8,
		CameraSensitivity = 1,
		CameraShake = true,
		LowGraphics = false,
		ButtonLayout = "Default",
	},
}
