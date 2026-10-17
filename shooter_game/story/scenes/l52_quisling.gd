extends RefCounted
# ============================================================
#  שלב 52 ("RAIL YARD") - בוגד חי (QUISLING - enemies/types/quisling.gd) מסתתר בין המתים עם מסכה של עור מת.
#  הוא מוריד את המסכה, מתחנן שלא יירו בו, ומגלה את התוכנית: כל המתים נוסעים דרומה,
#  ומישהו חושב בשבילם - THE ARCHITECT (הבוס של שלב 54). "והוא יודע איך קוראים לך".
#  השראה: הקוויזלינגים של World War Z ו-Whisperers מהקומיקס The Walking Dead.
#  קולות: sounds/story/l52_quisling/ (P = השחקן am_onyx, Z = הבוגד am_michael + לחישה + רעד) - ראו devtools/story_voices.py
#  פעולה "mask_off" = מוריד את המסכה (quisling.gd -> mask_off).
# ============================================================

const SCENE := {
	"id": "l52_quisling",
	"level": 52,
	"x": 1300.0,
	"actor": "QUISLING",
	"spot": 560.0,
	"dist": 280.0,
	"voices": "res://sounds/story/l52_quisling/",
	"names": {"P": "YOU", "Z": ""},
	"ending": "vanish",
	"beats": [
		["Z", "z01", "Don't shoot. Please. I'm alive.", "two", "mask_off", 0.3],
		["P", "p01", "You're wearing a dead man's face.", "cu_p", "", 0.2],
		["Z", "z02", "They don't eat their own. So I became one of them.", "cu_z", "tilt", 0.2],
		["P", "p02", "Where are they going?", "cu_p", "", 0.2],
		["Z", "z03", "South. Every train. Every road.", "cu_z2", "untilt", 0.3],
		["P", "p03", "The dead don't make plans.", "two", "", 0.2],
		["Z", "z04", "These ones do. Someone thinks for them now.", "cu_z2", "look_back", 0.3],
		["P", "p04", "Who?", "cu_p", "", 0.3],
		["Z", "z05", "The Architect. And he knows your name.", "xcu_z", "face", 0.6],
	],
}
