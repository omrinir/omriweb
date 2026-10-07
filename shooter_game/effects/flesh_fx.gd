extends RefCounted
# ============================================================
#  FLESH FX - חתיכות שנתלשות מהזומבי כשהוא נפגע (zombie.gd -> take_damage).
#  בנוסף לכל מה שכבר קורה בפגיעה (דם, פצעים, מספרי נזק):
#    * ריסוס דק: טיפות אדומות ואבק בשר אפור שעפים מצד היציאה של הקליע.
#    * חתיכות בשר (Chunk): מצולעים קטנים לא סדירים, אפורים עם שוליים אדומים - מסתובבים, נופלים,
#      קופצים על הרצפה, משאירים כתם אדום קטן ודוהים.
#    * פגיעה בראש: גם רסיסי עצם לבנבנים. הריגה / פיצוץ: יותר חתיכות.
#  ביצועים: רק על המסך, ולא יותר מ-MAX_CHUNKS חתיכות בבת אחת (כשיש המון זומבים).
#  לשנות: CHUNKS, SPRAY, MAX_CHUNKS, הצבעים למטה.
# ============================================================

const Art := preload("res://art.gd")

const CHUNKS := Vector2i(2, 4)       # כמה חתיכות (קטנות) בפגיעה רגילה
const SPRAY := 24                    # כמה טיפות דם בריסוס (חלקיקים - זול)
const MAX_CHUNKS := 70
const RED := [Color(0.55, 0.03, 0.04), Color(0.75, 0.06, 0.05), Color(0.4, 0.01, 0.03), Color(0.62, 0.02, 0.02)]
const BONE := Color(0.86, 0.84, 0.76)

static var _soft: Texture2D = null


# lite = מולטי-קיל (הרבה הריגות בשנייה): ריסוס אחד וחתיכה אחת בלבד
static func burst(parent: Node, pos: Vector2, dir: Vector2, skin: Color, zone: String, kill: bool, explosive: bool, lite := false) -> void:
	if parent == null or not Art.on_screen(parent, pos):
		return
	var d := dir.normalized() if dir != Vector2.ZERO else Vector2.UP
	var grey := skin.lerp(Color(0.42, 0.41, 0.4), 0.6).darkened(0.3)   # בשר זומבי אפור
	_spray(parent, pos, d, grey, kill, lite)
	var n := 1 if lite else randi_range(CHUNKS.x, CHUNKS.y) + (3 if kill else 0) + (4 if explosive else 0) + (1 if zone == "head" else 0)
	for i in n:
		if Chunk.alive >= MAX_CHUNKS:
			break
		var c := Chunk.new()
		var bone := zone == "head" and i % 2 == 0
		c.base = BONE if bone else (grey if i % 2 == 0 else RED[randi() % RED.size()])   # חצי אפור, חצי אדום
		c.edge = c.base.darkened(0.5) if not c.base in RED else RED[2].darkened(0.3)
		c.cut = RED[randi() % RED.size()]
		c.radius = randf_range(1.3, 2.5) * (1.25 if kill or explosive else 1.0)   # חתיכות קטנות
		var spread := 1.6 if explosive else 0.9
		var sp := randf_range(140.0, 330.0) * (1.6 if explosive else 1.0)
		c.velocity = Vector2.from_angle(d.angle() + randf_range(-spread, spread)) * sp + Vector2(0.0, -randf_range(90.0, 220.0))
		parent.add_child(c)
		c.global_position = pos + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))


