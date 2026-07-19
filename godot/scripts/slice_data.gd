class_name SliceData
extends RefCounted
## 튜토리얼 5방 청사진 — 능력 획득 진행(오브로 대시·이단점프·벽달리기 순차 습득).
## slice_room.gd 가 get_room(id) 로 방 정의를 읽어 지형·오브·게이트·적·거점·출구를
## 코드 생성한다. 좌표계: 방 원점(0,0) 좌상단, y 아래로 증가. 외벽(좌·우·천장)은
## size 로부터 slice_room 이 자동 생성하므로 여기서는 내부 지형만 나열한다.
##
## 치수 근거(player.gd 상수 직접 검산):
##   점프 JUMP_VELOCITY=-620, GRAVITY=1500 → 최고 상승 620^2/(2*1500)≈128px
##   이단점프 DOUBLE_JUMP_VELOCITY=-560 → 추가 ≈104px, 합 ≈232px
##   대시 DASH_SPEED=620 * DASH_TIME=0.14 ≈ 87px 순간 + 관성(저천장 통로로 점프 봉쇄)
##   벽달리기 WALL_RUN_SPEED=380 * WALL_RUN_MAX=0.8 ≈ 304px/회 (+벽도약 반복)
## 게이트는 시작 능력(달리기·점프)만으로 "통과 불가"를 지형으로 강제한다 →
## 해당 오브 습득 후에만 통과 가능(습득→길 열림 루프). 물/기류 필수 게이트는 없다.
##
## 오브 dict 키: id(orbs_taken 추적)·pos·grants(켤 player.abilities 키들)·label·toast.
## 출구 dict 키: rect·to·entry·arrow(문틀 화살표 방향). gate_marks: 게이트 색 표식.

const ROOM_ORDER := ["hub", "gate_room", "field1", "glade", "reward"]

const WALL_COLOR := Color(0.16, 0.19, 0.27)
const PLAT_COLOR := Color(0.20, 0.24, 0.34)


static func room_count() -> int:
	return ROOM_ORDER.size()


static func has_room(id: String) -> bool:
	return ROOM_ORDER.has(id)


static func get_room(id: String) -> Dictionary:
	# 방 정의 단일 출처. 키: name/size/solids/plats/water/updraft/bubbles/
	# enemies/rewards/signs/bench/npc/orbs/gate_marks/entries/exits.
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
	# 현관(시작) — 안전지대·거점. 시작 능력(달리기·점프·칼)만. 허수아비로 공격 학습.
	return {
		"name": "현관 (시작)",
		"size": Vector2(1200, 700),
		"solids": [Rect2(20, 560, 1160, 120)],  # 바닥
		"plats": [
			Rect2(260, 520, 120, 40),  # 벤치 받침(장식 겸 발판)
			Rect2(850, 432, 150, 20),  # 점프 연습 발판(바닥 위 128px = 단일 점프 한계)
		],
		"water": [],
		"updraft": [],
		"bubbles": [],
		"enemies": [
			{"type": "dummy", "pos": Vector2(680, 500)},  # 허수아비(칼 연습 표적)
		],
		"rewards": [],
		"bench": Vector2(320, 520),  # 거점 상호작용 지점(F: 회복·세이브·각인)
		"npc": Vector2(400, 560),  # 각인술사(거점 옆 장식)
		"signs": [
			{
				"pos": Vector2(70, 150),
				"text": "튜토리얼 — 능력 획득\n"
				+ "←→ 이동   Z 점프   A 마력 칼날\n"
				+ "오브로 대시·이단점프·벽달리기를 하나씩 배운다",
			},
			{
				"pos": Vector2(230, 430),
				"text": "거점(벤치) — 근접 후 F\n회복 · 세이브 · 각인",
			},
			{"pos": Vector2(600, 428), "text": "허수아비 — A로 마력 칼날 연습"},
			{"pos": Vector2(820, 380), "text": "발판 — Z로 점프해 오르기"},
			{"pos": Vector2(1000, 470), "text": "→ 대시 복도"},
		],
		"entries": {
			"start": Vector2(180, 500),  # 최초 진입
			"from_gate_room": Vector2(1060, 500),  # gate_room 좌측 출구로 귀환
			"from_reward": Vector2(600, 120),  # 졸업 방 낙하 지름길 착지(위에서 떨어짐)
			"bench": Vector2(320, 500),  # 사망 리스폰(거점 위치)
		},
		"exits": [
			{
				"rect": Rect2(1150, 20, 30, 540),
				"to": "gate_room",
				"entry": "from_hub",
				"arrow": "right",
			},
		],
	}


