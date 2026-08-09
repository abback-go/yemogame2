extends Node2D
## 수직 슬라이스 방 빌더 — GameState.slice_room 이 가리키는 방 하나를 코드 생성한다.
## 방 전환 = 씬 재로드(get_tree().reload_current_scene()): 출구 트리거 진입 시
## GameState 에 목표 방·문·플레이어 상태를 저장하고 재로드 → 방 단위 카메라 리셋 자연 달성.
## 4.7 조립 규칙: 노드 전부 코드 생성, $경로 조회 없음, 참조는 메서드 주입.
## 지형·존·주스·HUD·각인 패턴은 combat_arena.gd 를 그대로 재사용(DRY).

const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/debug_hud.gd")
const EngravePanelScript := preload("res://scripts/engrave_panel.gd")
const DummyScript := preload("res://scripts/enemies/dummy.gd")
const WalkerScript := preload("res://scripts/enemies/walker.gd")
const ShooterScript := preload("res://scripts/enemies/shooter.gd")

const BENCH_RADIUS := 70.0
const SPAWN_GRACE := 0.25  # 스폰 직후 출구 재트리거 방지 유예
const ORB_RADIUS := 44.0  # 능력 오브 습득 근접 거리
const EXIT_COLOR := Color(0.3, 1.0, 1.0)  # 출구 문틀·화살표(시안)

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
var _water_rects: Array[Rect2] = []
var _updraft_rects: Array[Rect2] = []
var _exits: Array = []  # [{rect:Rect2, to:String, entry:String}]
var _room_id := "hub"
var _room_name := ""
var _room_size := Vector2(1200, 700)
var _has_bench := false
var _bench_pos := Vector2.ZERO
var _region_label: Label
var _bench_prompt: Label
var _reloading := false
var _grace_t := 0.0
var _pending_bubbles: Array[Node2D] = []  # 스폰 전 생성된 산소통 — 플레이어 스폰 후 등록
var _orbs: Array = []  # 활성 능력 오브 [{node, pos, grants, id, toast, tween}]


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.06, 0.09))
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	_setup_input()
	_room_id = GameState.slice_room
	var room := SliceData.get_room(_room_id)
	_room_name = String(room["name"])
	_room_size = room["size"]
	_mark_visited(_room_id)
	_build_room(room)
	_player = _spawn_player(_entry_pos(room["entries"], GameState.slice_entry))
	_player.collision_layer = 2  # 적(레이어4)·플레이어 물리 충돌 분리(발판=1)
	_inject_player_state()
	_player.died.connect(_on_player_death)
	_apply_granted_abilities()
	_player.set_zones(_water_rects, _updraft_rects)
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
	_setup_slice_ui()
	_grace_t = SPAWN_GRACE


func _apply_granted_abilities() -> void:
	# 튜토리얼: 9종 전부 OFF로 초기화한 뒤 GameState.abilities_granted 만 ON.
	# 달리기·점프·칼 공격은 abilities 딕셔너리 밖 → 항상 가능(시작 능력).
	for key in PlayerScript.ABILITY_KEYS:
		_player.abilities[key] = false
	for key in GameState.abilities_granted:
		var k := String(key)
		if _player.abilities.has(k):
			_player.abilities[k] = true


func _physics_process(delta: float) -> void:
	if _reloading:
		return
	if _grace_t > 0.0:
		_grace_t = maxf(0.0, _grace_t - delta)
	else:
		_check_exits()
	_check_orbs()
	_update_bench_prompt()


func _check_exits() -> void:
	var p := _player.global_position
	for ex in _exits:
		if (ex["rect"] as Rect2).has_point(p):
			_go_to(String(ex["to"]), String(ex["entry"]))
			return


func _update_bench_prompt() -> void:
	if not _has_bench:
		return
	var near := _player.global_position.distance_to(_bench_pos) < BENCH_RADIUS
	_bench_prompt.visible = near and not _engrave.is_open()


# ── 방 전환·지속 (GameState) ─────────────────────────────────────

func _go_to(room: String, entry: String) -> void:
	# 출구 트리거 진입 — 현재 상태 저장 후 목표 방으로 씬 재로드.
	if _reloading:
		return
	_reloading = true
	_save_player_state()
	GameState.slice_room = room
	GameState.slice_entry = entry
	get_tree().reload_current_scene()


