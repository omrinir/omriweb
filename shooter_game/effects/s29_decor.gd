extends RefCounted
# ============================================================
#  קישוטים לשלב 29 ("MINE OF ECHOES") - מכרה כסף בהרי האנדים (בהשראת צ'רו ריקו, פוטוסי):
#  מנהרות סלע, מסגרות עץ, פנסי שמן מהבהבים, מסילות עגלות, עורקי כסף נוצצים, פסל "אל טיו" (אל המכרה) עם מנחות.
#    mine_rock     - ("שמיים") סלע כהה
#    far_cavern    - (רקע) מערה ענקית: פיגומי עץ, סולמות, אורות פנסים רחוקים, עגלה שנוסעת על גשר מסילה
#    mid_timbers   - (רקע) מסגרות תמיכה מעץ, פנסים תלויים, נטיפים
#    near_rocks    - (רקע) סלעים קרובים
#    MineGround    - (עולם) מסילה (פסים + אדנים), חצץ, עפרות
#    CaveCeiling   - (עולם) תקרת סלע עם נטיפים וטיפות מים
#    CaveIn        - (עולם, מלכודת, קבוצה "cave_ins") קטע תקרה סדוק. יריות קרובות (RUMBLE_SHOTS) / פיצוץ -> אבק נושר (WARN_T) ->
#                    סלעים נופלים (FallingRock: ROCK_DMG לשחקן, הורג זומבים). רעש מפיל את המכרה!
#    Lantern       - (עולם, קבוצה "mine_lights") פנס תלוי מהבהב - מאיר בחושך
#    SteamLeak     - (עולם) צינור אוויר דחוס שדולף: פרצי אדים (חלקיקים)
#    ElTio         - (עולם) פסל אל טיו עם נרות, עלי קוקה וסיגריה שמעשנת
#    Obstacle      - (מוצק + מחסה) "minecart" עגלת עפרות / "ore" ערמת עפרה / "timber" ערמת קורות
#    MineDark      - (שכבת חושך) המכרה חשוך (DARKNESS); פנסים + הפנס שלך + זוהר סביבך מאירים
#    MineFX        - (מסך) אבק מרחף
#  לשנות: CaveIn.RUMBLE_SHOTS, CaveIn.WARN_T, MineDark.DARKNESS.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const ROCK := Color("4a3e36")
const ROCK_D := Color("2a221e")
const WOOD := Color("6a4a2a")
const WOOD_D := Color("3e2a18")
const CEIL_Y := -380.0


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func mine_rock(ci: CanvasItem, v: Vector2, _t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("120e0c"), Color("1e1814"), Color("2a221c"), Color("1e1814")], 0.9)


