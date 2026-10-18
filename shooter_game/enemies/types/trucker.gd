extends "res://enemies/zombie_type.gd"
# ============================================================
#  TRUCKER - "EL CAMIONERO" (הבוס של שלב 28, "DEATH ROAD") - נהג משאית ענק, כובע מצחייה, חולצת ג'ינס,
#  צמיג משאית על הכתף. 40 שנה נהג בדרך המוות - ועכשיו הוא הדרך.
#    WALK   - הולך אליך לאט
#    REV    - רוקע ברגליים, צופר המשאית (REV_T) = אזהרה!
#    CHARGE - מסתער כמו משאית בלי בלמים (CHARGE_V). פגיעה = נזק + הדף. קופץ מעל בורות.
#    CRASH  - נתקע במכשול (אוטובוס, משאית, סלעים): המום (CRASH_T), נפגע כפול  <- המטרה: לעמוד מול מכשול ולהתחמק ברגע האחרון
#    SKID   - פספס בשטח פתוח: מחליק ומסתובב
#    THROW  - זורק צמיג (Tire) שקופץ ומתגלגל - קופצים מעליו
#  "THEY LEARN": אחרי LEARN_AT התרסקויות הוא לא מסתער כשיש מכשול מאחוריך - זורק צמיגים במקום.
#  חצי חיים: אזהרה קצרה יותר, וזורק שני צמיגים ברצף.
#  לשנות: REV_T, CHARGE_V, OVERSHOOT, CRASH_T, LEARN_AT, TIRE_V.
# ============================================================

const SOUNDS := {
	"tr_horn": {"drive": 2.6, "layers": [["Q", 220, 218, 0.0, 0.85, 0.02, 0.8, 0.3, 0.6, 0], ["Q", 277, 275, 0.0, 0.85, 0.02, 0.8, 0.26, 0.6, 0], ["S", 110, 110, 0.0, 0.85, 0.02, 0.8, 0.3, 1.0, 0]]},
	"tr_crash": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 1.2, 0.4, 0], ["S", 90, 36, 0.0, 0.45, 0.0, 6.0, 1.1, 1.0, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.6, 1.0, 0]]},
	"tr_stomp": [["S", 72, 40, 0.0, 0.18, 0.0, 16.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.3, 0.2, 0]],
	"tr_bounce": [["S", 140, 80, 0.0, 0.12, 0.0, 24.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.06, 0.0, 50.0, 0.2, 0.3, 0]],
}

const REV_T := 0.9
const CHARGE_V := 470.0
const OVERSHOOT := 260.0
const CRASH_T := 2.2
const SKID_T := 0.8
const LEARN_AT := 2
const TIRE_V := 330.0
const DAMAGE := 2