func _on_player_death() -> void:
	# 사망(health<=0)·낙사 — 거점 방으로 재로드·풀회복. 각인은 유지.
	if _reloading:
		return
	_reloading = true
	GameState.skill_slots[0] = _player.skill_slots[0]
	GameState.skill_slots[1] = _player.skill_slots[1]
	GameState.player_mana = PlayerScript.MANA_MAX
	GameState.player_health = PlayerScript.HEALTH_MAX
	GameState.player_oxygen = PlayerScript.OXYGEN_MAX
	GameState.slice_room = GameState.respawn_room
	GameState.slice_entry = "bench"
	get_tree().reload_current_scene()


func _inject_player_state() -> void:
	# 방 재로드 후 지속 상태 주입 — 체력·마나·산소·각인 유지.
	_player.mana = GameState.player_mana
	_player.health = GameState.player_health
	_player.oxygen = GameState.player_oxygen
	_player.skill_slots[0] = GameState.skill_slots[0]
	_player.skill_slots[1] = GameState.skill_slots[1]


func _save_player_state() -> void:
	GameState.player_mana = _player.mana
	GameState.player_health = _player.health
	GameState.player_oxygen = _player.oxygen
	GameState.skill_slots[0] = _player.skill_slots[0]
	GameState.skill_slots[1] = _player.skill_slots[1]


func _rest_at_bench() -> void:
	# 거점 F: 회복 + 세이브(리스폰 지점 갱신) + 각인 패널. 세 기능 한 번에.
	_player.mana = PlayerScript.MANA_MAX
	_player.health = PlayerScript.HEALTH_MAX
	_player.oxygen = PlayerScript.OXYGEN_MAX
	GameState.respawn_room = _room_id
	_save_player_state()
	_hud.show_toast("휴식 — 회복·세이브 완료")
	_engrave.open(_player)


func _mark_visited(id: String) -> void:
	if not GameState.visited.has(id):
		GameState.visited.append(id)


# ── 입력 (combat_arena 키맵 동일) ────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	# 각인 패널 열림 중엔 패널 _input 이 키를 소비 → 여기 오지 않는다.
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


# ── 방 빌드 ──────────────────────────────────────────────────────

func _build_room(room: Dictionary) -> void:
	_build_outer_walls(_room_size)
	for r in room["solids"]:
		_add_platform(r, SliceData.WALL_COLOR)
	for r in room["plats"]:
		_add_platform(r, SliceData.PLAT_COLOR)
	for r in room["water"]:
		var wr: Rect2 = r
		_add_zone(wr, Color(0.2, 0.45, 0.9, 0.35))
		_water_rects.append(wr)
	for r in room["updraft"]:
		var ur: Rect2 = r
		_add_zone(ur, Color(0.4, 0.9, 0.5, 0.22))
		_updraft_rects.append(ur)
	for pos in room["bubbles"]:
		_pending_bubbles.append(_make_air_bubble(pos))
	for pos in room["rewards"]:
		_add_reward(pos)
	for s in room["signs"]:
		_add_sign(s["pos"], String(s["text"]))
	if room.has("gate_marks"):
		for gm in room["gate_marks"]:
			_add_visual_rect(gm["rect"], gm["color"])
	if room.has("orbs"):
		for od in room["orbs"]:
			if not GameState.orbs_taken.has(String(od["id"])):
				_spawn_orb(od)
	_exits = room["exits"]
	for ex in _exits:
		_add_exit_marker(ex["rect"], String(ex.get("arrow", "right")), EXIT_COLOR)
	if room.has("bench"):
		_has_bench = true
		_bench_pos = room["bench"]
		_build_bench(_bench_pos)
	if room.has("npc"):
		_build_npc(room["npc"])


func _build_outer_walls(size: Vector2) -> void:
	# 좌·우·천장 외벽만(바닥/낙하 굴뚝은 방 solids 가 담당).
	_add_platform(Rect2(0, 0, 20, size.y), SliceData.WALL_COLOR)
	_add_platform(Rect2(size.x - 20, 0, 20, size.y), SliceData.WALL_COLOR)
	_add_platform(Rect2(0, 0, size.x, 20), SliceData.WALL_COLOR)


func _add_platform(rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	body.add_child(_make_rect_visual(rect.size, color))
	add_child(body)


func _add_zone(rect: Rect2, color: Color) -> void:
	var area := Area2D.new()
	area.position = rect.position + rect.size / 2.0
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	area.add_child(shape)
	area.add_child(_make_rect_visual(rect.size, color))
	add_child(area)


func _make_rect_visual(size: Vector2, color: Color) -> Polygon2D:
	var vis := Polygon2D.new()
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	vis.color = color
	return vis


func _add_reward(pos: Vector2) -> void:
	var vis := Polygon2D.new()
	vis.position = pos
	vis.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(10, 0), Vector2(0, 12), Vector2(-10, 0),
	])
	vis.color = Color(1.0, 0.85, 0.25)
	add_child(vis)


