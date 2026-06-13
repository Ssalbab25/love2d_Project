-- TimeManager.lua: 제한시간 및 피셔 가산시간 관리 클래스
-- SOLID: 
-- - SRP (단일 책임 원칙): 화면 렌더링에 관여하지 않고 대국자별 잔여 제한 시간 연산, 피셔 딜레이(Fischer Increment) 가산만을 계산합니다.
-- - OCP (개방-폐쇄 원칙): 시간 관리의 규칙 세부 항목 변경 시 외부 로직 수정 없이 시간 업데이트 조건만 확장 가능합니다.

local Object = require "libs.classic"
local TimeManager = Object:extend()

function TimeManager:new(initialTime)
    self.initialTime = initialTime or 600
    self.whiteTime = self.initialTime
    self.blackTime = self.initialTime
end

-- 제한시간 감소 업데이트 연산 수행
-- dt: 프레임 델타 타임
-- gameMode: "offline", "vs_ai" 등
-- currentTurn: "white" 또는 "black"
-- isPaused: 게임 일시정지 유무 (게임오버, 프로모션 대기, 무승부 제안 팝업 등)
-- 반환값: isTimeout(boolean), winner(string/nil), gameOverReason(string/nil)
function TimeManager:update(dt, gameMode, currentTurn, isPaused)
    -- 오직 vs Human (offline) 모드에서만 타이머가 동작하며, vs AI 모드 혹은 일시정지 상태에서는 정지
    if gameMode == "vs_ai" or isPaused then
        return false, nil, nil
    end
    
    if currentTurn == "white" then
        self.whiteTime = self.whiteTime - dt
        if self.whiteTime <= 0 then
            self.whiteTime = 0
            return true, "black", "timeout"
        end
    else
        self.blackTime = self.blackTime - dt
        if self.blackTime <= 0 then
            self.blackTime = 0
            return true, "white", "timeout"
        end
    end
    
    return false, nil, nil
end

-- 피셔 딜레이(가산시간) 추가
-- color: "white" 또는 "black"
-- amount: 가산 초 (기본값 5초)
function TimeManager:addIncrement(color, amount)
    amount = amount or 5
    if color == "white" then
        self.whiteTime = self.whiteTime + amount
    else
        self.blackTime = self.blackTime + amount
    end
end

-- 시간 상태 초기화
function TimeManager:reset()
    self.whiteTime = self.initialTime
    self.blackTime = self.initialTime
end

return TimeManager
