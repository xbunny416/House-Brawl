--!strict
-- Structural checks on Config so a balance edit cannot silently break the game.
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)

local function isHex(color: string): boolean
	return string.match(color, "^#%x%x%x%x%x%x$") ~= nil
end

return {
	["config is frozen"] = function()
		expect.equal(table.isfrozen(Config), true)
		expect.equal(table.isfrozen(Config.Combat.Attacks.Punch.Hitbox), true)
		expect.equal(
			pcall(function()
				Config.Combat.Knockback.Base = 1
			end),
			false
		)
	end,
	["default style and mode exist"] = function()
		expect.truthy(Config.Styles.List[Config.Styles.Default], "default style")
		expect.truthy(Config.Modes.List[Config.Modes.Default], "default mode")
	end,
	["style order lists every style exactly once"] = function()
		local seen = {}
		for _, id in Config.Styles.Order do
			expect.truthy(Config.Styles.List[id], `style {id}`)
			expect.equal(seen[id], nil, `duplicate {id}`)
			seen[id] = true
		end
		for id in Config.Styles.List do
			expect.truthy(seen[id], `{id} missing from Order`)
		end
	end,
	["styles are side-grades with positive multipliers"] = function()
		for id, style in Config.Styles.List do
			expect.truthy(style.AttackSpeed > 0, `{id} AttackSpeed`)
			for _, attack in { style.Punch, style.Shove } do
				expect.truthy(attack.DamageMultiplier > 0 and attack.DamageMultiplier <= 1.25, `{id} damage`)
				expect.truthy(attack.KnockbackMultiplier > 0 and attack.KnockbackMultiplier <= 1.25, `{id} KB`)
			end
		end
	end,
	["every mode has the fields its rules need"] = function()
		local classic = Config.Modes.List.Classic
		expect.truthy(classic.MaxHealth and classic.Lives and classic.HealthToPercent, "classic fields")
		local casual = Config.Modes.List.Casual
		expect.truthy(casual.PercentCap and casual.PassiveGainAmount and casual.PassiveGainInterval, "casual fields")
	end,
	["prop types reference real classes and valid colors"] = function()
		for id, prop in Config.Props.Types do
			expect.truthy(Config.Props.Classes[prop.Class], `{id} class`)
			expect.truthy(isHex(prop.Color), `{id} color`)
		end
		for _, id in Config.Props.LooseSpotTypes do
			expect.truthy(Config.Props.Types[id], `loose spot type {id}`)
		end
		local explosive = Config.Props.Classes.Explosive
		expect.truthy(explosive.Radius and explosive.FuseTime, "explosive radius + fuse")
	end,
	["structure drops reference real props"] = function()
		for id, structure in Config.Structures.Types do
			expect.truthy(structure.MinDrops >= 1 and structure.MinDrops <= structure.MaxDrops, `{id} drop range`)
			for _, propId in structure.DropTable do
				expect.truthy(Config.Props.Types[propId], `{id} drops {propId}`)
			end
		end
	end,
	["ranks ascend and start at level 1"] = function()
		local ranks = Config.Progression.Ranks
		expect.equal(ranks[1].Level, 1)
		for i = 2, #ranks do
			expect.truthy(ranks[i].Level > ranks[i - 1].Level, `rank {i} order`)
		end
		expect.truthy(ranks[#ranks].Level <= Config.Progression.LevelCap, "last rank within cap")
	end,
	["crumble always leaves the central platform plus one more"] = function()
		expect.truthy(Config.Round.Crumble.MinPlatformsRemaining >= 2)
		expect.truthy(Config.Round.Crumble.StartTime < Config.Round.RoundTime)
	end,
	["rotation only references known maps and at least one is enabled"] = function()
		local enabled = 0
		for _, id in Config.Maps.Rotation do
			local map = Config.Maps.List[id]
			expect.truthy(map, `map {id}`)
			if map.Enabled then
				enabled += 1
			end
		end
		expect.truthy(enabled >= 1, "enabled maps")
	end,
	["daily quest rewards are within 75-150 Scrap"] = function()
		for _, quest in Config.Retention.Quests.Daily do
			expect.truthy(quest.Scrap >= 75 and quest.Scrap <= 150, `{quest.Id} reward`)
		end
		expect.truthy(#Config.Retention.Quests.Daily >= Config.Retention.Quests.DailyCount, "quest pool size")
	end,
	["scrap packs grant what the bible says"] = function()
		local products = Config.Monetization.Products
		expect.equal(products.ScrapPackS.Scrap, 500)
		expect.equal(products.ScrapPackM.Scrap, 2000)
		expect.equal(products.ScrapPackL.Scrap, 6000)
	end,
}
