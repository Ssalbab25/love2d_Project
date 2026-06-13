local test_Bishop = {}
local Board = require "src.Board"
local Bishop = require "src.pieces.Bishop"
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

function test_Bishop.run()
    print("  -> test_Bishop 시작...")
    
    -- 1. 빈 보드에서 비숍의 대각선 4방향 이동 검증 (중앙 (4, 4) 배치 시)
    do
        local board = Board()
        local bishop = Bishop("white")
        board:setPiece(4, 4, bishop)
        
        local moves = bishop:getValidMoves(board, {row = 4, col = 4})
        
        -- 대각선 총 13칸 이동 가능해야 함
        assert(#moves == 13, "빈 보드 중앙의 비숍은 13개의 이동이 가능해야 합니다. 실제: " .. tostring(#moves))
        
        -- 임의의 유효 좌표 검사
        assert(hasMove(moves, 1, 1), "대각선 왼쪽 위 끝으로 이동 가능해야 합니다.")
        assert(hasMove(moves, 1, 7), "대각선 오른쪽 위 끝으로 이동 가능해야 합니다.")
        assert(hasMove(moves, 7, 1), "대각선 왼쪽 아래 끝으로 이동 가능해야 합니다.")
        assert(hasMove(moves, 8, 8), "대각선 오른쪽 아래 끝으로 이동 가능해야 합니다.")
        assert(not hasMove(moves, 4, 3), "가로로는 이동 불가능해야 합니다.")
    end

    -- 2. 아군 기물에 의한 가로막힘 검증
    do
        local board = Board()
        local bishop = Bishop("white")
        local ally = Pawn("white")
        
        board:setPiece(4, 4, bishop)
        board:setPiece(2, 6, ally) -- 대각선 오른쪽 위 2칸 앞(2, 6)에 아군 배치
        
        local moves = bishop:getValidMoves(board, {row = 4, col = 4})
        
        -- (3, 5)는 가능하지만, (2, 6) 및 (1, 7)은 불가능해야 함
        assert(hasMove(moves, 3, 5), "(3, 5)는 이동 가능해야 합니다.")
        assert(not hasMove(moves, 2, 6), "아군 기물이 있는 (2, 6)은 이동 불가능해야 합니다.")
        assert(not hasMove(moves, 1, 7), "아군 기물 뒤인 (1, 7)은 이동 불가능해야 합니다.")
    end

    -- 3. 적군 기물 포획 및 뒤쪽 차단 검증
    do
        local board = Board()
        local bishop = Bishop("white")
        local enemy = Pawn("black")
        
        board:setPiece(4, 4, bishop)
        board:setPiece(6, 2, enemy) -- 대각선 왼쪽 아래 2칸 앞(6, 2)에 적군 배치
        
        local moves = bishop:getValidMoves(board, {row = 4, col = 4})
        
        -- (5, 3)과 (6, 2)는 가능해야 하지만, (7, 1)은 불가능해야 함
        assert(hasMove(moves, 5, 3), "(5, 3)은 이동 가능해야 합니다.")
        assert(hasMove(moves, 6, 2), "적군 기물이 있는 (6, 2)는 포획 이동 가능해야 합니다.")
        assert(not hasMove(moves, 7, 1), "적군 기물 뒤인 (7, 1)은 이동 불가능해야 합니다.")
    end

    print("  -> test_Bishop 모든 검증 완료.")
end

return test_Bishop
