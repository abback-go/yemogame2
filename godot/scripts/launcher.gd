extends Node2D
## 시작 메뉴 — 1: 조작감 테스트 방 / 2: 월드맵 뷰어 / 3: 전투 아레나(v3).
## v3: 원소 토글 제거. [3]은 곧장 무속성 칼 + 각인 2슬롯 아레나로 진입한다.

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
	var menu := Label.new()
	menu.position = Vector2(64, 230)
	menu.add_theme_font_override("font", font)
	menu.add_theme_font_size_override("font_size", 18)
	menu.text = "[1]  조작감 테스트 방  (이동 마법 9종 토글)\n\n" + \
		"[2]  월드맵 뷰어  (17개 지역 · 295방 설계도)\n\n" + \
		"[3]  전투 아레나  (v3 · 무속성 칼 + 각인 2슬롯 · 이동 놀이터)\n\n" + \
		"[4]  수직 슬라이스  (학교 현관→뒷숲 · 5방 미니 메트로베니아)"
	layer.add_child(menu)
	var foot := Label.new()
	foot.text = "숫자 키로 선택"
	foot.position = Vector2(64, 400)
	foot.add_theme_font_override("font", font)
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	layer.add_child(foot)
	add_child(layer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1, KEY_KP_1:
				get_tree().change_scene_to_file("res://scenes/main.tscn")
			KEY_2, KEY_KP_2:
				get_tree().change_scene_to_file("res://scenes/world_map_viewer.tscn")
			KEY_3, KEY_KP_3:
				get_tree().change_scene_to_file("res://scenes/combat_arena.tscn")
			KEY_4, KEY_KP_4:
				# 첫 진입 초기화: 시작 방·풀피/풀마나·빈 각인·방문 기록 리셋 후 로드.
				GameState.reset_slice()
				get_tree().change_scene_to_file("res://scenes/slice.tscn")
