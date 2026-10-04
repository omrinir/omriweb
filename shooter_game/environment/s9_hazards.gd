extends RefCounted
# ============================================================
#  S9 HAZARDS - סכנות של שלב 9 ("THEY LEARN"):
#    InfectionZone - שלולית הדבקה / ענן רעיל זמני (נוצר ע"י INFECTOR, או קבוע במעבדה)
#    InfectGlob    - גוש הדבקה שה-INFECTOR זורק בקשת. נוחת -> InfectionZone
#    RubbleShot    - גוש בטון שה-EVOLVED זורק (נגד שחקן שאוהב שוטגאן)
#    CollapseZone  - תקרה / חזית הרוסה שמתמוטטת מדי פעם: אבק ורעד = אזהרה, ואז נופלים גושים
#  כולם יורשים מ-environment/hazard.gd (חוץ מהקליעים), כך שזומבים חכמים עוקפים אותם.
#  איך משנים: גודל / זמן חיים ב-setup(), נזק ב-player_damage, קצב ב-tick.
#  הוגנות: לכל אזור יש "חסד" של חצי שנייה לפני הפגיעה הראשונה (אפשר לברוח).
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")

const MAX_ZONES := 8     # תקרה כללית: לא יותר מ-8 אזורי הדבקה בבת אחת בכל השלב


