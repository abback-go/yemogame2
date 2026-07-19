extends CanvasLayer
## 디버그/전투 HUD v3 — 전투 모드(체력·마나·산소·정수·재화·2슬롯·콤보·키안내)와
## 비전투 모드(능력 9종 토글·바·상태·키안내)를 겹침 없이 960×540 안에 배치한다.
## 노드는 전부 코드 생성, 상태는 bind()된 플레이어에서 매 프레임 조회. CanvasLayer라
## 카메라 줌과 무관한 화면 좌표. 여백 16px, 요소 간 최소 8px 확보로 상호 비겹침 보장.

const PlayerScript := preload("res://scripts/player.gd")
const MARGIN := 16.0
const BAR_W := 200.0
const HEART_W := 18.0
const HEART_H := 16.0
const HEART_STEP := 22.0
const NONCOMBAT_GUIDE := \
	"←→ 이동  Z/Space 점프  C/Shift 대시  X 부유(홀드)  ↓ 활공(홀드)\n" + \
	"A 얼음 발판  D 비행 발동   1~9 능력 토글   F 마나 리필   R 리스폰   Esc 메뉴"
const COMBAT_GUIDE := \
	"←→ 이동  Z 점프  C 대시  X 부유  ↑ 상승  ↓ 활공  Q 얼음발판  E 비행\n" + \
	"A 마력 칼날  S 슬롯1  D 슬롯2  F NPC  R 리스폰  Esc 메뉴"

# ── 색 상수 (단일 출처) ──────────────────────────────────────────
const COL_LABEL := Color(0.85, 0.9, 1.0)
const COL_MANA := Color(0.3, 0.6, 1.0)
const COL_MANA_LOW := Color(1.0, 0.4, 0.3)
const COL_MANA_BLINK := Color(1.0, 0.9, 0.3)
const COL_MANA_BG := Color(0.15, 0.17, 0.24)
const COL_OXY := Color(0.4, 0.8, 1.0)
const COL_OXY_LABEL := Color(0.6, 0.9, 1.0)
const COL_OXY_LOW := Color(1.0, 0.5, 0.3)
const COL_OXY_BG := Color(0.12, 0.2, 0.26)
const COL_HEART := Color(0.9, 0.3, 0.3)
const COL_HEART_DEAD := Color(0.28, 0.16, 0.18)
const COL_HEART_LABEL := Color(0.95, 0.7, 0.7)
const COL_READY := Color(0.55, 0.85, 1.0)
const COL_COOL := Color(0.55, 0.6, 0.68)
const COL_MATERIAL := Color(1.0, 0.85, 0.5)
const COL_ESSENCE := Color(0.9, 0.9, 0.95)
const COL_COMBO := Color(1.0, 0.95, 0.7)
const COL_DIM := Color(0.6, 0.65, 0.75)
const COL_ON := Color(0.4, 0.9, 0.5)
const COL_OFF := Color(0.5, 0.55, 0.62)

var player: CharacterBody2D = null
var combat_mode := false
var _font: SystemFont

# 공용(두 모드 다 사용) — 위치는 _place_shared()가 모드별로 재배치
var _health_lbl: Label
var _masks: Array[ColorRect] = []
var _mana_text: Label
var _mana_bg: ColorRect
var _mana_fill: ColorRect
var _oxygen_text: Label
var _oxygen_bg: ColorRect
var _oxygen_fill: ColorRect

# 비전투 전용
var _abil_header: Label
var _rows: Array[Label] = []
var _ice_text: Label
var _hover_text: Label
var _fly_text: Label
var _state: Label
var _noncombat_guide: Label

# 전투 전용
var _essence_swatch: ColorRect
var _essence_lbl: Label
var _material_lbl: Label
var _slot1_lbl: Label
var _slot2_lbl: Label
var _combo_lbl: Label
var _combat_guide: Label

# 공용 알림(상단 중앙)
var _drown: Label
var _toast: Label
var _toast_t := 0.0


func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	_build()
	_apply_mode()


func bind(p: CharacterBody2D) -> void:
	player = p


func set_combat_mode(on: bool) -> void:
	# 전투 아레나/학교/슬라이스: 이동 토글 목록을 숨기고 정수·재화·2슬롯·콤보로 전환
	combat_mode = on
	_apply_mode()


func show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 1.6


# ── 빌드 ────────────────────────────────────────────────────────

func _build() -> void:
	_build_shared()
	_build_noncombat()
	_build_combat()
	_build_alerts()


func _build_shared() -> void:
	_health_lbl = _mklabel("체력", Vector2.ZERO, 14, COL_HEART_LABEL)
	add_child(_health_lbl)
	for _i in PlayerScript.HEALTH_MAX:
		var m := ColorRect.new()
		m.size = Vector2(HEART_W, HEART_H)
		add_child(m)
		_masks.append(m)
	_mana_text = _mklabel("마나", Vector2.ZERO, 14, COL_LABEL)
	add_child(_mana_text)
	_mana_bg = _mkbar(COL_MANA_BG)
	_mana_fill = _mkbar(COL_MANA)
	_oxygen_text = _mklabel("산소", Vector2.ZERO, 14, COL_OXY_LABEL)
	add_child(_oxygen_text)
	_oxygen_bg = _mkbar(COL_OXY_BG)
	_oxygen_fill = _mkbar(COL_OXY)


