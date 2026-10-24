extends "res://enemies/zombie_type.gd"
# ============================================================
#  DRIFTER (שלב 55, "WIND STEPPE") - זומבי תלוי ברתמה מתחת למצנח רחיפה (paraglider) קרוע וצבעוני.
#  קסדה סדוקה, משקפי טיסה, מעיל רוח קרוע, רגליים מתנדנדות, ידיים למעלה על ידיות הבלמים.
#  מה הוא למד: "הגיבור לא מסתכל למעלה". הם מתו מולך על הכביש, בגובה העיניים - אז הם באים מהשמיים, עם הרוח.
#  הוא לא יכול לעוף נגד הרוח: נסחף במורד הרוח (DRIFT_V x wind), יכול רק לבלום / להאיץ קצת (STEER), לעולם לא לחזור.
#    משב (stage.gust_k) = עולה (CLIMB). הרוח נופלת (wind קרוב ל-0) = שוקע (SINK). הצל שלו על הקרקע = הרמז ("תסתכל למעלה").
#  מחזור:
#    PERCH  - עומד על במה (מגדל מים / טורבינה) עם הכנף מקופלת שמתנופפת. אתה במורד הרוח בטווח (LAUNCH_R) -> LAUNCH.
#    KITE   - על הקרקע, הכנף מתנפחת מאחוריו ומחכה למשב. משב (או KITE_WAIT) -> המשב מרים אותו (LAUNCH).
#    FLY    - נסחף אליך עם הרוח בגובה CRUISE. מעליך -> מפיל סלע / עמוד גדר (ROCK, עם צל שגדל על הקרקע).
#             לפניך ומתחת (DIVE_DX) -> DIVE_W (צווחה, רגליים למעלה, DIVE_WIND) -> DIVE: צלילה עליך (DIVE_V, DIVE_DMG).
#             AIR_MAX שניות באוויר -> צלילה בכוח / יורד. עברת אותו נגד הרוח (PASS_DX) -> הוא מוריד אוויר ונוחת.
#             תמיד יורד תוך כמה שניות - אף פעם לא מרחף מחוץ לטווח.
#    LANDED - נחת / נחבט: מסוחרר רגע (חלון), זורק את הכנף ו- GROUND: זומבי רגלי חלש (המוח).
#  נגד: לירות בכנף (מטרה גדולה וצבעונית, CANOPY_HP): כל פגיעה קורעת חור וחתיכות בד עפות. נקרעה -> SPIRAL:
#    מסתחרר למטה עם הכנף המקופלת ומתרסק (CRASH_DMG - הורג, ענן אבק, רסס דם). אש (להביור / דרקון) = הכנף נשרפת מיד.
#    פיצוץ קורע את הכנף. גם הגוף נהרג (כל נשק): מת באוויר -> הכנף הריקה עפה ברוח.
#  "THEY CUT LOOSE NOW" (main meta "dr_rips" >= LEARN): אחרי שקרעת LEARN כנפיים, הבאים חותכים את החוטים בעצמם -
#    כשהם מעליך ולפניך, או ברגע שהכנף נפגעת - ונופלים עליך ברגליים (CUT). והשלב שולח אותם בזוגות מכיוון הרוח.
#  צלילים: "dr_flap", "dr_rip", "dr_screech", "dr_crash", "dr_cut", "dr_whistle", "dr_thud" (מסונתזים).
#  לשנות: DRIFT_V, STEER, MIN_V, CRUISE, CLIMB, SINK, LAUNCH_R, KITE_WAIT, DIVE_DX, DIVE_WIND, DIVE_V, DIVE_DMG, ROCK_DMG,
#    AIR_MAX, PASS_DX, CANOPY_HP, CRASH_DMG, LEARN.
# ============================================================

const SOUNDS := {
	"dr_flap": {"drive": 1.3, "layers": [["N", 0, 0, 0.0, 0.5, 0.02, 3.0, 0.4, 0.3, 0.4, 0.05], ["B", 14.0, 9.0, 0.0, 0.5, 0.0, 3.0, 0.25, 1.0, 0, 0, 30.0]]},
	"dr_rip": [["N", 0, 0, 0.0, 0.28, 0.0, 9.0, 0.75, 0.75, 0.6, 0.35], ["N", 0, 0, 0.06, 0.2, 0.0, 12.0, 0.5, 0.9, 0.9, 0.5]],
	"dr_screech": {"drive": 2.6, "layers": [["V", 380, 820, 0.0, 0.45, 0.01, 4.0, 0.75, 1.0, 0.08, 0, [850, 2300, 50]], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.3, 0.6, 0, 0.25]]},
	"dr_crash": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.9, 0.12, 0], ["C", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.8, 1.0, 0], ["S", 90, 40, 0.0, 0.35, 0.0, 7.0, 0.7, 1.0, 0], ["V", 160, 90, 0.04, 0.4, 0.01, 6.0, 0.4, 1.0, 0.1, 0, [520, 1000, 60]]]},
	"dr_cut": [["S", 2400, 1600, 0.0, 0.06, 0.0, 40.0, 0.35, 1.0, 0], ["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.5, 1.0, 0], ["S", 2100, 1300, 0.07, 0.06, 0.0, 40.0, 0.3, 1.0, 0]],
	"dr_whistle": [["S", 1500, 520, 0.0, 0.7, 0.05, 1.6, 0.18, 1.0, 0.0]],
	"dr_thud": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.7, 0.1, 0], ["S", 80, 40, 0.0, 0.25, 0.0, 9.0, 0.6, 1.0, 0]],
}

const FleshFx := preload("res://effects/flesh_fx.gd")
const DebrisScript := preload("res://debris.gd")

const DRIFT_V := 175.0           # מהירות סחיפה ברוח מלאה
const STEER := 70.0              # כמה הוא יכול לבלום / להאיץ (לא נגד הרוח)
const MIN_V := 16.0              # מינימום במורד הרוח
const CRUISE := 250.0            # גובה שיוט מעל הקרקע
const CLIMB := 125.0             # עולה במשב
const SINK := 95.0               # שוקע כשהרוח נופלת
const LAUNCH_R := 640.0
const KITE_WAIT := 5.0
const DIVE_DX := Vector2(60.0, 270.0)   # השחקן לפניו (במורד הרוח) בטווח הזה ומתחתיו -> צלילה
const DIVE_WIND := 0.4
const DIVE_V := 390.0
const DIVE_DMG := 1
const ROCK_DMG := 1
const AIR_MAX := 6.5
const PASS_DX := 170.0
const CANOPY_HP := 24
const CANOPY_Y := 112.0          # מרכז הכנף מעל הרגליים (יחידות ציור)
const CANOPY_W := 74.0           # חצי רוחב
const CRASH_DMG := 80
const LEARN := 2

