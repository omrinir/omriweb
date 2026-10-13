extends "res://enemies/zombie_type.gd"
# ============================================================
#  SMOKER (שלב 33, "SULFUR CRATER") - עובד פומרולות במסכת גז עם מיכל עשן על הגב וצינור.
#  "THEY LEARNED TO HIDE": שומר מרחק (BACKOFF) וזורק מיכל עשן (SMOKE_CD) בין עצמו לבינך ->
#    ענן עשן שחור סמיך (SmokeCloud, RADIUS, LIFE) - הזומבים מתקרבים אליך בתוכו בלי שתראה אותם.
#    כשיש זומבים קרובים אליו - זורק את הענן ממש לפניהם (מכסה את ההתקפה שלהם).
#  מת -> המיכל מתפוצץ = ענן גדול במקום.
#  לשנות: BACKOFF, SMOKE_CD, SmokeCloud.RADIUS / LIFE.
# ============================================================

const SOUNDS := {
	"sm_hiss": [["N", 0, 0, 0.0, 0.9, 0.05, 2.0, 0.5, 0.6, 0, 0.3]],
	"sm_cough": [["N", 0, 0, 0.0, 0.12, 0.0, 20.0, 0.4, 0.3, 0], ["N", 0, 0, 0.18, 0.12, 0.0, 20.0, 0.35, 0.3, 0]],
}

const BACKOFF := 240.0
const SMOKE_CD := 6.0
const RANGE := 520.0

enum { WALK, AIM }
var state := WALK
var throws := 0              # לבדיקות
var _st := 0.0
var _cd := 1.5


func stats() -> Dictionary:
	return {"name": "SMOKER", "hp": 30, "walk": 38.0, "chase": 70.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.3, "skin": Color("8a8a74"), "shirt": Color("5a5a3a"), "pants": Color("3a3a2e"), "shoe": Color("2a2620"), "points": 440}


func can_bite() -> bool:
	return state == WALK


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var d := Vector2.ZERO
	if has_pl:
		d = pl.global_position - z.global_position
	match state:
		WALK:
			if has_pl and _cd <= 0.0 and absf(d.x) < RANGE and absf(d.x) > 90.0 and absf(d.y) < 100.0 and z.is_on_floor():
				state = AIM
				_st = 0.45
				z._dir = signf(d.x)
				return _stay(delta)
			if has_pl and absf(d.x) < BACKOFF and absf(d.y) < 90.0:   # שומר מרחק
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.5, 600.0 * delta)
				if not z.is_on_floor():
					z.velocity.y += z.gravity * delta
				elif z.is_on_wall():
					z.velocity.y = -380.0
				z.move_and_slide()
				return true
			return false
		AIM:
			if _st <= 0.0:
				_throw(pl)
				state = WALK
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# זורק לנקודה בין הזומבים הקרובים אליך לבינך (או באמצע הדרך)
func _throw(pl: Node) -> void:
	throws += 1
	_cd = SMOKE_CD
	var px: float = pl.global_position.x if pl != null else z.global_position.x + z._dir * 200.0
	var target := lerpf(z.global_position.x, px, 0.55)
	var best := INF
	for o in z.get_tree().get_nodes_in_group("zombies"):   # יש חבר שמתקרב אליך? מכסים אותו
		if o == z or o.dead or o.is_boss():
			continue
		var od: float = absf(o.global_position.x - px)
		if od < 320.0 and od > 60.0 and od < best and signf(o.global_position.x - px) == signf(z.global_position.x - px):
			best = od
			target = lerpf(o.global_position.x, px, 0.4)
	var c := Canister.new()
	z.get_parent().add_child(c)
	c.global_position = z.global_position + Vector2(z._dir * 10.0, -50.0)
	var flight := 0.7
	c.velocity = Vector2((target - c.global_position.x) / flight, (z.global_position.y - 6.0 - c.global_position.y) / flight - 0.5 * c.gravity * flight)
	Sfx.play("throw", z.global_position, -2.0)


func on_death() -> void:   # המיכל מתפוצץ
	var sc := SmokeCloud.new()
	sc.radius = 150.0
	z.get_parent().add_child(sc)
	sc.global_position = z.global_position + Vector2(0, -30)
	Sfx.play("sm_hiss", z.global_position, 2.0, 0.1, 2)


