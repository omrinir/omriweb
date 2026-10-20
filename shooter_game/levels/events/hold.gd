extends Node
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  HOLD THE LINE - סוג שלב (levels/level_events.gd -> "hold"): שלבים 6, 21, 30, 48, 57.
#  בערך ב-30%-40% מהשלב (על קרקע מוצקה: לא בור, לא ליד סצנת סיפור, לא ליד נקודת הביקורת / הבוס)
#  יש "נקודה מבוצרת" (שורת שקי חול על הרצפה משני הצדדים). השחקן מגיע לאמצע ->
#    * שני מחסומים (שקי חול + פחים + קרשים + תיל) נוחתים בטריקה משני הצדדים, ~1.2 מסכים זה מזה.
#      הם מוצקים (שכבה 1): השחקן, הזומבים והקליעים לא עוברים. מעליהם קיר שקוף שרק השחקן מתנגש בו
#      (שכבה 512, כמו environment/pass_barrier.gd) - שלא יקפוץ מקומה / יעוף עם JETPACK החוצה.
#    * באנר "HOLD THE LINE" + שעון יורד (DURATION לפי רמת הקושי) מתחת לשעון של השלב.
#    * גלים: זומבים קופצים מעל המחסומים משני הצדדים (ונוחתים בפנים), ובשלבים עם קומות גם על הקומות
#      שבתוך הזירה ("מלמעלה"). הסוגים - מהתמהיל של השלב (main._pick_kind). הקצב עולה, יש הפוגה קצרה
#      באמצע (LULL: ארגז תחמושת במצנח), ובסוף FINAL WAVE.
#    * נגמר הזמן: "LINE HELD" + פרס (ארגז SUPPLY + קופסת תחמושת + לב, במצנח), המחסומים קורסים החוצה, ומי שנשאר ממשיך להילחם.
#  תחמושת: לנשק שביד נשאר מעט (LOW_AMMO מהמקסימום) - קופסת תחמושת נופלת עליו במצנח (כל AMMO_CD שניות).
#  אין כלום בכל הנשקים - ארגז SUPPLY (כבר אחרי EMPTY_CD). בהפוגה תמיד ארגז SUPPLY.
#  בוסים: הזירה לא נבחרת ליד בוס, וזומבי בוס שנוצר בטעות בגל - נמחק.
#  שעון השלב: זמן ההחזקה נוסף ל-GOLD / SILVER (Game.clock_pars) - לא מפסידים מדליה בגלל ההמתנה.
#  נקודת ביקורת: אם השלב מתחיל ממנה (השחקן כבר אחרי הזירה) - אין אירוע. מוות = השלב מתחיל מחדש כרגיל
#  (הכל נבנה מחדש, אין כאן מצב ששומרים).
#  זהירות: לא נותנים לזומבים chase_range > 600 - אצל הרבה סוגים (enemies/types) זה הסימן שהם הבוס!
#          במקום זה _alert_t (כמו levels/pace_director.gd), מתחדש כל ALERT_EVERY שניות.
#  לשנות: AT / PREFER (איפה), WIDTHS (רוחב הזירה במסכים), DURATION, MAX_ALIVE, RAMP / SURGE / LULL,
#         INTERVAL_MULT / SIZE_ADD / EARLY_EASE (קושי), ABOVE_SHARE, SAFE_DROP, LOW_AMMO / AMMO_CD, WALL_H / WALL_W.
# ============================================================

const Sfx := preload("res://sfx.gd")
const Art := preload("res://art.gd")
const PickupScript := preload("res://pickup.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")
const StoryDB := preload("res://story/story_db.gd")
const FONT_PATH := "res://fonts/Bangers-Regular.ttf"
const BANNER_FS := 72                  # גודל הגופן של הבאנר (קבוע - מגדילים עם set_transform)

# ---- איפה ----
const AT := Vector2(0.30, 0.40)        # טווח מרכז הזירה (חלק מאורך השלב)
const AT_WIDE := Vector2(0.26, 0.44)   # אם אין מקום בטווח הרגיל
const PREFER := 0.35
const WIDTHS := [1.2, 1.0, 0.85]       # רוחב הזירה במסכים (נרואים, אחרי הזום). מנסים מהגדול לקטן
const STEP := 40.0                     # צעד החיפוש
const STORY_CLEAR := 1000.0            # מרחק מסצנת סיפור
const CP_CLEAR := 350.0                # מרחק מנקודת הביקורת
const BOSS_ZONE := 1500.0              # לא בסוף השלב
const PIT_CLEAR := 80.0
const TRIGGER_BEFORE := 90.0           # כמה לפני האמצע זה מתחיל

# ---- המחסומים ----
const WALL_W := 56.0                   # רוחב הגוף המוצק
const WALL_VIS := 72.0                 # רוחב הציור
const WALL_H := 230.0                  # גובה (קפיצה כפולה מהרצפה ~220)
const SKY_H := 1400.0                  # הקיר השקוף מעליו (רק לשחקן)
const SLAM_T := 0.28
const FALL_T := 1.1                    # קורס החוצה בסוף

