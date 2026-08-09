extends Node2D
## 오프닝 튜토리얼 드라이버 v2 — 콘티 6씬 + 연출 패스(주스 패스).
## op_alley(잠입) → op_run(추격) → op_dead_end(경비대장) → op_duel(결투) → world.tscn 인계.
## v2 연출: 컷씬 카메라(줌 포커스/펀치) · 전 인물 말풍선(타자기) · 앰비언트 한 줄 대사 ·
## 시차 배경 실루엣(ParallaxBackground) · 씬 색조(CanvasModulate) · 결투장 달빛 스포트.
## 방 전환 = 씬 재로드(GameState.opening_*). 사망 = 현재 방 재시작(풀회복).

const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/debug_hud.gd")
const BossScript := preload("res://scripts/enemies/professor_boss.gd")
const GuardScript := preload("res://scripts/enemies/brute.gd")

const SPAWN_GRACE := 0.25
const PICKUP_RADIUS := 46.0
const FAMILY_RADIUS := 100.0
const DUEL_TRIGGER_DIST := 340.0
# 씬 색조(달밤 하층가 → 결투장은 옅게) — HUD(CanvasLayer)는 영향 없음
const ROOM_TINT := {
	"op_alley": Color(0.78, 0.83, 1.0),
	"op_run": Color(0.75, 0.8, 1.0),
	"op_dead_end": Color(0.72, 0.76, 0.95),
	"op_duel": Color(0.88, 0.86, 1.0),
}

@export_group("주스 (combat-spec §6)")
@export var shake_max_offset := 12.0
@export var trauma_decay := 1.8
@export var lookahead_dist := 40.0
@export var lookahead_speed := 5.0
@export var hitstop_scale := 0.0
@export_group("결투 연출 타이밍 (F5 튜닝)")
@export var crack_beat := 0.9
@export var down_beat := 1.2
@export var guard_clear_beat := 1.0

var _player: CharacterBody2D
var _hud: CanvasLayer
var _juice: Juice
var _font: SystemFont
var _room_id := "op_alley"
var _room_size := Vector2(1600, 720)
var _exits: Array = []
var _grace_t := 0.0
var _reloading := false
# 카메라(플레이어 추적 + 컷씬 오버라이드)
var _cam: Camera2D = null
var _cutcam: Camera2D = null
var _cam_tw: Tween = null
# 씬별 상태
var _artifact_node: Node2D = null
var _artifact_taken := false
var _family_shown := false
var _exit_hint_t := 0.0
var _chaser: CharacterBody2D = null
var _guard: CharacterBody2D = null
var _guard_cleared := false
var _boss: CharacterBody2D = null
var _intro_done := false
var _bubble: SpeechBubble = null
var _ambient: SpeechBubble = null
var _dialog_lines: Array = []
var _dialog_idx := 0
var _dialog_phase := ""  # "" / "intro" / "end"
var _cutscene := false  # 게이지 파괴~정산 대화 사이(조작·R 차단)
var _fade_rect: ColorRect = null
var _artifact_prop: Node2D = null


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.055, 0.085))
	_font = RoomBuilder.make_font()
	_setup_input()
	_room_id = GameState.opening_room
	var room := OpeningData.get_room(_room_id)
	_room_size = room["size"]
	_build_backdrop()
	_build_tint()
	_build_room(room)
	_player = _spawn_player(_entry_pos(room["entries"], GameState.opening_entry))
	_player.collision_layer = 2
	_apply_opening_abilities()
	_player.set_zones([] as Array[Rect2], [] as Array[Rect2])
	_player.died.connect(_restart_room)
	_cam = _setup_camera(_player)
	_juice = Juice.new()
	_juice.configure(
		shake_max_offset, trauma_decay, lookahead_dist, lookahead_speed, hitstop_scale)
	_juice.bind_camera(_cam)
	_juice.bind_target(_player)
	add_child(_juice)
	_player.set_juice(_juice)
	_hud = _setup_hud(_player)
	_hud.set_combat_mode(true)
	_setup_fade_layer()
	_bubble = _make_bubble()
	_ambient = _make_bubble()
	_setup_room_content(room)
	_grace_t = SPAWN_GRACE