func _build_noncombat() -> void:
	# 좌측 단일 열: 능력 목록(위) → 바·상태(충분히 아래) 로 분리해 겹침 해소
	_abil_header = _mklabel("능력 (숫자키 토글)", Vector2(MARGIN, 16.0), 15, Color(1, 1, 1))
	add_child(_abil_header)
	var keys: Array = PlayerScript.ABILITY_KEYS
	for i in keys.size():
		var lb := _mklabel("", Vector2(MARGIN, 42.0 + float(i) * 22.0), 15, Color(1, 1, 1))
		add_child(lb)
		_rows.append(lb)
	_ice_text = _mklabel("", Vector2(MARGIN, 368.0), 14, Color(0.7, 0.9, 1.0))
	add_child(_ice_text)
	_hover_text = _mklabel("", Vector2(MARGIN, 390.0), 14, Color(0.8, 0.95, 0.8))
	add_child(_hover_text)
	_fly_text = _mklabel("", Vector2(MARGIN, 412.0), 14, Color(0.85, 0.75, 1.0))
	add_child(_fly_text)
	_state = _mklabel("", Vector2(MARGIN, 434.0), 14, Color(0.8, 0.85, 0.95))
	add_child(_state)
	_noncombat_guide = _mklabel(NONCOMBAT_GUIDE, Vector2(MARGIN, 500.0), 13, COL_DIM)
	add_child(_noncombat_guide)


func _build_combat() -> void:
	# 좌측 열: 체력·마나·산소(공용) 아래로 정수 → 재화 → 슬롯1/2 → 콤보
	_essence_swatch = ColorRect.new()
	_essence_swatch.size = Vector2(14.0, 14.0)
	_essence_swatch.position = Vector2(MARGIN, 133.0)
	add_child(_essence_swatch)
	_essence_lbl = _mklabel("정수: 없음", Vector2(36.0, 132.0), 14, COL_ESSENCE)
	add_child(_essence_lbl)
	_material_lbl = _mklabel("마력 결정 × 0", Vector2(MARGIN, 158.0), 14, COL_MATERIAL)
	add_child(_material_lbl)
	_slot1_lbl = _mklabel("", Vector2(MARGIN, 186.0), 15, COL_READY)
	add_child(_slot1_lbl)
	_slot2_lbl = _mklabel("", Vector2(MARGIN, 210.0), 15, COL_READY)
	add_child(_slot2_lbl)
	_combo_lbl = _mklabel("", Vector2(MARGIN, 238.0), 17, COL_COMBO)
	add_child(_combo_lbl)
	_combat_guide = _mklabel(COMBAT_GUIDE, Vector2(MARGIN, 502.0), 13, Color(0.6, 0.7, 0.82))
	add_child(_combat_guide)


func _build_alerts() -> void:
	# 상단 중앙(x=330) — 익사 경고와 토스트를 세로로 분리해 상호 비겹침
	_drown = _mklabel("익사! 물 밖으로", Vector2(330.0, 60.0), 26, Color(1.0, 0.25, 0.2))
	_drown.visible = false
	add_child(_drown)
	_toast = _mklabel("", Vector2(330.0, 24.0), 22, Color(1.0, 0.9, 0.4))
	_toast.visible = false
	add_child(_toast)


