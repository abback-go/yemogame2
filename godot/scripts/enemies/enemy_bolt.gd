class_name EnemyBolt
extends Node2D
## 사수의 적대 투사체 (combat-spec §5) — 느린 직선 이동, 플레이어 근접 시
## 접촉 데미지. 아군 냉기(하늘색)와 구분되게 따뜻한 색(주황) 마법탄.

var velocity := Vector2.ZERO
var target: Node2D = null
var life := 6.0
var radius := 8.0
var damage := 1

func setup(dir: Vector2, speed: float, tgt: Node2D, dmg: int) -> void:
	velocity = dir.normalized() * speed
	target = tgt
	damage = dmg
	queue_redraw()

func _process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if target != null and is_instance_valid(target):
		if position.distance_to(target.global_position) <= radius + 14.0:
			if target.has_method("take_damage"):
				target.take_damage(damage, position)
			queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 4.0, Color(1.0, 0.5, 0.2, 0.25))
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.6, 0.3, 0.9))
	draw_circle(Vector2.ZERO, radius * 0.5, Color(1.0, 0.92, 0.75, 1.0))
