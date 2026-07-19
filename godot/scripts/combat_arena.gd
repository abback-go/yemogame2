extends Node2D
## v3 전투 아레나 = 각인 테스트맵 — 무속성 마력 칼날 + 각인 2슬롯 손맛 테스트.
## 평지 전투존(적 3종) + 이동 놀이터(벽달리기·상승기류·물잠·발판 갭) + 각인술사 NPC.
## 4.7 조립: 노드 전부 코드 생성, 참조는 메서드 주입(set_enemies·set_zones·register_air_bubble).

const ROOM_W := 2600.0
const ROOM_H := 980.0
const FLOOR_TOP := 700.0
const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/debug_hud.gd")
const EngravePanelScript := preload("res://scripts/engrave_panel.gd")
const DummyScript := preload("res://scripts/enemies/dummy.gd")
const WalkerScript := preload("res://scripts/enemies/walker.gd")
const ShooterScript := preload("res://scripts/enemies/shooter.gd")
const BruteScript := preload("res://scripts/enemies/brute.gd")
const CasterScript := preload("res://scripts/enemies/caster.gd")
const LearnPanelScript := preload("res://scripts/learn_panel.gd")

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
var _enemies: Array = []
var _water_rects: Array[Rect2] = []
var _updraft_rects: Array[Rect2] = []
var _air_bubble: Node2D = null
var _engrave: EngravePanel = null
var _learn: LearnPanel = null
var _npc_pos := Vector2.ZERO
var _prof_pos := Vector2.ZERO
var _bench_pos := Vector2.ZERO
var _essences: Array = []

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.06, 0.09))
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	_setup_input()
	_build_room()
	_player = _spawn_player()
	# 적과 물리 충돌 안 하게 레이어 분리(플레이어=2, 발판=1, 적=4)
	_player.collision_layer = 2
	_enable_all_abilities()
	_player.set_zones(_water_rects, _updraft_rects)
	if _air_bubble != null:
		_player.register_air_bubble(_air_bubble)
	_enemies = _spawn_enemies()
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
	_build_professor()
	_build_essences()
	_build_bench()
	_player.set_blade_element(GameState.arena_blade_element)

func _enable_all_abilities() -> void:
	# 아레나: 이동기 9종 전부 ON — 놀이터에서 전부 시험 가능
	for key in PlayerScript.ABILITY_KEYS:
		_player.abilities[key] = true

func _unhandled_input(event: InputEvent) -> void:
	# 각인 패널 열림 중에는 패널 _input 이 키를 소비 → 여기 오지 않는다.
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
		_try_open_panel()
	elif code == KEY_1:
		_cycle_essence()
	elif code == KEY_M:
		GameState.arena_material += 30
		_hud.show_toast("[디버그] 마력 결정 +30 (총 %d)" % GameState.arena_material)
	elif code == KEY_L:
		_debug_bootstrap()

func _near(pos: Vector2) -> bool:
	return _player.global_position.distance_to(pos) < 60.0

func _setup_input() -> void:
	# v3 아레나 키맵 — 이동 + 각인 스킬 2슬롯 + NPC. 씬 재진입 오염 방지 위해
	# 액션별 이벤트를 지우고 다시 바인딩(_bind). A·S·D 는 전투, Q·E 는 이동 엑스트라.
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

func _build_room() -> void:
	var wall := Color(0.16, 0.19, 0.27)
	var plat := Color(0.20, 0.24, 0.34)
	# 외곽 + 바닥(물웅덩이 x2040~2360 만큼 끊김)
	_add_platform(Rect2(0, 0, 20, ROOM_H), wall)
	_add_platform(Rect2(ROOM_W - 20, 0, 20, ROOM_H), wall)
	_add_platform(Rect2(0, 0, ROOM_W, 20), wall)
	_add_platform(Rect2(20, FLOOR_TOP, 2020, 120), wall)
	_add_platform(Rect2(2360, FLOOR_TOP, ROOM_W - 20 - 2360, 120), wall)
	# 전투존 발판(부유·대시 회피용 낙차)
	_add_platform(Rect2(380, 560, 150, 16), plat)
	_add_platform(Rect2(620, 470, 150, 16), plat)
	_add_platform(Rect2(1180, 560, 160, 16), plat)
	_add_platform(Rect2(2410, 560, 150, 16), plat)
	_build_wall_run(wall, plat)
	_build_updraft(plat)
	_build_water(wall)
	_build_signs()
	_build_npc()

func _build_wall_run(wall: Color, plat: Color) -> void:
	# 벽달리기: 바닥에서 솟은 수직 벽 1쌍(gap 120) + 상단 보상 선반
	_add_platform(Rect2(1480, 360, 20, FLOOR_TOP - 360), wall)
	_add_platform(Rect2(1620, 360, 20, FLOOR_TOP - 360), wall)
	_add_platform(Rect2(1500, 320, 140, 16), plat)
	_add_reward(Vector2(1570, 300))

