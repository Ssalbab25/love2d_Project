-- InputHandler.lua: 마우스 클릭 및 입력 좌표 변환 클래스
-- SOLID: 
-- - SRP (단일 책임 원칙): 오직 화면상의 마우스 픽셀 좌표(x, y)를 게임 보드의 8x8 격자 좌표(row, col)로 물리 변환하는 책임만 집니다.
-- - DIP (의존성 역전 원칙): BoardRenderer의 구체적인 크기 변수(tileSize, offsetX, offsetY)를 간접적으로 활용하되, 입력 매핑 자체를 전담합니다.

local Object = require "libs.classic"
local InputHandler = Object:extend()

function InputHandler:new(boardRenderer)
    self.renderer = boardRenderer
end

-- 화면 좌표 (x, y)를 보드 (row, col)로 변환
-- 반환값: row, col (보드 내부 클릭 시), 또는 nil, nil (보드 외부 클릭 시)
function InputHandler:toBoardCoords(x, y)
    if not self.renderer then return nil, nil end
    
    local tileSize = self.renderer.tileSize
    local ox = self.renderer.offsetX
    local oy = self.renderer.offsetY
    
    -- 마우스 클릭 위치가 8x8 체스판 내부 영역인지 판별
    if x >= ox and x < ox + tileSize * 8 and y >= oy and y < oy + tileSize * 8 then
        local col = math.floor((x - ox) / tileSize) + 1
        local row = math.floor((y - oy) / tileSize) + 1
        return row, col
    end
    
    return nil, nil
end

return InputHandler
