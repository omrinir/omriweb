extends RefCounted
# ============================================================
#  קישוטים לשלב 41 ("THE PARADE") - ברזיליה בדמדומים: מצעד הניצחון של אימפריית המתים. אזור חמישי, שלב 5.
#  בניין הקונגרס (שני המגדלים, הכיפה והקערה ההפוכה) עטוף בכרזות אדומות, הקתדרלה (כתר של עמודים מעוקלים),
#  שורת בנייני המשרדים בשדרה עם כרזות, טורי חיילים צועדים, זרקורים חוצים את השמיים, זיקוקי הצדעה.
#    capital_sky     - (רקע) דמדומים, 4 זרקורים שמתנודדים, זיקוקי הצדעה אדומים-לבנים
#    far_capital     - (רקע) הקונגרס + כרזות, הקתדרלה, תורן דגל ענק עם דגל האימפריה
#    mid_ministries  - (רקע) בנייני המשרדים עם כרזות, טורי חיילים צועדים בשדרה
#    near_posts      - (רקע) עמודי תאורה עם דגלים, מחסומי קהל
#    AvenueGround    - (עולם) אספלט רחב, קווי מצעד אדומים
#    ReviewStand     - (עולם) יציע כבוד מדורג עם וילונות אדומים (הקומה = add_floor) + מדרגות
#    TankColumn      - (עולם, מלכודת) טור טנקים חוצה את השדרה: אורות אדומים + רעם = אזהרה -> 3 טנקים דורסים כל מה שעל הכביש.
#                      חיילי האימפריה "יודעים" - יוצאים מהנתיב EARLY שניות לפני האזעקה (goal_x) - רמז! עלו על היציע!
#    SaluteGun       - (עולם, מלכודת) תותח הצדעה טקסי: פתיל בוער (אזהרה) -> גל הדף שזורק ומסחרר
#    Obstacle        - (מוצק + מחסה) "crowd_barrier" מחסום קהל / "planter" עציץ בטון עם פרחים אדומים / "drum_stack" תופים
#    ParadeFX        - (מסך) נייר טיקר אדום-לבן שנופל, אובך זרקורים
#  לשנות: TankColumn.CYCLE / WARN_T / SPEED / DMG_Z, SaluteGun.CYCLE / R / DAZE_T.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const E := preload("res://enemies/empire_kit.gd")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)


# טנק קטן (רקע / טור) - p = אמצע התחתית, dir = לאן פונה
static func tank(ci: CanvasItem, p: Vector2, s: float, dir: float, col := Color("3e4232"), t := 0.0, with_flag := true) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-40, 0) * s, p + Vector2(40, 0) * s, p + Vector2(46, -10) * s, p + Vector2(-46, -10) * s]), col.darkened(0.3))
	for q in 6:
		ci.draw_circle(p + Vector2(-32.0 + float(q) * 13.0, -5.0) * s, 4.0 * s, col.darkened(0.55))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-44, -10) * s, p + Vector2(44, -10) * s, p + Vector2(36, -22) * s, p + Vector2(-40, -22) * s]), col)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, -22) * s, p + Vector2(18, -22) * s, p + Vector2(14, -34) * s, p + Vector2(-16, -34) * s]), col.lightened(0.05))
	ci.draw_line(p + Vector2(dir * 14.0, -28.0) * s, p + Vector2(dir * 62.0, -29.0) * s, col.darkened(0.35), 4.0 * s)
	E.emblem(ci, p + Vector2(0, -28) * s, 4.5 * s)
	if with_flag:
		ci.draw_line(p + Vector2(-dir * 14.0, -34.0) * s, p + Vector2(-dir * 18.0, -62.0) * s, Color("2a2a2a"), 1.2)
		E.flag(ci, p + Vector2(-dir * 18.0, -62.0) * s, 22.0 * s, 14.0 * s, t, int(p.x) % 5, s > 0.8)


