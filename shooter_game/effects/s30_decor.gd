extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 30 ("FROZEN VILLAGE") - כפר אנדי גבוה בסופת שלג: בתי אדובי עם גגות פח וקש מכוסי שלג,
#  ארובות מעשנות, כנסייה קולוניאלית לבנה עם מגדל פעמון, גדרות אלפקות, חומות אבן, מדורות בחביות.
#    blizzard_sky  - (רקע) אפור-לבן כבד
#    far_ridges    - (רקע) רכסים דהויים בתוך הסופה
#    mid_village   - (רקע) בתי אדובי, ארובות עם עשן, כנסייה, חלונות מוארים, גדרות
#    near_drifts   - (רקע) ערימות שלג, עמודי גדר, חבל כביסה קפוא
#    SnowGround    - (עולם) שלג על אבני מרצפת, עקבות
#    House         - (עולם) קירות בית אדובי מתחת לגג (הגג = add_floor "roof"), דלת, חלון מואר, ארובה מעשנת
#    BellTower     - (עולם, קבוצה "bells") מגדל הפעמון של הכנסייה. ring() = הפעמון מתנדנד, צלצול, ושורת גלי קול
#    ThinIce       - (עולם, מלכודת) שלולית קפואה: עומדים עליה -> נסדקת (CRACK_T) -> נשברת: DMG + קפוא (איטי וכוונת רועדת), מתקשה מחדש (REFREEZE)
#    Brazier       - (עולם) חבית אש: עשן, ניצוצות, אור חם. עומדים לידה (WARM_R) = מתחממים (הקור נעלם)
#    Obstacle      - (מוצק + מחסה) "stonewall" חומת אבן מושלגת / "woodpile" ערמת עצים / "haycart" עגלה
#    BlizzardFX    - (מסך, קבוצה "blizzard") שלג כבד אלכסוני + whiteout(t) = לבן כמעט מלא (מהפעמון)
#  לשנות: ThinIce.CRACK_T, ThinIce.CHILL, Brazier.WARM_R, BlizzardFX.WHITE.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const SNOW := Color("eef2f6")
const SNOW_D := Color("c8d2dc")
const ADOBE := Color("b08a62")
const ADOBE_D := Color("8a6a48")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func blizzard() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("blizzard") if tree != null else null


static func blizzard_sky(ci: CanvasItem, v: Vector2, _t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("6a7480"), Color("8a949e"), Color("a8b0b8"), Color("c4cad0")], 0.85)


static func far_ridges(ci: CanvasItem, sc: float, v: Vector2, y: float, _t: float) -> void:
	var period := 1800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 29 + 6)
		var pts := PackedVector2Array([Vector2(x, y)])
		for i in 10:
			pts.append(Vector2(x + float(i) * period / 9.0, y - r.randf_range(100.0, 230.0)))
		pts.append(Vector2(x + period, y))
		DrawBatch.colored_polygon(ci, pts, Color("9aa4b0"))
	DrawBatch.rect(ci, Rect2(0, y - 120, v.x, 120), Color(0.85, 0.88, 0.92, 0.35))   # אובך סופה
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("9aa4b0"))


