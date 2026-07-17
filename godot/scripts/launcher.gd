extends Node2D
## 시작 메뉴 — 1: 조작감 테스트 방 / 2: 월드맵 뷰어

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
	menu.text = "[1]  조작감 테스트 방  (달리기·점프·대시)\n\n[2]  월드맵 뷰어  (17개 지역 · 295방 설계도)"
	menu.position = Vector2(64, 230)
	menu.add_theme_font_override("font", font)
	menu.add_theme_font_size_override("font_size", 18)
	layer.add_child(menu)
	var foot := Label.new()
	foot.text = "숫자 키로 선택"
	foot.position = Vector2(64, 380)
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
