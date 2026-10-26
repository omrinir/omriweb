extends Node
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  ESCAPE - "THE HORDE" (שלבים 11, 23, 41, 55 - levels/level_events.gd)
#  בערך ב-START_AT מהשלב (TRIGGER) מאחורי השחקן, בקצה השמאלי של המסך, קם "צונאמי" של מתים:
#  קיר כהה וצפוף של צלליות (ידיים מושטות, עיניים בוהקות, אבק) שמתקדם ימינה קצת לאט יותר מהריצה של השחקן
#  (player.gd: הליכה 205, ריצה 320). מי שהולך / עוצר להילחם יותר מדי - נתפס.
#  העדר = ציור אחד (DrawBatch), לא מאות זומבים אמיתיים. ההתנגשות = רק בדיקת x מול החזית (_hx).
#    נגיעה בקיר: לב אחד + הדיפה חזקה קדימה ולמעלה (גם מעל מכשול), והעדר "נתקל" לרגע (STUMBLE) - יש זמן לברוח.
#    זומבים אמיתיים שהעדר עוקף - נבלעים בתוכו (נעלמים בהתזת דם).
#  RUN! על המסך, מד למעלה (עדר -> שחקן -> SAFE), וכשהעדר מחוץ למסך: זוהר אדום בצד שמאל + מרחק במטרים.
#  בדרך: רצים מקדימה מהתמהיל של השלב (SPAWN_EVERY / SPAWN_BUDGET) - רץ-ויורה, לא רק ריצה.
#  נקודת הביטחון (SAFE): לפני נקודת הביקורת, CHASE_LEN אחרי ההתחלה לכל היותר, ורחוק מסצנת סיפור (STORY_GAP).
#    שם העדר נעצר, שואג ומתפורר לאבק. רשת ביטחון: אחרי MAX_T שניות הוא מוותר בכל מקרה.
#  קיר המעבר (environment/pass_barrier.gd) כבוי בזמן המרדף - אחרת הוא נועל את השחקן מול העדר.
#  התחלה מנקודת הביקורת (השחקן כבר אחרי ה-TRIGGER) -> אין מרדף. מוות -> העדר עוצר; TRY AGAIN בונה הכל מחדש.
#  לשנות: START_AT, CHASE_LEN, CP_GAP, STORY_GAP, SPEED, START_SPEED, RAMP_T, CATCHUP_GAP, CATCHUP_SPEED,
#    WALL_H, TOUCH_CD, KNOCK, STUMBLE_T, SPAWN_EVERY, SPAWN_BUDGET, MAX_T, CRUMBLE_T.
# ============================================================

const Sfx := preload("res://sfx.gd")
const StreakUI := preload("res://ui/kill_streak.gd")
const StoryDB := preload("res://story/story_db.gd")
const Particles := preload("res://particles.gd")

const START_AT := 0.15             # איפה העדר קם (חלק מאורך השלב)
const CHASE_LEN := 3300.0          # כמה פיקסלים המרדף לכל היותר (בערך 3 מסכים)
const MIN_LEN := 1400.0            # פחות מזה (סצנת סיפור / נקודת ביקורת קרובות) -> אין מרדף בשלב
const CP_GAP := 350.0              # נקודת הביטחון לפחות כך לפני נקודת הביקורת
const STORY_GAP := 1100.0          # מרחק מסצנת סיפור (שלב 55: STRANGER ב-4500)
const SPEED := [210.0, 232.0, 258.0]   # מהירות העדר (קל / רגיל / קשה). הליכה = 205, ריצה = 320
const START_SPEED := 140.0         # בהתחלה לאט (רגע להבין מה קורה)
const RAMP_T := 2.5                # שניות עד מהירות מלאה
const CATCHUP_GAP := 950.0         # רחוק מזה מהשחקן -> העדר מדביק (נשאר קרוב מחוץ למסך)
const CATCHUP_SPEED := 330.0
const WALL_H := 330.0              # גובה אזור הפגיעה מעל הכביש (כל הקומות בשלבים האלה נמוכות מזה)
const TOUCH_CD := [2.2, 1.8, 1.4]  # שניות בין שתי פגיעות של הקיר (קל / רגיל / קשה)
const KNOCK := Vector2(560.0, -480.0)   # הדיפה קדימה ולמעלה
const STUMBLE_T := 1.6             # אחרי פגיעה העדר מאט לרגע (STUMBLE_K)
const STUMBLE_K := 0.3
const SPAWN_EVERY := [3.6, 2.9, 2.4]    # כל כמה שניות קבוצה מקדימה
const SPAWN_BUDGET := [8, 11, 14]       # כמה רצים מקדימה בכל המרדף
const AHEAD := Vector2(640.0, 820.0)    # כמה לפני השחקן הם מופיעים
const ALERT := 6.0                 # רצים אל השחקן מיד
const MAX_T := 75.0                # רשת ביטחון: אחרי זה העדר מוותר
const CRUMBLE_T := 2.6             # כמה זמן העדר מתפורר בסוף
const BODY := 1500.0               # עומק הגוש שמצוירים בו דמויות (מאחורי החזית)
const PX_PER_M := 40.0             # למד המרחק
const INTRO_T := 5.2               # לא לפני שכותרת השלב (hud.gd, 5 שניות) נעלמת
const HUSH_BEFORE := 360.0         # המרחק לפני ההתחלה שבו המוזיקה נסוגה לשקט (effects/music_mood.gd)

