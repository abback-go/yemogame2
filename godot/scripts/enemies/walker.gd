extends EnemyBase
## 근접 워커 (combat-spec §5) — 플레이어로 느리게 이동(60px/s), HP3.
## 접촉 시 짧은 찌르기 1 마스크. 공격 전 0.5s 정지+예비 모션(읽히는 텔).
## 리듬·창 리치·거리 조절 검증용.

@export var chase_speed := 60.0
@export var telegraph_time := 0.5
@export var attack_range := 40.0
@export var attack_active := 0.18
@export var attack_cooldown := 0.7
@export var attack_damage := 1

var _phase := "chase"
var _phase_t := 0.0

func _configure() -> void:
	max_hp = 3
	body_size = Vector2(28.0, 40.0)
	body_color = Color(0.72, 0.44, 0.4)

func _on_respawn() -> void:
	_phase = "chase"
	_phase_t = 0.0

func _ai(delta: float) -> void:
	if target == null:
		return
	var dx: float = target.global_position.x - global_position.x
	var dy: float = target.global_position.y - global_position.y
	var sd := delta * slow_factor  # 빙결 시 행동 속도까지 둔화
	match _phase:
		"chase":
			if absf(dx) <= attack_range and absf(dy) < 44.0:
				_phase = "windup"
				_phase_t = telegraph_time
				velocity.x = 0.0
			else:
				velocity.x = signf(dx) * chase_speed * slow_factor
		"windup":
			velocity.x = 0.0
			_phase_t -= sd
			if _phase_t <= 0.0:
				_phase = "strike"
				_phase_t = attack_active
		"strike":
			velocity.x = signf(dx) * chase_speed * 0.5
			_phase_t -= sd
			if _phase_t <= 0.0:
				_phase = "cooldown"
				_phase_t = attack_cooldown
		"cooldown":
			velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
			_phase_t -= sd
			if _phase_t <= 0.0:
				_phase = "chase"

func _post_ai(_delta: float) -> void:
	if _phase != "strike" or target == null:
		return
	if not target.has_method("take_damage"):
		return
	if global_position.distance_to(target.global_position) <= attack_range + 8.0:
		target.take_damage(attack_damage, global_position)

func _draw_telegraph() -> void:
	var top := -body_size.y * 0.5 - 10.0
	if _phase == "windup":
		# 예비: 빨간 경고 마름모 깜빡임
		var blink := 0.4 + 0.6 * absf(sin(_phase_t * 20.0))
		var c := Color(1.0, 0.35, 0.3, blink)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, top - 6.0), Vector2(6.0, top),
			Vector2(0.0, top + 6.0), Vector2(-6.0, top)]), c)
	elif _phase == "strike":
		# 찌르기: 바라보는 쪽 빨간 창선
		var f := signf(target.global_position.x - global_position.x) if target else 1.0
		draw_line(
			Vector2.ZERO, Vector2(f * (attack_range + 8.0), 0.0),
			Color(1.0, 0.4, 0.35), 4.0)
