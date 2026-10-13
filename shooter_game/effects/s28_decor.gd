extends RefCounted
# ============================================================
#  קישוטים לשלב 28 ("CLOUD PASS") - מעבר הרים באנדים בגובה 4,000 מטר: פסגות מושלגות, עננים שעוברים דרך המעבר,
#  טרסות חקלאות של האינקה, חומות אבן אינקאיות (פתחים טרפזיים), קונדורים, ערמות אבנים (אפצ'טה), עשב איצ'ו צהוב.
#    andes_sky     - (רקע) כחול עמוק של גובה רב, שמש חזקה, עננים דקים
#    far_peaks     - (רקע) רכסים מושלגים + גדות עננים שנעות דרך המעבר
#    mid_terraces  - (רקע) טרסות אינקה ירוקות-חומות, חורבות, קונדורים חגים, לאמות
#    near_ichu     - (רקע) עשב איצ'ו מתנופף, סלעים, אפצ'טות
#    PassGround    - (עולם) שביל סלעי עם חצץ וכתמי שלג
#    Crevasse      - (עולם, מלכודת) סדק קרח עם יתדות קרח (יורש SpikePit משלב 21: נופלים = נפגעים ונזרקים החוצה)
#    Obstacle      - (מוצק + מחסה) "inka_wall" חומת אבן אינקאית / "apacheta" ערמת אבנים / "bale" חבילות איצ'ו
#    RopeBridge    - (עולם) גשר חבלים אינקאי (חבלים מעל קומה מעץ)
#    Campfire      - (עולם) מדורת רועים עם עשן (חלקיקים) ועשב שנשרף
#    Wind          - (עולם, מלכודת, קבוצה "wind") רוח חזקה במחזור: CALM -> WARN (דגלים ואבק) -> GUST (דוחפת אותך ואת הזומבים)
#    PassFX        - (מסך) פתיתי שלג, אבק ופסי רוח בזמן משב, ערפל עננים שעובר
#  לשנות: Wind.CALM_T, Wind.WARN_T, Wind.GUST_T, Wind.PUSH.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const ROCK := Color("7a6e62")
const ROCK_D := Color("4e463e")
const ICHU := Color("c8a858")
const STONE := Color("9a8e7e")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func wind() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("wind") if tree != null else null


# ---- שמיים של גובה רב ----
static func andes_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("1a3a7a"), Color("2a5aa0"), Color("5a8ac8"), Color("a8c8e0"), Color("dde8f0")], 0.82)
	var sun := Vector2(v.x * 0.78, v.y * 0.16)
	for i in 4:
		ci.draw_circle(sun, 90.0 - float(i) * 20.0, Color(1.0, 1.0, 0.92, 0.06 + 0.05 * float(i)))
	ci.draw_circle(sun, 22.0, Color("fffff0"))
	for i in 3:   # עננים דקים גבוהים
		var y := v.y * (0.12 + 0.07 * float(i))
		var x := fposmod(t * (3.0 + float(i) * 2.0) + float(i) * 470.0, v.x + 800.0) - 400.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 300, y - 5), Vector2(x + 640, y + 2), Vector2(x + 320, y + 6)]), Color(1, 1, 1, 0.35))


# ---- רכסים מושלגים + עננים שעוברים ----
static func far_peaks(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1600.0
	var start := int(floor(sc / period)) - 1
	for layer in 2:
		var lsc := sc * (0.6 if layer == 0 else 1.0)
		var base := y - (60.0 if layer == 0 else 0.0)
		var col := Color("7a86a8") if layer == 0 else Color("5a6488")
		start = int(floor(lsc / period)) - 1
		for k in range(start, start + int(ceil(v.x / period)) + 3):
			var x := float(k) * period - lsc
			var r := _rng(k * 61 + layer * 7 + 3)
			for m in 5:
				var mx := x + float(m) * 340.0 + r.randf_range(-50.0, 50.0)
				var mh := r.randf_range(180.0, 300.0) * (0.85 if layer == 0 else 1.0)
				var pts := PackedVector2Array([Vector2(mx - 230, base), Vector2(mx - 60, base - mh * 0.7), Vector2(mx, base - mh), Vector2(mx + 40, base - mh * 0.82), Vector2(mx + 250, base)])
				ci.draw_colored_polygon(pts, col)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(mx - 80, base - mh * 0.62), Vector2(mx - 60, base - mh * 0.7), Vector2(mx, base - mh), Vector2(mx + 40, base - mh * 0.82), Vector2(mx + 70, base - mh * 0.6), Vector2(mx + 20, base - mh * 0.7), Vector2(mx - 20, base - mh * 0.58)]), Color("f4f6fa"))
	# גדות עננים שזזות דרך המעבר
	for i in 4:
		var cx := fposmod(t * (14.0 + float(i) * 5.0) - sc * 0.3 + float(i) * 700.0, v.x + 1200.0) - 600.0
		var cy := y - 90.0 + float(i % 2) * 40.0
		for q in 7:   # בלי עיגולים חדים: אליפסות שטוחות ושקופות שחופפות
			var cc := Vector2(cx + float(q) * 60.0, cy + sin(float(q) * 1.3) * 10.0)
			ci.draw_colored_polygon(Art.ellipse(cc, 110.0 + float(q % 3) * 20.0, 26.0 + float(q % 2) * 10.0, 0.0, 16), Color(1, 1, 1, 0.13))
			ci.draw_colored_polygon(Art.ellipse(cc + Vector2(10, -6), 60.0, 16.0, 0.0, 12), Color(1, 1, 1, 0.12))
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("5a6488"))


