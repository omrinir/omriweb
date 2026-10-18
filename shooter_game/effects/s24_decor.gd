extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 24 ("BURNING FIELDS") - שדות חיטה בוערים בלילה: אסם אדום, ממגורות, טחנת רוח, עשן ואש באופק.
#    night_sky     - (רקע) לילה אדום מעשן, ירח כתום, עמודי עשן
#    far_fire      - (רקע) גבעות עם קו אש בוער לאורך האופק
#    mid_farm      - (רקע) אסם אדום, ממגורות, טחנת רוח מסתובבת, גדרות
#    near_wheat    - (רקע) שיבולים גבוהות מתנדנדות, חלקן בוערות
#    FieldGround   - (עולם) דרך עפר בין שיבולים, תלמים, קש
#    Scarecrow     - (עולם, קישוט) דחליל על עמוד. לפעמים עורב יושב עליו. הדחלילים האמיתיים (SCARECROW) - בלי עורבים!
#    BearTrap      - (עולם, מלכודת) מלכודת דובים חבויה בעשב (שיניים מנצנצות לפעמים). דורכים -> נתפס (HOLD_T, A/D מהר = משתחרר),
#                    1 נזק. זומבי שנתפס - נתקע ונפגע (לפתות אותם!). זומבים חכמים עוקפים.
#    Obstacle      - (מוצק + מחסה) "bale" חבילת קש / "fence" גדר / "cart" עגלה
#    FieldFX       - (מסך) גחלים, אפר וזוהר אדום
#  scarecrow_body() - הציור המשותף לדחליל קישוט ולזומבי SCARECROW כשהוא "מתחזה".
#  לשנות: BearTrap.HOLD_T, BearTrap.Z_DMG, Scarecrow.crow.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const SOIL := Color("4a3626")
const SOIL_D := Color("2e2018")
const WHEAT := Color("c8a050")
const WHEAT_D := Color("8a6a30")
const BURLAP := Color("b8a070")
const POST_H := 30.0


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- לילה אדום ----
static func night_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("0e0a12"), Color("2a1218"), Color("5a1e1a"), Color("8a3a1e")], 0.85)
	var moon := Vector2(v.x * 0.22, v.y * 0.2)
	DrawBatch.circle(ci, moon, 46.0, Color(1.0, 0.55, 0.3, 0.12))
	DrawBatch.circle(ci, moon, 26.0, Color("e8a060"))
	DrawBatch.circle(ci, moon + Vector2(7, -5), 6.0, Color(0.8, 0.45, 0.25, 0.6))
	for i in 3:
		Kit.smoke_column(ci, Vector2(v.x * (0.35 + 0.25 * float(i)), v.y * 0.62), t + float(i) * 3.0, 380.0, Color(0.1, 0.06, 0.06, 0.4), 160.0)


# ---- גבעות + קו אש באופק ----
static func far_fire(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1600.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 53 + 7)
		var pts := PackedVector2Array([Vector2(x, y)])
		for i in 9:
			pts.append(Vector2(x + float(i) * period / 8.0, y - r.randf_range(30.0, 90.0)))
		pts.append(Vector2(x + period, y))
		DrawBatch.colored_polygon(ci, pts, Color("241014"))
		for i in 8:   # קו אש על הגבעות
			var p: Vector2 = pts[i + 1]
			var h := 14.0 + 10.0 * sin(t * 6.0 + float(i) * 1.9 + float(k))
			DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(-26, 2), p + Vector2(-8, -h * 0.7), p + Vector2(0, -h), p + Vector2(10, -h * 0.6), p + Vector2(26, 2)]), Color(1.0, 0.45, 0.12, 0.55))
			DrawBatch.circle(ci, p, 40.0, Color(1.0, 0.35, 0.1, 0.07))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("241014"))


