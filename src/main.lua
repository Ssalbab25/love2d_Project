-- main.lua: LÖVE2D 애플리케이션 진입점

-- 콘솔 출력 즉시 플러시 설정 (버퍼링 방지)
io.stdout:setvbuf("no")

-- 1. 단위 테스트 자동 실행 (TDD 규칙 준수)
local testRunner = require "tests.runner"
testRunner.run()

-- 2. 핵심 게임 인스턴스화
local Game = require "src.Game"
local game

function love.load()
    print("모든 유닛 테스트 완료! 게임 루프를 시작합니다.")
    
    -- 창 크기 설정 (860x600, 크기 조절 가능)
    love.window.setMode(860, 600, {resizable = true})
    
    -- 배경색 설정 (체스판과 라벨이 조화롭게 돋보이는 부드러운 밝은 실버 그레이 테마)
    love.graphics.setBackgroundColor(0.88, 0.88, 0.86)
    
    game = Game()
end

function love.update(dt)
    if game then
        game:update(dt)
    end
end

function love.draw()
    if game then
        game:draw()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if game then
        game:handleMousePressed(x, y, button)
    end
end
