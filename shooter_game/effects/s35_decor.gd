extends RefCounted
# ============================================================
#  קישוטים לשלב 35 ("SKULL GLACIER") - קרחון אנדי גבוה (בהשראת הקרחונים של אקונקגואה):
#  שמש לבנה עם הילת קרח (טבעת 22 מעלות + "כלבי שמש"), פסגות מושלגות, חומת סרקים כחולה עם מערות קרח ומפל קפוא,
#  שדה פניטנטס (קוצי שלג גבוהים שנוטים לשמש). משלחת טיפוס שנעלמה - הם עדיין כאן, בתוך הקרח.
#    glacier_sky    - (רקע) שמיים קרים, שמש + הילה וכלבי שמש, ענני נוצה, "אבק יהלומים" נוצץ
#    far_peaks      - (רקע) פסגות מושלגות חדות עם צללים כחולים ולשון קרחון עם סדקים
#    mid_seracs     - (רקע) חומת סרקים כחולה, מערות קרח, מפל קפוא, גולגלת ענק כלואה בקרח
#    near_penitents - (רקע) שדה פניטנטס לבנים-כחולים, דגלי משלחת קרועים
#    GlacierGround  - (עולם) שלג על קרח כחול, גושי קרח שקועים
#    IceShelf       - (עולם) מדף קרח תלוי (הקומה = add_floor) עם עמוד קרח וסולם חבלים
#    Icicles        - (עולם, מלכודת, "hazards") נטיפי קרח ענקיים מתחת למדף: עוברים מתחת -> נסדקים (אזהרה) -> נופלים.
#                     גם ירייה בנטיף מפילה אותו - על הזומבים שמתחת!
#    GlareIce       - (עולם, מלכודת) משטח קרח חלק ומבריק: השחקן מחליק (player.slip_t)
#    Obstacle       - (מוצק + מחסה) "ice_cube" גוש קרח עם משהו קפוא בפנים / "sled" מזחלת משלחת / "old_tent" אוהל קרוע
#    GlacierFX      - (מסך) אבק יהלומים, שלג שנסחף ברוח, סנוור לבן
#  לשנות: Icicles.WARN_T / REGROW_T / DMG_Z, GlareIce.SLIP.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const SNOW := Color("eef4fa")
const SNOW_S := Color("b8cce0")
const ICE := Color("8ec8ec")
const ICE_D := Color("3a7aaa")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)


static func _vn(t: float, s: int) -> float:
	var i := floori(t)
	var f := t - float(i)
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_h(i, s), _h(i + 1, s), f)


# ---- שמיים קרים: שמש עם הילת קרח וכלבי שמש ----
static func glacier_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("2a5a9a"), Color("4a82c0"), Color("8ab8e0"), Color("d4e8f4")], 0.85)
	var sun := Vector2(v.x * 0.7, v.y * 0.2)
	Art.glow(ci, sun, 140.0, Color(1.0, 1.0, 1.0, 0.25))
	ci.draw_circle(sun, 22.0, Color(1.0, 1.0, 0.97))
	# הילת 22 מעלות: טבעת בהירה עם שוליים אדמדמים מבפנים
	ci.draw_arc(sun, 150.0, 0.0, TAU, 72, Color(1.0, 0.85, 0.8, 0.18), 6.0)
	ci.draw_arc(sun, 156.0, 0.0, TAU, 72, Color(1.0, 1.0, 1.0, 0.16), 5.0)
	for sgn in [-1.0, 1.0]:   # כלבי שמש
		var d := sun + Vector2(sgn * 156.0, 0.0)
		Art.glow(ci, d, 26.0, Color(1.0, 0.95, 0.85, 0.35 + 0.05 * sin(t * 0.7)))
		ci.draw_colored_polygon(Art.ellipse(d, 7.0, 4.0, 0.0, 10), Color(1.0, 0.98, 0.9, 0.8))
		ci.draw_line(d + Vector2(sgn * 6.0, 0), d + Vector2(sgn * 40.0, 0), Color(1, 1, 1, 0.2), 2.0)
	ci.draw_line(Vector2(0, sun.y), Vector2(v.x, sun.y), Color(1, 1, 1, 0.05), 3.0)   # מעגל פרהלי
	for i in 5:   # ענני נוצה
		var cx := fposmod(float(i) * 330.0 + t * 4.0, v.x + 400.0) - 200.0
		var cy := v.y * (0.08 + 0.07 * float(i % 3))
		ci.draw_colored_polygon(Art.ellipse(Vector2(cx, cy), 120.0, 6.0, -0.08, 12), Color(1, 1, 1, 0.18))
		ci.draw_colored_polygon(Art.ellipse(Vector2(cx + 40.0, cy + 8.0), 80.0, 4.0, -0.1, 10), Color(1, 1, 1, 0.12))
	for i in 40:   # אבק יהלומים
		var sx := fposmod(_h(i, 1) * v.x + t * (6.0 + _h(i, 2) * 8.0), v.x)
		var sy := _h(i, 3) * v.y * 0.7
		var tw := maxf(sin(t * (2.0 + _h(i, 4) * 3.0) + float(i) * 1.7), 0.0)
		if tw > 0.6:
			ci.draw_line(Vector2(sx - 2, sy), Vector2(sx + 2, sy), Color(1, 1, 1, tw * 0.7), 1.0)
			ci.draw_line(Vector2(sx, sy - 2), Vector2(sx, sy + 2), Color(1, 1, 1, tw * 0.7), 1.0)


