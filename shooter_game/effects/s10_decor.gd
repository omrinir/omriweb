extends RefCounted
# ============================================================
#  שלב 10 (צפון-מזרח ברזיל, "מישורי המלח") - ציורי רקע וקישוטים.
#  השראה: ערימות המלח של מוסורו, בריכות אידוי ורודות, דיונות לבנות עם לגונות
#  (לנסואיס), טורבינות רוח על החוף של סיארה, מגדלור, ספינות "ז'נגדה" עם מפרש משולש,
#  דקלי קוקוס וקרנאובה, קקטוס מנדקרו, בתים קולוניאליים צבעוניים עם גגות רעפים.
#  * פונקציות static לציור בשכבות הפרלקסה (ci = מה שמציירים עליו).
#  * SaltWorks - קישוט עולם מאחורי הכביש (בריכות אידוי, ערימות מלח, בתים), חלקים של 1024.
#  * Obstacle - מכשולים על הכביש: "sacks" (שקי מלח), "jangada" (סירה על החוף), "cart" (עגלה).
#  * HeatHaze - גלי חום מעל האופק (שכבת מסך).
# ============================================================

const Art := preload("res://art.gd")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---------------- רקע: חלקים ----------------
static func turbine(ci: CanvasItem, base: Vector2, h: float, t: float, phase: float, c: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-3.5, 0), base + Vector2(3.5, 0), base + Vector2(1.5, -h), base + Vector2(-1.5, -h)]), c)
	var hub := base + Vector2(0, -h)
	ci.draw_rect(Rect2(hub.x - 4.0, hub.y - 3.0, 9.0, 5.0), c)
	var bl := h * 0.42
	for i in 3:
		var a := t * 1.6 + phase + float(i) * TAU / 3.0
		var d := Vector2.from_angle(a)
		var n := Vector2(-d.y, d.x)
		ci.draw_colored_polygon(PackedVector2Array([hub + n * 2.0, hub + d * bl + n * 0.6, hub + d * bl - n * 0.4, hub - n * 1.5]), c)
	ci.draw_circle(hub, 2.6, c.lightened(0.15))


static func coconut_palm(ci: CanvasItem, base: Vector2, h: float, lean: float, t: float, seed_v: int, c: Color) -> void:
	var sway := sin(t * 1.1 + float(seed_v)) * 4.0
	var top := base + Vector2(lean * h * 0.35 + sway, -h)
	var ctrl := base + Vector2(lean * h * 0.05, -h * 0.55)
	var prev := base
	for i in range(1, 11):   # גזע מעוקל שמתעבה למטה
		var u := float(i) / 10.0
		var p := base.lerp(ctrl, u).lerp(ctrl.lerp(top, u), u)
		ci.draw_line(prev, p, c, lerpf(7.0, 4.0, u))
		prev = p
	for i in 7:   # עלים
		var a := -PI * 0.5 + (float(i) - 3.0) * 0.48 + sin(t * 1.6 + float(i) + float(seed_v)) * 0.06
		var len := h * (0.32 + 0.06 * float(i % 3))
		var tip := top + Vector2(cos(a) * len, sin(a) * len * 0.5 + len * 0.42)
		var mid := top + Vector2(cos(a) * len * 0.5, sin(a) * len * 0.5 - 6.0)
		var pts := PackedVector2Array()
		for q in 7:
			var u := float(q) / 6.0
			pts.append(top.lerp(mid, u).lerp(mid.lerp(tip, u), u))
		ci.draw_polyline(pts, c, 3.0)
		for q in range(1, 6):   # עלעלים
			var pp: Vector2 = pts[q]
			ci.draw_line(pp, pp + Vector2(cos(a) * 3.0, 9.0 - float(q)), c, 1.6)
	ci.draw_circle(top + Vector2(2, 4), 3.0, c)   # קוקוסים
	ci.draw_circle(top + Vector2(-3, 5), 3.0, c)


