extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 33 ("SULFUR CRATER") - מכרה גופרית על הר געש פעיל באנדים (בהשראת אאוקנקילצ'ה, המכרה הגבוה בעולם).
#  לילה, ענן אפר אדום מעל המכתש, ברקים בתוך הענן, להבות גופרית כחולות, גושי גופרית צהובה, מחנה כורים נטוש,
#  רכבל עם דליים חלודים. לכאן ברח SUPAY.
#    volcano_sky    - (רקע) לילה עם זוהר אדום על העננים, ברקים בתוך תמרת האפר
#    far_cones      - (רקע) חרוטי הרי געש, אחד מתפרץ (תמרה + זרמי לבה)
#    mid_camp       - (רקע) המדרון: מגדלי רכבל עם דליים זזים, בקתות אבן, נחלי לבה זוהרים, להבות כחולות
#    near_rocks     - (רקע) סלעי לבה שחורים, קרום גופרית, אדים
#    VolcGround     - (עולם) סלע געשי שחור, כתמי גופרית, סדקים זוהרים
#    LavaPit        - (עולם, מלכודת) בור לבה (יורש SpikePit משלב 21: נשרפים ונזרקים החוצה)
#    Vent           - (עולם, מלכודת, "hazards") פומרולה: מחזור של להבת גופרית כחולה (ON_T/OFF_T) + ענן גז צהוב
#    Shelter        - (עולם, קבוצה "shelters") בקתת אבן - מחסה מגל האפר. inside(pos)
#    Hopper         - (עולם) מגדל עץ למיון גופרית עם רציף עליון (הקומה = add_floor)
#    Obstacle       - (מוצק + מחסה) "sulfur_sacks" שקי גופרית / "slag_cart" עגלת סיגים / "lava_rocks" סלעי לבה
#    Volcano        - (קבוצה "volcano") ההר: CALM -> WARN (רעידות, "TAKE COVER!") -> SURGE (גל אפר לוהט: נזק לכל מי שלא במחסה)
#    AshFX          - (מסך) אפר נופל, זוהר אדום, גל האפר עצמו
#  לשנות: Volcano.CALM_T / WARN_T / SURGE_T / TICK, Vent.ON_T / OFF_T, Shelter.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const BASALT := Color("2a2626")
const BASALT_L := Color("3e3836")
const SULFUR := Color("e0c830")
const LAVA := Color("ff6a1a")
const BLUE := Color(0.35, 0.65, 1.0)


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


static func volcano() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("volcano") if tree != null else null


static func heat() -> float:   # 0..1 - כמה ההר "רותח" (לזוהר ברקע)
	var v: Node = volcano()
	return 0.0 if v == null else v.heat()


# ---- לילה עם זוהר אדום וברקים בתמרה ----
static func volcano_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	var hh := heat()
	Kit.gradient_sky(ci, v, [Color("0a0608"), Color("1e0e10"), Color("3a1612").lerp(Color("6a2010"), hh), Color("5a2414").lerp(Color("9a3a14"), hh)], 0.8)
	for i in 30:   # כוכבים חלשים בין האפר
		DrawBatch.circle(ci, Vector2(fposmod(float(i) * 211.0, v.x), fposmod(float(i) * 67.0, v.y * 0.35)), 0.9, Color(1, 0.9, 0.85, 0.25))
	for i in 5:   # ענני אפר מוארים מלמטה
		var y := v.y * (0.1 + 0.08 * float(i))
		var x := fposmod(t * (4.0 + float(i)) + float(i) * 350.0, v.x + 900.0) - 450.0
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(x, y), 280.0, 34.0, 0.0, 16), Color(0.2, 0.08, 0.06, 0.6))
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(x, y + 14.0), 240.0, 12.0, 0.0, 14), Color(1.0, 0.35, 0.1, 0.08 + 0.1 * hh))
	if Kit.lightning(ci, v, t, 6.5, 33):   # ברק בתוך הענן (Kit מצייר)
		pass


