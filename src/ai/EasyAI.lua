-- EasyAI.lua: Easy 난이도 AI 전략 클래스
-- SOLID: SRP를 준수하여 Easy AI만의 행마 결정 규칙을 담고 있습니다.

local AIStrategy = require "src.ai.AIStrategy"
local EasyAI = AIStrategy:extend()

local PIECE_VALUES = {
    pawn = 100,
    knight = 320,
    bishop = 330,
    rook = 500,
    queen = 900,
    king = 20000
}

function EasyAI:new()
    -- classic 라이브러리 상속 초기화
end

function EasyAI:getBestMove(board, color, game)
    -- 1. 모든 합법적인 수(Legal Moves) 찾기
    local legalMoves = {}
    local captureMoves = {}

    for r = 1, 8 do
        for c = 1, 8 do
            local piece = board:getPiece(r, c)
            if piece and piece.color == color then
                local moves = game:getLegalMoves(piece, {row = r, col = c})
                for _, move in ipairs(moves) do
                    local moveData = {
                        from = {row = r, col = c},
                        to = {row = move.row, col = move.col}
                    }
                    table.insert(legalMoves, moveData)
                    
                    -- 상대방 기물이 있거나 앙파상인 경우 캡처(포획) 수로 분류
                    local targetPiece = board:getPiece(move.row, move.col)
                    local isCapture = false
                    local captureVal = 0
                    
                    if targetPiece and targetPiece.color ~= color then
                        isCapture = true
                        captureVal = PIECE_VALUES[targetPiece.type] or 100
                    elseif move.isEnPassant then
                        isCapture = true
                        captureVal = PIECE_VALUES["pawn"] -- 앙파상 포획 대상은 폰
                    end
                    
                    if isCapture then
                        moveData.captureValue = captureVal
                        table.insert(captureMoves, moveData)
                    end
                end
            end
        end
    end

    if #legalMoves == 0 then
        return nil
    end

    -- 2. Heuristic 적용: 35% 확률로 캡처(포획) 수 중 최선수 선택, 65% 확률로 무작위 수
    local roll = math.random()
    if roll <= 0.35 and #captureMoves > 0 then
        -- 가장 가치가 높은 타겟을 가진 캡처 수들 필터링
        local maxVal = -1
        for _, m in ipairs(captureMoves) do
            if m.captureValue > maxVal then
                maxVal = m.captureValue
            end
        end
        
        local bestCaptures = {}
        for _, m in ipairs(captureMoves) do
            if m.captureValue == maxVal then
                table.insert(bestCaptures, m)
            end
        end
        
        if #bestCaptures > 0 then
            return bestCaptures[math.random(#bestCaptures)]
        end
    end

    -- 3. 무작위 수 또는 캡처 수 선택 실패 시 폴백
    return legalMoves[math.random(#legalMoves)]
end

return EasyAI
