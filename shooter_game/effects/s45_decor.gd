extends RefCounted
# ============================================================
#  קישוטים לשלב 45 ("THE RED PALACE") - פטרופוליס, ארמון הקיץ של קיסרי ברזיל, בהרי סרה דוס אורגאוס. אזור חמישי, שלב 9 (הסוף).
#  קיסר המתים התיישב בארמון הקיסרי הישן וצבע אותו אדום. גנים עם הורטנזיות, תעלות עם גשרים, הקתדרלה הגותית, "אצבע האלוהים".
#    palace_sky    - (רקע) שקיעה סגולה-אדומה, ירח, עשן ממדורות
#    far_mountains - (רקע) רכס סרה דוס אורגאוס עם פסגת "אצבע האלוהים", הקתדרלה הגותית של פטרופוליס
#    mid_palace    - (רקע) חזית הארמון הניאו-קלאסית (צבועה אדום), חלונות מוארים, דגלי ענק, דקלים קיסריים
#    near_garden   - (רקע) שיחי הורטנזיה כחולים, גדר ברזל, פנסים
#    PalaceGround  - (עולם) שביל אבן עם שטיח אדום
#    Balcony       - (עולם) מרפסת אבן עם מעקה (הקומה = add_floor)
#    Brazier       - (עולם, מלכודת) מדורת טקס: מתלקחת (WARN_T - גחלים) -> לשון אש בטווח R. מצית זומבים.
#    HangingBanner - (עולם, מלכודת) כרזת ענק תלויה על חבל מעל השביל: אתה מתחת - חריקה (WARN_T) ואז נופלת (נזק + הפלה).
#                    ירייה בחבל = הפלה ברגע שתבחר (על זומבים!).
#    Throne        - (עולם) במת הכס של הקיסר בסוף השלב (מדרגות + וילון + הכס)
#    Obstacle      - (מוצק + מחסה) "statue" פסל / "urn" כד / "hedge" גדר חיה
#    PalaceFX      - (מסך) עלי כותרת אדומים ואפר
#  לשנות: Brazier.CYCLE / WARN_T / R, HangingBanner.WARN_T / DMG / DMG_Z.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const E := preload("res://enemies/empire_kit.gd")


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func palace_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("1a1028"), Color("3a1a38"), Color("8a2a34"), Color("d8603a")], 0.88)
	ci.draw_circle(Vector2(v.x * 0.78, v.y * 0.16), 26.0, Color(1.0, 0.85, 0.75, 0.9))   # ירח
	Art.glow(ci, Vector2(v.x * 0.78, v.y * 0.16), 70.0, Color(1.0, 0.6, 0.5, 0.15))
	Kit.clouds(ci, t * 3.0, v, t, v.y * 0.22, Color(0.25, 0.1, 0.15, 0.35), 7, 5.0)


# ---- ההרים והקתדרלה ----
static func far_mountains(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, v.y))
	var x := -30.0
	while x <= v.x + 30.0:
		var wx := x + sc
		var hgt := 150.0 + sin(wx * 0.003) * 60.0 + sin(wx * 0.013) * 22.0 + absf(sin(wx * 0.007)) * 30.0
		pts.append(Vector2(x, y - hgt))
		x += 30.0
	pts.append(Vector2(v.x, v.y))
	ci.draw_colored_polygon(pts, Color("2a1830"))
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# אצבע האלוהים: פסגה דקה וזקופה
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx + 300, y - 160), Vector2(bx + 330, y - 330), Vector2(bx + 342, y - 345), Vector2(bx + 352, y - 320), Vector2(bx + 372, y - 160)]), Color("24142a"))
		# הקתדרלה הגותית: צריח מחודד + כנסייה
		var cx := bx + 900.0
		ci.draw_rect(Rect2(cx - 60.0, y - 120.0, 120.0, 100.0), Color("341c34"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 60, y - 120), Vector2(cx, y - 150), Vector2(cx + 60, y - 120)]), Color("341c34"))
		ci.draw_rect(Rect2(cx - 14.0, y - 230.0, 28.0, 120.0), Color("341c34"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 14, y - 230), Vector2(cx, y - 300), Vector2(cx + 14, y - 230)]), Color("341c34"))
		ci.draw_circle(Vector2(cx, y - 170.0), 6.0, Color(1.0, 0.6, 0.3, 0.5))   # רוזטה
		E.flag(ci, Vector2(cx, y - 300.0), 34.0, 22.0, t, k)
		Kit.smoke_column(ci, Vector2(bx + 600.0, y - 40.0), t, 180.0, Color(0.1, 0.05, 0.08, 0.3), 50.0)