enum { WALK, REV, CHARGE, CRASH, SKID, THROW }
var state := WALK
var charges := 0             # לבדיקות
var crashes := 0
var tires := 0
var hits := 0
var learned := false
var _st := 0.0
var _cd := 2.0
var _target_x := 0.0
var _hit_done := false
var _throws := 0
var _stomp := 0.0
var _charge_t := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "TRUCKER", "hp": 340, "walk": 46.0, "chase": 72.0, "damage": 2, "bite_delay": 0.9, "scale": 1.75, "width": 1.25,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9474"), "shirt": Color("3e5a7a"), "pants": Color("4a3a2a"), "shoe": Color("2a2018"),
			"points": 1400, "boss": true, "boss_name": "EL CAMIONERO - MAKE HIM CRASH"}
	return {"name": "TRUCKER", "hp": 110, "walk": 44.0, "chase": 70.0, "damage": 2, "bite_delay": 0.9, "scale": 1.3, "width": 1.2,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9474"), "shirt": Color("3e5a7a"), "pants": Color("4a3a2a"), "shoe": Color("2a2018"), "points": 700}


func setup() -> void:
	z.set_meta("pit_hop", true)


func can_bite() -> bool:
	return state == WALK


func damage_mult(_zone: String, _src: Dictionary) -> float:
	match state:
		CRASH:
			return 2.0
		SKID:
			return 1.3
	return 1.0


func _rage() -> bool:
	return float(z.hp) < float(z.max_hp) * 0.5


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_stomp -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var d := Vector2.ZERO
	if has_pl:
		d = pl.global_position - z.global_position
	match state:
		WALK:
			if has_pl and _cd <= 0.0 and z.is_on_floor() and absf(d.x) > 150.0 and absf(d.x) < 720.0:
				z._dir = signf(d.x)
				if absf(d.y) > 60.0 or (learned and _wall_behind(pl)):   # על הכביש העליון / למד שמכשול = התרסקות
					_start_throw()
				else:
					state = REV
					_st = REV_T * (0.65 if _rage() else 1.0)
					Sfx.play("tr_horn", z.global_position, 4.0, 0.05, 1)
				return _brake(delta)
			return false
		REV:
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if _stomp <= 0.0:   # רוקע (אבק)
				_stomp = 0.3
				Sfx.play("tr_stomp", z.global_position, -2.0, 0.1, 2)
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 10.0, -4.0), "smoke", Vector2(-z._dir, -0.3), 2)
			if _st <= 0.0:
				state = CHARGE
				charges += 1
				_charge_t = 0.0
				_hit_done = false
				_target_x = (pl.global_position.x if has_pl else z.global_position.x + z._dir * 300.0) + z._dir * OVERSHOOT
			return _brake(delta)
		CHARGE:
			var v := CHARGE_V * (1.12 if _rage() else 1.0)
			_charge_t += delta
			z.velocity.x = move_toward(z.velocity.x, z._dir * v, 1500.0 * delta)
			_hop_pits()
			if has_pl and not _hit_done:
				var b := Rect2(z.global_position + Vector2(-24.0, -50.0) * z.sc, Vector2(48.0, 50.0) * z.sc)
				if pl.body_rect().grow(4.0).intersects(b):
					_hit_done = true
					hits += 1
					pl.hurt(DAMAGE, Vector2(z._dir * 2.6, -1.3))
			for o in z.get_tree().get_nodes_in_group("zombies"):   # דורס זומבים בדרך
				if o != z and not o.dead and absf(o.global_position.x - z.global_position.x) < 30.0 * z.sc and absf(o.global_position.y - z.global_position.y) < 30.0:
					o.take_damage(25, o.global_position + Vector2(0, -20), Vector2(z._dir, -0.4), false, {"source": "trucker"})
			_move(delta)
			if z.is_on_wall() and _charge_t > 0.3:   # התרסק במכשול
				_crash()
			elif _charge_t > 2.5 or (z._dir > 0.0 and z.global_position.x > _target_x) or (z._dir < 0.0 and z.global_position.x < _target_x) or z.global_position.x <= 40.0 or z.global_position.x >= float(z.world_w) - 40.0:
				state = SKID
				_st = SKID_T
				Sfx.play("bk_skid", z.global_position, 0.0, 0.1, 2)
			return true
		CRASH:
			if Engine.get_physics_frames() % 10 == 0 and Art.on_screen(z, z.global_position):   # כוכבים / אדים
				Particles.burst(z.get_parent(), z.global_position + Vector2(0, -62.0) * z.sc, "smoke", Vector2.UP, 1)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(1.0, 1.8)
			return _brake(delta)
		SKID:
			if Engine.get_physics_frames() % 4 == 0 and absf(z.velocity.x) > 60.0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2(-z._dir, -0.3), 1)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(1.4, 2.4)
			return _brake(delta, 700.0)
		THROW:
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if _st <= 0.0:
				_throw(pl)
				_throws -= 1
				if _throws > 0:
					_st = 0.55
				else:
					state = WALK
					_cd = randf_range(1.6, 2.6)
			return _brake(delta)
	return false


func _brake(delta: float, k := 1200.0) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, k * delta)
	_move(delta)
	return true


func _move(delta: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	z.global_position.x = clampf(z.global_position.x, 30.0, float(z.world_w) - 30.0)


func _hop_pits() -> void:   # קופץ מעל בורות בזמן הסתערות
	if not z.is_on_floor():
		return
	for w in z.get_tree().get_nodes_in_group("washouts"):
		var edge: float = w.global_position.x if z._dir > 0.0 else w.global_position.x + float(w.w)
		var ahead: float = (edge - z.global_position.x) * z._dir
		if ahead > 0.0 and ahead < 70.0:
			z.velocity.y = -560.0
			return


# יש מכשול מוצק מאחורי השחקן (בכיוון ההסתערות)?
func _wall_behind(pl: Node) -> bool:
	var from: Vector2 = pl.global_position + Vector2(0.0, -20.0)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(z._dir * 300.0, 0.0), 1)
	var ex: Array[RID] = [z.get_rid()]
	q.exclude = ex
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and not hit.collider.is_in_group("zombies")