# ---- הזמן והגלים (k = חלק מהזמן) ----
const DURATION := [45.0, 60.0, 70.0]   # קל / רגיל / קשה
const START_AT := 0.04                 # הגל הראשון (אחרי הבאנר)
const LULL := Vector2(0.5, 0.6)        # הפוגה: בלי גלים, ארגז תחמושת
const RAMP := [3.4, 2.4]               # מרווח בין קבוצות: תחילת השלב -> לפני ההפוגה
const SURGE := [2.2, 1.6]              # אחרי ההפוגה -> הסוף
const RAMP_SIZE := Vector2(1.0, 2.0)   # גודל קבוצה (לפני עיגול)
const SURGE_SIZE := Vector2(1.6, 2.5)
const INTERVAL_MULT := [1.3, 1.0, 0.85]
const SIZE_ADD := [-0.5, 0.0, 0.5]
const MAX_ALIVE := [5, 7, 9]           # כמה זומבים ערים בזירה לכל היותר (אחרת מחכים)
const EARLY_LEVEL := 12                # שלבים מוקדמים (נשקים חלשים): קצת פחות
const EARLY_EASE := 1.2                # מרווח x1.2, ואחד פחות בזירה
const MEMBER_GAP := 0.32               # שניות בין זומבים באותה קבוצה
const ABOVE_SHARE := 0.3               # חלק מהקבוצות שבאות מהקומות (אם יש קומה בזירה)
const SAFE_DROP := 300.0               # לא נוחתים קרוב מזה לשחקן (צמוד למחסום -> באים מהצד השני)
const FINAL_T := 10.0                  # "FINAL WAVE" כשנשארו כך שניות
const STOP_T := 3.5                    # בשניות האחרונות כבר לא נכנסים (גומרים את מי שבפנים)
const ALERT := 4.0
const ALERT_EVERY := 0.5
const BAD_KINDS := {5: 0, 7: 0, 19: 1, 8: 1, 11: 0}   # בוסים / זוחל תקרה / יד ביוב -> סוג אחר

# ---- תחמושת ופרס ----
const LOW_AMMO := 0.25                 # הנשק שביד מתחת לזה (מהמקסימום) -> קופסה נופלת
const AMMO_CD := 6.0
const EMPTY_CD := 2.5                  # אין כלום בכל הנשקים -> כבר אחרי כך שניות
const CHUTE_GRAVITY := 260.0           # מצנח: נופל לאט
const DROP_H := 430.0                  # מאיזה גובה (מעל השחקן) הארגז נופל
const REWARD_H := 120.0                # הפרס בסוף: נמוך (נוחת מהר, לפני השחקן)

var main: Node
var floor_y: float
var hud_layer: CanvasLayer

enum { WAIT, ACTIVE, DONE }
var state := WAIT
var x0 := 0.0
var x1 := 0.0
var cx := 0.0
var duration := 60.0
var t := 0.0                    # שניות מאז שהתחיל
var _rng := RandomNumberGenerator.new()
var _diff := 1
var _ease := 1.0
var _max_alive := 7
var _walls: Array = []          # Barricade
var _bodies: Array = []         # StaticBody2D
var _fx: FX = null
var _ui: Node2D = null
var _next := 0.0                # הקבוצה הבאה
var _queue: Array = []          # [time, side(-1/1/0=למעלה), kind, plat]
var _alert_t := 0.0
var _ammo_cd := 0.0
var _ammo_t := 0.0
var _lull_done := false
var _final_done := false
var _tick := -1
var _decks: Array = []          # [x_lo, x_hi, y] קומות בתוך הזירה
var _banner := {}               # text, sub, col, t0, dur, size
var _end_t := 0.0
var _now := 0.0                 # זמן משחק (באנרים) - לא זמן אמיתי: עוצר בהשהיה / האטה
var spawned := 0                # לבדיקות
var drops := 0
static var _font: Font = null

const SOUNDS := {
	"hold_slam": {"rev": 0.3, "drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.015, 0.0, 260.0, 1.5, 1.0, 0], ["S", 95, 32, 0.0, 0.55, 0.0, 6.0, 1.4, 1.0, 0], ["N", 0, 0, 0.0, 0.7, 0.0, 5.0, 0.8, 0.12, 0], ["S", 480, 470, 0.0, 0.7, 0.0, 6.0, 0.25, 1.0, 0], ["S", 1170, 1160, 0.0, 0.5, 0.0, 9.0, 0.12, 1.0, 0], ["C", 0, 0, 0.02, 0.4, 0.0, 6.0, 0.5, 1.0, 0]]},
	"hold_alarm": [["Q", 440, 660, 0.0, 0.45, 0.01, 1.2, 0.26, 0.4, 0], ["Q", 660, 440, 0.45, 0.45, 0.0, 1.2, 0.26, 0.4, 0], ["Q", 440, 660, 0.9, 0.45, 0.0, 1.2, 0.26, 0.4, 0], ["Q", 660, 440, 1.35, 0.5, 0.0, 2.5, 0.26, 0.4, 0]],
	"hold_win": {"rev": 0.35, "layers": [["S", 392, 392, 0.0, 0.5, 0.01, 3.0, 0.3, 1.0, 0], ["S", 523, 523, 0.12, 0.5, 0.01, 3.0, 0.3, 1.0, 0], ["S", 659, 659, 0.24, 0.6, 0.01, 2.5, 0.3, 1.0, 0], ["S", 784, 784, 0.36, 1.1, 0.01, 1.6, 0.34, 1.0, 0.01], ["W", 196, 196, 0.36, 1.1, 0.02, 1.6, 0.12, 0.25, 0]]},
	"hold_vault": [["N", 0, 0, 0.0, 0.18, 0.0, 16.0, 0.5, 0.35, 0], ["S", 700, 640, 0.0, 0.12, 0.0, 30.0, 0.18, 1.0, 0], ["C", 0, 0, 0.0, 0.15, 0.0, 14.0, 0.4, 1.0, 0]],
}


static func font() -> Font:
	if _font == null and ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH) as Font
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font


