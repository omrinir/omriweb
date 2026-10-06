extends RefCounted
# ============================================================
#  שלב 15 (צפון-מזרח, "CARNIVAL OF THE DEAD") - בוקר אחרי קרנבל שלא נגמר, באולינדה.
#  * רקע (static): שמי בוקר (תכלת -> זהב), שמש נמוכה עם קרניים, ים ומגדלי רסיפה באובך,
#    גבעת אולינדה עם בתים קולוניאליים בצבעי פסטל, כנסיות לבנות עם שני מגדלים, דקלים.
#  * ColonialRow - שורת "סוברדוס" (בתים קולוניאליים דו-קומתיים) מאחורי הרחוב: מרפסות ברזל,
#    תריסי עץ צבעוניים, מסכות קרנבל ומטריות פרבו על הקירות, קונפטי על הרצפה.
#  * GiantPuppet - בובות הענק של אולינדה (בונקוס): גוף בד צבעוני וראש עיסת נייר ענק. חלקן נפלו.
#  * ParadeFloat - עגלת מצעד (קארו אלגוריקו) נטושה: קומה שנייה (הפלטפורמה של השלב) + מסכה ענקית.
#  * Obstacle - "drums" (ערימת תופי מרקטו), "stall" (דוכן שתייה עם צידניות).
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const PASTELS := [Color("f2c94c"), Color("f4a3a8"), Color("8ec5e8"), Color("9bd3a8"), Color("f5a65b"), Color("c9a7e8"), Color("f7e1a0")]
const CONFETTI := [Color("ff4a6a"), Color("ffd23a"), Color("3ac0ff"), Color("5ae07a"), Color("c070ff"), Color("ff8a3a")]


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- רקע ----
static func morning_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("7fb8e6"), Color("a8d0ee"), Color("d6e2e6"), Color("f6dcb0"), Color("fbc98a")])
	var sun := Vector2(v.x * 0.22, 380.0)
	for i in 6:   # קרני שמש רכות
		var a := -0.9 + float(i) * 0.36 + sin(t * 0.1 + float(i)) * 0.02
		var d := Vector2.from_angle(a - PI * 0.5)
		ci.draw_colored_polygon(PackedVector2Array([sun, sun + d.rotated(-0.05) * 900.0, sun + d.rotated(0.05) * 900.0]), Color(1.0, 0.92, 0.7, 0.05))
	for i in 4:
		ci.draw_circle(sun, 150.0 - float(i) * 32.0, Color(1.0, 0.86, 0.55, 0.07 + float(i) * 0.04))
	ci.draw_circle(sun, 38.0, Color(1.0, 0.96, 0.82))
	Kit.clouds(ci, t * 6.0, v, t, 120.0, Color(1.0, 0.9, 0.86, 0.55), 4, 6.0)
	Kit.birds(ci, v, t, 8, Color(0.25, 0.22, 0.2, 0.6), 6)


static func sea_and_recife(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + 3):   # מגדלי רסיפה באובך
		var x := float(k) * period - sc
		var r := _rng(k * 31 + 5)
		for i in 9:
			var w := r.randf_range(22.0, 40.0)
			var h := r.randf_range(50.0, 130.0)
			ci.draw_rect(Rect2(x + float(i) * 52.0 + r.randf_range(0, 20), y - h, w, h), Color(0.62, 0.7, 0.8, 0.55))
	ci.draw_rect(Rect2(0, y, v.x, 60), Color("5aa8c8"))   # ים בוקר
	for i in 4:
		var yy := y + 5.0 + float(i) * 12.0
		ci.draw_line(Vector2(0, yy + sin(t + float(i)) * 1.5), Vector2(v.x, yy + sin(t * 1.2 + float(i) * 2.0) * 1.5), Color(1.0, 0.95, 0.8, 0.18), 2.0)


