extends RefCounted
# ============================================================
#  LEVEL EVENTS - סוגי שלבים חדשים (2026-10-20), כדי שלא כל שלב ייראה אותו דבר
#  (8 מסכים -> נקודת ביקורת באמצע -> בוס בסוף). כל אירוע = קובץ ב-levels/events/:
#    hold   - HOLD THE LINE: נסגרים במקום אחד ושורדים גלים עד שהשעון נגמר.
#    escape - ESCAPE: עדר רודף מאחור, חייבים להמשיך לזוז.
#    escort - RESCUE: מלווים ניצול חי עד היציאה (בונוס אם הוא שורד).
#  MID_BOSS = הבוס מחכה באמצע השלב (ולא בסוף). כשהוא מת השער נפתח, והשלב ממשיך עד היציאה.
#  main.gd יוצר את האירוע אחרי שהשלב נבנה (make) ושואל את mid_boss() כשהוא שם את הבוס.
#  ממשק אירוע: extends Node, משתנים main / floor_y / hud_layer, ו-start() נקרא אחרי add_child.
# ============================================================

const FILES := {
	"hold": "res://levels/events/hold.gd",
	"escape": "res://levels/events/escape.gd",
	"escort": "res://levels/events/escort.gd",
}

# שלב -> סוג (בערך 2 לכל אזור, לא בשלבים מיוחדים: 1-4 לימוד, 16 נחילים, 32 תזמורת, 63 הסוף)
const TYPES := {
	6: "hold", 21: "hold", 30: "hold", 48: "hold", 57: "hold",
	11: "escape", 23: "escape", 41: "escape", 55: "escape",
	13: "escort", 34: "escort", 44: "escort", 52: "escort",
}

const MID_BOSS := [10, 19, 40]
const MID_BOSS_AT := 0.62   # איפה הבוס עומד (חלק מאורך השלב). נקודת הביקורת ב-0.5


static func type_of(level: int) -> String:
	return str(TYPES.get(level, ""))


static func make(level: int) -> Node:
	var t := type_of(level)
	if t == "" or not FILES.has(t) or not ResourceLoader.exists(FILES[t]):
		return null
	return load(FILES[t]).new()


static func mid_boss(level: int) -> bool:
	return level in MID_BOSS
