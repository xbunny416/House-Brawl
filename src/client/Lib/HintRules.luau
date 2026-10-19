--!strict
--[[
	HintRules — which small key hints the bottom edge shows (owner's fix list, 2026-10-19: "small light-grey key hints
	at the bottom of the UI, more when near something interactive"). Pure, so Lune specs test it; the lists come from
	Config.Controls.Hints. Touch shows none (its buttons carry their labels), nor does an open menu screen. Spectating
	(out of lives, or watching from the lobby) shows how to switch fighters; fighting or respawning the round's
	hints; the lobby its own, plus one per walk-up prompt in reach.
]]
export type Hint = { Actions: { string }, Key: string?, Text: string? } -- Key: a GameStrings key; Text: shown as is

export type Context = {
	Device: string, -- "KeyboardAndMouse" | "Gamepad" | "Touch"
	Status: string?, -- the local player's RoundStatus
	Watching: boolean, -- watching the round from the lobby
	MenuOpen: boolean,
	Prompts: { string }, -- action texts of the walk-up prompts in reach (already localized)
}

export type Lists = {
	Lobby: { { Actions: { string }, Key: string } },
	Round: { { Actions: { string }, Key: string } },
	Spectating: { { Actions: { string }, Key: string } },
	PromptAction: string,
}

local HintRules = {}

local function copy(list: { { Actions: { string }, Key: string } }): { Hint }
	local result: { Hint } = {}
	for _, hint in list do
		table.insert(result, { Actions = hint.Actions, Key = hint.Key })
	end
	return result
end

function HintRules.list(context: Context, lists: Lists): { Hint }
	if context.Device == "Touch" or context.MenuOpen then
		return {}
	elseif context.Status == "Spectating" or context.Watching then
		return copy(lists.Spectating)
	elseif context.Status == "Playing" or context.Status == "Respawning" then
		return copy(lists.Round)
	end
	local result = copy(lists.Lobby)
	for _, text in context.Prompts do
		table.insert(result, { Actions = { lists.PromptAction }, Text = text })
	end
	return result
end

return HintRules
