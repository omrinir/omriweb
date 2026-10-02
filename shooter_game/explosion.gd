extends RefCounted
# ============================================================
#  פיצוץ משותף: רימון, חביות נפץ ומכוניות משתמשים באותו פיצוץ.
#  Boom.blast(...) פוגע בכל מה שבטווח, מרעיד את המצלמה
#  ויוצר את אפקט האש והעשן.
# ============================================================


# center = מרכז הפיצוץ, radius = טווח, break_radius = לבנים קרובות מזה נשברות מיד,
# damage = נזק לזומבים, player_damage = נזק לשחקן (אם הוא קרוב)
static func blast(parent: Node2D, center: Vector2, radius := 120.0, break_radius := 70.0, damage := 40, player_damage := 2) -> void:
	var tree := parent.get_tree()
	# לבנים, מכוניות, חביות...
	for b in tree.get_nodes_in_group("blastable"):
		if b.has_method("hit_by_blast") and b.has_method("blast_rect"):
			var r: Rect2 = b.blast_rect()
			var cp := Vector2(clampf(center.x, r.position.x, r.end.x), clampf(center.y, r.position.y, r.end.y))
			if center.distance_to(cp) <= radius:
				b.hit_by_blast(center, break_radius)
	for z in tree.get_nodes_in_group("zombies"):
		var zc: Vector2 = z.global_position + Vector2(0, -32)
		if center.distance_to(zc) <= radius:
			z.take_damage(damage, zc, (zc - center).normalized(), true)
	for sv in tree.get_nodes_in_group("survivors"):
		var sc: Vector2 = sv.global_position + Vector2(0, -26)
		if center.distance_to(sc) <= radius:
			sv.take_damage(damage, sc, (sc - center).normalized(), true)
	var p := tree.get_first_node_in_group("player")
	if p != null:
		var pc: Vector2 = p.global_position + Vector2(0, -26)
		if center.distance_to(pc) <= radius * 0.6:
			p.hurt(player_damage, Vector2(signf(pc.x - center.x), 0.0))
	var cam := parent.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(16.0, 0.45)
	# על הריצפה? אז האש והעשן הולכים רק למעלה ולצדדים
	var q := PhysicsRayQueryParameters2D.create(center, center + Vector2(0.0, 24.0), 1)
	var on_ground := not parent.get_world_2d().direct_space_state.intersect_ray(q).is_empty()
	var fx := Explosion.new()
	fx.radius = radius
	fx.on_ground = on_ground
	parent.add_child(fx)
	fx.global_position = center
	var smoke := Smoke.new()
	smoke.radius = radius
	smoke.on_ground = on_ground
	parent.add_child(smoke)
	smoke.global_position = center


