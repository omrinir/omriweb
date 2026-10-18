extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 42 ("METRO BARRACKS") - המטרו של ברזיליה, מתחת לבירה. אזור חמישי, שלב 6.
#  אימפריית המתים הפכה את התחנה לקסרקטין: מיטות קומתיים על הרציף, מתלי נשק, כרזות אדומות על קירות האריחים -
#  פסיפס אריחים גאומטרי כחול-לבן בסגנון של אתוס בולקאו (האמן של ברזיליה), מנורות פלורסנט מהבהבות, פתחי מנהרות.
#    metro_ceiling   - (רקע) תקרת בטון עם שורות פלורסנט (חלק מהן מהבהבות)
#    far_tiles       - (רקע) קיר האריחים הגאומטריים + שלט התחנה + פתחי מנהרה עם אור אדום
#    mid_barracks    - (רקע) מיטות קומתיים, מתלי רובים, כרזות, פוסטרים של האימפריה
#    near_columns    - (רקע) עמודי בטון, צינורות וכבלים תלויים
#    PlatformGround  - (עולם) רציף עם פס בטיחות צהוב ופסי רכבת בבור
#    Mezzanine       - (עולם) גשר הולכי רגל מעל הרציף (הקומה = add_floor) עם מעקה
#    MGNest          - (עולם, מלכודת) קן מקלע מבין שקי חול. "THEY WORK TOGETHER": חייל אימפריה מאייש אותו;
#                      הורגים את התותחן -> החייל הקרוב רץ לאייש ("MAN THE GUN!"). AMMO כדורים ואז טעינה ארוכה -
#                      אלא אם LOADER מביא ארגז. יורה ב-E.fire (לומד יחד עם כל הרובאים - empire_kit squad_aim_y).
#    Tripwire        - (עולם, מלכודת) חוט מעידה עם רימון: דורכים -> קליק -> פיצוץ. קופצים מעליו, או מתכופפים עליו DISARM_T
#                      לפרק. ירייה ברימון = פיצוץ מרחוק. חיילי האימפריה יודעים איפה החוטים (לא מפעילים).
#    FirePatch       - (עולם, סכנה) שלולית נפאלם בוערת (FLAMER): נזק לשחקן, מצית זומבים. אפשר להתחיל עם delay = מיכל נופל.
#    Sandbags        - (עולם, מחסה) קיר שקי חול שה-PIONEER בונה: נבנה לאט, HP, ירי מוריד, פיצוץ מפרק.
#    Obstacle        - (מוצק + מחסה) "bunk" מיטת קומתיים / "footlocker" ארגז חייל / "rack" מתלה רובים
#    MetroFX         - (מסך) אבק שמרחף באור, הבהוב פלורסנט
#  לשנות: MGNest.AMMO / BURST / CD / RANGE, Tripwire.FUSE / BLAST_R / DISARM_T, FirePatch.LIFE, Sandbags.HP / BUILD_T.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const E := preload("res://enemies/empire_kit.gd")

const TILE_A := Color("2a5a9a")
const TILE_B := Color("d8dce4")


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


# ---- תקרה ----
static func metro_ceiling(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("0c0e14"), Color("1a1e28"), Color("262a34"), Color("2e323c")], 0.95)
	for row in 2:
		var y := 40.0 + float(row) * 60.0
		for q in 7:
			var x := v.x * (0.04 + float(q) * 0.15) + float(row) * 60.0
			var flick := _h(q + row * 7, 4) < 0.25 and fposmod(t * (3.0 + float(q)), 1.0) < 0.3
			var a := 0.15 if flick else 0.85
			DrawBatch.rect(ci, Rect2(x, y, 120.0, 5.0), Color(0.85, 0.95, 1.0, a))
			if not flick:
				Art.glow(ci, Vector2(x + 60.0, y + 3.0), 70.0, Color(0.7, 0.85, 1.0, 0.06))


