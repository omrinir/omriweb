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
	20: "res://levels/stage_20.gd",   # אזור שלישי, שלב 2 (ג'ונגל צפוף)
	21: "res://levels/stage_21.gd",   # אזור שלישי, שלב 3 (צוקים)
	22: "res://levels/stage_22.gd",   # אזור שלישי, שלב 4 (הסכר)
	23: "res://levels/stage_23.gd",   # אזור שלישי, שלב 5 (כביש מהיר)
	24: "res://levels/stage_24.gd",   # אזור שלישי, שלב 6 (שדות בוערים)
	25: "res://levels/stage_25.gd",   # אזור שלישי, שלב 7 (תורן רדיו)
	26: "res://levels/stage_26.gd",   # אזור שלישי, שלב 8 (הבונקר)
	27: "res://levels/stage_27.gd",   # אזור שלישי, שלב 9 (שער הרמה - סוף האזור)
	28: "res://levels/stage_28.gd",   # אזור רביעי (האנדים), שלב 1 (מעבר העננים)
	29: "res://levels/stage_29.gd",   # אזור רביעי, שלב 2 (מכרה ההדים)
	30: "res://levels/stage_30.gd",   # אזור רביעי, שלב 3 (הכפר הקפוא)
	31: "res://levels/stage_31.gd",   # אזור רביעי, שלב 4 (איי הקנים - טיטיקקה)
	32: "res://levels/stage_32.gd",   # אזור רביעי, שלב 5 (קרנבל השדים - אורורו)
	33: "res://levels/stage_33.gd",   # אזור רביעי, שלב 6 (מכתש הגופרית)
	34: "res://levels/stage_34.gd",   # אזור רביעי, שלב 7 (המצפה - אטקמה)
	35: "res://levels/stage_35.gd",   # אזור רביעי, שלב 8 (קרחון הגולגולת)
	36: "res://levels/stage_36.gd",   # אזור רביעי, שלב 9 (הפסגה - סוף האנדים)
	37: "res://levels/stage_37.gd",   # אזור חמישי, שלב 1 (פאבלה בריו)
	38: "res://levels/stage_38.gd",   # אזור חמישי, שלב 2 (סאו פאולו)
	39: "res://levels/stage_39.gd",   # אזור חמישי, שלב 3 (המרקנה)
	40: "res://levels/stage_40.gd",   # אזור חמישי, שלב 4 (נמל סנטוס - אימפריית המתים)
	41: "res://levels/stage_41.gd",   # אזור חמישי, שלב 5 (המצעד בברזיליה)
	42: "res://levels/stage_42.gd",   # אזור חמישי, שלב 6 (המטרו של ברזיליה - קסרקטין)
	43: "res://levels/stage_43.gd",   # אזור חמישי, שלב 7 (מפעל המלחמה - וולטה רדונדה)
	44: "res://levels/stage_44.gd",   # אזור חמישי, שלב 8 (סכר איטאיפו)
}


static func make(level: int) -> Node:
	if not STAGES.has(level) or not ResourceLoader.exists(STAGES[level]):
		return null
	return load(STAGES[level]).new()
