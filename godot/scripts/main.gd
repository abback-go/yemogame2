extends Node2D
## 파이프라인 실험용 메인 씬 — 입력 맵 등록, 테스트 방 생성, 카메라 경계 설정.
## 방 지오메트리는 코드로 생성 (본개발에서는 .tscn/타일맵으로 전환 예정).

const ROOM_W := 1920.0
const ROOM_H := 1080.0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.043, 0.051, 0.071))
	_setup_input()
	_build_room()
	_setup_camera()
	_setup_ui()

func _setup_input() -> void:
	# 에디터 없이 코드로 입력 맵 등록 — HTML 프로토타입과 같은 키
	_add_key(&"move_left", KEY_LEFT)
	_add_key(&"move_right", KEY_RIGHT)
	_add_key(&"jump", KEY_Z)
	_add_key(&"jump", KEY_SPACE)
	_add_key(&"dash", KEY_C)
	_add_key(&"dash", KEY_SHIFT)

func _add_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

func _build_room() -> void:
	var wall := Color(0.16, 0.19, 0.27)
	var plat := Color(0.20, 0.24, 0.34)
	# 바닥·벽·천장
	_add_platform(Rect2(0, 1000, ROOM_W, 80), wall)
	_add_platform(Rect2(0, 0, 20, ROOM_H), wall)
	_add_platform(Rect2(ROOM_W - 20, 0, 20, ROOM_H), wall)
	_add_platform(Rect2(0, 0, ROOM_W, 20), wall)
	# 오르막 사다리 (상승폭 ≤110px — 점프 -620 기준 검증치)
	_add_platform(Rect2(500, 890, 200, 16), plat)
	_add_platform(Rect2(820, 780, 200, 16), plat)
	_add_platform(Rect2(500, 670, 200, 16), plat)
	# 질풍보 거리 테스트: 같은 높이, 240px 갭 (달리기 점프로는 애매, 질풍보로 쾌적)
	_add_platform(Rect2(1150, 670, 180, 16), plat)
	_add_platform(Rect2(1570, 670, 180, 16), plat)

func _add_platform(rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	var vis := Polygon2D.new()
	var hw := rect.size.x / 2.0
	var hh := rect.size.y / 2.0
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	vis.color = color
	body.add_child(vis)
	add_child(body)

func _setup_camera() -> void:
	var cam: Camera2D = $Player/Camera2D
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(ROOM_W)
	cam.limit_bottom = int(ROOM_H)

func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	var label := Label.new()
	label.text = "←→ 이동   Z/Space 점프   C/Shift 질풍보\n파이프라인 실험 — 조작 수치는 HTML 프로토타입 이식"
	label.position = Vector2(16, 12)
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", 16)
	ui.add_child(label)
	add_child(ui)
