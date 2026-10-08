extends RefCounted
# ============================================================
#  ARSENAL - מבנה ההתקדמות של הנשקים והתחמושת (במקום רשימות ידניות בכל שלב).
#  כמו ברוב משחקי היריות הדו-ממדיים (Metal Slug / Broforce / Blazing Chrome / Doom):
#   * כל נשק נכנס למשחק בשלב קבוע: weapons/weapon_db.gd -> "unlock_level".
#     בשלב הזה הוא מחכה לך בהתחלה (NEW WEAPON) - כך כל שלב מביא משהו חדש, בסדר הגיוני.
#   * מטמון נשק (CACHE) באמצע כל שלב: נשק שכבר נפתח אבל אין לך (זרקת / איבדת / פספסת).
#   * נקודות אספקה (SUPPLY POINTS) במקומות קבועים: 20% / 40% / 60% / 80% מהשלב (עם שלט),
#     במקום קופסאות מפוזרות באקראי.
#   * תחמושת דינמית: זומבים מפילים יותר תחמושת כשנגמרת לך (ופחות כשיש מלא) - אף פעם לא נתקעים.
#   * רצפת תחמושת: בתחילת כל שלב לרובה יש לפחות תחמושת התחלה (player.gd).
#  לשנות: SUPPLY_POINTS, CACHE_AT, DROP_CHANCE, ו-"unlock_level" של כל נשק.
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")

const SUPPLY_POINTS := [[0.2, "ammo"], [0.4, "supply"], [0.6, "ammo"], [0.8, "supply"]]   # [מיקום יחסי, מה יש שם]
const CACHE_AT := 0.47               # מטמון הנשק באמצע השלב
const DROP_CHANCE := Vector2(0.03, 0.2)   # סיכוי שזומבי מפיל תחמושת: [כשיש מלא, כשכמעט נגמר]
const EMPTY_DROP := 0.35             # כשאין תחמושת בכלל בשום נשק


# ============================================================
#  SPECIAL ITEMS - נשקי נפץ שהם לא "נשק" (לא בגלגל, לא בחנות): מוצאים 1-2 בכל שלב במקום אקראי,
#  יש להם כמה שימושים (E = מחליף אליהם, ירייה = שימוש), ואחרי השימוש האחרון - נזרקים.
#  מחזיקים רק אחד: מציאה של אחר מחליפה אותו (אותו סוג = עוד שימושים).
#  "from" = מאיזה שלב הוא יכול להופיע, "weight" = כמה נפוץ, "weapon" = איך לצייר (weapon_db id).
# ============================================================
const SPECIALS := {
	"grenade": {"name": "GRENADES", "uses": 3, "from": 1, "weight": 3.0, "color": Color("8aa040"), "weapon": -1},
	"molotov": {"name": "MOLOTOVS", "uses": 2, "from": 3, "weight": 2.0, "color": Color("ff8a30"), "weapon": 8},
	"launcher": {"name": "GRENADE LAUNCHER", "uses": 4, "from": 5, "weight": 1.6, "color": Color("80b060"), "weapon": 9},
	"rocket": {"name": "ROCKET LAUNCHER", "uses": 2, "from": 8, "weight": 1.0, "color": Color("e05a30"), "weapon": 11},
	# שיקוי GOD MODE: מתחיל מיד כשלוקחים אותו (player.collect). 13 שניות: הגוף בוער, קליעי אש אדומים, נזק פי 4 (+300%)
	# לא נופל באקראי ("from" 999) - מופיע רק בשלבים של potion_levels()
	"god": {"name": "GOD MODE", "uses": 1, "from": 999, "weight": 0.0, "color": Color("ff2a2a"), "weapon": -2},
}
const SPECIAL_FINDS := Vector2(0.15, 0.85)   # איפה בשלב (יחסי) הם יכולים להיות
const POTION_FIRST := 3        # שיקוי GOD MODE: שלב 3, ואז כל 2-3 שלבים
const POTION_MID := Vector2(0.42, 0.58)   # איפה בשלב (יחסי): באמצע, איפה שיש זומבים
const POTION_SEED := 1717      # הסדר קבוע (אותם שלבים בכל משחק)


static func potion_levels() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = POTION_SEED
	var out := []
	var lv := POTION_FIRST
	while lv <= 60:
		out.append(lv)
		lv += rng.randi_range(2, 3)
	return out


static func has_potion(lv: int) -> bool:
	return potion_levels().has(lv)


# 1-2 מציאות לשלב, לפי מה שכבר זמין בשלב הזה
static func specials_for_level(lv: int, rng: RandomNumberGenerator) -> Array:
	var pool := []
	var total := 0.0
	for k in SPECIALS:
		if int(SPECIALS[k].from) <= lv:
			pool.append(k)
			total += float(SPECIALS[k].weight)
	var out := []
	for i in (2 if rng.randf() < 0.5 else 1):
		var r := rng.randf() * total
		for k in pool:
			r -= float(SPECIALS[k].weight)
			if r <= 0.0:
				out.append(k)
				break
	return out


