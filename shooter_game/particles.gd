extends Node2D
# ============================================================
#  פרטיקלים פשוטים: פיצוץ קטן של נקודות שעפות לצדדים ונעלמות.
#  Particles.burst(parent, pos, סוג, כיוון)  סוגים: "hit", "fire", "smoke"
# ============================================================

var _p := []        # [מיקום, מהירות, חיים, חיים מקסימליים, גודל, צבע]
var gravity := 600.0
var grow := 0.0      # עשן גדל עם הזמן


static func burst(parent: Node, pos: Vector2, kind: String, dir := Vector2.ZERO, n := 10) -> void:
	var b = load("res://particles.gd").new()
	parent.add_child(b)
	b.global_position = pos
	b.z_index = 12
	for i in n:
		var a := randf() * TAU if dir == Vector2.ZERO else dir.angle() + randf_range(-1.3, 1.3)
		match kind:
			"hit":     # דם ושברים שעפים לצדדים
				var c := Color("8a0d0d").lerp(Color("2a0505"), randf()) if randf() < 0.8 else Color("1a1a1a")
				b._p.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(120, 320) + Vector2(0, -80), 0.0, randf_range(0.3, 0.6), randf_range(1.2, 2.8), c])
			"fire":    # ניצוצות אש שעולים
				b.gravity = -150.0
				var c := Color(1.0, randf_range(0.3, 0.85), 0.1)
				b._p.append([Vector2(randf_range(-6, 6), randf_range(-6, 6)), Vector2.from_angle(a) * randf_range(30, 140) + Vector2(0, -60), 0.0, randf_range(0.25, 0.55), randf_range(1.5, 3.5), c])
			"spark":   # ניצוצות חשמל כחולים-לבנים (שלב 10)
				b.gravity = 260.0
				var c := Color(0.55, 0.8, 1.0).lerp(Color.WHITE, randf())
				b._p.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(90, 260), 0.0, randf_range(0.15, 0.35), randf_range(1.0, 2.2), c])
			"leaf":    # עלים ירוקים שנתלשים ונופלים (GHILLIE בשלב 20)
				b.gravity = 120.0
				var c := Color("2f5a2c").lerp(Color("5a8a3a"), randf())
				b._p.append([Vector2(randf_range(-8, 8), randf_range(-8, 8)), Vector2.from_angle(a) * randf_range(30, 110) + Vector2(0, -50), 0.0, randf_range(0.5, 0.9), randf_range(1.8, 3.0), c])
			"smoke":   # עשן אפור שעולה וגדל
				b.gravity = -60.0
				b.grow = 10.0
				var g := randf_range(0.18, 0.32)
				b._p.append([Vector2(randf_range(-6, 6), randf_range(-4, 4)), Vector2.from_angle(a) * randf_range(10, 40) + Vector2(0, -30), 0.0, randf_range(0.7, 1.3), randf_range(3.0, 5.0), Color(g, g, g)])


func _process(delta: float) -> void:
	var alive := false
	for q in _p:
		q[2] += delta
		if q[2] < q[3]:
			alive = true
			q[1].y += gravity * delta
			q[1] *= 1.0 - 1.5 * delta
			q[0] += q[1] * delta
	if not alive:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	for q in _p:
		var k: float = q[2] / q[3]
		if k >= 1.0:
			continue
		var c: Color = q[5]
		var a := 1.0 - k
		if grow > 0.0:
			a *= 0.5
		draw_circle(q[0], q[4] + grow * k, Color(c, a))
