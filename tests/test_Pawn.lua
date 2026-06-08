local test_Pawn = {}
local Board = require "src.Board"
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

function test_Pawn.run()
    print("  -> test_Pawn 시작...")
    
    -- 1. 기본 첫 턴 2칸 전진 및 1칸 전진 검증 (White 폰)
    do
        local board = Board()
        local pawn = Pawn("white")
        board:setPiece(7, 4, pawn) -- d2(7,4)에 White 폰 배치
        
        local moves = pawn:getValidMoves(board, {row = 7, col = 4})
        
        assert(#moves == 2, "첫 턴 White 폰의 이동 가능한 수는 2개여야 합니다. 실제 개수: " .. tostring(#moves))
        assert(hasMove(moves, 6, 4), "White 폰은 1칸 전진할 수 있어야 합니다 (6, 4).")
        assert(hasMove(moves, 5, 4), "White 폰은 첫 턴에 2칸 전진할 수 있어야 합니다 (5, 4).")
    end

    -- 2. 첫 이동 이후 1칸만 전진 가능 여부 검증 (hasMoved = true)
    do
        local board = Board()
        local pawn = Pawn("white")
        pawn.hasMoved = true -- 이미 한 번 이동한 상태로 설정
        board:setPiece(6, 4, pawn)
        
        local moves = pawn:getValidMoves(board, {row = 6, col = 4})
        
        assert(#moves == 1, "한 번 이동한 White 폰의 이동 가능한 수는 1개여야 합니다. 실제 개수: " .. tostring(#moves))
        assert(hasMove(moves, 5, 4), "White 폰은 1칸만 전진할 수 있어야 합니다 (5, 4).")
        assert(not hasMove(moves, 4, 4), "한 번 이동한 White 폰은 2칸 전진할 수 없어야 합니다.")
    end

    -- 3. 전방 기물 차단 검증
    do
        local board = Board()
        local pawn = Pawn("white")
        local blocker = Pawn("black") -- 앞을 가로막을 흑색 폰
        
        board:setPiece(7, 4, pawn)
        board:setPiece(6, 4, blocker) -- 바로 앞 칸(6, 4) 차단
        
        local moves = pawn:getValidMoves(board, {row = 7, col = 4})
        assert(#moves == 0, "바로 앞 칸이 막히면 폰은 전혀 전진할 수 없어야 합니다. 실제 개수: " .. tostring(#moves))
        
        -- 2칸 앞 칸만 막힌 경우 검사
        board:setPiece(6, 4, nil) -- 1칸 앞 비움
        board:setPiece(5, 4, blocker) -- 2칸 앞(5, 4) 차단
        
        local moves2 = pawn:getValidMoves(board, {row = 7, col = 4})
        assert(#moves2 == 1, "2칸 앞 칸이 막히면 1칸만 전진할 수 있어야 합니다. 실제 개수: " .. tostring(#moves2))
        assert(hasMove(moves2, 6, 4), "1칸 앞(6, 4) 전진이 가능해야 합니다.")
        assert(not hasMove(moves2, 5, 4), "2칸 앞(5, 4) 전진은 차단되어야 합니다.")
    end

    -- 4. 대각선 공격 검증 (적군 공격 허용, 아군 공격 불가, 빈 칸 이동 불가)
    do
        local board = Board()
        local pawn = Pawn("white")
        local enemy = Pawn("black")
        local ally = Pawn("white")
        
        board:setPiece(7, 4, pawn)
        board:setPiece(6, 3, enemy) -- 대각선 왼쪽 앞 (6, 3) 에 적 배치
        board:setPiece(6, 5, ally)  -- 대각선 오른쪽 앞 (6, 5) 에 아군 배치
        
        local moves = pawn:getValidMoves(board, {row = 7, col = 4})
        
        -- 가능한 수: 1칸 전진(6,4), 2칸 전진(5,4), 대각선 왼쪽 적 잡기(6,3) -> 총 3개
        assert(#moves == 3, "적군 1명 포획 가능 시 가능한 수는 총 3개여야 합니다. 실제 개수: " .. tostring(#moves))
        assert(hasMove(moves, 6, 3), "대각선 왼쪽의 적군을 잡을 수 있어야 합니다 (6, 3).")
        assert(not hasMove(moves, 6, 5), "대각선 오른쪽의 아군은 잡을 수 없어야 합니다 (6, 5).")
    end

    -- 5. 후퇴 불가 검증 (White 폰은 row가 늘어나는 아래 방향으로 갈 수 없음)
    do
        local board = Board()
        local pawn = Pawn("white")
        board:setPiece(5, 4, pawn)
        
        local moves = pawn:getValidMoves(board, {row = 5, col = 4})
        assert(not hasMove(moves, 6, 4), "White 폰은 뒤로 후퇴할 수 없어야 합니다 (6, 4).")
    end

    print("  -> test_Pawn 모든 검증 완료.")
end

return test_Pawn
