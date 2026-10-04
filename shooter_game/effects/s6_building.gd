extends RefCounted
# ============================================================
#  S6 BUILDING - כל הקישוטים של שלב 6 ("NO SAFE FLOOR"): בניין דירות/משרדים הרוס.
#  הכל מצויר בקוד, בעולם (z_index שלילי = מאחורי הדמויות).
#
#    Room        - חדר אחד (קומת קרקע / קומה שנייה / לובי בגובה כפול): קיר אחורי עם חלונות
#                  (חורים שדרכם רואים את קו הרקיע הגשום), תקרה, רהיטים ברקע, גרפיטי.
#                  סוגים: lobby, office, corridor, utility, barricade, apartment, bathroom, office2
#    WindowRain  - טיפות גשם שזולגות על הזגוגיות (מונפש, רק על המסך)
#    FloorTrim   - פני הריצפה של קומת הקרקע (שיש / שטיח / לינוליאום) מעל הכביש של main.gd
#    RoofChunk   - תקרת הבניין + גג (מיכל מים, מזגנים, אנטנות) ב-1024 פיקסלים
#    Beacon      - נורה אדומה מהבהבת על אנטנה
#    NeonSign    - שלט ניאון "HALCYON TOWERS" עם אותיות מהבהבות
#    Chandelier  - נברשת מתנדנדת בלובי
#    Elevator    - מעליות שבורות: דלתות פתוחות, פיר, כבלים מתנדנדים, תא תקוע
#    PipeOutlet  - צינור על הקיר (ממנו יוצאים האדים)
#    Puddle      - שלולית מחזירת אור עם אדוות
#    Exterior    - חזית הבניין בסוף + החצר הגשומה (זירת הבוס)
#
#  איך משנים: צבעים ב-PALETTES, טקסטים ב-GRAFFITI, רהיטים ב-Room._plan_items().
#  ביצועים: כל חדר מצויר פעם אחת (סטטי). רק מה שזז מצויר מחדש, ורק כשהוא על המסך.
# ============================================================

const Art := preload("res://art.gd")

const GRAFFITI := ["THEY LEARN", "NO SAFE FLOOR", "LOOK UP", "DON'T RELOAD NEAR THEM", "THEY WAIT", "HE GIVES ORDERS",
	"STAY ON THE LADDERS", "3RD FLOOR GONE", "IT GRABBED MIA", "CEILING!!", "RUN", "HELP 2B"]

# [קיר עליון, קיר תחתון, פס עץ/קישוט, צבע משני]
const PALETTES := {
	"lobby": [Color("5c5850"), Color("3e3a34"), Color("8a7440"), Color("2e2a26")],
	"office": [Color("4a5458"), Color("3a4246"), Color("2e3436"), Color("5a6468")],
	"office2": [Color("4e5250"), Color("3c403e"), Color("2c302e"), Color("5e6260")],
	"corridor": [Color("5a5a4c"), Color("3e4a3c"), Color("2a3028"), Color("6a6a58")],
	"utility": [Color("44474a"), Color("36383a"), Color("5a4a2a"), Color("50545a")],
	"barricade": [Color("4e3c34"), Color("3a2c26"), Color("2a201c"), Color("5e4a40")],
	"apartment": [Color("54464e"), Color("40363c"), Color("2e2428"), Color("64545c")],
	"apartment_b": [Color("46524a"), Color("36403a"), Color("262e28"), Color("56625a")],
	"apartment_c": [Color("5a5240"), Color("443e30"), Color("2e2a20"), Color("6a6250")],
	"bathroom": [Color("5a6668"), Color("4a5658"), Color("3a4446"), Color("7a8688")],
}


