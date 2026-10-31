extends "res://enemies/zombie_type.gd"
# ============================================================
#  COFFIN BREAKER (שלב 50, "TANGO CEMETERY") - זומבי שוכב בארון מתים סגור על הרצפה / על גג מאוזוליאום.
#    COFFIN  - ארון סגור. כשאתה מתקרב (HINT_R) שומעים גירוד חלש והמכסה רועד קצת.
#    SCRATCH - אתה בטווח WAKE_R: אזהרה ברורה (WARN_T) - גירוד חזק, המכסה קופץ, אצבעות יוצאות מהסדק.
#    BURST   - המכסה עף. אם אתה רחוק (THROW_R) - זורק עליך את המכסה (LidShot, מסתובב באוויר).
#              אם אתה קרוב - שומר את המכסה כמגן מלפנים (LID_HP פגיעות בגוף נחסמות; הראש והגב פתוחים).
#    CHASE   - בא אליך ותופס. אם אתה בורח (FLEE_R) או עולה לגג והמכסה עוד אצלו - זורק אותו.
#              (GRAB): נתפסת -> A/D לסירוגין להשתחרר. כל BITE_T נושך. השתחררת -> הוא המום (STUN).
#  ירייה בארון סגור מוקדם (לפני שהתקרבת) - הארון נפתח מוקדם ובלי מגן: יתרון לשחקן.
#  "THEY LEARN": אחרי EARLY_LEARN ארונות שנפתחו מוקדם בירי (main meta "cb_early") - הארונות הבאים
#    "סבלניים": לא נפתחים מיריות, לא מגרדים כשאתה מתקרב, מחכים שתעבור (PASS_D) ואז פורצים מאחוריך ("BEHIND YOU").
#  לשנות: HINT_R, WAKE_R, WARN_T, THROW_R, LID_HP, LID_V, GRAB_R, BITE_T, EARLY_LEARN, PASS_D.
# ============================================================

