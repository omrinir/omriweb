extends RefCounted
# ============================================================
#  S7 DECOR - קישוטי העולם של שלב 7 (מפעל חשוך). levels/stage_7.gd יוצר אותם.
#    WallChunk  - קיר המפעל מאחורי הריצפה (אריח של 1024 פיקסלים, מצויר פעם אחת):
#                 לוחות מתכת עם ניטים, צינורות, מכולות אחסון, מכונות שבורות, ארונות חשמל,
#                 שלטי אזהרה וגרפיטי "THEY WATCH"
#    Cctv       - מצלמת אבטחה שמסתובבת אחרי השחקן ("הם צופים")
#    Crane      - עגורן גשר בעולם שנוסע הלוך ושוב עם ארגז מתנדנד
#    WallFan    - מאוורר בקיר שמסתובב (צללים מהבהבים)
#    DarkPocket - כיס חושך מתחת למכונה שבורה - שם מתחבא ה-AMBUSHER (group "s7_dark")
#    FgChains   - שרשראות כהות בחזית (לפני השחקן), גבוה מעל הראש
#    Machine    - מכשול מוצק (שכבה 1) מכונה שבורה / גנרטור. זומבים מתחבאים מאחוריו (group "cover")
#    TrenchEdge - שוליים של תעלת תחזוקה (פסי אזהרה + סורג)
#  איך משנים: צבעים / גדלים בתוך כל מחלקה. כל מה שמונפש מצויר רק כשהוא על המסך.
# ============================================================

const Art := preload("res://art.gd")


