extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 40 ("HARBOR OF WAR") - נמל סנטוס עם שחר. אזור חמישי, שלב 4. האימפריה מעמיסה טנקים על אוניות.
#  רכס סרה דו מאר, הבניינים הנטויים המפורסמים של סנטוס, אוניות מלחמה עם דגלים אדומים, עגורני רציף ענקיים עם כרזות,
#  ערמות מכולות, ערפל ים.
#    harbor_sky     - (רקע) שחר כתום-סגול, שמש נמוכה באובך, עמודי עשן מארובות
#    far_coast      - (רקע) רכס הרים ירוק-כהה, הבניינים הנטויים, אוניות מלחמה בים עם דגלים
#    mid_cranes     - (רקע) עגורני רציף ענקיים עם כרזות אדומות, ערמות מכולות, אוניית משא עם טנקים על הסיפון
#    near_quay      - (רקע) שרשראות, עמודי עגינה, חביות
#    QuayGround     - (עולם) בטון רציף עם קווים צהובים ומסילות עגורן
#    ContainerStack - (עולם) ערמת מכולות (הגג = הקומה, add_floor) + סולם
#    SwingBox       - (עולם, מלכודת) מכולה שמתנדנדת על כבל של עגורן בגובה הגוף - מטוטלת. מכה (גם זומבים)
#    BarbWire       - (עולם, מלכודת) גלילי תיל: הליכה דרכם = איטי + נזק (קופצים מעל). חיילי האימפריה יודעים לעבור
#    Obstacle       - (מוצק + מחסה) "drum_pile" חביות / "cargo_crate" ארגז עם הסמל / "bollard" עמוד עגינה
#    HarborFX       - (מסך) ערפל ים נסחף
#  לשנות: SwingBox.PERIOD / AMP / DMG_Z, BarbWire.TICK.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const E := preload("res://enemies/empire_kit.gd")

const BOX_COLS := [Color("2a5a9a"), Color("c8642a"), Color("6a6e74"), Color("2a7a5a"), Color("9a2a24"), Color("c8a030")]


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


# ---- שחר מעל הנמל ----
static func harbor_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("1e2440"), Color("5a3a5a"), Color("d8704a"), Color("f0c070")], 0.9)
	var sun := Vector2(v.x * 0.62, v.y * 0.66)
	Art.glow(ci, sun, 180.0, Color(1.0, 0.7, 0.4, 0.35))
	DrawBatch.circle(ci, sun, 34.0, Color(1.0, 0.82, 0.55, 0.9))
	for i in 4:   # עמודי עשן מארובות (נוטים ברוח)
		var bx := v.x * (0.12 + 0.24 * float(i))
		for q in 7:
			var k := float(q) / 6.0
			var p := Vector2(bx + k * 120.0 + sin(t * 0.5 + float(q) + float(i)) * 8.0, v.y * 0.62 - k * v.y * 0.5)
			DrawBatch.colored_polygon(ci, Art.ellipse(p, 20.0 + k * 40.0, 12.0 + k * 22.0, 0.0, 12), Color(0.25, 0.22, 0.26, 0.22 * (1.0 - k * 0.6)))


