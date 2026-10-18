extends "res://enemies/zombie_type.gd"
# ============================================================
#  REVOLVER (שלב 21, "CLIFFSIDE") - זומבי אקדוחן: מעיל ארוך, כובע בוקרים, מטפחת, אקדח תופי ענק.
#  מחזור ("ירייה אחת ובורח קצת"):
#    WALK  - מתקרב ושומר מרחק (המוח).
#    AIM   - שולף ומכוון: קו כוונה דק + ניצוץ על הקנה (AIM_T) = אזהרה. מכוון קצת לאן שאתה הולך (LEAD).
#    FIRE  - ירייה אחת חזקה (DAMAGE, כדור מהיר וגדול), עשן מהקנה, הרתע מרים לו את היד.
#    RUN   - רץ קצת (RUN_T): אם אתה קרוב - מתרחק, אחרת - לצד / למחסה. ואז שוב מכוון.
#  התחמקות: קפיצה / גלגול / לרוץ לכיוון ההפוך כשרואים את הקו האדום.
#  בוס: THE SHERIFF - יורה 2 כדורים ברצף (השני מקדים יותר), גדול, כוכב שריף.
#  צליל: "pistol"/"sniper" (הירייה), "rv_cock" (דריכה).
#  לשנות: RANGE, AIM_T, DAMAGE, SHOT_V, LEAD, RUN_T, RUN_K, CD.
# ============================================================

const SOUNDS := {
	"rv_cock": [["C", 0, 0, 0.0, 0.05, 0.0, 30.0, 0.5, 1.0, 0], ["C", 0, 0, 0.12, 0.06, 0.0, 30.0, 0.6, 1.0, 0]],
}

const RANGE := 560.0
const AIM_T := 0.6
const DAMAGE := 2
const SHOT_V := 1250.0
const LEAD := 0.35
const RUN_T := Vector2(0.7, 1.1)
const RUN_K := 1.7
const CD := Vector2(0.5, 1.0)

enum { WALK, AIM, RUN }
var state := WALK
var shots := 0           # לבדיקות
var runs := 0
var _st := 0.0
var _cd := 1.0
var _aim := 0.0          # זווית הקנה בעולם
var _flash := 0.0
var _kick := 0.0         # הרתע מרים את היד
var _left := 0           # כמה יריות נשארו בתור (בוס = 2)
var _shot_t := 0.0
var _run_dir := 1.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "REVOLVER", "hp": 300, "walk": 50.0, "chase": 96.0, "damage": 2, "bite_delay": 0.9, "scale": 1.6, "width": 1.05,
			"duck": 0.0, "cover": 0.0, "skin": Color("9aa48a"), "shirt": Color("5a4632"), "pants": Color("3a3026"), "shoe": Color("2a1c12"),
			"points": 1000, "boss": true, "boss_name": "THE SHERIFF - HE RUNS AFTER EVERY SHOT"}
	return {"name": "REVOLVER", "hp": 30, "walk": 50.0, "chase": 100.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.92,
		"duck": 0.2, "cover": 0.4, "skin": Color("9aa48a"), "shirt": Color("5a4632"), "pants": Color("3a3026"), "shoe": Color("2a1c12"), "points": 400}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.35, "keep_range": 320.0}


func can_bite() -> bool:
	return state == WALK


func _pivot() -> Vector2:
	return z.global_position + Vector2(z._dir * 5.0, -37.0) * z.sc


func _muzzle() -> Vector2:
	return _pivot() + Vector2.from_angle(_aim) * 37.0 * z.sc


