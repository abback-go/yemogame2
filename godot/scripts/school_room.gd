extends Node2D
## 협곡 학교 심장부 12방 그레이박스 빌더 — GameState.school_room 이 가리키는 방 하나를
## 코드 생성한다. 아키텍처는 slice_room.gd 와 동일: 방 전환 = 씬 재로드
## (get_tree().reload_current_scene()) + GameState 크로스-방 지속. 순수 지형·출구·NPC·거점
## 도형은 RoomBuilder 공용 헬퍼로 조립(DRY). 학교 전용 상태는 GameState 의 school_* 병렬
## 필드(튜토리얼 slice 상태와 분리)로 다룬다.
##
## 학교 성격: 안전지대 — 전투는 결계 돔의 훈련 허수아비뿐. 전 이동기 ON(능력 게이트 없음).
## 거점(내 방)에서 F로 회복·세이브·각인. 미구현 외부 연결은 회색 문틀 + "미구현" 스텁.

const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/debug_hud.gd")
const EngravePanelScript := preload("res://scripts/engrave_panel.gd")
const DummyScript := preload("res://scripts/enemies/dummy.gd")

const BENCH_RADIUS := 70.0
const SPAWN_GRACE := 0.25  # 스폰 직후 출구 재트리거 방지 유예
const BLOCKED_TOAST_CD := 1.6  # 미구현 문 토스트 재표시 쿨다운

@export_group("주스 (combat-spec §6)")
@export var shake_max_offset := 12.0
@export var trauma_decay := 1.8
@export var lookahead_dist := 40.0
@export var lookahead_speed := 5.0
@export var hitstop_scale := 0.0

var _player: CharacterBody2D
var _hud: CanvasLayer
var _juice: Juice
var _font: SystemFont
var _engrave: EngravePanel = null
var _enemies: Array = []
var _exits: Array = []  # [{rect:Rect2, to:String, entry:String}]
var _blocked: Array = []  # [{rect:Rect2, name:String}]
var _room_id := "sch_plaza"
var _room_name := ""
var _room_size := Vector2(2000, 760)
var _has_bench := false
var _bench_pos := Vector2.ZERO
var _region_label: Label
var _bench_prompt: Label
var _reloading := false
var _grace_t := 0.0
var _blocked_toast_t := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.10))
	_font = RoomBuilder.make_font()
	_setup_input()
	_room_id = GameState.school_room
	var room := SchoolData.get_room(_room_id)
	_room_name = String(room["name"])
	_room_size = room["size"]
	_mark_visited(_room_id)
	_build_room(room)
	_player = _spawn_player(_entry_pos(room["entries"], GameState.school_entry))
	_player.collision_layer = 2  # 적(레이어4)·플레이어 물리 충돌 분리(발판=1)
	_inject_player_state()
	_player.died.connect(_on_player_death)
	_apply_all_abilities()
	_player.set_zones([] as Array[Rect2], [] as Array[Rect2])
	_enemies = _spawn_enemies(room["enemies"])
	_player.set_enemies(_enemies)
	var cam := _setup_camera(_player)
	_juice = Juice.new()
	_juice.configure(
		shake_max_offset, trauma_decay, lookahead_dist, lookahead_speed, hitstop_scale)
	_juice.bind_camera(cam)
	_juice.bind_target(_player)
	add_child(_juice)
	_player.set_juice(_juice)
	_hud = _setup_hud(_player)
	_hud.set_combat_mode(true)
	_engrave = _setup_engrave()
	_setup_school_ui()
	_grace_t = SPAWN_GRACE


func _apply_all_abilities() -> void:
	# 학교 = 자유 이동. 능력 게이트가 없으므로 이동기 9종 전부 ON(달리기·점프·칼은 상시).
	for key in PlayerScript.ABILITY_KEYS:
		_player.abilities[key] = true


func _physics_process(delta: float) -> void:
	if _reloading:
		return
	if _blocked_toast_t > 0.0:
		_blocked_toast_t = maxf(0.0, _blocked_toast_t - delta)
	if _grace_t > 0.0:
		_grace_t = maxf(0.0, _grace_t - delta)
	else:
		_check_exits()
		_check_blocked()
	_update_bench_prompt()


func _check_exits() -> void:
	var p := _player.global_position
	for ex in _exits:
		if (ex["rect"] as Rect2).has_point(p):
			_go_to(String(ex["to"]), String(ex["entry"]))
			return


func _check_blocked() -> void:
	# 미구현 문 통과 시 토스트만(전환 없음). 쿨다운으로 스팸 방지.
	if _blocked_toast_t > 0.0:
		return
	var p := _player.global_position
	for bd in _blocked:
		if (bd["rect"] as Rect2).has_point(p):
			_hud.show_toast("미구현 구역 — %s" % String(bd["name"]))
			_blocked_toast_t = BLOCKED_TOAST_CD
			return


