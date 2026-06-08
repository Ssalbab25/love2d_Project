-- Pawn.lua: 폰 기물의 행마 및 상태 클래스
-- SOLID: OCP를 준수하여 부모인 Piece를 확장하고, 폰 고유의 getValidMoves()를 구현합니다.
--        LSP를 준수하여 반환값 좌표 리스트 구조를 일관성 있게 유지합니다.

local Piece = require "src.pieces.Piece"
local Pawn = Piece:extend()

function Pawn:new(color)
    Pawn.super.new(self, color, "pawn")
end

-- 폰 고유의 행마 가능 좌표 리스트 계산
-- board: Board 객체
-- currentPos: {row = r, col = c} 형태
-- 반환값: { {row, col}, ... } 형태
function Pawn:getValidMoves(board, currentPos)
    local moves = {}
    local r = currentPos.row
    local c = currentPos.col
    
    -- 색상에 따른 이동 방향 정의 (White는 위로(row 감소), Black은 아래로(row 증가))
    local dir = (self.color == "white") and -1 or 1
    
    -- 1. 1칸 전진 검사
    local nextRow = r + dir
    if nextRow >= 1 and nextRow <= 8 then
        -- 폰의 전방 1칸에 기물이 없는 경우에만 전진 가능
        if board:getPiece(nextRow, c) == nil then
            table.insert(moves, {row = nextRow, col = c})
            
            -- 2. 2칸 전진 검사 (아직 한 번도 안 움직였고 1칸 앞이 비어있는 상태에서 2칸 앞도 비어있는 경우)
            if not self.hasMoved then
                local doubleRow = r + 2 * dir
                if doubleRow >= 1 and doubleRow <= 8 then
                    if board:getPiece(doubleRow, c) == nil then
                        table.insert(moves, {row = doubleRow, col = c})
                    end
                end
            end
        end
    end
    
    -- 3. 대각선 공격 검사 (대각선에 적군 기물이 있는 경우에만 대각선 이동 가능)
    local diagCols = { c - 1, c + 1 }
    local diagRow = r + dir
    
    if diagRow >= 1 and diagRow <= 8 then
        for _, diagCol in ipairs(diagCols) do
            if diagCol >= 1 and diagCol <= 8 then
                local target = board:getPiece(diagRow, diagCol)
                -- 기물이 존재하고, 색상이 아군과 다른 경우 (적군) 잡기 가능
                if target ~= nil and target.color ~= self.color then
                    table.insert(moves, {row = diagRow, col = diagCol})
                end
            end
        end
    end
    
    return moves
end

return Pawn