# ---- קיר המפעל ----
class WallChunk extends Node2D:
	var seed_v := 0

	func _ready() -> void:
		z_index = -3

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var w := 1024.0
		# לוחות קיר
		draw_rect(Rect2(0, -230, w, 230), Color("24221f"))
		var px := 0.0
		while px < w:
			var pw := r.randf_range(90.0, 140.0)
			var pc := Color("2a2723").lerp(Color("201e1b"), r.randf())
			draw_rect(Rect2(px + 1, -228, pw - 2, 200), pc)
			for q in 5:   # ניטים
				draw_circle(Vector2(px + 5, -220 + q * 44), 1.3, Color("3a3631"))
				draw_circle(Vector2(px + pw - 5, -220 + q * 44), 1.3, Color("3a3631"))
			if r.randf() < 0.3:   # כתם חלודה
				Art.oval(self, Vector2(px + r.randf_range(20, pw - 20), r.randf_range(-200, -60)), r.randf_range(8, 18), r.randf_range(14, 30), Color(0.35, 0.18, 0.08, 0.35), 0.0, Art.NONE)
			px += pw
		# פס אזהרה צהוב-שחור בתחתית הקיר
		var sx := 0.0
		var i := 0
		while sx < w:
			draw_colored_polygon(PackedVector2Array([Vector2(sx, -26), Vector2(sx + 14, -26), Vector2(sx + 24, -16), Vector2(sx + 10, -16)]), Color("8a6c18") if i % 2 == 0 else Color("1a1814"))
			sx += 14.0
			i += 1
		draw_rect(Rect2(0, -16, w, 16), Color("1a1815"))
		# צינורות לאורך הקיר
		for pyv in [-188.0, -172.0]:
			draw_rect(Rect2(0, pyv, w, 9), Color("33302b"))
			draw_line(Vector2(0, pyv + 2), Vector2(w, pyv + 2), Color(0.6, 0.55, 0.45, 0.12), 1.0)
		# פריטים לאורך הקיר
		var x := r.randf_range(10.0, 80.0)
		while x < w - 120.0:
			var kind := r.randi() % 7
			match kind:
				0:   # מכולות אחסון (אחת או שתיים)
					var cw := r.randf_range(130.0, 170.0)
					var cols := [Color("3a2a22"), Color("26323a"), Color("3a3a26"), Color("402018")]
					var cc: Color = cols[r.randi() % cols.size()]
					_container(Rect2(x, -78, cw, 62), cc, r)
					if r.randf() < 0.5:
						_container(Rect2(x + r.randf_range(-10, 20), -140, cw * 0.9, 62), (cols[r.randi() % cols.size()] as Color).darkened(0.1), r)
					x += cw + 20.0
				1:   # מכונה שבורה (מחרטה) עם גלגל שיניים
					Art.fill_shaded(self, PackedVector2Array([Vector2(x, -16), Vector2(x, -70), Vector2(x + 30, -86), Vector2(x + 110, -86), Vector2(x + 120, -16)]), Color("2c302e"), 0.15, 0.35, Color(0, 0, 0, 0.6))
					_gear(Vector2(x + 40, -60), 16.0, Color("3a3c3a"))
					_gear(Vector2(x + 70, -48), 10.0, Color("34363a"))
					draw_rect(Rect2(x + 84, -76, 26, 16), Color("161816"))
					draw_line(Vector2(x + 100, -86), Vector2(x + 128, -120), Color("2c302e"), 4.0)   # זרוע שבורה
					x += 150.0
				2:   # ארון חשמל עם מחוגים
					draw_rect(Rect2(x, -120, 60, 104), Color("2e3330"))
					draw_rect(Rect2(x + 4, -116, 52, 96), Color("262a28"))
					for q in 2:
						var gc := Vector2(x + 18 + q * 24, -96)
						draw_circle(gc, 7.0, Color("d0ccb8"))
						draw_line(gc, gc + Vector2.from_angle(r.randf_range(-2.6, -0.4)) * 6.0, Color("201010"), 1.0)
					draw_rect(Rect2(x + 10, -70, 40, 8), Color("161816"))
					draw_colored_polygon(PackedVector2Array([Vector2(x + 30, -52), Vector2(x + 40, -36), Vector2(x + 20, -36)]), Color("b8901c"))
					draw_line(Vector2(x + 30, -48), Vector2(x + 30, -41), Color("161816"), 1.5)
					x += 90.0
				3:   # חביות שמן
					for q in r.randi_range(2, 3):
						var bxx := x + q * 26
						draw_rect(Rect2(bxx, -46, 24, 30), Color("3a2a1a") if q % 2 == 0 else Color("2a3a3a"))
						draw_line(Vector2(bxx, -38), Vector2(bxx + 24, -38), Color(0, 0, 0, 0.35), 1.5)
						draw_line(Vector2(bxx, -26), Vector2(bxx + 24, -26), Color(0, 0, 0, 0.35), 1.5)
					x += 100.0
				4:   # שלט אזהרה / גרפיטי
					var f := ThemeDB.fallback_font
					var tags := ["THEY WATCH", "BAY 7", "DANGER", "NO ENTRY", "WE SEE YOU", "SECTOR 7", "HIGH VOLTAGE"]
					var tag: String = tags[r.randi() % tags.size()]
					var red := tag == "THEY WATCH" or tag == "WE SEE YOU"
					if not red:
						draw_rect(Rect2(x - 4, -150, tag.length() * 9.0 + 8.0, 24), Color("1a1814"))
					draw_string(f, Vector2(x, -132), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.75, 0.12, 0.08, 0.75) if red else Color(0.8, 0.65, 0.2, 0.7))
					if red:   # עין מצוירת
						var ec := Vector2(x + tag.length() * 4.5, -110)
						draw_arc(ec, 10.0, PI * 1.15, PI * 1.85, 8, Color(0.75, 0.12, 0.08, 0.7), 2.0)
						draw_arc(ec + Vector2(0, -12), 10.0, PI * 0.15, PI * 0.85, 8, Color(0.75, 0.12, 0.08, 0.7), 2.0)
						draw_circle(ec + Vector2(0, -6), 3.0, Color(0.75, 0.12, 0.08, 0.7))
					x += tag.length() * 9.0 + 40.0
				5:   # משטחי עץ ושקים
					for q in 3:
						draw_rect(Rect2(x, -22 - q * 8, 70, 4), Color("3a2e20"))
					draw_rect(Rect2(x + 6, -52, 28, 22), Color("4a4030"))
					draw_rect(Rect2(x + 36, -46, 26, 16), Color("40382a"))
					x += 90.0
				_:   # מנוע ענק עם רצועה
					draw_circle(Vector2(x + 40, -60), 34.0, Color("2a2e2c"))
					draw_circle(Vector2(x + 40, -60), 10.0, Color("1a1c1c"))
					draw_rect(Rect2(x + 40, -94, 70, 78), Color("2a2e2c"))
					draw_line(Vector2(x + 40, -94), Vector2(x + 110, -50), Color("121414"), 3.0)
					draw_line(Vector2(x + 40, -26), Vector2(x + 110, -50), Color("121414"), 3.0)
					x += 140.0
			x += r.randf_range(20.0, 90.0)

	func _container(rc: Rect2, c: Color, r: RandomNumberGenerator) -> void:
		draw_rect(rc, c)
		var gx := rc.position.x + 4.0
		while gx < rc.end.x - 2.0:   # צלעות
			draw_line(Vector2(gx, rc.position.y + 3), Vector2(gx, rc.end.y - 3), c.darkened(0.3), 2.0)
			gx += 8.0
		draw_rect(Rect2(rc.position, Vector2(rc.size.x, 3)), c.lightened(0.12))
		if r.randf() < 0.6:
			draw_string(ThemeDB.fallback_font, rc.position + Vector2(10, 22), ["KX-07", "HAZMAT", "BIO", "07-B"][r.randi() % 4], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.85, 0.8, 0.3))

	func _gear(c: Vector2, rad: float, col: Color) -> void:
		draw_circle(c, rad, col)
		for q in 8:
			var a := float(q) * TAU / 8.0
			draw_rect(Rect2(c + Vector2.from_angle(a) * rad - Vector2(2.5, 2.5), Vector2(5, 5)), col)
		draw_circle(c, rad * 0.35, Color("161816"))