enum { PERCH, KITE, LAUNCH, FLY, DIVE_W, DIVE, CUT, SPIRAL, LANDED, GROUND }

# לבדיקות
var launches := 0
var dives := 0
var dive_hits := 0
var rocks := 0
var rock_hits := 0
var canopy_hits := 0
var rips := 0
var crashes := 0
var cuts := 0
var cut_hits := 0
var landings := 0
var forced := 0
var burns := 0
var max_air := 0.0

var state := KITE
var _first := true
var _t := 0.0
var _cd := 0.8
var _air := 0.0
var _canopy_hp := CANOPY_HP
var _canopy := true              # הכנף עדיין מחוברת
var _torn := false               # נקרעה (SPIRAL)
var _inflate := 0.3              # 0 מקופלת .. 1 פתוחה
var _holes: Array = []           # חורים בכנף [x יחסי -1..1, עומק 0..1, גודל]
var _cfire := 0.0                # הכנף בוערת
var _cflash := 0.0
var _rocks_left := 1
var _target := Vector2.ZERO
var _hit_done := false
var _swing := 0.0                # נדנוד הגוף מתחת לכנף
var _swing_v := 0.0
var _spin_a := 0.0
var _gy := 630.0                 # הקרקע מתחת (לצל)
var _gy_t := 0.0
var _spill := false
var _wd := -1.0                  # כיוון הרוח האחרון
var _flap_t := 0.0
var _body: StaticBody2D = null
var _cshape: CollisionShape2D = null
# צבעים לכל אחד
var _c1 := Color("ff6a2a")
var _c2 := Color("f0d040")
var _c3 := Color("2a3a6a")
var _jacket := Color("3a5a7a")
var _helmet := Color("e8e0d0")


class CanopyBody extends StaticBody2D:
	var owner_t = null
	func take_damage(_a, p: Vector2, d: Vector2, _e := false, s := {}) -> void:
		if owner_t != null:
			owner_t.canopy_hit(p, d, s)


