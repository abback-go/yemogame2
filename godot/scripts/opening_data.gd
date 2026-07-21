class_name OpeningData
extends RefCounted
## 오프닝(튜토리얼) 4방 청사진 — tutorial-conti.md 콘티의 씬 단위 구현.
## 씬 드라이버가 방 하나를 조립하고, 대사/토스트 상수를 참조한다.
## 흐름: op_alley(잠입) → op_run(도주·추격) → op_dead_end(미니보스) → op_duel(보스전·결투).
## 좌표계: 방 원점(0,0) 좌상단. 바닥 top y=620. 방마다 폭이 다르다(1600/2000/1000/1400).

const ROOM_ORDER := [
	"op_alley", "op_run", "op_dead_end", "op_duel",
]
const ROOM_NAMES := {
	"op_alley": "하층가 · 뒷골목",
	"op_run": "도주로",
	"op_dead_end": "막다른 골목",
	"op_duel": "결투장",
}

const OPENING_TOASTS := {
	"move": "←→ 이동 · Z 점프",
	"family": "이거 하나면 다들 겨울을 난다.",
	"artifact": "손에 넣었다 — 이제 빠져나간다",
	"alarm": "들켰다! 도망쳐라",
	"dash": "C — 대시",
	"blob": "A — 마력 덩어리",
}
# 컷씬 대사(말풍선·타자기·Z/A 진행) — who: "prof"(교수) / "player"(주인공) / "guard"(경비대장)
const DUEL_INTRO := [
	{"who": "prof", "text": "…그거, 꽤 비싼 건데."},
	{"who": "prof", "text": "내기 하나 하자. 내가 이 자리에서 한 발이라도 움직이면, 네가 이긴 거다."},
	{"who": "player", "text": "…뭐든."},
	{"who": "prof", "text": "이기면 — 평생 먹고살 걱정은 없을 거다."},
]
const DUEL_END := [
	{"who": "prof", "text": "…졌네."},
	{"who": "prof", "text": "약속은 지킨다. 학교로 와. 먹고사는 건 거기서 해결된다."},
	{"who": "prof", "text": "저건 별도다. 네가 갚아."},
]
# 지나가는 한 줄(앰비언트 말풍선 — 조작 잠금 없음, 자동 숨김)
const AMBIENT_LINES := {
	"family": "이거 하나면… 다들 겨울을 난다.",
	"artifact": "챙겼다. 튀자.",
	"guard_alarm": "도둑이다! 거기 서라!",
	"guard_corner": "막다른 골목이다. 끝났어, 꼬마.",
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
		"op_alley":
			return _op_alley()
		"op_run":
			return _op_run()
		"op_dead_end":
			return _op_dead_end()
		"op_duel":
			return _op_duel()
	push_warning("[진단] 없는 오프닝 방 id: %s — 뒷골목 대체" % id)
	return _op_alley()


# ── 조립 헬퍼 (world_data.gd 스타일) ──────────────────────────────

static func _floor(w: int) -> Rect2:
	# 방 폭 w 에 맞춘 바닥(top y=620). 좌우 20px 마진.
	return Rect2(20, 620, w - 40, 100)


static func _exit(rect: Rect2, to: String, entry: String, arrow: String) -> Dictionary:
	return {"rect": rect, "to": to, "entry": entry, "arrow": arrow}


static func _exit_right(w: int, to: String) -> Dictionary:
	# 오른쪽 벽 출구 → 다음 방 from_left 진입.
	return _exit(Rect2(w - 64, 500, 44, 120), to, "from_left", "right")


# ── 씬1: 하층가 · 뒷골목 (잠입 — 이동·점프) ───────────────────────

static func _op_alley() -> Dictionary:
	# 좌상단 지붕(y~350)에서 시작 → 차양을 계단식으로 밟아 내려가 → 우측 바닥 마도구.
	return {
		"name": "하층가 · 뒷골목",
		"size": Vector2(1600, 720),
		"entries": {"start": Vector2(200, 290)},
		"solids": [_floor(1600)],
		"plats": [
			Rect2(120, 350, 280, 20),
			Rect2(480, 440, 200, 20),
			Rect2(800, 520, 200, 20),
			Rect2(1120, 580, 180, 20),
		],
		"artifact_pos": Vector2(1380, 560),
		"sleepers_pos": Vector2(300, 330),
		"exits": [_exit_right(1600, "op_run")],
	}


# ── 씬2: 도주로 (추격 — 대시) ─────────────────────────────────────

static func _op_run() -> Dictionary:
	# 바닥이 갭 2개(폭 260px)로 끊김. 갭 아래 y=680 얕은 세이프티(낙사 아님).
	return {
		"name": "도주로",
		"size": Vector2(2000, 720),
		"entries": {"from_left": Vector2(90, 560), "start": Vector2(90, 560)},
		"solids": [
			Rect2(20, 620, 580, 100),
			Rect2(860, 620, 500, 100),
			Rect2(1620, 620, 360, 100),
			Rect2(600, 680, 260, 40),
			Rect2(1360, 680, 260, 40),
		],
		"plats": [],
		"chaser_spawn": Vector2(120, 560),
		"exits": [_exit_right(2000, "op_dead_end")],
	}


# ── 씬3: 막다른 골목 (미니보스 — 경비대장) ────────────────────────

static func _op_dead_end() -> Dictionary:
	# 우측 끝 높은 담(넘을 수 없음). exits 없음 — 전투 후 드라이버가 강제 전환.
	return {
		"name": "막다른 골목",
		"size": Vector2(1000, 720),
		"entries": {"from_left": Vector2(90, 560), "start": Vector2(90, 560)},
		"solids": [_floor(1000), Rect2(940, 200, 40, 420)],
		"plats": [],
		"guard_spawn": Vector2(220, 560),
		"exits": [],
	}


# ── 씬4~6: 결투장 (보스전 + 대화) ─────────────────────────────────

static func _op_duel() -> Dictionary:
	# 넓은 평지 안마당. 궤짝 위 마도구는 데코로 드라이버가 그림(여긴 좌표만).
	# exits 없음 — 대화(DUEL_END) 후 드라이버가 학교(hub_plaza)로 전환.
	return {
		"name": "결투장",
		"size": Vector2(1400, 720),
		"entries": {"start": Vector2(150, 560)},
		"solids": [_floor(1400)],
		"plats": [],
		"boss_spawn": Vector2(1000, 560),
		"artifact_prop": Vector2(1150, 585),
		"exits": [],
	}
