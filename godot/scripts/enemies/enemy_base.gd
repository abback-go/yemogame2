class_name EnemyBase
extends CharacterBody2D
## 더미 적 공통 베이스 (combat-spec §5). 체력·빙결 슬로우·스턴·피격 반응·
## 넉백·서리 파편·리스폰을 담당하고, AI는 서브클래스의 _ai()가 채운다.
## 4.7 조립: 충돌 도형·레이어 전부 코드 생성. 플레이어와 물리 충돌하지
## 않도록 레이어 분리(적=4, 플레이어=2, 발판=1).

@export var enemy_gravity := 1500.0
@export var fall_max := 900.0
@export var hurt_radius := 18.0
@export var body_size := Vector2(28.0, 38.0)
@export var use_gravity := true
@export var hitreact_time := 0.12
@export var knockback_friction := 900.0
@export var respawn_delay := 2.5

var hp := 3
var max_hp := 3
var slow_factor := 1.0
var slow_t := 0.0
var stun_t := 0.0
var flash_t := 0.0
var hitreact_t := 0.0
var squash := Vector2.ONE
var alive := true
var body_color := Color(0.6, 0.6, 0.7)
var target: Node2D = null
var home_pos := Vector2.ZERO

func _ready() -> void:
	home_pos = global_position
	collision_layer = 4
	collision_mask = 1
	_configure()
	_build_shape()
	hp = max_hp

func _configure() -> void:
	pass  # 서브클래스: max_hp·body_size·body_color·use_gravity 설정

func _build_shape() -> void:
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = body_size
	shape.shape = rs
	add_child(shape)

func set_target(t: Node2D) -> void:
	target = t

func reset_enemy() -> void:
	# 아레나 R 리스폰 — 전체 상태 초기화
	_respawn()

func apply_slow(factor: float, t: float) -> void:
	# 빙결 슬로우 — 이동·행동 속도 배율 (스킬1)
	slow_factor = factor
	slow_t = maxf(slow_t, t)

func apply_stun(t: float) -> void:
	# 짧은 빙결 스턴 (스킬2) — AI 정지
	stun_t = maxf(stun_t, t)
	velocity.x = 0.0

func take_hit(dmg: int, knock: Vector2, heavy: bool) -> void:
	if not alive:
		return
	hp -= dmg
	flash_t = 0.12
	hitreact_t = hitreact_time * (1.6 if heavy else 1.0)
	squash = Vector2(1.35, 0.7)
	velocity.x = knock.x
	if use_gravity:
		velocity.y = minf(velocity.y, knock.y)
	Juice.frost_burst(get_parent(), global_position, 8 if heavy else 5)
	if hp <= 0:
		_die()

func _die() -> void:
	alive = false
	visible = false
	stun_t = 0.0
	slow_t = 0.0
	Juice.frost_burst(get_parent(), global_position, 16, Color(0.85, 0.96, 1.0))
	get_tree().create_timer(respawn_delay).timeout.connect(_respawn)

func _respawn() -> void:
	global_position = home_pos
	velocity = Vector2.ZERO
	hp = max_hp
	alive = true
	visible = true
	slow_factor = 1.0
	slow_t = 0.0
	stun_t = 0.0
	hitreact_t = 0.0
	squash = Vector2.ONE
	_on_respawn()

func _on_respawn() -> void:
	pass  # 서브클래스: 상태머신 리셋 훅

func _physics_process(delta: float) -> void:
	if not alive:
		return
	_tick_enemy(delta)
	if hitreact_t > 0.0 or stun_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
	else:
		_ai(delta)
	if use_gravity:
		velocity.y = minf(velocity.y + enemy_gravity * delta, fall_max)
	move_and_slide()
	_post_ai(delta)
	queue_redraw()

func _tick_enemy(delta: float) -> void:
	flash_t = maxf(0.0, flash_t - delta)
	hitreact_t = maxf(0.0, hitreact_t - delta)
	stun_t = maxf(0.0, stun_t - delta)
	if slow_t > 0.0:
		slow_t = maxf(0.0, slow_t - delta)
		if slow_t <= 0.0:
			slow_factor = 1.0
	squash = squash.lerp(Vector2.ONE, clampf(delta * 12.0, 0.0, 1.0))

func _ai(_delta: float) -> void:
	pass  # 서브클래스 구현

func _post_ai(_delta: float) -> void:
	pass  # 서브클래스: 접촉 데미지 등

func _draw() -> void:
	var hw := body_size.x * 0.5 * squash.x
	var hh := body_size.y * 0.5 * squash.y
	draw_rect(Rect2(-hw, -hh, hw * 2.0, hh * 2.0), body_color)
	if flash_t > 0.0:
		var a := clampf(flash_t / 0.12, 0.0, 1.0)
		draw_rect(Rect2(-hw, -hh, hw * 2.0, hh * 2.0), Color(1.0, 1.0, 1.0, a * 0.8))
	if slow_factor < 1.0:
		# 빙결 슬로우 시각 표시(하늘색 서리 테두리)
		draw_rect(Rect2(-hw, -hh, hw * 2.0, hh * 2.0), Color(0.6, 0.85, 1.0, 0.35), false, 3.0)
	_draw_telegraph()
	_draw_hp(hh)

func _draw_telegraph() -> void:
	pass  # 서브클래스: 예비동작 표시

func _draw_hp(hh: float) -> void:
	if max_hp > 20:
		return  # 허수아비(무한 HP)는 표시 생략
	var y := -hh - 12.0
	for i in max_hp:
		var col := Color(0.9, 0.4, 0.4) if i < hp else Color(0.3, 0.3, 0.35)
		draw_rect(Rect2(-float(max_hp) * 5.0 + float(i) * 10.0, y, 8.0, 5.0), col)
