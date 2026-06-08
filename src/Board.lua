-- Board.lua: 보드 데이터 및 기물 위치 상태 관리 클래스
-- SOLID: SRP를 준수하여 오직 체스판의 데이터(2차원 배열) 상태만 관리합니다.
--        렌더링이나 규칙 연산은 분리되어 있습니다.

local Object = require "libs.classic"
local Board = Object:extend()

function Board:new()
    self.grid = {}
    for r = 1, 8 do
        self.grid[r] = {}
        for c = 1, 8 do
            self.grid[r][c] = nil -- 초기에는 모든 칸이 비어 있음
        end
    end
end

-- 특정 위치에 기물 배치
function Board:setPiece(row, col, piece)
    if row >= 1 and row <= 8 and col >= 1 and col <= 8 then
        self.grid[row][col] = piece
    end
end

-- 특정 위치의 기물 획득
function Board:getPiece(row, col)
    if row >= 1 and row <= 8 and col >= 1 and col <= 8 then
        return self.grid[row][col]
    end
    return nil
end

return Board