func _mkbar(col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.size = Vector2(BAR_W, 14.0)
	add_child(r)
	return r


func _mklabel(text: String, pos: Vector2, size: int, col: Color) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.position = pos
	lb.add_theme_font_override("font", _font)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", col)
	return lb


# ── 모드 전환·배치 ──────────────────────────────────────────────

func _apply_mode() -> void:
	var c := combat_mode
	_abil_header.visible = not c
	for r in _rows:
		r.visible = not c
	_ice_text.visible = not c
	_hover_text.visible = not c
	_fly_text.visible = not c
	_state.visible = not c
	_noncombat_guide.visible = not c
	_essence_swatch.visible = c
	_essence_lbl.visible = c
	_material_lbl.visible = c
	_slot1_lbl.visible = c
	_slot2_lbl.visible = c
	_combo_lbl.visible = c
	_combat_guide.visible = c
	_place_shared()


func _place_shared() -> void:
	# 공용 체력·마나·산소를 모드별 위치로 재배치(전투=상단 좌열, 비전투=좌열 하단부)
	if combat_mode:
		_health_lbl.position = Vector2(MARGIN, 16.0)
		for i in _masks.size():
			_masks[i].position = Vector2(64.0 + float(i) * HEART_STEP, 16.0)
		_mana_text.position = Vector2(MARGIN, 44.0)
		_place_bar(_mana_bg, _mana_fill, Vector2(MARGIN, 64.0))
		_oxygen_text.position = Vector2(MARGIN, 88.0)
		_place_bar(_oxygen_bg, _oxygen_fill, Vector2(MARGIN, 108.0))
	else:
		_mana_text.position = Vector2(MARGIN, 252.0)
		_place_bar(_mana_bg, _mana_fill, Vector2(MARGIN, 272.0))
		_oxygen_text.position = Vector2(MARGIN, 296.0)
		_place_bar(_oxygen_bg, _oxygen_fill, Vector2(MARGIN, 316.0))
		_health_lbl.position = Vector2(MARGIN, 344.0)
		for i in _masks.size():
			_masks[i].position = Vector2(70.0 + float(i) * HEART_STEP, 344.0)


func _place_bar(bg: ColorRect, fill: ColorRect, pos: Vector2) -> void:
	bg.position = pos
	fill.position = pos


# ── 매 프레임 갱신 ──────────────────────────────────────────────

func _process(delta: float) -> void:
	if player == null:
		return
	_update_toast(delta)
	_update_mana()
	_update_oxygen()
	_update_health()
	_drown.visible = player.drowning
	if combat_mode:
		_update_combat()
	else:
		_update_abilities()
		_update_movement_status()


func _update_toast(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.visible = true
		_toast.modulate.a = clampf(_toast_t / 0.6, 0.0, 1.0)
	else:
		_toast.visible = false


func _update_mana() -> void:
	var m: float = player.mana
	_mana_fill.size.x = BAR_W * clampf(m / 100.0, 0.0, 1.0)
	if player.mana_blink > 0.0 and int(player.mana_blink * 12.0) % 2 == 0:
		_mana_fill.color = COL_MANA_BLINK
	elif m < 25.0:
		_mana_fill.color = COL_MANA_LOW
	else:
		_mana_fill.color = COL_MANA
	_mana_text.text = "마나  %d / 100" % int(m)


func _update_oxygen() -> void:
	# 물 접촉 중 또는 산소 미충전 시에만 표시(전투·비전투 공통)
	var o: float = player.oxygen
	var omax: float = PlayerScript.OXYGEN_MAX
	var show: bool = player.in_water or o < omax
	_oxygen_text.visible = show
	_oxygen_bg.visible = show
	_oxygen_fill.visible = show
	if not show:
		return
	_oxygen_fill.size.x = BAR_W * clampf(o / omax, 0.0, 1.0)
	_oxygen_fill.color = COL_OXY_LOW if o < 25.0 else COL_OXY
	_oxygen_text.text = "산소  %d / 100" % int(o)


func _update_health() -> void:
	var hp: int = player.health
	for i in _masks.size():
		_masks[i].color = COL_HEART if i < hp else COL_HEART_DEAD


func _update_abilities() -> void:
	var keys: Array = PlayerScript.ABILITY_KEYS
	var labels: Dictionary = PlayerScript.ABILITY_LABELS
	var costs: Dictionary = PlayerScript.ABILITY_COSTS
	for i in keys.size():
		var k: String = keys[i]
		var on: bool = player.abilities[k]
		var mark := "ON" if on else "OFF"
		_rows[i].text = "%d. %s : %s  (%s)" % [i + 1, labels[k], mark, costs[k]]
		_rows[i].add_theme_color_override("font_color", COL_ON if on else COL_OFF)


func _update_movement_status() -> void:
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


# ── 전투 갱신 ───────────────────────────────────────────────────

func _update_combat() -> void:
	_update_essence()
	_material_lbl.text = "마력 결정 × %d" % GameState.arena_material
	_slot1_lbl.text = _slot_line(0, "S")
	_apply_slot_color(_slot1_lbl, 0)
	_slot2_lbl.text = _slot_line(1, "D")
	_apply_slot_color(_slot2_lbl, 1)
	_update_combo()


func _update_essence() -> void:
	var e: String = player.blade_element
	_essence_swatch.color = Elements.color_of(e)
	if e == "무":
		_essence_lbl.text = "정수: 없음"
	else:
		_essence_lbl.text = "정수: %s" % e


func _slot_line(idx: int, keyname: String) -> String:
	var id: String = player.skill_slots[idx]
	if id == "":
		return "슬롯%d [%s]: 미각인" % [idx + 1, keyname]
	var nm := SkillDB.name_of(id)
	var el := SkillDB.element_of(id)
	var lv := GameState.skill_level(id)
	var cd: float = player.slot_cd[idx]
	if cd > 0.0:
		return "슬롯%d [%s]: %s(%s) Lv.%d  쿨 %.1f초" % [idx + 1, keyname, nm, el, lv, cd]
	return "슬롯%d [%s]: %s(%s) Lv.%d  준비" % [idx + 1, keyname, nm, el, lv]


func _apply_slot_color(lb: Label, idx: int) -> void:
	# 준비=밝은 하늘색, 쿨 중·미각인=회색
	var id: String = player.skill_slots[idx]
	var col := COL_COOL
	if id != "" and player.slot_cd[idx] <= 0.0:
		col = COL_READY
	lb.add_theme_color_override("font_color", col)


func _update_combo() -> void:
	var combo: int = player.attack_step
	if combo == 0 and player.combo_reset_t > 0.0:
		combo = player.combo_index
	if combo > 0:
		_combo_lbl.text = "콤보  x%d" % combo
	else:
		_combo_lbl.text = "A  마력 칼날 콤보"