# ---- מערה: פיגומים, אורות רחוקים, עגלה על גשר מסילה ----
static func far_cavern(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var wall := Color("2e2620")
	var dark := Color("1a1410")
	ci.draw_rect(Rect2(0, y - 440, v.x, 440), wall)
	var period := 1300.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 131 + 3)
		for s in 3:   # פיגומי עץ עם סולמות
			var sx := x + 100.0 + float(s) * 380.0
			var sh := r.randf_range(180.0, 300.0)
			ci.draw_line(Vector2(sx, y), Vector2(sx, y - sh), dark, 4.0)
			ci.draw_line(Vector2(sx + 90, y), Vector2(sx + 90, y - sh), dark, 4.0)
			for q in int(sh / 60.0):
				ci.draw_line(Vector2(sx, y - float(q + 1) * 60.0), Vector2(sx + 90, y - float(q + 1) * 60.0), dark, 3.0)
				ci.draw_line(Vector2(sx, y - float(q) * 60.0), Vector2(sx + 90, y - float(q + 1) * 60.0), dark, 1.5)
			var lp := Vector2(sx + 45, y - sh + 30.0)   # פנס רחוק
			var fl := 0.7 + 0.3 * sin(t * 7.0 + float(k + s))
			ci.draw_circle(lp, 26.0, Color(1.0, 0.6, 0.2, 0.08 * fl))
			ci.draw_circle(lp, 3.0, Color(1.0, 0.75, 0.35, 0.9 * fl))
		for v2 in 5:   # עורקי כסף
			var vx := x + r.randf_range(0.0, period)
			var vy := y - r.randf_range(60.0, 400.0)
			ci.draw_line(Vector2(vx, vy), Vector2(vx + r.randf_range(20.0, 60.0), vy + r.randf_range(-20.0, 20.0)), Color(0.75, 0.78, 0.8, 0.35), 2.0)
			if fmod(t * 0.7 + float(v2) * 1.3 + float(k), 3.0) < 0.15:
				ci.draw_circle(Vector2(vx + 10, vy), 2.5, Color(1, 1, 1, 0.9))
	# גשר מסילה + עגלה שנוסעת
	var by := y - 210.0
	ci.draw_rect(Rect2(0, by, v.x, 6), dark)
	var pp := 0.0
	while pp < v.x + 60.0:
		var px := pp - fposmod(sc, 120.0)
		ci.draw_line(Vector2(px, by + 6), Vector2(px + 30, y), dark, 2.0)
		ci.draw_line(Vector2(px + 60, by + 6), Vector2(px + 30, y), dark, 2.0)
		pp += 120.0
	var cx := fposmod(t * 70.0 - sc, v.x + 400.0) - 200.0
	ci.draw_rect(Rect2(cx, by - 22, 46, 20), Color("3a3028"))
	ci.draw_circle(Vector2(cx + 10, by - 1), 5.0, dark)
	ci.draw_circle(Vector2(cx + 36, by - 1), 5.0, dark)
	ci.draw_circle(Vector2(cx + 48, by - 14), 10.0, Color(1.0, 0.7, 0.3, 0.12))
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), dark)


# ---- מסגרות עץ, פנסים, נטיפים, אל טיו ----
static func mid_timbers(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var col := Color("181210")
	var period := 700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 53 + 9)
		var fx := x + 200.0   # מסגרת תמיכה
		ci.draw_rect(Rect2(fx, y - 360, 16, 360), col)
		ci.draw_rect(Rect2(fx + 260, y - 360, 16, 360), col)
		ci.draw_rect(Rect2(fx - 10, y - 370, 296, 18), col)
		ci.draw_line(Vector2(fx + 16, y - 330), Vector2(fx + 60, y - 352), col, 6.0)   # תומכות אלכסוניות
		ci.draw_line(Vector2(fx + 260, y - 330), Vector2(fx + 216, y - 352), col, 6.0)
		var lx := fx + 138.0   # פנס תלוי
		var sw := sin(t * 1.4 + float(k)) * 4.0
		ci.draw_line(Vector2(lx, y - 352), Vector2(lx + sw, y - 300), col, 1.5)
		var fl := 0.75 + 0.25 * sin(t * 9.0 + float(k) * 2.0) + 0.1 * sin(t * 23.0 + float(k))
		ci.draw_circle(Vector2(lx + sw, y - 292), 40.0, Color(1.0, 0.6, 0.2, 0.06 * fl))
		ci.draw_rect(Rect2(lx + sw - 5, y - 300, 10, 14), col)
		ci.draw_circle(Vector2(lx + sw, y - 292), 3.0, Color(1.0, 0.75, 0.35, fl))
		for s in 6:   # נטיפים
			var sx := x + r.randf_range(0.0, period)
			var sl := r.randf_range(20.0, 60.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - 7, 0), Vector2(sx, sl), Vector2(sx + 7, 0)]), col)
		if k % 3 == 0:   # פסל אל טיו ברקע (צללית עם קרניים)
			var ex := x + 520.0
			ci.draw_colored_polygon(Art.ellipse(Vector2(ex, y - 26), 16.0, 26.0, 0.0, 14), Color("3a1a14"))
			ci.draw_circle(Vector2(ex, y - 60), 11.0, Color("3a1a14"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(ex - 8, y - 66), Vector2(ex - 16, y - 86), Vector2(ex - 4, y - 70)]), Color("3a1a14"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(ex + 8, y - 66), Vector2(ex + 16, y - 86), Vector2(ex + 4, y - 70)]), Color("3a1a14"))
			ci.draw_circle(Vector2(ex - 4, y - 61), 1.6, Color(1.0, 0.4, 0.2, 0.8))
			ci.draw_circle(Vector2(ex + 4, y - 61), 1.6, Color(1.0, 0.4, 0.2, 0.8))
	ci.draw_rect(Rect2(0, 0, v.x, 22.0), col)
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), col)


