extends CharacterBody2D
## 이동 마법 테스트 컨트롤러 — 능력 9종을 딕셔너리로 토글.
## 수치는 movement-spec.md §2·§3의 시작값(F5 손 튜닝 전제).
## 상태 우선순위: 물 > 비행 > 벽달리기 > 대시 > 일반.

const RUN_SPEED := 280.0
const ACCEL := 2600.0
const DECEL := 3200.0
const GRAVITY := 1500.0
const FALL_MAX := 900.0
const JUMP_VELOCITY := -620.0
const JUMP_CUT := -180.0
const COYOTE_TIME := 0.09
const JUMP_BUFFER := 0.12
const DASH_SPEED := 620.0
const DASH_TIME := 0.14
const DASH_COOLDOWN := 0.38
const DOUBLE_JUMP_VELOCITY := -560.0
const WALL_RUN_SPEED := 380.0
const WALL_RUN_MAX := 0.8
const WALL_JUMP_X := 420.0
const WALL_JUMP_Y := -520.0
const ICE_JUMP_VELOCITY := -620.0
const ICE_PLATFORM_LIFE := 0.75
const HOVER_GRAVITY_SCALE := 0.15
const HOVER_MAX := 0.6
const GLIDE_FALL_MAX := 140.0
const GLIDE_UPDRAFT_RISE := -260.0
const SWIM_SPEED := 240.0
const SWIM_MANA_PER_SEC := 8.0
const FLY_SPEED := 300.0
const FLY_MANA_PER_SEC := 12.0
const MANA_MAX := 100.0
const MANA_REGEN_GROUND := 20.0
const MANA_REGEN_AIR := 6.0

# HUD·main과 공유하는 능력 순서/한글명 (단일 출처)
const ABILITY_KEYS := [
	"dash_ground", "dash_air", "hover", "double_jump", "wall_run",
	"ice_platform", "glide", "water_dive", "flight",
]
const ABILITY_LABELS := {
	"dash_ground": "대시(지상)",
	"dash_air": "대시(공중)",
	"hover": "부유",
	"double_jump": "이단점프",
	"wall_run": "벽달리기",
	"ice_platform": "얼음 발판",
	"glide": "활공",
	"water_dive": "물잠",
	"flight": "비행",
}

# 시작 킷만 기본 ON (spec §2)
var abilities := {
	"dash_ground": true,
	"dash_air": true,
	"hover": true,
	"double_jump": false,
	"wall_run": false,
	"ice_platform": false,
	"glide": false,
	"water_dive": false,
	"flight": false,
}

var mana := MANA_MAX
var state_name := "일반"
var coyote := 0.0
var jump_buf := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var hover_left := HOVER_MAX
var wall_run_t := 0.0
var wall_active_side := 0
var last_wall_dir := 0
var air_dash_used := false
var double_jump_used := false
var flying := false
var mana_draining := false
var in_water := false
var in_updraft := false
var face := 1
var start_pos := Vector2.ZERO
var fall_limit := 2000.0
var water_rects: Array[Rect2] = []
var updraft_rects: Array[Rect2] = []

func _ready() -> void:
	start_pos = position

func toggle_ability(key: String) -> bool:
	if not abilities.has(key):
		return false
	abilities[key] = not abilities[key]
	return abilities[key]

func refill_mana() -> void:
	mana = MANA_MAX

func respawn() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO
	mana = MANA_MAX
	air_dash_used = false
	double_jump_used = false
	hover_left = HOVER_MAX
	wall_run_t = 0.0
	wall_active_side = 0
	last_wall_dir = 0
	flying = false

func set_zones(water: Array[Rect2], updraft: Array[Rect2]) -> void:
	water_rects = water
	updraft_rects = updraft

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_read_facing()
	_buffer_jump()
	_update_zones()
	_recover_on_contact()
	_try_start_dash()

	if in_water:
		_water_move(delta)
	elif _do_flight(delta):
		pass
	elif _do_wall_run(delta):
		pass
	elif dash_t > 0.0:
		_dash_move(delta)
	else:
		_normal_move(delta)

	_regen_mana(delta)
	move_and_slide()
	_post_move()
	queue_redraw()

func _tick_timers(delta: float) -> void:
	coyote -= delta
	jump_buf -= delta
	dash_cd -= delta
	mana_draining = false

