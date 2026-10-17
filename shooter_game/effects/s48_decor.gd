extends RefCounted
# ============================================================
#  קישוטים לשלב 48 ("OLD QUARTER") - בואנוס איירס בלילה: לה בוקה וסן טלמו. אזור שישי (החרוט הדרומי), שלב 3.
#  בתי הקונבנטיו מפח גלי צבוע בכל הצבעים, קמיניטו, אבני מרצפת, פנסי ברזל, שלטי "פילטאדו", טנגו ברחוב.
#    oq_sky       - (רקע) לילה כחול-סגול, ירח, כוכבים מנצנצים, זוהר כתום של העיר מלמטה, עננים זזים
#    far_city     - (רקע, 0.06) קו הרקיע עם האובליסק, מנופי הנמל עם אורות מהבהבים, גשר המעבורת של לה בוקה,
#                   הנהר (ריאצ'ואלו) עם אורות של ספינות שזזות
#    mid_houses   - (רקע, 0.28) שורת בתי פח צבעוניים, חלונות מוארים (חלק מהבהבים), חבלי כביסה מתנדנדים
#    near_street  - (רקע, 0.6) פנסי ברזל עם הילה, שלטי פילטאדו, זוג טנגו (צללית רוקדת), נגן בנדוניאון
#    CobbleGround - (עולם) מרצפת אבנים + פסי חשמלית
#    Conventillo  - (עולם) חזית בית פח צבעוני עם מרפסת ברזל (הקומה = add_floor)
#    Tram         - (עולם, מלכודת) חשמלית שועטת לאורך קטע רחוב: פעמון + פנס (WARN_T) ואז חוצה את הקטע (DMG / DMG_Z).
#                   לטפס למרפסת או קפיצה כפולה מעליה.
#    SparkWire    - (עולם, מלכודת) כבל חשמלית קרוע על הרצפה הרטובה: מתפצפץ (WARN_T) ואז פורק (R): נזק לך + לזומבים.
#    TangoStage   - (עולם) במת הטנגו של קמיניטו בסוף השלב (רחבת הבוס)
#    Obstacle     - (מוצק + מחסה) "kiosk" קיוסק עיתונים / "cart" עגלת צ'וריפאן / "planter" עציץ ענק עם עץ
#    QuarterFX    - (מסך) ערפל נהר נמוך ועשים סביב האור
#  לשנות: Tram.WARN_T / SPEED / DMG / DMG_Z / CYCLE, SparkWire.CYCLE / WARN_T / R / DMG_Z.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const HOUSE_COLS := [Color("2a6ab0"), Color("e0b020"), Color("c83a2a"), Color("2a9a6a"), Color("e07a20"), Color("7a3a9a"), Color("3a9ac8")]


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func oq_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("080a1e"), Color("141a3a"), Color("2a2448"), Color("6a3a40"), Color("c06a3a")], 0.9)
	for i in 50:   # כוכבים
		var p := Vector2(_h(i, 1) * v.x, _h(i, 2) * v.y * 0.5)
		var tw := 0.4 + 0.6 * absf(sin(t * (0.8 + _h(i, 3) * 2.0) + float(i)))
		ci.draw_circle(p, 0.8 + _h(i, 4), Color(1.0, 0.95, 0.85, 0.5 * tw))
	var mp := Vector2(v.x * 0.64, v.y * 0.17)
	Art.glow(ci, mp, 80.0, Color(0.8, 0.85, 1.0, 0.12))
	ci.draw_circle(mp, 24.0, Color(0.95, 0.94, 0.88))
	ci.draw_circle(mp + Vector2(7, -5), 5.0, Color(0.85, 0.84, 0.8))
	ci.draw_circle(mp + Vector2(-8, 6), 3.5, Color(0.86, 0.85, 0.8))
	Kit.clouds(ci, t * 4.0, v, t, v.y * 0.2, Color(0.12, 0.12, 0.24, 0.45), 11, 6.0)


