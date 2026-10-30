extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 49 ("RIVER DELTA") - הדלתא של הפרנה ליד טיגרה, ארגנטינה, בבוקר ערפילי אפור-ירוק. אזור שישי, שלב 4.
#  איים של בוץ וערבות בוכיות, בתים על כלונסאות (פלפיטוס), מועדוני חתירה בסגנון טיודור, סירות חלודות, ערוצים של מים חומים.
#    delta_sky     - (רקע) בוקר ערפילי: אפור-ירקרק, שמש חיוורת מאחורי הערפל, פסי ערפל זזים, אנפות עפות
#    far_islands   - (רקע, 0.06) הנהר הרחב עם איים נמוכים, צפצפות גבוהות וערבות בוכיות, מעבורת ("לנצ'ה") שחוצה לאט
#    mid_stilts    - (רקע, 0.28) בתים צבעוניים דהויים על כלונסאות, מועדון חתירה בסגנון טיודור, סירות קשורות שמתנדנדות
#    near_reeds    - (רקע, 0.6) קנים (חונקוס) שמתנדנדים, ענף סייבו עם פרחים אדומים, עמודי עגינה, מים עם פסולת שצפה
#    DeltaGround   - (עולם) טיילת קרשים מעל גדת בוץ
#    Channel       - (עולם) ערוץ מים רדוד שחוצה את הטיילת (המים מכסים את כפות הרגליים). ANGLER מתחבא בתוכו.
#    StiltDeck     - (עולם) מרפסת של בית על כלונסאות - הקומה העליונה (add_floor)
#    SinkingDock   - (עולם, מלכודת) קרשים רקובים (ירוקים, טחב, רווחים): עומדים עליהם -> חריקה (WARN_T) -> נשברים:
#                    נזק DMG + נתקעים בבוץ (slow). זומבים שעליהם נופלים (DMG_Z). אחרי שנשבר = בור מים.
#    TideDirector  - (עולם, מלכודת) "THE RIVER RISES": כל CYCLE שניות הנהר עולה ומציף את הטיילת ל-HIGH_T שניות.
#                    על הטיילת אתה במים (איטי), ו-ANGLER יכול לשחות אליך מכל מקום. לעלות למרפסות / על מכשולים!
#                    הוא גם מנהל את player.in_water (ערוצים, בורות, גאות). main meta "tide" = 0..1 (כמה המים גבוהים).
#    Obstacle      - (מוצק + מחסה) "wreck" סירה חלודה הפוכה / "crates" ארגזי פירות וסלי נצרים / "nets" תוף רשתות ומצופים
#    RowingClub    - (עולם) חזית מועדון החתירה בסוף השלב (טיודור, שלט "CLUB DE REMO", מתלה סירות חתירה)
#    DeltaFX       - (מסך) פסי ערפל שזזים + יתושים + גוון ירקרק
#  לשנות: SinkingDock.WARN_T / DMG / SLOW_T, TideDirector.CYCLE / WARN_T / HIGH_T / H.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const WATER := Color("5a4a32")
const WATER_D := Color("3e3424")
const WOOD := Color("6a5236")
const WOOD_D := Color("4a3824")
const MOSS := Color("4a5a2a")
const HOUSE := [Color("6a8a6a"), Color("a85a4a"), Color("5a7a9a"), Color("c8a860"), Color("8a6a8a")]


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func delta_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("6a7a74"), Color("8a9a90"), Color("aab4a4"), Color("c4c6b0")], 0.85)
	var sun := Vector2(v.x * 0.68, v.y * 0.26)
	Art.glow(ci, sun, 160.0, Color(1.0, 0.98, 0.85, 0.16))
	DrawBatch.circle(ci, sun, 26.0, Color(1.0, 0.98, 0.9, 0.55))   # שמש חיוורת מאחורי הערפל
	for i in 7:   # פסי ערפל ארוכים שזזים לאט
		var y := v.y * (0.12 + float(i) * 0.08)
		var x := fposmod(float(i) * 290.0 + t * (4.0 + float(i % 3) * 2.0), v.x + 700.0) - 350.0
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(x, y), 320.0 + float(i % 3) * 90.0, 16.0 + float(i % 2) * 8.0, 0.0, 16), Color(0.86, 0.88, 0.82, 0.22))
	for i in 4:   # אנפות (כנפיים ארוכות ואיטיות)
		var bx := fposmod(float(i) * 410.0 + t * (22.0 + float(i) * 3.0), v.x + 300.0) - 150.0
		var by := v.y * 0.2 + float(i) * 26.0 + sin(t * 0.6 + float(i)) * 10.0
		var f := sin(t * 3.0 + float(i) * 1.3) * 6.0
		var c := Color(0.25, 0.28, 0.27, 0.75)
		DrawBatch.polyline(ci, PackedVector2Array([Vector2(bx - 16, by + f), Vector2(bx - 6, by - 2), Vector2(bx, by), Vector2(bx + 6, by - 2), Vector2(bx + 16, by + f)]), c, 2.0)
		DrawBatch.line(ci, Vector2(bx, by), Vector2(bx + 9, by + 1), c, 1.5)   # צוואר
		DrawBatch.line(ci, Vector2(bx, by), Vector2(bx - 10, by + 2), c, 1.2)  # רגליים מאחור


