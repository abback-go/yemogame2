extends CharacterBody2D
## 이동 마법 테스트 컨트롤러 v2 — 능력 9종을 딕셔너리로 토글.
## 수치는 movement-spec.md v2 §2·§3의 시작값(F5 손 튜닝 전제).
## 상태 우선순위: 물 > 비행 > 벽달리기 > 대시 > 일반.
## v2 핵심: 전 이동 마나 소모 / 8방향 공중대시 / 부유 고정 / 얼음 발판 A키
## 설치형(이단점프와 완전 독립) / 활공 ↓홀드 / 물잠 익사(체력) / 비행 D키 발동형.

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
const HOVER_DRIFT := 40.0
const HOVER_DECEL := 1400.0
const HOVER_MAX_TIME := 2.0
const HOVER_COOLDOWN := 3.0
const GLIDE_FALL_MAX := 140.0
const GLIDE_UPDRAFT_RISE := -260.0
const SWIM_SPEED := 240.0
const FLY_SPEED := 300.0
const FLY_DURATION := 6.0
const FLY_COOLDOWN := 12.0
const MANA_MAX := 100.0
const MANA_REGEN_GROUND := 20.0
const MANA_REGEN_AIR := 6.0

# v2 마나 비용 (모든 이동 마법이 소모 — spec §2)
const DASH_MANA := 4.0
const DOUBLE_JUMP_MANA := 5.0
const HOVER_MANA_PER_SEC := 3.0
const WALL_RUN_MANA_PER_SEC := 6.0
const ICE_PLATFORM_MANA := 12.0
const GLIDE_MANA_PER_SEC := 2.0
const SWIM_MANA_PER_SEC := 8.0
const FLY_MANA_COST := 45.0

# 얼음 발판 설치형 (spec §2-6)
const ICE_PLATFORM_LIFE := 3.0
const ICE_PLATFORM_MAX := 1
const ICE_PLATFORM_COOLDOWN := 5.0

# 체력·익사 (spec §2-8·§4)
const HEALTH_MAX := 5
const DROWN_INTERVAL := 2.0
const MANA_BLINK_TIME := 0.4