# ריסוס חד-פעמי: טיפות אדומות + אבק אפור (CPUParticles2D)
static func _spray(parent: Node, pos: Vector2, d: Vector2, grey: Color, kill := false, lite := false) -> void:
	# שכבה 0: טיפות דם קטנות (הרבה), 1: ערפל דם אדום כהה, 2: אבק בשר אפור
	for layer in (1 if lite else 3):
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.explosiveness = 0.9
		p.amount = [int(SPRAY * (1.5 if kill else 1.0)), 8, 6][layer]
		p.lifetime = [0.55, 0.45, 0.7][layer]
		p.direction = d
		p.spread = [34.0, 25.0, 55.0][layer]
		p.gravity = Vector2(0.0, [950.0, 200.0, 300.0][layer])
		p.initial_velocity_min = [110.0, 30.0, 40.0][layer]
		p.initial_velocity_max = [360.0, 110.0, 130.0][layer]
		p.damping_min = 40.0
		p.damping_max = 120.0
		p.scale_amount_min = [0.8, 0.22, 0.1][layer]
		p.scale_amount_max = [2.0, 0.45, 0.22][layer]
		if layer > 0:   # ערפל / אבק רך
			p.texture = _soft_tex()
		var g := Gradient.new()
		var c0: Color = [RED[1], Color(RED[0], 0.55), Color(grey, 0.7)][layer]
		g.set_color(0, c0)
		g.set_color(1, Color(c0.darkened(0.3), 0.0))
		p.color_ramp = g
		p.z_index = 6
		parent.add_child(p)
		p.global_position = pos
		p.emitting = true
		p.finished.connect(p.queue_free)


static func _soft_tex() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 24
		t.height = 24
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_soft = t
	return _soft


# ---- חתיכת בשר: מצולע לא סדיר שמסתובב, נופל, קופץ ומשאיר כתם ----
class Chunk extends Node2D:
	const Art := preload("res://art.gd")
	static var alive := 0            # כמה חתיכות קיימות עכשיו
	var base := Color(0.5, 0.5, 0.5)
	var edge := Color(0.2, 0.2, 0.2)
	var cut := Color(0.6, 0.05, 0.05)     # חתך אדום בתוך החתיכה
	var radius := 2.4
	var velocity := Vector2.ZERO
	var life := 2.6
	var _spin := 0.0
	var _pts := PackedVector2Array()
	var _landed := false
	var _smear := Vector2.INF
	var _smear_r := 0.0

	func _ready() -> void:
		alive += 1
		z_index = 6
		_spin = randf_range(-14.0, 14.0)
		var n := randi_range(4, 6)
		for i in n:   # צורה לא סדירה
			var a := TAU * float(i) / float(n) + randf_range(-0.3, 0.3)
			_pts.append(Vector2.from_angle(a) * radius * randf_range(0.65, 1.15))
		life = randf_range(2.0, 3.0)

	func _exit_tree() -> void:
		alive -= 1

	func _physics_process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		if not _landed:
			velocity.y += 1100.0 * delta
			var to := global_position + velocity * delta
			var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
			if hit and hit.normal != Vector2.ZERO:
				global_position = hit.position + hit.normal * radius * 0.6
				if _smear == Vector2.INF:   # כתם דם במקום הנחיתה
					_smear = global_position + Vector2(0.0, radius * 0.6)
					_smear_r = radius * randf_range(1.4, 2.4)
				velocity = velocity.bounce(hit.normal) * 0.25
				velocity.x *= 0.6
				_spin *= 0.4
				if velocity.length() < 40.0:
					_landed = true
			else:
				global_position = to
			rotation += _spin * delta
		modulate.a = clampf(life / 0.6, 0.0, 1.0)   # דוהה בלי לצייר מחדש
		if not _landed and Art.on_screen(self, global_position):   # נחת = לא מצייר יותר (חוסך)
			queue_redraw()

	func _draw() -> void:
		var a := 1.0
		if _smear != Vector2.INF:
			var sl := to_local(_smear)
			draw_set_transform(sl, -rotation, Vector2.ONE)
			draw_colored_polygon(Art.ellipse(Vector2.ZERO, _smear_r, _smear_r * 0.3, 0.0, 10), Color(0.4, 0.02, 0.03, 0.55 * a))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_colored_polygon(_pts, Color(base, a))
		var loop := _pts.duplicate()
		loop.append(_pts[0])
		draw_polyline(loop, Color(edge, a), 0.9, true)
		draw_line(_pts[0] * 0.55, _pts[2] * 0.45, Color(cut, a), 1.3)   # חתך אדום בפנים
