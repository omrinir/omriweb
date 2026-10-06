extends RefCounted
# ============================================================
#  קישוטים לשלב 16 ("THE FLOOD") - אתר בנייה בשולי העיר, אחר הצהריים, גשם קל.
#    afternoon_sky   - שמיים מעוננים-חמימים, שמש נמוכה מאחורי עננים, קרני אור
#    far_city        - קו רקיע עירוני באובך + עגורנים רחוקים
#    skeletons       - שלדי בניינים מבטון (עמודים + תקרות + ברזלים), עגורן צריח עם וו מתנדנד
#    fence_layer     - גדר אתר בנייה עם ברזנט ושלטי סכנה
#    LightRain       - גשם דק ומלוכסן על המסך + התזות על הכביש
#    Scaffold        - פיגום פלדה (עמודים, אלכסונים, רשת) מאחורי שתי הקומות של השלב
#    Obstacle        - צינורות בטון / מחסום ניו ג'רזי / משטח לבנים (מוצק)
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func afternoon_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("6f7c8e"), Color("8e98a6"), Color("b7b4b0"), Color("dcb796"), Color("e9a974")])
	var sun := Vector2(v.x * 0.74, 420.0)
	for i in 5:   # קרני אור דרך העננים
		var a := -0.75 + float(i) * 0.32 + sin(t * 0.08 + float(i)) * 0.02
		var d := Vector2.from_angle(a - PI * 0.5)
		ci.draw_colored_polygon(PackedVector2Array([sun, sun + d.rotated(-0.06) * 900.0, sun + d.rotated(0.06) * 900.0]), Color(1.0, 0.85, 0.6, 0.045))
	for i in 4:
		ci.draw_circle(sun, 170.0 - float(i) * 36.0, Color(1.0, 0.78, 0.5, 0.06 + float(i) * 0.035))
	ci.draw_circle(sun, 34.0, Color(1.0, 0.9, 0.72, 0.85))
	Kit.clouds(ci, t * 9.0, v, t, 90.0, Color(0.55, 0.56, 0.62, 0.75), 5, 7.0)
	Kit.clouds(ci, t * 14.0 + 400.0, v, t, 190.0, Color(0.68, 0.64, 0.66, 0.55), 4, 5.0)
	Kit.birds(ci, v, t, 5, Color(0.2, 0.2, 0.22, 0.55), 4)


static func far_city(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 37 + 11)
		for i in 14:
			var w := r.randf_range(30.0, 70.0)
			var h := r.randf_range(60.0, 190.0)
			var bx := x + float(i) * 105.0 + r.randf_range(0.0, 30.0)
			ci.draw_rect(Rect2(bx, y - h, w, h), Color(0.47, 0.5, 0.58, 0.6))
			if r.randf() < 0.3:   # אנטנה
				ci.draw_line(Vector2(bx + w * 0.5, y - h), Vector2(bx + w * 0.5, y - h - 22.0), Color(0.47, 0.5, 0.58, 0.6), 1.5)
		var cx := x + r.randf_range(200.0, 1200.0)   # עגורן רחוק
		var ch := r.randf_range(200.0, 260.0)
		ci.draw_line(Vector2(cx, y), Vector2(cx, y - ch), Color(0.42, 0.44, 0.5, 0.65), 3.0)
		ci.draw_line(Vector2(cx - 50.0, y - ch), Vector2(cx + 170.0, y - ch), Color(0.42, 0.44, 0.5, 0.65), 2.5)
		ci.draw_line(Vector2(cx + 120.0, y - ch), Vector2(cx + 120.0 + sin(t * 0.5 + float(k)) * 4.0, y - ch + 70.0), Color(0.42, 0.44, 0.5, 0.5), 1.0)
	ci.draw_rect(Rect2(0, y, v.x, 200.0), Color(0.5, 0.52, 0.58, 0.55))
	ci.draw_rect(Rect2(0, y - 40.0, v.x, 60.0), Color(0.85, 0.75, 0.68, 0.18))   # אובך


