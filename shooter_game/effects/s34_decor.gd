extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 34 ("OBSERVATORY") - מדבר אטקמה בצ'ילה בלילה: השמיים הכי צלולים בעולם.
#  שביל החלב עם ענני מגלן, מערך צלחות רדיו (כמו ALMA), כיפות מצפה על הפסגות שיורות קרני לייזר צהובות ("כוכב מנחה"),
#  קרום מלח סדוק. המדענים לא עזבו - הם רק הפסיקו לנשום.
#    atacama_sky   - (רקע) שמי לילה עמוקים, אלפי כוכבים, שביל החלב עם פסי אבק, ענני מגלן, כוכב נופל
#    far_andes     - (רקע) הרים כהים עם כיפות מצפה וקרני לייזר צהובות לשמיים
#    mid_array     - (רקע) מערך צלחות רדיו לבנות שמסתובבות לאט, אורות אדומים מהבהבים
#    near_desert   - (רקע) סלעים, עמודי מלח, קקטוסים מנורתיים
#    SaltGround    - (עולם) קרום מלח סדוק במשושים
#    Dome          - (עולם) כיפת מצפה עם מרפסת (הקומה = add_floor) ומשגר לייזר
#    GuideLaser    - (עולם, מלכודת, "hazards") קרן לייזר שסורקת את הקרקע: קו אדום מקווקו (אזהרה) -> קרן שורפת
#    Obstacle      - (מוצק + מחסה) "flight_cases" ארגזי ציוד / "rover" רכב מחקר הפוך / "solar_rack" פאנלים סולאריים
#    NightFX       - (מסך) כוכבים נופלים, אבק מלח
#  לשנות: GuideLaser.CYCLE / WARN_T / SWEEP_T / SPAN.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const SALT := Color("b8b4c0")
const SALT_D := Color("7a7686")
const LASER := Color(1.0, 0.82, 0.25)


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


# ---- השמיים הכי צלולים בעולם ----
static func atacama_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("03040c"), Color("070a1c"), Color("101834"), Color("1c2648")], 0.9)
	# שביל החלב: פס אלכסוני רך עם ליבה בהירה ופסי אבק כהים
	var a := Vector2(-100, v.y * 0.75)
	var b := Vector2(v.x + 100, v.y * 0.05)
	var dir := (b - a).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	for i in 14:
		var u := float(i) / 13.0
		var c := a.lerp(b, u)
		var core := exp(-pow((u - 0.55) * 3.0, 2.0))
		Kit.soft_ellipse(ci, c, 190.0, 80.0 + core * 40.0, dir.angle(), Color(0.75, 0.75, 0.95, 0.14 + core * 0.14))   # רך (היו אליפסות עם קצוות)
		Kit.soft_ellipse(ci, c + nrm * 6.0, 140.0, 30.0 + core * 18.0, dir.angle(), Color(1.0, 0.92, 0.8, 0.1 + core * 0.18))
		if i % 2 == 1:   # פסי אבק
			Kit.soft_ellipse(ci, c + nrm * (sin(float(i)) * 10.0), 110.0, 9.0, dir.angle() + 0.08, Color(0.02, 0.02, 0.06, 0.7))
	for i in 160:   # כוכבים
		var sx := _h(i, 1) * v.x
		var sy := _h(i, 2) * v.y * 0.8
		var tw := 0.5 + 0.5 * sin(t * (1.0 + _h(i, 3) * 3.0) + float(i))
		var sz := 0.7 + _h(i, 4) * 1.1
		DrawBatch.rect(ci, Rect2(sx, sy, sz, sz), Color(0.85 + _h(i, 5) * 0.15, 0.85, 1.0, 0.35 + 0.6 * tw * _h(i, 6)))
	DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(v.x * 0.16, v.y * 0.22), 40.0, 26.0, 0.4, 14), Color(0.8, 0.8, 1.0, 0.1))   # ענני מגלן
	DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(v.x * 0.24, v.y * 0.3), 22.0, 14.0, 0.2, 12), Color(0.8, 0.8, 1.0, 0.09))
	var cyc := fposmod(t, 9.0)   # כוכב נופל
	if cyc < 0.7:
		var s0 := Vector2(v.x * (0.3 + 0.4 * _h(floori(t / 9.0), 7)), v.y * 0.1)
		var p := s0 + Vector2(260.0, 110.0) * (cyc / 0.7)
		DrawBatch.line(ci, p, p - Vector2(60, 25), Color(1, 1, 1, 0.7 * (1.0 - cyc / 0.7)), 1.5)