static func near_rocks(ci: CanvasItem, sc: float, v: Vector2, y: float, _t: float) -> void:
	var col := Color("0c0806")
	var period := 600.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 17 + 2)
		for i in 3:
			var rx := x + r.randf_range(0.0, period)
			var rh := r.randf_range(20.0, 50.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(rx - 40, y), Vector2(rx - 20, y - rh), Vector2(rx + 10, y - rh * 1.1), Vector2(rx + 40, y)]), col)
	ci.draw_rect(Rect2(0, y - 2.0, v.x, v.y - y + 2.0), col)


# ---- רצפת המכרה: מסילה ----
class MineGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s29_decor.gd")
		draw_rect(Rect2(0, 0, w, depth), S.ROCK_D)
		draw_rect(Rect2(0, 0, w, 8.0), S.ROCK)
		var x := fposmod(-position.x, 34.0)
		while x < w:   # אדנים
			draw_rect(Rect2(x, 3, 22, 5), S.WOOD_D)
			x += 34.0
		draw_line(Vector2(0, 2), Vector2(w, 2), Color("6a6a6e"), 2.0)   # פסים
		draw_line(Vector2(0, 6), Vector2(w, 6), Color("5a5a5e"), 2.0)
		for i in int(w / 10.0):
			draw_circle(Vector2(r.randf_range(0.0, w), r.randf_range(12.0, depth - 4.0)), r.randf_range(1.0, 2.6), Color(0.4, 0.34, 0.3, 0.5))
		for i in int(w / 160.0):   # עפרות נוצצות
			draw_circle(Vector2(r.randf_range(0.0, w), r.randf_range(14.0, 40.0)), 1.6, Color(0.85, 0.88, 0.9, 0.6))


# ---- תקרת סלע + נטיפים + טיפות ----
class CaveCeiling extends Node2D:
	var w := 1024.0
	var seed_v := 0
	var _drops := []     # [x, y, מהירות]
	var _t := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta
		if not Art.on_screen(self, global_position + Vector2(w * 0.5, -300.0), w * 0.6):
			return
		if randf() < delta * 2.0:   # טיפת מים
			_drops.append([randf_range(0.0, w), preload("res://effects/s29_decor.gd").CEIL_Y + 30.0, 0.0])
		for d in _drops:
			d[2] += 900.0 * delta
			d[1] += d[2] * delta
		_drops = _drops.filter(func(d): return d[1] < 0.0)
		queue_redraw()

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s29_decor.gd")
		var top := S.CEIL_Y
		draw_rect(Rect2(0, top - 900.0, w, 900.0), Color("1a1410"))
		var pts := PackedVector2Array([Vector2(0, top - 10)])
		var x := 0.0
		while x < w:   # תחתית סלעית לא ישרה
			x += r.randf_range(20.0, 50.0)
			pts.append(Vector2(minf(x, w), top + r.randf_range(-6.0, 10.0)))
		pts.append(Vector2(w, top - 30))
		pts.append(Vector2(0, top - 30))
		draw_colored_polygon(pts, Color("2a221c"))
		for i in int(w / 70.0):   # נטיפים
			var sx := r.randf_range(0.0, w)
			var sl := r.randf_range(14.0, 40.0)
			draw_colored_polygon(PackedVector2Array([Vector2(sx - 6, top), Vector2(sx, top + sl), Vector2(sx + 6, top)]), Color("3a302a"))
			draw_line(Vector2(sx - 1, top + 2), Vector2(sx, top + sl - 3), Color(0.6, 0.55, 0.5, 0.4), 1.0)
		for d in _drops:
			draw_line(Vector2(d[0], d[1]), Vector2(d[0], d[1] - 6.0), Color(0.7, 0.8, 0.9, 0.7), 1.2)


