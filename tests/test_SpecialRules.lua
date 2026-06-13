local test_SpecialRules = {}

local Game = require "src.Game"
local Board = require "src.Board"
local King = require "src.pieces.King"
local Rook = require "src.pieces.Rook"
local Queen = require "src.pieces.Queen"
local Bishop = require "src.pieces.Bishop"
local Pawn = require "src.pieces.Pawn"

local function hasMove(moves, r, c)
    for _, m in ipairs(moves) do
        if m.row == r and m.col == c then
            return true
        end
    end
    return false
end

function test_SpecialRules.run()
    print("  -> test_SpecialRules 시작...")

    -- 1. 프로모션(Promotion) 검증
    do
        local game = Game()
        game.board = Board() -- 보드 비우기
        
        local whitePawn = Pawn("white")
        game.board:setPiece(2, 4, whitePawn) -- 7행이 아닌 2행에 백색 폰 배치
        
        game:selectSquare(2, 4)
        local status = game:selectSquare(1, 4) -- 1행으로 한 칸 전진 시도
        
        assert(status == true, "폰 전진은 성공해야 합니다.")
        assert(game.pendingPromotion ~= nil, "프로모션 대기 상태가 설정되어야 합니다.")
        assert(game.pendingPromotion.row == 1 and game.pendingPromotion.col == 4, "프로모션 발생 좌표가 올바르지 않습니다.")
        assert(game.currentTurn == "white", "프로모션 대기 중에는 아직 턴이 넘어가선 안 됩니다.")
        
        -- 프로모션 완료
        game:promotePawn("queen")
        
        local promotedPiece = game.board:getPiece(1, 4)
        assert(promotedPiece ~= nil and promotedPiece.type == "queen" and promotedPiece.color == "white", "퀸으로 정상 승급되어야 합니다.")
        assert(game.pendingPromotion == nil, "프로모션 대기 상태가 초기화되어야 합니다.")
        assert(game.currentTurn == "black", "프로모션 완료 후 턴이 흑색으로 넘어가야 합니다.")
    end

    -- 2. 캐슬링(Castling) 검증
    do
        -- (1) 킹사이드 및 퀸사이드 캐슬링 행마법 연산 검증
        local game = Game()
        game.board = Board()
        
        local whiteKing = King("white")
        local whiteRookK = Rook("white")
        local whiteRookQ = Rook("white")
        
        game.board:setPiece(8, 5, whiteKing)
        game.board:setPiece(8, 8, whiteRookK) -- 킹사이드 룩
        game.board:setPiece(8, 1, whiteRookQ) -- 퀸사이드 룩
        
        local kingMoves = game:getLegalMoves(whiteKing, {row = 8, col = 5})
        assert(hasMove(kingMoves, 8, 7), "킹사이드 캐슬링 목적지 (8, 7)이 존재해야 합니다.")
        assert(hasMove(kingMoves, 8, 3), "퀸사이드 캐슬링 목적지 (8, 3)이 존재해야 합니다.")
        
        -- 킹사이드 캐슬링 실행
        game:selectSquare(8, 5)
        game:selectSquare(8, 7)
        
        assert(game.board:getPiece(8, 7) == whiteKing, "캐슬링 후 킹은 (8, 7)로 이동해야 합니다.")
        assert(game.board:getPiece(8, 6) == whiteRookK, "캐슬링 후 룩은 (8, 6)으로 이동해야 합니다.")
        assert(whiteKing.hasMoved == true and whiteRookK.hasMoved == true, "이동 완료 플래그가 활성화되어야 합니다.")
    end

    -- (2) 체크 상태 시 캐슬링 불가 검증
    do
        local game = Game()
        game.board = Board()
        
        local whiteKing = King("white")
        local whiteRook = Rook("white")
        local blackRook = Rook("black")
        
        game.board:setPiece(8, 5, whiteKing)
        game.board:setPiece(8, 8, whiteRook)
        game.board:setPiece(1, 5, blackRook) -- 동일 열에 적 룩 배치 (직접 체크)
        
        local kingMoves = game:getLegalMoves(whiteKing, {row = 8, col = 5})
        assert(not hasMove(kingMoves, 8, 7), "체크 상태일 때는 캐슬링을 할 수 없어야 합니다.")
    end

    -- (3) 통과하는 칸이 공격받는 경우 캐슬링 불가 검증
    do
        local game = Game()
        game.board = Board()
        
        local whiteKing = King("white")
        local whiteRook = Rook("white")
        local blackRook = Rook("black")
        
        game.board:setPiece(8, 5, whiteKing)
        game.board:setPiece(8, 8, whiteRook)
        game.board:setPiece(1, 6, blackRook) -- 6열 공격 (킹이 통과하는 8행 6열 위협)
        
        local kingMoves = game:getLegalMoves(whiteKing, {row = 8, col = 5})
        assert(not hasMove(kingMoves, 8, 7), "킹이 통과하는 칸이 공격받고 있으면 캐슬링을 할 수 없어야 합니다.")
    end

    -- 3. 앙파상(En Passant) 검증
    do
        local game = Game()
        game.board = Board()
        
        local whitePawn = Pawn("white")
        local blackPawn = Pawn("black")
        
        game.board:setPiece(4, 4, whitePawn)  -- 백색 폰 (4, 4) 배치
        game.board:setPiece(2, 5, blackPawn)  -- 흑색 폰 (2, 5) 배치
        
        -- 흑색 폰의 2칸 전진 전에는 앙파상 타겟이 없어야 함
        assert(game.board.enPassantTarget == nil, "초기에는 앙파상 타겟이 없어야 합니다.")
        
        -- 흑색 턴으로 변경 후 흑색 폰 2칸 전진
        game.currentTurn = "black"
        game:selectSquare(2, 5)
        game:selectSquare(4, 5) -- (2, 5) -> (4, 5) 이동
        
        -- 앙파상 타겟 좌표 생성 확인
        assert(game.board.enPassantTarget ~= nil, "2칸 전진 시 앙파상 타겟이 활성화되어야 합니다.")
        assert(game.board.enPassantTarget.row == 3 and game.board.enPassantTarget.col == 5, "앙파상 목적 좌표가 (3, 5)여야 합니다.")
        
        -- 백색 턴 전환 후 백색 폰의 앙파상 이동 확인
        game.currentTurn = "white"
        game:selectSquare(4, 4)
        assert(hasMove(game.validMoves, 3, 5), "백색 폰의 유효 행마에 앙파상 캡처 칸 (3, 5)가 추가되어야 합니다.")
        
        -- 앙파상 실행
        game:selectSquare(3, 5)
        
        assert(game.board:getPiece(3, 5) == whitePawn, "앙파상 이동 완료 후 백색 폰이 (3, 5)에 있어야 합니다.")
        assert(game.board:getPiece(4, 5) == nil, "앙파상 포획 대상이었던 흑색 폰은 보드에서 제거되어야 합니다.")
        assert(game.board.enPassantTarget == nil, "앙파상 실행 후 타겟 정보는 소멸해야 합니다.")
    end

    print("  -> test_SpecialRules 모든 검증 완료.")
end

return test_SpecialRules
