extends RefCounted
# ============================================================
#  שלב 1 - "החבר": זומבי שמדבר (STRANGER - enemies/types/stranger.gd) מחכה ברחוב, קצת אחרי ההתחלה.
#  השיחה מתחילה בעקיצות ונגמרת בתעלומה: הוא מכיר את השחקן, השחקן לא זוכר, ו"משהו עבד".
#  קולות: sounds/story/l01_stranger/ (P = השחקן, Z = הזומבי) - Kokoro TTS + עיבוד ffmpeg.
#
#  beats: [מי, קובץ קול, טקסט, שוט, פעולה, הפסקה אחרי]
#    הנשק של השחקן למטה כל הסצנה (LOW_READY ב-story_scene.gd).
#    שוטים: two (שניהם) / cu_p / cu_z / cu_z2 (תקריבים) / behind (מאחורי השחקן) / xcu_z (סיום, זחילה פנימה)
#    פעולות: aim / lower (נשק השחקן) / tilt / untilt / grin / smile / look_back / face / turn_back
#  x = איפה הדמות עומדת בשלב. spot = מאיזה מרחק השחקן "רואה" אותה והסצנה מתחילה. dist = מרחק השיחה.
# ============================================================

const SCENE := {
	"id": "l01_stranger",
	"level": 1,
	"x": 1050.0,
	"actor": "STRANGER",
	"spot": 560.0,
	"dist": 300.0,
	"voices": "res://sounds/story/l01_stranger/",
	"names": {"P": "YOU", "Z": ""},   # "" = בלי שם (הדמות עדיין זרה)
	"ending": "leap",                 # leap = קופץ החוצה מהמסך / vanish = שחור + בום
	"beats": [
		["Z", "z01", "Hello, friend.", "two", "", 0.25],
		["P", "p01", "Friend? You're a fucking zombie.", "cu_p", "", 0.1],
		["Z", "z02", "Such an ugly word.", "cu_z", "tilt", 0.1],
		["P", "p02", "Give me one reason not to shoot.", "cu_p", "", 0.15],
		["Z", "z03", "I've been dead for weeks.", "cu_z2", "grin", 0.2],
		["P", "p03", "Then why talk?", "two", "", 0.2],
		["Z", "z04", "We've met before.", "cu_z2", "untilt", 0.5],
		["P", "p04", "...I don't remember.", "cu_p", "", 0.5],
		["Z", "z05", "Good. Then it worked.", "cu_z2", "grin", 0.3],
		["P", "p05", "What worked?", "cu_p", "", 0.2],
		["Z", "z06", "We'll talk again.", "two", "smile", 0.4],
	],
}
