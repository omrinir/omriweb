extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 36 ("THE SUMMIT") - הפסגה: מקדש אינקה בגובה 6,700 מטר (בהשראת המקדשים על ליולייאקו), סופת ברקים בשקיעה.
#  האינקה העלו לכאן מנחות ל"אפו" - רוח ההר. משהו ענה.
#    summit_sky    - (רקע) שמיים סגולים-אפורים כבדים, פס שקיעה אדום נמוך, ברקים בתוך העננים
#    cloud_sea     - (רקע) ים עננים מתחתינו, פסגות אחרות מבצבצות, העננים נדלקים מבפנים בברקים
#    mid_ruins     - (רקע) טרסות אינקה (אנדנס) על המדרון, מגדל קבורה (צ'ולפה), פתחים טרפזיים
#    near_rocks    - (רקע) סלעים כהים, אפצ'טות (ערמות אבנים), עשב איצ'ו קפוא שנע ברוח
#    SummitGround  - (עולם) סלע כהה עם כתמי שלג ועשב
#    Terrace       - (עולם) קיר אבנים מצולעות מושלם של האינקה + מדרגות (הקומה = add_floor)
#    Crumble       - (עולם, מלכודת) אבני מדרגה רופפות: עומדים עליהן -> רועדות -> נופלות (הקומה נעלמת), חוזרות אחרי RESET_T
#    Strike        - (עולם, מלכודת/בוס) ברק: עיגול זוהר + ניצוצות על הקרקע (WARN) -> ברק מהשמיים. נזק לשחקן ולזומבים
#    Storm         - (עולם, מלכודת) הסופה: כל CYCLE שניות ברק ליד השחקן. עומד גבוה (על טרסה)? הברק בוחר בך בדיוק
#    Obstacle      - (מוצק + מחסה) "apacheta" ערמת אבנים / "offering" מזבח מנחות / "wall_stub" שבר קיר אינקה
#    StormFX       - (מסך) שלג נסחף באלכסון, הבזקי ברק
#  לשנות: Storm.CYCLE, Strike.WARN / R / DMG_Z, Crumble.HOLD_T / RESET_T.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const STONE := Color("6a6058")
const STONE_D := Color("3e3832")
const BOLT := Color(0.85, 0.9, 1.0)


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


static func _flash(t: float, period: float, s: int) -> float:   # הבזק ברק ברקע (0..1)
	var c := fposmod(t, period)
	var k := floori(t / period)
	if c > 0.35 or _h(k, s) < 0.3:
		return 0.0
	return (1.0 - c / 0.35) * (0.6 + 0.4 * sin(c * 60.0))


static func jag(a: Vector2, b: Vector2, seed_v: int, n := 9, amp := 28.0) -> PackedVector2Array:   # קו ברק משונן
	var p := PackedVector2Array()
	for q in n + 1:
		var u := float(q) / float(n)
		var off := 0.0 if q == 0 or q == n else (_h(q, seed_v) - 0.5) * 2.0 * amp
		p.append(a.lerp(b, u) + Vector2(off, 0.0))
	return p


# ---- שמיים סוערים בשקיעה ----
static func summit_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("15121e"), Color("2a2234"), Color("4a3448"), Color("9a4a3a")], 0.95)
	DrawBatch.rect(ci, Rect2(0, v.y * 0.6, v.x, v.y * 0.08), Color(1.0, 0.45, 0.25, 0.25))   # פס שקיעה
	var f := _flash(t, 4.3, 3)
	for i in 7:   # עננים כבדים
		var cx := fposmod(float(i) * 260.0 - t * 6.0, v.x + 500.0) - 250.0
		var cy := v.y * (0.1 + 0.07 * float(i % 4))
		var c := Color("2e2838").lerp(Color("8a80b0"), f * (0.4 + 0.6 * _h(i, 9)))
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, cy), 220.0, 46.0, 0.0, 18), c)
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx + 80.0, cy + 18.0), 160.0, 34.0, 0.0, 16), c.darkened(0.15))
	if f > 0.3:   # ברק ענף בשמיים
		var k := floori(t / 4.3)
		var a := Vector2(v.x * (0.15 + 0.7 * _h(k, 5)), v.y * 0.12)
		var pts := jag(a, a + Vector2((_h(k, 6) - 0.5) * 200.0, v.y * 0.4), k, 8, 24.0)
		DrawBatch.polyline(ci, pts, Color(BOLT, 0.35 * f), 6.0)
		DrawBatch.polyline(ci, pts, Color(1, 1, 1, f), 1.8)
	DrawBatch.rect(ci, Rect2(0, 0, v.x, v.y), Color(0.8, 0.8, 1.0, 0.12 * f))


