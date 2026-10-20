extends RefCounted
# ============================================================
#  ZOMBIE MIX - זומבים חוזרים בשלבים אחרים (2026-10-20).
#  "Most zombies appear in only one level, so there's nothing to master":
#    * זומבי שהופיע לראשונה בשלב N חוזר בשלבים N+1 ו-N+2, בפחות (NEXT_K מהמשקל).
#    * וחוזר עוד 1-2 פעמים בשלבים מאוחרים יותר "באקראי" (GUEST_K). האקראיות קבועה לכל סוג
#      (seed לפי הסוג), כך שכל זומבי חוזר בדיוק באותם 1-2 שלבים בכל משחק - אפשר לבדוק ולתכנן.
#  main.gd קורא ל-mix() אחרי zombie_weights() של השלב.
#  INTRO = הזומבים החדשים של כל שלב והמשקל שלהם שם (נוצר מ-levels/stage_N.gd -> zombie_weights).
#  STAY_HOME = סוגים שצריכים את השלב שלהם (מים, צוקים, גפנים...) - לא חוזרים בשלבים אחרים.
#  שלב בלי זומבי רגיל (0) במשקלים (למשל 16 = רק נחילים) לא מקבל אורחים.
# ============================================================
const R := preload("res://enemies/zombie_registry.gd")

const NEXT_K := [0.5, 0.25]     # שלב אחד אחרי / שניים אחרי: חצי ורבע מהמשקל
const GUEST_K := 0.5            # אורח בשלב מאוחר
const GUESTS := Vector2i(1, 2)  # בכמה שלבים מאוחרים כל זומבי חוזר
const LAST_LEVEL := 63

const INTRO := {
	5: {R.CLIMBER: 0.18, R.SCOUT: 0.1},
	6: {R.STALKER: 0.15, R.WALL_CRAWLER: 0.12, R.GRABBER: 0.11, R.PACK_LEADER: 0.03},
	7: {R.AMBUSHER: 0.14, R.TACTICIAN: 0.06, R.SHIELDED: 0.14, R.LEAPER: 0.16, R.ENGINEER: 0.06},
	8: {R.ADAPTOR: 0.22, R.DODGER: 0.2, R.HUNTER: 0.1, R.SIREN: 0.06},
	9: {R.HUNTER_ELITE: 0.14, R.SHIELD_ELITE: 0.14, R.INFECTOR: 0.1, R.COMMANDER: 0.06},
	10: {R.BLOODGATE: 0.22, R.KRAKEN: 0.2, R.LIVEWIRE: 0.14},
	11: {R.DEVOURER: 0.18, R.SPLITJAW: 0.2},
	12: {R.MIMIC: 0.08, R.IRONWING: 0.16, R.SPARE_PARTS: 0.2},
	13: {R.GRAVEBORN: 0.22, R.SANDBLASTER: 0.2},
	14: {R.CRUMBLER: 0.26, R.RETCHER: 0.12},
	15: {R.BOMBHEAD: 0.22, R.MINIGUNNER: 0.12, R.STILTER: 0.22},
	16: {R.SWARMER: 1.0},
	17: {R.MIRAGE: 0.28},
	18: {R.DRILLER: 0.16, R.UZI: 0.2},
	19: {R.SWINGER: 0.2, R.BLADES: 0.16},
	20: {R.GHILLIE: 0.24},
	21: {R.GLIDER: 0.22, R.REVOLVER: 0.16},
	22: {R.GOLIATH: 0.07, R.HARPOONER: 0.2},
	23: {R.BIKER: 0.12, R.SHOVER: 0.12},
	24: {R.TORCH: 0.13, R.SCARECROW: 0.06},
	25: {R.SIGNALER: 0.1, R.ROD: 0.1},
	26: {R.HAZMAT: 0.1, R.BLACKOUT: 0.07, R.VENT: 0.09},
	27: {R.SAPPER: 0.1, R.HANDLER: 0.07, R.SNIPER: 0.04},
	28: {R.CLINGER: 0.08, R.BOULDER: 0.08},
	29: {R.ECHO: 0.13, R.DYNAMITER: 0.1},
	30: {R.FROSTBITE: 0.14, R.BELLRINGER: 0.05},
	31: {R.DROWNED: 0.12, R.NETTER: 0.06},
	32: {R.DIABLO: 0.14, R.MORENADA: 0.07, R.BANDLEADER: 0.03},
	33: {R.AZUFRERO: 0.09, R.CINDER: 0.1, R.SMOKER: 0.05},
	34: {R.REVIVER: 0.05, R.SPOTTER: 0.05, R.PANEL: 0.08},
	35: {R.ENCASED: 0.04, R.AXEMAN: 0.07, R.AVALANCHER: 0.03},
	36: {R.MALLKI: 0.05, R.GUARDIAN: 0.06, R.QUIPU: 0.02},
	37: {R.KITE: 0.04, R.CAPOEIRA: 0.05, R.GRAFFITI: 0.04},
	38: {R.OFFICE: 0.05, R.WASHER: 0.03, R.COURIER: 0.04},
	39: {R.HOOLIGAN: 0.06, R.STRIKER: 0.04, R.REFEREE: 0.02},
	40: {R.CONSCRIPT: 0.12, R.OFFICER: 0.02, R.FLAGBEARER: 0.02},
	41: {R.GUARDSMAN: 0.05, R.DRUMMER: 0.02, R.PROPAGANDIST: 0.02},
	42: {R.FLAMER: 0.03, R.PIONEER: 0.02, R.LOADER: 0.02},
	43: {R.WELDER: 0.03, R.TANKETTE: 0.02, R.FOREMAN: 0.01},
	44: {R.STORMTROOPER: 0.03, R.MORTARMAN: 0.015, R.PARATROOPER: 0.02},
	45: {R.PRAETORIAN: 0.03, R.COMMISSAR: 0.015, R.HERALD: 0.015},
	46: {R.EXECUTIONER: 0.03, R.HARVESTER: 0.05, R.CASK: 0.04},
	47: {R.BOLEADOR: 0.08, R.STORMCALLER: 0.05, R.TORO: 0.025},
	48: {R.IRONARMS: 0.03, R.TANGO: 0.02, R.CLOCKWORK: 0.05},
	49: {R.FLOATER: 0.04, R.ANGLER: 0.03, R.SPOREWALKER: 0.05},
	50: {R.PUPPETEER: 0.02, R.LOBIZON: 0.035, R.COFFIN_BREAKER: 0.04},
	51: {R.BRANDER: 0.07, R.BEEKEEPER: 0.05, R.RIDER: 0.03},
	52: {R.STRAGGLER: 0.05, R.HAULER: 0.035, R.QUISLING: 0.02},
	53: {R.STACKER: 0.09, R.BABBLER: 0.04},
	54: {R.SHEPHERD: 0.02, R.STINGER: 0.05, R.DARKSEEKER: 0.05},
	55: {R.SHEARER: 0.03, R.DRIFTER: 0.035, R.TUMBLER: 0.05},
	56: {R.THAWED: 0.045, R.BUOY: 0.03, R.SEALER: 0.03},
	57: {R.WADDLER: 0.03, R.MURMUR: 0.025, R.BLUBBER: 0.03},
	58: {R.FLENSER: 0.04, R.SKUA: 0.02, R.BONECRAWLER: 0.02},
	59: {R.CHARRED: 0.045, R.ASHMOTH: 0.015, R.DAMBUILDER: 0.025},
	60: {R.SPECIMEN: 0.035, R.BLOOM: 0.015, R.WARDEN: 0.01},
	61: {R.BONESIDE: 0.035, R.THRONG: 0.03, R.CONDOR: 0.006},
	62: {R.SEEPER: 0.04, R.REMNANT: 0.012},
	63: {R.HOLLOW: 0.07},
}