# ---- קיר האריחים ----
static func far_tiles(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := y - 330.0
	DrawBatch.rect(ci, Rect2(0, top, v.x, v.y - top), Color("1c2230"))
	var ts := 40.0
	var x0 := -fposmod(sc, ts)
	var i0 := int(floor(sc / ts))
	var col := 0
	var x := x0
	var banners := []
	while x < v.x:
		var ci_ := i0 + col
		var panel := posmod(int(floor(float(ci_) / 12.0)), 4)
		for row in 5:
			var ty := top + 70.0 + float(row) * ts
			var tr := Rect2(x + 1.0, ty + 1.0, ts - 2.0, ts - 2.0)
			if panel == 3:   # פתח מנהרה (בכל לוח רביעי)
				continue
			var a := (ci_ + row) % 2 == 0
			DrawBatch.rect(ci, tr, (TILE_B if a else TILE_A).darkened(0.5))
			# מוטיב גאומטרי בסגנון בולקאו: משולש / חצי עיגול / פס, מסובב לפי האריח
			var m := posmod(ci_ * 3 + row * 5 + panel, 4)
			var c: Vector2 = tr.get_center()
			var mc := (TILE_A if a else TILE_B).darkened(0.5)
			match m:
				0:
					DrawBatch.colored_polygon(ci, PackedVector2Array([tr.position, tr.position + Vector2(tr.size.x, 0), tr.position + Vector2(0, tr.size.y)]), mc)
				1:
					DrawBatch.circle(ci, c + Vector2(0, tr.size.y * 0.5), tr.size.x * 0.32, mc)
				2:
					DrawBatch.rect(ci, Rect2(tr.position + Vector2(tr.size.x * 0.4, 0), Vector2(tr.size.x * 0.2, tr.size.y)), mc)
				_:
					DrawBatch.colored_polygon(ci, PackedVector2Array([c + Vector2(0, -12), c + Vector2(12, 0), c + Vector2(0, 12), c + Vector2(-12, 0)]), mc)
		if panel == 3 and posmod(ci_, 12) == 0:   # פתח המנהרה: קשת חשוכה + אור אדום
			var ax := x + 4.0 * ts
			var arch := PackedVector2Array()
			for q in 13:
				var aa := PI + float(q) / 12.0 * PI
				arch.append(Vector2(ax + cos(aa) * 150.0, top + 230.0 + sin(aa) * 110.0))
			arch.append(Vector2(ax + 150.0, y))
			arch.append(Vector2(ax - 150.0, y))
			DrawBatch.colored_polygon(ci, arch, Color("07080c"))
			var on := fposmod(t * 0.7 + float(ci_) * 0.1, 2.0) < 1.4
			Art.glow(ci, Vector2(ax - 40.0, top + 270.0), 26.0, Color(1.0, 0.15, 0.1, 0.5 if on else 0.15))
			DrawBatch.circle(ci, Vector2(ax - 40.0, top + 270.0), 3.0, Color(1.0, 0.2, 0.15) if on else Color(0.3, 0.05, 0.05))
		if posmod(ci_, 24) == 5:   # שלט התחנה (רצועה) + כרזה
			DrawBatch.rect(ci, Rect2(x, top + 24.0, 220.0, 34.0), Color("14161c"))
			DrawBatch.string(ci, ThemeDB.fallback_font, Vector2(x + 18.0, top + 50.0), "CENTRAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.92, 0.92, 0.9))
			banners.append(x + 300.0)
		x += ts
		col += 1
	for bx in banners:   # הכרזות מעל האריחים (אחרי כל האריחים)
		E.banner(ci, Vector2(bx, top + 40.0), 50.0, 170.0, t)


# ---- הקסרקטין: מיטות, מתלים, פוסטרים ----
static func mid_barracks(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 420.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var c := Color("2a2e36")
		for b in 2:   # מיטות קומתיים
			var bx := x + 20.0 + float(b) * 110.0
			DrawBatch.rect(ci, Rect2(bx, y - 90.0, 4.0, 90.0), c)
			DrawBatch.rect(ci, Rect2(bx + 86.0, y - 90.0, 4.0, 90.0), c)
			for lv in 2:
				var ly := y - 30.0 - float(lv) * 50.0
				DrawBatch.rect(ci, Rect2(bx, ly, 90.0, 8.0), c)
				DrawBatch.rect(ci, Rect2(bx + 4.0, ly - 5.0, 82.0, 5.0), Color("4a4636"))   # שמיכת צבא
				DrawBatch.rect(ci, Rect2(bx + 6.0, ly - 9.0, 14.0, 5.0), Color("8a8676"))   # כרית
		# מתלה רובים
		var rx := x + 250.0
		DrawBatch.rect(ci, Rect2(rx, y - 70.0, 60.0, 4.0), c)
		for q in 6:
			DrawBatch.line(ci, Vector2(rx + 6.0 + float(q) * 9.0, y - 66.0), Vector2(rx + 4.0 + float(q) * 9.0, y - 10.0), Color("1a1814"), 2.0)
		DrawBatch.rect(ci, Rect2(rx, y - 12.0, 60.0, 4.0), c)
		# פוסטר האימפריה
		var px := x + 340.0
		DrawBatch.rect(ci, Rect2(px, y - 150.0, 54.0, 76.0), E.RED_D)
		DrawBatch.rect(ci, Rect2(px + 3.0, y - 147.0, 48.0, 70.0), E.RED)
		E.emblem(ci, Vector2(px + 27.0, y - 125.0), 15.0)
		DrawBatch.string(ci, ThemeDB.fallback_font, Vector2(px + 8.0, y - 86.0), "OBEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.92, 0.85))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("181b22"))


# ---- עמודים, צינורות ----
static func near_columns(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	DrawBatch.rect(ci, Rect2(0, 18.0, v.x, 10.0), Color("1a1c22"))   # צינור תקרה
	DrawBatch.rect(ci, Rect2(0, 34.0, v.x, 6.0), Color("22252c"))
	var period := 520.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		DrawBatch.rect(ci, Rect2(x, 40.0, 46.0, y - 40.0), Color("23262e"))
		DrawBatch.rect(ci, Rect2(x + 4.0, 40.0, 6.0, y - 40.0), Color("2c3038"))
		DrawBatch.rect(ci, Rect2(x - 6.0, y - 30.0, 58.0, 30.0), Color("1e2128"))
		var sway := sin(t * 0.8 + float(k)) * 4.0   # כבלים תלויים
		var pts := PackedVector2Array()
		for q in 9:
			var u := float(q) / 8.0
			pts.append(Vector2(x + 46.0 + u * 160.0, 40.0 + sin(u * PI) * (60.0 + sway)))
		DrawBatch.polyline(ci, pts, Color("101114"), 2.0)
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("121418"))


# ============================================================
#  עולם
# ============================================================
class PlatformGround extends Node2D:
	var w := 1024.0
	var depth := 90.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("3a3c42"))
		DrawBatch.rect(self, Rect2(0, 0, w, 6.0), Color("d8b830"))   # פס בטיחות צהוב
		var x := 0.0
		while x < w:
			DrawBatch.rect(self, Rect2(x, 1.0, 3.0, 4.0), Color("2a2a2a"))
			x += 9.0
		DrawBatch.rect(self, Rect2(0, 26.0, w, 30.0), Color("16171a"))   # בור הפסים
		DrawBatch.rect(self, Rect2(0, 34.0, w, 3.0), Color("8a8a90"))
		DrawBatch.rect(self, Rect2(0, 48.0, w, 3.0), Color("8a8a90"))
		x = 0.0
		while x < w:
			DrawBatch.rect(self, Rect2(x, 37.0, 8.0, 11.0), Color("2a2620"))
			x += 22.0


class Mezzanine extends Node2D:   # גשר הולכי רגל (הקומה עצמה = add_floor)
	var w := 400.0
	var tier := 140.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.rect(self, Rect2(0, -tier, w, 12.0), Color("4a4e58"))
		DrawBatch.rect(self, Rect2(0, -tier + 12.0, w, 4.0), Color("2a2c32"))
		for q in int(w / 16.0) + 1:   # מעקה
			DrawBatch.line(self, Vector2(float(q) * 16.0, -tier), Vector2(float(q) * 16.0, -tier - 26.0), Color("6a6e78"), 1.5)
		DrawBatch.line(self, Vector2(0, -tier - 26.0), Vector2(w, -tier - 26.0), Color("8a8e98"), 2.5)
		for px in [10.0, w - 22.0]:   # עמודי תמיכה
			DrawBatch.rect(self, Rect2(px, -tier + 16.0, 12.0, tier - 16.0), Color("33363e"))
		E.banner(self, Vector2(w * 0.5, -tier + 16.0), 40.0, 70.0, float(Engine.get_process_frames()) / 60.0)


# ---- קן מקלע ----
class MGNest extends StaticBody2D:
	const AMMO := 30
	const BURST := 5
	const RATE := 0.1
	const CD := 2.0
	const RELOAD_T := 6.0
	const RANGE := 820.0
	const RECRUIT_R := 520.0
	const SIZE := Vector2(76, 30)
	var face := -1.0                # לאן הקנה מכוון
	var ammo := AMMO
	var gunner: Node = null
	var bursts := 0                 # לבדיקות
	var recruits := 0
	var resupplied := 0
	var _cd := 1.5
	var _left := 0
	var _rate := 0.0
	var _reload := 0.0
	var _scan := 0.0
	var _flash := 0.0
	var _caller: Node = null

	func _ready() -> void:
		collision_layer = 1
		add_to_group("cover")
		add_to_group("mg_nests")
		add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = SIZE
		cs.shape = sh
		cs.position = Vector2(0, -SIZE.y * 0.5)
		add_child(cs)
		z_index = 2

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(-SIZE.x * 0.5, -SIZE.y), SIZE)

	func gun_spot() -> float:   # איפה התותחן עומד (מאחורי השקים)
		return global_position.x - face * (SIZE.x * 0.5 + 14.0)

	func muzzle() -> Vector2:
		return global_position + Vector2(face * (SIZE.x * 0.5 + 18.0), -SIZE.y - 6.0)

	func manned() -> bool:
		return is_instance_valid(gunner) and not gunner.dead and absf(gunner.global_position.x - gun_spot()) < 26.0

	func hit_by_bullet(p: Vector2, _n: Vector2, d: Vector2) -> void:
		preload("res://particles.gd").burst(get_parent(), p, "smoke", -d, 2)

	func refill(by: Node) -> void:   # LOADER הביא ארגז
		ammo = AMMO
		_reload = 0.0
		resupplied += 1
		if by != null:
			by._popup("AMMO!", Color("ffd060"), 13, -80.0)

	func needs_ammo() -> bool:
		return ammo <= 0

	func _physics_process(delta: float) -> void:
		_cd -= delta
		_rate -= delta
		_scan -= delta
		_flash = maxf(_flash - delta, 0.0)
		if _reload > 0.0:
			_reload -= delta
			if _reload <= 0.0:
				ammo = AMMO
		# מי מאייש?
		if _scan <= 0.0:
			_scan = 0.5
			if not is_instance_valid(gunner) or gunner.dead:
				gunner = null
			if gunner == null:
				_recruit()
			elif not manned() and gunner.goal_x == INF:
				gunner.goal_x = gun_spot()
		var pl := get_tree().get_first_node_in_group("player")
		if not manned() or pl == null or pl.dead:
			_left = 0
			queue_redraw()
			return
		gunner._dir = face
		if _left > 0:
			if _rate <= 0.0 and ammo > 0:
				_left -= 1
				ammo -= 1
				_rate = RATE
				_flash = 0.05
				var tgt: Vector2 = pl.global_position + Vector2(0, E.squad_aim_y(get_parent()))
				tgt.y += muzzle().distance_to(tgt) * randf_range(-0.06, 0.04)
				E.fire(gunner, muzzle(), tgt, 700.0)
				preload("res://sfx.gd").play("mb_mg", muzzle(), -3.0, 0.1, 4)
				if ammo <= 0:
					_left = 0
					_reload = RELOAD_T
					gunner._popup("NO AMMO!", Color("ffd060"), 13, -80.0)
		else:
			var d: Vector2 = pl.global_position - muzzle()
			if _cd <= 0.0 and ammo > 0 and signf(d.x) == face and absf(d.x) < RANGE and absf(d.y + 20.0) < 140.0 \
					and E.clear_shot(self, muzzle(), pl.global_position + Vector2(0, -24)):
				_left = BURST
				_cd = CD
				bursts += 1
		queue_redraw()

	func _recruit() -> void:
		var best: Node = null
		var bd := RECRUIT_R
		for z in get_tree().get_nodes_in_group("empire"):
			if z.dead or z.is_boss() or z.has_meta("manning") or absf(z.global_position.y - global_position.y) > 60.0:
				continue
			var dd: float = absf(z.global_position.x - gun_spot())
			if dd < bd:
				bd = dd
				best = z
		if best == null:
			return
		gunner = best
		gunner.set_meta("manning", self)
		gunner.goal_x = gun_spot()
		recruits += 1
		if recruits > 1:
			gunner._popup("MAN THE GUN!", Color("ff8060"), 13, -85.0)

	func _draw() -> void:
		var sb := Color("8a7a58")
		for row in 3:   # שקי חול
			var n := 5 - row
			var bw := SIZE.x / 5.0
			for q in n:
				var bx := -SIZE.x * 0.5 + float(row) * bw * 0.5 + float(q) * bw
				var by := -float(row + 1) * (SIZE.y / 3.0)
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(bx + bw * 0.5, by + 5.0), bw * 0.55, 5.5, 0.0, 10), sb.darkened(0.08 * float((q + row) % 2)))
		# המקלע על חצובה
		var m := Vector2(face * (SIZE.x * 0.5 + 18.0), -SIZE.y - 6.0)
		DrawBatch.line(self, Vector2(face * 6.0, -SIZE.y + 2.0), Vector2(face * 14.0, -SIZE.y - 6.0), Color("1a1a1a"), 3.0)
		DrawBatch.rect(self, Rect2(Vector2(minf(face * 4.0, face * 30.0), -SIZE.y - 10.0), Vector2(26.0, 7.0)), Color("2a2a2a"))
		DrawBatch.line(self, Vector2(face * 14.0, -SIZE.y - 6.5), m, Color("1a1a1a"), 3.0)
		DrawBatch.rect(self, Rect2(Vector2(face * 12.0 - 4.0, -SIZE.y - 4.0), Vector2(8.0, 6.0)), Color("4a4630"))   # תיבת תחמושת
		if _flash > 0.0:
			Art.glow(self, m + Vector2(face * 4.0, 0), 12.0, Color(1.0, 0.85, 0.4, 0.9))
		if _reload > 0.0:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-30, -SIZE.y - 30.0), "RELOAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.85, 0.4, 0.8))
		E.emblem(self, Vector2(0, -SIZE.y * 0.5), 7.0)


