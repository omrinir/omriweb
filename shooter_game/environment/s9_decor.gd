extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  S9 DECOR - קישוטי העולם של שלב 9 ("THEY LEARN"): עיר הרוסה ענקית שמחברת את כל
#  הסביבות הקודמות. כל קטע בשלב מקבל "נושא" (theme_at):
#    0 רחובות (בנייני דירות שרופים)   1 מפעל (מחסנים, צינורות, ארובות)
#    2 גגות במרכז העיר                  3 חורבות מעבדה (אריחים לבנים, זכוכית ירוקה)
#    4 אזור בשליטת הזומבים (מתרסים, גרפיטי "THEY LEARN", טוטמים)
#  מחלקות:
#    CityChunk    - חזיתות מאחורי הכביש, בחתיכות של 1024 פיקסלים (מצויר פעם אחת)
#    TunnelDecor  - המנהרה מתחת לכביש: אדמה, קירות, צינורות, עמודים (מנהרת שירות / מעבדה)
#    Buildings    - גופי הבניינים שמתחת לגגות / לקומות השנייה (חתך פתוח)
#    Conveyor     - מסוע (StaticBody2D עם constant_linear_velocity) - נושא את מי שעומד עליו
#    SpecimenTank - מיכל דגימה במעבדה עם בועות (מונפש רק כשעל המסך)
#    JunkPile     - ערימת גרוטאות / מתרס (מכשול "s9_junk")
#  איך משנים: גבולות הקטעים ב-THEME_EDGES, צבעים בכל פונקציית ציור.
# ============================================================

const Art := preload("res://art.gd")

const THEME_EDGES := [0.205, 0.40, 0.575, 0.75]   # חלק מאורך השלב שבו מתחיל כל נושא


static func theme_at(x: float, level_w: float) -> int:
	var f := x / maxf(level_w, 1.0)
	for i in THEME_EDGES.size():
		if f < float(THEME_EDGES[i]):
			return i
	return THEME_EDGES.size()


