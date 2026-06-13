-- Game.lua: 게임 상태 및 매니저 조율 클래스
-- SOLID: SRP를 준수하여 보드 데이터, 렌더러, 입력 핸들러의 인스턴스를 조율하고 게임 차례와 규칙 루프를 제어합니다.

local Object = require "libs.classic"
local Board = require "src.Board"
local BoardRenderer = require "src.BoardRenderer"
local InputHandler = require "src.InputHandler"
local EasyAI = require "src.ai.EasyAI"
local MediumAI = require "src.ai.MediumAI"
local HardAI = require "src.ai.HardAI"

-- SOLID 준수를 위한 신규 모듈 의존성 주입
local MoveValidator = require "src.MoveValidator"
local GameStateDetector = require "src.GameStateDetector"
local TimeManager = require "src.TimeManager"
local SoundManager = require "src.SoundManager"

local Game = Object:extend()

function Game:new()
    self.boardRenderer = BoardRenderer()
    self.inputHandler = InputHandler(self.boardRenderer)
    self.aiStrategies = {
        easy = EasyAI(),
        medium = MediumAI(),
        hard = HardAI()
    }
    
    -- 시간 및 사운드 관리를 전담 모듈로 이관 (SRP 준수)
    self.timeManager = TimeManager(600)
    self.soundManager = SoundManager()
    
    -- 화면 상태 및 모드 관리 변수
    self.screenState = "menu"        -- 'menu', 'difficulty_select', 'playing'
    self.gameMode = nil              -- 'offline', 'vs_ai'
    self.aiDifficulty = nil         -- 'easy', 'medium', 'hard'
    
    -- 게임 플레이 상태 초기화
    self:resetGame()
    
    -- 오디오 소스 추가 (착수음, 처치음, 체크음, 체크메이트음)
    -- SoundManager 내부에서 관리하지만 하위 호환성을 위해 레퍼런스 유지
    if self.soundManager then
        self.moveSound = self.soundManager.moveSound
        self.captureSound = self.soundManager.captureSound
        self.checkSound = self.soundManager.checkSound
        self.checkmateSound = self.soundManager.checkmateSound
    end
end

-- 대국 상태 초기화 (메인 메뉴 재진입 또는 재시작 시 활용)
function Game:resetGame()
    local Board = require "src.Board"
    self.board = Board()
    self.board:setupPieces()
    
    self.currentTurn = "white"
    self.selectedPiece = nil
    self.selectedPos = nil
    self.validMoves = {}
    self.isGameOver = false
    self.winner = nil
    
    self.board.enPassantTarget = nil
    self.pendingPromotion = nil
    
    -- TimeManager 초기화 및 동기화
    if self.timeManager then
        self.timeManager:reset()
        self.whiteTime = self.timeManager.whiteTime
        self.blackTime = self.timeManager.blackTime
    else
        self.whiteTime = 600
        self.blackTime = 600
    end
    self.capturedPieces = { white = {}, black = {} }
    
    self.gameOverReason = nil
    self.pendingDrawOffer = nil
    
    -- AI 관련 대기 타이머 및 연출용 상태 초기화
    self.aiTimer = 0.8
    self.aiSelectedMove = nil

    -- FEN 규칙용 클록 변수 초기화
    self.halfmoveClock = 0
    self.fullmoveNumber = 1
end

