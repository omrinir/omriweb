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
#    EmperorBalloon  - (עולם) בלון מצעד ענק (גולגולת הקיסר עם כתר) על 3 חבלים, מחזיקים צועדים מתחת. מפיל פצצות (טבעת אדומה
#                      מסמנת איפה תנחת), לומד להקדים אותך. לפוצץ אותו -> מתרסק על מי שמתחת. להרוג 2 מחזיקים -> עף לשמיים.
#    HonorGuard      - (עולם) משמר כבוד על פודיום: סמל + 3 רובאים. מטח הצדעה לשמיים - עד שהם לומדים לכוון עליך.
#    Obstacle        - (מוצק + מחסה) "crowd_barrier" מחסום קהל / "planter" עציץ בטון עם פרחים אדומים / "drum_stack" תופים
#    ParadeFX        - (מסך) נייר טיקר אדום-לבן שנופל, אובך זרקורים
#  לשנות: EmperorBalloon (HP, BOMB_CD, BOMB_R, ROAM, CRASH_R), HonorGuard (VOLLEY_CD, READY_T, LOCK_T, NOTICE_R, SERGEANT_HP).
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


# ---- בלון המצעד של הקיסר ----
#  בלון ענק בצורת גולגולת הקיסר עם כתר, קשור ב-3 חבלים ל-3 חיילים שצועדים מתחתיו (handlers, זומבים אמיתיים).
#  הבלון עוקב אחריך לאורך השדרה (ROAM) ומפיל פצצות (BOMB_CD) - טבעת אדומה על הקרקע מראה איפה כל פצצה תנחת.
#  "THEY LEARNED YOUR STEP": זוכר לאן ברחת מהפצצה. התחמקות 1 -> זוג פצצות: עליך + איפה שברחת אליו בפעם הקודמת.
#    התחמקות 2 -> מניפה של 3 (עליך + שני הצדדים). הטבעות האדומות מראות את כל הנקודות - לחפש את הרווח.
#  להפיל אותו: HP פגיעות בבלון -> מתרוקן, מסתחרר ומתרסק על מי שמתחת (CRASH_R - גם חיילים!).
#  או להרוג 2 מהמחזיקים -> הבלון משתחרר ועף לשמיים (אין יותר פצצות). פצצה שנופלת ליד המחזיקים - הורגת גם אותם.
class EmperorBalloon extends Node2D:
	const HEIGHT := 255.0
	const R := Vector2(74, 62)
	const ROAM := 520.0
	const SPEED := 60.0
	const ROPE_MAX := 260.0         # הבלון לא מתרחק מהמחזיקים יותר מזה (חבלים ארוכים)
	const BOMB_CD := Vector2(2.6, 3.6)
	const BOMB_R := 95.0
	const BOMB_GRAV := 700.0
	const HP := 16
	const CRASH_R := 170.0
	const CRASH_DMG := 60
	const OFFS := [140.0, 190.0, 240.0]   # המחזיקים הולכים מאחורי הבלון (בצד הרחוק ממך) - הבלון מעליך, הם רחוק מהפצצות
	enum { FLY, FREE, FALL, DOWN }
	var state := FLY
	var floor_y := 630.0
	var home_x := 0.0
	var hp := HP
	var handlers := []
	var bombs := 0                  # לבדיקות
	var bomb_hits := 0
	var misses := 0
	var lead := 0.0                 # 0..1 - כמה הוא למד להקדים
	var dodge := 0.0                # לאן ברחת בפעם האחרונה (פיקסלים, + ימינה)
	var crushed := 0
	var _vx := 0.0
	var _cd := 2.5
	var _t := 0.0
	var _st := 0.0
	var _hit := 0.0
	var _vy := 0.0
	var _spin := 0.0
	var _body: StaticBody2D = null
	var _side := 1.0                # באיזה צד של הבלון המחזיקים

	func _ready() -> void:
		z_index = 8
		home_x = global_position.x
		floor_y = global_position.y + HEIGHT
		add_to_group("balloons")
		_body = BalloonBody.new()
		_body.b = self
		add_child(_body)

	func alive_handlers() -> Array:
		return handlers.filter(func(h): return is_instance_valid(h) and not h.dead)

	func hit(amount: int, at: Vector2) -> void:
		if state != FLY and state != FREE:
			return
		hp -= maxi(1, int(round(float(amount) / 12.0)))
		_hit = 0.08
		preload("res://particles.gd").burst(get_parent(), at, "spark", Vector2.UP, 2)
		if hp <= 0:
			_pop()

	func _pop() -> void:
		state = FALL
		_vy = -60.0
		_body.collision_layer = 0
		preload("res://sfx.gd").play("bl_pop", global_position, 3.0, 0.05, 2)
		_text("THE BALLOON IS COMING DOWN!", Color("ffe0a0"))
		_release()

	func _release() -> void:
		for h in handlers:
			if is_instance_valid(h):
				h.goal_x = INF
		handlers.clear()

	func _text(s: String, col: Color) -> void:
		var p = preload("res://zombie.gd").HitText.new()
		p.text = s
		p.color = col
		p.size = 15
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(0, R.y + 30.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		_hit -= delta
		_cd -= delta
		var pl := get_tree().get_first_node_in_group("player")
		match state:
			FLY:
				var hs := alive_handlers()
				if hs.size() < 2:   # אין מספיק מחזיקים - משתחרר
					state = FREE
					_st = 0.0
					_release()
					preload("res://sfx.gd").play("bl_whoosh", global_position, 0.0, 0.05, 2)
					_text("THE BALLOON BROKE FREE", Color("ffe0a0"))
				else:
					var tx := home_x
					if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < 900.0:
						tx = clampf(pl.global_position.x + pl.velocity.x * 0.6 * lead, home_x - ROAM, home_x + ROAM)
					var hx := 0.0
					for h in hs:
						hx += h.global_position.x
					hx /= float(hs.size())
					tx = clampf(tx, hx - ROPE_MAX, hx + ROPE_MAX)   # החבלים מחזיקים
					_vx = move_toward(_vx, clampf((tx - global_position.x) * 1.5, -SPEED, SPEED), 80.0 * delta)
					global_position.x += _vx * delta
					global_position.y = floor_y - HEIGHT + sin(_t * 1.3) * 6.0
					if pl != null and absf(pl.global_position.x - global_position.x) > 40.0:
						_side = -signf(pl.global_position.x - global_position.x)
					for i in handlers.size():   # המחזיקים צועדים מאחורי הבלון
						var h = handlers[i]
						if is_instance_valid(h) and not h.dead:
							h.goal_x = global_position.x + _side * float(OFFS[i % OFFS.size()])
					if _cd <= 0.0 and pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < 320.0 and absf(pl.global_position.y - floor_y) < 200.0:
						_cd = randf_range(BOMB_CD.x, BOMB_CD.y)
						_drop(pl)
			FREE:   # עף לשמיים
				_st += delta
				global_position += Vector2(30.0, -70.0) * delta
				if _st > 6.0:
					queue_free()
					return
			FALL:   # מתרוקן, מסתחרר ונופל
				_vy += 320.0 * delta
				_spin += delta * 9.0
				global_position += Vector2(sin(_t * 7.0) * 90.0, _vy) * delta
				if global_position.y + R.y * 0.5 >= floor_y:
					_crash()
			DOWN:
				_st += delta
				if _st > 3.0:
					queue_free()
					return
		if Art.on_screen(self, Vector2(global_position.x, floor_y - HEIGHT * 0.5), 400.0):
			queue_redraw()

	func _drop(pl: Node) -> void:
		bombs += 1
		var from := global_position + Vector2(0, R.y + 14.0)
		var land_y: float = minf(pl.global_position.y, floor_y)   # נוחתת בגובה שלך (כביש / מעבר היציע)
		var fall := sqrt(2.0 * maxf(land_y - from.y, 10.0) / BOMB_GRAV)
		var tx: float = pl.global_position.x + pl.velocity.x * fall * 0.5
		var targets := [tx]
		var off := signf(dodge) * clampf(absf(dodge), 110.0, 200.0) if dodge != 0.0 else 0.0
		if misses >= 1 and off != 0.0:   # איפה שברחת אליו בפעם שעברה
			targets.append(tx + off)
		if misses >= 2 and off != 0.0:   # ושני הצדדים
			targets.append(tx - off)
		var hs := alive_handlers()
		for i in range(targets.size() - 1, 0, -1):   # פצצות נוספות לא נופלות על המחזיקים שלו (רק הפצצה עליך אפשר "למשוך" אליהם)
			for h in hs:
				if absf(float(targets[i]) - h.global_position.x) < 110.0:
					targets.remove_at(i)
					break
		for i in targets.size():
			var b := Bomb.new()
			b.balloon = self
			b.main_bomb = i == 0
			b.vel = Vector2(clampf((float(targets[i]) - from.x) / fall, -320.0, 320.0), 0.0)
			b.floor_y = land_y
			b.aim_x = pl.global_position.x
			get_parent().add_child(b)
			b.global_position = from + Vector2(float(i) * 4.0, 0)
		preload("res://sfx.gd").play("bl_drop", from, -2.0, 0.1, 3)

	func bomb_result(hit_player: bool, moved_by: float) -> void:
		if hit_player:
			bomb_hits += 1
		elif absf(moved_by) > 60.0:   # זזת והתחמקת -> זוכר לאן
			misses += 1
			dodge = moved_by
			lead = minf(lead + 0.5, 1.0)
			if misses == 1:
				_text("THEY AIM WHERE YOU WILL BE", Color("ffb0a0"))
			elif misses == 2:
				_text("THEY COVER BOTH SIDES", Color("ffb0a0"))

	func _crash() -> void:
		state = DOWN
		_st = 0.0
		global_position.y = floor_y - R.y * 0.35
		var c := Vector2(global_position.x, floor_y)
		preload("res://sfx.gd").play("bl_crash", c, 3.0, 0.05, 2)
		preload("res://particles.gd").burst(get_parent(), c + Vector2(0, -10), "smoke", Vector2.UP, 14)
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(8.0, 0.4)
		for zz in get_tree().get_nodes_in_group("zombies"):
			if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - c.x) < CRASH_R and absf(zz.global_position.y - c.y) < 80.0:
				crushed += 1
				zz.take_damage(CRASH_DMG, zz.global_position + Vector2(0, -30), Vector2(signf(zz.global_position.x - c.x), -0.5), true, {"source": "crash", "fixed": CRASH_DMG})
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and absf(pl.global_position.x - c.x) < CRASH_R * 0.7 and absf(pl.global_position.y - c.y) < 80.0:
			pl.hurt(1, Vector2(signf(pl.global_position.x - c.x) * 2.0, -1.0))
		if crushed > 0:
			_text("CRUSHED %d" % crushed, Color("ffe060"))

	func _draw() -> void:
		var S := preload("res://effects/s41_decor.gd")
		var gy := floor_y - global_position.y
		# צל על הכביש
		if state == FLY or state == FALL:
			var k := clampf(1.0 - (gy - R.y) / (HEIGHT + 40.0), 0.25, 1.0)
			draw_colored_polygon(Art.ellipse(Vector2(0, gy - 1.0), R.x * 0.9 * k + 20.0, 6.0, 0.0, 16), Color(0, 0, 0, 0.25))
		# חבלים
		if state == FLY:
			for h in alive_handlers():
				var hp_: Vector2 = h.global_position - global_position + Vector2(h._dir * 6.0, -42.0)
				var mid := (Vector2(0, R.y * 0.8) + hp_) * 0.5 + Vector2(0, 14)
				draw_polyline(PackedVector2Array([Vector2(0, R.y * 0.8), mid, hp_]), Color("d8d0b8"), 1.5)
		var sq := 1.0
		var flat := 1.0
		var rot := 0.0
		if state == FALL:
			sq = 0.75 + 0.1 * sin(_t * 30.0)
			rot = sin(_spin) * 0.5
		elif state == DOWN:
			flat = 0.35
		draw_set_transform(Vector2.ZERO, rot, Vector2(sq, sq * flat))
		var white := Color("e8e2d0") if _hit <= 0.0 else Color.WHITE
		# גוף הבלון: גולגולת
		Art.oval_shaded(self, Vector2.ZERO, R.x, R.y, white, 0.0, Color("3a3428"), 2.5)
		for q in 5:   # תפרים של הבלון
			var xx := -R.x * 0.7 + float(q) * R.x * 0.35
			draw_arc(Vector2(xx * 0.15, 0), R.y * 0.95, -1.9 + float(q) * 0.05, -1.25 + float(q) * 0.1, 8, Color(0, 0, 0, 0.08), 1.5)
		draw_colored_polygon(Art.ellipse(Vector2(-24, -4), 16.0, 18.0, 0.2, 12), Color("2a2420"))   # ארובות עיניים
		draw_colored_polygon(Art.ellipse(Vector2(24, -4), 16.0, 18.0, -0.2, 12), Color("2a2420"))
		if state == FLY or state == FREE:
			var glow := 0.6 + 0.4 * sin(_t * 4.0)
			draw_circle(Vector2(-24, -2), 5.0, Color(1.0, 0.2, 0.15, glow))
			draw_circle(Vector2(24, -2), 5.0, Color(1.0, 0.2, 0.15, glow))
		draw_colored_polygon(PackedVector2Array([Vector2(0, 12), Vector2(-7, 26), Vector2(7, 26)]), Color("2a2420"))   # אף
		for q in 6:   # שיניים
			draw_rect(Rect2(Vector2(-27.0 + float(q) * 9.0, 36), Vector2(7, 12)), Color("f4eee0"))
			draw_rect(Rect2(Vector2(-27.0 + float(q) * 9.0, 36), Vector2(7, 12)), Color("3a3428"), false, 1.0)
		# כתר
		var crown := PackedVector2Array([Vector2(-46, -R.y + 12), Vector2(-50, -R.y - 22), Vector2(-28, -R.y - 6), Vector2(0, -R.y - 30), Vector2(28, -R.y - 6), Vector2(50, -R.y - 22), Vector2(46, -R.y + 12)])
		draw_colored_polygon(crown, S.E.BRASS)
		draw_polyline(crown, Color("8a6a20"), 2.0)
		for jx in [-50.0, 0.0, 50.0]:
			draw_circle(Vector2(jx, -R.y - (30.0 if jx == 0.0 else 22.0)), 4.5, S.E.RED)
		# סרט אדום עם הסמל
		draw_colored_polygon(PackedVector2Array([Vector2(-R.x * 0.95, 18), Vector2(-R.x * 0.7, 30), Vector2(-40, 34), Vector2(-46, 20)]), S.E.RED)
		draw_colored_polygon(PackedVector2Array([Vector2(R.x * 0.95, 18), Vector2(R.x * 0.7, 30), Vector2(40, 34), Vector2(46, 20)]), S.E.RED)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		if state == FLY:   # תא הפצצות מתחת לסנטר
			draw_rect(Rect2(Vector2(-12, R.y + 2), Vector2(24, 12)), Color("3a3e34"))
			S.E.emblem(self, Vector2(0, R.y + 8), 5.0)