# 물잠 산소 3단 버퍼 (spec §2.1-8: 산소 → 마나 → 체력)
const OXYGEN_MAX := 100.0
const OXYGEN_DRAIN_PER_SEC := 10.0
const OXYGEN_REGEN_PER_SEC := 40.0

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
# 능력별 마나 비용 표기 (HUD 토글 목록 옆)
const ABILITY_COSTS := {
	"dash_ground": "마나 4",
	"dash_air": "마나 4",
	"hover": "마나 3/초",
	"double_jump": "마나 5",
	"wall_run": "마나 6/초",
	"ice_platform": "마나 12/개",
	"glide": "마나 2/초",
	"water_dive": "산소→마나 8/초",
	"flight": "마나 45 선불",
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
var oxygen := OXYGEN_MAX
var health := HEALTH_MAX
var state_name := "일반"
var coyote := 0.0
var jump_buf := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector2.ZERO
var wall_run_t := 0.0
var wall_locked_side := 0
var wall_running := false
var air_dash_used := false
var double_jump_used := false
var hovering := false
var hover_t := 0.0
var hover_cd := 0.0
var ice_cd := 0.0
var flying := false
var fly_t := 0.0
var fly_cd := 0.0
var drown_t := 0.0
var drowning := false
var mana_blink := 0.0
var mana_draining := false
var in_water := false
var in_updraft := false
var face := 1
var start_pos := Vector2.ZERO
var fall_limit := 2000.0
var water_rects: Array[Rect2] = []
var updraft_rects: Array[Rect2] = []
var ice_platforms: Array[Node] = []
var air_bubbles: Array[Dictionary] = []

func _ready() -> void:
	start_pos = position

func toggle_ability(key: String) -> bool:
	if not abilities.has(key):
		return false
	abilities[key] = not abilities[key]
	return abilities[key]

func refill_mana() -> void:
	mana = MANA_MAX
	oxygen = OXYGEN_MAX

func respawn() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO
	mana = MANA_MAX
	oxygen = OXYGEN_MAX
	health = HEALTH_MAX
	air_dash_used = false
	double_jump_used = false
	hovering = false
	hover_t = 0.0
	hover_cd = 0.0
	ice_cd = 0.0
	wall_run_t = 0.0
	wall_locked_side = 0
	wall_running = false
	flying = false
	fly_t = 0.0
	fly_cd = 0.0
	drown_t = 0.0
	drowning = false
	_clear_ice_platforms()

func set_zones(water: Array[Rect2], updraft: Array[Rect2]) -> void:
	water_rects = water
	updraft_rects = updraft

func register_air_bubble(node: Node2D) -> void:
	# 산소통(공기 방울) 등록 — main이 노드 참조 직접 전달 (spec §2.1-8)
	air_bubbles.append({"node": node, "active": true})

func ice_count() -> int:
	var n := 0
	for p in ice_platforms:
		if is_instance_valid(p):
			n += 1
	return n

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_read_facing()
	_buffer_jump()
	_update_zones()
	_recover_on_contact()
	_try_start_dash()
	_try_place_ice()
	_try_start_flight()

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
	_regen_oxygen(delta)
	move_and_slide()
	_check_air_bubbles()
	_post_move()
	queue_redraw()

func _tick_timers(delta: float) -> void:
	coyote -= delta
	jump_buf -= delta
	dash_cd -= delta
	fly_cd = maxf(0.0, fly_cd - delta)
	hover_cd = maxf(0.0, hover_cd - delta)
	ice_cd = maxf(0.0, ice_cd - delta)
	mana_blink = maxf(0.0, mana_blink - delta)
	mana_draining = false
	drowning = false

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
	if not in_water:
		drown_t = 0.0
	# 물에 잠기면 비행 강제 해제 (물 상태가 최우선)
	if in_water and flying:
		_end_flight()

func _in_any(rects: Array) -> bool:
	for r in rects:
		if r.has_point(global_position):
			return true
	return false

func _recover_on_contact() -> void:
	# 착지: 공중 자원 회복 (spec §2-2·3·4). 비행은 시간제라 착지로 안 풀림.
	if is_on_floor():
		coyote = COYOTE_TIME
		air_dash_used = false
		double_jump_used = false
		# 착지: 벽 잠금 해제(spec §2-5) + 부유 쿨 즉시 초기화(spec §2-3)
		wall_locked_side = 0
		wall_running = false
		hovering = false
		hover_cd = 0.0
	# 벽 접촉: 공중 대시만 회복 (spec §2-2)
	if is_on_wall():
		air_dash_used = false

func _flash_mana() -> void:
	# 마나 부족 피드백: HUD 마나 바 깜빡임 (spec §2 공통 원칙)
	mana_blink = MANA_BLINK_TIME

func _try_start_dash() -> void:
	if in_water or flying:
		return
	if not Input.is_action_just_pressed("dash"):
		return
	if dash_cd > 0.0 or dash_t > 0.0:
		return
	if is_on_floor():
		if abilities["dash_ground"]:
			_attempt_dash(Vector2(float(face), 0.0), false)
	elif abilities["dash_air"] and not air_dash_used:
		_attempt_dash(_air_dash_dir(), true)

func _attempt_dash(dir: Vector2, is_air: bool) -> void:
	if mana < DASH_MANA:
		_flash_mana()
		return
	if is_air:
		air_dash_used = true
	mana -= DASH_MANA
	dash_dir = dir
	dash_t = DASH_TIME
	dash_cd = DASH_COOLDOWN

func _air_dash_dir() -> Vector2:
	# 공중 대시: 방향키 8방향(대각 정규화). 무입력=바라보는 방향 수평.
	var h := Input.get_axis("move_left", "move_right")
	var v := Input.get_axis("fly_up", "move_down")
	var d := Vector2(h, v)
	if d == Vector2.ZERO:
		return Vector2(float(face), 0.0)
	return d.normalized()

func _dash_move(delta: float) -> void:
	# 대시 중: 시작 방향 고정, 중력 0 (지상=수평, 공중=8방향)
	dash_t -= delta
	velocity = dash_dir * DASH_SPEED
	state_name = "대시"

func _try_place_ice() -> void:
	# A 키: 발밑에 얼음 발판 설치 (동시 1개·쿨 5초, spec §2-6)
	if not Input.is_action_just_pressed("ice_place"):
		return
	if not abilities["ice_platform"]:
		return
	# 설계 의도: 쿨(5s) > 유지(3s) → 연속 설치 공중 사다리 불가.
	# 쿨 중엔 마나 부족과 달리 조용히 리턴(_flash_mana 없음, spec §2-6)
	if ice_cd > 0.0:
		return
	if mana < ICE_PLATFORM_MANA:
		_flash_mana()
		return
	mana -= ICE_PLATFORM_MANA
	ice_cd = ICE_PLATFORM_COOLDOWN
	_spawn_ice_platform()

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
	ice_platforms.append(plat)
	# 동시 최대 1개: 새로 설치 시 기존 즉시 파괴 (spec §2-6)
	while ice_platforms.size() > ICE_PLATFORM_MAX:
		var old: Node = ice_platforms.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	get_tree().create_timer(ICE_PLATFORM_LIFE).timeout.connect(
		_on_ice_expire.bind(plat))

func _on_ice_expire(plat: Node) -> void:
	ice_platforms.erase(plat)
	if is_instance_valid(plat):
		plat.queue_free()

func _clear_ice_platforms() -> void:
	for p in ice_platforms:
		if is_instance_valid(p):
			p.queue_free()
	ice_platforms.clear()

func _try_start_flight() -> void:
	# D 키 발동형: 마나 45 선불·6초 자유비행·쿨 12초 (spec §2-9)
	if not Input.is_action_just_pressed("fly"):
		return
	if not abilities["flight"] or flying or fly_cd > 0.0:
		return
	if mana < FLY_MANA_COST:
		_flash_mana()
		return
	mana -= FLY_MANA_COST
	flying = true
	fly_t = FLY_DURATION
	wall_running = false

func _do_flight(delta: float) -> bool:
	if not flying:
		return false
	fly_t -= delta
	if fly_t <= 0.0:
		_end_flight()
		return false
	# 방향키 8방향 300, 정규화, 중력 무시
	var h := Input.get_axis("move_left", "move_right")
	var v := Input.get_axis("fly_up", "move_down")
	var mv := Vector2(h, v)
	if mv.length() > 1.0:
		mv = mv.normalized()
	velocity = mv * FLY_SPEED
	mana_draining = true
	state_name = "비행"
	return true

func _end_flight() -> void:
	if flying:
		fly_cd = FLY_COOLDOWN
	flying = false
	fly_t = 0.0

func _do_wall_run(delta: float) -> bool:
	# 벽 상호작용(주행 시작·벽도약) 순간 그 방향으로 잠긴다. 잠긴 방향엔
	# 재부착·재도약 불가 (spec §2-5: 같은 방향 벽 재부착 금지 — 무한 상승 봉쇄).
	if not abilities["wall_run"] or is_on_floor() or not is_on_wall():
		wall_running = false
		return false
	var normal := get_wall_normal()
	var wall_side := -1 if normal.x > 0.0 else 1
	var dir := int(Input.get_axis("move_left", "move_right"))
	# 벽도약: 진행 중인 같은 방향 주행에서만 허용 (재부착 도약은 금지)
	if Input.is_action_just_pressed("jump"):
		var can_jump := wall_running and wall_side == wall_locked_side
		wall_running = false
		if can_jump:
			velocity.x = float(-wall_side) * WALL_JUMP_X
			velocity.y = WALL_JUMP_Y
			wall_locked_side = wall_side
			wall_run_t = 0.0
			state_name = "벽도약"
		return can_jump
	# 벽 향해 밀지 않거나(해제) 잠긴 방향 재부착이면 주행 불가 (잠금 유지, spec §2-5)
	var reattach := wall_side == wall_locked_side and not wall_running
	if dir != wall_side or reattach:
		wall_running = false
		return false
	# 새 상호작용 시작(반대 벽·착지 후 첫 벽): 잠금·타이머만 리셋
	if not wall_running:
		wall_locked_side = wall_side
		wall_run_t = WALL_RUN_MAX
	# 타이머·마나 소진 시 주행 종료(잠금은 그대로 유지)
	if wall_run_t <= 0.0 or mana <= 0.0:
		wall_running = false
		return false
	wall_run_t -= delta
	mana = maxf(0.0, mana - WALL_RUN_MANA_PER_SEC * delta)
	mana_draining = true
	velocity.y = -WALL_RUN_SPEED
	velocity.x = float(wall_side) * 40.0
	wall_running = true
	state_name = "벽달리기"
	return true

func _water_move(delta: float) -> void:
	wall_running = false
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, dir * SWIM_SPEED, ACCEL * delta)
	# Z로 물 밖으로 튀어나가기 (다음 프레임 존 이탈)
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		state_name = "물 탈출"
		return
	if not abilities["water_dive"]:
		# 물잠 OFF: 수면 부유만 (잠수 불가, spec §2-8)
		var surface := _water_surface_y()
		if global_position.y > surface:
			velocity.y = maxf(-SWIM_SPEED, (surface - global_position.y) * 8.0)
		else:
			velocity.y = 0.0
		state_name = "수면"
		return
	# 물잠 ON: 마나와 무관하게 4방향 잠수 가능 (spec §2-8)
	var v := Input.get_axis("fly_up", "move_down")
	velocity.y = move_toward(velocity.y, v * SWIM_SPEED, ACCEL * delta)
	# 잠수 판정: 수면보다 10px 이상 아래여야 자원 소모 (spec §2.1-8)
	if global_position.y <= _water_surface_y() + 10.0:
		# 수면 근처: 무소모 (산소는 _regen_oxygen이 40/s 회복)
		drown_t = 0.0
		state_name = "수영"
		return
	# 잠수 중 3단 버퍼: ①산소 → ②마나 → ③체력(익사) (spec §2.1-8)
	if oxygen > 0.0:
		oxygen = maxf(0.0, oxygen - OXYGEN_DRAIN_PER_SEC * delta)
		drown_t = 0.0
		state_name = "수영"
	elif mana > 0.0:
		mana = maxf(0.0, mana - SWIM_MANA_PER_SEC * delta)
		mana_draining = true
		drown_t = 0.0
		state_name = "수영"
	else:
		# 산소·마나 모두 0: 익사 — 2초당 체력 1 소모 (spec §2.1-8)
		_drown(delta)
		state_name = "익사"

