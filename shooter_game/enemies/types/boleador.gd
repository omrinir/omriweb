extends "res://enemies/zombie_type.gd"
# ============================================================
#  BOLEADOR (שלב 47, "PAMPAS STORM") - גאוצ'ו מת: כובע רחב שוליים, פונצ'ו, בומבאצ'ה, מגפי עור.
#  זורק בולאדורס - שלוש אבנים עטופות עור על חבלים, כמו שציידו נאנדו בפמפס.
#    WALK  - שומר מרחק (keep_range).
#    SPIN  - מסובב את הבולאדורס מעל הראש (SPIN_T) - אזהרה (שריקה + עיגול).
#    THROW - הבולאדורס עפות אליך בקשת (Bola). פגיעה = נכרכות לך על הרגליים (Tangle): אתה לא זז ולא קופץ
#            עד שמשתחררים (A/D לסירוגין) או עד TANGLE_T. ואז כולם רצים אליך...
#  התחמקות: לירות בבולאדורס באוויר (Bola.Hitbox - שכבה 4 כמו זומבי), לקפוץ / להתגלגל.
#  "THEY LEARN TOGETHER": כל בולאדורס שפספסה בזמן שרצת -> כל הבוליאדורים מקדימים יותר את הריצה שלך
#    (main meta "bola_lead", עד LEAD_MAX). קפצת מעליה -> הבאות עפות גבוה יותר ("bola_high").
#  לשנות: KEEP, BACKOFF, RANGE, SPIN_T, CD, BOLA_V, TANGLE_T, LEAD_STEP, LEAD_MAX.
# ============================================================

const SOUNDS := {
	"bl_whirl": [["N", 0, 0, 0.0, 0.9, 0.1, 1.0, 0.35, 0.35, 0, 0.9], ["S", 220, 300, 0.0, 0.9, 0.1, 1.0, 0.12, 1.0, 0.25]],
	"bl_throw": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.5, 0.5, 0, 0.6]],
	"bl_wrap": [["N", 0, 0, 0.0, 0.2, 0.0, 16.0, 0.6, 0.3, 0], ["C", 0, 0, 0.0, 0.15, 0.0, 20.0, 0.6, 1.0, 0], ["S", 160, 90, 0.0, 0.1, 0.0, 30.0, 0.4, 1.0, 0]],
}

const KEEP := 260.0
const BACKOFF := 130.0      # קרוב מזה - נסוג (אלא אם אתה כרוך - אז הוא בא לנשוך)
const RANGE := 640.0
const SPIN_T := 0.9
const CD := Vector2(2.6, 3.8)
const BOLA_V := 430.0
const TANGLE_T := 2.0
const LEAD_STEP := 0.15
const LEAD_MAX := 0.6

enum { WALK, SPIN }
var state := WALK
var throws := 0              # לבדיקות
var tangles := 0
var _st := 0.0
var _cd := 1.5


func stats() -> Dictionary:
	return {"name": "BOLEADOR", "hp": 34, "walk": 44.0, "chase": 92.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 1.0,
		"duck": 0.2, "cover": 0.4, "skin": Color("8c9a80"), "shirt": Color("5a3a2a"), "pants": Color("d8d0bc"), "shoe": Color("3a2414"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.25, "keep_range": KEEP}


func can_bite() -> bool:
	return state == WALK


static func lead(main: Node) -> float:
	return float(main.get_meta("bola_lead")) if main.has_meta("bola_lead") else 0.0


static func high(main: Node) -> float:
	return float(main.get_meta("bola_high")) if main.has_meta("bola_high") else 0.0


func learn(how: String) -> void:   # נקרא מהבולה שפספסה
	var m: Node = z.get_parent()
	if how == "run":
		var l := minf(lead(m) + LEAD_STEP, LEAD_MAX)
		if l > lead(m):
			m.set_meta("bola_lead", l)
			z._popup("THEY LEAD YOUR RUN", Color("ffd080"), 12, -78.0)
	elif how == "jump":
		m.set_meta("bola_high", minf(high(m) + 16.0, 40.0))
		z._popup("THEY THROW HIGH", Color("ffd080"), 12, -78.0)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if has_pl and _cd <= 0.0 and z.is_on_floor() and pl.grabbed_by == null:
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees or absf(d.x) < 380.0
				if sees and absf(d.x) < RANGE and absf(d.x) > 70.0 and d.y > -260.0 and d.y < 300.0:
					state = SPIN
					_st = SPIN_T
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					Sfx.play("bl_whirl", z.global_position, -4.0, 0.1, 2)
					return _stay(delta)
			if has_pl and z.is_on_floor():   # קרוב מדי: נסוג אחורה כדי לזרוק שוב
				var dd: Vector2 = pl.global_position - z.global_position
				if absf(dd.x) < BACKOFF and absf(dd.y) < 60.0 and not z.is_on_wall() and pl.grabbed_by == null:
					z._dir = signf(dd.x) if dd.x != 0.0 else z._dir
					z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.8, 700.0 * delta)
					z.velocity.y += z.gravity * delta
					z.move_and_slide()
					return true
			return false
		SPIN:
			if has_pl:
				var d2: Vector2 = pl.global_position - z.global_position
				z._dir = signf(d2.x) if absf(d2.x) > 4.0 else z._dir
			if _st <= 0.0:
				if has_pl:
					_throw(pl)
				state = WALK
				_cd = randf_range(CD.x, CD.y)
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 4.0, -62.0) * z.sc