func start() -> void:
	_rng.randomize()
	_diff = clampi(int(Settings.difficulty), 0, 2)
	duration = float(DURATION[_diff])
	if Game.level <= EARLY_LEVEL:
		_ease = EARLY_EASE
		_max_alive = int(MAX_ALIVE[_diff]) - 1
	else:
		_max_alive = int(MAX_ALIVE[_diff])
	Sfx.register(SOUNDS)
	Sfx.warm_up()   # הצלילים החדשים מסונתזים עכשיו (בטעינה), לא בטריקה
	if not _find_spot():
		push_warning("[HOLD] no spot for the hold in level %d" % Game.level)
		queue_free()
		return
	# זמן ההחזקה לא נספר נגד המדליה (גם כשמתחילים מנקודת הביקורת - הזמן שנשמר שם כבר כולל את ההחזקה)
	Game.clock_pars += Vector2(duration, duration)
	var p = main._player
	if p != null and p.global_position.x > x0 - 40.0:   # התחלה מנקודת הביקורת: כבר עברת
		state = DONE
		queue_free()
		return
	_fx = FX.new()
	_fx.ev = self
	main.add_child(_fx)
	_ui = HoldUI.new()   # כבר עכשיו: מצייר פעם אחת את האותיות בשקיפות 0 (שלא ייתקע בטריקה)
	_ui.ev = self
	hud_layer.add_child(_ui)
	for i in 2:   # בסיס המחסום (שקי חול נמוכים) כבר שם - רואים שזה מקום מבוצר
		var b := Barricade.new()
		b.side = -1.0 if i == 0 else 1.0
		b.position = Vector2(x0 if i == 0 else x1, floor_y)
		b.seed_v = _rng.randi() % 1000
		main.add_child(b)
		_walls.append(b)


# ============ איפה הזירה ============
func _find_spot() -> bool:
	var vp: Vector2 = main.get_viewport_rect().size
	var screen: float = vp.x / maxf(float(main.camera_zoom), 0.1)
	var stories := []
	for sc in StoryDB.for_level(Game.level):
		if sc.has("x"):
			stories.append(float(sc.x))
	for pass_i in 3:   # 0 = רגיל, 1 = טווח רחב, 2 = מותר בור בפנים (לא מתחת למחסום / לאמצע)
		var rng_at: Vector2 = AT if pass_i == 0 else AT_WIDE
		for w in WIDTHS:
			var half: float = float(w) * screen * 0.5
			var best := INF
			var best_c := -1.0
			var c: float = float(main.level_w) * rng_at.x
			while c <= float(main.level_w) * rng_at.y:
				var s := _score(c, half, stories, pass_i == 2)
				if s < best:
					best = s
					best_c = c
				c += STEP
			if best_c > 0.0:
				cx = best_c
				x0 = cx - half
				x1 = cx + half
				return true
	return false


func _score(c: float, half: float, stories: Array, allow_pit: bool) -> float:
	var a := c - half
	var b := c + half
	var lw: float = main.level_w
	if a < float(main.safe_zone) + 300.0 or b > lw - BOSS_ZONE:
		return INF
	if allow_pit:
		if main._in_pit(a - PIT_CLEAR, a + PIT_CLEAR, 0.0) or main._in_pit(b - PIT_CLEAR, b + PIT_CLEAR, 0.0) or main._in_pit(c - 160.0, c + 160.0, 0.0):
			return INF
	elif main._in_pit(a - PIT_CLEAR, b + PIT_CLEAR, 0.0):
		return INF
	for sx in stories:
		if float(sx) > a - STORY_CLEAR and float(sx) < b + STORY_CLEAR:
			return INF
	if main._checkpoint != null:
		var cpx: float = main._checkpoint.position.x
		if cpx > a - CP_CLEAR and cpx < b + CP_CLEAR:
			return INF
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.is_boss() and z.global_position.x > a - 300.0 and z.global_position.x < b + 300.0:
			return INF
	var s := absf(c / lw - PREFER) * 3000.0
	if allow_pit and main._in_pit(a, b, 0.0):
		s += 2000.0
	for r in main._hazard_rects():   # שלולית חשמל / קרח דק / כבל - עדיף בלי
		var hr: Rect2 = r
		if hr.end.x > a and hr.position.x < b:
			s += 350.0
	for wx in [a, b]:   # המחסום לא על מכשול / סולם / מלכודת
		if main._near_brick(float(wx)):
			s += 250.0
	if main._near_brick(c):
		s += 60.0
	return s


# ============ כל פריים ============
func _process(delta: float) -> void:
	_now += delta


func _physics_process(delta: float) -> void:
	if state == DONE:
		_end_t += delta
		if _end_t > FALL_T + 4.0:
			_cleanup_ui()
			queue_free()
		return
	var p = main._player
	if p == null or not is_instance_valid(p):
		return
	if state == WAIT:
		if not p.dead and p.global_position.x >= cx - TRIGGER_BEFORE and get_tree().get_nodes_in_group("story_scene").is_empty():
			_begin(p)
		return
	if p.dead:   # מוות: השלב יתחיל מחדש (main / pause_menu). רק לא ממשיכים לשלוח זומבים
		return
	t += delta
	var face := WALL_W * 0.5   # רשת ביטחון: איכשהו מעבר למחסום (באג / שיגור) -> חזרה פנימה
	if p.global_position.x < x0 + face or p.global_position.x > x1 - face:
		p.global_position.x = clampf(p.global_position.x, x0 + face + 20.0, x1 - face - 20.0)
	_alert_t -= delta
	if _alert_t <= 0.0:
		_alert_t = ALERT_EVERY
		_alert_all()
	_ammo_t -= delta
	_ammo_cd -= delta
	if _ammo_t <= 0.0:
		_ammo_t = 1.0
		_check_ammo(p)
		_fix_pickups()
	var k := t / duration
	# הפוגה: ארגז תחמושת
	if not _lull_done and k >= LULL.x:
		_lull_done = true
		_drop(PickupScript.SUPPLY, p, _rng.randf_range(-30.0, 30.0))
		_ammo_cd = AMMO_CD
		_show("SUPPLY DROP", "RELOAD!", Color("ffd34a"), 2.2, 44)
		Sfx.play("whoosh", null, -2.0)
	if not _final_done and duration - t <= FINAL_T:
		_final_done = true
		_show("FINAL WAVE", "", Color("ff5a3a"), 1.8, 50)
		Sfx.play("hold_alarm", null, -6.0, 0.0, 1, 1.15)
	var left := int(ceil(duration - t))
	if left <= 5 and left != _tick and left > 0:
		_tick = left
		Sfx.play("streak_tick", null, -2.0, 0.0, 2, 1.0 + 0.06 * float(5 - left))
	# גלים
	if k >= START_AT and (k < LULL.x or k >= LULL.y) and duration - t > STOP_T:
		_next -= delta
		if _next <= 0.0 and _queue.is_empty():
			if _alive_in_arena() < _max_alive:
				_plan_group(k)
			else:
				_next = 0.4
	_run_queue()
	if t >= duration:
		_finish(p)


