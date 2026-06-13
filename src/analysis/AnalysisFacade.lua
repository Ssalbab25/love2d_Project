-- AnalysisFacade.lua: 형세 분석 및 추천 시스템 고수준 파사드 클래스
-- SOLID: DIP를 준수하여 보드 상태를 바탕으로 평가 점수와 추천 수를 일괄 도출합니다.

local Object = require "libs.classic"
local OpeningBookMatcher = require "src.analysis.OpeningBookMatcher"
local EvaluationEngine = require "src.analysis.EvaluationEngine"

local AnalysisFacade = Object:extend()

function AnalysisFacade:new()
    self.bookMatcher = OpeningBookMatcher()
    self.evaluator = EvaluationEngine()
end

-- 보드에서 특정 색상 플레이어의 모든 합법적인 수를 구합니다.
local function getBoardLegalMoves(board, color)
    local allMoves = {}
    for r = 1, 8 do
        for c = 1, 8 do
            local piece = board:getPiece(r, c)
            if piece and piece.color == color then
                local pseudoMoves = piece:getValidMoves(board, {row = r, col = c})
                for _, mv in ipairs(pseudoMoves) do
                    -- 가상 이동 실행 및 킹 체크 상태 시뮬레이션
                    local originalPiece = board:getPiece(mv.row, mv.col)
                    board:setPiece(r, c, nil)
                    board:setPiece(mv.row, mv.col, piece)

                    local inCheck = board:isInCheck(color)

                    -- 상태 복구
                    board:setPiece(mv.row, mv.col, originalPiece)
                    board:setPiece(r, c, piece)

                    if not inCheck then
                        table.insert(allMoves, {
                            from = {row = r, col = c},
                            to = {row = mv.row, col = mv.col},
                            piece = piece
                        })
                    end
                end
            end
        end
    end
    return allMoves
end

-- 가상 이동 시뮬레이션 (캐슬링, 승급, 앙파상 포함)
local function makeMove(board, move)
    local from = move.from
    local to = move.to
    local piece = board:getPiece(from.row, from.col)

    local undoInfo = {
        from = from,
        to = to,
        piece = piece,
        captured = board:getPiece(to.row, to.col),
        hasMoved = piece.hasMoved,
        enPassantTarget = board.enPassantTarget,
        isCastling = false,
        isPromotion = false,
        isEnPassant = false
    }

    -- 1. 프로모션 처리 (가상 시뮬레이션 시에는 무조건 퀸으로 승급)
    if piece.type == "pawn" and (to.row == 1 or to.row == 8) then
        undoInfo.isPromotion = true
        local Queen = require "src.pieces.Queen"
        board:setPiece(to.row, to.col, Queen(piece.color))
        board:setPiece(from.row, from.col, nil)
        return undoInfo
    end

    -- 2. 캐슬링 처리
    if piece.type == "king" and math.abs(to.col - from.col) == 2 then
        undoInfo.isCastling = true
        local rookCol = (to.col > from.col) and 8 or 1
        local newRookCol = (to.col > from.col) and 6 or 4
        local rook = board:getPiece(from.row, rookCol)

        board:setPiece(from.row, from.col, nil)
        board:setPiece(to.row, to.col, piece)
        board:setPiece(from.row, rookCol, nil)
        board:setPiece(from.row, newRookCol, rook)

        piece.hasMoved = true
        if rook then
            undoInfo.rookHasMoved = rook.hasMoved
            rook.hasMoved = true
        end
        return undoInfo
    end

    -- 3. 앙파상 처리
    if piece.type == "pawn" and board.enPassantTarget and to.row == board.enPassantTarget.row and to.col == board.enPassantTarget.col then
        undoInfo.isEnPassant = true
        local epRow = from.row
        undoInfo.epCaptured = board:getPiece(epRow, to.col)
        board:setPiece(epRow, to.col, nil)
        board:setPiece(from.row, from.col, nil)
        board:setPiece(to.row, to.col, piece)
        piece.hasMoved = true
        return undoInfo
    end

    -- 4. 일반 이동 / 포획
    board:setPiece(from.row, from.col, nil)
    board:setPiece(to.row, to.col, piece)
    piece.hasMoved = true

    -- 앙파상 타겟 격자 갱신
    if piece.type == "pawn" and math.abs(to.row - from.row) == 2 then
        board.enPassantTarget = {
            row = (from.row + to.row) / 2,
            col = to.col
        }
    else
        board.enPassantTarget = nil
    end

    return undoInfo
end

