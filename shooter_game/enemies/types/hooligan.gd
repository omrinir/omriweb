extends "res://enemies/zombie_type.gd"
# ============================================================
#  HOOLIGAN (שלב 39, "THE STADIUM") - אוהד "טורסידה" זומבי: בלי חולצה, צעיף הקבוצה על הפנים, סינליזדור (זיקוק יד) בוער ביד.
#  "THEY LEARNED TO CORNER YOU": זורק סינליזדור אל מאחוריך (בצד השני מהזומבים) -> אש אדומה על הקרקע (FlareFire, BURN_T)
#    שחוסמת את הנסיגה. כשיש סביבו זומבים (CHANT_N) - שר: כולם מסתערים יחד (rush).
#    FLARES זיקוקים. ירייה בזיקוק שביד (בזמן ההנפה) - נדלק עליו.
#  לשנות: FLARES, THROW_CD, BURN_T, CHANT_R, CHANT_N.
# ============================================================

const SOUNDS := {
	"hl_hiss": [["N", 0, 0, 0.0, 0.6, 0.05, 2.0, 0.3, 0.85, 0, 0.9]],
	"hl_chant": {"drive": 1.3, "layers": [["V", 160, 170, 0.0, 0.35, 0.03, 4.0, 0.4, 1.0, 0.04, 0, [500, 1100, 4]], ["V", 150, 160, 0.4, 0.35, 0.03, 4.0, 0.4, 1.0, 0.04, 0, [500, 1100, 4]], ["V", 190, 200, 0.8, 0.5, 0.03, 3.0, 0.45, 1.0, 0.04, 0, [500, 1100, 4]]]},
}

const FLARES := 2
const THROW_CD := 4.5
const BURN_T := 5.0
const CHANT_R := 260.0
const CHANT_N := 2
const CHANT_CD := 7.0

var flares := FLARES
var throws := 0              # לבדיקות
var chants := 0
var _cd := 1.5
var _chant_cd := 2.0
var _wind := 0.0


func stats() -> Dictionary:
	return {"name": "HOOLIGAN", "hp": 32, "walk": 46.0, "chase": 90.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 1.05,
		"duck": 0.1, "cover": 0.1, "skin": Color("7a8a6c"), "shirt": Color("7a8a6c"), "pants": Color("2a2a3a"), "shoe": Color("e0e0e0"), "points": 460}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if _wind > 0.0 and hit_pos.distance_to(_hand()) < 10.0 * z.sc:   # הזיקוק ביד נדלק עליו
		_wind = 0.0
		flares = 0
		Particles.burst(z.get_parent(), hit_pos, "fire", Vector2.UP, 12)
		z._popup("BURNED BY HIS OWN FLARE", Color("ff6040"), 12, -80.0)
		z.take_damage.call_deferred(14, z.global_position + Vector2(0, -30), Vector2.UP, false, {"source": "fire", "fixed": 14})
	return true


func _hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 6.0, -58.0) * z.sc


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_chant_cd -= delta
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if _chant_cd <= 0.0 and absf(d.x) < 600.0:   # שירה -> הסתערות משותפת
		var near := []
		for o in z.get_tree().get_nodes_in_group("zombies"):
			if o != z and not o.dead and not o.is_boss() and o.global_position.distance_to(z.global_position) < CHANT_R:
				near.append(o)
		if near.size() >= CHANT_N:
			_chant_cd = CHANT_CD
			chants += 1
			Sfx.play("hl_chant", z.global_position, 0.0, 0.05, 2)
			z._popup("OLE OLE OLE!", Color("ffe060"), 13, -80.0)
			for o in near:
				o._alert_t = maxf(float(o._alert_t), 6.0)
				o._rush_t = 2.5
			z._rush_t = 2.5
	if _wind > 0.0:
		_wind -= delta
		if _wind <= 0.0:
			_throw(pl)
		z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	if flares > 0 and _cd <= 0.0 and absf(d.x) > 120.0 and absf(d.x) < 480.0 and absf(d.y) < 100.0:
		_wind = 0.5
		z._dir = signf(d.x)
		Sfx.play("hl_hiss", z.global_position, -4.0, 0.1, 2)
		return true
	return false


func _throw(pl: Node) -> void:
	flares -= 1
	throws += 1
	_cd = THROW_CD
	# אל מאחוריך: בצד הרחוק מהזומבים
	var back := signf(pl.global_position.x - z.global_position.x)
	var tx: float = pl.global_position.x + back * 150.0
	var f := Flare.new()
	z.get_parent().add_child(f)
	f.global_position = _hand()
	var fl := 0.8
	f.vel = Vector2((tx - f.global_position.x) / fl, (pl.global_position.y - f.global_position.y) / fl - 0.5 * 900.0 * fl)
	f.floor_y = pl.global_position.y


