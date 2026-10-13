extends RefCounted
# ============================================================
#  קישוטים לשלב 37 ("FAVELA HEIGHTS") - פאבלה על גבעה בריו דה ז'ניירו בשקיעה. אזור חמישי (דרום-מזרח): הערים הענקיות.
#  ישו הגואל על הקורקובדו, הר הסוכר, המפרץ, מאות בתים צבעוניים מוערמים, מכלי מים כחולים, חוטי חשמל מסובכים ("גאטו"),
#  עפיפונים (פיפה) בשמיים.
#    rio_sky       - (רקע) שקיעה זהובה-ורודה, שמש נמוכה, עפיפונים שמתנדנדים ברוח
#    far_rio       - (רקע) הר הסוכר והקורקובדו עם פסל ישו, המפרץ ואורות העיר שנדלקים
#    mid_favela    - (רקע) גבעה מכוסה בתים צבעוניים מוערמים, חלונות דולקים, מכלי מים, חוטים
#    near_houses   - (רקע) חזיתות קרובות, מוטות ברזל על הגגות, חבלי כביסה
#    FavelaGround  - (עולם) רחוב בטון שחוק עם תעלת ניקוז
#    Laje          - (עולם) בית לבנים עם גג שטוח ("לאז'ה" = הקומה, add_floor) + מדרגות
#    LiveWire      - (עולם, מלכודת) חוט חשמל גנוב בין שני עמודים: ניצוצות (אזהרה) -> קשת חשמל לקרקע. ירייה בקופסה מנתקת אותו
#    WaterTank     - (עולם, מלכודת) מכל מים כחול על גג: יורים בו -> נשפך ושוטף את הזומבים, ומשאיר שלולית (Puddle)
#    Puddle        - (עולם) שלולית. חוט חשמל שיורה קשת עליה -> כל השלולית מחושמלת!
#    Obstacle      - (מוצק + מחסה) "moto" מוטו-טקסי / "trash_bags" שקיות זבל / "bar_table" שולחן בוטקו וארגזי בירה
#    FavelaFX      - (מסך) אובך חם של שקיעה, אבק
#  לשנות: LiveWire.CYCLE / WARN_T / ARC_T / DMG_Z, WaterTank.HP, Puddle.LIFE / SHOCK_DMG.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const HOUSE_COLS := [Color("c8643a"), Color("e8b040"), Color("4a9ac8"), Color("e07a8a"), Color("6ab06a"), Color("d8d0c0"), Color("a0522d"), Color("8a6ab0")]


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


static func kite(ci: CanvasItem, p: Vector2, s: float, c: Color, t: float, seed_v: int) -> void:   # עפיפון (פיפה)
	var a := sin(t * 1.3 + float(seed_v)) * 0.25
	var pts := PackedVector2Array([Vector2(0, -10), Vector2(7, 0), Vector2(0, 12), Vector2(-7, 0)])
	var tp := PackedVector2Array()
	for q in pts:
		tp.append(p + q.rotated(a) * s)
	ci.draw_colored_polygon(tp, c)
	ci.draw_line(tp[0], tp[2], c.darkened(0.4), 1.0)
	var tail := PackedVector2Array()
	for q in 6:
		tail.append(tp[2] + Vector2(sin(t * 4.0 + float(q) + float(seed_v)) * 4.0 * s, float(q) * 5.0 * s))
	ci.draw_polyline(tail, c.lightened(0.3), 1.0)


# ---- שקיעה זהובה ועפיפונים ----
static func rio_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("2a3a7a"), Color("8a4a8a"), Color("e8705a"), Color("f8c060")], 0.9)
	var sun := Vector2(v.x * 0.32, v.y * 0.62)
	Art.glow(ci, sun, 160.0, Color(1.0, 0.75, 0.4, 0.35))
	ci.draw_circle(sun, 30.0, Color(1.0, 0.88, 0.6))
	for i in 4:   # עננים דקים צבועים
		var cx := fposmod(float(i) * 400.0 + t * 5.0, v.x + 400.0) - 200.0
		var cy := v.y * (0.2 + 0.08 * float(i % 3))
		ci.draw_colored_polygon(Art.ellipse(Vector2(cx, cy), 160.0, 9.0, 0.0, 14), Color(1.0, 0.6, 0.55, 0.35))
		ci.draw_colored_polygon(Art.ellipse(Vector2(cx + 50.0, cy + 7.0), 100.0, 5.0, 0.0, 12), Color(1.0, 0.8, 0.6, 0.3))
	for i in 9:   # עפיפונים
		var kx := fposmod(_h(i, 2) * v.x + sin(t * 0.3 + float(i)) * 40.0, v.x)
		var ky := v.y * (0.12 + 0.3 * _h(i, 3)) + sin(t * 0.8 + float(i) * 2.0) * 10.0
		kite(ci, Vector2(kx, ky), 0.8 + 0.4 * _h(i, 4), HOUSE_COLS[i % HOUSE_COLS.size()].lightened(0.15), t, i)