const SOUNDS := {   # צליל מסונתז (לא קובץ): רעם של אלפי רגליים
	"esc_rumble": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 1.6, 0.3, 1.5, 0.9, 0.05, 0], ["S", 48, 36, 0.0, 1.5, 0.25, 1.8, 0.5, 1.0, 0.2], ["C", 0, 0, 0.0, 1.4, 0.2, 2.0, 0.25, 1.0, 0]]},
}

enum { WAIT, CHASE, CRUMBLE, DONE }

var main: Node
var floor_y: float = 630.0
var hud_layer: CanvasLayer

var _state := WAIT
var _trigger_x := 0.0
var _safe_x := 0.0
var _hx := 0.0                     # החזית של העדר (x בעולם)
var _t := 0.0                      # זמן מאז שהעדר קם
var _anim := 0.0                   # שעון לאנימציה
var _touch_cd := 0.0
var _stumble := 0.0
var _spawn_t := 2.0
var _budget := 0
var _end_t := 0.0                  # זמן מאז תחילת ההתפוררות
var _timed_out := false
var _roar_t := 0.0
var _rumble_t := 0.0
var _shake_t := 0.0
var _player_dead := false
var _barrier: Node = null
var _rng := RandomNumberGenerator.new()
var _world: Node2D                 # הציור בעולם (העדר + נקודת הביטחון)
var _ui: Node2D                    # ה-HUD (RUN!, מד, חץ)
var _banner_t := -1.0              # RUN! (שניות מאז שהופיע)
var _safe_t := -1.0                # SAFE! (שניות מאז שהופיע)
# דמויות (נוצרות פעם אחת, אותו מראה כל פעם): [d, גודל, פאזה, הרמת ידיים, סוג עיניים]
var _figs: Array = []
var _runners: Array = []
var _crest: Array = []
# ציור מהיר: הגיאומטריה של דמות נבנית פעם אחת (מקומית, כפות הרגליים ב-0,0), ובכל פריים יש לדמות טרנספורם אחד.
# קודם: ~12 קריאות ציור לכל דמות, כ-40 דמויות על המסך = 1.1-2.4 ms בכל פריים רק לבניית העדר.
# כל המשולשים של העדר נאספים ל-_gp/_gc ונשלחים ביחד (DrawBatch.tris) - אותו מראה בדיוק.
const HEAD_N := 16                 # צלעות לראש / לזוהר העיניים / לעין / לאבק (מספיק לצללית כהה בגודל הזה)
const GLOW_N := 10
const EYE_N := 6
const DUST_N := 20
const STEP := 18.0                 # רוחב רצועה בגוש
const EYE_COLS := [Color(1.0, 0.22, 0.12), Color(1.0, 0.8, 0.25), Color(0.75, 1.0, 0.35)]   # אדום, צהוב, ירקרק
var _tpl_body := PackedVector2Array()   # גוף + ראש
var _tpl_glow := PackedVector2Array()   # זוהר סביב העיניים
var _tpl_eyes := PackedVector2Array()   # שתי העיניים
var _dust := PackedVector2Array()       # עיגול יחידה לאבק
var _lim := PackedVector2Array()        # ידיים + אצבעות (+ רגליים לרצים), נבנה מחדש לכל דמות
var _pile_tab := PackedFloat32Array()   # _pile(d) לכל רצועה (המרחק של רצועה מהחזית קבוע)
var _strip_c := PackedColorArray()      # צבעי הרצועות (משתנים רק בהתפוררות)
var _strip_k := -1.0
var _sp := PackedVector2Array()
var _gp := PackedVector2Array()         # כל המשולשים של העדר בפריים הזה
var _gc := PackedColorArray()
var _cb := PackedColorArray()           # צבע אחיד לכל חלק (fill - בלי לולאה)
var _cbl := PackedColorArray()
var _cg := PackedColorArray()
var _ce := PackedColorArray()
var _cd := PackedColorArray()


