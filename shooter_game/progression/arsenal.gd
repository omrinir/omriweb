extends RefCounted
# ============================================================
#  ARSENAL - מבנה ההתקדמות של הנשקים, היכולות והתחמושת (במקום רשימות ידניות בכל שלב).
#  כמו ברוב משחקי היריות הדו-ממדיים (Metal Slug / Broforce / Blazing Chrome / Doom):
#   * כל נשק נכנס למשחק בשלב קבוע: weapons/weapon_db.gd -> "unlock_level" (18 נשקים, פרוסים על שלבים 1-45).
#     בשלב הזה הוא מחכה לך בהתחלה (NEW WEAPON: קרן אור + באנר, ui/unlock_banner.gd) - כך כל שלב מביא משהו חדש.
#     מקומות מלאים? הנשק החדש מחליף את הכי ישן (שנשאר על הרצפה).
#   * כל יכולת נפתחת בשלב קבוע: abilities/ability_db.gd -> "unlock_level" (באנר NEW ABILITY בתחילת השלב).
#   * שלב בלי נשק / יכולת חדשים (משלב MOD_FROM) = WEAPON MOD: ארגז שנותן שדרוג חינם לנשק שביד (apply_mod).
#     נלקח פעם אחת בכל שלב (Game.upgrades["m.<שלב>"]), גם אחרי TRY AGAIN.
#   * rewards(lv) = מה השלב נותן (לבאנר, לבדיקות ולטבלה ב-DEV_GUIDE).
#   * מטמון נשק (CACHE) באמצע כל שלב: נשק שכבר נפתח אבל אין לך (זרקת / איבדת / פספסת).
#   * נקודות אספקה (SUPPLY POINTS) במקומות קבועים: 20% / 40% / 60% / 80% מהשלב (עם שלט),
#     במקום קופסאות מפוזרות באקראי.
#   * תחמושת דינמית: זומבים מפילים יותר תחמושת כשנגמרת לך (ופחות כשיש מלא) - אף פעם לא נתקעים.
#   * רצפת תחמושת: בתחילת כל שלב לרובה יש לפחות תחמושת התחלה (player.gd).
#  לשנות: SUPPLY_POINTS, CACHE_AT, DROP_CHANCE, ו-"unlock_level" של כל נשק.
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Sfx := preload("res://sfx.gd")

const SUPPLY_POINTS := [[0.2, "ammo"], [0.4, "supply"], [0.6, "ammo"], [0.8, "supply"]]   # [מיקום יחסי, מה יש שם]
const CACHE_AT := 0.47               # מטמון הנשק באמצע השלב
const DROP_CHANCE := Vector2(0.03, 0.2)   # סיכוי שזומבי מפיל תחמושת: [כשיש מלא, כשכמעט נגמר]
const EMPTY_DROP := 0.35             # כשאין תחמושת בכלל בשום נשק
# שלבים 1-5 (רק רובה + שוטגאן / אקדח, בלי מחסניות גדולות): נקודת אספקה נוספת לפני הבוס, וסיכוי נפילה גבוה יותר כשנגמר
const EARLY_LEVELS := 5
const EARLY_SUPPLY := [0.9, "supply"]
const EARLY_DROP := 0.3              # במקום DROP_CHANCE.y בשלבים האלה


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
	# GRAVITY GRENADE: חור שחור קטן ששואב את כל הזומבים מסביב ואז קורס בפיצוץ (weapons/gravity_grenade.gd)
	# "intro" = בשלבים האלה הוא מחכה בטוח ליד ההתחלה (הפעמים הראשונות שפוגשים אותו). אחר כך - רק מציאות אקראיות
	"gravity": {"name": "GRAVITY GRENADE", "uses": 2, "from": 6, "weight": 1.5, "color": Color("7aa8ff"), "weapon": -5, "intro": [6, 7]},
	# שיקוי GOD MODE: מתחיל מיד כשלוקחים אותו (player.collect). 23 שניות: הגוף בוער, קליעי אש אדומים, נזק פי 4 (+300%)
	# לא נופל באקראי ("from" 999) - מופיע רק בשלבים של potion_levels()
	"god": {"name": "GOD MODE", "uses": 1, "from": 999, "weight": 0.0, "color": Color("ff2a2a"), "weapon": -2},
	# MIND CONTROL: קרן שהופכת אותך לזומבי ל-14 שניות (effects/mind_control.gd). שימוש אחד, נדיר, משלב 10
	"mind": {"name": "MIND CONTROL", "uses": 1, "from": 10, "weight": 0.7, "color": Color("b060ff"), "weapon": -3},
	# LASER CANNON: מחזיקים 1.4 שנ' טעינה -> קרן ירוקה 1.6 שנ' שעוברת דרך כל הזומבים (weapons/laser_cannon.gd). 8 שימושים
	"laser": {"name": "LASER CANNON", "uses": 8, "from": 14, "weight": 0.5, "color": Color("50ff70"), "weapon": -4},
}
const TEST_LASER_LEVEL := 0          # בדיקה: תותח לייזר בתחילת השלב הזה (main.gd). 0 = בלי
const TEST_MIND_EVERY_LEVEL := false  # בדיקה: מכשיר MIND CONTROL בתחילת כל שלב (main.gd). false = רק המציאות הרגילות (משלב 10)
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


