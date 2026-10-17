extends "res://enemies/zombie_type.gd"
# ============================================================
#  SEALER (שלב 56, "ICE FJORD") - צייד כלבי ים מת: לובש את עור כלב הים שהוא צד (ראש הכלב כברדס, הסנפירים
#    תלויים מאחור), מגפי עור, זקן קפוא, ובידו "הקפיק" - מקל עץ עם ראש פלדה (פטיש + וו).
#  מה הם למדו: "אתה יורה במה שאתה רואה". אז הם ירדו מתחת לקרח, לאן שהכדורים לא מגיעים, ויוצאים רק כדי להכות.
#  מחזור:
#    SUB   - שוחה מתחת לקרח (אי אפשר לפגוע בו - collision_layer 0). רואים רק צל כהה ובועות שזזים בתוך הקרח.
#            הולך לחור הקרוב אליך (group "ice_holes": חורי דיג, פסי מים, קרח דק שנשבר) - ואם אין, שובר קרח חדש לידך.
#    TELL  - בועות רותחות בחור (דגל ה-tip-up קופץ) / סדקים מתפשטים בקרח (TELL_T). ירייה בבועות (Spot) = "SPOTTED":
#            הוא נזרק החוצה המום (STUN_T, נזק x STUN_MULT). פיצוץ מעל הצל = אותו דבר (מטען עומק).
#    BURST - פורץ מהמים בקפיצה אליך (LUNGE_V) עם ההקפיק - 1 נזק. נוחת על הבטן ומחליק (SLIDE) כמו כלב ים.
#    RETURN- קם והולך לחור הקרוב (מכה במקל אם אתה צמוד) -> צולל חזרה (DIVE). אין חור קרוב? חוצב אחד (CHOP) - חלון לירות.
#  "THEY LEARN" (main meta "sealer_spotted"): תפסת אותם בבועות SPOT_LEARN פעמים -> הבאים מזייפים: בועות בחור אחד
#    (הפיתיון), והם עצמם שוחים מהר לצד השני שלך ופורצים משם (FEINT) - "THE BUBBLES LIE NOW". נגד: לעקוב אחרי הצל, לא הבועות.
#  צלילים: "se_bubble", "se_burst", "se_bark", "se_crack", "se_slide", "se_club".
#  לשנות: SWIM_SPEED, EXIT_R, TELL_T, LUNGE_V, SLIDE_T, STUN_T, STUN_MULT, SPOT_LEARN, FEINT_*, CLUB_*, HOLE_R.
# ============================================================

