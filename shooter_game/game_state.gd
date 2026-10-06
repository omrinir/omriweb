extends Node
# ============================================================
#  מצב המשחק (Autoload בשם Game - זמין מכל מקום):
#  * ניקוד, קומבו (מכפיל), סטטיסטיקות של השלב
#  * שלבים, נקודות SCRAP ושדרוגים בין שלבים
#  * גביעים (Trophies) ושיאים - נשמרים בקובץ
#  * רעש: יריות ופיצוצים מעירים זומבים
# ============================================================

signal score_changed
signal trophy_unlocked(id: String)
# אירועי "סיפור" לשחקן שמדבר לעצמו (ui/monologue.gd). כולם שולחים, רק מי שמאזין משתמש:
#   zhit, zkill, wake, notice, phurt, reload, grenade, dodge, ambush, flank_jump, cover, adapt, call, squad, thunder...
signal story(event: String, info: Dictionary)

const SAVE_PATH := "user://progress.cfg"

# ---------------- גביעים ----------------
const TROPHIES := [
	{"id": "headhunter", "name": "HEADHUNTER", "desc": "10 headshots in a row"},
	{"id": "chain", "name": "CHAIN REACTION", "desc": "Kill 4 zombies with one barrel"},
	{"id": "merciful", "name": "MERCIFUL", "desc": "Finish a level without draining anyone"},
	{"id": "soul_eater", "name": "SOUL EATER", "desc": "Drain 3 survivors in one level"},
	{"id": "untouchable", "name": "UNTOUCHABLE", "desc": "Finish a level without losing a heart"},
	{"id": "leg_day", "name": "LEG DAY", "desc": "Sever 20 zombie legs"},
	{"id": "hard_boiled", "name": "HARD BOILED", "desc": "Finish a level on HARD"},
	{"id": "return", "name": "RETURN TO SENDER", "desc": "Shoot a thrown leg out of the air"},
]

# ---------------- שדרוגים ----------------
# השדרוגים עצמם: progression/upgrade_db.gd (נשקים, יכולות, PERKS). כאן רק המצב השמור:
#   upgrades = {"w.<weapon id>.<track>": רמה, "a.<ability id>.<track>": רמה, "p.<perk>": רמה}
#   seen_weapons = נשקים שהשחקן מצא פעם (רק אותם אפשר לשדרג)
const Upgrades := preload("res://progression/upgrade_db.gd")
var seen_weapons := [0]
# השדרוגים הישנים (הוסרו) - מי שקנה אותם מקבל את הגרוטאות בחזרה
const OLD_UPGRADES := {"fire_rate": [40, 80, 140], "ammo": [40, 70, 110], "grenades": [60, 120], "siphon": [80, 150], "boost_time": [50, 100], "laser": [70]}


# ---------------- ניקוד ----------------
const KILL_POINTS := [100, 120, 200, 150, 150, 2000, 160, 3000, 140, 180, 20, 120, 250, 300, 80, 120, 150, 220, 260, 4000]   # לפי סוג זומבי
const COMBO_WINDOW := 4.0                               # שניות בין הריגות כדי שהקומבו ימשיך