class Flare extends Node2D:   # הזיקוק באוויר -> אש על הקרקע
	var vel := Vector2.ZERO
	var floor_y := 630.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 8

	func _physics_process(delta: float) -> void:
		_t += delta
		vel.y += 900.0 * delta
		var to := global_position + vel * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
		if not hit.is_empty() or to.y >= floor_y or _t > 3.0:
			var fire := FlareFire.new()
			get_parent().add_child(fire)
			fire.global_position = Vector2(to.x, floor_y if hit.is_empty() else float(hit.position.y))
			queue_free()
			return
		global_position = to
		rotation += 10.0 * delta
		if Engine.get_physics_frames() % 3 == 0:
			preload("res://particles.gd").burst(get_parent(), global_position, "smoke", Vector2.UP, 1)
		queue_redraw()

	func _draw() -> void:
		DrawBatch.line(self, Vector2(-5, 0), Vector2(5, 0), Color("c03020"), 3.0)
		DrawBatch.circle(self, Vector2(5, 0), 3.0, Color(1.0, 0.7, 0.5))
		DrawBatch.circle(self, Vector2(5, 0), 7.0, Color(1.0, 0.3, 0.2, 0.35))


class FlareFire extends Node2D:   # אש סינליזדור על הקרקע
	const T := 5.0   # = BURN_T
	const W := 80.0
	var _t := 0.0
	var _tick := 0.0

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		preload("res://sfx.gd").play("hl_hiss", global_position, 0.0, 0.1, 2)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -50), Vector2(W, 50))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.9
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and world_rect().has_point(pl.global_position + Vector2(0, -10)):
				pl.hurt(1, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 0.8, -0.6))
		if Engine.get_physics_frames() % 4 == 0:
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-W * 0.4, W * 0.4), -6), "fire", Vector2.UP, 2)
		if Engine.get_physics_frames() % 9 == 0:
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-W * 0.3, W * 0.3), -20), "smoke", Vector2.UP, 1)
		if _t > T:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf((T - _t) / 1.0, 0.0, 1.0)
		Art.glow(self, Vector2(0, -12), 50.0, Color(1.0, 0.25, 0.15, 0.35 * a))
		for q in 5:   # לשונות אש אדומות
			var x := -W * 0.4 + float(q) * W * 0.2
			var h := (18.0 + 10.0 * sin(_t * 14.0 + float(q) * 1.7)) * a
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x - 6, 0), Vector2(x + 1, -h), Vector2(x + 7, 0)]), Color(1.0, 0.25 + 0.2 * float(q % 2), 0.15, 0.85))
		DrawBatch.line(self, Vector2(-6, -2), Vector2(6, -1), Color("c03020"), 3.0)


# ============================================================
#  ציור: בלי חולצה, צעיף צהוב-ירוק על הפנים, מכנסיים קצרים, זיקוק בוער ביד מורמת
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], sk.darkened(0.2), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], sk, sk, col(z.shoe))
	DrawBatch.rect(z, Rect2(hip + Vector2(-6, -2), Vector2(12, 9)), col(z.pants))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-6.0 - sin(p) * 2.0, 14.0), Art.shade(sk, 0.25), Art.shade(sk, 0.25))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, -1), hip + Vector2(-6, -1)]), sk, 0.15, 0.4)
	DrawBatch.line(z, sh + Vector2(-5, 6), sh + Vector2(5, 6), sk.darkened(0.3), 1.0)
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-5, 0), head + Vector2(6, 0), head + Vector2(6, 5), head + Vector2(-5, 5)]), col(Color("e0d020")))   # צעיף
	DrawBatch.line(z, head + Vector2(-5, 3), head + Vector2(6, 3), col(Color("2a8a3a")), 1.5)
	DrawBatch.line(z, sh + Vector2(-6, -1), sh + Vector2(-9, 12), col(Color("e0d020")), 2.5)   # קצה הצעיף
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -2.0), 1.1, Color(1.0, 0.85, 0.4))
	var hf := sh + Vector2(6, -16) if _wind > 0.0 else sh + Vector2(10, -10)
	z._arm(sh + Vector2(3, 1), hf, sk, sk)
	if flares > 0:   # הזיקוק
		DrawBatch.line(z, hf, hf + Vector2(0, -8), col(Color("c03020")), 2.5)
		if not z.dead:
			Art.glow(z, hf + Vector2(0, -10), 9.0 + 2.0 * sin(z._time * 30.0), Color(1.0, 0.3, 0.2, 0.6))
			DrawBatch.circle(z, hf + Vector2(0, -10), 2.0, Color(1.0, 0.85, 0.7))
	end_draw()
	return true
