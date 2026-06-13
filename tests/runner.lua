local runner = {}
local config = require "src.config"

function runner.run()
    config.isTesting = true
    print("=== 테스트 러너 작동 시작 ===")
    local tests = {
        "tests.test_Board",
        "tests.test_Pawn",
        "tests.test_Rook",
        "tests.test_Bishop",
        "tests.test_Knight",
        "tests.test_Queen",
        "tests.test_King",
        "tests.test_GameControl",
        "tests.test_Checkmate",
        "tests.test_SpecialRules",
        "tests.test_DrawConditions",
        "tests.test_AIMode",
        "tests.test_Analysis",
    }

    local successCount = 0
    local failCount = 0

    for _, testPath in ipairs(tests) do
        print("테스트 실행 중: " .. testPath)
        -- 패키지 캐시를 강제로 제거해 매번 최신 버전을 로드하도록 합니다
        package.loaded[testPath] = nil

        local status, err = pcall(function()
            local test = require(testPath)
            if type(test) == "table" and type(test.run) == "function" then
                test.run()
            else
                error("테스트 모듈에 run() 함수가 존재하지 않습니다: " .. testPath)
            end
        end)

        if status then
            print("성공: " .. testPath)
            successCount = successCount + 1
        else
            print("실패: " .. testPath .. " | 에러 내용: " .. tostring(err))
            failCount = failCount + 1
        end
    end

    print(string.format("=== 테스트 종료: 성공 %d개, 실패 %d개 ===", successCount, failCount))
    config.isTesting = false
    if failCount > 0 then
        error("일부 유닛 테스트가 실패했습니다. 실행을 중단합니다.")
    end
end

return runner