# ---- חזית הארמון ----
static func mid_palace(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1100.0
	var start := int(floor(sc / period)) - 1
	var wall := Color("8a2a2a")
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הבניין: אגף מרכזי גבוה + שני אגפים
		ci.draw_rect(Rect2(bx + 80.0, y - 170.0, 760.0, 150.0), wall)
		ci.draw_rect(Rect2(bx + 330.0, y - 230.0, 260.0, 210.0), wall.lightened(0.05))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx + 320, y - 230), Vector2(bx + 460, y - 275), Vector2(bx + 600, y - 230)]), wall.darkened(0.1))   # גמלון
		E.emblem(ci, Vector2(bx + 460.0, y - 246.0), 13.0)
		ci.draw_rect(Rect2(bx + 76.0, y - 176.0, 768.0, 8.0), Color("d8c8b0"))   # כרכוב לבן
		ci.draw_rect(Rect2(bx + 326.0, y - 236.0, 268.0, 8.0), Color("d8c8b0"))
		for q in 14:   # חלונות מוארים (קשתות)
			var wx := bx + 100.0 + float(q) * 52.0
			if wx > bx + 320.0 and wx < bx + 590.0:
				continue
			var lit := _h(q + k * 31, 3) < 0.7
			ci.draw_rect(Rect2(wx, y - 140.0, 22.0, 46.0), Color(1.0, 0.75, 0.4, 0.75) if lit else Color("2a1418"))
			ci.draw_circle(Vector2(wx + 11.0, y - 140.0), 11.0, Color(1.0, 0.75, 0.4, 0.75) if lit else Color("2a1418"))
			ci.draw_rect(Rect2(wx, y - 84.0, 22.0, 40.0), Color(1.0, 0.75, 0.4, 0.55) if lit else Color("2a1418"))
		for q in 5:   # עמודים במרכז
			ci.draw_rect(Rect2(bx + 345.0 + float(q) * 55.0, y - 200.0, 12.0, 180.0), Color("d8c8b0"))
		E.banner(ci, Vector2(bx + 380.0, y - 196.0), 34.0, 120.0, t)
		E.banner(ci, Vector2(bx + 540.0, y - 196.0), 34.0, 120.0, t + 1.0)
		for px in [bx + 40.0, bx + 900.0, bx + 1000.0]:   # דקלים קיסריים
			ci.draw_line(Vector2(px, y - 20.0), Vector2(px, y - 260.0), Color("3a2a24"), 5.0)
			for f in 7:
				var a := -PI * 0.5 + (float(f) - 3.0) * 0.45 + sin(t * 0.7 + float(f)) * 0.05
				ci.draw_line(Vector2(px, y - 260.0), Vector2(px, y - 260.0) + Vector2.from_angle(a + PI * 0.5 * signf(float(f) - 3.0 + 0.01) * 0.6) * 50.0, Color("1e2a1e"), 3.0)
	ci.draw_rect(Rect2(0, y - 20.0, v.x, v.y - y + 20.0), Color("2a1a1e"))


# ---- גן ההורטנזיות ----
static func near_garden(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 260.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		for q in 6:   # שיח הורטנזיה
			var bx := x + 20.0 + float(q) * 14.0
			var by := y - 22.0 - absf(sin(float(q) * 1.7)) * 10.0
			ci.draw_circle(Vector2(bx, by), 11.0, Color("1e3a24"))
			ci.draw_circle(Vector2(bx + 2.0, by - 4.0), 6.0, Color(0.45, 0.5, 0.95, 0.85) if (q + k) % 3 != 0 else Color(0.85, 0.4, 0.75, 0.85))
		for q in 10:   # גדר ברזל
			ci.draw_line(Vector2(x + 130.0 + float(q) * 12.0, y), Vector2(x + 130.0 + float(q) * 12.0, y - 40.0), Color("120a0e"), 2.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 127.0 + float(q) * 12.0, y - 40.0), Vector2(x + 130.0 + float(q) * 12.0, y - 46.0), Vector2(x + 133.0 + float(q) * 12.0, y - 40.0)]), Color("120a0e"))
		ci.draw_line(Vector2(x + 128.0, y - 30.0), Vector2(x + 246.0, y - 30.0), Color("120a0e"), 2.0)
		ci.draw_line(Vector2(x + 250.0, y), Vector2(x + 250.0, y - 90.0), Color("120a0e"), 3.0)   # פנס
		Art.glow(ci, Vector2(x + 250.0, y - 94.0), 16.0, Color(1.0, 0.7, 0.4, 0.4))
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("160c10"))