func stats() -> Dictionary:
	return {"name": "DRIFTER", "hp": 26, "walk": 50.0, "chase": 104.0, "damage": 1, "bite_delay": 0.8, "scale": 0.95, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("98a888"), "shirt": _jacket, "pants": Color("4a4a52"), "shoe": Color("2a2420"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func use_brain_movement() -> bool:
	return state == GROUND


func can_bite() -> bool:
	return state == GROUND


func can_groan() -> bool:
	return state == GROUND or state == KITE or state == PERCH


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func _wind() -> float:
	var st := _stage()
	if st != null and st.has_method("wind"):
		return float(st.wind())
	return -0.4


func _gust() -> float:
	var st := _stage()
	if st != null and st.has_method("gust_k"):
		return float(st.gust_k())
	return 0.0


func _floor() -> float:
	var st := _stage()
	return float(st.floor_y) if st != null else 630.0


static func is_learned(m: Node) -> bool:
	return m != null and int(m.get_meta("dr_rips", 0)) >= LEARN


func learned() -> bool:
	return is_learned(_main())


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 7 + 3
	var pal := [[Color("ff6a2a"), Color("f0d040")], [Color("e83a4a"), Color("f0f0e8")], [Color("2ab0c0"), Color("f0e040")],
		[Color("c040a0"), Color("ffb040")], [Color("40c060"), Color("f0f0e0")], [Color("ffcc20"), Color("2a5ad0")]]
	var p: Array = pal[r.randi() % pal.size()]
	_c1 = p[0]
	_c2 = p[1]
	_c3 = [Color("2a3a6a"), Color("3a2a2a"), Color("1e3a30")][r.randi() % 3]
	_jacket = [Color("3a5a7a"), Color("7a3a2a"), Color("4a5a3a"), Color("5a4a6a"), Color("8a6a2a")][r.randi() % 5]
	z.shirt = _jacket
	_helmet = [Color("e8e0d0"), Color("d04a2a"), Color("2a2a30"), Color("e0c040")][r.randi() % 4]
	_body = CanopyBody.new()
	_body.owner_t = self
	_body.collision_layer = 4
	_body.collision_mask = 0
	_cshape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(CANOPY_W * 2.0 * z.sc, 40.0 * z.sc)
	_cshape.shape = rs
	_cshape.position = Vector2(0.0, -CANOPY_Y * z.sc)
	_body.add_child(_cshape)
	z.add_child(_body)
	_wd = signf(_wind()) if absf(_wind()) > 0.02 else -1.0


# מה הוא עושה בהתחלה: על במה -> PERCH, נולד באוויר (stage: meta "dr_fly") -> FLY, אחרת KITE
func _init_state() -> void:
	if z.has_meta("dr_fly"):
		state = FLY
		_inflate = 1.0
		_air = 0.0
		z.velocity = Vector2(_wind() * DRIFT_V, 0.0)
		z.collision_mask = 1   # באוויר: עובר דרך קומות (רק הקרקע / מכשולים עוצרים)
	elif z.global_position.y < _floor() - 40.0:
		state = PERCH
		_inflate = 0.2
	else:
		state = KITE
		_t = KITE_WAIT * randf_range(0.6, 1.2)
		_inflate = 0.35


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	if _first:
		_first = false
		_init_state()
	_t -= delta
	_cd -= delta
	_cflash = maxf(0.0, _cflash - delta)
	var w := _wind()
	if absf(w) > 0.03:
		_wd = signf(w)
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2(9999, 0)
	_canopy_fire_tick(delta)
	if state == GROUND:
		return false
	# נדנוד הגוף מתחת לכנף (מטוטלת לפי התאוצה)
	var acc: float = -z.velocity.x * 0.004
	_swing_v += (acc - _swing * 9.0) * delta * 6.0
	_swing_v *= 1.0 - 2.5 * delta
	_swing = clampf(_swing + _swing_v * delta, -0.7, 0.7)
	_gy_t -= delta
	if _gy_t <= 0.0:
		_gy_t = 0.15
		_gy = _ground_under()
	match state:
		PERCH:
			_perch(pl, has, d, w, delta)
		KITE:
			_kite(pl, has, d, w, delta)
		LAUNCH:
			_inflate = move_toward(_inflate, 1.0, delta * 3.0)
			z.velocity.x = move_toward(z.velocity.x, w * DRIFT_V * 0.7, 300.0 * delta)
			z.velocity.y = move_toward(z.velocity.y, -150.0, 900.0 * delta)
			z._dir = _wd
			if _t <= 0.0:
				state = FLY
				_air = 0.0
		FLY:
			_fly(pl, has, d, w, delta)
		DIVE_W:
			z.velocity = z.velocity.move_toward(Vector2(w * 40.0, -50.0), 500.0 * delta)
			if has:
				_target = _target.lerp(pl.global_position + Vector2(0, -24), clampf(delta * 3.0, 0.0, 1.0))
				z._dir = signf(_target.x - z.global_position.x) if absf(_target.x - z.global_position.x) > 4.0 else z._dir
			if _t <= 0.0:
				state = DIVE
				_t = 1.6
				_hit_done = false
				dives += 1
		DIVE:
			if has:   # מתקן קצת (לא טיל)
				_target = _target.lerp(pl.global_position + Vector2(0, -24), clampf(delta * 1.4, 0.0, 1.0))
			var aim := _target + Vector2(0, 20)
			var dv: Vector2 = (aim - (z.global_position + Vector2(0, -30))).normalized()
			z.velocity = z.velocity.move_toward(dv * DIVE_V + Vector2(w * 50.0, 0.0), 1600.0 * delta)
			z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir
			_check_hit(pl, has, DIVE_DMG, false)
			if z.is_on_floor() or _t <= 0.0 or (z.global_position.y > aim.y + 30.0 and z.velocity.y > 0.0 and absf(d.x) > 60.0):
				_land(0.75)
		CUT:
			z.velocity.y = minf(z.velocity.y + z.gravity * 1.15 * delta, 720.0)
			if has:
				z.velocity.x = move_toward(z.velocity.x, clampf(d.x * 2.0, -230.0, 230.0), 600.0 * delta)
			_check_hit(pl, has, DIVE_DMG, true)
			if z.is_on_floor():
				_land(0.35)
		SPIRAL:
			_spin_a += delta * 7.5
			_inflate = move_toward(_inflate, 0.35, delta)
			z.velocity.x = move_toward(z.velocity.x, w * 60.0 + cos(_spin_a) * 150.0, 700.0 * delta)
			z.velocity.y = move_toward(z.velocity.y, 340.0, 420.0 * delta)
			_flap_t -= delta
			if _flap_t <= 0.0:
				_flap_t = 0.35
				Sfx.play("dr_flap", z.global_position, -2.0, 0.15, 2)
			if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(z, z.global_position):
				var c: Vector2 = z.global_position + Vector2(0, -CANOPY_Y * z.sc * 0.7)
				var dbr = DebrisScript.new()
				_main().add_child(dbr)
				dbr.setup(c, Vector2(randf_range(3, 6), randf_range(2, 4)), _c1 if randf() < 0.6 else _c2, Vector2(w * 160.0, -randf_range(40, 140)))
			if z.is_on_floor() or z.is_on_wall() or z.global_position.y > _floor() + 4.0:
				_crash()
				return true
		LANDED:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 700.0 * delta)
			_inflate = move_toward(_inflate, 0.0, delta * 2.0)
			if _t <= 0.0 and z.is_on_floor():
				state = GROUND
				_drop_canopy(false)
	z.move_and_slide()
	if state == FLY or state == DIVE or state == DIVE_W or state == LAUNCH:
		_air += delta
		max_air = maxf(max_air, _air)
		if z.global_position.x < 30.0 or z.is_on_ceiling():
			z.velocity = Vector2(0.0, 120.0)
	return true


func _perch(pl: Node, has: bool, d: Vector2, w: float, delta: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
	_inflate = 0.15 + 0.1 * sin(z._time * 5.0) + 0.25 * _gust()
	if not has:
		return
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	if absf(d.x) < LAUNCH_R and absf(d.x) > 70.0:
		var downwind := signf(d.x) == _wd
		if downwind:
			_launch(220.0)
		elif absf(d.x) < 320.0:   # עברת אותו נגד הרוח: קופץ למטה ונלחם ברגל
			state = LANDED
			_t = 0.3
			z.velocity = Vector2(signf(d.x) * 130.0, -220.0)
	elif absf(d.x) <= 70.0 and d.y > 40.0:   # אתה ממש מתחתיו
		state = CUT
		cuts += 1
		_drop_canopy(false)
		z.velocity = Vector2(0.0, -80.0)


func _kite(pl: Node, has: bool, d: Vector2, w: float, delta: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	_inflate = move_toward(_inflate, 0.35 + 0.45 * _gust() + 0.15 * absf(w), delta * 2.0)
	if not has:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 300.0 * delta)
		return
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	var downwind := signf(d.x) == _wd
	z.velocity.x = move_toward(z.velocity.x, z._dir * 26.0 if absf(d.x) > 200.0 else 0.0, 300.0 * delta)
	z._walk_phase += delta * absf(z.velocity.x) / 9.0
	if absf(d.x) < 220.0 or (not downwind and absf(d.x) < 700.0):   # קרוב / אתה מאחוריו: זורק את הכנף ונלחם
		state = LANDED
		_t = 0.25
		return
	if downwind and absf(d.x) < 1150.0 and (_gust() > 0.45 or _t <= 0.0):
		_launch(330.0)


func _launch(vy: float) -> void:
	state = LAUNCH
	_t = 0.45
	launches += 1
	_air = 0.0
	_rocks_left = 1
	z.velocity.y = -vy
	z.velocity.x = _wd * 90.0
	z.collision_mask = 1   # באוויר: עובר דרך קומות
	Sfx.play("dr_flap", z.global_position, 0.0, 0.1, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -4), "smoke", Vector2(_wd, -0.3), 5)


func _fly(pl: Node, has: bool, d: Vector2, w: float, delta: float) -> void:
	_inflate = move_toward(_inflate, 1.0, delta * 2.0)
	var gk := _gust()
	var lull := clampf(1.0 - absf(w) / 0.22, 0.0, 1.0)
	var steer := 0.0
	if has:
		steer = clampf((pl.global_position.x - _wd * 30.0 - z.global_position.x) * 0.9, -STEER, STEER)
	var vx := w * DRIFT_V + steer
	if vx * _wd < MIN_V:   # לא יכול נגד הרוח
		vx = _wd * MIN_V
	z.velocity.x = move_toward(z.velocity.x, vx, 220.0 * delta)
	z._dir = _wd
	var ty := _floor() - CRUISE
	var vy := clampf((ty - z.global_position.y) * 1.1, -60.0, 60.0) - gk * CLIMB + lull * SINK
	if _spill:
		vy = 240.0
	z.velocity.y = move_toward(z.velocity.y, vy, 300.0 * delta)
	_flap_t -= delta
	if _flap_t <= 0.0:
		_flap_t = randf_range(0.9, 1.6) if gk < 0.3 else 0.45
		if Art.on_screen(z, z.global_position):
			Sfx.play("dr_flap", z.global_position, -8.0, 0.15, 2)
	if (z.is_on_floor() or z.global_position.y > _floor() - 8.0) and _air > 0.5:
		_land(0.5)
		return
	if not has:
		return
	var rel: float = d.x
	var ahead := rel * _wd   # חיובי = אתה לפניו במורד הרוח
	var below: float = d.y
	# סלע / עמוד גדר כשהוא מעליך
	if _rocks_left > 0 and _cd <= 0.0 and absf(rel) < 40.0 + absf(z.velocity.x) * 0.35 and below > 150.0:
		_rocks_left -= 1
		_cd = 0.6
		_drop_rock(pl)
		return
	if learned() and _cd <= 0.0 and ahead > -10.0 and ahead < 190.0 and below > 90.0:
		_cut(pl)
		return
	if _cd <= 0.0 and ahead > DIVE_DX.x and ahead < DIVE_DX.y and below > 50.0:
		_start_dive(pl)
		return
	if _air > AIR_MAX and not _spill:   # תמיד יורד
		forced += 1
		if absf(rel) < 600.0 and below > 0.0:
			_start_dive(pl)
		else:
			_spill = true
		return
	if ahead < -PASS_DX and not _spill:   # עברת אותו נגד הרוח - לא יכול לחזור: מוריד אוויר ונוחת
		_spill = true


func _start_dive(pl: Node) -> void:
	state = DIVE_W
	_t = DIVE_WIND
	_target = pl.global_position + Vector2(0, -24) + pl.velocity * 0.2
	Sfx.play("dr_screech", z.global_position, 2.0, 0.1, 2)


func _cut(pl: Node) -> void:
	state = CUT
	cuts += 1
	_cd = 1.0
	_drop_canopy(true)
	z.velocity = Vector2(z.velocity.x * 0.5, -60.0)
	Sfx.play("dr_cut", z.global_position, 2.0, 0.1, 2)
	Sfx.play("dr_screech", z.global_position, 0.0, 0.1, 2)
	var m := _main()
	if m != null and not m.has_meta("dr_cut_said"):
		m.set_meta("dr_cut_said", true)
		z._popup("THEY CUT LOOSE NOW", Color("ffb070"), 15, -110.0)
		if pl != null and pl.has_method("_say"):
			pl._say("They're dropping straight on me!", Color("ffb070"))


func _check_hit(pl: Node, has: bool, dmg: int, stomp: bool) -> void:
	if _hit_done or not has:
		return
	var me := Rect2(z.global_position + Vector2(-14.0, -52.0) * z.sc, Vector2(28.0, 52.0) * z.sc)
	if me.intersects(pl.body_rect()):
		_hit_done = true
		if pl._roll_t <= 0.0:
			if stomp:
				cut_hits += 1
			else:
				dive_hits += 1
		pl.hurt(dmg, Vector2(signf(z.velocity.x + 0.01) * 1.2, -0.4))
		Sfx.play("dr_thud", z.global_position, 2.0, 0.1, 2)
		z.velocity = Vector2(-signf(z.velocity.x + 0.01) * 140.0, -180.0)
		_land(0.6)


func _land(stun: float) -> void:
	if state == LANDED or state == GROUND:
		return
	state = LANDED
	landings += 1
	_t = stun
	z.collision_mask = 1 | 16
	_spill = false
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -2), "smoke", Vector2(_wd, -0.3), 6)
	Sfx.play("dr_thud", z.global_position, -2.0, 0.1, 2)


