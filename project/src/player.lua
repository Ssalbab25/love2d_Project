local Player = {}
Player.__index = Player

--- Player 생성자
-- @param x (number|nil) 초기 월드 x 좌표 (기본값: 0)
-- @param y (number|nil) 초기 월드 y 좌표 (기본값: 0)
function Player:new(x, y)
    local obj = {
        x = x or 0,
        y = y or 0,
        vx = 0,                -- x 방향 속도
        vy = 0,                -- y 방향 속도
        radius = 0.4,          -- 플레이어 반지름 (0.4배)
        isMoving = false,      -- 이동 중인지 여부
        speedMultiplier = 1.3, -- 속도 배율 (1.3배)
        showTrail = true,      -- 잔상 표시 여부 (기본 켜짐)
        trail = {},            -- 잔상 좌표들
        trailTimer = 0,        -- 잔상 타이머
        health = 3,            -- 플레이어 체력
        targetX = nil,         -- 마우스 추적 목표 x 좌표
        targetY = nil,         -- 마우스 추적 목표 y 좌표
        moveSpeed = 10,        -- 이동 속도
        isDashing = false,     -- 대시 중인지 여부
        dashSpeed = 30,        -- 대시 속도
        dashDuration = 0.2,    -- 대시 지속 시간
        dashTimer = 0          -- 대시 타이머
    }
    setmetatable(obj, self)
    return obj
end

--- 플레이어 위치 설정
-- @param x (number)
-- @param y (number)
function Player:setPosition(x, y)
    self.x = x or 0
    self.y = y or 0
end

--- 플레이어를 해당 지점으로 이동
-- @param x (number)
-- @param y (number)
function Player:moveTo(x, y)
    self.x = x or 0
    self.y = y or 0
    self.vx = 0
    self.vy = 0
    self.isMoving = false
    self.targetX = nil
    self.targetY = nil
end

--- 마우스 추적 목표 설정
-- @param x (number)
-- @param y (number)
function Player:setTarget(x, y)
    self.targetX = x
    self.targetY = y
    self.isMoving = true
end

--- 마우스 추적 목표 해제
function Player:clearTarget()
    self.targetX = nil
    self.targetY = nil
    self.isMoving = false
end

--- 대시 시작
-- @param targetX (number)
-- @param targetY (number)
function Player:startDash(targetX, targetY)
    self.isDashing = true
    self.dashTimer = self.dashDuration
    self.dashTargetX = targetX
    self.dashTargetY = targetY
end

--- 플레이어 속도 설정
-- @param vx (number) x 방향 속도
-- @param vy (number) y 방향 속도
function Player:setVelocity(vx, vy)
    self.vx = vx or 0
    self.vy = vy or 0
end

--- 플레이어 이동 시작
-- @param vx (number) x 방향 속도
-- @param vy (number) y 방향 속도
function Player:startMoving(vx, vy)
    self.vx = vx or 0
    self.vy = vy or 0
    self.isMoving = true
end

--- 플레이어 정지
function Player:stop()
    self.vx = 0
    self.vy = 0
    self.isMoving = false
end

--- 속도 배율 증가
function Player:increaseSpeed()
    self.speedMultiplier = self.speedMultiplier + 0.2
end

--- 속도 배율 감소
function Player:decreaseSpeed()
    self.speedMultiplier = math.max(0.2, self.speedMultiplier - 0.2)
end

--- 잔상 토글
function Player:toggleTrail()
    self.showTrail = not self.showTrail
    if not self.showTrail then
        self.trail = {}
    end
end

--- 공 크기 증가
function Player:increaseRadius()
    self.radius = self.radius + 0.1
end

--- 공 크기 감소
function Player:decreaseRadius()
    self.radius = math.max(0.2, self.radius - 0.1)
end

--- 속도 반사 (충돌 시)
-- @param normalX (number) 법선 x 성분
-- @param normalY (number) 법선 y 성분
function Player:reflect(normalX, normalY)
    -- 반사 공식: v' = v - 2(v·n)n
    local dotProduct = self.vx * normalX + self.vy * normalY
    self.vx = self.vx - 2 * dotProduct * normalX
    self.vy = self.vy - 2 * dotProduct * normalY
end

--- 플레이어 그리기
function Player:draw()
    -- 잔상 그리기 (폴리곤 트레일)
    if self.showTrail and #self.trail > 1 then
        for i = 1, #self.trail - 1 do
            local pos1 = self.trail[i]
            local pos2 = self.trail[i + 1]
            local alpha = (i / #self.trail) * 0.5
            local lineWidth = (i / #self.trail) * self.radius * 0.5

            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.setLineWidth(lineWidth)
            love.graphics.line(pos1.x, pos1.y, pos2.x, pos2.y)
        end

        -- 마지막 점에서 현재 위치까지 연결
        local lastPos = self.trail[#self.trail]
        local alpha = 0.5
        local lineWidth = self.radius * 0.5
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setLineWidth(lineWidth)
        love.graphics.line(lastPos.x, lastPos.y, self.x, self.y)
    end

    -- 플레이어 그리기
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

--- 플레이어 업데이트
-- @param dt (number) 델타 타임
function Player:update(dt)
    -- 대시 타이머 업데이트
    if self.isDashing then
        self.dashTimer = self.dashTimer - dt
        if self.dashTimer <= 0 then
            self.isDashing = false
        end
    end

    -- 현재 속도 결정 (대시 중이면 대시 속도, 아니면 일반 속도)
    local currentSpeed = self.isDashing and self.dashSpeed or self.moveSpeed
    currentSpeed = currentSpeed * self.speedMultiplier

    if self.targetX ~= nil and self.targetY ~= nil then
        -- 마우스 추적: 목표 좌표로 직접 이동 (관성 제거)
        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > 0.1 then
            -- 목표 방향으로 일정 속도로 이동
            local moveX = (dx / dist) * currentSpeed * dt
            local moveY = (dy / dist) * currentSpeed * dt

            self.x = self.x + moveX
            self.y = self.y + moveY
        else
            -- 목표에 도달하면 정지
            self.targetX = nil
            self.targetY = nil
            self.isMoving = false
        end
    elseif self.isMoving then
        -- 스페이스바로 시작한 기존 이동 (관성 유지)
        local actualVx = self.vx * self.speedMultiplier
        local actualVy = self.vy * self.speedMultiplier

        self.x = self.x + actualVx * dt
        self.y = self.y + actualVy * dt
    end

    -- 잔상 저장 (0.4초 동안)
    if self.showTrail then
        self.trailTimer = self.trailTimer + dt
        if self.trailTimer >= 0.02 then -- 0.02초마다 저장
            table.insert(self.trail, { x = self.x, y = self.y })
            self.trailTimer = 0
        end

        -- 0.4초 이전의 잔상 제거
        while #self.trail > 20 do -- 20개 프레임 (0.4초 / 0.02초)
            table.remove(self.trail, 1)
        end
    end
end

return Player
