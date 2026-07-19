extends CharacterBody2D
## 이동 마법 테스트 컨트롤러 v2 — 능력 9종을 딕셔너리로 토글.
## 수치는 movement-spec.md v2 §2·§3의 시작값(F5 손 튜닝 전제).
## 상태 우선순위: 물 > 비행 > 벽달리기 > 대시 > 일반.
## v2 핵심: 전 이동 마나 소모 / 8방향 공중대시 / 부유 고정 / 얼음 발판 A키
## 설치형(이단점프와 완전 독립) / 활공 ↓홀드 / 물잠 익사(체력) / 비행 D키 발동형.

# 사망(health<=0)·낙사 신호 — 수직 슬라이스가 거점 리스폰 전환에 연결(아레나는 미연결).
signal died

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

# ─────────────────────────────────────────────────────────────
# 전투 코어 (combat-spec v0.1) — 얼음/창 트라이얼. 수치는 전부 시작값,
# 인스펙터 @export로 F5 손 튜닝. 공격 상태머신 페이즈 상수:
const AP_NONE := 0
const AP_STARTUP := 1
const AP_ACTIVE := 2
const AP_RECOVERY := 3

@export_group("기본 공격 · 타이밍")
@export var atk1_startup := 0.08
@export var atk1_active := 0.06
@export var atk1_recovery := 0.12
@export var atk2_startup := 0.07
@export var atk2_active := 0.06
@export var atk2_recovery := 0.12
@export var atk3_startup := 0.12
@export var atk3_active := 0.08
@export var atk3_recovery := 0.22
@export var combo_buffer_time := 0.25
@export var combo_reset_time := 0.5

@export_group("기본 공격 · 판정/런지")
@export var atk1_reach := 64.0
@export var atk2_reach := 64.0
@export var atk3_reach := 88.0
@export var attack_hitbox_height := 24.0
@export var atk_lunge_light := 240.0
@export var atk_lunge_heavy := 380.0
@export var atk_knockback_light := 160.0
@export var atk_knockback_heavy := 320.0
@export var atk_mana_light := 3.0
@export var atk_mana_heavy := 5.0
@export var atk_damage_light := 1
@export var atk_damage_heavy := 2

@export_group("스킬1 · 관통 서리창 (K)")
@export var skill1_cooldown := 6.0
@export var skill1_mana := 20.0
@export var skill1_damage := 3
@export var skill1_reach := 160.0
@export var skill1_dash_dist := 140.0
@export var skill1_dash_time := 0.2
@export var skill1_cast_tell := 0.15
@export var skill1_slow_factor := 0.4
@export var skill1_slow_time := 2.0

@export_group("스킬2 · 빙정 폭발 (L)")
@export var skill2_cooldown := 9.0
@export var skill2_mana := 30.0
@export var skill2_damage := 2
@export var skill2_radius := 90.0
@export var skill2_cast_tell := 0.18
@export var skill2_stun_time := 0.6
@export var skill2_knockback := 320.0

@export_group("불 전공 · 발밑 화염 (S)")
@export var fire_skill1_cooldown := 6.0
@export var fire_skill1_mana := 20.0
@export var fire_skill1_damage := 3
@export var fire_skill1_cast_tell := 0.25
@export var fire_skill1_width := 74.0
@export var fire_skill1_height := 150.0
@export var fire_skill1_range := 360.0
@export var fire_skill1_knockback := 130.0

@export_group("불 전공 · 메테오 (D)")
@export var fire_skill2_cooldown := 9.0
@export var fire_skill2_mana := 30.0
@export var fire_skill2_damage := 4
@export var fire_skill2_cast_tell := 0.35
@export var fire_skill2_radius := 110.0
@export var fire_skill2_range := 520.0
@export var fire_skill2_knockback := 340.0
@export var fire_skill2_fall_time := 0.45
@export var fire_skill2_stun := 0.4

@export_group("불 전공 · 스프라이트")
@export var fire_sprite_offset := Vector2(0.0, 0.0)
@export var fire_sprite_scale := 1.0

@export_group("피격 · 주스")
@export var invuln_time := 0.6
@export var damage_knockback := 220.0
@export var hitstop_light := 0.04
@export var hitstop_heavy := 0.09
@export var trauma_light := 0.2
@export var trauma_heavy := 0.4
@export var trauma_land := 0.15
@export var squash_recover_speed := 12.0
@export var land_shake_min_speed := 260.0

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