# ============ התחלה ============
func _begin(_p: Node) -> void:
	state = ACTIVE
	t = 0.0
	_next = 0.0
	for i in 2:
		var wx := x0 if i == 0 else x1
		_shove_out(wx)
		_bodies.append(_make_body(wx, Vector2(WALL_W, WALL_H), floor_y - WALL_H * 0.5, 1))
		_bodies.append(_make_body(wx, Vector2(WALL_W, SKY_H), floor_y - WALL_H - SKY_H * 0.5, 512))
		var b: Barricade = _walls[i]
		b.slam()
		Sfx.play("hold_slam", b.global_position + Vector2(0, -100), 2.0, 0.05, 2)
	Sfx.play("hold_alarm", null, -4.0, 0.0, 1)
	for z in get_tree().get_nodes_in_group("zombies"):   # מי שכבר בפנים מתעורר מהטריקה
		if not z.dead and z.global_position.x > x0 and z.global_position.x < x1:
			z.hear_noise(z.global_position, 100.0)
	for pl in get_tree().get_nodes_in_group("platforms"):   # קומות בתוך הזירה ("מלמעלה")
		var r: Rect2 = pl.world_rect()
		var lo := maxf(r.position.x + 24.0, x0 + WALL_W)
		var hi := minf(r.end.x - 24.0, x1 - WALL_W)
		if hi - lo > 80.0 and r.position.y < floor_y - 60.0:
			_decks.append([lo, hi, r.position.y])
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(10.0)
	_show("HOLD THE LINE", "SURVIVE %s" % _fmt(duration), Color("ffcf3a"), 2.6, 76)


func _make_body(x: float, sz: Vector2, y: float, layer: int) -> StaticBody2D:
	var sb := StaticBody2D.new()
	sb.collision_layer = layer
	sb.collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = sz
	cs.shape = r
	sb.add_child(cs)
	sb.position = Vector2(x, y)
	add_child(sb)
	return sb


# זומבי / חפץ שעומד בדיוק איפה שהמחסום נוחת - זז לצד שלו
func _shove_out(wx: float) -> void:
	var half := WALL_W * 0.5 + 26.0
	for z in get_tree().get_nodes_in_group("zombies"):
		var dx: float = z.global_position.x - wx
		if absf(dx) < half and z.global_position.y > floor_y - WALL_H - 40.0:
			z.global_position.x = wx + (half if dx >= 0.0 else -half)
	for pk in get_tree().get_nodes_in_group("pickups"):
		var dx2: float = pk.global_position.x - wx
		if absf(dx2) < half and pk.global_position.y > floor_y - WALL_H - 40.0:
			pk.global_position.x = wx + (half if dx2 >= 0.0 else -half)


# ============ גלים ============
func _plan_group(k: float) -> void:
	var size_v: Vector2
	var iv: float
	if k < LULL.x:
		var r := clampf((k - START_AT) / (LULL.x - START_AT), 0.0, 1.0)
		iv = lerpf(float(RAMP[0]), float(RAMP[1]), r)
		size_v = Vector2(lerpf(RAMP_SIZE.x, RAMP_SIZE.y, r), 0.0)
	else:
		var r2 := clampf((k - LULL.y) / (1.0 - LULL.y), 0.0, 1.0)
		iv = lerpf(float(SURGE[0]), float(SURGE[1]), r2)
		size_v = Vector2(lerpf(SURGE_SIZE.x, SURGE_SIZE.y, r2), 0.0)
	_next = iv * float(INTERVAL_MULT[_diff]) * _ease * _rng.randf_range(0.85, 1.15)
	var n := maxi(1, int(round(size_v.x + float(SIZE_ADD[_diff]) + _rng.randf_range(-0.45, 0.45))))
	n = mini(n, _max_alive - _alive_in_arena() + 1)
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	var deck: Array = []
	if not _decks.is_empty() and _rng.randf() < ABOVE_SHARE:
		deck = _decks[_rng.randi() % _decks.size()]
		side = 0.0
	var k0 := _kind()
	if k0 == 10 or k0 == 15:   # חולדות / כלבים - בלהקה
		n = maxi(n, int(main._group_size(k0, _rng)))
	for i in n:
		var kk := k0 if (i == 0 or k0 == 10 or k0 == 15) else _kind()
		if kk == 10 and k0 != 10:
			kk = 0
		_queue.append([t + float(i) * MEMBER_GAP * (0.4 if k0 == 10 else 1.0), side, kk, deck])


func _kind() -> int:
	var k: int = main._pick_kind(_rng)
	if BAD_KINDS.has(k):
		k = int(BAD_KINDS[k])
	return k


func _run_queue() -> void:
	while not _queue.is_empty() and float(_queue[0][0]) <= t:
		var q: Array = _queue.pop_front()
		_spawn_one(float(q[1]), int(q[2]), q[3])


