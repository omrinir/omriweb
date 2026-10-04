extends Node
# ============================================================
#  PLAYER MEMORY - "THEY LEARN"
#  זיכרון קל של איך שהשחקן משחק (בלי machine learning - רק ממוצעים נעים).
#  Autoload בשם PlayerMemory. הזיכרון נשמר לאורך כל הריצה (משלב לשלב),
#  ובתחילת כל שלב הוא "נשכח" קצת (decay_on_level).
#
#  מה נרשם (כל ערך בין 0 ל-1 אלא אם כתוב אחרת):
#    weapon_use[category]   - כמה משתמשים בכל סוג נשק: auto / shotgun / precision / explosive / other
#    avg_distance           - מרחק ממוצע מהזומבי הקרוב (פיקסלים) כשיורים
#    preferred_dir          - לאיזה כיוון השחקן פונה כשהוא יורה (-1 = שמאלה, 1 = ימינה)
#    retreat_dir            - לאן הוא בורח כשזומבים מתקרבים (-1 / 1)
#    crouch                 - כמה זמן הוא כורע
#    camping                - כמה זמן הוא נשאר באותו מקום
#    high_ground            - כמה זמן הוא נמצא גבוה (על קומה / מכונית)
#    reload_rate            - כמה טעינות בדקה
#    retreat                - כמה הוא נסוג
#    explosives             - כמה רימונים / בקבוקים / משגר
#    camp_spot, camp_shots  - מאיפה הוא יורה שוב ושוב (הזומבי TACTICIAN מנצל את זה)
#
#  איך הזומבים משתמשים בזה: ai/zombie_brain.gd -> _adapt()
#  איך לשנות כמה מהר הם לומדים: LEARN_RATE (גדול = לומדים מהר)
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const LEARN_RATE := 0.035          # כמה כל אירוע משנה את הממוצע
const SAMPLE_TIME := 0.5           # כל כמה שניות דוגמים את מצב השחקן
const DECAY_ON_LEVEL := 0.35       # בתחילת שלב: כמה מהזיכרון נשכח

var weapon_use := {"auto": 0.0, "shotgun": 0.0, "precision": 0.5, "explosive": 0.0, "other": 0.0}
var avg_distance := 300.0
var preferred_dir := 0.0
var retreat_dir := 0.0
var crouch := 0.0
var camping := 0.0
var high_ground := 0.0
var reload_rate := 0.0
var retreat := 0.0
var explosives := 0.0
var camp_spot := Vector2.ZERO
var camp_shots := 0
var shots_total := 0

var _sample_t := 0.0
var _still_pos := Vector2.ZERO
var _still_t := 0.0
var _reloads_window := []          # זמנים של טעינות (לחישוב טעינות בדקה)
var _time := 0.0
var _last_near_dist := 9999.0


func _process(delta: float) -> void:
	_time += delta
	var p := get_tree().get_first_node_in_group("player")
	if p == null or p.dead:
		return
	_sample_t -= delta
	if _sample_t > 0.0:
		return
	_sample_t = SAMPLE_TIME
	_sample(p)


func _ema(old: float, v: float, rate := LEARN_RATE) -> float:
	return old + (v - old) * rate


func _sample(p: Node) -> void:
	var pos: Vector2 = p.global_position
	crouch = _ema(crouch, 1.0 if p._crouching else 0.0)
	# גבוה = מעל הריצפה הראשית (קומה שנייה / גג / מכונית)
	var floor_y: float = p.get_meta("ground_y", pos.y)
	high_ground = _ema(high_ground, 1.0 if pos.y < floor_y - 50.0 else 0.0)
	# נשאר באותו מקום?
	if pos.distance_to(_still_pos) < 70.0:
		_still_t += SAMPLE_TIME
	else:
		_still_t = 0.0
		_still_pos = pos
	camping = _ema(camping, 1.0 if _still_t > 2.5 else 0.0)
	# נסיגה: זומבי קרוב מתקרב והשחקן זז הפוך ממנו
	var near := _nearest_zombie(pos)
	if near != null:
		var dx: float = near.global_position.x - pos.x
		var d := absf(dx)
		var moving_away: bool = absf(p.velocity.x) > 40.0 and signf(p.velocity.x) == -signf(dx)
		var backing: bool = moving_away and d < 320.0 and d < _last_near_dist + 5.0
		retreat = _ema(retreat, 1.0 if backing else 0.0)
		if backing:
			retreat_dir = _ema(retreat_dir, signf(p.velocity.x), LEARN_RATE * 2.0)
		_last_near_dist = d
	# טעינות בדקה
	_reloads_window = _reloads_window.filter(func(t): return _time - float(t) < 60.0)
	reload_rate = _ema(reload_rate, clampf(float(_reloads_window.size()) / 12.0, 0.0, 1.0), 0.1)


