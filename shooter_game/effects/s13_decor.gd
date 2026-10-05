extends RefCounted
# ============================================================
#  שלב 13 (צפון-מזרח, "DUNES OF BONE") - רקע וקישוטים.
#  השראה: לנסואיס מרניינסס - ים של דיונות לבנות עם לגונות מי-גשם בצבע טורקיז,
#  ושלדים: לווייתן ענק שנקבר בחול, גולגולות של שוורים מהסרטאו, עצים מתים מולבנים.
#  שעה: צהריים לבנים ולוהטים, שמיים חיוורים, מיראז' באופק, נשרים חגים.
#  * static draw: רקע (דיונות רחוקות + לגונות, שלד לווייתן, גולגולות, עצים מתים).
#  * BoneField: קישוט עולם מאחורי הכביש (עצמות, צלעות, גולגולות שור על מקלות, יתדות).
# ============================================================

const Art := preload("res://art.gd")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func dune_band(ci: CanvasItem, sc: float, v: Vector2, base_y: float, amp: float, c: Color, lagoon: Color, seed_v: int) -> void:
	var pts := PackedVector2Array([Vector2(-10, v.y)])
	var ys := []
	for i in 41:
		var x := float(i) * (v.x + 20.0) / 40.0 - 10.0
		var wx := x + sc
		var y := base_y - amp * (0.5 + 0.5 * sin(wx * 0.006 + float(seed_v))) - amp * 0.35 * sin(wx * 0.017 + float(seed_v) * 2.0)
		pts.append(Vector2(x, y))
		ys.append(y)
	pts.append(Vector2(v.x + 10, v.y))
	ci.draw_colored_polygon(pts, c)
	if lagoon.a <= 0.0:
		return
	for i in range(1, 40):   # לגונות טורקיז רק בתחתית העמקים (מינימום מקומי)
		if float(ys[i]) >= float(ys[i - 1]) and float(ys[i]) >= float(ys[i + 1]) and float(ys[i]) > base_y - amp * 0.3:
			var lp: Vector2 = pts[i + 1]
			Art.oval(ci, lp + Vector2(0, 3), 22.0, 3.5, lagoon, 0.0, Art.NONE)


static func whale(ci: CanvasItem, p: Vector2, s: float, c: Color) -> void:
	for i in 14:   # עמוד שדרה + צלעות
		var x := float(i) * 18.0 * s
		var y := -sin(float(i) / 13.0 * PI) * 16.0 * s
		ci.draw_circle(p + Vector2(x, y), 3.5 * s, c)
		if i > 2 and i < 12:
			var rl := (30.0 + 18.0 * sin(float(i) / 13.0 * PI)) * s
			ci.draw_arc(p + Vector2(x, y + rl * 0.95), rl, -PI * 0.5 - 0.9, -PI * 0.5 + 0.2, 10, c, 2.2 * s)
	# גולגולת / לסת
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 0) * s, p + Vector2(-80, 10) * s, p + Vector2(-90, 22) * s, p + Vector2(-8, 14) * s]), c)
	ci.draw_line(p + Vector2(-12, 22) * s, p + Vector2(-96, 40) * s, c, 3.0 * s)


static func ox_skull(ci: CanvasItem, p: Vector2, s: float, c: Color, dark: Color) -> void:
	Art.oval(ci, p, 7.0 * s, 9.0 * s, c, 0.0, Art.NONE)
	ci.draw_circle(p + Vector2(-3, -2) * s, 2.0 * s, dark)
	ci.draw_circle(p + Vector2(3, -2) * s, 2.0 * s, dark)
	ci.draw_arc(p + Vector2(-13, -8) * s, 9.0 * s, 0.1, 1.7, 8, c, 2.4 * s)
	ci.draw_arc(p + Vector2(13, -8) * s, 9.0 * s, PI - 1.7, PI - 0.1, 8, c, 2.4 * s)


static func dead_tree(ci: CanvasItem, base: Vector2, h: float, c: Color, seed_v: int) -> void:
	var r := _rng(seed_v)
	ci.draw_line(base, base + Vector2(0, -h), c, 4.0)
	for i in 4:
		var y := -h * (0.45 + 0.13 * float(i))
		var s := 1.0 if i % 2 == 0 else -1.0
		var e := base + Vector2(s * r.randf_range(14.0, 26.0), y - r.randf_range(10.0, 20.0))
		ci.draw_line(base + Vector2(0, y), e, c, 2.0)
		ci.draw_line(e, e + Vector2(s * 6.0, -6.0), c, 1.2)


