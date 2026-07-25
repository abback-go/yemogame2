# yemogame2

1인 개발 게임 프로젝트 저장소 (Claude Code 협업).

- **Track 1 — 작은 게임**: Unity/C# 소품 완성·출시 (최우선, 컨셉 미정)
- **Track 2 — 본 게임**: 2D 마법학교 메트로베니아 (Steam 목표, 기획 단계)

## 시작 문서

| 문서 | 내용 |
|---|---|
| `TODO.md` | 현황·다음 액션·결정 로그 — **새 세션은 여기부터** |
| `CLAUDE.md` | 작업 규칙 (세션 프로토콜·저장소 규칙) |
| `docs/game-design.md` | 본 게임 기획서 (정본) |
| `docs/story-track.md` | 스토리 트랙 (유저 뼈대 제시 대기) |
| `docs/movement-spec.md` | 이동 수치 정본 (유저 검증 완료) |

## 바로 플레이 (GitHub Pages)

- **전투 샌드박스**: https://abback-go.github.io/yemogame2/game/combat.html — 손맛 검증용 (F1 = 튜닝 패널)
- 월드맵 뷰어: https://abback-go.github.io/yemogame2/map.html

## 폴더 구조

```
docs/           기획 문서 (world/ = 월드 원본 JSON + 산출물)
game/           HTML 검증 샌드박스 (일회용 — 본편 코드 아님)
godot/          동결 아카이브 (수정 금지 — 검증 자산 참조용)
prototype/      구 HTML 프로토타입 (일회용·종료)
tools/          빌드 스크립트 (worldmap_build.py)
```

- 브랜치: `claude/magic-school-game-concept-wchpjn` = 작업 정본 / `gh-pages` = 배포 전용
