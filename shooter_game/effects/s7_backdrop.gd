extends RefCounted
# ============================================================
#  S7 BACKDROP - ציורי הרקע של שלב 7 (מפעל תעשייתי חשוך, "THEY WATCH")
#  פונקציות סטטיות שמקבלות (ci, scroll, vp, t) - בדיוק כמו effects/backdrop_kit.gd.
#  levels/stage_7.gd -> build_background מחבר אותן לשכבות הפרלקסה:
#    sky()  - תקרה חשוכה, אובך, קרני אור מחלונות עליונים (זזות לאט)
#    far()  - 0.10: קיר רחוק עם חלונות, מסבכי גג, תנורים/ממגורות, גלגל תנופה ענק שמסתובב,
#                   עגורן גשר שנוסע לבד, צלליות זומבים על גשר רחוק
#    mid()  - 0.30: צרורות צינורות, גנרטורים עם נורות ומאווררים, עמודי קיטור, גשם ניצוצות מריתוך
#    near() - 0.60: עמודי I, שרשראות תלויות שמתנדנדות, קו מסוע עילי עם ארגזים זזים,
#                   מגדלור אזהרה מסתובב, גשר קרוב עם צלליות
#  האקראיות דטרמיניסטית לפי מספר אריח - לא מהבהב כשזזים.
#  איך משנים: צבעים בקבועים למטה, צפיפות לפי period של כל אריח.
# ============================================================

const Kit := preload("res://effects/backdrop_kit.gd")

const FAR_COL := Color("1d1a18")
const MID_COL := Color("181614")
const NEAR_COL := Color("0f0e0d")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- תקרה + אובך + קרני אור ----
static func sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("070708"), Color("0f0e10"), Color("1a1715"), Color("2a241f"), Color("1e1915")], 0.9)
	# קרני אור אלכסוניות מהחלונות העליונים (נעות קצת)
	for i in 4:
		var x0 := v.x * (0.12 + 0.24 * float(i)) + sin(t * 0.13 + float(i) * 2.0) * 30.0
		var a := 0.035 + 0.02 * sin(t * 0.5 + float(i) * 1.3)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 70, 0), Vector2(x0 + 330, v.y * 0.85), Vector2(x0 + 170, v.y * 0.85)]), Color(0.75, 0.8, 0.85, a))