func _spawn_one(side: float, kind: int, deck: Array) -> void:
	var pos := Vector2.ZERO
	var vin := 0.0
	var pl = main._player
	var px: float = pl.global_position.x if pl != null else cx
	if side == 0.0 and deck.size() == 3:   # על קומה בזירה: מהקצה הקרוב למחסום (לא על הראש של השחקן)
		var lo: float = deck[0]
		var hi: float = deck[1]
		var ends := [lo, hi] if absf(lo - x0) < absf(hi - x1) else [hi, lo]
		side = -1.0 if px > cx else 1.0   # אין קצה רחוק מספיק -> מהמחסום הרחוק
		for e in ends:
			if absf(float(e) - px) > SAFE_DROP:
				pos = Vector2(float(e) + _rng.randf_range(-10.0, 10.0), float(deck[2]) - 30.0)
				vin = 1.0 if float(e) < cx else -1.0
				side = 0.0
				break
	if side != 0.0:   # מעל המחסום: נוחת בפנים. השחקן צמוד למחסום הזה -> מהשני
		var face := (x0 + WALL_W * 0.5) if side < 0.0 else (x1 - WALL_W * 0.5)
		if absf(px - face) < SAFE_DROP:
			side = -side
			face = (x0 + WALL_W * 0.5) if side < 0.0 else (x1 - WALL_W * 0.5)
		vin = -side   # שמאל (-1) -> נכנס ימינה
		pos = Vector2(face + vin * _rng.randf_range(40.0, 75.0), floor_y - WALL_H - 10.0)
	var fy := floor_y
	if kind == 18:   # ג'טפאק מתחיל באוויר בעצמו (230 מעל הנקודה)
		pos.y = floor_y
	var z = main._spawn_zombie(pos.x, fy, kind, null)
	if z == null or not is_instance_valid(z):
		return
	if z.is_boss():
		z.queue_free()
		return
	if kind != 18:
		z.position.y = pos.y
	z.dormant = false
	z._dir = vin
	z._alert_t = ALERT + 2.0
	z.velocity = Vector2(vin * 140.0, -180.0)
	spawned += 1
	if _fx != null:
		_fx.puff(Vector2(pos.x, pos.y - 20.0))
	if Art.on_screen(_fx, pos, 80.0):
		Sfx.play("hold_vault", pos, -6.0, 0.15, 3)


func _alive_in_arena() -> int:
	var n := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.dead and not z.dormant and z.global_position.x > x0 and z.global_position.x < x1:
			n += 1
	return n


# כל מי שבזירה רודף אחרי השחקן (לא chase_range - ראה למעלה)
func _alert_all() -> void:
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.is_boss():
			continue
		var zx: float = z.global_position.x
		if zx > x0 and zx < x1:
			if z.dormant:
				z.hear_noise(z.global_position, 100.0)
			z._alert_t = maxf(float(z._alert_t), ALERT)


# ============ תחמושת ============
func _check_ammo(p: Node) -> void:
	if _ammo_cd > AMMO_CD - EMPTY_CD:
		return
	var cur := 0.0      # הנשק שביד
	var total := 0
	for s in p.slots:
		if s == null:
			continue
		total += int(s.ammo)
		if int(s.id) == int(p.gun):
			cur = float(s.ammo) / float(maxi(Upgrades.ammo_max(int(s.id)), 1))
	if cur >= LOW_AMMO and total > 0:
		return
	if total > 0 and _ammo_cd > 0.0:
		return
	for pk in get_tree().get_nodes_in_group("pickups"):   # כבר יש קופסה ליד השחקן (באותו גובה - שאפשר להגיע אליה)
		var d: Vector2 = pk.global_position - p.global_position
		if pk.kind == PickupScript.AMMO and absf(d.x) < 220.0 and absf(d.y + 20.0) < 50.0:
			return
	_ammo_cd = AMMO_CD
	_drop(PickupScript.AMMO if total > 0 else PickupScript.SUPPLY, p, _rng.randf_range(-30.0, 30.0))   # ריק לגמרי = ארגז מלא


# שלל של זומבי שנפל על ראש המחסום (אי אפשר להגיע) - מחליק פנימה ונופל לזירה
func _fix_pickups() -> void:
	for pk in get_tree().get_nodes_in_group("pickups"):
		for wx in [x0, x1]:
			if absf(pk.global_position.x - float(wx)) < WALL_W * 0.5 + 8.0 and pk.global_position.y < floor_y - 30.0:
				pk.global_position.x = float(wx) + (WALL_W * 0.5 + 24.0) * signf(cx - float(wx))
				pk._resting = false
				pk.velocity = Vector2.ZERO


# ארגז במצנח שנוחת על המשטח שהשחקן עומד עליו (מתחת לקומה / תקרה שמעליו - לא עליה)
func _drop(kind: int, p: Node, dx: float, h := DROP_H, inside := true) -> void:
	var x: float = p.global_position.x + dx
	if inside:
		x = clampf(x, x0 + WALL_W * 0.5 + 18.0, x1 - WALL_W * 0.5 - 18.0)
	var py: float = p.global_position.y
	var y0: float = py - h
	var ss: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
	var hit: Dictionary = ss.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, py - 50.0), Vector2(x, y0), 1 | 16))
	if not hit.is_empty():
		y0 = float(hit.position.y) + 22.0
	var pk = PickupScript.new()
	pk.kind = kind
	pk.life = 100000.0
	pk.gravity = CHUTE_GRAVITY
	main.add_child(pk)
	pk.setup(Vector2(x, y0), Vector2.ZERO)
	drops += 1
	if _fx != null and py - y0 > 120.0:
		_fx.chutes.append(pk)


# ============ הסוף ============
func _finish(p: Node) -> void:
	state = DONE
	_end_t = 0.0
	_queue.clear()
	for b in _bodies:
		if is_instance_valid(b):
			b.queue_free()
	_bodies.clear()
	_fix_pickups()
	for w in _walls:
		w.fall()
		Sfx.play("hold_slam", w.global_position + Vector2(0, -100), -3.0, 0.05, 2, 0.7)
	# הפרס: קצת לפני השחקן, בדרך החוצה (המחסומים כבר לא מוצקים) - לוקחים אותו בריצה
	_drop(PickupScript.SUPPLY, p, 70.0, REWARD_H, false)
	_drop(PickupScript.AMMO, p, 120.0, REWARD_H, false)
	_drop(PickupScript.HEALTH, p, 170.0, REWARD_H, false)
	_show("LINE HELD!", "SUPPLY DROP INCOMING", Color("7aff6a"), 3.2, 80)
	Sfx.play("hold_win", null, -1.0, 0.0, 1)
	Sfx.play("streak_up", null, -4.0, 0.0, 1)
	for z in get_tree().get_nodes_in_group("zombies"):   # מי שנשאר בזירה (ומי שחיכה מול המחסום הימני) - בא להילחם
		if not z.dead and not z.is_boss() and z.global_position.x > x0 - 100.0 and z.global_position.x < x1 + 500.0:
			z._alert_t = maxf(float(z._alert_t), 6.0)


