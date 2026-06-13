local test_Board = {}
local Board = require "src.Board"

function test_Board.run()
    local board = Board()
    assert(board ~= nil, "Board 객체가 생성되지 않았습니다.")
    
    -- 8x8 격자 크기 및 초기 nil 상태 검증
    assert(board.grid ~= nil, "board.grid 테이블이 존재하지 않습니다.")
    assert(#board.grid == 8, "보드의 행 크기가 8이 아닙니다. 실제 크기: " .. tostring(#board.grid))
    
    for r = 1, 8 do
        assert(type(board.grid[r]) == "table", string.format("%d번째 행이 테이블이 아닙니다.", r))
        for c = 1, 8 do
            assert(board.grid[r][c] == nil, string.format("초기화 검증 실패: (%d, %d) 칸이 nil이 아닙니다.", r, c))
        end
    end
    -- setupPieces() 호출 후 표준 배치 상태 검증
    board:setupPieces()
    
    -- 3~6행은 완전히 비어 있어야 함
    for r = 3, 6 do
        for c = 1, 8 do
            assert(board:getPiece(r, c) == nil, string.format("setupPieces 오류: 비어 있어야 할 (%d, %d) 칸에 기물이 있습니다.", r, c))
        end
    end
    
    -- 2행과 7행은 모두 Pawn이어야 함
    for c = 1, 8 do
        local blackPawn = board:getPiece(2, c)
        assert(blackPawn ~= nil and blackPawn.type == "pawn" and blackPawn.color == "black", string.format("setupPieces 오류: (%d, %d) 칸에 흑색 폰이 없습니다.", 2, c))
        
        local whitePawn = board:getPiece(7, c)
        assert(whitePawn ~= nil and whitePawn.type == "pawn" and whitePawn.color == "white", string.format("setupPieces 오류: (%d, %d) 칸에 백색 폰이 없습니다.", 7, c))
    end
    
    -- 주요 특정 기물 타입 및 색상 검증
    local wr1 = board:getPiece(8, 1)
    assert(wr1 ~= nil and wr1.type == "rook" and wr1.color == "white", "setupPieces 오류: a1(8, 1)에 백색 룩이 없습니다.")
    
    local bk = board:getPiece(1, 5)
    assert(bk ~= nil and bk.type == "king" and bk.color == "black", "setupPieces 오류: e8(1, 5)에 흑색 킹이 없습니다.")
    
    local wq = board:getPiece(8, 4)
    assert(wq ~= nil and wq.type == "queen" and wq.color == "white", "setupPieces 오류: d1(8, 4)에 백색 퀸이 없습니다.")

    print("  -> Board 초기화 및 격자 크기 검증 완료.")
    print("  -> Board setupPieces() 표준 배치 검증 완료.")
end

return test_Board