# ---- פסגות מושלגות ----
static func far_peaks(ci: CanvasItem, sc: float, v: Vector2, y: float, _t: float) -> void:
	var pts := PackedVector2Array()
	var x := -30.0
	while x <= v.x + 30.0:
		var u := x + sc
		var hh := (_vn(u / 260.0, 5) * 0.55 + _vn(u / 70.0, 9) * 0.25 + absf(sin(u / 140.0)) * 0.2) * 260.0
		pts.append(Vector2(x, y - 60.0 - hh))
		x += 30.0
	var poly := pts.duplicate()
	poly.append(Vector2(v.x + 30.0, v.y))
	poly.append(Vector2(-30.0, v.y))
	ci.draw_colored_polygon(poly, Color("a8bcd4"))
	for i in pts.size() - 1:   # צד מוצל (כחול) לכל פסגה
		var a := pts[i]
		var b := pts[i + 1]
		if b.y > a.y:
			ci.draw_colored_polygon(PackedVector2Array([a, b, Vector2(b.x, b.y + 90.0), Vector2(a.x, a.y + 120.0)]), Color(0.4, 0.5, 0.72, 0.35))
	for i in pts.size():   # כיפות שלג בהירות
		if i > 0 and i < pts.size() - 1 and pts[i].y < pts[i - 1].y and pts[i].y < pts[i + 1].y:
			var p := pts[i]
			ci.draw_colored_polygon(PackedVector2Array([p, p + Vector2(28, 40), p + Vector2(12, 34), p + Vector2(-4, 48), p + Vector2(-22, 34)]), Color("f4f8fc"))
	ci.draw_polyline(pts, Color(1, 1, 1, 0.5), 1.4)
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("a8bcd4"))
	# לשון קרחון יורדת בין הפסגות
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var gx := float(k) * period - sc + 400.0 + _h(k, 3) * 400.0
		if gx < -200.0 or gx > v.x + 200.0:
			continue
		ci.draw_colored_polygon(PackedVector2Array([Vector2(gx - 20, y - 190), Vector2(gx + 20, y - 190), Vector2(gx + 110, y), Vector2(gx - 110, y)]), Color("cfe2f0"))
		for q in 5:
			var yy := y - 160.0 + float(q) * 32.0
			var hw := 20.0 + float(q + 1) * 18.0
			ci.draw_line(Vector2(gx - hw * 0.6, yy), Vector2(gx + hw * 0.5, yy + 6.0), Color(0.35, 0.55, 0.8, 0.5), 1.2)