func _cleanup_ui() -> void:
	if _ui != null and is_instance_valid(_ui):
		_ui.queue_free()
	_ui = null


func _exit_tree() -> void:
	_cleanup_ui()


func _show(text: String, sub: String, col: Color, dur: float, size: int) -> void:
	_banner = {"text": text, "sub": sub, "col": col, "t0": _now, "dur": dur, "size": size}


static func _fmt(s: float) -> String:
	var n := maxi(int(ceil(s)), 0)
	return "%d:%02d" % [n / 60, n % 60]


func is_active() -> bool:
	return state == ACTIVE


# ============================================================
#  המחסום: שקי חול + פח גלי + דלת מכונית + קרשים + תיל, ומנורת אזהרה.
#  לפני: רק שורת שקי חול נמוכה. slam() = נוחת מלמעלה. fall() = קורס החוצה ונעלם.
# ============================================================
class Barricade extends Node2D:
	var side := -1.0            # -1 = המחסום השמאלי (נופל שמאלה)
	var seed_v := 0
	var _st := 0                # 0 בסיס, 1 נוחת / עומד, 2 קורס
	var _k := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 3   # מתחת לשחקן (4) - הוא לא נבלע מאחורי המחסום

	func slam() -> void:
		_st = 1
		_k = 0.0

	func fall() -> void:
		_st = 2
		_k = 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _st == 1 and _k < 1.0:
			_k = minf(_k + delta / SLAM_T, 1.0)
		elif _st == 2:
			_k += delta / FALL_T
			if _k > 1.6:
				queue_free()
				return
		if Art.on_screen(self, global_position + Vector2(0, -120), 200.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var hw := WALL_VIS * 0.5
		if _st == 0:   # בסיס נמוך (עוד לא נסגר)
			_bags(hw, 1, 1.0)
			return
		var a := 1.0
		if _st == 1:
			var e := _k * _k   # נופל מהר ונוחת
			var bounce := sin(clampf((_k - 0.85) / 0.15, 0.0, 1.0) * PI) * 6.0 if _k > 0.85 else 0.0
			DrawBatch.set_transform(self, Vector2(0.0, -(1.0 - e) * (WALL_H + 380.0) - bounce))
		else:   # קורס החוצה סביב הפינה התחתונה החיצונה
			var f := clampf(_k, 0.0, 1.0)
			var rot := side * f * f * 1.45
			var piv := Vector2(side * hw, 0.0)
			a = clampf(1.6 - _k, 0.0, 1.0)
			DrawBatch.set_transform_matrix(self, Transform2D(rot, piv) * Transform2D(0.0, -piv))
		_wall(hw, a)
		DrawBatch.set_transform(self, Vector2.ZERO)
		if _st == 1 and _k >= 1.0 and fmod(_t, 0.6) < 0.3:   # הבזק של המנורה על הרצפה
			DrawBatch.circle(self, Vector2(0, -WALL_H - 14.0), 34.0, Color(1.0, 0.15, 0.1, 0.12))

	func _bags(hw: float, rows: int, a: float) -> void:
		var bw := WALL_VIS / 3.0
		for r in rows:
			var y := -11.0 - float(r) * 20.0
			var off := 0.0 if r % 2 == 0 else bw * 0.5
			for i in (3 if r % 2 == 0 else 2):
				var bx := -hw + bw * (float(i) + 0.5) + off
				var c := Color("8d7b52").lerp(Color("6e5f3e"), float((seed_v + i * 7 + r * 3) % 5) / 5.0)
				Art.oval(self, Vector2(bx, y), bw * 0.5 + 3.0, 11.0, Color(c, a), 0.0, Color(0.08, 0.06, 0.04, a), 1.4)
				DrawBatch.line(self, Vector2(bx - 4.0, y - 6.0), Vector2(bx - 2.0, y + 6.0), Color(0.3, 0.25, 0.15, 0.6 * a), 1.0)

	func _wall(hw: float, a: float) -> void:
		var ol := Color(0.06, 0.05, 0.05, a)
		var top := -WALL_H
		# שלד: עמודי פלדה
		DrawBatch.rect(self, Rect2(-hw + 6.0, top - 6.0, 6.0, WALL_H + 6.0), Color(0.22, 0.22, 0.24, a))
		DrawBatch.rect(self, Rect2(hw - 12.0, top - 6.0, 6.0, WALL_H + 6.0), Color(0.22, 0.22, 0.24, a))
		# פח גלי (חלודה)
		var sy := top + 8.0
		var sh := WALL_H - 70.0
		DrawBatch.rect(self, Rect2(-hw + 2.0, sy, WALL_VIS - 4.0, sh), Color(0.42, 0.3, 0.22, a))
		var x := -hw + 4.0
		var i := 0
		while x < hw - 4.0:
			DrawBatch.rect(self, Rect2(x, sy, 3.0, sh), Color(0.55, 0.4, 0.28, a) if i % 2 == 0 else Color(0.3, 0.21, 0.15, a))
			x += 6.0
			i += 1
		for rs in [[0.25, 0.3], [0.6, 0.22]]:   # כתמי חלודה
			DrawBatch.circle(self, Vector2(-hw * 0.3 + float(seed_v % 7) * 3.0, sy + sh * float(rs[0])), 10.0 * float(rs[1]) * 3.0, Color(0.5, 0.22, 0.1, 0.45 * a))
		DrawBatch.rect(self, Rect2(-hw + 2.0, sy, WALL_VIS - 4.0, sh), ol, false, 2.0)
		# דלת מכונית מוברגת
		var dy := sy + 18.0 + float(seed_v % 3) * 8.0
		var door := PackedVector2Array([Vector2(-hw + 8.0, dy), Vector2(hw - 10.0, dy + 4.0), Vector2(hw - 8.0, dy + 58.0), Vector2(-hw + 10.0, dy + 54.0)])
		Art.fill_shaded(self, door, Color(Color("3d5670") if seed_v % 2 == 0 else Color("7a3a32"), a), 0.18, 0.3, ol, 1.6)
		Art.fill(self, PackedVector2Array([Vector2(-hw + 14.0, dy + 6.0), Vector2(hw - 16.0, dy + 9.0), Vector2(hw - 18.0, dy + 26.0), Vector2(-hw + 14.0, dy + 24.0)]), Color(0.12, 0.16, 0.2, a), ol, 1.0)
		# פס אזהרה צהוב-שחור
		var by := sy + sh * 0.62
		DrawBatch.rect(self, Rect2(-hw, by, WALL_VIS, 16.0), Color(0.95, 0.75, 0.1, a))
		var sx := -hw
		while sx < hw:
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(sx, by + 16.0), Vector2(sx + 8.0, by), Vector2(sx + 14.0, by), Vector2(sx + 6.0, by + 16.0)]), Color(0.08, 0.08, 0.08, a))
			sx += 14.0
		DrawBatch.rect(self, Rect2(-hw, by, WALL_VIS, 16.0), ol, false, 1.5)
		# קרשים באלכסון
		Art.fill(self, PackedVector2Array([Vector2(-hw - 4.0, sy + 30.0), Vector2(-hw + 6.0, sy + 22.0), Vector2(hw + 4.0, sy + sh - 30.0), Vector2(hw - 6.0, sy + sh - 22.0)]), Color(0.55, 0.4, 0.24, a), ol, 1.3)
		# שקי חול למטה (3 שורות)
		_bags(hw, 3, a)
		# מוטות ברזל + תיל דוקרני למעלה
		for k in 5:
			var rx := -hw + 6.0 + float(k) * (WALL_VIS - 12.0) / 4.0
			DrawBatch.line(self, Vector2(rx, top + 8.0), Vector2(rx + float((k * 5 + seed_v) % 9) - 4.0, top - 14.0 - float((k * 7 + seed_v) % 10)), Color(0.35, 0.3, 0.28, a), 2.5)
		for k in 6:
			var wx := -hw + float(k) * WALL_VIS / 5.0
			DrawBatch.arc(self, Vector2(wx, top - 2.0), 9.0, 0.0, TAU, 10, Color(0.6, 0.6, 0.62, 0.9 * a), 1.3)
		# מנורת אזהרה
		var on := _st == 1 and fmod(_t, 0.6) < 0.3
		DrawBatch.rect(self, Rect2(-5.0, top - 22.0, 10.0, 12.0), Color(0.15, 0.15, 0.16, a))
		DrawBatch.circle(self, Vector2(0.0, top - 26.0), 6.0, Color(1.0, 0.2, 0.12, a) if on else Color(0.4, 0.08, 0.06, a))
		if on:
			DrawBatch.circle(self, Vector2(0.0, top - 26.0), 16.0, Color(1.0, 0.25, 0.15, 0.25 * a))


