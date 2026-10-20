--!strict
--[[
	ChessRules — the rules of chess (owner's fix list: "chess minigame in the lobby"). Pure, shared: the server checks
	every move with it (ChessService through Shared/ChessMatch) and the board screen shows the legal moves from it.
	Specs check it against the standard perft counts (every legal move to a given depth from known positions).
	  * A Position holds 64 squares (index = rank * 8 + file + 1: a1 = 1, h1 = 8, a8 = 57, h8 = 64), each "" or a
	    piece letter (PNBRQK White, pnbrqk Black), the side to move ("w" / "b"), castling rights ("KQkq" or "-"),
	    the en passant square, and the half-move clock (for the 50-move rule) and move number, like FEN.
	  * Every rule: castling (not out of, through or into check), en passant, promotion to Q / R / B / N, check,
	    checkmate, stalemate, and the draws by insufficient material, the 50-move rule and threefold repetition.
]]
export type Move = {
	From: number,
	To: number,
	Promotion: string?, -- "Q" / "R" / "B" / "N" (always upper case)
	Castle: boolean?,
	EnPassant: boolean?,
	DoublePush: boolean?,
}

export type Position = {
	Board: { string },
	Turn: string, -- "w" / "b"
	Castling: string, -- "KQkq", a subset, or "-"
	EnPassant: number?, -- the square a pawn may capture onto en passant
	Halfmove: number,
	Fullmove: number,
}

local ChessRules = {}

ChessRules.StartFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
ChessRules.Promotions = { "Q", "R", "B", "N" }

local KNIGHT: { { number } } =
	{ { 1, 2 }, { 2, 1 }, { 2, -1 }, { 1, -2 }, { -1, -2 }, { -2, -1 }, { -2, 1 }, { -1, 2 } }
local KING: { { number } } = { { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 }, { 0, -1 }, { 1, -1 } }
local ROOK_DIRS: { { number } } = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local BISHOP_DIRS: { { number } } = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

-- Castling: the king's square, where it lands, the rook's squares, the squares that must be empty and the squares
-- the king crosses (which must not be attacked).
type Castle = { King: number, To: number, RookFrom: number, RookTo: number, Empty: { number }, Safe: { number } }
local CASTLES: { [string]: Castle } = {
	K = { King = 5, To = 7, RookFrom = 8, RookTo = 6, Empty = { 6, 7 }, Safe = { 5, 6, 7 } },
	Q = { King = 5, To = 3, RookFrom = 1, RookTo = 4, Empty = { 2, 3, 4 }, Safe = { 5, 4, 3 } },
	k = { King = 61, To = 63, RookFrom = 64, RookTo = 62, Empty = { 62, 63 }, Safe = { 61, 62, 63 } },
	q = { King = 61, To = 59, RookFrom = 57, RookTo = 60, Empty = { 58, 59, 60 }, Safe = { 61, 60, 59 } },
}
-- Moving from or capturing on these squares loses these rights.
local RIGHTS_LOST: { [number]: string } = { [1] = "Q", [8] = "K", [5] = "KQ", [57] = "q", [64] = "k", [61] = "kq" }

function ChessRules.fileOf(index: number): number
	return (index - 1) % 8
end

function ChessRules.rankOf(index: number): number
	return (index - 1) // 8
end

function ChessRules.index(file: number, rank: number): number?
	if file < 0 or file > 7 or rank < 0 or rank > 7 then
		return nil
	end
	return rank * 8 + file + 1
end

-- "e2" → 13, or nil.
function ChessRules.square(name: string): number?
	local file, rank = string.match(name, "^([a-h])([1-8])$")
	if file == nil or rank == nil then
		return nil
	end
	return ChessRules.index(string.byte(file) - 97, (tonumber(rank) :: number) - 1)
end

-- 13 → "e2".
function ChessRules.name(index: number): string
	return string.char(97 + ChessRules.fileOf(index)) .. tostring(ChessRules.rankOf(index) + 1)
end

-- "w" for a White piece, "b" for a Black one, nil for an empty square.
function ChessRules.colorOf(piece: string): string?
	if piece == "" then
		return nil
	end
	return if string.upper(piece) == piece then "w" else "b"
end

local function other(color: string): string
	return if color == "w" then "b" else "w"
end

local function hasRight(position: Position, right: string): boolean
	return string.find(position.Castling, right, 1, true) ~= nil
end

---------------------------------------------------------------------------------------------------------------------
-- FEN
---------------------------------------------------------------------------------------------------------------------

function ChessRules.fromFen(fen: string): Position
	local parts = string.split(fen, " ")
	local board = table.create(64, "")
	local rank, file = 7, 0
	for character in string.gmatch(parts[1] or "", ".") do
		if character == "/" then
			rank -= 1
			file = 0
		elseif tonumber(character) then
			file += tonumber(character) :: number
		else
			local index = ChessRules.index(file, rank)
			if index then
				board[index] = character
			end
			file += 1
		end
	end
	local enPassant = parts[4]
	return {
		Board = board,
		Turn = if parts[2] == "b" then "b" else "w",
		Castling = if parts[3] and parts[3] ~= "" then parts[3] else "-",
		EnPassant = if enPassant and enPassant ~= "-" then ChessRules.square(enPassant) else nil,
		Halfmove = tonumber(parts[5]) or 0,
		Fullmove = tonumber(parts[6]) or 1,
	}
end

local function placement(board: { string }): string
	local ranks: { string } = {}
	for rank = 7, 0, -1 do
		local row, empty = "", 0
		for file = 0, 7 do
			local piece = board[rank * 8 + file + 1]
			if piece == "" then
				empty += 1
			else
				if empty > 0 then
					row ..= tostring(empty)
					empty = 0
				end
				row ..= piece
			end
		end
		if empty > 0 then
			row ..= tostring(empty)
		end
		table.insert(ranks, row)
	end
	return table.concat(ranks, "/")
end

function ChessRules.toFen(position: Position): string
	local enPassant = if position.EnPassant then ChessRules.name(position.EnPassant) else "-"
	return table.concat({
		placement(position.Board),
		position.Turn,
		position.Castling,
		enPassant,
		tostring(position.Halfmove),
		tostring(position.Fullmove),
	}, " ")
end

function ChessRules.new(): Position
	return ChessRules.fromFen(ChessRules.StartFen)
end

---------------------------------------------------------------------------------------------------------------------
-- Attacks and moves
---------------------------------------------------------------------------------------------------------------------

-- Whether `color`'s pieces attack `square` on `board`.
function ChessRules.isAttacked(board: { string }, square: number, color: string): boolean
	local file, rank = ChessRules.fileOf(square), ChessRules.rankOf(square)
	local white = color == "w"
	local function pieceAt(df: number, dr: number): string
		local index = ChessRules.index(file + df, rank + dr)
		return if index then board[index] else ""
	end
	-- Pawns attack diagonally forward, so a White pawn attacking here stands one rank below.
	local pawnRank = if white then -1 else 1
	local pawn = if white then "P" else "p"
	if pieceAt(-1, pawnRank) == pawn or pieceAt(1, pawnRank) == pawn then
		return true
	end
	local knight, king = if white then "N" else "n", if white then "K" else "k"
	for _, step in KNIGHT do
		if pieceAt(step[1], step[2]) == knight then
			return true
		end
	end
	for _, step in KING do
		if pieceAt(step[1], step[2]) == king then
			return true
		end
	end
	local function slides(dirs: { { number } }, a: string, b: string): boolean
		for _, dir in dirs do
			local f, r = file + dir[1], rank + dir[2]
			while true do
				local index = ChessRules.index(f, r)
				if index == nil then
					break
				end
				local piece = board[index]
				if piece ~= "" then
					if piece == a or piece == b then
						return true
					end
					break
				end
				f += dir[1]
				r += dir[2]
			end
		end
		return false
	end
	local queen = if white then "Q" else "q"
	return slides(ROOK_DIRS, if white then "R" else "r", queen)
		or slides(BISHOP_DIRS, if white then "B" else "b", queen)
end

local function kingSquare(board: { string }, color: string): number?
	local king = if color == "w" then "K" else "k"
	return table.find(board, king)
end

-- Whether the side to move is in check.
function ChessRules.inCheck(position: Position): boolean
	local king = kingSquare(position.Board, position.Turn)
	return king ~= nil and ChessRules.isAttacked(position.Board, king, other(position.Turn))
end

-- Every move the side to move could make if checks didn't matter.
local function pseudoMoves(position: Position): { Move }
	local board, color = position.Board, position.Turn
	local moves: { Move } = {}
	local function add(from: number, to: number, extra: { [string]: any }?)
		local move: Move = { From = from, To = to }
		if extra then
			for key, value in extra do
				(move :: any)[key] = value
			end
		end
		table.insert(moves, move)
	end
	local function addPawn(from: number, to: number, extra: { [string]: any }?)
		local lastRank = if color == "w" then 7 else 0
		if ChessRules.rankOf(to) == lastRank then
			for _, piece in ChessRules.Promotions do
				add(from, to, { Promotion = piece })
			end
		else
			add(from, to, extra)
		end
	end
	for from = 1, 64 do
		local piece = board[from]
		if piece == "" or ChessRules.colorOf(piece) ~= color then
			continue
		end
		local kind = string.upper(piece)
		local file, rank = ChessRules.fileOf(from), ChessRules.rankOf(from)
		if kind == "P" then
			local forward = if color == "w" then 1 else -1
			local one = ChessRules.index(file, rank + forward)
			if one and board[one] == "" then
				addPawn(from, one)
				local startRank = if color == "w" then 1 else 6
				local two = ChessRules.index(file, rank + 2 * forward)
				if rank == startRank and two and board[two] == "" then
					add(from, two, { DoublePush = true })
				end
			end
			for _, side in { -1, 1 } do
				local target = ChessRules.index(file + side, rank + forward)
				if target then
					local victim = board[target]
					if victim ~= "" and ChessRules.colorOf(victim) ~= color then
						addPawn(from, target)
					elseif target == position.EnPassant then
						add(from, target, { EnPassant = true })
					end
				end
			end
		elseif kind == "N" or kind == "K" then
			local steps: { { number } } = if kind == "N" then KNIGHT else KING
			for _, step in steps do
				local target = ChessRules.index(file + step[1], rank + step[2])
				if target and ChessRules.colorOf(board[target]) ~= color then
					add(from, target)
				end
			end
		else
			local dirs: { { number } } = {}
			if kind == "R" or kind == "Q" then
				table.move(ROOK_DIRS, 1, 4, #dirs + 1, dirs)
			end
			if kind == "B" or kind == "Q" then
				table.move(BISHOP_DIRS, 1, 4, #dirs + 1, dirs)
			end
			for _, dir in dirs do
				local f, r = file + dir[1], rank + dir[2]
				while true do
					local target = ChessRules.index(f, r)
					if target == nil then
						break
					end
					local victim = board[target]
					if victim == "" then
						add(from, target)
					else
						if ChessRules.colorOf(victim) ~= color then
							add(from, target)
						end
						break
					end
					f += dir[1]
					r += dir[2]
				end
			end
		end
	end
	-- Castling: the rights, an unmoved rook, empty squares between, and no attacked square on the king's path.
	local enemy = other(color)
	for right, castle in CASTLES do
		local mine = (color == "w") == (string.upper(right) == right)
		if mine and hasRight(position, right) and board[castle.RookFrom] == (if color == "w" then "R" else "r") then
			local clear = true
			for _, square in castle.Empty do
				if board[square] ~= "" then
					clear = false
				end
			end
			for _, square in castle.Safe do
				if clear and ChessRules.isAttacked(board, square, enemy) then
					clear = false
				end
			end
			if clear then
				add(castle.King, castle.To, { Castle = true })
			end
		end
	end
	return moves
end

-- The position after `move` (a legal or pseudo-legal move of the side to move); `position` is left as it was.
function ChessRules.apply(position: Position, move: Move): Position
	local board = table.clone(position.Board)
	local piece = board[move.From]
	local color = position.Turn
	local captured = board[move.To]
	board[move.To] = if move.Promotion
		then (if color == "w" then move.Promotion else string.lower(move.Promotion))
		else piece
	board[move.From] = ""
	if move.EnPassant then
		local behind = ChessRules.index(ChessRules.fileOf(move.To), ChessRules.rankOf(move.From)) :: number
		board[behind] = ""
		captured = "p"
	end
	if move.Castle then
		for right, castle in CASTLES do
			if
				castle.King == move.From
				and castle.To == move.To
				and (color == "w") == (string.upper(right) == right)
			then
				board[castle.RookTo] = board[castle.RookFrom]
				board[castle.RookFrom] = ""
			end
		end
	end
	local castling = position.Castling
	for _, square in { move.From, move.To } do
		local lost = RIGHTS_LOST[square]
		if lost then
			for right in string.gmatch(lost, ".") do
				castling = string.gsub(castling, right, "")
			end
		end
	end
	if castling == "" then
		castling = "-"
	end
	local isPawn = string.upper(piece) == "P"
	return {
		Board = board,
		Turn = other(color),
		Castling = castling,
		EnPassant = if move.DoublePush then (move.From + move.To) // 2 else nil,
		Halfmove = if isPawn or captured ~= "" then 0 else position.Halfmove + 1,
		Fullmove = position.Fullmove + (if color == "b" then 1 else 0),
	}
end

-- Every legal move of the side to move.
function ChessRules.legalMoves(position: Position): { Move }
	local legal: { Move } = {}
	local color = position.Turn
	for _, move in pseudoMoves(position) do
		local after = ChessRules.apply(position, move)
		local king = kingSquare(after.Board, color)
		if king and not ChessRules.isAttacked(after.Board, king, other(color)) then
			table.insert(legal, move)
		end
	end
	return legal
end

-- The legal moves of the piece on `from`.
function ChessRules.movesFrom(position: Position, from: number): { Move }
	local moves: { Move } = {}
	for _, move in ChessRules.legalMoves(position) do
		if move.From == from then
			table.insert(moves, move)
		end
	end
	return moves
end

-- The legal move from `from` to `to` (with `promotion` when a pawn reaches the last rank), or nil.
function ChessRules.findMove(position: Position, from: number, to: number, promotion: string?): Move?
	for _, move in ChessRules.legalMoves(position) do
		if move.From == from and move.To == to and move.Promotion == promotion then
			return move
		end
	end
	return nil
end

-- "e2e4" (and the promotion piece, lower case: "e7e8q").
function ChessRules.notation(move: Move): string
	return ChessRules.name(move.From) .. ChessRules.name(move.To) .. string.lower(move.Promotion or "")
end

---------------------------------------------------------------------------------------------------------------------
-- The end of the game
---------------------------------------------------------------------------------------------------------------------

-- Whether `color` still has pieces that could ever checkmate (a pawn, rook or queen, or two minor pieces).
function ChessRules.canMate(board: { string }, color: string): boolean
	local minors = 0
	for _, piece in board do
		if piece ~= "" and ChessRules.colorOf(piece) == color then
			local kind = string.upper(piece)
			if kind == "P" or kind == "R" or kind == "Q" then
				return true
			elseif kind == "B" or kind == "N" then
				minors += 1
			end
		end
	end
	return minors >= 2
end

-- Neither side can checkmate: kings alone, a king and one bishop or knight against a king, or one bishop each on
-- squares of the same colour.
function ChessRules.insufficientMaterial(board: { string }): boolean
	local others: { number } = {}
	for index, piece in board do
		if piece ~= "" and string.upper(piece) ~= "K" then
			table.insert(others, index)
		end
	end
	if #others == 0 then
		return true
	elseif #others == 1 then
		local kind = string.upper(board[others[1]])
		return kind == "B" or kind == "N"
	elseif #others == 2 then
		local a, b = board[others[1]], board[others[2]]
		local shade = function(index: number): number
			return (ChessRules.fileOf(index) + ChessRules.rankOf(index)) % 2
		end
		return string.upper(a) == "B"
			and string.upper(b) == "B"
			and ChessRules.colorOf(a) ~= ChessRules.colorOf(b)
			and shade(others[1]) == shade(others[2])
	end
	return false
end

-- A key for threefold repetition: the pieces, the side to move, castling rights and a usable en passant square.
function ChessRules.key(position: Position): string
	local enPassant = "-"
	local square = position.EnPassant
	if square then
		for _, move in ChessRules.legalMoves(position) do
			if move.EnPassant then
				enPassant = ChessRules.name(square)
				break
			end
		end
	end
	return `{placement(position.Board)} {position.Turn} {position.Castling} {enPassant}`
end

--[[
	Whether the game is over in `position`: "Checkmate" (the side to move lost), "Stalemate", "Insufficient",
	"FiftyMoves" or "Repetition" (the current position's key appears 3 times in `history`, the keys of every
	position since the game began, the current one included); nil while it goes on.
]]
function ChessRules.outcome(position: Position, history: { string }?): string?
	if #ChessRules.legalMoves(position) == 0 then
		return if ChessRules.inCheck(position) then "Checkmate" else "Stalemate"
	elseif ChessRules.insufficientMaterial(position.Board) then
		return "Insufficient"
	elseif position.Halfmove >= 100 then
		return "FiftyMoves"
	end
	if history and #history > 0 then
		local current, seen = history[#history], 0
		for _, key in history do
			if key == current then
				seen += 1
			end
		end
		if seen >= 3 then
			return "Repetition"
		end
	end
	return nil
end

-- Counts the move paths `depth` moves deep (perft; for specs).
function ChessRules.perft(position: Position, depth: number): number
	if depth == 0 then
		return 1
	end
	local moves = ChessRules.legalMoves(position)
	if depth == 1 then
		return #moves
	end
	local total = 0
	for _, move in moves do
		total += ChessRules.perft(ChessRules.apply(position, move), depth - 1)
	end
	return total
end

return ChessRules