# ---- טרסות אינקה, חורבות, קונדורים, לאמות ----
static func mid_terraces(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1400.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 211 + 1)
		# גבעה עם טרסות מדורגות
		var hx := x + r.randf_range(0.0, 300.0)
		for s in 6:
			var sy := y - float(s) * 26.0
			var sw := 760.0 - float(s) * 110.0
			var sx := hx + float(s) * 55.0
			ci.draw_rect(Rect2(sx, sy - 26.0, sw, 26.0), Color("6a7a4a") if s % 2 == 0 else Color("7a8a52"))
			ci.draw_rect(Rect2(sx, sy - 4.0, sw, 4.0), Color("5a5042"))   # קיר אבן של הטרסה
		# חורבת אינקה: קיר עם פתח טרפזי
		var rx := x + r.randf_range(800.0, 1100.0)
		ci.draw_rect(Rect2(rx, y - 70, 150, 70), Color("8a7e6c"))
		for row in 4:
			for c in 5:
				ci.draw_rect(Rect2(rx + float(c) * 30.0 + float(row % 2) * 15.0, y - 70.0 + float(row) * 17.5, 28, 16), Color(0, 0, 0, 0.12), false, 1.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(rx + 55, y), Vector2(rx + 62, y - 50), Vector2(rx + 88, y - 50), Vector2(rx + 95, y)]), Color("2a2620"))
		# לאמות רועות
		for l in 2:
			var lx := x + r.randf_range(100.0, 1300.0)
			var lc := Color("e8e0d0") if l == 0 else Color("8a6a4a")
			ci.draw_colored_polygon(Art.ellipse(Vector2(lx, y - 14), 11.0, 6.0, 0.0, 10), lc)
			ci.draw_line(Vector2(lx + 8, y - 16), Vector2(lx + 12, y - 30), lc, 3.0)
			ci.draw_circle(Vector2(lx + 13, y - 31), 3.0, lc)
			for lg in [-7.0, -3.0, 4.0, 8.0]:
				ci.draw_line(Vector2(lx + lg, y - 9), Vector2(lx + lg, y), lc, 1.5)
	# קונדורים חגים (שמיים)
	for c in 2:
		var a := t * 0.25 + float(c) * 2.5
		var cp := Vector2(fposmod(v.x * 0.3 + float(c) * 500.0 + cos(a) * 220.0 - sc * 0.1, v.x + 200.0) - 100.0, y - 300.0 + sin(a) * 60.0)
		var flap := sin(t * 1.5 + float(c)) * 0.15
		ci.draw_polyline(PackedVector2Array([cp + Vector2(-34, -6 + flap * 40.0), cp + Vector2(-14, 0), cp, cp + Vector2(14, 0), cp + Vector2(34, -6 + flap * 40.0)]), Color("1a1a20"), 3.0)
		ci.draw_circle(cp, 2.5, Color("f0f0f0"))
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("5a5042"))