# ---- קו הרקיע, הנמל והנהר ----
static func far_city(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	Kit.skyline(ci, sc, v, y - 40.0, Color("1c1a34"), 48, Vector2(50, 120), Vector2(80, 240), 0.06, Color(1.0, 0.8, 0.5, 0.7), t, 0.0)
	var period := 1600.0
	var start := int(floor(sc / period)) - 1
	var dark := Color("161428")
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# האובליסק
		var ox := bx + 300.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(ox - 11, y - 40), Vector2(ox - 7, y - 300), Vector2(ox, y - 318), Vector2(ox + 7, y - 300), Vector2(ox + 11, y - 40)]), Color("242240"))
		ci.draw_line(Vector2(ox - 6, y - 290), Vector2(ox - 9, y - 50), Color(1.0, 0.85, 0.6, 0.15), 2.0)
		ci.draw_circle(Vector2(ox, y - 316), 2.0, Color(1.0, 0.2, 0.15, 0.4 + 0.6 * float(int(t * 1.5) % 2)))
		# גשר המעבורת (פואנטה טרנסבורדדור)
		var gx := bx + 900.0
		for side: float in [-1.0, 1.0]:
			var tx := gx + side * 130.0
			ci.draw_line(Vector2(tx - 10, y - 40), Vector2(tx - 4, y - 230), dark, 4.0)
			ci.draw_line(Vector2(tx + 10, y - 40), Vector2(tx + 4, y - 230), dark, 4.0)
			for q in 6:
				var yy := y - 40.0 - float(q) * 32.0
				ci.draw_line(Vector2(tx - 9, yy), Vector2(tx + 9, yy - 32), dark, 1.5)
		ci.draw_rect(Rect2(gx - 150, y - 240, 300, 14), dark)
		for q in 15:
			ci.draw_line(Vector2(gx - 150 + float(q) * 20.0, y - 240), Vector2(gx - 140 + float(q) * 20.0, y - 226), Color("24223e"), 1.0)
		var gond := gx + sin(t * 0.15 + float(k)) * 100.0   # הגונדולה נוסעת
		ci.draw_line(Vector2(gond, y - 226), Vector2(gond, y - 70), Color("24223e"), 1.0)
		ci.draw_rect(Rect2(gond - 18, y - 72, 36, 14), dark)
		ci.draw_circle(Vector2(gond, y - 66), 2.0, Color(1.0, 0.8, 0.4, 0.8))
		# מנופי נמל
		for q in 2:
			var cx := bx + 1250.0 + float(q) * 160.0
			ci.draw_line(Vector2(cx, y - 40), Vector2(cx, y - 200), dark, 5.0)
			ci.draw_line(Vector2(cx - 30, y - 190), Vector2(cx + 110, y - 196), dark, 4.0)
			ci.draw_line(Vector2(cx, y - 200), Vector2(cx + 110, y - 196), dark, 1.0)
			ci.draw_line(Vector2(cx + 80, y - 194), Vector2(cx + 80, y - 120 + sin(t * 0.5 + float(q)) * 10.0), dark, 1.0)
			ci.draw_circle(Vector2(cx + 110, y - 196), 2.2, Color(1.0, 0.15, 0.1, 0.3 + 0.7 * float(int(t * 2.0 + float(q)) % 2)))
	# הנהר עם השתקפויות ואורות ספינות
	ci.draw_rect(Rect2(0, y - 40.0, v.x, 40.0), Color("0e1024"))
	for i in 12:
		var rx := fposmod(float(i) * 173.0 - sc * 1.0 + sin(t * 0.7 + float(i)) * 8.0, v.x)
		ci.draw_line(Vector2(rx, y - 28.0 + float(i % 3) * 8.0), Vector2(rx + 30.0, y - 28.0 + float(i % 3) * 8.0), Color(1.0, 0.7, 0.4, 0.15), 1.5)
	for i in 3:   # ספינות שזזות לאט
		var sx := fposmod(t * (12.0 + float(i) * 5.0) + float(i) * 700.0 - sc, v.x + 400.0) - 200.0
		var sy := y - 36.0 + float(i) * 6.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - 60, sy - 6), Vector2(sx + 60, sy - 6), Vector2(sx + 50, sy + 4), Vector2(sx - 54, sy + 4)]), Color("0a0a16"))
		ci.draw_rect(Rect2(sx - 20, sy - 18, 34, 12), Color("0a0a16"))
		for q in 5:
			ci.draw_circle(Vector2(sx - 40.0 + float(q) * 18.0, sy - 2.0), 1.4, Color(1.0, 0.85, 0.5, 0.8))
		ci.draw_circle(Vector2(sx + 55.0, sy - 8.0), 1.8, Color(0.3, 1.0, 0.4, 0.9))


# ---- בתי הפח הצבעוניים של לה בוקה ----
static func mid_houses(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 140.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		var c: Color = HOUSE_COLS[posmod(k * 3 + int(_h(k, 7) * 3.0), HOUSE_COLS.size())]
		c = c.darkened(0.45)
		var floors := 2 + int(_h(k, 8) * 2.0)
		var hh := float(floors) * 62.0 + 20.0
		var w := period - 6.0
		ci.draw_rect(Rect2(bx, y - hh, w, hh), c)
		for q in int(w / 8.0):   # פח גלי
			ci.draw_line(Vector2(bx + float(q) * 8.0 + 4.0, y - hh), Vector2(bx + float(q) * 8.0 + 4.0, y), c.darkened(0.2), 1.0)
		# גג משופע
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 6, y - hh), Vector2(bx + w * 0.5, y - hh - 22.0), Vector2(bx + w + 6, y - hh)]), Color("2a2030").lerp(c, 0.3))
		for f in floors:
			var fy := y - hh + 26.0 + float(f) * 62.0
			for q in 2:
				var wx := bx + 22.0 + float(q) * 56.0
				var lit := _h(k * 5 + f * 2 + q, 9) < 0.62
				var flick := 1.0
				if _h(k * 5 + f * 2 + q, 11) < 0.12:
					flick = 0.5 + 0.5 * float(int(t * 6.0 + float(k)) % 4 != 0)
				ci.draw_rect(Rect2(wx, fy, 26, 34), Color(1.0, 0.72, 0.38, 0.85 * flick) if lit else Color("12101e"))
				ci.draw_line(Vector2(wx + 13, fy), Vector2(wx + 13, fy + 34), Color(0.1, 0.08, 0.1, 0.8), 1.5)
				ci.draw_rect(Rect2(wx - 4, fy, 4, 34), c.lightened(0.15))   # תריסים
				ci.draw_rect(Rect2(wx + 26, fy, 4, 34), c.lightened(0.15))
			if f > 0:   # מרפסת ברזל
				ci.draw_line(Vector2(bx + 10, fy + 40), Vector2(bx + w - 10, fy + 40), Color("101018"), 2.0)
				for q in int((w - 20.0) / 7.0):
					ci.draw_line(Vector2(bx + 10.0 + float(q) * 7.0, fy + 40), Vector2(bx + 10.0 + float(q) * 7.0, fy + 28), Color("101018"), 1.0)
		# חבל כביסה לבית הבא - מתנדנד
		if _h(k, 12) < 0.55:
			var ly := y - hh + 60.0
			var a := Vector2(bx + w - 4.0, ly)
			var b := Vector2(bx + w + 6.0 + period - 10.0, ly + 6.0)
			var sag := 14.0 + sin(t * 1.3 + float(k)) * 3.0
			var pts := PackedVector2Array()
			for q in 9:
				var u := float(q) / 8.0
				pts.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * sag))
			ci.draw_polyline(pts, Color("0c0a14"), 1.0)
			for q in 4:
				var u := 0.18 + float(q) * 0.2
				var p := a.lerp(b, u) + Vector2(0, sin(u * PI) * sag)
				var sw := sin(t * 2.2 + float(q) + float(k)) * 3.0
				var cc: Color = HOUSE_COLS[(k + q) % HOUSE_COLS.size()].darkened(0.3)
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 0), p + Vector2(6, 0), p + Vector2(6 + sw, 14), p + Vector2(-6 + sw, 14)]), cc)
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("100c18"))