# ============================================================
#  REWARDS - מה כל שלב נותן (נשק חדש / יכולת חדשה / WEAPON MOD)
# ============================================================
const AbilityDB := preload("res://abilities/ability_db.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")
const MOD_FROM := 11       # משלב זה: שלב בלי נשק / יכולת חדשים נותן WEAPON MOD
const MOD_SCRAP := 120     # הנשק שביד כבר בשדרוג מלא? גרוטאות במקום


static func abilities_at(lv: int) -> Array:
	var out := []
	for a in AbilityDB.ABILITIES:
		if int(a.unlock_level) == lv:
			out.append(a.id)
	return out


static func has_mod(lv: int) -> bool:
	return lv >= MOD_FROM and introduced_at(lv).is_empty() and abilities_at(lv).is_empty()


static func mod_key(lv: int) -> String:
	return "m.%d" % lv


# [{"kind": "weapon"/"ability"/"mod", "id": ..., "name": ...}]
static func rewards(lv: int) -> Array:
	var out := []
	for id in introduced_at(lv):
		out.append({"kind": "weapon", "id": id, "name": str(WeaponDB.val(id, "name", "?"))})
	for id in abilities_at(lv):
		out.append({"kind": "ability", "id": id, "name": str(AbilityDB.val(id, "name", "?"))})
	if has_mod(lv):
		out.append({"kind": "mod", "id": -1, "name": "WEAPON MOD"})
	return out


# WEAPON MOD נאסף: +1 רמה במסלול הכי נמוך של הנשק שביד (או של נשק אחר שלך), אחרת גרוטאות
static func apply_mod(player: Node, _p: Node) -> bool:
	var ids := []
	if player.weapon == 0 and player.gun >= 0:   # GUN
		ids.append(player.gun)
	for s in player.slots:
		if s != null and not s.id in ids:
			ids.append(s.id)
	var key := ""
	var wid := -1
	var tname := ""
	for id in ids:
		var best := ""
		for t in Upgrades.weapon_tracks(id):
			var k := Upgrades.weapon_key(id, t)
			if Upgrades.level_of(k) < Upgrades.MAX_LEVEL and (best == "" or Upgrades.level_of(k) < Upgrades.level_of(best)):
				best = k
				tname = str(Upgrades.WEAPON_TRACKS[t].name)
		if best != "":
			key = best
			wid = id
			break
	Game.upgrades[mod_key(Game.level)] = 1   # לא יופיע שוב בשלב הזה
	if key == "":
		Game.scrap += MOD_SCRAP
		Game._level_start_scrap += MOD_SCRAP
		player.get_tree().call_group("unlock_banner", "picked_mod", -1, "+%d SCRAP" % MOD_SCRAP, 0)
	else:
		Game.upgrades[key] = Upgrades.level_of(key) + 1
		player.get_tree().call_group("unlock_banner", "picked_mod", wid, tname, Upgrades.level_of(key))
	Game._save()
	Sfx.play("pickup", null)
	Sfx.play("weapon", null, 2.0)
	return true


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
	var low := EARLY_DROP if Game.level <= EARLY_LEVELS else DROP_CHANCE.y
	return lerpf(low, DROP_CHANCE.x, clampf(cur * 2.5, 0.0, 1.0))


# נקודות האספקה של השלב (main.gd -> _spawn_supplies): בשלבים הראשונים עוד ארגז לפני הבוס
static func supply_points_for(lv: int, base: Array) -> Array:
	if lv > EARLY_LEVELS:
		return base
	var out := base.duplicate()
	out.append(EARLY_SUPPLY)
	return out


# ציוד לתרגול (כפתורי שלבים בתפריט): הנשקים שהיו לך בערך בשלב הזה, עם תחמושת
static func loadout_for(lv: int) -> Array:
	var ids := unlocked_by(lv)
	ids.sort_custom(func(a, b): return intro_level(a) > intro_level(b))   # הכי חדשים
	var slots: Array = [{"id": 0, "ammo": 60}]
	for id in ids:
		if slots.size() >= 5:
			break
		if id != 0:
			slots.append({"id": id, "ammo": mini(int(round(float(WeaponDB.val(id, "ammo_start", 10)) * 1.5)), int(WeaponDB.val(id, "ammo_max", 9999)))})   # לא יותר מהמקסימום (מיניגאן: 140)
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