func _apply_opening_abilities() -> void:
	# 오프닝 시작 킷: 달리기·점프(딕셔너리 밖) + 육체 대시(지상)만. 나머지는 학교에서.
	for key in PlayerScript.ABILITY_KEYS:
		_player.abilities[key] = false
	_player.abilities["dash_ground"] = true


func _physics_process(delta: float) -> void:
	if _reloading:
		return
	if _exit_hint_t > 0.0:
		_exit_hint_t = maxf(0.0, _exit_hint_t - delta)
	if _grace_t > 0.0:
		_grace_t = maxf(0.0, _grace_t - delta)
	else:
		_check_exits()
	_tick_room()


# ── 방별 콘텐츠 셋업 ─────────────────────────────────────────────

func _setup_room_content(room: Dictionary) -> void:
	match _room_id:
		"op_alley":
			_setup_alley(room)
		"op_run":
			_setup_run(room)
		"op_dead_end":
			_setup_dead_end(room)
		"op_duel":
			_setup_duel(room)


func _setup_alley(room: Dictionary) -> void:
	_build_sleepers(room["sleepers_pos"])
	_artifact_node = _build_artifact(room["artifact_pos"], true)
	_toast_later("move", 0.6)


func _setup_run(room: Dictionary) -> void:
	_chaser = GuardScript.new()
	_chaser.position = room.get("chaser_spawn", Vector2(120, 560))
	add_child(_chaser)
	_tune_guard(_chaser)
	_chaser.set_target(_player)
	_player.set_enemies([_chaser])
	_say_later("guard", "guard_alarm", 0.4, 2.4)
	_toast_later("dash", 1.6)


func _setup_dead_end(room: Dictionary) -> void:
	_guard = GuardScript.new()
	_guard.position = room.get("guard_spawn", Vector2(220, 560))
	add_child(_guard)
	_tune_guard(_guard)
	_guard.set_target(_player)
	_player.set_enemies([_guard])
	_say_later("guard", "guard_corner", 0.6, 2.6)
	_toast_later("blob", 1.6)


func _setup_duel(room: Dictionary) -> void:
	var boss_pos: Vector2 = room.get("boss_spawn", Vector2(1000, 560))
	_build_spotlight(Vector2(boss_pos.x, 612.0))
	_boss = BossScript.new()
	_boss.position = boss_pos
	add_child(_boss)
	_boss.gauge_broken.connect(_on_gauge_broken)
	_boss.stepped.connect(_on_boss_stepped)
	_boss.finisher_done.connect(_on_finisher_done)
	_artifact_prop = _build_crate_prop(room.get("artifact_prop", Vector2(1150, 585)))
	# 대화는 접근 시 시작(_tick_duel) — 멀리서 시작하면 말풍선이 화면 밖이라 금지.


func _tune_guard(g: CharacterBody2D) -> void:
	# 경비대장 — brute 변형(중간보스): HP10·강철 톤·드롭/상성 없음.
	g.max_hp = 10
	g.hp = 10
	g.body_color = Color(0.45, 0.5, 0.62)
	g.material_drop = 0
	g.weak_element = ""
	g.resist_element = ""


# ── 방별 진행 로직 ───────────────────────────────────────────────

func _tick_room() -> void:
	match _room_id:
		"op_alley":
			_tick_alley()
		"op_dead_end":
			_tick_dead_end()
		"op_duel":
			_tick_duel()


func _tick_alley() -> void:
	var p := _player.global_position
	if not _family_shown:
		var room := OpeningData.get_room(_room_id)
		if p.distance_to(room["sleepers_pos"]) < FAMILY_RADIUS:
			_family_shown = true
			_say("player", "family", 2.6)
	if not _artifact_taken and _artifact_node != null:
		if p.distance_to(_artifact_node.position) < PICKUP_RADIUS:
			_artifact_taken = true
			_artifact_node.visible = false
			_say("player", "artifact", 2.0)
			_flash(Color(1.0, 0.6, 0.3, 0.35), 0.25)
			get_tree().create_timer(1.2).timeout.connect(_toast.bind("alarm"))


func _tick_dead_end() -> void:
	if _guard_cleared or _guard == null:
		return
	if not _guard.alive:
		_guard_cleared = true
		get_tree().create_timer(guard_clear_beat).timeout.connect(
			_go_to.bind("op_duel", "start"))