static func skeletons(ci: CanvasItem, sc: float, _v: Vector2, y: float, t: float) -> void:
	var period := 1100.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + 4):
		var x := float(k) * period - sc
		var r := _rng(k * 53 + 3)
		var floors := r.randi_range(4, 7)
		var w := r.randf_range(240.0, 360.0)
		var fh := 52.0
		var c := Color(0.52, 0.5, 0.5)
		var c2 := Color(0.4, 0.39, 0.4)
		for f in floors:   # תקרות
			var fy := y - float(f + 1) * fh
			var ww := w if f < floors - 1 else w * r.randf_range(0.4, 0.8)
			ci.draw_rect(Rect2(x, fy, ww, 7.0), c)
			ci.draw_rect(Rect2(x, fy + 7.0, ww, 2.0), c2)
		var cols := int(w / 60.0)
		for i in cols + 1:   # עמודים
			var cx := x + float(i) * (w / float(cols))
			var top := y - float(floors) * fh + (fh if i > cols * 0.6 else 0.0)
			ci.draw_rect(Rect2(cx - 4.0, top, 8.0, y - top), c2)
			if i == cols:   # ברזלים בולטים למעלה
				for q in 3:
					ci.draw_line(Vector2(cx - 3.0 + float(q) * 3.0, top), Vector2(cx - 4.0 + float(q) * 3.5, top - 14.0), Color(0.35, 0.25, 0.2), 1.2)
		if r.randf() < 0.6:   # ברזנט כחול מתנופף
			var tx := x + r.randf_range(20.0, w - 80.0)
			var ty := y - float(r.randi_range(1, floors - 1)) * fh + 9.0
			var wave := sin(t * 2.0 + float(k)) * 4.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(tx, ty), Vector2(tx + 60.0, ty), Vector2(tx + 62.0 + wave, ty + 38.0), Vector2(tx + 2.0 + wave * 0.5, ty + 42.0)]), Color(0.25, 0.42, 0.62, 0.9))
		if k % 2 == 0:   # עגורן צריח עם וו מתנדנד
			var cx2 := x + w + 140.0
			var ch := float(floors) * fh + 120.0
			for s in int(ch / 20.0):
				var sy := y - float(s) * 20.0
				ci.draw_line(Vector2(cx2 - 6.0, sy), Vector2(cx2 + 6.0, sy - 20.0), Color(0.75, 0.55, 0.2), 1.2)
			ci.draw_line(Vector2(cx2 - 6.0, y), Vector2(cx2 - 6.0, y - ch), Color(0.82, 0.6, 0.2), 2.0)
			ci.draw_line(Vector2(cx2 + 6.0, y), Vector2(cx2 + 6.0, y - ch), Color(0.82, 0.6, 0.2), 2.0)
			ci.draw_rect(Rect2(cx2 - 90.0, y - ch - 8.0, 330.0, 8.0), Color(0.85, 0.62, 0.2))
			ci.draw_rect(Rect2(cx2 - 90.0, y - ch - 2.0, 40.0, 16.0), Color(0.4, 0.4, 0.42))   # משקל נגד
			var hx := cx2 + 170.0
			var sw := sin(t * 0.9 + float(k)) * 10.0
			var hook := Vector2(hx + sw, y - ch + 150.0)
			ci.draw_line(Vector2(hx, y - ch), hook, Color(0.2, 0.2, 0.2), 1.2)
			ci.draw_rect(Rect2(hook + Vector2(-16.0, 0.0), Vector2(32.0, 14.0)), Color(0.5, 0.45, 0.4))   # משטח תלוי


