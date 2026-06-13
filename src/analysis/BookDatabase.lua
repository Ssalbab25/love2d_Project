-- BookDatabase.lua: 체스 오프닝 기보 데이터베이스
-- 다양한 표준 오프닝의 FEN 상태와 이에 따르는 가중치 기반 기보 이동 목록 정의

local BookDatabase = {
    -- 0. 초기 시작 보드 상태
    ["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"] = {
        { move = "e2e4", weight = 450 }, -- 킹스 폰 오프닝
        { move = "d2d4", weight = 380 }, -- 퀸스 폰 오프닝
        { move = "g1f3", weight = 180 }, -- 레티 오프닝
        { move = "c2c4", weight = 150 }  -- 잉글리시 오프닝
    },

    -- 1. e4 이후 (킹스 폰 오프닝)
    ["rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"] = {
        { move = "e7e5", weight = 400 }, -- 오픈 게임
        { move = "c7c5", weight = 380 }, -- 시실리안 디펜스
        { move = "e7e6", weight = 200 }, -- 프렌치 디펜스
        { move = "c7c6", weight = 180 }  -- 카로칸 디펜스
    },

    -- 1. d4 이후 (퀸스 폰 오프닝)
    ["rnbqkbnr/pppppppp/8/8/3P4/8/PPPP1PPP/RNBQKBNR b KQkq d3 0 1"] = {
        { move = "d7d5", weight = 400 }, -- 클로즈드 게임
        { move = "g8f6", weight = 380 }  -- 인디언 디펜스
    },

    -- 1. e4 e5 (오픈 게임) 이후 Nf3
    ["rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2"] = {
        { move = "g1f3", weight = 500 }
    },

    -- 1. e4 e5 2. Nf3 이후 Nc6
    ["rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2"] = {
        { move = "b8c6", weight = 480 },
        { move = "g8f6", weight = 200 } -- 페트로프 디펜스
    },

    -- 1. e4 e5 2. Nf3 Nc6 이후 Bb5 (루이 로페즈) or Bc4 (이탈리안 게임)
    ["r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3"] = {
        { move = "f1b5", weight = 450 }, -- 루이 로페즈
        { move = "f1c4", weight = 400 }, -- 이탈리안 게임
        { move = "d2d4", weight = 150 }  -- 스카치 게임
    },

    -- 1. e4 c5 (시실리안 디펜스) 이후 Nf3
    ["rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2"] = {
        { move = "g1f3", weight = 480 }
    },

    -- 1. e4 c5 2. Nf3 이후 d6
    ["rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2"] = {
        { move = "d7d6", weight = 450 },
        { move = "b8c6", weight = 300 },
        { move = "e7e6", weight = 200 }
    },

    -- 1. e4 c5 2. Nf3 d6 3. d4
    ["rnbqkbnr/pp2pppp/3p4/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3"] = {
        { move = "d2d4", weight = 500 }
    },

    -- 1. d4 d5 (클로즈드 게임) 이후 c4 (퀸즈 갬빗)
    ["rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2"] = {
        { move = "c2c4", weight = 480 },
        { move = "g1f3", weight = 200 }
    },

    -- 1. d4 d5 2. c4 이후 e6 (퀸즈 갬빗 거절)
    ["rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq - 0 2"] = {
        { move = "e7e6", weight = 450 },
        { move = "c7c6", weight = 350 }, -- 슬라브 디펜스
        { move = "d5c4", weight = 150 }  -- 퀸즈 갬빗 수락
    }
}

return BookDatabase
