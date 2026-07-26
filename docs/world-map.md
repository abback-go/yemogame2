# 월드맵 마스터 문서 — 대협곡 세계

> 생성원: `docs/world/overview.md`(원칙 — 손으로 관리) + `docs/world/regions/*.json`(지역별 원본) → `tools/worldmap_build.py`가 검증·병합.
> 수정은 원본에서 하고 스크립트를 다시 돌릴 것. 이 문서와 `godot/data/world_map.json`은 산출물.

# 월드 설계 원칙 (기획서 §5에서 이관 — 손으로 관리하는 부분)

> ## ⚠ 상태: 재료 창고 (2026-07-26 유저 확정)
>
> **이 월드 설계는 스토리보다 먼저 만들어졌다.** 그래서 지금은 **정본이 아니라 재료 창고**다 — 지형 아이디어·기믹·분위기를 참조하는 용도로만 쓴다.
> 맵은 스토리의 **막 6개**(`docs/story-track.md` §2.1)에 필요한 만큼 **0에서 다시 쌓는다**(기획서 §9 · §12-1). "295→260 컷" 방식은 폐기 — 맵이 기준으로 남으면 스펙 폭발이 그대로다.
> 또한 아래의 **게이트 순서는 이미 무효**다: 얼음 발판·물잠이 07-26에 폐기되어(movement-spec v2.2) 게이트가 이단점프 → 벽달리기 → 활공 → 비행 4개로 줄었고, 새 게이트 축은 기획서 §11-2 미결이다.
>
> 이 파일은 `tools/worldmap_build.py`가 `docs/world-map.md` 생성 시 맨 앞에 포함한다.
> 방 단위 상세는 `docs/world/regions/*.json`이 원본. 게임 시스템은 `docs/game-design.md`.

## 구조 원칙
- **골격**: 따뜻한 학교 허브 → 개성 있는 지역들 → 후반 지역 (아르피아의 지형 감성 + HN의 유기적 연결)
- **지역 개성은 싸게**: 색 + 음악 + 고유 적 1종 + 이동 트릭 1개 + 지역 속성 1개
- **이중 게이팅**: 길은 ①이동 마법(하드 게이트 — 필수 진행)과 ②적의 강함(소프트 게이트 — 일찍 가면 위험하지만 실력으로 뚫을 수 있음)의 두 겹으로 잠근다. 레벨 게이팅("레벨 20 찍고 와")은 금지.
- **수직 장벽 규칙** (2026-07-17 — 벽달리기 전벽 허용·8방향 대시 채택의 대가): 통과 불가 수직 장벽 = **공중 체인 최대 수직 도달(점프+이단점프+상향 대시+벽달리기 1회 ≈ 400px, 튜닝 후 확정)보다 높은 민벽(중간 선반 없음) / 처마(오버행) / 위험 표면.** 굴뚝(마주보는 벽 쌍)은 의도된 등반 루트에만 배치. 방 내부 치수 설계 시 이 값 하나로 기계 검증한다.
- **지도 그리기**: 새 지역은 지도 없이 진입 → 지역 내 지도 입수 → 탐험으로 채움
- **루프형 맵 그래프**: 막다른 트리 금지 — 백트래킹이 지름길 발견이 되게
- **거점**: 저장 + 지도 갱신 + 각인 교체. 패스트트래블은 월드가 커진 뒤 개방
- **비전투 다양성**: 추격·장애물·정밀 플랫포밍 챌린지 룸(선택 격리)·미로·어둠/매복 — 전부 이동 엔진 재사용
- **인카운터 밀도**: 다수 잡몹 벌판이 아니라 소수 정예 개체를 하나하나 상대하는 배치 (HN 배치 감각) — 상세는 기획서 §6

## 월드 지형 — "대협곡 세계" (확정)
학교는 깊은 협곡의 양쪽 절벽에 걸쳐 지어진 수직 캠퍼스. 세계는 협곡을 수직 척추로 삼아 아래(심부)로도 위(하늘)로도 열린다.

```
(하늘층)                      ⟪ 바람이 시작되는 곳 ⟫  ← 최후반
                              ▲ 시계탑 기류      ▲ 폭풍 상승기류
═(지표층)═════════════════════│═════════════════│══════════════════════
 [거울의 도시]─가도─[기사단 마을]─┐  [번개 목장]──고개──[종의 계곡]
   사막·태양      검의 질서      │      번개         얼음 │(언 갱도)
     │ 지하 수로            ┌───▼── 협 곡 ──────────────┐ ↘
     │                     │ [협곡 학교]·········[첫 학교] │← 건너편 절벽,
     │                     │  본교·도서관·시계탑    (폐교)  │  첫날부터 보임
     │                     │     ↕ 곤돌라                 │
     │                     │ [곤돌라 마을]     [온천]─강─[조수 도시]─바다
     │                     │     ↕                        │ 썰물에만↓
     │                     │  [정수장] ─ 옛 갱도 문        │ [수몰 성소]
═(심부)════════════════════│═════│═══════════════════════│═══════════
 [거인의 광산]══수레 레일════╧═════╝                        │
   대지·미로 │ 심장부의 열기        [잠들지 않는 숲]          │
            ▼                협곡 바닥 — 해가 닿지 않는 땅   │
        [가마 마을]                │                        │
         불의 본고장               └────── 지하 수맥 ────────┘
```

**지리가 설정을 설명한다**: 잠들지 않는 숲이 어두운 이유 = 협곡 바닥이라 햇빛이 닿은 적 없음 / 첫 학교(폐교)는 첫날부터 보이는 '갈 수 없는 랜드마크' / 광산 심장부의 열기가 가마 마을의 가마를 데움.

## 연결 구조
- 모든 지역은 이웃 2~4개와 접속 (HN 문법)
- **루프 5개**: ①서쪽(학교→정수장→광산→서쪽 가도→기사단 마을→학교) ②심부(광산 하부→숲→협곡 벽→곤돌라 마을) ③동쪽(학교→온천→조수 도시→수몰 성소→지하 수맥→숲) ④북쪽(번개 목장→종의 계곡→언 갱도→광산) ⑤남쪽(광산 심장부→가마 마을→남쪽 가도→거울의 도시)
- **패스트트래블 2종**: 곤돌라망(수직: 학교↔간이역↔곤돌라 마을) + 폐선 수레 레일(수평: 광산↔폐역 교차로↔사막 앞)
- **진행 흐름(이동 마법 = 개방 순서)**: 튜토리얼(학교·실습림·곤돌라 마을) → 이단점프: 광산 → 벽달리기: 숲·기사단 마을 → 얼음 발판: 거울의 도시·조수 도시 → 활공: 번개 목장·종의 계곡 → 물잠: 수몰 성소 → 비행: 부유군도·첫 학교

## 지역 내부 문법 (대지역 공통 템플릿)
| 요소 | 수량 | 비고 |
|---|---|---|
| 입구 | 2~3 | 첫 진입구 + 능력으로 열리는 뒷문 |
| 마을/안전지대 | 1 | NPC·상점·로컬 스토리 허브. 지역 지도 입수처 |
| 거점 | 2~3 | 보스 앞 1개 필수 |
| 필드 구획 | 3~4 | 지역 기믹이 도입→응용→조합으로 심화 |
| 미니보스 | 1~2 | 하나는 선택(비밀 수문장) |
| 최종보스 | 1 | 보스전 = 지역 기믹의 졸업시험 |
| 보스 보상 | — | 지역 마법 + 지역 상태 변화(마을이 눈에 띄게 좋아짐) |
| 내부 루프 | 2+ | 일방 낙하/잠긴 문 → 뒤에서 열리는 지름길 |
| 비밀 | 3~5 | 숨은 방·챌린지 룸 1(격리)·달시장 터 후보 |
| 규모 | 25~35방 | 소지역은 5~12방(완화 문법) |

- **보스 문의 열쇠는 로컬 스토리에서** — "잡으러 왔다"가 아니라 "마을 일을 돕다 보니 그 문이 열렸다"

## 방 수 현황 (v1 설계 완료분)
17개 지역 295방 설계 완료 (`docs/world/regions/`). 기획서 예산(185~260)의 최대 확장판 — **컷 라인: 종의 계곡 24방(컷 후보) + 비밀 일부 → 컷 시 ~260방.** 최종 결정은 수직 슬라이스에서 방 1개 생산 시간을 실측한 뒤 데이터로 내린다.


---

**규모: 17개 지역 / 295방** (기획서 §5.7 예산 185~260의 최대 확장판 — 컷 라인: 종의 계곡 24방 + 비밀 일부)

## 진행 단계별 개방 (검증 결과)

| 단계 | 해금 이동술 | 새로 열림 | 누적 도달 |
|---|---|---|---|
| 0 | 시작 킷(대시·부유) | +91 | 91 |
| 1 | 이단점프 | +30 | 121 |
| 2 | 벽달리기 | +41 | 162 |
| 3 | 얼음 발판 | +42 | 204 |
| 4 | 활공 | +52 | 256 |
| 5 | 물잠 | +6 | 262 |
| 6 | 비행 | +33 | 295 |

## 지역별 상세

