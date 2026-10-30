extends RefCounted
# ============================================================
#  שלב 62 ("THE HIVE MIND", פטגוניה שלב 8) - THE ONE VOICE: בחדר הקול האחד, מתחת לכלא של אושואיה, הכוורת מדברת
#  לגיבור בפעם הראשונה בקול אחד (לא מקהלה כמו בשלב 57) ומספרת לו למה: הם נוצרו כדי ללמוד אותו. כל מי שהוא הרג היה
#  שיעור, וכל שיעור חזר הביתה. הם לא שונאים אותו - הוא המורה שלהם. הם לא לומדים לנצח אותו - הם לומדים *להיות* הוא.
#  וה-ROOT עדיין צריך את המקור: "Come down to the heart. Finish the lesson."
#  הדמות: SEEPER שעומד בבריכת הזיכרון הגדולה (actor_props speaker) - הגוף שהקול יוצא ממנו. הפנים בקיר המוח מעליו.
#  פעולות speak / replay / mirror / melt -> stage_62.on_story_beat (הקירות פועמים, הבריכות מבזיקות את הקרבות שלך,
#  הפנים נהיים הפנים שלך, הדובר נמס לבריכה).
#  קולות: sounds/story/l62_hive/ (P = am_onyx, H = "ONE VOICE": bm_lewis + שכבות על אותו גובה צליל - devtools/story_voices.py)
# ============================================================

const SCENE := {
	"id": "l62_hive",
	"level": 62,
	"x": 5300.0,
	"actor": "SEEPER",
	"actor_props": {"speaker": true},
	"spot": 560.0,
	"dist": 250.0,
	"voices": "res://sounds/story/l62_hive/",
	"names": {"P": "YOU", "H": "THE HIVE"},
	"ending": "vanish",
	"beats": [
		["H", "h01", "Zero. You came down to us.", "wide", "speak", 0.4],
		["P", "p01", "Who's there? Show yourself.", "cu_p", "aim", 0.2],
		["H", "h02", "There is no one here. There is only us. One voice, now.", "cu_z", "speak", 0.4],
		["P", "p02", "Then talk. Why me? Why all of this?", "two", "lower", 0.3],
		["H", "h03", "We were made to learn you.", "xcu_z", "speak", 0.5],
		["H", "h04", "Every one you killed was a lesson. Every lesson came home.", "wide", "replay", 0.5],
		["P", "p03", "So I taught you how to kill me.", "cu_p", "", 0.4],
		["H", "h05", "We do not hate you. You are our teacher.", "cu_z", "speak", 0.5],
		["H", "h06", "We are not learning to beat you, Zero. We are learning to be you.", "cu_z2", "mirror", 0.6],
		["P", "p04", "Seven soldiers. One man's pattern. That was the project.", "cu_p", "", 0.4],
		["H", "h07", "And the root still needs the first. Come down to the heart. Finish the lesson.", "two", "melt", 0.6],
		["P", "p05", "I'll finish it. My way.", "cu_p", "aim", 0.5],
	],
}
