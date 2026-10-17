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
#    cd_after              - true = ה-cooldown מתחיל כשהאפקט נגמר (לא בהפעלה). C בזמן שפועל = stop()
#    power_desc/power_base - תיאור ומחיר בסיס מיוחדים למסלול POWER בחנות
#    keep                  - ציוד קבוע (פנס, ג'טפאק, LAST BREATH): יכולת חדשה לא מחליפה אותו כשכל 5 המקומות מלאים
# ============================================================

# סדר הרשימה = סדר ההתקדמות (unlock_level). 13 יכולות פרוסות על שלבים 1-46, אחת בכל כמה שלבים (progression/arsenal.gd -> rewards)
const ABILITIES := [
	{"id": "flashlight", "name": "FLASHLIGHT", "color": Color("ffe6a8"), "cooldown": 25.0, "unlock_level": 1, "icon": "torch", "cd_after": true, "keep": true,
		"power_desc": "Longer battery (50s -> 2 min max)", "power_base": 80,
		"desc": "A warm light that cuts through the dark for 50s. They can see you too. Flickers when the battery dies. C again = off."},
	{"id": "dark_pulse", "name": "SHOCK BLAST", "color": Color("5ac8ff"), "cooldown": 10.0, "unlock_level": 3, "icon": "pulse",
		"power_desc": "Bigger radius, harder knockback, more damage",
		"desc": "Your device discharges: knocks back and stuns everything around you and breaks grabs. For when they swarm you."},
	{"id": "flare", "name": "FLARE", "color": Color("ff4a3a"), "cooldown": 16.0, "duration": 6.0, "unlock_level": 5, "icon": "flare",
		"power_desc": "Burns longer and hotter (sets more of them on fire)",
		"desc": "Throw a burning road flare. They think it's you and run to it - and catch fire. Smart ones learn to ignore it."},
	{"id": "jetpack", "name": "JETPACK", "color": Color("ff9a3a"), "cooldown": 40.0, "unlock_level": 6, "icon": "jet", "cd_after": true, "keep": true,
		"power_desc": "More flight time (20s -> 32s max)", "power_base": 110,
		"desc": "Fly! Hold W/SPACE to thrust, fire while flying. 20s of fuel, burns only in the air. C again = land."},
	{"id": "last_breath", "name": "LAST BREATH", "color": Color("e8e0c8"), "cooldown": 0.0, "unlock_level": 8, "icon": "heart", "passive": true, "keep": true,
		"power_desc": "Longer invulnerability; level 3+ = twice per stage",
		"desc": "Once per stage: a killing blow leaves you at 1 heart, briefly untouchable."},
	{"id": "fire_rounds", "name": "INCENDIARY ROUNDS", "color": Color("ff8a20"), "cooldown": 18.0, "duration": 7.0, "unlock_level": 11, "icon": "fire",
		"power_desc": "Lasts longer (+20% per level)",
		"desc": "For 7 seconds every bullet sets zombies on fire. Burning zombies panic and spread it."},
	{"id": "hunters_sight", "name": "MOTION SCANNER", "color": Color("4aff8a"), "cooldown": 12.0, "duration": 4.0, "unlock_level": 15, "icon": "radar",
		"power_desc": "Scan lasts longer",
		"desc": "A scan pulse shows every zombie through walls, darkness and cover - and which ones wait in AMBUSH."},
	{"id": "smoke", "name": "SMOKE BOMB", "color": Color("a8b0b8"), "cooldown": 14.0, "duration": 5.0, "unlock_level": 20, "icon": "smoke",
		"power_desc": "Bigger, longer cloud",
		"desc": "Smoke at your feet: zombies inside choke and lose track of you. They can't learn what they can't see."},
	{"id": "focus", "name": "FOCUS", "color": Color("8ab8ff"), "cooldown": 22.0, "duration": 3.0, "unlock_level": 25, "icon": "focus",
		"power_desc": "Slow time for longer",
		"desc": "Time slows down around you for 3s (you move at full speed) and your magazine is refilled. Line up the headshots."},
	{"id": "sentry", "name": "SENTRY GUN", "color": Color("d8d060"), "cooldown": 30.0, "duration": 12.0, "unlock_level": 28, "icon": "sentry",
		"power_desc": "Works longer, shoots harder",
		"desc": "Drop an auto-turret that shoots the nearest zombie it can see for 12s. Hold a corridor while you reload."},
	{"id": "adrenaline", "name": "ADRENALINE SHOT", "color": Color("ff4a6a"), "cooldown": 30.0, "duration": 6.0, "unlock_level": 33, "icon": "syringe",
		"power_desc": "Lasts longer; level 3+ heals 2 hearts",
		"desc": "Stab a syringe: +1 heart and for 6s you shoot twice as fast, reload faster and run harder."},
	{"id": "mortar", "name": "MORTAR STRIKE", "color": Color("ff6a3a"), "cooldown": 35.0, "unlock_level": 40, "icon": "mortar",
		"power_desc": "More shells, more damage",
		"desc": "Mark the spot you aim at: 4 mortar shells land there a second later. Don't stand under it."},
	{"id": "chain_shock", "name": "CHAIN LIGHTNING", "color": Color("b48aff"), "cooldown": 14.0, "unlock_level": 46, "icon": "chain",
		"power_desc": "Jumps to more zombies, more damage",
		"desc": "A bolt from your device hits the zombie you aim at and jumps to 5 more nearby. Stuns and burns through crowds."},
]