# ---- הרחוב הקרוב: פנסים, שלטי פילטאדו, טנגו ----
static func near_street(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 520.0
	var start := int(floor(sc / period)) - 1
	var iron := Color("0a080e")
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		# פנס ברזל יצוק עם 3 זרועות
		var lx := x + 40.0
		Art.glow(ci, Vector2(lx, y - 150), 70.0, Color(1.0, 0.75, 0.4, 0.22))
		ci.draw_line(Vector2(lx, y), Vector2(lx, y - 140), iron, 5.0)
		ci.draw_rect(Rect2(lx - 8, y - 14, 16, 14), iron)
		for s in [-1.0, 1.0]:
			ci.draw_line(Vector2(lx, y - 140), Vector2(lx + s * 20.0, y - 150), iron, 2.5)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(lx + s * 20.0 - 5, y - 150), Vector2(lx + s * 20.0 + 5, y - 150), Vector2(lx + s * 20.0 + 4, y - 166), Vector2(lx + s * 20.0 - 4, y - 166)]), Color(1.0, 0.82, 0.5))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(lx - 5, y - 150), Vector2(lx + 5, y - 150), Vector2(lx + 4, y - 170), Vector2(lx - 4, y - 170)]), Color(1.0, 0.85, 0.55))
		# שלט פילטאדו (מסגרת מעוטרת)
		var sx := x + 140.0
		var sy := y - 120.0
		ci.draw_line(Vector2(sx + 60, sy - 20), Vector2(sx + 60, y), iron, 3.0)
		ci.draw_rect(Rect2(sx, sy, 120, 44), Color("141018"))
		ci.draw_rect(Rect2(sx + 3, sy + 3, 114, 38), Color("1e3a2a") if k % 2 == 0 else Color("3a1a20"))
		for q in 4:   # עיטורי פילטאדו - ספירלות
			var cpos := Vector2(sx + 12.0 + float(q % 2) * 96.0, sy + 10.0 + float(q / 2) * 24.0)
			ci.draw_arc(cpos, 5.0, 0.0, PI * 1.5, 8, Color("e0b030"), 1.5)
			ci.draw_arc(cpos + Vector2(2, 1), 2.5, PI, TAU, 6, Color("d03030"), 1.2)
		var word: String = ["TANGO", "BOCA", "CAFE", "MILONGA"][posmod(k, 4)]
		ci.draw_string(ThemeDB.fallback_font, Vector2(sx + 26, sy + 30), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f0d070"))
		# זוג טנגו (צללית) - מסתובבים ברגליים
		if k % 2 == 0:
			var tx := x + 330.0
			var sw := sin(t * 2.0 + float(k))
			var lean := sw * 0.15
			_dancer(ci, Vector2(tx, y), lean, iron, false, t)
			_dancer(ci, Vector2(tx + 16.0, y), -lean, iron, true, t)
		else:   # נגן בנדוניאון על כיסא
			var bx := x + 330.0
			ci.draw_rect(Rect2(bx - 10, y - 22, 20, 4), iron)
			ci.draw_line(Vector2(bx - 8, y - 18), Vector2(bx - 8, y), iron, 2.0)
			ci.draw_line(Vector2(bx + 8, y - 18), Vector2(bx + 8, y), iron, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 8, y - 22), Vector2(bx + 6, y - 22), Vector2(bx + 4, y - 50), Vector2(bx - 6, y - 50)]), iron)
			ci.draw_circle(Vector2(bx, y - 57), 7.0, iron)
			var open := 10.0 + sin(t * 3.0) * 7.0   # המפוח נפתח ונסגר
			ci.draw_rect(Rect2(bx + 4, y - 40, 8, 14), iron)
			for q in 4:
				ci.draw_line(Vector2(bx + 12 + float(q) * open / 4.0, y - 41), Vector2(bx + 12 + float(q) * open / 4.0, y - 25), Color("2a2030"), 2.0)
			ci.draw_rect(Rect2(bx + 12 + open, y - 40, 8, 14), iron)
			for q in 3:   # תווים עולים
				var nt := fposmod(t * 0.6 + float(q) * 0.33, 1.0)
				ci.draw_circle(Vector2(bx + 20.0 + nt * 30.0 + sin(nt * 9.0) * 6.0, y - 50.0 - nt * 60.0), 2.0, Color(1.0, 0.85, 0.5, 0.6 * (1.0 - nt)))
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("0a080c"))