# ---- הר הסוכר, הקורקובדו עם ישו, המפרץ ----
static func far_rio(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	ci.draw_rect(Rect2(0, y - 30.0, v.x, v.y - y + 30.0), Color("4a3a6a"))   # המפרץ
	for i in 30:   # ניצוצות על המים
		var wx := fposmod(_h(i, 7) * v.x - sc * 0.2, v.x)
		ci.draw_line(Vector2(wx, y - 24.0 + float(i % 4) * 5.0), Vector2(wx + 10.0, y - 24.0 + float(i % 4) * 5.0), Color(1.0, 0.8, 0.5, 0.3 + 0.3 * sin(t * 2.0 + float(i))), 1.0)
	var period := 1800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הר הסוכר: כיפה מעוגלת
		var sl := Vector2(bx + 300.0, y - 30.0)
		var sug := PackedVector2Array()
		for q in 13:
			var a := PI + float(q) / 12.0 * PI
			sug.append(sl + Vector2(cos(a) * 70.0, sin(a) * 150.0 * (0.9 + 0.1 * cos(a))))
		ci.draw_colored_polygon(sug, Color("2e2448"))
		ci.draw_colored_polygon(Art.ellipse(sl + Vector2(-120, 0), 60.0, 40.0, 0.0, 12), Color("2e2448"))
		ci.draw_line(sl + Vector2(-120, -40), sl + Vector2(0, -148), Color(0.1, 0.08, 0.15, 0.6), 1.0)   # הרכבל
		# הקורקובדו + פסל ישו הגואל
		var cx := bx + 1100.0
		var peak := Vector2(cx, y - 260.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 340, y - 30), Vector2(cx - 120, y - 150), Vector2(cx - 30, y - 245), peak, Vector2(cx + 30, y - 240), Vector2(cx + 160, y - 120), Vector2(cx + 380, y - 30)]), Color("2a2244"))
		var st := peak + Vector2(0, -4)
		ci.draw_rect(Rect2(st + Vector2(-3, -10), Vector2(6, 10)), Color("e8e0f0"))   # בסיס
		ci.draw_rect(Rect2(st + Vector2(-2, -30), Vector2(4, 20)), Color("f0e8f8"))   # גוף
		ci.draw_rect(Rect2(st + Vector2(-18, -27), Vector2(36, 3)), Color("f0e8f8"))   # ידיים פרושות
		ci.draw_circle(st + Vector2(0, -33), 2.5, Color("f0e8f8"))
		Art.glow(ci, st + Vector2(0, -20), 40.0, Color(1.0, 0.95, 0.85, 0.15))
	for i in 50:   # אורות העיר לאורך החוף
		var lx := fposmod(_h(i, 11) * v.x * 1.5 - sc * 0.15, v.x)
		ci.draw_rect(Rect2(lx, y - 34.0 + _h(i, 12) * 6.0, 1.5, 1.5), Color(1.0, 0.85, 0.5, 0.5 + 0.4 * _h(i, 13)))


