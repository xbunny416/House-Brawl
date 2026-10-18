--!strict
--[[
	Launch check (step 3.12): lists everything in the code that still has a placeholder before release — Robux pass /
	product ids, the group id, badge ids, audio ids, the developer panel allowlist and the placeholder code. Report
	only (always exits 0); the owner-side steps are in docs/LAUNCH.md.
	  lune run tools/launch-check
]]
local Shim = require("../tests/roblox")

local Config = Shim.require(Shim.game.ReplicatedStorage.Shared.Config)
local ServerConfig = Shim.require(Shim.game.ServerScriptService.Server.ServerConfig)

local todo = 0

local function heading(text: string)
	print(`\n{text}`)
end

local function line(ok: boolean, text: string)
	if not ok then
		todo += 1
	end
	print(`  [{if ok then "x" else " "}] {text}`)
end

local function sorted(map: { [string]: any }): { string }
	local keys: { string } = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

heading("Robux (Creator Dashboard → Monetization; ids go in src/shared/Config/Monetization.luau)")
for _, key in sorted(Config.Monetization.GamePasses) do
	local pass = Config.Monetization.GamePasses[key]
	line(pass.Id > 0, `Game pass {key} ({pass.PriceRobux} R$): id {pass.Id}`)
end
for _, key in sorted(Config.Monetization.Products) do
	local product = Config.Monetization.Products[key]
	line(product.Id > 0, `Developer product {key} ({product.PriceRobux} R$): id {product.Id}`)
end

heading("Group (Config.Retention.Group.GroupId: [Crew] chat tag + join reward)")
line(Config.Retention.Group.GroupId > 0, `Group id {Config.Retention.Group.GroupId}`)

heading("Badges (optional, skipped for now: Config.Retention.Badges)")
local badgesMade = 0
local badgeCount = 0
for _, badge in Config.Retention.Badges do
	badgeCount += 1
	if badge.BadgeId > 0 then
		badgesMade += 1
	end
end
print(`  {badgesMade} of {badgeCount} badges have ids`)

heading("Audio (free Creator Store audio ids in src/shared/Config/Audio.luau)")
local silent: { string } = {}
local function walk(node: any, path: string)
	if type(node) ~= "table" then
		return
	end
	if type(node.Id) == "number" then
		if node.Id == 0 then
			table.insert(silent, path)
		end
		return
	end
	for _, key in sorted(node) do
		walk(node[key], if path == "" then key else `{path}.{key}`)
	end
end
walk({ Music = Config.Audio.Music, Sfx = Config.Audio.Sfx }, "")
line(#silent == 0, `{#silent} sound slots are silent{if #silent > 0 then ": " .. table.concat(silent, ", ") else ""}`)

heading("Developer panel (Config.Dev.AllowedUserIds: who can open it in live servers)")
print(`  {#Config.Dev.AllowedUserIds} UserIds allowed (empty = Studio only, the owner's choice; optional)`)

heading("Codes (server-only: src/server/ServerConfig.luau)")
for _, key in sorted(ServerConfig.Codes) do
	local code = ServerConfig.Codes[key]
	local placeholder = key == "LAUNCH"
	line(
		not placeholder,
		`{key}: {code.Scrap or 0} Scrap{if placeholder then " (placeholder: rename it for launch)" else ""}`
	)
end

print(`\n{todo} item(s) left. Owner-side steps (publish, store page, tests): docs/LAUNCH.md`)
