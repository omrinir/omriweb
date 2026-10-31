extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 38 ("MEGACITY CORE") - סאו פאולו בלילה בטפטוף ("גארואה"). אזור חמישי, שלב 2.
#  יער בלתי נגמר של גורדי שחקים, מסוקים עם זרקורים מעל, בניין הקופאן הגלי, המוזיאון התלוי על קורות אדומות (MASP),
#  שדרת פאוליסטה עם פקק של אורות אדומים, גשר המינוקאו עם "פישסאו" (כתובות ענק) על העמודים, שלטי פרסומת דיגיטליים.
#    sp_sky         - (רקע) שמיים סגולים-כתומים מאור העיר, מסוקים חוצים עם אורות מהבהבים וזרקורים
#    far_towers     - (רקע) קו רקיע צפוף של גורדי שחקים עם חלונות דולקים, אנטנות עם אורות אדומים, הקופאן
#    mid_avenue     - (רקע) שדרת פאוליסטה: MASP, עצים, פקק מכוניות (אורות אחוריים), שלטים
#    near_overpass  - (רקע) עמודי בטון עם כתובות פישסאו, גדרות
#    CityGround     - (עולם) אספלט רטוב עם סימוני נתיב והשתקפויות ניאון
#    Overpass       - (עולם) גשר בטון מוגבה (הקומה = add_floor) על עמודים
#    GlassTower     - (עולם, מלכודת) לובי של מגדל זכוכית: פאנל נסדק כשאתה מתחת (נצנוץ = אזהרה) -> גשם רסיסים.
#                     ירייה בפאנל מפילה אותו על הזומבים. הרסיסים נשארים על הקרקע: הליכה עליהם = "קראנץ'" שמעיר זומבים
#    Billboard      - (עולם, מלכודת) שלט דיגיטלי ש"הם" פרצו אליו: "LOOK" -> הבזק לבן מסנוור (daze) אם אתה מסתכל לכיוונו
#    Obstacle       - (מוצק + מחסה) "taxi" מונית / "barrier_jersey" מחסום בטון / "kiosk" דוכן עיתונים
#    RainFX         - (מסך) טפטוף, אובך ניאון
#  לשנות: GlassTower.WARN_T / RAIN_T / DMG_Z / CRUNCH_R, Billboard.CYCLE / DAZE_T.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const NEON := [Color("ff3a8a"), Color("30d0ff"), Color("ffd020"), Color("7a5aff"), Color("40ff90")]


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)


static func heli(ci: CanvasItem, p: Vector2, dir: float, t: float, s := 1.0) -> void:   # מסוק (צללית)
	var c := Color("12101a")
	DrawBatch.colored_polygon(ci, Art.ellipse(p, 16.0 * s, 7.0 * s, 0.0, 12), c)
	DrawBatch.line(ci, p + Vector2(-dir * 14.0, -2.0) * s, p + Vector2(-dir * 34.0, -5.0) * s, c, 3.0 * s)
	DrawBatch.line(ci, p + Vector2(-dir * 34.0, -9.0) * s, p + Vector2(-dir * 34.0, -1.0) * s, c, 2.0 * s)
	var rw := 28.0 * absf(sin(t * 30.0)) * s
	DrawBatch.line(ci, p + Vector2(-rw, -9.0 * s), p + Vector2(rw, -9.0 * s), Color(c, 0.8), 1.5)
	DrawBatch.line(ci, p + Vector2(-6, 7) * s, p + Vector2(10, 7) * s, c, 1.5)
	if fposmod(t * 1.5, 1.0) < 0.15:
		DrawBatch.circle(ci, p + Vector2(-dir * 34.0, -5.0) * s, 2.0, Color(1, 0.2, 0.2))
	DrawBatch.circle(ci, p + Vector2(0, 6) * s, 1.5, Color(1, 1, 1, 0.9))