func _drown(delta: float) -> void:
	drowning = true
	drown_t += delta
	if drown_t >= DROWN_INTERVAL:
		drown_t -= DROWN_INTERVAL
		health -= 1
		if health <= 0:
			respawn()

func _water_surface_y() -> float:
	for r in water_rects:
		if r.has_point(global_position):
			return r.position.y
	return global_position.y

func _check_air_bubbles() -> void:
	# 물속에서 활성 공기 방울 접촉(30px) 시 산소 리필 → 5초 뒤 재생성 (spec §2.1-8)
	if not in_water:
		return
	if oxygen > OXYGEN_MAX - 5.0:
		return  # 산소가 거의 가득이면 방울을 낭비하지 않는다
	for bubble in air_bubbles:
		if not bubble["active"]:
			continue
		var node: Node2D = bubble["node"]
		if not is_instance_valid(node):
			continue
		if global_position.distance_to(node.global_position) < 30.0:
			oxygen = OXYGEN_MAX
			bubble["active"] = false
			node.visible = false
			get_tree().create_timer(5.0).timeout.connect(
				_on_air_bubble_respawn.bind(bubble))

func _on_air_bubble_respawn(bubble: Dictionary) -> void:
	bubble["active"] = true
	var node: Node2D = bubble["node"]
	if is_instance_valid(node):
		node.visible = true