# ============================================================
#  חזיתות מאחורי הכביש (z_index שלילי)
# ============================================================
class CityChunk extends Node2D:
	const Self := preload("res://environment/s9_decor.gd")
	var seed_v := 0
	var level_w := 10240.0

	func _ready() -> void:
		z_index = -3

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var x := 0.0
		while x < 1024.0:
			var th: int = Self.theme_at(position.x + x, level_w)
			var w := r.randf_range(140.0, 240.0)
			match th:
				0: _apartment(r, x, w)
				1: _factory(r, x, w)
				2: _alley(r, x, w)
				3: _lab(r, x, w)
				_: _barricade(r, x, w)
			x += w + r.randf_range(0.0, 16.0)

	func _windows(r: RandomNumberGenerator, x: float, w: float, top: float, bottom: float, lit_col: Color, fire := 0.08) -> void:
		var wy := top + 18.0
		while wy < bottom - 30.0:
			var n := int((w - 24.0) / 30.0)
			for q in n:
				var wx := x + 14.0 + float(q) * 30.0
				var k := r.randf()
				var c := Color("141218")
				if k < fire:
					c = Color(1.0, 0.45, 0.15, 0.9)
					DrawBatch.rect(self, Rect2(wx - 4, wy - 10, 26, 14), Color(0.15, 0.1, 0.1, 0.5))   # פיח מעל החלון
				elif k < fire + 0.1:
					c = lit_col
				DrawBatch.rect(self, Rect2(wx, wy, 18, 20), c)
				if k > 0.85:   # חלון שבור
					DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(wx, wy), Vector2(wx + 10, wy), Vector2(wx + 2, wy + 12)]), Color(0.6, 0.65, 0.7, 0.3))
			wy += 36.0

	func _apartment(r: RandomNumberGenerator, x: float, w: float) -> void:
		var h := r.randf_range(170.0, 300.0)
		var wall := Color("3a3030").lerp(Color("4a3a34"), r.randf())
		var top := -h
		var pts := PackedVector2Array([Vector2(x, 0), Vector2(x, top + r.randf_range(0, 30)), Vector2(x + w * 0.4, top + r.randf_range(0, 50)), Vector2(x + w * 0.6, top + r.randf_range(30, 80)), Vector2(x + w, top + r.randf_range(0, 40)), Vector2(x + w, 0)])
		DrawBatch.colored_polygon(self, pts, wall)
		_windows(r, x, w, top + 40.0, -60.0, Color(1.0, 0.75, 0.4, 0.6), 0.1)
		# מדרגות חירום
		if r.randf() < 0.5:
			var fx := x + w * 0.3
			var y := -90.0
			while y > top + 70.0:
				DrawBatch.line(self, Vector2(fx, y), Vector2(fx + 60, y), Color("1c1a1c"), 2.0)
				DrawBatch.line(self, Vector2(fx, y), Vector2(fx + 60, y - 36), Color("1c1a1c"), 1.2)
				y -= 36.0
		DrawBatch.rect(self, Rect2(x + w * 0.5 - 18, -56, 36, 56), Color("161216"))   # פתח כניסה
		_graffiti(r, x, w)

	func _factory(r: RandomNumberGenerator, x: float, w: float) -> void:
		var h := r.randf_range(130.0, 220.0)
		var wall := Color("3c3a36").lerp(Color("4a4238"), r.randf())
		DrawBatch.rect(self, Rect2(x, -h, w, h), wall)
		var y := -h
		while y < 0.0:   # פח גלי
			DrawBatch.line(self, Vector2(x, y), Vector2(x + w, y), Color(0, 0, 0, 0.18), 1.0)
			y += 7.0
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x - 6, -h), Vector2(x + w * 0.5, -h - 34), Vector2(x + w + 6, -h)]), Art.shade(wall, 0.2))
		# ארובה / צינורות
		if r.randf() < 0.6:
			var cx := x + r.randf_range(20.0, w - 40.0)
			DrawBatch.rect(self, Rect2(cx, -h - 120, 22, 120), Color("2e2a28"))
			DrawBatch.rect(self, Rect2(cx - 2, -h - 124, 26, 8), Color("242020"))
			for i in 3:
				DrawBatch.rect(self, Rect2(cx, -h - 100 + i * 30, 22, 3), Color(0.6, 0.15, 0.1, 0.6))
		DrawBatch.rect(self, Rect2(x, -84, w, 10), Color("5a4a30"))   # צינור אופקי
		DrawBatch.rect(self, Rect2(x, -84, w, 3), Color(1, 1, 1, 0.08))
		for i in int(w / 22.0):   # פסי אזהרה על שער
			var sx := x + 10.0 + float(i) * 22.0
			if sx < x + w - 20.0:
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(sx, -30), Vector2(sx + 10, -30), Vector2(sx + 20, -18), Vector2(sx + 10, -18)]), Color(0.8, 0.65, 0.1, 0.5))
		DrawBatch.rect(self, Rect2(x + 14, -70, w * 0.5, 40), Color("1c1a18"))   # פתח מחסן
		_windows(r, x, w * 0.8, -h + 10.0, -h + 70.0, Color(1.0, 0.6, 0.3, 0.5), 0.05)

	func _alley(r: RandomNumberGenerator, x: float, w: float) -> void:
		# קירות כהים בין הבניינים הגבוהים (הבניינים עצמם = Buildings)
		var h := r.randf_range(110.0, 170.0)
		DrawBatch.rect(self, Rect2(x, -h, w, h), Color("2c2628").lerp(Color("36302e"), r.randf()))
		for i in 4:
			DrawBatch.rect(self, Rect2(x + r.randf_range(0, w - 40), -h + r.randf_range(10, h - 30), r.randf_range(20, 40), 3), Color(0, 0, 0, 0.25))
		if r.randf() < 0.6:   # פח אשפה + שקיות
			DrawBatch.rect(self, Rect2(x + w * 0.6, -26, 34, 26), Color("2a3a2e"))
			DrawBatch.circle(self, Vector2(x + w * 0.6 + 44, -6), 7.0, Color("161618"))
		_graffiti(r, x, w)

	func _lab(r: RandomNumberGenerator, x: float, w: float) -> void:
		var h := r.randf_range(140.0, 230.0)
		var wall := Color("8a9094").lerp(Color("9aa0a0"), r.randf())
		var pts := PackedVector2Array([Vector2(x, 0), Vector2(x, -h), Vector2(x + w * 0.7, -h + r.randf_range(0, 40)), Vector2(x + w, -h + r.randf_range(30, 90)), Vector2(x + w, 0)])
		DrawBatch.colored_polygon(self, pts, wall)
		var y := -h
		while y < -6.0:   # אריחים
			DrawBatch.line(self, Vector2(x, y), Vector2(x + w, y), Color(0, 0, 0, 0.1), 1.0)
			y += 16.0
		var gx := x + 12.0
		while gx < x + w - 50.0:   # חלונות זכוכית עם זוהר ירוק
			DrawBatch.rect(self, Rect2(gx, -h + 30, 40, 50), Color(0.12, 0.2, 0.16))
			DrawBatch.rect(self, Rect2(gx + 4, -h + 34, 32, 42), Color(0.3, 0.9, 0.5, 0.18 + r.randf() * 0.15))
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(gx + 4, -h + 34), Vector2(gx + 22, -h + 34), Vector2(gx + 6, -h + 60)]), Color(0.8, 0.95, 0.9, 0.25))
			gx += 56.0
		DrawBatch.rect(self, Rect2(x, -40, w, 6), Color(0.85, 0.75, 0.1, 0.6))   # פס אזהרה
		if r.randf() < 0.7:   # סמל ביולוגי
			var c := Vector2(x + w * 0.5, -100)
			DrawBatch.circle(self, c, 13.0, Color(0.9, 0.75, 0.1, 0.85))
			for i in 3:
				DrawBatch.circle(self, c + Vector2.from_angle(TAU * float(i) / 3.0 - PI * 0.5) * 6.0, 4.0, Color("1a1a1a"))
			DrawBatch.circle(self, c, 2.5, Color(0.9, 0.75, 0.1))
		DrawBatch.line(self, Vector2(x + w * 0.2, -h + 10), Vector2(x + w * 0.35, -60), Color(0.2, 0.22, 0.22, 0.6), 1.5)   # סדק

	func _barricade(r: RandomNumberGenerator, x: float, w: float) -> void:
		var h := r.randf_range(160.0, 260.0)
		DrawBatch.rect(self, Rect2(x, -h, w, h), Color("2a2226").lerp(Color("34282a"), r.randf()))
		_windows(r, x, w, -h + 20.0, -110.0, Color(1.0, 0.4, 0.2, 0.5), 0.12)
		# מתרס גרוטאות לרגלי הבניין: פחים, דלתות, צמיגים
		var bx := x
		while bx < x + w:
			var pw := r.randf_range(20.0, 44.0)
			var ph := r.randf_range(26.0, 64.0)
			var c := [Color("4a3a30"), Color("3a3e44"), Color("5a2a22"), Color("2e2e2e")][r.randi() % 4] as Color
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(bx, 0), Vector2(bx + r.randf_range(-4, 4), -ph), Vector2(bx + pw, -ph + r.randf_range(-8, 8)), Vector2(bx + pw, 0)]), c)
			bx += pw - 4.0
		for i in 3:   # יתדות חדים
			var sx := x + r.randf_range(10, w - 10)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(sx - 3, -40), Vector2(sx + 3, -40), Vector2(sx + 8, -90)]), Color("3a3028"))
		var f := ThemeDB.fallback_font
		var tags := ["THEY LEARN", "WE SEE YOU", "NO EXIT", "WE REMEMBER", "YOU ARE PREY", "THEY COMMAND"]
		var tag: String = tags[r.randi() % tags.size()]
		DrawBatch.string(self, f, Vector2(x + 10, -120 + r.randf_range(-20, 10)), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.75, 0.08, 0.06, 0.8))
		if r.randf() < 0.6:   # טוטם: גולגולות על מוט
			var tx := x + w * 0.7
			DrawBatch.line(self, Vector2(tx, -40), Vector2(tx, -150), Color("2a2018"), 3.0)
			for i in 3:
				var sp := Vector2(tx, -150 + i * 22)
				DrawBatch.circle(self, sp, 7.0, Color("c8c0a8"))
				DrawBatch.circle(self, sp + Vector2(-2.5, -1), 1.8, Color("1a1010"))
				DrawBatch.circle(self, sp + Vector2(2.5, -1), 1.8, Color("1a1010"))

	func _graffiti(r: RandomNumberGenerator, x: float, w: float) -> void:
		if r.randf() < 0.45:
			var f := ThemeDB.fallback_font
			var tags := ["THEY LEARN", "RUN", "HELP", "SECTOR 9", "DON'T STOP", "X"]
			var tag: String = tags[r.randi() % tags.size()]
			DrawBatch.string(self, f, Vector2(x + 16, -24 - r.randf_range(0, 20)), tag, HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 15, Color(r.randf_range(0.6, 1.0), 0.15, 0.15, 0.7))


