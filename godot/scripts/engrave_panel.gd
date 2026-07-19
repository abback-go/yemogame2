class_name EngravePanel
extends CanvasLayer
## v3 각인술사 모달 패널 — 테스트 아레나의 각인 접점.
## F로 열리며, 열린 동안 player.input_locked 로 이동/전투 입력을 얼린다.
## 조작: ←/→ 슬롯 선택 · ↑/↓ 그 슬롯 스킬 순환(빈칸 포함) · F/Esc 확정·닫기.
## 닫으면 선택을 player.skill_slots 에 반영. 4.7 조립: 노드 전부 코드 생성,
## 참조는 open()으로 주입(경로 조회 없음). 입력은 _input 에서 소비(_unhandled 차단).

var _player: CharacterBody2D = null
var _open := false
var _sel_slot := 0
var _choice := [0, 0]  # 슬롯별 옵션 인덱스 (0 = 미각인/빈칸)
var _options: Array[String] = []
var _font: SystemFont
var _nodes: Array[CanvasItem] = []
var _slot_lbls: Array[Label] = []
var _list_lbls: Array[Label] = []


func _ready() -> void:
	layer = 5  # HUD(기본 레이어) 위에 오도록
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	_options = [""]
	for id in SkillDB.ids():
		_options.append(id)
	_build()
	_set_visible(false)


func is_open() -> bool:
	return _open


func open(player: CharacterBody2D) -> void:
	if player == null:
		push_warning("[진단] 각인 패널 open() — player null, 무시")
		return
	_player = player
	# 현재 장착 상태 → 옵션 인덱스 복원
	for s in 2:
		var idx := _options.find(player.skill_slots[s])
		_choice[s] = idx if idx >= 0 else 0
	_sel_slot = 0
	_open = true
	player.input_locked = true
	player.velocity = Vector2.ZERO
	_set_visible(true)
	_refresh()


func close() -> void:
	# 확정: 선택을 player.skill_slots 에 반영 후 입력 잠금 해제
	if _player != null:
		for s in 2:
			_player.skill_slots[s] = _options[_choice[s]]
		_player.input_locked = false
	_open = false
	_set_visible(false)


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_LEFT:
			_sel_slot = 0
		KEY_RIGHT:
			_sel_slot = 1
		KEY_UP:
			_cycle(-1)
		KEY_DOWN:
			_cycle(1)
		KEY_F, KEY_ESCAPE:
			close()
	# 열린 동안 모든 키 입력을 소비 — 아레나 _unhandled_input(R·Esc 등) 차단
	get_viewport().set_input_as_handled()
	if _open:
		_refresh()


func _cycle(dir: int) -> void:
	var n := _options.size()
	_choice[_sel_slot] = (_choice[_sel_slot] + dir + n) % n


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	_add(dim)
	_add(_mklabel(
		"각인술사 — 스킬 각인", Vector2(360.0, 120.0), 24, Color(1.0, 0.92, 0.6)))
	for s in 2:
		var lb := _mklabel("", Vector2(360.0, 172.0 + float(s) * 30.0), 18, Color(1, 1, 1))
		_add(lb)
		_slot_lbls.append(lb)
	_add(_mklabel("스킬 목록", Vector2(360.0, 250.0), 16, Color(0.8, 0.85, 0.95)))
	for i in _options.size():
		var lb := _mklabel("", Vector2(380.0, 282.0 + float(i) * 26.0), 16, Color(1, 1, 1))
		_add(lb)
		_list_lbls.append(lb)
	var hy := 282.0 + float(_options.size()) * 26.0 + 20.0
	_add(_mklabel(
		"←/→ 슬롯 선택   ↑/↓ 스킬 변경(빈칸 포함)   F/Esc 확정·닫기",
		Vector2(360.0, hy), 14, Color(0.65, 0.72, 0.85)))


func _refresh() -> void:
	for s in 2:
		var id: String = _options[_choice[s]]
		var nm := "미각인" if id == "" else _skill_text(id)
		var mark := "◀ " if s == _sel_slot else "    "
		var key := "S" if s == 0 else "D"
		_slot_lbls[s].text = "%s슬롯%d [%s]: %s" % [mark, s + 1, key, nm]
		var col := Color(1.0, 0.95, 0.6) if s == _sel_slot else Color(0.8, 0.85, 0.95)
		_slot_lbls[s].add_theme_color_override("font_color", col)
	var cur: int = _choice[_sel_slot]
	for i in _options.size():
		var id: String = _options[i]
		var txt := "빈칸 (미각인)" if id == "" else _skill_text(id)
		var arrow := "▶ " if i == cur else "    "
		_list_lbls[i].text = arrow + txt
		var col := Color(0.6, 1.0, 0.7) if i == cur else Color(0.72, 0.76, 0.85)
		_list_lbls[i].add_theme_color_override("font_color", col)


func _skill_text(id: String) -> String:
	return "%s (%s)" % [SkillDB.name_of(id), SkillDB.element_of(id)]


func _set_visible(v: bool) -> void:
	for n in _nodes:
		n.visible = v


func _add(node: CanvasItem) -> void:
	add_child(node)
	_nodes.append(node)


func _mklabel(text: String, pos: Vector2, size: int, col: Color) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.position = pos
	lb.add_theme_font_override("font", _font)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", col)
	return lb
