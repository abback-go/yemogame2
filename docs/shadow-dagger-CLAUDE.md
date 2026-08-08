# 성창(聖槍) — 잊힌 성물 · 개발 지침 (Claude 필독)

> 이 파일은 새 세션에서 자동으로 읽힙니다. **먼저 이 문서 → 그다음 [`docs/handoff-2026-08-08.md`](docs/handoff-2026-08-08.md)** 순으로 보면 맥락이 복원됩니다.

## 1. 프로젝트 한 줄

**창(槍) + 신성력**을 쓰는 성창사가 되어, 천상의 **신전**을 거점으로 **인간계로 강림**해
**잊힌 성물**을 되찾는 **2D 사이드뷰 도트 액션 메트로바니아**.
톤·템포는 **할로우 나이트 실크송**(빠르고 곡예적·공격적), 아트는 **메이플 「시간의 신전」 리마스터**
(대리석·금세공·구름 하늘·은청 빛결정).

## 2. 목표와 제약 (매우 중요)

- **개발 환경:** 개발자는 군 사지방(제한 PC)에서 **브라우저만으로** 개발한다.
  - `cmd` · PowerShell · 작업관리자 = **정책 차단**. Claude Code CLI 로컬 설치 **불가**.
  - **되는 것:** Git for Windows(설치됨, `git 2.55`) + **Git Bash** + 브라우저 + **웹 Claude Code**.
  - 따라서 워크플로는 **웹 Claude Code가 커밋·푸시 → 사지방에서 `git pull` → 브라우저로 실행**.
  - **결론: 로컬 개발 도구를 전제하지 마라.** 검증은 브라우저 안에서 돌아가야 한다.
- **최종 목표:** 전역 후 **Unity로 이식·보완하여 Steam 판매**.
- 그러므로 **웹 빌드의 진짜 산출물은 코드가 아니라 "검증된 디자인 + 엔진 독립 데이터 + 이식 스펙"** 이다.

## 3. 개발 원칙

1. **데이터는 선언적·JSON 직렬화 가능하게.** 형상은 `rect:[x,y,w,h]`(좌하단 원점) → Unity `Rect`/`BoxCollider2D` 1:1.
   모든 요소에 **ascii `id`**(1차 키), 한글 `label`은 표시용.
2. **단일 파일 `file://` 실행을 깨지 마라.** 외부 `fetch` 금지. 데이터 반출은 게임 내 버튼/키(JSON 다운로드)로.
3. **검증은 인게임에서 돌아가야 한다.** node 전용 테스트만 두지 말 것(사지방에서 실행 불가).
   `proto/index.html`의 `runTests()`가 정본이고, `proto/verify-map.mjs`는 그걸 호출하는 CI 래퍼일 뿐.
4. **물리·도달성 수치는 단일 진실원에서 유도.** `REACH`를 손으로 적지 말고 `PHYS`에서 계산할 것.
5. **게이팅 검증에 하드코딩 리터럴 금지.** 반드시 데이터에서 파생. (이 원칙을 어겨서 시퀀스 브레이크 5건이 통과된 전례가 있다.)
6. **게이트 갭은 이동기 한계 대비 최소 `0.30u` 초과.** (렛지스냅 0.08 등 런타임 관대함을 흡수)
7. 아트는 최종 규격에 맞춘 플레이스홀더. 웹 전용 기술에 과투자 금지(최종 아트·오디오·셰이더는 Unity 단계).

## 4. 핵심 시그니처 — "창 꽂기"

> **실물 창을 던져 벽·지형·적 표면에 박아 작은 발판을 만들고, 딛고 도약하며, 빠르게 회수(돌아오며 타격).
> 한 번에 하나만. 공중 부양 발판은 없다(반드시 표면에 박혀야 함).**

- 이동·전투·수직 표현을 하나로 관통하는 정체성. **포고(pogo)는 실크송과 겹쳐서 의도적으로 배제.**
- **창대 도약(vault)은 도약 나브(`t:"vault"`) 또는 박힌 창 위에서만 발동.** 아무 발판에서나 3.4u가 나오지 않는다.
- 공중 부양 발판은 후속 신성력 강화판으로 남겨둠(진행 보상 훅).

## 5. 저장소 구조

```
CLAUDE.md                         ← 지금 이 문서
docs/
  handoff-2026-08-08.md           ★ 세션 인계 문서 (먼저 읽을 것)
  specs/2026-08-07-holy-spear-design.md      ★ 게임 기획 정본
  specs/2026-08-07-temple-training-map.md    ★ 맵 설계 (끝의 「개정 v1.1」이 구현 정본)
  unity-vertical-slice-spec.md               Unity 이식/필 검증 스펙
proto/
  index.html                      ★ 맵 프로토타입 v1.1 (단일 파일, 의존성 0)
  verify-map.mjs                  CI 래퍼 (인게임 runTests() 호출)
--- 아래는 폐기(legacy). 참고만, 수정하지 말 것 ---
index.html, arcane/               구 프로토타입
docs/specs/2026-07-11-arcane-academy-design.md   구 마법학교 기획서(폐기)
docs/specs/2026-05-25-shadow-dagger-eclipse-design.md
```

## 6. `proto/index.html` 구조 (v1.1)

- `PHYS` → `REACH`(유도) → `GATE_MARGIN`
- `MAP`(schema `temple-map/1.1`) — 층별 로컬 좌표 + `yOff`
  - `geo[]`(`t: solid|oneway|wall|vault|deco`, `rect`, `stand`, `cap:"finial"`, `gate`, `dropThrough`, `reachVia`)
  - `spearFaces[]`(`normal:[nx,ny]`, `role`) · `hazards[]`(`respawn`) · `checkpoints[]`
  - `portals[]`(`mode:"door"|"physical"`, `toPortal`) · `targets[]` · `collectibles[]`(`gate`) · `triggers[]` · `spearPlan[]`
- `buildWorld()` → **월드 좌표 1회 평탄화** (`WORLD_GEO`/`SPEAR_FACES`/…). 이후 코드에 `yOff` 산술 없음.
- `SpatialHash(2u)` + **콜리전 질의 API `Q.*`** + 동적 창 발판 `plantSpear()`/`recallSpear()`
- **검증 `runTests()` 11항목** — 상세는 인계 문서 참조
- 렌더: `draw*(g, T)` 단일 규약, 월드 좌표

## 7. 조작 (뷰어)

`드래그`/`WASD`/휠 = 카메라 · `1~7` 층 · `O` 조망 · `L` 라벨 · `K` 콜리전 · `G` 그리드 ·
`P` 창꽂기선 · `H` 도움말 · **`T` 검증 실행** · **`E` JSON 내보내기** · 표면 클릭 = 도달성 오버레이

## 8. 워크플로

- 브랜치 **`claude/magic-school-game-design-50d3ib`** 에 커밋·푸시. 커밋 메시지는 한국어, 상세히. PR은 요청 시에만.
- **변경 후 항상** `node proto/verify-map.mjs`(또는 인게임 `T`)로 11항목 통과 확인 + 전 층 렌더 에러 0.
- 설계 수치를 바꾸면 **`docs/specs/2026-08-07-temple-training-map.md`의 「개정」 절도 같이 갱신.**
- 사용자와는 **한국어**로 소통.
