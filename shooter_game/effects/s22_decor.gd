extends RefCounted
# ============================================================
#  קישוטים לשלב 22 ("THE DAM") - סכר בטון ענק בבוקר אפור וגשום: מפלי מים מהשערים, ערפל רסס,
#  עמודי חשמל, יער אורנים, מגרש עצים (בולי עץ) למטה.
#    overcast_sky  - (רקע) שמיים אפורים-כחולים, פסי עננים נמוכים
#    far_dam       - (רקע) גבעות מיוערות + קיר הסכר הענק עם שערים ומפלים זורמים
#    mid_pylons    - (רקע) עמודי חשמל עם כבלים, אורנים, מגדל קליטה
#    near_bank     - (רקע) קנים וגדר רשת קרובים
#    DamGround     - (עולם) בטון רטוב: לוחות, שלוליות, פסים צהובים, ניקוז
#    LogTrap       - (עולם, מלכודת) חוט מתיחה על הקרקע + מסגרת עץ עם בול עץ למעלה. נוגעים בחוט ->
#                    החבל נקרע, הבול נופל עליך (DROP_DMG) ואז מתגלגל לכיוונך (ROLL_DMG) - קפוץ מעליו.
#                    פוגע גם בזומבים. אחרי שנעצר - נשאר על הקרקע כמחסה.
#    Obstacle      - (מוצק + מחסה) "barrier" מחסום בטון / "drums" חביות / "timber" ערימת בולים
#    DamFX         - (מסך) טפטוף גשם ורסס ערפל
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")

const CONCRETE := Color("7a7e82")
const CONCRETE_D := Color("4e5256")
const WOOD := Color("7a5634")
const WOOD_D := Color("4e3620")
const BARK := Color("5a3e26")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- שמיים אפורים ----
static func overcast_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	var bands := [Color("4a5868"), Color("5a6878"), Color("6a7888"), Color("7e8a96"), Color("909aa2")]
	var h := v.y * 0.75 / float(bands.size())
	for i in bands.size():
		ci.draw_rect(Rect2(0, float(i) * h, v.x, h + 1.0), bands[i])
	ci.draw_rect(Rect2(0, h * bands.size(), v.x, v.y), Color("909aa2"))
	for i in 4:   # עננים נמוכים
		var y := v.y * (0.08 + 0.1 * float(i))
		var x := fposmod(t * (8.0 + float(i) * 4.0) + float(i) * 300.0, v.x + 700.0) - 350.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 300, y - 14), Vector2(x + 620, y), Vector2(x + 320, y + 12)]), Color(0.35, 0.4, 0.46, 0.35))


# ---- גבעות + קיר הסכר עם מפלים ----
static func far_dam(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 2200.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 71 + 5)
		# גבעות מיוערות משני הצדדים
		for side in 2:
			var hx := x + (0.0 if side == 0 else 1500.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx, y), Vector2(hx + 120, y - 230), Vector2(hx + 380, y - 260), Vector2(hx + 700, y)]), Color("3e4c4a"))
		# הסכר: קיר בטון קעור בין הגבעות
		var dx := x + 560.0
		var dw := 1000.0
		var top := y - 250.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(dx, y), Vector2(dx + 30, top), Vector2(dx + dw - 30, top), Vector2(dx + dw, y)]), Color("8a8e90"))
		ci.draw_rect(Rect2(dx + 20, top - 14, dw - 40, 14), Color("6a6e72"))   # כביש על הסכר
		for g in 5:   # שערים + מפלים
			var gx := dx + 140.0 + float(g) * 170.0
			ci.draw_rect(Rect2(gx, top + 20, 46, 34), Color("4a4e52"))
			ci.draw_rect(Rect2(gx + 4, top + 54, 38, y - top - 54), Color(0.85, 0.92, 0.98, 0.55))
			var off := fposmod(t * 160.0 + float(g) * 30.0, 60.0)
			for q in 4:
				var ly := top + 54 + off + float(q) * 60.0
				if ly < y - 10.0:
					ci.draw_line(Vector2(gx + 8 + float(q % 2) * 18.0, ly), Vector2(gx + 8 + float(q % 2) * 18.0, minf(ly + 26.0, y)), Color(1, 1, 1, 0.6), 2.0)
		for s in 6:   # פסי יציקה
			ci.draw_line(Vector2(dx + 30, top + 40.0 * float(s) + 30), Vector2(dx + dw - 30, top + 40.0 * float(s) + 30), Color(0, 0, 0, 0.06), 2.0)
		ci.draw_rect(Rect2(dx - 40, y - 50, dw + 80, 50), Color(0.9, 0.94, 0.98, 0.3))   # רסס בתחתית
		r.randf()
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("3e4c4a"))