# ---- אסם, ממגורות, טחנת רוח ----
static func mid_farm(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var dark := Color("1a0c0e")
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 311 + 5)
		# אסם אדום (מואר מהאש)
		var bx := x + 200.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx, y), Vector2(bx, y - 110), Vector2(bx + 30, y - 160), Vector2(bx + 130, y - 160), Vector2(bx + 160, y - 110), Vector2(bx + 160, y)]), Color("5a1a16"))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx - 8, y - 108), Vector2(bx + 30, y - 166), Vector2(bx + 130, y - 166), Vector2(bx + 168, y - 108), Vector2(bx + 160, y - 108), Vector2(bx + 128, y - 158), Vector2(bx + 32, y - 158), Vector2(bx, y - 108)]), dark)
		DrawBatch.rect(ci, Rect2(bx + 55, y - 70, 50, 70), Color("2a0e0c"))
		DrawBatch.line(ci, Vector2(bx + 55, y - 70), Vector2(bx + 105, y), Color("c8b8a0", 0.5), 2.0)
		DrawBatch.line(ci, Vector2(bx + 105, y - 70), Vector2(bx + 55, y), Color("c8b8a0", 0.5), 2.0)
		DrawBatch.rect(ci, Rect2(bx + 68, y - 130, 24, 20), Color(1.0, 0.6, 0.25, 0.5 + 0.2 * sin(t * 5.0 + float(k))))   # חלון בוער
		# ממגורות
		for s in 2:
			var sx := bx + 190.0 + float(s) * 46.0
			DrawBatch.rect(ci, Rect2(sx, y - 190, 40, 190), Color("3a2a2c"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(sx, y - 190), Vector2(sx + 20, y - 212), Vector2(sx + 40, y - 190)]), dark)
			for q in 5:
				DrawBatch.line(ci, Vector2(sx, y - 30.0 - float(q) * 34.0), Vector2(sx + 40, y - 30.0 - float(q) * 34.0), Color(0, 0, 0, 0.25), 1.5)
		# טחנת רוח
		var wx := x + r.randf_range(800.0, 1250.0)
		DrawBatch.line(ci, Vector2(wx - 20, y), Vector2(wx - 3, y - 170), dark, 3.0)
		DrawBatch.line(ci, Vector2(wx + 20, y), Vector2(wx + 3, y - 170), dark, 3.0)
		for q in 4:
			DrawBatch.line(ci, Vector2(wx - 18 + float(q) * 4.0, y - float(q) * 40.0), Vector2(wx + 18 - float(q) * 4.0, y - float(q) * 40.0 - 40.0), dark, 1.2)
		var hub := Vector2(wx, y - 176)
		for b in 6:
			var a := t * 0.8 + float(b) * TAU / 6.0 + float(k)
			DrawBatch.line(ci, hub, hub + Vector2.from_angle(a) * 46.0, dark, 3.0)
			DrawBatch.line(ci, hub + Vector2.from_angle(a) * 20.0, hub + Vector2.from_angle(a) * 46.0 + Vector2.from_angle(a + 1.57) * 8.0, dark, 2.0)
		DrawBatch.circle(ci, hub, 5.0, dark)
		# גדר
		var fx := x + r.randf_range(450.0, 700.0)
		for f in 7:
			DrawBatch.line(ci, Vector2(fx + float(f) * 40.0, y), Vector2(fx + float(f) * 40.0, y - 34), dark, 3.0)
		DrawBatch.line(ci, Vector2(fx, y - 28), Vector2(fx + 240, y - 28), dark, 2.5)
		DrawBatch.line(ci, Vector2(fx, y - 14), Vector2(fx + 240, y - 14), dark, 2.5)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), dark)