# ---- הכפר: בתי אדובי, ארובות, כנסייה ----
static func mid_village(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	var wall := Color("8a7a6a")
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 401 + 3)
		for h in 4:   # בתים
			var hx := x + float(h) * 330.0 + r.randf_range(0.0, 60.0)
			var hw := r.randf_range(130.0, 190.0)
			var hh := r.randf_range(70.0, 100.0)
			DrawBatch.rect(ci, Rect2(hx, y - hh, hw, hh), wall)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(hx - 10, y - hh), Vector2(hx + hw * 0.5, y - hh - 40), Vector2(hx + hw + 10, y - hh)]), Color("6a5a50"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(hx - 10, y - hh), Vector2(hx + hw * 0.5, y - hh - 40), Vector2(hx + hw + 10, y - hh), Vector2(hx + hw * 0.5, y - hh - 30)]), Color("e8ecf0"))   # שלג על הגג
			var wx := hx + hw * 0.3
			DrawBatch.rect(ci, Rect2(wx, y - hh * 0.6, 18, 16), Color(1.0, 0.75, 0.4, 0.75 + 0.15 * sin(t * 3.0 + float(h + k))))   # חלון מואר
			DrawBatch.rect(ci, Rect2(hx + hw * 0.65, y - 44, 22, 44), Color("4a3a2e"))   # דלת
			var cx := hx + hw * 0.75   # ארובה + עשן (רק בחלק מהבתים - חוסך ציור)
			DrawBatch.rect(ci, Rect2(cx, y - hh - 40, 12, 26), Color("6a5a50"))
			if (h + k) % 2 == 0:
				Kit.smoke_column(ci, Vector2(cx + 6, y - hh - 44), t + float(h) * 1.7 + float(k), 160.0, Color(0.55, 0.55, 0.58, 0.35), 90.0)
		if k % 2 == 0:   # כנסייה קולוניאלית לבנה
			var chx := x + 1300.0
			DrawBatch.rect(ci, Rect2(chx, y - 150, 180, 150), Color("d8d4cc"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(chx - 8, y - 150), Vector2(chx + 90, y - 196), Vector2(chx + 188, y - 150)]), Color("e8ecf0"))
			DrawBatch.rect(ci, Rect2(chx + 120, y - 250, 54, 100), Color("d8d4cc"))   # מגדל
			DrawBatch.rect(ci, Rect2(chx + 132, y - 238, 30, 34), Color("3a3430"))   # קשת הפעמון
			DrawBatch.circle(ci, Vector2(chx + 147, y - 218), 9.0, Color("8a6a2a"))
			DrawBatch.line(ci, Vector2(chx + 147, y - 270), Vector2(chx + 147, y - 290), Color("3a3430"), 3.0)   # צלב
			DrawBatch.line(ci, Vector2(chx + 139, y - 282), Vector2(chx + 155, y - 282), Color("3a3430"), 3.0)
			DrawBatch.rect(ci, Rect2(chx + 30, y - 60, 40, 60), Color("5a4030"))   # דלת עץ
			DrawBatch.arc(ci, Vector2(chx + 50, y - 60), 20.0, PI, TAU, 10, Color("5a4030"), 4.0)
		var fx := x + r.randf_range(0.0, 400.0)   # גדר אלפקות
		for f in 7:
			DrawBatch.line(ci, Vector2(fx + float(f) * 30.0, y), Vector2(fx + float(f) * 30.0, y - 26), Color("5a4a3a"), 2.0)
		DrawBatch.line(ci, Vector2(fx, y - 20), Vector2(fx + 180, y - 20), Color("5a4a3a"), 1.6)
		for a in 2:   # אלפקות
			var ax := fx + 50.0 + float(a) * 70.0
			var ac := Color("f0e8dc") if a == 0 else Color("7a5a40")
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(ax, y - 12), 10.0, 7.0, 0.0, 10), ac)
			DrawBatch.line(ci, Vector2(ax + 7, y - 15), Vector2(ax + 10, y - 28), ac, 4.0)
			DrawBatch.circle(ci, Vector2(ax + 11, y - 29), 3.5, ac)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("aab4be"))


