class_name SkillDB
extends RefCounted
## v3 각인 스킬 레지스트리 — 4종 스킬의 메타데이터 단일 출처(id·한글명·속성·순서).
## 실수치(cooldown·mana·cast_tell)는 player.gd 의 @export 가 인스턴스별로 보유해
## F5 손 튜닝을 유지한다. 여기서는 표기·라우팅에 쓰는 고정 정보만 둔다.
## NPC 각인 패널(engrave_panel.gd)·전투 HUD(debug_hud.gd)가 참조.

const SKILLS := [
	{"id": "flame_pillar", "name_kr": "화염 기둥", "element": "불"},
	{"id": "meteor", "name_kr": "메테오", "element": "불"},
	{"id": "frost_spear", "name_kr": "서리창", "element": "물"},
	{"id": "ice_burst", "name_kr": "빙정 폭발", "element": "물"},
]


static func ids() -> Array[String]:
	# 표시 순서대로의 skill id 목록.
	var out: Array[String] = []
	for s in SKILLS:
		out.append(s["id"])
	return out


static func name_of(id: String) -> String:
	for s in SKILLS:
		if s["id"] == id:
			return s["name_kr"]
	return ""


static func element_of(id: String) -> String:
	for s in SKILLS:
		if s["id"] == id:
			return s["element"]
	return ""
