extends RefCounted
# ============================================================
#  קישוטי שלב 8 - מעבדה תת-קרקעית נטושה ("THEY ADAPT").
#  כל הקישוט מצויר בקוד, בחתיכות של 1024 פיקסלים (מצוירות רק כשהן על המסך).
#    LabWall     - קיר אחורי: לוחות קרים, תקרה עם צינורות, חדרי זכוכית, תאי כליאה,
#                  עמדות מחשב, דלתות חסומות, שלטי אזהרה, כבלים, דם. (z = -3)
#                  יוצרת לעצמה ילדים מונפשים: מסכים מהבהבים (Ambient.Screen) ומיכלי נוזל (LiquidTank).
#    FloorTiles  - אריחי רצפה, פס אזהרה, סורגים, זכוכית שבורה וכתמי דם מעל הכביש.
#    PropOverlay - ציור של רהיט מעבדה (שולחן / מכולת דגימות / ארון שרתים) מעל בלוק מוצק.
#                  נעלם כשהבלוק נשבר, ומצייר את הסדקים שלו.
#    LiquidTank  - מיכל נוזל גדול עם בועות ונבדק צף (מונפש).
#    LeakPipe    - צינור סדוק בקיר שמטפטף כימיקלים ירוקים + אדים ירוקים (מעל שלולית חומצה).
#    AlarmPulse  - שכבת מסך: אור חירום אדום שפועם בשולי המסך.
#  לשנות: צבעים בראש כל מחלקה, SIGNS (טקסטים של שלטים), סוגי הקטעים ב-LabWall._draw.
# ============================================================

const Art := preload("res://art.gd")
const Ambient := preload("res://effects/ambient.gd")

const SIGNS := ["BIOHAZARD", "CONTAINMENT BREACH", "SUBJECT 08", "DO NOT ENTER", "LEVEL B4", "SECTOR 8", "QUARANTINE", "THEY ADAPT", "NO EXIT"]
const WALL := Color("27303a")
const WALL_D := Color("1c232b")
const PANEL := Color("33404a")
const STEEL := Color("4a545e")


