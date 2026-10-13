extends RefCounted
# ============================================================
#  קישוטים לשלב 31 ("FLOATING ISLANDS") - אגם טיטיקקה בזריחה: איי הקנים של האורוס (קנה טוטורה),
#  בקתות קנים, סירות קנים עם ראש פומה, תנורי חימר מעשנים, הקורדיירה ריאל המושלגת בצד השני של האגם.
#  המים רדודים (עד הברכיים) - אבל הם שלהם עכשיו.
#    titicaca_sky  - (רקע) זריחה: כחול עמוק -> לילך -> אפרסק, שמש עולה, עננים דקים
#    far_cordillera- (רקע) הרים מושלגים מעבר לאגם + ההשתקפות שלהם, שביל אור של השמש על המים
#    mid_islands   - (רקע) איים רחוקים: בקתות, מגדלי תצפית, סירות קנים, עשן בישול
#    near_reeds    - (רקע) קני טוטורה שמתנדנדים, אדוות
#    LakeGround    - (עולם) קרקעית האגם (מתחת לפני המים)
#    WaterFront    - (עולם, מעל השחקנים) פני המים השקופים: הרגליים בתוך המים, אדוות
#    Island        - (מוצק) אי קנים: שכבות קנים, בקתות, מתלה דגים, תנור מעשן (smoke). RottenPatch = קנים רקובים שנשברים
#    RottenPatch   - (מוצק -> בור, מלכודת) קנים כהים עם טחב. דורכים -> חורק ושוקע (SAG_T) -> נשבר: נופלים לבור מים,
#                    נזק 1 + מסתבכים (TANGLE_T). חוזר אחרי REGROW_T
#    Obstacle      - (מוצק + מחסה) "moored_boat" סירת קנים קשורה / "reed_bundles" ערמת קנים / "fish_crates" ארגזי דגים
#    LakeFX        - (מסך) ערפל בוקר נמוך על המים, ניצוצות אור
#  לשנות: ISL_H, WATER_Y, RottenPatch.SAG_T / TANGLE_T / REGROW_T.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const ISL_H := 36.0          # גובה האיים מעל קרקעית האגם
const WATER_Y := 18.0        # פני המים מעל הקרקעית
const REED := Color("c8a858")
const REED_D := Color("8a7034")
const REED_W := Color("5a4a2a")
const WATER := Color("2a5a6a")
const WATER_D := Color("163440")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)


static func _vn(t: float, s: int) -> float:
	var i := floori(t)
	var f := t - float(i)
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_h(i, s), _h(i + 1, s), f)


# מים מתיזים (טיפות + רסס)
static func splash(parent: Node, pos: Vector2, n := 6) -> void:
	Particles.burst(parent, pos, "drop", Vector2.UP, n)
	Particles.burst(parent, pos, "mist", Vector2.UP, maxi(1, n / 3))


# ---- זריחה מעל האגם ----
static func titicaca_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("1a2a5a"), Color("3a4a8a"), Color("8a7ab0"), Color("e0a088"), Color("f4c890")], 0.72)
	var sun := Vector2(v.x * 0.74, v.y * 0.66)
	for i in 5:
		ci.draw_circle(sun, 230.0 - float(i) * 42.0, Color(1.0, 0.8, 0.5, 0.05 + 0.03 * float(i)))
	ci.draw_circle(sun, 30.0, Color("fff2d0"))
	for i in 4:   # עננים דקים בצבעי זריחה
		var y := v.y * (0.14 + 0.09 * float(i))
		var x := fposmod(t * (3.0 + float(i)) + float(i) * 410.0, v.x + 900.0) - 450.0
		var c := Color("ffc0a0").lerp(Color("8a6a9a"), float(i % 2) * 0.6)
		ci.draw_colored_polygon(Art.ellipse(Vector2(x, y), 240.0, 7.0, 0.0, 14), Color(c, 0.4))
		ci.draw_colored_polygon(Art.ellipse(Vector2(x + 120.0, y + 6.0), 160.0, 5.0, 0.0, 12), Color(c, 0.3))


