--!strict
-- Input bindings and camera. Names map to Enum.KeyCode / Enum.UserInputType at runtime. Bible §5.2.
type Bindings = { [string]: { string } }

type ControlsConfig = {
	Keyboard: Bindings,
	Gamepad: Bindings,
	Touch: { MinButtonSize: number },
	Camera: {
		MaxZoom: number,
		ShiftLockAllowed: boolean,
		ShakeMagnitude: number,
		ShakeDuration: number,
	},
}

local Controls: ControlsConfig = {
	Keyboard = {
		Attack = { "MouseButton1" },
		Shove = { "MouseButton2" },
		Grab = { "E" },
		Dash = { "Q", "LeftShift" },
		Scoreboard = { "Tab" },
		Menu = { "M" },
	},
	Gamepad = {
		Attack = { "ButtonX" },
		Shove = { "ButtonY" },
		Grab = { "ButtonB" },
		Dash = { "ButtonR1" },
		Scoreboard = { "ButtonSelect" },
		Menu = { "ButtonStart" },
	},
	Touch = { MinButtonSize = 64 }, -- pixels
	Camera = {
		MaxZoom = 30,
		ShiftLockAllowed = true,
		ShakeMagnitude = 0.6, -- studs, heavy hits only (can be turned off in Settings)
		ShakeDuration = 0.25,
	},
}

return Controls
