extends Node2D
## 월드맵 뷰어 — data/world_map.json을 읽어 지역/방/연결을 그린다.
## 조작: 화살표·WASD 이동, 휠·＋－ 줌, 클릭 방 상세, Q/E 진행 단계, Esc 메뉴로.

const STAGE_NAMES := [
	"0 시작 킷(달리기·점프·대시·부유)", "1 +이단점프", "2 +벽달리기",
	"3 +얼음 발판", "4 +활공", "5 +물잠", "6 +비행",
]

var rooms: Array = []
var regions: Array = []
var edges: Array = []
var by_id: Dictionary = {}
var reg_by_id: Dictionary = {}

var cam_pos := Vector2.ZERO
var zoom := 0.55
var stage_max := 6
var selected: Dictionary = {}

var ui_font: SystemFont
var hud: Label
var info: Label

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.043, 0.051, 0.071))
	var txt := FileAccess.get_file_as_string("res://data/world_map.json")
	var parsed = JSON.parse_string(txt)
	if parsed == null:
		push_error("[진단] world_map.json 로드/파싱 실패")
		return
	rooms = parsed.get("rooms", [])
	regions = parsed.get("regions", [])
	edges = parsed.get("edges", [])
	for r in rooms:
		by_id[r["id"]] = r
	for g in regions:
		reg_by_id[g["id"]] = g
	if by_id.has("sch_plaza"):
		cam_pos = Vector2(by_id["sch_plaza"]["x"], by_id["sch_plaza"]["y"])
	_setup_ui()
	queue_redraw()

func _setup_ui() -> void:
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	var layer := CanvasLayer.new()
	hud = Label.new()
	hud.position = Vector2(14, 10)
	hud.add_theme_font_override("font", ui_font)
	hud.add_theme_font_size_override("font_size", 14)
	layer.add_child(hud)
	info = Label.new()
	info.position = Vector2(14, 64)
	info.add_theme_font_override("font", ui_font)
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	layer.add_child(info)
	add_child(layer)
	_refresh_hud()

func _refresh_hud() -> void:
	var head := "🗺 대협곡 세계 — %d개 지역 · %d방" % [regions.size(), rooms.size()]
	var stage_line := "    |    진행 단계 %s  (Q/E로 변경)" % STAGE_NAMES[stage_max]
	hud.text = head + stage_line + "\n화살표·WASD 이동 · 휠/＋－ 줌 · 방 클릭=상세 · Esc=메뉴"

func w2s(p: Vector2) -> Vector2:
	return (p - cam_pos) * zoom + get_viewport_rect().size / 2.0

