--!strict
--[[
	AudioRules — which music plays and which sound effect a moment uses (pure, so Lune specs test it). Keys name
	entries of Config.Audio (Music.Arenas by map id, "Lobby"; Sfx by name).
]]
local AudioRules = {}

-- The hit sound of each style's weapon (Config.Styles.List[id].Weapon).
AudioRules.WeaponHits = {
	Fists = "Punch",
	BaseballBat = "BatHit",
	Shovel = "ShovelHit",
	WrenchAndHubcap = "WrenchHit",
}

local function inArena(roundStatus: string?): boolean
	return roundStatus == "Playing" or roundStatus == "Respawning" or roundStatus == "Spectating"
end

-- The music for this player: the arena's track (its map id) while they are in the running round (fighting,
-- respawning or watching), else the lobby's.
function AudioRules.musicFor(roundState: string?, roundStatus: string?, mapId: string?): string
	if roundState == "Playing" and inArena(roundStatus) and mapId then
		return mapId
	end
	return "Lobby"
end

-- The tension layer plays over the arena track in the last `tensionTime` seconds of a round the player is in.
function AudioRules.tensionOn(roundState: string?, roundStatus: string?, timeLeft: number, tensionTime: number): boolean
	return roundState == "Playing" and inArena(roundStatus) and timeLeft > 0 and timeLeft <= tensionTime
end

-- The sound of a landed hit: what hit (an attack, a parry or a thrown prop), the attacker's weapon, heavy or not.
function AudioRules.hitSound(attack: string, weapon: string?, heavy: boolean): string
	if attack == "Parry" then
		return "Parry"
	elseif attack ~= "Punch" and attack ~= "Charged" then
		return "PropHit"
	elseif heavy then
		return "ChargedHit"
	end
	return AudioRules.WeaponHits[weapon or "Fists"] or "Punch"
end

-- The smash of a structure breaking, from its material name.
function AudioRules.smashSound(material: string): string
	if material == "Glass" or material == "Ice" then
		return "SmashGlass"
	elseif string.find(material, "Wood") then
		return "SmashWood"
	end
	return "SmashMetal"
end

return AudioRules
