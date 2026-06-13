local test_Analysis = {}

local Board = require "src.Board"
local OpeningBookMatcher = require "src.analysis.OpeningBookMatcher"
local EvaluationEngine = require "src.analysis.EvaluationEngine"
local AnalysisFacade = require "src.analysis.AnalysisFacade"

function test_Analysis.run()
    print("  -> test_Analysis 시작...")

    -- 1. FEN 생성 테스트
    local board = Board()
    board:setupPieces()

    local fen = OpeningBookMatcher.generateFEN(board, "white", 0, 1)
    local expectedFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    assert(fen == expectedFen, "기본 배치 FEN이 일치하지 않습니다.\n기대값: " .. expectedFen .. "\n실제값: " .. fen)

    -- 2. 오프닝 북 매치 테스트
    local bookMatcher = OpeningBookMatcher()
    local bestBookMove = bookMatcher:getBestMove(board, "white", 0, 1)
    -- 오프닝 데이터베이스에 e2e4가 매칭되는지 확인
    assert(bestBookMove ~= nil, "오프닝 북 매칭이 실패했습니다.")
    assert(bestBookMove.from.row == 7 and bestBookMove.from.col == 5, "첫 수 시작 위치가 e2(7, 5)가 아닙니다.")
    assert(bestBookMove.to.row == 5 and bestBookMove.to.col == 5, "첫 수 도착 위치가 e4(5, 5)가 아닙니다.")

    -- 3. 정적 평가 엔진 테스트
    local evaluator = EvaluationEngine()
    local score = evaluator:evaluate(board)
    -- 대칭적인 초기 보드 점수는 0이어야 함
    assert(score == 0, "초기 상태의 대칭적인 점수가 0이 아닙니다: " .. tostring(score))

    -- 4. 분석 파사드 테스트
    local facade = AnalysisFacade()
    local result = facade:analyze(board, "white", 0, 1)
    
    assert(result.score ~= nil, "분석 점수가 포함되어야 합니다.")
    assert(result.bestMove ~= nil, "추천 수가 포함되어야 합니다.")
    assert(result.isBook == true, "초기 상태는 오프닝 북이어야 합니다.")

    print("  -> test_Analysis 모든 검증 완료.")
end

return test_Analysis