# ---- חומת סרקים כחולה עם מערות, מפל קפוא וגולגלת כלואה ----
static func mid_seracs(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	ci.draw_rect(Rect2(0, y - 40.0, v.x, v.y - y + 40.0), Color("7aa6cc"))
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x0 := float(k) * period - sc
		var r := _rng(k * 53 + 11)
		var x := x0
		while x < x0 + period:   # עמודי סרקים (קוביות קרח ענקיות)
			var w := r.randf_range(50.0, 110.0)
			var h := r.randf_range(120.0, 230.0)
			var top := y - 40.0 - h
			var c := Color("8cbadf").lerp(Color("5a90c4"), r.randf())
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 4, top + 10), Vector2(x + w * 0.4, top), Vector2(x + w - 6, top + 14), Vector2(x + w, y)]), c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 4, top + 10), Vector2(x + w * 0.4, top), Vector2(x + w - 6, top + 14), Vector2(x + w * 0.4, top + 10)]), Color(0.95, 0.98, 1.0))   # שלג על הראש
			ci.draw_line(Vector2(x + w * 0.3, top + 20), Vector2(x + w * 0.35, y - 30), Color(1, 1, 1, 0.25), 2.0)   # ברק
			ci.draw_line(Vector2(x + w, top + 14), Vector2(x + w, y), Color(0.2, 0.4, 0.65, 0.5), 2.0)
			x += w - 4.0
		var cave := Vector2(x0 + r.randf_range(100.0, 700.0), y - 40.0)   # מערת קרח כחולה עמוקה (קשת על הקרקע)
		var arch := PackedVector2Array()
		var arch2 := PackedVector2Array()
		for q in 13:
			var a := PI + float(q) / 12.0 * PI
			arch.append(cave + Vector2(cos(a) * 38.0, sin(a) * 60.0))
			arch2.append(cave + Vector2(cos(a) * 24.0, sin(a) * 44.0))
		ci.draw_colored_polygon(arch, Color("2a5e94"))
		ci.draw_colored_polygon(arch2, Color("12345c"))
		ci.draw_polyline(arch, Color(0.85, 0.95, 1.0, 0.6), 2.0)
		if k % 2 == 0:   # גולגלת ענק כלואה בקרח (שם הקרחון)
			var sk := Vector2(x0 + r.randf_range(80.0, 820.0), y - 150.0)
			ci.draw_colored_polygon(Art.ellipse(sk, 30.0, 26.0, 0.0, 16), Color(0.85, 0.9, 0.95, 0.55))
			ci.draw_rect(Rect2(sk + Vector2(-16, 14), Vector2(32, 16)), Color(0.85, 0.9, 0.95, 0.55))
			for e in [-1.0, 1.0]:
				ci.draw_colored_polygon(Art.ellipse(sk + Vector2(e * 11.0, 2.0), 7.0, 8.0, 0.0, 10), Color(0.1, 0.2, 0.35, 0.7))
			ci.draw_colored_polygon(PackedVector2Array([sk + Vector2(-3, 14), sk + Vector2(3, 14), sk + Vector2(0, 8)]), Color(0.1, 0.2, 0.35, 0.7))
		else:   # מפל קפוא
			var fx := x0 + r.randf_range(150.0, 750.0)
			for q in 6:
				var xx := fx + float(q) * 7.0
				ci.draw_line(Vector2(xx, y - 200.0), Vector2(xx + sin(float(q)) * 3.0, y - 40.0), Color(0.88, 0.96, 1.0, 0.75), 5.0)
			ci.draw_colored_polygon(Art.ellipse(Vector2(fx + 18.0, y - 40.0), 34.0, 8.0, 0.0, 12), Color(0.9, 0.97, 1.0, 0.8))
			if fposmod(t + float(k), 3.0) < 0.15:
				ci.draw_circle(Vector2(fx + 12.0, y - 120.0), 2.0, Color(1, 1, 1, 0.9))


# ---- שדה פניטנטס ----
static func near_penitents(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 520.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x0 := float(k) * period - sc
		var r := _rng(k * 31 + 7)
		for i in 9:
			var px := x0 + r.randf_range(0.0, period)
			var ph := r.randf_range(40.0, 110.0)
			var pw := ph * r.randf_range(0.16, 0.24)
			var lean := ph * 0.12   # נוטים לכיוון השמש
			ci.draw_colored_polygon(PackedVector2Array([Vector2(px - pw, y), Vector2(px + lean, y - ph), Vector2(px + pw, y)]), Color("e8f0f8"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(px + lean, y - ph), Vector2(px + pw, y), Vector2(px + pw * 0.2, y)]), Color("9cb8d6"))
		if k % 3 == 0:   # דגל משלחת קרוע על מוט
			var fx := x0 + r.randf_range(60.0, 460.0)
			ci.draw_line(Vector2(fx, y), Vector2(fx, y - 90), Color("3a3a40"), 2.0)
			var wv := sin(t * 5.0 + float(k)) * 4.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(fx, y - 90), Vector2(fx + 30, y - 86 + wv), Vector2(fx + 24, y - 78 + wv), Vector2(fx + 30, y - 72 + wv), Vector2(fx, y - 74)]), Color("c03a2a"))
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("dce8f2"))