# ---- חוף: הרים, בניינים נטויים, אוניות מלחמה ----
static func far_coast(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pts := PackedVector2Array()
	var x := -30.0
	while x <= v.x + 30.0:
		var u := x + sc
		pts.append(Vector2(x, y - 120.0 - _vn(u / 260.0, 4) * 140.0))
		x += 30.0
	var poly := pts.duplicate()
	poly.append(Vector2(v.x + 30.0, y))
	poly.append(Vector2(-30.0, y))
	DrawBatch.colored_polygon(ci, poly, Color("3a3a4a"))
	DrawBatch.rect(ci, Rect2(0, y - 40.0, v.x, v.y - y + 40.0), Color("4a4a64"))   # הים
	for i in 40:   # ניצוצות שחר על המים
		var wx := fposmod(_h(i, 3) * v.x - sc * 0.3, v.x)
		DrawBatch.line(ci, Vector2(wx, y - 34.0 + float(i % 5) * 6.0), Vector2(wx + 12.0, y - 34.0 + float(i % 5) * 6.0), Color(1.0, 0.75, 0.5, 0.3), 1.0)
	var period := 1200.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		for q in 4:   # הבניינים הנטויים של סנטוס
			var lx := bx + 80.0 + float(q) * 44.0
			var lean := (_h(k * 4 + q, 6) - 0.5) * 12.0
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(lx, y - 40.0), Vector2(lx + 34.0, y - 40.0), Vector2(lx + 34.0 + lean, y - 150.0 - float(q % 2) * 30.0), Vector2(lx + lean, y - 150.0 - float(q % 2) * 30.0)]), Color("44445a"))
			for w in 6:
				DrawBatch.line(ci, Vector2(lx + 4.0 + lean * float(w) / 6.0, y - 50.0 - float(w) * 16.0), Vector2(lx + 30.0 + lean * float(w) / 6.0, y - 50.0 - float(w) * 16.0), Color(1.0, 0.8, 0.5, 0.25), 1.0)
		var sx := bx + 600.0 + _h(k, 8) * 300.0   # אוניית מלחמה
		var sy := y - 30.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(sx, sy), Vector2(sx + 260, sy), Vector2(sx + 280, sy - 18), Vector2(sx - 10, sy - 18)]), Color("2a2a38"))
		DrawBatch.rect(ci, Rect2(sx + 80, sy - 40, 70, 22), Color("2a2a38"))
		DrawBatch.rect(ci, Rect2(sx + 100, sy - 62, 24, 22), Color("2a2a38"))
		DrawBatch.line(ci, Vector2(sx + 112, sy - 62), Vector2(sx + 112, sy - 100), Color("2a2a38"), 2.0)
		DrawBatch.line(ci, Vector2(sx + 150, sy - 30), Vector2(sx + 200, sy - 36), Color("2a2a38"), 3.0)   # תותח
		E.flag(ci, Vector2(sx + 112, sy - 100), 26.0, 16.0, t, k, false)


# ---- עגורני רציף ומכולות ----
static func mid_cranes(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	DrawBatch.rect(ci, Rect2(0, y - 10.0, v.x, v.y - y + 10.0), Color("2e2a30"))
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x0 := float(k) * period - sc
		var r := _rng(k * 61 + 5)
		var cx := x0 + 120.0   # עגורן רציף: רגליים, קורה, זרוע
		var cc := Color("8a3a2a").darkened(0.35)
		for lx in [cx, cx + 120.0]:
			DrawBatch.line(ci, Vector2(lx, y), Vector2(lx + 10.0, y - 260.0), cc, 6.0)
		DrawBatch.line(ci, Vector2(cx - 20.0, y - 120.0), Vector2(cx + 150.0, y - 120.0), cc, 4.0)
		DrawBatch.rect(ci, Rect2(cx - 140.0, y - 272.0, 420.0, 14.0), cc)   # הזרוע מעל הים והרציף
		DrawBatch.rect(ci, Rect2(cx + 10.0, y - 300.0, 40.0, 28.0), cc.lightened(0.05))   # תא
		DrawBatch.line(ci, Vector2(cx + 30.0, y - 300.0), Vector2(cx - 140.0, y - 272.0), cc, 2.0)
		E.banner(ci, Vector2(cx + 65.0, y - 258.0), 40.0, 120.0, t)
		var bx := x0 + 360.0   # ערמת מכולות
		for row in 3:
			for col in 4:
				if r.randf() < 0.85 - float(row) * 0.2:
					var c: Color = BOX_COLS[r.randi() % BOX_COLS.size()].darkened(0.4)
					var p := Vector2(bx + float(col) * 64.0, y - 26.0 * float(row + 1))
					DrawBatch.rect(ci, Rect2(p, Vector2(62, 25)), c)
					for q in 6:
						DrawBatch.line(ci, p + Vector2(4.0 + float(q) * 10.0, 2), p + Vector2(4.0 + float(q) * 10.0, 23), c.darkened(0.25), 1.0)
		# אוניית משא עם טנקים על הסיפון
		var hx := x0 + 640.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(hx, y - 20), Vector2(hx + 240, y - 20), Vector2(hx + 252, y - 70), Vector2(hx - 8, y - 70)]), Color("3a2e2e"))
		for q in 3:
			var tx := hx + 20.0 + float(q) * 72.0
			DrawBatch.rect(ci, Rect2(tx, y - 86.0, 52.0, 14.0), Color("3e4232"))
			DrawBatch.rect(ci, Rect2(tx + 14.0, y - 96.0, 24.0, 10.0), Color("3e4232"))
			DrawBatch.line(ci, Vector2(tx + 36.0, y - 92.0), Vector2(tx + 62.0, y - 94.0), Color("3e4232"), 3.0)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("2e2a30"))