func _tick_duel() -> void:
	# 씬4: 접근하면 결투 전 대화 시작(말풍선이 화면 안에 들어오는 거리에서).
	if _intro_done or _boss == null:
		return
	if _player.global_position.distance_to(_boss.global_position) < DUEL_TRIGGER_DIST:
		_intro_done = true
		_cam_focus(_between(_player, _boss) + Vector2(0.0, -50.0), 1.85, 0.7)
		_start_dialog("intro", OpeningData.DUEL_INTRO)


# ── 대화 시스템 (컷씬 말풍선 — 화자별 부착·타자기·Z/A 진행) ──────

func _start_dialog(phase: String, lines: Array) -> void:
	_dialog_phase = phase
	_dialog_lines = lines
	_dialog_idx = 0
	_player.input_locked = true
	_player.velocity = Vector2.ZERO
	_show_dialog_line()


func _show_dialog_line() -> void:
	var ln: Dictionary = _dialog_lines[_dialog_idx]
	var who := String(ln["who"])
	var spk := _speaker_node(who)
	_bubble.attach(spk, _bubble_offset(who))
	_bubble.show_line(String(ln["text"]))


func _advance_dialog() -> void:
	if _bubble.is_typing():
		_bubble.complete()  # 첫 입력 = 타자기 스킵, 두 번째 = 다음 줄
		return
	_dialog_idx += 1
	if _dialog_idx < _dialog_lines.size():
		_show_dialog_line()
		return
	_bubble.hide_bubble()
	var done := _dialog_phase
	_dialog_phase = ""
	if done == "intro":
		_begin_duel()
	elif done == "end":
		_fade_to_world()


func _speaker_node(who: String) -> Node2D:
	match who:
		"prof":
			return _boss
		"guard":
			if _guard != null and is_instance_valid(_guard):
				return _guard
			return _chaser
	return _player


func _bubble_offset(who: String) -> Vector2:
	match who:
		"prof":
			return Vector2(0.0, -92.0)
		"guard":
			return Vector2(0.0, -64.0)
	return Vector2(0.0, -52.0)


func _say(who: String, key: String, dur: float) -> void:
	# 앰비언트 한 줄(조작 잠금 없음·자동 숨김) — 인물 대사는 전부 말풍선으로.
	var spk := _speaker_node(who)
	if spk == null or not is_instance_valid(spk):
		return
	_ambient.attach(spk, _bubble_offset(who))
	_ambient.show_ambient(String(OpeningData.AMBIENT_LINES.get(key, key)), dur)


func _say_later(who: String, key: String, delay: float, dur: float) -> void:
	get_tree().create_timer(delay).timeout.connect(_say.bind(who, key, dur))


# ── 결투 시퀀스 (씬5~6) ──────────────────────────────────────────

func _begin_duel() -> void:
	_cam_release()
	_player.input_locked = false
	_boss.set_target(_player)
	_player.set_enemies([_boss])
	_hud.show_toast("결투 개시 — 그녀는 움직이지 않는다")


func _on_gauge_broken() -> void:
	# 사고: 유탄이 마도구를 스침 — 카메라가 깨진 마도구로, 금 가는 연출 후 피니셔.
	if _reloading or not is_inside_tree():
		return
	_cutscene = true
	_player.input_locked = true
	_player.velocity = Vector2.ZERO
	if _artifact_prop != null:
		_artifact_prop.modulate = Color(0.55, 0.4, 0.4)
		_cam_focus(_artifact_prop.position + Vector2(0.0, -30.0), 2.0, 0.3)
	_juice.add_trauma(0.35)
	_flash(Color(1.0, 0.9, 0.6, 0.3), 0.2)
	get_tree().create_timer(crack_beat).timeout.connect(_boss.begin_finisher)


func _on_boss_stepped() -> void:
	# "한 발" — 보스 클로즈업 펀치 + 히트스톱.
	_cam_punch(_boss.global_position + Vector2(0.0, -24.0), 2.15)
	_juice.hitstop(0.08)


func _on_finisher_done() -> void:
	if _reloading or not is_inside_tree():
		return
	_flash(Color(1.0, 1.0, 1.0, 0.85), 0.5)
	# 연출 패배가 실제 사망이 되면 안 됨 — 체력 바닥 보장(3-2=1 생존)
	_player.health = maxi(_player.health, 3)
	_player.invuln_t = 0.0
	_player.take_damage(2, _boss.global_position)
	_player.velocity = Vector2.ZERO
	_player.input_locked = true
	get_tree().create_timer(down_beat).timeout.connect(_begin_end_dialog)