# יכולות ישנות שהוחלפו (שמירות ישנות): id ישן -> id חדש
const MIGRATE := {"decoy": "flare", "phantom_step": "smoke", "silence": "focus", "blood_hook": "fire_rounds"}


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


# id אחרי המרה (יכולת שהוחלפה -> החדשה, לא קיימת -> "")
static func migrate_id(id: String) -> String:
	id = str(MIGRATE.get(id, id))
	return id if not get_def(id).is_empty() else ""


# ability_slots משמירה ישנה: מחליפים יכולות שהוחלפו, מוחקים כפולות ולא מוכרות
static func migrate_slots(slots: Array) -> Array:
	var out := []
	for v in slots:
		var id := migrate_id(str(v)) if v != null else ""
		out.append(null if id == "" or id in out else id)
	while out.size() < 5:
		out.append(null)
	return out


# שדרוגים שנקנו ליכולת שהוחלפה עוברים ליכולת החדשה ("a.<id>.<track>")
static func migrate_upgrades(up: Dictionary) -> void:
	for k in up.keys():
		var parts := str(k).split(".")
		if parts.size() == 3 and parts[0] == "a" and MIGRATE.has(parts[1]):
			var nk := "a.%s.%s" % [MIGRATE[parts[1]], parts[2]]
			up[nk] = maxi(int(up.get(nk, 0)), int(up[k]))
			up.erase(k)


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
		"jet":
			ci.draw_rect(Rect2(c + Vector2(-7, -9) * s, Vector2(14, 12) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-5, 3) * s, Vector2(3, 3) * s), col)
			ci.draw_rect(Rect2(c + Vector2(2, 3) * s, Vector2(3, 3) * s), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 7) * s, c + Vector2(-2, 7) * s, c + Vector2(-3.5, 12) * s]), Color(1.0, 0.85, 0.3, alpha))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(2, 7) * s, c + Vector2(5, 7) * s, c + Vector2(3.5, 12) * s]), Color(1.0, 0.85, 0.3, alpha))
		"torch":   # פנס: גוף + ראש + אור רך
			ci.draw_circle(c + Vector2(5, -1) * s, 8.0 * s, Color(1.0, 0.92, 0.7, 0.25 * alpha))
			ci.draw_rect(Rect2(c + Vector2(-9, -2) * s, Vector2(10, 5) * s), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(1, -4) * s, c + Vector2(5, -5) * s, c + Vector2(5, 6) * s, c + Vector2(1, 5) * s]), col)
			ci.draw_line(c + Vector2(5.5, -4) * s, c + Vector2(5.5, 5) * s, Color(1.0, 0.97, 0.85, alpha), w, true)
		"pulse":   # SHOCK BLAST: טבעות + ברק
			for i in 3:
				ci.draw_arc(c, (3.0 + float(i) * 4.0) * s, 0.0, TAU, 20, Color(col, alpha * (1.0 - float(i) * 0.25)), w, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-2, -9) * s, c + Vector2(2, -2) * s, c + Vector2(-2, 1) * s, c + Vector2(2, 9) * s]), Color(1, 1, 1, alpha), w, true)
		"flare":   # זיקוק דרכים אדום עם להבה וניצוצות
			ci.draw_line(c + Vector2(-7, 7) * s, c + Vector2(3, -3) * s, Color(0.75, 0.12, 0.1, alpha), 4.0 * s, true)
			ci.draw_line(c + Vector2(-7, 7) * s, c + Vector2(-4, 4) * s, Color(0.2, 0.2, 0.22, alpha), 4.0 * s, true)
			ci.draw_circle(c + Vector2(5, -5) * s, 5.0 * s, Color(1.0, 0.3, 0.2, 0.35 * alpha))
			ci.draw_circle(c + Vector2(5, -5) * s, 2.6 * s, Color(1.0, 0.85, 0.7, alpha))
			for k in 4:
				var d := Vector2.from_angle(-0.4 - float(k) * 0.55) * (8.0 + float(k % 2) * 3.0)
				ci.draw_circle(c + Vector2(5, -5) * s + d * s, 0.9 * s, Color(1.0, 0.7, 0.3, alpha))
		"fire":   # קליע בוער
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 9) * s, c + Vector2(-7, 1) * s, c + Vector2(-3, -4) * s, c + Vector2(-1, -10) * s, c + Vector2(2, -3) * s, c + Vector2(6, -6) * s, c + Vector2(7, 2) * s, c + Vector2(3, 9) * s]), Color(col, 0.85 * alpha))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, 8) * s, c + Vector2(-3, 2) * s, c + Vector2(0, -3) * s, c + Vector2(3, 2) * s, c + Vector2(2, 8) * s]), Color(1.0, 0.92, 0.5, alpha))
			ci.draw_rect(Rect2(c + Vector2(-1.6, 1) * s, Vector2(3.2, 7) * s), Color(0.85, 0.6, 0.25, alpha))
		"radar":   # סורק: עיגולים + קרן מסתובבת + נקודות
			ci.draw_arc(c, 10.0 * s, 0.0, TAU, 24, col, w, true)
			ci.draw_arc(c, 5.5 * s, 0.0, TAU, 16, Color(col, 0.5 * alpha), w * 0.7, true)
			var sw := Time.get_ticks_msec() / 400.0
			ci.draw_line(c, c + Vector2.from_angle(sw) * 10.0 * s, col, w, true)
			ci.draw_circle(c + Vector2(4, -5) * s, 1.6 * s, Color(1.0, 0.3, 0.25, alpha))
			ci.draw_circle(c + Vector2(-6, 3) * s, 1.6 * s, Color(1.0, 0.3, 0.25, alpha))
		"smoke":   # רימון עשן + ענן
			for k in 4:
				ci.draw_circle(c + Vector2(-5 + k * 4, -4 + (k % 2) * 3) * s, (4.0 + float(k % 2)) * s, Color(col, 0.45 * alpha))
			ci.draw_rect(Rect2(c + Vector2(-3, 1) * s, Vector2(6, 9) * s), Color(0.3, 0.34, 0.3, alpha))
			ci.draw_rect(Rect2(c + Vector2(-3, 1) * s, Vector2(6, 2) * s), Color(0.85, 0.85, 0.85, alpha))
		"focus":   # שעון עצר / כוונת
			ci.draw_arc(c + Vector2(0, 1) * s, 9.0 * s, 0.0, TAU, 24, col, w, true)
			ci.draw_line(c + Vector2(0, 1) * s, c + Vector2(0, -5) * s, col, w, true)
			ci.draw_line(c + Vector2(0, 1) * s, c + Vector2(4, 3) * s, col, w, true)
			ci.draw_rect(Rect2(c + Vector2(-2, -11) * s, Vector2(4, 2.5) * s), col)
			for k in 4:
				var d := Vector2.from_angle(float(k) * PI * 0.5)
				ci.draw_line(c + Vector2(0, 1) * s + d * 11.0 * s, c + Vector2(0, 1) * s + d * 13.5 * s, Color(col, 0.7 * alpha), w * 0.8, true)
		"sentry":   # טורט על חצובה
			ci.draw_line(c + Vector2(0, 2) * s, c + Vector2(-7, 11) * s, col, w, true)
			ci.draw_line(c + Vector2(0, 2) * s, c + Vector2(7, 11) * s, col, w, true)
			ci.draw_line(c + Vector2(0, 2) * s, c + Vector2(0, 11) * s, col, w, true)
			ci.draw_rect(Rect2(c + Vector2(-6, -6) * s, Vector2(10, 8) * s), col)
			ci.draw_line(c + Vector2(4, -3) * s, c + Vector2(12, -3) * s, col, w * 1.3, true)
			ci.draw_circle(c + Vector2(-3, -3) * s, 1.3 * s, Color(1.0, 0.25, 0.2, alpha))
		"syringe":   # מזרק אדרנלין
			ci.draw_line(c + Vector2(-8, 8) * s, c + Vector2(4, -4) * s, col, 4.5 * s, true)
			ci.draw_line(c + Vector2(-6, 6) * s, c + Vector2(2, -2) * s, Color(1.0, 0.8, 0.85, alpha), 2.0 * s, true)
			ci.draw_line(c + Vector2(4, -4) * s, c + Vector2(10, -10) * s, Color(0.85, 0.85, 0.9, alpha), 1.2 * s, true)
			ci.draw_line(c + Vector2(-10, 6) * s, c + Vector2(-6, 10) * s, col, 2.0 * s, true)
			ci.draw_line(c + Vector2(-11, 11) * s, c + Vector2(-8, 8) * s, col, 2.0 * s, true)
		"chain":   # ברק שקופץ בין 3 נקודות
			var pts := PackedVector2Array([c + Vector2(-10, -6) * s, c + Vector2(-4, -1) * s, c + Vector2(-6, 3) * s, c + Vector2(2, 1) * s, c + Vector2(0, 6) * s, c + Vector2(10, 8) * s])
			ci.draw_polyline(pts, Color(col, 0.5 * alpha), w * 2.4, true)
			ci.draw_polyline(pts, Color(1, 1, 1, alpha), w * 0.9, true)
			for q in [pts[0], pts[3], pts[5]]:
				ci.draw_circle(q, 2.2 * s, col)
		"mortar":   # פגז נופל + מטרה
			ci.draw_arc(c + Vector2(0, 5) * s, 8.0 * s, 0.0, TAU, 20, Color(col, 0.8 * alpha), w, true)
			ci.draw_line(c + Vector2(-10, 5) * s, c + Vector2(10, 5) * s, Color(col, 0.6 * alpha), w * 0.7)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-2.5, -10) * s, c + Vector2(2.5, -10) * s, c + Vector2(2.5, -2) * s, c + Vector2(0, 2) * s, c + Vector2(-2.5, -2) * s]), Color(0.75, 0.75, 0.7, alpha))
			ci.draw_line(c + Vector2(0, -12) * s, c + Vector2(0, -16) * s, Color(1, 1, 1, 0.5 * alpha), w * 0.7)
		_:
			ci.draw_circle(c, 6.0 * s, col)
