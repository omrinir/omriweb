extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 28 ("DEATH ROAD") - "דרך המוות" של היונגס בבוליביה: כביש עפר צר שחצוב בצוק,
#  בתוך יער עננים. ערפל עולה מהעמק, מפלים שנופלים על הכביש, אוטובוסים ומשאיות שהתרסקו,
#  צלבים ומקדשונים קטנים (אנימיטות) לזכר מי שנפל.
#    yungas_sky    - (רקע) דמדומים מעוננים, אור חם מאחורי העננים
#    far_ranges    - (רקע) הקורדיירה המושלגת רחוק + רכסים אפורים, ערפל בין השכבות
#    mid_slope     - (רקע) ההר שממול: יער ירוק כהה, הכביש חצוב בו, משאיות עם פנסים, צלבים, מפלים
#    near_canopy   - (רקע) צמרות יער העננים מתחת לכביש + שרכי עץ, ערפל
#    RoadGround    - (עולם) כביש עפר בוצי: תעלות גלגלים, שלוליות, חצץ, שורשים
#    Washout       - (עולם, מלכודת, קבוצה "washouts") הכביש נשבר: בור עם ברזלים חלודים וסלעים (יורש SpikePit משלב 21),
#                    ערפל עולה מבפנים. שם מחכים ה-CLINGER.
#    CliffLedge    - (עולם, קבוצה "ledges") קטע כביש עליון חצוב בצוק, עם קורות עץ שתומכות בו. מאחוריו קיר סלע עם טחב.
#    Waterfall     - (עולם) מפל שנופל מהצוק על הכביש: מסך מים שקוף, רסס וטיפות
#    WreckBus      - (מוצק + מחסה) אוטובוס "פלוטה" שהתרסק, ידיים בחלונות. מתקרבים -> נוסעים זומבים יוצאים (on_open)
#    WreckTruck    - (מוצק + מחסה) משאית הפוכה ובוערת עם עמוד עשן
#    Shrine        - (עולם) אנימיטה: בית קטן עם צלב, נרות מהבהבים ופרחים
#    Obstacle      - (מוצק + מחסה) "slide_rocks" מפולת סלעים ובוץ / "fuel_drums" חביות דלק חלודות / "luggage" מטען שנפל מהגג
#    RoadFX        - (מסך) טפטוף, גדות ערפל שעוברות
#  לשנות: WreckBus.OPEN_R, Waterfall, CliffLedge.TOP_EXTRA.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const MUD := Color("6e5a42")
const MUD_D := Color("3a2e24")
const ROCK := Color("4a463c")
const ROCK_D := Color("2e2b25")
const MOSS := Color("4a6a34")
const FOREST := Color("2c4234")
const FOREST_D := Color("1c2e24")
const MIST := Color(0.84, 0.84, 0.8)


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- רעש חלק (רכסים שממשיכים בלי תפרים כשהמצלמה זזה) ----
static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)


static func _vn(t: float, s: int) -> float:
	var i := floori(t)
	var f := t - float(i)
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_h(i, s), _h(i + 1, s), f)


static func _ridge(u: float, period: float, s: int) -> float:   # 0..1, פסגות חדות
	var a := _vn(u / period, s)
	var b := 1.0 - absf(_vn(u / (period * 0.42), s + 7) * 2.0 - 1.0)
	var c := _vn(u / (period * 0.14), s + 13)
	return a * 0.5 + b * 0.36 + c * 0.14


static func _ridge_pts(sc: float, v: Vector2, base: float, amp: float, period: float, s: int, step := 16.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x := -step
	while x <= v.x + step:
		pts.append(Vector2(x, base - _ridge(x + sc, period, s) * amp))
		x += step
	return pts


static func _fill_below(ci: CanvasItem, pts: PackedVector2Array, v: Vector2, col: Color) -> void:
	var poly := pts.duplicate()
	poly.append(Vector2(pts[pts.size() - 1].x, v.y))
	poly.append(Vector2(pts[0].x, v.y))
	DrawBatch.colored_polygon(ci, poly, col)


# ערפל שמצטבר למטה (שקוף למעלה, סמיך למטה)
static func _fog(ci: CanvasItem, v: Vector2, y0: float, y1: float, col: Color) -> void:
	var n := 6
	var hh := (y1 - y0) / float(n)
	for i in n:
		DrawBatch.rect(ci, Rect2(0, y0 + hh * float(i), v.x, hh + 1.0), Color(col, col.a * float(i + 1) / float(n)))


# ---- דמדומים מעוננים ----
static func yungas_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("262c36"), Color("3e4856"), Color("6a6e72"), Color("a88e7a"), Color("caa486")], 0.8)
	var sun := Vector2(v.x * 0.68, v.y * 0.42)   # שמש שוקעת מאחורי העננים
	Kit.soft_glow(ci, sun, 300.0, Color(1.0, 0.72, 0.45, 0.42))   # הילה רכה (היו 5 טבעות)
	for i in 5:   # שכבות עננים כבדות
		var y := v.y * (0.08 + 0.075 * float(i))
		var x := fposmod(t * (2.0 + float(i)) + float(i) * 390.0, v.x + 900.0) - 450.0
		var c := Color("2e3440").lerp(Color("8a7a70"), float(i) / 4.0)
		for q in 4:
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(x + float(q) * 230.0, y + float(q % 2) * 10.0), 210.0, 22.0 + float(q % 3) * 6.0, 0.0, 14), Color(c, 0.55))


