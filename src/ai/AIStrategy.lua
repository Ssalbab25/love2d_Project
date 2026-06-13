-- AIStrategy.lua: AI 대국 전략 인터페이스/부모 클래스
-- SOLID: OCP(개방-폐쇄 원칙)와 DIP(의존성 역전 원칙)를 준수하여, 고수준 매니저가 개별 AI 전략의 종류에 구애받지 않도록 설계되었습니다.

local Object = require "libs.classic"
local AIStrategy = Object:extend()

-- 하위 클래스에서 각자의 동작 알고리즘에 맞추어 아래 함수를 오버라이드하여 구현해야 합니다.
-- board: Board 객체
-- color: AI의 기물 색상 ("white" 또는 "black")
-- game: Game 객체 (필요 시 시간 정보, 추가 메타데이터 참조용)
-- 반환값: {from = {row, col}, to = {row, col}, promotion = type} 형식의 테이블
function AIStrategy:getBestMove(board, color, game)
    error("AIStrategy:getBestMove()는 추상 메소드입니다. 하위 클래스에서 오버라이드해야 합니다.")
end

return AIStrategy