# ---- שלג על קרח כחול ----
class GlacierGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s35_decor.gd")
		draw_rect(Rect2(0, 0, w, depth), Color("5a8ab8"))
		for i in int(w / 70.0):   # שכבות קרח כחול
			var yy := r.randf_range(16.0, depth - 6.0)
			draw_line(Vector2(r.randf_range(0.0, w), yy), Vector2(r.randf_range(0.0, w), yy + r.randf_range(-3.0, 3.0)), Color(0.75, 0.88, 1.0, 0.35), 1.5)
		for i in int(w / 160.0):   # גושי קרח שקועים
			var c := Vector2(r.randf_range(0.0, w), r.randf_range(26.0, depth - 10.0))
			draw_colored_polygon(Art.ellipse(c, r.randf_range(10.0, 18.0), r.randf_range(6.0, 9.0), r.randf_range(-0.4, 0.4), 6), Color("3a6a9a"))
		draw_rect(Rect2(0, 0, w, 12.0), S.SNOW)   # שכבת שלג
		var x := 0.0
		while x < w:   # תלוליות שלג
			var cw := r.randf_range(30.0, 70.0)
			draw_colored_polygon(Art.ellipse(Vector2(x + cw * 0.5, 1.0), cw * 0.55, 4.0, 0.0, 10), S.SNOW)
			x += cw
		draw_line(Vector2(0, 12), Vector2(w, 12), S.SNOW_S, 2.0)
		for i in int(w / 40.0):   # נצנוצים
			draw_rect(Rect2(r.randf_range(0.0, w), r.randf_range(-3.0, 9.0), 1.5, 1.5), Color(1, 1, 1, 0.9))


# ---- מדף קרח תלוי (קומה עליונה) ----
class IceShelf extends Node2D:
	var w := 260.0
	var tier := 140.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s35_decor.gd")
		# עמוד קרח שתומך במדף (בצד ימין)
		var px := w - 40.0
		Art.fill_shaded(self, PackedVector2Array([Vector2(px - 18, 0), Vector2(px - 12, -tier), Vector2(px + 22, -tier), Vector2(px + 28, 0)]), Color("7ab4dc"), 0.2, 0.45, Art.OUTLINE, 1.2)
		draw_line(Vector2(px - 4, -tier + 10), Vector2(px - 2, -10), Color(1, 1, 1, 0.35), 2.0)
		# המדף עצמו: לוח קרח עבה עם שלג למעלה
		var slab := PackedVector2Array([Vector2(-14, -tier), Vector2(w + 14, -tier), Vector2(w + 6, -tier + 18), Vector2(w * 0.6, -tier + 24), Vector2(w * 0.3, -tier + 20), Vector2(-6, -tier + 16)])
		Art.fill_shaded(self, slab, S.ICE, 0.25, 0.4, Art.OUTLINE, 1.3)
		draw_rect(Rect2(-14, -tier - 4, w + 28, 6), S.SNOW)
		for q in int(w / 30.0):   # שלג תלוי מהשפה
			draw_colored_polygon(Art.ellipse(Vector2(-6.0 + float(q) * 30.0 + r.randf_range(0.0, 10.0), -tier - 3.0), 12.0, 4.0, 0.0, 8), S.SNOW)
		for q in 4:
			draw_line(Vector2(r.randf_range(0.0, w), -tier + 4), Vector2(r.randf_range(0.0, w), -tier + 14), Color(1, 1, 1, 0.35), 1.2)


