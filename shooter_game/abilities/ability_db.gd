extends RefCounted
# ============================================================
#  ABILITY DB - כל היכולות של הדמות (מוכן ל-24+ יכולות).
#
#  איך מוסיפים יכולת חדשה:
#    1. מוסיפים מילון ל-ABILITIES (id ייחודי).
#    2. יוצרים abilities/types/<id>.gd שמתחיל ב- extends "res://abilities/ability_base.gd"
#       ומממש activate() (או passive = true ו-on_lethal_hit / process).
#    3. אייקון: מוסיפים מקרה ב-draw_icon() לפי "icon".
#  החנות (ui/upgrade_shop.gd) והגלגל (weapon_wheel.gd) מציגים אותה אוטומטית,
#  והיא מקבלת מסלולי שדרוג POWER / COOLDOWN (progression/upgrade_db.gd).
#
#  שדות:
#    name, color, desc     - בממשק
#    cooldown              - שניות עד שאפשר שוב (לפני שדרוג)
#    duration              - כמה זמן האפקט נמשך (אם יש)
#    unlock_level          - מאיזה שלב היכולת נפתחת (חינם, נכנסת אוטומטית למקום פנוי)
#    passive               - true = עובדת לבד (לא צריך ללחוץ)
#    icon                  - איזה ציור (draw_icon)
# ============================================================

const ABILITIES := [
	{"id": "blood_hook", "name": "BLOOD HOOK", "color": Color("d83a3a"), "cooldown": 7.0, "unlock_level": 3, "icon": "hook",
		"desc": "Rip one zombie out of cover and drag it to you."},
	{"id": "last_breath", "name": "LAST BREATH", "color": Color("e8e0c8"), "cooldown": 0.0, "unlock_level": 4, "icon": "heart", "passive": true,
		"desc": "Once per stage: a killing blow leaves you at 1 heart, briefly untouchable."},
	{"id": "phantom_step", "name": "PHANTOM STEP", "color": Color("8a7aff"), "cooldown": 6.0, "unlock_level": 5, "icon": "blink",
		"desc": "Blink through zombies toward your aim. Nearby zombies lose track of you."},
	{"id": "dark_pulse", "name": "DARK PULSE", "color": Color("b050ff"), "cooldown": 10.0, "unlock_level": 6, "icon": "pulse",
		"desc": "Shockwave: knocks back and staggers everything around you, breaks grabs."},
	{"id": "hunters_sight", "name": "HUNTER'S SIGHT", "color": Color("ff4a3a"), "cooldown": 12.0, "duration": 4.0, "unlock_level": 7, "icon": "eye",
		"desc": "See every zombie through walls, darkness and cover."},
	{"id": "decoy", "name": "DECOY ECHO", "color": Color("4ad0ff"), "cooldown": 15.0, "duration": 5.0, "unlock_level": 8, "icon": "decoy",
		"desc": "A ghost copy draws their attacks, flanks and orders. Smart ones may see through it."},
	{"id": "silence", "name": "SILENCE", "color": Color("9ad0c0"), "cooldown": 20.0, "duration": 6.0, "unlock_level": 9, "icon": "silence",
		"desc": "Around you zombies can't call each other or receive orders."},
]


static func count() -> int:
	return ABILITIES.size()


static func get_def(id: String) -> Dictionary:
	for a in ABILITIES:
		if a.id == id:
			return a
	return {}


static func val(id: String, field: String, default: Variant = null) -> Variant:
	return get_def(id).get(field, default)


static func script_path(id: String) -> String:
	return "res://abilities/types/%s.gd" % id


# היכולות שנפתחו עד שלב מסוים
static func unlocked(level: int) -> Array:
	var out := []
	for a in ABILITIES:
		if int(a.unlock_level) <= level:
			out.append(a.id)
	return out


# ---- אייקונים (מצוירים בקוד). c = מרכז, s = גודל (~1 = 24 פיקסלים) ----
static func draw_icon(ci: CanvasItem, c: Vector2, id: String, s: float, alpha := 1.0) -> void:
	var col: Color = val(id, "color", Color.WHITE)
	col.a = alpha
	var w := maxf(1.5 * s, 1.0)
	match str(val(id, "icon", "")):
		"hook":
			ci.draw_arc(c + Vector2(0, 2) * s, 6.0 * s, 0.2, PI + 0.6, 12, col, w * 1.3, true)
			ci.draw_line(c + Vector2(6, 2) * s, c + Vector2(6, -10) * s, col, w * 1.3, true)
			ci.draw_line(c + Vector2(-6, 2) * s, c + Vector2(-9, -2) * s, col, w, true)
		"heart":
			var pts := PackedVector2Array()
			for i in 24:
				var t := TAU * float(i) / 24.0
				pts.append(c + Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * 0.55 * s)
			ci.draw_colored_polygon(pts, Color(col, 0.35 * alpha))
			pts.append(pts[0])
			ci.draw_polyline(pts, col, w, true)
			ci.draw_line(c + Vector2(-5, 0) * s, c + Vector2(-1, 0) * s, col, w)
			ci.draw_line(c + Vector2(-1, 0) * s, c + Vector2(1, -4) * s, col, w)
			ci.draw_line(c + Vector2(1, -4) * s, c + Vector2(3, 3) * s, col, w)
			ci.draw_line(c + Vector2(3, 3) * s, c + Vector2(6, 0) * s, col, w)
		"blink":
			for i in 3:
				var x := -8.0 + float(i) * 6.0
				ci.draw_circle(c + Vector2(x, 0) * s, (2.0 + float(i)) * s, Color(col, (0.3 + 0.3 * float(i)) * alpha))
			ci.draw_line(c + Vector2(4, -6) * s, c + Vector2(10, 0) * s, col, w, true)
			ci.draw_line(c + Vector2(4, 6) * s, c + Vector2(10, 0) * s, col, w, true)
		"pulse":
			for i in 3:
				ci.draw_arc(c, (3.0 + float(i) * 4.0) * s, 0.0, TAU, 20, Color(col, alpha * (1.0 - float(i) * 0.25)), w, true)
		"eye":
			ci.draw_arc(c + Vector2(0, 6) * s, 10.0 * s, PI + 0.5, TAU - 0.5, 12, col, w, true)
			ci.draw_arc(c + Vector2(0, -6) * s, 10.0 * s, 0.5, PI - 0.5, 12, col, w, true)
			ci.draw_circle(c, 3.2 * s, col)
			ci.draw_circle(c, 1.2 * s, Color(0, 0, 0, alpha))
		"decoy":
			for k in 2:
				var o := Vector2(-4 + 8 * k, 0) * s
				var a := alpha * (0.45 if k == 0 else 1.0)
				ci.draw_circle(c + o + Vector2(0, -6) * s, 3.0 * s, Color(col, a))
				ci.draw_line(c + o + Vector2(0, -3) * s, c + o + Vector2(0, 7) * s, Color(col, a), w * 1.4)
		"silence":
			ci.draw_arc(c, 9.0 * s, 0.0, TAU, 20, col, w, true)
			ci.draw_line(c + Vector2(-6, -6) * s, c + Vector2(6, 6) * s, col, w, true)
			ci.draw_arc(c + Vector2(-2, 0) * s, 3.0 * s, -1.0, 1.0, 6, col, w * 0.8, true)
		_:
			ci.draw_circle(c, 6.0 * s, col)