# ---- שיבולים קרובות ----
static func near_wheat(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	var col := Color("3a2414")
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 149 + 1)
		for i in 26:   # גושי שיבולים
			var px := x + float(i) * period / 26.0 + r.randf_range(-8.0, 8.0)
			var h := r.randf_range(36.0, 64.0)
			var sway := sin(t * 1.5 + px * 0.02) * 4.0
			DrawBatch.line(ci, Vector2(px, y), Vector2(px + sway, y - h), col, 2.0)
			DrawBatch.line(ci, Vector2(px + sway, y - h), Vector2(px + sway * 1.2, y - h - 9), Color("5a3a1a"), 3.5)
		var bx := x + r.randf_range(100.0, 800.0)   # כתם בוער
		Kit.fire_glow(ci, Vector2(bx, y - 4), t, 46.0, k)
	DrawBatch.rect(ci, Rect2(0, y - 2.0, v.x, v.y - y + 2.0), col)


# ---- דחליל (ציור משותף). (0,0) = כפות הרגליים על הקורה, פונה ימינה. head_turn = כמה הראש מסתובב (-1..1) ----
static func scarecrow_body(ci: CanvasItem, flash: bool, head_turn := 0.0, sway := 0.0) -> void:
	var W := func(c: Color) -> Color: return Color.WHITE if flash else c
	var shirt: Color = W.call(Color("5a3a6a"))
	var patch: Color = W.call(Color("8a5a2a"))
	var straw: Color = W.call(WHEAT)
	var sack: Color = W.call(BURLAP)
	var pants: Color = W.call(Color("3a4a5a"))
	var hip := Vector2(0, -20)
	var sh := Vector2(0, -38)
	# רגליים משתלשלות
	for lx in [-3.0, 3.0]:
		DrawBatch.line(ci, hip + Vector2(lx, 0), Vector2(lx * 1.3 + sway, 0), pants, 5.0)
		DrawBatch.line(ci, Vector2(lx * 1.3 + sway - 2, 0), Vector2(lx * 1.3 + sway + 2, 3), straw, 1.5)
	# ידיים פרושות על הקורה + קש מהשרוולים
	for side in [-1.0, 1.0]:
		var hand := sh + Vector2(side * 24.0, 1.0)
		DrawBatch.line(ci, sh + Vector2(side * 4.0, 0), hand, Art.OUTLINE, 6.5)
		DrawBatch.line(ci, sh + Vector2(side * 4.0, 0), hand, shirt, 5.0)
		for q in 3:
			DrawBatch.line(ci, hand, hand + Vector2(side * 5.0, -3.0 + float(q) * 3.0), straw, 1.4)
	# גוף
	Art.fill_shaded(ci, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, -1), hip + Vector2(6, 2), hip + Vector2(-6, 2)]), shirt, 0.12, 0.35)
	DrawBatch.rect(ci, Rect2(sh + Vector2(1, 6), Vector2(5, 5)), patch)
	DrawBatch.line(ci, hip + Vector2(-6, 0), hip + Vector2(6, 0), W.call(Color("6a4a2a")), 2.0)   # חבל
	for q in 3:
		DrawBatch.line(ci, hip + Vector2(-4.0 + float(q) * 4.0, 2), hip + Vector2(-5.0 + float(q) * 5.0, 7), straw, 1.4)
	# ראש שק עם פרצוף תפור + כובע קש
	var head := sh + Vector2(1.0 + head_turn * 2.0, -8.0)
	Art.oval_shaded(ci, head, 6.2, 6.8, sack, 0.0)
	DrawBatch.line(ci, head + Vector2(-1 + head_turn * 2.0, 3), head + Vector2(4 + head_turn * 2.0, 3), W.call(Color("3a2a1a")), 1.0)   # תפר פה
	for q in 3:
		DrawBatch.line(ci, head + Vector2(head_turn * 2.0 + float(q) * 1.6 - 0.5, 2), head + Vector2(head_turn * 2.0 + float(q) * 1.6 - 0.5, 4), W.call(Color("3a2a1a")), 0.8)
	for ex in [-1.5, 3.5]:   # עיניים: כפתורים
		DrawBatch.circle(ci, head + Vector2(ex + head_turn * 2.0, -1.5), 1.2, W.call(Color("1a1414")))
	DrawBatch.line(ci, head + Vector2(-5, 5), head + Vector2(5, 5), W.call(Color("6a4a2a")), 1.4)   # קשירה בצוואר
	Art.fill(ci, PackedVector2Array([head + Vector2(-11, -4), head + Vector2(11, -4), head + Vector2(6, -6), head + Vector2(4, -12), head + Vector2(-4, -12), head + Vector2(-6, -6)]), straw, Art.OUTLINE, 1.0)
	DrawBatch.line(ci, head + Vector2(-6, -6), head + Vector2(6, -6), W.call(Color("8a2a22")), 1.6)


