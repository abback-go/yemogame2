class_name SpeechBubble
extends Node2D
## 월드 내 말풍선 위젯 — 화자를 추적하며 짧은 대사 한 줄을 표시한다.
## 노드는 전부 코드 생성. 씬 드라이버가 setup→attach→show_line/hide_bubble 로 구동한다.
## 카메라 줌 1.5 환경의 월드 노드 → 폰트 13, z_index 100.

const PAD := 10.0
const MAX_W := 260.0
const FONT_SIZE := 13
const TAIL_H := 12.0
const TAIL_W := 9.0
const MARK_INSET := Vector2(16.0, 18.0)
const BG_COLOR := Color(0.05, 0.06, 0.1, 0.92)
const TEXT_COLOR := Color(0.96, 0.97, 1.0, 1.0)
const LINE_COLOR := Color(0.6, 0.65, 0.8, 0.35)

var _panel: ColorRect
var _border: Line2D
var _tail: Polygon2D
var _label: Label
var _marker: Label
var _font: SystemFont
var _speaker: Node2D
var _offset: Vector2 = Vector2.ZERO
var _blink_t: float = 0.0


# ── API (씬 드라이버 전용, 시그니처 고정) ─────────────────────────

func setup(font: SystemFont) -> void:
	# 폰트 주입 + 내부 노드 생성 (_ready 아님 — 드라이버가 명시 호출).
	_font = font
	z_index = 100
	visible = false

	_panel = ColorRect.new()
	_panel.color = BG_COLOR
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_border = Line2D.new()
	_border.width = 1.0
	_border.default_color = LINE_COLOR
	_border.closed = true
	add_child(_border)

	_tail = Polygon2D.new()
	_tail.color = BG_COLOR
	add_child(_tail)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(MAX_W, 0.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(_label)
	add_child(_label)

	_marker = Label.new()
	_marker.text = "▼"
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(_marker)
	add_child(_marker)


func attach(speaker: Node2D, offset: Vector2) -> void:
	# 화자 추적 시작 (_process 에서 매 프레임 global_position 갱신).
	_speaker = speaker
	_offset = offset
	if is_instance_valid(_speaker):
		global_position = _speaker.global_position + _offset


func show_line(text: String) -> void:
	# 말풍선 표시 + 텍스트 교체 + 크기 재계산.
	if _label == null:
		return
	visible = true
	_label.text = text

	# 자연 폭(줄바꿈 없이) 측정 → MAX_W 상한으로 래핑 폭 결정.
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var natural: float = _label.get_minimum_size().x
	var wrap_w: float = min(natural, MAX_W)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(wrap_w, 0.0)
	_label.size = Vector2(wrap_w, 0.0)
	var lbl_h: float = _label.get_minimum_size().y

	var panel_w: float = wrap_w + PAD * 2.0
	var panel_h: float = lbl_h + PAD * 2.0
	var left: float = -panel_w * 0.5
	var top: float = -TAIL_H - panel_h
	var bottom: float = top + panel_h

	_panel.position = Vector2(left, top)
	_panel.size = Vector2(panel_w, panel_h)

	_label.position = Vector2(left + PAD, top + PAD)
	_label.size = Vector2(wrap_w, lbl_h)

	_border.points = PackedVector2Array([
		Vector2(left, top),
		Vector2(left + panel_w, top),
		Vector2(left + panel_w, bottom),
		Vector2(left, bottom),
	])

	# 아래 꼬리 삼각형: 판 하단 → 원점(화자 머리 위)으로 뾰족.
	_tail.polygon = PackedVector2Array([
		Vector2(-TAIL_W, bottom),
		Vector2(TAIL_W, bottom),
		Vector2(0.0, 0.0),
	])

	# 진행 표식 ▼ 우하단.
	_marker.position = Vector2(
		left + panel_w - MARK_INSET.x, bottom - MARK_INSET.y
	)


func hide_bubble() -> void:
	visible = false


# ── 내부 ──────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	# 화자 추적(없거나 무효면 위치 유지) + ▼ 알파 깜빡임(Time 금지, 누적 변수).
	if is_instance_valid(_speaker):
		global_position = _speaker.global_position + _offset
	_blink_t += delta
	if _marker != null:
		var pulse: float = 0.5 + 0.5 * sin(_blink_t * 4.0)
		_marker.modulate = Color(1.0, 1.0, 1.0, 0.35 + 0.6 * pulse)


func _apply_font(lbl: Label) -> void:
	if _font != null:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	lbl.add_theme_color_override("font_color", TEXT_COLOR)