# ---- ים עננים מתחת, פסגות מבצבצות ----
static func cloud_sea(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):   # פסגות רחוקות מעל העננים
		var px := float(k) * period - sc + _h(k, 2) * 500.0
		var ph := 80.0 + _h(k, 4) * 120.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 140, y), Vector2(px - 20, y - ph), Vector2(px + 10, y - ph + 10), Vector2(px + 160, y)]), Color("3a3440"))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 20, y - ph), Vector2(px + 10, y - ph + 10), Vector2(px + 26, y - ph + 40), Vector2(px - 36, y - ph + 32)]), Color("c8c4d4"))
	var f := _flash(t + 1.7, 3.1, 8)
	var x := -60.0
	var i := 0
	while x < v.x + 60.0:   # ים העננים
		var u := x + sc * 0.6
		var cy := y - 10.0 + sin(u / 90.0 + t * 0.3) * 6.0
		var c := Color("4a4258").lerp(Color("b0a8d8"), f * _h(int(u / 120.0), 3))
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(x, cy), 70.0, 22.0, 0.0, 12), c)
		x += 50.0
		i += 1
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("4a4258"))


# ---- טרסות אינקה ומגדלי קבורה ----
static func mid_ruins(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pts := PackedVector2Array()   # המדרון
	var x := -30.0
	while x <= v.x + 30.0:
		var u := x + sc
		pts.append(Vector2(x, y - 70.0 - _vn(u / 300.0, 7) * 120.0))
		x += 30.0
	var poly := pts.duplicate()
	poly.append(Vector2(v.x + 30.0, v.y))
	poly.append(Vector2(-30.0, v.y))
	DrawBatch.colored_polygon(ci, poly, Color("3a3242"))   # היה 2c2630 - כהה מדי מאחורי הדמויות
	for q in pts.size():   # שלג על קו הרכס
		if q % 3 == 0:
			DrawBatch.colored_polygon(ci, Art.ellipse(pts[q] + Vector2(0, 3), 22.0, 4.0, 0.0, 8), Color(0.75, 0.75, 0.82, 0.6))
	var period := 600.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc + _h(k, 3) * 200.0
		var gi := clampi(int((bx + 30.0) / 30.0), 0, pts.size() - 1)
		var gy := pts[gi].y + 10.0
		if k % 2 == 0:   # טרסות: 3 קירות מדורגים
			for r in 3:
				var ww := 220.0 - float(r) * 50.0
				var ry := gy + 30.0 - float(r) * 18.0
				DrawBatch.rect(ci, Rect2(bx - ww * 0.5, ry - 14.0, ww, 14.0), Color("4a4248"))
				DrawBatch.line(ci, Vector2(bx - ww * 0.5, ry - 14.0), Vector2(bx + ww * 0.5, ry - 14.0), Color("6a6068"), 1.5)
		else:   # צ'ולפה: מגדל קבורה עגול עם פתח טרפזי
			DrawBatch.rect(ci, Rect2(bx - 16, gy - 60, 32, 60), Color("3e3640"))
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(bx, gy - 60), 18.0, 5.0, 0.0, 10), Color("4e4650"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx - 5, gy - 8), Vector2(bx + 5, gy - 8), Vector2(bx + 3, gy - 26), Vector2(bx - 3, gy - 26)]), Color("14101a"))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("3a3242"))


# ---- סלעים, אפצ'טות, עשב איצ'ו ----
static func near_rocks(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 560.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x0 := float(k) * period - sc
		var r := _rng(k * 47 + 5)
		for i in 3:   # סלעים
			var rx := x0 + r.randf_range(0.0, period)
			var rw := r.randf_range(40.0, 90.0)
			var rh := r.randf_range(24.0, 60.0)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(rx, y), Vector2(rx + rw * 0.15, y - rh), Vector2(rx + rw * 0.6, y - rh * 1.1), Vector2(rx + rw, y)]), Color("1e1a20"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(rx + rw * 0.15, y - rh), Vector2(rx + rw * 0.6, y - rh * 1.1), Vector2(rx + rw * 0.5, y - rh * 0.9)]), Color(0.75, 0.75, 0.82, 0.7))
		var ax := x0 + r.randf_range(50.0, 500.0)   # אפצ'טה
		for q in 5:
			var s := 12.0 - float(q) * 2.0
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(ax + r.randf_range(-3.0, 3.0), y - 6.0 - float(q) * 9.0), s, 5.0, 0.0, 8), Color("26222a"))
		for i in 6:   # עשב איצ'ו נע ברוח
			var gx := x0 + r.randf_range(0.0, period)
			var sway := sin(t * 3.0 + gx * 0.05) * 5.0
			for q in 4:
				DrawBatch.line(ci, Vector2(gx + float(q) * 2.0, y), Vector2(gx + float(q) * 2.0 + 8.0 + sway, y - 16.0 - float(q % 2) * 6.0), Color("8a7a50"), 1.2)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("1e1a20"))