# ---- שכבה רחוקה ----
static func far(ci: CanvasItem, sc: float, v: Vector2, t: float) -> void:
	# חלונות גבוהים בקיר הרחוק
	var period := 420.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(v.x / period) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 733 + 11)
		var wx := x + 60.0
		ci.draw_rect(Rect2(wx - 6, 44, 132, 172), Color("15130f"))
		var lit := Color(0.32, 0.4, 0.48, 0.32 + 0.05 * sin(t * 0.3 + float(k)))
		ci.draw_rect(Rect2(wx, 50, 120, 160), lit)
		for q in 4:   # שמשות שבורות / כהות
			if r.randf() < 0.35:
				ci.draw_rect(Rect2(wx + float(q % 2) * 60.0, 50 + floorf(float(q) * 0.5) * 80.0, 60, 80), Color(0.06, 0.06, 0.07, 0.8))
		for q in 3:
			ci.draw_line(Vector2(wx + float(q + 1) * 30.0, 50), Vector2(wx + float(q + 1) * 30.0, 210), Color("15130f"), 3.0)
		for q in 4:
			ci.draw_line(Vector2(wx, 50 + float(q + 1) * 32.0), Vector2(wx + 120, 50 + float(q + 1) * 32.0), Color("15130f"), 2.0)
	# מסבכי גג
	var tp := 140.0
	var ts := int(floor(sc / tp)) - 1
	ci.draw_rect(Rect2(0, 20, v.x, 8), FAR_COL)
	ci.draw_rect(Rect2(0, 104, v.x, 6), FAR_COL)
	for k in range(ts, ts + int(v.x / tp) + 3):
		var x := float(k) * tp - sc
		ci.draw_line(Vector2(x, 28), Vector2(x + tp * 0.5, 104), FAR_COL, 3.0)
		ci.draw_line(Vector2(x + tp * 0.5, 104), Vector2(x + tp, 28), FAR_COL, 3.0)
	# מכונות ענק: תנור, ממגורות, גלגל תנופה
	var mp := 900.0
	var ms := int(floor(sc / mp)) - 1
	for k in range(ms, ms + int(v.x / mp) + 3):
		var x := float(k) * mp - sc
		var r := _rng(k * 977 + 5)
		var kind := r.randi() % 3
		var bx := x + r.randf_range(80.0, 400.0)
		if kind == 0:   # תנור היתוך עם פה זוהר
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx, 560), Vector2(bx + 20, 260), Vector2(bx + 150, 260), Vector2(bx + 170, 560)]), FAR_COL)
			ci.draw_rect(Rect2(bx + 55, 140, 60, 120), FAR_COL)
			var g := 0.6 + 0.25 * sin(t * 2.3 + float(k)) + 0.1 * sin(t * 7.1)
			ci.draw_rect(Rect2(bx + 55, 470, 60, 40), Color(1.0, 0.45, 0.12, 0.55 * g))
			for i in 3:
				ci.draw_circle(Vector2(bx + 85, 490), 50.0 + float(i) * 30.0, Color(1.0, 0.4, 0.1, 0.05 * g))
		elif kind == 1:   # זוג ממגורות עם צינור מחבר
			for i in 2:
				var sx := bx + float(i) * 110.0
				ci.draw_rect(Rect2(sx, 250, 90, 310), FAR_COL)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(sx, 250), Vector2(sx + 45, 215), Vector2(sx + 90, 250)]), FAR_COL)
				for q in 5:
					ci.draw_line(Vector2(sx, 290 + q * 55), Vector2(sx + 90, 290 + q * 55), Color("14120f"), 2.0)
			ci.draw_rect(Rect2(bx + 90, 300, 20, 12), FAR_COL)
		else:   # גלגל תנופה ענק שמסתובב לאט
			var c := Vector2(bx + 100, 400)
			ci.draw_circle(c, 120.0, FAR_COL)
			ci.draw_circle(c, 100.0, Color("17150f"))
			for i in 6:
				var a := t * 0.25 + float(i) * TAU / 6.0
				ci.draw_line(c, c + Vector2.from_angle(a) * 104.0, FAR_COL, 10.0)
			ci.draw_circle(c, 22.0, FAR_COL)
			ci.draw_rect(Rect2(c.x - 30, c.y, 60, 160), FAR_COL)
	# עגורן גשר רחוק שנוסע לבד + מטען מתנדנד
	ci.draw_rect(Rect2(0, 150, v.x, 10), FAR_COL)
	var cx := fposmod(t * 22.0 - sc * 0.5, v.x + 400.0) - 200.0
	ci.draw_rect(Rect2(cx - 30, 146, 60, 18), Color("221f1b"))
	var sway := sin(t * 0.9) * 0.12
	var hook := Vector2(cx, 164) + Vector2.from_angle(PI * 0.5 + sway) * 150.0
	ci.draw_line(Vector2(cx, 164), hook, Color("13110f"), 2.0)
	ci.draw_rect(Rect2(hook.x - 34, hook.y, 68, 40), Color("221f1b"))
	# צלליות זומבים על גשר רחוק (הולכים לבד)
	ci.draw_rect(Rect2(0, 330, v.x, 4), FAR_COL)
	for i in 4:
		var zx := fposmod(float(i) * 330.0 + t * 14.0 - sc * 0.8, v.x + 200.0) - 100.0
		var bob := absf(sin(t * 3.0 + float(i))) * 1.5
		ci.draw_rect(Rect2(zx - 3, 312 - bob, 6, 18), Color("120f0d"))
		ci.draw_circle(Vector2(zx + 1, 309 - bob), 3.5, Color("120f0d"))
		ci.draw_line(Vector2(zx + 2, 318 - bob), Vector2(zx + 9, 322 - bob), Color("120f0d"), 2.0)