# ---- הקורדיירה ריאל מעבר לאגם + השתקפות + שביל אור ----
static func far_cordillera(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pts := PackedVector2Array()
	var refl := PackedVector2Array()
	var x := -20.0
	while x <= v.x + 20.0:
		var u := x + sc
		var hgt := (_vn(u / 260.0, 5) * 0.55 + (1.0 - absf(_vn(u / 110.0, 9) * 2.0 - 1.0)) * 0.45) * 150.0
		pts.append(Vector2(x, y - hgt))
		refl.append(Vector2(x, y + hgt * 0.45))
		x += 20.0
	var poly := pts.duplicate()
	poly.append(Vector2(v.x + 20.0, y))
	poly.append(Vector2(-20.0, y))
	ci.draw_colored_polygon(poly, Color("8a8ab0"))
	for i in pts.size() - 1:   # שלג
		var a := pts[i]
		var b := pts[i + 1]
		if y - a.y > 80.0 and y - b.y > 80.0:
			ci.draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, (y - b.y - 80.0) * 0.6), a + Vector2(0, (y - a.y - 80.0) * 0.6)]), Color("f4eef0"))
	# האגם
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("3a5a8a"))
	var rp := refl.duplicate()
	rp.append(Vector2(v.x + 20.0, y))
	rp.append(Vector2(-20.0, y))
	ci.draw_colored_polygon(rp, Color(0.6, 0.6, 0.78, 0.35))   # השתקפות ההרים
	for i in 6:   # פסי אור על המים
		ci.draw_rect(Rect2(0, y + 6.0 + float(i) * 14.0, v.x, 2.0), Color(1, 0.85, 0.7, 0.05))
	var sx := v.x * 0.74
	for i in 26:   # שביל השמש: ניצוצות קצרים מתחת לשמש
		var yy := y + 4.0 + float(i) * 5.0
		var ww := 8.0 + float(i) * 3.5
		var jx := sin(t * 2.0 + float(i) * 1.7) * ww * 0.5
		ci.draw_line(Vector2(sx - ww * 0.5 + jx, yy), Vector2(sx + ww * 0.3 + jx, yy), Color(1.0, 0.9, 0.7, 0.55 - float(i) * 0.018), 1.5)


# ---- איים רחוקים: בקתות, מגדלי תצפית, סירות, עשן ----
static func mid_islands(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var r := _rng(k * 131 + 3)
		var ix := x + r.randf_range(0.0, 300.0)
		var iw := r.randf_range(300.0, 480.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(ix, y), Vector2(ix + 14, y - 10), Vector2(ix + iw - 14, y - 10), Vector2(ix + iw, y)]), Color("b09050"))
		ci.draw_colored_polygon(Art.ellipse(Vector2(ix + iw * 0.5, y + 2.0), iw * 0.55, 4.0, 0.0, 14), Color(0.3, 0.25, 0.2, 0.35))   # השתקפות
		for h in 3:   # בקתות קנים
			var hx := ix + 40.0 + float(h) * (iw - 80.0) / 2.0 + r.randf_range(-20.0, 20.0)
			ci.draw_rect(Rect2(hx - 14, y - 32, 28, 22), Color("c8a860"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx - 18, y - 30), Vector2(hx, y - 46), Vector2(hx + 18, y - 30)]), Color("a08040"))
			ci.draw_rect(Rect2(hx - 4, y - 24, 8, 14), [Color("c02a4a"), Color("2a6ac0"), Color("e0a020")][h])
		if r.randf() < 0.6:   # מגדל תצפית
			var tx := ix + iw * 0.8
			ci.draw_line(Vector2(tx - 8, y - 10), Vector2(tx - 4, y - 70), Color("a08040"), 3.0)
			ci.draw_line(Vector2(tx + 8, y - 10), Vector2(tx + 4, y - 70), Color("a08040"), 3.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 10, y - 68), Vector2(tx, y - 84), Vector2(tx + 10, y - 68)]), Color("b09050"))
		var smx := ix + iw * 0.3   # עשן בישול (קווים גליים שקופים)
		for q in 5:
			var sy := y - 40.0 - float(q) * 16.0
			var wob := sin(t * 1.2 + float(q) * 0.9 + float(k)) * (3.0 + float(q) * 2.0)
			ci.draw_circle(Vector2(smx + wob + float(q) * 4.0, sy), 5.0 + float(q) * 2.5, Color(0.9, 0.88, 0.86, 0.16 - float(q) * 0.025))
		var bx := fposmod(x + r.randf_range(500.0, 800.0) + t * 6.0 * (1.0 if k % 2 == 0 else -1.0), period) + x   # סירת קנים
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 26, y + 14), Vector2(bx + 26, y + 14), Vector2(bx + 34, y + 2), Vector2(bx + 28, y + 6), Vector2(bx - 28, y + 6), Vector2(bx - 34, y + 2)]), Color("b8963e"))
		ci.draw_line(Vector2(bx + 6, y + 6), Vector2(bx + 6, y - 20), Color("5a4a3a"), 1.5)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx + 6, y - 20), Vector2(bx + 22, y - 2), Vector2(bx + 6, y - 2)]), Color("e8e0d0"))