static func _dancer(ci: CanvasItem, p: Vector2, lean: float, c: Color, woman: bool, t: float) -> void:
	var top := p + Vector2(sin(lean) * 40.0, -54.0)
	ci.draw_line(p + Vector2(-3, 0), top + Vector2(0, 26), c, 3.0)
	if woman:   # רגל מורמת (גנצ'ו) + חצאית
		var kick := maxf(sin(t * 2.0) , 0.0)
		ci.draw_line(top + Vector2(0, 26), p + Vector2(10.0 + kick * 10.0, -kick * 14.0), c, 3.0)
		ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-5, 20), top + Vector2(5, 20), top + Vector2(10, 34), top + Vector2(-9, 34)]), c)
	else:
		ci.draw_line(top + Vector2(0, 26), p + Vector2(4, 0), c, 3.0)
		ci.draw_rect(Rect2(top + Vector2(-6, -12), Vector2(12, 3)), c)   # פדורה
		ci.draw_rect(Rect2(top + Vector2(-4, -16), Vector2(8, 5)), c)
	ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-5, 0), top + Vector2(5, 0), top + Vector2(4, 26), top + Vector2(-4, 26)]), c)
	ci.draw_circle(top + Vector2(0, -5), 5.0, c)
	ci.draw_line(top + Vector2(0, 4), top + Vector2(8 if not woman else -8, 2), c, 2.0)   # ידיים מחובקות


# ============================================================
#  עולם
# ============================================================
class CobbleGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		draw_rect(Rect2(0, 0, w, depth), Color("2a2630"))
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for row in 3:   # אבני מרצפת מעוגלות
			var yy := 2.0 + float(row) * 9.0
			var x := -float(row % 2) * 7.0
			while x < w:
				var bw := r.randf_range(11.0, 15.0)
				var shade := r.randf_range(-0.06, 0.06)
				draw_rect(Rect2(x + 1.0, yy, bw - 2.0, 7.5), Color("5a5464").lightened(shade))
				draw_line(Vector2(x + 2.0, yy + 1.0), Vector2(x + bw - 3.0, yy + 1.0), Color(1.0, 0.85, 0.6, 0.18), 1.0)   # אור הפנסים על האבנים
				x += bw
		draw_rect(Rect2(0, 0, w, 2), Color("8a8090"))
		for q in 2:   # פסי חשמלית
			draw_rect(Rect2(0, 6.0 + float(q) * 12.0, w, 2.5), Color("8a8a98"))
			draw_rect(Rect2(0, 8.5 + float(q) * 12.0, w, 1.0), Color("1a1820"))
		var px := r.randf_range(80.0, 400.0)   # שלוליות עם השתקפות
		while px < w - 60.0:
			draw_colored_polygon(Art.ellipse(Vector2(px, 4), r.randf_range(22, 40), 2.5, 0.0, 12), Color(1.0, 0.75, 0.45, 0.22))
			px += r.randf_range(260.0, 520.0)


# ---- חזית בית קונבנטיו עם מרפסת ברזל ----
class Conventillo extends Node2D:
	var w := 320.0
	var tier := 150.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var top := -tier - 130.0
		var n := maxi(int(w / 110.0), 2)
		var pw := w / float(n)
		for q in n:   # כל קטע בצבע אחר (כמו בקמיניטו)
			var c: Color = HOUSE_COLS[(seed_v + q * 3) % HOUSE_COLS.size()].darkened(0.15)
			var x0 := float(q) * pw
			var htop := top + float((seed_v + q) % 3) * 14.0
			draw_rect(Rect2(x0, htop, pw, -htop), c)
			for k in int(pw / 7.0):
				draw_line(Vector2(x0 + float(k) * 7.0 + 3.0, htop), Vector2(x0 + float(k) * 7.0 + 3.0, 0), c.darkened(0.18), 1.0)
			draw_rect(Rect2(x0 - 2, htop - 6, pw + 4, 6), Color("3a3040"))
			# חלון למעלה (מואר) + דלת למטה
			var wx := x0 + pw * 0.5 - 14.0
			var lit := (seed_v + q) % 4 != 0
			draw_rect(Rect2(wx, -tier - 80.0, 28, 40), Color(1.0, 0.75, 0.42) if lit else Color("1a1420"))
			draw_line(Vector2(wx + 14, -tier - 80.0), Vector2(wx + 14, -tier - 40.0), Color("2a2030"), 2.0)
			draw_rect(Rect2(wx - 5, -tier - 80.0, 5, 40), c.lightened(0.25))
			draw_rect(Rect2(wx + 28, -tier - 80.0, 5, 40), c.lightened(0.25))
			draw_rect(Rect2(wx - 2, -64.0, 32, 64), Color("3a2418"))
			draw_rect(Rect2(wx + 2, -60.0, 24, 26), Color(1.0, 0.7, 0.35, 0.5) if lit else Color("1a1018"))
			draw_circle(Vector2(wx + 24, -30.0), 1.5, Color("c8a040"))
		# המרפסת: רצפת עץ + מעקה ברזל + תומכות
		draw_rect(Rect2(-6, -tier, w + 12, 10.0), Color("4a3428"))
		draw_rect(Rect2(-6, -tier + 10.0, w + 12, 3.0), Color("1a1018"))
		draw_line(Vector2(-6, -tier - 26.0), Vector2(w + 6, -tier - 26.0), Color("16121c"), 3.0)
		for k in int(w / 9.0) + 1:
			var bx := float(k) * 9.0
			draw_line(Vector2(bx, -tier), Vector2(bx, -tier - 26.0), Color("16121c"), 1.5)
			if k % 4 == 0:
				draw_arc(Vector2(bx + 4.5, -tier - 13.0), 4.0, 0.0, TAU, 8, Color("16121c"), 1.0)
		for px: float in [10.0, w * 0.5, w - 16.0]:
			draw_line(Vector2(px, -tier + 13.0), Vector2(px - 18.0, -tier + 50.0), Color("16121c"), 2.5)   # זוויתן
		# עציצי גרניום על המעקה
		for k in int(w / 80.0):
			var fx := 30.0 + float(k) * 80.0
			draw_rect(Rect2(fx, -tier - 34.0, 14, 8), Color("8a3a20"))
			for q in 3:
				draw_circle(Vector2(fx + 3.0 + float(q) * 4.0, -tier - 36.0), 3.0, Color("d02030") if (k + q) % 2 == 0 else Color("2a6a2a"))