# ============================================================
#  חדר
# ============================================================
class Room extends Node2D:
	var w := 600.0
	var kind := "office"
	var band := 1                 # 1 = קומת קרקע, 2 = קומה שנייה, 0 = לובי בגובה כפול
	var seed_v := 0
	var gaps := []                # [[x0, x1]] מקומי: איפה הרצפה של הקומה השנייה חסרה
	var open := []                # [[x0, x1]] מקומי: בלי קיר אחורי (מרפסת / קיר שקרס)
	var busy := []                # [[x0, x1]] מקומי: בלי חלונות (מעלית...)
	var windows: Array[Rect2] = []
	var holes: Array[Rect2] = []
	var screens: Array[Vector2] = []   # מקומי: מסכי מחשב (השלב מוסיף Ambient.Screen)
	var sparks: Array[Vector2] = []    # מקומי: ארון חשמל (השלב מוסיף ניצוצות)
	var items := []
	var variant := ""

	func _ready() -> void:
		z_index = -3
		var wr := WindowRain.new()
		wr.rects = windows
		add_child(wr)

	func ytop() -> float:
		return -160.0 if band == 1 else -302.0

	func ybot() -> float:
		return -160.0 if band == 2 else 0.0

	func base() -> float:
		return -160.0 if band == 2 else 0.0

	func ceil_y() -> float:
		return -146.0 if band == 1 else -302.0

	func _in(ranges: Array, x0: float, x1: float) -> bool:
		for rg in ranges:
			if x1 > float(rg[0]) and x0 < float(rg[1]):
				return true
		return false

	# מחשב חלונות, חורים ורהיטים (דטרמיניסטי לפי seed_v). נקרא לפני add_child
	func plan() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		windows.clear()
		holes.clear()
		var b := base()
		if band == 0:   # לובי: חלונות ענק לכל הגובה
			var x := 50.0
			while x < w - 110.0:
				if not _in(busy, x - 10.0, x + 100.0):
					windows.append(Rect2(x, -284.0, 86.0, 236.0))
				x += 124.0
		else:
			var n := maxi(1, int(w / 230.0))
			for i in n:
				var cx := (float(i) + 0.5) * w / float(n) + r.randf_range(-30.0, 30.0)
				var ww := r.randf_range(62.0, 96.0)
				var wy := b - 124.0
				var wh := 76.0
				if kind == "utility":
					ww = 46.0
					wy = ceil_y() + 12.0
					wh = 26.0
				elif kind == "bathroom":
					ww = 36.0
					wh = 44.0
					wy = b - 116.0
				var rect := Rect2(cx - ww * 0.5, wy, ww, wh)
				if rect.position.x < 24.0 or rect.end.x > w - 24.0 or _in(open, rect.position.x - 10.0, rect.end.x + 10.0) or _in(busy, rect.position.x, rect.end.x):
					continue
				windows.append(rect)
			if r.randf() < 0.35 and w > 300.0:   # חור בקיר (פגיעה / פיצוץ)
				var hw := r.randf_range(70.0, 120.0)
				var hx := r.randf_range(40.0, w - hw - 40.0)
				var hr := Rect2(hx, b - r.randf_range(112.0, 126.0), hw, r.randf_range(52.0, 78.0))
				var ok := not _in(open, hr.position.x - 20.0, hr.end.x + 20.0) and not _in(busy, hr.position.x, hr.end.x)
				for wr in windows:
					if wr.grow(18.0).intersects(hr):
						ok = false
				if ok:
					holes.append(hr)
		_plan_items(r)

	func _plan_items(r: RandomNumberGenerator) -> void:
		items.clear()
		screens.clear()
		sparks.clear()
		var b := base()
		var x := 40.0
		while x < w - 60.0:
			if _in(open, x - 10.0, x + 90.0) or _in(busy, x - 10.0, x + 90.0):
				x += 60.0
				continue
			var pick := ""
			var adv := 80.0
			match kind:
				"office", "office2":
					pick = ["cubicle", "cubicle", "shelf", "cooler", "printer", "plant"][r.randi() % 6]
				"corridor":
					pick = ["door", "door", "extinguisher", "notice", "bench"][r.randi() % 5]
				"utility":
					pick = ["boiler", "fusebox", "shelf", "pipes", "mop"][r.randi() % 5]
				"barricade":
					pick = ["mattress", "camp", "planks", "cans"][r.randi() % 4]
				"apartment":
					pick = ["sofa", "tv", "shelf", "lamp", "kitchen", "bed", "wardrobe", "frames"][r.randi() % 8]
				"bathroom":
					pick = ["tub", "sink", "toilet"][r.randi() % 3]
				"lobby":
					pick = ["plant", "mailboxes", "bench", "directory", "plant"][r.randi() % 5]
			match pick:
				"cubicle":
					adv = 96.0
					screens.append(Vector2(x + 30.0, b - 54.0))
				"kitchen":
					adv = 120.0
				"bed", "sofa", "tub", "boiler", "mattress":
					adv = 100.0
				"door":
					adv = 70.0
				"fusebox":
					sparks.append(Vector2(x + 12.0, b - 82.0))
					adv = 50.0
				"tv":
					screens.append(Vector2(x + 6.0, b - 50.0))
				"frames", "lamp", "plant", "extinguisher", "notice", "mop", "cans", "toilet", "sink":
					adv = 56.0
			items.append([pick, x])
			x += adv + r.randf_range(10.0, 60.0)

	# ---- צביעת אזור בלי החורים (חלונות / חורים / מרפסות) ----
	func _cuts() -> Array:
		var out: Array = []
		for wr in windows:
			out.append(wr)
		for hr in holes:
			out.append(hr)
		var top := ytop()
		var bot := base() if band == 2 else ybot()
		for o in open:
			out.append(Rect2(float(o[0]), top - 1.0, float(o[1]) - float(o[0]), bot - top + 1.0))
		return out

	func _spans(xa: float, xb: float, y0: float, y1: float, cuts: Array) -> Array:
		var spans := [[y0, y1]]
		var mx := (xa + xb) * 0.5
		for c in cuts:
			var cr: Rect2 = c
			if mx <= cr.position.x or mx >= cr.end.x:
				continue
			var out := []
			for s in spans:
				var s0: float = s[0]
				var s1: float = s[1]
				if cr.end.y <= s0 or cr.position.y >= s1:
					out.append(s)
					continue
				if cr.position.y > s0:
					out.append([s0, cr.position.y])
				if cr.end.y < s1:
					out.append([cr.end.y, s1])
			spans = out
		return spans

	func _paint(x0: float, x1: float, y0: float, y1: float, ct: Color, cb: Color, cuts: Array) -> void:
		var xs := [x0, x1]
		for c in cuts:
			var cr: Rect2 = c
			if cr.position.x > x0 and cr.position.x < x1:
				xs.append(cr.position.x)
			if cr.end.x > x0 and cr.end.x < x1:
				xs.append(cr.end.x)
		xs.sort()
		for i in xs.size() - 1:
			var xa: float = xs[i]
			var xb: float = xs[i + 1]
			if xb - xa < 0.01:
				continue
			for s in _spans(xa, xb, y0, y1, cuts):
				var s0: float = s[0]
				var s1: float = s[1]
				var k0 := (s0 - y0) / maxf(y1 - y0, 1.0)
				var k1 := (s1 - y0) / maxf(y1 - y0, 1.0)
				var c0 := ct.lerp(cb, k0)
				var c1 := ct.lerp(cb, k1)
				draw_polygon(PackedVector2Array([Vector2(xa, s0), Vector2(xb, s0), Vector2(xb, s1), Vector2(xa, s1)]), PackedColorArray([c0, c0, c1, c1]))

	func _pal() -> Array:
		var key := kind
		if kind == "apartment" and variant != "":
			key = variant
		return PALETTES.get(key, PALETTES["office"])

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v + 11
		var pal := _pal()
		var wall: Color = pal[0]
		var low: Color = pal[1]
		var trim: Color = pal[2]
		var acc: Color = pal[3]
		var top := ytop()
		var bot := ybot()
		var b := base()
		var c := ceil_y()
		var cuts := _cuts()
		# קיר: בהיר באמצע, כהה ליד התקרה
		_paint(0.0, w, top, bot, wall.darkened(0.35), wall.darkened(0.05), cuts)
		# חצי תחתון / טפט / אריחים
		match kind:
			"apartment":
				var x := 6.0
				while x < w:
					_paint(x, x + 2.0, c + 4.0, b - 34.0, Color(acc, 0.35), Color(acc, 0.35), cuts)
					x += 15.0
				_paint(0.0, w, b - 34.0, b, low, low.darkened(0.2), cuts)
				_paint(0.0, w, b - 36.0, b - 33.0, trim, trim, cuts)
			"bathroom":
				var y := c + 6.0
				while y < b:
					_paint(0.0, w, y, y + 1.0, Color(0.2, 0.24, 0.25, 0.6), Color(0.2, 0.24, 0.25, 0.6), cuts)
					y += 10.0
				var x2 := 0.0
				while x2 < w:
					_paint(x2, x2 + 1.0, c + 6.0, b, Color(0.2, 0.24, 0.25, 0.6), Color(0.2, 0.24, 0.25, 0.6), cuts)
					x2 += 10.0
			"lobby":
				_paint(0.0, w, b - 54.0, b, low, low.darkened(0.25), cuts)
				_paint(0.0, w, b - 56.0, b - 53.0, trim, trim, cuts)
				_paint(0.0, w, -150.0, -147.0, trim.darkened(0.2), trim.darkened(0.2), cuts)
				var x3 := 0.0
				while x3 < w:   # פאנלים של שיש
					_paint(x3, x3 + 1.0, -147.0, b - 56.0, Color(0, 0, 0, 0.18), Color(0, 0, 0, 0.18), cuts)
					x3 += 64.0
			"barricade", "utility":
				var y2 := c + 10.0
				var row := 0
				while y2 < b:   # לבנים / בלוקים חשופים
					_paint(0.0, w, y2, y2 + 1.0, Color(0, 0, 0, 0.2), Color(0, 0, 0, 0.2), cuts)
					var off := 0.0 if row % 2 == 0 else 22.0
					var xb := off
					while xb < w:
						_paint(xb, xb + 1.0, y2, minf(y2 + 14.0, b), Color(0, 0, 0, 0.16), Color(0, 0, 0, 0.16), cuts)
						xb += 44.0
					y2 += 14.0
					row += 1
			_:
				_paint(0.0, w, b - 30.0, b, low, low.darkened(0.2), cuts)
				_paint(0.0, w, b - 31.0, b - 29.0, trim, trim, cuts)
		# כתמי רטיבות / עובש
		for i in int(w / 260.0) + 1:
			var sx := r.randf_range(10.0, w - 40.0)
			var sh := r.randf_range(30.0, 80.0)
			_paint(sx, sx + r.randf_range(14.0, 40.0), c + 4.0, c + 4.0 + sh, Color(0.05, 0.06, 0.04, 0.25), Color(0.05, 0.06, 0.04, 0.0), cuts)
		# חלונות
		for wr in windows:
			_window(wr, r)
		for hr in holes:
			_hole(hr, r)
		for o in open:
			_balcony_frame(float(o[0]), float(o[1]))
		# רהיטים ברקע
		for it in items:
			_item(str(it[0]), float(it[1]), b, r)
		# גרפיטי, דם
		var f := ThemeDB.fallback_font
		if r.randf() < 0.75 and kind != "lobby":
			var tx := r.randf_range(30.0, maxf(w - 220.0, 40.0))
			var ty := b - r.randf_range(60.0, 90.0)
			if _spans(tx, tx + 1.0, ty - 12.0, ty, cuts).size() > 0 and not _in(open, tx, tx + 180.0):
				var tag: String = GRAFFITI[r.randi() % GRAFFITI.size()]
				var gc := Color(0.7, 0.12, 0.1, 0.75) if r.randf() < 0.6 else Color(0.85, 0.85, 0.8, 0.55)
				draw_string(f, Vector2(tx, ty), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, gc)
				draw_line(Vector2(tx + 6, ty + 2), Vector2(tx + 6, ty + 14), Color(gc, gc.a * 0.6), 1.0)   # צבע נוזל
		for i in 2:
			if r.randf() < 0.4 and kind != "lobby":   # טביעת יד מדממת / מריחה
				var hx := r.randf_range(20.0, w - 20.0)
				var hy := b - r.randf_range(30.0, 70.0)
				if not _in(open, hx - 10.0, hx + 10.0):
					for k in 4:
						draw_line(Vector2(hx + float(k) * 2.5, hy), Vector2(hx + float(k) * 2.5 + 1.0, hy + r.randf_range(14.0, 30.0)), Color(0.35, 0.03, 0.03, 0.6), 2.0)
		# פס תחתון (פאנל) + תקרה
		_paint(0.0, w, b - 5.0, b, trim.darkened(0.3), trim.darkened(0.4), cuts)
		if kind == "lobby":
			_lobby_extras(r)
		draw_rect(Rect2(0, c, w, 5), Color("1c1c1e"))
		_ceiling(r, c)
		# רצפה שקרסה: קצוות שבורים ברקע + ערימת הריסות למטה
		for g in gaps:
			_gap(float(g[0]), float(g[1]), r)

	# ---- לובי: דלפק קבלה, אותיות מפליז, שלט קומות ----
	func _lobby_extras(r: RandomNumberGenerator) -> void:
		var f := ThemeDB.fallback_font
		var gold := Color("8a7440")
		draw_string(f, Vector2(842, -196), "HALCYON", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, gold.darkened(0.1))
		draw_string(f, Vector2(852, -172), "TOWERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, gold.darkened(0.2))
		draw_line(Vector2(840, -166), Vector2(960, -166), gold.darkened(0.3), 1.5)
		# דלפק קבלה מעוגל
		draw_colored_polygon(PackedVector2Array([Vector2(840, 0), Vector2(846, -44), Vector2(980, -44), Vector2(986, 0)]), Color("3e3428"))
		draw_rect(Rect2(838, -48, 150, 5), Color("6a5a40"))
		draw_rect(Rect2(870, -62, 22, 14), Color("1c1e22"))   # מחשב
		draw_rect(Rect2(930, -56, 10, 8), Color("2a2a2c"))   # טלפון
		draw_colored_polygon(PackedVector2Array([Vector2(890, -30), Vector2(930, -34), Vector2(920, -14)]), Color(0.35, 0.03, 0.03, 0.6))
		# שעון קיר שנעצר
		draw_circle(Vector2(905, -232), 14.0, Color("2a2622"))
		draw_circle(Vector2(905, -232), 11.0, Color("b8b0a0"))
		draw_line(Vector2(905, -232), Vector2(905, -241), Color("1a1a1a"), 1.5)
		draw_line(Vector2(905, -232), Vector2(911, -228), Color("1a1a1a"), 1.5)
		# גרפיטי גדול בלובי
		draw_string(f, Vector2(60, -40), "NO SAFE FLOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.7, 0.1, 0.08, 0.7))
		draw_string(f, Vector2(830, -110), "THEY'RE IN THE CEILING", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.85, 0.8, 0.5))

	# ---- חלון ----
	func _window(wr: Rect2, r: RandomNumberGenerator) -> void:
		var fc := Color("1e2024")
		draw_rect(wr, Color(0.55, 0.65, 0.85, 0.07))   # זכוכית
		draw_line(wr.position + Vector2(wr.size.x * 0.2, wr.size.y), wr.position + Vector2(wr.size.x * 0.65, 0), Color(0.8, 0.9, 1.0, 0.08), 6.0)
		var broken := r.randf() < 0.45
		if broken:   # רסיסים בקצוות + סדקים
			var cpt := wr.position + Vector2(r.randf_range(0.3, 0.7), r.randf_range(0.3, 0.7)) * wr.size
			for i in 6:
				var a := r.randf() * TAU
				var e := cpt + Vector2.from_angle(a) * maxf(wr.size.x, wr.size.y)
				e = Vector2(clampf(e.x, wr.position.x, wr.end.x), clampf(e.y, wr.position.y, wr.end.y))
				draw_line(cpt, e, Color(0.85, 0.9, 1.0, 0.25), 1.0)
			for i in 5:
				var sx := wr.position.x + r.randf_range(0.0, wr.size.x - 10.0)
				var top := r.randf() < 0.5
				var yy := wr.position.y if top else wr.end.y
				var dy := r.randf_range(8.0, 20.0) * (1.0 if top else -1.0)
				draw_colored_polygon(PackedVector2Array([Vector2(sx, yy), Vector2(sx + r.randf_range(6.0, 14.0), yy), Vector2(sx + r.randf_range(0.0, 8.0), yy + dy)]), Color(0.7, 0.8, 0.9, 0.3))
		match kind:
			"office", "office2", "lobby":
				if r.randf() < 0.4 and kind != "lobby":   # תריס חצי סגור
					var depth := wr.size.y * r.randf_range(0.25, 0.7)
					var y := wr.position.y
					while y < wr.position.y + depth:
						draw_rect(Rect2(wr.position.x, y, wr.size.x, 2.5), Color("5a5e60"))
						y += 4.5
					draw_line(Vector2(wr.position.x + 6, wr.position.y), Vector2(wr.position.x + 6, wr.position.y + depth + 10), Color("3a3a3a"), 1.0)
			"apartment":   # וילונות
				var cc := Color.from_hsv(r.randf(), 0.35, 0.35)
				for side in [0, 1]:
					var cw := wr.size.x * r.randf_range(0.18, 0.32)
					var x0: float = wr.position.x - 6.0 if side == 0 else wr.end.x + 6.0 - cw
					var torn := r.randf() < 0.3
					var pts := PackedVector2Array([Vector2(x0, wr.position.y - 6), Vector2(x0 + cw, wr.position.y - 6), Vector2(x0 + cw * (0.7 if side == 0 else 1.0), wr.end.y + (-20.0 if torn else 8.0)), Vector2(x0 + cw * (0.0 if side == 0 else 0.3), wr.end.y + 8.0)])
					draw_colored_polygon(pts, cc)
					for k in 3:
						var fx := x0 + cw * (0.25 + 0.25 * float(k))
						draw_line(Vector2(fx, wr.position.y - 4), Vector2(fx, wr.end.y), cc.darkened(0.35), 1.0)
				draw_line(Vector2(wr.position.x - 10, wr.position.y - 7), Vector2(wr.end.x + 10, wr.position.y - 7), Color("2a2622"), 2.0)
			"barricade":   # קרשים על החלון
				for i in 3:
					var y0 := wr.position.y + wr.size.y * (0.2 + 0.3 * float(i))
					var a := r.randf_range(-0.25, 0.25)
					var p0 := Vector2(wr.position.x - 8, y0)
					var p1 := Vector2(wr.end.x + 8, y0 + tan(a) * wr.size.x)
					var nv := Vector2(0, 4)
					draw_colored_polygon(PackedVector2Array([p0 - nv, p1 - nv, p1 + nv, p0 + nv]), Color("6a4e32"))
					draw_line(p0 - nv, p1 - nv, Color(0, 0, 0, 0.5), 1.0)
					draw_circle(p0 + Vector2(6, 0), 1.2, Color("1a1a1a"))
					draw_circle(p1 + Vector2(-6, 0), 1.2, Color("1a1a1a"))
		# מסגרת + חלוקה
		draw_rect(wr, fc, false, 3.0)
		if kind != "bathroom" and kind != "utility":
			draw_line(Vector2(wr.get_center().x, wr.position.y), Vector2(wr.get_center().x, wr.end.y), fc, 2.0)
			if kind != "lobby":
				draw_line(Vector2(wr.position.x, wr.position.y + wr.size.y * 0.4), Vector2(wr.end.x, wr.position.y + wr.size.y * 0.4), fc, 2.0)
			else:
				for k in 3:
					draw_line(Vector2(wr.position.x, wr.position.y + wr.size.y * (0.25 + 0.25 * float(k))), Vector2(wr.end.x, wr.position.y + wr.size.y * (0.25 + 0.25 * float(k))), fc, 2.0)
		else:
			draw_rect(wr, Color(0.7, 0.75, 0.8, 0.12))   # זכוכית חלבית
		draw_rect(Rect2(wr.position.x - 5, wr.end.y, wr.size.x + 10, 4), Color("2a2a2c"))   # אדן

	# ---- חור בקיר (שוליים משוננים + ברזלים) ----
	func _hole(hr: Rect2, r: RandomNumberGenerator) -> void:
		var wall: Color = _pal()[0]
		var edge := wall.darkened(0.25)
		var n := 7
		for side in 4:
			for i in n:
				var u := (float(i) + r.randf()) / float(n)
				var p: Vector2
				var inward: Vector2
				match side:
					0:
						p = Vector2(hr.position.x + u * hr.size.x, hr.position.y)
						inward = Vector2(0, 1)
					1:
						p = Vector2(hr.position.x + u * hr.size.x, hr.end.y)
						inward = Vector2(0, -1)
					2:
						p = Vector2(hr.position.x, hr.position.y + u * hr.size.y)
						inward = Vector2(1, 0)
					_:
						p = Vector2(hr.end.x, hr.position.y + u * hr.size.y)
						inward = Vector2(-1, 0)
				var depth := r.randf_range(3.0, 12.0)
				var tang := Vector2(-inward.y, inward.x) * r.randf_range(5.0, 9.0)
				draw_colored_polygon(PackedVector2Array([p - tang, p + tang, p + inward * depth]), edge)
		for i in 3:   # ברזלים חשופים
			var y := hr.position.y + hr.size.y * (0.25 + 0.25 * float(i))
			draw_line(Vector2(hr.position.x - 2, y), Vector2(hr.position.x + r.randf_range(8.0, 20.0), y + r.randf_range(-4.0, 6.0)), Color("6a4a3a"), 1.2)
			draw_line(Vector2(hr.end.x + 2, y), Vector2(hr.end.x - r.randf_range(8.0, 20.0), y + r.randf_range(-4.0, 6.0)), Color("6a4a3a"), 1.2)

	# ---- מרפסת: מסגרת דלת הזזה פתוחה בצדדים ----
	func _balcony_frame(x0: float, x1: float) -> void:
		var fc := Color("26282c")
		var top := ytop()
		var b := base()
		for xx in [x0, x1]:
			draw_rect(Rect2(float(xx) - 6.0, top, 12.0, b - top), Color("3a3a3e"))
			draw_rect(Rect2(float(xx) - 6.0, top, 12.0, b - top), fc, false, 2.0)
		draw_rect(Rect2(x0, top, x1 - x0, 10.0), Color("3a3a3e"))   # משקוף / גגון
		draw_colored_polygon(PackedVector2Array([Vector2(x0 - 10, top + 10), Vector2(x1 + 10, top + 10), Vector2(x1 + 4, top + 22), Vector2(x0 - 4, top + 22)]), Color("5a2a26"))   # סוכך
		for k in int((x1 - x0) / 18.0):
			draw_line(Vector2(x0 + float(k) * 18.0, top + 10), Vector2(x0 + float(k) * 18.0 - 3.0, top + 22), Color("3a1a18"), 1.0)

	# ---- תקרה: אריחים חסרים, כבלים, צינורות ----
	func _ceiling(r: RandomNumberGenerator, c: float) -> void:
		match kind:
			"office", "office2", "corridor":
				draw_line(Vector2(0, c + 9), Vector2(w, c + 9), Color(0.1, 0.1, 0.11, 0.7), 1.0)
				var x := r.randf_range(0.0, 60.0)
				while x < w:
					draw_line(Vector2(x, c + 5), Vector2(x, c + 9), Color(0.1, 0.1, 0.11, 0.7), 1.0)
					if r.randf() < 0.25:   # אריח תלוי באלכסון
						draw_colored_polygon(PackedVector2Array([Vector2(x, c + 9), Vector2(x + 30, c + 9), Vector2(x + 26, c + 26), Vector2(x - 2, c + 14)]), Color("6a6a64"))
					x += 32.0
			"utility", "barricade":
				draw_rect(Rect2(0, c + 8, w, 8), Color("3a3c3e"))   # צינור לאורך התקרה
				draw_line(Vector2(0, c + 9), Vector2(w, c + 9), Color(1, 1, 1, 0.06), 1.0)
				var x2 := 30.0
				while x2 < w:
					draw_rect(Rect2(x2, c + 6, 6, 12), Color("2a2c2e"))
					x2 += 90.0
		for i in int(w / 300.0) + 1:   # כבלים תלויים
			var cx := r.randf_range(20.0, w - 20.0)
			var ln := r.randf_range(14.0, 40.0)
			draw_polyline(PackedVector2Array([Vector2(cx, c + 4), Vector2(cx + 4, c + ln * 0.5), Vector2(cx + 1, c + ln)]), Color("141414"), 1.5, true)

	# ---- רצפה שקרסה ----
	func _gap(g0: float, g1: float, r: RandomNumberGenerator) -> void:
		if band == 2:   # שאריות הבטון שנשארו צמודות לקיר מאחור
			var pts := PackedVector2Array([Vector2(g0, -162), Vector2(g1, -162)])
			var x := g1
			while x > g0:
				pts.append(Vector2(x, -150.0 + r.randf_range(-4.0, 6.0)))
				x -= r.randf_range(8.0, 18.0)
			pts.append(Vector2(g0, -152))
			draw_colored_polygon(pts, Color("3a3836"))
			for i in 4:   # ברזלים תלויים מהשאריות
				var rx := r.randf_range(g0 + 6.0, g1 - 6.0)
				draw_line(Vector2(rx, -150), Vector2(rx + r.randf_range(-6.0, 6.0), -150.0 + r.randf_range(10.0, 26.0)), Color("6a4a3a"), 1.2)
		else:   # הריסות על הריצפה מתחת לחור
			var cx := (g0 + g1) * 0.5
			for i in 7:
				var px := cx + r.randf_range(-(g1 - g0) * 0.6, (g1 - g0) * 0.6)
				var s := r.randf_range(6.0, 14.0)
				draw_colored_polygon(PackedVector2Array([Vector2(px - s, 0), Vector2(px - s * 0.4, -s * 0.9), Vector2(px + s * 0.6, -s * 0.7), Vector2(px + s, 0)]), Color("4a4644").lerp(Color("2e2c2a"), r.randf()))
			# אור ירח/ברק שיורד מלמעלה
			draw_colored_polygon(PackedVector2Array([Vector2(g0 + 6, -146), Vector2(g1 - 6, -146), Vector2(g1 + 20, 0), Vector2(g0 - 20, 0)]), Color(0.7, 0.8, 1.0, 0.04))

	# ============ רהיטים ברקע (צלליות כהות עם פרטים) ============
	func _item(n: String, x: float, b: float, r: RandomNumberGenerator) -> void:
		var dk := Color("24262a")
		var md := Color("34363a")
		match n:
			"cubicle":
				draw_rect(Rect2(x, b - 44, 86, 44), Color("3e4246"))
				draw_rect(Rect2(x, b - 46, 86, 3), Color("2a2c2e"))
				draw_rect(Rect2(x + 8, b - 34, 70, 4), md)   # משטח
				draw_rect(Rect2(x + 24, b - 56, 30, 22), dk)   # מסך (Ambient.Screen מעליו)
				draw_rect(Rect2(x + 36, b - 34, 4, 4), dk)
				draw_rect(Rect2(x + 60, b - 30, 14, 22), Color("2e2a2a"))   # כיסא
				for i in 3:   # ניירות מודבקים
					draw_rect(Rect2(x + 6 + i * 6, b - 42 + (i % 2) * 3, 5, 5), Color(0.7, 0.7, 0.5, 0.5))
			"shelf":
				draw_rect(Rect2(x, b - 92, 50, 92), Color("3a3230"))
				for i in 4:
					draw_rect(Rect2(x + 2, b - 88 + i * 22, 46, 2), dk)
					for j in 5:
						if r.randf() < 0.7:
							var bh := r.randf_range(10.0, 18.0)
							draw_rect(Rect2(x + 4 + j * 8, b - 68 + i * 22 - bh + 2, 6, bh), Color.from_hsv(r.randf(), 0.35, 0.3))
			"cooler":
				draw_rect(Rect2(x, b - 46, 18, 46), Color("8a8a86"))
				Art.oval(self, Vector2(x + 9, b - 58), 8.0, 11.0, Color(0.3, 0.5, 0.75, 0.6), 0.0, Color(0.1, 0.15, 0.2, 0.8), 1.0)
			"printer":
				draw_rect(Rect2(x, b - 30, 40, 30), Color("6a6a66"))
				draw_rect(Rect2(x + 4, b - 34, 32, 4), Color("4a4a46"))
				draw_rect(Rect2(x + 4, b - 22, 24, 3), dk)
			"plant":
				draw_colored_polygon(PackedVector2Array([Vector2(x, b - 22), Vector2(x + 20, b - 22), Vector2(x + 16, b), Vector2(x + 4, b)]), Color("5a3a2a"))
				for i in 6:
					var a := -PI * 0.5 + r.randf_range(-1.0, 1.0)
					var ln := r.randf_range(14.0, 30.0)
					draw_line(Vector2(x + 10, b - 22), Vector2(x + 10, b - 22) + Vector2.from_angle(a) * ln, Color("4a4a2a"), 2.0)
			"door":
				draw_rect(Rect2(x, b - 74, 40, 74), Color("2a2622"))
				var openk := r.randf()
				if openk < 0.4:   # פתוחה: חושך
					draw_rect(Rect2(x + 3, b - 71, 34, 71), Color("0c0c0e"))
					draw_colored_polygon(PackedVector2Array([Vector2(x + 37, b - 71), Vector2(x + 50, b - 76), Vector2(x + 50, b + 2), Vector2(x + 37, b)]), Color("4a3a2e"))
				else:
					draw_rect(Rect2(x + 3, b - 71, 34, 71), Color("4a3a2e"))
					draw_circle(Vector2(x + 31, b - 36), 2.0, Color("a09060"))
					if openk > 0.8:   # אטומה בקרשים
						draw_line(Vector2(x - 2, b - 60), Vector2(x + 42, b - 40), Color("6a4e32"), 5.0)
						draw_line(Vector2(x - 2, b - 30), Vector2(x + 42, b - 50), Color("6a4e32"), 5.0)
				draw_rect(Rect2(x + 14, b - 66, 12, 7), Color("8a7a50"))
				draw_string(ThemeDB.fallback_font, Vector2(x + 15, b - 60), str(1 + r.randi() % 9) + "ABCDEF"[r.randi() % 6], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("1a1a1a"))
			"extinguisher":
				draw_rect(Rect2(x, b - 76, 22, 34), Color("2a2a2c"))
				draw_rect(Rect2(x + 5, b - 72, 12, 26), Color("8a1a14"))
				draw_rect(Rect2(x + 3, b - 92, 30, 10), Color(0.2, 0.6, 0.3, 0.8))   # שלט EXIT
				draw_string(ThemeDB.fallback_font, Vector2(x + 6, b - 84), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.85, 1.0, 0.85))
			"notice":
				draw_rect(Rect2(x, b - 92, 44, 30), Color("5a4630"))
				for i in 5:
					draw_rect(Rect2(x + 3 + (i % 3) * 13, b - 89 + (i / 3) * 13, 11, 11), Color(0.75, 0.72, 0.6, 0.7))
			"bench":
				draw_rect(Rect2(x, b - 18, 60, 5), md)
				draw_rect(Rect2(x + 4, b - 13, 4, 13), dk)
				draw_rect(Rect2(x + 52, b - 13, 4, 13), dk)
			"boiler":
				draw_rect(Rect2(x, b - 84, 50, 84), Color("4a4440"))
				Art.oval(self, Vector2(x + 25, b - 84), 25.0, 6.0, Color("5a5450"), 0.0, Art.NONE)
				draw_rect(Rect2(x + 14, b - 50, 22, 12), Color("2a2624"))
				draw_circle(Vector2(x + 25, b - 64), 6.0, Color("c8c0a0"))
				draw_line(Vector2(x + 25, b - 64), Vector2(x + 29, b - 67), Color("8a1a14"), 1.5)
				draw_rect(Rect2(x + 22, b - 130, 8, 46), Color("3a3634"))
			"fusebox":
				draw_rect(Rect2(x, b - 96, 26, 34), Color("5a5e60"))
				draw_rect(Rect2(x + 3, b - 93, 20, 28), Color("1e2022"))
				for i in 4:
					draw_rect(Rect2(x + 6, b - 90 + i * 6, 6, 3), Color("8a8a80"))
				Art.fill(self, PackedVector2Array([Vector2(x + 8, b - 110), Vector2(x + 18, b - 110), Vector2(x + 13, b - 101)]), Color("e8c020"), Art.OUTLINE, 1.0)   # משולש אזהרה
				draw_line(Vector2(x + 12, b - 62), Vector2(x + 18, b - 40), Color("141414"), 2.0)
			"pipes":
				for i in 3:
					draw_rect(Rect2(x + i * 12, ceil_y() + 5, 7, b - ceil_y() - 5), Color("3e4246").lerp(Color("5a4a3a"), float(i) * 0.3))
				draw_circle(Vector2(x + 15, b - 70), 7.0, Color("8a1a14"))   # ברז
				draw_circle(Vector2(x + 15, b - 70), 3.0, Color("2a0a08"))
			"mop":
				draw_rect(Rect2(x, b - 16, 18, 16), Color("6a6a20"))
				draw_line(Vector2(x + 9, b - 16), Vector2(x + 16, b - 64), Color("6a4a2a"), 2.0)
			"mattress":
				draw_colored_polygon(PackedVector2Array([Vector2(x, b), Vector2(x + 10, b - 76), Vector2(x + 44, b - 80), Vector2(x + 36, b)]), Color("7a7460"))
				for i in 4:
					draw_line(Vector2(x + 12 + i * 7, b - 74), Vector2(x + 8 + i * 7, b - 4), Color("5a5444"), 1.0)
				draw_colored_polygon(PackedVector2Array([Vector2(x + 18, b - 40), Vector2(x + 30, b - 46), Vector2(x + 26, b - 30)]), Color(0.4, 0.05, 0.05, 0.5))
			"camp":
				Art.oval(self, Vector2(x + 30, b - 6), 30.0, 6.0, Color("3a4a3a"), 0.0, Art.NONE)   # שק שינה
				draw_rect(Rect2(x + 60, b - 14, 14, 14), Color("2a2622"))
				Art.oval(self, Vector2(x + 67, b - 18), 9.0, 3.0, Color(1.0, 0.6, 0.2, 0.25), 0.0, Art.NONE)   # נר כבוי
			"planks":
				for i in 4:
					var px := x + float(i) * 9.0
					draw_colored_polygon(PackedVector2Array([Vector2(px, b), Vector2(px + 14, b - 70 - i * 4), Vector2(px + 20, b - 70 - i * 4), Vector2(px + 6, b)]), Color("6a4e32").darkened(float(i) * 0.08))
			"cans":
				for i in 6:
					draw_rect(Rect2(x + (i % 3) * 9, b - 10 - (i / 3) * 10, 8, 10), Color("7a6a50").lerp(Color("8a3a2a"), float(i % 2)))
			"sofa":
				draw_rect(Rect2(x, b - 30, 84, 22), Color("4a3a40"))
				draw_rect(Rect2(x, b - 44, 84, 16), Color("40323a"))
				draw_rect(Rect2(x - 4, b - 34, 10, 26), Color("3a2c32"))
				draw_rect(Rect2(x + 78, b - 34, 10, 26), Color("3a2c32"))
				draw_rect(Rect2(x + 4, b - 8, 4, 8), dk)
				draw_rect(Rect2(x + 76, b - 8, 4, 8), dk)
			"tv":
				draw_rect(Rect2(x - 4, b - 22, 52, 22), Color("2e2620"))
				draw_rect(Rect2(x, b - 54, 44, 32), dk)
			"lamp":
				draw_line(Vector2(x + 10, b), Vector2(x + 10, b - 64), dk, 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(x, b - 62), Vector2(x + 20, b - 62), Vector2(x + 15, b - 78), Vector2(x + 5, b - 78)]), Color("6a5a3a"))
			"kitchen":
				draw_rect(Rect2(x, b - 36, 76, 36), Color("4e4a44"))
				draw_rect(Rect2(x - 2, b - 38, 80, 4), Color("6a6660"))
				for i in 3:
					draw_rect(Rect2(x + 4 + i * 25, b - 30, 20, 26), Color("44403a"))
					draw_rect(Rect2(x + 4 + i * 25, b - 108, 20, 30), Color("44403a"))
				draw_rect(Rect2(x + 84, b - 92, 32, 92), Color("8a8a86"))   # מקרר
				draw_line(Vector2(x + 84, b - 60), Vector2(x + 116, b - 60), Color("5a5a56"), 1.0)
				draw_rect(Rect2(x + 110, b - 84, 2, 16), Color("4a4a46"))
			"bed":
				draw_rect(Rect2(x, b - 22, 92, 16), Color("6a6458"))
				draw_rect(Rect2(x, b - 48, 8, 48), Color("3a2a22"))
				draw_rect(Rect2(x + 6, b - 28, 20, 8), Color("8a8478"))
				draw_colored_polygon(PackedVector2Array([Vector2(x + 30, b - 24), Vector2(x + 92, b - 24), Vector2(x + 96, b - 6), Vector2(x + 28, b - 8)]), Color("4a5a6a"))
				draw_colored_polygon(PackedVector2Array([Vector2(x + 50, b - 24), Vector2(x + 64, b - 26), Vector2(x + 60, b - 14)]), Color(0.4, 0.05, 0.05, 0.6))
			"wardrobe":
				draw_rect(Rect2(x, b - 104, 48, 104), Color("3e3028"))
				draw_line(Vector2(x + 24, b - 102), Vector2(x + 24, b - 2), dk, 1.0)
				draw_circle(Vector2(x + 20, b - 52), 1.5, Color("8a7a50"))
				draw_circle(Vector2(x + 28, b - 52), 1.5, Color("8a7a50"))
			"frames":
				for i in 3:
					var fy := b - 104 + r.randf_range(-6.0, 6.0)
					var fx := x + float(i) * 18.0
					var tilt := r.randf_range(-0.2, 0.2)
					var fr := Transform2D(tilt, Vector2(fx + 7, fy + 9)) * PackedVector2Array([Vector2(-7, -9), Vector2(7, -9), Vector2(7, 9), Vector2(-7, 9)])
					draw_colored_polygon(fr, Color("5a4630"))
					var inner := Transform2D(tilt, Vector2(fx + 7, fy + 9)) * PackedVector2Array([Vector2(-5, -7), Vector2(5, -7), Vector2(5, 7), Vector2(-5, 7)])
					draw_colored_polygon(inner, Color.from_hsv(r.randf(), 0.3, 0.35))
			"tub":
				draw_colored_polygon(PackedVector2Array([Vector2(x, b - 30), Vector2(x + 90, b - 30), Vector2(x + 84, b - 4), Vector2(x + 6, b - 4)]), Color("aab4b4"))
				draw_rect(Rect2(x + 8, b - 4, 6, 4), dk)
				draw_rect(Rect2(x + 76, b - 4, 6, 4), dk)
				draw_line(Vector2(x + 80, b - 30), Vector2(x + 80, b - 50), Color("8a8a86"), 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(x + 30, b - 30), Vector2(x + 50, b - 30), Vector2(x + 44, b - 12)]), Color(0.4, 0.05, 0.05, 0.6))
			"sink":
				draw_rect(Rect2(x, b - 40, 30, 10), Color("aab4b4"))
				draw_rect(Rect2(x + 12, b - 30, 6, 30), Color("8a9494"))
				draw_rect(Rect2(x + 2, b - 86, 26, 34), Color("6a7e88"))   # מראה שבורה
				draw_line(Vector2(x + 6, b - 82), Vector2(x + 22, b - 58), Color(1, 1, 1, 0.3), 1.0)
				draw_line(Vector2(x + 22, b - 82), Vector2(x + 10, b - 62), Color(1, 1, 1, 0.3), 1.0)
			"toilet":
				draw_rect(Rect2(x + 4, b - 46, 16, 22), Color("aab4b4"))
				Art.oval(self, Vector2(x + 14, b - 18), 12.0, 6.0, Color("aab4b4"), 0.0, Art.NONE)
				draw_rect(Rect2(x + 8, b - 14, 12, 14), Color("9aa4a4"))
			"mailboxes":
				draw_rect(Rect2(x, b - 104, 64, 48), Color("6a5a3a"))
				for i in 4:
					for j in 3:
						draw_rect(Rect2(x + 3 + i * 15, b - 101 + j * 15, 13, 13), Color("4a3e28"))
						draw_circle(Vector2(x + 13 + i * 15, b - 95 + j * 15), 1.0, Color("a09060"))
			"directory":
				draw_rect(Rect2(x, b - 120, 50, 64), Color("1e1c1a"))
				for i in 8:
					draw_rect(Rect2(x + 5, b - 114 + i * 7, r.randf_range(18.0, 40.0), 2), Color(0.85, 0.8, 0.6, 0.5))