# ---- הקורדיירה המושלגת + רכסים אפורים ----
static func far_ranges(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var snow := _ridge_pts(sc * 0.5, v, y - 110.0, 240.0, 900.0, 3, 18.0)
	_fill_below(ci, snow, v, Color("8a94a0"))
	for i in snow.size() - 1:   # שלג על הפסגות
		var a := snow[i]
		var b := snow[i + 1]
		var la := (y - 110.0 - a.y) / 240.0
		var lb := (y - 110.0 - b.y) / 240.0
		if la > 0.6 and lb > 0.6:
			DrawBatch.colored_polygon(ci, PackedVector2Array([a, b, b + Vector2(0, (lb - 0.6) * 90.0), a + Vector2(0, (la - 0.6) * 90.0)]), Color("e4e8ee"))
	_fog(ci, v, y - 210.0, y - 60.0, Color(MIST, 0.55))
	var mid := _ridge_pts(sc, v, y - 10.0, 210.0, 620.0, 11)
	_fill_below(ci, mid, v, Color("566468"))
	_fog(ci, v, y - 120.0, y + 10.0, Color(MIST, 0.5))
	for i in 3:   # ענני נוצה שנעים בעמק
		var cx := fposmod(t * (6.0 + float(i) * 3.0) - sc * 0.2 + float(i) * 640.0, v.x + 1000.0) - 500.0
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, y - 70.0 + float(i) * 22.0), 260.0, 18.0, 0.0, 16), Color(1, 1, 1, 0.12))


# ---- ההר שממול: יער, הכביש חצוב בו, משאיות, צלבים, מפלים ----
static func _road_y(u: float, base: float, amp: float) -> float:
	return base - _ridge(u, 760.0, 41) * amp + 74.0 + sin(u / 260.0) * 22.0


static func mid_slope(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var amp := 300.0
	var top := PackedVector2Array()   # הרכס + צמרות עצים פרועות (בפוליגון אחד - זול)
	var x0 := -fposmod(sc, 9.0) - 9.0
	while x0 <= v.x + 18.0:
		var u := x0 + sc
		top.append(Vector2(x0, y - _ridge(u, 760.0, 41) * amp - _h(roundi(u / 9.0), 23) * 7.0))
		x0 += 9.0
	_fill_below(ci, top, v, FOREST)
	# הכביש חצוב בהר (קו בהיר + שוליים כהים)
	var road := PackedVector2Array()
	var x := -16.0
	while x <= v.x + 16.0:
		road.append(Vector2(x, _road_y(x + sc, y, amp)))
		x += 16.0
	DrawBatch.polyline(ci, road, Color("22302a"), 4.0)
	DrawBatch.polyline(ci, road, Color(0.62, 0.56, 0.45, 0.45), 1.5)
	# צלבים ומפלים לאורך הכביש
	var p0 := int(floor(sc / 380.0)) - 1
	for k in range(p0, p0 + int(v.x / 380.0) + 3):
		var u := float(k) * 380.0 + _h(k, 5) * 200.0
		var sx := u - sc
		var ry := _road_y(u, y, amp)
		if _h(k, 9) < 0.45:
			DrawBatch.line(ci, Vector2(sx, ry - 2), Vector2(sx, ry - 10), Color(0.95, 0.95, 0.92, 0.9), 1.5)
			DrawBatch.line(ci, Vector2(sx - 3, ry - 7.5), Vector2(sx + 3, ry - 7.5), Color(0.95, 0.95, 0.92, 0.9), 1.5)
		if _h(k, 17) < 0.3:   # מפל דק מהכביש למטה
			var fx := sx + 60.0
			var fy := _road_y(u + 60.0, y, amp) + 3.0
			for q in 3:
				var yy := fy + fposmod(t * 70.0 + float(q) * 33.0, 100.0)
				DrawBatch.line(ci, Vector2(fx, yy), Vector2(fx + 1, yy + 22.0), Color(0.85, 0.92, 1.0, 0.5), 2.0)
			DrawBatch.line(ci, Vector2(fx, fy), Vector2(fx + 2, fy + 120.0), Color(0.85, 0.92, 1.0, 0.22), 3.0)
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(fx + 2, fy + 122.0), 16.0, 6.0, 0.0, 10), Color(1, 1, 1, 0.25))
	# משאיות עם פנסים שזוחלות בכביש (בשני הכיוונים)
	for i in 3:
		var dirn := 1.0 if i % 2 == 0 else -1.0
		var u: float = fposmod(t * 16.0 * dirn + float(i) * 1700.0, 4200.0) + floorf(sc / 4200.0) * 4200.0
		var sx: float = u - sc
		if sx < -100.0:
			sx += 4200.0
			u += 4200.0
		if sx > v.x + 60.0:
			continue
		var ry := _road_y(u, y, amp)
		DrawBatch.rect(ci, Rect2(sx - 10, ry - 9, 14, 7), Color("4a3a2a"))
		DrawBatch.rect(ci, Rect2(sx + (4.0 if dirn > 0.0 else -16.0), ry - 7, 6, 5), Color("6a2a20"))
		var hl := Vector2(sx + (10.0 if dirn > 0.0 else -16.0), ry - 5)
		DrawBatch.circle(ci, hl, 1.6, Color(1.0, 0.95, 0.7))
		DrawBatch.colored_polygon(ci, PackedVector2Array([hl, hl + Vector2(dirn * 44.0, -6), hl + Vector2(dirn * 44.0, 6)]), Color(1.0, 0.95, 0.7, 0.12))
	_fog(ci, v, y - 120.0, y + 6.0, Color(MIST, 0.6))
	for i in 2:   # ענן שעולה מהעמק ונדבק להר
		var cx := fposmod(t * (9.0 + float(i) * 4.0) - sc * 0.5 + float(i) * 800.0, v.x + 1100.0) - 550.0
		for q in 3:
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx + float(q) * 120.0, y - 150.0 + float(i) * 50.0 + float(q % 2) * 12.0), 170.0, 26.0, 0.0, 14), Color(1, 1, 1, 0.1))


