extends RefCounted
# ============================================================
#  שלב 12 (צפון-מזרח, "THE LIGHTHOUSE") - הכפר הקבור בחול.
#  השראה: טטז'ובה (סיארה) - כפר דייגים שהדיונות הנודדות קברו, כנסייה שרק המגדל שלה
#    מבצבץ מהחול, מגדלור על הכף, ספינה טרופה, בית קברות על הדיונה (צלבי עץ).
#  שעה: שקיעה אדומה-דם עם ערפל ים כבד. אור המגדלור עובר בערפל כל כמה שניות.
#  * static draw: רקע (שמש שוקעת בים, מגדלור + אלומה, ספינה טרופה, דיונות, כנסייה קבורה, צלבים).
#  * Village     - קישוט עולם: בתים חצי-קבורים בחול, רשתות דייגים, צלבים, ערימות חול.
#  * BuriedHouse - בית שרק הקומה העליונה שלו מעל החול - הגג = קומה שנייה (add_floor בשלב).
#  * FogBanks    - גושי ערפל שנעים לאט על המסך + האלומה של המגדלור (שכבת מסך).
# ============================================================

const Art := preload("res://art.gd")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func lighthouse(ci: CanvasItem, base: Vector2, h: float, t: float, lit: float) -> void:
	var w0 := h * 0.12
	var w1 := h * 0.075
	for i in 7:
		var y0 := base.y - h * float(i) / 7.0
		var y1 := base.y - h * float(i + 1) / 7.0
		var a := lerpf(w0, w1, float(i) / 7.0)
		var b := lerpf(w0, w1, float(i + 1) / 7.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - a, y0), Vector2(base.x + a, y0), Vector2(base.x + b, y1), Vector2(base.x - b, y1)]), Color("3a1c1c") if i % 2 == 0 else Color("4a3a36"))
	var lamp := base + Vector2(0, -h - 8.0)
	ci.draw_rect(Rect2(lamp.x - w1 * 1.3, lamp.y + 4.0, w1 * 2.6, 4.0), Color("1a1010"))
	ci.draw_rect(Rect2(lamp.x - w1, lamp.y - 6.0, w1 * 2.0, 10.0), Color(1.0, 0.95, 0.7, 0.4 + 0.6 * lit))
	ci.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-w1 - 2, -6), lamp + Vector2(w1 + 2, -6), lamp + Vector2(0, -16)]), Color("1a1010"))
	Art.glow(ci, lamp, 22.0 + 30.0 * lit, Color(1.0, 0.92, 0.6, 0.3 + 0.4 * lit))


static func shipwreck(ci: CanvasItem, p: Vector2, s: float, c: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-70, 0) * s, p + Vector2(-60, -24) * s, p + Vector2(40, -30) * s, p + Vector2(80, -14) * s, p + Vector2(60, 0) * s]), c)
	ci.draw_line(p + Vector2(-10, -28) * s, p + Vector2(-24, -110) * s, c, 3.0 * s)   # תורן שבור
	ci.draw_line(p + Vector2(30, -30) * s, p + Vector2(46, -76) * s, c, 2.5 * s)
	ci.draw_line(p + Vector2(-22, -100) * s, p + Vector2(10, -70) * s, c, 1.0)
	for i in 5:   # צלעות חשופות
		var x := -50.0 + float(i) * 22.0
		ci.draw_line(p + Vector2(x, -22) * s, p + Vector2(x + 4.0, -44) * s, c, 2.0 * s)


static func buried_church(ci: CanvasItem, base: Vector2, s: float, c: Color) -> void:
	ci.draw_rect(Rect2(base.x - 16.0 * s, base.y - 90.0 * s, 32.0 * s, 90.0 * s), c)   # מגדל
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-20, -90) * s, base + Vector2(20, -90) * s, base + Vector2(0, -122) * s]), c)
	ci.draw_line(base + Vector2(0, -122) * s, base + Vector2(0, -138) * s, c, 2.5 * s)
	ci.draw_line(base + Vector2(-6, -132) * s, base + Vector2(6, -132) * s, c, 2.5 * s)
	ci.draw_rect(Rect2(base.x - 6.0 * s, base.y - 70.0 * s, 12.0 * s, 18.0 * s), Color(0.05, 0.02, 0.02))
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(16, -40) * s, base + Vector2(80, -28) * s, base + Vector2(80, 0) * s, base + Vector2(16, 0) * s]), c)   # גג הכנסייה מתחת לחול


static func dune(ci: CanvasItem, x: float, base_y: float, w: float, h: float, c: Color) -> void:
	var pts := PackedVector2Array([Vector2(x, base_y)])
	for i in range(1, 14):   # בלי הנקודות של הקצוות (כפולות = המשולש נכשל)
		var u := float(i) / 14.0
		var y := base_y - h * pow(sin(u * PI), 1.4) * (1.0 - 0.25 * u)
		pts.append(Vector2(x + u * w, y))
	pts.append(Vector2(x + w, base_y))
	ci.draw_colored_polygon(pts, c)


