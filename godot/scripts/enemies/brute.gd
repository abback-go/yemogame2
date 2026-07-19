extends EnemyBase
## 중형 근접 보스 "브루트" (combat-spec §5 확장) — HP16, 리스폰 없음(auto_respawn=false).
## 두 가지 텔레그래프 공격으로 탐욕을 응징하되 공정하게: 돌진(charge)과
## 내려찍기(slam)를 공격 카운터 짝/홀로 번갈아 사용(무작위 없음 — Date/random 불가 환경).
## 느리고 무겁게 이동하며, 빙결 시 slow_factor 로 이동·페이즈 타이머까지 둔화한다.
## 상태머신: chase → charge_windup/slam_windup → charge/slam → recover → chase.

@export var chase_speed := 70.0  # 느리고 무거운 추격 속도
@export var align_tolerance := 80.0  # 이 수직 오차 이내여야 공격 개시
@export var attack_range := 210.0  # 돌진 결심 사거리(수평)
@export var slam_range := 96.0  # 이 이내면 내려찍기 선택 가능(근접)

@export var charge_windup_time := 0.6  # 돌진 예비동작(정지)
@export var charge_time := 0.35  # 돌진 지속
@export var charge_speed := 360.0  # 돌진 속도
@export var charge_damage := 2
@export var charge_hit_range := 46.0  # 돌진 접촉 판정 거리(중심간)

@export var slam_windup_time := 0.5  # 내려찍기 예비동작(정지)
@export var slam_active := 0.25  # 착지 충격 활성 시간
@export var slam_radius := 90.0  # 내려찍기 반경(접촉·시각 공통)
@export var slam_damage := 3

@export var recover_time := 0.6  # 공격 후 경직

var _phase := "chase"
var _phase_t := 0.0
var _attack_count := 0  # 짝/홀로 패턴 교대(무작위 대체)
var _face := 1.0  # 바라보는·돌진 방향(-1/1)
var _hit_applied := false  # 공격 1회당 1히트(공정성)


func _configure() -> void:
	max_hp = 16
	body_size = Vector2(46.0, 60.0)
	body_color = Color(0.75, 0.35, 0.3)
	use_gravity = true
	auto_respawn = false
	material_drop = 15
	weak_element = "물"
	resist_element = "불"


func _on_respawn() -> void:
	_phase = "chase"
	_phase_t = 0.0
	_attack_count = 0
	_face = 1.0
	_hit_applied = false


func _ai(delta: float) -> void:
	if target == null:
		return
	var dx: float = target.global_position.x - global_position.x
	var dy: float = target.global_position.y - global_position.y
	var sd := delta * slow_factor  # 빙결 시 페이즈 진행까지 둔화
	match _phase:
		"chase":
			_ai_chase(dx, dy)
		"charge_windup":
			velocity.x = 0.0
			if absf(dx) > 1.0:
				_face = signf(dx)
			_phase_t -= sd
			if _phase_t <= 0.0:
				_begin_charge()
		"charge":
			velocity.x = _face * charge_speed * slow_factor
			_phase_t -= sd
			if _phase_t <= 0.0:
				_begin_recover()
		"slam_windup":
			velocity.x = 0.0
			_phase_t -= sd
			if _phase_t <= 0.0:
				_begin_slam()
		"slam":
			velocity.x = 0.0
			_phase_t -= sd
			if _phase_t <= 0.0:
				_begin_recover()
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
			_phase_t -= sd
			if _phase_t <= 0.0:
				_phase = "chase"


func _ai_chase(dx: float, dy: float) -> void:
	if absf(dx) <= attack_range and absf(dy) < align_tolerance:
		_choose_attack(dx)
		return
	velocity.x = signf(dx) * chase_speed * slow_factor