# ---- צמרות יער העננים מתחת לכביש + שרכי עץ ----
static func near_canopy(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var r := _rng(k * 113 + 7)
		for i in 7:   # צמרות
			var cx := x + r.randf_range(0.0, period)
			var cy := y - r.randf_range(10.0, 60.0)
			var c := FOREST_D.lerp(Color("2a4a30"), r.randf())
			for q in 3:
				DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx + float(q - 1) * 26.0, cy + float(q % 2) * 10.0), 34.0, 22.0, 0.0, 12), c)
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx - 6.0, cy - 10.0), 22.0, 9.0, 0.0, 10), Color(0.5, 0.65, 0.4, 0.12))
		for i in 2:   # שרך עץ
			var fx := x + r.randf_range(0.0, period)
			var ft := Vector2(fx + 6.0, y - r.randf_range(90.0, 130.0))
			DrawBatch.line(ci, Vector2(fx, y), ft, Color("2a2018"), 4.0)
			for f in 8:
				var a := -PI + float(f) * PI / 7.0 + sin(t * 0.8 + fx) * 0.04
				var d := Vector2.from_angle(a)
				var tip := ft + d * 46.0 + Vector2(0, 22.0 * absf(d.x))
				DrawBatch.polyline(ci, PackedVector2Array([ft, ft + d * 22.0 + Vector2(0, -4), tip]), Color("1e3a24"), 3.0)
	_fog(ci, v, y - 70.0, y + 10.0, Color(MIST, 0.35))
	DrawBatch.rect(ci, Rect2(0, y + 10.0, v.x, v.y - y), Color("16241c"))


# ---- כביש עפר בוצי ----
class RoadGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s28_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), S.MUD_D)
		DrawBatch.rect(self, Rect2(0, 0, w, 10.0), S.MUD)
		DrawBatch.line(self, Vector2(0, 0.5), Vector2(w, 0.5), Color(0.8, 0.7, 0.55, 0.35), 1.0)
		var x := 0.0
		while x < w:   # תעלות גלגלים
			var l := r.randf_range(40.0, 120.0)
			DrawBatch.line(self, Vector2(x, 4.0), Vector2(minf(x + l, w), 4.0 + r.randf_range(-0.6, 0.6)), Color("54442f"), 2.0)
			DrawBatch.line(self, Vector2(x + 14.0, 8.0), Vector2(minf(x + l * 0.8, w), 8.0), Color("54442f"), 1.5)
			x += l + r.randf_range(20.0, 60.0)
		for i in int(w / 260.0):   # שלוליות שמשקפות את השמיים
			var px := r.randf_range(30.0, w - 60.0)
			var pw := r.randf_range(20.0, 44.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(px, 4.0), pw, 2.6, 0.0, 12), Color("8e8a86"))
			DrawBatch.line(self, Vector2(px - pw * 0.5, 3.5), Vector2(px + pw * 0.2, 3.5), Color(1, 0.9, 0.8, 0.5), 1.0)
		for i in int(w / 12.0):   # חצץ
			DrawBatch.circle(self, Vector2(r.randf_range(0.0, w), r.randf_range(1.0, 9.0)), r.randf_range(0.8, 1.8), Color(0.6, 0.55, 0.48, 0.6))
		for i in int(w / 70.0):   # אבנים באדמה
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(r.randf_range(0.0, w), r.randf_range(18.0, depth - 6.0)), r.randf_range(4.0, 9.0), r.randf_range(3.0, 5.0), r.randf(), 8), Color("4a3e30"))
		for i in int(w / 160.0):   # שורשים
			var rx := r.randf_range(0.0, w)
			var pts := PackedVector2Array()
			for q in 5:
				pts.append(Vector2(rx + sin(float(q) * 1.7 + rx) * 8.0, 12.0 + float(q) * 9.0))
			DrawBatch.polyline(self, pts, Color("2a2018"), 1.6)
		for i in int(w / 90.0):   # עשב בשוליים
			var gx := r.randf_range(0.0, w)
			for q in 4:
				DrawBatch.line(self, Vector2(gx + float(q) * 2.5, 1.0), Vector2(gx + float(q) * 2.5 + r.randf_range(-3.0, 3.0), -r.randf_range(4.0, 9.0)), S.MOSS, 1.2)