# ---- חוט מעידה ----
class Tripwire extends Node2D:
	const W := 70.0
	const FUSE := 0.55
	const BLAST_R := 100.0
	const DISARM_T := 1.0
	var state := 0                  # 0 = דרוך, 1 = נדלק, 2 = התפוצץ / פורק
	var blown := 0                  # לבדיקות
	var disarmed := false
	var _t := 0.0
	var _dis := 0.0
	var _body: StaticBody2D = null

	class Grenade extends StaticBody2D:
		var trap = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if trap != null and trap.state == 0:
				trap._trigger(0.05)

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")
		var g := Grenade.new()
		g.trap = self
		g.collision_layer = 4   # שכבת הזומבים: כדורים פוגעים בו, השחקן והזומבים עוברים דרכו
		g.collision_mask = 0
		g.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(8, 10)
		cs.shape = sh
		cs.position = Vector2(0, -5)
		g.add_child(cs)
		add_child(g)
		_body = g

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-10, -40), Vector2(W + 20.0, 40))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 0 and world_rect().grow(margin).has_point(p)

	func _trigger(fuse: float) -> void:
		state = 1
		_t = fuse
		preload("res://sfx.gd").play("mb_click", global_position, 0.0, 0.05, 2)

	func _physics_process(delta: float) -> void:
		if state == 2:
			return
		if state == 1:
			_t -= delta
			queue_redraw()
			if _t <= 0.0:
				state = 2
				blown += 1
				preload("res://explosion.gd").blast(get_parent(), global_position + Vector2(0, -12), BLAST_R, BLAST_R * 0.4, 45, 2, "hazard")
				queue_redraw()
			return
		var pl := get_tree().get_first_node_in_group("player")
		var on_wire := func(n: Node2D) -> bool:
			return n.is_on_floor() and n.global_position.x > global_position.x and n.global_position.x < global_position.x + W \
					and absf(n.global_position.y - global_position.y) < 8.0
		if pl != null and not pl.dead and on_wire.call(pl):
			if pl._crouching:   # מתכופף מעל החוט: מפרק בזהירות
				_dis += delta
				if _dis >= DISARM_T:
					state = 2
					disarmed = true
					pl._say("DISARMED.", Color(0.8, 1.0, 0.8))
					preload("res://sfx.gd").play("mb_click", global_position, -6.0, 0.05, 2)
					queue_redraw()
				return
			_trigger(FUSE)
			return
		_dis = maxf(_dis - delta, 0.0)
		if Engine.get_physics_frames() % 6 == 0:
			for z in get_tree().get_nodes_in_group("zombies"):
				if not z.dead and not z.is_in_group("empire") and not z.is_boss() and on_wire.call(z):   # האימפריה יודעת איפה החוטים
					_trigger(FUSE)
					return
		if Engine.get_physics_frames() % 30 == 0:
			queue_redraw()

	func _draw() -> void:
		if state == 2:
			if disarmed:
				DrawBatch.line(self, Vector2(0, -6), Vector2(W * 0.4, -2), Color(0.7, 0.7, 0.7, 0.6), 1.0)
			return
		DrawBatch.line(self, Vector2(0, -14), Vector2(0, 0), Color("4a3a24"), 2.0)   # יתדות
		DrawBatch.line(self, Vector2(W, -14), Vector2(W, 0), Color("4a3a24"), 2.0)
		var glint := fposmod(float(Engine.get_physics_frames()) / 60.0, 2.5) < 0.5
		DrawBatch.line(self, Vector2(0, -6), Vector2(W, -6), Color(0.9, 0.9, 0.95, 0.85 if glint else 0.35), 1.0)
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -7), 4.0, 5.0, 0.0, 10), Color("3a4a2a"))   # רימון
		DrawBatch.rect(self, Rect2(-1.5, -14, 3, 3), Color("8a8a80"))
		if state == 1:
			Art.glow(self, Vector2(0, -8), 8.0 + 6.0 * sin(_t * 40.0), Color(1.0, 0.3, 0.2, 0.7))