func _read_facing() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		face = 1 if dir > 0.0 else -1

func _buffer_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buf = JUMP_BUFFER

func _update_zones() -> void:
	in_water = _in_any(water_rects)
	in_updraft = _in_any(updraft_rects)

func _in_any(rects: Array) -> bool:
	for r in rects:
		if r.has_point(global_position):
			return true
	return false

func _recover_on_contact() -> void:
	# 착지: 공중 자원 전부 회복 (spec §2-2·3·4·6)
	if is_on_floor():
		coyote = COYOTE_TIME
		air_dash_used = false
		double_jump_used = false
		hover_left = HOVER_MAX
		last_wall_dir = 0
		wall_active_side = 0
		flying = false
	# 벽 접촉: 공중 대시만 회복 (spec §2-2)
	if is_on_wall():
		air_dash_used = false

func _try_start_dash() -> void:
	if in_water or flying:
		return
	if not Input.is_action_just_pressed("dash"):
		return
	if dash_cd > 0.0 or dash_t > 0.0:
		return
	if is_on_floor():
		if abilities["dash_ground"]:
			_begin_dash()
	elif abilities["dash_air"] and not air_dash_used:
		air_dash_used = true
		_begin_dash()

func _begin_dash() -> void:
	dash_t = DASH_TIME
	dash_cd = DASH_COOLDOWN

func _dash_move(delta: float) -> void:
	# 대시 중: 수평 고정, 중력 0 (프로토타입 이식)
	dash_t -= delta
	velocity.x = float(face) * DASH_SPEED
	velocity.y = 0.0
	state_name = "대시"

func _do_flight(delta: float) -> bool:
	if not abilities["flight"] or is_on_floor():
		flying = false
		return false
	# ↑ 홀드로 유지, 마나 소진 시 자동 해제 (spec §2-9)
	if not Input.is_action_pressed("fly_up") or mana <= 0.0:
		flying = false
		return false
	flying = true
	mana_draining = true
	var spd := FLY_SPEED
	var cost := FLY_MANA_PER_SEC
	if in_updraft:
		spd *= 1.5
		cost *= 0.5
	var h := Input.get_axis("move_left", "move_right")
	var v := Input.get_axis("fly_up", "move_down")
	var mv := Vector2(h, v)
	if mv.length() > 1.0:
		mv = mv.normalized()
	velocity = mv * spd
	mana = maxf(0.0, mana - cost * delta)
	state_name = "비행"
	return true

func _do_wall_run(delta: float) -> bool:
	if not abilities["wall_run"] or is_on_floor() or not is_on_wall():
		return false
	var normal := get_wall_normal()
	var wall_side := -1 if normal.x > 0.0 else 1
	# 벽도약: Z로 벽 반대 방향 튕김 (같은 벽 재달리기 잠금)
	if Input.is_action_just_pressed("jump"):
		velocity.x = float(-wall_side) * WALL_JUMP_X
		velocity.y = WALL_JUMP_Y
		last_wall_dir = wall_side
		wall_run_t = 0.0
		wall_active_side = 0
		state_name = "벽도약"
		return true
	var dir := Input.get_axis("move_left", "move_right")
	if int(dir) != wall_side or wall_side == last_wall_dir:
		return false
	if wall_side != wall_active_side:
		wall_active_side = wall_side
		wall_run_t = WALL_RUN_MAX
	if wall_run_t <= 0.0:
		last_wall_dir = wall_side
		return false
	wall_run_t -= delta
	velocity.y = -WALL_RUN_SPEED
	velocity.x = float(wall_side) * 40.0
	state_name = "벽달리기"
	return true

func _water_move(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, dir * SWIM_SPEED, ACCEL * delta)
	# Z로 물 밖으로 튀어나가기 (다음 프레임 존 이탈)
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		state_name = "물 탈출"
		return
	# 물잠 ON + 마나>0: 4방향 수영 / 아니면 수면 뜨기 (spec §2-8)
	if abilities["water_dive"] and mana > 0.0:
		var v := Input.get_axis("fly_up", "move_down")
		velocity.y = move_toward(velocity.y, v * SWIM_SPEED, ACCEL * delta)
		mana = maxf(0.0, mana - SWIM_MANA_PER_SEC * delta)
		mana_draining = true
		state_name = "수영"
	else:
		var surface := _water_surface_y()
		if global_position.y > surface:
			velocity.y = maxf(-SWIM_SPEED, (surface - global_position.y) * 8.0)
		else:
			velocity.y = 0.0
		state_name = "수면"