### 협곡 학교 (`sch`) — 36방
- **정체성**: 협곡 양쪽 절벽에 걸쳐 지어진 수직 캠퍼스 — 세계의 허브. 수업·승급·각인·기록 정리의 중심이자 끝까지 피난처.
- **속성**: 정규 3속성(불·물·바람) / **팔레트**: 따뜻한 석재 베이지 + 남색 지붕 + 창마다 노란 불빛 / **음악**: 목관+하프, 낮에는 부산하고 밤에는 고요한 두 버전
- **고유 적**: 없음(결계 돔 안의 훈련 허수아비만 — 전투는 실습으로 격리)
- **보스 열쇠(로컬 스토리)**: 보스 없음 — 허브. 대신 승급 시험(3부)이 이 지역의 '보스' 역할을 한다.
- **클리어 후 변화**: 막이 진행될수록 게시판·급식 메뉴·학생들의 대화가 갱신되고, 시계탑 꼭대기가 마지막에 열린다.
- 루프: 정문 마당→본관→아래 계단→정수장→곤돌라 마을→곤돌라 승강장→정문 마당 (허브 순환)
- 루프: 서쪽 다리 개통 시: 학교↔기사단 마을 직통 (월드 루프 ①의 닫힘)

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| sch_gondola_st | **곤돌라 승강장** `gondola` | transit | 정문 | 학교의 현관. 협곡 아래 마을로 내려가는 곤돌라가 삐걱이며 오간다. | →gon_lift_top; →sch_plaza |
| sch_plaza | **정문 마당** | hub | 정문 | 협곡 바람이 지나가는 너른 마당. 게시판 앞으로 학생들이 모여든다. | →sch_gondola_st; →sch_west_bridge; →sch_hall_main; →sch_dorm_hall; →sch_clock_base; →sch_backwoods_gate |
| sch_west_bridge | **무너진 서쪽 다리** | transit | 정문 | 협곡 서쪽으로 뻗다 끊긴 다리. 건너편 기사단 마을이 보이지만 지금은 갈 수 없다. | →sch_plaza; →kni_bridge_east(상태:서쪽 다리 개통) |
| sch_hall_main | **본관 홀** `map` | hub | 본관 | 의뢰 게시판과 대계단이 있는 학교의 심장. 종이 울리면 교실 문들이 일제히 열린다. | →sch_plaza; →sch_office; →sch_class_fire; →sch_class_move; →sch_lib_gate; →sch_dome; →sch_stairs_deep |
| sch_office | **교무처** | event | 본관 | 승급 서류와 학교 지도를 받는 곳. 오래된 서류 냄새. | →sch_hall_main |
| sch_class_fire | **불 기초 교실** | exam | 본관 | 그을음이 밴 벽. 화로에 불을 붙이는 첫 수업이 여기서 열린다. | →sch_hall_main; →sch_class_water |
| sch_class_water | **물 기초 교실** | exam | 본관 | 수반과 물시계가 늘어선 교실. 바닥이 늘 촉촉하다. | →sch_class_fire; →sch_class_wind |
| sch_class_wind | **바람 기초 교실** | exam | 본관 | 창문이 전부 열려 있는 교실. 종이가 날아다녀 문진이 필수다. | →sch_class_water |
| sch_class_move | **이동술 강의실** | exam | 본관 | 책상이 없다 — 바닥에 문양이 그려진 넓은 강의실. 이동술 수업 아크의 출발점. | →sch_hall_main |
| sch_dome | **결계 돔** | field | 훈련동 | 마법이 밖으로 새지 않는 반구형 훈련장. 실습 수업과 손맛 연습의 집. | →sch_hall_main; →sch_trial_hall; →sch_ceremony |
| sch_trial_hall | **시험의 회랑** | challenge | 훈련동 | 전 수업이 재사용하는 챌린지 룸. 수업마다 내부가 다른 코스로 재구성된다. | →sch_dome; →sch_appraise_class |
| sch_appraise_class | **감정학 교실** | exam | 훈련동 | 온갖 잡동사니가 유리장에 담긴 교실. '동의 없는 감정은 결례'가 첫 시간의 가르침. | →sch_trial_hall |
| sch_ceremony | **승급의 방** | event | 훈련동 | 승급식이 열리는 원형 홀. 바닥의 각인 문양이 승급자에게만 빛난다. | →sch_dome |
| sch_lib_gate | **대도서관 홀** | hub | 대도서관 | 천장까지 닿은 서가의 입구. 사서의 책상 위에 반납 안 된 책이 산을 이룬다. | →sch_hall_main; →sch_lib_stacks |
| sch_lib_stacks | **대서가** | field | 대도서관 | 사다리로 오르내리는 책의 절벽. 마도서 등록대가 안쪽에 있다. | →sch_lib_gate; →sch_lib_reading; →sch_lib_vault(열쇠:사서의 신뢰); →sch_lib_attic(비밀) |
| sch_lib_reading | **열람실** `warm` | event | 대도서관 | 난로가 타는 조용한 방. 창밖으로 협곡의 눈비가 지나간다. | →sch_lib_stacks |
| sch_lib_vault | **금서고** | secret | 대도서관 | 사서의 신뢰를 얻어야 열리는 서고. 읽을수록 통찰이 자라는 책들. | →sch_lib_stacks |
| sch_lib_attic | **서가 다락** `warm` | secret | 대도서관 | 책 수레 뒤에 숨은 사다리 위 다락. 오래된 학생들의 낙서가 남아 있다. | →sch_lib_stacks |
| sch_clock_base | **시계탑 기단** | transit | 시계탑 | 학교 어디서나 보이는 시계탑의 발치. 톱니 소리가 벽을 타고 내려온다. | →sch_plaza; →sch_clock_gears |
| sch_clock_gears | **톱니 층** | field | 시계탑 | 거대한 톱니 사이를 건너는 수직 플랫포밍. 시간이 몸으로 느껴지는 곳. | →sch_clock_base; →sch_clock_face |
| sch_clock_face | **문자반 층** `warm` | field | 시계탑 | 시계 문자반 뒤편. 유리 너머로 협곡과 건너편 폐교가 한눈에 들어온다. | →sch_clock_gears; →sch_clock_peak(비행) |
| sch_clock_peak | **시계탑 꼭대기** | transit | 시계탑 | 세계의 바람이 지나가는 첨탑 끝. 여기서 하늘의 기류에 오른다 — 최후반의 문. | →sch_clock_face; →sky_clock_updraft(비행) |
| sch_dorm_hall | **기숙사 복도** | hub | 기숙사 | 방문마다 다른 문패와 냄새. 밤이면 몰래 나온 학생들과 마주친다. | →sch_plaza; →sch_dorm_room; →sch_cafeteria; →sch_dorm_roof(비밀) |
| sch_dorm_room | **내 방** `bench,warm` | bench | 기숙사 | 주 거점. 침대·책상·기록 정리대 — 모험이 여기서 '내 것'이 된다. | →sch_dorm_hall |
| sch_cafeteria | **급식동** `warm` | event | 기숙사 | 오늘의 메뉴가 마법으로 떠 있는 식당. 소극과 소문의 산지. | →sch_dorm_hall |
| sch_dorm_roof | **기숙사 지붕** `warm` | secret | 기숙사 | 기왓장 아래 숨겨둔 누군가의 보물과, 협곡의 밤하늘. | →sch_dorm_hall |
| sch_backwoods_gate | **뒷숲 문** | transit | 뒷숲 실습림 | 실습림으로 나가는 쪽문. '허가 없이 깊이 들어가지 말 것' 팻말. | →sch_plaza; →sch_backwoods_field |
| sch_backwoods_field | **실습 터** | field | 뒷숲 실습림 | 수업 과제가 벌어지는 뒷숲의 너른 터. 첫 필드 전투를 여기서 배운다. | →sch_backwoods_gate; →sch_backwoods_glade; →sch_backwoods_spring(비밀) |
| sch_backwoods_glade | **실습림 빈터** | field | 뒷숲 실습림 | 쓰러진 고목이 벤치가 된 빈터. 과제 표적과 채집 노드가 흩어져 있다. | →sch_backwoods_field; →sch_backwoods_east |
| sch_backwoods_east | **실습림 동쪽 끝** | transit | 뒷숲 실습림 | 숲이 옅어지고 온천 김이 멀리 보이는 길목. | →sch_backwoods_glade; →spr_forest_path |
| sch_backwoods_spring | **숨은 옹달샘** `warm` | secret | 뒷숲 실습림 | 실습림 안쪽의 작은 샘. 정수병을 처음 확장해 주는 맑은 물이 솟는다. | →sch_backwoods_field |
| sch_stairs_deep | **아래 계단** | transit | 정수장 | 본관에서 학교의 아래로 내려가는 오래된 나선 계단. 내려갈수록 공기가 달다. | →sch_hall_main; →sch_cistern_upper |
| sch_cistern_upper | **정수장 상부** | field | 정수장 | 마나가 이슬처럼 맺히는 수반들. 곤돌라 마을의 우물 계단과도 이어진다. | →sch_stairs_deep; →sch_cistern_hall; →gon_lower_stair |
| sch_cistern_hall | **정수장** `bench` | bench | 정수장 | 학교가 이 위에 세워졌다. 역대 학생을 전부 기억하는 은퇴한 1호 골렘이 물가를 지킨다. | →sch_cistern_upper; →sch_cistern_deep; →sch_cistern_pool(기초:물) |
| sch_cistern_pool | **이슬 못** | secret | 정수장 | 수반을 물 기초로 채우면 열리는 안쪽 못. 첫 마력석 광맥이 잠들어 있다. | →sch_cistern_hall |
| sch_cistern_deep | **옛 갱도 문** | transit | 정수장 | 정수장 심부의 녹슨 문 — 문 너머는 거인의 광산. 첫 대지역으로 나가는 출구. | →sch_cistern_hall; →min_old_gate |

### 곤돌라 마을 (`gon`) — 10방
- **정체성**: 학교로 오르는 곤돌라 줄기에 계단식으로 붙어 자란 하숙·상점 마을. 튜토리얼 직후 만나는 세상의 첫 온기.
- **속성**: 없음 / **팔레트**: 낡은 목재 갈색 + 빨랫줄의 원색 + 곤돌라 케이블의 검은 선 / **음악**: 아코디언과 그릇 부딪는 소리, 저녁엔 느려진다
- **고유 적**: 없음(마을 — 안전지대)
- **보스 열쇠(로컬 스토리)**: 보스 없음 — 마을. 하숙집에 짐을 풀면(첫 거점) 마을 사람들의 부탁이 게시판으로 흘러들기 시작한다.
- **클리어 후 변화**: 의뢰 평판이 쌓일수록 장터에 좌판이 늘고 곤돌라 야간 운행이 열린다.
- 루프: 곤돌라 정거장→윗계단→중턱 장터→아랫계단→우물 계단→(정수장)→학교→곤돌라 (수직 생활 순환)

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| gon_lift_top | **곤돌라 정거장** `gondola` | transit | 윗마을 | 마을 꼭대기의 정거장. 케이블이 협곡 위 학교까지 걸려 있다. | →sch_gondola_st; →gon_steps_up |
| gon_steps_up | **윗계단 골목** | town | 윗마을 | 계단 양옆으로 하숙 간판이 다닥다닥. 처마 밑을 지나면 밥 냄새가 난다. | →gon_lift_top; →gon_inn; →gon_steps_mid |
| gon_inn | **하숙집** `bench,warm` | bench | 윗마을 | 주인 아주머니의 하숙집 — 마을의 거점. 늦게 들어가면 잔소리와 야식이 같이 나온다. | →gon_steps_up |
| gon_steps_mid | **중턱 장터** `shop,map` | town | 중턱 | 마을의 배꼽. 지역 지도를 파는 행상과 소식이 모이는 좌판들. | →gon_steps_up; →gon_workshop; →gon_moon_site; →gon_steps_low |
| gon_workshop | **지팡이 공방** `shop` | town | 중턱 | 장인이 마력 회로를 손보는 공방. 첫 지팡이 정비를 여기서 배운다. | →gon_steps_mid |
| gon_moon_site | **달빛 빈터** `moon_site` | event | 중턱 | 평소엔 빨래만 널린 빈터 — 보름밤이면 등불이 줄지어 켜지고 낯선 문이 선다. | →gon_steps_mid; →mkt_gate_gon(상태:보름밤) |
| gon_steps_low | **아랫계단** | town | 아랫마을 | 마을의 발치. 절벽 쪽에서 찬바람이 올라와 겨울엔 다들 종종걸음. | →gon_steps_mid; →gon_cellar(비밀); →gon_cliff_gate; →gon_lower_stair |
| gon_cellar | **바람 창고** | secret | 아랫마을 | 계단 아래 숨은 창고. 옛 상인의 장부와 마력석 꾸러미가 먼지를 쓰고 있다. | →gon_steps_low |
| gon_cliff_gate | **절벽 뒷문** | transit | 아랫마을 | 마을 뒤 협곡 벽으로 나가는 좁은 문. '바람 부는 날엔 나가지 말 것.' | →gon_steps_low; →cyn_ledge_top |
| gon_lower_stair | **우물 계단** | transit | 아랫마을 | 마을 우물이 있는 가장 낮은 계단 — 물길이 학교 정수장과 이어져 있다. | →gon_steps_low; →sch_cistern_upper |

### 대협곡 (`cyn`) — 12방
- **정체성**: 세계의 수직 척추 — 절벽·선반·낡은 사다리로 이어진 연결 조직. 위로는 고원, 아래로는 해가 닿은 적 없는 바닥.
- **속성**: 없음 / **팔레트**: 회청색 암벽 + 높이에 따라 변하는 빛(위는 금빛, 아래는 남색) / **음악**: 바람 소리 그 자체가 음악 — 높이에 따라 화음이 변한다
- **고유 적**: 절벽 틈의 바람매 — 상승기류를 타고 급습해 오는 비행형.
- **보스 열쇠(로컬 스토리)**: 보스 없음 — 통로 지역. 대신 수직 왕복 자체가 시험이다.
- **클리어 후 변화**: 곤돌라 간이역이 수리되면(의뢰) 협곡 중단이 패스트트래블로 열린다.
- 루프: 낙하 수직굴로 한 번에 내려가고, 벽달리기로 벽 하부에서 되올라오는 수직 루프
- 루프: 간이 곤돌라역 개통 후: 중단↔학교/마을 패스트트래블 루프

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| cyn_east_rim | **동쪽 벼랑 끝** | transit | 협곡 상부 | 협곡 동쪽 가장자리. 고원의 바람이 밀려 내려오고, 건너편엔 폐교가 마주 서 있다. | →cyn_rim_path; →lig_west_gate(활공); →old_front_gate(비행) |
| cyn_rim_path | **벼랑 순례길** | field | 협곡 상부 | 바람 순례자들이 밟아 다진 좁은 길. 발밑으로 협곡 전체가 내려다보인다. | →cyn_east_rim; →cyn_ledge_top |
| cyn_ledge_top | **바람 선반** | field | 협곡 상부 | 곤돌라 마을 뒷문과 이어지는 첫 선반. 여기서부터 아래는 사다리와 배짱의 영역. | →gon_cliff_gate; →cyn_rim_path; →cyn_ladder_upper |
| cyn_ladder_upper | **낡은 사다리 상부** | field | 협곡 상부 | 몇 세대의 학생들이 못질해 이은 사다리 길. 군데군데 발판이 삭았다. | →cyn_ledge_top; →cyn_gondola_mid; →cyn_echo_shelf(비밀) |
| cyn_echo_shelf | **메아리 선반** | secret | 협곡 상부 | 소리가 세 번 돌아오는 움푹한 선반. 옛 측량사의 기록과 마력석 광맥. | →cyn_ladder_upper |
| cyn_gondola_mid | **간이 곤돌라역** `bench,gondola` | bench | 협곡 중단 | 협곡 중단의 버려진 간이역. 수리하면 케이블이 다시 걸린다 — 협곡의 허리 거점. | →cyn_ladder_upper; →cyn_wall_mid |
| cyn_wall_mid | **협곡 벽 중단** | field | 협곡 중단 | 빛이 옅어지기 시작하는 높이. 절벽 틈마다 바람매가 둥지를 튼다. | →cyn_gondola_mid; →cyn_drop_shaft; →cyn_wind_hollow(비밀) |
| cyn_wind_hollow | **바람 안 닿는 굴** `warm` | secret | 협곡 중단 | 이상하리만큼 고요한 움푹한 굴. 누군가 담요와 등잔을 두고 갔다. | →cyn_wall_mid |
| cyn_drop_shaft | **낙하 수직굴** | transit | 협곡 하부 | 바닥이 보이지 않는 수직굴 — 뛰어내리면 빠르지만, 돌아오는 길은 벽을 달려야 한다. | →cyn_wall_mid; →cyn_wall_low(벽달리기)[일방] |
| cyn_wall_low | **어스름 벽 하부** | field | 협곡 하부 | 여기서부터 해가 닿은 적 없는 세계. 이끼가 빛을 대신해 희미하게 빛난다. | →cyn_drop_shaft(벽달리기); →cyn_floor_south; →cyn_root_cave(비밀) |
| cyn_root_cave | **뿌리 굴** | secret | 협곡 하부 | 숲의 나무뿌리가 협곡 벽까지 뻗어 든 굴. 뿌리 사이에 마력석이 맺혀 있다. | →cyn_wall_low |
| cyn_floor_south | **협곡 바닥 남단** | transit | 협곡 하부 | 협곡의 밑바닥. 남쪽으로 잠들지 않는 숲의 검은 우듬지가 시작된다. | →cyn_wall_low; →for_mouth_north |