class Canister extends Node2D:
	var velocity := Vector2.ZERO
	var gravity := 900.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += gravity * delta
		var to := global_position + velocity * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
		if not hit.is_empty() or _t > 2.0:
			var sc := SmokeCloud.new()
			get_parent().add_child(sc)
			sc.global_position = (hit.position if not hit.is_empty() else to) + Vector2(0, -40)
			preload("res://sfx.gd").play("sm_hiss", sc.global_position, 0.0, 0.1, 3)
			queue_free()
			return
		global_position = to
		rotation += 10.0 * delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-4, -7, 8, 14), Color("5a5a3a"))
		draw_rect(Rect2(-4, -7, 8, 3), Color("c0a020"))
		draw_circle(Vector2(0, -9), 2.0 + sin(_t * 30.0), Color(0.3, 0.3, 0.3, 0.8))


# ---- ענן עשן שחור סמיך: מצויר מעל הכל - מה שבפנים לא נראה ----
class SmokeCloud extends Node2D:
	const LIFE := 7.0
	var radius := 120.0
	var clouds := 0              # לבדיקות
	var _t := 0.0
	var _seed := 0

	func _ready() -> void:
		z_index = 8
		add_to_group("smoke_clouds")
		_seed = randi()

	func covers(p: Vector2) -> bool:
		return _t < LIFE - 0.5 and p.distance_to(global_position) < radius * 0.85

	func _process(delta: float) -> void:
		_t += delta
		global_position.x += sin(_t * 0.7) * 6.0 * delta
		if _t > LIFE:
			queue_free()
			return
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = _seed
		var grow := clampf(_t / 0.6, 0.0, 1.0)
		var fade := clampf((LIFE - _t) / 1.5, 0.0, 1.0)
		for q in 12:
			var a := r.randf() * TAU
			var dd := r.randf_range(0.0, radius * 0.7) * grow
			var pr := r.randf_range(radius * 0.35, radius * 0.55) * (0.6 + 0.4 * grow)
			var p := Vector2.from_angle(a) * dd * Vector2(1.2, 0.7) + Vector2(sin(_t * 0.8 + float(q)) * 6.0, -_t * 2.0)
			var g := r.randf_range(0.08, 0.16)
			draw_circle(p, pr, Color(g, g * 0.95, g * 0.9, 0.8 * fade))
		for q in 5:   # שוליים בהירים יותר
			var a := r.randf() * TAU
			draw_circle(Vector2.from_angle(a) * radius * 0.6 * grow, radius * 0.3, Color(0.3, 0.28, 0.26, 0.35 * fade))


# ============================================================
#  ציור: מסכת גז עם פילטר עגול, משקפיים, מיכל עשן על הגב עם צינור, סרבל
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var tank := sh + Vector2(-10, 8)   # מיכל על הגב
	Art.fill_shaded(z, PackedVector2Array([tank + Vector2(-5, -10), tank + Vector2(5, -10), tank + Vector2(5, 10), tank + Vector2(-5, 10)]), col(Color("6a6a4a")), 0.2, 0.4, Art.OUTLINE, 1.1)
	z.draw_rect(Rect2(tank + Vector2(-5, -6), Vector2(10, 3)), col(Color("c0a020")))
	var hb := sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	var hf := sh + Vector2(9.0 + sin(p) * 2.0, 12.0)
	if state == AIM:
		hf = sh + Vector2(6, -14)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(suit, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 2), hip + Vector2(-6, 2)]), suit, 0.12, 0.4)
	z.draw_line(sh + Vector2(-5, 2), sh + Vector2(5, 2), col(Color("8a7a30")), 1.5)   # רצועות
	Art.oval_shaded(z, head, 5.4, 6.0, col(Color("3a3a32")), 0.0)   # מסכת גז
	if not z.dead:
		z.draw_circle(head + Vector2(1.5, -2.0), 1.8, Color(0.75, 0.85, 0.6, 0.9))   # משקפיים
		z.draw_circle(head + Vector2(4.5, -2.0), 1.8, Color(0.75, 0.85, 0.6, 0.9))
	z.draw_circle(head + Vector2(5.5, 3.0), 2.8, col(Color("5a5a4a")))   # פילטר
	z.draw_circle(head + Vector2(5.5, 3.0), 1.4, col(Color("2a2a22")))
	z.draw_polyline(PackedVector2Array([head + Vector2(3, 5), sh + Vector2(-4, 4), tank + Vector2(0, -10)]), col(Color("2a2a22")), 1.6)   # צינור
	z._arm(sh + Vector2(3, 1), hf, sk, suit)
	if state == AIM:
		z.draw_rect(Rect2(hf + Vector2(-3, -10), Vector2(6, 10)), col(Color("5a5a3a")))
	end_draw()
	return true