# ---- ערימות שלג, עמודים, חבל כביסה קפוא ----
static func near_drifts(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 71 + 2)
		for i in 3:
			var dx := x + r.randf_range(0.0, period)
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(dx, y), r.randf_range(60.0, 120.0), r.randf_range(16.0, 30.0), 0.0, 16), Color("dfe5ea"))
		var lx := x + r.randf_range(100.0, 500.0)
		DrawBatch.line(ci, Vector2(lx, y), Vector2(lx, y - 70), Color("4a3a2e"), 4.0)
		DrawBatch.line(ci, Vector2(lx + 200, y), Vector2(lx + 200, y - 70), Color("4a3a2e"), 4.0)
		var sag := sin(t * 1.5 + float(k)) * 3.0
		DrawBatch.polyline(ci, PackedVector2Array([Vector2(lx, y - 66), Vector2(lx + 100, y - 56 + sag), Vector2(lx + 200, y - 66)]), Color("3a3a3a"), 1.2)
		for c in 3:   # בגדים קפואים (צבעוני אנדים)
			var cx := lx + 40.0 + float(c) * 55.0
			var cy := y - 60.0 + sag * 0.6
			DrawBatch.rect(ci, Rect2(cx, cy, 22, 26), [Color("c02a4a"), Color("2a7ac0"), Color("e8a020")][c])
			DrawBatch.rect(ci, Rect2(cx, cy, 22, 4), Color(1, 1, 1, 0.8))
	DrawBatch.rect(ci, Rect2(0, y - 2.0, v.x, v.y - y + 2.0), Color("d0d8e0"))


class SnowGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s30_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("5a5a60"))
		var x := 0.0
		while x < w:   # אבני מרצפת
			DrawBatch.rect(self, Rect2(x + 1, 12, 26, 14), Color("6a6a70"))
			DrawBatch.rect(self, Rect2(x + 14, 28, 26, 14), Color("626268"))
			x += 28.0
		var pts := PackedVector2Array([Vector2(0, 14)])   # שכבת שלג גלית
		x = 0.0
		while x <= w:
			pts.append(Vector2(x, r.randf_range(-3.0, 3.0)))
			x += 24.0
		pts.append(Vector2(w, 14))
		DrawBatch.colored_polygon(self, pts, S.SNOW)
		DrawBatch.line(self, Vector2(0, 10), Vector2(w, 10), S.SNOW_D, 2.0)
		for i in int(w / 40.0):   # עקבות
			var px := r.randf_range(0.0, w)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(px, 3), 4.0, 1.4), Color(0.75, 0.8, 0.86, 0.8))


# ---- קירות בית אדובי מתחת לגג ----
class House extends Node2D:
	var w := 400.0
	var h := 150.0
	var seed_v := 0
	var _puff := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_puff -= delta
		if _puff <= 0.0 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0)):
			_puff = 0.3
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(w * 0.8 + 8.0, -h - 40.0), "smoke", Vector2(0.4, -1.0), 2)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s30_decor.gd")
		DrawBatch.rect(self, Rect2(0, -h, w, h), S.ADOBE)
		for i in int(w / 30.0):   # לבני אדובי
			for j in int(h / 16.0):
				if r.randf() < 0.25:
					DrawBatch.rect(self, Rect2(float(i) * 30.0 + float(j % 2) * 15.0, -h + float(j) * 16.0, 28, 14), S.ADOBE_D)
		DrawBatch.rect(self, Rect2(0, -h, w, h), Color(0, 0, 0, 0.12), false, 2.0)
		for wi in int(w / 140.0):   # חלונות מוארים
			var wx := 40.0 + float(wi) * 140.0
			DrawBatch.rect(self, Rect2(wx, -h + 40, 30, 26), Color("3a2a1e"))
			DrawBatch.rect(self, Rect2(wx + 3, -h + 43, 24, 20), Color(1.0, 0.75, 0.4, 0.85))
			DrawBatch.line(self, Vector2(wx + 15, -h + 43), Vector2(wx + 15, -h + 63), Color("3a2a1e"), 2.0)
			DrawBatch.rect(self, Rect2(wx - 4, -h + 66, 38, 5), S.SNOW)
		DrawBatch.rect(self, Rect2(w * 0.45, -60, 36, 60), Color("5a3a24"))   # דלת
		DrawBatch.rect(self, Rect2(w * 0.45 + 28, -32, 4, 4), Color("c8a040"))
		DrawBatch.rect(self, Rect2(w * 0.8, -h - 40, 16, 40), Color("8a6a50"))   # ארובה
		DrawBatch.rect(self, Rect2(w * 0.8 - 2, -h - 44, 20, 6), S.SNOW)


