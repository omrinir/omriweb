extends RefCounted
# ============================================================
#  שלב 54 ("LAST BRIDGE", סוף האזור) - החבר (STRANGER) חוזר בפעם השלישית, על הגשר, לפני THE ARCHITECT.
#  "אין צדדים, רק התוכנית" - והרמז הגדול: השחקן הוא "היחיד מאיתנו ששכח" (המשך ל"Good. Then it worked." משלב 1
#  ולשחקן בלי צל משלב 17). השראה: I Am Legend - הגיבור הוא המפלצת בסיפורים של הצד השני.
#  פעולות wind / herd_roar / lamps_out -> stage_54.on_story_beat (רוח, העדר בנהר שואג, הפנסים כבים).
#  קולות: sounds/story/l54_stranger/ (P = am_onyx, Z = bm_lewis מונמך + הד מתכתי) - ראו devtools/story_voices.py
# ============================================================

const SCENE := {
	"id": "l54_stranger",
	"level": 54,
	"x": 8250.0,
	"actor": "STRANGER",
	"spot": 560.0,
	"dist": 300.0,
	"voices": "res://sounds/story/l54_stranger/",
	"names": {"P": "YOU", "Z": "THE STRANGER"},
	"ending": "leap",
	"beats": [
		["Z", "z01", "You came to burn the bridge.", "two", "wind", 0.25],
		["P", "p01", "You again. Whose side are you on?", "cu_p", "", 0.2],
		["Z", "z02", "There are no sides. Only the plan.", "cu_z", "tilt", 0.2],
		["P", "p02", "Then I'll kill the one who made it.", "cu_p", "aim", 0.2],
		["Z", "z03", "He's waiting for you. He always was.", "cu_z2", "herd_roar", 0.4],
		["P", "p03", "Why me?", "cu_p", "lower", 0.3],
		["Z", "z04", "Because you're the only one of us... who forgot.", "xcu_z", "grin", 0.6],
		["P", "p04", "...Of us?", "two", "", 0.4],
		["Z", "z05", "Cross the bridge. Remember.", "two", "lamps_out", 0.4],
	],
}