# ============ קיר המעבדה (חתיכה של 1024) ============
class LabWall extends Node2D:
	var seed_v := 0
	var floor_y := 630.0
	var _segs := []        # [x, w, type]

	func _ready() -> void:
		z_index = -3
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var x := 0.0
		var types := ["glass", "chamber", "terminal", "door", "plain", "open", "open", "glass", "chamber", "terminal", "open"]
		while x < 1024.0:
			var w := r.randf_range(190.0, 290.0)
			var t: String = types[r.randi() % types.size()]
			_segs.append([x, w, t, r.randi()])
			# ילדים מונפשים
			if t == "terminal":
				for i in 3:
					var s = Ambient.Screen.new()
					s.size = Vector2(30, 22)
					s.color = [Color(0.3, 0.9, 0.8), Color(0.4, 1.0, 0.5), Color(1.0, 0.35, 0.3)][(i + r.randi()) % 3]
					s.position = Vector2(x + 24.0 + float(i) * 44.0, -150.0)
					add_child(s)
			elif t == "chamber":
				var lt := LiquidTank.new()
				lt.position = Vector2(x + w * 0.5, -60.0)
				lt.seed_v = r.randi()
				add_child(lt)
			x += w

	func _draw() -> void:
		var top := -floor_y
		# קירות (כל קטע מצייר את הקיר שלו; קטע "open" משאיר פתח לאולם המכונות שברקע)
		for sg in _segs:
			_draw_seg(float(sg[0]), float(sg[1]), str(sg[2]), int(sg[3]))
		# עמודי פלדה מהתקרה עד הקיר (ממסגרים את האולם שברקע)
		var bx := 40.0
		while bx < 1024.0:
			draw_rect(Rect2(bx, top, 22, floor_y - 360.0), Color("12161a"))
			for k in int((floor_y - 360.0) / 46.0):   # הצלבות
				var yy := top + 60.0 + float(k) * 46.0
				draw_line(Vector2(bx + 2, yy), Vector2(bx + 20, yy + 40), Color("1c2228"), 2.0)
			bx += 340.0
		# תקרה: צינורות, מגשי כבלים
		draw_rect(Rect2(0, top, 1024, 58), Color("161b20"))
		draw_rect(Rect2(0, top + 58, 1024, 4), Color("0e1114"))
		for i in 3:
			var cy := top + 14.0 + float(i) * 13.0
			draw_rect(Rect2(0, cy, 1024, 7), Color("3a444c") if i != 1 else Color("5a3a30"))
			draw_rect(Rect2(0, cy, 1024, 2), Color(1, 1, 1, 0.08))
			var jx := float(i) * 90.0
			while jx < 1024.0:
				draw_rect(Rect2(jx, cy - 2, 8, 11), Color("2a3238"))
				jx += 260.0

	# קיר בסיס של קטע (גובה 360 מעל הרצפה)
	func _base_wall(x: float, w: float) -> void:
		draw_rect(Rect2(x, -360, w, 360), WALL)
		var px := x
		while px < x + w:
			draw_line(Vector2(px, -360), Vector2(px, 0), WALL_D, 2.0)
			px += 64.0
		for hy in [-250.0, -95.0]:
			var y: float = hy
			draw_rect(Rect2(x, y, w, 3), WALL_D)
		draw_rect(Rect2(x, -205, w, 10), PANEL)
		draw_rect(Rect2(x, -205, w, 2), Color(0.45, 0.85, 0.95, 0.35))   # פס תאורה כחלחל
		draw_rect(Rect2(x, -40, w, 40), Color("20272e"))   # פאנל תחתון
		draw_rect(Rect2(x, -366, w, 8), Color("2e363e"))   # מעקה עליון של הקיר
		draw_rect(Rect2(x, -366, w, 2), Color(1, 1, 1, 0.12))

	func _draw_seg(x: float, w: float, t: String, sd: int) -> void:
		var r := RandomNumberGenerator.new()
		r.seed = sd
		if t != "open":
			_base_wall(x, w)
		match t:
			"open":   # פתח לאולם המכונות: רק מחסום נמוך, מעקה וקורות
				draw_rect(Rect2(x, -44, w, 44), Color("20272e"))
				_stripes(Rect2(x, -50, w, 6))
				draw_line(Vector2(x, -110), Vector2(x + w, -110), Color("3a444c"), 3.0)
				var rx2 := x
				while rx2 <= x + w:
					draw_line(Vector2(rx2, -110), Vector2(rx2, -44), Color("3a444c"), 2.0)
					rx2 += 40.0
				draw_rect(Rect2(x, -366, w, 10), Color("1a2026"))   # קורה עליונה
				_sign(Vector2(x + 16, -130), "VIEWING GALLERY" if r.randf() < 0.5 else "REACTOR HALL", Color(0.6, 0.85, 0.95))
			"glass":   # חדר זכוכית: חלונות גדולים עם מסגרות, ציוד בפנים, סדקים
				var gx := x + 14.0
				var gw := w - 28.0
				draw_rect(Rect2(gx, -330, gw, 260), Color("10171c"))
				# ציוד בפנים (צלליות): מדפים, כיסא, מנורה
				draw_rect(Rect2(gx + 10, -250, gw * 0.4, 6), Color("1e2a30"))
				draw_rect(Rect2(gx + 10, -210, gw * 0.4, 6), Color("1e2a30"))
				for i in 4:
					draw_rect(Rect2(gx + 14 + i * 14, -268, 8, 18), Color(0.2, 0.35, 0.3, 0.8))
				draw_rect(Rect2(gx + gw * 0.6, -150, gw * 0.3, 8), Color("1e2a30"))
				draw_rect(Rect2(gx + gw * 0.62, -142, 4, 72), Color("1e2a30"))
				draw_colored_polygon(PackedVector2Array([Vector2(gx + gw * 0.7, -330), Vector2(gx + gw * 0.7 + 30, -330), Vector2(gx + gw * 0.7 + 50, -200), Vector2(gx + gw * 0.7 - 20, -200)]), Color(0.6, 0.9, 1.0, 0.05))
				# זכוכית + מסגרת
				draw_rect(Rect2(gx, -330, gw, 260), Color(0.5, 0.75, 0.85, 0.1))
				var mx := gx
				while mx <= gx + gw + 1.0:
					draw_rect(Rect2(mx - 2, -332, 5, 264), STEEL)
					mx += gw / 2.0
				draw_rect(Rect2(gx - 3, -334, gw + 6, 6), STEEL)
				draw_rect(Rect2(gx - 3, -74, gw + 6, 6), STEEL)
				for i in 3:   # השתקפויות
					var rx := gx + 10.0 + float(i) * gw * 0.33
					draw_line(Vector2(rx, -320), Vector2(rx + 40, -230), Color(1, 1, 1, 0.06), 6.0)
				if r.randf() < 0.75:   # סדק כוכב
					var c := Vector2(gx + r.randf_range(20, gw - 20), r.randf_range(-300, -120))
					for k in 9:
						var a := TAU * float(k) / 9.0 + r.randf() * 0.4
						var l := r.randf_range(18, 60)
						draw_line(c, c + Vector2.from_angle(a) * l, Color(0.85, 0.95, 1.0, 0.45), 1.0)
					draw_arc(c, 12.0, 0, TAU, 12, Color(0.85, 0.95, 1.0, 0.35), 1.0)
				if r.randf() < 0.5:   # טביעת יד מדממת על הזכוכית
					_hand(Vector2(gx + r.randf_range(20, gw - 20), r.randf_range(-200, -110)), r)
			"chamber":   # תא כליאה: גומחה עם מסגרת אזהרה (המיכל עצמו = LiquidTank מונפש)
				var cx := x + w * 0.5
				draw_rect(Rect2(cx - 60, -340, 120, 340), Color("12181d"))
				_stripes(Rect2(cx - 66, -346, 132, 8))
				_stripes(Rect2(cx - 66, -8, 132, 8))
				draw_rect(Rect2(cx - 66, -346, 6, 346), Color("3a3020"))
				draw_rect(Rect2(cx + 60, -346, 6, 346), Color("3a3020"))
				_sign(Vector2(cx - 44, -318), "SUBJECT %02d" % (r.randi() % 40 + 1), Color(0.9, 0.85, 0.3))
				for i in 2:   # כבלים עבים לתא
					draw_line(Vector2(cx - 30 + i * 60, -340), Vector2(cx - 30 + i * 60 + r.randf_range(-10, 10), -300), Color("0e1114"), 4.0)
			"terminal":   # עמדות מחשב (המסכים עצמם מונפשים - Ambient.Screen)
				draw_rect(Rect2(x + 14, -160, 140, 40), Color("161c22"))
				draw_rect(Rect2(x + 10, -100, w - 20, 8), STEEL)   # שולחן
				draw_rect(Rect2(x + 14, -92, 6, 92), Color("2a3036"))
				draw_rect(Rect2(x + w - 24, -92, 6, 92), Color("2a3036"))
				draw_rect(Rect2(x + 30, -112, 46, 12), Color("2a3036"))   # מקלדת
				draw_rect(Rect2(x + w - 80, -150, 50, 50), Color("20262c"))   # מחשב
				for i in 4:
					draw_circle(Vector2(x + w - 70 + i * 10, -140), 1.6, Color(0.3, 1.0, 0.4) if r.randf() < 0.6 else Color(1.0, 0.3, 0.2))
				for i in 6:   # ניירות על הרצפה
					var pp := Vector2(x + r.randf_range(10, w - 10), r.randf_range(-6, -2))
					draw_colored_polygon(PackedVector2Array([pp, pp + Vector2(9, -2), pp + Vector2(10, 3), pp + Vector2(1, 4)]), Color(0.75, 0.75, 0.7, 0.6))
				_sign(Vector2(x + 20, -230), SIGNS[r.randi() % SIGNS.size()], Color(0.9, 0.3, 0.25))
			"door":   # דלת חסומה עם פסי אזהרה ונורה אדומה
				var dx := x + w * 0.5 - 50.0
				draw_rect(Rect2(dx - 8, -206, 116, 206), Color("1a1f24"))
				draw_rect(Rect2(dx, -198, 100, 198), Color("3e464e"))
				draw_line(Vector2(dx + 50, -198), Vector2(dx + 50, 0), Color("22282e"), 3.0)
				_stripes(Rect2(dx, -40, 100, 14))
				draw_rect(Rect2(dx + 12, -170, 26, 40), Color(0.1, 0.15, 0.18))
				draw_rect(Rect2(dx + 62, -170, 26, 40), Color(0.1, 0.15, 0.18))
				draw_circle(Vector2(dx + 50, -222), 6.0, Color(0.6, 0.1, 0.08))
				_sign(Vector2(dx + 6, -250), "LOCKDOWN", Color(1.0, 0.3, 0.25))
				for i in 3:   # שריטות של ציפורניים
					var sx := dx + 30.0 + float(i) * 6.0
					draw_line(Vector2(sx, -120), Vector2(sx + 8, -60), Color(0.12, 0.1, 0.1, 0.7), 1.2)
			_:   # קיר רגיל: שלט, צינורות אנכיים, לוח חשמל
				_sign(Vector2(x + 20, -300), SIGNS[r.randi() % SIGNS.size()], Color(0.95, 0.8, 0.2))
				if r.randf() < 0.6:
					_trefoil(Vector2(x + w - 50, -290), 16.0)
				draw_rect(Rect2(x + w * 0.3, -floor_y + 60, 10, floor_y - 60), Color("2e363e"))
				draw_rect(Rect2(x + w * 0.3 + 16, -floor_y + 60, 6, floor_y - 60), Color("4a3a2e"))
				draw_rect(Rect2(x + w * 0.55, -190, 50, 70), Color("2a3238"))
				draw_rect(Rect2(x + w * 0.55 + 4, -186, 42, 62), Color("20272e"))
				for i in 3:
					draw_line(Vector2(x + w * 0.55 + 12 + i * 12, -186), Vector2(x + w * 0.55 + 12 + i * 12, -150), Color("0e1114"), 2.0)
		# כבלים תלויים מהתקרה
		for i in 2:
			if r.randf() < 0.55:
				var c0 := Vector2(x + r.randf_range(10, w - 10), -floor_y + 60)
				var l := r.randf_range(60, 200)
				var sag := r.randf_range(-20, 20)
				draw_polyline(PackedVector2Array([c0, c0 + Vector2(sag * 0.5, l * 0.5), c0 + Vector2(sag, l)]), Color("0c0e10"), 2.0, true)
		# דם על הקיר
		if r.randf() < 0.5:
			var bp := Vector2(x + r.randf_range(10, w - 30), r.randf_range(-140, -40))
			for k in 5:
				draw_circle(bp + Vector2(r.randf_range(-10, 10), r.randf_range(-6, 6)), r.randf_range(2, 6), Color(0.35, 0.04, 0.04, 0.8))
			for k in 4:
				var dx2 := bp.x + r.randf_range(-8, 8)
				draw_line(Vector2(dx2, bp.y), Vector2(dx2, bp.y + r.randf_range(10, 40)), Color(0.35, 0.04, 0.04, 0.7), r.randf_range(1.0, 2.5))
		if r.randf() < 0.35:   # מריחת יד ארוכה
			var sp := Vector2(x + r.randf_range(10, w - 60), r.randf_range(-120, -60))
			draw_line(sp, sp + Vector2(r.randf_range(40, 80), r.randf_range(10, 40)), Color(0.32, 0.03, 0.03, 0.6), 7.0)

	func _hand(c: Vector2, r: RandomNumberGenerator) -> void:
		var col := Color(0.4, 0.04, 0.04, 0.75)
		draw_circle(c, 5.0, col)
		for k in 4:
			var a := -2.2 + float(k) * 0.4
			draw_line(c, c + Vector2.from_angle(a) * r.randf_range(9, 12), col, 2.4)
		draw_line(c, c + Vector2(-8, 0), col, 2.4)
		draw_line(c + Vector2(0, 4), c + Vector2(r.randf_range(-2, 2), 26), Color(0.4, 0.04, 0.04, 0.5), 1.5)

	func _stripes(rc: Rect2) -> void:
		draw_rect(rc, Color(0.85, 0.7, 0.1))
		var sx := rc.position.x
		while sx < rc.end.x:
			var a := Vector2(sx, rc.end.y)
			draw_colored_polygon(PackedVector2Array([a, a + Vector2(rc.size.y, -rc.size.y), a + Vector2(rc.size.y + 6, -rc.size.y), a + Vector2(6, 0)]), Color(0.08, 0.08, 0.08))
			sx += 14.0

	func _sign(p: Vector2, text: String, c: Color) -> void:
		var f := ThemeDB.fallback_font
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_rect(Rect2(p + Vector2(-4, -12), Vector2(tw + 8, 17)), Color(0.08, 0.08, 0.09))
		draw_rect(Rect2(p + Vector2(-4, -12), Vector2(tw + 8, 17)), Color(c, 0.6), false, 1.0)
		draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c)

	func _trefoil(c: Vector2, r: float) -> void:   # סימן קרינה / ביו
		draw_circle(c, r + 3.0, Color(0.9, 0.75, 0.1))
		for k in 3:
			var a := -PI / 2.0 + TAU * float(k) / 3.0
			var pts := PackedVector2Array([c])
			for j in 7:
				pts.append(c + Vector2.from_angle(a - 0.5 + float(j) / 6.0) * r)
			draw_colored_polygon(pts, Color(0.08, 0.08, 0.08))
		draw_circle(c, r * 0.25, Color(0.9, 0.75, 0.1))


