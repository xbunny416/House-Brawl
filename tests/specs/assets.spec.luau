--!strict
-- ReplicatedStorage.Assets (assets/Assets.luau; owner's project rules, 2026-10-30): the committed model matches a fresh
-- build, every template the game clones is there, and nothing in it is a raw emitter, sound or animation without an id.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local expect = require("../expect")

local Assets = require("../../assets/Assets")
local Sounds = require("../../assets/Sounds")

local folder = Assets.build()

local function find(path: string): any
	local node = folder
	for name in string.gmatch(path, "[^/]+") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

return {
	["the generated model is up to date (run: lune run assets/build) and in the place"] = function()
		local path = "assets/generated/Assets.rbxmx"
		expect.truthy(fs.isFile(path), path)
		expect.equal(fs.readFile(path) == roblox.serializeModel({ folder }, true), true, path)
		local project = fs.readFile("default.project.json")
		expect.truthy(string.find(project, path, 1, true) ~= nil, "default.project.json syncs it")
	end,
	["every VFX template the game clones exists"] = function()
		-- Controllers/VfxController, CrumbleController, Services/CosmeticService.
		local bursts = { "Sparks", "KOBurst", "ExplosionSmoke", "BreakDust", "CrumbleDust", "LaunchSmoke" }
		for _, name in bursts do
			local attachment = find(`VFX/{name}`)
			expect.truthy(attachment and attachment:IsA("Attachment"), `{name} is an Attachment`)
			local emitter = attachment:FindFirstChildOfClass("ParticleEmitter")
			expect.truthy(emitter ~= nil, `{name} holds a ParticleEmitter`)
		end
		for _, name in { "Anchor", "FlashBall", "Shockwave", "Chunk", "Crack" } do
			local part = find(`VFX/{name}`)
			expect.truthy(part and part:IsA("BasePart"), `{name} is a part`)
			expect.truthy(not part.CanCollide and not part.CanQuery and not part.CanTouch, `{name} only shows`)
		end
		for _, name in { "DashStreak", "CosmeticTrail" } do
			local trail = find(`VFX/{name}/Trail`)
			expect.truthy(trail and trail:IsA("Trail"), `{name} has a Trail`)
			expect.equal(trail.Attachment0, find(`VFX/{name}/Top`), `{name}'s trail starts at its Top`)
			expect.equal(trail.Attachment1, find(`VFX/{name}/Bottom`), `{name}'s trail ends at its Bottom`)
		end
		for _, path in { "VFX/KOStarburst/Holder/Text", "VFX/KOStarburst/Holder/Scale", "VFX/FloatingText/Text" } do
			expect.truthy(find(path) ~= nil, path)
		end
	end,
	["the folders the game waits for exist (VFX, Sounds/Sfx, Sounds/Music, Animations)"] = function()
		for _, path in { "VFX", "Sounds/Sfx", "Sounds/Music", "Animations" } do
			expect.truthy(find(path) ~= nil and find(path):IsA("Folder"), path)
		end
	end,
	["a sound or animation slot with an id becomes a template; one at 0 stays silent"] = function()
		local silent = { Id = 0, Volume = 0.5 }
		local config = {
			Audio = {
				Sfx = { Punch = { Id = 123, Volume = 0.7 }, Click = silent },
				Music = {
					Lobby = { Id = 456, Volume = 0.5 },
					Arenas = { Shinjuku = silent },
					Tension = silent,
					VictorySting = { Id = 789, Volume = 0.7 },
				},
			},
			Animations = { AssetIds = { Jab = 321, Kick = 0 } },
		}
		local sounds = Sounds.build(config)
		local punch = sounds.Sfx:FindFirstChild("Punch")
		expect.truthy(
			punch and punch.SoundId == "rbxassetid://123" and math.abs(punch.Volume - 0.7) < 1e-4,
			"Punch at its volume"
		)
		expect.equal(sounds.Sfx:FindFirstChild("Click"), nil, "an unpicked sound has no template")
		local lobby = sounds.Music:FindFirstChild("Lobby")
		expect.truthy(lobby and lobby.Looped, "music loops")
		local sting = sounds.Music:FindFirstChild("VictorySting")
		expect.truthy(sting and not sting.Looped, "the sting plays once")
		expect.equal(sounds.Music:FindFirstChild("Shinjuku"), nil, "an unpicked track has no template")
		local animations = Sounds.animations(config)
		local jab = animations:FindFirstChild("Jab")
		expect.truthy(jab and jab.AnimationId == "rbxassetid://321", "Jab")
		expect.equal(animations:FindFirstChild("Kick"), nil, "no Animation with an empty id")
	end,
	["no raw emitter without a texture, sound without an id or animation without an id"] = function()
		for _, instance in folder:GetDescendants() do
			if instance:IsA("ParticleEmitter") then
				expect.truthy(instance.Texture ~= "", `{instance:GetFullName()} has a texture`)
			elseif instance:IsA("Sound") then
				expect.truthy(string.find(instance.SoundId, "%d") ~= nil, `{instance:GetFullName()} has an id`)
			elseif instance:IsA("Animation") then
				expect.truthy(string.find(instance.AnimationId, "%d") ~= nil, `{instance:GetFullName()} has an id`)
			end
		end
	end,
}