# ---- סלע הפסגה ----
class SummitGround extends Node2D:
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
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("2e2a2c"))
		for i in int(w / 60.0):   # אבנים
			var c := Vector2(r.randf_range(0.0, w), r.randf_range(10.0, depth - 6.0))
			DrawBatch.colored_polygon(self, Art.ellipse(c, r.randf_range(8.0, 16.0), r.randf_range(4.0, 7.0), r.randf_range(-0.3, 0.3), 6), Color("3a3436").lerp(Color("4a4246"), r.randf()))
		DrawBatch.rect(self, Rect2(0, 0, w, 6.0), Color("4a4448"))
		var x := 0.0
		while x < w:   # כתמי שלג ועשב
			var cw := r.randf_range(30.0, 90.0)
			if r.randf() < 0.45:
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x + cw * 0.5, 1.0), cw * 0.5, 3.5, 0.0, 10), Color("d8d8e2"))
			elif r.randf() < 0.5:
				for q in 5:
					DrawBatch.line(self, Vector2(x + float(q) * 3.0, 0), Vector2(x + float(q) * 3.0 + 5.0, -9.0 - float(q % 2) * 4.0), Color("9a8a58"), 1.2)
			x += cw


# ---- קיר טרסה אינקאי (אבנים מצולעות) + מדרגות ----
class Terrace extends Node2D:
	var w := 300.0
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
		var S := preload("res://effects/s36_decor.gd")
		DrawBatch.rect(self, Rect2(0, -tier, w, tier), S.STONE_D)
		# אבנים מצולעות צמודות (הסגנון של סקסייוואמן): שורות עם אבנים בגדלים שונים, פינות מעוגלות
		var y := 0.0
		var row := 0
		while y > -tier + 4.0:
			var hh := r.randf_range(18.0, 28.0)
			var x := -r.randf_range(0.0, 20.0) if row % 2 == 1 else 0.0
			while x < w:
				var sw := r.randf_range(26.0, 50.0)
				var x0 := maxf(x, 0.0)
				var x1 := minf(x + sw, w)
				var y1 := maxf(y - hh, -tier)
				var c := S.STONE.lerp(Color("7a7068"), r.randf()).darkened(r.randf_range(0.0, 0.15))
				if x1 - x0 < 9.0 or y - y1 < 8.0:   # שבב קטן בקצה - בלי מצולע
					x += sw
					continue
				var p := PackedVector2Array([Vector2(x0 + 2, y - 1), Vector2(x1 - 2, y - 1), Vector2(x1 - 1, y - 4), Vector2(x1 - 1, y1 + 4), Vector2(x1 - 3, y1 + 1), Vector2(x0 + 3, y1 + 1), Vector2(x0 + 1, y1 + 4), Vector2(x0 + 1, y - 4)])
				DrawBatch.colored_polygon(self, p, c)
				DrawBatch.line(self, Vector2(x0 + 3, y1 + 2), Vector2(x1 - 3, y1 + 2), c.lightened(0.15), 1.0)
				x += sw
			y -= hh
			row += 1
		DrawBatch.rect(self, Rect2(-6, -tier - 4, w + 12, 6), Color("8a8088"))   # אבן כותרת
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w * 0.6, 0), Vector2(w * 0.6 + 18, -tier * 0.45), Vector2(w * 0.6 + 30, -tier * 0.45), Vector2(w * 0.6 + 12, 0)]), Color("14101a"))   # נישה טרפזית
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.3, -tier - 2), 26.0, 3.0, 0.0, 10), Color("d8d8e2"))   # שלג


