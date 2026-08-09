class_name SchoolData
extends RefCounted
## 협곡 학교 심장부 12방 그레이박스 청사진 — school_room.gd 가 get_room(id) 로 읽어
## 지형·장식·NPC·팻말·거점·출구·막힌 문을 코드 생성한다(RoomBuilder 헬퍼 사용).
## 정본(docs/world/regions/sch.json)의 방 id·연결·컨셉·NPC 이름·치수를 참고했으나,
## world_map.json 파이프라인과는 무관한 별도 그레이박스다(정본 미접촉).
##
## 좌표계: 방 원점(0,0) 좌상단, y 아래로 증가. 외벽(좌·우·천장)은 size 로부터 school_room
## 이 자동 생성하므로 여기서는 내부 지형만 나열한다. 학교=안전지대·전 이동기 ON·능력
## 게이트 없음 → 모든 발판은 걷기/점프로 도달 가능(오브·물/기류·수직 게이트 없음).
##
## 방 dict 키:
##   name/size/solids/plats/decos/enemies/rewards/npcs/signs/bench/blocked/entries/exits.
##   npcs: [{pos, label, color}]  ·  blocked: [{rect, arrow, name}](미구현 문 스텁)
##   exits: [{rect, to, entry, arrow}]  entry = 목적지 방에서 이 문으로 들어올 때의 입장 키.
##   decos: [{rect, color}] 충돌 없는 장식 표식(각인 문양·구덩이 등).

const ROOM_ORDER := [
	"sch_plaza", "sch_hall_main", "sch_office",
	"sch_class_fire", "sch_class_water", "sch_class_wind", "sch_class_move",
	"sch_dome", "sch_trial_hall", "sch_ceremony",
	"sch_dorm_hall", "sch_dorm_room",
]

const ROOM_NAMES := {
	"sch_plaza": "정문 마당",
	"sch_hall_main": "본관 홀",
	"sch_office": "교무처",
	"sch_class_fire": "불 기초 교실",
	"sch_class_water": "물 기초 교실",
	"sch_class_wind": "바람 기초 교실",
	"sch_class_move": "이동술 강의실",
	"sch_dome": "결계 돔",
	"sch_trial_hall": "시험의 회랑",
	"sch_ceremony": "승급의 방",
	"sch_dorm_hall": "기숙사 복도",
	"sch_dorm_room": "내 방",
}

const COL_PROF := Color(0.7, 0.55, 1.0)  # 교수
const COL_STAFF := Color(0.55, 0.8, 0.65)  # 행정·감독
const COL_STUDENT := Color(0.6, 0.75, 1.0)  # 학생
const COL_OBJECT := Color(0.72, 0.6, 0.42)  # 게시판·노점 등 사물형


static func room_count() -> int:
	return ROOM_ORDER.size()


static func has_room(id: String) -> bool:
	return ROOM_ORDER.has(id)


static func room_name(id: String) -> String:
	return String(ROOM_NAMES.get(id, id))


static func get_room(id: String) -> Dictionary:
	match id:
		"sch_plaza":
			return _plaza()
		"sch_hall_main":
			return _hall_main()
		"sch_office":
			return _office()
		"sch_class_fire":
			return _class_fire()
		"sch_class_water":
			return _class_water()
		"sch_class_wind":
			return _class_wind()
		"sch_class_move":
			return _class_move()
		"sch_dome":
			return _dome()
		"sch_trial_hall":
			return _trial_hall()
		"sch_ceremony":
			return _ceremony()
		"sch_dorm_hall":
			return _dorm_hall()
		"sch_dorm_room":
			return _dorm_room()
	push_warning("[진단] SchoolData.get_room 알 수 없는 방: %s → 정문 마당 대체" % id)
	return _plaza()


