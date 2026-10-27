--!strict
-- The lobby spin wheel (owner's fix list, 2026-10-19): exact odds that add up to 100, the free daily spin and paid
-- spins, one spin at a time, picks that follow the odds, the cosmetic prize, and the wheel in the lobby: one slice per
-- prize with its label facing the room, and the spin button.
local fs = require("@lune/fs")
local csv = require("../../tools/csv")
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local WheelRules = Roblox.require(Roblox.game.ReplicatedStorage.Shared.WheelRules)
local Hideout = require("../../maps/layouts/Hideout")

local Wheel = Config.Retention.Wheel
local DAY = 20000

local function tagged(root: any, tag: string): { any }
	local found = {}
	for _, item in root:GetDescendants() do
		if item:HasTag(tag) then
			table.insert(found, item)
		end
	end
	return found
end

return {
	["prizes: known kinds, positive amounts, unique ids, odds add up to exactly 100"] = function()
		local total, seen = 0, {}
		for _, prize in Wheel.Prizes do
			expect.truthy(table.find(WheelRules.PrizeKinds, prize.Kind), `{prize.Id} kind`)
			expect.truthy(prize.Amount > 0 and prize.Percent > 0, `{prize.Id} amount / percent`)
			expect.equal(seen[prize.Id], nil, `duplicate {prize.Id}`)
			seen[prize.Id] = true
			total += prize.Percent
		end
		expect.near(total, 100)
		expect.truthy(Wheel.SpinPrice > 0 and Wheel.CosmeticFallbackScrap > 0, "prices")
	end,
	["spins land on each prize as often as its odds say"] = function()
		local counts: { [number]: number } = {}
		local steps = 10000
		for index = 0, steps - 1 do
			local prize = WheelRules.pick((index + 0.5) / steps)
			counts[prize] = (counts[prize] or 0) + 1
		end
		for index, prize in Wheel.Prizes do
			expect.near((counts[index] or 0) / steps * 100, prize.Percent, 0.02, prize.Id)
		end
		expect.equal(WheelRules.pick(0.99999), #Wheel.Prizes)
	end,
	["spin checks: private servers, fighting, one spin at a time, the daily free spin, paid spins"] = function()
		local wheel = { FreeDay = -1 }
		local function check(kind: string, scrap: number, overrides: { [string]: boolean }?): string?
			local checks: { [string]: boolean } = { Allowed = true, Fighting = false, PaidAllowed = true }
			for key, value in overrides or {} do
				checks[key] = value
			end
			return WheelRules.checkSpin(wheel, kind, DAY, scrap, checks :: any)
		end
		expect.equal(check("Free", 0), nil)
		expect.equal(check("Free", 0, { Allowed = false }), "PrivateServer")
		expect.equal(check("Free", 0, { Fighting = true }), "Fighting")
		expect.equal(check("Free", 0, { Busy = true }), "Busy")
		expect.equal(check("Paid", Wheel.SpinPrice, { Busy = true }), "Busy")
		expect.equal(check("Paid", Wheel.SpinPrice), nil)
		expect.equal(check("Paid", Wheel.SpinPrice - 1), "NotEnoughScrap")
		expect.equal(check("Paid", 1000000, { PaidAllowed = false }), "NotAllowed")
		expect.equal(check("Spin", 1000000), "TryAgain")
		wheel.FreeDay = DAY
		expect.equal(check("Free", 0), "NoFreeSpin")
		expect.equal(WheelRules.freeSpinReady(wheel, DAY + 1), true, "back the next day")
	end,
	["the cosmetic prize is one the player doesn't own, sold for Scrap; none when they own them all"] = function()
		local owned: { [string]: boolean } = {}
		local first = WheelRules.cosmeticFor(owned, 0)
		expect.truthy(first and Config.Cosmetics.Items[first].Exclusive == nil, "a Scrap cosmetic")
		for id in Config.Cosmetics.Items do
			owned[id] = true
		end
		expect.equal(WheelRules.cosmeticFor(owned, 0.5), nil)
	end,
	["every prize and reason has its strings"] = function()
		local rows = csv.parse(fs.readFile("src/localization/GameStrings.csv"))
		local keys: { [string]: boolean } = {}
		for index = 2, #rows do
			keys[rows[index][1]] = true
		end
		for _, reason in WheelRules.Reasons do
			expect.truthy(keys[`Wheel.Error.{reason}`], `Wheel.Error.{reason}`)
		end
		for _, kind in WheelRules.PrizeKinds do
			expect.truthy(keys[`Wheel.Slice.{kind}`], `Wheel.Slice.{kind}`)
		end
		local others =
			{ "Wheel.XP", "Wheel.StyleSpin", "Wheel.Cosmetic", "Wheel.Won", "Currency.Scrap", "Lobby.Sign.Wheel" }
		for _, key in { "Prompt.Wheel", "Prompt.Wheel.Free", "Prompt.Wheel.Paid", "Prompt.Wheel.Object" } do
			table.insert(others, key)
		end
		for _, key in others do
			expect.truthy(keys[key], key)
		end
	end,
	["the lobby wheel: one slice (two wedges) and one label per prize, the labels facing the room, a spin button"] = function()
		local lobby = Hideout.build(Config.Maps.LobbyOrigin)
		local wheels = tagged(lobby, "SpinWheel")
		expect.equal(#wheels, 1)
		local wheel = wheels[1]
		expect.equal(wheel.ModelStreamingMode.Name, "Atomic", "streams in whole")
		local stand = wheel:FindFirstChild("SpinButton")
		expect.truthy(stand and stand:FindFirstChild("Button"), "SpinButton with a Button")
		local rotor = wheel:FindFirstChild("Rotor")
		expect.truthy(rotor and rotor:FindFirstChild("Hub"), "Rotor with a Hub")
		local hub = rotor.Hub.CFrame.Position
		-- The wheel hangs on the east wall since 2026-10-27 (the west wall before): the room is toward −X from it.
		local room = if hub.X > Config.Maps.LobbyOrigin[1] then -1 else 1
		local slices: { [number]: number } = {}
		local labels: { [number]: number } = {}
		for _, part in rotor:GetDescendants() do
			local segment = part:GetAttribute("Segment")
			if segment and part.Name == "Label" then
				labels[segment] = (labels[segment] or 0) + 1
				-- Its front (where the client writes the prize) faces the room; its up points from the hub out
				-- through the middle of its slice (slice i at (i - 1) / count of a turn from the top, toward +Z).
				local angle = (segment - 1) / #Wheel.Prizes * 2 * math.pi
				local look, up = part.CFrame.LookVector, part.CFrame.UpVector
				expect.near(look.X, room, 1e-3, `label {segment} faces the room`)
				expect.near(up.Y, math.cos(angle), 1e-3, `label {segment} up`)
				expect.near(up.Z, math.sin(angle), 1e-3, `label {segment} up`)
				local out = part.CFrame.Position - hub
				expect.near(out.Y * up.Z - out.Z * up.Y, 0, 1e-3, `label {segment} sits on its slice's middle line`)
				expect.truthy(out.Y * up.Y + out.Z * up.Z > 3, `label {segment} out toward the rim`)
			elseif segment then
				slices[segment] = (slices[segment] or 0) + 1
			end
		end
		for index = 1, #Wheel.Prizes do
			expect.equal(slices[index], 2, `slice {index}`)
			expect.equal(labels[index], 1, `label {index}`)
		end
		expect.equal(slices[#Wheel.Prizes + 1], nil, "no extra slices")
	end,
}