func _begin_end_dialog() -> void:
	if _reloading or not is_inside_tree():
		return
	_cam_focus(_between(_player, _boss) + Vector2(0.0, -50.0), 1.85, 0.8)
	_start_dialog("end", OpeningData.DUEL_END)


func _fade_to_world() -> void:
	if _reloading:
		return
	_reloading = true
	_fade_rect.visible = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, 1.1)
	tw.tween_callback(_enter_world)


func _enter_world() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")


# ── 컷씬 카메라 (플레이어 캠 ↔ 연출 캠 전환) ─────────────────────

func _ensure_cutcam() -> Camera2D:
	if _cutcam != null:
		return _cutcam
	_cutcam = Camera2D.new()
	_cutcam.limit_left = 0
	_cutcam.limit_top = 0
	_cutcam.limit_right = int(_room_size.x)
	_cutcam.limit_bottom = int(_room_size.y)
	add_child(_cutcam)
	return _cutcam


func _cam_focus(pos: Vector2, zoom: float, dur: float) -> void:
	# 현재 뷰에서 목표 지점/줌으로 부드럽게 이동(연출 캠 활성).
	var c := _ensure_cutcam()
	if not c.is_current():
		c.global_position = _cam.get_screen_center_position()
		c.zoom = _cam.zoom
		c.make_current()
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	_cam_tw = create_tween()
	_cam_tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_cam_tw.tween_property(c, "global_position", pos, dur)
	_cam_tw.parallel().tween_property(c, "zoom", Vector2(zoom, zoom), dur)


func _cam_punch(pos: Vector2, zoom: float) -> void:
	# 즉시 컷(펀치인) — "한 발" 같은 순간용.
	var c := _ensure_cutcam()
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	c.global_position = pos
	c.zoom = Vector2(zoom, zoom)
	c.make_current()


func _cam_release() -> void:
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	if _cam != null and is_instance_valid(_cam):
		_cam.make_current()


func _between(a: Node2D, b: Node2D) -> Vector2:
	return (a.global_position + b.global_position) * 0.5


# ── 이동·전환·입력 ───────────────────────────────────────────────

func _check_exits() -> void:
	var p := _player.global_position
	for ex in _exits:
		if (ex["rect"] as Rect2).has_point(p):
			if _room_id == "op_alley" and not _artifact_taken:
				if _exit_hint_t <= 0.0:
					_hud.show_toast("먼저 물건을 챙기자")
					_exit_hint_t = 1.6
				return
			_go_to(String(ex["to"]), String(ex["entry"]))
			return


func _go_to(room: String, entry: String) -> void:
	if _reloading:
		return
	_reloading = true
	GameState.opening_room = room
	GameState.opening_entry = entry
	get_tree().reload_current_scene()


func _restart_room() -> void:
	if _reloading:
		return
	_reloading = true
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var code: int = event.physical_keycode
	if _dialog_phase != "":
		if code in [KEY_Z, KEY_SPACE, KEY_A, KEY_ENTER]:
			_advance_dialog()
		get_viewport().set_input_as_handled()
		return
	if code == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/launcher.tscn")
	elif code == KEY_R and not _cutscene:
		_restart_room()


func _setup_input() -> void:
	_bind(&"move_left", [KEY_LEFT])
	_bind(&"move_right", [KEY_RIGHT])
	_bind(&"move_down", [KEY_DOWN])
	_bind(&"fly_up", [KEY_UP])
	_bind(&"jump", [KEY_Z, KEY_SPACE])
	_bind(&"dash", [KEY_C, KEY_SHIFT])
	_bind(&"cast", [KEY_X])
	_bind(&"ice_place", [KEY_Q])
	_bind(&"fly", [KEY_E])
	_bind(&"attack", [KEY_A])
	_bind(&"skill1", [KEY_S])
	_bind(&"skill2", [KEY_D])