# ---- קטע תקרה סדוק: רעש -> מפולת ----
class CaveIn extends Node2D:
	const RUMBLE_SHOTS := 6      # כמה יריות קרובות (בתוך DECAY שניות) מפילות אותה
	const DECAY := 1.4           # כמה "רעש" יורד בשנייה
	const NEAR := 280.0          # יריות בטווח הזה נחשבות
	const WARN_T := 0.9
	const ROCKS := 5
	const CD := 9.0
	var w := 220.0
	var falls := 0               # לבדיקות
	var _rumble := 0.0
	var _warn := -1.0
	var _cd := 0.0
	var _prev_flash := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 4
		add_to_group("cave_ins")
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -70), Vector2(w, 70))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _warn >= 0.0 and p.x > global_position.x - margin and p.x < global_position.x + w + margin

	func shake(from: Vector2, amount := 99.0) -> void:   # פיצוץ / רעש חזק קרוב
		if from.distance_to(global_position + Vector2(w * 0.5, -100.0)) < 360.0:
			_rumble += amount

	func _physics_process(delta: float) -> void:
		_t += delta
		_cd -= delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead:
			var f: float = pl._muzzle_flash
			if f > _prev_flash + 0.001 and absf(pl.global_position.x - (global_position.x + w * 0.5)) < NEAR + w * 0.5:
				_rumble += 1.0   # ירייה קרובה
				if _rumble >= RUMBLE_SHOTS * 0.5 and _warn < 0.0 and Engine.get_physics_frames() % 2 == 0:
					preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(0.0, w), preload("res://effects/s29_decor.gd").CEIL_Y + 10.0), "smoke", Vector2.DOWN, 1)
			_prev_flash = f
		_rumble = maxf(_rumble - DECAY * delta, 0.0)
		if _warn < 0.0 and _cd <= 0.0 and _rumble >= RUMBLE_SHOTS:
			_warn = WARN_T
			_rumble = 0.0
			Sfx.play("m29_rumble", global_position + Vector2(w * 0.5, -150), 4.0, 0.05, 2)
			_shake(4.0, WARN_T)
		if _warn >= 0.0:
			_warn -= delta
			if Engine.get_physics_frames() % 3 == 0:   # אבק נושר = אזהרה
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(0.0, w), preload("res://effects/s29_decor.gd").CEIL_Y + 12.0), "smoke", Vector2.DOWN, 2)
			if _warn < 0.0:
				_fall()
		if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -300.0), 300.0):
			queue_redraw()

	func _fall() -> void:
		falls += 1
		_cd = CD
		_shake(10.0, 0.4)
		Sfx.play("bd_crack", global_position + Vector2(w * 0.5, -200), 4.0, 0.1, 2)
		for i in ROCKS:
			var fr := FallingRock.new()
			fr.delay = float(i) * 0.08 + randf() * 0.1
			fr.size = randf_range(10.0, 17.0)
			get_parent().add_child(fr)
			fr.global_position = global_position + Vector2(w * (float(i) + randf()) / float(ROCKS), preload("res://effects/s29_decor.gd").CEIL_Y + 14.0)

	func _shake(st: float, t: float) -> void:
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(st, t)

	func _draw() -> void:   # סדקים בתקרה (מאירים כשהיא עומדת ליפול)
		var top: float = preload("res://effects/s29_decor.gd").CEIL_Y
		var hot := _warn >= 0.0
		var c := Color(0.85, 0.75, 0.6, 0.9) if hot else Color(0.05, 0.04, 0.03, 0.9)
		var r := RandomNumberGenerator.new()
		r.seed = int(global_position.x)
		for i in 4:
			var sx := r.randf_range(10.0, w - 10.0)
			var pts := PackedVector2Array([Vector2(sx, top - 4)])
			for q in 4:
				pts.append(pts[pts.size() - 1] + Vector2(r.randf_range(-14.0, 14.0), r.randf_range(4.0, 9.0)))
			draw_polyline(pts, c, 2.0 if hot else 1.5)
		var shake_k := clampf(_rumble / float(RUMBLE_SHOTS), 0.0, 1.0)
		if shake_k > 0.3 or hot:   # אבנים שמתנדנדות
			for i in 3:
				var sx := w * (0.2 + 0.3 * float(i)) + sin(_t * 40.0 + float(i)) * 2.0 * (1.0 if hot else shake_k)
				draw_circle(Vector2(sx, top + 6), 6.0, Color("4a3e36"))