func start() -> void:
	Sfx.register(SOUNDS)
	_rng.randomize()
	var p: Node2D = main._player
	var lw: float = main.level_w
	_trigger_x = lw * START_AT
	var cp_x: float = lw * float(main.CHECKPOINT_AT)
	if main._checkpoint != null:
		cp_x = main._checkpoint.global_position.x
	_safe_x = minf(_trigger_x + CHASE_LEN, cp_x - CP_GAP)
	for sc in StoryDB.for_level(Game.level):   # לא ליד סצנת סיפור
		var sx := float(sc.get("x", -99999.0))
		if sx > _trigger_x - STORY_GAP and sx < _safe_x + STORY_GAP:
			_safe_x = minf(_safe_x, sx - STORY_GAP)
	_safe_x = minf(_safe_x, lw - 1500.0 - 200.0)   # לא בזירת הבוס
	# התחלה מנקודת הביקורת / אין מקום למרדף -> אין אירוע
	if p == null or p.global_position.x > _trigger_x - 100.0 or _safe_x - _trigger_x < MIN_LEN:
		queue_free()
		return
	Sfx.warm(SOUNDS)   # הרעם נבנה עכשיו, בטעינה - לא ברגע שהעדר קם (שם זו הייתה קפיאה של רבע שנייה)
	_budget = int(SPAWN_BUDGET[_diff()])
	_make_figs()
	_world = Node2D.new()
	_world.z_index = 6   # מעל השחקן (4) והזומבים (3): כשהוא תופס אותך אתה בתוכו
	main.add_child(_world)
	_world.draw.connect(_draw_world)
	_ui = Node2D.new()
	hud_layer.add_child(_ui)
	_ui.draw.connect(_draw_ui)
	for n in main.get_children():
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("pass_barrier.gd"):
			_barrier = n


func _exit_tree() -> void:
	if _barrier != null and is_instance_valid(_barrier):
		_barrier.set_physics_process(true)
	for n in [_world, _ui]:
		if n != null and is_instance_valid(n):
			n.queue_free()


func _diff() -> int:
	return clampi(int(Settings.difficulty), 0, 2)


# העדר בדרך (levels/flank_director.gd לא שולח אז אף אחד מאחור)
func is_active() -> bool:
	return _state == CHASE or _state == CRUMBLE


func _physics_process(delta: float) -> void:
	if main == null or _world == null:
		return
	var p: Node2D = main._player
	if p == null or not is_instance_valid(p):
		return
	_anim += delta
	if _banner_t >= 0.0:
		_banner_t += delta
	if _safe_t >= 0.0:
		_safe_t += delta
	_world.queue_redraw()
	_ui.queue_redraw()
	var paused: bool = main.clock_paused or main._finished or get_tree().get_first_node_in_group("story_scene") != null
	match _state:
		WAIT:
			if not paused and not p.dead and p.global_position.x >= _trigger_x and _anim > INTRO_T:
				_begin(p)
			elif not paused and not p.dead and p.global_position.x >= _trigger_x - HUSH_BEFORE:   # השקט שלפני (main.music_hush)
				main.music_hush()
		CHASE:
			if paused:
				return
			main.music_hot(0.5)   # ההמון הוא לא זומבים בקבוצה: המוזיקה נשארת פתוחה כל הבריחה
			_chase(p, delta)
		CRUMBLE:
			_end_t += delta
			if _end_t > CRUMBLE_T + 2.2:
				_state = DONE
				queue_free()


func _begin(p: Node2D) -> void:
	_state = CHASE
	var v := _view()
	_hx = minf(v.position.x - 70.0, p.global_position.x - 420.0)   # בקצה השמאלי של המסך
	_banner_t = 0.0
	_spawn_t = 1.5
	Sfx.play("roar", null, 6.0, 0.05, 2, 0.55)
	Sfx.play("esc_rumble", null, 4.0, 0.05, 2)
	Sfx.play("zscream", Vector2(_hx + 60.0, floor_y - 120.0), 2.0, 0.2, 3)
	main.music_hit()
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(12.0, 0.7)


func _chase(p: Node2D, delta: float) -> void:
	_t += delta
	_touch_cd -= delta
	_stumble -= delta
	_spawn_t -= delta
	var px := p.global_position.x
	# קיר המעבר כבוי בזמן המרדף (אם הוא כבר עומד - נותנים לו להיעלם)
	if _barrier != null and is_instance_valid(_barrier):
		if _barrier.get("_wall") != null:
			_barrier.set("_fade", true)
			_barrier.set_physics_process(true)
		else:
			_barrier.set_physics_process(false)
	if p.dead:
		if not _player_dead:
			_player_dead = true
			Sfx.play("roar", Vector2(_hx, floor_y - 120.0), 4.0, 0.05, 2, 0.6)
		return
	# הגיע לנקודת הביטחון / הזמן נגמר -> העדר מתפורר
	if px >= _safe_x or _t > MAX_T:
		_timed_out = px < _safe_x
		_end(p)
		return
	# מהירות
	var sp: float = float(SPEED[_diff()])
	sp = lerpf(START_SPEED, sp, clampf(_t / RAMP_T, 0.0, 1.0))
	var gap := px - _hx
	if gap > CATCHUP_GAP:
		sp = maxf(sp, CATCHUP_SPEED)
	if _stumble > 0.0:
		sp *= STUMBLE_K
	if px < _hx - 40.0:   # השחקן בתוכו (נדחף / הלך אחורה) - העדר לא עובר אותו, מחכה שההדיפה תוציא אותו
		sp = 0.0
	_hx += sp * delta
	# נגיעה
	var py := p.global_position.y
	if px < _hx + 8.0 and py > floor_y - WALL_H and _touch_cd <= 0.0:
		_touch_cd = float(TOUCH_CD[_diff()])
		_stumble = STUMBLE_T
		p.hurt(1, Vector2(1.0, 0.0))
		if "velocity" in p:
			var vel: Vector2 = p.velocity
			p.velocity = Vector2(maxf(vel.x, KNOCK.x), minf(vel.y, KNOCK.y))
		Sfx.play("zscream", Vector2(_hx, floor_y - 100.0), 3.0, 0.2, 3)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(9.0, 0.35)
	_absorb()
	_spawn_ahead(p)
	_sounds(gap)


