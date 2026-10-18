extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 26 ("THE BUNKER") - בונקר פיקוד צבאי מתחת לרמה: בטון, צינורות, אורות חירום אדומים,
#  דלתות כספת ענקיות, תעלות אוורור בתקרה. מכאן שידרו לתורן של שלב 25 - ומכאן ה-GENERAL בורח לשער (שלב 27).
#    bunker_wall   - ("שמיים") קיר בטון כהה עם פסי יציקה
#    far_hall      - (רקע) אולם ענק: מפרצים, דלתות כספת עגולות, מספרי קומות מצוירים, צינורות
#    mid_pillars   - (רקע) עמודי בטון עם פסי אזהרה, מנורות תלויות, ארגזים
#    near_rail     - (רקע) מעקה ושרשראות קרובים
#    BunkerGround  - (עולם) רצפת בטון: פסי אזהרה צהוב-שחור, רשתות ניקוז, קווים צבועים
#    Ceiling       - (עולם) תקרת בטון + תעלות אוורור (DUCT_Y) עם רשתות + פלורסנטים מהבהבים + נורות חירום מסתובבות
#    FuseBox       - (עולם) לוח חשמל על הקיר. כל אחד מפעיל "קטע" (x0..x1). BLACKOUT מנתק אותו -> הקטע חשוך (BLACKOUT_T).
#                    השחקן נוגע בו -> החשמל חוזר מיד.
#    LaserGate     - (עולם, מלכודת) מסך לייזר אדום מהתקרה לרצפה: דולק/כבוי במחזור (ON_T / OFF_T), מהבהב לפני שנדלק.
#                    פגיעה = DMG + הדף אחורה. זומבים נשרפים (Z_DMG), חכמים מחכים.
#    Obstacle      - (מוצק + מחסה) "crates" ארגזי תחמושת / "drums" חביות רעל / "locker" ארונות
#    BunkerDark    - (שכבת חושך) הבונקר חשוך קצת (DARKNESS), קטע מנותק חשוך מאוד. הפנס של השחקן מאיר.
#    ExitTunnel    - (עולם) הכניסה למנהרה בסוף השלב ("TO THE GATE") - מכאן מתחיל שלב 27.
#  לשנות: FuseBox.BLACKOUT_T, LaserGate.ON_T/OFF_T, BunkerDark.DARKNESS.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const CONC := Color("5a5e58")
const CONC_D := Color("3a3e3a")
const STRIPE := Color("d8b030")
const DUCT_Y := -330.0            # גובה תעלות האוורור (יחסית לרצפה)
const CEIL_Y := -372.0            # תחתית התקרה


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- קיר בטון (במקום שמיים) ----
static func bunker_wall(ci: CanvasItem, v: Vector2, _t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("161a18"), Color("232824"), Color("2c322c"), Color("262a26")], 0.9)


