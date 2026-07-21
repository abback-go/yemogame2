class_name Juice
extends Node
## 공용 주스/필 레이어 (combat-spec §6) — 전투·이동 공용 프리미티브.
## 인스턴스: 히트스톱 · 화면 흔들림(trauma) · 카메라 룩어헤드.
## 정적 헬퍼: 도형 파티클(서리 파편·먼지·냉기 폭발) · 마법진 룬 flash.
## 4.7 조립 규칙대로 노드는 코드 생성, 카메라·타깃은 메서드 주입.

# 글로벌 튜닝(코드 생성 노드라 씬 스크립트의 @export로 configure 주입)
var shake_max_offset := 12.0
var trauma_decay := 1.8
var lookahead_dist := 40.0
var lookahead_speed := 5.0
var hitstop_scale := 0.0

var camera: Camera2D = null
var target: CharacterBody2D = null
var lookahead_enabled := false
var _trauma := 0.0
var _look := Vector2.ZERO
var _hitstop_token := 0

func configure(
	shake_max: float, decay: float,
	look_dist: float, look_spd: float, hs_scale: float) -> void:
	shake_max_offset = shake_max
	trauma_decay = decay
	lookahead_dist = look_dist
	lookahead_speed = look_spd
	hitstop_scale = hs_scale

func bind_camera(cam: Camera2D) -> void:
	camera = cam

func bind_target(t: CharacterBody2D) -> void:
	target = t
	lookahead_enabled = true

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func hitstop(duration: float) -> void:
	# 짧은 게임 정지 + unscaled 타이머 복귀 (상시 로직 영구 정지 금지, §6)
	if duration <= 0.0:
		return
	# 씬 전환 찰나 등 트리 밖이면 get_tree()==null — 시간축을 건드리기 전에 중단
	# (null.create_timer 크래시 + time_scale 0 잔류 동시 방지)
	var st := get_tree()
	if st == null:
		return
	_hitstop_token += 1
	var tok := _hitstop_token
	Engine.time_scale = hitstop_scale
	var timer := st.create_timer(duration, true, false, true)
	timer.timeout.connect(_end_hitstop.bind(tok))

func _end_hitstop(tok: int) -> void:
	if tok == _hitstop_token:
		Engine.time_scale = 1.0

