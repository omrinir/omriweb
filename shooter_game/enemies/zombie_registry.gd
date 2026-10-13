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
	DEVOURER, SPLITJAW,            # שלב 11
	MIMIC, IRONWING, SPARE_PARTS,  # שלב 12
	GRAVEBORN, SANDBLASTER,        # שלב 13
	CRUMBLER, RETCHER,             # שלב 14
	BOMBHEAD, MINIGUNNER, STILTER, # שלב 15
	SWARMER, BROODMOTHER,          # שלב 16
	STRANGER,                      # "החבר" מסצנת הסיפור של שלב 1 (story/)
	MIRAGE, MIRAGE_KING,           # שלב 17
	DRILLER, UZI,                  # שלב 18
	SWINGER, BLADES,               # שלב 19 (ג'ונגל)
	GHILLIE, HANGED,               # שלב 20 (ג'ונגל צפוף)
	GLIDER, REVOLVER,              # שלב 21 (צוקים)
	GOLIATH, HARPOONER,            # שלב 22 (הסכר)
	BIKER, SHOVER,                 # שלב 23 (כביש מהיר)
	SCARECROW, TORCH,              # שלב 24 (שדות בוערים)
	SIGNALER, ROD,                 # שלב 25 (תורן רדיו)
	HAZMAT, BLACKOUT, VENT, GENERAL,   # שלב 26 (הבונקר) - GENERAL = הבוס של 26 ו-27
	SNIPER, SAPPER, HANDLER,       # שלב 27 (שער הרמה)
	CLINGER, BOULDER,              # שלב 28 (האנדים - דרך המוות)
	ECHO, DYNAMITER,               # שלב 29 (מכרה ההדים)
	FROSTBITE, BELLRINGER,         # שלב 30 (הכפר הקפוא)
	TRUCKER,                       # שלב 28 - הבוס (EL CAMIONERO)
	DROWNED, BALSERO, NETTER,      # שלב 31 (איי הקנים)
	DIABLO, MORENADA, BANDLEADER, SUPAY,   # שלב 32 (קרנבל השדים). SUPAY = הבוס של 32 ו-33
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
	DEVOURER: "res://enemies/types/devourer.gd",
	SPLITJAW: "res://enemies/types/splitjaw.gd",
	MIMIC: "res://enemies/types/mimic.gd",
	IRONWING: "res://enemies/types/ironwing.gd",
	SPARE_PARTS: "res://enemies/types/spare_parts.gd",
	GRAVEBORN: "res://enemies/types/graveborn.gd",
	SANDBLASTER: "res://enemies/types/sandblaster.gd",
	CRUMBLER: "res://enemies/types/crumbler.gd",
	RETCHER: "res://enemies/types/retcher.gd",
	BOMBHEAD: "res://enemies/types/bombhead.gd",
	MINIGUNNER: "res://enemies/types/minigunner.gd",
	STILTER: "res://enemies/types/stilter.gd",
	SWARMER: "res://enemies/types/swarmer.gd",
	BROODMOTHER: "res://enemies/types/broodmother.gd",
	STRANGER: "res://enemies/types/stranger.gd",
	MIRAGE: "res://enemies/types/mirage.gd",
	MIRAGE_KING: "res://enemies/types/mirage_king.gd",
	DRILLER: "res://enemies/types/driller.gd",
	UZI: "res://enemies/types/uzi.gd",
	SWINGER: "res://enemies/types/swinger.gd",
	BLADES: "res://enemies/types/blades.gd",
	GHILLIE: "res://enemies/types/ghillie.gd",
	HANGED: "res://enemies/types/hanged.gd",
	GLIDER: "res://enemies/types/glider.gd",
	REVOLVER: "res://enemies/types/revolver.gd",
	GOLIATH: "res://enemies/types/goliath.gd",
	HARPOONER: "res://enemies/types/harpooner.gd",
	BIKER: "res://enemies/types/biker.gd",
	SHOVER: "res://enemies/types/shover.gd",
	SCARECROW: "res://enemies/types/scarecrow.gd",
	TORCH: "res://enemies/types/torch.gd",
	SIGNALER: "res://enemies/types/signaler.gd",
	ROD: "res://enemies/types/rod.gd",
	HAZMAT: "res://enemies/types/hazmat.gd",
	BLACKOUT: "res://enemies/types/blackout.gd",
	VENT: "res://enemies/types/vent.gd",
	GENERAL: "res://enemies/types/general.gd",
	SNIPER: "res://enemies/types/sniper.gd",
	SAPPER: "res://enemies/types/sapper.gd",
	HANDLER: "res://enemies/types/handler.gd",
	CLINGER: "res://enemies/types/clinger.gd",
	BOULDER: "res://enemies/types/boulder.gd",
	ECHO: "res://enemies/types/echo.gd",
	DYNAMITER: "res://enemies/types/dynamiter.gd",
	FROSTBITE: "res://enemies/types/frostbite.gd",
	BELLRINGER: "res://enemies/types/bellringer.gd",
	TRUCKER: "res://enemies/types/trucker.gd",
	DROWNED: "res://enemies/types/drowned.gd",
	BALSERO: "res://enemies/types/balsero.gd",
	NETTER: "res://enemies/types/netter.gd",
	DIABLO: "res://enemies/types/diablo.gd",
	MORENADA: "res://enemies/types/morenada.gd",
	BANDLEADER: "res://enemies/types/bandleader.gd",
	SUPAY: "res://enemies/types/supay.gd",
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