func _build_updraft(plat: Color) -> void:
	# 상승기류 기둥(활공 상승·비행 시험) + 상단 보상 선반
	var updraft := Rect2(1780, 300, 90, FLOOR_TOP - 300)
	_add_zone(updraft, Color(0.4, 0.9, 0.5, 0.22))
	_updraft_rects.append(updraft)
	_add_platform(Rect2(1740, 280, 150, 16), plat)
	_add_reward(Vector2(1815, 260))

func _build_water(wall: Color) -> void:
	# 물웅덩이(물잠) — 끊긴 바닥 x2040~2360 에 깊이 240 피트 + 산소통
	_add_platform(Rect2(2040, FLOOR_TOP, 20, 260), wall)
	_add_platform(Rect2(2340, FLOOR_TOP, 20, 260), wall)
	_add_platform(Rect2(2040, FLOOR_TOP + 240, 320, 20), wall)
	var water := Rect2(2060, FLOOR_TOP, 280, 240)
	_add_zone(water, Color(0.2, 0.45, 0.9, 0.35))
	_water_rects.append(water)
	_air_bubble = _make_air_bubble(Vector2(2200, FLOOR_TOP + 190))

func _build_signs() -> void:
	_add_sign(Vector2(70, 510),
		"[전투 트라이얼] v3 · 무속성 마력 칼날\n" +
		"A 칼날 콤보(타격=마나 수급)   S 슬롯1   D 슬롯2\n" +
		"스킬은 각인술사(F)에게 각인해야 발동")
	_add_sign(Vector2(70, 610),
		"이동 놀이터 (이동기 9종 ON)\n" +
		"←→ Z점프 C대시 X부유 ↑상승 ↓활공 Q얼음발판 E비행")
	_add_sign(Vector2(700, 600), "허수아비 — 무한 HP\n콤보·히트스톱·타격감 확인")
	_add_sign(Vector2(1060, 600), "근접 워커 — HP3\n0.5초 예비동작 후 찌르기")
	_add_sign(Vector2(840, 560), "원거리 사수 — HP2\n0.6초 조준 후 느린 투사체")
	_add_sign(Vector2(1400, 560), "벽달리기 — 벽 향해+↑\n좌우벽 교차로 상승")
	_add_sign(Vector2(1680, 560), "상승기류 — ↓활공/E비행으로 상승")
	_add_sign(Vector2(2050, 560), "물잠 — 산소→마나→체력 순 소모\n하늘색 방울=산소 리필")
	_add_sign(Vector2(360, 600),
		"교수(F) 수업: 스킬 습득·강화(재화)\n각인술사(F): 배운 스킬 각인")
	_add_sign(Vector2(1140, 600),
		"중형 적(비리스폰) — brute·caster\nbrute 약점:물 / caster 약점:불 (상성)")
	_add_sign(Vector2(60, 660),
		"[디버그] 1:정수 전환  M:재화+30  L:정수2·전스킬·재화")

func _build_npc() -> void:
	# 각인술사 NPC — 코드 생성 도형 + 라벨. 근접(F)으로 각인 패널 오픈.
	_npc_pos = Vector2(330, FLOOR_TOP - 30)
	var npc := Node2D.new()
	npc.position = _npc_pos
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
	tag.text = "각인술사\n(F 대화)"
	tag.position = Vector2(-34, -94)
	tag.add_theme_font_override("font", _font)
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	npc.add_child(tag)
	add_child(npc)

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
	# 시각·의미용 Area2D (판정은 주입된 Rect2로) — main.gd 존 패턴 재사용
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
	# 하늘색 원(12각 근사) — 접촉 시 산소 리필, 5초 뒤 재생성 (main.gd 패턴)
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

func _add_sign(pos: Vector2, text: String) -> void:
	var lb := Label.new()
	lb.text = text
	lb.position = pos
	lb.add_theme_font_override("font", _font)
	lb.add_theme_font_size_override("font_size", 15)
	lb.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	add_child(lb)

func _spawn_player() -> CharacterBody2D:
	var packed := load("res://scenes/player.tscn") as PackedScene
	var p: CharacterBody2D = null
	if packed != null:
		p = packed.instantiate() as CharacterBody2D
	if p != null:
		print("[진단] player.tscn 인스턴스 성공 — v3 전투 아레나 공유 컨트롤러")
	else:
		push_warning("[진단] player.tscn 로드 실패 — 코드 생성으로 대체함")
		p = CharacterBody2D.new()
		p.set_script(PlayerScript)
		var shape := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(20, 34)
		shape.shape = rs
		p.add_child(shape)
	p.name = "Player"
	p.position = Vector2(170, 640)
	add_child(p)
	return p

func _spawn_enemies() -> Array:
	var arr: Array = []
	arr.append(_spawn_enemy(DummyScript, Vector2(760, 640)))
	arr.append(_spawn_enemy(WalkerScript, Vector2(1120, 640)))
	arr.append(_spawn_enemy(ShooterScript, Vector2(960, 420)))
	arr.append(_spawn_enemy(BruteScript, Vector2(1350, 620)))
	arr.append(_spawn_enemy(CasterScript, Vector2(1300, 400)))
	return arr