# ---- הנהר הרחב והאיים הרחוקים ----
static func far_islands(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	DrawBatch.rect(ci, Rect2(0, y - 40.0, v.x, v.y - y + 40.0), Color("8a8a76"))   # הנהר
	for q in 9:   # ניצוצות על המים
		var wy := y - 34.0 + float(q) * 9.0
		var wx := fposmod(float(q) * 173.0 - sc * 0.4 + sin(t * 0.7 + float(q)) * 30.0, v.x + 200.0) - 100.0
		DrawBatch.line(ci, Vector2(wx, wy), Vector2(wx + 60.0 + float(q % 3) * 30.0, wy), Color(0.85, 0.86, 0.78, 0.35), 1.5)
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# אי נמוך וארוך
		var top := y - 46.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx + 60, y - 36), Vector2(bx + 140, top), Vector2(bx + 980, top - 4), Vector2(bx + 1080, y - 36)]), Color("6e7a68"))
		# צפצפות גבוהות ודקות
		for q in 10:
			var px := bx + 180.0 + float(q) * 38.0
			var hh := 110.0 + _h(q + k * 11, 1) * 60.0
			var sw := sin(t * 0.9 + float(q)) * 2.0
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 7, top), Vector2(px - 4 + sw * 0.5, top - hh * 0.6), Vector2(px + sw, top - hh), Vector2(px + 4 + sw * 0.5, top - hh * 0.6), Vector2(px + 7, top)]), Color("5e6e5c"))
		# ערבות בוכיות (כיפה עם ענפים נוטפים)
		for q in 3:
			var wx := bx + 620.0 + float(q) * 120.0
			var r := 46.0 + _h(q + k, 2) * 14.0
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(wx, top - r * 0.7), r, r * 0.75, 0.0, 16), Color("66765e"))
			for d in 9:
				var dx := wx - r + float(d) * r * 0.25
				var sw2 := sin(t * 1.1 + float(d) + float(q)) * 3.0
				DrawBatch.line(ci, Vector2(dx, top - r * 0.6), Vector2(dx + sw2, top - 4.0), Color("5c6c54"), 4.0)
		# מגדל מים / טחנה ישנה
		DrawBatch.rect(ci, Rect2(bx + 1040.0, top - 70.0, 8.0, 70.0), Color("62705e"))
		DrawBatch.rect(ci, Rect2(bx + 1026.0, top - 92.0, 36.0, 24.0), Color("62705e"))
	# המעבורת: נעה לאורך הנהר בלי קשר למצלמה
	var fx := fposmod(t * 12.0, v.x + 500.0) - 250.0
	var fy := y - 20.0 + sin(t * 1.2) * 1.0
	DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(fx - 70, fy - 8), Vector2(fx + 76, fy - 8), Vector2(fx + 64, fy + 4), Vector2(fx - 62, fy + 4)]), Color("3e4a48"))
	DrawBatch.rect(ci, Rect2(fx - 52, fy - 22, 96, 14), Color("cfcab4"))
	for q in 8:
		DrawBatch.rect(ci, Rect2(fx - 47.0 + float(q) * 11.5, fy - 19.0, 7.0, 6.0), Color("4a5a5a"))
	DrawBatch.rect(ci, Rect2(fx - 54, fy - 25, 100, 3), Color("8a3a2a"))
	DrawBatch.line(ci, Vector2(fx - 80, fy + 2), Vector2(fx - 160, fy + 3), Color(0.9, 0.9, 0.85, 0.35), 2.0)   # שובל
	DrawBatch.rect(ci, Rect2(0, y - 8.0, v.x, 30.0), Color(0.82, 0.84, 0.78, 0.3))   # ערפל על המים