# אזור הפגיעה של הבלון
class BalloonBody extends StaticBody2D:
	var b: Node2D

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = 62.0
		cs.shape = sh
		add_child(cs)

	func take_damage(amount: int, hit_pos: Vector2, _dir: Vector2, _explosive := false, src := {}) -> void:
		b.hit(int(src.get("fixed", amount)), hit_pos)


# פצצה מהבלון: נופלת, טבעת אדומה על הקרקע מראה איפה תנחת
class Bomb extends Node2D:
	var balloon: Node2D = null
	var vel := Vector2.ZERO
	var floor_y := 630.0
	var aim_x := 0.0                # איפה היית כשהיא נזרקה
	var main_bomb := true           # (רק הפצצה הראשית מדווחת לבלון אם התחמקת)
	var land_x := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 9
		var fall := sqrt(2.0 * maxf(floor_y - global_position.y, 1.0) / 700.0)
		land_x = global_position.x + vel.x * fall

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t < 0.02:
			var fall := sqrt(2.0 * maxf(floor_y - global_position.y, 1.0) / 700.0)
			land_x = global_position.x + vel.x * fall
		vel.y += 700.0 * delta
		var to := global_position + vel * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))   # (עוברת דרך במות one-way - נוחתת בגובה שלך)
		if not hit.is_empty() or to.y >= floor_y or _t > 4.0:
			var at: Vector2 = hit.position if not hit.is_empty() else Vector2(to.x, minf(to.y, floor_y))
			var pl := get_tree().get_first_node_in_group("player")
			var hp0: int = pl.health if pl != null else 0
			preload("res://explosion.gd").blast(get_parent(), at + Vector2(0, -6), 95.0, 50.0, 30, 1, "bomb")
			if balloon != null and is_instance_valid(balloon) and pl != null:
				if pl.health < hp0:
					balloon.bomb_result(true, 0.0)
				elif main_bomb:
					balloon.bomb_result(false, pl.global_position.x - aim_x)
			queue_free()
			return
		global_position = to
		rotation += delta * 3.0
		queue_redraw()

	func _draw() -> void:
		# טבעת על הקרקע (בעולם, לא מסתובבת)
		var gp := Vector2(land_x, floor_y) - global_position
		draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
		var k := clampf(_t / 0.8, 0.0, 1.0)
		draw_arc(gp.rotated(-rotation * 0.0), 40.0 - 22.0 * k, 0.0, TAU, 24, Color(1.0, 0.15, 0.1, 0.85), 2.5)
		draw_colored_polygon(Art.ellipse(gp, 34.0 - 18.0 * k, 5.0, 0.0, 14), Color(1.0, 0.15, 0.1, 0.25))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		draw_circle(Vector2.ZERO, 7.0, Color("1e1e22"))
		draw_rect(Rect2(Vector2(-3, -11), Vector2(6, 5)), Color("3a3e34"))
		draw_circle(Vector2(-2.5, -2.5), 2.0, Color(1, 1, 1, 0.3))