# ---- טיפות שזולגות על הזכוכית (ילד של החדר) ----
class WindowRain extends Node2D:
	var rects: Array[Rect2] = []
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if rects.is_empty():
			return
		var p := global_position + rects[0].get_center()
		var p2 := global_position + rects[rects.size() - 1].get_center()
		if (Art.on_screen(self, p, 300.0) or Art.on_screen(self, p2, 300.0)) and Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		for wi in rects.size():
			var wr: Rect2 = rects[wi]
			var n := int(wr.size.x / 14.0) + 1
			for i in n:
				var seed_f := float(wi * 31 + i * 7)
				var speed := 30.0 + fmod(seed_f * 13.7, 40.0)
				var y := fmod(_t * speed + seed_f * 17.0, wr.size.y + 20.0) - 10.0
				var x := wr.position.x + (float(i) + 0.5) * wr.size.x / float(n) + sin(seed_f + y * 0.08) * 2.0
				if y < 0.0 or y > wr.size.y:
					continue
				var tail := minf(y, 10.0 + fmod(seed_f, 8.0))
				draw_line(Vector2(x, wr.position.y + y - tail), Vector2(x, wr.position.y + y), Color(0.75, 0.85, 1.0, 0.22), 1.0)
				draw_circle(Vector2(x, wr.position.y + y), 1.2, Color(0.85, 0.92, 1.0, 0.45))