# ---- נטיפי קרח ענקיים שנופלים ----
class Icicles extends Node2D:
	const WARN_T := 0.6
	const REGROW_T := 11.0
	const DMG_Z := 22
	const TRIG_R := 50.0
	var w := 200.0
	var drop := 120.0                 # מרחק הנפילה עד הקרקע
	var falls := 0                    # לבדיקות
	var hits := 0
	var zhits := 0
	var _ice := []                    # [x, len, state(0 תלוי / 1 נסדק / 2 נופל / 3 שבור), t, y, vy, hit, body]
	var _t := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		var r := RandomNumberGenerator.new()
		r.seed = int(global_position.x)
		var x := 12.0
		while x < w - 10.0:
			var ln := r.randf_range(26.0, 46.0)
			var b := Tip.new()
			b.owner_i = self
			b.idx = _ice.size()
			b.collision_layer = 4
			b.collision_mask = 0
			var cs := CollisionShape2D.new()
			var sh := RectangleShape2D.new()
			sh.size = Vector2(10, ln * 0.7)
			cs.shape = sh
			cs.position = Vector2(x, ln * 0.35)
			b.add_child(cs)
			add_child(b)
			_ice.append([x, ln, 0, 0.0, 0.0, 0.0, false, b])
			x += r.randf_range(22.0, 34.0)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, 0), Vector2(w, drop))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		for e in _ice:
			if int(e[2]) in [1, 2] and absf(global_position.x + float(e[0]) - p.x) < 20.0 + margin and p.y > global_position.y:
				return true
		return false

	func crack(i: int) -> void:
		var e: Array = _ice[i]
		if int(e[2]) != 0:
			return
		e[2] = 1
		e[3] = WARN_T
		Sfx.play("ic_crack", global_position + Vector2(float(e[0]), 0), -2.0, 0.15, 3)

	func shot(i: int) -> void:   # ירייה בנטיף = נופל מיד
		var e: Array = _ice[i]
		if int(e[2]) == 0 or int(e[2]) == 1:
			e[2] = 1
			e[3] = 0.0

	func _physics_process(delta: float) -> void:
		_t += delta
		var pl := get_tree().get_first_node_in_group("player")
		var near := false
		for i in _ice.size():
			var e: Array = _ice[i]
			match int(e[2]):
				0:
					if pl != null and not pl.dead and pl.global_position.y > global_position.y + 20.0 and absf(pl.global_position.x - (global_position.x + float(e[0]))) < TRIG_R:
						crack(i)
				1:
					near = true
					e[3] = float(e[3]) - delta
					if Engine.get_physics_frames() % 8 == 0:
						Particles.burst(get_parent(), global_position + Vector2(float(e[0]), 2), "snow", Vector2.DOWN, 1)
					if float(e[3]) <= 0.0:
						e[2] = 2
						e[4] = 0.0
						e[5] = 0.0
						e[6] = false
						(e[7] as CollisionObject2D).collision_layer = 0
						falls += 1
				2:
					near = true
					e[5] = float(e[5]) + 1700.0 * delta
					e[4] = float(e[4]) + float(e[5]) * delta
					var tip := global_position + Vector2(float(e[0]), float(e[4]) + float(e[1]))
					if not bool(e[6]) and pl != null and not pl.dead and pl.body_rect().grow(4.0).has_point(tip):
						e[6] = true
						hits += 1
						pl.hurt(1, Vector2(0.0, -0.5))
					if float(e[4]) + float(e[1]) >= drop:
						var at := global_position + Vector2(float(e[0]), drop)
						Sfx.play("ic_shatter", at, 0.0, 0.15, 3)
						Particles.burst(get_parent(), at, "spark", Vector2.UP, 8)
						Particles.burst(get_parent(), at, "snow", Vector2.UP, 6)
						for zz in get_tree().get_nodes_in_group("zombies"):
							if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - at.x) < 22.0 and absf(zz.global_position.y - at.y) < 30.0:
								zhits += 1
								zz.take_damage(DMG_Z, zz.global_position + Vector2(0, -40), Vector2(0, 1), false, {"source": "icicle", "fixed": DMG_Z})
						e[2] = 3
						e[3] = REGROW_T
				3:
					e[3] = float(e[3]) - delta
					if float(e[3]) <= 0.0:
						e[2] = 0
						(e[7] as CollisionObject2D).collision_layer = 4
		if (near or Engine.get_physics_frames() % 6 == 0) and Art.on_screen(self, global_position + Vector2(w * 0.5, drop * 0.5), w):
			queue_redraw()

	func _draw() -> void:
		for e in _ice:
			var x: float = e[0]
			var ln: float = e[1]
			var st: int = e[2]
			var y := 0.0
			var shake := 0.0
			var grow := 1.0
			if st == 1:
				shake = sin(_t * 70.0) * 1.5
			elif st == 2:
				y = e[4]
			elif st == 3:
				grow = clampf(1.0 - float(e[3]) / REGROW_T, 0.0, 1.0)
				if grow < 0.25:
					continue
			var l := ln * grow
			var p := PackedVector2Array([Vector2(x - 6 + shake, y), Vector2(x + 6 + shake, y), Vector2(x + 1 + shake, y + l), Vector2(x - 1 + shake, y + l)])
			draw_colored_polygon(p, Color(0.78, 0.92, 1.0, 0.92))
			draw_polyline(p + PackedVector2Array([p[0]]), Color(0.3, 0.5, 0.75, 0.8), 1.0)
			draw_line(Vector2(x - 2 + shake, y + 2), Vector2(x - 0.5 + shake, y + l * 0.8), Color(1, 1, 1, 0.7), 1.2)
			if st == 1:   # סדק בבסיס
				draw_line(Vector2(x - 6, y + 3), Vector2(x + 5, y + 6), Color(0.1, 0.2, 0.4), 1.4)

	class Tip extends StaticBody2D:   # גוף קטן לכל נטיף - קליע שפוגע בו מפיל אותו
		var owner_i = null
		var idx := 0

		func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
			if owner_i != null:
				owner_i.shot(idx)