# ---- דמדומים, זרקורים, זיקוקי הצדעה ----
static func capital_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("10142e"), Color("2a2450"), Color("7a3a58"), Color("e07a4a")], 0.9)
	for i in 4:   # זרקורים
		var base := Vector2(v.x * (0.12 + 0.25 * float(i)), v.y * 0.8)
		var a := -PI * 0.5 + sin(t * 0.35 + float(i) * 1.7) * 0.5
		var tip := base + Vector2.from_angle(a) * v.y * 1.1
		var nrm := Vector2.from_angle(a + PI * 0.5)
		ci.draw_colored_polygon(PackedVector2Array([base - nrm * 4.0, base + nrm * 4.0, tip + nrm * 50.0, tip - nrm * 50.0]), Color(1.0, 0.97, 0.85, 0.07))
	var cyc := fposmod(t, 4.0)   # זיקוק הצדעה
	if cyc < 1.4:
		var k := floori(t / 4.0)
		var c0 := Vector2(v.x * (0.15 + 0.7 * _h(k, 5)), v.y * (0.1 + 0.15 * _h(k, 6)))
		for q in 18:
			var d := Vector2.from_angle(float(q) / 18.0 * TAU) * cyc * 70.0
			var col := Color(1.0, 0.25, 0.2) if q % 2 == 0 else Color(1, 1, 1)
			ci.draw_circle(c0 + d + Vector2(0, cyc * cyc * 14.0), 2.0, Color(col, 1.0 - cyc / 1.4))


