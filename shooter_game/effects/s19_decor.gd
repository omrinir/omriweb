extends RefCounted
# ============================================================
#  קישוטים לשלב 19 ("THE GREEN WALL") - ג'ונגל עבות: צמרת סגורה, קרני אור, ערפל, חורבות מקדש.
#    jungle_sky    - אור ירוק-זהוב שמסתנן דרך הצמרת, שמש מאחורי העלים
#    far_jungle    - צמרות רחוקות באובך, מפל מצוק, פירמידת מקדש מכוסה צמחים
#    mid_trees     - עצי ענק עם שורשי תמך, ליאנות מתנדנדות, ראשי אבן ענקיים עם טחב
#    near_plants   - שרכים, כפות דקל, עלי מונסטרה, פרחים אדומים - זזים ברוח
#    JungleGround  - (עולם) בוץ כהה, עלים יבשים, שורשים, שלוליות, טחב
#    Obstacle      - (מוצק + מחסה) "log" גזע שנפל עם טחב / "boulder" סלע מכוסה טחב /
#                    "ruin" עמוד מקדש שבור עם חריטות (גבוה) / "stump" גדם
#    JungleFX      - (מסך) צמרת תלויה למעלה, קרני אור, עלים נושרים, גחליליות/חרקים, ערפל נמוך
# ============================================================

const Art := preload("res://art.gd")

const LEAF := Color("3f7a32")
const LEAF_D := Color("24502a")
const LEAF_L := Color("6aa648")
const MUD := Color("4a3a26")
const MUD_D := Color("2e2418")
const MOSS := Color("5e8a3a")
const STONE := Color("8a8e7a")
const STONE_D := Color("5e6254")
const BARK := Color("4e3a28")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _blob(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, n := 12) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := float(i) * TAU / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


static func _leaf(ci: CanvasItem, base: Vector2, dir: Vector2, length: float, col: Color) -> void:
	var n := dir.orthogonal() * length * 0.28
	var tip := base + dir * length
	ci.draw_colored_polygon(PackedVector2Array([base, base + dir * length * 0.5 + n, tip, base + dir * length * 0.5 - n]), col)


# ---- שמיים מבעד לצמרת ----
static func jungle_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	var steps := 12
	for i in steps:
		var k := float(i) / float(steps - 1)
		ci.draw_rect(Rect2(0, v.y * k, v.x, v.y / float(steps) + 1.0), Color("1f4a32").lerp(Color("c8e0a0"), pow(k, 0.8)))
	var sun := Vector2(v.x * 0.35, 150.0)
	ci.draw_circle(sun, 150.0, Color(1.0, 0.98, 0.75, 0.12))
	ci.draw_circle(sun, 46.0, Color(1.0, 1.0, 0.88, 0.85))
	for i in 5:   # קרני אור אלכסוניות
		var x0 := sun.x - 220.0 + float(i) * 90.0
		var w := 26.0 + float(i % 3) * 14.0
		var a := 0.07 + 0.03 * sin(t * 0.5 + float(i))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + w, 0), Vector2(x0 + w + 260.0, v.y), Vector2(x0 + 180.0, v.y)]), Color(1.0, 1.0, 0.8, a))