# ---- שכבה אמצעית ----
static func mid(ci: CanvasItem, sc: float, v: Vector2, t: float) -> void:
	# צרור צינורות אופקי לכל הרוחב
	for i in 3:
		var py := 228.0 + float(i) * 15.0
		ci.draw_rect(Rect2(0, py, v.x, 10), MID_COL)
		ci.draw_line(Vector2(0, py + 2), Vector2(v.x, py + 2), Color(0.5, 0.45, 0.4, 0.12), 1.0)
	var fp := 120.0
	var fs := int(floor(sc / fp)) - 1
	for k in range(fs, fs + int(v.x / fp) + 3):   # אוגנים
		var x := float(k) * fp - sc
		ci.draw_rect(Rect2(x, 224, 6, 52), Color("100e0c"))
	var period := 760.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(v.x / period) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 389 + 21)
		# צינור יורד עם שסתום
		var dx := x + r.randf_range(20.0, 120.0)
		ci.draw_rect(Rect2(dx, 270, 12, 300), MID_COL)
		ci.draw_circle(Vector2(dx + 6, 380), 11.0, Color("1c1916"))
		ci.draw_line(Vector2(dx - 6, 380), Vector2(dx + 18, 380), Color("2a2420"), 2.0)
		# גנרטור עם נורות מהבהבות ומאוורר מסתובב
		var gx := x + r.randf_range(220.0, 420.0)
		ci.draw_rect(Rect2(gx, 430, 200, 130), MID_COL)
		ci.draw_circle(Vector2(gx, 495), 65.0, MID_COL)
		ci.draw_circle(Vector2(gx + 200, 495), 65.0, MID_COL)
		for q in 9:   # צלעות קירור
			ci.draw_line(Vector2(gx + 20 + q * 18, 440), Vector2(gx + 20 + q * 18, 550), Color("100e0c"), 3.0)
		var fc := Vector2(gx + 200, 495)
		ci.draw_circle(fc, 40.0, Color("100e0c"))
		for q in 4:
			var a := t * 4.0 + float(q) * TAU / 4.0 + float(k)
			ci.draw_colored_polygon(PackedVector2Array([fc, fc + Vector2.from_angle(a - 0.2) * 36.0, fc + Vector2.from_angle(a + 0.25) * 36.0]), Color("221e1a"))
		for q in 3:
			var on := fmod(t * (0.7 + float(q) * 0.4) + float(k), 1.0) < 0.5
			var lc := Color(1.0, 0.6, 0.15) if q != 2 else Color(0.3, 1.0, 0.45)
			ci.draw_circle(Vector2(gx + 40 + q * 18, 450), 3.0, Color(lc, 0.85 if on else 0.15))
			if on:
				ci.draw_circle(Vector2(gx + 40 + q * 18, 450), 9.0, Color(lc, 0.12))
		# עמוד קיטור מהצינור
		Kit.smoke_column(ci, Vector2(dx + 6, 270), t * 1.6 + float(k), 200.0, Color(0.55, 0.55, 0.58, 0.1), 30.0)
		# גשם ניצוצות מנקודת ריתוך
		var wx := x + r.randf_range(480.0, 700.0)
		var flash := fmod(t * 0.6 + float(k) * 0.37, 1.0)
		if flash < 0.5:
			ci.draw_circle(Vector2(wx, 300), 10.0 + 6.0 * sin(t * 40.0), Color(1.0, 0.85, 0.5, 0.25))
			for q in 8:
				var ph := fmod(t * 1.3 + float(q) * 0.125, 1.0)
				var sx := wx + (float(q) - 3.5) * 9.0 * ph * 3.0
				var sy := 300.0 + ph * ph * 160.0
				ci.draw_line(Vector2(sx, sy), Vector2(sx, sy + 4.0), Color(1.0, 0.7, 0.25, 0.8 * (1.0 - ph)), 1.5)


