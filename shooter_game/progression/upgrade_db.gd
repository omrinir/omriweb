extends RefCounted
# ============================================================
#  UPGRADE DB - כל השדרוגים שאפשר לקנות בחנות (אחרי כל שלב), והכלכלה של 70 שלבים.
#
#  שלושה סוגים:
#    נשקים    - לכל נשק (weapons/weapon_db.gd) יש מסלולים: DAMAGE / FIRE RATE / MAGAZINE / RELOAD
#               (נשק בלי מחסנית מקבל CAPACITY במקום). שדרוג נפתח אחרי שמצאת את הנשק פעם אחת.
#    יכולות   - לכל יכולת (abilities/ability_db.gd): POWER / COOLDOWN. נפתח כשהיכולת נפתחת.
#    שיפורים  - PERKS (חיים, רימונים, תחמושת, בוסטים, כוונת לייזר, שאיבה).
#  אין צורך לשנות את הקובץ כשמוסיפים נשק או יכולת - הם מקבלים מסלולים אוטומטית.
#
#  הכלכלה (מאוזנת ל-70 שלבים):
#    level_income() - כמה גרוטאות (SCRAP) מקבלים בסוף שלב: גדל בהדרגה עם מספר השלב.
#    cost()         - מחיר = בסיס x (1 + שלב_הפתיחה / 12) x 1.55^רמה.
#    כך נשק שנפתח בשלב 60 יקר יותר מנשק של שלב 1 - אבל גם ההכנסה בשלב 60 גדולה יותר,
#    ובכל שלב אפשר לקנות בערך 2-3 שדרוגים.
#  איך משנים: GROWTH (כמה כל רמה מתייקרת), TRACKS (מה כל רמה נותנת), level_income.
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const AbilityDB := preload("res://abilities/ability_db.gd")

const GROWTH := 1.55
const MAX_LEVEL := 5

# מסלולי שדרוג. per = כמה כל רמה משנה (באחוזים)
const WEAPON_TRACKS := {
	"damage": {"name": "DAMAGE", "desc": "+12% damage per level", "per": 0.12, "base": 50},
	"fire_rate": {"name": "FIRE RATE", "desc": "Shoots 8% faster per level", "per": 0.08, "base": 45},
	"magazine": {"name": "MAGAZINE", "desc": "+15% magazine (at least +1)", "per": 0.15, "base": 40},
	"reload": {"name": "RELOAD", "desc": "Reloads 12% faster per level", "per": 0.12, "base": 40},
	"capacity": {"name": "CAPACITY", "desc": "+20% max ammo per level", "per": 0.2, "base": 40},
}
const ABILITY_TRACKS := {
	"power": {"name": "POWER", "desc": "Stronger, bigger, longer", "base": 70},
	"cooldown": {"name": "COOLDOWN", "desc": "Recharges 10% faster per level", "per": 0.10, "base": 60},
}
const PERKS := [
	{"id": "vitality", "name": "VITALITY", "desc": "+1 max heart", "max": 3, "base": 120, "tier": 3},
	{"id": "grenade_pouch", "name": "BANDOLIER", "desc": "+1 use on every special item you find (grenades, molotovs, launchers)", "max": 3, "base": 70, "tier": 1},
	{"id": "scavenger", "name": "SCAVENGER", "desc": "Ammo boxes give 25% more", "max": 3, "base": 60, "tier": 2},
	{"id": "long_boosts", "name": "LONG BOOSTS", "desc": "Boosts last 30% longer", "max": 2, "base": 60, "tier": 2},
	{"id": "laser_sight", "name": "LASER SIGHT", "desc": "A laser line shows your aim", "max": 1, "base": 90, "tier": 1},
	{"id": "siphon", "name": "SIPHON SHIELD", "desc": "Draining a survivor also gives a shield", "max": 2, "base": 100, "tier": 4},
]


# ---------------- הכנסה ----------------
# כמה גרוטאות מקבלים בסוף שלב (level = מספר השלב, stars = 1..3)
static func level_income(level: int, stars: int, level_score: int) -> int:
	return 30 + 8 * level + stars * (10 + 2 * level) + level_score / 40


# ---------------- מפתחות ----------------
static func weapon_key(id: int, track: String) -> String:
	return "w.%d.%s" % [id, track]