# ---- חרוטי הרי געש, אחד מתפרץ ----
static func far_cones(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var hh := heat()
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var r := _rng(k * 61 + 7)
		for c in 2:
			var cx := x + r.randf_range(200.0, 1300.0)
			var ch := r.randf_range(200.0, 300.0)
			var cw := ch * 1.6
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - cw, y), Vector2(cx - 30, y - ch), Vector2(cx + 30, y - ch), Vector2(cx + cw, y)]), Color("1e1416"))
			if c == 0 and k % 2 == 0:   # מתפרץ: תמרה + זרמי לבה
				for q in 6:
					var pk := fposmod(t * 0.3 + float(q) / 6.0, 1.0)
					DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx + sin(float(q) * 2.0) * 30.0 + pk * 60.0, y - ch - 20.0 - pk * 160.0), 30.0 + pk * 60.0, 20.0 + pk * 30.0, 0.0, 12), Color(0.18, 0.1, 0.1, 0.5 * (1.0 - pk)))
				Art.glow(ci, Vector2(cx, y - ch), 80.0, Color(1.0, 0.4, 0.1, 0.25 + 0.2 * hh))
				for q in 3:   # זרמי לבה מתפתלים במורד
					var lp := PackedVector2Array()
					var len_k := 0.45 + 0.25 * float(q % 2)
					for s in 9:
						var u := float(s) / 8.0 * len_k
						var side := float(q - 1) * (0.35 + u * 0.9)
						lp.append(Vector2(cx + side * ch * u * 1.4 + sin(u * 14.0 + float(q) * 2.0) * 6.0, y - ch + 4.0 + u * ch))
					DrawBatch.polyline(ci, lp, Color(1.0, 0.35, 0.08, 0.3), 5.0)
					DrawBatch.polyline(ci, lp, Color(1.0, 0.6, 0.2, 0.85), 1.6)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("1e1416"))


# ---- המדרון: מגדלי רכבל + דליים, בקתות, נחלי לבה, להבות כחולות ----
static func mid_camp(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pts := PackedVector2Array()
	var x := -20.0
	while x <= v.x + 20.0:
		var u := x + sc
		pts.append(Vector2(x, y - 50.0 - _vn(u / 300.0, 3) * 70.0))
		x += 20.0
	var poly := pts.duplicate()
	poly.append(Vector2(v.x + 20.0, v.y))
	poly.append(Vector2(-20.0, v.y))
	DrawBatch.colored_polygon(ci, poly, Color("2a1e1c"))
	var period := 1100.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x0 := float(k) * period - sc
		var r := _rng(k * 97 + 3)
		for q in 2:   # נחל לבה זוהר במורד
			var lx := x0 + r.randf_range(100.0, 1000.0)
			var lp := PackedVector2Array()
			for s in 6:
				lp.append(Vector2(lx + sin(float(s) * 1.3 + float(k)) * 14.0 + float(s) * 8.0, y - 110.0 + float(s) * 22.0))
			DrawBatch.polyline(ci, lp, Color(1.0, 0.4, 0.1, 0.35), 6.0)
			DrawBatch.polyline(ci, lp, Color(1.0, 0.75, 0.3, 0.8), 2.0)
		var hx := x0 + r.randf_range(50.0, 900.0)   # בקתת אבן
		DrawBatch.rect(ci, Rect2(hx, y - 46, 60, 36), Color("3a302c"))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(hx - 6, y - 46), Vector2(hx + 30, y - 62), Vector2(hx + 66, y - 46)]), Color("2a2220"))
		DrawBatch.rect(ci, Rect2(hx + 22, y - 34, 14, 24), Color(1.0, 0.6, 0.25, 0.5))
		for q in 3:   # להבות גופרית כחולות קטנות
			var bx := x0 + r.randf_range(0.0, period)
			var fh := 6.0 + sin(t * 9.0 + bx) * 3.0
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx - 4, y - 20), Vector2(bx, y - 20 - fh), Vector2(bx + 4, y - 20)]), Color(0.4, 0.7, 1.0, 0.85))
			Art.glow(ci, Vector2(bx, y - 22), 14.0, Color(0.4, 0.7, 1.0, 0.2))
	# רכבל: מגדלים + כבל + דליים שזזים
	var tp := 700.0
	var t0 := int(floor(sc / tp)) - 1
	var prev := Vector2.ZERO
	for k in range(t0, t0 + int(ceil(v.x / tp)) + 3):
		var tx := float(k) * tp - sc
		var top := Vector2(tx, y - 190.0 - _h(k, 5) * 40.0)
		DrawBatch.line(ci, Vector2(tx - 14, y - 40), top, Color("4a2e22"), 3.0)
		DrawBatch.line(ci, Vector2(tx + 14, y - 40), top, Color("4a2e22"), 3.0)
		DrawBatch.line(ci, top + Vector2(-16, 0), top + Vector2(16, 0), Color("4a2e22"), 3.0)
		if k > t0:
			DrawBatch.line(ci, prev, top, Color(0.15, 0.12, 0.12), 1.5)
			var bu := fposmod(t * 0.05 + float(k) * 0.37, 1.0)   # דלי
			var bp := prev.lerp(top, bu) + Vector2(0, 4.0 + sin(bu * PI) * 18.0)
			DrawBatch.line(ci, bp + Vector2(0, -4), bp + Vector2(0, 4), Color("2a2020"), 1.0)
			DrawBatch.rect(ci, Rect2(bp + Vector2(-7, 4), Vector2(14, 10)), Color("5a3a2a"))
			DrawBatch.rect(ci, Rect2(bp + Vector2(-6, 4), Vector2(12, 3)), Color(0.88, 0.78, 0.2))
		prev = top