# 전투 상태 (combat-spec §2·§3)
var attack_step := 0
var combo_index := 0
var attack_phase := AP_NONE
var attack_phase_t := 0.0
var attack_hit_done := false
var attack_buffer_t := 0.0
var attack_cancelable := false
var combo_reset_t := 0.0
var attack_face := 1
# v3 각인 2슬롯 — 슬롯별 상태(어느 슬롯이든 어떤 스킬이든 낄 수 있게 일반화).
var skill_slots: Array[String] = ["", ""]  # 각 슬롯: skill id 또는 빈칸(미각인)
var slot_cd: Array[float] = [0.0, 0.0]  # 슬롯별 쿨다운
var slot_cast_t: Array[float] = [0.0, 0.0]  # 슬롯별 시전 텔 타이머
var slot_dash_t: Array[float] = [0.0, 0.0]  # 슬롯별 돌진 타이머(서리창)
var input_locked := false  # 각인 패널 등 모달 UI — 이동/전투 입력 차단
var invuln_t := 0.0
var hurt_flash_t := 0.0
var squash := Vector2.ONE
var _juice = null
var _enemies: Array = []
var _was_on_floor := true
# 불 스프라이트 참조(비공개)
var _sprite: AnimatedSprite2D = null
var _use_sprite := false

func _ready() -> void:
	start_pos = position
	_init_sprite()

func _init_sprite() -> void:
	# v3: 스프라이트 = 무속성 플레이어 캐릭터. 원소 게이트 없이 항상 로드 시도,
	# 성공 시 AnimatedSprite2D, 실패 시 그레이박스 폴백(_use_sprite=false).
	_sprite = PlayerSprite.build(self)
	if _sprite == null:
		return
	_sprite.offset = fire_sprite_offset
	_sprite.scale = Vector2(fire_sprite_scale, fire_sprite_scale)
	_use_sprite = true

func set_juice(j) -> void:
	_juice = j

func set_enemies(arr: Array) -> void:
	_enemies = arr

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
	attack_step = 0
	attack_phase = AP_NONE
	combo_index = 0
	combo_reset_t = 0.0
	attack_buffer_t = 0.0
	for i in 2:
		slot_cd[i] = 0.0
		slot_cast_t[i] = 0.0
		slot_dash_t[i] = 0.0
	invuln_t = 0.0
	hurt_flash_t = 0.0
	squash = Vector2.ONE
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
	if input_locked:
		_locked_physics(delta)
		return
	_tick_timers(delta)
	_read_facing()
	_buffer_jump()
	_update_zones()
	_recover_on_contact()
	_try_start_dash()
	_try_place_ice()
	_try_start_flight()
	_try_attack()
	_try_slot(0, &"skill1")
	_try_slot(1, &"skill2")

	var dash_slot := _active_dash_slot()
	if in_water:
		_water_move(delta)
	elif _do_flight(delta):
		pass
	elif _do_wall_run(delta):
		pass
	elif dash_slot >= 0:
		_slot_dash_move(dash_slot, delta)
	elif dash_t > 0.0:
		_dash_move(delta)
	else:
		_normal_move(delta)

	_update_attack(delta)
	_update_skills(delta)
	_update_squash(delta)
	_regen_mana(delta)
	_regen_oxygen(delta)
	var vy_before := velocity.y
	move_and_slide()
	_check_air_bubbles()
	_post_move()
	_land_check(vy_before)
	_was_on_floor = is_on_floor()
	_update_sprite()
	queue_redraw()

func _locked_physics(delta: float) -> void:
	# 각인 패널 등 모달 UI 중 — 입력 무시, 관성 감쇠 + 중력만 적용해 제자리 고정.
	velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	move_and_slide()
	_update_squash(delta)
	state_name = "각인 중"
	_update_sprite()
	queue_redraw()

func _update_sprite() -> void:
	if not _use_sprite or _sprite == null:
		return
	PlayerSprite.drive(_sprite, _sprite_state(), face)

func _sprite_state() -> String:
	# 플레이어 상태 → 불 스프라이트 애니 이름 (우선순위: 피격 > 공격 > 공중 > 지상)
	if hurt_flash_t > 0.0:
		return "hit"
	if attack_step != AP_NONE:
		return "attack2" if attack_step == 2 else "attack1"
	if not is_on_floor():
		return "jump" if velocity.y < 0.0 else "fall"
	if absf(velocity.x) > 10.0:
		return "run"
	return "idle"