func _crash() -> void:
	state = CRASH
	_st = CRASH_T
	crashes += 1
	z.velocity = Vector2(-z._dir * 160.0, -180.0)
	Sfx.play("tr_crash", z.global_position, 6.0, 0.05, 1)
	z.take_damage(int(float(z.max_hp) * 0.06), z.global_position + Vector2(z._dir * 20.0, -50.0) * z.sc, Vector2(-z._dir, 0.0), false, {"source": "crash"})
	Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 24.0, -40.0) * z.sc, "spark", Vector2(-z._dir, -0.5), 12)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(14.0, 0.45)
	z._popup("CRASHED!", Color("ffd060"), 20, -140.0)
	if crashes >= LEARN_AT and not learned:
		learned = true
		_popup_later.call_deferred()


func _popup_later() -> void:
	if z != null and is_instance_valid(z) and not z.dead:
		z._popup("HE LEARNED - NO MORE WALLS", Color("ff7050"), 15, -175.0)


func _start_throw() -> void:
	state = THROW
	_st = 0.5
	_throws = 2 if _rage() else 1


func _throw(pl: Node) -> void:
	tires += 1
	var t := Tire.new()
	t.ground_y = z.global_position.y
	z.get_parent().add_child(t)
	t.global_position = z.global_position + Vector2(z._dir * 26.0, -70.0) * z.sc
	var tx: float = pl.global_position.x if pl != null else t.global_position.x + z._dir * 300.0
	var ty: float = pl.global_position.y - 14.0 if pl != null else z.global_position.y
	var flight := clampf(absf(tx - t.global_position.x) / TIRE_V, 0.45, 1.3)
	t.velocity = Vector2((tx - t.global_position.x) / flight, (ty - t.global_position.y) / flight - 0.5 * t.gravity * flight)
	if ty < z.global_position.y - 60.0:   # על הכביש העליון: נוחת שם
		t.ground_y = ty + 14.0
	Sfx.play("throw", z.global_position, 2.0)


# ============================================================
#  צמיג: עף בקשת, קופץ על הכביש ומתגלגל. פגיעה = נזק + הדף. קופצים מעליו.
# ============================================================
class Tire extends Node2D:
	const R := 15.0
	var velocity := Vector2.ZERO
	var gravity := 1200.0
	var ground_y := 630.0
	var _t := 0.0
	var _rot := 0.0
	var _hit := false

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += gravity * delta
		var to := global_position + velocity * delta
		if to.y > ground_y - R and velocity.y > 0.0 and not _over_pit(to.x):
			to.y = ground_y - R
			if velocity.y > 160.0:
				velocity.y = -velocity.y * 0.42
				preload("res://sfx.gd").play("tr_bounce", to, -2.0, 0.1, 3)
			else:
				velocity.y = 0.0
		var wall := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + Vector2(signf(velocity.x) * R, 0.0), 1))
		if not wall.is_empty() and not wall.collider.is_in_group("zombies") and absf(wall.normal.x) > 0.5:
			velocity.x = -velocity.x * 0.5
			to.x = global_position.x
		var pl := get_tree().get_first_node_in_group("player")
		if not _hit and pl != null and not pl.dead and pl.body_rect().grow(R * 0.6).has_point(to):
			_hit = true
			pl.hurt(1, Vector2(signf(velocity.x) * 1.6, -0.8))
			velocity.x *= 0.4
		global_position = to
		_rot += velocity.x * delta / R
		if _t > 4.0 or global_position.y > ground_y + 300.0:
			queue_free()
			return
		queue_redraw()

	func _over_pit(x: float) -> bool:
		for w in get_tree().get_nodes_in_group("washouts"):
			if x > w.global_position.x + 4.0 and x < w.global_position.x + float(w.w) - 4.0 and absf(w.global_position.y - ground_y) < 4.0:
				return true
		return false

	func _draw() -> void:
		DrawBatch.circle(self, Vector2.ZERO, R + 1.5, Color("0e0e0e"))
		DrawBatch.circle(self, Vector2.ZERO, R, Color("262628"))
		DrawBatch.circle(self, Vector2.ZERO, R * 0.5, Color("5a5a5e"))
		DrawBatch.circle(self, Vector2.ZERO, R * 0.25, Color("2a2a2c"))
		for k in 8:   # חריצים
			var a := _rot + float(k) * TAU / 8.0
			DrawBatch.line(self, Vector2.from_angle(a) * (R - 4.0), Vector2.from_angle(a) * R, Color("3a3a3e"), 2.0)