static func church(ci: CanvasItem, p: Vector2, s: float) -> void:
	var white := Color("f4f0e6")
	var shade := Color("d8d2c4")
	ci.draw_rect(Rect2(p + Vector2(-30, -40) * s, Vector2(60, 40) * s), white)
	for x: float in [-30.0, 18.0]:   # שני מגדלים
		ci.draw_rect(Rect2(p + Vector2(x, -72) * s, Vector2(12, 72) * s), white)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(x - 1, -72) * s, p + Vector2(x + 13, -72) * s, p + Vector2(x + 6, -86) * s]), Color("c86a3a"))
		ci.draw_rect(Rect2(p + Vector2(x + 3, -62) * s, Vector2(6, 8) * s), Color("4a3a2a"))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-18, -40) * s, p + Vector2(18, -40) * s, p + Vector2(0, -56) * s]), shade)   # חזית בארוק
	ci.draw_rect(Rect2(p + Vector2(-6, -18) * s, Vector2(12, 18) * s), Color("6a4a2a"))


static func palm(ci: CanvasItem, base: Vector2, h: float, c: Color, t: float, seed_v: int) -> void:
	var top := base + Vector2(sin(float(seed_v)) * 12.0, -h)
	ci.draw_line(base, top, c, 4.0)
	for i in 6:
		var a := -PI * 0.5 + (float(i) - 2.5) * 0.55 + sin(t * 1.3 + float(i) + float(seed_v)) * 0.06
		var e := top + Vector2.from_angle(a) * 34.0 + Vector2(0, 12)
		ci.draw_polyline(PackedVector2Array([top, top.lerp(e, 0.5) + Vector2(0, -6), e]), c, 2.5)


static func olinda_hill(ci: CanvasItem, sc: float, v: Vector2, base_y: float, t: float) -> void:
	var pts := PackedVector2Array([Vector2(-10, v.y)])
	for i in 41:
		var x := float(i) * (v.x + 20.0) / 40.0 - 10.0
		pts.append(Vector2(x, base_y - 70.0 - 60.0 * (0.5 + 0.5 * sin((x + sc) * 0.0035)) - 18.0 * sin((x + sc) * 0.011)))
	pts.append(Vector2(v.x + 10, v.y))
	ci.draw_colored_polygon(pts, Color("7aa86a"))
	var period := 1300.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + 3):
		var x0 := float(k) * period - sc
		var r := _rng(k * 977 + 11)
		for i in 26:   # בתים קטנים על הגבעה
			var x := x0 + r.randf_range(0.0, period)
			var gy := base_y - 70.0 - 60.0 * (0.5 + 0.5 * sin((x + sc) * 0.0035)) - 18.0 * sin((x + sc) * 0.011)
			var y := gy + r.randf_range(4.0, 90.0)
			var w := r.randf_range(14.0, 24.0)
			var c: Color = PASTELS[r.randi() % PASTELS.size()]
			ci.draw_rect(Rect2(x, y - 12.0, w, 12.0), c.lerp(Color(0.85, 0.9, 1.0), 0.25))
			ci.draw_rect(Rect2(x - 1.0, y - 15.0, w + 2.0, 3.0), Color("b85a34"))
		church(ci, Vector2(x0 + r.randf_range(300.0, 900.0), base_y - 100.0), 1.0)
		for i in 3:
			palm(ci, Vector2(x0 + r.randf_range(0.0, period), base_y + 10.0), r.randf_range(60.0, 90.0), Color("3a5a34"), t, k * 3 + i)


static func bunting_line(ci: CanvasItem, a: Vector2, b: Vector2, sag: float, t: float, seed_v: int) -> void:
	var n := int(a.distance_to(b) / 16.0)
	var prev := a
	for i in range(1, n + 1):
		var u := float(i) / float(n)
		var p := a.lerp(b, u) + Vector2(0, sin(u * PI) * sag + sin(t * 2.0 + u * 6.0) * 1.5)
		ci.draw_line(prev, p, Color(0.3, 0.25, 0.2, 0.7), 1.0)
		var c: Color = CONFETTI[(i + seed_v) % CONFETTI.size()]
		ci.draw_colored_polygon(PackedVector2Array([prev, p, prev.lerp(p, 0.5) + Vector2(0, 9)]), c)
		prev = p


