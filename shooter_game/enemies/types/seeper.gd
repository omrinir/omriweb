extends "res://enemies/zombie_type.gd"
# ============================================================
#  SEEPER (שלב 62, "THE HIVE MIND") - זומבי של רפש ירוק רעיל ושקוף: גוף נוזלי בצורת אדם, השלד של מי שהוא היה צף בפנים,
#    וגרעין זוהר (CORE) ששוחה בתוך החזה. טיפות נוזלות ממנו כל הזמן ומשאירות שלוליות.
#  מה הוא למד, וממה: אלפי מיתות של ירייה בגוף. הכוורת למדה ש"גוף אפשר לירות - שלולית אי אפשר". אז הוא מפסיק להיות גוף.
#    כל פגיעה שהייתה הורגת אותו (הנזק הצפוי, hit_damage() x MARGIN) -> הוא נמס (MELT) לשלולית במקום למות.
#    השלולית (PUDDLE): קליעים רק מתיזים ("SPLASH", חסום). היא זורמת אליך (FLOW_V) - דביקה מתחתיך (מאט) - ואז קמה שלמה
#    (REFORM, אנימציית עמוד שעולה): מי שעומד עליה כשהיא קמה חוטף SURGE. אחרי שקם - חוזר עם REFORM_HP מהחיים.
#  איך הורגים אותו באמת:
#    CORE - הגרעין בחזה (CORE_R, קרן מנקודת הפגיעה). פגיעה בו x CORE_MULT ויכולה להרוג ("CORE BURST"). כשהוא קם (REFORM)
#           הגרעין חשוף וגדול (x REFORM_CORE) - והחיים שלו עדיין נמוכים: ירייה אחת טובה. שאר הגוף בזמן הקימה x SOFT ולא הורג.
#    אש / פיצוץ - מאדים את הנוזל: בגוף x FIRE_MULT / BLAST_MULT והורגים, ובשלולית - מיד ("EVAPORATED").
#    MAX_REFORMS - אחרי כמה קימות הוא כבר לא מחזיק את עצמו ומת כמו כולם.
#  התקפה: ENGULF - קרוב (ENGULF_R): מתנפח קדימה (ENGULF_WIND) וזורק את עצמו עליך: נזק + נדבק (האטה).
#  לומד (main meta "sep_beaten" = כמה פעמים הרגת אותו בדרך הנכונה - גרעין / אש / פיצוץ):
#    >= LEARN_BEHIND: "IT RISES BEHIND YOU NOW" - השלולית זורמת מתחתיך וקמה BEHIND פיקסלים מאחוריך (ומיד מתנפל).
#    >= LEARN_SPLIT:  "IT SPLITS NOW" - כשהוא נמס הוא מתפצל לשתי שלוליות קטנות (mini) שקמות משני הצדדים שלך.
#  בוס (chase_range > 600): "THE FLOOD" - ענק עשוי מהרבה גופות (גולגולות צפות בפנים), גרעין ענק.
#    SLAM (B_SLAM_*) - קרוב: מרים את הזרועות וחובט. SPIT - יורק גושי רפש (acid.gd) ולפעמים משיר SEEPER קטן שזורם אליך.
#    GATES - ב-70% וב-40% חיים הוא נמס לגל (B_WAVE) ששוטף את כל הזירה (WAVE_V, גובה WAVE_H): לקפוץ מעליו או לעלות על
#      פטריית מדף. אחרי הגל הוא קם בצד השני (B_REFORM) עם גרעין חשוף x B_REFORM_CORE.
#    לומד בקרב: אחרי הגל הראשון - "IT RISES WHERE YOU STAND NOW" (GEYSER: טבעת מבעבעת מתחתיך ואז עמוד רפש);
#    מתחת לחצי חיים - "IT SPLITS NOW" (כל קימה משירה שני SEEPER קטנים).
#  שחקן בסצנה (story/scenes/l62_hive.gd, actor_props speaker): עומד בבריכת הזיכרון, הפה זז כשהכוורת מדברת,
#    scene_melt (stage_62 "melt") = נמס לתוך הבריכה.
#  לשנות: MARGIN_*, CORE_*, REFORM_*, FLOW_V, PUDDLE_T, MELT_T, MAX_REFORMS, ENGULF_*, LEARN_*, BEHIND, SPLIT_*;
#    בוס: B_*, GATES, WAVE_*, GEY_*, MINI_MAX, ARENA_W.
# ============================================================

const Decor := preload("res://effects/s62_decor.gd")
const AcidScript := preload("res://acid.gd")
const U := Decor.U

const SOUNDS := {
	"sep_melt": {"rev": 0.25, "layers": [["B", 1.4, 0.5, 0.0, 0.6, 0.0, 4.0, 0.55, 1.0, 0, 0, 90.0], ["N", 0, 0, 0.0, 0.5, 0.02, 5.0, 0.45, 0.3, 0, 0.1], ["S", 260, 70, 0.0, 0.5, 0.0, 5.0, 0.35, 1.0, 0.02]]},
	"sep_rise": {"rev": 0.3, "layers": [["B", 0.5, 1.6, 0.0, 0.9, 0.1, 2.0, 0.5, 1.0, 0, 0, 80.0], ["S", 70, 240, 0.0, 0.9, 0.2, 2.0, 0.4, 1.0, 0.03], ["N", 0, 0, 0.0, 0.9, 0.3, 2.0, 0.25, 0.25, 0]]},
	"sep_splash": [["N", 0, 0, 0.0, 0.18, 0.0, 16.0, 0.45, 0.5, 0, 0.1], ["B", 1.2, 1.2, 0.0, 0.2, 0.0, 9.0, 0.3, 1.0, 0, 0, 120.0]],
	"sep_core": {"drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.8, 0.6, 0, 0.2], ["S", 900, 120, 0.0, 0.3, 0.0, 10.0, 0.6, 1.0, 0], ["B", 1.0, 1.0, 0.0, 0.5, 0.0, 5.0, 0.4, 1.0, 0, 0, 100.0]]},
	"sep_evap": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 0.9, 0.0, 2.6, 0.6, 1.0, 0, 0.7], ["S", 1800, 2600, 0.0, 0.6, 0.0, 4.0, 0.12, 1.0, 0]]},
	"sep_engulf": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.35, 0.03, 7.0, 0.6, 0.3, 0, 0.1], ["B", 1.6, 0.8, 0.0, 0.4, 0.0, 6.0, 0.45, 1.0, 0, 0, 90.0], ["V", 120, 80, 0.0, 0.4, 0.02, 5.0, 0.4, 1.0, 0.05, 0, [380, 700, 18]]]},
	"sep_gurgle": {"rev": 0.3, "layers": [["B", 0.7, 0.9, 0.0, 1.0, 0.1, 2.5, 0.35, 1.0, 0, 0, 70.0], ["V", 80, 70, 0.0, 1.0, 0.1, 2.5, 0.3, 1.0, 0.06, 0, [300, 600, 14]]]},
	"fld_roar": {"rev": 0.5, "drive": 2.6, "layers": [["V", 58, 44, 0.0, 1.8, 0.1, 1.0, 1.0, 1.0, 0.08, 0, [300, 640, 24]], ["B", 0.6, 0.4, 0.0, 1.8, 0.1, 1.0, 0.5, 1.0, 0, 0, 60.0], ["N", 0, 0, 0.0, 1.6, 0.1, 1.4, 0.35, 0.15, 0]]},
	"fld_wave": {"rev": 0.4, "layers": [["N", 0, 0, 0.0, 2.2, 0.2, 0.9, 1.0, 0.25, 0, 0.15], ["B", 0.9, 0.5, 0.0, 2.0, 0.2, 1.0, 0.5, 1.0, 0, 0, 70.0], ["S", 55, 40, 0.0, 2.0, 0.2, 1.0, 0.6, 1.0, 0.04]]},
	"fld_slam": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 1.0, 0.3, 0, 0.1], ["S", 60, 30, 0.0, 0.5, 0.0, 6.0, 0.9, 1.0, 0], ["B", 1.0, 1.0, 0.0, 0.5, 0.0, 6.0, 0.5, 1.0, 0, 0, 100.0]]},
	"fld_spit": [["N", 0, 0, 0.0, 0.3, 0.02, 10.0, 0.6, 0.4, 0, 0.1], ["B", 1.4, 1.4, 0.0, 0.3, 0.0, 9.0, 0.4, 1.0, 0, 0, 90.0]],
	"fld_geyser": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 0.7, 0.0, 4.0, 0.8, 0.5, 0, 0.3], ["B", 1.8, 1.0, 0.0, 0.7, 0.0, 4.0, 0.5, 1.0, 0, 0, 110.0]]},
}

