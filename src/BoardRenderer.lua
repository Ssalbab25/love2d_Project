-- BoardRenderer.lua: 체스판 화면 렌더링 클래스
-- SOLID: SRP를 준수하여 화면에 보드와 라벨을 그리는 역할만 담당합니다.
--        DIP를 준수하여 보드 데이터 상태(Board 객체)를 넘겨받아 렌더링에 활용합니다.

local Object = require "libs.classic"
local BoardRenderer = Object:extend()

function BoardRenderer:new()
    -- 디자인 테마 색상 설정 (세련된 크림 & 다크 그레이 계열)
    self.colors = {
        lightTile = { 0.94, 0.93, 0.88 },  -- 부드러운 크림색
        darkTile = { 0.46, 0.53, 0.60 },   -- 모던한 블루-그레이/슬레이트색
        label = { 0.20, 0.22, 0.25 },      -- 짙은 차콜색 (라벨 텍스트용)
        border = { 0.15, 0.15, 0.15 }      -- 경계선 색상
    }
    
    -- 기본 레이아웃 변수 설정 (창 크기 대비 적절한 사이즈)
    self.tileSize = 60
    self.offsetX = 0
    self.offsetY = 0
    
    -- 폰트 초기화 (가로/세로 중앙 맞춤용)
    self.font = love.graphics.newFont(16)
end

-- 창 크기가 변경되거나 최초 로드 시 오프셋을 계산합니다.
function BoardRenderer:updateLayout(windowWidth, windowHeight)
    local boardSize = self.tileSize * 8
    self.offsetX = (windowWidth - boardSize) / 2
    self.offsetY = (windowHeight - boardSize) / 2
end

-- 체스판 및 라벨 그리기
function BoardRenderer:draw(board)
    -- 화면 중앙 배치 갱신 (반응형 대응)
    local w, h = love.graphics.getDimensions()
    self:updateLayout(w, h)
    
    local oldFont = love.graphics.getFont()
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
    
    -- 2. 보드 외곽 테두리 그리기
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.offsetX, self.offsetY, self.tileSize * 8, self.tileSize * 8)
    
    -- 3. 라벨 그리기 (옆쪽 1~8 및 아래쪽 a~h)
    love.graphics.setColor(self.colors.label)
    
    -- (1) 옆쪽(왼쪽)에 1~8 그리기
    -- 체스는 백색 관점에서 위가 8행, 아래가 1행이므로, r = 1일 때 8, r = 8일 때 1이 됨
    for r = 1, 8 do
        local labelText = tostring(9 - r)
        local x = self.offsetX - 25 -- 체스판 왼쪽 외부 배치
        local y = self.offsetY + (r - 1) * self.tileSize + (self.tileSize - self.font:getHeight()) / 2
        
        -- 텍스트 우측 정렬 느낌으로 그리기
        love.graphics.printf(labelText, x, y, 20, "right")
    end
    
    -- (2) 아래쪽에 a~h 그리기
    -- c = 1 -> 'a', c = 8 -> 'h'
    for c = 1, 8 do
        local labelText = string.char(96 + c)
        local x = self.offsetX + (c - 1) * self.tileSize
        local y = self.offsetY + (self.tileSize * 8) + 8 -- 체스판 아래쪽 외부 배치
        
        -- 텍스트 중앙 정렬 느낌으로 그리기
        love.graphics.printf(labelText, x, y, self.tileSize, "center")
    end
    
    -- 원래 폰트 및 색상 복구
    love.graphics.setFont(oldFont)
    love.graphics.setColor(1, 1, 1, 1)
end

return BoardRenderer