# ============ רצפת המעבדה (מעל הכביש) ============
class FloorTiles extends Node2D:
	var seed_v := 0

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		draw_rect(Rect2(0, 0, 1024, 4), Color("5a646c"))
		draw_rect(Rect2(0, 4, 1024, 2), Color(0, 0, 0, 0.5))
		var x := 0.0
		while x < 1024.0:
			draw_line(Vector2(x, 6), Vector2(x, 40), Color(0, 0, 0, 0.35), 1.0)
			x += 48.0
		draw_line(Vector2(0, 26), Vector2(1024, 26), Color(0, 0, 0, 0.25), 1.0)
		for i in 3:   # סורגי ניקוז
			var gx := r.randf_range(20.0, 980.0)
			draw_rect(Rect2(gx, 8, 30, 10), Color("16191c"))
			for k in 5:
				draw_line(Vector2(gx + 3 + k * 6, 8), Vector2(gx + 3 + k * 6, 18), Color("3a4248"), 1.5)
		for i in 5:   # זכוכית שבורה על הרצפה
			var sx := r.randf_range(0.0, 1024.0)
			for k in 4:
				var sp := Vector2(sx + r.randf_range(-14, 14), r.randf_range(-2, 1))
				draw_colored_polygon(PackedVector2Array([sp, sp + Vector2(r.randf_range(2, 6), -r.randf_range(1, 4)), sp + Vector2(r.randf_range(3, 7), 0)]), Color(0.75, 0.9, 1.0, 0.55))
		for i in 2:   # שובל דם על הרצפה
			if r.randf() < 0.6:
				var bx := r.randf_range(0.0, 900.0)
				draw_rect(Rect2(bx, 6, r.randf_range(40, 120), 4), Color(0.35, 0.03, 0.03, 0.55))


