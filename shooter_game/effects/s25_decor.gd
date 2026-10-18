extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 25 ("RADIO TOWER") - לילה סוער על גבעה עם תורן רדיו ענק: גשם, ברקים, צלחות לוויין, מסלולי פלדה.
#    storm_sky     - (רקע) שמיים כחולים-אפורים, עננים כבדים שזזים
#    far_mast      - (רקע) גבעות + תורן רדיו ענק עם אורות אדומים מהבהבים וכבלי עיגון
#    mid_station   - (רקע) צלחות לוויין, מבני ציוד, אורנים, גדר רשת עם תיל
#    near_grass    - (רקע) עשב רטוב מתנופף ברוח, עמודי גדר
#    HillGround    - (עולם) עפר רטוב עם חצץ ושלוליות קטנות
#    Puddle        - (עולם, מלכודת) שלולית עם כבל חשמל קרוע בתוכה. לפני ברק היא זוהרת כחול ומנצנצת (STORM WARN),
#                    ובזמן הברק - מחשמלת את מי שעומד בה (DMG לשחקן, Z_DMG לזומבים). זומבים חכמים מחכים בצד.
#    Obstacle      - (מוצק + מחסה) "cabinet" ארון ציוד / "spool" סליל כבלים / "generator" גנרטור
#    StormFX       - (מסך, קבוצה "storm") גשם + ברקים בזמנים קבועים: warning() לפני, flashing() בזמן.
#                    הנקודה המרכזית לסנכרון המלכודות. strike_flash() = הבזק קטן (ROD).
#  לשנות: StormFX.PERIOD, StormFX.WARN, Puddle.DMG, Puddle.Z_DMG.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const MUD := Color("3a3a36")
const MUD_D := Color("22231f")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func storm() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("storm") if tree != null else null


# ---- שמיים סוערים ----
static func storm_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("0a0e16"), Color("16202c"), Color("26323e"), Color("34404a")], 0.85)
	for i in 3:
		Kit.clouds(ci, float(i) * 300.0, v, t, v.y * (0.12 + 0.12 * float(i)), Color(0.1, 0.12, 0.16, 0.55 - float(i) * 0.1), 40 + i, 14.0 + float(i) * 6.0)


# ---- גבעות + תורן ענק ----
static func far_mast(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var dark := Color("10161c")
	var period := 2400.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(x, y), Vector2(x + 500, y - 120), Vector2(x + 1000, y - 150), Vector2(x + 1500, y - 90), Vector2(x + 2400, y)]), Color("161e26"))
		# תורן: משולש מסבכי, צר למעלה
		var mx := x + 1000.0
		var base := y - 150.0
		var h := 420.0
		var lw := 46.0
		DrawBatch.line(ci, Vector2(mx - lw, base), Vector2(mx - 4, base - h), dark, 3.0)
		DrawBatch.line(ci, Vector2(mx + lw, base), Vector2(mx + 4, base - h), dark, 3.0)
		for q in 14:
			var k0 := float(q) / 14.0
			var k1 := float(q + 1) / 14.0
			var w0 := lerpf(lw, 4.0, k0)
			var w1 := lerpf(lw, 4.0, k1)
			DrawBatch.line(ci, Vector2(mx - w0, base - h * k0), Vector2(mx + w1, base - h * k1), dark, 1.2)
			DrawBatch.line(ci, Vector2(mx + w0, base - h * k0), Vector2(mx - w1, base - h * k1), dark, 1.2)
		DrawBatch.line(ci, Vector2(mx, base - h), Vector2(mx, base - h - 40), dark, 2.0)
		for g in 3:   # כבלי עיגון
			var gy := base - h * (0.3 + 0.3 * float(g))
			DrawBatch.line(ci, Vector2(mx, gy), Vector2(mx - 260 - float(g) * 60.0, y - 60), Color(dark, 0.7), 1.0)
			DrawBatch.line(ci, Vector2(mx, gy), Vector2(mx + 260 + float(g) * 60.0, y - 70), Color(dark, 0.7), 1.0)
		for q in 4:   # אורות אדומים
			var ly := base - h * (0.25 + 0.25 * float(q)) - (40.0 if q == 3 else 0.0)
			var on := fmod(t * 0.8 + float(q) * 0.15, 1.6) < 0.8
			if on:
				DrawBatch.circle(ci, Vector2(mx, ly), 10.0, Color(1.0, 0.1, 0.05, 0.25))
				DrawBatch.circle(ci, Vector2(mx, ly), 3.0, Color(1.0, 0.25, 0.15))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("161e26"))


