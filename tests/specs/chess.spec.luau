--!strict
-- Chess at the lobby table (owner's fix list): the rules (checked against the standard perft counts) and the table's
-- game flow (clocks, results, draws, rematches).
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local ChessRules = Roblox.require(Roblox.game.ReplicatedStorage.Shared.ChessRules)
local ChessMatch = Roblox.require(Roblox.game.ReplicatedStorage.Shared.ChessMatch)

local chess = Config.World.Chess

local function perft(fen: string, depth: number): number
	return ChessRules.perft(ChessRules.fromFen(fen), depth)
end

-- Plays moves like "e2e4" (with an optional promotion letter) in `position`; fails on an illegal one.
local function play(position: any, moves: { string }): any
	for _, text in moves do
		local from, to = ChessRules.square(string.sub(text, 1, 2)), ChessRules.square(string.sub(text, 3, 4))
		local promotion = if #text > 4 then string.upper(string.sub(text, 5, 5)) else nil
		local move = ChessRules.findMove(position, from, to, promotion)
		expect.truthy(move, `{text} is legal`)
		position = ChessRules.apply(position, move)
	end
	return position
end

-- A table with both seats taken (White 11, Black 22) and a game started at time `t`.
local function game(t: number): any
	local match = ChessMatch.new()
	ChessMatch.seat(match, 1, 11, t)
	expect.equal(ChessMatch.seat(match, 2, 22, t), "Started")
	return match
end

return {
	["squares and FEN round-trip"] = function()
		expect.equal(ChessRules.square("a1"), 1)
		expect.equal(ChessRules.square("h8"), 64)
		expect.equal(ChessRules.square("e2"), 13)
		expect.equal(ChessRules.square("i9"), nil)
		expect.equal(ChessRules.name(13), "e2")
		expect.equal(ChessRules.toFen(ChessRules.new()), ChessRules.StartFen)
		local fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"
		expect.equal(ChessRules.toFen(ChessRules.fromFen(fen)), fen)
		expect.equal(
			ChessRules.toFen(play(ChessRules.new(), { "e2e4" })),
			"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
		)
	end,
	["perft: the start position"] = function()
		expect.equal(perft(ChessRules.StartFen, 1), 20)
		expect.equal(perft(ChessRules.StartFen, 2), 400)
		expect.equal(perft(ChessRules.StartFen, 3), 8902)
	end,
	["perft: castling, en passant and promotions (Kiwipete, positions 3, 4 and 5)"] = function()
		local kiwipete = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"
		expect.equal(perft(kiwipete, 1), 48)
		expect.equal(perft(kiwipete, 2), 2039)
		local three = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"
		expect.equal(perft(three, 1), 14)
		expect.equal(perft(three, 2), 191)
		expect.equal(perft(three, 3), 2812)
		local four = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"
		expect.equal(perft(four, 1), 6)
		expect.equal(perft(four, 2), 264)
		expect.equal(perft(four, 3), 9467)
		local five = "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8"
		expect.equal(perft(five, 1), 44)
		expect.equal(perft(five, 2), 1486)
	end,
	["special moves move the right pieces"] = function()
		-- Castling king side moves the rook to f1 and loses White's rights.
		local castled = play(ChessRules.fromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1"), { "e1g1" })
		expect.equal(castled.Board[ChessRules.square("g1")], "K")
		expect.equal(castled.Board[ChessRules.square("f1")], "R")
		expect.equal(castled.Board[ChessRules.square("h1")], "")
		expect.equal(castled.Castling, "kq")
		-- En passant removes the pawn that double-pushed past.
		local passant = play(ChessRules.new(), { "e2e4", "a7a6", "e4e5", "d7d5", "e5d6" })
		expect.equal(passant.Board[ChessRules.square("d5")], "")
		expect.equal(passant.Board[ChessRules.square("d6")], "P")
		-- Promotion needs the piece named.
		local promoting = ChessRules.fromFen("8/4P3/8/8/8/8/k7/4K3 w - - 0 1")
		expect.equal(ChessRules.findMove(promoting, ChessRules.square("e7"), ChessRules.square("e8"), nil), nil)
		expect.equal(play(promoting, { "e7e8n" }).Board[ChessRules.square("e8")], "N")
		-- Black promotes to a black piece.
		local black = play(ChessRules.fromFen("4k3/8/8/8/8/8/p7/4K3 b - - 0 1"), { "a2a1q" })
		expect.equal(black.Board[ChessRules.square("a1")], "q")
	end,
	["checkmate, stalemate and the draw rules"] = function()
		local mated = play(ChessRules.new(), { "f2f3", "e7e5", "g2g4", "d8h4" })
		expect.truthy(ChessRules.inCheck(mated), "in check")
		expect.equal(ChessRules.outcome(mated), "Checkmate")
		expect.equal(ChessRules.outcome(ChessRules.fromFen("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")), "Stalemate")
		expect.equal(ChessRules.outcome(ChessRules.fromFen("8/8/4k3/8/8/2B5/4K3/8 w - - 0 1")), "Insufficient")
		expect.equal(ChessRules.outcome(ChessRules.fromFen("8/8/4k3/8/8/2N5/4K3/8 w - - 0 1")), "Insufficient")
		expect.equal(ChessRules.outcome(ChessRules.fromFen("8/8/4k3/8/8/2R5/4K3/8 w - - 0 1")), nil)
		expect.equal(ChessRules.outcome(ChessRules.fromFen("8/8/4k3/8/8/2R5/4K3/8 w - - 100 80")), "FiftyMoves")
		expect.equal(ChessRules.canMate(ChessRules.fromFen("8/8/4k3/8/8/2B5/4K3/8 w - - 0 1").Board, "w"), false)
		expect.equal(ChessRules.canMate(ChessRules.fromFen("8/8/4k3/8/8/2BN4/4K3/8 w - - 0 1").Board, "w"), true)
	end,
	["a game: moves alternate, clocks run and gain the increment"] = function()
		local match = game(0)
		expect.equal(ChessMatch.toMove(match), 1)
		expect.equal((ChessMatch.move(match, 2, "e7", "e5", nil, 1)), false) -- not Black's turn
		expect.equal((ChessMatch.move(match, 1, "e2", "e5", nil, 1)), false) -- illegal
		expect.equal((ChessMatch.move(match, 1, "e2", "e4", nil, 10)), true)
		expect.equal(match.LastMove, "e2e4")
		expect.near(match.Clocks[1], chess.TimePerSide - 10 + chess.Increment)
		expect.near(ChessMatch.remaining(match, 2, 15), chess.TimePerSide - 5)
		expect.near(ChessMatch.remaining(match, 1, 15), chess.TimePerSide - 10 + chess.Increment)
		expect.equal(ChessMatch.toMove(match), 2)
	end,
	["a game ends by checkmate, resignation, time or leaving"] = function()
		local match = game(0)
		ChessMatch.move(match, 1, "f2", "f3", nil, 1)
		ChessMatch.move(match, 2, "e7", "e5", nil, 2)
		ChessMatch.move(match, 1, "g2", "g4", nil, 3)
		local _, event = ChessMatch.move(match, 2, "d8", "h4", nil, 4)
		expect.equal(event, "Finished")
		expect.equal(match.Result, "Checkmate")
		expect.equal(match.Winner, 2)
		expect.equal(match.State, "Over")

		match = game(0)
		expect.equal(ChessMatch.act(match, 1, "Resign", 5), "Finished")
		expect.equal(match.Winner, 2)
		expect.equal(match.Result, "Resigned")

		match = game(0)
		expect.equal(ChessMatch.tick(match, chess.TimePerSide - 1), nil)
		expect.equal(ChessMatch.tick(match, chess.TimePerSide), "Finished")
		expect.equal(match.Result, "Time")
		expect.equal(match.Winner, 2)

		match = game(0)
		match.Position = ChessRules.fromFen("8/8/4k3/8/8/2B5/4K3/8 b - - 0 1") -- Black's flag falls; White can't mate
		expect.equal(ChessMatch.tick(match, chess.TimePerSide), "Finished")
		expect.equal(match.Winner, 0)

		match = game(0)
		expect.equal(ChessMatch.seat(match, 2, 0, 5), "Finished")
		expect.equal(match.Result, "Left")
		expect.equal(match.Winner, 1)
	end,
	["draw offers: accepted, or lapsing when the other side moves"] = function()
		local match = game(0)
		expect.equal(ChessMatch.act(match, 2, "AcceptDraw", 1), nil) -- nothing to accept
		ChessMatch.act(match, 1, "OfferDraw", 1)
		expect.equal(match.DrawOffer, 1)
		expect.equal(ChessMatch.act(match, 1, "AcceptDraw", 2), nil) -- not your own offer
		ChessMatch.move(match, 1, "e2", "e4", nil, 2)
		expect.equal(match.DrawOffer, 1) -- still open: Black hasn't answered
		ChessMatch.move(match, 2, "e7", "e5", nil, 3)
		expect.equal(match.DrawOffer, 0) -- Black moved instead
		ChessMatch.act(match, 2, "OfferDraw", 4)
		expect.equal(ChessMatch.act(match, 1, "AcceptDraw", 5), "Finished")
		expect.equal(match.Result, "Agreed")
		expect.equal(match.Winner, 0)
	end,
	["threefold repetition is a draw"] = function()
		local match = game(0)
		local t = 0
		for _ = 1, 2 do
			for _, move in { { 1, "g1", "f3" }, { 2, "g8", "f6" }, { 1, "f3", "g1" }, { 2, "f6", "g8" } } do
				t += 1
				ChessMatch.move(match, move[1], move[2], move[3], nil, t)
			end
		end
		expect.equal(match.Result, "Repetition")
		expect.equal(match.Winner, 0)
	end,
	["after a game: a rematch if both stay, otherwise the table waits"] = function()
		local match = game(0)
		ChessMatch.act(match, 2, "Resign", 1)
		expect.equal(ChessMatch.tick(match, 1 + chess.NewGameDelay - 0.1), nil)
		expect.equal(ChessMatch.tick(match, 1 + chess.NewGameDelay), "Started")
		expect.equal(match.State, "Playing")
		expect.equal(ChessRules.toFen(match.Position), ChessRules.StartFen)
		ChessMatch.act(match, 1, "Resign", 50)
		ChessMatch.seat(match, 2, 0, 51)
		expect.equal(match.State, "Over")
		ChessMatch.tick(match, 50 + chess.NewGameDelay)
		expect.equal(match.State, "Waiting")
		expect.equal(ChessMatch.seat(match, 2, 33, 70), "Started")
	end,
}