# ---- רגיל ----
const BODY := Vector2(24.0, 54.0)         # אזור פגיעה בהליכה (יחידות ציור)
const POOL := Vector2(62.0, 11.0)         # אזור פגיעה כשלולית
const MARGIN_HEAD := 2.2                  # (PERFECT בראש = x2) כמה ביטחון כשבודקים אם פגיעה תהרוג
const MARGIN_BODY := 1.3
const CORE_R := 4.6                       # רדיוס הגרעין בהליכה
const CORE_MULT := 1.8
const REFORM_CORE := 2.6
const REFORM_CORE_R := 7.5
const SOFT := 0.5                         # פגיעה בגוף כשהוא קם (לא הורגת)
const FIRE_MULT := 1.5
const BLAST_MULT := 1.4
const MELT_T := 0.45
const PUDDLE_T := Vector2(1.6, 2.2)
const FLOW_V := 210.0
const STICK := 0.35                       # האטה כשהשלולית מתחתיך
const REFORM_T := 1.15
const REFORM_HP := 0.65
const SURGE_DMG := 1
const MAX_REFORMS := 3
const ENGULF_R := 72.0
const ENGULF_WIND := 0.45
const ENGULF_V := 330.0
const ENGULF_T := 0.32
const ENGULF_DMG := 1
const ENGULF_SLOW := 0.8
const CD := Vector2(0.9, 1.6)
const WAKE_R := 900.0
const LURK_R := 230.0                     # שלולית שמחכה (lurk) קמה כשאתה כאן
const LEARN_BEHIND := 3
const LEARN_SPLIT := 5
const BEHIND := 120.0
const SPLIT_SCALE := 0.78
const SPLIT_HP := 0.55
# ---- בוס: THE FLOOD ----
const B_CORE_R := 7.0
const B_CORE_MULT := 2.0
const B_BODY_MULT := 0.8
const B_REFORM_CORE := 3.0
const B_SOFT := 0.6
const B_FIRE := 1.4
const B_BLAST := 1.3
const GATES := [0.7, 0.4]
const B_SLAM_R := 170.0
const B_SLAM_WIND := 0.6
const B_SLAM_DMG := 2
const B_SPIT_R := Vector2(240.0, 720.0)
const B_SPIT_WIND := 0.55
const B_CD := Vector2(0.8, 1.5)
const WAVE_V := 430.0
const WAVE_H := 72.0
const WAVE_DMG := 2
const WAVE_MELT_T := 0.9
const B_POOL_T := 0.5
const B_REFORM_T := 1.7
const GEY_WARN := 0.95
const GEY_T := 0.45
const GEY_R := 46.0
const GEY_CD := Vector2(5.0, 7.0)
const MINI_MAX := 3
const ARENA_W := 1180.0

enum {WALK, ENGULF_W, ENGULF, MELT, PUDDLE, REFORM, B_WALK, B_SLAM_W, B_SLAM, B_SPIT_W, B_MELT, B_WAVE, B_POOL, B_REFORM}
var state := WALK
# לבדיקות
var melts := 0
var reforms := 0
var splashes := 0
var core_hits := 0
var core_kills := 0
var evaporated := 0
var engulfs := 0
var engulf_hits := 0
var surges := 0
var behinds := 0
var splits := 0
var waves := 0
var wave_hits := 0
var slams := 0
var slam_hits := 0
var spits := 0
var geysers := 0
var geyser_hits := 0
var shed := 0

# שחקן בסצנה
var t := 0.0
var talking := false
var tilt := 0.0
var smile := 0.0
var look_back := 0.0
var speaker := false
var scene_melt := 0.0

