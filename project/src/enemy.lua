local Enemy = {}
Enemy.__index = Enemy

--- Enemy 생성자
-- @param x (number|nil) 적 x 좌표 (기본값: 0)
-- @param y (number|nil) 적 y 좌표 (기본값: 0)
-- @param size (number|nil) 적 크기 (기본값: 1.2)
-- @param type (string|nil) 적 타입 (기본값: "square", "triangle", "pentagon")
function Enemy:new(x, y, size, type)
    local obj = {
        x = x or 0,
        y = y or 0,
        size = size or 1.2,
        type = type or "square",
        angle = 0,
        shootTimer = 0,
        isDead = false,
        respawnTimer = 0
    }
    setmetatable(obj, self)
    return obj
end

--- 꼭짓점 좌표 계산
function Enemy:getVertices()
    local halfSize = self.size / 2
    local cosA = math.cos(self.angle)
    local sinA = math.sin(self.angle)

    local baseVertices

    if self.type == "triangle" then
        -- 삼각형 (3개 꼭짓점)
        baseVertices = {
            { 0, halfSize },          -- 1: 상단
            { -halfSize, -halfSize }, -- 2: 좌하단
            { halfSize, -halfSize }   -- 3: 우하단
        }
    elseif self.type == "pentagon" then
        -- 오각형 (5개 꼭짓점)
        baseVertices = {}
        for i = 0, 4 do
            local angle = (i * 2 * math.pi / 5) - math.pi / 2
            table.insert(baseVertices, {
                math.cos(angle) * halfSize,
                math.sin(angle) * halfSize
            })
        end
    else
        -- 사각형 (기본값)
        baseVertices = {
            { -halfSize, -halfSize }, -- 1: 좌하단
            { halfSize, -halfSize },  -- 2: 우하단 (1 -> 2 가 노란색 면)
            { halfSize, halfSize },   -- 3: 우상단
            { -halfSize, halfSize }   -- 4: 좌상단
        }
    end

    local vertices = {}
    for i, v in ipairs(baseVertices) do
        local rotatedX = v[1] * cosA - v[2] * sinA
        local rotatedY = v[1] * sinA + v[2] * cosA
        vertices[i] = { rotatedX + self.x, rotatedY + self.y }
    end

    return vertices
end

--- 적 업데이트
-- @param dt (number)
-- @param playerX (number) 플레이어의 현재 x
-- @param playerY (number) 플레이어의 현재 y
-- @param spawnBulletFunc (function) 탄환을 생성할 메인 루프 콜백 함수
function Enemy:update(dt, playerX, playerY, spawnBulletFunc)
    if self.isDead then
        self.respawnTimer = self.respawnTimer + dt
        if self.respawnTimer >= 3.0 then
            self.isDead = false
            self.respawnTimer = 0
            self.angle = 0
            self.shootTimer = 0
        end
        return
    end

    -- 1. 서서히 회전 (관성감 충족을 위해 초당 약 45도 회전)
    self.angle = self.angle + 0.8 * dt

    -- 2. 타입에 따른 공격 패턴
    self.shootTimer = self.shootTimer + dt
    if self.shootTimer >= 1.0 then
        self.shootTimer = self.shootTimer - 1.0

        local dx = playerX - self.x
        local dy = playerY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if self.type == "triangle" then
            -- 삼각형: 3점사 (플레이어 방향으로 3발 발사)
            if dist > 0 then
                local dirX = dx / dist
                local dirY = dy / dist
                local bulletSpeed = 6

                -- 중앙 발사
                spawnBulletFunc(self.x, self.y, dirX * bulletSpeed, dirY * bulletSpeed)
                -- 좌측 발사
                local angle1 = math.atan2(dirY, dirX) - 0.2
                spawnBulletFunc(self.x, self.y, math.cos(angle1) * bulletSpeed, math.sin(angle1) * bulletSpeed)
                -- 우측 발사
                local angle2 = math.atan2(dirY, dirX) + 0.2
                spawnBulletFunc(self.x, self.y, math.cos(angle2) * bulletSpeed, math.sin(angle2) * bulletSpeed)
            end
        elseif self.type == "pentagon" then
            -- 오각형: 방사형 3발 발사
            local bulletSpeed = 6
            for i = 0, 2 do
                local angle = self.angle + (i * 2 * math.pi / 3)
                spawnBulletFunc(self.x, self.y, math.cos(angle) * bulletSpeed, math.sin(angle) * bulletSpeed)
            end
        else
            -- 사각형: 플레이어를 향해 단일 발사
            if dist > 0 then
                local dirX = dx / dist
                local dirY = dy / dist
                spawnBulletFunc(self.x, self.y, dirX * 6, dirY * 6)
            end
        end
    end