func s2w(p: Vector2) -> Vector2:
	return (p - get_viewport_rect().size / 2.0) / zoom + cam_pos

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): dir.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): dir.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): dir.y += 1
	if dir != Vector2.ZERO:
		cam_pos += dir.normalized() * 700.0 / zoom * delta
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = minf(zoom * 1.12, 4.0); queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = maxf(zoom / 1.12, 0.12); queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_click(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_EQUAL, KEY_KP_ADD:
				zoom = minf(zoom * 1.25, 4.0); queue_redraw()
			KEY_MINUS, KEY_KP_SUBTRACT:
				zoom = maxf(zoom / 1.25, 0.12); queue_redraw()
			KEY_Q:
				stage_max = maxi(stage_max - 1, 0); _refresh_hud(); queue_redraw()
			KEY_E:
				stage_max = mini(stage_max + 1, 6); _refresh_hud(); queue_redraw()
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://scenes/launcher.tscn")

func _click(screen_pos: Vector2) -> void:
	var wp := s2w(screen_pos)
	var best: Dictionary = {}
	var bd := 1e18
	for r in rooms:
		var d: float = Vector2(r["x"], r["y"]).distance_to(wp)
		if d < bd:
			bd = d; best = r
	if bd * zoom < 24.0 and not best.is_empty():
		selected = best
		var g: Dictionary = reg_by_id[best["region"]]
		var lines := "▶ %s   [%s · %s · 개방 %d단계]\n%s" % [
			best["name"], g["name"], str(best["type"]), int(best["stage"]), best["concept"]]
		for e in best["exits"]:
			var t: Dictionary = by_id.get(e["to"], {})
			var gate: String = "" if e["gate"] == "none" else " 〔" + e["gate"] + "〕"
			var ow: String = " (일방)" if e.get("oneway", false) else ""
			lines += "\n   → " + (t.get("name", e["to"])) + gate + ow
		info.text = lines
		queue_redraw()

func _draw() -> void:
	# 지역 박스
	for g in regions:
		var b: Array = g["bounds"]
		var col := Color.html(g["color"])
		var p1 := w2s(Vector2(b[0] - 34, b[1] - 34))
		var p2 := w2s(Vector2(b[2] + 34, b[3] + 34))
		draw_rect(Rect2(p1, p2 - p1), Color(col.r, col.g, col.b, 0.07))
		draw_rect(Rect2(p1, p2 - p1), Color(col.r, col.g, col.b, 0.35), false, 1.0)
		draw_string(ui_font, p1 + Vector2(8, 18), g["name"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(col.r, col.g, col.b, 0.95))
	# 간선
	for e in edges:
		var a: Dictionary = by_id.get(e["a"], {})
		var b2: Dictionary = by_id.get(e["b"], {})
		if a.is_empty() or b2.is_empty():
			continue
		var pa := w2s(Vector2(a["x"], a["y"]))
		var pb := w2s(Vector2(b2["x"], b2["y"]))
		var dim: bool = int(a["stage"]) > stage_max or int(b2["stage"]) > stage_max
		var alpha := 0.08 if dim else (0.8 if e["cross"] else 0.4)
		var col := Color(0.62, 0.68, 0.82, alpha)
		if e["gate"] != "none":
			col = Color(0.91, 0.78, 0.4, alpha)
		var width: float = 2.0 if e["cross"] else 1.2
		if e["gate"] != "none":
			draw_dashed_line(pa, pb, col, width, 6.0)
		else:
			draw_line(pa, pb, col, width)
		if e.get("oneway", false):
			var mid := (pa + pb) / 2.0
			var ang := (pb - pa).angle()
			var pts := PackedVector2Array([
				mid + Vector2(7, 0).rotated(ang),
				mid + Vector2(7, 0).rotated(ang + 2.6),
				mid + Vector2(7, 0).rotated(ang - 2.6),
			])
			draw_colored_polygon(pts, col)
	# 방
	for r in rooms:
		var g: Dictionary = reg_by_id[r["region"]]
		var col := Color.html(g["color"])
		if int(r["stage"]) > stage_max:
			col.a = 0.14
		var p := w2s(Vector2(r["x"], r["y"]))
		var rad: float = {"S": 6.0, "M": 8.0, "L": 11.0, "XL": 14.0}.get(r["size"], 8.0)
		rad *= clampf(zoom, 0.6, 1.4)
		var t: String = r["type"]
		if t == "boss" or t == "miniboss":
			var k := rad * (1.5 if t == "boss" else 1.1)
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(0, -k), p + Vector2(k, 0), p + Vector2(0, k), p + Vector2(-k, 0),
			]), col)
		elif t == "town" or t == "hub":
			draw_rect(Rect2(p - Vector2(rad, rad), Vector2(rad * 2, rad * 2)), col)
		else:
			draw_circle(p, rad, col)
		if (r["flags"] as Array).has("bench"):
			draw_circle(p, maxf(rad * 0.35, 2.0), Color(0.04, 0.05, 0.07, col.a))
		if (r["flags"] as Array).has("gondola") or (r["flags"] as Array).has("rail"):
			draw_arc(p, rad + 4.0, 0.0, TAU, 24, Color(1, 1, 1, col.a * 0.9), 1.4)
		if not selected.is_empty() and selected["id"] == r["id"]:
			draw_arc(p, rad + 7.0, 0.0, TAU, 24, Color(1, 0.9, 0.4, 0.95), 2.0)
		if zoom > 0.85:
			draw_string(ui_font, p + Vector2(-40, rad + 14), r["name"],
				HORIZONTAL_ALIGNMENT_CENTER, 80, 10, Color(0.87, 0.9, 0.95, col.a))
