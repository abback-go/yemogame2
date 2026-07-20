class_name WorldData
extends RefCounted
## 연속 월드 방 청사진 — world_room.gd 가 GameState.world_room 으로 방 하나를 조립한다.
## 1단계(느낌/재미 확인): 허브 2방(정문마당·본관홀) + 전투 5방(입구·사수·브루트·캐스터·제단).
## 전 방 free_move(이동기 9종 ON), 평지 그레이박스, **방당 적 1마리**(입구서 멀리 → 동시 교전 없음).
## 방 전환=씬 재로드. 오브 학습 오프닝은 검증된 slice 방 재사용으로 2단계에 연결 예정.
## 좌표계: 방 원점(0,0) 좌상단. 표준 방 1600×720, 바닥 top y=620.

const ROOM_ORDER := [
	"hub_plaza", "hub_hall",
	"cw_entry", "cw_shooter", "cw_brute", "cw_caster", "cw_altar",
]
const ROOM_NAMES := {
	"hub_plaza": "정문 마당",
	"hub_hall": "본관 홀",
	"cw_entry": "훈련 구역 · 입구",
	"cw_shooter": "사수 회랑",
	"cw_brute": "브루트의 투기장",
	"cw_caster": "캐스터의 성소",
	"cw_altar": "정수 제단",
}


func _init() -> void:
	pass  # class_name 등록용 (전부 static 접근)


static func room_count() -> int:
	return ROOM_ORDER.size()


static func has_room(id: String) -> bool:
	return ROOM_ORDER.has(id)


static func room_name(id: String) -> String:
	return String(ROOM_NAMES.get(id, id))


static func get_room(id: String) -> Dictionary:
	match id:
		"hub_plaza":
			return _hub_plaza()
		"hub_hall":
			return _hub_hall()
		"cw_entry":
			return _cw_entry()
		"cw_shooter":
			return _cw_shooter()
		"cw_brute":
			return _cw_brute()
		"cw_caster":
			return _cw_caster()
		"cw_altar":
			return _cw_altar()
	push_warning("[진단] 없는 월드 방 id: %s — 정문 마당 대체" % id)
	return _hub_plaza()


# ── 조립 헬퍼 (dict 축약) ─────────────────────────────────────────

static func _floor() -> Rect2:
	return Rect2(20, 620, 1560, 100)


static func _entries_lr() -> Dictionary:
	# 표준 좌우 입장문 위치(바닥 위). bench 등 추가는 방에서 병합.
	return {
		"start": Vector2(120, 560),
		"from_left": Vector2(90, 560),
		"from_right": Vector2(1500, 560),
	}


static func _exit(rect: Rect2, to: String, entry: String, arrow: String) -> Dictionary:
	return {"rect": rect, "to": to, "entry": entry, "arrow": arrow}


static func _exit_left(to: String) -> Dictionary:
	return _exit(Rect2(20, 500, 44, 120), to, "from_right", "left")


static func _exit_right(to: String) -> Dictionary:
	return _exit(Rect2(1536, 500, 44, 120), to, "from_left", "right")


static func _sign(pos: Vector2, text: String) -> Dictionary:
	return {"pos": pos, "text": text}


static func _enemy(kind: String, pos: Vector2) -> Dictionary:
	return {"type": kind, "pos": pos}


static func _ess(element: String, pos: Vector2) -> Dictionary:
	return {"element": element, "pos": pos}


static func _prof(pos: Vector2) -> Dictionary:
	return {
		"pos": pos, "label": "교수\n(F 수업)",
		"color": Color(0.7, 0.55, 1.0), "kind": "professor",
	}


static func _blk(rect: Rect2, name_kr: String, arrow: String) -> Dictionary:
	return {"rect": rect, "name": name_kr, "arrow": arrow}


# ── 허브 ──────────────────────────────────────────────────────────

static func _hub_plaza() -> Dictionary:
	return {
		"name": "정문 마당",
		"size": Vector2(1600, 720),
		"free_move": true,
		"entries": {"start": Vector2(120, 560), "from_right": Vector2(1500, 560)},
		"solids": [_floor()],
		"plats": [],
		"essences": [_ess("불", Vector2(520, 560))],
		"signs": [
			_sign(Vector2(110, 350), "이름 없는 마법학교 — 정문 마당\n오른쪽: 본관 홀 (수업·거점)"),
			_sign(Vector2(440, 470), "불의 정수 — 밟아 획득\n1키로 무속성 칼날에 속성 부여"),
		],
		"blocked": [_blk(Rect2(20, 500, 44, 120), "정문(교외)", "left")],
		"exits": [_exit_right("hub_hall")],
	}


