extends RefCounted
# ============================================================
#  קישוטים לשלב 23 ("HIGHWAY 7") - כביש מהיר פקוק בשקיעה: מכוניות נטושות, גשרים עיליים שבורים,
#  שלטי חוצות, עשן מהעיר הבוערת.
#    dusk_sky      - (רקע) שקיעה כתומה-סגולה, שמש נמוכה, עמודי עשן
#    far_city      - (רקע) קו רקיע של עיר עם חלונות דולקים ושריפות
#    mid_overpass  - (רקע) גשר כביש עילי על עמודים, מכוניות עליו, שלטי חוצות, פנסי רחוב
#    near_rail     - (רקע) מעקה בטיחות, שלט ירוק "EXIT 7", עשבים
#    RoadGround    - (עולם) אספלט: פסי נתיבים, סימני בלימה, כתמי שמן, סדקים
#    Car           - (עולם, מוצק + מחסה) מכונית נטושה. אפשר לעמוד עליה. SHOVER דוחף אותה (push) ->
#                    היא מחליקה ופוגעת במי שבדרך. alarm = true -> נורה אדומה מהבהבת על השמשה:
#                    נגיעה / ירייה / דחיפה -> אזעקה! צופר + אורות, כל הזומבים באזור שומעים, ועוד זומבים רצים אליך.
#    Gantry        - (עולם) גשר שלטים מעל הכביש (קישוט)
#    RoadFX        - (מסך) גחלים ואפר באוויר, אובך חם בתחתית
#  לשנות: Car.ALARM_SPAWN, Car.ALARM_NOISE, Car.HIT_DMG.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const ASPHALT := Color("3a3a3e")
const ASPHALT_D := Color("26262a")
const CONCRETE := Color("8a8682")
const CAR_COLS := [Color("8a2a24"), Color("2a4a6a"), Color("c8c0a8"), Color("3a5a3a"), Color("6a6a70"), Color("b88a2a"), Color("1e1e22")]


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- שקיעה ----
static func dusk_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("2a1e3a"), Color("5a2e4a"), Color("a8484a"), Color("e07a3a"), Color("f0b060")], 0.8)
	var sun := Vector2(v.x * 0.68, v.y * 0.66)
	for i in 4:
		ci.draw_circle(sun, 120.0 - float(i) * 26.0, Color(1.0, 0.75, 0.4, 0.08 + float(i) * 0.04))
	ci.draw_circle(sun, 40.0, Color("ffd890"))
	for i in 3:   # פסי עננים מול השמש
		var y := v.y * (0.5 + 0.07 * float(i))
		var x := fposmod(t * (5.0 + float(i) * 3.0) + float(i) * 400.0, v.x + 900.0) - 450.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 380, y - 9), Vector2(x + 760, y), Vector2(x + 380, y + 7)]), Color(0.45, 0.18, 0.28, 0.45))


# ---- עיר רחוקה בוערת ----
static func far_city(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	Kit.skyline(ci, sc * 0.6, v, y - 20.0, Color("3a2236"), 231, Vector2(50, 110), Vector2(140, 300), 0.0)
	Kit.skyline(ci, sc, v, y, Color("2a1828"), 77, Vector2(60, 140), Vector2(80, 230), 0.06, Color(1.0, 0.7, 0.35, 0.8), t, 0.4)
	var period := 1800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 97 + 3)
		var fx := x + r.randf_range(200.0, 1600.0)
		Kit.fire_glow(ci, Vector2(fx, y - r.randf_range(40.0, 120.0)), t, 60.0, k)
		Kit.smoke_column(ci, Vector2(fx, y - 100.0), t + float(k), 320.0, Color(0.15, 0.1, 0.12, 0.35), 120.0)
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("2a1828"))