# ---- קני טוטורה מתנדנדים + אדוות ----
static func near_reeds(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	ci.draw_rect(Rect2(0, y - 4.0, v.x, v.y - y + 4.0), Color("2e5070"))
	for i in 5:   # אדוות
		var yy := y + 6.0 + float(i) * 12.0
		var ox := fposmod(-sc * 0.5 + float(i) * 70.0 + t * 8.0, 160.0)
		var x := -ox
		while x < v.x:
			ci.draw_line(Vector2(x, yy), Vector2(x + 50.0, yy), Color(0.8, 0.9, 1.0, 0.12), 1.5)
			x += 160.0
	var period := 600.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var r := _rng(k * 71 + 9)
		for c in 3:   # גושי קנים
			var cx := x + r.randf_range(0.0, period)
			var n := r.randi_range(8, 13)
			for q in n:
				var px := cx + float(q) * 4.0 - float(n) * 2.0
				var hgt := r.randf_range(50.0, 90.0)
				var bend := sin(t * 1.4 + px * 0.03) * 4.0
				var top := Vector2(px + bend + float(q - n / 2) * 1.2, y - hgt)
				ci.draw_line(Vector2(px, y + 2.0), top, Color("5a7a3a") if q % 3 else Color("7a8a3a"), 1.8)
				if q % 3 == 0:
					ci.draw_colored_polygon(Art.ellipse(top + Vector2(0, 6), 1.8, 5.0, 0.1, 8), Color("6a4a2a"))


# ---- קרקעית האגם ----
class LakeGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s31_decor.gd")
		draw_rect(Rect2(0, -S.WATER_Y, w, S.WATER_Y), S.WATER)   # המים מאחורי השחקנים
		for i in 5:   # עומק: כהה יותר למטה
			draw_rect(Rect2(0, float(i) * depth / 5.0, w, depth / 5.0 + 1.0), S.WATER.lerp(S.WATER_D, float(i + 1) / 5.0))
		draw_rect(Rect2(0, 0, w, 3.0), Color("4a5a40"))   # קרקעית בוצית
		for i in int(w / 60.0):   # שורשי קנים וצמחי מים
			var x := r.randf_range(0.0, w)
			draw_line(Vector2(x, 2), Vector2(x + r.randf_range(-4, 4), r.randf_range(14.0, 34.0)), Color(0.2, 0.3, 0.2, 0.6), 1.5)
		for i in int(w / 120.0):   # אבנים
			draw_colored_polygon(Art.ellipse(Vector2(r.randf_range(0.0, w), r.randf_range(12.0, depth - 10.0)), r.randf_range(4.0, 8.0), r.randf_range(3.0, 5.0), 0.0, 8), Color(0.12, 0.2, 0.22))


# ---- פני המים מעל השחקנים (הרגליים במים) ----
class WaterFront extends Node2D:
	var w := 1024.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0.0), w * 0.5 + 100.0):
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s31_decor.gd")
		draw_rect(Rect2(0, -S.WATER_Y, w, S.WATER_Y + 3.0), Color(0.16, 0.36, 0.44, 0.5))
		var pts := PackedVector2Array()
		var x := 0.0
		while x <= w:
			pts.append(Vector2(x, -S.WATER_Y + sin(x * 0.05 + _t * 2.2) * 1.2))
			x += 16.0
		draw_polyline(pts, Color(0.85, 0.95, 1.0, 0.6), 1.5)
		for i in int(w / 90.0):   # ניצוצות אור
			var gx := fposmod(float(i) * 91.0 + _t * 12.0, w)
			draw_line(Vector2(gx, -S.WATER_Y + 4.0), Vector2(gx + 10.0, -S.WATER_Y + 4.0), Color(1, 0.95, 0.85, 0.25 + 0.2 * sin(_t * 3.0 + float(i))), 1.0)