# ---- סלעי לבה, קרום גופרית, אדים ----
static func near_rocks(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var r := _rng(k * 43 + 9)
		for i in 5:
			var rx := x + r.randf_range(0.0, period)
			var rw := r.randf_range(30.0, 70.0)
			var rh := r.randf_range(20.0, 50.0)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(rx, y), Vector2(rx + rw * 0.2, y - rh), Vector2(rx + rw * 0.7, y - rh * 0.85), Vector2(rx + rw, y)]), Color("1a1414"))
			if i % 2 == 0:
				DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(rx + rw * 0.45, y - rh * 0.85), rw * 0.25, 4.0, 0.0, 10), Color(0.85, 0.75, 0.2, 0.7))
		var sx := x + r.randf_range(100.0, 600.0)   # אדים עולים
		for q in 4:
			var pk := fposmod(t * 0.4 + float(q) * 0.25, 1.0)
			DrawBatch.circle(ci, Vector2(sx + sin(pk * 5.0) * 10.0, y - 10.0 - pk * 90.0), 8.0 + pk * 16.0, Color(0.9, 0.9, 0.8, 0.12 * (1.0 - pk)))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("140e0e"))


# ---- סלע געשי ----
class VolcGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 10 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w * 0.5 + 100.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s33_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("1a1616"))
		DrawBatch.rect(self, Rect2(0, 0, w, 9.0), S.BASALT_L)
		for i in int(w / 30.0):   # אבנים חדות
			var px := r.randf_range(0.0, w)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(px - 6, 2), Vector2(px - 2, -3), Vector2(px + 4, -2), Vector2(px + 7, 2)]), S.BASALT)
		for i in int(w / 160.0):   # כתמי גופרית
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(r.randf_range(0.0, w), 2.0), r.randf_range(14.0, 30.0), 3.0, 0.0, 10), Color(0.85, 0.75, 0.2, 0.85))
		var glow := 0.5 + 0.3 * sin(_t * 2.0)
		for i in int(w / 220.0):   # סדקים זוהרים
			var cx := r.randf_range(20.0, w - 40.0)
			var pts := PackedVector2Array([Vector2(cx, 9), Vector2(cx + 8, 20), Vector2(cx + 3, 34), Vector2(cx + 12, 50)])
			DrawBatch.polyline(self, pts, Color(1.0, 0.4, 0.1, 0.4 * glow), 4.0)
			DrawBatch.polyline(self, pts, Color(1.0, 0.7, 0.3, glow), 1.5)


# ---- בור לבה (יורש את בור היתדות של שלב 21: נשרפים ונזרקים) ----
class LavaPit extends "res://effects/s21_decor.gd".SpikePit:
	var _t := 0.0
	var _bub := 0.0

	func _ready() -> void:
		super._ready()
		zombie_burn = 2.0

	func _process(delta: float) -> void:
		_t += delta
		_bub -= delta
		if Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w):
			if Engine.get_process_frames() % 3 == 0:
				queue_redraw()
			if _bub <= 0.0:
				_bub = randf_range(0.3, 0.7)
				Particles.burst(get_parent(), global_position + Vector2(randf_range(8.0, w - 8.0), depth - 20.0), "fire", Vector2.UP, 3)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var S := preload("res://effects/s33_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth + 30.0), Color("1a0a06"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(9, 0), Vector2(5, depth), Vector2(0, depth)]), S.BASALT)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w, 0), Vector2(w - 9, 0), Vector2(w - 5, depth), Vector2(w, depth)]), S.BASALT)
		var ly := depth - 24.0
		var pts := PackedVector2Array([Vector2(4, depth + 30.0)])
		for q in 9:
			var x := 4.0 + float(q) * (w - 8.0) / 8.0
			pts.append(Vector2(x, ly + sin(_t * 2.5 + float(q)) * 2.5))
		pts.append(Vector2(w - 4, depth + 30.0))
		DrawBatch.colored_polygon(self, pts, S.LAVA)
		for q in 4:   # קרום ונקודות בהירות
			var bx := fposmod(float(q) * 23.0 + _t * 6.0, w - 16.0) + 8.0
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(bx, ly + 6.0), 7.0, 2.0, 0.0, 8), Color("7a1a08"))
			DrawBatch.circle(self, Vector2(fposmod(float(q) * 37.0 + _t * 10.0, w - 12.0) + 6.0, ly + 3.0), 2.0, Color(1.0, 0.9, 0.5))
		Art.glow(self, Vector2(w * 0.5, ly), w * 0.8, Color(1.0, 0.45, 0.1, 0.25))


