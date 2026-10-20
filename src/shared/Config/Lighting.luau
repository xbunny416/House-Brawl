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
	-- Roblox's dynamic clouds (Workspace.Terrain.Clouds), or none: how much of the sky they cover, how thick, their tint.
	Clouds: { Cover: number, Density: number, Color: string }?,
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
	-- Broken Highway (owner, 2026-10-20: a sky that matches the arena, "not this clear"): a smoggy sunset — the sun low
	-- behind a thick brown-orange haze, heavy rust-tinted clouds over most of the sky, slightly washed-out colour.
	Smog = {
		ClockTime = 17.85,
		GeographicLatitude = 30,
		Brightness = 2.1,
		Ambient = "#544649",
		OutdoorAmbient = "#94786A",
		ColorShiftTop = "#FF9E5E",
		ColorShiftBottom = "#2E2228",
		EnvironmentDiffuseScale = 0.4,
		EnvironmentSpecularScale = 0.2,
		Atmosphere = { Density = 0.42, Offset = 0.25, Color = "#B98466", Decay = "#4A2E28", Glare = 0.8, Haze = 2.6 },
		Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.4 },
		ColorCorrection = { Brightness = 0.01, Contrast = 0.12, Saturation = -0.08, TintColor = "#FFE8D2" },
		Clouds = { Cover = 0.78, Density = 0.65, Color = "#B07C66" },
	},
	-- Junkyard Isles (owner, 2026-10-20: a sky that matches the arena, not clear): a stormy rust sunset — the sun just
	-- setting under heavy grey-violet storm clouds lit orange from below, a dusty rust haze.
	Rust = {
		ClockTime = 18.05,
		GeographicLatitude = 30,
		Brightness = 1.9,
		Ambient = "#4E4450",
		OutdoorAmbient = "#8A6E6A",
		ColorShiftTop = "#FF8C52",
		ColorShiftBottom = "#2A2234",
		EnvironmentDiffuseScale = 0.4,
		EnvironmentSpecularScale = 0.25,
		Atmosphere = { Density = 0.38, Offset = 0.2, Color = "#A8705A", Decay = "#3E2A3A", Glare = 0.6, Haze = 2.2 },
		Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.4 },
		ColorCorrection = { Brightness = 0.01, Contrast = 0.12, Saturation = -0.02, TintColor = "#FFE6DA" },
		Clouds = { Cover = 0.72, Density = 0.78, Color = "#7E6A7A" },
	},
	-- Night with neon (Neon Motel, step 2.5). Brightened after the owner's first look ("a bit too dark"): bright
	-- moonlight and a purple ambient so fighters stay readable; the neon and roof lamps add colour.
	Night = {
		ClockTime = 0.5,
		GeographicLatitude = 30,
		Brightness = 2,
		Ambient = "#4A4270",
		OutdoorAmbient = "#6A5CA0",
		ColorShiftTop = "#7A5CFF",
		ColorShiftBottom = "#1A1030",
		EnvironmentDiffuseScale = 0.5,
		EnvironmentSpecularScale = 0.4,
		Atmosphere = { Density = 0.3, Offset = 0.1, Color = "#3A2A60", Decay = "#1A1030", Glare = 0, Haze = 0.8 },
		Bloom = { Intensity = 0.9, Size = 28, Threshold = 1.2 },
		ColorCorrection = { Brightness = 0.06, Contrast = 0.1, Saturation = 0.15, TintColor = "#EEE8FF" },
	},
}

return Lighting
