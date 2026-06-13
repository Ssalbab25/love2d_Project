local test_Perf = {}

local Game = require "src.Game"
local Board = require "src.Board"
local HardAI = require "src.ai.HardAI"

function test_Perf.run()
    print("  -> test_Perf 시작...")
    local game = Game()
    
    -- 1. 양측이 몇 수씩 대국을 진행한 미들게임 보드 구성 (5수 이상 진행 상황 재현)
    -- 백: e2e4 (7,5 -> 5,5), 흑: e7e5 (2,5 -> 4,5)
    game:selectSquare(7, 5)
    game:selectSquare(5, 5)
    
    -- AI 턴 진행 대기 시간 스킵을 위해 직접 강제 턴 제어
    game.currentTurn = "black"
    local move = game.aiStrategies.hard:getBestMove(game.board, "black", game)
    if move then
        game:selectSquare(move.from.row, move.from.col)
        game:selectSquare(move.to.row, move.to.col)
    end
    
    -- 백: g1f3 (8,7 -> 6,6), 흑: b8c6 (1,2 -> 3,3)
    game.currentTurn = "white"
    game:selectSquare(8, 7)
    game:selectSquare(6, 6)
    
    game.currentTurn = "black"
    local move2 = game.aiStrategies.hard:getBestMove(game.board, "black", game)
    if move2 then
        game:selectSquare(move2.from.row, move2.from.col)
        game:selectSquare(move2.to.row, move2.to.col)
    end
    
    -- 백: f1c4 (8,6 -> 5,3)
    game.currentTurn = "white"
    game:selectSquare(8, 6)
    game:selectSquare(5, 3)
    
    -- 이제 흑(AI) 차례에서 Hard AI의 검색 성능 측정
    game.currentTurn = "black"
    local hardAI = game.aiStrategies.hard
    
    print("  -> Hard AI 성능 측정 시작...")
    local startTime = os.clock()
    local bestMove = hardAI:getBestMove(game.board, "black", game)
    local endTime = os.clock()
    
    print(string.format("  -> Hard AI 검색 시간: %.4f 초", endTime - startTime))
    if bestMove then
        print(string.format("  -> 추천 이동: (%d,%d) -> (%d,%d)", 
            bestMove.from.row, bestMove.from.col, bestMove.to.row, bestMove.to.col))
    else
        print("  -> 추천 이동 없음")
    end
    
    print("  -> test_Perf 완료.")
end

return test_Perf