# ---- שמיים: אור העיר, מסוקים ----
static func sp_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("120e22"), Color("2a1e40"), Color("5a2e50"), Color("b0604a")], 0.9)
	for i in 4:   # עננים נמוכים מוארים מלמטה
		var cx := fposmod(float(i) * 420.0 + t * 7.0, v.x + 400.0) - 200.0
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, v.y * (0.15 + 0.08 * float(i % 2))), 220.0, 30.0, 0.0, 16), Color(0.6, 0.35, 0.45, 0.25))
	for i in 3:   # מסוקים חוצים עם זרקור
		var period := 18.0 + float(i) * 5.0
		var k := fposmod(t + float(i) * 7.0, period) / period
		var dir := 1.0 if i % 2 == 0 else -1.0
		var hx := lerpf(-100.0, v.x + 100.0, k) if dir > 0.0 else lerpf(v.x + 100.0, -100.0, k)
		var hy := v.y * (0.12 + 0.1 * float(i))
		if i == 0:   # זרקור
			var tip := Vector2(hx + sin(t * 0.7) * 120.0, v.y)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(hx - 3, hy + 6), Vector2(hx + 3, hy + 6), tip + Vector2(70, 0), tip - Vector2(70, 0)]), Color(1.0, 0.98, 0.85, 0.06))
		heli(ci, Vector2(hx, hy), dir, t, 0.8 + 0.2 * float(i))


# ---- קו רקיע של גורדי שחקים ----
static func far_towers(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var col_w := 60.0
	var first := int(floor(sc / col_w)) - 1
	for k in range(first, first + int(ceil(v.x / col_w)) + 3):
		var x := float(k) * col_w - sc
		var r := _rng(k * 23 + 9)
		var h := r.randf_range(140.0, 380.0)
		var w := r.randf_range(40.0, 70.0)
		var c := Color("1a1628").lerp(Color("2a2438"), r.randf())
		DrawBatch.rect(ci, Rect2(x, y - h, w, h), c)
		var lit := 0.25 + 0.2 * r.randf()
		var wy := y - h + 8.0
		var row := 0
		while wy < y - 6.0:   # חלונות (שורות מדולגות - חוסך ציור)
			var wx := x + 4.0
			var col := 0
			while wx < x + w - 6.0:
				if _h(row * 13 + col, k) < lit:
					DrawBatch.rect(ci, Rect2(wx, wy, 3.0, 4.0), Color(1.0, 0.85, 0.55, 0.7))
				wx += 9.0
				col += 1
			wy += 13.0
			row += 1
		if r.randf() < 0.3:   # אנטנה עם אור אדום מהבהב
			DrawBatch.line(ci, Vector2(x + w * 0.5, y - h), Vector2(x + w * 0.5, y - h - 30.0), Color("2a2438"), 2.0)
			if fposmod(t + float(k) * 0.37, 2.0) < 0.4:
				DrawBatch.circle(ci, Vector2(x + w * 0.5, y - h - 30.0), 2.5, Color(1, 0.15, 0.15))
		if k % 23 == 0:   # בניין הקופאן: גל לבן
			var cp := PackedVector2Array()
			for q in 13:
				var u := float(q) / 12.0
				cp.append(Vector2(x - 40.0 + u * 160.0, y - 300.0 + sin(u * PI * 1.5) * 26.0))
			cp.append(Vector2(x + 120.0, y))
			cp.append(Vector2(x - 40.0, y))
			DrawBatch.colored_polygon(ci, cp, Color("3a3448"))
			for q in 30:
				DrawBatch.line(ci, Vector2(x - 38.0, y - 290.0 + float(q) * 9.5), Vector2(x + 118.0, y - 290.0 + float(q) * 9.5 + sin(float(q)) * 2.0), Color(0.6, 0.55, 0.7, 0.35), 1.0)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("1a1628"))