# ---- פומרולה: להבת גופרית כחולה במחזור + ענן גז ----
class Vent extends "res://environment/hazard.gd":
	const ON_T := 2.4
	const OFF_T := 3.0
	const WARN := 0.7
	var phase := 0.0
	var burns := 0               # לבדיקות
	var _t := 0.0
	var _puff := 0.0

	func _ready() -> void:
		super._ready()
		z_index = 3
		rect = Rect2(-18, -70, 36, 70)
		player_damage = 1
		zombie_damage = 6
		zombie_burn = 1.5
		tick = 0.45
		story_kind = "fire"
		_t = phase

	func is_on() -> bool:
		return fposmod(_t, ON_T + OFF_T) < ON_T

	func warning() -> bool:
		var k := fposmod(_t, ON_T + OFF_T)
		return k > ON_T + OFF_T - WARN

	func _hazard_tick(delta: float) -> void:
		var was := active
		_t += delta
		active = is_on()
		if active and not was:
			burns += 1
			if Art.on_screen(self, global_position):
				Sfx.play("v33_whoosh", global_position, -2.0, 0.15, 3)
		_puff -= delta
		if _puff <= 0.0 and Art.on_screen(self, global_position):
			_puff = 0.18 if active else 0.5
			Particles.burst(get_parent(), global_position + Vector2(randf_range(-8, 8), -10.0), "smoke" if not active else "spark", Vector2.UP, 1 if not active else 2)
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var S := preload("res://effects/s33_decor.gd")
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-22, 0), Vector2(-10, -10), Vector2(10, -10), Vector2(22, 0)]), Color("3a3020"))   # פתח עם קרום גופרית
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -9), 12.0, 3.5, 0.0, 10), S.SULFUR)
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -9), 6.0, 2.0, 0.0, 8), Color("1a1206"))
		if active:   # להבה כחולה
			for q in 3:
				var hh := 50.0 + float(q) * 8.0 + sin(_t * 18.0 + float(q)) * 8.0
				var ww := 14.0 - float(q) * 3.5
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-ww, -8), Vector2(sin(_t * 9.0 + float(q)) * 4.0, -8.0 - hh), Vector2(ww, -8)]), Color(0.3 + float(q) * 0.2, 0.6 + float(q) * 0.13, 1.0, 0.55 + float(q) * 0.15))
			Art.glow(self, Vector2(0, -36), 60.0, Color(0.35, 0.65, 1.0, 0.22))
		elif warning():   # אזהרה: מבעבע
			DrawBatch.circle(self, Vector2(0, -12), 5.0 + sin(_t * 30.0) * 2.0, Color(0.5, 0.75, 1.0, 0.6))
		var gk := 0.25 if active else 0.12   # ענן גז צהבהב
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -40), 34.0, 30.0, 0.0, 14), Color(0.85, 0.8, 0.3, gk * 0.5))