# ============================================================
#  עולם
# ============================================================
class PalaceGround extends Node2D:
	var w := 1024.0
	var depth := 90.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		draw_rect(Rect2(0, 0, w, depth), Color("5a5048"))
		var x := 0.0
		while x < w:   # אבני ריצוף
			draw_rect(Rect2(x, 0, 62.0, 30.0), Color("6a6056").darkened(0.05 * float(int(x / 64.0) % 2)))
			x += 64.0
		draw_rect(Rect2(0, 2, w, 10), Color("8a1a1a"))   # שטיח אדום
		draw_rect(Rect2(0, 2, w, 2), Color("c8a040"))
		draw_rect(Rect2(0, 10, w, 2), Color("c8a040"))


class Balcony extends Node2D:   # מרפסת (הקומה = add_floor)
	var w := 320.0
	var tier := 150.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		draw_rect(Rect2(0, -tier, w, 14.0), Color("d8c8b0"))
		draw_rect(Rect2(0, -tier + 14.0, w, 6.0), Color("a89880"))
		for q in int(w / 18.0) + 1:   # עמודונים
			var bx := float(q) * 18.0
			draw_colored_polygon(PackedVector2Array([Vector2(bx + 3, -tier), Vector2(bx + 9, -tier), Vector2(bx + 11, -tier - 12), Vector2(bx + 9, -tier - 22), Vector2(bx + 3, -tier - 22), Vector2(bx + 1, -tier - 12)]), Color("d8c8b0"))
		draw_rect(Rect2(-4, -tier - 28.0, w + 8.0, 6.0), Color("e8d8c0"))
		for px in [10.0, w - 30.0]:   # עמודים
			draw_rect(Rect2(px, -tier + 20.0, 20.0, tier - 20.0), Color("c8b8a0"))
			draw_rect(Rect2(px - 4.0, -tier + 20.0, 28.0, 8.0), Color("e8d8c0"))
		E.banner(self, Vector2(w * 0.5, -tier + 20.0), 50.0, tier - 40.0, float(Engine.get_process_frames()) / 60.0)


# ---- מדורת טקס ----
class Brazier extends Node2D:
	const CYCLE := Vector2(4.0, 6.5)
	const WARN_T := 1.0
	const FLARE_T := 0.9
	const R := 110.0
	const TICK := 0.3
	var flares := 0                 # לבדיקות
	var burns := 0
	var _t := 2.0
	var _state := 0                 # 0 = בוער רגיל, 1 = גחלים מתלקחות, 2 = לשון אש
	var _tick := 0.0
	var _tt := 0.0

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-R, -120), Vector2(R * 2.0, 120))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _state != 0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t -= delta
		_tick -= delta
		_tt += delta
		match _state:
			0:
				if _t <= 0.0:
					_state = 1
					_t = WARN_T
			1:
				if _t <= 0.0:
					_state = 2
					_t = FLARE_T
					flares += 1
					preload("res://sfx.gd").play("rp_whoosh", global_position, 0.0, 0.1, 2)
			2:
				if _tick <= 0.0:
					_tick = TICK
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and pl.global_position.distance_to(global_position) < R:
						burns += 1
						pl.hurt(1, Vector2(signf(pl.global_position.x - global_position.x + 0.01), -0.5))
					for z in get_tree().get_nodes_in_group("zombies"):
						if not z.dead and not z.is_boss() and z.global_position.distance_to(global_position) < R and z.has_method("ignite"):
							z.ignite(2.0)
				if _t <= 0.0:
					_state = 0
					_t = randf_range(CYCLE.x, CYCLE.y)
		if Art.on_screen(self, global_position + Vector2(0, -60), R + 50.0) and Engine.get_physics_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(-14, 0), Vector2(0, -40), Color("8a6a30"), 3.0)   # רגליים
		draw_line(Vector2(14, 0), Vector2(0, -40), Color("8a6a30"), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-26, -50), Vector2(26, -50), Vector2(18, -36), Vector2(-18, -36)]), Color("c8a040"))   # הקערה
		E.emblem(self, Vector2(0, -43), 4.5)
		var big := 1.0
		if _state == 1:
			big = 1.3 + 0.2 * sin(_tt * 30.0)
		elif _state == 2:
			big = 3.0
		for q in 5:
			var fx := -16.0 + float(q) * 8.0
			var fh := (16.0 + 8.0 * absf(sin(_tt * 8.0 + float(q)))) * big
			draw_colored_polygon(PackedVector2Array([Vector2(fx - 6, -50), Vector2(fx + 6, -50), Vector2(fx + sin(_tt * 10.0 + float(q)) * 3.0, -50 - fh)]), Color(1.0, 0.5 + 0.1 * float(q % 3), 0.1, 0.9))
		if _state == 2:
			for q in 8:
				var a := float(q) / 8.0 * TAU + _tt * 2.0
				draw_circle(Vector2(0, -60) + Vector2.from_angle(a) * R * 0.7, 14.0, Color(1.0, 0.45, 0.1, 0.5))
		Art.glow(self, Vector2(0, -60), 50.0 * big, Color(1.0, 0.5, 0.2, 0.15))