# ---- משמר כבוד: מטח הצדעה ----
#  פודיום עם סמל (SERGEANT, חרב מורמת) ושלושה רובאים בטקס (טוניקה אדומה, קסדת נוצה). כל VOLLEY_CD:
#  "PRESENT... FIRE!" - מטח הצדעה לשמיים (סרק, לא מסוכן).
#  "THEY LEARNED TO AIM": מתקרבים אליהם (NOTICE_R) / יורים לידם / פוגעים באחד מהם -> הסמל מסובב אותם אליך:
#    "AIM!" - קווי כוונה אדומים בגובה הראש (AIM_Y, READY_T). הכוונה ננעלת LOCK_T לפני הירי -> "FIRE!" - 3 כדורים אמיתיים.
#    מתחמקים: להתכופף מתחת לקו (או מחסה) - הכדורים עוברים מעל.
#  להרוג את הסמל (SERGEANT_HP) -> אין פקודות - המשמר עומד דום ולא יורה יותר. כל רובאי שמת = כדור אחד פחות.
class HonorGuard extends Node2D:
	const VOLLEY_CD := Vector2(3.5, 5.0)
	const READY_T := 1.2
	const LOCK_T := 0.35
	const AIM_Y := -42.0            # גובה ראש: עובר מעל שחקן מתכופף (34), פוגע בעומד (52)
	const NOTICE_R := 330.0
	const RANGE := 900.0
	const SHOT_V := 650.0
	const SERGEANT_HP := 40
	const RIFLE_HP := 25
	const POS := [Vector2(-50, -16), Vector2(-14, -16), Vector2(14, -16), Vector2(42, -16)]   # סמל + 3 רובאים
	var hostile := false            # למדו לכוון עליך
	var volleys := 0                # לבדיקות
	var real_volleys := 0
	var shots := 0
	var hps := [SERGEANT_HP, RIFLE_HP, RIFLE_HP, RIFLE_HP]
	var _t := 2.0
	var _ready_t := 0.0
	var _fire_anim := 0.0
	var _lock := Vector2.ZERO
	var _hit := [0.0, 0.0, 0.0, 0.0]
	var _bodies := []
	var _face := -1.0

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		add_to_group("honor_guards")
		for i in 4:
			var b := GuardBody.new()
			b.g = self
			b.idx = i
			b.position = POS[i] + Vector2(0, -20)
			add_child(b)
			_bodies.append(b)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-70, -60), Vector2(140, 60))

	func danger_at(_p: Vector2, _margin := 0.0) -> bool:
		return false

	func sergeant_alive() -> bool:
		return int(hps[0]) > 0

	func hit(idx: int, dmg: int, at: Vector2) -> void:
		if int(hps[idx]) <= 0:
			return
		hps[idx] = int(hps[idx]) - dmg
		_hit[idx] = 0.1
		preload("res://particles.gd").burst(get_parent(), at, "hit", Vector2.UP, 6)
		_learn("THEY TURN THEIR RIFLES ON YOU")
		if int(hps[idx]) <= 0:
			_bodies[idx].collision_layer = 0
			preload("res://sfx.gd").play("zdeath", at, -2.0, 0.1, 2)
			Game.on_zombie_killed(0, {"pos": at, "zone": "", "source": "guard"})
			if idx == 0:
				_ready_t = 0.0
				_text("NO ORDERS - THE GUARD STANDS STILL", Color("e0e0e0"))

	func _learn(msg: String) -> void:
		if not hostile and sergeant_alive():
			hostile = true
			_text(msg, Color("ffb0a0"))

	func _text(s: String, col: Color) -> void:
		var p = preload("res://zombie.gd").HitText.new()
		p.text = s
		p.color = col
		p.size = 14
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(0, -90)

	func _muzzle(i: int) -> Vector2:
		var base: Vector2 = global_position + POS[i]
		if hostile:
			return base + Vector2(_face * 16.0, -30.0)
		return base + Vector2(_face * 4.0, -62.0)

	func _physics_process(delta: float) -> void:
		_t -= delta
		_fire_anim -= delta
		for i in 4:
			_hit[i] = float(_hit[i]) - delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead:
			var dx: float = pl.global_position.x - global_position.x
			if hostile:
				_face = signf(dx) if absf(dx) > 4.0 else _face
			if absf(dx) < NOTICE_R and absf(pl.global_position.y - global_position.y) < 150.0:
				_learn("THEY TURN THEIR RIFLES ON YOU")
			elif absf(dx) < 600.0 and pl._muzzle_flash > 0.0:
				_learn("YOU FIRED AT THE PARADE - THEY AIM AT YOU")
		if sergeant_alive() and pl != null:
			if _ready_t > 0.0:
				_ready_t -= delta
				if hostile and _ready_t > LOCK_T and not pl.dead:   # הכוונה עוקבת, ננעלת LOCK_T לפני הירי
					_lock = pl.global_position + Vector2(0, AIM_Y)
				if _ready_t <= 0.0:
					_fire(pl)
			elif _t <= 0.0 and absf(pl.global_position.x - global_position.x) < RANGE:
				_t = randf_range(VOLLEY_CD.x, VOLLEY_CD.y)
				_ready_t = READY_T
				_lock = pl.global_position + Vector2(0, AIM_Y)
				preload("res://sfx.gd").play("hg_order", global_position, -2.0, 0.05, 2)
		if Art.on_screen(self, global_position + Vector2(0, -40), 200.0):
			queue_redraw()

	func _fire(pl: Node) -> void:
		volleys += 1
		_fire_anim = 0.25
		preload("res://sfx.gd").play("hg_volley", global_position, 2.0, 0.05, 2)
		for i in range(1, 4):
			if int(hps[i]) <= 0:
				continue
			var m := _muzzle(i)
			preload("res://particles.gd").burst(get_parent(), m, "smoke", Vector2.UP, 2)
			if hostile:
				var s = preload("res://enemies/stationary_boss.gd").Shot.new()
				s.velocity = (_lock + Vector2(randf_range(-6, 6), randf_range(-2, 2)) - m).normalized() * SHOT_V
				s.damage = 1
				s.kind = "bolt"
				s.col = Color(1.0, 0.85, 0.4)
				s.r = 3.5
				get_parent().add_child(s)
				s.global_position = m
				shots += 1
		if hostile:
			real_volleys += 1

	func _draw() -> void:
		var S := preload("res://effects/s41_decor.gd")
		var font := ThemeDB.fallback_font
		# פודיום
		draw_rect(Rect2(Vector2(-70, -16), Vector2(140, 16)), Color("4a4650"))
		draw_rect(Rect2(Vector2(-70, -18), Vector2(140, 4)), S.E.RED)
		draw_rect(Rect2(Vector2(-70, -14), Vector2(140, 1.5)), S.E.BRASS)
		S.E.emblem(self, Vector2(0, -8), 5.0)
		var aiming := hostile and _ready_t > 0.0 and sergeant_alive()
		for i in 4:
			var p: Vector2 = POS[i]
			var dead := int(hps[i]) <= 0
			var tunic := S.E.RED if i > 0 else S.E.RED_D
			var sk := Color("7a8670")
			if float(_hit[i]) > 0.0:
				tunic = Color.WHITE
				sk = Color.WHITE
			if dead:   # שוכב על הפודיום
				draw_rect(Rect2(p + Vector2(-12, -6), Vector2(24, 6)), tunic.darkened(0.3))
				draw_circle(p + Vector2(14, -3), 4.0, sk.darkened(0.2))
				continue
			var f := _face
			draw_line(p + Vector2(-2, 0), p + Vector2(-2, -16), Color("e8e8e8"), 3.5)   # מכנסיים לבנים
			draw_line(p + Vector2(2, 0), p + Vector2(2, -16), Color("e8e8e8"), 3.5)
			draw_rect(Rect2(p + Vector2(-6, -34), Vector2(12, 19)), tunic)   # טוניקה
			draw_line(p + Vector2(-6, -30), p + Vector2(6, -22), Color("f0f0f0"), 1.5)   # רצועה
			draw_rect(Rect2(p + Vector2(-6, -18), Vector2(12, 2)), S.E.BRASS)
			var head := p + Vector2(f * 1.0, -39)
			draw_circle(head, 4.5, sk)
			draw_rect(Rect2(head + Vector2(-5, -12), Vector2(10, 9)), Color("1a1a1a"))   # קסדה גבוהה
			draw_rect(Rect2(head + Vector2(-5, -5), Vector2(10, 1.5)), S.E.BRASS)
			draw_line(head + Vector2(0, -12), head + Vector2(-f * 3.0, -22), Color("f0f0f0"), 3.0)   # נוצה
			if i == 0:   # הסמל: חרב
				var up := _ready_t > 0.0
				var hand := p + Vector2(f * 6.0, -30)
				var tip := hand + (Vector2(f * 4.0, -24) if up else Vector2(f * 20.0, 10))
				draw_line(p + Vector2(f * 4.0, -32), hand, sk, 2.0)
				draw_line(hand, tip, Color("d8dce4"), 2.0)
				if _ready_t > 0.0:   # הפקודה
					var txt := "AIM!" if hostile else "PRESENT..."
					if _ready_t < LOCK_T:
						txt = "FIRE!"
					draw_string_outline(font, p + Vector2(-40, -70), txt, HORIZONTAL_ALIGNMENT_CENTER, 80, 14, 4, Color(0, 0, 0, 0.8))
					draw_string(font, p + Vector2(-40, -70), txt, HORIZONTAL_ALIGNMENT_CENTER, 80, 14, Color(1.0, 0.35, 0.25) if hostile else Color(1, 1, 1))
				continue
			# רובאי: רובה עם כידון - למעלה (הצדעה) או אליך (כוונה)
			var m := _muzzle(i) - global_position
			var grip := p + Vector2(f * 3.0, -27)
			draw_line(grip, m, Color("3a2a1a"), 3.0)
			draw_line(m, m + (m - grip).normalized() * 7.0, Color("d8dce4"), 1.5)
			draw_line(p + Vector2(f * 2.0, -32), grip, sk, 2.0)
			if _fire_anim > 0.0:
				draw_circle(m + (m - grip).normalized() * 6.0, 5.0, Color(1.0, 0.85, 0.4, 0.9))
			if aiming:   # קו כוונה אדום אל המטרה (בהיר כשננעל)
				var lk := _lock - global_position
				var c := Color(1.0, 0.1, 0.1, 0.75 if _ready_t < LOCK_T else 0.3)
				draw_line(m, m + (lk - m).normalized() * minf(m.distance_to(lk), 700.0), c, 1.2 if _ready_t >= LOCK_T else 2.0)


class GuardBody extends StaticBody2D:
	var g: Node2D
	var idx := 0

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(14, 44)
		cs.shape = sh
		add_child(cs)

	func take_damage(amount: int, hit_pos: Vector2, _dir: Vector2, _explosive := false, src := {}) -> void:
		g.hit(idx, int(src.get("fixed", amount)), hit_pos)


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