var mini := false
var lurk := false
var learn_behind := false
var learn_split := false
var _st := 0.0
var _cd := 1.0
var _hit := false
var _pop_t := 0.0
var _jump_cd := 0.0
var _flow_x := 0.0
var _behind := false
var _mult := 1.0
var _core := false
var _core_kill := false
var _evap := false
var _seed := 0.0
var _dpos := Vector2.ZERO
var _wander_t := 0.0
var _gurgle_t := 2.0
var _drip_t := 0.0
# בוס
var _gate := 0
var _b_cd := 2.0
var _spit_n := 0
var _engaged := false
var _wave_dir := 1.0
var _wave_x0 := 0.0
var _wave_tx := 0.0
var _gey_learn := false
var _split_learn := false
var _gey_cd := 3.0
var _gey_t := -1.0                       # >0 = טבעת מבעבעת, <=0 ו-> -GEY_T = העמוד
var _gey_x := 0.0
var _gey_hit := false
var _spawned: Array = []


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "SEEPER", "hp": 480, "walk": 46.0, "chase": 80.0, "damage": 2, "bite_delay": 1.0, "scale": 2.3, "width": 1.15,
			"duck": 0.0, "cover": 0.0, "skin": Color("5ae83a"), "shirt": Color("2a8a1e"), "pants": Color("1a5a12"), "shoe": Color("124a0c"),
			"points": 3000, "boss": true, "boss_name": "THE FLOOD", "ragdoll": false}
	return {"name": "SEEPER", "hp": 58, "walk": 48.0, "chase": 92.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.05,
		"duck": 0.0, "cover": 0.0, "skin": Color("62f03e"), "shirt": Color("2a8a1e"), "pants": Color("1a5a12"), "shoe": Color("124a0c"),
		"points": 380, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func death_sound() -> String:
	return "sep_core"


func _main() -> Node:
	return z.get_parent()


func _scene_actor() -> bool:
	return not z.is_in_group("zombies")


func setup() -> void:
	_seed = float(z.get_instance_id() % 997) * 0.61
	_gurgle_t = randf_range(1.0, 4.0)
	if _boss():
		state = B_WALK
		_resize(BODY * Vector2(1.3, 1.08))
		z.set_meta("no_cover", true)
		return
	state = WALK
	_resize(BODY)
	_learn_check()


func _learn_check() -> void:
	var m := _main()
	var n: int = int(m.get_meta("sep_beaten", 0)) if m != null else 0
	learn_behind = n >= LEARN_BEHIND
	learn_split = n >= LEARN_SPLIT


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


# SEEPER קטן (התפצל / הבוס השיר אותו)
func make_mini() -> void:
	mini = true
	z.sc *= SPLIT_SCALE
	z.max_hp = maxi(8, int(float(z.max_hp) * SPLIT_HP))
	z.hp = mini_hp()
	_resize(BODY)


func mini_hp() -> int:
	return maxi(4, int(float(z.max_hp) * REFORM_HP))


# מתחיל כשלולית: lurk = מחכה על הרצפה עד שאתה קרוב. flow_to = לאן לזרום (INF = אליך)
func start_puddle(wait := false, flow_to := INF) -> void:
	state = PUDDLE
	lurk = wait
	_st = randf_range(PUDDLE_T.x, PUDDLE_T.y)
	_flow_x = flow_to if flow_to < INF else z.global_position.x
	_behind = flow_to < INF
	_resize(POOL)


# הגרעין בעולם (שוחה בתוך החזה)
func core_pos() -> Vector2:
	var lp := Vector2(1.0 + sin(z._time * 1.3 + _seed) * 3.0, -33.0 + cos(z._time * 0.9 + _seed) * 4.0)
	if state == REFORM:
		var k := clampf(1.0 - _st / REFORM_T, 0.0, 1.0)
		lp = Vector2(0.0, lerpf(-4.0, -30.0, k))
	elif _boss() and state == B_REFORM:
		var k2 := clampf(1.0 - _st / B_REFORM_T, 0.0, 1.0)
		lp = Vector2(0.0, lerpf(-4.0, -32.0, k2))
	return z.global_position + Vector2(lp.x * z._dir * z.wf, lp.y) * z.sc


func is_liquid() -> bool:
	return state in [MELT, PUDDLE, B_MELT, B_WAVE, B_POOL]


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	t += delta
	_st -= delta
	_cd -= delta
	_pop_t -= delta
	_jump_cd -= delta
	_drip_t -= delta
	if _scene_actor():   # שחקן בסצנה: עומד בבריכה
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.velocity.x = 0.0
		z.move_and_slide()
		return true
	if z.dead:
		return false
	if Engine.get_physics_frames() % 30 == 0 and not _boss():   # לומד גם באמצע השלב
		_learn_check()
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	_gurgle_t -= delta
	if _gurgle_t <= 0.0:
		_gurgle_t = randf_range(3.5, 7.0)
		if Art.on_screen(z, z.global_position):
			Sfx.play("sep_gurgle", z.global_position, -6.0 if not _boss() else 0.0, 0.15, 2, 0.6 if _boss() else 1.0)
	if _boss():
		_boss_physics(pl, has, d, delta)
		z.move_and_slide()
		return true
	match state:
		WALK:
			_walk(pl, has, d, delta)
		ENGULF_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has and absf(d.x) > 6.0 and _st > ENGULF_WIND * 0.4:
				z._dir = signf(d.x)
			if _st <= 0.0:
				state = ENGULF
				_st = ENGULF_T
				_hit = false
				engulfs += 1
				z.velocity.x = z._dir * ENGULF_V
				z.velocity.y = -160.0
				Sfx.play("sep_engulf", z.global_position, 0.0, 0.1, 3)
		ENGULF:
			if has and not _hit:
				var x0: float = z.global_position.x - z._dir * 6.0
				var x1: float = z.global_position.x + z._dir * 30.0 * z.sc
				var r := Rect2(minf(x0, x1), z.global_position.y - 50.0 * z.sc, absf(x1 - x0), 50.0 * z.sc)
				if r.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						engulf_hits += 1
						pl.slow_t = maxf(float(pl.slow_t), ENGULF_SLOW)
						z._popup("ENGULFED", Decor.TOX, 13, -70.0)
						Decor.GooSplash.spawn(_main(), pl.global_position + Vector2(0, -30), Vector2(z._dir, -0.6), 6, z.global_position.y)
					pl.hurt(ENGULF_DMG, Vector2(z._dir * 0.6, -0.2))
			if _st <= 0.0 and z.is_on_floor():
				state = WALK
				_cd = randf_range(CD.x, CD.y)
			z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
		MELT:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			var k := clampf(1.0 - _st / MELT_T, 0.0, 1.0)
			_resize(Vector2(lerpf(BODY.x, POOL.x, k), lerpf(BODY.y, POOL.y, k)))
			if _st <= 0.0:
				state = PUDDLE
				_st = randf_range(PUDDLE_T.x, PUDDLE_T.y)
				_resize(POOL)
		PUDDLE:
			_puddle(pl, has, d, delta)
		REFORM:
			z.velocity.x = 0.0
			var k2 := clampf(1.0 - _st / REFORM_T, 0.0, 1.0)
			_resize(Vector2(lerpf(POOL.x, BODY.x, k2), lerpf(POOL.y, BODY.y, k2)))
			if _st <= 0.0:
				_reformed(pl, has, d)
	z.move_and_slide()
	return true


func _drum() -> float:
	return 1.3 if z.has_meta("drum_t") and float(z.get_meta("drum_t")) > float(z._time) else 1.0


func _walk(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	var awake: bool = has and absf(d.y) < 420.0 and (absf(d.x) < WAKE_R or z._alert_t > 0.0)
	if not awake:   # משוטט לאט
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(1.5, 3.5)
			z._dir = -1.0 if randf() < 0.5 else 1.0
		z.velocity.x = move_toward(z.velocity.x, z._dir * z.walk_speed * 0.45, 300.0 * delta)
	else:
		if absf(d.x) > 6.0:
			z._dir = signf(d.x)
		var spd: float = z.chase_speed * z.speed_mult * _drum()
		var mv: float = z._dir * spd if absf(d.x) > ENGULF_R * 0.5 else 0.0
		z.velocity.x = move_toward(z.velocity.x, mv, 600.0 * delta)
		if z.is_on_floor() and _jump_cd <= 0.0 and d.y < -80.0 and absf(d.x) < 230.0:   # עולה אליך על פטריית מדף
			z.velocity.y = -640.0
			_jump_cd = 1.6
		if _cd <= 0.0 and z.is_on_floor() and absf(d.x) < ENGULF_R * z.sc and absf(d.y) < 50.0:
			state = ENGULF_W
			_st = ENGULF_WIND
			z.velocity.x = 0.0
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0 and _jump_cd <= 0.0:
		z.velocity.y = -520.0
		_jump_cd = 0.8
	z._walk_phase += delta * absf(z.velocity.x) / 7.5
	if _drip_t <= 0.0 and Art.on_screen(z, z.global_position, 40.0):
		_drip_t = randf_range(0.6, 1.4)
		Particles.burst(_main(), z.global_position + Vector2(randf_range(-8.0, 8.0), -randf_range(10.0, 40.0)) * Vector2(1.0, z.sc), "drop", Vector2.DOWN, 1)


# שלולית: זורמת אליך (או מתחתיך ואל מאחוריך), דביקה, ואז קמה
func _puddle(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	if lurk:   # מחכה על הרצפה
		_st = maxf(_st, 0.6)
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		if has and absf(d.x) < LURK_R and absf(d.y) < 90.0:
			lurk = false
			_st = 0.55
			_flow_x = pl.global_position.x
			z._popup("!!", Decor.TOX, 16, -30.0)
			Sfx.play("sep_gurgle", z.global_position, 2.0, 0.1, 2)
		return
	if has and not _behind:   # עוקבת אחריך (ומאחוריך אם למד)
		if learn_behind:
			var side: float = signf(d.x) if absf(d.x) > 4.0 else float(z._dir)
			_flow_x = pl.global_position.x + side * BEHIND
		else:
			_flow_x = pl.global_position.x
	_flow_x = clampf(_flow_x, 40.0, z.world_w - 40.0)
	var dx: float = _flow_x - z.global_position.x
	if absf(dx) > 6.0:
		z._dir = signf(dx)
		z.velocity.x = move_toward(z.velocity.x, signf(dx) * FLOW_V * _drum(), 900.0 * delta)
	else:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if z.is_on_wall():
		_st = minf(_st, 0.1)
	# דביק: עומד עליה = איטי
	if has and absf(d.x) < POOL.x * 0.5 * z.sc and absf(d.y) < 24.0:
		pl.slow_t = maxf(float(pl.slow_t), STICK)
	z._walk_phase += delta * 6.0
	if _st <= 0.0:
		_start_reform(pl, has, d)


func _start_reform(pl: Node, has: bool, d: Vector2) -> void:
	state = REFORM
	_st = REFORM_T
	z.velocity.x = 0.0
	_behind = false
	if has:
		var side_now := signf(d.x)
		if absf(d.x) > 4.0:
			z._dir = side_now
		# קם מאחוריך (למד): פונה אליך מהגב שלך
		var aimx: float = float(pl._aim.x)
		if learn_behind and absf(d.x) < BEHIND * 1.6 and signf(aimx) == -side_now:
			behinds += 1
			var m := _main()
			if m != null and not m.has_meta("sep_behind_said"):
				m.set_meta("sep_behind_said", true)
				z._popup("IT RISES BEHIND YOU NOW", Color("b8ff7a"), 13, -80.0)
		# עומד עליה כשהיא קמה = SURGE
		if absf(d.x) < 30.0 * z.sc and absf(d.y) < 30.0:
			surges += 1
			pl.hurt(SURGE_DMG, Vector2(signf(d.x + 0.01) * 0.8, -1.0))
			z._popup("SURGE", Decor.TOX, 13, -40.0)
	Sfx.play("sep_rise", z.global_position, 0.0, 0.1, 3)
	Decor.GooSplash.spawn(_main(), z.global_position + Vector2(0, -6), Vector2.UP, 5, z.global_position.y)


func _reformed(_pl: Node, has: bool, d: Vector2) -> void:
	reforms += 1
	state = WALK
	_resize(BODY)
	z.hp = maxi(z.hp, mini_hp() if mini else int(ceil(float(z.max_hp) * REFORM_HP)))
	_cd = 0.25 if learn_behind else 0.7
	if has and absf(d.x) > 6.0:
		z._dir = signf(d.x)
	if reforms >= MAX_REFORMS:
		z._popup("IT CAN'T HOLD", Color("d8ffb0"), 11, -70.0)


# הפגיעה הזאת הייתה הורגת -> נמס
func _melt(dir: Vector2) -> void:
	melts += 1
	state = MELT
	_st = MELT_T
	z._flash = 0.06
	z.velocity.x = 0.0
	_behind = false
	var m := _main()
	if m != null:
		m.set_meta("sep_melts", int(m.get_meta("sep_melts", 0)) + 1)
	if _pop_t <= 0.0:
		_pop_t = 0.8
		z._popup("MELTS", Decor.TOX, 14, -60.0)
	Sfx.play("sep_melt", z.global_position, 0.0, 0.1, 3)
	Decor.GooSplash.spawn(m, z.global_position + Vector2(0, -30.0 * z.sc), Vector2(dir.x, -0.5), 8, z.global_position.y)
	if learn_split and not mini:
		_split()


# (למד) מתפצל: הוא נהיה קטן, ושלולית קטנה שנייה זורמת לצד השני שלך
func _split() -> void:
	var m := _main()
	if m == null or not m.has_method("_spawn_zombie"):
		return
	splits += 1
	make_mini()
	z.hp = 1
	var pl := player() as Node2D
	var px: float = pl.global_position.x if pl != null else z.global_position.x
	var side := signf(px - z.global_position.x)
	if side == 0.0:
		side = 1.0
	var w = m._spawn_zombie(z.global_position.x, z.global_position.y, z.kind)
	if w == null or w.type_mod == null:
		return
	w.dormant = false
	w.type_mod.make_mini()
	w.type_mod.start_puddle(false, clampf(px + side * BEHIND * 0.9, 60.0, z.world_w - 60.0))
	_flow_x = px - side * BEHIND * 0.6
	_behind = true
	if not m.has_meta("sep_split_said"):
		m.set_meta("sep_split_said", true)
		z._popup("IT SPLITS NOW", Color("b8ff7a"), 13, -80.0)


# ============================================================
#  נזק: גרעין / שלולית / קימה
# ============================================================
func _core_hit(hit_pos: Vector2, dir: Vector2, r: float) -> bool:
	var rel := core_pos() - hit_pos
	if dir == Vector2.ZERO:
		return rel.length() < r * 2.2
	var along := rel.dot(dir)
	if along < -r:
		return false
	return absf(rel.cross(dir)) < r


func _is_fire(s: String, src: Dictionary) -> bool:
	return s == "fire" or bool(src.get("incendiary", false))


func _is_blast(s: String) -> bool:
	return not (s == "bullet" or s == "melee" or s == "laser" or s == "taser" or s == "fire" or s == "hazard")


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	if _scene_actor():
		return false
	var s := str(src.get("source", "bullet"))
	_mult = 1.0
	_core = false
	if _boss():
		return _boss_damage(amount, hit_pos, dir, src, s)
	if s == "hazard":   # מלכודת (MAW): אוכל אותו כמו כל אחד
		return true
	match state:
		MELT, PUDDLE:
			if _is_fire(s, src) or _is_blast(s):   # אש / פיצוץ מאדים את השלולית
				_evap = true
				_mult = 99.0
				return true
			_splash(hit_pos, dir)
			return false
		REFORM:
			if _is_fire(s, src) or _is_blast(s):
				_evap = true
				_mult = FIRE_MULT
				return true
			if _core_hit(hit_pos, dir, REFORM_CORE_R * z.sc):
				_core = true
				_mult = REFORM_CORE
				core_hits += 1
				return true
			_mult = SOFT
			if _would_kill(amount, hit_pos, src, SOFT):   # הגוף עוד לא מחזיק - אבל גם לא מת מזה
				_splash(hit_pos, dir)
				return false
			return true
	# גוף שלם
	if _is_fire(s, src):
		_mult = FIRE_MULT
		_evap = true
		return true
	if _is_blast(s):
		_mult = BLAST_MULT
		_evap = true
		return true
	if (s == "bullet" or s == "melee" or s == "laser") and _core_hit(hit_pos, dir, CORE_R * z.sc):
		_core = true
		_mult = CORE_MULT
		core_hits += 1
		return true
	if reforms >= MAX_REFORMS:   # כבר לא מחזיק את עצמו
		return true
	if _would_kill(amount, hit_pos, src, 1.0):
		_melt(dir)
		return false
	return true


func _would_kill(amount: int, hit_pos: Vector2, src: Dictionary, mult: float) -> bool:
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	var pred := float(hit_damage(amount, hit_pos, src)) * mult * (MARGIN_HEAD if ly < -42.0 else MARGIN_BODY)
	return float(z.hp) - pred <= 0.0


func _splash(hit_pos: Vector2, dir: Vector2) -> void:
	splashes += 1
	Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
	if Art.on_screen(z, hit_pos):
		Sfx.play("sep_splash", hit_pos, -3.0, 0.2, 3)
		Decor.GooSplash.spawn(_main(), hit_pos, Vector2(-dir.x, -0.7), 3, z.global_position.y)
	if _pop_t <= 0.0:
		_pop_t = 0.7
		z._popup("SPLASH", Color("c8ff9a"), 12, -26.0 if is_liquid() else -70.0)
	var m := _main()
	if m != null and int(m.get_meta("sep_splashes", 0)) < 99:
		m.set_meta("sep_splashes", int(m.get_meta("sep_splashes", 0)) + 1)
		if int(m.get_meta("sep_splashes", 0)) == 6:
			var pl := player()
			if pl != null and pl.has_method("_say"):
				pl._say("Bullets just splash. Wait for it to RISE - then the core!", Color("c8ff9a"))


func damage_mult(_zone: String, _src: Dictionary) -> float:
	var m := _mult
	_mult = 1.0
	return m


func on_death() -> void:
	_dpos = z.global_position
	var m := _main()
	var how := "EVAPORATED" if _evap else ("CORE BURST" if _core else "")
	if _core or _evap:
		if _core:
			core_kills += 1
		else:
			evaporated += 1
		if m != null and not _scene_actor():
			m.set_meta("sep_beaten", int(m.get_meta("sep_beaten", 0)) + 1)
	if _boss():
		_boss_death()
		return
	if how != "":
		z._popup(how, Color("e0ffb0") if _core else Color("ffd080"), 14, -60.0 if not is_liquid() else -30.0)
	if Art.on_screen(z, z.global_position):
		var c: Vector2 = z.global_position + Vector2(0, (-30.0 if not is_liquid() else -6.0) * z.sc)
		Decor.GooSplash.spawn(m, c, Vector2.UP, 10, z.global_position.y)
		if _evap:
			Sfx.play("sep_evap", c, 0.0, 0.1, 2)
			Particles.burst(m, c, "smoke", Vector2.UP, 6)
			Particles.burst(m, c, "mist", Vector2.UP, 5)
		else:
			Particles.burst(m, c, "spark", Vector2.UP, 5)


# ============================================================
#  בוס: THE FLOOD
# ============================================================
func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_b_cd -= delta
	_gey_cd -= delta
	var met: bool = has and (_engaged or absf(d.x) < z.chase_range or z._alert_t > 0.0)
	if met and not _engaged:
		_engaged = true
		Sfx.play("fld_roar", z.global_position, 3.0, 0.0, 1)
	# ההיתך: מתחת לשער -> נמס לגל
	if _gate < GATES.size() and float(z.hp) < float(z.max_hp) * float(GATES[_gate]) and state in [B_WALK, B_SLAM_W, B_SPIT_W]:
		_gate += 1
		state = B_MELT
		_st = WAVE_MELT_T
		_gey_t = -1.0
		Sfx.play("fld_roar", z.global_position, 4.0, 0.0, 1, 0.8)
		Sfx.play("sep_melt", z.global_position, 4.0, 0.0, 1, 0.6)
		z._popup("THE FLOOD BREAKS", Decor.TOX, 18, -150.0)
	if not _split_learn and float(z.hp) < float(z.max_hp) * 0.5:
		_split_learn = true
		z._popup("IT SPLITS NOW", Color("b8ff7a"), 15, -170.0)
	_geyser_tick(pl, has, delta)
	match state:
		B_WALK:
			if not met:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 400.0 * delta)
			else:
				if absf(d.x) > 10.0:
					z._dir = signf(d.x)
				var mv: float = z._dir * z.chase_speed * z.speed_mult if absf(d.x) > B_SLAM_R * 0.6 else 0.0
				z.velocity.x = move_toward(z.velocity.x, mv, 500.0 * delta)
				z._walk_phase += delta * absf(z.velocity.x) / 16.0
				if _b_cd <= 0.0 and z.is_on_floor():
					if absf(d.x) < B_SLAM_R and absf(d.y) < 140.0:
						state = B_SLAM_W
						_st = B_SLAM_WIND
						Sfx.play("fld_roar", z.global_position, 0.0, 0.1, 1, 1.2)
					elif absf(d.x) > B_SPIT_R.x and absf(d.x) < B_SPIT_R.y:
						state = B_SPIT_W
						_st = B_SPIT_WIND
				if _gey_learn and _gey_cd <= 0.0 and _gey_t <= -GEY_T and absf(d.x) > 90.0 and d.y > -200.0 and pl.is_on_floor():
					_gey_cd = randf_range(GEY_CD.x, GEY_CD.y)
					_gey_t = GEY_WARN
					_gey_hit = false
					_gey_x = pl.global_position.x
					geysers += 1
					Sfx.play("sep_gurgle", Vector2(_gey_x, z.global_position.y), 4.0, 0.1, 2)
		B_SLAM_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = B_SLAM
				_st = 0.35
				slams += 1
				_hit = false
				Sfx.play("fld_slam", z.global_position, 3.0, 0.05, 2)
				_shake(9.0, 0.3)
				var fx: Vector2 = z.global_position + Vector2(z._dir * 90.0, -8.0)
				Decor.GooSplash.spawn(_main(), fx, Vector2(z._dir, -1.0), 10, z.global_position.y)
				if has:
					var x0: float = z.global_position.x
					var x1: float = z.global_position.x + z._dir * B_SLAM_R
					var r := Rect2(minf(x0, x1), z.global_position.y - 130.0, absf(x1 - x0), 130.0)
					if r.intersects(pl.body_rect()):
						if pl._roll_t <= 0.0:
							slam_hits += 1
						pl.hurt(B_SLAM_DMG, Vector2(z._dir * 1.6, -0.8))
		B_SLAM:
			if _st <= 0.0:
				state = B_WALK
				_b_cd = randf_range(B_CD.x, B_CD.y)
		B_SPIT_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				_spit(pl, has)
				state = B_WALK
				_b_cd = randf_range(B_CD.x, B_CD.y) + 0.4
		B_MELT:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			var k := clampf(1.0 - _st / WAVE_MELT_T, 0.0, 1.0)
			_resize(Vector2(lerpf(BODY.x * 1.3, 70.0, k), lerpf(BODY.y * 1.08, 14.0, k)))
			if _st <= 0.0:
				_start_wave(pl, has)
		B_WAVE:
			z.velocity.x = _wave_dir * WAVE_V
			if has and not _hit:
				var fx2: float = z.global_position.x
				var r2 := Rect2(minf(fx2, fx2 - _wave_dir * 110.0), z.global_position.y - WAVE_H, 110.0, WAVE_H)
				if r2.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						wave_hits += 1
						pl.slow_t = maxf(float(pl.slow_t), 0.8)
					pl.hurt(WAVE_DMG, Vector2(_wave_dir * 1.8, -0.9))
			var done: bool = (_wave_dir > 0.0 and z.global_position.x >= _wave_tx) or (_wave_dir < 0.0 and z.global_position.x <= _wave_tx) or z.is_on_wall()
			if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(0, -WAVE_H * 0.8), "drop", Vector2(_wave_dir, -1.0), 2)
			if done:
				state = B_POOL
				_st = B_POOL_T
				z.velocity.x = 0.0
		B_POOL:
			z.velocity.x = 0.0
			if _st <= 0.0:
				state = B_REFORM
				_st = B_REFORM_T
				if has and absf(d.x) > 10.0:
					z._dir = signf(d.x)
				Sfx.play("sep_rise", z.global_position, 4.0, 0.0, 1, 0.6)
				if _split_learn:
					_shed(2)
		B_REFORM:
			z.velocity.x = 0.0
			var k2 := clampf(1.0 - _st / B_REFORM_T, 0.0, 1.0)
			_resize(Vector2(lerpf(70.0, BODY.x * 1.3, k2), lerpf(14.0, BODY.y * 1.08, k2)))
			if _st <= 0.0:
				state = B_WALK
				_b_cd = 0.6
				_resize(BODY * Vector2(1.3, 1.08))
				if not _gey_learn:
					_gey_learn = true
					_gey_cd = 1.5
					z._popup("IT RISES WHERE YOU STAND NOW", Color("b8ff7a"), 15, -170.0)
	_keep_arena()


func _start_wave(pl: Node, has: bool) -> void:
	state = B_WAVE
	waves += 1
	_hit = false
	var px: float = pl.global_position.x if has else z.global_position.x - 300.0
	_wave_dir = signf(px - z.global_position.x)
	if _wave_dir == 0.0:
		_wave_dir = -z._dir
	z._dir = _wave_dir
	_wave_x0 = z.global_position.x
	var lo: float = z.world_w - ARENA_W + 60.0
	var hi: float = z.world_w - 90.0
	_wave_tx = lo if _wave_dir < 0.0 else hi
	_resize(Vector2(70.0, 14.0))
	Sfx.play("fld_wave", z.global_position, 4.0, 0.0, 1)
	_shake(7.0, 0.8)
	if pl != null and pl.has_method("_say") and waves == 1:
		pl._say("It's coming as a WAVE - jump it or get up high!", Color("c8ff9a"))


func _geyser_tick(pl: Node, has: bool, delta: float) -> void:
	if _gey_t <= -GEY_T:
		return
	var was := _gey_t
	_gey_t -= delta
	if was > 0.0 and _gey_t <= 0.0:   # העמוד פורץ
		Sfx.play("fld_geyser", Vector2(_gey_x, z.global_position.y), 3.0, 0.1, 2)
		Decor.GooSplash.spawn(_main(), Vector2(_gey_x, z.global_position.y - 20.0), Vector2.UP, 10, z.global_position.y)
	if _gey_t <= 0.0 and not _gey_hit and has:
		var p: Vector2 = pl.global_position
		if absf(p.x - _gey_x) < GEY_R and p.y > z.global_position.y - 220.0:
			_gey_hit = true
			if pl._roll_t <= 0.0:
				geyser_hits += 1
			pl.hurt(1, Vector2(signf(p.x - _gey_x + 0.01) * 0.5, -1.4))


func _spit(pl: Node, has: bool) -> void:
	spits += 1
	_spit_n += 1
	var from: Vector2 = z.global_position + Vector2(z._dir * 18.0, -112.0)
	var to: Vector2 = pl.global_position if has else from + Vector2(z._dir * 400.0, 120.0)
	Sfx.play("fld_spit", from, 3.0, 0.1, 2)
	for i in 3:
		var a = AcidScript.new()
		_main().add_child(a)
		var dx: float = (to.x - from.x) * (0.75 + 0.2 * float(i))
		var tt := 0.85 + 0.1 * float(i)
		a.setup(from, Vector2(dx / tt, (to.y - from.y - 0.5 * 900.0 * tt * tt) / tt))
	if _spit_n % 2 == 0:
		_shed(1)


# משיר SEEPER קטן שזורם אליך כשלולית
func _shed(n: int) -> void:
	var m := _main()
	if m == null or not m.has_method("_spawn_zombie"):
		return
	for i in n:
		if _alive_spawned() >= MINI_MAX:
			return
		var w = m._spawn_zombie(z.global_position.x + z._dir * 40.0 * (1.0 if i == 0 else -1.0), z.global_position.y, z.kind)
		if w == null or w.type_mod == null:
			continue
		w.dormant = false
		w.type_mod.make_mini()
		w.type_mod.start_puddle()
		_spawned.append(w)
		shed += 1
	Decor.GooSplash.spawn(m, z.global_position + Vector2(0, -40.0), Vector2.UP, 8, z.global_position.y)


func _alive_spawned() -> int:
	var n := 0
	for w in _spawned:
		if is_instance_valid(w) and not w.dead:
			n += 1
	return n


func _keep_arena() -> void:
	var bx: float = z.global_position.x
	if bx < z.world_w - ARENA_W and z.velocity.x < 0.0:
		z.velocity.x = 0.0
	if bx > z.world_w - 70.0 and z.velocity.x > 0.0:
		z.velocity.x = 0.0


func _shake(a: float, tt: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(a, tt)


func _boss_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary, s: String) -> bool:
	if s == "hazard":
		return false
	if state in [B_MELT, B_WAVE, B_POOL]:   # גל של נוזל: הכל מתיז
		if s != "fire":
			_splash(hit_pos, dir)
		return false
	var reform := state == B_REFORM
	if _is_fire(s, src):
		_mult = B_FIRE
		return true
	if _is_blast(s):
		_mult = B_BLAST
		return true
	if _core_hit(hit_pos, dir, (REFORM_CORE_R * 1.3 if reform else B_CORE_R) * z.sc):
		_core = true
		core_hits += 1
		_mult = B_REFORM_CORE if reform else B_CORE_MULT
		if _pop_t <= 0.0:
			_pop_t = 0.5
			z._popup("CORE", Color("e8ffb0"), 13, -150.0)
		return true
	_mult = B_SOFT if reform else B_BODY_MULT
	if reform and _would_kill(amount, hit_pos, src, _mult):
		_splash(hit_pos, dir)
		return false
	return true


func _boss_death() -> void:
	for w in _spawned:
		if is_instance_valid(w) and not w.dead:
			w.take_damage(999, w.global_position + Vector2(0, -10), Vector2.UP, true, {"source": "fire", "fixed": 999})
	_shake(16.0, 0.9)
	Sfx.play("fld_roar", z.global_position, 4.0, 0.0, 1, 0.6)
	Sfx.play("sep_evap", z.global_position, 4.0, 0.0, 1, 0.7)
	var m := _main()
	z._popup("THE FLOOD DRAINS", Color("e0ffb0"), 20, -170.0)
	for i in 4:
		Decor.GooSplash.spawn(m, z.global_position + Vector2(randf_range(-60.0, 60.0), -randf_range(40.0, 120.0)), Vector2(randf_range(-1.0, 1.0), -1.0), 10, z.global_position.y)
	Particles.burst(m, z.global_position + Vector2(0, -80), "mist", Vector2.UP, 14)
	Particles.burst(m, z.global_position + Vector2(0, -80), "spark", Vector2.UP, 12)


# ============================================================
#  ציור: גוף נוזלי שקוף בצורת אדם (ירוק רעיל), שלד כהה בפנים, גרעין זוהר ששוחה בחזה, טיפות.
#  נמס = הגוף נמעך לרוחב לתוך שלולית. שלולית = נוזל זורם עם בליטה קדמית, אדוות, בועות ושתי עיניים צפות.
#  קם = עמוד שעולה מהשלולית עם חוטי רפש, והגרעין עולה איתו - גדול וחשוף. הכל ב-draw call אחד (Decor.U + flush).
# ============================================================
func wants_redraw() -> bool:
	return true


func _c(c: Color) -> Color:   # לבן כשנפגע (שומר על השקיפות)
	return Color(1.0, 1.0, 1.0, c.a) if z._flash > 0.0 else c


func draw() -> bool:
	if z.dead:
		_draw_dead()
		return true
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var tt: float = z._time
	if _boss() and state == B_WAVE:
		DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
		_draw_wave(pts, cols, tt)
		U.flush(z, pts, cols)
		_draw_geyser()
		return true
	begin_draw(not is_liquid() and state != REFORM and state != B_REFORM)
	var melt := 0.0
	var rise := 1.0
	var pool := 0.0
	match state:
		MELT:
			melt = clampf(1.0 - _st / MELT_T, 0.0, 1.0)
			pool = melt
		PUDDLE:
			pool = 1.0
			rise = 0.0
		REFORM:
			rise = clampf(1.0 - _st / REFORM_T, 0.0, 1.0)
			pool = 1.0 - rise
		B_MELT:
			melt = clampf(1.0 - _st / WAVE_MELT_T, 0.0, 1.0)
			pool = melt
		B_POOL:
			pool = 1.0
			rise = 0.0
		B_REFORM:
			rise = clampf(1.0 - _st / B_REFORM_T, 0.0, 1.0)
			pool = 1.0 - rise
	if _scene_actor() and scene_melt > 0.0:
		melt = scene_melt
		pool = scene_melt
	# השלולית (מתחת)
	if pool > 0.0:
		_draw_pool(pts, cols, pool, tt)
	# הגוף: נמעך (נמס) / עולה (קם)
	if rise > 0.0 and melt < 1.0:
		var pb := PackedVector2Array()
		var cb := PackedColorArray()
		_draw_body(pb, cb, tt, rise < 1.0)
		var sy := 1.0
		var sx := 1.0
		if melt > 0.0:
			sy = 1.0 - melt * 0.9
			sx = 1.0 + melt * 0.7
		elif rise < 1.0:
			var e := rise * rise * (3.0 - 2.0 * rise)
			sy = maxf(0.05, e + sin(rise * PI) * 0.1)
			sx = 1.0 + (1.0 - rise) * 0.6 - sin(rise * PI * 2.0) * 0.06
			_strands(pts, cols, sy, tt)
		pts.append_array(Transform2D(0.0, Vector2(sx, sy), 0.0, Vector2.ZERO) * pb)
		cols.append_array(cb)
		_draw_core(pts, cols, tt, rise < 1.0, sy if melt > 0.0 else 1.0)
	U.flush(z, pts, cols)
	end_draw()
	if _boss():
		_draw_geyser()
	return true


# הגוף העומד (0,0 = כפות הרגליים, פונה ימינה, גובה ~56)
func _draw_body(pts: PackedVector2Array, cols: PackedColorArray, tt: float, _exposed: bool) -> void:
	var fl: bool = z._flash > 0.0
	var skin := Color(0.38, 0.95, 0.22, 0.8)
	var rim := Color(0.08, 0.42, 0.06, 0.9)
	var deep := Color(0.18, 0.62, 0.1, 0.85)
	if fl:
		skin = Color(0.95, 1.0, 0.9, 0.9)
	var f: Array = feet(4.5, 2.0)
	var lean := 0.0
	var arm_up := 0.0
	var puff := 0.0
	match state:
		ENGULF_W:
			lean = -2.5
			puff = clampf(1.0 - _st / ENGULF_WIND, 0.0, 1.0)
		ENGULF:
			lean = 5.0
			puff = 1.0
		B_SLAM_W:
			arm_up = clampf(1.0 - _st / B_SLAM_WIND, 0.0, 1.0)
			lean = -2.0
		B_SLAM:
			lean = 4.0
			arm_up = -0.5
		B_SPIT_W:
			puff = clampf(1.0 - _st / B_SPIT_WIND, 0.0, 1.0)
	var wob := sin(tt * 3.1 + _seed) * 0.8
	var hip := Vector2(0.0, -22.0)
	var sh := Vector2(1.0 + lean, -41.0 + wob * 0.4)
	var head := sh + Vector2(3.0 + lean * 0.3, -9.0 - puff * 1.0)
	if _scene_actor():
		head += Vector2(tilt * 2.0, 0.0)
	# רגליים: עמודי נוזל עבים שמתמזגים לשלולית קטנה בכפות
	U.oval(pts, cols, Vector2(0.0, -1.0), 15.0, 3.2, Color(rim, 0.75), 12)
	for i in 2:
		var ft: Vector2 = f[i]
		var hp := hip + Vector2(-3.0 + float(i) * 5.0, 0.0)
		U.taper(pts, cols, hp, ft + Vector2(0.0, -2.0), 8.6, 7.0, rim, rim)
		U.taper(pts, cols, hp, ft + Vector2(0.0, -2.0), 7.0, 5.6, deep if i == 0 else skin, skin)
		U.oval(pts, cols, ft + Vector2(1.0, -1.5), 5.5, 2.6, skin, 8)
	# יד אחורית
	var hand_b := sh + Vector2(9.0 + lean, 13.0 - arm_up * 30.0)
	U.taper(pts, cols, sh + Vector2(-5.0, 1.0), hand_b, 6.5, 5.0, deep, deep)
	U.oval(pts, cols, hand_b, 3.6, 3.0, deep, 8)
	# גוף: גוש נוזל עם בטן נפולה
	var tc := Vector2(1.0 + lean * 0.5, -33.0 + wob * 0.3)
	U.oval(pts, cols, tc, 12.8 + puff * 3.0, 15.0 + puff * 1.5, rim, 16)
	U.oval(pts, cols, tc + Vector2(1.0, 7.0), 11.6 + puff * 2.0, 8.6, rim, 14)
	U.oval(pts, cols, tc, 11.4 + puff * 3.0, 13.8 + puff * 1.5, skin, 16)
	U.oval(pts, cols, tc + Vector2(1.0, 7.0), 10.4 + puff * 2.0, 7.6, skin, 14)
	U.halo(pts, cols, tc + Vector2(0.0, 1.0), 9.0, 11.0, Color(0.8, 1.0, 0.5, 0.35), 12)
	# שלד בפנים (מי שהוא היה)
	var bone := Color(0.05, 0.22, 0.04, 0.45) if not fl else Color(0.6, 0.7, 0.6, 0.4)
	U.seg(pts, cols, sh + Vector2(-1.0, 1.0), hip + Vector2(-1.0, -1.0), 2.0, bone)
	for q in 4:   # צלעות
		var ry := sh.y + 4.0 + float(q) * 3.4
		U.seg(pts, cols, Vector2(-1.0, ry), Vector2(6.5 - float(q) * 0.6, ry + 2.4), 1.3, bone)
		U.seg(pts, cols, Vector2(-1.0, ry), Vector2(-6.0 + float(q) * 0.5, ry + 2.2), 1.3, bone)
	U.oval(pts, cols, hip + Vector2(0.0, -2.0), 5.0, 2.4, bone, 8)
	# ראש: כדור נוזל נפול, גולגולת בפנים
	U.oval(pts, cols, head, 8.4 + puff * 1.6, 8.8, rim, 14)
	U.oval(pts, cols, head + Vector2(1.0, 5.0), 7.0 + puff * 2.4, 4.4 + puff * 2.0, rim, 10)
	U.oval(pts, cols, head, 7.3 + puff * 1.6, 7.8, skin, 14)
	U.oval(pts, cols, head + Vector2(1.0, 5.0), 6.0 + puff * 2.4, 3.6 + puff * 2.0, skin, 10)
	U.oval(pts, cols, head + Vector2(0.5, -0.5), 4.4, 4.6, bone, 10)
	# פנים: עיניים זוהרות, פה פתוח שנוטף
	var eyes := Color(0.95, 1.0, 0.45) if not fl else Color.WHITE
	var mouth := 1.4 + 1.6 * puff
	if _scene_actor() and talking:
		mouth = 1.0 + 2.2 * absf(sin(t * 11.0))
	var face_k := clampf(U.since(U.face_ms) / 2.0, 0.0, 1.0) if (_scene_actor() and U.face_ms >= 0) else 0.0
	U.oval(pts, cols, head + Vector2(3.6, -1.6), 2.2, 1.7 - face_k * 0.6, Color(0.0, 0.1, 0.0, 0.85), 8)
	U.oval(pts, cols, head + Vector2(3.8, -1.6), 1.1, 1.1, eyes, 6)
	U.oval(pts, cols, head + Vector2(-0.6, -1.9), 1.6, 1.3, Color(0.0, 0.1, 0.0, 0.7), 6)
	U.oval(pts, cols, head + Vector2(-0.5, -1.9), 0.8, 0.8, Color(eyes, 0.8), 6)
	U.halo(pts, cols, head + Vector2(3.8, -1.6), 5.0, 4.0, Color(0.9, 1.0, 0.4, 0.35), 8)
	U.oval(pts, cols, head + Vector2(4.2, 3.4), 2.4 + smile * 1.5, mouth, Color(0.02, 0.12, 0.02, 0.9), 8)
	var dr := fposmod(tt * 0.9 + _seed, 1.0)
	U.seg(pts, cols, head + Vector2(4.2, 3.4 + mouth), head + Vector2(4.4, 4.0 + mouth + dr * 6.0), 1.2, skin)
	if face_k > 0.0:   # (סצנה) הפנים נהיים הפנים שלך: לסת מרובעת, שיער קצר
		U.seg(pts, cols, head + Vector2(-5.0, -6.5), head + Vector2(6.0, -7.0), 2.4, Color(0.1, 0.25, 0.08, 0.7 * face_k))
		U.seg(pts, cols, head + Vector2(6.0, 2.0), head + Vector2(3.0, 6.5), 1.4, Color(0.1, 0.3, 0.08, 0.7 * face_k))
	# יד קדמית (מושטת קדימה - נוטפת)
	var hand_f := sh + Vector2(15.0 + lean * 1.5 + puff * 3.0, 9.0 - arm_up * 34.0)
	U.taper(pts, cols, sh + Vector2(4.0, 1.0), hand_f, 7.6, 6.0, rim, rim)
	U.taper(pts, cols, sh + Vector2(4.0, 1.0), hand_f, 6.2, 4.8, skin, skin)
	U.oval(pts, cols, hand_f, 3.8, 3.2, skin, 8)
	for q in 2:   # טיפות שנוטפות מהידיים
		var k := fposmod(tt * 1.1 + float(q) * 0.5 + _seed, 1.0)
		var hp2: Vector2 = hand_f if q == 0 else hand_b
		var dp := hp2 + Vector2(0.0, 3.0 + k * k * 16.0)
		U.seg(pts, cols, hp2 + Vector2(0, 2.0), dp, 1.6 * (1.0 - k * 0.6), skin)
		U.oval(pts, cols, dp, 1.6, 2.0, skin, 6)
	# בועות שעולות בתוך הגוף
	for q in 4:
		var k2 := fposmod(tt * 0.45 + float(q) * 0.27 + _seed, 1.0)
		var bp := Vector2(-4.0 + float(q) * 3.0 + sin(k2 * 6.0 + float(q)) * 1.5, -14.0 - k2 * 36.0)
		U.oval(pts, cols, bp, 1.1 + 0.4 * float(q % 2), 1.1 + 0.4 * float(q % 2), Color(0.85, 1.0, 0.7, 0.45 * (1.0 - k2)), 6)
	# ברק (נוזל מבריק)
	U.oval(pts, cols, head + Vector2(-3.0, -4.0), 2.4, 1.4, Color(1, 1, 1, 0.45), 6, -0.5)
	U.oval(pts, cols, tc + Vector2(-6.0, -6.0), 1.8, 5.0, Color(1, 1, 1, 0.25), 8, 0.3)
	if _boss():   # THE FLOOD: עוד גולגולות צפות בתוכו (הרבה גופות בגוף אחד)
		for q in 3:
			var sp := Vector2(-6.0 + float(q) * 5.0 + sin(tt * 0.7 + float(q) * 2.0) * 2.0, -24.0 - float(q) * 6.0 + cos(tt * 0.5 + float(q)) * 2.0)
			U.oval(pts, cols, sp, 3.0, 3.2, bone, 8)
			U.oval(pts, cols, sp + Vector2(1.2, -0.4), 0.8, 0.9, Color(0.0, 0.05, 0.0, 0.6), 6)
		for q in 5:   # כתר של טיפות על הראש
			var a := -PI * 0.5 + (float(q) - 2.0) * 0.45
			var k3 := fposmod(tt * 0.7 + float(q) * 0.21, 1.0)
			U.oval(pts, cols, head + Vector2.from_angle(a) * (8.0 + k3 * 5.0), 1.5 * (1.0 - k3), 1.8 * (1.0 - k3), Color(skin, 0.8), 6)


# הגרעין (נקודת התורפה): באותו מקום שבו core_pos() בודק פגיעות. exposed = קם (גדול, פועם מהר)
func _draw_core(pts: PackedVector2Array, cols: PackedColorArray, tt: float, exposed: bool, sy: float) -> void:
	var cp: Vector2 = (core_pos() - z.global_position) / z.sc
	cp.x *= z._dir / z.wf
	cp.y *= sy
	var cr := (REFORM_CORE_R * 0.75 if exposed else CORE_R * 0.9) * (1.15 if _boss() else 1.0)
	var pul := 0.5 + 0.5 * sin(tt * (9.0 if exposed else 4.0))
	var hot := Color(0.85, 1.0, 0.3, 0.95) if z._flash <= 0.0 else Color.WHITE
	U.halo(pts, cols, cp, cr * (2.6 + pul), cr * (2.6 + pul), Color(0.95, 1.0, 0.4, 0.3 + (0.3 if exposed else 0.0)), 10)
	U.oval(pts, cols, cp, cr + 0.8, cr + 0.8, Color(0.3, 0.5, 0.0, 0.8), 12)
	U.oval(pts, cols, cp, cr, cr, hot, 12)
	U.oval(pts, cols, cp + Vector2(-cr * 0.25, -cr * 0.25), cr * 0.45, cr * 0.45, Color(1, 1, 1, 0.9), 8)
	if exposed:   # קווי אור שיוצאים מהגרעין החשוף
		for q in 6:
			var an := float(q) / 6.0 * TAU + tt * 2.0
			U.seg(pts, cols, cp + Vector2.from_angle(an) * (cr + 1.5), cp + Vector2.from_angle(an) * (cr + 5.0 + 2.0 * pul), 1.0, Color(1.0, 1.0, 0.6, 0.7))


# חוטי רפש בין השלולית לעמוד שעולה
func _strands(pts: PackedVector2Array, cols: PackedColorArray, sy: float, tt: float) -> void:
	for q in 4:
		var x := -10.0 + float(q) * 7.0
		var top := Vector2(x * 0.6, -50.0 * sy * (0.3 + 0.15 * float(q % 2)))
		U.taper(pts, cols, Vector2(x * 1.6 + sin(tt * 5.0 + float(q)) * 2.0, -1.0), top, 3.2, 1.0, Color(0.38, 0.95, 0.22, 0.6), Color(0.38, 0.95, 0.22, 0.3))


# שלולית (k = כמה היא פרושה). בליטה קדימה, אדוות, בועות, שתי עיניים צפות, הגרעין מעומעם בתחתית
func _draw_pool(pts: PackedVector2Array, cols: PackedColorArray, k: float, tt: float) -> void:
	var fl: bool = z._flash > 0.0
	var rx := lerpf(14.0, POOL.x * 0.55, k)
	var flow := clampf(absf(z.velocity.x) / FLOW_V, 0.0, 1.0)
	var skin := Color(0.38, 0.95, 0.22, 0.85) if not fl else Color(0.95, 1.0, 0.9, 0.9)
	var rim := Color(0.08, 0.42, 0.06, 0.9)
	U.oval(pts, cols, Vector2(0.0, -1.5), rx + 2.0, 4.6, rim, 16)
	U.oval(pts, cols, Vector2(0.0, -2.0), rx, 3.6, skin, 16)
	# הבליטה הקדמית (החזית של הזרימה) + השובל
	var bulge := 4.5 + 2.5 * flow + sin(tt * 6.0) * 0.8
	U.oval(pts, cols, Vector2(rx * 0.62, -2.5), 10.0 + 4.0 * flow, bulge + 1.2, rim, 12)
	U.oval(pts, cols, Vector2(rx * 0.62, -2.8), 9.0 + 4.0 * flow, bulge, skin, 12)
	U.oval(pts, cols, Vector2(rx * 0.55, -4.5 - bulge * 0.5), 3.5, 1.0, Color(1, 1, 1, 0.45), 6)
	U.halo(pts, cols, Vector2(0.0, -2.5), rx * 0.8, 3.0, Color(0.8, 1.0, 0.5, 0.35), 12)
	# הגרעין בתחתית (מעומעם, לא פגיע)
	U.oval(pts, cols, Vector2(-2.0, -2.0), 3.0, 1.6, Color(0.8, 1.0, 0.3, 0.45 + 0.2 * sin(tt * 3.0)), 8)
	# אדוות + בועות
	for q in 2:
		var rk := fposmod(tt * 0.8 + float(q) * 0.5, 1.0)
		U.oval(pts, cols, Vector2(-rx * 0.3, -2.4), rx * 0.3 * (0.3 + rk), 1.0 * (0.3 + rk), Color(1, 1, 1, 0.18 * (1.0 - rk)), 10)
	for q in 3:
		var bk := fposmod(tt * 1.6 + float(q) * 0.37 + _seed, 1.0)
		var bp := Vector2(-rx * 0.6 + float(q) * rx * 0.5, -3.0 - bk * 3.0)
		U.oval(pts, cols, bp, 1.2 + bk * 1.0, 1.2 + bk * 1.0, Color(0.85, 1.0, 0.7, 0.55 * (1.0 - bk)), 6)
	# עיניים צפות (מסתכלות קדימה, ממצמצות)
	if k > 0.5 and not _boss():
		var blink := 0.25 if fposmod(tt * 0.6 + _seed, 1.0) < 0.06 else 1.0
		for q in 2:
			var ep := Vector2(rx * 0.45 + float(q) * 4.5, -5.0 - bulge * 0.3)
			U.oval(pts, cols, ep, 1.7, 1.4 * blink, Color(0.0, 0.1, 0.0, 0.85), 6)
			U.oval(pts, cols, ep + Vector2(0.4, 0.0), 0.8, 0.8 * blink, Color(0.95, 1.0, 0.45), 6)
	elif _boss():   # THE FLOOD: גולגולות צפות בשלולית
		for q in 3:
			var sp := Vector2(-rx * 0.5 + float(q) * rx * 0.45, -4.0 + sin(tt * 2.0 + float(q)) * 0.8)
			U.oval(pts, cols, sp, 2.6, 2.2, Color(0.05, 0.22, 0.04, 0.6), 8)


# הגל של THE FLOOD (קואורדינטות עולם יחסית לזומבי, בלי היפוך): קיר נוזל שמתעקם קדימה, שובל עד נקודת ההתחלה
func _draw_wave(pts: PackedVector2Array, cols: PackedColorArray, tt: float) -> void:
	var dr := _wave_dir
	var gy := 0.0
	var skin := Color(0.38, 0.95, 0.22, 0.8)
	var rim := Color(0.08, 0.42, 0.06, 0.9)
	# השובל: שכבה דקה עד המקום שבו התחיל
	var back: float = _wave_x0 - z.global_position.x
	U.quad(pts, cols, Vector2(0.0, gy - 10.0), Vector2(back, gy - 2.0), Vector2(back, gy), Vector2(0.0, gy), Color(skin, 0.7), Color(skin, 0.0), Color(rim, 0.0), Color(rim, 0.8))
	# גוף הגל: פרופיל שעולה מאחור ומתעקם קדימה בראש
	var prof := PackedVector2Array()
	for q in 13:
		var u := float(q) / 12.0
		var h := WAVE_H * sin(u * PI * 0.62) * (1.0 + 0.06 * sin(tt * 9.0 + u * 7.0))
		var x := -dr * (110.0 - u * 110.0) + dr * pow(u, 3.0) * 16.0
		prof.append(Vector2(x, gy - h))
	for q in prof.size() - 1:
		var a: Vector2 = prof[q]
		var b: Vector2 = prof[q + 1]
		U.quad(pts, cols, Vector2(a.x, gy), Vector2(b.x, gy), b, a, rim, rim, skin, skin)
	# השפה המתעקמת + קצף
	var tip: Vector2 = prof[prof.size() - 1]
	U.taper(pts, cols, tip, tip + Vector2(dr * 18.0, 16.0), 10.0, 3.0, skin, Color(skin, 0.4))
	for q in 7:
		var k := fposmod(tt * 2.0 + float(q) * 0.14, 1.0)
		var fp: Vector2 = prof[6 + (q % 6)] + Vector2(dr * k * 12.0, -k * 6.0)
		U.oval(pts, cols, fp, 2.6 * (1.0 - k) + 1.0, 2.0 * (1.0 - k) + 1.0, Color(0.9, 1.0, 0.8, 0.7 * (1.0 - k)), 6)
	# גולגולות וגופות שנסחפות בתוכו
	for q in 4:
		var sp := Vector2(-dr * (20.0 + float(q) * 22.0), gy - 14.0 - float(q % 2) * 18.0 + sin(tt * 3.0 + float(q)) * 3.0)
		U.oval(pts, cols, sp, 6.0, 6.5, Color(0.05, 0.22, 0.04, 0.55), 8)
		U.oval(pts, cols, sp + Vector2(dr * 2.0, -1.0), 1.6, 1.8, Color(0.0, 0.05, 0.0, 0.7), 6)
	# הגרעין נסחף בתוך הגל
	var cp := Vector2(-dr * 40.0, gy - 26.0)
	U.halo(pts, cols, cp, 22.0, 22.0, Color(0.95, 1.0, 0.4, 0.3), 10)
	U.oval(pts, cols, cp, 9.0, 9.0, Color(0.85, 1.0, 0.3, 0.8), 12)
	U.halo(pts, cols, Vector2(-dr * 50.0, gy - WAVE_H * 0.4), 90.0, WAVE_H * 0.6, Color(0.6, 1.0, 0.4, 0.15), 14)


# טבעת מבעבעת מתחת לשחקן / עמוד הרפש (GEYSER) - בטרנספורם עולם
func _draw_geyser() -> void:
	if _gey_t <= -GEY_T:
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	var c := Vector2(_gey_x - z.global_position.x, 0.0)
	if _gey_t > 0.0:
		var k := 1.0 - _gey_t / GEY_WARN
		U.oval(pts, cols, c + Vector2(0, -1.0), GEY_R * (0.5 + 0.5 * k), 4.0, Color(0.08, 0.42, 0.06, 0.8), 14)
		U.oval(pts, cols, c + Vector2(0, -1.5), GEY_R * (0.4 + 0.5 * k), 3.0, Color(0.38, 0.95, 0.22, 0.7 + 0.3 * sin(z._time * 30.0)), 14)
		for q in 5:
			var bk := fposmod(z._time * 3.0 + float(q) * 0.2, 1.0)
			U.oval(pts, cols, c + Vector2((float(q) - 2.0) * GEY_R * 0.3, -2.0 - bk * 8.0), 2.0 + bk * 2.0, 2.0 + bk * 2.0, Color(0.85, 1.0, 0.7, 0.7 * (1.0 - bk)), 6)
	else:
		var k2 := clampf(-_gey_t / GEY_T, 0.0, 1.0)
		var h := 210.0 * sin(clampf(k2 * 1.6, 0.0, 1.0) * PI * 0.5) * (1.0 - maxf(0.0, k2 - 0.7) / 0.3)
		U.taper(pts, cols, c, c + Vector2(0, -h), GEY_R * 1.1, GEY_R * 0.5, Color(0.08, 0.42, 0.06, 0.9), Color(0.38, 0.95, 0.22, 0.6))
		U.taper(pts, cols, c, c + Vector2(0, -h), GEY_R * 0.8, GEY_R * 0.3, Color(0.38, 0.95, 0.22, 0.85), Color(0.7, 1.0, 0.5, 0.5))
		U.oval(pts, cols, c + Vector2(0, -h), GEY_R * 0.6, 10.0, Color(0.6, 1.0, 0.4, 0.7), 10)
	U.flush(z, pts, cols)


# מת: הנוזל מתפשט ונספג ברצפה (או מתאדה). בטרנספורם עולם, במקום שבו מת
func _draw_dead() -> void:
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var c: Vector2 = _dpos - z.global_position + Vector2(0, -1.0)
	var k := clampf(float(z._dead_t) / 2.0, 0.0, 1.0)
	var a := 1.0 - k
	var rx: float = (22.0 + 30.0 * k) * z.sc * (0.6 if _evap else 1.0)
	U.oval(pts, cols, c, rx + 2.0, 3.2 * z.sc * (1.0 - k * 0.5), Color(0.08, 0.42, 0.06, 0.8 * a), 16)
	U.oval(pts, cols, c + Vector2(0, -0.5), rx, 2.4 * z.sc * (1.0 - k * 0.5), Color(0.38, 0.95, 0.22, 0.7 * a), 16)
	for q in 3:   # שברי הגרעין
		U.oval(pts, cols, c + Vector2((float(q) - 1.0) * rx * 0.4, -1.5), 1.6, 1.0, Color(0.85, 1.0, 0.3, 0.6 * a), 6)
	U.flush(z, pts, cols)