func _choose_attack(dx: float) -> void:
	if absf(dx) > 1.0:
		_face = signf(dx)
	var want_slam := _attack_count % 2 == 1
	var close := absf(dx) <= slam_range
	_attack_count += 1
	velocity.x = 0.0
	if want_slam and close:
		_phase = "slam_windup"
		_phase_t = slam_windup_time
	else:
		_phase = "charge_windup"
		_phase_t = charge_windup_time


func _begin_charge() -> void:
	_phase = "charge"
	_phase_t = charge_time
	_hit_applied = false


func _begin_slam() -> void:
	_phase = "slam"
	_phase_t = slam_active
	_hit_applied = false


func _begin_recover() -> void:
	_phase = "recover"
	_phase_t = recover_time


func _post_ai(_delta: float) -> void:
	if target == null:
		return
	if not target.has_method("take_damage"):
		return
	if _hit_applied:
		return
	var d := global_position.distance_to(target.global_position)
	if _phase == "charge":
		if d <= charge_hit_range:
			target.take_damage(charge_damage, global_position)
			_hit_applied = true
	elif _phase == "slam":
		if d <= slam_radius:
			target.take_damage(slam_damage, global_position)
			_hit_applied = true


func _draw_telegraph() -> void:
	match _phase:
		"charge_windup":
			_draw_charge_windup()
		"charge":
			_draw_charge_active()
		"slam_windup":
			_draw_slam_windup()
		"slam":
			_draw_slam_active()


func _draw_charge_windup() -> void:
	# 전방으로 커지는 빨간 화살표(돌진 경고, 깜빡임)
	var reach := charge_speed * charge_time
	var progress := 1.0 - clampf(_phase_t / charge_windup_time, 0.0, 1.0)
	var blink := 0.4 + 0.6 * absf(sin(_phase_t * 18.0))
	var col := Color(1.0, 0.32, 0.26, blink)
	var base_x := _face * body_size.x * 0.5
	var tip := _face * reach * (0.4 + 0.6 * progress)
	draw_line(Vector2(base_x, 0.0), Vector2(tip, 0.0), col, 4.0 + 4.0 * progress)
	var ah := 10.0 + 6.0 * progress
	draw_colored_polygon(
		PackedVector2Array(
			[Vector2(tip + _face * ah, 0.0), Vector2(tip, -ah), Vector2(tip, ah)]
		),
		col
	)


func _draw_charge_active() -> void:
	# 돌진 중 전방 빨간 창선(활성)
	var reach := charge_speed * charge_time
	var base_x := _face * body_size.x * 0.5
	var tip := _face * (body_size.x * 0.5 + reach * 0.35)
	draw_line(Vector2(base_x, 0.0), Vector2(tip, 0.0), Color(1.0, 0.45, 0.35, 0.9), 6.0)


func _draw_slam_windup() -> void:
	# 위로 커지는 빨간 원 + 위 화살표(내려찍기 경고)
	var progress := 1.0 - clampf(_phase_t / slam_windup_time, 0.0, 1.0)
	var blink := 0.5 + 0.5 * absf(sin(_phase_t * 16.0))
	var col := Color(1.0, 0.3, 0.25, blink)
	var r := slam_radius * (0.25 + 0.75 * progress)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, col, 3.0 + 3.0 * progress)
	var top := -body_size.y * 0.5 - 6.0
	var ah := 8.0 + 8.0 * progress
	draw_colored_polygon(
		PackedVector2Array(
			[Vector2(0.0, top - ah), Vector2(-ah * 0.7, top), Vector2(ah * 0.7, top)]
		),
		col
	)


func _draw_slam_active() -> void:
	# 착지 충격파(반경까지 퍼지는 빨간 링)
	var progress := 1.0 - clampf(_phase_t / slam_active, 0.0, 1.0)
	var r := slam_radius * (0.6 + 0.4 * progress)
	var a := 0.7 * (1.0 - progress)
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.35, 0.28, a * 0.4))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1.0, 0.5, 0.35, a + 0.2), 5.0)