# ---- גשר עילי, שלטי חוצות, פנסים ----
static func mid_overpass(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var deck := y - 150.0
	var col := Color("4a3440")
	var dark := Color("362430")
	# גשר רציף לכל הרוחב
	ci.draw_rect(Rect2(0, deck, v.x, 22.0), col)
	ci.draw_rect(Rect2(0, deck - 10.0, v.x, 10.0), dark)
	ci.draw_rect(Rect2(0, deck + 22.0, v.x, 4.0), Color(0, 0, 0, 0.25))
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 389 + 11)
		for p in 2:   # עמודים
			var px := x + 120.0 + float(p) * 450.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(px, y), Vector2(px + 8, deck + 26), Vector2(px + 40, deck + 26), Vector2(px + 48, y)]), dark)
		for c in 3:   # מכוניות תקועות על הגשר (צלליות)
			var cx := x + r.randf_range(0.0, period - 60.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx, deck - 10), Vector2(cx + 4, deck - 20), Vector2(cx + 14, deck - 20), Vector2(cx + 20, deck - 29), Vector2(cx + 40, deck - 29), Vector2(cx + 48, deck - 20), Vector2(cx + 58, deck - 18), Vector2(cx + 58, deck - 10)]), dark)
		if k % 2 == 0:   # שלט חוצות
			var bx := x + r.randf_range(250.0, 500.0)
			var by := deck - 140.0
			ci.draw_line(Vector2(bx + 30, deck - 10), Vector2(bx + 30, by + 60), dark, 4.0)
			ci.draw_line(Vector2(bx + 130, deck - 10), Vector2(bx + 130, by + 60), dark, 4.0)
			ci.draw_rect(Rect2(bx, by, 160, 62), Color("c8b088"))
			ci.draw_rect(Rect2(bx + 4, by + 4, 152, 54), Color("3a6a8a") if k % 4 == 0 else Color("a83a2a"))
			ci.draw_rect(Rect2(bx + 12, by + 14, 70, 9), Color(1, 1, 1, 0.75))
			ci.draw_rect(Rect2(bx + 12, by + 30, 100, 6), Color(1, 1, 1, 0.5))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx + 90, by + 4), Vector2(bx + 140, by + 4), Vector2(bx + 156, by + 40), Vector2(bx + 156, by + 58), Vector2(bx + 120, by + 58)]), Color(0, 0, 0, 0.3))   # קרוע
			ci.draw_line(Vector2(bx + 6, by + 62), Vector2(bx + 14, by + 76), Color(0.8, 0.7, 0.55, 0.8), 2.0)
		var lx := x + 700.0   # פנס רחוב (חלק מהבהבים)
		ci.draw_line(Vector2(lx, y), Vector2(lx, deck - 100), dark, 3.0)
		ci.draw_line(Vector2(lx, deck - 100), Vector2(lx + 26, deck - 104), dark, 3.0)
		if k % 3 != 1 or fmod(t * 3.0 + float(k), 2.0) < 1.3:
			ci.draw_circle(Vector2(lx + 26, deck - 100), 9.0, Color(1.0, 0.8, 0.45, 0.25))
			ci.draw_circle(Vector2(lx + 26, deck - 101), 3.0, Color("ffe0a0"))
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), dark)


# ---- מעקה, שלט יציאה, עשבים ----
static func near_rail(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var c := Color("1e1418")
	var period := 700.0
	var start := int(floor(sc / period)) - 1
	ci.draw_rect(Rect2(0, y - 26.0, v.x, 9.0), c)   # מעקה בטיחות רציף
	ci.draw_line(Vector2(0, y - 22.0), Vector2(v.x, y - 22.0), Color(0.45, 0.35, 0.35, 0.5), 1.0)
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 61 + 2)
		for p in 7:   # עמודי מעקה
			ci.draw_rect(Rect2(x + float(p) * 100.0, y - 26.0, 5.0, 26.0), c)
		for g in 5:   # עשבים
			var gx := x + r.randf_range(0.0, period)
			for q in 4:
				var sway := sin(t * 1.6 + gx * 0.05 + float(q)) * 2.0
				ci.draw_line(Vector2(gx + float(q) * 4.0, y), Vector2(gx + float(q) * 4.0 + sway, y - r.randf_range(12.0, 30.0)), c, 1.6)
		if k % 3 == 0:   # שלט יציאה ירוק
			var sx := x + 300.0
			ci.draw_line(Vector2(sx + 20, y), Vector2(sx + 20, y - 150), c, 5.0)
			ci.draw_line(Vector2(sx + 110, y), Vector2(sx + 110, y - 150), c, 5.0)
			ci.draw_rect(Rect2(sx, y - 200, 130, 58), Color("1e3a26"))
			ci.draw_rect(Rect2(sx + 3, y - 197, 124, 52), Color("2e6a3e"))
			ci.draw_rect(Rect2(sx + 3, y - 197, 124, 52), Color(1, 1, 1, 0.55), false, 1.5)
			ci.draw_rect(Rect2(sx + 12, y - 188, 46, 8), Color(1, 1, 1, 0.8))
			ci.draw_rect(Rect2(sx + 12, y - 174, 70, 6), Color(1, 1, 1, 0.6))
			ci.draw_rect(Rect2(sx + 90, y - 192, 28, 18), Color("e8c040"))   # "EXIT 7"
			ci.draw_line(Vector2(sx + 104, y - 160), Vector2(sx + 118, y - 152), Color(1, 1, 1, 0.8), 3.0)   # חץ
	ci.draw_rect(Rect2(0, y - 17.0, v.x, v.y - y + 17.0), c)


