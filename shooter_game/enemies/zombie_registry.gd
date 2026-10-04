extends RefCounted
# ============================================================
#  ZOMBIE REGISTRY - רשימת כל סוגי הזומבים החדשים (שלבים 5-9)
#  סוגים 0-19 נמצאים ב-zombie.gd (KINDS). מ-20 והלאה כל סוג = קובץ ב-enemies/types/.
#
#  ****  להוספת זומבי חדש: מוסיפים שורה ל-TYPES (מספר חדש + נתיב)  ****
# ============================================================

enum {
	CLIMBER = 20, SCOUT, STALKER, WALL_CRAWLER, GRABBER, PACK_LEADER, AMBUSHER, TACTICIAN, SHIELDED, LEAPER,
	ENGINEER, ADAPTOR, DODGER, TANK, HUNTER, COMMANDER, HUNTER_ELITE, SHIELD_ELITE, INFECTOR, EVOLVED, SIREN,
	BLOODGATE, KRAKEN, LIVEWIRE,   # שלב 10 (צפון-מזרח)
}

const FIRST := 20
const TYPES := {
	CLIMBER: "res://enemies/types/climber.gd",
	SCOUT: "res://enemies/types/scout.gd",
	STALKER: "res://enemies/types/stalker.gd",
	WALL_CRAWLER: "res://enemies/types/wall_crawler.gd",
	GRABBER: "res://enemies/types/grabber.gd",
	PACK_LEADER: "res://enemies/types/pack_leader.gd",
	AMBUSHER: "res://enemies/types/ambusher.gd",
	TACTICIAN: "res://enemies/types/tactician.gd",
	SHIELDED: "res://enemies/types/shielded.gd",
	LEAPER: "res://enemies/types/leaper.gd",
	ENGINEER: "res://enemies/types/engineer.gd",
	ADAPTOR: "res://enemies/types/adaptor.gd",
	DODGER: "res://enemies/types/dodger.gd",
	TANK: "res://enemies/types/tank.gd",
	HUNTER: "res://enemies/types/hunter.gd",
	COMMANDER: "res://enemies/types/commander.gd",
	HUNTER_ELITE: "res://enemies/types/hunter_elite.gd",
	SHIELD_ELITE: "res://enemies/types/shield_elite.gd",
	INFECTOR: "res://enemies/types/infector.gd",
	EVOLVED: "res://enemies/types/evolved.gd",
	SIREN: "res://enemies/types/siren.gd",
	BLOODGATE: "res://enemies/types/blood_gate.gd",
	KRAKEN: "res://enemies/types/kraken.gd",
	LIVEWIRE: "res://enemies/types/live_wire.gd",
}

static var _stats_cache := {}


static func has(kind: int) -> bool:
	return TYPES.has(kind) and ResourceLoader.exists(TYPES[kind])


# יוצר את המודול של הסוג (או null)
static func make(kind: int) -> RefCounted:
	if not has(kind):
		return null
	return load(TYPES[kind]).new()


static func stats(kind: int) -> Dictionary:
	if _stats_cache.has(kind):
		return _stats_cache[kind]
	var m := make(kind)
	var s: Dictionary = m.stats() if m != null else {}
	_stats_cache[kind] = s
	return s


static func points(kind: int) -> int:
	return int(stats(kind).get("points", 150))


static func display_name(kind: int) -> String:
	return str(stats(kind).get("name", "ZOMBIE"))
