# Shadow Dagger: ECLIPSE — 설계 문서

작성일: 2026-05-25
원본: https://studyemomo-blip.github.io/pr1.github.io/ (Shadow Dagger)

## 목표

원본 "Shadow Dagger"(단검 암살자 vs 그림자 기사)와 거의 유사하되, **타격감(juice)과 비주얼**을
극한으로 끌어올린 단일 보스 강화판. 결과물은 의존성 없는 단일 HTML 파일.

확정 방향:
- 핵심: 전투 손맛·비주얼
- 스코프: 단일 보스 강화판
- 결과물: 단일 `index.html`
- 음향: 제외 (선택 안 함)

## 접근 방식

순수 `<canvas>` + vanilla JS, 외부 라이브러리 0개. 더블클릭 실행 + GitHub Pages 즉시 업로드 가능.

## 타격감 시스템 (핵심)

1. 히트스톱: 적중 순간 프레임 정지(강도 비례).
2. 화면 흔들림: trauma 기반, 제곱 감쇠.
3. 슬로우모션: 페이즈 전환·막타·퍼펙트 회피.
4. 파티클: 베기 궤적, 스파크, 대시 잔상, 착지 먼지, 피격 파편.
5. 네온 글로우: additive blend / shadowBlur.
6. 콤보 시스템: 연타 카운터 → 데미지 증가 + 콤보 숫자 연출.
7. 데미지 넘버: 떠오르는 숫자, 크리티컬 강조.
8. 줌 펀치: 큰 타격 시 카메라 미세 줌인.

## 전투

- 이동(←→), 점프/더블점프(Space/↑), Z 3연타 콤보(3타 넉백),
  X 표창(MP), C 그림자 대시(무적+잔상+데미지), Q 궁극기 라이트닝(차지 게이지), Shift 회피(무적).
- 신규: 퍼펙트 회피/패링 — 보스 공격 직전 회피 시 슬로우모 + 반격 윈도우 + 스파크.
- 원본 소환(E)은 제외(단일 보스·손맛 집중).

## 보스 — Shadow Knight (3페이즈)

- P1(100~66%): 돌진 베기, 투사체 물결.
- P2(66~33%): + 지면 강타 충격파, 순간이동 기습.
- P3(33~0%, 격노): + 광역기, 그림자 분신, 공속 증가.
- 모든 공격에 windup 예열 플래시(공정한 회피).

## 화면 흐름 / UI

- TITLE → HOW TO PLAY → PLAY → WIN/LOSE.
- HUD: 보스 HP(페이즈 분절), 플레이어 HP/MP, 콤보 카운터, 쿨다운 아이콘, 궁극 차지 게이지.
- 승패 화면: 클리어 타임 + 최대 콤보 + 랭크(S/A/B).

## 기술 구조 (단일 파일 내부 모듈화)

- 고정 타임스텝 루프(accumulator) + requestAnimationFrame.
- 섹션: config / input / particles / effects(shake·hitstop·slowmo·flash) /
  entities(player·boss·projectile·clone) / combat·collision / render layers / state machine.