const SOUNDS := {
	"cb_scratch": [["N", 0, 0, 0.0, 0.5, 0.0, 3.0, 0.35, 0.25, 0, 0.9, [3000, 5000, 18]], ["N", 0, 0, 0.12, 0.3, 0.0, 6.0, 0.2, 0.3, 0, 0.8]],
	"cb_knock": [["S", 110, 70, 0.0, 0.12, 0.0, 30.0, 0.6, 1.0, 0.1], ["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.4, 0.15, 0, 0.3]],
	"cb_burst": [["N", 0, 0, 0.0, 0.45, 0.0, 9.0, 0.8, 0.4, 0, 0.6], ["S", 140, 50, 0.0, 0.35, 0.0, 10.0, 0.6, 1.0, 0.2]],
	"cb_spin": [["S", 300, 260, 0.0, 0.4, 0.0, 5.0, 0.15, 1.0, 0.0, 0, [600, 900, 14]]],
}

const HINT_R := 460.0
const WAKE_R := 190.0
const WARN_T := 1.0
const THROW_R := 170.0
const THROW_WIND := 0.4
const FLEE_R := 280.0          # עם מכסה ביד ואתה רחוק מזה -> זורק
const LID_HP := 6
const LID_V := 430.0
const GRAB_R := 34.0
const GRAB_CD := 1.2
const BITE_T := 0.9
const STUN_T := 1.4
const EARLY_LEARN := 2
const PASS_D := 80.0

enum { COFFIN, SCRATCH, RISE, THROW, CHASE, HOLD, STUN }
var state := COFFIN
var patient := false          # לומד: מחכה שתעבור
# לבדיקות
var woke := 0
var early := false
var thrown := 0
var throw_hits := 0
var blocks := 0
var grabs := 0
var bites := 0
var behind := false

var lid := 0                  # חיי המגן (0 = אין מכסה ביד)
var held: Node = null
var _st := 0.0
var _cd := 0.0
var _hint := 0.0
var _side := 0.0
var _shake := 0.0
var _splinter := 0.0
var _pl_x0 := INF


func stats() -> Dictionary:
	return {"name": "COFFIN BREAKER", "hp": 50, "walk": 38.0, "chase": 92.0, "damage": 1, "bite_delay": 1.0, "scale": 1.08, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9484"), "shirt": Color("2a2a30"), "pants": Color("26242a"), "shoe": Color("18161a"),
		"points": 580}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8}


func can_bite() -> bool:
	return false


func setup() -> void:
	var m: Node = z.get_parent()
	patient = m != null and int(m.get_meta("cb_early", 0)) >= EARLY_LEARN
	_set_box(true)
	z._dir = -1.0 if randf() < 0.5 else 1.0


# אזור פגיעה: שוכב בארון / עומד
func _set_box(lying: bool) -> void:
	var r: RectangleShape2D = z._shape.shape
	if lying:
		r.size = Vector2(60, 20) * float(z.sc)
		z._shape.position = Vector2(0.0, -10.0 * z.sc)
	else:
		r.size = Vector2(38.0 * z.wf, 66.0 * z.sc)
		z._shape.position = Vector2(0.0, -33.0 * z.sc)


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if state == COFFIN or state == SCRATCH:
		# הארון בולע את הפגיעה (רסיסי עץ)
		_splinter = 0.12
		Particles.burst(z.get_parent(), hit_pos, "spark", Vector2(-dir.x, -0.5), 3)
		Sfx.play("cb_knock", hit_pos, -2.0, 0.15, 3)
		if src.has("blast"):
			_wake(true)
			return true
		if patient:
			if randf() < 0.3:
				z._popup("...", Color("a09080"), 11, -30.0)
			return false
		if state == COFFIN:
			early = true
			var m: Node = z.get_parent()
			m.set_meta("cb_early", int(m.get_meta("cb_early", 0)) + 1)
			_wake(true)
		return false
	if lid > 0 and (state == CHASE or state == THROW):
		var s := str(src.get("source", "bullet"))
		if (s == "bullet" or s == "melee") and not src.has("blast") and dir.x * z._dir < 0.0:
			var ly: float = (hit_pos.y - z.global_position.y) / z.sc
			if ly > -46.0 and ly < -4.0:
				lid -= 1
				blocks += 1
				_splinter = 0.12
				Sfx.play("cb_knock", hit_pos, 0.0, 0.15, 3, 1.2)
				Particles.burst(z.get_parent(), hit_pos, "spark", Vector2(-dir.x, -0.4), 3)
				if lid <= 0:
					z._popup("LID BROKE", Color("c0a080"), 12, -80.0 * z.sc)
					Chips.burst(z.get_parent(), hit_pos, Vector2(-dir.x, -0.6), 8)
				return false
	return true


func _wake(fast: bool) -> void:
	if state != COFFIN:
		return
	state = SCRATCH
	_st = WARN_T * (0.5 if fast else 1.0) * (0.35 if behind else 1.0)
	woke += 1
	Sfx.play("cb_scratch", z.global_position, 3.0, 0.1, 2)


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_hint -= delta
	_shake = maxf(_shake - delta, 0.0)
	_splinter -= delta
	if z.dead:
		_drop()
		return false
	var has_pl: bool = pl != null and not pl.dead
	var d: Vector2 = pl.global_position - z.global_position if has_pl else Vector2(9999, 0)
	match state:
		COFFIN:
			if has_pl and absf(d.y) < 140.0:
				if patient:
					if absf(d.x) < HINT_R and _side == 0.0:
						_side = signf(d.x) if d.x != 0.0 else 1.0
					if _side != 0.0 and signf(d.x) != _side and absf(d.x) > PASS_D and absf(d.x) < HINT_R:
						behind = true
						z._dir = signf(d.x)
						_wake(true)
				else:
					if absf(d.x) < WAKE_R:
						z._dir = signf(d.x) if d.x != 0.0 else z._dir
						_wake(false)
					elif absf(d.x) < HINT_R and _hint <= 0.0:
						_hint = randf_range(1.4, 2.4)
						_shake = 0.25
						Sfx.play("cb_scratch", z.global_position, -6.0, 0.15, 2)
			return _stay(delta)
		SCRATCH:
			_shake = 0.1
			if Engine.get_physics_frames() % 9 == 0:
				Sfx.play("cb_knock", z.global_position, 0.0, 0.2, 3)
			if _st <= 0.0:
				_burst(pl, d)
			return _stay(delta)
		RISE:
			if _st <= 0.0:
				state = CHASE
				if behind and has_pl:   # פורץ מאחוריך: מזנק
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					z.velocity = Vector2(z._dir * 300.0, -260.0)
			return _stay(delta)
		THROW:
			if has_pl:
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if _st <= 0.0:
				_throw(pl)
				state = CHASE
				_cd = 0.5
			return _stay(delta)
		CHASE:
			# בורח ממנו (או עלית לגג) עם המכסה עוד ביד -> זורק אותו
			if has_pl and lid > 0 and _cd <= 0.0 and (absf(d.x) > FLEE_R or d.y < -90.0) and absf(d.x) < 520.0:
				state = THROW
				_st = THROW_WIND
				return _stay(delta)
			if has_pl and _cd <= 0.0 and pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl.god_mode():
				if absf(d.x) < GRAB_R * z.sc + 10.0 and absf(d.y) < 50.0:
					_grab(pl)
					return _stay(delta)
			return false
		HOLD:
			return _hold(pl, delta)
		STUN:
			if _st <= 0.0:
				state = CHASE
				_cd = GRAB_CD
			return _stay(delta)
	return false


func _burst(pl: Node, d: Vector2) -> void:
	_set_box(false)
	z.velocity = Vector2(0, -180.0)
	Sfx.play("cb_burst", z.global_position, 4.0, 0.08, 2)
	var main: Node = z.get_parent()
	Chips.burst(main, z.global_position + Vector2(0, -10), Vector2.UP, 12)
	Particles.burst(main, z.global_position + Vector2(0, -6), "smoke", Vector2.UP, 6)
	var box := CoffinBox.new()   # הארון הפתוח נשאר על הרצפה
	main.add_child(box)
	box.global_position = z.global_position
	z._alert_t = 10.0
	if behind:
		z._popup("BEHIND YOU", Color("ff8060"), 15, -90.0 * z.sc)
	var far: bool = pl != null and not pl.dead and absf(d.x) > THROW_R and not early
	if early:   # נפתח מוקדם מהירי: המכסה עף לבד, בלי מגן
		lid = 0
		var l := LidShot.new()
		l.harmless = true
		main.add_child(l)
		l.global_position = z.global_position + Vector2(0, -24)
		l.velocity = Vector2(randf_range(-80, 80), -380.0)
		state = RISE
		_st = 0.6
	elif far:
		lid = LID_HP
		state = THROW
		_st = THROW_WIND + 0.25
		z._dir = signf(d.x) if d.x != 0.0 else z._dir
	else:
		lid = 0 if behind else LID_HP
		state = RISE
		_st = 0.15 if behind else 0.4


func _throw(pl: Node) -> void:
	if lid <= 0:
		return
	lid = 0
	thrown += 1
	var l := LidShot.new()
	l.owner_t = self
	z.get_parent().add_child(l)
	l.global_position = z.global_position + Vector2(z._dir * 14.0, -40.0) * z.sc
	var dy: float = (pl.global_position.y - 30.0 - l.global_position.y) if pl != null else 0.0
	l.velocity = Vector2(z._dir * LID_V, clampf(dy * 1.2, -260.0, 200.0) - 90.0)
	Sfx.play("cb_spin", l.global_position, 2.0, 0.1, 2)
	Sfx.play("throw", z.global_position, 2.0)


func lid_hit(hit_player: bool) -> void:
	if hit_player:
		throw_hits += 1


func _grab(pl: Node) -> void:
	state = HOLD
	grabs += 1
	held = pl
	_st = BITE_T
	z.velocity.x = 0.0
	pl.grab(z)
	Sfx.play("cb_knock", pl.global_position, 3.0, 0.1, 2, 0.7)


func _hold(_pl: Node, delta: float) -> bool:
	if held == null or not is_instance_valid(held) or held.dead or held.grabbed_by != z:
		held = null
		state = STUN
		_st = 0.6
		return _stay(delta)
	if _st <= 0.0:
		_st = BITE_T
		bites += 1
		held.hurt(z.damage, Vector2(z._dir * 0.3, -0.2))
		Sfx.play("zhit", held.global_position, 0.0, 0.15, 3, 0.8)
	return _stay(delta)


func on_release() -> void:
	if held != null and is_instance_valid(held):
		held.velocity = Vector2(-z._dir * 160.0, -180.0)
	held = null
	state = STUN
	_st = STUN_T
	z._popup("SHAKEN OFF", Color("c0c8b0"), 11, -80.0 * z.sc)


func _drop() -> void:
	if held != null and is_instance_valid(held):
		if held.grabbed_by == z:
			held.grabbed_by = null
	held = null


func on_death() -> void:
	_drop()


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  המכסה הנזרק: קרש מתומן מסתובב, עם צלב. פוגע בשחקן (1), נשבר בקיר. harmless = רק עף (פתיחה מוקדמת)
# ============================================================
class LidShot extends Node2D:
	var owner_t = null
	var velocity := Vector2.ZERO
	var harmless := false
	var _t := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 6

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += 420.0 * delta
		var to := global_position + velocity * delta
		var pl := get_tree().get_first_node_in_group("player")
		if not harmless and pl != null and not pl.dead and pl.body_rect().grow(14.0).has_point(to):
			pl.hurt(1, Vector2(signf(velocity.x) * 1.5, -0.6))
			_end(true)
			return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
		if (not hit.is_empty() and velocity.y > -50.0) or _t > 3.0:
			_end(false)
			return
		global_position = to
		rotation += delta * 14.0 * signf(velocity.x if velocity.x != 0.0 else 1.0)
		if Art.on_screen(self, global_position, 60.0):
			queue_redraw()

	func _end(hit_player: bool) -> void:
		if _done:
			return
		_done = true
		if owner_t != null and owner_t.z != null and is_instance_valid(owner_t.z):
			owner_t.lid_hit(hit_player)
		Chips.burst(get_parent(), global_position, -velocity.normalized(), 10)
		Sfx.play("cb_knock", global_position, 2.0, 0.1, 3, 0.8)
		queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		CoffinBox.lid_shape(self, Vector2.ZERO, 1.0)


# ============================================================
#  רסיסי עץ (שבבים חומים שעפים ונופלים)
# ============================================================
class Chips extends Node2D:
	var _p: Array = []
	var _t := 0.0

	static func burst(parent: Node, pos: Vector2, dir: Vector2, n: int) -> void:
		if parent == null:
			return
		var c := Chips.new()
		n = Quality.scaled(n, Quality.particles())
		for i in n:
			var a := dir.angle() + randf_range(-1.2, 1.2)
			c._p.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(80, 240), randf() * TAU, randf_range(2.0, 4.5), Color("5a3a24").lerp(Color("8a6a44"), randf())])
		parent.add_child(c)
		c.global_position = pos

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.9:
			queue_free()
			return
		for q in _p:
			q[1].y += 620.0 * delta
			q[0] += q[1] * delta
			q[2] += delta * 12.0
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := clampf(1.6 - _t * 1.8, 0.0, 1.0)
		for q in _p:
			var d: Vector2 = Vector2.from_angle(q[2]) * q[3]
			var c: Color = q[4]
			c.a = a
			DrawBatch.line(self, q[0] - d, q[0] + d, c, 1.6)