# ---- צמרות רחוקות, מפל, פירמידה ----
static func far_jungle(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	var haze := Color(0.45, 0.62, 0.48, 0.8)
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 71 + 3)
		if r.randf() < 0.55:   # פירמידת מקדש
			var px := x + r.randf_range(200.0, 1100.0)
			var tiers := 6
			for i in tiers:
				var w := 260.0 - float(i) * 38.0
				ci.draw_rect(Rect2(px - w * 0.5, y - 40.0 - float(i + 1) * 30.0, w, 31.0), Color(0.5, 0.58, 0.5, 0.85))
				ci.draw_line(Vector2(px - w * 0.5, y - 40.0 - float(i + 1) * 30.0), Vector2(px + w * 0.5, y - 40.0 - float(i + 1) * 30.0), Color(0.4, 0.5, 0.4, 0.8), 2.0)
			ci.draw_rect(Rect2(px - 22.0, y - 40.0 - float(tiers) * 30.0 - 30.0, 44.0, 30.0), Color(0.48, 0.56, 0.48, 0.85))
			ci.draw_rect(Rect2(px - 8.0, y - 40.0 - float(tiers) * 30.0 - 22.0, 16.0, 22.0), Color(0.2, 0.25, 0.2, 0.8))
			for i in 8:   # צמחים על הפירמידה
				_blob(ci, Vector2(px + r.randf_range(-120.0, 120.0), y - r.randf_range(50.0, 200.0)), r.randf_range(10.0, 22.0), r.randf_range(6.0, 12.0), Color(0.3, 0.5, 0.32, 0.8))
		if r.randf() < 0.4:   # מצוק עם מפל
			var cx := x + r.randf_range(100.0, 1200.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 90.0, y), Vector2(cx - 70.0, y - 300.0), Vector2(cx + 40.0, y - 320.0), Vector2(cx + 90.0, y)]), Color(0.38, 0.48, 0.4, 0.85))
			var fall := Rect2(cx - 14.0, y - 300.0, 26.0, 300.0)
			ci.draw_rect(fall, Color(0.85, 0.95, 1.0, 0.75))
			for i in 6:   # מים זורמים
				var yy := fposmod(t * 160.0 + float(i) * 50.0, 300.0)
				ci.draw_line(Vector2(cx - 10.0 + float(i % 3) * 8.0, y - 300.0 + yy), Vector2(cx - 10.0 + float(i % 3) * 8.0, y - 300.0 + yy + 24.0), Color(1, 1, 1, 0.7), 2.0)
			_blob(ci, Vector2(cx, y - 6.0), 70.0, 22.0, Color(1, 1, 1, 0.35))   # אד המפל
		var px2 := x - 60.0
		while px2 < x + period + 60.0:   # צמרות מעוגלות באובך
			var rr := r.randf_range(50.0, 95.0)
			_blob(ci, Vector2(px2, y - r.randf_range(40.0, 120.0)), rr, rr * 0.7, haze)
			ci.draw_rect(Rect2(px2 - 6.0, y - 60.0, 12.0, 60.0), Color(0.35, 0.45, 0.36, 0.7))
			px2 += r.randf_range(70.0, 130.0)
	ci.draw_rect(Rect2(0, y - 20.0, v.x, v.y - y + 20.0), Color(0.42, 0.56, 0.44, 0.85))


# ---- עצי ענק, ליאנות, ראשי אבן ----
static func mid_trees(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1100.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 131 + 9)
		for j in 2:   # עצי ענק
			var tx := x + r.randf_range(80.0, 1000.0)
			var tw := r.randf_range(40.0, 64.0)
			var bark := BARK.lerp(Color("2e2a20"), r.randf_range(0.0, 0.4))
			ci.draw_rect(Rect2(tx - tw * 0.5, -40.0, tw, y + 40.0), bark)
			ci.draw_line(Vector2(tx - tw * 0.2, -40.0), Vector2(tx - tw * 0.2, y), Color(0, 0, 0, 0.18), 3.0)
			for s in [-1.0, 1.0]:   # שורשי תמך
				ci.draw_colored_polygon(PackedVector2Array([Vector2(tx + s * tw * 0.4, y - 90.0), Vector2(tx + s * tw * 1.6, y), Vector2(tx + s * tw * 0.3, y)]), bark)
			for q in 3:   # טחב על הגזע: פסים כהים לאורך הקליפה
				var my := y - r.randf_range(60.0, 300.0)
				var mx := tx + r.randf_range(-tw * 0.35, tw * 0.15)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(mx, my - 40.0), Vector2(mx + tw * 0.25, my - 30.0), Vector2(mx + tw * 0.2, my + 30.0), Vector2(mx - 2.0, my + 40.0)]), Color(0.24, 0.34, 0.2, 0.55))
			for q in 3:   # ליאנות תלויות מתנדנדות
				var lx := tx + r.randf_range(-tw * 2.0, tw * 2.0)
				var ll := r.randf_range(160.0, 320.0)
				var sway := sin(t * 0.9 + float(q) + tx * 0.01) * 10.0
				var pts := PackedVector2Array()
				for i in 9:
					var u := float(i) / 8.0
					pts.append(Vector2(lx + sway * u * u + sin(u * 6.0) * 4.0, u * ll))
				ci.draw_polyline(pts, Color("2e4a22"), 2.4, true)
				for i in 4:
					_leaf(ci, pts[2 + i], Vector2(1.0 if i % 2 == 0 else -1.0, 0.6).normalized(), 9.0, LEAF)
		if r.randf() < 0.5:   # חורבה: קיר אבן מתפורר עם קשת, טחב רק בשוליים
			var hx := x + r.randf_range(150.0, 900.0)
			var ww := r.randf_range(120.0, 190.0)
			var wh := r.randf_range(90.0, 140.0)
			var sc1 := Color(0.33, 0.38, 0.32)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx, y), Vector2(hx, y - wh), Vector2(hx + ww * 0.3, y - wh - 12.0), Vector2(hx + ww * 0.55, y - wh + 18.0), Vector2(hx + ww, y - wh * 0.6), Vector2(hx + ww, y)]), sc1)
			ci.draw_rect(Rect2(hx + ww * 0.35, y - wh * 0.55, ww * 0.28, wh * 0.55), Color(0.16, 0.2, 0.16))   # פתח הקשת
			for q in 4:   # שורות אבנים
				var yy := y - wh * (0.2 + 0.2 * float(q))
				ci.draw_line(Vector2(hx + 4.0, yy), Vector2(hx + ww - 4.0, yy), Color(0.26, 0.3, 0.25), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx - 6.0, y - wh - 4.0), Vector2(hx + ww * 0.3, y - wh - 16.0), Vector2(hx + ww * 0.5, y - wh + 10.0), Vector2(hx + ww * 0.2, y - wh + 6.0)]), Color(0.2, 0.32, 0.2))   # טחב מעל