-- 가상의 칸 또는 마우스 클릭 격자 좌표 선택 시 비즈니스 규칙 처리
-- row, col: 1~8 격자 인덱스
-- 반환값: 기물 선택/이동 처리 성공 시 true, 그 외 false
function Game:selectSquare(row, col)
    -- 게임이 종료되었거나 프로모션 대기 중이면 더 이상 보드 조작 불가
    if self.isGameOver or self.pendingPromotion then
        return false
    end

    -- 1. 이미 기물이 선택되어 있고, 클릭한 칸이 유효한 이동 경로에 포함되어 있는 경우 (이동 실행)
    if self.selectedPiece and self:isValidMove(row, col) then
        local startRow = self.selectedPos.row
        local startCol = self.selectedPos.col
        local movingPiece = self.selectedPiece
        
        -- (1) 특수 규칙 처리: 캐슬링 확인 및 Rook 동시 이동
        local isCastlingKing = (movingPiece.type == "king") and (col - startCol == 2)
        local isCastlingQueen = (movingPiece.type == "king") and (col - startCol == -2)
        
        if isCastlingKing then
            local rook = self.board:getPiece(startRow, 8)
            self.board:setPiece(startRow, 8, nil)
            self.board:setPiece(startRow, 6, rook)
            if rook then rook.hasMoved = true end
        elseif isCastlingQueen then
            local rook = self.board:getPiece(startRow, 1)
            self.board:setPiece(startRow, 1, nil)
            self.board:setPiece(startRow, 4, rook)
            if rook then rook.hasMoved = true end
        end
        
        -- (2) 특수 규칙 처리: 앙파상 포획 처리
        local isEP = false
        for _, m in ipairs(self.validMoves) do
            if m.row == row and m.col == col and m.isEnPassant then
                isEP = true
                break
            end
        end
        if isEP then
            local epPiece = self.board:getPiece(startRow, col)
            if epPiece then
                table.insert(self.capturedPieces[movingPiece.color], epPiece.type)
            end
            self.board:setPiece(startRow, col, nil)
        end
        
        -- (2.5) 일반 기물 포획 처리 및 기록
        local targetPiece = self.board:getPiece(row, col)
        local isCapture = (targetPiece ~= nil or isEP)
        if targetPiece then
            table.insert(self.capturedPieces[movingPiece.color], targetPiece.type)
        end
        
        -- 원래 자리 비우고 목적지로 이동 실행
        self.board:setPiece(startRow, startCol, nil)
        self.board:setPiece(row, col, movingPiece)
        movingPiece.hasMoved = true
        
        -- (3) 특수 규칙 처리: 앙파상 타겟 설정 및 해제
        if movingPiece.type == "pawn" and math.abs(row - startRow) == 2 then
            self.board.enPassantTarget = {
                row = (startRow + row) / 2,
                col = col
            }
        else
            self.board.enPassantTarget = nil
        end
        
        -- (4) 특수 규칙 처리: 프로모션 조건 확인
        local isPromotionTriggered = (movingPiece.type == "pawn") and (row == 1 or row == 8)
        if isPromotionTriggered then
            self.pendingPromotion = {
                row = row,
                col = col,
                color = movingPiece.color,
                isCapture = isCapture
            }
            self.selectedPiece = nil
            self.selectedPos = nil
            self.validMoves = {}
            return true
        end
        
        -- FEN 규칙 클록 트래킹
        if movingPiece.type == "pawn" or isCapture then
            self.halfmoveClock = 0
        else
            self.halfmoveClock = self.halfmoveClock + 1
        end
        if self.currentTurn == "black" then
            self.fullmoveNumber = self.fullmoveNumber + 1
        end

        -- 턴 교대 (white <-> black) 및 피셔 딜레이 가산 (+5초) (TimeManager 활용)
        if self.timeManager then
            self.timeManager:addIncrement(self.currentTurn, 5)
            self.whiteTime = self.timeManager.whiteTime
            self.blackTime = self.timeManager.blackTime
        else
            if self.currentTurn == "white" then
                self.whiteTime = self.whiteTime + 5
            else
                self.blackTime = self.blackTime + 5
            end
        end
        self.currentTurn = (self.currentTurn == "white") and "black" or "white"
        
        -- 게임 종료 상태(체크메이트/스테일메이트/기물부족 무승부) 검증
        self:checkGameEndStatus()
        
        -- 오디오 재생 효과 조율
        self:playMoveSound(isCapture)
        
        -- 선택 상태 리셋
        self.selectedPiece = nil
        self.selectedPos = nil
        self.validMoves = {}
        return true
    end
    
    -- 2. 기물이 선택되어 있지 않거나, 유효 경로 외의 칸을 선택한 경우 (새로운 선택 시도)
    local clickedPiece = self.board:getPiece(row, col)
    if clickedPiece and clickedPiece.color == self.currentTurn then
        -- 자신의 차례에 속한 아군 기물이면 선택 활성화
        self.selectedPiece = clickedPiece
        self.selectedPos = {row = row, col = col}
        self.validMoves = self:getLegalMoves(clickedPiece, self.selectedPos)
        return true
    else
        -- 빈 칸이거나 상대 턴 기물이면 선택 해제
        self.selectedPiece = nil
        self.selectedPos = nil
        self.validMoves = {}
        return false
    end
