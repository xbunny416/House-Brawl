--!strict
-- Fighting styles (step 2.2): unlocks by level, ownership, the Wrecker parry, weapon models.
local Roblox = require("../roblox")
local roblox = require("@lune/roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local Formulas = Roblox.require(Shared.Formulas)
local StyleRules = Roblox.require(Shared.StyleRules)
local Fighter = Roblox.require(Roblox.game.ServerScriptService.Server.Combat.Fighter)

local function isEnumItem(enum: any, name: string): boolean
	return (pcall(function()
		return enum[name]
	end))
end

return {
	["styles match the bible: unlock levels, prices, changes"] = function()
		local styles = Config.Styles.List
		expect.equal(styles.Slugger.UnlockLevel, 5)
		expect.equal(styles.Slugger.Price, 1500)
		expect.equal(styles.Scrapper.UnlockLevel, 12)
		expect.equal(styles.Wrecker.UnlockLevel, 25)
		local slugger = Formulas.resolveAttack("Slugger", "Punch")
		expect.near(slugger.Damage, Config.Combat.Attacks.Punch.Damage * 1.15)
		expect.near(slugger.Cooldown, Config.Combat.Attacks.Punch.Cooldown / 0.8)
		expect.equal(slugger.Hitbox.Z, Config.Combat.Attacks.Punch.Hitbox.Z + 2)
		expect.equal(Formulas.resolveAttack("Scrapper", "Punch").Hitbox.X, 7)
		local parry = Formulas.resolveAttack("Wrecker", "Shove").Parry
		expect.truthy(parry and parry.Window == 0.2, "Wrecker parry window")
	end,
	["styles unlock by level; the default is always owned"] = function()
		expect.equal(table.concat(StyleRules.unlockedAt(1), ","), "Brawler")
		expect.equal(table.concat(StyleRules.unlockedAt(12), ","), "Brawler,Slugger,Scrapper")
		expect.equal(#StyleRules.unlockedAt(100), #Config.Styles.Order)
		expect.equal(StyleRules.owns({}, "Brawler"), true)
		expect.equal(StyleRules.owns({}, "Wrecker"), false)
		expect.equal(StyleRules.owns({ Wrecker = true }, "Wrecker"), true)
	end,
	["parry: a 0.2 s window turns melee hits back; shares the Shove cooldown"] = function()
		local f = Fighter.new("Classic")
		local cooldown = Config.Combat.Attacks.Shove.Cooldown
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
					expect.truthy(part.Hand == "Right" or part.Hand == "Left", `{part.Name} hand`)
					expect.truthy(isEnumItem(roblox.Enum.Material, part.Material), `{part.Name} material`)
					expect.truthy(isEnumItem(roblox.Enum.PartType, part.Shape or "Block"), `{part.Name} shape`)
					expect.equal(#part.Offset, 3, `{part.Name} offset`)
				end
			end
		end
	end,
}