func _target(pl: Node) -> Vector2:
	var pv: Vector2 = pl.velocity if pl.get("velocity") != null else Vector2.ZERO
	var tgt: Vector2 = pl.global_position + Vector2(0.0, -30.0)
	var tt := _pivot().distance_to(tgt) / SHOT_V
	return tgt + Vector2(clampf(pv.x, -420.0, 420.0) * (LEAD + tt), 0.0)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_flash -= delta
	_kick = move_toward(_kick, 0.0, delta * 3.0)
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if _cd <= 0.0 and has_pl and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees
				if sees and absf(d.x) < RANGE and absf(d.y) < 200.0:
					state = AIM
					_st = AIM_T * (0.8 if _boss() else 1.0)
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					_aim = (_target(pl) - _pivot()).angle()
					Sfx.play("rv_cock", z.global_position, 0.0, 0.08, 2)
					return _stay(delta)
			return false
		AIM:
			if has_pl:
				z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
				_aim = lerp_angle(_aim, (_target(pl) - _pivot()).angle(), delta * 6.0)
			if _st <= 0.0 and _left == 0:
				_left = 2 if _boss() else 1
				_shot_t = 0.0
			if _left > 0:
				_shot_t -= delta
				if _shot_t <= 0.0:
					_fire()
					_left -= 1
					_shot_t = 0.28
					if has_pl:   # השני מקדים יותר
						_aim = (_target(pl) + Vector2(signf(pl.velocity.x) * 60.0, 0.0) - _pivot()).angle()
					if _left == 0:
						_start_run(pl)
			return _stay(delta)
		RUN:
			if _st <= 0.0 or z.is_on_wall():
				state = WALK
				_cd = randf_range(CD.x, CD.y)
				return false
			z._dir = _run_dir
			z.velocity.x = move_toward(z.velocity.x, _run_dir * float(z.chase_speed) * RUN_K, 1400.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			z._walk_phase += delta * absf(z.velocity.x) * 0.075 / z.sc
			return true
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _fire() -> void:
	shots += 1
	var b := Slug.new()
	z.get_parent().add_child(b)
	b.global_position = _muzzle()
	b.velocity = Vector2.from_angle(_aim + randf_range(-0.015, 0.015)) * SHOT_V
	b.damage = DAMAGE
	_flash = 0.07
	_kick = 1.0
	Sfx.play("sniper", _muzzle(), -3.0, 0.08, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), _muzzle(), "smoke", Vector2.from_angle(_aim), 4)
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(3.0, 0.12)