# ---- אולם ענק ----
static func far_hall(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var wall := Color("2e342e")
	var dark := Color("1e221e")
	DrawBatch.rect(ci, Rect2(0, y - 420, v.x, 420), wall)
	var period := 1100.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 113 + 2)
		for b in 3:   # מפרצים עם קורות
			var bx := x + float(b) * 360.0
			DrawBatch.rect(ci, Rect2(bx + 20, y - 380, 300, 360), Color("262c26"))
			DrawBatch.rect(ci, Rect2(bx, y - 400, 20, 400), dark)
		# דלת כספת עגולה ענקית
		var dc := Vector2(x + 560.0, y - 150.0)
		DrawBatch.circle(ci, dc, 120.0, dark)
		DrawBatch.circle(ci, dc, 108.0, Color("3e443e"))
		DrawBatch.circle(ci, dc, 70.0, Color("343a34"))
		for s in 8:
			var a := float(s) * TAU / 8.0
			DrawBatch.line(ci, dc + Vector2.from_angle(a) * 70.0, dc + Vector2.from_angle(a) * 106.0, dark, 6.0)
		for s in 3:   # גלגל פתיחה
			DrawBatch.line(ci, dc + Vector2.from_angle(float(s) * PI / 3.0) * -30.0, dc + Vector2.from_angle(float(s) * PI / 3.0) * 30.0, Color("4a504a"), 5.0)
		DrawBatch.rect(ci, Rect2(dc.x + 130, y - 210, 60, 8), Color(STRIPE, 0.5))
		# מספר קומה מצויר "B2"
		var nx := x + 160.0 + r.randf_range(0.0, 60.0)
		DrawBatch.rect(ci, Rect2(nx, y - 330, 16, 70), Color(0.75, 0.7, 0.55, 0.35))
		DrawBatch.rect(ci, Rect2(nx + 24, y - 330, 40, 12), Color(0.75, 0.7, 0.55, 0.35))
		DrawBatch.rect(ci, Rect2(nx + 52, y - 330, 12, 70), Color(0.75, 0.7, 0.55, 0.35))
		DrawBatch.rect(ci, Rect2(nx + 24, y - 270, 40, 10), Color(0.75, 0.7, 0.55, 0.35))
		# צינורות לאורך הקיר
		for q in 2:
			DrawBatch.rect(ci, Rect2(x, y - 300.0 + float(q) * 18.0, period, 10.0), Color("3a3328") if q == 0 else Color("2e3a3e"))
		# נורת חירום אדומה מסתובבת
		var lx := x + 900.0
		var on := fmod(t * 1.2 + float(k) * 0.3, 1.0)
		DrawBatch.rect(ci, Rect2(lx - 6, y - 360, 12, 10), dark)
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(lx, y - 352), Vector2(lx + cos(on * TAU) * 120.0 - 30.0, y - 200), Vector2(lx + cos(on * TAU) * 120.0 + 30.0, y - 200)]), Color(1.0, 0.1, 0.05, 0.06))
		DrawBatch.circle(ci, Vector2(lx, y - 352), 5.0, Color(1.0, 0.2, 0.1, 0.5 + 0.5 * absf(sin(on * TAU))))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), dark)


# ---- עמודים, מנורות, ארגזים ----
static func mid_pillars(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var col := Color("1a1e1a")
	var period := 800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 41 + 7)
		var px := x + 300.0
		DrawBatch.rect(ci, Rect2(px, y - 460, 60, 460), col)
		for q in 5:   # פסי אזהרה בתחתית העמוד
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px + float(q) * 12.0, y - 60), Vector2(px + float(q) * 12.0 + 6.0, y - 60), Vector2(px + float(q) * 12.0 + 18.0, y - 40), Vector2(px + float(q) * 12.0 + 12.0, y - 40)]), Color(STRIPE, 0.35))
		var lx := x + r.randf_range(80.0, 700.0)   # מנורה תלויה
		var sway := sin(t * 0.9 + float(k)) * 3.0
		DrawBatch.line(ci, Vector2(lx, y - 470), Vector2(lx + sway, y - 330), col, 1.5)
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(lx + sway - 12, y - 322), Vector2(lx + sway - 5, y - 332), Vector2(lx + sway + 5, y - 332), Vector2(lx + sway + 12, y - 322)]), col)
		var flick := 1.0 if fmod(t * 7.0 + float(k) * 3.1, 9.0) > 0.4 else 0.2
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(lx + sway - 10, y - 322), Vector2(lx + sway + 10, y - 322), Vector2(lx + sway + 70, y), Vector2(lx + sway - 70, y)]), Color(0.9, 0.95, 0.8, 0.035 * flick))
		for c in 2:   # ארגזים
			var cx := x + r.randf_range(0.0, period - 80.0)
			DrawBatch.rect(ci, Rect2(cx, y - 44, 70, 44), col)
			DrawBatch.rect(ci, Rect2(cx + 10, y - 80, 50, 36), col)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), col)