# ---- עמודי חשמל, אורנים, מגדל ----
static func mid_pylons(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1300.0
	var start := int(floor(sc / period)) - 1
	var prev := Vector2.INF
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 557 + 9)
		for i in 9:   # אורנים
			var px := x + r.randf_range(0.0, period)
			var h := r.randf_range(70.0, 130.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(px - h * 0.2, y), Vector2(px, y - h), Vector2(px + h * 0.2, y)]), Color("2e3a3a"))
		# עמוד חשמל (שתי רגליים, זרועות)
		var bx := x + 600.0
		var ph := 260.0
		var c := Color("2a3034")
		ci.draw_line(Vector2(bx - 26, y), Vector2(bx - 6, y - ph), c, 3.0)
		ci.draw_line(Vector2(bx + 26, y), Vector2(bx + 6, y - ph), c, 3.0)
		for q in 5:
			var qy := y - float(q) * ph / 5.0
			ci.draw_line(Vector2(bx - 26 + float(q) * 4.0, qy), Vector2(bx + 26 - float(q) * 4.0 - 4.0, qy - ph / 5.0), c, 1.2)
		ci.draw_line(Vector2(bx - 40, y - ph + 20), Vector2(bx + 40, y - ph + 20), c, 3.0)
		ci.draw_line(Vector2(bx - 30, y - ph + 50), Vector2(bx + 30, y - ph + 50), c, 3.0)
		var tip := Vector2(bx - 40, y - ph + 22)
		if prev != Vector2.INF:   # כבלים שמשתלשלים
			ci.draw_polyline(PackedVector2Array([prev, (prev + tip) * 0.5 + Vector2(0, 40), tip]), c, 1.2)
		prev = Vector2(bx + 40, y - ph + 22)
		if k % 2 == 0:   # מגדל קליטה
			var tx := x + 1050.0
			ci.draw_rect(Rect2(tx, y - 180, 50, 180), Color("6a6e72"))
			ci.draw_rect(Rect2(tx - 8, y - 196, 66, 16), Color("5a5e62"))
			ci.draw_circle(Vector2(tx + 25, y - 150), 4.0, Color(1.0, 0.3, 0.2, 0.6 + 0.4 * sin(t * 3.0)))
	ci.draw_rect(Rect2(0, y - 14, v.x, 30), Color(0.85, 0.9, 0.95, 0.15))


# ---- קנים וגדר קרובים ----
const DARK := [Color("1e2628"), Color("242c2e"), Color("2a3234")]


static func near_bank(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 211 + 4)
		var col: Color = DARK[k % 3]
		for i in 4:   # גושי קנים
			var px := x + r.randf_range(0.0, period)
			for q in 8:
				var bx := px + float(q) * 5.0
				var h := r.randf_range(30.0, 70.0)
				var sway := sin(t * 1.4 + bx * 0.03) * 3.0
				ci.draw_line(Vector2(bx, y), Vector2(bx + sway, y - h), col, 2.0)
				if q % 3 == 0:
					ci.draw_rect(Rect2(bx + sway - 1.5, y - h - 8, 3, 9), Color("3a2a1e"))   # ראש קנה
		var fx := x + r.randf_range(0.0, period * 0.5)   # גדר רשת
		for f in 6:
			ci.draw_line(Vector2(fx + float(f) * 50.0, y), Vector2(fx + float(f) * 50.0, y - 60), col, 3.0)
		ci.draw_line(Vector2(fx, y - 58), Vector2(fx + 250, y - 58), col, 1.5)
		for d in 10:
			ci.draw_line(Vector2(fx + float(d) * 25.0, y - 58), Vector2(fx + float(d) * 25.0 + 25.0, y - 4), Color(col, 0.6), 1.0)
	ci.draw_rect(Rect2(0, y - 3.0, v.x, v.y - y + 3.0), DARK[0])


