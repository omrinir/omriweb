extends RefCounted
# ============================================================
#  קישוטים לשלב 18 ("THE QUARRY") - מחצבה פתוחה בשמש של צהריים. הכל מואר, צבעים חמים ובהירים.
#    quarry_sky    - שמיים כחולים בהירים, שמש לבנה חזקה עם קרניים, עננים לבנים זזים
#    terraces      - קירות המחצבה הרחוקים: מדרגות אבן בהירות (ספסלים), משאיות קטנטנות עליהן
#    machines      - מכונות כרייה ענקיות באמצע: מחפר גלגל-דליים, מסועים על רגליים, מגדל מגרסה, עגורן
#    gravel        - ערמות חצץ, גדרות בטיחות כתומות, קונוסים, שלטי "DANGER - BLASTING"
#    QuarryGround  - (עולם) רצפת חצץ מעל הכביש: אבנים, עקבות צמיגים, כתמי אבק
#    Obstacle      - (מוצק + מחסה) "blocks" ערמת אבני גיר חתוכות / "truck" משאית מכרה ענקית (אפשר לעלות)
#                    / "cart" עגלת מכרה על מסילה / "drill_rig" אסדת קידוח קטנה
#    SunGlare      - (מסך) קרני שמש רכות מהפינה + חום צהבהב קל
# ============================================================

const Art := preload("res://art.gd")

const STONE := Color("e6d6b6")       # אבן גיר בהירה
const STONE_D := Color("bfa883")
const STONE_L := Color("f4ead6")
const DIRT := Color("c9b088")
const GROUND := Color("a88c64")
const PAINT := Color("e2a224")       # צהוב מכרה
const SAFETY := Color("ff7a1a")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- שמיים: כחול בהיר, שמש לבנה, עננים ----
static func quarry_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	var steps := 12
	for i in steps:
		var k := float(i) / float(steps - 1)
		ci.draw_rect(Rect2(0, v.y * k * 0.85, v.x, v.y * 0.85 / float(steps) + 1.0), Color("6fb4ec").lerp(Color("dcefff"), k))
	ci.draw_rect(Rect2(0, v.y * 0.85, v.x, v.y * 0.15), Color("e8f2fb"))
	var sun := Vector2(v.x * 0.8, 86.0)
	for i in 10:   # קרניים
		var a := float(i) * TAU / 10.0 + t * 0.04
		ci.draw_colored_polygon(PackedVector2Array([sun, sun + Vector2.from_angle(a - 0.06) * 420.0, sun + Vector2.from_angle(a + 0.06) * 420.0]), Color(1.0, 1.0, 0.92, 0.06))
	for r in [120.0, 80.0, 52.0]:
		ci.draw_circle(sun, r, Color(1.0, 0.98, 0.85, 0.12))
	ci.draw_circle(sun, 34.0, Color(1.0, 1.0, 0.96))
	for i in 5:   # עננים
		var cx := fposmod(float(i) * 330.0 + t * (6.0 + float(i)), v.x + 400.0) - 200.0
		var cy := 70.0 + float(i % 3) * 46.0
		for q in 5:
			ci.draw_circle(Vector2(cx + float(q) * 26.0 - 52.0, cy - absf(float(q) - 2.0) * -6.0 - 10.0 + (8.0 if q % 2 == 0 else 0.0)), 22.0 - absf(float(q) - 2.0) * 3.0, Color(1, 1, 1, 0.85))


