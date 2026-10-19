--!strict
-- Fighting styles (step 2.2): the style roll (owner's fix list, 2026-10-19: odds, pity, free / paid spins, slots),
-- the Wrecker parry, weapon models.
local Roblox = require("../roblox")
local roblox = require("@lune/roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local Formulas = Roblox.require(Shared.Formulas)
local StyleRules = Roblox.require(Shared.StyleRules)
local DataTemplate = Roblox.require(Shared.Data.Template)
local Fighter = Roblox.require(Roblox.game.ServerScriptService.Server.Combat.Fighter)

local Roll = Config.Styles.Roll
local DAY = 20000

local function isEnumItem(enum: any, name: string): boolean
	return (pcall(function()
		return enum[name]
	end))
end

-- A new player's styles (the data template's), as a fresh table.
local function slots(): any
	local template = DataTemplate.Template.Styles
	return {
		Slots = table.clone(template.Slots),
		Locked = table.clone(template.Locked),
		Active = template.Active,
		Equipped = template.Equipped,
		Pity = template.Pity,
		FreeSpinDay = template.FreeSpinDay,
	}
end

return {
	["styles match the bible and the owner's rarities"] = function()
		local styles = Config.Styles.List
		expect.equal(styles.Brawler.Rarity, "Common")
		expect.equal(styles.Slugger.Rarity, "Uncommon")
		expect.equal(styles.Scrapper.Rarity, "Rare")
		expect.equal(styles.Wrecker.Rarity, "Legendary")
		local slugger = Formulas.resolveAttack("Slugger", "Punch")
		expect.near(slugger.Damage, Config.Combat.Attacks.Punch.Damage * 1.15)
		expect.near(slugger.Cooldown, Config.Combat.Attacks.Punch.Cooldown / 0.8)
		expect.equal(slugger.Hitbox.Z, Config.Combat.Attacks.Punch.Hitbox.Z + 2)
		expect.equal(Formulas.resolveAttack("Scrapper", "Punch").Hitbox.X, 7)
		local ability = styles.Wrecker.Ability
		expect.truthy(ability and ability.Parry.Window == 0.2, "Wrecker parry window")
	end,
	["roll odds: add up to 100, every rarity has styles, the default style is never rolled"] = function()
		local total = 0
		for rarity, percent in Roll.Odds do
			expect.truthy(percent > 0, `{rarity} odds`)
			expect.truthy(Roll.RarityColors[rarity], `{rarity} color`)
			expect.truthy(table.find(Roll.RarityOrder, rarity), `{rarity} order`)
			total += percent
		end
		expect.near(total, 100)
		local styleTotal = 0
		for _, tier in StyleRules.tiers() do
			expect.truthy(#tier.Styles > 0, tier.Rarity)
			for _, styleId in tier.Styles do
				styleTotal += StyleRules.chance(styleId)
			end
		end
		expect.near(styleTotal, 100)
		expect.equal(StyleRules.chance(Config.Styles.Default), 0)
		expect.truthy(Roll.Odds[Roll.PityRarity], "the pity rarity can be rolled")
		for id, style in Config.Styles.List do
			expect.truthy(Roll.RarityColors[style.Rarity], `{id} rarity`)
		end
		expect.truthy(Roll.SpinPrice > 0 and Roll.PityAt > 1, "price and pity")
		expect.truthy(Roll.Slots.Start >= 1 and Roll.Slots.Max >= Roll.Slots.Start, "slots")
	end,
	["roll: spins land on each style as often as its odds say; a pity spin is always the pity rarity"] = function()
		local counts: { [string]: number } = {}
		local steps = 10000
		for index = 0, steps - 1 do
			local styleId = StyleRules.pick((index + 0.5) / steps, 0)
			counts[styleId] = (counts[styleId] or 0) + 1
		end
		for id in Config.Styles.List do
			expect.near((counts[id] or 0) / steps * 100, StyleRules.chance(id), 0.02, id)
		end
		for _, roll in { 0, 0.3, 0.99999 } do
			local styleId = StyleRules.pick(roll, Roll.PityAt - 1)
			expect.equal(Config.Styles.List[styleId].Rarity, Roll.PityRarity, `pity spin at {roll}`)
		end
		expect.equal(StyleRules.isPitySpin(Roll.PityAt - 2), false)
		expect.equal(StyleRules.isPitySpin(Roll.PityAt - 1), true)
		expect.equal(StyleRules.nextPity(10, "Slugger"), 11)
		expect.equal(StyleRules.nextPity(10, "Wrecker"), 0)
	end,
	["spin checks: fighting, locked slot, the daily free spin, private servers, paid spins"] = function()
		local styles = slots()
		local function check(kind: string, scrap: number, overrides: { [string]: boolean }?): string?
			local checks: { [string]: boolean } = { Fighting = false, PaidAllowed = true, FreeAllowed = true }
			for key, value in overrides or {} do
				checks[key] = value
			end
			return StyleRules.checkSpin(styles, kind, DAY, scrap, checks :: any)
		end
		expect.equal(check("Free", 0), nil)
		expect.equal(check("Free", 0, { Fighting = true }), "Fighting")
		expect.equal(check("Free", 0, { FreeAllowed = false }), "PrivateServer")
		expect.equal(check("Paid", Roll.SpinPrice), nil)
		expect.equal(check("Paid", Roll.SpinPrice - 1), "NotEnoughScrap")
		expect.equal(check("Paid", 1000000, { PaidAllowed = false }), "NotAllowed")
		expect.equal(check("Spin", 1000000), "TryAgain")
		styles.FreeSpinDay = DAY
		expect.equal(check("Free", 0), "NoFreeSpin")
		expect.equal(StyleRules.freeSpinReady(styles, DAY + 1), true, "back the next day")
		styles.Locked[1] = true
		expect.equal(check("Paid", 1000000), "SlotLocked")
	end,
	["a spin replaces the equipped slot; slots equip, lock and grow up to the maximum"] = function()
		local styles = slots()
		expect.equal(#styles.Slots, Roll.Slots.Start)
		expect.equal(styles.Equipped, Config.Styles.Default)
		StyleRules.applySpin(styles, "Free", DAY, "Scrapper")
		expect.equal(styles.Slots[1], "Scrapper")
		expect.equal(styles.Equipped, "Scrapper")
		expect.equal(styles.FreeSpinDay, DAY)
		expect.equal(styles.Pity, 1)
		StyleRules.applySpin(styles, "Paid", DAY + 3, "Wrecker")
		expect.equal(styles.FreeSpinDay, DAY, "a paid spin leaves the free spin alone")
		expect.equal(styles.Pity, 0)
		for _ = #styles.Slots + 1, Roll.Slots.Max do
			expect.equal(StyleRules.canAddSlot(styles), true)
			StyleRules.addSlot(styles)
		end
		expect.equal(#styles.Slots, Roll.Slots.Max)
		expect.equal(StyleRules.canAddSlot(styles), false)
		if Roll.Slots.Max >= 2 then
			expect.equal(styles.Slots[2], Config.Styles.Default)
			StyleRules.equipSlot(styles, 2)
			expect.equal(styles.Equipped, Config.Styles.Default)
			StyleRules.applySpin(styles, "Paid", DAY, "Slugger")
			expect.equal(styles.Slots[1], "Wrecker", "only the equipped slot changes")
		end
		expect.equal(StyleRules.isSlot(styles, 0), false)
		expect.equal(StyleRules.isSlot(styles, Roll.Slots.Max + 1), false)
		styles.Slots[styles.Active] = "Gone"
		expect.equal(StyleRules.equipped(styles), Config.Styles.Default, "an unknown style falls back")
	end,
	["odds read like the reference: whole numbers plain, up to 3 decimals"] = function()
		expect.equal(StyleRules.formatPercent(70), "70")
		expect.equal(StyleRules.formatPercent(2.5), "2.5")
		expect.equal(StyleRules.formatPercent(0.015), "0.015")
		expect.equal(StyleRules.formatPercent(100 / 3), "33.333")
	end,
	["parry: a 0.2 s window turns melee hits back; it has its own cooldown"] = function()
		local f = Fighter.new("Classic")
		local cooldown = (Config.Styles.List.Wrecker.Ability :: any).Cooldown
		local charged = Fighter.new("Classic")
		Fighter.startCharge(charged, 0)
		Fighter.releaseCharge(charged, Config.Combat.Attacks.Charged.Cooldown, 0.1)
		expect.equal(Fighter.parry(charged, 0.2, 0.2, cooldown), true, "a charged punch's cooldown does not block it")
		expect.equal(Fighter.parry(f, 0, 0.2, cooldown), true)
		expect.equal(Fighter.evade(f, 0.1, true), "Parried")
		expect.equal(Fighter.evade(f, 0.1, false), "None", "props and blasts are not parried")
		expect.equal(Fighter.evade(f, 0.21, true), "None", "window over")
		expect.equal(Fighter.parry(f, cooldown - 0.01, 0.2, cooldown), false, "cooldown")
		expect.equal(Fighter.parry(f, cooldown, 0.2, cooldown), true)
		local stunned = Fighter.new("Classic")
		local result = Fighter.takeHit(stunned, {
			Damage = 8,
			Percent = 6,
			KnockbackScale = 1,
			Multiplier = 1,
		}, "a", 0)
		expect.equal(Fighter.parry(stunned, result.Hitstun / 2, 0.2, cooldown), false, "no parry in hitstun")
	end,
	["a zero-damage reflected blow still knocks back from the current Percent"] = function()
		local f = Fighter.new("Classic")
		f.Health = 60
		f.Percent = 60
		local result = Fighter.takeHit(f, { Damage = 0, Percent = 0, KnockbackScale = 1.6, Multiplier = 1 }, "p", 0)
		expect.equal(f.Health, 60)
		expect.near(result.Force, Formulas.knockbackForce(60, 1.6, "Classic"))
	end,
	["every style's weapon has a valid blockout model (fists have none)"] = function()
		for id, style in Config.Styles.List do
			local parts = Config.Styles.Weapons[style.Weapon]
			if style.Weapon == "Fists" then
				expect.equal(parts, nil, `{id} fists`)
			else
				expect.truthy(parts and #parts > 0, `{id} weapon {style.Weapon}`)
				for _, part in parts do
					expect.truthy(part.Attach == "RightHand" or part.Attach == "LeftHand", `{part.Name} hand`)
					expect.truthy(isEnumItem(roblox.Enum.Material, part.Material), `{part.Name} material`)
					expect.truthy(isEnumItem(roblox.Enum.PartType, part.Shape or "Block"), `{part.Name} shape`)
					expect.equal(#part.Offset, 3, `{part.Name} offset`)
				end
			end
		end
	end,
}