static func carnauba(ci: CanvasItem, base: Vector2, h: float, t: float, c: Color) -> void:
	ci.draw_line(base, base + Vector2(0, -h), c, 3.0)
	var top := base + Vector2(sin(t * 0.9 + base.x) * 1.5, -h)
	for i in 11:   # כתר מניפה עגול
		var a := PI + float(i) * PI / 10.0
		ci.draw_line(top, top + Vector2(cos(a), sin(a) * 0.9) * h * 0.22, c, 2.0)
	ci.draw_circle(top, h * 0.06, c)


static func mandacaru(ci: CanvasItem, base: Vector2, h: float, c: Color) -> void:
	var w := maxf(5.0, h * 0.09)
	ci.draw_rect(Rect2(base.x - w * 0.5, base.y - h, w, h), c)
	ci.draw_circle(base + Vector2(0, -h), w * 0.5, c)
	for s: float in [-1.0, 1.0]:   # זרועות "מנורה"
		var ay := base.y - h * (0.45 if s < 0.0 else 0.6)
		var ax := base.x + s * w * 2.2
		ci.draw_rect(Rect2(minf(base.x, ax), ay - w * 0.5, absf(ax - base.x), w), c)
		ci.draw_rect(Rect2(ax - w * 0.5, ay - h * 0.35, w, h * 0.35), c)
		ci.draw_circle(Vector2(ax, ay - h * 0.35), w * 0.5, c)


static func salt_mound(ci: CanvasItem, base: Vector2, w: float, h: float, lit: Color, dark: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		pts.append(base + Vector2((u - 0.5) * w, -h * pow(sin(u * PI), 0.8)))
	ci.draw_colored_polygon(pts, lit)
	var sh := PackedVector2Array([base + Vector2(0.05 * w, -h * 0.98), base + Vector2(w * 0.5, 0), base + Vector2(w * 0.12, 0)])
	ci.draw_colored_polygon(sh, dark)


static func house(ci: CanvasItem, base: Vector2, w: float, h: float, wall: Color, r: RandomNumberGenerator, dim: float) -> void:
	var wall_c := wall.darkened(dim)
	ci.draw_rect(Rect2(base.x, base.y - h, w, h), wall_c)
	ci.draw_rect(Rect2(base.x, base.y - h, w, 4.0), wall_c.lightened(0.25))   # כרכוב לבן
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-4, -h), base + Vector2(w + 4, -h), base + Vector2(w - 6, -h - 14), base + Vector2(6, -h - 14)]), Color("a04a2a").darkened(dim))
	var n := maxi(1, int(w / 26.0))
	for i in n:   # דלתות / חלונות מקושתים
		var cx := base.x + (float(i) + 0.5) * w / float(n)
		var dh := h * (0.55 if i % 2 == 0 else 0.4)
		var dc := Color("2a4a5a").darkened(dim) if r.randf() < 0.6 else Color("5a2a2a").darkened(dim)
		ci.draw_rect(Rect2(cx - 5.0, base.y - dh - (0.0 if i % 2 == 0 else h * 0.2), 10.0, dh), dc)
		ci.draw_circle(Vector2(cx, base.y - dh - (0.0 if i % 2 == 0 else h * 0.2)), 5.0, dc)


static func jangada(ci: CanvasItem, p: Vector2, s: float, t: float, c: Color, sail: Color) -> void:
	var bob := sin(t * 1.4 + p.x * 0.01) * 1.5
	var q := p + Vector2(0, bob)
	ci.draw_rect(Rect2(q.x - 14.0 * s, q.y - 2.0 * s, 28.0 * s, 3.0 * s), c)
	ci.draw_line(q + Vector2(0, -2.0 * s), q + Vector2(-2.0 * s, -30.0 * s), c, 1.2)
	ci.draw_colored_polygon(PackedVector2Array([q + Vector2(-1.5 * s, -29.0 * s), q + Vector2(14.0 * s, -6.0 * s), q + Vector2(0, -4.0 * s)]), sail)