# ---- שלולית הדבקה / ענן רעיל ----
class InfectionZone extends "res://environment/hazard.gd":
	var width := 70.0
	var cloud := false
	var owner_z: Node = null
	var _t := 0.0
	var _max := 6.0
	var _seed := 0.0

	func setup(w: float, seconds: float, is_cloud: bool) -> void:
		width = w
		cloud = is_cloud
		life = seconds
		_max = seconds
		rect = Rect2(-w * 0.5, -78.0, w, 80.0) if is_cloud else Rect2(-w * 0.5, -12.0, w, 14.0)
		player_damage = 1
		tick = 0.9 if is_cloud else 0.8
		_tick_t = 0.6   # חסד: חצי שנייה לפני הפגיעה הראשונה

	# יוצר אזור הדבקה (מחזיר null אם הגענו לתקרה הכללית)
	static func spawn(parent: Node, pos: Vector2, w: float, seconds: float, is_cloud: bool, by: Node = null) -> Node2D:
		if parent == null or parent.get_tree().get_nodes_in_group("s9_infection").size() >= MAX_ZONES:
			return null
		var zn := InfectionZone.new()
		zn.setup(w, seconds, is_cloud)
		zn.owner_z = by
		parent.add_child(zn)
		zn.global_position = pos
		return zn

	func _ready() -> void:
		super._ready()
		add_to_group("s9_infection")
		z_index = 8 if cloud else 2
		_seed = randf() * 10.0

	func _hazard_tick(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var fade := clampf(life / 1.0, 0.0, 1.0) if life > 0.0 else 1.0
		var grow := clampf(_t / 0.5, 0.0, 1.0)   # מתפשט בהתחלה (אזהרה)
		var a := fade * grow
		var g := Color(0.55, 1.0, 0.3)
		var pu := Color(0.62, 0.25, 0.75)
		if cloud:
			# ענן רעיל: כמה עיגולים שקופים שמסתחררים לאט
			for i in 9:
				var k := float(i) / 9.0
				var ang := _t * 0.6 + k * TAU + _seed
				var p := Vector2(cos(ang) * width * 0.32 * grow, -34.0 + sin(ang * 1.3) * 16.0 - k * 10.0)
				var r := (18.0 + 10.0 * sin(_t * 1.5 + float(i))) * (0.5 + 0.5 * grow)
				draw_circle(p, r, Color(pu.lerp(g, k), 0.16 * a))
			for i in 6:   # נבגים קטנים שעולים
				var q := fmod(_t * 0.4 + float(i) * 0.17, 1.0)
				draw_circle(Vector2((float(i) / 5.0 - 0.5) * width * 0.8, -q * 76.0), 1.6, Color(0.8, 1.0, 0.5, 0.6 * a * (1.0 - q)))
			return
		var pts := PackedVector2Array()
		for i in 18:
			var t := TAU * float(i) / 18.0
			pts.append(Vector2(cos(t) * width * 0.5 * grow * (1.0 + 0.1 * sin(t * 3.0 + _t * 2.0)), sin(t) * 4.0 + 1.0))
		draw_colored_polygon(pts, Color(pu, 0.6 * a))
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(p * Vector2(0.7, 0.6))
		draw_colored_polygon(inner, Color(g, 0.45 * a))
		for i in 5:   # בועות שמתפוצצות
			var k := fmod(_t * 1.1 + float(i) * 0.23, 1.0)
			var bx := (float(i) / 4.0 - 0.5) * width * 0.75
			draw_circle(Vector2(bx, -k * 12.0), 2.4 * (1.0 - k), Color(0.8, 1.0, 0.55, a * (1.0 - k)))
		draw_circle(Vector2(0, -8), width * 0.55, Color(g, 0.05 * a))   # זוהר
		for i in 3:   # אדים ירוקים מעל
			var k := fmod(_t * 0.5 + float(i) * 0.33, 1.0)
			draw_circle(Vector2((float(i) - 1.0) * width * 0.25, -6.0 - k * 26.0), 5.0 + k * 8.0, Color(g, 0.12 * a * (1.0 - k)))


# ---- גוש הדבקה שעף בקשת ----
class InfectGlob extends Node2D:
	var velocity := Vector2.ZERO
	var gravity := 900.0
	var cloud := false
	var owner_z: Node = null
	var _life := 3.0
	var _trail := []

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		velocity.y += gravity * delta
		var to := global_position + velocity * delta
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and (p.body_rect() as Rect2).has_point(to):   # פגיעה ישירה
			p.hurt(1, Vector2(signf(velocity.x), 0.0))
			_land(Vector2(to.x, p.global_position.y))
			return
		var q := PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			var n: Vector2 = hit.normal
			var col: Object = hit.collider
			if n.y < -0.5:
				_land(hit.position)
				return
			if not (col is Node and (col as Node).is_in_group("platforms")):   # קיר: מתפזר בלי שלולית
				Particles.burst(get_parent(), hit.position, "smoke", n, 4)
				queue_free()
				return
		_trail.push_front(global_position)
		if _trail.size() > 5:
			_trail.pop_back()
		global_position = to
		queue_redraw()

	func _land(at: Vector2) -> void:
		Sfx.play("infect_splat", at, -4.0, 0.15, 3)
		Particles.burst(get_parent(), at + Vector2(0, -4), "smoke", Vector2.UP, 5)
		InfectionZone.spawn(get_parent(), at, 120.0 if cloud else 84.0, 4.5 if cloud else 6.0, cloud, owner_z)
		queue_free()

	func _draw() -> void:
		for i in _trail.size():
			var tp: Vector2 = _trail[i] - global_position
			draw_circle(tp, 4.0 - float(i) * 0.6, Color(0.6, 1.0, 0.35, 0.35 - float(i) * 0.06))
		Art.glow(self, Vector2.ZERO, 10.0, Color(0.6, 1.0, 0.3, 0.5))
		draw_circle(Vector2.ZERO, 5.0, Color(0.55, 0.22, 0.65))
		draw_circle(Vector2(-1, -1), 2.6, Color(0.7, 1.0, 0.4))


# ---- גוש בטון שנזרק (EVOLVED) ----
class RubbleShot extends Node2D:
	var velocity := Vector2.ZERO
	var gravity := 1000.0
	var _life := 2.5
	var _rot := 0.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		velocity.y += gravity * delta
		_rot += delta * 9.0
		var to := global_position + velocity * delta
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and (p.body_rect() as Rect2).grow(4.0).has_point(to):
			p.hurt(1, Vector2(signf(velocity.x), 0.0))
			_break(to)
			return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))
		if not hit.is_empty():
			_break(hit.position)
			return
		global_position = to
		queue_redraw()

	func _break(at: Vector2) -> void:
		Sfx.play("evo_rock", at, -3.0, 0.2, 3)
		Particles.burst(get_parent(), at, "smoke", Vector2.UP, 4)
		queue_free()

	func _draw() -> void:
		var pts := Transform2D(_rot, Vector2.ZERO) * PackedVector2Array([Vector2(-6, -4), Vector2(3, -7), Vector2(7, 1), Vector2(2, 6), Vector2(-6, 4)])
		Art.fill(self, pts, Color("6a6560"), Art.OUTLINE, 1.2)
		draw_line(pts[0], pts[2], Color(0.3, 0.28, 0.26), 1.0)


