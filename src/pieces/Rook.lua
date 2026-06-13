-- Rook.lua: 룩 기물의 행마 및 상태 클래스
-- SOLID: 
-- - OCP (개방-폐쇄 원칙): Piece 추상 클래스를 상속받아 기존 코드를 수정하지 않고 Rook 고유의 getValidMoves를 확장 구현합니다.
-- - LSP (리스코프 치환 원칙): 부모 Piece와 동일하게 getValidMoves가 { {row = r, col = c}, ... } 구조의 배열을 일관되게 반환합니다.
-- - SRP (단일 책임 원칙): 오직 룩 기물의 고유 속성 및 이동 규칙 계산의 책임만 가집니다.

local Piece = require "src.pieces.Piece"
local Rook = Piece:extend()

function Rook:new(color)
    Rook.super.new(self, color, "rook")
end

-- 룩의 행마 가능 좌표 리스트 계산
-- board: Board 객체
-- currentPos: {row = r, col = c} 형태
-- 반환값: { {row = r, col = c}, ... } 형태
function Rook:getValidMoves(board, currentPos)
    local moves = {}
    local r = currentPos.row
    local c = currentPos.col
    
    -- 4방향 정의 (상, 하, 좌, 우)
    local directions = {
        { dr = -1, dc = 0 },  -- 위
        { dr = 1,  dc = 0 },  -- 아래
        { dr = 0,  dc = -1 }, -- 왼쪽
        { dr = 0,  dc = 1 }   -- 오른쪽
    }
    
    for _, dir in ipairs(directions) do
        local step = 1
        while true do
            local nextRow = r + dir.dr * step
            local nextCol = c + dir.dc * step
            
            -- 보드 경계 검사
            if nextRow < 1 or nextRow > 8 or nextCol < 1 or nextCol > 8 then
                break
            end
            
            local target = board:getPiece(nextRow, nextCol)
            if target == nil then
                -- 빈 칸이면 이동 가능 및 계속 전진
                table.insert(moves, {row = nextRow, col = nextCol})
            else
                -- 기물이 있는 경우
                if target.color ~= self.color then
                    -- 적군 기물이면 포획 가능 (이동 목록에 추가 후 중단)
                    table.insert(moves, {row = nextRow, col = nextCol})
                end
                -- 아군이든 적군이든 기물과 충돌하면 해당 방향은 더 이상 갈 수 없음
                break
            end
            
            step = step + 1
        end
    end
    
    return moves
end

return Rook