func _water_surface_y() -> float:
	for r in water_rects:
		if r.has_point(global_position):
			return r.position.y
	return global_position.y

func _normal_move(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * RUN_SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)

	var g := GRAVITY
	var hovering := _apply_hover(delta)
	if hovering:
		g *= HOVER_GRAVITY_SCALE
	velocity.y = minf(velocity.y + g * delta, FALL_MAX)

	if not hovering and _glide_active():
		if in_updraft:
			velocity.y = GLIDE_UPDRAFT_RISE
		else:
			velocity.y = minf(velocity.y, GLIDE_FALL_MAX)
		state_name = "활공"
	elif hovering:
		state_name = "부유"
	else:
		state_name = "일반"

	if Input.is_action_just_released("jump") and velocity.y < JUMP_CUT:
		velocity.y = JUMP_CUT

	_handle_jump()

func _apply_hover(delta: float) -> bool:
	# X 홀드 + 공중, 잔여 시간 소모 (착지 시 회복)
	if not abilities["hover"] or is_on_floor():
		return false
	if not Input.is_action_pressed("cast") or hover_left <= 0.0:
		return false
	hover_left -= delta
	return true

func _glide_active() -> bool:
	# Z 홀드 + 공중, 하강 중이거나 상승기류 위 (spec §2-7)
	if not abilities["glide"] or is_on_floor():
		return false
	if not Input.is_action_pressed("jump"):
		return false
	return velocity.y > 0.0 or in_updraft

func _handle_jump() -> void:
	# 지상 점프 (선입력 + 코요테)
	if jump_buf > 0.0 and coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buf = 0.0
		coyote = 0.0
		return
	if not Input.is_action_just_pressed("jump"):
		return
	if is_on_floor() or coyote > 0.0:
		return
	# 공중 Z: 얼음 발판이 이단점프보다 우선 (spec §2-6)
	if abilities["ice_platform"] and not double_jump_used:
		_spawn_ice_platform()
		velocity.y = ICE_JUMP_VELOCITY
		double_jump_used = true
		jump_buf = 0.0
	elif abilities["double_jump"] and not double_jump_used:
		velocity.y = DOUBLE_JUMP_VELOCITY
		double_jump_used = true
		jump_buf = 0.0

func _spawn_ice_platform() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var plat := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(72.0, 14.0)
	shape.shape = rs
	plat.add_child(shape)
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-36.0, -7.0), Vector2(36.0, -7.0),
		Vector2(36.0, 7.0), Vector2(-36.0, 7.0),
	])
	vis.color = Color(0.6, 0.85, 1.0, 0.55)
	plat.add_child(vis)
	parent.add_child(plat)
	plat.global_position = global_position + Vector2(0.0, 24.0)
	get_tree().create_timer(ICE_PLATFORM_LIFE).timeout.connect(plat.queue_free)

func _regen_mana(delta: float) -> void:
	if mana_draining:
		return
	var rate := MANA_REGEN_GROUND if is_on_floor() else MANA_REGEN_AIR
	mana = minf(MANA_MAX, mana + rate * delta)

func _post_move() -> void:
	if global_position.y > fall_limit:
		respawn()

func _draw() -> void:
	# 임시 비주얼: 상태별 몸통색 + 지팡이
	var body_color := Color(0.93, 0.91, 0.86)
	if flying:
		body_color = Color(0.75, 0.6, 1.0)
	elif in_water:
		body_color = Color(0.45, 0.7, 1.0)
	elif dash_t > 0.0:
		body_color = Color(0.6, 0.9, 1.0)
	draw_rect(Rect2(-10.0, -17.0, 20.0, 34.0), body_color)
	var tip := Vector2(15.0 * float(face), -14.0)
	draw_line(Vector2(6.0 * float(face), 4.0), tip, Color(0.83, 0.62, 0.25), 3.0)
	draw_circle(tip, 3.0, Color(0.4, 0.75, 1.0))
