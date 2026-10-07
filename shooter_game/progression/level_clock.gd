extends RefCounted
# ============================================================
#  THEY LEARN CLOCK - שעון השלב (מוצג למעלה באמצע, hud.gd).
#  למה הוא חשוב: כל שנייה בשלב היא שנייה שהזומבים לומדים אותך.
#   * GOLD / SILVER = זמני יעד לשלב (לפי אורך השלב, מספר השלב והקושי).
#   * עברת את SILVER -> "THEY'RE LEARNING YOU": כל LEARN_STEP שניות עוד דרגה (עד MAX_TIER).
#     כל דרגה: הזומבים משתמשים יותר במה שלמדו עליך (adaptation), מתואמים יותר, מגיבים מהר יותר,
#     ו-PlayerMemory לומד אותך מהר יותר. בלי עוד חיים ובלי עוד זומבים - רק יותר חכמים.
#  מה מקבלים על זמן טוב (Game.finish_level):
#   * GOLD: בונוס ניקוד לכל שנייה שנשארה, +50% גרוטאות, ו-"THEY FORGET": בשלב הבא הם זוכרים
#     הרבה פחות ממה שלמדו עליך (PlayerMemory נשכח 70% במקום 35%). + גביע GHOST.
#   * SILVER: בונוס ניקוד קטן יותר ו-+25% גרוטאות.
#  השעון עוצר בסצנות סיפור ובהשהיה, וממשיך מנקודת הביקורת (נשמר בה).
#  לשנות: PACE (מהירות "טובה" בפיקסלים לשנייה), BOSS_TIME, SILVER_MULT, LEARN_STEP, DIFF_MULT.
# ============================================================

const PACE := 95.0            # GOLD: מהירות התקדמות ממוצעת (כולל קרבות) בשלב 1
const PACE_DROP := 2.0        # כל שלב (עד 10) קצת יותר צפוף -> קצת יותר זמן
const BOSS_TIME := 35.0       # זמן לבוס בסוף השלב
const SILVER_MULT := 1.45
const DIFF_MULT := [1.3, 1.0, 0.9]   # קל / רגיל / קשה
const LEARN_STEP := 30.0      # אחרי SILVER: כל כמה שניות עוד דרגת למידה
const MAX_TIER := 3
const GOLD_POINTS := 20       # ניקוד לכל שנייה שנשארה עד GOLD
const SILVER_POINTS := 8      # ניקוד לכל שנייה שנשארה עד SILVER
const GOLD_SCRAP := 0.5       # כמה מהגרוטאות של השלב נוספות
const SILVER_SCRAP := 0.25
const TIER_WORDS := ["", "THEY'RE LEARNING YOU", "THEY'RE LEARNING FASTER", "THEY KNOW YOU NOW"]

enum { NONE, SILVER, GOLD }


# [gold, silver] בשניות
static func pars(level: int, level_w: float, difficulty: int) -> Vector2:
	var pace := PACE - PACE_DROP * float(clampi(level, 1, 10) - 1)
	var gold := (level_w / pace + BOSS_TIME) * float(DIFF_MULT[clampi(difficulty, 0, 2)])
	gold = roundf(gold / 5.0) * 5.0   # מספר עגול
	return Vector2(gold, roundf(gold * SILVER_MULT / 5.0) * 5.0)


static func medal(t: float, p: Vector2) -> int:
	if p.x <= 0.0:
		return NONE
	return GOLD if t <= p.x else (SILVER if t <= p.y else NONE)


# דרגת הלמידה (0 = עוד לא, 1..MAX_TIER)
static func tier(t: float, p: Vector2) -> int:
	if p.y <= 0.0 or t <= p.y:
		return 0
	return mini(1 + int((t - p.y) / LEARN_STEP), MAX_TIER)


static func fmt(t: float) -> String:
	var s := maxi(int(t), 0)
	return "%d:%02d" % [s / 60, s % 60]
