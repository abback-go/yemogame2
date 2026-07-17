extends CanvasLayer
## 디버그 HUD v2 — 능력 ON/OFF·마나 비용·마나 바·체력 마스크·비행 시간/쿨·
## 얼음 발판 잔여·익사 경고·상태·키 안내·토글 토스트 (spec §7).
## 노드는 전부 코드 생성, 상태는 bind()된 플레이어에서 매 프레임 조회.

const PlayerScript := preload("res://scripts/player.gd")
const KEY_GUIDE := \
	"←→ 이동  Z/Space 점프  C/Shift 대시  X 부유(홀드)  ↓ 활공(홀드)\n" + \
	"A 얼음 발판  D 비행 발동   1~9 능력 토글   F 마나 리필   R 리스폰   Esc 메뉴"
const BAR_W := 200.0

var player: CharacterBody2D = null
var _font: SystemFont
var _rows: Array[Label] = []
var _masks: Array[ColorRect] = []
var _mana_fill: ColorRect
var _mana_text: Label
var _health_text: Label
var _ice_text: Label
var _fly_text: Label
var _state: Label
var _drown: Label
var _toast: Label
var _toast_t := 0.0

func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(
		["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	_build()

func bind(p: CharacterBody2D) -> void:
	player = p

func show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 1.6

func _build() -> void:
	add_child(_mklabel("능력 (숫자키 토글)", Vector2(16.0, 12.0), 16, Color(1, 1, 1)))
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
	_build_status(by)

func _build_status(by: float) -> void:
	_health_text = _mklabel("체력", Vector2(16.0, by + 46.0), 14, Color(0.95, 0.7, 0.7))
	add_child(_health_text)
	for i in PlayerScript.HEALTH_MAX:
		var m := ColorRect.new()
		m.position = Vector2(70.0 + float(i) * 22.0, by + 46.0)
		m.size = Vector2(18.0, 16.0)
		add_child(m)
		_masks.append(m)
	_ice_text = _mklabel("", Vector2(16.0, by + 70.0), 14, Color(0.7, 0.9, 1.0))
	add_child(_ice_text)
	_fly_text = _mklabel("", Vector2(16.0, by + 92.0), 14, Color(0.85, 0.75, 1.0))
	add_child(_fly_text)
	_state = _mklabel("", Vector2(16.0, by + 116.0), 14, Color(0.8, 0.85, 0.95))
	add_child(_state)
	var guide := _mklabel(KEY_GUIDE, Vector2(16.0, 486.0), 13, Color(0.6, 0.65, 0.75))
	add_child(guide)
	_drown = _mklabel("", Vector2(300.0, 84.0), 26, Color(1.0, 0.25, 0.2))
	_drown.visible = false
	add_child(_drown)
	_toast = _mklabel("", Vector2(300.0, 30.0), 22, Color(1.0, 0.9, 0.4))
	_toast.visible = false
	add_child(_toast)

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
	_update_abilities()
	_update_mana()
	_update_status()

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

func _update_status() -> void:
	var hp: int = player.health
	for i in _masks.size():
		_masks[i].color = Color(0.9, 0.3, 0.3) if i < hp else Color(0.28, 0.16, 0.18)
	var ice_max: int = PlayerScript.ICE_PLATFORM_MAX
	var left: int = maxi(0, ice_max - player.ice_count())
	_ice_text.text = "얼음 발판  잔여 %d / %d" % [left, ice_max]
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