# ---- בטון רטוב ----
class DamGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s22_decor.gd")
		draw_rect(Rect2(0, 0, w, depth), S.CONCRETE_D)
		draw_rect(Rect2(0, 0, w, 10.0), S.CONCRETE)
		var x := 0.0
		while x < w:   # לוחות בטון
			draw_line(Vector2(x, 0), Vector2(x, depth), Color(0, 0, 0, 0.25), 1.5)
			x += r.randf_range(120.0, 180.0)
		for i in int(w / 260.0):   # פסים צהובים
			var px := r.randf_range(0.0, w - 60.0)
			draw_rect(Rect2(px, 2, 48, 4), Color("c8a830"))
		for i in int(w / 200.0):   # שלוליות עם השתקפות
			var px := r.randf_range(0.0, w - 90.0)
			var pw := r.randf_range(40.0, 90.0)
			draw_rect(Rect2(px, 1, pw, 4), Color(0.6, 0.7, 0.8, 0.55))
			draw_line(Vector2(px + 6, 2), Vector2(px + pw * 0.4, 2), Color(1, 1, 1, 0.4), 1.0)
		for i in int(w / 400.0):   # ניקוז
			var px := r.randf_range(0.0, w - 40.0)
			draw_rect(Rect2(px, 12, 30, 8), Color("2a2c2e"))
			for q in 4:
				draw_line(Vector2(px + 4 + float(q) * 7.0, 12), Vector2(px + 4 + float(q) * 7.0, 20), S.CONCRETE, 1.5)


