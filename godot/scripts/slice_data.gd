class_name SliceData
extends RefCounted
## 수직 슬라이스 5방 청사진 — 손 제작 구역의 단일 출처(정본 맵과 무관).
## slice_room.gd 가 get_room(id) 로 방 정의를 읽어 지형·게이트·적·존·거점·출구를
## 코드 생성한다. 좌표계: 방 원점(0,0) 좌상단, y 아래로 증가. 외벽(좌·우·천장)은
## size 로부터 slice_room 이 자동 생성하므로 여기서는 내부 지형만 나열한다.
##
## 치수 근거(player.gd 상수 직접 검산):
##   점프 JUMP_VELOCITY=-620, GRAVITY=1500 → 최고 상승 620^2/(2*1500)≈128px
##   이단점프 DOUBLE_JUMP_VELOCITY=-560 → 추가 ≈104px, 합 ≈232px
##   대시 DASH_SPEED=620 * DASH_TIME=0.14 ≈ 87px 순간 + 관성(저천장 통로로 점프 봉쇄)
##   벽달리기 WALL_RUN_SPEED=380 * WALL_RUN_MAX=0.8 ≈ 304px/회 (+벽도약 반복)
##   활공 상승기류 GLIDE_UPDRAFT_RISE=-260 → 기둥 위 비밀 선반 도달
## 게이트는 "기본 단일 점프로 불가"를 지형으로 강제한다(이동기 전부 ON — 상급 우회는 허용).

const ROOM_ORDER := ["hub", "gate_room", "field1", "glade", "reward"]

const WALL_COLOR := Color(0.16, 0.19, 0.27)
const PLAT_COLOR := Color(0.20, 0.24, 0.34)


static func room_count() -> int:
	return ROOM_ORDER.size()


static func has_room(id: String) -> bool:
	return ROOM_ORDER.has(id)


static func get_room(id: String) -> Dictionary:
	# 방 정의 단일 출처. 키: name/size/solids/plats/water/updraft/bubbles/
	# enemies/rewards/signs/bench/npc/entries/exits.
	match id:
		"hub":
			return _hub()
		"gate_room":
			return _gate_room()
		"field1":
			return _field1()
		"glade":
			return _glade()
		"reward":
			return _reward()
	push_warning("[진단] SliceData.get_room 알 수 없는 방: %s → hub 대체" % id)
	return _hub()


static func _hub() -> Dictionary:
	# 학교 현관 — 안전지대·거점. 적 없음. 우측 출구→gate_room. 좌측=슬라이스 안내.
	return {
		"name": "학교 현관",
		"size": Vector2(1200, 700),
		"solids": [Rect2(20, 560, 1160, 120)],  # 바닥
		"plats": [Rect2(260, 520, 120, 40)],  # 벤치 받침(장식 겸 발판)
		"water": [],
		"updraft": [],
		"bubbles": [],
		"enemies": [],
		"rewards": [],
		"bench": Vector2(320, 520),  # 거점 상호작용 지점(F: 회복·세이브·각인)
		"npc": Vector2(400, 560),  # 각인술사(거점 옆 장식)
		"signs": [
			{
				"pos": Vector2(70, 150),
				"text": "[수직 슬라이스] 학교 현관 → 뒷숲\n"
				+ "루프: 현관→문→실습터→빈터→안쪽→(낙하 지름길)→현관\n"
				+ "게이트: 대시 / 이단점프 / 벽달리기 / 활공",
			},
			{
				"pos": Vector2(230, 430),
				"text": "거점(벤치) — 근접 후 F\n회복 · 세이브 · 각인",
			},
			{"pos": Vector2(980, 470), "text": "→ 뒷숲 문\n(대시 게이트)"},
		],
		"entries": {
			"start": Vector2(180, 500),  # 최초 진입
			"from_gate_room": Vector2(1060, 500),  # gate_room 좌측 출구로 귀환
			"from_reward": Vector2(600, 120),  # 안쪽 방 낙하 지름길 착지(위에서 떨어짐)
			"bench": Vector2(320, 500),  # 사망 리스폰(거점 위치)
		},
		"exits": [
			{"rect": Rect2(1150, 20, 30, 540), "to": "gate_room", "entry": "from_hub"},
		],
	}