# הכנף נפרדת ממנו (נוחת / חותך / מת): עפה ברוח
func _drop_canopy(fly_away: bool) -> void:
	if not _canopy:
		return
	_canopy = false
	if _body != null:
		_body.collision_layer = 0
	if _inflate < 0.12 and not fly_away:
		return
	var lc := LooseCanopy.new()
	lc.c1 = _c1
	lc.c2 = _c2
	lc.c3 = _c3
	lc.torn = _torn
	lc.holes = _holes.duplicate()
	lc.k = z.sc * maxf(_inflate, 0.4)
	lc.vel = Vector2(_wind() * 120.0, -110.0 if fly_away else -40.0)
	lc.stage = _stage()
	_main().add_child(lc)
	lc.global_position = z.global_position + Vector2(0, -CANOPY_Y * z.sc)


# ============================================================
#  הכנף: פגיעות, קריעה, אש
# ============================================================
func canopy_hit(p: Vector2, d: Vector2, src: Dictionary) -> void:
	if z.dead or not _canopy or _torn:
		return
	if not (state == FLY or state == DIVE_W or state == DIVE or state == LAUNCH or state == PERCH or state == KITE):
		return
	var dmg := 10
	if src.has("fixed"):
		dmg = int(src.fixed)
	elif src.has("dmg_mult"):
		dmg = maxi(4, int(round(10.0 * float(src.dmg_mult))))
	if src.get("sniper", false):
		dmg *= 2
	if src.get("god", false):
		dmg *= 4
	canopy_hits += 1
	_cflash = 0.07
	Game.on_zombie_hit({"source": "bullet", "zone": "canopy", "shot": src.get("shot", 0)})
	var lx: float = (p.x - z.global_position.x) / (CANOPY_W * z.sc) * z._dir
	if _holes.size() < 7:
		_holes.append([clampf(lx, -0.9, 0.9), randf_range(0.2, 0.8), randf_range(3.0, 6.0)])
	if Art.on_screen(z, p):
		for i in Quality.scaled(4, 1.0):
			var dbr = DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(p, Vector2(randf_range(3, 7), randf_range(2, 5)), _c1 if randf() < 0.6 else _c2, Vector2(d.x * randf_range(60, 200) + _wind() * 120.0, -randf_range(40, 200)))
	Sfx.play("dr_rip", p, -6.0, 0.2, 3)
	_swing_v += d.x * 1.5
	if src.get("incendiary", false):
		_ignite_canopy()
		return
	if learned() and (state == FLY or state == DIVE_W) and z.global_position.y < _floor() - 60.0:   # למד: חותך לפני שתקרע
		_cut(player())
		return
	_canopy_hp -= dmg
	if _canopy_hp <= 0:
		_rip()


