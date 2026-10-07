extends RefCounted
# ============================================================
#  שלב 17 ("THE DRY RIVER") - החבר חוזר. מלמד את כלל הצל של המיראז'ים ("רק לאמיתיים יש צל")...
#  והשחקן שם לב שלו עצמו אין צל (actor_props: no_shadow). בסוף הוא מתפוגג כמו מיראז' (ending "shimmer").
#  קולות: sounds/story/l17_stranger/ (P = השחקן, Z = הזומבי).  (המבנה של beats - ראה l01_stranger.gd)
# ============================================================

const SCENE := {
	"id": "l17_stranger",
	"level": 17,
	"x": 1100.0,
	"actor": "STRANGER",
	"actor_props": {"no_shadow": true},
	"spot": 560.0,
	"dist": 260.0,
	"voices": "res://sounds/story/l17_stranger/",
	"names": {"P": "YOU", "Z": ""},
	"ending": "shimmer",
	"beats": [
		["Z", "z01", "There you are.", "two", "", 0.25],
		["P", "p01", "You again.", "cu_p", "", 0.2],
		["Z", "z02", "Careful. Out here, the heat lies.", "cu_z", "tilt", 0.2],
		["P", "p02", "What's that supposed to mean?", "cu_p", "", 0.2],
		["Z", "z03", "Some of them aren't really there.", "cu_z2", "untilt", 0.3],
		["Z", "z04", "Watch the ground. The real ones cast a shadow.", "two", "", 0.9],
		["P", "p03", "...You don't have a shadow.", "two", "", 0.6],
		["Z", "z05", "Don't I?", "xcu_z", "smile", 0.5],
	],
}