# ============================================================
#  הארון הפתוח שנשאר על הרצפה אחרי הפריצה (נעלם לאט)
# ============================================================
class CoffinBox extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = 2
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if _t > 25.0:
			modulate.a -= delta
			if modulate.a <= 0.0:
				queue_free()
				return
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		box_shape(self, Vector2.ZERO, true)

	# ארון מתומן שוכב (צורה קלאסית: רחב בכתפיים). open = בלי מכסה, רואים בטנה אדומה בפנים
	static func box_shape(ci: CanvasItem, o: Vector2, open: bool) -> void:
		var wood := Color("4a2e1e")
		var pts := PackedVector2Array([o + Vector2(-32, -2), o + Vector2(-26, -14), o + Vector2(14, -16), o + Vector2(32, -12), o + Vector2(32, -2), o + Vector2(14, 0), o + Vector2(-26, 0)])
		Art.fill_shaded(ci, pts, wood, 0.12, 0.35)
		if open:
			DrawBatch.colored_polygon(ci, PackedVector2Array([o + Vector2(-27, -12), o + Vector2(14, -14), o + Vector2(29, -11), o + Vector2(29, -6), o + Vector2(14, -8), o + Vector2(-27, -6)]), Color("5a1418"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([o + Vector2(-27, -6), o + Vector2(14, -8), o + Vector2(29, -6), o + Vector2(14, -5), o + Vector2(-27, -4)]), Color("2a0a0c"))
		for h in [Vector2(-18, -4), Vector2(2, -4), Vector2(22, -4)]:   # ידיות פליז
			DrawBatch.line(ci, o + h + Vector2(-3, 0), o + h + Vector2(3, 0), Color("a08040"), 1.5)

	static func lid_shape(ci: CanvasItem, c: Vector2, a: float) -> void:
		var wood := Color("5a3a24")
		wood.a = a
		var pts := PackedVector2Array([c + Vector2(-30, 0), c + Vector2(-24, -6), c + Vector2(14, -7), c + Vector2(30, -4), c + Vector2(30, 3), c + Vector2(14, 6), c + Vector2(-24, 5), c + Vector2(-30, 2)])
		Art.fill_shaded(ci, pts, wood, 0.15, 0.3)
		DrawBatch.line(ci, c + Vector2(-14, -0.5), c + Vector2(10, -0.5), Color("c8b070", a), 1.6)   # צלב על המכסה
		DrawBatch.line(ci, c + Vector2(4, -4), c + Vector2(4, 3.5), Color("c8b070", a), 1.6)


# ============================================================
#  ציור: בארון - רק הארון (מכסה רועד, אצבעות בסדק). בחוץ - זומבי בחליפת קבורה מתפוררת, תכריכים,
#  מטבעות על העיניים, וידיים עם ציפורניים שבורות. מגן = המכסה ביד הקדמית.
# ============================================================
func draw() -> bool:
	if state == COFFIN or state == SCRATCH:
		_draw_coffin()
		return true
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var rise_k := 1.0
	if state == RISE:
		rise_k = clampf(1.0 - _st / 0.5, 0.0, 1.0)
	var hip := Vector2(0, -22.0 + 8.0 * (1.0 - rise_k))
	var sh := Vector2(4, -39.0 + 14.0 * (1.0 - rise_k))
	var head := sh + Vector2(4, -7)
	if state == STUN:
		sh += Vector2(-3, 2)
		head = sh + Vector2(0, -6)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית: מושטת קדימה (תופס)
	var reach := state == CHASE or state == HOLD
	var hb := sh + Vector2(14, 6) if reach else sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	if state == HOLD:
		hb = sh + Vector2(18, 2 + sin(z._time * 20.0))
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(suit, 0.3))
	_nails(hb, true)
	# גוף: חליפת קבורה קרועה + תכריכים
	var torso := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(8, 2), hip + Vector2(-8, 2)])
	Art.fill_shaded(z, torso, suit, 0.1, 0.35)
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-1, 0), sh + Vector2(5, 0), hip + Vector2(3, -6), hip + Vector2(0, -6)]), col(Color("b8b0a0")))   # חולצה לבנה
	DrawBatch.line(z, sh + Vector2(2, 1), sh + Vector2(2, 9), col(Color("2a1a1a")), 1.4)   # עניבה
	for q in 3:   # תכריכים תלויים
		var a := sh + Vector2(-7.0 + float(q) * 5.0, 3.0 + float(q) * 4.0)
		DrawBatch.line(z, a, a + Vector2(-3.0 + sin(z._time * 2.0 + float(q)) * 2.0, 12.0), col(Color(0.8, 0.78, 0.7, 0.75)), 2.0)
	DrawBatch.colored_polygon(z, Art.ellipse(sh.lerp(hip, 0.5) + Vector2(-3, 0), 2.5, 3.0, 0.0, 8), col(Color("3a4434")))   # קרע ברקבון
	# ראש
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-5, -2), head + Vector2(-3, -6), head + Vector2(3, -6.5), head + Vector2(5, -4), head + Vector2(0, -4)]), col(Color("3a3430")))   # שיער מסורק לקבורה
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(2.4, -0.6), 1.7, col(Color("b89040")))   # מטבע על העין
		DrawBatch.circle(z, head + Vector2(2.4, -0.6), 0.9, col(Color("806020")))
		DrawBatch.line(z, head + Vector2(1.0, 3.2), head + Vector2(4.6, 2.6), col(Color("2a1414")), 1.0)
		if state == HOLD:
			DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(3.5, 3.0), 2.0, 2.4, 0.0, 8), col(Color("200808")))
	# יד קדמית: מגן (מכסה) / זריקה / תפיסה
	var hf := sh + Vector2(12, 8)
	if state == THROW:
		var k := clampf(1.0 - _st / (THROW_WIND + 0.25), 0.0, 1.0)
		hf = sh + Vector2(-10.0 + 8.0 * k, -16.0)
	elif reach:
		hf = sh + Vector2(17, 0)
	z._arm(sh + Vector2(4, 1), hf, sk, suit)
	if lid > 0:
		if state == THROW:
			_lid_held(hf + Vector2(-2, -6), -1.2)
		else:
			_lid_held(hf + Vector2(6, -6), 0.0)
	else:
		_nails(hf, false)
	if _splinter > 0.0 and lid > 0:
		DrawBatch.circle(z, hf + Vector2(8, -6), 6.0, Color(1, 0.9, 0.7, 0.35))
	end_draw()
	return true


