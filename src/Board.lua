-- Board.lua: 보드 데이터 및 기물 위치 상태 관리 클래스
-- SOLID: SRP를 준수하여 오직 체스판의 데이터(2차원 배열) 상태만 관리합니다.
--        렌더링이나 규칙 연산은 분리되어 있습니다.

local Object = require "libs.classic"
local Board = Object:extend()

-- 기물 모듈 로드
local Pawn = require "src.pieces.Pawn"
local Rook = require "src.pieces.Rook"
local Knight = require "src.pieces.Knight"
local Bishop = require "src.pieces.Bishop"
local Queen = require "src.pieces.Queen"
local King = require "src.pieces.King"

function Board:new()
    self.grid = {}
    for r = 1, 8 do
        self.grid[r] = {}
        for c = 1, 8 do
            self.grid[r][c] = nil -- 초기에는 모든 칸이 비어 있음
        end
    end
end

-- 특정 위치에 기물 배치
function Board:setPiece(row, col, piece)
    if row >= 1 and row <= 8 and col >= 1 and col <= 8 then
        self.grid[row][col] = piece
    end
end

-- 특정 위치의 기물 획득
function Board:getPiece(row, col)
    if row >= 1 and row <= 8 and col >= 1 and col <= 8 then
        return self.grid[row][col]
    end
    return nil
end

-- 체스판 표준 기물 배치 초기화
function Board:setupPieces()
    -- 1. 폰(Pawn) 배치
    for col = 1, 8 do
        self:setPiece(2, col, Pawn("black"))
        self:setPiece(7, col, Pawn("white"))
    end
    
    -- 2. 룩, 나이트, 비숍, 퀸, 킹 배치
    local backRowPieces = {
        [1] = Rook,
        [2] = Knight,
        [3] = Bishop,
        [4] = Queen,
        [5] = King,
        [6] = Bishop,
        [7] = Knight,
        [8] = Rook
    }
    
    for col = 1, 8 do
        local pieceClass = backRowPieces[col]
        self:setPiece(1, col, pieceClass("black"))
        self:setPiece(8, col, pieceClass("white"))
    end
end

-- 특정 색상의 킹 위치(행, 열)를 찾습니다.
function Board:findKing(color)
    for r = 1, 8 do
        for c = 1, 8 do
            local piece = self:getPiece(r, c)
            if piece and piece.type == "king" and piece.color == color then
                return r, c
            end
        end
    end
    return nil, nil
end

-- 특정 색상의 킹이 상대 기물로부터 공격받는 상태(체크)인지 검사합니다.
function Board:isInCheck(color)
    local kr, kc = self:findKing(color)
    if not kr then return false end
    
    local opponentColor = (color == "white") and "black" or "white"
    
    for r = 1, 8 do
        for c = 1, 8 do
            local piece = self:getPiece(r, c)
            if piece and piece.color == opponentColor then
                local moves = piece:getValidMoves(self, {row = r, col = c}, true)
                for _, move in ipairs(moves) do
                    if move.row == kr and move.col == kc then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- 특정 좌표(row, col)가 특정 색상(attackerColor)의 기물로부터 공격받고 있는지 검사합니다.
function Board:isSquareAttacked(row, col, attackerColor)
    -- 공격 여부를 확인하기 위해 해당 칸에 임시로 상대 색상의 가상 기물을 둡니다.
    -- (예: 폰의 대각선 공격 등을 올바르게 감지하기 위함)
    local originalPiece = self:getPiece(row, col)
    local defenderColor = (attackerColor == "white") and "black" or "white"
    
    local dummyPiece = { color = defenderColor, type = "dummy" }
    self:setPiece(row, col, dummyPiece)
    
    local isAttacked = false
    for r = 1, 8 do
        for c = 1, 8 do
            local piece = self:getPiece(r, c)
            if piece and piece.color == attackerColor and piece ~= originalPiece then
                local moves = piece:getValidMoves(self, {row = r, col = c}, true)
                for _, move in ipairs(moves) do
                    if move.row == row and move.col == col then
                        isAttacked = true
                        break
                    end
                end
            end
            if isAttacked then break end
        end
    end
    
    -- 원래 기물 상태 복구
    self:setPiece(row, col, originalPiece)
    return isAttacked
end

-- 기물 부족(Insufficient Material) 무승부 조건 판정
function Board:hasInsufficientMaterial()
    local whitePieces = {}
    local blackPieces = {}
    
    for r = 1, 8 do
        for c = 1, 8 do
            local piece = self:getPiece(r, c)
            if piece then
                if piece.color == "white" then
                    table.insert(whitePieces, {type = piece.type, row = r, col = c})
                else
                    table.insert(blackPieces, {type = piece.type, row = r, col = c})
                end
            end
        end
    end
    
    local wCount = #whitePieces
    local bCount = #blackPieces
    
    -- 1. King vs King (양측에 킹만 1개씩 존재)
    if wCount == 1 and bCount == 1 then
        if whitePieces[1].type == "king" and blackPieces[1].type == "king" then
            return true
        end
    end
    
    -- 2. King + Bishop/Knight vs King (한쪽은 킹만, 다른 쪽은 킹+비숍 또는 킹+나이트)
    if (wCount == 2 and bCount == 1) or (wCount == 1 and bCount == 2) then
        local twoSide = (wCount == 2) and whitePieces or blackPieces
        local oneSide = (wCount == 1) and whitePieces or blackPieces
        
        if oneSide[1].type == "king" then
            local hasKing = false
            local nonKing = nil
            for _, p in ipairs(twoSide) do
                if p.type == "king" then
                    hasKing = true
                else
                    nonKing = p.type
                end
            end
            if hasKing and (nonKing == "bishop" or nonKing == "knight") then
                return true
            end
        end
    end
    
    -- 3. King + Bishop vs King + Bishop (동색 비숍 매치)
    if wCount == 2 and bCount == 2 then
        local wKing = false
        local wBishop = false
        local wBishopPos = nil
        for _, p in ipairs(whitePieces) do
            if p.type == "king" then
                wKing = true
            elseif p.type == "bishop" then
                wBishop = true
                wBishopPos = {row = p.row, col = p.col}
            end
        end
        
        local bKing = false
        local bBishop = false
        local bBishopPos = nil
        for _, p in ipairs(blackPieces) do
            if p.type == "king" then
                bKing = true
            elseif p.type == "bishop" then
                bBishop = true
                bBishopPos = {row = p.row, col = p.col}
            end
        end
        
        if wKing and wBishop and bKing and bBishop then
            local wSquareColor = (wBishopPos.row + wBishopPos.col) % 2
            local bSquareColor = (bBishopPos.row + bBishopPos.col) % 2
            if wSquareColor == bSquareColor then
                return true
            end
        end
    end
    
    return false
end

return Board