static func _gate_room() -> Dictionary:
	# 뒷숲 문 — 전이 방. 게이트①=대시: 저천장 통로 + 바닥 갭(점프 봉쇄, 대시로만 횡단).
	return {
		"name": "뒷숲 문",
		"size": Vector2(1000, 640),
		"solids": [
			Rect2(20, 520, 410, 120),  # 좌 바닥 (x20..430)
			Rect2(560, 520, 420, 120),  # 우 바닥 (x560..980), 갭 x430..560 ≈130px
			Rect2(360, 460, 300, 20),  # 저천장(바닥520↔천장480, 여유 40px→점프 봉쇄)
		],
		"plats": [],
		"water": [],
		"updraft": [],
		"bubbles": [],
		"enemies": [],
		"rewards": [],
		"signs": [
			{
				"pos": Vector2(150, 360),
				"text": "게이트① 대시\n저천장이라 점프 불가 —\nC(대시)로 갭 횡단",
			},
			{"pos": Vector2(700, 380), "text": "→ 실습 터"},
			{"pos": Vector2(120, 470), "text": "← 현관"},
		],
		"entries": {
			"from_hub": Vector2(110, 460),  # 좌 바닥
			"from_field1": Vector2(900, 460),  # 우 바닥
		},
		"exits": [
			{"rect": Rect2(20, 20, 30, 500), "to": "hub", "entry": "from_gate_room"},
			{"rect": Rect2(950, 20, 30, 500), "to": "field1", "entry": "from_gate_room"},
		],
	}


static func _field1() -> Dictionary:
	# 실습 터 — 전투1(walker+shooter). 게이트②=이단점프: 단일 점프로 못 닿는 선반 위 출구.
	return {
		"name": "실습 터",
		"size": Vector2(1200, 760),
		"solids": [Rect2(20, 620, 1160, 120)],  # 바닥
		"plats": [Rect2(830, 440, 180, 16)],  # 이단점프 선반(바닥620 위 180px, 벽 비접촉)
		"water": [],
		"updraft": [],
		"bubbles": [],
		"enemies": [
			{"type": "walker", "pos": Vector2(480, 560)},
			{"type": "shooter", "pos": Vector2(720, 420)},
		],
		"rewards": [],
		"signs": [
			{
				"pos": Vector2(720, 300),
				"text": "게이트② 이단점프\n단일 점프로 못 닿는 선반 —\nZ점프 후 공중 Z(이단점프)",
			},
			{"pos": Vector2(90, 470), "text": "← 뒷숲 문"},
			{"pos": Vector2(300, 560), "text": "실습 터 — 워커/사수\nA 마력 칼날로 처치"},
		],
		"entries": {
			"from_gate_room": Vector2(110, 560),
			"from_glade": Vector2(1050, 560),  # 빈터에서 귀환 — 바닥(선반 아님, 즉시 재트리거 방지)
		},
		"exits": [
			{"rect": Rect2(20, 20, 30, 600), "to": "gate_room", "entry": "from_field1"},
			# 이단점프 선반 위 → 빈터
			{"rect": Rect2(830, 404, 180, 40), "to": "glade", "entry": "from_field1"},
		],
	}