static func lighthouse(ci: CanvasItem, base: Vector2, h: float, t: float) -> void:
	var w0 := h * 0.13
	var w1 := h * 0.08
	for i in 6:   # פסים אדומים-לבנים
		var y0 := base.y - h * float(i) / 6.0
		var y1 := base.y - h * float(i + 1) / 6.0
		var a := lerpf(w0, w1, float(i) / 6.0)
		var b := lerpf(w0, w1, float(i + 1) / 6.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - a, y0), Vector2(base.x + a, y0), Vector2(base.x + b, y1), Vector2(base.x - b, y1)]), Color("c84a3a") if i % 2 == 0 else Color("e8e0d0"))
	var lamp := base + Vector2(0, -h - 6.0)
	ci.draw_rect(Rect2(lamp.x - w1, lamp.y - 4.0, w1 * 2.0, 10.0), Color("3a3a3a"))
	ci.draw_circle(lamp, 5.0, Color(1.0, 0.95, 0.6, 0.9))
	var a := sin(t * 0.9)   # אלומה מסתובבת
	var dir := Vector2(signf(a) if a != 0.0 else 1.0, 0.0)
	var len := 260.0 * absf(a)
	ci.draw_colored_polygon(PackedVector2Array([lamp, lamp + dir * len + Vector2(0, -18), lamp + dir * len + Vector2(0, 18)]), Color(1.0, 0.95, 0.7, 0.13 * absf(a)))


# ============================================================
#  קישוט עולם (מאחורי הכביש): בריכות אידוי, ערימות מלח, בתים, דקלים, שלט "SAL"
# ============================================================
class SaltWorks extends Node2D:
	var seed_v := 0

	func _ready() -> void:
		z_index = -3

	func _draw() -> void:
		var r := S10._rng(seed_v)
		var x := 0.0
		while x < 1024.0:
			var pick := r.randf()
			if pick < 0.4:   # בריכת אידוי (מים ורודים-לבנים עם סוללות בוץ)
				var w := r.randf_range(160.0, 260.0)
				var water := Color("d8a8b0").lerp(Color("e8e0e0"), r.randf())
				draw_rect(Rect2(x, -18.0, w, 18.0), Color("7a6450"))
				draw_rect(Rect2(x + 6.0, -14.0, w - 12.0, 10.0), water)
				for k in 4:   # גבישי מלח ובוהק
					var gx := x + 12.0 + r.randf_range(0.0, w - 30.0)
					draw_line(Vector2(gx, -9.0), Vector2(gx + r.randf_range(8.0, 18.0), -9.0), Color(1, 1, 1, 0.6), 1.0)
				if r.randf() < 0.6:   # מגרפה עומדת
					var rx := x + r.randf_range(20.0, w - 20.0)
					draw_line(Vector2(rx, -12.0), Vector2(rx + 10.0, -46.0), Color("6a4a2a"), 2.0)
					draw_line(Vector2(rx - 8.0, -12.0), Vector2(rx + 8.0, -12.0), Color("6a4a2a"), 3.0)
				x += w + r.randf_range(10.0, 30.0)
			elif pick < 0.7:   # ערימת מלח
				var w := r.randf_range(90.0, 150.0)
				var h := r.randf_range(50.0, 90.0)
				S10.salt_mound(self, Vector2(x + w * 0.5, 0.0), w, h, Color("ece6de"), Color("c8c0b8"))
				for k in 5:
					draw_circle(Vector2(x + r.randf_range(10.0, w - 10.0), -r.randf_range(4.0, h * 0.6)), 1.2, Color("ffffff"))
				x += w + r.randf_range(10.0, 40.0)
			elif pick < 0.88:   # בית קולוניאלי צבעוני
				var w := r.randf_range(90.0, 150.0)
				var h := r.randf_range(70.0, 110.0)
				var cols := [Color("e8b84a"), Color("4aa0b8"), Color("e87a6a"), Color("7ac08a"), Color("c890c8"), Color("f0e0c0")]
				S10.house(self, Vector2(x, 0.0), w, h, cols[r.randi() % cols.size()], r, 0.25)
				if r.randf() < 0.5:   # כתובת על הקיר
					var tags := ["SAL", "SOCORRO", "ELES APRENDEM", "FUJA", "SAL MOSSORÓ"]
					draw_string(ThemeDB.fallback_font, Vector2(x + 8.0, -h * 0.35), tags[r.randi() % tags.size()], HORIZONTAL_ALIGNMENT_LEFT, w - 12.0, 12, Color(0.55, 0.1, 0.1, 0.75))
				x += w + r.randf_range(0.0, 20.0)
			else:   # דקל קוקוס + קקטוס
				S10.coconut_palm(self, Vector2(x + 20.0, 0.0), r.randf_range(120.0, 170.0), r.randf_range(-0.4, 0.4), 0.0, r.randi() % 50, Color("3a3424"))
				S10.mandacaru(self, Vector2(x + 60.0, 0.0), r.randf_range(40.0, 70.0), Color("4a6a3a"))
				x += 90.0

	const S10 := preload("res://effects/s10_decor.gd")


