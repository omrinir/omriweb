extends RefCounted
# ============================================================
#  שלב 57 ("PENGUIN COAST", פטגוניה שלב 3) - THE CHORUS: בפעם הראשונה הכוורת מדברת.
#  להקת ציפורים נגועה (MURMUR) נוצרת בצורת פנים מעל הים ומדברת בהרבה קולות בבת אחת.
#  הגילוי: הם לא צדים את השחקן כדי לאכול אותו - הוא היה "הקול הראשון" (Subject Zero) והם רוצים שיחזור.
#  השחקן מדבר עם WADDLER אחד שעומד בתוך המושבה (הגוף שהקול יוצא ממנו), והלהקה בשמיים היא הפנים.
#  פעולות flock_form / flock_break / penguins_flee -> stage_57.on_story_beat.
#  קולות: sounds/story/l57_chorus/ (P = am_onyx, C = 5 קולות Kokoro בשכבות - devtools/story_voices.py CHORUS)
# ============================================================

const SCENE := {
	"id": "l57_chorus",
	"level": 57,
	"x": 6240.0,
	"actor": "WADDLER",
	"spot": 560.0,
	"dist": 320.0,
	"voices": "res://sounds/story/l57_chorus/",
	"names": {"P": "YOU", "C": "THE CHORUS"},
	"ending": "vanish",
	"beats": [
		["C", "c01", "We... remember... you.", "two", "flock_form", 0.5],
		["P", "p01", "Who's talking?", "cu_p", "aim", 0.2],
		["C", "c02", "All of us. Every one you killed. We kept them.", "cu_z", "", 0.4],
		["P", "p02", "You're a flock of birds.", "cu_p", "", 0.2],
		["C", "c03", "Bodies break. So we learned to be many.", "two", "", 0.4],
		["P", "p03", "What do you want from me?", "cu_p", "lower", 0.3],
		["C", "c04", "You were the first voice. Subject Zero.", "cu_z2", "", 0.5],
		["C", "c05", "We don't want to eat you. We want you to come home.", "xcu_z", "", 0.6],
		["P", "p04", "I'm not one of you.", "cu_p", "aim", 0.3],
		["C", "c06", "You will remember.", "two", "flock_break", 0.5],
	],
}