# ---- אבנים רופפות ----
class Crumble extends Node2D:
	const HOLD_T := 0.8
	const RESET_T := 8.0
	var w := 80.0
	var floor_node: Node = null     # ה-add_floor שמתחת
	var falls := 0                  # לבדיקות
	var _t := 0.0
	var _hold := 0.0
	var _gone := 0.0
	var _drop := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -6), Vector2(w, 20))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _hold > 0.0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _gone > 0.0:
			_gone -= delta
			_drop += delta
			if _gone <= 0.0:
				if floor_node != null:
					floor_node.collision_layer = 16
				_hold = 0.0
				_drop = 0.0
			queue_redraw()
			return
		var pl := get_tree().get_first_node_in_group("player")
		var on: bool = pl != null and not pl.dead and pl.is_on_floor() and absf(pl.global_position.y - global_position.y) < 6.0 and pl.global_position.x > global_position.x - 4.0 and pl.global_position.x < global_position.x + w + 4.0
		if on or _hold > 0.0:
			if _hold == 0.0:
				preload("res://sfx.gd").play("su_rumble", global_position + Vector2(w * 0.5, 0), -4.0, 0.1, 2)
			_hold += delta
			if Engine.get_physics_frames() % 6 == 0:
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(0.0, w), 6.0), "smoke", Vector2.DOWN, 1)
			if _hold >= HOLD_T:
				falls += 1
				_gone = RESET_T
				if floor_node != null:
					floor_node.collision_layer = 0
				preload("res://sfx.gd").play("su_fall", global_position + Vector2(w * 0.5, 0), 0.0, 0.1, 2)
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(w * 0.5, 4.0), "smoke", Vector2.DOWN, 8)
		if _hold > 0.0 or Engine.get_physics_frames() % 10 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var S := preload("res://effects/s36_decor.gd")
		if _gone > 0.0:
			if _drop < 1.2:   # אבנים נופלות
				for q in 4:
					var fx := float(q) * w / 4.0 + 6.0
					var fy := 0.5 * 900.0 * _drop * _drop + float(q % 2) * 4.0
					DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(fx, fy), Vector2(fx + w / 4.0 - 6.0, fy + 2), Vector2(fx + w / 4.0 - 8.0, fy + 14), Vector2(fx + 2, fy + 12)]), S.STONE)
			elif _gone < 1.5:   # חוזרות (מתמלאות)
				DrawBatch.rect(self, Rect2(0, 0, w, 12), Color(S.STONE, 1.0 - _gone / 1.5))
			return
		var shk := sin(_t * 60.0) * 1.5 * minf(_hold / HOLD_T * 2.0, 1.0)
		for q in 4:
			var fx := float(q) * w / 4.0 + shk * (1.0 if q % 2 == 0 else -1.0)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(fx + 1, 0), Vector2(fx + w / 4.0 - 1, 0), Vector2(fx + w / 4.0 - 2, 12), Vector2(fx + 2, 12)]), S.STONE.lerp(Color("8a7a68"), float(q % 2) * 0.3))
			DrawBatch.line(self, Vector2(fx + 4, 3), Vector2(fx + w / 4.0 - 6.0, 5), Color(0.2, 0.18, 0.16, 0.6), 1.0)   # סדק
		if _hold > 0.0:
			DrawBatch.rect(self, Rect2(0, -2, w, 2), Color(1.0, 0.6, 0.3, 0.6))


