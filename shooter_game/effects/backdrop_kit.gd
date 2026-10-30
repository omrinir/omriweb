extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  BACKDROP KIT - פונקציות ציור מוכנות לרקעים (סטטיות, בלי מצב).
#  כל פונקציה מקבלת ci (ה-CanvasItem שמצייר), scroll (מהשכבה) ו-vp (גודל מסך).
#  האקראיות דטרמיניסטית לפי מספר "אריח" - כך שהרקע לא מהבהב כשזזים.
# ============================================================


static func _rng(seed_v: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	return r


# שמיים: מעבר צבעים (רשימת צבעים מלמעלה למטה)
static func gradient_sky(ci: CanvasItem, vp: Vector2, cols: Array, bottom := 0.85) -> void:
	var n := cols.size()
	var steps := 24
	for i in steps:
		var k := float(i) / float(steps - 1)
		var f := k * float(n - 1)
		var a := int(floor(f))
		var b := mini(a + 1, n - 1)
		var c: Color = (cols[a] as Color).lerp(cols[b], f - float(a))
		DrawBatch.rect(ci, Rect2(0, vp.y * bottom * k, vp.x, vp.y * bottom / float(steps - 1) + 1.0), c)
	DrawBatch.rect(ci, Rect2(0, vp.y * bottom, vp.x, vp.y * (1.0 - bottom)), cols[n - 1])


# קו רקיע של בניינים. base_y = איפה הבניינים "עומדים". windows = הסתברות לחלון דולק
static func skyline(ci: CanvasItem, scroll: float, vp: Vector2, base_y: float, col: Color, seed_v: int,
		w_range := Vector2(60, 140), h_range := Vector2(120, 320), windows := 0.0, win_col := Color(1.0, 0.75, 0.4), t := 0.0, broken := 0.3) -> void:
	var tile := 900.0
	var start := int(floor(scroll / tile)) - 1
	for ti in range(start, start + int(vp.x / tile) + 3):
		var rng := _rng(seed_v * 7919 + ti * 104729)
		var x := float(ti) * tile - scroll
		var end := x + tile
		while x < end:
			var w := rng.randf_range(w_range.x, w_range.y)
			var h := rng.randf_range(h_range.x, h_range.y)
			var top := base_y - h
			var pts := PackedVector2Array([Vector2(x, base_y), Vector2(x, top), Vector2(x + w, top), Vector2(x + w, base_y)])
			if rng.randf() < broken:   # בניין הרוס: גג שבור
				var bx := rng.randf_range(0.3, 0.7) * w
				pts = PackedVector2Array([Vector2(x, base_y), Vector2(x, top + rng.randf_range(0, 30)), Vector2(x + bx * 0.6, top + rng.randf_range(10, 50)),
					Vector2(x + bx, top + rng.randf_range(40, 90)), Vector2(x + w * 0.8, top + rng.randf_range(0, 30)), Vector2(x + w, top + rng.randf_range(20, 60)), Vector2(x + w, base_y)])
			DrawBatch.colored_polygon(ci, pts, col)
			if rng.randf() < 0.3:   # אנטנה / מגדל מים
				DrawBatch.line(ci, Vector2(x + w * 0.5, top), Vector2(x + w * 0.5, top - rng.randf_range(15, 45)), col, 2.0)
			if windows > 0.0:
				var wy := top + 12.0
				while wy < base_y - 14.0:
					var wx := x + 8.0
					while wx < x + w - 10.0:
						var r := rng.randf()
						if r < windows:
							var flick := 1.0 if r > windows * 0.15 else (0.4 + 0.6 * float(int(t * 7.0 + wx) % 3 != 0))   # חלק מהחלונות מהבהבים
							DrawBatch.rect(ci, Rect2(wx, wy, 5, 7), Color(win_col, win_col.a * flick))
						wx += 12.0
					wy += 16.0
			x += w + rng.randf_range(4.0, 30.0)


# עמוד עשן שעולה (מונפש)
static func smoke_column(ci: CanvasItem, base: Vector2, t: float, height := 260.0, col := Color(0.12, 0.1, 0.1, 0.4), drift := 60.0) -> void:
	for i in 10:   # כתמים רכים (היו עיגולים חדים שנראו כמו בועות)
		var k := fmod(float(i) / 10.0 + t * 0.06, 1.0)
		var p := base + Vector2(k * drift + sin(k * 6.0 + t * 0.5) * 12.0, -k * height)
		soft_glow(ci, p, 24.0 + k * 75.0, Color(col, minf(col.a * 1.7 * (1.0 - k) * clampf(k * 8.0 + 0.3, 0.0, 1.0), 1.0)))


# זוהר של שריפה רחוקה
static func fire_glow(ci: CanvasItem, p: Vector2, t: float, r := 70.0, seed_v := 0) -> void:
	var fl := 0.8 + 0.2 * sin(t * 7.0 + float(seed_v)) + 0.1 * sin(t * 17.0 + float(seed_v) * 2.0)
	soft_glow(ci, p, r * 1.2, Color(1.0, 0.45, 0.12, 0.3 * fl))   # הילה רכה (היו 4 טבעות)
	for i in 5:
		var fx := (float(i) - 2.0) * r * 0.12
		var h := r * 0.35 * (0.6 + 0.4 * sin(t * 9.0 + float(i) * 1.7 + float(seed_v)))
		DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(fx - 6, 0), p + Vector2(fx, -h), p + Vector2(fx + 6, 0)]), Color(1.0, 0.55, 0.15, 0.7))