# ---- הקונגרס, הקתדרלה, תורן הדגל ----
static func far_capital(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	ci.draw_rect(Rect2(0, y - 30.0, v.x, v.y - y + 30.0), Color("2a2a40"))
	var period := 1600.0
	var start := int(floor(sc / period)) - 1
	var c := Color("3a3a54")
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הקונגרס
		var cx := bx + 500.0
		ci.draw_rect(Rect2(cx - 260.0, y - 56.0, 520.0, 26.0), c)   # הפלטפורמה
		ci.draw_rect(Rect2(cx - 34.0, y - 270.0, 26.0, 214.0), c)   # שני המגדלים
		ci.draw_rect(Rect2(cx + 8.0, y - 270.0, 26.0, 214.0), c)
		ci.draw_rect(Rect2(cx - 8.0, y - 180.0, 16.0, 12.0), c)   # הגשר ביניהם
		for q in 18:
			ci.draw_line(Vector2(cx - 32.0, y - 262.0 + float(q) * 11.0), Vector2(cx - 10.0, y - 262.0 + float(q) * 11.0), Color(1.0, 0.85, 0.6, 0.18), 1.0)
		E.banner(ci, Vector2(cx - 21.0, y - 262.0), 22.0, 120.0, t)
		E.banner(ci, Vector2(cx + 21.0, y - 262.0), 22.0, 120.0, t + 1.0)
		var dome := PackedVector2Array()   # הכיפה (הסנאט)
		for q in 13:
			var a := PI + float(q) / 12.0 * PI
			dome.append(Vector2(cx - 150.0, y - 56.0) + Vector2(cos(a) * 44.0, sin(a) * 30.0))
		ci.draw_colored_polygon(dome, c.lightened(0.05))
		var bowl := PackedVector2Array()   # הקערה ההפוכה (בית הנבחרים)
		for q in 13:
			var a := float(q) / 12.0 * PI
			bowl.append(Vector2(cx + 150.0, y - 82.0) + Vector2(cos(a) * 64.0, sin(a) * 24.0))
		ci.draw_colored_polygon(bowl, c.lightened(0.05))
		# הקתדרלה: כתר של עמודים מעוקלים
		var kx := bx + 1100.0
		for q in 9:
			var u := (float(q) / 8.0 - 0.5) * 2.0
			var pts := PackedVector2Array()
			for i in 7:
				var v2 := float(i) / 6.0
				pts.append(Vector2(kx + u * 46.0 * (1.0 - 0.55 * sin(v2 * PI)) + u * 10.0 * v2, y - 30.0 - v2 * 130.0))
			ci.draw_polyline(pts, c.lightened(0.08), 4.0)
		ci.draw_colored_polygon(Art.ellipse(Vector2(kx, y - 35.0), 52.0, 8.0, 0.0, 14), c)
		# תורן ענק עם דגל האימפריה
		var mx := bx + 1400.0
		ci.draw_line(Vector2(mx, y - 30.0), Vector2(mx, y - 330.0), Color("4a4a60"), 3.0)
		E.flag(ci, Vector2(mx, y - 330.0), 110.0, 70.0, t * 0.6, k)


# ---- בנייני המשרדים, טורי חיילים ----
static func mid_ministries(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 300.0
	var start := int(floor(sc / period)) - 1
	ci.draw_rect(Rect2(0, y - 20.0, v.x, v.y - y + 20.0), Color("22223a"))
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var c := Color("2e2e48")
		ci.draw_rect(Rect2(x + 20.0, y - 170.0, 150.0, 150.0), c)
		for row in 9:   # חלונות
			for col in 10:
				if _h(row * 11 + col + k * 97, 2) < 0.45:
					ci.draw_rect(Rect2(x + 26.0 + float(col) * 14.0, y - 162.0 + float(row) * 15.0, 8.0, 8.0), Color(1.0, 0.85, 0.55, 0.45))
		E.banner(ci, Vector2(x + 95.0, y - 168.0), 34.0, 110.0, t + float(k))
	# טורי חיילים צועדים (צלליות קטנות בשורות)
	var march := fposmod(t * 30.0, 18.0)
	var x0 := -fposmod(sc * 1.0 + t * 30.0, 18.0)
	var xx := x0
	var i := int(floor((sc + t * 30.0) / 18.0))
	while xx < v.x + 20.0:
		if _h(int(floor(float(i) / 8.0)), 9) < 0.7:   # קבוצות של 8 עם רווחים
			for row in 2:
				var sy := y - 6.0 - float(row) * 7.0
				var step := 2.0 if (i + row) % 2 == 0 else -2.0
				ci.draw_line(Vector2(xx, sy - 10.0), Vector2(xx, sy - 4.0), Color("14141e"), 3.0)
				ci.draw_circle(Vector2(xx, sy - 12.0), 2.2, Color("14141e"))
				ci.draw_line(Vector2(xx, sy - 4.0), Vector2(xx + step, sy), Color("14141e"), 1.5)
				ci.draw_line(Vector2(xx, sy - 4.0), Vector2(xx - step, sy), Color("14141e"), 1.5)
				ci.draw_line(Vector2(xx + 1.0, sy - 10.0), Vector2(xx + 3.0, sy - 17.0), Color("14141e"), 1.0)   # רובה
		xx += 18.0
		i += 1
	if march < 0.0:
		pass


# ---- עמודי תאורה עם דגלים ----
static func near_posts(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 380.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		ci.draw_line(Vector2(x, y), Vector2(x, y - 130.0), Color("1a1a24"), 4.0)
		ci.draw_line(Vector2(x, y - 126.0), Vector2(x + 24.0, y - 130.0), Color("1a1a24"), 3.0)
		Art.glow(ci, Vector2(x + 26.0, y - 126.0), 22.0, Color(1.0, 0.85, 0.6, 0.25))
		E.flag(ci, Vector2(x + 2.0, y - 112.0), 26.0, 16.0, t, k, false)
		for q in 6:   # מחסום קהל
			ci.draw_line(Vector2(x + 60.0 + float(q) * 40.0, y), Vector2(x + 60.0 + float(q) * 40.0, y - 22.0), Color("1a1a24"), 1.5)
		ci.draw_line(Vector2(x + 60.0, y - 22.0), Vector2(x + 260.0, y - 22.0), Color("1a1a24"), 2.0)
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("14141c"))


# ---- השדרה ----
class AvenueGround extends Node2D:
	var w := 1024.0
	var depth := 90.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		draw_rect(Rect2(0, 0, w, depth), Color("3a3a42"))
		draw_rect(Rect2(0, 0, w, 5.0), Color("5a5a62"))
		draw_rect(Rect2(0, 14, w, 4), Color(0.75, 0.1, 0.1, 0.7))   # קו מצעד אדום
		var x := 0.0
		while x < w:
			draw_rect(Rect2(x, 34.0, 50.0, 3.0), Color(0.9, 0.9, 0.9, 0.5))
			x += 110.0


# ---- יציע כבוד ----
class ReviewStand extends Node2D:
	var w := 320.0
	var tier := 130.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var S := preload("res://effects/s41_decor.gd")
		for r in 4:   # מדרגות היציע
			var ry := -tier + float(r) * (tier / 4.0)
			draw_rect(Rect2(float(r) * 8.0 - 8.0, ry, w - float(r) * 16.0 + 16.0, tier / 4.0), Color("4a4650").darkened(0.06 * float(r)))
		var dr := PackedVector2Array()   # וילון אדום עם קפלים
		for q in 13:
			var x := float(q) / 12.0 * w
			dr.append(Vector2(x, -tier * 0.6 + (8.0 if q % 2 == 1 else 0.0)))
		dr.append(Vector2(w, 0))
		dr.append(Vector2(0, 0))
		draw_colored_polygon(dr, S.E.RED)
		for q in 12:
			draw_line(Vector2(float(q) / 12.0 * w + w / 24.0, -tier * 0.6 + 6.0), Vector2(float(q) / 12.0 * w + w / 24.0, -2.0), S.E.RED_D, 2.0)
		draw_rect(Rect2(-10, -tier - 4, w + 20, 6), Color("b8b0a0"))   # מעקה
		S.E.emblem(self, Vector2(w * 0.5, -tier * 0.32), 22.0)
		for px in [0.0, w]:
			draw_line(Vector2(px, -tier), Vector2(px, -tier - 60.0), Color("2a2a2a"), 2.0)
			S.E.flag(self, Vector2(px, -tier - 60.0), 30.0, 20.0, float(Engine.get_process_frames()) / 60.0, int(px), false)


# ---- טור טנקים ----
class TankColumn extends Node2D:
	const CYCLE := Vector2(13.0, 17.0)
	const WARN_T := 2.0
	const SPEED := 300.0
	const N := 3
	const GAP := 230.0
	const DMG_Z := 40
	const EARLY := 4.0              # כמה שניות לפני האזעקה חיילי האימפריה כבר יוצאים מהנתיב (רמז לשחקן!)
	const TANK := Vector2(190, 70)
	var w := 900.0
	var state := 0                  # 0 = שקט, 1 = אזהרה, 2 = טנקים עוברים
	var passes := 0                 # לבדיקות
	var hits := 0
	var crushed := 0
	var stepped_aside := 0
	var _t := 5.0
	var _x := 0.0                   # מיקום הטנק הראשון (מקומי)
	var _hit := {}
	var _moved := []
	var _early := false

	func _ready() -> void:
		z_index = 7
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -90), Vector2(w, 90))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != 0 and world_rect().grow(margin).has_point(p)

	func tank_rects() -> Array:
		var out := []
		if state != 2:
			return out
		for q in N:
			var tx := _x + float(q) * GAP
			if _vis(tx):
				out.append(Rect2(global_position + Vector2(tx - TANK.x * 0.5, -TANK.y), TANK))
		return out

	# טנק נראה / מסוכן רק בתוך הנתיב: יוצא ממסך עשן בקצה הימני ונעלם במסך עשן בקצה השמאלי
	func _vis(tx: float) -> bool:
		return tx >= TANK.x * 0.5 - 2.0 and tx <= w - TANK.x * 0.5 + 2.0

	func _physics_process(delta: float) -> void:
		_t -= delta
		match state:
			0:
				if _t <= EARLY and not _early:   # חיילי האימפריה "יודעים" את לוח הזמנים - יוצאים מהנתיב לפני האזעקה
					_early = true
					for zz in get_tree().get_nodes_in_group("empire"):
						if not zz.dead and world_rect().grow(20.0).has_point(zz.global_position + Vector2(0, -10)):
							var lx: float = global_position.x - 60.0
							var rx: float = global_position.x + w + 60.0
							zz.goal_x = lx if absf(zz.global_position.x - lx) < absf(zz.global_position.x - rx) else rx
							_moved.append(zz)
							stepped_aside += 1
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and absf(pl.global_position.x - (global_position.x + w * 0.5)) < w + 600.0:
						preload("res://sfx.gd").play("pa_rumble", global_position + Vector2(w * 0.5, -40), 2.0, 0.05, 2)
			1:
				if Engine.get_physics_frames() % 10 == 0:
					var cam: Camera2D = get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position + Vector2(w * 0.5, -40), w):
						cam.shake(3.0, 0.15)
				if _t <= 0.0:
					state = 2
					_x = w - TANK.x * 0.5
					passes += 1
					_hit.clear()
			2:
				_x -= SPEED * delta
				var pl := get_tree().get_first_node_in_group("player")
				var rects := tank_rects()
				for i in rects.size():
					var r: Rect2 = rects[i]
					if pl != null and not pl.dead and not _hit.has(i) and r.intersects(pl.body_rect()):
						_hit[i] = true
						hits += 1
						pl.hurt(2, Vector2(-3.0, -1.5))
						pl.velocity = Vector2(-560.0, -380.0)
					if Engine.get_physics_frames() % 5 == 0:
						for zz in get_tree().get_nodes_in_group("zombies"):
							if not zz.dead and not zz.is_boss() and r.has_point(zz.global_position + Vector2(0, -10)):
								crushed += 1
								zz.take_damage(DMG_Z, zz.global_position + Vector2(0, -30), Vector2(-1, -0.3), false, {"source": "tank", "fixed": DMG_Z})
				if _x + float(N - 1) * GAP < TANK.x * 0.5 - 2.0:
					state = 0
					_early = false
					_t = randf_range(CYCLE.x, CYCLE.y)
					for zz in _moved:
						if is_instance_valid(zz):
							zz.goal_x = INF
					_moved.clear()
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -60), w + 300.0):
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s41_decor.gd")
		if state == 1:   # אורות אדומים מהבהבים לאורך הנתיב + חיצים
			var on := fposmod(_t * 4.0, 1.0) < 0.5
			var x := 0.0
			while x <= w:
				draw_circle(Vector2(x, -4), 4.0, Color(1.0, 0.15, 0.1, 0.9) if on else Color(0.3, 0.05, 0.05, 0.8))
				x += 75.0
			draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 70.0, -200.0), "<<< TANKS <<<", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.3, 0.2, 0.9 if on else 0.5))
		elif state == 2:
			for q in N:
				var tx := _x + float(q) * GAP
				if _vis(tx):
					S.tank(self, Vector2(tx, 0), 2.1, -1.0, Color("3e4232"), float(Engine.get_process_frames()) / 60.0)
					if Engine.get_physics_frames() % 4 == 0:
						preload("res://particles.gd").burst(get_parent(), global_position + Vector2(tx + 90.0, -10.0), "smoke", Vector2.UP, 1)
		if state != 0:   # מסכי עשן בשני קצוות הנתיב (מכסים את הכניסה / היציאה של הטנקים)
			var tt := float(Engine.get_process_frames()) / 60.0
			for ex in [0.0, w]:
				for q in 7:
					var a := float(q) * 0.9 + tt * 0.6
					var c := Vector2(ex + cos(a) * 34.0 + (float(q) - 3.0) * 12.0, -40.0 - absf(sin(a * 1.3)) * 50.0 - float(q % 3) * 14.0)
					draw_circle(c, 46.0 - float(q % 3) * 6.0, Color(0.55, 0.52, 0.5, 0.82))
				draw_circle(Vector2(ex, -46.0), 50.0, Color(0.5, 0.47, 0.45, 0.9))


