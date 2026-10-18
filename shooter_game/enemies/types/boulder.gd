extends "res://enemies/zombie_type.gd"
# ============================================================
#  BOULDER (שלב 28, "CLOUD PASS") - סבל הרים ענק: פונצ'ו קרוע, רצועת מצח, סל אבנים על הגב.
#    WALK  - מתקרב לאט, שומר מרחק (KEEP).
#    LIFT  - מרים סלע ענק מעל הראש (LIFT_T, אבק נופל) = אזהרה.
#    ROLL  - מגלגל את הסלע אליך על הקרקע (Rock: ROLL_V). אתה למעלה (קומה) -> זורק אותו בקשת.
#  הסלע: קופץ קצת, פוגע בך (ROCK_DMG) ומועך זומבים בדרך, נשבר על קיר / מכשול לאבק ואבנים. לקפוץ מעליו!
#  לשנות: KEEP, LIFT_T, ROLL_V, ROCK_DMG, CD.
# ============================================================

const SOUNDS := {
	"bd_grunt": [["V", 120, 90, 0.0, 0.4, 0.05, 4.0, 0.5, 0.8, 0.02, 0.0, [500.0, 1000.0, 30.0]]],
	"bd_roll": [["N", 0, 0, 0.0, 1.2, 0.1, 1.2, 0.5, 0.12, 0], ["C", 0, 0, 0.0, 1.2, 0.0, 1.5, 0.4, 0.5, 0]],
	"bd_crack": [["N", 0, 0, 0.0, 0.05, 0.0, 120.0, 1.2, 1.0, 0], ["N", 0, 0, 0.0, 0.5, 0.0, 7.0, 0.7, 0.2, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 9.0, 0.6, 1.0, 0]],
}

const KEEP := Vector2(220.0, 460.0)
const LIFT_T := 0.7
const ROLL_V := 330.0
const ROCK_DMG := 2
const CD := Vector2(2.6, 3.6)

enum { WALK, LIFT }
var state := WALK
var rolls := 0               # לבדיקות
var _st := 0.0
var _cd := 1.5


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	return {"name": "BOULDER", "hp": 74, "walk": 38.0, "chase": 70.0, "damage": 2, "bite_delay": 1.0, "scale": 1.35, "width": 1.3,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a80"), "shirt": Color("8a3a2a"), "pants": Color("4a3e30"), "shoe": Color("2a2018"), "points": 500}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.4, "keep_range": 300.0}


func can_bite() -> bool:
	return state == WALK


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if not has_pl:
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if _cd <= 0.0 and absf(d.x) > 120.0 and absf(d.x) < 700.0 and absf(d.y) < 260.0 and z.is_on_floor():
				state = LIFT
				_st = LIFT_T
				z._dir = signf(d.x)
				Sfx.play("bd_grunt", z.global_position, 0.0, 0.1, 2)
				return _stay(delta)
			return false
		LIFT:
			if Engine.get_physics_frames() % 8 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 4.0, -70.0) * z.sc, "smoke", Vector2.DOWN, 1)
			if _st <= 0.0:
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


func _throw(pl: Node) -> void:
	rolls += 1
	var r := Rock.new()
	r.radius = 17.0 * z.sc / 1.35
	r.owner_z = z
	var from: Vector2 = z.global_position + Vector2(z._dir * 18.0, -24.0) * z.sc
	if pl != null and pl.global_position.y < z.global_position.y - 60.0:   # אתה למעלה: זורק בקשת
		var tgt: Vector2 = pl.global_position + Vector2(0, -20)
		var t := clampf(absf(tgt.x - from.x) / 380.0, 0.6, 1.2)
		r.velocity = Vector2((tgt.x - from.x) / t, (tgt.y - from.y - 0.5 * 1100.0 * t * t) / t)
	else:
		r.velocity = Vector2(z._dir * ROLL_V, -40.0)
	z.get_parent().add_child(r)
	r.global_position = from
	Sfx.play("bd_roll", z.global_position, 2.0, 0.1, 2)


# ============================================================
#  ציור: גוף רחב, פונצ'ו פסים, רצועת מצח לסל, סל אבנים על הגב; LIFT = סלע מעל הראש
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var pon := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var lifting: bool = state == LIFT and not z.dead
	var hip := Vector2(0, -22)
	var sh := Vector2(0, -38)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# סל אבנים על הגב
	var bk := sh + Vector2(-13, 2)
	Art.fill_shaded(z, PackedVector2Array([bk + Vector2(-5, -8), bk + Vector2(6, -8), bk + Vector2(5, 14), bk + Vector2(-4, 14)]), col(Color("7a5a34")), 0.15, 0.4)
	for q in 3:
		DrawBatch.circle(z, bk + Vector2(-2.0 + float(q) * 3.0, -9.0 - float(q % 2) * 2.0), 3.0, col(Color("8a8070")))
	DrawBatch.line(z, bk + Vector2(5, -6), head + Vector2(-2, -4), col(Color("4a3a20")), 1.6)   # רצועת מצח
	# ידיים
	var hb: Vector2
	var hf: Vector2
	if lifting:
		hb = sh + Vector2(-2, -18)
		hf = sh + Vector2(8, -18)
	else:
		hb = sh + Vector2(-5.0 - sin(p) * 3.0, 15.0)
		hf = sh + Vector2(9.0 + sin(p) * 3.0, 14.0)
	z._arm(sh + Vector2(-4, 1), hb, Art.shade(sk, 0.25), Art.shade(pon, 0.3))
	# פונצ'ו עם פסים
	var pts := PackedVector2Array([sh + Vector2(-10, -1), sh + Vector2(9, -1), hip + Vector2(11, 3), hip + Vector2(-11, 3)])
	Art.fill_shaded(z, pts, pon, 0.12, 0.35)
	for q in 3:
		var yy := sh.y + 5.0 + float(q) * 6.0
		DrawBatch.line(z, Vector2(-9.0 - float(q), yy), Vector2(9.0 + float(q), yy), col([Color("e8c030"), Color("2a6aa0"), Color("e8e0d0")][q]), 1.6)
	DrawBatch.line(z, sh + Vector2(-2, 1), sh + Vector2(2, 6), col(Color("2a1a14")), 1.2)   # קרע
	Art.oval_shaded(z, head, 6.0, 6.2, sk, 0.0)
	face(head, Vector2(3.5, -1.0))
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -1.0), 1.0, Color(1.0, 0.45, 0.2))
	DrawBatch.line(z, head + Vector2(-1, 3.5), head + Vector2(5, 3.5), col(Color("3a2a1a")), 1.2)
	z._arm(sh + Vector2(4, 1), hf, sk, pon)
	if lifting:   # הסלע מעל הראש
		var rc := sh + Vector2(3, -26)
		Art.oval_shaded(z, rc, 13.0, 11.0, col(Color("8a8070")), 0.2)
		DrawBatch.line(z, rc + Vector2(-6, -3), rc + Vector2(2, 4), col(Color("5a5048")), 1.4)
	end_draw()
	return true