# זומבים שהעדר עוקף - נבלעים
func _absorb() -> void:
	var fx := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(z) or z.dead or z.is_boss():
			continue
		var zp: Vector2 = z.global_position
		if zp.x > _hx - 25.0 or zp.y < floor_y - WALL_H - 60.0 or zp.y > floor_y + 80.0:
			continue
		if fx < 3:
			fx += 1
			Particles.burst(main, zp + Vector2(0.0, -30.0), "hit", Vector2(-1.0, -0.4), 10)
		z.queue_free()


# רצים מקדימה, מהתמהיל של השלב
func _spawn_ahead(p: Node2D) -> void:
	if _spawn_t > 0.0 or _budget <= 0:
		return
	_spawn_t = float(SPAWN_EVERY[_diff()])
	var px := p.global_position.x
	if px + AHEAD.x > _safe_x - 150.0:   # לא אחרי נקודת הביטחון
		return
	var x := _spot(px)
	if x < 0.0:
		_spawn_t = 0.5
		return
	var k0: int = main._pick_kind(_rng)
	if k0 == 8:   # זוחל תקרה - לא כאן
		k0 = 1
	var n := mini(_rng.randi_range(1, 2), _budget)
	if k0 == 10 or k0 == 15:   # חולדות / כלבים - הגודל שלהם
		n = int(main._group_size(k0, _rng))
	for z in main._spawn_group(_rng, x, floor_y, k0, n, false):
		if z == null or not is_instance_valid(z):
			continue
		if z.is_boss():
			z.queue_free()
			continue
		_budget -= 1
		z.dormant = false
		z._dir = -1.0
		z._alert_t = ALERT


# מקום פנוי על הכביש מקדימה (כמו levels/pace_director.gd). -1 = אין
func _spot(px: float) -> float:
	var ss: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
	for i in 8:
		var x := px + _rng.randf_range(AHEAD.x, AHEAD.y) + float(i) * 37.0
		if main._near_brick(x) or main._near_brick(x + 110.0):
			continue
		if main._spawn_blocked(x - 30.0, x + 140.0):
			continue
		var ray := PhysicsRayQueryParameters2D.create(Vector2(x, floor_y - 30.0), Vector2(x, floor_y + 12.0), 1)
		var hit: Dictionary = ss.intersect_ray(ray)
		if hit.is_empty() or absf(float(hit.position.y) - floor_y) > 6.0:
			continue
		var q := PhysicsShapeQueryParameters2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(130.0, 50.0)
		q.shape = r
		q.transform = Transform2D(0.0, Vector2(x + 50.0, floor_y - 32.0))
		q.collision_mask = 1
		if not ss.intersect_shape(q, 1).is_empty():
			continue
		return x
	return -1.0


func _sounds(gap: float) -> void:
	var d: float = get_physics_process_delta_time()
	_roar_t -= d
	_rumble_t -= d
	_shake_t -= d
	var near := clampf(1.0 - (gap - 200.0) / 900.0, 0.0, 1.0)   # 1 = צמוד
	if _rumble_t <= 0.0:
		_rumble_t = 1.3
		Sfx.play("esc_rumble", null, lerpf(-14.0, 2.0, near), 0.08, 2)
	if _roar_t <= 0.0:
		_roar_t = _rng.randf_range(0.7, 1.4)
		var nm: String = ["groan", "zscream", "groan2", "zscream2"][_rng.randi() % 4]
		Sfx.play(nm, Vector2(_hx - _rng.randf_range(0.0, 200.0), floor_y - 120.0), lerpf(-8.0, 2.0, near), 0.25, 3)
	if near > 0.55 and _shake_t <= 0.0:   # האדמה רועדת כשהוא קרוב
		_shake_t = 0.25
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(2.5 * near, 0.3)


func _end(p: Node2D) -> void:
	_state = CRUMBLE
	_end_t = 0.0
	_safe_t = 0.0
	if _barrier != null and is_instance_valid(_barrier):
		_barrier.set_physics_process(true)
	Sfx.play("roar", Vector2(_hx, floor_y - 120.0), 6.0, 0.05, 2, 0.5)
	Sfx.play("esc_rumble", null, 0.0, 0.05, 2, 0.8)
	Sfx.play("streak_up" if Sfx.has_sound("streak_up") else "boost", null, 0.0, 0.0, 1)
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(8.0, 0.8)
	for i in 6:   # אבק לאורך החזית
		Particles.burst(main, Vector2(_hx - float(i) * 70.0, floor_y - 40.0 - float(i % 3) * 60.0), "smoke", Vector2.ZERO, 6)
	if not _timed_out:
		Game.on_style("escape", 40.0)


# ============================================================
#  ציור
# ============================================================
func _view() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var vs := get_viewport().get_visible_rect().size
	var a: Vector2 = inv * Vector2.ZERO
	var b: Vector2 = inv * vs
	return Rect2(a, b - a)


