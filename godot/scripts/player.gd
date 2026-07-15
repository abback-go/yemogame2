extends CharacterBody2D
## 파이프라인 실험용 플레이어 — 수치는 HTML 프로토타입 v0.2에서 이식.
## 시작 킷 중 달리기 / 점프(코요테·선입력·컷) / 지상 질풍보만 구현.

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

var coyote := 0.0
var jump_buf := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var face := 1
var start_pos := Vector2.ZERO

func _ready() -> void:
	start_pos = position

func _physics_process(delta: float) -> void:
	coyote -= delta
	jump_buf -= delta
	dash_cd -= delta

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		face = 1 if dir > 0.0 else -1

	if Input.is_action_just_pressed("jump"):
		jump_buf = JUMP_BUFFER

	if dash_t > 0.0:
		# 질풍보 중: 수평 고정, 중력 무시 (프로토타입과 동일)
		dash_t -= delta
		velocity.x = face * DASH_SPEED
		velocity.y = 0.0
	else:
		if dir != 0.0:
			velocity.x = move_toward(velocity.x, dir * RUN_SPEED, ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, DECEL * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
		if Input.is_action_just_released("jump") and velocity.y < JUMP_CUT:
			velocity.y = JUMP_CUT

	if is_on_floor():
		coyote = COYOTE_TIME

	if jump_buf > 0.0 and coyote > 0.0 and dash_t <= 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buf = 0.0
		coyote = 0.0

	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and is_on_floor():
		dash_t = DASH_TIME
		dash_cd = DASH_COOLDOWN

	move_and_slide()

	# 실험용 안전장치: 방 밖으로 떨어지면 시작점으로
	if position.y > 1300.0:
		position = start_pos
		velocity = Vector2.ZERO

	queue_redraw()

func _draw() -> void:
	# 임시 비주얼 (HTML 프로토타입과 같은 콘셉트): 몸통 + 지팡이
	var body_color := Color(0.93, 0.91, 0.86)
	if dash_t > 0.0:
		body_color = Color(0.6, 0.9, 1.0)
	draw_rect(Rect2(-10.0, -17.0, 20.0, 34.0), body_color)
	var tip := Vector2(15.0 * face, -14.0)
	draw_line(Vector2(6.0 * face, 4.0), tip, Color(0.83, 0.62, 0.25), 3.0)
	draw_circle(tip, 3.0, Color(0.4, 0.75, 1.0))
