--!strict
-- The lobby bartender's phrases (owner's fix list): when the bartender talks, which line, and that every line exists.
local fs = require("@lune/fs")
local csv = require("../../tools/csv")
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local BartenderRules = Roblox.require(Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib.BartenderRules)

local talk = Config.World.Bartender.Talk

-- Says whatever `tick` asks for at `now`, the way the controller does (a 4 s line, idle delay at its minimum).
local function step(state: any, near: boolean, now: number): string?
	local pool = BartenderRules.tick(state, talk, near, now)
	if pool then
		BartenderRules.said(state, talk, now, 4, 0)
	end
	return pool
end

return {
	["walking up greets once per cooldown"] = function()
		local state = BartenderRules.new()
		expect.equal(step(state, false, 0), nil)
		expect.equal(step(state, true, 1), "Greet")
		expect.equal(step(state, true, 2), nil)
		expect.equal(step(state, false, 10), nil)
		expect.equal(step(state, true, 11), nil) -- back too soon: no second greeting
		expect.equal(step(state, false, 20), nil)
		expect.equal(step(state, true, 1 + talk.GreetCooldown), "Greet")
	end,
	["staying near brings idle lines, never over a line on show"] = function()
		local state = BartenderRules.new()
		expect.equal(step(state, true, 0), "Greet")
		local due = 4 + talk.IdleEvery.Min
		expect.equal(step(state, true, due - 0.1), nil)
		expect.equal(step(state, true, due), "Idle")
		expect.equal(step(state, true, due + 1), nil)
		-- A Shop line pushes the next idle line back.
		BartenderRules.said(state, talk, due + 2, 6, 0)
		expect.equal(step(state, true, due + 4 + talk.IdleEvery.Min), nil)
		expect.equal(step(state, true, due + 8 + talk.IdleEvery.Min), "Idle")
		expect.equal(step(state, false, 1000), nil)
	end,
	["a round's result is said once, the next time the player is near"] = function()
		local state = BartenderRules.new()
		expect.equal(step(state, true, 0), "Greet")
		BartenderRules.roundEnded(state, 1)
		expect.equal(step(state, false, 5), nil)
		expect.equal(step(state, true, 6), "Won")
		expect.equal(step(state, false, 7), nil)
		expect.equal(step(state, true, 8), nil)
		BartenderRules.roundEnded(state, 3)
		expect.equal(step(state, true, 9), "Lost")
	end,
	["shop lines only near the bar"] = function()
		expect.equal(BartenderRules.react("ShopOpened", true), "Shop")
		expect.equal(BartenderRules.react("Bought", true), "Thanks")
		expect.equal(BartenderRules.react("ShopOpened", false), nil)
		expect.equal(BartenderRules.react("Bought", false), nil)
	end,
	["a pool never says its last line twice in a row"] = function()
		local state = BartenderRules.new()
		local last = BartenderRules.pick(state, "Idle", 5, 0.99)
		expect.equal(last, 5)
		for _, roll in { 0, 0.3, 0.6, 0.99 } do
			local index = BartenderRules.pick(state, "Idle", 5, roll)
			expect.truthy(index ~= last and index >= 1 and index <= 5, `roll {roll}: {index}`)
			last = index
		end
		expect.equal(BartenderRules.pick(state, "Shop", 1, 0.5), 1)
		expect.equal(BartenderRules.pick(state, "Shop", 1, 0.5), 1)
	end,
	["read time grows with the line, within its limits"] = function()
		local time = talk.ReadTime
		expect.equal(BartenderRules.readTime(talk, 0), time.Min)
		expect.equal(BartenderRules.readTime(talk, 10_000), time.Max)
		expect.truthy(BartenderRules.readTime(talk, 40) >= BartenderRules.readTime(talk, 20), "longer reads longer")
		expect.truthy(talk.IdleEvery.Min > 0 and talk.IdleEvery.Max >= talk.IdleEvery.Min, "idle range")
		expect.truthy(talk.Distance > 0 and talk.GreetCooldown > 0, "distance and cooldown")
	end,
	["every pool has its lines, and no more than Config says"] = function()
		local rows = csv.parse(fs.readFile("src/localization/GameStrings.csv"))
		local keys: { [string]: boolean } = {}
		for index = 2, #rows do
			keys[rows[index][1]] = true
		end
		for _, pool in BartenderRules.Pools do
			local count = talk.Lines[pool]
			expect.truthy(count and count >= 1, `{pool} lines`)
			for index = 1, count do
				expect.truthy(keys[`Bartender.{pool}.{index}`], `Bartender.{pool}.{index}`)
			end
			expect.equal(keys[`Bartender.{pool}.{count + 1}`], nil, `Bartender.{pool}.{count + 1} is unused`)
		end
	end,
}