# ============================================================
#  פני הריצפה (מעל הכביש של main.gd)
# ============================================================
class FloorTrim extends Node2D:
	var w := 600.0
	var kind := "office"
	var seed_v := 0

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		draw_rect(Rect2(0, 0, w, 90), Color(0.1, 0.1, 0.12, 0.88))   # יסודות
		draw_rect(Rect2(0, 8, w, 3), Color(0.0, 0.0, 0.0, 0.4))
		match kind:
			"lobby":
				var x := 0.0
				var i := 0
				while x < w:
					draw_rect(Rect2(x, 0, 32, 8), Color("5c5a54") if i % 2 == 0 else Color("3e3c38"))
					x += 32.0
					i += 1
				draw_line(Vector2(0, 0), Vector2(w, 0), Color(0.85, 0.85, 0.8, 0.3), 1.0)
			"office", "office2", "apartment":
				draw_rect(Rect2(0, 0, w, 8), Color("3a3e44"))
				for k in int(w / 6.0):
					draw_line(Vector2(float(k) * 6.0, 1), Vector2(float(k) * 6.0 + 3.0, 6), Color(0, 0, 0, 0.15), 1.0)
			"corridor", "bathroom":
				var x2 := 0.0
				while x2 < w:
					draw_rect(Rect2(x2, 0, 24, 8), Color("4a4a40").lerp(Color("3a3a32"), r.randf()))
					x2 += 24.0
			_:
				draw_rect(Rect2(0, 0, w, 8), Color("3e3e40"))
				for k in int(w / 80.0):   # סדקים בבטון
					var cx := r.randf_range(0.0, w)
					draw_line(Vector2(cx, 0), Vector2(cx + r.randf_range(-8, 8), 8), Color(0, 0, 0, 0.4), 1.0)
		draw_line(Vector2(0, 0), Vector2(w, 0), Color(1, 1, 1, 0.12), 1.0)
		for k in int(w / 140.0):   # כתמים / פסולת קטנה
			var dx := r.randf_range(0.0, w)
			draw_rect(Rect2(dx, -2, r.randf_range(3.0, 8.0), 2), Color(0.2, 0.2, 0.2, 0.6))