# ---- קירות המחצבה (מדרגות אבן) ----
static func terraces(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1400.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 61 + 11)
		var top := y - r.randf_range(230.0, 300.0)
		var steps := 5
		for s in steps:   # מדרגות: כל אחת קצת יותר בהירה ורחוקה
			var sy := top + float(s) * (y - top) / float(steps)
			var inset := float(steps - s) * 18.0
			var col := STONE.lerp(Color("cfe3f3"), 0.45 - float(s) * 0.07)
			var pts := PackedVector2Array([Vector2(x - 40.0, y), Vector2(x - 40.0, sy + 6.0)])
			var px := x - 40.0
			while px < x + period + 40.0:
				pts.append(Vector2(px, sy + r.randf_range(-6.0, 6.0) + inset * 0.2))
				px += r.randf_range(60.0, 140.0)
			pts.append(Vector2(x + period + 40.0, sy))
			pts.append(Vector2(x + period + 40.0, y))
			ci.draw_colored_polygon(pts, col)
			ci.draw_line(Vector2(x - 40.0, sy + 3.0), Vector2(x + period + 40.0, sy + 3.0), Color(STONE_D, 0.35), 2.0)
			if r.randf() < 0.7:   # משאית קטנטנה על המדרגה
				var tx := x + fposmod(r.randf_range(0.0, period) + t * r.randf_range(8.0, 18.0) * (1.0 if s % 2 == 0 else -1.0), period)
				ci.draw_rect(Rect2(tx, sy - 7.0, 14.0, 6.0), Color(PAINT, 0.6))
				ci.draw_rect(Rect2(tx + 10.0, sy - 10.0, 5.0, 4.0), Color(PAINT, 0.6))
		for i in 6:   # קווי שכבות בסלע
			var lx := x + r.randf_range(0.0, period)
			ci.draw_line(Vector2(lx, top + 30.0), Vector2(lx + r.randf_range(-20, 20), y - 10.0), Color(STONE_D, 0.18), 1.5)


# ---- מכונות כרייה ענקיות ----
static func machines(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1700.0
	var start := int(floor(sc / period)) - 1
	var mcol := Color(0.62, 0.55, 0.45, 0.85)
	var acc := Color(PAINT.r, PAINT.g, PAINT.b, 0.8)
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 97 + 5)
		# מחפר גלגל-דליים: גוף, זרוע ארוכה, גלגל מסתובב
		var bx := x + r.randf_range(100.0, 500.0)
		ci.draw_rect(Rect2(bx, y - 90.0, 150.0, 70.0), mcol)
		ci.draw_rect(Rect2(bx + 10.0, y - 20.0, 130.0, 20.0), Color(0.4, 0.36, 0.32, 0.85))
		ci.draw_rect(Rect2(bx + 20.0, y - 120.0, 40.0, 30.0), acc)
		var arm_end := Vector2(bx + 330.0, y - 150.0)
		ci.draw_line(Vector2(bx + 140.0, y - 80.0), arm_end, mcol, 10.0)
		ci.draw_line(Vector2(bx + 60.0, y - 140.0), arm_end, Color(0.3, 0.3, 0.3, 0.6), 2.0)   # כבל
		var wa := t * 0.6
		ci.draw_arc(arm_end, 46.0, 0.0, TAU, 28, mcol, 6.0)
		for i in 8:
			var a := wa + float(i) * TAU / 8.0
			var bp := arm_end + Vector2.from_angle(a) * 46.0
			ci.draw_line(arm_end, bp, Color(mcol, 0.6), 2.0)
			ci.draw_rect(Rect2(bp - Vector2(7, 7), Vector2(14, 14)), acc)
		# מסוע על רגליים עולה למגדל מגרסה
		var cx := x + r.randf_range(700.0, 1000.0)
		var c0 := Vector2(cx, y - 30.0)
		var c1 := Vector2(cx + 380.0, y - 210.0)
		ci.draw_line(c0, c1, mcol, 8.0)
		for i in 5:
			var p := c0.lerp(c1, float(i) / 4.0)
			ci.draw_line(p, Vector2(p.x, y), Color(mcol, 0.7), 3.0)
		for i in 8:   # סלעים על המסוע זזים למעלה
			var u := fposmod(float(i) / 8.0 + t * 0.05, 1.0)
			ci.draw_circle(c0.lerp(c1, u) + Vector2(0, -6), 4.0, Color(STONE_D, 0.9))
		ci.draw_rect(Rect2(c1.x - 20.0, c1.y - 30.0, 90.0, y - c1.y + 30.0), mcol)   # מגדל
		ci.draw_rect(Rect2(c1.x - 10.0, c1.y - 20.0, 20.0, 14.0), Color(0.2, 0.3, 0.4, 0.6))
		ci.draw_rect(Rect2(c1.x - 20.0, c1.y - 30.0, 90.0, 6.0), acc)
		# עגורן
		var kx := x + r.randf_range(1250.0, 1550.0)
		ci.draw_line(Vector2(kx, y), Vector2(kx, y - 260.0), mcol, 6.0)
		ci.draw_line(Vector2(kx - 60.0, y - 250.0), Vector2(kx + 200.0, y - 250.0), mcol, 5.0)
		var hook := kx + 120.0 + sin(t * 0.4 + float(k)) * 40.0
		ci.draw_line(Vector2(hook, y - 250.0), Vector2(hook, y - 170.0), Color(0.25, 0.25, 0.25, 0.7), 1.5)
		ci.draw_rect(Rect2(hook - 14.0, y - 170.0, 28.0, 18.0), Color(STONE_D, 0.9))