func _tick_timers(delta: float) -> void:
	coyote -= delta
	jump_buf -= delta
	dash_cd -= delta
	fly_cd = maxf(0.0, fly_cd - delta)
	hover_cd = maxf(0.0, hover_cd - delta)
	ice_cd = maxf(0.0, ice_cd - delta)
	mana_blink = maxf(0.0, mana_blink - delta)
	for i in 2:
		slot_cd[i] = maxf(0.0, slot_cd[i] - delta)
	invuln_t = maxf(0.0, invuln_t - delta)
	hurt_flash_t = maxf(0.0, hurt_flash_t - delta)
	attack_buffer_t = maxf(0.0, attack_buffer_t - delta)
	if attack_step == AP_NONE:
		combo_reset_t = maxf(0.0, combo_reset_t - delta)
		if combo_reset_t <= 0.0:
			combo_index = 0
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
	# v2.1: 벽 접촉 대시 회복 폐지 — 회복은 착지로만 (spec §2-2, 대시 사다리 봉쇄)

func _flash_mana() -> void:
	# 마나 부족 피드백: HUD 마나 바 깜빡임 (spec §2 공통 원칙)
	mana_blink = MANA_BLINK_TIME

func _try_start_dash() -> void:
	if in_water or flying:
		return
	if not Input.is_action_just_pressed("dash"):
		return
	# 스윙 중(판정 프레임 이전)엔 대시 불가 — 판정 이후만 캔슬 허용(§2)
	if attack_step != AP_NONE and not attack_cancelable:
		return
	if _busy_casting():
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
	# 대시 캔슬 + 주스(먼지·스쿼시·흔들림) — 이동에도 즉시 적용(§6)
	_cancel_attack()
	_trigger_squash(Vector2(1.22, 0.82))
	_shake(0.1)
	Juice.dust_puff(get_parent(), global_position + Vector2(0.0, 17.0), 6)

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
			died.emit()
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
	# 스윙 판정 프레임 이전엔 점프 금지(판정 이후만 캔슬, §2)
	if attack_step != AP_NONE and not attack_cancelable:
		return
	# 지상 점프 (선입력 + 코요테)
	if jump_buf > 0.0 and coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buf = 0.0
		coyote = 0.0
		_cancel_attack()
		_trigger_squash(Vector2(0.82, 1.22))
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
		_cancel_attack()
		_trigger_squash(Vector2(0.82, 1.22))

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
		died.emit()
		respawn()

# ── 주스 래퍼 (juice 미주입 시 안전 no-op) ───────────────────────

func _shake(amount: float) -> void:
	if _juice != null:
		_juice.add_trauma(amount)

func _hitstop(duration: float) -> void:
	if _juice != null:
		_juice.hitstop(duration)

func _trigger_squash(v: Vector2) -> void:
	squash = v

func _update_squash(delta: float) -> void:
	squash = squash.lerp(Vector2.ONE, clampf(delta * squash_recover_speed, 0.0, 1.0))

func _land_check(vy_before: float) -> void:
	# 착지 스쿼시·먼지·흔들림 — 이동 밋밋함 해소(§6)
	if is_on_floor() and not _was_on_floor and vy_before >= land_shake_min_speed:
		_trigger_squash(Vector2(1.25, 0.78))
		_shake(trauma_land)
		Juice.dust_puff(get_parent(), global_position + Vector2(0.0, 17.0), 8)

# ── 기본 공격: 얼음 창 3타 lunge 콤보 (§2) ──────────────────────

func _can_attack() -> bool:
	if in_water or flying or wall_running:
		return false
	if dash_t > 0.0 or _active_dash_slot() >= 0:
		return false
	return not _any_slot_casting()

func _try_attack() -> void:
	if not Input.is_action_just_pressed("attack"):
		return
	if not _can_attack():
		return
	if attack_step == AP_NONE:
		var nxt := 1
		if combo_reset_t > 0.0 and combo_index >= 1 and combo_index < 3:
			nxt = combo_index + 1
		_start_attack_step(nxt)
	else:
		# 진행 중이면 다음 타 버퍼(후딜 중 0.25s, §2)
		attack_buffer_t = combo_buffer_time