func _lid_held(c: Vector2, rot: float) -> void:
	var a := col(Color("5a3a24"))
	var w := 0.5 + 0.5 * float(lid) / float(LID_HP)
	var pts := PackedVector2Array()
	for v in [Vector2(-4, -30), Vector2(3, -26), Vector2(4, 14), Vector2(2, 28), Vector2(-3, 28), Vector2(-5, 14)]:
		pts.append(c + (v * Vector2(1.0, 0.85)).rotated(rot))
	Art.fill_shaded(z, pts, a, 0.15, 0.3)
	var cr := col(Color("c8b070"))
	DrawBatch.line(z, c + Vector2(0, -16).rotated(rot), c + Vector2(0, 8).rotated(rot), cr, 1.4)
	DrawBatch.line(z, c + Vector2(-3, -9).rotated(rot), c + Vector2(3, -9).rotated(rot), cr, 1.4)
	if w < 0.9:   # סדקים במגן
		DrawBatch.line(z, c + Vector2(-3, -4), c + Vector2(2, 4), col(Color("1a0e08")), 1.0)
	if w < 0.7:
		DrawBatch.line(z, c + Vector2(2, -18), c + Vector2(-2, -10), col(Color("1a0e08")), 1.0)


func _nails(h: Vector2, back: bool) -> void:
	var c := col(Color("d8d0b0") if not back else Color("a8a088"))
	for q in 3:
		DrawBatch.line(z, h, h + Vector2(3.0, -2.0 + float(q) * 2.0), c, 0.9)