end

-- 지정한 좌표가 현재 선택된 기물의 유효 이동 경로에 포함되는지 확인
function Game:isValidMove(row, col)
    for _, move in ipairs(self.validMoves) do
        if move.row == row and move.col == col then
            return true
        end
    end
    return false
end

-- 특정 기물의 유효 이동 중, 자신의 킹을 위험(체크)에 노출시키지 않는 '합법적 수'만 필터링합니다. (MoveValidator 이관)
function Game:getLegalMoves(piece, pos)
    return MoveValidator.getLegalMoves(self.board, piece, pos)
end

-- 특정 플레이어가 둘 수 있는 합법적인 수(Legal Moves)가 하나라도 있는지 확인합니다. (MoveValidator 이관)
function Game:hasLegalMoves(color)
    return MoveValidator.hasLegalMoves(self.board, color)
end

-- 특정 플레이어가 체크메이트 상태인지 검사합니다. (MoveValidator 이관)
function Game:isCheckmate(color)
    return MoveValidator.isCheckmate(self.board, color)
end

-- 게임 종료 조건(체크메이트, 스테일메이트, 기물 부족 무승부)을 최종 검사 및 반영합니다. (GameStateDetector 이관)
function Game:checkGameEndStatus()
    local isOver, winner, reason = GameStateDetector.detectGameEnd(self.board, self.currentTurn)
    if isOver then
        self.isGameOver = true
        self.winner = winner
        self.gameOverReason = reason
    end
end

-- 프로모션 대기 중인 폰을 선택한 기물 타입(queen, rook, bishop, knight)으로 변환합니다.
function Game:promotePawn(pieceType)
    if not self.pendingPromotion then return end
    
    local row = self.pendingPromotion.row
    local col = self.pendingPromotion.col
    local color = self.pendingPromotion.color
    
    -- 새 기물 생성
    local newPiece
    if pieceType == "queen" then
        local Queen = require "src.pieces.Queen"
        newPiece = Queen(color)
    elseif pieceType == "rook" then
        local Rook = require "src.pieces.Rook"
        newPiece = Rook(color)
    elseif pieceType == "bishop" then
        local Bishop = require "src.pieces.Bishop"
        newPiece = Bishop(color)
    elseif pieceType == "knight" then
        local Knight = require "src.pieces.Knight"
        newPiece = Knight(color)
    end
    
    if newPiece then
        self.board:setPiece(row, col, newPiece)
        newPiece.hasMoved = true
    end
    
    -- 프로모션 완료 후 피셔 딜레이 가산 (+5초), 턴 교대 및 게임 종료 상태 확인
    local isCapture = self.pendingPromotion.isCapture
    self.pendingPromotion = nil
    
    -- 프로모션은 폰 이동이므로 하프무브 리셋
    self.halfmoveClock = 0
    if self.currentTurn == "black" then
        self.fullmoveNumber = self.fullmoveNumber + 1
    end

    if self.timeManager then
        self.timeManager:addIncrement(self.currentTurn, 5)
        self.whiteTime = self.timeManager.whiteTime
        self.blackTime = self.timeManager.blackTime
    else
        if self.currentTurn == "white" then
            self.whiteTime = self.whiteTime + 5
        else
            self.blackTime = self.blackTime + 5
        end
    end
    self.currentTurn = (self.currentTurn == "white") and "black" or "white"
    
    self:checkGameEndStatus()
    
    -- 오디오 재생 효과 조율
    self:playMoveSound(isCapture)
end