### 거인의 광산 (`min`) — 32방
- **정체성**: 화석이 된 태고 거인의 몸을 파 내려가는 광산 — 마력석의 산지이자 세계의 길찾기 미로. 이단점프가 여는 첫 대지역.
- **속성**: 대지 / **팔레트**: 황토·뼈의 상아색 + 갱도 램프의 주황 점들 / **음악**: 곡괭이 리듬과 낮은 울림 — 심부로 갈수록 심장박동 같은 저음이 섞인다
- **고유 적**: 잠꼬대 굴착꾼 — 평소엔 화석처럼 잠들어 있다가 소리(공격·달리기)에 깨어나는 석상형.
- **지역 마법**: 돌기둥(가칭) — 발밑에서 돌기둥을 솟구쳐 적을 띄우고 낮은 발판이 된다 — 무겁고 결정적인 지역 마법
- **보스 열쇠(로컬 스토리)**: 입구 캠프의 노광부 일을 돕다 보면 '거인을 달래는 자장가'(진동의 리듬)를 배운다 — 그 리듬 없이 심장 방 문은 열리지 않는다.
- **클리어 후 변화**: 심장의 맥동이 잦아들어 무너지던 갱도가 안정되고, 열기 통로(가마 마을행)와 수레 레일 전 구간이 개방된다.
- 루프: 권양기를 수리하면 잊힌 레일 구간이 열려 심부↔입구 캠프 직통 지름길이 된다
- 루프: 뼈의 미로 가짜 출구가 사실 상부 갱도로 되돌아오는 낙하 지름길
- 루프: 언 갱도·수문·열기 통로 — 이웃 지역들로 향하는 뒷문 셋이 전부 나중에 열리는 외부 루프

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| min_old_gate | **갱도 문턱** | transit | 입구 캠프 | 정수장의 옛 갱도 문 너머, 광산 쪽 문턱. 여기부터 공기에 돌가루 맛이 난다. | →sch_cistern_deep; →min_camp |
| min_camp | **입구 캠프** `bench,map,shop` | town | 입구 캠프 | 광부들의 천막과 화덕. 노광부가 신입에게 갱도의 예절을 가르친다 — 지역 지도 입수처. | →min_old_gate; →min_camp_gate; →min_toolshed; →min_upper_1; →min_forgotten_rail(상태:권양기 수리) |
| min_camp_gate | **지상 문** | transit | 입구 캠프 | 광산이 지상의 옛 가도와 만나는 문. 수레 바큇자국이 서쪽으로 이어진다. | →min_camp; →roa_mine_trail |
| min_toolshed | **장비고** `shop` | town | 입구 캠프 | 곡괭이·램프·밧줄이 걸린 창고. 광부 조합의 소소한 의뢰가 붙는다. | →min_camp |
| min_upper_1 | **버팀목 갱도** | field | 상부 갱도 | 거인의 갈빗대를 버팀목 삼은 상부 갱도. 첫 광맥과 첫 매복이 함께 있다. | →min_camp; →min_rail_st; →min_dust_hall |
| min_rail_st | **수레 정거장** `rail` | transit | 상부 갱도 | 폐선 수레 레일의 광산 쪽 종점. 레일이 다시 달리면 세계의 서쪽이 가까워진다. | →min_upper_1; →min_upper_2 |
| min_upper_2 | **수레 나들목** | field | 상부 갱도 | 수레를 타고 갈라지는 갱도들을 익히는 구간 — 이 지역 이동 트릭의 도입부. | →min_rail_st; →min_winch; →min_maze_gate(이단점프) |
| min_winch | **권양기 방** | event | 상부 갱도 | 멈춘 권양기와 끊긴 승강 케이블. 부품을 모아 수리하면 잊힌 레일이 깨어난다. | →min_upper_2; →min_cart_run |
| min_cart_run | **수레 질주로** | challenge | 상부 갱도 | 격리된 수레 질주 챌린지 — 갈림길마다 레버를 젖혀 완주하면 광부들의 상금이 걸려 있다. | →min_winch |
| min_dust_hall | **먼지 홀** | field | 상부 갱도 | 발소리가 먼지를 일으키는 넓은 홀 — 잠꼬대 굴착꾼이 처음 등장하는 안전한 소개 방. | →min_upper_1; →min_echo_gallery; →min_frozen_adit |
| min_echo_gallery | **울림 회랑** | field | 상부 갱도 | 소리가 벽을 타고 달리는 회랑. 조용히 걷는 법을 배우는 응용 구간. | →min_dust_hall; →min_vein_1(이단점프) |
| min_frozen_adit | **얼어붙은 막장** | transit | 상부 갱도 | 얼음이 벽을 타고 내려온 북쪽 막장 — 위쪽 어딘가와 이어져 있지만 얼음 너머는 보이지 않는다. | →min_dust_hall; →bel_adit_south(상태:언 갱도 개통) |
| min_maze_gate | **미로 어귀** | field | 뼈의 미로 | '여기부터 지도가 그려지지 않는다' — 광부들의 경고판. 표식을 직접 남겨야 하는 구간의 시작. | →min_upper_2; →min_maze_rib |
| min_maze_rib | **갈비뼈 회랑** | field | 뼈의 미로 | 거인의 갈비뼈 사이로 갈라지는 길들. 어느 뼈나 똑같이 생겼다. | →min_maze_gate; →min_maze_spine; →min_maze_marrow(비밀) |
| min_maze_marrow | **골수 굴** | secret | 뼈의 미로 | 갈비뼈 안쪽의 숨은 굴 — 마력석이 가장 굵게 맺히는 부광맥. | →min_maze_rib |
| min_maze_spine | **등뼈 교차로** | field | 뼈의 미로 | 미로의 중심 — 여섯 갈래가 만난다. 바닥의 옛 표식은 절반이 지워져 있다. | →min_maze_rib; →min_maze_false; →min_bone_shrine(비밀); →min_maze_exit |
| min_maze_false | **가짜 출구** | transit | 뼈의 미로 | 빛이 드는 줄 알았던 구멍 — 상부 갱도로 떨어지는 낙하 지름길이었다. 미로의 짓궂은 농담. | →min_maze_spine; →min_upper_1[일방] |
| min_bone_shrine | **뼈 사당** `warm` | secret | 뼈의 미로 | 광부들이 거인에게 절하는 오래된 사당. 촛농이 수백 년 치 쌓여 있다. | →min_maze_spine |
| min_maze_exit | **미로 남단** | field | 뼈의 미로 | 미로를 벗어나면 벽의 색이 변한다 — 여기서부터 굳은 핏줄, 광산의 진짜 속살. | →min_maze_spine; →min_vein_1; →min_west_end |
| min_west_end | **서단 수로** | transit | 뼈의 미로 | 물소리가 벽 너머에서 들리는 서쪽 끝 — 수문이 잠겨 있다. 열쇠는 사막의 도시 쪽에 있다. | →min_maze_exit; →mir_waterway_east(상태:수문 개방) |
| min_vein_1 | **굳은 핏줄 광맥** | field | 굳은 핏줄 | 거인의 혈관이 광맥이 된 구간. 붉은 결이 램프 빛에 맥박처럼 일렁인다. | →min_maze_exit; →min_echo_gallery; →min_vein_2(이단점프) |
| min_vein_2 | **맥박 광층** | field | 굳은 핏줄 | 발디딜 곳이 끊겨 이단점프 없이는 건널 수 없는 광층. 벽이 미세하게 두근거린다. | →min_vein_1(이단점프); →min_vein_camp; →min_lower_breach |
| min_vein_camp | **광부 야영지** `bench` | bench | 굳은 핏줄 | 심부 광부들의 간이 야영지 — 두 번째 거점. 여기서부터는 램프도 아껴 켠다. | →min_vein_2; →min_crush_arena; →min_forgotten_rail(상태:권양기 수리) |
| min_lower_breach | **무너진 하부** | transit | 굳은 핏줄 | 바닥이 숲으로 꺼져 내린 붕괴 지점 — 뛰어내릴 수는 있지만 돌아올 수는 없다. | →min_vein_2; →for_west_roots(벽달리기)[일방] |
| min_crush_arena | **무너지는 홀** | miniboss | 굳은 핏줄 | 천장이 반쯤 내려앉은 홀 — 미니보스 '무너뜨리는 자'가 길을 막는다(웹 프로토타입 계승). | →min_vein_camp; →min_deep_shaft |
| min_deep_shaft | **심부 수직굴** | field | 심장부 | 거인의 심장으로 내려가는 마지막 수직굴. 이단점프로 벽 사이를 지그재그로 딛는다. | →min_crush_arena; →min_heart_gate; →min_gem_hollow(비밀) |
| min_gem_hollow | **정동(晶洞) 굴** `warm` | secret | 심장부 | 수정이 별처럼 박힌 빈 굴 — 광산에서 가장 조용하고 가장 아름다운 방. | →min_deep_shaft |
| min_heart_gate | **심장 앞 등불** `bench` | bench | 심장부 | 보스 앞 거점. 광부들이 남긴 등불이 줄지어 심장 방을 가리킨다. | →min_deep_shaft; →min_giant_eye; →min_heart(열쇠:거인의 자장가) |
| min_giant_eye | **거인의 눈꺼풀** `warm` | event | 심장부 | 감긴 거인의 눈을 정면으로 마주보는 선반 — 이 광산이 '몸'임을 처음 실감하는 곳. | →min_heart_gate |
| min_heart | **심장 방** | boss | 심장부 | 보스전 — 꿈꾸는 거인의 심장. '깨우지 않으며' 치르는 전투: 소음·진동을 관리하는 기믹의 졸업시험. | →min_heart_gate; →min_heart_pass(상태:광산 심장 안정) |
| min_heart_pass | **열기 통로** | transit | 심장부 | 심장이 잠잠해진 뒤 열리는 뜨거운 통로 — 이 열기가 가마 마을의 가마를 데운다. | →min_heart; →kil_heat_gate |
| min_forgotten_rail | **잊힌 레일 구간** | transit | 굳은 핏줄 | 권양기 수리로 깨어나는 직통 레일 — 심부에서 입구 캠프까지 한달음의 내부 루프. | →min_camp; →min_vein_camp |

