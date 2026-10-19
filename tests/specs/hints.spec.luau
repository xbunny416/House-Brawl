--!strict
-- Key hints along the bottom edge (owner's fix list, 2026-10-19): which hints show where, and every hint is valid.
local fs = require("@lune/fs")
local csv = require("../../tools/csv")
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local HintRules = Roblox.require(Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib.HintRules)

local lists = Config.Controls.Hints

local function context(overrides: { [string]: any }): any
	local result: { [string]: any } = {
		Device = "KeyboardAndMouse",
		Status = "Lobby",
		Watching = false,
		MenuOpen = false,
		Prompts = {},
	}
	for key, value in overrides do
		result[key] = value
	end
	return result
end

local function describe(hints: { any }): string
	local parts = {}
	for _, hint in hints do
		table.insert(parts, `{table.concat(hint.Actions, "+")}={hint.Key or hint.Text}`)
	end
	return table.concat(parts, ",")
end

return {
	["lobby: run and menu, plus one hint per walk-up prompt in reach"] = function()
		expect.equal(describe(HintRules.list(context({}), lists)), "Run=Hint.Run,Menu=Hint.Menu")
		local near = HintRules.list(context({ Prompts = { "Shop" } }), lists)
		expect.equal(describe(near), "Run=Hint.Run,Menu=Hint.Menu,Grab=Shop")
	end,
	["fighting and respawning show the round's hints, prompts are left out"] = function()
		local expected = "Attack=Hint.Attack,Scoreboard=Hint.Scoreboard"
		expect.equal(describe(HintRules.list(context({ Status = "Playing", Prompts = { "Shop" } }), lists)), expected)
		expect.equal(describe(HintRules.list(context({ Status = "Respawning" }), lists)), expected)
	end,
	["spectating and watching from the lobby show how to switch fighters"] = function()
		local expected = "SpectatePrevious+SpectateNext=Hint.Spectate,Scoreboard=Hint.Scoreboard"
		expect.equal(describe(HintRules.list(context({ Status = "Spectating" }), lists)), expected)
		expect.equal(describe(HintRules.list(context({ Watching = true }), lists)), expected)
	end,
	["touch and an open menu show nothing"] = function()
		expect.equal(#HintRules.list(context({ Device = "Touch" }), lists), 0)
		expect.equal(#HintRules.list(context({ MenuOpen = true, Status = "Playing" }), lists), 0)
	end,
	["every hint names known actions and an existing string"] = function()
		local rows = csv.parse(fs.readFile("src/localization/GameStrings.csv"))
		local keys: { [string]: boolean } = {}
		for index = 2, #rows do
			keys[rows[index][1]] = true
		end
		for name, list in { Lobby = lists.Lobby, Round = lists.Round, Spectating = lists.Spectating } do
			for _, hint in list do
				expect.truthy(#hint.Actions > 0, `{name}: a hint without actions`)
				for _, action in hint.Actions do
					expect.truthy(table.find(Config.Controls.Actions, action), `{name}: unknown action {action}`)
				end
				expect.truthy(keys[hint.Key], `{name}: missing string {hint.Key}`)
			end
		end
		expect.truthy(table.find(Config.Controls.Actions, lists.PromptAction), "PromptAction is an action")
	end,
}
