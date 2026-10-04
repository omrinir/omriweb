extends RefCounted
# ============================================================
#  AMBIENT - אפקטי סביבה מונפשים לשימוש חוזר (שלבים 5-9)
#
#  על המסך (מוסיפים ל-CanvasLayer):
#    Ambient.screen_particles("ash" / "embers" / "dust" / "spores", vp)  -> CPUParticles2D
#  בעולם (מוסיפים לשלב עם position):
#    SteamVent    - אדים שיוצאים מצינור/פתח (hazard אופציונלי)
#    SparkEmitter - ניצוצות מכבל / מכונה (חשמל)
#    Drip         - טיפות מים מהתקרה + שלולית
#    FlickerLight - אור מהבהב (נורה / מסך)
#    FallingDebris- חתיכות בטון נופלות מלמעלה מדי פעם (קישוט, לא פוגע)
#    Screen       - מסך מחשב מהבהב עם קווים (מעבדה)
# ============================================================

const Art := preload("res://art.gd")
const Particles := preload("res://particles.gd")
const Sfx := preload("res://sfx.gd")


static func screen_particles(kind: String, vp: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.position = Vector2(vp.x * 0.5, -10.0)
	p.emission_rect_extents = Vector2(vp.x * 0.6, 4.0)
	p.local_coords = false
	match kind:
		"ash":   # אפר אפור נופל לאט
			p.amount = 70
			p.lifetime = 9.0
			p.direction = Vector2(-0.3, 1.0)
			p.spread = 25.0
			p.gravity = Vector2(0, 8)
			p.initial_velocity_min = 20.0
			p.initial_velocity_max = 45.0
			p.scale_amount_min = 1.0
			p.scale_amount_max = 2.5
			p.color = Color(0.7, 0.68, 0.66, 0.55)
		"embers":   # גצים כתומים עולים מלמטה
			p.amount = 40
			p.lifetime = 6.0
			p.position = Vector2(vp.x * 0.5, vp.y + 10.0)
			p.direction = Vector2(0.2, -1.0)
			p.spread = 30.0
			p.gravity = Vector2(0, -6)
			p.initial_velocity_min = 25.0
			p.initial_velocity_max = 60.0
			p.scale_amount_min = 1.0
			p.scale_amount_max = 2.2
			p.color = Color(1.0, 0.55, 0.15, 0.85)
		"spores":   # רעלים ירקרקים (מעבדה / אזור נגוע)
			p.amount = 45
			p.lifetime = 10.0
			p.position = Vector2(vp.x * 0.5, vp.y * 0.5)
			p.emission_rect_extents = Vector2(vp.x * 0.6, vp.y * 0.5)
			p.direction = Vector2(0.1, -1.0)
			p.spread = 180.0
			p.gravity = Vector2(0, -2)
			p.initial_velocity_min = 3.0
			p.initial_velocity_max = 12.0
			p.scale_amount_min = 1.0
			p.scale_amount_max = 3.0
			p.color = Color(0.55, 1.0, 0.45, 0.35)
		_:   # dust: חלקיקי אבק מרחפים
			p.amount = 50
			p.lifetime = 10.0
			p.position = Vector2(vp.x * 0.5, vp.y * 0.5)
			p.emission_rect_extents = Vector2(vp.x * 0.6, vp.y * 0.5)
			p.direction = Vector2(1, 0)
			p.spread = 180.0
			p.gravity = Vector2.ZERO
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 10.0
			p.scale_amount_min = 1.0
			p.scale_amount_max = 2.0
			p.color = Color(0.9, 0.9, 0.85, 0.25)
	p.preprocess = p.lifetime
	return p


# ---- אדים מפתח בריצפה / צינור. hazard=true -> שורף (פרץ כל כמה שניות) ----
class SteamVent extends Node2D:
	var dir := Vector2.UP
	var hazard := false
	var period := 4.0
	var _t := 0.0
	var _puffs := []
	var _haz: Node = null

	func _ready() -> void:
		_t = randf() * period
		z_index = 5
		if hazard:
			_haz = load("res://environment/hazard.gd").new()
			_haz.rect = Rect2(-14, -70, 28, 70) if dir == Vector2.UP else Rect2(-70 if dir.x < 0 else 0, -14, 70, 28)
			_haz.active = false
			_haz.tick = 0.4
			_haz.zombie_damage = 4
			_haz.triggerable = true
			add_child(_haz)

	func burst() -> void:
		_t = 0.0

	func _process(delta: float) -> void:
		_t += delta
		var blasting := hazard and fmod(_t, period) < 1.1
		if _haz != null:
			_haz.active = blasting
		var n := 3 if blasting else 1
		if randf() < (0.9 if blasting else 0.25):
			for i in n:
				_puffs.append([Vector2(randf_range(-3, 3), 0), dir.rotated(randf_range(-0.25, 0.25)) * randf_range(60, 140) * (1.8 if blasting else 0.6), 0.0, randf_range(0.6, 1.3)])
		for pf in _puffs:
			pf[2] += delta
			pf[0] += pf[1] * delta
			pf[1] *= 0.97
		_puffs = _puffs.filter(func(q): return q[2] < q[3])
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		for pf in _puffs:
			var k: float = pf[2] / pf[3]
			draw_circle(pf[0], 4.0 + k * 16.0, Color(0.85, 0.88, 0.9, 0.3 * (1.0 - k)))


# ---- ניצוצות חשמל מכבל קרוע / מכונה ----
class SparkEmitter extends Node2D:
	var period := 2.5
	var color := Color(1.0, 0.85, 0.4)
	var _t := 0.0
	var _arc := 0.0

	func _ready() -> void:
		_t = randf() * period
		z_index = 6

	func _process(delta: float) -> void:
		_t -= delta
		_arc -= delta
		if _t <= 0.0:
			_t = period * randf_range(0.6, 1.4)
			_arc = 0.15
			if Art.on_screen(self, global_position):
				Particles.burst(get_parent(), global_position, "fire", Vector2.DOWN, 8)
				Sfx.play("zap", global_position, -14.0, 0.2, 2)
		if _arc > 0.0 or Engine.get_process_frames() % 20 == 0:
			queue_redraw()

	func _draw() -> void:
		if _arc <= 0.0:
			return
		var pts := PackedVector2Array([Vector2.ZERO])
		var p := Vector2.ZERO
		for i in 5:
			p += Vector2(randf_range(-6, 6), randf_range(3, 8))
			pts.append(p)
		draw_polyline(pts, Color(0.7, 0.85, 1.0, 0.9), 1.5)
		Art.glow(self, Vector2.ZERO, 14.0, Color(color, 0.6))


# ---- טיפות מים מהתקרה ----
class Drip extends Node2D:
	var fall := 200.0         # כמה פיקסלים עד הריצפה
	var period := 1.8
	var _drops := []
	var _splash := []
	var _t := 0.0

	func _ready() -> void:
		_t = randf() * period
		z_index = 2

	func _process(delta: float) -> void:
		_t -= delta
		if _t <= 0.0:
			_t = period * randf_range(0.7, 1.3)
			_drops.append([0.0, 0.0])
		for d in _drops:
			d[1] += 900.0 * delta
			d[0] += d[1] * delta
		for d in _drops:
			if d[0] >= fall:
				_splash.append([0.0])
		_drops = _drops.filter(func(d): return d[0] < fall)
		for s in _splash:
			s[0] += delta
		_splash = _splash.filter(func(s): return s[0] < 0.4)
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		Art.oval(self, Vector2(0, fall + 1.0), 14.0, 2.0, Color(0.4, 0.5, 0.6, 0.35), 0.0, Art.NONE)   # שלולית
		for d in _drops:
			draw_line(Vector2(0, d[0] - 5.0), Vector2(0, d[0]), Color(0.7, 0.8, 0.95, 0.8), 1.5)
		for s in _splash:
			var k: float = s[0] / 0.4
			draw_arc(Vector2(0, fall), 3.0 + k * 9.0, PI, TAU, 10, Color(0.75, 0.85, 1.0, 0.6 * (1.0 - k)), 1.0)


# ---- אור מהבהב (נורת פלורסנט / נורה אדומה של חירום) ----
class FlickerLight extends Node2D:
	var color := Color(0.85, 0.95, 1.0)
	var radius := 90.0
	var mode := "flicker"     # flicker / pulse (אזעקה) / steady
	var tube := true          # מצייר גוף נורה
	var _t := 0.0
	var _on := 1.0

	func _ready() -> void:
		_t = randf() * 10.0
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		match mode:
			"pulse":
				_on = 0.35 + 0.65 * absf(sin(_t * 3.0))
			"steady":
				_on = 1.0
			_:
				_on = 0.0 if fmod(_t * 5.3, 7.0) < 0.6 or (fmod(_t, 11.0) < 1.2 and randf() < 0.5) else 1.0
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		if tube:
			draw_rect(Rect2(-14, -2, 28, 4), Color(0.3, 0.3, 0.32))
			draw_rect(Rect2(-12, 1, 24, 2), Color(color, 0.35 + 0.65 * _on))
		if _on > 0.05:
			draw_colored_polygon(PackedVector2Array([Vector2(-12, 2), Vector2(12, 2), Vector2(radius * 0.7, radius * 1.6), Vector2(-radius * 0.7, radius * 1.6)]), Color(color, 0.06 * _on))
			Art.glow(self, Vector2(0, 4), radius * 0.35, Color(color, 0.35 * _on))


# ---- חתיכות בטון נופלות מדי פעם ליד המצלמה (קישוט) ----
class FallingDebris extends Node2D:
	var period := 5.0
	var top_y := 0.0
	var floor_y := 630.0
	var _t := 2.0
	var _chunks := []

	func _ready() -> void:
		z_index = 7

	func _process(delta: float) -> void:
		_t -= delta
		var cam := get_viewport().get_camera_2d()
		if _t <= 0.0 and cam != null:
			_t = period * randf_range(0.6, 1.5)
			var x := cam.get_screen_center_position().x + randf_range(-500, 500)
			for i in randi_range(2, 5):
				_chunks.append([Vector2(x + randf_range(-20, 20), top_y + randf_range(-30, 0)), Vector2(randf_range(-40, 40), randf_range(0, 80)), randf_range(2.0, 5.0), randf() * TAU])
		for c in _chunks:
			c[1].y += 900.0 * delta
			c[0] += c[1] * delta
			c[3] += delta * 6.0
			if c[0].y >= floor_y:
				Particles.burst(get_parent(), Vector2(c[0].x, floor_y), "smoke", Vector2.UP, 2)
		_chunks = _chunks.filter(func(c): return c[0].y < floor_y)
		queue_redraw()

	func _draw() -> void:
		for c in _chunks:
			var p: Vector2 = c[0]
			var s: float = c[2]
			draw_colored_polygon(Transform2D(c[3], p) * PackedVector2Array([Vector2(-s, -s * 0.6), Vector2(s, -s), Vector2(s * 0.7, s), Vector2(-s * 0.8, s * 0.7)]), Color("5a5650"))


# ---- מסך מחשב מהבהב (מעבדה / חדר בקרה) ----
class Screen extends Node2D:
	var size := Vector2(34, 24)
	var color := Color(0.3, 0.9, 0.8)
	var _t := 0.0

	func _ready() -> void:
		_t = randf() * 10.0
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position) and Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), Color(0.12, 0.12, 0.14))
		var on := 0.25 if fmod(_t * 3.1, 9.0) < 0.3 else 1.0
		draw_rect(Rect2(Vector2.ZERO, size), Color(color.r * 0.15, color.g * 0.2, color.b * 0.2))
		for i in int(size.y / 4.0):
			var w := size.x * (0.3 + 0.6 * absf(sin(_t * 0.7 + float(i) * 1.9)))
			draw_rect(Rect2(3, 2 + i * 4, w - 6, 1.5), Color(color, 0.6 * on))
		draw_rect(Rect2(0, fmod(_t * 20.0, size.y), size.x, 2), Color(color, 0.25 * on))   # קו סריקה
		Art.glow(self, size * 0.5, size.x * 0.8, Color(color, 0.12 * on))
