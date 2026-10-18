extends "res://enemies/zombie_type.gd"
# ============================================================
#  ROD (שלב 25, "RADIO TOWER") - זומבי עובד חשמל במעיל גשם צהוב, מחזיק מוט ברזל עם קצה נחושת (כליא ברק).
#    WALK  - שומר מרחק (keep_range), נסוג אם אתה קרוב (BACKOFF).
#    RAISE - מרים את המוט לשמיים (RAISE_T), ניצוצות בקצה.
#    -> מסמן עיגול על הקרקע מתחתיך (Strike), WARN_T שניות אזהרה, ואז ברק נופל שם (DAMAGE, רדיוס R).
#       הברק פוגע גם בזומבים שעומדים בעיגול!
#  התחמקות: לזוז ברגע שמופיע העיגול (הוא לא זז אחריך).
#  בוס: THE STORMBRINGER - 3 ברקים ברצף (עליך, לפניך, מאחוריך).
#  לשנות: RANGE, RAISE_T, WARN_T, R, DAMAGE, CD.
# ============================================================

const RANGE := 620.0
const RAISE_T := 0.5
const WARN_T := 0.9
const R := 42.0
const DAMAGE := 2
const CD := Vector2(4.5, 6.0)
const BACKOFF := 120.0      # קרוב מזה - נסוג

enum { WALK, RAISE }
var state := WALK
var strikes := 0             # לבדיקות
var strike_hits := 0
var _st := 0.0
var _cd := 2.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "ROD", "hp": 400, "walk": 46.0, "chase": 88.0, "damage": 2, "bite_delay": 0.9, "scale": 1.75, "width": 1.1,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9aa0"), "shirt": Color("c8a020"), "pants": Color("2a3038"), "shoe": Color("1a1a1e"),
			"points": 1200, "boss": true, "boss_name": "THE STORMBRINGER - MOVE WHEN THE CIRCLE APPEARS"}
	return {"name": "ROD", "hp": 40, "walk": 44.0, "chase": 86.0, "damage": 1, "bite_delay": 0.8, "scale": 1.1, "width": 1.0,
		"duck": 0.1, "cover": 0.4, "skin": Color("8a9aa0"), "shirt": Color("c8a020"), "pants": Color("2a3038"), "shoe": Color("1a1a1e"), "points": 500}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3, "keep_range": 320.0}


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
			if has_pl and _cd <= 0.0 and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees or absf(d.x) < 420.0
				if sees and absf(d.x) < RANGE and absf(d.y) < 300.0:
					state = RAISE
					_st = RAISE_T
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					Sfx.play("s25_zap", z.global_position, -6.0, 0.1, 2, 1.4)
					return _stay(delta)
			if has_pl and z.is_on_floor():   # קרוב מדי: נסוג אחורה (ופונה אליך)
				var dd: Vector2 = pl.global_position - z.global_position
				if absf(dd.x) < BACKOFF and absf(dd.y) < 60.0 and not z.is_on_wall():
					z._dir = signf(dd.x) if dd.x != 0.0 else z._dir
					z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.7, 700.0 * delta)
					z.velocity.y += z.gravity * delta
					z.move_and_slide()
					return true
			return false
		RAISE:
			if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), _tip(), "spark", Vector2.UP, 2)
			if _st <= 0.0:
				if has_pl:
					_call_strikes(pl)
				state = WALK
				_cd = randf_range(CD.x, CD.y) * (0.8 if _boss() else 1.0)
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _tip() -> Vector2:
	return z.global_position + Vector2(z._dir * 6.0, -78.0) * z.sc


func _call_strikes(pl: Node) -> void:
	var px: float = pl.global_position.x
	var offs := [0.0]
	if _boss():
		var mv := signf(pl.velocity.x) if absf(pl.velocity.x) > 20.0 else (1.0 if randf() < 0.5 else -1.0)
		offs = [0.0, mv * 130.0, -mv * 130.0]
	for i in offs.size():
		var x: float = px + float(offs[i])
		var top := Vector2(x, pl.global_position.y - 60.0)
		var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(top, top + Vector2(0, 600), 1 | 16))
		var s := Strike.new()
		s.delay = WARN_T + float(i) * 0.3
		s.radius = R * (1.2 if _boss() else 1.0)
		s.damage = DAMAGE
		s.src_z = z
		z.get_parent().add_child(s)
		s.global_position = hit.position if hit else Vector2(x, pl.global_position.y)
		strikes += 1