# ---- שדרת פאוליסטה: MASP, פקק ----
static func mid_avenue(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1400.0
	var start := int(floor(sc / period)) - 1
	DrawBatch.rect(ci, Rect2(0, y - 26.0, v.x, v.y - y + 26.0), Color("1e1a26"))
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x0 := float(k) * period - sc
		var r := _rng(k * 41 + 2)
		var mx := x0 + 200.0   # MASP: קופסה תלויה על שתי קורות אדומות
		DrawBatch.rect(ci, Rect2(mx, y - 120.0, 260.0, 54.0), Color("2a2a34"))
		for q in 6:
			DrawBatch.line(ci, Vector2(mx + 4.0, y - 112.0 + float(q) * 8.0), Vector2(mx + 256.0, y - 112.0 + float(q) * 8.0), Color(0.9, 0.7, 0.4, 0.25), 1.0)
		for bx in [mx - 12.0, mx + 258.0]:
			DrawBatch.rect(ci, Rect2(bx, y - 132.0, 14.0, 132.0), Color("b02a24"))
		DrawBatch.rect(ci, Rect2(mx - 12.0, y - 132.0, 284.0, 12.0), Color("b02a24"))
		DrawBatch.rect(ci, Rect2(mx - 12.0, y - 66.0, 284.0, 10.0), Color("b02a24"))
		for i in 4:   # שלטים מוארים
			var bx := x0 + 600.0 + float(i) * 180.0 + r.randf_range(-30.0, 30.0)
			var by := y - r.randf_range(90.0, 150.0)
			var nc: Color = NEON[(k + i) % NEON.size()]
			DrawBatch.rect(ci, Rect2(bx, by, 70.0, 26.0), Color(nc, 0.25 + 0.15 * sin(t * 2.0 + float(i))))
			DrawBatch.rect(ci, Rect2(bx + 6.0, by + 9.0, 58.0, 4.0), Color(nc, 0.9))
			DrawBatch.line(ci, Vector2(bx + 35.0, by + 26.0), Vector2(bx + 35.0, y - 26.0), Color("2a2430"), 2.0)
	# פקק: אורות אחוריים אדומים, פנסים לבנים
	var cx := -fposmod(sc * 0.4 + t * 6.0, 70.0)
	while cx < v.x + 70.0:
		DrawBatch.rect(ci, Rect2(cx, y - 22.0, 46.0, 12.0), Color("161320"))
		DrawBatch.circle(ci, Vector2(cx + 3.0, y - 16.0), 2.0, Color(1.0, 0.15, 0.1, 0.9))
		DrawBatch.circle(ci, Vector2(cx + 43.0, y - 16.0), 2.0, Color(1.0, 0.15, 0.1, 0.9))
		Art.glow(ci, Vector2(cx + 23.0, y - 14.0), 20.0, Color(1.0, 0.2, 0.15, 0.12))
		cx += 70.0
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("1e1a26"))


# ---- עמודי מינוקאו עם פישסאו ----
static func near_overpass(ci: CanvasItem, sc: float, v: Vector2, y: float, _t: float) -> void:
	var period := 520.0
	var start := int(floor(sc / period)) - 1
	DrawBatch.rect(ci, Rect2(0, y - 190.0, v.x, 18.0), Color("2a2630"))   # גשר מעל
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		DrawBatch.rect(ci, Rect2(x, y - 172.0, 46.0, 172.0), Color("2e2a34"))
		var r := _rng(k * 13 + 4)
		for q in 4:   # פישסאו: אותיות גבוהות וחדות
			var lx := x + 5.0 + float(q) * 10.0
			var ly := y - 150.0 + r.randf_range(0.0, 20.0)
			DrawBatch.line(ci, Vector2(lx, ly), Vector2(lx, ly + 40.0), Color("0e0c12"), 2.0)
			DrawBatch.line(ci, Vector2(lx, ly), Vector2(lx + 6.0, ly - 4.0), Color("0e0c12"), 2.0)
			if r.randf() < 0.5:
				DrawBatch.line(ci, Vector2(lx + 6.0, ly - 4.0), Vector2(lx + 6.0, ly + 36.0), Color("0e0c12"), 2.0)
		DrawBatch.line(ci, Vector2(x + 60.0, y - 30.0), Vector2(x + 200.0, y - 30.0), Color("3a3640"), 2.0)   # גדר
		for q in 8:
			DrawBatch.line(ci, Vector2(x + 60.0 + float(q) * 20.0, y - 30.0), Vector2(x + 60.0 + float(q) * 20.0, y), Color("3a3640"), 1.0)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("16141c"))