const SOUNDS := {
	"se_bubble": [["B", 1.2, 1.6, 0.0, 0.7, 0.05, 3.0, 0.5, 1.0, 0, 0, 90.0], ["N", 0, 0, 0.0, 0.6, 0.1, 4.0, 0.12, 0.3, 0, 0.5], ["S", 140, 90, 0.0, 0.5, 0.05, 5.0, 0.15, 1.0, 0.3]],
	"se_burst": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 0.5, 0.005, 7.0, 0.9, 0.5, 0, 0.1], ["B", 0.8, 0.8, 0.0, 0.5, 0.0, 4.0, 0.5, 1.0, 0, 0, 120.0], ["S", 110, 45, 0.0, 0.2, 0.0, 14.0, 0.5, 1.0, 0]]},
	"se_bark": {"drive": 2.4, "layers": [["V", 260, 180, 0.0, 0.22, 0.01, 10.0, 0.8, 1.0, 0.04, 0, [500, 900, 30]], ["V", 240, 170, 0.25, 0.2, 0.01, 11.0, 0.7, 1.0, 0.04, 0, [500, 900, 30]], ["N", 0, 0, 0.0, 0.4, 0.0, 9.0, 0.15, 0.4, 0]]},
	"se_crack": [["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.8, 0.9, 0, 0.3], ["C", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.8, 1.0, 0], ["S", 2600, 2100, 0.0, 0.2, 0.0, 14.0, 0.15, 1.0, 0]],
	"se_slide": [["N", 0, 0, 0.0, 0.7, 0.02, 3.0, 0.4, 0.7, 0, 0.6]],
	"se_club": [["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.5, 0.5, 0, 0.5], ["S", 160, 60, 0.0, 0.12, 0.0, 24.0, 0.6, 1.0, 0]],
}

const SWIM_SPEED := 240.0
const FEINT_SPEED := 400.0
const AGGRO := 720.0              # מאיזה מרחק הוא מתחיל לצוד
const EXIT_R := 240.0             # חור במרחק כזה ממך = יוצא ממנו
const BREAK_X := 95.0             # אין חור? שובר קרח במרחק כזה ממך
const TELL_T := 0.75
const FEINT_TELL := 0.3
const LUNGE_V := 470.0
const LUNGE_DMG := 1
const SLIDE_T := 0.85
const UP_T := 0.45
const STUN_T := 1.4
const STUN_MULT := 1.5
const SPOT_LEARN := 2
const FEINT_BEHIND := 115.0
const CLUB_R := 46.0
const CLUB_WIND := 0.35
const CLUB_DMG := 1
const HOLE_R := 520.0             # עד כמה רחוק הוא הולך לחור כדי לצלול
const CHOP_T := 1.1
const DIVE_T := 0.5
const RETURN_MAX := 6.0
const DEPTH_R := 110.0            # פיצוץ במרחק כזה מהצל = מוציא אותו

enum { SUB, TELL, FEINT, BURST, SLIDE, UP, RETURN, CHOP, DIVE, STUN }
var state := SUB
# לבדיקות
var bursts := 0
var tells := 0
var lunge_hits := 0
var spotted := 0
var feints := 0
var breaks := 0
var dives := 0
var chops := 0
var clubs := 0
var club_hits := 0
var slides := 0
var depth_charged := 0
var learned := false

var _st := 0.0
var _cd := 1.0
var _ccd := 0.0
var _cwind := -1.0
var _floor := 630.0
var _exit := Vector2.ZERO
var _hole: Node = null
var _new_break := false
var _decoy := Vector2.ZERO
var _spot: Node = null
var _hit_done := false
var _pick_t := 0.0
var _ret_t := 0.0
var _bub := 0.0
var _z0 := 0
var _inited := false
var _stunned := false
var _shape_mode := 0
var _pelt := Color("9aa4a8")
var _spots := Color("3a4048")
var _face := Color("9fb0bc")
var _beard := Color("dfe8ee")
var _harp := true
var _club_head := Color("8a929a")
var _trou := Color("e8b820")
var _seed := 0


func stats() -> Dictionary:
	return {"name": "SEALER", "hp": 40, "walk": 40.0, "chase": 78.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("9fb0bc"), "shirt": Color("9aa4a8"), "pants": Color("3a3a40"), "shoe": Color("2a2624"),
		"points": 420, "ragdoll": false}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return submerged() == false


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 13 + 5
	_seed = r.randi()
	_harp = r.randf() < 0.6
	if _harp:   # כלב ים מגרינלנד: אפור-כסוף עם "אוכף" כהה
		_pelt = Color(0.7, 0.74, 0.76).lerp(Color(0.82, 0.84, 0.8), r.randf())
		_spots = Color("2e343c")
	else:   # כלב ים פרוותי: חום
		_pelt = Color("7a5a40").lerp(Color("9a7450"), r.randf())
		_spots = Color("3a2a22")
	_face = Color(0.6, 0.7, 0.76).lerp(Color(0.68, 0.66, 0.72), r.randf() * 0.7)
	_beard = [Color("dfe8ee"), Color("8a6a4a"), Color("3a3028")][r.randi() % 3]
	_club_head = [Color("8a929a"), Color("6a4a3a")][r.randi() % 2]
	_trou = [Color("e8b820"), Color("e8601a"), Color("2a3a5a"), Color("e8b820")][r.randi() % 4]
	var m: Node = z.get_parent()
	learned = m != null and int(m.get_meta("sealer_spotted", 0)) >= SPOT_LEARN
	_z0 = z.z_index
	_cd = r.randf_range(0.5, 1.5)


func submerged() -> bool:
	return state == SUB or state == TELL or state == FEINT


func _stage() -> Node:
	return z.get_parent().get("_stage") if z.get_parent() != null else null


func _go_under() -> void:
	z.collision_layer = 0
	z.collision_mask = 0
	z.z_index = maxi(_z0, 2)
	z.velocity = Vector2.ZERO
	z.global_position.y = _floor
	z._burn_t = 0.0
	_set_shape(0)


func _go_up() -> void:
	z.collision_layer = 4
	z.collision_mask = 1 | 16
	z.z_index = _z0
	_free_spot()


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_ccd -= delta
	_pick_t -= delta
	_bub += delta
	if not _inited:
		_inited = true
		var stg := _stage()
		_floor = float(stg.floor_y) if stg != null and stg.get("floor_y") != null else z.global_position.y
		if absf(z.global_position.y - _floor) < 30.0:
			state = SUB
			_go_under()
		else:   # נולד על קומה: הולך לחור
			state = RETURN
			_ret_t = 0.0
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2(9999, 0)
	match state:
		SUB:
			z.global_position.y = _floor
			if not has or absf(d.x) > AGGRO * 1.6:
				z.velocity.x = 0.0
				return true
			var on_ground: bool = absf(pl.global_position.y - _floor) < 90.0
			if absf(d.x) < AGGRO and on_ground:
				z._noticed = true
				if _pick_t <= 0.0:
					_pick_t = 0.35
					_pick_exit(pl)
				var tx: float = _exit.x if _exit != Vector2.ZERO else pl.global_position.x - signf(d.x) * 70.0
				var dx: float = tx - z.global_position.x
				z._dir = signf(dx) if absf(dx) > 3.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, clampf(dx * 4.0, -SWIM_SPEED, SWIM_SPEED), 900.0 * delta)
				if _exit != Vector2.ZERO and absf(dx) < 10.0 and _cd <= 0.0:
					if learned and _feint_target(pl):
						_start_feint(pl)
					else:
						_start_tell(TELL_T)
			else:   # מחכה מתחתיך
				var tx2: float = pl.global_position.x
				z.velocity.x = move_toward(z.velocity.x, clampf((tx2 - z.global_position.x) * 2.0, -SWIM_SPEED * 0.6, SWIM_SPEED * 0.6), 600.0 * delta)
		TELL:
			z.velocity.x = 0.0
			z.global_position.y = _floor
			if _hole != null and is_instance_valid(_hole) and _hole.has_method("boil"):
				_hole.boil(1.0)
			if _st <= 0.0:
				_burst(pl, false)
		FEINT:   # הפיתיון רותח בחור A - והוא שוחה מהר אל B
			z.global_position.y = _floor
			if _hole != null and is_instance_valid(_hole) and _hole.has_method("boil"):
				_hole.boil(1.0)
			var dx2: float = _exit.x - z.global_position.x
			z._dir = signf(dx2) if absf(dx2) > 3.0 else z._dir
			z.velocity.x = clampf(dx2 * 6.0, -FEINT_SPEED, FEINT_SPEED)
			if absf(dx2) < 10.0 or _st <= 0.0:
				z.global_position.x = _exit.x
				_hole = null
				_start_tell(FEINT_TELL)
		BURST:
			z.velocity.y += z.gravity * delta
			_contact(pl)
			if z.is_on_floor() and _st < 0.25:
				if _stunned:
					state = STUN
					_st = STUN_T
					_set_shape(2)
				else:
					state = SLIDE
					_st = SLIDE_T
					slides += 1
					_set_shape(1)
					if Art.on_screen(z, z.global_position):
						Sfx.play("se_slide", z.global_position, -5.0, 0.1, 2)
		SLIDE:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 380.0 * delta)
			_contact(pl)
			if Engine.get_physics_frames() % 5 == 0 and absf(z.velocity.x) > 60.0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 10.0, -2.0), "snow", Vector2.UP, 2)
			if _st <= 0.0:
				state = UP
				_st = UP_T
				_set_shape(0)
		STUN:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if _st <= 0.0:
				_stunned = false
				state = UP
				_st = UP_T
				_set_shape(0)
		UP:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
			if _st <= 0.0:
				state = RETURN
				_ret_t = 0.0
				_pick_t = 0.0
		RETURN:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			_ret_t += delta
			if _pick_t <= 0.0:
				_pick_t = 0.5
				_hole = _nearest_hole(z.global_position.x, HOLE_R)
			var v := 0.0
			var tx3: float = z.global_position.x
			var on_floor0: bool = absf(z.global_position.y - _floor) < 8.0
			if _hole != null and is_instance_valid(_hole) and on_floor0:
				tx3 = _hole.surface_point().x
			elif has:
				tx3 = pl.global_position.x
			var dx3: float = tx3 - z.global_position.x
			if absf(dx3) > 6.0:
				z._dir = signf(dx3)
				v = z._dir * float(z.chase_speed)
			# מכה במקל כשאתה צמוד
			if _cwind >= 0.0:
				v = 0.0
				_cwind -= delta
				if _cwind < 0.0:
					clubs += 1
					Sfx.play("se_club", z.global_position, -3.0, 0.15, 2)
					if has and absf(d.x) < CLUB_R + 10.0 and absf(d.y) < 50.0 and d.x * z._dir > -8.0:
						if pl._roll_t <= 0.0:
							club_hits += 1
						pl.hurt(CLUB_DMG, Vector2(z._dir, -0.3))
					_ccd = 1.0
			elif has and _ccd <= 0.0 and absf(d.x) < CLUB_R and absf(d.y) < 50.0:
				_cwind = CLUB_WIND
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, v, 700.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) / 14.0
			if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 20.0:
				z.velocity.y = -480.0
			if _cwind < 0.0 and on_floor0 and z.is_on_floor():
				if _hole != null and is_instance_valid(_hole) and absf(dx3) < 10.0 and _hole.is_open():
					state = DIVE
					_st = DIVE_T
					Sfx.play("splash", z.global_position, -4.0, 0.1, 2)
					if _hole.has_method("splash"):
						_hole.splash()
				elif (_hole == null or _ret_t > RETURN_MAX) and _can_break(z.global_position.x) and (not has or absf(d.x) > 70.0):
					state = CHOP
					_st = CHOP_T
					chops += 1
		CHOP:   # חוצב חור בקרח (חלון לירות)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
			if fmod(_st, 0.36) < delta and Art.on_screen(z, z.global_position):
				Sfx.play("se_club", z.global_position, -6.0, 0.2, 2)
				Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 14.0, -2.0), "snow", Vector2.UP, 4)
			if _st <= 0.0:
				_hole = _make_break(z.global_position.x + z._dir * 12.0)
				z.global_position.x += z._dir * 12.0
				state = DIVE
				_st = DIVE_T
				Sfx.play("splash", z.global_position, -4.0, 0.1, 2)
		DIVE:
			z.velocity = Vector2.ZERO
			if _st <= 0.0:
				dives += 1
				state = SUB
				_cd = randf_range(1.2, 2.0)
				_exit = Vector2.ZERO
				_hole = null
				_go_under()
				return true
	if submerged():
		z.global_position.x += z.velocity.x * delta
		z.global_position.x = clampf(z.global_position.x, 40.0, z.world_w - 40.0)
	else:
		z.move_and_slide()
	return true


