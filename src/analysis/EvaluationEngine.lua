-- EvaluationEngine.lua: 체스 포지션 평가 엔진
-- SOLID: SRP를 준수하여 보드 상태의 정적 점수를 계산하는 역할만 담당합니다.

local Object = require "libs.classic"
local EvaluationEngine = Object:extend()

-- 기물 기본 가치 정의 (센티폰 단위)
EvaluationEngine.materialValues = {
    pawn = 100,
    knight = 320,
    bishop = 330,
    rook = 500,
    queen = 900,
    king = 20000
}

-- 기물-위치 가치 테이블 (Piece-Square Tables, PST)
-- 백색 기준 정의. 흑색은 행(Row)을 뒤집어(9 - row) 조회합니다.
-- 1행: 상대방 끝행 (랭크 8), 8행: 아군 시작행 (랭크 1)
EvaluationEngine.PST = {
    pawn = {
        {  0,  0,  0,  0,  0,  0,  0,  0 }, -- 8
        { 50, 50, 50, 50, 50, 50, 50, 50 }, -- 7
        { 10, 10, 20, 30, 30, 20, 10, 10 }, -- 6
        {  5,  5, 10, 25, 25, 10,  5,  5 }, -- 5
        {  0,  0,  0, 20, 20,  0,  0,  0 }, -- 4
        {  5, -5,-10,  0,  0,-10, -5,  5 }, -- 3
        {  5, 10, 10,-20,-20, 10, 10,  5 }, -- 2
        {  0,  0,  0,  0,  0,  0,  0,  0 }  -- 1
    },
    knight = {
        {-50,-40,-30,-30,-30,-30,-40,-50 },
        {-40,-20,  0,  0,  0,  0,-20,-40 },
        {-30,  0, 10, 15, 15, 10,  0,-30 },
        {-30,  5, 15, 20, 20, 15,  5,-30 },
        {-30,  0, 15, 20, 20, 15,  0,-30 },
        {-30,  5, 10, 15, 15, 10,  5,-30 },
        {-40,-20,  0,  5,  5,  0,-20,-40 },
        {-50,-40,-30,-30,-30,-30,-40,-50 }
    },
    bishop = {
        {-20,-10,-10,-10,-10,-10,-10,-20 },
        {-10,  0,  0,  0,  0,  0,  0,-10 },
        {-10,  0,  5, 10, 10,  5,  0,-10 },
        {-10,  5,  5, 10, 10,  5,  5,-10 },
        {-10,  0, 10, 10, 10, 10,  0,-10 },
        {-10, 10, 10, 10, 10, 10, 10,-10 },
        {-10,  5,  0,  0,  0,  0,  5,-10 },
        {-20,-10,-10,-10,-10,-10,-10,-20 }
    },
    rook = {
        {  0,  0,  0,  0,  0,  0,  0,  0 },
        {  5, 10, 10, 10, 10, 10, 10,  5 },
        { -5,  0,  0,  0,  0,  0,  0, -5 },
        { -5,  0,  0,  0,  0,  0,  0, -5 },
        { -5,  0,  0,  0,  0,  0,  0, -5 },
        { -5,  0,  0,  0,  0,  0,  0, -5 },
        { -5,  0,  0,  0,  0,  0,  0, -5 },
        {  0,  0,  0,  5,  5,  0,  0,  0 }
    },
    queen = {
        {-20,-10,-10, -5, -5,-10,-10,-20 },
        {-10,  0,  0,  0,  0,  0,  0,-10 },
        {-10,  0,  5,  5,  5,  5,  0,-10 },
        { -5,  0,  5,  5,  5,  5,  0, -5 },
        {  0,  0,  5,  5,  5,  5,  0, -5 },
        {-10,  5,  5,  5,  5,  5,  0,-10 },
        {-10,  0,  5,  0,  0,  0,  0,-10 },
        {-20,-10,-10, -5, -5,-10,-10,-20 }
    },
    kingMiddleGame = {
        {-30,-40,-40,-50,-50,-40,-40,-30 },
        {-30,-40,-40,-50,-50,-40,-40,-30 },
        {-30,-40,-40,-50,-50,-40,-40,-30 },
        {-30,-40,-40,-50,-50,-40,-40,-30 },
        {-20,-30,-30,-40,-40,-30,-30,-20 },
        {-10,-20,-20,-20,-20,-20,-20,-10 },
        { 20, 20,  0,  0,  0,  0, 20, 20 },
        { 20, 30, 10,  0,  0, 10, 30, 20 }
    },
    kingEndGame = {
        {-50,-40,-30,-20,-20,-30,-40,-50 },
        {-30,-20,-10,  0,  0,-10,-20,-30 },
        {-30,-10, 20, 30, 30, 20,-10,-30 },
        {-30,-10, 30, 40, 40, 30,-10,-30 },
        {-30,-10, 30, 40, 40, 30,-10,-30 },
        {-30,-10, 20, 30, 30, 20,-10,-30 },
        {-30,-30,  0,  0,  0,  0,-30,-30 },
        {-50,-30,-30,-30,-30,-30,-30,-50 }
    }
}

-- 보드 상의 남은 기물을 분석하여 엔드게임 상태 여부를 판별합니다.
function EvaluationEngine.isEndgame(board)
    local numWhiteMinors = 0
    local numBlackMinors = 0
    local hasWhiteQueen = false
    local hasBlackQueen = false

    for r = 1, 8 do
        for c = 1, 8 do
            local piece = board:getPiece(r, c)
            if piece then
                if piece.type == "queen" then
                    if piece.color == "white" then
                        hasWhiteQueen = true
                    else
                        hasBlackQueen = true
                    end
                elseif piece.type == "rook" or piece.type == "bishop" or piece.type == "knight" then
                    if piece.color == "white" then
                        numWhiteMinors = numWhiteMinors + 1
                    else
                        numBlackMinors = numBlackMinors + 1
                    end
                end
            end
        end
    end

    -- 엔드게임 기준: 양측 퀸이 없거나, 퀸이 있더라도 마이너 기물이 1개 이하일 때
    if not hasWhiteQueen and not hasBlackQueen then
        return true
    end
    if hasWhiteQueen and numWhiteMinors <= 1 and hasBlackQueen and numBlackMinors <= 1 then
        return true
    end
    return false
end

-- 백색 기준의 평가 점수를 반환합니다. (백색이 유리하면 양수, 흑색이 유리하면 음수)
function EvaluationEngine:evaluate(board)
    local isEnd = self.isEndgame(board)
    local score = 0

    for r = 1, 8 do
        for c = 1, 8 do
            local piece = board:getPiece(r, c)
            if piece then
                local val = self.materialValues[piece.type] or 0
                local pstVal = 0

                local pstTable = self.PST[piece.type]
                if piece.type == "king" then
                    pstTable = isEnd and self.PST.kingEndGame or self.PST.kingMiddleGame
                end

                if pstTable then
                    local lookupRow = r
                    if piece.color == "black" then
                        lookupRow = 9 - r
                    end
                    pstVal = pstTable[lookupRow][c] or 0
                end

                local totalVal = val + pstVal
                if piece.color == "white" then
                    score = score + totalVal
                else
                    score = score - totalVal
                end
            end
        end
    end

    return score
end

return EvaluationEngine
