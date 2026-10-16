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

type ControlsConfig = {
	Actions: { string },
	Keyboard: Bindings,
	Gamepad: Bindings,
	ShoveDragCancel: number?,
	Touch: {
		MinButtonSize: number,
		ButtonSize: number,
		MaxButtonSize: number,
		Gap: number,
		Layouts: { [string]: { TouchButton } },
	},
	Camera: {
		MinZoom: number,
		MaxZoom: number,
		ShiftLockAllowed: boolean,
		ShiftLockKeys: { string },
		ShakeMagnitude: number,
		ShakeDuration: number,
		ShakeFrequency: number,
	},
}

local Controls: ControlsConfig = {
	-- Every action the game listens for. Each one needs a keyboard and a gamepad binding.
	Actions = { "Attack", "Shove", "Grab", "Dash", "Scoreboard", "Menu", "SpectatePrevious", "SpectateNext" },
	Keyboard = {
		Attack = { "MouseButton1" },
		Shove = { "MouseButton2" },
		Grab = { "E" },
		Dash = { "Q", "LeftShift" },
		Scoreboard = { "Tab" },
		Menu = { "M" },
		SpectatePrevious = { "Z" }, -- only while spectating (touch: the arrows on the spectate bar)
		SpectateNext = { "X" },
	},
	Gamepad = {
		Attack = { "ButtonX" },
		Shove = { "ButtonY" },
		Grab = { "ButtonB" },
		Dash = { "ButtonR1" },
		-- Not Select / Start: Roblox keeps those for its own menu and UI navigation (owner's choice, 2026-10-16).
		Scoreboard = { "DPadDown" },
		Menu = { "DPadUp" },
		SpectatePrevious = { "DPadLeft" },
		SpectateNext = { "DPadRight" },
	},
	-- Right-click is also Roblox's drag-to-turn-the-camera button: dragging the mouse this many pixels while a
	-- right-click Shove is charging cancels the Shove (it was a camera turn). nil keeps the Shove.
	ShoveDragCancel = 12,
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
				{ Action = "Shove", Angle = 155, Distance = 1.35, Scale = 1 },
				{ Action = "Grab", Angle = 115, Distance = 1.35, Scale = 1 },
			},
		},
	},
	Camera = {
		MinZoom = 8, -- studs; keeps the camera third-person (no first person)
		MaxZoom = 30,
		ShiftLockAllowed = true,
		-- Shift Lock toggle keys. Left Shift is left out because it is a Dash key.
		ShiftLockKeys = { "RightShift" },
		ShakeMagnitude = 0.6, -- studs at full intensity, heavy hits only (can be turned off in Settings)
		ShakeDuration = 0.25,
		ShakeFrequency = 18, -- wobbles per second
	},
}

return Controls
