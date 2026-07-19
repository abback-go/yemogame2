extends CanvasLayer
## 디버그 HUD v2.1 — 능력 ON/OFF·마나 비용·마나 바·산소 바·체력 마스크·
## 부유/비행 시간·쿨·얼음 발판 쿨·익사 경고·상태·키 안내·토글 토스트 (spec §7).
## 노드는 전부 코드 생성, 상태는 bind()된 플레이어에서 매 프레임 조회.

const PlayerScript := preload("res://scripts/player.gd")
const KEY_GUIDE := \
	"←→ 이동  Z/Space 점프  C/Shift 대시  X 부유(홀드)  ↓ 활공(홀드)\n" + \
	"A 얼음 발판  D 비행 발동   1~9 능력 토글   F 마나 리필   R 리스폰   Esc 메뉴"
const COMBAT_GUIDE := \
	"←→ 이동  Z 점프  C 대시  X 부유  ↑ 상승  ↓ 활공  Q 얼음발판  E 비행\n" + \
	"A 마력 칼날  S 슬롯1  D 슬롯2  F 각인술사  R 리스폰  Esc 메뉴"
const BAR_W := 200.0

var player: CharacterBody2D = null
var combat_mode := false
var _font: SystemFont
var _rows: Array[Label] = []
var _masks: Array[ColorRect] = []
var _mana_fill: ColorRect
var _mana_text: Label
var _oxygen_bg: ColorRect
var _oxygen_fill: ColorRect
var _oxygen_text: Label
var _health_text: Label
var _ice_text: Label
var _hover_text: Label
var _fly_text: Label
var _state: Label
var _drown: Label
var _toast: Label
var _toast_t := 0.0
var _abil_header: Label
var _guide: Label
var _skill1_lbl: Label
var _skill2_lbl: Label
var _combo_lbl: Label
var _combat_guide: Label

func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	_build()

func bind(p: CharacterBody2D) -> void:
	player = p

func set_combat_mode(on: bool) -> void:
	# 전투 아레나: 이동 전용 표시를 숨기고 스킬 쿨/콤보/전투 키 안내로 전환
	combat_mode = on
	_apply_mode()

func _apply_mode() -> void:
	var c := combat_mode
	_abil_header.visible = not c
	for r in _rows:
		r.visible = not c
	_ice_text.visible = not c
	_hover_text.visible = not c
	_fly_text.visible = not c
	_guide.visible = not c
	_skill1_lbl.visible = c
	_skill2_lbl.visible = c
	_combo_lbl.visible = c
	_combat_guide.visible = c

func show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 1.6

func _build() -> void:
	_abil_header = _mklabel("능력 (숫자키 토글)", Vector2(16.0, 12.0), 16, Color(1, 1, 1))
	add_child(_abil_header)
	var keys: Array = PlayerScript.ABILITY_KEYS
	for i in keys.size():
		var lb := _mklabel("", Vector2(16.0, 40.0 + float(i) * 22.0), 15, Color(1, 1, 1))
		add_child(lb)
		_rows.append(lb)
	var by := 40.0 + float(keys.size()) * 22.0 + 14.0
	_mana_text = _mklabel("마나", Vector2(16.0, by), 14, Color(0.85, 0.9, 1.0))
	add_child(_mana_text)
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.17, 0.24)
	bg.position = Vector2(16.0, by + 22.0)
	bg.size = Vector2(BAR_W, 14.0)
	add_child(bg)
	_mana_fill = ColorRect.new()
	_mana_fill.color = Color(0.3, 0.6, 1.0)
	_mana_fill.position = Vector2(16.0, by + 22.0)
	_mana_fill.size = Vector2(BAR_W, 14.0)
	add_child(_mana_fill)
	# 산소 바: 물 접촉 중 또는 산소 미충전 시에만 표시 (spec §7)
	_oxygen_text = _mklabel("산소", Vector2(16.0, by + 40.0), 14, Color(0.6, 0.9, 1.0))
	add_child(_oxygen_text)
	_oxygen_bg = ColorRect.new()
	_oxygen_bg.color = Color(0.12, 0.2, 0.26)
	_oxygen_bg.position = Vector2(16.0, by + 62.0)
	_oxygen_bg.size = Vector2(BAR_W, 14.0)
	add_child(_oxygen_bg)
	_oxygen_fill = ColorRect.new()
	_oxygen_fill.color = Color(0.4, 0.8, 1.0)
	_oxygen_fill.position = Vector2(16.0, by + 62.0)
	_oxygen_fill.size = Vector2(BAR_W, 14.0)
	add_child(_oxygen_fill)
	_build_status(by)