static func _gate_room() -> Dictionary:
	# 대시 복도 — 게이트①. 대시 오브 습득 후 저천장+바닥 갭을 대시로만 횡단.
	return {
		"name": "대시 복도",
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
		"orbs": [
			{
				"id": "orb_dash",
				"pos": Vector2(200, 485),
				"grants": ["dash_ground", "dash_air"],
				"label": "대시 습득",
				"toast": "대시 습득! C 또는 Shift로 대시",
			},
		],
		"gate_marks": [
			{"rect": Rect2(430, 470, 130, 50), "color": Color(0.3, 0.9, 1.0, 0.16)},
		],
		"signs": [
			{
				"pos": Vector2(120, 350),
				"text": "게이트① 대시\n저천장이라 점프 불가 —\n대시로 갭 횡단",
			},
			{"pos": Vector2(700, 380), "text": "→ 실습 터"},
			{"pos": Vector2(120, 470), "text": "← 현관"},
		],
		"entries": {
			"from_hub": Vector2(110, 460),  # 좌 바닥
			"from_field1": Vector2(900, 460),  # 우 바닥
		},
		"exits": [
			{
				"rect": Rect2(20, 20, 30, 500),
				"to": "hub",
				"entry": "from_gate_room",
				"arrow": "left",
			},
			{
				"rect": Rect2(950, 20, 30, 500),
				"to": "field1",
				"entry": "from_gate_room",
				"arrow": "right",
			},
		],
	}


static func _field1() -> Dictionary:
	# 실습 터(이단점프) — 첫 전투(walker+shooter). 게이트②. 이단점프 오브 후 선반 등정.
	return {
		"name": "실습 터 (이단점프)",
		"size": Vector2(1200, 760),
		"solids": [Rect2(20, 620, 1160, 120)],  # 바닥
		"plats": [Rect2(830, 440, 180, 16)],  # 이단점프 선반(바닥620 위 180px, 벽 비접촉)
		"water": [],
		"updraft": [],
		"bubbles": [],
		"enemies": [
			{"type": "walker", "pos": Vector2(400, 560)},
			{"type": "shooter", "pos": Vector2(760, 420)},
		],
		"rewards": [],
		"orbs": [
			{
				"id": "orb_double_jump",
				"pos": Vector2(600, 585),
				"grants": ["double_jump"],
				"label": "이단점프 습득",
				"toast": "이단점프 습득! 공중에서 Z 한 번 더",
			},
		],
		"gate_marks": [
			{"rect": Rect2(830, 456, 180, 164), "color": Color(1.0, 0.85, 0.3, 0.12)},
		],
		"signs": [
			{
				"pos": Vector2(760, 300),
				"text": "게이트② 이단점프\n단일 점프로 못 닿는 선반 —\nZ점프 후 공중 Z(이단점프)",
			},
			{"pos": Vector2(90, 470), "text": "← 대시 복도"},
			{"pos": Vector2(250, 560), "text": "첫 전투 — 워커/사수\nA 마력 칼날로 처치"},
		],
		"entries": {
			"from_gate_room": Vector2(110, 560),
			"from_glade": Vector2(1050, 560),  # 빈터에서 귀환 — 바닥(즉시 재트리거 방지)
		},
		"exits": [
			{
				"rect": Rect2(20, 20, 30, 600),
				"to": "gate_room",
				"entry": "from_field1",
				"arrow": "left",
			},
			{
				"rect": Rect2(830, 404, 180, 40),  # 이단점프 선반 위 → 굴뚝
				"to": "glade",
				"entry": "from_field1",
				"arrow": "up",
			},
		],
	}


