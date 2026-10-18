extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 27 ("PLATEAU GATE") - מחסום צבאי מבוצר בקצה הרמה, עם שחר. סוף האזור השלישי.
#  מתחילים ביציאה מהמנהרה של הבונקר (שלב 26), ונגמרים בשער הענק - שם ה-GENERAL מחכה.
#    dawn_sky      - (רקע) שחר ורוד-כתום, שמש עולה, פסי ערפל
#    far_andes     - (רקע) קצה הרמה + הרי האנדים המושלגים באופק (האזור הבא!)
#    mid_wall      - (רקע) חומת גבול ארוכה עם מגדלי שמירה, תיל, דגלים, פנסים
#    near_wire     - (רקע) "קיפודים" נגד טנקים, גדר תיל, שקי חול
#    GateGround    - (עולם) עפר דחוס, עקבות צמיגים, בוץ
#    TunnelExit    - (עולם) פתח המנהרה מהבונקר בתחילת השלב ("BUNKER B-2")
#    Watchtower    - (עולם) מגדל שמירה (הקומה עצמה = add_floor) + זרקור (Searchlight)
#    Searchlight   - (עולם, מלכודת) אלומה שסורקת את הקרקע. אתה באור -> "SPOTTED!" -> פגז ארטילריה עליך
#                    (enemies/types/general.gd Shell: עיגול אזהרה + שריקה + פיצוץ) + כל הזומבים שומעים.
#    Obstacle      - (מוצק + מחסה) "sandbags" שקי חול / "hedgehog" קיפוד פלדה / "jeep" ג'יפ שרוף
#    GreatGate     - (עולם) השער הענק בסוף השלב (מאחורי היציאה). נפתח כשה-GENERAL מת.
#    GateFX        - (מסך) ערפל בוקר ואבק
#  לשנות: Searchlight.SWEEP, Searchlight.CD, Searchlight.SPOT_R.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const DIRT := Color("6a5a44")
const DIRT_D := Color("4a3e2e")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- שחר ----
static func dawn_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("2a3050"), Color("6a4a6a"), Color("c87060"), Color("f0a868"), Color("f8d090")], 0.8)
	var sun := Vector2(v.x * 0.3, v.y * 0.62)
	for i in 4:
		DrawBatch.circle(ci, sun, 130.0 - float(i) * 28.0, Color(1.0, 0.85, 0.55, 0.08 + 0.05 * float(i)))
	DrawBatch.circle(ci, sun, 34.0, Color("fff0c0"))
	for i in 3:
		var y := v.y * (0.3 + 0.08 * float(i))
		var x := fposmod(t * (4.0 + float(i) * 2.0) + float(i) * 500.0, v.x + 900.0) - 450.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(x, y), Vector2(x + 400, y - 8), Vector2(x + 800, y), Vector2(x + 400, y + 6)]), Color(0.95, 0.75, 0.7, 0.35))


# ---- הרי האנדים באופק + קצה הרמה ----
static func far_andes(ci: CanvasItem, sc: float, v: Vector2, y: float, _t: float) -> void:
	var period := 1800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 37 + 1)
		for m in 4:   # פסגות מושלגות
			var mx := x + float(m) * 450.0 + r.randf_range(-60.0, 60.0)
			var mh := r.randf_range(160.0, 260.0)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(mx - 260, y), Vector2(mx, y - mh), Vector2(mx + 260, y)]), Color("6a6a8a"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(mx - 70, y - mh + 70), Vector2(mx, y - mh), Vector2(mx + 70, y - mh + 70), Vector2(mx + 30, y - mh + 56), Vector2(mx, y - mh + 74), Vector2(mx - 30, y - mh + 58)]), Color("f0e8f0"))
	DrawBatch.rect(ci, Rect2(0, y - 30.0, v.x, 30.0), Color(0.95, 0.8, 0.75, 0.35))   # ערפל בעמק
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("5a4a50"))


