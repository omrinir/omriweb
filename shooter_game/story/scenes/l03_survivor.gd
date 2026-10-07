extends RefCounted
# ============================================================
#  שלב 3 (מפעל) - "החיים שלה": ניצולה עומדת ומחכה. היא מבינה שהוא לא בא להציל אותה,
#  שואלת למה החיים שלה שווים פחות משלו - והוא שואב ממנה את כוח החיים עם המכשיר. היא צורחת.
#  מצלמה קצת רחוקה (zoom 0.75) כדי שהשאיבה בסוף תיראה במלואה.
#  קולות: sounds/story/l03_survivor/ (P = השחקן, S = הניצולה) - Kokoro TTS + עיבוד ffmpeg.
#  ending "drain" = השחקן שואב אותה (כמו במשחק: חיים מלאים), היא נשארת שרופה בשלב.
#  (המבנה של beats - ראה l01_stranger.gd)
# ============================================================

const SCENE := {
	"id": "l03_survivor",
	"level": 3,
	"x": 1050.0,
	"actor": "SURVIVOR",
	"variant": 0,
	"spot": 560.0,
	"dist": 78.0,
	"zoom": 0.75,
	"voices": "res://sounds/story/l03_survivor/",
	"names": {"P": "YOU", "S": ""},
	"ending": "drain",
	"beats": [
		["S", "s01", "You're not here to save me... are you?", "two", "", 0.5],
		["P", "p01", "No.", "cu_p", "", 0.7],
		["S", "s02", "Why? Why is my life worth less than yours?", "cu_z", "", 0.5],
		["P", "p02", "It isn't. I know it's not fair.", "cu_p", "", 0.3],
		["P", "p03", "But I have to finish the job.", "two", "", 0.2],
		["P", "p04", "And you'll help me do it... whether you want to or not.", "cu_p", "", 0.2],
	],
}
