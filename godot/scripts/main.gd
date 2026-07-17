extends Node2D
## 이동 마법 테스트 방 — 검증 지형 8종·물/기류 존·한국어 팻말·디버그 HUD.
## 4.7 교훈대로 노드는 전부 코드 생성. 존은 Area2D 시각화 + Rect2를
## 플레이어에 주입(경로 조회 없이 안전 판정).

const ROOM_W := 4200.0
const ROOM_H := 1600.0
const CAM_BOTTOM := 1860.0
const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/debug_hud.gd")

var _player: CharacterBody2D
var _hud: CanvasLayer
var _font: SystemFont
var _water_rects: Array[Rect2] = []
var _updraft_rects: Array[Rect2] = []

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.043, 0.051, 0.071))
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	_setup_input()
	_build_room()
	_player = _spawn_player()
	_player.set_zones(_water_rects, _updraft_rects)
	_setup_camera(_player)
	_hud = _setup_hud(_player)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var code: int = event.physical_keycode
	if code == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/launcher.tscn")
	elif code == KEY_R:
		_player.respawn()
		_hud.show_toast("리스폰")
	elif code == KEY_F:
		_player.refill_mana()
		_hud.show_toast("마나 리필")
	elif code >= KEY_1 and code <= KEY_9:
		_toggle_ability(code - KEY_1)

func _toggle_ability(idx: int) -> void:
	var keys: Array = PlayerScript.ABILITY_KEYS
	if idx < 0 or idx >= keys.size():
		return
	var key: String = keys[idx]
	var now: bool = _player.toggle_ability(key)
	var label: String = PlayerScript.ABILITY_LABELS[key]
	var mark := "ON" if now else "OFF"
	_hud.show_toast("%s  %s" % [label, mark])

func _setup_input() -> void:
	_add_key(&"move_left", KEY_LEFT)
	_add_key(&"move_right", KEY_RIGHT)
	_add_key(&"jump", KEY_Z)
	_add_key(&"jump", KEY_SPACE)
	_add_key(&"dash", KEY_C)
	_add_key(&"dash", KEY_SHIFT)
	_add_key(&"cast", KEY_X)
	_add_key(&"fly_up", KEY_UP)
	_add_key(&"move_down", KEY_DOWN)

func _add_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

func _build_room() -> void:
	var wall := Color(0.16, 0.19, 0.27)
	var plat := Color(0.20, 0.24, 0.34)
	# 외곽: 바닥은 물 웅덩이(x 3260~3660)만큼 끊김
	_add_platform(Rect2(20, 1500, 3240, 100), wall)
	_add_platform(Rect2(3660, 1500, 520, 100), wall)
	_add_platform(Rect2(0, 0, 20, ROOM_H), wall)
	_add_platform(Rect2(ROOM_W - 20, 0, 20, ROOM_H), wall)
	_add_platform(Rect2(0, 0, ROOM_W, 20), wall)

	_build_hover(plat)
	_build_double_jump(plat)
	_build_dash(plat)
	_build_wall_run(wall, plat)
	_build_ice_tower(plat)
	_build_water(wall)
	_build_glide_flight(plat)

func _build_hover(plat: Color) -> void:
	# ⑧ 부유: 260px 갭 위에서 X 홀드 체공
	_add_platform(Rect2(300, 1360, 180, 16), plat)
	_add_platform(Rect2(740, 1360, 180, 16), plat)
	_add_sign(Vector2(300, 1290), "부유(3): 공중 X 홀드\n갭 260px 체공")

func _build_double_jump(plat: Color) -> void:
	# ② 이단점프: 단일 점프 불가 높이(180px) 선반
	_add_platform(Rect2(990, 1320, 210, 16), plat)
	_add_sign(Vector2(990, 1250), "이단점프(4): 180px 선반\n단일 점프로는 불가")

func _build_dash(plat: Color) -> void:
	# ① 대시: 240px·380px 갭 (380은 공중 대시 필요)
	_add_platform(Rect2(1280, 1300, 200, 16), plat)
	_add_platform(Rect2(1720, 1300, 200, 16), plat)
	_add_platform(Rect2(2300, 1300, 200, 16), plat)
	_add_sign(Vector2(1280, 1230), "대시(1·2): 240·380 갭\n380은 공중 대시")

func _build_wall_run(wall: Color, plat: Color) -> void:
	# ③ 벽달리기: 높이 500·폭 140 수직 통로
	_add_platform(Rect2(2600, 1000, 20, 500), wall)
	_add_platform(Rect2(2760, 1000, 20, 500), wall)
	_add_platform(Rect2(2780, 1000, 160, 16), plat)
	_add_reward(Vector2(2860, 980))
	_add_sign(Vector2(2560, 920), "벽달리기(5): 벽 향해+위\n좌우벽 교차로 상승")

func _build_ice_tower(plat: Color) -> void:
	# ④ 얼음 발판 고탑: 연속 발판으로 400px 상승
	_add_platform(Rect2(3020, 1080, 200, 16), plat)
	_add_reward(Vector2(3120, 1060))
	_add_sign(Vector2(3000, 1010), "얼음 발판(6): 공중 Z 반복\n420px 상승")

func _build_water(wall: Color) -> void:
	# ⑥ 물 웅덩이: 깊이 300, 바닥에 보상
	_add_platform(Rect2(3260, 1800, 400, 60), wall)
	_add_platform(Rect2(3260, 1500, 20, 300), wall)
	_add_platform(Rect2(3640, 1500, 20, 300), wall)
	var water := Rect2(3280, 1500, 360, 300)
	_add_zone(water, Color(0.2, 0.45, 0.9, 0.35))
	_water_rects.append(water)
	_add_reward(Vector2(3460, 1770))
	_add_sign(Vector2(3300, 1420), "물잠(8): 물에서 방향키\n마나 8/s, 0이면 부상")

func _build_glide_flight(plat: Color) -> void:
	# ⑤ 활공 코스 + 상승기류 / ⑦ 비행 개활지 + 높은 목표
	var updraft := Rect2(3720, 700, 100, 800)
	_add_zone(updraft, Color(0.4, 0.9, 0.5, 0.22))
	_updraft_rects.append(updraft)
	_add_platform(Rect2(3660, 760, 120, 16), plat)
	_add_platform(Rect2(3900, 1120, 140, 16), plat)
	_add_reward(Vector2(3970, 1100))
	_add_platform(Rect2(4000, 420, 150, 16), plat)
	_add_reward(Vector2(4075, 400))
	_add_sign(Vector2(3660, 620), "활공(7): Z 홀드 낙하감속\n초록 기둥=상승기류")
	_add_sign(Vector2(3980, 330), "비행(9): 공중 ↑ 홀드\n마나 12/s, 높은 목표")

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
	# 시각·의미용 Area2D (판정은 주입된 Rect2로)
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
		print("[진단] player.tscn 인스턴스 성공 — 씬 파이프라인 정상")
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
	p.position = Vector2(140, 1440)
	add_child(p)
	return p

func _setup_camera(player: CharacterBody2D) -> void:
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ROOM_W)
	cam.limit_bottom = int(CAM_BOTTOM)
	cam.set("position_smoothing_enabled", true)
	cam.set("position_smoothing_speed", 8.0)
	player.add_child(cam)
	cam.make_current()

func _setup_hud(player: CharacterBody2D) -> CanvasLayer:
	var hud := CanvasLayer.new()
	hud.set_script(HudScript)
	add_child(hud)
	hud.bind(player)
	return hud