# ---- אספלט רטוב ----
class CityGround extends Node2D:
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
		var S := preload("res://effects/s38_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("24222a"))
		DrawBatch.rect(self, Rect2(0, 0, w, 6.0), Color("3a3842"))
		var x := 20.0
		while x < w:   # סימוני נתיב
			DrawBatch.rect(self, Rect2(x, 26.0, 40.0, 3.0), Color(0.85, 0.8, 0.5, 0.55))
			x += 90.0
		for i in int(w / 140.0):   # השתקפויות ניאון בשלוליות
			var px := r.randf_range(0.0, w - 60.0)
			var c: Color = S.NEON[r.randi() % S.NEON.size()]
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(px + 30.0, 12.0), r.randf_range(24.0, 40.0), 3.0, 0.0, 12), Color(c, 0.18))
			DrawBatch.line(self, Vector2(px + 20.0, 12.0), Vector2(px + 40.0, 12.0), Color(c, 0.35), 1.0)


# ---- גשר בטון מוגבה ----
class Overpass extends Node2D:
	var w := 320.0
	var tier := 140.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(-6, -tier, w + 12, 16), Color("4a4650"))   # הסיפון
		DrawBatch.rect(self, Rect2(-6, -tier + 16, w + 12, 6), Color("2e2a34"))
		DrawBatch.rect(self, Rect2(-6, -tier - 14, w + 12, 3), Color("6a6670"))   # מעקה
		for q in int(w / 24.0) + 1:
			DrawBatch.line(self, Vector2(-4.0 + float(q) * 24.0, -tier - 14), Vector2(-4.0 + float(q) * 24.0, -tier), Color("6a6670"), 1.5)
		for px in [20.0, w - 50.0]:   # עמודים
			DrawBatch.rect(self, Rect2(px, -tier + 22, 30, tier - 22), Color("3e3a44"))
			DrawBatch.line(self, Vector2(px + 4, -tier + 30), Vector2(px + 4, -4), Color(1, 1, 1, 0.06), 2.0)
			for q in 3:   # פישסאו
				DrawBatch.line(self, Vector2(px + 6.0 + float(q) * 8.0, -tier * 0.6), Vector2(px + 6.0 + float(q) * 8.0, -tier * 0.6 + 34.0), Color("141218"), 2.0)
		Art.glow(self, Vector2(w * 0.5, -tier + 22), 40.0, Color(1.0, 0.75, 0.4, 0.15))   # פנס מתחת לגשר


