extends Node2D
## 전투 아레나 (combat-spec §7) — 평지 원룸 + 발판 2~3개, 3종 더미 적,
## 카메라·주스·전투 HUD. 4.7 조립 규칙대로 노드는 전부 코드 생성,
## 참조는 메서드 주입(set_enemies·set_juice·set_target). main.gd 패턴 미러.

const ROOM_W := 1680.0
const ROOM_H := 720.0
const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/debug_hud.gd")
const DummyScript := preload("res://scripts/enemies/dummy.gd")
const WalkerScript := preload("res://scripts/enemies/walker.gd")
const ShooterScript := preload("res://scripts/enemies/shooter.gd")

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
		_player.refill_mana()
		_hud.show_toast("마나 리필")

func _setup_input() -> void:
	# 이동 키(movement-spec v2.1) + 전투 키(combat-spec §1) 등록
	_add_key(&"move_left", KEY_LEFT)
	_add_key(&"move_right", KEY_RIGHT)
	_add_key(&"jump", KEY_Z)
	_add_key(&"jump", KEY_SPACE)
	_add_key(&"dash", KEY_C)
	_add_key(&"dash", KEY_SHIFT)
	_add_key(&"cast", KEY_X)
	_add_key(&"ice_place", KEY_A)
	_add_key(&"fly", KEY_D)
	_add_key(&"fly_up", KEY_UP)
	_add_key(&"move_down", KEY_DOWN)
	_add_key(&"attack", KEY_J)
	_add_key(&"skill1", KEY_K)
	_add_key(&"skill2", KEY_L)

func _add_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

func _build_room() -> void:
	var wall := Color(0.16, 0.19, 0.27)
	var plat := Color(0.20, 0.24, 0.34)
	# 평지 원룸 외곽
	_add_platform(Rect2(0, 620, ROOM_W, 100), wall)
	_add_platform(Rect2(0, 0, 20, ROOM_H), wall)
	_add_platform(Rect2(ROOM_W - 20, 0, 20, ROOM_H), wall)
	_add_platform(Rect2(0, 0, ROOM_W, 20), wall)
	# 발판 2~3개(부유·대시 회피용 낙차)
	_add_platform(Rect2(300, 470, 200, 18), plat)
	_add_platform(Rect2(740, 380, 220, 18), plat)
	_add_platform(Rect2(1180, 470, 200, 18), plat)
	_add_signs()

func _add_signs() -> void:
	_add_sign(Vector2(70, 250),
		"[전투 트라이얼] 얼음 · 창\n" +
		"J 3타 콤보   K 관통 서리창   L 빙정 폭발\n" +
		"타격=마나 수급, 스킬=마나 소모")
	_add_sign(Vector2(556, 512), "허수아비 — 무한 HP\n콤보·히트스톱·타격감 확인")
	_add_sign(Vector2(1108, 512), "근접 워커 — HP3\n0.5초 예비동작 후 찌르기")
	_add_sign(Vector2(760, 250), "원거리 사수 — HP2\n0.6초 조준 후 느린 투사체")

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

func _make_rect_visual(size: Vector2, color: Color) -> Polygon2D:
	var vis := Polygon2D.new()
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	vis.color = color
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
		print("[진단] player.tscn 인스턴스 성공 — 전투 아레나 공유 컨트롤러")
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
	p.position = Vector2(160, 560)
	add_child(p)
	return p

func _spawn_enemies() -> Array:
	var arr: Array = []
	arr.append(_spawn_enemy(DummyScript, Vector2(620, 560)))
	arr.append(_spawn_enemy(WalkerScript, Vector2(1240, 560)))
	arr.append(_spawn_enemy(ShooterScript, Vector2(880, 300)))
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
	player.add_child(cam)
	cam.make_current()
	return cam

func _setup_hud(player: CharacterBody2D) -> CanvasLayer:
	var hud := CanvasLayer.new()
	hud.set_script(HudScript)
	add_child(hud)
	hud.bind(player)
	return hud
