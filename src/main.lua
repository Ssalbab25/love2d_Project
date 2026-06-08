-- main.lua: LÖVE2D 애플리케이션 진입점

-- 1. 단위 테스트 자동 실행 (TDD 규칙 준수)
local testRunner = require "tests.runner"
testRunner.run()

-- 2. 핵심 게임 인스턴스화
local Game = require "src.Game"
local game

function love.load()
    print("모든 유닛 테스트 완료! 게임 루프를 시작합니다.")
    
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