# ---- מעקה קרוב ----
static func near_rail(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var col := Color("0e100e")
	var period := 600.0
	var start := int(floor(sc / period)) - 1
	DrawBatch.rect(ci, Rect2(0, y - 34.0, v.x, 4.0), col)
	DrawBatch.rect(ci, Rect2(0, y - 18.0, v.x, 3.0), col)
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		for p in 4:
			DrawBatch.rect(ci, Rect2(x + float(p) * 150.0, y - 36.0, 5.0, 36.0), col)
		var cx := x + 380.0   # שרשרת תלויה
		var sw := sin(t * 1.3 + float(k)) * 4.0
		DrawBatch.polyline(ci, PackedVector2Array([Vector2(cx, -10), Vector2(cx + sw * 0.5, v.y * 0.3), Vector2(cx + sw, v.y * 0.45)]), col, 2.0)
	DrawBatch.rect(ci, Rect2(0, y - 2.0, v.x, v.y - y + 2.0), col)


# ---- רצפת בטון ----
class BunkerGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s26_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), S.CONC_D)
		DrawBatch.rect(self, Rect2(0, 0, w, 8.0), S.CONC)
		DrawBatch.rect(self, Rect2(0, 14, w, 3), Color(S.STRIPE, 0.5))   # קו צבוע
		var x := 0.0
		while x < w:   # לוחות
			DrawBatch.line(self, Vector2(x, 0), Vector2(x, depth), Color(0, 0, 0, 0.3), 1.5)
			x += 200.0
		for i in int(w / 420.0):   # פס אזהרה צהוב-שחור
			var px := r.randf_range(0.0, w - 120.0)
			for q in 8:
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(px + float(q) * 14.0, 1), Vector2(px + float(q) * 14.0 + 7.0, 1), Vector2(px + float(q) * 14.0 + 3.0, 7), Vector2(px + float(q) * 14.0 - 4.0, 7)]), S.STRIPE)
		for i in int(w / 350.0):   # רשת ניקוז
			var px := r.randf_range(0.0, w - 50.0)
			DrawBatch.rect(self, Rect2(px, 22, 40, 10), Color("1a1c1a"))
			for q in 5:
				DrawBatch.line(self, Vector2(px + 4.0 + float(q) * 8.0, 22), Vector2(px + 4.0 + float(q) * 8.0, 32), S.CONC, 1.5)


# ---- תקרה + תעלות אוורור + פלורסנטים ----
class Ceiling extends Node2D:
	var w := 1024.0
	var seed_v := 0
	var duct := true             # יש תעלה בקטע הזה
	var _t := 0.0
	var _flick := []

	func _ready() -> void:
		z_index = 3
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in int(w / 260.0):
			_flick.append(r.randf() < 0.25)

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -300.0), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s26_decor.gd")
		var top := S.CEIL_Y
		DrawBatch.rect(self, Rect2(0, top - 900.0, w, 900.0), Color("1c201c"))
		DrawBatch.rect(self, Rect2(0, top - 14.0, w, 14.0), Color("2a2e2a"))
		for i in int(w / 200.0):   # קורות
			DrawBatch.rect(self, Rect2(float(i) * 200.0 + 10.0, top - 4.0, 14.0, 20.0), Color("262a26"))
		if duct:   # תעלה מלבנית עם רשתות
			var dy := S.DUCT_Y
			DrawBatch.rect(self, Rect2(0, dy - 28.0, w, 30.0), Color("5a6066"))
			DrawBatch.rect(self, Rect2(0, dy - 28.0, w, 4.0), Color("7a8086"))
			DrawBatch.rect(self, Rect2(0, dy - 1.0, w, 3.0), Color("3a3e42"))
			var x := 30.0
			while x < w:
				DrawBatch.line(self, Vector2(x, dy - 28.0), Vector2(x, dy + 2.0), Color("44484c"), 1.5)   # תפרים
				x += 110.0
			for g in int(w / 330.0):   # רשתות
				var gx := 80.0 + float(g) * 330.0
				DrawBatch.rect(self, Rect2(gx, dy - 22.0, 34.0, 20.0), Color("2a2e30"))
				for q in 5:
					DrawBatch.line(self, Vector2(gx + 3.0 + float(q) * 7.0, dy - 22.0), Vector2(gx + 3.0 + float(q) * 7.0, dy - 2.0), Color("6a7076"), 1.2)
			for h in int(w / 260.0):   # מתלים
				DrawBatch.line(self, Vector2(40.0 + float(h) * 260.0, top), Vector2(40.0 + float(h) * 260.0, dy - 28.0), Color("2a2e2a"), 2.0)
		for i in _flick.size():   # פלורסנטים
			var lx := 120.0 + float(i) * 260.0
			var on := true
			if _flick[i]:
				on = fmod(_t * 5.0 + float(i) * 1.7, 4.0) > 0.6
			DrawBatch.rect(self, Rect2(lx, top + 2.0, 60.0, 6.0), Color("3a3e3a"))
			DrawBatch.rect(self, Rect2(lx + 3.0, top + 8.0, 54.0, 3.0), Color(0.95, 1.0, 0.85, 0.95) if on else Color(0.3, 0.32, 0.3))
			if on:
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(lx, top + 11.0), Vector2(lx + 60.0, top + 11.0), Vector2(lx + 120.0, top + 120.0), Vector2(lx - 60.0, top + 120.0)]), Color(0.9, 1.0, 0.85, 0.05))


