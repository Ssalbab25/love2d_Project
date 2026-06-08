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
    print("  -> Board 초기화 및 격자 크기 검증 완료.")
end

return test_Board