# ---- גבעת הפאבלה ----
static func mid_favela(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var col_w := 46.0
	var first := int(floor(sc / col_w)) - 1
	for k in range(first, first + int(ceil(v.x / col_w)) + 3):
		var x := float(k) * col_w - sc
		var top := y - 90.0 - _vn(float(k) * 0.08, 5) * 220.0   # פרופיל הגבעה
		ci.draw_rect(Rect2(x, top, col_w + 1.0, y - top + 4.0), Color("3a2a2a"))
		var yy := y
		var r := _rng(k * 37 + 1)
		while yy > top + 10.0:   # בתים מוערמים
			var hh := r.randf_range(22.0, 34.0)
			var c: Color = HOUSE_COLS[r.randi() % HOUSE_COLS.size()].darkened(0.35 + 0.2 * r.randf())
			var w := col_w - r.randf_range(0.0, 8.0)
			ci.draw_rect(Rect2(x + 1.0, yy - hh, w, hh - 1.0), c)
			ci.draw_line(Vector2(x + 1.0, yy - hh), Vector2(x + w + 1.0, yy - hh), c.lightened(0.15), 1.0)
			for q in 2:   # חלונות (חלקם דולקים)
				var wx := x + 6.0 + float(q) * (w * 0.5)
				var lit := _h(k * 13 + int(yy) + q, 3) < 0.35
				ci.draw_rect(Rect2(wx, yy - hh + 7.0, 7.0, 7.0), Color(1.0, 0.8, 0.45, 0.8 + 0.2 * sin(t + float(k))) if lit else Color(0.1, 0.08, 0.1, 0.8))
			yy -= hh
		if k % 3 == 0:   # מכל מים כחול על הגג העליון
			ci.draw_rect(Rect2(x + 10.0, yy - 10.0, 16.0, 11.0), Color("2a6aa8"))
			ci.draw_colored_polygon(Art.ellipse(Vector2(x + 18.0, yy - 10.0), 8.0, 2.0, 0.0, 8), Color("4a8ac8"))
		if k % 4 == 1:   # חוטים לעמוד הבא
			ci.draw_line(Vector2(x + 20.0, yy - 4.0), Vector2(x + 20.0 + col_w * 2.0, yy + 6.0), Color(0.08, 0.06, 0.08, 0.7), 1.0)
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("3a2a2a"))


# ---- חזיתות קרובות, מוטות ברזל וכביסה ----
static func near_houses(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 620.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x0 := float(k) * period - sc
		var r := _rng(k * 59 + 3)
		var x := x0
		while x < x0 + period:
			var w := r.randf_range(90.0, 150.0)
			var h := r.randf_range(70.0, 130.0)
			var c: Color = HOUSE_COLS[r.randi() % HOUSE_COLS.size()].darkened(0.55)
			ci.draw_rect(Rect2(x, y - h, w - 4.0, h), c)
			if r.randf() < 0.5:   # לבנים חשופות
				for q in int(h / 10.0):
					ci.draw_line(Vector2(x, y - h + float(q) * 10.0), Vector2(x + w - 4.0, y - h + float(q) * 10.0), c.darkened(0.25), 1.0)
			for q in 3:   # מוטות ברזל בולטים מהגג
				ci.draw_line(Vector2(x + 8.0 + float(q) * 14.0, y - h), Vector2(x + 8.0 + float(q) * 14.0, y - h - 12.0), Color("2a1e1a"), 1.5)
			ci.draw_rect(Rect2(x + w * 0.5, y - h * 0.6, 14.0, 16.0), Color(1.0, 0.75, 0.4, 0.6) if r.randf() < 0.4 else Color("141014"))
			if r.randf() < 0.45:   # חבל כביסה
				var ly := y - h + 20.0
				ci.draw_line(Vector2(x + 4.0, ly), Vector2(x + w - 8.0, ly + 4.0), Color("1a1418"), 1.0)
				for q in 4:
					var cx := x + 12.0 + float(q) * (w - 24.0) / 4.0
					var sw := sin(t * 2.5 + float(q) + float(k)) * 2.0
					ci.draw_colored_polygon(PackedVector2Array([Vector2(cx, ly + 1.0), Vector2(cx + 10.0, ly + 2.0), Vector2(cx + 9.0 + sw, ly + 14.0), Vector2(cx + 1.0 + sw, ly + 13.0)]), HOUSE_COLS[(q + k) % HOUSE_COLS.size()].darkened(0.3))
			x += w
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("2a1e22"))