# ============ רהיט מעבדה מעל בלוק מוצק ============
class PropOverlay extends Node2D:
	var kind := "bench"
	var size := Vector2(90, 34)
	var brick: Node = null
	var seed_v := 0
	var _cracks := 0

	func _ready() -> void:
		z_index = 1
		if brick != null:
			brick.tree_exiting.connect(queue_free)

	func _process(_d: float) -> void:
		if brick == null or not is_instance_valid(brick) or Engine.get_process_frames() % 10 != 0:
			return
		var n: int = brick._cracks.size()
		if n != _cracks:
			_cracks = n
			queue_redraw()

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var w := size.x
		var h := size.y
		match kind:
			"bench":   # שולחן מעבדה: משטח לבן, ארונות מתכת, כלי זכוכית
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 6), Vector2(w, 6), Vector2(w, h), Vector2(0, h)]), Color("56626c"), 0.15, 0.3)
				draw_rect(Rect2(-3, 0, w + 6, 7), Color("c8d2d6"))
				draw_rect(Rect2(-3, 6, w + 6, 2), Color(0, 0, 0, 0.4))
				var dw := w / 3.0
				for i in 3:
					draw_rect(Rect2(4 + i * dw, 12, dw - 8, h - 16), Color(0, 0, 0, 0.15), false, 1.0)
					draw_rect(Rect2(i * dw + dw * 0.5 - 4, 16, 8, 2), Color("aab4ba"))
				for i in 3:   # כלי זכוכית על השולחן
					var gx := 8.0 + r.randf_range(0, w - 20)
					var gh := r.randf_range(8, 16)
					var liq: Color = [Color(0.4, 1.0, 0.4, 0.7), Color(0.4, 0.8, 1.0, 0.7), Color(1.0, 0.4, 0.6, 0.7)][r.randi() % 3]
					draw_rect(Rect2(gx, -gh, 6, gh), Color(0.8, 0.9, 1.0, 0.35))
					draw_rect(Rect2(gx, -gh * 0.5, 6, gh * 0.5), liq)
				if r.randf() < 0.5:   # מיקרוסקופ
					draw_rect(Rect2(w - 22, -4, 12, 4), Color("2a3036"))
					draw_line(Vector2(w - 16, -4), Vector2(w - 12, -18), Color("2a3036"), 3.0)
					draw_circle(Vector2(w - 12, -19), 3.0, Color("3a4248"))
			"crate":   # מכולת דגימות: מתכת עם פסי אזהרה וחלון קטן
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), Color("5a6670"), 0.2, 0.35)
				draw_rect(Rect2(0, 0, w, 5), Color(0.85, 0.7, 0.1))
				for i in int(w / 10.0):
					draw_line(Vector2(i * 10, 5), Vector2(i * 10 + 5, 0), Color(0.08, 0.08, 0.08), 2.0)
				draw_rect(Rect2(w * 0.3, h * 0.3, w * 0.4, h * 0.25), Color(0.25, 0.6, 0.35, 0.8))
				draw_rect(Rect2(w * 0.3, h * 0.3, w * 0.4, h * 0.25), Color("2a3036"), false, 1.5)
				draw_string(ThemeDB.fallback_font, Vector2(4, h - 5), "BIO-%d" % (r.randi() % 90 + 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.9, 0.85, 0.7))
			_:   # server: ארון שרתים גבוה עם נורות
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), Color("23292f"), 0.15, 0.3)
				var y := 6.0
				while y < h - 8.0:
					draw_rect(Rect2(4, y, w - 8, 8), Color("1a1e22"))
					for k in 3:
						draw_circle(Vector2(8 + k * 5, y + 4), 1.2, Color(0.3, 1.0, 0.4) if r.randf() < 0.6 else Color(1.0, 0.6, 0.2))
					y += 11.0
				draw_line(Vector2(w, 4), Vector2(w + 8, h * 0.6), Color("0c0e10"), 2.0)   # כבל קרוע
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.5), false, 1.2)
		if brick != null and is_instance_valid(brick):   # הסדקים של הבלוק
			for pts in brick._cracks:
				draw_polyline(pts, Color(0.05, 0.05, 0.06, 0.85), 1.4)


