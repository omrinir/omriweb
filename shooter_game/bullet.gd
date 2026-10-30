extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
const VIS_SCALE := 0.45   # גודל הקליע על המסך (רק ויזואלי)
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
const FlameFx := preload("res://effects/flame_fx.gd")   # להבות הלהביור (לשון אש + הילה רכה)
const BulletCam := preload("res://effects/bullet_cam.gd")   # מצלמת קליע (צלף): "מחוץ למסך" = המסך הרגיל, לא הזום
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
var god := false                           # GOD MODE: קליע בוער אדום (שובל חלקיקים, פיצוץ חלקיקים קטן בפגיעה, נזק פי 4)
var _embers := []                          # GOD MODE: [מיקום בעולם, מהירות, גיל, חיים, גודל]
var falloff := []                          # שוטגאן: [נזק קרוב, נזק רחוק, מרחק] - הנזק יורד עם המרחק
var fixed_damage := []                     # [min, max] נזק קבוע (חץ)
var dmg_mult := 1.0                        # מכפיל נזק של הנשק (weapon_db.gd)
var head_mult := 1.0                       # מכפיל לירייה בראש (נשקים אוטומטיים: פחות מ-1)
var knockback := 60.0                      # כמה הזומבי נהדף
var weapon_id := 0
var flame := false                         # FLAMETHROWER: לשון אש שגדלה ודועכת (לא קליע), נעלמת בקיר
var _age := 0.0
var _life0 := 0.0
var arrow := false                         # חץ: עף בקשת (כבידה), נזק 13-19, ננעץ בריצפה ואפשר לאסוף
var gravity := 0.0
var _stuck := -1.0                         # חץ שננעץ: כמה זמן נשאר
var sniper := false                        # צלף: נזק כפול בראש, פי 1.5 בגוף
var shot := 0                              # מספר הירייה (Game.shot_id) - לחישוב הדיוק
var _dist := 0.0
var velocity := Vector2.ZERO
var _exclude: Array[RID] = []
var _cast_from := Vector2.ZERO
var _first := true
var ip_from := Vector2.ZERO                # המיקום בתחילת צעד הפיזיקה האחרון (interp_pos)
const TRACER_K := 0.019                    # שובל נותב: אורך = מהירות x זה (בערך מה שהקליע עובר בפריים), 24-80 פיקסלים
# מצלמת קליע (effects/bullet_cam.gd): הקליע שהמצלמה עוקבת אחריו מצויר בגודל מלא, עם גלי אוויר שיוצאים מהחוד (זמן אמיתי)
const CAM_VIS := 1.0
const WAKE_EVERY := 0.11                   # גל חדש כל ... שניות
const WAKE_LIFE := 0.5
const WAKE_SPEED := 46.0                   # כמה מהר גל נשאר מאחור (פיקסלים בשנייה, יחסית לקליע)
var _cam_drawn := false


func setup(muzzle_pos: Vector2, vel: Vector2, check_from: Vector2) -> void:
	global_position = muzzle_pos
	ip_from = muzzle_pos
	velocity = vel
	rotation = vel.angle()
	_cast_from = check_from   # בצעד הראשון בודקים מהכתף, למקרה שהלוע בתוך קיר
	z_index = 10