# גובה הגוש מעל הכביש לפי המרחק מהחזית (d): עולה מהר, פסגה שנוטה קדימה כמו גל, ואז יורד קצת
func _pile(d: float) -> float:
	var h := 250.0 * smoothstep(0.0, 230.0, d) + 45.0 * exp(-pow((d - 190.0) / 90.0, 2.0))
	return h - 60.0 * smoothstep(500.0, 1400.0, d)


func _make_figs() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 7311
	for i in 56:   # בתוך הגוש
		_figs.append([70.0 + float(i) * 25.0 + r.randf_range(-10.0, 10.0), r.randf_range(0.9, 1.3), r.randf() * TAU, r.randf(), r.randi() % 3])
	for i in 7:    # רצים בחזית (על הכביש)
		_runners.append([float(i) * 22.0 + r.randf_range(0.0, 12.0), r.randf_range(0.95, 1.15), r.randf() * TAU, r.randf(), r.randi() % 3])
	for i in 6:    # על הפסגה, צוללים קדימה
		_crest.append([120.0 + float(i) * 28.0 + r.randf_range(-8.0, 8.0), r.randf_range(1.0, 1.25), r.randf() * TAU, r.randf(), r.randi() % 3])
	# הצורות הקבועות של דמות (פונה ימינה): גוף (מרובע) + ראש, זוהר העיניים, העיניים
	_tpl_body = PackedVector2Array([Vector2(-9, -32), Vector2(9, -32), Vector2(12, -60), Vector2(-9, -32), Vector2(12, -60), Vector2(-10, -62)])
	_tpl_body.append_array(_disc(Vector2(4, -70), 9.0, HEAD_N))
	_tpl_glow = _disc(Vector2(9, -72), 5.0, GLOW_N)
	_tpl_eyes = _disc(Vector2(7, -72), 1.7, EYE_N)
	_tpl_eyes.append_array(_disc(Vector2(11, -72), 1.7, EYE_N))
	_dust = _disc(Vector2.ZERO, 1.0, DUST_N)
	_lim.resize(36)
	_cb.resize(_tpl_body.size() + 24)
	_cbl.resize(_tpl_body.size() + 36)
	_cg.resize(_tpl_glow.size())
	_ce.resize(_tpl_eyes.size())
	_cd.resize(_dust.size())
	_pile_tab.resize(int((BODY + 900.0) / STEP) + 2)
	for i in _pile_tab.size():
		_pile_tab[i] = _pile(STEP * float(i + 1) - 6.0)


