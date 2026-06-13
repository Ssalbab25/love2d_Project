-- BoardRenderer.lua: 체스판 화면 렌더링 클래스
-- SOLID: SRP를 준수하여 화면에 보드와 라벨을 그리는 역할만 담당합니다.
--        DIP를 준수하여 보드 데이터 상태(Board 객체)를 넘겨받아 렌더링에 활용합니다.

local Object = require "libs.classic"

-- =========================================================================
-- [신규 UI] 보조 헬퍼 함수
-- =========================================================================
local function formatTime(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function getCounts(list)
    local counts = { pawn = 0, knight = 0, bishop = 0, rook = 0, queen = 0 }
    for _, t in ipairs(list or {}) do
        if counts[t] then
            counts[t] = counts[t] + 1
        end
    end
    return counts
end

local BoardRenderer = Object:extend()

function BoardRenderer:new()
    -- 디자인 테마 색상 설정 (세련된 크림 & 다크 그레이 계열)
    self.colors = {
        lightTile = { 0.94, 0.93, 0.88 }, -- 부드러운 크림색
        darkTile = { 0.46, 0.53, 0.60 },  -- 모던한 블루-그레이/슬레이트색
        label = { 0.20, 0.22, 0.25 },     -- 짙은 차콜색 (라벨 텍스트용)
        border = { 0.15, 0.15, 0.15 }     -- 경계선 색상
    }

    -- 기본 레이아웃 변수 설정 (창 크기 대비 적절한 사이즈)
    self.tileSize = 60
    self.offsetX = 0
    self.offsetY = 0

    -- 폰트 초기화 (가로/세로 중앙 맞춤용, 한국어 지원 볼드체 적용)
    self.font = love.graphics.newFont("korean_bold.ttf", 16)
    self.pieceFont = love.graphics.newFont("seguisym.ttf", 56) -- 기물용 큰 폰트
    self.checkFont = love.graphics.newFont("korean_bold.ttf", 22) -- 체크 경고용 폰트
    self.gameOverTitleFont = love.graphics.newFont("korean_bold.ttf", 32) -- 게임종료 타이틀 폰트
    self.gameOverTextFont = love.graphics.newFont("korean_bold.ttf", 18)  -- 게임종료 결과 안내용 폰트
    self.uiPieceFont = love.graphics.newFont("seguisym.ttf", 22)   -- UI용 작은 기물 폰트
    self.promoPieceFont = love.graphics.newFont("seguisym.ttf", 36) -- 프로모션 기물용 폰트
end

-- 창 크기가 변경되거나 최초 로드 시 오프셋을 계산합니다.
function BoardRenderer:updateLayout(windowWidth, windowHeight)
    local boardSize = self.tileSize * 8
    self.offsetX = 50
    self.offsetY = (windowHeight - boardSize) / 2
end

-- 체스판 및 라벨 그리기
-- selectedPos: 현재 선택된 기물의 {row, col} 좌표 (선택 사항)
-- validMoves: 현재 선택된 기물이 이동 가능한 { {row, col}, ... } 좌표 목록 (선택 사항)
-- isGameOver: 게임 종료 여부 (선택 사항)
-- winner: 승리한 플레이어 색상 (선택 사항)
function BoardRenderer:draw(board, selectedPos, validMoves, isGameOver, winner, pendingPromotion, whiteTime, blackTime, currentTurn, capturedPieces, pendingDrawOffer, gameOverReason, screenState, gameMode, aiDifficulty)
    -- 화면 중앙 배치 갱신 (반응형 대응)
    local w, h = love.graphics.getDimensions()
    self:updateLayout(w, h)

    local oldFont = love.graphics.getFont()

    -- 1. 메인 메뉴 화면 그리기
    if screenState == "menu" then
        love.graphics.clear(0.12, 0.14, 0.18)
        
        love.graphics.setFont(self.gameOverTitleFont)
        love.graphics.setColor(0.85, 0.68, 0.25, 0.95)
        love.graphics.printf("Love2D Chess", 0, 140, w, "center")
        
        love.graphics.setFont(self.font)
        love.graphics.setColor(0.65, 0.70, 0.75, 0.8)
        love.graphics.printf("A Premium Chess Experience", 0, 200, w, "center")
        
        local menuBtns = self:getMenuButtons()
        local mx, my = 0, 0
        if love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        
        -- vs AI 버튼
        local aiBtn = menuBtns.vs_ai
        local aiHover = (mx >= aiBtn.x and mx <= aiBtn.x + aiBtn.w and my >= aiBtn.y and my <= aiBtn.y + aiBtn.h)
        if aiHover then
            love.graphics.setColor(0.22, 0.32, 0.45, 0.95)
        else
            love.graphics.setColor(0.16, 0.22, 0.30, 0.9)
        end
        love.graphics.rectangle("fill", aiBtn.x, aiBtn.y, aiBtn.w, aiBtn.h, 8, 8)
        
        if aiHover then
            love.graphics.setColor(0.85, 0.68, 0.25, 0.95)
        else
            love.graphics.setColor(0.35, 0.42, 0.52, 0.7)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", aiBtn.x, aiBtn.y, aiBtn.w, aiBtn.h, 8, 8)
        
        love.graphics.setFont(self.font)
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.printf("vs AI (인공지능 대국)", aiBtn.x, aiBtn.y + 15, aiBtn.w, "center")
        
        -- vs Offline 버튼
        local offlineBtn = menuBtns.vs_offline
        local offlineHover = (mx >= offlineBtn.x and mx <= offlineBtn.x + offlineBtn.w and my >= offlineBtn.y and my <= offlineBtn.y + offlineBtn.h)
        if offlineHover then
            love.graphics.setColor(0.22, 0.32, 0.45, 0.95)
        else
            love.graphics.setColor(0.16, 0.22, 0.30, 0.9)
        end
        love.graphics.rectangle("fill", offlineBtn.x, offlineBtn.y, offlineBtn.w, offlineBtn.h, 8, 8)
        
        if offlineHover then
            love.graphics.setColor(0.85, 0.68, 0.25, 0.95)
        else
            love.graphics.setColor(0.35, 0.42, 0.52, 0.7)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", offlineBtn.x, offlineBtn.y, offlineBtn.w, offlineBtn.h, 8, 8)
        
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.printf("vs Offline (로컬 2인 대국)", offlineBtn.x, offlineBtn.y + 15, offlineBtn.w, "center")
        
        love.graphics.setFont(oldFont)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- 2. 난이도 선택 화면 그리기
    if screenState == "difficulty_select" then
        love.graphics.clear(0.12, 0.14, 0.18)
        
        love.graphics.setFont(self.checkFont)
        love.graphics.setColor(0.85, 0.68, 0.25, 0.95)
        love.graphics.printf("Select AI Difficulty", 0, 140, w, "center")
        
        local diffBtns = self:getDifficultyButtons()
        local mx, my = 0, 0
        if love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        
        local difficulties = {
            { key = "easy", label = "Easy (하)", color = {0.18, 0.35, 0.25} },
            { key = "medium", label = "Medium (중)", color = {0.35, 0.30, 0.18} },
            { key = "hard", label = "Hard (상)", color = {0.45, 0.20, 0.20} },
            { key = "back", label = "Back (이전)", color = {0.25, 0.28, 0.32} }
        }
        
        love.graphics.setFont(self.font)
        
        for _, diff in ipairs(difficulties) do
            local btn = diffBtns[diff.key]
            local hover = (mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h)
            
            if hover then
                love.graphics.setColor(diff.color[1] * 1.3, diff.color[2] * 1.3, diff.color[3] * 1.3, 0.95)
            else
                love.graphics.setColor(diff.color[1], diff.color[2], diff.color[3], 0.85)
            end
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 6, 6)
            
            if hover then
                love.graphics.setColor(0.85, 0.68, 0.25, 0.95)
            else
                love.graphics.setColor(diff.color[1] * 1.8, diff.color[2] * 1.8, diff.color[3] * 1.8, 0.6)
            end
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 6, 6)
            
            love.graphics.setColor(0.95, 0.95, 0.95)
            love.graphics.printf(diff.label, btn.x, btn.y + 12, btn.w, "center")
        end
        
        love.graphics.setFont(oldFont)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    love.graphics.setFont(self.font)

    -- 1. 격자판 그리기
    for r = 1, 8 do
        for c = 1, 8 do
            local x = self.offsetX + (c - 1) * self.tileSize
            local y = self.offsetY + (r - 1) * self.tileSize

            -- 밝은 칸과 어두운 칸을 번갈아 가며 칠함
            if (r + c) % 2 == 0 then
                love.graphics.setColor(self.colors.lightTile)
            else
                love.graphics.setColor(self.colors.darkTile)
            end

            love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
        end
    end

    -- 1.5. 선택된 기물 하이라이트 그리기
    if selectedPos then
        local x = self.offsetX + (selectedPos.col - 1) * self.tileSize
        local y = self.offsetY + (selectedPos.row - 1) * self.tileSize
        love.graphics.setColor(0.95, 0.95, 0.40, 0.35) -- 세련된 파스텔톤 노란색 하이라이트
        love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
    end

    -- 1.5.1. 체크 당한 킹 빨간색 하이라이트 그리기
    for _, color in ipairs({"white", "black"}) do
        if board:isInCheck(color) then
            local kr, kc = board:findKing(color)
            if kr and kc then
                local x = self.offsetX + (kc - 1) * self.tileSize
                local y = self.offsetY + (kr - 1) * self.tileSize
                -- 부드러운 빨간색 채우기 + 진한 빨간색 테두리
                love.graphics.setColor(0.95, 0.20, 0.20, 0.45)
                love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
                love.graphics.setColor(0.90, 0.10, 0.10, 0.85)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", x + 1.5, y + 1.5, self.tileSize - 3, self.tileSize - 3)
            end
        end
    end

    -- 1.6. 이동 가능한 유효 경로 가이드(원/링) 그리기
    if validMoves then
        for _, move in ipairs(validMoves) do
            local x = self.offsetX + (move.col - 1) * self.tileSize
            local y = self.offsetY + (move.row - 1) * self.tileSize
            local cx = x + self.tileSize / 2
            local cy = y + self.tileSize / 2

            local targetPiece = board:getPiece(move.row, move.col)
            if targetPiece == nil and not move.isEnPassant then
                -- (1) 빈 칸: 중앙에 작은 반투명 원 그리기
                love.graphics.setColor(0.20, 0.22, 0.25, 0.25)
                love.graphics.circle("fill", cx, cy, self.tileSize * 0.15)
            else
                -- (2) 적군 포획 가능 칸 또는 앙파상 칸: 외곽을 크게 두르는 반투명 링 그리기 (체스닷컴 스타일)
                love.graphics.setColor(0.20, 0.22, 0.25, 0.25)
                love.graphics.setLineWidth(4)
                love.graphics.circle("line", cx, cy, self.tileSize * 0.42)
            end
        end
    end

    -- 2. 보드 외곽 테두리 그리기
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.offsetX, self.offsetY, self.tileSize * 8, self.tileSize * 8)

    -- 3. 라벨 그리기 (옆쪽 1~8 및 아래쪽 a~h)
    love.graphics.setColor(self.colors.label)

    -- (1) 옆쪽(왼쪽)에 1~8 그리기
    for r = 1, 8 do
        local labelText = tostring(9 - r)
        local x = self.offsetX - 25 -- 체스판 왼쪽 외부 배치
        local y = self.offsetY + (r - 1) * self.tileSize + (self.tileSize - self.font:getHeight()) / 2

        -- 텍스트 우측 정렬 느낌으로 그리기
        love.graphics.printf(labelText, x, y, 20, "right")
    end

    -- (2) 아래쪽에 a~h 그리기
    for c = 1, 8 do
        local labelText = string.char(96 + c)
        local x = self.offsetX + (c - 1) * self.tileSize
        local y = self.offsetY + (self.tileSize * 8) + 8 -- 체스판 아래쪽 외부 배치

        -- 텍스트 중앙 정렬 느낌으로 그리기
        love.graphics.printf(labelText, x, y, self.tileSize, "center")
    end

    -- 4. 기물 그리기 (격자 및 라벨 렌더링 후 위에 레이어로 그림)
    love.graphics.setFont(self.pieceFont)

    local pieceSymbols = {
        white = {
            pawn = "♙",
            rook = "♖",
            knight = "♘",
            bishop = "♗",
            queen = "♕",
            king = "♔"
        },
        black = {
            pawn = "♟",
            rook = "♜",
            knight = "♞",
            bishop = "♝",
            queen = "♛",
            king = "♚"
        }
    }

    for r = 1, 8 do
        for c = 1, 8 do
            local piece = board:getPiece(r, c)
            if piece then
                local symbol = pieceSymbols[piece.color] and pieceSymbols[piece.color][piece.type] or "?"
                local x = self.offsetX + (c - 1) * self.tileSize
                local y = self.offsetY + (r - 1) * self.tileSize

                -- 글자 중앙 배치를 위한 오프셋 계산
                local fontHeight = self.pieceFont:getHeight()
                local fontWidth = self.pieceFont:getWidth(symbol)
                local textX = x + (self.tileSize - fontWidth) / 2
                local textY = y + (self.tileSize - fontHeight) / 2

                -- 부드러운 섀도우 효과 (입체감 부여, 크기에 비례하여 2px로 이동, 볼드 처리)
                love.graphics.setColor(0.1, 0.1, 0.1, 0.35)
                love.graphics.print(symbol, textX + 2, textY + 2)
                love.graphics.print(symbol, textX + 3, textY + 2)

                -- 기물 색상 지정 (백색: 부드러운 밝은 아이보리, 흑색: 짙은 차콜)
                if piece.color == "white" then
                    love.graphics.setColor(0.96, 0.94, 0.90)
                else
                    love.graphics.setColor(0.16, 0.18, 0.20)
                end

                -- 기물 출력 (볼드체 시뮬레이션: 1px 가로 오프셋)
                love.graphics.print(symbol, textX, textY)
                love.graphics.print(symbol, textX + 1, textY)
            end
        end
    end

    -- 5. 체크 경고 텍스트 "chack!" 그리기
    local time = love.timer and love.timer.getTime() or 0
    local pulseAlpha = 0.45 + 0.45 * math.sin(time * 9) -- 0.0 ~ 0.9 범위 점멸
    
    for _, color in ipairs({"white", "black"}) do
        if board:isInCheck(color) then
            love.graphics.setFont(self.checkFont)
            love.graphics.setColor(0.9, 0.1, 0.1, pulseAlpha)
            
            local text = "chack!"
            local yPos
            if color == "white" then
                yPos = self.offsetY + (self.tileSize * 8) + 38
            else
                yPos = self.offsetY - 38
            end
            
            love.graphics.printf(text, self.offsetX, yPos, self.tileSize * 8, "center")
        end
    end

    -- =========================================================================
    -- [신규 UI] 우측 패널 수직 정렬 그리기 (x: 570 ~ 810, 너비: 240)
    -- =========================================================================
    
    local rightX = 570
    local panelW = 240
    local displayOrder = {"queen", "rook", "bishop", "knight", "pawn"}

    -- 1. 흑의 남은 시간 (BLACK TIME)
    local blackTimerY = 82
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.colors.label)
    love.graphics.printf("BLACK TIME", rightX, blackTimerY - 22, panelW, "center")
    
    -- 타이머 박스 배경
    if currentTurn == "black" and not isGameOver then
        -- 활성화된 턴인 경우 강조색 (부드러운 주황/노랑 테두리와 어두운 배경)
        love.graphics.setColor(0.25, 0.28, 0.35, 0.95)
        love.graphics.rectangle("fill", rightX, blackTimerY, panelW, 45, 6, 6)
        love.graphics.setColor(0.85, 0.68, 0.25, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", rightX, blackTimerY, panelW, 45, 6, 6)
    else
        love.graphics.setColor(0.18, 0.20, 0.23, 0.8)
        love.graphics.rectangle("fill", rightX, blackTimerY, panelW, 45, 6, 6)
        love.graphics.setColor(0.35, 0.38, 0.42, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", rightX, blackTimerY, panelW, 45, 6, 6)
    end
    
    -- 시간 텍스트 출력
    love.graphics.setFont(self.checkFont)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.printf(formatTime(blackTime), rightX, blackTimerY + 10, panelW, "center")
    
    -- 2. 흑의 획득 기물 (BLACK CAPTURES - 백의 기물 표시)
    local blackCapturesY = 177
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.colors.label)
    love.graphics.printf("BLACK CAPTURES", rightX, blackCapturesY - 22, panelW, "center")
    
    love.graphics.setColor(0.18, 0.20, 0.23, 0.6)
    love.graphics.rectangle("fill", rightX, blackCapturesY, panelW, 50, 6, 6)
    love.graphics.setColor(0.35, 0.38, 0.42, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", rightX, blackCapturesY, panelW, 50, 6, 6)
    
    local blackCapturedCounts = getCounts(capturedPieces and capturedPieces.black)
    local whiteSymbols = {queen = "♕", rook = "♖", bishop = "♗", knight = "♘", pawn = "♙"}
    local blackItems = {}
    for _, typeName in ipairs(displayOrder) do
        local count = blackCapturedCounts[typeName] or 0
        if count > 0 then
            table.insert(blackItems, {symbol = whiteSymbols[typeName], count = count, color = {0.96, 0.94, 0.90}})
        end
    end
    
    if #blackItems == 0 then
        love.graphics.setFont(self.font)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("-", rightX, blackCapturesY + 15, panelW, "center")
    else
        local itemW = 40
        local spacing = 12
        local totalW = #blackItems * itemW + (#blackItems - 1) * spacing
        local startX = rightX + (panelW - totalW) / 2
        
        for idx, item in ipairs(blackItems) do
            local ix = startX + (idx - 1) * (itemW + spacing)
            
            -- 백색 기호 (볼드 처리)
            love.graphics.setFont(self.uiPieceFont)
            love.graphics.setColor(item.color[1], item.color[2], item.color[3])
            love.graphics.print(item.symbol, ix, blackCapturesY + 12)
            love.graphics.print(item.symbol, ix + 1, blackCapturesY + 12)
            
            -- 개수 텍스트
            love.graphics.setFont(self.font)
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print("x" .. tostring(item.count), ix + 22, blackCapturesY + 16)
        end
    end
    
    -- 3. 현재 차례 (ACTIVE TURN)
    local turnY = 255
    love.graphics.setColor(0.15, 0.17, 0.20, 0.9)
    love.graphics.rectangle("fill", rightX, turnY, panelW, 80, 8, 8)
    love.graphics.setColor(0.4, 0.45, 0.5, 0.6)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", rightX, turnY, panelW, 80, 8, 8)
    
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("ACTIVE TURN", rightX, turnY + 15, panelW, "center")
    
    love.graphics.setFont(self.checkFont)
    if isGameOver then
        love.graphics.setColor(0.9, 0.2, 0.2)
        love.graphics.printf("FINISHED", rightX, turnY + 45, panelW, "center")
    elseif currentTurn == "white" then
        love.graphics.setColor(0.95, 0.93, 0.88)
        love.graphics.printf("WHITE (백)", rightX, turnY + 45, panelW, "center")
    else
        love.graphics.setColor(0.25, 0.55, 0.85)
        love.graphics.printf("BLACK (흑)", rightX, turnY + 45, panelW, "center")
    end
    
    -- 4. 백의 획득 기물 (WHITE CAPTURES - 흑의 기물 표시)
    local whiteCapturesY = 385
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.colors.label)
    love.graphics.printf("WHITE CAPTURES", rightX, whiteCapturesY - 22, panelW, "center")
    
    love.graphics.setColor(0.18, 0.20, 0.23, 0.6)
    love.graphics.rectangle("fill", rightX, whiteCapturesY, panelW, 50, 6, 6)
    love.graphics.setColor(0.35, 0.38, 0.42, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", rightX, whiteCapturesY, panelW, 50, 6, 6)
    
    local whiteCapturedCounts = getCounts(capturedPieces and capturedPieces.white)
    local blackSymbols = {queen = "♛", rook = "♜", bishop = "♝", knight = "♞", pawn = "♟"}
    local whiteItems = {}
    for _, typeName in ipairs(displayOrder) do
        local count = whiteCapturedCounts[typeName] or 0
        if count > 0 then
            table.insert(whiteItems, {symbol = blackSymbols[typeName], count = count, color = {0.16, 0.18, 0.20}})
        end
    end
    
    if #whiteItems == 0 then
        love.graphics.setFont(self.font)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("-", rightX, whiteCapturesY + 15, panelW, "center")
    else
        local itemW = 40
        local spacing = 12
        local totalW = #whiteItems * itemW + (#whiteItems - 1) * spacing
        local startX = rightX + (panelW - totalW) / 2
        
        for idx, item in ipairs(whiteItems) do
            local ix = startX + (idx - 1) * (itemW + spacing)
            
            -- 흑색 기호 (볼드 처리)
            love.graphics.setFont(self.uiPieceFont)
            love.graphics.setColor(item.color[1], item.color[2], item.color[3])
            love.graphics.print(item.symbol, ix, whiteCapturesY + 12)
            love.graphics.print(item.symbol, ix + 1, whiteCapturesY + 12)
            
            -- 개수 텍스트
            love.graphics.setFont(self.font)
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print("x" .. tostring(item.count), ix + 22, whiteCapturesY + 16)
        end
    end
    
    -- 5. 백의 남은 시간 (WHITE TIME)
    local whiteTimerY = 485
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.colors.label)
    love.graphics.printf("WHITE TIME", rightX, whiteTimerY - 22, panelW, "center")
    
    -- 타이머 박스 배경
    if currentTurn == "white" and not isGameOver then
        love.graphics.setColor(0.25, 0.28, 0.35, 0.95)
        love.graphics.rectangle("fill", rightX, whiteTimerY, panelW, 45, 6, 6)
        love.graphics.setColor(0.85, 0.68, 0.25, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", rightX, whiteTimerY, panelW, 45, 6, 6)
    else
        love.graphics.setColor(0.18, 0.20, 0.23, 0.8)
        love.graphics.rectangle("fill", rightX, whiteTimerY, panelW, 45, 6, 6)
        love.graphics.setColor(0.35, 0.38, 0.42, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", rightX, whiteTimerY, panelW, 45, 6, 6)
    end
    
    -- 시간 텍스트 출력
    love.graphics.setFont(self.checkFont)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.printf(formatTime(whiteTime), rightX, whiteTimerY + 10, panelW, "center")

    -- 5.5. 기권 (RESIGN) 및 무승부 제안 (OFFER DRAW) 버튼 그리기
    local mx, my = 0, 0
    if love.mouse and love.mouse.getPosition then
        mx, my = love.mouse.getPosition()
    end
    
    local resignBtn = self:getResignButtonRect()
    local drawBtn = self:getDrawOfferButtonRect()
    
    local resignHover = (mx >= resignBtn.x and mx <= resignBtn.x + resignBtn.w and my >= resignBtn.y and my <= resignBtn.y + resignBtn.h)
    local drawHover = (mx >= drawBtn.x and mx <= drawBtn.x + drawBtn.w and my >= drawBtn.y and my <= drawBtn.y + drawBtn.h)
    
    love.graphics.setFont(self.font)
    
    -- 기권 버튼 그리기 (부드러운 빨간색 계열)
    if resignHover and not isGameOver then
        love.graphics.setColor(0.75, 0.25, 0.25, 0.9)
    else
        love.graphics.setColor(0.55, 0.15, 0.15, 0.75)
    end
    love.graphics.rectangle("fill", resignBtn.x, resignBtn.y, resignBtn.w, resignBtn.h, 6, 6)
    love.graphics.setColor(0.85, 0.35, 0.35, 0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", resignBtn.x, resignBtn.y, resignBtn.w, resignBtn.h, 6, 6)
    
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.printf("RESIGN", resignBtn.x, resignBtn.y + 8, resignBtn.w, "center")
    
    -- 무승부 제안 버튼 그리기 (부드러운 파란색/청회색 계열)
    if drawHover and not isGameOver and not pendingPromotion then
        love.graphics.setColor(0.25, 0.45, 0.65, 0.9)
    else
        love.graphics.setColor(0.15, 0.30, 0.45, 0.75)
    end
    love.graphics.rectangle("fill", drawBtn.x, drawBtn.y, drawBtn.w, drawBtn.h, 6, 6)
    love.graphics.setColor(0.35, 0.55, 0.75, 0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", drawBtn.x, drawBtn.y, drawBtn.w, drawBtn.h, 6, 6)
    
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.printf("DRAW", drawBtn.x, drawBtn.y + 8, drawBtn.w, "center")

    -- 6. 게임종료 오버레이 그리기
    if isGameOver and winner then
        local w, h = love.graphics.getDimensions()
        
        love.graphics.setColor(0.08, 0.08, 0.10, 0.65)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        -- 중앙 팝업 박스
        local boxWidth = 360
        local boxHeight = 230
        local boxX = (w - boxWidth) / 2
        local boxY = (h - boxHeight) / 2
        
        love.graphics.setColor(0.12, 0.14, 0.18, 0.95)
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 12, 12)
        
        love.graphics.setColor(0.85, 0.68, 0.25, 0.85)
        love.graphics.setLineWidth(2.5)
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 12, 12)
        
        -- 종료 원인에 따른 타이틀 및 메시지 설정
        local titleText = "GAME OVER"
        local titleColor = { 0.9, 0.2, 0.2 }
        local detailText1 = ""
        local detailText2 = ""
        
        if gameOverReason == "checkmate" then
            titleText = "CHECKMATE!"
            detailText1 = "Win Player: " .. (winner == "white" and "White (백)" or "Black (흑)")
            detailText2 = "Lose Player: " .. (winner == "white" and "Black (흑)" or "White (백)")
        elseif gameOverReason == "timeout" then
            titleText = "TIMEOUT!"
            detailText1 = "Win Player: " .. (winner == "white" and "White (백)" or "Black (흑)")
            detailText2 = "Lose Player: " .. (winner == "white" and "Black (흑)" or "White (백)")
        elseif gameOverReason == "resign" then
            titleText = "RESIGNATION!"
            detailText1 = "Win Player: " .. (winner == "white" and "White (백)" or "Black (흑)")
            detailText2 = "Lose Player: " .. (winner == "white" and "Black (흑) (기권)" or "White (백) (기권)")
        elseif gameOverReason == "stalemate" then
            titleText = "STALEMATE!"
            titleColor = { 0.25, 0.55, 0.85 }
            detailText1 = "Draw Game (무승부)"
            detailText2 = "No legal moves left."
        elseif gameOverReason == "draw_offer" then
            titleText = "DRAW AGREED!"
            titleColor = { 0.25, 0.55, 0.85 }
            detailText1 = "Draw Game (무승부)"
            detailText2 = "Players agreed to a draw."
        elseif gameOverReason == "insufficient_material" then
            titleText = "DRAW!"
            titleColor = { 0.25, 0.55, 0.85 }
            detailText1 = "Draw Game (무승부)"
            detailText2 = "Insufficient material to checkmate."
        else
            if winner == "draw" then
                titleText = "DRAW!"
                titleColor = { 0.25, 0.55, 0.85 }
                detailText1 = "Draw Game (무승부)"
            else
                titleText = "GAME OVER!"
                detailText1 = "Winner: " .. (winner == "white" and "White" or "Black")
            end
        end
        
        love.graphics.setFont(self.gameOverTitleFont)
        love.graphics.setColor(titleColor)
        love.graphics.printf(titleText, boxX, boxY + 25, boxWidth, "center")
        
        -- 승자 및 패자/상세 텍스트
        love.graphics.setFont(self.gameOverTextFont)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf(detailText1, boxX, boxY + 80, boxWidth, "center")
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf(detailText2, boxX, boxY + 115, boxWidth, "center")

        -- 메인 메뉴 이동 버튼 그리기
        local menuBtn = self:getGameOverMenuButtonRect()
        local menuHover = (mx >= menuBtn.x and mx <= menuBtn.x + menuBtn.w and my >= menuBtn.y and my <= menuBtn.y + menuBtn.h)
        
        if menuHover then
            love.graphics.setColor(0.85, 0.68, 0.25, 0.95)
        else
            love.graphics.setColor(0.20, 0.24, 0.30, 0.9)
        end
        love.graphics.rectangle("fill", menuBtn.x, menuBtn.y, menuBtn.w, menuBtn.h, 6, 6)
        
        if menuHover then
            love.graphics.setColor(0.95, 0.95, 0.95, 0.95)
        else
            love.graphics.setColor(0.85, 0.68, 0.25, 0.75)
        end
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", menuBtn.x, menuBtn.y, menuBtn.w, menuBtn.h, 6, 6)
        
        love.graphics.setFont(self.font)
        if menuHover then
            love.graphics.setColor(0.12, 0.14, 0.18)
        else
            love.graphics.setColor(0.95, 0.95, 0.95)
        end
        love.graphics.printf("MENU (메뉴)", menuBtn.x, menuBtn.y + 8, menuBtn.w, "center")
    end

    -- 6.5. 무승부 제안 (Draw Offer) 팝업 모달 그리기
    if pendingDrawOffer then
        local w, h = love.graphics.getDimensions()
        
        love.graphics.setColor(0.08, 0.08, 0.10, 0.5)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        local buttons, boxX, boxY, boxWidth, boxHeight = self:getDrawOfferModalButtons()
        
        love.graphics.setColor(0.15, 0.17, 0.22, 0.95)
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10, 10)
        love.graphics.setColor(0.4, 0.45, 0.5, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)
        
        love.graphics.setFont(self.font)
        love.graphics.setColor(0.9, 0.9, 0.9)
        local offerText = "Draw Offered by " .. (currentTurn == "white" and "WHITE" or "BLACK")
        love.graphics.printf(offerText, boxX, boxY + 18, boxWidth, "center")
        
        local accept = buttons.accept
        local decline = buttons.decline
        
        local acceptHover = (mx >= accept.x and mx <= accept.x + accept.w and my >= accept.y and my <= accept.y + accept.h)
        local declineHover = (mx >= decline.x and mx <= decline.x + decline.w and my >= decline.y and my <= decline.y + decline.h)
        
        -- ACCEPT 버튼
        if acceptHover then
            love.graphics.setColor(0.25, 0.55, 0.35, 0.9)
        else
            love.graphics.setColor(0.18, 0.38, 0.25, 0.8)
        end
        love.graphics.rectangle("fill", accept.x, accept.y, accept.w, accept.h, 6, 6)
        love.graphics.setColor(0.45, 0.75, 0.55, 0.9)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", accept.x, accept.y, accept.w, accept.h, 6, 6)
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.printf(accept.text, accept.x, accept.y + 8, accept.w, "center")
        
        -- DECLINE 버튼
        if declineHover then
            love.graphics.setColor(0.75, 0.25, 0.25, 0.9)
        else
            love.graphics.setColor(0.55, 0.15, 0.15, 0.8)
        end
        love.graphics.rectangle("fill", decline.x, decline.y, decline.w, decline.h, 6, 6)
        love.graphics.setColor(0.85, 0.35, 0.35, 0.9)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", decline.x, decline.y, decline.w, decline.h, 6, 6)
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.printf(decline.text, decline.x, decline.y + 8, decline.w, "center")
    end

    -- 7. 프로모션 선택 오버레이 그리기
    if pendingPromotion then
        local w, h = love.graphics.getDimensions()
        
        love.graphics.setColor(0.08, 0.08, 0.10, 0.5)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        local buttons, boxX, boxY, boxWidth, boxHeight = self:getPromotionButtons(pendingPromotion)
        
        love.graphics.setColor(0.15, 0.17, 0.22, 0.95)
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10, 10)
        
        love.graphics.setColor(0.4, 0.45, 0.5, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)
        
        love.graphics.setFont(self.font)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf("PROMOTION", boxX, boxY + 15, boxWidth, "center")
        
        local mx, my = 0, 0
        if love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        
        -- 4개 버튼 그리기
        love.graphics.setFont(self.promoPieceFont)
        for _, btn in ipairs(buttons) do
            local isHovered = (mx >= btn.x and mx <= btn.x + btn.size and my >= btn.y and my <= btn.y + btn.size)
            
            if isHovered then
                love.graphics.setColor(0.25, 0.35, 0.50, 0.9)
            else
                love.graphics.setColor(0.18, 0.20, 0.25, 0.9)
            end
            love.graphics.rectangle("fill", btn.x, btn.y, btn.size, btn.size, 6, 6)
            
            if isHovered then
                love.graphics.setColor(0.85, 0.68, 0.25, 0.9)
            else
                love.graphics.setColor(0.35, 0.40, 0.45, 0.7)
            end
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", btn.x, btn.y, btn.size, btn.size, 6, 6)
            
            -- 기물 문자 출력
            local fontHeight = self.promoPieceFont:getHeight()
            local fontWidth = self.promoPieceFont:getWidth(btn.symbol)
            local tx = btn.x + (btn.size - fontWidth) / 2
            local ty = btn.y + (btn.size - fontHeight) / 2
            
            if pendingPromotion.color == "white" then
                love.graphics.setColor(0.96, 0.94, 0.90)
            else
                love.graphics.setColor(0.16, 0.18, 0.20)
            end
            
            love.graphics.print(btn.symbol, tx, ty)
            love.graphics.print(btn.symbol, tx + 1, ty)
        end
    end

    -- 원래 폰트 및 색상 복구
    love.graphics.setFont(oldFont)
    love.graphics.setColor(1, 1, 1, 1)
end

-- 프로모션 UI 버튼들의 정보(좌표, 심볼 등)를 계산하여 반환합니다.
function BoardRenderer:getPromotionButtons(pendingPromotion)
    local w, h = love.graphics.getDimensions()
    local boxWidth = 320
    local boxHeight = 120
    local boxX = (w - boxWidth) / 2
    local boxY = (h - boxHeight) / 2
    
    local btnSize = 50
    local spacing = 15
    local totalWidth = 4 * btnSize + 3 * spacing
    local startX = boxX + (boxWidth - totalWidth) / 2
    local startY = boxY + 50
    
    local options = {"queen", "rook", "bishop", "knight"}
    local symbols = {
        white = {queen = "♕", rook = "♖", bishop = "♗", knight = "♘"},
        black = {queen = "♛", rook = "♜", bishop = "♝", knight = "♞"}
    }
    
    local buttons = {}
    for i, opt in ipairs(options) do
        local bx = startX + (i - 1) * (btnSize + spacing)
        local by = startY
        local symbol = symbols[pendingPromotion.color] and symbols[pendingPromotion.color][opt] or "?"
        table.insert(buttons, {
            type = opt,
            symbol = symbol,
            x = bx,
            y = by,
            size = btnSize
        })
    end
    
    return buttons, boxX, boxY, boxWidth, boxHeight
end

-- 마우스 클릭 위치에 맞는 프로모션 옵션을 확인하여 반환합니다.
function BoardRenderer:getPromotionOptionAt(x, y, pendingPromotion)
    local buttons = self:getPromotionButtons(pendingPromotion)
    for _, btn in ipairs(buttons) do
        if x >= btn.x and x <= btn.x + btn.size and y >= btn.y and y <= btn.y + btn.size then
            return btn.type
        end
    end
    return nil
end

-- 기권 버튼 위치 정보 반환
function BoardRenderer:getResignButtonRect()
    local rightX = 570
    local btnY = 545
    local btnW = 110
    local btnH = 35
    return { x = rightX, y = btnY, w = btnW, h = btnH }
end

-- 무승부 제안 버튼 위치 정보 반환
function BoardRenderer:getDrawOfferButtonRect()
    local rightX = 570
    local panelW = 240
    local btnW = 110
    local btnH = 35
    local btnY = 545
    return { x = rightX + panelW - btnW, y = btnY, w = btnW, h = btnH }
end

-- 무승부 제안 모달 내 버튼 위치 정보 반환
function BoardRenderer:getDrawOfferModalButtons()
    local w, h = love.graphics.getDimensions()
    local boxW, boxH = 320, 120
    local boxX = (w - boxW) / 2
    local boxY = (h - boxH) / 2
    
    return {
        accept = { x = boxX + 30, y = boxY + 60, w = 110, h = 35, text = "ACCEPT" },
        decline = { x = boxX + boxW - 140, y = boxY + 60, w = 110, h = 35, text = "DECLINE" }
    }, boxX, boxY, boxW, boxH
end

-- 메인 메뉴 버튼 영역 정보 반환
function BoardRenderer:getMenuButtons()
    local w, h = love.graphics.getDimensions()
    local btnW = 240
    local btnH = 50
    local btnX = (w - btnW) / 2
    return {
        vs_ai = { x = btnX, y = 260, w = btnW, h = btnH },
        vs_offline = { x = btnX, y = 330, w = btnW, h = btnH }
    }
end

-- 난이도 선택 버튼 영역 정보 반환
function BoardRenderer:getDifficultyButtons()
    local w, h = love.graphics.getDimensions()
    local btnW = 240
    local btnH = 45
    local btnX = (w - btnW) / 2
    return {
        easy = { x = btnX, y = 220, w = btnW, h = btnH },
        medium = { x = btnX, y = 280, w = btnW, h = btnH },
        hard = { x = btnX, y = 340, w = btnW, h = btnH },
        back = { x = btnX, y = 415, w = btnW, h = btnH }
    }
end

-- 게임 종료 창의 메뉴 이동 버튼 영역 정보 반환
function BoardRenderer:getGameOverMenuButtonRect()
    local w, h = love.graphics.getDimensions()
    local boxW, boxH = 360, 230
    local boxX = (w - boxW) / 2
    local boxY = (h - boxH) / 2
    return { x = boxX + 110, y = boxY + 170, w = 140, h = 35 }
end

return BoardRenderer
