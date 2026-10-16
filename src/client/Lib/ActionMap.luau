--!strict
--[[
	ActionMap — pure logic behind InputController: which input triggers which action, and when an action that
	several inputs can hold (Q and Left Shift, a key and a touch button) begins and ends.
	No Roblox instances are used, so Lune specs can test it.
]]
export type Device = "KeyboardAndMouse" | "Gamepad" | "Touch"

-- Input name -> the actions it triggers.
export type Lookup = { [string]: { string } }

export type Tracker = {
	-- Marks `source` as holding `action`. True if the action just began (no other source was holding it).
	press: (source: string, action: string) -> boolean,
	-- Releases `source` from `action`. True if the action just ended (no source holds it any more).
	release: (source: string, action: string) -> boolean,
	-- Releases everything (e.g. the window lost focus). Returns the actions that ended.
	releaseAll: () -> { string },
	isDown: (action: string) -> boolean,
}

local ActionMap = {}

-- Merges binding tables (action -> input names) into one input name -> actions lookup.
function ActionMap.lookup(...: { [string]: { string } }): Lookup
	local lookup: Lookup = {}
	for _, bindings in { ... } do
		for action, inputs in bindings do
			for _, input in inputs do
				local actions = lookup[input]
				if actions == nil then
					actions = {}
					lookup[input] = actions
				end
				if not table.find(actions, action) then
					table.insert(actions, action)
				end
			end
		end
	end
	return lookup
end

-- The binding name for an input: KeyCode names for keyboard keys and gamepad buttons, UserInputType names for mouse
-- buttons. nil for inputs that cannot be bound (mouse movement, touches, thumbsticks without a KeyCode).
function ActionMap.inputName(userInputType: string, keyCode: string): string?
	if userInputType == "Keyboard" or string.sub(userInputType, 1, 7) == "Gamepad" then
		return if keyCode ~= "Unknown" then keyCode else nil
	elseif string.sub(userInputType, 1, 11) == "MouseButton" then
		return userInputType
	end
	return nil
end

-- The device a UserInputService.PreferredInput name stands for (micro gamepads such as TV remotes count as gamepads).
function ActionMap.device(preferredInput: string): Device
	if preferredInput == "Touch" then
		return "Touch"
	elseif preferredInput == "Gamepad" or preferredInput == "MicroGamepad" then
		return "Gamepad"
	end
	return "KeyboardAndMouse"
end

function ActionMap.newTracker(): Tracker
	local held: { [string]: { [string]: boolean } } = {}

	local function isDown(action: string): boolean
		return held[action] ~= nil
	end

	local function press(source: string, action: string): boolean
		local sources = held[action]
		if sources == nil then
			held[action] = { [source] = true }
			return true
		end
		sources[source] = true
		return false
	end

	local function release(source: string, action: string): boolean
		local sources = held[action]
		if sources == nil or not sources[source] then
			return false
		end
		sources[source] = nil
		if next(sources) == nil then
			held[action] = nil
			return true
		end
		return false
	end

	local function releaseAll(): { string }
		local ended: { string } = {}
		for action in held do
			table.insert(ended, action)
		end
		table.clear(held)
		table.sort(ended)
		return ended
	end

	return {
		press = press,
		release = release,
		releaseAll = releaseAll,
		isDown = isDown,
	}
end

return ActionMap