# ---- מגדל הפעמון ----
class BellTower extends Node2D:
	var h := 280.0
	var w := 110.0
	var rings := 0               # לבדיקות
	var _swing := 0.0
	var _ring_t := 0.0
	var _waves := []

	func _ready() -> void:
		z_index = -1
		add_to_group("bells")

	func bell_pos() -> Vector2:
		return global_position + Vector2(w * 0.5, -h - 60.0)

	func ring() -> void:
		rings += 1
		_ring_t = 1.4
		for i in 3:
			_waves.append(-float(i) * 0.35)
		Sfx.play("s30_bell", bell_pos(), 6.0, 0.02, 2)

	func _process(delta: float) -> void:
		if _ring_t > 0.0:
			_ring_t -= delta
		_swing = sin(_ring_t * 9.0) * 0.6 * clampf(_ring_t, 0.0, 1.0)
		for i in _waves.size():
			_waves[i] += delta
		_waves = _waves.filter(func(wv): return wv < 1.2)
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -h), 300.0) and (Engine.get_process_frames() % 6 == 0 or _ring_t > 0.0 or not _waves.is_empty()):
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s30_decor.gd")
		var white := Color("e0dcd4")
		DrawBatch.rect(self, Rect2(0, -h, w, h), white)
		DrawBatch.rect(self, Rect2(0, -h, w, h), Color(0, 0, 0, 0.12), false, 2.0)
		DrawBatch.rect(self, Rect2(w * 0.3, -70, w * 0.4, 70), Color("5a3a24"))
		DrawBatch.arc(self, Vector2(w * 0.5, -70), w * 0.2, PI, TAU, 10, Color("5a3a24"), 5.0)
		DrawBatch.rect(self, Rect2(-6, -h - 6, w + 12, 10), Color("c8c4bc"))   # קורת הרצפה של הפעמון
		DrawBatch.rect(self, Rect2(0, -h - 120, 12, 120), white)   # עמודי הקשת
		DrawBatch.rect(self, Rect2(w - 12, -h - 120, 12, 120), white)
		DrawBatch.arc(self, Vector2(w * 0.5, -h - 120), w * 0.5 - 6.0, PI, TAU, 14, white, 12.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-10, -h - 130), Vector2(w * 0.5, -h - 190), Vector2(w + 10, -h - 130)]), Color("8a4a3a"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-10, -h - 130), Vector2(w * 0.5, -h - 190), Vector2(w + 10, -h - 130), Vector2(w * 0.5, -h - 176)]), S.SNOW)
		DrawBatch.line(self, Vector2(w * 0.5, -h - 190), Vector2(w * 0.5, -h - 220), Color("3a3430"), 3.0)   # צלב
		DrawBatch.line(self, Vector2(w * 0.5 - 9, -h - 210), Vector2(w * 0.5 + 9, -h - 210), Color("3a3430"), 3.0)
		var pivot := Vector2(w * 0.5, -h - 100)   # הפעמון מתנדנד
		DrawBatch.set_transform(self, pivot, _swing, Vector2.ONE)
		DrawBatch.line(self, Vector2.ZERO, Vector2(0, 10), Color("3a3430"), 3.0)
		Art.fill_shaded(self, PackedVector2Array([Vector2(-10, 10), Vector2(10, 10), Vector2(16, 40), Vector2(-16, 40)]), Color("a07a2a"), 0.25, 0.35, Art.OUTLINE, 1.4)
		DrawBatch.circle(self, Vector2(0, 42), 4.0, Color("6a4a1a"))
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
		for wv in _waves:   # גלי קול
			if wv > 0.0:
				DrawBatch.arc(self, pivot + Vector2(0, 25), 30.0 + wv * 200.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.6, 0.5 * (1.0 - wv / 1.2)), 3.0)