func _bind(action: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	else:
		InputMap.action_erase_events(action)
	for kc in keycodes:
		var ev := InputEventKey.new()
		ev.physical_keycode = kc
		InputMap.action_add_event(action, ev)


# ── 배경·색조 (주스 패스: 시차 실루엣·달·씬 틴트·스포트) ─────────

func _build_backdrop() -> void:
	# 시차 스크롤 실루엣 2겹 + 달 — ParallaxBackground(월드 뒤 자체 레이어).
	var pb := ParallaxBackground.new()
	add_child(pb)
	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.18, 0.05)
	far.motion_mirroring = Vector2(3200.0, 0.0)
	pb.add_child(far)
	far.add_child(_make_moon(Vector2(520.0, 120.0)))
	for i in 10:
		var h := 200.0 + float((i * 97) % 180)
		var w := 200.0 + float((i * 53) % 140)
		var x := float(i) * 320.0
		far.add_child(_make_building(Rect2(x, 640.0 - h, w, h), Color(0.085, 0.095, 0.155)))
	var near := ParallaxLayer.new()
	near.motion_scale = Vector2(0.45, 0.12)
	near.motion_mirroring = Vector2(3200.0, 0.0)
	pb.add_child(near)
	for i in 8:
		var h := 130.0 + float((i * 71) % 120)
		var w := 240.0 + float((i * 89) % 130)
		var x := float(i) * 410.0
		near.add_child(_make_building(Rect2(x, 660.0 - h, w, h), Color(0.115, 0.13, 0.2)))


func _make_building(rect: Rect2, col: Color) -> Polygon2D:
	var b := Polygon2D.new()
	b.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	])
	b.color = col
	return b


func _make_moon(pos: Vector2) -> Node2D:
	var root := Node2D.new()
	root.position = pos
	var halo := Polygon2D.new()
	halo.polygon = _circle_pts(52.0)
	halo.color = Color(0.9, 0.93, 1.0, 0.14)
	root.add_child(halo)
	var disc := Polygon2D.new()
	disc.polygon = _circle_pts(32.0)
	disc.color = Color(0.93, 0.95, 1.0, 0.9)
	root.add_child(disc)
	return root


func _build_tint() -> void:
	# 씬 색조 — 월드 캔버스만 물들임(HUD·배경 레이어는 별개 캔버스).
	var cmod := CanvasModulate.new()
	cmod.color = ROOM_TINT.get(_room_id, Color(1.0, 1.0, 1.0))
	add_child(cmod)


func _build_spotlight(pos: Vector2) -> void:
	# 결투장 달빛 스포트 — 보스 바닥에 옅은 동심원 3겹(보스보다 먼저 추가 = 뒤에 깔림).
	var radii := [210.0, 140.0, 80.0]
	var alphas := [0.05, 0.08, 0.12]
	for i in 3:
		var ring := Polygon2D.new()
		ring.position = pos
		ring.polygon = _circle_pts(radii[i])
		ring.color = Color(0.86, 0.89, 1.0, alphas[i])
		add_child(ring)


func _circle_pts(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


# ── 빌드 (RoomBuilder 재사용 + 오프닝 소품) ──────────────────────

func _build_room(room: Dictionary) -> void:
	_build_outer_walls(_room_size)
	for r in room["solids"]:
		RoomBuilder.add_platform(self, r, RoomBuilder.WALL_COLOR)
	for r in room["plats"]:
		RoomBuilder.add_platform(self, r, RoomBuilder.PLAT_COLOR)
	for s in room.get("signs", []):
		RoomBuilder.add_sign(self, _font, s["pos"], String(s["text"]))
	_exits = room["exits"]
	for ex in _exits:
		RoomBuilder.add_exit_marker(
			self, _font, ex["rect"], String(ex.get("arrow", "right")),
			OpeningData.room_name(String(ex["to"])))


func _build_outer_walls(size: Vector2) -> void:
	RoomBuilder.add_platform(self, Rect2(0, 0, 20, size.y), RoomBuilder.WALL_COLOR)
	RoomBuilder.add_platform(self, Rect2(size.x - 20, 0, 20, size.y), RoomBuilder.WALL_COLOR)
	RoomBuilder.add_platform(self, Rect2(0, 0, size.x, 20), RoomBuilder.WALL_COLOR)


func _build_sleepers(pos: Vector2) -> void:
	# 잠든 식구들 — 어두운 실루엣 덩어리 2개(대사는 앰비언트 말풍선 한 줄).
	var root := Node2D.new()
	root.position = pos
	for i in 2:
		var body := Polygon2D.new()
		body.position = Vector2(float(i) * 34.0 - 17.0, 0.0)
		body.polygon = PackedVector2Array([
			Vector2(-16, 0), Vector2(-10, -12), Vector2(10, -12), Vector2(16, 0)])
		body.color = Color(0.16, 0.15, 0.2)
		root.add_child(body)
	add_child(root)


func _build_artifact(pos: Vector2, with_tag: bool) -> Node2D:
	# 마도구 — 발광 다이아 + '?' 라벨(정체 미정 = 떡밥).
	var root := Node2D.new()
	root.position = pos
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(16, 0), Vector2(0, 22), Vector2(-16, 0)])
	glow.color = Color(0.95, 0.8, 0.4, 0.35)
	root.add_child(glow)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(9, 0), Vector2(0, 13), Vector2(-9, 0)])
	core.color = Color(1.0, 0.9, 0.55)
	root.add_child(core)
	if with_tag:
		var tag := Label.new()
		tag.text = "?"
		tag.position = Vector2(-5, -46)
		tag.add_theme_font_override("font", _font)
		tag.add_theme_font_size_override("font_size", 16)
		tag.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		root.add_child(tag)
	add_child(root)
	return root