# ============================================================
#  המנהרה מתחת לכביש
# ============================================================
class TunnelDecor extends Node2D:
	var x0 := 0.0
	var x1 := 1000.0
	var top := 720.0      # התקרה (תחתית הכביש)
	var bottom := 930.0   # הריצפה
	var lab := false
	var seed_v := 0

	func _ready() -> void:
		z_index = -4

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		# אדמה וסלעים מסביב (רואים אותה כשהמצלמה למטה)
		DrawBatch.rect(self, Rect2(x0 - 760.0, top, x1 - x0 + 1520.0, bottom - top + 100.0), Color("1e1a18"))
		for i in 60:
			var px := r.randf_range(x0 - 740.0, x1 + 740.0)
			var py := r.randf_range(top + 6.0, bottom + 80.0)
			DrawBatch.circle(self, Vector2(px, py), r.randf_range(4.0, 14.0), Color("2a2420").lerp(Color("15120f"), r.randf()))
		for k in 3:   # שכבות
			var sy := top + 50.0 + float(k) * 70.0
			DrawBatch.line(self, Vector2(x0 - 760.0, sy), Vector2(x1 + 760.0, sy + 6.0), Color(0.3, 0.25, 0.2, 0.25), 2.0)
		# הקיר הפנימי
		var wall := Color("a6aeb0") if lab else Color("3e3a36")
		DrawBatch.rect(self, Rect2(x0, top, x1 - x0, bottom - top), wall)
		if lab:
			var y := top
			while y < bottom:
				DrawBatch.line(self, Vector2(x0, y), Vector2(x1, y), Color(0, 0, 0, 0.12), 1.0)
				y += 18.0
			var x := x0
			while x < x1:
				DrawBatch.line(self, Vector2(x, top), Vector2(x, bottom), Color(0, 0, 0, 0.08), 1.0)
				x += 18.0
			DrawBatch.rect(self, Rect2(x0, bottom - 46.0, x1 - x0, 8.0), Color(0.85, 0.7, 0.1, 0.7))
			for i in int((x1 - x0) / 40.0):
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x0 + i * 40, bottom - 46), Vector2(x0 + i * 40 + 14, bottom - 46), Vector2(x0 + i * 40 + 22, bottom - 38), Vector2(x0 + i * 40 + 8, bottom - 38)]), Color("1a1a1a"))
		else:
			var y := top + 30.0
			while y < bottom:   # לבני בטון
				DrawBatch.line(self, Vector2(x0, y), Vector2(x1, y), Color(0, 0, 0, 0.2), 1.0)
				y += 30.0
			DrawBatch.rect(self, Rect2(x0, bottom - 30.0, x1 - x0, 30.0), Color(0.2, 0.25, 0.2, 0.35))   # כתמי רטיבות
		# צינורות בתקרה
		DrawBatch.rect(self, Rect2(x0, top + 8.0, x1 - x0, 12.0), Color("5a5048") if not lab else Color("707a80"))
		DrawBatch.rect(self, Rect2(x0, top + 8.0, x1 - x0, 3.0), Color(1, 1, 1, 0.1))
		DrawBatch.rect(self, Rect2(x0, top + 26.0, x1 - x0, 6.0), Color("3a3430") if not lab else Color("4a7a5a"))
		# עמודי תמך + כבלים תלויים
		var px2 := x0 + 80.0
		while px2 < x1 - 40.0:
			DrawBatch.rect(self, Rect2(px2, top, 22.0, bottom - top), Art.shade(wall, 0.3))
			DrawBatch.rect(self, Rect2(px2, top, 4.0, bottom - top), Color(1, 1, 1, 0.06))
			if r.randf() < 0.5:
				var pts := PackedVector2Array()
				for q in 8:
					var u := float(q) / 7.0
					pts.append(Vector2(px2 + 22.0 + u * 140.0, top + 40.0 + sin(u * PI) * 26.0))
				DrawBatch.polyline(self, pts, Color(0.08, 0.08, 0.08), 1.5)
			px2 += r.randf_range(240.0, 340.0)
		# גרפיטי / שלטים
		var f := ThemeDB.fallback_font
		var signs := ["EXIT ^", "LEVEL B2", "NO ENTRY", "QUARANTINE", "THEY LEARN"] if lab else ["EXIT ^", "TUNNEL 9", "THEY HIDE HERE", "AMMO >", "DON'T GO DOWN"]
		var sx := x0 + 140.0
		while sx < x1 - 120.0:
			var s: String = signs[r.randi() % signs.size()]
			DrawBatch.string(self, f, Vector2(sx, top + 90.0 + r.randf_range(0, 50)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.15, 0.1, 0.7) if not lab else Color(0.15, 0.4, 0.2, 0.8))
			sx += r.randf_range(380.0, 600.0)
		# קירות הקצה
		DrawBatch.rect(self, Rect2(x0 - 40.0, top, 40.0, bottom - top), Color("2a2624"))
		DrawBatch.rect(self, Rect2(x1, top, 40.0, bottom - top), Color("2a2624"))