# ============================================================
#  תקרת הבניין + הגג (חתיכות של 1024)
# ============================================================
class RoofChunk extends Node2D:
	var w := 1024.0
	var seed_v := 0
	var is_end := false

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		# הלוח עצמו: -320 עד -302 + מעקה גג
		draw_rect(Rect2(0, -320, w, 18), Color("4a4844"))
		draw_rect(Rect2(0, -306, w, 4), Color("2e2c2a"))
		draw_line(Vector2(0, -320), Vector2(w, -320), Color(1, 1, 1, 0.12), 1.0)
		draw_rect(Rect2(0, -332, w, 12), Color("3e3c3a"))
		for i in int(w / 70.0):   # סדקים + נזילות
			var cx := r.randf_range(0.0, w)
			draw_line(Vector2(cx, -320), Vector2(cx + r.randf_range(-6, 6), -302), Color(0, 0, 0, 0.45), 1.0)
		# אובייקטים על הגג (צלליות מול השמיים)
		var x := r.randf_range(20.0, 120.0)
		var sil := Color("15171c")
		while x < w - 60.0:
			var pick := r.randi() % 5
			match pick:
				0:   # מיכל מים על רגליים
					draw_rect(Rect2(x + 6, -360, 4, 28), sil)
					draw_rect(Rect2(x + 50, -360, 4, 28), sil)
					draw_line(Vector2(x + 8, -350), Vector2(x + 52, -340), sil, 2.0)
					draw_colored_polygon(PackedVector2Array([Vector2(x, -360), Vector2(x + 60, -360), Vector2(x + 58, -420), Vector2(x + 2, -420)]), sil)
					draw_colored_polygon(PackedVector2Array([Vector2(x - 2, -420), Vector2(x + 62, -420), Vector2(x + 30, -440)]), sil)
					for k in 3:
						draw_line(Vector2(x + 1, -372 - k * 16), Vector2(x + 59, -372 - k * 16), Color("22252c"), 1.0)
					x += 90.0
				1:   # מזגנים
					draw_rect(Rect2(x, -356, 44, 24), sil)
					draw_circle(Vector2(x + 22, -344), 8.0, Color("1e2128"))
					draw_line(Vector2(x + 16, -344), Vector2(x + 28, -344), sil, 2.0)
					draw_rect(Rect2(x + 50, -350, 30, 18), sil)
					x += 100.0
				2:   # אנטנה (נורה מהבהבת - Beacon)
					draw_line(Vector2(x, -332), Vector2(x, -430), sil, 2.0)
					draw_line(Vector2(x - 10, -400), Vector2(x + 10, -400), sil, 1.5)
					draw_line(Vector2(x - 6, -416), Vector2(x + 6, -416), sil, 1.5)
					x += 60.0
				3:   # צלחת לוויין + ארובות
					draw_rect(Rect2(x, -350, 6, 18), sil)
					Art.oval(self, Vector2(x + 4, -358), 12.0, 6.0, sil, -0.6, Art.NONE)
					draw_rect(Rect2(x + 30, -372, 10, 40), sil)
					draw_rect(Rect2(x + 46, -362, 8, 30), sil)
					x += 80.0
				_:
					x += r.randf_range(60.0, 140.0)
			x += r.randf_range(40.0, 120.0)
		if is_end:   # פינת הבניין
			draw_rect(Rect2(w - 30, -340, 30, 20), Color("3a3836"))


