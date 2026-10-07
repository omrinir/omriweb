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

const CHUNKS := Vector2i(2, 3)       # כמה חתיכות בפגיעה רגילה
const SPRAY := 14                    # כמה טיפות / אבק בריסוס
const MAX_CHUNKS := 70
const RED := [Color(0.55, 0.04, 0.04), Color(0.72, 0.08, 0.06), Color(0.42, 0.02, 0.03)]
const BONE := Color(0.86, 0.84, 0.76)

static var _soft: Texture2D = null


static func burst(parent: Node, pos: Vector2, dir: Vector2, skin: Color, zone: String, kill: bool, explosive: bool) -> void:
	if parent == null or not Art.on_screen(parent, pos):
		return
	var d := dir.normalized() if dir != Vector2.ZERO else Vector2.UP
	var grey := skin.lerp(Color(0.42, 0.41, 0.4), 0.6).darkened(0.3)   # בשר זומבי אפור
	_spray(parent, pos, d, grey)
	var n := randi_range(CHUNKS.x, CHUNKS.y) + (3 if kill else 0) + (4 if explosive else 0) + (1 if zone == "head" else 0)
	for i in n:
		if Chunk.alive >= MAX_CHUNKS:
			break
		var c := Chunk.new()
		var bone := zone == "head" and i % 2 == 0
		c.base = BONE if bone else (grey if i % 3 != 2 else RED[randi() % RED.size()])
		c.edge = c.base.darkened(0.5) if c.base != RED[0] and c.base != RED[1] and c.base != RED[2] else RED[2].darkened(0.3)
		c.cut = RED[randi() % RED.size()]
		c.radius = randf_range(2.2, 4.0) * (1.3 if kill or explosive else 1.0)
		var spread := 1.6 if explosive else 0.9
		var sp := randf_range(140.0, 330.0) * (1.6 if explosive else 1.0)
		c.velocity = Vector2.from_angle(d.angle() + randf_range(-spread, spread)) * sp + Vector2(0.0, -randf_range(90.0, 220.0))
		parent.add_child(c)
		c.global_position = pos + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))


# ריסוס חד-פעמי: טיפות אדומות + אבק אפור (CPUParticles2D)
static func _spray(parent: Node, pos: Vector2, d: Vector2, grey: Color) -> void:
	for layer in 2:
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.explosiveness = 0.9
		p.amount = SPRAY if layer == 0 else SPRAY / 2
		p.lifetime = 0.5 if layer == 0 else 0.7
		p.direction = d
		p.spread = 32.0 if layer == 0 else 50.0
		p.gravity = Vector2(0.0, 900.0 if layer == 0 else 300.0)
		p.initial_velocity_min = 120.0 if layer == 0 else 40.0
		p.initial_velocity_max = 320.0 if layer == 0 else 130.0
		p.damping_min = 40.0
		p.damping_max = 120.0
		p.scale_amount_min = 1.2 if layer == 0 else 0.12
		p.scale_amount_max = 2.6 if layer == 0 else 0.28
		if layer == 1:   # אבק בשר רך
			p.texture = _soft_tex()
		var g := Gradient.new()
		var c0: Color = RED[1] if layer == 0 else Color(grey, 0.75)
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
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var a := clampf(life / 0.6, 0.0, 1.0)
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