func _start_attack_step(step: int) -> void:
	attack_step = step
	attack_phase = AP_STARTUP
	attack_phase_t = _atk_startup(step)
	attack_hit_done = false
	attack_cancelable = false
	attack_buffer_t = 0.0
	attack_face = face
	_trigger_squash(Vector2(0.9, 1.12))

func _update_attack(delta: float) -> void:
	if attack_step == AP_NONE:
		return
	if in_water or flying:
		_cancel_attack()
		return
	attack_phase_t -= delta
	match attack_phase:
		AP_STARTUP:
			if attack_phase_t <= 0.0:
				_enter_active()
		AP_ACTIVE:
			_attack_hit_check()
			if attack_phase_t <= 0.0:
				_enter_recovery()
		AP_RECOVERY:
			attack_cancelable = true
			if attack_phase_t <= 0.0:
				_finish_attack_step()

func _enter_active() -> void:
	attack_phase = AP_ACTIVE
	attack_phase_t = _atk_active(attack_step)
	attack_hit_done = false
	var lunge := atk_lunge_heavy if attack_step == 3 else atk_lunge_light
	velocity.x = float(attack_face) * lunge
	_trigger_squash(Vector2(1.3, 0.85))
	# v3 무속성: 원소 궤적 없이 중립 칼날 스파크(흰/회색)만
	var tip := global_position + Vector2(float(attack_face) * _atk_reach(attack_step) * 0.6, -8.0)
	Juice.hit_spark(get_parent(), tip, 5)

func _enter_recovery() -> void:
	attack_phase = AP_RECOVERY
	attack_phase_t = _atk_recovery(attack_step)
	attack_cancelable = true

func _finish_attack_step() -> void:
	var step := attack_step
	if attack_buffer_t > 0.0:
		attack_buffer_t = 0.0
		var nxt := step + 1
		if nxt > 3:
			nxt = 1
		combo_index = 0 if nxt == 1 else step
		_start_attack_step(nxt)
	else:
		combo_index = step
		attack_step = AP_NONE
		attack_phase = AP_NONE
		combo_reset_t = combo_reset_time

func _cancel_attack() -> void:
	if attack_step == AP_NONE:
		return
	combo_index = attack_step
	combo_reset_t = combo_reset_time
	attack_step = AP_NONE
	attack_phase = AP_NONE
	attack_buffer_t = 0.0

func _attack_hit_check() -> void:
	if attack_hit_done:
		return
	attack_hit_done = true
	var heavy := attack_step == 3
	var reach := _atk_reach(attack_step)
	var hb := _attack_hitbox(reach)
	var dmg := atk_damage_heavy if heavy else atk_damage_light
	var kb := atk_knockback_heavy if heavy else atk_knockback_light
	var up := -120.0 if heavy else -60.0
	var knock := Vector2(float(attack_face) * kb, up)
	var hit_any := false
	for e in _enemies:
		if not is_instance_valid(e) or not e.alive:
			continue
		if _rect_hits(hb, e.global_position, e.hurt_radius):
			e.take_hit(dmg, knock, heavy)
			hit_any = true
	if hit_any:
		# 타격이 마나 수급원(§4): 콤보로 벌어 스킬로 쓴다
		mana = minf(MANA_MAX, mana + (atk_mana_heavy if heavy else atk_mana_light))
		_hitstop(hitstop_heavy if heavy else hitstop_light)
		_shake(trauma_heavy if heavy else trauma_light)
		var fx := global_position + Vector2(float(attack_face) * reach * 0.7, -8.0)
		Juice.hit_spark(get_parent(), fx, 10 if heavy else 6)

func _attack_hitbox(reach: float) -> Rect2:
	# 얇고 긴 창 판정 — 세로 attack_hitbox_height, 가로 reach, 전방으로 뻗음
	var cx := global_position.x + float(attack_face) * (reach * 0.5 + 6.0)
	var cy := global_position.y - 6.0
	return Rect2(
		cx - reach * 0.5, cy - attack_hitbox_height * 0.5, reach, attack_hitbox_height)

func _rect_hits(rect: Rect2, point: Vector2, radius: float) -> bool:
	var nx := clampf(point.x, rect.position.x, rect.position.x + rect.size.x)
	var ny := clampf(point.y, rect.position.y, rect.position.y + rect.size.y)
	return Vector2(nx, ny).distance_to(point) <= radius

func _atk_startup(step: int) -> float:
	return atk1_startup if step == 1 else atk2_startup if step == 2 else atk3_startup