# ---- תותח הצדעה ----
class SaluteGun extends Node2D:
	const CYCLE := Vector2(6.0, 9.0)
	const WARN_T := 1.2
	const R := 150.0
	const DAZE_T := 0.8
	var fired := 0                  # לבדיקות
	var dazed := 0
	var _t := 3.0
	var _warn := 0.0
	var _ring := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-R, -80), Vector2(R * 2.0, 80))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _warn > 0.0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t -= delta
		_ring = maxf(_ring - delta, 0.0)
		if _warn > 0.0:
			_warn -= delta
			if Engine.get_physics_frames() % 4 == 0:
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(-26, -18), "fire", Vector2.UP, 1)
			if _warn <= 0.0:
				_boom()
		elif _t <= 0.0:
			_t = randf_range(CYCLE.x, CYCLE.y)
			_warn = WARN_T
			preload("res://sfx.gd").play("pa_fuse", global_position, -4.0, 0.1, 2)
		if _warn > 0.0 or _ring > 0.0 or Engine.get_physics_frames() % 10 == 0:
			queue_redraw()

	func _boom() -> void:
		fired += 1
		_ring = 0.5
		preload("res://sfx.gd").play("pa_salute", global_position, 3.0, 0.05, 2)
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(40, -30), "smoke", Vector2(1, -0.3), 14)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.global_position.distance_to(global_position) < R:
			dazed += 1
			var d := signf(pl.global_position.x - global_position.x + 0.01)
			pl.velocity = Vector2(d * 420.0, -320.0)
			if pl.has_method("daze"):
				pl.daze(DAZE_T, "MY EARS ARE RINGING")
		for zz in get_tree().get_nodes_in_group("zombies"):
			if not zz.dead and not zz.is_boss() and zz.global_position.distance_to(global_position) < R:
				zz.velocity = Vector2(signf(zz.global_position.x - global_position.x + 0.01) * 380.0, -260.0)

	func _draw() -> void:
		draw_circle(Vector2(-18, -10), 10.0, Color("3a2a1a"))   # גלגלים
		draw_circle(Vector2(18, -10), 10.0, Color("3a2a1a"))
		draw_circle(Vector2(-18, -10), 3.0, Color("c8a040"))
		draw_circle(Vector2(18, -10), 3.0, Color("c8a040"))
		draw_line(Vector2(-26, -18), Vector2(44, -32), Color("c8a040"), 9.0)   # קנה פליז
		draw_circle(Vector2(44, -32), 5.0, Color("8a6a20"))
		if _warn > 0.0:
			draw_line(Vector2(-26, -18), Vector2(-34, -24), Color(1.0, 0.7, 0.2), 1.5)
			draw_circle(Vector2(-34, -24), 2.5 + sin(_warn * 40.0), Color(1.0, 0.9, 0.4))
		if _ring > 0.0:
			var k := 1.0 - _ring / 0.5
			draw_arc(Vector2(0, -20), R * k, 0.0, TAU, 32, Color(1, 1, 1, 0.5 * (1.0 - k)), 4.0)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "crowd_barrier"
	var size := Vector2(90, 34)
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
		var S := preload("res://effects/s41_decor.gd")
		match kind:
			"crowd_barrier":   # מחסום קהל מתכת עם שלט אדום
				draw_rect(Rect2(0, -h, w, 3), Color("9a9aa0"))
				draw_rect(Rect2(0, -4, w, 3), Color("9a9aa0"))
				for q in int(w / 8.0) + 1:
					draw_line(Vector2(float(q) * 8.0, -h), Vector2(float(q) * 8.0, -4), Color("8a8a90"), 1.2)
				draw_rect(Rect2(w * 0.25, -h * 0.75, w * 0.5, h * 0.4), S.E.RED)
				S.E.emblem(self, Vector2(w * 0.5, -h * 0.55), h * 0.17)
			"planter":   # עציץ בטון עם פרחים אדומים
				Art.fill_shaded(self, PackedVector2Array([Vector2(4, 0), Vector2(w - 4, 0), Vector2(w, -h * 0.7), Vector2(0, -h * 0.7)]), Color("8a8680"), 0.15, 0.35, Art.OUTLINE, 1.2)
				var r := RandomNumberGenerator.new()
				r.seed = seed_v
				for q in int(w / 7.0):
					var fx := 4.0 + float(q) * 7.0
					draw_line(Vector2(fx, -h * 0.7), Vector2(fx + r.randf_range(-2, 2), -h + 4.0), Color("2a5a2a"), 1.2)
					draw_circle(Vector2(fx + r.randf_range(-2, 2), -h + 3.0), 3.0, Color("c02020"))
			_:   # ערמת תופי מצעד
				for q in 3:
					var dx := float(q % 2) * w * 0.5 + (w * 0.25 if q == 2 else 0.0)
					var dy := -h * 0.5 if q == 2 else 0.0
					var dw := w * 0.48
					Art.fill_shaded(self, PackedVector2Array([Vector2(dx, dy), Vector2(dx + dw, dy), Vector2(dx + dw, dy - h * 0.5), Vector2(dx, dy - h * 0.5)]), S.E.RED, 0.15, 0.35, Art.OUTLINE, 1.0)
					for z in 4:
						draw_line(Vector2(dx + float(z) * dw / 4.0, dy), Vector2(dx + float(z) * dw / 4.0 + dw / 8.0, dy - h * 0.5), Color("e0c040"), 1.2)
					draw_rect(Rect2(dx, dy - h * 0.5, dw, 3), Color("e8e0d0"))


# ---- נייר טיקר נופל (מסך) ----
class ParadeFX extends Node2D:
	var vp := Vector2(1280, 720)
	var floor_y := 630.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var gy: float = (get_viewport().get_canvas_transform() * Vector2(0, floor_y)).y
		for i in 28:
			var x := fposmod(float(i) * 79.0 + sin(_t * 1.5 + float(i)) * 20.0, vp.x)
			var y := fposmod(float(i) * 47.0 + _t * (50.0 + float(i % 5) * 10.0), maxf(gy, 10.0))
			var c := Color(0.85, 0.12, 0.12, 0.8) if i % 2 == 0 else Color(0.95, 0.95, 0.92, 0.8)
			draw_rect(Rect2(x, y, 3.0 + 2.0 * absf(sin(_t * 4.0 + float(i))), 5.0), c)
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.4, 0.2, 0.3, 0.04))