func _throw(pl: Node) -> void:
	throws += 1
	var from := hand()
	var m: Node = z.get_parent()
	var vx: float = pl.velocity.x if absf(pl.velocity.x) > 40.0 else 0.0
	var tgt: Vector2 = pl.global_position + Vector2(0, -14.0 - high(m))
	var t0: float = absf(tgt.x - from.x) / BOLA_V
	tgt.x += vx * lead(m) * minf(t0 * 2.0, 1.6)
	var dx: float = tgt.x - from.x
	var t: float = maxf(absf(dx) / BOLA_V, 0.25)
	var g := Bola.G
	var b := Bola.new()
	b.owner_t = self
	b.velocity = Vector2(dx / t, (tgt.y - from.y - 0.5 * g * t * t) / t)
	b.moving = absf(vx) > 0.0
	b.tangle_t = TANGLE_T
	z.get_parent().add_child(b)
	b.global_position = from
	Sfx.play("bl_throw", from, 0.0, 0.1, 3)


func on_death() -> void:
	state = WALK


# ============================================================
#  הבולאדורס: שלוש אבנים על חבלים שמסתובבות סביב מרכז ועפות בקשת.
# ============================================================
class Bola extends Node2D:
	const A := preload("res://art.gd")
	const G := 520.0
	var owner_t = null
	var tangle_t := 2.0
	var velocity := Vector2.ZERO
	var moving := false          # השחקן רץ כשזרקו (למידה)
	var _t := 0.0
	var _passed := false
	var _done := false
	var _hb: StaticBody2D = null

	class Hitbox extends StaticBody2D:   # יורים בבולאדורס באוויר
		var b = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if b != null:
				b.shot_down()

	func _ready() -> void:
		z_index = 9
		var h := Hitbox.new()
		h.b = self
		h.collision_layer = 4
		h.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = 13.0
		cs.shape = sh
		h.add_child(cs)
		add_child(h)
		_hb = h

	func shot_down() -> void:
		if _done:
			return
		_done = true
		var P := preload("res://particles.gd")
		P.burst(get_parent(), global_position, "smoke", Vector2.UP, 3)
		preload("res://sfx.gd").play("clink", global_position, 0.0, 0.1, 3)
		if is_instance_valid(_hb):
			_hb.queue_free()
		queue_free()

	func _physics_process(delta: float) -> void:
		if _done:
			return
		_t += delta
		velocity.y += G * delta
		var to := global_position + velocity * delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.body_rect().grow(10.0).has_point(to):
			_wrap(pl)
			return
		if pl != null and not pl.dead and not _passed and absf(to.x - pl.global_position.x) < 12.0:
			_passed = true
			if owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead:
				if not pl.is_on_floor() and to.y > pl.global_position.y - 20.0:
					owner_t.learn("jump")
				elif moving:
					owner_t.learn("run")
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))
		if not hit.is_empty() or _t > 3.0:
			if not hit.is_empty():
				preload("res://particles.gd").burst(get_parent(), hit.position, "smoke", Vector2.UP, 2)
			if not _passed and moving and pl != null and owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead:
				owner_t.learn("run")
			_done = true
			queue_free()
			return
		global_position = to
		if A.on_screen(self, global_position, 40.0):
			queue_redraw()

	func _wrap(pl: Node) -> void:
		_done = true
		if pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl.god_mode():
			var tg := Tangle.new()
			pl.get_parent().add_child(tg)
			tg.victim = pl
			tg.hold = tangle_t
			tg.global_position = pl.global_position
			pl.grab(tg)
			pl._say("TANGLED!  A / D", Color("ffb070"))
			if owner_t != null and is_instance_valid(owner_t.z):
				owner_t.tangles += 1
			preload("res://sfx.gd").play("bl_wrap", pl.global_position, 3.0, 0.1, 2)
		queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := _t * 16.0
		for q in 3:
			var p := Vector2.from_angle(a + float(q) * TAU / 3.0) * 12.0
			DrawBatch.line(self, Vector2.ZERO, p, Color("5a4028"), 1.4)
			DrawBatch.circle(self, p, 3.4, A.OUTLINE)
			DrawBatch.circle(self, p, 2.6, Color("8a6a44"))
		DrawBatch.arc(self, Vector2.ZERO, 12.0, a + 0.5, a + 2.4, 8, Color(1, 1, 1, 0.25), 1.5)


