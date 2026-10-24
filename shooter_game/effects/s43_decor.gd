extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 43 ("WAR FACTORY") - וולטה רדונדה, עיר הפלדה של ברזיל. אזור חמישי, שלב 7.
#  אימפריית המתים השתלטה על מפעל הפלדה: תנורי ההתכה בוערים, ובאולם ההרכבה הענק פס ייצור של טנקים.
#    furnace_sky   - (רקע) שמיים כתומים-אפורים מאובך המפעל, ניצוצות
#    far_steelworks- (רקע) תנורי התכה (blast furnaces), ארובות עם עשן, נהר הפראיבה, אור פלדה מותכת
#    mid_hall      - (רקע) אולם ההרכבה: חלונות גג משוננים, גופי טנקים תלויים על עגורנים, כרזות
#    near_girders  - (רקע) קורות פלדה, שרשראות עם ווים, מנורות תעשייה
#    FactoryGround - (עולם) רצפת בטון עם פסי סימון צהוב-שחור
#    Catwalk       - (עולם) גשר שירות מפלדה מחוררת (הקומה = add_floor) עם מעקה
#    Conveyor      - (עולם, מלכודת) מסוע: מזיז אותך ואת הזומבים (SPEED), עם חלקי טנק שנוסעים עליו
#    Press         - (עולם, מלכודת) מכבש הטבעה: עולה, אזהרה (WARN_T - אור + שריקת קיטור), נוחת. נזק כבד לשחקן, מרסק זומבים.
#                    FOREMAN יכול להפעיל אותו מוקדם כשאתה מתחתיו (rush() - אזהרה קצרה RUSH_WARN).
#    Obstacle      - (מוצק + מחסה) "steel_coil" גליל פלדה / "parts_bin" ארגז חלקים / "road_wheel" גלגלי טנק
#    FactoryFX     - (מסך) ניצוצות ריתוך ואובך חם
#  לשנות: Conveyor.SPEED, Press.CYCLE / WARN_T / RUSH_WARN / DMG / DMG_Z.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const E := preload("res://enemies/empire_kit.gd")


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func furnace_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("2a1c1e"), Color("5a3428"), Color("a0542a"), Color("d88a3a")], 0.9)
	for i in 14:   # ניצוצות באוויר
		var x := fposmod(float(i) * 131.0 + t * (8.0 + float(i % 4) * 3.0), v.x)
		var y := v.y * 0.75 - fposmod(t * (20.0 + float(i % 5) * 6.0) + float(i) * 47.0, v.y * 0.7)
		DrawBatch.circle(ci, Vector2(x, y), 1.4, Color(1.0, 0.7, 0.3, 0.6))


# ---- תנורי התכה, ארובות, הנהר ----
static func far_steelworks(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	DrawBatch.rect(ci, Rect2(0, y - 24.0, v.x, v.y - y + 24.0), Color("2a2224"))
	DrawBatch.rect(ci, Rect2(0, y - 30.0, v.x, 8.0), Color(0.9, 0.5, 0.25, 0.25))   # הנהר משקף את האש
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	var c := Color("3a2c2c")
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		for f in 2:   # תנורי התכה: מגדל גלילי + צינורות + מגדלי קירור
			var fx := bx + 120.0 + float(f) * 300.0
			DrawBatch.rect(ci, Rect2(fx - 30.0, y - 250.0, 60.0, 226.0), c)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(fx - 30.0, y - 250.0), Vector2(fx + 30.0, y - 250.0), Vector2(fx + 16.0, y - 290.0), Vector2(fx - 16.0, y - 290.0)]), c)
			DrawBatch.line(ci, Vector2(fx + 16.0, y - 280.0), Vector2(fx + 90.0, y - 200.0), c.lightened(0.05), 8.0)   # צינור גז
			DrawBatch.rect(ci, Rect2(fx + 80.0, y - 210.0, 30.0, 186.0), c)
			for q in 3:   # טבעות
				DrawBatch.rect(ci, Rect2(fx - 32.0, y - 230.0 + float(q) * 60.0, 64.0, 5.0), c.lightened(0.08))
			var glow := 0.5 + 0.5 * sin(t * 1.3 + float(k * 2 + f))
			Art.glow(ci, Vector2(fx, y - 40.0), 60.0, Color(1.0, 0.45, 0.1, 0.25 + 0.15 * glow))   # פלדה מותכת בבסיס
			Kit.smoke_column(ci, Vector2(fx, y - 290.0), t + float(f) * 3.0, 200.0, Color(0.18, 0.14, 0.14, 0.35), 50.0)
		for q in 3:   # ארובות
			var cx := bx + 650.0 + float(q) * 60.0
			DrawBatch.rect(ci, Rect2(cx, y - 320.0, 18.0, 296.0), c.darkened(0.1))
			DrawBatch.rect(ci, Rect2(cx, y - 300.0, 18.0, 6.0), E.RED_D)
			Kit.smoke_column(ci, Vector2(cx + 9.0, y - 320.0), t + float(q), 240.0, Color(0.16, 0.12, 0.12, 0.35), 70.0)
		E.flag(ci, Vector2(bx + 840.0, y - 280.0), 70.0, 44.0, t * 0.7, k)
		DrawBatch.line(ci, Vector2(bx + 840.0, y - 24.0), Vector2(bx + 840.0, y - 280.0), Color("2a2020"), 3.0)


