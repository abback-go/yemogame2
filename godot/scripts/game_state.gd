class_name GameState
extends Node
## 씬 전환에도 유지되는 전역 전투 상태.
## static var는 스크립트 수명 동안 살아남아(씬 change 시 스크립트는 언로드 안 됨)
## 런처에서 선택한 원소를 combat_arena/player로 전달하는 단일 출처가 된다.
## 오토로드 불필요 — class_name 이므로 GameState.combat_element 로 어디서든 접근.

static var combat_element := "fire"  # "fire" 기본 / "ice"