static func _glade() -> Dictionary:
	# 실습림 빈터 — 전투(dummy)+게이트③=벽달리기(수직 굴뚝) + 물잠 존(산소통).
	# 굴뚝 치수는 combat_arena 검증 패턴 복제(벽 20폭·안쪽 갭 120·높이 340).
	return {
		"name": "실습림 빈터",
		"size": Vector2(1100, 820),
		"solids": [
			Rect2(20, 680, 300, 120),  # 좌 바닥 (x20..320)
			Rect2(460, 680, 620, 120),  # 우 바닥 (x460..1080), 물웅덩이 x320..460
			Rect2(320, 800, 140, 20),  # 물웅덩이 바닥
			Rect2(740, 340, 20, 340),  # 굴뚝 좌벽
			Rect2(880, 340, 20, 340),  # 굴뚝 우벽 (안쪽 갭 760..880=120)
		],
		"plats": [Rect2(760, 320, 140, 16)],  # 굴뚝 상단 선반(출구 발판)
		"water": [Rect2(320, 680, 140, 120)],  # 물잠 존(수면 y680, 깊이 120)
		"updraft": [],
		"bubbles": [Vector2(390, 760)],  # 산소통
		"enemies": [
			{"type": "dummy", "pos": Vector2(600, 620)},
		],
		"rewards": [],
		"signs": [
			{
				"pos": Vector2(690, 250),
				"text": "게이트③ 벽달리기\n벽 향해 +↑ 로 상승,\n좌우 벽 교차(벽도약)로 굴뚝 등반",
			},
			{"pos": Vector2(300, 600), "text": "물잠 — ↓로 잠수\n하늘색 방울=산소 리필"},
			{"pos": Vector2(90, 620), "text": "← 실습 터"},
		],
		"entries": {
			"from_field1": Vector2(140, 620),  # 좌 바닥
			"from_reward": Vector2(980, 620),  # 안쪽 방에서 귀환 — 우 바닥(굴뚝 상단 아님)
		},
		"exits": [
			{"rect": Rect2(20, 20, 30, 660), "to": "field1", "entry": "from_glade"},
			# 굴뚝 상단 선반 위 → 안쪽 방
			{"rect": Rect2(750, 300, 160, 30), "to": "reward", "entry": "from_glade"},
		],
	}


static func _reward() -> Dictionary:
	# 실습림 안쪽 — 보상 + 루프 닫기. 게이트④(선택)=활공(상승기류)로 비밀 선반.
	# 우측 수직 굴뚝으로 일방 낙하 → 현관(백트래킹이 지름길임을 실증).
	return {
		"name": "실습림 안쪽",
		"size": Vector2(1200, 1080),
		"solids": [
			Rect2(20, 560, 980, 120),  # 본 바닥 (x20..1000). 우측 x1000..1180=낙하 굴뚝
			Rect2(1000, 960, 180, 120),  # 굴뚝 바닥(착지)
		],
		"plats": [
			Rect2(520, 280, 150, 16),  # 비밀 선반(활공 게이트④ 보상)
		],
		"water": [],
		"updraft": [Rect2(560, 300, 90, 260)],  # 상승기류 기둥(활공으로 비밀 선반 상승)
		"bubbles": [],
		"enemies": [],
		"rewards": [
			Vector2(300, 520),  # 본 보상
			Vector2(595, 255),  # 비밀 보상(선반 위)
		],
		"signs": [
			{"pos": Vector2(120, 460), "text": "실습림 안쪽 — 보상 지점"},
			{
				"pos": Vector2(470, 360),
				"text": "게이트④(선택) 활공\n↓ 홀드로 상승기류 타고\n비밀 선반 등정",
			},
			{
				"pos": Vector2(1000, 700),
				"text": "↓ 낙하 지름길\n굴뚝으로 뛰어내리면\n곧장 현관(백트래킹=지름길)",
			},
		],
		"entries": {
			"from_glade": Vector2(110, 500),  # 본 바닥 좌
		},
		"exits": [
			{"rect": Rect2(20, 20, 30, 540), "to": "glade", "entry": "from_reward"},
			# 낙하 굴뚝 하단 → 현관(일방 지름길)
			{"rect": Rect2(1000, 880, 180, 60), "to": "hub", "entry": "from_reward"},
		],
	}