# ---- סלע נופל ----
class FallingRock extends Node2D:
	var delay := 0.0
	var size := 14.0
	var _v := 0.0
	var _done := false
	var _life := 3.0

	func _ready() -> void:
		z_index = 5

	func _physics_process(delta: float) -> void:
		if delay > 0.0:
			delay -= delta
			return
		if _done:
			_life -= delta
			if _life <= 0.0:
				queue_free()
			elif _life < 1.0:
				modulate.a = _life
			return
		_v += 1300.0 * delta
		var to := global_position + Vector2(0, _v * delta)
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, size), 1 | 16))
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.body_rect().grow(size * 0.6).has_point(to):
			pl.hurt(2, Vector2(0.0, -0.5))
			_land(to)
			return
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and absf(z.global_position.x - to.x) < 12.0 * float(z.wf) + size and to.y > z.global_position.y - 56.0 * float(z.sc) and to.y < z.global_position.y:
				z.take_damage(40, to, Vector2.DOWN, true, {"source": "hazard", "fixed": 40})
		if hit:
			_land(hit.position - Vector2(0, size * 0.6))
			return
		global_position = to
		queue_redraw()

	func _land(p: Vector2) -> void:
		_done = true
		global_position = p
		preload("res://particles.gd").burst(get_parent(), p, "smoke", Vector2.UP, 5)
		preload("res://sfx.gd").play("land", p, 0.0, 0.2, 4)
		queue_redraw()

	func _draw() -> void:
		if delay > 0.0:
			return
		Art.oval_shaded(self, Vector2.ZERO, size, size * 0.85, Color("5a4e44"), 0.4)
		draw_line(Vector2(-size * 0.4, -size * 0.2), Vector2(size * 0.3, size * 0.3), Color("3a302a"), 1.5)


# ---- פנס תלוי (מקור אור) ----
class Lantern extends Node2D:
	var cord := 60.0
	var _t := 0.0
	var _seed := 0.0

	func _ready() -> void:
		z_index = 3
		add_to_group("mine_lights")
		_seed = randf() * 10.0

	func light() -> float:
		return 0.8 + 0.15 * sin(_t * 9.0 + _seed) + 0.08 * sin(_t * 23.0 + _seed)

	func light_pos() -> Vector2:
		return global_position + Vector2(sin(_t * 1.2 + _seed) * 3.0, cord + 60.0)

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var sw := sin(_t * 1.2 + _seed) * 3.0
		var p := Vector2(sw, cord)
		draw_line(Vector2.ZERO, p, Color("1a1410"), 1.5)
		draw_rect(Rect2(p + Vector2(-6, 0), Vector2(12, 16)), Color("2a2420"))
		draw_rect(Rect2(p + Vector2(-4, 3), Vector2(8, 10)), Color(1.0, 0.75, 0.35, light()))
		Art.glow(self, p + Vector2(0, 8), 30.0, Color(1.0, 0.6, 0.2, 0.25 * light()))


# ---- צינור אוויר דולף: פרצי אדים ----
class SteamLeak extends Node2D:
	var _t := 0.0
	var _next := 1.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0:
			_next = randf_range(1.5, 3.0)
			if Art.on_screen(self, global_position):
				for i in 3:
					preload("res://particles.gd").burst(get_parent(), global_position + Vector2(10, -62), "smoke", Vector2(1.0, -0.6), 3)
				Sfx.play("m29_hiss", global_position, -6.0, 0.15, 2)

	func _draw() -> void:
		draw_rect(Rect2(-4, -200, 8, 200), Color("4a4448"))   # צינור אנכי
		draw_rect(Rect2(-8, -66, 16, 8), Color("5a5458"))       # מחבר שדולף
		draw_line(Vector2(6, -62), Vector2(12, -64), Color("8a8488"), 2.0)