# ---- בתים על כלונסאות, מועדון חתירה, סירות ----
static func mid_stilts(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var wl := y - 30.0   # קו המים
	DrawBatch.rect(ci, Rect2(0, wl, v.x, v.y - wl), Color("6a5e44"))
	var period := 1250.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# גדת אי עם עצים
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx - 20, wl + 2), Vector2(bx + 10, wl - 26), Vector2(bx + 1200, wl - 30), Vector2(bx + 1230, wl + 2)]), Color("4e5a40"))
		for q in 6:
			var tx := bx + 60.0 + float(q) * 200.0 + _h(q + k, 4) * 60.0
			DrawBatch.line(ci, Vector2(tx, wl - 26.0), Vector2(tx, wl - 70.0), Color("3a3424"), 4.0)
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(tx, wl - 86.0), 34.0, 26.0, 0.0, 14), Color("4a5a3c").lightened(0.05 * float(q % 2)))
		# שני בתים על כלונסאות
		for q in 2:
			var hx := bx + 120.0 + float(q) * 330.0
			var c: Color = HOUSE[(q + k * 2) % 5].darkened(0.25)
			var floor_y := wl - 50.0
			for p in 5:   # כלונסאות
				DrawBatch.line(ci, Vector2(hx + float(p) * 32.0, floor_y), Vector2(hx + float(p) * 32.0, wl + 6.0), Color("3a2e22"), 4.0)
			DrawBatch.rect(ci, Rect2(hx - 14.0, floor_y - 4.0, 156.0, 6.0), Color("4a3a28"))   # מרפסת
			DrawBatch.rect(ci, Rect2(hx, floor_y - 66.0, 128.0, 62.0), c)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(hx - 10, floor_y - 66), Vector2(hx + 64, floor_y - 100), Vector2(hx + 138, floor_y - 66)]), Color("5a3a2e"))
			for w in 3:
				DrawBatch.rect(ci, Rect2(hx + 14.0 + float(w) * 38.0, floor_y - 52.0, 18.0, 20.0), Color("2a2a26"))
				DrawBatch.rect(ci, Rect2(hx + 12.0 + float(w) * 38.0, floor_y - 54.0, 22.0, 3.0), c.lightened(0.2))
			for r in 8:   # מעקה
				DrawBatch.line(ci, Vector2(hx - 12.0 + float(r) * 20.0, floor_y - 4.0), Vector2(hx - 12.0 + float(r) * 20.0, floor_y - 18.0), Color("4a3a28"), 2.0)
			DrawBatch.line(ci, Vector2(hx - 12.0, floor_y - 18.0), Vector2(hx + 140.0, floor_y - 18.0), Color("4a3a28"), 2.0)
			# בגדים על חבל (מתנדנדים)
			for g in 4:
				var gx := hx + 20.0 + float(g) * 22.0
				var sw := sin(t * 1.6 + float(g) + float(k)) * 2.0
				DrawBatch.rect(ci, Rect2(gx + sw, floor_y - 30.0, 12.0, 14.0), HOUSE[(g + q) % 5].lightened(0.1))
		# מועדון החתירה (טיודור: לבן עם קורות כהות, גג תלול, דלתות קשת לסירות)
		var cx := bx + 830.0
		var cb := wl - 6.0
		DrawBatch.rect(ci, Rect2(cx, cb - 120.0, 240.0, 120.0), Color("d8d2c0"))
		for q in 9:   # קורות
			DrawBatch.line(ci, Vector2(cx + float(q) * 30.0, cb - 120.0), Vector2(cx + float(q) * 30.0, cb - 60.0), Color("3a2a1e"), 3.0)
		DrawBatch.line(ci, Vector2(cx, cb - 90.0), Vector2(cx + 240.0, cb - 90.0), Color("3a2a1e"), 3.0)
		for q in 4:
			DrawBatch.line(ci, Vector2(cx + float(q) * 60.0, cb - 120.0), Vector2(cx + float(q) * 60.0 + 30.0, cb - 90.0), Color("3a2a1e"), 2.0)
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - 16, cb - 120), Vector2(cx + 120, cb - 200), Vector2(cx + 256, cb - 120)]), Color("4a2a24"))
		for q in 3:   # דלתות קשת לסירות
			var dx := cx + 22.0 + float(q) * 72.0
			DrawBatch.rect(ci, Rect2(dx, cb - 46.0, 52.0, 46.0), Color("2a2620"))
			DrawBatch.circle(ci, Vector2(dx + 26.0, cb - 46.0), 26.0, Color("2a2620"))
		DrawBatch.line(ci, Vector2(cx + 120.0, cb - 200.0), Vector2(cx + 120.0, cb - 240.0), Color("3a3a3a"), 2.0)   # דגל
		var fw := sin(t * 3.0 + float(k)) * 4.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx + 120, cb - 240), Vector2(cx + 150 + fw, cb - 234), Vector2(cx + 120, cb - 226)]), Color("5a7aaa"))
		# סירות קשורות שמתנדנדות
		for q in 3:
			var sx := bx + 600.0 + float(q) * 70.0
			var sy := wl + 6.0 + sin(t * 1.4 + float(q) * 1.7 + float(k)) * 2.0
			var rot := sin(t * 1.1 + float(q)) * 0.03
			var hull := PackedVector2Array([Vector2(-28, -6), Vector2(28, -8), Vector2(22, 2), Vector2(-24, 2)])
			var xf := Transform2D(rot, Vector2(sx, sy))
			DrawBatch.colored_polygon(ci, xf * hull, HOUSE[(q + k) % 5].darkened(0.35))
			DrawBatch.line(ci, xf * Vector2(-28, -6), xf * Vector2(28, -8), Color(0.9, 0.9, 0.85, 0.5), 1.0)
			DrawBatch.line(ci, Vector2(sx - 28.0, sy - 6.0), Vector2(sx - 46.0, wl - 22.0), Color(0.2, 0.18, 0.14, 0.7), 1.0)   # חבל
	for q in 12:   # אדוות
		var rx := fposmod(float(q) * 131.0 - sc * 0.1 + t * 6.0, v.x + 100.0) - 50.0
		DrawBatch.line(ci, Vector2(rx, wl + 12.0 + float(q % 4) * 7.0), Vector2(rx + 34.0, wl + 12.0 + float(q % 4) * 7.0), Color(0.85, 0.82, 0.7, 0.25), 1.2)
	DrawBatch.rect(ci, Rect2(0, wl - 20.0, v.x, 26.0), Color(0.75, 0.78, 0.72, 0.2))   # ערפל נמוך