# ---- רציף קרוב ----
static func near_quay(ci: CanvasItem, sc: float, v: Vector2, y: float, _t: float) -> void:
	var period := 480.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		DrawBatch.rect(ci, Rect2(x + 30.0, y - 24.0, 18.0, 24.0), Color("1a181c"))   # עמוד עגינה
		DrawBatch.rect(ci, Rect2(x + 26.0, y - 28.0, 26.0, 6.0), Color("1a181c"))
		var pts := PackedVector2Array()   # שרשרת
		for q in 9:
			var u := float(q) / 8.0
			pts.append(Vector2(x + 50.0 + u * 160.0, y - 20.0 + sin(u * PI) * 14.0))
		DrawBatch.polyline(ci, pts, Color("2a262a"), 3.0)
		for q in 3:   # חביות
			DrawBatch.rect(ci, Rect2(x + 260.0 + float(q) * 22.0, y - 30.0, 18.0, 30.0), Color("24202a"))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("1a181c"))


# ---- בטון הרציף ----
class QuayGround extends Node2D:
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
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("4a4644"))
		DrawBatch.rect(self, Rect2(0, 0, w, 6.0), Color("6a6662"))
		var x := 10.0
		while x < w:   # קווים צהובים אלכסוניים
			DrawBatch.line(self, Vector2(x, 1), Vector2(x + 10.0, 5), Color(0.9, 0.75, 0.2, 0.7), 3.0)
			x += 60.0
		for q in 2:   # מסילות עגורן
			DrawBatch.line(self, Vector2(0, 20.0 + float(q) * 14.0), Vector2(w, 20.0 + float(q) * 14.0), Color("8a8680"), 2.0)
		for i in int(w / 120.0):   # כתמי שמן
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(r.randf_range(0.0, w), r.randf_range(10.0, 60.0)), r.randf_range(10.0, 24.0), 4.0, 0.0, 10), Color(0.1, 0.1, 0.12, 0.4))


# ---- ערמת מכולות ----
class ContainerStack extends Node2D:
	var w := 260.0
	var tier := 120.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s40_decor.gd")
		var hh := tier * 0.5
		for row in 2:
			var c: Color = S.BOX_COLS[r.randi() % S.BOX_COLS.size()]
			var y := -hh * float(row + 1)
			DrawBatch.rect(self, Rect2(0, y, w, hh - 2.0), c.darkened(0.15))
			for q in int(w / 10.0):   # גלי פח
				DrawBatch.line(self, Vector2(4.0 + float(q) * 10.0, y + 3), Vector2(4.0 + float(q) * 10.0, y + hh - 5.0), c.darkened(0.35), 1.2)
			DrawBatch.rect(self, Rect2(0, y, w, hh - 2.0), Color("1a1a1a"), false, 1.5)
			DrawBatch.rect(self, Rect2(w - 30.0, y + 6.0, 4.0, hh - 14.0), c.darkened(0.5))   # ידית דלת
			if row == 0:   # סמל מרוסס
				S.E.emblem(self, Vector2(w * 0.35, y + hh * 0.5), hh * 0.3, Color(0.9, 0.88, 0.82, 0.85))