# ---- צמחייה קרובה: צלליות כהות ומציאותיות (עשב גבוה, עלים רחבים, כפות דקל) - מעט מצולעים ----
const UNDER := [Color("172a1a"), Color("1f3622"), Color("27422a")]


static func near_plants(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 223 + 41)
		for i in 6:
			var px := x + r.randf_range(0.0, period)
			var col: Color = UNDER[r.randi() % 3]
			var wind := sin(t * 1.1 + px * 0.013) * 0.06
			match r.randi() % 3:
				0:   # גוש עשב גבוה: להבים דקים בפוליגון אחד כל אחד
					for q in 7:
						var bx := px + float(q) * 6.0 - 18.0
						var h := r.randf_range(40.0, 78.0)
						var lean := (float(q) - 3.0) * 4.0 + wind * h
						ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 2.5, y), Vector2(bx + lean, y - h), Vector2(bx + 2.5, y)]), col)
				1:   # צמח עלים רחבים (אוזן פיל): 3-4 עלים מחודדים
					for q in 4:
						var a := -PI * 0.5 + (float(q) - 1.5) * 0.55 + wind
						var dirv := Vector2.from_angle(a)
						var base := Vector2(px, y) + dirv * r.randf_range(18.0, 34.0)
						var ln := r.randf_range(34.0, 50.0)
						var n := dirv.orthogonal() * ln * 0.32
						ci.draw_line(Vector2(px, y), base, col, 2.0)
						ci.draw_colored_polygon(PackedVector2Array([base, base + dirv * ln * 0.45 + n, base + dirv * ln, base + dirv * ln * 0.45 - n]), col)
						ci.draw_line(base, base + dirv * ln * 0.85, Color(1, 1, 1, 0.05), 1.0)
				_:   # כף דקל נמוכה: עמוד שדרה מתעקל + פוליגון מסורק
					for q in 3:
						var a2 := -PI * 0.5 + (float(q) - 1.0) * 0.8 + wind
						var root := Vector2(px, y)
						var tip := root + Vector2.from_angle(a2) * 62.0 + Vector2(0, 22.0)
						var mid := root.lerp(tip, 0.5) + Vector2(0, -16.0)
						ci.draw_polyline(PackedVector2Array([root, mid, tip]), col, 2.0)
						var comb := PackedVector2Array([root])
						for u in 6:
							var p0 := root.lerp(mid, float(u) / 3.0) if u < 3 else mid.lerp(tip, float(u - 3) / 3.0)
							comb.append(p0 + Vector2(0, 16.0 - float(u) * 2.0))
						comb.append(tip)
						ci.draw_colored_polygon(comb, col)
	ci.draw_rect(Rect2(0, y - 6.0, v.x, v.y - y + 6.0), UNDER[0])


# ---- קרקע הג'ונגל ----
class JungleGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s19_decor.gd")
		draw_rect(Rect2(0, 0, w, depth), S.MUD_D)
		draw_rect(Rect2(0, 0, w, 10.0), S.MUD)
		draw_line(Vector2(0, 0), Vector2(w, 0), S.MOSS, 3.0)
		for i in 6:   # שורשים שחוצים
			var x0 := r.randf_range(0.0, w)
			var pts := PackedVector2Array()
			for u in 7:
				pts.append(Vector2(x0 + float(u) * 22.0, 4.0 + sin(float(u) * 1.3 + x0) * 4.0 + float(u) * 2.0))
			draw_polyline(pts, Color("3a2a1a"), 4.0, true)
		for i in 3:   # שלוליות
			var px := r.randf_range(40.0, w - 80.0)
			draw_rect(Rect2(px, 3.0, r.randf_range(40.0, 80.0), 4.0), Color(0.45, 0.55, 0.5, 0.6))
		for i in 90:   # עלים יבשים
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(2.0, depth - 4.0))
			var c: Color = [Color("6a5a2a"), Color("7a4a22"), Color("4e5a2a"), Color("8a6a30")][r.randi() % 4]
			var a := r.randf_range(0.0, TAU)
			draw_colored_polygon(PackedVector2Array([p, p + Vector2.from_angle(a) * 4.0 + Vector2.from_angle(a + 1.5) * 1.5, p + Vector2.from_angle(a) * 7.0, p + Vector2.from_angle(a) * 4.0 - Vector2.from_angle(a + 1.5) * 1.5]), Color(c, 0.8))
		for i in 14:   # טחב על פני השטח
			draw_circle(Vector2(r.randf_range(0, w), 1.0), r.randf_range(3.0, 7.0), S.MOSS)