# ---- קרח חלק ומבריק ----
class GlareIce extends Node2D:
	const SLIP := 0.15
	var w := 220.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _physics_process(delta: float) -> void:
		_t += delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.is_on_floor() and absf(pl.global_position.y - global_position.y) < 8.0 and pl.global_position.x > global_position.x and pl.global_position.x < global_position.x + w:
			pl.slip_t = SLIP
		if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w):
			queue_redraw()

	func _draw() -> void:
		var p := PackedVector2Array([Vector2(0, 1), Vector2(10, -3), Vector2(w - 10, -3), Vector2(w, 1), Vector2(w - 8, 5), Vector2(8, 5)])
		draw_colored_polygon(p, Color(0.55, 0.8, 1.0, 0.95))
		draw_polyline(p + PackedVector2Array([p[0]]), Color(0.3, 0.55, 0.85), 1.2)
		var sx := fposmod(_t * 90.0, w + 120.0) - 60.0   # ברק שזז
		if sx > 4.0 and sx < w - 14.0:
			draw_colored_polygon(PackedVector2Array([Vector2(sx, -3), Vector2(sx + 10, -3), Vector2(sx + 4, 5), Vector2(sx - 6, 5)]), Color(1, 1, 1, 0.75))
		for q in int(w / 40.0):
			draw_line(Vector2(14.0 + float(q) * 40.0, 0), Vector2(30.0 + float(q) * 40.0, 2), Color(1, 1, 1, 0.5), 1.0)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "ice_cube"
	var size := Vector2(70, 50)
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
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var w := size.x
		var h := size.y
		match kind:
			"ice_cube":   # גוש קרח שקוף עם משהו קפוא בפנים
				var p := PackedVector2Array([Vector2(2, 0), Vector2(0, -h + 6), Vector2(8, -h), Vector2(w - 4, -h + 3), Vector2(w, -6), Vector2(w - 6, 0)])
				draw_colored_polygon(p, Color(0.6, 0.82, 0.96, 0.9))
				match r.randi() % 3:
					0:   # גולגולת
						draw_colored_polygon(Art.ellipse(Vector2(w * 0.5, -h * 0.5), 9.0, 8.0, 0.3, 10), Color(0.85, 0.85, 0.78, 0.7))
						draw_circle(Vector2(w * 0.5 - 3, -h * 0.5), 2.0, Color(0.2, 0.25, 0.35, 0.8))
						draw_circle(Vector2(w * 0.5 + 3, -h * 0.5 - 1), 2.0, Color(0.2, 0.25, 0.35, 0.8))
					1:   # תרמיל אדום
						draw_rect(Rect2(w * 0.35, -h * 0.7, w * 0.3, h * 0.45), Color(0.65, 0.2, 0.15, 0.7))
					_:   # יד מושטת
						draw_line(Vector2(w * 0.3, -h * 0.25), Vector2(w * 0.6, -h * 0.6), Color(0.55, 0.6, 0.55, 0.7), 4.0)
						draw_circle(Vector2(w * 0.62, -h * 0.62), 3.5, Color(0.55, 0.6, 0.55, 0.7))
				draw_colored_polygon(PackedVector2Array([Vector2(8, -h + 4), Vector2(18, -h + 4), Vector2(10, -8), Vector2(4, -8)]), Color(1, 1, 1, 0.35))
				draw_polyline(p + PackedVector2Array([p[0]]), Color(0.25, 0.45, 0.7), 1.4)
				draw_rect(Rect2(4, -h - 3, w - 8, 5), Color("eef4fa"))
			"sled":   # מזחלת משלחת עם ארגזים וחבלים
				draw_line(Vector2(0, -2), Vector2(w, -2), Color("4a3a2a"), 3.0)
				draw_arc(Vector2(w - 4, -8), 6.0, -PI * 0.5, PI * 0.5, 6, Color("4a3a2a"), 3.0)
				Art.fill_shaded(self, PackedVector2Array([Vector2(6, -6), Vector2(w * 0.55, -6), Vector2(w * 0.55, -h), Vector2(6, -h)]), Color("7a5a3a"), 0.15, 0.35, Art.OUTLINE, 1.2)
				Art.fill_shaded(self, PackedVector2Array([Vector2(w * 0.55, -6), Vector2(w - 8, -6), Vector2(w - 8, -h * 0.65), Vector2(w * 0.55, -h * 0.65)]), Color("3a5a7a"), 0.15, 0.35, Art.OUTLINE, 1.2)
				draw_line(Vector2(6, -h * 0.5), Vector2(w - 8, -h * 0.4), Color("c8a060"), 1.5)
				draw_rect(Rect2(4, -h - 3, w * 0.55, 4), Color("eef4fa"))
			_:   # אוהל משלחת קרוע ומושלג
				var p := PackedVector2Array([Vector2(0, 0), Vector2(w * 0.45, -h), Vector2(w, 0)])
				Art.fill_shaded(self, p, Color("d06a2a"), 0.2, 0.4, Art.OUTLINE, 1.3)
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.45, -h), Vector2(w * 0.6, -h * 0.55), Vector2(w * 0.5, -h * 0.4), Vector2(w * 0.38, -h * 0.5)]), Color("2a2a30"))   # קרע
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.1, -h * 0.2), Vector2(w * 0.45, -h + 2), Vector2(w * 0.7, -h * 0.6), Vector2(w * 0.4, -h * 0.55)]), Color("eef4fa"))
				draw_line(Vector2(w * 0.45, -h), Vector2(w * 0.45, -h - 8), Color("6a6a70"), 2.0)


# ---- אבק יהלומים, שלג נסחף, סנוור (מסך) ----
class GlacierFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		for i in 26:   # שלג נסחף נמוך
			var x := fposmod(float(i) * 97.0 - _t * (70.0 + float(i % 5) * 20.0), vp.x + 40.0) - 20.0
			var y := vp.y * 0.72 + fposmod(float(i) * 41.0, vp.y * 0.2) + sin(_t * 2.0 + float(i)) * 5.0
			draw_line(Vector2(x, y), Vector2(x + 8.0, y - 1.0), Color(1, 1, 1, 0.45), 1.5)
		for i in 22:   # אבק יהלומים נוצץ
			var x := fposmod(float(i) * 173.0 + _t * 12.0, vp.x)
			var y := fposmod(float(i) * 61.0 + _t * 9.0, vp.y * 0.8)
			var tw := maxf(sin(_t * 3.0 + float(i) * 2.3), 0.0)
			draw_rect(Rect2(x, y, 1.5, 1.5), Color(1, 1, 1, 0.3 + 0.6 * tw))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(1.0, 1.0, 1.0, 0.04))
