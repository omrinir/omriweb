extends RefCounted
# ============================================================
#  S9 FX - אפקטים של שלב 9 ("THEY LEARN"):
#    OrderLinks  - קווי פקודה מה-COMMANDER לכל זומבי שקיבל פקודה (רואים מי שומע למי)
#    LightRain   - גשם קל על המסך (פחות טיפות מ-rain.gd, בלי ברקים)
#    פונקציות ציור לרקע (סטטיות): מגדל בוער, שלד גורד שחקים, מנוף, כיפת מעבדה,
#    המון זומבים צועד באופק, זרקור מסתובב, מסוק עם זרקור.
#  איך משנים: צבעים / גדלים בתוך כל פונקציה. מספר הטיפות: LightRain.COUNT
# ============================================================

const Art := preload("res://art.gd")


# ---- קווי פקודה (COMMANDER -> הזומבים) ----
class OrderLinks extends Node2D:
	var from_z: Node2D = null
	var targets := []
	var color := Color(1.0, 0.8, 0.3)
	var _t := 0.0
	const LIFE := 0.9

	func _ready() -> void:
		z_index = 19

	func _process(delta: float) -> void:
		_t += delta
		if _t > LIFE or from_z == null or not is_instance_valid(from_z):
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := 1.0 - _t / LIFE
		var o: Vector2 = from_z.global_position + Vector2(0, -60) - global_position
		for tz in targets:
			if not is_instance_valid(tz) or tz.dead:
				continue
			var e: Vector2 = tz.global_position + Vector2(0, -52) - global_position
			var n := int(o.distance_to(e) / 14.0)
			for i in n:   # קו מקווקו שזורם מהמפקד אל הזומבי
				var k0 := (float(i) + fmod(_t * 4.0, 1.0)) / float(maxi(n, 1))
				var k1 := minf(k0 + 0.5 / float(maxi(n, 1)), 1.0)
				draw_line(o.lerp(e, k0), o.lerp(e, k1), Color(color, 0.75 * a), 1.6, true)
			# חץ קטן מעל הזומבי
			draw_colored_polygon(PackedVector2Array([e + Vector2(-5, -8), e + Vector2(5, -8), e + Vector2(0, -1)]), Color(color, 0.9 * a))
			Art.glow(self, e, 7.0, Color(color, 0.5 * a))


# ---- גשם קל (על המסך) ----
class LightRain extends Node2D:
	const COUNT := 80
	var _drops := []

	func _ready() -> void:
		for i in COUNT:
			_drops.append([randf() * 1400.0, randf() * 760.0, randf_range(650.0, 900.0), randf_range(8.0, 16.0)])

	func _process(delta: float) -> void:
		for d in _drops:
			d[1] += d[2] * delta
			d[0] -= d[2] * 0.3 * delta
			if d[1] > 740.0:
				d[1] = -20.0
				d[0] = randf() * 1400.0
		queue_redraw()

	func _draw() -> void:
		for d in _drops:
			var p := Vector2(d[0], d[1])
			draw_line(p, p + Vector2(-d[3] * 0.3, d[3]), Color(0.75, 0.72, 0.78, 0.22), 1.0)


