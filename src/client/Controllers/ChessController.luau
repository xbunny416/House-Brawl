--!strict
--[[
	ChessController — the lobby's chess table on screen (ChessService runs the games; this only draws the table's
	attributes and sends the seated player's moves).
	  * The pieces on the lobby board, for everyone: built here from parts on each square (Board part + SquareSize,
	    see Furniture.chessTable) from the table's Fen, with the last move and a king in check marked on the board.
	  * Over every table, for everyone: a board with CHESS, who plays White and Black with their clocks, and whose move
	    it is / check / how the game ended / the next game's countdown.
	  * For the two players, the board screen: the board from their own side (White at the bottom for White), the
	    pieces as cream / dark tokens with the chess symbols (Config.World.Chess.PieceLetters shows letters instead),
	    the last move tinted. On your move, tap or click one of your pieces to see where it can go (dots, rings on
	    captures), then the square to move there; a pawn reaching the end asks which piece it becomes. Both clocks,
	    whose move it is, Resign (tap twice) and Offer / Accept draw. Moves go to the server (ChessMove) which checks
	    them; the legal moves shown come from the same Shared/ChessRules.
]]
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ChessMatch = require(Shared:WaitForChild("ChessMatch"))
local ChessRules = require(Shared:WaitForChild("ChessRules"))
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Client = script.Parent.Parent
local HudFormat = require(Client:WaitForChild("Lib"):WaitForChild("HudFormat"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local TABLE_TAG = "ChessTable"
local SEAT_TAG = "ChessSeat"
local REFRESH_INTERVAL = 0.1
local BOARD_HEIGHT = 7 -- studs from the table top up to the board over the table
local BOARD_DISTANCE = 70 -- studs the board over the table shows from
local PIECE_LIFT = 0.02 -- studs from the board frame's top to the squares' top
local DESIGN_SQUARE = 0.55 -- the square size the 3D pieces are drawn for (they scale with SquareSize)
local LOW_CLOCK = 20 -- seconds: a clock this low turns red
local RESIGN_CONFIRM = 3 -- seconds the "Sure? Resign" button waits for the second tap

-- The chess symbols (outline set: none of them turns into an emoji) and the letters used instead if asked.
local SYMBOLS: { [string]: string } =
	{ K = "\u{2654}", Q = "\u{2655}", R = "\u{2656}", B = "\u{2657}", N = "\u{2658}", P = "\u{2659}" }
local LETTERS: { [string]: string } = { K = "K", Q = "Q", R = "R", B = "B", N = "N", P = "P" }

type PieceShape = { Shape: string, Size: { number }, At: { number }, Turn: number? }

-- The 3D pieces, from parts: sizes and heights (studs, for DESIGN_SQUARE squares), "Cylinder" stands upright.
local BASE: PieceShape = { Shape = "Cylinder", Size = { 0.4, 0.08 }, At = { 0, 0.04, 0 } }
local PIECES: { [string]: { PieceShape } } = {
	P = {
		BASE,
		{ Shape = "Cylinder", Size = { 0.24, 0.22 }, At = { 0, 0.19, 0 } },
		{ Shape = "Ball", Size = { 0.22 }, At = { 0, 0.38, 0 } },
	},
	R = {
		BASE,
		{ Shape = "Cylinder", Size = { 0.3, 0.4 }, At = { 0, 0.28, 0 } },
		{ Shape = "Cylinder", Size = { 0.36, 0.12 }, At = { 0, 0.52, 0 } },
		{ Shape = "Block", Size = { 0.09, 0.08, 0.09 }, At = { 0.11, 0.62, 0.11 } },
		{ Shape = "Block", Size = { 0.09, 0.08, 0.09 }, At = { -0.11, 0.62, 0.11 } },
		{ Shape = "Block", Size = { 0.09, 0.08, 0.09 }, At = { 0.11, 0.62, -0.11 } },
		{ Shape = "Block", Size = { 0.09, 0.08, 0.09 }, At = { -0.11, 0.62, -0.11 } },
	},
	-- The knight's head points forward (−Z), turned to face the other side.
	N = {
		BASE,
		{ Shape = "Cylinder", Size = { 0.3, 0.16 }, At = { 0, 0.16, 0 } },
		{ Shape = "Block", Size = { 0.18, 0.36, 0.22 }, At = { 0, 0.4, 0.03 }, Turn = -12 },
		{ Shape = "Block", Size = { 0.16, 0.14, 0.34 }, At = { 0, 0.56, -0.07 } },
		{ Shape = "Block", Size = { 0.05, 0.09, 0.05 }, At = { 0.05, 0.67, 0.05 } },
		{ Shape = "Block", Size = { 0.05, 0.09, 0.05 }, At = { -0.05, 0.67, 0.05 } },
	},
	B = {
		BASE,
		{ Shape = "Cylinder", Size = { 0.26, 0.36 }, At = { 0, 0.26, 0 } },
		{ Shape = "Ball", Size = { 0.24 }, At = { 0, 0.5, 0 } },
		{ Shape = "Ball", Size = { 0.08 }, At = { 0, 0.65, 0 } },
	},
	Q = {
		BASE,
		{ Shape = "Cylinder", Size = { 0.3, 0.46 }, At = { 0, 0.31, 0 } },
		{ Shape = "Cylinder", Size = { 0.36, 0.1 }, At = { 0, 0.58, 0 } },
		{ Shape = "Ball", Size = { 0.14 }, At = { 0, 0.69, 0 } },
	},
	K = {
		BASE,
		{ Shape = "Cylinder", Size = { 0.32, 0.5 }, At = { 0, 0.33, 0 } },
		{ Shape = "Cylinder", Size = { 0.38, 0.1 }, At = { 0, 0.62, 0 } },
		{ Shape = "Block", Size = { 0.07, 0.24, 0.07 }, At = { 0, 0.79, 0 } },
		{ Shape = "Block", Size = { 0.2, 0.07, 0.07 }, At = { 0, 0.82, 0 } },
	},
}

type Overhead = { Gui: BillboardGui, Players: TextLabel, Clocks: TextLabel, Status: TextLabel }
type TableView = {
	Model: Model,
	Folder: Folder, -- this client's 3D pieces and marks
	Pieces: { [number]: { Piece: string, Model: Model } },
	Marks: { BasePart },
	Board: BasePart?, -- the board part the pieces were placed on
	ShownFen: string,
	ShownMarks: string,
	Overhead: Overhead,
}
type Cell =
	{ Button: TextButton, Token: Frame, Glyph: TextLabel, Dot: Frame, Ring: Frame, Tint: Frame, Coord: TextLabel }

local ChessController = {}

local player = Players.LocalPlayer
local views: { [Model]: TableView } = {}
local letters = Config.World.Chess.PieceLetters

-- The board screen.
local screen: ScreenGui
local boardFrame: Frame
local cells: { [number]: Cell } = {}
local topName: TextLabel
local topClock: TextLabel
local bottomName: TextLabel
local bottomClock: TextLabel
local statusLabel: TextLabel
local resignButton: TextButton
local drawButton: TextButton
local picker: TextButton
local pickerRow: Frame
local pickerTokens: { [string]: { Token: Frame, Glyph: TextLabel } } = {}

local selected: number? = nil
local targets: { [number]: ChessRules.Move } = {}
local pendingPromotion: { From: number, To: number }? = nil
local resignArmedUntil = 0
local shownSignature = ""
local wasOpen = false

local function numberAttribute(model: Instance, name: string): number
	local value = model:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function stringAttribute(model: Instance, name: string): string
	local value = model:GetAttribute(name)
	return if type(value) == "string" then value else ""
end

local function nameOf(userId: number): string
	if userId == ChessMatch.Bot then
		return Localization.format("Chess.Bot")
	end
	local other = if userId > 0 then Players:GetPlayerByUserId(userId) else nil
	return if other then other.DisplayName else Localization.format("Chess.Someone")
end

-- Who plays `side` in the current (or last) game: kept after they stand up, for the result line.
local function gamePlayer(model: Instance, side: number): number
	return numberAttribute(model, if side == 1 then "White" else "Black")
end

-- Seconds `side` has left now (the clock of the side to move keeps running).
local function clockOf(model: Instance, side: number, position: ChessRules.Position): number
	local left = numberAttribute(model, `Clock{side}`)
	local toMove = if position.Turn == "w" then 1 else 2
	if model:GetAttribute("State") == "Playing" and toMove == side then
		left -= Workspace:GetServerTimeNow() - numberAttribute(model, "TurnStartedAt")
	end
	return math.max(left, 0)
end

local function positionOf(model: Instance): ChessRules.Position
	local fen = stringAttribute(model, "Fen")
	return ChessRules.fromFen(if fen ~= "" then fen else ChessRules.StartFen)
end

-- How the game ended, as a line ("Checkmate! Alex wins").
local function resultText(model: Instance): string
	local result, winner = stringAttribute(model, "Result"), numberAttribute(model, "Winner")
	local winnerName = if winner ~= 0 then nameOf(gamePlayer(model, winner)) else ""
	local loserName = if winner ~= 0 then nameOf(gamePlayer(model, 3 - winner)) else ""
	if result == "Checkmate" then
		return Localization.format("Chess.Result.Checkmate", { winnerName })
	elseif result == "Resigned" then
		return Localization.format("Chess.Result.Resigned", { winnerName, loserName })
	elseif result == "Time" then
		return if winner == 0
			then Localization.format("Chess.Result.TimeDraw")
			else Localization.format("Chess.Result.Time", { winnerName })
	elseif result == "Left" then
		return Localization.format("Chess.Result.Left", { winnerName, loserName })
	elseif result == "Stalemate" then
		return Localization.format("Chess.Result.Stalemate")
	elseif result == "Insufficient" then
		return Localization.format("Chess.Result.Insufficient")
	elseif result == "FiftyMoves" then
		return Localization.format("Chess.Result.FiftyMoves")
	elseif result == "Repetition" then
		return Localization.format("Chess.Result.Repetition")
	elseif result == "Agreed" then
		return Localization.format("Chess.Result.Agreed")
	end
	return ""
end

local function newGameIn(model: Instance): number
	return math.max(0, math.ceil(numberAttribute(model, "EndsAt") - Workspace:GetServerTimeNow()))
end

---------------------------------------------------------------------------------------------------------------------
-- The pieces on the lobby board
---------------------------------------------------------------------------------------------------------------------

-- Where square `index`'s centre is on `board`, at the squares' surface.
local function squareCFrame(board: BasePart, index: number): CFrame
	local size = numberAttribute(board, "SquareSize")
	local rank, file = ChessRules.rankOf(index), ChessRules.fileOf(index)
	return board.CFrame * CFrame.new((rank - 3.5) * size, board.Size.Y / 2 + PIECE_LIFT, (file - 3.5) * size)
end

local function piecePart(parent: Instance, shape: PieceShape, at: CFrame, scale: number, color: Color3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	local size, offset = shape.Size, shape.At
	local cf = at * CFrame.new(offset[1] * scale, offset[2] * scale, offset[3] * scale)
	if shape.Turn then
		cf *= CFrame.Angles(math.rad(shape.Turn), 0, 0)
	end
	if shape.Shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(size[2], size[1], size[1]) * scale
		cf *= CFrame.Angles(0, 0, math.pi / 2)
	elseif shape.Shape == "Ball" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.one * size[1] * scale
	else
		part.Size = Vector3.new(size[1], size[2], size[3]) * scale
	end
	part.CFrame = cf
	part.Parent = parent
end

local function buildPiece(view: TableView, board: BasePart, index: number, piece: string): Model
	local white = ChessRules.colorOf(piece) == "w"
	local scale = numberAttribute(board, "SquareSize") / DESIGN_SQUARE
	-- White faces +X (toward Black), Black faces −X.
	local at = squareCFrame(board, index) * CFrame.Angles(0, if white then -math.pi / 2 else math.pi / 2, 0)
	local model = Instance.new("Model")
	model.Name = piece
	for _, shape in PIECES[string.upper(piece)] do
		piecePart(model, shape, at, scale, if white then Kit.Colors.ChessWhite else Kit.Colors.ChessBlack)
	end
	model.Parent = view.Folder
	return model
end

local function mark(view: TableView, board: BasePart, index: number, color: Color3)
	local size = numberAttribute(board, "SquareSize")
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Transparency = 0.45
	part.Size = Vector3.new(size, 0.01, size)
	part.CFrame = squareCFrame(board, index) * CFrame.new(0, 0.01, 0)
	part.Parent = view.Folder
	table.insert(view.Marks, part)
end

local function clearPieces(view: TableView)
	for _, entry in view.Pieces do
		entry.Model:Destroy()
	end
	view.Pieces = {}
	for _, part in view.Marks do
		part:Destroy()
	end
	view.Marks = {}
	view.ShownFen, view.ShownMarks = "", ""
end

local function refreshPieces(view: TableView)
	local model = view.Model
	local board = model:FindFirstChild("Board")
	if board == nil or not board:IsA("BasePart") or numberAttribute(board, "SquareSize") <= 0 then
		if view.Board then
			clearPieces(view) -- streamed out
			view.Board = nil
		end
		return
	end
	if view.Board ~= board then
		clearPieces(view)
		view.Board = board
	end
	local fen = stringAttribute(model, "Fen")
	local position = positionOf(model)
	if fen ~= view.ShownFen then
		view.ShownFen = fen
		for index = 1, 64 do
			local piece = position.Board[index]
			local current = view.Pieces[index]
			if current and current.Piece ~= piece then
				current.Model:Destroy()
				view.Pieces[index] = nil
			end
			if view.Pieces[index] == nil and piece ~= "" then
				view.Pieces[index] = { Piece = piece, Model = buildPiece(view, board, index, piece) }
			end
		end
	end
	local lastMove, check = stringAttribute(model, "LastMove"), model:GetAttribute("Check") == true
	local marks = `{lastMove}|{check}|{fen}`
	if marks ~= view.ShownMarks then
		view.ShownMarks = marks
		for _, part in view.Marks do
			part:Destroy()
		end
		view.Marks = {}
		if #lastMove >= 4 then
			for _, name in { string.sub(lastMove, 1, 2), string.sub(lastMove, 3, 4) } do
				local index = ChessRules.square(name)
				if index then
					mark(view, board, index, Kit.Colors.ChessMark)
				end
			end
		end
		local king = if check then table.find(position.Board, if position.Turn == "w" then "K" else "k") else nil
		if king then
			mark(view, board, king, Kit.Colors.Live)
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- The board over each table
---------------------------------------------------------------------------------------------------------------------

local function buildOverhead(): Overhead
	local gui = Instance.new("BillboardGui")
	gui.Name = "ChessBoardInfo"
	gui.Size = UDim2.fromOffset(300, 120)
	gui.LightInfluence = 0
	gui.MaxDistance = BOARD_DISTANCE
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Kit.Colors.Panel
	back.BackgroundTransparency = 0.15
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = back
	local outline = Instance.new("UIStroke")
	outline.Color = Kit.Colors.Gold
	outline.Thickness = 2
	outline.Parent = back
	local title = Kit.label(back, Localization.format("Chess.Title"), UDim2.fromScale(1, 0.24), 20)
	title.Font = Kit.TitleFont
	title.TextColor3 = Kit.Colors.Gold
	title.Position = UDim2.fromScale(0, 0.04)
	local names = Kit.label(back, "", UDim2.fromScale(0.92, 0.22), 16)
	names.Position = UDim2.fromScale(0.04, 0.3)
	local clocks = Kit.label(back, "", UDim2.fromScale(0.92, 0.18), 16)
	clocks.Position = UDim2.fromScale(0.04, 0.52)
	clocks.TextColor3 = Kit.Colors.Muted
	local status = Kit.label(back, "", UDim2.fromScale(0.92, 0.22), 16)
	status.Position = UDim2.fromScale(0.04, 0.72)
	status.TextColor3 = Kit.Colors.Coin
	gui.Parent = player:WaitForChild("PlayerGui")
	return { Gui = gui, Players = names, Clocks = clocks, Status = status }
end

local function refreshOverhead(view: TableView)
	local model, overhead = view.Model, view.Overhead
	local top = model:FindFirstChild("Top")
	if top and top:IsA("BasePart") and overhead.Gui.Adornee ~= top then
		overhead.Gui.Adornee = top
	end
	overhead.Gui.StudsOffsetWorldSpace = Vector3.new(0, BOARD_HEIGHT, 0)
	local state = model:GetAttribute("State")
	local white, black = numberAttribute(model, "Player1"), numberAttribute(model, "Player2")
	local position = positionOf(model)
	local playing = state == "Playing" or state == "Over"
	overhead.Players.Text = if playing
		then Localization.format("Chess.Versus", { nameOf(gamePlayer(model, 1)), nameOf(gamePlayer(model, 2)) })
		elseif white ~= 0 or black ~= 0 then Localization.format(
			"Chess.WaitingFor",
			{ nameOf(if white ~= 0 then white else black) }
		)
		else Localization.format("Chess.Empty")
	overhead.Clocks.Text = if playing
		then `{HudFormat.clock(clockOf(model, 1, position))} · {HudFormat.clock(clockOf(model, 2, position))}`
		else ""
	if state == "Playing" then
		local toMove = nameOf(gamePlayer(model, if position.Turn == "w" then 1 else 2))
		overhead.Status.Text = if model:GetAttribute("Check") == true
			then Localization.format("Chess.CheckFor", { toMove })
			else Localization.format("Chess.ToMove", { toMove })
	elseif state == "Over" then
		overhead.Status.Text = resultText(model)
	else
		overhead.Status.Text = ""
	end
end

local function addTable(instance: Instance)
	if not instance:IsA("Model") or views[instance] then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "ChessPieces"
	folder.Parent = Workspace
	local view: TableView = {
		Model = instance,
		Folder = folder,
		Pieces = {},
		Marks = {},
		Board = nil,
		ShownFen = "",
		ShownMarks = "",
		Overhead = buildOverhead(),
	}
	views[instance] = view
	instance.Destroying:Connect(function()
		folder:Destroy()
		view.Overhead.Gui:Destroy()
		views[instance] = nil
	end)
end

---------------------------------------------------------------------------------------------------------------------
-- The board screen
---------------------------------------------------------------------------------------------------------------------

-- The table the local player sits at and their side, if any.
local function myTable(): (Model?, number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat == nil or not seat:HasTag(SEAT_TAG) then
		return nil, 0
	end
	local node: Instance? = seat.Parent
	while node and not node:HasTag(TABLE_TAG) do
		node = node.Parent
	end
	local side = seat:GetAttribute("Side")
	if node == nil or not node:IsA("Model") or (side ~= 1 and side ~= 2) then
		return nil, 0
	end
	return node, side :: number
end

local function round(frame: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = frame
end

-- A piece token: a cream or dark disc with the piece's symbol (or letter).
local function setToken(token: Frame, glyph: TextLabel, piece: string)
	token.Visible = piece ~= ""
	if piece == "" then
		return
	end
	local white = ChessRules.colorOf(piece) == "w"
	token.BackgroundColor3 = if white then Kit.Colors.ChessWhite else Kit.Colors.ChessBlack
	glyph.TextColor3 = if white then Kit.Colors.ChessBlack else Kit.Colors.ChessWhite
	local kind = string.upper(piece)
	glyph.Text = if letters then LETTERS[kind] else SYMBOLS[kind]
end

local function newToken(parent: Instance, scale: number): (Frame, TextLabel)
	local token = Instance.new("Frame")
	token.Name = "Token"
	token.AnchorPoint = Vector2.new(0.5, 0.5)
	token.Position = UDim2.fromScale(0.5, 0.5)
	token.Size = UDim2.fromScale(scale, scale)
	token.ZIndex = 3
	round(token, UDim.new(0.5, 0))
	local stroke = Instance.new("UIStroke")
	stroke.Color = Kit.Colors.Panel
	stroke.Thickness = 1.5
	stroke.Parent = token
	local glyph = Instance.new("TextLabel")
	glyph.BackgroundTransparency = 1
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.Font = Kit.TitleFont
	glyph.TextScaled = true
	glyph.ZIndex = 4
	glyph.Parent = token
	token.Parent = parent
	return token, glyph
end

local function send(from: number, to: number, promotion: string?)
	Net.fire("ChessMove", ChessRules.name(from), ChessRules.name(to), promotion)
	selected = nil
	targets = {}
	pendingPromotion = nil
	picker.Visible = false
	shownSignature = "" -- redraw now (the selection is gone)
end

local function onSquare(index: number)
	local model, side = myTable()
	if model == nil or model:GetAttribute("State") ~= "Playing" then
		return
	end
	local position = positionOf(model)
	local mine = if side == 1 then "w" else "b"
	if position.Turn ~= mine then
		return
	end
	local move = targets[index]
	if selected and move then
		if move.Promotion then
			pendingPromotion = { From = move.From, To = move.To }
			picker.Visible = true
			for piece, choice in pickerTokens do
				setToken(choice.Token, choice.Glyph, if side == 1 then piece else string.lower(piece))
			end
		else
			send(move.From, move.To, nil)
		end
		return
	end
	local previous = selected
	selected, targets = nil, {}
	-- Tapping one of your pieces selects it (tapping it again lets go); anything else clears the selection.
	if ChessRules.colorOf(position.Board[index]) == mine and previous ~= index then
		selected = index
		for _, legal in ChessRules.movesFrom(position, index) do
			targets[legal.To] = legal
		end
	end
	shownSignature = ""
end

local function buildScreen()
	screen = Kit.screen("Chess", 6)
	local panel = Kit.panel(
		screen,
		UDim2.fromScale(0.78, 0.86),
		UDim2.fromScale(0.56, 0.48),
		Vector2.new(0.5, 0.5),
		Vector2.new(980, 680)
	)

	-- The board: as big a square as fits on the right.
	boardFrame = Instance.new("Frame")
	boardFrame.Name = "Board"
	boardFrame.AnchorPoint = Vector2.new(1, 0.5)
	boardFrame.Position = UDim2.fromScale(1, 0.5)
	boardFrame.Size = UDim2.fromScale(0.62, 1)
	boardFrame.BackgroundColor3 = Kit.Colors.ChessDark
	boardFrame.Parent = panel
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.Parent = boardFrame
	for index = 1, 64 do
		local button = Instance.new("TextButton")
		button.Name = ChessRules.name(index)
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		button.Text = ""
		button.Size = UDim2.fromScale(1 / 8, 1 / 8)
		local shade = (ChessRules.fileOf(index) + ChessRules.rankOf(index)) % 2
		button.BackgroundColor3 = if shade == 0 then Kit.Colors.ChessDark else Kit.Colors.ChessLight
		local tint = Instance.new("Frame")
		tint.Name = "Tint"
		tint.Size = UDim2.fromScale(1, 1)
		tint.BackgroundColor3 = Kit.Colors.ChessMark
		tint.BackgroundTransparency = 0.5
		tint.BorderSizePixel = 0
		tint.ZIndex = 2
		tint.Visible = false
		tint.Parent = button
		local token, glyph = newToken(button, 0.82)
		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.Size = UDim2.fromScale(0.3, 0.3)
		dot.BackgroundColor3 = Kit.Colors.Panel
		dot.BackgroundTransparency = 0.45
		dot.ZIndex = 5
		dot.Visible = false
		round(dot, UDim.new(0.5, 0))
		dot.Parent = button
		local ring = Instance.new("Frame")
		ring.Name = "Ring"
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.Size = UDim2.fromScale(0.94, 0.94)
		ring.BackgroundTransparency = 1
		ring.ZIndex = 5
		ring.Visible = false
		round(ring, UDim.new(0.5, 0))
		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = Kit.Colors.Panel
		ringStroke.Transparency = 0.35
		ringStroke.Thickness = 3
		ringStroke.Parent = ring
		ring.Parent = button
		local coord = Instance.new("TextLabel")
		coord.Name = "Coord"
		coord.BackgroundTransparency = 1
		coord.Size = UDim2.fromScale(0.3, 0.3)
		coord.Font = Kit.BodyFont
		coord.TextScaled = true
		coord.TextColor3 = if shade == 0 then Kit.Colors.ChessLight else Kit.Colors.ChessDark
		coord.ZIndex = 6
		coord.Parent = button
		button.Activated:Connect(function()
			onSquare(index)
		end)
		button.Parent = boardFrame
		cells[index] =
			{ Button = button, Token = token, Glyph = glyph, Dot = dot, Ring = ring, Tint = tint, Coord = coord }
	end

	-- The promotion picker: Queen, Rook, Bishop, Knight over the board; tapping beside them cancels.
	picker = Instance.new("TextButton")
	picker.Name = "Promotion"
	picker.Text = ""
	picker.AutoButtonColor = false
	picker.Size = UDim2.fromScale(1, 1)
	picker.BackgroundColor3 = Kit.Colors.Panel
	picker.BackgroundTransparency = 0.35
	picker.ZIndex = 10
	picker.Visible = false
	picker.Parent = boardFrame
	picker.Activated:Connect(function()
		pendingPromotion = nil
		picker.Visible = false
	end)
	local prompt = Kit.label(picker, Localization.format("Chess.Promote"), UDim2.fromScale(1, 0.1), 22)
	prompt.Position = UDim2.fromScale(0, 0.3)
	prompt.ZIndex = 11
	pickerRow = Instance.new("Frame")
	pickerRow.BackgroundTransparency = 1
	pickerRow.AnchorPoint = Vector2.new(0.5, 0.5)
	pickerRow.Position = UDim2.fromScale(0.5, 0.52)
	pickerRow.Size = UDim2.fromScale(0.8, 0.2)
	pickerRow.ZIndex = 11
	pickerRow.Parent = picker
	local layout = Kit.list(pickerRow, Enum.FillDirection.Horizontal, UDim.new(0.04, 0))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	for order, piece in ChessRules.Promotions do
		local choice = Instance.new("TextButton")
		choice.Name = piece
		choice.Text = ""
		choice.LayoutOrder = order
		choice.Size = UDim2.fromScale(0.22, 1)
		choice.BackgroundColor3 = Kit.Colors.Button
		choice.ZIndex = 12
		round(choice, UDim.new(0, 8))
		local token, glyph = newToken(choice, 0.86)
		token.ZIndex = 13
		glyph.ZIndex = 14
		pickerTokens[piece] = { Token = token, Glyph = glyph }
		choice.Activated:Connect(function()
			local pending = pendingPromotion
			if pending then
				send(pending.From, pending.To, piece)
			end
		end)
		choice.Parent = pickerRow
	end

	-- The side column: the other player on top, you at the bottom, the status and the buttons between.
	local column = Instance.new("Frame")
	column.BackgroundTransparency = 1
	column.Size = UDim2.fromScale(0.35, 1)
	column.Parent = panel
	local function playerRow(y: number): (TextLabel, TextLabel)
		local name = Kit.label(column, "", UDim2.fromScale(1, 0.09), 22)
		name.Position = UDim2.fromScale(0, y)
		name.TextXAlignment = Enum.TextXAlignment.Left
		local clock = Kit.label(column, "", UDim2.fromScale(1, 0.11), 34)
		clock.Font = Kit.TitleFont
		clock.Position = UDim2.fromScale(0, y + 0.09)
		clock.TextXAlignment = Enum.TextXAlignment.Left
		return name, clock
	end
	topName, topClock = playerRow(0)
	statusLabel = Kit.label(column, "", UDim2.fromScale(1, 0.2), 24)
	statusLabel.Position = UDim2.fromScale(0, 0.27)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	resignButton = Kit.button(column, Localization.format("Chess.Resign"), UDim2.fromScale(0.48, 0.1))
	resignButton.Position = UDim2.fromScale(0, 0.52)
	drawButton = Kit.button(column, Localization.format("Chess.OfferDraw"), UDim2.fromScale(0.48, 0.1))
	drawButton.Position = UDim2.fromScale(0.52, 0.52)
	bottomName, bottomClock = playerRow(0.8)

	resignButton.Activated:Connect(function()
		if os.clock() < resignArmedUntil then
			resignArmedUntil = 0
			Net.fire("ChessAction", "Resign")
		else
			resignArmedUntil = os.clock() + RESIGN_CONFIRM
		end
	end)
	drawButton.Activated:Connect(function()
		local model, side = myTable()
		if model == nil then
			return
		end
		local offer = numberAttribute(model, "DrawOffer")
		if offer == 3 - side then
			Net.fire("ChessAction", "AcceptDraw")
		elseif offer == 0 then
			Net.fire("ChessAction", "OfferDraw")
		end
	end)
end

-- Redraws the squares: pieces, the last move, the selection and where the selected piece can go.
local function renderBoard(model: Model, side: number, position: ChessRules.Position)
	local lastMove = stringAttribute(model, "LastMove")
	local lastFrom = if #lastMove >= 4 then ChessRules.square(string.sub(lastMove, 1, 2)) else nil
	local lastTo = if #lastMove >= 4 then ChessRules.square(string.sub(lastMove, 3, 4)) else nil
	local check = model:GetAttribute("Check") == true
	local king = if check then table.find(position.Board, if position.Turn == "w" then "K" else "k") else nil
	for index, cell in cells do
		local file, rank = ChessRules.fileOf(index), ChessRules.rankOf(index)
		-- White sees rank 1 at the bottom and file a on the left; Black the other way round.
		local column = if side == 1 then file else 7 - file
		local row = if side == 1 then 7 - rank else rank
		cell.Button.Position = UDim2.fromScale(column / 8, row / 8)
		local piece = position.Board[index]
		setToken(cell.Token, cell.Glyph, piece)
		cell.Tint.Visible = index == lastFrom or index == lastTo or index == selected or index == king
		cell.Tint.BackgroundColor3 = if index == king then Kit.Colors.Live else Kit.Colors.ChessMark
		local move = targets[index]
		cell.Dot.Visible = move ~= nil and piece == "" and not move.EnPassant
		cell.Ring.Visible = move ~= nil and (piece ~= "" or move.EnPassant == true)
		-- Coordinates on the edge squares: files along the bottom row, ranks down the left column.
		local text = ""
		if row == 7 then
			text = string.char(97 + file)
			cell.Coord.AnchorPoint = Vector2.new(1, 1)
			cell.Coord.Position = UDim2.fromScale(0.98, 1)
		end
		if column == 0 then
			text = if text ~= "" then tostring(rank + 1) .. " " .. text else tostring(rank + 1)
			cell.Coord.AnchorPoint = Vector2.new(0, 0)
			cell.Coord.Position = UDim2.fromScale(0.03, 0)
		end
		cell.Coord.Text = text
	end
end

local function refreshScreen()
	local model, side = myTable()
	local open = model ~= nil
	screen.Enabled = open
	if model == nil then
		if wasOpen then
			selected, targets, pendingPromotion = nil, {}, nil
			picker.Visible = false
			shownSignature = ""
		end
		wasOpen = false
		return
	end
	local state = model:GetAttribute("State")
	local position = positionOf(model)
	local mine = if side == 1 then "w" else "b"
	local myTurn = state == "Playing" and position.Turn == mine
	if not myTurn and (selected or pendingPromotion) then
		selected, targets, pendingPromotion = nil, {}, nil
		picker.Visible = false
		shownSignature = ""
	end
	local signature = table.concat({
		stringAttribute(model, "Fen"),
		stringAttribute(model, "LastMove"),
		tostring(model:GetAttribute("Check")),
		tostring(side),
		tostring(selected),
	}, "|")
	if signature ~= shownSignature then
		shownSignature = signature
		renderBoard(model, side, position)
	end

	-- Names and clocks: the other player on top, you below; the side to move's clock is bright.
	local other = 3 - side
	local seated = numberAttribute(model, `Player{other}`)
	local otherId = if state == "Playing" or state == "Over" then gamePlayer(model, other) else seated
	local colorKey = { "Chess.White", "Chess.Black" }
	topName.Text = if otherId ~= 0
		then Localization.format("Chess.PlayerColor", { nameOf(otherId), Localization.format(colorKey[other]) })
		else ""
	bottomName.Text = Localization.format(
		"Chess.PlayerColor",
		{ Localization.format("Chess.You"), Localization.format(colorKey[side]) }
	)
	local playing = state == "Playing" or state == "Over"
	local toMove = if position.Turn == "w" then 1 else 2
	local function showClock(label: TextLabel, clockSide: number)
		local left = clockOf(model, clockSide, position)
		label.Text = if playing then HudFormat.clock(left) else ""
		label.TextColor3 = if left <= LOW_CLOCK
			then Kit.Colors.Live
			elseif state == "Playing" and toMove == clockSide then Kit.Colors.Text
			else Kit.Colors.Muted
	end
	showClock(topClock, other)
	showClock(bottomClock, side)

	local offer = numberAttribute(model, "DrawOffer")
	if state == "Playing" then
		local lines: { string } = {}
		if model:GetAttribute("Check") == true then
			table.insert(lines, Localization.format("Chess.Check"))
		end
		table.insert(
			lines,
			if myTurn
				then Localization.format("Chess.YourMove")
				else Localization.format("Chess.TheirMove", { nameOf(otherId) })
		)
		if offer == other then
			table.insert(lines, Localization.format("Chess.TheyOfferDraw", { nameOf(otherId) }))
		end
		statusLabel.Text = table.concat(lines, "\n")
		statusLabel.TextColor3 = if myTurn then Kit.Colors.Coin else Kit.Colors.Text
	elseif state == "Over" then
		local result = resultText(model)
		local next = if seated ~= 0 then "\n" .. Localization.format("Chess.NewGame", { newGameIn(model) }) else ""
		statusLabel.Text = result .. next
		statusLabel.TextColor3 = Kit.Colors.Gold
	else
		statusLabel.Text = Localization.format("Chess.WaitingYou")
		statusLabel.TextColor3 = Kit.Colors.Muted
	end

	resignButton.Visible = state == "Playing"
	resignButton.Text =
		Localization.format(if os.clock() < resignArmedUntil then "Chess.ResignSure" else "Chess.Resign")
	drawButton.Visible = state == "Playing"
	drawButton.Text = Localization.format(
		if offer == other then "Chess.AcceptDraw" elseif offer == side then "Chess.DrawOffered" else "Chess.OfferDraw"
	)
	Kit.setChosen(drawButton, offer == other)

	-- On a gamepad, put the selection on the board when the screen opens.
	if not wasOpen and InputController.getDevice() == "Gamepad" then
		local start = table.find(position.Board, if side == 1 then "K" else "k")
		GuiService.SelectedObject = if start then cells[start].Button else cells[1].Button
	end
	wasOpen = true
end

function ChessController.Start(_self: any)
	buildScreen()
	for _, model in CollectionService:GetTagged(TABLE_TAG) do
		addTable(model)
	end
	CollectionService:GetInstanceAddedSignal(TABLE_TAG):Connect(addTable)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < REFRESH_INTERVAL then
			return
		end
		elapsed = 0
		for _, view in views do
			refreshPieces(view)
			refreshOverhead(view)
		end
		refreshScreen()
	end)
end

return ChessController