# מצב הריצה (נשמר בין שלבים, מתאפס במשחק חדש)
var level := 1
# ---- נשקים: 5 מקומות, לכל נשק תחמושת משלו (נשמר בין שלבים) ----
# הנשקים מוגדרים ב-weapons/weapon_db.gd. כאן רק עמודות נוחות (Game.WEAPON_NAMES[id] וכו')
const WeaponDB := preload("res://weapons/weapon_db.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
var WEAPON_NAMES: Array = WeaponDB.column("name")
var WEAPON_COLORS: Array = WeaponDB.column("color")
var AMMO_START: Array = WeaponDB.column("ammo_start", 10)   # תחמושת כשמוצאים את הנשק
var AMMO_BOX: Array = WeaponDB.column("ammo_box", 2)        # כמה כל קופסת תחמושת נותנת לכל נשק
var AMMO_MAX: Array = WeaponDB.column("ammo_max", 20)
var weapon_slots := [{"id": 0, "ammo": 30}, null, null, null, null]
var ability_slots := [null, null, null, null, null]   # בקרוב
var player_dark := false   # השחקן בחושך (ברכבת התחתית) - זומבים רואים אותו פחות
var run_score := 0
var scrap := 0
var upgrades := {}
var _level_start_score := 0
var _level_start_scrap := 0

# מצב השלב
var level_score := 0
var combo := 0
var combo_t := 0.0
var stats := {}
var _bullet_kills := {}
var _blast_kills := {}
var _head_streak := 0
# ---- דירוג סטייל (D C B A S) ----
var style := 0.0
var player_move := "ground"      # player.gd מעדכן: ground / air / slide / roll
var _last_styles := []
const STYLE_RANKS := ["D", "C", "B", "A", "S"]

# נשמר לתמיד
var trophies := {}
var high_scores := [0, 0, 0]
var lifetime := {"legs": 0, "kills": 0, "headshots": 0}

var _banner: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_migrate_old_upgrades()
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_banner = TrophyBanner.new()
	layer.add_child(_banner)
	reset_level()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	style = maxf(style - 6.0 * delta / maxf(Engine.time_scale, 0.01), 0.0)
	if combo > 0:
		combo_t -= delta / maxf(Engine.time_scale, 0.01)
		if combo_t <= 0.0:
			combo = 0
			score_changed.emit()


# ============================================================
#  ריצה / שלב
# ============================================================
# שלבים זוגיים = רכבת תחתית
# העולמות מתחלפים: 0 = רחוב, 1 = רכבת תחתית, 2 = מפעל
# איזה עולם בכל שלב: 0 רחוב, 1 רכבת תחתית, 2 מפעל, 3 רחוב בלילה עם גשם
const LEVEL_WORLD := {1: 0, 2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 6, 8: 7, 9: 8, 10: 9, 11: 10, 12: 11, 13: 12}   # 4-8 = עולמות של שלבים 5-9 (levels/stage_N.gd)
func world() -> int:
	return LEVEL_WORLD.get(level, (level - 1) % 4)


func is_street() -> bool:
	return world() == 0 or world() == 3


func is_night() -> bool:
	return world() == 3


func is_subway() -> bool:
	return world() == 1


func is_factory() -> bool:
	return world() == 2


# ============================================================
#  מפה: 7 אזורים, 9 שלבים בכל אזור (כרגע 3 השלבים הראשונים קיימים)
# ============================================================
const LEVELS_PER_REGION := 9
const IMPLEMENTED := 15           # כמה שלבים כבר בנויים
const REGIONS := [
	{"name": "NORTHERN AMAZON", "color": Color(0.45, 0.85, 0.3), "desc": "Where it started. The first ones only hunger.",
		"levels": ["Fallen City", "The Red Line", "Rust Works", "River of Teeth", "Ruined District", "Highrise", "The Works", "Research Site", "Zone Zero"]},
	{"name": "NORTHEAST", "color": Color(1.0, 0.8, 0.25), "desc": "Sun, salt and sand. They learned to wait in the heat.",
		"levels": ["Salt Flats", "Sun-Bleached Town", "The Lighthouse", "Dunes of Bone", "Fishermen's Grave", "Carnival of the Dead", "Old Fort", "The Dry River", "Cathedral of Ash"]},
	{"name": "CENTRAL PLATEAU", "color": Color(0.35, 0.65, 1.0), "desc": "Endless roads. They learned to hunt in packs.",
		"levels": ["Savanna Road", "Cattle Ghosts", "Glass Capital", "The Dam", "Highway 7", "Burning Fields", "Radio Tower", "The Bunker", "Plateau Gate"]},
	{"name": "ANDES", "color": Color(0.78, 0.5, 1.0), "desc": "Thin air, deep mines. They learned to climb.",
		"levels": ["Cloud Pass", "Mine of Echoes", "Frozen Village", "Condor Peak", "Lost Temple", "Avalanche Road", "Observatory", "Skull Glacier", "The Summit"]},
	{"name": "SOUTHEAST", "color": Color(1.0, 0.55, 0.2), "desc": "The megacities. They learned to use our machines.",
		"levels": ["Favela Heights", "Megacity Core", "The Stadium", "Harbor Cranes", "Neon District", "Metro Labyrinth", "The Skyscraper", "The Lab", "Patient Zero"]},
	{"name": "SOUTHERN CONE", "color": Color(0.25, 0.9, 0.75), "desc": "Plains and old cities. They learned to plan.",
		"levels": ["Wine Valley", "Pampas Storm", "Old Quarter", "River Delta", "Tango Cemetery", "The Ranch", "Rail Yard", "Capital Siege", "Last Bridge"]},
	{"name": "PATAGONIA", "color": Color(1.0, 0.4, 0.35), "desc": "The end of the world. They learned to think.",
		"levels": ["Wind Steppe", "Ice Fjord", "Penguin Coast", "Whale Graveyard", "Black Forest", "Glacier Lab", "End of the World", "The Hive Mind", "They Learned"]},
]
var completed := {}               # שלב -> כוכבים (1-3)
var level_best := {}              # שלב -> ניקוד הכי טוב


func region_of(lv: int) -> int:
	return (lv - 1) / LEVELS_PER_REGION


func level_name(lv: int) -> String:
	var r := region_of(lv)
	if r < 0 or r >= REGIONS.size():
		return "LEVEL %d" % lv
	return REGIONS[r].levels[(lv - 1) % LEVELS_PER_REGION]


func region_done(r: int) -> int:
	var n := 0
	for i in LEVELS_PER_REGION:
		if completed.has(r * LEVELS_PER_REGION + i + 1):
			n += 1
	return n


# אזור נפתח רק אחרי שמסיימים את כל השלבים של האזור הקודם
func region_unlocked(r: int) -> bool:
	return r == 0 or (r < REGIONS.size() and region_done(r - 1) >= LEVELS_PER_REGION)


func level_unlocked(lv: int) -> bool:
	return region_unlocked(region_of(lv)) and ((lv - 1) % LEVELS_PER_REGION == 0 or completed.has(lv - 1))


func level_playable(lv: int) -> bool:
	return level_unlocked(lv) and lv <= IMPLEMENTED


# מתחילים שלב מהמפה (הנשקים, השדרוגים והגרוטאות נשמרים)
func start_level(lv: int) -> void:
	level = lv
	run_score = 0
	level_score = 0
	combo = 0
	_level_start_score = 0
	_level_start_scrap = scrap


# ---- שמירה לקובץ (אפשר להוריד למחשב ולטעון בחזרה) ----
func save_dict() -> Dictionary:
	var comp := {}
	for k in completed:
		comp[str(k)] = completed[k]
	var best := {}
	for k in level_best:
		best[str(k)] = level_best[k]
	return {"game": "THEY LEARN", "version": 1, "completed": comp, "level_best": best, "weapon_slots": weapon_slots,
		"scrap": scrap, "upgrades": upgrades, "seen_weapons": seen_weapons, "ability_slots": ability_slots, "trophies": trophies, "high_scores": high_scores, "lifetime": lifetime,
		"difficulty": Settings.difficulty}


func load_dict(d: Dictionary) -> bool:
	if d.get("game", "") != "THEY LEARN":
		return false
	completed.clear()
	for k in d.get("completed", {}):
		completed[int(k)] = int(d.completed[k])
	level_best.clear()
	for k in d.get("level_best", {}):
		level_best[int(k)] = int(d.level_best[k])
	var ws = d.get("weapon_slots", null)
	if ws is Array and ws.size() == 5:
		weapon_slots = []
		for s in ws:
			weapon_slots.append(null if s == null else {"id": int(s.id), "ammo": int(s.ammo)})
	scrap = int(d.get("scrap", scrap))
	var up = d.get("upgrades", {})
	for k in up:
		upgrades[k] = int(up[k])
	var sw = d.get("seen_weapons", [])
	for w in sw:
		mark_weapon_seen(int(w))
	var asl = d.get("ability_slots", [])
	if asl is Array and asl.size() == 5:
		ability_slots = asl.duplicate()
	var tr = d.get("trophies", {})
	if tr is Dictionary:
		trophies = tr
	var hs = d.get("high_scores", [])
	if hs is Array and hs.size() == 3:
		high_scores = [int(hs[0]), int(hs[1]), int(hs[2])]
	var lt = d.get("lifetime", {})
	for k in lt:
		lifetime[k] = int(lt[k])
	Settings.difficulty = int(d.get("difficulty", Settings.difficulty))
	_save()
	return true


func export_save(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(save_dict(), "  "))
	return true


func import_save(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	return d is Dictionary and load_dict(d)


# THEY LEARN: בכל שלב הזומבים לומדים משהו חדש
const LEVEL_TITLES := [
	["THEY HUNGER", "They only want to eat. For now."],
	["THEY HIDE", "They learned the dark. They learned to wait."],
	["THEY BUILD", "They learned to use machines. And each other."],
	["THEY HUNT", "They learned to hunt in packs. And to shoot back."],
	["THE CITY REMEMBERS", "They learned to call each other."],
	["NO SAFE FLOOR", "They learned to hide. And to climb."],
	["THEY WATCH", "They learned the machines. They learned your habits."],
	["THEY ADAPT", "They learned your weapons."],
	["THEY LEARN", "At first I was fighting zombies. Now the zombies are fighting ME."],
	["THEY BLEED WITH PURPOSE", "They learned that a wound can be a door."],
	["THEY HUNGER TOGETHER", "They learned to eat each other. And to play dead."],
	["THEY WEAR OUR FACES", "Not everyone who calls for help is still human."],
	["THEY RISE FROM THE SAND", "They learned to wait beneath you."],
	["THEY KNOW YOUR VOICE", "Out here, the only one talking is you. For now."],
	["THEY DANCE WITH DEATH", "The carnival never ended. It just changed partners."],
]
func level_title() -> Array:
	var t: Array = LEVEL_TITLES[(level - 1) % LEVEL_TITLES.size()].duplicate()
	if level > LEVEL_TITLES.size():
		t[0] += " " + ["II", "III", "IV", "V"][mini((level - 1) / LEVEL_TITLES.size() - 1, 3)]
	return t


# כמה הזומבים "חכמים" בשלב הזה (מתכופפים, מתחבאים, מכוונים לאן שאתה הולך)
func intelligence() -> float:
	return 1.0 + 0.25 * float(level - 1)


func new_run() -> void:
	level = 1
	PlayerMemory.new_run()   # ריצה חדשה: הזומבים "שוכחים" את השחקן
	weapon_slots = [{"id": 0, "ammo": 30}, null, null, null, null]
	run_score = 0
	scrap = 0
	upgrades.clear()
	seen_weapons = [0]
	ability_slots = [null, null, null, null, null]
	_level_start_score = 0
	_level_start_scrap = 0


func reset_level() -> void:
	PlayerMemory.on_level_start()
	level_score = 0
	combo = 0
	combo_t = 0.0
	style = 0.0
	_bullet_kills.clear()
	_blast_kills.clear()
	stats = {"kills": 0, "headshots": 0, "shots": 0, "hits": 0, "drained": 0, "spared": 0,
		"hearts_lost": 0, "time": 0.0, "survivors": 0}
	Engine.time_scale = 1.0


# TRY AGAIN: חוזרים לתחילת השלב (בלי הניקוד שהרווחנו בו)
func restart_level() -> void:
	run_score = _level_start_score
	scrap = _level_start_scrap
	reset_level()


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


# שדרוגים ישנים -> החזר גרוטאות (פעם אחת)
func _migrate_old_upgrades() -> void:
	var refund := 0
	for k in upgrades.keys():
		if OLD_UPGRADES.has(k):
			var costs: Array = OLD_UPGRADES[k]
			for i in mini(int(upgrades[k]), costs.size()):
				refund += int(costs[i])
			upgrades.erase(k)
	if refund > 0:
		scrap += refund
		_save()


# השלב הכי רחוק שהשחקן הגיע אליו (יכולות נפתחות לפי זה - גם כשמשחקים שוב שלב מוקדם)
func reached_level() -> int:
	var r := level
	for k in completed:
		r = maxi(r, int(k) + 1)
	return r


# הנשק נמצא (נפתח לשדרוג בחנות)
func mark_weapon_seen(id: int) -> void:
	if not id in seen_weapons:
		seen_weapons.append(id)


func style_rank() -> int:
	return clampi(int(style / 20.0), 0, 4)


# סטייל עולה על הריגות מגוונות, ויורד כשחוזרים על אותו דבר
func on_style(kind: String, amount: float) -> void:
	var n := _last_styles.count(kind)
	style = minf(style + amount / (1.0 + float(n)), 100.0)
	_last_styles.append(kind)
	if _last_styles.size() > 4:
		_last_styles.pop_front()


func multiplier() -> int:
	if combo >= 15: return 5
	if combo >= 10: return 4
	if combo >= 6: return 3
	if combo >= 3: return 2
	return 1


func add_score(points: int) -> void:
	level_score += int(points * multiplier() * (1.0 + 0.25 * style_rank()))   # S = +100%
	score_changed.emit()


# ============================================================
#  אירועים מהמשחק
# ============================================================
func on_shot() -> void:
	stats.shots += 1


# info: zone, explosive, source ("bullet" / "grenade" / "barrel" / "car" / "fire"), bullet, blast, hidden
func on_zombie_hit(info: Dictionary) -> void:
	if info.get("source", "") == "bullet" and not info.get("counted", false):
		stats.hits += 1
	if info.get("source", "") == "bullet":
		if info.get("zone", "") == "head":
			_head_streak += 1
			if _head_streak >= 10:
				unlock("headhunter")
		else:
			_head_streak = 0


# מחזיר רשימת בונוסים [טקסט, נקודות] כדי שהזומבי יציג אותם
func on_zombie_killed(kind: int, info: Dictionary) -> Array:
	var bonuses := []
	combo += 1
	combo_t = COMBO_WINDOW
	stats.kills += 1
	lifetime.kills += 1
	var pts: int = Registry.points(kind) if kind >= Registry.FIRST else KILL_POINTS[clampi(kind, 0, KILL_POINTS.size() - 1)]
	if info.get("zone", "") == "head":
		stats.headshots += 1
		lifetime.headshots += 1
		bonuses.append(["HEADSHOT", 50])
	if info.get("hidden", false):
		bonuses.append(["FLUSHED OUT", 75])
	if info.get("perfect", false):
		bonuses.append(["PERFECT", 100])
	# בונוס תנועה: הריגה באוויר / בהחלקה / בגלגול שווה יותר
	var mv := player_move
	if info.get("source", "") == "stomp":
		bonuses.append(["STOMP", 100])
		on_style("stomp", 22)
	elif mv == "air":
		bonuses.append(["AIR KILL", 100])
		on_style("air", 18)
	elif mv == "slide" or mv == "roll":
		bonuses.append(["SLIDE KILL" if mv == "slide" else "ROLL KILL", 100])
		on_style(mv, 18)
	else:
		on_style("ground_" + str(info.get("zone", "")), 8)
	if info.get("perfect", false):
		on_style("perfect", 15)
	var src: String = info.get("source", "")
	if src == "barrel" or src == "car" or src == "bloater" or src == "jet" or src == "mech":
		bonuses.append(["BOOM", 75])
	if src == "fire":
		bonuses.append(["ROASTED", 40])
	# כמה זומבים הרג אותו קליע / אותו פיצוץ
	var bid: int = info.get("bullet", 0)
	if bid != 0:
		_bullet_kills[bid] = int(_bullet_kills.get(bid, 0)) + 1
		var n: int = _bullet_kills[bid]
		if n == 2:
			bonuses.append(["DOUBLE KILL", 100])
		elif n >= 3:
			bonuses.append(["MULTI KILL", 150])
	var blast: int = info.get("blast", 0)
	if blast != 0:
		_blast_kills[blast] = int(_blast_kills.get(blast, 0)) + 1
		if src == "barrel" and _blast_kills[blast] >= 4:
			unlock("chain")
	for b in bonuses:
		pts += int(b[1])
	add_score(pts)
	if combo == 10:
		story.emit("combo", {})
	if combo == 5 or combo == 10 or combo == 15:
		bonuses.append(["COMBO x%d" % multiplier(), 0])
	return bonuses


func on_leg_severed() -> void:
	lifetime.legs += 1
	if lifetime.legs >= 20:
		unlock("leg_day")
	_save()


func on_player_hurt(amount: int) -> void:
	stats.hearts_lost += amount
	style = maxf(style - 35.0, 0.0)
	if combo > 0:
		combo = 0
		score_changed.emit()


func on_drain() -> void:
	stats.drained += 1
	add_score(100)
	if stats.drained >= 3:
		unlock("soul_eater")


func on_spared() -> void:
	stats.spared += 1
	add_score(150)


func on_leg_shot() -> void:
	add_score(200)
	unlock("return")


# רעש: מעיר זומבים ששוכבים, ומושך זומבים שמסתובבים
func make_noise(pos: Vector2, radius: float) -> void:
	get_tree().call_group("zombies", "hear_noise", pos, radius)


# ============================================================
#  סוף שלב
# ============================================================
# מחזיר את התוצאות למסך הסיום
func finish_level(time_sec: float) -> Dictionary:
	stats.time = time_sec
	var acc := float(stats.hits) / float(maxi(stats.shots, 1))
	var stars := 1
	if acc >= 0.45 or stats.shots == 0:
		stars = 2
		if stats.hearts_lost <= 1:
			stars = 3
	var bonus := stars * 250
	level_score += bonus
	var earned := Upgrades.level_income(level, stars, level_score)   # כלכלה מאוזנת ל-70 שלבים
	scrap += earned
	run_score += level_score
	if stats.drained == 0:
		unlock("merciful")
	if stats.hearts_lost == 0:
		unlock("untouchable")
	if Settings.difficulty == Settings.HARD:
		unlock("hard_boiled")
	var best := _update_high_score(run_score)
	completed[level] = maxi(int(completed.get(level, 0)), stars)   # התקדמות במפה
	level_best[level] = maxi(int(level_best.get(level, 0)), level_score)
	var result := {"stars": stars, "accuracy": acc, "bonus": bonus, "scrap": earned, "best": best,
		"level_score": level_score, "run_score": run_score, "stats": stats.duplicate()}
	level += 1
	level_score = 0   # כבר נוסף ל-run_score
	combo = 0
	_level_start_score = run_score
	_level_start_scrap = scrap
	_save()
	return result


func finish_run() -> bool:
	return _update_high_score(run_score + level_score)


func _update_high_score(score: int) -> bool:
	var d: int = Settings.difficulty
	if score > high_scores[d]:
		high_scores[d] = score
		_save()
		return true
	return false


# ============================================================
#  גביעים + שמירה
# ============================================================
func unlock(id: String) -> void:
	if trophies.get(id, false):
		return
	trophies[id] = true
	_save()
	for t in TROPHIES:
		if t.id == id:
			_banner.show_trophy(t.name, t.desc)
	trophy_unlocked.emit(id)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "trophies", trophies)
	cfg.set_value("progress", "high_scores", high_scores)
	cfg.set_value("progress", "lifetime", lifetime)
	cfg.set_value("progress", "campaign", save_dict())   # התקדמות במפה, נשקים, שדרוגים
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	trophies = cfg.get_value("progress", "trophies", {})
	var hs = cfg.get_value("progress", "high_scores", [0, 0, 0])
	if hs is Array and hs.size() == 3:
		high_scores = hs
	var lt = cfg.get_value("progress", "lifetime", {})
	if lt is Dictionary:
		for k in lt:
			lifetime[k] = lt[k]
	var camp = cfg.get_value("progress", "campaign", {})
	if camp is Dictionary:
		var d: Dictionary = camp
		completed.clear()
		for k in d.get("completed", {}):
			completed[int(k)] = int(d.completed[k])
		for k in d.get("level_best", {}):
			level_best[int(k)] = int(d.level_best[k])
		var ws = d.get("weapon_slots", null)
		if ws is Array and ws.size() == 5:
			weapon_slots = ws
		scrap = int(d.get("scrap", 0))
		for k in d.get("upgrades", {}):
			upgrades[k] = int(d.upgrades[k])
		for w in d.get("seen_weapons", []):
			mark_weapon_seen(int(w))
		var asl = d.get("ability_slots", [])
		if asl is Array and asl.size() == 5:
			ability_slots = asl.duplicate()


# ---- באנר שיורד מלמעלה כשפותחים גביע ----
class TrophyBanner extends Node2D:
	var _queue := []
	var _t := -1.0
	var _name := ""
	var _desc := ""
	const SHOW := 3.2

	func show_trophy(n: String, d: String) -> void:
		_queue.append([n, d])

	func _process(delta: float) -> void:
		if _t < 0.0 and _queue.size() > 0:
			var q = _queue.pop_front()
			_name = q[0]
			_desc = q[1]
			_t = 0.0
		if _t >= 0.0:
			_t += delta
			if _t > SHOW:
				_t = -1.0
			queue_redraw()

	func _draw() -> void:
		if _t < 0.0:
			return
		var vp := get_viewport_rect().size
		var k := clampf(minf(_t / 0.35, (SHOW - _t) / 0.35), 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		var w := 420.0
		var h := 70.0
		var pos := Vector2((vp.x - w) / 2.0, -h + (h + 14.0) * k)
		draw_rect(Rect2(pos + Vector2(4, 5), Vector2(w, h)), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(pos, Vector2(w, h)), Color(0.08, 0.06, 0.05, 0.95))
		draw_rect(Rect2(pos, Vector2(w, h)), Color("d8a033"), false, 2.0)
		_cup(pos + Vector2(38, 36))
		var f := ThemeDB.fallback_font
		draw_string(f, pos + Vector2(72, 26), "TROPHY UNLOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d8a033"))
		draw_string_outline(f, pos + Vector2(72, 48), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 4, Color(0, 0, 0, 0.8))
		draw_string(f, pos + Vector2(72, 48), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		draw_string(f, pos + Vector2(72, 64), _desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.78, 0.75))

	func _cup(c: Vector2) -> void:
		var gold := Color("e0b040")
		draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -16), c + Vector2(13, -16), c + Vector2(9, 0), c + Vector2(3, 4), c + Vector2(-3, 4), c + Vector2(-9, 0)]), gold)
		draw_arc(c + Vector2(-13, -9), 6.0, PI * 0.5, PI * 1.5, 10, gold, 2.5, true)
		draw_arc(c + Vector2(13, -9), 6.0, -PI * 0.5, PI * 0.5, 10, gold, 2.5, true)
		draw_rect(Rect2(c + Vector2(-2, 4), Vector2(4, 7)), gold)
		draw_rect(Rect2(c + Vector2(-9, 11), Vector2(18, 4)), gold.darkened(0.2))
		draw_line(c + Vector2(-8, -13), c + Vector2(-5, -3), Color(1, 1, 1, 0.5), 2.0, true)