# ---- מגדל זכוכית: גשם רסיסים ----
class GlassTower extends Node2D:
	const WARN_T := 0.7
	const RAIN_T := 0.9
	const RESET_T := 9.0
	const DMG_Z := 14
	const CRUNCH_R := 520.0
	var w := 200.0
	var h := 260.0                  # כמה מהקומה למעלה רואים
	var state := 0                  # 0 = שלם, 1 = נסדק, 2 = נופל, 3 = שבור (מתחלף)
	var falls := 0                  # לבדיקות
	var hits := 0
	var zhits := 0
	var crunches := 0
	var _t := 0.0
	var _st := 0.0
	var _hit := false
	var _glass := 0.0               # כמה זמן הרסיסים נשארים על הקרקע
	var _crunch_cd := 0.0
	var _panel: StaticBody2D = null

	func _ready() -> void:
		z_index = -1
		add_to_group("hazards")
		_panel = GlassPanel.new()
		_panel.owner_g = self
		_panel.collision_layer = 4
		_panel.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(w - 40.0, 50.0)
		cs.shape = sh
		cs.position = Vector2(w * 0.5, -h + 60.0)
		_panel.add_child(cs)
		add_child(_panel)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(10, -80), Vector2(w - 20, 80))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (state == 1 or state == 2) and world_rect().grow(margin).has_point(p)

	func shatter() -> void:   # ירייה בפאנל
		if state == 0:
			state = 1
			_st = 0.05

	func _physics_process(delta: float) -> void:
		_t += delta
		_crunch_cd -= delta
		var pl := get_tree().get_first_node_in_group("player")
		match state:
			0:
				if pl != null and not pl.dead and pl.global_position.x > global_position.x + 20.0 and pl.global_position.x < global_position.x + w - 20.0 and absf(pl.global_position.y - global_position.y) < 40.0:
					state = 1
					_st = WARN_T
					preload("res://sfx.gd").play("sp_crack", global_position + Vector2(w * 0.5, -h + 60.0), 0.0, 0.1, 2)
			1:
				_st -= delta
				if _st <= 0.0:
					state = 2
					_st = RAIN_T
					_hit = false
					falls += 1
					preload("res://sfx.gd").play("sp_shatter", global_position + Vector2(w * 0.5, -60.0), 2.0, 0.1, 2)
			2:
				_st -= delta
				var k := 1.0 - _st / RAIN_T
				if k > 0.45:   # הרסיסים הגיעו לקרקע
					if not _hit and pl != null and not pl.dead and world_rect().has_point(pl.global_position + Vector2(0, -10)):
						_hit = true
						hits += 1
						pl.hurt(1, Vector2(0.0, -0.4))
					if Engine.get_physics_frames() % 10 == 0:
						for zz in get_tree().get_nodes_in_group("zombies"):
							if not zz.dead and not zz.is_boss() and world_rect().has_point(zz.global_position + Vector2(0, -10)):
								zhits += 1
								zz.take_damage(DMG_Z, zz.global_position + Vector2(0, -40), Vector2(0, 1), false, {"source": "glass", "fixed": DMG_Z})
				if Engine.get_physics_frames() % 4 == 0:
					preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(20.0, w - 20.0), -4.0), "spark", Vector2.UP, 1)
				if _st <= 0.0:
					state = 3
					_st = RESET_T
					_glass = RESET_T
					_panel.collision_layer = 0
			3:
				_st -= delta
				if _st <= 0.0:
					state = 0
					_panel.collision_layer = 4
		# רסיסים על הקרקע: מי שהולך עליהם עושה רעש - הזומבים שומעים
		if _glass > 0.0:
			_glass -= delta
			if pl != null and not pl.dead and _crunch_cd <= 0.0 and pl.is_on_floor() and absf(pl.velocity.x) > 40.0 and world_rect().has_point(pl.global_position + Vector2(0, -10)):
				_crunch_cd = 0.6
				crunches += 1
				preload("res://sfx.gd").play("sp_crunch", pl.global_position, -2.0, 0.2, 3)
				for zz in get_tree().get_nodes_in_group("zombies"):
					if not zz.dead and zz.global_position.distance_to(pl.global_position) < CRUNCH_R:
						zz._alert_t = maxf(float(zz._alert_t), 4.0)
						if zz.dormant:
							zz._wake()
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -h * 0.5), w + h):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		# לובי: עמודים ותקרה, ומעליהם חזית זכוכית
		DrawBatch.rect(self, Rect2(0, -h, w, h - 90.0), Color("1e2a3a"))
		var cols := int(w / 34.0)
		for q in cols + 1:
			DrawBatch.line(self, Vector2(float(q) * w / float(cols), -h), Vector2(float(q) * w / float(cols), -90.0), Color("3a4a5a"), 1.5)
		for q in int((h - 90.0) / 30.0) + 1:
			DrawBatch.line(self, Vector2(0, -h + float(q) * 30.0), Vector2(w, -h + float(q) * 30.0), Color("3a4a5a"), 1.0)
		for q in 6:   # השתקפויות
			var rx := fposmod(float(q) * 53.0 + _t * 3.0, w)
			DrawBatch.line(self, Vector2(rx, -h + 4.0), Vector2(rx + 20.0, -100.0), Color(0.6, 0.75, 1.0, 0.08), 6.0)
		DrawBatch.rect(self, Rect2(0, -94, w, 8), Color("4a4a54"))   # תקרת הלובי
		DrawBatch.rect(self, Rect2(10, -86, 12, 86), Color("3a3a44"))
		DrawBatch.rect(self, Rect2(w - 22, -86, 12, 86), Color("3a3a44"))
		DrawBatch.rect(self, Rect2(30, -80, w - 60, 80), Color(1.0, 0.85, 0.6, 0.08))   # אור הלובי
		var pr := Rect2(20, -h + 35, w - 40, 50)   # הפאנל
		if state == 0:
			DrawBatch.rect(self, pr, Color(0.35, 0.5, 0.7, 0.35))
		elif state == 1:   # נסדק: קווים + נצנוצים
			DrawBatch.rect(self, pr, Color(0.6, 0.75, 1.0, 0.45 + 0.3 * sin(_t * 40.0)))
			for q in 5:
				var c := pr.get_center()
				DrawBatch.line(self, c, c + Vector2.from_angle(float(q) * 1.3) * 40.0, Color(1, 1, 1, 0.9), 1.2)
		elif state == 2:   # רסיסים נופלים
			var k := 1.0 - _st / RAIN_T
			for q in 26:
				var sx := 20.0 + _hh(q, 1) * (w - 40.0)
				var sy := lerpf(-h + 60.0, -6.0, clampf(k * (1.4 + _hh(q, 2) * 0.6), 0.0, 1.0))
				var a := _hh(q, 3) * TAU + _t * 8.0
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(sx, sy) + Vector2.from_angle(a) * 6.0, Vector2(sx, sy) + Vector2.from_angle(a + 2.3) * 4.0, Vector2(sx, sy) + Vector2.from_angle(a + 4.0) * 5.0]), Color(0.75, 0.88, 1.0, 0.85))
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -2), w * 0.45 * minf(k * 2.0, 1.0), 4.0, 0.0, 14), Color(0.2, 0.3, 0.5, 0.35))
		else:
			DrawBatch.rect(self, pr, Color(0.05, 0.05, 0.08, 0.9))   # חור
		if _glass > 0.0:   # רסיסים על הקרקע
			var a := clampf(_glass / 2.0, 0.0, 1.0)
			for q in 18:
				var gx := 16.0 + _hh(q, 7) * (w - 32.0)
				DrawBatch.line(self, Vector2(gx, -1), Vector2(gx + 4.0 + _hh(q, 8) * 4.0, -2.0 - _hh(q, 9) * 2.0), Color(0.8, 0.9, 1.0, 0.8 * a), 1.2)

	func _hh(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)

	class GlassPanel extends StaticBody2D:
		var owner_g = null

		func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
			if owner_g != null:
				owner_g.shatter()