# ---- מצלמת אבטחה שעוקבת אחרי השחקן ----
class Cctv extends Node2D:
	var _a := 2.6
	var _t := 0.0
	var _sees := false

	func _ready() -> void:
		z_index = -1
		_t = randf() * 3.0

	func _process(delta: float) -> void:
		_t += delta
		if not Art.on_screen(self, global_position):
			return
		var p := get_tree().get_first_node_in_group("player")
		var want := 2.2 + sin(_t * 0.5) * 0.6   # סורקת לאט
		_sees = false
		if p != null and not p.dead:
			var d: Vector2 = p.global_position + Vector2(0, -30) - global_position
			if d.length() < 650.0:
				want = d.angle()
				_sees = true
		_a = lerp_angle(_a, want, delta * (3.0 if _sees else 1.0))
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-4, -6, 8, 12), Color("1e2022"))   # בסיס בקיר
		var dv := Vector2.from_angle(_a)
		var tr := Transform2D(_a, Vector2(dv.x * 4.0, 2.0))
		draw_colored_polygon(tr * PackedVector2Array([Vector2(0, -5), Vector2(20, -6), Vector2(22, 4), Vector2(0, 4)]), Color("34383c"))
		draw_colored_polygon(tr * PackedVector2Array([Vector2(20, -4), Vector2(25, -4), Vector2(25, 2), Vector2(20, 2)]), Color("101214"))
		var on := fmod(_t * (3.0 if _sees else 1.0), 1.0) < 0.5
		draw_circle(tr * Vector2(4, -2), 1.6, Color(1.0, 0.15, 0.1) if on else Color(0.3, 0.05, 0.05))
		if _sees:   # קרן צפייה חלשה
			var o := tr * Vector2(25, -1)
			draw_colored_polygon(PackedVector2Array([o, o + dv.rotated(-0.18) * 200.0, o + dv.rotated(0.18) * 200.0]), Color(1.0, 0.2, 0.15, 0.04))