# ============================================================
#  גופי הבניינים מתחת לגגות (חתך פתוח - רואים קומות מבפנים)
# ============================================================
class Buildings extends Node2D:
	var list := []          # [x, רוחב, גובה הגג (y), [גבהי קומות ביניים]]
	var floor_y := 630.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for b in list:
			var x: float = b[0]
			var w: float = b[1]
			var top: float = b[2]
			var mids: Array = b[3]
			var wall := Color("3a3436").lerp(Color("443a38"), r.randf())
			DrawBatch.rect(self, Rect2(x, top, w, floor_y - top), wall)
			# חלל פנימי כהה (חתך) עם קירות צד
			DrawBatch.rect(self, Rect2(x + 14.0, top + 14.0, w - 28.0, floor_y - top - 14.0), Art.shade(wall, 0.45))
			for my in mids:
				DrawBatch.rect(self, Rect2(x + 14.0, float(my) + 14.0, w - 28.0, 10.0), Art.shade(wall, 0.25))
			# חלונות בקיר האחורי
			var wy := top + 30.0
			while wy < floor_y - 50.0:
				var wx := x + 30.0
				while wx < x + w - 40.0:
					var k := r.randf()
					var c := Color("120e12")
					if k < 0.08:
						c = Color(1.0, 0.5, 0.2, 0.8)
					elif k < 0.16:
						c = Color(0.9, 0.8, 0.6, 0.35)
					DrawBatch.rect(self, Rect2(wx, wy, 16, 22), c)
					wx += 34.0
				wy += 40.0
			# מעקה / מיכל מים / אנטנה על הגג
			DrawBatch.rect(self, Rect2(x, top - 4.0, w, 4.0), Art.shade(wall, -0.1))
			if r.randf() < 0.7:
				var tx := x + r.randf_range(30.0, w - 70.0)
				DrawBatch.rect(self, Rect2(tx + 6, top - 34, 4, 30), Color("201c1c"))
				DrawBatch.rect(self, Rect2(tx + 34, top - 34, 4, 30), Color("201c1c"))
				DrawBatch.rect(self, Rect2(tx, top - 70, 44, 38), Color("3a2e26"))
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(tx - 2, top - 70), Vector2(tx + 22, top - 84), Vector2(tx + 46, top - 70)]), Color("2a221e"))
			DrawBatch.line(self, Vector2(x + w - 30, top), Vector2(x + w - 26, top - 60), Color("1a1818"), 2.0)
			# קיר שבור בצד
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x + w, top + 30), Vector2(x + w - 14, top + 60), Vector2(x + w - 6, top + 110), Vector2(x + w, top + 120)]), Art.shade(wall, 0.5))