# ---- אולם ההרכבה ----
static func mid_hall(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := 60.0
	# גג משונן (חלונות)
	var period := 160.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(x, top + 50.0), Vector2(x + 110.0, top), Vector2(x + 110.0, top + 50.0)]), Color(1.0, 0.75, 0.45, 0.18))
		DrawBatch.line(ci, Vector2(x, top + 50.0), Vector2(x + 110.0, top), Color("2a2224"), 3.0)
		DrawBatch.line(ci, Vector2(x + 110.0, top), Vector2(x + 110.0, top + 50.0), Color("2a2224"), 3.0)
	DrawBatch.rect(ci, Rect2(0, top + 50.0, v.x, 10.0), Color("2a2224"))
	# גופי טנקים תלויים + כרזות
	var p2 := 640.0
	var s2 := int(floor(sc / p2)) - 1
	for k in range(s2, s2 + int(ceil(v.x / p2)) + 2):
		var x := float(k) * p2 - sc
		var hy := top + 180.0 + sin(t * 0.5 + float(k)) * 4.0
		DrawBatch.line(ci, Vector2(x + 120.0, top + 60.0), Vector2(x + 120.0, hy - 30.0), Color("1e1a1a"), 2.0)
		DrawBatch.line(ci, Vector2(x + 70.0, hy - 20.0), Vector2(x + 120.0, hy - 30.0), Color("1e1a1a"), 1.5)
		DrawBatch.line(ci, Vector2(x + 170.0, hy - 20.0), Vector2(x + 120.0, hy - 30.0), Color("1e1a1a"), 1.5)
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(x + 50.0, hy - 20.0), Vector2(x + 190.0, hy - 20.0), Vector2(x + 205.0, hy), Vector2(x + 190.0, hy + 22.0), Vector2(x + 50.0, hy + 22.0), Vector2(x + 38.0, hy)]), Color("3a3634"))
		E.emblem(ci, Vector2(x + 120.0, hy + 2.0), 9.0)
		E.banner(ci, Vector2(x + 400.0, top + 64.0), 46.0, 150.0, t + float(k))
		# קירות האולם: עמודים
		DrawBatch.rect(ci, Rect2(x + 300.0, top + 60.0, 22.0, y - top - 60.0), Color("2e2828"))
	DrawBatch.rect(ci, Rect2(0, y - 40.0, v.x, v.y - y + 40.0), Color("241e1e"))
	for q in 6:   # עמדות ריתוך רחוקות - ניצוצות
		var wx := fposmod(float(q) * 260.0 - sc * 1.0, v.x + 100.0) - 50.0
		if fposmod(t * 3.0 + float(q) * 1.3, 2.0) < 0.6:
			Art.glow(ci, Vector2(wx, y - 50.0), 14.0, Color(0.7, 0.85, 1.0, 0.5))