# ---- בקתת אבן - מחסה מגל האפר ----
class Shelter extends Node2D:
	var w := 110.0
	var h := 96.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -1
		add_to_group("shelters")

	func inside(p: Vector2) -> bool:
		return p.x > global_position.x + 8.0 and p.x < global_position.x + w - 8.0 and p.y > global_position.y - h and p.y < global_position.y + 6.0

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s33_decor.gd")
		var v: Node = S.volcano()
		var warn: bool = v != null and v.state > 0
		DrawBatch.rect(self, Rect2(-6, -h, w + 12, h), Color("3a302c"))   # קיר אחורי
		var y := 0.0
		while y > -h + 4.0:   # אבנים
			var x := -6.0 + r.randf_range(0.0, 10.0)
			while x < w + 4.0:
				var bw := r.randf_range(16.0, 26.0)
				DrawBatch.rect(self, Rect2(x, y - 12.0, bw - 2.0, 10.0), Color("4a3e38").darkened(r.randf_range(0.0, 0.25)))
				x += bw
			y -= 12.0
		DrawBatch.rect(self, Rect2(10, -h + 22, w - 20, h - 22), Color(0.08, 0.06, 0.06, 0.85))   # הפנים (חשוך)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-16, -h + 4), Vector2(w * 0.5, -h - 26), Vector2(w + 16, -h + 4), Vector2(w + 10, -h + 12), Vector2(-10, -h + 12)]), Color("2a2220"))   # גג אבן
		var c := Color(0.5, 1.0, 0.5) if warn else Color(0.9, 0.85, 0.6)   # שלט "REFUGIO"
		DrawBatch.rect(self, Rect2(w * 0.5 - 30, -h - 4, 60, 14), Color(0.1, 0.08, 0.06))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w * 0.5 - 26, -h + 7), "REFUGIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c)
		if warn:
			Art.glow(self, Vector2(w * 0.5, -h * 0.5), w * 0.7, Color(0.4, 1.0, 0.4, 0.12))


# ---- מגדל עץ למיון גופרית עם רציף עליון ----
class Hopper extends Node2D:
	var w := 260.0
	var tier := 140.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var S := preload("res://effects/s33_decor.gd")
		for x in [10.0, w * 0.5, w - 10.0]:   # רגליים
			DrawBatch.line(self, Vector2(x, 0), Vector2(x, -tier), Color("4a3424"), 6.0)
		for q in 2:   # הצלבות
			DrawBatch.line(self, Vector2(10, -float(q) * tier * 0.5), Vector2(w * 0.5, -float(q + 1) * tier * 0.5), Color("3a2818"), 3.0)
			DrawBatch.line(self, Vector2(w - 10, -float(q) * tier * 0.5), Vector2(w * 0.5, -float(q + 1) * tier * 0.5), Color("3a2818"), 3.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w * 0.25, -tier + 10), Vector2(w * 0.75, -tier + 10), Vector2(w * 0.58, -tier * 0.45), Vector2(w * 0.42, -tier * 0.45)]), Color("5a4030"))   # משפך
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w * 0.3, -tier + 14), Vector2(w * 0.7, -tier + 14), Vector2(w * 0.55, -tier * 0.55), Vector2(w * 0.45, -tier * 0.55)]), S.SULFUR.darkened(0.15))
		DrawBatch.rect(self, Rect2(-6, -tier, w + 12, 10), Color("6a4a30"))   # הרציף
		for q in int(w / 30.0):
			DrawBatch.line(self, Vector2(float(q) * 30.0, -tier), Vector2(float(q) * 30.0, -tier - 20.0), Color("5a3a24"), 2.0)
		DrawBatch.line(self, Vector2(-6, -tier - 20), Vector2(w + 6, -tier - 20), Color("5a3a24"), 2.0)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "sulfur_sacks"
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
		var S := preload("res://effects/s33_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"sulfur_sacks":   # שקי יוטה מלאים גופרית
				for row in 2:
					var n := 3 - row
					for q in n:
						var c := Vector2(w * (0.5 - 0.17 * float(n - 1) + 0.34 * float(q)), -h * (0.25 + 0.5 * float(row)))
						Art.fill_shaded(self, Art.ellipse(c, w * 0.19, h * 0.27, 0.0, 12), Color("a08a5a").darkened(r.randf_range(0.0, 0.15)), 0.15, 0.35, Art.OUTLINE, 1.2)
						DrawBatch.colored_polygon(self, Art.ellipse(c + Vector2(0, -h * 0.2), w * 0.1, h * 0.06, 0.0, 8), S.SULFUR)
			"slag_cart":   # עגלת סיגים חלודה
				Art.fill_shaded(self, PackedVector2Array([Vector2(4, -8), Vector2(w - 4, -8), Vector2(w, -h), Vector2(0, -h)]), Color("5a3a2a"), 0.12, 0.35, Art.OUTLINE, 1.5)
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -h), w * 0.45, 6.0, 0.0, 12), S.SULFUR.darkened(0.1))
				for q in 4:
					DrawBatch.circle(self, Vector2(r.randf_range(8.0, w - 8.0), -h - 2.0), r.randf_range(3.0, 6.0), S.SULFUR)
				for wc in [Vector2(14, -4), Vector2(w - 14, -4)]:
					DrawBatch.circle(self, wc, 6.0, Art.OUTLINE)
					DrawBatch.circle(self, wc, 4.5, Color("3a3232"))
			_:   # סלעי לבה
				for i in 3:
					var c := Vector2(w * (0.25 + 0.25 * float(i)), -h * (0.35 if i != 1 else 0.6))
					Art.fill_shaded(self, Art.ellipse(c, w * 0.22, h * (0.35 if i != 1 else 0.42), r.randf_range(-0.3, 0.3), 9), S.BASALT_L, 0.15, 0.45, Art.OUTLINE, 1.3)
					DrawBatch.line(self, c + Vector2(-4, -2), c + Vector2(4, 3), Color(1.0, 0.45, 0.1, 0.8), 1.5)