# ---- שלט דיגיטלי פרוץ: הבזק מסנוור ----
class Billboard extends Node2D:
	const CYCLE := Vector2(5.0, 8.0)
	const WARN_T := 1.0
	const FLASH_T := 0.35
	const DAZE_T := 1.6
	const RANGE := 520.0
	var w := 160.0
	var h := 90.0
	var height := 240.0             # כמה גבוה מעל הקרקע
	var state := 0                  # 0 = פרסומת, 1 = "LOOK", 2 = הבזק
	var flashes := 0                # לבדיקות
	var dazed := 0
	var _t := 3.0
	var _st := 0.0
	var _ad := 0

	func _ready() -> void:
		z_index = -1
		_ad = randi() % 3

	func screen_pos() -> Vector2:
		return global_position + Vector2(0, -height)

	func _physics_process(delta: float) -> void:
		_t -= delta
		match state:
			0:
				if _t <= 0.0:
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < RANGE:
						state = 1
						_st = WARN_T
						preload("res://sfx.gd").play("sp_beep", screen_pos(), -2.0, 0.05, 2)
					else:
						_t = 1.0
			1:
				_st -= delta
				if _st <= 0.0:
					state = 2
					_st = FLASH_T
					flashes += 1
					preload("res://sfx.gd").play("sp_flash", screen_pos(), 2.0, 0.05, 2)
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < RANGE:
						var to_me: float = signf(global_position.x - pl.global_position.x)
						var looking: bool = signf(pl.aim_end.x - pl.global_position.x) == to_me or absf(pl.global_position.x - global_position.x) < w * 0.5
						if looking and pl.has_method("daze"):
							dazed += 1
							pl.daze(DAZE_T)
							pl._say("TOO BRIGHT!", Color("ffffff"))
			2:
				_st -= delta
				if _st <= 0.0:
					state = 0
					_t = randf_range(CYCLE.x, CYCLE.y)
		if Art.on_screen(self, screen_pos(), RANGE):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var S := preload("res://effects/s38_decor.gd")
		var p := Vector2(-w * 0.5, -height - h * 0.5)
		DrawBatch.line(self, Vector2(-w * 0.3, 0), Vector2(-w * 0.3, -height + h * 0.5), Color("2a2830"), 6.0)   # עמודים
		DrawBatch.line(self, Vector2(w * 0.3, 0), Vector2(w * 0.3, -height + h * 0.5), Color("2a2830"), 6.0)
		DrawBatch.rect(self, Rect2(p - Vector2(5, 5), Vector2(w + 10, h + 10)), Color("1a1820"))
		match state:
			0:   # פרסומת מתחלפת
				var c: Color = S.NEON[_ad % S.NEON.size()]
				DrawBatch.rect(self, Rect2(p, Vector2(w, h)), c.darkened(0.55))
				DrawBatch.rect(self, Rect2(p + Vector2(10, 14), Vector2(w * 0.5, 14)), c)
				DrawBatch.rect(self, Rect2(p + Vector2(10, 36), Vector2(w * 0.35, 6)), Color(1, 1, 1, 0.6))
				DrawBatch.circle(self, p + Vector2(w * 0.78, h * 0.5), h * 0.3, c.lightened(0.2))
			1:   # נפרץ: "LOOK" + עין
				var blink := fposmod(_st * 6.0, 1.0) < 0.5
				DrawBatch.rect(self, Rect2(p, Vector2(w, h)), Color("1a0408") if blink else Color("3a0812"))
				DrawBatch.colored_polygon(self, Art.ellipse(p + Vector2(w * 0.5, h * 0.5), w * 0.3, h * 0.25, 0.0, 16), Color(0.95, 0.9, 0.85))
				DrawBatch.circle(self, p + Vector2(w * 0.5, h * 0.5), h * 0.17, Color(0.6, 0.1, 0.1))
				DrawBatch.circle(self, p + Vector2(w * 0.5, h * 0.5), h * 0.08, Color(0.05, 0.02, 0.02))
				for q in 4:   # גליץ'
					DrawBatch.rect(self, Rect2(p + Vector2(0, fposmod(_t * 300.0 + float(q) * 23.0, h)), Vector2(w, 2)), Color(1, 0.2, 0.3, 0.4))
			_:   # הבזק
				DrawBatch.rect(self, Rect2(p, Vector2(w, h)), Color(1, 1, 1))
				Art.glow(self, p + Vector2(w * 0.5, h * 0.5), 260.0, Color(1, 1, 1, 0.5 * _st / FLASH_T))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "taxi"
	var size := Vector2(110, 44)
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
			"taxi":   # מונית לבנה של סאו פאולו
				Art.fill_shaded(self, PackedVector2Array([Vector2(2, -8), Vector2(w - 2, -8), Vector2(w - 4, -h * 0.55), Vector2(w * 0.75, -h * 0.6), Vector2(w * 0.62, -h), Vector2(w * 0.3, -h), Vector2(w * 0.2, -h * 0.6), Vector2(4, -h * 0.55)]), Color("e8e8e4"), 0.15, 0.35, Art.OUTLINE, 1.3)
				DrawBatch.rect(self, Rect2(w * 0.33, -h * 0.92, w * 0.26, h * 0.28), Color("2a3448"))
				DrawBatch.rect(self, Rect2(w * 0.4, -h - 6, w * 0.14, 6), Color("e0c030"))   # שלט מונית
				for wx in [w * 0.22, w * 0.78]:
					DrawBatch.circle(self, Vector2(wx, -8), 8.0, Art.OUTLINE)
					DrawBatch.circle(self, Vector2(wx, -8), 4.0, Color("7a7a7a"))
				DrawBatch.circle(self, Vector2(w - 4, -h * 0.45), 2.5, Color(1.0, 0.9, 0.6))
			"barrier_jersey":   # מחסום בטון
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 6, -h * 0.35), Vector2(w - 10, -h), Vector2(10, -h), Vector2(6, -h * 0.35)]), Color("8a8680"), 0.15, 0.35, Art.OUTLINE, 1.2)
				for q in 3:
					DrawBatch.rect(self, Rect2(w * 0.15 + float(q) * w * 0.25, -h * 0.75, w * 0.12, 5), Color("e0c030") if q % 2 == 0 else Color("1a1a1a"))
			_:   # דוכן עיתונים ירוק
				Art.fill_shaded(self, PackedVector2Array([Vector2(2, 0), Vector2(w - 2, 0), Vector2(w - 2, -h), Vector2(2, -h)]), Color("2a6a4a"), 0.15, 0.35, Art.OUTLINE, 1.2)
				DrawBatch.rect(self, Rect2(-4, -h - 6, w + 8, 7), Color("1e4a34"))
				for q in 4:
					DrawBatch.rect(self, Rect2(6.0 + float(q) * (w - 12.0) / 4.0, -h * 0.75, (w - 20.0) / 4.0, h * 0.35), [Color("e04040"), Color("e0e0e0"), Color("e0c030"), Color("40a0e0")][q])