# ---- קרח דק ----
class ThinIce extends Node2D:
	const CRACK_T := 0.9         # כמה זמן אפשר לעמוד עליו
	const DMG := 2
	const CHILL := 2.5           # כמה שניות קפוא (איטי, כוונת רועדת)
	const REFREEZE := 8.0
	var w := 110.0
	var breaks := 0              # לבדיקות
	var _crack := 0.0
	var _broken := 0.0
	var _seed := 0
	var _creak := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		_seed = randi()

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -10), Vector2(w, 12))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _broken <= 0.0 and p.x > global_position.x - margin and p.x < global_position.x + w + margin and absf(p.y - global_position.y) < 40.0

	func _on(b: Rect2) -> bool:
		return b.end.x > global_position.x + 6.0 and b.position.x < global_position.x + w - 6.0 and absf(b.end.y - global_position.y) < 6.0

	func _physics_process(delta: float) -> void:
		_creak -= delta
		if _broken > 0.0:
			_broken -= delta
			if _broken <= 0.0:
				_crack = 0.0
				queue_redraw()
			return
		var pl := get_tree().get_first_node_in_group("player")
		var weight := false
		if pl != null and not pl.dead and pl.is_on_floor() and _on(pl.body_rect()):
			weight = true
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or not z.is_on_floor():
				continue
			if z.global_position.x > global_position.x and z.global_position.x < global_position.x + w and absf(z.global_position.y - global_position.y) < 6.0:
				if float(z.sc) >= 1.3:   # כבד - שובר מיד
					_crack = CRACK_T
				weight = true
		if weight:
			_crack += delta
			if _creak <= 0.0:
				_creak = 0.3
				Sfx.play("s30_crack", global_position + Vector2(w * 0.5, 0), -4.0 + _crack * 6.0, 0.2, 3)
			queue_redraw()
		else:
			_crack = maxf(_crack - delta * 0.3, 0.0)
		if _crack >= CRACK_T:
			_break(pl)

	func _break(pl: Node) -> void:
		breaks += 1
		_broken = REFREEZE
		Sfx.play("splash", global_position + Vector2(w * 0.5, 0), 2.0, 0.1, 2)
		Sfx.play("s30_crack", global_position + Vector2(w * 0.5, 0), 4.0, 0.1, 2)
		for i in 3:
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(w * (0.25 + 0.25 * float(i)), -4), "smoke", Vector2.UP, 3)
		if pl != null and not pl.dead and _on(pl.body_rect()):
			pl.hurt(DMG, Vector2(0.0, -1.4))
			pl._daze_t = maxf(float(pl._daze_t), CHILL)
			pl._say("FREEZING WATER!", Color("a0d8ff"))
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and z.global_position.x > global_position.x and z.global_position.x < global_position.x + w and absf(z.global_position.y - global_position.y) < 8.0:
				z.take_damage(30, z.global_position + Vector2(0, -10), Vector2.UP, false, {"source": "hazard", "fixed": 30})
		queue_redraw()

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = _seed
		if _broken > 0.0:   # מים פתוחים עם גושי קרח
			DrawBatch.rect(self, Rect2(0, -2, w, 10), Color("1a3a5a"))
			for i in 4:
				var ix := r.randf_range(6.0, w - 20.0)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(ix, -1), Vector2(ix + 14, -2), Vector2(ix + 12, 3), Vector2(ix + 2, 3)]), Color(0.8, 0.9, 1.0, 0.9))
			var k := 1.0 - _broken / REFREEZE
			DrawBatch.rect(self, Rect2(0, -2, w, 4), Color(0.7, 0.85, 1.0, 0.6 * k))   # מתקשה מחדש
			return
		DrawBatch.rect(self, Rect2(0, -2, w, 6), Color(0.62, 0.8, 0.95))
		DrawBatch.line(self, Vector2(6, -1), Vector2(w * 0.5, -1), Color(1, 1, 1, 0.7), 1.2)   # ברק
		DrawBatch.rect(self, Rect2(-6, -3, 8, 6), preload("res://effects/s30_decor.gd").SNOW)
		DrawBatch.rect(self, Rect2(w - 2, -3, 8, 6), preload("res://effects/s30_decor.gd").SNOW)
		var k := clampf(_crack / CRACK_T, 0.0, 1.0)
		for i in int(k * 8.0):   # סדקים לפי כמה זמן עמדת
			var cx := r.randf_range(8.0, w - 8.0)
			DrawBatch.polyline(self, PackedVector2Array([Vector2(cx, -1), Vector2(cx + r.randf_range(-12.0, 12.0), 1), Vector2(cx + r.randf_range(-18.0, 18.0), 3)]), Color(1, 1, 1, 0.9), 1.2)