# ============================================================
#  מכשולים על הכביש (מוצקים: גוף + קו מתאר אוטומטי)
# ============================================================
class Obstacle extends Node2D:
	var kind := "sacks"
	var size := Vector2(70, 40)
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
		var r := S10._rng(seed_v)
		match kind:
			"sacks":   # שקי מלח מוערמים
				var rows := int(size.y / 14.0)
				for row in rows:
					var n := int(size.x / 22.0) - (row % 2)
					for i in n:
						var c := Vector2(11.0 + float(i) * 22.0 + float(row % 2) * 11.0, -7.0 - float(row) * 14.0)
						Art.oval_shaded(self, c, 11.5, 7.5, Color("e0d8c8").darkened(r.randf() * 0.12), r.randf_range(-0.1, 0.1))
						draw_string(ThemeDB.fallback_font, c + Vector2(-7, 3), "SAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.3, 0.6, 0.7))
			"jangada":   # רפסודת דייגים על החוף, תורן ומפרש קרוע
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, -size.y), Vector2(size.x, -size.y), Vector2(size.x - 10, 0), Vector2(10, 0)]), Color("8a6440"), 0.15, 0.35)
				for i in 5:
					draw_line(Vector2(6 + i * size.x / 5.0, -size.y + 2), Vector2(14 + i * size.x / 5.0, -2), Color("5a3e24"), 1.5)
				draw_line(Vector2(size.x * 0.45, -size.y), Vector2(size.x * 0.4, -size.y - 90.0), Color("5a3e24"), 3.0)
				Art.fill(self, PackedVector2Array([Vector2(size.x * 0.41, -size.y - 86.0), Vector2(size.x * 0.95, -size.y - 14.0), Vector2(size.x * 0.46, -size.y - 8.0)]), Color("e8dcc0"), Art.OUTLINE, 1.2)
				Art.fill(self, PackedVector2Array([Vector2(size.x * 0.6, -size.y - 50.0), Vector2(size.x * 0.75, -size.y - 30.0), Vector2(size.x * 0.66, -size.y - 26.0)]), Color("2a2620"), Art.NONE)   # קרע
			_:   # עגלה עם שקים
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, -size.y), Vector2(size.x, -size.y), Vector2(size.x, -12), Vector2(0, -12)]), Color("7a5a3a"), 0.15, 0.3)
				for i in 3:
					Art.oval_shaded(self, Vector2(14.0 + float(i) * (size.x - 28.0) * 0.5, -size.y - 6.0), 12.0, 7.0, Color("e0d8c8"), 0.0)
				Art.disc(self, Vector2(size.x * 0.25, -10), 10.0, Color("4a3a2a"))
				Art.disc(self, Vector2(size.x * 0.75, -10), 10.0, Color("4a3a2a"))
				draw_line(Vector2(size.x, -size.y + 6), Vector2(size.x + 30, -8), Color("5a3e24"), 3.0)

	const S10 := preload("res://effects/s10_decor.gd")


# ============================================================
#  גלי חום מעל האופק (שכבת מסך, עדין)
# ============================================================
class HeatHaze extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for i in 7:
			var y := vp.y * 0.6 + float(i) * 18.0
			var pts := PackedVector2Array()
			for k in 33:
				var x := float(k) * vp.x / 32.0
				pts.append(Vector2(x, y + sin(x * 0.02 + _t * 2.2 + float(i)) * 3.0))
			draw_polyline(pts, Color(1.0, 0.95, 0.85, 0.035), 10.0)
