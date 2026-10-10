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
	11: "res://levels/stage_11.gd",   # אזור צפון-מזרח, שלב 2
	12: "res://levels/stage_12.gd",   # אזור צפון-מזרח, שלב 3
	13: "res://levels/stage_13.gd",   # אזור צפון-מזרח, שלב 4
	14: "res://levels/stage_14.gd",   # אזור צפון-מזרח, שלב 5
	15: "res://levels/stage_15.gd",   # אזור צפון-מזרח, שלב 6
	16: "res://levels/stage_16.gd",   # אזור צפון-מזרח, שלב 7
	17: "res://levels/stage_17.gd",   # אזור צפון-מזרח, שלב 8
	18: "res://levels/stage_18.gd",   # אזור צפון-מזרח, שלב 9 (סוף האזור)
	19: "res://levels/stage_19.gd",   # אזור שלישי, שלב 1 (ג'ונגל)
}


static func make(level: int) -> Node:
	if not STAGES.has(level) or not ResourceLoader.exists(STAGES[level]):
		return null
	return load(STAGES[level]).new()