# ============================================================
#  בתים קולוניאליים מאחורי הרחוב
# ============================================================
class ColonialRow extends Node2D:
	var seed_v := 0
	var skip := []
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(512, -100), 600.0):
			queue_redraw()

	func _skipped(x0: float, x1: float) -> bool:
		for s in skip:
			if x1 > float(s[0]) - 20.0 and x0 < float(s[1]) + 20.0:
				return true
		return false

	func _draw() -> void:
		var r := S15._rng(seed_v)
		var x := 0.0
		while x < 1024.0:
			var w := r.randf_range(110.0, 170.0)
			var h := r.randf_range(115.0, 160.0)
			if _skipped(x, x + w):
				x += w
				continue
			var c: Color = S15.PASTELS[r.randi() % S15.PASTELS.size()]
			draw_rect(Rect2(x, -h, w, h), c)
			draw_rect(Rect2(x, -h, w, h), Color(0, 0, 0, 0.08), false, 2.0)
			draw_rect(Rect2(x - 4.0, -h - 8.0, w + 8.0, 10.0), Color("b45a32"))   # גג רעפים
			draw_rect(Rect2(x, -h * 0.5 - 2.0, w, 4.0), Color(1, 1, 1, 0.75))   # כרכוב לבן
			var shut: Color = S15.PASTELS[r.randi() % S15.PASTELS.size()].darkened(0.35)
			for k in 2:   # חלונות עם תריסים ומרפסת ברזל
				var wx := x + w * (0.22 + 0.42 * float(k))
				var wy := -h + 26.0
				draw_rect(Rect2(wx - 10.0, wy, 20.0, 30.0), Color("2a2620"))
				var broken := r.randf() < 0.3
				draw_rect(Rect2(wx - 10.0, wy, 9.0, 30.0 if not broken else 18.0), shut)
				draw_rect(Rect2(wx + 1.0, wy, 9.0, 30.0), shut)
				draw_line(Vector2(wx - 14.0, wy + 30.0), Vector2(wx + 14.0, wy + 30.0), Color("2a2a2a"), 2.0)
				for q in 6:
					draw_line(Vector2(wx - 13.0 + float(q) * 5.2, wy + 30.0), Vector2(wx - 13.0 + float(q) * 5.2, wy + 40.0), Color("2a2a2a"), 1.0)
			# דלת עם קשת
			var dx := x + w * 0.5
			draw_rect(Rect2(dx - 12.0, -46.0, 24.0, 46.0), Color("5a3a22"))
			draw_arc(Vector2(dx, -46.0), 12.0, PI, TAU, 10, Color("5a3a22"), 6.0)
			if r.randf() < 0.45:   # מסכת קרנבל על הקיר
				var mp := Vector2(x + w * r.randf_range(0.2, 0.8), -h * 0.5 + 16.0)
				Art.oval(self, mp, 9.0, 6.0, S15.CONFETTI[r.randi() % 6], 0.0, Art.OUTLINE, 1.0)
				draw_circle(mp + Vector2(-3.5, -1), 1.8, Color("1a1a1a"))
				draw_circle(mp + Vector2(3.5, -1), 1.8, Color("1a1a1a"))
				draw_line(mp + Vector2(-9, -2), mp + Vector2(-15, -10), S15.CONFETTI[r.randi() % 6], 2.0)
			if r.randf() < 0.35:   # כתם דם / יד על הקיר
				Art.oval(self, Vector2(x + w * r.randf_range(0.1, 0.9), -r.randf_range(20.0, 60.0)), 6.0, 10.0, Color(0.45, 0.05, 0.05, 0.45), 0.4, Art.NONE)
			x += w
		# קונפטי על הרצפה
		for i in 90:
			var cx := r.randf_range(0.0, 1024.0)
			draw_rect(Rect2(cx, -r.randf_range(1.0, 4.0), 3.0, 2.0), S15.CONFETTI[i % S15.CONFETTI.size()])

	const S15 := preload("res://effects/s15_decor.gd")