# ---- שלולית נפאלם ----
class FirePatch extends Node2D:
	const LIFE := 4.0
	const TICK := 0.5
	var w := 90.0
	var life := LIFE
	var delay := 0.0                # >0: מיכל נופל מלמעלה לפני שנדלק
	var burned := 0                 # לבדיקות
	var _tick := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-w * 0.5, -30), Vector2(w, 30))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		if delay > 0.0:
			delay -= delta
			if delay <= 0.0:
				preload("res://sfx.gd").play("mb_whoosh", global_position, 0.0, 0.1, 3)
			queue_redraw()
			return
		life -= delta
		_tick -= delta
		if life <= 0.0:
			queue_free()
			return
		if _tick <= 0.0:
			_tick = TICK
			var r := world_rect()
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and r.intersects(pl.body_rect()):
				burned += 1
				pl.hurt(1, Vector2(0, -0.5))
			for z in get_tree().get_nodes_in_group("zombies"):
				if not z.dead and not z.is_boss() and not z.has_meta("fireproof") and r.has_point(z.global_position + Vector2(0, -6)) and z.has_method("ignite"):
					z.ignite(2.0)
		if Engine.get_physics_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		if delay > 0.0:   # מיכל נפאלם נופל
			var y := -delay * 520.0
			DrawBatch.rect(self, Rect2(-4, y - 10, 8, 14), Color("6a3a1a"))
			DrawBatch.circle(self, Vector2(0, y + 6), 2.0 + sin(_t * 30.0), Color(1.0, 0.7, 0.2))
			DrawBatch.line(self, Vector2(-w * 0.5, -1), Vector2(w * 0.5, -1), Color(1.0, 0.4, 0.1, 0.4), 2.0)
			return
		var fade := clampf(life / 0.8, 0.0, 1.0)
		DrawBatch.rect(self, Rect2(-w * 0.5, -3, w, 3), Color(0.15, 0.08, 0.04, 0.8 * fade))
		for q in 9:
			var fx := -w * 0.5 + (float(q) + 0.5) * w / 9.0
			var fh := (14.0 + 10.0 * absf(sin(_t * 7.0 + float(q) * 1.7))) * fade
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(fx - 6.0, 0), Vector2(fx + 6.0, 0), Vector2(fx + sin(_t * 9.0 + float(q)) * 3.0, -fh)]), Color(1.0, 0.45 + 0.1 * float(q % 3), 0.1, 0.85 * fade))
		Art.glow(self, Vector2(0, -10), w * 0.6, Color(1.0, 0.5, 0.15, 0.12 * fade))


