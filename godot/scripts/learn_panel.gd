class_name LearnPanel
extends CanvasLayer
## v3 수업 모달 패널 — 교수 NPC 대화로 스킬을 배우고(learn) 등급을 올린다(level up).
## 배운 스킬만 이후 각인(engrave_panel.gd) 가능. 재화(마력 결정)를 소모한다.
## F로 열리며, 열린 동안 player.input_locked 로 이동/전투 입력을 얼린다.
## 조작: ↑/↓ 스킬 선택 · Enter/Space 맥락 행동(배우기/강화) · F/Esc 닫기.
## 4.7 조립: 노드 전부 코드 생성, 참조는 open()으로 주입(경로 조회 없음).
## 입력은 _input 에서 소비(씬 단축키 차단). engrave_panel 과 동일 구조·조작감.

const LEARN_COST := 20
const MAX_LEVEL := 3

var _player: CharacterBody2D = null
var _open := false
var _sel := 0
var _skill_ids: Array[String] = []
var _font: SystemFont
var _nodes: Array[CanvasItem] = []
var _row_lbls: Array[Label] = []
var _mat_lbl: Label = null


func _ready() -> void:
	layer = 5  # HUD(기본 레이어) 위에 오도록
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	_skill_ids = SkillDB.ids()
	_build()
	_set_visible(false)


func is_open() -> bool:
	return _open


func open(player: CharacterBody2D) -> void:
	if player == null:
		push_warning("[진단] 수업 패널 open() — player null, 무시")
		return
	_player = player
	_sel = 0
	_open = true
	player.input_locked = true
	player.velocity = Vector2.ZERO
	_set_visible(true)
	_refresh()


func close() -> void:
	if _player != null:
		_player.input_locked = false
	_open = false
	_set_visible(false)


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_UP:
			_move(-1)
		KEY_DOWN:
			_move(1)
		KEY_ENTER, KEY_SPACE:
			_act()
		KEY_F, KEY_ESCAPE:
			close()
	# 열린 동안 모든 키 입력을 소비 — 아레나 _unhandled_input(R·Esc 등) 차단
	get_viewport().set_input_as_handled()
	if _open:
		_refresh()


func _move(dir: int) -> void:
	var n := _skill_ids.size()
	if n == 0:
		return
	_sel = (_sel + dir + n) % n


func _levelup_cost(next: int) -> int:
	return 15 if next == 2 else 25


func _act() -> void:
	if _sel < 0 or _sel >= _skill_ids.size():
		return
	var id: String = _skill_ids[_sel]
	var lv := GameState.skill_level(id)
	var learned := GameState.arena_learned.has(id)
	if not learned:
		# 미습득 → 배우기
		if GameState.arena_material >= LEARN_COST:
			GameState.arena_material -= LEARN_COST
			GameState.arena_learned.append(id)
		else:
			_flash_deny()
	elif lv < MAX_LEVEL:
		# 습득 & 등급<3 → 레벨업
		var next := lv + 1
		var cost := _levelup_cost(next)
		if GameState.arena_material >= cost:
			GameState.arena_material -= cost
			GameState.arena_levels[id] = next
		else:
			_flash_deny()
	# 등급 3(만렙)이면 아무 것도 안 함


func _flash_deny() -> void:
	# 재화 부족 불발 — 보유 재화 라벨을 잠깐 붉게 깜빡(modulate, _refresh 와 무간섭).
	if _mat_lbl == null:
		return
	_mat_lbl.modulate = Color(1.0, 0.4, 0.4)
	var t := create_tween()
	t.tween_property(_mat_lbl, "modulate", Color(1, 1, 1), 0.3)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	_add(dim)
	_add(_mklabel(
		"수업 — 스킬 습득·강화", Vector2(360.0, 110.0), 24, Color(1.0, 0.92, 0.6)))
	_mat_lbl = _mklabel("", Vector2(360.0, 150.0), 18, Color(0.7, 0.9, 1.0))
	_add(_mat_lbl)
	_add(_mklabel("스킬 목록", Vector2(360.0, 194.0), 16, Color(0.8, 0.85, 0.95)))
	for i in _skill_ids.size():
		var lb := _mklabel("", Vector2(380.0, 226.0 + float(i) * 30.0), 16, Color(1, 1, 1))
		_add(lb)
		_row_lbls.append(lb)
	var hy := 226.0 + float(_skill_ids.size()) * 30.0 + 22.0
	_add(_mklabel(
		"↑/↓ 선택   Enter 배우기·강화   F/Esc 닫기",
		Vector2(360.0, hy), 14, Color(0.65, 0.72, 0.85)))
	_add(_mklabel(
		"배우기 %d · 강화 Lv2 %d · Lv3 %d (마력 결정 소모)"
		% [LEARN_COST, _levelup_cost(2), _levelup_cost(3)],
		Vector2(360.0, hy + 22.0), 13, Color(0.55, 0.62, 0.75)))


func _refresh() -> void:
	_mat_lbl.text = "보유 마력 결정: %d" % GameState.arena_material
	for i in _skill_ids.size():
		var id: String = _skill_ids[i]
		_row_lbls[i].text = _row_text(id, i)
		_row_lbls[i].add_theme_color_override("font_color", _row_color(id, i))


func _row_text(id: String, i: int) -> String:
	var arrow := "▶ " if i == _sel else "    "
	var base := "%s(%s)" % [SkillDB.name_of(id), SkillDB.element_of(id)]
	var lv := GameState.skill_level(id)
	var learned := GameState.arena_learned.has(id)
	var tag := ""
	var hint := ""
	if not learned:
		tag = "[미습득]"
		hint = "배우기 %d" % LEARN_COST
	elif lv >= MAX_LEVEL:
		tag = "[배움 Lv.%d]" % lv
		hint = "만렙"
	else:
		tag = "[배움 Lv.%d]" % lv
		hint = "강화 %d" % _levelup_cost(lv + 1)
	return "%s%s  %s   %s" % [arrow, base, tag, hint]


func _row_color(id: String, i: int) -> Color:
	var sel := i == _sel
	var lv := GameState.skill_level(id)
	var learned := GameState.arena_learned.has(id)
	if learned and lv >= MAX_LEVEL:
		return Color(1.0, 0.85, 0.4) if sel else Color(0.7, 0.62, 0.4)
	var cost := LEARN_COST if not learned else _levelup_cost(lv + 1)
	var afford := GameState.arena_material >= cost
	if not afford:
		return Color(0.9, 0.55, 0.55) if sel else Color(0.5, 0.5, 0.55)
	return Color(0.6, 1.0, 0.7) if sel else Color(0.85, 0.88, 0.95)


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