func _ignite_canopy() -> void:
	if _cfire > 0.0:
		return
	burns += 1
	_cfire = 0.7
	Sfx.play("dr_rip", z.global_position, 0.0, 0.1, 2)
	z._popup("ON FIRE!", Color("ff9a3a"), 14, -120.0)
	if z.global_position.y > _floor() - 40.0:   # על הקרקע: פשוט נשרפת
		_cfire = 0.4


func _canopy_fire_tick(delta: float) -> void:
	if _cfire <= 0.0:
		return
	_cfire -= delta
	if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(z, z.global_position):
		var c: Vector2 = z.global_position + Vector2(randf_range(-CANOPY_W, CANOPY_W) * z.sc * 0.8, -CANOPY_Y * z.sc)
		Particles.burst(_main(), c, "fire", Vector2(_wind(), -1.0), 3)
		Particles.burst(_main(), c, "smoke", Vector2(_wind(), -1.0), 1)
	if _cfire <= 0.0:
		if state == FLY or state == DIVE_W or state == DIVE or state == LAUNCH:
			_rip()
			z._popup("BURNED!", Color("ff9a3a"), 15, -120.0)
		else:
			_canopy = false
			if _body != null:
				_body.collision_layer = 0


func _rip() -> void:
	if _torn:
		return
	_torn = true
	rips += 1
	state = SPIRAL
	_spin_a = 0.0
	if _body != null:
		_body.collision_layer = 0
	Sfx.play("dr_rip", z.global_position, 4.0, 0.0, 2)
	Sfx.play("dr_screech", z.global_position, 0.0, 0.1, 2)
	var m := _main()
	var n := int(m.get_meta("dr_rips", 0)) + 1
	m.set_meta("dr_rips", n)
	if n <= 3:
		z._popup("RIPPED!", Color("ffd34a"), 16, -120.0)
	if Art.on_screen(z, z.global_position):
		for i in Quality.scaled(8, 1.0):
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(z.global_position + Vector2(randf_range(-40, 40), -CANOPY_Y * z.sc), Vector2(randf_range(4, 9), randf_range(2, 5)), _c1 if i % 2 == 0 else _c2, Vector2(randf_range(-160, 160) + _wind() * 160.0, -randf_range(60, 260)))


func _crash() -> void:
	crashes += 1
	var m := _main()
	Sfx.play("dr_crash", z.global_position, 4.0, 0.08, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(m, z.global_position + Vector2(0, -4), "smoke", Vector2.UP, Quality.scaled(14, 1.0))
		for i in Quality.scaled(8, Quality.gore()):
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(z.global_position + Vector2(randf_range(-10, 10), -6), Vector2(randf_range(2, 5), randf_range(2, 5)), Color("8a6a44") if i % 2 == 0 else Color("5a4a36"), Vector2(randf_range(-220, 220), -randf_range(120, 320)))
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(7.0, 0.25)
	if crashes == 1 and int(m.get_meta("dr_crash_pop", 0)) < 3:
		m.set_meta("dr_crash_pop", int(m.get_meta("dr_crash_pop", 0)) + 1)
		z._popup("CRASHED!", Color("ffd34a"), 17, -80.0)
	z._spray_blood(z.global_position + Vector2(0, -20), Vector2(signf(z.velocity.x + 0.01), -0.8), 18, 420.0)
	z.velocity = Vector2(z.velocity.x * 0.6, -120.0)
	z.take_damage(CRASH_DMG, z.global_position + Vector2(0, -26.0 * z.sc), Vector2(signf(z.velocity.x + 0.01), -0.4), false, {"source": "crash", "fixed": CRASH_DMG, "knockback": 200.0})


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var airborne := state == FLY or state == DIVE_W or state == DIVE or state == LAUNCH
	if src.has("blast") and _canopy and not _torn and airborne:   # פיצוץ קורע את הכנף
		_rip()
	elif src.get("incendiary", false) and _canopy and not _torn:
		_ignite_canopy()
	elif airborne and _canopy:
		_swing_v += _dir.x * 2.0
	return true


func on_death() -> void:
	if _canopy:
		_drop_canopy(true)
	if _body != null:
		_body.collision_layer = 0


func _ground_under() -> float:
	var from: Vector2 = z.global_position + Vector2(0, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 900), 17)
	q.exclude = [z.get_rid()]
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	return float(hit.position.y) if hit else _floor()


func _drop_rock(pl: Node) -> void:
	rocks += 1
	var rk := Rock.new()
	rk.owner_t = self
	rk.post = randf() < 0.4
	rk.vel = Vector2(z.velocity.x * 0.6, 40.0)
	_main().add_child(rk)
	rk.global_position = z.global_position + Vector2(0, -20.0 * z.sc)
	Sfx.play("dr_whistle", z.global_position, 0.0, 0.1, 2)
	if rocks == 1 and pl != null and pl.has_method("_say") and not _main().has_meta("dr_rock_said"):
		_main().set_meta("dr_rock_said", true)
		pl._say("LOOK UP!", Color("ffd34a"))


# ============================================================
#  ציור: כנף רחיפה קרועה + זומבי תלוי ברתמה
# ============================================================
func wants_redraw() -> bool:
	return true


func _xf(angle: float) -> void:
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	var piv := Vector2(0.0, -CANOPY_Y)
	DrawBatch.set_transform_matrix(z, Transform2D(angle, Vector2(0.0, -CANOPY_Y * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO) * Transform2D(0.0, -piv))


func draw() -> bool:
	if z.dead:
		begin_draw()
		_draw_pilot(false, true)
		end_draw()
		return true
	var flying := state == FLY or state == DIVE_W or state == DIVE or state == LAUNCH or state == SPIRAL
	if flying:
		# צל על הקרקע מתחתיו (הרמז: "תסתכל למעלה")
		var hgt: float = maxf(0.0, _gy - z.global_position.y)
		var a := clampf(1.0 - hgt / 520.0, 0.15, 0.6)
		DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, hgt), 22.0 * (0.6 + hgt / 600.0), 4.0, 0.0, 14), Color(0.1, 0.06, 0.02, a * 0.5))
		var ang := _swing
		if state == SPIRAL:
			ang = sin(_spin_a) * 0.9
		elif state == DIVE:
			ang = -0.35
		_xf(ang)
		_draw_canopy()
		_draw_lines(true)
		_draw_pilot(true, false)
		end_draw()
		return true
	begin_draw()
	if state == KITE or state == PERCH:
		_draw_ground_canopy()
	_draw_pilot(false, false)
	end_draw()
	return true