func _contact(pl: Node) -> void:
	if _hit_done or _stunned or pl == null or pl.dead:
		return
	var me := Rect2(z.global_position + Vector2(-20.0, -40.0), Vector2(40.0, 40.0))
	if state == SLIDE:
		me = Rect2(z.global_position + Vector2(-30.0, -24.0), Vector2(60.0, 24.0))
	if me.intersects(pl.body_rect()):
		_hit_done = true
		if pl._roll_t <= 0.0:
			lunge_hits += 1
		pl.hurt(LUNGE_DMG, Vector2(signf(z.velocity.x) if z.velocity.x != 0.0 else z._dir, -0.5))


# ---- בחירת יציאה ----
func _open_holes() -> Array:
	var out := []
	for h in z.get_tree().get_nodes_in_group("ice_holes"):
		if is_instance_valid(h) and h.has_method("is_open") and h.is_open() and absf(h.surface_point().y - _floor) < 14.0:
			out.append(h)
	return out


func _nearest_hole(x: float, r: float) -> Node:
	var best: Node = null
	var bd := r
	for h in _open_holes():
		var dd := absf(h.surface_point().x - x)
		if dd < bd:
			bd = dd
			best = h
	return best


func _can_break(x: float) -> bool:
	var stg := _stage()
	return stg != null and stg.has_method("ice_at") and stg.ice_at(x)