# ---- רחוב הפאבלה ----
class FavelaGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		draw_rect(Rect2(0, 0, w, depth), Color("4a4240"))
		draw_rect(Rect2(0, 0, w, 8.0), Color("7a706a"))
		for i in int(w / 30.0):   # סדקים ותיקונים
			var x := r.randf_range(0.0, w)
			draw_line(Vector2(x, 1), Vector2(x + r.randf_range(-12.0, 12.0), 7), Color("5a5250"), 1.0)
		for i in int(w / 200.0):
			draw_rect(Rect2(r.randf_range(0.0, w - 60.0), 1.0, r.randf_range(30.0, 60.0), 6.0), Color("6a6260"))
		draw_rect(Rect2(0, 12, w, 6), Color("2a2426"))   # תעלת ניקוז
		for i in int(w / 18.0):
			draw_line(Vector2(float(i) * 18.0, 12), Vector2(float(i) * 18.0, 18), Color("4a4240"), 2.0)


# ---- בית עם לאז'ה (גג שטוח = קומה) ----
class Laje extends Node2D:
	var w := 240.0
	var tier := 130.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s37_decor.gd")
		var bare := r.randf() < 0.5
		var c: Color = Color("a0522d") if bare else S.HOUSE_COLS[r.randi() % S.HOUSE_COLS.size()].darkened(0.1)
		draw_rect(Rect2(0, -tier, w, tier), c)
		if bare:   # לבנים חשופות
			var y := -tier
			var row := 0
			while y < -2.0:
				draw_line(Vector2(0, y), Vector2(w, y), c.darkened(0.3), 1.0)
				var off := 0.0 if row % 2 == 0 else 10.0
				var x := off
				while x < w:
					draw_line(Vector2(x, y), Vector2(x, y + 8.0), c.darkened(0.3), 1.0)
					x += 20.0
				y += 8.0
				row += 1
		else:   # טיח צבעוני מתקלף
			for q in 4:
				draw_rect(Rect2(r.randf_range(0.0, w - 30.0), -r.randf_range(20.0, tier - 10.0), r.randf_range(14.0, 30.0), r.randf_range(8.0, 14.0)), Color("a0522d").darkened(0.1))
		draw_rect(Rect2(w * 0.12, -64, 30, 64), Color("3a2a22"))   # דלת
		draw_rect(Rect2(w * 0.12 + 2, -62, 26, 60), Color("6a4a32"))
		for q in 2:   # חלונות עם סורגים
			var wx := w * (0.5 + 0.25 * float(q))
			draw_rect(Rect2(wx - 14, -tier + 26, 28, 24), Color(1.0, 0.78, 0.45, 0.85) if r.randf() < 0.5 else Color("1e1618"))
			for b in 4:
				draw_line(Vector2(wx - 14 + float(b) * 9.0, -tier + 26), Vector2(wx - 14 + float(b) * 9.0, -tier + 50), Color("2a2a2a"), 1.2)
		draw_rect(Rect2(-4, -tier - 4, w + 8, 6), Color("8a8078"))   # שפת הגג
		for q in int(w / 40.0):   # מוטות ברזל
			draw_line(Vector2(10.0 + float(q) * 40.0, -tier - 4), Vector2(10.0 + float(q) * 40.0, -tier - 18), Color("5a3a2a"), 1.6)