# ---- ברק: אזהרה על הקרקע -> פגיעה מהשמיים ----
class Strike extends Node2D:
	const WARN := 1.0
	const R := 46.0
	const DMG_Z := 25
	var warn := 1.0
	var owner_t = null              # מי ביקש (Storm / בוס) - לספירת פגיעות
	var hit_player := false         # לבדיקות
	var _t := 0.0
	var _done := false
	var _seed := 0

	func _ready() -> void:
		z_index = 10
		add_to_group("hazards")
		_seed = randi()
		preload("res://sfx.gd").play("su_hum", global_position, -2.0, 0.1, 3)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-R, -80.0), Vector2(R * 2.0, 90.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return not _done and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t < warn:
			if Engine.get_physics_frames() % 5 == 0:
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-R, R) * 0.7, -2.0), "spark", Vector2.UP, 1)
		elif not _done:
			_done = true
			preload("res://sfx.gd").play("su_thunder", global_position, 4.0, 0.1, 2)
			preload("res://particles.gd").burst(get_parent(), global_position, "spark", Vector2.UP, 18)
			preload("res://particles.gd").burst(get_parent(), global_position, "smoke", Vector2.UP, 6)
			var cam: Camera2D = get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(9.0, 0.3)
			for fx in get_tree().get_nodes_in_group("storm_fx"):
				fx.flash()
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < R + 8.0 and absf(pl.global_position.y - global_position.y) < 70.0:
				hit_player = true
				pl.hurt(1, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 1.6, -1.0))
				if pl.has_method("daze"):
					pl.daze(0.6)
				if owner_t != null and is_instance_valid(owner_t) and owner_t.get("hits") != null:
					owner_t.hits += 1
			for zz in get_tree().get_nodes_in_group("zombies"):
				if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - global_position.x) < R and absf(zz.global_position.y - global_position.y) < 60.0:
					zz.take_damage(DMG_Z, zz.global_position + Vector2(0, -30), Vector2(0, -1), false, {"source": "lightning", "fixed": DMG_Z})
		if _t > warn + 2.5:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var S := preload("res://effects/s36_decor.gd")
		if _t < warn:   # אזהרה: עיגול כחול-לבן פועם על הקרקע + קו דק לשמיים
			var k := _t / warn
			var pulse := 0.5 + 0.5 * sin(_t * (12.0 + 20.0 * k))
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -1), R * (0.6 + 0.4 * k), 6.0, 0.0, 16), Color(0.6, 0.75, 1.0, 0.18 + 0.25 * pulse))
			DrawBatch.arc(self, Vector2(0, -1), R, PI, TAU, 14, Color(0.8, 0.9, 1.0, 0.3 + 0.4 * k), 1.5)
			DrawBatch.line(self, Vector2(0, -2), Vector2(0, -700), Color(0.8, 0.9, 1.0, 0.05 + 0.12 * k * pulse), 2.0)
		elif _t < warn + 0.3:   # הברק
			var a := 1.0 - (_t - warn) / 0.3
			var pts := S.jag(Vector2(randf_range(-60, 60), -760), Vector2.ZERO, _seed, 11, 30.0)
			DrawBatch.polyline(self, pts, Color(S.BOLT, 0.35 * a), 12.0)
			DrawBatch.polyline(self, pts, Color(1, 1, 1, a), 3.0)
			var br := S.jag(pts[5], pts[5] + Vector2(70, 160), _seed + 1, 5, 14.0)
			DrawBatch.polyline(self, br, Color(1, 1, 1, 0.7 * a), 1.5)
			Art.glow(self, Vector2(0, -6), 70.0, Color(0.7, 0.8, 1.0, 0.5 * a))
		else:   # סימן חריכה
			var a := clampf(1.0 - (_t - warn - 0.3) / 2.2, 0.0, 1.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -1), R * 0.6, 4.0, 0.0, 12), Color(0.08, 0.06, 0.06, 0.6 * a))