func _nearest_zombie(pos: Vector2) -> Node:
	var best: Node = null
	var bd := 900.0
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead:
			continue
		var d: float = z.global_position.distance_to(pos)
		if d < bd:
			bd = d
			best = z
	return best


# ---- אירועים (player.gd קורא) ----
func on_shot(weapon_id: int) -> void:
	shots_total += 1
	var cat: String = WeaponDB.val(weapon_id, "category", "other")
	for k in weapon_use:
		weapon_use[k] = _ema(weapon_use[k], 1.0 if k == cat else 0.0, LEARN_RATE * 0.5)
	if cat == "explosive":
		on_explosive()
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var pos: Vector2 = p.global_position
	preferred_dir = _ema(preferred_dir, p._face(), LEARN_RATE * 0.5)
	var near := _nearest_zombie(pos)
	if near != null:
		avg_distance = _ema(avg_distance, pos.distance_to(near.global_position), LEARN_RATE)
	# יורה שוב ושוב מאותה נקודה?
	if pos.distance_to(camp_spot) < 90.0:
		camp_shots += 1
	else:
		camp_spot = pos
		camp_shots = 1


func on_reload() -> void:
	_reloads_window.append(_time)


func on_explosive() -> void:
	explosives = _ema(explosives, 1.0, 0.12)
	explosives = minf(explosives, 1.0)


# ---- שאלות (ai/zombie_brain.gd שואל) ----
# 0..1: כמה השחקן מעדיף כלי נשק לטווח קצר (שוטגאן)
func likes_close_range() -> float:
	return clampf(float(weapon_use.shotgun) * 1.6 + (1.0 - clampf(avg_distance / 300.0, 0.0, 1.0)) * 0.3, 0.0, 1.0)


# 0..1: כמה הוא צלף / יורה מרחוק
func likes_long_range() -> float:
	return clampf(float(weapon_use.precision) * 0.8 + clampf((avg_distance - 250.0) / 400.0, 0.0, 1.0) * 0.5, 0.0, 1.0)


# 0..1: כמה הוא "מרסס" (SMG / רובה סער)
func likes_spray() -> float:
	return clampf(float(weapon_use.auto) * 1.6, 0.0, 1.0)


# לאיזה צד כדאי לאגף אותו: הפוך מהצד שאליו הוא בורח בדרך כלל
func flank_side() -> float:
	if absf(retreat_dir) < 0.15:
		return 1.0 if randf() < 0.5 else -1.0
	return -signf(retreat_dir)


# האם הוא יורה כבר הרבה זמן מאותו מקום (לTACTICIAN)
func is_camping() -> bool:
	return camp_shots >= 8 or camping > 0.45


# תחילת שלב: שוכחים קצת (אבל לא הכל - הם זוכרים!)
func on_level_start() -> void:
	for k in weapon_use:
		weapon_use[k] = lerpf(weapon_use[k], 0.2, DECAY_ON_LEVEL)
	for f in ["crouch", "camping", "high_ground", "retreat", "explosives", "reload_rate"]:
		set(f, float(get(f)) * (1.0 - DECAY_ON_LEVEL))
	retreat_dir *= 1.0 - DECAY_ON_LEVEL
	camp_shots = 0
	_reloads_window.clear()


func new_run() -> void:
	weapon_use = {"auto": 0.0, "shotgun": 0.0, "precision": 0.5, "explosive": 0.0, "other": 0.0}
	avg_distance = 300.0
	preferred_dir = 0.0
	retreat_dir = 0.0
	for f in ["crouch", "camping", "high_ground", "retreat", "explosives", "reload_rate"]:
		set(f, 0.0)
	camp_shots = 0


# לבדיקות / דיבאג
func snapshot() -> Dictionary:
	return {"weapon_use": weapon_use.duplicate(), "avg_distance": avg_distance, "retreat_dir": retreat_dir, "crouch": crouch,
		"camping": camping, "high_ground": high_ground, "reload_rate": reload_rate, "retreat": retreat, "explosives": explosives,
		"camp_shots": camp_shots}