# ---- קורות ושרשראות ----
static func near_girders(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	DrawBatch.rect(ci, Rect2(0, 0, v.x, 16.0), Color("1a1616"))
	var period := 420.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		DrawBatch.rect(ci, Rect2(x, 16.0, 30.0, y - 16.0), Color("231e1e"))   # עמוד I
		DrawBatch.rect(ci, Rect2(x - 6.0, 16.0, 42.0, 6.0), Color("2c2626"))
		for q in 6:   # חיזוק X
			var yy := 40.0 + float(q) * 90.0
			DrawBatch.line(ci, Vector2(x + 2.0, yy), Vector2(x + 28.0, yy + 45.0), Color("2c2626"), 2.0)
			DrawBatch.line(ci, Vector2(x + 28.0, yy), Vector2(x + 2.0, yy + 45.0), Color("2c2626"), 2.0)
		var sw := sin(t * 0.9 + float(k) * 2.0) * 6.0   # שרשרת עם וו
		var hx := x + 200.0
		for q in 12:
			DrawBatch.circle(ci, Vector2(hx + sw * float(q) / 12.0, 16.0 + float(q) * 12.0), 3.0, Color("161212"))
		DrawBatch.arc(ci, Vector2(hx + sw, 16.0 + 12.0 * 12.0 + 8.0), 8.0, 0.0, PI * 1.3, 8, Color("161212"), 3.0)
		Art.glow(ci, Vector2(x + 330.0, 40.0), 30.0, Color(1.0, 0.8, 0.5, 0.12))   # מנורה תעשייתית
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(x + 316.0, 34.0), Vector2(x + 344.0, 34.0), Vector2(x + 338.0, 26.0), Vector2(x + 322.0, 26.0)]), Color("161212"))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("161212"))


# ============================================================
#  עולם
# ============================================================
class FactoryGround extends Node2D:
	var w := 1024.0
	var depth := 90.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("3a3634"))
		DrawBatch.rect(self, Rect2(0, 0, w, 4.0), Color("5a5450"))
		var x := 0.0
		while x < w:   # פס אזהרה צהוב-שחור
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x, 8), Vector2(x + 10, 8), Vector2(x + 16, 14), Vector2(x + 6, 14)]), Color("c8a020"))
			x += 20.0
		x = 30.0
		while x < w:   # כתמי שמן
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x, 30.0), 24.0, 5.0, 0.0, 10), Color(0.1, 0.09, 0.08, 0.5))
			x += 270.0


class Catwalk extends Node2D:   # גשר שירות (הקומה = add_floor)
	var w := 380.0
	var tier := 150.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, -tier, w, 8.0), Color("5a524c"))
		var x := 0.0
		while x < w:   # רשת מחוררת
			DrawBatch.rect(self, Rect2(x + 2.0, -tier + 2.0, 4.0, 4.0), Color("2a2624"))
			x += 8.0
		for q in int(w / 20.0) + 1:
			DrawBatch.line(self, Vector2(float(q) * 20.0, -tier), Vector2(float(q) * 20.0, -tier - 24.0), Color("c8a020"), 1.5)
		DrawBatch.line(self, Vector2(0, -tier - 24.0), Vector2(w, -tier - 24.0), Color("c8a020"), 2.5)
		DrawBatch.line(self, Vector2(0, -tier - 12.0), Vector2(w, -tier - 12.0), Color("c8a020"), 1.2)
		for px in [6.0, w - 16.0]:
			DrawBatch.rect(self, Rect2(px, -tier + 8.0, 10.0, tier - 8.0), Color("3a3430"))
			for q in int((tier - 8.0) / 30.0):
				DrawBatch.line(self, Vector2(px, -tier + 8.0 + float(q) * 30.0), Vector2(px + 10.0, -tier + 38.0 + float(q) * 30.0), Color("4a4440"), 1.5)


