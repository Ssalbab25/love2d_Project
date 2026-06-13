local test_King = {}
local Board = require "src.Board"
local King = require "src.pieces.King"
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

function test_King.run()
    print("  -> test_King 시작...")
    
    -- 1. 빈 보드에서 킹의 8방향 1칸 이동 검증 (중앙 (4, 4) 배치 시)
    do
        local board = Board()
        local king = King("white")
        board:setPiece(4, 4, king)
        
        local moves = king:getValidMoves(board, {row = 4, col = 4})
        
        -- 총 8칸 이동 가능해야 함
        assert(#moves == 8, "빈 보드 중앙의 킹은 8개의 이동이 가능해야 합니다. 실제: " .. tostring(#moves))
        
        -- 8방향 1칸 좌표 검사
        local expectedMoves = {
            {3, 3}, {3, 4}, {3, 5},
            {4, 3},         {4, 5},
            {5, 3}, {5, 4}, {5, 5}
        }
        for _, exp in ipairs(expectedMoves) do
            assert(hasMove(moves, exp[1], exp[2]), "킹은 ("..exp[1]..","..exp[2]..")로 이동 가능해야 합니다.")
        end
        
        assert(not hasMove(moves, 4, 6), "2칸 멀리 떨어진 곳으로는 이동할 수 없어야 합니다.")
    end

    -- 2. 아군 기물 차단 및 적군 포획 검증
    do
        local board = Board()
        local king = King("white")
        local ally = Pawn("white")
        local enemy = Pawn("black")
        
        board:setPiece(4, 4, king)
        board:setPiece(3, 4, ally)  -- 바로 위(3, 4) 아군
        board:setPiece(3, 3, enemy) -- 왼쪽 위(3, 3) 적군
        
        local moves = king:getValidMoves(board, {row = 4, col = 4})
        
        assert(not hasMove(moves, 3, 4), "아군 기물이 있는 (3, 4)는 이동할 수 없어야 합니다.")
        assert(hasMove(moves, 3, 3), "적군 기물이 있는 (3, 3)은 포획 이동 가능해야 합니다.")
    end

    print("  -> test_King 모든 검증 완료.")
end

return test_King