# ---- תקרה / חזית שמתמוטטת ----
# שלבים: 0 שקט, 1 אזהרה (אבק נושר + חריקה + רעד), 2 נפילה, 3 הריסות על הריצפה
class CollapseZone extends "res://environment/hazard.gd":
	var width := 130.0
	var top := -250.0          # איפה התקרה התלויה (יחסית לריצפה)
	var period := 9.0
	var _t := 0.0
	var _state := 0
	var _st := 0.0
	var _chunks := []
	var _dust := []
	var _seed := 0
	var collapses := 0         # לבדיקות

	func setup(w: float, per: float, top_y := -250.0) -> void:
		width = w
		period = per
		top = top_y
		rect = Rect2(-w * 0.5, -64.0, w, 64.0)
		active = false
		player_damage = 1
		zombie_damage = 14
		tick = 0.2
		triggerable = true

	func _ready() -> void:
		super._ready()
		z_index = 4
		_t = randf() * period * 0.5
		_seed = randi()

	# אזהרה + נפילה: זומבים חכמים לא נכנסים מתחת
	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (_state == 1 or _state == 2) and world_rect().grow(margin).has_point(p)

	func trigger() -> void:
		if _state == 0:
			_start_warning()

	func _start_warning() -> void:
		_state = 1
		_st = 1.1
		Sfx.play("s9_creak", global_position + Vector2(0, top), -2.0, 0.15, 2)

	func _hazard_tick(delta: float) -> void:
		_t += delta
		_st -= delta
		var near := false
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead:
			var pd: Vector2 = p.global_position - global_position
			near = absf(pd.x) < width * 0.5 + 140.0 and absf(pd.y) < 120.0
		match _state:
			0:
				# השחקן מתחת / קרוב -> מתמוטט מהר יותר
				if _t >= period or (near and _t >= period * 0.45):
					_start_warning()
			1:
				if randf() < 0.5:
					_dust.append([Vector2(randf_range(-width * 0.5, width * 0.5), top + 10.0), 0.0])
				if _st <= 0.0:
					_state = 2
					_st = 0.55
					collapses += 1
					_chunks.clear()
					for i in 7:
						_chunks.append([Vector2(randf_range(-width * 0.45, width * 0.45), top + randf_range(0.0, 20.0)), randf_range(0.0, 90.0), randf_range(5.0, 11.0), randf() * TAU])
			2:
				for c in _chunks:
					c[1] += 1600.0 * delta
					c[0].y = minf(c[0].y + c[1] * delta, -4.0)
					c[3] += delta * 5.0
				# הגושים פוגעים כשהם קרובים לריצפה
				var hitting := _st < 0.32 and _st > 0.12
				if hitting and not active:
					_tick_t = 0.0
					Sfx.play("s9_crash", global_position, 2.0, 0.1, 2)
					Particles.burst(get_parent(), global_position + Vector2(0, -10), "smoke", Vector2.UP, 12)
					var cam := get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake") and near:
						cam.shake(9.0, 0.3)
				active = hitting
				if _st <= 0.0:
					active = false
					_state = 3
					_st = 1.6
			3:
				if _st <= 0.0:
					_state = 0
					_t = 0.0
		for d in _dust:
			d[1] += delta
			d[0].y += 160.0 * delta
		_dust = _dust.filter(func(d): return d[1] < 1.0)
		if Art.on_screen(self, global_position, 260.0):
			queue_redraw()

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = _seed
		var shake := Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0)) if _state == 1 else Vector2.ZERO
		# קורת פלדה שבורה + לוחות בטון תלויים (נראים גם כשהם "שקטים")
		var beam_y := top - 16.0
		draw_rect(Rect2(-width * 0.5 - 30.0, beam_y, width + 60.0, 10.0), Color("2e2a2a"))
		draw_line(Vector2(-width * 0.5 - 30.0, beam_y), Vector2(width * 0.5 + 30.0, beam_y), Color(0.6, 0.55, 0.5, 0.4), 1.0)
		if _state != 2 and _state != 3:
			for i in 4:
				var sx := -width * 0.5 + (float(i) + 0.15) * width / 4.0
				var sw := width / 4.0 - 4.0
				var sh := r.randf_range(14.0, 26.0)
				var tilt := r.randf_range(-0.12, 0.12)
				var slab := Transform2D(tilt, Vector2(sx + sw * 0.5, top + sh * 0.5) + shake) * PackedVector2Array([Vector2(-sw * 0.5, -sh * 0.5), Vector2(sw * 0.5, -sh * 0.5), Vector2(sw * 0.5, sh * 0.5), Vector2(-sw * 0.5, sh * 0.5)])
				Art.fill_shaded(self, slab, Color("6e6862"), 0.1, 0.35, Art.OUTLINE, 1.0)
				draw_line(Vector2(sx + 3.0, top - 6.0), Vector2(sx + 5.0, top + 2.0) + shake, Color("6a4030"), 1.2)   # ברזל זיון
		# אזהרה: פסי אבק נושרים + קווי סדק
		for d in _dust:
			draw_line(d[0], d[0] + Vector2(0, 7), Color(0.75, 0.7, 0.62, 0.5 * (1.0 - float(d[1]))), 1.5)
		if _state == 1:
			draw_rect(Rect2(-width * 0.5, -4.0, width, 4.0), Color(1.0, 0.3, 0.2, 0.25 + 0.2 * sin(_t * 30.0)))
		for c in _chunks:
			var s: float = c[2]
			var pts := Transform2D(c[3], c[0]) * PackedVector2Array([Vector2(-s, -s * 0.7), Vector2(s, -s), Vector2(s * 0.8, s), Vector2(-s * 0.9, s * 0.6)])
			Art.fill(self, pts, Color("5e5852"), Art.OUTLINE, 1.0)
		if _state == 3 or _state == 0:   # ערימת הריסות קבועה על הריצפה (קישוט)
			for i in 5:
				var bx := -width * 0.4 + float(i) * width * 0.2
				Art.oval(self, Vector2(bx, -3.0), 9.0 + float(i % 2) * 4.0, 4.0, Color("4e4a46"), 0.0, Art.OUTLINE, 1.0)