func _physics_process(delta: float) -> void:
	ip_from = global_position
	if _cam_drawn or BulletCam.bullet_look(self) > 0.0:
		queue_redraw()
	if _stuck >= 0.0:   # חץ תקוע: השחקן יכול לאסוף אותו
		_stuck -= delta
		modulate.a = clampf(_stuck, 0.0, 1.0)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.global_position.distance_to(global_position) < 26.0 and pl.add_ammo(weapon_id, 1):
			queue_free()
		elif _stuck <= 0.0:
			queue_free()
		return
	if gravity != 0.0:
		velocity.y += gravity * delta
		rotation = velocity.angle()
	if god:
		_update_embers(delta)
	if flame:   # להבה: מאטה, עולה קצת ומתנפחת
		if _life0 <= 0.0:
			_life0 = life_time
			velocity *= randf_range(0.7, 1.05)   # להבות במהירויות שונות = לשון אש רציפה
		_age += delta
		velocity *= 1.0 - 1.6 * delta
		velocity.y -= 90.0 * delta
		queue_redraw()
	life_time -= delta
	if life_time <= 0.0:
		queue_free()
		return
	var from := _cast_from if _first else global_position
	_first = false
	var to := global_position + velocity * delta
	# הקליע נעלם 70 פיקסלים אחרי קצה המסך
	var view := BulletCam.logic_view(get_viewport()).grow(max_offscreen)
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
			Game.story.emit("lamp_shot", {})
			queue_free()
			return
	for mh in get_tree().get_nodes_in_group("manholes"):   # מכסה ביוב קופץ
		if mh.hit_test(from, to):
			mh.pop(velocity.normalized())
	_dist += from.distance_to(to)
	if _dist < 100.0 and not arrow and not flame:   # השובל עוד גדל (לא נמשך אחורה לתוך הדמות בפריים הראשון)
		queue_redraw()
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
			# המילון נבנה רק כשיש פגיעה (לא בכל פריים לכל קליע)
			var src := {"source": "bullet", "bullet": get_instance_id(), "incendiary": incendiary, "sniper": sniper, "shot": shot}
			if god:
				src["god"] = true
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
			# שולחים גם את כיוון הקליע - לפיו הזומבי עף כשהוא מת
			var fleshy: bool = hit.collider.is_in_group("zombies")
			hit.collider.take_damage(damage, hit.position, velocity.normalized(), false, src)
			if fleshy and not flame:
				_flesh_hit(hit.position)
			if god:
				_god_burst(hit.position)
			if pierce > 0:   # קליע חודר: ממשיך לזומבי הבא
				pierce -= 1
				_exclude.append(hit.rid)
				from = hit.position
				continue
		else:
			if hit.collider.has_method("hit_by_bullet"):   # לבנה - נסדקת / נשברת
				hit.collider.hit_by_bullet(hit.position, hit.normal, velocity.normalized())
			if flame:   # להבה נכבית בקיר בלי ניצוצות
				queue_free()
				return
			if arrow:   # החץ ננעץ ונשאר (אפשר לאסוף)
				global_position = hit.position - velocity.normalized() * 4.0
				_stuck = 8.0
				Sfx.play("arrow_hit", global_position, -4.0)
				return
			if god:
				_god_burst(hit.position)
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


# איפה הקליע מצויר עכשיו: בין שני צעדי הפיזיקה האחרונים (physics interpolation, effects/smooth_motion.gd)
func interp_pos() -> Vector2:
	if not is_physics_interpolated_and_enabled():
		return global_position
	return ip_from.lerp(global_position, Engine.get_physics_interpolation_fraction())


# כמה פיקסלים עד שהקליע יוצא מהמלבן
func _dist_to_edge(r: Rect2, p: Vector2, d: Vector2) -> float:
	var t := INF
	if d.x > 0.0: t = minf(t, (r.end.x - p.x) / d.x)
	elif d.x < 0.0: t = minf(t, (r.position.x - p.x) / d.x)
	if d.y > 0.0: t = minf(t, (r.end.y - p.y) / d.y)
	elif d.y < 0.0: t = minf(t, (r.position.y - p.y) / d.y)
	return maxf(t - 0.5, 0.0)


# GOD MODE: גיצים אדומים שנשארים מאחור ודועכים
func _update_embers(delta: float) -> void:
	if Engine.get_physics_frames() % 2 == 0:   # גיץ אחד כל שני פריימים (הרבה קליעים ב-SMG)
		_embers.append([global_position - velocity * delta * randf(), Vector2(randf_range(-30.0, 30.0), randf_range(-60.0, -10.0)) - velocity * 0.04, 0.0, randf_range(0.12, 0.24), randf_range(1.4, 2.6)])
	for e in _embers:
		e[2] += delta
		e[0] += e[1] * delta
	_embers = _embers.filter(func(e): return e[2] < e[3])
	if _embers.size() > 8:
		_embers = _embers.slice(_embers.size() - 8)
	queue_redraw()