end

--- 적 그리기
function Enemy:draw()
    if self.isDead then return end

    local vertices = self:getVertices()
    local n = #vertices

    -- 1. 빨간색 몸체 그리기 (내부 채우기)
    local flatVertices = {}
    for _, v in ipairs(vertices) do
        table.insert(flatVertices, v[1])
        table.insert(flatVertices, v[2])
    end
    love.graphics.setColor(0.8, 0.15, 0.15, 0.85)
    love.graphics.polygon("fill", flatVertices)

    -- 2. 빨간색 외곽선 그리기 (약점 면 제외)
    love.graphics.setLineWidth(0.06)
    for i = 2, n do
        local nextIdx = i % n + 1
        local v1 = vertices[i]
        local v2 = vertices[nextIdx]
        love.graphics.setColor(0.9, 0.2, 0.2, 1)
        love.graphics.line(v1[1], v1[2], v2[1], v2[2])
    end

    -- 3. 노란색 약점 면 그리기 (1번 면: v1 -> v2)
    local v1 = vertices[1]
    local v2 = vertices[2]
    love.graphics.setColor(1.0, 0.9, 0.15, 1)
    love.graphics.setLineWidth(0.08) -- 약점임을 부각하기 위해 조금 더 굵게
    love.graphics.line(v1[1], v1[2], v2[1], v2[2])
end

--- 점과 선분 사이의 거리 계산 헬퍼 함수
local function pointToSegmentDistance(px, py, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local lengthSq = dx * dx + dy * dy

    if lengthSq == 0 then
        return math.sqrt((px - x1) ^ 2 + (py - y1) ^ 2)
    end

    local t = math.max(0, math.min(1, ((px - x1) * dx + (py - y1) * dy) / lengthSq))
    local nearestX = x1 + t * dx
    local nearestY = y1 + t * dy

    return math.sqrt((px - nearestX) ^ 2 + (py - nearestY) ^ 2), nearestX, nearestY
end

--- 충돌 감지
-- @param playerX (number)
-- @param playerY (number)
-- @param playerRadius (number)
-- @return collided (boolean), isYellow (boolean), normalX (number), normalY (number)
function Enemy:checkCollision(playerX, playerY, playerRadius)
    if self.isDead then return false, false, 0, 0 end

    local vertices = self:getVertices()
    local n = #vertices

    for i = 1, n do
        local nextIdx = i % n + 1
        local v1 = vertices[i]
        local v2 = vertices[nextIdx]

        local dist, nearestX, nearestY = pointToSegmentDistance(
            playerX, playerY,
            v1[1], v1[2],
            v2[1], v2[2]
        )

        if dist < playerRadius then
            -- 충돌 발생!
            local normalX = playerX - nearestX
            local normalY = playerY - nearestY
            local normalLength = math.sqrt(normalX * normalX + normalY * normalY)

            if normalLength > 0 then
                normalX = normalX / normalLength
                normalY = normalY / normalLength
            else
                normalX = 0
                normalY = 1
            end

            local isYellow = (i == 1) -- 1번 면(v1->v2) 충돌일 때 노란색 충돌
            return true, isYellow, normalX, normalY
        end
    end

    return false, false, 0, 0
end

--- 리셋
function Enemy:reset()
    self.isDead = false
    self.respawnTimer = 0
    self.angle = 0
    self.shootTimer = 0
end

return Enemy
