--!strict
-- Low-end device performance (bible §6 "runs smoothly on low-end phones"; step 3.11).
return {
	-- How often other characters are posed (Client/Lib/AnimationLod): every frame up to Near studs from the camera,
	-- every FarEvery frames up to Far, every OffscreenEvery frames when off screen, not at all past Cull. Low Graphics
	-- multiplies the distances by LowGraphicsScale. Your own character is posed every frame.
	AnimationLod = {
		Near = 60,
		Far = 150,
		Cull = 300,
		FarEvery = 2,
		OffscreenEvery = 4,
		LowGraphicsScale = 0.6,
	},
	-- Once per player, StartDelay seconds after joining, the client measures its frame rate for SampleTime seconds;
	-- below MinFps it turns Low Graphics on (and says so). Players can switch it back in Settings.
	AutoLowGraphics = { StartDelay = 10, SampleTime = 20, MinFps = 40 },
}