# ---- חוט חשמל גנוב ("גאטו") ----
class LiveWire extends Node2D:
	const CYCLE := Vector2(4.0, 6.5)
	const WARN_T := 0.9
	const ARC_T := 0.7
	const DMG_Z := 15
	var w := 260.0                  # המרחק בין העמודים
	var pole_h := 170.0
	var state := 0                  # 0 = שקט, 1 = ניצוצות (אזהרה), 2 = קשת
	var dead_wire := false          # נותק (ירו בקופסה)
	var arcs := 0                   # לבדיקות
	var hits := 0
	var zhits := 0
	var _t := 2.0
	var _st := 0.0
	var _hit := false
	var _box: StaticBody2D = null

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")
		_box = Box.new()
		_box.owner_w = self
		_box.collision_layer = 4
		_box.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(16, 18)
		cs.shape = sh
		_box.add_child(cs)
		add_child(_box)
		_box.position = Vector2(10, -pole_h * 0.62)

	func sag_y(x: float) -> float:   # גובה החוט (מקומי) בנקודה x
		var u := clampf(x / w, 0.0, 1.0)
		return -pole_h + 12.0 + 4.0 * u * (1.0 - u) * (pole_h - 60.0)

	func arc_x0() -> float:
		return global_position.x + w * 0.25

	func arc_x1() -> float:
		return global_position.x + w * 0.75

	func world_rect() -> Rect2:
		return Rect2(Vector2(arc_x0(), global_position.y - 80.0), Vector2(arc_x1() - arc_x0(), 80.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != 0 and not dead_wire and world_rect().grow(margin).has_point(p)

	func cut() -> void:   # ירו בקופסה - קצר
		if dead_wire:
			return
		dead_wire = true
		state = 0
		preload("res://sfx.gd").play("fv_short", _box.global_position, 2.0, 0.05, 2)
		preload("res://particles.gd").burst(get_parent(), _box.global_position, "spark", Vector2.UP, 24)
		preload("res://particles.gd").burst(get_parent(), _box.global_position, "smoke", Vector2.UP, 6)
		for zz in get_tree().get_nodes_in_group("zombies"):
			if not zz.dead and not zz.is_boss() and zz.global_position.distance_to(_box.global_position) < 130.0:
				zz.take_damage(20, zz.global_position + Vector2(0, -30), Vector2(0, -1), false, {"source": "electric", "fixed": 20})
		_box.collision_layer = 0
		queue_redraw()

	func _physics_process(delta: float) -> void:
		if dead_wire:
			return
		_t -= delta
		match state:
			0:
				if _t <= 0.0:
					state = 1
					_st = WARN_T
					if Art.on_screen(self, global_position + Vector2(w * 0.5, -60.0), w):
						preload("res://sfx.gd").play("fv_buzz", global_position + Vector2(w * 0.5, -80.0), -2.0, 0.1, 2)
			1:
				_st -= delta
				if Engine.get_physics_frames() % 4 == 0:
					preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(w * 0.25, w * 0.75), sag_y(w * 0.5) + 6.0), "spark", Vector2.DOWN, 1)
				if _st <= 0.0:
					state = 2
					_st = ARC_T
					arcs += 1
					_hit = false
					if Art.on_screen(self, global_position + Vector2(w * 0.5, -60.0), w):
						preload("res://sfx.gd").play("fv_zap", global_position + Vector2(w * 0.5, -40.0), 2.0, 0.05, 2)
					for pd in get_tree().get_nodes_in_group("puddles"):   # שלולית מתחת? מחשמלים אותה
						if pd.x1() > arc_x0() and pd.x0() < arc_x1() and absf(pd.global_position.y - global_position.y) < 20.0:
							pd.shock()
			2:
				_st -= delta
				var pl := get_tree().get_first_node_in_group("player")
				if not _hit and pl != null and not pl.dead and pl.global_position.x > arc_x0() and pl.global_position.x < arc_x1() and pl.global_position.y > global_position.y - 70.0:
					_hit = true
					hits += 1
					pl.hurt(1, Vector2(0.0, -1.2))
				if Engine.get_physics_frames() % 15 == 0:
					for zz in get_tree().get_nodes_in_group("zombies"):
						if not zz.dead and not zz.is_boss() and zz.global_position.x > arc_x0() and zz.global_position.x < arc_x1() and absf(zz.global_position.y - global_position.y) < 30.0:
							zhits += 1
							zz.take_damage(DMG_Z, zz.global_position + Vector2(0, -30), Vector2(0, -1), false, {"source": "electric", "fixed": DMG_Z})
				if _st <= 0.0:
					state = 0
					_t = randf_range(CYCLE.x, CYCLE.y)
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -60.0), w):
			queue_redraw()

	func _draw() -> void:
		for px in [0.0, w]:   # עמודים
			draw_line(Vector2(px, 0), Vector2(px, -pole_h), Color("3a3230"), 5.0)
			draw_line(Vector2(px - 10, -pole_h + 8), Vector2(px + 10, -pole_h + 8), Color("3a3230"), 3.0)
		# החוטים המסובכים
		for q in 4:
			var pts := PackedVector2Array()
			for i in 13:
				var x := float(i) / 12.0 * w
				pts.append(Vector2(x, sag_y(x) + float(q) * 5.0 + sin(float(i) * 1.7 + float(q)) * 2.0))
			draw_polyline(pts, Color("141012"), 1.4)
		for q in 3:   # סבך חוטים ליד העמוד
			draw_arc(Vector2(14, -pole_h + 18 + float(q) * 5.0), 8.0 + float(q) * 3.0, 0.3, 4.5, 8, Color("141012"), 1.0)
		# הקופסה (מטרה)
		var bp := Vector2(10, -pole_h * 0.62)
		draw_rect(Rect2(bp - Vector2(8, 9), Vector2(16, 18)), Color("5a6a5a") if not dead_wire else Color("2a2a2a"))
		draw_rect(Rect2(bp - Vector2(8, 9), Vector2(16, 18)), Color("1a1a1a"), false, 1.2)
		if not dead_wire:
			draw_circle(bp + Vector2(0, -3), 2.0, Color(1.0, 0.3, 0.2) if state > 0 else Color(0.3, 1.0, 0.4))
			draw_colored_polygon(PackedVector2Array([bp + Vector2(1, -1), bp + Vector2(-2, 3), bp + Vector2(0, 3), bp + Vector2(-1, 7), bp + Vector2(3, 2), bp + Vector2(1, 2)]), Color(1.0, 0.85, 0.2))   # סימן ברק
		if dead_wire:
			return
		var mid := w * 0.5
		if state == 1:   # ניצוצות לאורך החוט + פס צהוב על הקרקע
			for q in 4:
				var sx := randf_range(w * 0.25, w * 0.75)
				draw_circle(Vector2(sx, sag_y(sx) + 6.0), 2.0, Color(1.0, 0.95, 0.6))
			draw_rect(Rect2(w * 0.25, -3, w * 0.5, 3), Color(1.0, 0.85, 0.2, 0.3 + 0.3 * sin(_st * 30.0)))
		elif state == 2:   # קשתות חשמל לקרקע
			for q in 3:
				var sx := lerpf(w * 0.28, w * 0.72, (float(q) + randf() * 0.5) / 3.0)
				var pts := PackedVector2Array()
				var top := Vector2(sx, sag_y(sx) + 8.0)
				for i in 8:
					var u := float(i) / 7.0
					pts.append(top.lerp(Vector2(sx + randf_range(-30, 30), 0), u) + Vector2(randf_range(-8, 8) if i > 0 and i < 7 else 0.0, 0))
				draw_polyline(pts, Color(0.6, 0.85, 1.0, 0.5), 5.0)
				draw_polyline(pts, Color(1, 1, 1, 0.95), 1.6)
			Art.glow(self, Vector2(mid, -6), 60.0, Color(0.5, 0.75, 1.0, 0.3))

	class Box extends StaticBody2D:
		var owner_w = null

		func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
			if owner_w != null:
				owner_w.cut()