# ============================================================
#  ההר: CALM -> WARN ("TAKE COVER!") -> SURGE (גל אפר לוהט). במחסה (Shelter.inside) - בטוח.
# ============================================================
class Volcano extends Node:
	const CALM_T := Vector2(20.0, 26.0)
	const WARN_T := 4.0
	const SURGE_T := 3.0
	const TICK := 0.5
	var state := 0               # 0 רגוע, 1 אזהרה, 2 גל
	var surges := 0              # לבדיקות
	var hits := 0
	var _t := 14.0
	var _tick := 0.0
	var enabled := true

	func _ready() -> void:
		add_to_group("volcano")

	func heat() -> float:
		match state:
			1:
				return clampf(1.0 - _t / WARN_T, 0.0, 1.0)
			2:
				return 1.0
		return 0.0

	func sheltered(p: Vector2) -> bool:
		for s in get_tree().get_nodes_in_group("shelters"):
			if s.inside(p):
				return true
		return false

	func nearest_shelter(x: float) -> Node:
		var best: Node = null
		var bd := INF
		for s in get_tree().get_nodes_in_group("shelters"):
			var d := absf(s.global_position.x + float(s.w) * 0.5 - x)
			if d < bd:
				bd = d
				best = s
		return best

	func _physics_process(delta: float) -> void:
		if not enabled:
			return
		_t -= delta
		match state:
			0:
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					Sfx.play("v33_rumble", null, 4.0, 0.0, 1)
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and pl.has_method("_say"):
						pl._say("THE MOUNTAIN ROARS - GET TO A REFUGIO!", Color("ffb060"))
					get_tree().call_group("shelters", "queue_redraw")
			1:
				if Engine.get_physics_frames() % 15 == 0:   # "למדו": הזומבים רצים למחסה
					for z in get_tree().get_nodes_in_group("zombies"):
						if z.dead or z.is_boss() or (z.type_mod != null and z.type_mod.has_method("ash_proof")):
							continue
						var pl := get_tree().get_first_node_in_group("player")
						if pl != null and not pl.dead and pl.global_position.distance_to(z.global_position) < 90.0:
							z.goal_x = INF   # אתה לידו - נלחם (גם בתוך המחסה)
							continue
						var sh := nearest_shelter(z.global_position.x)
						if sh != null and absf(sh.global_position.x + float(sh.w) * 0.5 - z.global_position.x) < 700.0:
							z.goal_x = sh.global_position.x + 20.0 + float(z.get_instance_id() % 7) * (float(sh.w) - 40.0) / 6.0
				var cam := get_viewport().get_camera_2d()
				if cam != null and cam.has_method("shake") and Engine.get_physics_frames() % 20 == 0:
					cam.shake(3.0 + 6.0 * heat(), 0.3)
				if _t <= 0.0:
					state = 2
					_t = SURGE_T
					surges += 1
					_tick = 0.2
					Sfx.play("v33_surge", null, 6.0, 0.0, 1)
			2:
				if Engine.get_physics_frames() % 15 == 0:   # במחסה ליד השחקן: נלחמים
					var pp := get_tree().get_first_node_in_group("player")
					for z in get_tree().get_nodes_in_group("zombies"):
						if z.goal_x < INF and pp != null and pp.global_position.distance_to(z.global_position) < 90.0:
							z.goal_x = INF
				_tick -= delta
				if _tick <= 0.0:
					_tick = TICK
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and not sheltered(pl.global_position):
						hits += 1
						pl.hurt(1, Vector2(-1.0, -0.3))
					for z in get_tree().get_nodes_in_group("zombies"):
						if not z.dead and not z.is_boss() and not sheltered(z.global_position) and (z.type_mod == null or not z.type_mod.has_method("ash_proof")):
							z.take_damage(7, z.global_position + Vector2(0, -30), Vector2(-1, 0), false, {"source": "fire", "fixed": 7})
				if _t <= 0.0:
					state = 0
					_t = randf_range(CALM_T.x, CALM_T.y)
					get_tree().call_group("shelters", "queue_redraw")
					for z in get_tree().get_nodes_in_group("zombies"):   # חוזרים לצוד
						z.goal_x = INF
						z._alert_t = maxf(float(z._alert_t), 4.0)