# ---- טפטוף ואובך ניאון (מסך) ----
class RainFX extends Node2D:
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
		for i in 60:
			var x := fposmod(float(i) * 97.0 + _t * 60.0, vp.x)
			var y := fposmod(float(i) * 61.0 + _t * 520.0, vp.y)
			DrawBatch.line(self, Vector2(x, y), Vector2(x - 2.0, y + 9.0), Color(0.75, 0.75, 0.9, 0.25), 1.0)
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.35, 0.15, 0.4, 0.06))


# ---- פיגום של אתר בנייה (הבוס עומד למעלה) ----
class Scaffold extends Node2D:
	var w := 300.0
	var tier := 170.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var steel := Color("6a6a74")
		var cols := int(w / 50.0)
		for q in cols + 1:   # עמודים
			var x := float(q) * w / float(cols)
			DrawBatch.line(self, Vector2(x, 0), Vector2(x, -tier), steel, 3.0)
		var lv := 0
		var y := 0.0
		while y > -tier:   # קומות + אלכסונים
			var y2 := maxf(y - 42.0, -tier)
			DrawBatch.line(self, Vector2(0, y2), Vector2(w, y2), steel, 2.0)
			for q in cols:
				var x0 := float(q) * w / float(cols)
				var x1 := float(q + 1) * w / float(cols)
				if (q + lv) % 2 == 0:
					DrawBatch.line(self, Vector2(x0, y), Vector2(x1, y2), steel.darkened(0.2), 1.2)
				else:
					DrawBatch.line(self, Vector2(x1, y), Vector2(x0, y2), steel.darkened(0.2), 1.2)
			DrawBatch.rect(self, Rect2(0, y2 - 4, w, 4), Color("7a5a3a"))   # קרשים
			y = y2
			lv += 1
		DrawBatch.rect(self, Rect2(-4, -tier - 6, w + 8, 8), Color("8a6a4a"))   # הרצפה העליונה
		DrawBatch.rect(self, Rect2(w * 0.1, -tier * 0.8, w * 0.8, tier * 0.55), Color(0.2, 0.55, 0.3, 0.35))   # רשת ירוקה
		for q in 6:
			DrawBatch.line(self, Vector2(w * 0.1 + float(q) * w * 0.16, -tier * 0.8), Vector2(w * 0.1 + float(q) * w * 0.16, -tier * 0.25), Color(0.15, 0.4, 0.2, 0.4), 1.0)
		DrawBatch.rect(self, Rect2(w * 0.35, -26, w * 0.3, 20), Color("e0c020"))   # שלט
		DrawBatch.rect(self, Rect2(w * 0.35 + 6, -21, w * 0.3 - 12, 3), Color("1a1a1a"))
		DrawBatch.rect(self, Rect2(w * 0.35 + 6, -14, w * 0.2, 3), Color("1a1a1a"))