func _pick_exit(pl: Node) -> void:
	var px: float = pl.global_position.x
	var h := _nearest_hole(px, EXIT_R)
	_new_break = false
	if h != null:
		_hole = h
		var sp: Vector2 = h.surface_point()
		var hw: float = h.hole_w() if h.has_method("hole_w") else 40.0
		# בתוך החור: הנקודה הכי קרובה אליך
		_exit = Vector2(clampf(px, sp.x - hw * 0.3, sp.x + hw * 0.3), _floor)
		return
	_hole = null
	var s := signf(z.global_position.x - px) if absf(z.global_position.x - px) > 4.0 else 1.0
	for side in [s, -s]:
		var bx: float = px + float(side) * BREAK_X
		if _can_break(bx):
			_exit = Vector2(bx, _floor)
			_new_break = true
			return
	_exit = Vector2.ZERO


func _feint_target(pl: Node) -> bool:
	var px: float = pl.global_position.x
	var bx: float = px + signf(px - _exit.x if absf(px - _exit.x) > 4.0 else 1.0) * FEINT_BEHIND
	var h := _nearest_hole(bx, 50.0)
	if h != null:
		_decoy = _exit
		_exit = Vector2(h.surface_point().x, _floor)
		return true
	if _can_break(bx):
		_decoy = _exit
		_exit = Vector2(bx, _floor)
		return true
	return false


func _start_tell(t: float) -> void:
	state = TELL
	_st = t
	tells += 1
	if _hole == null or not is_instance_valid(_hole) or absf(_hole.surface_point().x - _exit.x) > _hole.hole_w():
		_hole = _nearest_hole(_exit.x, 40.0)
		_new_break = _hole == null
	z.global_position.x = _exit.x
	if Art.on_screen(z, z.global_position, 200.0):
		Sfx.play("se_crack" if _new_break else "se_bubble", z.global_position, -2.0, 0.15, 2)
	# הבועות: אפשר לירות בהן
	_free_spot()
	var sp := Spot.new()
	sp.tm = self
	sp.collision_layer = 4
	sp.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(56, 34)
	cs.shape = sh
	cs.position = Vector2(0, -17)
	sp.add_child(cs)
	z.get_parent().add_child(sp)
	sp.global_position = Vector2(_exit.x, _floor)
	_spot = sp


func _start_feint(pl: Node) -> void:
	state = FEINT
	_st = 1.2
	feints += 1
	if _hole != null and is_instance_valid(_hole) and _hole.has_method("boil"):
		_hole.boil(1.0)
	var fx := Bubbles.new()
	fx.position = _decoy
	z.get_parent().add_child(fx)
	Sfx.play("se_bubble", _decoy, -2.0, 0.15, 2)
	var m: Node = z.get_parent()
	if m != null and not m.has_meta("se_told_feint"):
		m.set_meta("se_told_feint", true)
		z._popup("THE BUBBLES LIE NOW", Color("9adcff"), 14, -60.0)
		if pl.has_method("_say"):
			pl._say("They saw me shoot the bubbles... watch the shadow, not the bubbles", Color("9adcff"))
	# _hole = החור של הפיתיון (רותח), _exit = היציאה האמיתית
	_hole = _nearest_hole(_decoy.x, 40.0)


func _free_spot() -> void:
	if _spot != null and is_instance_valid(_spot):
		_spot.queue_free()
	_spot = null


# הבועות נורו בזמן האזהרה / מטען עומק
func spot_hit() -> void:
	if not (state == TELL) or z.dead:
		return
	spotted += 1
	var m: Node = z.get_parent()
	if m != null:
		m.set_meta("sealer_spotted", int(m.get_meta("sealer_spotted", 0)) + 1)
		if int(m.get_meta("se_told_spot", 0)) < 2:
			m.set_meta("se_told_spot", int(m.get_meta("se_told_spot", 0)) + 1)
			z._popup("SPOTTED", Color("ffe08a"), 15, -70.0)
	_burst(player(), true)


func _burst(pl: Node, stunned: bool) -> void:
	_free_spot()
	if _new_break or _hole == null or not is_instance_valid(_hole):
		_hole = _make_break(_exit.x)
	elif _hole.has_method("splash"):
		_hole.splash()
	bursts += 1
	state = BURST
	_st = 0.5
	_hit_done = false
	_stunned = stunned
	_go_up()
	z.global_position = Vector2(_exit.x if _exit != Vector2.ZERO else z.global_position.x, _floor - 2.0)
	if stunned:
		z.velocity = Vector2(randf_range(-40.0, 40.0), -400.0)
	else:
		var dx: float = (pl.global_position.x - z.global_position.x) if pl != null and not pl.dead else z._dir * 100.0
		z._dir = signf(dx) if absf(dx) > 2.0 else z._dir
		z.velocity = Vector2(clampf(dx * 1.9, -LUNGE_V, LUNGE_V), -430.0)
		Sfx.play("se_bark", z.global_position, -1.0, 0.1, 2)
	Sfx.play("se_burst", z.global_position, 1.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position, "drop", Vector2.UP, 14)
	Particles.burst(z.get_parent(), z.global_position, "snow", Vector2.UP, 6)


func _make_break(x: float) -> Node:
	var stg := _stage()
	if stg == null or not stg.has_method("ice_at") or not stg.ice_at(x):
		return _nearest_hole(x, 80.0)
	breaks += 1
	var b := IceBreak.new()
	z.get_parent().add_child(b)
	b.global_position = Vector2(x, _floor)
	Sfx.play("se_crack", b.global_position, 0.0, 0.1, 2)
	return b