# ============ מיכל נוזל עם נבדק (מונפש) ============
class LiquidTank extends Node2D:
	var seed_v := 0
	var height := 260.0
	var radius := 42.0
	var _t := 0.0
	var _tint := Color(0.3, 0.9, 0.5)

	func _ready() -> void:
		z_index = -2
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		_t = r.randf() * 20.0
		_tint = [Color(0.3, 0.9, 0.5), Color(0.3, 0.75, 1.0), Color(0.9, 0.5, 0.3)][r.randi() % 3]

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(0, -height * 0.5), 200.0) and Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var top := -height
		draw_rect(Rect2(-radius - 8, -2, radius * 2 + 16, 62), Color("2a3036"))
		draw_rect(Rect2(-radius - 8, top - 18, radius * 2 + 16, 18), Color("2a3036"))
		draw_rect(Rect2(-radius, top, radius * 2, height), Color(_tint.r * 0.25, _tint.g * 0.3, _tint.b * 0.3, 0.95))
		var lvl := top + 16.0 + sin(_t * 0.6) * 2.0
		draw_rect(Rect2(-radius, lvl, radius * 2, -lvl), Color(_tint, 0.35))
		# נבדק צף
		var bob := sin(_t * 0.7) * 6.0
		var c := Vector2(sin(_t * 0.3) * 4.0, -height * 0.55 + bob)
		var sil := Color(0.06, 0.1, 0.09, 0.85)
		draw_circle(c + Vector2(0, -44), 11.0, sil)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-12, -34), c + Vector2(12, -34), c + Vector2(10, 20), c + Vector2(-10, 20)]), sil)
		draw_line(c + Vector2(-11, -30), c + Vector2(-26, 0 + bob), sil, 5.0)
		draw_line(c + Vector2(11, -30), c + Vector2(24, -4 - bob), sil, 5.0)
		draw_line(c + Vector2(-5, 18), c + Vector2(-8, 60), sil, 6.0)
		draw_line(c + Vector2(5, 18), c + Vector2(9, 58 + bob * 0.5), sil, 6.0)
		draw_line(c + Vector2(0, -55), Vector2(0, top), Color(0.05, 0.05, 0.05, 0.7), 1.5)
		# בועות
		for i in 8:
			var k := fmod(_t * 0.25 + float(i) * 0.137, 1.0)
			var bx := sin(float(i) * 2.3 + _t) * radius * 0.7
			draw_circle(Vector2(bx, lerpf(-6.0, lvl, k)), 1.5 + 2.0 * k, Color(1, 1, 1, 0.35 * (1.0 - k)))
		# זכוכית
		draw_rect(Rect2(-radius + 6, top + 4, 6, height - 8), Color(1, 1, 1, 0.12))
		draw_line(Vector2(-radius, top), Vector2(-radius, 0), Color(0.7, 0.9, 1.0, 0.5), 2.0)
		draw_line(Vector2(radius, top), Vector2(radius, 0), Color(0.7, 0.9, 1.0, 0.5), 2.0)
		Art.glow(self, Vector2(0, -height * 0.5), radius * 1.6, Color(_tint, 0.1))
		for i in 3:   # נורות בבסיס
			var on := int(_t * 2.0 + float(i)) % 3 != 0
			draw_circle(Vector2(-20 + i * 20, 20), 2.5, Color(0.4, 1.0, 0.5) if on else Color(0.15, 0.3, 0.2))


