extends Node2D
## 시작 메뉴 — 1: 조작감 테스트 방 / 2: 월드맵 뷰어 / 3: 전투 아레나(원소 선택)
## T 키로 전투 원소 토글(불/얼음). 선택은 GameState.combat_element(static)로
## 씬 전환에도 유지되어 combat_arena/player 가 스폰 시 읽는다. 기본 = 불.

var _menu: Label

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.043, 0.051, 0.071))
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "NanumGothic", "Noto Sans KR"])
	var layer := CanvasLayer.new()
	var title := Label.new()
	title.text = "이름 없는 마법학교 — 개발 빌드"
	title.position = Vector2(60, 140)
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 30)
	layer.add_child(title)
	_menu = Label.new()
	_menu.position = Vector2(64, 230)
	_menu.add_theme_font_override("font", font)
	_menu.add_theme_font_size_override("font_size", 18)
	layer.add_child(_menu)
	_refresh_menu()
	var foot := Label.new()
	foot.text = "숫자 키로 선택   ·   T: 전투 원소 전환(불/얼음)"
	foot.position = Vector2(64, 400)
	foot.add_theme_font_override("font", font)
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	layer.add_child(foot)
	add_child(layer)

func _refresh_menu() -> void:
	var elem := "불" if GameState.combat_element == "fire" else "얼음"
	_menu.text = "[1]  조작감 테스트 방  (이동 마법 9종 토글)\n\n" + \
		"[2]  월드맵 뷰어  (17개 지역 · 295방 설계도)\n\n" + \
		"[3]  전투 아레나  (현재 원소: %s · T로 전환)" % elem

func _toggle_element() -> void:
	if GameState.combat_element == "fire":
		GameState.combat_element = "ice"
	else:
		GameState.combat_element = "fire"
	_refresh_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1, KEY_KP_1:
				get_tree().change_scene_to_file("res://scenes/main.tscn")
			KEY_2, KEY_KP_2:
				get_tree().change_scene_to_file("res://scenes/world_map_viewer.tscn")
			KEY_3, KEY_KP_3:
				get_tree().change_scene_to_file("res://scenes/combat_arena.tscn")
			KEY_T:
				_toggle_element()