func _set_shape(mode: int) -> void:
	if _shape_mode == mode or z._shape == null:
		return
	_shape_mode = mode
	var rs := z._shape.shape as RectangleShape2D
	if mode == 0:
		rs.size = Vector2(38.0 * z.wf, 66.0 * z.sc)
		z._shape.position = Vector2(0.0, -33.0 * z.sc)
	else:   # שוכב: אזור פגיעה נמוך ורחב
		rs.size = Vector2(62.0 * z.sc, 24.0 * z.sc)
		z._shape.position = Vector2(0.0, -12.0 * z.sc)


# ============================================================
#  נזק
# ============================================================
func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if submerged():
		var s := str(src.get("source", "bullet"))
		if (src.has("blast") or s in ["grenade", "barrel", "rocket", "launcher", "molotov"]) and state == TELL:
			depth_charged += 1
			spot_hit()
		elif (src.has("blast") or s in ["grenade", "barrel", "rocket", "launcher"]) and absf(hit_pos.x - z.global_position.x) < DEPTH_R:
			depth_charged += 1   # מטען עומק: נזרק החוצה המום
			_exit = Vector2(z.global_position.x, _floor)
			_new_break = true
			state = TELL
			spot_hit()
		z._burn_t = 0.0
		return false
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	if state == STUN or (state == BURST and _stunned):
		return STUN_MULT
	return 1.0