# ---- קנים, סייבו, עמודי עגינה ופסולת צפה (הכי קרוב) ----
static func near_reeds(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	DrawBatch.rect(ci, Rect2(0, y - 14.0, v.x, v.y - y + 14.0), WATER_D)
	var period := 340.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		# עמוד עגינה עם חבל
		DrawBatch.rect(ci, Rect2(x + 250.0, y - 60.0, 10.0, 60.0), Color("3a2c1e"))
		DrawBatch.circle(ci, Vector2(x + 255.0, y - 60.0), 6.0, Color("3a2c1e"))
		DrawBatch.arc(ci, Vector2(x + 255.0, y - 40.0), 7.0, 0.0, TAU, 10, Color("8a7a5a"), 2.0)
		# קנים
		for q in 16:
			var rx := x + 10.0 + float(q) * 12.0 + _h(q + k, 1) * 6.0
			var hh := 50.0 + _h(q + k * 3, 2) * 50.0
			var sw := sin(t * 1.8 + float(q) * 0.6 + float(k)) * (4.0 + hh * 0.05)
			DrawBatch.polyline(ci, PackedVector2Array([Vector2(rx, y), Vector2(rx + sw * 0.4, y - hh * 0.5), Vector2(rx + sw, y - hh)]), Color("3e4a26").lightened(0.06 * float(q % 3)), 2.2)
			if q % 4 == 0:   # "סיגר" חום בראש הקנה
				DrawBatch.line(ci, Vector2(rx + sw, y - hh), Vector2(rx + sw * 1.05, y - hh - 10.0), Color("5a3a22"), 4.0)
		# ענף סייבו עם פרחים אדומים (הפרח הלאומי)
		if k % 2 == 0:
			var bx := x + 200.0
			var sw2 := sin(t * 1.2 + float(k)) * 3.0
			DrawBatch.polyline(ci, PackedVector2Array([Vector2(bx - 40, y - 10), Vector2(bx - 10, y - 60), Vector2(bx + 30 + sw2, y - 92), Vector2(bx + 70 + sw2, y - 104)]), Color("3a2a1e"), 4.0)
			for f in 6:
				var fp := Vector2(bx - 14.0 + float(f) * 16.0 + sw2 * 0.6, y - 62.0 - float(f) * 8.0 + _h(f + k, 3) * 10.0)
				DrawBatch.colored_polygon(ci, Art.ellipse(fp, 6.0, 3.0, 0.6, 8), Color("c82a2a"))
				DrawBatch.colored_polygon(ci, Art.ellipse(fp + Vector2(3, 2), 4.0, 2.4, -0.4, 8), Color("e04a3a"))
				DrawBatch.colored_polygon(ci, Art.ellipse(fp + Vector2(-6, 6), 6.0, 2.5, 0.3, 6), Color("3e5a2a"))
	# פסולת שצפה עם הזרם (בקבוק, ענף, חתיכת קרש)
	for q in 6:
		var dx := fposmod(float(q) * 257.0 - sc + t * 9.0, v.x + 200.0) - 100.0
		var dy := y - 6.0 + sin(t * 1.5 + float(q)) * 1.5
		match q % 3:
			0:
				DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(dx, dy), 7.0, 2.6, 0.1, 8), Color("6a8a6a"))
			1:
				DrawBatch.line(ci, Vector2(dx - 14, dy), Vector2(dx + 14, dy - 2), Color("4a3a26"), 3.0)
				DrawBatch.line(ci, Vector2(dx + 2, dy - 1), Vector2(dx + 8, dy - 7), Color("4a3a26"), 2.0)
			_:
				DrawBatch.rect(ci, Rect2(dx - 10, dy - 3, 20, 4), WOOD)
	for q in 10:   # אדוות
		var rx := fposmod(float(q) * 151.0 - sc * 0.9 + t * 10.0, v.x + 80.0) - 40.0
		DrawBatch.line(ci, Vector2(rx, y - 6.0 + float(q % 3) * 4.0), Vector2(rx + 26.0, y - 6.0 + float(q % 3) * 4.0), Color(0.75, 0.7, 0.55, 0.3), 1.2)


# ============================================================
#  עולם
# ============================================================
class DeltaGround extends Node2D:   # טיילת קרשים מעל בוץ
	var w := 1024.0
	var depth := 90.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("2e2618"))   # בוץ
		DrawBatch.rect(self, Rect2(0, 16, w, 10), WATER_D)
		var x := 0.0
		var i := 0
		while x < w:   # קרשים
			var c := WOOD.darkened(0.06 * float(i % 3))
			DrawBatch.rect(self, Rect2(x, 0, 30.0, 12.0), c)
			DrawBatch.line(self, Vector2(x + 30.0, 0), Vector2(x + 30.0, 12), Color("2a2016"), 2.0)
			if _h2(i) < 0.3:
				DrawBatch.circle(self, Vector2(x + 6.0, 3.0), 1.0, Color("2a2016"))
				DrawBatch.circle(self, Vector2(x + 24.0, 3.0), 1.0, Color("2a2016"))
			if _h2(i + 99) < 0.15:
				DrawBatch.rect(self, Rect2(x + 4.0, 8.0, 18.0, 3.0), MOSS)
			x += 32.0
			i += 1
		DrawBatch.rect(self, Rect2(0, 0, w, 2), WOOD.lightened(0.15))
		for q in int(w / 128.0) + 1:   # כלונסאות מתחת
			DrawBatch.rect(self, Rect2(float(q) * 128.0 + 10.0, 12, 8, depth - 12.0), Color("3a2c1c"))

	func _h2(i: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + position.x * 0.013) * 43758.5453, 1.0)