# ---- חומת הגבול ----
static func mid_wall(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var wall := Color("4a4048")
	var dark := Color("2e282e")
	DrawBatch.rect(ci, Rect2(0, y - 120, v.x, 120), wall)
	DrawBatch.rect(ci, Rect2(0, y - 128, v.x, 8), dark)
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		for s in 6:   # לוחות בטון
			DrawBatch.line(ci, Vector2(x + float(s) * 150.0, y - 120), Vector2(x + float(s) * 150.0, y), dark, 2.0)
		for c in 18:   # תיל על החומה
			DrawBatch.arc(ci, Vector2(x + float(c) * 50.0 + 25.0, y - 136), 9.0, 0.0, TAU, 8, dark, 1.2)
		var tx := x + 450.0   # מגדל שמירה
		DrawBatch.rect(ci, Rect2(tx - 30, y - 250, 60, 130), dark)
		DrawBatch.rect(ci, Rect2(tx - 40, y - 262, 80, 16), dark)
		DrawBatch.rect(ci, Rect2(tx - 22, y - 236, 44, 18), Color(1.0, 0.85, 0.5, 0.3))
		var a := sin(t * 0.6 + float(k)) * 0.6   # זרקור רחוק
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(tx, y - 236), Vector2(tx + sin(a) * 300.0 - 40.0, y - 40), Vector2(tx + sin(a) * 300.0 + 40.0, y - 40)]), Color(1.0, 0.95, 0.75, 0.05))
		DrawBatch.line(ci, Vector2(tx + 34, y - 262), Vector2(tx + 34, y - 320), dark, 2.0)   # דגל
		var wv := sin(t * 3.0 + float(k)) * 4.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(tx + 34, y - 320), Vector2(tx + 64, y - 314 + wv), Vector2(tx + 34, y - 302)]), Color("8a2a24"))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), dark)


# ---- קיפודים, תיל, שקי חול ----
static func near_wire(ci: CanvasItem, sc: float, v: Vector2, y: float, _t: float) -> void:
	var col := Color("1c1618")
	var period := 700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 19 + 4)
		for h in 2:   # קיפוד נגד טנקים
			var hx := x + r.randf_range(50.0, 650.0)
			DrawBatch.line(ci, Vector2(hx - 22, y), Vector2(hx + 22, y - 40), col, 5.0)
			DrawBatch.line(ci, Vector2(hx + 22, y), Vector2(hx - 22, y - 40), col, 5.0)
			DrawBatch.line(ci, Vector2(hx, y + 2), Vector2(hx, y - 44), col, 5.0)
		var wx := x + r.randf_range(0.0, 400.0)   # גדר תיל
		for c in 10:
			DrawBatch.arc(ci, Vector2(wx + float(c) * 22.0, y - 14), 11.0, 0.0, TAU, 8, col, 1.4)
		for s in 6:   # שורת שקי חול
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(x + 520.0 + float(s) * 24.0, y - 8), 13.0, 8.0, 0.0, 10), col)
	DrawBatch.rect(ci, Rect2(0, y - 2.0, v.x, v.y - y + 2.0), col)


# ---- עפר דחוס ----
class GateGround extends Node2D:
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
		var S := preload("res://effects/s27_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), S.DIRT_D)
		DrawBatch.rect(self, Rect2(0, 0, w, 9.0), S.DIRT)
		for i in 2:   # עקבות צמיגים
			var ty := 3.0 + float(i) * 3.0
			var x := 0.0
			while x < w:
				DrawBatch.line(self, Vector2(x, ty), Vector2(x + 6.0, ty), Color(0, 0, 0, 0.25), 2.0)
				x += 12.0
		for i in int(w / 240.0):   # בוץ
			var px := r.randf_range(0.0, w - 60.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(px, 4), r.randf_range(16.0, 34.0), 3.0), Color(0.3, 0.24, 0.18, 0.7))
		for i in int(w / 14.0):   # אבנים
			DrawBatch.circle(self, Vector2(r.randf_range(0.0, w), r.randf_range(12.0, depth - 6.0)), r.randf_range(1.0, 2.5), Color(0.5, 0.42, 0.32, 0.5))