func _spawn_enemy(script: GDScript, pos: Vector2) -> Node:
	# 위치를 add_child 전에 세팅 → _ready의 home_pos가 정확히 잡힘
	var e: CharacterBody2D = script.new()
	e.position = pos
	add_child(e)
	e.set_target(_player)
	return e

func _setup_camera(player: CharacterBody2D) -> Camera2D:
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ROOM_W)
	cam.limit_bottom = int(ROOM_H)
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

func _build_bench() -> void:
	# 거점(벤치) — F로 체력·마나·산소 완전 회복. 비리스폰 중형 적 전투의 공정성 장치.
	# R(리스폰)과 달리 적 상태·위치를 리셋하지 않아 "치고 빠지며 회복" 루프가 가능.
	_bench_pos = Vector2(250.0, FLOOR_TOP - 10.0)
	var seat := Polygon2D.new()
	seat.position = _bench_pos
	seat.polygon = PackedVector2Array([
		Vector2(-40, -6), Vector2(40, -6), Vector2(40, 4), Vector2(-40, 4)])
	seat.color = Color(0.55, 0.4, 0.28)
	add_child(seat)
	var back := Polygon2D.new()
	back.position = _bench_pos
	back.polygon = PackedVector2Array([
		Vector2(-40, -28), Vector2(-32, -28), Vector2(-32, -6), Vector2(-40, -6)])
	back.color = Color(0.48, 0.35, 0.24)
	add_child(back)
	var lb := Label.new()
	lb.text = "거점 (F 휴식)"
	lb.position = _bench_pos + Vector2(-34, -52)
	lb.add_theme_font_override("font", _font)
	lb.add_theme_font_size_override("font_size", 13)
	lb.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	add_child(lb)

func _rest_at_bench() -> void:
	# 위치·적 상태 그대로 두고 체력·마나·산소만 회복.
	_player.health = PlayerScript.HEALTH_MAX
	_player.refill_mana()
	_hud.show_toast("거점에서 휴식 — 체력·마나 회복")

func _try_open_panel() -> void:
	# F: 근접한 NPC에 따라 각인술사(각인) 또는 교수(수업) 패널을 연다.
	if _engrave == null or _learn == null:
		return
	if _engrave.is_open() or _learn.is_open():
		return
	if _near(_npc_pos):
		_engrave.open(_player)
	elif _near(_prof_pos):
		_learn.open(_player)
	elif _near(_bench_pos):
		_rest_at_bench()

func _cycle_essence() -> void:
	# 1키: 보유한 속성 정수를 순환 장착("무" 포함). 미보유 시 안내.
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
	# L키(디버그): 두 정수 소유·전 스킬 습득·재화 지급 — 아침 테스트 부트스트랩.
	for el in ["불", "물"]:
		if not (el in GameState.arena_elements):
			GameState.arena_elements.append(el)
	for id in SkillDB.ids():
		if not (id in GameState.arena_learned):
			GameState.arena_learned.append(id)
	GameState.arena_material += 100
	_hud.show_toast("[디버그] 정수2·전스킬 습득·재화+100")

func _build_professor() -> void:
	# 교수 NPC — 수업(F): 스킬 습득·강화. 각인술사와 형제 도형(녹색 계열).
	_prof_pos = Vector2(480, FLOOR_TOP - 30)
	var npc := Node2D.new()
	npc.position = _prof_pos
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-14, -30), Vector2(14, -30), Vector2(14, 30), Vector2(-14, 30)])
	body.color = Color(0.45, 0.75, 0.6)
	npc.add_child(body)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([
		Vector2(0, -48), Vector2(13, -35), Vector2(0, -22), Vector2(-13, -35)])
	gem.color = Color(0.7, 1.0, 0.85)
	npc.add_child(gem)
	var tag := Label.new()
	tag.text = "교수\n(F 수업)"
	tag.position = Vector2(-30, -94)
	tag.add_theme_font_override("font", _font)
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color(0.75, 1.0, 0.85))
	npc.add_child(tag)
	add_child(npc)

func _build_essences() -> void:
	# 속성 정수 픽업 2종 — 접촉 시 보유·즉시 장착. 1키로 순환 전환. 아레나 테스트용.
	_essences = []
	_essences.append(_make_essence(Vector2(620, FLOOR_TOP - 40), "불"))
	_essences.append(_make_essence(Vector2(1180, FLOOR_TOP - 40), "물"))

func _make_essence(pos: Vector2, element: String) -> Dictionary:
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
	return {"node": vis, "tag": tag, "pos": pos, "element": element, "taken": false}

func _check_essence_pickup() -> void:
	for e in _essences:
		if e["taken"]:
			continue
		if _player.global_position.distance_to(e["pos"]) < 40.0:
			e["taken"] = true
			e["node"].visible = false
			e["tag"].visible = false
			var el: String = e["element"]
			if not (el in GameState.arena_elements):
				GameState.arena_elements.append(el)
			_player.set_blade_element(el)
			GameState.arena_blade_element = el
			_hud.show_toast("%s의 정수 획득! (1키로 장착 전환)" % Elements.label(el))

func _process(_delta: float) -> void:
	if _player == null:
		return
	_check_essence_pickup()