# ============================================================
#  מסוע (מפעל): נושא את מי שעומד עליו (constant_linear_velocity)
# ============================================================
class Conveyor extends StaticBody2D:
	var width := 220.0
	var speed := -110.0
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		constant_linear_velocity = Vector2(speed, 0.0)
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(width, 18.0)
		cs.shape = rs
		cs.position = Vector2(width * 0.5, -9.0)
		add_child(cs)
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(width * 0.5, 0.0), 200.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, -18, width, 18), Color("2a2a2c"))
		DrawBatch.rect(self, Rect2(0, -18, width, 4), Color("4a4a4c"))
		var off := fposmod(_t * speed, 20.0)
		var x := off - 20.0
		while x < width:   # חיצים זזים על הרצועה
			if x > 2.0 and x < width - 10.0:
				var d := signf(speed)
				DrawBatch.line(self, Vector2(x, -16), Vector2(x + 5.0 * d, -16 + 1.0), Color(0.85, 0.7, 0.2, 0.8), 1.5)
			x += 20.0
		for i in 2:   # גלגלים בקצוות
			var c := Vector2(9.0 + float(i) * (width - 18.0), -9.0)
			DrawBatch.circle(self, c, 8.0, Color("1a1a1a"))
			var a := _t * speed * 0.1
			DrawBatch.line(self, c, c + Vector2.from_angle(a) * 7.0, Color("6a6a6a"), 1.5)