# הבזק פגיעה בבשר: נקודה לבנה-חמה + קרניים + ענן אדום קטן (0.09 שנ'). רואים כל פגיעה גם בתוך המון
func _flesh_hit(at: Vector2) -> void:
	if FleshHit.alive >= FleshHit.MAX_ALIVE or arrow:
		return
	var fx := FleshHit.new()
	fx.dir = velocity.normalized()
	get_parent().add_child(fx)
	fx.global_position = at


func _god_burst(at: Vector2) -> void:
	var fx := GodBurst.new()
	get_parent().add_child(fx)
	fx.global_position = at


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	if god:   # שובל אש אדום (בקואורדינטות העולם -> מקומי)
		for e in _embers:
			var k: float = e[2] / e[3]
			var p := to_local(e[0])
			var c := Color(1.0, 0.85, 0.5).lerp(Color(1.0, 0.12, 0.08), minf(k * 2.0, 1.0))
			DrawBatch.circle(self, p, e[4] * 2.2 * (1.0 - k), Color(1.0, 0.1, 0.05, 0.18 * (1.0 - k)))
			DrawBatch.circle(self, p, e[4] * (1.0 - k * 0.6), Color(c, 1.0 - k))
	if flame:   # FLAMETHROWER: כדור אש שגדל, מצהוב-לבן לכתום לאדום כהה ועשן
		var k := clampf(_age / maxf(_life0, 0.01), 0.0, 1.0)
		var r := 5.0 + 21.0 * k
		var a := 1.0 - k * k
		# (עבר "weapons": במקום עיגולים קשים - הילה רכה + לשון אש שעולה למעלה בעולם, ובסוף עשן רך)
		DrawBatch.set_transform(self, Vector2.ZERO, -rotation, Vector2.ONE)   # הלשון עולה למעלה גם כשיורים באלכסון
		var ph := float(get_instance_id() % 97)
		FlameFx.glow(self, Vector2.ZERO, Vector2(r * 1.9, r * 1.5), Color(1.0, 0.38, 0.06, 0.26 * a))
		if k < 0.75:
			var tk := 1.0 - k / 0.75
			FlameFx.tongue(self, Vector2(0.0, r * 0.45), r * 0.95, r * (1.5 + 0.7 * FlameFx.wobble(_age, ph)), sin(_age * 9.0 + ph) * r * 0.35, FlameFx.PALETTE, 0.95 * tk, k < 0.35)
		else:   # עשן חם שמתפזר
			FlameFx.glow(self, Vector2(0.0, -r * 0.3), Vector2(r, r), Color(0.22, 0.18, 0.17, 0.5 * a))
		if k < 0.3:   # ליבה לבנה-חמה ליד הלוע
			FlameFx.glow(self, Vector2.ZERO, Vector2(r * 0.8, r * 0.8), Color(1.0, 0.95, 0.7, 0.8 * (1.0 - k / 0.3)))
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if arrow:   # חץ: מוט עץ, ראש מתכת ונוצות
		DrawBatch.line(self, Vector2(-22.0, 0.0), Vector2(4.0, 0.0), Color("8a6a40"), 1.6, true)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(4, -2.5), Vector2(10, 0), Vector2(4, 2.5)]), Color("b8b8c0"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-22, 0), Vector2(-17, -3.5), Vector2(-14, -3.5), Vector2(-18, 0)]), Color("d04030"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-22, 0), Vector2(-17, 3.5), Vector2(-14, 3.5), Vector2(-18, 0)]), Color("d04030"))
		return
	# שובל נותב (tracer): פס אור דק מאחורי הקליע, באורך מה שהוא עובר בפריים - רואים לאן יורים
	var tl := minf(clampf(velocity.length() * TRACER_K, 24.0, 80.0), _dist)
	if tl > 4.0 and not flame:
		var tc := Color(1.0, 0.86, 0.55)
		if pierce > 0 or sniper:
			tc = Color(0.6, 0.85, 1.0)
		elif god:
			tc = Color(1.0, 0.3, 0.2)
		elif incendiary:
			tc = Color(1.0, 0.6, 0.2)
		DrawBatch.polyline_colors(self, PackedVector2Array([Vector2(-tl, 0.0), Vector2(-tl * 0.45, 0.0), Vector2.ZERO]),
			PackedColorArray([Color(tc, 0.0), Color(tc, 0.22), Color(tc, 0.6)]), 1.6)
	var look := BulletCam.bullet_look(self)
	_cam_drawn = look > 0.0
	if _cam_drawn:
		_draw_wake(look)
	# הציור בלבד קטן יותר (VIS_SCALE) - ההתנגשות נשארת באותו גודל (קל לפגוע)
	var vs := lerpf(VIS_SCALE, CAM_VIS, look)
	DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(vs, vs))
	# שובל אוויר דק ושקוף (כדי שיהיה אפשר לראות את הקליע זז)
	DrawBatch.line(self, Vector2(-34.0, 0.0), Vector2(-6.0, 0.0), Color(0.9, 0.9, 0.95, 0.12), 2.0, true)
	DrawBatch.line(self, Vector2(-18.0, 0.0), Vector2(-6.0, 0.0), Color(0.9, 0.9, 0.95, 0.22), 1.2, true)
	# הקליע: גוף נחושת עם חוד מעוגל
	var body := PackedVector2Array([
		Vector2(-6.0, -1.6), Vector2(1.0, -1.6), Vector2(3.5, -1.2), Vector2(5.2, -0.5), Vector2(5.6, 0.0),
		Vector2(5.2, 0.5), Vector2(3.5, 1.2), Vector2(1.0, 1.6), Vector2(-6.0, 1.6),
	])
	var light := Color("e0a060")
	var dark := Color("8a4a20")
	if sniper:   # צלף: שובל ארוך ובהיר
		DrawBatch.line(self, Vector2(-90.0, 0.0), Vector2(-6.0, 0.0), Color(0.6, 0.85, 1.0, 0.35), 2.0, true)
	if pierce > 0:   # קליע חודר - כחול
		light = Color("90c8ff")
		dark = Color("2a5a9a")
		DrawBatch.line(self, Vector2(-40.0, 0.0), Vector2(-6.0, 0.0), Color(0.4, 0.7, 1.0, 0.35), 3.0, true)
	elif god:  # GOD MODE - אדום בוער
		light = Color("ff6a50")
		dark = Color("a00a0a")
		DrawBatch.line(self, Vector2(-44.0, 0.0), Vector2(-6.0, 0.0), Color(1.0, 0.15, 0.08, 0.5), 4.0, true)
		DrawBatch.circle(self, Vector2(1.0, 0.0), 7.0, Color(1.0, 0.2, 0.1, 0.35))
	elif incendiary:  # קליע אש - כתום
		light = Color("ffc060")
		dark = Color("c04010")
		DrawBatch.line(self, Vector2(-30.0, 0.0), Vector2(-6.0, 0.0), Color(1.0, 0.5, 0.1, 0.4), 3.0, true)
	DrawBatch.polygon(self, body, PackedColorArray([dark, light, light, light, light, dark, dark, dark, dark]))
	var closed := PackedVector2Array(body)
	closed.append(body[0])
	DrawBatch.polyline(self, closed, Color(0.15, 0.08, 0.04, 0.9), 0.8, true)
	DrawBatch.line(self, Vector2(-5.0, -0.7), Vector2(2.5, -0.7), Color(1.0, 0.9, 0.7, 0.7), 0.6, true)   # ברק של מתכת
	DrawBatch.line(self, Vector2(-6.0, -1.6), Vector2(-6.0, 1.6), Color(0.25, 0.15, 0.1), 1.0)              # בסיס
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)