# ---- הרים עם כיפות מצפה וקרני לייזר ----
static func far_andes(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pts := PackedVector2Array()
	var x := -20.0
	while x <= v.x + 20.0:
		var u := x + sc
		pts.append(Vector2(x, y - 40.0 - (_vn(u / 220.0, 3) * 0.6 + _vn(u / 90.0, 8) * 0.4) * 150.0))
		x += 20.0
	var poly := pts.duplicate()
	poly.append(Vector2(v.x + 20.0, v.y))
	poly.append(Vector2(-20.0, v.y))
	DrawBatch.colored_polygon(ci, poly, Color("0c1022"))
	DrawBatch.polyline(ci, pts, Color(0.5, 0.55, 0.75, 0.25), 1.2)   # אור ירח על הקו
	var period := 1300.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var dx := float(k) * period - sc + 300.0 + _h(k, 4) * 500.0
		if dx < -100.0 or dx > v.x + 100.0:
			continue
		var gi := clampi(int((dx + 20.0) / 20.0), 0, pts.size() - 1)
		var dy := pts[gi].y + 4.0
		DrawBatch.rect(ci, Rect2(dx - 9, dy - 10, 18, 10), Color("8a90a8"))   # כיפה קטנה
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(dx, dy - 10), 9.0, 8.0, 0.0, 10), Color("9aa0b8"))
		if k % 2 == 0:   # קרן לייזר כתומה-צהובה לשמיים
			var ang := -PI * 0.5 + sin(t * 0.07 + float(k)) * 0.35
			var tip := Vector2(dx, dy - 14) + Vector2.from_angle(ang) * 900.0
			DrawBatch.line(ci, Vector2(dx, dy - 14), tip, Color(1.0, 0.8, 0.3, 0.12), 6.0)
			DrawBatch.line(ci, Vector2(dx, dy - 14), tip, Color(1.0, 0.85, 0.4, 0.4), 1.4)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("0c1022"))


# ---- מערך צלחות רדיו ----
static func _dish(ci: CanvasItem, p: Vector2, s: float, ang: float, c: Color) -> void:
	DrawBatch.line(ci, p, p + Vector2(0, -16) * s, c.darkened(0.3), 3.0 * s)   # עמוד
	DrawBatch.rect(ci, Rect2(p + Vector2(-6, -2) * s, Vector2(12, 4) * s), c.darkened(0.4))
	var cen := p + Vector2(0, -20) * s
	var d := Vector2.from_angle(ang)
	var nrm := Vector2(-d.y, d.x)
	var rim := PackedVector2Array()
	for q in 9:   # צלחת (חצי אליפסה)
		var u := float(q) / 8.0 * PI
		rim.append(cen + nrm * cos(u) * 14.0 * s + d * (sin(u) * -5.0 * s))
	DrawBatch.colored_polygon(ci, rim, c)
	DrawBatch.line(ci, cen, cen + d * 12.0 * s, c.darkened(0.2), 1.2 * s)   # מקלט
	DrawBatch.circle(ci, cen + d * 12.0 * s, 1.5 * s, c.darkened(0.3))