func _update_bench_prompt() -> void:
	if not _has_bench:
		return
	var near := _player.global_position.distance_to(_bench_pos) < BENCH_RADIUS
	_bench_prompt.visible = near and not _engrave.is_open()


# ── 방 전환·지속 (GameState.school_*) ─────────────────────────────

func _go_to(room: String, entry: String) -> void:
	if _reloading:
		return
	_reloading = true
	_save_player_state()
	GameState.school_room = room
	GameState.school_entry = entry
	get_tree().reload_current_scene()


func _on_player_death() -> void:
	# 사망·낙사 — 거점(내 방)으로 재로드·풀회복. 각인은 유지.
	if _reloading:
		return
	_reloading = true
	GameState.school_skill_slots[0] = _player.skill_slots[0]
	GameState.school_skill_slots[1] = _player.skill_slots[1]
	GameState.school_mana = PlayerScript.MANA_MAX
	GameState.school_health = PlayerScript.HEALTH_MAX
	GameState.school_oxygen = PlayerScript.OXYGEN_MAX
	GameState.school_room = GameState.school_respawn_room
	GameState.school_entry = "bench"
	get_tree().reload_current_scene()


func _inject_player_state() -> void:
	_player.mana = GameState.school_mana
	_player.health = GameState.school_health
	_player.oxygen = GameState.school_oxygen
	_player.skill_slots[0] = GameState.school_skill_slots[0]
	_player.skill_slots[1] = GameState.school_skill_slots[1]


func _save_player_state() -> void:
	GameState.school_mana = _player.mana
	GameState.school_health = _player.health
	GameState.school_oxygen = _player.oxygen
	GameState.school_skill_slots[0] = _player.skill_slots[0]
	GameState.school_skill_slots[1] = _player.skill_slots[1]


func _rest_at_bench() -> void:
	# 거점 F: 회복 + 세이브(리스폰 지점 갱신) + 각인 패널.
	_player.mana = PlayerScript.MANA_MAX
	_player.health = PlayerScript.HEALTH_MAX
	_player.oxygen = PlayerScript.OXYGEN_MAX
	GameState.school_respawn_room = _room_id
	_save_player_state()
	_hud.show_toast("휴식 — 회복·세이브 완료")
	_engrave.open(_player)


func _mark_visited(id: String) -> void:
	if not GameState.visited_school.has(id):
		GameState.visited_school.append(id)


# ── 입력 (slice/combat_arena 키맵 동일) ───────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var code: int = event.physical_keycode
	if code == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/launcher.tscn")
	elif code == KEY_R:
		_player.respawn()
		for e in _enemies:
			if is_instance_valid(e):
				e.reset_enemy()
		_hud.show_toast("리스폰")
	elif code == KEY_F:
		if _has_bench and not _engrave.is_open():
			if _player.global_position.distance_to(_bench_pos) < BENCH_RADIUS:
				_rest_at_bench()


func _setup_input() -> void:
	_bind(&"move_left", [KEY_LEFT])
	_bind(&"move_right", [KEY_RIGHT])
	_bind(&"move_down", [KEY_DOWN])
	_bind(&"fly_up", [KEY_UP])
	_bind(&"jump", [KEY_Z, KEY_SPACE])
	_bind(&"dash", [KEY_C, KEY_SHIFT])
	_bind(&"cast", [KEY_X])
	_bind(&"ice_place", [KEY_Q])
	_bind(&"fly", [KEY_E])
	_bind(&"attack", [KEY_A])
	_bind(&"skill1", [KEY_S])
	_bind(&"skill2", [KEY_D])