# ============================================================
#  קישוט עולם: שדה עצמות מאחורי הכביש
# ============================================================
class BoneField extends Node2D:
	var seed_v := 0

	func _ready() -> void:
		z_index = -3

	func _draw() -> void:
		var r := S13._rng(seed_v)
		var bone := Color("ece4d0")
		var x := 0.0
		while x < 1024.0:
			var pick := r.randf()
			if pick < 0.3:   # כלוב צלעות גדול חצי קבור
				var w := r.randf_range(60.0, 100.0)
				for i in 6:
					var px := x + float(i) * w / 5.0
					draw_arc(Vector2(px, 4.0), r.randf_range(26.0, 40.0), PI + 0.4, TAU - 0.8, 10, bone, 3.0)
				draw_line(Vector2(x - 6, -2), Vector2(x + w + 8, -6), bone, 4.0)
				x += w + 40.0
			elif pick < 0.55:   # גולגולת שור על מקל (סימן אזהרה)
				draw_line(Vector2(x + 10, 0), Vector2(x + 12, -60), Color("5a4430"), 3.0)
				S13.ox_skull(self, Vector2(x + 12, -66), 1.2, bone, Color("2a2018"))
				x += 60.0
			elif pick < 0.75:   # עץ מת מולבן
				S13.dead_tree(self, Vector2(x + 20, 0), r.randf_range(70.0, 110.0), Color("d8d0bc"), r.randi())
				x += 70.0
			else:   # עצמות פזורות
				for i in 5:
					var bx := x + r.randf_range(0.0, 70.0)
					var a := r.randf_range(-0.4, 0.4)
					var d := Vector2.from_angle(a) * r.randf_range(6.0, 12.0)
					draw_line(Vector2(bx, -2) - d, Vector2(bx, -2) + d, bone, 2.6)
					draw_circle(Vector2(bx, -2) - d, 2.2, bone)
					draw_circle(Vector2(bx, -2) + d, 2.2, bone)
				x += 90.0
			x += r.randf_range(20.0, 80.0)

	const S13 := preload("res://effects/s13_decor.gd")


# ============================================================
#  מכשולים על הכביש (מוצקים): "ribcage" - כלוב צלעות ענק חצי קבור, "rock" - סלע אבן-חול
# ============================================================
class Obstacle extends Node2D:
	var kind := "ribcage"
	var size := Vector2(90, 32)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)

	func _draw() -> void:
		var r := S13._rng(seed_v)
		if kind == "rock":
			var pts := PackedVector2Array()
			for i in 9:
				var u := float(i) / 8.0
				pts.append(Vector2(u * size.x, -size.y * (0.55 + 0.45 * sin(u * PI)) * r.randf_range(0.85, 1.0)))
			pts.append(Vector2(size.x, 0))
			pts.append(Vector2(0, 0))
			Art.fill_shaded(self, pts, Color("b8865a"), 0.2, 0.35)
			for k in 3:
				draw_line(Vector2(size.x * 0.15, -size.y * (0.3 + 0.2 * float(k))), Vector2(size.x * 0.85, -size.y * (0.32 + 0.2 * float(k))), Color(0.5, 0.32, 0.2, 0.5), 1.0)
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(size.x * 0.5, -10), Vector2(size.x + 6, 0)]), Color("d8c49c"))   # חול
			for i in 6:
				var px := 8.0 + float(i) * (size.x - 16.0) / 5.0
				draw_arc(Vector2(px, 0.0), size.y, PI + 0.35, TAU - 0.35, 12, Art.OUTLINE, 6.0)
				draw_arc(Vector2(px, 0.0), size.y, PI + 0.35, TAU - 0.35, 12, Color("ece4d0"), 3.6)
			draw_line(Vector2(0, -size.y + 2), Vector2(size.x, -size.y + 4), Art.OUTLINE, 7.0)
			draw_line(Vector2(0, -size.y + 2), Vector2(size.x, -size.y + 4), Color("ece4d0"), 4.6)   # עמוד שדרה

	const S13 := preload("res://effects/s13_decor.gd")