# ---- לוח חשמל של קטע ----
class FuseBox extends Node2D:
	const BLACKOUT_T := 9.0
	var x0 := 0.0
	var x1 := 1000.0
	var powered := true
	var cuts := 0                # לבדיקות
	var restores := 0
	var _off_t := 0.0
	var _blink := 0.0

	func _ready() -> void:
		z_index = -1
		add_to_group("fuse_boxes")

	func section_has(x: float) -> bool:
		return x >= x0 and x < x1

	func cut() -> void:   # BLACKOUT
		if not powered:
			return
		powered = false
		cuts += 1
		_off_t = BLACKOUT_T
		Sfx.play("s26_powerdown", global_position, 4.0, 0.05, 2)
		queue_redraw()
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and section_has(pl.global_position.x):
			pl._say("WHO TURNED OFF THE LIGHTS?", Color("c0d0ff"))

	func restore() -> void:
		if powered:
			return
		powered = true
		restores += 1
		Sfx.play("s26_powerup", global_position, 2.0, 0.05, 2)
		queue_redraw()

	func _physics_process(delta: float) -> void:
		_blink += delta
		if not powered:
			_off_t -= delta
			var pl := get_tree().get_first_node_in_group("player")
			if _off_t <= 0.0:
				restore()
			elif pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < 26.0 and absf(pl.global_position.y - global_position.y) < 60.0:
				restore()   # השחקן מחזיר את החשמל
				pl._say("POWER BACK ON", Color("a0ffa0"))
			if Engine.get_physics_frames() % 10 == 0:
				queue_redraw()

	func _draw() -> void:
		var y := -100.0
		DrawBatch.line(self, Vector2(0, -60), Vector2(0, 0), Color("2a2e2a"), 3.0)   # צינור חשמל לרצפה
		Art.fill_shaded(self, PackedVector2Array([Vector2(-18, y), Vector2(18, y), Vector2(18, y + 44), Vector2(-18, y + 44)]), Color("6a7060"), 0.15, 0.4, Art.OUTLINE, 1.4)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-6, y + 8), Vector2(4, y + 8), Vector2(-1, y + 18), Vector2(5, y + 18), Vector2(-5, y + 34), Vector2(-2, y + 22), Vector2(-8, y + 22)]), Color("e8c040"))   # ברק
		var lever_a := -0.8 if powered else 0.8   # ידית
		DrawBatch.line(self, Vector2(12, y + 22), Vector2(12, y + 22) + Vector2.from_angle(-PI * 0.5 + lever_a) * 14.0, Color("2a2a2a"), 3.0)
		DrawBatch.circle(self, Vector2(12, y + 22) + Vector2.from_angle(-PI * 0.5 + lever_a) * 14.0, 3.0, Color("c03020"))
		var led := Color(0.3, 1.0, 0.4) if powered else (Color(1.0, 0.2, 0.1) if fmod(_blink, 0.6) < 0.3 else Color(0.3, 0.05, 0.05))
		DrawBatch.circle(self, Vector2(-12, y + 6), 2.5, led)
		if not powered:
			Art.glow(self, Vector2(-12, y + 6), 10.0, Color(1.0, 0.2, 0.1, 0.4))


