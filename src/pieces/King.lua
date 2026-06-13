-- King.lua: 킹 기물의 행마 및 상태 클래스
-- SOLID: 
-- - OCP (개방-폐쇄 원칙): Piece 추상 클래스를 상속받아 기존 코드를 수정하지 않고 King 고유의 getValidMoves를 확장 구현합니다.
-- - LSP (리스코프 치환 원칙): 부모 Piece와 동일하게 getValidMoves가 { {row = r, col = c}, ... } 구조의 배열을 일관되게 반환합니다.
-- - SRP (단일 책임 원칙): 오직 킹 기물의 고유 속성 및 이동 규칙 계산의 책임만 가집니다.

local Piece = require "src.pieces.Piece"
local King = Piece:extend()

function King:new(color)
    King.super.new(self, color, "king")
end

-- 킹의 행마 가능 좌표 리스트 계산
-- board: Board 객체
-- currentPos: {row = r, col = c} 형태
-- ignoreCastling: 캐슬링 검사 무시 여부 (무한 루프 방지용)
-- 반환값: { {row = r, col = c, isCastling = "king"/"queen" (선택)}, ... } 형태
function King:getValidMoves(board, currentPos, ignoreCastling)
    local moves = {}
    local r = currentPos.row
    local c = currentPos.col
    
    -- 주변 8방향 정의
    local directions = {
        { dr = -1, dc = -1 }, { dr = -1, dc = 0 }, { dr = -1, dc = 1 },
        { dr = 0,  dc = -1 },                      { dr = 0,  dc = 1 },
        { dr = 1,  dc = -1 }, { dr = 1,  dc = 0 }, { dr = 1,  dc = 1 }
    }
    
    for _, dir in ipairs(directions) do
        local nextRow = r + dir.dr
        local nextCol = c + dir.dc
        
        -- 보드 경계 검사
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
    
    -- 캐슬링 규칙 추가
    if not ignoreCastling and not self.hasMoved and c == 5 then
        local opponentColor = (self.color == "white") and "black" or "white"
        -- 킹이 현재 체크 상태가 아니어야 함
        if not board:isSquareAttacked(r, c, opponentColor) then
            -- 1. 킹사이드 캐슬링 (오른쪽 Rook)
            local rookK = board:getPiece(r, 8)
            if rookK and rookK.type == "rook" and rookK.color == self.color and not rookK.hasMoved then
                -- (r, 6)과 (r, 7)이 모두 비어 있어야 함
                if board:getPiece(r, 6) == nil and board:getPiece(r, 7) == nil then
                    -- (r, 6)과 (r, 7)이 공격받지 않아야 함
                    if not board:isSquareAttacked(r, 6, opponentColor) and not board:isSquareAttacked(r, 7, opponentColor) then
                        table.insert(moves, {row = r, col = 7, isCastling = "king"})
                    end
                end
            end
            
            -- 2. 퀸사이드 캐슬링 (왼쪽 Rook)
            local rookQ = board:getPiece(r, 1)
            if rookQ and rookQ.type == "rook" and rookQ.color == self.color and not rookQ.hasMoved then
                -- (r, 2), (r, 3), (r, 4)가 모두 비어 있어야 함
                if board:getPiece(r, 2) == nil and board:getPiece(r, 3) == nil and board:getPiece(r, 4) == nil then
                    -- (r, 3)과 (r, 4)가 공격받지 않아야 함
                    if not board:isSquareAttacked(r, 3, opponentColor) and not board:isSquareAttacked(r, 4, opponentColor) then
                        table.insert(moves, {row = r, col = 3, isCastling = "queen"})
                    end
                end
            end
        end
    end
    
    return moves
end

return King