# ============================================================
#  מיכל דגימה במעבדה (בועות, נוזל ירוק, צללית של זומבי בפנים)
# ============================================================
class SpecimenTank extends Node2D:
	var _t := 0.0
	var broken := false

	func _ready() -> void:
		z_index = -3
		_t = randf() * 10.0

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position) and Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(-22, -110, 44, 10), Color("4a5258"))
		DrawBatch.rect(self, Rect2(-24, -8, 48, 8), Color("4a5258"))
		var liquid := 0.45 if broken else 1.0
		var ly := -100.0 + (1.0 - liquid) * 92.0
		DrawBatch.rect(self, Rect2(-18, ly, 36, -8.0 - ly), Color(0.3, 0.9, 0.45, 0.35))
		# צללית בפנים
		DrawBatch.circle(self, Vector2(0, -78 + sin(_t) * 2.0), 7.0, Color(0.1, 0.2, 0.15, 0.7))
		DrawBatch.rect(self, Rect2(-6, -71 + sin(_t) * 2.0, 12, 40), Color(0.1, 0.2, 0.15, 0.7))
		for i in 5:
			var k := fmod(_t * 0.5 + float(i) * 0.2, 1.0)
			var by := lerpf(-10.0, ly, k)
			DrawBatch.circle(self, Vector2(-12.0 + float(i) * 6.0 + sin(_t * 2.0 + float(i)) * 2.0, by), 1.6, Color(0.7, 1.0, 0.7, 0.6))
		DrawBatch.rect(self, Rect2(-18, -100, 36, 92), Color(0.8, 0.95, 1.0, 0.12))
		DrawBatch.line(self, Vector2(-14, -96), Vector2(-14, -14), Color(1, 1, 1, 0.25), 2.0)
		if broken:
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(4, -100), Vector2(18, -100), Vector2(18, -60), Vector2(10, -80)]), Color(0.05, 0.08, 0.06, 0.9))
		Art.glow(self, Vector2(0, -55), 30.0, Color(0.3, 1.0, 0.45, 0.15))