# ---- הכביש נשבר: בור עם ברזלים חלודים (יורש את בור היתדות של שלב 21) ----
class Washout extends "res://effects/s21_decor.gd".SpikePit:
	func _ready() -> void:
		super._ready()
		add_to_group("washouts")
		var m := WashoutMist.new()
		m.w = w
		m.depth = depth
		m.z_index = 2   # (יחסי: מעל ה-CLINGER שתלוי בפנים)
		add_child(m)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = _seed
		var S := preload("res://effects/s28_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth + 30.0), Color("16140f"))
		# קירות משוננים (אדמה וסלע)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(6, 14), Vector2(12, 28), Vector2(5, 44), Vector2(9, depth), Vector2(0, depth)]), Color("4a3c2e"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w, 0), Vector2(w - 9, 0), Vector2(w - 5, 16), Vector2(w - 12, 30), Vector2(w - 4, 46), Vector2(w - 8, depth), Vector2(w, depth)]), Color("4a3c2e"))
		# קצוות כביש שבורים שתלויים מעל
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(16, 1), Vector2(11, 5), Vector2(4, 9), Vector2(0, 8)]), S.MUD)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w, 0), Vector2(w - 14, 1), Vector2(w - 8, 6), Vector2(w, 9)]), S.MUD)
		for i in 4:   # שורשים תלויים
			var rx := r.randf_range(4.0, 12.0) if i < 2 else w - r.randf_range(4.0, 12.0)
			DrawBatch.polyline(self, PackedVector2Array([Vector2(rx, 6), Vector2(rx + r.randf_range(-4, 4), 20), Vector2(rx + r.randf_range(-6, 6), 30 + r.randf_range(0, 10))]), Color("2a2018"), 1.4)
		# התחתית: סלעים שבורים וברזלים חלודים (זה מה שפוגע)
		DrawBatch.rect(self, Rect2(0, depth - 4.0, w, 34.0), Color("2a241c"))
		var n := int(w / 11.0)
		for i in n:
			var x := 5.0 + float(i) * (w - 10.0) / float(maxi(n - 1, 1))
			if i % 2 == 0:
				var hh := r.randf_range(12.0, 20.0)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x - 6, depth), Vector2(x - 2, depth - hh), Vector2(x + 4, depth - hh * 0.7), Vector2(x + 6, depth)]), Color("3a342c"))
			else:
				var tip := Vector2(x + r.randf_range(-5.0, 5.0), depth - r.randf_range(20.0, 28.0))
				DrawBatch.line(self, Vector2(x, depth), tip, Color("7a4a2a"), 2.2)
				DrawBatch.line(self, tip, tip + Vector2(0, 3), Color("c08050"), 2.2)
		# שלט אזהרה צהוב לפני הבור
		DrawBatch.line(self, Vector2(-18, 0), Vector2(-18, -30), Color("5a4030"), 2.5)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-18, -44), Vector2(-6, -32), Vector2(-18, -20), Vector2(-30, -32)]), Color("e0b020"))
		DrawBatch.polyline(self, PackedVector2Array([Vector2(-18, -44), Vector2(-6, -32), Vector2(-18, -20), Vector2(-30, -32), Vector2(-18, -44)]), Color("2a2010"), 1.2)
		DrawBatch.line(self, Vector2(-18, -38), Vector2(-18, -30), Color("2a2010"), 2.0)
		DrawBatch.circle(self, Vector2(-18, -26), 1.2, Color("2a2010"))


class WashoutMist extends Node2D:   # ערפל שעולה מתוך הבור (מעל ה-CLINGER - רק הידיים והראש בולטים)
	var w := 80.0
	var depth := 60.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var n := 5
		for i in n:
			var y0 := 18.0 + float(i) * (depth + 12.0 - 18.0) / float(n)
			DrawBatch.rect(self, Rect2(0, y0, w, (depth - 6.0) / float(n) + 1.0), Color(0.5, 0.54, 0.54, 0.12 + 0.08 * float(i)))
		for q in 3:   # סלסולי ערפל שעולים
			var yy := depth - fposmod(_t * 14.0 + float(q) * 20.0, depth - 10.0)
			var a := 0.18 * clampf(yy / depth, 0.0, 1.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * (0.25 + 0.25 * float(q)) + sin(_t + float(q)) * 6.0, yy), w * 0.3, 6.0, 0.0, 10), Color(0.75, 0.78, 0.78, a))


