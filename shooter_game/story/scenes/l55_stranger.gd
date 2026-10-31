extends RefCounted
# ============================================================
#  שלב 55 ("WIND STEPPE", פטגוניה שלב 1) - החבר (STRANGER) בפעם הרביעית, בערבה בסערה.
#  כאן המשחק אומר בקול *למה* הם לומדים: כל זומבי שמת נושף ענן נבגים עם מה שראה, והאחרים נושמים אותו.
#  "You're the best teacher they ever had" - כל הריגה מלמדת אותם. ה-ARCHITECT מת (54) וזה לא עצר אותם.
#  (ספר הסיפור: /mnt/project-files/story/THEY_LEARN_story.md, ECHO / הנבגים / Glacier Lab)
#  פעולות gust / flock_scatter -> stage_55.on_story_beat (משב רוח, הכבשים מתפזרות).
#  קולות: sounds/story/l55_stranger/ (P = am_onyx, Z = bm_lewis) - devtools/story_voices.py l55_stranger
# ============================================================

const SCENE := {
	"id": "l55_stranger",
	"level": 55,
	"x": 4500.0,
	"actor": "STRANGER",
	"spot": 560.0,
	"dist": 300.0,
	"voices": "res://sounds/story/l55_stranger/",
	"names": {"P": "YOU", "Z": "THE STRANGER"},
	"ending": "leap",
	"beats": [
		["Z", "z01", "Their shepherd is dead. Did you think that would stop them?", "two", "gust", 0.25],
		["P", "p01", "It stopped them at the bridge.", "cu_p", "", 0.2],
		["Z", "z02", "For an hour. Then they remembered.", "cu_z", "tilt", 0.2],
		["P", "p02", "Remembered what?", "cu_p", "", 0.2],
		["Z", "z03", "Every one you kill... breathes out what it saw.", "cu_z2", "", 0.3],
		["Z", "z04", "The others breathe it in. That's how they learn.", "xcu_z", "", 0.4],
		["P", "p03", "So every kill makes them smarter.", "cu_p", "lower", 0.3],
		["Z", "z05", "You're the best teacher they ever had.", "cu_z", "grin", 0.4],
		["P", "p04", "Then I'll end the lesson.", "cu_p", "aim", 0.2],
		["Z", "z06", "South. The glacier. Where it began.", "two", "flock_scatter", 0.4],
	],
}
