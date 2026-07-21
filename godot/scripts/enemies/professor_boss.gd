extends EnemyBase
## 튜토리얼 오프닝의 부동(不動) 보스 — 누나 교수 (P1 담당).
## 산나비식 '지는 보스전': 플레이어는 이길 수 없다. 위치 완전 고정,
## 명확한 텔레그래프 3패턴(견제탄→바닥룬→견제탄→반격장막 결정론 순환).
## hp 게이지가 30% 이하로 떨어지는 첫 순간 gauge_broken 을 쏘고 무적화한다.
## 이후 대마법 연출(P2)은 씬 드라이버가 지휘하며, 보스는 begin_finisher() 호출을
## 받아 "0.5s 후 한 발 전진(stepped) → 0.7s 후 finisher_done" 만 수행한다.
## 무작위·Time·Date 금지 — 모든 타이머는 자체 누적 변수(delta)로만 진행.

signal gauge_broken  # 게이지(hp)가 30% 이하로 처음 떨어진 순간 1회 emit
signal stepped  # begin_finisher 중 "한 발" 내딛는 순간 emit(드라이버가 화면흔들림)
signal finisher_done  # 마무리 연출 종료 시 emit(드라이버가 플레이어 다운·대사 진행)

const BoltScript := preload("res://scripts/enemies/enemy_bolt.gd")

const PHASE_IDLE := 0  # 패턴 사이 대기
const PHASE_AIM := 1  # 견제탄 조준 텔레그래프
const PHASE_SHIELD := 2  # 반격 장막 활성
const PHASE_BROKEN := 3  # 게이지 파괴 후 무적·정지(begin_finisher 대기)
const PHASE_FINISHER := 4  # 드라이버 지휘 마무리 시퀀스

const PATTERN_BOLT := 0
const PATTERN_RUNE := 1
const PATTERN_SHIELD := 2
# 결정론 순환: 견제탄→바닥룬→견제탄→반격장막
const PATTERN_CYCLE := [PATTERN_BOLT, PATTERN_RUNE, PATTERN_BOLT, PATTERN_SHIELD]

@export var idle_time := 0.6  # 패턴 사이 대기(텔레그래프 준비)
@export var aim_time := 0.5  # 견제탄 조준 텔레그래프 길이
@export var bolt_speed := 170.0  # 견제탄 속도
@export var bolt_damage := 1
@export var rune_warn_time := 0.8  # 바닥 룬 경고 표시 시간
@export var rune_radius := 60.0  # 룬 폭발 반경(피해·시각 공통)
@export var rune_damage := 1
@export var shield_time := 1.2  # 반격 장막 지속
@export var repel_speed := 300.0  # 장막 반격 시 플레이어 밀어내는 속도
@export var gauge_ratio := 0.3  # hp <= max_hp*이 값 이면 게이지 파괴
@export var finisher_step := 44.0  # begin_finisher 한 발 전진 거리
@export var finisher_step_delay := 0.5  # begin_finisher 후 전진까지
@export var finisher_end_delay := 0.7  # 전진 후 finisher_done 까지

var _phase := PHASE_IDLE
var _phase_t := 0.0
var _pattern_idx := 0
var _anim_t := 0.0  # 시각 펄스용 자체 누적 타이머(Time 대체)
var _face := 1.0  # 바라보는 방향(-1/1)
var _broken := false  # 게이지 파괴=무적
var _shielding := false  # 반격 장막 활성 중
var _fin_t := 0.0  # 피니셔 페이즈 누적 타이머
var _fin_stepped := false
var _fin_done := false
var _runes: Array = []  # [{"pos": Vector2, "t": float}] — 보스 내부 관리(노드 없음)


func _configure() -> void:
	max_hp = 20  # EnemyBase._draw_hp 표시 임계(≤20) — 게이지가 보여야 '몰아붙이는 감각'이 산다
	body_size = Vector2(30.0, 52.0)  # 우아하게 큼
	body_color = Color(0.85, 0.82, 0.95)  # 밝은 귀족 톤(어두운 배경에서 또렷)
	use_gravity = true
	collision_mask = 1
	auto_respawn = false
	material_drop = 0
	hitreact_time = 0.05  # 넉백 거의 안 먹게(보스 위엄)
	_reset_runtime()


func _on_respawn() -> void:
	# 결투 재시작 대비 — 전 상태 초기화(드라이버 reset_enemy 호출 시)
	_reset_runtime()


func _reset_runtime() -> void:
	_phase = PHASE_IDLE
	_phase_t = idle_time
	_pattern_idx = 0
	_anim_t = 0.0
	_face = 1.0
	_broken = false
	_shielding = false
	_fin_t = 0.0
	_fin_stepped = false
	_fin_done = false
	_runes.clear()


