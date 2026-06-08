-- Game.lua: 게임 상태 및 매니저 조율 클래스
-- SOLID: SRP를 준수하여 보드 데이터와 렌더러의 인스턴스를 관리하고 게임 루프를 중재합니다.

local Object = require "libs.classic"
local Board = require "src.Board"
local BoardRenderer = require "src.BoardRenderer"

local Game = Object:extend()

function Game:new()
    self.board = Board()
    self.boardRenderer = BoardRenderer()
end

function Game:update(dt)
    -- 현재 단계에서는 애니메이션 등 필요 시 확장 가능
end

function Game:draw()
    -- 보드 렌더러에 보드 인스턴스를 전달하여 드로잉
    self.boardRenderer:draw(self.board)
end

return Game