# ---- קטע כביש עליון חצוב בצוק (קורות עץ מתחת), קיר סלע עם טחב מאחור ----
class CliffLedge extends Node2D:
	const TOP_EXTRA := 520.0
	var w := 400.0
	var h := 150.0
	var seed_v := 0
	var cross := false

	func _ready() -> void:
		z_index = -1
		add_to_group("ledges")

	func lip_y() -> float:
		return global_position.y - h

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s28_decor.gd")
		# קיר הסלע (מאחורי הכביש - כהה)
		var H := h + TOP_EXTRA
		var face := PackedVector2Array([Vector2(-70, 0)])
		var yy := -40.0
		while yy > -H + 30.0:   # צד שמאל משונן, משתפע פנימה למעלה
			face.append(Vector2(lerpf(-70.0, 6.0, -yy / H) + r.randf_range(-12.0, 12.0), yy))
			yy -= 46.0
		var x := 10.0
		while x < w - 10.0:   # הפסגה (מחוץ למסך)
			face.append(Vector2(x, -H + r.randf_range(-20.0, 26.0)))
			x += 60.0
		yy = -H + 30.0
		while yy < -40.0:   # צד ימין
			face.append(Vector2(lerpf(w + 70.0, w - 6.0, -yy / H) + r.randf_range(-12.0, 12.0), yy))
			yy += 46.0
		face.append(Vector2(w + 70.0, 0))
		DrawBatch.colored_polygon(self, face, S.ROCK)
		for i in 4:   # שכבות סלע אופקיות
			var sy := -h - 40.0 - float(i) * r.randf_range(70.0, 100.0)
			var pts := PackedVector2Array()
			for q in 8:
				var qx := lerpf(-40.0, w + 40.0, float(q) / 7.0)
				pts.append(Vector2(qx, sy + r.randf_range(-6.0, 6.0)))
			DrawBatch.polyline(self, pts, S.ROCK_D, 2.0)
		for i in int(w / 26.0):   # שכבות וסדקים
			var cx := r.randf_range(-10.0, w + 10.0)
			var cy := -r.randf_range(10.0, h + TOP_EXTRA - 30.0)
			DrawBatch.line(self, Vector2(cx, cy), Vector2(cx + r.randf_range(-8.0, 8.0), cy + r.randf_range(18.0, 46.0)), S.ROCK_D, 1.5)
		for i in int(w / 40.0):   # כתמי טחב ושרכים קטנים
			var mp := Vector2(r.randf_range(-10.0, w + 10.0), -r.randf_range(20.0, h + TOP_EXTRA - 30.0))
			DrawBatch.colored_polygon(self, Art.ellipse(mp, r.randf_range(10.0, 22.0), r.randf_range(4.0, 8.0), 0.0, 10), Color(S.MOSS, 0.75))
			for f in 3:
				DrawBatch.line(self, mp, mp + Vector2.from_angle(-PI * 0.5 + float(f - 1) * 0.6) * 9.0, Color("5a7a3a"), 1.2)
		for i in int(w / 45.0):   # שרכים וגפנים שנתלים מבליטות בצוק
			var vx := r.randf_range(0.0, w)
			var vl := r.randf_range(40.0, 120.0)
			var top := -h - r.randf_range(60.0, TOP_EXTRA - 120.0)
			DrawBatch.line(self, Vector2(vx, top), Vector2(vx + r.randf_range(-6.0, 6.0), top + vl), Color("2e4a26"), 1.4)
			for q in int(vl / 16.0):
				var ly := top + float(q) * 16.0 + 6.0
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(vx + (3.0 if q % 2 == 0 else -3.0), ly), 3.5, 1.8, 0.4 if q % 2 == 0 else -0.4, 6), Color("3e6a30"))
		for i in 3:   # ערפל שנאחז בצוק (גובה)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * (0.2 + 0.3 * float(i)), -h - 190.0 - float(i % 2) * 40.0), w * 0.32, 18.0, 0.0, 14), Color(S.MIST, 0.12))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-40, -h + 22.0), Vector2(w + 40.0, -h + 22.0), Vector2(w + 60.0, 0), Vector2(-60, 0)]), Color(0, 0, 0, 0.18))   # צל מתחת לכביש העליון
		# הכביש העליון: מדף עפר עם קורות עץ
		var lip := -h
		for bx in range(0, int(w) + 1, 70):
			DrawBatch.line(self, Vector2(float(bx) + 8.0, lip + 18.0), Vector2(float(bx) - 14.0, lip + 66.0), Color("4a3424"), 5.0)
			DrawBatch.line(self, Vector2(float(bx) + 8.0, lip + 18.0), Vector2(float(bx) - 14.0, lip + 66.0), Color("6a4a30"), 2.0)
			DrawBatch.circle(self, Vector2(float(bx) - 14.0, lip + 66.0), 2.5, Color("5a5a5a"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-14, lip), Vector2(w + 14, lip), Vector2(w + 8, lip + 12), Vector2(w - 10, lip + 20), Vector2(20, lip + 21), Vector2(-8, lip + 13)]), S.MUD_D)
		DrawBatch.rect(self, Rect2(-14, lip, w + 28, 7), S.MUD)
		DrawBatch.line(self, Vector2(-14, lip + 0.5), Vector2(w + 14, lip + 0.5), Color(0.85, 0.75, 0.6, 0.4), 1.0)
		for i in int(w / 60.0):   # אבנים ועשב על המדף
			var gx := r.randf_range(0.0, w)
			for q in 3:
				DrawBatch.line(self, Vector2(gx + float(q) * 2.5, lip), Vector2(gx + float(q) * 2.5 + r.randf_range(-3.0, 3.0), lip - r.randf_range(4.0, 8.0)), S.MOSS, 1.2)
		if cross:   # צלב לבן על השפה
			var cx := w * 0.62
			DrawBatch.line(self, Vector2(cx, lip), Vector2(cx, lip - 24), Color("e8e4dc"), 2.5)
			DrawBatch.line(self, Vector2(cx - 7, lip - 17), Vector2(cx + 7, lip - 17), Color("e8e4dc"), 2.5)
			DrawBatch.circle(self, Vector2(cx - 4, lip - 2), 2.5, Color("d03a5a"))
			DrawBatch.circle(self, Vector2(cx + 4, lip - 2), 2.5, Color("e8c030"))


# ---- מפל שנופל מהצוק על הכביש ----
class Waterfall extends Node2D:
	var height := 380.0
	var w := 22.0
	var _t := 0.0
	var _puff := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta
		_puff -= delta
		if not Art.on_screen(self, global_position + Vector2(0, -60.0), 200.0):
			return
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()
		if _puff <= 0.0:
			_puff = 0.3
			Particles.burst(get_parent(), global_position + Vector2(w * 0.5, -6.0), "mist", Vector2.UP, 2)
			if randf() < 0.5:
				Particles.burst(get_parent(), global_position + Vector2(w * 0.5, -4.0), "drop", Vector2.UP, 3)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-6, -height - 6), Vector2(w + 8, -height - 4), Vector2(w + 4, -height + 10), Vector2(-2, -height + 8)]), Color("3a362e"))   # שפת הסלע
		DrawBatch.rect(self, Rect2(0, -height, w, height), Color(0.72, 0.82, 0.9, 0.32))
		for j in 6:   # פסי מים נופלים
			var x := 2.0 + float(j) * (w - 4.0) / 5.0
			for k in 5:
				var y := fposmod(_t * 300.0 + float(j) * 37.0 + float(k) * 80.0, height) - height
				DrawBatch.line(self, Vector2(x, y), Vector2(x + 0.5, minf(y + 34.0, 0.0)), Color(1, 1, 1, 0.42), 1.4)
		var s := 1.0 + sin(_t * 7.0) * 0.08   # רסס בתחתית + פלג שחוצה את הכביש
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -4.0), w * 1.4 * s, 9.0, 0.0, 14), Color(1, 1, 1, 0.35))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, 2.0), w * 2.6, 2.2, 0.0, 12), Color(0.7, 0.8, 0.88, 0.55))


