-- OpeningBookMatcher.lua: 현재 보드 상태와 오프닝 기보 데이터베이스 매칭 클래스
-- SOLID: SRP를 준수하여 보드를 FEN 문자열로 변환하고 오프닝 데이터베이스를 조회하는 역할만 담당합니다.

local Object = require "libs.classic"
local BookDatabase = require "src.analysis.BookDatabase"

local OpeningBookMatcher = Object:extend()

-- 보드 상태와 플레이 정보를 바탕으로 표준 FEN(Forsyth-Edwards Notation) 문자열을 생성합니다.
function OpeningBookMatcher.generateFEN(board, activeColor, halfmoveClock, fullmoveNumber)
    activeColor = activeColor or "white"
    halfmoveClock = halfmoveClock or 0
    fullmoveNumber = fullmoveNumber or 1

    -- 1. 기물 배치 (Piece Placement)
    local rows = {}
    local typeToChar = {
        pawn = "p", rook = "r", knight = "n", bishop = "b", queen = "q", king = "k"
    }

    for r = 1, 8 do
        local rowStr = ""
        local emptyCount = 0
        for c = 1, 8 do
            local piece = board:getPiece(r, c)
            if piece then
                if emptyCount > 0 then
                    rowStr = rowStr .. tostring(emptyCount)
                    emptyCount = 0
                end
                local char = typeToChar[piece.type] or "?"
                if piece.color == "white" then
                    char = string.upper(char)
                end
                rowStr = rowStr .. char
            else
                emptyCount = emptyCount + 1
            end
        end
        if emptyCount > 0 then
            rowStr = rowStr .. tostring(emptyCount)
        end
        table.insert(rows, rowStr)
    end
    local piecePlacement = table.concat(rows, "/")

    -- 2. 활성 플레이어 색상 (Active Color)
    local activeChar = (activeColor == "white") and "w" or "b"

    -- 3. 캐슬링 가능 여부 (Castling Availability)
    local castling = ""
    -- 백색 캐슬링 권한
    local wKing = board:getPiece(8, 5)
    if wKing and wKing.type == "king" and wKing.color == "white" and not wKing.hasMoved then
        local wRookK = board:getPiece(8, 8)
        if wRookK and wRookK.type == "rook" and wRookK.color == "white" and not wRookK.hasMoved then
            castling = castling .. "K"
        end
        local wRookQ = board:getPiece(8, 1)
        if wRookQ and wRookQ.type == "rook" and wRookQ.color == "white" and not wRookQ.hasMoved then
            castling = castling .. "Q"
        end
    end
    -- 흑색 캐슬링 권한
    local bKing = board:getPiece(1, 5)
    if bKing and bKing.type == "king" and bKing.color == "black" and not bKing.hasMoved then
        local bRookK = board:getPiece(1, 8)
        if bRookK and bRookK.type == "rook" and bRookK.color == "black" and not bRookK.hasMoved then
            castling = castling .. "k"
        end
        local bRookQ = board:getPiece(1, 1)
        if bRookQ and bRookQ.type == "rook" and bRookQ.color == "black" and not bRookQ.hasMoved then
            castling = castling .. "q"
        end
    end
    if castling == "" then
        castling = "-"
    end

    -- 4. 앙파상 타겟 격자 (En Passant Target Square)
    local ep = "-"
    if board.enPassantTarget then
        local r = board.enPassantTarget.row
        local c = board.enPassantTarget.col
        if r and c then
            local colChar = string.char(96 + c)
            local rankNum = 9 - r
            ep = colChar .. tostring(rankNum)
        end
    end

    return string.format("%s %s %s %s %d %d", piecePlacement, activeChar, castling, ep, halfmoveClock, fullmoveNumber)
end

-- UCI 기보 형식(예: "e2e4", "e7e8q")을 {from = {row, col}, to = {row, col}, promotion = type} 구조로 변환합니다.
function OpeningBookMatcher.parseUCIMove(moveStr)
    if not moveStr or #moveStr < 4 then return nil end

    local fromCol = string.byte(moveStr:sub(1,1)) - 96
    local fromRow = 9 - tonumber(moveStr:sub(2,2))
    local toCol = string.byte(moveStr:sub(3,3)) - 96
    local toRow = 9 - tonumber(moveStr:sub(4,4))

    local promotion = nil
    if #moveStr >= 5 then
        local pChar = moveStr:sub(5,5)
        if pChar == "q" then promotion = "queen"
        elseif pChar == "r" then promotion = "rook"
        elseif pChar == "b" then promotion = "bishop"
        elseif pChar == "n" then promotion = "knight"
        end
    end

    return {
        from = { row = fromRow, col = fromCol },
        to = { row = toRow, col = toCol },
        promotion = promotion
    }
end

-- 현재 FEN을 데이터베이스와 매칭하여 가장 높은 가중치를 지닌 추천 수를 찾아 반환합니다.
function OpeningBookMatcher:getBestMove(board, activeColor, halfmoveClock, fullmoveNumber)
    local fen = self.generateFEN(board, activeColor, halfmoveClock, fullmoveNumber)
    local entries = BookDatabase[fen]
    if not entries or #entries == 0 then
        return nil
    end

    -- 가중치가 가장 높은 오프닝 수 선택
    local bestEntry = nil
    for _, entry in ipairs(entries) do
        if not bestEntry or entry.weight > bestEntry.weight then
            bestEntry = entry
        end
    end

    if bestEntry then
        return self.parseUCIMove(bestEntry.move)
    end
    return nil
end

return OpeningBookMatcher