# ============================================================
#  אפקטים בעולם: אבק כשזומבי קופץ פנימה, מצנחים על הארגזים שנופלים
# ============================================================
class FX extends Node2D:
	var ev: Node = null
	var puffs: Array = []       # [pos, age]
	var chutes: Array = []      # pickups

	func _ready() -> void:
		z_index = 6

	func puff(p: Vector2) -> void:
		puffs.append([p, 0.0])

	func _process(delta: float) -> void:
		for pf in puffs:
			pf[1] = float(pf[1]) + delta
		puffs = puffs.filter(func(pf): return float(pf[1]) < 0.5)
		chutes = chutes.filter(func(c): return is_instance_valid(c) and not c._resting)
		if not puffs.is_empty() or not chutes.is_empty():
			queue_redraw()
		elif ev == null or not is_instance_valid(ev):
			queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for pf in puffs:
			var p: Vector2 = pf[0]
			var k: float = float(pf[1]) / 0.5
			for i in 5:
				var a := float(i) * TAU / 5.0 + 0.4
				DrawBatch.circle(self, p + Vector2(cos(a), sin(a) * 0.5) * (8.0 + 26.0 * k), 7.0 * (1.0 - k) + 2.0, Color(0.55, 0.5, 0.42, 0.45 * (1.0 - k)))
			for i in 4:   # שבבי פח
				DrawBatch.rect(self, Rect2(p + Vector2(float(i) * 9.0 - 14.0, -10.0 - 30.0 * k + 40.0 * k * k), Vector2(3, 3)), Color(0.45, 0.32, 0.22, 1.0 - k))
		for c in chutes:
			var cp: Vector2 = c.global_position
			var top := cp + Vector2(0, -62)
			DrawBatch.line(self, cp + Vector2(-8, -6), top + Vector2(-26, 6), Color(0.85, 0.85, 0.8, 0.8), 1.0)
			DrawBatch.line(self, cp + Vector2(8, -6), top + Vector2(26, 6), Color(0.85, 0.85, 0.8, 0.8), 1.0)
			DrawBatch.line(self, cp + Vector2(0, -8), top + Vector2(0, 2), Color(0.85, 0.85, 0.8, 0.8), 1.0)
			var canopy := PackedVector2Array()
			for i in 11:
				var a2 := PI + PI * float(i) / 10.0
				canopy.append(top + Vector2(cos(a2) * 30.0, sin(a2) * 18.0 + 6.0))
			Art.fill(self, canopy, Color(0.85, 0.35, 0.2) if int(cp.x) % 2 == 0 else Color(0.9, 0.85, 0.75), Art.OUTLINE, 1.3)
			for i in 3:
				var lx := top.x - 20.0 + float(i) * 20.0
				DrawBatch.line(self, Vector2(lx, top.y + 6.0), Vector2(lx * 0.9 + top.x * 0.1, top.y - 12.0), Color(0, 0, 0, 0.25), 1.0)


