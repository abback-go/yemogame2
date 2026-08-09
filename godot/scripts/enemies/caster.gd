extends EnemyBase
## 중형 부유 캐스터 보스 (combat-spec §5) — 잡몹 아님·리스폰 없음(auto_respawn
## false). 원거리 다중 패턴: 3연 스프레드(0.7s 조준 텔레그래프) + 순간이동
## 리포지션(blink). HP 높아 여러 번 때려야 잡힘. 접촉 데미지 없음(투사체만).
## 무작위 금지 — 발사 카운터로 패턴 교대, 시간은 자체 누적 _t 사용.

const BoltScript := preload("res://scripts/enemies/enemy_bolt.gd")

const STATE_MOVE := 0  # 거리 유지 이동, 다음 행동까지 대기
const STATE_AIM := 1  # 조준 텔레그래프 후 3연 스프레드 발사
const STATE_BLINK := 2  # 점멸 텔레그래프 후 순간이동

@export var move_speed := 46.0
@export var desired_dist := 300.0
@export var dist_margin := 40.0
@export var fire_interval := 1.4  # MOVE 상태 대기(다음 행동까지)
@export var aim_time := 0.7  # 조준 텔레그래프 길이
@export var blink_time := 0.4  # 순간이동 예비 점멸 길이
@export var bolt_speed := 200.0
@export var bolt_damage := 1
@export var spread_deg := 18.0  # 부채꼴 좌우 편차 각도
@export var hover_amp := 6.0
@export var bob_rate := 2.6
@export var height_gain := 4.0  # home_pos.y 복귀 강도
@export var aim_hold := 0.25  # 조준·점멸 중 수평 이동 감쇠
@export var blink_after := 3  # 이만큼 발사하면 다음엔 순간이동

var _state := 0
var _fire_t := 1.4
var _aim_t := 0.0
var _blink_t := 0.0
var _shots_since_blink := 0
var _t := 0.0


func _configure() -> void:
	max_hp = 11
	use_gravity = false
	collision_mask = 0  # 부유형 — 발판에 걸리지 않게 물리 충돌 없음
	body_size = Vector2(34.0, 42.0)
	body_color = Color(0.55, 0.4, 0.75)  # 보랏빛 술사
	auto_respawn = false
	material_drop = 12
	weak_element = "불"
	resist_element = "물"


func _on_respawn() -> void:
	_state = STATE_MOVE
	_fire_t = fire_interval
	_aim_t = 0.0
	_blink_t = 0.0
	_shots_since_blink = 0
	_t = 0.0


func _ai(delta: float) -> void:
	if target == null:
		return
	_t += delta
	var sd := delta * slow_factor
	_reposition()
	if _state == STATE_AIM:
		_tick_aim(sd)
	elif _state == STATE_BLINK:
		_tick_blink(sd)
	else:
		_tick_move(sd)


func _post_ai(_delta: float) -> void:
	pass  # 캐스터는 접촉 데미지 없음 — 데미지는 투사체(EnemyBolt)만


func _reposition() -> void:
	# 플레이어와 desired_dist 유지(수평) + home_pos.y 근처 유지(부드럽게, 미세 bob)
	var dx: float = target.global_position.x - global_position.x
	var vx := 0.0
	if absf(dx) < desired_dist - dist_margin:
		vx = -signf(dx) * move_speed
	elif absf(dx) > desired_dist + dist_margin:
		vx = signf(dx) * move_speed
	velocity.x = vx * slow_factor
	var ty := home_pos.y + sin(_t * bob_rate) * hover_amp
	velocity.y = (ty - global_position.y) * height_gain


func _tick_move(sd: float) -> void:
	_fire_t -= sd
	if _fire_t <= 0.0:
		if _shots_since_blink >= blink_after:
			_enter_blink()
		else:
			_enter_aim()


func _tick_aim(sd: float) -> void:
	velocity.x *= aim_hold
	_aim_t -= sd
	if _aim_t <= 0.0:
		_fire_spread()
		_shots_since_blink += 1
		_enter_move()


func _tick_blink(sd: float) -> void:
	velocity.x *= aim_hold
	_blink_t -= sd
	if _blink_t <= 0.0:
		_do_blink()
		_shots_since_blink = 0
		_enter_aim()  # 순간이동 직후 다시 조준


func _enter_move() -> void:
	_state = STATE_MOVE
	_fire_t = fire_interval


func _enter_aim() -> void:
	_state = STATE_AIM
	_aim_t = aim_time


func _enter_blink() -> void:
	_state = STATE_BLINK
	_blink_t = blink_time


func _fire_spread() -> void:
	# 플레이어 방향 기준 부채꼴 3발(중앙·±spread_deg)
	if target == null:
		return
	var base: Vector2 = (target.global_position - global_position).normalized()
	for a in [-spread_deg, 0.0, spread_deg]:
		var dir := base.rotated(deg_to_rad(a))
		var bolt := BoltScript.new()
		bolt.position = global_position + dir * 22.0
		get_parent().add_child(bolt)
		bolt.setup(dir, bolt_speed, target, bolt_damage)


func _do_blink() -> void:
	# 플레이어 반대쪽으로 순간이동(고정 규칙 — 무작위 금지). 클램프 없이 단순 offset.
	if target == null:
		return
	var side := signf(global_position.x - target.global_position.x)
	if side == 0.0:
		side = 1.0
	var nx := target.global_position.x - side * desired_dist
	global_position = Vector2(nx, home_pos.y)


func _draw_telegraph() -> void:
	if target == null:
		return
	if _state == STATE_AIM:
		_draw_aim()
	elif _state == STATE_BLINK:
		_draw_blink()


func _draw_aim() -> void:
	# 조준 중 부채꼴 3방향 빨간 조준선(강도 상승)
	var base: Vector2 = (target.global_position - global_position).normalized()
	var t := 1.0 - clampf(_aim_t / aim_time, 0.0, 1.0)
	var col := Color(1.0, 0.4, 0.3, 0.3 + 0.55 * t)
	var reach := 120.0 + 160.0 * t
	for a in [-spread_deg, 0.0, spread_deg]:
		var dir := base.rotated(deg_to_rad(a))
		draw_line(Vector2.ZERO, dir * reach, col, 2.0)
	draw_circle(base * 24.0, 5.0 + 3.0 * t, Color(1.0, 0.5, 0.3, 0.7))


func _draw_blink() -> void:
	# 순간이동 예비 — 몸통 주변 반투명 원이 점멸(사라짐 느낌)
	var pulse := 0.5 + 0.5 * sin(_t * 30.0)
	var hw := body_size.x * 0.9
	draw_circle(Vector2.ZERO, hw, Color(0.7, 0.5, 0.9, 0.15 + 0.4 * pulse))
