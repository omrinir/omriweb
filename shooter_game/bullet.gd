extends Node2D
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
# ============================================================
#  קליע. נוצר ע"י player.gd בכל ירייה.
#  הקליע בודק התנגשות עם קרניים (Raycast) כדי שלא יעבור דרך
#  לבנים דקות גם כשהוא מהיר מאוד.
# ============================================================

# ---- אפשר לשנות ----
var life_time := 2.0                       # כמה שניות הקליע חי לפני שנעלם
var length := 22.0                         # אורך הקו של הקליע
var width := 3.0                           # עובי
var bullet_color := Color(1.0, 0.85, 0.3)  # צבע
var collision_mask := 5                    # 1 = ריצפה ולבנים, 4 = זומבים
var max_offscreen := 70.0                  # כמה פיקסלים אחרי קצה המסך הקליע עוד ממשיך
var damage := 0                            # הנזק נקבע בזומבי לפי מקום הפגיעה (ראש / גוף / רגל)

var pierce := 0                            # בוסט: כמה זומבים נוספים הקליע עובר דרכם
var incendiary := false                    # בוסט: הקליע מצית זומבים
var falloff := []                          # שוטגאן: [נזק קרוב, נזק רחוק, מרחק] - הנזק יורד עם המרחק
var fixed_damage := []                     # [min, max] נזק קבוע (חץ)
var dmg_mult := 1.0                        # מכפיל נזק של הנשק (weapon_db.gd)
var head_mult := 1.0                       # מכפיל לירייה בראש (נשקים אוטומטיים: פחות מ-1)
var knockback := 60.0                      # כמה הזומבי נהדף
var weapon_id := 0
var arrow := false                         # חץ: עף בקשת (כבידה), נזק 13-19, ננעץ בריצפה ואפשר לאסוף
var gravity := 0.0
var _stuck := -1.0                         # חץ שננעץ: כמה זמן נשאר
var sniper := false                        # צלף: נזק כפול בראש, פי 1.5 בגוף
var count_hit := true                      # false = לא נספר לדיוק (כדורי שוטגאן נוספים)
var _dist := 0.0
var velocity := Vector2.ZERO
var _exclude: Array[RID] = []
var _cast_from := Vector2.ZERO
var _first := true


func setup(muzzle_pos: Vector2, vel: Vector2, check_from: Vector2) -> void:
	global_position = muzzle_pos
	velocity = vel
	rotation = vel.angle()
	_cast_from = check_from   # בצעד הראשון בודקים מהכתף, למקרה שהלוע בתוך קיר
	z_index = 10


func _physics_process(delta: float) -> void:
	if _stuck >= 0.0:   # חץ תקוע: השחקן יכול לאסוף אותו
		_stuck -= delta
		modulate.a = clampf(_stuck, 0.0, 1.0)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.global_position.distance_to(global_position) < 26.0 and pl.add_ammo(2, 1):
			queue_free()
		elif _stuck <= 0.0:
			queue_free()
		return
	if gravity != 0.0:
		velocity.y += gravity * delta
		rotation = velocity.angle()
	life_time -= delta
	if life_time <= 0.0:
		queue_free()
		return
	var from := _cast_from if _first else global_position
	_first = false
	var to := global_position + velocity * delta
	# הקליע נעלם 70 פיקסלים אחרי קצה המסך
	var vp := get_viewport()
	var view := (vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()).grow(max_offscreen)
	if not view.has_point(to):
		if view.has_point(global_position):   # בודקים פגיעה רק עד הגבול
			to = global_position + velocity.normalized() * _dist_to_edge(view, global_position, velocity.normalized())
		else:
			queue_free()
			return
	# קליע שפוגע ברגל שזומבי זרק - מפיל אותה מהאוויר
	for leg in get_tree().get_nodes_in_group("severed_legs"):
		if leg.state == 2 and Geometry2D.get_closest_point_to_segment(leg.global_position, from, to).distance_to(leg.global_position) < 16.0:
			leg.shot_down(velocity.normalized())
			Game.on_leg_shot()
	for lp in get_tree().get_nodes_in_group("lamps"):   # נורה של פנס רחוב
		if lp.hit_test(from, to):
			lp.shatter(velocity.normalized())
			queue_free()
			return
	for mh in get_tree().get_nodes_in_group("manholes"):   # מכסה ביוב קופץ
		if mh.hit_test(from, to):
			mh.pop(velocity.normalized())
	_dist += from.distance_to(to)
	var src := {"source": "bullet", "bullet": get_instance_id(), "incendiary": incendiary, "sniper": sniper, "counted": not count_hit}
	src["dmg_mult"] = dmg_mult
	src["head_mult"] = head_mult
	src["knockback"] = knockback
	src["weapon"] = weapon_id
	if falloff.size() == 3:   # שוטגאן: הרבה נזק מקרוב, יורד עם המרחק
		src["fixed"] = int(round(lerpf(float(falloff[0]), float(falloff[1]), clampf((_dist - 50.0) / (float(falloff[2]) - 50.0), 0.0, 1.0))))
	elif fixed_damage.size() == 2:
		src["fixed"] = randi_range(int(fixed_damage[0]), int(fixed_damage[1]))
	elif arrow:
		src["fixed"] = randi_range(13, 19)
	while true:
		var query := PhysicsRayQueryParameters2D.create(from, to, collision_mask, _exclude)
		query.hit_from_inside = true   # זומבי צמוד לקנה (הקרן מתחילה בתוכו) - עדיין נפגע
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not hit:
			break
		if hit.normal == Vector2.ZERO and not hit.collider.is_in_group("zombies"):   # מתחילים בתוך קיר/ניצולה - מתעלמים כמו קודם
			_exclude.append(hit.rid)
			continue
		if hit.collider.has_method("take_damage"):
			# שולחים גם את כיוון הקליע - לפיו הזומבי עף כשהוא מת
			hit.collider.take_damage(damage, hit.position, velocity.normalized(), false, src)
			if pierce > 0:   # קליע חודר: ממשיך לזומבי הבא
				pierce -= 1
				_exclude.append(hit.rid)
				from = hit.position
				continue
		else:
			if hit.collider.has_method("hit_by_bullet"):   # לבנה - נסדקת / נשברת
				hit.collider.hit_by_bullet(hit.position, hit.normal, velocity.normalized())
			if arrow:   # החץ ננעץ ונשאר (אפשר לאסוף)
				global_position = hit.position - velocity.normalized() * 4.0
				_stuck = 8.0
				Sfx.play("arrow_hit", global_position, -4.0)
				return
			if randf() < 0.35:
				Sfx.play("ricochet", hit.position, -8.0, 0.25, 2)
			var fx := Impact.new()   # ניצוצות רק על לבנים
			get_parent().add_child(fx)
			fx.global_position = hit.position
			fx.setup(hit.normal)
		queue_free()
		return
	if not view.has_point(to + velocity.normalized()):
		queue_free()
		return
	global_position = to


