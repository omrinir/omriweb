extends RefCounted
# ============================================================
#  שלב 59 ("BLACK FOREST", פטגוניה שלב 5) - הביקור האחרון של החבר (STRANGER), ביער השרוף, בעשן.
#  הווידוי: הוא זה שהזריק לגיבור את LETHE ולקח לו את הזיכרון - "היית הקול הראשון. אם היית חוזר הביתה, לא היה נשאר
#  אף אחד שהוא לא הם". הכוורת רוצה את הגיבור בבית, ו-Glacier Lab הוא המקום שבו הכול התחיל (שלב 60).
#  הוא לא יכול ללכת אחריו לשם: מוח מקושר (linked mind) - הכוורת תשמע כל מה שהוא יודע. הוא נעלם בעשן.
#  (ספר הסיפור: /mnt/project-files/story/THEY_LEARN_story.md, LETHE / Subject Zero / Glacier Lab)
#  פעולות smoke_in / embers / smoke_veil -> stage_59.on_story_beat (העשן מתגלגל, משב ניצוצות, ענן עשן על ה-STRANGER).
#  קולות: sounds/story/l59_stranger/ (P = am_onyx, Z = bm_lewis) - devtools/story_voices.py l59_stranger
# ============================================================

const SCENE := {
	"id": "l59_stranger",
	"level": 59,
	"x": 5450.0,
	"actor": "STRANGER",
	"spot": 560.0,
	"dist": 300.0,
	"voices": "res://sounds/story/l59_stranger/",
	"names": {"P": "YOU", "Z": "THE STRANGER"},
	"ending": "shimmer",
	"beats": [
		["Z", "z01", "This is my last visit. Where you're going, I can't follow.", "two", "smoke_in", 0.3],
		["P", "p01", "Then answer me. What did you do to me?", "cu_p", "aim", 0.2],
		["Z", "z02", "I did it. I took your memory. LETHE was mine.", "cu_z", "tilt", 0.4],
		["Z", "z03", "You were the first voice. If you went home... there would be no one left who isn't them.", "xcu_z", "", 0.5],
		["P", "p02", "Home. That's what they keep calling it.", "cu_p", "lower", 0.3],
		["Z", "z04", "The Glacier Lab. It started there. And it wants you back.", "cu_z2", "embers", 0.4],
		["Z", "z05", "A linked mind can't follow you. Goodbye, Zero.", "two", "smoke_veil", 0.6],
	],
}