static func _plaza() -> Dictionary:
	# 정문 마당(시작·중앙 광장) — 6방향 분기 중 본관·기숙사만 개방, 4개는 미구현 스텁.
	return {
		"name": "정문 마당",
		"size": Vector2(2000, 760),
		"solids": [Rect2(20, 620, 1960, 120)],  # 바닥
		"plats": [
			Rect2(80, 500, 300, 20),  # 좌 테라스(기숙사行, 바닥 위 120px)
			Rect2(1620, 500, 300, 20),  # 우 테라스(시계탑行, 미구현)
		],
		"decos": [],
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(720, 620), "label": "의뢰 게시판", "color": COL_OBJECT},
			{"pos": Vector2(1000, 620), "label": "잡화 노점", "color": COL_OBJECT},
			{"pos": Vector2(1250, 620), "label": "학생", "color": COL_STUDENT},
		],
		"signs": [
			{
				"pos": Vector2(480, 360),
				"text": "정문 마당 — 학교 심장부(시작)\n"
				+ "←→ 이동   Z 점프   C 대시   A 마력 칼날   F 거점\n"
				+ "시안 문틀 = 열린 길 · 회색 문틀 = 미구현",
			},
			{"pos": Vector2(120, 452), "text": "↑ 좌 테라스 — 기숙사 복도"},
			{"pos": Vector2(1640, 452), "text": "↑ 우 테라스 — 시계탑(미구현)"},
		],
		"blocked": [
			{"rect": Rect2(60, 500, 30, 120), "arrow": "down", "name": "곤돌라 승강장"},
			{"rect": Rect2(430, 500, 30, 120), "arrow": "left", "name": "서쪽 다리"},
			{"rect": Rect2(1700, 420, 30, 80), "arrow": "up", "name": "시계탑 기단"},
			{"rect": Rect2(1500, 500, 30, 120), "arrow": "right", "name": "뒷숲 문"},
		],
		"entries": {
			"start": Vector2(1000, 560),
			"from_hall_main": Vector2(1870, 560),
			"from_dorm_hall": Vector2(320, 440),  # 테라스 위, 기숙사 문 트리거(x150~250) 밖
		},
		"exits": [
			{
				"rect": Rect2(1968, 20, 32, 600),
				"to": "sch_hall_main",
				"entry": "from_plaza",
				"arrow": "right",
			},
			{
				"rect": Rect2(150, 420, 100, 80),  # 좌 테라스 위 → 기숙사 복도
				"to": "sch_dorm_hall",
				"entry": "from_plaza",
				"arrow": "up",
			},
		],
	}


static func _hall_main() -> Dictionary:
	# 본관 홀(중앙 허브·지도 입수처) — 5방 개방 + 대도서관·아래 계단 미구현 스텁.
	return {
		"name": "본관 홀",
		"size": Vector2(2000, 820),
		"solids": [Rect2(20, 680, 1960, 120)],  # 바닥
		"plats": [
			Rect2(1250, 620, 100, 20),  # 대계단 디딤(중2층 진입 발판)
			Rect2(1350, 560, 610, 20),  # 중2층 갤러리(교무처·결계 돔)
		],
		"decos": [],
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(350, 680), "label": "지도 배부 게시판", "color": COL_OBJECT},
			{"pos": Vector2(650, 680), "label": "학생", "color": COL_STUDENT},
		],
		"signs": [
			{
				"pos": Vector2(820, 460),
				"text": "본관 홀 — 학교 지도 입수처\n대계단 위 갤러리: 교무처 · 결계 돔",
			},
			{"pos": Vector2(220, 500), "text": "↓ 이동술 강의실"},
			{"pos": Vector2(470, 500), "text": "↓ 불 기초 교실"},
		],
		"blocked": [
			{"rect": Rect2(1350, 440, 30, 120), "arrow": "up", "name": "대도서관"},
			{"rect": Rect2(750, 560, 30, 120), "arrow": "down", "name": "아래 계단"},
		],
		"entries": {
			"from_plaza": Vector2(130, 620),
			"from_class_fire": Vector2(620, 620),  # 불 교실 문 트리거(x500~530) 밖
			"from_class_move": Vector2(380, 620),  # 이동술 문 트리거(x250~280) 밖
			"from_office": Vector2(1560, 500),
			"from_dome": Vector2(1760, 500),
		},
		"exits": [
			{
				"rect": Rect2(20, 20, 32, 660),
				"to": "sch_plaza",
				"entry": "from_hall_main",
				"arrow": "left",
			},
			{
				"rect": Rect2(500, 560, 30, 120),
				"to": "sch_class_fire",
				"entry": "from_hall_main",
				"arrow": "down",
			},
			{
				"rect": Rect2(250, 560, 30, 120),
				"to": "sch_class_move",
				"entry": "from_hall_main",
				"arrow": "down",
			},
			{
				"rect": Rect2(1450, 440, 30, 120),  # 중2층 갤러리 위
				"to": "sch_office",
				"entry": "from_hall_main",
				"arrow": "right",
			},
			{
				"rect": Rect2(1880, 440, 30, 120),  # 중2층 갤러리 우측 끝
				"to": "sch_dome",
				"entry": "from_hall_main",
				"arrow": "right",
			},
		],
	}


