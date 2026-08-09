class_name Elements
extends RefCounted
## v3 속성·상성 단일 출처. 무속성 마력 칼날은 "속성 정수"를 장착하면 속성을 얻는다.
## 상성: 공격 속성이 적의 약점이면 ×WEAK, 저항이면 ×RESIST, 그 외(그리고 무속성)는 ×1.0.
## "무"(무속성)은 항상 중립 — 정수 미장착 기본 상태. SkillDB 의 한글 속성명("불"·"물")과 통일.
## player(칼날·스킬)·EnemyBase(피해 배율)·HUD(아이콘색)가 참조.

const NONE := "무"
const FIRE := "불"
const WATER := "물"

const WEAK_MULT := 1.5
const RESIST_MULT := 0.5


static func mult(attacker: String, weak: String, resist: String) -> float:
	# 공격 속성 vs 적의 약점/저항 → 피해 배율. 무속성·빈 문자열은 항상 중립.
	if attacker == NONE or attacker == "":
		return 1.0
	if weak != "" and attacker == weak:
		return WEAK_MULT
	if resist != "" and attacker == resist:
		return RESIST_MULT
	return 1.0


static func color_of(e: String) -> Color:
	# 칼날 발광·룬·HUD 아이콘 공용 속성색.
	match e:
		FIRE:
			return Color(1.0, 0.55, 0.2)
		WATER:
			return Color(0.5, 0.8, 1.0)
	return Color(0.95, 0.96, 1.0)  # 무속성 = 중립 백색


static func label(e: String) -> String:
	match e:
		FIRE:
			return "불"
		WATER:
			return "물"
	return "무속성"