func _atk_active(step: int) -> float:
	return atk1_active if step == 1 else atk2_active if step == 2 else atk3_active

func _atk_recovery(step: int) -> float:
	return atk1_recovery if step == 1 else atk2_recovery if step == 2 else atk3_recovery

func _atk_reach(step: int) -> float:
	return atk1_reach if step == 1 else atk2_reach if step == 2 else atk3_reach

# ── 스킬 2종 (§3): 시전 텔 → 마침표. 쿨+마나, 자동발동 아님 ────────

func _can_cast() -> bool:
	return not in_water and not flying

# v3 슬롯 상태 헬퍼: 어느 슬롯이 돌진/시전 중인지(슬롯 인덱스별 일반화).

func _active_dash_slot() -> int:
	for s in 2:
		if slot_dash_t[s] > 0.0:
			return s
	return -1

func _any_slot_casting() -> bool:
	return slot_cast_t[0] > 0.0 or slot_cast_t[1] > 0.0

func _busy_casting() -> bool:
	# 시전 텔/돌진 진행 중이면 다른 슬롯 발동·대시 금지(캐스트 겹침 방지)
	return _any_slot_casting() or _active_dash_slot() >= 0

func _try_slot(slot: int, action: StringName) -> void:
	# S=슬롯0, D=슬롯1. 낀 스킬 있고·쿨 0·마나 충분이면 텔→효과 캐스트 실행.
	if not Input.is_action_just_pressed(action):
		return
	if not _can_cast():
		return
	var id: String = skill_slots[slot]
	if id == "":
		return  # 미각인 슬롯 — 조용히 무시
	if slot_cd[slot] > 0.0 or _busy_casting() or dash_t > 0.0:
		_shake(0.08)  # 불발(쿨/시전 중) 피드백
		return
	var cost := _skill_mana(id)
	if mana < cost:
		_flash_mana()
		_shake(0.08)
		return
	mana -= cost
	slot_cd[slot] = _skill_cooldown(id)
	attack_face = face
	_cancel_attack()
	slot_cast_t[slot] = _skill_cast_tell(id)
	_cast_rune(id)

func _cast_rune(id: String) -> void:
	# 시전 텔 룬 — 속성별 색(불=주황, 물=하늘색)
	var rp := global_position + Vector2(float(face) * 10.0, -8.0)
	var col := Color(1.0, 0.6, 0.2)
	if SkillDB.element_of(id) != "불":
		col = Color(0.65, 0.9, 1.0)
	Juice.rune_flash(get_parent(), rp, 34.0, 0.2, col)

func _skill_cooldown(id: String) -> float:
	# @export 실수치 라우팅(F5 손 튜닝 유지) — id → cooldown
	match id:
		"flame_pillar":
			return fire_skill1_cooldown
		"meteor":
			return fire_skill2_cooldown
		"frost_spear":
			return skill1_cooldown
		"ice_burst":
			return skill2_cooldown
	return 0.0

func _skill_mana(id: String) -> float:
	match id:
		"flame_pillar":
			return fire_skill1_mana
		"meteor":
			return fire_skill2_mana
		"frost_spear":
			return skill1_mana
		"ice_burst":
			return skill2_mana
	return 0.0

func _skill_cast_tell(id: String) -> float:
	match id:
		"flame_pillar":
			return fire_skill1_cast_tell
		"meteor":
			return fire_skill2_cast_tell
		"frost_spear":
			return skill1_cast_tell
		"ice_burst":
			return skill2_cast_tell
	return 0.0

func _update_skills(delta: float) -> void:
	# 슬롯별 시전 텔 진행 → 만료 시 낀 스킬 발동(슬롯 인덱스와 무관하게 id로 라우팅)
	for s in 2:
		if slot_cast_t[s] > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)  # 영창 루팅
			slot_cast_t[s] -= delta
			if slot_cast_t[s] <= 0.0:
				slot_cast_t[s] = 0.0
				_cast_skill(skill_slots[s], s)

func _cast_skill(id: String, slot: int) -> void:
	match id:
		"flame_pillar":
			_fire_skill1_fire()
		"meteor":
			_fire_skill2_fire()
		"frost_spear":
			_frost_spear_fire(slot)
		"ice_burst":
			_ice_skill2_fire()