static func _office() -> Dictionary:
	# 교무처(S) — 승급 서류·지도 발급. NPC 노마 페이지.
	return {
		"name": "교무처",
		"size": Vector2(720, 480),
		"solids": [Rect2(20, 340, 680, 120)],
		"plats": [],
		"decos": [{"rect": Rect2(360, 300, 160, 40), "color": Color(0.4, 0.34, 0.26, 0.5)}],
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(470, 340), "label": "노마 페이지 (교무처 직원)", "color": COL_STAFF},
		],
		"signs": [
			{"pos": Vector2(200, 180), "text": "교무처 — 승급 서류 · 지도 발급\n승급 시험 1부(이론) 접수처"},
		],
		"blocked": [],
		"entries": {"from_hall_main": Vector2(130, 280)},
		"exits": [
			{
				"rect": Rect2(20, 20, 32, 320),
				"to": "sch_hall_main",
				"entry": "from_office",
				"arrow": "left",
			},
		],
	}


static func _class_fire() -> Dictionary:
	# 불 기초 교실(M) — 이론 교실. NPC 가름 블레이즈. ↔ 본관, ↔ 물 교실.
	return {
		"name": "불 기초 교실",
		"size": Vector2(1100, 600),
		"solids": [Rect2(20, 460, 1060, 120)],
		"plats": [],
		"decos": [{"rect": Rect2(500, 420, 120, 40), "color": Color(0.9, 0.4, 0.2, 0.28)}],  # 화로
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(560, 460), "label": "가름 블레이즈 (불 교수)", "color": COL_PROF},
		],
		"signs": [
			{"pos": Vector2(300, 280), "text": "불 기초 교실 — 화로에 불을 붙이는 첫 수업"},
		],
		"blocked": [],
		"entries": {
			"from_hall_main": Vector2(150, 400),
			"from_class_water": Vector2(960, 400),
		},
		"exits": [
			{
				"rect": Rect2(80, 340, 30, 120),
				"to": "sch_hall_main",
				"entry": "from_class_fire",
				"arrow": "up",
			},
			{
				"rect": Rect2(1068, 20, 32, 440),
				"to": "sch_class_water",
				"entry": "from_class_fire",
				"arrow": "right",
			},
		],
	}


static func _class_water() -> Dictionary:
	# 물 기초 교실(M) — 이론 교실. NPC 이레나 모스. ↔ 불 교실, ↔ 바람 교실.
	return {
		"name": "물 기초 교실",
		"size": Vector2(1100, 600),
		"solids": [Rect2(20, 460, 1060, 120)],
		"plats": [],
		"decos": [{"rect": Rect2(20, 570, 1060, 10), "color": Color(0.3, 0.55, 0.9, 0.22)}],  # 젖은 바닥
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(560, 460), "label": "이레나 모스 (물 교수)", "color": COL_PROF},
		],
		"signs": [
			{"pos": Vector2(300, 280), "text": "물 기초 교실 — 수반과 물시계의 방"},
		],
		"blocked": [],
		"entries": {
			"from_class_fire": Vector2(150, 400),
			"from_class_wind": Vector2(960, 400),
		},
		"exits": [
			{
				"rect": Rect2(20, 20, 32, 440),
				"to": "sch_class_fire",
				"entry": "from_class_water",
				"arrow": "left",
			},
			{
				"rect": Rect2(1068, 20, 32, 440),
				"to": "sch_class_wind",
				"entry": "from_class_water",
				"arrow": "right",
			},
		],
	}


static func _class_wind() -> Dictionary:
	# 바람 기초 교실(M) — 이론 교실(막다른 방). NPC 핀 카일. ↔ 물 교실.
	return {
		"name": "바람 기초 교실",
		"size": Vector2(1100, 600),
		"solids": [Rect2(20, 460, 1060, 120)],
		"plats": [],
		"decos": [],
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(560, 460), "label": "핀 카일 (바람 교수)", "color": COL_PROF},
		],
		"signs": [
			{"pos": Vector2(300, 280), "text": "바람 기초 교실 — 창이 전부 열린 방\n종이가 날아 문진이 필수다"},
		],
		"blocked": [],
		"entries": {"from_class_water": Vector2(150, 400)},
		"exits": [
			{
				"rect": Rect2(20, 20, 32, 440),
				"to": "sch_class_water",
				"entry": "from_class_wind",
				"arrow": "left",
			},
		],
	}


