local test_DrawConditions = {}

local Game = require "src.Game"
local Board = require "src.Board"
local King = require "src.pieces.King"
local Queen = require "src.pieces.Queen"
local Bishop = require "src.pieces.Bishop"
local Knight = require "src.pieces.Knight"

function test_DrawConditions.run()
    print("  -> test_DrawConditions 시작...")

    -- 1. 스테일메이트(Stalemate) 검증
    do
        local game = Game()
        game.board = Board()
        
        -- 백색 킹을 구석에 배치
        local whiteKing = King("white")
        game.board:setPiece(8, 8, whiteKing)
        
        -- 흑색 킹 배치 (합법적인 일반 배치)
        local blackKing = King("black")
        game.board:setPiece(1, 1, blackKing)
        
        -- 흑색 퀸을 (7, 6)에 배치하여 백색 킹의 퇴로를 완전히 차단하지만 체크는 아님
        -- 킹은 8,8에 있음. 퀸이 7,6에 있으면:
        -- 8,7(퀸 공격범위), 7,7(퀸 공격범위), 7,8(퀸 공격범위)
        -- 8,8 자체는 퀸이 공격하지 못하므로 체크가 아님.
        local blackQueen = Queen("black")
        game.board:setPiece(7, 6, blackQueen)
        
        game.currentTurn = "white"
        game:checkGameEndStatus()
        
        assert(game.isGameOver == true, "스테일메이트 시 게임 오버 상태가 활성화되어야 합니다.")
        assert(game.winner == "draw", "스테일메이트 시 무승부 처리되어야 합니다.")
        assert(game.gameOverReason == "stalemate", "종료 원인이 'stalemate'여야 합니다.")
    end

    -- 2. 기물 부족(Insufficient Material) 검증
    -- Case A: King vs King
    do
        local game = Game()
        game.board = Board()
        
        game.board:setPiece(8, 8, King("white"))
        game.board:setPiece(1, 1, King("black"))
        
        assert(game.board:hasInsufficientMaterial() == true, "King vs King은 기물 부족 무승부로 인정되어야 합니다.")
        
        game.currentTurn = "white"
        game:checkGameEndStatus()
        assert(game.isGameOver == true and game.winner == "draw" and game.gameOverReason == "insufficient_material", "King vs King 시 게임 종료 처리가 올바르게 수행되어야 합니다.")
    end

    -- Case B: King + Bishop vs King
    do
        local game = Game()
        game.board = Board()
        
        game.board:setPiece(8, 8, King("white"))
        game.board:setPiece(8, 7, Bishop("white"))
        game.board:setPiece(1, 1, King("black"))
        
        assert(game.board:hasInsufficientMaterial() == true, "King + Bishop vs King은 기물 부족 무승부로 인정되어야 합니다.")
    end

    -- Case C: King + Knight vs King
    do
        local game = Game()
        game.board = Board()
        
        game.board:setPiece(8, 8, King("white"))
        game.board:setPiece(8, 7, Knight("white"))
        game.board:setPiece(1, 1, King("black"))
        
        assert(game.board:hasInsufficientMaterial() == true, "King + Knight vs King은 기물 부족 무승부로 인정되어야 합니다.")
    end

    -- Case D: King + Bishop vs King + Bishop
    -- D-1: 동색 비숍 매치 (무승부)
    do
        local game = Game()
        game.board = Board()
        
        game.board:setPiece(8, 8, King("white"))
        -- 백색 비숍을 (7, 7)에 배치: (7 + 7) % 2 = 0
        game.board:setPiece(7, 7, Bishop("white"))
        
        game.board:setPiece(1, 1, King("black"))
        -- 흑색 비숍을 (2, 2)에 배치: (2 + 2) % 2 = 0 (같은 색상의 타일)
        game.board:setPiece(2, 2, Bishop("black"))
        
        assert(game.board:hasInsufficientMaterial() == true, "동색 타일의 비숍 매치는 기물 부족 무승부로 인정되어야 합니다.")
    end

    -- D-2: 이색 비숍 매치 (무승부 아님 - 이론상 체크메이트 가능)
    do
        local game = Game()
        game.board = Board()
        
        game.board:setPiece(8, 8, King("white"))
        -- 백색 비숍을 (7, 7)에 배치: (7 + 7) % 2 = 0
        game.board:setPiece(7, 7, Bishop("white"))
        
        game.board:setPiece(1, 1, King("black"))
        -- 흑색 비숍을 (2, 3)에 배치: (2 + 3) % 2 = 1 (다른 색상의 타일)
        game.board:setPiece(2, 3, Bishop("black"))
        
        assert(game.board:hasInsufficientMaterial() == false, "다른 색상 타일의 비숍 매치는 기물 부족 무승부가 아닙니다.")
    end

    -- 3. 기권(Resignation) 검증
    do
        local game = Game()
        game.screenState = "playing"
        local resignBtn = game.boardRenderer:getResignButtonRect()
        
        -- 기권 버튼 좌표 클릭 시뮬레이션
        game:handleMousePressed(resignBtn.x + 5, resignBtn.y + 5, 1)
        
        assert(game.isGameOver == true, "기권 클릭 시 게임이 종료되어야 합니다.")
        assert(game.winner == "black", "White의 기권 시 Black이 승리해야 합니다.")
        assert(game.gameOverReason == "resign", "게임 종료 사유는 'resign'이어야 합니다.")
    end

    -- 4. 무승부 제안(Draw Offer) 수락/거절 검증
    do
        local game = Game()
        game.screenState = "playing"
        local drawBtn = game.boardRenderer:getDrawOfferButtonRect()
        
        -- 무승부 제안 버튼 클릭 시뮬레이션
        game:handleMousePressed(drawBtn.x + 5, drawBtn.y + 5, 1)
        assert(game.pendingDrawOffer == true, "무승부 제안 시 pendingDrawOffer가 활성화되어야 합니다.")
        
        -- 모달이 켜진 상태에서 타이머 일시정지 검증
        local initialWhiteTime = game.whiteTime
        game:update(0.5)
        assert(game.whiteTime == initialWhiteTime, "무승부 제안 중에는 타이머가 일시정지되어야 합니다.")
        
        -- 거절(Decline) 클릭 시뮬레이션
        local buttons = game.boardRenderer:getDrawOfferModalButtons()
        game:handleMousePressed(buttons.decline.x + 5, buttons.decline.y + 5, 1)
        assert(game.pendingDrawOffer == nil, "거절 시 무승부 제안 상태가 해제되어야 합니다.")
        assert(game.isGameOver == false, "거절 시 게임은 계속 진행되어야 합니다.")
        
        -- 다시 제안 후 수락(Accept) 클릭 시뮬레이션
        game:handleMousePressed(drawBtn.x + 5, drawBtn.y + 5, 1)
        game:handleMousePressed(buttons.accept.x + 5, buttons.accept.y + 5, 1)
        assert(game.isGameOver == true, "수락 시 게임이 종료되어야 합니다.")
        assert(game.winner == "draw", "무승부 합의 시 무승부로 처리되어야 합니다.")
        assert(game.gameOverReason == "draw_offer", "게임 종료 사유는 'draw_offer'여야 합니다.")
    end

    print("  -> test_DrawConditions 모든 검증 완료.")
end

return test_DrawConditions
