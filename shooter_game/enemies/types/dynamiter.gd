extends "res://enemies/zombie_type.gd"
# ============================================================
#  DYNAMITER (שלב 29, "MINE OF ECHOES") - כורה עם קסדה ופנס דולק, חגורת דינמיט על החזה.
#    WALK  - שומר מרחק (keep_range).
#    LIGHT - מדליק פתיל (LIGHT_T, ניצוצות ביד) = אזהרה.
#    THROW - זורק מקל דינמיט בקשת לאן שאתה הולך. המקל קופץ ומתגלגל, הפתיל בוער (FUSE) -> פיצוץ (RADIUS).
#            אתה מאחורי מחסה -> זורק גבוה יותר (מעל המחסה). פיצוץ במכרה מרעיד את התקרה (CaveIn)!
#  מת -> חגורת הדינמיט שלו נדלקת ומתפוצצת אחרי רגע (תתרחק מהגופה).
#  בוס: THE FOREMAN - 3 מקלות במניפה.
#  לשנות: LIGHT_T, FUSE, RADIUS, CD.
# ============================================================

const SOUNDS := {
	"dy_fuse": [["N", 0, 0, 0.0, 0.6, 0.02, 1.0, 0.3, 0.8, 0, 0.6], ["C", 0, 0, 0.0, 0.6, 0.0, 1.0, 0.25, 1.0, 0]],
}

const LIGHT_T := 0.6
const FUSE := 1.6
const RADIUS := 90.0
const CD := Vector2(2.6, 3.6)
const GRAV := 1000.0

enum { WALK, LIGHT }
var state := WALK
var throws := 0              # לבדיקות
var _st := 0.0
var _cd := 1.2
var _anim := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "DYNAMITER", "hp": 400, "walk": 46.0, "chase": 90.0, "damage": 2, "bite_delay": 0.9, "scale": 1.65, "width": 1.15,
			"duck": 0.0, "cover": 0.0, "skin": Color("9a9a88"), "shirt": Color("5a4630"), "pants": Color("3a3228"), "shoe": Color("1e1a14"),
			"points": 1200, "boss": true, "boss_name": "THE FOREMAN - MIND THE FUSE"}
	return {"name": "DYNAMITER", "hp": 34, "walk": 46.0, "chase": 92.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.2, "cover": 0.4, "skin": Color("9a9a88"), "shirt": Color("5a4630"), "pants": Color("3a3228"), "shoe": Color("1e1a14"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3, "keep_range": 300.0}


func can_bite() -> bool:
	return state == WALK


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_anim -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if has_pl and _cd <= 0.0 and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				if absf(d.x) > 90.0 and absf(d.x) < 560.0 and absf(d.y) < 260.0:
					state = LIGHT
					_st = LIGHT_T
					z._dir = signf(d.x)
					Sfx.play("dy_fuse", z.global_position, -2.0, 0.1, 2)
					return _stay(delta)
			return false
		LIGHT:
			if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), _hand(), "fire", Vector2.UP, 1)
			if _st <= 0.0:
				if has_pl:
					var pv: Vector2 = pl.velocity if pl.get("velocity") != null else Vector2.ZERO
					var tgt: Vector2 = pl.global_position + Vector2(clampf(pv.x, -300.0, 300.0) * 0.4, 0.0)
					var high := _cover_between(pl)
					if _boss():
						for k in [-80.0, 0.0, 80.0]:
							_throw(tgt + Vector2(k, 0.0), high)
					else:
						_throw(tgt, high)
				state = WALK
				_cd = randf_range(CD.x, CD.y)
				_anim = 0.35
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 4.0, -50.0) * z.sc


func _cover_between(pl: Node) -> bool:
	var q := PhysicsRayQueryParameters2D.create(_hand(), pl.global_position + Vector2(0, -30), 1)
	return not z.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _throw(target: Vector2, high: bool) -> void:
	throws += 1
	var from := _hand()
	var t := clampf(absf(target.x - from.x) / (300.0 if high else 420.0), 0.55, 1.4)
	var v := Vector2((target.x - from.x) / t, (target.y - 6.0 - from.y - 0.5 * GRAV * t * t) / t)
	var s := Stick.new()
	s.velocity = v
	s.fuse = FUSE - LIGHT_T
	s.radius = RADIUS
	z.get_parent().add_child(s)
	s.global_position = from
	Sfx.play("throw", z.global_position, 0.0, 0.1, 3)


func on_death() -> void:   # חגורת הדינמיט נדלקת
	var s := Stick.new()
	s.velocity = Vector2(randf_range(-40.0, 40.0), -160.0)
	s.fuse = 1.1
	s.radius = RADIUS * (1.4 if _boss() else 1.0)
	s.bundle = true
	z.get_parent().add_child.call_deferred(s)
	s.position = z.global_position + Vector2(0, -20)
	z._popup("FUSE LIT!", Color("ffb040"), 14, -70.0)


