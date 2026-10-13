extends RefCounted
# ============================================================
#  קישוטים לשלב 39 ("THE STADIUM") - המרקנה בלילה של משחק. אזור חמישי, שלב 3.
#  קערת יציעים ענקית מלאה בקהל זומבים שקופץ, גג טבעת לבן עם שורות זרקורים, זיקוקים (סינליזדורס) ועשן אדום-ירוק,
#  דגלים ענקיים, שלטי לד סביב המגרש, מסלול ריצה ודשא. בסוף - השער והשוער.
#    stadium_sky   - (רקע) לילה, הילת זרקורים לבנה, עשן צבעוני שנסחף, זיקוקים
#    far_stands    - (רקע) היציע שממול: גג טבעת, זרקורים, אלפי צופים קופצים (נקודות), דגלים, להבות סינליזדור
#    mid_boards    - (רקע) שלטי לד סביב המגרש שמתחלפים, צלמים, ספסלים
#    TrackGround   - (עולם) מסלול ריצה אדום עם קווים לבנים -> דשא מפוספס (מ-grass_from)
#    Stand         - (עולם) יציע קרוב: מדרגות מושבים, קהל זומבים, מעבר עליון (הקומה = add_floor)
#    CrowdThrow    - (עולם, מלכודת) הקהל ביציע: שריקות בוז (אזהרה) -> מטר כוסות, בקבוקים ונפצים עליך
#    Floodlight    - (עולם, מלכודת) מגדל זרקור שסורק את המסלול: נכנסת לאור -> כל הזומבים יודעים איפה אתה
#    Goal          - (עולם) השער (רשת + קורות) מאחורי השוער
#    Obstacle      - (מוצק + מחסה) "ad_board" שלט פרסומת נייד / "bench" ספסל מחליפים / "cooler" ארגזי שתייה
#    StadiumFX     - (מסך) קונפטי ונייר, הילה
#  לשנות: CrowdThrow.CD / WARN_T / N, Floodlight.SPEED / SPAN / ALERT_R.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const TEAM := [Color("e0d020"), Color("2a8a3a"), Color("e8e8e8"), Color("c02a2a"), Color("2a4ab0")]


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)


# ---- לילה עם הילת זרקורים ----
static func stadium_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("070a18"), Color("101a34"), Color("1e2a4a"), Color("3a4a6a")], 0.9)
	Art.glow(ci, Vector2(v.x * 0.5, v.y * 0.55), v.x * 0.6, Color(0.9, 0.95, 1.0, 0.12))
	for i in 5:   # עשן סינליזדורים שנסחף מעל
		var cx := fposmod(float(i) * 300.0 + t * 12.0, v.x + 400.0) - 200.0
		var c := Color(0.8, 0.2, 0.2, 0.12) if i % 2 == 0 else Color(0.2, 0.7, 0.3, 0.1)
		ci.draw_colored_polygon(Art.ellipse(Vector2(cx, v.y * (0.3 + 0.05 * float(i % 3))), 180.0, 40.0, 0.0, 14), c)
	var cyc := fposmod(t, 6.0)   # זיקוק
	if cyc < 1.2:
		var k := floori(t / 6.0)
		var c0 := Vector2(v.x * (0.2 + 0.6 * _h(k, 3)), v.y * (0.12 + 0.1 * _h(k, 4)))
		var col: Color = TEAM[k % TEAM.size()]
		for q in 14:
			var d := Vector2.from_angle(float(q) / 14.0 * TAU) * cyc * 60.0
			ci.draw_circle(c0 + d + Vector2(0, cyc * cyc * 10.0), 2.0, Color(col, 1.0 - cyc / 1.2))


