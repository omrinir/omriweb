extends "res://enemies/zombie_type.gd"
# ============================================================
#  ASHMOTH (שלב 59, "BLACK FOREST") - עש של אפר: גוף אדם חרוך ומכווץ (ראש, ידיים תלויות, רגליים נגררות) תלוי בין
#    שתי כנפיים ענקיות של קליפת עץ ועור שרוף - אפור-חום עם עורקי אפר, שוליים לוחשים ו"עיניים" של גחלים על הכנפיים.
#    מחושים נוצתיים, בטן לוחשת בכתום (נקודת התורפה). עף בזיג-זג עצבני של עש - אף פעם לא בקו ישר.
#  מה הם למדו: "THEY FOLLOW YOUR GUNFIRE NOW". בעשן הם לא רואים כלום - אבל כל מי שמת בעשן ראה את אותו הדבר האחרון:
#    הבזק הקנה שלך. עכשיו הם עפים אל ההבזק כמו עש אל מנורה.
#  מחזור:
#    ROOST   - יושב (על גג / במה / קרקע) עם כנפיים מקופלות שנפתחות לאט. הבזק בטווח WAKE_R או אתה קרוב (NEAR_R) -> ממריא.
#    FLUTTER - אין לו הבזק: מרפרף בגובה HOVER, נמשך לקו אש שבוער (FireLine) - ושם הכנפיים עלולות להידלק.
#    HOME    - עף אל ההבזק האחרון שראה (לא אליך!), בזיג-זג (ZIG). כל ירייה נוספת מעדכנת את היעד.
#              הגיע ליעד ואתה קרוב (STRIKE_R) -> STRIKE_W (נעצר, כנפיים לאחור) -> STRIKE: נזרק עליך (DIVE_V) -
#              DMG + אפר בעיניים (player.daze: איטי + כוונת רועדת). אחרי מכה: RECOIL (מתרחק למעלה) וחוזר.
#              הגיע ליעד ואתה לא שם (הפסקת לירות וזזת) -> SEARCH (מחפש סביב הנקודה SEARCH_T) -> LOST ("LOST YOU") -> FLUTTER.
#  נגד: להפסיק לירות ולזוז (הוא מאבד אותך), חץ / בקבוק / להביור (בלי הבזק), לירות בכנפיים (WING_HP כל אחת - נקרעת:
#    SPIRAL -> מתרסק ומת), לירות בבטן הלוחשת (x GLOW_MULT), אש = הכנפיים נדלקות ("MOTH TO A FLAME"), פיצוץ קורע את שתיהן.
#  "THEY WAIT WHERE YOU FIRED" (main meta "am_lost" >= LEARN): אחרי שאיבדו אותך LEARN פעמים, הבאים לא מוותרים:
#    מקיפים את נקודת ההבזק האחרונה (CIRCLE, CIRCLE_R) - והירייה הבאה בטווח CIRCLE_DIVE = צלילה מיידית בלי לחפש.
#    והשלב שולח אותם בזוגות.
#  צלילים: "am_flutter", "am_screech", "am_tear", "am_crash", "am_ignite", "am_puff" (מסונתזים).
#  לשנות: HOVER, FLY_V, HOME_V, ZIG, SENSE_R, WAKE_R, NEAR_R, STRIKE_R, STRIKE_WIND, DIVE_V, DMG, DAZE_T, SEARCH_T, WING_HP,
#    GLOW_MULT, CRASH_DMG, LEARN, CIRCLE_R, CIRCLE_DIVE, FIRE_PULL.
# ============================================================