func _nearest_enemy(max_dist: float) -> Node:
	# 살아있는 적 중 가장 가까운 것(조준 대체). 범위 밖이면 null.
	var best: Node = null
	var best_d := max_dist
	for e in _enemies:
		if not is_instance_valid(e) or not e.alive:
			continue
		var d := global_position.distance_to(e.global_position)
		if d <= best_d:
			best_d = d
			best = e
	return best

func _fire_skill1_fire() -> void:
	# 발밑 화염: 가장 가까운(또는 전방) 적의 발밑 지면에서 화염 기둥이 솟아 판정.
	var tgt := _nearest_enemy(fire_skill1_range)
	var fx := global_position.x + float(attack_face) * 120.0
	var fy := global_position.y
	if tgt != null:
		fx = tgt.global_position.x
		fy = tgt.global_position.y
	# 화염 기둥 판정: 지면(fx,fy)에서 위로 솟는 세로 rect
	var col := Rect2(
		fx - fire_skill1_width * 0.5, fy - fire_skill1_height,
		fire_skill1_width, fire_skill1_height + 20.0)
	for e in _enemies:
		if not is_instance_valid(e) or not e.alive:
			continue
		if _rect_hits(col, e.global_position, e.hurt_radius):
			var kdir := signf(e.global_position.x - fx)
			if kdir == 0.0:
				kdir = float(attack_face)
			e.take_hit(fire_skill1_damage, Vector2(kdir * fire_skill1_knockback, -180.0), true)
	_hitstop(hitstop_heavy)
	_shake(trauma_heavy)
	Juice.ground_flame(get_parent(), Vector2(fx, fy), fire_skill1_height)

func _frost_spear_fire(slot: int) -> void:
	# 관통 서리창: 전방 돌진 + 긴 얼음창 직선 관통 + 빙결 슬로우(끼운 슬롯의 돌진)
	slot_dash_t[slot] = skill1_dash_time
	invuln_t = maxf(invuln_t, skill1_dash_time + 0.05)  # 약한 밀림 저항(§3)
	var hb := _attack_hitbox(skill1_reach)
	var knock := Vector2(float(attack_face) * 180.0, -80.0)
	for e in _enemies:
		if not is_instance_valid(e) or not e.alive:
			continue
		if _rect_hits(hb, e.global_position, e.hurt_radius):
			e.take_hit(skill1_damage, knock, true)
			if e.has_method("apply_slow"):
				e.apply_slow(skill1_slow_factor, skill1_slow_time)
	_hitstop(hitstop_heavy)
	_shake(trauma_heavy)
	var fx := global_position + Vector2(float(attack_face) * skill1_reach * 0.6, -8.0)
	Juice.frost_burst(get_parent(), fx, 16, Color(0.72, 0.92, 1.0))

func _slot_dash_move(slot: int, delta: float) -> void:
	slot_dash_t[slot] -= delta
	velocity = Vector2(float(attack_face) * (skill1_dash_dist / skill1_dash_time), 0.0)
	state_name = "관통 서리창"

func _fire_skill2_fire() -> void:
	# 메테오: 가장 가까운(또는 전방) 적 지점을 조준해 화면 위에서 메테오 낙하.
	var tgt := _nearest_enemy(fire_skill2_range)
	var to := global_position + Vector2(float(attack_face) * 180.0, 0.0)
	if tgt != null:
		to = tgt.global_position
	var from := Vector2(to.x - 60.0, to.y - 520.0)
	Juice.meteor(get_parent(), from, to, fire_skill2_fall_time)
	# 착탄(폭발·피해)은 낙하 연출과 동기화 — fall_time 뒤 고정 지점에 AoE
	get_tree().create_timer(fire_skill2_fall_time).timeout.connect(
		_fire_skill2_impact.bind(to))

func _fire_skill2_impact(at: Vector2) -> void:
	for e in _enemies:
		if not is_instance_valid(e) or not e.alive:
			continue
		if at.distance_to(e.global_position) <= fire_skill2_radius + e.hurt_radius:
			var kdir := signf(e.global_position.x - at.x)
			if kdir == 0.0:
				kdir = float(face)
			e.take_hit(fire_skill2_damage, Vector2(kdir * fire_skill2_knockback, -220.0), true)
			if e.has_method("apply_stun"):
				e.apply_stun(fire_skill2_stun)
	_hitstop(hitstop_heavy)
	_shake(trauma_heavy)
	Juice.meteor_impact(get_parent(), at, fire_skill2_radius)