static func fence_layer(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 71 + 9)
		for i in 9:   # עמודי גדר + רשת
			var px := x + float(i) * 100.0
			ci.draw_line(Vector2(px, y), Vector2(px, y - 90.0), Color(0.3, 0.3, 0.32), 3.0)
			for q in 6:
				var gx := px + float(q) * 16.6
				ci.draw_line(Vector2(gx, y - 88.0), Vector2(gx + 16.0, y - 4.0), Color(0.35, 0.36, 0.38, 0.5), 0.8)
				ci.draw_line(Vector2(gx + 16.0, y - 88.0), Vector2(gx, y - 4.0), Color(0.35, 0.36, 0.38, 0.5), 0.8)
			if r.randf() < 0.45:   # ברזנט ירוק על הגדר
				var wave := sin(t * 1.6 + float(i)) * 2.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(px + 2.0, y - 84.0), Vector2(px + 98.0, y - 84.0), Vector2(px + 98.0 + wave, y - 20.0), Vector2(px + 2.0, y - 24.0)]), Color(0.2, 0.38, 0.28, 0.85))
			if r.randf() < 0.2:   # שלט סכנה
				var sp := Vector2(px + 30.0, y - 70.0)
				ci.draw_rect(Rect2(sp, Vector2(40.0, 26.0)), Color(0.95, 0.8, 0.15))
				ci.draw_rect(Rect2(sp, Vector2(40.0, 26.0)), Color(0.1, 0.1, 0.1), false, 1.4)
				ci.draw_colored_polygon(PackedVector2Array([sp + Vector2(20.0, 4.0), sp + Vector2(28.0, 21.0), sp + Vector2(12.0, 21.0)]), Color(0.1, 0.1, 0.1))
	Kit.ground_fade(ci, v, y)


# ---- גשם קל של אחר הצהריים: פסים דקים ומלוכסנים + התזות קטנות על הכביש ----
class LightRain extends Node2D:
	var floor_y := 630.0
	var amount := 150
	var _drops := []
	var _splash := []

	func _ready() -> void:
		for i in amount:
			_drops.append([randf() * 1400.0, randf() * 760.0, randf_range(700.0, 980.0), randf_range(9.0, 18.0), randf_range(0.18, 0.4)])

	func _process(delta: float) -> void:
		var vs := get_viewport_rect().size
		var gy: float = (get_viewport().get_canvas_transform() * Vector2(0.0, floor_y)).y
		for d in _drops:
			d[1] += d[2] * delta
			d[0] -= d[2] * 0.18 * delta
			if d[1] > minf(gy, vs.y) + randf_range(-6.0, 10.0) or d[0] < -20.0:
				if d[1] > gy - 20.0 and d[1] < vs.y and _splash.size() < 40:
					_splash.append([Vector2(d[0], gy + randf_range(-2.0, 6.0)), 0.0])
				d[1] = randf_range(-60.0, -5.0)
				d[0] = randf() * (vs.x + 160.0)
		for s in _splash:
			s[1] += delta
		_splash = _splash.filter(func(s): return s[1] < 0.25)
		queue_redraw()

	func _draw() -> void:
		for d in _drops:
			var p := Vector2(d[0], d[1])
			draw_line(p, p + Vector2(d[3] * 0.18, -d[3]), Color(0.8, 0.85, 0.92, d[4]), 1.0)
		for s in _splash:
			var k: float = s[1] / 0.25
			var c: Vector2 = s[0]
			draw_arc(c, 2.0 + 5.0 * k, PI, TAU, 6, Color(0.85, 0.9, 0.95, 0.5 * (1.0 - k)), 1.0)