func _draw_coffin() -> void:
	# בלי היפוך לפי כיוון - הארון לא מסתובב
	var s: float = z.sc
	DrawBatch.set_transform(z, Vector2(randf_range(-1, 1) * (1.5 if _shake > 0.0 else 0.0), 0), 0.0, Vector2(s, s))
	Art.ground_shadow(z, Vector2.ZERO, 34.0)
	CoffinBox.box_shape(z, Vector2.ZERO, false)
	# המכסה: קופץ בזמן הגירוד
	var lift := 0.0
	if state == SCRATCH:
		lift = absf(sin(z._time * 26.0)) * 3.0 + (1.0 - clampf(_st / WARN_T, 0.0, 1.0)) * 3.0
	elif _shake > 0.0:
		lift = absf(sin(z._time * 30.0)) * 1.5
	CoffinBox.lid_shape(z, Vector2(0, -17.0 - lift), 1.0)
	if _splinter > 0.0:
		DrawBatch.circle(z, Vector2(0, -14), 10.0, Color(1, 0.9, 0.7, 0.3))
	if state == SCRATCH:   # אצבעות יוצאות מהסדק
		var k := 1.0 - clampf(_st / WARN_T, 0.0, 1.0)
		for q in 4:
			var x := -6.0 + float(q) * 4.0
			var ln := 3.0 + 5.0 * k + sin(z._time * 18.0 + float(q)) * 1.5
			DrawBatch.line(z, Vector2(x, -15.0 - lift * 0.5), Vector2(x + 1.0, -15.0 - lift * 0.5 - ln), col(z.skin), 2.0)
			DrawBatch.line(z, Vector2(x + 1.0, -15.0 - lift * 0.5 - ln), Vector2(x + 1.5, -15.0 - lift * 0.5 - ln - 1.5), Color("d8d0b0"), 1.0)
		DrawBatch.line(z, Vector2(-28, -11 - lift), Vector2(30, -9 - lift), Color(0.1, 0.05, 0.03, 0.8), 1.5)
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