func _exit_tree() -> void:
	# 씬 전환 등으로 주스가 사라져도 시간축은 반드시 복구(히트스톱 잔류 방지)
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if camera == null:
		return
	# 룩어헤드: 진행 방향으로 최대 lookahead_dist 리드 (lerp)
	if lookahead_enabled and target != null:
		var vx: float = target.velocity.x
		var want := clampf(vx / 320.0, -1.0, 1.0) * lookahead_dist
		_look.x = lerpf(_look.x, want, clampf(delta * lookahead_speed, 0.0, 1.0))
	# trauma 모델: shake = trauma^2, 랜덤 오프셋, 감쇠
	_trauma = maxf(0.0, _trauma - trauma_decay * delta)
	var shake := _trauma * _trauma
	var off := Vector2.ZERO
	if shake > 0.0:
		off = Vector2(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_max_offset * shake
	camera.offset = _look + off

# ── 정적 파티클/룬 헬퍼 (인스턴스 불필요) ─────────────────────────

static func _spawn_particles(parent: Node, pos: Vector2, amount: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = maxi(1, amount)
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.45
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	return p

static func frost_burst(
	parent: Node, pos: Vector2,
	amount := 8, color := Color(0.72, 0.9, 1.0)) -> void:
	# 창 타격·피격 서리 파편 (하늘색/흰색 도형 파티클)
	var p := _spawn_particles(parent, pos, amount)
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 190.0
	p.gravity = Vector2(0.0, 340.0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = color
	p.emitting = true

static func frost_trail(parent: Node, pos: Vector2, face: int) -> void:
	# 찌를 때 창 끝 서리 궤적 (전방 편향)
	var p := _spawn_particles(parent, pos, 7)
	p.direction = Vector2(float(face), -0.2)
	p.spread = 45.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 210.0
	p.gravity = Vector2(0.0, 120.0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(0.8, 0.95, 1.0)
	p.emitting = true

static func frost_ring(parent: Node, pos: Vector2, radius: float) -> void:
	# 냉기 폭발(빙정 폭발) — 전방위 방사
	var p := _spawn_particles(parent, pos, 26)
	p.lifetime = 0.5
	p.direction = Vector2(1.0, 0.0)
	p.spread = 180.0
	p.initial_velocity_min = radius * 2.0
	p.initial_velocity_max = radius * 4.0
	p.gravity = Vector2(0.0, 60.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(0.75, 0.92, 1.0)
	p.emitting = true

static func hit_spark(parent: Node, pos: Vector2, amount := 6) -> void:
	# v3 무속성 마력 칼날 타격 — 흰/회색 히트스파크(원소 입자 없음)
	var p := _spawn_particles(parent, pos, amount)
	p.lifetime = 0.3
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 200.0
	p.gravity = Vector2(0.0, 200.0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(0.92, 0.93, 0.97)
	p.emitting = true

static func dust_puff(parent: Node, pos: Vector2, amount := 6) -> void:
	# 대시/착지 먼지 (회갈색 도형 파티클)
	var p := _spawn_particles(parent, pos, amount)
	p.lifetime = 0.35
	p.direction = Vector2(0.0, -1.0)
	p.spread = 90.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 120.0
	p.gravity = Vector2(0.0, 260.0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(0.62, 0.58, 0.52)
	p.emitting = true

# ── 불 전공 파티클 헬퍼 (서리 헬퍼 미러, 불 팔레트 주황/빨강) ─────────

static func flame_burst(
	parent: Node, pos: Vector2,
	amount := 8, color := Color(1.0, 0.55, 0.15)) -> void:
	# 불의 검 타격 불똥 — 불꽃은 위로 솟구침(음의 중력)
	var p := _spawn_particles(parent, pos, amount)
	p.direction = Vector2(0.0, -1.0)
	p.spread = 150.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 210.0
	p.gravity = Vector2(0.0, -120.0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = color
	p.emitting = true

static func flame_trail(parent: Node, pos: Vector2, face: int) -> void:
	# 불의 검 궤적 — 전방 편향 불꽃
	var p := _spawn_particles(parent, pos, 8)
	p.direction = Vector2(float(face), -0.3)
	p.spread = 40.0
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 230.0
	p.gravity = Vector2(0.0, -80.0)
	p.scale_amount_min = 1.6
	p.scale_amount_max = 3.2
	p.color = Color(1.0, 0.7, 0.25)
	p.emitting = true

static func ground_flame(parent: Node, pos: Vector2, height: float) -> void:
	# 스킬1 발밑 화염 기둥 — 지면(pos)에서 위로 솟구치는 불기둥 + 코어 폴리곤
	var p := _spawn_particles(parent, pos, 34)
	p.lifetime = 0.55
	p.direction = Vector2(0.0, -1.0)
	p.spread = 22.0
	p.initial_velocity_min = height * 2.0
	p.initial_velocity_max = height * 3.4
	p.gravity = Vector2(0.0, -160.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(1.0, 0.55, 0.12)
	p.emitting = true
	var core := Polygon2D.new()
	var hw := 9.0
	core.polygon = PackedVector2Array([
		Vector2(-hw, 0.0), Vector2(hw, 0.0),
		Vector2(hw * 0.5, -height), Vector2(-hw * 0.5, -height)])
	core.color = Color(1.0, 0.8, 0.3, 0.6)
	core.position = pos
	parent.add_child(core)
	var tw := core.create_tween()
	tw.tween_property(core, "modulate:a", 0.0, 0.4).from(1.0)
	tw.tween_callback(core.queue_free)

static func meteor(
	parent: Node, from: Vector2, to: Vector2, fall_time: float) -> void:
	# 스킬2 메테오 낙하 — 화면 위 from 에서 착탄점 to 로 하강(불덩이 + 꼬리 궤적)
	var n := Node2D.new()
	n.position = from
	var glow := Polygon2D.new()
	glow.polygon = _circle_poly(22.0, 12)
	glow.color = Color(1.0, 0.4, 0.1, 0.35)
	n.add_child(glow)
	var head := Polygon2D.new()
	head.polygon = _circle_poly(14.0, 12)
	head.color = Color(1.0, 0.6, 0.2)
	n.add_child(head)
	var trail := CPUParticles2D.new()
	trail.amount = 22
	trail.lifetime = 0.4
	trail.direction = (from - to).normalized()
	trail.spread = 18.0
	trail.initial_velocity_min = 40.0
	trail.initial_velocity_max = 120.0
	trail.gravity = Vector2.ZERO
	trail.scale_amount_min = 2.0
	trail.scale_amount_max = 4.0
	trail.color = Color(1.0, 0.55, 0.15)
	trail.emitting = true
	n.add_child(trail)
	parent.add_child(n)
	var tw := n.create_tween()
	tw.tween_property(n, "position", to, fall_time).from(from)
	tw.tween_callback(n.queue_free)

static func meteor_impact(parent: Node, pos: Vector2, radius: float) -> void:
	# 스킬2 착탄 폭발 — 전방위 불꽃 방사 + 충격 링
	var p := _spawn_particles(parent, pos, 30)
	p.lifetime = 0.5
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.initial_velocity_min = radius * 2.0
	p.initial_velocity_max = radius * 4.0
	p.gravity = Vector2(0.0, 220.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color(1.0, 0.5, 0.12)
	p.emitting = true
	var ring := _ring_line(radius * 0.6, Color(1.0, 0.7, 0.25), 24)
	ring.position = pos
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector2(1.8, 1.8), 0.3).from(Vector2(0.5, 0.5))
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.3).from(1.0)
	tw.tween_callback(ring.queue_free)

static func _circle_poly(radius: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts

static func rune_flash(
	parent: Node, pos: Vector2, radius: float,
	duration: float, color: Color) -> void:
	# 스킬 시전 텔 — 마법진/룬 순간 표시("영창하는 마법" 언어, §0.2)
	var n := Node2D.new()
	n.position = pos
	n.add_child(_ring_line(radius, color, 20))
	n.add_child(_rune_line(radius * 0.72, color))
	parent.add_child(n)
	var tw := n.create_tween()
	tw.tween_property(n, "modulate:a", 0.0, duration).from(1.0)
	tw.parallel().tween_property(
		n, "scale", Vector2(1.3, 1.3), duration).from(Vector2(0.55, 0.55))
	tw.tween_callback(n.queue_free)

static func _ring_line(radius: float, color: Color, seg: int) -> Line2D:
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = color
	var pts := PackedVector2Array()
	for i in seg + 1:
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	line.points = pts
	return line

static func _rune_line(radius: float, color: Color) -> Line2D:
	# 내부 삼각 룬 모티프
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(color.r, color.g, color.b, color.a * 0.8)
	var pts := PackedVector2Array()
	for i in 4:
		var a := TAU * float(i) / 3.0 - PI * 0.5
		pts.append(Vector2(cos(a), sin(a)) * radius)
	line.points = pts
	return line