# ---- היציע שממול ----
static func far_stands(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := y - 250.0
	ci.draw_rect(Rect2(0, top, v.x, y - top), Color("1a1e2e"))
	# גג טבעת לבן עם זרקורים
	ci.draw_rect(Rect2(0, top - 30.0, v.x, 22.0), Color("c8ccd8"))
	ci.draw_rect(Rect2(0, top - 8.0, v.x, 8.0), Color("8a8e9a"))
	var lx := -fposmod(sc * 0.3, 40.0)
	while lx < v.x:
		ci.draw_rect(Rect2(lx, top - 6.0, 26.0, 5.0), Color(1.0, 1.0, 0.95))
		lx += 40.0
	Art.glow(ci, Vector2(v.x * 0.5, top), v.x * 0.5, Color(1, 1, 1, 0.1))
	# הקהל: שורות של נקודות צבעוניות שקופצות
	var rows := 14
	for r in rows:
		var ry := top + 12.0 + float(r) * ((y - top - 20.0) / float(rows))
		var step := 7.0
		var x := -fposmod(sc * 0.3, step)
		var i := int(floor(sc * 0.3 / step))
		while x < v.x:
			var hsh := _h(i * 31 + r, 5)
			var jump := maxf(sin(t * 7.0 + float(i) * 0.9 + float(r)), 0.0) * 2.5 if hsh > 0.4 else 0.0
			var c: Color = TEAM[int(hsh * 10.0) % TEAM.size()].darkened(0.35 + 0.02 * float(rows - r))
			ci.draw_rect(Rect2(x, ry - jump, 4.0, 4.0), c)
			x += step
			i += 1
	var period := 700.0
	var start := int(floor(sc * 0.3 / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var fx := float(k) * period - sc * 0.3 + _h(k, 2) * 300.0
		var fy := top + 60.0 + _h(k, 6) * 80.0
		var fc: Color = TEAM[k % TEAM.size()]
		var w := sin(t * 2.0 + float(k)) * 6.0   # דגל ענק על הקהל
		ci.draw_colored_polygon(PackedVector2Array([Vector2(fx, fy), Vector2(fx + 120, fy + w), Vector2(fx + 118, fy + 50 - w), Vector2(fx - 2, fy + 50)]), Color(fc, 0.85))
		ci.draw_line(Vector2(fx + 10, fy + 25), Vector2(fx + 110, fy + 25), Color(1, 1, 1, 0.5), 3.0)
		var fl := Vector2(fx + 200.0, fy + 70.0)   # סינליזדור
		Art.glow(ci, fl, 30.0, Color(1.0, 0.3, 0.2, 0.5 + 0.2 * sin(t * 20.0 + float(k))))
		ci.draw_circle(fl, 3.0, Color(1.0, 0.85, 0.7))
	ci.draw_rect(Rect2(0, y - 6.0, v.x, v.y - y + 6.0), Color("2a3a2a"))


# ---- שלטי לד סביב המגרש ----
static func mid_boards(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	ci.draw_rect(Rect2(0, y - 34.0, v.x, 34.0), Color("101014"))
	var seg := 220.0
	var start := int(floor(sc / seg)) - 1
	for k in range(start, start + int(ceil(v.x / seg)) + 2):
		var x := float(k) * seg - sc
		var phase := int(t * 0.5 + float(k) * 0.3) % 3
		var c: Color = TEAM[(k + phase) % TEAM.size()]
		ci.draw_rect(Rect2(x + 2.0, y - 30.0, seg - 4.0, 24.0), c.darkened(0.45))
		var tx := fposmod(t * 80.0 + float(k) * 40.0, seg) - 40.0   # טקסט רץ
		for q in 4:
			ci.draw_rect(Rect2(x + tx + float(q) * 14.0, y - 24.0, 10.0, 12.0), Color(c.lightened(0.3), 0.9))
		if k % 3 == 1:   # צלם עם מצלמה
			var cx := x + 120.0
			ci.draw_rect(Rect2(cx, y - 64.0, 10.0, 30.0), Color("16161c"))
			ci.draw_circle(Vector2(cx + 5.0, y - 68.0), 5.0, Color("16161c"))
			ci.draw_rect(Rect2(cx + 8.0, y - 66.0, 18.0, 10.0), Color("16161c"))
			ci.draw_rect(Rect2(cx + 26.0, y - 64.0, 8.0, 6.0), Color("2a2a34"))
	ci.draw_rect(Rect2(0, y - 6.0, v.x, v.y - y + 6.0), Color("2a3a2a"))


# ---- מסלול ריצה ודשא ----
class TrackGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var grass := false

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		if grass:   # דשא מפוספס
			draw_rect(Rect2(0, 0, w, depth), Color("2a6a2a"))
			var x := 0.0
			var i := int(global_position.x / 80.0)
			while x < w:
				draw_rect(Rect2(x, 0, 80.0, depth), Color("327a32") if i % 2 == 0 else Color("2a6a2a"))
				x += 80.0
				i += 1
			draw_line(Vector2(0, 2), Vector2(w, 2), Color(0.95, 0.95, 0.95, 0.8), 2.0)
			for q in int(w / 12.0):
				draw_line(Vector2(float(q) * 12.0, 0), Vector2(float(q) * 12.0 + 2.0, -4.0), Color("3a8a3a"), 1.0)
			return
		draw_rect(Rect2(0, 0, w, depth), Color("a83a2a"))   # טרטן
		for q in 4:
			draw_line(Vector2(0, 4.0 + float(q) * 9.0), Vector2(w, 4.0 + float(q) * 9.0), Color(1, 1, 1, 0.55), 1.2)
		draw_rect(Rect2(0, 0, w, 2.0), Color("d0d0d0"))


# ---- יציע קרוב עם קהל + המעבר העליון ----
class Stand extends Node2D:
	var w := 420.0
	var tier := 130.0
	var _t := 0.0
	var angry := 0.0                # (CrowdThrow) כמה הקהל כועס - קמים ומנופפים

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w):
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s39_decor.gd")
		# מדרגות בטון עם כיסאות פלסטיק צבעוניים
		var rows := 6
		for rr in rows:   # מלמעלה למטה - כל שורה מכסה רק את הרגליים של השורה שמעליה
			var r := rows - 1 - rr
			var ry := -tier - 20.0 - float(r) * 22.0
			draw_rect(Rect2(-10, ry, w + 20, 22), Color("3a3a44").lightened(0.03 * float(r)))
			var x := 6.0
			var i := 0
			while x < w - 8.0:
				var c: Color = S.TEAM[(i + r) % 2 * 1 + (0 if r % 3 == 0 else 2)]
				draw_rect(Rect2(x, ry + 6, 10, 8), c.darkened(0.25))
				# צופה זומבי (לא בכל כיסא)
				if S._h(i * 7 + r, 3) < 0.6:
					var up := angry * (6.0 + 3.0 * sin(_t * 12.0 + float(i)))
					var bob := maxf(sin(_t * 6.0 + float(i) * 0.8 + float(r)), 0.0) * 2.0
					var sk := Color("7a8a70").darkened(S._h(i, r) * 0.3)
					var shirt: Color = S.TEAM[int(S._h(i, r + 9) * 10.0) % S.TEAM.size()]
					draw_rect(Rect2(x + 1, ry - 6 - bob - up * 0.4, 8, 10), shirt.darkened(0.2))
					draw_circle(Vector2(x + 5, ry - 9 - bob - up * 0.4), 3.5, sk)
					if angry > 0.2:   # ידיים למעלה
						draw_line(Vector2(x + 1, ry - 4 - bob), Vector2(x - 2, ry - 12 - up), sk, 1.5)
						draw_line(Vector2(x + 9, ry - 4 - bob), Vector2(x + 12, ry - 12 - up), sk, 1.5)
				x += 14.0
				i += 1
		# קיר היציע (מתחת למעבר) + שלט
		draw_rect(Rect2(-10, -tier, w + 20, tier), Color("2a2a34"))
		draw_rect(Rect2(20, -tier + 30, w - 40, 26), Color("1a1a22"))
		for q in 5:
			draw_rect(Rect2(30.0 + float(q) * (w - 60.0) / 5.0, -tier + 36, (w - 80.0) / 5.0, 14), S.TEAM[q].darkened(0.3))
		draw_rect(Rect2(w * 0.4, -70, 60, 70), Color("101016"))   # מנהרה
		draw_rect(Rect2(-10, -tier - 4, w + 20, 6), Color("8a8a94"))   # מעקה המעבר
		for q in int(w / 24.0) + 1:
			draw_line(Vector2(-8.0 + float(q) * 24.0, -tier - 4), Vector2(-8.0 + float(q) * 24.0, -tier - 18), Color("8a8a94"), 1.5)
		draw_line(Vector2(-10, -tier - 18), Vector2(w + 10, -tier - 18), Color("9a9aa4"), 2.0)


# ---- הקהל זורק עליך ----
class CrowdThrow extends Node2D:
	const CD := Vector2(6.0, 9.0)
	const WARN_T := 1.0
	const N := 10
	const SPREAD := 90.0
	var stand: Node2D = null
	var w := 420.0
	var barrages := 0               # לבדיקות
	var hits := 0
	var _t := 3.0
	var _warn := 0.0
	var _items := []                # [מיקום, מהירות, סוג, חי, פגע]
	var _hit := false

	func _ready() -> void:
		z_index = 9
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -60), Vector2(w, 60))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _warn > 0.0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t -= delta
		var pl := get_tree().get_first_node_in_group("player")
		var in_front: bool = pl != null and not pl.dead and pl.global_position.x > global_position.x - 60.0 and pl.global_position.x < global_position.x + w + 60.0 and absf(pl.global_position.y - global_position.y) < 40.0
		if _warn > 0.0:
			_warn -= delta
			if stand != null:
				stand.angry = minf(stand.angry + delta * 3.0, 1.0)
			if _warn <= 0.0 and pl != null:
				barrages += 1
				_hit = false
				preload("res://sfx.gd").play("st_throw", pl.global_position, 0.0, 0.1, 2)
				for q in N:   # זורקים לאן שאתה הולך
					var tx: float = pl.global_position.x + pl.velocity.x * 0.6 + randf_range(-SPREAD, SPREAD)
					var from := Vector2(clampf(tx + randf_range(-80, 80), global_position.x, global_position.x + w), global_position.y - 160.0 - randf() * 60.0)
					var fl := randf_range(0.7, 1.1)
					_items.append([from, Vector2((tx - from.x) / fl, (global_position.y - from.y) / fl - 0.5 * 700.0 * fl), q % 3, true, false])
		elif _t <= 0.0 and in_front:
			_warn = WARN_T
			_t = randf_range(CD.x, CD.y)
			preload("res://sfx.gd").play("st_boo", global_position + Vector2(w * 0.5, -150), 2.0, 0.05, 2)
		elif stand != null:
			stand.angry = maxf(stand.angry - delta, 0.0)
		for it in _items:
			if not bool(it[3]):
				continue
			it[1] = it[1] + Vector2(0, 700.0 * delta)
			it[0] = it[0] + it[1] * delta
			var p: Vector2 = it[0]
			if not _hit and pl != null and not pl.dead and pl.body_rect().grow(4.0).has_point(p):
				_hit = true
				hits += 1
				pl.hurt(1, Vector2(signf(float(it[1].x)) * 0.6, -0.4))
			if p.y >= global_position.y - 2.0:
				it[3] = false
				for zz in get_tree().get_nodes_in_group("zombies"):
					if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - p.x) < 14.0 and absf(zz.global_position.y - p.y) < 30.0:
						zz.take_damage(4, zz.global_position + Vector2(0, -40), Vector2(0, 1), false, {"source": "crowd", "fixed": 4})
				if int(it[2]) == 2:
					preload("res://particles.gd").burst(get_parent(), p, "fire", Vector2.UP, 4)
		if _items.size() > 0 and _items.all(func(it): return not bool(it[3])):
			_items.clear()
		if _items.size() > 0 or _warn > 0.0:
			queue_redraw()
		elif Engine.get_physics_frames() % 20 == 0:
			queue_redraw()

	func _draw() -> void:
		if _warn > 0.0:   # "!!!" מעל היציע
			for q in 3:
				var x := w * (0.25 + 0.25 * float(q))
				draw_string(ThemeDB.fallback_font, Vector2(x, -190.0 - 6.0 * sin(_warn * 20.0 + float(q))), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color(1.0, 0.3, 0.2))
		for it in _items:
			if not bool(it[3]):
				continue
			var p: Vector2 = it[0] - global_position
			match int(it[2]):
				0:   # כוס בירה
					draw_rect(Rect2(p - Vector2(3, 4), Vector2(6, 8)), Color(0.95, 0.95, 0.95))
					draw_rect(Rect2(p - Vector2(3, 4), Vector2(6, 3)), Color(1.0, 0.85, 0.3))
				1:   # בקבוק
					draw_line(p - Vector2(0, 6), p + Vector2(0, 6), Color(0.3, 0.6, 0.3), 3.0)
				_:   # נפץ / סינליזדור
					draw_circle(p, 3.0, Color(1.0, 0.4, 0.2))
					Art.glow(self, p, 8.0, Color(1.0, 0.4, 0.2, 0.5))


