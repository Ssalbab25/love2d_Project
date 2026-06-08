-- Piece.lua: 모든 체스 기물의 부모 추상 클래스
-- SOLID: SRP를 준수하여 개별 기물의 공통 속성과 추상 인터페이스만 정의합니다.
--        LSP를 준수하기 위해 모든 서브클래스에서 getValidMoves()가 { {row, col}, ... } 형태의 배열을 반환하도록 강제하는 설계를 담고 있습니다.

local Object = require "libs.classic"
local Piece = Object:extend()

function Piece:new(color, type)
    assert(color == "white" or color == "black", "기물의 색상은 'white' 또는 'black'이어야 합니다.")
    self.color = color
    self.type = type or "generic"
    self.hasMoved = false
end

-- 추상 메서드: 서브클래스에서 이 메서드를 오버라이드하여 각 기물의 행마법을 구현해야 합니다.
-- board: Board 객체
-- currentPos: {row = r, col = c} 형태의 테이블
-- 반환값: { {row, col}, {row, col} ... } 형태의 2차원 배열 테이블 (LSP 준수)
function Piece:getValidMoves(board, currentPos)
    error("getValidMoves()는 Piece의 서브클래스에서 오버라이드되어야 합니다.")
end

return Piece
