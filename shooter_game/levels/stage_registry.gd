extends RefCounted
# ============================================================
#  STAGE REGISTRY - איזה קובץ בונה כל שלב. שלבים 1-4 נבנים ב-main.gd עצמו.
#  להוספת שלב: מוסיפים שורה (מספר שלב -> נתיב).
# ============================================================
const STAGES := {
	5: "res://levels/stage_5.gd",
	6: "res://levels/stage_6.gd",
	7: "res://levels/stage_7.gd",
	8: "res://levels/stage_8.gd",
	9: "res://levels/stage_9.gd",
	10: "res://levels/stage_10.gd",   # אזור צפון-מזרח, שלב 1
}


static func make(level: int) -> Node:
	if not STAGES.has(level) or not ResourceLoader.exists(STAGES[level]):
		return null
	return load(STAGES[level]).new()
