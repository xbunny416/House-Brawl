--!strict
-- Action map, mobile button layout, camera shake, control bindings and settings validation (step 1.5).
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local csv = require("../../tools/csv")
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Lib = Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib
local Config = Roblox.require(Shared.Config)
local Settings = Roblox.require(Shared.Settings)
local ActionMap = Roblox.require(Lib.ActionMap)
local TouchLayout = Roblox.require(Lib.TouchLayout)
local CameraShake = Roblox.require(Lib.CameraShake)
local DashRules = Roblox.require(Lib.DashRules)

local Controls = Config.Controls

-- Landscape phones and tablets (Roblox's default orientation), plus a portrait phone.
local SCREENS = {
	{ 640, 360 },
	{ 667, 375 },
	{ 844, 390 },
	{ 932, 430 },
	{ 1024, 768 },
	{ 1194, 834 },
	{ 1366, 1024 },
	{ 375, 667 },
}

local function isEnumItem(enum: any, name: string): boolean
	return (pcall(function()
		return enum[name]
	end))
end

local function isBindable(name: string): boolean
	if string.sub(name, 1, 11) == "MouseButton" then
		return isEnumItem(roblox.Enum.UserInputType, name)
	end
	return isEnumItem(roblox.Enum.KeyCode, name)
end

local function distance(ax: number, ay: number, bx: number, by: number): number
	return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end

return {
	-- ActionMap -------------------------------------------------------------------------------------------------------
	["lookup merges keyboard and gamepad bindings"] = function()
		local lookup = ActionMap.lookup(Controls.Keyboard, Controls.Gamepad)
		expect.equal(lookup.Q[1], "Dash")
		expect.equal(lookup.LeftShift[1], "Dash")
		expect.equal(lookup.ButtonR1[1], "Dash")
		expect.equal(lookup.MouseButton1[1], "Attack")
		expect.equal(lookup.ButtonX[1], "Attack")
		expect.equal(lookup.Space, nil)
	end,
	["input names: KeyCode for keys and gamepads, UserInputType for mouse buttons"] = function()
		expect.equal(ActionMap.inputName("Keyboard", "Q"), "Q")
		expect.equal(ActionMap.inputName("Gamepad1", "ButtonX"), "ButtonX")
		expect.equal(ActionMap.inputName("MouseButton2", "Unknown"), "MouseButton2")
		expect.equal(ActionMap.inputName("MouseMovement", "Unknown"), nil)
		expect.equal(ActionMap.inputName("Touch", "Unknown"), nil)
		expect.equal(ActionMap.inputName("Keyboard", "Unknown"), nil)
	end,
	["preferred input maps to a device"] = function()
		expect.equal(ActionMap.device("KeyboardAndMouse"), "KeyboardAndMouse")
		expect.equal(ActionMap.device("Gamepad"), "Gamepad")
		expect.equal(ActionMap.device("MicroGamepad"), "Gamepad")
		expect.equal(ActionMap.device("Touch"), "Touch")
	end,
	["an action held by two inputs begins once and ends with the last release"] = function()
		local tracker = ActionMap.newTracker()
		expect.equal(tracker.press("Q", "Dash"), true)
		expect.equal(tracker.press("LeftShift", "Dash"), false)
		expect.equal(tracker.isDown("Dash"), true)
		expect.equal(tracker.release("Q", "Dash"), false)
		expect.equal(tracker.isDown("Dash"), true)
		expect.equal(tracker.release("LeftShift", "Dash"), true)
		expect.equal(tracker.isDown("Dash"), false)
		expect.equal(tracker.release("LeftShift", "Dash"), false, "double release")
		expect.equal(tracker.release("E", "Grab"), false, "release without press")
	end,
	["releaseAll ends every held action once"] = function()
		local tracker = ActionMap.newTracker()
		tracker.press("MouseButton2", "Shove")
		tracker.press("Touch.Dash", "Dash")
		tracker.press("Q", "Dash")
		local ended = tracker.releaseAll()
		expect.equal(table.concat(ended, ","), "Dash,Shove")
		expect.equal(tracker.isDown("Shove"), false)
		expect.equal(tracker.release("Q", "Dash"), false, "key released after focus loss")
		expect.equal(tracker.press("Q", "Dash"), true, "can begin again")
	end,

	-- Bindings ----------------------------------------------------------------------------------------------------------
	["every action has a keyboard and a gamepad binding, and every binding is a known action"] = function()
		local known: { [string]: boolean } = {}
		for _, action in Controls.Actions do
			known[action] = true
			expect.truthy(Controls.Keyboard[action] and #Controls.Keyboard[action] > 0, `{action} keyboard`)
			expect.truthy(Controls.Gamepad[action] and #Controls.Gamepad[action] > 0, `{action} gamepad`)
		end
		for _, bindings in { Controls.Keyboard, Controls.Gamepad } do
			for action in bindings do
				expect.truthy(known[action], `{action} is not in Controls.Actions`)
			end
		end
	end,
	["every binding names a real KeyCode or mouse button, used by one action only"] = function()
		for _, bindings in { Controls.Keyboard, Controls.Gamepad } do
			local owner: { [string]: string } = {}
			for action, inputs in bindings do
				for _, input in inputs do
					expect.truthy(isBindable(input), `{action}: unknown input {input}`)
					expect.equal(owner[input], nil, `{input} bound twice`)
					owner[input] = action
				end
			end
		end
	end,
	["shift lock keys are real keys and never steal an action key (Left Shift is Dash)"] = function()
		local lookup = ActionMap.lookup(Controls.Keyboard)
		expect.truthy(#Controls.Camera.ShiftLockKeys > 0, "at least one Shift Lock key")
		for _, key in Controls.Camera.ShiftLockKeys do
			expect.truthy(isEnumItem(roblox.Enum.KeyCode, key), `Shift Lock key {key}`)
			expect.equal(lookup[key], nil, `{key} is both Shift Lock and an action`)
		end
		expect.equal(lookup.LeftShift[1], "Dash")
	end,
	["studio debug keys are real keys and never steal an action key"] = function()
		local lookup = ActionMap.lookup(Controls.Keyboard)
		for name, key in Config.Dev.StudioKeys do
			expect.truthy(isEnumItem(roblox.Enum.KeyCode, key), `{name} key {key}`)
			expect.equal(lookup[key], nil, `{name} uses action key {key}`)
		end
	end,
	["camera limits: third person and max zoom 30"] = function()
		expect.equal(Controls.Camera.MaxZoom, 30)
		expect.truthy(Controls.Camera.MinZoom > 0.5 and Controls.Camera.MinZoom < Controls.Camera.MaxZoom, "MinZoom")
	end,
	["every action has a label string"] = function()
		local rows = csv.parse(fs.readFile("src/localization/GameStrings.csv"))
		local keys: { [string]: boolean } = {}
		for index = 2, #rows do
			keys[rows[index][1]] = true
		end
		for _, action in Controls.Actions do
			expect.truthy(keys[`Controls.{action}`], `Controls.{action}`)
		end
	end,

	-- Touch layout ----------------------------------------------------------------------------------------------------
	["touch layouts place known actions, each once, with a gap from the jump button"] = function()
		for name, layout in Controls.Touch.Layouts do
			local seen: { [string]: boolean } = {}
			for _, button in layout do
				expect.truthy(table.find(Controls.Actions, button.Action), `{name}: unknown action {button.Action}`)
				expect.equal(seen[button.Action], nil, `{name}: {button.Action} twice`)
				seen[button.Action] = true
				expect.truthy(button.Distance >= Controls.Touch.Gap, `{name}: {button.Action} touches the jump button`)
				expect.truthy(button.Scale >= 1, `{name}: {button.Action} smaller than the base size`)
			end
			for _, action in { "Attack", "Shove", "Grab", "Dash" } do
				expect.truthy(seen[action], `{name}: no {action} button (bible §5.1 arc)`)
			end
		end
	end,
	["touch buttons are at least 64 px, on screen and never overlap (all screen sizes)"] = function()
		expect.truthy(Controls.Touch.MinButtonSize >= 64, "bible: touch targets >= 64 px")
		for _, screen in SCREENS do
			local width, height = screen[1], screen[2]
			local jump = TouchLayout.defaultJump(width, height)
			for name, layout in Controls.Touch.Layouts do
				local label = `{name} @ {width}x{height}`
				local placed = TouchLayout.place(width, height, jump, layout, Controls.Touch)
				local gap = TouchLayout.buttonSize(width, height, Controls.Touch) * Controls.Touch.Gap
				expect.equal(#placed, #layout, label)
				for index, a in placed do
					local radius = a.Size / 2
					expect.truthy(a.Size >= Controls.Touch.MinButtonSize, `{label}: {a.Action} size {a.Size}`)
					expect.truthy(
						a.X - radius >= 0 and a.X + radius <= width and a.Y - radius >= 0 and a.Y + radius <= height,
						`{label}: {a.Action} off screen`
					)
					expect.truthy(
						distance(a.X, a.Y, jump.X, jump.Y) >= radius + jump.Radius + gap - 1e-6,
						`{label}: {a.Action} overlaps the jump button`
					)
					for other = index + 1, #placed do
						local b = placed[other]
						expect.truthy(
							distance(a.X, a.Y, b.X, b.Y) >= radius + b.Size / 2 + gap - 1e-6,
							`{label}: {a.Action} overlaps {b.Action}`
						)
					end
				end
			end
		end
	end,
	["button size scales with the screen between the min and max"] = function()
		local touch = Controls.Touch
		expect.equal(TouchLayout.buttonSize(320, 240, touch), touch.MinButtonSize)
		expect.equal(TouchLayout.buttonSize(2560, 1440, touch), touch.MaxButtonSize)
		local mid = TouchLayout.buttonSize(1024, 500, touch)
		expect.near(mid, 500 * touch.ButtonSize, 1e-9)
	end,
	["default jump button matches Roblox's small and large layouts"] = function()
		local small = TouchLayout.defaultJump(844, 390)
		expect.equal(small.Radius, 35)
		expect.equal(small.X, 844 - 60)
		local large = TouchLayout.defaultJump(1024, 768)
		expect.equal(large.Radius, 60)
		expect.equal(large.Y, 768 - 150)
	end,

	-- Camera shake ----------------------------------------------------------------------------------------------------
	["shake stays within the magnitude and stops after the duration"] = function()
		local magnitude, duration, frequency = 0.6, 0.25, 18
		local moved = false
		for step = 0, 99 do
			local elapsed = step * duration / 100
			local x, y = CameraShake.offset(elapsed, duration, magnitude, frequency, 12.5)
			expect.truthy(math.abs(x) <= magnitude and math.abs(y) <= magnitude, `bounded at {elapsed}`)
			moved = moved or x ~= 0 or y ~= 0
		end
		expect.truthy(moved, "shake moves the camera")
		local x, y = CameraShake.offset(duration, duration, magnitude, frequency, 12.5)
		expect.equal(x, 0)
		expect.equal(y, 0)
		x, y = CameraShake.offset(0.1, duration, 0, frequency, 12.5)
		expect.equal(x + y, 0, "zero magnitude")
	end,
	["shake fades out"] = function()
		local early, late = 0, 0
		for seed = 1, 50 do
			local ex, ey = CameraShake.offset(0.02, 0.25, 0.6, 18, seed + 0.5)
			local lx, ly = CameraShake.offset(0.22, 0.25, 0.6, 18, seed + 0.5)
			early += math.abs(ex) + math.abs(ey)
			late += math.abs(lx) + math.abs(ly)
		end
		expect.truthy(late < early, "later frames shake less")
	end,

	-- Dash ------------------------------------------------------------------------------------------------------------
	["dash: cooldown between dashes; ground dashes do not use the air dash"] = function()
		local dash = Config.Combat.Dash
		local state = DashRules.new()
		expect.equal(DashRules.tryDash(state, 0, false, dash), true)
		expect.equal(DashRules.tryDash(state, dash.Cooldown - 0.01, false, dash), false, "cooldown")
		expect.near(DashRules.cooldownLeft(state, 1), dash.Cooldown - 1)
		expect.equal(DashRules.tryDash(state, dash.Cooldown, true, dash), true, "air dash still available")
		expect.equal(DashRules.cooldownLeft(state, 100), 0)
	end,
	["dash: once per stay in the air, again after landing"] = function()
		local dash = Config.Combat.Dash
		local state = DashRules.new()
		expect.equal(DashRules.tryDash(state, 0, true, dash), true)
		expect.equal(DashRules.tryDash(state, 10, true, dash), false, "second air dash before landing")
		DashRules.landed(state)
		expect.equal(DashRules.tryDash(state, 10, true, dash), true)
	end,
	["dash speed covers 18 studs in 0.25 s"] = function()
		local Formulas = Roblox.require(Shared.Formulas)
		expect.near(Formulas.dashSpeed() * Config.Combat.Dash.Duration, 18)
	end,

	-- Settings --------------------------------------------------------------------------------------------------------
	["default settings are all valid"] = function()
		for key, value in Config.Data.DefaultSettings :: { [string]: any } do
			expect.truthy(Settings.isValid(key, value), `default {key}`)
		end
	end,
	["settings reject unknown keys, wrong types and out-of-range values"] = function()
		expect.equal(Settings.isValid("CameraShake", false), true)
		expect.equal(Settings.isValid("CameraShake", 0), false)
		expect.equal(Settings.isValid("MusicVolume", 0.3), true)
		expect.equal(Settings.isValid("MusicVolume", 1.5), false)
		expect.equal(Settings.isValid("MusicVolume", 0 / 0), false)
		expect.equal(Settings.isValid("MusicVolume", "loud"), false)
		expect.equal(Settings.isValid("ButtonLayout", "Default"), true)
		expect.equal(Settings.isValid("ButtonLayout", "NoSuchLayout"), false)
		expect.equal(Settings.isValid("Scrap", 1000000), false)
		expect.equal(Settings.isValid("__index", true), false)
	end,
	["every numeric setting has a range"] = function()
		for key, value in Config.Data.DefaultSettings :: { [string]: any } do
			if type(value) == "number" then
				local range = (Config.Data.SettingRanges :: any)[key]
				expect.truthy(range and range.Min <= value and value <= range.Max, `{key} range`)
			end
		end
	end,
}