# ---- אוטובוס "פלוטה" שהתרסק. מתקרבים -> נוסעים זומבים יוצאים ----
class WreckBus extends Node2D:
	const OPEN_R := 300.0         # כמה קרוב השחקן צריך להיות
	const KNOCK_R := 650.0        # מתחילים לדפוק על החלונות
	const SIZE := Vector2(240, 66)
	var seed_v := 0
	var on_open: Callable          # (bus) -> נקרא פעם אחת
	var opened := false
	var _knock := 0.0
	var _shake := 0.0
	var _check := 0.0

	func _ready() -> void:
		z_index = 1
		add_to_group("cover")
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = SIZE
		cs.shape = sh
		cs.position = Vector2(SIZE.x * 0.5, -SIZE.y * 0.5)
		body.add_child(cs)
		add_child(body)

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -SIZE.y), SIZE)

	func _physics_process(delta: float) -> void:
		_check -= delta
		_knock -= delta
		_shake = maxf(_shake - delta * 3.0, 0.0)
		if opened or _check > 0.0:
			return
		_check = 0.15
		var pl := get_tree().get_first_node_in_group("player")
		if pl == null or pl.dead:
			return
		var dx: float = absf(pl.global_position.x - (global_position.x + SIZE.x * 0.5))
		if dx < OPEN_R + SIZE.x * 0.5:
			opened = true
			_shake = 1.0
			Sfx.play("w28_bang", global_position + Vector2(SIZE.x * 0.5, -40.0), 4.0, 0.1, 2)
			if on_open.is_valid():
				on_open.call(self)
			queue_redraw()
		elif dx < KNOCK_R and _knock <= 0.0:   # דפיקות מבפנים (אזהרה)
			_knock = randf_range(1.2, 2.2)
			_shake = 0.5
			Sfx.play("w28_bang", global_position + Vector2(SIZE.x * 0.5, -40.0), -6.0, 0.15, 2)
			queue_redraw()
		if _shake > 0.0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var w := SIZE.x
		var hh := SIZE.y
		var jit := Vector2(sin(Time.get_ticks_msec() * 0.06) * 1.5 * _shake, 0.0)
		DrawBatch.set_transform(self, jit + Vector2(0, -2), -0.03, Vector2.ONE)   # נטוי - נפל על הצד של התעלה
		var body := Color("d8ccb0")
		Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, -hh + 8), Vector2(w - 10, -hh), Vector2(8, -hh), Vector2(0, -hh + 10)]), body, 0.1, 0.35, Art.OUTLINE, 1.8)
		DrawBatch.rect(self, Rect2(2, -24, w - 4, 7), Color("b02a2a"))   # פסים צבעוניים
		DrawBatch.rect(self, Rect2(2, -16, w - 4, 4), Color("2a5aa0"))
		for i in 7:   # חלונות שבורים
			var wx := 14.0 + float(i) * 30.0
			DrawBatch.rect(self, Rect2(wx, -hh + 10, 24, 20), Color("1a1c20"))
			DrawBatch.line(self, Vector2(wx + 3, -hh + 12), Vector2(wx + 16, -hh + 26), Color(0.7, 0.8, 0.85, 0.35), 1.0)
			if not opened and i % 2 == 1:   # ידיים על הזכוכית
				var hx := wx + 8.0 + sin(float(i) + Time.get_ticks_msec() * 0.004) * 2.0 * _shake
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(hx, -hh + 18), 3.5, 4.5, 0.0, 8), Color("8a9a70"))
				for f in 3:
					DrawBatch.line(self, Vector2(hx - 2.0 + float(f) * 2.0, -hh + 15), Vector2(hx - 2.5 + float(f) * 2.5, -hh + 11), Color("8a9a70"), 1.2)
		if opened:   # דלת פתוחה, דם על המדרגה
			DrawBatch.rect(self, Rect2(w - 34, -hh + 12, 18, hh - 14), Color("0e0e10"))
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w - 25, -3), 10.0, 2.5, 0.0, 10), Color("5a0a0a"))
		else:
			DrawBatch.rect(self, Rect2(w - 34, -hh + 12, 18, hh - 14), Color("3a4048"))
		for wc in [Vector2(40, -2), Vector2(w - 48, -2)]:   # גלגלים
			DrawBatch.circle(self, wc, 12.0, Art.OUTLINE)
			DrawBatch.circle(self, wc, 10.0, Color("222226"))
			DrawBatch.circle(self, wc, 4.0, Color("5a5a5e"))
		DrawBatch.rect(self, Rect2(w - 4, -30, 6, 8), Color("e8d890"))   # פנס מת
		# מטען על הגג: חבילות אגואיו צבעוניות
		DrawBatch.line(self, Vector2(10, -hh - 2), Vector2(w - 14, -hh - 2), Color("3a3a3a"), 2.0)
		var lx := 18.0
		for i in 5:
			var bw := r.randf_range(22.0, 34.0)
			var bh := r.randf_range(10.0, 16.0)
			Art.fill(self, PackedVector2Array([Vector2(lx, -hh - 2), Vector2(lx + bw, -hh - 2), Vector2(lx + bw - 2, -hh - 2 - bh), Vector2(lx + 2, -hh - 2 - bh)]), [Color("c0306a"), Color("2a8a5a"), Color("e08a20"), Color("6a3aa0")][i % 4], Art.OUTLINE, 1.0)
			DrawBatch.line(self, Vector2(lx + 2, -hh - 2 - bh * 0.5), Vector2(lx + bw - 2, -hh - 2 - bh * 0.5), Color(1, 1, 1, 0.5), 1.5)
			lx += bw + r.randf_range(6.0, 16.0)
		var f := ThemeDB.fallback_font
		DrawBatch.string(self, f, Vector2(30, -hh + 44), "FLOTA YUNGUENA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8a2020"))
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ---- משאית הפוכה ובוערת ----
class WreckTruck extends Node2D:
	const SIZE := Vector2(170, 58)
	var _puff := 0.0

	func _ready() -> void:
		z_index = 1
		add_to_group("cover")
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = SIZE
		cs.shape = sh
		cs.position = Vector2(SIZE.x * 0.5, -SIZE.y * 0.5)
		body.add_child(cs)
		add_child(body)
		var fire = preload("res://fire.gd").new()
		fire.width = 34.0
		fire.height = 40.0
		fire.position = Vector2(30, -SIZE.y + 4.0)
		add_child(fire)

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -SIZE.y), SIZE)

	func _process(delta: float) -> void:
		_puff -= delta
		if _puff <= 0.0 and Art.on_screen(self, global_position + Vector2(40, -60), 160.0):
			_puff = 0.18
			Particles.burst(get_parent(), global_position + Vector2(30.0 + randf_range(-8, 8), -SIZE.y - 20.0), "smoke", Vector2(0.25, -1.0), 2)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var w := SIZE.x
		var h := SIZE.y
		# ארגז המטען (הפוך - הגלגלים למעלה)
		Art.fill_shaded(self, PackedVector2Array([Vector2(56, 0), Vector2(w, 0), Vector2(w - 2, -h + 14), Vector2(58, -h + 14)]), Color("5a6a3a"), 0.1, 0.35, Art.OUTLINE, 1.6)
		for x in range(64, int(w) - 4, 12):
			DrawBatch.line(self, Vector2(x, -4), Vector2(x, -h + 18), Color(0, 0, 0, 0.25), 2.0)
		# תא נהג שרוף
		Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(58, 0), Vector2(58, -h + 6), Vector2(14, -h + 6), Vector2(0, -h + 22)]), Color("2e2a26"), 0.06, 0.2, Art.OUTLINE, 1.6)
		DrawBatch.rect(self, Rect2(14, -h + 14, 30, 16), Color("120e0c"))
		for wc in [Vector2(36, -h + 4), Vector2(110, -h + 12), Vector2(150, -h + 12)]:   # גלגלים באוויר
			DrawBatch.circle(self, wc, 11.0, Art.OUTLINE)
			DrawBatch.circle(self, wc, 9.0, Color("222226"))
			DrawBatch.circle(self, wc, 3.5, Color("4a4a4e"))
		Art.glow(self, Vector2(30, -h), 70.0, Color(1.0, 0.5, 0.2, 0.16))


