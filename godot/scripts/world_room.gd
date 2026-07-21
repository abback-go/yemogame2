extends Node2D
## 연속 월드 드라이버 — 입학(이동 학습)→학교(허브)→전투 구역을 하나의 방 그래프로 잇는다.
## school_room·slice_room·combat_arena 를 통합: 방 전환 = 씬 재로드(get_tree().reload_current_scene())
## + GameState.world_* 지속. 방 하나를 WorldData.get_room(GameState.world_room) 로 코드 생성.
## 방 dict 의 선택 키(orbs·essences·enemies·water·bench·npcs·free_move 등)에 따라
## 학습/허브/전투 방이 된다. 4.7 조립: 노드 전부 코드 생성, 참조 메서드 주입, 지형은 RoomBuilder.

const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/debug_hud.gd")
const EngravePanelScript := preload("res://scripts/engrave_panel.gd")
const LearnPanelScript := preload("res://scripts/learn_panel.gd")
const DummyScript := preload("res://scripts/enemies/dummy.gd")
const WalkerScript := preload("res://scripts/enemies/walker.gd")
const ShooterScript := preload("res://scripts/enemies/shooter.gd")
const BruteScript := preload("res://scripts/enemies/brute.gd")
const CasterScript := preload("res://scripts/enemies/caster.gd")

const BENCH_RADIUS := 70.0
const NPC_RADIUS := 60.0
const ORB_RADIUS := 44.0
const ESSENCE_RADIUS := 40.0
const SPAWN_GRACE := 0.25
const BLOCKED_TOAST_CD := 1.6

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
var _learn: LearnPanel = null
var _enemies: Array = []
var _exits: Array = []
var _blocked: Array = []
var _orbs: Array = []
var _essences: Array = []
var _professors: Array[Vector2] = []
var _pending_bubbles: Array[Node2D] = []
var _water_rects: Array[Rect2] = []
var _updraft_rects: Array[Rect2] = []
var _room_id := "hub_plaza"
var _room_name := ""
var _room_size := Vector2(1600, 720)
var _free_move := false
var _has_bench := false
var _bench_pos := Vector2.ZERO
var _region_label: Label
var _bench_prompt: Label
var _reloading := false
var _grace_t := 0.0
var _blocked_toast_t := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.06, 0.09))
	_font = RoomBuilder.make_font()
	_setup_input()
	_room_id = GameState.world_room
	var room := WorldData.get_room(_room_id)
	_room_name = String(room["name"])
	_room_size = room["size"]
	_free_move = bool(room.get("free_move", false))
	_mark_visited(_room_id)
	_build_room(room)
	_player = _spawn_player(_entry_pos(room["entries"], GameState.world_entry))
	_player.collision_layer = 2  # 적(레이어4)·플레이어 물리 충돌 분리(발판=1)
	_inject_player_state()
	_player.died.connect(_on_player_death)
	_apply_abilities()
	_player.set_zones(_water_rects, _updraft_rects)
	_player.set_blade_element(GameState.arena_blade_element)
	_enemies = _spawn_enemies(room.get("enemies", []))
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
	_learn = _setup_learn()
	_setup_world_ui()
	_grace_t = SPAWN_GRACE


func _apply_abilities() -> void:
	# free_move 방(허브·전투)=이동기 9종 ON. 오프닝 학습 방=오브로 획득한 것만 ON.
	# 달리기·점프·칼은 abilities 딕셔너리 밖 → 항상 가능(시작 능력).
	if _free_move:
		for key in PlayerScript.ABILITY_KEYS:
			_player.abilities[key] = true
		return
	for key in PlayerScript.ABILITY_KEYS:
		_player.abilities[key] = false
	for key in GameState.world_abilities_granted:
		var k := String(key)
		if _player.abilities.has(k):
			_player.abilities[k] = true


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
	_check_orbs()
	_check_essences()
	_update_bench_prompt()


func _check_exits() -> void:
	var p := _player.global_position
	for ex in _exits:
		if (ex["rect"] as Rect2).has_point(p):
			_go_to(String(ex["to"]), String(ex["entry"]))
			return


func _check_blocked() -> void:
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
	_bench_prompt.visible = near and not _panel_open()


func _panel_open() -> bool:
	return _engrave.is_open() or _learn.is_open()


# ── 방 전환·지속 (GameState.world_*) ─────────────────────────────

func _go_to(room: String, entry: String) -> void:
	if _reloading:
		return
	_reloading = true
	_save_player_state()
	GameState.world_room = room
	GameState.world_entry = entry
	get_tree().reload_current_scene()