# עיגול מלא כמשולשי מניפה (מרכז, נקודה, הנקודה הבאה)
func _disc(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		out.append_array([c, c + Vector2.from_angle(TAU * float(i) / float(n)) * r, c + Vector2.from_angle(TAU * float(i + 1) / float(n)) * r])
	return out


func _draw_world() -> void:
	DrawBatch.begin(_world)
	_draw_b()
	DrawBatch.end(_world)


func _draw_b() -> void:
	if _state == WAIT or _state == DONE:
		return
	var v := _view()
	if _state == CHASE:
		_draw_safe(v)
	var k := 1.0   # 1 = שלם, 0 = התפורר
	if _state == CRUMBLE:
		k = 1.0 - clampf(_end_t / CRUMBLE_T, 0.0, 1.0)
		if k <= 0.0:
			return
	if _hx < v.position.x - 40.0:   # מחוץ למסך
		return
	var sink := (1.0 - k) * 300.0   # בהתפוררות הכל שוקע
	var t := _anim
	var left := maxf(v.position.x - 40.0, _hx - BODY - 900.0)
	_gp.clear()
	_gc.clear()
	# ---- הגוש: רצועות אנכיות, למעלה אדמדם-כהה, למטה שחור ----
	var nc := clampi(int(ceil((_hx + 6.0 - left) / STEP)), 0, _pile_tab.size())
	_sp.resize(nc * 6)
	var x := _hx + 6.0
	var prev := Vector2(x, floor_y - 4.0 + sink)
	var by := floor_y + 8.0
	for i in nc:
		var nx := x - STEP
		var d := STEP * float(i + 1) - 6.0
		var h := _pile_tab[i] + 12.0 * sin(d * 0.09 + t * 3.0) + 7.0 * sin(d * 0.23 - t * 5.0)
		var cur := Vector2(nx, floor_y - maxf(h, 4.0) + sink)
		var j := i * 6
		_sp[j] = prev
		_sp[j + 1] = cur
		_sp[j + 2] = Vector2(nx, by)
		_sp[j + 3] = prev
		_sp[j + 4] = Vector2(nx, by)
		_sp[j + 5] = Vector2(x, by)
		prev = cur
		x = nx
	_gp.append_array(_sp)
	if k != _strip_k:
		_strip_k = k
		var top_c := Color(0.17, 0.09, 0.09, 0.97 * minf(k * 1.6, 1.0))
		var bot_c := Color(0.03, 0.025, 0.03, 0.98 * minf(k * 1.6, 1.0))
		_strip_c.resize(_pile_tab.size() * 6)
		for i in _pile_tab.size():
			var j := i * 6
			_strip_c[j] = top_c
			_strip_c[j + 1] = top_c
			_strip_c[j + 2] = bot_c
			_strip_c[j + 3] = top_c
			_strip_c[j + 4] = bot_c
			_strip_c[j + 5] = bot_c
	_gc.append_array(_strip_c.slice(0, nc * 6))
	# ---- דמויות בתוך הגוש (נסחפות לאט אחורה, נעלמות בקצוות) ----
	for f in _figs:
		var d := fposmod(float(f[0]) - 60.0 + t * 22.0, BODY - 60.0) + 60.0
		var fx := _hx - d + 6.0 * sin(t * 3.0 + float(f[2]))
		if fx < v.position.x - 60.0 or fx > v.end.x + 60.0:
			continue
		var a := clampf((d - 60.0) / 60.0, 0.0, 1.0) * clampf((BODY - d) / 120.0, 0.0, 1.0) * k
		var fy := floor_y - _pile(d) + 34.0 + 4.0 * sin(t * 7.0 + float(f[2])) + sink
		var lean := 0.15 + 0.35 * exp(-pow((d - 190.0) / 120.0, 2.0))
		_fig(Vector2(fx, fy), float(f[1]), lean, t * 7.0 + float(f[2]), float(f[3]), int(f[4]), false, a, 0.6)
	# ---- הפסגה: צוללים קדימה מעל החזית ----
	for f in _crest:
		var d: float = float(f[0]) + 14.0 * sin(t * 1.7 + float(f[2]))
		var fx := _hx - d
		if fx < v.position.x - 60.0 or fx > v.end.x + 60.0:
			continue
		var fy := floor_y - _pile(d) + 18.0 + 6.0 * sin(t * 5.0 + float(f[2])) + sink
		_fig(Vector2(fx, fy), float(f[1]), 0.75, t * 6.0 + float(f[2]), 1.0, int(f[4]), false, k, 0.85)
	# ---- רצים בחזית ----
	for f in _runners:
		var d: float = float(f[0]) + 10.0 * sin(t * 2.3 + float(f[2]))
		var fx := _hx - d
		if fx < v.position.x - 60.0 or fx > v.end.x + 60.0:
			continue
		var fy := floor_y + absf(sin(t * 9.0 + float(f[2]))) * -5.0 + sink
		_fig(Vector2(fx, fy), float(f[1]), 0.32, t * 11.0 + float(f[2]), float(f[3]), int(f[4]), true, k, 1.0)
	# ---- אבק מקדימה ומתחת ----
	var da := maxf(k, 0.25)
	for i in 22:
		var q := fposmod(t * 0.8 + float(i) / 22.0, 1.0)
		var dx := 40.0 - q * 300.0 + 30.0 * sin(float(i) * 3.7)
		var dy := -8.0 - q * (60.0 + float(i % 4) * 30.0)
		var rr := 16.0 + q * 46.0
		_gp.append_array(Transform2D(0.0, Vector2(rr, rr), 0.0, Vector2(_hx + dx, floor_y + dy + sink * 0.3)) * _dust)
		_cd.fill(Color(0.42, 0.36, 0.3, 0.16 * (1.0 - q) * da))
		_gc.append_array(_cd)
	DrawBatch.tris(_world, _gp, _gc)
	# בהתפוררות: ענן אבק גדול שעולה
	if _state == CRUMBLE:
		var e := 1.0 - k
		for i in 14:
			var cx := _hx - float(i) * 70.0 + 20.0 * sin(float(i) * 1.3)
			var cy := floor_y - 60.0 - e * (80.0 + float(i % 4) * 50.0)
			DrawBatch.circle(_world, Vector2(cx, cy), 40.0 + e * 60.0, Color(0.38, 0.33, 0.28, 0.4 * sin(e * PI)))


# דמות אחת (פונה ימינה, כפות הרגליים ב-c). eye: 0 אדום, 1 צהוב, 2 ירקרק. נאספת ל-_gp/_gc
func _fig(c: Vector2, s: float, lean: float, ph: float, arms: float, eye: int, legs: bool, a: float, light: float) -> void:
	if a <= 0.01:
		return
	var xf := Transform2D(lean, Vector2(s, s), 0.0, c)
	# ידיים מושטות קדימה (ולמעלה) + אצבעות. רגליים רק לרצים
	var h1 := Vector2(28.0 + 6.0 * sin(ph), -64.0 - arms * 22.0 + 5.0 * cos(ph * 1.3))
	var h2 := Vector2(24.0 + 6.0 * cos(ph * 0.9), -54.0 - arms * 14.0 + 5.0 * sin(ph * 1.1))
	_limb(0, Vector2(6, -58), h1, 2.25)
	_limb(6, Vector2(2, -56), h2, 2.25)
	_limb(12, h1, h1 + Vector2(5, -3), 1.0)
	_limb(18, h2, h2 + Vector2(5, 2), 1.0)
	var body := Color(0.05 + 0.08 * light, 0.04 + 0.05 * light, 0.05 + 0.05 * light, a)
	_gp.append_array(xf * _tpl_body)
	if legs:
		var sw := sin(ph) * 13.0
		_limb(24, Vector2(0, -34), Vector2(sw, 0), 3.0)
		_limb(30, Vector2(0, -34), Vector2(-sw, 0), 3.0)
		_gp.append_array(xf * _lim)
		_cbl.fill(body)
		_gc.append_array(_cbl)
	else:
		_gp.append_array(xf * _lim.slice(0, 24))
		_cb.fill(body)
		_gc.append_array(_cb)
	# עיניים בוהקות
	var ec: Color = EYE_COLS[eye]
	var flick := 0.75 + 0.25 * sin(ph * 1.7)
	_gp.append_array(xf * _tpl_glow)
	_cg.fill(Color(ec, 0.16 * a * flick))
	_gc.append_array(_cg)
	_gp.append_array(xf * _tpl_eyes)
	_ce.fill(Color(ec, a * flick))
	_gc.append_array(_ce)


# קו עבה (יד / אצבע / רגל) כשני משולשים ב-_lim, מקומי לדמות. hw = חצי רוחב
func _limb(i: int, a: Vector2, b: Vector2, hw: float) -> void:
	var d := b - a
	var n := Vector2(-d.y, d.x) * (hw / maxf(d.length(), 0.001))
	_lim[i] = a + n
	_lim[i + 1] = b + n
	_lim[i + 2] = b - n
	_lim[i + 3] = a + n
	_lim[i + 4] = b - n
	_lim[i + 5] = a - n


# נקודת הביטחון: זיקוק ירוק על הכביש
func _draw_safe(v: Rect2) -> void:
	if _safe_x < v.position.x - 50.0 or _safe_x > v.end.x + 50.0:
		return
	var b := Vector2(_safe_x, floor_y)
	var fl := 0.8 + 0.2 * sin(_anim * 21.0) * sin(_anim * 13.0)
	DrawBatch.circle(_world, b + Vector2(0, -16), 70.0, Color(0.3, 1.0, 0.45, 0.08 * fl))
	DrawBatch.circle(_world, b + Vector2(0, -16), 34.0, Color(0.4, 1.0, 0.5, 0.14 * fl))
	DrawBatch.rect(_world, Rect2(b.x - 3.0, b.y - 22.0, 6.0, 22.0), Color(0.75, 0.15, 0.12))
	DrawBatch.circle(_world, b + Vector2(0, -24), 5.0 * fl, Color(0.85, 1.0, 0.85))
	for i in 5:   # עשן ירוק שעולה
		var q := fposmod(_anim * 0.5 + float(i) / 5.0, 1.0)
		DrawBatch.circle(_world, b + Vector2(8.0 * sin(q * 5.0 + float(i)), -30.0 - q * 120.0), 6.0 + q * 14.0, Color(0.45, 0.9, 0.5, 0.22 * (1.0 - q)))


# ---- HUD: RUN!, המד למעלה, חץ לעדר מחוץ למסך, SAFE! ----
func _draw_ui() -> void:
	DrawBatch.begin(_ui)
	_draw_ui_b()
	DrawBatch.end(_ui)


func _draw_ui_b() -> void:
	if _state == WAIT or _state == DONE:
		return
	var vs := _ui.get_viewport().get_visible_rect().size
	var p: Node2D = main._player
	var f := StreakUI.font()
	if _state == CHASE and p != null and is_instance_valid(p):
		var px := p.global_position.x
		var gap := px - _hx
		# ---- המד: עדר -> שחקן -> SAFE ----
		var w := 320.0
		var mx := (vs.x - w) * 0.5
		var my := 128.0
		var x0 := _trigger_x - 600.0
		var span := maxf(_safe_x - x0, 1.0)
		var hk := clampf((_hx - x0) / span, 0.0, 1.0)
		var pk := clampf((px - x0) / span, 0.0, 1.0)
		DrawBatch.rect(_ui, Rect2(mx - 4.0, my - 4.0, w + 8.0, 14.0), Color(0, 0, 0, 0.55))
		DrawBatch.rect(_ui, Rect2(mx, my, w, 6.0), Color(0.25, 0.25, 0.28, 0.9))
		DrawBatch.rect(_ui, Rect2(mx, my, w * hk, 6.0), Color(0.85, 0.12, 0.08, 0.95))
		DrawBatch.rect(_ui, Rect2(mx + w - 4.0, my - 10.0, 3.0, 22.0), Color(0.5, 1.0, 0.55))
		DrawBatch.colored_polygon(_ui, PackedVector2Array([Vector2(mx + w - 1.0, my - 10.0), Vector2(mx + w + 14.0, my - 5.0), Vector2(mx + w - 1.0, my)]), Color(0.5, 1.0, 0.55))
		var pc := Vector2(mx + w * pk, my + 3.0)
		DrawBatch.colored_polygon(_ui, PackedVector2Array([pc + Vector2(-6, -12), pc + Vector2(6, -12), pc + Vector2(0, -3)]), Color.WHITE)
		var danger := clampf(1.0 - (gap - 150.0) / 700.0, 0.0, 1.0)
		var lab := "THE HORDE  %dm" % maxi(int(gap / PX_PER_M), 0)
		var lc := Color(1.0, 0.85 - 0.6 * danger, 0.7 - 0.6 * danger)
		DrawBatch.string_outline(_ui, f, Vector2(mx, my + 30.0), lab, HORIZONTAL_ALIGNMENT_LEFT, w, 20, 5, Color(0, 0, 0, 0.85))
		DrawBatch.string(_ui, f, Vector2(mx, my + 30.0), lab, HORIZONTAL_ALIGNMENT_LEFT, w, 20, lc)
		var sl := "SAFE %dm" % maxi(int((_safe_x - px) / PX_PER_M), 0)
		DrawBatch.string_outline(_ui, f, Vector2(mx, my + 30.0), sl, HORIZONTAL_ALIGNMENT_RIGHT, w, 20, 5, Color(0, 0, 0, 0.85))
		DrawBatch.string(_ui, f, Vector2(mx, my + 30.0), sl, HORIZONTAL_ALIGNMENT_RIGHT, w, 20, Color(0.6, 1.0, 0.65))
		# ---- העדר מחוץ למסך: זוהר אדום בצד שמאל + חץ ----
		var v := _view()
		if _hx < v.position.x:
			var pulse := 0.6 + 0.4 * sin(_anim * lerpf(5.0, 14.0, danger))
			var ga := (0.12 + 0.4 * danger) * pulse
			var gw := 70.0 + 80.0 * danger
			var gp := PackedVector2Array([Vector2(0, 0), Vector2(gw, 0), Vector2(gw, vs.y), Vector2(0, 0), Vector2(gw, vs.y), Vector2(0, vs.y)])
			var gc := Color(0.9, 0.08, 0.05, ga)
			var gz := Color(0.9, 0.08, 0.05, 0.0)
			DrawBatch.tris(_ui, gp, PackedColorArray([gc, gz, gz, gc, gz, gc]))
			var ay := vs.y * 0.52
			var ac := Color(1.0, 0.3, 0.2, 0.6 + 0.4 * pulse)
			DrawBatch.colored_polygon(_ui, PackedVector2Array([Vector2(14, ay), Vector2(38, ay - 18), Vector2(38, ay + 18)]), ac)
			var dt := "%dm" % maxi(int(gap / PX_PER_M), 0)
			DrawBatch.string_outline(_ui, f, Vector2(44, ay + 10.0), dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, Color(0, 0, 0, 0.85))
			DrawBatch.string(_ui, f, Vector2(44, ay + 10.0), dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, ac)
	# ---- RUN! ----
	if _banner_t >= 0.0 and _banner_t < 2.6 and _safe_t < 0.0:
		var bt := _banner_t
		var a := clampf(bt / 0.12, 0.0, 1.0) * clampf((2.6 - bt) / 0.5, 0.0, 1.0)
		var sc := lerpf(1.8, 1.0, clampf(bt / 0.22, 0.0, 1.0))
		var jit := Vector2(sin(_anim * 53.0), cos(_anim * 47.0)) * 3.0 * clampf(1.4 - bt, 0.0, 1.0)
		_big_text(f, "RUN!", Vector2(vs.x * 0.5, vs.y * 0.42) + jit, sc, 96, Color(1.0, 0.25, 0.15, a), a)
		var sub := "THE HORDE IS COMING - DON'T STOP" if bt < 1.3 else "DOUBLE-TAP TO SPRINT"
		_big_text(f, sub, Vector2(vs.x * 0.5, vs.y * 0.42 + 48.0), 1.0, 26, Color(1.0, 0.9, 0.75, a), a)
	# ---- SAFE! ----
	if _safe_t >= 0.0 and _safe_t < 3.0:
		var st := _safe_t
		var a := clampf(st / 0.15, 0.0, 1.0) * clampf((3.0 - st) / 0.6, 0.0, 1.0)
		var sc := lerpf(1.5, 1.0, clampf(st / 0.25, 0.0, 1.0))
		var t1 := "THEY GAVE UP" if _timed_out else "SAFE!"
		_big_text(f, t1, Vector2(vs.x * 0.5, vs.y * 0.42), sc, 80, Color(0.5, 1.0, 0.55, a), a)
		_big_text(f, "THE HORDE FELL APART", Vector2(vs.x * 0.5, vs.y * 0.42 + 42.0), 1.0, 24, Color(0.9, 1.0, 0.9, a), a)


# טקסט ממורכז עם קו מתאר, גודל דרך הטרנספורם (לא מגדלים פונט)
func _big_text(f: Font, txt: String, c: Vector2, sc: float, fs: int, col: Color, a: float) -> void:
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	DrawBatch.set_transform(_ui, c, 0.0, Vector2(sc, sc))
	var pos := Vector2(-w * 0.5, fs * 0.35)
	DrawBatch.string_outline(_ui, f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(fs / 8, 4), Color(0, 0, 0, 0.9 * a))
	DrawBatch.string(_ui, f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	DrawBatch.set_transform(_ui, Vector2.ZERO)