# ---- אספלט ----
class RoadGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s23_decor.gd")
		draw_rect(Rect2(0, 0, w, depth), S.ASPHALT_D)
		draw_rect(Rect2(0, 0, w, 8.0), S.ASPHALT)
		var x := fposmod(-position.x, 120.0)
		while x < w:   # פסי נתיב מקווקווים
			draw_rect(Rect2(x, 3, 52, 3), Color("d8d0b0"))
			x += 120.0
		draw_rect(Rect2(0, 14, w, 2), Color("c8a830"))   # קו צהוב רציף
		for i in int(w / 300.0):   # סימני בלימה
			var px := r.randf_range(0.0, w - 200.0)
			var pw := r.randf_range(80.0, 200.0)
			draw_line(Vector2(px, 1.5), Vector2(px + pw, 1.0 + r.randf_range(-0.5, 1.5)), Color(0, 0, 0, 0.45), 2.0)
			draw_line(Vector2(px + 6, 6.5), Vector2(px + pw + 4, 6.0), Color(0, 0, 0, 0.35), 2.0)
		for i in int(w / 260.0):   # כתמי שמן
			var px := r.randf_range(0.0, w - 60.0)
			draw_colored_polygon(Art.ellipse(Vector2(px, 4), r.randf_range(14.0, 30.0), 2.5), Color(0.05, 0.05, 0.08, 0.6))
		for i in int(w / 220.0):   # סדקים
			var px := r.randf_range(0.0, w - 40.0)
			draw_polyline(PackedVector2Array([Vector2(px, 8), Vector2(px + 8, 18), Vector2(px + 4, 30), Vector2(px + 14, 44)]), Color(0, 0, 0, 0.4), 1.2)


# ---- מכונית נטושה (מוצק, מחסה, אפשר לדחוף, אולי עם אזעקה) ----
class CarBody extends AnimatableBody2D:
	var car: Node = null

	func hit_by_bullet(_pos: Vector2, _normal: Vector2, _dir: Vector2) -> void:   # bullet.gd
		if car != null and is_instance_valid(car):
			car.on_shot()


