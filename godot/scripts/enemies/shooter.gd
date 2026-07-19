extends EnemyBase
## 원거리 사수 (combat-spec §5) — 저속 부유(거리 유지), HP2. 느린 투사체
## 180px/s, 2s 주기, 발사 전 0.6s 조준 모션(읽히는 텔). 부유(시그니처)·
## 대시 회피 검증용.

const BoltScript := preload("res://scripts/enemies/enemy_bolt.gd")

@export var move_speed := 40.0
@export var desired_dist := 260.0
@export var fire_interval := 2.0
@export var aim_time := 0.6
@export var bolt_speed := 180.0
@export var bolt_damage := 1
@export var hover_amp := 6.0

var _fire_t := 2.0
var _aim_t := 0.0
var _aiming := false
var _bob := 0.0

func _configure() -> void:
	max_hp = 2
	use_gravity = false
	collision_mask = 0  # 부유형 — 발판에 걸리지 않게 물리 충돌 없음
	body_size = Vector2(28.0, 34.0)
	body_color = Color(0.5, 0.5, 0.78)

func _on_respawn() -> void:
	_fire_t = fire_interval
	_aim_t = 0.0
	_aiming = false

func _ai(delta: float) -> void:
	if target == null:
		return
	_bob += delta
	var dx: float = target.global_position.x - global_position.x
	var vx := 0.0
	if absf(dx) < desired_dist - 40.0:
		vx = -signf(dx) * move_speed
	elif absf(dx) > desired_dist + 40.0:
		vx = signf(dx) * move_speed
	velocity.x = vx * slow_factor
	# 제높이 유지 + 미세 부유(시그니처)
	var ty := home_pos.y + sin(_bob * 3.0) * hover_amp
	velocity.y = (ty - global_position.y) * 4.0
	var sd := delta * slow_factor
	if _aiming:
		velocity.x *= 0.3
		_aim_t -= sd
		if _aim_t <= 0.0:
			_fire_bolt()
			_aiming = false
			_fire_t = fire_interval
	else:
		_fire_t -= sd
		if _fire_t <= 0.0:
			_aiming = true
			_aim_t = aim_time

func _fire_bolt() -> void:
	if target == null:
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var bolt := BoltScript.new()
	bolt.position = global_position + dir * 20.0
	get_parent().add_child(bolt)
	bolt.setup(dir, bolt_speed, target, bolt_damage)

func _draw_telegraph() -> void:
	if not _aiming or target == null:
		return
	# 조준선: 플레이어 방향으로 강도 상승(빨강)
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var t := 1.0 - clampf(_aim_t / aim_time, 0.0, 1.0)
	var col := Color(1.0, 0.45, 0.3, 0.35 + 0.5 * t)
	draw_line(Vector2.ZERO, dir * (120.0 + 120.0 * t), col, 2.0)
	draw_circle(dir * 22.0, 5.0 + 3.0 * t, Color(1.0, 0.5, 0.3, 0.7))