# הכנף פתוחה: קשת של תאים צבעוניים, פסים, חורים, קרעים מתנופפים במורד הרוח
func _draw_canopy() -> void:
	var cy := -CANOPY_Y
	var hw := CANOPY_W * (0.55 + 0.45 * _inflate)
	var arch := 24.0 * _inflate
	var thick := 10.0 + 6.0 * _inflate
	var flap := sin(z._time * 11.0) * (1.0 + 2.5 * _gust())
	var n := 12
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / float(n) * 2.0 - 1.0
		var yy := cy - (1.0 - u * u) * arch
		var wob := sin(u * 6.0 + z._time * 8.0) * 0.8 * (1.0 if not _torn else 3.0)
		if _torn:   # מקופלת וקרועה: הצד אחד נופל
			yy += maxf(0.0, u) * 26.0 + sin(z._time * 14.0 + u * 4.0) * 4.0
		top.append(Vector2(u * hw, yy + wob))
		bot.append(Vector2(u * hw * 0.95, yy + thick * (1.0 - 0.45 * u * u) + wob + flap * (u * u)))
	var fire_k := clampf(_cfire / 0.7, 0.0, 1.0)
	var flash := _cflash > 0.0
	for i in n:   # תאים: פסים צבעוניים, באמצע פס כהה עם מספר
		var cc: Color = _c1 if (i / 2) % 2 == 0 else _c2
		if i == 5 or i == 6:
			cc = _c3
		if fire_k > 0.0:
			cc = cc.lerp(Color("2a1a10"), (1.0 - fire_k) * 0.6 + 0.2)
		if flash:
			cc = Color.WHITE
		var mid_t := top[i].lerp(bot[i], 0.62)
		var mid_t2 := top[i + 1].lerp(bot[i + 1], 0.62)
		DrawBatch.colored_polygon(z, PackedVector2Array([top[i], top[i + 1], mid_t2, mid_t]), cc)
		DrawBatch.colored_polygon(z, PackedVector2Array([mid_t, mid_t2, bot[i + 1], bot[i]]), cc.darkened(0.32))   # הצד התחתון
		DrawBatch.colored_polygon(z, PackedVector2Array([top[i], top[i + 1], top[i + 1].lerp(mid_t2, 0.3), top[i].lerp(mid_t, 0.3)]), Color(1, 1, 1, 0.22))   # ברק
	DrawBatch.polyline(z, top, Art.OUTLINE, 1.8)
	DrawBatch.polyline(z, bot, Art.OUTLINE, 1.4)
	DrawBatch.line(z, top[0], bot[0], Art.OUTLINE, 1.4)
	DrawBatch.line(z, top[n], bot[n], Art.OUTLINE, 1.4)
	for i in range(1, n):   # תפרים + פתחי התאים בשפה התחתונה
		DrawBatch.line(z, top[i], bot[i], Color(0, 0, 0, 0.3), 0.9)
		var o := bot[i].lerp(bot[i - 1], 0.5) + Vector2(0, -2.0)
		DrawBatch.colored_polygon(z, Art.ellipse(o, 2.6, 1.6, 0.0, 6), Color(0, 0, 0, 0.45))
	# חורים (רואים דרכם את השמיים)
	for h in _holes:
		var u: float = h[0]
		var i := clampi(int((u + 1.0) * 0.5 * float(n)), 0, n - 1)
		var c: Vector2 = top[i].lerp(bot[i], float(h[1]))
		var r: float = float(h[2]) * 1.3
		DrawBatch.colored_polygon(z, Art.ellipse(c, r, r * 0.6, 0.4, 8), Color("8ab8e0"))
		DrawBatch.arc(z, c, r, 0.0, TAU, 8, Color(0, 0, 0, 0.55), 1.0)
	# קרעים מתנופפים (תמיד במורד הרוח, גם כשהוא מסתכל לצד השני)
	var wl: float = _wd * z._dir
	for q in 4:
		var base: Vector2 = bot[1 + q * 3]
		var len := 12.0 + float(q % 2) * 6.0 + (16.0 if _torn else 0.0)
		var tip := base + Vector2(wl * len, 5.0 + sin(z._time * 12.0 + float(q)) * 4.0)
		DrawBatch.colored_polygon(z, PackedVector2Array([base + Vector2(-2.5, 0), base + Vector2(2.5, 0), tip]), _c1.darkened(0.15) if q % 2 == 0 else _c2)


# חוטים מהכנף לרתמה (risers)
func _draw_lines(attached: bool) -> void:
	var cy := -CANOPY_Y
	var hw := CANOPY_W * (0.55 + 0.45 * _inflate)
	var sh := Vector2(0, -46)
	var lc := Color(0.2, 0.18, 0.16, 0.8)
	for i in 9:
		var u := float(i) / 8.0 * 2.0 - 1.0
		var p := Vector2(u * hw * 0.92, cy - (1.0 - u * u) * 24.0 * _inflate + (10.0 + 6.0 * _inflate) * (1.0 - 0.45 * u * u))
		var to := sh + Vector2(-3.0 if u < 0.0 else 3.0, -4.0)
		if not attached:
			to = p + Vector2(sin(z._time * 6.0 + u) * 4.0, 24.0)
		DrawBatch.line(z, p, to, lc, 0.8)