static func _class_move() -> Dictionary:
	# 이동술 강의실(M, 막다른 방) — 이동술 이론. NPC 테오 반스. 발코니 보너스(장식).
	return {
		"name": "이동술 강의실",
		"size": Vector2(1300, 760),
		"solids": [Rect2(20, 620, 1260, 120)],
		"plats": [
			Rect2(650, 470, 140, 20),  # 중간 디딤
			Rect2(850, 320, 200, 20),  # 발코니(보너스)
		],
		"decos": [
			{"rect": Rect2(300, 590, 220, 30), "color": Color(0.28, 0.32, 0.5, 0.4)},  # 시범 구덩이
			{"rect": Rect2(150, 600, 400, 16), "color": Color(1.0, 0.85, 0.3, 0.12)},  # 바닥 문양
		],
		"enemies": [],
		"rewards": [Vector2(950, 300)],  # 발코니 보너스 마력석
		"npcs": [
			{"pos": Vector2(500, 620), "label": "테오 반스 (이동술 교수)", "color": COL_PROF},
		],
		"signs": [
			{"pos": Vector2(300, 440), "text": "이동술 강의실 — 이단점프 · 벽달리기 이론\n책상 없는 개방 바닥"},
			{"pos": Vector2(820, 280), "text": "발코니 — 이동술로 오르는 보너스"},
		],
		"blocked": [],
		"entries": {"from_hall_main": Vector2(150, 560)},
		"exits": [
			{
				"rect": Rect2(80, 500, 30, 120),
				"to": "sch_hall_main",
				"entry": "from_class_move",
				"arrow": "up",
			},
		],
	}


static func _dome() -> Dictionary:
	# 결계 돔(L) — 학교 유일 전투(훈련 허수아비 2기). ↔ 본관, ↔ 시험의 회랑, ↔ 승급의 방.
	return {
		"name": "결계 돔",
		"size": Vector2(1900, 820),
		"solids": [Rect2(20, 680, 1860, 120)],
		"plats": [
			Rect2(700, 620, 120, 20),  # 승급의 방行 디딤
			Rect2(850, 540, 200, 20),  # 중앙 발판(승급의 방 문틀)
		],
		"decos": [{"rect": Rect2(800, 640, 400, 40), "color": Color(0.4, 0.6, 1.0, 0.12)}],  # 대련 링
		"enemies": [
			{"type": "dummy", "pos": Vector2(500, 620)},
			{"type": "dummy", "pos": Vector2(1300, 620)},
		],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(1600, 680), "label": "마르타 그림 (실습 감독)", "color": COL_STAFF},
		],
		"signs": [
			{
				"pos": Vector2(300, 440),
				"text": "결계 돔 — 학교 유일 전투 실습\n훈련 허수아비: A로 마력 칼날 · R 리스폰",
			},
			{"pos": Vector2(880, 400), "text": "↑ 승급의 방"},
		],
		"blocked": [],
		"entries": {
			"from_hall_main": Vector2(130, 620),
			"from_trial_hall": Vector2(1780, 620),
			"from_ceremony": Vector2(950, 480),
		},
		"exits": [
			{
				"rect": Rect2(20, 20, 32, 660),
				"to": "sch_hall_main",
				"entry": "from_dome",
				"arrow": "left",
			},
			{
				"rect": Rect2(1868, 20, 32, 660),
				"to": "sch_trial_hall",
				"entry": "from_dome",
				"arrow": "right",
			},
			{
				"rect": Rect2(910, 420, 30, 120),  # 중앙 발판 위
				"to": "sch_ceremony",
				"entry": "from_dome",
				"arrow": "up",
			},
		],
	}


static func _trial_hall() -> Dictionary:
	# 시험의 회랑(L) — 이동술 과제 코스(그레이박스: 게이트 없음). ↔ 돔, 감정학 교실 미구현.
	return {
		"name": "시험의 회랑",
		"size": Vector2(1900, 760),
		"solids": [Rect2(20, 620, 1860, 120)],
		"plats": [
			Rect2(500, 500, 180, 20),  # 재구성 석판(장식)
			Rect2(760, 420, 180, 20),
			Rect2(1020, 500, 180, 20),
		],
		"decos": [],
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(300, 620), "label": "오스카 벨 (시험관)", "color": COL_STAFF},
		],
		"signs": [
			{
				"pos": Vector2(350, 440),
				"text": "시험의 회랑 — 이동술 과제 코스\n(그레이박스: 이동 게이트 없음)",
			},
		],
		"blocked": [
			{"rect": Rect2(1868, 20, 32, 600), "arrow": "right", "name": "감정학 교실"},
		],
		"entries": {"from_dome": Vector2(130, 560)},
		"exits": [
			{
				"rect": Rect2(20, 20, 32, 600),
				"to": "sch_dome",
				"entry": "from_trial_hall",
				"arrow": "left",
			},
		],
	}