### 잠들지 않는 숲 (`for`) — 30방
- **정체성**: 해가 닿은 적 없는 협곡 바닥의 숲 — 빛을 재배하는 사람들의 땅. 추격과 매복의 지역, 벽달리기가 연다.
- **속성**: 어둠 / **팔레트**: 짙은 남색·먹색 + 램프의 호박색 원 + 반딧불의 점묘 / **음악**: 낮은 현악 드론 + 벌레 소리 — 램프 반경 밖에서는 음이 한 겹 얇아진다
- **고유 적**: 빛꺼림 — 램프 반경 밖에서만 움직이는 그림자 짐승. 빛 안으로는 절대 들어오지 못한다.
- **지역 마법**: 그림자 손(가칭) — 어둠에서 손이 뻗어 적을 붙잡아 세운다 — 추격자를 끊는 결정적 지역 마법, 어둠 장막(가칭) — 짧게 주위 빛을 삼켜 적의 시선을 끊는다
- **보스 열쇠(로컬 스토리)**: 램프 마을의 빛 밭에서 씨앗 도둑 소동을 해결하다 보면 '씨앗 램프'(휴대 광원의 심지)를 맡게 된다 — 그 빛이 없으면 심부의 어둠은 걷히지 않는다.
- **클리어 후 변화**: 등불나무가 개화해 숲 전체의 어둠이 한 단계 옅어지고, 나무 꼭대기에서 마을로 내려가는 빛의 지름길이 열린다.
- 루프: 등불나무 개화 후: 나무 꼭대기→램프 마을 직통 하강로 (보스 보상 지름길)
- 루프: 반딧불 틈→반딧불 성소(숨은 거점) 뒷길
- 루프: 서쪽 뿌리 비탈: 광산 붕괴 지점에서 떨어져 들어오는 뒷문(월드 루프 ②)

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| for_mouth_north | **숲 어귀** | transit | 숲 어귀 | 협곡 바닥이 검은 우듬지에 삼켜지는 곳. 마지막 햇빛의 기억이 여기서 끝난다. | →cyn_floor_south; →for_canopy_path |
| for_canopy_path | **검은 우듬지 길** | field | 숲 어귀 | 나무들이 지붕처럼 얽힌 길. 이끼의 인광이 유일한 이정표다. | →for_mouth_north; →for_lamp_road |
| for_lamp_road | **등불 가로수길** | field | 숲 어귀 | 마을 사람들이 세운 고정 램프의 가로수길 — 램프 반경 기믹의 도입. 빛 안은 안전, 밖은 그들의 영역. | →for_canopy_path; →for_village |
| for_village | **램프 마을** `bench,map,shop` | town | 램프 마을 | 빛을 재배해 사는 사람들의 마을. 처마마다 등롱이 열매처럼 걸려 있다 — 지역 지도 입수처. | →for_lamp_road; →for_village_farm; →for_moth_inn; →for_dusk_gate; →for_lantern_top(상태:등불나무 개화) |
| for_village_farm | **빛 밭** | field | 램프 마을 | 빛나는 이끼와 등롱 열매를 기르는 밭. 요즘 씨앗이 자꾸 사라진다 — 로컬 스토리의 시작. | →for_village; →for_glow_cellar(비밀) |
| for_glow_cellar | **씨앗광 창고** | secret | 램프 마을 | 빛 씨앗을 재우는 지하 창고. 도둑의 흔적과 함께 마력석 꾸러미가 굴러 나온다. | →for_village_farm |
| for_moth_inn | **나방등 여관** `warm` | town | 램프 마을 | 큰 나방 날개 무늬 간판의 여관. 난로가와 소문, 그리고 어둠을 무서워하지 않는 법. | →for_village |
| for_dusk_gate | **어스름 문** | transit | 어스름 층 | 마을의 마지막 고정 램프 — 여기부터는 들고 가는 빛이 전부다. | →for_village; →for_dusk_1 |
| for_dusk_1 | **어스름 숲** | field | 어스름 층 | 휴대 램프 반경을 익히는 응용 구간. 빛의 가장자리를 따라 빛꺼림들이 따라 걷는다. | →for_dusk_gate; →for_dusk_2; →for_dusk_shrine(비밀) |
| for_dusk_shrine | **반딧불 사당** | secret | 어스름 층 | 반딧불이 모여드는 작은 사당 — 숲 사람들의 옛 신앙. 도감과 기록의 보상. | →for_dusk_1 |
| for_dusk_2 | **그림자 웅덩이** | field | 어스름 층 | 빛이 고이지 않는 움푹한 땅. 램프를 어디에 내려놓는가가 전투의 수읽기가 된다. | →for_dusk_1; →for_dusk_3; →for_west_roots |
| for_west_roots | **서쪽 뿌리 비탈** | transit | 어스름 층 | 광산의 붕괴 지점에서 떨어져 들어오는 뒷문 비탈. 위로는 벽을 달려야 되돌아갈 수 있다. | →for_dusk_2; →min_lower_breach(벽달리기) |
| for_dusk_3 | **갈림 덤불** | field | 어스름 층 | 길이 세 갈래로 찢어지는 덤불. 잘못 든 길이 늘 조금 더 어둡다. | →for_dusk_2; →for_black_gate; →for_hollow_log(비밀) |
| for_hollow_log | **속 빈 큰나무** `warm` | secret | 어스름 층 | 쓰러진 거목의 속 — 누군가 살다 간 흔적. 등잔·담요·아이의 그림이 남아 있다. | →for_dusk_3 |
| for_black_gate | **칠흑 문** | transit | 칠흑 층 | '빛 없이 들어간 자, 돌아오지 않았다' — 경고판 너머로 완전한 어둠이 시작된다. | →for_dusk_3; →for_black_1 |
| for_black_1 | **칠흑 층** | field | 칠흑 층 | 램프 반경이 세계의 전부가 되는 어둠. 매복 기믹의 본격 구간. | →for_black_gate; →for_ambush_king |
| for_ambush_king | **그림자 목구멍** | miniboss | 칠흑 층 | 미니보스 — 어둠 그 자체처럼 웅크린 큰 빛꺼림. 램프를 빼앗으려 든다. | →for_black_1; →for_black_2 |
| for_black_2 | **숨죽인 골짜기** | field | 칠흑 층 | 추격 응용 구간 — 빛이 꺼지면 달려야 한다. 골짜기 끝의 램프까지, 숨 한 번의 거리. | →for_ambush_king; →for_black_3; →for_firefly_gate(비밀) |
| for_firefly_gate | **반딧불 틈** | secret | 칠흑 층 | 바위 틈으로 반딧불이 강물처럼 흘러든다 — 따라가면 성소가 나온다. | →for_black_2; →for_firefly_sanctum |
| for_firefly_sanctum | **반딧불 성소** `bench,warm` | bench | 칠흑 층 | 숨은 거점 — 수천의 반딧불이 별하늘을 대신하는 방. 숲에서 가장 밝고 가장 조용한 곳. | →for_firefly_gate |
| for_black_3 | **눈알 덤불** | field | 칠흑 층 | 어둠 속에서 눈들이 먼저 보이는 덤불 — 매복과 추격이 조합되는 구간. | →for_black_2; →for_deep_gate; →for_chase_run |
| for_chase_run | **달아나는 길** | challenge | 칠흑 층 | 격리된 추격 챌린지 — 꺼져가는 램프 하나로 끝까지. 완주하면 숲 사람들의 오래된 상. | →for_black_3 |
| for_deep_gate | **심부 문** | transit | 심부 | 씨앗 램프의 빛에만 반응해 열리는 뿌리의 문 — 벽달리기로 뿌리 벽을 달려 내려간다. | →for_black_3; →for_deep_1(벽달리기) |
| for_deep_1 | **뿌리 심부** | field | 심부 | 등불나무의 뿌리들이 대성당 기둥처럼 서 있는 심부. 어둠이 여기서는 오히려 고요하다. | →for_deep_gate; →for_deep_2; →for_deep_east |
| for_deep_2 | **마른 수맥 굴** | field | 심부 | 물이 말라붙은 옛 수맥 — 벽의 물자국이 옛 수위를 증언한다. | →for_deep_1; →for_lantern_approach; →for_moss_vault(비밀) |
| for_moss_vault | **이끼 금고** | secret | 심부 | 이끼가 삼킨 석실 — 마도서 한 권이 그냥 꽂혀 있다. 순수한 탐험의 보상. | →for_deep_2 |
| for_deep_east | **지하 수맥 어귀** | transit | 심부 | 물소리가 다시 들리는 동쪽 끝 — 물에 잠긴 길이 어딘가의 성소로 이어진다. | →for_deep_1; →sun_aquifer_west(물잠) |
| for_lantern_approach | **등불나무 앞뜰** `bench` | bench | 심부 | 보스 앞 거점 — 거대한 등불나무의 밑동 앞. 꺼진 등롱 열매들이 조용히 매달려 있다. | →for_deep_2; →for_lantern_boss(열쇠:씨앗 램프) |
| for_lantern_boss | **등불나무 밑동** | boss | 심부 | 보스전 — 빛을 삼키는 것. 씨앗 램프가 만드는 안전지대를 옮겨가며 싸우는 램프 기믹의 졸업시험. | →for_lantern_approach; →for_lantern_top(상태:등불나무 개화) |
| for_lantern_top | **개화한 등불나무** `warm` | event | 심부 | 보스 후 — 나무가 켜지고 숲에 첫 '낮'이 온다. 꼭대기에서 마을까지 빛의 길이 열린다. | →for_lantern_boss; →for_village[일방] |

### 거울의 도시 (`mir`) — 32방
- **정체성**: 태양빛을 거울 배관으로 골목마다 배달하는 사막 도시 — 빛 퍼즐의 지역. 얼음 발판이 연다. 로컬 스토리: '태양로가 흐려진다'.
- **속성**: 태양 / **팔레트**: 모래 백금색 + 거울의 은빛 섬광 + 그림자 골목의 청회색 / **음악**: 햇빛처럼 쨍한 현악 + 거울이 꺾일 때마다 반짝이는 타악
- **고유 적**: 볕도마뱀 — 빛을 받으면 수정처럼 굳어 무적이 되고, 그림자 속에서만 부드러워지는 역설의 적.
- **지역 마법**: 빛의 창(가칭) — 모아 쏘는 태양빛의 창 — 어둠 속성 적에게 결정적, 거울에 반사되어 꺾인다
- **보스 열쇠(로컬 스토리)**: 그림자 골목 아이들의 심부름과 빛 관리국의 배관 수리를 돕다 보면 '태양로 인장'을 맡게 된다 — 흐려진 태양로의 대문은 인장 없이 열리지 않는다.
- **클리어 후 변화**: 태양로가 다시 타오르며 그림자 골목에 사상 처음 빛이 들고, 광장과 태양로를 잇는 직통 승강기가 개방된다.
- 루프: 거울 대로에서 그림자 골목으로 일방 낙하 → 뒷계단(벽달리기)으로 상층 시가 복귀 (§5.5의 내부 루프)
- 루프: 보스 후 직통 승강기: 태양로 심장↔중앙 광장
- 루프: 지하 수로 수문 개방 → 광산 서단으로 이어지는 외부 루프(월드 루프 ⑤ 보조)

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| mir_gate_east | **사막 관문** | transit | 관문 | 가도의 끝, 모래바람을 막는 이중문. 거울 각도 기믹이 처음 손에 잡히는 곳. | →roa_desert_west(얼음 발판); →mir_gate_plaza |
| mir_gate_plaza | **관문 안뜰** | field | 관문 | 첫 거울들이 세워진 안뜰 — 빛을 꺾어 문을 여는 도입 퍼즐. | →mir_gate_east; →mir_sun_road |
| mir_sun_road | **태양 대로** | field | 관문 | 빛 배관이 처음 머리 위로 지나가는 큰길. 배달되는 햇빛이 골목마다 쏟아진다. | →mir_gate_plaza; →mir_plaza; →mir_dune_lookout(비밀) |
| mir_dune_lookout | **모래 전망대** `warm` | secret | 관문 | 사구 너머 지평선까지 보이는 낡은 전망대. 노을 시간엔 도시 전체가 금빛이 된다. | →mir_sun_road |
| mir_plaza | **중앙 광장** `bench,map,shop` | town | 중앙 | 거점A이자 마을 — 분수 대신 빛이 솟는 광장. 지역 지도와 소문, 시장이 모인다. | →mir_sun_road; →mir_guild_row; →mir_moon_site; →mir_mirror_ave; →mir_lower_stair; →mir_lift_shaft(상태:직통 승강기) |
| mir_guild_row | **세공 거리** `shop` | town | 중앙 | 거울 세공사들의 거리. 진열창마다 다른 각도의 하늘이 걸려 있다. | →mir_plaza; →mir_atelier |
| mir_atelier | **거울 공방** | event | 중앙 | 수석 세공사의 공방 — '태양로가 흐려진다'는 걱정이 처음 흘러나오는 곳. | →mir_guild_row |
| mir_moon_site | **그늘진 터** `moon_site` | event | 중앙 | 광장 뒤 늘 그늘인 공터 — 보름밤이면 달빛 장이 선다는 소문. | →mir_plaza; →mkt_gate_mir(상태:보름밤) |
| mir_mirror_ave | **거울 대로** | field | 중앙 | 빛 경로 퍼즐의 응용 구간 — 대로의 거울을 돌려 배관에 빛을 채우면 길이 열린다. | →mir_plaza; →mir_bureau_gate; →mir_high_street(얼음 발판); →mir_shadow_alley[일방] |
| mir_bureau_gate | **관리국 앞** | field | 관리국 | 빛 관리국의 육중한 정문. 배관 압력계가 전부 바닥을 가리키고 있다. | →mir_mirror_ave; →mir_bureau |
| mir_bureau | **빛 관리국** | miniboss | 관리국 | 미니보스 — 폭주한 거울 골렘. 도시의 빛 배관을 관리하던 것이 빛에 굶주려 뒤틀렸다. | →mir_bureau_gate; →mir_bureau_vault |
| mir_bureau_vault | **관리국 금고** | secret | 관리국 | 배관 도면과 옛 관리국의 기록 — 태양로로 가는 길과 인장의 존재가 여기서 드러난다. | →mir_bureau |
| mir_high_street | **상층 시가** | field | 상층 | 부유한 지붕들의 거리 — 얼음 발판을 허공에 놓아 오르는 수직 시가지. | →mir_mirror_ave(얼음 발판); →mir_pipe_cross; →mir_spire_base; →mir_back_stairs |
| mir_pipe_cross | **빛 배관 교차로** | field | 상층 | 도시의 모든 빛이 갈라지는 교차로 — 거울 각도와 얼음 발판이 조합되는 최고 난도 퍼즐. | →mir_high_street; →mir_furnace_upper; →mir_pipe_maint(비밀) |
| mir_pipe_maint | **배관 정비굴** | secret | 상층 | 정비공만 알던 배관 속 지름길 — 마력석과 오래된 정비 일지. | →mir_pipe_cross |
| mir_spire_base | **거울탑 기단** | field | 상층 | 도시에서 가장 높은 탑의 발치. 오르는 자를 위한 격언이 새겨져 있다. | →mir_high_street; →mir_spire_climb |
| mir_spire_climb | **거울탑 오르기** | challenge | 상층 | 격리된 정밀 플랫포밍 챌린지 — 거울 반사 타이밍에 맞춰 얼음 발판을 놓으며 오른다. | →mir_spire_base; →mir_spire_top |
| mir_spire_top | **거울탑 첨탑** `warm` | secret | 상층 | 도시 전체와 사막의 끝이 보이는 꼭대기 — 완주자만의 전망과 굵은 마력석. | →mir_spire_climb |
| mir_furnace_upper | **태양로 상부** | field | 태양로 | 도시의 심장인 거대한 빛 화로의 상부 — 배관이 전부 이곳으로 모인다. | →mir_pipe_cross; →mir_furnace_ante |
| mir_furnace_ante | **대문 앞 쉼터** `bench` | bench | 태양로 | 보스 앞 거점 — 태양로 인부들의 쉼터. 잠긴 대문 너머에서 약해진 빛이 새어 나온다. | →mir_furnace_upper; →mir_furnace_heart(열쇠:태양로 인장) |
| mir_furnace_heart | **태양로의 심장** | boss | 태양로 | 보스전 — 태양로의 심장. 보스룸의 거울로 빛을 꺾어 약점을 노출시키는 거울 기믹의 졸업시험. | →mir_furnace_ante; →mir_lift_shaft(상태:직통 승강기) |
| mir_lift_shaft | **직통 승강기** | transit | 태양로 | 보스 후 개방 — 태양로와 광장을 잇는 빛의 승강기. 도시가 다시 순환하기 시작한다. | →mir_furnace_heart; →mir_plaza |
| mir_lower_stair | **하층 계단** | transit | 그림자 골목 | 빛 배관이 닿지 않는 아래로 내려가는 계단 — 한 층마다 그늘이 짙어진다. | →mir_plaza; →mir_shadow_alley |
| mir_shadow_alley | **그림자 골목** | field | 그림자 골목 | 빛 배달이 끊긴 하층 — 도시의 그늘에 사는 사람들. 이 지역 정서의 심장. | →mir_lower_stair; →mir_lamp_cellar(비밀); →mir_shadow_court; →mir_south_gate |
| mir_lamp_cellar | **등잔 지하실** `bench,warm` | bench | 그림자 골목 | 거점B(숨은) — 골목 사람들이 등잔을 모아 만든 비밀 쉼터. 도시에서 가장 따뜻한 그늘. | →mir_shadow_alley |
| mir_shadow_court | **그림자 안마당** | field | 그림자 골목 | 골목 아이들의 놀이터 — 벽의 분필 낙서가 태양로로 가는 실마리를 그리고 있다. | →mir_shadow_alley; →mir_back_stairs; →mir_waterway_gate; →mir_urchin_den(비밀) |
| mir_urchin_den | **아이들의 은신처** `warm` | secret | 그림자 골목 | 빛을 못 받는 아이들의 아지트. 이들의 심부름 사슬이 보스 열쇠(인장)로 이어진다. | →mir_shadow_court |
| mir_back_stairs | **뒷계단** | transit | 그림자 골목 | 골목에서 상층 시가로 벽을 타고 오르는 지름길 — 아래에서 위로 여는 내부 루프. | →mir_shadow_court; →mir_high_street(벽달리기) |
| mir_south_gate | **남문 하부** | transit | 그림자 골목 | 남쪽 절벽 가도로 나가는 하층의 잠긴 문 — 안쪽에서만 빗장이 열린다. 가마 마을의 도기가 이 문으로 들어오던 시절이 있었다. | →mir_shadow_alley; →roa_south_high(상태:남문 개방) |
| mir_waterway_gate | **수로 수문** | event | 지하 수로 | 지하 수로의 잠긴 수문 — 관리국 도면의 열쇠로 열면 광산 방면 물길이 이어진다. | →mir_shadow_court; →mir_waterway_1(상태:수문 개방) |
| mir_waterway_1 | **지하 수로** | field | 지하 수로 | 도시 밑을 흐르는 어두운 물길 — 볕도마뱀도 여기서는 부드럽다. | →mir_waterway_gate; →mir_waterway_east |
| mir_waterway_east | **수로 동단** | transit | 지하 수로 | 물길의 동쪽 끝 — 벽 너머는 거인의 광산 서단이다. 두 지역을 잇는 뒷길. | →mir_waterway_1; →min_west_end |