# ---- מסך לייזר ----
class LaserGate extends Node2D:
	const ON_T := 1.7
	const OFF_T := 1.6
	const WARN_T := 0.45         # מהבהב לפני שנדלק
	const DMG := 2
	const Z_DMG := 20
	var h := 330.0
	var phase_off := 0.0
	var hits := 0                # לבדיקות
	var _t := 0.0
	var _hit_cd := 0.0
	var _zcd := {}

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		_t = phase_off

	func state() -> int:   # 0 = כבוי, 1 = אזהרה, 2 = דולק
		var c := fmod(_t, ON_T + OFF_T)
		if c < ON_T:
			return 2
		return 1 if c > ON_T + OFF_T - WARN_T else 0

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-6.0, -h), Vector2(12.0, h))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state() > 0 and world_rect().grow(margin + 10.0).has_point(p)

	func _physics_process(delta: float) -> void:
		var was := state()
		_t += delta
		_hit_cd -= delta
		var st := state()
		if st == 2 and was != 2 and Art.on_screen(self, global_position):
			Sfx.play("s26_laser", global_position, -4.0, 0.05, 2)
		if st == 2:
			var r := world_rect()
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and _hit_cd <= 0.0 and r.intersects(pl.body_rect()):
				_hit_cd = 0.8
				if pl._invuln <= 0.0:
					hits += 1
				var side := signf(pl.velocity.x) * -1.0 if absf(pl.velocity.x) > 10.0 else signf(pl.global_position.x - global_position.x)
				pl.hurt(DMG, Vector2((side if side != 0.0 else -1.0) * 2.0, -0.8))
				preload("res://particles.gd").burst(get_parent(), pl.global_position + Vector2(0, -30), "spark", Vector2.UP, 8)
			if Engine.get_physics_frames() % 5 == 0:
				for z in get_tree().get_nodes_in_group("zombies"):
					if z.dead or float(_zcd.get(z.get_instance_id(), 0.0)) > _t:
						continue
					if absf(z.global_position.x - global_position.x) < 10.0 + 8.0 * float(z.wf) and z.global_position.y > global_position.y - h:
						_zcd[z.get_instance_id()] = _t + 0.8
						z.take_damage(Z_DMG, z.global_position + Vector2(0, -28), Vector2.UP, false, {"source": "hazard", "fixed": Z_DMG})
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var st := state()
		DrawBatch.rect(self, Rect2(-9, -h - 4, 18, 12), Color("3a3e42"))   # פולט בתקרה
		DrawBatch.rect(self, Rect2(-9, -8, 18, 8), Color("3a3e42"))        # מקלט ברצפה
		DrawBatch.circle(self, Vector2(0, -h + 6), 3.0, Color(1, 0.2, 0.15) if st > 0 else Color(0.3, 0.08, 0.06))
		if st == 2:
			for q in 3:
				var x := (float(q) - 1.0) * 3.0
				DrawBatch.line(self, Vector2(x, -h + 8), Vector2(x, -8), Color(1.0, 0.15, 0.1, 0.85), 1.6)
			DrawBatch.rect(self, Rect2(-6, -h + 8, 12, h - 16), Color(1.0, 0.1, 0.05, 0.12))
			DrawBatch.circle(self, Vector2(0, -8), 6.0, Color(1.0, 0.3, 0.2, 0.4))
		elif st == 1 and fmod(_t * 12.0, 1.0) < 0.5:   # מהבהב: עוד רגע נדלק
			DrawBatch.line(self, Vector2(0, -h + 8), Vector2(0, -8), Color(1.0, 0.2, 0.1, 0.35), 1.0)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "ammo_crates"
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
		var w := size.x
		var h := size.y
		match kind:
			"ammo_crates":   # ארגזי תחמושת ירוקים עם סטנסיל
				var hh := h * 0.5
				for row in 2:
					var rw := w if row == 0 else w * 0.62
					var rx := 0.0 if row == 0 else w * 0.18
					var ry := -hh * float(row + 1)
					Art.fill_shaded(self, PackedVector2Array([Vector2(rx, ry + hh), Vector2(rx + rw, ry + hh), Vector2(rx + rw, ry), Vector2(rx, ry)]), Color("4a5a3a"), 0.15, 0.4, Art.OUTLINE, 1.3)
					DrawBatch.rect(self, Rect2(rx + rw * 0.3, ry + hh * 0.35, rw * 0.4, hh * 0.25), Color(0.85, 0.85, 0.7, 0.5))
					DrawBatch.rect(self, Rect2(rx + 2, ry + 2, 4, hh - 4), Color("2a3220"))
					DrawBatch.rect(self, Rect2(rx + rw - 6, ry + 2, 4, hh - 4), Color("2a3220"))
			"drums":   # חביות רעל
				for i in 2:
					var dx := float(i) * w * 0.5
					Art.fill_shaded(self, PackedVector2Array([Vector2(dx + 2, 0), Vector2(dx + w * 0.5 - 2, 0), Vector2(dx + w * 0.5 - 2, -h), Vector2(dx + 2, -h)]), Color("c8a020"), 0.2, 0.4, Art.OUTLINE, 1.4)
					var c := Vector2(dx + w * 0.25, -h * 0.5)
					DrawBatch.circle(self, c, 6.0, Color("1a1a1a"))
					for a in 3:
						DrawBatch.colored_polygon(self, PackedVector2Array([c, c + Vector2.from_angle(float(a) * TAU / 3.0 - 0.4) * 6.0, c + Vector2.from_angle(float(a) * TAU / 3.0 + 0.4) * 6.0]), Color("c8a020"))
			_:   # ארונות מתכת
				var n := maxi(1, int(w / 26.0))
				for i in n:
					var lx := float(i) * w / float(n)
					Art.fill_shaded(self, PackedVector2Array([Vector2(lx + 1, 0), Vector2(lx + w / float(n) - 1, 0), Vector2(lx + w / float(n) - 1, -h), Vector2(lx + 1, -h)]), Color("4a5a66"), 0.15, 0.4, Art.OUTLINE, 1.2)
					for q in 3:
						DrawBatch.line(self, Vector2(lx + 5, -h + 6.0 + float(q) * 4.0), Vector2(lx + w / float(n) - 5, -h + 6.0 + float(q) * 4.0), Color(0, 0, 0, 0.4), 1.2)
					DrawBatch.rect(self, Rect2(lx + w / float(n) - 7, -h * 0.55, 3, 8), Color("8a8e90"))