# ---- היציאה מהמנהרה של הבונקר (תחילת השלב) ----
class TunnelExit extends Node2D:
	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-200, 0), Vector2(-200, -230), Vector2(-60, -280), Vector2(120, -250), Vector2(240, -120), Vector2(300, 0)]), Color("5a4a3a"))   # גבעה
		DrawBatch.rect(self, Rect2(-40, -190, 220, 190), Color("6a6e68"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-20, 0), Vector2(-20, -140), Vector2(10, -170), Vector2(130, -170), Vector2(160, -140), Vector2(160, 0)]), Color("0a0c0a"))
		for q in 5:
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-40 + float(q) * 44.0, -190), Vector2(-18 + float(q) * 44.0, -190), Vector2(4 + float(q) * 44.0, -168), Vector2(-18 + float(q) * 44.0, -168)]), Color("d8b030"))
		DrawBatch.rect(self, Rect2(10, -186, 120, 14), Color("2a2e2a"))
		DrawBatch.rect(self, Rect2(16, -183, 50, 8), Color(0.85, 0.85, 0.75, 0.7))   # "BUNKER B-2"
		DrawBatch.rect(self, Rect2(72, -183, 30, 8), Color(0.85, 0.85, 0.75, 0.7))
		for i in 4:   # אור חם מבפנים (נורות החירום)
			DrawBatch.circle(self, Vector2(70, -60), 60.0 - float(i) * 12.0, Color(1.0, 0.2, 0.1, 0.03 + 0.02 * float(i)))
		DrawBatch.line(self, Vector2(60, -2), Vector2(240, -2), Color(0.3, 0.25, 0.2, 0.6), 3.0)   # עקבות מגפיים (הגנרל ברח לכאן)
		for i in 8:
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(180.0 + float(i) * 34.0, -1.0), 4.0, 1.5), Color(0.15, 0.12, 0.1, 0.7))


# ---- מגדל שמירה (רגליים, גג, שקי חול). הקומה עצמה נוספת ב-stage (add_floor) ----
class Watchtower extends Node2D:
	var h := 180.0
	var w := 120.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var wood := Color("5a4632")
		for lx in [6.0, w - 6.0]:
			DrawBatch.line(self, Vector2(lx, 0), Vector2(lx + (8.0 if lx < 50.0 else -8.0), -h), wood, 6.0)
		for q in 3:
			var y0 := -h * float(q) / 3.0
			var y1 := -h * float(q + 1) / 3.0
			DrawBatch.line(self, Vector2(8, y0), Vector2(w - 8, y1), wood, 2.5)
			DrawBatch.line(self, Vector2(w - 8, y0), Vector2(8, y1), wood, 2.5)
		for s in 5:   # שקי חול על המעקה
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(10.0 + float(s) * 25.0, -h - 8.0), 13.0, 8.0, 0.0, 10), Color("8a7a5a"))
		DrawBatch.line(self, Vector2(4, -h - 16), Vector2(4, -h - 70), wood, 4.0)
		DrawBatch.line(self, Vector2(w - 4, -h - 16), Vector2(w - 4, -h - 70), wood, 4.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-14, -h - 66), Vector2(w + 14, -h - 66), Vector2(w * 0.5, -h - 96)]), Color("4a3a2a"))