### 번개 목장 (`lig`) — 28방
- **정체성**: 폭풍의 번개를 수확해 병에 담는 고원 목장 — 고난도 액션의 지역. 활공가 연다.
- **속성**: 번개 / **팔레트**: 폭풍 회보라 + 마른 풀의 금색 + 번개의 백청색 섬광 / **음악**: 천둥의 간격이 박자가 되는 타악 중심 — 폭풍의 눈에 가까울수록 빨라진다
- **고유 적**: 피뢰짐승 — 등의 피뢰침으로 낙뢰를 유도해 주변을 감전시키는 놈. 낙뢰 리듬을 강제로 바꾼다.
- **지역 마법**: 낙뢰(가칭) — 하늘에서 번개를 내리꽂는다 — 웹 프로토타입에서 검증한 광역 결정타. 금속 지형에 연쇄한다
- **보스 열쇠(로컬 스토리)**: 폭풍에 흩어진 뇌우양(雷雨羊) 떼를 몰아다 주면 목장주가 폭풍의 눈 목책을 열어 준다 — '들어가는 건 네 사정이고, 나오는 건 네 실력이다.'
- **클리어 후 변화**: 검은 폭풍이 잠잠해져 목장에 몇 년 만의 볕이 들고, 폭풍 위 하늘 기류(부유군도행)가 열린다.
- 루프: 자기 레일 협곡의 그라인드 레일이 능선과 관측소를 잇는 고속 순환로
- 루프: 보스 후 폭풍 위 하늘이 열리며 시계탑 기류와 함께 부유군도 이중 진입로를 이룬다(월드 루프 상층)

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| lig_west_gate | **고원 오르막 문** | transit | 초지 | 협곡 동쪽 벼랑에서 고원으로 오르는 바람길 — 활공 없이는 기류를 거슬러 오를 수 없다. | →cyn_east_rim(활공); →lig_meadow_1 |
| lig_meadow_1 | **바람 초지** | field | 초지 | 허리까지 오는 풀이 파도치는 초지. 멀리 피뢰탑들이 바늘처럼 꽂혀 있다. | →lig_west_gate; →lig_ranch_road; →lig_cliff_view(비밀) |
| lig_cliff_view | **벼랑 풍향계** `warm` | secret | 초지 | 낡은 풍향계가 도는 벼랑 끝 — 협곡과 학교가 한눈에 내려다보이는 숨은 전망. | →lig_meadow_1 |
| lig_ranch_road | **목장 길** | field | 초지 | 울타리를 따라 걷는 길. 뇌우양들이 정전기 오른 털을 부풀리고 있다. | →lig_meadow_1; →lig_village |
| lig_village | **목장 마을** `bench,map,shop` | town | 마을 | 피뢰침 지붕의 마을 — 지역 지도 입수처. 번개병 파는 가게와 무뚝뚝한 목장주. | →lig_ranch_road; →lig_bottle_barn; →lig_south_trail; →lig_pass_road; →lig_pylon_gate |
| lig_bottle_barn | **번개병 헛간** `shop` | event | 마을 | 수확한 번개가 병째로 진열된 헛간 — 벽 전체가 은은히 빛난다. 번개 수확의 로어. | →lig_village |
| lig_south_trail | **남쪽 벼랑길** | transit | 마을 | 조수 도시 쪽으로 굽이치며 내려가는 벼랑길 — 바닷바람과 고원 바람이 만나는 곳. | →lig_village; →tid_cliff_north(활공) |
| lig_pass_road | **고갯길** | transit | 마을 | 동쪽 설곡으로 넘어가는 고갯길 — 걸을수록 공기가 차가워지고 조용해진다. | →lig_village; →lig_pass_east |
| lig_pass_east | **언 바람 고개** | transit | 마을 | 고개 정상 — 여기서부터 소리를 낮추라는 수화 그림 표지판이 서 있다. | →lig_pass_road; →bel_pass_west |
| lig_pylon_gate | **피뢰탑 초입** | field | 피뢰탑 능선 | 첫 피뢰탑 아래 — 낙뢰가 떨어지는 박자를 읽는 법을 배우는 도입 구간. | →lig_village; →lig_pylon_1 |
| lig_pylon_1 | **피뢰탑 능선** | field | 피뢰탑 능선 | 능선을 따라 피뢰탑이 줄지은 구간 — 낙뢰 리듬에 발을 맞춰 달린다. | →lig_pylon_gate; →lig_pylon_2 |
| lig_pylon_2 | **흔들리는 능선** | field | 피뢰탑 능선 | 바람에 출렁이는 현수 발판 위에서 낙뢰까지 피하는 응용 구간. | →lig_pylon_1; →lig_rail_gate; →lig_pylon_shrine(비밀) |
| lig_pylon_shrine | **새까맣게 탄 사당** | secret | 피뢰탑 능선 | 수백 번 벼락 맞은 옛 사당 — 그을린 벽 안쪽에 굵은 마력석이 녹아 붙어 있다. | →lig_pylon_2 |
| lig_rail_gate | **자기 레일 승강장** | field | 자기 레일 협곡 | 번개의 자기력으로 떠 있는 레일의 출발점 — 이 지역 이동 트릭의 심장. | →lig_pylon_2; →lig_rail_1; →lig_grind_gym |
| lig_grind_gym | **레일 질주 시험장** | challenge | 자기 레일 협곡 | 격리된 그라인드 챌린지 — 목동들의 통과의례 코스. 완주 기록이 벽에 새겨진다. | →lig_rail_gate |
| lig_rail_1 | **자기 레일 협곡** | field | 자기 레일 협곡 | 협곡 사이를 그라인드로 건너는 구간 — 레일 위에서도 낙뢰 리듬은 계속된다. | →lig_rail_gate; →lig_rail_2 |
| lig_rail_2 | **레일 교차 협곡** | field | 자기 레일 협곡 | 레일이 얽히고 갈라지는 응용 구간 — 갈아타는 순간이 곧 회피 타이밍이다. | →lig_rail_1; →lig_rail_junction; →lig_herd_cave(비밀) |
| lig_herd_cave | **피뢰짐승 둥지** | secret | 자기 레일 협곡 | 피뢰짐승들이 모여 사는 벼랑 굴 — 도감과 번개병 재료의 숨은 산지. | →lig_rail_2 |
| lig_rail_junction | **녹슨 분기기** | field | 자기 레일 협곡 | 레일이 관측소와 폭풍 방면으로 갈라지는 분기점 — 레버가 굳어 절반만 움직인다. | →lig_rail_2; →lig_storm_fence; →lig_obs_approach |
| lig_storm_fence | **뇌우양 우두머리의 우리** | miniboss | 자기 레일 협곡 | 미니보스 — 폭풍에 미쳐 우리를 부순 뇌우양 우두머리. 몰이가 아니라 정면 승부를 원한다. | →lig_rail_junction |
| lig_obs_approach | **관측소 오르막** | field | 폭풍 관측소 | 바람이 가장 사나운 마지막 오르막 — 관측 깃발들이 전부 한 방향으로 찢겨 있다. | →lig_rail_junction; →lig_observatory |
| lig_observatory | **폭풍 관측소** `bench` | bench | 폭풍 관측소 | 거점 — 폭풍을 기록해 온 관측사들의 탑. 벽면 가득 폭풍의 눈 스케치가 붙어 있다. | →lig_obs_approach; →lig_eye_gate; →lig_obs_roof(비밀) |
| lig_obs_roof | **관측소 지붕** `warm` | secret | 폭풍 관측소 | 피뢰침 사이에 앉아 폭풍을 정면으로 바라보는 자리 — 관측사들의 몰래 쉼터. | →lig_observatory |
| lig_eye_gate | **폭풍 앞 목책** | field | 폭풍의 눈 | 목장주의 허가 없이는 열리지 않는 마지막 목책 — 너머는 검은 폭풍의 영역. | →lig_observatory; →lig_eye_run(열쇠:목장주의 허가) |
| lig_eye_run | **폭풍 속 질주** | field | 폭풍의 눈 | 낙뢰 리듬과 그라인드가 조합되는 최종 구간 — 폭풍의 눈까지, 번개 사이를 꿰어 달린다. | →lig_eye_gate; →lig_eye_ante |
| lig_eye_ante | **폭풍의 눈 앞** `bench` | bench | 폭풍의 눈 | 보스 앞 거점 — 기이하게 고요한 폭풍의 가장자리. 머리카락이 곤두선다. | →lig_eye_run; →lig_storm_eye |
| lig_storm_eye | **검은 폭풍의 눈** | boss | 폭풍의 눈 | 보스전 — 검은 폭풍의 눈. 낙뢰가 떨어지는 박자가 곧 공격 윈도우인 낙뢰 리듬의 졸업시험. | →lig_eye_ante; →lig_storm_top(상태:폭풍 잠잠) |
| lig_storm_top | **폭풍 위 하늘** | transit | 폭풍의 눈 | 보스 후 — 폭풍이 걷힌 자리에 상승기류의 기둥이 남는다. 부유군도로 오르는 두 번째 문. | →lig_storm_eye; →sky_storm_updraft(비행) |