# עננים שזזים לבד (t)
static func clouds(ci: CanvasItem, scroll: float, vp: Vector2, t: float, y: float, col: Color, seed_v := 1, speed := 8.0) -> void:
	var rng := _rng(seed_v)
	for i in 7:
		var cx := fposmod(rng.randf_range(0, 2000) - scroll - t * speed * rng.randf_range(0.6, 1.4), vp.x + 600.0) - 300.0
		var cy := y + rng.randf_range(-40, 40)
		var s := rng.randf_range(0.7, 1.5)
		for k in 5:
			DrawBatch.circle(ci, Vector2(cx + float(k) * 34.0 * s, cy + sin(float(k) * 1.7) * 8.0), (26.0 + float(k % 3) * 8.0) * s, col)


# מסוק שעובר ברקע (צללית + אור מהבהב + זרקור)
static func helicopter(ci: CanvasItem, vp: Vector2, t: float, period := 38.0, y := 140.0, col := Color(0.05, 0.05, 0.07, 0.9), spot := true) -> void:
	var k := fmod(t / period, 1.0)
	if k > 0.6:
		return
	var x := lerpf(vp.x + 120.0, -160.0, k / 0.6)
	var p := Vector2(x, y + sin(t * 1.3) * 6.0)
	if spot:   # זרקור
		DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(-4, 6), p + Vector2(4, 6), p + Vector2(60 + sin(t) * 40.0, vp.y * 0.7), p + Vector2(-40 + sin(t) * 40.0, vp.y * 0.7)]), Color(0.9, 0.95, 1.0, 0.05))
	DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(-22, -6), p + Vector2(14, -8), p + Vector2(22, 0), p + Vector2(14, 6), p + Vector2(-18, 5)]), col)
	DrawBatch.line(ci, p + Vector2(-20, -1), p + Vector2(-52, -4), col, 3.0)
	DrawBatch.line(ci, p + Vector2(-52, -10), p + Vector2(-52, 2), col, 2.0)
	var blade := 40.0 * absf(sin(t * 30.0))
	DrawBatch.line(ci, p + Vector2(-blade, -12), p + Vector2(blade, -12), Color(col, 0.6), 1.5)
	if int(t * 2.0) % 2 == 0:
		DrawBatch.circle(ci, p + Vector2(18, 2), 2.0, Color(1.0, 0.2, 0.2, 0.9))


# להקת ציפורים / עטלפים
static func birds(ci: CanvasItem, vp: Vector2, t: float, seed_v := 3, col := Color(0.05, 0.05, 0.06, 0.8), n := 7) -> void:
	var rng := _rng(seed_v)
	var period := 26.0
	var k := fmod(t / period + rng.randf(), 1.0)
	var base := Vector2(lerpf(-100.0, vp.x + 100.0, k), 110.0 + rng.randf_range(0, 120))
	for i in n:
		var o := Vector2(rng.randf_range(-60, 60), rng.randf_range(-25, 25))
		var fl := sin(t * 9.0 + float(i)) * 4.0
		var p := base + o
		DrawBatch.polyline(ci, PackedVector2Array([p + Vector2(-6, fl), p, p + Vector2(6, fl)]), col, 1.5)


# פיצוץ רחוק (הבזק + פטרייה שמתפזרת). קורה כל period שניות
static func distant_explosions(ci: CanvasItem, scroll: float, vp: Vector2, t: float, horizon_y: float, period := 7.0, seed_v := 5) -> void:
	var idx := int(t / period)
	var k := fmod(t, period) / period
	if k > 0.35:
		return
	var rng := _rng(seed_v * 31 + idx)
	var x := fposmod(rng.randf_range(0, 3000) - scroll, vp.x + 200.0) - 100.0
	var p := Vector2(x, horizon_y)
	var e := k / 0.35
	DrawBatch.circle(ci, p, 20.0 + e * 70.0, Color(1.0, 0.6, 0.2, 0.25 * (1.0 - e)))
	DrawBatch.circle(ci, p + Vector2(0, -e * 40.0), 10.0 + e * 40.0, Color(0.25, 0.2, 0.18, 0.5 * (1.0 - e)))
	if e < 0.15:
		DrawBatch.rect(ci, Rect2(0, 0, vp.x, vp.y), Color(1.0, 0.7, 0.4, 0.05 * (1.0 - e / 0.15)))