func _ice_skill2_fire() -> void:
	# 빙정 폭발: 반경 90px 냉기 폭발 + 넉백 + 짧은 빙결 스턴
	for e in _enemies:
		if not is_instance_valid(e) or not e.alive:
			continue
		var d := global_position.distance_to(e.global_position)
		if d <= skill2_radius + e.hurt_radius:
			var dir := signf(e.global_position.x - global_position.x)
			if dir == 0.0:
				dir = float(face)
			e.take_hit(skill2_damage, Vector2(dir * skill2_knockback, -160.0), true)
			if e.has_method("apply_stun"):
				e.apply_stun(skill2_stun_time)
	_hitstop(hitstop_heavy)
	_shake(trauma_heavy)
	Juice.frost_ring(get_parent(), global_position, skill2_radius)
	var rp := global_position + Vector2(0.0, 16.0)
	Juice.rune_flash(get_parent(), rp, skill2_radius, 0.28, Color(0.6, 0.85, 1.0))

# ── 피격/체력 (§4) ──────────────────────────────────────────────

func take_damage(amount: int, from_pos: Vector2) -> void:
	if invuln_t > 0.0:
		return
	health -= amount
	invuln_t = invuln_time
	hurt_flash_t = 0.25
	var dir := signf(global_position.x - from_pos.x)
	if dir == 0.0:
		dir = -float(face)
	velocity.x = dir * damage_knockback
	velocity.y = minf(velocity.y, -160.0)
	_cancel_attack()
	_shake(trauma_heavy)
	Juice.frost_burst(get_parent(), global_position, 6, Color(1.0, 0.6, 0.6))
	if health <= 0:
		died.emit()
		respawn()

func _draw() -> void:
	# 불 스프라이트 사용 시 그레이박스/창 비주얼 생략(애니 스프라이트가 몸을 그림)
	if _use_sprite:
		return
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
	elif dash_t > 0.0 or _active_dash_slot() >= 0:
		body_color = Color(0.6, 0.9, 1.0)
	if invuln_t > 0.0 and int(invuln_t * 16.0) % 2 == 0:
		body_color = body_color.lerp(Color(1.0, 0.4, 0.4), 0.6)  # 피격 무적 깜빡임
	# 스쿼시/스트레치 적용(충돌 도형 불변, 비주얼만, §6)
	var hw := 10.0 * squash.x
	var hh := 17.0 * squash.y
	draw_rect(Rect2(-hw, -hh, hw * 2.0, hh * 2.0), body_color)
	# 매개체(마도구/촉매) — 손 위치에 상시 발광 오브(마법 출처, §0.2)
	var hand := Vector2(8.0 * float(face), -8.0)
	draw_circle(hand, 6.0, Color(0.85, 0.87, 0.95, 0.18))
	draw_circle(hand, 3.0, Color(0.9, 0.92, 0.97, 0.92))
	# v3 무속성 마력 칼날 — 폴백 그레이박스용 중립 발광 칼날(원소색 없음)
	var slen := _current_spear_len()
	if slen > 0.0:
		_draw_blade(hand, slen)

func _current_spear_len() -> float:
	# 시전/돌진 중엔 긴 스킬 칼날, 기본 공격은 판정 페이즈에 리치만큼
	if _active_dash_slot() >= 0 or _any_slot_casting():
		return skill1_reach
	if attack_step != AP_NONE and attack_phase == AP_STARTUP:
		return _atk_reach(attack_step) * 0.45
	if attack_step != AP_NONE and attack_phase == AP_ACTIVE:
		return _atk_reach(attack_step)
	return 0.0

func _draw_blade(base: Vector2, length: float) -> void:
	# 스러스트 스트레치 반영(가로 늘림) + 3겹 글로우로 발광하는 중립 칼날
	var f := float(face)
	var tip := base + Vector2(f * length * squash.x, 0.0)
	var w := attack_hitbox_height * 0.5
	_spear_layer(base, tip, w * 1.7, Color(0.82, 0.84, 0.92, 0.16))
	_spear_layer(base, tip, w, Color(0.88, 0.9, 0.96, 0.4))
	_spear_layer(base, tip, w * 0.5, Color(0.96, 0.97, 1.0, 0.88))
	draw_circle(tip, 3.0, Color(0.97, 0.98, 1.0, 0.9))

func _spear_layer(base: Vector2, tip: Vector2, w: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(0.0, -w), base + Vector2(0.0, w), tip]), col)