### 종의 계곡 (`bel`) — 24방
- **정체성**: 소리를 내면 눈사태가 오는 설곡 — 수화(手話)로 말하는 마을. 침묵의 지역. ※컷 후보(여유 시 제작).
- **속성**: 얼음 / **팔레트**: 눈의 청백색 + 침엽수의 먹녹색 + 언 종탑의 창백한 은색 / **음악**: 거의 무음 — 눈 밟는 소리와 멀리서 우는 바람뿐. 마을에서만 아주 작은 오르골
- **고유 적**: 눈밑의 것 — 소리에 반응해 눈 밑에서 솟구치는 놈. 조용히 걸으면 지나칠 수 있다.
- **지역 마법**: 얼음 묶기(가칭) — 적의 발을 얼려 그 자리에 묶는다 — 소리 없이 상황을 정지시키는 지역 마법
- **보스 열쇠(로컬 스토리)**: 수화 마을 아이들에게 수화를 배우고, 눈 속에서 잃어버린 종지기의 장갑을 되찾아 주면 — 언 종탑의 문이 조용히 열린다.
- **클리어 후 변화**: 종을 울리든(눈사태로 옛길이 무너지고 새 길이 열림) 침묵을 지키든(계곡이 그대로 남음) — 선택이 지형에 남는다.
- 루프: 언 갱도의 얼음을 깨면 광산 상부로 떨어지는 지름길 개통(월드 루프 ④의 닫힘)
- 루프: 흰 숲을 관통하는 사냥꾼의 우회로 — 설원을 건너뛰는 조용한 길

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| bel_pass_west | **서쪽 고개** | transit | 고개 | 목장의 소음이 끊기고 눈이 시작되는 고개 — 첫 소음 게이지 표지가 서 있다. | →lig_pass_east; →bel_snow_road |
| bel_snow_road | **눈길** | field | 고개 | 소음 게이지 도입 구간 — 달리면 게이지가 차고, 차면 눈처마가 운다. | →bel_pass_west; →bel_sign_village; →bel_watch_cairn(비밀) |
| bel_watch_cairn | **돌무더기 망대** `warm` | secret | 고개 | 옛 파수꾼의 돌탑 — 계곡 전체가 내려다보이는 숨은 자리. 언 망원경이 남아 있다. | →bel_snow_road |
| bel_sign_village | **수화 마을** `bench,map,shop` | town | 마을 | 모두가 손으로 말하는 마을 — 지역 지도 입수처. 간판도 그림, 인사도 손짓. | →bel_snow_road; →bel_mute_inn; →bel_sign_school; →bel_snowfield_1 |
| bel_mute_inn | **고요한 여관** `warm` | town | 마을 | 말소리 대신 난롯불 소리만 있는 여관 — 계곡에서 유일하게 '따뜻한 소리'가 허락된 곳. | →bel_sign_village |
| bel_sign_school | **수화 배움방** | event | 마을 | 아이들에게 수화를 배우는 방 — 로컬 스토리의 입구. 손짓 하나에 웃음이 터진다. | →bel_sign_village |
| bel_snowfield_1 | **첫 설원** | field | 설원 | 정적 걷기의 응용 구간 — 발자국 깊이가 곧 소음이다. 뛰고 싶은 만큼 위험해진다. | →bel_sign_village; →bel_snowfield_2; →bel_white_maze |
| bel_snowfield_2 | **숨죽인 설원** | miniboss | 설원 | 미니보스 — 눈밑의 것 어미. 설원 한가운데서 소리를 미끼로 낚아 올려야 한다. | →bel_snowfield_1; →bel_avalanche_slope |
| bel_avalanche_slope | **눈사태 비탈** | field | 설원 | 게이지가 가득 차면 실제로 눈사태가 쏟아지는 비탈 — 소음 관리의 조합 시험. | →bel_snowfield_2; →bel_cornice_1; →bel_frost_spring(비밀) |
| bel_frost_spring | **얼지 않는 샘** `warm` | secret | 설원 | 영하의 계곡에서 유일하게 얼지 않는 샘 — 김이 오르는 물가에 오래된 공물이 잠겨 있다. | →bel_avalanche_slope |
| bel_white_maze | **흰 숲** | field | 설원 | 눈을 뒤집어쓴 침엽수의 미로 — 모든 나무가 똑같이 하얗다. 발자국이 유일한 지도. | →bel_snowfield_1; →bel_hunter_hut; →bel_echo_vale |
| bel_hunter_hut | **사냥꾼 오두막** `bench` | bench | 설원 | 두 번째 거점 — 말 없는 사냥꾼의 오두막. 벽의 가죽 지도에 계곡의 지름길들이 바늘로 표시돼 있다. | →bel_white_maze |
| bel_echo_vale | **메아리 골** | field | 언 갱도 | 소리가 여덟 배로 돌아오는 골짜기 — 이 지역에서 가장 위험한 지형. 걷기조차 시험이 된다. | →bel_white_maze; →bel_adit_gate; →bel_deep_drift(비밀) |
| bel_deep_drift | **깊은 눈더미** | secret | 언 갱도 | 수십 년 치 눈이 쌓인 구덩이 — 파고들면 옛 상단의 얼어붙은 짐수레와 마력석. | →bel_echo_vale |
| bel_adit_gate | **언 갱도 어귀** | field | 언 갱도 | 광산으로 통하던 옛 갱도의 입구 — 두꺼운 얼음이 문을 봉하고 있다. | →bel_echo_vale; →bel_adit_south(기초:불) |
| bel_adit_south | **언 갱도** | transit | 언 갱도 | 얼음을 깬 갱도 — 아래로 광산 상부까지 미끄러져 내려가는 지름길이 된다. | →bel_adit_gate; →min_frozen_adit[일방] |
| bel_bell_road | **종탑 가는 길** | field | 종탑 | 언 종탑으로 오르는 마지막 길 — 눈처마가 머리 위로 처마처럼 이어진다. | →bel_cornice_2; →bel_bell_ante; →bel_bell_challenge |
| bel_cornice_1 | **눈처마 벼랑** | field | 종탑 | 발밑이 전부 눈처마인 벼랑 — 무게와 소리, 둘 다 관리해야 하는 조합 구간. | →bel_avalanche_slope; →bel_cornice_2; →bel_ice_cave(비밀) |
| bel_ice_cave | **얼음 굴** | secret | 종탑 | 벼랑 아래 숨은 푸른 얼음 굴 — 얼음 속에 마력석이 별처럼 박혀 있다. | →bel_cornice_1 |
| bel_cornice_2 | **처마 끝 능선** | field | 종탑 | 종탑이 처음 온전히 보이는 능선 — 언 종이 바람에도 울지 않고 매달려 있다. | →bel_cornice_1; →bel_bell_road |
| bel_bell_challenge | **침묵 질주** | challenge | 종탑 | 격리된 챌린지 — 소음 게이지 0으로 완주하는 빙판 코스. 계곡 사냥꾼들의 전설이 걸려 있다. | →bel_bell_road |
| bel_bell_ante | **종탑 앞 제단** `bench` | bench | 종탑 | 보스 앞 거점 — 종지기들이 대대로 기도하던 눈 덮인 제단. | →bel_bell_road; →bel_bell_tower(열쇠:종지기의 장갑) |
| bel_bell_tower | **언 종탑** | boss | 종탑 | 보스전 — 얼어붙은 종탑의 주인. 완전한 침묵 속의 전투, 그리고 마지막에 종을 울릴 것인가의 선택. | →bel_bell_ante; →bel_bell_top(상태:종탑의 결말) |
| bel_bell_top | **종탑 꼭대기** `warm` | event | 종탑 | 보스 후 — 선택의 결과가 계곡에 내려앉는 것을 지켜보는 자리. 울렸다면 눈사태의 새 길이, 침묵했다면 그대로의 설경이. | →bel_bell_tower |

### 바람이 시작되는 곳 (`sky`) — 22방
- **정체성**: 세계의 바람이 시작되는 부유 군도 — 최후반 지역. 비행이 열고, 시계탑과 폭풍 두 개의 하늘길이 닿는다.
- **속성**: 바람 심화 / **팔레트**: 새벽하늘의 담청·연보라 + 구름의 흰색 + 섬 밑면의 젖은 바위색 / **음악**: 높은 목관과 성가풍 허밍 — 바람이 화음을 이룬다
- **고유 적**: 구름송곳 — 구름 속에 숨어 있다가 기류를 타고 내리꽂는 급습형. 그림자가 유일한 예고다.
- **지역 마법**: 회오리(가칭) — 그 자리에 상승기류 기둥을 세운다 — 이동과 전투(띄우기)를 겸하는 바람 심화 마법
- **보스 열쇠(로컬 스토리)**: 순례자 야영지의 오래된 약속 — '가장 높은 곳은 바람이 허락한 자에게만'. 세 바람 사당에 예를 갖추면 마지막 기류가 열린다.
- **클리어 후 변화**: 시험을 마치면 군도의 기류가 온화해져 섬 사이 이동이 쉬워지고, 세계 전체가 보이는 자리가 열린다.
- 루프: 가장자리에서 떨어져도 기류가 받아 낮은 섬으로 — 낙사가 없는 대신 되돌이 기류로 복귀하는 순환
- 루프: 두 상륙섬(시계탑/폭풍)이 야영지에서 만나는 이중 진입 구조

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| sky_clock_updraft | **시계탑 기류 상륙섬** | transit | 상륙 | 학교 시계탑에서 오르는 기류가 닿는 첫 섬 — 아래로 학교가 장난감처럼 보인다. | →sch_clock_peak(비행); →sky_isle_gate_w |
| sky_storm_updraft | **폭풍 기류 상륙섬** | transit | 상륙 | 걷힌 폭풍 위로 오르는 기류가 닿는 동쪽 섬 — 아직 정전기가 풀잎에 남아 있다. | →lig_storm_top(비행); →sky_isle_gate_e |
| sky_isle_gate_w | **서쪽 바람 문** | field | 상륙 | 바람이 문설주처럼 갈라지는 길목 — 순례자들이 서쪽에서 오는 이를 맞는 곳. | →sky_clock_updraft; →sky_camp |
| sky_isle_gate_e | **동쪽 바람 문** | field | 상륙 | 폭풍 쪽 하늘길의 관문 — 기류 해협의 물살(바람살)을 처음 읽는 곳. | →sky_storm_updraft; →sky_current_1 |
| sky_camp | **순례자 야영지** `bench,map,shop` | town | 야영지 | 바람 순례자들의 천막과 깃발 — 군도의 안전지대이자 지도 입수처. 두 하늘길이 여기서 만난다. | →sky_isle_gate_w; →sky_current_1; →sky_drift_row; →sky_updraft_back |
| sky_current_1 | **첫 기류 해협** | field | 기류 해협 | 섬과 섬 사이의 바람 물길 — 기류 플랫포밍의 도입. 바람을 '읽고 올라타는' 법. | →sky_camp; →sky_isle_gate_e; →sky_current_2; →sky_wind_trial |
| sky_wind_trial | **기류 회랑** | challenge | 기류 해협 | 격리된 챌린지 — 좁은 바람길을 끊기지 않고 완주하는 순례자의 시험. | →sky_current_1 |
| sky_current_2 | **갈라지는 기류** | field | 기류 해협 | 응용 구간 — 두 갈래 기류가 얽히며 가짜 길을 만든다. 깃발의 방향이 힌트. | →sky_current_1; →sky_spiral; →sky_low_isle[일방] |
| sky_low_isle | **낮은 섬** | field | 군도 하부 | 군도의 밑바닥 섬 — 떨어진 자들이 모이는 곳. 잃어버린 짐과 오래된 낙서. | →sky_updraft_back; →sky_drop_old |
| sky_updraft_back | **되돌이 기류** | transit | 군도 하부 | 낮은 섬에서 야영지로 되돌아가는 상승 기둥 — 군도의 자비. 낙하가 벌이 되지 않는 이유. | →sky_low_isle; →sky_camp |
| sky_drop_old | **가장자리 벼랑** | transit | 군도 하부 | 군도의 남쪽 끝 — 구름 틈으로 폐교의 지붕이 보인다. 뛰어내리면 그리로 떨어진다. | →sky_low_isle; →old_roof[일방] |
| sky_drift_row | **떠도는 징검섬** | field | 바람 정원 | 자리를 바꾸는 작은 섬들의 줄 — 오늘의 길이 내일은 없다. 바람 정원으로 가는 길목. | →sky_camp; →sky_garden; →sky_hermit_isle(비밀) |
| sky_hermit_isle | **바람 은자의 섬** `teacher,warm` | secret | 바람 정원 | 구름에 가려진 작은 섬 — 바람의 고급 선생이 홀로 산다. 찾아오는 것 자체가 첫 수업. | →sky_drift_row |
| sky_garden | **바람 정원** `warm` | field | 바람 정원 | 풀이 눕는 방향으로 길을 읽는 정원 — 군도에서 가장 고요한 곳. 첫 바람 사당이 있다. | →sky_drift_row; →sky_shrine_gate |
| sky_shrine_gate | **사당 길목** | field | 바람 정원 | 세 바람 사당을 잇는 순례길의 갈림 — 예를 갖춘 흔적이 리본으로 남는다. | →sky_garden; →sky_wind_shrine |
| sky_wind_shrine | **바람 사당** | event | 바람 정원 | 바람 심화 마법이 잠든 사당 — 회오리을 여기서 얻는다. 사당지기는 없고 바람이 대답한다. | →sky_shrine_gate; →sky_spiral |
| sky_spiral | **나선 기류** | field | 높은 하늘 | 조합 구간 — 나선으로 감아 오르는 기류. 얼음 발판·활공·비행이 한 호흡에 엮인다. | →sky_current_2; →sky_wind_shrine; →sky_high_reach |
| sky_high_reach | **높은 물마루** | field | 높은 하늘 | 기류가 파도의 물마루처럼 부서지는 최고 난도 구간 — 구름송곳들의 사냥터. | →sky_spiral; →sky_ante; →sky_echo_isle(비밀) |
| sky_echo_isle | **메아리 섬** | secret | 높은 하늘 | 부르면 바람이 따라 부르는 섬 — 숨은 마력석 광맥과 순례자의 마지막 기록. | →sky_high_reach |
| sky_ante | **가장 높은 곳 앞** `bench` | bench | 정상 | 보스 앞 거점 — 구름 위, 바람마저 숨을 고르는 곳. 순례의 리본들이 여기서 끝난다. | →sky_high_reach; →sky_summit(열쇠:세 사당의 예) |
| sky_summit | **가장 높은 곳의 시험** | boss | 정상 | 보스전(가칭) — 바람 기믹의 최종 졸업시험. 서사는 미정, 기믹은 확정: 기류 위에서만 성립하는 전투. | →sky_ante; →sky_overlook(상태:바람의 인정) |
| sky_overlook | **세계가 보이는 곳** `warm` | event | 정상 | 보스 후 — 대협곡, 사막, 설곡, 바다까지 세계 전부가 한눈에 담기는 자리. 여정의 갈피가 접히는 방. | →sky_summit |