# ---- ערמות חצץ, גדרות כתומות, קונוסים, שלטים ----
static func gravel(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 211 + 17)
		for i in 2:   # ערמות חצץ
			var gx := x + r.randf_range(0.0, period)
			var gw := r.randf_range(140.0, 260.0)
			var gh := r.randf_range(50.0, 95.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(gx - gw * 0.5, y), Vector2(gx - gw * 0.1, y - gh), Vector2(gx + gw * 0.12, y - gh * 0.96), Vector2(gx + gw * 0.5, y)]), STONE_D.lerp(STONE, 0.3))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(gx + gw * 0.05, y - gh * 0.98), Vector2(gx + gw * 0.12, y - gh * 0.96), Vector2(gx + gw * 0.5, y), Vector2(gx + gw * 0.25, y)]), Color(STONE_D, 0.9))
			for q in 12:
				ci.draw_circle(Vector2(gx + r.randf_range(-gw * 0.4, gw * 0.4), y - r.randf_range(2.0, gh * 0.6)), 1.6, Color(0.5, 0.42, 0.32, 0.6))
		var fx := x + r.randf_range(50.0, period - 260.0)   # גדר בטיחות כתומה
		for i in 7:
			var px := fx + float(i) * 34.0
			ci.draw_line(Vector2(px, y), Vector2(px, y - 34.0), Color(0.45, 0.42, 0.4), 2.0)
		ci.draw_line(Vector2(fx, y - 30.0), Vector2(fx + 204.0, y - 30.0), SAFETY, 4.0)
		ci.draw_line(Vector2(fx, y - 16.0), Vector2(fx + 204.0, y - 16.0), SAFETY, 4.0)
		var sx := x + r.randf_range(300.0, 800.0)   # שלט אזהרה
		ci.draw_line(Vector2(sx, y), Vector2(sx, y - 60.0), Color(0.4, 0.4, 0.4), 3.0)
		ci.draw_rect(Rect2(sx - 30.0, y - 84.0, 60.0, 28.0), Color("f2c418"))
		ci.draw_rect(Rect2(sx - 30.0, y - 84.0, 60.0, 28.0), Color(0.15, 0.12, 0.1), false, 2.0)
		ci.draw_string(ThemeDB.fallback_font, Vector2(sx - 28.0, y - 66.0), "DANGER", HORIZONTAL_ALIGNMENT_CENTER, 56.0, 12, Color(0.15, 0.1, 0.08))
		ci.draw_string(ThemeDB.fallback_font, Vector2(sx - 28.0, y - 58.0), "BLASTING", HORIZONTAL_ALIGNMENT_CENTER, 56.0, 8, Color(0.15, 0.1, 0.08))