static func _ceremony() -> Dictionary:
	# 승급의 방(M) — 승급식 원형 홀. NPC 학장 아우렐 하임 + 교수단. ↔ 돔.
	return {
		"name": "승급의 방",
		"size": Vector2(1300, 820),
		"solids": [Rect2(20, 680, 1260, 120)],
		"plats": [],
		"decos": [{"rect": Rect2(500, 620, 300, 60), "color": Color(1.0, 0.85, 0.3, 0.16)}],  # 방사형 문양
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(650, 680), "label": "아우렐 하임 (학장)", "color": COL_PROF},
			{"pos": Vector2(900, 680), "label": "교수단", "color": COL_STAFF},
		],
		"signs": [
			{"pos": Vector2(450, 460), "text": "승급의 방 — 승급식 원형 홀\n바닥 문양이 승급자에게만 빛난다"},
		],
		"blocked": [],
		"entries": {"from_dome": Vector2(150, 620)},
		"exits": [
			{
				"rect": Rect2(80, 560, 30, 120),
				"to": "sch_dome",
				"entry": "from_ceremony",
				"arrow": "down",
			},
		],
	}


static func _dorm_hall() -> Dictionary:
	# 기숙사 복도(M) — 생활 허브. ↔ 정문 마당, ↔ 내 방. 급식동·기숙사 지붕 미구현.
	return {
		"name": "기숙사 복도",
		"size": Vector2(1500, 640),
		"solids": [Rect2(20, 500, 1460, 120)],
		"plats": [],
		"decos": [],
		"enemies": [],
		"rewards": [],
		"npcs": [
			{"pos": Vector2(600, 500), "label": "룸메이트", "color": COL_STUDENT},
			{"pos": Vector2(950, 500), "label": "기숙사생", "color": COL_STUDENT},
		],
		"signs": [
			{"pos": Vector2(500, 340), "text": "기숙사 복도 — 문패 늘어선 생활 허브"},
		],
		"blocked": [
			{"rect": Rect2(1468, 20, 32, 480), "arrow": "right", "name": "급식동"},
			{"rect": Rect2(760, 380, 30, 120), "arrow": "up", "name": "기숙사 지붕"},
		],
		"entries": {
			"from_plaza": Vector2(460, 440),
			"from_dorm_room": Vector2(130, 440),
		},
		"exits": [
			{
				"rect": Rect2(20, 20, 32, 480),
				"to": "sch_dorm_room",
				"entry": "from_dorm_hall",
				"arrow": "left",
			},
			{
				"rect": Rect2(350, 380, 30, 120),
				"to": "sch_plaza",
				"entry": "from_dorm_hall",
				"arrow": "down",
			},
		],
	}


static func _dorm_room() -> Dictionary:
	# 내 방(S) — 플레이어 거점(bench). F: 회복·세이브·각인. 리스폰 지점. ↔ 기숙사 복도.
	return {
		"name": "내 방",
		"size": Vector2(760, 480),
		"solids": [Rect2(20, 340, 720, 120)],
		"plats": [],
		"decos": [{"rect": Rect2(430, 300, 130, 40), "color": Color(0.4, 0.34, 0.26, 0.5)}],  # 책상
		"enemies": [],
		"rewards": [],
		"npcs": [],
		"bench": Vector2(220, 300),
		"signs": [
			{"pos": Vector2(340, 170), "text": "내 방 — 거점\n침대 · 책상 · 기록 정리대"},
			{"pos": Vector2(340, 230), "text": "거점(벤치) 근접 후 F\n회복 · 세이브 · 각인"},
		],
		"blocked": [],
		"entries": {
			"from_dorm_hall": Vector2(640, 280),
			"bench": Vector2(250, 280),
		},
		"exits": [
			{
				"rect": Rect2(728, 20, 32, 320),
				"to": "sch_dorm_hall",
				"entry": "from_dorm_room",
				"arrow": "right",
			},
		],
	}