class Beacon extends Node2D:
	var mast := 80.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2
		_t = randf() * 2.0

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(0, -mast)) and Engine.get_process_frames() % 4 == 0:
			queue_redraw()

	func _draw() -> void:
		var sil := Color("15171c")
		draw_line(Vector2(0, 0), Vector2(0, -mast), sil, 2.0)
		draw_line(Vector2(-8, -mast * 0.4), Vector2(0, 0), sil, 1.0)
		draw_line(Vector2(8, -mast * 0.4), Vector2(0, 0), sil, 1.0)
		for k in 3:
			var y := -mast * (0.45 + 0.17 * float(k))
			draw_line(Vector2(-6 + k * 1.5, y), Vector2(6 - k * 1.5, y), sil, 1.5)
		var top := Vector2(0, -mast - 2.0)
		var on := fmod(_t, 1.6) < 0.5
		draw_circle(top, 2.2, Color(1.0, 0.15, 0.1) if on else Color(0.3, 0.05, 0.05))
		if on:
			Art.glow(self, top, 12.0, Color(1.0, 0.2, 0.1, 0.6))


class NeonSign extends Node2D:
	var text := "HALCYON TOWERS"
	var _t := 0.0
	var _dead := 3

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position, 400.0) and Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var fs := 22
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_rect(Rect2(-8, -32, tw + 16, 38), Color("101216"))
		draw_line(Vector2(10, 6), Vector2(10, 20), Color("101216"), 3.0)
		draw_line(Vector2(tw - 10, 6), Vector2(tw - 10, 20), Color("101216"), 3.0)
		var x := 0.0
		for i in text.length():
			var ch := text[i]
			var cw := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var lit := 1.0
			if i == _dead:   # אות מתה שמהבהבת
				lit = 1.0 if fmod(_t * 7.0, 5.0) < 0.6 else 0.12
			elif fmod(_t + float(i) * 0.37, 9.0) < 0.08:
				lit = 0.3
			var c := Color(1.0, 0.35, 0.55)
			if ch != " ":
				Art.glow(self, Vector2(x + cw * 0.5, -10), 14.0, Color(c, 0.35 * lit))
				draw_string(f, Vector2(x, -2), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(c.lightened(0.4), 0.25 + 0.75 * lit))
			x += cw


