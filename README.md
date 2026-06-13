# LÖVE2D Chess Game (vs AI & Real-time Analysis)

본 프로젝트는 LÖVE2D 엔진을 기반으로 구현된 체스 게임 애플리케이션입니다. 2인 오프라인 대국 모드(vs Offline)와 3개 난이도의 인공지능 대국 모드(vs AI), 그리고 체스닷컴 스타일의 실시간 형세 분석 및 최선의 수 추천 시스템을 탑재하고 있습니다.

---

## 📂 프로젝트 폴더 구조

본 프로젝트는 수업 공통 템플릿의 구조 규칙을 엄격하게 준수합니다.

```
love2d_Project/
├── src/                      # 실제 게임 코드 및 에셋
│   ├── ai/                   # AI 전략 클래스 (Easy, Medium, Hard)
│   ├── analysis/             # 실시간 형세 분석 관련 모듈 (Opening Book, PST Evaluator 등)
│   ├── pieces/               # 체스 기물 모듈 (Piece 상속체)
│   ├── Board.lua             # 보드 데이터 구조 관리
│   ├── BoardRenderer.lua     # 화면 렌더링 및 UI 처리
│   ├── Game.lua              # 게임 모드, 규칙, 턴 제어 (MatchManager)
│   ├── GameStateDetector.lua # 체크메이트/스테일메이트/기물부족 등 상태 판정
│   ├── MoveValidator.lua     # 합법수 필터링 및 킹 체크 검증
│   ├── TimeManager.lua       # 대국자 제한시간 및 피셔 가산시간 관리
│   └── main.lua              # LÖVE2D 진입점
├── tests/                    # 자동화 단위 테스트 모듈
│   ├── runner.lua            # 테스트 실행 스케줄러
│   ├── test_AIMode.lua       # AI 모드 및 난이도별 작동 테스트
│   ├── test_Analysis.lua     # FEN 생성, 오프닝 북, PST 평가 엔진 테스트
│   └── (기타 기물별 테스트)
├── docs/                     # 시스템 설계서 및 명세서
│   ├── System_spec.md        # 게임 시스템 기획 및 아키텍처 명세서
│   ├── AI_spec.md            # AI 난이도별 상세 동작 및 알고리즘 명세서
│   └── analysis-system.md    # 실시간 분석 시스템 기획 명세서
├── worklogs/                 # AI 협업 작업 로그 및 회고 기록
├── run.bat                   # Windows 환경 실행 스크립트
└── README.md                 # 본 가이드 문서 (설치/실행/검증 안내)
```

---

## 🛠️ 설치 방법

### 1. LÖVE2D 엔진 다운로드
본 게임은 **LÖVE 11.5** 버전에 최적화되어 있습니다.
- Windows 사용자: [LÖVE 공식 홈페이지](https://love2d.org/)에서 `LÖVE 11.5 (64-bit installer)` 또는 `zip` 버전을 다운로드합니다.
- 본 저장소의 `love-11.5-win64/` 디렉토리에 실행에 필요한 LÖVE2D 바이너리가 기본 포함되어 있습니다.

---

## 🚀 실행 방법

### Windows 환경
저장소 루트 디렉토리에서 아래 방법 중 하나로 실행합니다.
1. **배치 파일 실행**: `run.bat`를 더블 클릭하여 실행합니다.
2. **콘솔 직접 실행**:
   ```cmd
   "love-11.5-win64/lovec.exe" "src"
   ```

### macOS / Linux 환경
LÖVE2D가 설치되어 있는 경우 터미널에서 실행합니다.
```bash
love src
```

---

## 🧪 자동화 유닛 테스트 및 검증 방법

본 프로젝트는 완벽한 테스트 환경(TDD)을 갖추고 있습니다. 게임 구동 시 자동으로 테스트가 선행 실행되며, `--test-only` 플래그를 통해 콘솔에서 테스트만 독립적으로 실행하고 즉시 안전하게 종료할 수 있습니다.

### 테스트 실행 명령어 (Windows)
```cmd
"love-11.5-win64/lovec.exe" "src" --test-only
```

### 테스트 케이스 구성 (총 13개 검증 모듈)
- **tests.test_Board**: 보드 격자 구조 및 초기 배치 검증.
- **tests.test_Pawn / Rook / Bishop / Knight / Queen / King**: 기물별 정밀 행마법(장애물 감지 및 포획 범위) 검증.
- **tests.test_GameControl**: 턴 교대, 아군/적군 기물 선택 차단, 이동 완료 처리 검증.
- **tests.test_Checkmate**: 킹 체크 판정 및 탈출 불가 시 체크메이트 판정 검증.
- **tests.test_SpecialRules**: 프로모션(기물 승급 UI 대기), 캐슬링(킹/룩 미이동 및 통로 공격 방지), 앙파상(타겟 생성 및 포획 제거) 검증.
- **tests.test_DrawConditions**: 스테일메이트, 기물 부족 무승부(킹 대 킹, 킹+비숍 대 킹 등), 기권 패배, 무승부 제안 모달 및 타이머 제제 검증.
- **tests.test_AIMode**: AI 난이도(Easy, Medium, Hard) 설정에 따른 대기 지연(Timer), 타이머 정지(Pause), 정상 행마 반환 검증.
- **tests.test_Analysis**: 보드 상태의 FEN 문자열 생성, 오프닝 북 데이터베이스 매칭, Piece-Square Table(PST) 연산 및 AnalysisFacade 분석 반환 검증.