static func usable(id: int) -> bool:
	return id >= 0 and id < WeaponDB.count() and not WeaponDB.removed(id)


static func intro_level(id: int) -> int:
	return int(WeaponDB.val(id, "unlock_level", 1))


# הנשקים שנכנסים למשחק בשלב הזה
static func introduced_at(lv: int) -> Array:
	var out := []
	for id in WeaponDB.count():
		if usable(id) and id != 0 and intro_level(id) == lv:
			out.append(id)
	return out


# כל הנשקים שנפתחו עד השלב הזה (כולל)
static func unlocked_by(lv: int) -> Array:
	var out := []
	for id in WeaponDB.count():
		if usable(id) and intro_level(id) <= lv:
			out.append(id)
	return out


# מה מחכה בשלב: {"new": [נשקים חדשים שאין לך], "cache": נשק ישן שאין לך או -1}
static func offers(lv: int, owned: Array) -> Dictionary:
	var fresh := introduced_at(lv).filter(func(id): return not id in owned)
	var missing := unlocked_by(lv - 1).filter(func(id): return not id in owned and not id in fresh)
	var cache := -1
	if not missing.is_empty():   # הכי חדש קודם (זה שהכי שימושי בשלב הזה), מתחלף בין שלבים
		missing.sort_custom(func(a, b): return intro_level(a) > intro_level(b))
		cache = missing[lv % mini(missing.size(), 2)]
	return {"new": fresh, "cache": cache}


# סיכוי שזומבי מת יפיל קופסת תחמושת (לפי כמה נשאר לשחקן)
static func ammo_drop_chance(player: Node) -> float:
	if player == null or not "slots" in player:
		return DROP_CHANCE.x
	var total := 0
	var cur := 1.0
	for s in player.slots:
		if s == null:
			continue
		total += int(s.ammo)
		if s.id == player.gun:
			var mx := float(maxi(int(WeaponDB.val(s.id, "ammo_max", 100)), 1))
			cur = float(s.ammo) / mx
	if total <= 0:
		return EMPTY_DROP
	return lerpf(DROP_CHANCE.y, DROP_CHANCE.x, clampf(cur * 2.5, 0.0, 1.0))


# ציוד לתרגול (כפתורי שלבים בתפריט): הנשקים שהיו לך בערך בשלב הזה, עם תחמושת
static func loadout_for(lv: int) -> Array:
	var ids := unlocked_by(lv)
	ids.sort_custom(func(a, b): return intro_level(a) > intro_level(b))   # הכי חדשים
	var slots: Array = [{"id": 0, "ammo": 60}]
	for id in ids:
		if slots.size() >= 5:
			break
		if id != 0:
			slots.append({"id": id, "ammo": int(round(float(WeaponDB.val(id, "ammo_start", 10)) * 1.5))})
	while slots.size() < 5:
		slots.append(null)
	return slots


# ---- שלט של נקודת אספקה / מטמון נשק (עמוד עם לוח וסמל) ----
class SupplyMarker extends Node2D:
	const Art := preload("res://art.gd")
	var kind := "ammo"   # ammo / supply / health / cache

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var col: Color = {"ammo": Color("d8c070"), "supply": Color("a8c070"), "health": Color("ff6a6a"), "cache": Color("ffb040")}.get(kind, Color.WHITE)
		draw_line(Vector2(-22, 0), Vector2(-22, -58), Color("3a3a3e"), 3.0)   # עמוד
		var r := Rect2(Vector2(-36, -74), Vector2(30, 18))
		draw_rect(r, Color(0.1, 0.1, 0.12, 0.9))
		draw_rect(r, col, false, 1.6)
		var c := r.get_center()
		match kind:
			"health":
				draw_rect(Rect2(c + Vector2(-2, -6), Vector2(4, 12)), col)
				draw_rect(Rect2(c + Vector2(-6, -2), Vector2(12, 4)), col)
			"cache":   # צללית רובה
				draw_line(c + Vector2(-10, 1), c + Vector2(10, -2), col, 2.4)
				draw_line(c + Vector2(-4, 0), c + Vector2(-6, 5), col, 2.0)
			_:   # כדורים
				for i in 3:
					var x := -6.0 + float(i) * 6.0
					draw_rect(Rect2(c + Vector2(x - 1.4, -3), Vector2(2.8, 7)), col)
					draw_colored_polygon(PackedVector2Array([c + Vector2(x - 1.4, -3), c + Vector2(x + 1.4, -3), c + Vector2(x, -6)]), col)
		draw_rect(Rect2(Vector2(-30, -2), Vector2(60, 3)), Color(0.2, 0.2, 0.22, 0.5))   # בסיס
