local test_GameControl = {}

-- LÖVE2D 그래픽 API 환경이 없는 CLI 테스트 환경을 대비한 스터빙(Stubbing)
if not love or not love.graphics then
    love = love or {}
    love.graphics = {
        newFont = function()
            return {
                getHeight = function() return 16 end,
                getWidth = function() return 10 end
            }
        end
    }
end

local Game = require "src.Game"
local Board = require "src.Board"
local Pawn = require "src.pieces.Pawn"

function test_GameControl.run()
    print("  -> test_GameControl 시작...")
    
    local game = Game()
    
    -- 1. 초기 턴 상태 검증 (White 선공)
    assert(game.currentTurn == "white", "초기 턴은 백색('white')이어야 합니다.")
    assert(game.selectedPiece == nil, "초기에는 선택된 기물이 없어야 합니다.")
    assert(#game.validMoves == 0, "초기에는 유효 이동 목록이 비어 있어야 합니다.")
    
    -- 2. 아군 기물 선택 검증 (7행 4열의 백색 폰)
    -- 가상의 클릭 이벤트를 Game 객체의 로직을 통해 처리
    -- d2(7, 4)에는 백색 폰이 표준 배치되어 있음
    local status = game:selectSquare(7, 4)
    assert(status == true, "아군 기물이 있는 (7, 4)는 선택되어야 합니다.")
    assert(game.selectedPiece ~= nil, "선택된 기물이 존재해야 합니다.")
    assert(game.selectedPiece.type == "pawn", "선택된 기물은 pawn이어야 합니다.")
    assert(game.selectedPiece.color == "white", "선택된 기물은 white여야 합니다.")
    assert(game.selectedPos.row == 7 and game.selectedPos.col == 4, "선택 좌표가 (7, 4)여야 합니다.")
    assert(#game.validMoves > 0, "선택된 폰의 유효한 이동 경로가 계산되어 있어야 합니다.")
    
    -- 3. 상대 턴 기물 선택 시도 차단 검증 (1행 5열의 흑색 킹)
    -- 이미 백색 기물이 선택되어 있는 상태에서 흑색 기물을 클릭하면 
    -- 이동(포획) 경로가 아니기 때문에 선택이 해제되거나 무시되어야 함
    local prevPiece = game.selectedPiece
    game:selectSquare(1, 5) -- 흑색 킹 클릭
    assert(game.selectedPiece == nil, "상대방 턴의 기물을 잘못 클릭하면 선택이 해제되거나 무시되어야 합니다.")
    
    -- 4. 기물의 정상적인 이동 및 턴 전환 검증
    -- 다시 d2(7, 4) 백색 폰 선택
    game:selectSquare(7, 4)
    assert(game.selectedPiece == prevPiece, "폰이 다시 정상 선택되어야 합니다.")
    
    -- 폰의 유효 경로 중 하나인 d4(5, 4)로 이동 시도
    -- 이동을 하기 위해 selectSquare(5, 4) 호출
    local moveStatus = game:selectSquare(5, 4)
    assert(moveStatus == true, "유효한 목적지 (5, 4)로의 이동은 성공해야 합니다.")
    
    -- 보드 상태 확인
    local oldSquare = game.board:getPiece(7, 4)
    local newSquare = game.board:getPiece(5, 4)
    assert(oldSquare == nil, "이동이 완료된 원래 칸(7, 4)은 비어 있어야(nil) 합니다.")
    assert(newSquare ~= nil, "이동된 목적지(5, 4)에 기물이 배치되어야 합니다.")
    assert(newSquare.type == "pawn" and newSquare.color == "white", "목적지 기물은 백색 폰이어야 합니다.")
    assert(newSquare.hasMoved == true, "이동한 기물의 hasMoved 플래그는 true로 설정되어야 합니다.")
    
    -- 게임 상태 리셋 및 턴 전환 확인
    assert(game.selectedPiece == nil, "이동 완료 후 선택 상태는 해제되어야 합니다.")
    assert(game.currentTurn == "black", "이동 완료 후 턴이 흑색('black')으로 전환되어야 합니다.")
    
    -- 5. 상대방 턴 상태에서 백색 기물 선택 차단 검증
    -- 현재 흑색 턴이므로 백색 폰(5, 4)을 클릭해도 선택되지 않아야 함
    local blackTurnSelect = game:selectSquare(5, 4)
    assert(blackTurnSelect == false, "흑색 턴일 때 백색 기물을 선택하려는 시도는 차단되어야 합니다.")
    assert(game.selectedPiece == nil, "차단된 선택 시도로 인해 선택된 기물은 없어야 합니다.")
    
    print("  -> test_GameControl 모든 검증 완료.")
end

return test_GameControl
