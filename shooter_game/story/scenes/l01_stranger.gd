extends RefCounted
# ============================================================
#  שלב 1 - "החבר": זומבי שמדבר (STRANGER - enemies/types/stranger.gd) מחכה ברחוב, קצת אחרי ההתחלה.
#  השיחה מתחילה בעקיצות ונגמרת בתעלומה: הוא מכיר את השחקן, השחקן לא זוכר, ו"משהו עבד".
#  קולות: sounds/story/l01_stranger/ (P = השחקן, Z = הזומבי) - Kokoro TTS + עיבוד ffmpeg.
#
#  beats: [מי, קובץ קול, טקסט, שוט, פעולה, הפסקה אחרי]
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
	"names": {"P": "YOU", "Z": "???"},
	"ending": "vanish",
	"beats": [
		["Z", "z01", "Ahh. There you are. Hello, friend.", "two", "", 0.3],
		["P", "p01", "Friend? You're a fucking zombie.", "cu_p", "", 0.1],
		["Z", "z02", "Zombie. Such an ugly word.", "cu_z", "tilt", 0.1],
		["P", "p02", "Ugly fits you. Give me one reason not to shoot.", "cu_p", "aim", 0.15],
		["Z", "z03", "Shoot me? I've been dead for weeks. It didn't take.", "cu_z2", "grin", 0.3],
		["P", "p03", "Then why talk, instead of bite?", "two", "", 0.2],
		["Z", "z04", "Because we've met before. You don't remember... do you?", "cu_z2", "tilt", 0.5],
		["P", "p04", "Should I?", "cu_p", "lower", 0.6],
		["Z", "z05", "Hm. Then it worked.", "cu_z2", "grin", 0.4],
		["P", "p05", "What worked? Hey... what worked?!", "cu_p", "aim", 0.2],
		["Z", "z06", "Keep walking, friend. The answers are further down the road.", "two", "untilt", 0.3],
		["Z", "z07", "We'll talk again.", "xcu_z", "smile", 0.7],
	],
}
