-- MediumAI.lua: Medium 난이도 AI 전략 클래스
-- SOLID: SRP를 준수하여 Medium AI만의 3-ply 미니맥스/알파베타 정적 기물 평가 행마 결정을 수행합니다.

local AIStrategy = require "src.ai.AIStrategy"
local AnalysisFacade = require "src.analysis.AnalysisFacade"
local MediumAI = AIStrategy:extend()

local PIECE_VALUES = {
    pawn = 100,
    knight = 320,
    bishop = 330,
    rook = 500,
    queen = 900,
    king = 20000
}

local function evaluateMaterialOnly(board)
    local score = 0
    for r = 1, 8 do
        for c = 1, 8 do
            local piece = board:getPiece(r, c)
            if piece then
                local val = PIECE_VALUES[piece.type] or 0
                if piece.color == "white" then
                    score = score + val
                else
                    score = score - val
                end
            end
        end
    end
    return score
end

local function minimax(board, depth, alpha, beta, isMaximizing, game)
    if depth == 0 then
        return evaluateMaterialOnly(board)
    end
    
    local activeColor = isMaximizing and "white" or "black"
    local moves = AnalysisFacade.getBoardLegalMoves(board, activeColor)
    
    if #moves == 0 then
        if board:isInCheck(activeColor) then
            -- 체크메이트: 깊이가 낮을수록 더 빠른 메이트를 선호하도록 깊이에 따른 가중치 부여
            return isMaximizing and (-30000 - depth) or (30000 + depth)
        else
            -- 스테일메이트 (무승부)
            return 0
        end
    end
    
    -- 기본 수 정렬 (포획 우선 정렬로 알파-베타 가지치기 효율 극대화)
    table.sort(moves, function(m1, m2)
        local score1 = 0
        local score2 = 0
        local p1 = board:getPiece(m1.to.row, m1.to.col)
        if p1 then score1 = PIECE_VALUES[p1.type] or 0 end
        local p2 = board:getPiece(m2.to.row, m2.to.col)
        if p2 then score2 = PIECE_VALUES[p2.type] or 0 end
        return score1 > score2
    end)
    
    if isMaximizing then
        local maxEval = -1000000
        for _, move in ipairs(moves) do
            local undoInfo = AnalysisFacade.makeMove(board, move)
            local eval = minimax(board, depth - 1, alpha, beta, false, game)
            AnalysisFacade.undoMove(board, undoInfo)
            maxEval = math.max(maxEval, eval)
            alpha = math.max(alpha, eval)
            if beta <= alpha then
                break
            end
        end
        return maxEval
    else
        local minEval = 1000000
        for _, move in ipairs(moves) do
            local undoInfo = AnalysisFacade.makeMove(board, move)
            local eval = minimax(board, depth - 1, alpha, beta, true, game)
            AnalysisFacade.undoMove(board, undoInfo)
            minEval = math.min(minEval, eval)
            beta = math.min(beta, eval)
            if beta <= alpha then
                break
            end
        end
        return minEval
    end
end

function MediumAI:new()
    -- classic 라이브러리 상속 초기화
end

function MediumAI:getBestMove(board, color, game)
    local moves = AnalysisFacade.getBoardLegalMoves(board, color)
    if #moves == 0 then
        return nil
    end
    
    -- 포획 가능성 높은 순으로 정렬
    table.sort(moves, function(m1, m2)
        local score1 = 0
        local score2 = 0
        local p1 = board:getPiece(m1.to.row, m1.to.col)
        if p1 then score1 = PIECE_VALUES[p1.type] or 0 end
        local p2 = board:getPiece(m2.to.row, m2.to.col)
        if p2 then score2 = PIECE_VALUES[p2.type] or 0 end
        return score1 > score2
    end)
    
    local bestMove = nil
    local isMaximizing = (color == "white")
    local bestVal = isMaximizing and -1000000 or 1000000
    
    for _, move in ipairs(moves) do
        local undoInfo = AnalysisFacade.makeMove(board, move)
        -- 총 깊이 3-ply이므로 자식 탐색 깊이는 2
        local eval = minimax(board, 2, -1000000, 1000000, not isMaximizing, game)
        AnalysisFacade.undoMove(board, undoInfo)
        
        if isMaximizing then
            if eval > bestVal then
                bestVal = eval
                bestMove = move
            end
        else
            if eval < bestVal then
                bestVal = eval
                bestMove = move
            end
        end
    end
    
    return bestMove
end

return MediumAI