# ============================================================
#  ציורי רקע (נקראים מ-levels/stage_9.gd -> build_background)
# ============================================================
# מגדל בוער: בניין גבוה שבור עם להבות בחלונות ועשן
static func burning_tower(ci: CanvasItem, x: float, base_y: float, w: float, h: float, col: Color, t: float, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var top := base_y - h
	var cut := r.randf_range(0.2, 0.8) * w
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x, base_y), Vector2(x, top + 20), Vector2(x + cut, top + r.randf_range(-10, 40)), Vector2(x + cut + 8, top + 50), Vector2(x + w, top + r.randf_range(10, 60)), Vector2(x + w, base_y)]), col)
	var wy := top + 60.0
	while wy < base_y - 20.0:
		var wx := x + 8.0
		while wx < x + w - 10.0:
			var q := r.randf()
			if q < 0.12:   # חלון בוער
				var fl := 0.6 + 0.4 * sin(t * 8.0 + wx * 0.3 + wy)
				ci.draw_rect(Rect2(wx, wy, 7, 9), Color(1.0, 0.45 + 0.2 * fl, 0.1, 0.85))
				ci.draw_circle(Vector2(wx + 3.5, wy + 2), 9.0 * fl, Color(1.0, 0.4, 0.1, 0.12))
			elif q < 0.18:
				ci.draw_rect(Rect2(wx, wy, 7, 9), Color(1.0, 0.8, 0.5, 0.35))
			wx += 14.0
		wy += 18.0
	# להבות על הגג השבור
	for i in 4:
		var fx := x + cut - 20.0 + float(i) * 12.0
		var fh := 18.0 + 10.0 * sin(t * 9.0 + float(i) * 1.9 + float(seed_v))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(fx - 7, top + 40), Vector2(fx, top + 40 - fh), Vector2(fx + 7, top + 40)]), Color(1.0, 0.55, 0.15, 0.8))
	ci.draw_circle(Vector2(x + cut, top + 30), 40.0, Color(1.0, 0.45, 0.15, 0.08))