# מצלמת קליע: הילה חלשה וגלי אוויר (אליפסות) שיוצאים מהחוד, גדלים ונשארים מאחור. k = 0..1 (נכנס עם הצילום)
func _draw_wake(k: float) -> void:
	DrawBatch.circle(self, Vector2(1.0, 0.0), 6.0, Color(1.0, 0.95, 0.85, 0.12 * k))
	var t: float = BulletCam.cam_time()
	for i in 6:
		var age := fmod(t, WAKE_EVERY) + float(i) * WAKE_EVERY
		if age > WAKE_LIFE:
			break
		var u := age / WAKE_LIFE
		var x := 3.0 - age * WAKE_SPEED
		var ry := 2.2 + 8.0 * u
		var rx := ry * 0.32
		var pts := PackedVector2Array()
		for j in 13:
			var a := TAU * float(j) / 12.0
			pts.append(Vector2(x + cos(a) * rx, sin(a) * ry))
		DrawBatch.polyline(self, pts, Color(0.85, 0.93, 1.0, 0.34 * k * (1.0 - u) * (1.0 - u)), 1.0, true)


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
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := t / duration
		for d in dirs:
			DrawBatch.circle(self, d * t, 2.2 * (1.0 - k), Color(1.0, 0.8, 0.3, 1.0 - k))