# ---- זרקור: סורק, ואם אתה באור - ארטילריה ----
class Searchlight extends Node2D:
	const SWEEP := 260.0         # כמה רחוק לכל צד הוא סורק
	const SPEED := 0.55
	const SPOT_R := 46.0
	const CD := 3.5
	var ground_y := 180.0        # כמה מתחת לזרקור הקרקע
	var spotted := 0             # לבדיקות
	var active := true
	var _t := 0.0
	var _cd := 0.0
	var _lock := 0.0
	var _lock_x := 0.0

	func _ready() -> void:
		z_index = 5
		_t = randf() * 10.0

	func spot_x() -> float:   # מרכז האלומה על הקרקע (גלובלי)
		if _lock > 0.0:
			return _lock_x
		return global_position.x + sin(_t * SPEED) * SWEEP

	func _physics_process(delta: float) -> void:
		_t += delta
		_cd -= delta
		_lock -= delta
		var pl := get_tree().get_first_node_in_group("player")
		if not active or pl == null or pl.dead:
			queue_redraw()
			return
		if _lock > 0.0:
			_lock_x = move_toward(_lock_x, pl.global_position.x, 140.0 * delta)   # עוקב אחריך לאט
		var gy := global_position.y + ground_y
		if _cd <= 0.0 and absf(pl.global_position.x - spot_x()) < SPOT_R and absf(pl.global_position.y - gy) < 160.0:
			_cd = CD
			spotted += 1
			_lock = 1.4
			_lock_x = pl.global_position.x
			pl._say("SPOTTED!", Color("ffe080"))
			Sfx.play("s27_siren", global_position, 2.0, 0.0, 2)
			Game.make_noise(pl.global_position, 900.0)
			var top := Vector2(pl.global_position.x, pl.global_position.y - 60.0)
			var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(top, top + Vector2(0, 600), 1 | 16))
			var sh = preload("res://enemies/types/general.gd").Shell.new()
			sh.delay = 1.3
			get_parent().add_child(sh)
			sh.global_position = hit.position if hit else pl.global_position
		if Art.on_screen(self, global_position, 400.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var sx := spot_x() - global_position.x
		var lit := _lock > 0.0
		var c := Color(1.0, 0.95, 0.7, 0.16 if not lit else 0.26)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-4, 0), Vector2(4, 0), Vector2(sx + SPOT_R, ground_y), Vector2(sx - SPOT_R, ground_y)]), c)
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(sx, ground_y - 2.0), SPOT_R, 8.0, 0.0, 16), Color(1.0, 0.95, 0.7, 0.3 if not lit else 0.5))
		var a := atan2(ground_y, sx)
		DrawBatch.set_transform(self, Vector2.ZERO, a - PI * 0.5, Vector2.ONE)
		DrawBatch.rect(self, Rect2(-7, -10, 14, 16), Color("3a3a3e"))
		DrawBatch.circle(self, Vector2(0, 6), 6.0, Color(1.0, 0.95, 0.75))
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
		if lit:
			DrawBatch.circle(self, Vector2(0, -16), 4.0, Color(1.0, 0.2, 0.1, 0.9 if fmod(_t * 8.0, 1.0) < 0.5 else 0.3))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "bags"
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
		var w := size.x
		var h := size.y
		match kind:
			"bags":   # 3 שורות שקי חול
				var rows := 3
				var bh := h / float(rows)
				for row in rows:
					var n := int(w / 24.0) - row
					for i in n:
						var cx := (w - float(n) * 24.0) * 0.5 + 12.0 + float(i) * 24.0
						var cy := -bh * 0.5 - float(row) * bh
						Art.oval_shaded(self, Vector2(cx, cy), 13.0, bh * 0.55, Color("a8946a"), 0.0, Art.OUTLINE, 1.1)
			"hedgehog":   # קיפוד פלדה
				var c := Vector2(w * 0.5, -h * 0.5)
				for a in [0.8, -0.8]:
					var d := Vector2.from_angle(a) * h * 0.62
					DrawBatch.line(self, c - d, c + d, Art.OUTLINE, 9.0)
					DrawBatch.line(self, c - d, c + d, Color("4a4a4e"), 6.0)
				DrawBatch.line(self, Vector2(w * 0.5, 0), Vector2(w * 0.5, -h), Art.OUTLINE, 9.0)
				DrawBatch.line(self, Vector2(w * 0.5, 0), Vector2(w * 0.5, -h), Color("5a5a5e"), 6.0)
				DrawBatch.circle(self, c, 5.0, Color("3a2a1a"))
			_:   # ג'יפ שרוף
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, -10), Vector2(0, -h * 0.6), Vector2(w * 0.25, -h * 0.62), Vector2(w * 0.32, -h), Vector2(w * 0.4, -h), Vector2(w * 0.45, -h * 0.62), Vector2(w, -h * 0.6), Vector2(w, -10)]), Color("4a5236"), 0.15, 0.4, Art.OUTLINE, 1.5)
				DrawBatch.rect(self, Rect2(w * 0.08, -h * 0.5, w * 0.2, h * 0.2), Color(0.1, 0.08, 0.06, 0.6))   # שרוף
				DrawBatch.circle(self, Vector2(w * 0.7, -h * 0.4), 8.0, Color(0.85, 0.85, 0.8, 0.6))   # כוכב
				for wx in [w * 0.2, w * 0.8]:
					DrawBatch.circle(self, Vector2(wx, -9), 10.0, Art.OUTLINE)
					DrawBatch.circle(self, Vector2(wx, -9), 8.0, Color("1e1e20"))