# שלד של גורד שחקים (קורות פלדה חשופות)
static func skeleton_tower(ci: CanvasItem, x: float, base_y: float, w: float, h: float, col: Color, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var floors := int(h / 26.0)
	var cols := int(w / 22.0) + 1
	for f in floors:
		var y := base_y - float(f) * 26.0
		var span := w * (1.0 if f < floors * 0.6 else r.randf_range(0.3, 0.9))
		ci.draw_line(Vector2(x, y), Vector2(x + span, y), col, 2.0)
		if r.randf() < 0.5 and f < floors - 1:
			ci.draw_line(Vector2(x + r.randf_range(0, span * 0.5), y), Vector2(x + r.randf_range(span * 0.5, span), y - 26.0), col, 1.0)
	for c in cols:
		var cx := x + float(c) * 22.0
		var ch := h * (1.0 if c % 3 != 2 else r.randf_range(0.5, 0.9))
		ci.draw_line(Vector2(cx, base_y), Vector2(cx, base_y - ch), col, 2.0)
	# קורה תלויה שמתנדנדת
	ci.draw_line(Vector2(x + w, base_y - h * 0.7), Vector2(x + w + 30, base_y - h * 0.7 + 40), col, 2.5)


# מנוף בנייה (אלמנט "מפעל")
static func crane(ci: CanvasItem, x: float, base_y: float, h: float, col: Color, t: float) -> void:
	ci.draw_rect(Rect2(x, base_y - h, 10, h), col)
	for i in int(h / 20.0):   # הצלבות
		var y := base_y - float(i) * 20.0
		ci.draw_line(Vector2(x, y), Vector2(x + 10, y - 20), Color(col, 0.6), 1.0)
	var arm := 170.0
	ci.draw_rect(Rect2(x - 60, base_y - h - 8, arm + 60, 8), col)
	ci.draw_line(Vector2(x + 5, base_y - h - 30), Vector2(x + arm, base_y - h - 8), col, 1.5)
	ci.draw_line(Vector2(x + 5, base_y - h - 30), Vector2(x - 60, base_y - h - 8), col, 1.5)
	# כבל + וו שמתנדנד ברוח
	var sw := sin(t * 0.7) * 10.0
	var hook := Vector2(x + arm - 20 + sw, base_y - h + 70)
	ci.draw_line(Vector2(x + arm - 20, base_y - h), hook, Color(col, 0.8), 1.0)
	ci.draw_rect(Rect2(hook + Vector2(-8, 0), Vector2(16, 12)), col)
	if int(t * 1.5) % 2 == 0:
		ci.draw_circle(Vector2(x + 5, base_y - h - 32), 2.0, Color(1.0, 0.2, 0.2, 0.9))


# כיפת מעבדה שבורה עם זוהר ירוק (אלמנט "מעבדה")
static func lab_dome(ci: CanvasItem, x: float, base_y: float, r: float, col: Color, t: float) -> void:
	var pts := PackedVector2Array([Vector2(x - r, base_y)])
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		var rr := r * (0.75 if i == 5 or i == 6 else 1.0)   # חור בכיפה
		pts.append(Vector2(x + cos(a) * rr, base_y + sin(a) * rr))
	pts.append(Vector2(x + r, base_y))
	ci.draw_colored_polygon(pts, col)
	var pulse := 0.5 + 0.5 * sin(t * 1.3)
	ci.draw_circle(Vector2(x - r * 0.05, base_y - r * 0.8), r * 0.4, Color(0.4, 1.0, 0.45, 0.10 + 0.08 * pulse))
	ci.draw_circle(Vector2(x - r * 0.05, base_y - r * 0.8), r * 0.18, Color(0.6, 1.0, 0.5, 0.15 + 0.1 * pulse))
	for i in 5:   # צלעות מתכת
		var a := PI + PI * (0.1 + 0.8 * float(i) / 4.0)
		ci.draw_line(Vector2(x, base_y), Vector2(x + cos(a) * r, base_y + sin(a) * r), Color(col.lightened(0.15), 0.6), 1.0)
	# אנטנה עם מנורה
	ci.draw_line(Vector2(x + r * 0.5, base_y - r * 0.85), Vector2(x + r * 0.55, base_y - r * 1.35), col, 2.0)
	if int(t * 2.0) % 3 == 0:
		ci.draw_circle(Vector2(x + r * 0.55, base_y - r * 1.35), 2.5, Color(0.5, 1.0, 0.5, 0.9))


# המון זומבים שצועד לאורך האופק (זז לבד - האזור בשליטתם)
static func horde(ci: CanvasItem, scroll: float, vp: Vector2, t: float, y: float, col: Color, seed_v: int, speed := 14.0) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var span := vp.x + 600.0
	for i in 34:
		var ox := r.randf_range(0.0, span)
		var x := fposmod(ox - scroll + t * speed, span) - 300.0
		var h := r.randf_range(9.0, 14.0)
		var bob := absf(sin(t * 3.0 + float(i))) * 1.2
		var py := y + r.randf_range(-3.0, 3.0) - bob
		ci.draw_rect(Rect2(x - 2.0, py - h, 4.0, h * 0.65), col)                       # גוף
		ci.draw_circle(Vector2(x + 0.5, py - h - 1.5), 2.2, col)                         # ראש
		ci.draw_line(Vector2(x + 1, py - h * 0.8), Vector2(x + 6, py - h * 0.75 + bob), col, 1.2)   # ידיים מושטות
		var st := sin(t * 3.0 + float(i)) * 2.0
		ci.draw_line(Vector2(x - 1, py - h * 0.35), Vector2(x - 1 + st, py), col, 1.3)     # רגליים
		ci.draw_line(Vector2(x + 1, py - h * 0.35), Vector2(x + 1 - st, py), col, 1.3)


# זרקור שמסתובב בשמיים (מחנה ניצולים רחוק / מסוק)
static func searchlight(ci: CanvasItem, base: Vector2, t: float, phase: float, col := Color(0.95, 0.95, 0.8, 0.06)) -> void:
	var a := -PI * 0.5 + sin(t * 0.35 + phase) * 0.7
	var d := Vector2.from_angle(a)
	var n := Vector2(-d.y, d.x)
	var far := base + d * 700.0
	ci.draw_colored_polygon(PackedVector2Array([base - n * 3.0, base + n * 3.0, far + n * 70.0, far - n * 70.0]), col)
	ci.draw_circle(base, 4.0, Color(1.0, 1.0, 0.85, 0.5))
