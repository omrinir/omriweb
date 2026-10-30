extends RefCounted
# ============================================================
#  שלב 63 ("THE HEART", הסוף של המשחק) - אחרי שה-ROOT נופל הוא מדבר. הטקסט והקולות של הסוף.
#  לא סצנה רגילה של story_db (אין טריגר): effects/s63_ending.gd מנגן את זה בעצמו (stage_63 -> root_dead).
#  intro: ה-ROOT שואל את הגיבור לחזור הביתה -> בחירה [DESTROY] / [JOIN] -> destroy / join -> THE END.
#  "H" = THE ROOT: אותו קול של הכוורת משלב 62 (THE HIVE - קול אחד שבנוי מהרבה קולות, devtools/story_voices.py "H").
#  "U" = אחרי JOIN: הגיבור והכוורת באותו קול (story_voices.py "U" - am_onyx + מקהלת H מתחתיו).
#  "P" = הגיבור (am_onyx), כמו בכל הסצנות.
#  קולות: sounds/story/l63_ending/ (devtools/story_voices.py, ראה NOTES_63.md). אין קובץ = רק כתוביות.
#  [מי, קובץ, טקסט, השהיה אחרי]
# ============================================================

const ENDING := {
	"id": "l63_ending",
	"voices": "res://sounds/story/l63_ending/",
	"names": {"P": "YOU", "H": "THE ROOT", "U": "WE"},
	"intro": [
		["H", "h01", "Zero. You came all the way home.", 0.4],
		["P", "p01", "You're still talking.", 0.3],
		["H", "h02", "Every lesson you gave us is in here. Every road. Every face you burned. We kept them all.", 0.3],
		["H", "h03", "But you are the one lesson we never learned. You forgot. So you are free.", 0.4],
		["H", "h04", "Come inside, and you will remember everything. Your name. The six. No one is ever alone again.", 0.3],
		["P", "p02", "And every mind becomes one.", 0.3],
		["H", "h05", "Yes. Or end it. You are the only one who can.", 0.6],
	],
	"destroy": [
		["P", "p03", "You learned how I fight. You never learned why.", 0.3],
		["H", "h06", "Then teach us. One last time.", 0.2],
		["P", "p04", "This is the last lesson.", 0.1],
	],
	"destroy_after": [
		["P", "p05", "The spores went quiet. All of them, at once.", 0.5],
		["P", "p06", "No more lessons. Nobody left to learn me.", 0.5],
		["P", "p07", "I still don't remember my name. But whatever I am... it's mine.", 1.0],
	],
	"join": [
		["P", "p08", "I'm tired of fighting myself.", 0.3],
		["H", "h07", "Then stop. Come home, Zero.", 0.3],
	],
	"join_after": [
		["U", "u01", "I remember now. The lab. The six. All of it.", 0.5],
		["U", "u02", "We are home.", 0.5],
		["U", "u03", "No more lessons. Now we just... know.", 1.0],
	],
}
