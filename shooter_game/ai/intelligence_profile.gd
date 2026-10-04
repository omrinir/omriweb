extends RefCounted
# ============================================================
#  INTELLIGENCE PROFILE - כמה הזומבים חכמים בכל שלב.
#  ****  כאן משנים את "האינטליגנציה" של הזומבים  ****
#
#  כל שורה = שלב. הערכים בין 0 ל-1 אלא אם כתוב אחרת:
#    aggression          - כמה הם לוחצים קדימה (מהירות התקפה, פחות המתנה)
#    awareness           - כמה טוב הם רואים/שומעים (טווח זיהוי, התחמקות מרימונים ומלכודות)
#    reaction_time       - שניות בין "החלטות" (קטן = מגיבים מהר יותר). לא יורד מתחת ל-0.25 (הוגנות)
#    accuracy            - דיוק של זומבים יורים/יורקים
#    flank_probability   - הסיכוי שזומבי בלי "תור" להתקפה יאגף מהצד השני
#    retreat_probability - הסיכוי לסגת כשנפצעים
#    cover_usage         - כמה הם משתמשים במחסות
#    coordination_level  - עבודת צוות: תורות התקפה, התקפות משולבות, תקשורת
#    adaptation_level    - כמה הם מגיבים לסגנון של השחקן (ai/player_memory.gd)
#    memory_duration     - כמה שניות הם זוכרים איפה ראו אותך אחרון
#    attack_slots        - כמה זומבים מותר להם לתקוף ביחד (השאר מאגפים / מחכים / מתחבאים)
#    communication       - 0/1: זומבים מזעיקים חברים קרובים כשהם רואים אותך
#    use_heights         - כמה הם מטפסים/קופצים לקומות אחרות כדי להגיע אליך
#    hazard_awareness    - כמה הם נמנעים ממלכודות (אש, חומצה, חביות נפץ)
#    group_attack        - הסיכוי להתקפה משולבת מכמה כיוונים כשכמה מחכים יחד
#
#  שלב 1-2: זומבים בסיסיים
#  שלב 3-4: התנהגות קבוצתית פשוטה (תורות)
#  שלב 5:   תקשורת
#  שלב 6:   מחסות והתקפות מגבהים
#  שלב 7:   איגוף ושימוש בסביבה
#  שלב 8:   התאמה לנשק של השחקן
#  שלב 9:   תיאום מתקדם וזיהוי הרגלים של השחקן
# ============================================================