# ---- ערוץ מים רדוד שחוצה את הטיילת ----
class Channel extends Node2D:
	var w := 140.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 6   # מעל כפות הרגליים

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w) and Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(-6, -2, 8, 16), WOOD_D)   # קצוות קרשים שבורים
		DrawBatch.rect(self, Rect2(w - 2, -2, 8, 16), WOOD_D)
		DrawBatch.rect(self, Rect2(0, -6, w, 30), Color(WATER, 0.88))
		DrawBatch.rect(self, Rect2(0, -7, w, 2), Color(0.8, 0.76, 0.6, 0.45))
		for q in 5:
			var rx := fposmod(float(q) * 37.0 + _t * 14.0, w - 20.0)
			DrawBatch.line(self, Vector2(rx, -3.0 + float(q % 3) * 5.0), Vector2(rx + 16.0, -3.0 + float(q % 3) * 5.0), Color(0.85, 0.8, 0.62, 0.35), 1.0)


# ---- מרפסת בית על כלונסאות (הקומה = add_floor) ----
class StiltDeck extends Node2D:
	var w := 320.0
	var tier := 150.0
	var col := Color("6a8a6a")

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		# הבית מאחורי המרפסת
		var hx := w * 0.15
		var hw := w * 0.7
		DrawBatch.rect(self, Rect2(hx, -tier - 110.0, hw, 110.0), col.darkened(0.15))
		for q in int(hw / 14.0):   # לוחות עץ
			DrawBatch.line(self, Vector2(hx + float(q) * 14.0, -tier - 110.0), Vector2(hx + float(q) * 14.0, -tier), col.darkened(0.3), 1.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(hx - 16, -tier - 108), Vector2(hx + hw * 0.5, -tier - 160), Vector2(hx + hw + 16, -tier - 108)]), Color("6a3a2e"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(hx - 16, -tier - 108), Vector2(hx + hw * 0.5, -tier - 160), Vector2(hx + hw + 16, -tier - 108), Vector2(hx + hw * 0.5, -tier - 150)]), Color("4a2a22"))
		DrawBatch.rect(self, Rect2(hx + hw * 0.5 - 18.0, -tier - 74.0, 36.0, 74.0), Color("2a2420"))   # דלת
		for wx in [hx + 20.0, hx + hw - 56.0]:
			DrawBatch.rect(self, Rect2(wx, -tier - 80.0, 36.0, 30.0), Color("2a3030"))
			DrawBatch.rect(self, Rect2(wx - 3.0, -tier - 82.0, 42.0, 3.0), col.lightened(0.25))
			DrawBatch.line(self, Vector2(wx + 18.0, -tier - 80.0), Vector2(wx + 18.0, -tier - 50.0), col.lightened(0.25), 1.5)
		# כלונסאות
		for px in range(0, int(w) + 1, 64):
			var x := minf(float(px), w - 10.0)
			DrawBatch.rect(self, Rect2(x, -tier, 10, tier + 10.0), Color("3e3020"))
			DrawBatch.rect(self, Rect2(x, -40.0, 10, 30.0), Color(0.25, 0.32, 0.18, 0.7))   # טחב בקו המים
		DrawBatch.line(self, Vector2(0, -tier + 30.0), Vector2(w - 10.0, -20.0), Color("3a2c1c"), 3.0)   # חיזוק אלכסוני
		# הרצפה + מעקה
		DrawBatch.rect(self, Rect2(-6, -tier - 2, w + 12, 12), WOOD)
		DrawBatch.rect(self, Rect2(-6, -tier - 2, w + 12, 3), WOOD.lightened(0.2))
		for q in int(w / 24.0) + 1:
			DrawBatch.line(self, Vector2(float(q) * 24.0, -tier - 2.0), Vector2(float(q) * 24.0, -tier - 26.0), WOOD_D, 2.0)
		DrawBatch.line(self, Vector2(-6, -tier - 26.0), Vector2(w + 6, -tier - 26.0), WOOD_D, 3.0)
		# מצוף ועוגן תלויים
		DrawBatch.circle(self, Vector2(w * 0.08, -tier - 40.0), 9.0, Color("d84a2a"))
		DrawBatch.arc(self, Vector2(w * 0.08, -tier - 40.0), 9.0, 0.0, TAU, 12, Color("e8e0d0"), 3.0)


