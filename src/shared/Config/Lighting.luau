--!strict
-- Lighting presets applied by MapService for the lobby and each arena (bible §3.2). Colors are hex strings.
-- Bloom and ColorCorrection are post-effects that the Low Graphics setting turns off on the client.
export type Preset = {
	ClockTime: number,
	GeographicLatitude: number,
	Brightness: number,
	Ambient: string,
	OutdoorAmbient: string,
	ColorShiftTop: string,
	ColorShiftBottom: string,
	EnvironmentDiffuseScale: number,
	EnvironmentSpecularScale: number,
	Atmosphere: { Density: number, Offset: number, Color: string, Decay: string, Glare: number, Haze: number },
	Bloom: { Intensity: number, Size: number, Threshold: number },
	ColorCorrection: { Brightness: number, Contrast: number, Saturation: number, TintColor: string },
}

local Lighting: { [string]: Preset } = {
	-- Late-afternoon dusk: orange sky, dusty haze (density ~0.35).
	Dusk = {
		ClockTime = 17.6,
		GeographicLatitude = 30,
		Brightness = 2.4,
		Ambient = "#5C4A48",
		OutdoorAmbient = "#A07E6A",
		ColorShiftTop = "#FFB37A",
		ColorShiftBottom = "#3A2A30",
		EnvironmentDiffuseScale = 0.4,
		EnvironmentSpecularScale = 0.25,
		Atmosphere = { Density = 0.35, Offset = 0.2, Color = "#E8A27A", Decay = "#8C5A4A", Glare = 0.4, Haze = 1.8 },
		Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.4 },
		ColorCorrection = { Brightness = 0.02, Contrast = 0.08, Saturation = 0.05, TintColor = "#FFF1E0" },
	},
	-- Night with neon (Neon Motel, step 2.5).
	Night = {
		ClockTime = 0.5,
		GeographicLatitude = 30,
		Brightness = 1,
		Ambient = "#2A2440",
		OutdoorAmbient = "#3A3260",
		ColorShiftTop = "#7A5CFF",
		ColorShiftBottom = "#1A1030",
		EnvironmentDiffuseScale = 0.3,
		EnvironmentSpecularScale = 0.4,
		Atmosphere = { Density = 0.4, Offset = 0.1, Color = "#3A2A60", Decay = "#1A1030", Glare = 0, Haze = 1.2 },
		Bloom = { Intensity = 0.9, Size = 28, Threshold = 1.2 },
		ColorCorrection = { Brightness = 0, Contrast = 0.12, Saturation = 0.15, TintColor = "#E8E0FF" },
	},
}

return Lighting