# ---- צלחות לוויין, מבני ציוד, אורנים ----
static func mid_station(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var dark := Color("0e1418")
	var period := 1400.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 271 + 3)
		for i in 7:   # אורנים
			var px := x + r.randf_range(0.0, period)
			var h := r.randf_range(80.0, 140.0)
			var sway := sin(t * 1.8 + px) * 4.0
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - h * 0.22, y), Vector2(px + sway, y - h), Vector2(px + h * 0.22, y)]), Color("121a1c"))
		# צלחת לוויין גדולה
		var dx := x + r.randf_range(200.0, 500.0)
		DrawBatch.line(ci, Vector2(dx, y), Vector2(dx, y - 60), dark, 6.0)
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(dx + 6, y - 92), 44.0, 16.0, -0.9, 18), dark)
		DrawBatch.line(ci, Vector2(dx + 6, y - 92), Vector2(dx + 40, y - 124), dark, 2.0)
		# מבנה ציוד עם חלון מואר
		var bx := x + r.randf_range(700.0, 1050.0)
		DrawBatch.rect(ci, Rect2(bx, y - 70, 120, 70), dark)
		DrawBatch.rect(ci, Rect2(bx - 6, y - 76, 132, 8), Color("182026"))
		DrawBatch.rect(ci, Rect2(bx + 20, y - 50, 22, 14), Color(0.6, 0.8, 0.9, 0.35 + 0.15 * sin(t * 2.0 + float(k))))
		DrawBatch.line(ci, Vector2(bx + 100, y - 76), Vector2(bx + 100, y - 130), dark, 2.0)   # אנטנה
		DrawBatch.circle(ci, Vector2(bx + 100, y - 132), 2.5, Color(1.0, 0.2, 0.1, 0.5 + 0.5 * sin(t * 4.0 + float(k))))
		# גדר רשת עם תיל
		var fx := x + r.randf_range(0.0, 300.0)
		for f in 8:
			DrawBatch.line(ci, Vector2(fx + float(f) * 45.0, y), Vector2(fx + float(f) * 45.0, y - 52), dark, 2.0)
		DrawBatch.line(ci, Vector2(fx, y - 50), Vector2(fx + 315, y - 50), dark, 1.0)
		for f in 30:
			DrawBatch.arc(ci, Vector2(fx + float(f) * 10.5, y - 56), 4.0, 0.0, TAU, 6, Color(dark, 0.7), 1.0)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), dark)


# ---- עשב רטוב ----
static func near_grass(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var col := Color("0a1012")
	var period := 700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 83 + 9)
		for i in 30:
			var px := x + float(i) * period / 30.0 + r.randf_range(-6.0, 6.0)
			var h := r.randf_range(14.0, 34.0)
			var wind := 6.0 + sin(t * 2.4 + px * 0.01) * 4.0   # רוח חזקה
			DrawBatch.line(ci, Vector2(px, y), Vector2(px + wind, y - h), col, 1.8)
		for f in 2:
			var fx := x + r.randf_range(0.0, period)
			DrawBatch.rect(ci, Rect2(fx, y - 46, 5, 46), col)
	DrawBatch.rect(ci, Rect2(0, y - 2.0, v.x, v.y - y + 2.0), col)


