--!strict
--[[
	Art — the pictures on Shinjuku's billboards, murals and posters (owner, 2026-10-30: "still looks plain/blocky").
	Made with ForgeGUI as made-up art with no words in it (the billboards' headlines stay GameStrings keys over them)
	and uploaded as Images to the owner's Roblox account, each 1024 × 572.

	A view is the part of an image a board shows: `Focus` is the x it centres on, `Left` / `Right` / `Top` / `Bottom`
	the area it may use (default the whole image), `Anchor` "Top" keeps a view's top edge (where its headline goes),
	`Headline` the share of the board's height the headline band takes.
]]
local Art = {}

Art.Width = 1024
Art.Height = 572

-- Roblox image asset ids (rbxassetid://).
Art.Images = {
	Cola = 137572009283976, -- a can in purple flames over manga speed lines; a calm dark-red top band
	Night = 140631213348036, -- a neon skyline under a crescent moon (left), light trails
	Ramen = 120715667336226, -- drawn as a billboard in a street: only its inner panel (an empty top band, an oni over
	-- a bowl) is used
	Wave = 98725250257464, -- a woodblock wave with two koi, graffiti drips
	Tiger = 117822648679885, -- a tiger and an oni mask in graffiti on brick (tags at the sides)
}

export type View = {
	Image: string,
	Focus: number,
	Left: number?,
	Right: number?,
	Top: number?,
	Bottom: number?,
	Anchor: string?,
	Headline: number?,
}

Art.Views = {
	-- Billboards (a headline band on top).
	Cola = { Image = "Cola", Focus = 543, Headline = 0.24 },
	Night = { Image = "Night", Focus = 512, Headline = 0.24 },
	Ramen = {
		Image = "Ramen",
		Focus = 512,
		Left = 112,
		Right = 912,
		Top = 41,
		Bottom = 521,
		Anchor = "Top",
		Headline = 0.19,
	},
	-- Murals.
	Wave = { Image = "Wave", Focus = 512 },
	TigerOni = { Image = "Tiger", Focus = 517, Left = 60, Right = 970 },
	NightCity = { Image = "Night", Focus = 512 },
	-- Posters (portrait crops).
	ColaCan = { Image = "Cola", Focus = 543 },
	Moon = { Image = "Night", Focus = 253 },
	RamenBowl = { Image = "Ramen", Focus = 513, Left = 112, Right = 912, Top = 127, Bottom = 521 },
	KoiLeft = { Image = "Wave", Focus = 268 },
	KoiRight = { Image = "Wave", Focus = 752 },
	Tiger = { Image = "Tiger", Focus = 339 },
	Oni = { Image = "Tiger", Focus = 744 },
} :: { [string]: View }

-- The posters' views, in the order the walls take them.
Art.Posters = { "ColaCan", "KoiRight", "Oni", "Moon", "RamenBowl", "Tiger", "KoiLeft" }

--[[
	The image id and the crop ({ x, y, width, height } in the image's pixels) that fills a board `aspect` wide (its
	width / height) with view `name`: as big as the view's area allows, centred on its focus (kept inside the area),
	and on the area's middle (or top) vertically.
]]
function Art.crop(name: string, aspect: number): (number, { number })
	local view = assert(Art.Views[name], `Art has no view "{name}"`)
	local left, right = view.Left or 0, view.Right or Art.Width
	local top, bottom = view.Top or 0, view.Bottom or Art.Height
	local width, height = right - left, bottom - top
	if width / height > aspect then
		width = height * aspect
	else
		height = width / aspect
	end
	local x = math.clamp(view.Focus - width / 2, left, right - width)
	local y = if view.Anchor == "Top" then top else top + ((bottom - top) - height) / 2
	local id = Art.Images[view.Image]
	return id, { math.floor(x + 0.5), math.floor(y + 0.5), math.floor(width + 0.5), math.floor(height + 0.5) }
end

return Art