# ---- המנהרה לשער (סוף השלב) ----
class ExitTunnel extends Node2D:
	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var c := Color("1a1e1a")
		DrawBatch.rect(self, Rect2(-20, -260, 280, 260), Color("2a2e2a"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(10, 0), Vector2(10, -170), Vector2(40, -210), Vector2(190, -210), Vector2(220, -170), Vector2(220, 0)]), Color("060806"))
		for q in 6:   # פסי אזהרה סביב הפתח
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-20 + float(q) * 48.0, -260), Vector2(4 + float(q) * 48.0, -260), Vector2(28 + float(q) * 48.0, -236), Vector2(4 + float(q) * 48.0, -236)]), STRIPE)
		DrawBatch.rect(self, Rect2(40, -250, 150, 20), c)
		DrawBatch.rect(self, Rect2(46, -246, 36, 12), Color(0.8, 0.8, 0.7, 0.6))   # "TO THE GATE"
		DrawBatch.rect(self, Rect2(88, -246, 26, 12), Color(0.8, 0.8, 0.7, 0.6))
		DrawBatch.rect(self, Rect2(120, -246, 60, 12), Color(0.8, 0.8, 0.7, 0.6))
		DrawBatch.line(self, Vector2(150, -120), Vector2(200, -120), Color(1, 1, 1, 0.08), 2.0)
		for i in 5:   # אור בקצה המנהרה (שחר של שלב 27)
			DrawBatch.circle(self, Vector2(115, -90), 70.0 - float(i) * 12.0, Color(1.0, 0.75, 0.45, 0.03 + 0.02 * float(i)))