static func mid_array(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	DrawBatch.rect(ci, Rect2(0, y - 6.0, v.x, v.y - y + 6.0), Color("1a1c2c"))
	var period := 160.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc + _h(k, 2) * 60.0
		var row := float(k % 3)
		var s := 1.4 - row * 0.25
		var ang := -PI * 0.5 - 0.6 + sin(t * 0.05 + float(k) * 0.3) * 0.25   # כולן מסתובבות יחד לאט
		_dish(ci, Vector2(x, y - row * 10.0), s, ang, Color(0.78, 0.8, 0.88).darkened(row * 0.15))
		if k % 5 == 0 and fposmod(t + float(k), 1.6) < 0.3:   # אור אדום מהבהב
			DrawBatch.circle(ci, Vector2(x, y - row * 10.0 - 22.0 * s), 1.8, Color(1, 0.2, 0.2))
	DrawBatch.line(ci, Vector2(0, y + 4.0), Vector2(v.x, y + 4.0), Color(0.3, 0.3, 0.4, 0.5), 1.0)   # הדרך


# ---- סלעים, עמודי מלח, קקטוסים מנורתיים ----
static func near_desert(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var r := _rng(k * 71 + 3)
		for i in 3:   # עמודי מלח
			var px := x + r.randf_range(0.0, period)
			var ph := r.randf_range(26.0, 60.0)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 10, y), Vector2(px - 5, y - ph), Vector2(px + 3, y - ph * 0.9), Vector2(px + 9, y)]), Color("3a3a4e"))
		var cx := x + r.randf_range(100.0, 600.0)   # קקטוס מנורתי
		DrawBatch.line(ci, Vector2(cx, y), Vector2(cx, y - 70), Color("1e2a26"), 7.0)
		for sgn in [-1.0, 1.0]:
			var ay := y - r.randf_range(30.0, 50.0)
			DrawBatch.line(ci, Vector2(cx, ay), Vector2(cx + sgn * 14.0, ay), Color("1e2a26"), 6.0)
			DrawBatch.line(ci, Vector2(cx + sgn * 14.0, ay), Vector2(cx + sgn * 14.0, ay - 22.0), Color("1e2a26"), 6.0)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("14141e"))


# ---- קרום מלח במשושים ----
class SaltGround extends Node2D:
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
		var S := preload("res://effects/s34_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("3a3846"))
		DrawBatch.rect(self, Rect2(0, 0, w, 10.0), S.SALT_D)
		var x := 0.0
		while x < w:   # משושי מלח בולטים
			var cw := r.randf_range(26.0, 44.0)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x + 2, 1), Vector2(x + cw - 2, 1), Vector2(x + cw - 6, -3), Vector2(x + 6, -3)]), S.SALT)
			DrawBatch.line(self, Vector2(x + cw, -2), Vector2(x + cw, 9), Color("4a4858"), 1.5)
			x += cw
		for i in int(w / 50.0):   # גבישים נוצצים
			var gx := r.randf_range(0.0, w)
			DrawBatch.rect(self, Rect2(gx, r.randf_range(-2.0, 6.0), 1.5, 1.5), Color(0.9, 0.95, 1.0, 0.7))
		for i in int(w / 120.0):
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(r.randf_range(0.0, w), r.randf_range(20.0, depth - 8.0)), r.randf_range(6.0, 12.0), r.randf_range(3.0, 5.0), 0.0, 8), Color("2e2c38"))


# ---- כיפת מצפה עם מרפסת ומשגר לייזר ----
class Dome extends Node2D:
	var w := 220.0
	var tier := 130.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w):
			queue_redraw()

	func laser_origin() -> Vector2:
		return global_position + Vector2(w * 0.5, -tier - w * 0.48)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var S := preload("res://effects/s34_decor.gd")
		var body := Color("8a8ea6")
		DrawBatch.rect(self, Rect2(0, -tier, w, tier), body.darkened(0.35))   # בניין גלילי
		for q in 3:
			DrawBatch.line(self, Vector2(0, -tier * (0.3 + 0.3 * float(q))), Vector2(w, -tier * (0.3 + 0.3 * float(q))), body.darkened(0.5), 1.5)
		DrawBatch.rect(self, Rect2(w * 0.4, -60, 34, 60), Color("1a1a24"))   # דלת
		DrawBatch.rect(self, Rect2(w * 0.4 + 6, -54, 8, 8), Color(1.0, 0.25, 0.2, 0.7))   # אור אדום (אסטרונומים)
		var cen := Vector2(w * 0.5, -tier)   # הכיפה
		var dome := PackedVector2Array()
		for q in 17:
			var a := PI + float(q) / 16.0 * PI
			dome.append(cen + Vector2(cos(a) * w * 0.5, sin(a) * w * 0.45))
		Art.fill_shaded(self, dome, body, 0.25, 0.4, Art.OUTLINE, 1.5)
		DrawBatch.colored_polygon(self, PackedVector2Array([cen + Vector2(-10, 0), cen + Vector2(10, 0), cen + Vector2(7, -w * 0.44), cen + Vector2(-7, -w * 0.44)]), Color("10121c"))   # חריץ פתוח
		DrawBatch.line(self, cen + Vector2(0, -6), cen + Vector2(18, -w * 0.38), Color("5a5e74"), 5.0)   # טלסקופ בפנים
		DrawBatch.circle(self, laser_origin() - global_position, 4.0, S.LASER.darkened(0.2))   # משגר לייזר
		Art.glow(self, laser_origin() - global_position, 14.0, Color(1.0, 0.8, 0.3, 0.2 + 0.1 * sin(_t * 3.0)))
		# מרפסת (הקומה)
		DrawBatch.rect(self, Rect2(-10, -tier, w + 20, 6), Color("4a4e60"))
		for q in int((w + 20.0) / 14.0):
			DrawBatch.line(self, Vector2(-10.0 + float(q) * 14.0, -tier), Vector2(-10.0 + float(q) * 14.0, -tier - 16.0), Color("5a5e70"), 1.5)
		DrawBatch.line(self, Vector2(-10, -tier - 16), Vector2(w + 10, -tier - 16), Color("6a6e80"), 2.0)


