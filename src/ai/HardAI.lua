-- HardAI.lua: Hard 난이도 AI 전략 클래스
-- SOLID: SRP를 준수하여 Hard AI만의 3-ply 미니맥스/알파베타 정적/위치(PST) 평가, 오프닝 북, 전치 테이블(TT)을 처리합니다.

local AIStrategy = require "src.ai.AIStrategy"
local AnalysisFacade = require "src.analysis.AnalysisFacade"
local OpeningBookMatcher = require "src.analysis.OpeningBookMatcher"
local EvaluationEngine = require "src.analysis.EvaluationEngine"
local HardAI = AIStrategy:extend()

-- TT 플래그 정의
local EXACT = 0
local LOWERBOUND = 1
local UPPERBOUND = 2

function HardAI:new()
    self.bookMatcher = OpeningBookMatcher()
    self.evaluator = EvaluationEngine()
end

-- 미니맥스 + 알파베타 + 전치 테이블(TT) 검색
local function minimax(board, depth, alpha, beta, isMaximizing, evaluator, game, transpositionTable)
    local activeColor = isMaximizing and "white" or "black"
    
    -- 성능 최적화: 깊이가 낮은 노드(1이하)에서는 FEN 생성 비용이 전치 테이블의 이득보다 크므로 TT 조회를 스킵합니다.
    local useTT = (depth >= 2)
    local fen
    local ttEntry
    
    if useTT then
        fen = OpeningBookMatcher.generateFEN(board, activeColor, game.halfmoveClock, game.fullmoveNumber)
        ttEntry = transpositionTable[fen]
        if ttEntry and ttEntry.depth >= depth then
            if ttEntry.flag == EXACT then
                return ttEntry.score
            elseif ttEntry.flag == LOWERBOUND then
                alpha = math.max(alpha, ttEntry.score)
            elseif ttEntry.flag == UPPERBOUND then
                beta = math.min(beta, ttEntry.score)
            end
            if alpha >= beta then
                return ttEntry.score
            end
        end
    end
    
    -- Leaf 노드: 정적 평가값 즉시 반환 (지연 유발 요소 배제)
    if depth == 0 then
        return evaluator:evaluate(board)
    end
    
    local moves = AnalysisFacade.getBoardLegalMoves(board, activeColor)
    if #moves == 0 then
        if board:isInCheck(activeColor) then
            return isMaximizing and (-30000 - depth) or (30000 + depth)
        else
            return 0
        end
    end
    
    -- 기본 수 정렬
    table.sort(moves, function(m1, m2)
        local score1 = 0
        local score2 = 0
        
        -- TT에 저장되었던 베스트 무브에 가중치 부여
        if useTT and ttEntry and ttEntry.move then
            if m1.from.row == ttEntry.move.from.row and m1.from.col == ttEntry.move.from.col and
               m1.to.row == ttEntry.move.to.row and m1.to.col == ttEntry.move.to.col then
                score1 = score1 + 100000
            end
            if m2.from.row == ttEntry.move.from.row and m2.from.col == ttEntry.move.from.col and
               m2.to.row == ttEntry.move.to.row and m2.to.col == ttEntry.move.to.col then
                score2 = score2 + 100000
            end
        end
        
        local p1 = board:getPiece(m1.to.row, m1.to.col)
        if p1 then
            score1 = score1 + 10 * evaluator.materialValues[p1.type]
        end
        local p2 = board:getPiece(m2.to.row, m2.to.col)
        if p2 then
            score2 = score2 + 10 * evaluator.materialValues[p2.type]
        end
        
        if m1.piece.type == "pawn" and (m1.to.row == 1 or m1.to.row == 8) then
            score1 = score1 + 900
        end
        if m2.piece.type == "pawn" and (m2.to.row == 1 or m2.to.row == 8) then
            score2 = score2 + 900
        end
        
        return score1 > score2
    end)
    
    local originalAlpha = alpha
    local originalBeta = beta
    local bestMove = nil
    local evalVal
    
    if isMaximizing then
        evalVal = -1000000
        for _, move in ipairs(moves) do
            local undoInfo = AnalysisFacade.makeMove(board, move)
            local val = minimax(board, depth - 1, alpha, beta, false, evaluator, game, transpositionTable)
            AnalysisFacade.undoMove(board, undoInfo)
            
            if val > evalVal then
                evalVal = val
                bestMove = move
            end
            alpha = math.max(alpha, val)
            if beta <= alpha then
                break
            end
        end
    else
        evalVal = 1000000
        for _, move in ipairs(moves) do
            local undoInfo = AnalysisFacade.makeMove(board, move)
            local val = minimax(board, depth - 1, alpha, beta, true, evaluator, game, transpositionTable)
            AnalysisFacade.undoMove(board, undoInfo)
            
            if val < evalVal then
                evalVal = val
                bestMove = move
            end
            beta = math.min(beta, val)
            if beta <= alpha then
                break
            end
        end
    end
    
    -- TT 기록
    if useTT then
        local newEntry = {
            depth = depth,
            score = evalVal,
            move = bestMove
        }
        if evalVal <= originalAlpha then
            newEntry.flag = UPPERBOUND
        elseif evalVal >= originalBeta then
            newEntry.flag = LOWERBOUND
        else
            newEntry.flag = EXACT
        end
        transpositionTable[fen] = newEntry
    end
    
    return evalVal
end

function HardAI:getBestMove(board, color, game)
    -- 1. 오프닝 북 먼저 대조
    local bookMove = self.bookMatcher:getBestMove(board, color, game.halfmoveClock, game.fullmoveNumber)
    if bookMove then
        return bookMove
    end
    
    -- 2. 미니맥스 3-ply (depth = 2) 탐색 수행 (렉 방지 및 최적의 실시간 응답 보장)
    local transpositionTable = {}
    local moves = AnalysisFacade.getBoardLegalMoves(board, color)
    if #moves == 0 then
        return nil
    end
    
    -- 기본적인 정렬 수행
    local evaluator = self.evaluator
    table.sort(moves, function(m1, m2)
        local score1 = 0
        local score2 = 0
        local p1 = board:getPiece(m1.to.row, m1.to.col)
        if p1 then score1 = score1 + 10 * evaluator.materialValues[p1.type] end
        local p2 = board:getPiece(m2.to.row, m2.to.col)
        if p2 then score2 = score2 + 10 * evaluator.materialValues[p2.type] end
        return score1 > score2
    end)
    
    local bestMove = nil
    local isMaximizing = (color == "white")
    local bestVal = isMaximizing and -1000000 or 1000000
    
    for _, move in ipairs(moves) do
        local undoInfo = AnalysisFacade.makeMove(board, move)
        -- depth = 2 이면 자식 노드에서 minimax(..., 1), minimax(..., 0) 수행
        local eval = minimax(board, 2, -1000000, 1000000, not isMaximizing, evaluator, game, transpositionTable)
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

return HardAI
