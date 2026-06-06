--[[
1. 유니티의 orthographic camera를 루아로 구현해보자.
2. 0, 0을 기준으로 카메라를 이동시켜보자.


local Camera = {}
Camera.__index = Camera

--- Camera 생성자
-- @param x (number|nil) 카메라의 초기 월드 x 좌표 (기본값: 0)
-- @param y (number|nil) 카메라의 초기 월드 y 좌표 (기본값: 0)
-- @param orthoSize (number|nil) 카메라의 종횡비 절반 높이 (기본값: 5)
function Camera:new(x, y, orthoSize)
    local obj = {
        x = x or 0,
        y = y or 0,
        orthoSize = orthoSize or 5
    }
    setmetatable(obj, self)
    return obj
end

--- 카메라의 절대 월드 위치 설정
-- @param x (number)
-- @param y (number)
function Camera:setPosition(x, y)
    self.x = x or 0
    self.y = y or 0
end

--- 카메라 위치 오프셋 이동
-- @param dx (number)
-- @param dy (number)
function Camera:move(dx, dy)
    self.x = self.x + (dx or 0)
    self.y = self.y + (dy or 0)
end

--- 카메라의 orthoSize(월드 기준 절반 높이) 설정
-- @param size (number) 0보다 큰 값이어야 함
function Camera:setOrthoSize(size)
    -- Division by zero 및 뒤집힘 방지를 위해 최소값 0.1로 클램프
    self.orthoSize = math.max(0.1, size or 5)
end

--- 카메라의 orthoSize 반환
-- @return number
function Camera:getOrthoSize()
    return self.orthoSize
end

--- 월드 단위 당 화면 픽셀 비율 계산
-- @return number
function Camera:getScale()
    local _, screenHeight = love.graphics.getDimensions()
    return screenHeight / (2 * self.orthoSize)
end

--- 월드 공간 렌더링 시작 (Love2D 그래픽 상태 스택에 카메라 변환 행렬 적용)
function Camera:attach()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local scale = self:getScale()

    love.graphics.push()

    -- 1. 화면 중앙으로 원점(0, 0) 이동
    love.graphics.translate(screenWidth / 2, screenHeight / 2)

    -- 2. 스케일 적용 (유니티는 Y가 위로 갈수록 양수이므로 y 스케일에 -1 곱함)
    love.graphics.scale(scale, -scale)

    -- 3. 카메라 좌표만큼 월드 좌표 평행이동
    love.graphics.translate(-self.x, -self.y)
end

--- 월드 공간 렌더링 해제 (이전 그래픽 상태 복원)
function Camera:detach()
    love.graphics.pop()
end

--- 월드 좌표를 화면 좌표로 변환
-- @param wx (number) 월드 X 좌표
-- @param wy (number) 월드 Y 좌표
-- @return number, number 화면 X 좌표, 화면 Y 좌표
function Camera:worldToScreen(wx, wy)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local scale = self:getScale()

    local sx = screenWidth / 2 + (wx - self.x) * scale
    local sy = screenHeight / 2 - (wy - self.y) * scale
    return sx, sy
end

--- 화면 좌표를 월드 좌표로 변환
-- @param sx (number) 화면 X 좌표
-- @param sy (number) 화면 Y 좌표
-- @return number, number 월드 X 좌표, 월드 Y 좌표
function Camera:screenToWorld(sx, sy)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local scale = self:getScale()

    local wx = self.x + (sx - screenWidth / 2) / scale
    local wy = self.y + (screenHeight / 2 - sy) / scale
    return wx, wy
end

return Camera ]]