# ── 드라이버 공개 API ─────────────────────────────────────────────
func begin_finisher() -> void:
	_phase = PHASE_FINISHER
	_fin_t = 0.0
	_fin_stepped = false
	_fin_done = false
	velocity = Vector2.ZERO


# ── AI ────────────────────────────────────────────────────────────
func _ai(delta: float) -> void:
	velocity.x = 0.0  # 완전 부동 — 이동 로직 없음
	_anim_t += delta
	if _phase == PHASE_FINISHER:
		_tick_finisher(delta)
		return
	if _phase == PHASE_BROKEN:
		return  # 무적·정지, begin_finisher 대기
	if target == null:
		return
	_tick_runes(delta)  # 바닥 룬은 부동 보스와 무관한 지면 위험 — 원시 delta
	var sd := delta * slow_factor
	match _phase:
		PHASE_IDLE:
			_tick_idle(sd)
		PHASE_AIM:
			_tick_aim(sd)
		PHASE_SHIELD:
			_tick_shield(sd)


func _tick_idle(sd: float) -> void:
	_phase_t -= sd
	if _phase_t <= 0.0:
		_start_pattern()


func _start_pattern() -> void:
	var kind: int = PATTERN_CYCLE[_pattern_idx]
	if kind == PATTERN_BOLT:
		_phase = PHASE_AIM
		_phase_t = aim_time
	elif kind == PATTERN_RUNE:
		_cast_rune()  # 즉시 발동(0.8s 경고 자체가 텔레그래프)
		_advance_pattern()
	else:
		_phase = PHASE_SHIELD
		_phase_t = shield_time
		_shielding = true


func _tick_aim(sd: float) -> void:
	_face_player()
	_phase_t -= sd
	if _phase_t <= 0.0:
		_fire_bolt()
		_advance_pattern()


func _tick_shield(sd: float) -> void:
	_phase_t -= sd
	if _phase_t <= 0.0:
		_shielding = false
		_advance_pattern()


func _advance_pattern() -> void:
	_pattern_idx = (_pattern_idx + 1) % PATTERN_CYCLE.size()
	_phase = PHASE_IDLE
	_phase_t = idle_time


func _face_player() -> void:
	if target == null:
		return
	var dx := target.global_position.x - global_position.x
	if absf(dx) > 1.0:
		_face = signf(dx)


func _fire_bolt() -> void:
	if target == null:
		return
	var dir := (target.global_position - global_position).normalized()
	var bolt := BoltScript.new()
	bolt.position = global_position + dir * 22.0
	get_parent().add_child(bolt)
	bolt.setup(dir, bolt_speed, target, bolt_damage)


func _cast_rune() -> void:
	# 플레이어 현재 위치를 기억 → 그 지점에 경고 룬 등록
	if target == null:
		return
	_runes.append({"pos": target.global_position, "t": rune_warn_time})


func _tick_runes(delta: float) -> void:
	for i in range(_runes.size() - 1, -1, -1):
		_runes[i]["t"] -= delta
		if _runes[i]["t"] <= 0.0:
			_resolve_rune(_runes[i]["pos"])
			_runes.remove_at(i)


func _resolve_rune(pos: Vector2) -> void:
	# 만료 시 반경 안에 플레이어 있으면 피해
	if target == null or not target.has_method("take_damage"):
		return
	if target.global_position.distance_to(pos) <= rune_radius:
		target.take_damage(rune_damage, pos)


func _tick_finisher(delta: float) -> void:
	_fin_t += delta
	if not _fin_stepped and _fin_t >= finisher_step_delay:
		_do_finisher_step()
	if not _fin_done and _fin_t >= finisher_step_delay + finisher_end_delay:
		_fin_done = true
		finisher_done.emit()


func _do_finisher_step() -> void:
	_fin_stepped = true
	var dir := _face
	if target != null:
		var dx := target.global_position.x - global_position.x
		if absf(dx) > 1.0:
			dir = signf(dx)
	position.x += dir * finisher_step  # 부동 보스라 discrete 한 발 전진
	stepped.emit()


# ── 피격: 무적/장막 우선 처리, 게이지 파괴 판정 ───────────────────
func take_hit(dmg: int, knock: Vector2, heavy: bool, element := "무") -> void:
	if not alive:
		return
	if _broken:
		return  # 게이지 파괴 후 완전 무적(장막 처리보다 먼저)
	if _shielding:
		_repel_player()  # 반격 장막 — 데미지 무시 + 밀어내기 + 스파크
		return
	super.take_hit(dmg, knock, heavy, element)
	velocity.x = 0.0  # 부동 유지(넉백 무효)
	if hp <= int(round(float(max_hp) * gauge_ratio)):
		_trigger_break()