# על הקרקע: הכנף שוכבת / מתנפחת מאחוריו (KITE), או מקופלת על הגב (PERCH)
func _draw_ground_canopy() -> void:
	var back := -1.0
	var inf := _inflate
	var cc1 := _c1 if _cflash <= 0.0 else Color.WHITE
	var cc2 := _c2 if _cflash <= 0.0 else Color.WHITE
	if state == PERCH:
		var b := Vector2(-9, -40)
		Art.fill(z, PackedVector2Array([b + Vector2(-6, -8), b + Vector2(4, -10), b + Vector2(6, 14), b + Vector2(-8, 16)]), cc1, Art.OUTLINE, 1.0)
		DrawBatch.line(z, b + Vector2(-5, 0), b + Vector2(5, -1), cc2, 2.0)
		var fl := Vector2(back * (14.0 + 10.0 * inf), -50.0 - 12.0 * inf + sin(z._time * 9.0) * 3.0)
		DrawBatch.colored_polygon(z, PackedVector2Array([b + Vector2(-4, -8), b + Vector2(0, -10), b + fl]), cc2)
		return
	# בד מתנפח מאחור: קשת שעולה ויורדת עם המשבים
	var cx := back * 34.0
	var hgt := 8.0 + inf * 46.0
	var pts := PackedVector2Array()
	var n := 9
	for i in n + 1:
		var u := float(i) / float(n)
		var x := cx + (u - 0.5) * (40.0 + 26.0 * inf)
		var y := -2.0 - sin(u * PI) * hgt + sin(z._time * 9.0 + u * 5.0) * 2.0 * inf
		pts.append(Vector2(x, y))
	var poly := pts.duplicate()
	for i in range(n, -1, -1):
		poly.append(pts[i] + Vector2(0, 6.0 + 3.0 * inf))
	DrawBatch.colored_polygon(z, poly, cc1)
	for i in range(1, n, 2):
		DrawBatch.colored_polygon(z, PackedVector2Array([pts[i], pts[i + 1], pts[i + 1] + Vector2(0, 6), pts[i] + Vector2(0, 6)]), cc2)
	DrawBatch.polyline(z, pts, Art.OUTLINE, 1.2)
	for i in [1, 4, 8]:
		DrawBatch.line(z, pts[i] + Vector2(0, 6), Vector2(-2, -42), Color(0.15, 0.13, 0.12, 0.6), 0.7)


func _draw_pilot(hanging: bool, dead: bool) -> void:
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.22))
	var jk := col(z.shirt)
	var jkd := col(Art.shade(z.shirt, 0.3))
	var hip := Vector2(0, -24)
	var sh := Vector2(1.0, -42)
	var f: Array = feet(5.0, 2.4)
	var hand_f := sh + Vector2(9.0, 9.0)
	var hand_b := sh + Vector2(-4.0, 12.0)
	if hanging:
		var sw := sin(z._time * 3.0) * 3.0
		f = [Vector2(4.0 + sw, -2.0), Vector2(-3.0 - sw, 0.0)]
		hand_f = sh + Vector2(3.0, -14.0)   # על ידיות הבלמים
		hand_b = sh + Vector2(-3.0, -13.0)
		if state == DIVE_W or state == DIVE:   # רגליים קדימה, ידיים פרושות
			f = [Vector2(14.0, -12.0), Vector2(10.0, -8.0)]
			hand_f = sh + Vector2(12.0, -4.0)
			hand_b = sh + Vector2(-8.0, -10.0)
		elif state == SPIRAL:
			f = [Vector2(9.0 + sw * 2.0, -6.0), Vector2(-8.0 - sw * 2.0, -4.0)]
			hand_f = sh + Vector2(10.0, -18.0)
			hand_b = sh + Vector2(-10.0, -16.0)
	elif state == CUT:
		f = [Vector2(4.0, 2.0), Vector2(-3.0, 3.0)]
		hand_f = sh + Vector2(10.0, -14.0)
		hand_b = sh + Vector2(-8.0, -12.0)
	elif state == KITE and not dead:
		hand_f = sh + Vector2(-2.0, -12.0)   # מחזיק את החוטים
		hand_b = sh + Vector2(-8.0, -6.0)
	elif state == LANDED and not dead:
		hand_f = sh + Vector2(8.0, 14.0)
	# רגל אחורית + יד אחורית
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), skd, col(z.shoe))
	z._arm(sh + Vector2(-3, 2), hand_b, skd, jkd)
	# רתמה (מושב) מאחורי הירכיים
	Art.fill(z, PackedVector2Array([hip + Vector2(-10, -6), hip + Vector2(4, -4), hip + Vector2(6, 6), hip + Vector2(-8, 8), hip + Vector2(-12, 2)]), col(Color("2a2a30")), Art.OUTLINE, 1.0)
	DrawBatch.line(z, hip + Vector2(-9, -4), hip + Vector2(3, -3), col(Color("e0c040")), 1.2)
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# מעיל רוח קרוע שמתנופף ברוח
	var wl: float = _wd * z._dir
	var body := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, -1), hip + Vector2(-7, 0), sh + Vector2(-9, 6)])
	Art.fill_shaded(z, body, jk, 0.15, 0.35)
	var tail := hip + Vector2(wl * (8.0 + 4.0 * absf(_wind())), -2.0 + sin(z._time * 10.0) * 2.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([hip + Vector2(-6, -6), hip + Vector2(6, -6), tail]), jkd)
	DrawBatch.line(z, sh + Vector2(-6, 1), sh + Vector2(-6, 12), col(Color("d8d0c0")), 0.8)   # רוכסן / רצועה
	DrawBatch.line(z, sh + Vector2(5, 1), hip + Vector2(4, -5), col(Color("1a1a1e")), 1.6)   # רצועת כתף
	if not dead:
		Art.oval(z, sh + Vector2(2, 10), 3.0, 2.2, Color(0.45, 0.04, 0.04, 0.6), 0.3, Art.NONE)
	# ראש: קסדה סדוקה + משקפי טיסה
	var head := sh + Vector2(3.0, -9.0)
	if not z._headless:
		z._head(head, sk)
		face(head)
		var hc := col(_helmet)
		Art.fill(z, PackedVector2Array([head + Vector2(-7, -1), head + Vector2(-6, -7), head + Vector2(0, -10), head + Vector2(6, -8), head + Vector2(8, -3), head + Vector2(2, -4), head + Vector2(-4, -2)]), hc, Art.OUTLINE, 1.0)
		DrawBatch.line(z, head + Vector2(-1, -9), head + Vector2(1, -5), Color(0, 0, 0, 0.5), 0.8)   # סדק
		DrawBatch.line(z, head + Vector2(-6, -3), head + Vector2(6, -3), col(Color("3a3030")), 1.6)   # רצועת משקפיים
		Art.disc(z, head + Vector2(4.5, -2.5), 2.2, col(Color("6a8a9a")), Art.OUTLINE, 0.8)
		if not dead:
			DrawBatch.circle(z, head + Vector2(4.8, -2.2), 0.9, Color(1.0, 0.3, 0.15))
	# יד קדמית
	z._arm(sh + Vector2(2, 2), hand_f, sk, jk)
	if hanging:   # ידיות הבלמים
		DrawBatch.line(z, hand_f, hand_f + Vector2(0, -4), col(Color("e83a2a")), 2.0)
	elif state == GROUND or state == LANDED or dead:   # חוטים חתוכים שתלויים מהרתמה
		for q in 3:
			DrawBatch.line(z, sh + Vector2(-2.0 + float(q) * 2.0, -2), sh + Vector2(-6.0 + float(q) * 3.0 - wl * 6.0, -14.0 + sin(z._time * 8.0 + float(q)) * 2.0), Color(0.15, 0.13, 0.12, 0.6), 0.6)


