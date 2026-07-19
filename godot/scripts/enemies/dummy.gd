extends EnemyBase
## 허수아비 (combat-spec §5) — 정지·사실상 무한 HP. 순수 타격감/콤보/
## 히트스톱 확인용. 예비동작·공격 없음, 피격 반응(넉백·플래시·서리)만.

func _configure() -> void:
	max_hp = 999999
	body_size = Vector2(30.0, 46.0)
	body_color = Color(0.52, 0.57, 0.66)

func _ai(delta: float) -> void:
	# 제자리 정지(넉백만 감쇠, 나머지는 베이스가 처리)
	velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

func _draw_telegraph() -> void:
	# 허수아비 표식: 정수리 하늘색 점(마법 타격 표적)
	draw_circle(Vector2(0.0, -body_size.y * 0.5 - 6.0), 3.0, Color(0.6, 0.85, 1.0, 0.8))