# ============================================================
#  אפקט הפיצוץ: הבזק, רסיסי אש שיוצאים לכל הכיוונים,
#  כדור אש, ניצוצות ואדמה שעפים, ואחר כך עשן שעולה ומתפזר.
# ============================================================
class Explosion extends Node2D:
	var radius := 120.0
	var on_ground := false
	var duration := 0.6
	var t := 0.0
	var _spikes := []    # [זווית, אורך, רוחב, עיכוב]
	var _blobs := []     # [מיקום, רדיוס]
	var _parts := []     # ניצוצות ואדמה: [מיקום, מהירות, חיים, סוג]

	func _ready() -> void:
		z_index = 20
		for i in 34:
			_spikes.append([_angle(), radius * randf_range(0.5, 1.35), randf_range(4.0, 13.0), randf() * 0.05])
		for i in 9:
			var bp := Vector2.from_angle(_angle()) * radius * randf_range(0.05, 0.3)
			_blobs.append([bp, radius * randf_range(0.18, 0.32)])
		for i in 40:
			var dirt := i % 3 == 0
			var v := Vector2.from_angle(_angle()) * randf_range(200.0, 650.0) + Vector2(0.0, -150.0)
			_parts.append([Vector2.ZERO, v, randf_range(0.4, 0.9), dirt])

	# כיוון אקראי. על הריצפה - רק חצי העליון (קצת מתחת לאופק)
	func _angle() -> float:
		if on_ground:
			return randf_range(-PI - 0.2, 0.2)
		return randf() * TAU

	func _process(delta: float) -> void:
		t += delta
		for p in _parts:
			p[1].y += 900.0 * delta
			p[1] *= 1.0 - 1.5 * delta
			p[0] += p[1] * delta
			p[2] -= delta
		queue_redraw()
		if t >= 1.0:
			queue_free()

	func _draw() -> void:
		var k := clampf(t / duration, 0.0, 1.0)
		var ease := 1.0 - pow(1.0 - clampf(t / 0.18, 0.0, 1.0), 3.0)   # מתפרץ מהר ומאט
		var fade := 1.0 - k
		# הבזק לבן
		if t < 0.1:
			draw_circle(Vector2.ZERO, radius * 1.3, Color(1.0, 0.95, 0.8, 0.5 * (1.0 - t / 0.1)))
		if k < 1.0:
			# רסיסי אש: משולשים ארוכים מצהוב-לבן במרכז לחום בקצה
			for sp in _spikes:
				var g := clampf((t - sp[3]) / 0.18, 0.0, 1.0)
				g = 1.0 - pow(1.0 - g, 3.0)
				if g <= 0.0:
					continue
				var dir := Vector2.from_angle(sp[0])
				var nrm := dir.orthogonal()
				var base := dir * radius * 0.12
				var tip: Vector2 = dir * float(sp[1]) * g
				var w: float = sp[2] * (1.0 - k * 0.6)
				var mid := base.lerp(tip, 0.45)
				var pts := PackedVector2Array([base + nrm * w * 0.6, mid + nrm * w * 0.5, tip, mid - nrm * w * 0.5, base - nrm * w * 0.6])
				var a := fade
				var cols := PackedColorArray([
					Color(1.0, 0.95, 0.7, a), Color(1.0, 0.55, 0.15, a), Color(0.45, 0.25, 0.15, a * 0.6),
					Color(1.0, 0.55, 0.15, a), Color(1.0, 0.95, 0.7, a),
				])
				draw_polygon(pts, cols)
			# כדור אש: כתום מבחוץ, צהוב-לבן במרכז
			for b in _blobs:
				var r: float = b[1] * (0.6 + ease * 0.7) * (1.0 - k * 0.5)
				draw_circle(b[0] * (0.5 + ease), r, Color(0.95, 0.4, 0.1, 0.75 * fade))
			for b in _blobs:
				var r: float = b[1] * (0.4 + ease * 0.5) * (1.0 - k * 0.7)
				draw_circle(b[0] * (0.4 + ease * 0.8), r, Color(1.0, 0.7, 0.2, 0.85 * fade))
			draw_circle(Vector2.ZERO, radius * 0.28 * (1.0 - k), Color(1.0, 0.97, 0.85, fade))
		# ניצוצות ואדמה
		for p in _parts:
			if p[2] <= 0.0:
				continue
			var al := clampf(p[2] * 2.0, 0.0, 1.0)
			if p[3]:
				draw_circle(p[0], 2.2, Color(0.3, 0.2, 0.12, al))
			else:
				draw_line(p[0], p[0] - p[1] * 0.03, Color(1.0, 0.75, 0.3, al), 2.0, true)


# ---- עשן שנשאר אחרי הפיצוץ, עולה למעלה ומתפזר ----
class Smoke extends Node2D:
	var radius := 120.0
	var on_ground := false
	var life := 3.2
	var t := 0.0
	var _puffs := []   # [מיקום, מהירות, רדיוס, עיכוב, גוון]

	func _ready() -> void:
		z_index = 19
		for i in 22:
			var dir := Vector2.from_angle(randf_range(-PI, 0.0) if on_ground else randf() * TAU)
			_puffs.append([dir * radius * randf_range(0.0, 0.35), dir * randf_range(20.0, 70.0) + Vector2(0.0, -randf_range(25.0, 60.0)),
				randf_range(0.18, 0.32) * radius, randf_range(0.05, 0.3), randf_range(0.12, 0.3)])

	func _process(delta: float) -> void:
		t += delta
		for p in _puffs:
			p[0] += p[1] * delta
			p[1] *= 1.0 - 0.6 * delta
			p[1].y -= 8.0 * delta   # עשן חם עולה
		queue_redraw()
		if t >= life:
			queue_free()

	func _draw() -> void:
		for p in _puffs:
			var lt: float = t - p[3]
			if lt <= 0.0:
				continue
			var k := clampf(lt / (life - p[3]), 0.0, 1.0)
			var r: float = p[2] * (0.5 + k * 1.3)
			var a := 0.55 * (1.0 - k) * clampf(lt / 0.15, 0.0, 1.0)
			# בהתחלה העשן מואר בכתום מהאש, ואז נהיה אפור
			var col := Color(0.55, 0.3, 0.15).lerp(Color(p[4], p[4], p[4] + 0.02), clampf(lt / 0.5, 0.0, 1.0))
			draw_circle(p[0], r, Color(col, a))
			draw_circle(p[0] + Vector2(-r * 0.25, -r * 0.25), r * 0.6, Color(col.lightened(0.15), a * 0.6))