func _build_status(by: float) -> void:
	_health_text = _mklabel("체력", Vector2(16.0, by + 86.0), 14, Color(0.95, 0.7, 0.7))
	add_child(_health_text)
	for i in PlayerScript.HEALTH_MAX:
		var m := ColorRect.new()
		m.position = Vector2(70.0 + float(i) * 22.0, by + 86.0)
		m.size = Vector2(18.0, 16.0)
		add_child(m)
		_masks.append(m)
	_ice_text = _mklabel("", Vector2(16.0, by + 110.0), 14, Color(0.7, 0.9, 1.0))
	add_child(_ice_text)
	_hover_text = _mklabel("", Vector2(16.0, by + 132.0), 14, Color(0.8, 0.95, 0.8))
	add_child(_hover_text)
	_fly_text = _mklabel("", Vector2(16.0, by + 154.0), 14, Color(0.85, 0.75, 1.0))
	add_child(_fly_text)
	_state = _mklabel("", Vector2(16.0, by + 176.0), 14, Color(0.8, 0.85, 0.95))
	add_child(_state)
	_guide = _mklabel(KEY_GUIDE, Vector2(16.0, 486.0), 13, Color(0.6, 0.65, 0.75))
	add_child(_guide)
	_build_combat(by)
	_drown = _mklabel("", Vector2(300.0, 84.0), 26, Color(1.0, 0.25, 0.2))
	_drown.visible = false
	add_child(_drown)
	_toast = _mklabel("", Vector2(300.0, 30.0), 22, Color(1.0, 0.9, 0.4))
	_toast.visible = false
	add_child(_toast)

func _build_combat(by: float) -> void:
	# 전투 표시(기본 숨김) — 이동 슬롯 재사용, set_combat_mode로 전환
	_skill1_lbl = _mklabel("", Vector2(16.0, by + 110.0), 15, Color(0.7, 0.9, 1.0))
	add_child(_skill1_lbl)
	_skill2_lbl = _mklabel("", Vector2(16.0, by + 134.0), 15, Color(0.75, 0.85, 1.0))
	add_child(_skill2_lbl)
	_combo_lbl = _mklabel("", Vector2(16.0, by + 162.0), 17, Color(1.0, 0.95, 0.7))
	add_child(_combo_lbl)
	_combat_guide = _mklabel(COMBAT_GUIDE, Vector2(16.0, 506.0), 13, Color(0.6, 0.7, 0.82))
	add_child(_combat_guide)
	_skill1_lbl.visible = false
	_skill2_lbl.visible = false
	_combo_lbl.visible = false
	_combat_guide.visible = false

func _mklabel(text: String, pos: Vector2, size: int, col: Color) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.position = pos
	lb.add_theme_font_override("font", _font)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", col)
	return lb

func _process(delta: float) -> void:
	if player == null:
		return
	_update_toast(delta)
	if not combat_mode:
		_update_abilities()
	_update_mana()
	_update_oxygen()
	_update_status()
	if combat_mode:
		_update_combat()