# ---- מלכודת בול עץ ----
class LogTrap extends Node2D:
	const DROP_DMG := 2
	const ROLL_DMG := 1
	const HEIGHT := 175.0        # גובה הבול מעל הקרקע
	const DELAY := 0.3           # מהחוט עד שהחבל נקרע (חריקה)
	const ROLL_V := 270.0
	const ROLL_T := 1.6
	const LOG_R := 15.0          # רדיוס הבול
	var wire_w := 70.0           # רוחב חוט המתיחה (ממורכז מתחת לבול)
	var log_w := 110.0
	var state := 0               # 0 = מחכה, 1 = חורק, 2 = נופל, 3 = מתגלגל, 4 = נח
	var triggered := 0           # לבדיקות
	var hit_player := 0
	var _t := 0.0
	var _logp := Vector2.ZERO    # מרכז הבול (מקומי)
	var _vy := 0.0
	var _dir := 1.0
	var _spin := 0.0
	var _hit_zs := []
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		_logp = Vector2(0, -HEIGHT)

	# זומבים חכמים נזהרים (ai/zombie_brain.gd)
	func danger_at(p: Vector2, margin := 0.0) -> bool:
		if state >= 2 and state <= 3:
			return absf(p.x - (global_position.x + _logp.x)) < log_w * 0.5 + margin
		return false

	func _physics_process(delta: float) -> void:
		var pl := get_tree().get_first_node_in_group("player")
		match state:
			0:
				if pl != null and not pl.dead:
					var wr := Rect2(global_position + Vector2(-wire_w * 0.5, -10.0), Vector2(wire_w, 12.0))
					if wr.intersects(pl.body_rect()):
						state = 1
						_t = DELAY
						triggered += 1
						Sfx.play("clink", global_position, 2.0)
						Sfx.play("servo", global_position + Vector2(0, -HEIGHT), 0.0)
						_dir = signf(pl.velocity.x) if absf(pl.velocity.x) > 10.0 else 1.0
						queue_redraw()
				return
			1:
				_t -= delta
				_logp.x = sin(_t * 60.0) * 1.5   # רועד
				if _t <= 0.0:
					state = 2
					_vy = 0.0
					Sfx.play("whoosh", global_position, 2.0)
			2:
				_vy += 1500.0 * delta
				_logp.y += _vy * delta
				_hurt_under(pl, DROP_DMG)
				if _logp.y >= -LOG_R:
					_logp.y = -LOG_R
					state = 3
					_t = ROLL_T
					Sfx.play("land", global_position, 6.0)
					var cam := get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake"):
						cam.shake(6.0, 0.25)
					preload("res://particles.gd").burst(get_parent(), global_position, "smoke", Vector2.UP, 10)
					if pl != null and not pl.dead:   # מתגלגל לכיוון השחקן
						_dir = signf(pl.global_position.x - global_position.x) if absf(pl.global_position.x - global_position.x) > 8.0 else _dir
			3:
				_t -= delta
				var v := ROLL_V * clampf(_t / ROLL_T + 0.3, 0.0, 1.0)
				var step := _dir * v * delta
				var gp := global_position + _logp + Vector2(step + _dir * log_w * 0.5, -4.0)
				if not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(gp - Vector2(_dir * 6.0, 0), gp, 1)).is_empty():
					_t = 0.0   # נתקע במכשול
				else:
					_logp.x += step
					_spin += step / LOG_R
				_hurt_under(pl, ROLL_DMG)
				if _t <= 0.0:
					state = 4
					_make_solid()
			_:
				return
		queue_redraw()

	func _hurt_under(pl: Node, dmg: int) -> void:
		var lr := Rect2(global_position + _logp + Vector2(-log_w * 0.5, -LOG_R), Vector2(log_w, LOG_R * 2.0))
		if pl != null and not pl.dead and lr.intersects(pl.body_rect()):
			if pl._invuln <= 0.0:
				hit_player += 1
			pl.hurt(dmg, Vector2(_dir * 1.6 if state == 3 else signf(pl.global_position.x - lr.get_center().x) * 1.4, -1.0))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or _hit_zs.has(z):
				continue
			if lr.has_point(z.global_position + Vector2(0, -20)):
				_hit_zs.append(z)
				z.take_damage(60, z.global_position + Vector2(0, -20), Vector2(_dir, -0.5), true, {"source": "hazard"})

	# אחרי שנעצר: מכשול מוצק (אפשר לעמוד עליו / להסתתר מאחוריו)
	func _make_solid() -> void:
		_body = StaticBody2D.new()
		_body.collision_layer = 1
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(log_w, LOG_R * 2.0)
		cs.shape = sh
		cs.position = _logp
		_body.add_child(cs)
		add_child(_body)

	func _draw() -> void:
		var S := preload("res://effects/s22_decor.gd")
		# מסגרת A מעץ שמחזיקה את הבול (נשארת)
		var fx := log_w * 0.5 + 8.0
		for s in [-1.0, 1.0]:
			draw_line(Vector2(s * fx, 0), Vector2(s * (fx - 18.0), -HEIGHT - 6.0), S.WOOD_D, 5.0)
			draw_line(Vector2(s * fx, 0), Vector2(s * (fx + 14.0), -HEIGHT * 0.5), S.WOOD_D, 3.0)
		draw_line(Vector2(-fx + 14.0, -HEIGHT + LOG_R + 4.0), Vector2(fx - 14.0, -HEIGHT + LOG_R + 4.0), S.WOOD, 4.0)   # קורה
		if state == 0 or state == 1:   # החבל שמחזיק
			draw_line(Vector2(fx - 18.0, -HEIGHT - 6.0), Vector2(log_w * 0.3, -HEIGHT - LOG_R), Color("c8b080"), 1.6)
		elif state >= 2:   # קצה חבל קרוע
			draw_line(Vector2(fx - 18.0, -HEIGHT - 6.0), Vector2(fx - 26.0, -HEIGHT + 10.0), Color("c8b080"), 1.4)
		# חוט המתיחה + יתדות עם סרט אדום (רואים אותו - הוגן)
		if state == 0:
			draw_line(Vector2(-wire_w * 0.5, -3), Vector2(wire_w * 0.5, -3), Color(0.85, 0.85, 0.8, 0.85), 1.0)
		for s in [-1.0, 1.0]:
			draw_line(Vector2(s * wire_w * 0.5, 0), Vector2(s * wire_w * 0.5, -8), S.WOOD_D, 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(s * wire_w * 0.5, -8), Vector2(s * wire_w * 0.5 + 6, -6), Vector2(s * wire_w * 0.5, -4)]), Color("c83a2a"))
		# הבול
		var c := _logp
		draw_rect(Rect2(c + Vector2(-log_w * 0.5, -LOG_R), Vector2(log_w, LOG_R * 2.0)), S.BARK)
		draw_rect(Rect2(c + Vector2(-log_w * 0.5, -LOG_R), Vector2(log_w, 4.0)), Color(S.BARK.lightened(0.15)))
		for q in 4:   # קליפה (מסתובבת כשהוא מתגלגל)
			var lx := fposmod(float(q) * 30.0 + _spin * LOG_R, log_w) - log_w * 0.5
			draw_line(c + Vector2(lx, -LOG_R + 2), c + Vector2(lx + 4, LOG_R - 2), Color(0, 0, 0, 0.3), 1.5)
		for s in [-1.0, 1.0]:   # קצוות עם טבעות
			var e := c + Vector2(s * log_w * 0.5, 0)
			draw_circle(e, LOG_R, Color("b08a5a"))
			draw_arc(e, LOG_R * 0.6, 0, TAU, 14, Color("8a6a40"), 1.2)
			draw_arc(e, LOG_R * 0.25, 0, TAU, 10, Color("8a6a40"), 1.0)
			draw_arc(e, LOG_R, 0, TAU, 18, Art.OUTLINE, 1.4)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "barrier"
	var size := Vector2(80, 40)
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

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s22_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"barrier":   # מחסום בטון (ג'רזי)
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.8, -h * 0.35), Vector2(w * 0.7, -h), Vector2(w * 0.3, -h), Vector2(w * 0.2, -h * 0.35)]), S.CONCRETE, 0.15, 0.45, Art.OUTLINE, 1.5)
				for q in 3:
					draw_colored_polygon(PackedVector2Array([Vector2(w * (0.3 + 0.15 * q), -h * 0.6), Vector2(w * (0.38 + 0.15 * q), -h * 0.6), Vector2(w * (0.33 + 0.15 * q), -h * 0.85), Vector2(w * (0.25 + 0.15 * q), -h * 0.85)]), Color("c8a830"))
			"drums":   # שתי חביות
				for i in 2:
					var dx := float(i) * w * 0.5
					var c := Color("3a6a8a") if i == 0 else Color("8a3a2a")
					Art.fill_shaded(self, PackedVector2Array([Vector2(dx + 2, 0), Vector2(dx + w * 0.5 - 2, 0), Vector2(dx + w * 0.5 - 2, -h), Vector2(dx + 2, -h)]), c, 0.2, 0.4, Art.OUTLINE, 1.4)
					for q in 2:
						draw_line(Vector2(dx + 2, -h * (0.33 + 0.33 * q)), Vector2(dx + w * 0.5 - 2, -h * (0.33 + 0.33 * q)), Color(0, 0, 0, 0.3), 2.0)
			_:   # ערימת בולי עץ (גבוה - מחסה)
				var rows := 3
				var rr := h / float(rows * 2)
				for row in rows:
					var n := rows - row + 1
					for i in n:
						var cx := w * 0.5 + (float(i) - float(n - 1) * 0.5) * rr * 2.0
						var cy := -rr - float(row) * rr * 1.75
						draw_circle(Vector2(cx, cy), rr, Color("b08a5a"))
						draw_arc(Vector2(cx, cy), rr * 0.55, 0, TAU, 12, Color("8a6a40"), 1.0)
						draw_arc(Vector2(cx, cy), rr, 0, TAU, 14, Art.OUTLINE, 1.3)
				draw_line(Vector2(w * 0.1, -h * 0.5), Vector2(w * 0.9, -h * 0.5), Color("c8b080"), 1.5)   # חבל


# ---- טפטוף + רסס (שכבת מסך) ----
class DamFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _drops := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 22
		for i in 70:
			_drops.append(Vector2(r.randf_range(0, vp.x), r.randf_range(0, vp.y)))

	func _process(delta: float) -> void:
		_t += delta
		for i in _drops.size():
			var d: Vector2 = _drops[i] + Vector2(-90.0, 520.0) * delta
			if d.y > vp.y:
				d = Vector2(randf_range(0.0, vp.x + 100.0), -10.0)
			_drops[i] = d
		queue_redraw()

	func _draw() -> void:
		for d in _drops:
			draw_line(d, d + Vector2(-3, 14), Color(0.8, 0.85, 0.95, 0.35), 1.0)
		var x := fposmod(-_t * 25.0, vp.x)
		for j in 2:
			var xx := x + float(j) * vp.x - vp.x * 0.5
			draw_colored_polygon(PackedVector2Array([Vector2(xx, vp.y - 110), Vector2(xx + vp.x * 0.5, vp.y - 128), Vector2(xx + vp.x, vp.y - 110), Vector2(xx + vp.x * 0.5, vp.y - 94)]), Color(0.9, 0.93, 0.97, 0.08))