# ---- עגורן גשר: נוסע הלוך ושוב עם ארגז מתנדנד ----
class Crane extends Node2D:
	var span := 900.0
	var drop := 120.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2
		_t = randf() * 30.0

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(span * 0.5, 0), span * 0.5 + 100.0):
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, -8, span, 12), Color("201e1c"))
		var x := 0.0
		while x < span:   # מסבך
			draw_line(Vector2(x, -8), Vector2(x + 20, 4), Color("161412"), 2.0)
			x += 20.0
		var k := 0.5 + 0.5 * sin(_t * 0.18)
		var tx := 40.0 + (span - 80.0) * k
		var vel := cos(_t * 0.18)
		draw_rect(Rect2(tx - 22, 2, 44, 14), Color("2c2a26"))
		draw_circle(Vector2(tx - 12, 2), 4.0, Color("121110"))
		draw_circle(Vector2(tx + 12, 2), 4.0, Color("121110"))
		var sw := -vel * 0.12 + sin(_t * 1.1) * 0.04
		var hook := Vector2(tx, 16) + Vector2.from_angle(PI * 0.5 + sw) * drop
		draw_line(Vector2(tx - 3, 16), hook + Vector2(-3, 0), Color("141210"), 1.5)
		draw_line(Vector2(tx + 3, 16), hook + Vector2(3, 0), Color("141210"), 1.5)
		var tr := Transform2D(sw, hook)
		Art.fill_shaded(self, tr * PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(30, 36), Vector2(-30, 36)]), Color("3a3226"), 0.15, 0.35, Color(0, 0, 0, 0.6))
		draw_line(tr * Vector2(-30, 12), tr * Vector2(30, 12), Color(0, 0, 0, 0.35), 1.5)
		draw_line(tr * Vector2(-30, 24), tr * Vector2(30, 24), Color(0, 0, 0, 0.35), 1.5)
		var blink := fmod(_t, 1.2) < 0.2
		draw_circle(Vector2(tx, 12), 2.0, Color(1.0, 0.6, 0.1) if blink else Color(0.3, 0.2, 0.1))


# ---- מאוורר בקיר ----
class WallFan extends Node2D:
	var radius := 26.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position) and Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-radius - 6, -radius - 6, radius * 2 + 12, radius * 2 + 12), Color("1c1b19"))
		draw_circle(Vector2.ZERO, radius, Color("0c0b0a"))
		for q in 4:
			var a := _t * 7.0 + float(q) * TAU / 4.0
			draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a - 0.25) * radius * 0.95, Vector2.from_angle(a + 0.2) * radius * 0.95]), Color("2a2824"))
		draw_circle(Vector2.ZERO, 4.0, Color("3a3834"))
		for q in 4:   # סורג
			draw_line(Vector2(-radius, -radius + q * radius * 0.66), Vector2(radius, -radius + q * radius * 0.66), Color(0.1, 0.1, 0.1, 0.7), 1.0)


# ---- כיס חושך: צל עמוק מתחת למכונה שבורה (מחבוא ל-AMBUSHER) ----
class DarkPocket extends Node2D:
	var size := Vector2(140, 150)

	func _ready() -> void:
		add_to_group("s7_dark")
		z_index = 4   # מעל הזומבים (3), מתחת לשחקן (4, נוסף אחרי)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# צל עם שוליים רכים
		for i in 6:
			var k := float(i) / 6.0
			var gw := w * (1.0 - k * 0.5)
			draw_rect(Rect2(-gw * 0.5, -h * (1.0 - k * 0.25), gw, h * (1.0 - k * 0.25)), Color(0.0, 0.0, 0.01, 0.16))
		# מכסה מכונה שבורה מעל (נותן את הצל)
		var top := -h - 6.0
		Art.fill_shaded(self, PackedVector2Array([Vector2(-w * 0.55, top + 18), Vector2(-w * 0.45, top), Vector2(w * 0.4, top - 4), Vector2(w * 0.58, top + 14), Vector2(w * 0.5, top + 26), Vector2(-w * 0.5, top + 28)]), Color("23221f"), 0.12, 0.4, Color(0, 0, 0, 0.7))
		draw_line(Vector2(-w * 0.4, top + 28), Vector2(-w * 0.42, 0), Color("161513"), 5.0)   # רגל
		draw_line(Vector2(w * 0.44, top + 26), Vector2(w * 0.5, -40), Color("161513"), 4.0)   # רגל שבורה
		for q in 3:   # כבלים תלויים
			var cx := -w * 0.25 + float(q) * w * 0.25
			draw_line(Vector2(cx, top + 26), Vector2(cx + 4, top + 60 + float(q) * 12.0), Color("0e0e0e"), 1.5)


# ---- שרשראות כהות בחזית (מעל גובה הראש) ----
class FgChains extends Node2D:
	var top_y := -520.0
	var length := 300.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 9
		_t = randf() * 10.0

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(0, top_y + length * 0.5), 200.0) and Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		for q in 2:
			var ox := float(q) * 46.0
			var ln := length * (1.0 if q == 0 else 0.75)
			var sw := sin(_t * 0.9 + float(q) * 1.4) * 0.05
			var prev := Vector2(ox, top_y)
			for s in 16:
				var u := float(s + 1) / 16.0
				var p := Vector2(ox + sin(sw * 12.0 * u) * ln * 0.1 * u, top_y + u * ln)
				draw_line(prev, p, Color(0.04, 0.035, 0.03, 0.92), 4.0 if s % 2 == 0 else 2.5)
				prev = p
			draw_arc(prev + Vector2(0, 9), 9.0, -0.4, PI + 0.5, 8, Color(0.04, 0.035, 0.03, 0.92), 3.5)


