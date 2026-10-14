extends Node2D
# ============================================================
#  פרטיקלים פשוטים: פיצוץ קטן של נקודות שעפות לצדדים ונעלמות.
#  Particles.burst(parent, pos, סוג, כיוון)  סוגים: "hit", "fire", "smoke"
# ============================================================

var _p := []        # [מיקום, מהירות, חיים, חיים מקסימליים, גודל, צבע, (כבידה, גדילה - בשכבה)]
var gravity := 600.0
var grow := 0.0      # עשן גדל עם הזמן
var is_layer := false   # ביצועים: שכבה אחת לכל ההתפרצויות של אותו הורה (במקום node לכל התפרצות)

const MAX_P := 1400     # תקרה: יותר מזה - חלקיקים חדשים לא נוספים (המון זומבים / פיצוצים)


# שכבת החלקיקים של ההורה (נוצרת פעם אחת)
static func _layer(parent: Node) -> Node:
	var l = parent.get_meta("_particle_layer") if parent.has_meta("_particle_layer") else null
	if l == null or not is_instance_valid(l) or l.is_queued_for_deletion():
		l = load("res://particles.gd").new()
		l.is_layer = true
		l.z_index = 12
		parent.add_child(l)
		parent.set_meta("_particle_layer", l)
	return l


static func burst(parent: Node, pos: Vector2, kind: String, dir := Vector2.ZERO, n := 10) -> void:
	if parent == null:
		return
	var b = _layer(parent)
	if b._p.size() >= MAX_P:
		return
	var off: Vector2 = b.to_local(pos)
	var grav := 600.0
	var grw := 0.0
	var start: int = b._p.size()
	for i in n:
		var a := randf() * TAU if dir == Vector2.ZERO else dir.angle() + randf_range(-1.3, 1.3)
		match kind:
			"hit":     # דם ושברים שעפים לצדדים
				var c := Color("8a0d0d").lerp(Color("2a0505"), randf()) if randf() < 0.8 else Color("1a1a1a")
				b._p.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(120, 320) + Vector2(0, -80), 0.0, randf_range(0.3, 0.6), randf_range(1.2, 2.8), c])
			"fire":    # ניצוצות אש שעולים
				grav = -150.0
				var c := Color(1.0, randf_range(0.3, 0.85), 0.1)
				b._p.append([Vector2(randf_range(-6, 6), randf_range(-6, 6)), Vector2.from_angle(a) * randf_range(30, 140) + Vector2(0, -60), 0.0, randf_range(0.25, 0.55), randf_range(1.5, 3.5), c])
			"spark":   # ניצוצות חשמל כחולים-לבנים (שלב 10)
				grav = 260.0
				var c := Color(0.55, 0.8, 1.0).lerp(Color.WHITE, randf())
				b._p.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(90, 260), 0.0, randf_range(0.15, 0.35), randf_range(1.0, 2.2), c])
			"leaf":    # עלים ירוקים שנתלשים ונופלים (GHILLIE בשלב 20)
				grav = 120.0
				var c := Color("2f5a2c").lerp(Color("5a8a3a"), randf())
				b._p.append([Vector2(randf_range(-8, 8), randf_range(-8, 8)), Vector2.from_angle(a) * randf_range(30, 110) + Vector2(0, -50), 0.0, randf_range(0.5, 0.9), randf_range(1.8, 3.0), c])
			"smoke":   # עשן אפור שעולה וגדל
				grav = -60.0
				grw = 10.0
				var g := randf_range(0.18, 0.32)
				b._p.append([Vector2(randf_range(-6, 6), randf_range(-4, 4)), Vector2.from_angle(a) * randf_range(10, 40) + Vector2(0, -30), 0.0, randf_range(0.7, 1.3), randf_range(3.0, 5.0), Color(g, g, g)])
			"mist":    # רסס מים / ערפל לבן שעולה לאט (מפלים, שלב 28)
				grav = -25.0
				grw = 14.0
				var g := randf_range(0.82, 0.95)
				b._p.append([Vector2(randf_range(-10, 10), randf_range(-4, 4)), Vector2.from_angle(a) * randf_range(10, 50) + Vector2(0, -20), 0.0, randf_range(0.9, 1.6), randf_range(3.0, 6.0), Color(g, g, g + 0.04)])
			"snow":    # (שלב 35) אבקת שלג / רסיסי קרח לבנים שמתפזרים ונופלים לאט
				grav = 160.0
				var g := randf_range(0.88, 1.0)
				b._p.append([Vector2(randf_range(-8, 8), randf_range(-4, 4)), Vector2.from_angle(a) * randf_range(30, 130), 0.0, randf_range(0.4, 0.9), randf_range(1.5, 3.2), Color(g, g, 1.0)])
			"drop":    # טיפות מים שניתזות
				grav = 520.0
				var c := Color(0.75, 0.88, 1.0).lerp(Color.WHITE, randf() * 0.5)
				b._p.append([Vector2(randf_range(-6, 6), 0.0), Vector2.from_angle(a) * randf_range(60, 170), 0.0, randf_range(0.25, 0.5), randf_range(1.0, 1.8), c])

	for j in range(start, b._p.size()):   # למיקום בשכבה + כבידה / גדילה לכל חלקיק
		var q: Array = b._p[j]
		q[0] += off
		q.append(grav)
		q.append(grw)
	b.set_process(true)


func _process(delta: float) -> void:
	var alive := 0
	var layer := is_layer
	for q in _p:
		q[2] += delta
		if q[2] < q[3]:
			alive += 1
			q[1].y += (q[6] if layer else gravity) * delta
			q[1] *= 1.0 - 1.5 * delta
			q[0] += q[1] * delta
	if alive == 0:
		if not layer:
			queue_free()
			return
		_p.clear()   # שכבה: נשארת, רק מפסיקה לעבוד עד ההתפרצות הבאה
		queue_redraw()
		set_process(false)
		return
	if layer and alive < _p.size() and (alive * 2 < _p.size() or _p.size() > 300):   # מנקים מתים
		var keep := []
		for q in _p:
			if q[2] < q[3]:
				keep.append(q)
		_p = keep
	queue_redraw()


func _draw() -> void:
	var vis := Rect2()
	if is_layer:   # רק מה שעל המסך
		var vp := get_viewport()
		vis = (get_global_transform().affine_inverse() * vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()).grow(40.0)
	for q in _p:
		var k: float = q[2] / q[3]
		if k >= 1.0:
			continue
		if is_layer and not vis.has_point(q[0]):
			continue
		var c: Color = q[5]
		var a := 1.0 - k
		var gr: float = q[7] if is_layer else grow
		if gr > 0.0:
			a *= 0.5
		draw_circle(q[0], q[4] + gr * k, Color(c, a))