# ---- מכולה מתנדנדת על כבל ----
class SwingBox extends Node2D:
	const PERIOD := 3.2
	const AMP := 210.0
	const DMG_Z := 20
	const SIZE := Vector2(90, 40)
	var hits := 0                   # לבדיקות
	var zhits := 0
	var _t := 0.0
	var _cd := 0.0

	func _ready() -> void:
		z_index = 6
		add_to_group("hazards")
		_t = randf() * PERIOD

	func box_pos() -> Vector2:   # מרכז המכולה (עולם)
		var a := sin(_t / PERIOD * TAU) * 0.62
		var l := 420.0
		return global_position + Vector2(0, -l - 30.0) + Vector2(sin(a) * l, cos(a) * l)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-AMP - 50.0, -80.0), Vector2(AMP * 2.0 + 100.0, 80.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		var b := box_pos()
		return Rect2(b - SIZE * 0.5, SIZE).grow(margin + 30.0).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		_cd -= delta
		var b := box_pos()
		var r := Rect2(b - SIZE * 0.5, SIZE)
		var vx := cos(_t / PERIOD * TAU)
		var pl := get_tree().get_first_node_in_group("player")
		if _cd <= 0.0 and pl != null and not pl.dead and r.intersects(pl.body_rect()):
			_cd = 0.8
			hits += 1
			pl.hurt(1, Vector2(signf(vx) * 3.0, -1.2))
			pl.velocity.x = signf(vx) * 520.0
			preload("res://sfx.gd").play("hb_clang", b, 2.0, 0.1, 2)
		if Engine.get_physics_frames() % 6 == 0:
			for zz in get_tree().get_nodes_in_group("zombies"):
				if not zz.dead and not zz.is_boss() and r.grow(6.0).has_point(zz.global_position + Vector2(0, -30)):
					zhits += 1
					zz.take_damage(DMG_Z, zz.global_position + Vector2(0, -30), Vector2(signf(vx), -0.3), false, {"source": "container", "fixed": DMG_Z})
					zz.velocity.x = signf(vx) * 400.0
		if Art.on_screen(self, b, 300.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var b := box_pos() - global_position
		var top := Vector2(0, -450.0)
		DrawBatch.line(self, top, b + Vector2(-30, -SIZE.y * 0.5), Color("1a1a1a"), 1.5)
		DrawBatch.line(self, top, b + Vector2(30, -SIZE.y * 0.5), Color("1a1a1a"), 1.5)
		var a := sin(_t / PERIOD * TAU) * 0.62
		DrawBatch.set_transform(self, b, -a * 0.6, Vector2.ONE)
		DrawBatch.rect(self, Rect2(-SIZE * 0.5, SIZE), Color("c8642a"))
		for q in 8:
			DrawBatch.line(self, Vector2(-SIZE.x * 0.5 + 6.0 + float(q) * 11.0, -SIZE.y * 0.5 + 3), Vector2(-SIZE.x * 0.5 + 6.0 + float(q) * 11.0, SIZE.y * 0.5 - 3), Color("8a4018"), 1.2)
		DrawBatch.rect(self, Rect2(-SIZE * 0.5, SIZE), Color("1a1a1a"), false, 1.5)
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
		# צל על הקרקע
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(b.x, -1), 46.0, 4.0, 0.0, 12), Color(0, 0, 0, 0.3))