# ---- שכבה קרובה ----
static func near(ci: CanvasItem, sc: float, v: Vector2, t: float) -> void:
	# קו מסוע עילי עם ארגזים תלויים שנוסעים לבד
	ci.draw_rect(Rect2(0, 186, v.x, 8), NEAR_COL)
	var hp := 220.0
	var off := fposmod(t * 40.0 - sc, hp)
	var hx := off - hp
	while hx < v.x + hp:
		ci.draw_line(Vector2(hx, 194), Vector2(hx, 236), NEAR_COL, 2.0)
		ci.draw_rect(Rect2(hx - 18, 236, 36, 30), Color("14120f"))
		ci.draw_line(Vector2(hx - 18, 251), Vector2(hx + 18, 251), Color("0a0908"), 1.5)
		hx += hp
	var period := 620.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(v.x / period) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 1187 + 3)
		# עמוד I עם הצלבות
		var cx := x + 40.0
		ci.draw_rect(Rect2(cx, 0, 26, 600), NEAR_COL)
		ci.draw_rect(Rect2(cx + 11, 0, 4, 600), Color("1a1816"))
		for q in 12:
			ci.draw_circle(Vector2(cx + 5, 30 + q * 48), 1.6, Color("2a2622"))
		ci.draw_line(Vector2(cx + 26, 330), Vector2(cx + 140, 200), NEAR_COL, 6.0)
		# מגדלור אזהרה מסתובב על העמוד
		var bc := Vector2(cx + 13, 300)
		ci.draw_rect(Rect2(bc.x - 6, bc.y - 2, 12, 8), Color("0a0908"))
		var a := t * 3.0 + float(k)
		var lum := absf(cos(a))
		ci.draw_circle(bc, 4.5, Color(1.0, 0.55, 0.1, 0.4 + 0.6 * lum))
		ci.draw_colored_polygon(PackedVector2Array([bc, bc + Vector2(cos(a) * 260.0, -50), bc + Vector2(cos(a) * 260.0, 50)]), Color(1.0, 0.55, 0.1, 0.07 * lum))
		# שרשראות תלויות עם ווים (מתנדנדות)
		for q in 2:
			var chx := x + r.randf_range(180.0, 560.0)
			var ln := r.randf_range(200.0, 340.0)
			var sw := sin(t * 0.8 + float(k) * 1.7 + float(q) * 2.3) * 0.06
			var pts := PackedVector2Array()
			for s in 9:
				var u := float(s) / 8.0
				pts.append(Vector2(chx + sin(sw * u * 10.0) * ln * 0.12 * u, u * ln))
			ci.draw_polyline(pts, Color("15130f"), 3.0)
			var hk: Vector2 = pts[8]
			ci.draw_arc(hk + Vector2(0, 8), 8.0, -0.3, PI + 0.6, 8, Color("15130f"), 3.0)
	# גשר קרוב עם מעקה + צלליות שהולכות עליו
	ci.draw_rect(Rect2(0, 392, v.x, 8), NEAR_COL)
	ci.draw_line(Vector2(0, 372), Vector2(v.x, 372), NEAR_COL, 2.0)
	var rp := 60.0
	var rs := fposmod(-sc, rp)
	var rx := rs
	while rx < v.x:
		ci.draw_line(Vector2(rx, 372), Vector2(rx, 392), NEAR_COL, 2.0)
		rx += rp
	for i in 3:
		var zx := fposmod(float(i) * 470.0 - t * 22.0 - sc, v.x + 200.0) - 100.0
		var bob := absf(sin(t * 4.0 + float(i) * 2.0)) * 2.0
		ci.draw_rect(Rect2(zx - 5, 360 - bob, 10, 32), Color("0b0a09"))
		ci.draw_circle(Vector2(zx - 3, 354 - bob), 6.0, Color("0b0a09"))
		ci.draw_line(Vector2(zx - 4, 368 - bob), Vector2(zx - 16, 374 - bob), Color("0b0a09"), 3.0)
	Kit.ground_fade(ci, v, 560.0)