# ============================================================
#  סלע / עמוד גדר שהוא מפיל (עם צל שגדל על הקרקע)
# ============================================================
class Rock extends Node2D:
	const G := 900.0
	var owner_t = null
	var post := false
	var vel := Vector2.ZERO
	var ground_y := 630.0
	var _rot := 0.0
	var _spin := 0.0
	var _done := false
	var _hit := false
	var _life := 1.6

	func _ready() -> void:
		z_index = 6
		_spin = randf_range(-9.0, 9.0)
		var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 900), 17)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		ground_y = float(hit.position.y) if hit else global_position.y + 400.0

	func _physics_process(delta: float) -> void:
		if _done:
			_life -= delta
			if _life <= 0.0:
				queue_free()
			else:
				modulate.a = clampf(_life, 0.0, 1.0)
			return
		vel.y += G * delta
		vel.x = move_toward(vel.x, 0.0, 40.0 * delta)
		global_position += vel * delta
		_rot += _spin * delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and not _hit:
			var r := Rect2(global_position - Vector2(8, 8), Vector2(16, 16))
			if r.intersects(pl.body_rect()):
				_hit = true
				if pl._roll_t <= 0.0 and owner_t != null:
					owner_t.rock_hits += 1
				pl.hurt(1, Vector2(signf(vel.x + 0.01) * 0.5, 0.0))
				Particles.burst(get_parent(), global_position, "hit", Vector2.UP, 6)
		if global_position.y >= ground_y - 4.0:
			global_position.y = ground_y - 4.0
			_done = true
			Sfx.play("dr_thud", global_position, 0.0, 0.15, 3)
			if Art.on_screen(self, global_position):
				Particles.burst(get_parent(), global_position, "smoke", Vector2.UP, 5)
				for i in 4:
					var dbr = DebrisScript.new()
					get_parent().add_child(dbr)
					dbr.setup(global_position, Vector2(3, 3), Color("6a5a48"), Vector2(randf_range(-160, 160), -randf_range(80, 200)))
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if not _done:   # צל
			var hgt := maxf(0.0, ground_y - global_position.y)
			var k := clampf(1.0 - hgt / 360.0, 0.2, 1.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, hgt), 4.0 + 9.0 * k, 2.0 + 1.5 * k, 0.0, 12), Color(0.0, 0.0, 0.0, 0.25 + 0.35 * k))
		DrawBatch.set_transform(self, Vector2.ZERO, _rot if not _done else (0.0 if not post else PI * 0.5), Vector2.ONE)
		if post:
			Art.fill(self, PackedVector2Array([Vector2(-3, -15), Vector2(3, -15), Vector2(3.5, 15), Vector2(-3.5, 15)]), Color("6a4a30"), Art.OUTLINE, 1.0)
			DrawBatch.line(self, Vector2(-3, -6), Vector2(3, -6), Color("8a8e90"), 1.0)
			DrawBatch.line(self, Vector2(-3, 4), Vector2(3, 4), Color("8a8e90"), 1.0)
		else:
			Art.fill(self, PackedVector2Array([Vector2(-8, -3), Vector2(-4, -8), Vector2(5, -7), Vector2(9, -1), Vector2(6, 6), Vector2(-5, 7)]), Color("7a7064"), Art.OUTLINE, 1.0)
			DrawBatch.line(self, Vector2(-4, -5), Vector2(4, -5), Color(1, 1, 1, 0.25), 1.2)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
#  הכנף הריקה (נחת / חתך / מת): עפה ברוח, מסתובבת ונעלמת
# ============================================================
class LooseCanopy extends Node2D:
	var c1 := Color("ff6a2a")
	var c2 := Color("f0d040")
	var c3 := Color("2a3a6a")
	var torn := false
	var holes: Array = []
	var k := 1.0
	var vel := Vector2.ZERO
	var stage: Node = null
	var _t := 0.0
	var _rot := 0.0
	var _life := 4.0

	func _ready() -> void:
		z_index = 5

	func _process(delta: float) -> void:
		_t += delta
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		var w := -0.4
		if stage != null and is_instance_valid(stage) and stage.has_method("wind"):
			w = float(stage.wind())
		vel.x = move_toward(vel.x, w * 230.0, 120.0 * delta)
		vel.y = move_toward(vel.y, (40.0 if torn else -30.0) + sin(_t * 2.0) * 40.0, 80.0 * delta)
		global_position += vel * delta
		_rot = sin(_t * 1.7) * 0.5 + _t * 0.3 * signf(w)
		modulate.a = clampf(_life, 0.0, 1.0)
		if Art.on_screen(self, global_position, 200.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.set_transform(self, Vector2.ZERO, _rot, Vector2(k, k))
		var n := 8
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		for i in n + 1:
			var u := float(i) / float(n) * 2.0 - 1.0
			var yy := -(1.0 - u * u) * 10.0 + sin(_t * 9.0 + u * 5.0) * 2.5
			if torn:
				yy += maxf(0.0, u) * 14.0
			top.append(Vector2(u * 46.0, yy))
			bot.append(Vector2(u * 44.0, yy + 9.0 - 3.0 * u * u))
		for i in n:
			DrawBatch.colored_polygon(self, PackedVector2Array([top[i], top[i + 1], bot[i + 1], bot[i]]), c1 if i % 2 == 0 else (c3 if i == 3 or i == 4 else c2))
		DrawBatch.polyline(self, top, Art.OUTLINE, 1.2)
		DrawBatch.polyline(self, bot, Art.OUTLINE, 1.0)
		for h in holes:
			var i := clampi(int((float(h[0]) + 1.0) * 0.5 * float(n)), 0, n - 1)
			DrawBatch.colored_polygon(self, Art.ellipse(top[i].lerp(bot[i], float(h[1])), float(h[2]), float(h[2]) * 0.6, 0.0, 8), Color("8ab8e0"))
		for i in 6:   # חוטים תלויים
			var u := float(i) / 5.0 * 2.0 - 1.0
			var p := Vector2(u * 40.0, bot[clampi(int((u + 1.0) * 0.5 * float(n)), 0, n)].y)
			DrawBatch.line(self, p, p + Vector2(sin(_t * 5.0 + u * 3.0) * 6.0, 26.0 + absf(u) * 4.0), Color(0.15, 0.13, 0.12, 0.6), 0.7)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