# עמוד + קורה (מאחורי הדחליל). (0,0) = על הקרקע
static func scarecrow_post(ci: CanvasItem) -> void:
	var wood := Color("5a4028")
	DrawBatch.rect(ci, Rect2(-2.5, -POST_H - 46.0, 5.0, POST_H + 46.0), wood)
	DrawBatch.rect(ci, Rect2(-28.0, -POST_H - 40.0, 56.0, 4.0), wood)
	DrawBatch.line(ci, Vector2(-6, 0), Vector2(6, 0), Color("2a1c10"), 3.0)


# ---- דרך עפר + שיבולים ----
class FieldGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s24_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), S.SOIL_D)
		DrawBatch.rect(self, Rect2(0, 0, w, 9.0), S.SOIL)
		for i in int(w / 18.0):   # תלמים
			var px := r.randf_range(0.0, w)
			DrawBatch.line(self, Vector2(px, 12), Vector2(px + r.randf_range(20.0, 60.0), 12.0 + r.randf_range(0.0, 30.0)), Color(0, 0, 0, 0.2), 1.5)
		for i in int(w / 10.0):   # קש על הדרך
			var px := r.randf_range(0.0, w)
			DrawBatch.line(self, Vector2(px, 2), Vector2(px + r.randf_range(-5.0, 5.0), 2.0 + r.randf_range(-2.0, 2.0)), S.WHEAT_D, 1.0)
		for i in int(w / 340.0):   # כתם שרוף
			var px := r.randf_range(0.0, w - 80.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(px, 4), r.randf_range(20.0, 40.0), 3.5), Color(0.06, 0.04, 0.03, 0.6))


# ---- דחליל קישוט (לא זז). crow = עורב יושב על הכובע / היד ----
class Scarecrow extends Node2D:
	var crow := true
	var seed_v := 0
	var _t := 0.0
	var _crow_hop := 0.0

	func _ready() -> void:
		z_index = -1
		_t = randf() * 6.0

	func _process(delta: float) -> void:
		if not crow:
			return
		_t += delta
		var hop := 1.0 if fmod(_t, 5.0) < 0.25 else 0.0   # העורב מקפץ קצת
		if hop != _crow_hop and Art.on_screen(self, global_position):
			_crow_hop = hop
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s24_decor.gd")
		S.scarecrow_post(self)
		DrawBatch.set_transform(self, Vector2(0, -S.POST_H), 0.0, Vector2(-1.0 if seed_v % 2 == 0 else 1.0, 1.0))
		S.scarecrow_body(self, false, 0.0)
		if crow:
			var c := Vector2(20, -42.0 - _crow_hop * 4.0) if seed_v % 3 != 0 else Vector2(2, -66.0 - _crow_hop * 4.0)
			DrawBatch.colored_polygon(self, Art.ellipse(c, 5.0, 3.5), Color("141016"))
			DrawBatch.circle(self, c + Vector2(4, -3), 2.6, Color("141016"))
			DrawBatch.colored_polygon(self, PackedVector2Array([c + Vector2(6, -3.5), c + Vector2(10, -2.5), c + Vector2(6, -2)]), Color("a08a40"))
			DrawBatch.colored_polygon(self, PackedVector2Array([c + Vector2(-4, -1), c + Vector2(-10, 1), c + Vector2(-4, 2)]), Color("141016"))
			DrawBatch.line(self, c + Vector2(0, 3), c + Vector2(0, 6), Color("141016"), 1.0)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ---- מלכודת דובים חבויה בעשב ----