# ---- מסוע ----
class Conveyor extends Node2D:
	const SPEED := 110.0
	var w := 300.0
	var dir := 1.0                  # 1 = ימינה
	var carried := 0.0              # לבדיקות (פיקסלים שהשחקן הוזז)
	var _off := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("conveyors")

	func on_belt(n: Node2D) -> bool:
		return n.is_on_floor() and n.global_position.x > global_position.x and n.global_position.x < global_position.x + w \
				and absf(n.global_position.y - global_position.y) < 6.0

	func _physics_process(delta: float) -> void:
		_off = fposmod(_off + SPEED * dir * delta, 24.0)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and on_belt(pl):
			pl.global_position.x += SPEED * dir * delta
			carried += SPEED * delta
		if Engine.get_physics_frames() % 2 == 0:
			for z in get_tree().get_nodes_in_group("zombies"):
				if not z.dead and not z.is_boss() and on_belt(z):
					z.global_position.x += SPEED * dir * delta * 2.0
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -10), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, -6, w, 6), Color("1e1c1c"))   # הרצועה
		var x := _off - 24.0
		while x < w:
			if x >= 0.0:
				DrawBatch.line(self, Vector2(x, -6), Vector2(x + 6.0 * dir, -1), Color("3a3634"), 1.5)
			x += 24.0
		DrawBatch.rect(self, Rect2(-4, -2, w + 8, 4), Color("4a4440"))
		for q in int(w / 30.0) + 1:   # גלגלות
			DrawBatch.circle(self, Vector2(float(q) * 30.0, 2), 3.0, Color("5a5450"))
		# חיצי כיוון
		for q in int(w / 100.0):
			var ax := 50.0 + float(q) * 100.0
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(ax - 6.0 * dir, -14), Vector2(ax + 6.0 * dir, -10), Vector2(ax - 6.0 * dir, -6)]), Color(0.9, 0.7, 0.1, 0.6))