# ---- כרזה תלויה ----
class HangingBanner extends Node2D:
	const WARN_T := 0.7
	const H := 170.0                # גובה החבל
	const DMG := 2
	const DMG_Z := 60
	const W := 90.0
	var state := 0                  # 0 = תלויה, 1 = חורקת, 2 = נופלת, 3 = על הרצפה
	var falls := 0                  # לבדיקות
	var hits := 0
	var crushed := 0
	var shot := false
	var _t := 0.0
	var _y := 0.0                   # כמה ירדה
	var _vy := 0.0
	var _rope: StaticBody2D = null

	class Rope extends StaticBody2D:
		var b = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if b != null and b.state <= 1:
				b.shot = true
				b._drop()

	func _ready() -> void:
		z_index = 6
		add_to_group("hazards")
		var r := Rope.new()
		r.b = self
		r.collision_layer = 4   # כדורים פוגעים בחבל (כמו זומבי), שום דבר לא נתקע בו
		r.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(10, 40)
		cs.shape = sh
		cs.position = Vector2(0, -H - 30.0)
		r.add_child(cs)
		add_child(r)
		_rope = r

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -H), Vector2(W, H))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (state == 1 or state == 2) and world_rect().grow(margin).has_point(p)

	func _drop() -> void:
		state = 2
		_vy = 0.0
		falls += 1
		preload("res://sfx.gd").play("rp_snap", global_position + Vector2(0, -H), 0.0, 0.1, 2)
		if is_instance_valid(_rope):
			_rope.queue_free()

	func _physics_process(delta: float) -> void:
		match state:
			0:
				var pl := get_tree().get_first_node_in_group("player")
				if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < W * 0.5 and absf(pl.global_position.y - global_position.y) < 20.0:
					state = 1
					_t = WARN_T
					preload("res://sfx.gd").play("rp_creak", global_position + Vector2(0, -H), -2.0, 0.1, 2)
			1:
				_t -= delta
				if _t <= 0.0:
					_drop()
			2:
				_vy += 1600.0 * delta
				_y += _vy * delta
				if _y >= H - 10.0:
					_y = H - 10.0
					state = 3
					_land()
		if state != 3 or Engine.get_physics_frames() % 30 == 0:
			queue_redraw()

	func _land() -> void:
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -6), "smoke", Vector2.UP, 8)
		var r := Rect2(global_position + Vector2(-W * 0.5, -60), Vector2(W, 60))
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and r.intersects(pl.body_rect()):
			hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 1.5, -0.6))
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and not z.is_boss() and r.has_point(z.global_position + Vector2(0, -10)):
				crushed += 1
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2.DOWN, true, {"source": "hazard", "fixed": DMG_Z})

	func _draw() -> void:
		var top := -H + _y
		if state <= 1:
			var sw := sin(float(Engine.get_physics_frames()) * 0.6) * 3.0 if state == 1 else 0.0
			draw_line(Vector2(0, -H - 60.0), Vector2(sw, top), Color("6a5030"), 2.0)   # החבל
			if state == 1:
				draw_string(ThemeDB.fallback_font, Vector2(-8, -H - 70.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.4, 0.2))
		draw_rect(Rect2(-W * 0.5 - 6.0, top - 4.0, W + 12.0, 6.0), Color("c8a040"))   # מוט
		var bh := minf(130.0, -top - 4.0)
		if state < 3 and bh > 40.0:
			E.banner(self, Vector2(0, top + 2.0), W, bh, float(Engine.get_physics_frames()) / 60.0)
		elif state < 3:   # כמעט על הרצפה - הבד מתקפל
			draw_rect(Rect2(-W * 0.5, top + 2.0, W, maxf(-top - 2.0, 4.0)), E.RED_D)
		else:   # על הרצפה - בד מקופל
			draw_rect(Rect2(-W * 0.5, -10, W, 10), E.RED_D)
			draw_rect(Rect2(-W * 0.5, -10, W, 3), E.RED)