func _make_air_bubble(pos: Vector2) -> Node2D:
	var vis := Polygon2D.new()
	vis.position = pos
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * 12.0)
	vis.polygon = pts
	vis.color = Color(0.55, 0.85, 1.0, 0.9)
	add_child(vis)
	return vis


# ── 능력 오브 (습득 진행) ────────────────────────────────────────

func _check_orbs() -> void:
	# 플레이어 근접 시 오브 습득 — 능력 ON·GameState 영구 기록·토스트·오브 소멸.
	if _orbs.is_empty():
		return
	var p := _player.global_position
	for i in range(_orbs.size() - 1, -1, -1):
		var orb: Dictionary = _orbs[i]
		if p.distance_to(orb["pos"]) < ORB_RADIUS:
			_grant_orb(orb)
			_orbs.remove_at(i)


func _grant_orb(orb: Dictionary) -> void:
	for key in orb["grants"]:
		var k := String(key)
		if not GameState.abilities_granted.has(k):
			GameState.abilities_granted.append(k)
		if _player.abilities.has(k):
			_player.abilities[k] = true
	if not GameState.orbs_taken.has(String(orb["id"])):
		GameState.orbs_taken.append(String(orb["id"]))
	_hud.show_toast(String(orb["toast"]))
	var tw = orb["tween"]
	if tw != null and tw.is_valid():
		tw.kill()
	var node: Node2D = orb["node"]
	if is_instance_valid(node):
		node.queue_free()


func _spawn_orb(def: Dictionary) -> void:
	# 발광 오브(3겹 다이아 + 라벨) + 맥동 modulate tween. 습득 판정은 _check_orbs.
	var root := Node2D.new()
	root.position = def["pos"]
	root.add_child(_orb_diamond(22.0, Color(0.4, 1.0, 0.9, 0.25)))
	root.add_child(_orb_diamond(14.0, Color(0.6, 1.0, 0.95, 0.6)))
	root.add_child(_orb_diamond(7.0, Color(1.0, 1.0, 1.0, 0.95)))
	var lb := Label.new()
	lb.text = String(def["label"])
	lb.position = Vector2(-34.0, -52.0)
	lb.add_theme_font_override("font", _font)
	lb.add_theme_font_size_override("font_size", 15)
	lb.add_theme_color_override("font_color", Color(0.7, 1.0, 0.95))
	root.add_child(lb)
	add_child(root)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(root, "modulate:a", 0.4, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(root, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	_orbs.append({
		"node": root,
		"pos": def["pos"],
		"grants": def["grants"],
		"id": String(def["id"]),
		"toast": String(def["toast"]),
		"tween": tw,
	})


func _orb_diamond(r: float, col: Color) -> Polygon2D:
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(0.0, -r), Vector2(r, 0.0), Vector2(0.0, r), Vector2(-r, 0.0)])
	vis.color = col
	return vis


func _add_visual_rect(rect: Rect2, color: Color) -> void:
	# 충돌 없는 순수 색 표식(게이트 힌트 등).
	var vis := _make_rect_visual(rect.size, color)
	vis.position = rect.position + rect.size / 2.0
	add_child(vis)


# ── 출구 문틀·화살표 (진행 방향 시각 표식) ────────────────────────

func _add_exit_marker(rect: Rect2, arrow: String, color: Color) -> void:
	# 밝은 문틀(테두리) + 진행 방향 화살표 삼각형 — 어디로 나가는지 즉시 보이게.
	var border := Line2D.new()
	border.width = 4.0
	border.default_color = color
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := x0 + rect.size.x
	var y1 := y0 + rect.size.y
	border.points = PackedVector2Array([
		Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1),
		Vector2(x0, y1), Vector2(x0, y0),
	])
	add_child(border)
	var head := Polygon2D.new()
	head.position = rect.position + rect.size / 2.0
	head.polygon = _arrow_points(arrow)
	head.color = color
	add_child(head)


func _arrow_points(dir: String) -> PackedVector2Array:
	var s := 14.0
	match dir:
		"left":
			return PackedVector2Array([
				Vector2(s, -s), Vector2(-s, 0.0), Vector2(s, s)])
		"up":
			return PackedVector2Array([
				Vector2(-s, s), Vector2(0.0, -s), Vector2(s, s)])
		"down":
			return PackedVector2Array([
				Vector2(-s, -s), Vector2(0.0, s), Vector2(s, -s)])
	return PackedVector2Array([Vector2(-s, -s), Vector2(s, 0.0), Vector2(-s, s)])