const STAY_HOME := [
	R.SWARMER,                        # שלב 16 = שלב של נחילים בלבד
	R.DROWNED, R.ANGLER, R.SEALER,    # צריכים מים / חורים בקרח
	R.SWINGER, R.CLINGER, R.VENT, R.SCARECROW,   # צריכים צמרת עצים / שפת צוק / תעלות אוורור / עמודי דחליל
	R.DRIFTER, R.TUMBLER, R.BUOY,     # צריכים את הרוח של השלב שלהם
	R.SKUA, R.CONDOR,                 # צריכים תרנים / זרמי אוויר חם (בשלב אחר הם נעלמים)
]


# משקלי השלב + הזומבים שחוזרים. רק מוסיף - לא משנה את מה שהשלב ביקש
static func mix(level: int, w: Dictionary) -> Dictionary:
	if not w.has(0):
		return w
	var out := w.duplicate()
	var ref := 0.0   # המשקל של הזומבי החדש הכי נפוץ בשלב הזה (שהחוזרים לא יעקפו אותו)
	for k in w:
		if int(k) >= R.FIRST:
			ref = maxf(ref, float(w[k]))
	if ref <= 0.0:
		ref = 0.05
	for src in extras(level):
		var k: int = src[0]
		if not out.has(k):
			out[k] = minf(float(src[1]), ref) * float(src[2])
	return out


# [[סוג, משקל מקורי, מקדם], ...] - מי חוזר לשלב הזה
static func extras(level: int) -> Array:
	var res := []
	for from_lv in INTRO:
		var d: int = level - int(from_lv)
		if d <= 0:
			continue
		for k in INTRO[from_lv]:
			if k in STAY_HOME:
				continue
			if d <= NEXT_K.size():
				res.append([k, INTRO[from_lv][k], NEXT_K[d - 1]])
			elif level in guest_levels(k, int(from_lv)):
				res.append([k, INTRO[from_lv][k], GUEST_K])
	return res


# 1-2 שלבים מאוחרים (אחרי N+2) שבהם הסוג הזה חוזר. קבוע לכל סוג
static func guest_levels(kind: int, from_lv: int) -> Array:
	var first := from_lv + NEXT_K.size() + 1
	if first > LAST_LEVEL:
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = kind * 7919 + 104729
	var n := rng.randi_range(GUESTS.x, GUESTS.y)
	var res := []
	for i in 12:
		if res.size() >= n:
			break
		var lv := rng.randi_range(first, LAST_LEVEL)
		if not lv in res:
			res.append(lv)
	return res