func _repel_player() -> void:
	Juice.frost_burst(get_parent(), global_position, 6)
	if target == null:
		return
	var push := signf(target.global_position.x - global_position.x)
	if push == 0.0:
		push = _face
	if target is CharacterBody2D:
		target.velocity.x = push * repel_speed


func _trigger_break() -> void:
	_broken = true
	_phase = PHASE_BROKEN
	_shielding = false
	_runes.clear()
	hp = maxi(hp, 1)  # 이길 수 없는 보스 — 절대 죽지 않음
	alive = true
	visible = true
	hitreact_t = 0.0
	stun_t = 0.0
	velocity = Vector2.ZERO
	gauge_broken.emit()


# ── 텔레그래프 그리기(로컬 좌표계 — 보스 부동이라 to_local 안전) ──
func _draw_telegraph() -> void:
	_draw_runes()
	match _phase:
		PHASE_AIM:
			_draw_aim()
		PHASE_SHIELD:
			_draw_shield()
		PHASE_FINISHER:
			_draw_finisher()


func _draw_aim() -> void:
	# 조준 중 플레이어 방향으로 뻗는 경고 적색선(강도 상승)
	if target == null:
		return
	var dir := (target.global_position - global_position).normalized()
	var t := 1.0 - clampf(_phase_t / aim_time, 0.0, 1.0)
	var col := Color(1.0, 0.35, 0.3, 0.35 + 0.5 * t)
	var reach := 140.0 + 200.0 * t
	draw_line(Vector2.ZERO, dir * reach, col, 2.0 + 2.0 * t)
	draw_circle(dir * 26.0, 5.0 + 3.0 * t, Color(1.0, 0.5, 0.35, 0.75))


func _draw_runes() -> void:
	# 바닥 룬 경고 원(적색) — 내부 원이 수축하며 임팩트 임박 표시
	for r in _runes:
		var lp: Vector2 = to_local(r["pos"])
		var frac := 1.0 - clampf(r["t"] / rune_warn_time, 0.0, 1.0)
		var fill := Color(0.9, 0.2, 0.2, 0.12 + 0.18 * frac)
		var edge := Color(1.0, 0.3, 0.25, 0.25 + 0.45 * frac)
		draw_circle(lp, rune_radius, fill)
		draw_arc(lp, rune_radius, 0.0, TAU, 48, edge, 2.0 + 2.0 * frac)
		draw_arc(lp, rune_radius * (1.0 - frac), 0.0, TAU, 40, edge, 2.0)


func _draw_shield() -> void:
	# 반격 장막 링(흰·보라 계열, 맥동)
	var pulse := 0.5 + 0.5 * sin(_anim_t * 6.0)
	var r := body_size.x * 0.9 + 8.0
	var fill := Color(0.85, 0.8, 1.0, 0.12 + 0.12 * pulse)
	var ring := Color(0.95, 0.9, 1.0, 0.5 + 0.4 * pulse)
	var outer := Color(0.7, 0.6, 1.0, 0.3 + 0.3 * pulse)
	draw_circle(Vector2.ZERO, r, fill)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, ring, 3.0)
	draw_arc(Vector2.ZERO, r + 6.0, 0.0, TAU, 48, outer, 2.0)


func _draw_finisher() -> void:
	# 전방 거대 발광 폴리곤(백열) — 화면 플래시는 드라이버 몫
	var span := finisher_step_delay + finisher_end_delay
	var grow := clampf(_fin_t / span, 0.0, 1.0)
	var shimmer := 0.75 + 0.25 * sin(_anim_t * 18.0)
	var reach := 60.0 + 260.0 * grow
	var half := 30.0 + 70.0 * grow
	var bx := _face * body_size.x * 0.5
	var col := Color(1.0, 0.98, 0.85, (0.3 + 0.55 * grow) * shimmer)
	var pts := PackedVector2Array(
		[
			Vector2(bx, -half * 0.5),
			Vector2(bx + _face * reach, -half),
			Vector2(bx + _face * (reach + 40.0), 0.0),
			Vector2(bx + _face * reach, half),
			Vector2(bx, half * 0.5),
		]
	)
	draw_colored_polygon(pts, col)
	var core := Color(1.0, 1.0, 0.95, 0.6 * shimmer)
	draw_circle(Vector2(bx, 0.0), 14.0 + 24.0 * grow, core)
