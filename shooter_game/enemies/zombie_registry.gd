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
	AZUFRERO, CINDER, SMOKER,      # שלב 33 (מכתש הגופרית)
	REVIVER, SPOTTER, PANEL, DISH, # שלב 34 (המצפה). REVIVER חוזר בשלבים הבאים. DISH = בוס נייח
	ENCASED, AXEMAN, AVALANCHER, ICE_TITAN, # שלב 35 (קרחון הגולגולת). ICE_TITAN = בוס נייח
	MALLKI, GUARDIAN, QUIPU, APU, # שלב 36 (הפסגה). APU = בוס נייח
	KITE, CAPOEIRA, GRAFFITI, DONO, # שלב 37 (פאבלה בריו). DONO = בוס נייח על גג
	OFFICE, WASHER, COURIER, TOWER, # שלב 38 (סאו פאולו). TOWER = בוס נייח על פיגום
	HOOLIGAN, STRIKER, REFEREE, GOALKEEPER, # שלב 39 (המרקנה). GOALKEEPER = בוס נייח בשער
	CONSCRIPT, OFFICER, FLAGBEARER, BEHEMOTH, # שלב 40 (נמל סנטוס - אימפריית המתים). BEHEMOTH = טנק נייח
	DRUMMER, GUARDSMAN, PROPAGANDIST, MARSHAL, # שלב 41 (המצעד בברזיליה). MARSHAL = בוס נייח על יציע הכבוד
	LOADER, FLAMER, PIONEER, ARMORED_TRAIN, # שלב 42 (המטרו של ברזיליה). ARMORED_TRAIN = בוס נייח (קטר משוריין)
	WELDER, TANKETTE, FOREMAN, PROTOTYPE, # שלב 43 (מפעל המלחמה בוולטה רדונדה). PROTOTYPE = בוס נייח (טנק-על)
	PARATROOPER, MORTARMAN, STORMTROOPER, RED_ZEPPELIN, # שלב 44 (סכר איטאיפו). RED_ZEPPELIN = בוס מרחף
	PRAETORIAN, COMMISSAR, HERALD, EMPEROR, # שלב 45 (הארמון האדום בפטרופוליס). EMPEROR = הבוס האחרון של האימפריה
	EXECUTIONER, HARVESTER, CASK,  # שלב 46 (עמק היין - מנדוסה). EXECUTIONER = גם הבוס (THE HEADSMAN)
	TORO, BOLEADOR, STORMCALLER,   # שלב 47 (סערה בפמפס). TORO = גם הבוס (EL TORO)
	IRONARMS, TANGO, CLOCKWORK,    # שלב 48 (הרובע הישן - בואנוס איירס). IRONARMS = גם הבוס (THE MACHINIST)
	FLOATER, ANGLER, SPOREWALKER,  # שלב 49 (הדלתא - טיגרה). FLOATER = גם הבוס
	PUPPETEER, LOBIZON, COFFIN_BREAKER,   # שלב 50 (בית הקברות - רקולטה). PUPPETEER = גם הבוס
	RIDER, BEEKEEPER, BRANDER,     # שלב 51 (החווה). RIDER = גם הבוס
	HAULER, QUISLING, STRAGGLER,   # שלב 52 (מגרש הרכבות). HAULER = גם הבוס (THE ENGINE)
	STACKER, BABBLER, PURSUER,     # שלב 53 (המצור על הבירה - מונטווידאו). STACKER = גם הבוס (THE SIEGE TOWER)
	SHEPHERD, STINGER, DARKSEEKER, # שלב 54 (הגשר האחרון). SHEPHERD = גם הבוס (THE ARCHITECT)
	SHEARER, DRIFTER, TUMBLER,     # שלב 55 (ערבת הרוח - פטגוניה). SHEARER = גם הבוס (THE ESTANCIERO)
	THAWED, BUOY, SEALER,          # שלב 56 (פיורד הקרח). THAWED = גם הבוס (THE GLACIER)
	WADDLER, MURMUR, BLUBBER,      # שלב 57 (חוף הפינגווינים). WADDLER = גם הבוס (THE BEACHMASTER)
	FLENSER, SKUA, BONECRAWLER,    # שלב 58 (בית הקברות של הלווייתנים). FLENSER = גם הבוס (THE BONE KING)
	CHARRED, ASHMOTH, DAMBUILDER,  # שלב 59 (היער השחור). CHARRED = גם הבוס (THE PYRE)
	SPECIMEN, BLOOM, WARDEN,       # שלב 60 (מעבדת הקרחון). SPECIMEN = גם הבוס (SUBJECT FOUR)
	BONESIDE, CONDOR, THRONG,      # שלב 61 (סוף העולם - אושואיה). BONESIDE = גם הבוס
	SEEPER, SYNAPSE, REMNANT,      # שלב 62 (מוח הכוורת - ה-ROOT). SEEPER = גם הבוס
	HOLLOW, PILGRIM, ROOT,         # שלב 63 (הסוף). ROOT = הבוס האחרון של המשחק
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
	AZUFRERO: "res://enemies/types/azufrero.gd",
	CINDER: "res://enemies/types/cinder.gd",
	SMOKER: "res://enemies/types/smoker.gd",
	REVIVER: "res://enemies/types/reviver.gd",
	SPOTTER: "res://enemies/types/spotter.gd",
	PANEL: "res://enemies/types/panel.gd",
	DISH: "res://enemies/types/dish.gd",
	ENCASED: "res://enemies/types/encased.gd",
	AXEMAN: "res://enemies/types/axeman.gd",
	AVALANCHER: "res://enemies/types/avalancher.gd",
	ICE_TITAN: "res://enemies/types/ice_titan.gd",
	MALLKI: "res://enemies/types/mallki.gd",
	GUARDIAN: "res://enemies/types/guardian.gd",
	QUIPU: "res://enemies/types/quipu.gd",
	APU: "res://enemies/types/apu.gd",
	KITE: "res://enemies/types/kite.gd",
	CAPOEIRA: "res://enemies/types/capoeira.gd",
	GRAFFITI: "res://enemies/types/graffiti.gd",
	DONO: "res://enemies/types/dono.gd",
	OFFICE: "res://enemies/types/office.gd",
	WASHER: "res://enemies/types/washer.gd",
	COURIER: "res://enemies/types/courier.gd",
	TOWER: "res://enemies/types/tower.gd",
	HOOLIGAN: "res://enemies/types/hooligan.gd",
	STRIKER: "res://enemies/types/striker.gd",
	REFEREE: "res://enemies/types/referee.gd",
	GOALKEEPER: "res://enemies/types/goalkeeper.gd",
	CONSCRIPT: "res://enemies/types/conscript.gd",
	OFFICER: "res://enemies/types/officer.gd",
	FLAGBEARER: "res://enemies/types/flagbearer.gd",
	BEHEMOTH: "res://enemies/types/behemoth.gd",
	DRUMMER: "res://enemies/types/drummer.gd",
	GUARDSMAN: "res://enemies/types/guardsman.gd",
	PROPAGANDIST: "res://enemies/types/propagandist.gd",
	MARSHAL: "res://enemies/types/marshal.gd",
	LOADER: "res://enemies/types/loader.gd",
	FLAMER: "res://enemies/types/flamer.gd",
	PIONEER: "res://enemies/types/pioneer.gd",
	ARMORED_TRAIN: "res://enemies/types/armored_train.gd",
	WELDER: "res://enemies/types/welder.gd",
	TANKETTE: "res://enemies/types/tankette.gd",
	FOREMAN: "res://enemies/types/foreman.gd",
	PROTOTYPE: "res://enemies/types/prototype.gd",
	PARATROOPER: "res://enemies/types/paratrooper.gd",
	MORTARMAN: "res://enemies/types/mortarman.gd",
	STORMTROOPER: "res://enemies/types/stormtrooper.gd",
	RED_ZEPPELIN: "res://enemies/types/red_zeppelin.gd",
	PRAETORIAN: "res://enemies/types/praetorian.gd",
	COMMISSAR: "res://enemies/types/commissar.gd",
	HERALD: "res://enemies/types/herald.gd",
	EMPEROR: "res://enemies/types/emperor.gd",
	EXECUTIONER: "res://enemies/types/executioner.gd",
	HARVESTER: "res://enemies/types/harvester.gd",
	CASK: "res://enemies/types/cask.gd",
	TORO: "res://enemies/types/toro.gd",
	BOLEADOR: "res://enemies/types/boleador.gd",
	STORMCALLER: "res://enemies/types/stormcaller.gd",
	IRONARMS: "res://enemies/types/ironarms.gd",
	TANGO: "res://enemies/types/tango.gd",
	CLOCKWORK: "res://enemies/types/clockwork.gd",
	FLOATER: "res://enemies/types/floater.gd",
	ANGLER: "res://enemies/types/angler.gd",
	SPOREWALKER: "res://enemies/types/sporewalker.gd",
	PUPPETEER: "res://enemies/types/puppeteer.gd",
	LOBIZON: "res://enemies/types/lobizon.gd",
	COFFIN_BREAKER: "res://enemies/types/coffin_breaker.gd",
	RIDER: "res://enemies/types/rider.gd",
	BEEKEEPER: "res://enemies/types/beekeeper.gd",
	BRANDER: "res://enemies/types/brander.gd",
	HAULER: "res://enemies/types/hauler.gd",
	QUISLING: "res://enemies/types/quisling.gd",
	STRAGGLER: "res://enemies/types/straggler.gd",
	STACKER: "res://enemies/types/stacker.gd",
	BABBLER: "res://enemies/types/babbler.gd",
	PURSUER: "res://enemies/types/pursuer.gd",
	SHEPHERD: "res://enemies/types/shepherd.gd",
	STINGER: "res://enemies/types/stinger.gd",
	DARKSEEKER: "res://enemies/types/darkseeker.gd",
	SHEARER: "res://enemies/types/shearer.gd",
	DRIFTER: "res://enemies/types/drifter.gd",
	TUMBLER: "res://enemies/types/tumbler.gd",
	THAWED: "res://enemies/types/thawed.gd",
	BUOY: "res://enemies/types/buoy.gd",
	SEALER: "res://enemies/types/sealer.gd",
	WADDLER: "res://enemies/types/waddler.gd",
	MURMUR: "res://enemies/types/murmur.gd",
	BLUBBER: "res://enemies/types/blubber.gd",
	FLENSER: "res://enemies/types/flenser.gd",
	SKUA: "res://enemies/types/skua.gd",
	BONECRAWLER: "res://enemies/types/bonecrawler.gd",
	CHARRED: "res://enemies/types/charred.gd",
	ASHMOTH: "res://enemies/types/ashmoth.gd",
	DAMBUILDER: "res://enemies/types/dambuilder.gd",
	SPECIMEN: "res://enemies/types/specimen.gd",
	BLOOM: "res://enemies/types/bloom.gd",
	WARDEN: "res://enemies/types/warden.gd",
	BONESIDE: "res://enemies/types/boneside.gd",
	CONDOR: "res://enemies/types/condor.gd",
	THRONG: "res://enemies/types/throng.gd",
	SEEPER: "res://enemies/types/seeper.gd",
	SYNAPSE: "res://enemies/types/synapse.gd",
	REMNANT: "res://enemies/types/remnant.gd",
	HOLLOW: "res://enemies/types/hollow.gd",
	PILGRIM: "res://enemies/types/pilgrim.gd",
	ROOT: "res://enemies/types/root.gd",
}

static var _stats_cache := {}


static func has(kind: int) -> bool:
	return TYPES.has(kind) and ResourceLoader.exists(TYPES[kind])


# יוצר את המודול של הסוג (או null)
static func make(kind: int) -> RefCounted:
	if not has(kind):
		return null
	var sc: Script = load(TYPES[kind])
	preload("res://sfx.gd").register_script(sc)   # הצלילים שלו (sfx.gd לא טוען את כל הסוגים בפתיחה)
	return sc.new()


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