# ============================================================
#  ציור: גוף ענק עם כרס, חולצת ג'ינס עם שרוולים מקופלים, כובע מצחייה, צמיג על הכתף.
#  REV: רוקע. CHARGE: ראש למטה, ידיים קדימה. CRASH: מתנדנד המום.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.5, 3.0)
	var lean := 0.0
	if state == CHARGE:
		lean = 7.0
	elif state == REV:
		lean = 3.0 + sin(z._time * 22.0) * 1.5
	var hip := Vector2(0, -22)
	var sh := Vector2(2.0 + lean, -40.0 + lean * 0.4)
	var head := sh + Vector2(4.0 + lean * 0.3, -9.0)
	if state == CRASH:
		head += Vector2(sin(z._time * 9.0) * 2.0, 1.0)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# צמיג על הגב/כתף (התחמושת שלו)
	if not (state == THROW and _st < 0.2):
		var tc := sh + Vector2(-9, 4)
		DrawBatch.circle(z, tc, 10.5, Art.OUTLINE)
		DrawBatch.circle(z, tc, 9.0, col(Color("2a2a2c")))
		for k in 8:   # חריצי הצמיג
			var ta := float(k) * TAU / 8.0
			DrawBatch.line(z, tc + Vector2.from_angle(ta) * 6.5, tc + Vector2.from_angle(ta) * 9.0, col(Color("46464a")), 1.6)
		DrawBatch.circle(z, tc, 4.2, col(Color("8a8a90")))
		DrawBatch.circle(z, tc, 2.0, col(Color("3a3a3e")))
		DrawBatch.line(z, tc + Vector2(-8, -6), sh + Vector2(4, 2), col(Color("5a4030")), 1.6)   # רצועה
	var hb := sh + Vector2(-6.0 - sin(p) * 3.0, 17.0)
	var hf := sh + Vector2(10.0 + sin(p) * 3.0, 15.0)
	if state == CHARGE:
		hb = sh + Vector2(14, 4)
		hf = sh + Vector2(17, 8)
	elif state == THROW:
		hf = sh + Vector2(-4.0, -14.0) if _st > 0.2 else sh + Vector2(18.0, -4.0)
	elif state == CRASH:
		hb = sh + Vector2(-10, 16)
		hf = sh + Vector2(6, 20)
	z._arm(sh + Vector2(-4, 1), hb, Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	# גוף עם כרס
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(11, -4), hip + Vector2(8, 3), hip + Vector2(-8, 3), hip + Vector2(-9, -4)]), shirt, 0.12, 0.4)
	Art.oval_shaded(z, hip + Vector2(5, -8), 7.0, 7.0, sk, 0.0)   # כרס מבצבצת
	DrawBatch.line(z, sh + Vector2(1, 0), hip + Vector2(3, -2), col(Color("2a3e56")), 1.2)   # כפתורים פתוחים
	Art.oval_shaded(z, head, 6.0, 6.2, sk, 0.0)
	DrawBatch.circle(z, head + Vector2(2.0, 3.5), 3.5, col(Color(0.25, 0.25, 0.22, 0.4)))   # זיפים
	# כובע מצחייה
	Art.fill(z, PackedVector2Array([head + Vector2(-6, -2), head + Vector2(-5, -7), head + Vector2(2, -9), head + Vector2(6, -6), head + Vector2(6, -3)]), col(Color("b02a2a")), Art.OUTLINE, 1.0)
	DrawBatch.line(z, head + Vector2(5, -3), head + Vector2(12, -2), col(Color("8a1e1e")), 2.2)
	if not z.dead:
		var ec := Color(1.0, 0.85, 0.3) if state in [REV, CHARGE] else Color(0.8, 0.85, 0.5)
		DrawBatch.circle(z, head + Vector2(3.5, -0.5), 1.1, ec)
		if state == CRASH:   # המום: כוכבים מעל הראש
			for k in 3:
				var a: float = z._time * 4.0 + float(k) * TAU / 3.0
				DrawBatch.circle(z, head + Vector2(cos(a) * 9.0, -14.0 + sin(a) * 2.5), 1.4, Color(1.0, 0.95, 0.5))
	z._arm(sh + Vector2(4, 1), hf, sk, shirt)
	if state == THROW and _st > 0.2:   # הצמיג מורם מעל הראש
		DrawBatch.circle(z, hf + Vector2(0, -6), 10.0, Art.OUTLINE)
		DrawBatch.circle(z, hf + Vector2(0, -6), 8.5, col(Color("262628")))
		DrawBatch.circle(z, hf + Vector2(0, -6), 4.0, col(Color("4a4a4e")))
	end_draw()
	return true