# כמה פיקסלים עד שהקליע יוצא מהמלבן
func _dist_to_edge(r: Rect2, p: Vector2, d: Vector2) -> float:
	var t := INF
	if d.x > 0.0: t = minf(t, (r.end.x - p.x) / d.x)
	elif d.x < 0.0: t = minf(t, (r.position.x - p.x) / d.x)
	if d.y > 0.0: t = minf(t, (r.end.y - p.y) / d.y)
	elif d.y < 0.0: t = minf(t, (r.position.y - p.y) / d.y)
	return maxf(t - 0.5, 0.0)


func _draw() -> void:
	if arrow:   # חץ: מוט עץ, ראש מתכת ונוצות
		draw_line(Vector2(-22.0, 0.0), Vector2(4.0, 0.0), Color("8a6a40"), 1.6, true)
		draw_colored_polygon(PackedVector2Array([Vector2(4, -2.5), Vector2(10, 0), Vector2(4, 2.5)]), Color("b8b8c0"))
		draw_colored_polygon(PackedVector2Array([Vector2(-22, 0), Vector2(-17, -3.5), Vector2(-14, -3.5), Vector2(-18, 0)]), Color("d04030"))
		draw_colored_polygon(PackedVector2Array([Vector2(-22, 0), Vector2(-17, 3.5), Vector2(-14, 3.5), Vector2(-18, 0)]), Color("d04030"))
		return
	# שובל אוויר דק ושקוף (כדי שיהיה אפשר לראות את הקליע זז)
	draw_line(Vector2(-34.0, 0.0), Vector2(-6.0, 0.0), Color(0.9, 0.9, 0.95, 0.12), 2.0, true)
	draw_line(Vector2(-18.0, 0.0), Vector2(-6.0, 0.0), Color(0.9, 0.9, 0.95, 0.22), 1.2, true)
	# הקליע: גוף נחושת עם חוד מעוגל
	var body := PackedVector2Array([
		Vector2(-6.0, -1.6), Vector2(1.0, -1.6), Vector2(3.5, -1.2), Vector2(5.2, -0.5), Vector2(5.6, 0.0),
		Vector2(5.2, 0.5), Vector2(3.5, 1.2), Vector2(1.0, 1.6), Vector2(-6.0, 1.6),
	])
	var light := Color("e0a060")
	var dark := Color("8a4a20")
	if sniper:   # צלף: שובל ארוך ובהיר
		draw_line(Vector2(-90.0, 0.0), Vector2(-6.0, 0.0), Color(0.6, 0.85, 1.0, 0.35), 2.0, true)
	if pierce > 0:   # קליע חודר - כחול
		light = Color("90c8ff")
		dark = Color("2a5a9a")
		draw_line(Vector2(-40.0, 0.0), Vector2(-6.0, 0.0), Color(0.4, 0.7, 1.0, 0.35), 3.0, true)
	elif incendiary:  # קליע אש - כתום
		light = Color("ffc060")
		dark = Color("c04010")
		draw_line(Vector2(-30.0, 0.0), Vector2(-6.0, 0.0), Color(1.0, 0.5, 0.1, 0.4), 3.0, true)
	draw_polygon(body, PackedColorArray([dark, light, light, light, light, dark, dark, dark, dark]))
	var closed := PackedVector2Array(body)
	closed.append(body[0])
	draw_polyline(closed, Color(0.15, 0.08, 0.04, 0.9), 0.8, true)
	draw_line(Vector2(-5.0, -0.7), Vector2(2.5, -0.7), Color(1.0, 0.9, 0.7, 0.7), 0.6, true)   # ברק של מתכת
	draw_line(Vector2(-6.0, -1.6), Vector2(-6.0, 1.6), Color(0.25, 0.15, 0.1), 1.0)              # בסיס


# ---- ניצוצות כשהקליע פוגע ----
class Impact extends Node2D:
	var t := 0.0
	var duration := 0.25
	var dirs: Array[Vector2] = []

	func setup(normal: Vector2) -> void:
		z_index = 10
		for i in 7:
			dirs.append(Vector2.from_angle(normal.angle() + randf_range(-1.2, 1.2)) * randf_range(40.0, 140.0))

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		if t >= duration:
			queue_free()

	func _draw() -> void:
		var k := t / duration
		for d in dirs:
			draw_circle(d * t, 2.2 * (1.0 - k), Color(1.0, 0.8, 0.3, 1.0 - k))
