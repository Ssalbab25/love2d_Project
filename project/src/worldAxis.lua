--[[
1. 0, 0 위치에서 +x, +y축의 방향이 표시되게 해줘.
2. x축은 red, y축은 green으로 해줘.
3. 인자로 카메라를 받을 수 있도록 해줘.
4. 카메라의 줌에 따라 축의 두께가 설정되게 해줘.
5. 필드에 격자로 흰 선이 나타나게 해줘.
6. 현재 카메라의 좌표를 표시해주는 함수를 작성해줘.
]]

local WorldAxis = {}

--- 월드 축 및 흰색 격자선 그리기 함수
-- @param camera (table|nil) 카메라 객체 (scale, orthoSize, getScale, x, y 등 지원 가능)
function WorldAxis.draw(camera)
    -- 4. 카메라의 줌에 따라 축 및 격자의 두께를 계산하기 위한 배율(scale) 산출
    local scale = 1.0
    if camera then
        if type(camera.getScale) == "function" then
            scale = camera:getScale()
        elseif type(camera.scale) == "number" then
            scale = camera.scale
        elseif type(camera.getOrthoSize) == "function" then
            local _, screenHeight = love.graphics.getDimensions()
            scale = screenHeight / (2 * camera:getOrthoSize())
        elseif type(camera.orthoSize) == "number" then
            local _, screenHeight = love.graphics.getDimensions()
            scale = screenHeight / (2 * camera.orthoSize)
        end
    end

    -- 배율이 비정상적일 때를 대비한 안전 장치
    if scale <= 0 then scale = 1.0 end

    -- ==========================================
    -- 5. 필드에 격자로 흰 선 그리기
    -- 화면 기준 1픽셀 두께의 격자선을 월드 좌표계에 맞게 렌더링
    -- ==========================================
    love.graphics.setColor(1, 1, 1, 0.15) -- 흰색, 투명도 15%
    love.graphics.setLineWidth(1 / scale)

    -- 월드 범위 -25부터 25까지 1단위 격자선 그리기
    for i = -25, 25 do
        -- 세로선 (x = i)
        love.graphics.line(i, -25, i, 25)
        -- 가로선 (y = i)
        love.graphics.line(-25, i, 25, i)
    end

    -- ==========================================
    -- 1~4. X, Y 축 그리기
    -- 화면 기준 3픽셀 두께로 축선이 보이게 설정
    -- ==========================================
    local thickness = 3 / scale
    love.graphics.setLineWidth(thickness)

    -- 화살표 머리 크기 계산 (화면 기준 길이 14px, 너비 8px 유지)
    local arrowLength = 14 / scale
    local arrowHalfWidth = 4 / scale
    local axisLength = 10 -- 축의 길이

    -- 2. x축은 red로 그리기
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.line(0, 0, axisLength, 0)
    -- +X 방향 화살표 머리
    love.graphics.polygon("fill",
        axisLength, 0,
        axisLength - arrowLength, arrowHalfWidth,
        axisLength - arrowLength, -arrowHalfWidth
    )

    -- 2. y축은 green으로 그리기
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.line(0, 0, 0, axisLength)
    -- +Y 방향 화살표 머리 (유니티 Y-Up 기준)
    love.graphics.polygon("fill",
        0, axisLength,
        -arrowHalfWidth, axisLength - arrowLength,
        arrowHalfWidth, axisLength - arrowLength
    )

    -- 축 라벨 그리기 (+X, +Y)
    -- 카메라 객체에 worldToScreen 기능이 있다면 글자가 뒤집히지 않게 스크린 좌표로 출력
    if camera and type(camera.worldToScreen) == "function" then
        love.graphics.push("all")

        local xLabelSX, xLabelSY = camera:worldToScreen(axisLength + 0.4, 0)
        love.graphics.origin()
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("+X", xLabelSX, xLabelSY - 7)

        love.graphics.pop()

        love.graphics.push("all")

        local yLabelSX, yLabelSY = camera:worldToScreen(0, axisLength + 0.4)
        love.graphics.origin()
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.print("+Y", yLabelSX - 8, yLabelSY - 7)

        love.graphics.pop()
    end
end

--- 6. 현재 카메라와 플레이어의 좌표를 화면에 표시해주는 함수
-- @param camera (table|nil) 카메라 객체
-- @param player (table|nil) 플레이어 객체
-- @param sx (number|nil) 화면 상의 X 출력 좌표 (기본값: 20)
-- @param sy (number|nil) 화면 상의 Y 출력 좌표 (기본값: 20)
function WorldAxis.drawCameraCoords(camera, player, sx, sy)
    sx = sx or 20
    sy = sy or 20

    -- 카메라 좌표값 취득
    local cx = camera and camera.x or 0
    local cy = camera and camera.y or 0

    -- 플레이어 좌표값 취득
    local px = player and player.x or 0
    local py = player and player.y or 0

    love.graphics.push("all")
    love.graphics.origin() -- 스크린 공간 좌표계 보장

    -- 글씨가 잘 보이도록 반투명한 어두운 바탕 사각형 패널을 그려줌
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", sx - 10, sy - 8, 250, 88, 6, 6)

    -- 카메라 좌표 정보 텍스트 렌더링
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Camera Coordinates", sx, sy)
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.print(string.format("X: %.2f, Y: %.2f", cx, cy), sx, sy + 18)

    -- 플레이어 좌표 정보 텍스트 렌더링
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Player Coordinates", sx, sy + 38)
    love.graphics.setColor(1, 0.8, 0.2, 1)
    love.graphics.print(string.format("X: %.2f, Y: %.2f", px, py), sx, sy + 56)

    love.graphics.pop()
end

return WorldAxis