# ---- חבית אש: עשן, ניצוצות, חום ----
class Brazier extends Node2D:
	const WARM_R := 60.0
	var _t := 0.0
	var _puff := 0.0

	func _ready() -> void:
		z_index = 2
		var f = preload("res://fire.gd").new()
		f.width = 20.0
		f.height = 26.0
		f.position = Vector2(0, -40)
		add_child(f)

	func _process(delta: float) -> void:
		_t += delta
		_puff -= delta
		if _puff <= 0.0 and Art.on_screen(self, global_position):
			_puff = 0.2
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-6, 6), -64), "smoke", Vector2(0.3, -1.0), 2)
			if randf() < 0.4:
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -50), "fire", Vector2.UP, 2)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.global_position.distance_to(global_position) < WARM_R and float(pl._daze_t) > 0.0:
			pl._daze_t = 0.0   # מתחמם
			pl._say("WARM...", Color("ffc080"))
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		Art.fill_shaded(self, PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(15, -40), Vector2(-15, -40)]), Color("4a4448"), 0.15, 0.4, Art.OUTLINE, 1.4)
		for q in 3:
			DrawBatch.circle(self, Vector2(-6.0 + float(q) * 6.0, -24), 2.5, Color(1.0, 0.5, 0.15, 0.6 + 0.3 * sin(_t * 8.0 + float(q))))   # חורים זוהרים
		DrawBatch.line(self, Vector2(-15, -14), Vector2(15, -14), Color("2a2428"), 2.0)
		Art.glow(self, Vector2(0, -44), 70.0, Color(1.0, 0.55, 0.2, 0.2 + 0.05 * sin(_t * 9.0)))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -1), 46.0, 6.0, 0.0, 14), Color(0.55, 0.65, 0.7, 0.4))   # שלג שנמס סביב


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "stonewall"
	var size := Vector2(90, 46)
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
		var S := preload("res://effects/s30_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"stonewall":
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 3, -h), Vector2(3, -h)]), Color("7a7470"), 0.15, 0.35, Art.OUTLINE, 1.4)
				for i in 10:
					DrawBatch.colored_polygon(self, Art.ellipse(Vector2(r.randf_range(8.0, w - 8.0), -r.randf_range(6.0, h - 6.0)), r.randf_range(6.0, 10.0), r.randf_range(4.0, 6.0), 0.0, 8), Color("8a8480"))
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-3, -h + 2), Vector2(w + 3, -h + 2), Vector2(w - 6, -h - 8), Vector2(w * 0.5, -h - 11), Vector2(6, -h - 8)]), S.SNOW)
			"woodpile":
				var rows := 3
				var rr := h / float(rows * 2)
				for row in rows:
					for i in int(w / (rr * 2.0)):
						var c := Vector2(rr + float(i) * rr * 2.0 + float(row % 2) * rr * 0.5, -rr - float(row) * rr * 2.0)
						DrawBatch.circle(self, c, rr, Color("8a6a44"))
						DrawBatch.arc(self, c, rr * 0.5, 0, TAU, 8, Color("6a4a2a"), 1.0)
						DrawBatch.arc(self, c, rr, 0, TAU, 10, Art.OUTLINE, 1.0)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, -h + 2), Vector2(w, -h + 2), Vector2(w * 0.5, -h - 8)]), S.SNOW)
			_:   # עגלה עם קש ושלג
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, -12), Vector2(w, -12), Vector2(w, -h * 0.55), Vector2(0, -h * 0.55)]), Color("6a4a2e"), 0.15, 0.4, Art.OUTLINE, 1.4)
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -h * 0.6), w * 0.48, h * 0.35, 0.0, 16), Color("c8a858"))
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -h * 0.82), w * 0.4, h * 0.16, 0.0, 14), S.SNOW)
				for wx in [w * 0.2, w * 0.8]:
					DrawBatch.circle(self, Vector2(wx, -10), 10.0, Art.OUTLINE)
					DrawBatch.circle(self, Vector2(wx, -10), 8.0, Color("5a4028"))


