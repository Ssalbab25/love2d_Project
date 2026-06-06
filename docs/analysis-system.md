---
AI 게임 분석 및 실시간 추천 시스템 기획 명세서
본 문서는 플레이어에게 현재 형세의 유리함(평가 점수)을 실시간으로 시각화하고, 수백 가지 마스터 기보를 바탕으로 최적의 다음 수를 추천하는 '분석 시스템'의 아키텍처 및 UI 기획 명세서이다.
---
# 1. 시스템 개요 (System Overview)

목적: 체스닷컴(Chess.com)과 유사한 게임 분석 환경을 제공하여 플레이어의 학습을 돕고 게임의 시각적 재미를 배가시킨다.핵심 기능:실시간 형세 평가 바 (Evaluation Bar): 현재 보드 상황을 점수화하여 흑/백 중 누가 얼마나 유리한지 화면 측면에 그래픽으로 표시.추천 수 화살표 (Hint Arrow): 시스템이 계산한 최적의 다음 수(Best Move)를 보드 위에 반투명 화살표로 시각화.


# 2. 데이터 구조 및 데이터베이스 (BookDatabase)

LuaJIT 환경에서의 메모리 효율과 탐색 속도를 위해 기보 데이터는 아래와 같이 구조화하여 관리한다.
기보 데이터셋 (Opening Book): 수백 가지 공식 마스터 기보를 FEN(Forsyth-Edwards Notation, 보드 상태 문자열) 또는 해시(Hash) 키 값으로 전환하여 테이블에 정적 캐싱(Static Caching)한다.

데이터 구조 예시:Lua-- 데이터 아키텍처 레이어 예시

local OpeningBook = {
    ["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"] = {
        { move = "e2e4", weight = 450 }, -- 백의 가장 인기 있고 유리한 수
        { move = "d2d4", weight = 380 }
    }
}


# 3. 핵심 아키텍처 설계 (SOLID 원칙 적용)

본 시스템은 연산 집약적인 로직과 시각적 UI가 결합되어 있으므로, 철저히 모듈을 분리하여 결합도를 낮춘다.

3.1. OpeningBookMatcher (SRP: 기보 매칭 책임)

역할: 현재 보드의 FEN 문자열을 추출하여 BookDatabase에 일치하는 데이터가 있는지 탐색한다.
동작: 매칭되는 기보가 존재할 경우, 가중치(weight)가 가장 높은 최적의 수(Best Move)를 반환한다.

3.2. EvaluationEngine (SRP: 형세 평가 책임)

기보 데이터베이스 범위를 벗어난 중후반전(Middle/End Game)에서는 실시간 알고리즘을 통해 점수를 계산한다.

# 평가 공식 (Evaluation Function):
$$\text{Score} = \sum (\text{Material Value}) + \sum (\text{Position Value})$$

기물 점수(Material): 폰(1), 나이트(3), 비숍(3), 룩(5), 퀸(9)

위치 가중치(Position): 기물이 중앙에 위치하거나 활동성이 좋을 때 추가 점수를 부여하는 8x8 정적 가중치 테이블(Piece-Square Tables)을 활용한다.

출력값: 센티폰(Centipawns) 단위의 정수형 점수를 반환한다. (예: +150은 백이 1.5폰만큼 유리함, -300은 흑이 3폰만큼 유리함)

3.3. AnalysisFacade (DIP: 고수준 인터페이스 역전)

역할: OpeningBookMatcher와 EvaluationEngine을 하위 모듈로 두고, 게임 루프와 통신하는 단일 창구 역할을 한다.

의존성 주입: Board 상태를 주입받아 최종적으로 { score = 120, bestMove = {from = "e2", to = "e4"} } 형태의 분석 데이터를 반환한다. 

게임 모델 코드는 이 모듈의 내부 동작(기보를 쓰는지, 알고리즘을 쓰는지)을 알 필요가 없다.


# 4. UI/UX 표현 및 렌더링 규칙 (AnalysisRenderer)

Love2D의 update/draw 분리 원칙에 따라, 분석 연산은 턴이 바뀔 때만 수행하고 draw 루프에서는 계산된 결과만 그린다.
평가 바 (Evaluation Bar):위치: 체스판 좌측 또는 우측에 세로형 막대 그래프로 배치.

동작: 백이 유리하면 흰색 영역이 위로 차오르고, 흑이 유리하면 검은색 영역이 아래로 차오름. 점수가 0점(균형)일 때는 정확히 50:50 분할.

최적화: 점수가 급격하게 변할 때 부드럽게 움직이도록 love.update(dt)에서 보간 연산(Lerp)을 수행한다.

추천 화살표 (Hint Arrow):위치: 체스판 타일 위 레이어.시각화: 시작 칸(from)에서 도착 칸(to)으로 향하는 반투명한 색상의 화살표 그리기.

구현: Love2D의 love.graphics.polygon 및 love.graphics.line을 조합하여 단일 함수로 캡슐화한다.


# 5. 경계 사례 및 주의점 (Edge Cases)

기보 데이터의 부재: 수백 가지 기보를 벗어난 완전히 난해한 수(Blunder)를 유저가 두었을 경우, OpeningBookMatcher는 nil을 반환하고 즉시 EvaluationEngine 알고리즘 연산 체제로 전환되어야 한다.

성능 저하 방지: 매 프레임마다 보드 전체를 평가하면 알고리즘 특성상 연산 병목이 온다. 오직 기물이 이동하여 보드 상태가 변경되었을 때(Turn Change) 딱 1번만 계산하여 그 값을 변수에 저장(Caching)한 뒤 재사용해야 한다.