--!strict
--[[
	TouchLayout — places the mobile action buttons in an arc around Roblox's jump button (bottom-right).
	Pure math in screen pixels (x right, y down), so Lune specs can check every screen size: buttons never shrink
	below Config.Controls.Touch.MinButtonSize, never overlap each other or the jump button, and stay on screen.
]]
export type Circle = { X: number, Y: number, Radius: number }

export type ButtonSpec = {
	Action: string,
	Angle: number,
	Distance: number,
	Scale: number,
}

export type TouchConfig = {
	MinButtonSize: number,
	ButtonSize: number,
	MaxButtonSize: number,
	Gap: number,
}

-- Center (X, Y) and diameter of one button.
export type Placement = { Action: string, X: number, Y: number, Size: number }

local TouchLayout = {}

-- Base button diameter: a fraction of the screen's shorter side, between MinButtonSize and MaxButtonSize.
function TouchLayout.buttonSize(width: number, height: number, touch: TouchConfig): number
	local size = math.min(width, height) * touch.ButtonSize
	return math.clamp(size, touch.MinButtonSize, math.max(touch.MinButtonSize, touch.MaxButtonSize))
end

-- Where the default PlayerModule (TouchJump) puts the jump button on a screen of this size. Used only until the
-- real button is found in PlayerGui.TouchGui.
function TouchLayout.defaultJump(width: number, height: number): Circle
	if math.min(width, height) <= 500 then
		return { X = width - 60, Y = height - 55, Radius = 35 } -- 70 px button
	end
	return { X = width - 110, Y = height - 150, Radius = 60 } -- 120 px button
end

-- Centers and sizes for `buttons` around `jump`, pulled back inside the screen if needed.
function TouchLayout.place(
	width: number,
	height: number,
	jump: Circle,
	buttons: { ButtonSpec },
	touch: TouchConfig
): { Placement }
	local base = TouchLayout.buttonSize(width, height, touch)
	local margin = base * touch.Gap
	local placements: { Placement } = {}
	for _, spec in buttons do
		local size = math.max(base * spec.Scale, touch.MinButtonSize)
		local radius = size / 2
		local distance = jump.Radius + spec.Distance * base + radius
		local angle = math.rad(spec.Angle)
		local x = jump.X + math.cos(angle) * distance
		local y = jump.Y - math.sin(angle) * distance
		table.insert(placements, {
			Action = spec.Action,
			X = math.clamp(x, radius + margin, math.max(radius + margin, width - radius - margin)),
			Y = math.clamp(y, radius + margin, math.max(radius + margin, height - radius - margin)),
			Size = size,
		})
	end
	return placements
end

return TouchLayout