# ---- הסופה: ברקים ליד השחקן. על טרסה גבוהה - בדיוק עליך ----
class Storm extends Node2D:
	const CYCLE := Vector2(3.5, 6.0)
	const HIGH := 60.0              # כמה מעל הקרקע = "גבוה"
	var floor_y := 630.0
	var strikes := 0                # לבדיקות
	var hits := 0
	var targeted := 0               # כמה פעמים כיוון בדיוק עליך (עמדת גבוה)
	var quiet_from := INF            # (עולם x) מכאן והלאה הסופה שקטה - הבוס מביא ברקים משלו
	var _t := 4.0

	func _physics_process(delta: float) -> void:
		_t -= delta
		if _t > 0.0:
			return
		_t = randf_range(CYCLE.x, CYCLE.y)
		var pl := get_tree().get_first_node_in_group("player")
		if pl == null or pl.dead or pl.global_position.x > quiet_from:
			return
		var high: bool = pl.global_position.y < floor_y - HIGH
		var x: float = pl.global_position.x + (pl.velocity.x * 0.5 if high else randf_range(-260.0, 260.0))
		if high:
			targeted += 1
		var q := PhysicsRayQueryParameters2D.create(Vector2(x, pl.global_position.y - 260.0), Vector2(x, floor_y + 20.0), 1 | 16)
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(q)
		var y: float = floor_y if hit.is_empty() else float(hit.position.y)
		strike(get_parent(), Vector2(x, y), 1.0, self)
		strikes += 1

	static func strike(parent: Node, at: Vector2, warn := 1.0, owner_n = null) -> Node:
		var s := Strike.new()
		s.warn = warn
		s.owner_t = owner_n
		parent.add_child(s)
		s.global_position = at
		return s


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "apacheta"
	var size := Vector2(60, 46)
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
		var S := preload("res://effects/s36_decor.gd")
		match kind:
			"apacheta":   # ערמת אבנים של עוברי דרך
				var y := 0.0
				var lw := w
				while y > -h + 4.0:
					var n := maxi(1, int(lw / 16.0))
					for q in n:
						var cx := (w - lw) * 0.5 + (float(q) + 0.5) * lw / float(n)
						Art.oval_shaded(self, Vector2(cx, y - 6.0), lw / float(n) * 0.55, 6.5, S.STONE.lerp(Color("8a8078"), r.randf()), 0.0)
					y -= 11.0
					lw *= 0.78
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -h + 2), 8.0, 3.0, 0.0, 8), Color("d8d8e2"))
			"offering":   # מזבח מנחות: אבן שטוחה, אריג צבעוני, פסלוני לאמה, עלי קוקה
				Art.fill_shaded(self, PackedVector2Array([Vector2(4, 0), Vector2(w - 4, 0), Vector2(w - 8, -h * 0.7), Vector2(8, -h * 0.7)]), S.STONE, 0.15, 0.35, Art.OUTLINE, 1.3)
				DrawBatch.rect(self, Rect2(10, -h * 0.7 - 4, w - 20, 5), Color("b02a2a"))
				for q in 4:
					DrawBatch.rect(self, Rect2(12.0 + float(q) * (w - 24.0) / 4.0, -h * 0.7 - 4, 4, 5), [Color("e0b030"), Color("2a6a9a"), Color("2a8a4a"), Color("e0e0d0")][q])
				for q in 2:   # לאמות קטנות מכסף/זהב
					var lx := w * (0.3 + 0.35 * float(q))
					var lc := Color("d8c060") if q == 0 else Color("c0c4cc")
					DrawBatch.rect(self, Rect2(lx - 4, -h * 0.7 - 12, 8, 4), lc)
					DrawBatch.line(self, Vector2(lx + 3, -h * 0.7 - 12), Vector2(lx + 4, -h * 0.7 - 19), lc, 2.0)
					DrawBatch.line(self, Vector2(lx - 3, -h * 0.7 - 8), Vector2(lx - 3, -h * 0.7 - 4), lc, 1.5)
					DrawBatch.line(self, Vector2(lx + 3, -h * 0.7 - 8), Vector2(lx + 3, -h * 0.7 - 4), lc, 1.5)
				DrawBatch.line(self, Vector2(w * 0.5, -h * 0.7 - 6), Vector2(w * 0.5 + 6, -h), Color(0.6, 0.6, 0.6, 0.5), 1.5)   # עשן קטורת
			_:   # שבר קיר אינקאי
				var y := 0.0
				while y > -h + 2.0:
					var hh := minf(r.randf_range(14.0, 20.0), h + y)
					var x := 0.0
					var top_w := w * (1.0 - (-y) / h * 0.35)
					while x < top_w:
						var sw := minf(r.randf_range(18.0, 30.0), top_w - x)
						if sw < 8.0 or hh < 8.0:
							break
						Art.fill(self, PackedVector2Array([Vector2(x + 1, y - 1), Vector2(x + sw - 1, y - 1), Vector2(x + sw - 1, y - hh + 3), Vector2(x + sw - 3, y - hh + 1), Vector2(x + 3, y - hh + 1), Vector2(x + 1, y - hh + 3)]), S.STONE.lerp(Color("7a7068"), r.randf()), Art.OUTLINE, 1.0)
						x += sw
					y -= hh


# ---- שלג נסחף באלכסון + הבזקי ברק (מסך) ----
class StormFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _flash := 0.0

	func _ready() -> void:
		add_to_group("storm_fx")

	func flash() -> void:
		_flash = 1.0

	func _process(delta: float) -> void:
		_t += delta
		_flash = maxf(_flash - delta * 4.0, 0.0)
		if Engine.get_process_frames() % 2 == 0 or _flash > 0.0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for i in 40:
			var x := fposmod(float(i) * 83.0 - _t * (220.0 + float(i % 5) * 40.0), vp.x + 80.0) - 40.0
			var y := fposmod(float(i) * 57.0 + _t * (120.0 + float(i % 3) * 30.0), vp.y)
			DrawBatch.line(self, Vector2(x, y), Vector2(x + 10.0, y - 5.0), Color(0.9, 0.9, 1.0, 0.35), 1.3)
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.15, 0.1, 0.25, 0.08))
		if _flash > 0.0:
			DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.85, 0.9, 1.0, 0.35 * _flash))
