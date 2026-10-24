extends RefCounted
# ============================================================
#  שלב 60 ("GLACIER LAB", פטגוניה שלב 6) - SUBJECT ZERO: במסוף של ארכיון פרויקט ECHO הגיבור מוצא את התיק של עצמו.
#  הקול של המסוף (T - "ECHO FILE", קול מוקלט מונוטוני) מקריא: דפוס מקורי, LETHE, "Do not let him go home."
#  ואז הכוורת עונה ברמקולים של המעבדה (C - THE CHORUS, אותם קולות כמו שלב 57): "Welcome home."
#  הדמות: SPECIMEN קפוא במיכל ההקפאה ליד המסוף (actor_props tank_actor) - פוקח עיניים ירוקות ב-"welcome".
#  פעולות file_open / welcome -> stage_60.on_story_beat (התיק על המסך, הפטרייה בולעת את המסך, המיכל נסדק).
#  ה-ROOT והסוף נשמרים לשלבים 61-63.
#  קולות: sounds/story/l60_file/ (P = am_onyx, T = af_sarah מונוטוני + מסנן רמקול, C = מקהלת Kokoro) - devtools/story_voices.py
# ============================================================

const SCENE := {
	"id": "l60_file",
	"level": 60,
	"x": 6000.0,
	"actor": "SPECIMEN",
	"actor_props": {"tank_actor": true},
	"spot": 560.0,
	"dist": 160.0,
	"voices": "res://sounds/story/l60_file/",
	"names": {"P": "YOU", "T": "ECHO FILE", "C": "THE CHORUS"},
	"ending": "vanish",
	"beats": [
		["P", "p01", "Project Echo... This file has my face on it.", "wide", "file_open", 0.3],
		["T", "t01", "Subject Zero. Pattern: original, unmutated.", "wide", "", 0.2],
		["T", "t02", "Status: LETHE administered.", "wide", "", 0.3],
		["T", "t03", "If the network reclaims him, every mind becomes one. Do not let him go home.", "cu_p", "", 0.5],
		["P", "p02", "Home...? This is where I came from.", "cu_p", "lower", 0.6],
		["C", "c01", "Welcome home.", "xcu_z", "welcome", 0.9],
	],
}