func on_death() -> void:
	_free_spot()
	_set_shape(0)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	var t: float = z._time
	var fl: bool = z._flash > 0.0
	if submerged() and not z.dead:
		_draw_under(t)
		return true
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	var pose := 0
	var xf := Transform2D.IDENTITY
	var dk := 0.0
	if z.dead:
		begin_draw()
		draw_body(z, 3, t, fl)
		end_draw()
		return true
	match state:
		BURST:
			pose = 4 if _stunned else 1
		SLIDE:
			pose = 2
			xf = Transform2D(PI / 2.0 * 0.92, Vector2(-26.0, -10.0))
		STUN:
			pose = 3
			xf = Transform2D(-PI / 2.0 * 0.95 + sin(t * 9.0) * 0.08, Vector2(26.0, -9.0))
		UP:
			pose = 5
		CHOP:
			pose = 6
		DIVE:
			pose = 7
			dk = clampf(1.0 - _st / DIVE_T, 0.0, 1.0)
			xf = Transform2D(0.0, Vector2(0.0, dk * 62.0))
	if z.is_on_floor() and state != DIVE:
		Art.ground_shadow(z, Vector2.ZERO, 16.0 * z.wf * z.sc)
	z.draw_set_transform_matrix(Transform2D(z.react_tilt(), Vector2(0.0, z.react_hop() * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO) * xf)
	draw_body(z, pose, t, fl)
	end_draw()
	if state == DIVE:   # המים / הקרח מכסים אותו
		var c := Color(0.03, 0.08, 0.14)
		z.draw_rect(Rect2(-30.0, 0.0, 60.0, 70.0), c)
		z.draw_rect(Rect2(-32.0, -2.0, 64.0, 3.0), Color(0.7, 0.9, 1.0, 0.8))
		for q in 4:
			var k := fmod(t * 2.0 + float(q) * 0.25, 1.0)
			z.draw_circle(Vector2(sin(float(q) * 2.3) * 14.0, -k * 10.0), 1.5 + k * 2.0, Color(0.85, 0.95, 1.0, 0.7 * (1.0 - k)))
	return true


# מתחת לקרח: צל כהה בצורת כלב ים + בועות. TELL: בועות רותחות / סדקים בקרח
func _draw_under(t: float) -> void:
	var sw := sin(t * 6.0) * 2.0
	var a := 0.5
	var c := Color(0.02, 0.05, 0.1, a)
	var dd: float = z._dir
	var pts := PackedVector2Array([Vector2(-26 * dd, 18 + sw * 0.3), Vector2(-14 * dd, 13), Vector2(10 * dd, 12), Vector2(22 * dd, 15), Vector2(26 * dd, 18), Vector2(20 * dd, 22), Vector2(-12 * dd, 23), Vector2(-30 * dd, 20 - sw * 0.5)])
	z.draw_colored_polygon(pts, c)
	z.draw_colored_polygon(Art.ellipse(Vector2(-31.0 * dd, 18.0 + sw), 5.0, 2.4, 0.4 * dd, 8), c)   # סנפירים
	z.draw_colored_polygon(Art.ellipse(Vector2(-31.0 * dd, 21.0 - sw), 5.0, 2.4, -0.4 * dd, 8), c)
	if absf(z.velocity.x) > 30.0:   # שובל בועות מתחת לקרח
		for q in 4:
			var k := fmod(t * 2.5 + float(q) * 0.25, 1.0)
			z.draw_circle(Vector2(-dd * (28.0 + k * 30.0), 12.0 - k * 4.0), 1.2 + k, Color(0.8, 0.92, 1.0, 0.5 * (1.0 - k)))
	elif fmod(_bub, 3.0) < 0.6:
		var k2 := fmod(_bub, 3.0) / 0.6
		z.draw_circle(Vector2(6.0 * dd, 12.0 - k2 * 8.0), 1.6, Color(0.85, 0.95, 1.0, 0.6 * (1.0 - k2)))
	if state == TELL:
		var k3: float = clampf(1.0 - _st / TELL_T, 0.0, 1.0)
		if _new_break:   # סדקים מתפשטים על הקרח
			var r := RandomNumberGenerator.new()
			r.seed = _seed
			for q in 7:
				var ang := -PI + float(q) / 6.0 * PI + r.randf_range(-0.2, 0.2)
				var p0 := Vector2.ZERO
				var p1 := p0 + Vector2(cos(ang) * (8.0 + 22.0 * k3), sin(ang) * 3.0 * k3 + 2.0)
				var p2 := p1 + Vector2(cos(ang + 0.4) * 12.0 * k3, 1.0)
				z.draw_polyline(PackedVector2Array([p0, p1, p2]), Color(0.1, 0.25, 0.4, 0.85), 1.4)
			z.draw_colored_polygon(Art.ellipse(Vector2(0, 2), 10.0 + 10.0 * k3, 3.0 + k3, 0.0, 12), Color(0.1, 0.25, 0.4, 0.4 * k3))
		for q in 8:
			var k := fmod(t * 3.2 + float(q) / 8.0, 1.0)
			var bx := sin(float(q) * 2.1 + t * 2.0) * 16.0
			z.draw_circle(Vector2(bx, -k * 22.0 * (0.5 + k3)), 1.5 + k * 2.8, Color(0.88, 0.97, 1.0, 0.85 * (1.0 - k)))
		z.draw_colored_polygon(Art.ellipse(Vector2(0, -1), 16.0 + 4.0 * sin(t * 30.0), 3.2, 0.0, 12), Color(0.75, 0.9, 1.0, 0.55 * k3 + 0.2))


# הגוף. pose: 0 הולך, 1 קפיצה (ההקפיק למעלה), 2 החלקה על הבטן (מסובב), 3 מוטל / מת, 4 נזרק המום, 5 קם, 6 חוצב, 7 צולל
func draw_body(ci: CanvasItem, pose: int, t: float, fl: bool) -> void:
	var pelt := Color.WHITE if fl else _pelt
	var pelt_d := Color.WHITE if fl else Art.shade(_pelt, 0.3)
	var spots := Color.WHITE if fl else _spots
	var sk := Color.WHITE if fl else _face
	var boot := Color.WHITE if fl else Color("2e2a26")
	var trou := Color.WHITE if fl else _trou
	var f: Array = feet(4.5, 2.2)
	var hip := Vector2(0, -24)
	var sh := Vector2(2.0, -43)
	var hf := sh + Vector2(8.0, 13.0)
	var hb := sh + Vector2(-5.0, 14.0)
	var club_a := -0.4
	match pose:
		1:   # קפיצה עם ההקפיק מעל הראש
			f = [Vector2(8.0, -8.0), Vector2(-7.0, -4.0)]
			hf = sh + Vector2(6.0, -16.0)
			hb = sh + Vector2(10.0, -10.0)
			club_a = -0.9 + clampf(1.0 - _st / 0.5, 0.0, 1.0) * 1.6
			sh += Vector2(3.0, 0.0)
		2:   # מחליק על הבטן: הידיים קדימה
			f = [Vector2(2.0, 0.0), Vector2(-2.0, 2.0)]
			hf = sh + Vector2(4.0, -22.0)
			hb = sh + Vector2(-2.0, -20.0)
			club_a = -1.5
		3, 4:   # מוטל
			f = [Vector2(6.0 + sin(t * 11.0) * 3.0, -4.0), Vector2(-5.0, -2.0)]
			hf = sh + Vector2(12.0, -6.0 + sin(t * 12.0) * 4.0)
			hb = sh + Vector2(-10.0, -8.0)
			club_a = 0.6
		5:   # קם
			hip += Vector2(0, 6)
			sh += Vector2(4.0, 10.0)
			f = [Vector2(6.0, 0.0), Vector2(-5.0, 0.0)]
			hf = sh + Vector2(10.0, 14.0)
		6:   # חוצב
			var ck := fmod(_st, 0.36) / 0.36
			hf = sh + Vector2(10.0, -14.0 + ck * 30.0)
			hb = hf + Vector2(-4.0, 2.0)
			club_a = -1.3 + ck * 2.6
			sh += Vector2(3.0, 3.0)
		_:
			if _cwind >= 0.0:
				var wk: float = clampf(1.0 - _cwind / CLUB_WIND, 0.0, 1.0)
				hf = sh + Vector2(2.0 - wk * 4.0, -14.0)
				club_a = -1.9
			elif _ccd > 0.7:
				hf = sh + Vector2(15.0, 8.0)
				club_a = 0.9
	# סנפירי הזנב תלויים מאחור
	var tail := hip + Vector2(-9.0, 10.0 + sin(t * 3.0) * 1.5)
	Art.fill(ci, PackedVector2Array([tail + Vector2(2, -8), tail + Vector2(-3, 4), tail + Vector2(-9, 9), tail + Vector2(-2, 7), tail + Vector2(3, 9), tail + Vector2(4, 0)]), pelt_d, Art.OUTLINE, 1.0)
	# רגליים: מכנסי פרווה כהים + מגפי עור עם שוליים
	for q in 2:
		var ft: Vector2 = f[1] if q == 0 else f[0]
		var hp := hip + Vector2(-2.0 if q == 0 else 2.0, 0.0)
		var knee := Art.joint(hp, ft + Vector2(0, -3), 11.5, 11.5, 1.0)
		Art.limb(ci, PackedVector2Array([hp, knee, ft + Vector2(0, -5)]), 6.6, Art.shade(trou, 0.25) if q == 0 else trou)
		Art.fill(ci, PackedVector2Array([ft + Vector2(-3.5, -8.0), ft + Vector2(3.5, -8.0), ft + Vector2(7.5, -1.5), ft + Vector2(7.5, 0.5), ft + Vector2(-4.0, 0.5)]), boot, Art.OUTLINE, 1.0)
		ci.draw_line(ft + Vector2(-4.0, -8.0), ft + Vector2(4.0, -8.0), Color.WHITE if fl else Color("d8d0c0"), 2.0)
	# יד אחורית
	_arm(ci, sh + Vector2(-3, 1), hb, pelt_d, sk)
	# גוף: פרוות כלב הים כמעיל עם "אוכף" כהה וכתמים
	var torso := PackedVector2Array([sh + Vector2(-9, -2), sh + Vector2(8, -1), hip + Vector2(8, 3), hip + Vector2(-3, 8), hip + Vector2(-11, 4)])
	Art.fill_shaded(ci, torso, pelt, 0.14, 0.32)
	var r := RandomNumberGenerator.new()
	r.seed = _seed
	if _harp:   # "אוכף" בצורת נבל על הגב
		ci.draw_colored_polygon(PackedVector2Array([sh + Vector2(-8, 2), sh + Vector2(-2, 3), hip + Vector2(-3, -4), hip + Vector2(-9, 3), hip + Vector2(-11, -2)]), Color(spots.r, spots.g, spots.b, 0.85))
	for q in 7:
		var sp := sh.lerp(hip, r.randf_range(0.1, 0.95)) + Vector2(r.randf_range(-7, 7), 0)
		ci.draw_colored_polygon(Art.ellipse(sp, r.randf_range(0.8, 1.8), r.randf_range(0.6, 1.2), r.randf(), 6), Color(spots.r, spots.g, spots.b, 0.8))
	var belly := Color.WHITE if fl else _pelt.lightened(0.35)
	ci.draw_colored_polygon(PackedVector2Array([sh + Vector2(3, 0), sh + Vector2(8, -1), hip + Vector2(8, 3), hip + Vector2(3, 4)]), Color(belly.r, belly.g, belly.b, 0.8))
	ci.draw_line(hip + Vector2(-9, -3), hip + Vector2(8, -3), Color.WHITE if fl else Color("c03a20"), 2.4)   # חגורת חבל אדומה
	# מים מטפטפים
	if not fl and pose != 7:
		for q in 3:
			var k := fmod(t * 1.3 + float(q) * 0.33, 1.0)
			ci.draw_circle(hip + Vector2(-6.0 + float(q) * 6.0, 2.0 + k * 20.0), 1.0, Color(0.7, 0.9, 1.0, 0.7 * (1.0 - k)))
	# ראש: פנים כחלחלות, זקן קפוא, ומעליו ראש כלב הים (ברדס) עם עיניים שחורות ושפם
	var head := sh + Vector2(2.5, -7.5)
	Art.disc(ci, head, 6.2, sk)
	ci.draw_colored_polygon(Art.ellipse(head + Vector2(3.5, -0.5), 1.6, 1.2, 0.0, 8), Color(0.08, 0.03, 0.05))
	if not fl and pose != 3:
		Art.glow(ci, head + Vector2(3.6, -0.5), 3.0, Color(0.6, 0.9, 1.0, 0.45))
	var bc := Color.WHITE if fl else _beard
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-3, 1), head + Vector2(6.5, 2.5), head + Vector2(5, 8.5), head + Vector2(0, 9), head + Vector2(-3, 5)]), bc)
	for q in 4:   # נטיפי קרח בזקן
		ci.draw_line(head + Vector2(-1.0 + float(q) * 1.8, 8.0), head + Vector2(-0.8 + float(q) * 1.8, 11.0 + float(q % 2)), Color(0.85, 0.96, 1.0, 0.85), 0.9)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(2.0, 3.0), head + Vector2(5.8, 2.6), head + Vector2(5.2, 4.6), head + Vector2(2.4, 4.6)]), Color(0.15, 0.05, 0.1))
	# ברדס: ראש כלב הים
	var hood := PackedVector2Array([head + Vector2(-8, 6), head + Vector2(-9, -3), head + Vector2(-5, -9), head + Vector2(3, -10), head + Vector2(9, -8), head + Vector2(14, -5.5), head + Vector2(14.5, -3.5), head + Vector2(8, -3), head + Vector2(3, -4.5), head + Vector2(-3, -3), head + Vector2(-4, 5)])
	Art.fill_shaded(ci, hood, pelt, 0.15, 0.3)
	ci.draw_colored_polygon(Art.ellipse(head + Vector2(14.0, -4.6), 1.4, 1.0, 0.0, 8), Color.WHITE if fl else Color("1a1a1e"))   # אף הכלב
	ci.draw_colored_polygon(Art.ellipse(head + Vector2(6.5, -7.0), 1.8, 1.6, 0.0, 8), Color.WHITE if fl else Color("101014"))   # עין הכלב
	ci.draw_circle(head + Vector2(6.9, -7.4), 0.5, Color(1, 1, 1, 0.8))
	for q in 3:   # שפם
		ci.draw_line(head + Vector2(13.0, -4.0 + float(q) * 0.8), head + Vector2(17.5, -5.0 + float(q) * 1.6), Color(0.9, 0.9, 0.85, 0.7), 0.6)
	if _harp:
		ci.draw_colored_polygon(Art.ellipse(head + Vector2(4.0, -8.0), 4.0, 1.6, 0.1, 8), Color(spots.r, spots.g, spots.b, 0.7))
	# יד קדמית + ההקפיק
	_arm(ci, sh + Vector2(4, 1), hf, pelt, sk)
	var ca := club_a
	var cd := Vector2.from_angle(ca - PI / 2.0)
	var tip := hf + cd * 24.0
	ci.draw_line(hf - cd * 6.0, tip, Color.WHITE if fl else Color("7a5a32"), 2.4)
	var cn := Vector2(-cd.y, cd.x)
	var ch := Color.WHITE if fl else _club_head
	Art.fill(ci, PackedVector2Array([tip - cn * 3.5 - cd * 2.0, tip + cn * 2.0 - cd * 2.0, tip + cn * 2.0 + cd * 2.0, tip - cn * 3.5 + cd * 2.0]), ch, Art.OUTLINE, 0.9)
	ci.draw_polyline(PackedVector2Array([tip + cn * 2.0, tip + cn * 6.0 + cd * 1.0, tip + cn * 7.0 - cd * 2.0]), ch, 1.6)   # הוו
	if not fl:
		ci.draw_circle(tip + cn * 6.5, 0.9, Color(0.6, 0.05, 0.05, 0.8))