# ---- קיר שקי חול (PIONEER) ----
class Sandbags extends StaticBody2D:
	const HP := 10
	const BUILD_T := 2.0
	const SIZE := Vector2(56, 28)
	var hp := HP
	var max_hp := HP
	var steel := false              # PIONEER למד: לוחות פלדה (פי 2 HP)
	var built := 0.0                # 0..1
	var hits := 0                   # לבדיקות
	var _shape: CollisionShape2D = null

	func _ready() -> void:
		collision_layer = 0
		add_to_group("no_outline")
		add_to_group("blastable")
		add_to_group("sandbags")
		_shape = CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = SIZE
		_shape.shape = sh
		_shape.position = Vector2(0, -SIZE.y * 0.5)
		add_child(_shape)
		z_index = 2

	func done() -> bool:
		return built >= 1.0

	func build(amount: float) -> void:
		built = minf(built + amount, 1.0)
		if done() and collision_layer == 0:
			collision_layer = 1
			add_to_group("cover")
		queue_redraw()

	func repair(amount: int) -> void:
		hp = mini(hp + amount, max_hp)
		queue_redraw()

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(-SIZE.x * 0.5, -SIZE.y), SIZE)

	func blast_rect() -> Rect2:
		return cover_rect()

	func hit_by_bullet(p: Vector2, _n: Vector2, d: Vector2) -> void:
		if hp <= 0:
			return
		hits += 1
		hp -= 1
		preload("res://particles.gd").burst(get_parent(), p, "smoke", -d, 2)
		if hp <= 0:
			var m := get_parent()   # ה-PIONEERים לומדים: "קירות נופלים מירי" -> פלדה
			if m != null:
				m.set_meta("walls_lost", (int(m.get_meta("walls_lost")) if m.has_meta("walls_lost") else 0) + 1)
			_break()
		else:
			queue_redraw()

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		if hp > 0:
			hp = 0
			_break()

	func _break() -> void:
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -14), "smoke", Vector2.UP, 8)
		queue_free()

	func _draw() -> void:
		var rows := int(ceil(built * 3.0))
		var bw := SIZE.x / 4.0
		var dmg := 1.0 - float(hp) / float(max_hp)
		for row in rows:
			var n := 4 - (row % 2)
			for q in n:
				var bx := -SIZE.x * 0.5 + float(row % 2) * bw * 0.5 + float(q) * bw
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(bx + bw * 0.5, -float(row) * 9.0 - 5.0), bw * 0.55, 5.0, 0.0, 10), Color("8a7a58").darkened(0.06 * float((q + row) % 2) + dmg * 0.3))
		if steel and built > 0.6:   # לוח פלדה מלפנים
			DrawBatch.rect(self, Rect2(-SIZE.x * 0.5 - 2.0, -SIZE.y + 2.0, SIZE.x + 4.0, SIZE.y * 0.6), Color("5a5e66").darkened(dmg * 0.3))
			for q in 4:
				DrawBatch.circle(self, Vector2(-SIZE.x * 0.5 + 6.0 + float(q) * (SIZE.x - 12.0) / 3.0, -SIZE.y + 6.0), 1.2, Color("9a9ea6"))
		if not done():
			DrawBatch.rect(self, Rect2(-SIZE.x * 0.5, -SIZE.y, SIZE.x, SIZE.y), Color(1.0, 0.85, 0.4, 0.12))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "bunk"
	var size := Vector2(90, 50)
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
			"bunk":   # מיטת קומתיים מתקפלת על הצד
				DrawBatch.rect(self, Rect2(0, -h, 4, h), Color("4a4e56"))
				DrawBatch.rect(self, Rect2(w - 4, -h, 4, h), Color("4a4e56"))
				DrawBatch.rect(self, Rect2(0, -h * 0.55, w, 6), Color("4a4e56"))
				DrawBatch.rect(self, Rect2(2, -h * 0.55 - 6, w - 4, 6), Color("4a4636"))
				DrawBatch.rect(self, Rect2(0, -6, w, 6), Color("4a4e56"))
				DrawBatch.rect(self, Rect2(2, -12, w - 4, 6), Color("4a4636"))
				DrawBatch.rect(self, Rect2(4, -h * 0.55 - 10, 14, 4), Color("8a8676"))
			"footlocker":   # ארגז חייל
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, -h), Vector2(0, -h)]), Color("4a5236"), 0.15, 0.35, Art.OUTLINE, 1.2)
				DrawBatch.rect(self, Rect2(0, -h * 0.7, w, 3), Color("2a2e1e"))
				DrawBatch.rect(self, Rect2(w * 0.45, -h * 0.75, w * 0.1, h * 0.2), Color("b8a060"))
				E.emblem(self, Vector2(w * 0.5, -h * 0.35), h * 0.17)
			_:   # מתלה רובים
				DrawBatch.rect(self, Rect2(0, -h, w, 4), Color("3a3020"))
				DrawBatch.rect(self, Rect2(0, -6, w, 6), Color("3a3020"))
				for q in int(w / 9.0):
					DrawBatch.line(self, Vector2(5.0 + float(q) * 9.0, -h + 4.0), Vector2(3.0 + float(q) * 9.0, -6.0), Color("1a1814"), 2.4)
					DrawBatch.line(self, Vector2(5.0 + float(q) * 9.0, -h + 4.0), Vector2(5.0 + float(q) * 9.0, -h - 4.0), Color("1a1a1a"), 1.2)


# ---- אבק והבהוב (מסך) ----
class MetroFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		for i in 22:
			var x := fposmod(float(i) * 97.0 + sin(_t * 0.4 + float(i)) * 30.0 + _t * 6.0, vp.x)
			var y := fposmod(float(i) * 61.0 + sin(_t * 0.3 + float(i) * 2.0) * 20.0, vp.y * 0.85)
			DrawBatch.circle(self, Vector2(x, y), 1.2, Color(0.9, 0.92, 1.0, 0.25))
		var flick := fposmod(_t, 7.3) < 0.12 or fposmod(_t + 2.1, 11.7) < 0.08
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.0, 0.02, 0.05, 0.28 if flick else 0.1))