# ---- מכשולים (מוצקים + מחסה) ----
class Obstacle extends Node2D:
	var kind := "log"
	var size := Vector2(110, 30)
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
		var S := preload("res://effects/s19_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"boulder":   # סלע מעוגל עם טחב
				var pts := PackedVector2Array()
				for i in 14:
					var a := PI + float(i) * PI / 13.0
					pts.append(Vector2(w * 0.5 + cos(a) * w * 0.5 * r.randf_range(0.92, 1.05), sin(a) * h * r.randf_range(0.9, 1.0)))
				Art.fill_shaded(self, pts, S.STONE, 0.15, 0.45, Art.OUTLINE, 1.6)
				for i in 4:
					S._blob(self, Vector2(w * r.randf_range(0.2, 0.8), -h * r.randf_range(0.7, 0.95)), w * 0.14, h * 0.12, S.MOSS)
				draw_line(Vector2(w * 0.3, -h * 0.5), Vector2(w * 0.45, -h * 0.25), Color(0.3, 0.3, 0.28, 0.6), 1.2)
			"ruin":   # עמוד מקדש שבור: אבנים מגולפות, חריטות, טחב, צמחים מטפסים
				var bh := h / 3.0
				for i in 3:
					var y0 := -bh * float(i + 1)
					var inset := float(i) * 3.0 + r.randf_range(-2.0, 2.0)
					Art.fill_shaded(self, PackedVector2Array([Vector2(inset, y0), Vector2(w - inset, y0), Vector2(w - inset, y0 + bh - 1.0), Vector2(inset, y0 + bh - 1.0)]), S.STONE.lerp(S.STONE_D, r.randf_range(0.0, 0.3)), 0.1, 0.4, Art.OUTLINE, 1.3)
					for q in 2:   # חריטות
						draw_arc(Vector2(w * (0.3 + 0.4 * float(q)), y0 + bh * 0.5), 5.0, 0.0, TAU, 10, Color(0.35, 0.36, 0.3), 1.4)
						draw_line(Vector2(w * (0.3 + 0.4 * float(q)) - 3.0, y0 + bh * 0.5), Vector2(w * (0.3 + 0.4 * float(q)) + 3.0, y0 + bh * 0.5), Color(0.35, 0.36, 0.3), 1.2)
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.6, -h), Vector2(w, -h + 6.0), Vector2(w, -h + 2.0)]), S.STONE_D)   # שבר בראש
				var vine := PackedVector2Array()
				for u in 8:
					vine.append(Vector2(w * 0.2 + sin(float(u)) * 6.0, -h + float(u) * h / 7.0))
				draw_polyline(vine, Color("2e4a22"), 2.0, true)
				for u in range(1, 7):
					S._leaf(self, vine[u], Vector2(1.0 if u % 2 == 0 else -1.0, 0.3).normalized(), 8.0, S.LEAF)
				S._blob(self, Vector2(w * 0.5, -h + 2.0), w * 0.4, 5.0, S.MOSS)
			"stump":   # גדם עם טבעות ופטריות
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(4, -h), Vector2(w - 4, -h), Vector2(w, 0)]), S.BARK, 0.15, 0.4, Art.OUTLINE, 1.4)
				S._blob(self, Vector2(w * 0.5, -h), w * 0.45, 4.0, Color("8a6a44"))
				draw_arc(Vector2(w * 0.5, -h), w * 0.25, 0.0, TAU, 12, Color("6a4e30"), 1.0)
				for i in 3:
					S._blob(self, Vector2(w * (0.2 + 0.25 * float(i)), -h * 0.4), 4.0, 2.2, Color("d8c090"))
			_:   # "log": גזע שנפל, קליפה, טחב, ענף שבור
				var pts2 := PackedVector2Array([Vector2(0, -h * 0.15), Vector2(4, -h), Vector2(w - 6, -h * 0.95), Vector2(w, -h * 0.5), Vector2(w - 4, 0), Vector2(6, 0)])
				Art.fill_shaded(self, pts2, S.BARK, 0.15, 0.45, Art.OUTLINE, 1.5)
				for i in 5:
					draw_line(Vector2(w * (0.1 + 0.18 * float(i)), -h * 0.85), Vector2(w * (0.14 + 0.18 * float(i)), -h * 0.25), Color(0.2, 0.15, 0.1, 0.5), 1.4)
				draw_circle(Vector2(w - 3.0, -h * 0.5), h * 0.42, Color("8a6a44"))   # חתך עם טבעות
				draw_arc(Vector2(w - 3.0, -h * 0.5), h * 0.25, 0.0, TAU, 12, Color("6a4e30"), 1.0)
				for i in 5:
					S._blob(self, Vector2(w * r.randf_range(0.1, 0.85), -h * 0.95), r.randf_range(8.0, 14.0), 4.0, S.MOSS)
				draw_line(Vector2(w * 0.4, -h), Vector2(w * 0.5, -h - 14.0), S.BARK, 4.0)