func _arm(ci: CanvasItem, s: Vector2, h: Vector2, sleeve: Color, sk: Color) -> void:
	var el := Art.joint(s, h, 10.0, 10.0, -1.0)
	Art.limb(ci, PackedVector2Array([s, el, el.lerp(h, 0.7)]), 5.4, sleeve)
	Art.limb(ci, PackedVector2Array([el.lerp(h, 0.65), h]), 3.6, sk)
	Art.disc(ci, h, 2.6, sk, Art.OUTLINE, 0.9)


# ============================================================
#  הבועות שאפשר לירות בהן (TELL)
# ============================================================
class Spot extends StaticBody2D:
	var tm = null

	func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
		if tm != null:
			tm.spot_hit()


# ---- בועות פיתיון (FEINT) ----
class Bubbles extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		if _t > 1.3:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.3 - _t, 0.0, 1.0)
		for q in 8:
			var k := fmod(_t * 3.2 + float(q) / 8.0, 1.0)
			var bx := sin(float(q) * 2.1 + _t * 2.0) * 16.0
			draw_circle(Vector2(bx, -k * 22.0), 1.5 + k * 2.8, Color(0.88, 0.97, 1.0, 0.85 * (1.0 - k) * a))
		draw_colored_polygon(Art.ellipse(Vector2(0, -1), 16.0 + 4.0 * sin(_t * 30.0), 3.2, 0.0, 12), Color(0.75, 0.9, 1.0, 0.5 * a))


