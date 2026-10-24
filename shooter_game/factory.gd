extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  עולם המפעל (שלב 3: THEY BUILD). main.gd יוצר אותו.
#  הזומבים השתלטו על מפעל ובונים בו מכונות.
#  * רקע: ארובות עם עשן, עגורנים, מיכלים, תנורים זוהרים, גצים באוויר
#  * ריצפה: בטון עם פסי אזהרה צהוב-שחור וכתמי שמן
# ============================================================

var floor_y := 630.0
var level_w := 10240.0


func _ready() -> void:
	var x := 0.0
	while x < level_w:   # קישוטי ריצפה (מצוירים פעם אחת)
		var c := Chunk.new()
		c.floor_y = floor_y
		c.position = Vector2(x, 0.0)
		get_parent().add_child.call_deferred(c)
		x += 1024.0


class Chunk extends Node2D:
	var floor_y := 630.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(position.x) + 333
		var w := 1024.0
		var y := floor_y
		DrawBatch.rect(self, Rect2(0, y, w, 4), Color("4a4640"))   # שפת בטון
		var x := rng.randf_range(0.0, 200.0)
		while x < w - 120.0:   # פסי אזהרה
			var len := rng.randf_range(90.0, 180.0)
			DrawBatch.rect(self, Rect2(x, y + 1, len, 5), Color("c8a020"))
			var sx := x
			while sx < x + len - 6.0:
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(sx, y + 6), Vector2(sx + 6, y + 1), Vector2(sx + 11, y + 1), Vector2(sx + 5, y + 6)]), Color("1a1a1a"))
				sx += 12.0
			x += len + rng.randf_range(250.0, 500.0)
		for i in 5:   # כתמי שמן
			var ox := rng.randf_range(0.0, w)
			DrawBatch.set_transform(self, Vector2(ox, y + 8), 0.0, Vector2(1.0, 0.25))
			DrawBatch.circle(self, Vector2.ZERO, rng.randf_range(10.0, 26.0), Color(0.05, 0.05, 0.06, 0.6))
			DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
		for i in 10:   # ברגים וחלקים זרוקים
			var bx := rng.randf_range(0.0, w)
			DrawBatch.rect(self, Rect2(bx, y - 2, rng.randf_range(2.0, 6.0), 2), Color("6a6660"))