# ---- פסל אל טיו עם מנחות + עשן סיגריה ----
class ElTio extends Node2D:
	var _t := 0.0
	var _puff := 0.0

	func _ready() -> void:
		z_index = -1
		add_to_group("mine_lights")

	func light() -> float:   # הנרות מאירים קצת
		return 0.55 + 0.1 * sin(_t * 11.0)

	func light_pos() -> Vector2:
		return global_position + Vector2(0, -30)

	func _process(delta: float) -> void:
		_t += delta
		_puff -= delta
		if _puff <= 0.0 and Art.on_screen(self, global_position):
			_puff = 0.5
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(14, -60), "smoke", Vector2(0.2, -1.0), 1)
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var clay := Color("8a2a1e")
		Art.fill_shaded(self, PackedVector2Array([Vector2(-26, 0), Vector2(26, 0), Vector2(22, -14), Vector2(-22, -14)]), Color("5a4a3a"), 0.15, 0.35, Art.OUTLINE, 1.2)   # במה
		Art.oval_shaded(self, Vector2(0, -34), 15.0, 20.0, clay, 0.0, Art.OUTLINE, 1.4)   # גוף יושב
		Art.oval_shaded(self, Vector2(0, -60), 10.0, 10.0, clay, 0.0, Art.OUTLINE, 1.2)   # ראש
		for side in [-1.0, 1.0]:   # קרניים
			Art.fill(self, PackedVector2Array([Vector2(side * 6, -66), Vector2(side * 16, -84), Vector2(side * 10, -68)]), Color("c8b890"), Art.OUTLINE, 1.0)
		for side in [-1.0, 1.0]:   # עיניים מנצנצות (זכוכית)
			draw_circle(Vector2(side * 4, -61), 2.2, Color("e8e0c0"))
			draw_circle(Vector2(side * 4, -61), 1.0, Color("1a1a1a"))
		draw_line(Vector2(-3, -54), Vector2(4, -54), Color("2a0a08"), 1.6)
		draw_line(Vector2(5, -55), Vector2(13, -58), Color("e8e8e0"), 1.6)   # סיגריה
		draw_circle(Vector2(13, -58), 1.4, Color(1.0, 0.45, 0.15, 0.6 + 0.4 * sin(_t * 5.0)))
		for i in 6:   # עלי קוקה + סרטים צבעוניים
			draw_colored_polygon(Art.ellipse(Vector2(-18.0 + float(i) * 7.0, -16), 3.0, 1.6, 0.4, 6), Color("4a7a2a"))
		draw_line(Vector2(-12, -48), Vector2(12, -40), Color("e8c030"), 2.0)
		draw_line(Vector2(-12, -42), Vector2(12, -48), Color("2a8ad0"), 2.0)
		for c in 2:   # נרות
			var cx := -20.0 + float(c) * 40.0
			draw_rect(Rect2(cx - 2, -24, 4, 10), Color("e8e0c8"))
			var fl := 1.0 + 0.2 * sin(_t * 13.0 + float(c))
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 2, -24), Vector2(cx, -24 - 6.0 * fl), Vector2(cx + 2, -24)]), Color(1.0, 0.7, 0.2))
			Art.glow(self, Vector2(cx, -27), 14.0, Color(1.0, 0.6, 0.2, 0.35))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "minecart"
	var size := Vector2(80, 46)
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
		var S := preload("res://effects/s29_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"minecart":   # עגלת עפרות על המסילה
				Art.fill_shaded(self, PackedVector2Array([Vector2(4, -10), Vector2(w - 4, -10), Vector2(w, -h), Vector2(0, -h)]), Color("5a4a3a"), 0.15, 0.4, Art.OUTLINE, 1.5)
				for q in 2:
					draw_line(Vector2(2, -h * (0.4 + 0.3 * float(q))), Vector2(w - 2, -h * (0.4 + 0.3 * float(q))), Color("3a3a3e"), 2.0)
				for i in 5:   # עפרה בתוך העגלה
					draw_circle(Vector2(w * (0.15 + 0.17 * float(i)), -h - 2.0 + r.randf_range(-2.0, 2.0)), 6.0, Color("6a6058"))
					if r.randf() < 0.4:
						draw_circle(Vector2(w * (0.15 + 0.17 * float(i)) + 2.0, -h - 4.0), 1.5, Color(0.9, 0.92, 0.95))
				for wx in [w * 0.22, w * 0.78]:
					draw_circle(Vector2(wx, -6), 7.0, Art.OUTLINE)
					draw_circle(Vector2(wx, -6), 5.5, Color("3a3a3e"))
			"ore":   # ערמת עפרה
				var pts := PackedVector2Array([Vector2(0, 0)])
				for i in 7:
					var u := float(i + 1) / 8.0
					pts.append(Vector2(u * w, -sin(u * PI) * h - r.randf_range(-4.0, 4.0)))
				pts.append(Vector2(w, 0))
				Art.fill_shaded(self, pts, Color("5a4e44"), 0.15, 0.4, Art.OUTLINE, 1.4)
				for i in 6:
					draw_circle(Vector2(r.randf_range(w * 0.2, w * 0.8), -r.randf_range(4.0, h * 0.7)), 1.6, Color(0.9, 0.92, 0.95, 0.85))
			_:   # ערמת קורות
				var rows := 3
				var rr := h / float(rows * 2)
				for row in rows:
					var n := rows - row + 1
					for i in n:
						var cx := w * 0.5 + (float(i) - float(n - 1) * 0.5) * rr * 2.0
						var cy := -rr - float(row) * rr * 1.75
						draw_circle(Vector2(cx, cy), rr, S.WOOD)
						draw_arc(Vector2(cx, cy), rr * 0.5, 0, TAU, 10, S.WOOD_D, 1.0)
						draw_arc(Vector2(cx, cy), rr, 0, TAU, 12, Art.OUTLINE, 1.2)


# ---- חושך המכרה ----
class MineDark extends CanvasLayer:
	const DARKNESS := 0.48   # היה 0.55 - זומבים כהים נעלמו ברקע החום
	var _rect: ColorRect
	const SHADER := """
shader_type canvas_item;
uniform float darkness = 0.5;
uniform vec4 lights[14];
uniform vec2 vp_size = vec2(1280.0, 720.0);
void fragment() {
	vec2 p = SCREEN_UV * vp_size;
	float lit = 0.0;
	for (int i = 0; i < 14; i++) {
		vec4 l = lights[i];
		if (l.w <= 0.0) continue;
		vec2 d = (p - l.xy) / vec2(l.z, l.z * 1.2);
		lit = max(lit, l.w * (1.0 - smoothstep(0.2, 1.0, length(d))));
	}
	COLOR = vec4(0.02, 0.012, 0.0, darkness * (1.0 - lit));
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

	func _process(_delta: float) -> void:
		var vp := get_viewport()
		var ct := vp.get_canvas_transform()
		var zoom := ct.get_scale().x
		var view := ct.affine_inverse() * vp.get_visible_rect()
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var lights := []
		for lp in get_tree().get_nodes_in_group("mine_lights"):
			if lights.size() >= 10 or absf((lp as Node2D).global_position.x - view.get_center().x) > view.size.x * 0.75:
				continue
			var c: Vector2 = ct * lp.light_pos()
			lights.append(Vector4(c.x, c.y, 210.0 * zoom, lp.light()))
		if player != null:
			var pp: Vector2 = ct * (player.global_position + Vector2(0.0, -30.0))
			lights.append(Vector4(pp.x, pp.y, 130.0 * zoom, 0.55))   # היה 110
		var dyn: Array = preload("res://effects/dyn_lights.gd").gather(get_tree(), ct, zoom, player)
		lights = preload("res://effects/dyn_lights.gd").merge(dyn[0], lights, 14)
		var m := _rect.material as ShaderMaterial
		m.set_shader_parameter("lights", lights)
		m.set_shader_parameter("darkness", DARKNESS)
		m.set_shader_parameter("vp_size", vp.get_visible_rect().size)


# ---- אבק מרחף (מסך) ----
class MineFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _p := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 29
		for i in 40:
			_p.append(Vector3(r.randf_range(0, vp.x), r.randf_range(0, vp.y), r.randf_range(0.4, 1.4)))

	func _process(delta: float) -> void:
		_t += delta
		for i in _p.size():
			var e: Vector3 = _p[i]
			e.x += sin(_t * 0.5 + e.z * 6.0) * 8.0 * delta
			e.y += 6.0 * delta * e.z
			if e.y > vp.y:
				e.y = 0.0
			_p[i] = e
		queue_redraw()

	func _draw() -> void:
		for e in _p:
			draw_circle(Vector2(e.x, e.y), 1.2 * e.z, Color(0.85, 0.75, 0.6, 0.3))
