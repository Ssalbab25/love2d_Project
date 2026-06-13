-- Knight.lua: 나이트 기물의 행마 및 상태 클래스
-- SOLID: 
-- - OCP (개방-폐쇄 원칙): Piece 추상 클래스를 상속받아 기존 코드를 수정하지 않고 Knight 고유의 getValidMoves를 확장 구현합니다.
-- - LSP (리스코프 치환 원칙): 부모 Piece와 동일하게 getValidMoves가 { {row = r, col = c}, ... } 구조의 배열을 일관되게 반환합니다.
-- - SRP (단일 책임 원칙): 오직 나이트 기물의 고유 속성 및 이동 규칙 계산의 책임만 가집니다.

local Piece = require "src.pieces.Piece"
local Knight = Piece:extend()

function Knight:new(color)
    Knight.super.new(self, color, "knight")
end

-- 나이트의 행마 가능 좌표 리스트 계산
-- board: Board 객체
-- currentPos: {row = r, col = c} 형태
-- 반환값: { {row = r, col = c}, ... } 형태
function Knight:getValidMoves(board, currentPos)
    local moves = {}
    local r = currentPos.row
    local c = currentPos.col
    
    -- L자 8방향 오프셋 정의
    local offsets = {
        { dr = -2, dc = -1 },
        { dr = -2, dc = 1 },
        { dr = -1, dc = -2 },
        { dr = -1, dc = 2 },
        { dr = 1,  dc = -2 },
        { dr = 1,  dc = 2 },
        { dr = 2,  dc = -1 },
        { dr = 2,  dc = 1 }
    }
    
    for _, offset in ipairs(offsets) do
        local nextRow = r + offset.dr
        local nextCol = c + offset.dc
        
        -- 보드 경계 내에 있을 때만 검사
        if nextRow >= 1 and nextRow <= 8 and nextCol >= 1 and nextCol <= 8 then
            local target = board:getPiece(nextRow, nextCol)
            if target == nil then
                -- 빈 칸이면 이동 가능
                table.insert(moves, {row = nextRow, col = nextCol})
            else
                -- 기물이 있는 경우, 아군 기물이 아니면(적군 기물) 포획 이동 가능
                if target.color ~= self.color then
                    table.insert(moves, {row = nextRow, col = nextCol})
                end
            end
        end
    end
    
    return moves
end

return Knight