# ============================================================
#  נברשת מתנדנדת בלובי
# ============================================================
class Chandelier extends Node2D:
	var length := 90.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position, 200.0) and Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var a := sin(_t * 0.9) * 0.07
		var end := Vector2(sin(a), cos(a)) * length
		draw_line(Vector2.ZERO, end, Color("1a1a1a"), 2.0)
		var xf := Transform2D(-a, end)
		var gold := Color("8a7440")
		draw_colored_polygon(xf * PackedVector2Array([Vector2(-36, 0), Vector2(36, 0), Vector2(26, 10), Vector2(-26, 10)]), gold.darkened(0.3))
		draw_colored_polygon(xf * PackedVector2Array([Vector2(-6, -8), Vector2(6, -8), Vector2(4, 22), Vector2(-4, 22)]), gold.darkened(0.2))
		for i in 7:
			var bx := -30.0 + float(i) * 10.0
			var dead := i == 2 or i == 5
			var flick := 1.0 if not dead else (0.4 if fmod(_t * 6.0 + float(i), 4.0) < 0.3 else 0.0)
			var bp: Vector2 = xf * Vector2(bx, -4)
			draw_line(xf * Vector2(bx, 0), bp, gold, 1.5)
			draw_circle(bp, 2.5, Color(1.0, 0.85, 0.55, 0.3 + 0.7 * flick))
			if flick > 0.1:
				Art.glow(self, bp, 12.0, Color(1.0, 0.8, 0.5, 0.25 * flick))
			for k in 2:   # קריסטלים
				var cp: Vector2 = xf * Vector2(bx + 3.0, 12.0 + float(k) * 6.0 + sin(_t * 2.0 + float(i)) * 1.0)
				draw_colored_polygon(PackedVector2Array([cp + Vector2(0, -3), cp + Vector2(2, 0), cp + Vector2(0, 3), cp + Vector2(-2, 0)]), Color(0.8, 0.9, 1.0, 0.5))


# ============================================================
#  מעליות שבורות (בלובי, בגובה כפול). position = על הריצפה, רוחב ~240
# ============================================================
class Elevator extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(120, -150), 250.0) and Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var frame := Color("4a4640")
		var steel := Color("6a6e72")
		# מעלית A: סגורה, "OUT OF ORDER", חיווי קומה מהבהב
		draw_rect(Rect2(0, -96, 76, 96), frame)
		draw_rect(Rect2(6, -88, 31, 88), steel)
		draw_rect(Rect2(39, -88, 31, 88), steel.darkened(0.1))
		draw_line(Vector2(38, -88), Vector2(38, 0), Color("2a2a2a"), 1.0)
		draw_rect(Rect2(20, -114, 36, 14), Color("101010"))
		var lit := fmod(_t, 1.2) < 0.6
		draw_string(ThemeDB.fallback_font, Vector2(24, -103), "▲ 2" if lit else "  ?", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.5, 0.2, 0.9))
		for k in 2:   # סרט אזהרה באיקס
			var s := 1.0 if k == 0 else -1.0
			var p0 := Vector2(38 - 34 * s, -80)
			var p1 := Vector2(38 + 34 * s, -20)
			draw_line(p0, p1, Color("c8a020"), 5.0)
			var m := p0.lerp(p1, 0.5)
			draw_line(m - (p1 - p0) * 0.08, m + (p1 - p0) * 0.08, Color("1a1a1a"), 5.0)
		# פיר B: דלתות שנפרצו, פיר חשוך לכל הגובה, כבלים ותא תקוע
		var sx := 120.0
		draw_rect(Rect2(sx, -302, 90, 302), Color("08090b"))
		draw_rect(Rect2(sx + 6, -302, 3, 302), Color("2a2c30"))
		draw_rect(Rect2(sx + 81, -302, 3, 302), Color("2a2c30"))
		for k in 10:   # קורות בפיר
			draw_line(Vector2(sx, -290 + k * 30), Vector2(sx + 90, -290 + k * 30), Color("16181c"), 2.0)
		var sway := sin(_t * 0.7) * 3.0
		var car_y := -238.0 + sin(_t * 0.5) * 2.0
		for k in 3:   # כבלים
			var cx := sx + 30.0 + float(k) * 15.0
			draw_line(Vector2(cx, -302), Vector2(cx + sway, car_y), Color("2e2e2e"), 1.5)
		# כבל קרוע שמתנדנד מתחת לתא
		var tip := Vector2(sx + 60 + sin(_t * 1.6) * 10.0, car_y + 150)
		draw_polyline(PackedVector2Array([Vector2(sx + 60 + sway, car_y + 70), Vector2(sx + 62 + sway * 2.0, car_y + 110), tip]), Color("2e2e2e"), 1.5, true)
		# התא התקוע (מוטה)
		var xf := Transform2D(0.05 + sway * 0.004, Vector2(sx + 45 + sway, car_y + 35))
		draw_colored_polygon(xf * PackedVector2Array([Vector2(-40, -36), Vector2(40, -36), Vector2(40, 36), Vector2(-40, 36)]), Color("3a3c40"))
		draw_colored_polygon(xf * PackedVector2Array([Vector2(-34, -30), Vector2(34, -30), Vector2(34, 32), Vector2(-34, 32)]), Color("1a1c20"))
		var light := 1.0 if fmod(_t * 3.0, 5.0) > 0.5 else 0.2
		draw_colored_polygon(xf * PackedVector2Array([Vector2(-34, -30), Vector2(34, -30), Vector2(34, 32), Vector2(-34, 32)]), Color(0.9, 0.85, 0.6, 0.12 * light))
		draw_colored_polygon(xf * PackedVector2Array([Vector2(-6, 32), Vector2(4, 32), Vector2(2, 50), Vector2(-3, 48)]), Color("6a7a6a"))   # יד תלויה
		draw_rect(Rect2(sx + 4, -302, 82, 12), Color("2a2a2c"))
		# הדלתות של קומת הקרקע: פרוצות לצדדים
		draw_rect(Rect2(sx - 10, -96, 110, 96), frame, false, 8.0)
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 6, -92), Vector2(sx + 10, -88), Vector2(sx + 10, -4), Vector2(sx - 6, 0)]), steel)
		draw_colored_polygon(PackedVector2Array([Vector2(sx + 80, -88), Vector2(sx + 96, -92), Vector2(sx + 96, 0), Vector2(sx + 80, -4)]), steel.darkened(0.1))
		draw_line(Vector2(sx + 2, -40), Vector2(sx + 6, -30), Color(0.4, 0.04, 0.04, 0.7), 3.0)   # שריטות דם
		# קומה שנייה של הפיר: פתח עם מסגרת
		draw_rect(Rect2(sx - 10, -258, 110, 96), frame, false, 6.0)
		draw_rect(Rect2(-6, -300, 230, 4), Color("2a2826"))


