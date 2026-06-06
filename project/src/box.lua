local Box = {}
Box.__index = Box

--- Box 생성자
-- @param x (number|nil) 박스 중심 월드 x 좌표 (기본값: 0)
-- @param y (number|nil) 박스 중심 월드 y 좌표 (기본값: 0)
-- @param size (number|nil) 박스 크기 (기본값: 5)
-- @param angle (number|nil) 회전각 (라디안, 기본값: 0)
-- @param numSides (number|nil) 다각형의 갯수 (기본값: 4, 최소: 3)
function Box:new(x, y, size, angle, numSides)
    local sides = numSides or 4
    if sides < 4 then
        sides = 4
    end
    if sides % 2 ~= 0 then
        sides = sides + 1
    end

    local obj = {
        x = x or 0,
        y = y or 0,
        size = size or 5,
        angle = angle or 0,
        numSides = sides,
        isPortal = false -- 포탈 모드 여부
    }
    setmetatable(obj, self)
    return obj
end

--- 박스 회전각 설정
-- @param angle (number) 회전각 (라디안)
function Box:setAngle(angle)
    self.angle = angle
end

--- 박스 회전 (상대적)
-- @param deltaAngle (number) 회전할 각도 (라디안)
function Box:rotate(deltaAngle)
    self.angle = self.angle + deltaAngle
end

--- 다각형 갯수 증가
function Box:addSide()
    self.numSides = self.numSides + 2
end

--- 다각형 갯수 감소 (최소 4, 짝수 유지)
function Box:removeSide()
    self.numSides = math.max(4, self.numSides - 2)
end

--- 포탈 모드 토글
function Box:togglePortal()
    self.isPortal = not self.isPortal
end

--- 다각형의 꼭짓점 좌표 계산
-- @return table 꼭짓점 좌표들의 테이블 {{x1,y1}, {x2,y2}, ...}
function Box:getVertices()
    local halfSize = self.size / 2
    local cosA = math.cos(self.angle)
    local sinA = math.sin(self.angle)

    -- 정다각형 꼭짓점 계산
    local baseVertices = {}
    for i = 0, self.numSides - 1 do
        local angle = (2 * math.pi * i) / self.numSides - math.pi / 2
        local x = halfSize * math.cos(angle)
        local y = halfSize * math.sin(angle)
        table.insert(baseVertices, { x, y })
    end

    -- 회전 변환 적용
    local vertices = {}
    for i, v in ipairs(baseVertices) do
        local rotatedX = v[1] * cosA - v[2] * sinA
        local rotatedY = v[1] * sinA + v[2] * cosA
        vertices[i] = { rotatedX + self.x, rotatedY + self.y }
    end

    return vertices
end

--- 박스 그리기 (속이 비어있는 다각형)
function Box:draw()
    local vertices = self:getVertices()

    -- 포탈 모드이면 파란색, 아니면 흰색
    if self.isPortal then
        love.graphics.setColor(0.2, 0.6, 1, 0.8)
    else
        love.graphics.setColor(1, 1, 1, 0.8)
    end
    love.graphics.setLineWidth(0.05)

    -- 꼭짓점들을 순서대로 연결
    local flatVertices = {}
    for i, v in ipairs(vertices) do
        table.insert(flatVertices, v[1])
        table.insert(flatVertices, v[2])
    end
    love.graphics.polygon("line", flatVertices)
end

--- 점과 선분 사이의 거리 계산
-- @param px (number) 점의 x 좌표
-- @param py (number) 점의 y 좌표
-- @param x1 (number) 선분 시작점 x
-- @param y1 (number) 선분 시작점 y
-- @param x2 (number) 선분 끝점 x
-- @param y2 (number) 선분 끝점 y
-- @return number 거리
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

--- 플레이어와 박스 충돌 감지 및 반사 벡터 계산
-- @param playerX (number) 플레이어 x 좌표
-- @param playerY (number) 플레이어 y 좌표
-- @param playerRadius (number) 플레이어 반지름
-- @return boolean, number, number, number, number 충돌 여부, 반사 벡터 x, 반사 벡터 y, 포탈 이동 x, 포탈 이동 y
function Box:checkCollision(playerX, playerY, playerRadius)
    local vertices = self:getVertices()
    local minDistance = math.huge
    local collisionNormal = { x = 0, y = 0 }
    local collidedEdge = nil

    -- 각 변에 대해 거리 계산
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
            -- 충돌 발생
            collidedEdge = i
            local normalX = playerX - nearestX
            local normalY = playerY - nearestY
            local normalLength = math.sqrt(normalX * normalX + normalY * normalY)

            if normalLength > 0 then
                normalX = normalX / normalLength
                normalY = normalY / normalLength
            end

            -- 포탈 모드이면 무작위 면으로 이동
            if self.isPortal then
                -- 짝수 개의 면을 가지므로, 정반대쪽 면의 인덱스는 (collidedEdge - 1 + n / 2) % n + 1
                local targetEdge = (collidedEdge - 1 + n / 2) % n + 1

                local targetV1 = vertices[targetEdge]
                local targetV2 = vertices[(targetEdge % n) + 1]
                local targetMidX = (targetV1[1] + targetV2[1]) / 2
                local targetMidY = (targetV1[2] + targetV2[2]) / 2

                -- 해당 면의 법선 계산 (내부 방향)
                local edgeDx = targetV2[1] - targetV1[1]
                local edgeDy = targetV2[2] - targetV1[2]
                local portalNormalX = -edgeDy
                local portalNormalY = edgeDx
                local portalNormalLength = math.sqrt(portalNormalX * portalNormalX + portalNormalY * portalNormalY)
                if portalNormalLength > 0 then
                    portalNormalX = portalNormalX / portalNormalLength
                    portalNormalY = portalNormalY / portalNormalLength
                end

                -- 면의 중심점에서 내부 방향으로 약간 떨어진 곳으로 이동 (무한 충돌 방지)
                local offsetDistance = 0.5
                local portalX = targetMidX + portalNormalX * offsetDistance
                local portalY = targetMidY + portalNormalY * offsetDistance

                return true, portalNormalX, portalNormalY, portalX, portalY
            end

            return true, normalX, normalY, 0, 0
        end
    end

    return false, 0, 0, 0, 0
end

return Box