# ---- עפר רטוב ----
class HillGround extends Node2D:
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
		var S := preload("res://effects/s25_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), S.MUD_D)
		DrawBatch.rect(self, Rect2(0, 0, w, 8.0), S.MUD)
		DrawBatch.line(self, Vector2(0, 1), Vector2(w, 1), Color(0.6, 0.7, 0.8, 0.25), 1.0)   # ברק רטוב
		for i in int(w / 8.0):   # חצץ
			var px := r.randf_range(0.0, w)
			DrawBatch.circle(self, Vector2(px, r.randf_range(10.0, depth - 4.0)), r.randf_range(1.0, 2.5), Color(0.4, 0.4, 0.38, 0.4))
		for i in int(w / 260.0):
			var px := r.randf_range(0.0, w - 60.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(px, 3), r.randf_range(14.0, 26.0), 2.0), Color(0.5, 0.6, 0.7, 0.35))


# ---- שלולית מחושמלת ----
class Puddle extends Node2D:
	const DMG := 2
	const Z_DMG := 25
	var w := 90.0
	var zaps := 0                # לבדיקות
	var hit_player := 0
	var _done_flash := false
	var _storm: Node = null
	var _was := 0

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-w * 0.5, -40.0), Vector2(w, 42.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:   # זומבים חכמים מחכים בצד כשהשלולית "חיה"
		return _phase() > 0 and world_rect().grow(margin).has_point(p)

	func _phase() -> int:   # 0 = רגיל, 1 = אזהרה, 2 = ברק
		if _storm == null or not is_instance_valid(_storm):
			_storm = preload("res://effects/s25_decor.gd").storm()
		if _storm == null:
			return 0
		if _storm.flashing():
			return 2
		return 1 if _storm.warning() else 0

	func _physics_process(_delta: float) -> void:
		var ph := _phase()
		if ph == 2 and not _done_flash:
			_done_flash = true
			_zap()
		elif ph != 2:
			_done_flash = false
		var vis := Art.on_screen(self, global_position)
		if vis and (ph > 0 or ph != _was or Engine.get_physics_frames() % 8 == 0):
			queue_redraw()
		if ph == 1 and vis and Engine.get_physics_frames() % 7 == 0:
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-w * 0.4, w * 0.4), -2.0), "spark", Vector2.UP, 2)
		_was = ph

	func _zap() -> void:
		zaps += 1
		var r := world_rect()
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead:
			var b: Rect2 = pl.body_rect()
			if b.end.y > global_position.y - 6.0 and b.end.x > r.position.x + 4.0 and b.position.x < r.end.x - 4.0:
				if pl._invuln <= 0.0:
					hit_player += 1
				pl.hurt(DMG, Vector2(0.0, -1.6))
				pl._say("ZZZT!", Color("80d0ff"))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead:
				continue
			if absf(z.global_position.x - global_position.x) < w * 0.5 and absf(z.global_position.y - global_position.y) < 6.0:
				z.take_damage(Z_DMG, z.global_position + Vector2(0, -20), Vector2.UP, false, {"source": "hazard", "fixed": Z_DMG})
		if Art.on_screen(self, global_position):
			Sfx.play("s25_zap", global_position, 2.0, 0.1, 3)
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -6), "spark", Vector2.UP, 14)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var ph := _phase()
		var t := float(Engine.get_physics_frames()) / 60.0
		var pts := Art.ellipse(Vector2(0, 0), w * 0.5, 4.5, 0.0, 18)
		DrawBatch.colored_polygon(self, pts, Color(0.2, 0.26, 0.32, 0.9))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(-w * 0.12, -1), w * 0.3, 1.6, 0.0, 12), Color(0.6, 0.7, 0.8, 0.35))
		for i in 3:   # טיפות גשם על המים
			var k := fmod(t * 1.3 + float(i) * 0.37, 1.0)
			var rx := -w * 0.35 + float(i) * w * 0.35
			DrawBatch.arc(self, Vector2(rx, 0), 2.0 + k * 8.0, PI, TAU, 8, Color(0.8, 0.9, 1.0, 0.5 * (1.0 - k)), 1.0)
		# עמוד חשמל שבור + כבל שנופל לתוך השלולית
		var px := w * 0.5 + 24.0
		DrawBatch.line(self, Vector2(px, 2), Vector2(px - 10, -70), Color("3a2e24"), 5.0)
		DrawBatch.line(self, Vector2(px - 22, -60), Vector2(px + 4, -64), Color("3a2e24"), 3.0)
		var cable := PackedVector2Array([Vector2(px - 18, -60), Vector2(px - 26, -30), Vector2(px - 30, -8), Vector2(w * 0.2, -1)])
		DrawBatch.polyline(self, cable, Color("16181a"), 2.2)
		var tip := Vector2(w * 0.2, -1)
		DrawBatch.circle(self, tip, 2.5, Color("c87a3a"))   # קצה נחושת
		if ph == 1:   # אזהרה: זוהר כחול + ברקים קטנים בכבל
			var a := 0.35 + 0.25 * sin(t * 30.0)
			DrawBatch.colored_polygon(self, pts, Color(0.4, 0.8, 1.0, a))
			for q in 3:
				var p0 := tip + Vector2(randf_range(-w * 0.4, w * 0.1), randf_range(-2.0, 1.0))
				DrawBatch.polyline(self, PackedVector2Array([tip, (tip + p0) * 0.5 + Vector2(0, randf_range(-6.0, 0.0)), p0]), Color(0.8, 0.95, 1.0, 0.9), 1.2)
		elif ph == 2:   # ברק: כל השלולית מתחשמלת
			DrawBatch.colored_polygon(self, pts, Color(0.85, 0.95, 1.0, 0.9))
			for q in 6:
				var x0 := randf_range(-w * 0.5, w * 0.5)
				DrawBatch.polyline(self, PackedVector2Array([Vector2(x0, 0), Vector2(x0 + randf_range(-6, 6), -14), Vector2(x0 + randf_range(-10, 10), -28)]), Color(0.8, 0.95, 1.0, 0.9), 1.6)
			Art.glow(self, Vector2(0, -10), w * 0.7, Color(0.5, 0.85, 1.0, 0.4))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "cabinet"
	var size := Vector2(60, 70)
	var seed_v := 0
	var _t := 0.0

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
			"cabinet":   # ארון ציוד רדיו (גבוה - מחסה)
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, -h), Vector2(0, -h)]), Color("5a646a"), 0.15, 0.4, Art.OUTLINE, 1.5)
				DrawBatch.line(self, Vector2(w * 0.5, -h + 4), Vector2(w * 0.5, -4), Color(0, 0, 0, 0.35), 1.5)
				for q in 4:
					DrawBatch.rect(self, Rect2(6, -h + 10.0 + float(q) * 8.0, w * 0.5 - 12.0, 3), Color(0, 0, 0, 0.3))
				DrawBatch.circle(self, Vector2(w - 10, -h + 12), 2.0, Color(0.3, 1.0, 0.4))
				DrawBatch.circle(self, Vector2(w - 10, -h + 20), 2.0, Color(1.0, 0.3, 0.2))
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w * 0.62, -h * 0.55), Vector2(w * 0.88, -h * 0.55), Vector2(w * 0.75, -h * 0.75)]), Color("e8c040"))   # סימן מתח גבוה
			"spool":   # סליל כבלים מעץ (מהצד)
				var c := Vector2(w * 0.5, -h * 0.5)
				DrawBatch.circle(self, c, h * 0.5 + 1.5, Art.OUTLINE)
				DrawBatch.circle(self, c, h * 0.5, Color("7a5a3a"))
				DrawBatch.circle(self, c, h * 0.32, Color("1a1a1c"))
				for q in 3:
					DrawBatch.arc(self, c, h * 0.18 + float(q) * 3.5, 0, TAU, 14, Color("2e2e30"), 1.5)
				DrawBatch.circle(self, c, h * 0.1, Color("5a4028"))
			_:   # גנרטור
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, -h * 0.8), Vector2(w * 0.8, -h), Vector2(0, -h)]), Color("8a7a2a"), 0.15, 0.4, Art.OUTLINE, 1.5)
				for q in 5:
					DrawBatch.line(self, Vector2(8.0 + float(q) * 7.0, -h * 0.7), Vector2(8.0 + float(q) * 7.0, -h * 0.3), Color(0, 0, 0, 0.35), 2.0)
				DrawBatch.rect(self, Rect2(w * 0.65, -h * 0.65, w * 0.25, h * 0.3), Color("3a3a3e"))
				DrawBatch.line(self, Vector2(w * 0.85, -h), Vector2(w * 0.85, -h - 10), Color("4a4a4e"), 4.0)   # אגזוז