# ---- קרשים רקובים: נשברים כשעומדים עליהם ----
class SinkingDock extends Node2D:
	const W := 110.0
	const WARN_T := 0.55
	const DMG := 1
	const DMG_Z := 25
	const SLOW_T := 2.2
	var state := 0                  # 0 שלם, 1 חורק, 2 נשבר (בור מים)
	var breaks := 0                 # לבדיקות
	var traps := 0
	var _t := 0.0
	var _tt := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -70), Vector2(W, 76))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 1 and world_rect().grow(margin).has_point(p)

	func water_rect() -> Rect2:   # TideDirector: אחרי שנשבר - בור מים
		return Rect2(global_position + Vector2(0, -20), Vector2(W, 26))

	func _physics_process(delta: float) -> void:
		_tt += delta
		match state:
			0:
				if Engine.get_physics_frames() % 4 == 0:
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and pl.is_on_floor() and _on(pl.global_position):
						state = 1
						_t = WARN_T
						preload("res://sfx.gd").play("rd_creak", global_position + Vector2(W * 0.5, 0), 0.0, 0.1, 2)
			1:
				_t -= delta
				if _t <= 0.0:
					_break()
		if state == 1 or Engine.get_physics_frames() % 20 == 0:
			queue_redraw()

	func _on(p: Vector2) -> bool:
		return p.x > global_position.x + 4.0 and p.x < global_position.x + W - 4.0 and absf(p.y - global_position.y) < 8.0

	func _break() -> void:
		state = 2
		breaks += 1
		preload("res://sfx.gd").play("rd_snap", global_position + Vector2(W * 0.5, 0), 2.0, 0.1, 2)
		preload("res://sfx.gd").play("splash", global_position + Vector2(W * 0.5, 0), 0.0)
		var D := preload("res://debris.gd")
		for i in 6:
			var c = D.new()
			get_parent().add_child(c)
			c.setup(global_position + Vector2(randf_range(10, W - 10), -4), Vector2(randf_range(8, 16), 3), WOOD, Vector2(randf_range(-120, 120), -randf_range(80, 240)))
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and _on(pl.global_position):
			traps += 1
			pl.hurt(DMG, Vector2(0, -0.3))
			pl.slow_t = maxf(float(pl.slow_t), SLOW_T)
			pl._say("STUCK IN THE MUD", Color("c8b070"))
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and not z.is_boss() and _on(z.global_position):
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -12), Vector2.DOWN, true, {"source": "hazard", "fixed": DMG_Z})
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if state == 2:   # בור עם מים וקרשים שבורים
			DrawBatch.rect(self, Rect2(0, -6, W, 28), Color(WATER, 0.92))
			DrawBatch.rect(self, Rect2(0, -7, W, 2), Color(0.8, 0.76, 0.6, 0.45))
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-2, -2), Vector2(14, -2), Vector2(8, 8), Vector2(-2, 10)]), WOOD_D)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(W - 12, -2), Vector2(W + 2, -2), Vector2(W + 2, 10), Vector2(W - 6, 6)]), WOOD_D)
			DrawBatch.line(self, Vector2(30, 4), Vector2(58, -3), WOOD, 4.0)
			return
		var j := Vector2(sin(_tt * 60.0) * 1.2, 0) if state == 1 else Vector2.ZERO
		for q in 4:   # קרשים רקובים: ירוקים-כהים, מוכתמים, רווחים
			var x := 2.0 + float(q) * 27.0
			DrawBatch.rect(self, Rect2(Vector2(x, 0) + j, Vector2(24.0, 11.0)), Color("4a4428").darkened(0.08 * float(q % 2)))
			DrawBatch.rect(self, Rect2(Vector2(x + 3.0, 6) + j, Vector2(12.0, 3.0)), MOSS)
			DrawBatch.circle(self, Vector2(x + 18.0, 4.0) + j, 2.0, Color(0.15, 0.18, 0.1, 0.8))
		DrawBatch.line(self, Vector2(40, 1) + j, Vector2(52, 9) + j, Color("1a1810"), 1.2)   # סדק
		DrawBatch.line(self, Vector2(75, 2) + j, Vector2(70, 10) + j, Color("1a1810"), 1.2)
		if state == 1:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(W * 0.5 - 4.0, -60.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.5, 0.2))