### 첫 학교(폐교) (`old`) — 10방
- **정체성**: 협곡 건너편 절벽의 폐교 — 입학 첫날부터 보이지만 갈 수 없는 랜드마크. 비행이 열어 주는 떡밥의 창고.
- **속성**: 없음 / **팔레트**: 바랜 회벽 + 담쟁이 초록 + 깨진 유리창의 무지개 반사 / **음악**: 현재 학교 테마의 느리고 조각난 변주 — 아는 멜로디가 반쯤 지워져 들린다
- **고유 적**: 먼지 학인 — 책과 먼지가 뭉쳐 학생의 형상을 흉내 내는 것. 공격보다는 따라 걷는다.
- **보스 열쇠(로컬 스토리)**: 보스 없음 — 질문의 장소. '누가, 왜 떠났는가'를 묻게 만드는 환경 서사만 놓는다(스토리 미확정 — 답은 두지 않음).
- **클리어 후 변화**: 탐사 후 기숙사 터의 난로에 다시 불이 붙는다 — 폐교에 남는 작은 온기 하나.
- 루프: 부유군도에서 지붕으로 떨어지는 뒷문(일방)과 정문(비행)의 이중 진입

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| old_front_gate | **무너진 정문** | transit | 바깥뜰 | 현판의 교명이 바람에 닳아 읽히지 않는다 — 협곡을 건너온 자만 서는 문 앞. | →cyn_east_rim(비행); →old_yard |
| old_yard | **잡초 안뜰** `map` | hub | 바깥뜰 | 수풀에 삼켜진 안뜰 — 조회대였던 돌단 위에 새들이 모여 산다. | →old_front_gate; →old_hall; →old_bell_base; →old_dorm_ruin |
| old_hall | **바랜 강당** | field | 교사(校舍) | 천장이 반쯤 무너진 강당 — 남은 현수막의 글자가 지금 학교의 표어와 미묘하게 다르다. | →old_yard; →old_classroom; →old_library_ruin(비밀); →old_exam_hall |
| old_classroom | **옛 교실** | event | 교사(校舍) | 칠판에 마지막 수업이 그대로 남은 교실 — 낯선 술식 표기. 분필은 아직 놓인 그대로다. | →old_hall |
| old_library_ruin | **무너진 서고** | secret | 교사(校舍) | 책장이 서로를 떠받치며 버티는 서고 — 지금 학교가 잊은 옛 마법의 마도서 한 권이 꽂혀 있다. | →old_hall |
| old_exam_hall | **옛 시험장** | event | 교사(校舍) | 지금과 전혀 다른 방식의 실기 시험장 흔적 — 바닥 문양이 절반쯤 남아 여전히 희미하게 반응한다. | →old_hall; →old_deep_cellar(비밀) |
| old_deep_cellar | **봉인된 지하** | secret | 교사(校舍) | 시험장 아래 잠긴 층계 — 문 너머는 조용하다. 열 수 있지만, 답은 없다(떡밥만 남긴다). | →old_exam_hall |
| old_bell_base | **낡은 종탑 기단** | field | 종탑 | 협곡 건너 지금 학교의 시계탑과 마주 보는 종탑 — 종은 사라지고 매듭만 남았다. | →old_yard; →old_roof |
| old_roof | **이끼 낀 지붕** | transit | 종탑 | 부유군도에서 떨어진 자가 처음 딛는 기와 — 위를 올려다보면 구름 틈의 섬들이 보인다. | →old_bell_base |
| old_dorm_ruin | **옛 기숙사 터** `bench,warm` | bench | 바깥뜰 | 거점 — 무너진 기숙사에서 유일하게 온전한 방 하나. 난로에 불을 붙이면 아직 따뜻해진다. | →old_yard |

### 온천 마을 (`spr`) — 6방
- **정체성**: 무장해제 중립지 — 전투가 없는 김 서린 완충 마을. 지친 모험가와 강자들이 무장을 풀고 어깨를 나란히 담그는 곳.
- **속성**: 없음 / **팔레트**: 유황의 유백색 김 + 등롱의 다홍 + 젖은 돌의 짙은 회색 / **음악**: 물소리와 풍경(風磬) — 템포가 반으로 느려지는 지역
- **고유 적**: 없음(중립지 — 적 배치 금지)
- **보스 열쇠(로컬 스토리)**: 보스 없음 — 규칙의 장소. '탕에서는 지팡이를 내려놓는다'가 이 마을의 유일한 법이다.
- **클리어 후 변화**: 의뢰 평판이 쌓이면 전세탕이 열리고, 탕에 몸을 담근 유명 인사들의 소문이 갱신된다.
- 루프: 학교 뒷숲과 조수 도시를 잇는 강변 완충로 (월드 루프 ③의 허리)

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| spr_forest_path | **숲길 어귀** | transit | 어귀 | 실습림의 나무가 옅어지고 유황 냄새가 먼저 마중 나오는 길. | →sch_backwoods_east; →spr_village |
| spr_village | **온천 마을 어귀** `map,shop` | town | 마을 | 김이 골목마다 피어오르는 마을 — 지도 파는 가게와 수건 대여점이 나란히 있다. | →spr_forest_path; →spr_bath; →spr_inn; →spr_gossip_deck |
| spr_bath | **노천탕** `bench,warm` | bench | 마을 | 거점 — 협곡이 내려다보이는 노천탕. 지팡이는 입구의 우산꽂이에. 여기서의 회복은 유난히 깊다. | →spr_village |
| spr_inn | **수건 여관** `warm,shop` | town | 마을 | 수건을 머리에 얹은 간판의 여관 — 늦은 밤에도 국물 요리가 나온다. | →spr_village |
| spr_gossip_deck | **소문 평상** | event | 마을 | 탕에서 나온 사람들이 몸을 말리며 세상 이야기를 흘리는 평상 — 세계의 소문이 모이는 곳. | →spr_village; →spr_river_east |
| spr_river_east | **강가 나루** | transit | 강가 | 온천물이 섞여 김이 오르는 강 — 나룻배가 조수 도시까지 오간다. | →spr_gossip_deck; →tid_river_west |

### 조수 도시 (`tid`) — 10방
- **정체성**: 밀물과 썰물로 길이 바뀌는 항구 도시 — 같은 골목이 물때에 따라 다른 지도가 된다. 얼음 발판 연계 소지역.
- **속성**: 없음 / **팔레트**: 젖은 목재의 짙은 갈색 + 바다의 청록 + 등대의 흰색과 주황 / **음악**: 뱃노래 풍의 아코디언 — 밀물 때는 잔잔하게, 썰물 때는 경쾌하게 바뀐다
- **고유 적**: 따개비 집게 — 썰물에 드러난 골목 바닥에 붙어 있다가 지나가는 발목을 노리는 놈.
- **보스 열쇠(로컬 스토리)**: 보스 없음(미니보스만). 등대지기의 부탁으로 조수 시계를 손보면 — 물때를 스스로 고를 수 있게 된다(썰물 전환 개방).
- **클리어 후 변화**: 조수 시계 수리 후 도시의 물때를 등대에서 전환할 수 있다 — 하층과 수직갱이 온전히 열린다.
- 루프: 밀물/썰물 전환 자체가 루프 — 같은 방들이 두 벌의 경로로 작동한다
- 루프: 북쪽 벼랑길(번개 목장)~강 나루(온천)를 잇는 동부 순환의 모서리(월드 루프 ③)

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| tid_river_west | **강 하구 나루** | transit | 항구 | 온천의 김이 채 가시지 않은 강물이 바다와 만나는 나루 — 갈매기가 먼저 안다. | →spr_river_east; →tid_quay |
| tid_quay | **부두** `map,shop` | town | 항구 | 도시의 현관 — 지역 지도 입수처. 밧줄과 생선 궤짝, 물때표가 걸린 게시판. | →tid_river_west; →tid_market; →tid_lighthouse_base; →tid_lower_town(얼음 발판) |
| tid_market | **생선 골목 시장** `shop` | town | 항구 | 경매 소리로 시끄러운 시장 — 물때에 따라 파는 것이 달라진다. | →tid_quay; →tid_moon_site |
| tid_moon_site | **보름 물때 빈터** `moon_site` | event | 항구 | 보름밤 만조 때만 물 위로 드러나는 판판한 터 — 달시장의 소문이 도는 곳. | →tid_market; →mkt_gate_tid(상태:보름밤) |
| tid_lighthouse_base | **등대 기단** `bench,warm` | bench | 등대 | 거점 — 등대지기의 부엌이 딸린 기단. 벽에 물때 달력이 백 년 치 걸려 있다. | →tid_quay; →tid_lighthouse_top |
| tid_lighthouse_top | **등대 꼭대기** | event | 등대 | 고장 난 조수 시계가 있는 꼭대기 — 수리하면 여기서 물때를 전환한다(지역 기믹의 심장). | →tid_lighthouse_base |
| tid_lower_town | **물에 잠긴 하층** | field | 하층 | 밀물이면 지붕만 남는 옛 시가 — 썰물이면 골목이, 밀물이면 뱃길이 된다. | →tid_quay(얼음 발판); →tid_flooded_lane(상태:썰물); →tid_cliff_north |
| tid_flooded_lane | **잠긴 골목** | miniboss | 하층 | 미니보스 — 썰물 골목의 주인, 따개비 집게 큰 놈. 물때가 바뀌면 싸움의 지형도 바뀐다. | →tid_lower_town; →tid_lowtide_well(상태:썰물) |
| tid_lowtide_well | **썰물 수직갱** | transit | 하층 | 썰물 때만 아가리를 드러내는 우물 모양 수직갱 — 두레박 사슬이 어둠 속으로 이어진다. | →tid_flooded_lane(상태:썰물); →sun_upper_gate(상태:썰물) |
| tid_cliff_north | **북쪽 벼랑길** | transit | 하층 | 바닷바람이 벼랑을 때리는 북행 길 — 고원의 목장까지, 활공으로 기류를 타는 자만 오른다. | →tid_lower_town; →lig_south_trail(활공) |

### 수몰 성소·지하 수맥 (`sun`) — 12방
- **정체성**: 물에 잠긴 옛 성소와 그 아래의 수맥 — 물잠이 여는 수중 미니 던전. 숨 대신 마나가 닳는 세계.
- **속성**: 없음(물 테마) / **팔레트**: 물속의 심청색 + 성소 석재의 상아색 + 수면에 흔들리는 빛 무늬 / **음악**: 물에 잠긴 종소리 같은 잔향 — 수면 위와 아래의 소리가 다르다
- **고유 적**: 빛낚시꾼 — 어둔 물속에서 등불 같은 미끼를 흔드는 놈. 미끼와 진짜 출구를 구분해야 한다.
- **보스 열쇠(로컬 스토리)**: 보스 없음(미니보스 수문장만). 성소가 무엇을 모셨는지는 끝내 말하지 않는다 — 부조와 배치로만 묻게 한다(스토리 미확정).
- **클리어 후 변화**: 수문장이 물러나면 수맥의 물이 맑아져 숲 쪽 물길의 시야가 트인다.
- 루프: 조수 도시(썰물)에서 내려와 숲 심부(물잠)로 빠져나가는 관통형 던전 — 월드 루프 ③의 물밑 구간

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| sun_upper_gate | **성소 상부 수문** | transit | 상부 | 수직갱의 두레박이 닿는 곳 — 썰물 때만 문설주가 물 위로 드러난다. | →tid_lowtide_well(상태:썰물); →sun_dry_cloister |
| sun_dry_cloister | **마른 회랑** | field | 상부 | 썰물이면 걸어서, 밀물이면 헤엄으로 — 물때가 난이도를 정하는 회랑. | →sun_upper_gate; →sun_altar_isle; →sun_mosaic_hall |
| sun_altar_isle | **물 위 제단** `bench,warm` | bench | 상부 | 거점 — 어떤 물때에도 잠기지 않는 단 하나의 제단. 촛불이 물그림자에 흔들린다. | →sun_dry_cloister |
| sun_mosaic_hall | **물비늘 모자이크 홀** | field | 상부 | 바닥 모자이크가 물결에 살아 움직이는 홀 — 무엇을 그린 그림인지는 반쯤 지워져 있다. | →sun_dry_cloister; →sun_relief_room(비밀); →sun_sunk_stair |
| sun_relief_room | **부조의 방** | secret | 상부 | 오래된 신앙의 부조 — 물에 닳아 얼굴들이 지워졌다. 답 없는 질문 하나와 마력석. | →sun_mosaic_hall |
| sun_sunk_stair | **잠긴 계단** | transit | 심부 | 어느 물때에도 물 밑인 계단 — 여기부터는 물잠 없이 내려갈 수 없다. | →sun_mosaic_hall; →sun_deep_nave(물잠) |
| sun_deep_nave | **수몰된 본당** | field | 심부 | 완전한 수중 — 마나가 숨이 되는 본당. 기둥 사이로 빛낚시꾼의 가짜 등불이 어른거린다. | →sun_sunk_stair(물잠); →sun_choir_cave(비밀); →sun_warden_hall |
| sun_choir_cave | **노래하는 공기굴** `warm` | secret | 심부 | 천장에 갇힌 큰 공기 방울 — 숨(마나)을 고르는 쉼터. 물이 오르간처럼 운다. | →sun_deep_nave |
| sun_warden_hall | **수문장의 방** | miniboss | 심부 | 미니보스 — 성소의 마지막 수문장. 물살을 일으켜 위치를 강제하는 수중전의 시험. | →sun_deep_nave; →sun_aquifer_1 |
| sun_aquifer_1 | **지하 수맥** | field | 수맥 | 성소를 지나 서쪽으로 흐르는 큰 물길 — 세계의 밑을 잇는 조용한 혈관. | →sun_warden_hall; →sun_aquifer_book(비밀); →sun_aquifer_west |
| sun_aquifer_book | **물에 잠긴 서고** | secret | 수맥 | 방수 유리함에 봉해진 마도서 한 권 — 물의 상급 주문. 누가 여기 두었는지는 모른다. | →sun_aquifer_1 |
| sun_aquifer_west | **수맥 서단** | transit | 수맥 | 물길이 숲의 뿌리 밑으로 빠져나가는 서쪽 끝 — 물 밖으로 반딧불의 초록빛이 비쳐 든다. | →sun_aquifer_1; →for_deep_east(물잠) |

