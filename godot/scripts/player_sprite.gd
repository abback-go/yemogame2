class_name PlayerSprite
extends RefCounted
## 불 전공 애니메이션 스프라이트 로더/구동 헬퍼 (player.gd 비대·gdlint 방지 분리).
## res://assets/sprites/fire/ 의 `<이름>_<N>.png` 를 가로 N등분 슬라이스해
## SpriteFrames 를 구성하고 AnimatedSprite2D(코드 생성)를 player 자식으로 붙인다.
## 폴더/파일/슬라이스 실패 시 build()가 null → player.gd 가 그레이박스로 폴백.
## 4.7 조립 규칙: 노드는 전부 코드 생성, $경로 조회 없음.

const FIRE_DIR := "res://assets/sprites/fire/"

# 애니 이름 → FPS (공격 빠르게 / idle 느리게). 파일명 접두사와 1:1.
const ANIM_FPS := {
	"idle": 8.0,
	"run": 14.0,
	"jump": 12.0,
	"fall": 12.0,
	"attack1": 24.0,
	"attack2": 24.0,
	"hit": 16.0,
	"death": 10.0,
}
const LOOP_ANIMS := ["idle", "run", "jump", "fall"]


static func build(parent: Node2D) -> AnimatedSprite2D:
	# 성공 시 AnimatedSprite2D 반환(parent 에 이미 add_child 됨), 실패 시 null.
	var dir := DirAccess.open(FIRE_DIR)
	if dir == null:
		push_warning("[진단] 불 스프라이트 폴더 없음 — 그레이박스 폴백")
		return null
	var files := dir.get_files()
	if files.is_empty():
		push_warning("[진단] 불 스프라이트 파일 없음 — 그레이박스 폴백")
		return null
	var frames := SpriteFrames.new()
	var built := 0
	for anim in ANIM_FPS.keys():
		var fname := _find_file(files, anim)
		if fname == "":
			continue
		var count := _parse_count(fname)
		if count <= 0:
			continue
		var tex := load(FIRE_DIR + fname) as Texture2D
		if tex == null:
			continue
		_register_anim(frames, anim, tex, count)
		built += 1
	if built == 0:
		push_warning("[진단] 불 스프라이트 슬라이스 실패 — 그레이박스 폴백")
		return null
	var spr := AnimatedSprite2D.new()
	spr.name = "FireSprite"
	spr.sprite_frames = frames
	if frames.has_animation("idle"):
		spr.animation = "idle"
		spr.play("idle")
	parent.add_child(spr)
	return spr


static func drive(spr: AnimatedSprite2D, state: String, face: int) -> void:
	# 상태 문자열로 애니 전환(같은 애니면 재시작 안 함) + face 로 좌우 뒤집기.
	if spr == null or spr.sprite_frames == null:
		return
	spr.flip_h = face < 0
	if not spr.sprite_frames.has_animation(state):
		return
	if spr.animation != state:
		spr.play(state)


static func _find_file(files: PackedStringArray, anim: String) -> String:
	var prefix := anim + "_"
	for f in files:
		if f.begins_with(prefix) and f.ends_with(".png"):
			return f
	return ""


static func _parse_count(fname: String) -> int:
	# `<이름>_<N>.png` 끝의 N 파싱 (마지막 _ 뒤 정수).
	var base := fname.get_basename()
	var idx := base.rfind("_")
	if idx < 0:
		return 0
	var num := base.substr(idx + 1)
	if not num.is_valid_int():
		return 0
	return num.to_int()


static func _register_anim(
		frames: SpriteFrames, anim: String, tex: Texture2D, count: int) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, ANIM_FPS[anim])
	frames.set_animation_loop(anim, anim in LOOP_ANIMS)
	var fw := tex.get_width() / count
	var h := tex.get_height()
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(float(i * fw), 0.0, float(fw), float(h))
		frames.add_frame(anim, atlas)
