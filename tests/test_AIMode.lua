local test_AIMode = {}

-- LÖVE2D 환경이 없는 CLI 환경을 위한 스터빙
if not love or not love.graphics then
    love = love or {}
    love.graphics = {
        newFont = function()
            return {
                getHeight = function() return 16 end,
                getWidth = function() return 10 end
            }
        end,
        getDimensions = function()
            return 860, 600
        end
    }
end

local Game = require "src.Game"
local Board = require "src.Board"

function test_AIMode.run()
    print("  -> test_AIMode 시작...")
    
    local game = Game()
    
    -- 1. 초기 메뉴 화면 상태 확인
    assert(game.screenState == "menu", "게임 시작 시 초기 화면 상태는 'menu'여야 합니다.")
    assert(game.gameMode == nil, "초기 게임 모드는 nil이어야 합니다.")
    assert(game.aiDifficulty == nil, "초기 AI 난이도는 nil이어야 합니다.")
    
    -- 2. vs AI 메뉴 클릭 시뮬레이션
    local menuBtns = game.boardRenderer:getMenuButtons()
    local vsAiBtn = menuBtns.vs_ai
    
    -- vs AI 클릭
    game:handleMousePressed(vsAiBtn.x + 5, vsAiBtn.y + 5, 1)
    assert(game.screenState == "difficulty_select", "vs AI 버튼 클릭 시 difficulty_select 화면으로 이동해야 합니다.")
    
    -- 3. Back 클릭 시 다시 메뉴 화면으로 복귀
    local diffBtns = game.boardRenderer:getDifficultyButtons()
    local backBtn = diffBtns.back
    game:handleMousePressed(backBtn.x + 5, backBtn.y + 5, 1)
    assert(game.screenState == "menu", "Back 클릭 시 menu 화면으로 돌아와야 합니다.")
    
    -- 4. 다시 vs AI 클릭 후 Easy 난이도 선택 시뮬레이션
    game:handleMousePressed(vsAiBtn.x + 5, vsAiBtn.y + 5, 1)
    local easyBtn = diffBtns.easy
    game:handleMousePressed(easyBtn.x + 5, easyBtn.y + 5, 1)
    
    assert(game.screenState == "playing", "난이도 선택 시 playing 상태로 전환되어야 합니다.")
    assert(game.gameMode == "vs_ai", "게임 모드는 'vs_ai'여야 합니다.")
    assert(game.aiDifficulty == "easy", "AI 난이도는 'easy'여야 합니다.")
    
    -- 5. vs AI 모드에서 타이머 감소 검증
    assert(game.currentTurn == "white", "게임 시작 후 턴은 'white'여야 합니다.")
    local prevWhiteTime = game.whiteTime
    game:update(1.0)
    assert(game.whiteTime < prevWhiteTime, "vs AI 모드에서도 White 턴일 때 제한 시간이 감소해야 합니다.")
    
    -- 6. White 기물 이동을 통해 턴을 Black (AI)으로 전환
    -- d2(7, 4)의 백색 폰을 d4(5, 4)로 이동
    local selected = game:selectSquare(7, 4)
    assert(selected == true, "d2 폰 선택이 완료되어야 합니다.")
    local moved = game:selectSquare(5, 4)
    assert(moved == true, "d4로의 이동이 완료되어야 합니다.")
    
    assert(game.currentTurn == "black", "이동 완료 후 턴이 흑색('black')으로 변경되어야 합니다.")
    assert(game.blackTime == 600, "이동 완료 직후 흑색 타이머는 시작 시간(600)이어야 합니다.")
    
    -- 7. AI 턴 진행 검사 (1단계: 0.8초 후 기물 선택 및 강조)
    assert(game.aiTimer == 0.8, "AI 턴 시작 시 타이머 초기값은 0.8초여야 합니다.")
    assert(game.aiSelectedMove == nil, "선택된 AI 이동 기보가 없어야 합니다.")
    
    -- 0.7초가 흘렀을 때는 아직 선택 및 이동이 일어나지 않음
    local prevBlackTime = game.blackTime
    game:update(0.7)
    assert(math.abs(game.aiTimer - 0.1) < 0.001, "0.7초 흐른 후 aiTimer는 약 0.1초여야 합니다.")
    assert(game.aiSelectedMove == nil, "0.7초 흐른 시점에는 AI 이동이 선택되지 않아야 합니다.")
    assert(game.blackTime < prevBlackTime, "vs AI 모드에서도 Black 턴일 때 제한 시간이 감소해야 합니다.")
    
    -- 추가로 0.15초가 흐르면 aiTimer <= 0 이 되어 기물을 선택하고 하이라이트(0.4초) 설정함
    game:update(0.15)
    assert(game.aiSelectedMove ~= nil, "aiTimer 만료 후 무작위 이동이 선택되어야 합니다.")
    assert(game.selectedPiece ~= nil, "이동할 기물이 선택(하이라이트) 상태여야 합니다.")
    assert(game.selectedPiece.color == "black", "선택된 기물은 흑색이어야 합니다.")
    assert(math.abs(game.aiTimer - 0.4) < 0.001, "기물 선택 후 대기 타이머는 0.4초로 재설정되어야 합니다.")
    
    -- 8. AI 턴 진행 검사 (2단계: 0.4초 후 기물 이동 완료)
    -- 0.3초가 흘렀을 때는 아직 이동하지 않음
    game:update(0.3)
    assert(game.aiSelectedMove ~= nil, "0.3초 흐른 시점에는 아직 이동하지 않아야 합니다.")
    assert(game.currentTurn == "black", "아직 흑색의 턴이어야 합니다.")
    
    -- 추가로 0.15초가 흘러 aiTimer <= 0 이 되면 착수 완료 및 턴 교대
    game:update(0.15)
    assert(game.aiSelectedMove == nil, "이동 실행 후 aiSelectedMove는 nil로 리셋되어야 합니다.")
    assert(game.currentTurn == "white", "AI가 이동을 완료한 후 턴이 백색('white')으로 교대되어야 합니다.")
    assert(game.selectedPiece == nil, "착수 완료 후 선택 상태는 해제되어야 합니다.")
    assert(game.aiTimer == 0.8, "다음 AI 턴을 위한 준비로 aiTimer가 0.8초로 리셋되어야 합니다.")
    
    print("  -> test_AIMode 모든 검증 완료.")
end

return test_AIMode