### 기사단 마을 (`kni`) — 8방
- **정체성**: 마법 없는 사람들의 마을 — 검과 규율의 질서. 마법사를 신기해하고, 조금 경계하고, 끝내 존중하는 시선들.
- **속성**: 없음 / **팔레트**: 무쇠 회색 + 깃발의 진홍 + 연무장의 다진 흙색 / **음악**: 북과 발 구르는 소리의 절제된 행진곡 — 저녁 종 뒤엔 조용해진다
- **고유 적**: 없음(마을). 외곽 가도의 위협은 옛 가도 지역이 담당.
- **보스 열쇠(로컬 스토리)**: 보스 없음. 로컬 스토리 — 무너진 서쪽 다리의 수리 탄원: 자재 호위와 측량을 도우면 학교 직통 다리가 개통된다(상태:서쪽 다리 개통).
- **클리어 후 변화**: 다리 개통 — 학교와 서쪽 세계가 걸어서 이어지고, 마을에 학교 학생들의 왕래가 생긴다.
- 루프: 다리 개통으로 월드 루프 ①(학교→광산→가도→기사단 마을→학교)이 닫힌다

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| kni_road_west | **가도 초소** | transit | 외곽 | 창을 든 초병이 여행자를 기록하는 초소 — 마법사 신분증을 신기해하며 오래 들여다본다. | →roa_knight_gate; →kni_yard |
| kni_yard | **연무장 마당** `map` | town | 마을 | 마을의 중심 — 지역 지도 입수처. 목검 소리와 구령이 하루 종일 끊이지 않는다. | →kni_road_west; →kni_forge; →kni_hall; →kni_watchtower; →kni_inn; →kni_bridge_east |
| kni_forge | **대장간** `shop` | town | 마을 | 마법 없이 벼려낸 강철의 긍지 — 지팡이 손잡이 보강 같은 '비마법' 개조를 맡아 준다. | →kni_yard |
| kni_hall | **기사단 회관** | event | 마을 | 다리 수리 탄원서가 걸린 회관 — 로컬 스토리의 심장. 늙은 단장은 마법사를 다리 지지대만큼 믿는다. | →kni_yard |
| kni_watchtower | **망루** `warm` | field | 마을 | 협곡과 다리 터가 한눈에 보이는 망루 — 초병의 망원경을 빌려 볼 수 있다. | →kni_yard; →kni_training_wall |
| kni_training_wall | **수직 훈련벽** | challenge | 마을 | 기사 후보생의 담력 시험 벽 — 벽달리기 챌린지 코스로 완벽하다. 완주하면 단원들의 박수. | →kni_watchtower |
| kni_inn | **창끝 여관** `bench,warm` | bench | 마을 | 거점 — 은퇴 기사가 여는 여관. 벽난로 위에 부러진 첫 창이 걸려 있다. | →kni_yard |
| kni_bridge_east | **서쪽 다리 어귀** | transit | 외곽 | 무너진 다리의 마을 쪽 끝 — 수리가 끝나면 협곡 건너 학교 정문 마당까지 곧장 이어진다. | →kni_yard; →sch_west_bridge(상태:서쪽 다리 개통) |

### 가마 마을 (`kil`) — 8방
- **정체성**: 불의 본고장 — 광산 심장부의 열기가 데우는 큰 가마들의 도공 마을. 고급 화염술사가 은거하는 불 전공의 성지.
- **속성**: 없음(불 테마) / **팔레트**: 붉은 벽돌 + 가마 불빛의 진홍과 주황 + 재의 회백색 / **음악**: 장작 튀는 소리와 낮은 풀무 리듬 — 열기가 음악의 밀도로 느껴진다
- **고유 적**: 재도깨비 — 가마 재 속에서 뭉쳐 일어나는 장난꾸러기. 물 기초 한 방이면 얌전해진다.
- **보스 열쇠(로컬 스토리)**: 보스 없음. 로컬 스토리 — 식어가던 가마들이 광산 심장의 안정과 함께 되살아난다: 마을의 감사가 곧 문이다.
- **클리어 후 변화**: 열기 통로 개통 후 모든 가마에 불이 들어오고, 도공들의 야시장이 열린다.
- 루프: 광산 심장부(열기 통로)→가마 마을→남쪽 가도→거울의 도시로 이어지는 월드 루프 ⑤의 모서리

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| kil_heat_gate | **열기 통로 어귀** | transit | 외곽 | 광산 쪽에서 뜨거운 바람이 올라오는 문 — 마을의 가마들이 이 열기로 산다. | →min_heart_pass; →kil_court |
| kil_court | **가마 앞마당** `map,shop` | town | 마을 | 마을의 중심 — 지역 지도 입수처. 갓 구운 도기가 식는 냄새와 잔불의 온기. | →kil_heat_gate; →kil_great_kiln; →kil_glaze_lane; →kil_south_gate |
| kil_great_kiln | **큰가마 홀** `warm` | event | 마을 | 마을에서 가장 오래된 가마 — 안에 들어가 몸을 말릴 수 있을 만큼 크다. 도공들의 자부심. | →kil_court |
| kil_glaze_lane | **유약 골목** `shop` | town | 마을 | 유약 단지가 무지개처럼 늘어선 골목 — 내열 소품과 도기 상점. | →kil_court; →kil_kiln_maze |
| kil_kiln_maze | **가마 사잇길** | field | 안마을 | 열기가 벽처럼 서는 가마 사이 미로 — 물 기초로 김을 세워 길을 여는 짧은 퍼즐. | →kil_glaze_lane; →kil_master_door(기초:물) |
| kil_master_door | **가장 뜨거운 가마 뒤** | field | 안마을 | 마을 사람들도 잘 가지 않는 막다른 골목 — 문패 없는 문 하나가 붉게 달아 있다. | →kil_kiln_maze; →kil_fire_master |
| kil_fire_master | **화염술사의 방** `bench,teacher,warm` | bench | 안마을 | 고급 화염술사의 은거처 — 찾아온 것 자체가 입학 시험이었다는 듯 웃는다. 불 전공 오의 교습처. | →kil_master_door |
| kil_south_gate | **남녘 가도 문** | transit | 외곽 | 절벽 가도로 나가는 남문 — 도기 수레가 거울의 도시로 오르는 길의 시작. | →kil_court; →roa_south_low |

### 달시장 (`mkt`) — 5방
- **정체성**: 보름밤에만 열리는 이동 시장 — 세 도시의 빈터에 같은 시장이 나타난다. 단, 시장은 '네가 이미 서 본 적 있는 터'로만 문을 낸다 (미방문 도시로의 지름길 불가).
- **속성**: 없음 / **팔레트**: 먹빛 밤하늘 + 달빛의 은백 + 등롱의 남보라와 금색 / **음악**: 어디선가 들리는 오르골과 낮은 웅성임 — 박자가 달의 위상처럼 느리게 찬다
- **고유 적**: 없음(시장 — 전투 없음)
- **보스 열쇠(로컬 스토리)**: 보스 없음 — 시장의 유일한 규칙: '값을 깎지 말 것, 출처를 묻지 말 것.'
- **클리어 후 변화**: 방문 횟수가 쌓이면 골동품상이 얼굴을 기억하고, 안 팔던 물건을 슬쩍 꺼내 놓는다.
- 루프: 곤돌라 마을·거울의 도시·조수 도시의 세 터를 잇는 보름밤 지름길 — 시장 자체가 움직이는 루프

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| mkt_gate_gon | **등불 문** | transit | 문 | 곤돌라 마을 빈터 쪽 문 — 빨랫줄 자리에 등불이 줄지어 걸린다. | →gon_moon_site(상태:보름밤); →mkt_lane |
| mkt_gate_mir | **모래 문** | transit | 문 | 거울의 도시 그늘 터 쪽 문 — 문지방에 사막의 모래가 흘러든다. | →mir_moon_site(상태:달시장 터·거울); →mkt_lane |
| mkt_gate_tid | **물때 문** | transit | 문 | 조수 도시 물때 터 쪽 문 — 문턱이 젖어 있고 갯내가 난다. | →tid_moon_site(상태:달시장 터·조수); →mkt_lane |
| mkt_lane | **달빛 골목** `shop,warm` | town | 시장 | 세 문이 만나는 등롱 골목 — 좌판마다 낯선 물건. 걸음이 느려지는 곳. | →mkt_gate_gon; →mkt_gate_mir; →mkt_gate_tid; →mkt_bazaar |
| mkt_bazaar | **달의 좌판** `shop` | town | 시장 | 수상한 마도서 상인과 화폐→마력석 환전소(보름마다 한정 수량) — 시장의 심장. 골동품상은 손님 얼굴을 오래 기억한다. | →mkt_lane |

### 옛 가도·폐역 (`roa`) — 10방
- **정체성**: 세계를 잇던 옛 상단 가도와 폐선 수레 레일의 역들 — 서쪽 팔과 남쪽 팔이 만나는 Y자 연결 조직. 쓸쓸함이 정체성.
- **속성**: 없음 / **팔레트**: 바랜 침목의 회갈색 + 마른 풀 + 저녁빛의 주황 / **음악**: 빈 레일을 스치는 바람과 삐걱이는 간판 — 멜로디는 거의 없다
- **고유 적**: 가도 뜨내기 — 버려진 짐수레를 뒤지는 스캐빈저형. 싸움보다 도망이 빠르다.
- **보스 열쇠(로컬 스토리)**: 보스 없음. 로컬 스토리 — 폐역의 늙은 역장(이 마을의 마지막 주민)이 레일 재가동을 꿈꾼다: 광산의 권양기 수리와 맞물려 수레 패스트트래블이 깨어난다.
- **클리어 후 변화**: 수레 레일 재가동 — 광산↔폐역 교차로↔사막 앞 폐역이 이어지는 수평 패스트트래블 개통. 역장이 처음으로 제복을 다려 입는다.
- 루프: 절벽 밧줄 샛길(벽달리기)로 남쪽 가도에 내려가고, 거울의 도시 남문(내부 개방 후)→가도로 되돌아오는 순환
- 루프: 레일 재가동 후 서쪽 팔 전체가 패스트트래블 순환에 편입(월드 루프 ①·⑤의 연결로)

| id | 방 | 유형 | 구획 | 컨셉 | 연결 |
|---|---|---|---|---|---|
| roa_mine_trail | **광산 오솔길** | transit | 서쪽 팔 | 수레 바큇자국이 두 줄로 팬 오솔길 — 광산의 지상 문과 가도를 잇는다. | →min_camp_gate; →roa_rail_junction |
| roa_rail_junction | **폐역 교차로** `bench,rail,warm,map` | bench | 서쪽 팔 | 거점 — 늙은 역장이 홀로 지키는 큰 폐역. 대합실 난로와 백 년 치 시각표. 레일 패스트트래블의 심장. | →roa_mine_trail; →roa_knight_gate; →roa_west_run; →roa_cliff_drop |
| roa_knight_gate | **무너진 벼랑 구간** | field | 서쪽 팔 | 기사단 마을로 가는 가도가 벼랑째 무너진 곳 — 벽을 달릴 수 있다면 지나갈 수 있다. | →roa_rail_junction; →kni_road_west(벽달리기) |
| roa_west_run | **서쪽 가도** | field | 서쪽 팔 | 레일과 가도가 나란히 달리는 긴 직선 — 지평선 끝에 사막의 흰 빛이 걸려 있다. | →roa_rail_junction; →roa_rail_westend; →roa_old_camp(비밀) |
| roa_old_camp | **옛 상단 야영지** | secret | 서쪽 팔 | 가도 전성기의 야영 터 — 모닥불 자리와 상단의 장부. 세계 물류가 어떻게 돌았는지의 기록. | →roa_west_run |
| roa_rail_westend | **사막 앞 폐역** `rail` | transit | 서쪽 팔 | 레일의 서쪽 종점 — 모래가 플랫폼을 반쯤 삼켰다. 재가동되면 사막의 관문이 코앞이다. | →roa_west_run; →roa_desert_west |
| roa_desert_west | **사막 관문 앞** | transit | 서쪽 팔 | 거울의 도시 이중문 앞 모래 언덕 — 허공에 얼음 발판을 놓을 수 있어야 문루에 오른다. | →roa_rail_westend; →mir_gate_east(얼음 발판) |
| roa_cliff_drop | **절벽 밧줄 샛길** | transit | 남쪽 팔 | 옛 밀수꾼들이 절벽에 걸어 둔 샛길 — 벽을 달릴 줄 아는 자만 오르내린다. | →roa_rail_junction; →roa_south_high(벽달리기) |
| roa_south_high | **남쪽 가도 상단** | field | 남쪽 팔 | 절벽 허리를 감아 도는 가도 — 위로는 거울의 도시 남문, 아래로는 가마 연기가 보인다. | →roa_cliff_drop(벽달리기); →roa_south_low; →mir_south_gate(상태:남문 개방) |
| roa_south_low | **남쪽 가도 하단** | field | 남쪽 팔 | 가마 마을의 도기 수레가 쉬어 가는 굽잇길 — 깨진 도기 조각이 이정표처럼 박혀 있다. | →roa_south_high; →kil_south_gate |
