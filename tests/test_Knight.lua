local test_Knight = {}
local Board = require "src.Board"
local Knight = require "src.pieces.Knight"
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

function test_Knight.run()
    print("  -> test_Knight 시작...")
    
    -- 1. 빈 보드에서 나이트의 L자 8방향 이동 검증 (중앙 (4, 4) 배치 시)
    do
        local board = Board()
        local knight = Knight("white")
        board:setPiece(4, 4, knight)
        
        local moves = knight:getValidMoves(board, {row = 4, col = 4})
        
        -- 총 8칸 이동 가능해야 함
        assert(#moves == 8, "빈 보드 중앙의 나이트는 8개의 이동이 가능해야 합니다. 실제: " .. tostring(#moves))
        
        -- 모든 8개 위치 검사
        local expectedMoves = {
            {2, 3}, {2, 5}, {3, 2}, {3, 6},
            {5, 2}, {5, 6}, {6, 3}, {6, 5}
        }
        for _, exp in ipairs(expectedMoves) do
            assert(hasMove(moves, exp[1], exp[2]), "나이트는 ("..exp[1]..","..exp[2]..")로 이동 가능해야 합니다.")
        end
        assert(not hasMove(moves, 4, 5), "일반 직선 방향은 불가능해야 합니다.")
    end

    -- 2. 아군 기물 차단 및 적군 포획 검증
    do
        local board = Board()
        local knight = Knight("white")
        local ally = Pawn("white")
        local enemy = Pawn("black")
        
        board:setPiece(4, 4, knight)
        board:setPiece(2, 3, ally)  -- 목적지 중 하나에 아군 배치
        board:setPiece(2, 5, enemy) -- 목적지 중 하나에 적군 배치
        
        local moves = knight:getValidMoves(board, {row = 4, col = 4})
        
        assert(not hasMove(moves, 2, 3), "아군 기물이 있는 (2, 3)은 이동 불가능해야 합니다.")
        assert(hasMove(moves, 2, 5), "적군 기물이 있는 (2, 5)는 포획 이동 가능해야 합니다.")
    end

    -- 3. 장애물 뛰어넘기 검증
    do
        local board = Board()
        local knight = Knight("white")
        local barrier1 = Pawn("white")
        local barrier2 = Pawn("black")
        
        board:setPiece(4, 4, knight)
        -- 나이트가 (2, 3)으로 뛰는 경로 상의 위치인 (3, 4), (3, 3) 등에 기물이 가로막고 있어도 목적지인 (2, 3)이 비어있다면 가야 함
        board:setPiece(3, 4, barrier1)
        board:setPiece(3, 3, barrier2)
        
        local moves = knight:getValidMoves(board, {row = 4, col = 4})
        
        assert(hasMove(moves, 2, 3), "경로 상에 기물이 존재해도 나이트는 (2, 3)으로 뛰어넘어 이동 가능해야 합니다.")
    end

    print("  -> test_Knight 모든 검증 완료.")
end

return test_Knight