# ---- גלילי תיל ----
class BarbWire extends Node2D:
	const TICK := 1.0
	var w := 120.0
	var cuts := 0                   # לבדיקות
	var _tick := 0.0

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -26), Vector2(w, 26))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_tick -= delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.is_on_floor() and world_rect().grow(4.0).has_point(pl.global_position + Vector2(0, -4)):
			pl.slow_t = maxf(float(pl.slow_t), 0.25)
			if _tick <= 0.0:
				_tick = TICK
				cuts += 1
				pl.hurt(1, Vector2(0.0, -0.3))
				preload("res://sfx.gd").play("hb_wire", pl.global_position, -2.0, 0.1, 2)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var x := 0.0
		while x < w:   # לולאות תיל
			DrawBatch.arc(self, Vector2(x + 12.0, -12.0), 12.0, 0.0, TAU, 12, Color("5a5a60"), 1.2)
			for q in 3:
				var a := float(q) * 2.1 + x
				var p := Vector2(x + 12.0, -12.0) + Vector2.from_angle(a) * 12.0
				DrawBatch.line(self, p - Vector2(2, 2), p + Vector2(2, 2), Color("8a8a90"), 1.0)
			x += 14.0
		for q in 2:   # יתדות
			DrawBatch.line(self, Vector2(4.0 + float(q) * (w - 8.0), 0), Vector2(4.0 + float(q) * (w - 8.0), -24), Color("3a3020"), 2.0)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "drum_pile"
	var size := Vector2(70, 40)
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
		var S := preload("res://effects/s40_decor.gd")
		match kind:
			"drum_pile":   # חביות שמן
				var n := maxi(2, int(w / 24.0))
				for q in n:
					var dx := 2.0 + float(q) * (w - 4.0) / float(n)
					var dw := (w - 4.0) / float(n) - 2.0
					var c := Color("2a5a3a") if r.randf() < 0.5 else Color("6a2a20")
					Art.fill_shaded(self, PackedVector2Array([Vector2(dx, 0), Vector2(dx + dw, 0), Vector2(dx + dw, -h), Vector2(dx, -h)]), c, 0.15, 0.4, Art.OUTLINE, 1.0)
					DrawBatch.line(self, Vector2(dx, -h * 0.33), Vector2(dx + dw, -h * 0.33), c.darkened(0.4), 1.5)
					DrawBatch.line(self, Vector2(dx, -h * 0.66), Vector2(dx + dw, -h * 0.66), c.darkened(0.4), 1.5)
			"cargo_crate":   # ארגז עץ צבאי עם הסמל
				Art.fill_shaded(self, PackedVector2Array([Vector2(2, 0), Vector2(w - 2, 0), Vector2(w - 2, -h), Vector2(2, -h)]), Color("6a5a3a"), 0.15, 0.35, Art.OUTLINE, 1.3)
				DrawBatch.line(self, Vector2(2, -h), Vector2(w - 2, 0), Color("4a3e28"), 2.0)
				DrawBatch.line(self, Vector2(2, 0), Vector2(w - 2, -h), Color("4a3e28"), 2.0)
				S.E.emblem(self, Vector2(w * 0.5, -h * 0.5), h * 0.28, Color(0.88, 0.85, 0.78, 0.9))
			_:   # עמוד עגינה + חבל
				Art.fill_shaded(self, PackedVector2Array([Vector2(w * 0.25, 0), Vector2(w * 0.75, 0), Vector2(w * 0.7, -h * 0.8), Vector2(w * 0.85, -h * 0.85), Vector2(w * 0.85, -h), Vector2(w * 0.15, -h), Vector2(w * 0.15, -h * 0.85), Vector2(w * 0.3, -h * 0.8)]), Color("2a2a30"), 0.15, 0.35, Art.OUTLINE, 1.3)
				DrawBatch.arc(self, Vector2(w * 0.5, -h * 0.55), w * 0.3, 0.3, PI - 0.3, 8, Color("c8b080"), 3.0)


# ---- ערפל ים (מסך) ----
class HarborFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for i in 6:
			var x := fposmod(float(i) * 260.0 + _t * (14.0 + float(i) * 3.0), vp.x + 500.0) - 250.0
			var y := vp.y * (0.62 + 0.06 * float(i % 3))
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x, y), 260.0, 26.0, 0.0, 16), Color(0.9, 0.85, 0.85, 0.07))
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(1.0, 0.7, 0.5, 0.04))
