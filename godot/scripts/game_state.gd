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
# ── 튜토리얼 능력 획득 진행(오브로 하나씩 습득 → 방 넘어·재로드 지속) ──
# abilities_granted: 오브로 습득한 player.abilities 키들(예: "dash_ground").
#   방 빌드마다 slice_room 이 이 목록만 player.abilities 에 ON(_apply_granted_abilities).
# orbs_taken: 이미 먹은 오브 id — 재로드·재방문 시 오브 재생성 스킵.
static var abilities_granted: Array[String] = []
static var orbs_taken: Array[String] = []

# ── 학교 심장부 그레이박스 크로스-방 지속 상태 (school_room.gd 전용) ──
# 튜토리얼 slice 상태(위)와 완전히 분리한 병렬 필드다. 런처 [5] 진입 시 reset_school()로
# 리셋되며, 방 재로드(get_tree().reload_current_scene())로 방을 넘어 유지할 값(현재 방·입장
# 문·체력/마나/산소·각인·방문 기록·거점 방)만 여기 둔다. 학교는 안전지대·전 이동기 ON이라
# 능력 획득(abilities_granted/orbs_taken) 개념이 없다.
static var school_room := "sch_plaza"  # 현재 학교 방 id (SchoolData 의 키)
static var school_entry := "start"  # 입장 문 id (스폰 위치 결정)
static var school_mana := 100.0
static var school_health := 5
static var school_oxygen := 100.0
static var school_skill_slots: Array[String] = ["", ""]  # 각인 2슬롯 (방 넘어 유지)
static var visited_school: Array[String] = []  # 방문한 학교 방 id (중복 없이, 발견 N/12)
static var school_respawn_room := "sch_dorm_room"  # 거점(내 방) — 사망 시 리스폰

# ── v3 전투 아레나 진행 상태 (combat_arena.gd 전용) ──
# 아레나는 단일 씬이라 R(리스폰)은 player.respawn()만 하고 씬을 재로드하지 않는다.
# 재화·배운 스킬·스킬 등급·장착 정수·각인 슬롯은 Esc→메뉴→[3] 재진입에도 유지되도록
# 여기(static)에 둔다. 런처 [3] 진입 시 reset_arena()로 리셋. 전부 slice/school 과 분리.
static var arena_material := 0  # 마력 결정 — 적 처치 드롭, 수업·레벨업 재화
static var arena_blade_element := "무"  # 장착된 속성 정수("무"=미장착 / "불" / "물")
static var arena_elements: Array[String] = ["무"]  # 보유 정수(장착 순환 대상)
static var arena_learned: Array[String] = []  # 수업으로 배운 스킬 id(각인 가능 목록)
static var arena_levels: Dictionary = {}  # skill id → 등급(1~3), 미기재=1
static var arena_slots: Array[String] = ["", ""]  # 각인 2슬롯 (재진입 유지)

# ── 연속 월드 (world_room.gd) — 학교 허브+전투 통합 진행 상태 ──
# 방 전환=씬 재로드 방식. 네비게이션·플레이어 상태·이동 능력 획득은 world_*,
# 전투 인벤토리(재화·정수·배운스킬·등급)는 arena_* 재사용(단일 출처).
static var world_room := "hub_plaza"  # 현재 월드 방 id (WorldData 키)
static var world_entry := "start"  # 입장 문 id
static var world_mana := 100.0
static var world_health := 5
static var world_oxygen := 100.0
static var world_skill_slots: Array[String] = ["", ""]  # 각인 2슬롯 (방 넘어 유지)
static var world_respawn_room := "hub_hall"  # 거점(세이브) 방 — 사망 시 리스폰
static var visited_world: Array[String] = []  # 방문 방 id (발견 N/총)
static var world_abilities_granted: Array[String] = []  # 오브로 획득한 이동 능력
static var world_orbs_taken: Array[String] = []  # 이미 먹은 오브 id (재생성 방지)

# ── 오프닝 튜토리얼 (opening_room.gd) — 콘티 6씬 선형 진행 상태 ──
# 방 전환=씬 재로드. 사망 시 현재 방 재시작(오프닝은 관대하게 — 풀회복).
static var opening_room := "op_alley"  # 현재 오프닝 방 id (OpeningData 키)
static var opening_entry := "start"  # 입장 문 id


static func reset_opening() -> void:
	# 런처 "시작" 진입 초기화 — 오프닝 첫 방부터.
	opening_room = "op_alley"
	opening_entry = "start"


static func reset_arena() -> void:
	# 런처 [3] 진입 초기화 — 재화 0·정수 미장착·배운 스킬 없음·등급 초기·빈 각인.
	arena_material = 0
	arena_blade_element = "무"
	arena_elements = ["무"]
	arena_learned = []
	arena_levels = {}
	arena_slots = ["", ""]


static func skill_level(id: String) -> int:
	# 스킬 등급 조회(미기재=1). 데미지·쿨 배율 계산의 단일 출처.
	return int(arena_levels.get(id, 1))


static func reset_world() -> void:
	# 런처 "시작" 진입 초기화 — 오프닝 첫 방·풀피/풀마나·빈 각인·능력/방문 리셋
	# + 전투 인벤토리(arena_*)도 초기화(단일 출처).
	world_room = "hub_plaza"
	world_entry = "start"
	world_mana = 100.0
	world_health = 5
	world_oxygen = 100.0
	world_skill_slots = ["", ""]
	world_respawn_room = "hub_hall"
	visited_world = []
	world_abilities_granted = []
	world_orbs_taken = []
	reset_arena()


static func reset_slice() -> void:
	# 런처 [4] 첫 진입 초기화 — 시작 방·풀피/풀마나·빈 각인·방문·능력 획득 리셋.
	slice_room = "hub"
	slice_entry = "start"
	player_mana = 100.0
	player_health = 5
	player_oxygen = 100.0
	skill_slots = ["", ""]
	visited = []
	respawn_room = "hub"
	abilities_granted = []
	orbs_taken = []


static func reset_school() -> void:
	# 런처 [5] 첫 진입 초기화 — 정문 마당·풀피/풀마나·빈 각인·방문 기록·거점 리셋.
	school_room = "sch_plaza"
	school_entry = "start"
	school_mana = 100.0
	school_health = 5
	school_oxygen = 100.0
	school_skill_slots = ["", ""]
	visited_school = []
	school_respawn_room = "sch_dorm_room"
