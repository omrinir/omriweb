extends RefCounted
# ============================================================
#  שלב 12 (צפון-מזרח, "THE LIGHTHOUSE") - חפצים משותפים:
#   ThrownHand - כף יד כרותה שנזרקת (SPARE PARTS). פוגעת בשחקן (1), נוחתת ונשארת לכמה שניות.
#   QuickSand  - חול טובעני: מאט מאוד את מי שבתוכו (שחקן וזומבים), ופוגע בשחקן אם הוא נשאר בו.
#                יד של שלד מבצבצת מהחול ונבלעת - אזהרה.
# ============================================================


class ThrownHand extends Node2D:
	const GRAV := 1100.0
	var velocity := Vector2.ZERO
	var skin := Color("a09a86")
	var landed := false
	var life := 6.0
	var _spin := 0.0

	func _ready() -> void:
		z_index = 8
		_spin = randf_range(10.0, 16.0) * (1.0 if velocity.x >= 0.0 else -1.0)

	func _physics_process(delta: float) -> void:
		if landed:
			life -= delta
			modulate.a = clampf(life, 0.0, 1.0)
			if life <= 0.0:
				queue_free()
			return
		velocity.y += GRAV * delta
		var to := global_position + velocity * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | (16 if velocity.y > 0.0 else 0)))
		if not hit.is_empty():
			global_position = hit.position
			landed = true
			rotation = 0.0
			queue_redraw()
			return
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and p.body_rect().grow(4.0).has_point(to):
			p.hurt(1, Vector2(signf(velocity.x), -0.2))
			Particles.burst(get_parent(), to, "hit", -velocity.normalized(), 6)
			landed = true
			life = 2.0
			velocity = Vector2.ZERO
			return
		global_position = to
		rotation += _spin * delta
		queue_redraw()

	func _draw() -> void:
		Art.limb(self, PackedVector2Array([Vector2(-6, 0), Vector2(1, 0)]), 4.2, skin)
		Art.disc(self, Vector2(-7, 0), 2.4, Color(0.5, 0.03, 0.05), Art.NONE)
		Art.disc(self, Vector2(2, 0), 3.2, skin)
		for i in 4:   # אצבעות
			var a := -0.8 + float(i) * 0.5
			var d := Vector2.from_angle(a)
			draw_line(Vector2(3, 0) + d, Vector2(3, 0) + d * 5.5, Art.OUTLINE, 2.2, true)
			draw_line(Vector2(3, 0) + d, Vector2(3, 0) + d * 5.5, skin, 1.2, true)

	const Art := preload("res://art.gd")
	const Particles := preload("res://particles.gd")


class QuickSand extends "res://environment/hazard.gd":
	const SLOW := 70.0          # מהירות מקסימלית בתוך החול
	var width := 120.0
	var _t := 0.0
	var _in_t := 0.0            # כמה זמן השחקן בתוך החול
	var _hand_t := 0.0

	func _ready() -> void:
		super._ready()
		rect = Rect2(-width * 0.5, -20.0, width, 21.0)
		player_damage = 0          # הנזק כאן מנוהל לפי זמן (למטה)
		tick = 0.3
		z_index = 4
		_hand_t = randf_range(2.0, 5.0)

	func _hazard_tick(delta: float) -> void:
		_t += delta
		var r := world_rect()
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and r.intersects(p.body_rect()) and p.is_on_floor():
			p.velocity.x = clampf(p.velocity.x, -SLOW, SLOW)   # בוץ: כמעט לא זזים
			if p.velocity.y < 0.0:
				p.velocity.y *= 0.82   # קשה לקפוץ החוצה
			_in_t += delta
			if _in_t > 1.2:   # שוקע
				_in_t = 0.4
				p.hurt(1, Vector2.ZERO)
		else:
			_in_t = maxf(_in_t - delta * 2.0, 0.0)
		for zz in get_tree().get_nodes_in_group("zombies"):
			if not zz.dead and r.has_point(zz.global_position + Vector2(0, -6)):
				zz.velocity.x = clampf(zz.velocity.x, -SLOW * 0.6, SLOW * 0.6)
		_hand_t -= delta
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var hw := width * 0.5
		var pts := PackedVector2Array()
		for i in 17:   # שקע מעוגל בחול
			var u := float(i) / 16.0
			pts.append(Vector2(lerpf(-hw, hw, u), -1.0 + sin(u * PI) * 6.0))
		pts.append(Vector2(hw, 7.0))   # מתחת לשקע (אחרת המצולע נחתך)
		pts.append(Vector2(-hw, 7.0))
		draw_colored_polygon(pts, Color("8a6a40"))
		for k in 3:   # טבעות שמסתובבות לאט (מערבולת)
			var rr := fposmod(_t * 10.0 + float(k) * 14.0, 42.0)
			draw_arc(Vector2(0, 1), rr * hw / 42.0, PI + 0.2, TAU - 0.2, 14, Color(0.35, 0.25, 0.12, 0.5 * (1.0 - rr / 42.0)), 1.5)
		for i in 3:   # בועות
			var bx := sin(_t * 1.3 + float(i) * 2.0) * hw * 0.6
			if fmod(_t + float(i) * 0.7, 2.0) < 0.3:
				draw_circle(Vector2(bx, 0.0), 2.0, Color(0.45, 0.35, 0.2))
		if _hand_t < 0.0 and _hand_t > -2.5:   # יד של שלד עולה ונבלעת
			var k := -_hand_t / 2.5
			var h := sin(k * PI) * 18.0
			var hx := hw * 0.3
			draw_line(Vector2(hx, 2), Vector2(hx + 2, -h), Color("d8d0b8"), 2.0)
			for f in 4:
				draw_line(Vector2(hx + 2, -h), Vector2(hx - 2 + float(f) * 2.0, -h - 6.0), Color("d8d0b8"), 1.2)
		elif _hand_t <= -2.5:
			_hand_t = randf_range(4.0, 8.0)

	const Art := preload("res://art.gd")
