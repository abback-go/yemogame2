class_name RoomBuilder
extends RefCounted
## 방 그레이박스 공용 빌더 — slice_room.gd 의 코드 생성 헬퍼(_add_platform·_add_zone·
## _add_sign·출구 문틀/화살표·NPC·거점 도형)를 순수 정적 함수로 추출한 모듈.
## school_room.gd 가 이 모듈로 지형·존·팻말·출구·막힌 문·NPC·거점을 조립한다(DRY).
## 4.7 조립 규칙: 노드 전부 코드 생성, $경로 조회 없음. 모든 함수는 parent 에 자식을 붙인다.
## 좌표계: 방 원점(0,0) 좌상단, y 아래로 증가.

const EXIT_COLOR := Color(0.3, 1.0, 1.0)  # 열린 출구 문틀·화살표(시안)
const BLOCKED_COLOR := Color(0.5, 0.52, 0.58)  # 막힌 문 문틀·라벨(회색)
const WALL_COLOR := Color(0.16, 0.19, 0.27)
const PLAT_COLOR := Color(0.20, 0.24, 0.34)


static func make_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	return f


static func add_platform(parent: Node2D, rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	body.add_child(make_rect_visual(rect.size, color))
	parent.add_child(body)


static func add_zone(parent: Node2D, rect: Rect2, color: Color) -> void:
	# 충돌 있는 감지용 Area2D. 학교 그레이박스는 물/기류가 없어 사실상 미사용이나
	# slice 스키마 호환을 위해 유지한다.
	var area := Area2D.new()
	area.position = rect.position + rect.size / 2.0
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	area.add_child(shape)
	area.add_child(make_rect_visual(rect.size, color))
	parent.add_child(area)


static func add_visual_rect(parent: Node2D, rect: Rect2, color: Color) -> void:
	# 충돌 없는 순수 색 표식(각인 문양·시범용 구덩이 등 장식).
	var vis := make_rect_visual(rect.size, color)
	vis.position = rect.position + rect.size / 2.0
	parent.add_child(vis)


static func make_rect_visual(size: Vector2, color: Color) -> Polygon2D:
	var vis := Polygon2D.new()
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	vis.color = color
	return vis


static func mklabel(
	parent: Node2D, font: SystemFont, text: String, pos: Vector2, size: int, col: Color
) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.position = pos
	lb.add_theme_font_override("font", font)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", col)
	parent.add_child(lb)
	return lb


static func add_sign(parent: Node2D, font: SystemFont, pos: Vector2, text: String) -> void:
	mklabel(parent, font, text, pos, 15, Color(0.95, 0.9, 0.6))


static func add_exit_marker(
	parent: Node2D, font: SystemFont, rect: Rect2, arrow: String, dest_name: String
) -> void:
	# 열린 출구: 시안 문틀(테두리) + 진행 방향 화살표 + 목적지 방 이름 라벨.
	_frame(parent, rect, EXIT_COLOR)
	_arrow_head(parent, rect.position + rect.size / 2.0, arrow, EXIT_COLOR)
	var lb := mklabel(
		parent, font, "→ %s" % dest_name,
		Vector2(rect.position.x - 20.0, rect.position.y - 26.0), 14, EXIT_COLOR)
	lb.add_theme_color_override("font_color", Color(0.7, 1.0, 1.0))


static func add_blocked_door(
	parent: Node2D, font: SystemFont, rect: Rect2, arrow: String, name_kr: String
) -> void:
	# 막힌 문(미구현 스텁): 회색 문틀 + 화살표 + "미구현: <이름>" 라벨. 통과 시 토스트만.
	_frame(parent, rect, BLOCKED_COLOR)
	_arrow_head(parent, rect.position + rect.size / 2.0, arrow, BLOCKED_COLOR)
	mklabel(
		parent, font, "미구현: %s" % name_kr,
		Vector2(rect.position.x - 20.0, rect.position.y - 26.0), 14, BLOCKED_COLOR)


static func _frame(parent: Node2D, rect: Rect2, color: Color) -> void:
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
	parent.add_child(border)


static func _arrow_head(parent: Node2D, center: Vector2, dir: String, color: Color) -> void:
	var head := Polygon2D.new()
	head.position = center
	head.polygon = arrow_points(dir)
	head.color = color
	parent.add_child(head)


static func arrow_points(dir: String) -> PackedVector2Array:
	var s := 14.0
	match dir:
		"left":
			return PackedVector2Array([Vector2(s, -s), Vector2(-s, 0.0), Vector2(s, s)])
		"up":
			return PackedVector2Array([Vector2(-s, s), Vector2(0.0, -s), Vector2(s, s)])
		"down":
			return PackedVector2Array([Vector2(-s, -s), Vector2(0.0, s), Vector2(s, -s)])
	return PackedVector2Array([Vector2(-s, -s), Vector2(s, 0.0), Vector2(-s, s)])


static func build_bench(parent: Node2D, font: SystemFont, pos: Vector2) -> void:
	# 거점 — 코드 생성 벤치(장식). 근접 안내는 school_room 의 _bench_prompt 가 담당.
	var seat := Polygon2D.new()
	seat.position = pos
	seat.polygon = PackedVector2Array([
		Vector2(-42, -6), Vector2(42, -6), Vector2(42, 4), Vector2(-42, 4)])
	seat.color = Color(0.55, 0.4, 0.28)
	parent.add_child(seat)
	var back := Polygon2D.new()
	back.position = pos
	back.polygon = PackedVector2Array([
		Vector2(-42, -30), Vector2(-34, -30), Vector2(-34, -6), Vector2(-42, -6)])
	back.color = Color(0.48, 0.35, 0.24)
	parent.add_child(back)
	mklabel(parent, font, "거점", pos + Vector2(-16, -52), 14, Color(1.0, 0.92, 0.6))


static func build_npc(
	parent: Node2D, font: SystemFont, pos: Vector2, label: String, body_color: Color
) -> void:
	# NPC 그레이박스 — 도형(몸통+보석) + 한글 라벨. 대사 UI는 이번 범위 밖(라벨만).
	var npc := Node2D.new()
	npc.position = pos
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-14, -30), Vector2(14, -30), Vector2(14, 30), Vector2(-14, 30)])
	body.color = body_color
	npc.add_child(body)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([
		Vector2(0, -48), Vector2(13, -35), Vector2(0, -22), Vector2(-13, -35)])
	gem.color = Color(1.0, 0.9, 0.4)
	npc.add_child(gem)
	var tag := Label.new()
	tag.text = label
	tag.position = Vector2(-40, -70)
	tag.add_theme_font_override("font", font)
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	npc.add_child(tag)
	parent.add_child(npc)