# ---- שלולית (ממכל שנשפך) ----
class Puddle extends Node2D:
	const LIFE := 7.0
	const SHOCK_DMG := 20
	var w := 220.0
	var shocks := 0                 # לבדיקות
	var _t := 0.0
	var _shock := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("puddles")

	func x0() -> float:
		return global_position.x - w * 0.5

	func x1() -> float:
		return global_position.x + w * 0.5

	func shock() -> void:
		shocks += 1
		_shock = 0.6
		preload("res://sfx.gd").play("fv_zap", global_position, 3.0, 0.05, 2)
		for zz in get_tree().get_nodes_in_group("zombies"):
			if not zz.dead and not zz.is_boss() and zz.global_position.x > x0() and zz.global_position.x < x1() and absf(zz.global_position.y - global_position.y) < 30.0:
				zz.take_damage(SHOCK_DMG, zz.global_position + Vector2(0, -20), Vector2(0, -1), false, {"source": "electric", "fixed": SHOCK_DMG})
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.is_on_floor() and pl.global_position.x > x0() and pl.global_position.x < x1() and absf(pl.global_position.y - global_position.y) < 20.0:
			pl.hurt(1, Vector2(0.0, -1.0))

	func _process(delta: float) -> void:
		_t += delta
		_shock = maxf(_shock - delta, 0.0)
		if _t > LIFE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf((LIFE - _t) / 1.5, 0.0, 1.0)
		draw_colored_polygon(Art.ellipse(Vector2(0, -1), w * 0.5, 4.0, 0.0, 18), Color(0.45, 0.6, 0.8, 0.55 * a))
		draw_line(Vector2(-w * 0.3, -2), Vector2(w * 0.1, -2), Color(1, 0.85, 0.7, 0.4 * a), 1.0)
		if _shock > 0.0:
			for q in 6:
				var x := randf_range(-w * 0.45, w * 0.45)
				draw_polyline(PackedVector2Array([Vector2(x, -1), Vector2(x + randf_range(-8, 8), -10), Vector2(x + randf_range(-8, 8), -18)]), Color(0.7, 0.9, 1.0, _shock), 1.5)
			draw_colored_polygon(Art.ellipse(Vector2(0, -1), w * 0.5, 5.0, 0.0, 18), Color(0.6, 0.85, 1.0, 0.4 * _shock / 0.6))