# ---- סערה: גשם + ברקים בזמנים קבועים (שכבת מסך) ----
class StormFX extends Node2D:
	const PERIOD := Vector2(7.0, 10.0)   # כל כמה זמן ברק
	const WARN := 1.1                     # כמה זמן לפני הברק השלוליות מזהירות
	const FLASH := 0.35
	var vp := Vector2(1280, 720)
	var flashes := 0                      # לבדיקות
	var _next := 6.0
	var _flash := 0.0
	var _small := 0.0
	var _bolt := PackedVector2Array()
	var _drops := []

	func _ready() -> void:
		add_to_group("storm")
		var r := RandomNumberGenerator.new()
		r.seed = 25
		for i in 110:
			_drops.append(Vector3(r.randf_range(0, vp.x + 200.0), r.randf_range(0, vp.y), r.randf_range(0.7, 1.3)))

	func warning() -> bool:
		return _next > 0.0 and _next <= WARN

	func flashing() -> bool:
		return _flash > FLASH * 0.2

	func time_to_flash() -> float:
		return _next

	func strike_flash() -> void:   # ROD: הבזק קטן
		_small = 0.25

	func _process(delta: float) -> void:
		_next -= delta
		_flash = maxf(_flash - delta, 0.0)
		_small = maxf(_small - delta, 0.0)
		if _next <= 0.0:
			_next = randf_range(PERIOD.x, PERIOD.y)
			_flash = FLASH
			flashes += 1
			Sfx.play("thunder", null, 0.0, 0.15)
			_bolt = PackedVector2Array([Vector2(randf_range(vp.x * 0.15, vp.x * 0.85), 0)])
			var y := 0.0
			var x: float = _bolt[0].x
			while y < vp.y * 0.55:
				y += randf_range(25.0, 50.0)
				x += randf_range(-30.0, 30.0)
				_bolt.append(Vector2(x, y))
		for i in _drops.size():
			var d: Vector3 = _drops[i]
			d.x -= 260.0 * delta * d.z
			d.y += 900.0 * delta * d.z
			if d.y > vp.y:
				d = Vector3(randf_range(0.0, vp.x + 300.0), -10.0, d.z)
			_drops[i] = d
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for d in _drops:
			DrawBatch.line(self, Vector2(d.x, d.y), Vector2(d.x + 5.0, d.y - 16.0 * d.z), Color(0.7, 0.8, 0.95, 0.35), 1.0)
		if _flash > 0.0:
			var a := (_flash / FLASH) * (1.0 if fmod(_flash, 0.1) < 0.06 else 0.5)
			DrawBatch.rect(self, Rect2(Vector2.ZERO, vp), Color(0.75, 0.85, 1.0, 0.28 * a))
			DrawBatch.polyline(self, _bolt, Color(0.9, 0.95, 1.0, a), 2.5)
		elif _small > 0.0:
			DrawBatch.rect(self, Rect2(Vector2.ZERO, vp), Color(0.75, 0.85, 1.0, 0.25 * _small))
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.05, 0.08, 0.14, 0.12))   # כהות סערה