# ============================================================
#  צינור על הקיר שמוביל לפתח אדים. position = פתח היציאה
# ============================================================
class PipeOutlet extends Node2D:
	var dir := Vector2.LEFT
	var up_len := 110.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var pc := Color("4a4e52")
		var bend := Vector2(-dir.x * 18.0, 0.0)
		draw_rect(Rect2(bend.x - 5, -up_len, 10, up_len), pc)
		draw_line(Vector2(bend.x - 5, -up_len), Vector2(bend.x - 5, 0), Color(1, 1, 1, 0.08), 1.0)
		draw_rect(Rect2(minf(bend.x, 0.0) - 2, -5, absf(bend.x) + 4, 10), pc)
		draw_rect(Rect2(-3 + dir.x * 2.0, -7, 6, 14), Color("2a2c2e"))   # פיה שבורה
		for k in 3:   # פסי אזהרה
			draw_line(Vector2(bend.x - 5, -40 - k * 8), Vector2(bend.x + 5, -46 - k * 8), Color("c8a020"), 3.0)
		draw_circle(Vector2(bend.x, -70), 7.0, Color("8a1a14"))   # ברז
		draw_circle(Vector2(bend.x, -70), 2.5, Color("2a0a08"))
		for k in 4:
			draw_line(Vector2(bend.x, -70), Vector2(bend.x, -70) + Vector2.from_angle(float(k) * PI * 0.5) * 7.0, Color("5a0a08"), 1.5)


# ============================================================
#  שלולית עם השתקפות ואדוות (טיפות מהתקרה / גשם)
# ============================================================
class Puddle extends Node2D:
	var width := 80.0
	var _t := 0.0
	var _rings := []
	var _next := 0.5

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0:
			_next = randf_range(0.3, 1.1)
			_rings.append([randf_range(-width * 0.4, width * 0.4), 0.0])
		for rg in _rings:
			rg[1] += delta
		_rings = _rings.filter(func(q: Array): return float(q[1]) < 0.9)
		if Art.on_screen(self, global_position) and Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		draw_colored_polygon(Art.ellipse(Vector2.ZERO, width * 0.5, 3.5, 0.0, 20), Color(0.16, 0.2, 0.28, 0.75))
		var shim := 0.5 + 0.5 * sin(_t * 1.7)
		draw_line(Vector2(-width * 0.3, -0.5), Vector2(width * 0.2, -0.5), Color(0.7, 0.8, 1.0, 0.2 + 0.15 * shim), 1.5)   # השתקפות אור
		draw_line(Vector2(-width * 0.1, 1.0), Vector2(width * 0.35, 1.0), Color(0.6, 0.7, 0.9, 0.12), 1.0)
		for rg in _rings:
			var k: float = float(rg[1]) / 0.9
			var pts := Art.ellipse(Vector2(float(rg[0]), 0.0), 2.0 + k * 12.0, 0.6 + k * 2.2, 0.0, 14)
			pts.append(pts[0])
			draw_polyline(pts, Color(0.8, 0.9, 1.0, 0.45 * (1.0 - k)), 1.0)


# ============================================================
#  חזית הבניין בסוף + החצר הגשומה (זירת הבוס). position.x = קצה הבניין, y = ריצפה
# ============================================================
class Exterior extends Node2D:
	var w := 820.0

	func _ready() -> void:
		z_index = -3

	func _draw() -> void:
		# קיר חיצוני של הבניין (לבנים) מהגג עד הקומה השנייה
		var brick := Color("4a3430")
		draw_rect(Rect2(-24, -332, 40, 186), brick)
		var y := -330.0
		var row := 0
		while y < -146.0:
			draw_line(Vector2(-24, y), Vector2(16, y), Color(0, 0, 0, 0.3), 1.0)
			var off := -24.0 if row % 2 == 0 else -14.0
			draw_line(Vector2(off + 20, y), Vector2(off + 20, y + 10), Color(0, 0, 0, 0.3), 1.0)
			y += 10.0
			row += 1
		# משקוף היציאה של קומת הקרקע
		draw_rect(Rect2(-24, -146, 40, 10), Color("2a2624"))
		draw_rect(Rect2(10, -146, 6, 146), Color("2a2624"))
		draw_colored_polygon(PackedVector2Array([Vector2(16, -140), Vector2(46, -150), Vector2(46, 6), Vector2(16, 0)]), Color("3a3e44"))   # דלת פתוחה החוצה
		# שלט EXIT ירוק מעל הדלת
		draw_rect(Rect2(-14, -170, 34, 14), Color(0.15, 0.55, 0.3))
		draw_string(ThemeDB.fallback_font, Vector2(-10, -159), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 1.0, 0.85))
		Art.glow(self, Vector2(3, -163), 22.0, Color(0.3, 1.0, 0.5, 0.25))
		# גדר רשת ברקע של החצר (רואים דרכה את הרקע)
		var fc := Color(0.2, 0.22, 0.26, 0.8)
		draw_line(Vector2(60, -110), Vector2(w, -110), fc, 2.0)
		var x := 60.0
		while x < w:
			draw_line(Vector2(x, -110), Vector2(x, 0), Color(0.18, 0.2, 0.24, 0.9), 3.0)
			x += 120.0
		x = 60.0
		while x < w:
			draw_line(Vector2(x, -110), Vector2(x + 14, -96), Color(0.3, 0.32, 0.36, 0.35), 1.0)
			draw_line(Vector2(x + 14, -110), Vector2(x, -96), Color(0.3, 0.32, 0.36, 0.35), 1.0)
			x += 14.0
		var gy := -96.0
		while gy < 0.0:
			var gx := 60.0
			while gx < w:
				draw_line(Vector2(gx, gy), Vector2(gx + 14, gy + 14), Color(0.3, 0.32, 0.36, 0.3), 1.0)
				draw_line(Vector2(gx + 14, gy), Vector2(gx, gy + 14), Color(0.3, 0.32, 0.36, 0.3), 1.0)
				gx += 14.0
			gy += 14.0
		# פח אשפה ומכונית שרופה (צלליות)
		draw_rect(Rect2(150, -46, 80, 46), Color("2a3a2e"))
		draw_rect(Rect2(146, -52, 88, 8), Color("223026"))
		draw_colored_polygon(PackedVector2Array([Vector2(420, 0), Vector2(424, -30), Vector2(460, -34), Vector2(486, -58), Vector2(560, -58), Vector2(590, -32), Vector2(620, -28), Vector2(622, 0)]), Color("1e1c1c"))
		draw_circle(Vector2(460, -2), 13.0, Color("101010"))
		draw_circle(Vector2(585, -2), 13.0, Color("101010"))
		draw_colored_polygon(PackedVector2Array([Vector2(492, -54), Vector2(530, -54), Vector2(530, -36), Vector2(478, -36)]), Color(0.3, 0.4, 0.55, 0.3))
		# עמוד תאורה
		draw_rect(Rect2(330, -170, 5, 170), Color("1c1e22"))
		draw_line(Vector2(332, -170), Vector2(362, -176), Color("1c1e22"), 3.0)