static func _hub_hall() -> Dictionary:
	var e := _entries_lr()
	e["bench"] = Vector2(760, 560)
	return {
		"name": "본관 홀",
		"size": Vector2(1600, 720),
		"free_move": true,
		"entries": e,
		"solids": [_floor()],
		"plats": [],
		"npcs": [_prof(Vector2(400, 580))],
		"bench": Vector2(760, 612),
		"signs": [
			_sign(Vector2(110, 340), "본관 홀\n교수(F): 스킬 배우기·강화\n거점(F): 회복·세이브·각인"),
			_sign(Vector2(1040, 470), "오른쪽 뒷문 → 훈련 구역(전투)\n중형 적 주의 — 정수·상성 활용"),
		],
		"exits": [_exit_left("hub_plaza"), _exit_right("cw_entry")],
	}


# ── 전투 구역 (방당 적 1마리, 입구서 멀리) ────────────────────────

static func _cw_entry() -> Dictionary:
	return {
		"name": "훈련 구역 · 입구",
		"size": Vector2(1600, 720),
		"free_move": true,
		"entries": _entries_lr(),
		"solids": [_floor()],
		"plats": [],
		"enemies": [_enemy("walker", Vector2(920, 580))],
		"essences": [_ess("물", Vector2(360, 560))],
		"signs": [
			_sign(Vector2(110, 350), "훈련 구역 — 방마다 적 1마리\n물의 정수: 밟아 획득 (1키 전환)"),
		],
		"exits": [_exit_left("hub_hall"), _exit_right("cw_shooter")],
	}


static func _cw_shooter() -> Dictionary:
	return {
		"name": "사수 회랑",
		"size": Vector2(1600, 720),
		"free_move": true,
		"entries": _entries_lr(),
		"solids": [_floor()],
		"plats": [Rect2(520, 480, 180, 20), Rect2(900, 400, 180, 20)],
		"enemies": [_enemy("shooter", Vector2(980, 360))],
		"signs": [
			_sign(Vector2(110, 350), "원거리 사수 — 조준 텔레그래프 후 발사\n대시로 회피, 발판으로 접근"),
		],
		"exits": [_exit_left("cw_entry"), _exit_right("cw_brute")],
	}


static func _cw_brute() -> Dictionary:
	return {
		"name": "브루트의 투기장",
		"size": Vector2(1600, 720),
		"free_move": true,
		"entries": _entries_lr(),
		"solids": [_floor()],
		"plats": [],
		"enemies": [_enemy("brute", Vector2(960, 560))],
		"signs": [
			_sign(Vector2(110, 350), "브루트(중형) — 돌진·내려찍기 텔레그래프\n약점: 물 (물 정수/서리 스킬)"),
		],
		"exits": [_exit_left("cw_shooter"), _exit_right("cw_caster")],
	}


static func _cw_caster() -> Dictionary:
	return {
		"name": "캐스터의 성소",
		"size": Vector2(1600, 720),
		"free_move": true,
		"entries": _entries_lr(),
		"solids": [_floor()],
		"plats": [Rect2(600, 460, 160, 20), Rect2(1000, 460, 160, 20)],
		"enemies": [_enemy("caster", Vector2(960, 380))],
		"signs": [
			_sign(Vector2(110, 350), "캐스터(중형) — 3연발·순간이동\n약점: 불 (불 정수/화염 스킬)"),
		],
		"exits": [_exit_left("cw_brute"), _exit_right("cw_altar")],
	}


static func _cw_altar() -> Dictionary:
	var e := _entries_lr()
	e["bench"] = Vector2(520, 560)
	return {
		"name": "정수 제단",
		"size": Vector2(1600, 720),
		"free_move": true,
		"entries": e,
		"solids": [_floor()],
		"plats": [],
		"decos": [{"rect": Rect2(760, 470, 90, 90), "color": Color(1.0, 0.85, 0.3, 0.4)}],
		"rewards": [Vector2(805, 540)],
		"bench": Vector2(520, 612),
		"signs": [
			_sign(Vector2(110, 340), "정수 제단 — 1구역 클리어!\n거점(F) 세이브·회복 · (데모 끝, Esc 메뉴)"),
		],
		"exits": [_exit_left("cw_caster")],
	}