static func ability_key(id: String, track: String) -> String:
	return "a.%s.%s" % [id, track]


static func perk_key(id: String) -> String:
	return "p." + id


static func level_of(key: String) -> int:
	return int(Game.upgrades.get(key, 0))


# ---------------- מחיר ----------------
static func cost(base: int, tier: int, lvl: int) -> int:
	var c := float(base) * (1.0 + float(tier) / 12.0) * pow(GROWTH, float(lvl))
	return int(round(c / 5.0)) * 5


# המסלולים של נשק (בלי מחסנית -> CAPACITY במקום MAGAZINE/RELOAD)
static func weapon_tracks(id: int) -> Array:
	var w: Dictionary = WeaponDB.get_def(id)
	var out := ["damage", "fire_rate"]
	if int(w.get("magazine_size", 0)) > 0:
		out.append_array(["magazine", "reload"])
	else:
		out.append("capacity")
	return out


static func weapon_tier(id: int) -> int:
	return int(WeaponDB.val(id, "unlock_level", 1))


# ---------------- הנשק אחרי שדרוגים ----------------
# מחזיר עותק של הגדרות הנשק עם השדרוגים (player.gd משתמש בזה בכל ירייה)
static func weapon_def(id: int) -> Dictionary:
	var w: Dictionary = WeaponDB.get_def(id).duplicate()
	var dmg := level_of(weapon_key(id, "damage"))
	if dmg > 0:
		var k := 1.0 + WEAPON_TRACKS.damage.per * float(dmg)
		w["damage"] = float(w.get("damage", 1.0)) * k
		if w.has("falloff"):
			var f: Array = w.falloff
			w["falloff"] = [float(f[0]) * k, float(f[1]) * k, f[2]]
		if w.has("fixed_damage"):
			var fd: Array = w.fixed_damage
			w["fixed_damage"] = [int(round(float(fd[0]) * k)), int(round(float(fd[1]) * k))]
	var fr := level_of(weapon_key(id, "fire_rate"))
	w["fire_rate"] = float(w.get("fire_rate", 0.7)) / (1.0 + WEAPON_TRACKS.fire_rate.per * float(fr))
	var mg := level_of(weapon_key(id, "magazine"))
	var base_mag := int(w.get("magazine_size", 0))
	if base_mag > 0 and mg > 0:
		w["magazine_size"] = base_mag + maxi(mg, int(round(float(base_mag) * WEAPON_TRACKS.magazine.per * float(mg))))
	var rl := level_of(weapon_key(id, "reload"))
	w["reload_time"] = float(w.get("reload_time", 1.5)) / (1.0 + WEAPON_TRACKS.reload.per * float(rl))
	var cp := level_of(weapon_key(id, "capacity"))
	w["ammo_max"] = int(round(float(w.get("ammo_max", 20)) * (1.0 + WEAPON_TRACKS.capacity.per * float(cp))))
	return w


static func wval(id: int, field: String, default: Variant = null) -> Variant:
	return weapon_def(id).get(field, default)


static func ammo_max(id: int) -> int:
	return int(wval(id, "ammo_max", 20))


# ---------------- יכולות ----------------
static func ability_power(id: String) -> int:
	return level_of(ability_key(id, "power"))


static func ability_cooldown(id: String) -> float:
	var base: float = AbilityDB.val(id, "cooldown", 10.0)
	return base / (1.0 + ABILITY_TRACKS.cooldown.per * float(level_of(ability_key(id, "cooldown"))))


# ---------------- PERKS ----------------
static func perk(id: String) -> int:
	return level_of(perk_key(id))


static func perk_def(id: String) -> Dictionary:
	for p in PERKS:
		if p.id == id:
			return p
	return {}


# ---------------- קנייה ----------------
# מחיר הרמה הבאה (או -1 אם מקסימום)
static func next_cost(key: String, base: int, tier: int, max_lvl: int) -> int:
	var lvl := level_of(key)
	if lvl >= max_lvl:
		return -1
	return cost(base, tier, lvl)


static func buy(key: String, base: int, tier: int, max_lvl: int) -> bool:
	var c := next_cost(key, base, tier, max_lvl)
	if c < 0 or Game.scrap < c:
		return false
	Game.scrap -= c
	Game.upgrades[key] = level_of(key) + 1
	Game._level_start_scrap = Game.scrap
	Game._save()
	return true