func _normal_move(delta: float) -> void:
	if _apply_hover(delta):
		_hover_move(delta)
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * RUN_SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)

	velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)

	if _glide_active():
		if in_updraft:
			velocity.y = GLIDE_UPDRAFT_RISE
		else:
			velocity.y = minf(velocity.y, GLIDE_FALL_MAX)
		mana = maxf(0.0, mana - GLIDE_MANA_PER_SEC * delta)
		mana_draining = true
		state_name = "활공"
	else:
		state_name = "일반"

	if Input.is_action_just_released("jump") and velocity.y < JUMP_CUT:
		velocity.y = JUMP_CUT

	_handle_jump()

func _apply_hover(delta: float) -> bool:
	# X 홀드 + 공중: 지속 2.0초 · 해제 후 쿨 3.0초 (spec §2-3)
	if not abilities["hover"] or is_on_floor():
		if hovering:
			_end_hover()
		return false
	var held := Input.is_action_pressed("cast")
	if not hovering:
		# 시작: 능력 ON + 공중 + X 홀드 + 마나 > 0 + 쿨 없음
		if not (held and mana > 0.0 and hover_cd <= 0.0):
			return false
		hovering = true
		hover_t = HOVER_MAX_TIME
	# 홀드 해제·마나 0·지속 만료 중 하나면 해제(부분 사용도 쿨 전액)
	if not held or mana <= 0.0 or hover_t <= 0.0:
		_end_hover()
		return false
	hover_t -= delta
	mana = maxf(0.0, mana - HOVER_MANA_PER_SEC * delta)
	mana_draining = true
	return true