# ---- "THE RIVER RISES": גאות שמציפה את הטיילת + מנהל המים של השחקן ----
class TideDirector extends Node2D:
	const CYCLE := Vector2(30.0, 40.0)
	const WARN_T := 3.0
	const HIGH_T := 9.0
	const FALL_T := 2.5
	const H := 22.0                 # כמה המים עולים מעל הטיילת
	var floor_y := 630.0
	var spans := []                 # [[x0, x1], ...] ערוצי מים קבועים
	var holes := []                 # SinkingDock (אחרי שנשברו = מים)
	var state := 0                  # 0 רגוע, 1 עולה (אזהרה), 2 גבוה, 3 יורד
	var level := 0.0                # 0..1
	var rises := 0                  # לבדיקות
	var soaked := 0
	var _t := 18.0
	var _tt := 0.0
	var _set_water := false

	func _ready() -> void:
		z_index = 6

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		match state:
			0:
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					rises += 1
					preload("res://sfx.gd").play("rd_tide", null, 0.0)
					var pl0 := get_tree().get_first_node_in_group("player")
					if pl0 != null and not pl0.dead:
						pl0._say("THE RIVER IS RISING - GET HIGH!", Color("a0d0e0"))
			1:
				level = 1.0 - _t / WARN_T
				if _t <= 0.0:
					state = 2
					_t = HIGH_T
			2:
				level = 1.0
				if _t <= 0.0:
					state = 3
					_t = FALL_T
			3:
				level = _t / FALL_T
				if _t <= 0.0:
					state = 0
					level = 0.0
					_t = randf_range(CYCLE.x, CYCLE.y)
		get_parent().set_meta("tide", level if state == 2 else level * 0.5)
		_water()
		if state != 0 or Engine.get_physics_frames() % 30 == 0:
			queue_redraw()

	func high() -> bool:
		return state == 2

	# האם הנקודה (כפות רגליים) במים
	func wet(p: Vector2) -> bool:
		if absf(p.y - floor_y) > 10.0:
			return false
		if level > 0.35:
			return true
		for s in spans:
			if p.x > float(s[0]) and p.x < float(s[1]):
				return true
		for hd in holes:
			if is_instance_valid(hd) and hd.state == 2:
				var r: Rect2 = hd.water_rect()
				if p.x > r.position.x and p.x < r.end.x:
					return true
		return false

	func _water() -> void:
		var pl := get_tree().get_first_node_in_group("player")
		if pl == null:
			return
		var w := wet(pl.global_position)
		if w and level > 0.35 and not pl.in_water:
			soaked += 1
		pl.in_water = w

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if level <= 0.01:
			return
		var cam := get_viewport().get_camera_2d()
		if cam == null:
			return
		var c := cam.get_screen_center_position()
		var x0 := c.x - 700.0
		var hh := H * level
		var top := floor_y - hh
		DrawBatch.rect(self, Rect2(x0, top, 1400.0, hh + 12.0), Color(WATER, 0.78))
		DrawBatch.rect(self, Rect2(x0, top - 1.0, 1400.0, 2.0), Color(0.82, 0.78, 0.62, 0.5))
		for q in 24:
			var rx := x0 + fposmod(float(q) * 61.0 + _tt * 30.0, 1400.0)
			DrawBatch.line(self, Vector2(rx, top + 3.0 + float(q % 3) * 5.0), Vector2(rx + 22.0, top + 3.0 + float(q % 3) * 5.0), Color(0.85, 0.8, 0.62, 0.35), 1.2)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "wreck"
	var size := Vector2(60, 50)
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
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var w := size.x
		var h := size.y
		match kind:
			"wreck":   # סירה חלודה הפוכה על הגדה
				var hull := PackedVector2Array([Vector2(0, 0), Vector2(w * 0.04, -h * 0.7), Vector2(w * 0.2, -h), Vector2(w * 0.85, -h), Vector2(w, -h * 0.55), Vector2(w * 0.97, 0)])
				DrawBatch.colored_polygon(self, hull, Color("1a1612"))
				var inner := PackedVector2Array([Vector2(2, -1), Vector2(w * 0.06, -h * 0.68), Vector2(w * 0.21, -h + 2), Vector2(w * 0.84, -h + 2), Vector2(w - 2, -h * 0.55), Vector2(w * 0.96, -1)])
				DrawBatch.colored_polygon(self, inner, Color("6a4a3a"))
				for q in 5:   # חלודה ופסים
					var rx := w * (0.15 + float(q) * 0.16)
					DrawBatch.line(self, Vector2(rx, -h + 4.0), Vector2(rx - 2.0, -2.0), Color("4a2e22"), 2.0)
					DrawBatch.circle(self, Vector2(rx + 6.0, -h * 0.5 + float((q * 7 + seed_v) % 10)), 3.0 + float(q % 2), Color("8a4a26"))
				DrawBatch.rect(self, Rect2(w * 0.2, -h * 0.62, w * 0.62, 5), Color("c8c0a8"))   # פס צבע
				DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w * 0.25, -h * 0.68), "TIGRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("2a2a2a"))
				DrawBatch.rect(self, Rect2(w * 0.3, -h * 0.35, 8, 8), Color("1a1612"))   # חור
			"crates":   # ארגזי פירות וסלי נצרים (נמל הפירות)
				DrawBatch.rect(self, Rect2(0, -h * 0.55, w * 0.55, h * 0.55), Color("1a1410"))
				DrawBatch.rect(self, Rect2(1, -h * 0.55 + 1, w * 0.55 - 2, h * 0.55 - 2), Color("a8844a"))
				for q in 3:
					DrawBatch.line(self, Vector2(1, -h * 0.55 + 4.0 + float(q) * h * 0.16), Vector2(w * 0.55 - 1, -h * 0.55 + 4.0 + float(q) * h * 0.16), Color("7a5a2a"), 1.2)
				for q in 5:   # תפוזים
					DrawBatch.circle(self, Vector2(5.0 + float(q) * w * 0.1, -h * 0.55), 4.0, Color("e08a2a"))
				DrawBatch.rect(self, Rect2(w * 0.08, -h, w * 0.4, h * 0.45), Color("1a1410"))
				DrawBatch.rect(self, Rect2(w * 0.08 + 1, -h + 1, w * 0.4 - 2, h * 0.45 - 2), Color("9a7a44"))
				var bc := Vector2(w * 0.78, -h * 0.35)   # סל נצרים
				DrawBatch.colored_polygon(self, Art.ellipse(bc, w * 0.2, h * 0.36, 0.0, 14), Color("8a6a3a"))
				for q in 5:
					DrawBatch.line(self, bc + Vector2(-w * 0.18, -h * 0.25 + float(q) * h * 0.12), bc + Vector2(w * 0.18, -h * 0.25 + float(q) * h * 0.12), Color("5a4220"), 1.2)
				for q in 4:
					DrawBatch.circle(self, bc + Vector2(-w * 0.12 + float(q) * w * 0.08, -h * 0.32), 3.5, Color("c83a2a") if q % 2 == 0 else Color("e0c040"))
			_:   # תוף רשתות + מצופים
				DrawBatch.rect(self, Rect2(w * 0.05, -h * 0.85, w * 0.6, h * 0.85), Color("1a1612"))
				DrawBatch.rect(self, Rect2(w * 0.05 + 2, -h * 0.85 + 2, w * 0.6 - 4, h * 0.85 - 4), Color("4a4a50"))
				for q in 6:
					DrawBatch.line(self, Vector2(w * 0.05 + 2, -h * 0.8 + float(q) * h * 0.13), Vector2(w * 0.65 - 2, -h * 0.75 + float(q) * h * 0.13), Color(0.35, 0.4, 0.3, 0.9), 2.0)
				for q in 8:   # רשת שנופלת
					DrawBatch.line(self, Vector2(w * 0.62, -h * 0.6 + float(q) * 4.0), Vector2(w * 0.95, -2.0 + float(q % 3)), Color(0.4, 0.42, 0.32, 0.8), 1.0)
				DrawBatch.circle(self, Vector2(w * 0.82, -h * 0.25), h * 0.16, Color("d84a2a"))
				DrawBatch.circle(self, Vector2(w * 0.92, -h * 0.12), h * 0.12, Color("e8c040"))