# ---- מכל מים כחול על גג ----
class WaterTank extends Node2D:
	const HP := 3
	var hp := HP
	var tipped := false
	var floor_y := 630.0
	var knocked := 0                # לבדיקות
	var _t := 0.0
	var _pour := 0.0
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 2
		_body = Tank.new()
		_body.owner_t = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(34, 30)
		cs.shape = sh
		cs.position = Vector2(0, -15)
		_body.add_child(cs)
		add_child(_body)

	func hit() -> void:
		if tipped:
			return
		hp -= 1
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -16), "drop", Vector2.UP, 6)
		if hp <= 0:
			_tip()

	func _tip() -> void:
		tipped = true
		_pour = 1.2
		_body.collision_layer = 0
		preload("res://sfx.gd").play("fv_splash", global_position, 2.0, 0.05, 2)
		var pd := Puddle.new()
		get_parent().add_child(pd)
		pd.global_position = Vector2(global_position.x, floor_y)
		for zz in get_tree().get_nodes_in_group("zombies"):   # הגל שוטף אותם
			if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - global_position.x) < 150.0 and absf(zz.global_position.y - floor_y) < 40.0:
				knocked += 1
				var d := signf(zz.global_position.x - global_position.x + 0.01)
				zz.velocity = Vector2(d * 420.0, -200.0)
				zz.take_damage(6, zz.global_position + Vector2(0, -20), Vector2(d, 0), false, {"source": "water", "fixed": 6})

	func _process(delta: float) -> void:
		_t += delta
		if _pour > 0.0:
			_pour -= delta
			if Engine.get_process_frames() % 3 == 0:
				preload("res://particles.gd").burst(get_parent(), Vector2(global_position.x + randf_range(-20, 20), floor_y - 4.0), "drop", Vector2.UP, 3)
			queue_redraw()

	func _draw() -> void:
		if tipped:   # מכל הפוך + מפל מים
			draw_colored_polygon(PackedVector2Array([Vector2(-18, -4), Vector2(14, -14), Vector2(20, -2), Vector2(-14, 6)]), Color("2a5a98"))
			if _pour > 0.0:
				var a := clampf(_pour / 1.2, 0.0, 1.0)
				draw_rect(Rect2(-14, 0, 28, floor_y - global_position.y), Color(0.55, 0.75, 0.95, 0.6 * a))
				for q in 4:
					draw_line(Vector2(-10.0 + float(q) * 7.0, 0), Vector2(-10.0 + float(q) * 7.0, floor_y - global_position.y), Color(0.85, 0.95, 1.0, 0.6 * a), 1.2)
			return
		Art.fill_shaded(self, PackedVector2Array([Vector2(-17, 0), Vector2(17, 0), Vector2(19, -28), Vector2(-19, -28)]), Color("2a6ab0"), 0.2, 0.4, Art.OUTLINE, 1.2)
		draw_colored_polygon(Art.ellipse(Vector2(0, -28), 19.0, 4.0, 0.0, 12), Color("4a8ad0"))
		for q in 3:
			draw_line(Vector2(-17, -7.0 - float(q) * 8.0), Vector2(17, -7.0 - float(q) * 8.0), Color("1e4a80"), 1.0)
		if hp < HP:   # סדקים ודליפה
			draw_line(Vector2(-6, -18), Vector2(2, -10), Color("0e2a50"), 1.4)
			draw_line(Vector2(4, -6), Vector2(4, 4 + fposmod(_t * 30.0, 10.0)), Color(0.6, 0.8, 1.0, 0.8), 1.5)

	class Tank extends StaticBody2D:
		var owner_t = null

		func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
			if owner_t != null:
				owner_t.hit()


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "moto"
	var size := Vector2(80, 40)
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
		var S := preload("res://effects/s37_decor.gd")
		match kind:
			"moto":   # מוטו-טקסי חונה
				var c: Color = S.HOUSE_COLS[r.randi() % S.HOUSE_COLS.size()]
				for wx in [w * 0.18, w * 0.82]:
					draw_circle(Vector2(wx, -10), 10.0, Color("1a1a1a"))
					draw_circle(Vector2(wx, -10), 4.0, Color("8a8a8a"))
				Art.fill_shaded(self, PackedVector2Array([Vector2(w * 0.2, -14), Vector2(w * 0.75, -14), Vector2(w * 0.85, -h * 0.6), Vector2(w * 0.55, -h * 0.75), Vector2(w * 0.3, -h * 0.6)]), c, 0.15, 0.35, Art.OUTLINE, 1.2)
				draw_rect(Rect2(w * 0.28, -h * 0.82, w * 0.3, 6), Color("1e1e1e"))   # מושב
				draw_line(Vector2(w * 0.8, -h * 0.65), Vector2(w * 0.9, -h), Color("3a3a3a"), 2.5)   # כידון
				draw_line(Vector2(w * 0.84, -h), Vector2(w * 0.98, -h), Color("3a3a3a"), 2.5)
				draw_rect(Rect2(w * 0.06, -h * 0.75, w * 0.18, h * 0.3), Color("e0c040"))   # ארגז משלוחים
			"trash_bags":   # ערמת שקיות זבל
				for q in 5:
					var cx := w * (0.15 + 0.18 * float(q)) + r.randf_range(-4.0, 4.0)
					var cy := -h * (0.3 if q % 2 == 0 else 0.6)
					Art.oval_shaded(self, Vector2(cx, cy), w * 0.16, h * 0.32, Color("1e1e22").lerp(Color("2a3a2a"), r.randf()), r.randf_range(-0.3, 0.3))
					draw_line(Vector2(cx - 2, cy - h * 0.3), Vector2(cx + 3, cy - h * 0.38), Color("e0c040"), 1.5)
			_:   # שולחן בוטקו וארגזי בירה
				for q in 2:
					Art.fill(self, PackedVector2Array([Vector2(4.0 + float(q) * 4.0, -float(q) * h * 0.38), Vector2(w * 0.4 + float(q) * 4.0, -float(q) * h * 0.38), Vector2(w * 0.4 + float(q) * 4.0, -h * 0.38 - float(q) * h * 0.38), Vector2(4.0 + float(q) * 4.0, -h * 0.38 - float(q) * h * 0.38)]), Color("d0a020") if q == 0 else Color("c03020"), Art.OUTLINE, 1.0)
				Art.fill(self, PackedVector2Array([Vector2(w * 0.48, -h * 0.75), Vector2(w - 2, -h * 0.75), Vector2(w - 2, -h * 0.68), Vector2(w * 0.48, -h * 0.68)]), Color("f0f0f0"), Art.OUTLINE, 1.0)   # שולחן פלסטיק
				draw_line(Vector2(w * 0.55, -h * 0.68), Vector2(w * 0.52, 0), Color("e0e0e0"), 2.0)
				draw_line(Vector2(w * 0.92, -h * 0.68), Vector2(w * 0.95, 0), Color("e0e0e0"), 2.0)
				for q in 3:   # בקבוקים
					draw_rect(Rect2(w * 0.6 + float(q) * 8.0, -h * 0.75 - 12.0, 4, 12), Color("3a6a2a"))


# ---- אובך שקיעה חם (מסך) ----
class FavelaFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		for i in 14:   # אבק שמנצנץ באור
			var x := fposmod(float(i) * 113.0 + _t * 8.0, vp.x)
			var y := fposmod(float(i) * 71.0 - _t * 5.0, vp.y)
			draw_rect(Rect2(x, y, 1.5, 1.5), Color(1.0, 0.85, 0.6, 0.35))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(1.0, 0.6, 0.3, 0.05))
