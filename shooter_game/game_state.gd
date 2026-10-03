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
const UPGRADES := [
	{"id": "fire_rate", "name": "QUICK HANDS", "desc": "Shoot 15% faster", "costs": [40, 80, 140]},
	{"id": "ammo", "name": "BANDOLIER", "desc": "+10 bullets at start", "costs": [40, 70, 110]},
	{"id": "grenades", "name": "GRENADE BELT", "desc": "+1 grenade at start", "costs": [60, 120]},
	{"id": "siphon", "name": "SIPHON SHIELD", "desc": "Draining also gives a shield", "costs": [80, 150]},
	{"id": "boost_time", "name": "LONG BOOSTS", "desc": "Boosts last 30% longer", "costs": [50, 100]},
	{"id": "laser", "name": "LASER SIGHT", "desc": "A laser line shows your aim", "costs": [70]},
]

# ---------------- ניקוד ----------------
const KILL_POINTS := [100, 120, 200, 150, 150, 2000]   # לפי סוג זומבי
const COMBO_WINDOW := 4.0                               # שניות בין הריגות כדי שהקומבו ימשיך

# מצב הריצה (נשמר בין שלבים, מתאפס במשחק חדש)
var level := 1
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

# נשמר לתמיד
var trophies := {}
var high_scores := [0, 0, 0]
var lifetime := {"legs": 0, "kills": 0, "headshots": 0}

var _banner: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	for u in UPGRADES:
		upgrades[u.id] = 0
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_banner = TrophyBanner.new()
	layer.add_child(_banner)
	reset_level()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if combo > 0:
		combo_t -= delta / maxf(Engine.time_scale, 0.01)
		if combo_t <= 0.0:
			combo = 0
			score_changed.emit()


# ============================================================
#  ריצה / שלב
# ============================================================
func new_run() -> void:
	level = 1
	run_score = 0
	scrap = 0
	for u in UPGRADES:
		upgrades[u.id] = 0
	_level_start_score = 0
	_level_start_scrap = 0


func reset_level() -> void:
	level_score = 0
	combo = 0
	combo_t = 0.0
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


func multiplier() -> int:
	if combo >= 15: return 5
	if combo >= 10: return 4
	if combo >= 6: return 3
	if combo >= 3: return 2
	return 1


func add_score(points: int) -> void:
	level_score += points * multiplier()
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
	var pts: int = KILL_POINTS[clampi(kind, 0, KILL_POINTS.size() - 1)]
	if info.get("zone", "") == "head":
		stats.headshots += 1
		lifetime.headshots += 1
		bonuses.append(["HEADSHOT", 50])
	if info.get("hidden", false):
		bonuses.append(["FLUSHED OUT", 75])
	var src: String = info.get("source", "")
	if src == "barrel" or src == "car":
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
	var earned := level_score / 20 + stars * 20
	scrap += earned
	run_score += level_score
	if stats.drained == 0:
		unlock("merciful")
	if stats.hearts_lost == 0:
		unlock("untouchable")
	if Settings.difficulty == Settings.HARD:
		unlock("hard_boiled")
	var best := _update_high_score(run_score)
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


func buy(id: String) -> bool:
	for u in UPGRADES:
		if u.id == id:
			var lvl := upgrade_level(id)
			if lvl >= u.costs.size() or scrap < int(u.costs[lvl]):
				return false
			scrap -= int(u.costs[lvl])
			upgrades[id] = lvl + 1
			_level_start_scrap = scrap
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