-- LÖVE2D 마우스 pressed 이벤트를 보드 좌표로 변환하여 처리 위임
function Game:handleMousePressed(x, y, button)
    if button ~= 1 then return end -- 마우스 좌클릭만 처리
    
    -- 1. 메인 메뉴 화면인 경우 클릭 처리
    if self.screenState == "menu" then
        local menuBtns = self.boardRenderer:getMenuButtons()
        local ai = menuBtns.vs_ai
        local offline = menuBtns.vs_offline
        
        if x >= ai.x and x <= ai.x + ai.w and y >= ai.y and y <= ai.y + ai.h then
            self.screenState = "difficulty_select"
        elseif x >= offline.x and x <= offline.x + offline.w and y >= offline.y and y <= offline.y + offline.h then
            self:resetGame()
            self.gameMode = "offline"
            self.screenState = "playing"
        end
        return
    end

    -- 2. 난이도 선택 화면인 경우 클릭 처리
    if self.screenState == "difficulty_select" then
        local diffBtns = self.boardRenderer:getDifficultyButtons()
        local easy = diffBtns.easy
        local medium = diffBtns.medium
        local hard = diffBtns.hard
        local back = diffBtns.back
        
        if x >= easy.x and x <= easy.x + easy.w and y >= easy.y and y <= easy.y + easy.h then
            self:resetGame()
            self.gameMode = "vs_ai"
            self.aiDifficulty = "easy"
            self.screenState = "playing"
        elseif x >= medium.x and x <= medium.x + medium.w and y >= medium.y and y <= medium.y + medium.h then
            self:resetGame()
            self.gameMode = "vs_ai"
            self.aiDifficulty = "medium"
            self.screenState = "playing"
        elseif x >= hard.x and x <= hard.x + hard.w and y >= hard.y and y <= hard.y + hard.h then
            self:resetGame()
            self.gameMode = "vs_ai"
            self.aiDifficulty = "hard"
            self.screenState = "playing"
        elseif x >= back.x and x <= back.x + back.w and y >= back.y and y <= back.y + back.h then
            self.screenState = "menu"
        end
        return
    end

    -- 3. 게임 플레이 화면인 경우 클릭 처리
    if self.screenState == "playing" then
        -- 게임이 이미 종료되었으면 더 이상 상호작용 불가 (단, MENU 버튼 클릭은 허용)
        if self.isGameOver then
            local menuBtn = self.boardRenderer:getGameOverMenuButtonRect()
            if x >= menuBtn.x and x <= menuBtn.x + menuBtn.w and y >= menuBtn.y and y <= menuBtn.y + menuBtn.h then
                self:resetGame()
                self.screenState = "menu"
            end
            return
        end

        -- 3.1. 무승부 제안 팝업 모달이 활성화된 경우
        if self.pendingDrawOffer then
            local buttons = self.boardRenderer:getDrawOfferModalButtons()
            if buttons then
                local accept = buttons.accept
                local decline = buttons.decline
                
                if x >= accept.x and x <= accept.x + accept.w and y >= accept.y and y <= accept.y + accept.h then
                    -- 무승부 합의 수락
                    self.isGameOver = true
                    self.winner = "draw"
                    self.gameOverReason = "draw_offer"
                    self.pendingDrawOffer = nil
                elseif x >= decline.x and x <= decline.x + decline.w and y >= decline.y and y <= decline.y + decline.h then
                    -- 무승부 거절
                    self.pendingDrawOffer = nil
                end
            end
            return
        end

        -- 3.2. 프로모션 팝업 모달이 활성화된 경우
        if self.pendingPromotion then
            local option = self.boardRenderer:getPromotionOptionAt(x, y, self.pendingPromotion)
            if option then
                self:promotePawn(option)
            end
            return
        end

        -- 3.3. 우측 패널의 기권/무승부 제안 버튼 선택 확인
        local resignBtn = self.boardRenderer:getResignButtonRect()
        local drawBtn = self.boardRenderer:getDrawOfferButtonRect()
        
        if resignBtn and x >= resignBtn.x and x <= resignBtn.x + resignBtn.w and y >= resignBtn.y and y <= resignBtn.y + resignBtn.h then
            -- 기권 처리
            self.isGameOver = true
            self.winner = (self.currentTurn == "white") and "black" or "white"
            self.gameOverReason = "resign"
            return
        end
        
        if not self.pendingPromotion and drawBtn and x >= drawBtn.x and x <= drawBtn.x + drawBtn.w and y >= drawBtn.y and y <= drawBtn.y + drawBtn.h then
            -- 무승부 제안 활성화
            self.pendingDrawOffer = true
            return
        end

        -- 3.4. 일반 보드 격자 클릭 처리 (vs AI 모드일 때 흑의 턴에는 사용자 보드 조작 불가)
        if self.gameMode == "vs_ai" and self.currentTurn == "black" then
            return
        end

        local row, col = self.inputHandler:toBoardCoords(x, y)
        if row and col then
            self:selectSquare(row, col)
        end
    end