# ---- חור שהוא שבר בקרח (נקפא מחדש אחרי REFREEZE) ----
class IceBreak extends Node2D:
	const W := 54.0
	const REFREEZE := 14.0
	var _t := 0.0
	var _splash := 1.0
	var _shards := []

	func _ready() -> void:
		z_index = 5
		add_to_group("ice_holes")
		for i in 7:
			_shards.append([randf_range(-W * 0.7, W * 0.7), randf_range(5.0, 11.0), randf_range(-0.6, 0.6)])

	func surface_point() -> Vector2:
		return global_position

	func hole_w() -> float:
		return W

	func is_open() -> bool:
		return _t < REFREEZE

	func boil(_k: float) -> void:
		pass

	func splash() -> void:
		_splash = 1.0

	func _process(delta: float) -> void:
		_t += delta
		_splash = move_toward(_splash, 0.0, delta * 1.5)
		if _t > REFREEZE and is_in_group("ice_holes"):
			remove_from_group("ice_holes")
		if _t > REFREEZE + 2.0:
			queue_free()
			return
		if Art.on_screen(self, global_position, 100.0) and (Engine.get_process_frames() % 3 == 0 or _splash > 0.0):
			queue_redraw()

	func _draw() -> void:
		var fz := clampf((_t - REFREEZE + 2.0) / 2.0, 0.0, 1.0)   # קופא מחדש
		var a := 1.0 - fz
		draw_colored_polygon(Art.ellipse(Vector2(0, 2), W * 0.7, 6.0, 0.0, 16), Color(0.75, 0.88, 0.96, a))
		draw_colored_polygon(Art.ellipse(Vector2(0, 2), W * 0.5, 4.2, 0.0, 16), Color(0.03, 0.08, 0.14, a))
		draw_colored_polygon(Art.ellipse(Vector2(-4, 1), W * 0.3, 1.4, 0.0, 10), Color(0.3, 0.5, 0.65, 0.6 * a))
		for s in _shards:   # גושי קרח שבורים סביב
			var p := Vector2(float(s[0]), -1.0)
			var r := float(s[1])
			draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.5, 2), p + Vector2(-r * 0.3, -r * 0.5), p + Vector2(r * 0.4, -r * 0.6), p + Vector2(r * 0.5, 2)]), Color(0.85, 0.95, 1.0, a))
			draw_line(p + Vector2(-r * 0.3, -r * 0.5), p + Vector2(r * 0.4, -r * 0.6), Color(1, 1, 1, a), 1.2)
		if _splash > 0.0:
			for q in 7:
				var ang := -PI / 2.0 + (float(q) - 3.0) * 0.32
				var rr := (1.0 - _splash) * 50.0 + 6.0
				draw_circle(Vector2.from_angle(ang) * rr * Vector2(0.9, 1.3), 3.0 + _splash * 3.0, Color(0.9, 0.97, 1.0, 0.75 * _splash))