# ---- מכשול מוצק: מכונה שבורה / גנרטור ----
class Machine extends StaticBody2D:
	var size := Vector2(100, 56)
	var kind := 0          # 0 = מכונה שבורה, 1 = גנרטור (נורות מהבהבות)
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		add_to_group("cover")
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = size
		cs.shape = r
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		add_child(cs)
		z_index = 1
		_t = randf() * 4.0

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -size.y), size)

	func _process(delta: float) -> void:
		_t += delta
		if kind == 1 and Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if kind == 1:   # גנרטור: גוף מעוגל, צלעות קירור, נורות
			Art.fill_shaded(self, PackedVector2Array([Vector2(4, 0), Vector2(0, -h + 10), Vector2(10, -h), Vector2(w - 10, -h), Vector2(w, -h + 10), Vector2(w - 4, 0)]), Color("3e4a3c"), 0.2, 0.4)
			for q in int((w - 30.0) / 8.0):
				draw_line(Vector2(14 + q * 8, -h + 14), Vector2(14 + q * 8, -12), Color("26302a"), 2.0)
			draw_rect(Rect2(w - 30, -h + 8, 20, 14), Color("1a1e1a"))
			for q in 3:
				var on := fmod(_t * (0.8 + float(q) * 0.5), 1.0) < 0.5
				var lc := Color(1.0, 0.6, 0.15) if q < 2 else Color(0.3, 1.0, 0.4)
				draw_circle(Vector2(w - 26 + q * 6, -h + 15), 1.8, lc if on else lc.darkened(0.7))
			draw_rect(Rect2(0, -6, w, 6), Color("1e221e"))
			draw_string(ThemeDB.fallback_font, Vector2(14, -h * 0.4), "GEN-7", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.75, 0.3, 0.55))
		else:   # מכונה שבורה: בסיס, ראש עקום, גלגל שיניים, כבלים
			Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(0, -h * 0.6), Vector2(w * 0.3, -h * 0.6), Vector2(w * 0.35, -h), Vector2(w * 0.85, -h + 6), Vector2(w, -h * 0.55), Vector2(w, 0)]), Color("3a3c40"), 0.2, 0.45)
			draw_circle(Vector2(w * 0.6, -h * 0.55), h * 0.22, Color("2a2c30"))
			for q in 8:
				var a := float(q) * TAU / 8.0
				draw_circle(Vector2(w * 0.6, -h * 0.55) + Vector2.from_angle(a) * h * 0.22, 2.5, Color("2a2c30"))
			draw_circle(Vector2(w * 0.6, -h * 0.55), 3.0, Color("6a6e74"))
			var x := 4.0
			var i := 0
			while x < w - 6.0:   # פס אזהרה בבסיס
				draw_rect(Rect2(x, -9, 6, 5), Color("a8861c") if i % 2 == 0 else Color("1c1c1c"))
				x += 6.0
				i += 1
			draw_line(Vector2(w * 0.85, -h + 6), Vector2(w + 10, -h - 8), Color("2a2c30"), 3.0)
			draw_line(Vector2(w * 0.2, -h * 0.6), Vector2(w * 0.12, -h * 0.85), Color("111111"), 1.5)


# ---- שוליים של תעלה: פסי אזהרה ----
class TrenchEdge extends Node2D:
	var width := 80.0

	func _ready() -> void:
		z_index = 2

	func _draw() -> void:
		for ex in [-14.0, width]:
			var x: float = ex
			for q in 3:
				draw_rect(Rect2(x + float(q) * 5.0, -3, 3, 6), Color("b8901c"))
		draw_line(Vector2(0, 0), Vector2(0, 60), Color("2a2a2e"), 3.0)
		draw_line(Vector2(width, 0), Vector2(width, 60), Color("2a2a2e"), 3.0)
		draw_rect(Rect2(2, 50, width - 4, 10), Color(0.04, 0.04, 0.05, 0.9))