# הבזק ברק על כל המסך (מחזיר true אם יש הבזק עכשיו - כדי להשמיע רעם)
static func lightning(ci: CanvasItem, vp: Vector2, t: float, period := 9.0, seed_v := 9) -> bool:
	var idx := int(t / period)
	var rng := _rng(seed_v + idx * 13)
	var at := rng.randf_range(0.0, period * 0.6)
	var k := fmod(t, period) - at
	if k < 0.0 or k > 0.35:
		return false
	var a := 0.35 * (1.0 - k / 0.35) * (1.0 if fmod(k, 0.12) < 0.07 else 0.4)
	DrawBatch.rect(ci, Rect2(Vector2.ZERO, vp), Color(0.75, 0.8, 1.0, a))
	# ברק עצמו
	var x := rng.randf_range(vp.x * 0.1, vp.x * 0.9)
	var pts := PackedVector2Array([Vector2(x, 0)])
	var y := 0.0
	while y < vp.y * 0.45:
		y += rng.randf_range(20, 45)
		x += rng.randf_range(-25, 25)
		pts.append(Vector2(x, y))
	DrawBatch.polyline(ci, pts, Color(0.9, 0.95, 1.0, a * 2.5), 2.0)
	return true


# שכבת "רצפה" כהה בתחתית (כדי שהמעבר לרצפת המשחק יהיה רך)
static func ground_fade(ci: CanvasItem, vp: Vector2, from_y := 560.0) -> void:
	for i in 6:
		DrawBatch.rect(ci, Rect2(0, from_y + float(i) * 12.0, vp.x, 12.0), Color(0, 0, 0, 0.12 + float(i) * 0.08))


# זוהר רך (טקסטורה רדיאלית אחת משותפת) - בלי טבעות קשות כמו בכמה draw_circle שקופים
static var _glow_tex: Texture2D


static func glow_tex() -> Texture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		g.add_point(0.7, Color(1, 1, 1, 0.15))
		var tx := GradientTexture2D.new()
		tx.gradient = g
		tx.fill = GradientTexture2D.FILL_RADIAL
		tx.fill_from = Vector2(0.5, 0.5)
		tx.fill_to = Vector2(1.0, 0.5)
		tx.width = 128
		tx.height = 128
		_glow_tex = tx
	return _glow_tex


static func soft_glow(ci: CanvasItem, c: Vector2, r: float, col: Color, squash := 1.0) -> void:
	DrawBatch.texture_rect(ci, glow_tex(), Rect2(c.x - r, c.y - r * squash, r * 2.0, r * 2.0 * squash), false, col)


# פס אובך אנכי (שקוף למעלה -> col למטה). מאחורי הדמויות: מבהיר את הרקע כדי שצלליות כהות ייקראו
static func haze_band(ci: CanvasItem, vp: Vector2, y0: float, y1: float, col: Color) -> void:
	var c0 := Color(col, 0.0)
	DrawBatch.polygon(ci, PackedVector2Array([Vector2(0, y0), Vector2(vp.x, y0), Vector2(vp.x, y1), Vector2(0, y1)]),
		PackedColorArray([c0, c0, col, col]))


# עמוד עשן רך (כתמי זוהר רדיאליים במקום עיגולים חדים)
static func soft_smoke(ci: CanvasItem, base: Vector2, t: float, height := 260.0, col := Color(0.12, 0.1, 0.1, 0.4), drift := 60.0, n := 9) -> void:
	for i in n:
		var k := fmod(float(i) / float(n) + t * 0.06, 1.0)
		var p := base + Vector2(k * drift + sin(k * 6.0 + t * 0.5) * 12.0, -k * height)
		soft_glow(ci, p, 22.0 + k * 70.0, Color(col, col.a * 1.6 * (1.0 - k) * clampf(k * 6.0, 0.0, 1.0)))


# אליפסה רכה מסובבת (ערפילית, שביל החלב, ענן)
static func soft_ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, angle: float, col: Color) -> void:
	DrawBatch.set_transform(ci, c, angle, Vector2.ONE)
	DrawBatch.texture_rect(ci, glow_tex(), Rect2(-rx, -ry, rx * 2.0, ry * 2.0), false, col)
	DrawBatch.set_transform_matrix(ci, Transform2D.IDENTITY)