class BearTrap extends Node2D:
	const HOLD_T := 1.5          # כמה זמן מחזיקה את השחקן (A/D מהר = פחות)
	const DMG := 1
	const Z_DMG := 14
	const Z_HOLD := 2.2
	const W := 26.0
	var state := 0               # 0 = דרוכה, 1 = תפסה שחקן, 2 = תפסה זומבי, 3 = סגורה (לא מסוכנת)
	var caught_player := 0       # לבדיקות
	var caught_zombie := 0
	var dead := false            # (player.grab בודק .dead)
	var _hold := 0.0
	var _glint := 0.0
	var _victim: Node = null
	var _jaw := 0.0              # 0 = פתוחה, 1 = סגורה

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")
		_glint = randf() * 3.0

	func danger_at(p: Vector2, margin := 0.0) -> bool:   # זומבים חכמים עוקפים (ai/zombie_brain.gd)
		return state == 0 and absf(p.x - global_position.x) < W * 0.5 + margin and absf(p.y - global_position.y) < 40.0

	func world_rect() -> Rect2:   # (ai/zombie_brain.gd: קופצים מעל סכנה קטנה)
		return Rect2(global_position + Vector2(-W * 0.5, -10.0), Vector2(W, 10.0))

	func release_grab() -> void:   # player.gd: השחקן השתחרר (A/D)
		_free_player()

	func _physics_process(delta: float) -> void:
		_glint += delta
		match state:
			0:
				var pl := get_tree().get_first_node_in_group("player")
				if pl != null and not pl.dead and pl.is_on_floor() and pl.grabbed_by == null:
					var r: Rect2 = pl.body_rect()
					if r.end.y > global_position.y - 8.0 and r.end.y < global_position.y + 8.0 and absf(r.get_center().x - global_position.x) < W * 0.5:
						_snap_player(pl)
						return
				if Engine.get_physics_frames() % 4 == 0:
					for z in get_tree().get_nodes_in_group("zombies"):
						if z.dead or not z.is_on_floor() or z.get("possessed") != null and z.possessed != null:
							continue
						if absf(z.global_position.x - global_position.x) < W * 0.5 and absf(z.global_position.y - global_position.y) < 8.0:
							_snap_zombie(z)
							return
				var g := fmod(_glint, 2.6) < 0.15   # ניצוץ קטן על השיניים
				if g != has_meta("g") and Art.on_screen(self, global_position):
					if g: set_meta("g", true)
					else: remove_meta("g")
					queue_redraw()
			1:
				_hold -= delta
				if _victim != null and is_instance_valid(_victim):
					_victim.global_position.x = move_toward(_victim.global_position.x, global_position.x, 200.0 * delta)
					_victim.velocity.x = 0.0
				if _hold <= 0.0 or _victim == null or not is_instance_valid(_victim) or _victim.dead or _victim.grabbed_by != self:
					_free_player()
			2:
				_hold -= delta
				if _victim != null and is_instance_valid(_victim) and not _victim.dead:
					_victim.global_position.x = global_position.x
					_victim.velocity.x = 0.0
					_victim._stagger_t = maxf(float(_victim._stagger_t), 0.2)
				if _hold <= 0.0 or _victim == null or not is_instance_valid(_victim) or _victim.dead:
					state = 3
					_victim = null
					set_physics_process(false)

	func _snap() -> void:
		_jaw = 1.0
		Sfx.play("s24_snap", global_position, 4.0, 0.08, 2)
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -4), "smoke", Vector2.UP, 4)
		queue_redraw()

	func _snap_player(pl: Node) -> void:
		state = 1
		caught_player += 1
		_victim = pl
		_hold = HOLD_T
		_snap()
		pl.hurt(DMG, Vector2.ZERO)
		pl.grab(self)
		pl._say("BEAR TRAP!  A / D", Color("ff6050"))

	func _free_player() -> void:
		if _victim != null and is_instance_valid(_victim) and _victim.grabbed_by == self:
			_victim.grabbed_by = null
		_victim = null
		state = 3
		dead = true
		set_physics_process(false)
		queue_redraw()

	func _snap_zombie(z: Node) -> void:
		state = 2
		caught_zombie += 1
		_victim = z
		_hold = Z_HOLD
		_snap()
		z.take_damage(Z_DMG, z.global_position + Vector2(0, -10), Vector2.UP, false, {"source": "hazard", "fixed": Z_DMG})
		if not z.dead:
			z._popup("TRAPPED!", Color("ffb070"), 14, -70.0)

	func _draw() -> void:
		var metal := Color("6a6a6e")
		var dk := Color("3a3a3e")
		DrawBatch.line(self, Vector2(-W * 0.5 - 8, -1), Vector2(W * 0.5 + 8, -1), Color("2a2420"), 2.0)   # שרשרת / יתד
		DrawBatch.circle(self, Vector2(W * 0.5 + 9, -1), 2.0, dk)
		if _jaw < 0.5:   # פתוחה: שתי לסתות שטוחות על הקרקע
			DrawBatch.rect(self, Rect2(-W * 0.5, -3, W, 3), dk)
			for i in 6:
				var x := -W * 0.5 + 2.0 + float(i) * (W - 4.0) / 5.0
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x - 2, -2), Vector2(x, -6), Vector2(x + 2, -2)]), metal)
			DrawBatch.circle(self, Vector2(0, -2), 3.0, Color("8a7a50"))   # פלטת דריכה
			if has_meta("g"):
				DrawBatch.circle(self, Vector2(-4, -6), 3.0, Color(1, 1, 0.9, 0.8))
				DrawBatch.line(self, Vector2(-9, -6), Vector2(1, -6), Color(1, 1, 1, 0.7), 1.0)
				DrawBatch.line(self, Vector2(-4, -11), Vector2(-4, -1), Color(1, 1, 1, 0.7), 1.0)
		else:   # סגורה: קשת שיניים
			DrawBatch.arc(self, Vector2(0, -2), 10.0, PI, TAU, 10, dk, 3.0)
			for i in 5:
				var a := PI + float(i + 1) * PI / 6.0
				var p := Vector2(0, -2) + Vector2.from_angle(a) * 10.0
				DrawBatch.line(self, p, p + Vector2(0, 4), metal, 1.6)
			if state == 1 or state == 2:
				DrawBatch.circle(self, Vector2(0, -6), 3.0, Color(0.6, 0.05, 0.05, 0.8))
		# עשב שמסתיר (מלפנים)
		if state == 0:
			for i in 7:
				var x := -W * 0.5 - 4.0 + float(i) * (W + 8.0) / 6.0
				DrawBatch.line(self, Vector2(x, 0), Vector2(x + (2.0 if i % 2 == 0 else -2.0), -9.0 - float(i % 3) * 2.0), Color("6a5028"), 1.6)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "bale"
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
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s24_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"bale":   # חבילת קש עגולה (מהצד: עיגול עם ספירלה)
				var c := Vector2(w * 0.5, -h * 0.5)
				DrawBatch.circle(self, c, h * 0.5 + 1.5, Art.OUTLINE)
				DrawBatch.circle(self, c, h * 0.5, S.WHEAT)
				for q in 4:
					DrawBatch.arc(self, c, h * 0.5 * (0.2 + 0.2 * float(q)), float(q), float(q) + 5.0, 12, S.WHEAT_D, 1.3)
				DrawBatch.line(self, c + Vector2(-h * 0.45, -h * 0.2), c + Vector2(h * 0.45, -h * 0.2), Color("8a2a22"), 1.5)
				for q in 6:
					var a := r.randf() * TAU
					DrawBatch.line(self, c + Vector2.from_angle(a) * h * 0.48, c + Vector2.from_angle(a) * (h * 0.5 + 4.0), S.WHEAT, 1.0)
				if w > h + 10.0:   # שתי חבילות
					var c2 := Vector2(w - h * 0.5, -h * 0.5)
					DrawBatch.circle(self, c2, h * 0.5 + 1.5, Art.OUTLINE)
					DrawBatch.circle(self, c2, h * 0.5, Art.shade(S.WHEAT, 0.12))
					for q in 3:
						DrawBatch.arc(self, c2, h * 0.5 * (0.25 + 0.25 * float(q)), float(q) * 2.0, float(q) * 2.0 + 5.0, 12, S.WHEAT_D, 1.3)
			"fence":   # גדר עץ שבורה
				for i in 4:
					var px := float(i) * (w - 6.0) / 3.0
					DrawBatch.rect(self, Rect2(px, -h, 6, h), Color("5a4028"))
				Art.fill(self, PackedVector2Array([Vector2(0, -h * 0.75), Vector2(w, -h * 0.8), Vector2(w, -h * 0.65), Vector2(0, -h * 0.6)]), Color("6a4a2e"), Art.OUTLINE, 1.0)
				Art.fill(self, PackedVector2Array([Vector2(0, -h * 0.35), Vector2(w * 0.6, -h * 0.4), Vector2(w * 0.62, -h * 0.25), Vector2(0, -h * 0.2)]), Color("6a4a2e"), Art.OUTLINE, 1.0)
			_:   # עגלת עץ הפוכה עם גלגל
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 6, -h * 0.75), Vector2(6, -h * 0.75)]), Color("6a4a2e"), 0.15, 0.4, Art.OUTLINE, 1.4)
				for q in 3:
					DrawBatch.line(self, Vector2(4, -h * 0.25 * float(q + 1) + 2.0), Vector2(w - 4, -h * 0.25 * float(q + 1) + 2.0), Color(0, 0, 0, 0.3), 1.5)
				var wc := Vector2(w * 0.75, -h * 0.75)
				DrawBatch.circle(self, wc, h * 0.3, Art.OUTLINE)
				DrawBatch.circle(self, wc, h * 0.3 - 2.0, Color("5a4028"))
				for q in 4:
					DrawBatch.line(self, wc, wc + Vector2.from_angle(float(q) * PI / 4.0 + 0.3) * h * 0.28, Color("3a2818"), 1.6)
				DrawBatch.line(self, Vector2(w * 0.2, -h * 0.75), Vector2(w * 0.05, -h * 1.05), Color("5a4028"), 3.0)   # ידית