# ---- לייזר "כוכב מנחה" שסורק את הקרקע ----
class GuideLaser extends Node2D:
	const CYCLE := Vector2(6.0, 9.0)
	const WARN_T := 1.2
	const SWEEP_T := 1.3
	const SPAN := 420.0
	var origin := Vector2.ZERO        # (עולם) מאיפה יוצאת הקרן
	var x0 := 0.0                     # (עולם) תחילת הסריקה
	var state := 0                    # 0 = כבוי, 1 = אזהרה, 2 = סורק
	var sweeps := 0                   # לבדיקות
	var hits := 0
	var _t := 3.0
	var _dir := 1.0
	var _hit := false
	var _tick := 0.0

	func _ready() -> void:
		z_index = 8
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(Vector2(x0, global_position.y - 60.0), Vector2(SPAN, 60.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		if state == 0:
			return false
		return world_rect().grow(margin).has_point(p)

	func _target(k: float) -> Vector2:
		var a := x0 if _dir > 0.0 else x0 + SPAN
		return Vector2(a + _dir * SPAN * k, global_position.y)

	func _physics_process(delta: float) -> void:
		_t -= delta
		match state:
			0:
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					_dir = 1.0 if randf() < 0.5 else -1.0
					_hit = false
			1:
				if _t <= 0.0:
					state = 2
					_t = SWEEP_T
					sweeps += 1
					if Art.on_screen(self, Vector2(x0 + SPAN * 0.5, global_position.y), 300.0):
						preload("res://sfx.gd").play("o34_laser", Vector2(x0 + SPAN * 0.5, global_position.y), 0.0, 0.05, 2)
			2:
				var k := 1.0 - _t / SWEEP_T
				var tip := _target(k)
				_tick -= delta
				if _tick <= 0.0 and Art.on_screen(self, tip, 200.0):
					_tick = 0.05
					preload("res://particles.gd").burst(get_parent(), tip, "fire", Vector2.UP, 2)
				var pl := get_tree().get_first_node_in_group("player")
				if not _hit and pl != null and not pl.dead and _seg_hits(pl.body_rect(), origin, tip):
					_hit = true
					hits += 1
					pl.hurt(1, Vector2(_dir * 1.2, -0.8))
				for zz in get_tree().get_nodes_in_group("zombies"):
					if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - tip.x) < 14.0 and absf(zz.global_position.y - tip.y) < 20.0:
						zz.take_damage(12, zz.global_position + Vector2(0, -20), Vector2(_dir, 0), false, {"source": "laser", "fixed": 12})
				if _t <= 0.0:
					state = 0
					_t = randf_range(CYCLE.x, CYCLE.y)
		if Art.on_screen(self, Vector2(x0 + SPAN * 0.5, global_position.y), SPAN):
			queue_redraw()

	# הקרן חוצה את גוף השחקן? (דגימה לאורך הקטע)
	func _seg_hits(r: Rect2, a: Vector2, b: Vector2) -> bool:
		for q in 24:
			if r.has_point(a.lerp(b, 0.6 + 0.4 * float(q) / 23.0)):
				return true
		return false

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var o := origin - global_position
		if state == 1:   # אזהרה: קו אדום מקווקו לאורך האזור
			var a := Vector2(x0, global_position.y) - global_position
			var x := 0.0
			while x < SPAN:
				DrawBatch.line(self, a + Vector2(x, -2), a + Vector2(minf(x + 12.0, SPAN), -2), Color(1.0, 0.25, 0.2, 0.5 + 0.4 * sin(_t * 25.0)), 2.0)
				x += 22.0
			DrawBatch.line(self, o, _target(0.0) - global_position, Color(1.0, 0.3, 0.2, 0.25), 1.0)
		elif state == 2:
			var tip := _target(1.0 - _t / SWEEP_T) - global_position
			DrawBatch.line(self, o, tip, Color(1.0, 0.75, 0.2, 0.25), 9.0)
			DrawBatch.line(self, o, tip, Color(1.0, 0.9, 0.5, 0.9), 2.5)
			DrawBatch.circle(self, tip, 7.0, Color(1.0, 0.9, 0.5, 0.9))
			Art.glow(self, tip, 30.0, Color(1.0, 0.6, 0.2, 0.35))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "flight_cases"
	var size := Vector2(90, 40)
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
		var w := size.x
		var h := size.y
		match kind:
			"flight_cases":   # ארגזי ציוד שחורים עם פינות מתכת
				for q in 2:
					var bx := float(q) * w * 0.48
					var bh := h * (1.0 - 0.3 * float(q))
					Art.fill_shaded(self, PackedVector2Array([Vector2(bx + 2, 0), Vector2(bx + w * 0.5, 0), Vector2(bx + w * 0.5, -bh), Vector2(bx + 2, -bh)]), Color("2a2c34"), 0.15, 0.35, Art.OUTLINE, 1.3)
					for c in [Vector2(bx + 2, -bh), Vector2(bx + w * 0.5 - 6, -bh), Vector2(bx + 2, -6), Vector2(bx + w * 0.5 - 6, -6)]:
						DrawBatch.rect(self, Rect2(c, Vector2(6, 6)), Color("a0a4b0"))
					DrawBatch.rect(self, Rect2(bx + w * 0.2, -bh * 0.55, w * 0.12, 4), Color("e0c040"))
			"rover":   # רכב מחקר הפוך עם אנטנה
				Art.fill_shaded(self, PackedVector2Array([Vector2(4, 0), Vector2(w - 4, 0), Vector2(w - 10, -h * 0.75), Vector2(10, -h * 0.75)]), Color("d0d0c8"), 0.15, 0.35, Art.OUTLINE, 1.4)
				DrawBatch.rect(self, Rect2(w * 0.15, -h * 0.6, w * 0.35, h * 0.25), Color("2a3a5a"))
				DrawBatch.line(self, Vector2(w * 0.7, -h * 0.75), Vector2(w * 0.85, -h), Color("8a8a8a"), 2.0)
				DrawBatch.circle(self, Vector2(w * 0.85, -h), 3.0, Color(1, 0.3, 0.2))
				for wc in [Vector2(w * 0.2, -h * 0.78), Vector2(w * 0.8, -h * 0.78)]:
					DrawBatch.circle(self, wc, 7.0, Art.OUTLINE)
					DrawBatch.circle(self, wc, 5.5, Color("3a3a3a"))
			_:   # מתקן פאנלים סולאריים
				for q in 3:
					var px := float(q) * w / 3.0
					DrawBatch.line(self, Vector2(px + w / 6.0, 0), Vector2(px + w / 6.0, -h * 0.6), Color("6a6a70"), 2.0)
					Art.fill(self, PackedVector2Array([Vector2(px + 2, -h * 0.55), Vector2(px + w / 3.0 - 2, -h * 0.75), Vector2(px + w / 3.0 - 2, -h), Vector2(px + 2, -h * 0.8)]), Color("1e2e5a"), Art.OUTLINE, 1.0)
					DrawBatch.line(self, Vector2(px + 4, -h * 0.68), Vector2(px + w / 3.0 - 4, -h * 0.88), Color(0.6, 0.7, 1.0, 0.5), 1.0)


# ---- כוכבים נופלים + אבק מלח (מסך) ----
class NightFX extends Node2D:
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
		for i in 18:   # אבק מלח שעף ברוח
			var x := fposmod(float(i) * 151.0 + _t * (30.0 + float(i % 4) * 10.0), vp.x + 20.0) - 10.0
			var y := vp.y * 0.55 + fposmod(float(i) * 37.0, vp.y * 0.4) + sin(_t + float(i)) * 6.0
			DrawBatch.rect(self, Rect2(x, y, 1.5, 1.5), Color(0.8, 0.82, 0.95, 0.4))
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.1, 0.12, 0.3, 0.06))