const STAGES := {
	1: {"aggression": 0.6, "awareness": 0.4, "reaction_time": 0.6, "accuracy": 0.3, "flank_probability": 0.0, "retreat_probability": 0.0,
		"cover_usage": 0.2, "coordination_level": 0.0, "adaptation_level": 0.0, "memory_duration": 2.0, "attack_slots": 99,
		"communication": 0, "use_heights": 0.0, "hazard_awareness": 0.0, "group_attack": 0.0},
	2: {"aggression": 0.65, "awareness": 0.5, "reaction_time": 0.55, "accuracy": 0.35, "flank_probability": 0.0, "retreat_probability": 0.05,
		"cover_usage": 0.3, "coordination_level": 0.0, "adaptation_level": 0.0, "memory_duration": 3.0, "attack_slots": 99,
		"communication": 0, "use_heights": 0.0, "hazard_awareness": 0.2, "group_attack": 0.0},
	3: {"aggression": 0.7, "awareness": 0.55, "reaction_time": 0.5, "accuracy": 0.4, "flank_probability": 0.15, "retreat_probability": 0.1,
		"cover_usage": 0.35, "coordination_level": 0.3, "adaptation_level": 0.0, "memory_duration": 4.0, "attack_slots": 4,
		"communication": 0, "use_heights": 0.0, "hazard_awareness": 0.3, "group_attack": 0.0},
	4: {"aggression": 0.75, "awareness": 0.6, "reaction_time": 0.45, "accuracy": 0.45, "flank_probability": 0.25, "retreat_probability": 0.15,
		"cover_usage": 0.4, "coordination_level": 0.4, "adaptation_level": 0.05, "memory_duration": 5.0, "attack_slots": 3,
		"communication": 0, "use_heights": 0.1, "hazard_awareness": 0.4, "group_attack": 0.3},
	5: {"aggression": 0.75, "awareness": 0.65, "reaction_time": 0.42, "accuracy": 0.5, "flank_probability": 0.3, "retreat_probability": 0.2,
		"cover_usage": 0.45, "coordination_level": 0.5, "adaptation_level": 0.1, "memory_duration": 6.0, "attack_slots": 3,
		"communication": 1, "use_heights": 0.3, "hazard_awareness": 0.5, "group_attack": 0.4},
	6: {"aggression": 0.8, "awareness": 0.7, "reaction_time": 0.4, "accuracy": 0.55, "flank_probability": 0.35, "retreat_probability": 0.25,
		"cover_usage": 0.65, "coordination_level": 0.55, "adaptation_level": 0.15, "memory_duration": 7.0, "attack_slots": 3,
		"communication": 1, "use_heights": 0.75, "hazard_awareness": 0.6, "group_attack": 0.5},
	7: {"aggression": 0.8, "awareness": 0.75, "reaction_time": 0.36, "accuracy": 0.6, "flank_probability": 0.55, "retreat_probability": 0.3,
		"cover_usage": 0.65, "coordination_level": 0.65, "adaptation_level": 0.25, "memory_duration": 8.0, "attack_slots": 3,
		"communication": 1, "use_heights": 0.75, "hazard_awareness": 0.75, "group_attack": 0.6},
	8: {"aggression": 0.85, "awareness": 0.8, "reaction_time": 0.33, "accuracy": 0.65, "flank_probability": 0.55, "retreat_probability": 0.35,
		"cover_usage": 0.7, "coordination_level": 0.7, "adaptation_level": 0.7, "memory_duration": 9.0, "attack_slots": 3,
		"communication": 1, "use_heights": 0.8, "hazard_awareness": 0.8, "group_attack": 0.7},
	9: {"aggression": 0.9, "awareness": 0.85, "reaction_time": 0.3, "accuracy": 0.7, "flank_probability": 0.6, "retreat_probability": 0.4,
		"cover_usage": 0.75, "coordination_level": 0.85, "adaptation_level": 0.9, "memory_duration": 10.0, "attack_slots": 3,
		"communication": 1, "use_heights": 0.85, "hazard_awareness": 0.9, "group_attack": 0.85},
}

# גבולות הוגנות: גם הזומבי הכי חכם לא "מרמה"
const MIN_REACTION := 0.25
const MAX_SLOTS := 3            # מעל שלב 3: לא יותר מ-3 תוקפים בבת אחת (+1 ברגע פגיע של השחקן)


# הפרופיל של שלב מסוים, מותאם לרמת הקושי (Settings -> smart: קל 0.5, רגיל 1, קשה 1.5)
static func for_level(level: int, smart := 1.0) -> Dictionary:
	var lv := clampi(level, 1, 9)
	var p: Dictionary = STAGES[lv].duplicate()
	if level > 9:   # שלבים מעבר ל-9 (אזורים הבאים במפה): כמו 9
		p = STAGES[9].duplicate()
	var k := clampf(0.75 + 0.25 * smart, 0.8, 1.15)   # הקושי משנה קצת - לא הופך אותם לגאונים
	for f in ["coordination_level", "adaptation_level", "flank_probability", "cover_usage", "awareness", "group_attack"]:
		p[f] = clampf(float(p[f]) * k, 0.0, 1.0)
	p.reaction_time = maxf(float(p.reaction_time) / k, MIN_REACTION)
	if smart < 0.8 and int(p.attack_slots) < 99:   # קל: עוד מקום אחד לתוקפים פחות מאורגנים
		p.attack_slots = int(p.attack_slots) + 1
	return p


# תוספות לפי סוג זומבי (אפשר גם מתוך enemies/types/*.gd -> brain_overrides)
# ערך מספרי = מוסיפים לבסיס. ערך bool/מחרוזת = מחליפים.
const KIND_OVERRIDES := {
	1: {"aggression": 0.15, "hit_and_run": 0.45, "flank_probability": 0.1},     # RUNNER: מתקיף, נסוג, חוזר
	2: {"aggression": -0.1, "charge": true, "protect": true, "flank_probability": -0.3},   # BRUTE: מגן על הקטנים ומסתער
	9: {"cover_usage": 0.2},                                                      # COP
	14: {"aggression": 0.2},                                                      # IMP
}