-- 가상 이동 상태 복구
local function undoMove(board, undoInfo)
    local from = undoInfo.from
    local to = undoInfo.to
    local piece = undoInfo.piece

    if undoInfo.isPromotion then
        board:setPiece(from.row, from.col, piece)
        board:setPiece(to.row, to.col, undoInfo.captured)
        piece.hasMoved = undoInfo.hasMoved
    elseif undoInfo.isCastling then
        local rookCol = (to.col > from.col) and 8 or 1
        local newRookCol = (to.col > from.col) and 6 or 4
        local rook = board:getPiece(from.row, newRookCol)

        board:setPiece(from.row, from.col, piece)
        board:setPiece(to.row, to.col, nil)
        board:setPiece(from.row, rookCol, rook)
        board:setPiece(from.row, newRookCol, nil)

        piece.hasMoved = undoInfo.hasMoved
        if rook then
            rook.hasMoved = undoInfo.rookHasMoved
        end
    elseif undoInfo.isEnPassant then
        board:setPiece(from.row, from.col, piece)
        board:setPiece(to.row, to.col, nil)
        board:setPiece(from.row, to.col, undoInfo.epCaptured)
        piece.hasMoved = undoInfo.hasMoved
    else
        board:setPiece(from.row, from.col, piece)
        board:setPiece(to.row, to.col, undoInfo.captured)
        piece.hasMoved = undoInfo.hasMoved
    end

    board.enPassantTarget = undoInfo.enPassantTarget
end

-- 알파-베타 가지치기가 적용된 미니맥스 탐색
local function minimaxSearch(board, depth, alpha, beta, isMaximizing, evaluator)
    if depth == 0 then
        return evaluator:evaluate(board)
    end

    local activeColor = isMaximizing and "white" or "black"
    local moves = getBoardLegalMoves(board, activeColor)

    if #moves == 0 then
        if board:isInCheck(activeColor) then
            -- 체크메이트: 깊이가 낮을수록 더 빠른 메이트를 선호하도록 보정
            return isMaximizing and (-30000 - depth) or (30000 + depth)
        else
            -- 스테일메이트 (무승부)
            return 0
        end
    end

    -- 수 정렬 (포획 위주 정렬)
    table.sort(moves, function(m1, m2)
        local score1 = 0
        local score2 = 0

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

    if isMaximizing then
        local maxEval = -1000000
        for _, move in ipairs(moves) do
            local undoInfo = makeMove(board, move)
            local eval = minimaxSearch(board, depth - 1, alpha, beta, false, evaluator)
            undoMove(board, undoInfo)
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
            local undoInfo = makeMove(board, move)
            local eval = minimaxSearch(board, depth - 1, alpha, beta, true, evaluator)
            undoMove(board, undoInfo)
            minEval = math.min(minEval, eval)
            beta = math.min(beta, eval)
            if beta <= alpha then
                break
            end
        end
        return minEval
    end
end

-- 미니맥스 탐색을 통해 최적의 수를 산출합니다.
function AnalysisFacade:findBestMove(board, color, depth)
    local isMaximizing = (color == "white")
    local evaluator = self.evaluator
    local moves = getBoardLegalMoves(board, color)
    if #moves == 0 then return nil, 0 end

    local bestMove = nil
    local bestVal = isMaximizing and -1000000 or 1000000

    -- 수 정렬
    table.sort(moves, function(m1, m2)
        local score1 = 0
        local score2 = 0
        local p1 = board:getPiece(m1.to.row, m1.to.col)
        if p1 then score1 = score1 + 10 * evaluator.materialValues[p1.type] end
        local p2 = board:getPiece(m2.to.row, m2.to.col)
        if p2 then score2 = score2 + 10 * evaluator.materialValues[p2.type] end
        return score1 > score2
    end)

    for _, move in ipairs(moves) do
        local undoInfo = makeMove(board, move)
        local eval = minimaxSearch(board, depth - 1, -1000000, 1000000, not isMaximizing, evaluator)
        undoMove(board, undoInfo)

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

    return bestMove, bestVal
end

-- FEN 추출, 오프닝 조회 및 미니맥스 보완을 통합한 최종 분석 함수
function AnalysisFacade:analyze(board, activeColor, halfmoveClock, fullmoveNumber)
    -- 1. 오프닝 북 매칭 시도
    local bookMove = self.bookMatcher:getBestMove(board, activeColor, halfmoveClock, fullmoveNumber)
    local staticScore = self.evaluator:evaluate(board)

    if bookMove then
        return {
            score = staticScore,
            bestMove = bookMove,
            isBook = true
        }
    end

    -- 2. 미니맥스 3-ply 기반 최선의 수 및 평가 계산
    local bestMove, searchScore = self:findBestMove(board, activeColor, 3)

    return {
        score = searchScore, -- 백색 기준 스코어
        bestMove = bestMove,
        isBook = false
    }
end

-- 외부에서 사용하기 쉽도록 가상 이동 헬퍼들 등록
AnalysisFacade.makeMove = makeMove
AnalysisFacade.undoMove = undoMove
AnalysisFacade.getBoardLegalMoves = getBoardLegalMoves
AnalysisFacade.minimaxSearch = minimaxSearch

return AnalysisFacade
