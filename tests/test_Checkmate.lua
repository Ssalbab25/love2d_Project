local test_Checkmate = {}

local Game = require "src.Game"
local Board = require "src.Board"
local King = require "src.pieces.King"
local Rook = require "src.pieces.Rook"
local Queen = require "src.pieces.Queen"
local Bishop = require "src.pieces.Bishop"
local Pawn = require "src.pieces.Pawn"

local function hasMove(moves, r, c)
    for _, m in ipairs(moves) do
        if m.row == r and m.col == c then
            return true
        end
    end
    return false
end

function test_Checkmate.run()
    print("  -> test_Checkmate 시작...")

    -- 1. Board:findKing 검증
    do
        local board = Board()
        local whiteKing = King("white")
        local blackKing = King("black")
        
        board:setPiece(4, 5, whiteKing)
        board:setPiece(1, 1, blackKing)
        
        local wr, wc = board:findKing("white")
        local br, bc = board:findKing("black")
        
        assert(wr == 4 and wc == 5, "백색 킹 위치 탐색 실패")
        assert(br == 1 and bc == 1, "흑색 킹 위치 탐색 실패")
    end

    -- 2. Board:isInCheck 검증 (Rook의 직접 공격)
    do
        local board = Board()
        local whiteKing = King("white")
        local blackRook = Rook("black")
        
        board:setPiece(8, 5, whiteKing)
        board:setPiece(2, 5, blackRook) -- 동일한 5열 배치 (체크 상태)
        
        assert(board:isInCheck("white") == true, "킹이 동일 열의 룩에게 체크당하고 있음을 감지해야 합니다.")
        
        -- 룩 위치 변경 (공격 해제)
        board:setPiece(2, 5, nil)
        board:setPiece(2, 6, blackRook) -- 다른 열 배치
        assert(board:isInCheck("white") == false, "킹이 위협에 벗어났을 때 체크가 아니어야 합니다.")
    end

    -- 3. Game:getLegalMoves 검증 (체크 시 킹을 보호하지 않는 수 필터링)
    do
        local game = Game()
        -- 보드 초기화 비우기
        game.board = Board()
        
        local whiteKing = King("white")
        local whiteRook = Rook("white")
        local blackQueen = Queen("black")
        
        game.board:setPiece(8, 5, whiteKing)
        game.board:setPiece(8, 1, whiteRook) -- 백색 룩 (체크와 상관없는 위치)
        game.board:setPiece(2, 5, blackQueen) -- 흑색 퀸이 백색 킹을 직접 체크 중
        
        -- 백색 룩의 일반 이동 목록에는 많은 수(8행의 좌우 이동 등)가 있지만,
        -- 이들은 킹을 보호(체크 해제)하지 못하므로 합법적 수 목록에서 0개로 필터링되어야 함.
        local rookMoves = game:getLegalMoves(whiteRook, {row = 8, col = 1})
        assert(#rookMoves == 0, "체크 상황에서 킹을 보호하지 못하는 룩의 이동은 전부 차단되어야 합니다. 실제 개수: " .. #rookMoves)
        
        -- 만약 백색 룩이 퀸의 공격 경로를 가로막을 수 있는 위치(예: 4, 1에서 4, 5로 이동)에 있다면
        -- 5열로 진입하는 이동은 허용되어야 함.
        game.board:setPiece(8, 1, nil)
        game.board:setPiece(4, 1, whiteRook)
        
        local rookMoves2 = game:getLegalMoves(whiteRook, {row = 4, col = 1})
        assert(#rookMoves2 > 0, "공격 경로를 가로막을 수 있는 이동은 유효해야 합니다.")
        assert(hasMove(rookMoves2, 4, 5), "룩은 (4, 5)로 이동하여 체크를 차단할 수 있어야 합니다.")
    end

    -- 4. Game:isCheckmate 검증 (피할 곳 없는 체크메이트 상태)
    do
        local game = Game()
        game.board = Board()
        
        local whiteKing = King("white")
        local blackQueen = Queen("black")
        local blackBishop = Bishop("black")
        
        -- 백색 킹을 구석에 배치
        game.board:setPiece(8, 8, whiteKing)
        -- 흑색 퀸을 바로 코앞(7, 8)에 배치하여 직접 체크
        game.board:setPiece(7, 8, blackQueen)
        -- 흑색 비숍이 퀸을 지키도록 배치 (킹이 퀸을 직접 잡을 수 없게 함)
        game.board:setPiece(5, 6, blackBishop) -- 비숍이 대각선으로 (7, 8) 보호
        
        -- 백색 킹의 탈출로 검사:
        -- (8, 7): 퀸(7, 8)의 공격 범위 내
        -- (7, 7): 퀸(7, 8)의 공격 범위 내
        -- (7, 8): 비숍이 지키고 있어 잡을 수 없음
        assert(game:isCheckmate("white") == true, "체크메이트 상태가 올바르게 감지되어야 합니다.")
        
        -- 만약 백색 룩을 추가해서 퀸을 잡을 수 있다면 체크메이트가 풀려야 함
        local whiteRook = Rook("white")
        game.board:setPiece(7, 1, whiteRook) -- (7, 1)에서 (7, 8)의 퀸 저격 가능
        
        assert(game:isCheckmate("white") == false, "아군 기물이 체크 원인 기물을 잡을 수 있다면 체크메이트가 아니어야 합니다.")
    end

    print("  -> test_Checkmate 모든 검증 완료.")
end

return test_Checkmate