# ---- מגדל זרקור שסורק ----
class Floodlight extends Node2D:
	const SPEED := 0.35
	const SPAN := 520.0
	const ALERT_R := 900.0
	const HEIGHT := 330.0
	var spotted := 0                # לבדיקות
	var _t := 0.0
	var _cd := 0.0
	var _phase := 0.0

	func _ready() -> void:
		z_index = -1
		_phase = randf() * TAU

	func beam_x() -> float:
		return global_position.x + sin(_t * SPEED * TAU * 0.25 + _phase) * SPAN

	func _physics_process(delta: float) -> void:
		_t += delta
		_cd -= delta
		var pl := get_tree().get_first_node_in_group("player")
		if _cd <= 0.0 and pl != null and not pl.dead and absf(pl.global_position.x - beam_x()) < 40.0 and pl.global_position.y > global_position.y - 260.0:
			_cd = 4.0
			spotted += 1
			preload("res://sfx.gd").play("st_spot", pl.global_position, 0.0, 0.05, 2)
			pl._say("THE LIGHT FOUND ME!", Color("fff4c0"))
			for zz in get_tree().get_nodes_in_group("zombies"):
				if not zz.dead and not zz.is_boss() and zz.global_position.distance_to(pl.global_position) < ALERT_R:
					zz._alert_t = maxf(float(zz._alert_t), 6.0)
					zz._rush_t = 2.0
					if zz.dormant:
						zz._wake()
		if Art.on_screen(self, Vector2(beam_x(), global_position.y - 100.0), SPAN):
			queue_redraw()

	func _draw() -> void:
		var top := Vector2(0, -HEIGHT)
		draw_line(Vector2(-8, 0), top + Vector2(-4, 10), Color("4a4a54"), 4.0)   # המגדל
		draw_line(Vector2(8, 0), top + Vector2(4, 10), Color("4a4a54"), 4.0)
		for q in 8:
			var y := -float(q) * HEIGHT / 8.0
			draw_line(Vector2(-7, y), Vector2(7, y - HEIGHT / 8.0), Color("4a4a54"), 1.0)
		draw_rect(Rect2(top + Vector2(-26, -14), Vector2(52, 20)), Color("2a2a34"))
		for q in 4:
			draw_circle(top + Vector2(-18.0 + float(q) * 12.0, -4.0), 4.5, Color(1.0, 1.0, 0.9))
		var bx := beam_x() - global_position.x
		var spot := _cd > 3.0
		draw_colored_polygon(PackedVector2Array([top + Vector2(-14, 0), top + Vector2(14, 0), Vector2(bx + 50.0, 0), Vector2(bx - 50.0, 0)]), Color(1.0, 0.98, 0.85, 0.12 if not spot else 0.25))
		draw_colored_polygon(Art.ellipse(Vector2(bx, -2), 52.0, 7.0, 0.0, 16), Color(1.0, 0.98, 0.85, 0.3 if not spot else 0.55))