# ---- רצפת חצץ מעל הכביש ----
class QuarryGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s18_decor.gd")
		draw_rect(Rect2(0, 0, w, depth), S.GROUND)
		draw_rect(Rect2(0, 0, w, 8.0), S.DIRT)
		draw_line(Vector2(0, 0), Vector2(w, 0), Color(S.STONE_L, 0.8), 2.0)
		for i in 2:   # עקבות צמיגים
			var ty := 14.0 + float(i) * 26.0
			var x := 0.0
			while x < w:
				draw_rect(Rect2(x, ty, 10.0, 4.0), Color(0.45, 0.36, 0.25, 0.45))
				x += 16.0
		for i in 120:   # חצץ
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(3.0, depth - 4.0))
			var c := S.STONE_D if r.randf() < 0.5 else S.STONE
			draw_circle(p, r.randf_range(1.0, 2.6), Color(c, 0.75))
		for i in 4:   # כתמי אבק בהירים
			draw_circle(Vector2(r.randf_range(0, w), r.randf_range(10, depth - 10)), r.randf_range(14, 26), Color(1, 1, 1, 0.06))


# ---- מכשולים (מוצקים + מחסה) ----
class Obstacle extends Node2D:
	var kind := "blocks"
	var size := Vector2(90, 50)
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

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s18_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"truck":   # משאית מכרה ענקית: ארגז, תא נהג, גלגלים ענקיים
				var wr := h * 0.32
				Art.fill_shaded(self, PackedVector2Array([Vector2(w * 0.02, -h * 0.42), Vector2(w * 0.72, -h * 0.42), Vector2(w * 0.78, -h), Vector2(-w * 0.02, -h * 0.92)]), S.PAINT, 0.15, 0.4, Art.OUTLINE, 1.6)   # ארגז
				for q in 4:
					draw_line(Vector2(w * (0.1 + 0.16 * float(q)), -h * 0.45), Vector2(w * (0.1 + 0.16 * float(q)), -h * 0.9), Color(0.6, 0.4, 0.1, 0.6), 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.05, -h * 0.92), Vector2(w * 0.7, -h * 0.98), Vector2(w * 0.55, -h * 1.06), Vector2(w * 0.15, -h * 1.02)]), S.STONE_D)   # מטען אבנים
				Art.fill_shaded(self, PackedVector2Array([Vector2(w * 0.74, -h * 0.42), Vector2(w, -h * 0.42), Vector2(w, -h * 0.82), Vector2(w * 0.8, -h * 0.82)]), S.PAINT, 0.1, 0.35, Art.OUTLINE, 1.4)   # תא
				draw_rect(Rect2(w * 0.83, -h * 0.78, w * 0.13, h * 0.16), Color("5a7a8a"))
				draw_rect(Rect2(w * 0.0, -h * 0.44, w, h * 0.06), Color("3a3a3c"))
				for wx in [w * 0.2, w * 0.82]:
					Art.disc(self, Vector2(wx, -wr), wr, Color("222226"), Art.OUTLINE, 1.6)
					Art.disc(self, Vector2(wx, -wr), wr * 0.45, Color("8a8a8e"))
					for q in 6:
						var a := float(q) * TAU / 6.0
						draw_line(Vector2(wx, -wr) + Vector2.from_angle(a) * wr * 0.6, Vector2(wx, -wr) + Vector2.from_angle(a) * wr * 0.95, Color("3a3a3e"), 2.0)
			"cart":   # עגלת מכרה על מסילה, מלאה אבנים
				draw_line(Vector2(-10, -2), Vector2(w + 10, -2), Color("6a6058"), 3.0)
				Art.fill_shaded(self, PackedVector2Array([Vector2(w * 0.05, -h * 0.25), Vector2(w * 0.95, -h * 0.25), Vector2(w, -h * 0.88), Vector2(0, -h * 0.88)]), Color("8a5a3a"), 0.15, 0.4, Art.OUTLINE, 1.4)
				for q in 3:
					draw_line(Vector2(w * (0.1 + 0.4 * float(q)), -h * 0.3), Vector2(w * (0.1 + 0.4 * float(q)), -h * 0.85), Color("5a3a24"), 2.0)
				for q in 7:
					Art.disc(self, Vector2(w * r.randf_range(0.1, 0.9), -h * r.randf_range(0.86, 1.0)), r.randf_range(4.0, 8.0), S.STONE, Art.OUTLINE, 1.0)
				for wx in [w * 0.22, w * 0.78]:
					Art.disc(self, Vector2(wx, -h * 0.16), h * 0.14, Color("3a3a3e"), Art.OUTLINE, 1.2)
			"drill_rig":   # אסדת קידוח קטנה: מגדל מסבכה עם מקדח
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, -h * 0.3), Vector2(w, -h * 0.3), Vector2(w, 0), Vector2(0, 0)]), Color("5a5e66"), 0.1, 0.35, Art.OUTLINE, 1.4)
				draw_rect(Rect2(0, -h * 0.3, w, h * 0.06), S.PAINT)
				var tx := w * 0.5
				draw_line(Vector2(tx - w * 0.3, -h * 0.3), Vector2(tx, -h), Color("4a4e56"), 3.0)
				draw_line(Vector2(tx + w * 0.3, -h * 0.3), Vector2(tx, -h), Color("4a4e56"), 3.0)
				for q in 4:
					var yy := -h * (0.4 + 0.15 * float(q))
					var half := w * 0.3 * (1.0 - (float(q) * 0.15 + 0.1) / 0.7)
					draw_line(Vector2(tx - half, yy), Vector2(tx + half, yy), Color("4a4e56"), 2.0)
				draw_line(Vector2(tx, -h), Vector2(tx, -h * 0.3), Color("9aa0a8"), 2.0)
			_:   # "blocks": ערמה של אבני גיר חתוכות (אפשר לעלות עליה)
				var rows := maxi(1, int(round(h / 26.0)))
				var bh := h / float(rows)
				for row in rows:
					var y0 := -bh * float(row + 1)
					var bx := r.randf_range(-6.0, 0.0) if row % 2 == 1 else 0.0
					var x := bx
					while x < w - 4.0:
						var bw := minf(r.randf_range(34.0, 52.0), w - x)
						var c := S.STONE.lerp(S.STONE_D, r.randf_range(0.0, 0.35))
						Art.fill_shaded(self, PackedVector2Array([Vector2(x + 1, y0 + 1), Vector2(x + bw - 1, y0 + 1), Vector2(x + bw - 1, y0 + bh), Vector2(x + 1, y0 + bh)]), c, 0.1, 0.3, Art.OUTLINE, 1.2)
						draw_line(Vector2(x + 3, y0 + 3), Vector2(x + bw - 4, y0 + 3), Color(S.STONE_L, 0.8), 1.2)
						if r.randf() < 0.4:   # חורי קידוח
							draw_line(Vector2(x + bw * 0.5, y0 + 4), Vector2(x + bw * 0.5, y0 + bh - 3), Color(0.5, 0.42, 0.32, 0.6), 1.0)
						x += bw


# ---- קרני שמש על המסך ----
class SunGlare extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var o := Vector2(vp.x * 0.86, -40.0)
		for i in 5:
			var a := 1.95 + float(i) * 0.13 + sin(_t * 0.3 + float(i)) * 0.02
			var w := 0.035 + 0.01 * float(i % 2)
			draw_colored_polygon(PackedVector2Array([o, o + Vector2.from_angle(a - w) * 1100.0, o + Vector2.from_angle(a + w) * 1100.0]), Color(1.0, 0.97, 0.82, 0.045))
		draw_rect(Rect2(Vector2.ZERO, vp), Color(1.0, 0.95, 0.8, 0.04))