# ============================================================
#  HUD: באנר גדול (נכנס בטריקה) + שעון יורד מתחת לשעון של השלב
# ============================================================
class HoldUI extends Node2D:
	var ev: Node = null
	var _warm := false

	func _process(_d: float) -> void:
		if not _warm or (ev != null and is_instance_valid(ev) and (ev.state != WAIT or not ev._banner.is_empty())):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if ev == null or not is_instance_valid(ev):
			return
		var vs := get_viewport().get_visible_rect().size
		var f: Font = ev.font()
		if not _warm:
			_warm = true
			var all := "HOLD THE LINE SURVIVE 0123456789: SUPPLY DROP RELOAD! FINAL WAVE LINE HELD! INCOMING"
			DrawBatch.string(self, f, Vector2(10, 10), all, HORIZONTAL_ALIGNMENT_LEFT, -1, BANNER_FS, Color(1, 1, 1, 0.0))
			DrawBatch.string_outline(self, f, Vector2(10, 10), all, HORIZONTAL_ALIGNMENT_LEFT, -1, BANNER_FS, 10, Color(1, 1, 1, 0.0))
			for fs in [26, 30]:
				DrawBatch.string(self, f, Vector2(10, 10), all, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.0))
				DrawBatch.string_outline(self, f, Vector2(10, 10), all, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(1, 1, 1, 0.0))
		var now: float = ev._now
		# ---- השעון ----
		if ev.is_active():
			var left: float = maxf(float(ev.duration) - float(ev.t), 0.0)
			var urgent := left <= 5.0
			var beat := 0.5 + 0.5 * sin(now * TAU * 2.0)
			var c := Vector2(vs.x * 0.5, 146.0)
			var bw := 236.0
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.05, 0.04, 0.04, 0.72)
			sb.border_color = Color(1.0, 0.3, 0.2, 0.6 + 0.4 * beat) if urgent else Color(1.0, 0.8, 0.3, 0.8)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(8)
			DrawBatch.style_box(self, sb, Rect2(c.x - bw * 0.5, c.y - 22.0, bw, 50.0))
			var txt: String = "HOLD  " + ev._fmt(left)
			var fs := 30
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var sc := 1.0 + (0.12 * beat if urgent else 0.0)
			DrawBatch.set_transform(self, Vector2(c.x, c.y + 8.0), 0.0, Vector2(sc, sc))
			var col := Color(1.0, 0.35, 0.25) if urgent else Color(1.0, 0.86, 0.4)
			DrawBatch.string_outline(self, f, Vector2(-w * 0.5, 0.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.9))
			DrawBatch.string(self, f, Vector2(-w * 0.5, 0.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			DrawBatch.set_transform(self, Vector2.ZERO)
			var k := clampf(float(ev.t) / float(ev.duration), 0.0, 1.0)
			var bx := c.x - bw * 0.5 + 12.0
			DrawBatch.rect(self, Rect2(bx, c.y + 16.0, bw - 24.0, 5.0), Color(0, 0, 0, 0.6))
			DrawBatch.rect(self, Rect2(bx, c.y + 16.0, (bw - 24.0) * k, 5.0), Color(1.0, 0.75, 0.2).lerp(Color(0.5, 1.0, 0.4), k))
			# ההפוגה מסומנת על הפס
			DrawBatch.rect(self, Rect2(bx + (bw - 24.0) * LULL.x, c.y + 14.0, (bw - 24.0) * (LULL.y - LULL.x), 2.0), Color(0.6, 0.85, 1.0, 0.8))
		# ---- באנר ----
		var bn: Dictionary = ev._banner
		if bn.is_empty():
			return
		var age := now - float(bn.t0)
		var dur: float = bn.dur
		if age > dur:
			return
		var a := clampf((dur - age) / 0.4, 0.0, 1.0)
		var pop := clampf(age / 0.18, 0.0, 1.0)
		var scl := lerpf(2.4, 1.0, pop * pop) + (sin(clampf((age - 0.18) / 0.25, 0.0, 1.0) * PI) * 0.08 if age > 0.18 else 0.0)
		var shake := Vector2(sin(age * 90.0), cos(age * 77.0)) * 5.0 * clampf(1.0 - (age - 0.18) / 0.3, 0.0, 1.0) if age > 0.18 else Vector2.ZERO
		var size: float = float(bn.size)
		scl *= size / float(BANNER_FS)
		var text: String = bn.text
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BANNER_FS).x
		var center := Vector2(vs.x * 0.5, vs.y * 0.34) + shake
		DrawBatch.rect(self, Rect2(0.0, center.y - size * 0.95, vs.x, size * 1.35 + (30.0 if bn.sub != "" else 0.0)), Color(0, 0, 0, 0.35 * a * pop))
		DrawBatch.set_transform(self, center, -0.03, Vector2(scl, scl))
		var bcol: Color = bn.col
		DrawBatch.string_outline(self, f, Vector2(-tw * 0.5, BANNER_FS * 0.3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, BANNER_FS, 10, Color(0.05, 0.02, 0.02, a))
		DrawBatch.string(self, f, Vector2(-tw * 0.5, BANNER_FS * 0.3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, BANNER_FS, Color(bcol, a))
		DrawBatch.set_transform(self, Vector2.ZERO)
		var sub: String = bn.sub
		if sub != "" and age > 0.3:
			var sa := a * clampf((age - 0.3) / 0.25, 0.0, 1.0)
			var sw := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
			var sp := Vector2(center.x - sw * 0.5, center.y + size * 0.3 + 34.0)
			DrawBatch.string_outline(self, f, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color(0, 0, 0, sa))
			DrawBatch.string(self, f, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.95, 0.85, sa))