static func cross(ci: CanvasItem, p: Vector2, h: float, c: Color, tilt: float) -> void:
	var up := Vector2(sin(tilt), -cos(tilt))
	var side := Vector2(cos(tilt), sin(tilt))
	ci.draw_line(p, p + up * h, c, 2.5)
	ci.draw_line(p + up * h * 0.72 - side * h * 0.28, p + up * h * 0.72 + side * h * 0.28, c, 2.5)


# ============================================================
#  קישוט עולם: הכפר הקבור
# ============================================================
class Village extends Node2D:
	var seed_v := 0
	var skip := []

	func _ready() -> void:
		z_index = -3

	func _free(x0: float, x1: float) -> bool:
		for s in skip:
			if x1 > float(s[0]) - 10.0 and x0 < float(s[1]) + 10.0:
				return false
		return true

	func _draw() -> void:
		var r := S12._rng(seed_v)
		var sand := Color("b8925a")
		var x := 0.0
		while x < 1024.0:
			var w := r.randf_range(110.0, 180.0)
			if not _free(x, x + w):
				x += 40.0
				continue
			var pick := r.randf()
			if pick < 0.45:   # בית חצי קבור: רק החלק העליון מעל החול
				var h := r.randf_range(50.0, 80.0)
				var wall := Color("c8b8a0").lerp(Color("a8b8c0"), r.randf()).darkened(0.25)
				draw_rect(Rect2(x, -h, w, h), wall)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 4, -h), Vector2(x + w + 4, -h), Vector2(x + w * 0.5, -h - 22.0)]), Color("6a3a2a"))
				for i in 2:
					var wx := x + 16.0 + float(i) * (w - 46.0)
					draw_rect(Rect2(wx, -h + 12.0, 14.0, 14.0), Color("0e0a0a"))
					if r.randf() < 0.3:   # עיניים בחלון החשוך...
						draw_circle(Vector2(wx + 4.0, -h + 18.0), 1.0, Color(1.0, 0.9, 0.6, 0.8))
						draw_circle(Vector2(wx + 9.0, -h + 18.0), 1.0, Color(1.0, 0.9, 0.6, 0.8))
				S12.dune(self, x - 30.0, 0.0, w + 60.0, h * 0.75, sand)   # החול מכסה את החלק התחתון
			elif pick < 0.65:   # רשת דייגים על מוטות עם מצופים
				draw_line(Vector2(x + 10, 0), Vector2(x + 12, -70), Color("4a3424"), 3.0)
				draw_line(Vector2(x + w - 10, 0), Vector2(x + w - 12, -66), Color("4a3424"), 3.0)
				for i in 7:
					var u := float(i) / 6.0
					var px := lerpf(x + 12.0, x + w - 12.0, u)
					draw_line(Vector2(px, -68.0 + sin(u * PI) * 14.0), Vector2(px + r.randf_range(-6, 6), -20.0), Color(0.2, 0.18, 0.15, 0.7), 1.0)
				for i in 8:
					var u := float(i) / 7.0
					draw_line(Vector2(lerpf(x + 12.0, x + w - 12.0, u), -68.0 + sin(u * PI) * 14.0), Vector2(lerpf(x + 12.0, x + w - 12.0, minf(u + 0.14, 1.0)), -68.0 + sin(minf(u + 0.14, 1.0) * PI) * 14.0), Color(0.2, 0.18, 0.15, 0.8), 1.0)
					draw_circle(Vector2(lerpf(x + 12.0, x + w - 12.0, u), -64.0 + sin(u * PI) * 14.0), 2.5, Color("c86a2a"))
				S12.dune(self, x, 0.0, w, 18.0, sand)
			elif pick < 0.82:   # בית קברות על דיונה: צלבי עץ עקומים
				S12.dune(self, x - 20.0, 0.0, w + 40.0, 40.0, sand)
				for i in 4:
					var cx := x + 14.0 + float(i) * (w - 28.0) / 3.0
					var cy := -sin((cx - x + 20.0) / (w + 40.0) * PI) * 34.0
					S12.cross(self, Vector2(cx, cy + 4.0), r.randf_range(22.0, 34.0), Color("3a2a1e"), r.randf_range(-0.25, 0.25))
					if r.randf() < 0.5:
						draw_circle(Vector2(cx + 3.0, cy + 2.0), 2.2, Color("c83a4a"))   # פרח
			else:   # שלד של רפסודה / עץ מת
				draw_line(Vector2(x + 30, 0), Vector2(x + 34, -80), Color("2a2018"), 4.0)
				for i in 4:
					var by := -30.0 - float(i) * 12.0
					draw_line(Vector2(x + 33, by), Vector2(x + 33.0 + (14.0 if i % 2 == 0 else -14.0), by - 14.0), Color("2a2018"), 2.0)
				S12.dune(self, x, 0.0, w * 0.6, 22.0, sand)
			x += w + r.randf_range(0.0, 30.0)

	const S12 := preload("res://effects/s12_decor.gd")