# ---- מועדון החתירה בסוף השלב ----
class RowingClub extends Node2D:
	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var t := float(Engine.get_process_frames()) / 60.0
		var cream := Color("d8d0bc")
		var beam := Color("3a2a1e")
		DrawBatch.rect(self, Rect2(-260, -250, 520, 250), cream)
		for q in 18:   # קורות טיודור
			DrawBatch.line(self, Vector2(-260.0 + float(q) * 30.6, -250), Vector2(-260.0 + float(q) * 30.6, -130), beam, 4.0)
		DrawBatch.line(self, Vector2(-260, -190), Vector2(260, -190), beam, 4.0)
		DrawBatch.line(self, Vector2(-260, -130), Vector2(260, -130), beam, 5.0)
		for q in 8:
			DrawBatch.line(self, Vector2(-260.0 + float(q) * 65.0, -250), Vector2(-260.0 + float(q) * 65.0 + 32.0, -190), beam, 3.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-290, -250), Vector2(0, -380), Vector2(290, -250)]), Color("4a2a24"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-90, -300), Vector2(0, -342), Vector2(90, -300)]), cream)
		DrawBatch.line(self, Vector2(0, -342), Vector2(0, -300), beam, 3.0)
		DrawBatch.rect(self, Rect2(-130, -236, 260, 30), Color("1e2a3a"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-108, -214), "CLUB DE REMO", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.92, 0.85, 0.6))
		for q in 3:   # דלתות קשת לסירות (פתוחות, חושך בפנים)
			var dx := -230.0 + float(q) * 160.0
			DrawBatch.rect(self, Rect2(dx, -110, 140, 110), Color("16140f"))
			DrawBatch.circle(self, Vector2(dx + 70.0, -110.0), 70.0, Color("16140f"))
			DrawBatch.arc(self, Vector2(dx + 70.0, -110.0), 70.0, PI, TAU, 18, beam, 5.0)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(dx + 10, -40), Vector2(dx + 130, -46), Vector2(dx + 126, -38), Vector2(dx + 14, -34)]), Color("8a5a2a"))   # סירת חתירה דקה על מתלה
		var fw := sin(t * 2.5) * 6.0   # דגל
		DrawBatch.line(self, Vector2(0, -380), Vector2(0, -440), Color("3a3a3a"), 3.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, -440), Vector2(50 + fw, -430), Vector2(0, -418)]), Color("6a9ad0"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, -432), Vector2(30 + fw * 0.6, -428), Vector2(0, -424)]), Color("f0f0f0"))
		for q in 2:   # משוטים מוצלבים
			var s := -1.0 if q == 0 else 1.0
			DrawBatch.line(self, Vector2(-160.0 * s - 40.0, -300), Vector2(-160.0 * s + 40.0, -270), Color("8a6a3a"), 4.0)
			DrawBatch.line(self, Vector2(-160.0 * s + 40.0, -300), Vector2(-160.0 * s - 40.0, -270), Color("8a6a3a"), 4.0)


# ---- ערפל + יתושים (מסך) ----
class DeltaFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var n := Quality.scaled(9, Quality.ambient())
		for i in n:   # פסי ערפל ארוכים שזזים לאורך המסך
			var x := fposmod(float(i) * 233.0 + _t * (12.0 + float(i % 4) * 5.0), vp.x + 900.0) - 450.0
			var y := vp.y * (0.45 + float(i % 5) * 0.11) + sin(_t * 0.3 + float(i)) * 12.0
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x, y), 380.0, 24.0 + float(i % 3) * 10.0, 0.0, 16), Color(0.82, 0.86, 0.8, 0.07))
		for i in Quality.scaled(14, Quality.ambient()):   # יתושים
			var cx := fposmod(float(i) * 97.0, vp.x)
			var cy := vp.y * 0.8 + float(i % 4) * 12.0
			var p := Vector2(cx + sin(_t * 7.0 + float(i) * 2.1) * 10.0, cy + cos(_t * 9.0 + float(i)) * 6.0)
			DrawBatch.circle(self, p, 1.0, Color(0.1, 0.1, 0.08, 0.6))
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.5, 0.65, 0.55, 0.06))