# ---- עשב איצ'ו, סלעים, אפצ'טות ----
static func near_ichu(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 800.0
	var start := int(floor(sc / period)) - 1
	var w: Node = wind()
	var gust: float = w.strength() if w != null else 0.0
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 97 + 5)
		for i in 9:   # גושי איצ'ו
			var px := x + r.randf_range(0.0, period)
			var h := r.randf_range(20.0, 38.0)
			for q in 6:
				var bend := sin(t * 2.0 + px * 0.02 + float(q)) * 3.0 + gust * 14.0
				ci.draw_line(Vector2(px + float(q) * 3.0, y), Vector2(px + float(q) * 3.0 + bend + float(q - 3) * 2.0, y - h), Color("6a5a30"), 1.6)
		var cx := x + r.randf_range(100.0, 700.0)   # אפצ'טה (ערמת אבנים)
		for s in 4:
			ci.draw_colored_polygon(Art.ellipse(Vector2(cx, y - 6.0 - float(s) * 9.0), 16.0 - float(s) * 3.0, 6.0, 0.0, 10), Color("3a3430"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 400, y), Vector2(x + 420, y - 30), Vector2(x + 470, y - 36), Vector2(x + 500, y)]), Color("2e2a26"))
	ci.draw_rect(Rect2(0, y - 2.0, v.x, v.y - y + 2.0), Color("2e2a26"))


# ---- שביל סלעי ----
class PassGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s28_decor.gd")
		draw_rect(Rect2(0, 0, w, depth), S.ROCK_D)
		draw_rect(Rect2(0, 0, w, 8.0), S.ROCK)
		for i in int(w / 9.0):   # חצץ
			draw_circle(Vector2(r.randf_range(0.0, w), r.randf_range(10.0, depth - 4.0)), r.randf_range(1.0, 3.0), Color(0.55, 0.5, 0.45, 0.5))
		for i in int(w / 230.0):   # כתמי שלג
			var px := r.randf_range(0.0, w - 60.0)
			draw_colored_polygon(Art.ellipse(Vector2(px, 2), r.randf_range(18.0, 40.0), 3.5), Color(0.95, 0.96, 1.0, 0.85))
		for i in int(w / 150.0):   # אבנים
			var px := r.randf_range(0.0, w)
			draw_colored_polygon(Art.ellipse(Vector2(px, -1.0), r.randf_range(4.0, 8.0), 3.0), S.STONE)


# ---- סדק קרח (יורש את בור היתדות של שלב 21, ציור אחר) ----
class Crevasse extends "res://effects/s21_decor.gd".SpikePit:
	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = _seed
		draw_rect(Rect2(0, 0, w, depth + 30.0), Color("1a2a3a"))
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(4, depth), Vector2(0, depth)]), Color("a8c8e0"))
		draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w - 10, 0), Vector2(w - 4, depth), Vector2(w, depth)]), Color("a8c8e0"))
		draw_rect(Rect2(0, depth - 4.0, w, 34.0), Color("2a3a4a"))
		var n := int(w / 10.0)
		for i in n:   # יתדות קרח
			var x := 4.0 + float(i) * (w - 8.0) / float(maxi(n - 1, 1))
			var h := r.randf_range(16.0, 28.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3.5, depth), Vector2(x + r.randf_range(-1.5, 1.5), depth - h), Vector2(x + 3.5, depth)]), Color(0.75, 0.88, 1.0, 0.9))
			draw_line(Vector2(x, depth - h + 2.0), Vector2(x, depth - 4.0), Color(1, 1, 1, 0.5), 1.0)
		for i in 3:   # נטיפי קרח על השפה
			var x := r.randf_range(8.0, w - 8.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 0), Vector2(x, 10), Vector2(x + 3, 0)]), Color(0.85, 0.95, 1.0, 0.9))
		draw_line(Vector2(-14, 0), Vector2(-14, -24), Color("6a5030"), 3.0)   # מקל עם סרט אדום
		draw_colored_polygon(PackedVector2Array([Vector2(-14, -24), Vector2(-4, -21), Vector2(-14, -17)]), Color("c03020"))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "inka_wall"
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
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s28_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"inka_wall":   # חומת אבן אינקאית: אבנים מצולעות שמשתלבות בלי טיט
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 4, -h), Vector2(4, -h)]), S.STONE, 0.15, 0.35, Art.OUTLINE, 1.5)
				var y := 0.0
				while y > -h + 6.0:
					var bh := r.randf_range(12.0, 18.0)
					var x := 2.0
					while x < w - 6.0:
						var bw := r.randf_range(16.0, 28.0)
						var pts := PackedVector2Array([Vector2(x + 2, y - 1), Vector2(minf(x + bw, w - 3), y - 1), Vector2(minf(x + bw, w - 4), maxf(y - bh, -h + 2)), Vector2(x + 3, maxf(y - bh, -h + 2))])
						draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.25, 0.22, 0.2, 0.7), 1.2)
						x += bw
					y -= bh
			"apacheta":   # ערמת אבנים עם בד צבעוני
				for s in 4:
					var sw := w * (1.0 - float(s) * 0.2)
					Art.oval_shaded(self, Vector2(w * 0.5, -h * 0.12 - float(s) * h * 0.22), sw * 0.5, h * 0.14, Color("8a8070").darkened(float(s % 2) * 0.1), 0.0, Art.OUTLINE, 1.1)
				for c in 3:
					draw_line(Vector2(w * 0.3 + float(c) * w * 0.2, -h * 0.5), Vector2(w * 0.35 + float(c) * w * 0.2, -h * 0.3), [Color("d02a4a"), Color("2a8ad0"), Color("e8c030")][c], 3.0)
			_:   # חבילות איצ'ו קשורות
				for i in 2:
					var bx := float(i) * w * 0.5
					Art.fill_shaded(self, PackedVector2Array([Vector2(bx + 2, 0), Vector2(bx + w * 0.5 - 2, 0), Vector2(bx + w * 0.5 - 4, -h), Vector2(bx + 4, -h)]), S.ICHU, 0.2, 0.35, Art.OUTLINE, 1.2)
					draw_line(Vector2(bx + 4, -h * 0.5), Vector2(bx + w * 0.5 - 4, -h * 0.5), Color("6a4a2a"), 2.0)
					for q in 5:
						draw_line(Vector2(bx + 6.0 + float(q) * 6.0, -h), Vector2(bx + 4.0 + float(q) * 6.0, -h - 6.0), S.ICHU, 1.2)