# ============================================================
#  בובת ענק של אולינדה (קישוט). fallen = שוכבת על הצד
# ============================================================
class GiantPuppet extends Node2D:
	var seed_v := 0
	var fallen := false
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(0, -90), 160.0):
			queue_redraw()

	func _draw() -> void:
		var r := S15._rng(seed_v)
		var cloth: Color = S15.CONFETTI[r.randi() % 6]
		var cloth2: Color = S15.PASTELS[r.randi() % S15.PASTELS.size()]
		var skin := Color("f0c8a0") if r.randf() < 0.5 else Color("8a5a3a")
		if fallen:
			draw_set_transform(Vector2(0, -6), -PI * 0.47, Vector2.ONE)
		var sway := sin(_t * 0.8 + float(seed_v)) * 1.5 if not fallen else 0.0
		# גוף בד רחב (פעמון)
		draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(16 + sway, -96), Vector2(-16 + sway, -96)]), cloth)
		for i in 4:
			draw_line(Vector2(-30 + float(i) * 20.0, 0), Vector2(-12 + float(i) * 8.0 + sway, -94), cloth.darkened(0.2), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-22, -60), Vector2(22, -60), Vector2(16 + sway, -96), Vector2(-16 + sway, -96)]), cloth2)
		# ידיים רפויות
		draw_line(Vector2(-16 + sway, -90), Vector2(-36, -40), cloth2.darkened(0.15), 7.0)
		draw_line(Vector2(16 + sway, -90), Vector2(36, -44), cloth2.darkened(0.15), 7.0)
		draw_circle(Vector2(-37, -38), 5.0, skin)
		draw_circle(Vector2(37, -42), 5.0, skin)
		# ראש עיסת נייר ענק
		var hc := Vector2(sway, -122)
		Art.oval(self, hc, 24.0, 28.0, skin, 0.0, Art.OUTLINE, 2.0)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-25, -6), hc + Vector2(-16, -30), hc + Vector2(14, -32), hc + Vector2(26, -8), hc + Vector2(6, -20)]), Color("2a1a10"))
		draw_circle(hc + Vector2(-9, -2), 5.0, Color.WHITE)
		draw_circle(hc + Vector2(9, -2), 5.0, Color.WHITE)
		draw_circle(hc + Vector2(-8, -1), 2.4, Color("2a3a6a"))
		draw_circle(hc + Vector2(10, -1), 2.4, Color("2a3a6a"))
		draw_arc(hc + Vector2(0, 10), 9.0, 0.3, PI - 0.3, 10, Color("a01818"), 3.0)
		Art.oval(self, hc + Vector2(-14, 8), 4.0, 2.5, Color(0.95, 0.45, 0.45, 0.6), 0.0, Art.NONE)
		Art.oval(self, hc + Vector2(14, 8), 4.0, 2.5, Color(0.95, 0.45, 0.45, 0.6), 0.0, Art.NONE)
		if fallen:   # הראש נסדק
			draw_polyline(PackedVector2Array([hc + Vector2(-4, -26), hc + Vector2(2, -14), hc + Vector2(-3, -4)]), Color("3a2a1a"), 1.5)
		draw_set_transform_matrix(Transform2D.IDENTITY)

	const S15 := preload("res://effects/s15_decor.gd")