# "רץ קצת": קרוב אליך -> מתרחק; אחרת -> לצד אקראי (או למחסה קרוב)
func _start_run(pl: Node) -> void:
	state = RUN
	runs += 1
	_st = randf_range(RUN_T.x, RUN_T.y)
	var away: float = -signf(pl.global_position.x - z.global_position.x) if pl != null else -float(z._dir)
	if pl != null and absf(pl.global_position.x - z.global_position.x) < 260.0:
		_run_dir = away
	else:
		_run_dir = away if randf() < 0.5 else -away
		for c in z.get_tree().get_nodes_in_group("cover"):   # מחסה קרוב בצד הרחוק ממך
			var cx: float = c.global_position.x - z.global_position.x
			if absf(cx) < 220.0 and signf(cx) == away:
				_run_dir = away
				break


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(6.0 if state == RUN else 5.0, 3.0 if state == RUN else 2.5)
	var hip := Vector2(-1.0, -22.0 + absf(sin(p)) * 0.8)
	var sh := Vector2(1.0, -37.0)
	if state == RUN:
		sh += Vector2(3.0, 1.0)
	var head := sh + Vector2(3.5, -8.0)
	# מעיל ארוך שמתנפנף מאחור
	var flap := sin(z._time * 5.0) * 2.0 + (5.0 if state == RUN else 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(4, 0), hip + Vector2(5, 4), hip + Vector2(3, 14), hip + Vector2(-9 - flap, 13), hip + Vector2(-8, 2)]), Art.shade(coat, 0.15))
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	# חזה: מעיל + חגורת כדורים
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 3), hip + Vector2(-5, 3)]), coat, 0.12, 0.4)
	DrawBatch.line(z, sh + Vector2(-5, 2), hip + Vector2(4, -2), col(Color("3a2a1a")), 2.0)
	for i in 4:
		DrawBatch.circle(z, (sh + Vector2(-5, 2)).lerp(hip + Vector2(4, -2), 0.2 + 0.2 * float(i)), 0.9, col(Color("c8a040")))
	if _boss():   # כוכב שריף
		var c := sh + Vector2(2, 5)
		var star := PackedVector2Array()
		for i in 10:
			star.append(c + Vector2.from_angle(-PI / 2.0 + float(i) * PI / 5.0) * (2.6 if i % 2 == 0 else 1.1))
		DrawBatch.colored_polygon(z, star, col(Color("e8c040")))
	# ראש: מטפחת אדומה + כובע בוקרים
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-4, 1), head + Vector2(6, 0.5), head + Vector2(5, 5), head + Vector2(-3, 5)]), col(Color("8a2020")), Art.OUTLINE, 0.8)
	Art.fill(z, PackedVector2Array([head + Vector2(-10, -4), head + Vector2(11, -4.5), head + Vector2(9, -2.5), head + Vector2(-9, -2)]), col(Color("4a3220")), Art.OUTLINE, 1.0)   # שוליים
	Art.fill(z, PackedVector2Array([head + Vector2(-5, -4), head + Vector2(-4, -10), head + Vector2(0, -8.5), head + Vector2(4, -10.5), head + Vector2(6, -4.5)]), col(Color("5a3e26")), Art.OUTLINE, 1.0)   # כיפה
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -1.0), 0.8, Color(1.0, 0.5, 0.2))
	# האקדח התופי הגדול
	var a := _aim if state == AIM else (1.15 if z._dir > 0.0 else PI - 1.15)   # בהליכה: מורד למטה
	if state == RUN:
		a = 1.35 if z._dir > 0.0 else PI - 1.35
	var la := Vector2(cos(a) * z._dir, sin(a)).normalized()
	la = la.rotated(-0.5 * _kick)   # הרתע
	var piv := Vector2(5.0, -37.0)
	var hand := piv + la * (11.0 - 2.0 * _kick)
	var tr := Transform2D(la.angle(), Vector2(1.4, 1.4), 0.0, hand)   # אקדח גדול
	Art.fill(z, tr * PackedVector2Array([Vector2(-1, 1), Vector2(3, 1), Vector2(1, 7), Vector2(-3, 6.5)]), col(Color("6a3e1e")), Art.OUTLINE, 0.9)   # ידית עץ
	Art.fill(z, tr * PackedVector2Array([Vector2(-2, -3), Vector2(5, -3), Vector2(5, 2), Vector2(-2, 1.5)]), col(Color("7a7e86")), Art.OUTLINE, 1.0)   # גוף
	Art.oval(z, tr * Vector2(2.5, -0.5), 3.9, 3.4, col(Color("9a9ea6")), la.angle(), Art.OUTLINE, 0.8)   # תוף
	Art.fill(z, tr * PackedVector2Array([Vector2(5, -2.6), Vector2(18, -2.2), Vector2(18, 0.2), Vector2(5, 0.8)]), col(Color("b8bcc4")), Art.OUTLINE, 1.0)   # קנה ארוך
	DrawBatch.line(z, tr * Vector2(17, -2.4), tr * Vector2(17, -3.6), Art.OUTLINE, 1.2)   # כוונת
	if state == AIM and not z.dead and _left == 0:
		var m := tr * Vector2(19, -1)
		DrawBatch.line(z, m, m + la * 120.0, Color(1.0, 0.15, 0.1, 0.3), 1.0)
		if int(z._time * 12.0) % 2 == 0:
			Art.glow(z, m, 5.0, Color(1.0, 0.25, 0.1, 0.8))
	if _flash > 0.0:
		var m2 := tr * Vector2(20, -1)
		Art.glow(z, m2, 11.0, Color(1.0, 0.8, 0.3, 0.9))
		DrawBatch.colored_polygon(z, PackedVector2Array([m2 + la.orthogonal() * 4.0, m2 + la * 16.0, m2 - la.orthogonal() * 4.0]), Color(1.0, 0.92, 0.55))
	z._arm(sh + Vector2(3, 1), hand, sk, coat)
	end_draw()
	return true


# ---- הכדור הכבד ----
class Slug extends Node2D:
	var velocity := Vector2.ZERO
	var damage := 2
	var life := 1.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		life -= delta
		var to := global_position + velocity * delta
		if life <= 0.0 or not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1)).is_empty():
			queue_free()
			return
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead:
			var r: Rect2 = p.body_rect()
			for i in 4:
				if r.has_point(global_position.lerp(to, float(i) / 3.0)):
					p.hurt(damage, Vector2(signf(velocity.x) * 1.6, -0.3))
					queue_free()
					return
		global_position = to
		rotation = velocity.angle()
		queue_redraw()

	func _draw() -> void:
		DrawBatch.line(self, Vector2(-34, 0), Vector2(0, 0), Color(1.0, 0.6, 0.25, 0.45), 3.0)
		DrawBatch.line(self, Vector2(-10, 0), Vector2(3, 0), Color(1.0, 0.92, 0.7), 3.2)