func _build_crate_prop(pos: Vector2) -> Node2D:
	var crate := Polygon2D.new()
	crate.position = pos
	crate.polygon = PackedVector2Array([
		Vector2(-26, 0), Vector2(26, 0), Vector2(26, 35), Vector2(-26, 35)])
	crate.color = Color(0.4, 0.32, 0.24)
	add_child(crate)
	return _build_artifact(pos + Vector2(0.0, -22.0), false)


func _setup_fade_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.visible = false
	layer.add_child(_fade_rect)


func _flash(col: Color, t: float) -> void:
	_fade_rect.visible = true
	_fade_rect.color = col
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, t)
	tw.tween_callback(_hide_fade)


func _hide_fade() -> void:
	if not _reloading:
		_fade_rect.visible = false


func _make_bubble() -> SpeechBubble:
	var b := SpeechBubble.new()
	b.setup(_font)
	add_child(b)
	return b


# ── 토스트 헬퍼 (UI 안내 전용 — 인물 대사는 말풍선) ──────────────

func _toast(key: String) -> void:
	_hud.show_toast(String(OpeningData.OPENING_TOASTS.get(key, key)))


func _toast_later(key: String, delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(_toast.bind(key))


# ── 스폰·카메라·HUD (world_room 패턴 재사용) ─────────────────────

func _spawn_player(pos: Vector2) -> CharacterBody2D:
	var packed := load("res://scenes/player.tscn") as PackedScene
	var p: CharacterBody2D = null
	if packed != null:
		p = packed.instantiate() as CharacterBody2D
	if p != null:
		print("[진단] player.tscn 인스턴스 성공 — 오프닝 공유 컨트롤러")
	else:
		push_warning("[진단] player.tscn 로드 실패 — 코드 생성 대체")
		p = CharacterBody2D.new()
		p.set_script(PlayerScript)
		var shape := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(20, 34)
		shape.shape = rs
		p.add_child(shape)
	p.name = "Player"
	p.position = pos
	add_child(p)
	return p


func _setup_camera(player: CharacterBody2D) -> Camera2D:
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(_room_size.x)
	cam.limit_bottom = int(_room_size.y)
	cam.set("position_smoothing_enabled", true)
	cam.set("position_smoothing_speed", 8.0)
	cam.zoom = Vector2(1.5, 1.5)  # §9.1: 960×540 창 → 640×360 월드뷰
	player.add_child(cam)
	cam.make_current()
	return cam


func _setup_hud(player: CharacterBody2D) -> CanvasLayer:
	var hud := CanvasLayer.new()
	hud.set_script(HudScript)
	add_child(hud)
	hud.bind(player)
	return hud


func _entry_pos(entries: Dictionary, entry: String) -> Vector2:
	if entries.has(entry):
		return entries[entry]
	push_warning("[진단] 입장 문 없음: %s — 기본 위치 대체" % entry)
	if entries.size() > 0:
		return entries.values()[0]
	return Vector2(100, 100)