# ---- במת הכס ----
class Throne extends Node2D:
	var w := 520.0
	var tier := 90.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for s in 4:   # מדרגות
			var sh := tier / 4.0
			draw_rect(Rect2(float(s) * 18.0, -sh * float(s + 1), w - float(s) * 36.0, sh), Color("6a1414").darkened(0.08 * float(s)))
			draw_rect(Rect2(float(s) * 18.0, -sh * float(s + 1), w - float(s) * 36.0, 3.0), Color("c8a040"))
		# וילון ענק מאחור
		var cx := w * 0.5
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 220, -tier), Vector2(cx - 200, -tier - 300), Vector2(cx + 200, -tier - 300), Vector2(cx + 220, -tier)]), Color("5a0e0e"))
		for q in 9:
			draw_line(Vector2(cx - 200.0 + float(q) * 50.0, -tier - 296.0), Vector2(cx - 210.0 + float(q) * 52.5, -tier), Color("4a0a0a"), 3.0)
		draw_rect(Rect2(cx - 210.0, -tier - 310.0, 420.0, 14.0), Color("c8a040"))
		E.emblem(self, Vector2(cx, -tier - 230.0), 40.0)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "statue"
	var size := Vector2(50, 60)
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
			"statue":   # פסל על כן (זומבי אצילי)
				draw_rect(Rect2(0, -h * 0.35, w, h * 0.35), Color("a89880"))
				draw_rect(Rect2(-2, -h * 0.38, w + 4, 4), Color("c8b8a0"))
				var c := Vector2(w * 0.5, -h * 0.35)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 0), c + Vector2(9, 0), c + Vector2(7, -h * 0.4), c + Vector2(-7, -h * 0.4)]), Color("b8a890"))
				draw_circle(c + Vector2(0, -h * 0.48), 7.0, Color("b8a890"))
				draw_line(c + Vector2(6, -h * 0.35), c + Vector2(14, -h * 0.58), Color("b8a890"), 3.0)
			"urn":   # כד ענק עם הורטנזיות
				var c2 := Vector2(w * 0.5, -h * 0.4)
				draw_colored_polygon(Art.ellipse(c2, w * 0.45, h * 0.32, 0.0, 16), Color("c8b8a0"))
				draw_rect(Rect2(w * 0.3, -h * 0.12, w * 0.4, h * 0.12), Color("a89880"))
				for q in 5:
					draw_circle(Vector2(w * 0.2 + float(q) * w * 0.15, -h * 0.75), 6.0, Color(0.45, 0.5, 0.95, 0.9))
			_:   # גדר חיה מעוצבת
				draw_rect(Rect2(0, -h, w, h), Color("1e3a24"))
				for q in int(w / 10.0):
					draw_circle(Vector2(5.0 + float(q) * 10.0, -h), 6.0, Color("2a4a2e"))


# ---- עלי כותרת ואפר (מסך) ----
class PalaceFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		for i in 20:
			var x := fposmod(float(i) * 71.0 + sin(_t * 0.8 + float(i)) * 40.0 + _t * 10.0, vp.x)
			var y := fposmod(float(i) * 53.0 + _t * (25.0 + float(i % 4) * 8.0), vp.y)
			var c := Color(0.8, 0.15, 0.15, 0.7) if i % 3 != 0 else Color(0.3, 0.3, 0.3, 0.5)
			draw_colored_polygon(Art.ellipse(Vector2(x, y), 3.0, 1.6, _t * 2.0 + float(i), 6), c)
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.3, 0.05, 0.1, 0.05))
