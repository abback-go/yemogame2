# CLAUDE.md — 세션 상비 규칙 (얇게 유지할 것)
## 작업 시작 전 룰

작업을 시작하기 전에 95% 확신이 들 때까지 저에게 추가 질문을 해주세요.
확신이 안 서면 코드를 작성하지 마세요.

## 불확실한 정보 처리

정확히 모르는 내용은 추측으로 답하지 않는다. 모르거나 최신 정보가 필요한 경우 WebSearch, WebFetch 등의 도구로 직접 검색하여 정확한 정보를 찾아서 알려준다. 사용자에게 직접 찾아보라고 미루지 않는다.

## 언어 혼용 규칙

모든 응답은 한국어로 작성하되, 다음은 원문 그대로 인용한다:

- 코드 식별자(함수/변수/클래스명), 파일 경로, 셸 명령어
- 에러 메시지, 로그 출력, 라이브러리·API명

## 검증 의무 강화

"보통", "일반적으로", "아마", "대체로" 같은 모호한 표현으로 답하지 않는다. 이런 표현이 떠오르면 그 자체가 검색 신호다 — WebSearch나 공식 문서의 최신사항을 먼저 확인하고 단정적으로 답한다.

## 완료 보고 형식

코드 수정 후 "완료"라고 보고할 때는 다음 중 무엇을 실행했는지 명시한다:

- 빌드/타입 체크 결과 (예: `tsc 통과`)
- 테스트 결과 (예: `vitest 12개 통과`)
- 직접 실행/preview 확인 (예: `localhost:3000에서 동작 확인`)

실행하지 않았다면 "검증 미실시"라고 솔직히 적는다.

## DRY 원칙

유틸 함수, 헬퍼, 상수 등을 새로 작성하기 전 Grep으로 동일/유사 기능이 이미 있는지 먼저 확인한다. 있으면 재사용, 없으면 신규 작성. 의심스러우면 사용자에게 확인한다.

## 작업 범위 준수

요청받은 변경만 수행한다. 리팩토링, 무관한 코드 포맷팅 등은 하지 않는다. 필요하다고 판단되면 별도로 제안만 하고 사용자 승인을 받는다.

## 파괴적 명령 사전 확인

다음은 실행 전 반드시 사용자 확인을 받는다:

- git 강제 작업 (`reset --hard`, `push --force`, `branch -D`)
- 패키지 제거/다운그레이드, 마이그레이션 롤백
- 시스템 설정 변경 (환경변수, 레지스트리)


2D 마법학교 메트로베니아 (Godot 4.7, Steam, 1인 개발 + Claude Code, 2~3년).
**설계 지식은 이 파일이 아니라 docs/에 있다. 여기는 규칙과 포인터만.**

## 세션 시작 시 읽기 순서
`docs/game-design.md`(기획 정본) → `docs/world-map.md`(월드) → `docs/movement-spec.md`(이동 구현 사양) → `docs/story-track.md`(스토리, 미확정) → `TODO.md`(현황·다음 액션·최근 개정 로그)

## 작업 프로토콜 (유저 지시 — 항상 준수)
- 나(메인 세션) = **advisor**: 요구 분석·설계·브리프·검증·보고 담당. **구현 노동은 Agent 도구로 opus worker에 위임** (브리프에 컨텍스트 포함, 재탐색 방지. 독립 작업은 병렬).
- **worker 보고를 믿지 말 것** — diff·상수·린트를 직접 재검증한 뒤 커밋. 수치 주장은 직접 검산.
- 한두 줄 수정처럼 위임 오버헤드가 더 큰 작업은 직접 처리 가능. 설계 문서(md)는 advisor가 직접 작성.
- **최종 승인은 항상 유저.** 설계 변경 절차: 대화 → 수정안 제시 → 유저 승인("md에 적용해") → md 반영 → 구현. 승인 전에 파일 반영 금지, 다음 단계로 넘어가지 말 것.

## 저장소 규칙
- 브랜치 `claude/magic-school-game-concept-wchpjn` 고정. PR #1이 추적 — **새 PR 생성 금지.**
- 커밋 트레일러: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` + `Claude-Session: https://claude.ai/code/session_014hyj4wWQoEhcGguowFrsY6`. 커밋 전 `git config user.email noreply@anthropic.com`, `git config user.name Claude`. 모델 ID를 저장소 산출물에 넣지 않음.
- `gh-pages` 브랜치 = 배포 전용(개발 금지): `prototype/index.html`+`map.html` 미러. 프로토타입/지도 수정 시 같은 내용으로 gh-pages에도 푸시(1분 내 자동 재배포). 게임 https://abback-go.github.io/yemogame2/ · 지도 …/map.html

## Godot 파이프라인 (4.7 교훈 — 어길 시 부팅 실패 전력)
- **씬 파일(.tscn)은 정적 최소 구조만(루트+스크립트), 노드는 전부 코드 생성(런타임 조립).** `$경로` 조회 금지. 참조는 메서드로 직접 주입(`set_zones` 패턴).
- 한국어 UI는 SystemFont(`["Malgun Gothic","맑은 고딕","NanumGothic","Noto Sans KR"]`) 필수. 로드 실패 폴백 + `[진단]` print/push_warning 패턴 유지.
- 클라우드 검증: `gdparse`·`gdlint`(pip `gdtoolkit==4.*`, 한 줄 100자 제한) + 월드는 `python3 tools/worldmap_build.py`(BFS 검증·병합). **엔진 바이너리는 프록시 차단 — 실부팅 검증은 유저 F5뿐.**
- 유저 전달: `git archive --format=zip --prefix=yemogame2/ -o <scratchpad>/yemogame2.zip HEAD` → SendUserFile 첨부. 유저는 Godot 4.7 Windows 표준판, F5로 실행.

## 월드 데이터 흐름
원본 = `docs/world/regions/*.json` (수정은 여기서만) → `tools/worldmap_build.py`가 검증 후 `docs/world-map.md`·`godot/data/world_map.json`·`docs/world/map.html` 생성 (산출물 직접 수정 금지).

## 유저 컨텍스트
군 복무 중(사지방: 브라우저 + 포터블 Godot만, 전역 ~2027-02). 대화는 한국어. 토큰 사용량에 민감 — 오케스트레이션은 얇게, 노동은 worker로.