# ---- חשמלית שועטת ----
class Tram extends Node2D:
	const WARN_T := 1.6
	const SPEED := 760.0
	const LEN := 230.0
	const HT := 118.0
	const DMG := 2
	const DMG_Z := 90
	const CYCLE := Vector2(5.0, 8.0)
	var span := 900.0                # אורך הקטע
	var dir := 1.0                   # לאיזה כיוון נוסעת
	var runs := 0                    # לבדיקות
	var hits := 0
	var crushed := 0
	var state := 0                   # 0 = מחכה, 1 = פעמון, 2 = נוסעת
	var _t := 3.0
	var _x := 0.0                    # מיקום החזית (מקומי)
	var _hit_pl := false
	var _hit_z := {}
	var _tt := 0.0

	func _ready() -> void:
		z_index = 5
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -HT), Vector2(span, HT))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != 0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_tt += delta
		var pl := get_tree().get_first_node_in_group("player")
		var near: bool = pl != null and not pl.dead and pl.global_position.x > global_position.x - 300.0 and pl.global_position.x < global_position.x + span + 300.0
		match state:
			0:
				if near:
					_t -= delta
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					preload("res://sfx.gd").play("oq_bell", pl.global_position if pl != null else global_position, 0.0, 0.05, 2)
			1:
				_t -= delta
				if Engine.get_physics_frames() % 24 == 0 and _t > 0.4:
					preload("res://sfx.gd").play("oq_bell", pl.global_position if pl != null else global_position, -4.0, 0.05, 2)
				if _t <= 0.0:
					state = 2
					runs += 1
					_hit_pl = false
					_hit_z.clear()
					_x = -LEN if dir > 0.0 else span + LEN
					preload("res://sfx.gd").play("train", global_position + Vector2(span * 0.5, 0), 2.0, 0.05, 2)
			2:
				_x += dir * SPEED * delta
				var r := Rect2(global_position + Vector2(_x - (LEN if dir > 0.0 else 0.0), -HT), Vector2(LEN, HT))
				if pl != null and not pl.dead and not _hit_pl and r.intersects(pl.body_rect()):
					_hit_pl = true
					hits += 1
					pl.hurt(DMG, Vector2(dir * 3.2, -1.2))
					pl.velocity.x = dir * 620.0
				if Engine.get_physics_frames() % 3 == 0:
					for z in get_tree().get_nodes_in_group("zombies"):
						if z.dead or z.is_boss() or _hit_z.has(z.get_instance_id()):
							continue
						if r.has_point(z.global_position + Vector2(0, -20)):
							_hit_z[z.get_instance_id()] = true
							crushed += 1
							z.take_damage(DMG_Z, z.global_position + Vector2(0, -30), Vector2(dir, -0.3), true, {"source": "car", "fixed": DMG_Z})
				if (dir > 0.0 and _x > span + LEN) or (dir < 0.0 and _x < -LEN):
					state = 0
					_t = randf_range(CYCLE.x, CYCLE.y)
		if Art.on_screen(self, global_position + Vector2(clampf(_x, 0.0, span), -60), span * 0.5 + LEN):
			queue_redraw()

	func _draw() -> void:
		# קטע הפסים המסומן + עמודי כבל עליון
		draw_line(Vector2(0, -HT - 40.0), Vector2(span, -HT - 40.0), Color("16121c"), 1.5)
		for px: float in [0.0, span]:
			draw_line(Vector2(px, 0), Vector2(px, -HT - 50.0), Color("16121c"), 4.0)
			draw_line(Vector2(px, -HT - 46.0), Vector2(px + (20.0 if px == 0.0 else -20.0), -HT - 40.0), Color("16121c"), 2.0)
		if state == 1:   # אזהרה: פנס מהצד שממנו היא מגיעה + "TRAM!"
			var ex := -20.0 if dir > 0.0 else span + 20.0
			var bl := 0.5 + 0.5 * sin(_tt * 18.0)
			Art.glow(self, Vector2(ex, -40), 60.0 + 30.0 * (1.0 - _t / WARN_T), Color(1.0, 0.95, 0.7, 0.35 + 0.3 * bl))
			draw_string(ThemeDB.fallback_font, Vector2(span * 0.5 - 40.0, -HT - 56.0), "TRAM!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.85, 0.3, 0.6 + 0.4 * bl))
			for q in 6:   # חצים לאורך הקטע
				var ax := fposmod(float(q) * span / 6.0 + _tt * 300.0 * dir, span)
				draw_colored_polygon(PackedVector2Array([Vector2(ax, -6), Vector2(ax + 14.0 * dir, -10), Vector2(ax, -14)]), Color(1.0, 0.8, 0.2, 0.7))
		if state == 2:
			_draw_tram(_x)

	func _draw_tram(fx: float) -> void:
		var x0 := fx - LEN if dir > 0.0 else fx
		var body := Color("2a6a3a")
		var cream := Color("e8dcc0")
		draw_rect(Rect2(x0, -HT + 10.0, LEN, HT - 22.0), body)
		draw_rect(Rect2(x0, -HT + 10.0, LEN, 30.0), cream)
		draw_rect(Rect2(x0 - 4, -HT + 4.0, LEN + 8, 8.0), Color("1a2a1e"))
		for q in 7:   # חלונות מוארים עם צלליות מתים
			var wx := x0 + 14.0 + float(q) * 30.0
			draw_rect(Rect2(wx, -HT + 16.0, 22, 20), Color(1.0, 0.8, 0.5, 0.9))
			if q % 2 == 1:
				draw_circle(Vector2(wx + 11, -HT + 30.0), 5.0, Color(0.1, 0.12, 0.1))
		draw_rect(Rect2(x0 + 10, -HT + 50.0, LEN - 20, 6), Color("c8a040"))
		draw_string(ThemeDB.fallback_font, Vector2(x0 + LEN * 0.5 - 22, -HT + 78.0), "BOCA", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e8dcc0"))
		for q in 2:   # גלגלים
			var gx := x0 + 40.0 + float(q) * (LEN - 80.0)
			draw_circle(Vector2(gx, -10), 10.0, Color("1a1a1e"))
			draw_circle(Vector2(gx, -10), 4.0, Color("6a6a70"))
		var front := x0 + LEN if dir > 0.0 else x0
		Art.glow(self, Vector2(front, -40), 40.0, Color(1.0, 0.95, 0.7, 0.5))
		draw_circle(Vector2(front, -40), 5.0, Color(1.0, 0.98, 0.85))
		draw_line(Vector2(x0 + LEN * 0.5, -HT + 4.0), Vector2(x0 + LEN * 0.5 - 30.0 * dir, -HT - 40.0), Color("16121c"), 2.0)   # פנטוגרף
		if Engine.get_physics_frames() % 4 < 2:
			draw_circle(Vector2(x0 + LEN * 0.5 - 30.0 * dir, -HT - 40.0), 3.0, Color(0.6, 0.85, 1.0))


# ---- כבל חשמלית קרוע על הרצפה הרטובה ----
class SparkWire extends Node2D:
	const CYCLE := Vector2(3.0, 5.0)
	const WARN_T := 0.9
	const ZAP_T := 0.6
	const R := 95.0
	const DMG_Z := 30
	var zaps := 0                    # לבדיקות
	var shocks := 0
	var state := 0                   # 0 = שקט, 1 = מתפצפץ, 2 = פורק
	var _t := 2.0
	var _tt := 0.0
	var _hit := {}

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-R, -90), Vector2(R * 2.0, 90))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != 0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t -= delta
		_tt += delta
		match state:
			0:
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					preload("res://sfx.gd").play("oq_crackle", global_position, -4.0, 0.1, 2)
			1:
				if _t <= 0.0:
					state = 2
					_t = ZAP_T
					zaps += 1
					_hit.clear()
					preload("res://sfx.gd").play("zap", global_position, 2.0, 0.1, 2)
					preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -4), "spark", Vector2.UP, 14)
			2:
				var pl := get_tree().get_first_node_in_group("player")
				if pl != null and not pl.dead and not _hit.has(0) and absf(pl.global_position.x - global_position.x) < R and absf(pl.global_position.y - global_position.y) < 30.0 and pl.is_on_floor():
					_hit[0] = true
					shocks += 1
					pl.hurt(1, Vector2(signf(pl.global_position.x - global_position.x + 0.01), -0.8))
				if Engine.get_physics_frames() % 4 == 0:
					for z in get_tree().get_nodes_in_group("zombies"):
						if z.dead or z.is_boss() or _hit.has(z.get_instance_id()):
							continue
						if absf(z.global_position.x - global_position.x) < R and absf(z.global_position.y - global_position.y) < 30.0:
							_hit[z.get_instance_id()] = true
							z.take_damage(DMG_Z, z.global_position + Vector2(0, -30), Vector2.UP, true, {"source": "hazard", "fixed": DMG_Z})
				if _t <= 0.0:
					state = 0
					_t = randf_range(CYCLE.x, CYCLE.y)
		if Art.on_screen(self, global_position + Vector2(0, -60), R + 80.0) and (state != 0 or Engine.get_physics_frames() % 6 == 0):
			queue_redraw()

	func _draw() -> void:
		# שלולית
		draw_colored_polygon(Art.ellipse(Vector2(0, -1), R, 4.0, 0.0, 20), Color(0.35, 0.45, 0.7, 0.35))
		# עמוד שבור עם הכבל משתלשל
		var px := -R - 16.0
		draw_rect(Rect2(px - 7.0, -8.0, 14.0, 8.0), Color("2a2430"))   # בסיס
		draw_line(Vector2(px, 0), Vector2(px + 3.0, -132), Color("16121c"), 6.0)
		draw_line(Vector2(px + 3.0, -126), Vector2(px + 34.0, -118), Color("16121c"), 3.0)   # זרוע שבורה
		draw_line(Vector2(px + 34.0, -118), Vector2(px + 44.0, -104), Color("16121c"), 3.0)
		draw_rect(Rect2(px + 38.0, -108, 8, 8), Color("6a6040"))   # מבודד
		var pts := PackedVector2Array()
		var sway := sin(_tt * 1.7) * 5.0
		var a0 := Vector2(px + 42.0, -100.0)
		for q in 12:
			var u := float(q) / 11.0
			pts.append(Vector2(lerpf(a0.x, 6.0, u) + sin(u * PI) * sway, lerpf(a0.y, -2.0, sqrt(u))))
		draw_polyline(pts, Color("101014"), 2.0)
		var tip := pts[pts.size() - 1]
		if state == 1:   # מתפצפץ
			for q in 4:
				var a := randf() * TAU
				draw_line(tip, tip + Vector2.from_angle(a) * randf_range(6.0, 16.0), Color(0.7, 0.9, 1.0, 0.9), 1.2)
			Art.glow(self, tip, 16.0, Color(0.6, 0.85, 1.0, 0.5))
		elif state == 2:   # פריקה על כל השלולית
			Art.glow(self, tip, 40.0, Color(0.6, 0.85, 1.0, 0.6))
			for q in 7:
				var ex := randf_range(-R, R)
				var p0 := tip
				var seg := PackedVector2Array([p0])
				for s in 4:
					seg.append(p0.lerp(Vector2(ex, -2), float(s + 1) / 4.0) + Vector2(0, randf_range(-8, 4)))
				draw_polyline(seg, Color(0.75, 0.92, 1.0, 0.95), 1.6)
			draw_colored_polygon(Art.ellipse(Vector2(0, -2), R, 6.0, 0.0, 20), Color(0.6, 0.85, 1.0, 0.35))
		else:
			if int(_tt * 3.0) % 5 == 0:
				draw_circle(tip, 2.0, Color(0.7, 0.9, 1.0, 0.8))