func _on_player_death() -> void:
	# 사망·낙사 — 거점 방으로 재로드·풀회복. 각인은 유지.
	if _reloading:
		return
	_reloading = true
	GameState.world_skill_slots[0] = _player.skill_slots[0]
	GameState.world_skill_slots[1] = _player.skill_slots[1]
	GameState.world_mana = PlayerScript.MANA_MAX
	GameState.world_health = PlayerScript.HEALTH_MAX
	GameState.world_oxygen = PlayerScript.OXYGEN_MAX
	GameState.world_room = GameState.world_respawn_room
	GameState.world_entry = "bench"
	get_tree().reload_current_scene()


func _inject_player_state() -> void:
	_player.mana = GameState.world_mana
	_player.health = GameState.world_health
	_player.oxygen = GameState.world_oxygen
	_player.skill_slots[0] = GameState.world_skill_slots[0]
	_player.skill_slots[1] = GameState.world_skill_slots[1]


func _save_player_state() -> void:
	GameState.world_mana = _player.mana
	GameState.world_health = _player.health
	GameState.world_oxygen = _player.oxygen
	GameState.world_skill_slots[0] = _player.skill_slots[0]
	GameState.world_skill_slots[1] = _player.skill_slots[1]


func _rest_at_bench() -> void:
	# 거점 F: 회복 + 세이브(리스폰 지점 갱신) + 각인 패널.
	_player.mana = PlayerScript.MANA_MAX
	_player.health = PlayerScript.HEALTH_MAX
	_player.oxygen = PlayerScript.OXYGEN_MAX
	GameState.world_respawn_room = _room_id
	_save_player_state()
	_hud.show_toast("휴식 — 회복·세이브 완료")
	_engrave.open(_player)


func _mark_visited(id: String) -> void:
	if not GameState.visited_world.has(id):
		GameState.visited_world.append(id)


# ── 입력 (school/slice/arena 키맵 동일 + 정수·디버그) ─────────────

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
		_interact()
	elif code == KEY_1:
		_cycle_essence()
	elif code == KEY_M:
		GameState.arena_material += 30
		_hud.show_toast("[디버그] 마력 결정 +30 (총 %d)" % GameState.arena_material)
	elif code == KEY_L:
		_debug_bootstrap()


func _interact() -> void:
	# F: 거점(회복·세이브·각인) 또는 근접 교수(수업) 오픈.
	if _panel_open():
		return
	if _has_bench and _player.global_position.distance_to(_bench_pos) < BENCH_RADIUS:
		_rest_at_bench()
		return
	for pos in _professors:
		if _player.global_position.distance_to(pos) < NPC_RADIUS:
			_learn.open(_player)
			return


func _cycle_essence() -> void:
	var owned: Array = GameState.arena_elements
	if owned.size() <= 1:
		_hud.show_toast("보유 정수 없음 — 정수를 먼저 획득하세요")
		return
	var cur: int = owned.find(_player.blade_element)
	if cur < 0:
		cur = 0
	var nxt: String = owned[(cur + 1) % owned.size()]
	_player.set_blade_element(nxt)
	GameState.arena_blade_element = nxt
	_hud.show_toast("정수 장착: %s" % Elements.label(nxt))


func _debug_bootstrap() -> void:
	for el in ["불", "물"]:
		if not (el in GameState.arena_elements):
			GameState.arena_elements.append(el)
	for id in SkillDB.ids():
		if not (id in GameState.arena_learned):
			GameState.arena_learned.append(id)
	GameState.arena_material += 100
	_hud.show_toast("[디버그] 정수2·전스킬 습득·재화+100")


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


# ── 방 빌드 (RoomBuilder 공용 헬퍼 + 선택 키) ─────────────────────

func _build_room(room: Dictionary) -> void:
	_build_outer_walls(_room_size)
	for r in room["solids"]:
		RoomBuilder.add_platform(self, r, RoomBuilder.WALL_COLOR)
	for r in room["plats"]:
		RoomBuilder.add_platform(self, r, RoomBuilder.PLAT_COLOR)
	for r in room.get("water", []):
		var wr: Rect2 = r
		RoomBuilder.add_zone(self, wr, Color(0.2, 0.45, 0.9, 0.35))
		_water_rects.append(wr)
	for r in room.get("updraft", []):
		var ur: Rect2 = r
		RoomBuilder.add_zone(self, ur, Color(0.4, 0.9, 0.5, 0.22))
		_updraft_rects.append(ur)
	for pos in room.get("bubbles", []):
		_pending_bubbles.append(_make_air_bubble(pos))
	for d in room.get("decos", []):
		RoomBuilder.add_visual_rect(self, d["rect"], d["color"])
	for pos in room.get("rewards", []):
		_add_reward(pos)
	for s in room.get("signs", []):
		RoomBuilder.add_sign(self, _font, s["pos"], String(s["text"]))
	for n in room.get("npcs", []):
		RoomBuilder.build_npc(self, _font, n["pos"], String(n["label"]), n["color"])
		if String(n.get("kind", "deco")) == "professor":
			_professors.append(n["pos"])
	for od in room.get("orbs", []):
		if not GameState.world_orbs_taken.has(String(od["id"])):
			_spawn_orb(od)
	for es in room.get("essences", []):
		_spawn_essence(es)
	_blocked = []
	for bd in room.get("blocked", []):
		RoomBuilder.add_blocked_door(
			self, _font, bd["rect"], String(bd["arrow"]), String(bd["name"]))
		_blocked.append({"rect": bd["rect"], "name": String(bd["name"])})
	_exits = room["exits"]
	for ex in _exits:
		RoomBuilder.add_exit_marker(
			self, _font, ex["rect"], String(ex.get("arrow", "right")),
			WorldData.room_name(String(ex["to"])))
	if room.has("bench"):
		_has_bench = true
		_bench_pos = room["bench"]
		RoomBuilder.build_bench(self, _font, _bench_pos)