class Car extends Node2D:
	const HIT_DMG := 2               # מכונית מחליקה פוגעת בשחקן
	const Z_DMG := 45                # ובזומבים
	const ALARM_NOISE := 1400.0      # כמה רחוק שומעים את האזעקה
	const ALARM_SPAWN := 3           # כמה זומבים רצים לרעש
	const ALARM_T := 4.0
	const LIFT := 8.0                # תחתית הגוף מעל הכביש: פינה בגובה הרגליים "תפסה" את השחקן (velocity.y עלה ל-15000, תקוע 25 שניות)
	var size := Vector2(128, 44)
	var model := 0                   # 0 = סדאן, 1 = האצ'בק, 2 = טנדר
	var tint := Color("8a2a24")
	var alarm := false
	var floor_y := 630.0
	var seed_v := 0
	var face := 1.0
	var alarmed := 0                 # לבדיקות
	var pushed := 0
	var hit_player := 0
	var _vx := 0.0
	var _push_t := 0.0
	var _hit_done := false
	var _hit_zs := []
	var _alarm_t := 0.0
	var _blink := false
	var _body: CarBody = null
	var _wheel := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("cover")
		add_to_group("cars")
		_body = CarBody.new()
		_body.car = self
		_body.sync_to_physics = false   # זזה עם ה-Node (אחרת הגוף נשאר מאחור וחוסם)
		_body.collision_layer = 1
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(size.x - 6.0, size.y * 0.82 - LIFT)
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.41 - LIFT * 0.5)
		_body.add_child(cs)
		add_child(_body)
		set_physics_process(alarm)

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y * 0.82), Vector2(size.x, size.y * 0.82))

	func rect() -> Rect2:
		return Rect2(global_position + Vector2(3.0, -size.y * 0.82), Vector2(size.x - 6.0, size.y * 0.82))

	func moving() -> bool:
		return absf(_vx) > 60.0

	# SHOVER: דוחף את המכונית (dir = -1/1). מחזיר false אם היא כבר זזה
	func push(dir: float, speed := 300.0, t := 1.0) -> bool:
		if moving():
			return false
		_vx = dir * speed
		_push_t = t
		_hit_done = false
		_hit_zs.clear()
		pushed += 1
		set_physics_process(true)
		Sfx.play("s23_scrape", global_position + Vector2(size.x * 0.5, 0), 2.0, 0.1, 2)
		trigger_alarm()
		return true

	func on_shot() -> void:
		trigger_alarm()

	func trigger_alarm() -> void:
		if not alarm or _alarm_t > 0.0 or alarmed > 0:
			return
		alarmed += 1
		_alarm_t = ALARM_T
		set_physics_process(true)
		var c := global_position + Vector2(size.x * 0.5, -20.0)
		Sfx.play("s23_alarm", c, 6.0, 0.0, 2)
		Game.make_noise(c, ALARM_NOISE)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead:
			pl._say("CAR ALARM... great.", Color("ffb070"))
		_call_horde.call_deferred()

	func _call_horde() -> void:   # זומבים רצים לרעש: משני הצדדים, מחוץ למסך
		var main := get_parent()
		if main == null or not main.has_method("_spawn_zombie"):
			return
		var lw: float = float(main.get("level_w")) if main.get("level_w") != null else 100000.0
		var cx := global_position.x + size.x * 0.5
		for i in ALARM_SPAWN:
			var side := 1.0 if i % 2 == 0 else -1.0
			var x := clampf(cx + side * randf_range(760.0, 880.0), 300.0, lw - 200.0)
			var zz: Node = main._spawn_zombie(x, floor_y, 1 if i < 2 else 0)
			if zz != null:
				zz.dormant = false
				zz.hear_noise(global_position, 100000.0)

	func _physics_process(delta: float) -> void:
		var pl := get_tree().get_first_node_in_group("player")
		if alarm and alarmed == 0 and pl != null and not pl.dead and Engine.get_physics_frames() % 3 == 0:
			if rect().grow(4.0).intersects(pl.body_rect()):   # נגעת / עלית עליה
				trigger_alarm()
			var b := Engine.get_physics_frames() % 60 < 8
			if b != _blink and Art.on_screen(self, global_position):
				_blink = b
				queue_redraw()
		if _alarm_t > 0.0:
			_alarm_t -= delta
			if Engine.get_physics_frames() % 6 == 0:
				queue_redraw()
			if _alarm_t > 1.0 and fmod(_alarm_t, 1.6) < delta:   # הצופר חוזר
				Sfx.play("s23_alarm", global_position + Vector2(size.x * 0.5, -20.0), 4.0, 0.0, 2)
			if _alarm_t <= 0.0:
				queue_redraw()
		if _vx != 0.0:
			_slide(pl, delta)
		if _vx == 0.0 and _alarm_t <= 0.0 and (not alarm or alarmed > 0):
			set_physics_process(false)

	func _slide(pl: Node, delta: float) -> void:
		_push_t -= delta
		if _push_t <= 0.0:
			_vx = move_toward(_vx, 0.0, 700.0 * delta)
		var step := _vx * delta
		var dir := signf(_vx)
		var front := global_position + Vector2((size.x + 2.0) if dir > 0.0 else -2.0, -size.y * 0.4)
		var q := PhysicsRayQueryParameters2D.create(front, front + Vector2(step + dir * 2.0, 0.0), 1)
		q.exclude = [_body.get_rid()]
		var lw: float = float(get_parent().get("level_w")) if get_parent().get("level_w") != null else 100000.0
		if not get_world_2d().direct_space_state.intersect_ray(q).is_empty() or global_position.x + step < 20.0 or global_position.x + size.x + step > lw - 20.0:
			if absf(_vx) > 150.0:
				Sfx.play("land", front, 4.0)
				_shake(5.0)
			_vx = 0.0
			_unpin(pl)
			queue_redraw()
			return
		if pl != null and not pl.dead and not _carry(pl, step, dir):
			_vx = 0.0   # השחקן נדחף לקיר: המכונית נעצרת (לא מוחצת / תוקעת אותו)
			queue_redraw()
			return
		position.x += step
		_unpin(pl)
		_wheel += step / 9.0
		if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(self, global_position):
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(size.x * (0.0 if dir > 0.0 else 1.0), -3.0), "smoke", Vector2(-dir, -0.4), 1)
		if moving():
			var hit_r := rect().grow(3.0)
			if pl != null and not pl.dead and not _hit_done and hit_r.intersects(pl.body_rect()):
				var pr: Rect2 = pl.body_rect()
				var pcx := pr.get_center().x
				var on_top := pr.end.y < rect().position.y + 8.0
				if not on_top and signf(pcx - (global_position.x + size.x * 0.5)) == dir:   # רק מהצד שאליו היא נוסעת
					_hit_done = true
					if pl._invuln <= 0.0:
						hit_player += 1
					pl.hurt(HIT_DMG, Vector2(dir * 2.6, -1.2))
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or _hit_zs.has(z) or z.get("type_mod") != null and z.type_mod.get("shoving") == self:
					continue
				var zr := Rect2(z.global_position + Vector2(-10.0 * float(z.wf), -50.0 * float(z.sc)), Vector2(20.0 * float(z.wf), 50.0 * float(z.sc)))
				if hit_r.intersects(zr) and signf(z.global_position.x - (global_position.x + size.x * 0.5)) == dir:
					_hit_zs.append(z)
					z.take_damage(Z_DMG, z.global_position + Vector2(0, -24), Vector2(dir, -0.5), true, {"source": "hazard"})
		queue_redraw()

	# הגוף המוצק בעולם (כמו ה-CollisionShape)
	func solid_rect() -> Rect2:
		return Rect2(global_position + Vector2(3.0, -size.y * 0.82), Vector2(size.x - 6.0, size.y * 0.82 - LIFT))

	# שחקן שעומד בדרך (לא על הגג): המכונית דוחפת אותו לפניה. false = הוא תקוע בקיר
	func _carry(pl: Node, step: float, dir: float) -> bool:
		var sr := solid_rect()
		var pr: Rect2 = pl.body_rect()
		if pr.end.y <= sr.position.y + 6.0 or pr.position.y >= sr.end.y:
			return true
		var gap: float = (pr.position.x - sr.end.x) if dir > 0.0 else (sr.position.x - pr.end.x)
		var need: float = absf(step) - gap + 1.0
		if gap < -sr.size.x * 0.5 or need <= 0.0:
			return true
		var col: KinematicCollision2D = pl.move_and_collide(Vector2(dir * need, 0.0))
		return col == null or absf(col.get_normal().x) < 0.5

	# רשת ביטחון: השחקן בתוך הגוף (מכונית נכנסה בו) -> החוצה לצד הקרוב, או לגג אם הצד חסום.
	# בלי זה Godot לא מחלץ אותו: velocity.y גדל ל-15000 והשחקן תקוע (בוט, שלב 23)
	func _unpin(pl: Node) -> void:
		if pl == null or pl.dead:
			return
		var sr := solid_rect()
		var pr: Rect2 = pl.body_rect()
		if not pr.grow(-0.5).intersects(sr) or pr.end.y <= sr.position.y + 6.0:
			return
		var half: float = pr.size.x * 0.5
		var right: bool = pr.get_center().x > sr.get_center().x
		var nx: float = (sr.end.x + half + 1.0) if right else (sr.position.x - half - 1.0)
		var q := PhysicsShapeQueryParameters2D.new()
		var box := RectangleShape2D.new()
		box.size = pr.size - Vector2(2.0, 4.0)
		q.shape = box
		q.collision_mask = pl.collision_mask & ~16
		q.exclude = [_body.get_rid(), pl.get_rid()]
		q.transform = Transform2D(0.0, Vector2(nx, pr.get_center().y - 2.0))
		if get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty():
			pl.global_position.x = nx
		else:
			pl.global_position = Vector2(clampf(pr.get_center().x, sr.position.x + half, sr.end.x - half), sr.position.y - 1.0)
		pl.velocity.y = minf(pl.velocity.y, 0.0)

	func _shake(st: float) -> void:
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(st, 0.2)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var w := size.x
		var h := size.y
		draw_set_transform(Vector2(w * 0.5, 0.0), 0.0, Vector2(face, 1.0))
		var o := Vector2(-w * 0.5, 0.0)
		var body := tint
		var dk := Art.shade(tint, 0.4)
		var glass := Color(0.25, 0.32, 0.4)
		Art.ground_shadow(self, Vector2.ZERO, w * 0.5)
		# גוף
		var pts: PackedVector2Array
		var win: PackedVector2Array
		match model:
			1:   # האצ'בק
				pts = PackedVector2Array([o + Vector2(2, -8), o + Vector2(4, -26), o + Vector2(14, -30), o + Vector2(28, -h), o + Vector2(w * 0.72, -h), o + Vector2(w * 0.86, -30), o + Vector2(w - 2, -27), o + Vector2(w, -8)])
				win = PackedVector2Array([o + Vector2(32, -h + 4), o + Vector2(w * 0.7, -h + 4), o + Vector2(w * 0.82, -31), o + Vector2(24, -31)])
			2:   # טנדר
				pts = PackedVector2Array([o + Vector2(0, -8), o + Vector2(0, -28), o + Vector2(w * 0.5, -28), o + Vector2(w * 0.52, -h), o + Vector2(w * 0.76, -h), o + Vector2(w * 0.84, -30), o + Vector2(w - 2, -28), o + Vector2(w, -8)])
				win = PackedVector2Array([o + Vector2(w * 0.55, -h + 4), o + Vector2(w * 0.75, -h + 4), o + Vector2(w * 0.81, -31), o + Vector2(w * 0.55, -31)])
			_:   # סדאן
				pts = PackedVector2Array([o + Vector2(2, -8), o + Vector2(2, -24), o + Vector2(w * 0.24, -28), o + Vector2(w * 0.34, -h), o + Vector2(w * 0.68, -h), o + Vector2(w * 0.8, -29), o + Vector2(w - 2, -25), o + Vector2(w, -8)])
				win = PackedVector2Array([o + Vector2(w * 0.36, -h + 4), o + Vector2(w * 0.66, -h + 4), o + Vector2(w * 0.76, -30), o + Vector2(w * 0.29, -30)])
		Art.fill_shaded(self, pts, body, 0.18, 0.35, Art.OUTLINE, 1.6)
		draw_rect(Rect2(o + Vector2(0, -12), Vector2(w, 5)), dk)   # מגן תחתון
		draw_colored_polygon(win, glass)
		draw_line(win[0].lerp(win[3], 0.5) + Vector2(w * 0.12, 0), win[1].lerp(win[2], 0.5) + Vector2(-w * 0.04, 0), Color(1, 1, 1, 0.12), 3.0)   # השתקפות
		var crack := win[0].lerp(win[2], r.randf_range(0.3, 0.7))   # שמשה סדוקה
		for k in 5:
			draw_line(crack, crack + Vector2.from_angle(float(k) * 1.3 + r.randf()) * r.randf_range(6.0, 12.0), Color(0.85, 0.9, 0.95, 0.55), 1.0)
		var mid := (win[0].x + win[1].x) * 0.5
		draw_line(Vector2(mid, win[0].y), Vector2(mid, -12), Art.shade(body, 0.3), 1.5)   # דלת
		draw_line(Vector2(mid + 8, -24), Vector2(mid + 16, -24), Art.shade(body, 0.5), 2.0)   # ידית
		for i in 3:   # חלודה / שריטות
			var rx := o.x + r.randf_range(8.0, w - 30.0)
			draw_colored_polygon(Art.ellipse(Vector2(rx, -r.randf_range(14.0, 22.0)), r.randf_range(5.0, 10.0), 3.0), Color(0.45, 0.25, 0.12, 0.55))
		# פנסים
		var head := o + Vector2(w - 4, -21)
		draw_rect(Rect2(head + Vector2(-6, -3), Vector2(7, 5)), Color("e8e0b0"))
		draw_rect(Rect2(o + Vector2(0, -22), Vector2(5, 5)), Color("a02020"))
		# אזעקה: נורה אדומה ליד השמשה / אורות מהבהבים
		if alarm:
			var led := Vector2(win[3].x + 6.0, win[3].y - 3.0)
			if alarmed == 0:
				draw_circle(led, 1.8, Color(1.0, 0.15, 0.1) if _blink else Color(0.35, 0.06, 0.05))
				if _blink:
					draw_circle(led, 5.0, Color(1.0, 0.2, 0.1, 0.35))
			if _alarm_t > 0.0 and fmod(_alarm_t, 0.4) < 0.2:
				Art.glow(self, head + Vector2(10, 0), 40.0, Color(1.0, 0.95, 0.7, 0.45))
				Art.glow(self, o + Vector2(-6, -20), 26.0, Color(1.0, 0.6, 0.1, 0.5))
				Art.glow(self, head, 22.0, Color(1.0, 0.6, 0.1, 0.5))
		# גלגלים (אחד פנצ'ר)
		var flat := r.randi() % 2
		for i in 2:
			var wc := o + Vector2(w * (0.2 if i == 0 else 0.8), -9.0)
			var ry := 8.0 if i != flat else 6.0
			draw_colored_polygon(Art.ellipse(wc + Vector2(0, 9.0 - ry), 10.0, ry), Art.OUTLINE)
			draw_colored_polygon(Art.ellipse(wc + Vector2(0, 9.0 - ry), 8.5, ry - 1.5), Color("222224"))
			draw_circle(wc + Vector2(0, 9.0 - ry), 4.0, Color("6a6a70"))
			var a := _wheel
			draw_line(wc + Vector2(0, 9.0 - ry) - Vector2.from_angle(a) * 3.5, wc + Vector2(0, 9.0 - ry) + Vector2.from_angle(a) * 3.5, Color("3a3a3e"), 1.2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---- גשר שלטים מעל הכביש (קישוט, לא מוצק) ----
class Gantry extends Node2D:
	var h := 300.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var c := Color("4a4a50")
		for px in [0.0, 300.0]:
			draw_rect(Rect2(px, -h, 8, h), c)
			draw_rect(Rect2(px - 6, -6, 20, 6), Color("3a3a40"))
		for q in 2:
			draw_line(Vector2(0, -h + 6.0 + float(q) * 18.0), Vector2(308, -h + 6.0 + float(q) * 18.0), c, 3.0)
		for q in 10:
			draw_line(Vector2(8.0 + float(q) * 30.0, -h + 6.0), Vector2(38.0 + float(q) * 30.0, -h + 24.0), c, 1.2)
		draw_rect(Rect2(40, -h + 26, 110, 48), Color("2e6a3e"))
		draw_rect(Rect2(40, -h + 26, 110, 48), Color(1, 1, 1, 0.6), false, 1.5)
		draw_rect(Rect2(52, -h + 36, 60, 8), Color(1, 1, 1, 0.8))
		draw_rect(Rect2(52, -h + 52, 40, 6), Color(1, 1, 1, 0.6))
		draw_rect(Rect2(170, -h + 26, 110, 48), Color("2e6a3e"))
		draw_rect(Rect2(170, -h + 26, 110, 48), Color(1, 1, 1, 0.6), false, 1.5)
		draw_rect(Rect2(182, -h + 36, 80, 8), Color(1, 1, 1, 0.8))
		draw_line(Vector2(250, -h + 60), Vector2(266, -h + 54), Color(1, 1, 1, 0.8), 3.0)
		draw_line(Vector2(178, -h + 74), Vector2(192, -h + 110), Color(0.6, 0.6, 0.6, 0.8), 2.0)   # שלט תלוי חצי


# ---- גחלים ואפר (שכבת מסך) ----
class RoadFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _e := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 23
		for i in 36:
			_e.append(Vector3(r.randf_range(0, vp.x), r.randf_range(0, vp.y), r.randf_range(0.5, 1.5)))

	func _process(delta: float) -> void:
		_t += delta
		for i in _e.size():
			var e: Vector3 = _e[i]
			e.x += (-30.0 + sin(_t + e.z * 5.0) * 20.0) * delta * e.z
			e.y -= 26.0 * delta * e.z
			if e.y < -10.0 or e.x < -10.0:
				e = Vector3(randf_range(0.0, vp.x + 100.0), vp.y + 10.0, e.z)
			_e[i] = e
		queue_redraw()

	func _draw() -> void:
		for e in _e:
			var hot: bool = e.z > 1.1
			draw_circle(Vector2(e.x, e.y), 1.4 * e.z, Color(1.0, 0.55, 0.2, 0.7) if hot else Color(0.5, 0.45, 0.45, 0.45))
		draw_rect(Rect2(0, vp.y - 90, vp.x, 90), Color(0.9, 0.45, 0.2, 0.06))