const SOUNDS := {
	"am_flutter": {"drive": 1.2, "layers": [["N", 0, 0, 0.0, 0.35, 0.02, 4.0, 0.35, 0.35, 0.6, 0.05], ["B", 22.0, 16.0, 0.0, 0.35, 0.0, 4.0, 0.2, 1.0, 0, 0, 34.0]]},
	"am_screech": {"drive": 2.2, "layers": [["V", 620, 1300, 0.0, 0.32, 0.01, 6.0, 0.6, 1.0, 0.1, 0, [1100, 2600, 60]], ["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.25, 0.8, 0, 0.4]]},
	"am_tear": [["N", 0, 0, 0.0, 0.22, 0.0, 11.0, 0.7, 0.8, 0.7, 0.4], ["C", 0, 0, 0.0, 0.15, 0.0, 20.0, 0.5, 1.0, 0]],
	"am_crash": {"drive": 2.2, "layers": [["N", 0, 0, 0.0, 0.4, 0.0, 7.0, 0.8, 0.15, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 7.0, 0.8, 1.0, 0], ["S", 90, 40, 0.0, 0.3, 0.0, 8.0, 0.6, 1.0, 0]]},
	"am_ignite": [["N", 0, 0, 0.0, 0.6, 0.02, 3.5, 0.7, 0.3, 0, 0.1], ["C", 0, 0, 0.0, 0.6, 0.0, 4.0, 0.7, 1.0, 0]],
	"am_puff": [["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.5, 0.25, 0, 0.3]],
}

const Decor := preload("res://effects/s59_decor.gd")
const CharredT := preload("res://enemies/types/charred.gd")

const HOVER := 210.0              # גובה רפרוף מעל הקרקע
const FLY_V := 120.0
const HOME_V := 215.0
const ZIG := 70.0                 # עוצמת הזיג-זג
const SENSE_R := 1050.0           # מאיזה מרחק הוא רואה הבזק
const WAKE_R := 720.0
const NEAR_R := 200.0
const STRIKE_R := 130.0
const STRIKE_WIND := 0.38
const DIVE_V := 430.0
const DMG := 1
const DAZE_T := 1.0
const SEARCH_T := 2.4
const WING_HP := 14
const GLOW_MULT := 1.8
const CRASH_DMG := 80
const LEARN := 3
const CIRCLE_R := 95.0
const CIRCLE_T := 14.0
const CIRCLE_DIVE := 620.0
const FIRE_PULL := 900.0          # קו אש שבוער בטווח הזה מושך אותו כשאין הבזק
const BODY_Y := 34.0              # מרכז הגוף מעל נקודת הבסיס (יחידות ציור)

enum { ROOST, TAKEOFF, FLUTTER, HOME, STRIKE_W, STRIKE, RECOIL, SEARCH, CIRCLE, SPIRAL, DOWN }

# לבדיקות
var flashes_seen := 0
var homes := 0
var strikes := 0
var strike_hits := 0
var losts := 0
var circles := 0
var wing_hits := 0
var tears := 0
var ignites := 0
var crashes := 0
var fire_visits := 0

var state := ROOST
var _first := true
var _t := 0.0
var _cd := 0.0
var _shot_seen := -1
var _target := Vector2.ZERO
var _home := Vector2.ZERO
var _flash_at := Vector2.ZERO
var _has_flash := false
var _hit_done := false
var _wing := [WING_HP, WING_HP]   # [שמאל, ימין] במסך
var _holes: Array = [[], []]
var _wfire := 0.0
var _flap := 0.0
var _flap_k := 0.2               # 0 מקופל .. 1 פתוח
var _jit := Vector2.ZERO
var _jit_t := 0.0
var _orb := 0.0
var _sound_t := 0.0
var _spin := 0.0
var _gy := 630.0
var _wflash := 0.0
var _hurt_side := 0
var _body: StaticBody2D = null
var _tone := Color("5a4a3e")
var _tone2 := Color("8a7a6a")
var _learned := false


class WingBody extends StaticBody2D:
	var owner_t = null
	func take_damage(_a, p: Vector2, d: Vector2, _e := false, s := {}) -> void:
		if owner_t != null:
			owner_t.wing_hit(p, d, s)


func stats() -> Dictionary:
	return {"name": "ASHMOTH", "hp": 18, "walk": 40.0, "chase": 80.0, "damage": 1, "bite_delay": 0.8, "scale": 0.92, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("2e2826"), "shirt": Color("2a2422"), "pants": Color("221e1c"), "shoe": Color("141210"),
		"points": 420, "ragdoll": false}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return state == ROOST


func death_sound() -> String:
	return "am_screech"


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func _floor() -> float:
	var st := _stage()
	return float(st.floor_y) if st != null else 630.0


static func is_learned(m: Node) -> bool:
	return m != null and int(m.get_meta("am_lost", 0)) >= LEARN


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 5 + 1
	_tone = [Color("5a4a3e"), Color("4a4440"), Color("6a5440"), Color("3e3632")][r.randi() % 4]
	_tone2 = _tone.lightened(0.3)
	_learned = is_learned(_main())
	# הגוף הקטן = הזומבי (בטן לוחשת). הכנפיים = גוף נפרד
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(16.0 * z.sc, 26.0 * z.sc)
	z._shape.position = Vector2(0.0, -BODY_Y * z.sc)
	_body = WingBody.new()
	_body.owner_t = self
	_body.collision_layer = 4
	_body.collision_mask = 0
	_body.add_to_group("no_outline")
	for s in [-1.0, 1.0]:
		var cs := CollisionShape2D.new()
		var ws := RectangleShape2D.new()
		ws.size = Vector2(34.0 * z.sc, 30.0 * z.sc)
		cs.shape = ws
		cs.position = Vector2(s * 26.0 * z.sc, -(BODY_Y + 6.0) * z.sc)
		_body.add_child(cs)
	z.add_child(_body)
	_flap = randf() * TAU
	_shot_seen = Game.shot_id


func _init_state() -> void:
	if z.has_meta("am_fly"):
		state = FLUTTER
		_flap_k = 1.0
		_home = z.global_position
		z.collision_mask = 0
	else:
		state = ROOST
		_flap_k = 0.15
		z.collision_mask = 1 | 16


func flying() -> bool:
	return state == TAKEOFF or state == FLUTTER or state == HOME or state == STRIKE_W or state == STRIKE or state == RECOIL or state == SEARCH or state == CIRCLE


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	if _first:
		_first = false
		_init_state()
	_t -= delta
	_cd -= delta
	_jit_t -= delta
	_sound_t -= delta
	_wflash = maxf(0.0, _wflash - delta)
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position + Vector2(0, -30) - _center()) if has else Vector2(9999, 0)
	_flap += delta * (4.0 if state == ROOST else (26.0 if state == STRIKE_W or state == STRIKE else 17.0))
	_sense_flash(pl, has)
	_wing_fire_tick(delta)
	if _jit_t <= 0.0:
		_jit_t = randf_range(0.18, 0.4)
		_jit = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	match state:
		ROOST:
			_roost(pl, has, d, delta)
		TAKEOFF:
			_flap_k = move_toward(_flap_k, 1.0, delta * 3.0)
			z.velocity = z.velocity.move_toward(Vector2(z._dir * 40.0, -160.0), 600.0 * delta)
			if _t <= 0.0:
				state = HOME if _has_flash else FLUTTER
				_home = z.global_position
		FLUTTER:
			_flutter(pl, has, d, delta)
		HOME:
			_homing(pl, has, d, delta)
		STRIKE_W:
			z.velocity = z.velocity.move_toward(-d.normalized() * 40.0, 900.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				_target = pl.global_position + Vector2(0, -34) + pl.velocity * 0.15
			if _t <= 0.0:
				state = STRIKE
				_t = 0.7
				_hit_done = false
				strikes += 1
				Sfx.play("am_screech", z.global_position, 0.0, 0.15, 2)
		STRIKE:
			var dv: Vector2 = (_target - _center()).normalized()
			z.velocity = z.velocity.move_toward(dv * DIVE_V, 2400.0 * delta)
			_check_hit(pl, has)
			if _t <= 0.0 or _center().distance_to(_target) < 14.0:
				_recoil()
		RECOIL:
			z.velocity = z.velocity.move_toward(Vector2(-z._dir * 120.0, -150.0), 700.0 * delta)
			if _t <= 0.0:
				if _has_flash:
					state = HOME
				else:
					_start_search()
		SEARCH:
			_search(pl, has, d, delta)
		CIRCLE:
			_circle(pl, has, d, delta)
		SPIRAL:
			_spin += delta * 9.0
			_flap_k = move_toward(_flap_k, 0.3, delta)
			z.velocity.x = move_toward(z.velocity.x, cos(_spin) * 130.0, 600.0 * delta)
			z.velocity.y = move_toward(z.velocity.y, 360.0, 500.0 * delta)
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
				CharredT.Cinders.spray(_main(), _center(), Vector2.UP, 2, _gy, 0.8, _tone)
			if z.global_position.y >= _gy - 2.0 or z.is_on_floor():
				_crash()
				return true
		DOWN:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
	if flying():
		# אף פעם לא מתחת לקרקע / מעבר לקצוות
		var fy := _floor()
		if z.global_position.y > fy - 24.0 and z.velocity.y > 0.0:
			z.velocity.y = -60.0
		if z.global_position.y < 60.0 and z.velocity.y < 0.0:
			z.velocity.y = 40.0
		if z.global_position.x < 30.0:
			z.velocity.x = absf(z.velocity.x)
		if _sound_t <= 0.0 and Art.on_screen(z, z.global_position):
			_sound_t = randf_range(0.5, 0.9)
			Sfx.play("am_flutter", z.global_position, -10.0, 0.2, 3)
	if state == SPIRAL:
		_gy = _floor()
	z.move_and_slide()
	return true


func _center() -> Vector2:
	return z.global_position + Vector2(0, -BODY_Y * z.sc)


# כל ירייה עם הבזק בטווח = יעד חדש
func _sense_flash(pl: Node, has: bool) -> void:
	if Game.shot_id == _shot_seen:
		return
	_shot_seen = Game.shot_id
	if not has or float(pl._muzzle_flash) <= 0.0:
		return
	var a: Vector2 = pl._aim.normalized() if pl._aim != Vector2.ZERO else Vector2.RIGHT
	var fp: Vector2 = pl.global_position + Vector2(0, -36) + a * 30.0
	var dist := fp.distance_to(_center())
	if dist > SENSE_R:
		return
	flashes_seen += 1
	_flash_at = fp
	_has_flash = true
	match state:
		ROOST:
			if dist < WAKE_R:
				_takeoff()
		FLUTTER, SEARCH:
			_start_home()
		CIRCLE:
			if dist < CIRCLE_DIVE:   # למד: חיכה כאן - צלילה מיידית
				state = STRIKE_W
				_t = STRIKE_WIND * 0.6
				Sfx.play("am_screech", z.global_position, 2.0, 0.1, 2)
			else:
				_start_home()


func _roost(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.velocity.x = move_toward(z.velocity.x, 0.0, 400.0 * delta)
	_flap_k = 0.15 + 0.12 * (0.5 + 0.5 * sin(z._time * 1.3))
	if has and d.length() < NEAR_R:
		_takeoff()


func _takeoff() -> void:
	state = TAKEOFF
	_t = 0.5
	z.collision_mask = 0
	z.velocity = Vector2(0.0, -120.0)
	Sfx.play("am_flutter", z.global_position, -2.0, 0.1, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -6), "smoke", Vector2.UP, 4)


func _start_home() -> void:
	if state != HOME:
		homes += 1
	state = HOME
	_t = 6.0


func _flutter(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_flap_k = move_toward(_flap_k, 1.0, delta * 2.0)
	var goal := _home + Vector2(sin(z._time * 0.7) * 120.0, -sin(z._time * 1.1) * 30.0)
	goal.y = minf(goal.y, _floor() - HOVER)
	# עש אל הלהבה: קו אש שבוער קרוב מושך אותו
	var best: Node2D = null
	var bd := FIRE_PULL
	for f in z.get_tree().get_nodes_in_group("s59_fires"):
		if float(f.heat()) < 0.5:
			continue
		var dd: float = f.glow_pos().distance_to(_center())
		if dd < bd:
			bd = dd
			best = f
	if best != null:
		goal = best.glow_pos() + Vector2(sin(z._time * 2.0) * 30.0, -10.0 + sin(z._time * 3.1) * 14.0)
		if bd < 40.0 and best.flaring():
			fire_visits += 1
			_ignite_wings()
	elif has and d.length() < NEAR_R * 0.6:   # נתקל בך בלי הבזק (צמוד מאוד)
		_flash_at = pl.global_position + Vector2(0, -30)
		_has_flash = true
		_start_home()
		return
	var to := goal - _center()
	var v := to.normalized() * minf(FLY_V, to.length() * 2.0) + _jit * ZIG * 0.7
	z.velocity = z.velocity.move_toward(v, 400.0 * delta)
	z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir


func _homing(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_flap_k = 1.0
	var thick := false
	var st := _stage()
	if st != null and st.has_method("smoke_k"):
		thick = float(st.smoke_k()) > 0.6
	var to := _flash_at - _center()
	var dist := to.length()
	var fwd := to.normalized()
	var side := Vector2(-fwd.y, fwd.x)
	var zig := sin(z._time * 9.0) * ZIG + _jit.x * ZIG * 0.6   # זיג-זג של עש
	var v := fwd * HOME_V * (1.2 if thick else 1.0) * clampf(dist / 80.0, 0.35, 1.0) + side * zig * clampf(dist / 120.0, 0.2, 1.0)
	z.velocity = z.velocity.move_toward(v, 900.0 * delta)
	z._dir = signf(to.x) if absf(to.x) > 6.0 else z._dir
	if has and d.length() < STRIKE_R and _cd <= 0.0:   # אתה ליד ההבזק: מכה
		state = STRIKE_W
		_t = STRIKE_WIND
		return
	if dist < 36.0 or _t <= 0.0:   # הגיע להבזק ואתה לא שם
		if has and d.length() < STRIKE_R * 1.4 and _cd <= 0.0:
			state = STRIKE_W
			_t = STRIKE_WIND
		else:
			_start_search()


func _check_hit(pl: Node, has: bool) -> void:
	if _hit_done or not has:
		return
	var me := Rect2(_center() - Vector2(14, 14) * z.sc, Vector2(28, 28) * z.sc)
	if me.intersects(pl.body_rect()):
		_hit_done = true
		if pl._roll_t <= 0.0:
			strike_hits += 1
			if pl.has_method("daze"):
				pl.daze(DAZE_T, "ASH IN YOUR EYES")
		pl.hurt(DMG, Vector2(signf(z.velocity.x + 0.01) * 0.8, -0.3))
		Sfx.play("am_puff", z.global_position, 2.0, 0.1, 2)
		if Art.on_screen(z, z.global_position):
			Particles.burst(_main(), _center(), "smoke", Vector2.UP, 5)
			CharredT.Cinders.spray(_main(), _center(), Vector2.UP, 5, pl.global_position.y, 0.6, Color(0.6, 0.58, 0.55))
		_recoil()


func _recoil() -> void:
	state = RECOIL
	_t = 0.6
	_cd = 1.1


func _start_search() -> void:
	state = SEARCH
	_t = SEARCH_T
	_has_flash = false


func _search(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_orb += delta * 3.2
	var goal := _flash_at + Vector2(cos(_orb) * 70.0, sin(_orb * 1.3) * 30.0 - 20.0)
	var to := goal - _center()
	z.velocity = z.velocity.move_toward(to.normalized() * minf(FLY_V, to.length() * 3.0) + _jit * ZIG * 0.5, 600.0 * delta)
	z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir
	if has and d.length() < NEAR_R * 0.5 and _cd <= 0.0:   # נתקל בך
		state = STRIKE_W
		_t = STRIKE_WIND
		return
	if _t > 0.0:
		return
	if _learned:   # למד: לא מוותר - מקיף את המקום שירית ממנו
		state = CIRCLE
		_t = CIRCLE_T
		circles += 1
		var m := _main()
		if m != null and not m.has_meta("am_told_wait"):
			m.set_meta("am_told_wait", true)
			z._popup("THEY WAIT WHERE YOU FIRED", Color("ff9a4a"), 15, -70.0)
			if pl != null and pl.has_method("_say"):
				pl._say("It's circling where I shot from... don't fire from the same spot.", Color("f0c890"))
		return
	_lost(pl)


func _lost(pl: Node) -> void:
	losts += 1
	state = FLUTTER
	_home = _center()
	var m := _main()
	if m == null:
		return
	var n := int(m.get_meta("am_lost", 0)) + 1
	m.set_meta("am_lost", n)
	if n <= 2:
		z._popup("LOST YOU", Color("b2aca4"), 13, -70.0)
	if n == 1 and pl != null and pl.has_method("_say"):
		pl._say("It lost me... it only sees the flash.", Color("f0c890"))


func _circle(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_orb += delta * 2.4
	var goal := _flash_at + Vector2(cos(_orb) * CIRCLE_R, sin(_orb) * CIRCLE_R * 0.45 - 30.0)
	var to := goal - _center()
	z.velocity = z.velocity.move_toward(to.normalized() * minf(FLY_V * 1.2, to.length() * 3.0) + _jit * ZIG * 0.3, 700.0 * delta)
	z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir
	if has and d.length() < NEAR_R * 0.6 and _cd <= 0.0:
		state = STRIKE_W
		_t = STRIKE_WIND
		return
	if _t <= 0.0:
		state = FLUTTER
		_home = _center()


# ============================================================
#  כנפיים: פגיעות, קריעה, אש
# ============================================================
func wing_hit(p: Vector2, d: Vector2, src: Dictionary) -> void:
	if z.dead or state == SPIRAL or state == DOWN:
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
	wing_hits += 1
	_wflash = 0.07
	var side := 0 if p.x < _center().x else 1
	_hurt_side = side
	Game.on_zombie_hit({"source": "bullet", "zone": "wing", "shot": src.get("shot", 0)})
	var lx: float = absf(p.x - _center().x) / (52.0 * z.sc)
	if _holes[side].size() < 5:
		_holes[side].append(Vector2(clampf(lx, 0.15, 0.95), randf_range(-0.6, 0.6)))
	if Art.on_screen(z, p):
		CharredT.Cinders.spray(_main(), p, Vector2(d.x, -0.4), 4, _floor(), 0.6, _tone2)
		Particles.burst(_main(), p, "spark", d, 2)
	Sfx.play("am_tear", p, -6.0, 0.2, 3)
	z.velocity += d * 60.0
	if state == ROOST:
		_takeoff()
	if src.get("incendiary", false):
		_ignite_wings()
		return
	_wing[side] -= dmg
	if _wing[side] <= 0:
		_tear(side)


func _ignite_wings() -> void:
	if _wfire > 0.0 or state == SPIRAL:
		return
	ignites += 1
	_wfire = 0.8
	Sfx.play("am_ignite", z.global_position, 0.0, 0.1, 2)
	z._popup("MOTH TO A FLAME", Color("ffb050"), 14, -70.0)


func _wing_fire_tick(delta: float) -> void:
	if z._burn_t > 0.0 and _wfire <= 0.0 and flying():   # בוער (קו אש / קליע אש) - הכנפיים נדלקות
		_ignite_wings()
	if _wfire <= 0.0:
		return
	_wfire -= delta
	if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(z, z.global_position):
		var c := _center() + Vector2(randf_range(-40.0, 40.0) * z.sc, randf_range(-14.0, 6.0))
		Particles.burst(_main(), c, "fire", Vector2.UP, 2)
	if _wfire <= 0.0:
		_tear(-1)
		z._popup("BURNED!", Color("ffb050"), 14, -70.0)


# side = -1: שתי הכנפיים
func _tear(side: int) -> void:
	if state == SPIRAL or state == DOWN:
		return
	tears += 1
	if side < 0:
		_wing = [0, 0]
	else:
		_wing[side] = 0
	var on := Art.on_screen(z, z.global_position)
	Sfx.play("am_tear", z.global_position, 2.0, 0.0, 2)
	if on:
		CharredT.Cinders.spray(_main(), _center(), Vector2.UP, 14, _floor(), 0.9, _tone2)
		for i in Quality.scaled(4, 1.0):
			var dbr = CharredT.DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(_center() + Vector2(randf_range(-30, 30), randf_range(-10, 10)), Vector2(randf_range(5, 10), randf_range(3, 6)), _tone, Vector2(randf_range(-150, 150), -randf_range(40, 200)))
	if not flying() and state != TAKEOFF:   # על הקרקע: נשאר זוחל על הקרקע (DOWN) - חלש
		state = DOWN
		z.collision_mask = 1 | 16
		return
	state = SPIRAL
	_spin = 0.0
	if _body != null:
		_body.collision_layer = 0
	z._popup("WING TORN" if side >= 0 else "WINGS BURNED", Color("ffd34a"), 14, -70.0)


func _crash() -> void:
	crashes += 1
	state = DOWN
	z.collision_mask = 1 | 16
	Sfx.play("am_crash", z.global_position, 2.0, 0.1, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -4), "smoke", Vector2.UP, Quality.scaled(8, 1.0))
		CharredT.Cinders.spray(_main(), z.global_position + Vector2(0, -8), Vector2.UP, 14, z.global_position.y, 0.8, _tone)
	z._spray_blood(z.global_position + Vector2(0, -12), Vector2(0, -1), 10, 300.0)
	z.take_damage(CRASH_DMG, _center(), Vector2(0, 1), false, {"source": "crash", "fixed": CRASH_DMG, "knockback": 120.0})


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	if src.has("blast") and flying():   # פיצוץ קורע את שתי הכנפיים
		_tear(-1)
	elif src.get("incendiary", false) and flying():
		_ignite_wings()
	if state == ROOST:
		_takeoff()
	if flying():
		z.velocity += _dir * 80.0
	return true


# הבטן הלוחשת: כל פגיעה בגוף = x GLOW_MULT
func damage_mult(_zone: String, src: Dictionary) -> float:
	var s := str(src.get("source", "bullet"))
	return GLOW_MULT if s == "bullet" or s == "melee" else 1.0


func on_death() -> void:
	if _body != null:
		_body.collision_layer = 0
	z.collision_mask = 1 | 16
	if Art.on_screen(z, z.global_position):
		CharredT.Cinders.spray(_main(), _center(), Vector2.UP, 16, _floor(), 0.9, _tone2)
		CharredT.Cinders.spray(_main(), _center(), Vector2.UP, 8, _floor(), 0.7)
		Particles.burst(_main(), _center(), "smoke", Vector2.UP, 5)


# ============================================================
#  ציור: עש ענק של אפר עם גוף אדם חרוך תלוי באמצע (חזית)
# ============================================================
func wants_redraw() -> bool:
	return true


# מת כשהכנף בוערת: הלהבה על הגופה ממשיכה להבהב (כל גופה אחרת נעצרת - zombie_type.gd corpse_anim)
func corpse_anim() -> bool:
	return _wfire > 0.0


func draw() -> bool:
	var dead: bool = z.dead
	var down := dead or state == DOWN or state == SPIRAL
	var ground := state == ROOST or state == DOWN or dead
	# צל על הקרקע (רמז: "משהו מעליך")
	if flying() and not dead:
		var hgt: float = maxf(0.0, _floor() - z.global_position.y)
		var a := clampf(1.0 - hgt / 420.0, 0.1, 0.5)
		DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, hgt), 26.0 * (0.6 + hgt / 600.0), 4.0, 0.0, 12), Color(0.05, 0.03, 0.02, a * 0.5))
	var s := Vector2(z._dir * z.sc, z.sc)
	var rot := 0.0
	if state == SPIRAL:
		rot = sin(_spin) * 0.8
	elif state == STRIKE:
		rot = 0.35
	elif flying():
		rot = clampf(z.velocity.x * 0.0012 * z._dir, -0.3, 0.3)
	var cy := -BODY_Y
	if dead or state == DOWN:
		cy = -8.0
		rot = 1.3 if dead else 0.0
	DrawBatch.set_transform_matrix(z, Transform2D(rot, Vector2(0.0, cy * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO))
	var t: float = z._time
	var open := _flap_k
	if ground and not flying():
		open = _flap_k
	var beat := sin(_flap) if not ground else 0.2 * sin(_flap)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	# כנפיים (מאחורי הגוף)
	for side in 2:
		var sx := -1.0 if side == 0 else 1.0
		if _wing[side] <= 0 and not dead:
			_wing_stub(sx)
			continue
		_wing_draw(pts, cols, sx, open, beat, side)
	if not pts.is_empty():
		DrawBatch.tris(z, pts, cols)
	# הגוף: גו אדם חרוך קטן, בטן לוחשת
	var cc := col(Color("2a2422"))
	var gl := 0.6 + 0.3 * sin(t * 6.0) + (0.4 if state == STRIKE_W else 0.0)
	# רגליים נגררות
	var lg := 3.0 * sin(t * 4.0)
	Art.limb(z, PackedVector2Array([Vector2(-2, 8), Vector2(-3 + lg * 0.3, 16), Vector2(-2 + lg, 23)]), 2.4, col(Color("1e1a18")))
	Art.limb(z, PackedVector2Array([Vector2(2, 8), Vector2(3 - lg * 0.3, 16), Vector2(2 - lg, 22)]), 2.4, col(Color("221e1c")))
	# בטן לוחשת (נקודת התורפה)
	DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, 6), 5.0, 7.5, 0.0, 12), cc)
	for q in 3:
		DrawBatch.line(z, Vector2(-4.0, 2.0 + float(q) * 3.5), Vector2(4.0, 2.0 + float(q) * 3.5), Color(1.0, 0.45 + 0.2 * gl, 0.1, 0.8 * gl if not dead else 0.2), 1.3)
	if not dead:
		Art.glow(z, Vector2(0, 6), 9.0, Color(1.0, 0.5, 0.15, 0.4 * gl))
	# חזה + ידיים תלויות
	Art.fill_shaded(z, PackedVector2Array([Vector2(-6, -8), Vector2(6, -8), Vector2(5, 2), Vector2(-5, 2)]), cc, 0.1, 0.3)
	var ah := 2.0 * sin(t * 5.0)
	var reach := 1.0 if state == STRIKE or state == STRIKE_W else 0.0
	Art.limb(z, PackedVector2Array([Vector2(-5, -6), Vector2(-8, 0 - reach * 6.0), Vector2(-7 + ah, 7 - reach * 14.0)]), 2.2, col(Color("221e1c")))
	Art.limb(z, PackedVector2Array([Vector2(5, -6), Vector2(8, 0 - reach * 6.0), Vector2(7 - ah, 7 - reach * 14.0)]), 2.2, col(Color("221e1c")))
	# ראש: גולגולת חרוכה, עיני גחלים, מחושים נוצתיים
	var hc := Vector2(0, -13)
	Art.oval_shaded(z, hc, 4.2, 4.6, col(Color("2e2826")), 0.0)
	if not dead:
		DrawBatch.circle(z, hc + Vector2(-1.6, -0.5), 0.9, Color(1.0, 0.55, 0.15))
		DrawBatch.circle(z, hc + Vector2(1.6, -0.5), 0.9, Color(1.0, 0.55, 0.15))
		Art.glow(z, hc, 4.0, Color(1.0, 0.5, 0.15, 0.35))
	DrawBatch.line(z, hc + Vector2(-1.5, 2.2), hc + Vector2(1.5, 2.2), Color(0.9, 0.4, 0.1, 0.7), 0.8)
	for sx in [-1.0, 1.0]:
		var tip := hc + Vector2(sx * 9.0, -9.0 + sin(t * 3.0 + sx) * 1.5)
		DrawBatch.line(z, hc + Vector2(sx * 1.5, -3.5), tip, col(Color("4a3e34")), 0.9)
		for q in 4:   # נוצות המחוש
			var p := (hc + Vector2(sx * 1.5, -3.5)).lerp(tip, 0.3 + float(q) * 0.18)
			DrawBatch.line(z, p, p + Vector2(sx * 1.8, -1.6), col(Color("6a5a4a")), 0.6)
	if _wflash > 0.0 or (_wfire > 0.0 and not dead):
		Art.glow(z, Vector2(0, -2), 20.0, Color(1.0, 0.6, 0.2, 0.5))
	end_draw()
	return true


# כנף: כנף קדמית + אחורית, קליפת עץ ועור שרוף, עורקים, "עין" לוחשת, שוליים לוחשים, חורים
func _wing_draw(pts: PackedVector2Array, cols: PackedColorArray, sx: float, open: float, beat: float, side: int) -> void:
	var span := 46.0 * (0.35 + 0.65 * open)
	var lift := beat * 18.0 * open
	var root := Vector2(sx * 3.0, -4.0)
	var tip := root + Vector2(sx * span, -14.0 - lift)
	var rear := root + Vector2(sx * span * 0.7, 14.0 - lift * 0.4)
	var low := root + Vector2(sx * 5.0, 12.0)
	var base := col(_tone)
	if z._flash > 0.0 or (_wflash > 0.0 and side == _hurt_side):
		base = Color(1, 1, 1)
	var dark := Color(base.darkened(0.45), base.a)
	var hurt: float = 1.0 - float(_wing[side]) / float(WING_HP)
	var ember := Color(1.0, 0.45, 0.1, 0.55 + 0.35 * hurt)
	if _wfire > 0.0:
		ember = Color(1.0, 0.7, 0.2, 0.95)
		base = base.lerp(Color(0.9, 0.35, 0.08), 0.5)
	# כנף קדמית (משולשים עם שיפוע)
	var fm := root.lerp(tip, 0.55) + Vector2(0, -8.0)
	pts.append_array([root, fm, tip, root, tip, rear])
	cols.append_array([dark, base, ember, dark, ember, base])
	# כנף אחורית
	var hm := root.lerp(rear, 0.6) + Vector2(sx * 6.0, 8.0)
	pts.append_array([root, rear, hm, root, hm, low])
	cols.append_array([dark, base, Color(ember, 0.5), dark, base, dark])
	# עורקי אפר
	for q in 3:
		var e := tip.lerp(rear, float(q) / 2.5)
		var n := Vector2(-(e - root).normalized().y, (e - root).normalized().x) * 0.5
		pts.append_array([root + n, e + n, e - n, root + n, e - n, root - n])
		var vc := col(_tone2)
		vc.a = 0.6
		cols.append_array([vc, vc, vc, vc, vc, vc])
	# "עין" של גחל על הכנף
	var eye := root.lerp(tip, 0.55).lerp(rear, 0.3)
	Decor.U.oval(pts, cols, eye, 5.5, 4.0, Color(0.1, 0.06, 0.04, 0.9), 8)
	Decor.U.oval(pts, cols, eye, 3.2, 2.4, Color(1.0, 0.5 + 0.2 * sin(z._time * 4.0), 0.12, 0.9), 8)
	# חורים (פגיעות)
	for h in _holes[side]:
		var hv: Vector2 = h
		var hp := root.lerp(tip, hv.x) + Vector2(0, hv.y * 10.0 + 4.0)
		Decor.U.oval(pts, cols, hp, 3.4, 2.6, Color(1.0, 0.45, 0.1, 0.8), 6)
		Decor.U.oval(pts, cols, hp, 2.4, 1.8, Color(0.05, 0.03, 0.02, 0.95), 6)
	if _wfire > 0.0:
		Decor.U.flame(pts, cols, root.lerp(tip, 0.6), 7.0, 14.0 + 6.0 * sin(z._time * 12.0), sx * 3.0, 0.9)


func _wing_stub(sx: float) -> void:
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(sx * 3.0, -4.0), Vector2(sx * 14.0, -10.0), Vector2(sx * 10.0, 2.0), Vector2(sx * 4.0, 4.0)]), col(_tone.darkened(0.3)))
	DrawBatch.line(z, Vector2(sx * 14.0, -10.0), Vector2(sx * 10.0, 2.0), Color(1.0, 0.45, 0.1, 0.8), 1.0)