func _build_outer_walls(size: Vector2) -> void:
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


# ── 능력 오브 (오프닝 학습 — slice 메커니즘) ─────────────────────

func _check_orbs() -> void:
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
		if not GameState.world_abilities_granted.has(k):
			GameState.world_abilities_granted.append(k)
		if _player.abilities.has(k):
			_player.abilities[k] = true
	if not GameState.world_orbs_taken.has(String(orb["id"])):
		GameState.world_orbs_taken.append(String(orb["id"]))
	_hud.show_toast(String(orb["toast"]))
	var tw = orb["tween"]
	if tw != null and tw.is_valid():
		tw.kill()
	var node: Node2D = orb["node"]
	if is_instance_valid(node):
		node.queue_free()


func _spawn_orb(def: Dictionary) -> void:
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


# ── 속성 정수 픽업 (arena 메커니즘) ──────────────────────────────

func _check_essences() -> void:
	for e in _essences:
		if e["taken"]:
			continue
		if _player.global_position.distance_to(e["pos"]) < ESSENCE_RADIUS:
			e["taken"] = true
			e["node"].visible = false
			e["tag"].visible = false
			var el: String = e["element"]
			if not (el in GameState.arena_elements):
				GameState.arena_elements.append(el)
			_player.set_blade_element(el)
			GameState.arena_blade_element = el
			_hud.show_toast("%s의 정수 획득! (1키로 장착 전환)" % Elements.label(el))


func _spawn_essence(def: Dictionary) -> void:
	var element := String(def["element"])
	var pos: Vector2 = def["pos"]
	var col := Elements.color_of(element)
	var vis := Polygon2D.new()
	vis.position = pos
	vis.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(12, 0), Vector2(0, 16), Vector2(-12, 0)])
	vis.color = col
	add_child(vis)
	var tag := Label.new()
	tag.text = "%s의 정수" % Elements.label(element)
	tag.position = pos + Vector2(-28, -44)
	tag.add_theme_font_override("font", _font)
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", col)
	add_child(tag)
	_essences.append(
		{"node": vis, "tag": tag, "pos": pos, "element": element, "taken": false})


# ── 스폰·카메라·HUD·패널·UI ──────────────────────────────────────

func _spawn_player(pos: Vector2) -> CharacterBody2D:
	var packed := load("res://scenes/player.tscn") as PackedScene
	var p: CharacterBody2D = null
	if packed != null:
		p = packed.instantiate() as CharacterBody2D
	if p != null:
		print("[진단] player.tscn 인스턴스 성공 — 연속 월드 공유 컨트롤러")
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
		"brute":
			return BruteScript
		"caster":
			return CasterScript
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


func _setup_learn() -> LearnPanel:
	var panel: LearnPanel = LearnPanelScript.new()
	add_child(panel)
	return panel


func _setup_world_ui() -> void:
	# 진행 기록(구역·발견 N/총) + 거점 안내 — 별도 CanvasLayer(HUD 위 상단 중앙).
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_region_label = RoomBuilder.mklabel(
		layer, _font, "", Vector2(330, 6), 16, Color(0.85, 0.92, 1.0))
	_bench_prompt = RoomBuilder.mklabel(
		layer, _font, "F: 휴식 (회복·세이브·각인)", Vector2(330, 110), 16,
		Color(1.0, 0.92, 0.6))
	_bench_prompt.visible = false
	_region_label.text = "구역: %s   ·   발견 %d/%d" % [
		_room_name, GameState.visited_world.size(), WorldData.room_count()]


func _entry_pos(entries: Dictionary, entry: String) -> Vector2:
	if entries.has(entry):
		return entries[entry]
	push_warning("[진단] 입장 문 없음: %s — 기본 위치 대체" % entry)
	if entries.size() > 0:
		return entries.values()[0]
	return Vector2(100, 100)