# ---- אפר נופל + זוהר + גל האפר (מסך) ----
class AshFX extends Node2D:
	var vp := Vector2(1280, 720)
	var floor_y := 630.0         # האפר נוחת על הקרקע (לא נופל עד תחתית המסך)
	var _t := 0.0
	var _a := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 33
		for i in 60:
			_a.append(Vector3(r.randf_range(0, vp.x), r.randf_range(0, vp.y), r.randf_range(0.5, 1.5)))

	func _process(delta: float) -> void:
		_t += delta
		var gy: float = (get_viewport().get_canvas_transform() * Vector2(0.0, floor_y)).y
		for i in _a.size():
			var e: Vector3 = _a[i]
			e.y += 30.0 * delta * e.z
			e.x += (sin(_t + e.z * 3.0) * 12.0 - 10.0) * delta
			if e.y > minf(gy - 2.0, vp.y + 6.0):
				e.y = -6.0
				e.x = randf_range(0.0, vp.x)
			e.x = fposmod(e.x, vp.x + 10.0) - 5.0
			_a[i] = e
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var S := preload("res://effects/s33_decor.gd")
		var v: Node = S.volcano()
		var st: int = v.state if v != null else 0
		var hh: float = v.heat() if v != null else 0.0
		for e in _a:   # אפר (חלקיקים אפורים + גחלים כתומות)
			var c := Color(0.6, 0.55, 0.5, 0.6) if int(e.z * 10.0) % 4 != 0 else Color(1.0, 0.5, 0.2, 0.8)
			DrawBatch.rect(self, Rect2(e.x, e.y, 2.0 * e.z, 2.0 * e.z), c)
		DrawBatch.rect(self, Rect2(0, vp.y * 0.8, vp.x, vp.y * 0.2), Color(1.0, 0.35, 0.1, 0.05 + 0.08 * hh))
		if st == 1:   # אזהרה: קצוות אדומים פועמים
			var k := 0.15 + 0.15 * sin(_t * 10.0) * hh
			DrawBatch.rect(self, Rect2(0, 0, vp.x, 18), Color(1.0, 0.3, 0.1, k))
			DrawBatch.rect(self, Rect2(0, vp.y - 18, vp.x, 18), Color(1.0, 0.3, 0.1, k))
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(vp.x * 0.5 - 150, vp.y * 0.3), "TAKE COVER!", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(1.0, 0.6, 0.3, 0.5 + 0.4 * sin(_t * 8.0)))
		elif st == 2:   # הגל: ענן אפר לוהט חוצה את המסך
			var pl := get_tree().get_first_node_in_group("player")
			var safe: bool = pl != null and v.sheltered(pl.global_position)
			DrawBatch.rect(self, Rect2(Vector2.ZERO, vp), Color(0.35, 0.18, 0.1, 0.35 if safe else 0.6))
			for q in 10:
				var x := fposmod(float(q) * 170.0 - _t * 900.0, vp.x + 400.0) - 200.0
				var y := vp.y * (0.2 + 0.07 * float(q))
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x, y), 220.0, 60.0, 0.0, 14), Color(0.3, 0.16, 0.1, 0.35))
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x + 40.0, y + 20.0), 120.0, 20.0, 0.0, 12), Color(1.0, 0.4, 0.1, 0.12))
			if safe:
				DrawBatch.string(self, ThemeDB.fallback_font, Vector2(vp.x * 0.5 - 70, vp.y * 0.3), "SHELTERED", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.6, 1.0, 0.6, 0.8))