func _add_sign(pos: Vector2, text: String) -> void:
	var lb := Label.new()
	lb.text = text
	lb.position = pos
	lb.add_theme_font_override("font", _font)
	lb.add_theme_font_size_override("font_size", 15)
	lb.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	add_child(lb)


func _build_bench(pos: Vector2) -> void:
	# 거점 — 코드 생성 벤치(장식) + 근접 안내는 _bench_prompt 가 담당.
	var seat := Polygon2D.new()
	seat.position = pos
	seat.polygon = PackedVector2Array([
		Vector2(-42, -6), Vector2(42, -6), Vector2(42, 4), Vector2(-42, 4)])
	seat.color = Color(0.55, 0.4, 0.28)
	add_child(seat)
	var back := Polygon2D.new()
	back.position = pos
	back.polygon = PackedVector2Array([
		Vector2(-42, -30), Vector2(-34, -30), Vector2(-34, -6), Vector2(-42, -6)])
	back.color = Color(0.48, 0.35, 0.24)
	add_child(back)
	var tag := Label.new()
	tag.text = "거점"
	tag.position = pos + Vector2(-16, -52)
	tag.add_theme_font_override("font", _font)
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	add_child(tag)


func _build_npc(pos: Vector2) -> void:
	# 각인술사 NPC(거점 옆 장식) — combat_arena _build_npc 도형 재사용.
	var npc := Node2D.new()
	npc.position = pos
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-14, -30), Vector2(14, -30), Vector2(14, 30), Vector2(-14, 30)])
	body.color = Color(0.7, 0.55, 1.0)
	npc.add_child(body)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([
		Vector2(0, -48), Vector2(13, -35), Vector2(0, -22), Vector2(-13, -35)])
	gem.color = Color(1.0, 0.9, 0.4)
	npc.add_child(gem)
	var tag := Label.new()
	tag.text = "각인술사"
	tag.position = Vector2(-30, -70)
	tag.add_theme_font_override("font", _font)
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	npc.add_child(tag)
	add_child(npc)


# ── 스폰·카메라·HUD·각인 (combat_arena 재사용) ────────────────────

func _spawn_player(pos: Vector2) -> CharacterBody2D:
	var packed := load("res://scenes/player.tscn") as PackedScene
	var p: CharacterBody2D = null
	if packed != null:
		p = packed.instantiate() as CharacterBody2D
	if p != null:
		print("[진단] player.tscn 인스턴스 성공 — 수직 슬라이스 공유 컨트롤러")
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
	# 버블 등록은 플레이어 존재 후 (register_air_bubble)
	for node in _pending_bubbles:
		p.register_air_bubble(node)
	return p


func _spawn_enemies(defs: Array) -> Array:
	var arr: Array = []
	for d in defs:
		var script := _enemy_script(String(d["type"]))
		if script == null:
			continue
		arr.append(_spawn_enemy(script, d["pos"]))
	return arr


func _enemy_script(kind: String) -> GDScript:
	match kind:
		"dummy":
			return DummyScript
		"walker":
			return WalkerScript
		"shooter":
			return ShooterScript
	push_warning("[진단] 알 수 없는 적 타입: %s" % kind)
	return null


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
	cam.zoom = Vector2(1.5, 1.5)  # §9.1: 960×540 창 → 640×360 월드뷰(스펙). 코드에서 조정.
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


func _setup_slice_ui() -> void:
	# 진행 기록 라벨(구역·발견 N/5) + 거점 안내 — 별도 CanvasLayer(HUD 위 상단 중앙).
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_region_label = _mklabel(
		"", Vector2(330, 6), 16, Color(0.85, 0.92, 1.0))
	layer.add_child(_region_label)
	_bench_prompt = _mklabel(
		"F: 휴식 (회복·세이브·각인)", Vector2(330, 110), 16, Color(1.0, 0.92, 0.6))
	_bench_prompt.visible = false
	layer.add_child(_bench_prompt)
	_region_label.text = "구역: %s   ·   발견 %d/%d" % [
		_room_name, GameState.visited.size(), SliceData.room_count()]


func _mklabel(text: String, pos: Vector2, size: int, col: Color) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.position = pos
	lb.add_theme_font_override("font", _font)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", col)
	return lb


func _entry_pos(entries: Dictionary, entry: String) -> Vector2:
	if entries.has(entry):
		return entries[entry]
	push_warning("[진단] 입장 문 없음: %s — 기본 위치 대체" % entry)
	if entries.size() > 0:
		return entries.values()[0]
	return Vector2(100, 100)