# ---- גחלים + זוהר (שכבת מסך) ----
class FieldFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _e := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 24
		for i in 48:
			_e.append(Vector3(r.randf_range(0, vp.x), r.randf_range(0, vp.y), r.randf_range(0.5, 1.6)))

	func _process(delta: float) -> void:
		_t += delta
		for i in _e.size():
			var e: Vector3 = _e[i]
			e.x += (20.0 + sin(_t * 0.7 + e.z * 4.0) * 30.0) * delta * e.z
			e.y -= 40.0 * delta * e.z
			if e.y < -10.0 or e.x > vp.x + 10.0:
				e = Vector3(randf_range(-100.0, vp.x), vp.y + 10.0, e.z)
			_e[i] = e
		queue_redraw()

	func _draw() -> void:
		for e in _e:
			var hot: bool = e.z > 1.0
			DrawBatch.circle(self, Vector2(e.x, e.y), 1.3 * e.z, Color(1.0, 0.5 + 0.2 * sin(_t * 9.0 + e.x), 0.15, 0.75) if hot else Color(0.35, 0.3, 0.3, 0.5))
		DrawBatch.rect(self, Rect2(0, vp.y - 120, vp.x, 120), Color(1.0, 0.3, 0.1, 0.07 + 0.02 * sin(_t * 3.0)))