# ============================================================
#  ערימת גרוטאות / מתרס (המכשול "s9_junk")
# ============================================================
class JunkPile extends Node2D:
	var seed_v := 0
	var theme := 0
	var width := 60.0
	var height := 40.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		match theme:
			1:   # מפעל: חביות שמן חלודות + משטח
				DrawBatch.rect(self, Rect2(0, -10, width, 10), Color("5a4026"))
				for i in 3:
					var bx := 4.0 + float(i) * (width - 8.0) / 3.0
					Art.fill_shaded(self, PackedVector2Array([Vector2(bx, -10), Vector2(bx + 16, -10), Vector2(bx + 16, -height), Vector2(bx, -height)]), Color("6a3a22").lerp(Color("3a4a5a"), r.randf()), 0.2, 0.35)
					DrawBatch.line(self, Vector2(bx, -height * 0.6), Vector2(bx + 16, -height * 0.6), Color(0, 0, 0, 0.3), 1.0)
			3:   # מעבדה: ארון מתכת הפוך + מבחנות שבורות
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(0, -height), Vector2(width, -height + 6), Vector2(width, 0)]), Color("9aa0a4"), 0.2, 0.35)
				DrawBatch.rect(self, Rect2(6, -height + 8, width - 12, 4), Color("5a6064"))
				for i in 4:
					DrawBatch.line(self, Vector2(8 + i * 10, -4), Vector2(12 + i * 10, -12), Color(0.5, 1.0, 0.6, 0.6), 2.0)
			4:   # אזור הזומבים: מתרס עם יתדות
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(4, -height), Vector2(width - 4, -height + 4), Vector2(width, 0)]), Color("4a3428"), 0.15, 0.4)
				for i in 4:
					var sx := 6.0 + float(i) * (width - 12.0) / 3.0
					Art.fill(self, PackedVector2Array([Vector2(sx - 2, -height), Vector2(sx + 2, -height), Vector2(sx + 6, -height - 18)]), Color("6a6058"), Art.OUTLINE, 1.0)
				DrawBatch.line(self, Vector2(2, -height * 0.5), Vector2(width - 2, -height * 0.4), Color("2a2a2a"), 2.0)
			_:   # רחוב / גגות: ערימת לבנים, צמיגים ופחים
				for i in 6:
					var c := Color("5a4a40") if r.randf() < 0.6 else Color("2a2a2e")
					Art.oval_shaded(self, Vector2(8 + i * (width - 16.0) / 5.0, -8 - (i % 2) * 8), 10.0, 8.0, c, r.randf(), Art.OUTLINE, 1.0)
				Art.fill_shaded(self, PackedVector2Array([Vector2(width * 0.3, -16), Vector2(width * 0.7, -height), Vector2(width * 0.8, -height + 6), Vector2(width * 0.4, -10)]), Color("6a6460"), 0.2, 0.3)