# ---- מסך: צמרת תלויה, קרני אור, עלים נושרים, גחליליות, ערפל ----
class JungleFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _leaves := []
	var _bugs := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 1919
		for i in 16:
			_leaves.append([Vector2(r.randf_range(0, vp.x), r.randf_range(0, vp.y)), r.randf_range(20.0, 45.0), r.randf_range(0.0, TAU), r.randf_range(4.0, 7.0)])
		for i in 24:
			_bugs.append([Vector2(r.randf_range(0, vp.x), r.randf_range(vp.y * 0.3, vp.y * 0.95)), r.randf_range(0.0, TAU), r.randf_range(0.5, 1.4)])

	func _process(delta: float) -> void:
		_t += delta
		for l in _leaves:
			l[0] += Vector2(sin(_t * 1.2 + l[2]) * 22.0 - 12.0, l[1]) * delta
			l[2] += delta * 2.0
			if l[0].y > vp.y + 10.0:
				l[0] = Vector2(randf_range(0.0, vp.x + 100.0), -10.0)
			if l[0].x < -20.0:
				l[0].x = vp.x + 10.0
		for b in _bugs:
			b[1] += delta * b[2]
			b[0] += Vector2(cos(b[1] * 1.7), sin(b[1] * 2.3)) * 14.0 * delta
		queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s19_decor.gd")
		for i in 4:   # קרני אור רכות
			var x0 := vp.x * (0.1 + 0.24 * float(i)) + sin(_t * 0.2 + float(i)) * 20.0
			draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 50.0, 0), Vector2(x0 + 230.0, vp.y), Vector2(x0 + 130.0, vp.y)]), Color(1.0, 1.0, 0.8, 0.045))
		draw_rect(Rect2(0, vp.y - 70.0, vp.x, 70.0), Color(0.85, 0.95, 0.85, 0.07))   # ערפל נמוך
		for b in _bugs:   # גחליליות
			var a: float = 0.4 + 0.4 * sin(_t * 5.0 + b[1] * 3.0)
			draw_circle(b[0], 3.0, Color(0.9, 1.0, 0.5, a * 0.25))
			draw_circle(b[0], 1.2, Color(0.95, 1.0, 0.6, a))
		for l in _leaves:   # עלים נושרים
			S._leaf(self, l[0], Vector2.from_angle(l[2]), l[3] * 2.0, Color(S.LEAF_L, 0.85))
		# צמרת תלויה בראש המסך: פוליגון אחד עם שוליים לא אחידים + כמה ליאנות
		var edge := PackedVector2Array([Vector2(-10, -10), Vector2(vp.x + 10.0, -10)])
		var x := vp.x + 10.0
		var i2 := 0
		while x > -20.0:
			var d := 18.0 + 14.0 * sin(float(i2) * 1.7) + 8.0 * sin(float(i2) * 0.6 + _t * 0.6)
			edge.append(Vector2(x, d))
			x -= 34.0
			i2 += 1
		draw_colored_polygon(edge, Color(S.LEAF_D.darkened(0.25), 0.95))
		for q in 7:   # ליאנות
			var lx := vp.x * (0.07 + 0.14 * float(q))
			var ll := 50.0 + float(q % 3) * 26.0
			var sway := sin(_t * 0.8 + float(q)) * 5.0
			draw_line(Vector2(lx, 12.0), Vector2(lx + sway, ll), Color("1e3418"), 2.0)
