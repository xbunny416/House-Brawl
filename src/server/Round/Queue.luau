--!strict
--[[
	Queue — the lobby join pad (pure, so specs can check it). A player is on the pad when their character's root is
	over the pad's footprint, from the pad's bottom up to `height` studs above its top (jumping still counts).
	Their queue status (the QueueStatus player attribute) is In (counted for the next round), AFK (on the pad but
	AFK, so not counted) or Off.
]]
export type Status = "Off" | "In" | "AFK"

local Queue = {}

function Queue.contains(padCFrame: CFrame, padSize: Vector3, point: Vector3, height: number): boolean
	local localPoint = padCFrame:PointToObjectSpace(point)
	local halfY = padSize.Y / 2
	return math.abs(localPoint.X) <= padSize.X / 2
		and math.abs(localPoint.Z) <= padSize.Z / 2
		and localPoint.Y >= -halfY
		and localPoint.Y <= halfY + height
end

-- A player's queue status: only someone in the lobby (or watching after being knocked out of a Classic round) can
-- queue; AFK players on the pad are not counted.
function Queue.status(roundStatus: string, onPad: boolean, afk: boolean): Status
	local status: Status = "Off"
	if onPad and (roundStatus == "Lobby" or roundStatus == "Spectating") then
		status = if afk then "AFK" else "In"
	end
	return status
end

return Queue