end

function Game:update(dt)
    -- 메인메뉴 등의 화면이면 업데이트 안 함
    if self.screenState ~= "playing" then return end

    -- AI 대국 업데이트 처리
    if self.gameMode == "vs_ai" and self.currentTurn == "black" then
        self:updateAI(dt)
    end

    -- TimeManager를 통한 타이머 업데이트 진행 (SRP 준수)
    local isPaused = self.isGameOver or self.pendingPromotion or self.pendingDrawOffer
    local isTimeout, winner, reason = self.timeManager:update(dt, self.gameMode, self.currentTurn, isPaused)
    
    -- 대국 시간 값 로컬 변수 동기화
    self.whiteTime = self.timeManager.whiteTime
    self.blackTime = self.timeManager.blackTime
    
    if isTimeout then
        self.isGameOver = true
        self.winner = winner
        self.gameOverReason = reason
    end
end

function Game:updateAI(dt)
    if self.isGameOver or self.pendingPromotion or self.pendingDrawOffer then
        return
    end

    self.aiTimer = self.aiTimer - dt

    if self.aiTimer <= 0 then
        if not self.aiSelectedMove then
            -- 1단계: 기물 선택 및 강조
            local strategy = self.aiStrategies[self.aiDifficulty or "easy"]
            local move = strategy:getBestMove(self.board, "black", self)

            if move then
                self.aiSelectedMove = move
                
                -- 기물 선택 강조
                self:selectSquare(self.aiSelectedMove.from.row, self.aiSelectedMove.from.col)
                self.aiTimer = 0.4 -- 0.4초 선택 지연 설정
            end
        else
            -- 2단계: 기물 이동
            local from = self.aiSelectedMove.from
            local to = self.aiSelectedMove.to
            
            -- 안전장치: 현재 선택된 기물이 없거나 다른 기물이면 다시 선택
            if not self.selectedPiece or self.selectedPos.row ~= from.row or self.selectedPos.col ~= from.col then
                self:selectSquare(from.row, from.col)
            end
            
            -- 목적지 선택하여 이동 수행
            self:selectSquare(to.row, to.col)
            
            -- 프로모션 대기 시 자동 퀸 프로모션
            if self.pendingPromotion and self.pendingPromotion.color == "black" then
                self:promotePawn("queen")
            end
            
            -- 상태 리셋
            self.aiSelectedMove = nil
            self.aiTimer = 0.8
        end
    end
end

function Game:draw()
    -- 보드 렌더러에 보드 상태와 선택된 좌표, 이동 가이드를 전달하여 드로잉 (DIP 준수)
    self.boardRenderer:draw(
        self.board, 
        self.selectedPos, 
        self.validMoves, 
        self.isGameOver, 
        self.winner, 
        self.pendingPromotion,
        self.whiteTime,
        self.blackTime,
        self.currentTurn,
        self.capturedPieces,
        self.pendingDrawOffer,
        self.gameOverReason,
        self.screenState,
        self.gameMode,
        self.aiDifficulty
    )
end

-- 조작 종류 및 보드 상태에 따라 사운드를 중지하고 올바른 효과음을 즉각 재생합니다. (SoundManager 이관)
function Game:playMoveSound(isCapture)
    local isInCheck = self.board:isInCheck(self.currentTurn)
    self.soundManager:playMoveSound(self.isGameOver, self.gameOverReason, isCapture, isInCheck)
end

return Game