# ---- בולאדורס כרוכות על הרגליים של השחקן (player.grabbed_by) ----
class Tangle extends Node2D:
	const A := preload("res://art.gd")
	var victim: Node = null
	var hold := 2.0
	var dead := false
	var _t := 0.0

	func _ready() -> void:
		z_index = 12

	func release_grab() -> void:   # השחקן השתחרר (A/D)
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -8), "smoke", Vector2.UP, 3)
		dead = true
		queue_free()

	func _physics_process(delta: float) -> void:
		_t += delta
		if victim == null or not is_instance_valid(victim) or victim.dead or victim.grabbed_by != self:
			queue_free()
			return
		global_position = victim.global_position
		victim.velocity.x = 0.0
		if _t >= hold:
			victim.grabbed_by = null
			dead = true
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var sw := sin(_t * 20.0) * 1.0
		for q in 3:   # חבלים כרוכים סביב השוקיים
			var y := -6.0 - float(q) * 5.0
			DrawBatch.arc(self, Vector2(sw, y), 9.0, 0.2, PI - 0.2, 10, Color("5a4028"), 1.8)
			DrawBatch.arc(self, Vector2(-sw, y + 2.0), 9.0, PI + 0.2, TAU - 0.2, 10, Color("4a3420"), 1.4)
		for q in 3:
			var p := Vector2(-10.0 + float(q) * 10.0, -3.0 + absf(sin(_t * 6.0 + float(q))) * -2.0)
			DrawBatch.circle(self, p, 3.4, A.OUTLINE)
			DrawBatch.circle(self, p, 2.6, Color("8a6a44"))


# ============================================================
#  ציור: כובע רחב שוליים, פונצ'ו מפוספס, בומבאצ'ה לבנה, מגפיים. SPIN = יד למעלה, בולאדורס מסתובבות מעל הראש.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var pon := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	Art.fill(z, PackedVector2Array([hip + Vector2(-7, -2), hip + Vector2(7, -2), hip + Vector2(8, 8), hip + Vector2(-8, 8)]), col(z.pants), Art.OUTLINE, 0.9)   # בומבאצ'ה
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), Art.shade(sk, 0.25), Art.shade(pon, 0.3))
	# פונצ'ו: משולש רחב עם פסים
	var pts := PackedVector2Array([sh + Vector2(-10, 2), sh + Vector2(-4, -2), sh + Vector2(6, -2), sh + Vector2(11, 3), hip + Vector2(9, 2), hip + Vector2(-9, 2)])
	Art.fill_shaded(z, pts, pon, 0.15, 0.35)
	for q in 3:
		var yy := sh.y + 5.0 + float(q) * 5.0
		DrawBatch.line(z, Vector2(sh.x - 9.0, yy), Vector2(sh.x + 10.0, yy), col(Color("c89a40") if q == 1 else Color("2a1a12")), 1.2)
	DrawBatch.rect(z, Rect2(hip + Vector2(-8, -2), Vector2(17, 3)), col(Color("8a1a14")))   # פחה אדומה
	Art.oval_shaded(z, head, 5.2, 5.6, sk, 0.0)
	face(head, Vector2(3.2, -0.6))
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.2, -0.5), 0.9, Color(1.0, 0.4, 0.2))
	DrawBatch.line(z, head + Vector2(1, 3), head + Vector2(5, 3.5), col(Color("2a1a14")), 1.4)   # שפם
	# כובע רחב שוליים
	Art.fill(z, PackedVector2Array([head + Vector2(-10, -3.5), head + Vector2(11, -3.5), head + Vector2(10, -2), head + Vector2(-9, -2)]), col(Color("2a221c")), Art.OUTLINE, 0.8)
	Art.fill(z, PackedVector2Array([head + Vector2(-5, -4), head + Vector2(5, -4), head + Vector2(4, -9), head + Vector2(-4, -9)]), col(Color("2a221c")), Art.OUTLINE, 0.8)
	DrawBatch.line(z, head + Vector2(-5, -5), head + Vector2(5, -5), col(Color("8a1a14")), 1.0)
	# יד קדמית + הבולאדורס
	var hf: Vector2
	if state == SPIN and not z.dead:
		hf = sh + Vector2(4, -22)
		var c := hf + Vector2(0, -4)
		var a: float = z._time * 18.0
		for q in 3:
			var bp := c + Vector2(cos(a + float(q) * TAU / 3.0) * 16.0, sin(a + float(q) * TAU / 3.0) * 5.0)
			DrawBatch.line(z, hf, bp, col(Color("5a4028")), 1.0)
			DrawBatch.circle(z, bp, 2.6, Art.OUTLINE)
			DrawBatch.circle(z, bp, 2.0, col(Color("8a6a44")))
		DrawBatch.arc(z, c, 16.0, 0, TAU, 16, Color(1, 1, 1, 0.18), 1.0)
	else:
		hf = sh + Vector2(10.0 + sin(p) * 2.0, 14.0)
		for q in 3:   # בולאדורס תלויות מהיד
			var bp2 := hf + Vector2(-3.0 + float(q) * 3.0, 6.0 + float(q % 2) * 3.0)
			DrawBatch.line(z, hf, bp2, col(Color("5a4028")), 0.8)
			DrawBatch.circle(z, bp2, 2.0, col(Color("8a6a44")))
	z._arm(sh + Vector2(3, 1), hf, sk, pon)
	end_draw()
	return true