# ---- הסלע המתגלגל ----
class Rock extends Node2D:
	var velocity := Vector2.ZERO
	var radius := 17.0
	var owner_z: Node = null
	var hit_player := 0          # לבדיקות
	var _ang := 0.0
	var _life := 6.0
	var _hit_zs := []
	var _hurt_cd := 0.0
	var _dust := 0.0

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return absf(p.x - global_position.x) < radius + margin + absf(velocity.x) * 0.15 and absf(p.y - global_position.y) < 50.0

	func _physics_process(delta: float) -> void:
		_life -= delta
		_hurt_cd -= delta
		if _life <= 0.0:
			_break()
			return
		velocity.y += 1100.0 * delta
		var space := get_world_2d().direct_space_state
		# קרקע
		var down := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, radius + maxf(velocity.y * delta, 0.0) + 1.0), 1 | 16))
		if down and velocity.y > 0.0:
			global_position.y = down.position.y - radius
			if velocity.y > 260.0:
				velocity.y = -velocity.y * 0.3   # קפיצה קטנה
				preload("res://sfx.gd").play("land", global_position, 0.0, 0.1, 3)
			else:
				velocity.y = 0.0
			if absf(velocity.x) < 60.0:
				velocity.x = signf(velocity.x) * 300.0
		# קיר / מכשול
		if absf(velocity.x) > 1.0:
			var side := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(signf(velocity.x) * (radius + absf(velocity.x) * delta + 1.0), 0.0), 1))
			if side:
				_break()
				return
		global_position += velocity * delta
		_ang += velocity.x * delta / radius
		_dust -= delta
		if _dust <= 0.0 and down and preload("res://art.gd").on_screen(self, global_position):
			_dust = 0.08
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(-signf(velocity.x) * radius * 0.6, radius), "smoke", Vector2(-signf(velocity.x), -0.5), 1)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and _hurt_cd <= 0.0:
			var r: Rect2 = pl.body_rect()
			var c := global_position
			var nearest := Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
			if nearest.distance_to(c) < radius:
				_hurt_cd = 0.8
				if pl._invuln <= 0.0:
					hit_player += 1
				pl.hurt(2, Vector2(signf(velocity.x) * 2.0, -1.0))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z == owner_z or _hit_zs.has(z):
				continue
			var zr := Rect2(z.global_position + Vector2(-10.0 * float(z.wf), -54.0 * float(z.sc)), Vector2(20.0 * float(z.wf), 54.0 * float(z.sc)))
			var cp := Vector2(clampf(global_position.x, zr.position.x, zr.end.x), clampf(global_position.y, zr.position.y, zr.end.y))
			if cp.distance_to(global_position) < radius:
				_hit_zs.append(z)
				z.take_damage(55, z.global_position + Vector2(0, -20), Vector2(signf(velocity.x), -0.5), true, {"source": "hazard", "fixed": 55})
		queue_redraw()

	func _break() -> void:
		preload("res://sfx.gd").play("bd_crack", global_position, 2.0, 0.1, 3)
		preload("res://particles.gd").burst(get_parent(), global_position, "smoke", Vector2.UP, 10)
		preload("res://particles.gd").burst(get_parent(), global_position, "hit", Vector2.UP, 6)
		queue_free()

	func _draw() -> void:
		var A := preload("res://art.gd")
		DrawBatch.circle(self, Vector2(2, 2), radius, Color(0, 0, 0, 0.25))
		A.oval_shaded(self, Vector2.ZERO, radius, radius * 0.92, Color("8a8070"), _ang)
		for k in 3:   # סדקים וכתמים שמסתובבים
			var a := _ang + float(k) * 2.1
			DrawBatch.line(self, Vector2.from_angle(a) * radius * 0.2, Vector2.from_angle(a) * radius * 0.8, Color("5a5048"), 1.6)
		DrawBatch.circle(self, Vector2.from_angle(_ang + 1.0) * radius * 0.5, radius * 0.18, Color("6a6458"))
		DrawBatch.circle(self, Vector2.from_angle(_ang + 3.5) * radius * 0.55, radius * 0.12, Color(0.9, 0.95, 1.0, 0.7))   # שלג דבוק
