-- love2d 진입점

local Object = require "libs.classic"

function love.load()
    print("Love2D 체스 프로젝트가 성공적으로 실행되었습니다!")
    print("classic 라이브러리 로드 상태: ", type(Object))
end

function love.update(dt)
end

function love.draw()
    love.graphics.print("Chess Project Initialized!", 300, 300)
end