# ---- אי קנים (מוצק). huts = כמה בקתות, stove = תנור מעשן, rack = מתלה דגים ----
class Island extends Node2D:
	var w := 400.0
	var seed_v := 0
	var huts := 1
	var stove := false
	var rack := false
	var tower := false
	var gaps := []           # [x0, x1] של קנים רקובים (RottenPatch נפרד) - לא מוצק שם
	var _puff := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("islands")
		add_to_group("cover")
		var S := preload("res://effects/s31_decor.gd")
		var segs := []
		var x := 0.0
		for g in gaps:
			segs.append([x, float(g[0])])
			x = float(g[1])
		segs.append([x, w])
		for s in segs:
			if float(s[1]) - float(s[0]) < 4.0:
				continue
			var body := StaticBody2D.new()
			body.collision_layer = 1
			body.add_to_group("no_outline")
			var cs := CollisionShape2D.new()
			var sh := RectangleShape2D.new()
			sh.size = Vector2(float(s[1]) - float(s[0]), S.ISL_H)
			cs.shape = sh
			cs.position = Vector2((float(s[0]) + float(s[1])) * 0.5, -S.ISL_H * 0.5)
			body.add_child(cs)
			add_child(body)

	func cover_rect() -> Rect2:
		var S := preload("res://effects/s31_decor.gd")
		return Rect2(global_position + Vector2(0.0, -S.ISL_H), Vector2(w, S.ISL_H))

	func top_y() -> float:
		var S := preload("res://effects/s31_decor.gd")
		return global_position.y - S.ISL_H

	func has_x(x: float, margin := 0.0) -> bool:
		return x > global_position.x - margin and x < global_position.x + w + margin

	func _process(delta: float) -> void:
		if not stove:
			return
		_puff -= delta
		if _puff <= 0.0 and Art.on_screen(self, global_position + Vector2(w * 0.25, -60.0), 200.0):
			_puff = 0.28
			Particles.burst(get_parent(), global_position + Vector2(w * 0.25 + randf_range(-3, 3), -preload("res://effects/s31_decor.gd").ISL_H - 30.0), "smoke", Vector2(0.15, -1.0), 1)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s31_decor.gd")
		var H := S.ISL_H
		# בקתות (מאחור)
		for i in huts:
			var hx := w * (0.18 + 0.64 * (float(i) + 0.5) / float(maxi(huts, 1))) + r.randf_range(-20.0, 20.0)
			var hw := r.randf_range(52.0, 66.0)
			var hh := r.randf_range(40.0, 50.0)
			var base := -H
			Art.fill_shaded(self, PackedVector2Array([Vector2(hx - hw * 0.5, base), Vector2(hx + hw * 0.5, base), Vector2(hx + hw * 0.5, base - hh), Vector2(hx - hw * 0.5, base - hh)]), Color("c8aa62"), 0.12, 0.3, Art.OUTLINE, 1.2)
			for q in int(hw / 5.0):   # קנים אנכיים בקירות
				draw_line(Vector2(hx - hw * 0.5 + 2.0 + float(q) * 5.0, base - 1.0), Vector2(hx - hw * 0.5 + 2.0 + float(q) * 5.0, base - hh + 2.0), Color(0.45, 0.35, 0.15, 0.35), 1.0)
			Art.fill(self, PackedVector2Array([Vector2(hx - hw * 0.62, base - hh + 2.0), Vector2(hx, base - hh - 30.0), Vector2(hx + hw * 0.62, base - hh + 2.0)]), Color("a8873c"), Art.OUTLINE, 1.2)
			for q in 6:
				draw_line(Vector2(hx - hw * 0.55 + float(q) * hw * 0.2, base - hh + 1.0), Vector2(hx, base - hh - 28.0), Color(0.4, 0.3, 0.12, 0.35), 1.0)
			var dc: Color = [Color("c0264a"), Color("2a6ac0"), Color("e09a20"), Color("2a9a5a")][r.randi() % 4]
			draw_rect(Rect2(hx - 8, base - 26, 16, 26), dc)   # וילון אריג בדלת
			for q in 3:
				draw_line(Vector2(hx - 8, base - 22.0 + float(q) * 7.0), Vector2(hx + 8, base - 22.0 + float(q) * 7.0), Color(1, 1, 1, 0.4), 1.5)
		if tower:   # מגדל תצפית מקנים בצורת דג
			var tx := w * 0.86
			for sgn in [-1.0, 1.0]:
				draw_line(Vector2(tx + sgn * 12.0, -H), Vector2(tx + sgn * 5.0, -H - 110.0), Color("a8873c"), 5.0)
			for q in 5:
				draw_line(Vector2(tx - 11.0 + float(q) * 0.5, -H - 20.0 - float(q) * 20.0), Vector2(tx + 11.0 - float(q) * 0.5, -H - 20.0 - float(q) * 20.0), Color("8a6a2a"), 2.0)
			Art.fill(self, PackedVector2Array([Vector2(tx - 16, -H - 106), Vector2(tx, -H - 128), Vector2(tx + 16, -H - 106)]), Color("b8963e"), Art.OUTLINE, 1.2)
		if rack:   # מתלה דגים מיובשים
			var rx := w * 0.62
			draw_line(Vector2(rx, -H), Vector2(rx, -H - 40), Color("6a5030"), 2.5)
			draw_line(Vector2(rx + 60, -H), Vector2(rx + 60, -H - 40), Color("6a5030"), 2.5)
			draw_line(Vector2(rx, -H - 36), Vector2(rx + 60, -H - 36), Color("4a3a2a"), 1.2)
			for q in 6:
				var fx := rx + 6.0 + float(q) * 9.0
				draw_colored_polygon(Art.ellipse(Vector2(fx, -H - 28), 2.5, 7.0, 0.0, 8), Color("b8b0a0"))
		if stove:   # תנור חימר
			var sx := w * 0.25
			Art.fill_shaded(self, PackedVector2Array([Vector2(sx - 14, -H), Vector2(sx + 14, -H), Vector2(sx + 10, -H - 22), Vector2(sx - 10, -H - 22)]), Color("9a5a3a"), 0.12, 0.35, Art.OUTLINE, 1.2)
			draw_circle(Vector2(sx, -H - 8), 5.0, Color("2a120a"))
			Art.glow(self, Vector2(sx, -H - 8), 20.0, Color(1.0, 0.5, 0.2, 0.3))
			draw_circle(Vector2(sx, -H - 8), 3.0, Color(1.0, 0.6, 0.2))
		# גוף האי: שכבות קנים
		var body := PackedVector2Array([Vector2(-8, 4), Vector2(-14, -H * 0.4), Vector2(-6, -H), Vector2(w + 6, -H), Vector2(w + 14, -H * 0.4), Vector2(w + 8, 4)])
		draw_colored_polygon(body, S.REED_D)
		var rows := 7
		for i in rows:
			var yy := -H + 2.0 + float(i) * (H + 2.0) / float(rows)
			var c: Color = S.REED.lerp(S.REED_W, float(i) / float(rows - 1))
			var x := -8.0 + float(i % 2) * 10.0
			while x < w + 4.0:   # חבילות קנים קשורות
				var bw := r.randf_range(26.0, 42.0)
				draw_colored_polygon(Art.ellipse(Vector2(x + bw * 0.5, yy), bw * 0.55, 3.2, 0.0, 10), c)
				draw_line(Vector2(x + bw * 0.5, yy - 3.0), Vector2(x + bw * 0.5, yy + 3.0), Color(0.3, 0.2, 0.1, 0.5), 1.0)
				x += bw
		for i in int(w / 6.0):   # קנים טריים למעלה
			var x := float(i) * 6.0 + r.randf_range(0.0, 4.0)
			draw_line(Vector2(x, -H), Vector2(x + r.randf_range(-3.0, 3.0), -H - r.randf_range(2.0, 6.0)), Color("e0c878"), 1.0)