# ---- במת הטנגו של קמיניטו (רחבת הבוס) ----
class TangoStage extends Node2D:
	var w := 560.0
	var tier := 70.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		# חזיתות קמיניטו צבעוניות מאחור - בגבהים שונים, עם חלונות ותריסים
		var n := 6
		var bw := w / float(n)
		for q in n:
			var c: Color = HOUSE_COLS[(q * 2 + 1) % HOUSE_COLS.size()].darkened(0.28)
			var hh := 150.0 + float((q * 37) % 5) * 14.0
			var r := Rect2(float(q) * bw + 3.0, -tier - hh, bw - 6.0, hh)
			draw_rect(r, c)
			draw_rect(Rect2(r.position.x - 3.0, r.position.y - 6.0, r.size.x + 6.0, 6.0), c.darkened(0.4))   # כרכוב
			for k in 6:   # פסי פח
				var lx := r.position.x + 6.0 + float(k) * (r.size.x - 12.0) / 5.0
				draw_line(Vector2(lx, r.position.y), Vector2(lx, -tier), c.darkened(0.15), 1.0)
			for k in 2:   # חלונות עם תריסים ירוקים
				var wx := r.position.x + r.size.x * (0.28 + 0.44 * float(k)) - 9.0
				var wy := r.position.y + 22.0
				draw_rect(Rect2(wx, wy, 18, 26), Color(1.0, 0.78, 0.45, 0.85) if (q + k) % 3 != 0 else Color("1a1420"))
				draw_rect(Rect2(wx - 7.0, wy, 6, 26), Color("2e6a4a"))
				draw_rect(Rect2(wx + 19.0, wy, 6, 26), Color("2e6a4a"))
		# שלט מעוטר על עמודים
		var sx := w * 0.5 - 120.0
		var sy := -tier - 232.0
		draw_line(Vector2(sx + 20.0, sy + 50.0), Vector2(sx + 20.0, -tier), Color("16121c"), 3.0)
		draw_line(Vector2(sx + 220.0, sy + 50.0), Vector2(sx + 220.0, -tier), Color("16121c"), 3.0)
		draw_rect(Rect2(sx, sy, 240, 52), Color("141018"))
		draw_rect(Rect2(sx + 4, sy + 4.0, 232, 44), Color("1e2a3a"))
		for q in 2:
			draw_arc(Vector2(sx + 18.0 + float(q) * 204.0, sy + 26.0), 7.0, 0.0, PI * 1.5, 8, Color("e0b030"), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(sx + 36, sy + 38.0), "CAMINITO", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("f0d070"))
		# הבמה: קרשים + מנורות
		draw_rect(Rect2(0, -tier, w, tier), Color("3a2418"))
		for q in int(w / 40.0):
			draw_line(Vector2(float(q) * 40.0, -tier), Vector2(float(q) * 40.0, 0), Color("2a180e"), 1.5)
		draw_rect(Rect2(-4, -tier - 4.0, w + 8, 6), Color("6a4a30"))
		for q in 8:
			var lx := 30.0 + float(q) * (w - 60.0) / 7.0
			draw_line(Vector2(lx, -tier - 4.0), Vector2(lx, -tier - 120.0), Color("16121c"), 1.0)
			draw_circle(Vector2(lx, -tier - 120.0), 4.0, Color(1.0, 0.85, 0.5))
			Art.glow(self, Vector2(lx, -tier - 120.0), 16.0, Color(1.0, 0.8, 0.4, 0.4))
		draw_line(Vector2(30, -tier - 120.0), Vector2(w - 30.0, -tier - 120.0), Color("16121c"), 1.0)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "kiosk"
	var size := Vector2(60, 70)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		if size.y >= 30.0:
			add_to_group("cover")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)
		z_index = 1

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		match kind:
			"kiosk":   # קיוסק עיתונים ירוק עם עיטורים
				draw_rect(Rect2(0, -h * 0.8, w, h * 0.8), Color("1e4a32"))
				draw_colored_polygon(PackedVector2Array([Vector2(-6, -h * 0.8), Vector2(w * 0.5, -h), Vector2(w + 6, -h * 0.8)]), Color("163828"))
				draw_rect(Rect2(6, -h * 0.7, w - 12, h * 0.3), Color(1.0, 0.8, 0.5, 0.7))
				for q in 4:   # עיתונים
					draw_rect(Rect2(8.0 + float(q) * (w - 16.0) / 4.0, -h * 0.65, (w - 20.0) / 4.0, h * 0.2), Color("e8e0d0") if q % 2 == 0 else Color("c8b8a0"))
				draw_line(Vector2(0, -h * 0.8), Vector2(w, -h * 0.8), Color("e0b030"), 2.0)
				draw_arc(Vector2(w * 0.5, -h * 0.28), 6.0, 0.0, PI * 1.5, 8, Color("e0b030"), 1.5)
			"cart":   # עגלת צ'וריפאן עם גריל ועשן
				draw_rect(Rect2(0, -h * 0.75, w, h * 0.45), Color("8a2a20"))
				draw_rect(Rect2(0, -h * 0.78, w, 5), Color("2a2a2e"))
				for q in 5:
					draw_line(Vector2(6.0 + float(q) * (w - 12.0) / 4.0, -h * 0.8), Vector2(6.0 + float(q) * (w - 12.0) / 4.0, -h * 0.76), Color("e07030"), 2.0)
				draw_line(Vector2(w * 0.1, -h * 0.3), Vector2(w * 0.1, -6), Color("2a2a2e"), 2.0)
				draw_line(Vector2(w * 0.9, -h * 0.3), Vector2(w * 0.9, -6), Color("2a2a2e"), 2.0)
				draw_circle(Vector2(w * 0.2, -6), 6.0, Color("1a1a1e"))
				draw_circle(Vector2(w * 0.8, -6), 6.0, Color("1a1a1e"))
				draw_line(Vector2(0, -h * 0.75), Vector2(-4, -h), Color("c8b8a0"), 2.0)   # שמשייה
				draw_colored_polygon(PackedVector2Array([Vector2(-30, -h - 2), Vector2(-4, -h - 14), Vector2(22, -h - 2)]), Color("e8c040"))
				draw_string(ThemeDB.fallback_font, Vector2(4, -h * 0.4), "CHORI", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("f0d070"))
			_:   # עציץ ענק עם עץ טיפה
				draw_rect(Rect2(0, -h * 0.45, w, h * 0.45), Color("7a6a5a"))
				draw_rect(Rect2(-3, -h * 0.48, w + 6, 5), Color("9a8a78"))
				draw_line(Vector2(w * 0.5, -h * 0.45), Vector2(w * 0.5, -h * 0.9), Color("3a2a1e"), 4.0)
				for q in 7:
					draw_circle(Vector2(w * 0.5 + sin(float(q) * 2.1) * w * 0.35, -h * 0.9 - cos(float(q) * 1.7) * 10.0), 9.0, Color("1e3a24"))
				for q in 5:
					draw_circle(Vector2(w * 0.5 + sin(float(q) * 3.1) * w * 0.3, -h * 0.92 - cos(float(q) * 2.3) * 9.0), 2.5, Color("b04ab0"))   # פרחי ג'קרנדה


# ---- מסך: ערפל נהר ועשים סביב האור ----
class QuarterFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		var n: int = Quality.scaled(14, Quality.ambient())
		for i in n:   # ערפל נמוך שזז לאט
			var x := fposmod(float(i) * 137.0 + _t * (8.0 + float(i % 3) * 4.0), vp.x + 300.0) - 150.0
			var y := vp.y * 0.78 + sin(_t * 0.3 + float(i)) * 20.0 + float(i % 4) * 16.0
			draw_colored_polygon(Art.ellipse(Vector2(x, y), 120.0, 18.0, 0.0, 14), Color(0.55, 0.6, 0.8, 0.045))
		for i in 8:   # חרקים ליד האור
			var c := Vector2(fposmod(float(i) * 211.0, vp.x), vp.y * 0.3 + float(i % 3) * 30.0)
			var p := c + Vector2(sin(_t * (3.0 + float(i)) + float(i)) * 14.0, cos(_t * (2.3 + float(i) * 0.7)) * 9.0)
			draw_circle(p, 1.2, Color(1.0, 0.9, 0.7, 0.35))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.15, 0.1, 0.3, 0.05))