# ---- אנימיטה: מקדשון לזכר מי שנפל ----
class Shrine extends Node2D:
	var _t := 0.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 5 == 0 and Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(-3, -16, 6, 16), Color("6a6258"))   # עמוד
		Art.fill_shaded(self, PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, -38), Vector2(0, -50), Vector2(-16, -38)]), Color("e0dcd0"), 0.1, 0.3, Art.OUTLINE, 1.2)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-19, -37), Vector2(0, -52), Vector2(19, -37), Vector2(16, -35), Vector2(0, -47), Vector2(-16, -35)]), Color("2a6aa0"))
		DrawBatch.line(self, Vector2(0, -52), Vector2(0, -64), Color("e8e4dc"), 2.0)   # צלב
		DrawBatch.line(self, Vector2(-5, -59), Vector2(5, -59), Color("e8e4dc"), 2.0)
		DrawBatch.rect(self, Rect2(-10, -34, 20, 15), Color("2a201a"))   # פנים
		for i in 3:   # נרות מהבהבים
			var cx := -6.0 + float(i) * 6.0
			DrawBatch.rect(self, Rect2(cx - 1, -24, 2, 5), Color("f0e8d0"))
			var fl := 1.0 + sin(_t * 13.0 + float(i) * 2.0) * 0.25
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(cx, -26.5), 1.2, 2.2 * fl, 0.0, 8), Color(1.0, 0.8, 0.3))
			DrawBatch.line(self, Vector2(cx, -29), Vector2(cx + sin(_t * 2.0 + float(i)) * 2.0, -33), Color(0.8, 0.8, 0.8, 0.25), 1.0)   # עשן דק
		Art.glow(self, Vector2(0, -26), 30.0, Color(1.0, 0.7, 0.3, 0.16 + 0.04 * sin(_t * 9.0)))
		for i in 4:   # פרחים
			var px := -14.0 + float(i) * 9.0
			DrawBatch.line(self, Vector2(px, 0), Vector2(px + 1, -8), Color("3a6a2a"), 1.2)
			DrawBatch.circle(self, Vector2(px + 1, -9), 2.2, [Color("e03a5a"), Color("f0c030"), Color("e8e8e8"), Color("c05ae0")][i])


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "slide_rocks"
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
		z_index = 1

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s28_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"slide_rocks":   # מפולת: בוץ + סלעים גדולים
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-10, 0), Vector2(w + 10, 0), Vector2(w - 6, -h * 0.4), Vector2(w * 0.5, -h * 0.55), Vector2(6, -h * 0.35)]), S.MUD_D)
				for i in 5:
					var c := Vector2(r.randf_range(w * 0.15, w * 0.85), -r.randf_range(h * 0.3, h * 0.65))
					if i == 0:
						c = Vector2(w * 0.5, -h * 0.55)
					var rr := r.randf_range(h * 0.22, h * 0.4) * (1.3 if i == 0 else 1.0)
					Art.fill_shaded(self, Art.ellipse(c, rr * 1.2, rr, r.randf_range(-0.4, 0.4), 9), Color("6a6458").darkened(r.randf_range(0.0, 0.25)), 0.18, 0.4, Art.OUTLINE, 1.3)
					DrawBatch.colored_polygon(self, Art.ellipse(c + Vector2(-rr * 0.3, rr * 0.4), rr * 0.5, rr * 0.2, 0.0, 8), Color(S.MOSS, 0.5))
				for i in 3:
					DrawBatch.line(self, Vector2(r.randf_range(0, w), -2), Vector2(r.randf_range(0, w), -r.randf_range(10.0, 20.0)), Color("2a2018"), 1.6)   # ענפים שבורים
			"fuel_drums":   # חביות דלק חלודות
				for i in 2:
					var bx := float(i) * w * 0.5 + 2.0
					var bw := w * 0.5 - 4.0
					var col: Color = [Color("8a3a1e"), Color("3a5a6a")][i]
					Art.fill_shaded(self, PackedVector2Array([Vector2(bx, 0), Vector2(bx + bw, 0), Vector2(bx + bw, -h), Vector2(bx, -h)]), col, 0.15, 0.35, Art.OUTLINE, 1.3)
					DrawBatch.line(self, Vector2(bx, -h * 0.33), Vector2(bx + bw, -h * 0.33), Color(0, 0, 0, 0.3), 2.0)
					DrawBatch.line(self, Vector2(bx, -h * 0.66), Vector2(bx + bw, -h * 0.66), Color(0, 0, 0, 0.3), 2.0)
					for q in 3:
						DrawBatch.circle(self, Vector2(bx + r.randf_range(4, bw - 4), -r.randf_range(4, h - 4)), r.randf_range(2.0, 4.0), Color("6a3a1a"))
			_:   # מטען שנפל מגג האוטובוס
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w * 0.45, 0), Vector2(w * 0.43, -h), Vector2(2, -h * 0.95)]), Color("c0306a"), 0.15, 0.35, Art.OUTLINE, 1.2)
				for q in 4:
					DrawBatch.line(self, Vector2(2, -h * (0.2 + 0.2 * float(q))), Vector2(w * 0.44, -h * (0.2 + 0.2 * float(q))), [Color("2a8a5a"), Color("e8c030"), Color("2a5aa0"), Color("f0f0f0")][q], 2.0)
				Art.fill_shaded(self, PackedVector2Array([Vector2(w * 0.48, 0), Vector2(w, 0), Vector2(w, -h * 0.7), Vector2(w * 0.48, -h * 0.7)]), Color("5a4030"), 0.15, 0.35, Art.OUTLINE, 1.2)
				DrawBatch.line(self, Vector2(w * 0.66, -h * 0.7), Vector2(w * 0.66, -h * 0.82), Color("2a2018"), 2.0)
				DrawBatch.line(self, Vector2(w * 0.82, -h * 0.7), Vector2(w * 0.82, -h * 0.82), Color("2a2018"), 2.0)
				DrawBatch.line(self, Vector2(w * 0.66, -h * 0.82), Vector2(w * 0.82, -h * 0.82), Color("2a2018"), 2.0)