# ---- חושך הבונקר ----
class BunkerDark extends CanvasLayer:
	const DARKNESS := 0.32
	const BLACK := 0.93
	var _rect: ColorRect
	const SHADER := """
shader_type canvas_item;
uniform float darkness = 0.3;
uniform float black = 0.93;
uniform vec4 lights[12];
uniform vec4 zones[4];
uniform vec2 vp_size = vec2(1280.0, 720.0);
void fragment() {
	vec2 p = SCREEN_UV * vp_size;
	float lit = 0.0;
	for (int i = 0; i < 12; i++) {
		vec4 l = lights[i];
		if (l.w <= 0.0) continue;
		vec2 d = (p - l.xy) / vec2(l.z, l.z * 1.2);
		lit = max(lit, l.w * (1.0 - smoothstep(0.2, 1.0, length(d))));
	}
	float inside = 0.0;
	for (int i = 0; i < 4; i++) {
		vec4 z = zones[i];
		if (z.w <= 0.0) continue;
		inside = max(inside, z.w * smoothstep(z.x - 60.0, z.x + 20.0, p.x) * (1.0 - smoothstep(z.y - 20.0, z.y + 60.0, p.x)));
	}
	float d = mix(darkness, black, inside);
	COLOR = vec4(0.0, 0.01, 0.02, d * (1.0 - lit));
}
"""

	func _ready() -> void:
		layer = 1
		_rect = ColorRect.new()
		_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = Shader.new()
		mat.shader.code = SHADER
		_rect.material = mat
		add_child(_rect)

	func any_dark() -> bool:
		for fb in get_tree().get_nodes_in_group("fuse_boxes"):
			if not fb.powered:
				return true
		return false

	func _process(_delta: float) -> void:
		var vp := get_viewport()
		var ct := vp.get_canvas_transform()
		var zoom := ct.get_scale().x
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var lights := []
		if player != null:
			var pp: Vector2 = ct * (player.global_position + Vector2(0.0, -30.0))
			lights.append(Vector4(pp.x, pp.y, 130.0 * zoom, 0.6))   # היה 95
		var dyn: Array = preload("res://effects/dyn_lights.gd").gather(get_tree(), ct, zoom, player)   # הפנס של השחקן
		lights = preload("res://effects/dyn_lights.gd").merge(dyn[0], lights, 12)
		var zones := []
		for fb in get_tree().get_nodes_in_group("fuse_boxes"):
			if fb.powered or zones.size() >= 4:
				continue
			var a: Vector2 = ct * Vector2(float(fb.x0), 0.0)
			var b: Vector2 = ct * Vector2(float(fb.x1), 0.0)
			if b.x < -100.0 or a.x > vp.get_visible_rect().size.x + 100.0:
				continue
			var k: float = clampf(float(fb.BLACKOUT_T) - float(fb._off_t), 0.0, 0.4) / 0.4   # נכבה בהדרגה
			zones.append(Vector4(a.x, b.x, 0.0, k))
		while zones.size() < 4:
			zones.append(Vector4(0, 0, 0, 0))
		var m := _rect.material as ShaderMaterial
		m.set_shader_parameter("lights", lights)
		m.set_shader_parameter("zones", zones)
		m.set_shader_parameter("darkness", DARKNESS)
		m.set_shader_parameter("black", BLACK)
		m.set_shader_parameter("vp_size", vp.get_visible_rect().size)