# ============================================================
#  ציור: קסדה עם פנס דולק, חגורת דינמיט אדומה על החזה, מקל ביד בזמן LIGHT
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 14.0), Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), shirt, 0.12, 0.4)
	z.draw_line(sh + Vector2(-5, 0), hip + Vector2(4, -1), col(Color("3a2a1a")), 3.0)   # חגורת דינמיט
	for q in 4:
		var bp := (sh + Vector2(-5, 0)).lerp(hip + Vector2(4, -1), 0.15 + 0.22 * float(q))
		z.draw_rect(Rect2(bp + Vector2(-1.5, -3), Vector2(3, 6)), col(Color("c03020")))
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	face(head)
	if not z.dead:
		z.draw_circle(head + Vector2(3.5, -0.5), 0.9, Color(1.0, 0.5, 0.2))
	Art.fill(z, PackedVector2Array([head + Vector2(-6.5, -3), head + Vector2(-5, -8), head + Vector2(4, -8.5), head + Vector2(7, -3)]), col(Color("8a8a8e")), Art.OUTLINE, 1.0)   # קסדה
	z.draw_rect(Rect2(head + Vector2(4, -8), Vector2(3, 3)), col(Color("e8e0a0")))   # פנס
	if not z.dead:
		Art.glow(z, head + Vector2(8, -6.5), 12.0, Color(1.0, 0.95, 0.6, 0.5))
	var hand: Vector2
	if state == LIGHT:
		hand = sh + Vector2(-6, -10)
	elif _anim > 0.0:
		hand = sh + Vector2(14, -4)
	else:
		hand = sh + Vector2(9.0 + sin(p) * 3.0, 13.0)
	z._arm(sh + Vector2(3, 1), hand, sk, shirt)
	if state == LIGHT and not z.dead:
		z.draw_rect(Rect2(hand + Vector2(-1.5, -8), Vector2(3, 8)), col(Color("c03020")))
		z.draw_line(hand + Vector2(0, -8), hand + Vector2(2, -12), col(Color("d8c8a0")), 1.0)
		z.draw_circle(hand + Vector2(2, -12), 1.8 + sin(z._time * 40.0), Color(1.0, 0.8, 0.3))
	end_draw()
	return true


# ---- מקל דינמיט: עף, קופץ, מתגלגל, פתיל בוער -> בום ----
class Stick extends Node2D:
	var velocity := Vector2.ZERO
	var fuse := 1.0
	var radius := 90.0
	var bundle := false          # חגורה שלמה (מהגופה)
	var _rot := 0.0
	var _spark := 0.0

	func _ready() -> void:
		z_index = 8
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position - Vector2(radius * 0.6, 40.0), Vector2(radius * 1.2, 50.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return p.distance_to(global_position) < radius * 0.7 + margin

	func _physics_process(delta: float) -> void:
		fuse -= delta
		if fuse <= 0.0:
			var at := global_position + Vector2(0, -8)
			preload("res://explosion.gd").blast(get_parent(), at, radius, 50.0, 45, 2, "dynamite")
			for c in get_tree().get_nodes_in_group("cave_ins"):   # פיצוץ מרעיד את התקרה
				c.shake(at)
			queue_free()
			return
		velocity.y += 1000.0 * delta
		var to := global_position + velocity * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 3), 1 | 16))
		if hit:
			if hit.normal.y < -0.5:   # רצפה: קופץ קצת ומתגלגל
				global_position = hit.position + Vector2(0, -3)
				velocity.y = -velocity.y * 0.25 if absf(velocity.y) > 150.0 else 0.0
				velocity.x *= 0.6
			else:   # קיר
				velocity.x = -velocity.x * 0.4
		else:
			global_position = to
		_rot += velocity.x * delta * 0.08
		_spark -= delta
		if _spark <= 0.0 and preload("res://art.gd").on_screen(self, global_position):
			_spark = 0.06
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2.from_angle(_rot - PI * 0.5) * 7.0, "fire", Vector2.UP, 1)
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, _rot, Vector2.ONE)
		var n := 3 if bundle else 1
		for i in n:
			var ox := (float(i) - float(n - 1) * 0.5) * 4.5
			draw_rect(Rect2(ox - 2.2, -7, 4.4, 14), Color("c03020"))
			draw_rect(Rect2(ox - 2.2, -7, 4.4, 14), Color("1a0a08"), false, 1.0)
		draw_line(Vector2(0, -7), Vector2(2, -11), Color("d8c8a0"), 1.2)
		var k := clampf(fuse, 0.0, 1.0)
		draw_circle(Vector2(2, -11), 2.0 + (1.0 - k) * 2.0 + sin(fuse * 40.0), Color(1.0, 0.8 - (1.0 - k) * 0.5, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if fuse < 0.5 and fmod(fuse * 10.0, 1.0) < 0.5:   # עוד רגע
			draw_arc(Vector2.ZERO, radius * 0.6, 0.0, TAU, 20, Color(1.0, 0.3, 0.1, 0.35), 2.0)