# רקע: אזור תעשייה הרוס בשקיעה מעושנת - שמיים + 3 שכבות פרלקסה (effects/parallax_backdrop.gd)
#   רחוק: מגדלי קירור עם אדים, ארובות עם נורות אדומות, לפיד גז
#   אמצע: בית זיקוק - מיכלים, כדורי גז, עמודי זיקוק עם אורות, תנור עם חלונות זוהרים
#   קרוב: צינורות ענק עם שסתומים שיורקים קיטור, עגורן עם מטען מתנדנד, פנסי נתרן
#   overlay: אובך חם מאחורי הדמויות (שהצלליות הכהות ייקראו) + גצים עולים
class FactoryBg extends "res://effects/parallax_backdrop.gd":
	const Kit := preload("res://effects/backdrop_kit.gd")
	const HZ := 607.0                       # קו הכביש על המסך
	const FAR := Color("6a3c32")            # שכבה רחוקה (באובך)
	const MID := Color("3c2420")
	const NEAR := Color("1f1513")
	const LAMP := Color(1.0, 0.72, 0.38)

	func _ready() -> void:
		sky = func(ci: CanvasItem, v: Vector2, t: float): _sky(ci, v, t)
		add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float): _far(ci, sc, v, t))
		add_layer(0.22, func(ci: CanvasItem, sc: float, v: Vector2, t: float): _mid(ci, sc, v, t))
		add_layer(0.5, func(ci: CanvasItem, sc: float, v: Vector2, t: float): _near(ci, sc, v, t))
		overlay = func(ci: CanvasItem, v: Vector2, t: float): _over(ci, v, t)

	static func _h(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)

	static func _sky(ci: CanvasItem, v: Vector2, t: float) -> void:
		Kit.gradient_sky(ci, v, [Color("1a1216"), Color("33191a"), Color("5e2c1e"), Color("a24f26"), Color("d8823c")], 0.86)
		var sp := Vector2(v.x * 0.68, 300.0)
		Kit.soft_glow(ci, sp, 330.0, Color(1.0, 0.5, 0.2, 0.32))
		Kit.soft_glow(ci, sp, 120.0, Color(1.0, 0.7, 0.4, 0.4))
		DrawBatch.circle(ci, sp, 54.0, Color(1.0, 0.66, 0.38, 0.92))
		for i in 4:   # פסי עשן שזזים על השמש
			var y := sp.y - 34.0 + float(i) * 20.0
			var x := fposmod(t * (6.0 + float(i) * 2.0) + float(i) * 90.0, 260.0) - 130.0
			DrawBatch.rect(ci, Rect2(sp.x - 180.0 + x, y, 300.0, 4.0 + float(i)), Color(0.35, 0.16, 0.12, 0.35))
		for i in 7:   # ענני עשן רכים שנסחפים (כתם אחד לכל ענן - זול)
			var cx := fposmod(float(i) * 260.0 - t * (5.0 + float(i % 3) * 3.0), v.x + 500.0) - 250.0
			var cy := 60.0 + float(i % 4) * 48.0
			Kit.soft_ellipse(ci, Vector2(cx, cy), 230.0, 46.0, 0.0, Color(0.12, 0.07, 0.07, 0.55) if i % 2 == 0 else Color(0.32, 0.15, 0.1, 0.4))
		Kit.birds(ci, v, t, 33, Color(0.08, 0.04, 0.04, 0.8), 6)

	# ---- רחוק: מגדלי קירור, ארובות, לפיד ----
	static func _far(ci: CanvasItem, sc: float, v: Vector2, t: float) -> void:
		var base := HZ - 40.0
		DrawBatch.rect(ci, Rect2(0, base - 10.0, v.x, v.y - base + 10.0), FAR)
		var period := 1150.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(ceil(v.x / period)) + 2):
			var bx := float(k) * period - sc
			for c in 2:   # מגדל קירור (היפרבולואיד) + אדים
				var cx := bx + 140.0 + float(c) * 190.0
				var hw := 62.0 + 10.0 * _h(k, c)
				var h := 210.0 + 30.0 * _h(k, c + 7)
				var pts := PackedVector2Array()
				for q in 9:
					var u := float(q) / 8.0
					pts.append(Vector2(cx - hw * (0.62 + 0.38 * pow(absf(u - 0.62) / 0.62, 1.6)), base - h * u))
				for q in range(8, -1, -1):
					var u := float(q) / 8.0
					pts.append(Vector2(cx + hw * (0.62 + 0.38 * pow(absf(u - 0.62) / 0.62, 1.6)), base - h * u))
				DrawBatch.colored_polygon(ci, pts, FAR.darkened(0.06))
				DrawBatch.line(ci, Vector2(cx - hw * 0.62, base - h * 0.62), Vector2(cx + hw * 0.62, base - h * 0.62), FAR.lightened(0.06), 2.0)
				for p in 7:   # אדים לבנבנים
					var a := fmod(t * 0.07 + float(p) / 7.0 + float(c) * 0.37, 1.0)
					var pp := Vector2(cx + a * 120.0 + sin(a * 5.0 + t * 0.3) * 10.0, base - h - a * 170.0)
					Kit.soft_glow(ci, pp, 40.0 + a * 70.0, Color(0.88, 0.66, 0.54, 0.4 * (1.0 - a) * clampf(a * 5.0, 0.0, 1.0)))
			for q in 3:   # ארובות פסים + נורה אדומה מהבהבת
				var chx := bx + 520.0 + float(q) * 70.0 + 30.0 * _h(k, q + 3)
				var chh := 250.0 + 70.0 * _h(k, q + 11)
				DrawBatch.rect(ci, Rect2(chx, base - chh, 16.0, chh), FAR.darkened(0.12))
				for s in 3:
					DrawBatch.rect(ci, Rect2(chx, base - chh + 10.0 + float(s) * 26.0, 16.0, 10.0), Color(0.55, 0.26, 0.22, 0.6))
				Kit.soft_smoke(ci, Vector2(chx + 8.0, base - chh), t * 0.8 + float(q * 3 + k), 230.0, Color(0.22, 0.13, 0.12, 0.3), 90.0)
				if fmod(t * 0.9 + float(q) * 0.6, 1.6) < 0.55:
					Kit.soft_glow(ci, Vector2(chx + 8.0, base - chh - 4.0), 14.0, Color(1.0, 0.15, 0.1, 0.9))
			# לפיד גז על עמוד דק
			var fx := bx + 900.0
			DrawBatch.rect(ci, Rect2(fx - 3.0, base - 300.0, 6.0, 300.0), FAR.darkened(0.15))
			var fl := 0.8 + 0.2 * sin(t * 9.0 + float(k)) + 0.1 * sin(t * 23.0)
			Kit.soft_glow(ci, Vector2(fx, base - 316.0), 60.0 * fl, Color(1.0, 0.55, 0.2, 0.45))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(fx - 5, base - 300), Vector2(fx + sin(t * 6.0) * 6.0, base - 300.0 - 34.0 * fl), Vector2(fx + 5, base - 300)]), Color(1.0, 0.8, 0.4, 0.9))
			# בתים נמוכים עם חלונות
			var hx := bx + 640.0
			DrawBatch.rect(ci, Rect2(hx, base - 70.0, 220.0, 70.0), FAR.darkened(0.08))
			for w in 9:
				if _h(k * 13 + w, 5) < 0.55:
					DrawBatch.rect(ci, Rect2(hx + 12.0 + float(w) * 23.0, base - 52.0, 8.0, 8.0), Color(1.0, 0.7, 0.35, 0.55))
		Kit.haze_band(ci, v, base - 220.0, base, Color(0.85, 0.45, 0.28, 0.28))

	# ---- אמצע: בית זיקוק ----
	static func _mid(ci: CanvasItem, sc: float, v: Vector2, t: float) -> void:
		var base := HZ - 12.0
		var period := 1400.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(ceil(v.x / period)) + 2):
			var bx := float(k) * period - sc
			# מיכלי אחסון גליליים
			for c in 2:
				var tx := bx + 60.0 + float(c) * 170.0
				var tw := 140.0
				var th := 110.0 + 30.0 * _h(k, c)
				DrawBatch.rect(ci, Rect2(tx, base - th, tw, th), MID)
				DrawBatch.rect(ci, Rect2(tx, base - th, tw, 6.0), MID.lightened(0.12))
				for s in 4:   # תפרים
					DrawBatch.line(ci, Vector2(tx + 18.0 + float(s) * 34.0, base - th + 6.0), Vector2(tx + 18.0 + float(s) * 34.0, base), MID.darkened(0.2), 1.0)
				DrawBatch.line(ci, Vector2(tx + tw - 14.0, base), Vector2(tx + 14.0, base - th), MID.lightened(0.08), 2.0)   # מדרגות סביב המיכל
				DrawBatch.rect(ci, Rect2(tx + 10.0, base - th * 0.5, 40.0, 14.0), Color(0.5, 0.42, 0.18, 0.5))   # שלט סכנה דהוי
			# כדורי גז על רגליים
			var gx := bx + 470.0
			for l in 4:
				DrawBatch.line(ci, Vector2(gx - 60.0 + float(l) * 40.0, base), Vector2(gx - 50.0 + float(l) * 33.0, base - 90.0), MID.darkened(0.1), 4.0)
			DrawBatch.circle(ci, Vector2(gx, base - 120.0), 72.0, MID)
			DrawBatch.arc(ci, Vector2(gx, base - 120.0), 66.0, -2.4, -1.0, 12, MID.lightened(0.14), 3.0)   # אור שקיעה על הכדור
			# עמודי זיקוק עם פלטפורמות ונורות
			for c in 3:
				var cx := bx + 640.0 + float(c) * 52.0
				var ch := 260.0 + 60.0 * _h(k, c + 20)
				DrawBatch.rect(ci, Rect2(cx, base - ch, 24.0 - float(c) * 4.0, ch), MID.darkened(0.05))
				var pl := base - ch + 30.0
				while pl < base - 20.0:
					DrawBatch.rect(ci, Rect2(cx - 8.0, pl, 40.0, 3.0), MID.lightened(0.05))
					if _h(int(pl) + k, c) < 0.5:
						DrawBatch.circle(ci, Vector2(cx - 6.0, pl - 3.0), 1.8, LAMP)
					pl += 48.0
				if fmod(t + float(c) * 0.5, 2.0) < 0.7:
					DrawBatch.circle(ci, Vector2(cx + 8.0, base - ch - 4.0), 2.5, Color(1.0, 0.2, 0.15))
			# מתלה צינורות שמחבר הכל
			DrawBatch.rect(ci, Rect2(bx + 20.0, base - 70.0, 760.0, 7.0), MID.darkened(0.15))
			DrawBatch.rect(ci, Rect2(bx + 20.0, base - 60.0, 760.0, 4.0), MID.lightened(0.06))
			for s in 9:
				DrawBatch.rect(ci, Rect2(bx + 30.0 + float(s) * 92.0, base - 70.0, 5.0, 70.0), MID.darkened(0.15))
			# תנור / בית יציקה עם חלונות זוהרים מהבהבים
			var fx := bx + 860.0
			DrawBatch.rect(ci, Rect2(fx, base - 170.0, 300.0, 170.0), MID.darkened(0.1))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(fx - 10, base - 170), Vector2(fx + 150, base - 215), Vector2(fx + 310, base - 170)]), MID.darkened(0.1))
			var fl := 0.65 + 0.2 * sin(t * 2.6 + float(k)) + 0.1 * sin(t * 13.0 + float(k))
			for w in 5:
				var wx := fx + 22.0 + float(w) * 56.0
				DrawBatch.rect(ci, Rect2(wx, base - 120.0, 34.0, 50.0), Color(1.0, 0.5, 0.15, 0.75 * fl))
				DrawBatch.rect(ci, Rect2(wx + 15.0, base - 120.0, 3.0, 50.0), MID.darkened(0.1))
			Kit.soft_glow(ci, Vector2(fx + 150.0, base - 95.0), 190.0, Color(1.0, 0.45, 0.15, 0.22 * fl), 0.5)
			for q in 2:   # ארובות התנור
				var sx := fx + 60.0 + float(q) * 170.0
				DrawBatch.rect(ci, Rect2(sx, base - 290.0, 20.0, 120.0), MID.darkened(0.15))
				Kit.soft_smoke(ci, Vector2(sx + 10.0, base - 290.0), t + float(q * 2 + k), 200.0, Color(0.14, 0.09, 0.09, 0.4), 70.0)
			# מסוע משופע אל המגדל
			DrawBatch.line(ci, Vector2(bx + 1180.0, base), Vector2(bx + 1360.0, base - 230.0), MID.darkened(0.12), 10.0)
			for s in 8:
				var u := float(s) / 8.0
				var a := Vector2(bx + 1180.0, base).lerp(Vector2(bx + 1360.0, base - 230.0), u)
				DrawBatch.line(ci, a, a + Vector2(0.0, 18.0), MID.darkened(0.12), 2.0)
			DrawBatch.rect(ci, Rect2(bx + 1340.0, base - 260.0, 70.0, 260.0), MID.darkened(0.08))
			DrawBatch.rect(ci, Rect2(bx + 1352.0, base - 240.0, 16.0, 12.0), Color(1.0, 0.75, 0.4, 0.6))
		DrawBatch.rect(ci, Rect2(0, base, v.x, v.y - base), MID.darkened(0.2))
		Kit.haze_band(ci, v, base - 140.0, base, Color(0.8, 0.4, 0.22, 0.2))

	# ---- קרוב: צינורות ענק, עגורן, פנסים ----
	static func _near(ci: CanvasItem, sc: float, v: Vector2, t: float) -> void:
		var period := 1000.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(ceil(v.x / period)) + 2):
			var bx := float(k) * period - sc
			# צינור עבה עולה מהקרקע ופונה אופקית (גבוה - לא מאחורי הדמויות)
			var py := 250.0 + 40.0 * _h(k, 1)
			DrawBatch.rect(ci, Rect2(bx + 40.0, py, 26.0, HZ - py), NEAR)
			DrawBatch.rect(ci, Rect2(bx + 40.0, py, 560.0, 26.0), NEAR)
			DrawBatch.rect(ci, Rect2(bx + 40.0, py + 2.0, 560.0, 4.0), Color(0.55, 0.3, 0.2, 0.35))   # אור שקיעה על הצינור
			for f in 5:   # אוגנים
				DrawBatch.rect(ci, Rect2(bx + 110.0 + float(f) * 110.0, py - 4.0, 8.0, 34.0), NEAR.lightened(0.04))
			DrawBatch.rect(ci, Rect2(bx + 594.0, py - 6.0, 14.0, HZ - py + 6.0), NEAR)
			# שסתום שיורק קיטור מדי פעם
			var vx := bx + 330.0
			DrawBatch.circle(ci, Vector2(vx, py - 10.0), 9.0, NEAR)
			DrawBatch.line(ci, Vector2(vx - 12.0, py - 18.0), Vector2(vx + 12.0, py - 18.0), NEAR, 3.0)
			var ph := fmod(t * 0.35 + _h(k, 4), 1.0)
			if ph < 0.4:
				var e := ph / 0.4
				for p in 6:
					var pp := Vector2(vx + float(p) * 9.0 * e + 6.0, py - 22.0 - float(p) * 16.0 * e)
					Kit.soft_glow(ci, pp, 10.0 + float(p) * 6.0 * e, Color(0.92, 0.84, 0.78, 0.4 * (1.0 - e)))
			# עגורן גשר עם מטען מתנדנד
			var gx := bx + 700.0
			DrawBatch.rect(ci, Rect2(gx, 170.0, 10.0, HZ - 170.0), NEAR)
			DrawBatch.rect(ci, Rect2(gx - 80.0, 160.0, 330.0, 12.0), NEAR)
			for s in 11:
				DrawBatch.line(ci, Vector2(gx - 80.0 + float(s) * 30.0, 172.0), Vector2(gx - 65.0 + float(s) * 30.0, 160.0), NEAR.lightened(0.05), 2.0)
			var sw := sin(t * 0.7 + float(k)) * 0.06
			var hk := Vector2(gx + 180.0, 172.0)
			var ld := hk + Vector2(sin(sw) * 150.0, cos(sw) * 150.0)
			DrawBatch.line(ci, hk, ld, NEAR, 2.0)
			DrawBatch.set_transform(ci, ld, -sw, Vector2.ONE)
			DrawBatch.rect(ci, Rect2(-36.0, 0.0, 72.0, 36.0), NEAR.lightened(0.03))
			DrawBatch.rect(ci, Rect2(-36.0, 0.0, 72.0, 4.0), Color(0.75, 0.6, 0.2, 0.5))
			DrawBatch.set_transform_matrix(ci, Transform2D.IDENTITY)
			# פנס נתרן גבוה
			var lx := bx + 900.0
			DrawBatch.rect(ci, Rect2(lx, 300.0, 6.0, HZ - 300.0), NEAR)
			DrawBatch.line(ci, Vector2(lx + 3.0, 302.0), Vector2(lx + 40.0, 296.0), NEAR, 4.0)
			var on := 1.0 if fmod(t * 1.7 + float(k) * 3.1, 9.0) > 0.25 else 0.3
			Kit.soft_glow(ci, Vector2(lx + 40.0, 304.0), 70.0, Color(LAMP, 0.35 * on))
			DrawBatch.rect(ci, Rect2(lx + 32.0, 298.0, 18.0, 6.0), Color(LAMP, 0.9 * on))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(lx + 30, 304), Vector2(lx + 52, 304), Vector2(lx + 110, HZ), Vector2(lx - 30, HZ)]), Color(LAMP, 0.05 * on))

	# ---- overlay: אובך מאחורי הדמויות + גצים ----
	static func _over(ci: CanvasItem, v: Vector2, t: float) -> void:
		Kit.haze_band(ci, v, HZ - 190.0, HZ + 4.0, Color(0.78, 0.42, 0.26, 0.26))
		for i in 34:   # גצים עולים
			var sp := 18.0 + float(i % 5) * 6.0
			var x := fposmod(float(i) * 97.0 + sin(t * 1.3 + float(i)) * 14.0, v.x)
			var y := v.y - fposmod(t * sp + float(i) * 61.0, v.y + 40.0)
			DrawBatch.rect(ci, Rect2(x, y, 2.0, 2.0), Color(1.0, 0.62, 0.25, 0.75))
