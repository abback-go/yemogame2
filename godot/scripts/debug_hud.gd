extends CanvasLayer
## 디버그 HUD — 능력 ON/OFF 목록·마나 바·상태·키 안내·토글 토스트 (spec §6).
## 노드는 전부 코드 생성, 상태는 bind()된 플레이어에서 매 프레임 조회 (경로 조회 없음).

const PlayerScript := preload("res://scripts/player.gd")
const KEY_GUIDE := \
	"←→ 이동  Z/Space 점프  C/Shift 대시  X 부유(홀드)  ↑ 비행(홀드)  ↓ 하강\n" + \
	"1~9 능력 토글   F 마나 리필   R 리스폰   Esc 메뉴"
const BAR_W := 200.0

var player: CharacterBody2D = null
var _font: SystemFont
var _rows: Array[Label] = []
var _mana_fill: ColorRect
var _mana_text: Label
var _state: Label
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
	_state = _mklabel("", Vector2(16.0, by + 48.0), 14, Color(0.8, 0.85, 0.95))
	add_child(_state)
	var guide := _mklabel(KEY_GUIDE, Vector2(16.0, 486.0), 13, Color(0.6, 0.65, 0.75))
	add_child(guide)
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
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.visible = true
		_toast.modulate.a = clampf(_toast_t / 0.6, 0.0, 1.0)
	else:
		_toast.visible = false
	var keys: Array = PlayerScript.ABILITY_KEYS
	var labels: Dictionary = PlayerScript.ABILITY_LABELS
	for i in keys.size():
		var k: String = keys[i]
		var on: bool = player.abilities[k]
		var mark := "ON" if on else "OFF"
		_rows[i].text = "%d. %s : %s" % [i + 1, labels[k], mark]
		var col := Color(0.4, 0.9, 0.5) if on else Color(0.5, 0.55, 0.62)
		_rows[i].add_theme_color_override("font_color", col)
	var m: float = player.mana
	_mana_fill.size.x = BAR_W * clampf(m / 100.0, 0.0, 1.0)
	_mana_fill.color = Color(1.0, 0.4, 0.3) if m < 25.0 else Color(0.3, 0.6, 1.0)
	_mana_text.text = "마나  %d / 100" % int(m)
	var v: Vector2 = player.velocity
	_state.text = "상태 : %s\n속도 : (%d, %d)" % [player.state_name, int(v.x), int(v.y)]