# ---- טפטוף + גדות ערפל שעוברות (מסך) ----
class RoadFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _d := []
	var _fog := 0.0
	var _fog_t := 10.0

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 28
		for i in 70:
			_d.append(Vector3(r.randf_range(0, vp.x), r.randf_range(0, vp.y), r.randf_range(0.6, 1.4)))

	func _process(delta: float) -> void:
		_t += delta
		for i in _d.size():
			var e: Vector3 = _d[i]
			e.y += 420.0 * delta * e.z
			e.x -= 60.0 * delta * e.z
			if e.y > vp.y + 10.0:
				e.y = -10.0
				e.x = randf_range(0.0, vp.x + 60.0)
			e.x = fposmod(e.x, vp.x + 20.0) - 10.0
			_d[i] = e
		_fog_t -= delta   # מדי פעם ענן עולה מהעמק ועובר על הכביש
		if _fog_t <= 0.0:
			_fog_t = randf_range(16.0, 24.0)
			_fog = 7.0
		_fog = maxf(_fog - delta, 0.0)
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for e in _d:
			DrawBatch.line(self, Vector2(e.x, e.y), Vector2(e.x - 2.0 * e.z, e.y + 9.0 * e.z), Color(0.8, 0.85, 0.9, 0.28), 1.0)
		Kit.haze_band(self, vp, vp.y * 0.7, vp.y, Color(0.85, 0.86, 0.84, 0.08))   # אד מהעמק בתחתית (מעבר רך - היה מלבן עם קו חד)
		if _fog > 0.0:   # ענן: חלש יותר מבעבר (0.28) - הזומבים נעלמו בלבן
			var k := sin(clampf(_fog / 7.0, 0.0, 1.0) * PI)
			DrawBatch.rect(self, Rect2(Vector2.ZERO, vp), Color(0.86, 0.87, 0.85, 0.15 * k))
			for q in 6:
				Kit.soft_glow(self, Vector2(fposmod(float(q) * 260.0 + _t * 50.0, vp.x + 400.0) - 200.0, vp.y * 0.6 + sin(float(q) * 1.7) * 90.0), 300.0, Color(1, 1, 1, 0.22 * k), 0.3)