static func _glade() -> Dictionary:
	# 굴뚝(벽달리기) — 게이트③. 벽달리기 오브 후 수직 굴뚝 등반. dummy 1기.
	# 굴뚝 치수는 combat_arena 검증 패턴(벽 20폭·안쪽 갭 120·높이 340). 물/기류 없음.
	return {
		"name": "굴뚝 (벽달리기)",
		"size": Vector2(1100, 820),
		"solids": [
			Rect2(20, 680, 1060, 120),  # 연속 바닥 (x20..1080)
			Rect2(740, 340, 20, 340),  # 굴뚝 좌벽
			Rect2(880, 340, 20, 340),  # 굴뚝 우벽 (안쪽 갭 760..880=120)
		],
		"plats": [Rect2(760, 320, 140, 16)],  # 굴뚝 상단 선반(출구 발판)
		"water": [],
		"updraft": [],
		"bubbles": [],
		"enemies": [
			{"type": "dummy", "pos": Vector2(480, 620)},
		],
		"rewards": [],
		"orbs": [
			{
				"id": "orb_wall_run",
				"pos": Vector2(300, 645),
				"grants": ["wall_run"],
				"label": "벽달리기 습득",
				"toast": "벽달리기 습득! 벽 향해 이동+↑, 벽도약 반복",
			},
		],
		"gate_marks": [
			{"rect": Rect2(760, 340, 120, 340), "color": Color(0.7, 0.5, 1.0, 0.12)},
		],
		"signs": [
			{
				"pos": Vector2(690, 250),
				"text": "게이트③ 벽달리기\n벽 향해 +↑ 로 상승,\n좌우 벽 교차(벽도약)로 굴뚝 등반",
			},
			{"pos": Vector2(90, 620), "text": "← 실습 터"},
		],
		"entries": {
			"from_field1": Vector2(140, 620),  # 좌 바닥
			"from_reward": Vector2(980, 620),  # 졸업 방에서 귀환 — 우 바닥(굴뚝 상단 아님)
		},
		"exits": [
			{
				"rect": Rect2(20, 20, 30, 660),
				"to": "field1",
				"entry": "from_glade",
				"arrow": "left",
			},
			{
				"rect": Rect2(750, 300, 160, 30),  # 굴뚝 상단 선반 위 → 졸업
				"to": "reward",
				"entry": "from_glade",
				"arrow": "up",
			},
		],
	}


static func _reward() -> Dictionary:
	# 졸업 — 튜토리얼 완료. 보상 + 각인 리마인더. 우측 수직 굴뚝으로 일방 낙하 → 현관(루프).
	return {
		"name": "졸업",
		"size": Vector2(1200, 1080),
		"solids": [
			Rect2(20, 560, 980, 120),  # 본 바닥 (x20..1000). 우측 x1000..1180=낙하 굴뚝
			Rect2(1000, 960, 180, 120),  # 굴뚝 바닥(착지)
		],
		"plats": [],
		"water": [],
		"updraft": [],
		"bubbles": [],
		"enemies": [],
		"rewards": [
			Vector2(300, 520),  # 졸업 보상
		],
		"signs": [
			{
				"pos": Vector2(120, 430),
				"text": "졸업 — 튜토리얼 완료!\n대시·이단점프·벽달리기를 모두 익혔다",
			},
			{
				"pos": Vector2(120, 490),
				"text": "각인은 거점(현관 벤치)에서 F로 — 여기선 리마인더만",
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
			{
				"rect": Rect2(20, 20, 30, 540),
				"to": "glade",
				"entry": "from_reward",
				"arrow": "left",
			},
			{
				"rect": Rect2(1000, 880, 180, 60),  # 낙하 굴뚝 하단 → 현관(일방 지름길)
				"to": "hub",
				"entry": "from_reward",
				"arrow": "down",
			},
		],
	}