# ============================================================
#  ציור: מעיל גשם צהוב עם ברדס, מגפיים, מוט ברזל ארוך עם קצה נחושת. RAISE = המוט מורם ישר למעלה.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	# מעיל גשם ארוך
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(8, 8), hip + Vector2(-8, 8)]), coat, 0.18, 0.35)
	DrawBatch.line(z, sh + Vector2(1, 0), hip + Vector2(1, 8), col(Color("8a6a10")), 1.0)
	DrawBatch.rect(z, Rect2(hip + Vector2(-7, 2), Vector2(15, 2)), col(Color(0.85, 0.85, 0.8)))   # פס מחזיר אור
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-7, 3), head + Vector2(-6, -5), head + Vector2(0, -8), head + Vector2(6, -6), head + Vector2(5, -3), head + Vector2(-2, -3), head + Vector2(-3, 4)]), coat, Art.OUTLINE, 1.0)   # ברדס
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -0.5), 0.9, Color(1.0, 0.5, 0.2))
	# מוט
	var hand: Vector2
	var tip: Vector2
	if state == RAISE and not z.dead:
		hand = sh + Vector2(6, -10)
		tip = hand + Vector2(1, -32)
	else:
		hand = sh + Vector2(9.0 + sin(p) * 2.0, 12.0)
		tip = hand + Vector2(10, -34)
	var butt := hand + (hand - tip).normalized() * 10.0
	DrawBatch.line(z, butt, tip, Art.OUTLINE, 3.6)
	DrawBatch.line(z, butt, tip, col(Color("8a8e94")), 2.2)
	DrawBatch.colored_polygon(z, PackedVector2Array([tip + Vector2(-2.2, 2), tip + Vector2(0, -6), tip + Vector2(2.2, 2)]), col(Color("d88a40")))   # קצה נחושת
	if state == RAISE and not z.dead:
		Art.glow(z, tip, 14.0, Color(0.6, 0.85, 1.0, 0.6))
		for q in 3:
			var a := randf() * TAU
			DrawBatch.line(z, tip, tip + Vector2.from_angle(a) * randf_range(5.0, 10.0), Color(0.85, 0.95, 1.0, 0.9), 1.2)
	z._arm(sh + Vector2(3, 1), hand, sk, coat)
	end_draw()
	return true


# ---- הברק: עיגול אזהרה על הקרקע, ואז ברק מהשמיים ----
class Strike extends Node2D:
	var delay := 0.9
	var radius := 42.0
	var damage := 2
	var src_z: Node = null
	var hit_player := 0
	var _t := 0.0
	var _bolt := PackedVector2Array()
	var _done := false

	func _ready() -> void:
		z_index = 8
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-radius, -60.0), Vector2(radius * 2.0, 62.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:   # זומבים חכמים לא נכנסים לעיגול
		return not _done and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not _done and _t >= delay:
			_done = true
			_strike()
		if _t > delay + 0.35:
			queue_free()
			return
		queue_redraw()

	func _strike() -> void:
		_bolt = PackedVector2Array([Vector2(randf_range(-40.0, 40.0), -720.0)])
		var y := -720.0
		var x: float = _bolt[0].x
		while y < -30.0:
			y += randf_range(40.0, 80.0)
			x = clampf(x + randf_range(-30.0, 30.0), -50.0, 50.0)
			_bolt.append(Vector2(x, minf(y, 0.0)))
		_bolt.append(Vector2.ZERO)
		var Sfx := preload("res://sfx.gd")
		Sfx.play("thunder", global_position, 2.0, 0.15, 2)
		Sfx.play("s25_zap", global_position, 4.0, 0.1, 3)
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -4), "spark", Vector2.UP, 16)
		preload("res://particles.gd").burst(get_parent(), global_position, "smoke", Vector2.UP, 6)
		var st := preload("res://effects/s25_decor.gd").storm()
		if st != null:
			st.strike_flash()
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(6.0, 0.25)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead:
			var b: Rect2 = pl.body_rect()
			if absf(b.get_center().x - global_position.x) < radius + b.size.x * 0.3 and b.end.y > global_position.y - 70.0 and b.position.y < global_position.y + 4.0:
				if pl._invuln <= 0.0:
					hit_player += 1
					if src_z != null and is_instance_valid(src_z) and src_z.type_mod != null:
						src_z.type_mod.strike_hits += 1
				pl.hurt(damage, Vector2(signf(b.get_center().x - global_position.x), -1.4))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z == src_z:
				continue
			if absf(z.global_position.x - global_position.x) < radius + 8.0 and absf(z.global_position.y - global_position.y) < 20.0:
				z.take_damage(30, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard", "fixed": 30})

	func _draw() -> void:
		if not _done:   # עיגול אזהרה שמתכווץ
			var k := clampf(_t / delay, 0.0, 1.0)
			var blink := fmod(_t * 8.0, 1.0) < 0.6
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2.ZERO, radius, radius * 0.22, 0.0, 20), Color(0.5, 0.8, 1.0, 0.18 + 0.2 * k))
			DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(1.0, 0.22))   # עיגולים "שוכבים" על הקרקע
			DrawBatch.arc(self, Vector2.ZERO, radius, 0, TAU, 24, Color(0.7, 0.9, 1.0, 0.9 if blink else 0.5), 3.0)
			DrawBatch.arc(self, Vector2.ZERO, radius * (1.0 - k) + 4.0, 0, TAU, 20, Color(1, 1, 1, 0.7), 2.0)
			DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
			DrawBatch.line(self, Vector2(0, -6), Vector2(0, -30.0 * k), Color(0.8, 0.95, 1.0, 0.6 * k), 2.0)
		else:
			var a := clampf(1.0 - (_t - delay) / 0.35, 0.0, 1.0)
			DrawBatch.polyline(self, _bolt, Color(0.6, 0.85, 1.0, 0.5 * a), 7.0)
			DrawBatch.polyline(self, _bolt, Color(1, 1, 1, a), 2.5)
			Art.glow(self, Vector2(0, -6), radius * 1.4, Color(0.6, 0.85, 1.0, 0.6 * a))
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2.ZERO, radius, radius * 0.22, 0.0, 20), Color(0.05, 0.05, 0.06, 0.6 * a))