# ============ צינור דולף (כימיקלים ירוקים) ============
class LeakPipe extends Node2D:
	var fall := 200.0         # מהצינור עד הרצפה
	var _drops := []
	var _fumes := []
	var _t := 0.0

	func _ready() -> void:
		z_index = -1
		_t = randf() * 3.0

	func _process(delta: float) -> void:
		if not Art.on_screen(self, global_position + Vector2(0, fall * 0.5), 260.0):
			return
		_t -= delta
		if _t <= 0.0:
			_t = randf_range(0.25, 0.6)
			_drops.append([0.0, 0.0])
			if randf() < 0.5:
				_fumes.append([Vector2(randf_range(-16, 16), fall - 4.0), 0.0, randf_range(1.5, 2.6)])
		for d in _drops:
			d[1] += 900.0 * delta
			d[0] += d[1] * delta
		_drops = _drops.filter(func(d: Array) -> bool: return float(d[0]) < fall)
		for f in _fumes:
			f[1] += delta
			f[0] += Vector2(sin(float(f[1]) * 2.0) * 6.0, -22.0) * delta
		_fumes = _fumes.filter(func(f: Array) -> bool: return float(f[1]) < float(f[2]))
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-60, -8, 120, 14), Color("3a4248"))
		draw_rect(Rect2(-60, -8, 120, 3), Color(1, 1, 1, 0.1))
		draw_rect(Rect2(-8, -11, 6, 20), Color("2a3036"))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, 6), Vector2(4, 6), Vector2(1, 12)]), Color(0.5, 1.0, 0.3, 0.9))   # סדק
		Art.glow(self, Vector2(1, 8), 10.0, Color(0.5, 1.0, 0.3, 0.4))
		for d in _drops:
			var y: float = d[0]
			draw_line(Vector2(1, 8 + y - 6.0), Vector2(1, 8 + y), Color(0.55, 1.0, 0.35, 0.9), 2.0)
		for f in _fumes:
			var k: float = float(f[1]) / float(f[2])
			draw_circle(f[0], 8.0 + k * 22.0, Color(0.45, 0.9, 0.3, 0.16 * (1.0 - k)))


# ============ אור חירום אדום שפועם בשולי המסך ============
class AlarmPulse extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var k := pow(absf(sin(_t * 1.1)), 4.0)
		var a := 0.1 * k
		if a < 0.005:
			return
		for i in 6:
			var d := float(i) * 14.0
			var c := Color(0.9, 0.05, 0.03, a * (1.0 - float(i) / 6.0))
			draw_rect(Rect2(0, d, vp.x, 14), c)
			draw_rect(Rect2(0, vp.y - d - 14.0, vp.x, 14), c)
			draw_rect(Rect2(d, 0, 14, vp.y), c)
			draw_rect(Rect2(vp.x - d - 14.0, 0, 14, vp.y), c)
