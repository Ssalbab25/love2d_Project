local test_Queen = {}
local Board = require "src.Board"
local Queen = require "src.pieces.Queen"
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

function test_Queen.run()
    print("  -> test_Queen 시작...")
    
    -- 1. 빈 보드에서 퀸의 8방향 무제한 이동 검증 (중앙 (4, 4) 배치 시)
    do
        local board = Board()
        local queen = Queen("white")
        board:setPiece(4, 4, queen)
        
        local moves = queen:getValidMoves(board, {row = 4, col = 4})
        
        -- 가로세로 14칸 + 대각선 13칸 = 총 27칸 이동 가능해야 함
        assert(#moves == 27, "빈 보드 중앙의 퀸은 27개의 이동이 가능해야 합니다. 실제: " .. tostring(#moves))
        
        -- 임의의 좌표 검증
        assert(hasMove(moves, 4, 1), "가로 왼쪽 끝 이동 가능해야 합니다.")
        assert(hasMove(moves, 1, 4), "세로 위쪽 끝 이동 가능해야 합니다.")
        assert(hasMove(moves, 1, 1), "대각선 왼쪽 위 끝 이동 가능해야 합니다.")
        assert(hasMove(moves, 8, 8), "대각선 오른쪽 아래 끝 이동 가능해야 합니다.")
    end

    -- 2. 아군 기물 차단 및 적군 포획 검증
    do
        local board = Board()
        local queen = Queen("white")
        local ally = Pawn("white")
        local enemy = Pawn("black")
        
        board:setPiece(4, 4, queen)
        board:setPiece(4, 6, ally)  -- 오른쪽 2칸 앞(4, 6) 아군
        board:setPiece(2, 2, enemy) -- 대각선 왼쪽 위 2칸 앞(2, 2) 적군
        
        local moves = queen:getValidMoves(board, {row = 4, col = 4})
        
        -- 아군 차단
        assert(hasMove(moves, 4, 5), "(4, 5)는 가능해야 합니다.")
        assert(not hasMove(moves, 4, 6), "아군 기물이 있는 (4, 6)은 불가해야 합니다.")
        assert(not hasMove(moves, 4, 7), "아군 기물 뒤인 (4, 7)은 불가해야 합니다.")
        
        -- 적군 포획
        assert(hasMove(moves, 3, 3), "(3, 3)은 가능해야 합니다.")
        assert(hasMove(moves, 2, 2), "적군 기물이 있는 (2, 2)는 포획 가능해야 합니다.")
        assert(not hasMove(moves, 1, 1), "적군 기물 뒤인 (1, 1)은 불가해야 합니다.")
    end

    print("  -> test_Queen 모든 검증 완료.")
end

return test_Queen