# ---- קנים רקובים: נראים כמעט כמו קנים רגילים (כהים, רטובים, טחב). דורכים -> חורקים ושוקעים (SAG_T) ->
#      נשברים: נופלים לבור מים בתוך האי, נזק 1 + מסתבכים בקנים (TANGLE_T: איטי, כוונת רועדת). חוזרים אחרי REGROW_T ----
class RottenPatch extends Node2D:
	const SAG_T := 0.45
	const TANGLE_T := 1.5
	const REGROW_T := 7.0
	var w := 60.0
	var broken := false
	var breaks := 0              # לבדיקות
	var _stand := 0.0
	var _t := 0.0
	var _creak := false
	var _seed := 0
	var _body: StaticBody2D
	var _cs: CollisionShape2D

	func _ready() -> void:
		z_index = 2
		_seed = randi()
		var S := preload("res://effects/s31_decor.gd")
		_body = StaticBody2D.new()
		_body.collision_layer = 1
		_body.add_to_group("no_outline")
		_cs = CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(w, S.ISL_H)
		_cs.shape = sh
		_cs.position = Vector2(w * 0.5, -S.ISL_H * 0.5)
		_body.add_child(_cs)
		add_child(_body)

	func _physics_process(delta: float) -> void:
		var S := preload("res://effects/s31_decor.gd")
		_t += delta
		var pl := get_tree().get_first_node_in_group("player")
		if broken:
			if _t >= REGROW_T and (pl == null or not Rect2(global_position + Vector2(-10, -S.ISL_H - 60.0), Vector2(w + 20, S.ISL_H + 60.0)).intersects(pl.body_rect())):
				broken = false
				_cs.set_deferred("disabled", false)
				queue_redraw()
			elif Engine.get_physics_frames() % 4 == 0 and Art.on_screen(self, global_position):
				queue_redraw()
			return
		var on: bool = pl != null and not pl.dead and pl.is_on_floor() and absf(pl.global_position.y - (global_position.y - S.ISL_H)) < 4.0 and pl.global_position.x > global_position.x + 2.0 and pl.global_position.x < global_position.x + w - 2.0
		if on:
			if _stand == 0.0:   # חריקה = אזהרה
				Sfx.play("s31_creak", global_position + Vector2(w * 0.5, -S.ISL_H), 0.0, 0.15, 2)
				Particles.burst(get_parent(), global_position + Vector2(w * 0.5, -S.ISL_H), "leaf", Vector2.UP, 3)
			_stand += delta
			queue_redraw()
			if _stand > SAG_T:
				_break(pl)
		elif _stand > 0.0:
			_stand = maxf(_stand - delta * 2.0, 0.0)
			queue_redraw()

	func _break(pl: Node) -> void:
		var S := preload("res://effects/s31_decor.gd")
		broken = true
		breaks += 1
		_stand = 0.0
		_t = 0.0
		_cs.set_deferred("disabled", true)
		Sfx.play("s31_creak", global_position + Vector2(w * 0.5, -S.ISL_H), 4.0, 0.1, 2, 0.7)
		Particles.burst(get_parent(), global_position + Vector2(w * 0.5, -S.ISL_H), "leaf", Vector2.UP, 12)
		S.splash(get_parent(), global_position + Vector2(w * 0.5, -S.WATER_Y), 10)
		if pl != null:
			pl.hurt(1, Vector2(0.0, 0.3))   # נופלים על קנים שבורים
			pl._daze_t = maxf(float(pl._daze_t), TANGLE_T)   # מסתבכים בקנים
			if pl.has_method("_say"):
				pl._say("ROTTEN REEDS! TANGLED!", Color("e0c070"))
		queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s31_decor.gd")
		var H := S.ISL_H
		var r := RandomNumberGenerator.new()
		r.seed = _seed
		if broken:   # בור מים בתוך האי: מים כהים, קנים שבורים בולטים מהשפות, שברים צפים
			draw_rect(Rect2(0, -H, w, H + 4.0), Color("2a2414"))
			var wy := -S.WATER_Y + sin(_t * 3.0) * 1.0
			draw_rect(Rect2(0, wy, w, S.WATER_Y + 4.0), S.WATER)
			draw_line(Vector2(0, wy), Vector2(w, wy), Color(0.8, 0.9, 1.0, 0.6), 1.5)
			for q in 4:   # שברי קנים צפים
				var fx := fposmod(float(q) * 17.0 + _t * 6.0 * (1.0 if q % 2 == 0 else -1.0), w - 12.0) + 6.0
				draw_line(Vector2(fx - 6, wy - 1), Vector2(fx + 6, wy + 1), S.REED_D, 2.0)
			for e in [0.0, w]:   # קצוות שבורים
				var sgn := 1.0 if e == 0.0 else -1.0
				for q in 5:
					var yy := -H + 2.0 + float(q) * 6.0
					draw_line(Vector2(e, yy), Vector2(e + sgn * r.randf_range(5.0, 11.0), yy + r.randf_range(2.0, 6.0)), S.REED_W if q % 2 else S.REED_D, 2.0)
			return
		# שלם: נראה כמו האי אבל כהה ורטוב, עם טחב. שוקע כשדורכים עליו
		var sag := 7.0 * clampf(_stand / SAG_T, 0.0, 1.0)
		var top := PackedVector2Array()
		for q in 9:
			var u := float(q) / 8.0
			top.append(Vector2(u * w, -H + sin(u * PI) * sag))
		var body := top.duplicate()
		body.append(Vector2(w, 4))
		body.append(Vector2(0, 4))
		draw_colored_polygon(body, Color("7a6432"))
		for i in 6:   # שכבות קנים כהות
			var yy := -H + 4.0 + float(i) * 6.0
			var x := float(i % 2) * 6.0
			while x < w - 2.0:
				var bw := r.randf_range(14.0, 22.0)
				draw_colored_polygon(Art.ellipse(Vector2(x + bw * 0.5, yy + sin(clampf((x + bw * 0.5) / w, 0.0, 1.0) * PI) * sag * (1.0 - float(i) / 6.0)), bw * 0.55, 2.6, 0.0, 8), Color("6a5428").lerp(S.REED_W, float(i) / 6.0))
				x += bw
		draw_polyline(top, Color("9a8040"), 2.0)
		for q in 3:   # כתמי טחב / ריקבון (הרמז)
			var mx := r.randf_range(8.0, w - 8.0)
			draw_colored_polygon(Art.ellipse(Vector2(mx, -H + 3.0 + sin(mx / w * PI) * sag), r.randf_range(4.0, 7.0), 1.6, 0.0, 8), Color(0.25, 0.35, 0.18, 0.8))
		if _stand > 0.0:   # סדקים
			for q in 3:
				var cx := w * (0.25 + 0.25 * float(q))
				draw_line(Vector2(cx, -H + sin(cx / w * PI) * sag), Vector2(cx + r.randf_range(-4.0, 4.0), -H + 10.0), Color(0.15, 0.1, 0.05, 0.9), 1.4)