func _bind(action: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	else:
		InputMap.action_erase_events(action)
	for kc in keycodes:
		var ev := InputEventKey.new()
		ev.physical_keycode = kc
		InputMap.action_add_event(action, ev)


# ── 방 빌드 (RoomBuilder 공용 헬퍼) ───────────────────────────────

func _build_room(room: Dictionary) -> void:
	_build_outer_walls(_room_size)
	for r in room["solids"]:
		RoomBuilder.add_platform(self, r, RoomBuilder.WALL_COLOR)
	for r in room["plats"]:
		RoomBuilder.add_platform(self, r, RoomBuilder.PLAT_COLOR)
	for d in room["decos"]:
		RoomBuilder.add_visual_rect(self, d["rect"], d["color"])
	for pos in room["rewards"]:
		_add_reward(pos)
	for s in room["signs"]:
		RoomBuilder.add_sign(self, _font, s["pos"], String(s["text"]))
	for n in room["npcs"]:
		RoomBuilder.build_npc(self, _font, n["pos"], String(n["label"]), n["color"])
	_blocked = []
	for bd in room["blocked"]:
		RoomBuilder.add_blocked_door(
			self, _font, bd["rect"], String(bd["arrow"]), String(bd["name"]))
		_blocked.append({"rect": bd["rect"], "name": String(bd["name"])})
	_exits = room["exits"]
	for ex in _exits:
		RoomBuilder.add_exit_marker(
			self, _font, ex["rect"], String(ex.get("arrow", "right")),
			SchoolData.room_name(String(ex["to"])))
	if room.has("bench"):
		_has_bench = true
		_bench_pos = room["bench"]
		RoomBuilder.build_bench(self, _font, _bench_pos)


func _build_outer_walls(size: Vector2) -> void:
	# 좌·우·천장 외벽만(바닥은 방 solids 가 담당).
	RoomBuilder.add_platform(self, Rect2(0, 0, 20, size.y), RoomBuilder.WALL_COLOR)
	RoomBuilder.add_platform(self, Rect2(size.x - 20, 0, 20, size.y), RoomBuilder.WALL_COLOR)
	RoomBuilder.add_platform(self, Rect2(0, 0, size.x, 20), RoomBuilder.WALL_COLOR)


func _add_reward(pos: Vector2) -> void:
	var vis := Polygon2D.new()
	vis.position = pos
	vis.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(10, 0), Vector2(0, 12), Vector2(-10, 0),
	])
	vis.color = Color(1.0, 0.85, 0.25)
	add_child(vis)


# ── 스폰·카메라·HUD·각인 (slice/combat_arena 재사용) ──────────────

func _spawn_player(pos: Vector2) -> CharacterBody2D:
	var packed := load("res://scenes/player.tscn") as PackedScene
	var p: CharacterBody2D = null
	if packed != null:
		p = packed.instantiate() as CharacterBody2D
	if p != null:
		print("[진단] player.tscn 인스턴스 성공 — 학교 그레이박스 공유 컨트롤러")
	else:
		push_warning("[진단] player.tscn 로드 실패 — 코드 생성 대체")
		p = CharacterBody2D.new()
		p.set_script(PlayerScript)
		var shape := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(20, 34)
		shape.shape = rs
		p.add_child(shape)
	p.name = "Player"
	p.position = pos  # add_child 전 세팅 → player._ready 의 start_pos(=R 리스폰) 정확
	add_child(p)
	return p


func _spawn_enemies(defs: Array) -> Array:
	var arr: Array = []
	for d in defs:
		if String(d["type"]) != "dummy":
			push_warning("[진단] 학교는 훈련 허수아비(dummy)만 지원: %s 무시" % String(d["type"]))
			continue
		arr.append(_spawn_enemy(DummyScript, d["pos"]))
	return arr


func _spawn_enemy(script: GDScript, pos: Vector2) -> Node:
	var e: CharacterBody2D = script.new()
	e.position = pos  # add_child 전 세팅 → _ready 의 home_pos 정확
	add_child(e)
	e.set_target(_player)
	return e


func _setup_camera(player: CharacterBody2D) -> Camera2D:
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(_room_size.x)
	cam.limit_bottom = int(_room_size.y)
	cam.set("position_smoothing_enabled", true)
	cam.set("position_smoothing_speed", 8.0)
	player.add_child(cam)
	cam.make_current()
	return cam


func _setup_hud(player: CharacterBody2D) -> CanvasLayer:
	var hud := CanvasLayer.new()
	hud.set_script(HudScript)
	add_child(hud)
	hud.bind(player)
	return hud


func _setup_engrave() -> EngravePanel:
	var panel: EngravePanel = EngravePanelScript.new()
	add_child(panel)
	return panel


func _setup_school_ui() -> void:
	# 진행 기록 라벨(구역·발견 N/12) + 거점 안내 — 별도 CanvasLayer(HUD 위 상단 중앙).
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_region_label = RoomBuilder.mklabel(
		layer, _font, "", Vector2(330, 6), 16, Color(0.85, 0.92, 1.0))
	_bench_prompt = RoomBuilder.mklabel(
		layer, _font, "F: 휴식 (회복·세이브·각인)", Vector2(330, 110), 16, Color(1.0, 0.92, 0.6))
	_bench_prompt.visible = false
	_region_label.text = "구역: %s   ·   발견 %d/%d" % [
		_room_name, GameState.visited_school.size(), SchoolData.room_count()]


func _entry_pos(entries: Dictionary, entry: String) -> Vector2:
	if entries.has(entry):
		return entries[entry]
	push_warning("[진단] 입장 문 없음: %s — 기본 위치 대체" % entry)
	if entries.size() > 0:
		return entries.values()[0]
	return Vector2(100, 100)