# ---- סופת שלג (מסך) + whiteout ----
class BlizzardFX extends Node2D:
	const WHITE := 0.62          # כמה לבן בשיא ה-whiteout
	var vp := Vector2(1280, 720)
	var whiteouts := 0           # לבדיקות
	var _t := 0.0
	var _f := []
	var _white := 0.0
	var _white_max := 0.0

	func _ready() -> void:
		add_to_group("blizzard")
		var r := RandomNumberGenerator.new()
		r.seed = 30
		for i in 90:
			_f.append(Vector3(r.randf_range(0, vp.x), r.randf_range(0, vp.y), r.randf_range(0.5, 1.6)))

	func whiteout(t: float) -> void:
		whiteouts += 1
		_white = maxf(_white, t)
		_white_max = maxf(_white, 0.1)

	func is_white() -> bool:
		return _white > 0.0

	func _process(delta: float) -> void:
		_t += delta
		_white = maxf(_white - delta, 0.0)
		var gust := 1.0 + 0.6 * sin(_t * 0.7) + (2.0 if _white > 0.0 else 0.0)
		for i in _f.size():
			var e: Vector3 = _f[i]
			e.x -= (120.0 * gust + sin(_t * 2.0 + e.z * 5.0) * 30.0) * delta * e.z
			e.y += 140.0 * delta * e.z
			if e.y > vp.y + 10.0 or e.x < -20.0:
				e = Vector3(randf_range(0.0, vp.x + 200.0), -10.0, e.z)
			_f[i] = e
		queue_redraw()

	func _draw() -> void:
		for e in _f:
			DrawBatch.line(self, Vector2(e.x, e.y), Vector2(e.x + 4.0 * e.z, e.y - 3.0 * e.z), Color(1, 1, 1, 0.8), 1.4 * e.z)
		var base := 0.08 + 0.04 * sin(_t * 0.5)
		var k := 0.0
		if _white > 0.0:
			k = clampf(minf(_white, _white_max - _white + 0.01) / 0.6, 0.0, 1.0)   # נכנס ויוצא בהדרגה
		DrawBatch.rect(self, Rect2(Vector2.ZERO, vp), Color(0.93, 0.95, 0.98, base + WHITE * k))
		var x := fposmod(-_t * 80.0, vp.x)
		for j in 2:   # רצועות סופה
			var xx := x + float(j) * vp.x - vp.x * 0.5
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(xx, vp.y * 0.4), Vector2(xx + vp.x * 0.5, vp.y * 0.3), Vector2(xx + vp.x, vp.y * 0.45), Vector2(xx + vp.x * 0.5, vp.y * 0.55)]), Color(1, 1, 1, 0.06))
