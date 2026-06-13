-- GameStateDetector.lua: 게임 상태 분석 및 종료 판별 클래스
-- SOLID: 
-- - SRP (단일 책임 원칙): 매 턴 종료 후 대국판 전체 상황을 스캔하여 체크메이트, 스테일메이트, 기물 부족 무승부 등의 게임 종료 상태를 판정하는 책임만 지닙니다.
-- - DIP (의존성 역전 원칙): 고수준 게임 연산을 직접 제어하지 않고, Board와 MoveValidator에 대한 추상적 상태 결과만 탐색해 반환합니다.

local Object = require "libs.classic"
local MoveValidator = require "src.MoveValidator"

local GameStateDetector = Object:extend()

-- 게임 종료 조건(체크메이트, 스테일메이트, 기물 부족 무승부)을 판정합니다.
-- board: Board 객체
-- currentTurn: "white" 또는 "black"
-- 반환값: isGameOver(boolean), winner(string/nil), gameOverReason(string/nil)
function GameStateDetector.detectGameEnd(board, currentTurn)
    -- 1. 기물 부족 무승부 검증
    if board:hasInsufficientMaterial() then
        return true, "draw", "insufficient_material"
    end
    
    -- 2. 합법수 유무에 따른 체크메이트 / 스테일메이트 검증
    if not MoveValidator.hasLegalMoves(board, currentTurn) then
        if board:isInCheck(currentTurn) then
            local winner = (currentTurn == "white") and "black" or "white"
            return true, winner, "checkmate"
        else
            return true, "draw", "stalemate"
        end
    end
    
    return false, nil, nil
end

return GameStateDetector