# ---- השער ----
class Goal extends Node2D:
	var w := 220.0
	var h := 150.0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		for q in int(w / 12.0) + 1:   # רשת
			draw_line(Vector2(float(q) * 12.0, -h), Vector2(float(q) * 12.0 + 20.0, 0), Color(1, 1, 1, 0.25), 1.0)
		for q in int(h / 12.0) + 1:
			draw_line(Vector2(0, -float(q) * 12.0), Vector2(w + 20.0, -float(q) * 12.0 + 6.0), Color(1, 1, 1, 0.25), 1.0)
		draw_rect(Rect2(-4, -h - 4, w + 8, 6), Color("f0f0f0"))   # משקוף
		draw_rect(Rect2(-4, -h, 6, h), Color("f0f0f0"))   # קורות
		draw_rect(Rect2(w - 2, -h, 6, h), Color("f0f0f0"))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "ad_board"
	var size := Vector2(110, 40)
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
		var w := size.x
		var h := size.y
		var S := preload("res://effects/s39_decor.gd")
		match kind:
			"ad_board":   # שלט פרסומת נייד (משולש)
				var c: Color = S.TEAM[r.randi() % S.TEAM.size()]
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 4, -h), Vector2(4, -h)]), c.darkened(0.2), 0.15, 0.35, Art.OUTLINE, 1.2)
				draw_rect(Rect2(10, -h * 0.65, w * 0.6, h * 0.3), Color(1, 1, 1, 0.8))
				draw_circle(Vector2(w * 0.82, -h * 0.5), h * 0.22, Color(1, 1, 1, 0.8))
			"bench":   # ספסל מחליפים עם גג פרספקס
				draw_rect(Rect2(4, -h * 0.35, w - 8, h * 0.12), Color("2a4ab0"))
				for q in 4:
					draw_rect(Rect2(10.0 + float(q) * (w - 20.0) / 4.0, -h * 0.55, (w - 30.0) / 4.0, h * 0.2), Color("2a4ab0").lightened(0.15))
				draw_line(Vector2(4, 0), Vector2(4, -h), Color("8a8a94"), 3.0)
				draw_line(Vector2(w - 4, 0), Vector2(w - 4, -h), Color("8a8a94"), 3.0)
				draw_colored_polygon(PackedVector2Array([Vector2(0, -h), Vector2(w, -h), Vector2(w - 6, -h + 8), Vector2(6, -h + 8)]), Color(0.7, 0.85, 1.0, 0.45))
			_:   # ארגזי שתייה
				for q in 2:
					Art.fill(self, PackedVector2Array([Vector2(2.0 + float(q) * w * 0.5, 0), Vector2(w * 0.5 - 2.0 + float(q) * w * 0.5, 0), Vector2(w * 0.5 - 2.0 + float(q) * w * 0.5, -h * (0.8 + 0.2 * float(q))), Vector2(2.0 + float(q) * w * 0.5, -h * (0.8 + 0.2 * float(q)))]), Color("e04020") if q == 0 else Color("2a8ad0"), Art.OUTLINE, 1.0)
					draw_rect(Rect2(6.0 + float(q) * w * 0.5, -h * 0.55, w * 0.5 - 12.0, 5), Color(1, 1, 1, 0.8))


# ---- קונפטי ונייר על המסך ----
class StadiumFX extends Node2D:
	var vp := Vector2(1280, 720)
	var floor_y := 630.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s39_decor.gd")
		var gy: float = (get_viewport().get_canvas_transform() * Vector2(0, floor_y)).y
		for i in 26:
			var x := fposmod(float(i) * 89.0 + sin(_t + float(i)) * 30.0 + _t * 10.0, vp.x)
			var y := fposmod(float(i) * 53.0 + _t * (40.0 + float(i % 4) * 10.0), maxf(gy, 10.0))
			var c: Color = S.TEAM[i % S.TEAM.size()]
			draw_rect(Rect2(x, y, 4.0, 2.5), Color(c, 0.75))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.9, 0.95, 1.0, 0.03))
