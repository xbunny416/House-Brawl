--!strict
--[[
	Input bindings, the mobile button arc and the camera. Bible §5.1–5.2.
	Binding names are Enum.KeyCode names, or Enum.UserInputType names for mouse buttons ("MouseButton1").
	Jump and movement stay on Roblox's default controls (Space / A / the touch jump button and thumbstick).
]]
type Bindings = { [string]: { string } }

export type TouchButton = {
	Action: string,
	Angle: number, -- degrees around the jump button's center: 90 = straight above, 180 = straight left
	Distance: number, -- gap from the jump button's edge to this button's edge, in base button sizes
	Scale: number, -- size relative to the base button size
}

export type Hint = { Actions: { string }, Key: string }

type ControlsConfig = {
	Actions: { string },
	Keyboard: Bindings,
	Gamepad: Bindings,
	Touch: {
		MinButtonSize: number,
		ButtonSize: number,
		MaxButtonSize: number,
		Gap: number,
		Layouts: { [string]: { TouchButton } },
	},
	Prompts: { Keyboard: string, Gamepad: string, MaxDistance: number },
	Hints: { Lobby: { Hint }, Round: { Hint }, Spectating: { Hint }, PromptAction: string },
	Camera: {
		MinZoom: number,
		MaxZoom: number,
		ShiftLockAllowed: boolean,
		ShiftLockKeys: { string },
		ShakeMagnitude: number,
		ShakeRotation: number,
		ShakeDuration: number,
		ShakeFrequency: number,
	},
}

local Controls: ControlsConfig = {
	-- Every action the game listens for. Each one needs a keyboard and a gamepad binding.
	Actions = { "Attack", "Ability", "Grab", "Dash", "Run", "Scoreboard", "Menu", "SpectatePrevious", "SpectateNext" },
	Keyboard = {
		Attack = { "MouseButton1" },
		-- Hold Attack to charge a punch. Right-click is left to Roblox's camera turn (owner, 2026-10-17: no Shove).
		Ability = { "F" }, -- the equipped style's move (Wrecker: parry)
		Grab = { "E" },
		Dash = { "Q" },
		Run = { "LeftShift" }, -- hold to run (stamina)
		Scoreboard = { "Tab" },
		Menu = { "M" },
		SpectatePrevious = { "Z" }, -- only while spectating (touch: the arrows on the spectate bar)
		SpectateNext = { "X" },
	},
	Gamepad = {
		Attack = { "ButtonX" },
		Ability = { "ButtonY" },
		Grab = { "ButtonB" },
		Dash = { "ButtonR1" },
		Run = { "ButtonL3" }, -- press the left stick: run until you stop moving (stamina)
		-- Not Select / Start: Roblox keeps those for its own menu and UI navigation (owner's choice, 2026-10-16).
		Scoreboard = { "DPadDown" },
		Menu = { "DPadUp" },
		SpectatePrevious = { "DPadLeft" },
		SpectateNext = { "DPadRight" },
	},
	Touch = {
		MinButtonSize = 64, -- pixels; no touch button is ever smaller
		ButtonSize = 0.17, -- base button size as a fraction of the screen's shorter side...
		MaxButtonSize = 104, -- ...capped in pixels so tablet buttons stay thumb-sized
		Gap = 0.15, -- minimum space between buttons, in base button sizes
		-- Bottom-right arc around Roblox's jump button. Settings > Button Layout picks one by name.
		Layouts = {
			Default = {
				{ Action = "Attack", Angle = 180, Distance = 0.2, Scale = 1.15 },
				{ Action = "Dash", Angle = 90, Distance = 0.2, Scale = 1 },
				{ Action = "Ability", Angle = 155, Distance = 1.35, Scale = 1 }, -- only shown for styles with one
				{ Action = "Grab", Angle = 115, Distance = 1.35, Scale = 1 },
				{ Action = "Run", Angle = 180, Distance = 2.5, Scale = 1 }, -- tap: run until you stop moving
			},
		},
	},
	-- Walk-up prompts in the lobby (bartender → Shop, locker booth → Locker): the keys are Grab's, which has nothing
	-- to grab in the lobby; touch taps the prompt. MaxDistance in studs.
	Prompts = { Keyboard = "E", Gamepad = "ButtonB", MaxDistance = 12 },
	-- Small light-grey key hints along the bottom edge (owner's fix list, 2026-10-19; keyboard and gamepad only, touch
	-- has its buttons): each shows its actions' keys and a GameStrings key, by where the player is (Client/Lib/HintRules).
	-- Near a walk-up prompt the lobby list adds "[key] <prompt text>"; PromptAction is the action whose keys prompts use.
	Hints = {
		Lobby = { { Actions = { "Run" }, Key = "Hint.Run" }, { Actions = { "Menu" }, Key = "Hint.Menu" } },
		Round = {
			{ Actions = { "Attack" }, Key = "Hint.Attack" },
			{ Actions = { "Scoreboard" }, Key = "Hint.Scoreboard" },
		},
		Spectating = {
			{ Actions = { "SpectatePrevious", "SpectateNext" }, Key = "Hint.Spectate" },
			{ Actions = { "Scoreboard" }, Key = "Hint.Scoreboard" },
		},
		PromptAction = "Grab",
	},
	Camera = {
		MinZoom = 8, -- studs; keeps the camera third-person (no first person)
		MaxZoom = 30,
		ShiftLockAllowed = true,
		-- Shift Lock toggle keys. Left Shift is left out because it is the Run key.
		ShiftLockKeys = { "RightShift" },
		ShakeMagnitude = 1, -- studs at full intensity, heavy hits only (can be turned off in Settings)
		ShakeRotation = 1.5, -- degrees of tilt at full intensity
		ShakeDuration = 0.35,
		ShakeFrequency = 18, -- wobbles per second
	},
}

return Controls