# ---- גשר חבלים אינקאי (מעל קומה מעץ) ----
class RopeBridge extends Node2D:
	var w := 400.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w):
			queue_redraw()

	func _draw() -> void:
		var rope := Color("8a6a3a")
		var w_node: Node = preload("res://effects/s28_decor.gd").wind()
		var sway: float = (w_node.strength() if w_node != null else 0.0) * 6.0 + sin(_t * 1.3) * 1.5
		for side in [0.0, w]:   # עמודי אבן
			draw_rect(Rect2(side - 8, -40, 16, 52), Color("8a7e6c"))
		for hgt in [-36.0, -18.0]:   # חבלי יד
			var pts := PackedVector2Array()
			for i in 13:
				var u := float(i) / 12.0
				pts.append(Vector2(u * w, hgt + sin(u * PI) * 10.0 + sway * sin(u * PI)))
			draw_polyline(pts, rope, 2.0)
		for i in int(w / 30.0):   # חבלים אנכיים
			var u := float(i) / (w / 30.0)
			var x := u * w
			draw_line(Vector2(x, -36.0 + sin(u * PI) * 10.0 + sway * sin(u * PI)), Vector2(x, 0), Color(rope, 0.7), 1.0)


# ---- מדורת רועים עם עשן ----
class Campfire extends Node2D:
	var _t := 0.0
	var _puff := 0.0

	func _ready() -> void:
		z_index = 2
		var f = preload("res://fire.gd").new()
		f.width = 18.0
		f.height = 26.0
		f.position = Vector2(0, -4)
		add_child(f)

	func _process(delta: float) -> void:
		_t += delta
		_puff -= delta
		if _puff <= 0.0 and Art.on_screen(self, global_position):
			_puff = 0.22
			var w_node: Node = preload("res://effects/s28_decor.gd").wind()
			var d := Vector2((w_node.dir * w_node.strength() if w_node != null else 0.0) * 1.5 + 0.2, -1.0)
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-4, 4), -26), "smoke", d, 2)

	func _draw() -> void:
		for i in 7:   # טבעת אבנים
			var a := PI + float(i) * PI / 6.0
			draw_colored_polygon(Art.ellipse(Vector2(cos(a) * 18.0, -2.0 + sin(a) * 3.0), 5.0, 3.5, 0.0, 8), Color("6a6058"))
		draw_line(Vector2(-12, -2), Vector2(10, -8), Color("4a3020"), 3.0)
		draw_line(Vector2(-10, -8), Vector2(12, -2), Color("4a3020"), 3.0)
		Art.glow(self, Vector2(0, -12), 46.0, Color(1.0, 0.55, 0.2, 0.18 + 0.05 * sin(_t * 9.0)))