func _end_hover() -> void:
	# 해제 시 쿨 전액 부과 — 펄스 홀드로 지속 연장 방지 (spec §2-3).
	# 착지 해제만 _recover_on_contact에서 hover_cd를 즉시 0으로 지운다.
	if hovering:
		hover_cd = HOVER_COOLDOWN
	hovering = false
	hover_t = 0.0

func _hover_move(delta: float) -> void:
	# 그 자리·그 높이 고정(속도 급감쇠 →0) + 방향키 초당 40 미세 표류
	var drift := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("fly_up", "move_down"))
	if drift.length() > 1.0:
		drift = drift.normalized()
	var target := drift * HOVER_DRIFT
	velocity.x = move_toward(velocity.x, target.x, HOVER_DECEL * delta)
	velocity.y = move_toward(velocity.y, target.y, HOVER_DECEL * delta)
	state_name = "부유"

func _glide_active() -> bool:
	# ↓ 홀드 + 공중, 하강 중이거나 상승기류 위 (spec §2-7)
	if not abilities["glide"] or is_on_floor():
		return false
	if not Input.is_action_pressed("move_down") or mana <= 0.0:
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
	# 순수 공중 점프 — 얼음 발판과 완전 독립 (spec §2-4)
	if abilities["double_jump"] and not double_jump_used:
		if mana < DOUBLE_JUMP_MANA:
			_flash_mana()
			return
		velocity.y = DOUBLE_JUMP_VELOCITY
		double_jump_used = true
		mana -= DOUBLE_JUMP_MANA
		jump_buf = 0.0

func _regen_mana(delta: float) -> void:
	if mana_draining or in_water:
		return
	var rate := MANA_REGEN_GROUND if is_on_floor() else MANA_REGEN_AIR
	mana = minf(MANA_MAX, mana + rate * delta)

func _regen_oxygen(delta: float) -> void:
	# 잠수 중이 아니면 산소 40/s 회복 (물 밖·수면, spec §2.1-8)
	if in_water and global_position.y > _water_surface_y() + 10.0:
		return
	oxygen = minf(OXYGEN_MAX, oxygen + OXYGEN_REGEN_PER_SEC * delta)

func _post_move() -> void:
	if global_position.y > fall_limit:
		respawn()

func _draw() -> void:
	# 임시 비주얼: 상태별 몸통색 + 지팡이 + 비행 날개
	if flying:
		var wcol := Color(0.96, 0.96, 1.0, 0.9)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-3.0, -6.0), Vector2(-24.0, -20.0), Vector2(-6.0, 8.0)]), wcol)
		draw_colored_polygon(PackedVector2Array([
			Vector2(3.0, -6.0), Vector2(24.0, -20.0), Vector2(6.0, 8.0)]), wcol)
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
