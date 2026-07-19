class_name GameState
extends Node
## 씬 전환에도 유지되는 전역 전투 상태.
## static var는 스크립트 수명 동안 살아남아(씬 change 시 스크립트는 언로드 안 됨)
## 런처에서 선택한 원소를 combat_arena/player로 전달하는 단일 출처가 된다.
## 오토로드 불필요 — class_name 이므로 GameState.combat_element 로 어디서든 접근.

static var combat_element := "fire"  # "fire" 기본 / "ice"

# ── 수직 슬라이스 크로스-방 지속 상태 (slice_room.gd 가 방 재로드마다 읽고 쓴다) ──
# 씬 재로드(get_tree().reload_current_scene())로 방을 전환하므로, 방을 넘어 유지할
# 값(현재 방·입장 문·체력/마나/산소·각인·방문 기록·거점 방)은 여기에만 둔다.
static var slice_room := "hub"  # 현재 방 id (SliceData 의 키)
static var slice_entry := "start"  # 입장 문 id (스폰 위치 결정)
static var player_mana := 100.0
static var player_health := 5
static var player_oxygen := 100.0
static var skill_slots: Array[String] = ["", ""]  # 각인 2슬롯 (방 넘어 유지)
static var visited: Array[String] = []  # 방문한 방 id (중복 없이, 발견 N/5)
static var respawn_room := "hub"  # 거점(bench) 세이브 방 — 사망 시 여기로 리스폰


static func reset_slice() -> void:
	# 런처 [4] 첫 진입 초기화 — 시작 방·풀피/풀마나·빈 각인·방문 기록 리셋.
	slice_room = "hub"
	slice_entry = "start"
	player_mana = 100.0
	player_health = 5
	player_oxygen = 100.0
	skill_slots = ["", ""]
	visited = []
	respawn_room = "hub"