# ---- הרוח: CALM -> WARN -> GUST (דוחפת שחקן וזומבים) ----
class Wind extends Node:
	const CALM_T := Vector2(6.0, 9.0)
	const WARN_T := 1.3
	const GUST_T := 2.0
	const PUSH := 120.0          # כמה פיקסלים בשנייה הרוח מזיזה אותך (באוויר x1.5)
	var state := 0               # 0 = רגוע, 1 = אזהרה, 2 = משב
	var dir := 1.0
	var gusts := 0               # לבדיקות
	var _t := 4.0

	func _ready() -> void:
		add_to_group("wind")

	func strength() -> float:   # -1..1 (לציור: עשב, דגלים, עשן)
		match state:
			1:
				return dir * 0.35 * (1.0 - _t / WARN_T)
			2:
				return dir * (0.6 + 0.4 * sin(_t * 9.0))
		return 0.0

	func _physics_process(delta: float) -> void:
		_t -= delta
		match state:
			0:
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					dir = 1.0 if randf() < 0.5 else -1.0
					Sfx.play("w28_howl", null, -4.0, 0.1, 1)
			1:
				if _t <= 0.0:
					state = 2
					_t = GUST_T
					gusts += 1
					Sfx.play("w28_gust", null, 0.0, 0.1, 1)
			2:
				var pl := get_tree().get_first_node_in_group("player")
				if pl != null and not pl.dead and pl.grabbed_by == null:   # דוחף ישירות (נעצר בקירות): נגד הרוח הולכים לאט
					pl.move_and_collide(Vector2(dir * PUSH * (1.0 if pl.is_on_floor() else 1.5) * delta, 0.0))
				for z in get_tree().get_nodes_in_group("zombies"):
					if not z.dead and z.sc < 1.6 and (z.type_mod == null or not z.type_mod.has_method("in_air")):
						z.move_and_collide(Vector2(dir * PUSH * 0.45 * delta, 0.0))
				if _t <= 0.0:
					state = 0
					_t = randf_range(CALM_T.x, CALM_T.y)


# ---- שלג, אבק, פסי רוח, ערפל עננים (מסך) ----
class PassFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _f := []
	var _fog := 0.0
	var _fog_t := 12.0

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 28
		for i in 60:
			_f.append(Vector3(r.randf_range(0, vp.x), r.randf_range(0, vp.y), r.randf_range(0.5, 1.5)))

	func _process(delta: float) -> void:
		_t += delta
		var w: Node = preload("res://effects/s28_decor.gd").wind()
		var s: float = w.strength() if w != null else 0.0
		for i in _f.size():
			var e: Vector3 = _f[i]
			e.x += (s * 700.0 + sin(_t + e.z * 4.0) * 20.0) * delta * e.z
			e.y += (40.0 - absf(s) * 20.0) * delta * e.z
			if e.y > vp.y + 10.0:
				e.y = -10.0
			e.x = fposmod(e.x, vp.x + 20.0) - 10.0
			_f[i] = e
		_fog_t -= delta   # מדי פעם ענן עובר דרך המעבר
		if _fog_t <= 0.0:
			_fog_t = randf_range(14.0, 22.0)
			_fog = 6.0
		_fog = maxf(_fog - delta, 0.0)
		queue_redraw()

	func _draw() -> void:
		var w: Node = preload("res://effects/s28_decor.gd").wind()
		var s: float = w.strength() if w != null else 0.0
		for e in _f:
			if absf(s) > 0.3:
				draw_line(Vector2(e.x, e.y), Vector2(e.x - s * 18.0 * e.z, e.y - 2.0), Color(1, 1, 1, 0.6), 1.2)
			else:
				draw_circle(Vector2(e.x, e.y), 1.4 * e.z, Color(1, 1, 1, 0.75))
		if absf(s) > 0.4:   # פסי רוח ואבק
			for i in 8:
				var y := fposmod(float(i) * 97.0 + _t * 13.0, vp.y)
				var x := fposmod(_t * 900.0 * signf(s) + float(i) * 211.0, vp.x + 400.0) - 200.0
				draw_line(Vector2(x, y), Vector2(x - signf(s) * 120.0, y), Color(1, 1, 1, 0.25 * absf(s)), 1.5)
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.85, 0.8, 0.7, 0.08 * absf(s)))
		if _fog > 0.0:   # ענן עובר
			var k := sin(clampf(_fog / 6.0, 0.0, 1.0) * PI)
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.95, 0.96, 1.0, 0.35 * k))
			for q in 8:
				draw_circle(Vector2(fposmod(float(q) * 190.0 + _t * 40.0, vp.x + 200.0) - 100.0, vp.y * 0.55 + sin(float(q)) * 80.0), 140.0, Color(1, 1, 1, 0.12 * k))