# בית קבור שהגג השטוח שלו בולט מהחול - עולים עליו (הקומה = add_floor בשלב)
class BuriedHouse extends Node2D:
	var w := 380.0
	var h := 130.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var r := S12._rng(seed_v)
		draw_rect(Rect2(0.0, -h, w, h), Color("9a8a78"))
		for i in 8:   # טיח מתקלף, סדקים
			var px := r.randf_range(6.0, w - 20.0)
			var py := -r.randf_range(30.0, h - 8.0)
			draw_rect(Rect2(px, py, r.randf_range(8.0, 20.0), r.randf_range(4.0, 9.0)), Color("6a5a48"))
		var n := int(w / 70.0)
		for i in n:
			var wx := 22.0 + float(i) * (w - 44.0) / maxf(float(n - 1), 1.0) - 9.0
			draw_rect(Rect2(wx, -h + 22.0, 18.0, 22.0), Color("0c0808"))
			draw_line(Vector2(wx, -h + 22.0), Vector2(wx + 18.0, -h + 44.0), Color("4a3424"), 2.0)   # קרשים על החלון
			draw_line(Vector2(wx + 18.0, -h + 22.0), Vector2(wx, -h + 44.0), Color("4a3424"), 2.0)
		S12.dune(self, -40.0, 0.0, w * 0.6, h * 0.62, Color("b8925a"))
		S12.dune(self, w * 0.45, 0.0, w * 0.65, h * 0.55, Color("b08a52"))

	const S12 := preload("res://effects/s12_decor.gd")


# ============================================================
#  ערפל ים + אלומת המגדלור (שכבת מסך)
# ============================================================
class FogBanks extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	# איפה המנורה של המגדלור על המסך (אותו חישוב כמו שכבת הרקע 0.10 בשלב: מגדלור כל 1600, ב-1200)
	func _lamp_pos() -> Vector2:
		var cam := get_viewport().get_camera_2d()
		var sc := cam.get_screen_center_position().x * 0.10 if cam != null else 0.0
		var lx := fposmod(1200.0 - sc, 1600.0)
		if lx > vp.x + 100.0:
			lx -= 1600.0
		return Vector2(lx, 332.0)

	func _wave(x: float, i: int, spd: float) -> float:
		return sin(x * 0.006 + _t * spd * 0.01 + float(i) * 1.9) * 26.0


	func beam_k() -> float:   # 0..1 - כמה האלומה עוברת עכשיו
		return maxf(0.0, sin(_t * 0.55)) ** 6.0

	func _draw() -> void:
		for i in 5:   # רצועות ערפל גליות שזזות (בלי קצוות חדים)
			var y0 := vp.y * (0.5 + 0.09 * float(i))
			var spd := 10.0 + float(i) * 6.0
			for k in 3:   # כל רצועה = 3 שכבות שקופות בעובי יורד = קצה רך
				var pts := PackedVector2Array()
				var th := 70.0 - float(k) * 22.0
				for q in 25:   # קצה עליון ותחתון על אותו גל (לא נחתכים)
					var x := float(q) * vp.x / 24.0
					pts.append(Vector2(x, y0 + _wave(x, i, spd) - th * 0.5))
				for q in range(24, -1, -1):
					var x := float(q) * vp.x / 24.0
					pts.append(Vector2(x, y0 + _wave(x, i, spd) + th * 0.5 + 8.0 * (1.0 + sin(x * 0.01 + _t * 0.4))))
				draw_colored_polygon(pts, Color(0.88, 0.72, 0.66, 0.035))
		var bk := beam_k()
		if bk > 0.01:   # האלומה חוצה את המסך מימין לשמאל
			var sweep := sin(_t * 0.55 * 2.0 - PI * 0.5)
			var src := _lamp_pos()
			var ang := (PI + 0.2 + sweep * 0.3) if src.x > vp.x * 0.5 else (-0.2 - sweep * 0.3)   # מאיר לכיוון מרכז המסך
			var d := Vector2.from_angle(ang)
			var n := Vector2(-d.y, d.x)
			draw_colored_polygon(PackedVector2Array([src, src + d * 1600.0 + n * 220.0, src + d * 1600.0 - n * 220.0]), Color(1.0, 0.95, 0.75, 0.10 * bk))
			draw_colored_polygon(PackedVector2Array([src, src + d * 1600.0 + n * 90.0, src + d * 1600.0 - n * 90.0]), Color(1.0, 0.97, 0.85, 0.08 * bk))

	const S12 := preload("res://effects/s12_decor.gd")
