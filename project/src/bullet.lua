local Bullet = {}
Bullet.__index = Bullet

--- Bullet 생성자
-- @param x (number) 초기 x 좌표
-- @param y (number) 초기 y 좌표
-- @param vx (number) x 방향 속도
-- @param vy (number) y 방향 속도
-- @param radius (number|nil) 탄환 반지름 (기본값: 0.12)
function Bullet:new(x, y, vx, vy, radius)
    local obj = {
        x = x or 0,
        y = y or 0,
        vx = vx or 0,
        vy = vy or 0,
        radius = radius or 0.12,
        isDead = false
    }
    setmetatable(obj, self)
    return obj
end

--- 탄환 업데이트
-- @param dt (number) 델타 타임
function Bullet:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

--- 탄환 그리기
function Bullet:draw()
    -- 주황색/노란색 빛깔의 구체 렌더링
    love.graphics.setColor(1, 0.5, 0.1, 0.9)
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Bullet