# ============================================================
#  עגלת מצעד נטושה (מתחת לקומה שנייה שהשלב מוסיף). w = רוחב, h = גובה הפלטפורמה
# ============================================================
class ParadeFloat extends Node2D:
	var w := 380.0
	var h := 130.0
	var seed_v := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -h), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		var r := S15._rng(seed_v)
		var base: Color = S15.CONFETTI[r.randi() % 6]
		# שלדה + חצאית מקושטת
		draw_rect(Rect2(0, -h, w, h - 16.0), base.darkened(0.15))
		for i in int(w / 26.0):   # חצאית משולשים
			var c: Color = S15.CONFETTI[(i + seed_v) % 6]
			draw_colored_polygon(PackedVector2Array([Vector2(float(i) * 26.0, -h), Vector2(float(i) * 26.0 + 26.0, -h), Vector2(float(i) * 26.0 + 13.0, -h + 22.0)]), c)
		for i in 4:   # גלגלים
			var wx := w * (0.12 + 0.25 * float(i))
			draw_circle(Vector2(wx, -12.0), 12.0, Color("1a1a1a"))
			draw_circle(Vector2(wx, -12.0), 5.0, Color("8a8a8a"))
		# מסכה ענקית (פסל) בצד העגלה
		var mc := Vector2(w * 0.78, -h - 60.0)
		Art.oval(self, mc, 42.0, 34.0, Color("f8d040"), 0.0, Art.OUTLINE, 2.0)
		draw_circle(mc + Vector2(-15, -4), 9.0, Color("1a1a22"))
		draw_circle(mc + Vector2(15, -4), 9.0, Color("1a1a22"))
		for i in 7:   # נוצות צבעוניות
			var a := -PI * 0.5 + (float(i) - 3.0) * 0.28 + sin(_t * 1.5 + float(i)) * 0.04
			draw_line(mc + Vector2(0, -28), mc + Vector2(0, -28) + Vector2.from_angle(a) * 46.0, S15.CONFETTI[i % 6], 5.0)
		draw_line(mc + Vector2(0, 34), Vector2(mc.x, -h), Color("5a4a3a"), 6.0)   # עמוד
		# מטריות פרבו קטנות לאורך המעקה
		for i in 4:
			var ux := w * (0.08 + 0.17 * float(i))
			var up := Vector2(ux, -h - 30.0)
			draw_line(up, Vector2(ux, -h), Color("3a3a3a"), 1.5)
			for q in 6:
				draw_colored_polygon(PackedVector2Array([up, up + Vector2.from_angle(PI + float(q) * PI / 6.0) * 16.0, up + Vector2.from_angle(PI + float(q + 1) * PI / 6.0) * 16.0]), S15.CONFETTI[q])

	const S15 := preload("res://effects/s15_decor.gd")


# ============================================================
#  מכשולים מוצקים על הרחוב
# ============================================================
class Obstacle extends Node2D:
	var kind := "drums"
	var size := Vector2(90, 40)
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
		var r := S15._rng(seed_v)
		if kind == "drums":   # תופי מרקטו (אלפאיה) בערימה
			var n := int(size.x / 30.0)
			for row in 2:
				for i in n - row:
					var p := Vector2(15.0 + float(i) * 30.0 + float(row) * 15.0, -size.y * 0.25 - float(row) * size.y * 0.5)
					var c: Color = S15.CONFETTI[r.randi() % 6]
					draw_rect(Rect2(p + Vector2(-14, -size.y * 0.25), Vector2(28, size.y * 0.5)), c.darkened(0.2))
					for q in 4:   # חבלי מתיחה בזיגזג
						draw_line(p + Vector2(-14 + float(q) * 7.0, -size.y * 0.25), p + Vector2(-10.5 + float(q) * 7.0, size.y * 0.25), Color("e8d8b0"), 1.0)
					draw_rect(Rect2(p + Vector2(-14, -size.y * 0.25), Vector2(28, size.y * 0.5)), Art.OUTLINE, false, 1.4)
		else:   # דוכן שתייה: צידניות קלקר + שמשייה שבורה
			draw_rect(Rect2(0, -size.y, size.x, size.y), Color("e8e8e0"))
			draw_rect(Rect2(0, -size.y, size.x, size.y), Art.OUTLINE, false, 1.6)
			draw_rect(Rect2(4, -size.y + 6, size.x - 8, 8), Color("3a8ae0"))
			draw_string(ThemeDB.fallback_font, Vector2(8, -size.y * 0.35), "CERVEJA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c02020"))
			var up := Vector2(size.x * 0.7, -size.y - 34.0)
			draw_line(up, Vector2(size.x * 0.7, -size.y), Color("5a5a5a"), 2.0)
			for q in 5:
				draw_colored_polygon(PackedVector2Array([up, up + Vector2.from_angle(PI * 0.95 + float(q) * 0.25) * 30.0, up + Vector2.from_angle(PI * 0.95 + float(q + 1) * 0.25) * 30.0]), Color("e83a3a") if q % 2 == 0 else Color("f0f0f0"))

	const S15 := preload("res://effects/s15_decor.gd")