func _update_toast(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.visible = true
		_toast.modulate.a = clampf(_toast_t / 0.6, 0.0, 1.0)
	else:
		_toast.visible = false

func _update_abilities() -> void:
	var keys: Array = PlayerScript.ABILITY_KEYS
	var labels: Dictionary = PlayerScript.ABILITY_LABELS
	var costs: Dictionary = PlayerScript.ABILITY_COSTS
	for i in keys.size():
		var k: String = keys[i]
		var on: bool = player.abilities[k]
		var mark := "ON" if on else "OFF"
		_rows[i].text = "%d. %s : %s  (%s)" % [i + 1, labels[k], mark, costs[k]]
		var col := Color(0.4, 0.9, 0.5) if on else Color(0.5, 0.55, 0.62)
		_rows[i].add_theme_color_override("font_color", col)

func _update_mana() -> void:
	var m: float = player.mana
	_mana_fill.size.x = BAR_W * clampf(m / 100.0, 0.0, 1.0)
	if player.mana_blink > 0.0 and int(player.mana_blink * 12.0) % 2 == 0:
		_mana_fill.color = Color(1.0, 0.9, 0.3)
	elif m < 25.0:
		_mana_fill.color = Color(1.0, 0.4, 0.3)
	else:
		_mana_fill.color = Color(0.3, 0.6, 1.0)
	_mana_text.text = "마나  %d / 100" % int(m)

func _update_oxygen() -> void:
	if combat_mode:
		_oxygen_text.visible = false
		_oxygen_bg.visible = false
		_oxygen_fill.visible = false
		return
	var o: float = player.oxygen
	var omax: float = PlayerScript.OXYGEN_MAX
	var show: bool = player.in_water or o < omax
	_oxygen_text.visible = show
	_oxygen_bg.visible = show
	_oxygen_fill.visible = show
	if not show:
		return
	_oxygen_fill.size.x = BAR_W * clampf(o / omax, 0.0, 1.0)
	_oxygen_fill.color = Color(1.0, 0.5, 0.3) if o < 25.0 else Color(0.4, 0.8, 1.0)
	_oxygen_text.text = "산소  %d / 100" % int(o)

func _update_status() -> void:
	var hp: int = player.health
	for i in _masks.size():
		_masks[i].color = Color(0.9, 0.3, 0.3) if i < hp else Color(0.28, 0.16, 0.18)
	if player.ice_cd > 0.0:
		_ice_text.text = "얼음 발판  쿨타임 %.1f초 (동시 1개)" % player.ice_cd
	else:
		_ice_text.text = "얼음 발판  대기 (동시 1개)"
	if player.hovering:
		_hover_text.text = "부유  남은 %.1f초" % player.hover_t
	elif player.hover_cd > 0.0:
		_hover_text.text = "부유  쿨타임 %.1f초" % player.hover_cd
	else:
		_hover_text.text = "부유  대기"
	if player.flying:
		_fly_text.text = "비행  남은 %.1f초" % player.fly_t
	elif player.fly_cd > 0.0:
		_fly_text.text = "비행  쿨타임 %.1f초" % player.fly_cd
	else:
		_fly_text.text = "비행  대기"
	var v: Vector2 = player.velocity
	_state.text = "상태 : %s\n속도 : (%d, %d)" % [player.state_name, int(v.x), int(v.y)]
	if player.drowning:
		_drown.visible = true
		_drown.text = "익사! 물 밖으로  (체력 %d)" % hp
	else:
		_drown.visible = false

func _update_combat() -> void:
	# v3 각인 2슬롯 표시(쿨 카운트다운) + 콤보 카운터. 마나·체력은 공용 재사용.
	_skill1_lbl.text = _slot_line(0, "S")
	_apply_slot_color(_skill1_lbl, 0)
	_skill2_lbl.text = _slot_line(1, "D")
	_apply_slot_color(_skill2_lbl, 1)
	var combo: int = player.attack_step
	if combo == 0 and player.combo_reset_t > 0.0:
		combo = player.combo_index
	_combo_lbl.text = "콤보  x%d" % combo if combo > 0 else "A  마력 칼날 콤보"

func _slot_line(idx: int, keyname: String) -> String:
	var id: String = player.skill_slots[idx]
	if id == "":
		return "슬롯%d [%s]: 미각인" % [idx + 1, keyname]
	var nm := SkillDB.name_of(id)
	var cd: float = player.slot_cd[idx]
	if cd > 0.0:
		return "슬롯%d [%s]: %s   쿨 %.1f초" % [idx + 1, keyname, nm, cd]
	return "슬롯%d [%s]: %s   준비" % [idx + 1, keyname, nm]

func _apply_slot_color(lb: Label, idx: int) -> void:
	var id: String = player.skill_slots[idx]
	var col := Color(0.5, 0.6, 0.7)  # 미각인/쿨 중
	if id != "" and player.slot_cd[idx] <= 0.0:
		col = Color(0.75, 0.9, 1.0)  # 준비
	lb.add_theme_color_override("font_color", col)
