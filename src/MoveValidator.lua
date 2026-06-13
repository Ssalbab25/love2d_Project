-- MoveValidator.lua: 기물의 합법적인 행마 및 체크/체크메이트 규칙 판정 클래스
-- SOLID: 
-- - SRP (단일 책임 원칙): 오직 기물의 이동 가능 여부와 체크 및 체크메이트 등의 규칙 연산만 전담합니다.
-- - LSP (리스코프 치환 원칙): getLegalMoves()를 호출하였을 때 항상 일관성 있는 { {row, col}, ... } 배열 구조를 반환합니다.

local Object = require "libs.classic"
local MoveValidator = Object:extend()

-- 특정 기물의 유효 이동 중, 자신의 킹을 위험(체크)에 노출시키지 않는 '합법적 수'만 필터링합니다.
-- board: Board 객체
-- piece: Piece 객체
-- pos: {row = r, col = c} 형태의 시작 좌표
-- 반환값: { {row = r, col = c, ...}, ... } 형태의 배열
function MoveValidator.getLegalMoves(board, piece, pos)
    local pseudoMoves = piece:getValidMoves(board, pos)
    local legalMoves = {}
    
    for _, move in ipairs(pseudoMoves) do
        -- 가상 이동 수행
        local originalPiece = board:getPiece(move.row, move.col)
        board:setPiece(pos.row, pos.col, nil)
        board:setPiece(move.row, move.col, piece)
        
        -- 자신의 킹이 체크당하는지 검사
        local inCheck = board:isInCheck(piece.color)
        
        -- 가상 이동 되돌리기
        board:setPiece(move.row, move.col, originalPiece)
        board:setPiece(pos.row, pos.col, piece)
        
        if not inCheck then
            table.insert(legalMoves, move)
        end
    end
    
    return legalMoves
end

-- 특정 플레이어가 둘 수 있는 합법적인 수(Legal Moves)가 하나라도 있는지 확인합니다.
-- board: Board 객체
-- color: "white" 또는 "black"
-- 반환값: 하나라도 존재하면 true, 없으면 false
function MoveValidator.hasLegalMoves(board, color)
    for r = 1, 8 do
        for c = 1, 8 do
            local piece = board:getPiece(r, c)
            if piece and piece.color == color then
                local legalMoves = MoveValidator.getLegalMoves(board, piece, {row = r, col = c})
                if #legalMoves > 0 then
                    return true
                end
            end
        end
    end
    return false
end

-- 특정 플레이어가 체크메이트 상태인지 검사합니다.
-- board: Board 객체
-- color: "white" 또는 "black"
-- 반환값: 체크메이트면 true, 아니면 false
function MoveValidator.isCheckmate(board, color)
    -- 체크 상태가 아니라면 체크메이트가 아님
    if not board:isInCheck(color) then
        return false
    end
    return not MoveValidator.hasLegalMoves(board, color)
end

return MoveValidator