# ---- מכשולים במים ----
class Obstacle extends Node2D:
	var kind := "moored_boat"
	var size := Vector2(90, 40)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		if size.y >= 30.0:
			add_to_group("cover")
		add_to_group("lake_obstacles")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)
		z_index = 2

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var w := size.x
		var h := size.y
		match kind:
			"moored_boat":   # סירת קנים עם ראש פומה
				var hull := PackedVector2Array([Vector2(6, 0), Vector2(w - 6, 0), Vector2(w + 4, -h * 0.55), Vector2(w - 2, -h * 0.5), Vector2(w - 10, -h * 0.25), Vector2(10, -h * 0.25), Vector2(2, -h * 0.5), Vector2(-4, -h * 0.55)])
				Art.fill_shaded(self, hull, Color("c0a050"), 0.15, 0.4, Art.OUTLINE, 1.5)
				for q in 4:
					draw_line(Vector2(8, -h * (0.05 + 0.05 * float(q))), Vector2(w - 8, -h * (0.05 + 0.05 * float(q))), Color(0.4, 0.3, 0.1, 0.4), 1.2)
				var head := Vector2(w + 2, -h * 0.85)   # ראש פומה מקנים
				draw_line(Vector2(w - 2, -h * 0.5), head + Vector2(-2, 6), Color("b09040"), 6.0)
				Art.fill(self, PackedVector2Array([head + Vector2(-8, 4), head + Vector2(-4, -6), head + Vector2(2, -8), head + Vector2(8, -4), head + Vector2(10, 2), head + Vector2(2, 6)]), Color("c8a858"), Art.OUTLINE, 1.2)
				draw_circle(head + Vector2(3, -3), 1.4, Color("2a1a0a"))
				draw_line(Vector2(w * 0.4, -h * 0.25), Vector2(w * 0.4, -h - 30.0), Color("5a4030"), 2.0)   # תורן עם מפרש קנים
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.4, -h - 28.0), Vector2(w * 0.4 + 30.0, -h * 0.4), Vector2(w * 0.4, -h * 0.4)]), Color("d8c070"))
			"reed_bundles":   # ערמת חבילות קנים קשורות
				for row in 3:
					var n := 3 - row
					for q in n:
						var c := Vector2(w * (0.5 - 0.17 * float(n - 1) + 0.34 * float(q)), -h * (0.18 + 0.32 * float(row)))
						Art.fill_shaded(self, Art.ellipse(c, w * 0.18, h * 0.17, 0.0, 12), Color("c8a858").darkened(r.randf_range(0.0, 0.2)), 0.2, 0.35, Art.OUTLINE, 1.2)
						draw_line(c + Vector2(0, -h * 0.17), c + Vector2(0, h * 0.17), Color("6a4a2a"), 1.5)
			_:   # ארגזי דגים
				for q in 2:
					var bx := float(q) * w * 0.5
					Art.fill_shaded(self, PackedVector2Array([Vector2(bx + 2, 0), Vector2(bx + w * 0.5 - 2, 0), Vector2(bx + w * 0.5 - 2, -h * (0.9 - 0.2 * float(q))), Vector2(bx + 2, -h * (0.9 - 0.2 * float(q)))]), Color("6a7a8a"), 0.15, 0.35, Art.OUTLINE, 1.2)
					for f in 3:
						draw_colored_polygon(Art.ellipse(Vector2(bx + 10.0 + float(f) * 9.0, -h * (0.9 - 0.2 * float(q)) + 2.0), 5.0, 2.2, 0.3, 8), Color("c0c8c8"))


# ---- ערפל בוקר על המים + ניצוצות (מסך) ----
class LakeFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		for i in 5:   # רצועות ערפל נמוכות שזזות לאט
			var y := vp.y * (0.7 + 0.05 * float(i))
			var x := fposmod(_t * (10.0 + float(i) * 4.0) + float(i) * 300.0, vp.x + 700.0) - 350.0
			draw_colored_polygon(Art.ellipse(Vector2(x, y), 380.0, 22.0, 0.0, 16), Color(1.0, 0.95, 0.9, 0.07))
		draw_rect(Rect2(Vector2.ZERO, vp), Color(1.0, 0.8, 0.6, 0.04))   # אור זריחה חם