# ---- הבזק פגיעה בזומבי ----
class FleshHit extends Node2D:
	const DUR := 0.09
	const MAX_ALIVE := 14
	static var alive := 0
	var t := 0.0
	var dir := Vector2.RIGHT

	func _ready() -> void:
		z_index = 11
		alive += 1
		rotation = dir.angle()

	func _exit_tree() -> void:
		alive -= 1

	func _process(delta: float) -> void:
		t += delta
		if t >= DUR:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := t / DUR
		var a := 1.0 - k
		DrawBatch.circle(self, Vector2(6.0 + 10.0 * k, 0.0), 4.0 + 9.0 * k, Color(0.75, 0.05, 0.04, 0.4 * a))   # ענן דם (יוצא מהצד השני)
		for r in [[-2.6, 13.0], [2.6, 13.0], [PI, 9.0], [0.0, 16.0]]:   # קרניים: חזרה לכיוון היורה, לצדדים ולפנים
			var d := Vector2.from_angle(float(r[0]))
			DrawBatch.line(self, d * 2.0, d * float(r[1]) * (0.6 + 0.6 * k), Color(1.0, 0.92, 0.7, 0.9 * a), 1.6 * a + 0.4)
		DrawBatch.circle(self, Vector2.ZERO, 4.5 * (1.0 - k * 0.7), Color(1.0, 0.97, 0.85, a))


# ---- GOD MODE: פיצוץ קטן של חלקיקים אדומים בנקודת הפגיעה ----
class GodBurst extends Node2D:
	var t := 0.0
	const DUR := 0.5
	var parts := []   # [מהירות, גודל, חיים]

	func _ready() -> void:
		z_index = 11
		for i in 14:
			parts.append([Vector2.from_angle(randf() * TAU) * randf_range(50.0, 210.0), randf_range(1.4, 3.2), randf_range(0.25, DUR)])

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		if t >= DUR:
			queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := t / DUR
		DrawBatch.circle(self, Vector2.ZERO, 6.0 + 22.0 * k, Color(1.0, 0.15, 0.08, 0.35 * (1.0 - k)))   # הבזק
		DrawBatch.arc(self, Vector2.ZERO, 4.0 + 26.0 * k, 0.0, TAU, 20, Color(1.0, 0.45, 0.3, 0.6 * (1.0 - k)), 1.5, true)
		for pr in parts:
			var pk: float = t / float(pr[2])
			if pk >= 1.0:
				continue
			var v: Vector2 = pr[0]
			var pos := v * t * (1.0 - 0.45 * pk) + Vector2(0.0, 60.0 * t * t)
			var c := Color(1.0, 0.8, 0.45).lerp(Color(0.9, 0.08, 0.05), pk)
			DrawBatch.circle(self, pos, float(pr[1]) * (1.0 - pk * 0.7), Color(c, 1.0 - pk))
