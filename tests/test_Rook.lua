local test_Rook = {}
local Board = require "src.Board"
local Rook = require "src.pieces.Rook"
local Pawn = require "src.pieces.Pawn"

-- 헬퍼 함수: 특정 좌표가 이동 목록에 존재하는지 검사
local function hasMove(moves, r, c)
    for _, move in ipairs(moves) do
        if move.row == r and move.col == c then
            return true
        end
    end
    return false
end

function test_Rook.run()
    print("  -> test_Rook 시작...")
    
    -- 1. 빈 보드에서 룩의 4방향 이동 검증 (중앙 (4, 4) 배치 시)
    do
        local board = Board()
        local rook = Rook("white")
        board:setPiece(4, 4, rook)
        
        local moves = rook:getValidMoves(board, {row = 4, col = 4})
        
        -- 가로 7칸, 세로 7칸 = 총 14칸 이동 가능해야 함
        assert(#moves == 14, "빈 보드 중앙의 룩은 14개의 이동이 가능해야 합니다. 실제: " .. tostring(#moves))
        
        -- 임의의 유효 좌표 검사
        assert(hasMove(moves, 4, 1), "가로 왼쪽 끝으로 이동 가능해야 합니다.")
        assert(hasMove(moves, 4, 8), "가로 오른쪽 끝으로 이동 가능해야 합니다.")
        assert(hasMove(moves, 1, 4), "세로 위쪽 끝으로 이동 가능해야 합니다.")
        assert(hasMove(moves, 8, 4), "세로 아래쪽 끝으로 이동 가능해야 합니다.")
        assert(not hasMove(moves, 3, 3), "대각선으로는 이동 불가능해야 합니다.")
    end

    -- 2. 아군 기물에 의한 가로막힘 검증
    do
        local board = Board()
        local rook = Rook("white")
        local ally = Pawn("white")
        
        board:setPiece(4, 4, rook)
        board:setPiece(4, 6, ally) -- 오른쪽 2칸 앞(4, 6)에 아군 배치
        
        local moves = rook:getValidMoves(board, {row = 4, col = 4})
        
        -- (4, 5)는 가능하지만, (4, 6), (4, 7), (4, 8)은 불가능해야 함
        assert(hasMove(moves, 4, 5), "(4, 5)는 이동 가능해야 합니다.")
        assert(not hasMove(moves, 4, 6), "아군 기물이 있는 (4, 6)은 이동 불가능해야 합니다.")
        assert(not hasMove(moves, 4, 7), "아군 기물 뒤인 (4, 7)은 이동 불가능해야 합니다.")
        assert(not hasMove(moves, 4, 8), "아군 기물 뒤인 (4, 8)은 이동 불가능해야 합니다.")
    end

    -- 3. 적군 기물 포획 및 뒤쪽 차단 검증
    do
        local board = Board()
        local rook = Rook("white")
        local enemy = Pawn("black")
        
        board:setPiece(4, 4, rook)
        board:setPiece(2, 4, enemy) -- 위쪽 2칸 앞(2, 4)에 적군 배치
        
        local moves = rook:getValidMoves(board, {row = 4, col = 4})
        
        -- (3, 4)와 (2, 4)는 가능해야 하지만, (1, 4)는 불가능해야 함
        assert(hasMove(moves, 3, 4), "(3, 4)는 이동 가능해야 합니다.")
        assert(hasMove(moves, 2, 4), "적군 기물이 있는 (2, 4)는 포획 이동 가능해야 합니다.")
        assert(not hasMove(moves, 1, 4), "적군 기물 뒤인 (1, 4)는 이동 불가능해야 합니다.")
    end

    print("  -> test_Rook 모든 검증 완료.")
end

return test_Rook