# ---- פיגום פלדה מאחורי שתי הקומות: עמודים, אלכסונים, רשת בטיחות ----
class Scaffold extends Node2D:
	var w := 800.0
	var tiers: Array = [120.0, 240.0]
	var t2_span := Vector2(0.15, 0.85)   # איפה הקומה העליונה (יחסי לרוחב)
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var steel := Color("6a7078")
		var dark := Color("3a3e44")
		var h1: float = tiers[0]
		var h2: float = tiers[1]
		var bays := int(w / 100.0)
		for i in bays + 1:
			var x := float(i) * (w / float(bays))
			var on2 := x >= w * t2_span.x - 2.0 and x <= w * t2_span.y + 2.0
			var top := -(h2 + 40.0) if on2 else -(h1 + 40.0)
			draw_line(Vector2(x, 0.0), Vector2(x, top), dark, 4.0)
			draw_line(Vector2(x - 1.0, 0.0), Vector2(x - 1.0, top), steel, 2.0)
			draw_rect(Rect2(x - 6.0, -3.0, 12.0, 3.0), dark)   # בסיס
			if i < bays:
				var nx := float(i + 1) * (w / float(bays))
				draw_line(Vector2(x, 0.0), Vector2(nx, -h1), Color(steel, 0.8), 1.6)   # אלכסונים
				var n2 := nx >= w * t2_span.x - 2.0 and nx <= w * t2_span.y + 2.0
				if on2 and n2:
					draw_line(Vector2(x, -h1), Vector2(nx, -h2), Color(steel, 0.8), 1.6)
					draw_line(Vector2(x, -h2 - 34.0), Vector2(nx, -h2 - 34.0), steel, 2.0)   # מעקה
				draw_line(Vector2(x, -h1 - 34.0), Vector2(nx, -h1 - 34.0), Color(steel, 0.7 if not on2 else 0.0), 2.0)
		# רשת בטיחות כתומה על חלק מהפיגום
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var nx0 := w * r.randf_range(0.05, 0.4)
		var nw := w * r.randf_range(0.2, 0.35)
		draw_rect(Rect2(nx0, -h2 + 6.0, nw, h2 - h1 - 10.0), Color(0.95, 0.5, 0.15, 0.22))
		for q in int(nw / 8.0):
			draw_line(Vector2(nx0 + float(q) * 8.0, -h2 + 6.0), Vector2(nx0 + float(q) * 8.0, -h1 - 4.0), Color(0.95, 0.5, 0.15, 0.25), 0.8)


# ---- מכשולים מוצקים: צינורות בטון, מחסום ניו ג'רזי, משטח לבנים ----
class Obstacle extends Node2D:
	var kind := "pipes"
	var size := Vector2(100, 44)
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
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		match kind:
			"pipes":   # צינורות בטון שוכבים, ערימה
				var rr := size.y * 0.5
				var n := int(size.x / (rr * 2.0))
				for i in n:
					var c := Vector2(rr + float(i) * rr * 2.0, -rr)
					draw_circle(c, rr, Art.OUTLINE)
					draw_circle(c, rr - 1.5, Color("a8a49c"))
					draw_circle(c, rr * 0.62, Color("4a4844"))
					draw_circle(c, rr * 0.62, Color("8a8680"), false, 1.5)
					draw_arc(c, rr - 4.0, -2.4, -1.2, 8, Color(1, 1, 1, 0.3), 1.5)
			"jersey":   # מחסומי ניו ג'רזי עם פסים
				var bw := 56.0
				var n := maxi(int(size.x / bw), 1)
				for i in n:
					var x := float(i) * bw
					var poly := PackedVector2Array([Vector2(x, 0), Vector2(x + bw, 0), Vector2(x + bw - 8.0, -size.y * 0.35), Vector2(x + bw - 14.0, -size.y), Vector2(x + 14.0, -size.y), Vector2(x + 8.0, -size.y * 0.35)])
					Art.fill(self, poly, Color("c8c4bc"), Art.OUTLINE, 1.4)
					for q in 3:
						var sx := x + 16.0 + float(q) * 9.0
						draw_colored_polygon(PackedVector2Array([Vector2(sx, -size.y + 6.0), Vector2(sx + 5.0, -size.y + 6.0), Vector2(sx + 9.0, -size.y + 16.0), Vector2(sx + 4.0, -size.y + 16.0)]), Color("e04a2a"))
			_:   # משטח עץ עם לבנים / שקי מלט
				draw_rect(Rect2(0, -6.0, size.x, 6.0), Color("8a6a40"))
				draw_rect(Rect2(0, -6.0, size.x, 6.0), Art.OUTLINE, false, 1.0)
				var rows := int((size.y - 6.0) / 9.0)
				for row in rows:
					for i in int(size.x / 18.0):
						var b := Rect2(float(i) * 18.0 + (9.0 if row % 2 == 1 else 0.0) * 0.0, -6.0 - float(row + 1) * 9.0, 17.0, 8.0)
						draw_rect(b, Color("a84a32").darkened(r.randf() * 0.2))
						draw_rect(b, Color(0.2, 0.08, 0.05, 0.8), false, 0.8)
				draw_rect(Rect2(0, -size.y, size.x, size.y - 6.0), Color(0.75, 0.85, 0.9, 0.18))   # ניילון עוטף