# ---- השער הענק (מאחורי היציאה). נפתח כשה-GENERAL מת ----
class GreatGate extends Node2D:
	var _open := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		var ex := get_tree().get_first_node_in_group("level_exit")
		var target := 0.0 if ex == null or ex.locked else 1.0
		if _open != target:
			_open = move_toward(_open, target, delta * 0.5)
			queue_redraw()
		elif Engine.get_process_frames() % 10 == 0 and Art.on_screen(self, global_position, 500.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var wall := Color("6a6268")
		var dark := Color("3e383e")
		for side in [-1.0, 1.0]:   # שני מגדלי שער
			var tx: float = side * 170.0
			Art.fill_shaded(self, PackedVector2Array([Vector2(tx - 60, 0), Vector2(tx - 54, -330), Vector2(tx + 54, -330), Vector2(tx + 60, 0)]), wall, 0.12, 0.35, Art.OUTLINE, 2.0)
			for q in 4:
				DrawBatch.rect(self, Rect2(tx - 66.0 + float(q) * 36.0, -352, 24, 22), wall)   # שיניים
			DrawBatch.rect(self, Rect2(tx - 20, -280, 40, 14), Color(0.05, 0.05, 0.05))   # חרך ירי
			DrawBatch.rect(self, Rect2(tx - 20, -200, 40, 14), Color(0.05, 0.05, 0.05))
		DrawBatch.rect(self, Rect2(-115, -330, 230, 40), dark)   # קשת מעל השער
		DrawBatch.rect(self, Rect2(-60, -322, 120, 22), Color("8a2a24"))   # שלט "PLATEAU GATE"
		DrawBatch.rect(self, Rect2(-50, -315, 100, 8), Color(0.95, 0.85, 0.6, 0.8))
		var gap := _open * 100.0   # דלתות כבדות שנפתחות לצדדים
		for side in [-1.0, 1.0]:
			var x0: float = side * gap
			var pts := PackedVector2Array([Vector2(x0, -290), Vector2(x0 + side * 110.0, -290), Vector2(x0 + side * 110.0, 0), Vector2(x0, 0)])
			Art.fill_shaded(self, pts, Color("5a5048"), 0.12, 0.4, Art.OUTLINE, 1.6)
			for q in 5:
				DrawBatch.line(self, Vector2(x0, -290.0 + float(q) * 58.0), Vector2(x0 + side * 110.0, -290.0 + float(q) * 58.0), dark, 3.0)
			for r in 3:
				DrawBatch.circle(self, Vector2(x0 + side * (20.0 + float(r) * 35.0), -150), 3.0, Color("8a8a8e"))
		if _open > 0.05:   # שחר מבעד לשער
			DrawBatch.rect(self, Rect2(-gap, -290, gap * 2.0, 290), Color(1.0, 0.85, 0.6, 0.15 * _open))


# ---- ערפל בוקר + אבק ----
class GateFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _p := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 27
		for i in 30:
			_p.append(Vector3(r.randf_range(0, vp.x), r.randf_range(vp.y * 0.3, vp.y), r.randf_range(0.5, 1.5)))

	func _process(delta: float) -> void:
		_t += delta
		for i in _p.size():
			var e: Vector3 = _p[i]
			e.x += 18.0 * delta * e.z
			e.y += sin(_t + e.z * 3.0) * 4.0 * delta
			if e.x > vp.x + 10.0:
				e.x = -10.0
			_p[i] = e
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for e in _p:
			DrawBatch.circle(self, Vector2(e.x, e.y), 1.2 * e.z, Color(1.0, 0.9, 0.75, 0.4))
		var x := fposmod(_t * 20.0, vp.x)
		for j in 2:
			var xx := x + float(j) * vp.x - vp.x
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(xx, vp.y - 100), Vector2(xx + vp.x * 0.5, vp.y - 124), Vector2(xx + vp.x, vp.y - 100), Vector2(xx + vp.x * 0.5, vp.y - 80)]), Color(1.0, 0.92, 0.85, 0.09))