# ---- מכבש הטבעה ----
class Press extends Node2D:
	const CYCLE := Vector2(3.5, 5.0)
	const WARN_T := 1.1
	const RUSH_WARN := 0.5
	const SLAM_T := 0.12
	const HOLD_T := 0.5
	const W := 110.0
	const H := 150.0              # כמה גבוה הפטיש כשהוא למעלה
	const DMG := 3
	const DMG_Z := 80
	var state := 0                  # 0 = למעלה, 1 = אזהרה, 2 = נוחת/למטה, 3 = עולה
	var slams := 0                  # לבדיקות
	var hits := 0
	var crushed := 0
	var rushed := 0
	var _t := 2.0
	var _y := 0.0                   # 0 = למעלה, 1 = למטה
	var _rush_cycle := false

	func _ready() -> void:
		z_index = 6
		add_to_group("hazards")
		add_to_group("presses")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -H), Vector2(W, H))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != 0 and world_rect().grow(margin).has_point(p)

	func under(n: Node2D) -> bool:
		return absf(n.global_position.x - global_position.x) < W * 0.5 and n.global_position.y <= global_position.y + 4.0 and n.global_position.y > global_position.y - H

	func rush() -> bool:   # FOREMAN: "PRESS NOW!"
		if state != 0:
			return false
		state = 1
		_t = RUSH_WARN
		rushed += 1
		_rush_cycle = true
		preload("res://sfx.gd").play("wf_hiss", global_position + Vector2(0, -H), 2.0, 0.05, 2)
		return true

	func _physics_process(delta: float) -> void:
		_t -= delta
		match state:
			0:
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					preload("res://sfx.gd").play("wf_hiss", global_position + Vector2(0, -H), -2.0, 0.05, 2)
			1:
				if _t <= 0.0:
					state = 2
					_t = SLAM_T + HOLD_T
					slams += 1
			2:
				if _y < 1.0:
					_y = minf(_y + delta / SLAM_T, 1.0)
					if _y >= 1.0:
						_slam()
				if _t <= 0.0:
					state = 3
			3:
				_y = maxf(_y - delta * 1.5, 0.0)
				if _y <= 0.0:
					state = 0
					_t = randf_range(CYCLE.x, CYCLE.y)
		if Art.on_screen(self, global_position + Vector2(0, -H * 0.5), W + 100.0):
			queue_redraw()

	func _slam() -> void:
		preload("res://sfx.gd").play("wf_slam", global_position, 2.0, 0.05, 2)
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -4), "spark", Vector2.UP, 10)
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position, 300.0):
			cam.shake(6.0, 0.2)
		var pl := get_tree().get_first_node_in_group("player")
		var was_rush := _rush_cycle
		_rush_cycle = false
		if was_rush and pl != null and not under(pl):   # FOREMAN הפעיל ואתה ברחת בזמן -> מנהלי העבודה לומדים
			var m := get_parent()
			m.set_meta("press_dodge", (int(m.get_meta("press_dodge")) if m.has_meta("press_dodge") else 0) + 1)
		if pl != null and not pl.dead and under(pl):
			hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 2.0, -0.5))
			pl.velocity.x = signf(pl.global_position.x - global_position.x + 0.01) * 420.0
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and not z.is_boss() and under(z):
				crushed += 1
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2.DOWN, true, {"source": "hazard", "fixed": DMG_Z})

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		# מסגרת
		DrawBatch.rect(self, Rect2(-W * 0.5 - 16.0, -H - 40.0, 12.0, H + 40.0), Color("4a3a34"))
		DrawBatch.rect(self, Rect2(W * 0.5 + 4.0, -H - 40.0, 12.0, H + 40.0), Color("4a3a34"))
		DrawBatch.rect(self, Rect2(-W * 0.5 - 16.0, -H - 52.0, W + 32.0, 14.0), Color("5a4840"))
		E.emblem(self, Vector2(0, -H - 45.0), 6.0)
		# הבוכנה + הפטיש
		var hy := -H + (H - 14.0) * _y
		DrawBatch.rect(self, Rect2(-8.0, -H - 38.0, 16.0, hy + H + 38.0), Color("8a8a90"))
		DrawBatch.rect(self, Rect2(-W * 0.5, hy - 26.0, W, 26.0), Color("5a5658"))
		DrawBatch.rect(self, Rect2(-W * 0.5, hy - 4.0, W, 4.0), Color("2a2828"))
		var x := -W * 0.5
		while x < W * 0.5:   # פסי אזהרה על הפטיש
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x, hy - 26.0), Vector2(x + 10.0, hy - 26.0), Vector2(x + 20.0, hy - 16.0), Vector2(x + 10.0, hy - 16.0)]), Color("c8a020"))
			x += 20.0
		DrawBatch.rect(self, Rect2(-W * 0.5 - 6.0, -6.0, W + 12.0, 6.0), Color("3a3634"))   # הסדן
		if state == 1:   # אזהרה: מנורה אדומה + קיטור
			var on := fposmod(_t * 6.0, 1.0) < 0.5
			Art.glow(self, Vector2(W * 0.5 + 10.0, -H - 46.0), 12.0, Color(1.0, 0.2, 0.1, 0.9 if on else 0.3))
			for q in 3:
				DrawBatch.circle(self, Vector2(-W * 0.5 + 10.0 + float(q) * 40.0, hy - 30.0 - fposmod(_t * 60.0 + float(q) * 9.0, 30.0)), 6.0, Color(0.9, 0.9, 0.9, 0.3))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "steel_coil"
	var size := Vector2(60, 50)
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
			"steel_coil":   # גליל פלדה על משטח
				var c := Vector2(w * 0.5, -h * 0.5)
				DrawBatch.colored_polygon(self, Art.ellipse(c, w * 0.5, h * 0.5, 0.0, 20), Color("6a6e74"))
				for q in 4:
					DrawBatch.arc(self, c, h * 0.5 - float(q) * 5.0, 0.0, TAU, 20, Color("4a4e54"), 1.2)
				DrawBatch.circle(self, c, h * 0.16, Color("1a1a1c"))
			"parts_bin":   # ארגז חלקים עם הסמל
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, -h), Vector2(0, -h)]), Color("5a4a30"), 0.15, 0.35, Art.OUTLINE, 1.2)
				for q in 4:
					DrawBatch.circle(self, Vector2(w * 0.2 + float(q) * w * 0.2, -h + 3.0), 4.0, Color("6a6a6a"))
				E.emblem(self, Vector2(w * 0.5, -h * 0.45), h * 0.18)
			_:   # גלגלי טנק בערימה
				for q in 3:
					var c2 := Vector2(w * (0.25 + 0.5 * float(q % 2)) + (w * 0.0 if q < 2 else 0.0), -h * 0.3 - (h * 0.4 if q == 2 else 0.0))
					if q == 2:
						c2.x = w * 0.5
					DrawBatch.circle(self, c2, h * 0.3, Color("2a2a2a"))
					DrawBatch.circle(self, c2, h * 0.18, Color("5a5a5a"))
					DrawBatch.circle(self, c2, h * 0.06, Color("2a2a2a"))


# ---- ניצוצות (מסך) ----
class FactoryFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for i in 16:
			var x := fposmod(float(i) * 83.0 + _t * (12.0 + float(i % 3) * 5.0), vp.x)
			var y := vp.y - fposmod(_t * (40.0 + float(i % 4) * 12.0) + float(i) * 53.0, vp.y)
			DrawBatch.circle(self, Vector2(x, y), 1.3, Color(1.0, 0.65, 0.25, 0.55))
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.5, 0.25, 0.1, 0.05))
